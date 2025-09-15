import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../../../../core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String matricNumber,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String matricNumber,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? department,
    String? faculty,
    int? yearOfStudy,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, void>> verifyEmail({
    required String token,
  });

  Future<Either<Failure, void>> forgotPassword({
    required String email,
  });

  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Either<Failure, void>> enableBiometric({
    required bool enabled,
    String? biometricData,
  });

  Future<Either<Failure, bool>> isAuthenticated();

  Future<Either<Failure, void>> refreshToken();
}