# Electra Development Environment Setup Script for Windows
# Run with: PowerShell -ExecutionPolicy Bypass -File setup-electra.ps1

param(
    [switch]$SkipSoftware,
    [switch]$SkipDatabase,
    [switch]$SkipKeys,
    [switch]$InstallChocolatey
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

# Install Chocolatey if requested and not present
if ($InstallChocolatey -and -not $SkipSoftware) {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "📦 Installing Chocolatey package manager..." -ForegroundColor Yellow
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Host "✅ Chocolatey installed successfully" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to install Chocolatey: $($_.Exception.Message)"
        }
    }

    # Install software via Chocolatey
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "📦 Installing development tools via Chocolatey..." -ForegroundColor Yellow
        try {
            choco install python --version=3.11.0 -y
            choco install postgresql15 -y  
            choco install redis-64 -y
            choco install git -y
            choco install vscode -y
            choco install flutter -y
            Write-Host "✅ Development tools installed" -ForegroundColor Green
        } catch {
            Write-Warning "Some packages failed to install via Chocolatey"
        }
    }
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
    try {
        git clone https://github.com/RS12A/electra.git
        Write-Host "✅ Repository cloned successfully" -ForegroundColor Green
    } catch {
        Write-Error "Failed to clone repository. Please ensure Git is installed and you have internet access."
        exit 1
    }
}

Set-Location $projectPath

# Check Python installation
$pythonVersion = ""
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✅ Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Error "Python not found. Please install Python 3.11+ from https://www.python.org/downloads/windows/"
    exit 1
}

# Setup Python virtual environment
Write-Host "🐍 Setting up Python virtual environment..." -ForegroundColor Yellow
if (!(Test-Path "venv")) {
    python -m venv venv
    Write-Host "✅ Virtual environment created" -ForegroundColor Green
}

# Activate virtual environment and install dependencies
try {
    & .\venv\Scripts\Activate.ps1
    pip install --upgrade pip
    pip install -r requirements.txt
    Write-Host "✅ Python dependencies installed" -ForegroundColor Green
} catch {
    Write-Warning "Failed to install some Python dependencies: $($_.Exception.Message)"
}

# Setup environment file
if (!(Test-Path ".env")) {
    Write-Host "⚙️  Creating environment file..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    
    # Update .env with Windows-appropriate settings
    $envContent = Get-Content ".env"
    $envContent = $envContent -replace "your_KEY_goes_here", "development_key_$(Get-Random)"
    $envContent = $envContent -replace "postgresql://.*@localhost:5432/electra_db", "postgresql://electra_user:electra_dev_password@localhost:5432/electra_db"
    $envContent = $envContent -replace "DJANGO_DEBUG=False", "DJANGO_DEBUG=True"
    $envContent = $envContent -replace "USE_MOCK_EMAIL=False", "USE_MOCK_EMAIL=True"
    $envContent | Set-Content ".env"
    Write-Host "✅ Environment file created and configured" -ForegroundColor Green
} else {
    Write-Host "✅ Environment file already exists" -ForegroundColor Green
}

# Generate RSA keys
if (!(Test-Path "keys\private_key.pem") -and !$SkipKeys) {
    Write-Host "🔐 Generating RSA keys..." -ForegroundColor Yellow
    try {
        python scripts\generate_rsa_keys.py
        Write-Host "✅ RSA keys generated" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to generate RSA keys: $($_.Exception.Message)"
    }
} else {
    Write-Host "✅ RSA keys already exist or skipped" -ForegroundColor Green
}

# Setup database (if PostgreSQL is available)
if (-not $SkipDatabase) {
    Write-Host "🗄️  Setting up database..." -ForegroundColor Yellow
    
    # Check if PostgreSQL is running
    $pgService = Get-Service -Name "*postgresql*" -ErrorAction SilentlyContinue
    if ($pgService -and $pgService.Status -eq "Running") {
        try {
            # Create database and user (if not exists)
            $dbExists = psql -U postgres -lqt | Select-String -Pattern "electra_db"
            if (-not $dbExists) {
                Write-Host "Creating database and user..." -ForegroundColor Yellow
                psql -U postgres -c "CREATE DATABASE electra_db;"
                psql -U postgres -c "CREATE USER electra_user WITH PASSWORD 'electra_dev_password';"
                psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE electra_db TO electra_user;"
                Write-Host "✅ Database and user created" -ForegroundColor Green
            }
            
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
            Write-Warning "Database setup encountered issues: $($_.Exception.Message)"
            Write-Host "You may need to set up PostgreSQL manually." -ForegroundColor Yellow
        }
    }
    else {
        Write-Warning "PostgreSQL service not found or not running."
        Write-Host "Please install and start PostgreSQL, then run this script again." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Database setup skipped" -ForegroundColor Yellow
}

# Setup Flutter (if Flutter is available)
if (Test-Path "electra_flutter") {
    Write-Host "📱 Setting up Flutter frontend..." -ForegroundColor Yellow
    Set-Location "electra_flutter"
    
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        try {
            flutter pub get
            flutter packages pub run build_runner build --delete-conflicting-outputs
            Write-Host "✅ Flutter dependencies installed and code generated" -ForegroundColor Green
        } catch {
            Write-Warning "Flutter setup encountered issues: $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "Flutter not found in PATH."
        Write-Host "Install Flutter SDK from https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
    }
    
    Set-Location ..
} else {
    Write-Warning "Flutter directory not found"
}

# Create batch scripts for easy development
Write-Host "📝 Creating development scripts..." -ForegroundColor Yellow

# Backend start script
@"
@echo off
title Electra Django Backend
echo ========================================
echo    Electra Django Backend Server
echo ========================================
echo.
if not exist "venv\Scripts\activate.bat" (
    echo ERROR: Virtual environment not found!
    pause & exit /b 1
)
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
title Electra Flutter Frontend
echo ========================================
echo   Electra Flutter Frontend
echo ========================================
cd electra_flutter
echo Frontend will be available at: http://localhost:3000
flutter run -d chrome --web-port 3000
pause
"@ | Out-File -FilePath "start_frontend.bat" -Encoding ASCII

# Validation script
@"
@echo off
title Electra Environment Validation
call venv\Scripts\activate.bat
python scripts\validate_environment.py --skip-docker
echo.
python scripts\test_deployment.py --skip-docker
pause
"@ | Out-File -FilePath "validate_setup.bat" -Encoding ASCII

Write-Host "✅ Development scripts created" -ForegroundColor Green

# Configure Windows Firewall (if admin)
if ($isAdmin) {
    Write-Host "🔥 Configuring Windows Firewall..." -ForegroundColor Yellow
    try {
        netsh advfirewall firewall add rule name="Electra Django Server" dir=in action=allow protocol=TCP localport=8000 2>$null
        netsh advfirewall firewall add rule name="Electra Flutter Server" dir=in action=allow protocol=TCP localport=3000 2>$null
        Write-Host "✅ Firewall rules added" -ForegroundColor Green
    } catch {
        Write-Warning "Could not configure firewall rules"
    }
} else {
    Write-Host "⚠️  Firewall configuration skipped (requires admin)" -ForegroundColor Yellow
}

# Final validation
Write-Host "🔍 Running environment validation..." -ForegroundColor Yellow
try {
    python scripts\validate_environment.py --skip-docker
} catch {
    Write-Warning "Environment validation encountered issues"
}

Write-Host "`n🎉 Electra development environment setup complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Quick Start:" -ForegroundColor Cyan
Write-Host "1. Double-click 'start_backend.bat' to start Django server" -ForegroundColor White
Write-Host "2. Double-click 'start_frontend.bat' to start Flutter app" -ForegroundColor White
Write-Host "3. Open http://localhost:8000/admin/ (admin/admin123)" -ForegroundColor White
Write-Host "4. Open http://localhost:3000 for Flutter web app" -ForegroundColor White
Write-Host "`nFor validation, run 'validate_setup.bat'" -ForegroundColor Yellow

# Create desktop shortcuts (if admin)
if ($isAdmin) {
    Write-Host "`nCreating desktop shortcuts..." -ForegroundColor Yellow
    try {
        $WshShell = New-Object -comObject WScript.Shell
        
        # Backend shortcut
        $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Electra Backend.lnk")
        $Shortcut.TargetPath = "$projectPath\start_backend.bat"
        $Shortcut.WorkingDirectory = $projectPath
        $Shortcut.IconLocation = "shell32.dll,21"
        $Shortcut.Save()
        
        # Frontend shortcut
        $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Electra Frontend.lnk")
        $Shortcut.TargetPath = "$projectPath\start_frontend.bat"
        $Shortcut.WorkingDirectory = $projectPath
        $Shortcut.IconLocation = "shell32.dll,14"
        $Shortcut.Save()
        
        Write-Host "✅ Desktop shortcuts created" -ForegroundColor Green
    } catch {
        Write-Warning "Could not create desktop shortcuts"
    }
}

Write-Host "`nSetup completed! Check the output above for any issues." -ForegroundColor Green
Write-Host "Documentation: See ACTIVATE.md for detailed instructions" -ForegroundColor Cyan

Read-Host "`nPress Enter to exit"