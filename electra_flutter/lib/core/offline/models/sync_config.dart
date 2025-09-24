import 'package:freezed_annotation/freezed_annotation.dart';

import 'queue_item.dart';

part 'sync_config.freezed.dart';
part 'sync_config.g.dart';

/// Configuration for sync behavior
@freezed
class SyncConfig with _$SyncConfig {
  const factory SyncConfig({
    /// Whether sync is enabled
    @Default(true) bool enabled,
    
    /// Sync only when on WiFi
    @Default(false) bool wifiOnly,
    
    /// Sync when device is charging
    @Default(false) bool requiresCharging,
    
    /// Maximum batch size for sync operations
    @Default(10) int maxBatchSize,
    
    /// Timeout for individual sync operations
    @Default(Duration(seconds: 30)) Duration syncTimeout,
    
    /// Delay between batch processing
    @Default(Duration(seconds: 2)) Duration batchDelay,
    
    /// Maximum concurrent sync operations
    @Default(3) int maxConcurrentSyncs,
    
    /// Retry configuration
    required RetryConfig retryConfig,
    
    /// Conflict resolution rules by operation type
    @Default({}) Map<QueueOperationType, ConflictRule> conflictRules,
    
    /// Background sync interval
    @Default(Duration(minutes: 15)) Duration backgroundSyncInterval,
    
    /// Enable aggressive sync when online
    @Default(true) bool aggressiveSyncWhenOnline,
    
    /// Sync priority order
    @Default([
      QueuePriority.critical,
      QueuePriority.high,
      QueuePriority.normal,
      QueuePriority.low,
    ]) List<QueuePriority> priorityOrder,
  }) = _SyncConfig;

  factory SyncConfig.fromJson(Map<String, dynamic> json) =>
      _$SyncConfigFromJson(json);
}

/// Retry configuration with exponential backoff
@freezed
class RetryConfig with _$RetryConfig {
  const factory RetryConfig({
    /// Initial retry delay
    @Default(Duration(seconds: 1)) Duration initialDelay,
    
    /// Maximum retry delay
    @Default(Duration(minutes: 30)) Duration maxDelay,
    
    /// Backoff multiplier
    @Default(2.0) double backoffMultiplier,
    
    /// Maximum number of retries
    @Default(5) int maxRetries,
    
    /// Jitter factor to prevent thundering herd
    @Default(0.1) double jitterFactor,
    
    /// Whether to use exponential backoff
    @Default(true) bool useExponentialBackoff,
    
    /// Custom retry delays for specific errors
    @Default({}) Map<String, Duration> customDelays,
  }) = _RetryConfig;

  factory RetryConfig.fromJson(Map<String, dynamic> json) =>
      _$RetryConfigFromJson(json);
}

/// Network connection quality levels
enum NetworkQuality {
  offline,
  poor,
  moderate,
  good,
  excellent;
}

/// Network status with detailed connection information
@freezed
class NetworkStatus with _$NetworkStatus {
  const factory NetworkStatus({
    /// Whether device is connected to internet
    required bool isConnected,
    
    /// Type of connection (WiFi, mobile, etc.)
    required String connectionType,
    
    /// Connection quality assessment
    required NetworkQuality quality,
    
    /// Whether connection is metered (mobile data)
    @Default(false) bool isMetered,
    
    /// Signal strength (0-100)
    int? signalStrength,
    
    /// Connection speed estimate (Mbps)
    double? speedMbps,
    
    /// Latency to server (milliseconds)
    int? latencyMs,
    
    /// When the status was last updated
    required DateTime lastUpdated,
    
    /// Whether sync is recommended given current conditions
    required bool syncRecommended,
    
    /// Reason why sync may not be recommended
    String? syncBlockReason,
  }) = _NetworkStatus;

  factory NetworkStatus.fromJson(Map<String, dynamic> json) =>
      _$NetworkStatusFromJson(json);
}

/// Default sync configurations for different scenarios
class SyncConfigPresets {
  /// Production configuration with conservative settings
  static const SyncConfig production = SyncConfig(
    enabled: true,
    wifiOnly: false,
    requiresCharging: false,
    maxBatchSize: 5,
    syncTimeout: Duration(seconds: 30),
    batchDelay: Duration(seconds: 3),
    maxConcurrentSyncs: 2,
    retryConfig: RetryConfig(
      initialDelay: Duration(seconds: 2),
      maxDelay: Duration(minutes: 10),
      backoffMultiplier: 2.0,
      maxRetries: 3,
      jitterFactor: 0.1,
      useExponentialBackoff: true,
    ),
    backgroundSyncInterval: Duration(minutes: 30),
    aggressiveSyncWhenOnline: false,
  );

  /// Development configuration with faster syncing
  static const SyncConfig development = SyncConfig(
    enabled: true,
    wifiOnly: false,
    requiresCharging: false,
    maxBatchSize: 10,
    syncTimeout: Duration(seconds: 15),
    batchDelay: Duration(seconds: 1),
    maxConcurrentSyncs: 5,
    retryConfig: RetryConfig(
      initialDelay: Duration(milliseconds: 500),
      maxDelay: Duration(minutes: 5),
      backoffMultiplier: 1.5,
      maxRetries: 5,
      jitterFactor: 0.05,
      useExponentialBackoff: true,
    ),
    backgroundSyncInterval: Duration(minutes: 5),
    aggressiveSyncWhenOnline: true,
  );

  /// Battery optimized configuration
  static const SyncConfig batteryOptimized = SyncConfig(
    enabled: true,
    wifiOnly: true,
    requiresCharging: true,
    maxBatchSize: 3,
    syncTimeout: Duration(seconds: 45),
    batchDelay: Duration(seconds: 5),
    maxConcurrentSyncs: 1,
    retryConfig: RetryConfig(
      initialDelay: Duration(seconds: 5),
      maxDelay: Duration(hours: 1),
      backoffMultiplier: 3.0,
      maxRetries: 3,
      jitterFactor: 0.2,
      useExponentialBackoff: true,
    ),
    backgroundSyncInterval: Duration(hours: 1),
    aggressiveSyncWhenOnline: false,
  );

  /// Get default conflict resolution rules
  static Map<QueueOperationType, ConflictRule> getDefaultConflictRules() {
    return {
      // Votes: Never overwrite, reject duplicates
      QueueOperationType.vote: const ConflictRule(
        operationType: QueueOperationType.vote,
        strategy: ConflictResolution.reject,
        allowDuplicates: false,
        timeout: Duration(seconds: 10),
      ),
      
      // Profile updates: Latest wins
      QueueOperationType.profileUpdate: const ConflictRule(
        operationType: QueueOperationType.profileUpdate,
        strategy: ConflictResolution.latestWins,
        allowDuplicates: false,
        timeout: Duration(seconds: 15),
      ),
      
      // Auth refresh: Always local wins (latest token)
      QueueOperationType.authRefresh: const ConflictRule(
        operationType: QueueOperationType.authRefresh,
        strategy: ConflictResolution.localWins,
        allowDuplicates: false,
        timeout: Duration(seconds: 5),
      ),
      
      // Notification acknowledgments: Allow duplicates, merge
      QueueOperationType.notificationAck: const ConflictRule(
        operationType: QueueOperationType.notificationAck,
        strategy: ConflictResolution.merge,
        allowDuplicates: true,
        timeout: Duration(seconds: 10),
      ),
      
      // Timetable events: Latest wins
      QueueOperationType.timetableEvent: const ConflictRule(
        operationType: QueueOperationType.timetableEvent,
        strategy: ConflictResolution.latestWins,
        allowDuplicates: false,
        timeout: Duration(seconds: 20),
      ),
    };
  }
}