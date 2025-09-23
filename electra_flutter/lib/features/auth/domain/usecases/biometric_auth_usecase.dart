import 'package:dartz/dartz.dart';

import '../../../core/error/app_exception.dart';
import '../entities/auth_entities.dart';
import '../repositories/auth_repository.dart';

/// Biometric authentication use case
///
/// Handles all biometric authentication operations including setup,
/// authentication, and management of biometric credentials.
class BiometricAuthUseCase {
  final AuthRepository _repository;

  const BiometricAuthUseCase(this._repository);

  /// Check if biometric authentication is available on device
  ///
  /// Returns true if device supports and has enrolled biometric data.
  Future<Either<AppException, bool>> isAvailable() async {
    try {
      return await _repository.isBiometricAvailable();
    } catch (e) {
      return Left(BiometricException(
        message: 'Failed to check biometric availability: ${e.toString()}',
        code: 'BIOMETRIC_CHECK_ERROR',
      ));
    }
  }

  /// Check if biometric authentication is enabled for current user
  ///
  /// Returns true if user has enabled biometric login.
  Future<Either<AppException, bool>> isEnabled() async {
    try {
      return await _repository.isBiometricEnabled();
    } catch (e) {
      return Left(BiometricException(
        message: 'Failed to check biometric status: ${e.toString()}',
        code: 'BIOMETRIC_STATUS_ERROR',
      ));
    }
  }

  /// Enable biometric authentication for current user
  ///
  /// Sets up biometric authentication and stores necessary credentials.
  Future<Either<AppException, void>> enable() async {
    try {
      // First check if biometric is available
      final availabilityResult = await _repository.isBiometricAvailable();
      return await availabilityResult.fold(
        (error) => Left(error),
        (isAvailable) async {
          if (!isAvailable) {
            return const Left(BiometricException.notAvailable());
          }

          // Perform biometric authentication to verify user
          final authResult = await _repository.authenticateWithBiometrics();
          return await authResult.fold(
            (error) => Left(error),
            (result) async {
              if (!result.isAuthenticated) {
                return Left(BiometricException(
                  message: result.errorMessage ?? 'Biometric authentication failed',
                  code: 'BIOMETRIC_AUTH_FAILED',
                ));
              }

              // Enable biometric authentication
              return await _repository.enableBiometric();
            },
          );
        },
      );
    } catch (e) {
      return Left(BiometricException(
        message: 'Failed to enable biometric authentication: ${e.toString()}',
        code: 'BIOMETRIC_ENABLE_ERROR',
      ));
    }
  }

  /// Disable biometric authentication for current user
  ///
  /// Removes biometric authentication and clears stored credentials.
  Future<Either<AppException, void>> disable() async {
    try {
      return await _repository.disableBiometric();
    } catch (e) {
      return Left(BiometricException(
        message: 'Failed to disable biometric authentication: ${e.toString()}',
        code: 'BIOMETRIC_DISABLE_ERROR',
      ));
    }
  }

  /// Authenticate user with biometrics
  ///
  /// Performs biometric authentication and returns detailed result.
  Future<Either<AppException, BiometricAuthResult>> authenticate() async {
    try {
      // Check if biometric is available
      final availabilityResult = await _repository.isBiometricAvailable();
      return await availabilityResult.fold(
        (error) => Left(error),
        (isAvailable) async {
          if (!isAvailable) {
            return const Left(BiometricException.notAvailable());
          }

          // Check if biometric is enabled for user
          final enabledResult = await _repository.isBiometricEnabled();
          return await enabledResult.fold(
            (error) => Left(error),
            (isEnabled) async {
              if (!isEnabled) {
                return const Left(BiometricException.notEnabled());
              }

              // Perform biometric authentication
              return await _repository.authenticateWithBiometrics();
            },
          );
        },
      );
    } catch (e) {
      return Left(BiometricException(
        message: 'Biometric authentication failed: ${e.toString()}',
        code: 'BIOMETRIC_AUTH_ERROR',
      ));
    }
  }

  /// Login user with biometric authentication
  ///
  /// Performs complete biometric login flow and returns authentication response.
  Future<Either<AppException, AuthResponse>> loginWithBiometric() async {
    try {
      // First authenticate with biometrics
      final authResult = await authenticate();
      return await authResult.fold(
        (error) => Left(error),
        (result) async {
          if (!result.isAuthenticated) {
            return Left(BiometricException(
              message: result.errorMessage ?? 'Biometric authentication failed',
              code: 'BIOMETRIC_LOGIN_FAILED',
            ));
          }

          // Perform biometric login
          return await _repository.loginWithBiometrics();
        },
      );
    } catch (e) {
      return Left(BiometricException(
        message: 'Biometric login failed: ${e.toString()}',
        code: 'BIOMETRIC_LOGIN_ERROR',
      ));
    }
  }

  /// Get biometric capabilities of the device
  ///
  /// Returns information about what types of biometric authentication
  /// are available on the current device.
  Future<Either<AppException, BiometricCapabilities>> getCapabilities() async {
    try {
      final availabilityResult = await _repository.isBiometricAvailable();
      return await availabilityResult.fold(
        (error) => Left(error),
        (isAvailable) async {
          if (!isAvailable) {
            return const Right(BiometricCapabilities.none());
          }

          // In a real implementation, this would check specific biometric types
          // For now, we'll return a general capability
          return const Right(BiometricCapabilities(
            hasFingerprint: true,
            hasFaceId: false,
            hasTouchId: false,
            hasIris: false,
            hasVoice: false,
          ));
        },
      );
    } catch (e) {
      return Left(BiometricException(
        message: 'Failed to get biometric capabilities: ${e.toString()}',
        code: 'BIOMETRIC_CAPABILITIES_ERROR',
      ));
    }
  }

  /// Get user-friendly biometric type name
  String getBiometricTypeName(BiometricType? type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.faceId:
        return 'Face ID';
      case BiometricType.touchId:
        return 'Touch ID';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.voice:
        return 'Voice Recognition';
      case null:
        return 'Biometric';
    }
  }

  /// Get biometric setup instructions for user
  List<String> getBiometricSetupInstructions() {
    return [
      '1. Ensure your device has biometric authentication set up',
      '2. Tap "Enable Biometric Login" button',
      '3. Authenticate using your device\'s biometric scanner',
      '4. Your biometric login will be enabled for future use',
      '5. You can disable this feature anytime in settings',
    ];
  }

  /// Get biometric security benefits for user education
  List<String> getBiometricSecurityBenefits() {
    return [
      'Quick and convenient login without typing passwords',
      'Enhanced security using your unique biometric data',
      'No need to remember complex passwords',
      'Biometric data is stored securely on your device only',
      'Cannot be easily replicated or stolen like passwords',
      'Automatic logout protection if biometric fails',
    ];
  }

  /// Validate biometric authentication requirements
  ///
  /// Checks if all requirements are met for biometric authentication.
  Future<Either<AppException, BiometricValidationResult>> validateRequirements() async {
    try {
      final issues = <String>[];
      final warnings = <String>[];

      // Check device support
      final availabilityResult = await _repository.isBiometricAvailable();
      await availabilityResult.fold(
        (error) {
          issues.add('Biometric authentication is not available on this device');
        },
        (isAvailable) async {
          if (!isAvailable) {
            issues.add('No biometric data is enrolled on this device');
          }
        },
      );

      // Check if user is logged in (required for enabling biometric)
      final userResult = await _repository.getCurrentUser();
      await userResult.fold(
        (error) {
          issues.add('You must be logged in to enable biometric authentication');
        },
        (user) {
          if (user == null) {
            issues.add('You must be logged in to enable biometric authentication');
          }
        },
      );

      // Check for security warnings
      final networkResult = await _repository.hasNetworkConnection();
      await networkResult.fold(
        (error) {
          warnings.add('Network connection required for initial biometric setup');
        },
        (hasNetwork) {
          if (!hasNetwork) {
            warnings.add('Network connection recommended for biometric setup');
          }
        },
      );

      final result = BiometricValidationResult(
        isValid: issues.isEmpty,
        issues: issues,
        warnings: warnings,
      );

      return Right(result);
    } catch (e) {
      return Left(BiometricException(
        message: 'Failed to validate biometric requirements: ${e.toString()}',
        code: 'BIOMETRIC_VALIDATION_ERROR',
      ));
    }
  }
}

/// Biometric capabilities information
class BiometricCapabilities {
  final bool hasFingerprint;
  final bool hasFaceId;
  final bool hasTouchId;
  final bool hasIris;
  final bool hasVoice;

  const BiometricCapabilities({
    required this.hasFingerprint,
    required this.hasFaceId,
    required this.hasTouchId,
    required this.hasIris,
    required this.hasVoice,
  });

  const BiometricCapabilities.none()
      : hasFingerprint = false,
        hasFaceId = false,
        hasTouchId = false,
        hasIris = false,
        hasVoice = false;

  bool get hasAny => hasFingerprint || hasFaceId || hasTouchId || hasIris || hasVoice;

  List<BiometricType> get availableTypes {
    final types = <BiometricType>[];
    if (hasFingerprint) types.add(BiometricType.fingerprint);
    if (hasFaceId) types.add(BiometricType.faceId);
    if (hasTouchId) types.add(BiometricType.touchId);
    if (hasIris) types.add(BiometricType.iris);
    if (hasVoice) types.add(BiometricType.voice);
    return types;
  }
}

/// Biometric validation result
class BiometricValidationResult {
  final bool isValid;
  final List<String> issues;
  final List<String> warnings;

  const BiometricValidationResult({
    required this.isValid,
    required this.issues,
    required this.warnings,
  });

  bool get hasIssues => issues.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}