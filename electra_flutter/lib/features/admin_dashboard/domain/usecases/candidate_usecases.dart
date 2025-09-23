import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_election.dart';
import '../repositories/admin_dashboard_repository.dart';

/// Use case for getting candidates
class GetCandidates extends UseCase<List<AdminCandidate>, GetCandidatesParams> {
  final AdminDashboardRepository repository;

  GetCandidates(this.repository);

  @override
  Future<Either<Failure, List<AdminCandidate>>> call(GetCandidatesParams params) {
    return repository.getCandidates(
      electionId: params.electionId,
      position: params.position,
      activeOnly: params.activeOnly,
      sortBy: params.sortBy,
    );
  }
}

/// Use case for getting candidate by ID
class GetCandidateById extends UseCase<AdminCandidate, StringParams> {
  final AdminDashboardRepository repository;

  GetCandidateById(this.repository);

  @override
  Future<Either<Failure, AdminCandidate>> call(StringParams params) {
    return repository.getCandidateById(params.value);
  }
}

/// Use case for creating a candidate
class CreateCandidate extends UseCase<AdminCandidate, CreateCandidateParams> {
  final AdminDashboardRepository repository;

  CreateCandidate(this.repository);

  @override
  Future<Either<Failure, AdminCandidate>> call(CreateCandidateParams params) {
    return repository.createCandidate(params.candidate);
  }
}

/// Use case for updating a candidate
class UpdateCandidate extends UseCase<AdminCandidate, UpdateCandidateParams> {
  final AdminDashboardRepository repository;

  UpdateCandidate(this.repository);

  @override
  Future<Either<Failure, AdminCandidate>> call(UpdateCandidateParams params) {
    return repository.updateCandidate(params.candidate);
  }
}

/// Use case for deleting a candidate
class DeleteCandidate extends UseCase<void, StringParams> {
  final AdminDashboardRepository repository;

  DeleteCandidate(this.repository);

  @override
  Future<Either<Failure, void>> call(StringParams params) {
    return repository.deleteCandidate(params.value);
  }
}

/// Use case for uploading candidate media
class UploadCandidateMedia extends UseCase<CandidateMedia, UploadCandidateMediaParams> {
  final AdminDashboardRepository repository;

  UploadCandidateMedia(this.repository);

  @override
  Future<Either<Failure, CandidateMedia>> call(UploadCandidateMediaParams params) {
    return repository.uploadCandidateMedia(
      candidateId: params.candidateId,
      filePath: params.filePath,
      mediaType: params.mediaType,
      title: params.title,
      description: params.description,
      isPrimary: params.isPrimary,
    );
  }
}

/// Use case for deleting candidate media
class DeleteCandidateMedia extends UseCase<void, StringParams> {
  final AdminDashboardRepository repository;

  DeleteCandidateMedia(this.repository);

  @override
  Future<Either<Failure, void>> call(StringParams params) {
    return repository.deleteCandidateMedia(params.value);
  }
}

/// Use case for updating candidate display order
class UpdateCandidateOrder extends UseCase<void, UpdateCandidateOrderParams> {
  final AdminDashboardRepository repository;

  UpdateCandidateOrder(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateCandidateOrderParams params) {
    return repository.updateCandidateOrder(
      electionId: params.electionId,
      position: params.position,
      candidateIds: params.candidateIds,
    );
  }
}

/// Parameters for GetCandidates use case
class GetCandidatesParams extends Equatable {
  final String electionId;
  final String? position;
  final bool activeOnly;
  final String sortBy;

  const GetCandidatesParams({
    required this.electionId,
    this.position,
    this.activeOnly = true,
    this.sortBy = 'displayOrder',
  });

  @override
  List<Object?> get props => [electionId, position, activeOnly, sortBy];
}

/// Parameters for CreateCandidate use case
class CreateCandidateParams extends Equatable {
  final AdminCandidate candidate;

  const CreateCandidateParams({
    required this.candidate,
  });

  @override
  List<Object?> get props => [candidate];
}

/// Parameters for UpdateCandidate use case
class UpdateCandidateParams extends Equatable {
  final AdminCandidate candidate;

  const UpdateCandidateParams({
    required this.candidate,
  });

  @override
  List<Object?> get props => [candidate];
}

/// Parameters for UploadCandidateMedia use case
class UploadCandidateMediaParams extends Equatable {
  final String candidateId;
  final String filePath;
  final MediaType mediaType;
  final String? title;
  final String? description;
  final bool isPrimary;

  const UploadCandidateMediaParams({
    required this.candidateId,
    required this.filePath,
    required this.mediaType,
    this.title,
    this.description,
    this.isPrimary = false,
  });

  @override
  List<Object?> get props => [
        candidateId,
        filePath,
        mediaType,
        title,
        description,
        isPrimary,
      ];
}

/// Parameters for UpdateCandidateOrder use case
class UpdateCandidateOrderParams extends Equatable {
  final String electionId;
  final String position;
  final List<String> candidateIds;

  const UpdateCandidateOrderParams({
    required this.electionId,
    required this.position,
    required this.candidateIds,
  });

  @override
  List<Object?> get props => [electionId, position, candidateIds];
}

/// Generic string parameter class
class StringParams extends Equatable {
  final String value;

  const StringParams(this.value);

  @override
  List<Object?> get props => [value];
}