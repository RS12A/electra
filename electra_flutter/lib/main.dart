import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';

import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/storage_service.dart';
import 'shared/utils/logger.dart';

/// Main entry point of the Electra Flutter application
///
/// Initializes all dependencies, storage, and starts the app with proper
/// error handling and logging configuration.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  AppLogger.initialize();
  AppLogger.info('Starting Electra Flutter App');

  try {
    // Initialize local storage
    await _initializeStorage();

    // Initialize dependency injection
    await configureDependencies();

    runApp(const ProviderScope(child: ElectraApp()));
  } catch (error, stackTrace) {
    AppLogger.error('Failed to initialize app', error, stackTrace);
    // Show error UI in case of critical failure
    runApp(ErrorApp(error: error));
  }
}

/// Initialize local storage systems (Hive & Isar)
Future<void> _initializeStorage() async {
  try {
    // Initialize Hive
    await Hive.initFlutter();

    // Initialize Isar
    final storageService = getIt<StorageService>();
    await storageService.initialize();

    AppLogger.info('Storage systems initialized successfully');
  } catch (error, stackTrace) {
    AppLogger.error('Failed to initialize storage', error, stackTrace);
    rethrow;
  }
}

/// Main application widget with theme, routing, and error handling
class ElectraApp extends ConsumerWidget {
  const ElectraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Electra - Secure Digital Voting',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Router configuration
      routerConfig: router,

      // Localization
      supportedLocales: const [Locale('en', 'US')],

      // Error handling
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          AppLogger.error(
            'Widget error occurred',
            details.exception,
            details.stack,
          );
          return ErrorDisplay(error: details.exception);
        };
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

/// Error app displayed when critical initialization fails
class ErrorApp extends StatelessWidget {
  final Object error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF1E3A8A), // KWASU Blue
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Electra App Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to initialize: ${error.toString()}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => main(), // Restart app
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Error display widget for runtime errors
class ErrorDisplay extends StatelessWidget {
  final Object error;

  const ErrorDisplay({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.red[50],
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: Colors.red[700], size: 48),
              const SizedBox(height: 8),
              Text(
                'An error occurred',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.red[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
