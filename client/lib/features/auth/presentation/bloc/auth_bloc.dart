import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../../../core/error/failures.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
  }) : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckStatusRequested>(_onCheckStatusRequested);
    on<AuthEmailVerificationRequested>(_onEmailVerificationRequested);
    on<AuthForgotPasswordRequested>(_onForgotPasswordRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthChangePasswordRequested>(_onChangePasswordRequested);
    on<AuthBiometricToggleRequested>(_onBiometricToggleRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await loginUseCase(
      matricNumber: event.matricNumber,
      password: event.password,
    );

    result.fold(
      (failure) => emit(_mapFailureToState(failure)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await registerUseCase(
      matricNumber: event.matricNumber,
      email: event.email,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
      department: event.department,
      faculty: event.faculty,
      yearOfStudy: event.yearOfStudy,
    );

    result.fold(
      (failure) => emit(_mapFailureToState(failure)),
      (user) => emit(AuthEmailVerificationSent()),
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await logoutUseCase();

    result.fold(
      (failure) => emit(AuthUnauthenticated()), // Still logout locally even if server fails
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onCheckStatusRequested(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    // This would check if user is authenticated from local storage
    // For now, emit unauthenticated
    emit(AuthUnauthenticated());
  }

  Future<void> _onEmailVerificationRequested(
    AuthEmailVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // TODO: Implement email verification use case
    // For now, just emit success
    emit(AuthEmailVerified());
  }

  Future<void> _onForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // TODO: Implement forgot password use case
    // For now, just emit success
    emit(AuthPasswordResetSent());
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // TODO: Implement reset password use case
    // For now, just emit success
    emit(AuthPasswordResetSuccess());
  }

  Future<void> _onChangePasswordRequested(
    AuthChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // TODO: Implement change password use case
    // For now, just emit success
    emit(AuthPasswordChanged());
  }

  Future<void> _onBiometricToggleRequested(
    AuthBiometricToggleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    // TODO: Implement biometric toggle use case
    // For now, just emit success
    emit(AuthBiometricUpdated(enabled: event.enabled));
  }

  AuthState _mapFailureToState(Failure failure) {
    if (failure is ValidationFailure) {
      return AuthValidationError(
        message: failure.message,
        field: failure.code,
      );
    } else if (failure is AuthFailure) {
      return AuthError(
        message: failure.message,
        code: failure.code,
      );
    } else if (failure is NetworkFailure) {
      return AuthError(
        message: failure.message,
        code: 'NETWORK_ERROR',
      );
    } else if (failure is ServerFailure) {
      return AuthError(
        message: failure.message,
        code: failure.code,
      );
    } else {
      return const AuthError(
        message: 'An unexpected error occurred',
        code: 'UNKNOWN_ERROR',
      );
    }
  }
}