import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/admin_election.dart';

part 'admin_election_model.freezed.dart';
part 'admin_election_model.g.dart';

/// Data model for admin election
@freezed
class AdminElectionModel with _$AdminElectionModel {
  const factory AdminElectionModel({
    required String id,
    required String title,
    required String description,
    required String category,
    @JsonKey(name: 'start_date') required DateTime startDate,
    @JsonKey(name: 'end_date') required DateTime endDate,
    required String status, // Will be converted to/from enum
    @JsonKey(name: 'eligible_voters') @Default(0) int eligibleVoters,
    @JsonKey(name: 'votes_cast') @Default(0) int votesCast,
    @Default([]) List<ElectionPositionModel> positions,
    ElectionConfigModel? config,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'last_modified_by') String? lastModifiedBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'allows_anonymous_voting') @Default(true) bool allowsAnonymousVoting,
    @JsonKey(name: 'allows_write_ins') @Default(false) bool allowsWriteIns,
    @JsonKey(name: 'allows_abstention') @Default(true) bool allowsAbstention,
    @JsonKey(name: 'minimum_turnout') @Default(0.0) double minimumTurnout,
    @JsonKey(name: 'is_public') @Default(true) bool isPublic,
    @JsonKey(name: 'results_published') @Default(false) bool resultsPublished,
    Map<String, dynamic>? results,
  }) = _AdminElectionModel;

  factory AdminElectionModel.fromJson(Map<String, dynamic> json) =>
      _$AdminElectionModelFromJson(json);

  const AdminElectionModel._();

  /// Convert model to domain entity
  AdminElection toEntity() {
    return AdminElection(
      id: id,
      title: title,
      description: description,
      category: category,
      startDate: startDate,
      endDate: endDate,
      status: _parseElectionStatus(status),
      eligibleVoters: eligibleVoters,
      votesCast: votesCast,
      positions: positions.map((p) => p.toEntity()).toList(),
      config: config?.toEntity(),
      createdBy: createdBy,
      lastModifiedBy: lastModifiedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      allowsAnonymousVoting: allowsAnonymousVoting,
      allowsWriteIns: allowsWriteIns,
      allowsAbstention: allowsAbstention,
      minimumTurnout: minimumTurnout,
      isPublic: isPublic,
      resultsPublished: resultsPublished,
      results: results,
    );
  }

  /// Create model from domain entity
  factory AdminElectionModel.fromEntity(AdminElection entity) {
    return AdminElectionModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      startDate: entity.startDate,
      endDate: entity.endDate,
      status: entity.status.name,
      eligibleVoters: entity.eligibleVoters,
      votesCast: entity.votesCast,
      positions: entity.positions.map((p) => ElectionPositionModel.fromEntity(p)).toList(),
      config: entity.config != null ? ElectionConfigModel.fromEntity(entity.config!) : null,
      createdBy: entity.createdBy,
      lastModifiedBy: entity.lastModifiedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      allowsAnonymousVoting: entity.allowsAnonymousVoting,
      allowsWriteIns: entity.allowsWriteIns,
      allowsAbstention: entity.allowsAbstention,
      minimumTurnout: entity.minimumTurnout,
      isPublic: entity.isPublic,
      resultsPublished: entity.resultsPublished,
      results: entity.results,
    );
  }

  ElectionStatus _parseElectionStatus(String statusString) {
    return ElectionStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => ElectionStatus.draft,
    );
  }
}

/// Election position data model
@freezed
class ElectionPositionModel with _$ElectionPositionModel {
  const factory ElectionPositionModel({
    required String id,
    required String title,
    required String description,
    @JsonKey(name: 'max_selections') @Default(1) int maxSelections,
    @JsonKey(name: 'min_selections') @Default(0) int minSelections,
    @JsonKey(name: 'display_order') @Default(0) int displayOrder,
    @JsonKey(name: 'requires_elevated_access') @Default(false) bool requiresElevatedAccess,
    @Default([]) List<AdminCandidateModel> candidates,
  }) = _ElectionPositionModel;

  factory ElectionPositionModel.fromJson(Map<String, dynamic> json) =>
      _$ElectionPositionModelFromJson(json);

  const ElectionPositionModel._();

  ElectionPosition toEntity() {
    return ElectionPosition(
      id: id,
      title: title,
      description: description,
      maxSelections: maxSelections,
      minSelections: minSelections,
      displayOrder: displayOrder,
      requiresElevatedAccess: requiresElevatedAccess,
      candidates: candidates.map((c) => c.toEntity()).toList(),
    );
  }

  factory ElectionPositionModel.fromEntity(ElectionPosition entity) {
    return ElectionPositionModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      maxSelections: entity.maxSelections,
      minSelections: entity.minSelections,
      displayOrder: entity.displayOrder,
      requiresElevatedAccess: entity.requiresElevatedAccess,
      candidates: entity.candidates.map((c) => AdminCandidateModel.fromEntity(c)).toList(),
    );
  }
}

/// Admin candidate data model
@freezed
class AdminCandidateModel with _$AdminCandidateModel {
  const factory AdminCandidateModel({
    required String id,
    required String name,
    required String department,
    required String position,
    required String manifesto,
    @JsonKey(name: 'id_number') String? idNumber,
    String? email,
    @JsonKey(name: 'photo_url') String? photoUrl,
    @JsonKey(name: 'video_url') String? videoUrl,
    @JsonKey(name: 'additional_info') String? additionalInfo,
    @JsonKey(name: 'election_id') required String electionId,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'display_order') @Default(0) int displayOrder,
    @JsonKey(name: 'vote_count') @Default(0) int voteCount,
    @JsonKey(name: 'media_files') @Default([]) List<CandidateMediaModel> mediaFiles,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'last_modified_by') String? lastModifiedBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _AdminCandidateModel;

  factory AdminCandidateModel.fromJson(Map<String, dynamic> json) =>
      _$AdminCandidateModelFromJson(json);

  const AdminCandidateModel._();

  AdminCandidate toEntity() {
    return AdminCandidate(
      id: id,
      name: name,
      department: department,
      position: position,
      manifesto: manifesto,
      idNumber: idNumber,
      email: email,
      photoUrl: photoUrl,
      videoUrl: videoUrl,
      additionalInfo: additionalInfo,
      electionId: electionId,
      isActive: isActive,
      displayOrder: displayOrder,
      voteCount: voteCount,
      mediaFiles: mediaFiles.map((m) => m.toEntity()).toList(),
      createdBy: createdBy,
      lastModifiedBy: lastModifiedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory AdminCandidateModel.fromEntity(AdminCandidate entity) {
    return AdminCandidateModel(
      id: entity.id,
      name: entity.name,
      department: entity.department,
      position: entity.position,
      manifesto: entity.manifesto,
      idNumber: entity.idNumber,
      email: entity.email,
      photoUrl: entity.photoUrl,
      videoUrl: entity.videoUrl,
      additionalInfo: entity.additionalInfo,
      electionId: entity.electionId,
      isActive: entity.isActive,
      displayOrder: entity.displayOrder,
      voteCount: entity.voteCount,
      mediaFiles: entity.mediaFiles.map((m) => CandidateMediaModel.fromEntity(m)).toList(),
      createdBy: entity.createdBy,
      lastModifiedBy: entity.lastModifiedBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}

/// Candidate media data model
@freezed
class CandidateMediaModel with _$CandidateMediaModel {
  const factory CandidateMediaModel({
    required String id,
    required String type, // Will be converted to/from enum
    @JsonKey(name: 'file_name') required String fileName,
    @JsonKey(name: 'file_url') required String fileUrl,
    @JsonKey(name: 'file_size') @Default(0) int fileSize,
    @JsonKey(name: 'mime_type') String? mimeType,
    String? title,
    String? description,
    @JsonKey(name: 'is_primary') @Default(false) bool isPrimary,
    @JsonKey(name: 'uploaded_at') required DateTime uploadedAt,
    @JsonKey(name: 'uploaded_by') required String uploadedBy,
  }) = _CandidateMediaModel;

  factory CandidateMediaModel.fromJson(Map<String, dynamic> json) =>
      _$CandidateMediaModelFromJson(json);

  const CandidateMediaModel._();

  CandidateMedia toEntity() {
    return CandidateMedia(
      id: id,
      type: _parseMediaType(type),
      fileName: fileName,
      fileUrl: fileUrl,
      fileSize: fileSize,
      mimeType: mimeType,
      title: title,
      description: description,
      isPrimary: isPrimary,
      uploadedAt: uploadedAt,
      uploadedBy: uploadedBy,
    );
  }

  factory CandidateMediaModel.fromEntity(CandidateMedia entity) {
    return CandidateMediaModel(
      id: entity.id,
      type: entity.type.name,
      fileName: entity.fileName,
      fileUrl: entity.fileUrl,
      fileSize: entity.fileSize,
      mimeType: entity.mimeType,
      title: entity.title,
      description: entity.description,
      isPrimary: entity.isPrimary,
      uploadedAt: entity.uploadedAt,
      uploadedBy: entity.uploadedBy,
    );
  }

  MediaType _parseMediaType(String typeString) {
    return MediaType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => MediaType.photo,
    );
  }
}

/// Election configuration data model
@freezed
class ElectionConfigModel with _$ElectionConfigModel {
  const factory ElectionConfigModel({
    @JsonKey(name: 'requires_verification') @Default(true) bool requiresVerification,
    @JsonKey(name: 'allows_offline_voting') @Default(true) bool allowsOfflineVoting,
    @JsonKey(name: 'enable_notifications') @Default(true) bool enableNotifications,
    @JsonKey(name: 'enable_real_time_results') @Default(false) bool enableRealTimeResults,
    @JsonKey(name: 'eligibility_criteria') Map<String, dynamic>? eligibilityCriteria,
    @JsonKey(name: 'additional_settings') Map<String, dynamic>? additionalSettings,
  }) = _ElectionConfigModel;

  factory ElectionConfigModel.fromJson(Map<String, dynamic> json) =>
      _$ElectionConfigModelFromJson(json);

  const ElectionConfigModel._();

  ElectionConfig toEntity() {
    return ElectionConfig(
      requiresVerification: requiresVerification,
      allowsOfflineVoting: allowsOfflineVoting,
      enableNotifications: enableNotifications,
      enableRealTimeResults: enableRealTimeResults,
      eligibilityCriteria: eligibilityCriteria,
      additionalSettings: additionalSettings,
    );
  }

  factory ElectionConfigModel.fromEntity(ElectionConfig entity) {
    return ElectionConfigModel(
      requiresVerification: entity.requiresVerification,
      allowsOfflineVoting: entity.allowsOfflineVoting,
      enableNotifications: entity.enableNotifications,
      enableRealTimeResults: entity.enableRealTimeResults,
      eligibilityCriteria: entity.eligibilityCriteria,
      additionalSettings: entity.additionalSettings,
    );
  }
}