import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Base class for all use cases
///
/// Defines the contract for use case implementations with type safety
/// for parameters and return types.
abstract class UseCase<Type, Params> {
  /// Execute the use case with given parameters
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case with no parameters
abstract class NoParamsUseCase<Type> {
  /// Execute the use case without parameters
  Future<Either<Failure, Type>> call();
}

/// Parameters class for use cases that don't need parameters
class NoParams {
  const NoParams();
}

/// Generic parameters class for simple string parameters
class StringParams {
  const StringParams(this.value);
  
  final String value;
}

/// Generic parameters class for pagination
class PaginationParams {
  const PaginationParams({
    this.page = 1,
    this.limit = 20,
    this.query,
  });
  
  final int page;
  final int limit;
  final String? query;
}