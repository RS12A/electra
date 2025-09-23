import 'package:equatable/equatable.dart';

/// Base class for all application exceptions
///
/// This abstract class provides a common interface for all exceptions
/// in the Electra application, ensuring consistent error handling.
abstract class AppException extends Equatable implements Exception {
  /// Human-readable error message
  final String message;

  /// Error code for programmatic handling
  final String? code;

  /// Additional error details
  final Map<String, dynamic>? details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required String message,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  /// No internet connection
  const NetworkException.noConnection()
      : super(
          message: 'No internet connection available',
          code: 'NO_CONNECTION',
        );

  /// Request timeout
  const NetworkException.timeout()
      : super(
          message: 'Request timed out',
          code: 'TIMEOUT',
        );

  /// Server unavailable
  const NetworkException.serverUnavailable()
      : super(
          message: 'Server is currently unavailable',
          code: 'SERVER_UNAVAILABLE',
        );
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException({
    required String message,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  /// Invalid credentials
  const AuthException.invalidCredentials()
      : super(
          message: 'Invalid email/password combination',
          code: 'INVALID_CREDENTIALS',
        );

  /// User not found
  const AuthException.userNotFound()
      : super(
          message: 'User account not found',
          code: 'USER_NOT_FOUND',
        );

  /// Email already exists
  const AuthException.emailAlreadyExists()
      : super(
          message: 'An account with this email already exists',
          code: 'EMAIL_ALREADY_EXISTS',
        );

  /// Matriculation number already exists
  const AuthException.matricNumberAlreadyExists()
      : super(
          message: 'This matriculation number is already registered',
          code: 'MATRIC_NUMBER_ALREADY_EXISTS',
        );

  /// Staff ID already exists
  const AuthException.staffIdAlreadyExists()
      : super(
          message: 'This staff ID is already registered',
          code: 'STAFF_ID_ALREADY_EXISTS',
        );

  /// Account not verified
  const AuthException.accountNotVerified()
      : super(
          message: 'Please verify your email address before logging in',
          code: 'ACCOUNT_NOT_VERIFIED',
        );

  /// Account suspended
  const AuthException.accountSuspended()
      : super(
          message: 'Your account has been suspended. Contact administrator.',
          code: 'ACCOUNT_SUSPENDED',
        );

  /// Invalid token
  const AuthException.invalidToken()
      : super(
          message: 'Authentication token is invalid or expired',
          code: 'INVALID_TOKEN',
        );

  /// Token expired
  const AuthException.tokenExpired()
      : super(
          message: 'Authentication token has expired',
          code: 'TOKEN_EXPIRED',
        );

  /// Invalid OTP
  const AuthException.invalidOtp()
      : super(
          message: 'Invalid or expired verification code',
          code: 'INVALID_OTP',
        );

  /// OTP expired
  const AuthException.otpExpired()
      : super(
          message: 'Verification code has expired',
          code: 'OTP_EXPIRED',
        );

  /// Too many attempts
  const AuthException.tooManyAttempts()
      : super(
          message: 'Too many login attempts. Please try again later.',
          code: 'TOO_MANY_ATTEMPTS',
        );

  /// Session expired
  const AuthException.sessionExpired()
      : super(
          message: 'Your session has expired. Please log in again.',
          code: 'SESSION_EXPIRED',
        );
}

/// Biometric authentication exceptions
class BiometricException extends AppException {
  const BiometricException({
    required String message,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  /// Biometric not available
  const BiometricException.notAvailable()
      : super(
          message: 'Biometric authentication is not available on this device',
          code: 'BIOMETRIC_NOT_AVAILABLE',
        );

  /// Biometric not enrolled
  const BiometricException.notEnrolled()
      : super(
          message: 'No biometric data is enrolled on this device',
          code: 'BIOMETRIC_NOT_ENROLLED',
        );

  /// Biometric not enabled
  const BiometricException.notEnabled()
      : super(
          message: 'Biometric authentication is not enabled for this account',
          code: 'BIOMETRIC_NOT_ENABLED',
        );

  /// Authentication failed
  const BiometricException.authenticationFailed()
      : super(
          message: 'Biometric authentication failed',
          code: 'BIOMETRIC_AUTH_FAILED',
        );

  /// User cancelled
  const BiometricException.userCancelled()
      : super(
          message: 'Biometric authentication was cancelled by user',
          code: 'BIOMETRIC_USER_CANCELLED',
        );

  /// Too many attempts
  const BiometricException.tooManyAttempts()
      : super(
          message: 'Too many failed biometric attempts. Please try again later.',
          code: 'BIOMETRIC_TOO_MANY_ATTEMPTS',
        );
}

/// Validation-related exceptions
class ValidationException extends AppException {
  const ValidationException({
    required String message,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  /// Invalid email format
  const ValidationException.invalidEmail()
      : super(
          message: 'Please enter a valid email address',
          code: 'INVALID_EMAIL',
        );

  /// Invalid password
  const ValidationException.invalidPassword()
      : super(
          message: 'Password must be at least 8 characters with uppercase, lowercase, and number',
          code: 'INVALID_PASSWORD',
        );

  /// Invalid matriculation number
  const ValidationException.invalidMatricNumber()
      : super(
          message: 'Invalid matriculation number format (e.g., MAT12345)',
          code: 'INVALID_MATRIC_NUMBER',
        );

  /// Invalid staff ID
  const ValidationException.invalidStaffId()
      : super(
          message: 'Staff ID must be at least 4 characters',
          code: 'INVALID_STAFF_ID',
        );

  /// Required field missing
  const ValidationException.requiredField(String field)
      : super(
          message: '$field is required',
          code: 'REQUIRED_FIELD',
        );
}

/// Storage-related exceptions
class StorageException extends AppException {
  const StorageException({
    required String message,
    String? code,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  /// Storage not available
  const StorageException.notAvailable()
      : super(
          message: 'Local storage is not available',
          code: 'STORAGE_NOT_AVAILABLE',
        );

  /// Storage access denied
  const StorageException.accessDenied()
      : super(
          message: 'Access to secure storage denied',
          code: 'STORAGE_ACCESS_DENIED',
        );

  /// Storage corrupted
  const StorageException.corrupted()
      : super(
          message: 'Stored data is corrupted',
          code: 'STORAGE_CORRUPTED',
        );
}

/// Server-related exceptions
class ServerException extends AppException {
  /// HTTP status code
  final int? statusCode;

  const ServerException({
    required String message,
    String? code,
    this.statusCode,
    Map<String, dynamic>? details,
  }) : super(message: message, code: code, details: details);

  /// Bad request (400)
  const ServerException.badRequest([String? message])
      : super(
          message: message ?? 'Bad request',
          code: 'BAD_REQUEST',
        ),
        statusCode = 400;

  /// Unauthorized (401)
  const ServerException.unauthorized()
      : super(
          message: 'Unauthorized access',
          code: 'UNAUTHORIZED',
        ),
        statusCode = 401;

  /// Forbidden (403)
  const ServerException.forbidden()
      : super(
          message: 'Access forbidden',
          code: 'FORBIDDEN',
        ),
        statusCode = 403;

  /// Not found (404)
  const ServerException.notFound()
      : super(
          message: 'Resource not found',
          code: 'NOT_FOUND',
        ),
        statusCode = 404;

  /// Internal server error (500)
  const ServerException.internal()
      : super(
          message: 'Internal server error',
          code: 'INTERNAL_SERVER_ERROR',
        ),
        statusCode = 500;

  @override
  List<Object?> get props => [...super.props, statusCode];
}