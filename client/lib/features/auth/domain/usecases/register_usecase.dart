import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/failures.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String matricNumber,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? department,
    String? faculty,
    int? yearOfStudy,
  }) async {
    // Validation
    if (matricNumber.isEmpty) {
      return const Left(ValidationFailure(
        message: 'Matric number is required',
        code: 'MATRIC_NUMBER_REQUIRED',
      ));
    }

    if (email.isEmpty) {
      return const Left(ValidationFailure(
        message: 'Email is required',
        code: 'EMAIL_REQUIRED',
      ));
    }

    if (!_isValidEmail(email)) {
      return const Left(ValidationFailure(
        message: 'Please enter a valid email address',
        code: 'INVALID_EMAIL',
      ));
    }

    if (password.isEmpty) {
      return const Left(ValidationFailure(
        message: 'Password is required',
        code: 'PASSWORD_REQUIRED',
      ));
    }

    if (password.length < 8) {
      return const Left(ValidationFailure(
        message: 'Password must be at least 8 characters',
        code: 'PASSWORD_TOO_SHORT',
      ));
    }

    if (firstName.isEmpty) {
      return const Left(ValidationFailure(
        message: 'First name is required',
        code: 'FIRST_NAME_REQUIRED',
      ));
    }

    if (lastName.isEmpty) {
      return const Left(ValidationFailure(
        message: 'Last name is required',
        code: 'LAST_NAME_REQUIRED',
      ));
    }

    return await repository.register(
      matricNumber: matricNumber,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      department: department,
      faculty: faculty,
      yearOfStudy: yearOfStudy,
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }
}