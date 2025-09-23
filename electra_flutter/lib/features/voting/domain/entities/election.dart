import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'election.freezed.dart';
part 'election.g.dart';

/// Election status enumeration
enum ElectionStatus {
  /// Election is scheduled but not yet active
  scheduled,
  
  /// Election is currently active and accepting votes
  active,
  
  /// Election has ended but results not yet published
  ended,
  
  /// Election results have been published
  completed,
  
  /// Election has been cancelled
  cancelled,
}

/// Election entity representing a voting election
///
/// Contains all information about an election including timing,
/// description, and current status for voting purposes.
@freezed
class Election with _$Election {
  const factory Election({
    /// Unique identifier for the election
    required String id,
    
    /// Title of the election
    required String title,
    
    /// Detailed description of the election
    required String description,
    
    /// Election start date and time
    required DateTime startDate,
    
    /// Election end date and time
    required DateTime endDate,
    
    /// Current status of the election
    required ElectionStatus status,
    
    /// List of positions being contested
    required List<String> positions,
    
    /// Total number of registered voters
    required int totalVoters,
    
    /// Number of votes cast so far
    @Default(0) int votesCast,
    
    /// Whether the election allows anonymous voting
    @Default(true) bool allowsAnonymousVoting,
    
    /// Election rules and guidelines
    String? rules,
    
    /// URL to election banner/poster
    String? bannerUrl,
    
    /// Whether the election is featured/promoted
    @Default(false) bool isFeatured,
    
    /// Created timestamp
    DateTime? createdAt,
    
    /// Updated timestamp
    DateTime? updatedAt,
  }) = _Election;

  factory Election.fromJson(Map<String, dynamic> json) =>
      _$ElectionFromJson(json);
}

/// Election summary for dashboard views
@freezed
class ElectionSummary with _$ElectionSummary {
  const factory ElectionSummary({
    required String id,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required ElectionStatus status,
    required int totalVoters,
    @Default(0) int votesCast,
    String? bannerUrl,
  }) = _ElectionSummary;

  factory ElectionSummary.fromJson(Map<String, dynamic> json) =>
      _$ElectionSummaryFromJson(json);
}

/// Extension methods for Election
extension ElectionExtension on Election {
  /// Check if the election is currently active
  bool get isActive => status == ElectionStatus.active;
  
  /// Check if the election has ended
  bool get hasEnded => 
      status == ElectionStatus.ended || 
      status == ElectionStatus.completed;
  
  /// Get the voting progress percentage
  double get votingProgress => 
      totalVoters > 0 ? (votesCast / totalVoters) * 100 : 0;
  
  /// Get time remaining until election starts (if scheduled)
  Duration? get timeUntilStart {
    if (status == ElectionStatus.scheduled) {
      final now = DateTime.now();
      if (startDate.isAfter(now)) {
        return startDate.difference(now);
      }
    }
    return null;
  }
  
  /// Get time remaining until election ends (if active)
  Duration? get timeUntilEnd {
    if (status == ElectionStatus.active) {
      final now = DateTime.now();
      if (endDate.isAfter(now)) {
        return endDate.difference(now);
      }
    }
    return null;
  }
}