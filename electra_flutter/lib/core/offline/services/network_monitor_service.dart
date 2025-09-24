import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../services/logger_service.dart';
import '../models/sync_config.dart';

/// Service for monitoring network connectivity and quality
///
/// Provides real-time network status updates, connection quality assessment,
/// and intelligent sync recommendations based on network conditions.
@singleton
class NetworkMonitorService {
  final Connectivity _connectivity;
  final LoggerService _logger;
  final Dio _dio;

  // Stream controllers for reactive updates
  final StreamController<NetworkStatus> _networkStatusController =
      StreamController<NetworkStatus>.broadcast();
  
  // Current network status
  NetworkStatus _currentStatus = const NetworkStatus(
    isConnected: false,
    connectionType: 'none',
    quality: NetworkQuality.offline,
    lastUpdated: null,
    syncRecommended: false,
  );

  // Monitoring state
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _qualityCheckTimer;
  Timer? _healthCheckTimer;
  
  // Configuration
  static const Duration _qualityCheckInterval = Duration(seconds: 30);
  static const Duration _healthCheckInterval = Duration(minutes: 2);
  static const Duration _connectivityTimeout = Duration(seconds: 10);
  static const String _healthCheckUrl = 'https://www.google.com/generate_204';

  NetworkMonitorService(
    this._connectivity,
    this._logger,
    this._dio,
  ) {
    // Configure Dio for health checks
    _dio.options.connectTimeout = _connectivityTimeout;
    _dio.options.receiveTimeout = _connectivityTimeout;
  }

  /// Stream of network status updates
  Stream<NetworkStatus> get networkStatusStream => _networkStatusController.stream;

  /// Current network status
  NetworkStatus get currentStatus => _currentStatus;

  /// Start monitoring network connectivity
  Future<void> startMonitoring() async {
    try {
      _logger.info('Starting network monitoring');

      // Initial connectivity check
      await _performInitialConnectivityCheck();

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          _logger.error('Connectivity monitoring error', error);
        },
      );

      // Start periodic quality checks
      _qualityCheckTimer = Timer.periodic(
        _qualityCheckInterval,
        (_) => _performQualityCheck(),
      );

      // Start periodic health checks
      _healthCheckTimer = Timer.periodic(
        _healthCheckInterval,
        (_) => _performHealthCheck(),
      );

      _logger.info('Network monitoring started successfully');
    } catch (e) {
      _logger.error('Failed to start network monitoring', e);
      rethrow;
    }
  }

  /// Stop monitoring network connectivity
  Future<void> stopMonitoring() async {
    _logger.info('Stopping network monitoring');

    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    _qualityCheckTimer?.cancel();
    _qualityCheckTimer = null;

    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    _logger.info('Network monitoring stopped');
  }

  /// Force refresh network status
  Future<void> refreshNetworkStatus() async {
    await _performConnectivityCheck();
  }

  /// Check if sync is recommended based on current conditions
  bool isSyncRecommended({
    SyncConfig? config,
    bool requiresWiFi = false,
    bool requiresCharging = false,
  }) {
    final status = _currentStatus;
    
    // No connection = no sync
    if (!status.isConnected) {
      return false;
    }

    // Check quality requirements
    if (status.quality == NetworkQuality.poor) {
      return false;
    }

    // Check WiFi requirement
    if (requiresWiFi && !_isWiFiConnection(status.connectionType)) {
      return false;
    }

    // Check metered connection
    if (status.isMetered && (config?.wifiOnly == true)) {
      return false;
    }

    // Check charging requirement (would need battery service integration)
    if (requiresCharging) {
      // This would require integration with a battery monitoring service
      // For now, assume charging is not required
    }

    return true;
  }

  /// Get estimated sync speed based on network quality
  double getEstimatedSyncSpeedMbps() {
    switch (_currentStatus.quality) {
      case NetworkQuality.excellent:
        return _currentStatus.speedMbps ?? 100.0;
      case NetworkQuality.good:
        return _currentStatus.speedMbps ?? 25.0;
      case NetworkQuality.moderate:
        return _currentStatus.speedMbps ?? 5.0;
      case NetworkQuality.poor:
        return _currentStatus.speedMbps ?? 1.0;
      case NetworkQuality.offline:
        return 0.0;
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _networkStatusController.close();
  }

  // Private methods

  Future<void> _performInitialConnectivityCheck() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    await _onConnectivityChanged(connectivityResult);
  }

  Future<void> _onConnectivityChanged(ConnectivityResult result) async {
    _logger.debug('Connectivity changed: $result');
    
    final connectionType = _mapConnectivityResult(result);
    final isConnected = result != ConnectivityResult.none;
    
    if (isConnected) {
      // Perform quality assessment for connected state
      await _assessNetworkQuality(connectionType);
    } else {
      // Update to offline state
      _updateNetworkStatus(
        isConnected: false,
        connectionType: connectionType,
        quality: NetworkQuality.offline,
        syncRecommended: false,
        syncBlockReason: 'No network connection',
      );
    }
  }

  Future<void> _performConnectivityCheck() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      await _onConnectivityChanged(connectivityResult);
    } catch (e) {
      _logger.error('Failed to perform connectivity check', e);
    }
  }

  Future<void> _performQualityCheck() async {
    if (!_currentStatus.isConnected) return;

    try {
      await _assessNetworkQuality(_currentStatus.connectionType);
    } catch (e) {
      _logger.error('Failed to perform quality check', e);
    }
  }

  Future<void> _performHealthCheck() async {
    if (!_currentStatus.isConnected) return;

    try {
      final stopwatch = Stopwatch()..start();
      final response = await _dio.get(
        _healthCheckUrl,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
        ),
      );
      stopwatch.stop();

      final isHealthy = response.statusCode == 204 || response.statusCode == 200;
      final latency = stopwatch.elapsedMilliseconds;

      if (!isHealthy) {
        _updateNetworkStatus(
          quality: NetworkQuality.poor,
          latencyMs: latency,
          syncRecommended: false,
          syncBlockReason: 'Network health check failed',
        );
      } else {
        // Health check passed, assess quality based on latency
        final quality = _assessQualityFromLatency(latency);
        _updateNetworkStatus(
          quality: quality,
          latencyMs: latency,
          syncRecommended: quality != NetworkQuality.poor,
        );
      }
    } catch (e) {
      _logger.warning('Network health check failed', e);
      _updateNetworkStatus(
        quality: NetworkQuality.poor,
        syncRecommended: false,
        syncBlockReason: 'Health check failed: ${e.toString()}',
      );
    }
  }

  Future<void> _assessNetworkQuality(String connectionType) async {
    try {
      // Perform a lightweight speed test
      final speedResult = await _performSpeedTest();
      final quality = _assessQualityFromSpeed(speedResult.speedMbps);
      
      _updateNetworkStatus(
        isConnected: true,
        connectionType: connectionType,
        quality: quality,
        isMetered: _isMeteredConnection(connectionType),
        speedMbps: speedResult.speedMbps,
        latencyMs: speedResult.latencyMs,
        syncRecommended: quality != NetworkQuality.poor,
      );
    } catch (e) {
      _logger.warning('Failed to assess network quality', e);
      
      // Fallback to basic connectivity assessment
      _updateNetworkStatus(
        isConnected: true,
        connectionType: connectionType,
        quality: NetworkQuality.moderate,
        isMetered: _isMeteredConnection(connectionType),
        syncRecommended: true,
      );
    }
  }

  Future<_SpeedTestResult> _performSpeedTest() async {
    const testUrl = 'https://httpbin.org/bytes/1024'; // 1KB test file
    
    final stopwatch = Stopwatch()..start();
    final response = await _dio.get(
      testUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    stopwatch.stop();

    final bytes = (response.data as List<int>).length;
    final timeMs = stopwatch.elapsedMilliseconds;
    final speedMbps = (bytes * 8) / (timeMs * 1000); // Convert to Mbps

    return _SpeedTestResult(
      speedMbps: speedMbps,
      latencyMs: timeMs,
    );
  }

  NetworkQuality _assessQualityFromSpeed(double speedMbps) {
    if (speedMbps >= 10.0) return NetworkQuality.excellent;
    if (speedMbps >= 5.0) return NetworkQuality.good;
    if (speedMbps >= 1.0) return NetworkQuality.moderate;
    return NetworkQuality.poor;
  }

  NetworkQuality _assessQualityFromLatency(int latencyMs) {
    if (latencyMs <= 50) return NetworkQuality.excellent;
    if (latencyMs <= 150) return NetworkQuality.good;
    if (latencyMs <= 500) return NetworkQuality.moderate;
    return NetworkQuality.poor;
  }

  String _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'wifi';
      case ConnectivityResult.mobile:
        return 'mobile';
      case ConnectivityResult.ethernet:
        return 'ethernet';
      case ConnectivityResult.bluetooth:
        return 'bluetooth';
      case ConnectivityResult.vpn:
        return 'vpn';
      case ConnectivityResult.other:
        return 'other';
      case ConnectivityResult.none:
      default:
        return 'none';
    }
  }

  bool _isWiFiConnection(String connectionType) {
    return connectionType == 'wifi' || connectionType == 'ethernet';
  }

  bool _isMeteredConnection(String connectionType) {
    return connectionType == 'mobile' || connectionType == 'bluetooth';
  }

  void _updateNetworkStatus({
    bool? isConnected,
    String? connectionType,
    NetworkQuality? quality,
    bool? isMetered,
    int? signalStrength,
    double? speedMbps,
    int? latencyMs,
    bool? syncRecommended,
    String? syncBlockReason,
  }) {
    final now = DateTime.now();
    
    final updatedStatus = _currentStatus.copyWith(
      isConnected: isConnected ?? _currentStatus.isConnected,
      connectionType: connectionType ?? _currentStatus.connectionType,
      quality: quality ?? _currentStatus.quality,
      isMetered: isMetered ?? _currentStatus.isMetered,
      signalStrength: signalStrength ?? _currentStatus.signalStrength,
      speedMbps: speedMbps ?? _currentStatus.speedMbps,
      latencyMs: latencyMs ?? _currentStatus.latencyMs,
      lastUpdated: now,
      syncRecommended: syncRecommended ?? _currentStatus.syncRecommended,
      syncBlockReason: syncBlockReason ?? _currentStatus.syncBlockReason,
    );

    // Only emit if status actually changed
    if (updatedStatus != _currentStatus) {
      _currentStatus = updatedStatus;
      _networkStatusController.add(_currentStatus);
      
      _logger.debug(
        'Network status updated: ${_currentStatus.connectionType} '
        '(${_currentStatus.quality.name}) - Sync: ${_currentStatus.syncRecommended}',
      );
    }
  }
}

/// Result of a network speed test
class _SpeedTestResult {
  final double speedMbps;
  final int latencyMs;

  const _SpeedTestResult({
    required this.speedMbps,
    required this.latencyMs,
  });
}