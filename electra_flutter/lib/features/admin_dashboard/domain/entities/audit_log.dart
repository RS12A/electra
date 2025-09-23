import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

/// Audit log entry entity for tamper-proof logging
///
/// Contains comprehensive audit trail information with cryptographic
/// integrity verification and blockchain-style hash chaining.
@freezed
class AuditLog with _$AuditLog {
  const factory AuditLog({
    /// Unique identifier for the audit log entry
    required String id,
    
    /// Sequential entry number for chain verification
    required int sequenceNumber,
    
    /// SHA-512 hash of the previous audit entry
    String? previousHash,
    
    /// SHA-512 hash of this entry's content
    required String contentHash,
    
    /// RSA digital signature of the entry
    required String digitalSignature,
    
    /// Action that was audited
    required AuditAction action,
    
    /// Category of the audit entry
    required AuditCategory category,
    
    /// User ID who performed the action
    String? userId,
    
    /// User role at the time of action
    String? userRole,
    
    /// IP address of the user
    String? ipAddress,
    
    /// User agent string
    String? userAgent,
    
    /// Resource ID affected (election, candidate, etc.)
    String? resourceId,
    
    /// Type of resource affected
    String? resourceType,
    
    /// Detailed description of the action
    required String description,
    
    /// Action result (success/failure)
    required AuditResult result,
    
    /// Error message if action failed
    String? errorMessage,
    
    /// Additional metadata and context
    Map<String, dynamic>? metadata,
    
    /// Timestamp when action was performed
    required DateTime timestamp,
    
    /// Session ID when action was performed
    String? sessionId,
    
    /// Client application identifier
    String? clientId,
    
    /// API version used
    String? apiVersion,
    
    /// Request ID for tracing
    String? requestId,
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, dynamic> json) =>
      _$AuditLogFromJson(json);
}

/// Ballot token audit entry for anonymous vote tracking
@freezed
class BallotTokenAudit with _$BallotTokenAudit {
  const factory BallotTokenAudit({
    /// Unique identifier for the ballot token audit
    required String id,
    
    /// Encrypted ballot token ID (for privacy)
    required String encryptedTokenId,
    
    /// Election ID associated with the token
    required String electionId,
    
    /// Token generation timestamp
    required DateTime generatedAt,
    
    /// Whether token has been used
    @Default(false) bool isUsed,
    
    /// Timestamp when token was used (if used)
    DateTime? usedAt,
    
    /// Anonymized voter hash (SHA-512)
    required String voterHash,
    
    /// Token status
    required TokenStatus status,
    
    /// Token expiry timestamp
    DateTime? expiresAt,
    
    /// Verification code hash
    String? verificationHash,
    
    /// Additional security metadata
    Map<String, dynamic>? securityMetadata,
  }) = _BallotTokenAudit;

  factory BallotTokenAudit.fromJson(Map<String, dynamic> json) =>
      _$BallotTokenAuditFromJson(json);
}

/// Vote audit entry for anonymous vote logging
@freezed
class VoteAudit with _$VoteAudit {
  const factory VoteAudit({
    /// Unique identifier for the vote audit
    required String id,
    
    /// Election ID
    required String electionId,
    
    /// Position ID voted for
    required String positionId,
    
    /// Anonymized ballot token hash
    required String ballotTokenHash,
    
    /// Timestamp when vote was cast
    required DateTime castAt,
    
    /// Vote verification hash
    required String verificationHash,
    
    /// Whether vote is valid
    @Default(true) bool isValid,
    
    /// Validation result details
    String? validationDetails,
    
    /// Vote weight (usually 1.0)
    @Default(1.0) double weight,
    
    /// Additional vote metadata (anonymized)
    Map<String, dynamic>? metadata,
  }) = _VoteAudit;

  factory VoteAudit.fromJson(Map<String, dynamic> json) =>
      _$VoteAuditFromJson(json);
}

/// Chain integrity verification result
@freezed
class ChainIntegrityResult with _$ChainIntegrityResult {
  const factory ChainIntegrityResult({
    /// Whether the audit chain is valid
    required bool isValid,
    
    /// Total number of entries verified
    required int totalEntries,
    
    /// Number of verified entries
    required int verifiedEntries,
    
    /// Number of corrupted entries
    @Default(0) int corruptedEntries,
    
    /// List of corrupted entry IDs
    @Default([]) List<String> corruptedEntryIds,
    
    /// First corrupted sequence number (if any)
    int? firstCorruptedSequence,
    
    /// Last verified sequence number
    int? lastVerifiedSequence,
    
    /// Verification start time
    required DateTime verificationStartTime,
    
    /// Verification end time
    required DateTime verificationEndTime,
    
    /// Additional verification details
    Map<String, dynamic>? details,
  }) = _ChainIntegrityResult;

  factory ChainIntegrityResult.fromJson(Map<String, dynamic> json) =>
      _$ChainIntegrityResultFromJson(json);
}

/// Audit action enumeration
enum AuditAction {
  // Authentication actions
  @JsonValue('user_login')
  userLogin,
  @JsonValue('user_logout')
  userLogout,
  @JsonValue('user_register')
  userRegister,
  @JsonValue('password_change')
  passwordChange,
  @JsonValue('account_lockout')
  accountLockout,
  
  // Election management actions
  @JsonValue('election_create')
  electionCreate,
  @JsonValue('election_update')
  electionUpdate,
  @JsonValue('election_activate')
  electionActivate,
  @JsonValue('election_close')
  electionClose,
  @JsonValue('election_delete')
  electionDelete,
  
  // Candidate management actions
  @JsonValue('candidate_create')
  candidateCreate,
  @JsonValue('candidate_update')
  candidateUpdate,
  @JsonValue('candidate_delete')
  candidateDelete,
  @JsonValue('candidate_media_upload')
  candidateMediaUpload,
  
  // Voting actions
  @JsonValue('ballot_token_generate')
  ballotTokenGenerate,
  @JsonValue('vote_cast')
  voteCast,
  @JsonValue('vote_verify')
  voteVerify,
  
  // User management actions
  @JsonValue('user_activate')
  userActivate,
  @JsonValue('user_deactivate')
  userDeactivate,
  @JsonValue('user_suspend')
  userSuspend,
  @JsonValue('role_assign')
  roleAssign,
  @JsonValue('permission_grant')
  permissionGrant,
  
  // System actions
  @JsonValue('data_export')
  dataExport,
  @JsonValue('system_backup')
  systemBackup,
  @JsonValue('config_change')
  configChange,
  @JsonValue('security_alert')
  securityAlert,
  
  // Audit actions
  @JsonValue('audit_access')
  auditAccess,
  @JsonValue('chain_verification')
  chainVerification;

  /// Get display name for the action
  String get displayName {
    switch (this) {
      case AuditAction.userLogin:
        return 'User Login';
      case AuditAction.userLogout:
        return 'User Logout';
      case AuditAction.userRegister:
        return 'User Registration';
      case AuditAction.passwordChange:
        return 'Password Change';
      case AuditAction.accountLockout:
        return 'Account Lockout';
      case AuditAction.electionCreate:
        return 'Election Created';
      case AuditAction.electionUpdate:
        return 'Election Updated';
      case AuditAction.electionActivate:
        return 'Election Activated';
      case AuditAction.electionClose:
        return 'Election Closed';
      case AuditAction.electionDelete:
        return 'Election Deleted';
      case AuditAction.candidateCreate:
        return 'Candidate Created';
      case AuditAction.candidateUpdate:
        return 'Candidate Updated';
      case AuditAction.candidateDelete:
        return 'Candidate Deleted';
      case AuditAction.candidateMediaUpload:
        return 'Media Uploaded';
      case AuditAction.ballotTokenGenerate:
        return 'Ballot Token Generated';
      case AuditAction.voteCast:
        return 'Vote Cast';
      case AuditAction.voteVerify:
        return 'Vote Verified';
      case AuditAction.userActivate:
        return 'User Activated';
      case AuditAction.userDeactivate:
        return 'User Deactivated';
      case AuditAction.userSuspend:
        return 'User Suspended';
      case AuditAction.roleAssign:
        return 'Role Assigned';
      case AuditAction.permissionGrant:
        return 'Permission Granted';
      case AuditAction.dataExport:
        return 'Data Export';
      case AuditAction.systemBackup:
        return 'System Backup';
      case AuditAction.configChange:
        return 'Config Change';
      case AuditAction.securityAlert:
        return 'Security Alert';
      case AuditAction.auditAccess:
        return 'Audit Access';
      case AuditAction.chainVerification:
        return 'Chain Verification';
    }
  }
}

/// Audit category enumeration
enum AuditCategory {
  @JsonValue('authentication')
  authentication,
  @JsonValue('authorization')
  authorization,
  @JsonValue('election_management')
  electionManagement,
  @JsonValue('candidate_management')
  candidateManagement,
  @JsonValue('voting')
  voting,
  @JsonValue('user_management')
  userManagement,
  @JsonValue('system')
  system,
  @JsonValue('security')
  security,
  @JsonValue('data_access')
  dataAccess,
  @JsonValue('configuration')
  configuration;

  /// Get display name for the category
  String get displayName {
    switch (this) {
      case AuditCategory.authentication:
        return 'Authentication';
      case AuditCategory.authorization:
        return 'Authorization';
      case AuditCategory.electionManagement:
        return 'Election Management';
      case AuditCategory.candidateManagement:
        return 'Candidate Management';
      case AuditCategory.voting:
        return 'Voting';
      case AuditCategory.userManagement:
        return 'User Management';
      case AuditCategory.system:
        return 'System';
      case AuditCategory.security:
        return 'Security';
      case AuditCategory.dataAccess:
        return 'Data Access';
      case AuditCategory.configuration:
        return 'Configuration';
    }
  }
}

/// Audit result enumeration
enum AuditResult {
  @JsonValue('success')
  success,
  @JsonValue('failure')
  failure,
  @JsonValue('partial_success')
  partialSuccess,
  @JsonValue('unauthorized')
  unauthorized,
  @JsonValue('blocked')
  blocked;

  /// Get display name for the result
  String get displayName {
    switch (this) {
      case AuditResult.success:
        return 'Success';
      case AuditResult.failure:
        return 'Failure';
      case AuditResult.partialSuccess:
        return 'Partial Success';
      case AuditResult.unauthorized:
        return 'Unauthorized';
      case AuditResult.blocked:
        return 'Blocked';
    }
  }

  /// Get color code for the result
  int get colorCode {
    switch (this) {
      case AuditResult.success:
        return 0xFF10B981; // Green
      case AuditResult.failure:
        return 0xFFEF4444; // Red
      case AuditResult.partialSuccess:
        return 0xFFF59E0B; // Amber
      case AuditResult.unauthorized:
        return 0xFFEF4444; // Red
      case AuditResult.blocked:
        return 0xFF7C2D12; // Dark red
    }
  }
}

/// Token status enumeration
enum TokenStatus {
  @JsonValue('active')
  active,
  @JsonValue('used')
  used,
  @JsonValue('expired')
  expired,
  @JsonValue('revoked')
  revoked,
  @JsonValue('invalid')
  invalid;

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case TokenStatus.active:
        return 'Active';
      case TokenStatus.used:
        return 'Used';
      case TokenStatus.expired:
        return 'Expired';
      case TokenStatus.revoked:
        return 'Revoked';
      case TokenStatus.invalid:
        return 'Invalid';
    }
  }
}