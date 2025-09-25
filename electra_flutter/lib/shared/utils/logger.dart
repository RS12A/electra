import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Application logger with structured logging capabilities
///
/// Provides different log levels, structured output, and integration
/// with crash reporting services for production monitoring.
class AppLogger {
  static late Logger _logger;
  static bool _initialized = false;

  /// Initialize the logger with production configuration
  static void initialize({
    Level level = Level.info,
    bool enableConsole = true,
    bool enableFile = true,
  }) {
    if (_initialized) return;

    _logger = Logger(
      level: level,
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      output: enableConsole ? ConsoleOutput() : null,
    );

    _initialized = true;
    info('Logger initialized');
  }

  /// Log debug messages (only in debug mode)
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info messages
  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages
  static void warning(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _ensureInitialized();
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.e(message, error: error, stackTrace: stackTrace);

    // In production, send to crash reporting service
    _reportError(message, error, stackTrace);
  }

  /// Log fatal errors that crash the app
  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.f(message, error: error, stackTrace: stackTrace);

    // Always report fatal errors
    _reportError(message, error, stackTrace, isFatal: true);
  }

  /// Log network requests
  static void network(
    String method,
    String url, {
    int? statusCode,
    Duration? duration,
    dynamic error,
  }) {
    if (error != null) {
      _logger.e('🌐 $method $url - ERROR: $error');
    } else if (statusCode != null) {
      final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
      final durationText = duration != null
          ? ' (${duration.inMilliseconds}ms)'
          : '';
      _logger.i('$emoji $method $url - $statusCode$durationText');
    } else {
      _logger.d('🌐 $method $url');
    }
  }

  /// Log authentication events
  static void auth(String event, {String? userId, dynamic extra}) {
    _logger.i(
      '🔐 Auth: $event${userId != null ? ' (User: $userId)' : ''}${extra != null ? ' - $extra' : ''}',
    );
  }

  /// Log voting events (without sensitive data)
  static void vote(String event, {String? electionId, dynamic extra}) {
    _logger.i(
      '🗳️  Vote: $event${electionId != null ? ' (Election: $electionId)' : ''}${extra != null ? ' - $extra' : ''}',
    );
  }

  /// Log security events
  static void security(String event, {String? details}) {
    _logger.w('🛡️  Security: $event${details != null ? ' - $details' : ''}');

    // Security events should always be reported
    _reportSecurityEvent(event, details);
  }

  /// Log user interactions for analytics
  static void analytics(String event, Map<String, dynamic>? properties) {
    final props =
        properties?.entries.map((e) => '${e.key}=${e.value}').join(', ') ?? '';
    _logger.d('📊 Analytics: $event${props.isNotEmpty ? ' ($props)' : ''}');
  }

  /// Log performance metrics
  static void performance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? metrics,
  }) {
    final metricsText =
        metrics?.entries.map((e) => '${e.key}=${e.value}').join(', ') ?? '';
    _logger.i(
      '⚡ Performance: $operation took ${duration.inMilliseconds}ms${metricsText.isNotEmpty ? ' ($metricsText)' : ''}',
    );
  }

  /// Ensure logger is initialized
  static void _ensureInitialized() {
    if (!_initialized) {
      initialize();
    }
  }

  /// Report errors to crash reporting service (implement based on your service)
  static void _reportError(
    dynamic message,
    dynamic error,
    StackTrace? stackTrace, {
    bool isFatal = false,
  }) {
    // Integrate with Sentry for error reporting
    try {
      if (error != null) {
        Sentry.captureException(
          error,
          stackTrace: stackTrace,
          withScope: (scope) {
            scope.setLevel(isFatal ? SentryLevel.fatal : SentryLevel.error);
            scope.setTag('source', 'flutter_app');
            scope.setContext('message', {'message': message.toString()});
          },
        );
      } else {
        Sentry.captureMessage(
          message.toString(),
          level: isFatal ? SentryLevel.fatal : SentryLevel.error,
          withScope: (scope) {
            scope.setTag('source', 'flutter_app');
          },
        );
      }
    } catch (e) {
      // Fallback logging if Sentry fails
      print('Failed to report error to Sentry: $e');
    }
  }

  /// Report security events for monitoring
  static void _reportSecurityEvent(String event, String? details) {
    // TODO: Integrate with security monitoring service
    // Example:
    // SecurityMonitor.reportEvent(event, details);
  }
}

/// Custom console output for structured logging
class ConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      print(line);
    }
  }
}

/// File output for logging to local files
class FileOutput extends LogOutput {
  final String filePath;

  FileOutput(this.filePath);

  @override
  void output(OutputEvent event) {
    // TODO: Implement file logging
    // Write event.lines to file
  }
}
