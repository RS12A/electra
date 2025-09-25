import 'package:equatable/equatable.dart';

/// Election status enumeration
enum ElectionStatus {
  /// Election is scheduled but not yet active
  scheduled,
  
  /// Election is upcoming (within notice period)
  upcoming,
  
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
class Election extends Equatable {
  const Election({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.positions,
    this.totalVoters = 0,
    this.votesCast = 0,
    this.allowsAnonymousVoting = true,
    this.rules,
    this.bannerUrl,
    this.isFeatured = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier for the election
  final String id;
  
  /// Title of the election
  final String title;
  
  /// Detailed description of the election
  final String description;
  
  /// Election start date and time
  final DateTime startDate;
  
  /// Election end date and time
  final DateTime endDate;
  
  /// Current status of the election
  final ElectionStatus status;
  
  /// List of positions being contested
  final List<String> positions;
  
  /// Total number of registered voters
  final int totalVoters;
  
  /// Number of votes cast so far
  final int votesCast;
  
  /// Whether the election allows anonymous voting
  final bool allowsAnonymousVoting;
  
  /// Election rules and guidelines
  final String? rules;
  
  /// URL to election banner/poster
  final String? bannerUrl;
  
  /// Whether the election is featured/promoted
  final bool isFeatured;
  
  /// Created timestamp
  final DateTime? createdAt;
  
  /// Updated timestamp
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    startDate,
    endDate,
    status,
    positions,
    totalVoters,
    votesCast,
    allowsAnonymousVoting,
    rules,
    bannerUrl,
    isFeatured,
    createdAt,
    updatedAt,
  ];

  /// Create a copy with updated values
  Election copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    ElectionStatus? status,
    List<String>? positions,
    int? totalVoters,
    int? votesCast,
    bool? allowsAnonymousVoting,
    String? rules,
    String? bannerUrl,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Election(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      positions: positions ?? this.positions,
      totalVoters: totalVoters ?? this.totalVoters,
      votesCast: votesCast ?? this.votesCast,
      allowsAnonymousVoting: allowsAnonymousVoting ?? this.allowsAnonymousVoting,
      rules: rules ?? this.rules,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create from JSON
  factory Election.fromJson(Map<String, dynamic> json) {
    return Election(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: ElectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ElectionStatus.scheduled,
      ),
      positions: (json['positions'] as List<dynamic>).cast<String>(),
      totalVoters: json['totalVoters'] as int? ?? 0,
      votesCast: json['votesCast'] as int? ?? 0,
      allowsAnonymousVoting: json['allowsAnonymousVoting'] as bool? ?? true,
      rules: json['rules'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
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
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.name,
      'positions': positions,
      'totalVoters': totalVoters,
      'votesCast': votesCast,
      'allowsAnonymousVoting': allowsAnonymousVoting,
      'rules': rules,
      'bannerUrl': bannerUrl,
      'isFeatured': isFeatured,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

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
    if (status == ElectionStatus.scheduled || status == ElectionStatus.upcoming) {
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

/// Election summary for dashboard views
class ElectionSummary extends Equatable {
  const ElectionSummary({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalVoters,
    this.votesCast = 0,
    this.bannerUrl,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final ElectionStatus status;
  final int totalVoters;
  final int votesCast;
  final String? bannerUrl;

  @override
  List<Object?> get props => [
    id,
    title,
    startDate,
    endDate,
    status,
    totalVoters,
    votesCast,
    bannerUrl,
  ];

  factory ElectionSummary.fromJson(Map<String, dynamic> json) {
    return ElectionSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: ElectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ElectionStatus.scheduled,
      ),
      totalVoters: json['totalVoters'] as int,
      votesCast: json['votesCast'] as int? ?? 0,
      bannerUrl: json['bannerUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.name,
      'totalVoters': totalVoters,
      'votesCast': votesCast,
      'bannerUrl': bannerUrl,
    };
  }
}