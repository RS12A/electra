import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../storage/storage_service.dart';
import '../theme/theme_controller.dart';
import 'injection_container.config.dart';

/// Service locator instance
final getIt = GetIt.instance;

/// Configure all dependencies for dependency injection
///
/// This function sets up all services, repositories, use cases,
/// and other dependencies needed throughout the application.
@InjectableInit()
Future<void> configureDependencies() async {
  // Register manual dependencies that can't be auto-registered
  await _registerManualDependencies();
  
  // Initialize generated dependencies
  await getIt.init();
}

/// Register dependencies that need manual registration
Future<void> _registerManualDependencies() async {
  // Register FlutterSecureStorage
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    ),
  );

  // Register StorageService with dependency
  getIt.registerSingleton<StorageService>(
    StorageService(getIt<FlutterSecureStorage>()),
  );

  // Register ThemeController with dependency
  getIt.registerSingleton<ThemeController>(
    ThemeController(getIt<StorageService>()),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}
