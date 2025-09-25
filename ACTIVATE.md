# Electra Project - Windows Local Setup Guide

**Complete step-by-step instructions for running the Electra secure digital voting system locally on Windows without Docker**

This guide provides detailed instructions for setting up the entire Electra project on a Windows development environment for offline development. The setup includes both the Django backend server and Flutter frontend application.

## Table of Contents

- [Prerequisites](#prerequisites)
- [System Requirements](#system-requirements)
- [Part 1: Windows Environment Setup](#part-1-windows-environment-setup)
- [Part 2: Django Backend Setup](#part-2-django-backend-setup)
- [Part 3: Flutter Frontend Setup](#part-3-flutter-frontend-setup)
- [Part 4: Configuration & Security](#part-4-configuration--security)
- [Part 5: Running the Applications](#part-5-running-the-applications)
- [Part 6: Validation & Testing](#part-6-validation--testing)
- [Part 7: Troubleshooting](#part-7-troubleshooting)
- [Part 8: Offline Development](#part-8-offline-development)
- [Part 9: Development Tools & IDE Setup](#part-9-development-tools--ide-setup)
- [Part 10: Windows-Specific Optimizations](#part-10-windows-specific-optimizations)

---

## Prerequisites

Before starting, ensure you have:
- Windows 10/11 (64-bit)
- Administrator access to install software
- Stable internet connection for initial setup
- At least 8GB RAM and 20GB free disk space
- Basic knowledge of command line operations

---

## System Requirements

### Hardware Requirements
- **CPU**: Intel Core i3 or AMD Ryzen 3 (minimum), i5/Ryzen 5 recommended
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 20GB free space minimum
- **Network**: Internet connection for initial setup only

### Software Requirements
- Windows 10 version 1903 or later
- Windows PowerShell 5.1 or PowerShell 7+
- Git for Windows
- Modern web browser (Chrome, Firefox, Edge)

---

## Part 1: Windows Environment Setup

### Step 1.1: Install Git for Windows

1. **Download Git for Windows**
   ```
   Visit: https://git-scm.com/download/win
   ```

2. **Install Git with recommended settings**
   - Run the installer as Administrator
   - Choose "Use Git from the Windows Command Prompt"
   - Select "Checkout Windows-style, commit Unix-style line endings"
   - Choose "Use Windows' default console window"

3. **Verify Git installation**
   ```cmd
   git --version
   ```
   Expected output: `git version 2.x.x.windows.x`

### Step 1.2: Install Python 3.11+

1. **Download Python 3.11 or later**
   ```
   Visit: https://www.python.org/downloads/windows/
   ```

2. **Install Python with these important settings**
   - ✅ Check "Add Python to PATH"
   - ✅ Check "Install for all users" (if you have admin rights)
   - Choose "Customize installation"
   - ✅ Check all optional features
   - ✅ Check "Add Python to environment variables"
   - ✅ Check "Precompile standard library"

3. **Verify Python installation**
   ```cmd
   python --version
   pip --version
   ```
   Expected output: `Python 3.11.x` and `pip 23.x.x`

### Step 1.3: Install PostgreSQL Database

1. **Download PostgreSQL 15**
   ```
   Visit: https://www.postgresql.org/download/windows/
   ```

2. **Install PostgreSQL**
   - Run installer as Administrator
   - Remember the password you set for the 'postgres' user
   - Default port: 5432 (keep default)
   - Install Stack Builder components if prompted

3. **Verify PostgreSQL installation**
   ```cmd
   psql --version
   ```

4. **Create database for Electra**
   ```cmd
   # Connect to PostgreSQL (will prompt for password)
   psql -U postgres -h localhost
   
   # Create database and user
   CREATE DATABASE electra_db;
   CREATE USER electra_user WITH PASSWORD 'your_secure_password';
   GRANT ALL PRIVILEGES ON DATABASE electra_db TO electra_user;
   \q
   ```

### Step 1.4: Install Redis (Optional but Recommended)

1. **Download Redis for Windows**
   ```
   Visit: https://github.com/microsoftarchive/redis/releases
   Download: Redis-x64-3.0.504.msi
   ```

2. **Install and start Redis**
   - Run installer as Administrator
   - Start Redis service after installation
   - Default port: 6379

3. **Verify Redis installation**
   ```cmd
   redis-cli ping
   ```
   Expected output: `PONG`

### Step 1.5: Install Flutter SDK

1. **Download Flutter SDK**
   ```
   Visit: https://docs.flutter.dev/get-started/install/windows
   Download the stable channel ZIP file
   ```

2. **Extract Flutter SDK**
   ```
   Extract to: C:\flutter
   ```

3. **Add Flutter to System PATH**
   - Open System Properties → Advanced → Environment Variables
   - Add `C:\flutter\bin` to the PATH variable
   - Restart Command Prompt

4. **Verify Flutter installation**
   ```cmd
   flutter --version
   flutter doctor
   ```

5. **Install Android Studio (for Flutter development)**
   ```
   Visit: https://developer.android.com/studio
   Install with default settings
   Install Flutter and Dart plugins
   ```

---

## Part 2: Django Backend Setup

### Step 2.1: Clone the Repository

1. **Create a project directory**
   ```cmd
   mkdir C:\Development
   cd C:\Development
   ```

2. **Clone the Electra repository**
   ```cmd
   git clone https://github.com/RS12A/electra.git
   cd electra
   ```

### Step 2.2: Set Up Python Virtual Environment

1. **Create virtual environment**
   ```cmd
   python -m venv venv
   ```

2. **Activate virtual environment**
   ```cmd
   # For Command Prompt
   venv\Scripts\activate.bat
   
   # For PowerShell
   venv\Scripts\Activate.ps1
   ```

3. **Upgrade pip and install dependencies**
   ```cmd
   python -m pip install --upgrade pip
   pip install -r requirements.txt
   ```

### Step 2.3: Configure Environment Variables

1. **Copy environment template**
   ```cmd
   copy .env.example .env
   ```

2. **Edit .env file with Windows-appropriate settings**
   Open `.env` in your preferred editor and update:
   ```env
   # Core Django Settings
   DJANGO_SECRET_KEY=your-very-secure-secret-key-here
   DJANGO_DEBUG=True
   DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
   DJANGO_ENV=development
   
   # Database Configuration (adjust with your PostgreSQL settings)
   DATABASE_URL=postgresql://electra_user:your_secure_password@localhost:5432/electra_db
   
   # JWT Configuration
   JWT_SECRET_KEY=your-jwt-secret-key-here
   JWT_ACCESS_TOKEN_LIFETIME=900
   JWT_REFRESH_TOKEN_LIFETIME=604800
   
   # RSA Keys (will be generated in next step)
   RSA_PRIVATE_KEY_PATH=keys/private_key.pem
   RSA_PUBLIC_KEY_PATH=keys/public_key.pem
   
   # Email Configuration (for development, use mock backend)
   USE_MOCK_EMAIL=True
   EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
   DEFAULT_FROM_EMAIL=noreply@electra.local
   
   # Redis Configuration
   REDIS_URL=redis://localhost:6379/0
   
   # CORS Configuration
   CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
   CSRF_TRUSTED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
   
   # Security Settings (disabled for development)
   SECURE_SSL_REDIRECT=False
   
   # Admin Configuration
   ADMIN_USERNAME=admin
   ADMIN_EMAIL=admin@electra.local
   ADMIN_PASSWORD=admin123
   ```

### Step 2.4: Generate RSA Keys

1. **Generate RSA keys for JWT signing**
   ```cmd
   python scripts/generate_rsa_keys.py
   ```

2. **Verify keys were created**
   ```cmd
   dir keys\
   ```
   You should see `private_key.pem` and `public_key.pem`

### Step 2.5: Initialize Database

1. **Run database migrations**
   ```cmd
   python manage.py migrate
   ```

2. **Create superuser account**
   ```cmd
   python manage.py createsuperuser
   ```
   Follow prompts to create admin account

3. **Load initial data (optional)**
   ```cmd
   python manage.py seed_initial_data
   ```

### Step 2.6: Validate Backend Setup

1. **Run environment validation**
   ```cmd
   python scripts/validate_environment.py
   ```

2. **Test deployment readiness**
   ```cmd
   python scripts/test_deployment.py --skip-docker
   ```

---

## Part 3: Flutter Frontend Setup

### Step 3.1: Navigate to Flutter Directory

```cmd
cd electra_flutter
```

### Step 3.2: Install Flutter Dependencies

1. **Get Flutter packages**
   ```cmd
   flutter pub get
   ```

2. **Generate code**
   ```cmd
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

### Step 3.3: Configure Flutter App

1. **Update API configuration**
   Edit `lib/shared/constants/app_constants.dart`:
   ```dart
   class ApiConstants {
     static const String baseUrl = 'http://localhost:8000';
     static const String wsBaseUrl = 'ws://localhost:8000';
     // ... other constants
   }
   ```

2. **Configure university settings**
   Update university-specific settings in the same file:
   ```dart
   class UniversityConstants {
     static const String name = 'Your University Name';
     static const String abbreviation = 'YUN';
     static const String supportEmail = 'support@youruniversity.edu';
     // ... other settings
   }
   ```

### Step 3.4: Set Up Flutter Assets

1. **Create asset directories**
   ```cmd
   mkdir assets\images
   mkdir assets\icons
   mkdir assets\logos
   mkdir assets\fonts
   ```

2. **Add placeholder assets (optional)**
   ```cmd
   # Create empty placeholder files
   echo. > assets\images\kwasu_logo.png
   echo. > assets\images\election_banner.png
   echo. > assets\fonts\KWASU-Regular.ttf
   echo. > assets\fonts\KWASU-Bold.ttf
   echo. > assets\fonts\KWASU-Medium.ttf
   ```

### Step 3.5: Validate Flutter Setup

1. **Run Flutter doctor**
   ```cmd
   flutter doctor -v
   ```

2. **Run code analysis**
   ```cmd
   flutter analyze
   ```

3. **Run tests**
   ```cmd
   flutter test
   ```

---

## Part 4: Configuration & Security

### Step 4.1: Security Configuration

1. **Verify RSA key permissions**
   ```cmd
   # Ensure keys directory exists and has proper files
   dir keys\
   icacls keys\private_key.pem
   ```

2. **Configure Windows Firewall (if needed)**
   - Allow Python and Flutter through Windows Firewall
   - Open Windows Defender Firewall
   - Click "Allow an app or feature through Windows Defender Firewall"
   - Add Python.exe and Flutter if not already allowed

### Step 4.2: Development Environment Optimization

1. **Configure Git for the project**
   ```cmd
   cd C:\Development\electra
   git config user.name "Your Name"
   git config user.email "your.email@domain.com"
   ```

2. **Set up environment variables persistently**
   - Open System Properties → Advanced → Environment Variables
   - Add `ELECTRA_ENV=development` to User variables
   - Add `PYTHONPATH=C:\Development\electra` to User variables

---

## Part 5: Running the Applications

### Step 5.1: Start Django Backend Server

1. **Activate Python virtual environment**
   ```cmd
   cd C:\Development\electra
   venv\Scripts\activate.bat
   ```

2. **Start Django development server**
   ```cmd
   python manage.py runserver 0.0.0.0:8000
   ```

3. **Verify backend is running**
   ```
   Open browser: http://localhost:8000/api/health/
   ```
   You should see a health check JSON response.

4. **Access Django Admin**
   ```
   Open browser: http://localhost:8000/admin/
   Login with superuser credentials
   ```

### Step 5.2: Start Flutter Frontend App

1. **Open new Command Prompt window**
   ```cmd
   cd C:\Development\electra\electra_flutter
   ```

2. **Start Flutter app in debug mode**
   ```cmd
   flutter run -d chrome --web-port 3000
   ```
   For desktop application:
   ```cmd
   flutter run -d windows
   ```

3. **Verify Flutter app is running**
   - Web: http://localhost:3000
   - Desktop: Application window should open automatically

### Step 5.3: Validate Full System

1. **Test API connectivity from Flutter**
   - Open Flutter app
   - Navigate to login screen
   - Attempt to register a test user
   - Verify backend logs show API requests

2. **Check database connections**
   ```cmd
   python manage.py dbshell
   \dt
   \q
   ```

---

## Part 6: Validation & Testing

### Step 6.1: Backend Testing

1. **Run Django test suite**
   ```cmd
   cd C:\Development\electra
   venv\Scripts\activate.bat
   python -m pytest
   ```

2. **Run specific test modules**
   ```cmd
   # Test authentication
   python -m pytest electra_server/apps/auth/tests/ -v
   
   # Test elections
   python -m pytest electra_server/apps/elections/tests/ -v
   
   # Test ballot tokens
   python -m pytest electra_server/apps/ballots/tests/ -v
   ```

3. **Generate test coverage report**
   ```cmd
   python -m pytest --cov=electra_server --cov-report=html
   ```

### Step 6.2: Frontend Testing

1. **Run Flutter unit tests**
   ```cmd
   cd C:\Development\electra\electra_flutter
   flutter test
   ```

2. **Run Flutter integration tests**
   ```cmd
   flutter test integration_test/
   ```

3. **Generate Flutter test coverage**
   ```cmd
   flutter test --coverage
   ```

### Step 6.3: End-to-End Validation

1. **Complete user registration flow**
   - Register as student with matriculation number
   - Register as staff with staff ID
   - Verify email sending (check console logs)

2. **Test voting workflow**
   - Create test election (admin panel)
   - Request ballot token
   - Cast encrypted vote
   - Verify vote confirmation

3. **Test offline functionality**
   - Disconnect internet
   - Attempt to cast vote
   - Verify offline queue
   - Reconnect and sync

---

## Part 7: Troubleshooting

### Common Issues and Solutions

#### Python/Django Issues

**Issue**: `ModuleNotFoundError: No module named 'django'`
```cmd
# Solution: Ensure virtual environment is activated
venv\Scripts\activate.bat
pip install -r requirements.txt
```

**Issue**: `django.core.exceptions.ImproperlyConfigured: DATABASES setting is invalid`
```cmd
# Solution: Check PostgreSQL is running and DATABASE_URL is correct
net start postgresql-x64-15
# Verify connection
psql -U electra_user -d electra_db -h localhost
```

**Issue**: `Permission denied` errors with RSA keys
```cmd
# Solution: Check file permissions
icacls keys\private_key.pem /grant:r "%USERNAME%":F
```

#### PostgreSQL Issues

**Issue**: PostgreSQL service not starting
```cmd
# Solution: Start PostgreSQL service manually
net start postgresql-x64-15

# Or use PostgreSQL Service Manager
# Check Windows Services for PostgreSQL
```

**Issue**: Connection refused to PostgreSQL
```cmd
# Solution: Check PostgreSQL configuration
# Edit postgresql.conf and pg_hba.conf in PostgreSQL data directory
# Ensure listen_addresses = 'localhost' 
# Ensure host connection allowed for 127.0.0.1
```

#### Flutter Issues

**Issue**: `Flutter doctor` shows issues
```cmd
# Solution: Run flutter doctor and fix each issue individually
flutter doctor -v
# Install missing dependencies as indicated
```

**Issue**: Build runner fails
```cmd
# Solution: Clean and regenerate
flutter clean
flutter pub get
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

**Issue**: Web app doesn't connect to backend
```cmd
# Solution: Check CORS settings in Django
# Ensure CORS_ALLOWED_ORIGINS includes http://localhost:3000
# Check browser developer tools for CORS errors
```

#### Windows-Specific Issues

**Issue**: PowerShell execution policy prevents script execution
```powershell
# Solution: Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Issue**: Long path issues with Node modules
```cmd
# Solution: Enable long paths in Windows
# Run as Administrator:
# New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
```

#### Network/Connectivity Issues

**Issue**: Cannot connect to localhost services
```cmd
# Solution: Check Windows Firewall settings
# Allow Python and Flutter through firewall
# Check if antivirus is blocking connections
```

**Issue**: Redis connection errors
```cmd
# Solution: Start Redis service
redis-server
# Or install Redis as Windows service
```

---

---

## Part 9: Development Tools & IDE Setup

### Step 9.1: Visual Studio Code Setup (Recommended)

1. **Install Visual Studio Code**
   ```
   Visit: https://code.visualstudio.com/download
   ```

2. **Install Essential Extensions**
   ```
   # Python Development
   - Python
   - Python Docstring Generator
   - Python Indent
   - autoDocstring

   # Django Development
   - Django
   - Django Snippets

   # Flutter Development
   - Flutter
   - Dart
   - Flutter Widget Snippets

   # General Development
   - GitLens
   - Better Comments
   - Bracket Pair Colorizer
   - Error Lens
   - REST Client
   ```

3. **Configure VS Code Workspace**
   Create `.vscode/settings.json` in project root:
   ```json
   {
     "python.defaultInterpreterPath": "./venv/Scripts/python.exe",
     "python.terminal.activateEnvironment": true,
     "python.linting.enabled": true,
     "python.linting.flake8Enabled": true,
     "python.formatting.provider": "black",
     "python.linting.flake8Args": ["--max-line-length=100"],
     "dart.flutterSdkPath": "C:\\flutter",
     "dart.openDevTools": "flutter",
     "files.associations": {
       "*.env": "dotenv"
     },
     "terminal.integrated.profiles.windows": {
       "PowerShell": {
         "source": "PowerShell",
         "icon": "terminal-powershell"
       },
       "Command Prompt": {
         "path": "C:\\Windows\\System32\\cmd.exe",
         "args": [],
         "icon": "terminal-cmd"
       }
     },
     "terminal.integrated.defaultProfile.windows": "Command Prompt"
   }
   ```

4. **Create VS Code Tasks**
   Create `.vscode/tasks.json`:
   ```json
   {
     "version": "2.0.0",
     "tasks": [
       {
         "label": "Start Django Server",
         "type": "shell",
         "command": "${workspaceFolder}/venv/Scripts/python.exe",
         "args": ["manage.py", "runserver", "0.0.0.0:8000"],
         "group": "build",
         "presentation": {
           "reveal": "always",
           "panel": "new"
         }
       },
       {
         "label": "Start Flutter Web",
         "type": "shell",
         "command": "flutter",
         "args": ["run", "-d", "chrome", "--web-port", "3000"],
         "options": {
           "cwd": "${workspaceFolder}/electra_flutter"
         },
         "group": "build",
         "presentation": {
           "reveal": "always",
           "panel": "new"
         }
       },
       {
         "label": "Run Django Tests",
         "type": "shell",
         "command": "${workspaceFolder}/venv/Scripts/python.exe",
         "args": ["-m", "pytest", "--verbose"],
         "group": "test",
         "presentation": {
           "reveal": "always"
         }
       },
       {
         "label": "Run Flutter Tests",
         "type": "shell",
         "command": "flutter",
         "args": ["test"],
         "options": {
           "cwd": "${workspaceFolder}/electra_flutter"
         },
         "group": "test",
         "presentation": {
           "reveal": "always"
         }
       }
     ]
   }
   ```

### Step 9.2: Database Management Tools

1. **pgAdmin 4 (PostgreSQL Management)**
   ```
   Download: https://www.pgadmin.org/download/pgadmin-4-windows/
   Install and connect to: localhost:5432
   ```

2. **Redis Desktop Manager (Optional)**
   ```
   Download: https://github.com/uglide/RedisDesktopManager/releases
   Connect to: localhost:6379
   ```

### Step 9.3: API Testing Tools

1. **Postman (Recommended)**
   ```
   Visit: https://www.postman.com/downloads/
   Import API collection from docs/api/
   ```

2. **VS Code REST Client Extension**
   Create `api_tests.http`:
   ```http
   ### Health Check
   GET http://localhost:8000/api/health/

   ### User Registration
   POST http://localhost:8000/api/auth/register/
   Content-Type: application/json

   {
     "email": "test@example.com",
     "password": "testpass123",
     "password_confirm": "testpass123",
     "full_name": "Test User",
     "matric_number": "TEST001",
     "role": "student"
   }

   ### User Login
   POST http://localhost:8000/api/auth/login/
   Content-Type: application/json

   {
     "identifier": "test@example.com",
     "password": "testpass123"
   }
   ```

## Part 10: Windows-Specific Optimizations

### Step 10.1: Performance Optimization

1. **Windows Defender Exclusions**
   Add these directories to Windows Defender exclusions for better performance:
   ```
   Windows Security → Virus & threat protection → 
   Virus & threat protection settings → Add or remove exclusions
   
   Add these folders:
   - C:\Development\electra\
   - C:\flutter\
   - C:\Users\[username]\AppData\Local\Programs\Python\
   - C:\Program Files\PostgreSQL\
   ```

2. **System PATH Optimization**
   Ensure correct PATH order in System Environment Variables:
   ```
   C:\Program Files\PostgreSQL\15\bin
   C:\flutter\bin
   C:\Users\[username]\AppData\Local\Programs\Python\Python311\Scripts
   C:\Users\[username]\AppData\Local\Programs\Python\Python311
   ```

3. **Power Management Settings**
   - Set power plan to "High Performance" or "Balanced"
   - Disable USB selective suspend settings
   - Prevent system sleep during development sessions

### Step 10.2: Network Configuration

1. **Windows Firewall Rules**
   ```cmd
   # Run Command Prompt as Administrator and execute:
   netsh advfirewall firewall add rule name="Python Dev Server" dir=in action=allow protocol=TCP localport=8000
   netsh advfirewall firewall add rule name="Flutter Dev Server" dir=in action=allow protocol=TCP localport=3000
   netsh advfirewall firewall add rule name="PostgreSQL" dir=in action=allow protocol=TCP localport=5432
   netsh advfirewall firewall add rule name="Redis" dir=in action=allow protocol=TCP localport=6379
   ```

2. **Host File Configuration (Optional)**
   Edit `C:\Windows\System32\drivers\etc\hosts` (as Administrator):
   ```
   127.0.0.1    electra.local
   127.0.0.1    api.electra.local
   127.0.0.1    admin.electra.local
   ```

### Step 10.3: Automated Setup Script

Create `setup-electra.ps1` in your project root for one-click setup:

```powershell
# Electra Development Environment Setup Script for Windows
# Run with: PowerShell -ExecutionPolicy Bypass -File setup-electra.ps1

param(
    [switch]$SkipSoftware,
    [switch]$SkipDatabase,
    [switch]$SkipKeys
)

Write-Host "🚀 Electra Development Environment Setup" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# Check if running as Administrator for certain operations
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Warning "Some operations may require Administrator privileges."
    Write-Host "Consider running PowerShell as Administrator for full setup." -ForegroundColor Yellow
}

# Set execution policy for current user
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Host "✅ PowerShell execution policy set" -ForegroundColor Green
} catch {
    Write-Warning "Could not set execution policy: $($_.Exception.Message)"
}

# Create project directory
$projectPath = "C:\Development\electra"
if (!(Test-Path "C:\Development")) {
    New-Item -ItemType Directory -Path "C:\Development" -Force
    Write-Host "✅ Created C:\Development directory" -ForegroundColor Green
}

# Clone repository if not exists
if (!(Test-Path $projectPath)) {
    Write-Host "📥 Cloning Electra repository..." -ForegroundColor Yellow
    Set-Location "C:\Development"
    git clone https://github.com/RS12A/electra.git
    Write-Host "✅ Repository cloned successfully" -ForegroundColor Green
}

Set-Location $projectPath

# Setup Python virtual environment
Write-Host "🐍 Setting up Python virtual environment..." -ForegroundColor Yellow
if (!(Test-Path "venv")) {
    python -m venv venv
}

# Activate virtual environment and install dependencies
& .\venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install -r requirements.txt
Write-Host "✅ Python dependencies installed" -ForegroundColor Green

# Setup environment file
if (!(Test-Path ".env")) {
    Write-Host "⚙️  Creating environment file..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    
    # Update .env with Windows-appropriate settings
    $envContent = Get-Content ".env"
    $envContent = $envContent -replace "your_KEY_goes_here", "development_key_$(Get-Random)"
    $envContent = $envContent -replace "postgresql://.*", "postgresql://electra_user:electra_dev_password@localhost:5432/electra_db"
    $envContent = $envContent -replace "DJANGO_DEBUG=False", "DJANGO_DEBUG=True"
    $envContent = $envContent -replace "USE_MOCK_EMAIL=False", "USE_MOCK_EMAIL=True"
    $envContent | Set-Content ".env"
    Write-Host "✅ Environment file created and configured" -ForegroundColor Green
}

# Generate RSA keys
if (!(Test-Path "keys\private_key.pem") -and !$SkipKeys) {
    Write-Host "🔐 Generating RSA keys..." -ForegroundColor Yellow
    python scripts\generate_rsa_keys.py
    Write-Host "✅ RSA keys generated" -ForegroundColor Green
}

# Setup database (if PostgreSQL is available)
if (-not $SkipDatabase) {
    Write-Host "🗄️  Setting up database..." -ForegroundColor Yellow
    
    # Check if PostgreSQL is running
    $pgService = Get-Service -Name "*postgresql*" -ErrorAction SilentlyContinue
    if ($pgService -and $pgService.Status -eq "Running") {
        try {
            # Run migrations
            python manage.py migrate
            Write-Host "✅ Database migrations completed" -ForegroundColor Green
            
            # Create superuser (non-interactive)
            $env:DJANGO_SUPERUSER_USERNAME = "admin"
            $env:DJANGO_SUPERUSER_EMAIL = "admin@electra.local"
            $env:DJANGO_SUPERUSER_PASSWORD = "admin123"
            python manage.py createsuperuser --noinput 2>$null
            Write-Host "✅ Admin user created (admin/admin123)" -ForegroundColor Green
        }
        catch {
            Write-Warning "Database setup encountered issues. You may need to set up PostgreSQL manually."
        }
    }
    else {
        Write-Warning "PostgreSQL service not found or not running. Database setup skipped."
        Write-Host "Install PostgreSQL and run this script again with database setup." -ForegroundColor Yellow
    }
}

# Setup Flutter (if Flutter is available)
if (Test-Path "electra_flutter") {
    Write-Host "📱 Setting up Flutter frontend..." -ForegroundColor Yellow
    Set-Location "electra_flutter"
    
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        flutter pub get
        flutter packages pub run build_runner build --delete-conflicting-outputs
        Write-Host "✅ Flutter dependencies installed and code generated" -ForegroundColor Green
    }
    else {
        Write-Warning "Flutter not found in PATH. Flutter setup skipped."
        Write-Host "Install Flutter SDK and run this script again." -ForegroundColor Yellow
    }
    
    Set-Location ..
}

# Create batch scripts for easy development
Write-Host "📝 Creating development scripts..." -ForegroundColor Yellow

# Backend start script
@"
@echo off
echo Starting Electra Django Backend...
cd /d $projectPath
call venv\Scripts\activate.bat
echo Backend will be available at: http://localhost:8000
echo Admin panel at: http://localhost:8000/admin/
echo Health check at: http://localhost:8000/api/health/
python manage.py runserver 0.0.0.0:8000
pause
"@ | Out-File -FilePath "start_backend.bat" -Encoding ASCII

# Frontend start script
@"
@echo off
echo Starting Electra Flutter Frontend...
cd /d $projectPath\electra_flutter
echo Frontend will be available at: http://localhost:3000
flutter run -d chrome --web-port 3000
pause
"@ | Out-File -FilePath "start_frontend.bat" -Encoding ASCII

# Validation script
@"
@echo off
echo Validating Electra Environment...
cd /d $projectPath
call venv\Scripts\activate.bat
python scripts\validate_environment.py
echo:
echo Running deployment tests...
python scripts\test_deployment.py --skip-docker
pause
"@ | Out-File -FilePath "validate_setup.bat" -Encoding ASCII

Write-Host "✅ Development scripts created" -ForegroundColor Green

# Final validation
Write-Host "🔍 Running environment validation..." -ForegroundColor Yellow
python scripts\validate_environment.py --skip-docker

Write-Host "`n🎉 Electra development environment setup complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Quick Start:" -ForegroundColor Cyan
Write-Host "1. Double-click 'start_backend.bat' to start Django server" -ForegroundColor White
Write-Host "2. Double-click 'start_frontend.bat' to start Flutter app" -ForegroundColor White
Write-Host "3. Open http://localhost:8000/admin/ (admin/admin123)" -ForegroundColor White
Write-Host "4. Open http://localhost:3000 for Flutter web app" -ForegroundColor White
Write-Host "`nFor validation, run 'validate_setup.bat'" -ForegroundColor Yellow
```

## Part 11: Offline Development

### Step 11.1: Prepare for Offline Development

1. **Cache Python Dependencies**
   ```cmd
   # Create offline cache directory
   mkdir offline_cache\python
   
   # Download all dependencies to cache
   pip download -r requirements.txt -d offline_cache\python\
   
   # Future offline installs can use:
   pip install --no-index --find-links offline_cache\python\ -r requirements.txt
   ```

2. **Cache Flutter Dependencies**
   ```cmd
   cd electra_flutter
   
   # Get all dependencies (creates local cache)
   flutter pub get
   
   # Generate offline pub cache
   flutter pub deps
   
   # Cache will be stored in:
   # Windows: %APPDATA%\Pub\Cache
   ```

3. **Download Development Documentation**
   ```cmd
   mkdir docs\offline
   
   # Clone documentation repositories
   git clone https://github.com/django/django.git docs\offline\django
   git clone https://github.com/flutter/website.git docs\offline\flutter
   git clone https://github.com/postgres/postgres.git docs\offline\postgresql
   ```

### Step 11.2: Configure Offline Mode

1. **Enable Offline Voting in Flutter**
   Edit `electra_flutter\lib\main.dart`:
   ```dart
   // Initialize offline module for development
   await OfflineModuleInitializer.initialize(
     isDevelopment: kDebugMode,
     isBatteryOptimized: false,  // Better for development
     enableAutoSync: true,
   );
   ```

2. **Configure Django for Offline Development**
   Update `.env` file:
   ```env
   # Offline development settings
   ENABLE_OFFLINE_VOTING=true
   DEVELOPMENT_MODE=true
   USE_MOCK_EMAIL=true
   
   # Disable external services for offline work
   SENTRY_DSN=
   GOOGLE_ANALYTICS_ID=
   ```

3. **Set Up Local DNS Resolution**
   Edit `C:\Windows\System32\drivers\etc\hosts`:
   ```
   127.0.0.1    electra.local
   127.0.0.1    api.electra.local
   127.0.0.1    admin.electra.local
   127.0.0.1    db.electra.local
   ```

### Step 11.3: Test Offline Functionality

1. **Test Offline Vote Casting**
   ```cmd
   # Start both servers
   start_backend.bat
   start_frontend.bat
   
   # In Flutter app:
   # 1. Register a test user
   # 2. Create test election (admin panel)
   # 3. Disconnect internet (disable network adapter)
   # 4. Try to cast vote - should work offline
   # 5. Reconnect internet
   # 6. Verify vote synchronization
   ```

2. **Monitor Offline Queue**
   Check offline vote queue in Flutter DevTools:
   ```dart
   // Access offline state provider
   final offlineState = ref.watch(offlineStateProvider);
   print('Queued votes: ${offlineState.queuedVotes}');
   print('Network status: ${offlineState.networkStatus}');
   ```

3. **Validate Offline Encryption**
   ```cmd
   # Test encrypted storage
   cd electra_flutter
   flutter test test/offline/encryption_test.dart
   
   # Verify offline database
   flutter test test/offline/storage_test.dart
   ```

### Step 11.4: Offline Development Workflow

1. **Daily Development Routine**
   ```cmd
   # Morning startup (can be done offline)
   start_backend.bat
   start_frontend.bat
   
   # Verify offline capabilities
   validate_setup.bat
   ```

2. **Testing Offline Features**
   ```cmd
   # Test complete offline workflow
   cd electra_flutter
   flutter test test/integration/offline_voting_test.dart
   
   # Test offline sync
   flutter test test/integration/sync_test.dart
   ```

3. **Offline Code Generation**
   ```cmd
   # Flutter code generation works offline
   cd electra_flutter
   flutter packages pub run build_runner build --delete-conflicting-outputs
   
   # Django migrations work offline
   cd ..
   python manage.py makemigrations
   python manage.py migrate
   ```

---

## Quick Reference Commands

### Start Development Environment

**Option 1: Manual Commands**
```cmd
# Terminal 1 - Django Backend
cd C:\Development\electra
venv\Scripts\activate.bat
python manage.py runserver 0.0.0.0:8000

# Terminal 2 - Flutter Frontend
cd C:\Development\electra\electra_flutter
flutter run -d chrome --web-port 3000
```

**Option 2: Using Windows Batch Scripts (Recommended)**

Create these batch scripts in `C:\Development\electra\` for easier development:

1. **`start_backend.bat`**
   ```batch
   @echo off
   echo Starting Electra Django Backend...
   call venv\Scripts\activate.bat
   python manage.py runserver 0.0.0.0:8000
   pause
   ```

2. **`start_frontend.bat`**
   ```batch
   @echo off
   echo Starting Electra Flutter Frontend...
   cd electra_flutter
   flutter run -d chrome --web-port 3000
   pause
   ```

3. **`setup_environment.bat`**
   ```batch
   @echo off
   echo Setting up Electra Development Environment...
   
   echo Activating Python virtual environment...
   call venv\Scripts\activate.bat
   
   echo Running database migrations...
   python manage.py migrate
   
   echo Validating environment...
   python scripts\validate_environment.py
   
   echo Generating RSA keys (if not exists)...
   if not exist "keys\private_key.pem" (
       python scripts\generate_rsa_keys.py
   )
   
   echo Environment setup complete!
   pause
   ```

4. **`run_tests.bat`**
   ```batch
   @echo off
   echo Running Electra Tests...
   
   echo Activating Python environment...
   call venv\Scripts\activate.bat
   
   echo Running Django tests...
   python -m pytest --verbose
   
   echo Running Flutter tests...
   cd electra_flutter
   flutter test
   
   echo All tests completed!
   pause
   ```

### Common Development Tasks
```cmd
# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run tests
python -m pytest
flutter test

# Generate new RSA keys
python scripts/generate_rsa_keys.py --force

# Validate environment
python scripts/validate_environment.py

# Check system health
curl http://localhost:8000/api/health/
```

### Environment Management
```cmd
# Activate Python environment
venv\Scripts\activate.bat

# Deactivate Python environment
deactivate

# Update dependencies
pip install -r requirements.txt --upgrade
flutter pub upgrade
```

---

## Production Considerations

When moving from local development to production:

1. **Update environment variables**
   - Set `DJANGO_DEBUG=False`
   - Use secure database credentials
   - Configure real SMTP settings
   - Enable SSL/HTTPS settings

2. **Security hardening**
   - Generate new RSA keys with 4096-bit strength
   - Use environment-specific secret keys
   - Configure proper CORS origins
   - Enable security headers

3. **Performance optimization**
   - Use PostgreSQL with connection pooling
   - Configure Redis for production
   - Enable static file compression
   - Set up proper logging

---

## Support and Resources

### Documentation Links
- [Django Documentation](https://docs.djangoproject.com/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

### Useful Commands Reference
- [Makefile commands](./Makefile) - Available development commands
- [Environment validation](./scripts/validate_environment.py) - Environment checker
- [Deployment testing](./scripts/test_deployment.py) - Production readiness tests

### Getting Help
1. Check this troubleshooting section first
2. Verify all services are running (PostgreSQL, Redis)
3. Check application logs in the console
4. Review environment variable configuration
5. Test individual components separately

---

**Setup Complete!** 🎉

Your Electra development environment is now ready for local development on Windows. The system supports both online and offline voting capabilities, with comprehensive security features and audit logging.

For additional features and advanced configuration, refer to the main [README.md](./README.md) file.