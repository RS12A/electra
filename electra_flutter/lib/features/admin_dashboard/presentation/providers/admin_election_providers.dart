import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/admin_election.dart';
import '../../domain/usecases/election_usecases.dart';

part 'admin_election_providers.g.dart';
part 'admin_election_providers.freezed.dart';

/// Election filters state
@freezed
class ElectionFilters with _$ElectionFilters {
  const factory ElectionFilters({
    ElectionStatus? status,
    String? searchQuery,
    @Default('createdAt') String sortBy,
    @Default('desc') String sortOrder,
  }) = _ElectionFilters;
}

/// Election management state
@freezed
class ElectionManagementState with _$ElectionManagementState {
  const factory ElectionManagementState({
    @Default([]) List<AdminElection> elections,
    AdminElection? selectedElection,
    @Default(ElectionFilters()) ElectionFilters filters,
    @Default(false) bool isLoading,
    @Default(false) bool isCreating,
    @Default(false) bool isUpdating,
    @Default(false) bool isDeleting,
    String? error,
    @Default(1) int currentPage,
    @Default(false) bool hasNextPage,
  }) = _ElectionManagementState;
}

/// Elections list provider with filtering and pagination
@riverpod
class AdminElections extends _$AdminElections {
  @override
  Future<List<AdminElection>> build({
    ElectionStatus? status,
    String? searchQuery,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final getElections = getIt<GetElections>();
    final result = await getElections(GetElectionsParams(
      status: status,
      searchQuery: searchQuery,
      page: page,
      limit: limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
    ));
    
    return result.fold(
      (failure) => throw failure,
      (elections) => elections,
    );
  }

  /// Load more elections (pagination)
  Future<List<AdminElection>> loadMore() async {
    final currentState = state.valueOrNull ?? [];
    final nextPage = (currentState.length ~/ 20) + 1;
    
    final getElections = getIt<GetElections>();
    final result = await getElections(GetElectionsParams(
      status: status,
      searchQuery: searchQuery,
      page: nextPage,
      limit: 20,
      sortBy: sortBy,
      sortOrder: sortOrder,
    ));
    
    return result.fold(
      (failure) => throw failure,
      (newElections) => [...currentState, ...newElections],
    );
  }
}

/// Selected election provider
@riverpod
class AdminSelectedElection extends _$AdminSelectedElection {
  @override
  Future<AdminElection?> build(String? electionId) async {
    if (electionId == null) return null;
    
    final getElectionById = getIt<GetElectionById>();
    final result = await getElectionById(StringParams(electionId));
    
    return result.fold(
      (failure) => throw failure,
      (election) => election,
    );
  }

  /// Update selected election
  void updateElection(AdminElection? election) {
    state = AsyncValue.data(election);
  }
}

/// Election management operations provider
@riverpod
class AdminElectionOperations extends _$AdminElectionOperations {
  @override
  ElectionManagementState build() {
    final electionsAsync = ref.watch(adminElectionsProvider());
    final selectedElectionAsync = ref.watch(adminSelectedElectionProvider(null));
    
    return ElectionManagementState(
      elections: electionsAsync.valueOrNull ?? [],
      selectedElection: selectedElectionAsync.valueOrNull,
      isLoading: electionsAsync.isLoading,
      error: electionsAsync.hasError ? electionsAsync.error.toString() : null,
    );
  }

  /// Create a new election
  Future<AdminElection> createElection(AdminElection election) async {
    state = state.copyWith(isCreating: true, error: null);
    
    final createElection = getIt<CreateElection>();
    final result = await createElection(CreateElectionParams(election: election));
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          isCreating: false,
          error: failure.message ?? 'Failed to create election',
        );
        throw failure;
      },
      (createdElection) {
        state = state.copyWith(isCreating: false);
        // Refresh elections list
        ref.invalidate(adminElectionsProvider());
        return createdElection;
      },
    );
  }

  /// Update an existing election
  Future<AdminElection> updateElection(AdminElection election) async {
    state = state.copyWith(isUpdating: true, error: null);
    
    final updateElection = getIt<UpdateElection>();
    final result = await updateElection(UpdateElectionParams(election: election));
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          isUpdating: false,
          error: failure.message ?? 'Failed to update election',
        );
        throw failure;
      },
      (updatedElection) {
        state = state.copyWith(isUpdating: false);
        // Update selected election if it matches
        if (state.selectedElection?.id == updatedElection.id) {
          ref.read(adminSelectedElectionProvider(updatedElection.id).notifier)
              .updateElection(updatedElection);
        }
        // Refresh elections list
        ref.invalidate(adminElectionsProvider());
        return updatedElection;
      },
    );
  }

  /// Delete an election
  Future<void> deleteElection(String electionId) async {
    state = state.copyWith(isDeleting: true, error: null);
    
    final deleteElection = getIt<DeleteElection>();
    final result = await deleteElection(StringParams(electionId));
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isDeleting: false,
          error: failure.message ?? 'Failed to delete election',
        );
        throw failure;
      },
      (_) {
        state = state.copyWith(isDeleting: false);
        // Clear selected election if it was deleted
        if (state.selectedElection?.id == electionId) {
          ref.read(adminSelectedElectionProvider(electionId).notifier)
              .updateElection(null);
        }
        // Refresh elections list
        ref.invalidate(adminElectionsProvider());
      },
    );
  }

  /// Activate an election
  Future<AdminElection> activateElection(String electionId) async {
    final activateElection = getIt<ActivateElection>();
    final result = await activateElection(StringParams(electionId));
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message ?? 'Failed to activate election',
        );
        throw failure;
      },
      (activatedElection) {
        // Update selected election if it matches
        if (state.selectedElection?.id == electionId) {
          ref.read(adminSelectedElectionProvider(electionId).notifier)
              .updateElection(activatedElection);
        }
        // Refresh elections list
        ref.invalidate(adminElectionsProvider());
        return activatedElection;
      },
    );
  }

  /// Close an election
  Future<AdminElection> closeElection(String electionId) async {
    final closeElection = getIt<CloseElection>();
    final result = await closeElection(StringParams(electionId));
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message ?? 'Failed to close election',
        );
        throw failure;
      },
      (closedElection) {
        // Update selected election if it matches
        if (state.selectedElection?.id == electionId) {
          ref.read(adminSelectedElectionProvider(electionId).notifier)
              .updateElection(closedElection);
        }
        // Refresh elections list
        ref.invalidate(adminElectionsProvider());
        return closedElection;
      },
    );
  }

  /// Suspend an election
  Future<AdminElection> suspendElection(String electionId) async {
    final suspendElection = getIt<SuspendElection>();
    final result = await suspendElection(StringParams(electionId));
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message ?? 'Failed to suspend election',
        );
        throw failure;
      },
      (suspendedElection) {
        // Update selected election if it matches
        if (state.selectedElection?.id == electionId) {
          ref.read(adminSelectedElectionProvider(electionId).notifier)
              .updateElection(suspendedElection);
        }
        // Refresh elections list
        ref.invalidate(adminElectionsProvider());
        return suspendedElection;
      },
    );
  }

  /// Get election results
  Future<Map<String, dynamic>> getElectionResults(String electionId) async {
    final getElectionResults = getIt<GetElectionResults>();
    final result = await getElectionResults(StringParams(electionId));
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message ?? 'Failed to get election results',
        );
        throw failure;
      },
      (results) => results,
    );
  }

  /// Publish election results
  Future<void> publishResults(String electionId) async {
    final publishResults = getIt<PublishResults>();
    final result = await publishResults(StringParams(electionId));
    
    result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message ?? 'Failed to publish results',
        );
        throw failure;
      },
      (_) {
        // Refresh elections list and selected election
        ref.invalidate(adminElectionsProvider());
        ref.invalidate(adminSelectedElectionProvider(electionId));
      },
    );
  }

  /// Update election filters
  void updateFilters(ElectionFilters filters) {
    state = state.copyWith(filters: filters);
    // Refresh elections with new filters
    ref.invalidate(adminElectionsProvider(
      status: filters.status,
      searchQuery: filters.searchQuery,
      sortBy: filters.sortBy,
      sortOrder: filters.sortOrder,
    ));
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}