part of 'auth_bloc.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated &&
          runtimeType == other.runtimeType &&
          user.id == other.user.id;

  @override
  int get hashCode => user.id.hashCode;
}

class AuthUnauthenticated extends AuthState {}

class AuthEmailVerificationSent extends AuthState {}

class AuthEmailVerified extends AuthState {}

class AuthPasswordResetSent extends AuthState {}

class AuthPasswordResetSuccess extends AuthState {}

class AuthPasswordChanged extends AuthState {}

class AuthBiometricUpdated extends AuthState {
  final bool enabled;

  const AuthBiometricUpdated({required this.enabled});
}

class AuthError extends AuthState {
  final String message;
  final String? code;

  const AuthError({
    required this.message,
    this.code,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

class AuthValidationError extends AuthState {
  final String message;
  final String? field;

  const AuthValidationError({
    required this.message,
    this.field,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthValidationError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          field == other.field;

  @override
  int get hashCode => message.hashCode ^ field.hashCode;
}