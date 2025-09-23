import 'package:dartz/dartz.dart';

import '../../../core/error/app_exception.dart';
import '../entities/user.dart';
import '../entities/auth_entities.dart';

/// Authentication repository interface
///
/// This interface defines all authentication-related operations.
/// It follows the Repository Pattern and abstracts data layer implementation.
abstract class AuthRepository {
  /// Login user with credentials
  ///
  /// Takes [LoginCredentials] and returns [AuthResponse] on success
  /// or [AppException] on failure.
  Future<Either<AppException, AuthResponse>> login(LoginCredentials credentials);

  /// Register a new user
  ///
  /// Takes [RegistrationData] and returns [AuthResponse] on success
  /// or [AppException] on failure.
  Future<Either<AppException, AuthResponse>> register(RegistrationData data);

  /// Send password reset OTP to email
  ///
  /// Takes [PasswordResetRequest] and returns success status.
  Future<Either<AppException, void>> sendPasswordResetOtp(
    PasswordResetRequest request,
  );

  /// Verify OTP code
  ///
  /// Takes [OtpVerification] and returns verification status.
  Future<Either<AppException, void>> verifyOtp(OtpVerification verification);

  /// Reset password with OTP
  ///
  /// Takes [OtpVerification] with new password and resets user password.
  Future<Either<AppException, void>> resetPassword(OtpVerification verification);

  /// Refresh authentication token
  ///
  /// Takes refresh token and returns new [AuthResponse].
  Future<Either<AppException, AuthResponse>> refreshToken(String refreshToken);

  /// Logout user
  ///
  /// Revokes tokens and clears local authentication data.
  Future<Either<AppException, void>> logout();

  /// Get current user profile
  ///
  /// Returns current authenticated user or null if not logged in.
  Future<Either<AppException, User?>> getCurrentUser();

  /// Update user profile
  ///
  /// Updates user profile information.
  Future<Either<AppException, User>> updateProfile(User user);

  /// Change user password
  ///
  /// Changes user password with current password verification.
  Future<Either<AppException, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  // Local Storage Methods

  /// Store authentication data locally
  ///
  /// Securely stores [AuthResponse] for offline access and auto-login.
  Future<Either<AppException, void>> storeAuthData(AuthResponse authResponse);

  /// Get stored authentication data
  ///
  /// Retrieves stored [AuthResponse] from secure local storage.
  Future<Either<AppException, AuthResponse?>> getStoredAuthData();

  /// Clear stored authentication data
  ///
  /// Removes all stored authentication data from local storage.
  Future<Either<AppException, void>> clearStoredAuthData();

  /// Check if user has stored credentials for auto-login
  ///
  /// Returns true if valid stored credentials exist.
  Future<Either<AppException, bool>> hasStoredCredentials();

  // Biometric Authentication Methods

  /// Check if biometric authentication is available on device
  ///
  /// Returns true if device supports biometric authentication.
  Future<Either<AppException, bool>> isBiometricAvailable();

  /// Check if biometric authentication is enabled for user
  ///
  /// Returns true if user has enabled biometric authentication.
  Future<Either<AppException, bool>> isBiometricEnabled();

  /// Enable biometric authentication for user
  ///
  /// Enables biometric authentication and stores necessary data.
  Future<Either<AppException, void>> enableBiometric();

  /// Disable biometric authentication for user
  ///
  /// Disables biometric authentication and removes stored data.
  Future<Either<AppException, void>> disableBiometric();

  /// Authenticate user with biometrics
  ///
  /// Performs biometric authentication and returns result.
  Future<Either<AppException, BiometricAuthResult>> authenticateWithBiometrics();

  /// Login with biometric authentication
  ///
  /// Performs biometric authentication and returns auth response if successful.
  Future<Either<AppException, AuthResponse>> loginWithBiometrics();

  // Validation Methods

  /// Validate email format
  ///
  /// Returns true if email format is valid.
  bool isValidEmail(String email);

  /// Validate password strength
  ///
  /// Returns true if password meets security requirements.
  bool isValidPassword(String password);

  /// Validate matriculation number format
  ///
  /// Returns true if matriculation number format is valid.
  bool isValidMatricNumber(String matricNumber);

  /// Validate staff ID format
  ///
  /// Returns true if staff ID format is valid.
  bool isValidStaffId(String staffId);

  /// Check if identifier is email
  ///
  /// Returns true if identifier appears to be an email address.
  bool isEmail(String identifier);

  /// Check if identifier is matriculation number
  ///
  /// Returns true if identifier appears to be a matriculation number.
  bool isMatricNumber(String identifier);

  /// Check if identifier is staff ID
  ///
  /// Returns true if identifier appears to be a staff ID.
  bool isStaffId(String identifier);

  // Network Status Methods

  /// Check network connectivity
  ///
  /// Returns true if device has internet connectivity.
  Future<Either<AppException, bool>> hasNetworkConnection();

  /// Sync offline data with server
  ///
  /// Synchronizes any offline authentication data with the server.
  Future<Either<AppException, void>> syncOfflineData();
}