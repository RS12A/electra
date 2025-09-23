import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/vote.dart';

/// Repository interface for vote-related operations
///
/// Defines the contract for casting, verifying, and managing votes
/// with support for offline queueing and secure submission.
abstract class VoteRepository {
  /// Cast a vote with encrypted selections
  ///
  /// Submits an encrypted vote to the server and returns confirmation.
  Future<Either<Failure, VoteConfirmation>> castVote({
    required String electionId,
    required Map<String, String> selections, // position -> candidateId
    required String ballotToken,
  });
  
  /// Verify a vote using its token
  ///
  /// Verifies that a vote exists and is valid using anonymous token.
  Future<Either<Failure, Map<String, dynamic>>> verifyVote(String voteToken);
  
  /// Queue vote for offline submission
  ///
  /// Stores vote locally when offline, for later synchronization.
  Future<Either<Failure, String>> queueOfflineVote({
    required String electionId,
    required Map<String, String> selections,
    required String ballotToken,
  });
  
  /// Get queued offline votes
  ///
  /// Returns all votes waiting for synchronization.
  Future<Either<Failure, List<OfflineVote>>> getQueuedVotes();
  
  /// Sync offline votes to server
  ///
  /// Attempts to submit all queued offline votes to the server.
  Future<Either<Failure, int>> syncOfflineVotes();
  
  /// Check if user has already voted in an election
  ///
  /// Prevents double voting by checking voting status.
  Future<Either<Failure, bool>> hasUserVoted(String electionId);
  
  /// Get user's voting history
  ///
  /// Returns anonymized voting history for the user.
  Future<Either<Failure, List<VoteConfirmation>>> getVotingHistory();
  
  /// Get vote statistics for an election
  ///
  /// Returns aggregated voting statistics without revealing vote content.
  Future<Either<Failure, Map<String, dynamic>>> getVoteStatistics(
    String electionId,
  );
  
  /// Generate ballot token for voting
  ///
  /// Creates a secure ballot token for vote authentication.
  Future<Either<Failure, String>> generateBallotToken(String electionId);
  
  /// Validate ballot token
  ///
  /// Verifies that a ballot token is valid and unused.
  Future<Either<Failure, bool>> validateBallotToken({
    required String ballotToken,
    required String electionId,
  });
  
  /// Delete queued offline vote
  ///
  /// Removes a specific offline vote from the queue.
  Future<Either<Failure, void>> deleteOfflineVote(String voteId);
  
  /// Get network connectivity status
  ///
  /// Checks if device can connect to voting servers.
  Future<bool> isConnected();
  
  /// Encrypt vote data
  ///
  /// Encrypts vote selections using AES-256-GCM encryption.
  Future<Either<Failure, Map<String, String>>> encryptVoteData({
    required Map<String, String> selections,
    required String encryptionKey,
  });
  
  /// Generate cryptographic signature
  ///
  /// Creates RSA signature for vote integrity verification.
  Future<Either<Failure, String>> generateVoteSignature({
    required String voteToken,
    required String encryptedData,
    required String electionId,
  });
}