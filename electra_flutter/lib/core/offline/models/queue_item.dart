import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

import '../../error/failures.dart';

part 'queue_item.freezed.dart';
part 'queue_item.g.dart';

/// Priority levels for queue items
enum QueuePriority {
  low(0),
  normal(1), 
  high(2),
  critical(3);

  const QueuePriority(this.value);
  final int value;
}

/// Types of operations that can be queued
enum QueueOperationType {
  vote('vote'),
  authRefresh('auth_refresh'),
  profileUpdate('profile_update'),
  notificationAck('notification_ack'),
  timetableEvent('timetable_event');

  const QueueOperationType(this.value);
  final String value;
}

/// Status of a queue item
enum QueueItemStatus {
  pending('pending'),
  processing('processing'),
  synced('synced'),
  failed('failed'),
  expired('expired');

  const QueueItemStatus(this.value);
  final String value;
}

/// Queue item entity for offline operations
///
/// Represents a single operation queued for synchronization when connection
/// is restored. Includes encryption, retry logic, and priority handling.
@freezed
@Collection()
class QueueItem with _$QueueItem {
  const factory QueueItem({
    /// Unique identifier for the queue item
    @Id() required int id,
    
    /// Unique UUID for the queue item
    @Index() required String uuid,
    
    /// Type of operation being queued
    @Enumerated(EnumType.name) required QueueOperationType operationType,
    
    /// Priority level for processing order
    @Enumerated(EnumType.name) @Default(QueuePriority.normal) QueuePriority priority,
    
    /// Current status of the queue item
    @Enumerated(EnumType.name) @Default(QueueItemStatus.pending) QueueItemStatus status,
    
    /// Encrypted payload data as JSON string
    required String encryptedPayload,
    
    /// Encryption initialization vector
    required String encryptionIv,
    
    /// Hash of the original payload for integrity verification
    required String payloadHash,
    
    /// Metadata for the operation (unencrypted)
    @Default({}) Map<String, dynamic> metadata,
    
    /// When the item was created and queued
    required DateTime createdAt,
    
    /// When the item was last updated
    required DateTime updatedAt,
    
    /// When the item should be processed (for scheduling)
    DateTime? scheduledAt,
    
    /// When the item was successfully synced
    DateTime? syncedAt,
    
    /// Number of sync attempts made
    @Default(0) int retryCount,
    
    /// Maximum number of retry attempts allowed
    @Default(5) int maxRetries,
    
    /// Next retry attempt timestamp
    DateTime? nextRetryAt,
    
    /// Last error message if sync failed
    String? lastError,
    
    /// Item expires after this time (to prevent stale data)
    DateTime? expiresAt,
    
    /// Related entity ID (e.g., election ID for votes)
    String? relatedEntityId,
    
    /// User ID associated with this operation
    String? userId,
    
    /// Device fingerprint for security
    String? deviceFingerprint,
  }) = _QueueItem;

  factory QueueItem.fromJson(Map<String, dynamic> json) =>
      _$QueueItemFromJson(json);
}

/// Conflict resolution strategy
enum ConflictResolution {
  /// Keep server version (reject local changes)
  serverWins,
  
  /// Keep local version (overwrite server)
  localWins,
  
  /// Use latest timestamp
  latestWins,
  
  /// Merge changes if possible
  merge,
  
  /// Create duplicate entry
  duplicate,
  
  /// Reject operation (e.g., for duplicate votes)
  reject;
}

/// Conflict resolution rule for specific operation types
@freezed
class ConflictRule with _$ConflictRule {
  const factory ConflictRule({
    /// Operation type this rule applies to
    required QueueOperationType operationType,
    
    /// Resolution strategy to use
    required ConflictResolution strategy,
    
    /// Additional parameters for resolution
    @Default({}) Map<String, dynamic> parameters,
    
    /// Whether to allow duplicate operations
    @Default(false) bool allowDuplicates,
    
    /// Timeout for conflict resolution
    @Default(Duration(seconds: 30)) Duration timeout,
  }) = _ConflictRule;

  factory ConflictRule.fromJson(Map<String, dynamic> json) =>
      _$ConflictRuleFromJson(json);
}

/// Sync batch for efficient processing
@freezed
class SyncBatch with _$SyncBatch {
  const factory SyncBatch({
    /// Unique batch identifier
    required String batchId,
    
    /// Items in this batch
    required List<QueueItem> items,
    
    /// Batch creation time
    required DateTime createdAt,
    
    /// Batch processing status
    @Default(QueueItemStatus.pending) QueueItemStatus status,
    
    /// Batch size limit
    @Default(10) int maxSize,
    
    /// Batch timeout
    @Default(Duration(minutes: 5)) Duration timeout,
  }) = _SyncBatch;

  factory SyncBatch.fromJson(Map<String, dynamic> json) =>
      _$SyncBatchFromJson(json);
}

/// Sync result for a queue item
@freezed
class SyncResult with _$SyncResult {
  const factory SyncResult({
    /// Queue item that was synced
    required QueueItem item,
    
    /// Whether sync was successful
    required bool success,
    
    /// Error details if sync failed
    Failure? error,
    
    /// Response data from server
    Map<String, dynamic>? responseData,
    
    /// Time taken for sync operation
    required Duration duration,
    
    /// Whether retry is recommended
    @Default(false) bool shouldRetry,
    
    /// Next retry delay if applicable
    Duration? retryDelay,
  }) = _SyncResult;

  factory SyncResult.fromJson(Map<String, dynamic> json) =>
      _$SyncResultFromJson(json);
}

/// Queue statistics for monitoring
@freezed
class QueueStats with _$QueueStats {
  const factory QueueStats({
    /// Total items in queue
    required int totalItems,
    
    /// Items by status
    required Map<QueueItemStatus, int> itemsByStatus,
    
    /// Items by operation type
    required Map<QueueOperationType, int> itemsByType,
    
    /// Items by priority
    required Map<QueuePriority, int> itemsByPriority,
    
    /// Oldest pending item timestamp
    DateTime? oldestPendingItem,
    
    /// Most recent sync timestamp
    DateTime? lastSyncTime,
    
    /// Average sync time
    Duration? averageSyncTime,
    
    /// Success rate percentage
    @Default(0.0) double successRate,
    
    /// Items expired and removed
    @Default(0) int expiredItems,
  }) = _QueueStats;

  factory QueueStats.fromJson(Map<String, dynamic> json) =>
      _$QueueStatsFromJson(json);
}