# 🗳️ Electra Django Server

A complete, production-grade Django backend for the Electra University Voting System. Built with enterprise-level security, structured logging, comprehensive testing, and Docker deployment ready.

## 🚀 Features

### 🔐 Security & Authentication
- **Argon2 Password Hashing**: Industry-standard password security
- **JWT Authentication**: Short-lived access tokens with refresh token rotation
- **RSA-4096 Digital Signatures**: Cryptographic vote integrity
- **CORS & CSRF Protection**: Comprehensive cross-origin and request forgery protection
- **Rate Limiting**: Configurable request throttling
- **Security Headers**: HSTS, XSS protection, clickjacking prevention

### 🏗️ Architecture
- **Django 5.2+ Framework**: Latest Django with REST Framework
- **PostgreSQL Database**: Production-ready with connection pooling
- **Redis Caching**: High-performance caching and session storage
- **Structured Logging**: JSON logging with request ID tracking
- **Docker Deployment**: Production-ready containerization

### 📊 API Features
- **RESTful API**: Clean, consistent API design
- **Health Check Endpoints**: Comprehensive system monitoring
- **User Management**: Registration, authentication, profile management
- **Election Management**: Create and manage voting events
- **Request Logging**: Detailed audit trails with UUID tracking

## 📋 Prerequisites

- Python 3.12+
- PostgreSQL 12+
- Redis 6+ (optional, for caching)
- Docker & Docker Compose
- Make (for build automation)

## 🚀 Quick Start

### 1. Clone and Setup Environment

```bash
git clone https://github.com/RS12A/electra.git
cd electra
cp .env.example .env
# Edit .env with your configuration
```

### 2. Generate RSA Keys

```bash
cd electra_server
python scripts/generate_rsa_keys.py
```

### 3. Start with Docker (Recommended)

```bash
# Build and start all services
make build
make up

# Run migrations and seed data
make migrate-prod
make seed-prod

# Create admin user
make createsuperuser-prod
```

### 4. Manual Development Setup

```bash
# Install dependencies
make install-deps

# Setup database (PostgreSQL required)
export DATABASE_URL="postgresql://user:pass@localhost:5432/electra_server"

# Run migrations
make migrate

# Seed initial data
make seed

# Start development server
make runserver
```

## 🔧 Configuration

### Environment Variables

All configuration is done through environment variables. Copy `.env.example` to `.env` and set your values:

#### Core Settings
```bash
DEBUG=False
DJANGO_SECRET_KEY=your_production_secret_key_here
DJANGO_SETTINGS_MODULE=electra_server.settings.prod
```

#### Database
```bash
DATABASE_URL=postgresql://user:pass@localhost:5432/electra_server
```

#### JWT Authentication
```bash
JWT_SECRET_KEY=your_jwt_secret_key_here
JWT_REFRESH_SECRET_KEY=your_jwt_refresh_secret_key_here
```

#### RSA Keys
```bash
RSA_PRIVATE_KEY_PATH=keys/private.pem
RSA_PUBLIC_KEY_PATH=keys/public.pem
```

#### CORS & Security
```bash
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://voting.yourdomain.com
ALLOWED_HOSTS=yourdomain.com,voting.yourdomain.com
```

#### Email Configuration
```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@domain.com
SMTP_PASS=your_app_password
SMTP_FROM="Electra Voting <noreply@yourdomain.com>"
```

#### University Settings
```bash
UNIVERSITY_NAME="Your University Name"
UNIVERSITY_ACRONYM="YUN"
```

### Settings Environments

- **Development**: `electra_server.settings.dev`
- **Production**: `electra_server.settings.prod`

## 🛠️ Development

### Available Make Commands

```bash
make help                 # Show all available commands
make build               # Build Docker containers
make up                  # Start all services
make down               # Stop all services
make migrate            # Run Django migrations
make seed               # Seed database with initial data
make test               # Run tests
make createsuperuser    # Create Django superuser
make shell              # Open Django shell
make logs               # Show Docker logs
make clean              # Clean up Docker resources
```

### Database Management

```bash
# Create migrations after model changes
make makemigrations

# Run migrations
make migrate

# Reset database (WARNING: destroys all data)
make reset-db

# Backup database
make backup-db
```

### Testing

```bash
# Run Django tests
make test

# Run with coverage
make test-coverage

# Run pytest
make pytest

# Run tests in Docker
make pytest-docker
```

### Code Quality

```bash
# Format code
make format

# Run linting
make lint

# Security check
make security-check

# System check
make check
```

## 📊 API Documentation

### Authentication Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/register/` | POST | User registration |
| `/api/auth/login/` | POST | User login |
| `/api/auth/logout/` | POST | User logout |
| `/api/auth/refresh/` | POST | Token refresh |
| `/api/auth/profile/` | GET | Get user profile |
| `/api/auth/profile/update/` | PUT/PATCH | Update profile |

### Health Check Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health/` | GET | Detailed health check |
| `/api/ping/` | GET | Simple health check |

### Example API Usage

#### User Registration
```bash
curl -X POST http://localhost:8001/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "matric_number": "KWU/SCI/001",
    "email": "student@kwasu.edu.ng",
    "first_name": "John",
    "last_name": "Doe",
    "password": "securepass123!",
    "password_confirm": "securepass123!",
    "faculty": "Science",
    "department": "Computer Science",
    "level": "300"
  }'
```

#### User Login
```bash
curl -X POST http://localhost:8001/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "matric_number": "KWU/SCI/001",
    "password": "securepass123!"
  }'
```

#### Health Check
```bash
curl http://localhost:8001/api/health/
```

## 🐳 Docker Deployment

### Development Environment

```bash
# Start development services
docker-compose -f docker-compose.django.yml up -d

# View logs
docker-compose -f docker-compose.django.yml logs -f web
```

### Production Environment

```bash
# Build production images
docker-compose -f docker-compose.django.yml build --no-cache

# Start production services
docker-compose -f docker-compose.django.yml up -d

# Run initial setup
docker-compose -f docker-compose.django.yml exec web python manage.py migrate
docker-compose -f docker-compose.django.yml exec web python manage.py seed_initial_data
docker-compose -f docker-compose.django.yml exec web python manage.py createsuperuser
```

## 🔒 Security

### Production Security Checklist

- [ ] Generate secure RSA keys with `make generate-keys`
- [ ] Set strong JWT secrets (minimum 32 characters)
- [ ] Configure HTTPS with valid SSL certificates
- [ ] Set proper CORS origins
- [ ] Enable database SSL connections
- [ ] Configure proper firewall rules
- [ ] Set up monitoring and alerting
- [ ] Regular security updates
- [ ] Backup encryption keys securely

For detailed security information, see [security.md](security.md).

### Key Generation

```bash
# Generate 4096-bit RSA keys
python scripts/generate_rsa_keys.py --key-size 4096

# Validate existing keys
python scripts/generate_rsa_keys.py --validate

# Set proper permissions
chmod 600 keys/private.pem
chmod 644 keys/public.pem
```

## 📝 Logging

The application provides structured JSON logging with request ID tracking:

```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "level": "INFO",
  "message": "HTTP request processed",
  "request_id": "uuid-here",
  "method": "POST",
  "path": "/api/auth/login/",
  "status_code": 200,
  "response_time_ms": 150,
  "user_id": "user-uuid",
  "ip_address": "192.168.1.100"
}
```

## 🧪 Testing

### Test Structure

- `tests/test_health.py`: Health endpoint tests
- `tests/test_auth.py`: Authentication flow tests
- `apps/*/tests.py`: App-specific tests

### Running Tests

```bash
# Run all tests
python manage.py test

# Run specific test file
python manage.py test tests.test_health

# Run with pytest
pytest

# Run with coverage
coverage run manage.py test
coverage report
coverage html
```

## 📦 Dependencies

### Core Dependencies
- **Django 5.2.6**: Web framework
- **djangorestframework 3.16.1**: REST API framework
- **psycopg2-binary 2.9.10**: PostgreSQL adapter
- **django-environ 0.12.0**: Environment configuration
- **argon2-cffi 25.1.0**: Password hashing
- **djangorestframework-simplejwt 5.5.1**: JWT authentication
- **django-cors-headers 4.9.0**: CORS handling

### Development Dependencies
- **pytest 8.4.2**: Testing framework
- **pytest-django 4.11.1**: Django pytest integration
- **factory-boy 3.3.3**: Test data generation
- **django-extensions 4.1**: Development tools

See [requirements.txt](electra_server/requirements.txt) for complete list.

## 🚀 Deployment

### Production Checklist

1. **Environment Configuration**
   ```bash
   cp .env.example .env
   # Set production values in .env
   ```

2. **Generate Keys**
   ```bash
   python scripts/generate_rsa_keys.py
   ```

3. **Build and Deploy**
   ```bash
   make build
   make up
   make migrate-prod
   make seed-prod
   ```

4. **SSL/TLS Setup**
   - Configure reverse proxy (Nginx/Apache)
   - Install SSL certificates
   - Enable HSTS headers

5. **Monitoring Setup**
   - Configure log aggregation
   - Set up health check monitoring
   - Configure alerting

### Recommended Production Stack

- **Reverse Proxy**: Nginx with SSL termination
- **Application**: Django with Gunicorn
- **Database**: PostgreSQL with connection pooling
- **Cache**: Redis for sessions and caching
- **Monitoring**: Prometheus + Grafana
- **Logging**: ELK Stack or similar

## 📈 Monitoring

### Health Check Endpoints

- `GET /api/health/`: Comprehensive health check
- `GET /api/ping/`: Simple availability check

### Metrics Monitored

- Database connectivity
- Cache availability
- File system access
- Memory usage
- Disk space
- Response times

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add/update tests
5. Update documentation
6. Submit a pull request

### Development Guidelines

- Follow Django best practices
- Write comprehensive tests
- Use type hints where appropriate
- Follow PEP 8 style guide
- Update documentation for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/RS12A/electra/issues)
- **Security**: security@yourdomain.com
- **Documentation**: [Wiki](https://github.com/RS12A/electra/wiki)

---

Built with ❤️ for secure, transparent university elections.