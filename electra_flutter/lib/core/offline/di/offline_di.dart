import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';

import '../encryption/offline_encryption_service.dart';
import '../repositories/offline_queue_repository.dart';
import '../services/network_monitor_service.dart';
import '../services/sync_orchestrator_service.dart';
import '../services/sync_handler_service.dart';
import '../models/queue_item.dart';
import '../models/sync_config.dart';
import '../../services/logger_service.dart';

/// Dependency injection configuration for offline module
@module
abstract class OfflineDI {
  // External dependencies
  @lazySingleton
  Connectivity get connectivity => Connectivity();

  @lazySingleton
  @Named('offlineHttpClient')
  Dio get offlineHttpClient => Dio()
    ..options.connectTimeout = const Duration(seconds: 10)
    ..options.receiveTimeout = const Duration(seconds: 10)
    ..options.sendTimeout = const Duration(seconds: 10);

  @lazySingleton
  @Named('offlineSecureStorage')
  FlutterSecureStorage get offlineSecureStorage => const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Core offline services
  @lazySingleton
  OfflineEncryptionService offlineEncryptionService(
    @Named('offlineSecureStorage') FlutterSecureStorage secureStorage,
    LoggerService logger,
  ) => OfflineEncryptionService(secureStorage, logger);

  @lazySingleton
  NetworkMonitorService networkMonitorService(
    Connectivity connectivity,
    LoggerService logger,
    @Named('offlineHttpClient') Dio dio,
  ) => NetworkMonitorService(connectivity, logger, dio);

  // Repository
  @Singleton(as: IOfflineQueueRepository)
  OfflineQueueRepository offlineQueueRepository(
    @Named('offlineIsar') Isar isar,
    OfflineEncryptionService encryptionService,
    LoggerService logger,
  ) => OfflineQueueRepository(isar, encryptionService, logger);

  // Sync services
  @lazySingleton
  SyncHandlerService syncHandlerService(
    LoggerService logger,
    // These would be injected from their respective modules
    @Named('castVoteUseCase') MockCastVote castVoteUseCase,
    @Named('refreshTokenUseCase') MockRefreshToken refreshTokenUseCase,
    @Named('markNotificationAsReadUseCase') MockMarkNotificationAsRead markNotificationAsReadUseCase,
  ) => SyncHandlerService(
    logger,
    castVoteUseCase,
    refreshTokenUseCase,
    markNotificationAsReadUseCase,
  );

  @lazySingleton
  SyncOrchestratorService syncOrchestratorService(
    IOfflineQueueRepository queueRepository,
    NetworkMonitorService networkMonitor,
    SyncHandlerService syncHandler,
    LoggerService logger,
  ) => SyncOrchestratorService(
    queueRepository,
    networkMonitor,
    syncHandler,
    logger,
  );
}

/// Extension for GetIt to register offline dependencies
extension OfflineGetItExtension on GetIt {
  /// Register all offline module dependencies
  Future<void> registerOfflineModule() async {
    // Register Isar database instance
    if (!isRegistered<Isar>(instanceName: 'offlineIsar')) {
      final isar = await _initializeIsarDatabase();
      registerSingleton<Isar>(isar, instanceName: 'offlineIsar');
    }

    // Initialize encryption service
    final encryptionService = get<OfflineEncryptionService>();
    await encryptionService.initialize();

    // Initialize and start network monitoring
    final networkMonitor = get<NetworkMonitorService>();
    await networkMonitor.startMonitoring();

    // Initialize sync orchestrator with default configuration
    final syncOrchestrator = get<SyncOrchestratorService>();
    await syncOrchestrator.initialize(SyncConfigPresets.production);
  }

  /// Clean up offline module resources
  Future<void> disposeOfflineModule() async {
    try {
      // Stop network monitoring
      if (isRegistered<NetworkMonitorService>()) {
        final networkMonitor = get<NetworkMonitorService>();
        await networkMonitor.stopMonitoring();
      }

      // Dispose sync orchestrator
      if (isRegistered<SyncOrchestratorService>()) {
        final syncOrchestrator = get<SyncOrchestratorService>();
        syncOrchestrator.dispose();
      }

      // Close Isar database
      if (isRegistered<Isar>(instanceName: 'offlineIsar')) {
        final isar = get<Isar>(instanceName: 'offlineIsar');
        await isar.close();
      }
    } catch (e) {
      // Log error but don't throw to avoid crash during app disposal
      print('Error disposing offline module: $e');
    }
  }
}

/// Initialize Isar database for offline storage
Future<Isar> _initializeIsarDatabase() async {
  final isar = await Isar.open([
    QueueItemSchema,
  ]);
  
  return isar;
}

/// Mock use case implementations for testing
/// These would be replaced with actual use cases in production

class MockCastVote {
  Future<dynamic> call(dynamic params) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
    return {'success': true};
  }
}

class MockRefreshToken {
  Future<dynamic> call(dynamic params) async {
    // Mock implementation  
    await Future.delayed(const Duration(milliseconds: 300));
    return {'success': true};
  }
}

class MockMarkNotificationAsRead {
  Future<dynamic> call(dynamic params) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 200));
    return {'success': true};
  }
}

/// Configuration for offline module in different environments
class OfflineModuleConfig {
  /// Development configuration with faster sync intervals
  static Future<void> configureDevelopment(GetIt getIt) async {
    await getIt.registerOfflineModule();
    
    final syncOrchestrator = getIt<SyncOrchestratorService>();
    syncOrchestrator.updateConfig(SyncConfigPresets.development);
  }

  /// Production configuration with conservative settings
  static Future<void> configureProduction(GetIt getIt) async {
    await getIt.registerOfflineModule();
    
    final syncOrchestrator = getIt<SyncOrchestratorService>();
    syncOrchestrator.updateConfig(SyncConfigPresets.production);
  }

  /// Battery optimized configuration for low-power scenarios
  static Future<void> configureBatteryOptimized(GetIt getIt) async {
    await getIt.registerOfflineModule();
    
    final syncOrchestrator = getIt<SyncOrchestratorService>();
    syncOrchestrator.updateConfig(SyncConfigPresets.batteryOptimized);
  }
}

/// Helper for initializing offline module in main.dart
class OfflineModuleInitializer {
  static Future<void> initialize({
    bool isDevelopment = false,
    bool isBatteryOptimized = false,
  }) async {
    final getIt = GetIt.instance;

    if (isBatteryOptimized) {
      await OfflineModuleConfig.configureBatteryOptimized(getIt);
    } else if (isDevelopment) {
      await OfflineModuleConfig.configureDevelopment(getIt);
    } else {
      await OfflineModuleConfig.configureProduction(getIt);
    }

    // Perform key rotation check on startup
    final encryptionService = getIt<OfflineEncryptionService>();
    if (await encryptionService.shouldRotateKeys()) {
      await encryptionService.rotateKeys();
      await encryptionService.cleanupOldKeys();
    }

    // Clean expired queue items on startup
    final queueRepository = getIt<IOfflineQueueRepository>();
    await queueRepository.cleanExpiredItems();
  }

  static Future<void> dispose() async {
    final getIt = GetIt.instance;
    await getIt.disposeOfflineModule();
  }
}