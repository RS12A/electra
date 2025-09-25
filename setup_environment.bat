@echo off
title Electra Environment Setup
echo ========================================
echo     Electra Environment Setup
echo ========================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH!
    echo Please install Python 3.11+ first:
    echo   https://www.python.org/downloads/windows/
    echo.
    pause
    exit /b 1
)

echo Python version:
python --version
echo.

REM Create virtual environment if it doesn't exist
if not exist "venv" (
    echo Creating Python virtual environment...
    python -m venv venv
    echo ✓ Virtual environment created
    echo.
) else (
    echo ✓ Virtual environment already exists
    echo.
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Upgrade pip
echo Upgrading pip...
python -m pip install --upgrade pip

REM Install Python dependencies
echo Installing Python dependencies...
pip install -r requirements.txt

REM Create .env file if it doesn't exist
if not exist ".env" (
    echo Creating environment file...
    copy .env.example .env
    echo ✓ .env file created from template
    echo.
    echo IMPORTANT: Please edit .env file with your configuration:
    echo - Set secure passwords
    echo - Configure database connection
    echo - Update email settings
    echo.
) else (
    echo ✓ .env file already exists
    echo.
)

REM Validate environment
echo Validating environment configuration...
python scripts\validate_environment.py --skip-docker
echo.

REM Generate RSA keys if they don't exist
if not exist "keys\private_key.pem" (
    echo Generating RSA keys for JWT signing...
    python scripts\generate_rsa_keys.py
    echo ✓ RSA keys generated
    echo.
) else (
    echo ✓ RSA keys already exist
    echo.
)

REM Check if PostgreSQL is accessible
echo Checking database connection...
python -c "
import os
from dotenv import load_dotenv
import psycopg2
from urllib.parse import urlparse

load_dotenv()
db_url = os.getenv('DATABASE_URL', '')

if db_url:
    try:
        parsed = urlparse(db_url)
        conn = psycopg2.connect(
            host=parsed.hostname,
            database=parsed.path[1:],
            user=parsed.username,
            password=parsed.password,
            port=parsed.port
        )
        conn.close()
        print('✓ Database connection successful')
    except Exception as e:
        print(f'⚠ Database connection failed: {e}')
        print('Please ensure PostgreSQL is running and configured correctly.')
else:
    print('⚠ DATABASE_URL not configured in .env file')
"
echo.

REM Run database migrations
echo Running database migrations...
python manage.py migrate
echo ✓ Database migrations completed
echo.

REM Create superuser if it doesn't exist
echo Checking for admin user...
python -c "
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'electra_server.settings.dev')
django.setup()

from electra_server.apps.auth.models import User

if not User.objects.filter(is_superuser=True).exists():
    print('Creating admin user...')
    admin = User.objects.create_superuser(
        email='admin@electra.local',
        password='admin123',
        full_name='System Administrator'
    )
    print('✓ Admin user created: admin@electra.local / admin123')
else:
    print('✓ Admin user already exists')
"
echo.

REM Setup Flutter if directory exists
if exist "electra_flutter" (
    echo Setting up Flutter frontend...
    cd electra_flutter
    
    REM Check if Flutter is installed
    flutter --version >nul 2>&1
    if errorlevel 1 (
        echo ⚠ Flutter is not installed. Skipping Flutter setup.
        echo Install Flutter from: https://flutter.dev/docs/get-started/install/windows
        cd ..
    ) else (
        echo Installing Flutter dependencies...
        flutter pub get
        
        echo Generating Flutter code...
        flutter packages pub run build_runner build --delete-conflicting-outputs
        
        echo ✓ Flutter setup completed
        cd ..
    )
    echo.
)

REM Final validation
echo Running final deployment tests...
python scripts\test_deployment.py --skip-docker
echo.

echo ========================================
echo      Setup Complete! 🎉
echo ========================================
echo.
echo Next steps:
echo 1. Review and update .env file if needed
echo 2. Double-click start_backend.bat to start Django server
echo 3. Double-click start_frontend.bat to start Flutter app
echo 4. Open http://localhost:8000/admin/ (admin@electra.local / admin123)
echo 5. Open http://localhost:3000 for the Flutter web app
echo.
echo For validation, run: validate_setup.bat
echo.
pause