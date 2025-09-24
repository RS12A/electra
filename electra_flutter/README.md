# Electra Flutter - Secure Digital Voting System

A production-grade Flutter frontend for the Electra secure digital voting system, built following Clean Architecture principles with KWASU university branding.

## 🏗 Architecture

This Flutter application follows Clean Architecture principles with a feature-based modular structure:

```
lib/
├── core/                          # Core application components
│   ├── di/                       # Dependency injection setup
│   ├── router/                   # Navigation and routing
│   ├── theme/                    # KWASU theming and branding
│   ├── network/                  # HTTP client and API services
│   ├── storage/                  # Local storage (Hive/Isar)
│   ├── offline/                  # Production-grade offline support system
│   │   ├── models/              # Queue items, sync config, network status
│   │   ├── services/            # Sync orchestrator, network monitor, handlers
│   │   ├── repositories/        # Encrypted queue repository
│   │   ├── encryption/          # AES-256-GCM encryption service
│   │   ├── providers/           # Riverpod state management
│   │   ├── widgets/             # Offline status & sync control UI
│   │   └── di/                  # Offline module dependency injection
│   └── error/                    # Error handling
├── features/                     # Feature modules
│   ├── auth/                     # Authentication (login, register, password recovery)
│   ├── voting/                   # Voting dashboard, cast vote, verification
│   ├── admin_dashboard/          # Electoral committee admin panel
│   ├── analytics/                # Reports and analytics dashboard
│   ├── notifications/            # System and election notifications with timetable
│   └── theme/                    # Theme management
├── shared/                       # Shared components
│   ├── constants/               # App constants and configuration
│   ├── extensions/              # Dart/Flutter extensions
│   ├── utils/                   # Utility functions and helpers
│   ├── theme/                   # KWASU theme system with neomorphic design
│   └── widgets/                 # Reusable UI components
└── main.dart                    # Application entry point
```

Each feature module follows Clean Architecture layers:
- **Presentation**: Pages, widgets, and state management (Riverpod)
- **Domain**: Business logic, entities, and use cases
- **Data**: Data sources, repositories, and models

## 🚀 Features

### 🔐 **Authentication & Security**
- **Multi-format Login**: Email, matriculation number, or staff ID
- **Secure Registration**: Role-based registration with validation
- **Password Recovery**: OTP-based password reset via email
- **Biometric Authentication**: Fingerprint and face ID support
- **JWT Token Management**: Automatic token refresh and secure storage
- **Encrypted Storage**: AES-256 encryption for sensitive data

### 🗳️ **Voting System**
- **Interactive Dashboard**: View active elections and voting status
- **Secure Vote Casting**: Multi-position election support with candidate profiles
- **Vote Verification**: Anonymous vote verification using cryptographic tokens
- **Offline Voting**: Cast votes offline with automatic sync when online
- **Real-time Updates**: Live election status and countdown timers

### 👔 **Admin Panel**
- **Electoral Committee Dashboard**: System overview and election monitoring
- **Election Management**: Create, edit, and manage elections
- **User Management**: Role-based access control
- **System Monitoring**: Health checks and audit logs

### 📊 **Analytics & Reporting**
- **Real-time Analytics**: Turnout metrics and participation tracking
- **Visual Reports**: Charts and graphs for election insights
- **Data Export**: CSV, PDF, and Excel export capabilities
- **Audit Trails**: Comprehensive logging and verification

### 🔔 **Notifications & Timetable System**

#### **Advanced Notifications**
- **Smart Categorization**: Elections, system, security, announcements, voting reminders, deadlines
- **Priority Levels**: Low, normal, high, critical with visual indicators and urgency animations
- **Interactive Actions**: Swipe-to-read, swipe-to-dismiss, custom notification actions
- **Rich Content**: Image support, metadata chips, expandable content for long messages
- **Real-time Updates**: Live notification streaming with offline queuing
- **Firebase Cloud Messaging**: Push notifications with topic subscriptions and deep linking
- **Advanced Filtering**: Filter by type, priority, status with search functionality
- **Bulk Operations**: Mark all as read, clear all notifications

#### **Interactive Timetable**
- **Multiple Calendar Views**: Month, week, and agenda views with smooth transitions
- **Event Management**: Elections, deadlines, voting periods, system maintenance
- **Countdown Timers**: Real-time countdowns for active elections with urgency indicators
- **Event Scheduling**: Create, edit, and manage election events
- **Smart Reminders**: Configurable notifications 1-24 hours before events
- **Color-coded Events**: Visual distinction by event type (elections=green, deadlines=orange, etc.)
- **Offline-first Support**: Local caching with background sync when online
- **Event Details**: Rich event information with location, description, and related election data

#### **Key Features**
- **Neomorphic Design**: Modern elevated UI following KWASU branding guidelines
- **Gesture Support**: Swipe gestures for quick actions and navigation
- **Accessibility**: Full screen reader support and keyboard navigation
- **Performance**: Optimized rendering with lazy loading and efficient animations
- **Cross-platform**: Consistent experience across iOS and Android

#### **Integration Points**
- **Backend APIs**: Connect with Election, Ballot, and Notifications services
- **Firebase FCM**: Secure push notification delivery with topic management
- **Deep Linking**: Navigate directly to relevant content from notifications
- **Sync Management**: Intelligent offline/online synchronization with conflict resolution

### 📡 **Production-Grade Offline Support**
- **Secure Queueing**: AES-256-GCM encrypted local storage for offline operations
- **Smart Sync**: Exponential backoff retry with intelligent conflict resolution
- **Operation Types**: Vote casting, auth refresh, profile updates, notification acknowledgments
- **Conflict Resolution**: Election votes → never overwrite/reject duplicates; Profile updates → latest wins
- **Network Monitoring**: Real-time connection quality assessment (offline/poor/moderate/good/excellent)
- **Batch Processing**: FIFO queue execution with rollback protection and priority handling
- **Status Indicators**: Real-time sync status with smooth animations and progress tracking
- **Background Sync**: Automatic synchronization when network conditions improve
- **Eventual Consistency**: Guarantees data consistency across devices and sessions
- **Security Features**: Encrypted payloads, integrity verification, secure key rotation
- **Performance**: Efficient batch processing with concurrent operation limits
- **Testing**: Comprehensive unit, integration, and widget tests for reliability

#### **Theme Architecture**
```
Theme System Architecture:
┌─────────────────────────────────────────────────────────────┐
│                    Theme Controller                         │
│  ┌─────────────────┐  ┌──────────────────────────────────┐  │
│  │ Theme State     │  │     Accessibility Settings      │  │
│  │ Management      │  │   (Motion, Contrast, Scale)     │  │
│  └─────────────────┘  └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Theme Variants                         │
│  ┌─────────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ KWASU Theme     │  │ Light Theme  │  │ Dark Theme    │  │
│  │ (Primary)       │  │              │  │               │  │
│  └─────────────────┘  └──────────────┘  └───────────────┘  │
│  ┌─────────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ High Contrast   │  │ Color System │  │ Typography    │  │
│  │ (Accessibility) │  │ & Palettes   │  │ & Spacing     │  │
│  └─────────────────┘  └──────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                  Component Library                          │
│  ┌─────────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ Neomorphic      │  │ Animated     │  │ Page Route    │  │
│  │ Components      │  │ Interactions │  │ Transitions   │  │
│  └─────────────────┘  └──────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

#### **Offline Architecture**
```
Offline Module Architecture:
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌─────────────────┐  ┌──────────────────────────────────┐  │
│  │ Status Widgets  │  │     Riverpod Providers          │  │
│  │ Sync Controls   │  │   (Global State Management)     │  │
│  └─────────────────┘  └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Service Layer                           │
│  ┌─────────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │ Sync            │  │ Network      │  │ Sync Handler  │  │
│  │ Orchestrator    │  │ Monitor      │  │ Service       │  │
│  └─────────────────┘  └──────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                  Data & Security Layer                      │
│  ┌─────────────────┐  ┌──────────────────────────────────┐  │
│  │ Encrypted       │  │        AES-256-GCM               │  │
│  │ Queue Repo      │  │     Encryption Service          │  │ 
│  └─────────────────┘  └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Storage Layer                            │
│  ┌─────────────────┐  ┌──────────────────────────────────┐  │
│  │ Isar Database   │  │    Flutter Secure Storage       │  │
│  │ (Queue Items)   │  │    (Encryption Keys)            │  │
│  └─────────────────┘  └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

#### **Sync Strategies**
- **Votes**: Never overwrite, reject duplicates to prevent double voting
- **Profile Updates**: Latest timestamp wins to ensure most recent data
- **Auth Tokens**: Local wins (newest token) for security freshness  
- **Notifications**: Merge/allow duplicates for comprehensive delivery
- **Timetable Events**: Latest wins with intelligent conflict detection

### 🎨 **Production-Grade Theming & Animation System**
- **Multi-Theme Support**: KWASU-first (primary), Light, Dark, and High-Contrast accessibility themes
- **Runtime Theme Switching**: Persistent theme preferences with encrypted local storage
- **Neomorphic Design**: Modern elevated UI components with soft shadows and depth variations
- **Accessibility Integration**: Automatic high-contrast mode, system font scaling, reduce motion support
- **Animation System**: Smooth screen transitions, micro-interactions, and Lottie animation support
- **Component Library**: Reusable neomorphic buttons, cards, inputs, switches under `/lib/ui/components/`
- **Developer Tools**: Theme showcase page for development and testing

### 🔔 **Legacy Notifications**
- **Real-time Alerts**: Election updates and system notifications
- **Categorized Notifications**: Elections, system, security alerts
- **Action Items**: Interactive notifications with quick actions
- **Push Notifications**: Background election reminders

### 🎨 **KWASU Branding**
- **Custom Theme**: KWASU university colors and typography
- **Responsive Design**: Adaptive layouts for mobile and tablet
- **Dark Mode**: System-wide dark theme support
- **Accessibility**: WCAG compliant design with screen reader support

## 🛠 Technology Stack

### **Core Framework**
- **Flutter 3.16+**: Cross-platform UI framework
- **Dart 3.1+**: Programming language

### **State Management & Architecture**
- **Riverpod 2.4**: Reactive state management
- **Get It 7.6**: Dependency injection
- **Injectable 2.3**: Code generation for DI
- **GoRouter 12.1**: Declarative routing

### **Networking & API**
- **Dio 5.4**: HTTP client with interceptors
- **Retrofit 4.0**: Type-safe REST API client
- **JSON Annotation**: Serialization support

### **Local Storage & Offline**
- **Hive 2.2**: Lightweight encrypted key-value storage
- **Isar 3.1**: High-performance local database
- **Flutter Secure Storage**: Encrypted credential storage
- **Path Provider**: File system access

### **Security & Encryption**
- **Encrypt 5.0**: AES encryption for sensitive data
- **Crypto 3.0**: Cryptographic operations
- **JWT Decoder**: Token parsing and validation

### **UI & Design**
- **Material 3**: Latest Material Design system
- **Custom KWASU Theme**: University branding
- **Flutter SVG**: Vector graphics support
- **Cached Network Image**: Optimized image loading
- **Shimmer**: Loading skeletons

### **Testing**
- **Flutter Test**: Unit and widget testing
- **Integration Test**: E2E testing
- **Mockito 5.4**: Mocking framework
- **Golden Tests**: UI regression testing

### **Code Quality**
- **Very Good Analysis**: Strict linting rules
- **Build Runner**: Code generation
- **Freezed**: Immutable data classes

## 📱 Screenshots & UI

The app features a modern, responsive design optimized for both mobile and tablet devices:

- **Authentication Flow**: Clean login/register with KWASU branding
- **Voting Dashboard**: Card-based election overview with status indicators
- **Vote Casting**: Step-by-step voting process with candidate profiles
- **Admin Panel**: Comprehensive management interface with analytics
- **Responsive Layout**: Adaptive design for different screen sizes

## 🚀 Getting Started

### Prerequisites
- Flutter 3.16.0 or higher
- Dart SDK 3.1.0 or higher
- Android Studio / VS Code with Flutter extensions
- iOS development tools (for iOS deployment)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/RS12A/electra.git
   cd electra/electra_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Configure environment**
   - Update `lib/shared/constants/app_constants.dart`
   - Set your backend API URL (replace `your_server_url_goes_here`)
   
5. **Run the app**
   ```bash
   flutter run
   ```

### Configuration

Update the following configuration files:

#### API Configuration
```dart
// lib/shared/constants/app_constants.dart
static const String baseUrl = 'https://your-api-server.com:8000';
```

#### Firebase Configuration (for Notifications)
1. **Add Firebase configuration files:**
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

2. **Update Firebase options:**
   ```dart
   // lib/firebase_options.dart
   // Generated from FlutterFire CLI - add your project configuration
   ```

3. **Configure notification channels (Android):**
   ```dart
   // Channels are automatically created by FCMService:
   // - election_notifications (High importance)
   // - system_notifications (Default importance)  
   // - security_notifications (Max importance)
   // - announcement_notifications (High importance)
   ```

#### Notification Preferences Configuration
```dart
// Default notification preferences
final defaultPreferences = <NotificationType, bool>{
  NotificationType.election: true,
  NotificationType.votingReminder: true,
  NotificationType.deadline: true, 
  NotificationType.security: true,
  NotificationType.system: false,
  NotificationType.announcement: true,
};
```

#### Asset Configuration
Add your university assets:
```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/images/kwasu_logo.png
    - assets/images/election_banner.png
  fonts:
    - family: KWASU
      fonts:
        - asset: assets/fonts/KWASU-Regular.ttf
        - asset: assets/fonts/KWASU-Bold.ttf
          weight: 700
```

## 📱 Notifications & Timetable Setup

### Quick Start
```dart
// Initialize FCM service
await FCMServiceProvider().initialize();

// Load notifications
ref.read(notificationProvider.notifier).loadNotifications();

// Load timetable events
ref.read(timetableProvider.notifier).loadEvents();

// Start countdown timers
ref.read(countdownProvider.notifier).startCountdowns();
```

### Usage Examples

#### Loading Notifications
```dart
// In a widget
final notificationState = ref.watch(notificationProvider);

// Load notifications with filters
await ref.read(notificationProvider.notifier).filterNotifications(
  types: {NotificationType.election, NotificationType.deadline},
  priority: NotificationPriority.high,
);

// Mark notification as read
await ref.read(notificationProvider.notifier).markNotificationAsRead(id);
```

#### Managing Timetable Events
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

#### Handling Push Notifications
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

### Event Flow Examples

#### Election Workflow
1. **Registration Opens** → Notification sent to all eligible users
2. **48 Hours Before Voting** → Voting reminder notifications
3. **Voting Period Starts** → Real-time countdown begins
4. **6 Hours Before Deadline** → Urgent reminder for non-voters
5. **Voting Ends** → Results announcement notification

#### System Maintenance Flow
1. **Maintenance Scheduled** → Advance notice to all users
2. **1 Hour Before** → Final warning notification
3. **Maintenance Begins** → System status notification
4. **Maintenance Complete** → Service restored notification

### API Integration

#### Notification Endpoints
```dart
// Get notifications with pagination
GET /api/notifications?page=1&limit=20&type=election&priority=high

// Mark notification as read
PATCH /api/notifications/{id}/read

// Subscribe to push notifications
POST /api/notifications/subscribe
{
  "fcm_token": "device_token",
  "topics": ["elections", "deadlines"]
}
```

#### Timetable Endpoints
```dart  
// Get events for date range
GET /api/timetable/events?start_date=2024-01-01&end_date=2024-01-31

// Create new event
POST /api/timetable/events
{
  "title": "Election Registration",
  "type": "election_start", 
  "start_datetime": "2024-01-15T09:00:00Z",
  "end_datetime": "2024-01-22T17:00:00Z"
}

// Subscribe to event reminders
POST /api/timetable/events/{id}/reminders
{
  "reminder_time": "1h"
}
```

## 📡 Offline Support Setup

### Quick Start
```dart
// Initialize offline module in main.dart
await OfflineModuleInitializer.initialize(
  isDevelopment: kDebugMode,
  isBatteryOptimized: false,
);

// Access offline operations in widgets
final offlineQueue = ref.read(offlineQueueProvider);

// Queue a vote for offline submission
await offlineQueue.queueVote(
  electionId: 'election-123',
  selections: {'president': 'candidate-1'},
  ballotToken: 'ballot-token-xyz',
  userId: 'user-456',
);
```

### Usage Examples

#### Monitoring Network Status
```dart
// Watch network connectivity
final networkStatus = ref.watch(offlineStateProvider.select(
  (state) => state.networkStatus,
));

// Check if device is online
final isConnected = ref.watch(isConnectedProvider);

// Check if sync is recommended
final canSync = ref.watch(syncRecommendedProvider);
```

#### Manual Sync Operations
```dart
// Start manual sync
final offlineNotifier = ref.read(offlineStateProvider.notifier);
await offlineNotifier.startManualSync();

// Sync specific operation types
await offlineNotifier.startManualSync(
  operationTypes: [QueueOperationType.vote],
);

// Sync high priority items only  
await offlineNotifier.startManualSync(
  priorities: [QueuePriority.high, QueuePriority.critical],
);
```

#### Queue Management
```dart
// Queue different operation types
final queueOps = ref.read(offlineQueueProvider);

// Queue authentication refresh
await queueOps.queueAuthRefresh(
  refreshToken: 'refresh-token',
  userId: 'user-id',
);

// Queue profile update
await queueOps.queueProfileUpdate(
  profileData: {'name': 'Updated Name'},
  userId: 'user-id',
);

// Queue notification acknowledgment
await queueOps.queueNotificationAck(
  notificationId: 'notification-id',
  userId: 'user-id',
);
```

#### UI Integration
```dart
// Display offline status indicator
OfflineStatusIndicator(
  showDetails: true,
  onTap: () => _showOfflineDetails(),
)

// Compact status for app bars
CompactOfflineStatusIndicator(
  onTap: () => _showSyncControls(),
)

// Full sync control widget
SyncControlWidget(
  showAdvancedControls: true,
)
```

### Configuration Options

#### Development Configuration
```dart
// Faster sync for development
await OfflineModuleConfig.configureDevelopment(GetIt.instance);

// Or use preset
await OfflineModuleInitializer.initialize(isDevelopment: true);
```

#### Production Configuration  
```dart
// Conservative settings for production
await OfflineModuleConfig.configureProduction(GetIt.instance);

// Custom sync configuration
final customConfig = SyncConfig(
  enabled: true,
  wifiOnly: false,
  maxBatchSize: 5,
  syncTimeout: Duration(seconds: 30),
  retryConfig: RetryConfig(
    maxRetries: 3,
    initialDelay: Duration(seconds: 2),
    backoffMultiplier: 2.0,
  ),
  conflictRules: SyncConfigPresets.getDefaultConflictRules(),
);

final syncOrchestrator = GetIt.instance<SyncOrchestratorService>();
syncOrchestrator.updateConfig(customConfig);
```

#### Battery Optimization
```dart
// Battery-optimized configuration
await OfflineModuleInitializer.initialize(isBatteryOptimized: true);

// This enables:
// - WiFi-only sync
// - Charging requirement
// - Longer sync intervals
// - Reduced concurrent operations
```

### Sync Strategies & Conflict Resolution

#### Vote Operations
```dart
// Votes use reject strategy - no duplicates allowed
ConflictRule(
  operationType: QueueOperationType.vote,
  strategy: ConflictResolution.reject,
  allowDuplicates: false,
)
```

#### Profile Updates
```dart  
// Profile updates use latest wins strategy
ConflictRule(
  operationType: QueueOperationType.profileUpdate,
  strategy: ConflictResolution.latestWins,
  allowDuplicates: false,
)
```

#### Custom Conflict Rules
```dart
final customRules = {
  QueueOperationType.vote: ConflictRule(
    operationType: QueueOperationType.vote,
    strategy: ConflictResolution.reject,
    timeout: Duration(seconds: 10),
  ),
  QueueOperationType.profileUpdate: ConflictRule(
    operationType: QueueOperationType.profileUpdate, 
    strategy: ConflictResolution.latestWins,
    timeout: Duration(seconds: 15),
  ),
};

final config = SyncConfig(
  conflictRules: customRules,
  // ... other settings
);
```

### Security Features

#### Encryption Management
```dart
// Key rotation (automatic monthly)
final encryptionService = GetIt.instance<OfflineEncryptionService>();

// Manual key rotation
await encryptionService.rotateKeys();

// Cleanup old keys
await encryptionService.cleanupOldKeys();

// Secure deletion
await encryptionService.secureDeleteKeys();
```

#### Data Integrity
- All queued operations are encrypted with AES-256-GCM
- Payload integrity verified with SHA-256 hashes
- Secure key storage using Flutter Secure Storage
- Automatic key rotation every 30 days
- Device fingerprinting for additional security

## 🧪 Testing

The application includes comprehensive test coverage for all notification and timetable functionality.

### Unit Tests
```bash
# Run all unit tests
flutter test

# Run specific feature tests
flutter test test/unit/features/notifications/
```

### Widget Tests
```bash
# Run all widget tests
flutter test test/widget/

# Run notification widget tests specifically
flutter test test/widget/features/notifications/presentation/widgets/
```

### Integration Tests
```bash
# Run all integration tests
flutter test test/integration/

# Run timetable integration tests
flutter test test/integration/timetable_integration_test.dart

# Run offline sync integration tests
flutter test test/integration/offline_sync_integration_test.dart
```

### Offline Module Tests

#### Unit Tests
```bash
# Run offline repository tests
flutter test test/unit/core/offline/repositories/

# Run encryption service tests  
flutter test test/unit/core/offline/encryption/

# Run sync orchestrator tests
flutter test test/unit/core/offline/services/
```

#### Integration Tests
```bash
# Test complete offline workflow
flutter test test/integration/offline_sync_integration_test.dart

# This tests:
# - Queue operations while offline
# - Network state transitions  
# - Automatic sync triggering
# - Conflict resolution
# - Batch processing
# - Retry mechanisms
```

#### Widget Tests
```bash
# Test offline UI components
flutter test test/widget/core/offline/

# Tests offline status indicators and sync controls
```

### Test Coverage Overview

#### Notification Card Tests (`notification_card_test.dart`)
- ✅ Notification display and formatting
- ✅ Interactive actions (mark as read, dismiss, delete)
- ✅ Swipe gesture functionality  
- ✅ Expand/collapse behavior for long messages
- ✅ Priority and type indicators
- ✅ Compact mode functionality
- ✅ Timestamp formatting
- ✅ Metadata display

#### Timetable Integration Tests (`timetable_integration_test.dart`)
- ✅ Timetable page navigation and interaction
- ✅ Calendar view switching (month/week/agenda)
- ✅ Event filtering and search functionality
- ✅ Countdown timer accuracy and display
- ✅ Event details modal presentation
- ✅ Pull-to-refresh functionality
- ✅ Empty state handling
- ✅ Date selection and navigation

#### Existing Test Coverage
- ✅ Authentication flow tests
- ✅ Voting system tests  
- ✅ Admin dashboard tests
- ✅ Core service tests

### Code Coverage
```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# View coverage report
open coverage/html/index.html
```

### Running Specific Test Suites
```bash
# Notification tests only
flutter test test/unit/features/notifications/ test/widget/features/notifications/

# Timetable tests only  
flutter test test/integration/timetable_integration_test.dart

# All notification & timetable tests
flutter test test/unit/features/notifications/ test/widget/features/notifications/ test/integration/timetable_integration_test.dart
```

## 📦 Build & Deployment

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS IPA
```bash
flutter build ipa --release
```

### Web Build
```bash
flutter build web --release
```

## 🔒 Security Considerations

### Data Protection
- All sensitive data encrypted with AES-256
- JWT tokens stored in secure storage
- Biometric authentication where available
- Certificate pinning for API requests

### Privacy
- No personal data stored in plain text
- Anonymous vote verification system
- Secure audit logging without PII
- GDPR compliant data handling

### Network Security
- HTTPS-only communication
- Request signing and verification
- Rate limiting and DDoS protection
- Token-based authentication

## 📊 Performance Optimizations

- **Lazy Loading**: Pages and images loaded on demand
- **Caching Strategy**: Intelligent API response caching
- **Image Optimization**: Compressed and cached network images
- **Database Indexing**: Optimized Isar database queries
- **Memory Management**: Proper disposal of resources
- **Bundle Size**: Code splitting and tree shaking

## 🔧 Development Workflow

### Code Generation
```bash
# Run code generation
flutter packages pub run build_runner build

# Watch for changes
flutter packages pub run build_runner watch
```

### Linting
```bash
flutter analyze
```

### Formatting
```bash
dart format .
```

## 📋 API Integration

The app integrates with the Django Electra backend API:

### Authentication Endpoints
- `POST /api/auth/login/` - User login
- `POST /api/auth/register/` - User registration
- `POST /api/auth/token/refresh/` - Token refresh
- `POST /api/auth/password-reset/` - Password recovery

### Election Endpoints
- `GET /api/elections/` - List elections
- `GET /api/elections/{id}/` - Election details
- `POST /api/ballots/request-token/` - Request ballot token

### Voting Endpoints
- `POST /api/votes/cast/` - Cast vote
- `POST /api/votes/verify/` - Verify vote
- `GET /api/votes/status/{token}/` - Vote status

### Admin Endpoints
- `GET /api/admin/dashboard/` - Admin dashboard
- `GET /api/analytics/turnout/` - Analytics data

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Dart/Flutter conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Write tests for new features
- Update documentation as needed

## 🔧 Troubleshooting

### Common Issues

#### Notifications Not Appearing
1. **Check notification permissions:**
   ```dart
   // Verify permissions are granted
   final notificationSettings = await FirebaseMessaging.instance.requestPermission();
   print('Permission granted: ${notificationSettings.authorizationStatus}');
   ```

2. **Verify FCM token registration:**
   ```dart
   final token = await FirebaseMessaging.instance.getToken();
   print('FCM Token: $token');
   ```

3. **Check notification channel setup (Android):**
   ```bash
   # Verify channels are created in Android settings
   # Settings > Apps > Electra > Notifications
   ```

#### Offline Sync Issues
1. **Check network connectivity:**
   ```dart
   final connectivity = ref.watch(networkStatusProvider);
   print('Network status: $connectivity');
   ```

2. **Verify sync queue status:**
   ```dart
   final syncState = ref.watch(syncProvider);
   print('Queued notifications: ${syncState.queuedNotifications}');
   print('Last sync: ${syncState.lastSyncTime}');
   ```

3. **Review error logs:**
   ```dart
   // Enable debug logging
   AppLogger.setLevel(LogLevel.debug);
   ```

#### Calendar Not Loading
1. **Check date range parameters:**
   ```dart
   // Ensure valid date ranges
   final startDate = DateTime.now().subtract(Duration(days: 30));
   final endDate = DateTime.now().add(Duration(days: 90));
   ```

2. **Verify API connectivity:**
   ```bash
   # Test timetable endpoint
   curl -H "Authorization: Bearer your_token" \
        "https://your-api.com/api/timetable/events"
   ```

3. **Review cached data validity:**
   ```dart
   // Clear cache if needed
   await ref.read(timetableProvider.notifier).clearCache();
   ```

#### Countdown Timers Not Updating
1. **Check system time accuracy:**
   ```dart
   print('System time: ${DateTime.now()}');
   print('Event time: ${event.startDateTime}');
   ```

2. **Verify timer lifecycle:**
   ```dart
   // Ensure timer is properly started
   ref.read(countdownProvider.notifier).startCountdowns();
   ```

#### Performance Issues
1. **Monitor memory usage:**
   ```dart
   // Check for memory leaks in animations
   @override
   void dispose() {
     _animationController.dispose();
     super.dispose();
   }
   ```

2. **Optimize image loading:**
   ```dart
   // Use cached network images
   CachedNetworkImage(imageUrl: notification.imageUrl)
   ```

### Debug Tools
```dart
// Enable debug logging for notifications
AppLogger.setLevel(LogLevel.debug);

// Check sync status
final syncState = ref.watch(syncProvider);
print('Queued notifications: ${syncState.queuedNotifications}');
print('Last sync: ${syncState.lastSyncTime}');

// Inspect notification state
final notifications = ref.watch(notificationProvider);
print('Total notifications: ${notifications.notifications.length}');
print('Unread count: ${notifications.summary?.unreadCount}');

// Monitor timetable events
final timetable = ref.watch(timetableProvider);
print('Events loaded: ${timetable.events.length}');
print('Active events: ${timetable.activeEvents.length}');
```

### Firebase Configuration Issues
1. **Verify google-services.json/GoogleService-Info.plist:**
   ```bash
   # Android - check file exists
   ls -la android/app/google-services.json
   
   # iOS - check file exists  
   ls -la ios/Runner/GoogleService-Info.plist
   ```

2. **Check Firebase project settings:**
   - Verify package name matches
   - Ensure FCM is enabled
   - Check API keys are valid

3. **Test FCM directly:**
   ```bash
   # Send test notification via Firebase Console
   # Project Settings > Cloud Messaging > Send test message
   ```

### Build Issues
1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter packages pub run build_runner build --delete-conflicting-outputs
   flutter run
   ```

2. **Check Flutter doctor:**
   ```bash
   flutter doctor -v
   ```

3. **Verify dependencies:**
   ```bash
   flutter pub deps
   ```

## 🎨 Theme & Animation Development Guide

### Quick Start with Theming

```dart
// Import the component library
import 'package:electra_flutter/ui/components/index.dart';

// Use neomorphic components
NeomorphicButtons.primary(
  onPressed: () => print('Hello KWASU!'),
  child: Text('Vote Now'),
)

// Access theme controller
final themeController = ref.watch(themeControllerProvider);
await themeController.changeTheme(AppThemeMode.dark);
```

### Theme Customization

#### 1. Adding New Themes
```dart
// Add to AppThemeMode enum in theme_config.dart
enum AppThemeMode {
  kwasu,
  light, 
  dark,
  highContrast,
  yourCustomTheme, // Add here
}

// Add color scheme in app_colors.dart
static ColorScheme _getYourCustomTheme() {
  return const ColorScheme.light(
    // Define your colors
  );
}
```

#### 2. Creating Custom Neomorphic Components
```dart
class CustomNeomorphicWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(currentThemeProvider);
    
    return NeomorphicCard(
      style: NeomorphicCardStyle.elevated,
      child: YourContent(),
    );
  }
}
```

#### 3. Adding Page Transitions
```dart
// Use built-in transitions
AppPageRoutes.slideTransition<void>(
  child: YourPage(),
  direction: SlideDirection.right,
)

// Or create custom transitions
PageRouteBuilder(
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return YourCustomTransition(child: child);
  },
)
```

### Animation System

#### 1. Respecting Accessibility Settings
```dart
// Always use the theme controller for duration
final duration = ref.watch(animationDurationProvider(
  AnimationConfig.microDuration
));

AnimatedContainer(
  duration: duration, // Automatically reduced if reduce motion is enabled
  child: child,
)
```

#### 2. Using Built-in Animations
```dart
// Press animation for buttons
AnimatedPressButton(
  onPressed: () {},
  child: YourWidget(),
)

// Shimmer loading
AnimatedShimmer(
  enabled: isLoading,
  child: YourContent(),
)

// Lottie animations
AppLottieAnimation(
  asset: 'assets/animations/voting_success.json',
  width: 200,
  height: 200,
)
```

### Testing Themes

#### 1. Theme Showcase
Run the theme showcase for development:
```dart
// Add to your development routes
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ThemeShowcase(),
));
```

#### 2. Golden Tests
```dart
testWidgets('golden test - KWASU theme', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeController._buildThemeData(AppThemeMode.kwasu),
      home: YourWidget(),
    ),
  );
  
  await expectLater(
    find.byType(YourWidget),
    matchesGoldenFile('golden/kwasu_theme.png'),
  );
});
```

#### 3. Accessibility Testing
```dart
testWidgets('respects reduce motion setting', (tester) async {
  // Test with reduce motion enabled
  final controller = ThemeController(mockStorage);
  await controller.setAccessibilitySettings(reduceMotion: true);
  
  final duration = controller.getAnimationDuration(Duration(milliseconds: 300));
  expect(duration, AnimationConfig.reducedMotionDuration);
});
```

### Best Practices

1. **Always use theme-aware colors**:
   ```dart
   // Good
   color: AppColors.getSurfaceColor(currentTheme)
   
   // Bad
   color: Colors.white
   ```

2. **Respect accessibility settings**:
   ```dart
   // Good
   duration: ref.watch(animationDurationProvider(defaultDuration))
   
   // Bad  
   duration: Duration(milliseconds: 300)
   ```

3. **Use semantic naming**:
   ```dart
   // Good  
   NeomorphicButtons.primary(onPressed: vote, child: Text('Cast Vote'))
   
   // Bad
   NeomorphicButton(style: NeomorphicButtonStyle.elevated, ...)
   ```

4. **Test all themes**:
   - Include golden tests for each theme variant
   - Test accessibility settings combinations
   - Verify animations work on low-end devices

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- **Email**: electoral@kwasu.edu.ng
- **Documentation**: See inline code documentation
- **Issues**: Create GitHub issue for bugs
- **Security**: Report security issues privately

## 🙏 Acknowledgments

- **KWASU Electoral Committee**: Requirements and testing
- **Flutter Community**: Amazing framework and ecosystem
- **Open Source Contributors**: Dependencies and inspiration

---

**Electra Flutter v1.0.0** - Secure Digital Voting for Modern Elections