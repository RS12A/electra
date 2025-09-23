import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_election.dart';
import '../repositories/admin_dashboard_repository.dart';

/// Use case for getting all elections
class GetElections extends UseCase<List<AdminElection>, GetElectionsParams> {
  final AdminDashboardRepository repository;

  GetElections(this.repository);

  @override
  Future<Either<Failure, List<AdminElection>>> call(GetElectionsParams params) {
    return repository.getElections(
      status: params.status,
      searchQuery: params.searchQuery,
      page: params.page,
      limit: params.limit,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    );
  }
}

/// Use case for getting election by ID
class GetElectionById extends UseCase<AdminElection, StringParams> {
  final AdminDashboardRepository repository;

  GetElectionById(this.repository);

  @override
  Future<Either<Failure, AdminElection>>> call(StringParams params) {
    return repository.getElectionById(params.value);
  }
}

/// Use case for creating an election
class CreateElection extends UseCase<AdminElection, CreateElectionParams> {
  final AdminDashboardRepository repository;

  CreateElection(this.repository);

  @override
  Future<Either<Failure, AdminElection>>> call(CreateElectionParams params) {
    return repository.createElection(params.election);
  }
}

/// Use case for updating an election
class UpdateElection extends UseCase<AdminElection, UpdateElectionParams> {
  final AdminDashboardRepository repository;

  UpdateElection(this.repository);

  @override
  Future<Either<Failure, AdminElection>>> call(UpdateElectionParams params) {
    return repository.updateElection(params.election);
  }
}

/// Use case for deleting an election
class DeleteElection extends UseCase<void, StringParams> {
  final AdminDashboardRepository repository;

  DeleteElection(this.repository);

  @override
  Future<Either<Failure, void>> call(StringParams params) {
    return repository.deleteElection(params.value);
  }
}

/// Use case for activating an election
class ActivateElection extends UseCase<AdminElection, StringParams> {
  final AdminDashboardRepository repository;

  ActivateElection(this.repository);

  @override
  Future<Either<Failure, AdminElection>>> call(StringParams params) {
    return repository.activateElection(params.value);
  }
}

/// Use case for closing an election
class CloseElection extends UseCase<AdminElection, StringParams> {
  final AdminDashboardRepository repository;

  CloseElection(this.repository);

  @override
  Future<Either<Failure, AdminElection>>> call(StringParams params) {
    return repository.closeElection(params.value);
  }
}

/// Use case for suspending an election
class SuspendElection extends UseCase<AdminElection, StringParams> {
  final AdminDashboardRepository repository;

  SuspendElection(this.repository);

  @override
  Future<Either<Failure, AdminElection>>> call(StringParams params) {
    return repository.suspendElection(params.value);
  }
}

/// Use case for getting election results
class GetElectionResults extends UseCase<Map<String, dynamic>, StringParams> {
  final AdminDashboardRepository repository;

  GetElectionResults(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(StringParams params) {
    return repository.getElectionResults(params.value);
  }
}

/// Use case for publishing election results
class PublishResults extends UseCase<void, StringParams> {
  final AdminDashboardRepository repository;

  PublishResults(this.repository);

  @override
  Future<Either<Failure, void>> call(StringParams params) {
    return repository.publishResults(params.value);
  }
}

/// Parameters for GetElections use case
class GetElectionsParams extends Equatable {
  final ElectionStatus? status;
  final String? searchQuery;
  final int page;
  final int limit;
  final String sortBy;
  final String sortOrder;

  const GetElectionsParams({
    this.status,
    this.searchQuery,
    this.page = 1,
    this.limit = 20,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });

  @override
  List<Object?> get props => [
        status,
        searchQuery,
        page,
        limit,
        sortBy,
        sortOrder,
      ];
}

/// Parameters for CreateElection use case
class CreateElectionParams extends Equatable {
  final AdminElection election;

  const CreateElectionParams({
    required this.election,
  });

  @override
  List<Object?> get props => [election];
}

/// Parameters for UpdateElection use case
class UpdateElectionParams extends Equatable {
  final AdminElection election;

  const UpdateElectionParams({
    required this.election,
  });

  @override
  List<Object?> get props => [election];
}

/// Generic string parameter class
class StringParams extends Equatable {
  final String value;

  const StringParams(this.value);

  @override
  List<Object?> get props => [value];
}