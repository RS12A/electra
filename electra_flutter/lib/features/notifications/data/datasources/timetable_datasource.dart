import '../models/timetable_event_model.dart';
import '../../domain/entities/timetable_event.dart';

/// Abstract remote data source for timetable API
abstract class TimetableRemoteDataSource {
  /// Get events from remote API
  Future<List<TimetableEventModel>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
    EventType? type,
    EventStatus? status,
    String? relatedElectionId,
  });

  /// Get event by ID from remote API
  Future<TimetableEventModel> getEventById(String id);

  /// Get events for specific date from remote API
  Future<List<TimetableEventModel>> getEventsForDate(DateTime date);

  /// Get active events from remote API
  Future<List<TimetableEventModel>> getActiveEvents();

  /// Get upcoming events from remote API
  Future<List<TimetableEventModel>> getUpcomingEvents({
    int? limit,
    Duration? withinDuration,
  });

  /// Create event on remote API
  Future<TimetableEventModel> createEvent({
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

  /// Update event on remote API
  Future<TimetableEventModel> updateEvent({
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

  /// Delete event on remote API
  Future<void> deleteEvent(String id);

  /// Get timetable summary from remote API
  Future<TimetableSummaryModel> getTimetableSummary();

  /// Get events for election from remote API
  Future<List<TimetableEventModel>> getElectionEvents(String electionId);

  /// Subscribe to event notifications on remote API
  Future<void> subscribeToEventNotifications(
    String eventId,
    Duration notificationTime,
  );

  /// Unsubscribe from event notifications on remote API
  Future<void> unsubscribeFromEventNotifications(String eventId);

  /// Get calendar data from remote API
  Future<Map<String, List<TimetableEventModel>>> getCalendarData({
    required DateTime startDate,
    required DateTime endDate,
    CalendarView view = CalendarView.month,
  });

  /// Search events on remote API
  Future<List<TimetableEventModel>> searchEvents({
    required String query,
    EventType? type,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Check event conflicts on remote API
  Future<List<TimetableEventModel>> checkEventConflicts({
    required DateTime startDateTime,
    DateTime? endDateTime,
    String? excludeEventId,
  });

  /// Import events to remote API
  Future<List<TimetableEventModel>> importEvents(
    String calendarData,
    String format,
  );

  /// Export events from remote API
  Future<String> exportEvents({
    required DateTime startDate,
    required DateTime endDate,
    required String format,
    EventType? type,
  });
}

/// Abstract local data source for timetable caching
abstract class TimetableLocalDataSource {
  /// Get cached events
  Future<List<TimetableEventModel>> getCachedEvents({
    DateTime? startDate,
    DateTime? endDate,
    EventType? type,
    EventStatus? status,
  });

  /// Cache events locally
  Future<void> cacheEvents(List<TimetableEventModel> events);

  /// Get cached event by ID
  Future<TimetableEventModel?> getCachedEventById(String id);

  /// Cache single event
  Future<void> cacheEvent(TimetableEventModel event);

  /// Update cached event
  Future<void> updateCachedEvent(TimetableEventModel event);

  /// Remove cached event
  Future<void> removeCachedEvent(String id);

  /// Clear all cached events
  Future<void> clearCachedEvents();

  /// Get cached events for date
  Future<List<TimetableEventModel>> getCachedEventsForDate(DateTime date);

  /// Get cached active events
  Future<List<TimetableEventModel>> getCachedActiveEvents();

  /// Get cached upcoming events
  Future<List<TimetableEventModel>> getCachedUpcomingEvents();

  /// Get cached timetable summary
  Future<TimetableSummaryModel?> getCachedTimetableSummary();

  /// Cache timetable summary
  Future<void> cacheTimetableSummary(TimetableSummaryModel summary);

  /// Queue event change for offline sync
  Future<void> queueEventChangeForSync({
    required String action,
    required Map<String, dynamic> eventData,
  });

  /// Get queued event changes for sync
  Future<List<Map<String, dynamic>>> getQueuedEventChanges();

  /// Remove queued event change after successful sync
  Future<void> removeQueuedEventChange(String queueId);

  /// Clear all queued event changes
  Future<void> clearQueuedEventChanges();

  /// Save event notification subscription
  Future<void> saveEventNotificationSubscription(
    String eventId,
    Duration notificationTime,
  );

  /// Remove event notification subscription
  Future<void> removeEventNotificationSubscription(String eventId);

  /// Get event notification subscriptions
  Future<Map<String, Duration>> getEventNotificationSubscriptions();
}