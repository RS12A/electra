import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

/// Notification type enumeration
enum NotificationType {
  /// Election-related notifications (voting reminders, results, etc.)
  election,
  
  /// System notifications (maintenance, updates, etc.)
  system,
  
  /// Security notifications (login attempts, password changes, etc.)
  security,
  
  /// General announcements
  announcement,
  
  /// Voting reminders for non-voters
  votingReminder,
  
  /// Election deadline notifications
  deadline,
}

/// Notification priority levels
enum NotificationPriority {
  /// Low priority notification
  low,
  
  /// Normal priority notification
  normal,
  
  /// High priority notification (important but not urgent)
  high,
  
  /// Critical priority notification (requires immediate attention)
  critical,
}

/// Notification status enumeration
enum NotificationStatus {
  /// Notification is unread
  unread,
  
  /// Notification has been read
  read,
  
  /// Notification has been dismissed
  dismissed,
  
  /// Notification has been archived
  archived,
}

/// Notification action for interactive notifications
@freezed
class NotificationAction with _$NotificationAction {
  const factory NotificationAction({
    required String id,
    required String label,
    required String actionType,
    Map<String, dynamic>? params,
  }) = _NotificationAction;

  factory NotificationAction.fromJson(Map<String, dynamic> json) =>
      _$NotificationActionFromJson(json);
}

/// Notification entity representing a single notification
///
/// Contains all information about a notification including content,
/// metadata, and interaction status.
@freezed
class Notification with _$Notification {
  const factory Notification({
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
    bool isPush,
    String? fcmMessageId,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);

  const Notification._();

  /// Check if notification is unread
  bool get isUnread => status == NotificationStatus.unread;

  /// Check if notification is read
  bool get isRead => status == NotificationStatus.read;

  /// Check if notification is dismissed
  bool get isDismissed => status == NotificationStatus.dismissed;

  /// Check if notification is expired
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Check if notification is critical
  bool get isCritical => priority == NotificationPriority.critical;

  /// Check if notification is actionable
  bool get hasActions => actions != null && actions!.isNotEmpty;

  /// Get notification age in minutes
  int get ageInMinutes => DateTime.now().difference(timestamp).inMinutes;

  /// Get notification age display string
  String get ageDisplay {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 30).floor()}mo ago';
    }
  }

  /// Get display color for notification priority
  String get priorityColor {
    switch (priority) {
      case NotificationPriority.low:
        return '#6B7280'; // Gray-500
      case NotificationPriority.normal:
        return '#3B82F6'; // Blue-500
      case NotificationPriority.high:
        return '#F59E0B'; // Amber-500
      case NotificationPriority.critical:
        return '#EF4444'; // Red-500
    }
  }

  /// Get icon for notification type
  String get typeIcon {
    switch (type) {
      case NotificationType.election:
        return 'how_to_vote';
      case NotificationType.system:
        return 'settings';
      case NotificationType.security:
        return 'security';
      case NotificationType.announcement:
        return 'campaign';
      case NotificationType.votingReminder:
        return 'notification_important';
      case NotificationType.deadline:
        return 'schedule';
    }
  }
}

/// Notification summary for overview displays
@freezed
class NotificationSummary with _$NotificationSummary {
  const factory NotificationSummary({
    required int totalCount,
    required int unreadCount,
    required int criticalCount,
    required Map<NotificationType, int> countByType,
    required DateTime? lastNotificationAt,
  }) = _NotificationSummary;

  factory NotificationSummary.fromJson(Map<String, dynamic> json) =>
      _$NotificationSummaryFromJson(json);
}