import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'candidate.freezed.dart';
part 'candidate.g.dart';

/// Candidate entity representing a candidate in an election
///
/// Contains all information needed to display a candidate including
/// their manifesto, photo, and optional video content for voters.
@freezed
class Candidate with _$Candidate {
  const factory Candidate({
    /// Unique identifier for the candidate
    required String id,
    
    /// Full name of the candidate
    required String name,
    
    /// Department or faculty of the candidate
    required String department,
    
    /// Position the candidate is running for
    required String position,
    
    /// Candidate's manifesto or campaign message
    required String manifesto,
    
    /// URL to candidate's photo
    String? photoUrl,
    
    /// URL to candidate's campaign video (optional)
    String? videoUrl,
    
    /// Additional candidate information
    String? additionalInfo,
    
    /// Election ID this candidate belongs to
    required String electionId,
    
    /// Whether the candidate is active/eligible
    @Default(true) bool isActive,
    
    /// Created timestamp
    DateTime? createdAt,
    
    /// Updated timestamp
    DateTime? updatedAt,
  }) = _Candidate;

  factory Candidate.fromJson(Map<String, dynamic> json) =>
      _$CandidateFromJson(json);
}

/// Candidate summary for listing views
@freezed
class CandidateSummary with _$CandidateSummary {
  const factory CandidateSummary({
    required String id,
    required String name,
    required String position,
    required String department,
    String? photoUrl,
  }) = _CandidateSummary;

  factory CandidateSummary.fromJson(Map<String, dynamic> json) =>
      _$CandidateSummaryFromJson(json);
}