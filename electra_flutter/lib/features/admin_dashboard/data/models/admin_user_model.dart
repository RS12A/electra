import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/admin_user.dart';

part 'admin_user_model.freezed.dart';
part 'admin_user_model.g.dart';

/// Data model for admin user
@freezed
class AdminUserModel with _$AdminUserModel {
  const factory AdminUserModel({
    required String id,
    required String email,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    @JsonKey(name: 'id_number') String? idNumber,
    String? department,
    @JsonKey(name: 'academic_level') String? academicLevel,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    @JsonKey(name: 'profile_photo_url') String? profilePhotoUrl,
    required String role, // Will be converted to/from enum
    required String status, // Will be converted to/from enum
    @JsonKey(name: 'is_email_verified') @Default(false) bool isEmailVerified,
    @JsonKey(name: 'is_phone_verified') @Default(false) bool isPhoneVerified,
    @JsonKey(name: 'has_biometric_auth') @Default(false) bool hasBiometricAuth,
    @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
    @JsonKey(name: 'last_active_at') DateTime? lastActiveAt,
    @JsonKey(name: 'failed_login_attempts') @Default(0) int failedLoginAttempts,
    @JsonKey(name: 'locked_until') DateTime? lockedUntil,
    @Default([]) List<String> permissions, // Will be converted to/from enum list
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? metadata,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'last_modified_by') String? lastModifiedBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _AdminUserModel;

  factory AdminUserModel.fromJson(Map<String, dynamic> json) =>
      _$AdminUserModelFromJson(json);

  const AdminUserModel._();

  /// Convert model to domain entity
  AdminUser toEntity() {
    return AdminUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      idNumber: idNumber,
      department: department,
      academicLevel: academicLevel,
      phoneNumber: phoneNumber,
      profilePhotoUrl: profilePhotoUrl,
      role: _parseUserRole(role),
      status: _parseAccountStatus(status),
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
      hasBiometricAuth: hasBiometricAuth,
      lastLoginAt: lastLoginAt,
      lastActiveAt: lastActiveAt,
      failedLoginAttempts: failedLoginAttempts,
      lockedUntil: lockedUntil,
      permissions: _parsePermissions(permissions),
      preferences: preferences,
      metadata: metadata,
      createdBy: createdBy,
      lastModifiedBy: lastModifiedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create model from domain entity
  factory AdminUserModel.fromEntity(AdminUser entity) {
    return AdminUserModel(
      id: entity.id,
      email: entity.email,
      firstName: entity.firstName,
      lastName: entity.lastName,
      idNumber: entity.idNumber,
      department: entity.department,
      academicLevel: entity.academicLevel,
      phoneNumber: entity.phoneNumber,
      profilePhotoUrl: entity.profilePhotoUrl,
      role: entity.role.name,
      status: entity.status.name,
      isEmailVerified: entity.isEmailVerified,
      isPhoneVerified: entity.isPhoneVerified,
      hasBiometricAuth: entity.hasBiometricAuth,
      lastLoginAt: entity.lastLoginAt,
      lastActiveAt: entity.lastActiveAt,
      failedLoginAttempts: entity.failedLoginAttempts,
      lockedUntil: entity.lockedUntil,
      permissions: entity.permissions.map((p) => p.name).toList(),
      preferences: entity.preferences,
      metadata: entity.metadata,
      createdBy: entity.createdBy,
      lastModifiedBy: entity.lastModifiedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  UserRole _parseUserRole(String roleString) {
    return UserRole.values.firstWhere(
      (e) => e.name == roleString,
      orElse: () => UserRole.student,
    );
  }

  AccountStatus _parseAccountStatus(String statusString) {
    return AccountStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => AccountStatus.pending,
    );
  }

  List<UserPermission> _parsePermissions(List<String> permissionStrings) {
    return permissionStrings
        .map((p) => UserPermission.values.firstWhere(
              (e) => e.name == p,
              orElse: () => UserPermission.readElections,
            ))
        .toList();
  }
}

/// User activity log data model
@freezed
class UserActivityLogModel with _$UserActivityLogModel {
  const factory UserActivityLogModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String action, // Will be converted to/from enum
    required String description,
    @JsonKey(name: 'resource_id') String? resourceId,
    @JsonKey(name: 'resource_type') String? resourceType,
    @JsonKey(name: 'ip_address') String? ipAddress,
    @JsonKey(name: 'user_agent') String? userAgent,
    Map<String, dynamic>? metadata,
    required DateTime timestamp,
    @JsonKey(name: 'was_successful') @Default(true) bool wasSuccessful,
    @JsonKey(name: 'error_message') String? errorMessage,
  }) = _UserActivityLogModel;

  factory UserActivityLogModel.fromJson(Map<String, dynamic> json) =>
      _$UserActivityLogModelFromJson(json);

  const UserActivityLogModel._();

  UserActivityLog toEntity() {
    return UserActivityLog(
      id: id,
      userId: userId,
      action: _parseUserAction(action),
      description: description,
      resourceId: resourceId,
      resourceType: resourceType,
      ipAddress: ipAddress,
      userAgent: userAgent,
      metadata: metadata,
      timestamp: timestamp,
      wasSuccessful: wasSuccessful,
      errorMessage: errorMessage,
    );
  }

  factory UserActivityLogModel.fromEntity(UserActivityLog entity) {
    return UserActivityLogModel(
      id: entity.id,
      userId: entity.userId,
      action: entity.action.name,
      description: entity.description,
      resourceId: entity.resourceId,
      resourceType: entity.resourceType,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      metadata: entity.metadata,
      timestamp: entity.timestamp,
      wasSuccessful: entity.wasSuccessful,
      errorMessage: entity.errorMessage,
    );
  }

  UserAction _parseUserAction(String actionString) {
    return UserAction.values.firstWhere(
      (e) => e.name == actionString,
      orElse: () => UserAction.login,
    );
  }
}

/// Bulk user operation result data model
@freezed
class BulkUserOperationResultModel with _$BulkUserOperationResultModel {
  const factory BulkUserOperationResultModel({
    @JsonKey(name: 'total_processed') required int totalProcessed,
    @JsonKey(name: 'success_count') required int successCount,
    @JsonKey(name: 'failure_count') required int failureCount,
    @JsonKey(name: 'successful_user_ids') @Default([]) List<String> successfulUserIds,
    @Default([]) List<FailedOperationModel> failures,
    required String status, // Will be converted to/from enum
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') required DateTime endTime,
  }) = _BulkUserOperationResultModel;

  factory BulkUserOperationResultModel.fromJson(Map<String, dynamic> json) =>
      _$BulkUserOperationResultModelFromJson(json);

  const BulkUserOperationResultModel._();

  BulkUserOperationResult toEntity() {
    return BulkUserOperationResult(
      totalProcessed: totalProcessed,
      successCount: successCount,
      failureCount: failureCount,
      successfulUserIds: successfulUserIds,
      failures: failures.map((f) => f.toEntity()).toList(),
      status: _parseBulkOperationStatus(status),
      startTime: startTime,
      endTime: endTime,
    );
  }

  factory BulkUserOperationResultModel.fromEntity(BulkUserOperationResult entity) {
    return BulkUserOperationResultModel(
      totalProcessed: entity.totalProcessed,
      successCount: entity.successCount,
      failureCount: entity.failureCount,
      successfulUserIds: entity.successfulUserIds,
      failures: entity.failures.map((f) => FailedOperationModel.fromEntity(f)).toList(),
      status: entity.status.name,
      startTime: entity.startTime,
      endTime: entity.endTime,
    );
  }

  BulkOperationStatus _parseBulkOperationStatus(String statusString) {
    return BulkOperationStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => BulkOperationStatus.failed,
    );
  }
}

/// Failed operation data model
@freezed
class FailedOperationModel with _$FailedOperationModel {
  const factory FailedOperationModel({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'error_message') required String errorMessage,
    @JsonKey(name: 'error_code') String? errorCode,
    @JsonKey(name: 'error_details') Map<String, dynamic>? errorDetails,
  }) = _FailedOperationModel;

  factory FailedOperationModel.fromJson(Map<String, dynamic> json) =>
      _$FailedOperationModelFromJson(json);

  const FailedOperationModel._();

  FailedOperation toEntity() {
    return FailedOperation(
      userId: userId,
      errorMessage: errorMessage,
      errorCode: errorCode,
      errorDetails: errorDetails,
    );
  }

  factory FailedOperationModel.fromEntity(FailedOperation entity) {
    return FailedOperationModel(
      userId: entity.userId,
      errorMessage: entity.errorMessage,
      errorCode: entity.errorCode,
      errorDetails: entity.errorDetails,
    );
  }
}