import 'package:dartz/dartz.dart';

import '../../../core/error/app_exception.dart';
import '../entities/user.dart';
import '../entities/auth_entities.dart';
import '../repositories/auth_repository.dart';

/// Login use case for user authentication
///
/// Handles user login with various identifier types (email, matric number, staff ID)
/// and supports biometric authentication and remember me functionality.
class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  /// Execute login with credentials
  ///
  /// Validates credentials and performs login operation.
  /// Supports offline login if network is unavailable.
  Future<Either<AppException, AuthResponse>> call(
    LoginCredentials credentials,
  ) async {
    try {
      // Validate credentials
      final validationError = _validateCredentials(credentials);
      if (validationError != null) {
        return Left(validationError);
      }

      // Check network connectivity
      final networkResult = await _repository.hasNetworkConnection();
      
      return await networkResult.fold(
        (error) => Left(error),
        (hasNetwork) async {
          if (hasNetwork) {
            // Online login
            final result = await _repository.login(credentials);
            
            return await result.fold(
              (error) => Left(error),
              (authResponse) async {
                // Store auth data if remember me is enabled
                if (credentials.rememberMe) {
                  await _repository.storeAuthData(authResponse);
                }
                return Right(authResponse);
              },
            );
          } else {
            // Offline login (check stored credentials)
            return await _attemptOfflineLogin(credentials);
          }
        },
      );
    } catch (e) {
      return Left(AuthException(message: 'Login failed: ${e.toString()}'));
    }
  }

  /// Attempt biometric login
  ///
  /// Performs biometric authentication and logs user in if successful.
  Future<Either<AppException, AuthResponse>> loginWithBiometrics() async {
    try {
      // Check if biometric is available
      final availabilityResult = await _repository.isBiometricAvailable();
      return await availabilityResult.fold(
        (error) => Left(error),
        (isAvailable) async {
          if (!isAvailable) {
            return const Left(BiometricException.notAvailable());
          }

          // Check if biometric is enabled
          final enabledResult = await _repository.isBiometricEnabled();
          return await enabledResult.fold(
            (error) => Left(error),
            (isEnabled) async {
              if (!isEnabled) {
                return const Left(BiometricException.notEnabled());
              }

              // Perform biometric authentication
              return await _repository.loginWithBiometrics();
            },
          );
        },
      );
    } catch (e) {
      return Left(BiometricException(
        message: 'Biometric login failed: ${e.toString()}',
      ));
    }
  }

  /// Check if auto login is possible
  ///
  /// Returns true if user has stored valid credentials for auto-login.
  Future<Either<AppException, bool>> canAutoLogin() async {
    try {
      final storedDataResult = await _repository.getStoredAuthData();
      return storedDataResult.fold(
        (error) => Left(error),
        (authData) {
          if (authData == null) {
            return const Right(false);
          }

          // Check if token is still valid
          if (authData.isExpired) {
            return const Right(false);
          }

          return const Right(true);
        },
      );
    } catch (e) {
      return Left(AuthException(message: 'Auto-login check failed: ${e.toString()}'));
    }
  }

  /// Perform auto login with stored credentials
  ///
  /// Attempts to log user in using stored authentication data.
  Future<Either<AppException, AuthResponse>> autoLogin() async {
    try {
      final storedDataResult = await _repository.getStoredAuthData();
      return await storedDataResult.fold(
        (error) => Left(error),
        (authData) async {
          if (authData == null) {
            return const Left(AuthException(
              message: 'No stored credentials found',
              code: 'NO_STORED_CREDENTIALS',
            ));
          }

          // Check if token is expired
          if (authData.isExpired) {
            // Try to refresh token
            return await _repository.refreshToken(authData.refreshToken);
          }

          return Right(authData);
        },
      );
    } catch (e) {
      return Left(AuthException(message: 'Auto-login failed: ${e.toString()}'));
    }
  }

  /// Validate login credentials
  ValidationException? _validateCredentials(LoginCredentials credentials) {
    if (credentials.identifier.isEmpty) {
      return const ValidationException(
        message: 'Please enter your email, matric number, or staff ID',
        code: 'IDENTIFIER_REQUIRED',
      );
    }

    if (credentials.password.isEmpty) {
      return const ValidationException(
        message: 'Please enter your password',
        code: 'PASSWORD_REQUIRED',
      );
    }

    // Validate identifier format based on type
    if (_repository.isEmail(credentials.identifier)) {
      if (!_repository.isValidEmail(credentials.identifier)) {
        return const ValidationException.invalidEmail();
      }
    } else if (_repository.isMatricNumber(credentials.identifier)) {
      if (!_repository.isValidMatricNumber(credentials.identifier)) {
        return const ValidationException.invalidMatricNumber();
      }
    } else if (_repository.isStaffId(credentials.identifier)) {
      if (!_repository.isValidStaffId(credentials.identifier)) {
        return const ValidationException.invalidStaffId();
      }
    } else {
      return const ValidationException(
        message: 'Please enter a valid email, matric number, or staff ID',
        code: 'INVALID_IDENTIFIER',
      );
    }

    return null;
  }

  /// Attempt offline login with stored credentials
  Future<Either<AppException, AuthResponse>> _attemptOfflineLogin(
    LoginCredentials credentials,
  ) async {
    final storedDataResult = await _repository.getStoredAuthData();
    return storedDataResult.fold(
      (error) => Left(NetworkException.noConnection()),
      (storedData) {
        if (storedData == null) {
          return const Left(NetworkException(
            message: 'No internet connection and no stored credentials available',
            code: 'OFFLINE_NO_CREDENTIALS',
          ));
        }

        // Verify that stored credentials match current login attempt
        final storedUser = storedData.user;
        if (storedUser.email == credentials.identifier ||
            storedUser.matricNumber == credentials.identifier ||
            storedUser.staffId == credentials.identifier) {
          // Return stored auth data for offline access
          return Right(storedData);
        } else {
          return const Left(NetworkException(
            message: 'No internet connection and credentials do not match stored data',
            code: 'OFFLINE_CREDENTIALS_MISMATCH',
          ));
        }
      },
    );
  }
}