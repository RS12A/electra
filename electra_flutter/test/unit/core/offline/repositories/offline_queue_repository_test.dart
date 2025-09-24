import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:isar/isar.dart';
import 'package:dartz/dartz.dart';

import 'package:electra_flutter/core/offline/repositories/offline_queue_repository.dart';
import 'package:electra_flutter/core/offline/encryption/offline_encryption_service.dart';
import 'package:electra_flutter/core/offline/models/queue_item.dart';
import 'package:electra_flutter/core/services/logger_service.dart';
import 'package:electra_flutter/core/error/failures.dart';

@GenerateMocks([Isar, OfflineEncryptionService, LoggerService])
import 'offline_queue_repository_test.mocks.dart';

void main() {
  late OfflineQueueRepository repository;
  late MockIsar mockIsar;
  late MockOfflineEncryptionService mockEncryptionService;
  late MockLoggerService mockLogger;

  setUp(() {
    mockIsar = MockIsar();
    mockEncryptionService = MockOfflineEncryptionService();
    mockLogger = MockLoggerService();
    
    repository = OfflineQueueRepository(
      mockIsar,
      mockEncryptionService,
      mockLogger,
    );
  });

  group('OfflineQueueRepository', () {
    group('enqueueItem', () {
      test('should enqueue item successfully with encryption', () async {
        // Arrange
        final payload = {'test': 'data'};
        final encryptedData = EncryptedData(
          encryptedPayload: 'encrypted_payload',
          iv: 'test_iv',
          payloadHash: 'test_hash',
          keyId: 'test_key',
          timestamp: 1234567890,
        );

        when(mockEncryptionService.encryptData(payload))
            .thenAnswer((_) async => encryptedData);

        when(mockIsar.writeTxn(any)).thenAnswer((_) async => {});

        // Act
        final result = await repository.enqueueItem(
          operationType: QueueOperationType.vote,
          payload: payload,
          priority: QueuePriority.high,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (itemId) => expect(itemId, isA<String>()),
        );

        verify(mockEncryptionService.encryptData(payload)).called(1);
        verify(mockIsar.writeTxn(any)).called(1);
      });

      test('should handle encryption failure', () async {
        // Arrange
        final payload = {'test': 'data'};
        
        when(mockEncryptionService.encryptData(payload))
            .thenThrow(Exception('Encryption failed'));

        // Act
        final result = await repository.enqueueItem(
          operationType: QueueOperationType.vote,
          payload: payload,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (itemId) => fail('Should fail'),
        );
      });
    });

    group('getNextBatch', () {
      test('should return pending items in correct order', () async {
        // Arrange
        final mockQuery = MockQueryBuilder<QueueItem>();
        final items = [
          QueueItem(
            id: 1,
            uuid: 'uuid1',
            operationType: QueueOperationType.vote,
            status: QueueItemStatus.pending,
            encryptedPayload: 'payload1',
            encryptionIv: 'iv1',
            payloadHash: 'hash1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          QueueItem(
            id: 2,
            uuid: 'uuid2',
            operationType: QueueOperationType.authRefresh,
            status: QueueItemStatus.pending,
            encryptedPayload: 'payload2',
            encryptionIv: 'iv2',
            payloadHash: 'hash2',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockIsar.queueItems).thenReturn(mockQuery as IsarCollection<QueueItem>);
        when(mockQuery.where()).thenReturn(mockQuery);
        when(mockQuery.statusEqualTo(QueueItemStatus.pending))
            .thenReturn(mockQuery);
        when(mockQuery.and()).thenReturn(mockQuery);
        when(mockQuery.expiresAtIsNullOrGreaterThan(any))
            .thenReturn(mockQuery);
        when(mockQuery.scheduledAtIsNullOrLessThan(any))
            .thenReturn(mockQuery);
        when(mockQuery.sortByPriorityDesc()).thenReturn(mockQuery);
        when(mockQuery.thenByCreatedAt()).thenReturn(mockQuery);
        when(mockQuery.limit(10)).thenReturn(mockQuery);
        when(mockQuery.findAll()).thenAnswer((_) async => items);

        // Act
        final result = await repository.getNextBatch(batchSize: 10);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (batchItems) {
            expect(batchItems.length, 2);
            expect(batchItems[0].operationType, QueueOperationType.vote);
            expect(batchItems[1].operationType, QueueOperationType.authRefresh);
          },
        );
      });
    });

    group('updateItemStatus', () {
      test('should update item status successfully', () async {
        // Arrange
        final item = QueueItem(
          id: 1,
          uuid: 'test_uuid',
          operationType: QueueOperationType.vote,
          status: QueueItemStatus.pending,
          encryptedPayload: 'payload',
          encryptionIv: 'iv',
          payloadHash: 'hash',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final mockQuery = MockQueryBuilder<QueueItem>();
        when(mockIsar.queueItems).thenReturn(mockQuery as IsarCollection<QueueItem>);
        when(mockQuery.where()).thenReturn(mockQuery);
        when(mockQuery.uuidEqualTo('test_uuid')).thenReturn(mockQuery);
        when(mockQuery.findFirst()).thenAnswer((_) async => item);
        when(mockIsar.writeTxn(any)).thenAnswer((_) async => {});

        // Act
        final result = await repository.updateItemStatus(
          'test_uuid',
          QueueItemStatus.synced,
        );

        // Assert
        expect(result.isRight(), true);
        verify(mockIsar.writeTxn(any)).called(1);
      });

      test('should handle item not found', () async {
        // Arrange
        final mockQuery = MockQueryBuilder<QueueItem>();
        when(mockIsar.queueItems).thenReturn(mockQuery as IsarCollection<QueueItem>);
        when(mockQuery.where()).thenReturn(mockQuery);
        when(mockQuery.uuidEqualTo('nonexistent_uuid')).thenReturn(mockQuery);
        when(mockQuery.findFirst()).thenAnswer((_) async => null);

        // Act
        final result = await repository.updateItemStatus(
          'nonexistent_uuid',
          QueueItemStatus.synced,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (success) => fail('Should fail'),
        );
      });
    });

    group('getQueueStats', () {
      test('should return correct queue statistics', () async {
        // Arrange
        when(mockIsar.queueItems.count()).thenAnswer((_) async => 5);
        
        // Mock status counts
        for (final status in QueueItemStatus.values) {
          final mockQuery = MockQueryBuilder<QueueItem>();
          when(mockIsar.queueItems).thenReturn(mockQuery as IsarCollection<QueueItem>);
          when(mockQuery.where()).thenReturn(mockQuery);
          when(mockQuery.statusEqualTo(status)).thenReturn(mockQuery);
          when(mockQuery.count()).thenAnswer((_) async => 1);
        }

        // Mock operation type counts
        for (final type in QueueOperationType.values) {
          final mockQuery = MockQueryBuilder<QueueItem>();
          when(mockIsar.queueItems).thenReturn(mockQuery as IsarCollection<QueueItem>);
          when(mockQuery.where()).thenReturn(mockQuery);
          when(mockQuery.operationTypeEqualTo(type)).thenReturn(mockQuery);
          when(mockQuery.count()).thenAnswer((_) async => 1);
        }

        // Mock priority counts
        for (final priority in QueuePriority.values) {
          final mockQuery = MockQueryBuilder<QueueItem>();
          when(mockIsar.queueItems).thenReturn(mockQuery as IsarCollection<QueueItem>);
          when(mockQuery.where()).thenReturn(mockQuery);
          when(mockQuery.priorityEqualTo(priority)).thenReturn(mockQuery);
          when(mockQuery.count()).thenAnswer((_) async => 1);
        }

        // Mock oldest pending item
        final mockPendingQuery = MockQueryBuilder<QueueItem>();
        when(mockIsar.queueItems).thenReturn(mockPendingQuery as IsarCollection<QueueItem>);
        when(mockPendingQuery.where()).thenReturn(mockPendingQuery);
        when(mockPendingQuery.statusEqualTo(QueueItemStatus.pending))
            .thenReturn(mockPendingQuery);
        when(mockPendingQuery.sortByCreatedAt()).thenReturn(mockPendingQuery);
        when(mockPendingQuery.findFirst()).thenAnswer((_) async => null);

        // Mock most recent sync
        final mockSyncedQuery = MockQueryBuilder<QueueItem>();
        when(mockIsar.queueItems).thenReturn(mockSyncedQuery as IsarCollection<QueueItem>);
        when(mockSyncedQuery.where()).thenReturn(mockSyncedQuery);
        when(mockSyncedQuery.statusEqualTo(QueueItemStatus.synced))
            .thenReturn(mockSyncedQuery);
        when(mockSyncedQuery.sortBySyncedAtDesc()).thenReturn(mockSyncedQuery);
        when(mockSyncedQuery.findFirst()).thenAnswer((_) async => null);

        // Act
        final result = await repository.getQueueStats();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (stats) {
            expect(stats.totalItems, 5);
            expect(stats.itemsByStatus.length, QueueItemStatus.values.length);
            expect(stats.itemsByType.length, QueueOperationType.values.length);
            expect(stats.itemsByPriority.length, QueuePriority.values.length);
          },
        );
      });
    });

    group('cleanExpiredItems', () {
      test('should remove expired items', () async {
        // Arrange
        final expiredItems = [
          QueueItem(
            id: 1,
            uuid: 'expired1',
            operationType: QueueOperationType.vote,
            status: QueueItemStatus.pending,
            encryptedPayload: 'payload',
            encryptionIv: 'iv',
            payloadHash: 'hash',
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
            updatedAt: DateTime.now().subtract(const Duration(days: 10)),
            expiresAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];

        final mockQuery = MockQueryBuilder<QueueItem>();
        when(mockIsar.queueItems).thenReturn(mockQuery as IsarCollection<QueueItem>);
        when(mockQuery.where()).thenReturn(mockQuery);
        when(mockQuery.expiresAtLessThan(any)).thenReturn(mockQuery);
        when(mockQuery.findAll()).thenAnswer((_) async => expiredItems);
        when(mockIsar.writeTxn(any)).thenAnswer((_) async => {});

        // Act
        final result = await repository.cleanExpiredItems();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (count) => expect(count, 1),
        );

        verify(mockIsar.writeTxn(any)).called(1);
      });
    });

    group('getDecryptedPayload', () {
      test('should decrypt payload successfully', () async {
        // Arrange
        final item = QueueItem(
          id: 1,
          uuid: 'test_uuid',
          operationType: QueueOperationType.vote,
          status: QueueItemStatus.pending,
          encryptedPayload: 'encrypted_payload',
          encryptionIv: 'test_iv',
          payloadHash: 'test_hash',
          metadata: {
            'keyId': 'test_key',
            'timestamp': 1234567890,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final encryptedData = EncryptedData(
          encryptedPayload: 'encrypted_payload',
          iv: 'test_iv',
          payloadHash: 'test_hash',
          keyId: 'test_key',
          timestamp: 1234567890,
        );

        final decryptedPayload = {'test': 'data'};

        when(mockEncryptionService.decryptData(encryptedData))
            .thenAnswer((_) async => decryptedPayload);

        // Act
        final result = await repository.getDecryptedPayload(item);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (payload) => expect(payload, decryptedPayload),
        );

        verify(mockEncryptionService.decryptData(any)).called(1);
      });

      test('should handle decryption failure', () async {
        // Arrange
        final item = QueueItem(
          id: 1,
          uuid: 'test_uuid',
          operationType: QueueOperationType.vote,
          status: QueueItemStatus.pending,
          encryptedPayload: 'encrypted_payload',
          encryptionIv: 'test_iv',
          payloadHash: 'test_hash',
          metadata: {
            'keyId': 'test_key',
            'timestamp': 1234567890,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockEncryptionService.decryptData(any))
            .thenThrow(Exception('Decryption failed'));

        // Act
        final result = await repository.getDecryptedPayload(item);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<SecurityFailure>()),
          (payload) => fail('Should fail'),
        );
      });
    });
  });
}

// Mock query builder for Isar
class MockQueryBuilder<T> extends Mock implements QueryBuilder<T, T, QWhere> {}