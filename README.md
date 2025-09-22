# Electra Server

A production-grade Django backend for the Electra voting system, built with security, scalability, and maintainability in mind.

## Features

🔐 **Security First**
- JWT authentication with RSA-256 signing
- Argon2 password hashing
- Comprehensive security headers
- Request logging and monitoring
- Rate limiting and CORS protection

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

### Authentication
- `POST /api/auth/register/` - User registration
- `POST /api/auth/login/` - User login
- `POST /api/auth/logout/` - User logout
- `POST /api/auth/token/refresh/` - Refresh JWT token
- `GET /api/auth/profile/` - Get user profile
- `PUT /api/auth/profile/update/` - Update user profile

### Admin
- `/admin/` - Django admin interface

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

- `tests/test_health.py` - Health endpoint tests
- `tests/test_auth.py` - Authentication tests
- `apps/*/tests.py` - App-specific tests

### Writing Tests

```python
# Example test
from django.test import TestCase
from rest_framework.test import APITestCase
from django.contrib.auth import get_user_model

User = get_user_model()

class MyTest(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='test',
            email='test@electra.com',
            password='testpass123',
            matric_staff_id='U1234567'
        )
    
    def test_something(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.get('/api/endpoint/')
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

| Variable | Description | Required |
|----------|-------------|----------|
| `DJANGO_SECRET_KEY` | Django secret key | Yes |
| `DATABASE_URL` | PostgreSQL connection string | Yes |
| `REDIS_URL` | Redis connection string | Yes |
| `DJANGO_ALLOWED_HOSTS` | Comma-separated allowed hosts | Yes |
| `EMAIL_HOST_USER` | SMTP username | Yes |
| `EMAIL_HOST_PASSWORD` | SMTP password | Yes |
| `RSA_PRIVATE_KEY_PATH` | Path to RSA private key | Yes |
| `RSA_PUBLIC_KEY_PATH` | Path to RSA public key | Yes |
| `ADMIN_USERNAME` | Default admin username | No |
| `ADMIN_EMAIL` | Default admin email | No |
| `ADMIN_PASSWORD` | Default admin password | No |

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
├── electra_server/          # Django project
│   ├── settings/           # Split settings
│   │   ├── base.py        # Base settings
│   │   ├── dev.py         # Development settings
│   │   └── prod.py        # Production settings
│   ├── middleware.py      # Custom middleware
│   ├── logging.py         # JSON logging formatter
│   └── exceptions.py      # Custom exception handlers
├── apps/                  # Django applications
│   ├── auth_app/         # Authentication
│   └── health/           # Health checks
├── tests/                # Test suite
├── scripts/              # Utility scripts
├── keys/                 # RSA keys (not committed)
├── logs/                 # Application logs
├── static/               # Static files
├── media/                # Media files
├── docker-compose.yml    # Docker services
├── Dockerfile           # Application container
├── Makefile            # Development commands
├── requirements.txt    # Python dependencies
├── .env.example       # Environment template
└── README.md         # This file
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
# Check RSA keys exist
ls -la keys/

# Regenerate keys if missing
make generate-keys

# Restart application
docker-compose restart web
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