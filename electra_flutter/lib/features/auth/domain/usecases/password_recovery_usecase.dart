import 'package:dartz/dartz.dart';

import '../../../core/error/app_exception.dart';
import '../entities/auth_entities.dart';
import '../repositories/auth_repository.dart';

/// Password recovery use case for OTP-based password reset
///
/// Implements a secure 3-step password recovery process:
/// 1. Request OTP via email
/// 2. Verify OTP code
/// 3. Reset password with verified OTP
class PasswordRecoveryUseCase {
  final AuthRepository _repository;

  const PasswordRecoveryUseCase(this._repository);

  /// Step 1: Send password reset OTP to email
  ///
  /// Validates email and sends OTP code for password recovery.
  Future<Either<AppException, void>> sendPasswordResetOtp(String email) async {
    try {
      // Validate email format
      if (email.isEmpty) {
        return const Left(ValidationException(
          message: 'Please enter your email address',
          code: 'EMAIL_REQUIRED',
        ));
      }

      if (!_repository.isValidEmail(email)) {
        return const Left(ValidationException.invalidEmail());
      }

      // Check network connectivity
      final networkResult = await _repository.hasNetworkConnection();
      return await networkResult.fold(
        (error) => Left(error),
        (hasNetwork) async {
          if (!hasNetwork) {
            return const Left(NetworkException.noConnection());
          }

          // Send OTP request
          final request = PasswordResetRequest(email: email);
          return await _repository.sendPasswordResetOtp(request);
        },
      );
    } catch (e) {
      return Left(AuthException(
        message: 'Failed to send reset code: ${e.toString()}',
        code: 'SEND_OTP_ERROR',
      ));
    }
  }

  /// Step 2: Verify OTP code
  ///
  /// Validates and verifies the OTP code sent to user's email.
  Future<Either<AppException, void>> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      // Validate input
      final validationError = _validateOtpInput(email, otpCode);
      if (validationError != null) {
        return Left(validationError);
      }

      // Check network connectivity
      final networkResult = await _repository.hasNetworkConnection();
      return await networkResult.fold(
        (error) => Left(error),
        (hasNetwork) async {
          if (!hasNetwork) {
            return const Left(NetworkException.noConnection());
          }

          // Verify OTP
          final verification = OtpVerification(
            email: email,
            otpCode: otpCode,
          );
          return await _repository.verifyOtp(verification);
        },
      );
    } catch (e) {
      return Left(AuthException(
        message: 'Failed to verify code: ${e.toString()}',
        code: 'VERIFY_OTP_ERROR',
      ));
    }
  }

  /// Step 3: Reset password with verified OTP
  ///
  /// Resets user password using verified OTP and new password.
  Future<Either<AppException, void>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      // Validate input
      final validationError = _validatePasswordResetInput(
        email,
        otpCode,
        newPassword,
        confirmPassword,
      );
      if (validationError != null) {
        return Left(validationError);
      }

      // Check network connectivity
      final networkResult = await _repository.hasNetworkConnection();
      return await networkResult.fold(
        (error) => Left(error),
        (hasNetwork) async {
          if (!hasNetwork) {
            return const Left(NetworkException.noConnection());
          }

          // Reset password
          final verification = OtpVerification(
            email: email,
            otpCode: otpCode,
            newPassword: newPassword,
          );
          return await _repository.resetPassword(verification);
        },
      );
    } catch (e) {
      return Left(AuthException(
        message: 'Failed to reset password: ${e.toString()}',
        code: 'RESET_PASSWORD_ERROR',
      ));
    }
  }

  /// Complete password recovery flow
  ///
  /// Executes the complete password recovery process in one call.
  /// This is useful for testing and simplified implementations.
  Future<Either<AppException, void>> completePasswordRecovery({
    required String email,
    required String otpCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // First verify OTP
    final verifyResult = await verifyOtp(email: email, otpCode: otpCode);
    
    return await verifyResult.fold(
      (error) => Left(error),
      (_) async {
        // Then reset password
        return await resetPassword(
          email: email,
          otpCode: otpCode,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        );
      },
    );
  }

  /// Validate OTP format
  ///
  /// Returns true if OTP code format is valid.
  bool isValidOtpFormat(String otpCode) {
    // OTP should be 6 digits
    return RegExp(r'^\d{6}$').hasMatch(otpCode);
  }

  /// Get password requirements for display
  ///
  /// Returns list of password requirements for user guidance.
  List<String> getPasswordRequirements() {
    return [
      'At least 8 characters long',
      'Contains at least one uppercase letter (A-Z)',
      'Contains at least one lowercase letter (a-z)',
      'Contains at least one number (0-9)',
      'Contains at least one special character (@\$!%*?&)',
      'Does not contain common passwords',
    ];
  }

  /// Check password strength
  ///
  /// Returns strength score from 0-4 (0=very weak, 4=very strong).
  int checkPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (RegExp(r'(?=.*[a-z])').hasMatch(password)) score++;
    if (RegExp(r'(?=.*[A-Z])').hasMatch(password)) score++;
    if (RegExp(r'(?=.*\d)').hasMatch(password)) score++;
    if (RegExp(r'(?=.*[@$!%*?&])').hasMatch(password)) score++;

    // Reduce score for common patterns
    if (password.toLowerCase().contains('password') ||
        password.toLowerCase().contains('12345') ||
        password.toLowerCase().contains('qwerty')) {
      score = (score - 2).clamp(0, 4);
    }

    return score;
  }

  /// Get password strength description
  String getPasswordStrengthDescription(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }

  /// Validate OTP input parameters
  ValidationException? _validateOtpInput(String email, String otpCode) {
    if (email.isEmpty) {
      return const ValidationException(
        message: 'Email is required',
        code: 'EMAIL_REQUIRED',
      );
    }

    if (!_repository.isValidEmail(email)) {
      return const ValidationException.invalidEmail();
    }

    if (otpCode.isEmpty) {
      return const ValidationException(
        message: 'Please enter the verification code',
        code: 'OTP_REQUIRED',
      );
    }

    if (!isValidOtpFormat(otpCode)) {
      return const ValidationException(
        message: 'Verification code must be 6 digits',
        code: 'INVALID_OTP_FORMAT',
      );
    }

    return null;
  }

  /// Validate password reset input parameters
  ValidationException? _validatePasswordResetInput(
    String email,
    String otpCode,
    String newPassword,
    String confirmPassword,
  ) {
    // First validate OTP input
    final otpError = _validateOtpInput(email, otpCode);
    if (otpError != null) {
      return otpError;
    }

    // Validate new password
    if (newPassword.isEmpty) {
      return const ValidationException(
        message: 'Please enter a new password',
        code: 'NEW_PASSWORD_REQUIRED',
      );
    }

    if (!_repository.isValidPassword(newPassword)) {
      return const ValidationException.invalidPassword();
    }

    // Validate password confirmation
    if (confirmPassword.isEmpty) {
      return const ValidationException(
        message: 'Please confirm your new password',
        code: 'CONFIRM_PASSWORD_REQUIRED',
      );
    }

    if (newPassword != confirmPassword) {
      return const ValidationException(
        message: 'Passwords do not match',
        code: 'PASSWORDS_DO_NOT_MATCH',
      );
    }

    return null;
  }
}