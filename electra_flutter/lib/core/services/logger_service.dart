import 'package:injectable/injectable.dart';
import '../../shared/utils/logger.dart';

/// Logger service interface for dependency injection
abstract class LoggerService {
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]);
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]);
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]);
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]);
  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]);
}

/// Implementation using AppLogger
@Singleton(as: LoggerService)
class AppLoggerService implements LoggerService {
  AppLoggerService() {
    AppLogger.initialize();
  }

  @override
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.debug(message, error, stackTrace);
  }

  @override
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.info(message, error, stackTrace);
  }

  @override
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.warning(message, error, stackTrace);
  }

  @override
  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.error(message, error, stackTrace);
  }

  @override
  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    AppLogger.fatal(message, error, stackTrace);
  }
}