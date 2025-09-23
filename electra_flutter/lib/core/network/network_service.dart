import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../shared/constants/app_constants.dart';
import '../../shared/utils/logger.dart';

/// HTTP client service for API communication
///
/// Handles all network requests to the Django backend with proper
/// authentication, error handling, and logging.
@singleton
class NetworkService {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  NetworkService(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  /// Get the underlying Dio instance
  Dio get dio => _dio;

  /// Set up request/response interceptors
  void _setupInterceptors() {
    // Request interceptor for authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // Add auth token to requests
            final token = await _secureStorage.read(key: 'access_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = '******';
            }

            AppLogger.debug('🌐 ${options.method} ${options.path}');
            handler.next(options);
          } catch (e) {
            AppLogger.error('Request interceptor error', e);
            handler.next(options);
          }
        },

        onResponse: (response, handler) {
          AppLogger.debug(
            '✅ ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },

        onError: (error, handler) async {
          AppLogger.error(
            '❌ ${error.response?.statusCode} ${error.requestOptions.path}',
            error.message,
          );

          // Handle token refresh for 401 errors
          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the original request
              final opts = error.requestOptions;
              try {
                final cloneReq = await _dio.request(
                  opts.path,
                  options: Options(method: opts.method, headers: opts.headers),
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                );
                return handler.resolve(cloneReq);
              } catch (e) {
                AppLogger.error('Retry request failed', e);
              }
            } else {
              // Refresh failed, clear tokens and redirect to login
              await _clearTokens();
              // Emit unauthenticated event
            }
          }

          handler.next(error);
        },
      ),
    );

    // Logging interceptor
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => AppLogger.debug(object.toString()),
      ),
    );
  }

  /// Refresh authentication token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/api/auth/token/refresh/',
        data: {'refresh': refreshToken},
        options: Options(
          headers: {'Authorization': null},
        ), // Remove auth header
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['access'];
        await _secureStorage.write(key: 'access_token', value: accessToken);
        AppLogger.info('Token refreshed successfully');
        return true;
      }
    } catch (e) {
      AppLogger.error('Token refresh failed', e);
    }

    return false;
  }

  /// Clear all stored tokens
  Future<void> _clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Upload file
  Future<Response> uploadFile(
    String path,
    String filePath, {
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final formData = FormData.fromMap({
      if (data != null) ...data,
      'file': await MultipartFile.fromFile(filePath),
    });

    return _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  /// Download file
  Future<Response> downloadFile(
    String path,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    return _dio.download(
      path,
      savePath,
      queryParameters: queryParameters,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }
}
