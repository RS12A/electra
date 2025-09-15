class UserEntity {
  final String id;
  final String matricNumber;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? department;
  final String? faculty;
  final int? yearOfStudy;
  final bool isActive;
  final bool isVerified;
  final bool biometricEnabled;
  final DateTime? lastLogin;

  const UserEntity({
    required this.id,
    required this.matricNumber,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.department,
    this.faculty,
    this.yearOfStudy,
    required this.isActive,
    required this.isVerified,
    required this.biometricEnabled,
    this.lastLogin,
  });

  String get fullName => '$firstName $lastName';

  bool get isStudent => role == 'STUDENT';
  bool get isAdmin => role == 'ADMIN';
  bool get isElectoralCommittee => role == 'ELECTORAL_COMMITTEE';
}