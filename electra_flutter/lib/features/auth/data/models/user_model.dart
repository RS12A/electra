import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_model.g.dart';

/// User data model for API serialization/deserialization
///
/// This model extends the domain User entity with JSON serialization capabilities
/// for API communication and local storage.
@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required String id,
    required String email,
    required String fullName,
    required UserRole role,
    String? matricNumber,
    String? staffId,
    required bool isEmailVerified,
    bool isBiometricEnabled = false,
    String? profilePictureUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          email: email,
          fullName: fullName,
          role: role,
          matricNumber: matricNumber,
          staffId: staffId,
          isEmailVerified: isEmailVerified,
          isBiometricEnabled: isBiometricEnabled,
          profilePictureUrl: profilePictureUrl,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Create UserModel from domain User entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      matricNumber: user.matricNumber,
      staffId: user.staffId,
      isEmailVerified: user.isEmailVerified,
      isBiometricEnabled: user.isBiometricEnabled,
      profilePictureUrl: user.profilePictureUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: UserRoleExtension.fromString(json['role'] as String),
      matricNumber: json['matric_number'] as String?,
      staffId: json['staff_id'] as String?,
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      isBiometricEnabled: json['is_biometric_enabled'] as bool? ?? false,
      profilePictureUrl: json['profile_picture_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.toApiString(),
      'matric_number': matricNumber,
      'staff_id': staffId,
      'is_email_verified': isEmailVerified,
      'is_biometric_enabled': isBiometricEnabled,
      'profile_picture_url': profilePictureUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert to domain User entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      fullName: fullName,
      role: role,
      matricNumber: matricNumber,
      staffId: staffId,
      isEmailVerified: isEmailVerified,
      isBiometricEnabled: isBiometricEnabled,
      profilePictureUrl: profilePictureUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create copy with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    String? matricNumber,
    String? staffId,
    bool? isEmailVerified,
    bool? isBiometricEnabled,
    String? profilePictureUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      matricNumber: matricNumber ?? this.matricNumber,
      staffId: staffId ?? this.staffId,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}