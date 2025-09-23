import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/candidate.dart';
import '../../domain/entities/election.dart';
import '../../domain/entities/vote.dart';

part 'voting_state.freezed.dart';

/// State for election data loading
@freezed
class ElectionState with _$ElectionState {
  const factory ElectionState({
    @Default(false) bool isLoading,
    @Default([]) List<ElectionSummary> elections,
    Election? selectedElection,
    String? error,
  }) = _ElectionState;
}

/// State for candidates data loading
@freezed
class CandidatesState with _$CandidatesState {
  const factory CandidatesState({
    @Default(false) bool isLoading,
    @Default([]) List<Candidate> candidates,
    @Default({}) Map<String, List<Candidate>> candidatesByPosition,
    Candidate? selectedCandidate,
    String? error,
  }) = _CandidatesState;
}

/// State for voting process
@freezed
class VotingState with _$VotingState {
  const factory VotingState({
    @Default(false) bool isLoading,
    @Default(false) bool isSubmitting,
    @Default({}) Map<String, String> selections, // position -> candidateId
    VoteConfirmation? confirmation,
    String? ballotToken,
    String? error,
    @Default(false) bool hasVoted,
    @Default(false) bool isEligible,
  }) = _VotingState;
}

/// State for offline votes management
@freezed
class OfflineVotesState with _$OfflineVotesState {
  const factory OfflineVotesState({
    @Default(false) bool isLoading,
    @Default(false) bool isSyncing,
    @Default([]) List<OfflineVote> queuedVotes,
    @Default(0) int syncedCount,
    String? error,
    @Default(false) bool hasConnection,
  }) = _OfflineVotesState;
}

/// Combined voting dashboard state
@freezed
class VotingDashboardState with _$VotingDashboardState {
  const factory VotingDashboardState({
    @Default(false) bool isLoading,
    @Default([]) List<ElectionSummary> activeElections,
    @Default([]) List<VoteConfirmation> votingHistory,
    @Default({}) Map<String, bool> votingStatus, // electionId -> hasVoted
    String? error,
  }) = _VotingDashboardState;
}

/// Voting flow state for navigation and progress tracking
@freezed
class VotingFlowState with _$VotingFlowState {
  const factory VotingFlowState({
    @Default(VotingStep.candidateListing) VotingStep currentStep,
    String? electionId,
    Election? election,
    @Default([]) List<Candidate> candidates,
    @Default({}) Map<String, String> selections,
    VoteConfirmation? confirmation,
    String? error,
  }) = _VotingFlowState;
}

/// Voting steps enumeration
enum VotingStep {
  candidateListing,
  voteCasting,
  confirmation,
}