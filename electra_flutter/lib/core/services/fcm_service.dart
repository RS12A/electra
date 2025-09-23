import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../shared/utils/logger.dart';
import '../../features/notifications/domain/entities/notification.dart';
import '../../features/notifications/data/models/notification_model.dart';

/// Firebase Cloud Messaging service for handling push notifications
@singleton
class FCMService {
  FCMService(this._localNotifications);

  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  StreamController<NotificationModel>? _notificationStreamController;
  StreamController<NotificationModel>? _notificationOpenedStreamController;

  /// Stream of incoming notifications
  Stream<NotificationModel> get onNotificationReceived {
    _notificationStreamController ??= StreamController<NotificationModel>.broadcast();
    return _notificationStreamController!.stream;
  }

  /// Stream of notifications opened/tapped by user
  Stream<NotificationModel> get onNotificationOpened {
    _notificationOpenedStreamController ??= StreamController<NotificationModel>.broadcast();
    return _notificationOpenedStreamController!.stream;
  }

  /// Initialize FCM service
  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing FCM service...');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      // Set up message handlers
      await _setupMessageHandlers();

      // Get initial message if app was opened from notification
      await _handleInitialMessage();

      AppLogger.info('FCM service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize FCM service', e, stackTrace);
      rethrow;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'election_notifications',
        'Election Notifications',
        description: 'Notifications about elections, voting, and results',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'system_notifications',
        'System Notifications',
        description: 'System maintenance and update notifications',
        importance: Importance.defaultImportance,
        enableVibration: false,
        playSound: false,
      ),
      AndroidNotificationChannel(
        'security_notifications',
        'Security Notifications',
        description: 'Security-related notifications and alerts',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'reminder_notifications',
        'Reminder Notifications',
        description: 'Voting reminders and deadline notifications',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Request notification permissions
  Future<NotificationSettings> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    AppLogger.info('FCM permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      AppLogger.warning('User denied notification permissions');
    }

    return settings;
  }

  /// Set up message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

    // Handle background messages (requires top-level function)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Handle messages received while app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      AppLogger.info('Received foreground message: ${message.messageId}');

      final notification = NotificationModel.fromFCMPayload({
        'messageId': message.messageId,
        'data': message.data,
        'notification': message.notification?.toMap(),
      });

      // Show local notification
      await _showLocalNotification(notification, message);

      // Emit to stream
      _notificationStreamController?.add(notification);
    } catch (e, stackTrace) {
      AppLogger.error('Error handling foreground message', e, stackTrace);
    }
  }

  /// Handle notification tapped/opened
  Future<void> _handleNotificationOpened(RemoteMessage message) async {
    try {
      AppLogger.info('Notification opened: ${message.messageId}');

      final notification = NotificationModel.fromFCMPayload({
        'messageId': message.messageId,
        'data': message.data,
        'notification': message.notification?.toMap(),
      });

      // Emit to stream
      _notificationOpenedStreamController?.add(notification);
    } catch (e, stackTrace) {
      AppLogger.error('Error handling notification opened', e, stackTrace);
    }
  }

  /// Handle initial message if app was opened from notification
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.info('App opened from notification: ${initialMessage.messageId}');
      await _handleNotificationOpened(initialMessage);
    }
  }

  /// Handle local notification tapped
  void _onNotificationTapped(NotificationResponse response) {
    try {
      AppLogger.info('Local notification tapped: ${response.payload}');
      
      if (response.payload != null) {
        // Parse payload and create notification model
        // This would need to be implemented based on how you store notification data
        // For now, we'll just log it
        AppLogger.info('Notification payload: ${response.payload}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error handling local notification tap', e, stackTrace);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(
    NotificationModel notification,
    RemoteMessage message,
  ) async {
    try {
      final channelId = _getChannelIdForNotificationType(notification.type);
      
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelNameForNotificationType(notification.type),
        channelDescription: _getChannelDescriptionForNotificationType(notification.type),
        importance: _getImportanceForPriority(notification.priority),
        priority: _getPriorityForPriority(notification.priority),
        enableVibration: notification.priority == NotificationPriority.critical || 
                       notification.priority == NotificationPriority.high,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: notification.imageUrl != null 
            ? FilePathAndroidBitmap(notification.imageUrl!)
            : null,
        styleInformation: notification.message.length > 50
            ? BigTextStyleInformation(
                notification.message,
                contentTitle: notification.title,
              )
            : null,
        actions: notification.actions?.map((action) => 
          AndroidNotificationAction(
            action.id,
            action.label,
            showsUserInterface: true,
          )).toList(),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.message,
        details,
        payload: notification.id,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error showing local notification', e, stackTrace);
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      AppLogger.info('FCM Token obtained: ${token?.substring(0, 20)}...');
      return token;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting FCM token', e, stackTrace);
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e, stackTrace) {
      AppLogger.error('Error subscribing to topic: $topic', e, stackTrace);
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e, stackTrace) {
      AppLogger.error('Error unsubscribing from topic: $topic', e, stackTrace);
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      AppLogger.info('FCM token deleted');
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting FCM token', e, stackTrace);
    }
  }

  /// Get channel ID for notification type
  String _getChannelIdForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.election:
      case NotificationType.votingReminder:
      case NotificationType.deadline:
        return 'election_notifications';
      case NotificationType.system:
      case NotificationType.announcement:
        return 'system_notifications';
      case NotificationType.security:
        return 'security_notifications';
      default:
        return 'reminder_notifications';
    }
  }

  /// Get channel name for notification type
  String _getChannelNameForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.election:
      case NotificationType.votingReminder:
      case NotificationType.deadline:
        return 'Election Notifications';
      case NotificationType.system:
      case NotificationType.announcement:
        return 'System Notifications';
      case NotificationType.security:
        return 'Security Notifications';
      default:
        return 'Reminder Notifications';
    }
  }

  /// Get channel description for notification type
  String _getChannelDescriptionForNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.election:
      case NotificationType.votingReminder:
      case NotificationType.deadline:
        return 'Notifications about elections, voting, and results';
      case NotificationType.system:
      case NotificationType.announcement:
        return 'System maintenance and update notifications';
      case NotificationType.security:
        return 'Security-related notifications and alerts';
      default:
        return 'Voting reminders and deadline notifications';
    }
  }

  /// Get Android importance for priority
  Importance _getImportanceForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return Importance.max;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.low:
        return Importance.low;
    }
  }

  /// Get Android priority for priority
  Priority _getPriorityForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.critical:
        return Priority.max;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.low:
        return Priority.low;
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationStreamController?.close();
    _notificationOpenedStreamController?.close();
  }
}

/// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    AppLogger.info('Background message received: ${message.messageId}');
    
    // Initialize Firebase if not already initialized
    await Firebase.initializeApp();
    
    // Handle background message
    // You can store the message locally or perform other background operations
    
    AppLogger.info('Background message handled');
  } catch (e) {
    AppLogger.error('Error handling background message: $e');
  }
}

/// FCM service provider
@singleton
class FCMServiceProvider {
  FCMServiceProvider() {
    _fcmService = FCMService(FlutterLocalNotificationsPlugin());
  }

  late final FCMService _fcmService;

  FCMService get service => _fcmService;

  /// Initialize FCM service
  Future<void> initialize() async {
    await _fcmService.initialize();
  }
}