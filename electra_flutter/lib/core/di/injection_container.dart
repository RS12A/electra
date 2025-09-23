import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection_container.config.dart';

/// Service locator instance
final getIt = GetIt.instance;

/// Configure all dependencies for dependency injection
///
/// This function sets up all services, repositories, use cases,
/// and other dependencies needed throughout the application.
@InjectableInit()
Future<void> configureDependencies() async {
  await getIt.init();
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}
