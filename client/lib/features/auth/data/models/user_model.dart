import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String id,
    required String matricNumber,
    required String email,
    required String firstName,
    required String lastName,
    required String role,
    String? department,
    String? faculty,
    int? yearOfStudy,
    required bool isActive,
    required bool isVerified,
    required bool biometricEnabled,
    DateTime? lastLogin,
  }) : super(
          id: id,
          matricNumber: matricNumber,
          email: email,
          firstName: firstName,
          lastName: lastName,
          role: role,
          department: department,
          faculty: faculty,
          yearOfStudy: yearOfStudy,
          isActive: isActive,
          isVerified: isVerified,
          biometricEnabled: biometricEnabled,
          lastLogin: lastLogin,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      matricNumber: json['matricNumber'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
      department: json['department'] as String?,
      faculty: json['faculty'] as String?,
      yearOfStudy: json['yearOfStudy'] as int?,
      isActive: json['isActive'] as bool,
      isVerified: json['isVerified'] as bool,
      biometricEnabled: json['biometricEnabled'] as bool,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricNumber': matricNumber,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'department': department,
      'faculty': faculty,
      'yearOfStudy': yearOfStudy,
      'isActive': isActive,
      'isVerified': isVerified,
      'biometricEnabled': biometricEnabled,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? matricNumber,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
    String? department,
    String? faculty,
    int? yearOfStudy,
    bool? isActive,
    bool? isVerified,
    bool? biometricEnabled,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      matricNumber: matricNumber ?? this.matricNumber,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      department: department ?? this.department,
      faculty: faculty ?? this.faculty,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}