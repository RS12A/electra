import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'timetable_event.freezed.dart';
part 'timetable_event.g.dart';

/// Timetable event type enumeration
enum EventType {
  /// Election start event
  electionStart,
  
  /// Election end event
  electionEnd,
  
  /// Candidate registration deadline
  candidateRegistration,
  
  /// Voter registration deadline
  voterRegistration,
  
  /// Results announcement
  resultsAnnouncement,
  
  /// Campaign period
  campaignPeriod,
  
  /// System maintenance
  maintenance,
  
  /// General announcement event
  announcement,
}

/// Event status enumeration
enum EventStatus {
  /// Event is upcoming
  upcoming,
  
  /// Event is currently active/ongoing
  active,
  
  /// Event has completed
  completed,
  
  /// Event has been cancelled
  cancelled,
  
  /// Event has been postponed
  postponed,
}

/// Timetable event entity representing calendar events
///
/// Contains all information about an event including timing,
/// description, and related election information.
@freezed
class TimetableEvent with _$TimetableEvent {
  const factory TimetableEvent({
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
    bool isAllDay,
    String? color,
    String? iconUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TimetableEvent;

  factory TimetableEvent.fromJson(Map<String, dynamic> json) =>
      _$TimetableEventFromJson(json);

  const TimetableEvent._();

  /// Check if event is currently active
  bool get isActive {
    if (status != EventStatus.active) return false;
    
    final now = DateTime.now();
    if (endDateTime != null) {
      return now.isAfter(startDateTime) && now.isBefore(endDateTime!);
    }
    return now.isAfter(startDateTime);
  }

  /// Check if event is upcoming
  bool get isUpcoming {
    return status == EventStatus.upcoming && 
           DateTime.now().isBefore(startDateTime);
  }

  /// Check if event has ended
  bool get hasEnded {
    if (status == EventStatus.completed) return true;
    if (endDateTime != null) {
      return DateTime.now().isAfter(endDateTime!);
    }
    return false;
  }

  /// Get time until event starts (in minutes)
  int? get minutesUntilStart {
    if (!isUpcoming) return null;
    return startDateTime.difference(DateTime.now()).inMinutes;
  }

  /// Get time remaining in event (in minutes)
  int? get minutesRemaining {
    if (!isActive || endDateTime == null) return null;
    final remaining = endDateTime!.difference(DateTime.now()).inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// Get duration of event in minutes
  int? get durationInMinutes {
    if (endDateTime == null) return null;
    return endDateTime!.difference(startDateTime).inMinutes;
  }

  /// Get display string for time until start
  String get timeUntilStartDisplay {
    final minutes = minutesUntilStart;
    if (minutes == null) return '';
    
    if (minutes < 60) {
      return '${minutes}m';
    } else if (minutes < 1440) { // Less than 24 hours
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return remainingMinutes > 0 ? '${hours}h ${remainingMinutes}m' : '${hours}h';
    } else {
      final days = minutes ~/ 1440;
      final remainingHours = (minutes % 1440) ~/ 60;
      return remainingHours > 0 ? '${days}d ${remainingHours}h' : '${days}d';
    }
  }

  /// Get display string for time remaining
  String get timeRemainingDisplay {
    final minutes = minutesRemaining;
    if (minutes == null) return '';
    
    if (minutes < 60) {
      return '${minutes}m left';
    } else if (minutes < 1440) { // Less than 24 hours
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return remainingMinutes > 0 ? 
          '${hours}h ${remainingMinutes}m left' : '${hours}h left';
    } else {
      final days = minutes ~/ 1440;
      final remainingHours = (minutes % 1440) ~/ 60;
      return remainingHours > 0 ? 
          '${days}d ${remainingHours}h left' : '${days}d left';
    }
  }

  /// Get event color based on type
  String get defaultColor {
    if (color != null) return color!;
    
    switch (type) {
      case EventType.electionStart:
        return '#10B981'; // Green
      case EventType.electionEnd:
        return '#EF4444'; // Red
      case EventType.candidateRegistration:
        return '#3B82F6'; // Blue
      case EventType.voterRegistration:
        return '#8B5CF6'; // Purple
      case EventType.resultsAnnouncement:
        return '#F59E0B'; // Amber
      case EventType.campaignPeriod:
        return '#06B6D4'; // Cyan
      case EventType.maintenance:
        return '#6B7280'; // Gray
      case EventType.announcement:
        return '#EC4899'; // Pink
    }
  }

  /// Get icon for event type
  String get typeIcon {
    switch (type) {
      case EventType.electionStart:
        return 'play_circle_filled';
      case EventType.electionEnd:
        return 'stop_circle';
      case EventType.candidateRegistration:
        return 'person_add';
      case EventType.voterRegistration:
        return 'how_to_reg';
      case EventType.resultsAnnouncement:
        return 'announcement';
      case EventType.campaignPeriod:
        return 'campaign';
      case EventType.maintenance:
        return 'build';
      case EventType.announcement:
        return 'info';
    }
  }

  /// Check if event is election-related
  bool get isElectionRelated {
    return relatedElectionId != null || [
      EventType.electionStart,
      EventType.electionEnd,
      EventType.candidateRegistration,
      EventType.voterRegistration,
      EventType.resultsAnnouncement,
      EventType.campaignPeriod,
    ].contains(type);
  }
}

/// Calendar view type for displaying events
enum CalendarView {
  day,
  week,
  month,
  agenda,
}

/// Timetable summary for overview displays
@freezed
class TimetableSummary with _$TimetableSummary {
  const factory TimetableSummary({
    required int totalEvents,
    required int activeEvents,
    required int upcomingEvents,
    required Map<EventType, int> eventsByType,
    required List<TimetableEvent> todayEvents,
    required List<TimetableEvent> upcomingElections,
  }) = _TimetableSummary;

  factory TimetableSummary.fromJson(Map<String, dynamic> json) =>
      _$TimetableSummaryFromJson(json);
}