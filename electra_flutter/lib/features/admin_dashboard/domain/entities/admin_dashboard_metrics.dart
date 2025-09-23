import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_dashboard_metrics.freezed.dart';
part 'admin_dashboard_metrics.g.dart';

/// Admin dashboard metrics entity for displaying key system statistics
///
/// Contains comprehensive metrics about elections, users, votes, and system
/// performance for administrators and electoral committee members.
@freezed
class AdminDashboardMetrics with _$AdminDashboardMetrics {
  const factory AdminDashboardMetrics({
    /// Total number of active elections
    @Default(0) int activeElections,
    
    /// Total number of pending elections
    @Default(0) int pendingElections,
    
    /// Total number of completed elections
    @Default(0) int completedElections,
    
    /// Total number of registered voters
    @Default(0) int totalVoters,
    
    /// Total number of votes cast across all elections
    @Default(0) int totalVotesCast,
    
    /// Average voter turnout percentage
    @Default(0.0) double averageTurnout,
    
    /// Number of active user sessions
    @Default(0) int activeSessions,
    
    /// Number of pending user registrations
    @Default(0) int pendingRegistrations,
    
    /// Number of audit log entries today
    @Default(0) int auditLogsToday,
    
    /// System uptime in hours
    @Default(0.0) double systemUptime,
    
    /// Recent alerts and notifications count
    @Default(0) int alertCount,
    
    /// Security incidents count (last 24h)
    @Default(0) int securityIncidents,
    
    /// Database health status (0-100)
    @Default(100) int databaseHealth,
    
    /// API response time in milliseconds
    @Default(0.0) double apiResponseTime,
    
    /// Last system update timestamp
    DateTime? lastSystemUpdate,
    
    /// Timestamp when metrics were last updated
    DateTime? lastUpdated,
  }) = _AdminDashboardMetrics;

  factory AdminDashboardMetrics.fromJson(Map<String, dynamic> json) =>
      _$AdminDashboardMetricsFromJson(json);
}

/// Quick action item entity for admin dashboard
@freezed
class QuickAction with _$QuickAction {
  const factory QuickAction({
    /// Unique identifier for the action
    required String id,
    
    /// Display title for the action
    required String title,
    
    /// Description of what the action does
    required String description,
    
    /// Icon code for the action
    required int iconCode,
    
    /// Color code for the action
    required int colorCode,
    
    /// Route to navigate when action is tapped
    required String route,
    
    /// Whether the action requires additional permissions
    @Default(false) bool requiresElevatedAccess,
    
    /// Badge count for notifications (0 means no badge)
    @Default(0) int badgeCount,
    
    /// Whether the action is currently enabled
    @Default(true) bool isEnabled,
  }) = _QuickAction;

  factory QuickAction.fromJson(Map<String, dynamic> json) =>
      _$QuickActionFromJson(json);
}

/// System alert entity for admin dashboard
@freezed
class SystemAlert with _$SystemAlert {
  const factory SystemAlert({
    /// Unique identifier for the alert
    required String id,
    
    /// Alert title
    required String title,
    
    /// Alert message
    required String message,
    
    /// Alert severity level
    required AlertSeverity severity,
    
    /// Alert category
    required AlertCategory category,
    
    /// Whether the alert has been acknowledged
    @Default(false) bool isAcknowledged,
    
    /// Timestamp when alert was created
    required DateTime createdAt,
    
    /// Timestamp when alert was acknowledged (if any)
    DateTime? acknowledgedAt,
    
    /// User ID who acknowledged the alert (if any)
    String? acknowledgedBy,
    
    /// Additional data associated with the alert
    Map<String, dynamic>? metadata,
  }) = _SystemAlert;

  factory SystemAlert.fromJson(Map<String, dynamic> json) =>
      _$SystemAlertFromJson(json);
}

/// Alert severity levels
enum AlertSeverity {
  @JsonValue('low')
  low,
  @JsonValue('medium') 
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical;

  /// Get display name for the severity
  String get displayName {
    switch (this) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  /// Get color code for the severity
  int get colorCode {
    switch (this) {
      case AlertSeverity.low:
        return 0xFF10B981; // Success green
      case AlertSeverity.medium:
        return 0xFFF59E0B; // Warning amber
      case AlertSeverity.high:
        return 0xFFEF4444; // Error red
      case AlertSeverity.critical:
        return 0xFF7C2D12; // Dark red
    }
  }
}

/// Alert categories
enum AlertCategory {
  @JsonValue('system')
  system,
  @JsonValue('security')
  security,
  @JsonValue('election')
  election,
  @JsonValue('user')
  user,
  @JsonValue('audit')
  audit;

  /// Get display name for the category
  String get displayName {
    switch (this) {
      case AlertCategory.system:
        return 'System';
      case AlertCategory.security:
        return 'Security';
      case AlertCategory.election:
        return 'Election';
      case AlertCategory.user:
        return 'User';
      case AlertCategory.audit:
        return 'Audit';
    }
  }
}