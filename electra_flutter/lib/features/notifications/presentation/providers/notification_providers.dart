import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection_container.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/timetable_event.dart';
import '../../domain/usecases/notification_usecases.dart';
import '../../domain/usecases/timetable_usecases.dart';
import 'notification_state.dart';

/// Provider for connectivity status
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Provider for network status
final networkStatusProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (result) => result != ConnectivityResult.none,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Notification use cases providers
final getNotificationsProvider = Provider<GetNotifications>((ref) => getIt<GetNotifications>());
final getNotificationByIdProvider = Provider<GetNotificationById>((ref) => getIt<GetNotificationById>());
final markNotificationAsReadProvider = Provider<MarkNotificationAsRead>((ref) => getIt<MarkNotificationAsRead>());
final markNotificationAsDismissedProvider = Provider<MarkNotificationAsDismissed>((ref) => getIt<MarkNotificationAsDismissed>());
final markAllNotificationsAsReadProvider = Provider<MarkAllNotificationsAsRead>((ref) => getIt<MarkAllNotificationsAsRead>());
final deleteNotificationProvider = Provider<DeleteNotification>((ref) => getIt<DeleteNotification>());
final clearAllNotificationsProvider = Provider<ClearAllNotifications>((ref) => getIt<ClearAllNotifications>());
final getNotificationSummaryProvider = Provider<GetNotificationSummary>((ref) => getIt<GetNotificationSummary>());
final subscribeToPushNotificationsProvider = Provider<SubscribeToPushNotifications>((ref) => getIt<SubscribeToPushNotifications>());
final unsubscribeFromPushNotificationsProvider = Provider<UnsubscribeFromPushNotifications>((ref) => getIt<UnsubscribeFromPushNotifications>());
final updateNotificationPreferencesProvider = Provider<UpdateNotificationPreferences>((ref) => getIt<UpdateNotificationPreferences>());
final getNotificationPreferencesProvider = Provider<GetNotificationPreferences>((ref) => getIt<GetNotificationPreferences>());
final handlePushNotificationProvider = Provider<HandlePushNotification>((ref) => getIt<HandlePushNotification>());
final syncNotificationsProvider = Provider<SyncNotifications>((ref) => getIt<SyncNotifications>());

/// Timetable use cases providers
final getEventsProvider = Provider<GetEvents>((ref) => getIt<GetEvents>());
final getEventByIdProvider = Provider<GetEventById>((ref) => getIt<GetEventById>());
final getEventsForDateProvider = Provider<GetEventsForDate>((ref) => getIt<GetEventsForDate>());
final getActiveEventsProvider = Provider<GetActiveEvents>((ref) => getIt<GetActiveEvents>());
final getUpcomingEventsProvider = Provider<GetUpcomingEvents>((ref) => getIt<GetUpcomingEvents>());
final createEventProvider = Provider<CreateEvent>((ref) => getIt<CreateEvent>());
final updateEventProvider = Provider<UpdateEvent>((ref) => getIt<UpdateEvent>());
final deleteEventProvider = Provider<DeleteEvent>((ref) => getIt<DeleteEvent>());
final getTimetableSummaryProvider = Provider<GetTimetableSummary>((ref) => getIt<GetTimetableSummary>());
final getElectionEventsProvider = Provider<GetElectionEvents>((ref) => getIt<GetElectionEvents>());
final subscribeToEventNotificationsProvider = Provider<SubscribeToEventNotifications>((ref) => getIt<SubscribeToEventNotifications>());
final unsubscribeFromEventNotificationsProvider = Provider<UnsubscribeFromEventNotifications>((ref) => getIt<UnsubscribeFromEventNotifications>());
final getCalendarDataProvider = Provider<GetCalendarData>((ref) => getIt<GetCalendarData>());
final searchEventsProvider = Provider<SearchEvents>((ref) => getIt<SearchEvents>());
final syncEventsProvider = Provider<SyncEvents>((ref) => getIt<SyncEvents>());

/// Notification state notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier({
    required this.getNotifications,
    required this.markAsRead,
    required this.markAsDismissed,
    required this.markAllAsRead,
    required this.deleteNotification,
    required this.clearAllNotifications,
    required this.getNotificationSummary,
    required this.ref,
  }) : super(const NotificationState());

  final GetNotifications getNotifications;
  final MarkNotificationAsRead markAsRead;
  final MarkNotificationAsDismissed markAsDismissed;
  final MarkAllNotificationsAsRead markAllAsRead;
  final DeleteNotification deleteNotification;
  final ClearAllNotifications clearAllNotifications;
  final GetNotificationSummary getNotificationSummary;
  final Ref ref;

  /// Load notifications with optional filters
  Future<void> loadNotifications({
    int? limit = 20,
    int? offset,
    NotificationType? type,
    NotificationStatus? status,
    NotificationPriority? priority,
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    final result = await getNotifications(GetNotificationsParams(
      limit: limit,
      offset: offset ?? (isRefresh ? 0 : state.notifications.length),
      type: type,
      status: status,
      priority: priority,
    ));

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: failure.message ?? 'Failed to load notifications',
      ),
      (notifications) {
        List<Notification> updatedNotifications;
        if (isRefresh || offset == 0) {
          updatedNotifications = notifications;
        } else {
          updatedNotifications = [...state.notifications, ...notifications];
        }

        state = state.copyWith(
          isLoading: false,
          isRefreshing: false,
          notifications: updatedNotifications,
          filteredNotifications: updatedNotifications,
          error: null,
          hasMoreData: notifications.length >= (limit ?? 20),
          currentPage: isRefresh ? 1 : state.currentPage + 1,
        );

        _loadSummary();
      },
    );
  }

  /// Filter notifications by type and status
  void filterNotifications(String filter) {
    state = state.copyWith(selectedFilter: filter);

    List<Notification> filtered = state.notifications;

    switch (filter) {
      case 'Unread':
        filtered = state.notifications.where((n) => n.isUnread).toList();
        break;
      case 'Election':
        filtered = state.notifications.where((n) => n.type == NotificationType.election).toList();
        break;
      case 'System':
        filtered = state.notifications.where((n) => n.type == NotificationType.system).toList();
        break;
      case 'Security':
        filtered = state.notifications.where((n) => n.type == NotificationType.security).toList();
        break;
      case 'Critical':
        filtered = state.notifications.where((n) => n.isCritical).toList();
        break;
      default: // All
        filtered = state.notifications;
    }

    state = state.copyWith(filteredNotifications: filtered);
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead(String id) async {
    final result = await markAsRead(StringParams(id));
    
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message ?? 'Failed to mark as read');
        return false;
      },
      (updatedNotification) {
        _updateNotificationInState(updatedNotification);
        return true;
      },
    );
  }

  /// Mark notification as dismissed
  Future<bool> markNotificationAsDismissed(String id) async {
    final result = await markAsDismissed(StringParams(id));
    
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message ?? 'Failed to mark as dismissed');
        return false;
      },
      (updatedNotification) {
        _updateNotificationInState(updatedNotification);
        return true;
      },
    );
  }

  /// Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    state = state.copyWith(isLoading: true);
    
    final result = await markAllAsRead();
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message ?? 'Failed to mark all as read',
        );
        return false;
      },
      (_) {
        // Update all unread notifications to read in state
        final updatedNotifications = state.notifications.map((notification) {
          if (notification.status == NotificationStatus.unread) {
            // This would need a copyWith method on the Notification entity
            // For now, we'll reload the notifications
            return notification;
          }
          return notification;
        }).toList();

        state = state.copyWith(
          isLoading: false,
          notifications: updatedNotifications,
          filteredNotifications: updatedNotifications,
          error: null,
        );
        
        // Reload notifications to get updated state
        loadNotifications(isRefresh: true);
        return true;
      },
    );
  }

  /// Delete notification
  Future<bool> deleteNotificationById(String id) async {
    final result = await deleteNotification(StringParams(id));
    
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message ?? 'Failed to delete notification');
        return false;
      },
      (_) {
        _removeNotificationFromState(id);
        return true;
      },
    );
  }

  /// Clear all notifications
  Future<bool> clearAllNotifications() async {
    state = state.copyWith(isLoading: true);
    
    final result = await clearAllNotifications();
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message ?? 'Failed to clear all notifications',
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          notifications: [],
          filteredNotifications: [],
          error: null,
        );
        return true;
      },
    );
  }

  /// Load notification summary
  Future<void> _loadSummary() async {
    final result = await getNotificationSummary();
    
    result.fold(
      (failure) => state = state.copyWith(error: failure.message ?? 'Failed to load summary'),
      (summary) => state = state.copyWith(summary: summary, error: null),
    );
  }

  /// Update notification in state
  void _updateNotificationInState(Notification updatedNotification) {
    final updatedNotifications = state.notifications.map((notification) {
      return notification.id == updatedNotification.id ? updatedNotification : notification;
    }).toList();

    final updatedFiltered = state.filteredNotifications.map((notification) {
      return notification.id == updatedNotification.id ? updatedNotification : notification;
    }).toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      filteredNotifications: updatedFiltered,
    );
  }

  /// Remove notification from state
  void _removeNotificationFromState(String id) {
    final updatedNotifications = state.notifications.where((n) => n.id != id).toList();
    final updatedFiltered = state.filteredNotifications.where((n) => n.id != id).toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      filteredNotifications: updatedFiltered,
    );
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    await loadNotifications(isRefresh: true);
  }

  /// Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    if (!state.hasMoreData || state.isLoading) return;
    
    await loadNotifications(
      offset: state.notifications.length,
    );
  }
}

/// Notification state provider
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(
    getNotifications: ref.watch(getNotificationsProvider),
    markAsRead: ref.watch(markNotificationAsReadProvider),
    markAsDismissed: ref.watch(markNotificationAsDismissedProvider),
    markAllAsRead: ref.watch(markAllNotificationsAsReadProvider),
    deleteNotification: ref.watch(deleteNotificationProvider),
    clearAllNotifications: ref.watch(clearAllNotificationsProvider),
    getNotificationSummary: ref.watch(getNotificationSummaryProvider),
    ref: ref,
  );
});

/// Notification preferences state notifier
class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferencesState> {
  NotificationPreferencesNotifier({
    required this.getPreferences,
    required this.updatePreferences,
  }) : super(const NotificationPreferencesState());

  final GetNotificationPreferences getPreferences;
  final UpdateNotificationPreferences updatePreferences;

  /// Load notification preferences
  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await getPreferences();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message ?? 'Failed to load preferences',
      ),
      (preferences) => state = state.copyWith(
        isLoading: false,
        preferences: preferences,
        error: null,
        hasChanges: false,
      ),
    );
  }

  /// Update preference for a notification type
  void updatePreference(NotificationType type, bool enabled) {
    final updatedPreferences = Map<NotificationType, bool>.from(state.preferences);
    updatedPreferences[type] = enabled;
    
    state = state.copyWith(
      preferences: updatedPreferences,
      hasChanges: true,
    );
  }

  /// Save preferences to server
  Future<bool> savePreferences() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await updatePreferences(NotificationPreferencesParams(state.preferences));

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message ?? 'Failed to save preferences',
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          error: null,
          hasChanges: false,
        );
        return true;
      },
    );
  }

  /// Reset preferences to default
  void resetPreferences() {
    final defaultPreferences = <NotificationType, bool>{
      for (final type in NotificationType.values) type: true,
    };
    
    state = state.copyWith(
      preferences: defaultPreferences,
      hasChanges: true,
    );
  }
}

/// Notification preferences provider
final notificationPreferencesProvider = StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferencesState>((ref) {
  return NotificationPreferencesNotifier(
    getPreferences: ref.watch(getNotificationPreferencesProvider),
    updatePreferences: ref.watch(updateNotificationPreferencesProvider),
  );
});

/// Push notification state notifier
class PushNotificationNotifier extends StateNotifier<PushNotificationState> {
  PushNotificationNotifier({
    required this.subscribeToPush,
    required this.unsubscribeFromPush,
    required this.handlePushNotification,
  }) : super(const PushNotificationState());

  final SubscribeToPushNotifications subscribeToPush;
  final UnsubscribeFromPushNotifications unsubscribeFromPush;
  final HandlePushNotification handlePushNotification;

  /// Subscribe to push notifications
  Future<bool> subscribeToNotifications() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await subscribeToPush();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message ?? 'Failed to subscribe to notifications',
        );
        return false;
      },
      (subscriptionId) {
        state = state.copyWith(
          isLoading: false,
          isSubscribed: true,
          subscriptionId: subscriptionId,
          error: null,
        );
        return true;
      },
    );
  }

  /// Unsubscribe from push notifications
  Future<bool> unsubscribeFromNotifications() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await unsubscribeFromPush();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message ?? 'Failed to unsubscribe from notifications',
        );
        return false;
      },
      (_) {
        state = state.copyWith(
          isLoading: false,
          isSubscribed: false,
          subscriptionId: null,
          error: null,
        );
        return true;
      },
    );
  }

  /// Handle incoming push notification
  Future<Notification?> handleIncomingNotification(Map<String, dynamic> payload) async {
    final result = await handlePushNotification(PushNotificationParams(payload));

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message ?? 'Failed to handle push notification');
        return null;
      },
      (notification) {
        return notification;
      },
    );
  }
}

/// Push notification provider
final pushNotificationProvider = StateNotifierProvider<PushNotificationNotifier, PushNotificationState>((ref) {
  return PushNotificationNotifier(
    subscribeToPush: ref.watch(subscribeToPushNotificationsProvider),
    unsubscribeFromPush: ref.watch(unsubscribeFromPushNotificationsProvider),
    handlePushNotification: ref.watch(handlePushNotificationProvider),
  );
});