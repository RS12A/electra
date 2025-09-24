import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/timetable_event.dart';
import '../../domain/usecases/timetable_usecases.dart';
import 'notification_providers.dart';
import 'notification_state.dart';

/// Timetable state notifier
class TimetableNotifier extends StateNotifier<TimetableState> {
  TimetableNotifier({
    required this.getEvents,
    required this.getEventsForDate,
    required this.getActiveEvents,
    required this.getUpcomingEvents,
    required this.getTimetableSummary,
    required this.getCalendarData,
    required this.searchEvents,
    required this.ref,
  }) : super(const TimetableState()) {
    // Initialize with current date
    state = state.copyWith(selectedDate: DateTime.now(), currentView: CalendarView.month);
  }

  final GetEvents getEvents;
  final GetEventsForDate getEventsForDate;
  final GetActiveEvents getActiveEvents;
  final GetUpcomingEvents getUpcomingEvents;
  final GetTimetableSummary getTimetableSummary;
  final GetCalendarData getCalendarData;
  final SearchEvents searchEvents;
  final Ref ref;

  /// Load events with optional filters
  Future<void> loadEvents({
    DateTime? startDate,
    DateTime? endDate,
    EventType? type,
    EventStatus? status,
    String? relatedElectionId,
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    final result = await getEvents(GetEventsParams(
      startDate: startDate,
      endDate: endDate,
      type: type,
      status: status,
      relatedElectionId: relatedElectionId,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: failure.message ?? 'Failed to load events',
      ),
      (events) {
        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          events: events,
          filteredEvents: events,
          error: null,
        );

        _loadActiveAndUpcomingEvents();
        _loadSummary();
      },
    );
  }

  /// Load events for a specific date
  Future<void> loadEventsForDate(DateTime date) async {
    state = state.copyWith(isLoading: true, selectedDate: date, error: null);

    final result = await getEventsForDate(DateParams(date));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message ?? 'Failed to load events for date',
      ),
      (events) {
        state = state.copyWith(
          isLoading: false,
          events: events,
          filteredEvents: events,
          error: null,
        );
      },
    );
  }

  /// Load calendar data for a date range
  Future<void> loadCalendarData({
    required DateTime startDate,
    required DateTime endDate,
    CalendarView view = CalendarView.month,
  }) async {
    state = state.copyWith(isLoading: true, currentView: view, error: null);

    final result = await getCalendarData(GetCalendarDataParams(
      startDate: startDate,
      endDate: endDate,
      view: view,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message ?? 'Failed to load calendar data',
      ),
      (calendarData) {
        // Convert calendar data to events list
        final allEvents = <TimetableEvent>[];
        calendarData.values.forEach((events) {
          allEvents.addAll(events);
        });

        state = state.copyWith(
          isLoading: false,
          events: allEvents,
          filteredEvents: allEvents,
          calendarData: calendarData,
          error: null,
        );
      },
    );
  }

  /// Search events
  Future<void> searchEventsBy({
    required String query,
    EventType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (query.isEmpty) {
      state = state.copyWith(filteredEvents: state.events);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final result = await searchEvents(SearchEventsParams(
      query: query,
      type: type,
      startDate: startDate,
      endDate: endDate,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message ?? 'Failed to search events',
      ),
      (events) => state = state.copyWith(
        isLoading: false,
        filteredEvents: events,
        error: null,
      ),
    );
  }

  /// Filter events by type
  void filterEventsByType(EventType? type) {
    if (type == null) {
      state = state.copyWith(filteredEvents: state.events);
    } else {
      final filtered = state.events.where((event) => event.type == type).toList();
      state = state.copyWith(filteredEvents: filtered);
    }
  }

  /// Filter events by status
  void filterEventsByStatus(EventStatus? status) {
    if (status == null) {
      state = state.copyWith(filteredEvents: state.events);
    } else {
      final filtered = state.events.where((event) => event.status == status).toList();
      state = state.copyWith(filteredEvents: filtered);
    }
  }

  /// Set calendar view
  void setCalendarView(CalendarView view) {
    state = state.copyWith(currentView: view);
  }

  /// Set selected date
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    loadEventsForDate(date);
  }

  /// Load active and upcoming events
  Future<void> _loadActiveAndUpcomingEvents() async {
    // Load active events
    final activeResult = await getActiveEvents();
    activeResult.fold(
      (failure) => null, // Ignore errors for background loading
      (activeEvents) => state = state.copyWith(activeEvents: activeEvents),
    );

    // Load upcoming events
    final upcomingResult = await getUpcomingEvents(const GetUpcomingEventsParams(limit: 10));
    upcomingResult.fold(
      (failure) => null, // Ignore errors for background loading
      (upcomingEvents) => state = state.copyWith(upcomingEvents: upcomingEvents),
    );
  }

  /// Load timetable summary
  Future<void> _loadSummary() async {
    final result = await getTimetableSummary();
    
    result.fold(
      (failure) => state = state.copyWith(error: failure.message ?? 'Failed to load summary'),
      (summary) => state = state.copyWith(summary: summary, error: null),
    );
  }

  /// Refresh all timetable data
  Future<void> refreshTimetable() async {
    await loadEvents(isRefresh: true);
  }

  /// Load month data for calendar view
  Future<void> loadMonth(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    await loadCalendarData(
      startDate: startOfMonth,
      endDate: endOfMonth,
      view: CalendarView.month,
    );
  }

  /// Load week data for calendar view
  Future<void> loadWeek(DateTime week) async {
    final startOfWeek = week.subtract(Duration(days: week.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    await loadCalendarData(
      startDate: startOfWeek,
      endDate: endOfWeek,
      view: CalendarView.week,
    );
  }
}

/// Event form state notifier
class EventFormNotifier extends StateNotifier<EventFormState> {
  EventFormNotifier({
    required this.createEvent,
    required this.updateEvent,
    required this.deleteEvent,
    required this.ref,
  }) : super(const EventFormState());

  final CreateEvent createEvent;
  final UpdateEvent updateEvent;
  final DeleteEvent deleteEvent;
  final Ref ref;

  /// Set event for editing
  void setEditingEvent(TimetableEvent? event) {
    state = state.copyWith(editingEvent: event, hasUnsavedChanges: false);
  }

  /// Create new event
  Future<bool> createNewEvent({
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
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await createEvent(CreateEventParams(
      type: type,
      title: title,
      description: description,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      location: location,
      relatedElectionId: relatedElectionId,
      relatedCandidateId: relatedCandidateId,
      tags: tags,
      metadata: metadata,
      isAllDay: isAllDay,
      color: color,
    ));

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSaving: false,
          error: failure.message ?? 'Failed to create event',
        );
        return false;
      },
      (createdEvent) {
        state = state.copyWith(
          isSaving: false,
          editingEvent: createdEvent,
          error: null,
          hasUnsavedChanges: false,
        );
        
        // Refresh timetable data
        ref.read(timetableProvider.notifier).refreshTimetable();
        return true;
      },
    );
  }

  /// Update existing event
  Future<bool> updateExistingEvent({
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
  }) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await updateEvent(UpdateEventParams(
      id: id,
      type: type,
      title: title,
      description: description,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      status: status,
      location: location,
      tags: tags,
      metadata: metadata,
      isAllDay: isAllDay,
      color: color,
    ));

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSaving: false,
          error: failure.message ?? 'Failed to update event',
        );
        return false;
      },
      (updatedEvent) {
        state = state.copyWith(
          isSaving: false,
          editingEvent: updatedEvent,
          error: null,
          hasUnsavedChanges: false,
        );
        
        // Refresh timetable data
        ref.read(timetableProvider.notifier).refreshTimetable();
        return true;
      },
    );
  }

  /// Delete event
  Future<bool> deleteEventById(String id) async {
    state = state.copyWith(isSaving: true, error: null);

    final result = await deleteEvent(StringParams(id));

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSaving: false,
          error: failure.message ?? 'Failed to delete event',
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isSaving: false,
          editingEvent: null,
          error: null,
          hasUnsavedChanges: false,
        );
        
        // Refresh timetable data
        ref.read(timetableProvider.notifier).refreshTimetable();
        return true;
      },
    );
  }

  /// Mark form as having unsaved changes
  void markAsChanged() {
    if (!state.hasUnsavedChanges) {
      state = state.copyWith(hasUnsavedChanges: true);
    }
  }

  /// Clear form
  void clearForm() {
    state = const EventFormState();
  }
}

/// Event notifications state notifier
class EventNotificationNotifier extends StateNotifier<EventNotificationState> {
  EventNotificationNotifier({
    required this.subscribeToEvent,
    required this.unsubscribeFromEvent,
  }) : super(const EventNotificationState());

  final SubscribeToEventNotifications subscribeToEvent;
  final UnsubscribeFromEventNotifications unsubscribeFromEvent;

  /// Subscribe to event notifications
  Future<bool> subscribeToEventNotifications(String eventId, Duration notificationTime) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await subscribeToEvent(EventNotificationParams(
      eventId: eventId,
      notificationTime: notificationTime,
    ));

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message ?? 'Failed to subscribe to event notifications',
        );
        return false;
      },
      (_) {
        final updatedSubscriptions = Map<String, Duration>.from(state.subscriptions);
        updatedSubscriptions[eventId] = notificationTime;
        
        state = state.copyWith(
          isLoading: false,
          subscriptions: updatedSubscriptions,
          error: null,
        );
        return true;
      },
    );
  }

  /// Unsubscribe from event notifications
  Future<bool> unsubscribeFromEventNotifications(String eventId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await unsubscribeFromEvent(StringParams(eventId));

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message ?? 'Failed to unsubscribe from event notifications',
        );
        return false;
      },
      (_) {
        final updatedSubscriptions = Map<String, Duration>.from(state.subscriptions);
        updatedSubscriptions.remove(eventId);
        
        state = state.copyWith(
          isLoading: false,
          subscriptions: updatedSubscriptions,
          error: null,
        );
        return true;
      },
    );
  }

  /// Check if subscribed to event
  bool isSubscribedToEvent(String eventId) {
    return state.subscriptions.containsKey(eventId);
  }

  /// Get notification time for event
  Duration? getNotificationTime(String eventId) {
    return state.subscriptions[eventId];
  }
}

/// Countdown state notifier for active events
class CountdownNotifier extends StateNotifier<CountdownState> {
  CountdownNotifier() : super(const CountdownState()) {
    _startCountdownTimer();
  }

  Timer? _timer;

  /// Start countdown timer
  void _startCountdownTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdowns();
    });
  }

  /// Add event to countdown tracking
  void addEventCountdown(TimetableEvent event) {
    if (!event.isActive && !event.isUpcoming) return;

    final updatedCountdowns = Map<String, Duration>.from(state.activeCountdowns);
    final updatedEvents = Map<String, TimetableEvent>.from(state.countdownEvents);

    if (event.isActive && event.minutesRemaining != null) {
      updatedCountdowns[event.id] = Duration(minutes: event.minutesRemaining!);
    } else if (event.isUpcoming && event.minutesUntilStart != null) {
      updatedCountdowns[event.id] = Duration(minutes: event.minutesUntilStart!);
    }

    updatedEvents[event.id] = event;

    state = state.copyWith(
      activeCountdowns: updatedCountdowns,
      countdownEvents: updatedEvents,
      isActive: updatedCountdowns.isNotEmpty,
    );
  }

  /// Remove event from countdown tracking
  void removeEventCountdown(String eventId) {
    final updatedCountdowns = Map<String, Duration>.from(state.activeCountdowns);
    final updatedEvents = Map<String, TimetableEvent>.from(state.countdownEvents);

    updatedCountdowns.remove(eventId);
    updatedEvents.remove(eventId);

    state = state.copyWith(
      activeCountdowns: updatedCountdowns,
      countdownEvents: updatedEvents,
      isActive: updatedCountdowns.isNotEmpty,
    );
  }

  /// Update countdown timers
  void _updateCountdowns() {
    if (state.activeCountdowns.isEmpty) return;

    final updatedCountdowns = <String, Duration>{};
    final now = DateTime.now();

    state.activeCountdowns.forEach((eventId, remainingTime) {
      final event = state.countdownEvents[eventId];
      if (event == null) return;

      Duration? newRemaining;
      
      if (event.isActive && event.endDateTime != null) {
        final remaining = event.endDateTime!.difference(now);
        if (remaining.isNegative) {
          return; // Event has ended, remove from countdown
        }
        newRemaining = remaining;
      } else if (event.isUpcoming) {
        final remaining = event.startDateTime.difference(now);
        if (remaining.isNegative) {
          return; // Event has started, remove from countdown
        }
        newRemaining = remaining;
      }

      if (newRemaining != null && !newRemaining.isNegative) {
        updatedCountdowns[eventId] = newRemaining;
      }
    });

    state = state.copyWith(
      activeCountdowns: updatedCountdowns,
      isActive: updatedCountdowns.isNotEmpty,
    );
  }

  /// Get formatted countdown string
  String getFormattedCountdown(String eventId) {
    final duration = state.activeCountdowns[eventId];
    if (duration == null) return '';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Sync state notifier
class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier({
    required this.syncNotifications,
    required this.syncEvents,
  }) : super(const SyncState());

  final SyncNotifications syncNotifications;
  final SyncEvents syncEvents;

  /// Sync notifications with server
  Future<bool> syncNotificationsData() async {
    state = state.copyWith(isSyncingNotifications: true, lastSyncError: null);

    final result = await syncNotifications();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSyncingNotifications: false,
          lastSyncError: failure.message ?? 'Failed to sync notifications',
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isSyncingNotifications: false,
          lastSyncTime: DateTime.now(),
        );
        return true;
      },
    );
  }

  /// Sync events with server
  Future<bool> syncEventsData() async {
    state = state.copyWith(isSyncingEvents: true, lastSyncError: null);

    final result = await syncEvents();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSyncingEvents: false,
          lastSyncError: failure.message ?? 'Failed to sync events',
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isSyncingEvents: false,
          lastSyncTime: DateTime.now(),
        );
        return true;
      },
    );
  }

  /// Sync both notifications and events
  Future<void> syncAll() async {
    await Future.wait([
      syncNotificationsData(),
      syncEventsData(),
    ]);
  }
}

/// Timetable provider
final timetableProvider = StateNotifierProvider<TimetableNotifier, TimetableState>((ref) {
  return TimetableNotifier(
    getEvents: ref.watch(getEventsProvider),
    getEventsForDate: ref.watch(getEventsForDateProvider),
    getActiveEvents: ref.watch(getActiveEventsProvider),
    getUpcomingEvents: ref.watch(getUpcomingEventsProvider),
    getTimetableSummary: ref.watch(getTimetableSummaryProvider),
    getCalendarData: ref.watch(getCalendarDataProvider),
    searchEvents: ref.watch(searchEventsProvider),
    ref: ref,
  );
});

/// Event form provider
final eventFormProvider = StateNotifierProvider<EventFormNotifier, EventFormState>((ref) {
  return EventFormNotifier(
    createEvent: ref.watch(createEventProvider),
    updateEvent: ref.watch(updateEventProvider),
    deleteEvent: ref.watch(deleteEventProvider),
    ref: ref,
  );
});

/// Event notification provider
final eventNotificationProvider = StateNotifierProvider<EventNotificationNotifier, EventNotificationState>((ref) {
  return EventNotificationNotifier(
    subscribeToEvent: ref.watch(subscribeToEventNotificationsProvider),
    unsubscribeFromEvent: ref.watch(unsubscribeFromEventNotificationsProvider),
  );
});

/// Countdown provider
final countdownProvider = StateNotifierProvider<CountdownNotifier, CountdownState>((ref) {
  return CountdownNotifier();
});

/// Sync provider
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(
    syncNotifications: ref.watch(syncNotificationsProvider),
    syncEvents: ref.watch(syncEventsProvider),
  );
});

/// Combined overview provider
final overviewProvider = StateNotifierProvider<NotificationTimetableOverviewNotifier, NotificationTimetableOverviewState>((ref) {
  return NotificationTimetableOverviewNotifier(
    getNotificationSummary: ref.watch(getNotificationSummaryProvider),
    getTimetableSummary: ref.watch(getTimetableSummaryProvider),
    getNotifications: ref.watch(getNotificationsProvider),
    getUpcomingEvents: ref.watch(getUpcomingEventsProvider),
    getEventsForDate: ref.watch(getEventsForDateProvider),
  );
});

/// Overview state notifier
class NotificationTimetableOverviewNotifier extends StateNotifier<NotificationTimetableOverviewState> {
  NotificationTimetableOverviewNotifier({
    required this.getNotificationSummary,
    required this.getTimetableSummary,
    required this.getNotifications,
    required this.getUpcomingEvents,
    required this.getEventsForDate,
  }) : super(const NotificationTimetableOverviewState());

  final GetNotificationSummary getNotificationSummary;
  final GetTimetableSummary getTimetableSummary;
  final GetNotifications getNotifications;
  final GetUpcomingEvents getUpcomingEvents;
  final GetEventsForDate getEventsForDate;

  /// Load overview data
  Future<void> loadOverview() async {
    state = state.copyWith(isLoading: true, error: null);

    // Load notification summary
    final notificationSummaryResult = await getNotificationSummary();
    notificationSummaryResult.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (summary) => state = state.copyWith(notificationSummary: summary),
    );

    // Load timetable summary
    final timetableSummaryResult = await getTimetableSummary();
    timetableSummaryResult.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (summary) => state = state.copyWith(timetableSummary: summary),
    );

    // Load recent notifications
    final recentNotificationsResult = await getNotifications(const GetNotificationsParams(limit: 5));
    recentNotificationsResult.fold(
      (failure) => null, // Ignore error for recent notifications
      (notifications) => state = state.copyWith(recentNotifications: notifications),
    );

    // Load today's events
    final today = DateTime.now();
    final todayEventsResult = await getEventsForDate(DateParams(today));
    todayEventsResult.fold(
      (failure) => null, // Ignore error for today's events
      (events) => state = state.copyWith(todayEvents: events),
    );

    // Load upcoming elections
    final upcomingEventsResult = await getUpcomingEvents(const GetUpcomingEventsParams(limit: 5));
    upcomingEventsResult.fold(
      (failure) => null, // Ignore error for upcoming events
      (events) {
        final upcomingElections = events.where((e) => e.isElectionRelated).toList();
        state = state.copyWith(upcomingElections: upcomingElections);
      },
    );

    state = state.copyWith(isLoading: false);
  }

  /// Refresh overview data
  Future<void> refreshOverview() async {
    await loadOverview();
  }
}