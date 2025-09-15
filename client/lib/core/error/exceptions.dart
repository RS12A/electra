class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ServerException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() => 'ServerException: $message (Code: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({required this.message});

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'AuthException: $message';
}

class ValidationException implements Exception {
  final String message;
  final String? code;

  const ValidationException({
    required this.message,
    this.code,
  });

  @override
  String toString() => 'ValidationException: $message';
}