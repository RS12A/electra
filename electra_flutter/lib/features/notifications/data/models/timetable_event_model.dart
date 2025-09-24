import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/timetable_event.dart';

part 'timetable_event_model.g.dart';

/// Timetable event data model for API serialization/deserialization
///
/// This model extends the domain TimetableEvent entity with JSON serialization 
/// capabilities for API communication and local storage.
@JsonSerializable()
class TimetableEventModel extends TimetableEvent {
  const TimetableEventModel({
    required String id,
    required EventType type,
    required String title,
    required String description,
    required DateTime startDateTime,
    DateTime? endDateTime,
    required EventStatus status,
    String? location,
    String? relatedElectionId,
    String? relatedCandidateId,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool isAllDay = false,
    String? color,
    String? iconUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          id: id,
          type: type,
          title: title,
          description: description,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
          status: status,
          location: location,
          relatedElectionId: relatedElectionId,
          relatedCandidateId: relatedCandidateId,
          tags: tags,
          metadata: metadata,
          isAllDay: isAllDay,
          color: color,
          iconUrl: iconUrl,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  /// Create model from domain entity
  factory TimetableEventModel.fromEntity(TimetableEvent event) {
    return TimetableEventModel(
      id: event.id,
      type: event.type,
      title: event.title,
      description: event.description,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      status: event.status,
      location: event.location,
      relatedElectionId: event.relatedElectionId,
      relatedCandidateId: event.relatedCandidateId,
      tags: event.tags,
      metadata: event.metadata,
      isAllDay: event.isAllDay,
      color: event.color,
      iconUrl: event.iconUrl,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    );
  }

  /// Create model from JSON
  factory TimetableEventModel.fromJson(Map<String, dynamic> json) =>
      _$TimetableEventModelFromJson(json);

  /// Convert model to JSON
  Map<String, dynamic> toJson() => _$TimetableEventModelToJson(this);

  /// Convert to cache-friendly map for local storage
  Map<String, dynamic> toCacheMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'startDateTime': startDateTime.millisecondsSinceEpoch,
      'endDateTime': endDateTime?.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
      'location': location,
      'relatedElectionId': relatedElectionId,
      'relatedCandidateId': relatedCandidateId,
      'tags': tags,
      'metadata': metadata,
      'isAllDay': isAllDay,
      'color': color,
      'iconUrl': iconUrl,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Create from cache map
  factory TimetableEventModel.fromCacheMap(Map<String, dynamic> map) {
    return TimetableEventModel(
      id: map['id'] as String,
      type: EventType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'] as String,
      ),
      title: map['title'] as String,
      description: map['description'] as String,
      startDateTime: DateTime.fromMillisecondsSinceEpoch(
        map['startDateTime'] as int,
      ),
      endDateTime: map['endDateTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDateTime'] as int)
          : null,
      status: EventStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'] as String,
      ),
      location: map['location'] as String?,
      relatedElectionId: map['relatedElectionId'] as String?,
      relatedCandidateId: map['relatedCandidateId'] as String?,
      tags: (map['tags'] as List<dynamic>?)?.cast<String>(),
      metadata: map['metadata'] as Map<String, dynamic>?,
      isAllDay: map['isAllDay'] as bool? ?? false,
      color: map['color'] as String?,
      iconUrl: map['iconUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }

  /// Create event from election data
  factory TimetableEventModel.fromElectionData({
    required String electionId,
    required String electionTitle,
    required DateTime startDate,
    required DateTime endDate,
    EventType eventType = EventType.electionStart,
  }) {
    String title;
    String description;
    DateTime eventDateTime;
    
    switch (eventType) {
      case EventType.electionStart:
        title = '$electionTitle - Voting Opens';
        description = 'Voting period begins for $electionTitle';
        eventDateTime = startDate;
        break;
      case EventType.electionEnd:
        title = '$electionTitle - Voting Closes';
        description = 'Voting period ends for $electionTitle';
        eventDateTime = endDate;
        break;
      default:
        title = electionTitle;
        description = 'Event for $electionTitle';
        eventDateTime = startDate;
    }

    return TimetableEventModel(
      id: '${electionId}_${eventType.toString().split('.').last}',
      type: eventType,
      title: title,
      description: description,
      startDateTime: eventDateTime,
      endDateTime: eventType == EventType.electionStart ? endDate : null,
      status: EventStatus.upcoming,
      relatedElectionId: electionId,
      isAllDay: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Copy with updated fields
  TimetableEventModel copyWith({
    String? id,
    EventType? type,
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    EventStatus? status,
    String? location,
    String? relatedElectionId,
    String? relatedCandidateId,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool? isAllDay,
    String? color,
    String? iconUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimetableEventModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      status: status ?? this.status,
      location: location ?? this.location,
      relatedElectionId: relatedElectionId ?? this.relatedElectionId,
      relatedCandidateId: relatedCandidateId ?? this.relatedCandidateId,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      isAllDay: isAllDay ?? this.isAllDay,
      color: color ?? this.color,
      iconUrl: iconUrl ?? this.iconUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Timetable summary data model
@JsonSerializable()
class TimetableSummaryModel extends TimetableSummary {
  const TimetableSummaryModel({
    required int totalEvents,
    required int activeEvents,
    required int upcomingEvents,
    required Map<EventType, int> eventsByType,
    required List<TimetableEvent> todayEvents,
    required List<TimetableEvent> upcomingElections,
  }) : super(
          totalEvents: totalEvents,
          activeEvents: activeEvents,
          upcomingEvents: upcomingEvents,
          eventsByType: eventsByType,
          todayEvents: todayEvents,
          upcomingElections: upcomingElections,
        );

  /// Create model from domain entity
  factory TimetableSummaryModel.fromEntity(TimetableSummary summary) {
    return TimetableSummaryModel(
      totalEvents: summary.totalEvents,
      activeEvents: summary.activeEvents,
      upcomingEvents: summary.upcomingEvents,
      eventsByType: summary.eventsByType,
      todayEvents: summary.todayEvents,
      upcomingElections: summary.upcomingElections,
    );
  }

  /// Create model from JSON
  factory TimetableSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$TimetableSummaryModelFromJson(json);

  /// Convert model to JSON
  Map<String, dynamic> toJson() => _$TimetableSummaryModelToJson(this);
}