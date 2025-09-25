# Windows Setup Scripts for Electra

This directory contains Windows-specific setup scripts to make development easier on Windows systems.

## Quick Start

### Option 1: Automated Setup (Recommended)

**PowerShell Script (Full Automation):**
```powershell
# Run as Administrator for best results
PowerShell -ExecutionPolicy Bypass -File setup-electra.ps1
```

**Batch Script (Manual Dependencies):**
```cmd
# Requires pre-installed Python, PostgreSQL, Flutter
setup_environment.bat
```

### Option 2: Manual Step-by-Step

1. **Install dependencies first** (Python 3.11+, PostgreSQL, Flutter)
2. **Run setup:** `setup_environment.bat`
3. **Start development:** `start_backend.bat` and `start_frontend.bat`

## Available Scripts

### 🚀 Setup Scripts

| Script | Description | Requirements |
|--------|-------------|--------------|
| `setup-electra.ps1` | Complete automated setup with optional software installation | PowerShell, Admin recommended |
| `setup_environment.bat` | Environment setup assuming dependencies are installed | Python, PostgreSQL |

### 🏃‍♂️ Development Scripts

| Script | Description | Purpose |
|--------|-------------|---------|
| `start_backend.bat` | Start Django development server | Daily backend development |
| `start_frontend.bat` | Start Flutter web development server | Daily frontend development |
| `validate_setup.bat` | Comprehensive environment validation | Troubleshooting |
| `run_tests.bat` | Run complete test suite with coverage | Testing & QA |

## Script Details

### setup-electra.ps1 (PowerShell)

**Full automated setup with optional software installation.**

```powershell
# Basic setup
.\setup-electra.ps1

# Skip software installation (if already installed)
.\setup-electra.ps1 -SkipSoftware

# Skip database setup
.\setup-electra.ps1 -SkipDatabase  

# Install Chocolatey and software packages
.\setup-electra.ps1 -InstallChocolatey

# Complete offline setup
.\setup-electra.ps1 -SkipSoftware -SkipDatabase -SkipKeys
```

**Features:**
- ✅ Chocolatey package manager installation
- ✅ Automatic software installation (Python, PostgreSQL, Redis, VS Code, Flutter)
- ✅ Virtual environment creation
- ✅ Environment file configuration
- ✅ Database setup and user creation
- ✅ RSA key generation
- ✅ Windows Firewall configuration
- ✅ Desktop shortcuts creation
- ✅ Final validation

### setup_environment.bat (Batch)

**Environment setup assuming dependencies are pre-installed.**

```cmd
setup_environment.bat
```

**Features:**
- ✅ Virtual environment creation
- ✅ Python dependency installation
- ✅ Environment file setup
- ✅ Database migrations
- ✅ Superuser creation
- ✅ Flutter dependency installation
- ✅ RSA key generation
- ✅ Environment validation

### start_backend.bat

**Start Django development server with comprehensive error handling.**

```cmd
start_backend.bat
```

**Features:**
- ✅ Virtual environment activation
- ✅ Environment file validation
- ✅ Startup information display
- ✅ Error handling and troubleshooting tips
- ✅ Automatic port availability check

**URLs when running:**
- Backend API: http://localhost:8000/
- Admin Panel: http://localhost:8000/admin/
- Health Check: http://localhost:8000/api/health/

### start_frontend.bat

**Start Flutter web development server.**

```cmd
start_frontend.bat
```

**Features:**
- ✅ Flutter installation check
- ✅ Dependency validation
- ✅ Code generation check
- ✅ Web server startup
- ✅ Alternative desktop app instructions

**URLs when running:**
- Flutter Web App: http://localhost:3000/
- Flutter DevTools: (URL displayed during startup)

### validate_setup.bat

**Comprehensive environment and setup validation.**

```cmd
validate_setup.bat
```

**Validation Tests:**
- ✅ Environment configuration validation
- ✅ Deployment readiness testing
- ✅ Database connectivity testing
- ✅ API endpoint testing
- ✅ Flutter setup validation
- ✅ Test suite execution

**Outputs:**
- Detailed validation report
- `validation_report.json` with status summary
- Coverage reports (if applicable)

### run_tests.bat

**Complete test suite with coverage reporting.**

```cmd
run_tests.bat
```

**Test Categories:**
- ✅ Django backend tests (auth, elections, ballots)
- ✅ Integration tests
- ✅ Flutter frontend tests (unit, widget, integration)
- ✅ Coverage report generation
- ✅ Test summary reporting

**Outputs:**
- HTML coverage report: `htmlcov/index.html`
- Flutter coverage: `electra_flutter/coverage/lcov.info`
- Test summary: `test_summary.json`

## Prerequisites

### Minimum Requirements
- Windows 10/11 (64-bit)
- PowerShell 5.1+ (for PowerShell scripts)
- Administrator access (recommended)
- Internet connection (for initial setup)

### Software Dependencies

**For setup-electra.ps1 (Auto-install):**
- None (script installs everything)

**For other scripts:**
- Python 3.11+
- PostgreSQL 13+
- Git for Windows
- Flutter SDK (for frontend)
- Redis (optional, recommended)

## Troubleshooting

### Common Issues

**PowerShell execution policy error:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Python not found:**
```cmd
# Ensure Python is in PATH
where python
# If not found, reinstall Python with "Add to PATH" option
```

**PostgreSQL connection errors:**
```cmd
# Check PostgreSQL service
net start postgresql-x64-15
# Verify connection
psql -U postgres -h localhost
```

**Flutter not found:**
```cmd
# Check Flutter installation
flutter doctor
# Add Flutter to PATH if needed
```

**Port already in use:**
```cmd
# Check what's using the port
netstat -ano | findstr :8000
# Kill the process if needed
taskkill /PID [PID_NUMBER] /F
```

### Script-Specific Issues

**setup-electra.ps1:**
- Run as Administrator for full functionality
- Check internet connection for package downloads
- Ensure Windows Defender allows script execution

**Database setup fails:**
- Manually create database user:
  ```sql
  CREATE USER electra_user WITH PASSWORD 'electra_dev_password';
  GRANT ALL PRIVILEGES ON DATABASE electra_db TO electra_user;
  ```

**Virtual environment issues:**
- Delete `venv` folder and run setup again
- Check Python installation integrity

## Development Workflow

### Daily Development
1. **Start Backend:** Double-click `start_backend.bat`
2. **Start Frontend:** Double-click `start_frontend.bat`
3. **Develop:** Edit code in VS Code or preferred IDE
4. **Test:** Run `run_tests.bat` before committing

### After Pulling Changes
1. **Update Dependencies:** Run `setup_environment.bat`
2. **Run Migrations:** Included in startup scripts
3. **Validate:** Run `validate_setup.bat`

### Troubleshooting Issues
1. **Validate Environment:** Run `validate_setup.bat`
2. **Check Logs:** Review console output
3. **Reset Environment:** Delete `venv`, run setup again

## Advanced Configuration

### Custom Database Settings
Edit `.env` file to customize database connection:
```env
DATABASE_URL=postgresql://username:password@localhost:5432/database_name
```

### Custom Ports
Update scripts to use different ports:
- Backend: Change `8000` to desired port in `start_backend.bat`
- Frontend: Change `3000` to desired port in `start_frontend.bat`

### Offline Development
- Run setup once with internet
- All subsequent development can be offline
- See ACTIVATE.md for offline-specific configuration

## Support

### Documentation
- **Complete Setup Guide:** [ACTIVATE.md](./ACTIVATE.md)
- **Main Documentation:** [README.md](./README.md)
- **Security Guide:** [security.md](./security.md)

### Getting Help
1. Check script output for error messages
2. Run `validate_setup.bat` for diagnostic information
3. Review logs in console windows
4. Check environment file configuration

### Contributing
When modifying scripts:
1. Test on clean Windows installation
2. Update this documentation
3. Ensure error handling is comprehensive
4. Test both admin and non-admin execution