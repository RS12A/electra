# Windows Automation Tools for Electra Project

This directory contains comprehensive Windows automation tools that fully set up both testing (debug) and production environments offline, from backend to frontend to testing.

## 🚀 Quick Start

### Option 1: Basic Setup (Recommended for first-time users)
```cmd
python windows_automation.py
```

### Option 2: Complete Setup (Full automation)
```cmd  
python windows_automation_complete.py
```

### With Flutter Disabled
```cmd
python windows_automation_complete.py --disable-flutter
```

## 📋 Features

### ✅ Environment Configuration
- **Debug Mode**: Offline-compatible test environment with working defaults
- **Production Mode**: User-prompted configuration for production deployment
- **Automatic .env Generation**: No placeholders, fully functional configurations
- **Secure Credential Handling**: Passwords masked in logs, files secured

### ✅ Infrastructure Setup
- **Python Virtual Environment**: Offline-compatible with system packages
- **PostgreSQL Database**: Automatic detection, database and user creation
- **Redis Integration**: WSL and Windows support with auto-detection
- **RSA Key Generation**: JWT signing keys with cryptographic fallback

### ✅ Application Setup  
- **Django Migrations**: Automatic makemigrations and migrate
- **Superuser Creation**: Non-interactive admin account setup
- **Test Data Seeding**: Sample data for debug mode testing
- **Flutter Frontend**: Optional pub get and code generation

### ✅ Testing & Validation
- **Backend Tests**: Pytest integration with proper environment setup
- **Flutter Tests**: Widget and UI testing (when enabled)
- **Connectivity Validation**: Database, Redis, and service checks
- **Environment Validation**: Comprehensive configuration verification

### ✅ Windows Integration
- **Batch Scripts**: Easy-to-use activation scripts for daily development
- **Documentation Generation**: Comprehensive WINDOWS_ACTIVATE.md guide
- **Error Handling**: Graceful failures with helpful error messages
- **Offline Compatibility**: Full functionality without internet in debug mode

## 🛠 Script Comparison

| Feature | windows_automation.py | windows_automation_complete.py |
|---------|----------------------|--------------------------------|
| Environment Setup | ✅ | ✅ |
| Python Virtual Env | ✅ | ✅ |
| Database Setup | ❌ | ✅ |
| Django Migrations | ❌ | ✅ |
| Redis Integration | ❌ | ✅ |
| Flutter Setup | ❌ | ✅ |
| Testing | ❌ | ✅ |
| Documentation | ❌ | ✅ |
| Batch Scripts | ❌ | ✅ |

## 🔧 Requirements

### System Requirements
- Windows 10/11
- Python 3.8+
- PowerShell or Command Prompt

### Optional Components
- PostgreSQL 12+ (for database functionality)
- Redis (via WSL or Windows installation)
- Flutter SDK (for frontend development)
- Git for Windows

## 🏃‍♂️ Usage Scenarios

### Scenario 1: Developer Onboarding
```cmd
# New developer setting up for the first time
python windows_automation_complete.py
# Select: 1 (Debug mode)
# Provides working offline environment immediately
```

### Scenario 2: Production Deployment
```cmd
# Setting up for production server
python windows_automation_complete.py  
# Select: 2 (Production mode)
# Enter production database, email, and admin credentials
```

### Scenario 3: Backend-Only Development
```cmd
# Working only on backend/API
python windows_automation_complete.py --disable-flutter
# Skips Flutter setup and testing
```

### Scenario 4: Quick Environment Check
```cmd
# Just want environment and venv setup
python windows_automation.py
# Minimal setup - environment files and Python venv only
```

## 📁 Generated Files

After running the automation tools, you'll have:

```
electra/
├── .env                          # Environment configuration
├── venv/                         # Python virtual environment
├── keys/                         # RSA keys for JWT
│   ├── private_key.pem
│   └── public_key.pem
├── start_backend.bat             # Django server startup
├── start_frontend.bat            # Flutter app startup (if enabled)
├── validate_setup.bat            # Environment validation
├── run_tests.bat                 # Test suite execution
└── WINDOWS_ACTIVATE.md           # Comprehensive usage guide
```

## 🐛 Troubleshooting

### Common Issues

**1. Python Virtual Environment Fails**
- Ensure Python 3.8+ is installed and in PATH
- Run as Administrator if permission issues occur
- Delete existing `venv` folder and retry

**2. PostgreSQL Connection Issues**  
- Install PostgreSQL and ensure service is running
- Check Windows services: `sc query postgresql*`
- Verify postgres user exists and has privileges

**3. Redis Not Found**
- Install Redis via WSL: `wsl --install` then `sudo apt install redis-server`
- Or install Redis for Windows
- Check connection: `redis-cli ping`

**4. Flutter Issues (if enabled)**
- Install Flutter SDK and add to PATH
- Run `flutter doctor` to check dependencies
- Use `--disable-flutter` flag to skip

**5. Permission Errors**
- Run PowerShell or Command Prompt as Administrator
- Check Windows Defender/Antivirus isn't blocking files
- Ensure Windows execution policy allows script execution

### Debug Information

Both scripts provide detailed logging:
- ✅ Green: Successful operations
- ⚠️ Yellow: Warnings (continue with caution)  
- ❌ Red: Errors (may require intervention)
- ℹ️ Blue: Informational messages

### Getting Help

1. Check `WINDOWS_ACTIVATE.md` after running complete setup
2. Run `validate_setup.bat` to check system configuration
3. Review console output for specific error messages
4. Check Windows Event Viewer for system-level issues

## 🔒 Security Considerations

### Credential Handling
- Passwords are masked in console output and logs
- Environment files are set with restrictive permissions
- Actual secrets stored separately from display values
- Users warned about not committing .env files

### File Security
- `.env` files created with owner-only permissions where supported
- RSA keys generated with appropriate cryptographic standards
- Database connections use parameterized queries
- No hardcoded credentials in source code

### Network Security
- Debug mode designed for offline use
- Production mode allows custom security configurations
- HTTPS/TLS settings configurable for production
- CORS and CSRF protection properly configured

## 🚀 Advanced Usage

### Custom Database Configuration
```cmd
# When prompted in production mode, provide:
Database name: my_electra_db
Database user: my_user  
Database password: [secure_password]
Database host: localhost
Database port: 5432
```

### Custom Redis Configuration
```cmd
# When prompted in production mode:
Redis host: localhost
Redis port: 6379
Redis password: [optional_password]
```

### Environment Variables
After setup, you can modify `.env` file directly:
```env
# Example customizations
DJANGO_DEBUG=True
DATABASE_URL=postgresql://user:pass@host:port/db
REDIS_URL=redis://localhost:6379/0
UNIVERSITY_NAME=Your University Name
```

### Multiple Environments
```cmd
# Create separate environments
mkdir electra_dev && cd electra_dev
python ../windows_automation_complete.py
# Select debug mode

mkdir electra_prod && cd electra_prod  
python ../windows_automation_complete.py
# Select production mode
```

## 📊 Performance & Optimization

### Offline Optimization
- Debug mode uses local mock services
- Virtual environment created with system packages
- No network calls required for basic functionality
- Flutter assets cached locally

### Production Optimization
- Environment-specific Django settings
- Database connection pooling configured
- Redis caching enabled
- Static file serving optimized

### Development Workflow
```cmd
# Daily development routine
start_backend.bat          # Start Django server
start_frontend.bat         # Start Flutter app (separate terminal)
validate_setup.bat         # Verify environment (as needed)
run_tests.bat             # Run test suite
```

---

## 📝 Changelog

### Version 1.0 (Initial Release)
- ✅ Complete Windows automation for Electra project
- ✅ Debug and Production mode support
- ✅ Full offline compatibility
- ✅ PostgreSQL and Redis integration
- ✅ Django and Flutter setup
- ✅ Comprehensive testing and validation
- ✅ Security-hardened credential handling
- ✅ Batch script generation
- ✅ Complete documentation

---

**Created by**: Windows Automation Tool for Electra Project  
**Compatible with**: Windows 10/11, Python 3.8+, Django 4.2+, Flutter 3.0+  
**License**: Same as Electra project