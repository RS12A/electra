import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../models/notification_model.dart';
import '../../domain/entities/notification.dart';

/// Abstract remote data source for notifications API
abstract class NotificationRemoteDataSource {
  /// Get notifications from remote API
  Future<List<NotificationModel>> getNotifications({
    int? limit,
    int? offset,
    NotificationType? type,
    NotificationStatus? status,
    NotificationPriority? priority,
  });

  /// Get notification by ID from remote API
  Future<NotificationModel> getNotificationById(String id);

  /// Mark notification as read on remote API
  Future<NotificationModel> markAsRead(String id);

  /// Mark notification as dismissed on remote API
  Future<NotificationModel> markAsDismissed(String id);

  /// Mark all notifications as read on remote API
  Future<void> markAllAsRead();

  /// Delete notification on remote API
  Future<void> deleteNotification(String id);

  /// Clear all notifications on remote API
  Future<void> clearAllNotifications();

  /// Get notification summary from remote API
  Future<NotificationSummaryModel> getNotificationSummary();

  /// Subscribe to push notifications on remote API
  Future<String> subscribeToPushNotifications(String fcmToken);

  /// Unsubscribe from push notifications on remote API
  Future<void> unsubscribeFromPushNotifications();

  /// Update notification preferences on remote API
  Future<void> updateNotificationPreferences(
    Map<NotificationType, bool> preferences,
  );

  /// Get notification preferences from remote API
  Future<Map<NotificationType, bool>> getNotificationPreferences();

  /// Send notification via remote API (admin/system use)
  Future<NotificationModel> sendNotification({
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
}

/// Abstract local data source for notifications caching
abstract class NotificationLocalDataSource {
  /// Get cached notifications
  Future<List<NotificationModel>> getCachedNotifications({
    NotificationType? type,
    NotificationStatus? status,
    NotificationPriority? priority,
  });

  /// Cache notifications locally
  Future<void> cacheNotifications(List<NotificationModel> notifications);

  /// Get cached notification by ID
  Future<NotificationModel?> getCachedNotificationById(String id);

  /// Cache single notification
  Future<void> cacheNotification(NotificationModel notification);

  /// Update cached notification
  Future<void> updateCachedNotification(NotificationModel notification);

  /// Remove cached notification
  Future<void> removeCachedNotification(String id);

  /// Clear all cached notifications
  Future<void> clearCachedNotifications();

  /// Get cached notification summary
  Future<NotificationSummaryModel?> getCachedNotificationSummary();

  /// Cache notification summary
  Future<void> cacheNotificationSummary(NotificationSummaryModel summary);

  /// Get notification preferences from cache
  Future<Map<NotificationType, bool>?> getCachedNotificationPreferences();

  /// Cache notification preferences
  Future<void> cacheNotificationPreferences(
    Map<NotificationType, bool> preferences,
  );

  /// Queue notification for offline sync
  Future<void> queueNotificationForSync(Map<String, dynamic> data);

  /// Get queued notifications for sync
  Future<List<Map<String, dynamic>>> getQueuedNotifications();

  /// Remove queued notification after successful sync
  Future<void> removeQueuedNotification(String queueId);

  /// Clear all queued notifications
  Future<void> clearQueuedNotifications();

  /// Save FCM token
  Future<void> saveFCMToken(String token);

  /// Get FCM token
  Future<String?> getFCMToken();
}