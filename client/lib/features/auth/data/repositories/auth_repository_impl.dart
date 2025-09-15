import 'package:dartz/dartz.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> login({
    required String matricNumber,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final authResponse = await remoteDataSource.login(
          matricNumber: matricNumber,
          password: password,
        );

        // Cache user and tokens
        await localDataSource.cacheUser(authResponse.user);
        await localDataSource.storeTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );

        return Right(authResponse.user);
      } on ServerException catch (e) {
        return Left(ServerFailure(
          message: e.message,
          code: e.code,
        ));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(
          message: e.message,
        ));
      } catch (e) {
        return Left(UnknownFailure(
          message: 'An unexpected error occurred during login',
        ));
      }
    } else {
      return const Left(NetworkFailure(
        message: 'No internet connection. Please check your connection and try again.',
      ));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String matricNumber,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? department,
    String? faculty,
    int? yearOfStudy,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final authResponse = await remoteDataSource.register(
          matricNumber: matricNumber,
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          department: department,
          faculty: faculty,
          yearOfStudy: yearOfStudy,
        );

        // Cache user and tokens
        await localDataSource.cacheUser(authResponse.user);
        await localDataSource.storeTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );

        return Right(authResponse.user);
      } on ServerException catch (e) {
        return Left(ServerFailure(
          message: e.message,
          code: e.code,
        ));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(
          message: e.message,
        ));
      } catch (e) {
        return Left(UnknownFailure(
          message: 'An unexpected error occurred during registration',
        ));
      }
    } else {
      return const Left(NetworkFailure(
        message: 'No internet connection. Please check your connection and try again.',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Try to logout from server if connected
      if (await networkInfo.isConnected) {
        await remoteDataSource.logout();
      }

      // Always clear local data
      await localDataSource.clearUser();
      await localDataSource.clearTokens();

      return const Right(null);
    } catch (e) {
      // Even if server logout fails, clear local data
      await localDataSource.clearUser();
      await localDataSource.clearTokens();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      // First try to get from cache
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        // If connected, try to refresh user data
        if (await networkInfo.isConnected) {
          try {
            final user = await remoteDataSource.getCurrentUser();
            await localDataSource.cacheUser(user);
            return Right(user);
          } catch (e) {
            // Return cached user if server call fails
            return Right(cachedUser);
          }
        }
        return Right(cachedUser);
      }

      // If no cached user and connected, get from server
      if (await networkInfo.isConnected) {
        final user = await remoteDataSource.getCurrentUser();
        await localDataSource.cacheUser(user);
        return Right(user);
      }

      return const Left(AuthFailure(
        message: 'No user data available. Please log in again.',
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        code: e.code,
      ));
    } catch (e) {
      return Left(UnknownFailure(
        message: 'An unexpected error occurred while getting user data',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmail({required String token}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.verifyEmail(token: token);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(
          message: e.message,
          code: e.code,
        ));
      } catch (e) {
        return Left(UnknownFailure(
          message: 'An unexpected error occurred during email verification',
        ));
      }
    } else {
      return const Left(NetworkFailure(
        message: 'No internet connection. Please check your connection and try again.',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.forgotPassword(email: email);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(
          message: e.message,
          code: e.code,
        ));
      } catch (e) {
        return Left(UnknownFailure(
          message: 'An unexpected error occurred while requesting password reset',
        ));
      }
    } else {
      return const Left(NetworkFailure(
        message: 'No internet connection. Please check your connection and try again.',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resetPassword(
          token: token,
          newPassword: newPassword,
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(
          message: e.message,
          code: e.code,
        ));
      } catch (e) {
        return Left(UnknownFailure(
          message: 'An unexpected error occurred while resetting password',
        ));
      }
    } else {
      return const Left(NetworkFailure(
        message: 'No internet connection. Please check your connection and try again.',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(
          message: e.message,
          code: e.code,
        ));
      } catch (e) {
        return Left(UnknownFailure(
          message: 'An unexpected error occurred while changing password',
        ));
      }
    } else {
      return const Left(NetworkFailure(
        message: 'No internet connection. Please check your connection and try again.',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> enableBiometric({
    required bool enabled,
    String? biometricData,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.enableBiometric(
          enabled: enabled,
          biometricData: biometricData,
        );

        // Update cached user
        final cachedUser = await localDataSource.getCachedUser();
        if (cachedUser != null) {
          final updatedUser = cachedUser.copyWith(biometricEnabled: enabled);
          await localDataSource.cacheUser(updatedUser);
        }

        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(
          message: e.message,
          code: e.code,
        ));
      } catch (e) {
        return Left(UnknownFailure(
          message: 'An unexpected error occurred while updating biometric settings',
        ));
      }
    } else {
      return const Left(NetworkFailure(
        message: 'No internet connection. Please check your connection and try again.',
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final isAuth = await localDataSource.isAuthenticated();
      return Right(isAuth);
    } catch (e) {
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, void>> refreshToken() async {
    if (await networkInfo.isConnected) {
      try {
        final refreshToken = await localDataSource.getRefreshToken();
        if (refreshToken == null) {
          return const Left(AuthFailure(
            message: 'No refresh token available',
          ));
        }

        final authResponse = await remoteDataSource.refreshToken(
          refreshToken: refreshToken,
        );

        // Update tokens
        await localDataSource.storeTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
        );

        return const Right(null);
      } on ServerException catch (e) {
        // If refresh fails, clear tokens
        await localDataSource.clearTokens();
        return Left(AuthFailure(
          message: e.message,
          code: e.code,
        ));
      } catch (e) {
        await localDataSource.clearTokens();
        return Left(UnknownFailure(
          message: 'An unexpected error occurred while refreshing token',
        ));
      }
    } else {
      return const Left(NetworkFailure(
        message: 'No internet connection. Please check your connection and try again.',
      ));
    }
  }
}