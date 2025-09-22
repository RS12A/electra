# Electra Server - Secure Digital Voting System

A production-grade Django backend for the Electra voting system, built with security, scalability, and maintainability in mind. Features secure ballot token management, RSA cryptographic signatures, and offline voting capabilities.

## Features

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

### 3. Start Development Environment

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