import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/network/network_service.dart';
import '../../../core/error/exceptions.dart';
import '../../../shared/utils/logger.dart';
import '../models/notification_model.dart';
import '../../domain/entities/notification.dart';
import 'notification_datasource.dart';

/// Remote data source implementation for notifications API
@Injectable(as: NotificationRemoteDataSource)
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  const NotificationRemoteDataSourceImpl(this._networkService);

  final NetworkService _networkService;

  @override
  Future<List<NotificationModel>> getNotifications({
    int? limit,
    int? offset,
    NotificationType? type,
    NotificationStatus? status,
    NotificationPriority? priority,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;
      if (type != null) queryParams['type'] = type.toString().split('.').last;
      if (status != null) queryParams['status'] = status.toString().split('.').last;
      if (priority != null) queryParams['priority'] = priority.toString().split('.').last;

      final response = await _networkService.dio.get(
        '/api/notifications/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? response.data;
        return data
            .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to get notifications',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error getting notifications', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error getting notifications', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<NotificationModel> getNotificationById(String id) async {
    try {
      final response = await _networkService.dio.get('/api/notifications/$id/');

      if (response.statusCode == 200) {
        return NotificationModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Failed to get notification',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error getting notification by ID', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error getting notification by ID', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<NotificationModel> markAsRead(String id) async {
    try {
      final response = await _networkService.dio.patch(
        '/api/notifications/$id/',
        data: {'status': 'read', 'readAt': DateTime.now().toIso8601String()},
      );

      if (response.statusCode == 200) {
        return NotificationModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Failed to mark notification as read',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error marking notification as read', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error marking notification as read', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<NotificationModel> markAsDismissed(String id) async {
    try {
      final response = await _networkService.dio.patch(
        '/api/notifications/$id/',
        data: {
          'status': 'dismissed',
          'dismissedAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return NotificationModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Failed to mark notification as dismissed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error marking notification as dismissed', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error marking notification as dismissed', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      final response = await _networkService.dio.post(
        '/api/notifications/mark-all-read/',
        data: {'readAt': DateTime.now().toIso8601String()},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to mark all notifications as read',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error marking all notifications as read', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error marking all notifications as read', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      final response = await _networkService.dio.delete('/api/notifications/$id/');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to delete notification',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error deleting notification', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error deleting notification', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> clearAllNotifications() async {
    try {
      final response = await _networkService.dio.delete('/api/notifications/clear-all/');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to clear all notifications',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error clearing all notifications', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error clearing all notifications', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<NotificationSummaryModel> getNotificationSummary() async {
    try {
      final response = await _networkService.dio.get('/api/notifications/summary/');

      if (response.statusCode == 200) {
        return NotificationSummaryModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Failed to get notification summary',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error getting notification summary', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error getting notification summary', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<String> subscribeToPushNotifications(String fcmToken) async {
    try {
      final response = await _networkService.dio.post(
        '/api/notifications/subscribe/',
        data: {'fcm_token': fcmToken},
      );

      if (response.statusCode == 200) {
        return response.data['subscription_id'] as String? ?? fcmToken;
      } else {
        throw ServerException(
          message: 'Failed to subscribe to push notifications',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error subscribing to push notifications', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error subscribing to push notifications', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> unsubscribeFromPushNotifications() async {
    try {
      final response = await _networkService.dio.post('/api/notifications/unsubscribe/');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to unsubscribe from push notifications',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error unsubscribing from push notifications', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error unsubscribing from push notifications', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateNotificationPreferences(
    Map<NotificationType, bool> preferences,
  ) async {
    try {
      final Map<String, bool> preferencesData = {};
      preferences.forEach((type, enabled) {
        preferencesData[type.toString().split('.').last] = enabled;
      });

      final response = await _networkService.dio.put(
        '/api/notifications/preferences/',
        data: {'preferences': preferencesData},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to update notification preferences',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error updating notification preferences', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error updating notification preferences', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<NotificationType, bool>> getNotificationPreferences() async {
    try {
      final response = await _networkService.dio.get('/api/notifications/preferences/');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data['preferences'] as Map<String, dynamic>;
        final Map<NotificationType, bool> preferences = {};
        
        data.forEach((key, value) {
          try {
            final type = NotificationType.values.firstWhere(
              (e) => e.toString().split('.').last == key,
            );
            preferences[type] = value as bool;
          } catch (e) {
            // Skip unknown notification types
            AppLogger.warning('Unknown notification type: $key');
          }
        });

        return preferences;
      } else {
        throw ServerException(
          message: 'Failed to get notification preferences',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error getting notification preferences', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error getting notification preferences', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
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
  }) async {
    try {
      final Map<String, dynamic> data = {
        'user_ids': userIds,
        'type': type.toString().split('.').last,
        'priority': priority.toString().split('.').last,
        'title': title,
        'message': message,
        'send_push': sendPush,
      };

      if (imageUrl != null) data['image_url'] = imageUrl;
      if (deepLinkUrl != null) data['deep_link_url'] = deepLinkUrl;
      if (actions != null) {
        data['actions'] = actions.map((a) => {
          'id': a.id,
          'label': a.label,
          'action_type': a.actionType,
          'params': a.params,
        }).toList();
      }
      if (metadata != null) data['metadata'] = metadata;
      if (expiresAt != null) data['expires_at'] = expiresAt.toIso8601String();

      final response = await _networkService.dio.post(
        '/api/notifications/send/',
        data: data,
      );

      if (response.statusCode == 201) {
        return NotificationModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Failed to send notification',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error sending notification', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error sending notification', e);
      throw ServerException(message: e.toString());
    }
  }
}