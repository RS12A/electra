import 'dart:async';
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../error/failures.dart';
import '../../services/logger_service.dart';
import '../models/queue_item.dart';
import '../models/sync_config.dart';
import '../repositories/offline_queue_repository.dart';
import 'network_monitor_service.dart';
import 'sync_handler_service.dart';

/// Status of sync orchestrator
enum SyncOrchestratorStatus {
  idle,
  syncing,
  paused,
  error,
}

/// Sync session statistics
class SyncSession {
  final String sessionId;
  final DateTime startTime;
  DateTime? endTime;
  int totalItems = 0;
  int successfulItems = 0;
  int failedItems = 0;
  int skippedItems = 0;
  final List<String> errors = [];
  
  SyncSession(this.sessionId, this.startTime);
  
  void complete() {
    endTime = DateTime.now();
  }
  
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
  
  double get successRate {
    return totalItems > 0 ? (successfulItems / totalItems) * 100 : 0.0;
  }
}

/// Service for orchestrating offline synchronization operations
///
/// Manages the complete sync lifecycle including batching, retry logic,
/// conflict resolution, and coordination between different operation types.
@singleton
class SyncOrchestratorService {
  final IOfflineQueueRepository _queueRepository;
  final NetworkMonitorService _networkMonitor;
  final SyncHandlerService _syncHandler;
  final LoggerService _logger;
  
  // Configuration
  SyncConfig _config = SyncConfigPresets.production;
  
  // State management
  SyncOrchestratorStatus _status = SyncOrchestratorStatus.idle;
  SyncSession? _currentSession;
  Timer? _backgroundSyncTimer;
  Timer? _retryTimer;
  StreamSubscription<NetworkStatus>? _networkStatusSubscription;
  
  // Stream controllers for reactive updates
  final StreamController<SyncOrchestratorStatus> _statusController =
      StreamController<SyncOrchestratorStatus>.broadcast();
  final StreamController<SyncSession> _sessionController =
      StreamController<SyncSession>.broadcast();
  
  // Concurrency control
  final Set<String> _activeSyncOperations = <String>{};
  int _maxConcurrentOperations = 3;
  
  // Statistics
  final List<SyncSession> _completedSessions = [];
  DateTime? _lastSuccessfulSync;
  int _totalItemsSynced = 0;
  int _totalSyncErrors = 0;

  SyncOrchestratorService(
    this._queueRepository,
    this._networkMonitor,
    this._syncHandler,
    this._logger,
  );

  /// Stream of sync orchestrator status updates
  Stream<SyncOrchestratorStatus> get statusStream => _statusController.stream;
  
  /// Stream of sync session updates
  Stream<SyncSession> get sessionStream => _sessionController.stream;
  
  /// Current sync orchestrator status
  SyncOrchestratorStatus get status => _status;
  
  /// Current sync session (if active)
  SyncSession? get currentSession => _currentSession;
  
  /// Last successful sync timestamp
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;
  
  /// Total items synced across all sessions
  int get totalItemsSynced => _totalItemsSynced;

  /// Initialize sync orchestrator
  Future<void> initialize(SyncConfig config) async {
    try {
      _config = config;
      _maxConcurrentOperations = config.maxConcurrentSyncs;
      
      // Listen to network status changes
      _networkStatusSubscription = _networkMonitor.networkStatusStream.listen(
        _onNetworkStatusChanged,
        onError: (error) {
          _logger.error('Network status monitoring error', error);
        },
      );
      
      // Start background sync timer if enabled
      if (config.enabled) {
        _startBackgroundSync();
      }
      
      _logger.info('Sync orchestrator initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize sync orchestrator', e);
      rethrow;
    }
  }

  /// Start manual sync operation
  Future<Either<Failure, SyncSession>> startSync({
    List<QueueOperationType>? operationTypes,
    List<QueuePriority>? priorities,
    bool forceSync = false,
  }) async {
    if (_status == SyncOrchestratorStatus.syncing && !forceSync) {
      return Left(ValidationFailure(message: 'Sync already in progress'));
    }

    if (!forceSync && !_shouldSync()) {
      return Left(ValidationFailure(message: 'Sync conditions not met'));
    }

    try {
      _logger.info('Starting manual sync operation');
      
      final session = await _startSyncSession(
        operationTypes: operationTypes,
        priorities: priorities,
      );
      
      return Right(session);
    } catch (e) {
      _logger.error('Failed to start sync', e);
      return Left(SyncFailure(message: 'Failed to start sync: ${e.toString()}'));
    }
  }

  /// Cancel current sync operation
  Future<void> cancelSync() async {
    if (_status != SyncOrchestratorStatus.syncing) return;
    
    _logger.info('Cancelling sync operation');
    
    _updateStatus(SyncOrchestratorStatus.paused);
    
    // Wait for active operations to complete
    while (_activeSyncOperations.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    _currentSession?.complete();
    _updateStatus(SyncOrchestratorStatus.idle);
    
    _logger.info('Sync operation cancelled');
  }

  /// Pause sync orchestrator
  void pauseSync() {
    if (_status == SyncOrchestratorStatus.syncing) {
      _updateStatus(SyncOrchestratorStatus.paused);
      _logger.info('Sync orchestrator paused');
    }
  }

  /// Resume sync orchestrator
  void resumeSync() {
    if (_status == SyncOrchestratorStatus.paused) {
      _updateStatus(SyncOrchestratorStatus.idle);
      _triggerSyncIfNeeded();
      _logger.info('Sync orchestrator resumed');
    }
  }

  /// Update sync configuration
  void updateConfig(SyncConfig config) {
    _config = config;
    _maxConcurrentOperations = config.maxConcurrentSyncs;
    
    // Restart background sync with new interval
    _backgroundSyncTimer?.cancel();
    if (config.enabled) {
      _startBackgroundSync();
    }
    
    _logger.info('Sync configuration updated');
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    final queueStatsResult = await _queueRepository.getQueueStats();
    final queueStats = queueStatsResult.fold(
      (failure) => null,
      (stats) => stats,
    );

    return {
      'status': _status.name,
      'lastSuccessfulSync': _lastSuccessfulSync?.toIso8601String(),
      'totalItemsSynced': _totalItemsSynced,
      'totalSyncErrors': _totalSyncErrors,
      'completedSessions': _completedSessions.length,
      'averageSessionDuration': _getAverageSessionDuration(),
      'averageSuccessRate': _getAverageSuccessRate(),
      'queueStats': queueStats?.toJson(),
      'networkStatus': _networkMonitor.currentStatus.toJson(),
      'config': _config.toJson(),
    };
  }

  /// Dispose resources
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _retryTimer?.cancel();
    _networkStatusSubscription?.cancel();
    _statusController.close();
    _sessionController.close();
  }

  // Private methods

  void _onNetworkStatusChanged(NetworkStatus networkStatus) {
    _logger.debug('Network status changed: ${networkStatus.connectionType} (${networkStatus.quality.name})');
    
    if (networkStatus.isConnected && networkStatus.syncRecommended) {
      _triggerSyncIfNeeded();
    } else if (!networkStatus.isConnected && _status == SyncOrchestratorStatus.syncing) {
      pauseSync();
    }
  }

  void _startBackgroundSync() {
    _backgroundSyncTimer = Timer.periodic(
      _config.backgroundSyncInterval,
      (_) => _triggerSyncIfNeeded(),
    );
  }

  void _triggerSyncIfNeeded() {
    if (_status == SyncOrchestratorStatus.idle && _shouldSync()) {
      startSync();
    }
  }

  bool _shouldSync() {
    // Check if sync is enabled
    if (!_config.enabled) return false;
    
    // Check network conditions
    if (!_networkMonitor.isSyncRecommended(
      config: _config,
      requiresWiFi: _config.wifiOnly,
      requiresCharging: _config.requiresCharging,
    )) {
      return false;
    }
    
    return true;
  }

  Future<SyncSession> _startSyncSession({
    List<QueueOperationType>? operationTypes,
    List<QueuePriority>? priorities,
  }) async {
    final sessionId = _generateSessionId();
    final session = SyncSession(sessionId, DateTime.now());
    
    _currentSession = session;
    _updateStatus(SyncOrchestratorStatus.syncing);
    _sessionController.add(session);
    
    // Process queue in batches
    await _processSyncBatches(
      session,
      operationTypes: operationTypes,
      priorities: priorities,
    );
    
    // Complete session
    session.complete();
    _completedSessions.add(session);
    _currentSession = null;
    
    // Update statistics
    _totalItemsSynced += session.successfulItems;
    _totalSyncErrors += session.failedItems;
    
    if (session.successfulItems > 0) {
      _lastSuccessfulSync = DateTime.now();
    }
    
    _updateStatus(SyncOrchestratorStatus.idle);
    _sessionController.add(session);
    
    _logger.info(
      'Sync session completed: ${session.sessionId} '
      '(${session.successfulItems}/${session.totalItems} synced, '
      '${session.successRate.toStringAsFixed(1)}% success rate)',
    );
    
    return session;
  }

  Future<void> _processSyncBatches(
    SyncSession session, {
    List<QueueOperationType>? operationTypes,
    List<QueuePriority>? priorities,
  }) async {
    bool hasMoreItems = true;
    
    while (hasMoreItems && _status == SyncOrchestratorStatus.syncing) {
      // Get next batch
      final batchResult = await _queueRepository.getNextBatch(
        batchSize: _config.maxBatchSize,
        operationTypes: operationTypes,
        priorities: priorities,
      );
      
      final batch = batchResult.fold(
        (failure) {
          session.errors.add('Failed to get batch: ${failure.message}');
          return <QueueItem>[];
        },
        (items) => items,
      );
      
      if (batch.isEmpty) {
        hasMoreItems = false;
        continue;
      }
      
      // Process batch items
      await _processBatch(session, batch);
      
      // Delay between batches
      if (hasMoreItems && _config.batchDelay.inMilliseconds > 0) {
        await Future.delayed(_config.batchDelay);
      }
    }
  }

  Future<void> _processBatch(SyncSession session, List<QueueItem> batch) async {
    _logger.debug('Processing batch of ${batch.length} items');
    
    final futures = <Future<void>>[];
    
    for (final item in batch) {
      // Respect concurrency limits
      while (_activeSyncOperations.length >= _maxConcurrentOperations) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      if (_status != SyncOrchestratorStatus.syncing) break;
      
      futures.add(_processSyncItem(session, item));
    }
    
    // Wait for all items in batch to complete
    await Future.wait(futures);
  }

  Future<void> _processSyncItem(SyncSession session, QueueItem item) async {
    _activeSyncOperations.add(item.uuid);
    session.totalItems++;
    
    try {
      // Update item status to processing
      await _queueRepository.updateItemStatus(
        item.uuid,
        QueueItemStatus.processing,
      );
      
      // Get decrypted payload
      final payloadResult = await _queueRepository.getDecryptedPayload(item);
      final payload = payloadResult.fold(
        (failure) => throw Exception('Failed to decrypt payload: ${failure.message}'),
        (data) => data,
      );
      
      // Sync the item
      final syncResult = await _syncHandler.syncItem(item, payload);
      
      syncResult.fold(
        (failure) {
          session.failedItems++;
          session.errors.add('${item.operationType.value}: ${failure.message}');
          
          // Update retry information
          _queueRepository.updateItemStatus(
            item.uuid,
            QueueItemStatus.failed,
            error: failure.message,
          );
        },
        (success) {
          session.successfulItems++;
          _queueRepository.markAsSynced(item.uuid);
        },
      );
      
    } catch (e) {
      session.failedItems++;
      session.errors.add('${item.operationType.value}: ${e.toString()}');
      
      await _queueRepository.updateItemStatus(
        item.uuid,
        QueueItemStatus.failed,
        error: e.toString(),
      );
    } finally {
      _activeSyncOperations.remove(item.uuid);
    }
  }

  void _updateStatus(SyncOrchestratorStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  String _generateSessionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomValue = random.nextInt(1000000);
    return 'sync_${timestamp}_$randomValue';
  }

  double _getAverageSessionDuration() {
    if (_completedSessions.isEmpty) return 0.0;
    
    final totalDuration = _completedSessions
        .map((s) => s.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    
    return totalDuration / _completedSessions.length / 1000.0; // seconds
  }

  double _getAverageSuccessRate() {
    if (_completedSessions.isEmpty) return 0.0;
    
    final totalSuccessRate = _completedSessions
        .map((s) => s.successRate)
        .reduce((a, b) => a + b);
    
    return totalSuccessRate / _completedSessions.length;
  }
}