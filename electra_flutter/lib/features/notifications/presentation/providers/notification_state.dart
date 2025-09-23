import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/notification.dart';
import '../../domain/entities/timetable_event.dart';

part 'notification_state.freezed.dart';

/// State for notification data loading and management
@freezed
class NotificationState with _$NotificationState {
  const factory NotificationState({
    @Default(false) bool isLoading,
    @Default(false) bool isRefreshing,
    @Default([]) List<Notification> notifications,
    @Default([]) List<Notification> filteredNotifications,
    NotificationSummary? summary,
    String? selectedFilter,
    String? error,
    @Default(false) bool hasMoreData,
    @Default(0) int currentPage,
  }) = _NotificationState;
}

/// State for notification preferences
@freezed
class NotificationPreferencesState with _$NotificationPreferencesState {
  const factory NotificationPreferencesState({
    @Default(false) bool isLoading,
    @Default({}) Map<NotificationType, bool> preferences,
    String? error,
    @Default(false) bool hasChanges,
  }) = _NotificationPreferencesState;
}

/// State for push notification subscription
@freezed
class PushNotificationState with _$PushNotificationState {
  const factory PushNotificationState({
    @Default(false) bool isLoading,
    @Default(false) bool isSubscribed,
    String? subscriptionId,
    String? fcmToken,
    String? error,
  }) = _PushNotificationState;
}

/// State for timetable events loading and management
@freezed
class TimetableState with _$TimetableState {
  const factory TimetableState({
    @Default(false) bool isLoading,
    @Default(false) bool isRefreshing,
    @Default([]) List<TimetableEvent> events,
    @Default([]) List<TimetableEvent> filteredEvents,
    @Default([]) List<TimetableEvent> activeEvents,
    @Default([]) List<TimetableEvent> upcomingEvents,
    TimetableSummary? summary,
    DateTime? selectedDate,
    CalendarView? currentView,
    String? error,
    @Default({}) Map<String, List<TimetableEvent>> calendarData,
  }) = _TimetableState;
}

/// State for timetable event creation/editing
@freezed
class EventFormState with _$EventFormState {
  const factory EventFormState({
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    TimetableEvent? editingEvent,
    @Default([]) List<TimetableEvent> conflictingEvents,
    String? error,
    @Default(false) bool hasUnsavedChanges,
  }) = _EventFormState;
}

/// State for event notifications subscription
@freezed
class EventNotificationState with _$EventNotificationState {
  const factory EventNotificationState({
    @Default(false) bool isLoading,
    @Default({}) Map<String, Duration> subscriptions,
    String? error,
  }) = _EventNotificationState;
}

/// State for notification sync operations
@freezed
class SyncState with _$SyncState {
  const factory SyncState({
    @Default(false) bool isSyncingNotifications,
    @Default(false) bool isSyncingEvents,
    @Default(0) int queuedNotifications,
    @Default(0) int queuedEvents,
    String? lastSyncError,
    DateTime? lastSyncTime,
  }) = _SyncState;
}

/// State for countdown timers
@freezed
class CountdownState with _$CountdownState {
  const factory CountdownState({
    @Default({}) Map<String, Duration> activeCountdowns,
    @Default({}) Map<String, TimetableEvent> countdownEvents,
    @Default(false) bool isActive,
  }) = _CountdownState;
}

/// Combined state for notifications and timetable overview
@freezed
class NotificationTimetableOverviewState with _$NotificationTimetableOverviewState {
  const factory NotificationTimetableOverviewState({
    @Default(false) bool isLoading,
    NotificationSummary? notificationSummary,
    TimetableSummary? timetableSummary,
    @Default([]) List<Notification> recentNotifications,
    @Default([]) List<TimetableEvent> todayEvents,
    @Default([]) List<TimetableEvent> upcomingElections,
    String? error,
  }) = _NotificationTimetableOverviewState;
}