import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/candidate.dart';
import '../entities/election.dart';
import '../repositories/election_repository.dart';

/// Get active elections use case
class GetActiveElections extends NoParamsUseCase<List<ElectionSummary>> {
  const GetActiveElections(this.repository);
  
  final ElectionRepository repository;
  
  @override
  Future<Either<Failure, List<ElectionSummary>>> call() async {
    return await repository.getActiveElections();
  }
}

/// Get election by ID use case
class GetElectionById extends UseCase<Election, StringParams> {
  const GetElectionById(this.repository);
  
  final ElectionRepository repository;
  
  @override
  Future<Either<Failure, Election>> call(StringParams params) async {
    return await repository.getElectionById(params.value);
  }
}

/// Get candidates use case
class GetCandidates extends UseCase<List<Candidate>, GetCandidatesParams> {
  const GetCandidates(this.repository);
  
  final ElectionRepository repository;
  
  @override
  Future<Either<Failure, List<Candidate>>> call(GetCandidatesParams params) async {
    if (params.position != null) {
      return await repository.getCandidatesByPosition(
        params.electionId,
        params.position!,
      );
    }
    return await repository.getCandidates(params.electionId);
  }
}

/// Get candidate by ID use case
class GetCandidateById extends UseCase<Candidate, StringParams> {
  const GetCandidateById(this.repository);
  
  final ElectionRepository repository;
  
  @override
  Future<Either<Failure, Candidate>> call(StringParams params) async {
    return await repository.getCandidateById(params.value);
  }
}

/// Check voting eligibility use case
class CheckVotingEligibility extends UseCase<bool, StringParams> {
  const CheckVotingEligibility(this.repository);
  
  final ElectionRepository repository;
  
  @override
  Future<Either<Failure, bool>> call(StringParams params) async {
    return await repository.checkVotingEligibility(params.value);
  }
}

/// Get election statistics use case
class GetElectionStats extends UseCase<Map<String, dynamic>, StringParams> {
  const GetElectionStats(this.repository);
  
  final ElectionRepository repository;
  
  @override
  Future<Either<Failure, Map<String, dynamic>>> call(StringParams params) async {
    return await repository.getElectionStats(params.value);
  }
}

/// Search elections use case
class SearchElections extends UseCase<List<ElectionSummary>, SearchElectionsParams> {
  const SearchElections(this.repository);
  
  final ElectionRepository repository;
  
  @override
  Future<Either<Failure, List<ElectionSummary>>> call(SearchElectionsParams params) async {
    return await repository.searchElections(
      query: params.query,
      status: params.status,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

/// Parameters for getting candidates
class GetCandidatesParams {
  const GetCandidatesParams({
    required this.electionId,
    this.position,
  });
  
  final String electionId;
  final String? position;
}

/// Parameters for searching elections
class SearchElectionsParams {
  const SearchElectionsParams({
    this.query,
    this.status,
    this.startDate,
    this.endDate,
  });
  
  final String? query;
  final ElectionStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
}