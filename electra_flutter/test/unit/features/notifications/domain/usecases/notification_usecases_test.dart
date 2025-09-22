/// Unit tests for notification use cases
/// 
/// These tests verify the business logic of notification operations
/// using mock dependencies and test data.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';

import 'package:electra_flutter/features/notifications/domain/entities/notification.dart';
import 'package:electra_flutter/features/notifications/domain/repositories/notification_repository.dart';
import 'package:electra_flutter/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:electra_flutter/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:electra_flutter/core/error/failures.dart';

import 'notification_usecases_test.mocks.dart';

@GenerateMocks([NotificationRepository])
void main() {
  late GetNotificationsUseCase getNotificationsUseCase;
  late MarkNotificationReadUseCase markNotificationReadUseCase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    getNotificationsUseCase = GetNotificationsUseCase(mockRepository);
    markNotificationReadUseCase = MarkNotificationReadUseCase(mockRepository);
  });

  group('GetNotificationsUseCase', () {
    final testNotifications = [
      Notification(
        id: '1',
        title: 'Test Notification 1',
        body: 'This is a test notification',
        type: NotificationType.election,
        priority: NotificationPriority.normal,
        userId: 'user1',
        createdAt: DateTime.now(),
      ),
      Notification(
        id: '2',
        title: 'Test Notification 2',
        body: 'Another test notification',
        type: NotificationType.reminder,
        priority: NotificationPriority.high,
        userId: 'user1',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
    ];

    test('should get notifications from repository', () async {
      // arrange
      when(mockRepository.getNotifications(
        page: anyNamed('page'),
        limit: anyNamed('limit'),
        type: anyNamed('type'),
        isRead: anyNamed('isRead'),
        forceRefresh: anyNamed('forceRefresh'),
      )).thenAnswer((_) async => Right(testNotifications));

      const params = GetNotificationsParams(
        page: 1,
        limit: 20,
        forceRefresh: false,
      );

      // act
      final result = await getNotificationsUseCase(params);

      // assert
      expect(result, isA<Right<Failure, List<Notification>>>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (notifications) {
          expect(notifications, equals(testNotifications));
          expect(notifications.length, equals(2));
        },
      );

      verify(mockRepository.getNotifications(
        page: 1,
        limit: 20,
        forceRefresh: false,
      )).called(1);
    });

    test('should return failure when repository fails', () async {
      // arrange
      when(mockRepository.getNotifications(
        page: anyNamed('page'),
        limit: anyNamed('limit'),
        type: anyNamed('type'),
        isRead: anyNamed('isRead'),
        forceRefresh: anyNamed('forceRefresh'),
      )).thenAnswer((_) async => const Left(NetworkFailure(
        message: 'Network error',
      )));

      const params = GetNotificationsParams();

      // act
      final result = await getNotificationsUseCase(params);

      // assert
      expect(result, isA<Left<Failure, List<Notification>>>());
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, equals('Network error'));
        },
        (notifications) => fail('Should not return success'),
      );
    });

    test('should filter notifications by type', () async {
      // arrange
      final electionNotifications = testNotifications
          .where((n) => n.type == NotificationType.election)
          .toList();

      when(mockRepository.getNotifications(
        page: anyNamed('page'),
        limit: anyNamed('limit'),
        type: NotificationType.election,
        isRead: anyNamed('isRead'),
        forceRefresh: anyNamed('forceRefresh'),
      )).thenAnswer((_) async => Right(electionNotifications));

      const params = GetNotificationsParams(
        type: NotificationType.election,
      );

      // act
      final result = await getNotificationsUseCase(params);

      // assert
      result.fold(
        (failure) => fail('Should not return failure'),
        (notifications) {
          expect(notifications.length, equals(1));
          expect(notifications.first.type, equals(NotificationType.election));
        },
      );
    });
  });

  group('MarkNotificationReadUseCase', () {
    final testNotification = Notification(
      id: '1',
      title: 'Test Notification',
      body: 'This is a test notification',
      type: NotificationType.election,
      priority: NotificationPriority.normal,
      userId: 'user1',
      createdAt: DateTime.now(),
    );

    test('should mark notification as read', () async {
      // arrange
      final readNotification = testNotification.markAsRead();
      when(mockRepository.markAsRead('1'))
          .thenAnswer((_) async => Right(readNotification));

      // act
      final result = await markNotificationReadUseCase('1');

      // assert
      expect(result, isA<Right<Failure, Notification>>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (notification) {
          expect(notification.id, equals('1'));
          expect(notification.isRead, isTrue);
          expect(notification.readAt, isNotNull);
        },
      );

      verify(mockRepository.markAsRead('1')).called(1);
    });

    test('should return failure when repository fails', () async {
      // arrange
      when(mockRepository.markAsRead('1'))
          .thenAnswer((_) async => const Left(ServerFailure(
        message: 'Server error',
      )));

      // act
      final result = await markNotificationReadUseCase('1');

      // assert
      expect(result, isA<Left<Failure, Notification>>());
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Server error'));
        },
        (notification) => fail('Should not return success'),
      );
    });

    test('should mark multiple notifications as read', () async {
      // arrange
      final notificationIds = ['1', '2'];
      final readNotifications = testNotifications.map((n) => n.markAsRead()).toList();

      when(mockRepository.markMultipleAsRead(notificationIds))
          .thenAnswer((_) async => Right(readNotifications));

      // act
      final result = await markNotificationReadUseCase.markMultiple(notificationIds);

      // assert
      expect(result, isA<Right<Failure, List<Notification>>>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (notifications) {
          expect(notifications.length, equals(2));
          expect(notifications.every((n) => n.isRead), isTrue);
        },
      );

      verify(mockRepository.markMultipleAsRead(notificationIds)).called(1);
    });
  });
}