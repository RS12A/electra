import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_models.dart';
import '../../../core/error/app_exception.dart';

/// Remote data source for authentication API calls
///
/// This class handles all HTTP requests to the Electra backend API
/// for authentication-related operations.
class AuthRemoteDataSource {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  /// API endpoints
  static const String _loginEndpoint = '/api/auth/login/';
  static const String _registerEndpoint = '/api/auth/register/';
  static const String _refreshEndpoint = '/api/auth/token/refresh/';
  static const String _logoutEndpoint = '/api/auth/logout/';
  static const String _profileEndpoint = '/api/auth/profile/';
  static const String _passwordResetEndpoint = '/api/auth/password-reset/';
  static const String _passwordResetConfirmEndpoint = '/api/auth/password-reset-confirm/';

  AuthRemoteDataSource(this._dio, this._secureStorage) {
    _setupInterceptors();
  }

  /// Setup Dio interceptors for authentication and error handling
  void _setupInterceptors() {
    // Request interceptor for adding auth headers
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authentication token if available
          final token = await _getStoredToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Add content type
          options.headers['Content-Type'] = 'application/json';
          
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle token expiry
          if (error.response?.statusCode == 401) {
            final refreshed = await _attemptTokenRefresh();
            if (refreshed) {
              // Retry original request with new token
              final token = await _getStoredToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              
              final retryResponse = await _dio.fetch(error.requestOptions);
              handler.resolve(retryResponse);
              return;
            }
          }
          
          handler.next(error);
        },
      ),
    );
  }

  /// Login user with credentials
  Future<AuthResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await _dio.post(
        _loginEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        await _storeTokens(authResponse.accessToken, authResponse.refreshToken);
        return authResponse;
      } else {
        throw ServerException(
          message: 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Login failed: ${e.toString()}');
    }
  }

  /// Register new user
  Future<AuthResponseModel> register(RegistrationRequestModel request) async {
    try {
      final response = await _dio.post(
        _registerEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        await _storeTokens(authResponse.accessToken, authResponse.refreshToken);
        return authResponse;
      } else {
        throw ServerException(
          message: 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Registration failed: ${e.toString()}');
    }
  }

  /// Send password reset OTP
  Future<void> sendPasswordResetOtp(PasswordResetRequestModel request) async {
    try {
      final response = await _dio.post(
        _passwordResetEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to send reset code',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Failed to send reset code: ${e.toString()}');
    }
  }

  /// Verify OTP code
  Future<void> verifyOtp(OtpVerificationModel verification) async {
    try {
      final response = await _dio.post(
        _passwordResetConfirmEndpoint,
        data: verification.toJson(),
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'OTP verification failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'OTP verification failed: ${e.toString()}');
    }
  }

  /// Reset password with OTP
  Future<void> resetPassword(OtpVerificationModel verification) async {
    try {
      final response = await _dio.post(
        _passwordResetConfirmEndpoint,
        data: verification.toJson(),
      );

      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Password reset failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Password reset failed: ${e.toString()}');
    }
  }

  /// Refresh authentication token
  Future<AuthResponseModel> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        _refreshEndpoint,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        await _storeTokens(authResponse.accessToken, authResponse.refreshToken);
        return authResponse;
      } else {
        throw ServerException(
          message: 'Token refresh failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Token refresh failed: ${e.toString()}');
    }
  }

  /// Get current user profile
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(_profileEndpoint);

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to get user profile',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Failed to get user profile: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile(UserModel user) async {
    try {
      final response = await _dio.patch(
        _profileEndpoint,
        data: user.toJson(),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to update profile',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException(message: 'Failed to update profile: ${e.toString()}');
    }
  }

  /// Logout user
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post(
        _logoutEndpoint,
        data: {'refresh': refreshToken},
      );
      
      // Clear stored tokens
      await _clearStoredTokens();
    } on DioException catch (e) {
      // Even if logout fails on server, clear local tokens
      await _clearStoredTokens();
      throw _handleDioError(e);
    } catch (e) {
      await _clearStoredTokens();
      throw ServerException(message: 'Logout failed: ${e.toString()}');
    }
  }

  /// Get stored access token
  Future<String?> _getStoredToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  /// Store authentication tokens
  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  /// Clear stored tokens
  Future<void> _clearStoredTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  /// Attempt to refresh expired token
  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await _dio.post(
        _refreshEndpoint,
        data: {'refresh': refreshToken},
        options: Options(
          headers: {}, // Don't add auth header for refresh
        ),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(response.data);
        await _storeTokens(authResponse.accessToken, authResponse.refreshToken);
        return true;
      }
    } catch (e) {
      // Token refresh failed, clear stored tokens
      await _clearStoredTokens();
    }
    return false;
  }

  /// Handle Dio errors and convert to app exceptions
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException.timeout();

      case DioExceptionType.connectionError:
        return const NetworkException.noConnection();

      case DioExceptionType.badResponse:
        return _handleHttpError(error.response);

      case DioExceptionType.cancel:
        return const NetworkException(
          message: 'Request was cancelled',
          code: 'REQUEST_CANCELLED',
        );

      case DioExceptionType.unknown:
      default:
        return NetworkException(
          message: 'Network error: ${error.message}',
          code: 'UNKNOWN_ERROR',
        );
    }
  }

  /// Handle HTTP response errors
  AppException _handleHttpError(Response? response) {
    if (response == null) {
      return const ServerException.internal();
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;

    String message = 'Server error occurred';
    String? code;

    // Try to extract error message from response
    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ??
               data['detail'] as String? ??
               data['error'] as String? ??
               message;
      code = data['code'] as String?;
    }

    switch (statusCode) {
      case 400:
        return AuthException(message: message, code: code ?? 'BAD_REQUEST');
      case 401:
        return const AuthException.invalidToken();
      case 403:
        return const AuthException.accountSuspended();
      case 404:
        return const AuthException.userNotFound();
      case 429:
        return const AuthException.tooManyAttempts();
      case 500:
      default:
        return ServerException(
          message: message,
          statusCode: statusCode,
          code: code,
        );
    }
  }
}