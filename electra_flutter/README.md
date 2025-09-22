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