import 'package:equatable/equatable.dart';

/// Authentication response entity containing tokens and user information
///
/// This entity represents the response received after successful authentication,
/// containing the JWT tokens and user details.
class AuthResponse extends Equatable {
  /// JWT access token for API authentication
  final String accessToken;

  /// JWT refresh token for obtaining new access tokens
  final String refreshToken;

  /// User information
  final User user;

  /// Token expiry time in seconds
  final int expiresIn;

  /// Token type (usually 'Bearer')
  final String tokenType;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresIn,
    this.tokenType = 'Bearer',
  });

  /// Get token expiry date
  DateTime get expiryDate => DateTime.now().add(Duration(seconds: expiresIn));

  /// Check if token is expired
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  /// Get authorization header value
  String get authorizationHeader => '$tokenType $accessToken';

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        user,
        expiresIn,
        tokenType,
      ];

  @override
  String toString() {
    return 'AuthResponse(user: ${user.email}, expiresIn: $expiresIn)';
  }
}

/// Login credentials entity
class LoginCredentials extends Equatable {
  /// User identifier (email, matric number, or staff ID)
  final String identifier;

  /// User password
  final String password;

  /// Whether to remember the user for auto-login
  final bool rememberMe;

  const LoginCredentials({
    required this.identifier,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [identifier, password, rememberMe];
}

/// Registration data entity
class RegistrationData extends Equatable {
  /// User's email address
  final String email;

  /// User's password
  final String password;

  /// User's full name
  final String fullName;

  /// User's role
  final UserRole role;

  /// Matriculation number (for students)
  final String? matricNumber;

  /// Staff ID (for staff)
  final String? staffId;

  const RegistrationData({
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    this.matricNumber,
    this.staffId,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        fullName,
        role,
        matricNumber,
        staffId,
      ];

  /// Validate registration data
  List<String> validate() {
    final errors = <String>[];

    if (email.isEmpty) {
      errors.add('Email is required');
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      errors.add('Invalid email format');
    }

    if (password.isEmpty) {
      errors.add('Password is required');
    } else if (password.length < 8) {
      errors.add('Password must be at least 8 characters');
    } else if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
      errors.add('Password must contain uppercase, lowercase, and number');
    }

    if (fullName.isEmpty) {
      errors.add('Full name is required');
    }

    if (role == UserRole.student) {
      if (matricNumber == null || matricNumber!.isEmpty) {
        errors.add('Matriculation number is required for students');
      } else if (!RegExp(r'^[A-Z]{3}\d{5}$').hasMatch(matricNumber!.toUpperCase())) {
        errors.add('Invalid matriculation number format (e.g., MAT12345)');
      }
    }

    if (role == UserRole.staff || role == UserRole.admin || role == UserRole.electoralCommittee) {
      if (staffId == null || staffId!.isEmpty) {
        errors.add('Staff ID is required for staff members');
      } else if (staffId!.length < 4) {
        errors.add('Staff ID must be at least 4 characters');
      }
    }

    return errors;
  }
}

/// Password reset request entity
class PasswordResetRequest extends Equatable {
  /// Email address for password reset
  final String email;

  const PasswordResetRequest({required this.email});

  @override
  List<Object?> get props => [email];
}

/// OTP verification entity
class OtpVerification extends Equatable {
  /// Email address
  final String email;

  /// OTP code
  final String otpCode;

  /// New password (for password reset)
  final String? newPassword;

  const OtpVerification({
    required this.email,
    required this.otpCode,
    this.newPassword,
  });

  @override
  List<Object?> get props => [email, otpCode, newPassword];
}

/// Biometric authentication result entity
class BiometricAuthResult extends Equatable {
  /// Whether biometric authentication was successful
  final bool isAuthenticated;

  /// Error message if authentication failed
  final String? errorMessage;

  /// Type of biometric used
  final BiometricType? biometricType;

  const BiometricAuthResult({
    required this.isAuthenticated,
    this.errorMessage,
    this.biometricType,
  });

  @override
  List<Object?> get props => [isAuthenticated, errorMessage, biometricType];
}

/// Types of biometric authentication
enum BiometricType {
  fingerprint,
  faceId,
  touchId,
  iris,
  voice,
}

/// Import missing User entity for reference
import '../entities/user.dart';