import 'package:dartz/dartz.dart';

import '../../../core/error/app_exception.dart';
import '../entities/user.dart';
import '../entities/auth_entities.dart';
import '../repositories/auth_repository.dart';

/// Registration use case for new user signup
///
/// Handles user registration with role-based validation and proper
/// verification for student matriculation numbers and staff IDs.
class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  /// Execute user registration
  ///
  /// Validates registration data and creates new user account.
  Future<Either<AppException, AuthResponse>> call(
    RegistrationData registrationData,
  ) async {
    try {
      // Validate registration data
      final validationErrors = _validateRegistrationData(registrationData);
      if (validationErrors.isNotEmpty) {
        return Left(ValidationException(
          message: validationErrors.first,
          code: 'VALIDATION_ERROR',
          details: {'errors': validationErrors},
        ));
      }

      // Check network connectivity
      final networkResult = await _repository.hasNetworkConnection();
      return await networkResult.fold(
        (error) => Left(error),
        (hasNetwork) async {
          if (!hasNetwork) {
            return const Left(NetworkException.noConnection());
          }

          // Perform registration
          return await _repository.register(registrationData);
        },
      );
    } catch (e) {
      return Left(AuthException(
        message: 'Registration failed: ${e.toString()}',
        code: 'REGISTRATION_ERROR',
      ));
    }
  }

  /// Validate email availability
  ///
  /// Checks if the email is already registered in the system.
  Future<Either<AppException, bool>> isEmailAvailable(String email) async {
    try {
      // Basic validation first
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

          // This would call a specific API endpoint to check email availability
          // For now, we'll return true as a placeholder
          // In a real implementation, this would be:
          // return await _repository.checkEmailAvailability(email);
          return const Right(true);
        },
      );
    } catch (e) {
      return Left(ValidationException(
        message: 'Email validation failed: ${e.toString()}',
      ));
    }
  }

  /// Validate matriculation number availability
  ///
  /// Checks if the matriculation number is already registered.
  Future<Either<AppException, bool>> isMatricNumberAvailable(
    String matricNumber,
  ) async {
    try {
      // Basic validation first
      if (!_repository.isValidMatricNumber(matricNumber)) {
        return const Left(ValidationException.invalidMatricNumber());
      }

      // Check network connectivity
      final networkResult = await _repository.hasNetworkConnection();
      return await networkResult.fold(
        (error) => Left(error),
        (hasNetwork) async {
          if (!hasNetwork) {
            return const Left(NetworkException.noConnection());
          }

          // This would call a specific API endpoint to check matric number availability
          // For now, we'll return true as a placeholder
          // In a real implementation, this would be:
          // return await _repository.checkMatricNumberAvailability(matricNumber);
          return const Right(true);
        },
      );
    } catch (e) {
      return Left(ValidationException(
        message: 'Matric number validation failed: ${e.toString()}',
      ));
    }
  }

  /// Validate staff ID availability
  ///
  /// Checks if the staff ID is already registered.
  Future<Either<AppException, bool>> isStaffIdAvailable(String staffId) async {
    try {
      // Basic validation first
      if (!_repository.isValidStaffId(staffId)) {
        return const Left(ValidationException.invalidStaffId());
      }

      // Check network connectivity
      final networkResult = await _repository.hasNetworkConnection();
      return await networkResult.fold(
        (error) => Left(error),
        (hasNetwork) async {
          if (!hasNetwork) {
            return const Left(NetworkException.noConnection());
          }

          // This would call a specific API endpoint to check staff ID availability
          // For now, we'll return true as a placeholder
          // In a real implementation, this would be:
          // return await _repository.checkStaffIdAvailability(staffId);
          return const Right(true);
        },
      );
    } catch (e) {
      return Left(ValidationException(
        message: 'Staff ID validation failed: ${e.toString()}',
      ));
    }
  }

  /// Get available user roles for registration
  ///
  /// Returns list of roles that can be selected during registration.
  List<UserRole> getAvailableRoles() {
    // In a real implementation, this might depend on configuration
    // or user permissions. For now, we return student and staff.
    return [UserRole.student, UserRole.staff];
  }

  /// Validate registration data comprehensively
  List<String> _validateRegistrationData(RegistrationData data) {
    final errors = <String>[];

    // Email validation
    if (data.email.isEmpty) {
      errors.add('Email is required');
    } else if (!_repository.isValidEmail(data.email)) {
      errors.add('Please enter a valid email address');
    }

    // Password validation
    if (data.password.isEmpty) {
      errors.add('Password is required');
    } else if (!_repository.isValidPassword(data.password)) {
      errors.add('Password must be at least 8 characters with uppercase, lowercase, and number');
    }

    // Full name validation
    if (data.fullName.isEmpty) {
      errors.add('Full name is required');
    } else if (data.fullName.trim().length < 2) {
      errors.add('Full name must be at least 2 characters');
    } else if (!RegExp(r'^[a-zA-Z\s\-\.\']+$').hasMatch(data.fullName)) {
      errors.add('Full name can only contain letters, spaces, hyphens, dots, and apostrophes');
    }

    // Role-specific validation
    switch (data.role) {
      case UserRole.student:
        if (data.matricNumber == null || data.matricNumber!.isEmpty) {
          errors.add('Matriculation number is required for students');
        } else if (!_repository.isValidMatricNumber(data.matricNumber!)) {
          errors.add('Invalid matriculation number format (e.g., MAT12345)');
        }
        break;

      case UserRole.staff:
      case UserRole.admin:
      case UserRole.electoralCommittee:
        if (data.staffId == null || data.staffId!.isEmpty) {
          errors.add('Staff ID is required for staff members');
        } else if (!_repository.isValidStaffId(data.staffId!)) {
          errors.add('Staff ID must be at least 4 characters');
        }
        break;
    }

    // Additional business rules
    _validateBusinessRules(data, errors);

    return errors;
  }

  /// Validate business-specific rules
  void _validateBusinessRules(RegistrationData data, List<String> errors) {
    // KWASU-specific email domain validation (if required)
    if (data.role == UserRole.student) {
      // Students might be required to use university email
      // This is configurable based on requirements
      final emailDomain = data.email.split('@').last.toLowerCase();
      final allowedDomains = ['kwasu.edu.ng', 'student.kwasu.edu.ng'];
      if (!allowedDomains.contains(emailDomain)) {
        // For now, we'll just warn rather than enforce
        // errors.add('Students should use their KWASU email address');
      }
    }

    // Matriculation number format validation (KWASU-specific)
    if (data.role == UserRole.student && data.matricNumber != null) {
      final matricNumber = data.matricNumber!.toUpperCase();
      if (!RegExp(r'^[A-Z]{3}\d{5}$').hasMatch(matricNumber)) {
        errors.add('Matriculation number must be in format: ABC12345 (3 letters followed by 5 digits)');
      }
    }

    // Staff ID format validation (KWASU-specific)
    if (data.role != UserRole.student && data.staffId != null) {
      if (data.staffId!.length < 4) {
        errors.add('Staff ID must be at least 4 characters long');
      }
      if (!RegExp(r'^[A-Z0-9]+$').hasMatch(data.staffId!.toUpperCase())) {
        errors.add('Staff ID can only contain letters and numbers');
      }
    }

    // Name validation (Nigerian naming conventions)
    if (data.fullName.isNotEmpty) {
      final nameParts = data.fullName.trim().split(' ');
      if (nameParts.length < 2) {
        errors.add('Please enter your full name (first and last name)');
      }
      if (nameParts.any((part) => part.length < 2)) {
        errors.add('Each part of your name must be at least 2 characters');
      }
    }

    // Password strength validation (additional rules)
    if (data.password.isNotEmpty) {
      if (data.password.length < 8) {
        errors.add('Password must be at least 8 characters long');
      }
      if (!RegExp(r'(?=.*[a-z])').hasMatch(data.password)) {
        errors.add('Password must contain at least one lowercase letter');
      }
      if (!RegExp(r'(?=.*[A-Z])').hasMatch(data.password)) {
        errors.add('Password must contain at least one uppercase letter');
      }
      if (!RegExp(r'(?=.*\d)').hasMatch(data.password)) {
        errors.add('Password must contain at least one number');
      }
      if (!RegExp(r'(?=.*[@$!%*?&])').hasMatch(data.password)) {
        // This is optional but recommended
        // errors.add('Password should contain at least one special character');
      }
      
      // Check for common passwords
      final commonPasswords = ['password', '12345678', 'qwerty123'];
      if (commonPasswords.contains(data.password.toLowerCase())) {
        errors.add('Please choose a more secure password');
      }
    }
  }
}