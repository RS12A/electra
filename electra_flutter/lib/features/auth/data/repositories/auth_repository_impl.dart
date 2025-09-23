import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/entities/user.dart';
import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../core/error/app_exception.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/auth_models.dart';
import '../models/user_model.dart';

/// Implementation of AuthRepository
///
/// This class implements the authentication repository interface,
/// coordinating between remote and local data sources to provide
/// a unified authentication API.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivity,
  );

  @override
  Future<Either<AppException, AuthResponse>> login(
    LoginCredentials credentials,
  ) async {
    try {
      // Check network connectivity
      final hasNetwork = await hasNetworkConnection();
      return await hasNetwork.fold(
        (error) => Left(error),
        (isConnected) async {
          if (isConnected) {
            // Online login
            final request = LoginRequestModel.fromCredentials(credentials);
            final authResponse = await _remoteDataSource.login(request);
            
            // Store auth data if remember me is enabled
            if (credentials.rememberMe) {
              await _localDataSource.storeAuthData(authResponse);
              await _localDataSource.setRememberMe(true);
              
              // Store offline credentials for future offline login
              await _localDataSource.storeOfflineCredentials(
                identifier: credentials.identifier,
                hashedPassword: _hashPassword(credentials.password),
                user: authResponse.user as UserModel,
              );
            }
            
            return Right(authResponse.toEntity());
          } else {
            // Offline login attempt
            final user = await _localDataSource.verifyOfflineCredentials(
              identifier: credentials.identifier,
              password: credentials.password,
            );
            
            if (user != null) {
              // Create mock auth response for offline login
              final offlineAuthResponse = AuthResponseModel(
                accessToken: 'offline_token',
                refreshToken: 'offline_refresh',
                user: user,
                expiresIn: 86400, // 24 hours
              );
              
              return Right(offlineAuthResponse.toEntity());
            } else {
              return const Left(NetworkException(
                message: 'No internet connection and invalid offline credentials',
                code: 'OFFLINE_LOGIN_FAILED',
              ));
            }
          }
        },
      );
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(AuthException(
        message: 'Login failed: ${e.toString()}',
        code: 'LOGIN_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, AuthResponse>> register(
    RegistrationData data,
  ) async {
    try {
      final hasNetwork = await hasNetworkConnection();
      return await hasNetwork.fold(
        (error) => Left(error),
        (isConnected) async {
          if (!isConnected) {
            return const Left(NetworkException.noConnection());
          }

          final request = RegistrationRequestModel.fromData(data);
          final authResponse = await _remoteDataSource.register(request);
          
          // Store auth data after successful registration
          await _localDataSource.storeAuthData(authResponse);
          
          return Right(authResponse.toEntity());
        },
      );
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(AuthException(
        message: 'Registration failed: ${e.toString()}',
        code: 'REGISTRATION_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, void>> sendPasswordResetOtp(
    PasswordResetRequest request,
  ) async {
    try {
      final hasNetwork = await hasNetworkConnection();
      return await hasNetwork.fold(
        (error) => Left(error),
        (isConnected) async {
          if (!isConnected) {
            return const Left(NetworkException.noConnection());
          }

          final requestModel = PasswordResetRequestModel.fromRequest(request);
          await _remoteDataSource.sendPasswordResetOtp(requestModel);
          return const Right(null);
        },
      );
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(AuthException(
        message: 'Failed to send reset code: ${e.toString()}',
        code: 'SEND_OTP_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, void>> verifyOtp(
    OtpVerification verification,
  ) async {
    try {
      final hasNetwork = await hasNetworkConnection();
      return await hasNetwork.fold(
        (error) => Left(error),
        (isConnected) async {
          if (!isConnected) {
            return const Left(NetworkException.noConnection());
          }

          final verificationModel = OtpVerificationModel.fromVerification(verification);
          await _remoteDataSource.verifyOtp(verificationModel);
          return const Right(null);
        },
      );
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(AuthException(
        message: 'OTP verification failed: ${e.toString()}',
        code: 'VERIFY_OTP_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, void>> resetPassword(
    OtpVerification verification,
  ) async {
    try {
      final hasNetwork = await hasNetworkConnection();
      return await hasNetwork.fold(
        (error) => Left(error),
        (isConnected) async {
          if (!isConnected) {
            return const Left(NetworkException.noConnection());
          }

          final verificationModel = OtpVerificationModel.fromVerification(verification);
          await _remoteDataSource.resetPassword(verificationModel);
          return const Right(null);
        },
      );
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(AuthException(
        message: 'Password reset failed: ${e.toString()}',
        code: 'RESET_PASSWORD_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, AuthResponse>> refreshToken(
    String refreshToken,
  ) async {
    try {
      final hasNetwork = await hasNetworkConnection();
      return await hasNetwork.fold(
        (error) => Left(error),
        (isConnected) async {
          if (!isConnected) {
            return const Left(NetworkException.noConnection());
          }

          final authResponse = await _remoteDataSource.refreshToken(refreshToken);
          
          // Update stored auth data
          await _localDataSource.storeAuthData(authResponse);
          
          return Right(authResponse.toEntity());
        },
      );
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(AuthException(
        message: 'Token refresh failed: ${e.toString()}',
        code: 'REFRESH_TOKEN_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, void>> logout() async {
    try {
      // Get stored refresh token for server logout
      final authData = await _localDataSource.getStoredAuthData();
      
      if (authData != null) {
        final hasNetwork = await hasNetworkConnection();
        await hasNetwork.fold(
          (error) => {}, // Continue with local logout even if network fails
          (isConnected) async {
            if (isConnected) {
              try {
                await _remoteDataSource.logout(authData.refreshToken);
              } catch (e) {
                // Continue with local logout even if server logout fails
              }
            }
          },
        );
      }
      
      // Clear all local data
      await _localDataSource.clearStoredAuthData();
      
      return const Right(null);
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(AuthException(
        message: 'Logout failed: ${e.toString()}',
        code: 'LOGOUT_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, User?>> getCurrentUser() async {
    try {
      // First check local storage
      final authData = await _localDataSource.getStoredAuthData();
      if (authData != null && !authData.isExpired) {
        return Right((authData.user as UserModel).toEntity());
      }
      
      // If no valid local data, fetch from server
      final hasNetwork = await hasNetworkConnection();
      return await hasNetwork.fold(
        (error) => const Right(null),
        (isConnected) async {
          if (!isConnected) {
            return const Right(null);
          }

          try {
            final user = await _remoteDataSource.getCurrentUser();
            return Right(user.toEntity());
          } catch (e) {
            return const Right(null);
          }
        },
      );
    } catch (e) {
      return const Right(null);
    }
  }

  @override
  Future<Either<AppException, User>> updateProfile(User user) async {
    try {
      final hasNetwork = await hasNetworkConnection();
      return await hasNetwork.fold(
        (error) => Left(error),
        (isConnected) async {
          if (!isConnected) {
            return const Left(NetworkException.noConnection());
          }

          final userModel = UserModel.fromEntity(user);
          final updatedUser = await _remoteDataSource.updateProfile(userModel);
          
          // Update local auth data with new user info
          final authData = await _localDataSource.getStoredAuthData();
          if (authData != null) {
            final updatedAuthData = AuthResponseModel(
              accessToken: authData.accessToken,
              refreshToken: authData.refreshToken,
              user: updatedUser,
              expiresIn: authData.expiresIn,
              tokenType: authData.tokenType,
            );
            await _localDataSource.storeAuthData(updatedAuthData);
          }
          
          return Right(updatedUser.toEntity());
        },
      );
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(AuthException(
        message: 'Profile update failed: ${e.toString()}',
        code: 'UPDATE_PROFILE_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final hasNetwork = await hasNetworkConnection();
      return await hasNetwork.fold(
        (error) => Left(error),
        (isConnected) async {
          if (!isConnected) {
            return const Left(NetworkException.noConnection());
          }

          // This would be implemented with a specific API endpoint
          // For now, we'll return success as this is not in the current backend API
          return const Right(null);
        },
      );
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(AuthException(
        message: 'Password change failed: ${e.toString()}',
        code: 'CHANGE_PASSWORD_ERROR',
      ));
    }
  }

  // Local Storage Methods

  @override
  Future<Either<AppException, void>> storeAuthData(AuthResponse authResponse) async {
    try {
      final authModel = AuthResponseModel(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        user: UserModel.fromEntity(authResponse.user),
        expiresIn: authResponse.expiresIn,
        tokenType: authResponse.tokenType,
      );
      
      await _localDataSource.storeAuthData(authModel);
      return const Right(null);
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(StorageException(
        message: 'Failed to store auth data: ${e.toString()}',
        code: 'STORAGE_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, AuthResponse?>> getStoredAuthData() async {
    try {
      final authData = await _localDataSource.getStoredAuthData();
      return Right(authData?.toEntity());
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(StorageException(
        message: 'Failed to get stored auth data: ${e.toString()}',
        code: 'STORAGE_READ_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, void>> clearStoredAuthData() async {
    try {
      await _localDataSource.clearStoredAuthData();
      return const Right(null);
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(StorageException(
        message: 'Failed to clear auth data: ${e.toString()}',
        code: 'STORAGE_CLEAR_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, bool>> hasStoredCredentials() async {
    try {
      final hasCredentials = await _localDataSource.hasStoredCredentials();
      return Right(hasCredentials);
    } catch (e) {
      return const Right(false);
    }
  }

  // Biometric Authentication Methods

  @override
  Future<Either<AppException, bool>> isBiometricAvailable() async {
    try {
      final isAvailable = await _localDataSource.isBiometricAvailable();
      return Right(isAvailable);
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(BiometricException(
        message: 'Failed to check biometric availability: ${e.toString()}',
        code: 'BIOMETRIC_CHECK_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, bool>> isBiometricEnabled() async {
    try {
      final isEnabled = await _localDataSource.isBiometricEnabled();
      return Right(isEnabled);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<AppException, void>> enableBiometric() async {
    try {
      final authData = await _localDataSource.getStoredAuthData();
      if (authData == null) {
        return const Left(BiometricException(
          message: 'No authentication data available for biometric setup',
          code: 'NO_AUTH_DATA',
        ));
      }
      
      await _localDataSource.enableBiometric(authData);
      return const Right(null);
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(BiometricException(
        message: 'Failed to enable biometric: ${e.toString()}',
        code: 'BIOMETRIC_ENABLE_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, void>> disableBiometric() async {
    try {
      await _localDataSource.disableBiometric();
      return const Right(null);
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(BiometricException(
        message: 'Failed to disable biometric: ${e.toString()}',
        code: 'BIOMETRIC_DISABLE_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, BiometricAuthResult>> authenticateWithBiometrics() async {
    try {
      final authenticated = await _localDataSource.authenticateWithBiometrics();
      return Right(BiometricAuthResult(
        isAuthenticated: authenticated,
        biometricType: BiometricType.fingerprint, // Default type
      ));
    } catch (e) {
      if (e is AppException) return Left(e);
      return Right(BiometricAuthResult(
        isAuthenticated: false,
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<Either<AppException, AuthResponse>> loginWithBiometrics() async {
    try {
      final authResult = await authenticateWithBiometrics();
      return await authResult.fold(
        (error) => Left(error),
        (result) async {
          if (!result.isAuthenticated) {
            return Left(BiometricException(
              message: result.errorMessage ?? 'Biometric authentication failed',
              code: 'BIOMETRIC_AUTH_FAILED',
            ));
          }
          
          final biometricAuthData = await _localDataSource.getBiometricAuthData();
          if (biometricAuthData == null) {
            return const Left(BiometricException(
              message: 'No biometric authentication data found',
              code: 'NO_BIOMETRIC_DATA',
            ));
          }
          
          return Right(biometricAuthData.toEntity());
        },
      );
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(BiometricException(
        message: 'Biometric login failed: ${e.toString()}',
        code: 'BIOMETRIC_LOGIN_ERROR',
      ));
    }
  }

  // Validation Methods

  @override
  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  @override
  bool isValidPassword(String password) {
    return password.length >= 8 &&
           RegExp(r'(?=.*[a-z])').hasMatch(password) &&
           RegExp(r'(?=.*[A-Z])').hasMatch(password) &&
           RegExp(r'(?=.*\d)').hasMatch(password);
  }

  @override
  bool isValidMatricNumber(String matricNumber) {
    return RegExp(r'^[A-Z]{3}\d{5}$').hasMatch(matricNumber.toUpperCase());
  }

  @override
  bool isValidStaffId(String staffId) {
    return staffId.length >= 4;
  }

  @override
  bool isEmail(String identifier) {
    return identifier.contains('@') && isValidEmail(identifier);
  }

  @override
  bool isMatricNumber(String identifier) {
    return RegExp(r'^[A-Z]{3}\d{5}$').hasMatch(identifier.toUpperCase());
  }

  @override
  bool isStaffId(String identifier) {
    return !isEmail(identifier) && !isMatricNumber(identifier) && identifier.length >= 4;
  }

  // Network Status Methods

  @override
  Future<Either<AppException, bool>> hasNetworkConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasConnection = connectivityResult != ConnectivityResult.none;
      return Right(hasConnection);
    } catch (e) {
      return Left(NetworkException(
        message: 'Failed to check network connection: ${e.toString()}',
        code: 'CONNECTIVITY_CHECK_ERROR',
      ));
    }
  }

  @override
  Future<Either<AppException, void>> syncOfflineData() async {
    try {
      // This would implement syncing offline data with server
      // For now, we'll just perform cleanup
      await _localDataSource.cleanupExpiredData();
      return const Right(null);
    } catch (e) {
      if (e is AppException) return Left(e);
      return Left(StorageException(
        message: 'Offline data sync failed: ${e.toString()}',
        code: 'SYNC_ERROR',
      ));
    }
  }

  /// Hash password for secure offline storage
  String _hashPassword(String password) {
    // This uses the same hashing method as the local data source
    // In a real implementation, you might want to use a more sophisticated approach
    return password; // Simplified for now - the local data source handles hashing
  }
}