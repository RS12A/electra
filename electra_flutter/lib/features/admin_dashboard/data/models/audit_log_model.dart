import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/audit_log.dart';

part 'audit_log_model.freezed.dart';
part 'audit_log_model.g.dart';

/// Data model for audit log
@freezed
class AuditLogModel with _$AuditLogModel {
  const factory AuditLogModel({
    required String id,
    @JsonKey(name: 'sequence_number') required int sequenceNumber,
    @JsonKey(name: 'previous_hash') String? previousHash,
    @JsonKey(name: 'content_hash') required String contentHash,
    @JsonKey(name: 'digital_signature') required String digitalSignature,
    required String action, // Will be converted to/from enum
    required String category, // Will be converted to/from enum
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'user_role') String? userRole,
    @JsonKey(name: 'ip_address') String? ipAddress,
    @JsonKey(name: 'user_agent') String? userAgent,
    @JsonKey(name: 'resource_id') String? resourceId,
    @JsonKey(name: 'resource_type') String? resourceType,
    required String description,
    required String result, // Will be converted to/from enum
    @JsonKey(name: 'error_message') String? errorMessage,
    Map<String, dynamic>? metadata,
    required DateTime timestamp,
    @JsonKey(name: 'session_id') String? sessionId,
    @JsonKey(name: 'client_id') String? clientId,
    @JsonKey(name: 'api_version') String? apiVersion,
    @JsonKey(name: 'request_id') String? requestId,
  }) = _AuditLogModel;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) =>
      _$AuditLogModelFromJson(json);

  const AuditLogModel._();

  /// Convert model to domain entity
  AuditLog toEntity() {
    return AuditLog(
      id: id,
      sequenceNumber: sequenceNumber,
      previousHash: previousHash,
      contentHash: contentHash,
      digitalSignature: digitalSignature,
      action: _parseAuditAction(action),
      category: _parseAuditCategory(category),
      userId: userId,
      userRole: userRole,
      ipAddress: ipAddress,
      userAgent: userAgent,
      resourceId: resourceId,
      resourceType: resourceType,
      description: description,
      result: _parseAuditResult(result),
      errorMessage: errorMessage,
      metadata: metadata,
      timestamp: timestamp,
      sessionId: sessionId,
      clientId: clientId,
      apiVersion: apiVersion,
      requestId: requestId,
    );
  }

  /// Create model from domain entity
  factory AuditLogModel.fromEntity(AuditLog entity) {
    return AuditLogModel(
      id: entity.id,
      sequenceNumber: entity.sequenceNumber,
      previousHash: entity.previousHash,
      contentHash: entity.contentHash,
      digitalSignature: entity.digitalSignature,
      action: entity.action.name,
      category: entity.category.name,
      userId: entity.userId,
      userRole: entity.userRole,
      ipAddress: entity.ipAddress,
      userAgent: entity.userAgent,
      resourceId: entity.resourceId,
      resourceType: entity.resourceType,
      description: entity.description,
      result: entity.result.name,
      errorMessage: entity.errorMessage,
      metadata: entity.metadata,
      timestamp: entity.timestamp,
      sessionId: entity.sessionId,
      clientId: entity.clientId,
      apiVersion: entity.apiVersion,
      requestId: entity.requestId,
    );
  }

  AuditAction _parseAuditAction(String actionString) {
    return AuditAction.values.firstWhere(
      (e) => e.name == actionString,
      orElse: () => AuditAction.userLogin,
    );
  }

  AuditCategory _parseAuditCategory(String categoryString) {
    return AuditCategory.values.firstWhere(
      (e) => e.name == categoryString,
      orElse: () => AuditCategory.system,
    );
  }

  AuditResult _parseAuditResult(String resultString) {
    return AuditResult.values.firstWhere(
      (e) => e.name == resultString,
      orElse: () => AuditResult.failure,
    );
  }
}

/// Ballot token audit data model
@freezed
class BallotTokenAuditModel with _$BallotTokenAuditModel {
  const factory BallotTokenAuditModel({
    required String id,
    @JsonKey(name: 'encrypted_token_id') required String encryptedTokenId,
    @JsonKey(name: 'election_id') required String electionId,
    @JsonKey(name: 'generated_at') required DateTime generatedAt,
    @JsonKey(name: 'is_used') @Default(false) bool isUsed,
    @JsonKey(name: 'used_at') DateTime? usedAt,
    @JsonKey(name: 'voter_hash') required String voterHash,
    required String status, // Will be converted to/from enum
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    @JsonKey(name: 'verification_hash') String? verificationHash,
    @JsonKey(name: 'security_metadata') Map<String, dynamic>? securityMetadata,
  }) = _BallotTokenAuditModel;

  factory BallotTokenAuditModel.fromJson(Map<String, dynamic> json) =>
      _$BallotTokenAuditModelFromJson(json);

  const BallotTokenAuditModel._();

  BallotTokenAudit toEntity() {
    return BallotTokenAudit(
      id: id,
      encryptedTokenId: encryptedTokenId,
      electionId: electionId,
      generatedAt: generatedAt,
      isUsed: isUsed,
      usedAt: usedAt,
      voterHash: voterHash,
      status: _parseTokenStatus(status),
      expiresAt: expiresAt,
      verificationHash: verificationHash,
      securityMetadata: securityMetadata,
    );
  }

  factory BallotTokenAuditModel.fromEntity(BallotTokenAudit entity) {
    return BallotTokenAuditModel(
      id: entity.id,
      encryptedTokenId: entity.encryptedTokenId,
      electionId: entity.electionId,
      generatedAt: entity.generatedAt,
      isUsed: entity.isUsed,
      usedAt: entity.usedAt,
      voterHash: entity.voterHash,
      status: entity.status.name,
      expiresAt: entity.expiresAt,
      verificationHash: entity.verificationHash,
      securityMetadata: entity.securityMetadata,
    );
  }

  TokenStatus _parseTokenStatus(String statusString) {
    return TokenStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => TokenStatus.invalid,
    );
  }
}

/// Vote audit data model
@freezed
class VoteAuditModel with _$VoteAuditModel {
  const factory VoteAuditModel({
    required String id,
    @JsonKey(name: 'election_id') required String electionId,
    @JsonKey(name: 'position_id') required String positionId,
    @JsonKey(name: 'ballot_token_hash') required String ballotTokenHash,
    @JsonKey(name: 'cast_at') required DateTime castAt,
    @JsonKey(name: 'verification_hash') required String verificationHash,
    @JsonKey(name: 'is_valid') @Default(true) bool isValid,
    @JsonKey(name: 'validation_details') String? validationDetails,
    @Default(1.0) double weight,
    Map<String, dynamic>? metadata,
  }) = _VoteAuditModel;

  factory VoteAuditModel.fromJson(Map<String, dynamic> json) =>
      _$VoteAuditModelFromJson(json);

  const VoteAuditModel._();

  VoteAudit toEntity() {
    return VoteAudit(
      id: id,
      electionId: electionId,
      positionId: positionId,
      ballotTokenHash: ballotTokenHash,
      castAt: castAt,
      verificationHash: verificationHash,
      isValid: isValid,
      validationDetails: validationDetails,
      weight: weight,
      metadata: metadata,
    );
  }

  factory VoteAuditModel.fromEntity(VoteAudit entity) {
    return VoteAuditModel(
      id: entity.id,
      electionId: entity.electionId,
      positionId: entity.positionId,
      ballotTokenHash: entity.ballotTokenHash,
      castAt: entity.castAt,
      verificationHash: entity.verificationHash,
      isValid: entity.isValid,
      validationDetails: entity.validationDetails,
      weight: entity.weight,
      metadata: entity.metadata,
    );
  }
}

/// Chain integrity result data model
@freezed
class ChainIntegrityResultModel with _$ChainIntegrityResultModel {
  const factory ChainIntegrityResultModel({
    @JsonKey(name: 'is_valid') required bool isValid,
    @JsonKey(name: 'total_entries') required int totalEntries,
    @JsonKey(name: 'verified_entries') required int verifiedEntries,
    @JsonKey(name: 'corrupted_entries') @Default(0) int corruptedEntries,
    @JsonKey(name: 'corrupted_entry_ids') @Default([]) List<String> corruptedEntryIds,
    @JsonKey(name: 'first_corrupted_sequence') int? firstCorruptedSequence,
    @JsonKey(name: 'last_verified_sequence') int? lastVerifiedSequence,
    @JsonKey(name: 'verification_start_time') required DateTime verificationStartTime,
    @JsonKey(name: 'verification_end_time') required DateTime verificationEndTime,
    Map<String, dynamic>? details,
  }) = _ChainIntegrityResultModel;

  factory ChainIntegrityResultModel.fromJson(Map<String, dynamic> json) =>
      _$ChainIntegrityResultModelFromJson(json);

  const ChainIntegrityResultModel._();

  ChainIntegrityResult toEntity() {
    return ChainIntegrityResult(
      isValid: isValid,
      totalEntries: totalEntries,
      verifiedEntries: verifiedEntries,
      corruptedEntries: corruptedEntries,
      corruptedEntryIds: corruptedEntryIds,
      firstCorruptedSequence: firstCorruptedSequence,
      lastVerifiedSequence: lastVerifiedSequence,
      verificationStartTime: verificationStartTime,
      verificationEndTime: verificationEndTime,
      details: details,
    );
  }

  factory ChainIntegrityResultModel.fromEntity(ChainIntegrityResult entity) {
    return ChainIntegrityResultModel(
      isValid: entity.isValid,
      totalEntries: entity.totalEntries,
      verifiedEntries: entity.verifiedEntries,
      corruptedEntries: entity.corruptedEntries,
      corruptedEntryIds: entity.corruptedEntryIds,
      firstCorruptedSequence: entity.firstCorruptedSequence,
      lastVerifiedSequence: entity.lastVerifiedSequence,
      verificationStartTime: entity.verificationStartTime,
      verificationEndTime: entity.verificationEndTime,
      details: entity.details,
    );
  }
}