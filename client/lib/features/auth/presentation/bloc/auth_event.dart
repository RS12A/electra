part of 'auth_bloc.dart';

abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String matricNumber;
  final String password;

  AuthLoginRequested({
    required this.matricNumber,
    required this.password,
  });
}

class AuthRegisterRequested extends AuthEvent {
  final String matricNumber;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? department;
  final String? faculty;
  final int? yearOfStudy;

  AuthRegisterRequested({
    required this.matricNumber,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.department,
    this.faculty,
    this.yearOfStudy,
  });
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckStatusRequested extends AuthEvent {}

class AuthEmailVerificationRequested extends AuthEvent {
  final String token;

  AuthEmailVerificationRequested({required this.token});
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;

  AuthForgotPasswordRequested({required this.email});
}

class AuthResetPasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;

  AuthResetPasswordRequested({
    required this.token,
    required this.newPassword,
  });
}

class AuthChangePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  AuthChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });
}

class AuthBiometricToggleRequested extends AuthEvent {
  final bool enabled;
  final String? biometricData;

  AuthBiometricToggleRequested({
    required this.enabled,
    this.biometricData,
  });
}