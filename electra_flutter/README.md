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
│   └── error/                    # Error handling
├── features/                     # Feature modules
│   ├── auth/                     # Authentication (login, register, password recovery)
│   ├── voting/                   # Voting dashboard, cast vote, verification
│   ├── admin_dashboard/          # Electoral committee admin panel
│   ├── analytics/                # Reports and analytics dashboard
│   ├── notifications/            # System and election notifications
│   └── theme/                    # Theme management
├── shared/                       # Shared components
│   ├── constants/               # App constants and configuration
│   ├── extensions/              # Dart/Flutter extensions
│   ├── utils/                   # Utility functions and helpers
│   └── widgets/                 # Reusable UI components
└── main.dart                    # Application entry point
```

Each feature module follows Clean Architecture layers:
- **Presentation**: Pages, widgets, and state management (Riverpod)
- **Domain**: Business logic, entities, and use cases
- **Data**: Data sources, repositories, and models

## 🚀 Features

## 🔐 Authentication System

The Electra Flutter app includes a comprehensive, production-grade authentication system with the following features:

### 🏗️ Architecture Overview

The authentication system follows Clean Architecture principles with three distinct layers:

#### Domain Layer
- **Entities**: `User`, `AuthState` - Core business objects
- **Use Cases**: `LoginUseCase`, `RegisterUseCase`, `PasswordRecoveryUseCase`, `BiometricAuthUseCase`, `LogoutUseCase`, `RefreshTokenUseCase`
- **Repository Interface**: `AuthRepository` - Defines contracts for data operations

#### Data Layer
- **Remote Data Source**: API communication with backend services
- **Local Data Source**: Secure local storage and offline caching
- **Repository Implementation**: Coordinates between remote and local data sources
- **DTOs**: Data transfer objects for API serialization

#### Presentation Layer
- **Providers**: Riverpod state management for authentication state
- **Pages**: Login, Registration, Password Recovery screens
- **Widgets**: Reusable neomorphic UI components

### 📱 Authentication Screens

#### 1. Login Screen (`LoginPage`)
- **Multi-format Login**: Supports email, matric number, or staff ID
- **Password Authentication**: Secure password input with visibility toggle
- **Biometric Authentication**: Fingerprint/Face ID support using `local_auth`
- **Remember Me**: Persistent login option
- **Validation**: Real-time form validation with user-friendly error messages
- **Offline Support**: Cached authentication for offline scenarios

**Features**:
- Neomorphic design with KWASU branding
- Smooth animations and transitions
- Accessibility support (screen readers, keyboard navigation)
- Loading states with progress indicators
- Error handling with contextual messages

#### 2. Registration Screen (`RegisterPage`)
- **Role-based Registration**: Separate flows for students and staff
- **3-Step Wizard Interface**:
  1. Role Selection (Student/Staff)
  2. Basic Information (credentials, ID validation)
  3. Additional Details (department, faculty, etc.)
- **Real-time Validation**: Field-by-field validation with immediate feedback
- **Password Strength Indicator**: Visual feedback on password security
- **University Email Verification**: Enforces `@kwasu.edu.ng` domain

**Validation Rules**:
- Students: Matric number format (ABC12345)
- Staff: Staff ID format (AB1234)  
- Password strength requirements (8+ chars, uppercase, lowercase, numbers, special characters)
- University email domain validation

#### 3. Password Recovery Screen (`PasswordRecoveryPage`)
- **4-Step Recovery Process**:
  1. Email Input
  2. OTP Verification (6-digit code)
  3. New Password Creation
  4. Success Confirmation
- **OTP Management**: 60-second resend countdown
- **Password Strength Validation**: Same criteria as registration
- **Email Integration**: Works with backend SMTP service

### 🔒 Security Features

#### Biometric Authentication
- **Device Compatibility**: Automatic detection of biometric capabilities
- **Secure Storage**: Biometric preferences stored securely
- **Fallback Options**: Password fallback when biometric fails
- **Setup Wizard**: Guided biometric enrollment process

#### Token Management
- **JWT Implementation**: Access and refresh token handling
- **Secure Storage**: Encrypted token storage using `flutter_secure_storage`
- **Automatic Refresh**: Background token refresh before expiration
- **Secure Cleanup**: Proper token cleanup on logout

#### Offline Authentication
- **Credential Caching**: Hashed password storage for offline access
- **Secure Hashing**: SHA-256 with salt for password storage
- **Offline Validation**: Local credential verification
- **Data Synchronization**: Automatic sync when connection restored

### 🎨 UI/UX Design

#### Neomorphic Design System
- **Visual Consistency**: Unified design language across all screens
- **Interactive Elements**: Pressed states and smooth transitions
- **Color Scheme**: KWASU-branded colors (green and gold)
- **Typography**: Custom KWASU font family

#### Accessibility Features
- **Screen Reader Support**: Semantic labels and announcements
- **Keyboard Navigation**: Full keyboard accessibility
- **High Contrast**: Support for accessibility color schemes
- **Focus Management**: Proper focus flow between elements

#### Responsive Design
- **Multi-device Support**: Optimized for phones and tablets
- **Dynamic Layouts**: Adaptive UI based on screen size
- **Touch Targets**: Appropriately sized interactive elements
- **Safe Areas**: Proper handling of notches and system UI

### 🧪 Testing Coverage

#### Unit Tests (`test/unit/auth/`)
- **Use Case Testing**: Comprehensive testing of business logic
- **Validation Testing**: Input validation and error scenarios
- **Repository Testing**: Data layer functionality
- **Mock Integration**: Proper mocking of dependencies

#### Widget Tests (`test/widget/auth/`)
- **UI Component Testing**: Individual widget functionality
- **Form Validation**: User input validation flows  
- **Navigation Testing**: Screen transitions and routing
- **Accessibility Testing**: Screen reader and keyboard support

#### Integration Tests (`test/integration/`)
- **End-to-End Flows**: Complete authentication workflows
- **API Integration**: Backend service communication
- **Offline Scenarios**: Network connectivity handling
- **Biometric Flows**: Biometric authentication testing

### 🔧 Configuration

#### Backend Integration
The authentication system integrates with the Django backend using these endpoints:

```dart
// API Configuration in lib/shared/constants/app_constants.dart
static const String baseUrl = 'https://your-api-server.com:8000';

// Authentication Endpoints
static const String loginEndpoint = '/auth/login/';
static const String registerEndpoint = '/auth/register/';
static const String passwordResetEndpoint = '/auth/password-reset/';
static const String tokenRefreshEndpoint = '/auth/token/refresh/';
```

#### Security Configuration
```dart
// Secure storage settings
const FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iOptions: IOSOptions(
    accessibility: IOSAccessibility.first_unlock_this_device,
  ),
)
```

### 🚀 Usage Examples

#### Basic Login
```dart
// Using the auth provider
final authNotifier = ref.read(authProvider.notifier);

await authNotifier.login(
  identifier: 'student@kwasu.edu.ng',
  password: 'securePassword123',
  rememberMe: true,
);
```

#### Biometric Login
```dart
// Check biometric availability
final biometricStatus = await ref.read(biometricStatusProvider.future);

if (biometricStatus['biometricsAvailable']) {
  await authNotifier.loginWithBiometrics();
}
```

#### Registration
```dart
await authNotifier.register(
  email: 'student@kwasu.edu.ng',
  password: 'SecurePass123!',
  passwordConfirm: 'SecurePass123!',
  fullName: 'John Doe',
  role: 'student',
  matricNumber: 'CSC12345',
);
```

### 🐛 Error Handling

The authentication system includes comprehensive error handling:

#### Network Errors
- Connection timeouts
- No internet connectivity
- Server unavailability
- Rate limiting

#### Validation Errors  
- Invalid input formats
- Password strength requirements
- Email domain validation
- Required field validation

#### Authentication Errors
- Invalid credentials
- Expired tokens
- Biometric failures
- Account lockouts

#### User-Friendly Messages
All errors are converted to user-friendly messages with actionable guidance:

```dart
// Example error handling
ref.listen<AuthState>(authProvider, (previous, next) {
  next.when(
    error: (message, code, validationErrors) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: KwasuColors.error,
        ),
      );
    },
    // ... other states
  );
});
```

### 📚 API Documentation

The authentication system connects to these backend endpoints:

#### Authentication Flow
1. **POST `/api/auth/register/`** - User registration
2. **POST `/api/auth/login/`** - User login  
3. **POST `/api/auth/logout/`** - User logout
4. **POST `/api/auth/token/refresh/`** - Refresh access token

#### Password Recovery Flow
1. **POST `/api/auth/password-reset/`** - Request OTP
2. **POST `/api/auth/password-reset-confirm/`** - Reset with OTP

#### Profile Management
- **GET `/api/auth/profile/`** - Get user profile
- **PUT `/api/auth/profile/`** - Update profile
- **POST `/api/auth/change-password/`** - Change password

### 🔄 State Management

The authentication system uses Riverpod for state management with the following providers:

#### Core Providers
- `authProvider`: Main authentication state
- `biometricStatusProvider`: Biometric capability status
- `passwordStrengthProvider`: Password strength validation
- `loginValidationProvider`: Login form validation
- `registrationValidationProvider`: Registration form validation

#### State Flow
```dart
AuthState.initial() → 
AuthState.loading() → 
AuthState.authenticated() | AuthState.error()
```

This comprehensive authentication system provides a secure, user-friendly, and accessible login experience for the Electra digital voting platform.
- **Multi-format Login**: Email, matriculation number, or staff ID
- **Secure Registration**: Role-based registration with validation
- **Password Recovery**: OTP-based password reset via email
- **Biometric Authentication**: Fingerprint and face ID support
- **JWT Token Management**: Automatic token refresh and secure storage
- **Encrypted Storage**: AES-256 encryption for sensitive data

### 🗳️ **Voting System**
- **Interactive Dashboard**: View active elections and voting status with neomorphic design
- **Candidate Listing**: Browse candidates with photos, manifestos, and optional campaign videos
- **Secure Vote Casting**: Multi-step voting process with encrypted ballot submission
- **Vote Confirmation**: Success screen with anonymous vote token for verification
- **Vote Verification**: Anonymous vote verification using cryptographic tokens
- **Offline Voting**: Cast votes offline with automatic sync when online
- **Real-time Updates**: Live election status and countdown timers

#### Voting Screens

##### 1. Voting Dashboard (`VotingDashboardPage`)
- **Welcome Section**: KWASU-branded welcome with security features overview
- **Active Elections**: List of ongoing and upcoming elections with status indicators
- **Election Cards**: Detailed election information with candidate counts and timing
- **Offline Votes Access**: Quick access to manage queued offline votes
- **Responsive Design**: Adapts to different screen sizes and orientations

**Features**:
- Neomorphic design with smooth animations
- Real-time election countdown timers
- Accessibility support with semantic labels
- Pull-to-refresh functionality
- KWASU branding with university colors

##### 2. Candidate Listing (`CandidateListingPage`)
- **Election Information**: Comprehensive election details with timing and status
- **Candidate Cards**: Expandable cards with candidate photos, manifestos, and videos
- **Interactive Elements**: Smooth expand/collapse animations for detailed view
- **Vote Button**: Direct access to vote casting for each candidate
- **Loading States**: Elegant loading and error states with retry functionality

**Features**:
- Cached network images for candidate photos
- Expandable candidate information sections
- Video preview indicators for campaign videos
- Staggered animations for candidate cards
- Full accessibility support

##### 3. Vote Casting (`VoteCastingPage`)
- **Vote Confirmation**: Detailed review of selected candidate before submission
- **Security Information**: Clear explanation of encryption and anonymity features
- **Visual Feedback**: Candidate photo and information display
- **Privacy Notice**: Explanation of vote anonymity and security measures
- **Loading Overlay**: Progress indication during vote encryption and submission

**Features**:
- End-to-end encryption visualization
- Ballot token validation before vote casting
- Automatic fallback to offline mode if network fails
- Scale animations for visual feedback
- Comprehensive security feature explanations

##### 4. Vote Confirmation (`VoteConfirmationPage`)
- **Success Animation**: Animated success indicator with pulse effects
- **Vote Summary**: Complete details of cast vote without compromising anonymity
- **Vote Token**: Anonymous token for later vote verification with copy functionality
- **Return Navigation**: Seamless return to dashboard with state cleanup
- **Verification Options**: Direct access to vote verification features

**Features**:
- Animated success sequences with elastic animations
- Vote token clipboard integration
- Offline vote queueing confirmation
- Thank you messaging with next election countdown
- Prevents accidental back navigation

##### 5. Offline Votes Management (`OfflineVotesPage`)
- **Queue Overview**: Display all offline votes waiting for submission
- **Submission Control**: Batch submit all offline votes when online
- **Status Tracking**: Individual vote status with error details
- **Queue Management**: Clear queue with confirmation dialogs
- **Sync Progress**: Real-time feedback during vote submission

**Features**:
- Detailed offline vote information
- Retry mechanisms for failed submissions
- Sync attempt tracking and error reporting
- Batch operations with progress indication
- Secure local vote storage

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

### 🔔 **Notifications**
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

## 🧪 Testing

The voting system includes comprehensive test coverage across all layers:

### Test Structure

```
test/
├── unit/                     # Unit tests
│   ├── voting/              # Voting use cases and domain logic
│   ├── auth/                # Authentication use cases
│   └── core/                # Core services
├── widget/                  # Widget tests  
│   ├── voting/              # Voting screens and components
│   ├── auth/                # Authentication screens
│   └── shared/              # Shared widgets
├── integration/             # Integration tests
│   ├── voting/              # End-to-end voting flows
│   └── auth/                # End-to-end auth flows
└── helpers/                 # Test utilities and mocks
```

### Voting System Tests

#### Unit Tests
- **Use Cases**: Complete testing of all voting use cases
  - `GetCandidatesUseCase`: Election and candidate data retrieval
  - `CastVoteUseCase`: Vote casting with validation and encryption
  - `VerifyVoteUseCase`: Anonymous vote verification
  - `QueueOfflineVoteUseCase`: Offline vote management
- **Repository**: Mock testing with various error scenarios
- **Security**: Encryption and token validation testing

#### Widget Tests
- **Candidate Listing**: UI interactions and data display
- **Vote Casting**: Form validation and user interactions
- **Vote Confirmation**: Success states and token management
- **Offline Votes**: Queue management and submission testing
- **Accessibility**: Screen reader and keyboard navigation testing

#### Integration Tests
- **Complete Voting Flow**: Dashboard → Candidate Selection → Vote Casting → Confirmation
- **Offline Scenarios**: Network failure handling and vote queueing
- **Error Handling**: Network errors, validation failures, and recovery
- **Accessibility**: End-to-end accessibility testing
- **State Persistence**: Vote token storage and retrieval

### Running Tests

```bash
# Run all tests
flutter test

# Run unit tests only
flutter test test/unit/

# Run widget tests only  
flutter test test/widget/

# Run integration tests
flutter test test/integration/

# Run specific test file
flutter test test/unit/voting/voting_usecases_test.dart

# Run tests with coverage
flutter test --coverage

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Generate mocks for testing
flutter packages pub run build_runner build
```

### Authentication Testing

#### Unit Tests
- Use case validation and error handling
- Repository data source coordination  
- Input validation and password strength
- Biometric authentication logic

#### Widget Tests
- Form validation and user interactions
- Navigation between auth screens
- Accessibility and semantic labels
- Loading states and error displays

#### Integration Tests  
- Complete login/registration flows
- Biometric authentication setup
- Password recovery process
- Offline authentication scenarios

### Test Data

Test data is defined in `test/helpers/test_data.dart`:

```dart
// Test user data
final testUser = User(
  id: 'test_id',
  email: 'test@kwasu.edu.ng', 
  fullName: 'Test User',
  role: 'student',
  matricNumber: 'CSC12345',
);

// Test credentials
const testCredentials = LoginParams(
  identifier: 'test@kwasu.edu.ng',
  password: 'TestPassword123!',
  rememberMe: true,
);
```

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

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widget/
```

### Integration Tests
```bash
flutter test integration_test/
```

### Code Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
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