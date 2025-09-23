import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_user.freezed.dart';
part 'admin_user.g.dart';

/// Admin user entity for user management operations
///
/// Extended user entity specifically for administrative user management
/// with role-based access control and detailed user information.
@freezed
class AdminUser with _$AdminUser {
  const factory AdminUser({
    /// Unique identifier for the user
    required String id,
    
    /// User's email address (unique)
    required String email,
    
    /// User's first name
    required String firstName,
    
    /// User's last name
    required String lastName,
    
    /// Student/Staff ID number
    String? idNumber,
    
    /// Department or faculty
    String? department,
    
    /// Academic level (for students)
    String? academicLevel,
    
    /// Phone number
    String? phoneNumber,
    
    /// Profile photo URL
    String? profilePhotoUrl,
    
    /// User role in the system
    required UserRole role,
    
    /// Account status
    required AccountStatus status,
    
    /// Whether email is verified
    @Default(false) bool isEmailVerified,
    
    /// Whether phone is verified
    @Default(false) bool isPhoneVerified,
    
    /// Whether biometric authentication is enabled
    @Default(false) bool hasBiometricAuth,
    
    /// Last login timestamp
    DateTime? lastLoginAt,
    
    /// Last active timestamp
    DateTime? lastActiveAt,
    
    /// Number of failed login attempts
    @Default(0) int failedLoginAttempts,
    
    /// Account locked until (if locked)
    DateTime? lockedUntil,
    
    /// Permissions granted to the user
    @Default([]) List<UserPermission> permissions,
    
    /// User preferences and settings
    Map<String, dynamic>? preferences,
    
    /// Additional user metadata
    Map<String, dynamic>? metadata,
    
    /// Created by user ID
    String? createdBy,
    
    /// Last modified by user ID
    String? lastModifiedBy,
    
    /// Creation timestamp
    required DateTime createdAt,
    
    /// Last modification timestamp
    DateTime? updatedAt,
  }) = _AdminUser;

  factory AdminUser.fromJson(Map<String, dynamic> json) =>
      _$AdminUserFromJson(json);
}

/// User activity log entry for tracking user actions
@freezed
class UserActivityLog with _$UserActivityLog {
  const factory UserActivityLog({
    /// Unique identifier for the log entry
    required String id,
    
    /// User ID who performed the action
    required String userId,
    
    /// Action type performed
    required UserAction action,
    
    /// Detailed description of the action
    required String description,
    
    /// Resource affected (election ID, candidate ID, etc.)
    String? resourceId,
    
    /// Resource type (election, candidate, user, etc.)
    String? resourceType,
    
    /// IP address of the user
    String? ipAddress,
    
    /// User agent string
    String? userAgent,
    
    /// Additional metadata about the action
    Map<String, dynamic>? metadata,
    
    /// Timestamp when action was performed
    required DateTime timestamp,
    
    /// Whether the action was successful
    @Default(true) bool wasSuccessful,
    
    /// Error message if action failed
    String? errorMessage,
  }) = _UserActivityLog;

  factory UserActivityLog.fromJson(Map<String, dynamic> json) =>
      _$UserActivityLogFromJson(json);
}

/// Bulk user operation result
@freezed
class BulkUserOperationResult with _$BulkUserOperationResult {
  const factory BulkUserOperationResult({
    /// Total number of users processed
    required int totalProcessed,
    
    /// Number of successful operations
    required int successCount,
    
    /// Number of failed operations
    required int failureCount,
    
    /// List of successful user IDs
    @Default([]) List<String> successfulUserIds,
    
    /// List of failed operations with details
    @Default([]) List<FailedOperation> failures,
    
    /// Overall operation status
    required BulkOperationStatus status,
    
    /// Operation start time
    required DateTime startTime,
    
    /// Operation end time
    required DateTime endTime,
  }) = _BulkUserOperationResult;

  factory BulkUserOperationResult.fromJson(Map<String, dynamic> json) =>
      _$BulkUserOperationResultFromJson(json);
}

/// Failed operation details
@freezed
class FailedOperation with _$FailedOperation {
  const factory FailedOperation({
    /// User ID that failed
    required String userId,
    
    /// Error message
    required String errorMessage,
    
    /// Error code (if available)
    String? errorCode,
    
    /// Additional error details
    Map<String, dynamic>? errorDetails,
  }) = _FailedOperation;

  factory FailedOperation.fromJson(Map<String, dynamic> json) =>
      _$FailedOperationFromJson(json);
}

/// User role enumeration
enum UserRole {
  @JsonValue('student')
  student,
  @JsonValue('staff')
  staff,
  @JsonValue('faculty')
  faculty,
  @JsonValue('admin')
  admin,
  @JsonValue('electoral_committee')
  electoralCommittee,
  @JsonValue('system_admin')
  systemAdmin;

  /// Get display name for the role
  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.staff:
        return 'Staff';
      case UserRole.faculty:
        return 'Faculty';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.electoralCommittee:
        return 'Electoral Committee';
      case UserRole.systemAdmin:
        return 'System Administrator';
    }
  }

  /// Get color code for the role
  int get colorCode {
    switch (this) {
      case UserRole.student:
        return 0xFF3B82F6; // Blue
      case UserRole.staff:
        return 0xFF10B981; // Green
      case UserRole.faculty:
        return 0xFF8B5CF6; // Purple
      case UserRole.admin:
        return 0xFFF59E0B; // Amber
      case UserRole.electoralCommittee:
        return 0xFFEF4444; // Red
      case UserRole.systemAdmin:
        return 0xFF1F2937; // Gray-800
    }
  }

  /// Check if role has admin privileges
  bool get hasAdminPrivileges {
    switch (this) {
      case UserRole.admin:
      case UserRole.electoralCommittee:
      case UserRole.systemAdmin:
        return true;
      default:
        return false;
    }
  }
}

/// Account status enumeration
enum AccountStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('active')
  active,
  @JsonValue('inactive')
  inactive,
  @JsonValue('suspended')
  suspended,
  @JsonValue('locked')
  locked,
  @JsonValue('banned')
  banned;

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case AccountStatus.pending:
        return 'Pending';
      case AccountStatus.active:
        return 'Active';
      case AccountStatus.inactive:
        return 'Inactive';
      case AccountStatus.suspended:
        return 'Suspended';
      case AccountStatus.locked:
        return 'Locked';
      case AccountStatus.banned:
        return 'Banned';
    }
  }

  /// Get color code for the status
  int get colorCode {
    switch (this) {
      case AccountStatus.pending:
        return 0xFF6B7280; // Gray
      case AccountStatus.active:
        return 0xFF10B981; // Green
      case AccountStatus.inactive:
        return 0xFF9CA3AF; // Gray-400
      case AccountStatus.suspended:
        return 0xFFF59E0B; // Amber
      case AccountStatus.locked:
        return 0xFFEF4444; // Red
      case AccountStatus.banned:
        return 0xFF7C2D12; // Dark red
    }
  }
}

/// User permission enumeration
enum UserPermission {
  @JsonValue('read_elections')
  readElections,
  @JsonValue('create_elections')
  createElections,
  @JsonValue('update_elections')
  updateElections,
  @JsonValue('delete_elections')
  deleteElections,
  @JsonValue('manage_candidates')
  manageCandidates,
  @JsonValue('manage_users')
  manageUsers,
  @JsonValue('view_analytics')
  viewAnalytics,
  @JsonValue('export_data')
  exportData,
  @JsonValue('manage_system')
  manageSystem,
  @JsonValue('view_audit_logs')
  viewAuditLogs;

  /// Get display name for the permission
  String get displayName {
    switch (this) {
      case UserPermission.readElections:
        return 'View Elections';
      case UserPermission.createElections:
        return 'Create Elections';
      case UserPermission.updateElections:
        return 'Update Elections';
      case UserPermission.deleteElections:
        return 'Delete Elections';
      case UserPermission.manageCandidates:
        return 'Manage Candidates';
      case UserPermission.manageUsers:
        return 'Manage Users';
      case UserPermission.viewAnalytics:
        return 'View Analytics';
      case UserPermission.exportData:
        return 'Export Data';
      case UserPermission.manageSystem:
        return 'Manage System';
      case UserPermission.viewAuditLogs:
        return 'View Audit Logs';
    }
  }
}

/// User action enumeration for activity logging
enum UserAction {
  @JsonValue('login')
  login,
  @JsonValue('logout')
  logout,
  @JsonValue('register')
  register,
  @JsonValue('update_profile')
  updateProfile,
  @JsonValue('change_password')
  changePassword,
  @JsonValue('vote_cast')
  voteCast,
  @JsonValue('election_created')
  electionCreated,
  @JsonValue('election_updated')
  electionUpdated,
  @JsonValue('candidate_added')
  candidateAdded,
  @JsonValue('user_activated')
  userActivated,
  @JsonValue('user_suspended')
  userSuspended,
  @JsonValue('data_export')
  dataExport;

  /// Get display name for the action
  String get displayName {
    switch (this) {
      case UserAction.login:
        return 'Login';
      case UserAction.logout:
        return 'Logout';
      case UserAction.register:
        return 'Register';
      case UserAction.updateProfile:
        return 'Update Profile';
      case UserAction.changePassword:
        return 'Change Password';
      case UserAction.voteCast:
        return 'Vote Cast';
      case UserAction.electionCreated:
        return 'Election Created';
      case UserAction.electionUpdated:
        return 'Election Updated';
      case UserAction.candidateAdded:
        return 'Candidate Added';
      case UserAction.userActivated:
        return 'User Activated';
      case UserAction.userSuspended:
        return 'User Suspended';
      case UserAction.dataExport:
        return 'Data Export';
    }
  }
}

/// Bulk operation status enumeration
enum BulkOperationStatus {
  @JsonValue('success')
  success,
  @JsonValue('partial_success')
  partialSuccess,
  @JsonValue('failed')
  failed;

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case BulkOperationStatus.success:
        return 'Success';
      case BulkOperationStatus.partialSuccess:
        return 'Partial Success';
      case BulkOperationStatus.failed:
        return 'Failed';
    }
  }
}