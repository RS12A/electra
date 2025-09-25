import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_exception.dart';
import '../domain/entities/user.dart';
import '../domain/entities/auth_entities.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/password_recovery_usecase.dart';
import '../domain/usecases/biometric_auth_usecase.dart';

part 'auth_provider.g.dart';

/// Authentication state
class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final bool isBiometricEnabled;
  final bool canUseBiometric;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.isBiometricEnabled = false,
    this.canUseBiometric = false,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool? isBiometricEnabled,
    bool? canUseBiometric,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      canUseBiometric: canUseBiometric ?? this.canUseBiometric,
    );
  }

  @override
  String toString() {
    return 'AuthState(isAuthenticated: $isAuthenticated, isLoading: $isLoading, error: $error)';
  }
}

/// Authentication state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final PasswordRecoveryUseCase _passwordRecoveryUseCase;
  final BiometricAuthUseCase _biometricAuthUseCase;

  AuthNotifier(
    this._loginUseCase,
    this._registerUseCase,
    this._passwordRecoveryUseCase,
    this._biometricAuthUseCase,
  ) : super(const AuthState()) {
    _initialize();
  }

  /// Initialize authentication state
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Check for auto-login capability
      final autoLoginResult = await _loginUseCase.canAutoLogin();
      final canAutoLogin = autoLoginResult.fold(
        (error) => false,
        (canLogin) => canLogin,
      );

      // Check biometric availability
      final biometricAvailable = await _biometricAuthUseCase.isAvailable();
      final canUseBiometric = biometricAvailable.fold(
        (error) => false,
        (available) => available,
      );

      final biometricEnabled = await _biometricAuthUseCase.isEnabled();
      final isBiometricEnabled = biometricEnabled.fold(
        (error) => false,
        (enabled) => enabled,
      );

      if (canAutoLogin) {
        await _performAutoLogin();
      } else {
        state = state.copyWith(
          isLoading: false,
          canUseBiometric: canUseBiometric,
          isBiometricEnabled: isBiometricEnabled,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Initialization failed: ${e.toString()}',
      );
    }
  }

  /// Perform auto-login with stored credentials
  Future<void> _performAutoLogin() async {
    final result = await _loginUseCase.autoLogin();
    result.fold(
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
      },
      (authResponse) {
        state = state.copyWith(
          user: authResponse.user,
          isAuthenticated: true,
          isLoading: false,
          clearError: true,
        );
      },
    );
  }

  /// Login with credentials
  Future<bool> login(LoginCredentials credentials) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _loginUseCase.call(credentials);
    return result.fold(
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
        return false;
      },
      (authResponse) {
        state = state.copyWith(
          user: authResponse.user,
          isAuthenticated: true,
          isLoading: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  /// Login with biometric authentication
  Future<bool> loginWithBiometric() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _loginUseCase.loginWithBiometrics();
    return result.fold(
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
        return false;
      },
      (authResponse) {
        state = state.copyWith(
          user: authResponse.user,
          isAuthenticated: true,
          isLoading: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  /// Register new user
  Future<bool> register(RegistrationData registrationData) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _registerUseCase.call(registrationData);
    return result.fold(
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
        return false;
      },
      (authResponse) {
        state = state.copyWith(
          user: authResponse.user,
          isAuthenticated: true,
          isLoading: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  /// Send password reset OTP
  Future<bool> sendPasswordResetOtp(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _passwordRecoveryUseCase.sendPasswordResetOtp(email);
    return result.fold(
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  /// Verify OTP code
  Future<bool> verifyOtp(String email, String otpCode) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _passwordRecoveryUseCase.verifyOtp(
      email: email,
      otpCode: otpCode,
    );
    return result.fold(
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  /// Reset password
  Future<bool> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _passwordRecoveryUseCase.resetPassword(
      email: email,
      otpCode: otpCode,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    return result.fold(
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _biometricAuthUseCase.enable();
    return result.fold(
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          isBiometricEnabled: true,
          clearError: true,
        );
        return true;
      },
    );
  }

  /// Disable biometric authentication
  Future<bool> disableBiometric() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _biometricAuthUseCase.disable();
    return result.fold(
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          isBiometricEnabled: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  /// Logout user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      // Call repository logout method to clear tokens and data 
      final result = await _loginUseCase.logout();
      
      result.fold(
        (failure) {
          // Even if server logout fails, clear local state
          state = const AuthState(); // Reset to initial state
        },
        (_) {
          state = const AuthState(); // Reset to initial state
        },
      );
    } catch (e) {
      // Always clear local state even on error
      state = const AuthState(); // Reset to initial state
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Update biometric capabilities
  Future<void> updateBiometricCapabilities() async {
    final biometricAvailable = await _biometricAuthUseCase.isAvailable();
    final canUseBiometric = biometricAvailable.fold(
      (error) => false,
      (available) => available,
    );

    final biometricEnabled = await _biometricAuthUseCase.isEnabled();
    final isBiometricEnabled = biometricEnabled.fold(
      (error) => false,
      (enabled) => enabled,
    );

    state = state.copyWith(
      canUseBiometric: canUseBiometric,
      isBiometricEnabled: isBiometricEnabled,
    );
  }
}

/// Temporary auth state provider (will be replaced with proper implementation)
final authStateProvider = StateProvider<AuthState>((ref) => const AuthState());

/// Convenience providers for specific auth state properties
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).error;
});

final canUseBiometricProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).canUseBiometric;
});

final isBiometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isBiometricEnabled;
});