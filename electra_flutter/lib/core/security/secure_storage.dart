/// Production-grade secure storage implementation for sensitive data
/// 
/// This class provides encrypted storage for sensitive information like
/// authentication tokens, voting data, and user credentials.
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class SecureStorage {
  static const String _keyPrefix = 'electra_';
  static const String _encryptionKeyName = '${_keyPrefix}encryption_key';
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeyChainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
    lOptions: LinuxOptions(
      useSessionKeyring: true,
    ),
    wOptions: WindowsOptions(
      useBackwardCompatibility: false,
    ),
  );

  static Encrypter? _encrypter;
  static late Key _key;

  /// Initialize secure storage with encryption
  static Future<void> initialize() async {
    try {
      await _initializeEncryption();
      print('✅ Secure storage initialized successfully');
    } catch (error, stackTrace) {
      print('❌ Failed to initialize secure storage: $error');
      rethrow;
    }
  }

  /// Initialize encryption key
  static Future<void> _initializeEncryption() async {
    String? keyString = await _secureStorage.read(key: _encryptionKeyName);
    
    if (keyString == null) {
      // Generate new encryption key
      _key = Key.fromSecureRandom(32); // 256-bit key
      await _secureStorage.write(
        key: _encryptionKeyName, 
        value: _key.base64,
      );
      print('🔑 Generated new encryption key');
    } else {
      _key = Key.fromBase64(keyString);
      print('🔑 Loaded existing encryption key');
    }
    
    _encrypter = Encrypter(AES(_key, mode: AESMode.gcm));
  }

  /// Store encrypted data
  static Future<void> store(String key, dynamic value) async {
    try {
      if (_encrypter == null) {
        await initialize();
      }

      final jsonString = json.encode(value);
      final iv = IV.fromSecureRandom(16); // 128-bit IV
      final encrypted = _encrypter!.encrypt(jsonString, iv: iv);
      
      // Store both encrypted data and IV
      final storageData = {
        'data': encrypted.base64,
        'iv': iv.base64,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _secureStorage.write(
        key: '$_keyPrefix$key',
        value: json.encode(storageData),
      );

      print('🔐 Stored encrypted data for key: $key');
    } catch (error, stackTrace) {
      print('❌ Failed to store secure data: $error');
      rethrow;
    }
  }

  /// Retrieve and decrypt data
  static Future<T?> retrieve<T>(String key) async {
    try {
      if (_encrypter == null) {
        await initialize();
      }

      final storageString = await _secureStorage.read(key: '$_keyPrefix$key');
      if (storageString == null) {
        return null;
      }

      final storageData = json.decode(storageString);
      final encrypted = Encrypted.fromBase64(storageData['data']);
      final iv = IV.fromBase64(storageData['iv']);

      final decrypted = _encrypter!.decrypt(encrypted, iv: iv);
      final value = json.decode(decrypted);

      print('🔓 Retrieved encrypted data for key: $key');
      return value as T;
    } catch (error, stackTrace) {
      print('❌ Failed to retrieve secure data: $error');
      return null;
    }
  }

  /// Check if key exists
  static Future<bool> containsKey(String key) async {
    final value = await _secureStorage.read(key: '$_keyPrefix$key');
    return value != null;
  }

  /// Delete specific key
  static Future<void> delete(String key) async {
    try {
      await _secureStorage.delete(key: '$_keyPrefix$key');
      print('🗑️ Deleted secure data for key: $key');
    } catch (error, stackTrace) {
      print('❌ Failed to delete secure data: $error');
      rethrow;
    }
  }

  /// Clear all app data (security measure)
  static Future<void> clearAll() async {
    try {
      final allKeys = await _secureStorage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith(_keyPrefix)) {
          await _secureStorage.delete(key: key);
        }
      }
      print('🧹 Cleared all secure storage data');
    } catch (error, stackTrace) {
      print('❌ Failed to clear secure storage: $error');
      rethrow;
    }
  }

  /// Store authentication tokens securely
  static Future<void> storeAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await store('auth_tokens', {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'stored_at': DateTime.now().toIso8601String(),
    });
  }

  /// Retrieve authentication tokens
  static Future<Map<String, String>?> getAuthTokens() async {
    final tokens = await retrieve<Map<String, dynamic>>('auth_tokens');
    if (tokens == null) return null;

    return {
      'access_token': tokens['access_token'] as String,
      'refresh_token': tokens['refresh_token'] as String,
    };
  }

  /// Store voting data temporarily (offline support)
  static Future<void> storeOfflineVote({
    required String electionId,
    required Map<String, dynamic> voteData,
  }) async {
    final voteId = _generateVoteId();
    await store('offline_vote_$voteId', {
      'election_id': electionId,
      'vote_data': voteData,
      'created_at': DateTime.now().toIso8601String(),
      'vote_id': voteId,
    });
  }

  /// Get all offline votes
  static Future<List<Map<String, dynamic>>> getOfflineVotes() async {
    final allKeys = await _secureStorage.readAll();
    final offlineVotes = <Map<String, dynamic>>[];

    for (final key in allKeys.keys) {
      if (key.startsWith('${_keyPrefix}offline_vote_')) {
        final voteData = await retrieve<Map<String, dynamic>>(
          key.substring(_keyPrefix.length),
        );
        if (voteData != null) {
          offlineVotes.add(voteData);
        }
      }
    }

    return offlineVotes;
  }

  /// Clear offline votes after successful sync
  static Future<void> clearOfflineVotes() async {
    final allKeys = await _secureStorage.readAll();
    
    for (final key in allKeys.keys) {
      if (key.startsWith('${_keyPrefix}offline_vote_')) {
        await _secureStorage.delete(key: key);
      }
    }
  }

  /// Generate unique vote ID
  static String _generateVoteId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List.generate(16, (i) => timestamp >> (i % 32));
    final hash = sha256.convert(randomBytes);
    return hash.toString().substring(0, 16);
  }

  /// Validate storage integrity
  static Future<bool> validateIntegrity() async {
    try {
      // Try to read and decrypt a test value
      await store('integrity_test', 'test_value');
      final retrieved = await retrieve<String>('integrity_test');
      await delete('integrity_test');
      
      return retrieved == 'test_value';
    } catch (error) {
      print('❌ Storage integrity check failed: $error');
      return false;
    }
  }

  /// Get storage statistics for debugging
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final appKeys = allKeys.keys.where((k) => k.startsWith(_keyPrefix));
      
      return {
        'total_keys': appKeys.length,
        'auth_tokens_stored': await containsKey('auth_tokens'),
        'offline_votes_count': (await getOfflineVotes()).length,
        'last_integrity_check': DateTime.now().toIso8601String(),
      };
    } catch (error) {
      return {'error': error.toString()};
    }
  }
}