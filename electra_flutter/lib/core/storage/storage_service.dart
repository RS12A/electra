import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:isar/isar.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart';

import '../../shared/utils/logger.dart';

/// Storage service for managing local data with encryption
///
/// Provides secure storage for sensitive data using flutter_secure_storage,
/// encrypted local cache using Hive, and fast offline database using Isar.
@singleton
class StorageService {
  late final Isar _isar;
  late final Box _cacheBox;
  late final Encrypter _encrypter;
  final FlutterSecureStorage _secureStorage;

  bool _initialized = false;

  StorageService(this._secureStorage);

  /// Initialize storage systems
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Get application directory
      final dir = await getApplicationDocumentsDirectory();

      // Initialize encryption
      await _initializeEncryption();

      // Initialize Isar database
      await _initializeIsar(dir);

      // Initialize Hive cache
      await _initializeHive(dir);

      _initialized = true;
      AppLogger.info('Storage service initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize storage service', e, stackTrace);
      rethrow;
    }
  }

  /// Initialize encryption for sensitive data
  Future<void> _initializeEncryption() async {
    // Try to get existing key
    String? keyString = await _secureStorage.read(key: 'encryption_key');

    if (keyString == null) {
      // Generate new key
      final key = Key.fromSecureRandom(32);
      keyString = key.base64;
      await _secureStorage.write(key: 'encryption_key', value: keyString);
      AppLogger.info('Generated new encryption key');
    }

    final key = Key.fromBase64(keyString);
    _encrypter = Encrypter(AES(key));
  }

  /// Initialize Isar database
  Future<void> _initializeIsar(Directory dir) async {
    _isar = await Isar.open(
      [
        // Add schema collections here when created
        // UserSchema,
        // ElectionSchema,
        // VoteSchema,
        // etc.
      ],
      directory: dir.path,
      name: 'electra_db',
    );

    AppLogger.info('Isar database initialized');
  }

  /// Initialize Hive cache
  Future<void> _initializeHive(Directory dir) async {
    Hive.init(dir.path);
    _cacheBox = await Hive.openBox(
      'cache',
      encryptionCipher: HiveAesCipher(_getHiveKey()),
    );

    AppLogger.info('Hive cache initialized');
  }

  /// Get Hive encryption key
  Uint8List _getHiveKey() {
    // Use first 32 bytes of our main encryption key for Hive
    final keyString = _secureStorage.read(key: 'encryption_key');
    return Uint8List.fromList(keyString.toString().codeUnits.take(32).toList());
  }

  /// Check if storage is initialized
  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'Storage service not initialized. Call initialize() first.',
      );
    }
  }

  // SECURE STORAGE METHODS (for sensitive data like tokens)

  /// Store sensitive data securely
  Future<void> storeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
    AppLogger.debug('Stored secure data: $key');
  }

  /// Read sensitive data securely
  Future<String?> readSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Delete secure data
  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
    AppLogger.debug('Deleted secure data: $key');
  }

  /// Clear all secure data
  Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
    AppLogger.info('Cleared all secure storage');
  }

  // CACHE METHODS (for temporary data with encryption)

  /// Store data in encrypted cache
  Future<void> cacheData<T>(String key, T data) async {
    _checkInitialized();

    try {
      // Encrypt sensitive data before caching
      if (data is String && _isSensitiveKey(key)) {
        final encrypted = _encrypter.encrypt(data);
        await _cacheBox.put(key, encrypted.base64);
      } else {
        await _cacheBox.put(key, data);
      }

      AppLogger.debug('Cached data: $key');
    } catch (e) {
      AppLogger.error('Failed to cache data: $key', e);
    }
  }

  /// Read data from encrypted cache
  Future<T?> getCachedData<T>(String key) async {
    _checkInitialized();

    try {
      final data = _cacheBox.get(key);
      if (data == null) return null;

      // Decrypt sensitive data
      if (data is String && _isSensitiveKey(key)) {
        final encrypted = Encrypted.fromBase64(data);
        final decrypted = _encrypter.decrypt(encrypted);
        return decrypted as T;
      }

      return data as T;
    } catch (e) {
      AppLogger.error('Failed to get cached data: $key', e);
      return null;
    }
  }

  /// Delete cached data
  Future<void> deleteCachedData(String key) async {
    _checkInitialized();
    await _cacheBox.delete(key);
    AppLogger.debug('Deleted cached data: $key');
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    _checkInitialized();
    await _cacheBox.clear();
    AppLogger.info('Cleared all cache');
  }

  /// Check if a key contains sensitive data
  bool _isSensitiveKey(String key) {
    const sensitiveKeys = [
      'user_data',
      'ballot_token',
      'vote_data',
      'biometric_data',
    ];
    return sensitiveKeys.any((k) => key.toLowerCase().contains(k));
  }

  // ISAR DATABASE METHODS (for structured offline data)

  /// Get Isar database instance
  Isar get database {
    _checkInitialized();
    return _isar;
  }

  /// Store data in Isar database
  Future<void> storeInDatabase<T>(T object) async {
    _checkInitialized();

    try {
      await _isar.writeTxn(() async {
        await _isar.collection<T>().put(object);
      });

      AppLogger.debug('Stored object in database: ${T.toString()}');
    } catch (e) {
      AppLogger.error('Failed to store in database', e);
      rethrow;
    }
  }

  /// Store multiple objects in Isar database
  Future<void> storeAllInDatabase<T>(List<T> objects) async {
    _checkInitialized();

    try {
      await _isar.writeTxn(() async {
        await _isar.collection<T>().putAll(objects);
      });

      AppLogger.debug(
        'Stored ${objects.length} objects in database: ${T.toString()}',
      );
    } catch (e) {
      AppLogger.error('Failed to store all in database', e);
      rethrow;
    }
  }

  /// Query data from Isar database
  Future<List<T>> queryFromDatabase<T>() async {
    _checkInitialized();

    try {
      return await _isar.collection<T>().where().findAll();
    } catch (e) {
      AppLogger.error('Failed to query from database', e);
      return [];
    }
  }

  /// Delete from Isar database
  Future<bool> deleteFromDatabase<T>(Id id) async {
    _checkInitialized();

    try {
      return await _isar.writeTxn(() async {
        return await _isar.collection<T>().delete(id);
      });
    } catch (e) {
      AppLogger.error('Failed to delete from database', e);
      return false;
    }
  }

  /// Clear all database data
  Future<void> clearDatabase() async {
    _checkInitialized();

    try {
      await _isar.writeTxn(() async {
        await _isar.clear();
      });

      AppLogger.info('Cleared all database data');
    } catch (e) {
      AppLogger.error('Failed to clear database', e);
    }
  }

  // OFFLINE QUEUE METHODS (for votes and other critical data)

  /// Queue data for offline sync
  Future<void> queueForSync(String type, Map<String, dynamic> data) async {
    final queueData = {
      'type': type,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
    };

    await cacheData(
      'offline_queue_${DateTime.now().millisecondsSinceEpoch}',
      queueData,
    );
    AppLogger.info('Queued data for sync: $type');
  }

  /// Get all queued items for sync
  Future<Map<String, dynamic>> getQueuedItems() async {
    _checkInitialized();

    final Map<String, dynamic> queuedItems = {};

    for (final key in _cacheBox.keys) {
      if (key.toString().startsWith('offline_queue_')) {
        final data = await getCachedData(key.toString());
        if (data != null) {
          queuedItems[key.toString()] = data;
        }
      }
    }

    return queuedItems;
  }

  /// Remove item from sync queue
  Future<void> removeFromQueue(String queueKey) async {
    await deleteCachedData(queueKey);
    AppLogger.debug('Removed from queue: $queueKey');
  }

  /// Clean up storage (remove old cached data)
  Future<void> cleanup() async {
    _checkInitialized();

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final maxAge = 7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds

      final keysToDelete = <String>[];

      for (final key in _cacheBox.keys) {
        final keyStr = key.toString();
        if (keyStr.contains('_')) {
          final parts = keyStr.split('_');
          if (parts.length >= 2) {
            final timestamp = int.tryParse(parts.last);
            if (timestamp != null && (now - timestamp) > maxAge) {
              keysToDelete.add(keyStr);
            }
          }
        }
      }

      for (final key in keysToDelete) {
        await deleteCachedData(key);
      }

      AppLogger.info('Cleaned up ${keysToDelete.length} old cache entries');
    } catch (e) {
      AppLogger.error('Failed to cleanup storage', e);
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    _checkInitialized();

    return {
      'cache_entries': _cacheBox.length,
      'database_collections': _isar.schemas.length,
      'cache_size_bytes': _cacheBox.length * 1024, // Approximate
      'initialized': _initialized,
    };
  }
}
