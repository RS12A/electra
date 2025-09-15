import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/failures.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String matricNumber,
    required String password,
  }) async {
    if (matricNumber.isEmpty) {
      return const Left(ValidationFailure(
        message: 'Matric number is required',
        code: 'MATRIC_NUMBER_REQUIRED',
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

    return await repository.login(
      matricNumber: matricNumber,
      password: password,
    );
  }
}