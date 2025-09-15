import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../../../../core/error/exceptions.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login({
    required String matricNumber,
    required String password,
  });

  Future<AuthResponse> register({
    required String matricNumber,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? department,
    String? faculty,
    int? yearOfStudy,
  });

  Future<UserModel> getCurrentUser();

  Future<void> logout();

  Future<void> verifyEmail({required String token});

  Future<void> forgotPassword({required String email});

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> enableBiometric({
    required bool enabled,
    String? biometricData,
  });

  Future<AuthResponse> refreshToken({required String refreshToken});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<AuthResponse> login({
    required String matricNumber,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'matricNumber': matricNumber,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(response.data);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<AuthResponse> register({
    required String matricNumber,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? department,
    String? faculty,
    int? yearOfStudy,
  }) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'matricNumber': matricNumber,
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          if (department != null) 'department': department,
          if (faculty != null) 'faculty': faculty,
          if (yearOfStudy != null) 'yearOfStudy': yearOfStudy,
        },
      );

      if (response.statusCode == 201) {
        return AuthResponse.fromJson(response.data);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dio.get('/users/profile');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user']);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Failed to get user profile',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
    } on DioException catch (e) {
      // Ignore logout errors as we want to clear local data anyway
      print('Logout error: ${e.message}');
    }
  }

  @override
  Future<void> verifyEmail({required String token}) async {
    try {
      final response = await dio.post(
        '/auth/verify-email',
        data: {'token': token},
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Email verification failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    try {
      final response = await dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Password reset request failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await dio.post(
        '/auth/reset-password',
        data: {
          'token': token,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Password reset failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await dio.post(
        '/users/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Password change failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> enableBiometric({
    required bool enabled,
    String? biometricData,
  }) async {
    try {
      final response = await dio.post(
        '/users/biometric',
        data: {
          'enabled': enabled,
          if (biometricData != null) 'biometricData': biometricData,
        },
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: response.data['message'] ?? 'Biometric setting update failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<AuthResponse> refreshToken({required String refreshToken}) async {
    try {
      final response = await dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(response.data);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Token refresh failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  ServerException _handleDioException(DioException e) {
    String message = 'An error occurred';
    int? statusCode;

    if (e.response != null) {
      statusCode = e.response!.statusCode;
      if (e.response!.data is Map<String, dynamic>) {
        message = e.response!.data['message'] ?? message;
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
               e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection. Please check your connection and try again.';
    }

    return ServerException(
      message: message,
      statusCode: statusCode,
    );
  }
}

class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      accessToken: json['tokens']['accessToken'],
      refreshToken: json['tokens']['refreshToken'],
    );
  }
}