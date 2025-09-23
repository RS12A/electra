import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/candidate.dart';
import '../entities/election.dart';

/// Repository interface for election-related operations
///
/// Defines the contract for fetching election and candidate data
/// from remote and local data sources.
abstract class ElectionRepository {
  /// Get list of active elections
  ///
  /// Returns a list of elections that are currently active or scheduled.
  Future<Either<Failure, List<ElectionSummary>>> getActiveElections();
  
  /// Get detailed election information
  ///
  /// Returns complete election details including rules and metadata.
  Future<Either<Failure, Election>> getElectionById(String electionId);
  
  /// Get candidates for a specific election
  ///
  /// Returns all candidates participating in the given election.
  Future<Either<Failure, List<Candidate>>> getCandidates(String electionId);
  
  /// Get candidates for a specific position in an election
  ///
  /// Returns candidates running for a particular position.
  Future<Either<Failure, List<Candidate>>> getCandidatesByPosition(
    String electionId,
    String position,
  );
  
  /// Get candidate details by ID
  ///
  /// Returns detailed information about a specific candidate.
  Future<Either<Failure, Candidate>> getCandidateById(String candidateId);
  
  /// Check if user is eligible to vote in an election
  ///
  /// Verifies voter eligibility based on various criteria.
  Future<Either<Failure, bool>> checkVotingEligibility(String electionId);
  
  /// Get election statistics
  ///
  /// Returns voting statistics and progress for an election.
  Future<Either<Failure, Map<String, dynamic>>> getElectionStats(
    String electionId,
  );
  
  /// Search elections by criteria
  ///
  /// Returns elections matching the search criteria.
  Future<Either<Failure, List<ElectionSummary>>> searchElections({
    String? query,
    ElectionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  });
}