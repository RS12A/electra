import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/elections/data/datasources/elections_local_data_source.dart';
import '../../features/elections/data/datasources/elections_remote_data_source.dart';
import '../../features/elections/data/repositories/elections_repository_impl.dart';
import '../../features/elections/domain/repositories/elections_repository.dart';
import '../../features/elections/domain/usecases/get_elections_usecase.dart';
import '../../features/elections/presentation/bloc/elections_bloc.dart';

import '../network/network_info.dart';
import '../services/local_storage_service.dart';
import '../services/navigation_service.dart';
import '../services/notification_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> init() async {
  // Initialize Hive for local storage
  await _initHive();
  
  // Core
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(getIt()));
  getIt.registerLazySingleton<LocalStorageService>(() => LocalStorageServiceImpl());
  getIt.registerLazySingleton<NavigationService>(() => NavigationService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  
  // External
  getIt.registerLazySingleton<Dio>(() => _createDio());
  getIt.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: IOSAccessibility.first_unlock_this_device),
  ));
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  
  // Auth Feature
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: getIt()),
  );
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: getIt()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      networkInfo: getIt(),
    ),
  );
  getIt.registerLazySingleton<LoginUseCase>(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton<RegisterUseCase>(() => RegisterUseCase(getIt()));
  getIt.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(getIt()));
  getIt.registerFactory<AuthBloc>(() => AuthBloc(
    loginUseCase: getIt(),
    registerUseCase: getIt(),
    logoutUseCase: getIt(),
  ));
  
  // Elections Feature
  getIt.registerLazySingleton<ElectionsRemoteDataSource>(
    () => ElectionsRemoteDataSourceImpl(dio: getIt()),
  );
  getIt.registerLazySingleton<ElectionsLocalDataSource>(
    () => ElectionsLocalDataSourceImpl(),
  );
  getIt.registerLazySingleton<ElectionsRepository>(
    () => ElectionsRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt(),
      networkInfo: getIt(),
    ),
  );
  getIt.registerLazySingleton<GetElectionsUseCase>(() => GetElectionsUseCase(getIt()));
  getIt.registerFactory<ElectionsBloc>(() => ElectionsBloc(getElectionsUseCase: getIt()));
}

Future<void> _initHive() async {
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  
  // Initialize boxes for offline storage
  await Hive.openBox('auth');
  await Hive.openBox('elections');
  await Hive.openBox('votes');
  await Hive.openBox('users');
  await Hive.openBox('settings');
}

Dio _createDio() {
  final dio = Dio();
  
  // Base configuration
  dio.options = BaseOptions(
    baseUrl: 'http://localhost:3000/api/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
  
  // Add interceptors
  dio.interceptors.addAll([
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('[DIO] $obj'),
    ),
    // Auth interceptor
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        final token = await getIt<AuthLocalDataSource>().getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle token refresh on 401
        if (error.response?.statusCode == 401) {
          try {
            // Try to refresh token
            final refreshToken = await getIt<AuthLocalDataSource>().getRefreshToken();
            if (refreshToken != null) {
              // Implement token refresh logic here
              // For now, just clear tokens and redirect to login
              await getIt<AuthLocalDataSource>().clearTokens();
            }
          } catch (e) {
            await getIt<AuthLocalDataSource>().clearTokens();
          }
        }
        handler.next(error);
      },
    ),
  ]);
  
  return dio;
}