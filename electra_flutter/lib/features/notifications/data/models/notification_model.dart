import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/notification.dart';

part 'notification_model.g.dart';

/// Notification action data model for API serialization
@JsonSerializable()
class NotificationActionModel extends NotificationAction {
  const NotificationActionModel({
    required String id,
    required String label,
    required String actionType,
    Map<String, dynamic>? params,
  }) : super(
          id: id,
          label: label,
          actionType: actionType,
          params: params,
        );

  /// Create model from domain entity
  factory NotificationActionModel.fromEntity(NotificationAction action) {
    return NotificationActionModel(
      id: action.id,
      label: action.label,
      actionType: action.actionType,
      params: action.params,
    );
  }

  /// Create model from JSON
  factory NotificationActionModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationActionModelFromJson(json);

  /// Convert model to JSON
  Map<String, dynamic> toJson() => _$NotificationActionModelToJson(this);
}

/// Notification data model for API serialization/deserialization
///
/// This model extends the domain Notification entity with JSON serialization 
/// capabilities for API communication and local storage.
@JsonSerializable()
class NotificationModel extends Notification {
  const NotificationModel({
    required String id,
    required NotificationType type,
    required NotificationPriority priority,
    required String title,
    required String message,
    required DateTime timestamp,
    required NotificationStatus status,
    String? imageUrl,
    String? deepLinkUrl,
    String? relatedElectionId,
    List<NotificationAction>? actions,
    Map<String, dynamic>? metadata,
    DateTime? expiresAt,
    DateTime? readAt,
    DateTime? dismissedAt,
    bool isPush = false,
    String? fcmMessageId,
  }) : super(
          id: id,
          type: type,
          priority: priority,
          title: title,
          message: message,
          timestamp: timestamp,
          status: status,
          imageUrl: imageUrl,
          deepLinkUrl: deepLinkUrl,
          relatedElectionId: relatedElectionId,
          actions: actions,
          metadata: metadata,
          expiresAt: expiresAt,
          readAt: readAt,
          dismissedAt: dismissedAt,
          isPush: isPush,
          fcmMessageId: fcmMessageId,
        );

  /// Create model from domain entity
  factory NotificationModel.fromEntity(Notification notification) {
    return NotificationModel(
      id: notification.id,
      type: notification.type,
      priority: notification.priority,
      title: notification.title,
      message: notification.message,
      timestamp: notification.timestamp,
      status: notification.status,
      imageUrl: notification.imageUrl,
      deepLinkUrl: notification.deepLinkUrl,
      relatedElectionId: notification.relatedElectionId,
      actions: notification.actions,
      metadata: notification.metadata,
      expiresAt: notification.expiresAt,
      readAt: notification.readAt,
      dismissedAt: notification.dismissedAt,
      isPush: notification.isPush,
      fcmMessageId: notification.fcmMessageId,
    );
  }

  /// Create model from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  /// Convert model to JSON
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  /// Create from Firebase Cloud Messaging payload
  factory NotificationModel.fromFCMPayload(Map<String, dynamic> payload) {
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    final notification = payload['notification'] as Map<String, dynamic>? ?? {};
    
    return NotificationModel(
      id: data['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] as String? ?? 'system'),
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == (data['priority'] as String? ?? 'normal'),
        orElse: () => NotificationPriority.normal,
      ),
      title: notification['title'] as String? ?? data['title'] as String? ?? 'Notification',
      message: notification['body'] as String? ?? data['message'] as String? ?? '',
      timestamp: DateTime.now(),
      status: NotificationStatus.unread,
      imageUrl: notification['image'] as String? ?? data['imageUrl'] as String?,
      deepLinkUrl: data['deepLinkUrl'] as String?,
      relatedElectionId: data['relatedElectionId'] as String?,
      metadata: data,
      isPush: true,
      fcmMessageId: payload['messageId'] as String?,
    );
  }

  /// Convert to cache-friendly map for local storage
  Map<String, dynamic> toCacheMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'title': title,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
      'imageUrl': imageUrl,
      'deepLinkUrl': deepLinkUrl,
      'relatedElectionId': relatedElectionId,
      'actions': actions?.map((a) => {
        'id': a.id,
        'label': a.label,
        'actionType': a.actionType,
        'params': a.params,
      }).toList(),
      'metadata': metadata,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
      'dismissedAt': dismissedAt?.millisecondsSinceEpoch,
      'isPush': isPush,
      'fcmMessageId': fcmMessageId,
    };
  }

  /// Create from cache map
  factory NotificationModel.fromCacheMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'] as String,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'] as String,
      ),
      title: map['title'] as String,
      message: map['message'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: NotificationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'] as String,
      ),
      imageUrl: map['imageUrl'] as String?,
      deepLinkUrl: map['deepLinkUrl'] as String?,
      relatedElectionId: map['relatedElectionId'] as String?,
      actions: (map['actions'] as List<dynamic>?)
          ?.map((a) => NotificationActionModel.fromJson(a as Map<String, dynamic>))
          .cast<NotificationAction>()
          .toList(),
      metadata: map['metadata'] as Map<String, dynamic>?,
      expiresAt: map['expiresAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int)
          : null,
      readAt: map['readAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['readAt'] as int)
          : null,
      dismissedAt: map['dismissedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dismissedAt'] as int)
          : null,
      isPush: map['isPush'] as bool? ?? false,
      fcmMessageId: map['fcmMessageId'] as String?,
    );
  }
}

/// Notification summary data model
@JsonSerializable()
class NotificationSummaryModel extends NotificationSummary {
  const NotificationSummaryModel({
    required int totalCount,
    required int unreadCount,
    required int criticalCount,
    required Map<NotificationType, int> countByType,
    required DateTime? lastNotificationAt,
  }) : super(
          totalCount: totalCount,
          unreadCount: unreadCount,
          criticalCount: criticalCount,
          countByType: countByType,
          lastNotificationAt: lastNotificationAt,
        );

  /// Create model from domain entity
  factory NotificationSummaryModel.fromEntity(NotificationSummary summary) {
    return NotificationSummaryModel(
      totalCount: summary.totalCount,
      unreadCount: summary.unreadCount,
      criticalCount: summary.criticalCount,
      countByType: summary.countByType,
      lastNotificationAt: summary.lastNotificationAt,
    );
  }

  /// Create model from JSON
  factory NotificationSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationSummaryModelFromJson(json);

  /// Convert model to JSON
  Map<String, dynamic> toJson() => _$NotificationSummaryModelToJson(this);
}