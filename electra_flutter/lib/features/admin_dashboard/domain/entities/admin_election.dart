import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_election.freezed.dart';
part 'admin_election.g.dart';

/// Admin election entity with comprehensive management capabilities
///
/// Extended election entity specifically for administrative operations,
/// including creation, updating, candidate management, and monitoring.
@freezed
class AdminElection with _$AdminElection {
  const factory AdminElection({
    /// Unique identifier for the election
    required String id,
    
    /// Election title
    required String title,
    
    /// Detailed description of the election
    required String description,
    
    /// Election category/type
    required String category,
    
    /// Start date and time for voting
    required DateTime startDate,
    
    /// End date and time for voting
    required DateTime endDate,
    
    /// Current status of the election
    required ElectionStatus status,
    
    /// Total number of eligible voters
    @Default(0) int eligibleVoters,
    
    /// Total number of votes cast
    @Default(0) int votesCast,
    
    /// Positions/offices in this election
    @Default([]) List<ElectionPosition> positions,
    
    /// Election configuration settings
    ElectionConfig? config,
    
    /// Created by user ID
    required String createdBy,
    
    /// Last modified by user ID
    String? lastModifiedBy,
    
    /// Creation timestamp
    required DateTime createdAt,
    
    /// Last modification timestamp
    DateTime? updatedAt,
    
    /// Whether anonymous voting is enabled
    @Default(true) bool allowsAnonymousVoting,
    
    /// Whether the election allows write-in candidates
    @Default(false) bool allowsWriteIns,
    
    /// Whether voters can abstain from positions
    @Default(true) bool allowsAbstention,
    
    /// Minimum voter turnout required (percentage)
    @Default(0.0) double minimumTurnout,
    
    /// Election visibility (public/private)
    @Default(true) bool isPublic,
    
    /// Results publication status
    @Default(false) bool resultsPublished,
    
    /// Results data (if published)
    Map<String, dynamic>? results,
  }) = _AdminElection;

  factory AdminElection.fromJson(Map<String, dynamic> json) =>
      _$AdminElectionFromJson(json);
}

/// Election position/office entity
@freezed
class ElectionPosition with _$ElectionPosition {
  const factory ElectionPosition({
    /// Unique identifier for the position
    required String id,
    
    /// Position title (e.g., "President", "Secretary")
    required String title,
    
    /// Position description
    required String description,
    
    /// Maximum number of candidates that can be selected for this position
    @Default(1) int maxSelections,
    
    /// Minimum number of candidates that must be selected
    @Default(0) int minSelections,
    
    /// Display order in the ballot
    @Default(0) int displayOrder,
    
    /// Whether this position requires elevated permissions to vote
    @Default(false) bool requiresElevatedAccess,
    
    /// List of candidates for this position
    @Default([]) List<AdminCandidate> candidates,
  }) = _ElectionPosition;

  factory ElectionPosition.fromJson(Map<String, dynamic> json) =>
      _$ElectionPositionFromJson(json);
}

/// Admin candidate entity with media management
@freezed
class AdminCandidate with _$AdminCandidate {
  const factory AdminCandidate({
    /// Unique identifier for the candidate
    required String id,
    
    /// Full name of the candidate
    required String name,
    
    /// Department or faculty
    required String department,
    
    /// Position they're running for
    required String position,
    
    /// Candidate's manifesto
    required String manifesto,
    
    /// Student/Staff ID number
    String? idNumber,
    
    /// Email address
    String? email,
    
    /// Profile photo URL
    String? photoUrl,
    
    /// Campaign video URL
    String? videoUrl,
    
    /// Additional candidate information
    String? additionalInfo,
    
    /// Election ID this candidate belongs to
    required String electionId,
    
    /// Whether the candidate is active/eligible
    @Default(true) bool isActive,
    
    /// Display order in the ballot
    @Default(0) int displayOrder,
    
    /// Vote count (if results are published)
    @Default(0) int voteCount,
    
    /// Media files associated with candidate
    @Default([]) List<CandidateMedia> mediaFiles,
    
    /// Created by user ID
    required String createdBy,
    
    /// Last modified by user ID
    String? lastModifiedBy,
    
    /// Creation timestamp
    required DateTime createdAt,
    
    /// Last modification timestamp
    DateTime? updatedAt,
  }) = _AdminCandidate;

  factory AdminCandidate.fromJson(Map<String, dynamic> json) =>
      _$AdminCandidateFromJson(json);
}

/// Candidate media file entity
@freezed
class CandidateMedia with _$CandidateMedia {
  const factory CandidateMedia({
    /// Unique identifier for the media
    required String id,
    
    /// Media type (photo, video, document)
    required MediaType type,
    
    /// File name
    required String fileName,
    
    /// File URL (secure cloud storage)
    required String fileUrl,
    
    /// File size in bytes
    @Default(0) int fileSize,
    
    /// MIME type
    String? mimeType,
    
    /// Media title/caption
    String? title,
    
    /// Media description
    String? description,
    
    /// Whether this is the primary media (for photos)
    @Default(false) bool isPrimary,
    
    /// Upload timestamp
    required DateTime uploadedAt,
    
    /// Uploaded by user ID
    required String uploadedBy,
  }) = _CandidateMedia;

  factory CandidateMedia.fromJson(Map<String, dynamic> json) =>
      _$CandidateMediaFromJson(json);
}

/// Election configuration settings
@freezed
class ElectionConfig with _$ElectionConfig {
  const factory ElectionConfig({
    /// Whether to require voter verification
    @Default(true) bool requiresVerification,
    
    /// Whether to allow offline voting
    @Default(true) bool allowsOfflineVoting,
    
    /// Whether to send notifications
    @Default(true) bool enableNotifications,
    
    /// Whether to enable real-time results
    @Default(false) bool enableRealTimeResults,
    
    /// Voter eligibility criteria
    Map<String, dynamic>? eligibilityCriteria,
    
    /// Additional configuration options
    Map<String, dynamic>? additionalSettings,
  }) = _ElectionConfig;

  factory ElectionConfig.fromJson(Map<String, dynamic> json) =>
      _$ElectionConfigFromJson(json);
}

/// Election status enumeration
enum ElectionStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('scheduled') 
  scheduled,
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('suspended')
  suspended;

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case ElectionStatus.draft:
        return 'Draft';
      case ElectionStatus.scheduled:
        return 'Scheduled';
      case ElectionStatus.active:
        return 'Active';
      case ElectionStatus.completed:
        return 'Completed';
      case ElectionStatus.cancelled:
        return 'Cancelled';
      case ElectionStatus.suspended:
        return 'Suspended';
    }
  }

  /// Get color code for the status
  int get colorCode {
    switch (this) {
      case ElectionStatus.draft:
        return 0xFF6B7280; // Gray
      case ElectionStatus.scheduled:
        return 0xFF3B82F6; // Blue
      case ElectionStatus.active:
        return 0xFF10B981; // Green
      case ElectionStatus.completed:
        return 0xFF8B5CF6; // Purple
      case ElectionStatus.cancelled:
        return 0xFFEF4444; // Red
      case ElectionStatus.suspended:
        return 0xFFF59E0B; // Amber
    }
  }
}

/// Media type enumeration
enum MediaType {
  @JsonValue('photo')
  photo,
  @JsonValue('video')
  video,
  @JsonValue('document')
  document;

  /// Get display name for the media type
  String get displayName {
    switch (this) {
      case MediaType.photo:
        return 'Photo';
      case MediaType.video:
        return 'Video';
      case MediaType.document:
        return 'Document';
    }
  }
}