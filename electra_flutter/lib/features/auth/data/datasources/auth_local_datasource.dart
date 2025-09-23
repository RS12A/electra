import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';

import '../models/auth_models.dart';
import '../models/user_model.dart';
import '../../../core/error/app_exception.dart';

/// Local data source for secure authentication data storage
///
/// Handles secure storage of authentication data, biometric setup,
/// and offline authentication capabilities.
class AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  /// Storage keys
  static const String _authDataKey = 'auth_data';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricDataKey = 'biometric_data';
  static const String _rememberMeKey = 'remember_me';
  static const String _offlineCredentialsKey = 'offline_credentials';

  AuthLocalDataSource(this._secureStorage, this._localAuth);

  /// Store authentication data securely
  Future<void> storeAuthData(AuthResponseModel authResponse) async {
    try {
      final authDataJson = json.encode(authResponse.toJson());
      await _secureStorage.write(key: _authDataKey, value: authDataJson);
    } catch (e) {
      throw StorageException(
        message: 'Failed to store authentication data: ${e.toString()}',
        code: 'STORAGE_WRITE_ERROR',
      );
    }
  }

  /// Get stored authentication data
  Future<AuthResponseModel?> getStoredAuthData() async {
    try {
      final authDataJson = await _secureStorage.read(key: _authDataKey);
      if (authDataJson == null) return null;

      final authDataMap = json.decode(authDataJson) as Map<String, dynamic>;
      return AuthResponseModel.fromJson(authDataMap);
    } catch (e) {
      throw StorageException(
        message: 'Failed to read authentication data: ${e.toString()}',
        code: 'STORAGE_READ_ERROR',
      );
    }
  }

  /// Clear stored authentication data
  Future<void> clearStoredAuthData() async {
    try {
      await _secureStorage.delete(key: _authDataKey);
      await _secureStorage.delete(key: _offlineCredentialsKey);
      await _clearBiometricData();
    } catch (e) {
      throw StorageException(
        message: 'Failed to clear authentication data: ${e.toString()}',
        code: 'STORAGE_DELETE_ERROR',
      );
    }
  }

  /// Check if user has stored credentials
  Future<bool> hasStoredCredentials() async {
    try {
      final authData = await getStoredAuthData();
      return authData != null && !authData.isExpired;
    } catch (e) {
      return false;
    }
  }

  /// Store offline credentials for offline login
  Future<void> storeOfflineCredentials({
    required String identifier,
    required String hashedPassword,
    required UserModel user,
  }) async {
    try {
      final offlineData = {
        'identifier': identifier,
        'hashed_password': hashedPassword,
        'user': user.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final offlineDataJson = json.encode(offlineData);
      await _secureStorage.write(key: _offlineCredentialsKey, value: offlineDataJson);
    } catch (e) {
      throw StorageException(
        message: 'Failed to store offline credentials: ${e.toString()}',
        code: 'OFFLINE_STORAGE_ERROR',
      );
    }
  }

  /// Verify offline credentials
  Future<UserModel?> verifyOfflineCredentials({
    required String identifier,
    required String password,
  }) async {
    try {
      final offlineDataJson = await _secureStorage.read(key: _offlineCredentialsKey);
      if (offlineDataJson == null) return null;

      final offlineData = json.decode(offlineDataJson) as Map<String, dynamic>;
      final storedIdentifier = offlineData['identifier'] as String;
      final storedHashedPassword = offlineData['hashed_password'] as String;

      // Check if identifier matches
      if (storedIdentifier != identifier) return null;

      // Hash provided password and compare
      final providedPasswordHash = _hashPassword(password);
      if (providedPasswordHash != storedHashedPassword) return null;

      // Return user data
      return UserModel.fromJson(offlineData['user'] as Map<String, dynamic>);
    } catch (e) {
      throw StorageException(
        message: 'Failed to verify offline credentials: ${e.toString()}',
        code: 'OFFLINE_VERIFICATION_ERROR',
      );
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) return false;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      throw BiometricException(
        message: 'Failed to check biometric availability: ${e.toString()}',
        code: 'BIOMETRIC_CHECK_ERROR',
      );
    }
  }

  /// Check if biometric authentication is enabled for user
  Future<bool> isBiometricEnabled() async {
    try {
      final enabledString = await _secureStorage.read(key: _biometricEnabledKey);
      return enabledString == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric authentication
  Future<void> enableBiometric(AuthResponseModel authData) async {
    try {
      // First, verify device supports biometric
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw const BiometricException.notAvailable();
      }

      // Authenticate with biometric to confirm setup
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authenticated) {
        throw const BiometricException.authenticationFailed();
      }

      // Store biometric-protected auth data
      final biometricDataJson = json.encode(authData.toJson());
      await _secureStorage.write(key: _biometricDataKey, value: biometricDataJson);
      await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
    } catch (e) {
      if (e is BiometricException) rethrow;
      throw BiometricException(
        message: 'Failed to enable biometric authentication: ${e.toString()}',
        code: 'BIOMETRIC_ENABLE_ERROR',
      );
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      await _clearBiometricData();
    } catch (e) {
      throw BiometricException(
        message: 'Failed to disable biometric authentication: ${e.toString()}',
        code: 'BIOMETRIC_DISABLE_ERROR',
      );
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        throw const BiometricException.notEnabled();
      }

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to log in to Electra',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      if (e is BiometricException) rethrow;
      throw BiometricException(
        message: 'Biometric authentication failed: ${e.toString()}',
        code: 'BIOMETRIC_AUTH_ERROR',
      );
    }
  }

  /// Get stored biometric authentication data
  Future<AuthResponseModel?> getBiometricAuthData() async {
    try {
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) return null;

      final biometricDataJson = await _secureStorage.read(key: _biometricDataKey);
      if (biometricDataJson == null) return null;

      final biometricDataMap = json.decode(biometricDataJson) as Map<String, dynamic>;
      return AuthResponseModel.fromJson(biometricDataMap);
    } catch (e) {
      throw StorageException(
        message: 'Failed to read biometric data: ${e.toString()}',
        code: 'BIOMETRIC_READ_ERROR',
      );
    }
  }

  /// Store remember me preference
  Future<void> setRememberMe(bool remember) async {
    try {
      await _secureStorage.write(key: _rememberMeKey, value: remember.toString());
    } catch (e) {
      // Non-critical error, can be ignored
    }
  }

  /// Get remember me preference
  Future<bool> getRememberMe() async {
    try {
      final rememberString = await _secureStorage.read(key: _rememberMeKey);
      return rememberString == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics
          .map((biometric) => _mapBiometricType(biometric))
          .where((type) => type != null)
          .cast<BiometricType>()
          .toList();
    } catch (e) {
      throw BiometricException(
        message: 'Failed to get available biometrics: ${e.toString()}',
        code: 'BIOMETRIC_TYPES_ERROR',
      );
    }
  }

  /// Check if device has biometric hardware
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Get device biometric support info
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Clear all biometric data
  Future<void> _clearBiometricData() async {
    await _secureStorage.delete(key: _biometricEnabledKey);
    await _secureStorage.delete(key: _biometricDataKey);
  }

  /// Hash password for secure storage
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Map local_auth BiometricType to domain BiometricType
  BiometricType? _mapBiometricType(BiometricType biometric) {
    switch (biometric) {
      case BiometricType.fingerprint:
        return BiometricType.fingerprint;
      case BiometricType.face:
        return BiometricType.faceId;
      case BiometricType.iris:
        return BiometricType.iris;
      case BiometricType.strong:
      case BiometricType.weak:
        return BiometricType.fingerprint; // Default mapping
      default:
        return null;
    }
  }

  /// Cleanup expired data
  Future<void> cleanupExpiredData() async {
    try {
      final authData = await getStoredAuthData();
      if (authData != null && authData.isExpired) {
        await clearStoredAuthData();
      }
    } catch (e) {
      // Non-critical error, can be ignored
    }
  }

  /// Get storage statistics (for debugging)
  Future<Map<String, bool>> getStorageStatus() async {
    final status = <String, bool>{};
    
    try {
      status['auth_data'] = await _secureStorage.containsKey(key: _authDataKey);
      status['biometric_enabled'] = await _secureStorage.containsKey(key: _biometricEnabledKey);
      status['biometric_data'] = await _secureStorage.containsKey(key: _biometricDataKey);
      status['offline_credentials'] = await _secureStorage.containsKey(key: _offlineCredentialsKey);
      status['remember_me'] = await _secureStorage.containsKey(key: _rememberMeKey);
    } catch (e) {
      // Return empty status on error
    }

    return status;
  }
}