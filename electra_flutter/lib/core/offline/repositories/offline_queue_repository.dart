import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../../error/failures.dart';
import '../../services/logger_service.dart';
import '../encryption/offline_encryption_service.dart';
import '../models/queue_item.dart';
import '../models/sync_config.dart';

/// Repository interface for offline queue operations
abstract class IOfflineQueueRepository {
  /// Add item to queue with encryption
  Future<Either<Failure, String>> enqueueItem({
    required QueueOperationType operationType,
    required Map<String, dynamic> payload,
    QueuePriority priority = QueuePriority.normal,
    Map<String, dynamic> metadata = const {},
    String? relatedEntityId,
    String? userId,
    DateTime? scheduledAt,
    DateTime? expiresAt,
  });

  /// Get next batch of items to sync
  Future<Either<Failure, List<QueueItem>>> getNextBatch({
    int batchSize = 10,
    List<QueueOperationType>? operationTypes,
    List<QueuePriority>? priorities,
  });

  /// Update item status
  Future<Either<Failure, void>> updateItemStatus(
    String itemUuid,
    QueueItemStatus status, {
    String? error,
    Map<String, dynamic>? responseData,
  });

  /// Mark item as synced
  Future<Either<Failure, void>> markAsSynced(String itemUuid);

  /// Delete item from queue
  Future<Either<Failure, void>> deleteItem(String itemUuid);

  /// Get queue statistics
  Future<Either<Failure, QueueStats>> getQueueStats();

  /// Clean expired items
  Future<Either<Failure, int>> cleanExpiredItems();

  /// Get items by status
  Future<Either<Failure, List<QueueItem>>> getItemsByStatus(
    QueueItemStatus status, {
    int? limit,
    int? offset,
  });

  /// Get items by operation type
  Future<Either<Failure, List<QueueItem>>> getItemsByType(
    QueueOperationType operationType, {
    int? limit,
    int? offset,
  });

  /// Get item by UUID
  Future<Either<Failure, QueueItem?>> getItemByUuid(String uuid);

  /// Clear all items
  Future<Either<Failure, void>> clearQueue();

  /// Get decrypted payload for an item
  Future<Either<Failure, Map<String, dynamic>>> getDecryptedPayload(
    QueueItem item,
  );
}

/// Implementation of offline queue repository using Isar database
@Singleton(as: IOfflineQueueRepository)
class OfflineQueueRepository implements IOfflineQueueRepository {
  final Isar _isar;
  final OfflineEncryptionService _encryptionService;
  final LoggerService _logger;
  final Uuid _uuid = const Uuid();
  final Random _random = Random.secure();

  OfflineQueueRepository(
    this._isar,
    this._encryptionService,
    this._logger,
  );

  @override
  Future<Either<Failure, String>> enqueueItem({
    required QueueOperationType operationType,
    required Map<String, dynamic> payload,
    QueuePriority priority = QueuePriority.normal,
    Map<String, dynamic> metadata = const {},
    String? relatedEntityId,
    String? userId,
    DateTime? scheduledAt,
    DateTime? expiresAt,
  }) async {
    try {
      // Generate unique identifier
      final uuid = _uuid.v4();
      final now = DateTime.now();

      // Encrypt payload
      final encryptedData = await _encryptionService.encryptData(payload);

      // Create queue item
      final queueItem = QueueItem(
        id: _generateIsarId(),
        uuid: uuid,
        operationType: operationType,
        priority: priority,
        status: QueueItemStatus.pending,
        encryptedPayload: encryptedData.encryptedPayload,
        encryptionIv: encryptedData.iv,
        payloadHash: encryptedData.payloadHash,
        metadata: Map<String, dynamic>.from(metadata)..addAll({
          'keyId': encryptedData.keyId,
          'timestamp': encryptedData.timestamp,
        }),
        createdAt: now,
        updatedAt: now,
        scheduledAt: scheduledAt,
        expiresAt: expiresAt ?? _getDefaultExpiration(operationType),
        relatedEntityId: relatedEntityId,
        userId: userId,
        deviceFingerprint: await _generateDeviceFingerprint(),
      );

      // Store in database
      await _isar.writeTxn(() async {
        await _isar.queueItems.put(queueItem);
      });

      _logger.info('Item queued successfully: $uuid ($operationType)');
      return Right(uuid);
    } catch (e) {
      _logger.error('Failed to enqueue item', e);
      return Left(CacheFailure(message: 'Failed to enqueue item: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<QueueItem>>> getNextBatch({
    int batchSize = 10,
    List<QueueOperationType>? operationTypes,
    List<QueuePriority>? priorities,
  }) async {
    try {
      final now = DateTime.now();
      
      var query = _isar.queueItems
          .where()
          .statusEqualTo(QueueItemStatus.pending)
          .and()
          .expiresAtIsNullOrGreaterThan(now)
          .and()
          .scheduledAtIsNullOrLessThan(now);

      // Apply operation type filter
      if (operationTypes != null && operationTypes.isNotEmpty) {
        query = query.and().anyOf(
          operationTypes,
          (q, operationType) => q.operationTypeEqualTo(operationType),
        );
      }

      // Apply priority filter
      if (priorities != null && priorities.isNotEmpty) {
        query = query.and().anyOf(
          priorities,
          (q, priority) => q.priorityEqualTo(priority),
        );
      }

      final items = await query
          .sortByPriorityDesc()
          .thenByCreatedAt()
          .limit(batchSize)
          .findAll();

      _logger.debug('Retrieved batch of ${items.length} items for sync');
      return Right(items);
    } catch (e) {
      _logger.error('Failed to get next batch', e);
      return Left(CacheFailure(message: 'Failed to get next batch: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateItemStatus(
    String itemUuid,
    QueueItemStatus status, {
    String? error,
    Map<String, dynamic>? responseData,
  }) async {
    try {
      final item = await _isar.queueItems
          .where()
          .uuidEqualTo(itemUuid)
          .findFirst();

      if (item == null) {
        return Left(NotFoundFailure(message: 'Queue item not found: $itemUuid'));
      }

      final now = DateTime.now();
      final updatedItem = item.copyWith(
        status: status,
        updatedAt: now,
        lastError: error,
        syncedAt: status == QueueItemStatus.synced ? now : item.syncedAt,
        retryCount: status == QueueItemStatus.failed 
            ? item.retryCount + 1 
            : item.retryCount,
        nextRetryAt: status == QueueItemStatus.failed
            ? _calculateNextRetry(item.retryCount + 1)
            : null,
        metadata: responseData != null
            ? Map<String, dynamic>.from(item.metadata)..addAll(responseData)
            : item.metadata,
      );

      await _isar.writeTxn(() async {
        await _isar.queueItems.put(updatedItem);
      });

      _logger.debug('Updated item status: $itemUuid -> $status');
      return const Right(null);
    } catch (e) {
      _logger.error('Failed to update item status', e);
      return Left(CacheFailure(message: 'Failed to update item status: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsSynced(String itemUuid) async {
    return updateItemStatus(itemUuid, QueueItemStatus.synced);
  }

  @override
  Future<Either<Failure, void>> deleteItem(String itemUuid) async {
    try {
      await _isar.writeTxn(() async {
        final deleted = await _isar.queueItems
            .where()
            .uuidEqualTo(itemUuid)
            .deleteFirst();
        
        if (!deleted) {
          throw Exception('Item not found: $itemUuid');
        }
      });

      _logger.debug('Deleted queue item: $itemUuid');
      return const Right(null);
    } catch (e) {
      _logger.error('Failed to delete item', e);
      return Left(CacheFailure(message: 'Failed to delete item: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, QueueStats>> getQueueStats() async {
    try {
      final totalItems = await _isar.queueItems.count();
      
      // Get counts by status
      final itemsByStatus = <QueueItemStatus, int>{};
      for (final status in QueueItemStatus.values) {
        final count = await _isar.queueItems
            .where()
            .statusEqualTo(status)
            .count();
        itemsByStatus[status] = count;
      }

      // Get counts by operation type
      final itemsByType = <QueueOperationType, int>{};
      for (final type in QueueOperationType.values) {
        final count = await _isar.queueItems
            .where()
            .operationTypeEqualTo(type)
            .count();
        itemsByType[type] = count;
      }

      // Get counts by priority
      final itemsByPriority = <QueuePriority, int>{};
      for (final priority in QueuePriority.values) {
        final count = await _isar.queueItems
            .where()
            .priorityEqualTo(priority)
            .count();
        itemsByPriority[priority] = count;
      }

      // Get oldest pending item
      final oldestPending = await _isar.queueItems
          .where()
          .statusEqualTo(QueueItemStatus.pending)
          .sortByCreatedAt()
          .findFirst();

      // Get most recent sync
      final mostRecentSync = await _isar.queueItems
          .where()
          .statusEqualTo(QueueItemStatus.synced)
          .sortBySyncedAtDesc()
          .findFirst();

      // Calculate success rate
      final syncedCount = itemsByStatus[QueueItemStatus.synced] ?? 0;
      final failedCount = itemsByStatus[QueueItemStatus.failed] ?? 0;
      final totalProcessed = syncedCount + failedCount;
      final successRate = totalProcessed > 0 ? (syncedCount / totalProcessed) * 100 : 0.0;

      final stats = QueueStats(
        totalItems: totalItems,
        itemsByStatus: itemsByStatus,
        itemsByType: itemsByType,
        itemsByPriority: itemsByPriority,
        oldestPendingItem: oldestPending?.createdAt,
        lastSyncTime: mostRecentSync?.syncedAt,
        successRate: successRate,
      );

      return Right(stats);
    } catch (e) {
      _logger.error('Failed to get queue stats', e);
      return Left(CacheFailure(message: 'Failed to get queue stats: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> cleanExpiredItems() async {
    try {
      final now = DateTime.now();
      final expiredItems = await _isar.queueItems
          .where()
          .expiresAtLessThan(now)
          .findAll();

      if (expiredItems.isEmpty) {
        return const Right(0);
      }

      await _isar.writeTxn(() async {
        await _isar.queueItems.deleteAll(expiredItems.map((e) => e.id).toList());
      });

      _logger.info('Cleaned ${expiredItems.length} expired queue items');
      return Right(expiredItems.length);
    } catch (e) {
      _logger.error('Failed to clean expired items', e);
      return Left(CacheFailure(message: 'Failed to clean expired items: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<QueueItem>>> getItemsByStatus(
    QueueItemStatus status, {
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _isar.queueItems
          .where()
          .statusEqualTo(status)
          .sortByCreatedAtDesc();

      if (offset != null) {
        query = query.offset(offset);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final items = await query.findAll();
      return Right(items);
    } catch (e) {
      _logger.error('Failed to get items by status', e);
      return Left(CacheFailure(message: 'Failed to get items by status: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<QueueItem>>> getItemsByType(
    QueueOperationType operationType, {
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _isar.queueItems
          .where()
          .operationTypeEqualTo(operationType)
          .sortByCreatedAtDesc();

      if (offset != null) {
        query = query.offset(offset);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final items = await query.findAll();
      return Right(items);
    } catch (e) {
      _logger.error('Failed to get items by type', e);
      return Left(CacheFailure(message: 'Failed to get items by type: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, QueueItem?>> getItemByUuid(String uuid) async {
    try {
      final item = await _isar.queueItems
          .where()
          .uuidEqualTo(uuid)
          .findFirst();
      
      return Right(item);
    } catch (e) {
      _logger.error('Failed to get item by UUID', e);
      return Left(CacheFailure(message: 'Failed to get item by UUID: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> clearQueue() async {
    try {
      await _isar.writeTxn(() async {
        await _isar.queueItems.clear();
      });

      _logger.info('Queue cleared successfully');
      return const Right(null);
    } catch (e) {
      _logger.error('Failed to clear queue', e);
      return Left(CacheFailure(message: 'Failed to clear queue: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDecryptedPayload(
    QueueItem item,
  ) async {
    try {
      final encryptedData = EncryptedData(
        encryptedPayload: item.encryptedPayload,
        iv: item.encryptionIv,
        payloadHash: item.payloadHash,
        keyId: item.metadata['keyId'] as String? ?? 'default',
        timestamp: item.metadata['timestamp'] as int? ?? 0,
      );

      final decryptedPayload = await _encryptionService.decryptData(encryptedData);
      return Right(decryptedPayload);
    } catch (e) {
      _logger.error('Failed to decrypt payload for item ${item.uuid}', e);
      return Left(SecurityFailure(message: 'Failed to decrypt payload: ${e.toString()}'));
    }
  }

  // Private helper methods

  int _generateIsarId() {
    return _random.nextInt(1 << 63);
  }

  DateTime _getDefaultExpiration(QueueOperationType operationType) {
    final now = DateTime.now();
    switch (operationType) {
      case QueueOperationType.vote:
        return now.add(const Duration(days: 7)); // Votes expire after 1 week
      case QueueOperationType.authRefresh:
        return now.add(const Duration(hours: 1)); // Auth tokens expire quickly
      case QueueOperationType.profileUpdate:
        return now.add(const Duration(days: 30)); // Profile updates expire after 1 month
      case QueueOperationType.notificationAck:
        return now.add(const Duration(days: 3)); // Notification acks expire after 3 days
      case QueueOperationType.timetableEvent:
        return now.add(const Duration(days: 14)); // Timetable events expire after 2 weeks
    }
  }

  DateTime _calculateNextRetry(int retryCount) {
    // Exponential backoff with jitter
    final baseDelayMs = 1000; // 1 second
    final maxDelayMs = 30 * 60 * 1000; // 30 minutes
    final multiplier = 2.0;
    
    final delayMs = (baseDelayMs * pow(multiplier, retryCount - 1)).toInt();
    final cappedDelayMs = delayMs.clamp(baseDelayMs, maxDelayMs);
    
    // Add jitter (±10%)
    final jitterMs = (cappedDelayMs * 0.1 * (_random.nextDouble() - 0.5)).toInt();
    final finalDelayMs = cappedDelayMs + jitterMs;
    
    return DateTime.now().add(Duration(milliseconds: finalDelayMs));
  }

  Future<String> _generateDeviceFingerprint() async {
    // Simple device fingerprint based on timestamp and random value
    // In production, this could include device info, screen resolution, etc.
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomValue = _random.nextInt(1000000);
    final fingerprint = '$timestamp-$randomValue';
    return fingerprint.substring(0, 16); // Keep it short
  }
}