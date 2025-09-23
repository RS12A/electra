import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'vote.freezed.dart';
part 'vote.g.dart';

/// Vote status enumeration
enum VoteStatus {
  /// Vote is being prepared (not yet cast)
  draft,
  
  /// Vote has been cast and is pending verification
  pending,
  
  /// Vote has been verified and counted
  verified,
  
  /// Vote was rejected due to validation errors
  rejected,
  
  /// Vote is queued for offline submission
  queued,
}

/// Vote entity representing a cast vote
///
/// Contains encrypted vote data and metadata for secure
/// and anonymous voting while maintaining audit capabilities.
@freezed
class Vote with _$Vote {
  const factory Vote({
    /// Unique identifier for the vote
    required String id,
    
    /// Anonymous vote token (separates vote from voter)
    required String voteToken,
    
    /// Election ID this vote belongs to
    required String electionId,
    
    /// Encrypted vote selections
    required Map<String, String> encryptedSelections,
    
    /// Vote status
    required VoteStatus status,
    
    /// Client-side timestamp when vote was cast
    required DateTime clientTimestamp,
    
    /// Server-side timestamp when vote was received
    DateTime? serverTimestamp,
    
    /// Cryptographic signature for verification
    required String signature,
    
    /// Encryption nonce/IV for decryption
    required String encryptionNonce,
    
    /// Hash of the encryption key for verification
    required String encryptionKeyHash,
    
    /// Client IP address (if available)
    String? clientIp,
    
    /// Device fingerprint for fraud detection
    String? deviceFingerprint,
    
    /// Verification result (if verified)
    String? verificationResult,
    
    /// Error message (if rejected)
    String? errorMessage,
  }) = _Vote;

  factory Vote.fromJson(Map<String, dynamic> json) =>
      _$VoteFromJson(json);
}

/// Vote selection for a specific position
@freezed
class VoteSelection with _$VoteSelection {
  const factory VoteSelection({
    /// Position ID (e.g., 'president', 'vice_president')
    required String positionId,
    
    /// Selected candidate ID
    required String candidateId,
    
    /// Position name for display
    required String positionName,
    
    /// Candidate name for display
    required String candidateName,
  }) = _VoteSelection;

  factory VoteSelection.fromJson(Map<String, dynamic> json) =>
      _$VoteSelectionFromJson(json);
}

/// Vote confirmation data
@freezed
class VoteConfirmation with _$VoteConfirmation {
  const factory VoteConfirmation({
    /// Unique confirmation ID
    required String confirmationId,
    
    /// Anonymous vote token for verification
    required String voteToken,
    
    /// Election title
    required String electionTitle,
    
    /// Timestamp of vote submission
    required DateTime timestamp,
    
    /// Number of positions voted for
    required int positionsVoted,
    
    /// Total positions available
    required int totalPositions,
    
    /// Verification URL or QR code data
    String? verificationCode,
    
    /// Next election information (if available)
    String? nextElectionInfo,
    
    /// Countdown to next election (if applicable)
    DateTime? nextElectionDate,
  }) = _VoteConfirmation;

  factory VoteConfirmation.fromJson(Map<String, dynamic> json) =>
      _$VoteConfirmationFromJson(json);
}

/// Offline vote queue entry
@freezed
class OfflineVote with _$OfflineVote {
  const factory OfflineVote({
    /// Unique identifier for the offline vote
    required String id,
    
    /// The vote data to be submitted
    required Vote vote,
    
    /// When the vote was queued for offline submission
    required DateTime queuedAt,
    
    /// Whether the vote has been synced to server
    @Default(false) bool isSynced,
    
    /// When the vote was synced (if applicable)
    DateTime? syncedAt,
    
    /// Sync result/error message
    String? syncResult,
    
    /// Retry count for failed sync attempts
    @Default(0) int retryCount,
    
    /// Next retry attempt time
    DateTime? nextRetryAt,
  }) = _OfflineVote;

  factory OfflineVote.fromJson(Map<String, dynamic> json) =>
      _$OfflineVoteFromJson(json);
}