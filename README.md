# Electra - Secure Digital Voting System

A complete production-grade digital voting platform with Django backend and Flutter frontend, built with security, scalability, and maintainability in mind. Features secure ballot token management, RSA cryptographic signatures, and offline voting capabilities.

## 📱 **Flutter Frontend**

The Electra Flutter app provides a modern, secure, and user-friendly interface for the digital voting system:

### 🎨 **Next-Generation UI/UX Design**
- **Neomorphic Design System**: Production-grade neomorphic components with optimized shadows and depth
- **GPU-Accelerated Animations**: 60+ FPS smooth animations optimized for mid-range Android devices  
- **Dynamic University Theming**: Customizable branding system supporting multiple universities
- **Responsive Design**: Fluid layouts that scale perfectly across mobile, tablet, desktop, and web
- **Dark/Light/High Contrast**: Multiple theme modes with seamless transitions
- **Staggered Animations**: Smooth, choreographed animations for lists and cards
- **Micro-Interactions**: Delightful button presses, hover effects, and state changes

### 🗳️ **Production-Grade Voting Screens**

#### Enhanced Login Screen
- **Staggered Entry Animations**: Smooth cascading animations for form elements
- **Neomorphic Form Inputs**: Beautiful inset input fields with focus animations
- **Biometric Integration**: Fingerprint and face recognition with animated feedback
- **Responsive Layout**: Optimized for all screen sizes with fluid typography
- **Accessibility First**: Full screen reader support and keyboard navigation

#### Candidate Listing Screen
- **Interactive Search & Filter**: Real-time search with debounced input and position filtering
- **Responsive Grid**: Adaptive grid layout that scales from 1 to 4 columns based on screen size
- **Staggered Card Animations**: Smooth entrance animations for candidate cards
- **Pull-to-Refresh**: Native pull-to-refresh functionality with custom animations
- **Candidate Details Modal**: Bottom sheet with draggable scroll for detailed candidate information
- **Empty States**: Beautiful empty states with helpful messaging and clear actions

#### Admin Dashboard
- **Real-time Metrics**: Live updating dashboard with animated counters and progress indicators
- **Quick Actions Grid**: Responsive action cards with hover effects and role-based permissions
- **System Status Indicators**: Visual health monitoring with color-coded status indicators
- **Responsive Charts**: Data visualization that adapts to screen size and orientation
- **Animated Alerts**: Smooth notification system with priority-based styling

#### Vote Casting Screen  
- **Secure Vote Selection**: Radio button selection with visual feedback
- **Real-time Validation**: Immediate validation of selections
- **Security Indicators**: Visual encryption and connection status
- **Progress Tracking**: Step-by-step progress through ballot positions
- **Selection Summary**: Review panel showing all choices before submission

#### Vote Confirmation Screen
- **Success Animation**: Animated success feedback with haptic responses  
- **Anonymized Summary**: Vote confirmation without revealing selections
- **Verification Codes**: QR codes and tokens for independent vote verification
- **Security Details**: Explanation of encryption and anonymity measures
- **Next Election Info**: Countdown and information about upcoming elections

### 🔐 **Security & Encryption**
- **End-to-End Encryption**: AES-256-GCM encryption of vote data
- **RSA Signatures**: Cryptographic signatures for vote integrity  
- **Anonymous Voting**: Complete separation of voter identity from vote content
- **Ballot Token System**: Secure token-based authentication prevents double voting
- **Offline Security**: Encrypted local storage for offline votes

### ⚙️ **Production Environment Management**
- **Comprehensive Environment Validation**: 140+ environment variables with runtime validation
- **Automatic Security Checks**: Detection of insecure defaults and missing configurations
- **Environment-Aware Configuration**: Frontend and backend adapt based on environment variables
- **Key Management**: Automated RSA key generation and rotation procedures
- **Deployment Readiness Testing**: Complete validation scripts for production deployment
- **Documentation**: Comprehensive setup guides and troubleshooting documentation

### 💾 **Offline Support**
- **Offline Vote Casting**: Cast votes without internet connection
- **Encrypted Queue**: Votes stored encrypted until sync
- **Automatic Sync**: Background synchronization when connection restored
- **Sync Status**: Visual indicators for offline votes and sync progress
- **Conflict Resolution**: Smart handling of sync conflicts and errors

### 🔧 **State Management & Architecture**
- **Clean Architecture**: Domain-driven design with clear separation of concerns
- **Riverpod State Management**: Reactive state management with proper error handling
- **Repository Pattern**: Abstracted data access with repository interfaces
- **Use Cases**: Business logic encapsulated in dedicated use case classes
- **Dependency Injection**: Proper dependency management with GetIt

### ♿ **Enhanced Accessibility Features**
- **Screen Reader Compatibility**: Full VoiceOver and TalkBack support with semantic labels
- **High Contrast Mode**: Dedicated high contrast theme with optimized color ratios
- **Reduced Motion Support**: Respect for system accessibility preferences with fallback animations
- **Keyboard Navigation**: Complete keyboard navigation with visible focus indicators
- **Scalable Typography**: Dynamic font scaling that respects user preferences
- **Touch Target Optimization**: All interactive elements meet minimum 44px touch target requirements
- **Voice Control**: Compatible with voice control systems and switch navigation

### 🧪 **Comprehensive Testing & Quality Assurance**
- **Component Library Tests**: Extensive testing of neomorphic components and responsive layouts
- **Animation Performance Tests**: Automated testing to ensure 60+ FPS on target devices
- **Accessibility Compliance Tests**: Automated accessibility testing with semantic validation
- **Visual Regression Tests**: Golden file testing to prevent UI regressions
- **Cross-Platform Tests**: Testing across mobile, tablet, desktop, and web platforms
- **Theme System Tests**: Comprehensive testing of all theme modes and transitions
- **Integration Tests**: End-to-end user flow testing with real animations

[👉 **View Flutter Frontend Documentation**](./electra_flutter/README.md)

## 🖥️ **Django Backend**

### 🔧 **Migration & Schema Management**

The Electra backend uses a comprehensive migration management system to ensure database schema integrity across all environments. All database operations use **PostgreSQL only** - SQLite is completely prohibited.

#### **Quick Migration Commands**

```bash
# Generate migrations for all apps
python manage.py makemigrations

# Apply all migrations
python manage.py migrate

# Verify database schema integrity
python manage.py verify_schema

# Create superuser (requires staff_id for admin users)
python manage.py createsuperuser
```

#### **Migration Verification Tools**

**🔍 Schema Verification Command**
```bash
# Basic schema verification
python manage.py verify_schema

# Verbose output with detailed checks
python manage.py verify_schema --verbose

# Auto-fix missing migrations
python manage.py verify_schema --fix-missing
```

The `verify_schema` command performs comprehensive checks:
- ✅ Database connection validation
- ✅ Critical table existence verification
- ✅ Custom user model configuration
- ✅ Model-to-database schema consistency
- ✅ Unmigrated changes detection
- ✅ Basic database operations testing

**🔧 Windows Migration Fixer Script**
```bash
# Run complete migration fix (Windows)
python scripts/fix_migrations_windows.py

# Verbose output
python scripts/fix_migrations_windows.py --verbose

# Dry run (show what would be done without changes)
python scripts/fix_migrations_windows.py --dry-run
```

The migration fixer automatically:
- Creates missing migration directories
- Runs `makemigrations` for all apps
- Applies all migrations with `migrate`
- Verifies all critical tables exist
- Runs comprehensive schema verification
- Provides detailed success/failure reporting

**🔧 Windows PowerShell Automation**
```powershell
# Complete backend verification (Windows PowerShell)
.\scripts\verify_backend.ps1

# With verbose output
.\scripts\verify_backend.ps1 -Verbose

# Skip test suite
.\scripts\verify_backend.ps1 -SkipTests

# Dry run mode
.\scripts\verify_backend.ps1 -DryRun
```

The PowerShell script performs end-to-end verification:
1. **Virtual Environment**: Checks Python environment activation
2. **Dependencies**: Validates required packages are installed
3. **Database Connection**: Tests PostgreSQL connectivity
4. **Migration Fixer**: Runs the migration automation script
5. **Schema Verification**: Executes schema integrity checks
6. **Test Suite**: Runs the complete test suite (optional)

#### **Schema Health Testing**

Comprehensive schema health tests ensure database integrity:

```bash
# Run schema health tests
python manage.py test tests.test_schema_health

# Run with verbose output
python manage.py test tests.test_schema_health -v 2

# Run specific test categories
python manage.py test tests.test_schema_health.SchemaHealthTestCase
python manage.py test tests.test_schema_health.SchemaOperationsTestCase
python manage.py test tests.test_schema_health.SchemaMigrationTestCase
```

**Test Categories:**
- **SchemaHealthTestCase**: Basic schema integrity checks
- **SchemaOperationsTestCase**: Database operations testing
- **SchemaMigrationTestCase**: Migration state verification
- **SchemaConstraintsTestCase**: Database constraint validation
- **SchemaIntegrationTestCase**: Full workflow integration tests

#### **Custom User Model Configuration**

The system uses a custom user model with proper configuration:

```python
# Settings Configuration
AUTH_USER_MODEL = 'electra_auth.User'

# Required fields for different user roles
STUDENT_REQUIRED_FIELDS = ['email', 'full_name', 'matric_number']
STAFF_REQUIRED_FIELDS = ['email', 'full_name', 'staff_id']
ADMIN_REQUIRED_FIELDS = ['email', 'full_name', 'staff_id']
```

**Creating Users:**
```bash
# Create staff user
python manage.py shell -c "
from django.contrib.auth import get_user_model
from electra_server.apps.auth.models import UserRole
User = get_user_model()
User.objects.create_user(
    email='staff@electra.test',
    full_name='Staff User',
    password='secure_password',
    role=UserRole.STAFF,
    staff_id='STAFF001'
)
"

# Create student user
python manage.py shell -c "
from django.contrib.auth import get_user_model
from electra_server.apps.auth.models import UserRole
User = get_user_model()
User.objects.create_user(
    email='student@electra.test',
    full_name='Student User',
    password='secure_password',
    role=UserRole.STUDENT,
    matric_number='STU001'
)
"
```

#### **Migration Troubleshooting**

**Common Issues and Solutions:**

**❌ `no such table: electra_auth_user`**
```bash
# Solution: Run migration fixer
python scripts/fix_migrations_windows.py --verbose

# Or manually:
python manage.py makemigrations
python manage.py migrate
python manage.py verify_schema
```

**❌ Missing migrations directories**
```bash
# Create missing directories
for app in admin analytics audit auth ballots elections health notifications votes; do
    mkdir -p electra_server/apps/$app/migrations
    touch electra_server/apps/$app/migrations/__init__.py
done
```

**❌ Superuser creation fails**
```bash
# Superusers require staff_id - create via Django shell:
python manage.py shell -c "
from django.contrib.auth import get_user_model
from electra_server.apps.auth.models import UserRole
User = get_user_model()
User.objects.create_superuser(
    email='admin@electra.test',
    password='admin_password',
    staff_id='ADMIN001',
    full_name='System Administrator'
)
"
```

**❌ Database connection issues**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Verify database exists
psql -h localhost -U postgres -l

# Create database if missing
psql -h localhost -U postgres -c "CREATE DATABASE electra_dev;"
```

**❌ Schema inconsistencies**
```bash
# Reset migrations (DANGER: destroys data)
python manage.py migrate --fake-initial
python manage.py migrate

# Or safer approach:
python manage.py sqlmigrate app_name migration_name
# Review SQL before applying
```

#### **Production Migration Checklist**

Before deploying to production:

- [ ] ✅ Run `python manage.py verify_schema` with exit code 0
- [ ] ✅ All tests pass: `python manage.py test`
- [ ] ✅ Migration fixer completes successfully
- [ ] ✅ Custom user model creates users correctly
- [ ] ✅ Critical tables exist and are accessible
- [ ] ✅ Database constraints are properly enforced
- [ ] ✅ Schema matches model definitions exactly

**Automated Verification:**
```bash
# Complete production readiness check
.\scripts\verify_backend.ps1 -Verbose

# Expected output: "ALL VERIFICATION CHECKS PASSED!"
```

## Features

🗳️ **Vote Casting System**
- **Secure Vote Casting**: AES-256-GCM encrypted votes with RSA signature verification  
- **Anonymous Vote Tokens**: Voter identity separated from vote content for anonymity
- **One Vote Per Election**: Server-side enforcement preventing duplicate voting
- **Offline Vote Support**: Votes can be cast offline and synced securely when online
- **Vote Verification**: Cryptographic verification of vote integrity and signatures
- **Comprehensive Audit Trail**: All voting operations logged while preserving anonymity

🔐 **Security First**
- JWT authentication with short-lived access tokens (15 minutes) and long-lived refresh tokens (7 days)
- **RSA Cryptographic Ballot Tokens**: Each ballot token is cryptographically signed using 4096-bit RSA keys
- Argon2 password hashing (production-grade security)
- Role-based access control with proper validation
- OTP-based password recovery with email verification
- **Anti-Duplication**: Single-use tokens prevent double voting
- **Comprehensive Audit Trail**: All ballot token operations are logged
- Comprehensive security headers and CORS protection
- Login attempt tracking and rate limiting
- Request logging and monitoring

🗳️ **Ballot Token System**
- **Secure Token Issuance**: Cryptographically signed ballot tokens for eligible voters
- **Token Validation**: Real-time verification of token signatures and validity
- **Expiration Management**: Automatic token expiration and cleanup
- **Offline Voting Support**: Tokens can be encrypted and stored for offline voting
- **Secure Synchronization**: Encrypted vote data syncs back when connectivity is restored

🏗️ **Production Ready**
- Docker containerization
- PostgreSQL database
- Redis caching
- Nginx reverse proxy support
- Health check endpoints

🧪 **Testing & Quality**
- Comprehensive test suite
- Code coverage reporting
- Automated linting and formatting
- Security scanning

📊 **Analytics & Reporting**
- **Comprehensive Analytics**: Real-time turnout and participation metrics
- **Time-Series Analysis**: Daily, weekly, and election period analytics
- **Export Capabilities**: Professional CSV, XLSX, and PDF exports with verification
- **Category Analysis**: Participation categorization (Excellent, Good, Fair, Critical)
- **Secure Access**: Admin-only analytics with comprehensive audit logging
- **Performance Optimized**: Intelligent caching with force-refresh capabilities

📊 **Observability**
- Structured JSON logging
- Request tracing with UUIDs
- Performance monitoring
- Health checks with service status

## Authentication Features

### User Roles & Registration
- **Students**: Register with email, password, full name, and matriculation number
- **Staff**: Register with email, password, full name, and staff ID  
- **Candidates**: Can have either matriculation number or staff ID
- **Administrators**: Full system access with staff ID
- **Electoral Committee**: Election management permissions

### Security Features
- **JWT Tokens**: Short-lived access tokens (15 minutes) with long-lived refresh tokens (7 days)
- **Password Security**: Argon2 hashing with configurable parameters
- **Account Recovery**: Time-limited 6-digit OTP codes sent via email
- **Login Tracking**: Comprehensive logging of all login attempts with IP addresses
- **Rate Limiting**: Protection against brute force attacks
- **Token Blacklisting**: Secure logout with token invalidation

### Authentication Methods
- Login with email address
- Login with matriculation number (students)  
- Login with staff ID (staff/admin)
- Password recovery via email OTP
- Profile management for authenticated users

### Email Configuration
- SMTP support for password recovery emails
- Mock email backend for local development
- Configurable email templates and settings

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Python 3.11+ (for local development)
- Make (optional, for convenience commands)

### 1. Clone and Setup Environment

```bash
# Clone the repository
git clone <repository-url>
cd electra

# Copy environment template
cp .env.example .env

# Edit .env with your configuration
nano .env  # or your preferred editor
```

### 2. Generate RSA Keys for JWT

```bash
# Generate secure RSA keys
python scripts/generate_rsa_keys.py

# Or using Make
make generate-keys
```

### 3. Validate Environment Configuration

```bash
# Validate all environment variables
python scripts/validate_environment.py

# Or validate specific environment file
python scripts/validate_environment.py --env-file .env.production

# Test deployment readiness (includes connectivity tests)
python scripts/test_deployment.py
```

### 4. Start Development Environment

```bash
# Using Make (recommended)
make setup-dev

# Or manually with Docker Compose
docker compose build
docker compose up -d
docker compose exec web python manage.py migrate
docker compose exec web python manage.py seed_initial_data
```

### 4. Verify Installation

```bash
# Check health endpoint
curl http://localhost:8000/api/health/

# Access admin panel
# http://localhost:8000/admin/
# Login with credentials from .env (default: admin/admin123)
```

## API Endpoints

### Health Check
- `GET /api/health/` - System health and service status

### Authentication & User Management

#### Core Authentication
- `POST /api/auth/register/` - User registration (students: email, password, full_name, matric_number; staff: email, password, full_name, staff_id)  
- `POST /api/auth/login/` - User login (identifier can be email, matric_number, or staff_id)
- `POST /api/auth/logout/` - User logout (blacklists refresh token)
- `POST /api/auth/token/refresh/` - Refresh JWT access token

#### Password Recovery
- `POST /api/auth/password-reset/` - Request password reset OTP (send 6-digit code via email)
- `POST /api/auth/password-reset-confirm/` - Confirm password reset with OTP and set new password

#### User Profile Management
- `GET /api/auth/profile/` - Get current user profile
- `PUT /api/auth/profile/` - Update user profile (authenticated users only)
- `POST /api/auth/change-password/` - Change password (authenticated users only)
- `GET /api/auth/login-history/` - View login history (authenticated users only)
- `GET /api/auth/status/` - Check authentication status

#### Admin & Management (admin/electoral committee only)
- `GET /api/auth/users/` - List users with filtering and search
- `GET /api/auth/users/<uuid:id>/` - Get user details by ID
- `GET /api/auth/stats/` - Get user statistics and metrics

### Admin API
The Admin API provides comprehensive administrative functionality for managing users, elections, and ballot tokens. All endpoints require authentication and admin or electoral committee privileges.

#### Access Control
- **Roles**: Only `admin` and `electoral_committee` roles have access
- **Rate Limiting**: 100 requests/hour general, 30 requests/hour for sensitive operations
- **Audit Logging**: All administrative actions are comprehensively logged
- **Security**: TLS 1.3 enforced, IP tracking, user agent logging

#### User Management
- `GET /api/admin/users/` - List all users with filtering and search
  - Query Parameters: `role`, `is_active`, `search`
- `GET /api/admin/users/{id}/` - Get detailed user information
- `POST /api/admin/users/` - Create new user account
- `PUT /api/admin/users/{id}/` - Update user account
- `PATCH /api/admin/users/{id}/` - Partial update user account
- `DELETE /api/admin/users/{id}/` - Delete user account (audit trail preserved)
- `POST /api/admin/users/{id}/activate/` - Activate user account
- `POST /api/admin/users/{id}/deactivate/` - Deactivate user account

#### Election Management
- `GET /api/admin/elections/` - List all elections with filtering
  - Query Parameters: `status`, `created_by`, `search`
- `GET /api/admin/elections/{id}/` - Get detailed election information
- `POST /api/admin/elections/` - Create new election
- `PUT /api/admin/elections/{id}/` - Update election
- `PATCH /api/admin/elections/{id}/` - Partial update election
- `DELETE /api/admin/elections/{id}/` - Delete election (non-active only)
- `POST /api/admin/elections/{id}/activate/` - Activate election
- `POST /api/admin/elections/{id}/close/` - Close/complete election
- `POST /api/admin/elections/{id}/cancel/` - Cancel election

#### Ballot Token Management
- `GET /api/admin/ballots/` - List all ballot tokens with filtering
  - Query Parameters: `status`, `election`, `user`, `is_valid`, `search`
- `GET /api/admin/ballots/{id}/` - Get detailed ballot token information
- `POST /api/admin/ballots/{id}/revoke/` - Revoke ballot token
  - Request Body: `{"reason": "Revocation reason"}`

#### System Dashboard
- `GET /api/admin/dashboard/` - Get system statistics and overview
  - Returns user statistics, election statistics, ballot token metrics
  - Provides real-time system health information

#### Candidate Management
- `GET /api/admin/candidates/` - Placeholder for candidate management
  - **Note**: Full implementation pending candidate model availability

#### Security Features
- **Comprehensive Audit Logging**: All admin actions logged with full context
- **Role-based Permissions**: Granular permissions for different admin operations
- **Rate Limiting**: Tiered throttling for normal vs sensitive operations
- **IP Tracking**: All requests logged with client IP and user agent
- **Data Validation**: Extensive validation with security-conscious defaults
- **Safe Operations**: Prevents dangerous operations (e.g., deleting own account)

### Admin Interface
- `/admin/` - Django admin interface with comprehensive user management

### Election Management

#### Core Election Operations
- `GET /api/elections/` - List elections (admin/electoral_committee see all; others see non-draft only)
- `GET /api/elections/<uuid:id>/` - Get election details
- `POST /api/elections/create/` - Create new election (admin/electoral_committee only)
- `PUT /api/elections/<uuid:id>/update/` - Update election (admin/electoral_committee only)
- `PATCH /api/elections/<uuid:id>/update/` - Partial update election (admin/electoral_committee only)
- `DELETE /api/elections/<uuid:id>/delete/` - Delete draft election (admin/electoral_committee only)

#### Election Status Management
- `PATCH /api/elections/<uuid:id>/status/` - Change election status (admin/electoral_committee only)
  - `{"action": "activate"}` - Activate a draft election
  - `{"action": "cancel"}` - Cancel an active or draft election  
  - `{"action": "complete"}` - Mark an active election as completed

#### Election Lifecycle
1. **Draft** - Initial creation state, only visible to election managers
2. **Active** - Election is running and users can vote (within start_time - end_time period)
3. **Completed** - Election has finished successfully
4. **Cancelled** - Election has been cancelled

#### Election Fields
- `id` (UUID) - Unique election identifier
- `title` (String) - Election title
- `description` (Text) - Detailed election description
- `start_time` (DateTime) - When voting begins
- `end_time` (DateTime) - When voting ends
- `status` (Choice) - Current election status (draft/active/completed/cancelled)
- `delayed_reveal` (Boolean) - Whether results are revealed after completion
- `created_by` (User) - Election creator
- `created_at` (DateTime) - Creation timestamp
- `updated_at` (DateTime) - Last update timestamp

#### Permissions & Access Control
- **Admin & Electoral Committee**: Full election management (create, update, delete, status changes)
- **Students & Staff**: View non-draft elections, participate in voting
- **Election Status Restrictions**:
  - Only draft elections can be deleted
  - Elections cannot be modified during active voting period
  - Start/end times cannot be changed after election has started/ended

### Ballot Token Management

#### Core Ballot Token Operations
- `POST /api/ballots/request-token/` - Generate and return signed ballot token for specific election
- `POST /api/ballots/validate-token/` - Verify token signature and validity before casting vote
- `GET /api/ballots/my-tokens/` - List current user's ballot tokens
- `GET /api/ballots/tokens/<uuid:id>/` - Get specific ballot token details (owner/managers only)

#### Offline Voting Support
- `GET /api/ballots/offline-queue/` - List offline ballot queue entries
- `POST /api/ballots/offline-submit/` - Submit offline ballot votes for synchronization

#### Management & Monitoring (admin/electoral committee only)
- `GET /api/ballots/stats/` - Get ballot token statistics and metrics
- `GET /api/ballots/usage-logs/` - View audit trail of ballot token operations

#### Ballot Token Features
- **Single-Use Tokens**: Each voter gets one cryptographically signed token per election
- **RSA Signatures**: 4096-bit RSA signatures for token verification
- **Automatic Expiration**: Tokens expire 24 hours after issuance or at election end
- **Offline Support**: Tokens can be queued and encrypted for offline voting
- **Comprehensive Logging**: All token operations logged for audit trail
- **Anti-Duplication**: Prevents multiple token requests for same election
- **Real-time Validation**: Tokens verified against signatures and election status

#### Ballot Token Request Example
```bash
# 1. Request ballot token (authenticated student/staff)
curl -X POST http://localhost:8000/api/ballots/request-token/ \
  -H "Authorization: Bearer <your-access-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "election_id": "550e8400-e29b-41d4-a716-446655440000"
  }'

# Response includes signed token
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "token_uuid": "789e4567-e89b-12d3-a456-426614174001",
  "signature": "abc123def456...",  // RSA signature hex
  "status": "issued",
  "election_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "456e7890-e89b-12d3-a456-426614174002",
  "issued_at": "2023-01-15T10:00:00Z",
  "expires_at": "2023-01-16T10:00:00Z",
  "is_valid": true,
  "token_data": {
    "token_uuid": "789e4567-e89b-12d3-a456-426614174001",
    "user_id": "456e7890-e89b-12d3-a456-426614174002",
    "election_id": "550e8400-e29b-41d4-a716-446655440000",
    "issued_at": "2023-01-15T10:00:00Z",
    "expires_at": "2023-01-16T10:00:00Z"
  }
}

# 2. Validate ballot token before voting
curl -X POST http://localhost:8000/api/ballots/validate-token/ \
  -H "Authorization: Bearer <your-access-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "token_uuid": "789e4567-e89b-12d3-a456-426614174001",
    "signature": "abc123def456...",
    "election_id": "550e8400-e29b-41d4-a716-446655440000"
  }'

# Response confirms validity
{
  "valid": true,
  "token": { /* token details */ },
  "message": "Token is valid for voting."
}

# 3. Submit offline ballot (when connectivity restored)
curl -X POST http://localhost:8000/api/ballots/offline-submit/ \
  -H "Authorization: Bearer <your-access-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "ballot_token_uuid": "789e4567-e89b-12d3-a456-426614174001",
    "encrypted_vote_data": "encrypted_ballot_data_here",
    "signature": "offline_ballot_signature",
    "submission_timestamp": "2023-01-15T15:30:00Z"
  }'
```

### Analytics & Reporting System

The Analytics module provides comprehensive voter participation and turnout analytics with secure export capabilities. All analytics endpoints require admin or electoral committee privileges.

#### Access Control
- **Roles**: Only `admin` and `electoral_committee` roles have access
- **Security**: TLS 1.3 enforced, comprehensive audit logging
- **Rate Limiting**: Standard API rate limits apply
- **Caching**: Intelligent caching with real-time refresh options

#### Analytics Endpoints

##### Turnout Metrics
- `GET /api/analytics/turnout/` - Get overall and per-election turnout metrics
- `POST /api/analytics/turnout/` - Get turnout metrics with advanced options

**Query Parameters:**
- `election_id` (UUID, optional) - Filter by specific election
- `use_cache` (boolean, default: true) - Enable/disable caching
- `force_refresh` (boolean, default: false) - Force cache refresh

**Response Structure:**
```json
{
  "overall_turnout": 75.25,
  "per_election": [
    {
      "election_id": "uuid",
      "election_title": "Student Union Election 2023",
      "status": "completed",
      "eligible_voters": 1500,
      "votes_cast": 1129,
      "turnout_percentage": 75.27,
      "category": "good",
      "start_time": "2023-10-01T09:00:00Z",
      "end_time": "2023-10-01T17:00:00Z"
    }
  ],
  "summary": {
    "total_elections": 5,
    "active_elections": 1,
    "completed_elections": 4,
    "total_eligible_voters": 7500,
    "total_votes_cast": 5643
  },
  "metadata": {
    "calculated_at": "2023-10-15T14:30:00Z",
    "calculation_duration": 1.25,
    "data_source": "real_time"
  }
}
```

##### Participation Analytics
- `GET /api/analytics/participation/` - Get participation analytics by user type and category
- `POST /api/analytics/participation/` - Get participation analytics with filters

**Query Parameters:**
- `election_id` (UUID, optional) - Filter by specific election
- `user_type` (string, optional) - Filter by user type (student, staff, candidate)
- `use_cache` (boolean, default: true) - Enable/disable caching
- `force_refresh` (boolean, default: false) - Force cache refresh

**Response Structure:**
```json
{
  "by_user_type": {
    "student": {
      "eligible_users": 5000,
      "participants": 3750,
      "participation_rate": 75.0,
      "category": "good"
    },
    "staff": {
      "eligible_users": 500,
      "participants": 425,
      "participation_rate": 85.0,
      "category": "excellent"
    }
  },
  "by_category": {
    "excellent": 2,
    "good": 3,
    "fair": 0,
    "critical": 0
  },
  "summary": {
    "total_eligible_users": 5500,
    "total_participants": 4175,
    "overall_participation_rate": 75.91
  }
}
```

##### Time Series Analytics
- `GET /api/analytics/time-series/` - Get time-series voting data
- `POST /api/analytics/time-series/` - Get time-series data with custom parameters

**Query Parameters:**
- `period_type` (string, default: daily) - Type of aggregation (daily, weekly, election_period)
- `start_date` (ISO date, optional) - Start date for analysis
- `end_date` (ISO date, optional) - End date for analysis
- `election_id` (UUID, optional) - Filter by specific election
- `use_cache` (boolean, default: true) - Enable/disable caching

**Response Structure:**
```json
{
  "period_type": "daily",
  "start_date": "2023-10-01T00:00:00Z",
  "end_date": "2023-10-31T23:59:59Z",
  "data_points": [
    {
      "period": "2023-10-01",
      "vote_count": 245,
      "period_start": "2023-10-01T00:00:00Z",
      "period_end": "2023-10-01T23:59:59Z"
    }
  ],
  "summary": {
    "total_votes": 5643,
    "peak_voting_day": {
      "period": "2023-10-01",
      "vote_count": 1129
    },
    "average_daily_votes": 182.0
  }
}
```

##### Election Summary
- `GET /api/analytics/election-summary/{election_id}/` - Get comprehensive election summary

**Response includes:**
- Election details and metadata
- Complete turnout analysis
- Participation breakdown by user type
- Time-series data for the election period

#### Data Export System

##### Export Analytics Data
- `POST /api/analytics/export/` - Export analytics data in various formats

**Request Body:**
```json
{
  "export_type": "csv|xlsx|pdf",
  "data_type": "turnout|participation|time_series|election_summary",
  "election_id": "uuid (optional)",
  "user_type": "string (optional)",
  "period_type": "daily|weekly|election_period (for time_series)",
  "start_date": "ISO date (optional)",
  "end_date": "ISO date (optional)",
  "include_verification": true
}
```

**Response:**
- Returns the exported file with appropriate Content-Type
- Includes verification headers for integrity checking

**Export Formats:**
- **CSV**: Clean tabular data with metadata headers
- **XLSX**: Professional spreadsheets with charts and formatting
- **PDF**: Formatted reports with tables and summary statistics

##### Export Verification
- `GET /api/analytics/verify/{verification_hash}/` - Verify exported file integrity

**Response:**
```json
{
  "verified": true,
  "verification_hash": "abc123...",
  "content_hash": "def456...",
  "filename": "turnout_metrics_20231015_143000.csv",
  "export_type": "csv",
  "file_size": 15420,
  "created_at": "2023-10-15T14:30:00Z",
  "requested_by": "Admin User",
  "export_params": {...},
  "message": "Export verification successful - file integrity confirmed"
}
```

#### Analytics Categories

**Participation Categories:**
- **Excellent**: ≥80% participation
- **Good**: 60-79% participation  
- **Fair**: 40-59% participation
- **Critical**: <40% participation

#### Caching and Performance

The analytics system uses intelligent caching to provide fast responses:

- **Django Cache**: Fast in-memory/Redis cache for frequently accessed data
- **Database Cache**: Persistent cache with integrity verification
- **Cache Keys**: Deterministic cache keys based on parameters
- **Auto-Expiration**: Configurable cache timeout (default: 1 hour)
- **Force Refresh**: Admin capability to bypass cache and recalculate

#### Security Features

- **Role-based Access**: Admin and electoral committee only
- **Audit Logging**: All analytics access logged for security monitoring
- **Export Verification**: Cryptographic hash verification for all exports
- **Rate Limiting**: Standard API throttling applies
- **IP Tracking**: Client IP logging for security analysis
- **TLS Enforcement**: All data transfer via TLS 1.3

#### Usage Examples

**Get overall turnout metrics:**
```bash
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/analytics/turnout/"
```

**Get participation data for students only:**
```bash
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/analytics/participation/?user_type=student"
```

**Export election summary as PDF:**
```bash
curl -X POST \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"export_type": "pdf", "data_type": "election_summary", "election_id": "uuid"}' \
  "http://localhost:8000/api/analytics/export/" \
  --output election_summary.pdf
```

**Verify export integrity:**
```bash
curl -H "Authorization: Bearer <token>" \
  "http://localhost:8000/api/analytics/verify/abc123hash456/"
```

### Vote Casting System

#### Core Vote Operations
- `POST /api/votes/cast/` - Cast an encrypted vote using a ballot token
- `POST /api/votes/verify/` - Verify vote signature and integrity
- `GET /api/votes/status/<uuid:vote_token>/` - Get vote status using anonymous vote token

#### Offline Vote Support  
- `GET /api/votes/offline-queue/` - List offline vote queue entries
- `POST /api/votes/offline-submit/` - Submit offline votes for synchronization

#### Audit & Monitoring (admin/electoral committee only)
- `GET /api/votes/audit-logs/` - View vote operation audit trail

#### Vote Casting Features
- **AES-256-GCM Encryption**: All vote data encrypted client-side before submission
- **Anonymous Vote Tokens**: Voter identity separated from vote content for complete anonymity
- **RSA Signature Verification**: All votes cryptographically signed and verified
- **One Vote Per Election**: Server-side duplicate vote prevention
- **Offline Vote Support**: Votes can be cast offline and synced when connectivity is restored
- **Comprehensive Audit Trail**: All vote operations logged while preserving voter anonymity
- **Vote Verification**: Independent verification of vote integrity using anonymous tokens

#### Vote Casting Flow
1. **Request Ballot Token** - User requests signed ballot token for specific election
2. **Client-Side Encryption** - Vote data encrypted using AES-256-GCM with random key
3. **Vote Signature** - Vote data signed with RSA private key for integrity
4. **Submit Vote** - Encrypted vote + signatures submitted to server
5. **Server Validation** - Token signature, vote signature, and duplication checks
6. **Anonymous Storage** - Vote stored with anonymous token, voter identity separated
7. **Vote Verification** - Vote can be independently verified using anonymous token

#### Vote Casting Example
```bash
# 1. Cast an encrypted vote (after obtaining ballot token)
curl -X POST http://localhost:8000/api/votes/cast/ \
  -H "Authorization: Bearer <your-access-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "token_uuid": "789e4567-e89b-12d3-a456-426614174001",
    "token_signature": "abc123def456...",
    "election_id": "550e8400-e29b-41d4-a716-446655440000",
    "encrypted_vote_data": "base64_encrypted_vote_data",
    "encryption_nonce": "base64_encryption_nonce", 
    "vote_signature": "rsa_signature_of_vote_data",
    "encryption_key_hash": "sha256_hash_of_client_key"
  }'

# Response includes anonymous vote token
{
  "vote_token": "321e4567-e89b-12d3-a456-426614174003",
  "status": "cast",
  "submitted_at": "2023-01-15T15:30:00Z",
  "message": "Vote cast successfully"
}

# 2. Verify your vote using anonymous token
curl -X POST http://localhost:8000/api/votes/verify/ \
  -H "Authorization: Bearer <your-access-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "vote_token": "321e4567-e89b-12d3-a456-426614174003",
    "election_id": "550e8400-e29b-41d4-a716-446655440000"
  }'

# Response confirms vote integrity  
{
  "vote_token": "321e4567-e89b-12d3-a456-426614174003",
  "signature_valid": true,
  "status": "cast",
  "submitted_at": "2023-01-15T15:30:00Z",
  "election": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "title": "Student Council Elections 2023"
  },
  "verified_at": "2023-01-15T16:00:00Z"
}

# 3. Check vote status
curl -X GET http://localhost:8000/api/votes/status/321e4567-e89b-12d3-a456-426614174003/ \
  -H "Authorization: Bearer <your-access-token>"

# 4. Submit offline vote for synchronization
curl -X POST http://localhost:8000/api/votes/offline-submit/ \
  -H "Authorization: Bearer <your-access-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "token_uuid": "789e4567-e89b-12d3-a456-426614174001",
    "token_signature": "abc123def456...",
    "encrypted_vote_data": {
      "election_id": "550e8400-e29b-41d4-a716-446655440000",
      "encrypted_vote_data": "base64_encrypted_vote_data",
      "encryption_nonce": "base64_encryption_nonce",
      "vote_signature": "rsa_signature_of_vote_data",
      "encryption_key_hash": "sha256_hash_of_client_key"
    },
    "client_timestamp": "2023-01-15T15:30:00Z"
  }'
```

#### Encryption & Security Details

**Client-Side Encryption Process:**
1. Generate random 32-byte AES-256 key for each vote
2. Generate random 12-byte nonce for AES-GCM
3. Encrypt vote JSON data using AES-256-GCM
4. Create SHA-256 hash of encryption key for verification
5. Sign vote data with RSA private key for integrity
6. Submit encrypted data + signatures to server

**Server-Side Security Measures:**
- Ballot token RSA signature verification
- Vote RSA signature verification  
- Anonymous vote token generation (deterministic but unlinkable)
- One vote per election enforcement
- Comprehensive audit logging without voter identification
- Replay attack prevention through token single-use

**Anonymity Preservation:**
- Voter identity separated from vote content via anonymous tokens
- Anonymous tokens generated using deterministic UUID5 from hashed ballot data
- Audit trails use anonymous tokens and hashed ballot references
- No direct voter-to-vote linkage stored in database

### Authentication Flow Example

```bash
# 1. Register a student
curl -X POST http://localhost:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "student@university.edu",
    "password": "securepassword123",
    "password_confirm": "securepassword123", 
    "full_name": "John Student",
    "matric_number": "MAT12345",
    "role": "student"
  }'

# 2. Login with email or matric number
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "MAT12345",
    "password": "securepassword123"
  }'

# 3. Use access token for authenticated requests
curl -X GET http://localhost:8000/api/auth/profile/ \
  -H "Authorization: Bearer <your-access-token>"

# 4. Refresh token when access token expires
curl -X POST http://localhost:8000/api/auth/token/refresh/ \
  -H "Content-Type: application/json" \
  -d '{
    "refresh": "<your-refresh-token>"
  }'

# 5. Reset password if forgotten
# Step 1: Request OTP
curl -X POST http://localhost:8000/api/auth/password-reset/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "student@university.edu"
  }'

# Step 2: Confirm with OTP and new password
curl -X POST http://localhost:8000/api/auth/password-reset-confirm/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "student@university.edu",
    "otp_code": "123456",
    "new_password": "newpassword123",
    "new_password_confirm": "newpassword123"
  }'

# 6. Logout (blacklist refresh token)
curl -X POST http://localhost:8000/api/auth/logout/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <your-access-token>" \
  -d '{
    "refresh": "<your-refresh-token>"
  }'
```

## 📱 Voting Screens User Guide

The Electra Flutter app provides a seamless and secure voting experience through three main screens:

### 🗳️ **Candidate Listing Screen**

The candidate listing screen allows voters to browse and learn about all candidates before making their selections.

#### Features
- **Rich Candidate Profiles**: Each candidate card displays:
  - Professional photo or placeholder avatar
  - Full name, department/faculty, and position
  - Campaign manifesto and key messages
  - Additional information when expanded
  - Campaign video (when available)

- **Interactive Design**:
  - Neomorphic card design with smooth animations
  - Expandable cards for detailed information  
  - Smooth hover and tap animations with haptic feedback
  - Position-based filtering with animated tabs

- **Accessibility**:
  - Full screen reader support with semantic labels
  - Keyboard navigation for all interactive elements
  - High contrast support and font scaling
  - Focus management and visual indicators

#### Navigation Flow
1. Select election from dashboard → View candidates
2. Filter candidates by position using top tabs
3. Tap candidate cards to expand for more details
4. Tap "Vote for this Candidate" to proceed to vote casting
5. Use refresh button to reload candidate data

### 🔒 **Vote Casting Screen**

The vote casting screen provides a secure interface for selecting candidates and submitting encrypted votes.

#### Security Features
- **Visual Security Indicators**:
  - Live connection status (Secure/Checking)
  - End-to-end encryption status
  - Offline mode indicators when disconnected

- **Encryption & Anonymity**:
  - AES-256-GCM encryption of vote selections
  - RSA cryptographic signatures for integrity
  - Anonymous vote tokens separate identity from vote
  - Client-side encryption before transmission

#### Voting Process
1. **Election Information**: Display of election details and timing
2. **Security Briefing**: Overview of security features and anonymity
3. **Voting Instructions**: Step-by-step guidance for vote casting
4. **Ballot Sections**: Organized by position with radio button selection
5. **Selection Review**: Summary panel showing all choices
6. **Secure Submission**: Encrypted vote transmission with progress indicators

#### Offline Support
- **Offline Vote Casting**: Full voting capability without internet
- **Encrypted Queue**: Votes stored securely until connection restored
- **Visual Indicators**: Clear offline mode notifications
- **Automatic Sync**: Background synchronization when online

### ✅ **Vote Confirmation Screen**

The confirmation screen provides feedback on successful vote submission while maintaining voter anonymity.

#### Confirmation Details
- **Success Animation**: Animated checkmark with haptic feedback
- **Vote Summary**: Anonymized confirmation details:
  - Unique confirmation ID for records
  - Masked vote token for verification
  - Election title and timestamp
  - Number of positions voted
  - Verification QR code/token

- **Security Information**: Explanation of:
  - Anonymous voting principles
  - End-to-end encryption details
  - Zero-knowledge verification
  - Cryptographic integrity measures

#### Post-Vote Actions
- **Vote Verification**: Link to independent vote verification
- **Anonymous Sharing**: Social sharing without revealing choices
- **Dashboard Return**: Quick return to main dashboard
- **Next Election Info**: Countdown and details for upcoming elections

### 🔄 **Error Handling & Recovery**

#### Network Issues
- **Offline Detection**: Automatic detection of connectivity loss
- **Queue Management**: Local encrypted storage of offline votes
- **Retry Logic**: Smart retry mechanisms for failed submissions
- **Status Indicators**: Real-time sync status and progress

#### Validation & Security
- **Input Validation**: Real-time validation of selections
- **Security Checks**: Ballot token validation and authentication
- **Error Recovery**: Clear error messages with recovery suggestions
- **Audit Trail**: Comprehensive logging while preserving anonymity

#### User Experience
- **Loading States**: Skeleton loading and progress indicators  
- **Error Feedback**: User-friendly error messages with actions
- **Success Feedback**: Clear confirmation of successful operations
- **Help & Support**: Contextual help and support information

### 🧪 **Testing Instructions**

#### Widget Testing
```bash
# Run candidate listing tests
flutter test test/widget/voting/candidate_listing_test.dart

# Run candidate card component tests  
flutter test test/widget/voting/candidate_card_test.dart

# Run vote casting page tests
flutter test test/widget/voting/cast_vote_page_test.dart
```

#### Unit Testing
```bash
# Test domain entities
flutter test test/unit/voting/domain_entities_test.dart

# Test use cases
flutter test test/unit/voting/voting_usecases_test.dart

# Test state management
flutter test test/unit/voting/voting_providers_test.dart
```

#### Integration Testing
```bash
# Run complete voting flow tests
flutter test integration_test/voting_flow_test.dart

# Run accessibility tests
flutter test test/accessibility/voting_accessibility_test.dart
```

#### Test Coverage
```bash
# Generate test coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 📱 **Platform Compatibility**

#### Supported Platforms
- **iOS**: iOS 11.0 and above
- **Android**: Android API level 21 (Android 5.0) and above  
- **Web**: Modern browsers with JavaScript enabled
- **Desktop**: Windows 10, macOS 10.14, Ubuntu 18.04

#### Responsive Design
- **Mobile First**: Optimized for mobile devices
- **Tablet Support**: Enhanced layouts for tablets
- **Desktop Adaptation**: Proper scaling for desktop use
- **Orientation**: Support for portrait and landscape modes

## Development

### Local Development Setup

```bash
# Install dependencies locally
make install-local

# Activate virtual environment
source venv/bin/activate

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run development server
python manage.py runserver
```

### Using Docker (Recommended)

```bash
# Start services
make up

# View logs
make logs

# Run tests
make test

# Open shell in container
make shell

# Run migrations
make migrate

# Create superuser
make createsuperuser

# Seed development data
make seed
```

### Available Make Commands

```bash
make help                 # Show all available commands
make build               # Build Docker images
make up                  # Start development environment
make down                # Stop all services
make logs                # Show application logs
make shell               # Open shell in web container
make migrate             # Run database migrations
make createsuperuser     # Create Django superuser
make seed                # Seed development data
make test                # Run test suite
make format              # Format code with black and isort
make lint                # Run linting with flake8
make security-check      # Run security scans
make setup-dev          # Complete development setup
```

## Testing

### Running Tests

```bash
# Using Docker (recommended)
make test

# Locally
pytest

# With coverage
pytest --cov=apps --cov-report=html
```

### Test Structure

```
tests/
├── test_health.py                     # Health endpoint tests
├── electra_server/apps/auth/tests/    # Authentication module tests
│   ├── test_models.py                # User, OTP, LoginAttempt model tests
│   ├── test_permissions.py           # Role-based permission tests  
│   ├── test_views.py                 # API endpoint tests
│   └── factories.py                  # Test data factories
├── electra_server/apps/elections/tests/ # Election management tests
│   ├── test_models.py                # Election model and lifecycle tests
│   ├── test_permissions.py           # Election permission tests
│   ├── test_views.py                 # Election API endpoint tests
│   └── factories.py                  # Election test data factories
├── electra_server/apps/ballots/tests/ # Ballot token system tests
│   ├── test_models.py                # BallotToken, OfflineQueue, UsageLog tests
│   ├── test_permissions.py           # Ballot token permission tests
│   ├── test_views.py                 # Ballot token API endpoint tests
│   └── factories.py                  # Ballot token test data factories
└── apps/*/tests.py                   # Other app-specific tests
```

### Running Authentication Tests

```bash
# Run all authentication tests
pytest electra_server/apps/auth/tests/ -v

# Run specific test modules
pytest electra_server/apps/auth/tests/test_views.py -v
pytest electra_server/apps/auth/tests/test_models.py -v

# Run tests with coverage
pytest electra_server/apps/auth/tests/ --cov=electra_server.apps.auth --cov-report=html
```

### Running Election Tests

```bash
# Run all election tests
pytest electra_server/apps/elections/tests/ -v

# Run specific election test modules
pytest electra_server/apps/elections/tests/test_models.py -v
pytest electra_server/apps/elections/tests/test_views.py -v
pytest electra_server/apps/elections/tests/test_permissions.py -v

# Run tests with coverage
pytest electra_server/apps/elections/tests/ --cov=electra_server.apps.elections --cov-report=html
```

### Running Ballot Token Tests

```bash
# Run all ballot token tests
pytest electra_server/apps/ballots/tests/ -v

# Run specific ballot token test modules
pytest electra_server/apps/ballots/tests/test_models.py -v
pytest electra_server/apps/ballots/tests/test_views.py -v
pytest electra_server/apps/ballots/tests/test_permissions.py -v

# Run tests with coverage
pytest electra_server/apps/ballots/tests/ --cov=electra_server.apps.ballots --cov-report=html
```

### Writing Tests

```python
# Example authentication test
from django.test import TestCase
from rest_framework.test import APITestCase
from electra_server.apps.auth.models import User, UserRole
from electra_server.apps.auth.tests.factories import UserFactory

class AuthenticationTest(APITestCase):
    def setUp(self):
        # Create test student user
        self.student = UserFactory(
            email='student@test.com',
            role=UserRole.STUDENT,
            matric_number='STU001'
        )
        
        # Create test staff user  
        self.staff = UserFactory(
            email='staff@test.com', 
            role=UserRole.STAFF,
            staff_id='STF001'
        )
    
    def test_student_registration(self):
        """Test student can register with matric number."""
        data = {
            'email': 'newstudent@test.com',
            'password': 'testpass123',
            'password_confirm': 'testpass123',
            'full_name': 'New Student',
            'matric_number': 'STU002',
            'role': 'student'
        }
        response = self.client.post('/api/auth/register/', data)
        self.assertEqual(response.status_code, 201)
        self.assertIn('tokens', response.data)
        self.assertEqual(response.data['user']['role'], 'student')
    
    def test_login_with_matric_number(self):
        """Test student can login with matriculation number."""
        data = {
            'identifier': 'STU001', 
            'password': 'testpass123'
        }
        response = self.client.post('/api/auth/login/', data)
        self.assertEqual(response.status_code, 200)
        self.assertIn('tokens', response.data)
    
    def test_password_reset_flow(self):
        """Test complete password reset flow."""
        # Request OTP
        data = {'email': 'student@test.com'}
        response = self.client.post('/api/auth/password-reset/', data)
        self.assertEqual(response.status_code, 200)
        
        # Get OTP from database  
        from electra_server.apps.auth.models import PasswordResetOTP
        otp = PasswordResetOTP.objects.get(user=self.student)
        
        # Confirm password reset
        data = {
            'email': 'student@test.com',
            'otp_code': otp.otp_code,
            'new_password': 'newpass123',
            'new_password_confirm': 'newpass123'
        }
        response = self.client.post('/api/auth/password-reset-confirm/', data)
        self.assertEqual(response.status_code, 200)
```

## Audit Logging System

Electra includes a comprehensive, tamper-proof audit logging system with blockchain-style hash chaining and RSA digital signatures. This system provides complete traceability of all critical actions while maintaining ballot secrecy.

### Audit System Features

- **Blockchain-style Chain Integrity**: Each audit entry contains SHA-512 hash of previous entry, creating tamper-evident chain
- **RSA Digital Signatures**: Every audit entry is cryptographically signed with 4096-bit RSA keys
- **Immutable Records**: Once created, audit entries cannot be modified or deleted
- **Comprehensive Coverage**: Logs authentication, election management, token issuance, and voting activities
- **Anonymous Vote Logging**: Vote activities logged without compromising ballot secrecy
- **Real-time Verification**: API endpoints for chain integrity verification
- **Role-based Access**: Admin and electoral committee access only
- **Production Security**: TLS 1.3 enforcement, tamper detection, and security middleware

### Audit API Endpoints

All audit endpoints require admin or electoral committee authentication and enforce HTTPS in production.

#### List Audit Logs
```bash
# List all audit entries (paginated)
curl -X GET "https://electra.example.com/api/audit/logs/" \
  -H "Authorization: Bearer <admin-token>" \
  -H "Accept: application/json"

# Filter by action type
curl -X GET "https://electra.example.com/api/audit/logs/?action_type=user_login" \
  -H "Authorization: Bearer <admin-token>"

# Filter by date range
curl -X GET "https://electra.example.com/api/audit/logs/?start_date=2024-01-01&end_date=2024-12-31" \
  -H "Authorization: Bearer <admin-token>"

# Filter by user
curl -X GET "https://electra.example.com/api/audit/logs/?user_id=<user-uuid>" \
  -H "Authorization: Bearer <admin-token>"

# Filter by election
curl -X GET "https://electra.example.com/api/audit/logs/?election_id=<election-uuid>" \
  -H "Authorization: Bearer <admin-token>"

# Get detailed entries
curl -X GET "https://electra.example.com/api/audit/logs/?detailed=true" \
  -H "Authorization: Bearer <admin-token>"
```

#### Get Audit Log Details
```bash
# Get specific audit entry with verification status
curl -X GET "https://electra.example.com/api/audit/logs/<audit-id>/" \
  -H "Authorization: Bearer <admin-token>" \
  -H "Accept: application/json"
```

#### Verify Audit Chain Integrity
```bash
# Quick verification (last 24 hours)
curl -X POST "https://electra.example.com/api/audit/verify/" \
  -H "Authorization: Bearer <admin-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "quick_verify": true
  }'

# Full chain verification
curl -X POST "https://electra.example.com/api/audit/verify/" \
  -H "Authorization: Bearer <admin-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "quick_verify": false
  }'

# Verify specific range
curl -X POST "https://electra.example.com/api/audit/verify/" \
  -H "Authorization: Bearer <admin-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "start_position": 1,
    "end_position": 100
  }'
```

#### Get Audit Statistics
```bash
# Get audit activity statistics
curl -X GET "https://electra.example.com/api/audit/stats/" \
  -H "Authorization: Bearer <admin-token>" \
  -H "Accept: application/json"
```

#### Get Action Types
```bash
# Get available action types for filtering
curl -X GET "https://electra.example.com/api/audit/action-types/" \
  -H "Authorization: Bearer <admin-token>" \
  -H "Accept: application/json"
```

### Audited Actions

The system automatically logs the following critical actions:

#### Authentication Events
- `user_login` - Successful user login
- `user_logout` - User logout  
- `user_login_failed` - Failed login attempt
- `user_password_reset` - Password reset action

#### Election Management
- `election_created` - New election created
- `election_updated` - Election details modified
- `election_activated` - Election status changed to active
- `election_completed` - Election status changed to completed
- `election_cancelled` - Election cancelled

#### Ballot Token Management
- `token_issued` - Ballot token issued to user
- `token_validated` - Ballot token validated for voting
- `token_invalidated` - Ballot token invalidated

#### Voting Activities
- `vote_cast` - Vote successfully cast (anonymous)
- `vote_verified` - Vote verification performed
- `vote_failed` - Vote casting failed

#### System Events
- `admin_action` - Administrative action performed
- `system_error` - System error or security violation

### Chain Verification Process

The audit system uses blockchain-style integrity verification:

1. **Hash Chaining**: Each entry contains SHA-512 hash of previous entry
2. **Content Hashing**: SHA-512 hash of entry content for tamper detection
3. **RSA Signatures**: 4096-bit RSA signatures on entry metadata
4. **Position Tracking**: Sequential chain position numbers prevent insertion attacks
5. **Immutability**: Entries sealed after creation, cannot be modified

#### Example Verification Response
```json
{
  "is_valid": true,
  "total_entries": 1250,
  "verified_entries": 1250,
  "failed_entries": [],
  "chain_breaks": [],
  "signature_failures": [],
  "verification_timestamp": "2024-03-15T10:30:00Z",
  "verified_by": "admin@electra.com"
}
```

### Security Features

#### TLS 1.3 Enforcement
- All audit endpoints require HTTPS in production
- TLS 1.3 preferred for enhanced security
- Security headers added to responses

#### Tamper Detection
- Monitors for injection attempts on audit endpoints
- Blocks suspicious patterns (SQL injection, XSS, path traversal)
- Logs security violations with detailed context
- Rate limiting preparation

#### Access Control
- Admin and electoral committee roles only
- Request logging with IP address and user agent tracking
- Session-based access monitoring

### Production Deployment

#### RSA Key Management
```bash
# Generate production RSA keys (4096-bit)
python scripts/generate_rsa_keys.py --key-size 4096 --output-dir /secure/keys/

# Set environment variables
export RSA_PRIVATE_KEY_PATH=/secure/keys/private_key.pem
export RSA_PUBLIC_KEY_PATH=/secure/keys/public_key.pem

# Secure key file permissions
chmod 600 /secure/keys/private_key.pem
chmod 644 /secure/keys/public_key.pem
```

#### Database Configuration
```bash
# Run audit migrations
python manage.py migrate audit

# Create audit indexes for performance
python manage.py dbshell << EOF
CREATE INDEX CONCURRENTLY IF NOT EXISTS audit_log_timestamp_desc ON audit_log(timestamp DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS audit_log_chain_position_asc ON audit_log(chain_position ASC);
EOF
```

#### Monitoring Setup
```bash
# Monitor chain integrity (daily cron job)
python manage.py shell << EOF
from electra_server.apps.audit.models import AuditLog
result = AuditLog.verify_chain_integrity_full()
if not result['is_valid']:
    print(f"CRITICAL: Audit chain integrity compromised! {result}")
    exit(1)
else:
    print(f"Audit chain verified: {result['verified_entries']}/{result['total_entries']} entries valid")
EOF

# Log rotation for audit logs
logrotate /etc/logrotate.d/electra-audit
```

### Integration with Existing Systems

The audit system automatically integrates with existing modules:

```python
# Example: Manual audit logging in custom code
from electra_server.apps.audit.utils import log_user_action
from electra_server.apps.audit.models import AuditActionType

# Log custom administrative action
log_user_action(
    action_type=AuditActionType.ADMIN_ACTION,
    description='Custom administrative action performed',
    user=request.user,
    request=request,
    outcome='success',
    metadata={'action_details': 'specific_action_data'}
)
```

### Troubleshooting

#### Chain Integrity Issues
```bash
# Check for specific chain breaks
python manage.py shell << EOF
from electra_server.apps.audit.models import AuditLog
entries = AuditLog.objects.order_by('chain_position')
for entry in entries:
    if not entry.verify_chain_integrity():
        print(f"Chain break at position {entry.chain_position}: {entry.id}")
EOF

# Verify signatures
python manage.py shell << EOF
from electra_server.apps.audit.models import AuditLog
invalid_sigs = []
for entry in AuditLog.objects.all():
    if not entry.verify_signature():
        invalid_sigs.append(entry.id)
print(f"Invalid signatures: {invalid_sigs}")
EOF
```

#### Performance Optimization
```sql
-- Add additional indexes for large deployments
CREATE INDEX CONCURRENTLY audit_log_user_timestamp ON audit_log(user_id, timestamp DESC);
CREATE INDEX CONCURRENTLY audit_log_election_timestamp ON audit_log(election_id, timestamp DESC);
CREATE INDEX CONCURRENTLY audit_log_action_outcome ON audit_log(action_type, outcome);
```

## Environment Management & Configuration

The Electra system includes comprehensive environment management with automatic validation, security checks, and deployment readiness testing.

### Environment Variables Overview

The system uses **140+ environment variables** organized into categories:

#### Core Backend Configuration
- **Django Settings**: `DJANGO_SECRET_KEY`, `DJANGO_DEBUG`, `DJANGO_ALLOWED_HOSTS`
- **Database**: `DATABASE_URL` (PostgreSQL connection string)
- **Authentication**: `JWT_SECRET_KEY`, RSA key paths, token lifetimes
- **Email/SMTP**: Host, port, credentials, TLS settings
- **Caching**: `REDIS_URL` for session and cache storage

#### Security & Encryption  
- **RSA Keys**: Private/public key paths for JWT signing
- **SSL Configuration**: HTTPS redirect, HSTS settings
- **CORS**: Allowed origins and trusted origins
- **Admin Security**: Custom admin URL configuration

#### Third-Party Integrations
- **Firebase/FCM**: Project ID, API keys, sender ID for push notifications
- **AWS Services**: Access keys, S3 bucket configuration
- **Monitoring**: Sentry DSN, Slack webhooks, OpenTelemetry settings
- **Analytics**: Google Analytics, Mixpanel, Amplitude tokens

#### Frontend Configuration
- **API URLs**: `API_BASE_URL`, `WS_BASE_URL` for backend communication  
- **Feature Flags**: Biometrics, offline voting, dark mode toggles
- **University Branding**: Name, abbreviation, contact information
- **Social Auth**: Google client ID for OAuth integration

### Environment Validation System

#### Automatic Validation
- **Django Backend**: Validates environment on production startup
- **Flutter Frontend**: Validates configuration on app initialization  
- **Security Checks**: Detects insecure defaults and missing SSL configuration
- **Connectivity Tests**: Validates database, Redis, email, and service connections

#### Manual Validation Tools

```bash
# Validate current environment
python scripts/validate_environment.py

# Validate specific environment file  
python scripts/validate_environment.py --env-file .env.production

# Strict validation (fail on warnings)
python scripts/validate_environment.py --strict

# Test deployment readiness
python scripts/test_deployment.py --env-file .env.production
```

#### Validation Features
- ✅ **Required Variable Detection**: Identifies missing critical variables
- ✅ **Security Validation**: Checks for insecure defaults and weak configurations  
- ✅ **URL Format Validation**: Validates database, Redis, and API URL formats
- ✅ **File Path Validation**: Ensures RSA keys and certificates exist
- ✅ **Service Connectivity**: Tests database, Redis, email, and external service connections
- ✅ **Docker Integration**: Validates Docker Compose environment variable injection

### Key Management

#### RSA Key Generation
```bash
# Generate production-grade 4096-bit keys
python scripts/generate_rsa_keys.py --key-size 4096

# Generate with custom output directory
python scripts/generate_rsa_keys.py --output-dir /secure/keys/

# Force overwrite existing keys (for rotation)
python scripts/generate_rsa_keys.py --force
```

#### Key Rotation Process
1. **Generate new keys** in separate directory
2. **Update environment variables** to point to new keys
3. **Deploy and restart services** (invalidates existing JWT tokens)
4. **Verify functionality** with test authentication
5. **Remove old keys** after verification

#### Security Best Practices
- Private keys have 600 file permissions (automatically set)
- Keys are never committed to version control (`.gitignore` created automatically)
- Regular rotation schedule (6-12 months for production)
- Hardware Security Module (HSM) support for enterprise deployments

### Environment Files

#### Development Environment
```bash
# Copy template and configure for development
cp .env.example .env.dev
# Set DJANGO_DEBUG=True, use local services
```

#### Staging Environment  
```bash
# Create staging configuration
cp .env.example .env.staging
# Configure with staging database, disable debug, enable SSL
```

#### Production Environment
```bash
# Create production configuration  
cp .env.example .env.production
# Use secure values, enable all security features
```

### Deployment Readiness Checklist

Before deploying to production, ensure:

- [ ] **Environment Validation**: `python scripts/validate_environment.py --strict` passes
- [ ] **Deployment Testing**: `python scripts/test_deployment.py` passes  
- [ ] **Security Review**: All placeholder values replaced with secure alternatives
- [ ] **RSA Keys**: Generated with 4096-bit strength and proper permissions
- [ ] **SSL Configuration**: HTTPS redirect enabled, HSTS configured
- [ ] **Service Connectivity**: Database, Redis, email, and monitoring services tested
- [ ] **Docker Environment**: All environment variables properly injected
- [ ] **CI/CD Pipeline**: Environment validation integrated into deployment workflow

### Documentation

For detailed environment setup instructions, see:
- **[Environment Setup Guide](docs/ENVIRONMENT_SETUP.md)** - Comprehensive configuration instructions
- **[Security Documentation](security.md)** - Security hardening and best practices
- **[CI/CD Documentation](ci/README.md)** - Pipeline configuration and secrets management

## Deployment

### Production Environment

```bash
# Generate production keys
make generate-keys

# Set up production environment
cp .env.example .env.production
# Edit .env.production with production values

# Start production services
make setup-prod

# Or manually
docker compose --profile production up -d
```

### Environment Variables

#### Required Configuration
| Variable | Description | Required |
|----------|-------------|----------|
| `DJANGO_SECRET_KEY` | Django secret key | Yes |
| `DATABASE_URL` | PostgreSQL connection string | Yes |
| `DJANGO_ALLOWED_HOSTS` | Comma-separated allowed hosts | Yes |

#### Authentication & Security
| Variable | Description | Default |
|----------|-------------|---------|
| `JWT_ACCESS_TOKEN_LIFETIME` | Access token lifetime (seconds) | 900 (15 min) |
| `JWT_REFRESH_TOKEN_LIFETIME` | Refresh token lifetime (seconds) | 604800 (7 days) |
| `RSA_PRIVATE_KEY_PATH` | Path to RSA private key | keys/private_key.pem |
| `RSA_PUBLIC_KEY_PATH` | Path to RSA public key | keys/public_key.pem |

#### Email Configuration (SMTP)  
| Variable | Description | Required |
|----------|-------------|----------|
| `SMTP_HOST` | SMTP server hostname | Yes |
| `SMTP_PORT` | SMTP server port | Yes |
| `SMTP_USER` | SMTP username | Yes |
| `SMTP_PASS` | SMTP password | Yes |
| `DEFAULT_FROM_EMAIL` | Default from email address | Yes |
| `USE_MOCK_EMAIL` | Use mock backend for development | No (False) |

#### Optional Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| `REDIS_URL` | Redis connection string | redis://localhost:6379/0 |
| `ADMIN_USERNAME` | Default admin username | admin |
| `ADMIN_EMAIL` | Default admin email | admin@electra.com |
| `ADMIN_PASSWORD` | Default admin password | - |

### Production Checklist

- [ ] Environment variables configured
- [ ] RSA keys generated and secured
- [ ] Database migrations applied
- [ ] Static files collected
- [ ] SSL certificate configured
- [ ] Firewall rules set
- [ ] Monitoring set up
- [ ] Backup procedures in place
- [ ] Log rotation configured
- [ ] Security headers verified

See [security.md](security.md) for detailed security hardening steps.

## Architecture

### Project Structure

```
electra/
├── electra_server/              # Django project
│   ├── settings/               # Split settings
│   │   ├── base.py            # Base settings
│   │   ├── dev.py             # Development settings  
│   │   └── prod.py            # Production settings
│   ├── apps/                  # Django applications
│   │   ├── auth/              # Authentication module
│   │       ├── models.py      # User, OTP, LoginAttempt models
│   │       ├── views.py       # Authentication API views
│   │       ├── serializers.py # DRF serializers
│   │       ├── permissions.py # Role-based permissions
│   │       ├── managers.py    # Custom model managers
│   │       ├── admin.py       # Django admin integration
│   │       ├── urls.py        # Authentication URL patterns
│   │       └── tests/         # Comprehensive test suite
│   │   └── elections/         # Election management module  
│   │       ├── models.py      # Election model with lifecycle management
│   │       ├── views.py       # Election management API views
│   │       ├── serializers.py # Election CRUD serializers
│   │       ├── permissions.py # Election-specific permissions
│   │       ├── admin.py       # Django admin for elections
│   │       ├── urls.py        # Election URL patterns
│   │       └── tests/         # Election test suite (models, views, permissions)
│   │   └── ballots/          # Ballot token management module
│   │       ├── models.py      # BallotToken, OfflineBallotQueue, UsageLog models
│   │       ├── views.py       # Ballot token API views (request, validate, stats)
│   │       ├── serializers.py # Ballot token CRUD and validation serializers
│   │       ├── permissions.py # Ballot-specific permissions and security
│   │       ├── admin.py       # Django admin for ballot management
│   │       ├── urls.py        # Ballot API URL patterns
│   │       └── tests/         # Ballot test suite (models, views, permissions)
│   ├── middleware.py          # Custom middleware
│   ├── logging.py             # JSON logging formatter
│   └── exceptions.py          # Custom exception handlers
├── apps/                      # Additional Django apps
│   └── health/                # Health check endpoints
├── tests/                     # Integration tests
├── scripts/                   # Utility scripts
├── keys/                      # RSA keys (not committed)
├── logs/                      # Application logs
├── static/                    # Static files
├── media/                     # Media files
├── docker-compose.yml         # Docker services
├── Dockerfile                 # Application container
├── Makefile                   # Development commands
├── requirements.txt           # Python dependencies
├── .env.example              # Environment template
└── README.md                 # This file
```

### Technology Stack

- **Framework**: Django 4.2 + Django REST Framework
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Authentication**: JWT with RSA-256 signing
- **Password Hashing**: Argon2
- **Containerization**: Docker + Docker Compose
- **Web Server**: Gunicorn (production)
- **Reverse Proxy**: Nginx (production)
- **Testing**: pytest + Factory Boy
- **Code Quality**: Black + isort + flake8
- **Security**: Bandit + Safety

### Security Features

- RSA-256 JWT signing with key rotation
- Argon2 password hashing
- CORS protection with restrictive defaults
- CSRF protection
- Security headers (HSTS, XSS protection, etc.)
- Request logging with UUID tracking
- Rate limiting ready
- SQL injection protection
- XSS protection
- Secure session handling

### Logging

All requests are logged with structured JSON including:
- Request ID (UUID)
- Timestamp
- HTTP method and path
- User information (if authenticated)
- Response time
- Status code
- Client IP address

Log files are stored in `logs/` directory and can be configured for centralized logging systems.

## Contributing

### Code Style

- Follow PEP 8
- Use Black for formatting
- Use isort for import sorting
- Maximum line length: 100 characters

### Development Workflow

1. Create feature branch from `main`
2. Write tests for new functionality
3. Implement feature
4. Run tests and linting
5. Update documentation
6. Submit pull request

### Commit Messages

Use conventional commits format:
```
feat: add user registration endpoint
fix: resolve JWT token validation issue
docs: update API documentation
test: add authentication tests
```

## Troubleshooting

### Common Issues

**Database connection errors**
```bash
# Check if PostgreSQL is running
docker-compose ps db

# View database logs
docker-compose logs db

# Reset database
docker-compose down -v
make up
make migrate
```

**Authentication errors**
```bash
# Check JWT token configuration
python manage.py shell -c "
from django.conf import settings
print('Access token lifetime:', settings.SIMPLE_JWT['ACCESS_TOKEN_LIFETIME'])
print('Refresh token lifetime:', settings.SIMPLE_JWT['REFRESH_TOKEN_LIFETIME'])
"

# Test authentication endpoints
curl -X POST http://localhost:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123","password_confirm":"test123","full_name":"Test User","matric_number":"T001","role":"student"}'

# Check user creation
python manage.py shell -c "
from electra_server.apps.auth.models import User
print('Total users:', User.objects.count())
print('Users:', list(User.objects.values('email', 'role')))
"
```

**Email/OTP issues**
```bash
# Check email backend configuration
python manage.py shell -c "
from django.conf import settings
print('Email backend:', settings.EMAIL_BACKEND)  
print('SMTP settings:', settings.EMAIL_HOST, settings.EMAIL_PORT)
print('Use mock email:', getattr(settings, 'USE_MOCK_EMAIL', False))
"

# Test password reset OTP creation
python manage.py shell -c "
from electra_server.apps.auth.models import PasswordResetOTP
print('Active OTPs:', PasswordResetOTP.objects.filter(is_used=False).count())
"
```

**Permission errors in Docker**
```bash
# Fix file permissions
sudo chown -R $USER:$USER .
```

### Getting Help

1. Check the logs: `make logs`
2. Verify health endpoint: `curl http://localhost:8000/api/health/`
3. Check Docker services: `docker-compose ps`
4. Review environment variables in `.env`
5. Consult [security.md](security.md) for security issues

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email admin@electra.com or create an issue in the repository.

---

**Built with ❤️ for secure and reliable voting systems**