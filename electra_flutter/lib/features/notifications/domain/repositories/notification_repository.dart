import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../entities/notification.dart';

/// Repository interface for notification operations
///
/// Defines all notification-related operations including CRUD operations,
/// push notification handling, and offline synchronization.
abstract class NotificationRepository {
  /// Get all notifications for the current user
  Future<Either<Failure, List<Notification>>> getNotifications({
    int? limit,
    int? offset,
    NotificationType? type,
    NotificationStatus? status,
    NotificationPriority? priority,
  });

  /// Get notification by ID
  Future<Either<Failure, Notification>> getNotificationById(String id);

  /// Mark notification as read
  Future<Either<Failure, Notification>> markAsRead(String id);

  /// Mark notification as dismissed
  Future<Either<Failure, Notification>> markAsDismissed(String id);

  /// Mark all notifications as read
  Future<Either<Failure, void>> markAllAsRead();

  /// Delete notification
  Future<Either<Failure, void>> deleteNotification(String id);

  /// Clear all notifications
  Future<Either<Failure, void>> clearAllNotifications();

  /// Get notification summary/counts
  Future<Either<Failure, NotificationSummary>> getNotificationSummary();

  /// Subscribe to push notifications
  Future<Either<Failure, String>> subscribeToPushNotifications();

  /// Unsubscribe from push notifications
  Future<Either<Failure, void>> unsubscribeFromPushNotifications();

  /// Update push notification preferences
  Future<Either<Failure, void>> updateNotificationPreferences(
    Map<NotificationType, bool> preferences,
  );

  /// Get push notification preferences
  Future<Either<Failure, Map<NotificationType, bool>>> getNotificationPreferences();

  /// Handle incoming push notification
  Future<Either<Failure, Notification>> handlePushNotification(
    Map<String, dynamic> payload,
  );

  /// Send notification (for admin/system use)
  Future<Either<Failure, Notification>> sendNotification({
    required List<String> userIds,
    required NotificationType type,
    required NotificationPriority priority,
    required String title,
    required String message,
    String? imageUrl,
    String? deepLinkUrl,
    List<NotificationAction>? actions,
    Map<String, dynamic>? metadata,
    DateTime? expiresAt,
    bool sendPush = true,
  });

  /// Get cached notifications (offline support)
  Future<Either<Failure, List<Notification>>> getCachedNotifications();

  /// Sync notifications with server
  Future<Either<Failure, void>> syncNotifications();

  /// Queue notification for offline delivery
  Future<Either<Failure, void>> queueOfflineNotification(
    Map<String, dynamic> notificationData,
  );

  /// Get queued offline notifications
  Future<Either<Failure, List<Map<String, dynamic>>>> getQueuedNotifications();

  /// Clear queued notifications after successful sync
  Future<Either<Failure, void>> clearQueuedNotifications();
}