import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vote.dart';
import '../repositories/vote_repository.dart';

/// Cast vote use case
class CastVote extends UseCase<VoteConfirmation, CastVoteParams> {
  const CastVote(this.repository);
  
  final VoteRepository repository;
  
  @override
  Future<Either<Failure, VoteConfirmation>> call(CastVoteParams params) async {
    return await repository.castVote(
      electionId: params.electionId,
      selections: params.selections,
      ballotToken: params.ballotToken,
    );
  }
}

/// Verify vote use case
class VerifyVote extends UseCase<Map<String, dynamic>, StringParams> {
  const VerifyVote(this.repository);
  
  final VoteRepository repository;
  
  @override
  Future<Either<Failure, Map<String, dynamic>>> call(StringParams params) async {
    return await repository.verifyVote(params.value);
  }
}

/// Queue offline vote use case
class QueueOfflineVote extends UseCase<String, QueueOfflineVoteParams> {
  const QueueOfflineVote(this.repository);
  
  final VoteRepository repository;
  
  @override
  Future<Either<Failure, String>> call(QueueOfflineVoteParams params) async {
    return await repository.queueOfflineVote(
      electionId: params.electionId,
      selections: params.selections,
      ballotToken: params.ballotToken,
    );
  }
}

/// Get queued votes use case
class GetQueuedVotes extends NoParamsUseCase<List<OfflineVote>> {
  const GetQueuedVotes(this.repository);
  
  final VoteRepository repository;
  
  @override
  Future<Either<Failure, List<OfflineVote>>> call() async {
    return await repository.getQueuedVotes();
  }
}

/// Sync offline votes use case
class SyncOfflineVotes extends NoParamsUseCase<int> {
  const SyncOfflineVotes(this.repository);
  
  final VoteRepository repository;
  
  @override
  Future<Either<Failure, int>> call() async {
    return await repository.syncOfflineVotes();
  }
}

/// Check if user has voted use case
class HasUserVoted extends UseCase<bool, StringParams> {
  const HasUserVoted(this.repository);
  
  final VoteRepository repository;
  
  @override
  Future<Either<Failure, bool>> call(StringParams params) async {
    return await repository.hasUserVoted(params.value);
  }
}

/// Get voting history use case
class GetVotingHistory extends NoParamsUseCase<List<VoteConfirmation>> {
  const GetVotingHistory(this.repository);
  
  final VoteRepository repository;
  
  @override
  Future<Either<Failure, List<VoteConfirmation>>> call() async {
    return await repository.getVotingHistory();
  }
}

/// Get vote statistics use case
class GetVoteStatistics extends UseCase<Map<String, dynamic>, StringParams> {
  const GetVoteStatistics(this.repository);
  
  final VoteRepository repository;
  
  @override
  Future<Either<Failure, Map<String, dynamic>>> call(StringParams params) async {
    return await repository.getVoteStatistics(params.value);
  }
}

/// Generate ballot token use case
class GenerateBallotToken extends UseCase<String, StringParams> {
  const GenerateBallotToken(this.repository);
  
  final VoteRepository repository;
  
  @override
  Future<Either<Failure, String>> call(StringParams params) async {
    return await repository.generateBallotToken(params.value);
  }
}

/// Validate ballot token use case
class ValidateBallotToken extends UseCase<bool, ValidateBallotTokenParams> {
  const ValidateBallotToken(this.repository);
  
  final VoteRepository repository;
  
  @override
  Future<Either<Failure, bool>> call(ValidateBallotTokenParams params) async {
    return await repository.validateBallotToken(
      ballotToken: params.ballotToken,
      electionId: params.electionId,
    );
  }
}

/// Parameters for casting a vote
class CastVoteParams {
  const CastVoteParams({
    required this.electionId,
    required this.selections,
    required this.ballotToken,
  });
  
  final String electionId;
  final Map<String, String> selections;
  final String ballotToken;
}

/// Parameters for queueing offline vote
class QueueOfflineVoteParams {
  const QueueOfflineVoteParams({
    required this.electionId,
    required this.selections,
    required this.ballotToken,
  });
  
  final String electionId;
  final Map<String, String> selections;
  final String ballotToken;
}

/// Parameters for validating ballot token
class ValidateBallotTokenParams {
  const ValidateBallotTokenParams({
    required this.ballotToken,
    required this.electionId,
  });
  
  final String ballotToken;
  final String electionId;
}