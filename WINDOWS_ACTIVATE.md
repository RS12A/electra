# Windows Activation Guide for Electra

This guide provides complete instructions for setting up and using the Electra digital voting system on Windows using the automated setup tools.

## Quick Setup

### Option 1: Python Setup Tool (Recommended)
```cmd
python setup/windows_setup.py
```

### Option 2: PowerShell Setup Tool
```powershell
PowerShell -ExecutionPolicy Bypass -File setup/windows_setup.ps1
```

## Command Line Options

### Python Tool
```cmd
# Interactive mode (prompts for Debug/Production)
python setup/windows_setup.py

# Debug mode (offline test environment)
python setup/windows_setup.py --mode debug

# Production mode (user-configured environment)  
python setup/windows_setup.py --mode production

# Offline mode (no network installs)
python setup/windows_setup.py --mode debug --offline

# Skip dependency installation (use global packages)
python setup/windows_setup.py --skip-python-deps --skip-flutter-deps

# Force overwrite existing configuration
python setup/windows_setup.py --mode debug --force
```

### PowerShell Tool
```powershell
# Interactive mode (prompts for Debug/Production)
PowerShell -ExecutionPolicy Bypass -File setup/windows_setup.ps1

# Debug mode (offline test environment)
PowerShell -ExecutionPolicy Bypass -File setup/windows_setup.ps1 -Mode Debug

# Production mode (user-configured environment)
PowerShell -ExecutionPolicy Bypass -File setup/windows_setup.ps1 -Mode Production

# Offline mode (no network installs)
PowerShell -ExecutionPolicy Bypass -File setup/windows_setup.ps1 -Mode Debug -Offline

# Skip dependency installation (use global packages)
PowerShell -ExecutionPolicy Bypass -File setup/windows_setup.ps1 -SkipPythonDeps -SkipFlutterDeps

# Force overwrite existing configuration
PowerShell -ExecutionPolicy Bypass -File setup/windows_setup.ps1 -Mode Debug -Force
```

## What the Setup Tool Does

1. **Environment Configuration**
   - Creates `.env` file with secure secrets (Debug) or user-provided values (Production)
   - Backs up existing environment files to `setup/env_backups/`
   - Generates `.env.lock` with checksum for integrity verification

2. **Python Environment**
   - Creates Python virtual environment with `--system-site-packages` if requested
   - Installs dependencies from `requirements.txt` (unless skipped)
   - Supports offline installation using local wheel cache

3. **Database Setup**
   - Creates PostgreSQL database (`electra_debug` or `electra_prod`)
   - Creates database user with proper privileges
   - Installs required PostgreSQL extensions (uuid-ossp, pgcrypto)
   - Runs Django migrations to create schema

4. **Security**
   - Generates RSA key pairs for JWT signing
   - Creates Django superuser with secure password
   - Sets appropriate file permissions on sensitive files

5. **Redis Configuration**
   - Detects Redis availability (WSL or Windows)
   - Configures Redis URL in environment

6. **Flutter Frontend** (Optional)
   - Installs Flutter dependencies (unless skipped)
   - Configures API endpoints for local development
   - Sets up development server configuration

7. **Verification**
   - Runs comprehensive system checks
   - Tests database connectivity
   - Validates Django configuration
   - Performs acceptance tests

## Starting Services

### Backend (Django)
```powershell
PowerShell -ExecutionPolicy Bypass -File setup/start_backend.ps1
```

The backend will be available at:
- **API Base**: http://localhost:8000/
- **Admin Panel**: http://localhost:8000/admin/
- **Health Check**: http://localhost:8000/api/health/

### Frontend (Flutter) 
```powershell
PowerShell -ExecutionPolicy Bypass -File setup/start_frontend.ps1
```

The frontend will be available at:
- **Web App**: http://localhost:3000/

### Custom Ports
```powershell
# Backend on port 9000
PowerShell -ExecutionPolicy Bypass -File setup/start_backend.ps1 -Port 9000

# Frontend on port 4000
PowerShell -ExecutionPolicy Bypass -File setup/start_frontend.ps1 -Port 4000
```

## Stopping Services

### Backend
```powershell
PowerShell -ExecutionPolicy Bypass -File setup/stop_backend.ps1
```

### Frontend
```powershell
PowerShell -ExecutionPolicy Bypass -File setup/stop_frontend.ps1
```

## Verification

Run the comprehensive verification script to check all components:

```powershell
PowerShell -ExecutionPolicy Bypass -File setup/verify_stack.ps1
```

### Verification Options
```powershell
# Skip specific tests
PowerShell -ExecutionPolicy Bypass -File setup/verify_stack.ps1 -SkipFrontend
PowerShell -ExecutionPolicy Bypass -File setup/verify_stack.ps1 -SkipDatabase

# Verbose output
PowerShell -ExecutionPolicy Bypass -File setup/verify_stack.ps1 -Verbose
```

The verification script tests:
- Environment configuration
- Python virtual environment
- Database connectivity
- Redis connectivity
- Backend API health
- Frontend functionality

## Database Management

### Standalone Database Setup
If you need to create the database separately:

```powershell
# PowerShell version
PowerShell -ExecutionPolicy Bypass -File setup/create_local_postgres_db.ps1

# Python version
python setup/create_local_postgres_db.py
```

### Custom Database Configuration
```powershell
# Create production database
PowerShell -ExecutionPolicy Bypass -File setup/create_local_postgres_db.ps1 -DatabaseName electra_prod -DatabaseUser electra_prod

# Create on remote server
python setup/create_local_postgres_db.py --host remote-server --port 5433
```

## Troubleshooting

### Common Issues

#### 1. Virtual Environment Issues
```cmd
# Check if venv exists
dir venv

# Recreate venv
python setup/windows_setup.py --mode debug --force
```

#### 2. Database Connection Issues
```cmd
# Check PostgreSQL service
sc query postgresql*

# Start PostgreSQL service  
net start postgresql*

# Test database connection
psql -U postgres -h localhost
```

#### 3. Redis Connection Issues
```cmd
# For WSL Redis
wsl redis-server --daemonize yes
wsl redis-cli ping

# For Windows Redis
redis-server
```

#### 4. Permission Errors
```powershell
# Run PowerShell as Administrator
Start-Process PowerShell -Verb RunAs

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 5. Port Conflicts
The setup uses these default ports:
- **Backend**: http://localhost:8000
- **Frontend**: http://localhost:3000  
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

If ports are in use, modify the start scripts or configuration files.

### Environment Variables

The `.env` file contains all configuration. Key variables:

#### Debug Mode
```env
DJANGO_DEBUG=True
DJANGO_SECRET_KEY=[auto-generated]
DATABASE_URL=postgresql://electra_debug:[password]@localhost:5432/electra_debug
REDIS_URL=redis://localhost:6379/0
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
```

#### Production Mode
```env
DJANGO_DEBUG=False
DJANGO_SECRET_KEY=[user-provided or generated]
DATABASE_URL=postgresql://[user]:[password]@[host]:[port]/[database]
REDIS_URL=[user-provided]
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
```

### Log Files

- **Setup Log**: `setup/setup.log` (contains non-sensitive setup information)
- **Environment Backups**: `setup/env_backups/[timestamp]/` (contains previous .env files)
- **Django Logs**: Check console output when running backend

### Re-running Setup

To completely reset and re-run setup:

```cmd
# Force overwrite all configuration
python setup/windows_setup.py --mode debug --force

# Or delete files manually and re-run
del .env
del .env.lock
rmdir /s venv
python setup/windows_setup.py --mode debug
```

## Offline Operation

The setup tools support complete offline operation:

1. **Prepare Offline Environment**:
   - Install Python, PostgreSQL, Redis, Flutter manually
   - Download Python wheels: `pip download -r requirements.txt -d wheels/`
   - Populate Flutter cache: `flutter precache`

2. **Run Offline Setup**:
   ```cmd
   python setup/windows_setup.py --mode debug --offline
   ```

3. **Offline Limitations**:
   - Cannot install missing system packages
   - Uses local wheel cache for Python dependencies
   - Uses local Flutter cache for dependencies
   - No network connectivity tests

## Security Notes

### Generated Secrets
- Django secret keys are cryptographically secure
- Database passwords are randomly generated
- Admin passwords are securely generated
- RSA keys are 4096-bit for JWT signing

### File Permissions
- `.env` files have restricted permissions (600)
- RSA private keys are protected
- Sensitive data excluded from logs

### Production Recommendations
1. Change all default passwords after setup
2. Use environment-specific secrets management
3. Enable SSL/TLS in production
4. Regularly rotate JWT signing keys
5. Monitor setup logs for security events

## Development Workflow

### Daily Development
1. Start backend: `PowerShell -ExecutionPolicy Bypass -File setup/start_backend.ps1`
2. Start frontend: `PowerShell -ExecutionPolicy Bypass -File setup/start_frontend.ps1`
3. Open http://localhost:8000/admin/ for backend admin
4. Open http://localhost:3000/ for frontend app

### Testing
```powershell
# Run verification
PowerShell -ExecutionPolicy Bypass -File setup/verify_stack.ps1

# Run backend tests (if available)
venv\Scripts\activate
python -m pytest

# Run frontend tests (if available)
cd electra_flutter
flutter test
```

### Database Operations
```cmd
# Activate virtual environment
venv\Scripts\activate

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Open Django shell
python manage.py shell
```

## Support

If you encounter issues not covered in this guide:

1. Check the setup log: `setup/setup.log`
2. Run verification: `PowerShell -ExecutionPolicy Bypass -File setup/verify_stack.ps1 -Verbose`
3. Re-run setup with force flag: `python setup/windows_setup.py --force`
4. Check individual component status:
   - PostgreSQL: `sc query postgresql*`
   - Python: `python --version`
   - Flutter: `flutter doctor`

---

Generated by Electra Windows Setup Tool - Production-grade automation for Windows development environment.