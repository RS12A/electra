import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../entities/timetable_event.dart';

/// Repository interface for timetable and calendar operations
///
/// Defines all timetable-related operations including CRUD operations,
/// event management, and offline synchronization.
abstract class TimetableRepository {
  /// Get events within a date range
  Future<Either<Failure, List<TimetableEvent>>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
    EventType? type,
    EventStatus? status,
    String? relatedElectionId,
  });

  /// Get event by ID
  Future<Either<Failure, TimetableEvent>> getEventById(String id);

  /// Get events for a specific date
  Future<Either<Failure, List<TimetableEvent>>> getEventsForDate(DateTime date);

  /// Get active events (currently happening)
  Future<Either<Failure, List<TimetableEvent>>> getActiveEvents();

  /// Get upcoming events
  Future<Either<Failure, List<TimetableEvent>>> getUpcomingEvents({
    int? limit,
    Duration? withinDuration,
  });

  /// Create new event (admin/system use)
  Future<Either<Failure, TimetableEvent>> createEvent({
    required EventType type,
    required String title,
    required String description,
    required DateTime startDateTime,
    DateTime? endDateTime,
    String? location,
    String? relatedElectionId,
    String? relatedCandidateId,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool isAllDay = false,
    String? color,
  });

  /// Update existing event
  Future<Either<Failure, TimetableEvent>> updateEvent({
    required String id,
    EventType? type,
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    EventStatus? status,
    String? location,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool? isAllDay,
    String? color,
  });

  /// Delete event
  Future<Either<Failure, void>> deleteEvent(String id);

  /// Get timetable summary
  Future<Either<Failure, TimetableSummary>> getTimetableSummary();

  /// Get events for election
  Future<Either<Failure, List<TimetableEvent>>> getElectionEvents(
    String electionId,
  );

  /// Subscribe to event notifications
  Future<Either<Failure, void>> subscribeToEventNotifications(
    String eventId,
    Duration notificationTime,
  );

  /// Unsubscribe from event notifications
  Future<Either<Failure, void>> unsubscribeFromEventNotifications(
    String eventId,
  );

  /// Get calendar view data
  Future<Either<Failure, Map<String, List<TimetableEvent>>>> getCalendarData({
    required DateTime startDate,
    required DateTime endDate,
    CalendarView view = CalendarView.month,
  });

  /// Search events
  Future<Either<Failure, List<TimetableEvent>>> searchEvents({
    required String query,
    EventType? type,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get cached events (offline support)
  Future<Either<Failure, List<TimetableEvent>>> getCachedEvents();

  /// Sync events with server
  Future<Either<Failure, void>> syncEvents();

  /// Queue event changes for offline sync
  Future<Either<Failure, void>> queueEventChange({
    required String action, // 'create', 'update', 'delete'
    required Map<String, dynamic> eventData,
  });

  /// Get queued event changes
  Future<Either<Failure, List<Map<String, dynamic>>>> getQueuedEventChanges();

  /// Clear queued event changes after successful sync
  Future<Either<Failure, void>> clearQueuedEventChanges();

  /// Check for event conflicts
  Future<Either<Failure, List<TimetableEvent>>> checkEventConflicts({
    required DateTime startDateTime,
    DateTime? endDateTime,
    String? excludeEventId,
  });

  /// Get recurring event instances
  Future<Either<Failure, List<TimetableEvent>>> getRecurringEventInstances({
    required String parentEventId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Import events from external calendar
  Future<Either<Failure, List<TimetableEvent>>> importEvents(
    String calendarData,
    String format, // 'ics', 'csv', etc.
  );

  /// Export events to external format
  Future<Either<Failure, String>> exportEvents({
    required DateTime startDate,
    required DateTime endDate,
    required String format,
    EventType? type,
  });
}