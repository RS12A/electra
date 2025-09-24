# Electra Notifications & Timetable Module

## Overview

This document provides comprehensive documentation for the production-grade notifications and timetable module implemented for the Electra secure digital voting system.

## Architecture

The module follows Clean Architecture principles with clear separation of concerns:

```
features/notifications/
├── domain/                    # Business logic layer
│   ├── entities/             # Core business objects
│   │   ├── notification.dart # Notification entity with full type system
│   │   └── timetable_event.dart # Event entity with calendar functionality
│   ├── repositories/         # Abstract interfaces
│   │   ├── notification_repository.dart
│   │   └── timetable_repository.dart
│   └── usecases/            # Business rules and operations
│       ├── notification_usecases.dart # 15+ notification use cases
│       └── timetable_usecases.dart   # 20+ timetable use cases
├── data/                     # Data access layer
│   ├── models/              # Data transfer objects
│   │   ├── notification_model.dart # JSON serialization + FCM support
│   │   └── timetable_event_model.dart # Calendar data serialization
│   ├── datasources/         # Remote and local data sources
│   │   ├── notification_remote_datasource_impl.dart # API integration
│   │   ├── notification_local_datasource_impl.dart  # Offline caching
│   │   ├── timetable_remote_datasource_impl.dart
│   │   └── timetable_local_datasource_impl.dart
│   └── repositories/        # Repository implementations
│       ├── notification_repository_impl.dart # Offline-first with sync
│       └── timetable_repository_impl.dart    # Event management
└── presentation/            # UI layer
    ├── providers/          # Riverpod state management
    │   ├── notification_providers.dart # Comprehensive state management
    │   ├── timetable_providers.dart   # Event and calendar states
    │   └── notification_state.dart    # State definitions
    ├── pages/              # Screen widgets
    │   ├── notifications_page.dart    # Enhanced notifications UI
    │   └── timetable_page.dart       # Calendar and events UI
    └── widgets/            # Reusable UI components
        ├── notification_card.dart     # Neomorphic notification cards
        ├── notification_filter_chip.dart
        ├── timetable_calendar.dart
        └── countdown_timer.dart
```

## Key Features Implemented

### ✅ Notifications System

#### Core Features
- **Push Notifications**: Full Firebase Cloud Messaging (FCM) integration
- **In-app Notifications**: Read/unread status, dismiss functionality
- **Notification Types**: Election, System, Security, Announcements, Voting Reminders, Deadlines
- **Priority Levels**: Low, Normal, High, Critical with visual indicators
- **Offline Support**: Local caching with background sync
- **Action Support**: Interactive notifications with custom actions

#### Advanced Features
- **Smart Filtering**: By type, status, priority with search functionality
- **Bulk Operations**: Mark all as read, clear all notifications
- **Notification Preferences**: Per-type subscription management
- **Real-time Updates**: Live notification streaming
- **Pagination**: Infinite scroll with efficient loading

### ✅ Timetable System

#### Core Features
- **Event Management**: Create, update, delete events with full CRUD operations
- **Event Types**: Election events, deadlines, campaign periods, maintenance, announcements
- **Calendar Views**: Day, week, month, agenda views
- **Event Status**: Upcoming, active, completed, cancelled, postponed
- **Offline-first**: Local caching with conflict resolution

#### Advanced Features
- **Countdown Timers**: Real-time countdowns for active events
- **Event Notifications**: Subscribe to event reminders with custom timing
- **Calendar Integration**: Import/export calendar data (ICS format)
- **Conflict Detection**: Automatic event overlap detection
- **Search & Filtering**: Advanced event search and filtering

### ✅ State Management (Riverpod)

#### Comprehensive State Architecture
- **NotificationState**: Loading, filtering, pagination states
- **TimetableState**: Calendar data, event management states
- **SyncState**: Offline queue management and sync status
- **CountdownState**: Real-time timer management
- **EventFormState**: Event creation/editing states

#### Provider Ecosystem
- **15+ Notification Providers**: Complete notification lifecycle management
- **20+ Timetable Providers**: Full event and calendar management
- **Connectivity Awareness**: Network-aware state management
- **Error Handling**: Comprehensive error states and recovery

### ✅ Offline-First Architecture

#### Data Persistence
- **Hive Integration**: Encrypted local caching
- **Isar Database**: High-performance local database for complex queries
- **Offline Queue**: Automatic queuing of operations when offline
- **Conflict Resolution**: Smart conflict resolution during sync

#### Sync Capabilities
- **Automatic Sync**: Background synchronization when online
- **Manual Sync**: User-initiated sync with progress indication
- **Queue Management**: View and manage pending offline operations
- **Retry Logic**: Exponential backoff for failed operations

### ✅ Firebase Cloud Messaging Integration

#### FCM Service Implementation
- **Message Handling**: Foreground, background, and terminated states
- **Local Notifications**: Rich local notifications with actions
- **Topic Subscriptions**: Election-specific and category-based subscriptions
- **Notification Channels**: Android notification channels for categorization
- **Deep Linking**: Navigation to relevant content from notifications

#### Security Features
- **Token Management**: Secure FCM token handling and refresh
- **Permission Handling**: Proper notification permission management
- **Data Encryption**: Encrypted notification payload handling

### ✅ Neomorphic UI Design

#### Design System
- **NeomorphicContainer**: Reusable neomorphic design component
- **KWASU Theme Integration**: University branding and color scheme
- **Dark/Light Mode**: Adaptive theming with proper contrast
- **Smooth Animations**: Subtle transitions and loading states

#### UI Components
- **NotificationCard**: Interactive notification display
- **FilterChips**: Elegant filtering interface
- **CountdownTimers**: Visual countdown displays
- **Calendar Views**: Modern calendar interface

### ✅ Testing Infrastructure

#### Test Coverage
- **Unit Tests**: Domain layer use cases and business logic
- **Widget Tests**: UI component testing
- **Integration Tests**: End-to-end workflow testing
- **Mock Infrastructure**: Comprehensive mocking for isolated testing

#### Test Structure
```
test/
├── unit/
│   └── features/notifications/
│       └── domain/usecases/
│           └── notification_usecases_test.dart
├── widget/
│   └── features/notifications/
│       └── presentation/widgets/
└── integration/
    └── notifications_flow_test.dart
```

## API Integration

### Notification Endpoints
```
GET    /api/notifications/              # Get notifications with filtering
GET    /api/notifications/{id}/         # Get specific notification
PATCH  /api/notifications/{id}/         # Update notification (mark read/dismissed)
DELETE /api/notifications/{id}/         # Delete notification
POST   /api/notifications/mark-all-read/    # Mark all as read
DELETE /api/notifications/clear-all/    # Clear all notifications
GET    /api/notifications/summary/      # Get notification summary
POST   /api/notifications/subscribe/    # Subscribe to push notifications
POST   /api/notifications/unsubscribe/  # Unsubscribe from push
GET    /api/notifications/preferences/  # Get notification preferences
PUT    /api/notifications/preferences/  # Update preferences
POST   /api/notifications/send/         # Send notification (admin)
```

### Timetable Endpoints
```
GET    /api/timetable/events/           # Get events with filtering
GET    /api/timetable/events/{id}/      # Get specific event
POST   /api/timetable/events/           # Create new event
PATCH  /api/timetable/events/{id}/      # Update event
DELETE /api/timetable/events/{id}/      # Delete event
GET    /api/timetable/events/active/    # Get active events
GET    /api/timetable/events/upcoming/  # Get upcoming events
GET    /api/timetable/summary/          # Get timetable summary
GET    /api/timetable/calendar/         # Get calendar data
GET    /api/timetable/events/search/    # Search events
POST   /api/timetable/events/{id}/subscribe/   # Subscribe to event notifications
DELETE /api/timetable/events/{id}/unsubscribe/ # Unsubscribe from event
```

## Configuration

### Firebase Setup
1. Add Firebase configuration files:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

2. Update `lib/firebase_options.dart` with your Firebase project configuration.

### API Configuration
Update `lib/shared/constants/app_constants.dart`:
```dart
static const String baseUrl = 'https://your-api-server.com:8000';
```

### Notification Configuration
Configure notification preferences in the app settings or use API defaults:
```dart
final defaultPreferences = <NotificationType, bool>{
  NotificationType.election: true,
  NotificationType.votingReminder: true,
  NotificationType.deadline: true,
  NotificationType.security: true,
  NotificationType.system: false,
  NotificationType.announcement: true,
};
```

## Usage Examples

### Loading Notifications
```dart
// In a widget
final notificationState = ref.watch(notificationProvider);

// Load notifications
ref.read(notificationProvider.notifier).loadNotifications();

// Filter notifications
ref.read(notificationProvider.notifier).filterNotifications('Election');

// Mark as read
await ref.read(notificationProvider.notifier).markNotificationAsRead(id);
```

### Managing Timetable Events
```dart
// Load events for current month
final now = DateTime.now();
await ref.read(timetableProvider.notifier).loadMonth(now);

// Create new event
await ref.read(eventFormProvider.notifier).createNewEvent(
  type: EventType.electionStart,
  title: 'Student Election Begins',
  description: 'Presidential election voting opens',
  startDateTime: DateTime.now().add(Duration(days: 1)),
  endDateTime: DateTime.now().add(Duration(days: 8)),
);

// Subscribe to event notifications
await ref.read(eventNotificationProvider.notifier)
    .subscribeToEventNotifications(eventId, Duration(hours: 1));
```

### Handling Push Notifications
```dart
// Listen to incoming notifications
FCMService.instance.onNotificationReceived.listen((notification) {
  // Handle foreground notification
  ref.read(notificationProvider.notifier).addNotification(notification);
});

// Handle notification taps
FCMService.instance.onNotificationOpened.listen((notification) {
  // Navigate to relevant screen
  context.go('/notifications/${notification.id}');
});
```

## Performance Considerations

### Caching Strategy
- **Aggressive Caching**: All data cached locally for offline access
- **Smart Invalidation**: Cache invalidation based on data freshness
- **Memory Management**: Efficient memory usage with pagination
- **Background Sync**: Minimal battery impact with optimized sync intervals

### Database Optimization
- **Indexed Queries**: Proper indexing for fast searches
- **Lazy Loading**: Load data as needed to reduce memory footprint
- **Batch Operations**: Efficient bulk operations for better performance

## Security Measures

### Data Protection
- **Encrypted Storage**: All local data encrypted using Flutter Secure Storage
- **Secure Transmission**: HTTPS with certificate pinning
- **Token Security**: Secure FCM token management and refresh
- **Input Validation**: Comprehensive validation of all user inputs

### Privacy
- **Notification Privacy**: Sensitive notifications only shown when authenticated
- **Data Minimization**: Only store necessary data locally
- **User Consent**: Proper consent management for push notifications

## Troubleshooting

### Common Issues

1. **Notifications Not Appearing**
   - Check notification permissions
   - Verify FCM token registration
   - Ensure proper notification channel setup

2. **Offline Sync Issues**
   - Check network connectivity
   - Verify sync queue status
   - Review error logs for failed operations

3. **Calendar Not Loading**
   - Check date range parameters
   - Verify API connectivity
   - Review cached data validity

### Debug Tools
```dart
// Enable debug logging
AppLogger.setLevel(LogLevel.debug);

// Check sync status
final syncState = ref.watch(syncProvider);
print('Queued notifications: ${syncState.queuedNotifications}');
print('Last sync: ${syncState.lastSyncTime}');

// Inspect notification state
final notifications = ref.watch(notificationProvider);
print('Total notifications: ${notifications.notifications.length}');
print('Unread count: ${notifications.summary?.unreadCount}');
```

## Future Enhancements

### Planned Features
- **Rich Notifications**: Media attachments and rich content
- **Smart Grouping**: Intelligent notification grouping
- **ML Recommendations**: AI-powered notification prioritization
- **Advanced Analytics**: Detailed engagement metrics
- **Webhook Support**: Real-time event streaming
- **Multi-language**: Internationalization support

### Performance Improvements
- **GraphQL Integration**: More efficient data fetching
- **Background App Refresh**: iOS background processing
- **Notification Scheduling**: Local notification scheduling
- **Advanced Caching**: Multi-level caching strategy

This comprehensive implementation provides a robust, scalable, and user-friendly notifications and timetable system that enhances the Electra voting platform's functionality while maintaining the highest standards of security and performance.