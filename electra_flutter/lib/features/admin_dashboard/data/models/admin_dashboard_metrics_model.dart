import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/admin_dashboard_metrics.dart';

part 'admin_dashboard_metrics_model.freezed.dart';
part 'admin_dashboard_metrics_model.g.dart';

/// Data model for admin dashboard metrics
///
/// Extends the domain entity with JSON serialization for API communication.
/// Contains factory methods for converting between model and entity.
@freezed
class AdminDashboardMetricsModel with _$AdminDashboardMetricsModel {
  const factory AdminDashboardMetricsModel({
    @JsonKey(name: 'active_elections') @Default(0) int activeElections,
    @JsonKey(name: 'pending_elections') @Default(0) int pendingElections,
    @JsonKey(name: 'completed_elections') @Default(0) int completedElections,
    @JsonKey(name: 'total_voters') @Default(0) int totalVoters,
    @JsonKey(name: 'total_votes_cast') @Default(0) int totalVotesCast,
    @JsonKey(name: 'average_turnout') @Default(0.0) double averageTurnout,
    @JsonKey(name: 'active_sessions') @Default(0) int activeSessions,
    @JsonKey(name: 'pending_registrations') @Default(0) int pendingRegistrations,
    @JsonKey(name: 'audit_logs_today') @Default(0) int auditLogsToday,
    @JsonKey(name: 'system_uptime') @Default(0.0) double systemUptime,
    @JsonKey(name: 'alert_count') @Default(0) int alertCount,
    @JsonKey(name: 'security_incidents') @Default(0) int securityIncidents,
    @JsonKey(name: 'database_health') @Default(100) int databaseHealth,
    @JsonKey(name: 'api_response_time') @Default(0.0) double apiResponseTime,
    @JsonKey(name: 'last_system_update') DateTime? lastSystemUpdate,
    @JsonKey(name: 'last_updated') DateTime? lastUpdated,
  }) = _AdminDashboardMetricsModel;

  factory AdminDashboardMetricsModel.fromJson(Map<String, dynamic> json) =>
      _$AdminDashboardMetricsModelFromJson(json);

  const AdminDashboardMetricsModel._();

  /// Convert model to domain entity
  AdminDashboardMetrics toEntity() {
    return AdminDashboardMetrics(
      activeElections: activeElections,
      pendingElections: pendingElections,
      completedElections: completedElections,
      totalVoters: totalVoters,
      totalVotesCast: totalVotesCast,
      averageTurnout: averageTurnout,
      activeSessions: activeSessions,
      pendingRegistrations: pendingRegistrations,
      auditLogsToday: auditLogsToday,
      systemUptime: systemUptime,
      alertCount: alertCount,
      securityIncidents: securityIncidents,
      databaseHealth: databaseHealth,
      apiResponseTime: apiResponseTime,
      lastSystemUpdate: lastSystemUpdate,
      lastUpdated: lastUpdated,
    );
  }

  /// Create model from domain entity
  factory AdminDashboardMetricsModel.fromEntity(AdminDashboardMetrics entity) {
    return AdminDashboardMetricsModel(
      activeElections: entity.activeElections,
      pendingElections: entity.pendingElections,
      completedElections: entity.completedElections,
      totalVoters: entity.totalVoters,
      totalVotesCast: entity.totalVotesCast,
      averageTurnout: entity.averageTurnout,
      activeSessions: entity.activeSessions,
      pendingRegistrations: entity.pendingRegistrations,
      auditLogsToday: entity.auditLogsToday,
      systemUptime: entity.systemUptime,
      alertCount: entity.alertCount,
      securityIncidents: entity.securityIncidents,
      databaseHealth: entity.databaseHealth,
      apiResponseTime: entity.apiResponseTime,
      lastSystemUpdate: entity.lastSystemUpdate,
      lastUpdated: entity.lastUpdated,
    );
  }
}

/// Quick action data model
@freezed
class QuickActionModel with _$QuickActionModel {
  const factory QuickActionModel({
    required String id,
    required String title,
    required String description,
    @JsonKey(name: 'icon_code') required int iconCode,
    @JsonKey(name: 'color_code') required int colorCode,
    required String route,
    @JsonKey(name: 'requires_elevated_access') @Default(false) bool requiresElevatedAccess,
    @JsonKey(name: 'badge_count') @Default(0) int badgeCount,
    @JsonKey(name: 'is_enabled') @Default(true) bool isEnabled,
  }) = _QuickActionModel;

  factory QuickActionModel.fromJson(Map<String, dynamic> json) =>
      _$QuickActionModelFromJson(json);

  const QuickActionModel._();

  /// Convert model to domain entity
  QuickAction toEntity() {
    return QuickAction(
      id: id,
      title: title,
      description: description,
      iconCode: iconCode,
      colorCode: colorCode,
      route: route,
      requiresElevatedAccess: requiresElevatedAccess,
      badgeCount: badgeCount,
      isEnabled: isEnabled,
    );
  }

  /// Create model from domain entity
  factory QuickActionModel.fromEntity(QuickAction entity) {
    return QuickActionModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      iconCode: entity.iconCode,
      colorCode: entity.colorCode,
      route: entity.route,
      requiresElevatedAccess: entity.requiresElevatedAccess,
      badgeCount: entity.badgeCount,
      isEnabled: entity.isEnabled,
    );
  }
}

/// System alert data model
@freezed
class SystemAlertModel with _$SystemAlertModel {
  const factory SystemAlertModel({
    required String id,
    required String title,
    required String message,
    required String severity, // Will be converted to/from enum
    required String category, // Will be converted to/from enum
    @JsonKey(name: 'is_acknowledged') @Default(false) bool isAcknowledged,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'acknowledged_at') DateTime? acknowledgedAt,
    @JsonKey(name: 'acknowledged_by') String? acknowledgedBy,
    Map<String, dynamic>? metadata,
  }) = _SystemAlertModel;

  factory SystemAlertModel.fromJson(Map<String, dynamic> json) =>
      _$SystemAlertModelFromJson(json);

  const SystemAlertModel._();

  /// Convert model to domain entity
  SystemAlert toEntity() {
    return SystemAlert(
      id: id,
      title: title,
      message: message,
      severity: _parseAlertSeverity(severity),
      category: _parseAlertCategory(category),
      isAcknowledged: isAcknowledged,
      createdAt: createdAt,
      acknowledgedAt: acknowledgedAt,
      acknowledgedBy: acknowledgedBy,
      metadata: metadata,
    );
  }

  /// Create model from domain entity
  factory SystemAlertModel.fromEntity(SystemAlert entity) {
    return SystemAlertModel(
      id: entity.id,
      title: entity.title,
      message: entity.message,
      severity: entity.severity.name,
      category: entity.category.name,
      isAcknowledged: entity.isAcknowledged,
      createdAt: entity.createdAt,
      acknowledgedAt: entity.acknowledgedAt,
      acknowledgedBy: entity.acknowledgedBy,
      metadata: entity.metadata,
    );
  }

  /// Parse severity string to enum
  AlertSeverity _parseAlertSeverity(String severityString) {
    return AlertSeverity.values.firstWhere(
      (e) => e.name == severityString,
      orElse: () => AlertSeverity.medium,
    );
  }

  /// Parse category string to enum
  AlertCategory _parseAlertCategory(String categoryString) {
    return AlertCategory.values.firstWhere(
      (e) => e.name == categoryString,
      orElse: () => AlertCategory.system,
    );
  }
}