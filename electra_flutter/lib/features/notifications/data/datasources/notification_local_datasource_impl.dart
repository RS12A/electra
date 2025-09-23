import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../../core/storage/storage_service.dart';
import '../../../shared/utils/logger.dart';
import '../models/notification_model.dart';
import '../../domain/entities/notification.dart';
import 'notification_datasource.dart';

/// Local data source implementation for notifications caching
@Injectable(as: NotificationLocalDataSource)
class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  const NotificationLocalDataSourceImpl(this._storageService);

  final StorageService _storageService;

  static const String _notificationsCacheKey = 'notifications_cache';
  static const String _notificationSummaryCacheKey = 'notification_summary_cache';
  static const String _notificationPreferencesKey = 'notification_preferences';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _queueKeyPrefix = 'notification_queue_';

  @override
  Future<List<NotificationModel>> getCachedNotifications({
    NotificationType? type,
    NotificationStatus? status,
    NotificationPriority? priority,
  }) async {
    try {
      final cachedData = await _storageService.getCachedData(_notificationsCacheKey);
      if (cachedData == null) return [];

      final List<dynamic> notificationsList = cachedData['notifications'] as List<dynamic>? ?? [];
      List<NotificationModel> notifications = notificationsList
          .map((json) => NotificationModel.fromCacheMap(json as Map<String, dynamic>))
          .toList();

      // Apply filters
      if (type != null) {
        notifications = notifications.where((n) => n.type == type).toList();
      }
      if (status != null) {
        notifications = notifications.where((n) => n.status == status).toList();
      }
      if (priority != null) {
        notifications = notifications.where((n) => n.priority == priority).toList();
      }

      // Sort by timestamp descending (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return notifications;
    } catch (e) {
      AppLogger.error('Error getting cached notifications', e);
      return [];
    }
  }

  @override
  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    try {
      final cacheData = {
        'notifications': notifications.map((n) => n.toCacheMap()).toList(),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      };

      await _storageService.cacheData(_notificationsCacheKey, cacheData);
      AppLogger.debug('Cached ${notifications.length} notifications');
    } catch (e) {
      AppLogger.error('Error caching notifications', e);
    }
  }

  @override
  Future<NotificationModel?> getCachedNotificationById(String id) async {
    try {
      final notifications = await getCachedNotifications();
      return notifications.cast<NotificationModel?>().firstWhere(
        (n) => n?.id == id,
        orElse: () => null,
      );
    } catch (e) {
      AppLogger.error('Error getting cached notification by ID', e);
      return null;
    }
  }

  @override
  Future<void> cacheNotification(NotificationModel notification) async {
    try {
      final existingNotifications = await getCachedNotifications();
      final index = existingNotifications.indexWhere((n) => n.id == notification.id);
      
      if (index != -1) {
        existingNotifications[index] = notification;
      } else {
        existingNotifications.insert(0, notification);
      }

      await cacheNotifications(existingNotifications);
      AppLogger.debug('Cached single notification: ${notification.id}');
    } catch (e) {
      AppLogger.error('Error caching single notification', e);
    }
  }

  @override
  Future<void> updateCachedNotification(NotificationModel notification) async {
    try {
      final existingNotifications = await getCachedNotifications();
      final index = existingNotifications.indexWhere((n) => n.id == notification.id);
      
      if (index != -1) {
        existingNotifications[index] = notification;
        await cacheNotifications(existingNotifications);
        AppLogger.debug('Updated cached notification: ${notification.id}');
      }
    } catch (e) {
      AppLogger.error('Error updating cached notification', e);
    }
  }

  @override
  Future<void> removeCachedNotification(String id) async {
    try {
      final existingNotifications = await getCachedNotifications();
      existingNotifications.removeWhere((n) => n.id == id);
      await cacheNotifications(existingNotifications);
      AppLogger.debug('Removed cached notification: $id');
    } catch (e) {
      AppLogger.error('Error removing cached notification', e);
    }
  }

  @override
  Future<void> clearCachedNotifications() async {
    try {
      await _storageService.deleteCachedData(_notificationsCacheKey);
      AppLogger.debug('Cleared all cached notifications');
    } catch (e) {
      AppLogger.error('Error clearing cached notifications', e);
    }
  }

  @override
  Future<NotificationSummaryModel?> getCachedNotificationSummary() async {
    try {
      final cachedData = await _storageService.getCachedData(_notificationSummaryCacheKey);
      if (cachedData == null) return null;

      return NotificationSummaryModel.fromJson(cachedData as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Error getting cached notification summary', e);
      return null;
    }
  }

  @override
  Future<void> cacheNotificationSummary(NotificationSummaryModel summary) async {
    try {
      await _storageService.cacheData(
        _notificationSummaryCacheKey,
        summary.toJson(),
      );
      AppLogger.debug('Cached notification summary');
    } catch (e) {
      AppLogger.error('Error caching notification summary', e);
    }
  }

  @override
  Future<Map<NotificationType, bool>?> getCachedNotificationPreferences() async {
    try {
      final cachedData = await _storageService.getCachedData(_notificationPreferencesKey);
      if (cachedData == null) return null;

      final Map<String, dynamic> preferencesData = cachedData as Map<String, dynamic>;
      final Map<NotificationType, bool> preferences = {};
      
      preferencesData.forEach((key, value) {
        try {
          final type = NotificationType.values.firstWhere(
            (e) => e.toString().split('.').last == key,
          );
          preferences[type] = value as bool;
        } catch (e) {
          // Skip unknown notification types
          AppLogger.warning('Unknown notification type in cache: $key');
        }
      });

      return preferences;
    } catch (e) {
      AppLogger.error('Error getting cached notification preferences', e);
      return null;
    }
  }

  @override
  Future<void> cacheNotificationPreferences(
    Map<NotificationType, bool> preferences,
  ) async {
    try {
      final Map<String, bool> preferencesData = {};
      preferences.forEach((type, enabled) {
        preferencesData[type.toString().split('.').last] = enabled;
      });

      await _storageService.cacheData(_notificationPreferencesKey, preferencesData);
      AppLogger.debug('Cached notification preferences');
    } catch (e) {
      AppLogger.error('Error caching notification preferences', e);
    }
  }

  @override
  Future<void> queueNotificationForSync(Map<String, dynamic> data) async {
    try {
      final queueKey = '${_queueKeyPrefix}${DateTime.now().millisecondsSinceEpoch}';
      await _storageService.queueForSync('notification', data);
      AppLogger.debug('Queued notification for sync: $queueKey');
    } catch (e) {
      AppLogger.error('Error queuing notification for sync', e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getQueuedNotifications() async {
    try {
      final queuedItems = await _storageService.getQueuedItems();
      final List<Map<String, dynamic>> notifications = [];
      
      queuedItems.forEach((key, value) {
        final data = value as Map<String, dynamic>;
        if (data['type'] == 'notification') {
          notifications.add({
            'queue_id': key,
            ...data['data'] as Map<String, dynamic>,
          });
        }
      });

      return notifications;
    } catch (e) {
      AppLogger.error('Error getting queued notifications', e);
      return [];
    }
  }

  @override
  Future<void> removeQueuedNotification(String queueId) async {
    try {
      await _storageService.removeFromQueue(queueId);
      AppLogger.debug('Removed queued notification: $queueId');
    } catch (e) {
      AppLogger.error('Error removing queued notification', e);
    }
  }

  @override
  Future<void> clearQueuedNotifications() async {
    try {
      final queuedItems = await _storageService.getQueuedItems();
      
      for (final key in queuedItems.keys) {
        final data = queuedItems[key] as Map<String, dynamic>;
        if (data['type'] == 'notification') {
          await _storageService.removeFromQueue(key);
        }
      }
      
      AppLogger.debug('Cleared all queued notifications');
    } catch (e) {
      AppLogger.error('Error clearing queued notifications', e);
    }
  }

  @override
  Future<void> saveFCMToken(String token) async {
    try {
      await _storageService.cacheData(_fcmTokenKey, {'token': token});
      AppLogger.debug('Saved FCM token');
    } catch (e) {
      AppLogger.error('Error saving FCM token', e);
    }
  }

  @override
  Future<String?> getFCMToken() async {
    try {
      final cachedData = await _storageService.getCachedData(_fcmTokenKey);
      if (cachedData == null) return null;
      
      return (cachedData as Map<String, dynamic>)['token'] as String?;
    } catch (e) {
      AppLogger.error('Error getting FCM token', e);
      return null;
    }
  }
}