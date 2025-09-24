import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

/// Use case for getting all notifications
class GetNotifications extends UseCase<List<Notification>, GetNotificationsParams> {
  const GetNotifications(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, List<Notification>>> call(
    GetNotificationsParams params,
  ) async {
    return await repository.getNotifications(
      limit: params.limit,
      offset: params.offset,
      type: params.type,
      status: params.status,
      priority: params.priority,
    );
  }
}

/// Parameters for getting notifications
class GetNotificationsParams {
  const GetNotificationsParams({
    this.limit,
    this.offset,
    this.type,
    this.status,
    this.priority,
  });

  final int? limit;
  final int? offset;
  final NotificationType? type;
  final NotificationStatus? status;
  final NotificationPriority? priority;
}

/// Use case for getting a single notification by ID
class GetNotificationById extends UseCase<Notification, StringParams> {
  const GetNotificationById(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, Notification>> call(StringParams params) async {
    return await repository.getNotificationById(params.value);
  }
}

/// Use case for marking notification as read
class MarkNotificationAsRead extends UseCase<Notification, StringParams> {
  const MarkNotificationAsRead(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, Notification>> call(StringParams params) async {
    return await repository.markAsRead(params.value);
  }
}

/// Use case for marking notification as dismissed
class MarkNotificationAsDismissed extends UseCase<Notification, StringParams> {
  const MarkNotificationAsDismissed(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, Notification>> call(StringParams params) async {
    return await repository.markAsDismissed(params.value);
  }
}

/// Use case for marking all notifications as read
class MarkAllNotificationsAsRead extends NoParamsUseCase<void> {
  const MarkAllNotificationsAsRead(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, void>> call() async {
    return await repository.markAllAsRead();
  }
}

/// Use case for deleting a notification
class DeleteNotification extends UseCase<void, StringParams> {
  const DeleteNotification(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, void>> call(StringParams params) async {
    return await repository.deleteNotification(params.value);
  }
}

/// Use case for clearing all notifications
class ClearAllNotifications extends NoParamsUseCase<void> {
  const ClearAllNotifications(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, void>> call() async {
    return await repository.clearAllNotifications();
  }
}

/// Use case for getting notification summary
class GetNotificationSummary extends NoParamsUseCase<NotificationSummary> {
  const GetNotificationSummary(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, NotificationSummary>> call() async {
    return await repository.getNotificationSummary();
  }
}

/// Use case for subscribing to push notifications
class SubscribeToPushNotifications extends NoParamsUseCase<String> {
  const SubscribeToPushNotifications(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, String>> call() async {
    return await repository.subscribeToPushNotifications();
  }
}

/// Use case for unsubscribing from push notifications
class UnsubscribeFromPushNotifications extends NoParamsUseCase<void> {
  const UnsubscribeFromPushNotifications(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, void>> call() async {
    return await repository.unsubscribeFromPushNotifications();
  }
}

/// Use case for updating notification preferences
class UpdateNotificationPreferences extends UseCase<void, NotificationPreferencesParams> {
  const UpdateNotificationPreferences(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, void>> call(NotificationPreferencesParams params) async {
    return await repository.updateNotificationPreferences(params.preferences);
  }
}

/// Parameters for notification preferences
class NotificationPreferencesParams {
  const NotificationPreferencesParams(this.preferences);

  final Map<NotificationType, bool> preferences;
}

/// Use case for getting notification preferences
class GetNotificationPreferences extends NoParamsUseCase<Map<NotificationType, bool>> {
  const GetNotificationPreferences(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, Map<NotificationType, bool>>> call() async {
    return await repository.getNotificationPreferences();
  }
}

/// Use case for handling push notifications
class HandlePushNotification extends UseCase<Notification, PushNotificationParams> {
  const HandlePushNotification(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, Notification>> call(PushNotificationParams params) async {
    return await repository.handlePushNotification(params.payload);
  }
}

/// Parameters for push notification handling
class PushNotificationParams {
  const PushNotificationParams(this.payload);

  final Map<String, dynamic> payload;
}

/// Use case for sending notifications (admin/system)
class SendNotification extends UseCase<Notification, SendNotificationParams> {
  const SendNotification(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, Notification>> call(SendNotificationParams params) async {
    return await repository.sendNotification(
      userIds: params.userIds,
      type: params.type,
      priority: params.priority,
      title: params.title,
      message: params.message,
      imageUrl: params.imageUrl,
      deepLinkUrl: params.deepLinkUrl,
      actions: params.actions,
      metadata: params.metadata,
      expiresAt: params.expiresAt,
      sendPush: params.sendPush,
    );
  }
}

/// Parameters for sending notifications
class SendNotificationParams {
  const SendNotificationParams({
    required this.userIds,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    this.imageUrl,
    this.deepLinkUrl,
    this.actions,
    this.metadata,
    this.expiresAt,
    this.sendPush = true,
  });

  final List<String> userIds;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final String? imageUrl;
  final String? deepLinkUrl;
  final List<NotificationAction>? actions;
  final Map<String, dynamic>? metadata;
  final DateTime? expiresAt;
  final bool sendPush;
}

/// Use case for syncing notifications
class SyncNotifications extends NoParamsUseCase<void> {
  const SyncNotifications(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, void>> call() async {
    return await repository.syncNotifications();
  }
}

/// Use case for getting cached notifications
class GetCachedNotifications extends NoParamsUseCase<List<Notification>> {
  const GetCachedNotifications(this.repository);

  final NotificationRepository repository;

  @override
  Future<Either<Failure, List<Notification>>> call() async {
    return await repository.getCachedNotifications();
  }
}