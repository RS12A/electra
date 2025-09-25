import 'package:equatable/equatable.dart';

/// Candidate entity representing a candidate in an election
///
/// Contains all information needed to display a candidate including
/// their manifesto, photo, and optional video content for voters.
class Candidate extends Equatable {
  const Candidate({
    required this.id,
    required this.name,
    required this.department,
    required this.position,
    required this.manifesto,
    required this.level,
    required this.photoUrl,
    required this.votes,
    this.videoUrl,
    this.additionalInfo,
    this.electionId,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier for the candidate
  final String id;
  
  /// Full name of the candidate
  final String name;
  
  /// Department or faculty of the candidate
  final String department;
  
  /// Position the candidate is running for
  final String position;
  
  /// Candidate's manifesto or campaign message
  final String manifesto;
  
  /// Student level (e.g., "300", "400")
  final String level;
  
  /// URL to candidate's photo
  final String photoUrl;
  
  /// Current vote count
  final int votes;
  
  /// URL to candidate's campaign video (optional)
  final String? videoUrl;
  
  /// Additional candidate information
  final String? additionalInfo;
  
  /// Election ID this candidate belongs to
  final String? electionId;
  
  /// Whether the candidate is active/eligible
  final bool isActive;
  
  /// Created timestamp
  final DateTime? createdAt;
  
  /// Updated timestamp
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    name,
    department,
    position,
    manifesto,
    level,
    photoUrl,
    votes,
    videoUrl,
    additionalInfo,
    electionId,
    isActive,
    createdAt,
    updatedAt,
  ];

  /// Create a copy with updated values
  Candidate copyWith({
    String? id,
    String? name,
    String? department,
    String? position,
    String? manifesto,
    String? level,
    String? photoUrl,
    int? votes,
    String? videoUrl,
    String? additionalInfo,
    String? electionId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Candidate(
      id: id ?? this.id,
      name: name ?? this.name,
      department: department ?? this.department,
      position: position ?? this.position,
      manifesto: manifesto ?? this.manifesto,
      level: level ?? this.level,
      photoUrl: photoUrl ?? this.photoUrl,
      votes: votes ?? this.votes,
      videoUrl: videoUrl ?? this.videoUrl,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      electionId: electionId ?? this.electionId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create from JSON
  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'] as String,
      name: json['name'] as String,
      department: json['department'] as String,
      position: json['position'] as String,
      manifesto: json['manifesto'] as String,
      level: json['level'] as String,
      photoUrl: json['photoUrl'] as String,
      votes: json['votes'] as int? ?? 0,
      videoUrl: json['videoUrl'] as String?,
      additionalInfo: json['additionalInfo'] as String?,
      electionId: json['electionId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'position': position,
      'manifesto': manifesto,
      'level': level,
      'photoUrl': photoUrl,
      'votes': votes,
      'videoUrl': videoUrl,
      'additionalInfo': additionalInfo,
      'electionId': electionId,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Candidate summary for listing views
class CandidateSummary extends Equatable {
  const CandidateSummary({
    required this.id,
    required this.name,
    required this.position,
    required this.department,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String position;
  final String department;
  final String? photoUrl;

  @override
  List<Object?> get props => [id, name, position, department, photoUrl];

  factory CandidateSummary.fromJson(Map<String, dynamic> json) {
    return CandidateSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      position: json['position'] as String,
      department: json['department'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'department': department,
      'photoUrl': photoUrl,
    };
  }
}