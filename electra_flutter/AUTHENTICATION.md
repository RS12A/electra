# Authentication System Documentation

## Overview

The Electra Flutter application features a production-grade authentication system built using Clean Architecture principles. This system provides secure, user-friendly authentication with support for multiple login methods, offline capabilities, and comprehensive security features.

## Features

### 🔐 Authentication Methods
- **Email/Password Login**: Standard authentication with email addresses
- **Student Login**: Matriculation number-based authentication for students
- **Staff Login**: Staff ID-based authentication for faculty and staff
- **Biometric Authentication**: Fingerprint/Face ID support for quick access
- **Offline Login**: Cached credential verification when network is unavailable

### 🎨 User Experience
- **Neomorphic Design**: Modern, depth-based UI elements
- **Smooth Animations**: Fluid transitions and micro-interactions
- **Multi-theme Support**: Light and dark themes with KWASU branding
- **Responsive Design**: Optimized for phones and tablets
- **Accessibility**: Full screen reader and keyboard navigation support

### 🛡️ Security Features
- **JWT Token Management**: Automatic token refresh and secure storage
- **Encrypted Storage**: Biometric data and credentials encrypted locally
- **Password Hashing**: Secure offline credential storage
- **Network Security**: Production-ready HTTPS and certificate validation
- **Session Management**: Automatic logout on token expiry

## Architecture

The authentication system follows Clean Architecture with clear separation of concerns:

```
auth/
├── domain/           # Business logic layer
│   ├── entities/     # Core business objects
│   ├── repositories/ # Abstract interfaces
│   └── usecases/     # Business rules
├── data/             # Data access layer
│   ├── datasources/  # Remote and local data sources
│   ├── models/       # Data transfer objects
│   └── repositories/ # Repository implementations
└── presentation/     # UI layer
    ├── pages/        # Screen widgets
    ├── providers/    # State management
    └── widgets/      # Reusable UI components
```

## Authentication Flow

### Login Process
1. User enters credentials (email/matric/staff ID + password)
2. System validates input format and requirements
3. Credentials sent to backend API for verification
4. JWT tokens returned and stored securely
5. User redirected to dashboard
6. Biometric data optionally stored for future quick access

### Offline Login
1. System detects no network connection
2. Checks for cached credentials matching input
3. Verifies password hash against stored hash
4. Grants limited offline access with cached user data

### Biometric Setup
1. User must be logged in successfully
2. Device biometric availability checked
3. User authenticates with device biometric
4. Encrypted auth data stored with biometric protection
5. Future logins can use biometric authentication

## API Integration

### Backend Endpoints
- `POST /api/auth/login/` - User authentication
- `POST /api/auth/register/` - New user registration  
- `POST /api/auth/token/refresh/` - JWT token refresh
- `POST /api/auth/password-reset/` - Password recovery initiation
- `POST /api/auth/password-reset-confirm/` - Password reset completion
- `POST /api/auth/logout/` - Session termination
- `GET /api/auth/profile/` - Current user information

### Request/Response Format
```json
// Login Request
{
  "identifier": "student@kwasu.edu.ng",
  "password": "securePassword123"
}

// Login Response
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": "123",
    "email": "student@kwasu.edu.ng",
    "full_name": "John Student",
    "role": "student",
    "matric_number": "STU12345"
  },
  "expires_in": 900
}
```

## Testing

### Unit Tests
- Authentication use cases with comprehensive scenarios
- Repository implementations with mocked dependencies
- Validation logic for all input formats
- Error handling and edge cases

### Widget Tests
- Authentication screens with user interactions
- Form validation and error display
- Biometric button functionality
- Animation and accessibility features

### Integration Tests
- Complete authentication flows
- Network connectivity handling
- Offline login scenarios
- Biometric setup and usage

## User Roles

### Student
- **Login**: Email or matriculation number + password
- **Registration**: Requires valid KWASU email and matric number
- **Validation**: Matric number format: `ABC12345` (3 letters + 5 digits)

### Staff
- **Login**: Email or staff ID + password
- **Registration**: Requires valid email and staff ID
- **Validation**: Staff ID minimum 4 characters, alphanumeric

### Admin/Electoral Committee
- **Login**: Same as staff
- **Access**: Additional administrative features
- **Management**: Can access election management and analytics

## Security Considerations

### Data Protection
- Biometric data never leaves the device
- Passwords hashed before storage using SHA-256
- JWT tokens stored in Flutter Secure Storage
- Network communications use TLS 1.3+

### Authentication Tokens
- Access tokens expire after 15 minutes
- Refresh tokens valid for 7 days
- Automatic token rotation on refresh
- Blacklisted tokens on logout

### Offline Security
- Cached credentials expire after 30 days
- Failed attempts trigger increasing delays
- Biometric authentication requires device security

## Error Handling

### Common Error Types
- `ValidationException`: Input format errors
- `AuthException`: Authentication failures
- `NetworkException`: Connectivity issues
- `BiometricException`: Biometric setup/usage failures
- `StorageException`: Local storage problems

### User-Friendly Messages
All errors are translated to user-friendly messages with actionable guidance:
- "Please enter a valid email address"
- "Password must contain uppercase, lowercase, and numbers"
- "No internet connection. Using cached credentials."
- "Biometric authentication is not set up on this device"

## Configuration

### Environment Setup
```dart
// lib/shared/constants/app_constants.dart
static const String baseUrl = 'https://your-api-server.com:8000';
static const Duration tokenRefreshThreshold = Duration(minutes: 5);
static const int maxOfflineLoginAttempts = 3;
```

### Theme Customization
The authentication screens automatically adapt to the app's theme system with KWASU branding:
- Primary Blue: `#1E3A8A`
- Secondary Green: `#10B981`  
- Accent Gold: `#F59E0B`

## Future Enhancements

### Planned Features
- Multi-factor authentication (MFA)
- Social login integration
- Password-less authentication
- Enhanced biometric types (iris, voice)
- Advanced security analytics

### Performance Optimizations
- Token refresh background processing
- Biometric data compression
- Offline sync optimizations
- Cache management improvements

## Support

For authentication-related issues:
1. Check network connectivity
2. Verify credentials format
3. Clear app cache if persistent issues
4. Contact Electoral Committee for account problems

## Changelog

### v1.0.0 (Current)
- Complete authentication system implementation
- Biometric authentication support
- Offline login capabilities
- Production-grade security features
- Comprehensive testing coverage
- Full accessibility support