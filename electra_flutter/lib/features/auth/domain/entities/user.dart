import 'package:equatable/equatable.dart';

/// User entity representing a user in the Electra system
///
/// This is the core user model used throughout the domain layer.
/// It contains all user information needed for authentication and authorization.
class User extends Equatable {
  /// Unique user identifier
  final String id;

  /// User's email address (used for login and communication)
  final String email;

  /// User's full name as registered
  final String fullName;

  /// User's role in the system (student, staff, admin, etc.)
  final UserRole role;

  /// Matriculation number for students
  final String? matricNumber;

  /// Staff ID for staff members
  final String? staffId;

  /// Whether the user has verified their email
  final bool isEmailVerified;

  /// Whether the user has enabled biometric authentication
  final bool isBiometricEnabled;

  /// User's profile picture URL (optional)
  final String? profilePictureUrl;

  /// Date when the user was created
  final DateTime createdAt;

  /// Date when the user was last updated
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.matricNumber,
    this.staffId,
    required this.isEmailVerified,
    this.isBiometricEnabled = false,
    this.profilePictureUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get the user's display identifier (matric number or staff ID)
  String get displayIdentifier {
    switch (role) {
      case UserRole.student:
        return matricNumber ?? email;
      case UserRole.staff:
      case UserRole.admin:
      case UserRole.electoralCommittee:
        return staffId ?? email;
    }
  }

  /// Check if user can access admin features
  bool get isAdmin => role == UserRole.admin || role == UserRole.electoralCommittee;

  /// Check if user is a student
  bool get isStudent => role == UserRole.student;

  /// Check if user is staff (includes admin and electoral committee)
  bool get isStaff => role == UserRole.staff || isAdmin;

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        role,
        matricNumber,
        staffId,
        isEmailVerified,
        isBiometricEnabled,
        profilePictureUrl,
        createdAt,
        updatedAt,
      ];

  /// Create a copy of the user with updated fields
  User copyWith({
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
    return User(
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

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, role: $role)';
  }
}

/// User roles in the Electra system
enum UserRole {
  /// Regular students who can vote
  student,

  /// Faculty and staff members who can vote
  staff,

  /// System administrators with full access
  admin,

  /// Electoral committee members with election management access
  electoralCommittee,
}

/// Extension methods for UserRole
extension UserRoleExtension on UserRole {
  /// Get human-readable name for the role
  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.staff:
        return 'Staff';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.electoralCommittee:
        return 'Electoral Committee';
    }
  }

  /// Get role description
  String get description {
    switch (this) {
      case UserRole.student:
        return 'Registered student with voting rights';
      case UserRole.staff:
        return 'Faculty or staff member with voting rights';
      case UserRole.admin:
        return 'System administrator with full access';
      case UserRole.electoralCommittee:
        return 'Electoral committee member with election management access';
    }
  }

  /// Convert from string representation
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'staff':
        return UserRole.staff;
      case 'admin':
        return UserRole.admin;
      case 'electoral_committee':
      case 'electoralcommittee':
        return UserRole.electoralCommittee;
      default:
        throw ArgumentError('Invalid user role: $role');
    }
  }

  /// Convert to string representation for API
  String toApiString() {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.staff:
        return 'staff';
      case UserRole.admin:
        return 'admin';
      case UserRole.electoralCommittee:
        return 'electoral_committee';
    }
  }
}