import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../../shared/utils/logger.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_datasource.dart';
import '../models/notification_model.dart';

/// Repository implementation for notification operations
@Injectable(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivity,
  );

  final NotificationRemoteDataSource _remoteDataSource;
  final NotificationLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  /// Check if device is connected to internet
  Future<bool> get _isConnected async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  Future<Either<Failure, List<Notification>>> getNotifications({
    int? limit,
    int? offset,
    NotificationType? type,
    NotificationStatus? status,
    NotificationPriority? priority,
  }) async {
    try {
      if (await _isConnected) {
        // Try to get from remote first
        try {
          final remoteNotifications = await _remoteDataSource.getNotifications(
            limit: limit,
            offset: offset,
            type: type,
            status: status,
            priority: priority,
          );
          
          // Cache the notifications
          await _localDataSource.cacheNotifications(remoteNotifications);
          
          return Right(remoteNotifications);
        } on ServerException catch (e) {
          AppLogger.warning('Remote fetch failed, falling back to cache', e);
        }
      }
      
      // Fall back to cached notifications
      final cachedNotifications = await _localDataSource.getCachedNotifications(
        type: type,
        status: status,
        priority: priority,
      );
      
      // Apply limit and offset to cached data
      List<NotificationModel> filteredNotifications = cachedNotifications;
      if (offset != null) {
        filteredNotifications = filteredNotifications.skip(offset).toList();
      }
      if (limit != null) {
        filteredNotifications = filteredNotifications.take(limit).toList();
      }
      
      return Right(filteredNotifications);
    } catch (e) {
      AppLogger.error('Error getting notifications', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Notification>> getNotificationById(String id) async {
    try {
      if (await _isConnected) {
        try {
          final remoteNotification = await _remoteDataSource.getNotificationById(id);
          await _localDataSource.cacheNotification(remoteNotification);
          return Right(remoteNotification);
        } on ServerException catch (e) {
          AppLogger.warning('Remote fetch failed, falling back to cache', e);
        }
      }
      
      final cachedNotification = await _localDataSource.getCachedNotificationById(id);
      if (cachedNotification != null) {
        return Right(cachedNotification);
      } else {
        return const Left(CacheFailure(message: 'Notification not found in cache'));
      }
    } catch (e) {
      AppLogger.error('Error getting notification by ID', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Notification>> markAsRead(String id) async {
    try {
      if (await _isConnected) {
        final updatedNotification = await _remoteDataSource.markAsRead(id);
        await _localDataSource.updateCachedNotification(updatedNotification);
        return Right(updatedNotification);
      } else {
        // Queue for offline sync
        await _localDataSource.queueNotificationForSync({
          'action': 'mark_read',
          'notification_id': id,
          'read_at': DateTime.now().toIso8601String(),
        });
        
        // Update local cache optimistically
        final cachedNotification = await _localDataSource.getCachedNotificationById(id);
        if (cachedNotification != null) {
          final updatedNotification = NotificationModel.fromEntity(cachedNotification).copyWith(
            status: NotificationStatus.read,
            readAt: DateTime.now(),
          );
          await _localDataSource.updateCachedNotification(updatedNotification);
          return Right(updatedNotification);
        } else {
          return const Left(CacheFailure(message: 'Notification not found in cache'));
        }
      }
    } on ServerException catch (e) {
      AppLogger.error('Error marking notification as read', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error marking notification as read', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Notification>> markAsDismissed(String id) async {
    try {
      if (await _isConnected) {
        final updatedNotification = await _remoteDataSource.markAsDismissed(id);
        await _localDataSource.updateCachedNotification(updatedNotification);
        return Right(updatedNotification);
      } else {
        // Queue for offline sync
        await _localDataSource.queueNotificationForSync({
          'action': 'mark_dismissed',
          'notification_id': id,
          'dismissed_at': DateTime.now().toIso8601String(),
        });
        
        // Update local cache optimistically
        final cachedNotification = await _localDataSource.getCachedNotificationById(id);
        if (cachedNotification != null) {
          final updatedNotification = NotificationModel.fromEntity(cachedNotification).copyWith(
            status: NotificationStatus.dismissed,
            dismissedAt: DateTime.now(),
          );
          await _localDataSource.updateCachedNotification(updatedNotification);
          return Right(updatedNotification);
        } else {
          return const Left(CacheFailure(message: 'Notification not found in cache'));
        }
      }
    } on ServerException catch (e) {
      AppLogger.error('Error marking notification as dismissed', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error marking notification as dismissed', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      if (await _isConnected) {
        await _remoteDataSource.markAllAsRead();
        
        // Update all cached notifications
        final cachedNotifications = await _localDataSource.getCachedNotifications();
        final updatedNotifications = cachedNotifications.map((notification) {
          if (notification.status == NotificationStatus.unread) {
            return NotificationModel.fromEntity(notification).copyWith(
              status: NotificationStatus.read,
              readAt: DateTime.now(),
            );
          }
          return notification;
        }).toList();
        
        await _localDataSource.cacheNotifications(updatedNotifications);
        return const Right(null);
      } else {
        // Queue for offline sync
        await _localDataSource.queueNotificationForSync({
          'action': 'mark_all_read',
          'read_at': DateTime.now().toIso8601String(),
        });
        
        return const Right(null);
      }
    } on ServerException catch (e) {
      AppLogger.error('Error marking all notifications as read', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error marking all notifications as read', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String id) async {
    try {
      if (await _isConnected) {
        await _remoteDataSource.deleteNotification(id);
      } else {
        // Queue for offline sync
        await _localDataSource.queueNotificationForSync({
          'action': 'delete',
          'notification_id': id,
        });
      }
      
      // Remove from local cache
      await _localDataSource.removeCachedNotification(id);
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.error('Error deleting notification', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error deleting notification', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllNotifications() async {
    try {
      if (await _isConnected) {
        await _remoteDataSource.clearAllNotifications();
      } else {
        // Queue for offline sync
        await _localDataSource.queueNotificationForSync({
          'action': 'clear_all',
        });
      }
      
      // Clear local cache
      await _localDataSource.clearCachedNotifications();
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.error('Error clearing all notifications', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error clearing all notifications', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, NotificationSummary>> getNotificationSummary() async {
    try {
      if (await _isConnected) {
        try {
          final remoteSummary = await _remoteDataSource.getNotificationSummary();
          await _localDataSource.cacheNotificationSummary(remoteSummary);
          return Right(remoteSummary);
        } on ServerException catch (e) {
          AppLogger.warning('Remote fetch failed, falling back to cache', e);
        }
      }
      
      final cachedSummary = await _localDataSource.getCachedNotificationSummary();
      if (cachedSummary != null) {
        return Right(cachedSummary);
      } else {
        // Generate summary from cached notifications
        final cachedNotifications = await _localDataSource.getCachedNotifications();
        final summary = _generateSummaryFromNotifications(cachedNotifications);
        return Right(summary);
      }
    } catch (e) {
      AppLogger.error('Error getting notification summary', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> subscribeToPushNotifications() async {
    try {
      // This would typically involve Firebase Cloud Messaging
      // For now, return a placeholder implementation
      if (await _isConnected) {
        final token = await _remoteDataSource.subscribeToPushNotifications('fcm_token_placeholder');
        await _localDataSource.saveFCMToken(token);
        return Right(token);
      } else {
        return const Left(ServerFailure(message: 'No internet connection'));
      }
    } on ServerException catch (e) {
      AppLogger.error('Error subscribing to push notifications', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error subscribing to push notifications', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unsubscribeFromPushNotifications() async {
    try {
      if (await _isConnected) {
        await _remoteDataSource.unsubscribeFromPushNotifications();
        return const Right(null);
      } else {
        return const Left(ServerFailure(message: 'No internet connection'));
      }
    } on ServerException catch (e) {
      AppLogger.error('Error unsubscribing from push notifications', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error unsubscribing from push notifications', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateNotificationPreferences(
    Map<NotificationType, bool> preferences,
  ) async {
    try {
      // Always cache preferences locally
      await _localDataSource.cacheNotificationPreferences(preferences);
      
      if (await _isConnected) {
        await _remoteDataSource.updateNotificationPreferences(preferences);
        return const Right(null);
      } else {
        // Queue for offline sync
        await _localDataSource.queueNotificationForSync({
          'action': 'update_preferences',
          'preferences': preferences.map((type, enabled) => 
            MapEntry(type.toString().split('.').last, enabled)),
        });
        return const Right(null);
      }
    } on ServerException catch (e) {
      AppLogger.error('Error updating notification preferences', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error updating notification preferences', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<NotificationType, bool>>> getNotificationPreferences() async {
    try {
      if (await _isConnected) {
        try {
          final remotePreferences = await _remoteDataSource.getNotificationPreferences();
          await _localDataSource.cacheNotificationPreferences(remotePreferences);
          return Right(remotePreferences);
        } on ServerException catch (e) {
          AppLogger.warning('Remote fetch failed, falling back to cache', e);
        }
      }
      
      final cachedPreferences = await _localDataSource.getCachedNotificationPreferences();
      if (cachedPreferences != null) {
        return Right(cachedPreferences);
      } else {
        // Return default preferences
        final defaultPreferences = <NotificationType, bool>{
          for (final type in NotificationType.values) type: true,
        };
        return Right(defaultPreferences);
      }
    } catch (e) {
      AppLogger.error('Error getting notification preferences', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Notification>> handlePushNotification(
    Map<String, dynamic> payload,
  ) async {
    try {
      final notification = NotificationModel.fromFCMPayload(payload);
      await _localDataSource.cacheNotification(notification);
      return Right(notification);
    } catch (e) {
      AppLogger.error('Error handling push notification', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      if (await _isConnected) {
        final notification = await _remoteDataSource.sendNotification(
          userIds: userIds,
          type: type,
          priority: priority,
          title: title,
          message: message,
          imageUrl: imageUrl,
          deepLinkUrl: deepLinkUrl,
          actions: actions,
          metadata: metadata,
          expiresAt: expiresAt,
          sendPush: sendPush,
        );
        return Right(notification);
      } else {
        return const Left(ServerFailure(message: 'No internet connection'));
      }
    } on ServerException catch (e) {
      AppLogger.error('Error sending notification', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error sending notification', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Notification>>> getCachedNotifications() async {
    try {
      final cachedNotifications = await _localDataSource.getCachedNotifications();
      return Right(cachedNotifications);
    } catch (e) {
      AppLogger.error('Error getting cached notifications', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncNotifications() async {
    try {
      if (!await _isConnected) {
        return const Left(ServerFailure(message: 'No internet connection'));
      }

      final queuedNotifications = await _localDataSource.getQueuedNotifications();
      
      for (final queuedItem in queuedNotifications) {
        try {
          final action = queuedItem['action'] as String;
          final queueId = queuedItem['queue_id'] as String;
          
          switch (action) {
            case 'mark_read':
              await _remoteDataSource.markAsRead(queuedItem['notification_id'] as String);
              break;
            case 'mark_dismissed':
              await _remoteDataSource.markAsDismissed(queuedItem['notification_id'] as String);
              break;
            case 'mark_all_read':
              await _remoteDataSource.markAllAsRead();
              break;
            case 'delete':
              await _remoteDataSource.deleteNotification(queuedItem['notification_id'] as String);
              break;
            case 'clear_all':
              await _remoteDataSource.clearAllNotifications();
              break;
            case 'update_preferences':
              final preferencesData = queuedItem['preferences'] as Map<String, dynamic>;
              final preferences = <NotificationType, bool>{};
              preferencesData.forEach((key, value) {
                try {
                  final type = NotificationType.values.firstWhere(
                    (e) => e.toString().split('.').last == key,
                  );
                  preferences[type] = value as bool;
                } catch (e) {
                  // Skip unknown types
                }
              });
              await _remoteDataSource.updateNotificationPreferences(preferences);
              break;
          }
          
          // Remove from queue after successful sync
          await _localDataSource.removeQueuedNotification(queueId);
        } catch (e) {
          AppLogger.warning('Failed to sync queued notification: ${e.toString()}');
          // Continue with next item
        }
      }
      
      return const Right(null);
    } catch (e) {
      AppLogger.error('Error syncing notifications', e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> queueOfflineNotification(
    Map<String, dynamic> notificationData,
  ) async {
    try {
      await _localDataSource.queueNotificationForSync(notificationData);
      return const Right(null);
    } catch (e) {
      AppLogger.error('Error queuing offline notification', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getQueuedNotifications() async {
    try {
      final queuedNotifications = await _localDataSource.getQueuedNotifications();
      return Right(queuedNotifications);
    } catch (e) {
      AppLogger.error('Error getting queued notifications', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearQueuedNotifications() async {
    try {
      await _localDataSource.clearQueuedNotifications();
      return const Right(null);
    } catch (e) {
      AppLogger.error('Error clearing queued notifications', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// Generate notification summary from cached notifications
  NotificationSummary _generateSummaryFromNotifications(List<NotificationModel> notifications) {
    final totalCount = notifications.length;
    final unreadCount = notifications.where((n) => n.status == NotificationStatus.unread).length;
    final criticalCount = notifications.where((n) => n.priority == NotificationPriority.critical).length;
    
    final countByType = <NotificationType, int>{};
    for (final type in NotificationType.values) {
      countByType[type] = notifications.where((n) => n.type == type).length;
    }
    
    final lastNotificationAt = notifications.isNotEmpty 
        ? notifications.first.timestamp 
        : null;
    
    return NotificationSummaryModel(
      totalCount: totalCount,
      unreadCount: unreadCount,
      criticalCount: criticalCount,
      countByType: countByType,
      lastNotificationAt: lastNotificationAt,
    );
  }
}

/// Extension to add copyWith method to NotificationModel
extension NotificationModelExtension on NotificationModel {
  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationStatus? status,
    String? imageUrl,
    String? deepLinkUrl,
    String? relatedElectionId,
    List<NotificationAction>? actions,
    Map<String, dynamic>? metadata,
    DateTime? expiresAt,
    DateTime? readAt,
    DateTime? dismissedAt,
    bool? isPush,
    String? fcmMessageId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      deepLinkUrl: deepLinkUrl ?? this.deepLinkUrl,
      relatedElectionId: relatedElectionId ?? this.relatedElectionId,
      actions: actions ?? this.actions,
      metadata: metadata ?? this.metadata,
      expiresAt: expiresAt ?? this.expiresAt,
      readAt: readAt ?? this.readAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
      isPush: isPush ?? this.isPush,
      fcmMessageId: fcmMessageId ?? this.fcmMessageId,
    );
  }
}