import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../di/injection_container.dart';
import '../models/queue_item.dart';
import '../models/sync_config.dart';
import '../repositories/offline_queue_repository.dart';
import '../services/network_monitor_service.dart';
import '../services/sync_orchestrator_service.dart';

part 'offline_providers.freezed.dart';

/// Global offline state for the application
@freezed
class OfflineState with _$OfflineState {
  const factory OfflineState({
    /// Network connectivity status
    @Default(NetworkStatus(
      isConnected: false,
      connectionType: 'none',
      quality: NetworkQuality.offline,
      lastUpdated: null,
      syncRecommended: false,
    )) NetworkStatus networkStatus,
    
    /// Sync orchestrator status
    @Default(SyncOrchestratorStatus.idle) SyncOrchestratorStatus syncStatus,
    
    /// Current sync session (if active)
    SyncSession? currentSyncSession,
    
    /// Queue statistics
    QueueStats? queueStats,
    
    /// Total pending items count
    @Default(0) int pendingItemsCount,
    
    /// Items currently being synced
    @Default([]) List<QueueItem> syncingItems,
    
    /// Recent sync errors
    @Default([]) List<String> recentErrors,
    
    /// Last successful sync timestamp
    DateTime? lastSuccessfulSync,
    
    /// Sync configuration
    SyncConfig? syncConfig,
    
    /// Whether offline mode is enabled
    @Default(true) bool offlineModeEnabled,
    
    /// Loading states
    @Default(false) bool isLoadingQueueStats,
    @Default(false) bool isManualSyncInProgress,
  }) = _OfflineState;
}

/// Provider for offline queue repository
final offlineQueueRepositoryProvider = Provider<IOfflineQueueRepository>((ref) {
  return getIt<IOfflineQueueRepository>();
});

/// Provider for network monitor service
final networkMonitorServiceProvider = Provider<NetworkMonitorService>((ref) {
  return getIt<NetworkMonitorService>();
});

/// Provider for sync orchestrator service
final syncOrchestratorServiceProvider = Provider<SyncOrchestratorService>((ref) {
  return getIt<SyncOrchestratorService>();
});

/// Provider for network status stream
final networkStatusStreamProvider = StreamProvider<NetworkStatus>((ref) {
  final networkMonitor = ref.watch(networkMonitorServiceProvider);
  return networkMonitor.networkStatusStream;
});

/// Provider for sync orchestrator status stream
final syncStatusStreamProvider = StreamProvider<SyncOrchestratorStatus>((ref) {
  final syncOrchestrator = ref.watch(syncOrchestratorServiceProvider);
  return syncOrchestrator.statusStream;
});

/// Provider for sync session stream
final syncSessionStreamProvider = StreamProvider<SyncSession>((ref) {
  final syncOrchestrator = ref.watch(syncOrchestratorServiceProvider);
  return syncOrchestrator.sessionStream;
});

/// Provider for queue statistics
final queueStatsProvider = FutureProvider<QueueStats?>((ref) async {
  final queueRepository = ref.watch(offlineQueueRepositoryProvider);
  final result = await queueRepository.getQueueStats();
  return result.fold(
    (failure) => null,
    (stats) => stats,
  );
});

/// Provider for pending items count
final pendingItemsCountProvider = FutureProvider<int>((ref) async {
  final queueRepository = ref.watch(offlineQueueRepositoryProvider);
  final result = await queueRepository.getItemsByStatus(QueueItemStatus.pending);
  return result.fold(
    (failure) => 0,
    (items) => items.length,
  );
});

/// Provider for syncing items
final syncingItemsProvider = FutureProvider<List<QueueItem>>((ref) async {
  final queueRepository = ref.watch(offlineQueueRepositoryProvider);
  final result = await queueRepository.getItemsByStatus(QueueItemStatus.processing);
  return result.fold(
    (failure) => [],
    (items) => items,
  );
});

/// Main offline state notifier
class OfflineStateNotifier extends StateNotifier<OfflineState> {
  final IOfflineQueueRepository _queueRepository;
  final NetworkMonitorService _networkMonitor;
  final SyncOrchestratorService _syncOrchestrator;
  final Ref _ref;

  // Stream subscriptions
  StreamSubscription<NetworkStatus>? _networkStatusSubscription;
  StreamSubscription<SyncOrchestratorStatus>? _syncStatusSubscription;
  StreamSubscription<SyncSession>? _syncSessionSubscription;

  // Periodic refresh timer
  Timer? _refreshTimer;

  OfflineStateNotifier(
    this._queueRepository,
    this._networkMonitor,
    this._syncOrchestrator,
    this._ref,
  ) : super(const OfflineState()) {
    _initialize();
  }

  /// Initialize offline state monitoring
  void _initialize() {
    // Listen to network status changes
    _networkStatusSubscription = _networkMonitor.networkStatusStream.listen(
      (networkStatus) {
        state = state.copyWith(networkStatus: networkStatus);
        
        // Trigger sync if network becomes available
        if (networkStatus.isConnected && networkStatus.syncRecommended) {
          _triggerAutoSync();
        }
      },
    );

    // Listen to sync orchestrator status changes
    _syncStatusSubscription = _syncOrchestrator.statusStream.listen(
      (syncStatus) {
        state = state.copyWith(syncStatus: syncStatus);
        
        // Update manual sync progress indicator
        if (syncStatus == SyncOrchestratorStatus.syncing) {
          state = state.copyWith(isManualSyncInProgress: true);
        } else {
          state = state.copyWith(isManualSyncInProgress: false);
        }
      },
    );

    // Listen to sync session updates
    _syncSessionSubscription = _syncOrchestrator.sessionStream.listen(
      (session) {
        state = state.copyWith(currentSyncSession: session);
        
        // Update last successful sync if session completed successfully
        if (session.endTime != null && session.successfulItems > 0) {
          state = state.copyWith(lastSuccessfulSync: session.endTime);
        }
        
        // Update recent errors
        if (session.errors.isNotEmpty) {
          final recentErrors = [
            ...state.recentErrors,
            ...session.errors.take(5),
          ].take(10).toList();
          
          state = state.copyWith(recentErrors: recentErrors);
        }
      },
    );

    // Start periodic refresh of queue statistics
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshQueueStats(),
    );

    // Initial data load
    _refreshQueueStats();
  }

  /// Queue an operation for offline sync
  Future<String?> queueOperation({
    required QueueOperationType operationType,
    required Map<String, dynamic> payload,
    QueuePriority priority = QueuePriority.normal,
    Map<String, dynamic> metadata = const {},
    String? relatedEntityId,
    String? userId,
  }) async {
    if (!state.offlineModeEnabled) {
      return null;
    }

    final result = await _queueRepository.enqueueItem(
      operationType: operationType,
      payload: payload,
      priority: priority,
      metadata: metadata,
      relatedEntityId: relatedEntityId,
      userId: userId,
    );

    return result.fold(
      (failure) {
        _addError('Failed to queue operation: ${failure.message}');
        return null;
      },
      (itemId) {
        _refreshQueueStats();
        
        // Trigger sync if network is available
        if (state.networkStatus.isConnected && state.networkStatus.syncRecommended) {
          _triggerAutoSync();
        }
        
        return itemId;
      },
    );
  }

  /// Start manual sync
  Future<bool> startManualSync({
    List<QueueOperationType>? operationTypes,
    List<QueuePriority>? priorities,
  }) async {
    if (state.syncStatus == SyncOrchestratorStatus.syncing) {
      return false;
    }

    state = state.copyWith(isManualSyncInProgress: true);

    final result = await _syncOrchestrator.startSync(
      operationTypes: operationTypes,
      priorities: priorities,
      forceSync: true,
    );

    return result.fold(
      (failure) {
        _addError('Failed to start sync: ${failure.message}');
        state = state.copyWith(isManualSyncInProgress: false);
        return false;
      },
      (session) {
        // Success handled by session stream listener
        return true;
      },
    );
  }

  /// Cancel current sync
  Future<void> cancelSync() async {
    await _syncOrchestrator.cancelSync();
    state = state.copyWith(
      isManualSyncInProgress: false,
      currentSyncSession: null,
    );
  }

  /// Enable/disable offline mode
  void setOfflineModeEnabled(bool enabled) {
    state = state.copyWith(offlineModeEnabled: enabled);
    
    if (enabled && state.networkStatus.isConnected) {
      _triggerAutoSync();
    }
  }

  /// Update sync configuration
  void updateSyncConfig(SyncConfig config) {
    _syncOrchestrator.updateConfig(config);
    state = state.copyWith(syncConfig: config);
  }

  /// Clear recent errors
  void clearRecentErrors() {
    state = state.copyWith(recentErrors: []);
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    return await _syncOrchestrator.getSyncStatistics();
  }

  /// Refresh queue statistics
  Future<void> _refreshQueueStats() async {
    state = state.copyWith(isLoadingQueueStats: true);

    final statsResult = await _queueRepository.getQueueStats();
    final pendingResult = await _queueRepository.getItemsByStatus(QueueItemStatus.pending);
    final syncingResult = await _queueRepository.getItemsByStatus(QueueItemStatus.processing);

    final stats = statsResult.fold((failure) => null, (stats) => stats);
    final pendingCount = pendingResult.fold((failure) => 0, (items) => items.length);
    final syncingItems = syncingResult.fold((failure) => <QueueItem>[], (items) => items);

    state = state.copyWith(
      queueStats: stats,
      pendingItemsCount: pendingCount,
      syncingItems: syncingItems,
      isLoadingQueueStats: false,
    );
  }

  /// Trigger automatic sync if conditions are met
  void _triggerAutoSync() {
    if (state.offlineModeEnabled &&
        state.syncStatus == SyncOrchestratorStatus.idle &&
        state.pendingItemsCount > 0) {
      // Use fire-and-forget for automatic sync
      _syncOrchestrator.startSync();
    }
  }

  /// Add error to recent errors list
  void _addError(String error) {
    final recentErrors = [error, ...state.recentErrors].take(10).toList();
    state = state.copyWith(recentErrors: recentErrors);
  }

  @override
  void dispose() {
    _networkStatusSubscription?.cancel();
    _syncStatusSubscription?.cancel();
    _syncSessionSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Provider for offline state notifier
final offlineStateProvider = StateNotifierProvider<OfflineStateNotifier, OfflineState>((ref) {
  final queueRepository = ref.watch(offlineQueueRepositoryProvider);
  final networkMonitor = ref.watch(networkMonitorServiceProvider);
  final syncOrchestrator = ref.watch(syncOrchestratorServiceProvider);

  return OfflineStateNotifier(queueRepository, networkMonitor, syncOrchestrator, ref);
});

/// Provider for network connection status
final isConnectedProvider = Provider<bool>((ref) {
  final offlineState = ref.watch(offlineStateProvider);
  return offlineState.networkStatus.isConnected;
});

/// Provider for sync recommendation status
final syncRecommendedProvider = Provider<bool>((ref) {
  final offlineState = ref.watch(offlineStateProvider);
  return offlineState.networkStatus.syncRecommended;
});

/// Provider for pending items count
final hasPendingItemsProvider = Provider<bool>((ref) {
  final offlineState = ref.watch(offlineStateProvider);
  return offlineState.pendingItemsCount > 0;
});

/// Provider for sync in progress status
final isSyncInProgressProvider = Provider<bool>((ref) {
  final offlineState = ref.watch(offlineStateProvider);
  return offlineState.syncStatus == SyncOrchestratorStatus.syncing;
});

/// Convenience provider for offline queue operations
final offlineQueueProvider = Provider<OfflineQueueOperations>((ref) {
  return OfflineQueueOperations(ref);
});

/// Helper class for offline queue operations
class OfflineQueueOperations {
  final Ref _ref;

  OfflineQueueOperations(this._ref);

  /// Queue a vote for offline submission
  Future<String?> queueVote({
    required String electionId,
    required Map<String, String> selections,
    required String ballotToken,
    String? userId,
  }) async {
    final notifier = _ref.read(offlineStateProvider.notifier);
    
    return await notifier.queueOperation(
      operationType: QueueOperationType.vote,
      priority: QueuePriority.high,
      payload: {
        'electionId': electionId,
        'selections': selections,
        'ballotToken': ballotToken,
      },
      relatedEntityId: electionId,
      userId: userId,
    );
  }

  /// Queue authentication refresh
  Future<String?> queueAuthRefresh({
    required String refreshToken,
    String? userId,
  }) async {
    final notifier = _ref.read(offlineStateProvider.notifier);
    
    return await notifier.queueOperation(
      operationType: QueueOperationType.authRefresh,
      priority: QueuePriority.critical,
      payload: {
        'refreshToken': refreshToken,
      },
      userId: userId,
    );
  }

  /// Queue profile update
  Future<String?> queueProfileUpdate({
    required Map<String, dynamic> profileData,
    String? userId,
  }) async {
    final notifier = _ref.read(offlineStateProvider.notifier);
    
    return await notifier.queueOperation(
      operationType: QueueOperationType.profileUpdate,
      priority: QueuePriority.normal,
      payload: profileData,
      userId: userId,
    );
  }

  /// Queue notification acknowledgment
  Future<String?> queueNotificationAck({
    required String notificationId,
    String? userId,
  }) async {
    final notifier = _ref.read(offlineStateProvider.notifier);
    
    return await notifier.queueOperation(
      operationType: QueueOperationType.notificationAck,
      priority: QueuePriority.low,
      payload: {
        'notificationId': notificationId,
      },
      relatedEntityId: notificationId,
      userId: userId,
    );
  }

  /// Queue timetable event
  Future<String?> queueTimetableEvent({
    required Map<String, dynamic> eventData,
    String? userId,
  }) async {
    final notifier = _ref.read(offlineStateProvider.notifier);
    
    return await notifier.queueOperation(
      operationType: QueueOperationType.timetableEvent,
      priority: QueuePriority.normal,
      payload: eventData,
      userId: userId,
    );
  }
}