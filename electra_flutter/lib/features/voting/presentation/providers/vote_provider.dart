import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/vote.dart';
import '../../domain/usecases/vote_usecases.dart';
import '../../../../core/error/failures.dart';

part 'vote_provider.g.dart';

/// Vote state for managing voting operations
class VoteState {
  final bool isLoading;
  final bool isVoting;
  final Vote? currentVote;
  final String? error;
  final bool hasVoted;
  final List<Vote> votingHistory;

  const VoteState({
    this.isLoading = false,
    this.isVoting = false,
    this.currentVote,
    this.error,
    this.hasVoted = false,
    this.votingHistory = const [],
  });

  VoteState copyWith({
    bool? isLoading,
    bool? isVoting,
    Vote? currentVote,
    String? error,
    bool? hasVoted,
    List<Vote>? votingHistory,
    bool clearError = false,
  }) {
    return VoteState(
      isLoading: isLoading ?? this.isLoading,
      isVoting: isVoting ?? this.isVoting,
      currentVote: currentVote ?? this.currentVote,
      error: clearError ? null : (error ?? this.error),
      hasVoted: hasVoted ?? this.hasVoted,
      votingHistory: votingHistory ?? this.votingHistory,
    );
  }
}

/// Vote provider for managing vote casting and history
@riverpod
class VoteNotifier extends _$VoteNotifier {
  @override
  VoteState build() {
    return const VoteState();
  }

  /// Cast a vote with the given selections
  Future<void> castVote({
    required String electionId,
    required Map<String, String> selections,
    required String ballotToken,
  }) async {
    state = state.copyWith(isVoting: true, clearError: true);

    try {
      final castVote = ref.read(castVoteProvider);
      final result = await castVote(CastVoteParams(
        electionId: electionId,
        selections: selections,
        ballotToken: ballotToken,
      ));

      result.fold(
        (failure) {
          state = state.copyWith(
            isVoting: false,
            error: _mapFailureToMessage(failure),
          );
        },
        (voteConfirmation) {
          state = state.copyWith(
            isVoting: false,
            hasVoted: true,
            currentVote: Vote(
              id: voteConfirmation.voteToken,
              voteToken: voteConfirmation.voteToken,
              electionId: electionId,
              encryptedSelections: selections,
              status: VoteStatus.pending,
              timestamp: DateTime.now(),
              ballotTokenHash: ballotToken.hashCode.toString(),
            ),
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isVoting: false,
        error: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Queue vote for offline processing
  Future<void> queueOfflineVote({
    required String electionId,
    required Map<String, String> selections,
    required String ballotToken,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final queueOfflineVote = ref.read(queueOfflineVoteProvider);
      final result = await queueOfflineVote(QueueOfflineVoteParams(
        electionId: electionId,
        selections: selections,
        ballotToken: ballotToken,
      ));

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: _mapFailureToMessage(failure),
          );
        },
        (queueId) {
          state = state.copyWith(
            isLoading: false,
            currentVote: Vote(
              id: queueId,
              voteToken: '',
              electionId: electionId,
              encryptedSelections: selections,
              status: VoteStatus.queued,
              timestamp: DateTime.now(),
              ballotTokenHash: ballotToken.hashCode.toString(),
            ),
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to queue offline vote: ${e.toString()}',
      );
    }
  }

  /// Load voting history
  Future<void> loadVotingHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final getVotingHistory = ref.read(getVotingHistoryProvider);
      final result = await getVotingHistory();

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: _mapFailureToMessage(failure),
          );
        },
        (history) {
          final votes = history.map((confirmation) => Vote(
            id: confirmation.voteToken,
            voteToken: confirmation.voteToken,
            electionId: confirmation.electionId ?? '',
            encryptedSelections: const {},
            status: VoteStatus.verified,
            timestamp: confirmation.submittedAt ?? DateTime.now(),
            ballotTokenHash: '',
          )).toList();

          state = state.copyWith(
            isLoading: false,
            votingHistory: votes,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load voting history: ${e.toString()}',
      );
    }
  }

  /// Clear current error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return 'Network error. Please check your connection.';
      case ServerFailure:
        return 'Server error. Please try again later.';
      case AuthenticationFailure:
        return 'Authentication failed. Please log in again.';
      case ValidationFailure:
        return 'Invalid data. Please check your input.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

/// Providers for vote use cases
@riverpod
CastVote castVote(CastVoteRef ref) {
  final repository = ref.read(voteRepositoryProvider);
  return CastVote(repository);
}

@riverpod
QueueOfflineVote queueOfflineVote(QueueOfflineVoteRef ref) {
  final repository = ref.read(voteRepositoryProvider);
  return QueueOfflineVote(repository);
}

@riverpod
GetVotingHistory getVotingHistory(GetVotingHistoryRef ref) {
  final repository = ref.read(voteRepositoryProvider);
  return GetVotingHistory(repository);
}

@riverpod
HasUserVoted hasUserVoted(HasUserVotedRef ref) {
  final repository = ref.read(voteRepositoryProvider);
  return HasUserVoted(repository);
}

// TODO: Implement VoteRepository provider
@riverpod
VoteRepository voteRepository(VoteRepositoryRef ref) {
  throw UnimplementedError('VoteRepository implementation needed');
}