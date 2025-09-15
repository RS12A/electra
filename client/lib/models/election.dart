class Election {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int candidateCount;
  final bool hasUserVoted;
  final int? voteCount;

  Election({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.candidateCount,
    required this.hasUserVoted,
    this.voteCount,
  });

  factory Election.fromJson(Map<String, dynamic> json) {
    return Election(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'],
      candidateCount: json['candidateCount'],
      hasUserVoted: json['hasUserVoted'],
      voteCount: json['voteCount'],
    );
  }

  String get status {
    final now = DateTime.now();
    if (!isActive) return 'Inactive';
    if (now.isBefore(startDate)) return 'Upcoming';
    if (now.isAfter(endDate)) return 'Completed';
    return 'Ongoing';
  }

  bool get canVote {
    final now = DateTime.now();
    return isActive && 
           !hasUserVoted && 
           now.isAfter(startDate) && 
           now.isBefore(endDate);
  }
}