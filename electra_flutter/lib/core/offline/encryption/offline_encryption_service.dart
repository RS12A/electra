import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../error/failures.dart';
import '../../services/logger_service.dart';

/// Service for encrypting/decrypting offline queue data using AES-256-GCM
///
/// Provides secure storage for sensitive offline operations with
/// key rotation, integrity verification, and secure deletion.
@singleton
class OfflineEncryptionService {
  final FlutterSecureStorage _secureStorage;
  final LoggerService _logger;
  
  // Cache for encryption components to avoid repeated key derivation
  Encrypter? _encrypter;
  IV? _currentIV;
  String? _currentKeyId;
  
  // Storage keys
  static const String _masterKeyKey = 'offline_master_key';
  static const String _keyRotationKey = 'offline_key_rotation';
  static const String _keyVersionKey = 'offline_key_version';
  
  OfflineEncryptionService(this._secureStorage, this._logger);

  /// Initialize encryption service and ensure master key exists
  Future<void> initialize() async {
    try {
      await _ensureMasterKeyExists();
      await _loadEncryptionComponents();
      _logger.info('OfflineEncryptionService initialized successfully');
    } catch (e) {
      _logger.error('Failed to initialize OfflineEncryptionService', e);
      rethrow;
    }
  }

  /// Encrypt sensitive data for offline storage
  ///
  /// Returns encrypted data with IV and integrity hash for verification
  Future<EncryptedData> encryptData(Map<String, dynamic> data) async {
    try {
      if (_encrypter == null) {
        await _loadEncryptionComponents();
      }

      // Convert data to JSON and get bytes
      final jsonString = json.encode(data);
      final dataBytes = utf8.encode(jsonString);
      
      // Generate random IV for this encryption
      final iv = IV.fromSecureRandom(16);
      
      // Encrypt the data
      final encrypted = _encrypter!.encryptBytes(dataBytes, iv: iv);
      
      // Create integrity hash
      final payloadHash = _createPayloadHash(dataBytes);
      
      // Create timestamp for freshness
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      return EncryptedData(
        encryptedPayload: encrypted.base64,
        iv: iv.base64,
        payloadHash: payloadHash,
        keyId: _currentKeyId!,
        timestamp: timestamp,
      );
    } catch (e) {
      _logger.error('Failed to encrypt offline data', e);
      throw const SecurityFailure(message: 'Failed to encrypt offline data');
    }
  }

  /// Decrypt data from offline storage
  ///
  /// Verifies integrity and authenticity before returning decrypted data
  Future<Map<String, dynamic>> decryptData(EncryptedData encryptedData) async {
    try {
      // Check if we need to use a different key version
      if (encryptedData.keyId != _currentKeyId) {
        await _loadEncryptionComponentsForKey(encryptedData.keyId);
      }

      // Decrypt the data
      final iv = IV.fromBase64(encryptedData.iv);
      final encrypted = Encrypted.fromBase64(encryptedData.encryptedPayload);
      final decryptedBytes = _encrypter!.decryptBytes(encrypted, iv: iv);
      
      // Verify integrity
      final computedHash = _createPayloadHash(decryptedBytes);
      if (computedHash != encryptedData.payloadHash) {
        throw const SecurityFailure(message: 'Data integrity verification failed');
      }
      
      // Convert back to data
      final jsonString = utf8.decode(decryptedBytes);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      
      return data;
    } catch (e) {
      _logger.error('Failed to decrypt offline data', e);
      if (e is SecurityFailure) rethrow;
      throw const SecurityFailure(message: 'Failed to decrypt offline data');
    }
  }

  /// Generate secure random IV for encryption
  String generateSecureIV() {
    final iv = IV.fromSecureRandom(16);
    return iv.base64;
  }

  /// Create SHA-256 hash of payload for integrity verification
  String createPayloadHash(Map<String, dynamic> data) {
    try {
      final jsonString = json.encode(data);
      final dataBytes = utf8.encode(jsonString);
      return _createPayloadHash(dataBytes);
    } catch (e) {
      _logger.error('Failed to create payload hash', e);
      throw const SecurityFailure(message: 'Failed to create payload hash');
    }
  }

  /// Rotate encryption keys for enhanced security
  Future<void> rotateKeys() async {
    try {
      _logger.info('Starting encryption key rotation');
      
      // Generate new master key
      final newMasterKey = _generateSecureKey();
      final newKeyId = _generateKeyId();
      
      // Store new key with version increment
      final currentVersion = await _getCurrentKeyVersion();
      final newVersion = currentVersion + 1;
      
      await _secureStorage.write(
        key: '${_masterKeyKey}_$newKeyId',
        value: newMasterKey,
      );
      
      await _secureStorage.write(
        key: _keyVersionKey,
        value: newVersion.toString(),
      );
      
      await _secureStorage.write(
        key: _keyRotationKey,
        value: DateTime.now().toIso8601String(),
      );
      
      // Update current encryption components
      _currentKeyId = newKeyId;
      await _loadEncryptionComponents();
      
      _logger.info('Encryption key rotation completed successfully');
    } catch (e) {
      _logger.error('Failed to rotate encryption keys', e);
      throw const SecurityFailure(message: 'Failed to rotate encryption keys');
    }
  }

  /// Clean up old encryption keys after successful rotation
  Future<void> cleanupOldKeys() async {
    try {
      final currentVersion = await _getCurrentKeyVersion();
      
      // Keep only the current and previous key for migration
      for (int i = 0; i < currentVersion - 1; i++) {
        try {
          await _secureStorage.delete(key: '${_masterKeyKey}_v$i');
        } catch (e) {
          // Key might not exist, continue cleanup
          continue;
        }
      }
      
      _logger.info('Old encryption keys cleaned up successfully');
    } catch (e) {
      _logger.error('Failed to cleanup old encryption keys', e);
      // Non-critical error, don't rethrow
    }
  }

  /// Check if encryption keys need rotation (monthly rotation)
  Future<bool> shouldRotateKeys() async {
    try {
      final lastRotationString = await _secureStorage.read(key: _keyRotationKey);
      if (lastRotationString == null) return true;
      
      final lastRotation = DateTime.parse(lastRotationString);
      final rotationInterval = const Duration(days: 30);
      
      return DateTime.now().difference(lastRotation) > rotationInterval;
    } catch (e) {
      _logger.error('Failed to check key rotation status', e);
      return true; // Err on the side of caution
    }
  }

  /// Securely delete all encryption keys and data
  Future<void> secureDeleteKeys() async {
    try {
      // Delete all key versions
      final currentVersion = await _getCurrentKeyVersion();
      for (int i = 0; i <= currentVersion; i++) {
        await _secureStorage.delete(key: '${_masterKeyKey}_v$i');
      }
      
      await _secureStorage.delete(key: _masterKeyKey);
      await _secureStorage.delete(key: _keyRotationKey);
      await _secureStorage.delete(key: _keyVersionKey);
      
      // Clear cached components
      _encrypter = null;
      _currentIV = null;
      _currentKeyId = null;
      
      _logger.info('All encryption keys securely deleted');
    } catch (e) {
      _logger.error('Failed to securely delete encryption keys', e);
      throw const SecurityFailure(message: 'Failed to securely delete keys');
    }
  }

  // Private helper methods

  Future<void> _ensureMasterKeyExists() async {
    final existingKey = await _secureStorage.read(key: _masterKeyKey);
    if (existingKey == null) {
      final masterKey = _generateSecureKey();
      final keyId = _generateKeyId();
      
      await _secureStorage.write(key: _masterKeyKey, value: masterKey);
      await _secureStorage.write(key: _keyVersionKey, value: '1');
      await _secureStorage.write(
        key: _keyRotationKey,
        value: DateTime.now().toIso8601String(),
      );
      
      _currentKeyId = keyId;
    }
  }

  Future<void> _loadEncryptionComponents() async {
    final masterKey = await _secureStorage.read(key: _masterKeyKey);
    if (masterKey == null) {
      throw const SecurityFailure(message: 'Master encryption key not found');
    }

    final key = Key.fromBase64(masterKey);
    _encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    _currentKeyId ??= 'default';
  }

  Future<void> _loadEncryptionComponentsForKey(String keyId) async {
    final masterKey = await _secureStorage.read(key: '${_masterKeyKey}_$keyId');
    if (masterKey == null) {
      throw const SecurityFailure(message: 'Encryption key not found for ID: $keyId');
    }

    final key = Key.fromBase64(masterKey);
    _encrypter = Encrypter(AES(key, mode: AESMode.gcm));
  }

  String _generateSecureKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(keyBytes);
  }

  String _generateKeyId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(bytes).substring(0, 8);
  }

  String _createPayloadHash(Uint8List dataBytes) {
    final digest = sha256.convert(dataBytes);
    return digest.toString();
  }

  Future<int> _getCurrentKeyVersion() async {
    final versionString = await _secureStorage.read(key: _keyVersionKey);
    return int.tryParse(versionString ?? '1') ?? 1;
  }
}

/// Encrypted data container with metadata
class EncryptedData {
  final String encryptedPayload;
  final String iv;
  final String payloadHash;
  final String keyId;
  final int timestamp;

  const EncryptedData({
    required this.encryptedPayload,
    required this.iv,
    required this.payloadHash,
    required this.keyId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'encryptedPayload': encryptedPayload,
    'iv': iv,
    'payloadHash': payloadHash,
    'keyId': keyId,
    'timestamp': timestamp,
  };

  factory EncryptedData.fromJson(Map<String, dynamic> json) => EncryptedData(
    encryptedPayload: json['encryptedPayload'] as String,
    iv: json['iv'] as String,
    payloadHash: json['payloadHash'] as String,
    keyId: json['keyId'] as String,
    timestamp: json['timestamp'] as int,
  );
}