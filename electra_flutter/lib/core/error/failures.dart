import 'package:equatable/equatable.dart';

/// Abstract base class for all failures in the application
///
/// Failures represent errors that can occur during business logic execution.
/// They are used with Either<Failure, Success> for functional error handling.
abstract class Failure extends Equatable {
  const Failure([this.message, this.code]);
  
  /// Human-readable error message
  final String? message;
  
  /// Error code for programmatic handling
  final String? code;
  
  @override
  List<Object?> get props => [message, code];
}

/// Server-side failures
class ServerFailure extends Failure {
  const ServerFailure([super.message, super.code]);
  
  @override
  String toString() => 'ServerFailure: ${message ?? 'Unknown server error'}';
}

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure([super.message, super.code]);
  
  @override
  String toString() => 'NetworkFailure: ${message ?? 'Network connection failed'}';
}

/// Authentication/Authorization failures
class AuthFailure extends Failure {
  const AuthFailure([super.message, super.code]);
  
  @override
  String toString() => 'AuthFailure: ${message ?? 'Authentication failed'}';
}

/// Local storage failures
class CacheFailure extends Failure {
  const CacheFailure([super.message, super.code]);
  
  @override
  String toString() => 'CacheFailure: ${message ?? 'Local storage failed'}';
}

/// Input validation failures
class ValidationFailure extends Failure {
  const ValidationFailure([super.message, super.code]);
  
  @override
  String toString() => 'ValidationFailure: ${message ?? 'Validation failed'}';
}

/// Encryption/Decryption failures
class CryptographyFailure extends Failure {
  const CryptographyFailure([super.message, super.code]);
  
  @override
  String toString() => 'CryptographyFailure: ${message ?? 'Cryptography operation failed'}';
}

/// Vote-specific failures
class VoteFailure extends Failure {
  const VoteFailure([super.message, super.code]);
  
  @override
  String toString() => 'VoteFailure: ${message ?? 'Vote operation failed'}';
}

/// Election-specific failures
class ElectionFailure extends Failure {
  const ElectionFailure([super.message, super.code]);
  
  @override
  String toString() => 'ElectionFailure: ${message ?? 'Election operation failed'}';
}

/// Permission/Access failures
class PermissionFailure extends Failure {
  const PermissionFailure([super.message, super.code]);
  
  @override
  String toString() => 'PermissionFailure: ${message ?? 'Permission denied'}';
}

/// Device/Platform specific failures
class PlatformFailure extends Failure {
  const PlatformFailure([super.message, super.code]);
  
  @override
  String toString() => 'PlatformFailure: ${message ?? 'Platform operation failed'}';
}

/// Timeout failures
class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message, super.code]);
  
  @override
  String toString() => 'TimeoutFailure: ${message ?? 'Operation timed out'}';
}

/// Unknown/Unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure([super.message, super.code]);
  
  @override
  String toString() => 'UnknownFailure: ${message ?? 'Unknown error occurred'}';
}