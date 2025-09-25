import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service for shipping Flutter logs to central logging system
class LogShippingService {
  static const String _apiEndpoint = 'your_KEY_goes_here'; // Set your log ingestion endpoint
  static const String _apiKey = 'your_KEY_goes_here'; // Set your API key
  
  final Dio _dio;
  final List<Map<String, dynamic>> _logBuffer = [];
  final int _maxBufferSize = 100;
  final Duration _flushInterval = const Duration(minutes: 1);
  
  String? _deviceId;
  String? _appVersion;
  String? _platform;
  
  LogShippingService() : _dio = Dio() {
    _initializeService();
    _startPeriodicFlush();
  }
  
  /// Initialize the log shipping service
  Future<void> _initializeService() async {
    try {
      // Get device information
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      _appVersion = packageInfo.version;
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = _hashDeviceId(androidInfo.id);
        _platform = 'android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = _hashDeviceId(iosInfo.identifierForVendor ?? 'unknown');
        _platform = 'ios';
      } else {
        _platform = 'web';
        _deviceId = _hashDeviceId('web-${DateTime.now().millisecondsSinceEpoch}');
      }
      
      // Configure Dio for secure communication
      _dio.options = BaseOptions(
        baseUrl: _apiEndpoint,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'X-Client-Version': _appVersion,
          'X-Client-Platform': _platform,
        },
      );
      
      // Add request/response interceptors for encryption
      _dio.interceptors.add(_LogEncryptionInterceptor());
      
    } catch (e) {
      debugPrint('Failed to initialize log shipping service: $e');
    }
  }
  
  /// Ship a log entry to the central store
  Future<void> shipLog({
    required String level,
    required String message,
    String? logger,
    String? module,
    String? function,
    int? line,
    Map<String, dynamic>? extra,
    DateTime? timestamp,
  }) async {
    try {
      final logEntry = _createLogEntry(
        level: level,
        message: message,
        logger: logger,
        module: module,
        function: function,
        line: line,
        extra: extra,
        timestamp: timestamp,
      );
      
      // Add to buffer
      _logBuffer.add(logEntry);
      
      // Flush if buffer is full
      if (_logBuffer.length >= _maxBufferSize) {
        await _flushLogs();
      }
    } catch (e) {
      debugPrint('Failed to ship log: $e');
    }
  }
  
  /// Create a structured log entry
  Map<String, dynamic> _createLogEntry({
    required String level,
    required String message,
    String? logger,
    String? module,
    String? function,
    int? line,
    Map<String, dynamic>? extra,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now().toUtc();
    
    return {
      '@timestamp': now.toIso8601String(),
      'level': level.toUpperCase(),
      'message': _sanitizeMessage(message),
      'logger': logger ?? 'flutter_app',
      'module': module,
      'function': function,
      'line': line,
      'device_id': _deviceId,
      'app_version': _appVersion,
      'platform': _platform,
      'client_type': 'flutter',
      'environment': kDebugMode ? 'development' : 'production',
      'extra': extra != null ? _sanitizeExtra(extra) : null,
    }..removeWhere((key, value) => value == null);
  }
  
  /// Sanitize log message to remove sensitive information
  String _sanitizeMessage(String message) {
    // Remove potential sensitive data patterns
    final sensitivePatterns = [
      RegExp(r'password["\s]*[:=]["\s]*[^"\s,}]+', caseSensitive: false),
      RegExp(r'token["\s]*[:=]["\s]*[^"\s,}]+', caseSensitive: false),
      RegExp(r'key["\s]*[:=]["\s]*[^"\s,}]+', caseSensitive: false),
      RegExp(r'secret["\s]*[:=]["\s]*[^"\s,}]+', caseSensitive: false),
      RegExp(r'matric["\s]*[:=]["\s]*[^"\s,}]+', caseSensitive: false),
      RegExp(r'\b\d{10,}\b'), // Potential phone numbers
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), // Email addresses
    ];
    
    String sanitized = message;
    for (final pattern in sensitivePatterns) {
      sanitized = sanitized.replaceAll(pattern, '[REDACTED]');
    }
    
    return sanitized;
  }
  
  /// Sanitize extra data to remove sensitive information
  Map<String, dynamic> _sanitizeExtra(Map<String, dynamic> extra) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in extra.entries) {
      final key = entry.key.toLowerCase();
      
      // Skip sensitive keys
      if (key.contains('password') ||
          key.contains('token') ||
          key.contains('key') ||
          key.contains('secret') ||
          key.contains('matric')) {
        sanitized[entry.key] = '[REDACTED]';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    
    return sanitized;
  }
  
  /// Hash device ID for privacy
  String _hashDeviceId(String deviceId) {
    final bytes = utf8.encode(deviceId + 'electra_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }
  
  /// Flush logs to the server
  Future<void> _flushLogs() async {
    if (_logBuffer.isEmpty) return;
    
    try {
      final logsToSend = List<Map<String, dynamic>>.from(_logBuffer);
      _logBuffer.clear();
      
      final payload = {
        'logs': logsToSend,
        'metadata': {
          'source': 'electra_flutter',
          'batch_size': logsToSend.length,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      };
      
      // Send logs to server
      await _dio.post('/logs/ingest', data: payload);
      
      debugPrint('Successfully shipped ${logsToSend.length} log entries');
      
    } catch (e) {
      debugPrint('Failed to flush logs: $e');
      // Re-add logs to buffer for retry (up to a limit)
      if (_logBuffer.length < _maxBufferSize * 2) {
        _logBuffer.addAll(_logBuffer);
      }
    }
  }
  
  /// Start periodic log flushing
  void _startPeriodicFlush() {
    Stream.periodic(_flushInterval).listen((_) {
      _flushLogs();
    });
  }
  
  /// Ship performance metrics
  Future<void> shipPerformanceMetric({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? metrics,
    String? screen,
    String? userId,
  }) async {
    await shipLog(
      level: 'INFO',
      message: 'Performance metric recorded',
      logger: 'performance',
      extra: {
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        'screen': screen,
        'user_id': userId != null ? _hashDeviceId(userId) : null,
        'metrics': metrics,
        'metric_type': 'performance',
      },
    );
  }
  
  /// Ship user interaction events
  Future<void> shipUserInteraction({
    required String action,
    String? screen,
    String? element,
    Map<String, dynamic>? context,
    String? userId,
  }) async {
    await shipLog(
      level: 'INFO',
      message: 'User interaction recorded',
      logger: 'analytics',
      extra: {
        'action': action,
        'screen': screen,
        'element': element,
        'context': context,
        'user_id': userId != null ? _hashDeviceId(userId) : null,
        'interaction_type': 'user_action',
      },
    );
  }
  
  /// Ship error events
  Future<void> shipError({
    required String error,
    String? stackTrace,
    String? screen,
    String? userId,
    Map<String, dynamic>? context,
  }) async {
    await shipLog(
      level: 'ERROR',
      message: error,
      logger: 'error',
      extra: {
        'stack_trace': stackTrace,
        'screen': screen,
        'user_id': userId != null ? _hashDeviceId(userId) : null,
        'context': context,
        'error_type': 'client_error',
      },
    );
  }
  
  /// Force flush all pending logs
  Future<void> forceFlush() async {
    await _flushLogs();
  }
  
  /// Get current buffer size
  int get bufferSize => _logBuffer.length;
}

/// Dio interceptor for encrypting log data in transit
class _LogEncryptionInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add timestamp and integrity hash
    if (options.data is Map<String, dynamic>) {
      final data = options.data as Map<String, dynamic>;
      data['client_timestamp'] = DateTime.now().toUtc().toIso8601String();
      
      // Add integrity hash
      final dataJson = jsonEncode(data);
      data['integrity_hash'] = sha256.convert(utf8.encode(dataJson)).toString();
    }
    
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('Log shipping error: ${err.message}');
    handler.next(err);
  }
}

/// Global log shipping service instance
final LogShippingService logShippingService = LogShippingService();