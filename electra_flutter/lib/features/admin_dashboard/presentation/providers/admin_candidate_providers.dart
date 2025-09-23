import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/admin_election.dart';
import '../../domain/usecases/candidate_usecases.dart';

part 'admin_candidate_providers.g.dart';
part 'admin_candidate_providers.freezed.dart';

/// Candidate management state
@freezed
class CandidateManagementState with _$CandidateManagementState {
  const factory CandidateManagementState({
    @Default([]) List<AdminCandidate> candidates,
    AdminCandidate? selectedCandidate,
    String? selectedElectionId,
    String? selectedPosition,
    @Default(false) bool isLoading,
    @Default(false) bool isCreating,
    @Default(false) bool isUpdating,
    @Default(false) bool isDeleting,
    @Default(false) bool isUploadingMedia,
    String? error,
  }) = _CandidateManagementState;
}

/// Candidates list provider for a specific election
@riverpod
class AdminCandidates extends _$AdminCandidates {
  @override
  Future<List<AdminCandidate>> build({
    required String electionId,
    String? position,
    bool activeOnly = true,
    String sortBy = 'displayOrder',
  }) async {
    final getCandidates = getIt<GetCandidates>();
    final result = await getCandidates(GetCandidatesParams(
      electionId: electionId,
      position: position,
      activeOnly: activeOnly,
      sortBy: sortBy,
    ));
    
    return result.fold(
      (failure) => throw failure,
      (candidates) => candidates,
    );
  }
}

/// Selected candidate provider
@riverpod
class AdminSelectedCandidate extends _$AdminSelectedCandidate {
  @override
  Future<AdminCandidate?> build(String? candidateId) async {
    if (candidateId == null) return null;
    
    final getCandidateById = getIt<GetCandidateById>();
    final result = await getCandidateById(StringParams(candidateId));
    
    return result.fold(
      (failure) => throw failure,
      (candidate) => candidate,
    );
  }

  /// Update selected candidate
  void updateCandidate(AdminCandidate? candidate) {
    state = AsyncValue.data(candidate);
  }
}

/// Candidate operations provider
@riverpod
class AdminCandidateOperations extends _$AdminCandidateOperations {
  @override
  CandidateManagementState build() {
    return const CandidateManagementState();
  }

  /// Set selected election and position
  void setElectionAndPosition(String electionId, String? position) {
    state = state.copyWith(
      selectedElectionId: electionId,
      selectedPosition: position,
    );
    
    // Load candidates for this election/position
    ref.invalidate(adminCandidatesProvider(
      electionId: electionId,
      position: position,
    ));
  }

  /// Create a new candidate
  Future<AdminCandidate> createCandidate(AdminCandidate candidate) async {
    state = state.copyWith(isCreating: true, error: null);
    
    final createCandidate = getIt<CreateCandidate>();
    final result = await createCandidate(CreateCandidateParams(candidate: candidate));
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          isCreating: false,
          error: failure.message ?? 'Failed to create candidate',
        );
        throw failure;
      },
      (createdCandidate) {
        state = state.copyWith(isCreating: false);
        // Refresh candidates list
        ref.invalidate(adminCandidatesProvider(electionId: candidate.electionId));
        return createdCandidate;
      },
    );
  }

  /// Update an existing candidate
  Future<AdminCandidate> updateCandidate(AdminCandidate candidate) async {
    state = state.copyWith(isUpdating: true, error: null);
    
    final updateCandidate = getIt<UpdateCandidate>();
    final result = await updateCandidate(UpdateCandidateParams(candidate: candidate));
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          isUpdating: false,
          error: failure.message ?? 'Failed to update candidate',
        );
        throw failure;
      },
      (updatedCandidate) {
        state = state.copyWith(isUpdating: false);
        
        // Update selected candidate if it matches
        if (state.selectedCandidate?.id == updatedCandidate.id) {
          ref.read(adminSelectedCandidateProvider(updatedCandidate.id).notifier)
              .updateCandidate(updatedCandidate);
        }
        
        // Refresh candidates list
        ref.invalidate(adminCandidatesProvider(electionId: candidate.electionId));
        return updatedCandidate;
      },
    );
  }

  /// Delete a candidate
  Future<void> deleteCandidate(String candidateId, String electionId) async {
    state = state.copyWith(isDeleting: true, error: null);
    
    final deleteCandidate = getIt<DeleteCandidate>();
    final result = await deleteCandidate(StringParams(candidateId));
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isDeleting: false,
          error: failure.message ?? 'Failed to delete candidate',
        );
        throw failure;
      },
      (_) {
        state = state.copyWith(isDeleting: false);
        
        // Clear selected candidate if it was deleted
        if (state.selectedCandidate?.id == candidateId) {
          ref.read(adminSelectedCandidateProvider(candidateId).notifier)
              .updateCandidate(null);
        }
        
        // Refresh candidates list
        ref.invalidate(adminCandidatesProvider(electionId: electionId));
      },
    );
  }

  /// Upload candidate media
  Future<CandidateMedia> uploadMedia({
    required String candidateId,
    required String filePath,
    required MediaType mediaType,
    String? title,
    String? description,
    bool isPrimary = false,
  }) async {
    state = state.copyWith(isUploadingMedia: true, error: null);
    
    final uploadCandidateMedia = getIt<UploadCandidateMedia>();
    final result = await uploadCandidateMedia(UploadCandidateMediaParams(
      candidateId: candidateId,
      filePath: filePath,
      mediaType: mediaType,
      title: title,
      description: description,
      isPrimary: isPrimary,
    ));
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          isUploadingMedia: false,
          error: failure.message ?? 'Failed to upload media',
        );
        throw failure;
      },
      (uploadedMedia) {
        state = state.copyWith(isUploadingMedia: false);
        
        // Refresh candidate details to show new media
        ref.invalidate(adminSelectedCandidateProvider(candidateId));
        
        // Refresh candidates list if needed
        if (state.selectedElectionId != null) {
          ref.invalidate(adminCandidatesProvider(electionId: state.selectedElectionId!));
        }
        
        return uploadedMedia;
      },
    );
  }

  /// Delete candidate media
  Future<void> deleteMedia(String mediaId, String candidateId) async {
    final deleteCandidateMedia = getIt<DeleteCandidateMedia>();
    final result = await deleteCandidateMedia(StringParams(mediaId));
    
    result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message ?? 'Failed to delete media',
        );
        throw failure;
      },
      (_) {
        // Refresh candidate details to remove deleted media
        ref.invalidate(adminSelectedCandidateProvider(candidateId));
        
        // Refresh candidates list if needed
        if (state.selectedElectionId != null) {
          ref.invalidate(adminCandidatesProvider(electionId: state.selectedElectionId!));
        }
      },
    );
  }

  /// Update candidate display order
  Future<void> updateCandidateOrder({
    required String electionId,
    required String position,
    required List<String> candidateIds,
  }) async {
    final updateCandidateOrder = getIt<UpdateCandidateOrder>();
    final result = await updateCandidateOrder(UpdateCandidateOrderParams(
      electionId: electionId,
      position: position,
      candidateIds: candidateIds,
    ));
    
    result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message ?? 'Failed to update candidate order',
        );
        throw failure;
      },
      (_) {
        // Refresh candidates list to show new order
        ref.invalidate(adminCandidatesProvider(
          electionId: electionId,
          position: position,
        ));
      },
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Set selected candidate
  void selectCandidate(AdminCandidate? candidate) {
    state = state.copyWith(selectedCandidate: candidate);
  }
}

/// Candidate media upload progress provider
@riverpod
class CandidateMediaUploadProgress extends _$CandidateMediaUploadProgress {
  @override
  Map<String, double> build() => {};

  /// Update upload progress for a file
  void updateProgress(String filePath, double progress) {
    state = {...state, filePath: progress};
  }

  /// Remove progress tracking for a file
  void removeProgress(String filePath) {
    final newState = Map<String, double>.from(state);
    newState.remove(filePath);
    state = newState;
  }

  /// Clear all progress
  void clearAll() {
    state = {};
  }
}

/// Candidate form state provider
@riverpod
class CandidateFormState extends _$CandidateFormState {
  @override
  AdminCandidate? build() => null;

  /// Initialize form with candidate data
  void initialize(AdminCandidate? candidate) {
    state = candidate;
  }

  /// Update form data
  void updateForm(AdminCandidate candidate) {
    state = candidate;
  }

  /// Clear form
  void clear() {
    state = null;
  }

  /// Check if form has changes
  bool hasChanges(AdminCandidate? original) {
    return state != original;
  }
}