@echo off
title Electra Setup Validation
echo ========================================
echo     Electra Setup Validation
echo ========================================
echo.

REM Activate virtual environment
if exist "venv\Scripts\activate.bat" (
    call venv\Scripts\activate.bat
) else (
    echo ERROR: Virtual environment not found!
    echo Please run setup_environment.bat first.
    echo.
    pause
    exit /b 1
)

echo Running comprehensive environment validation...
echo.

REM Validate environment configuration
echo [1/5] Validating environment configuration...
python scripts\validate_environment.py
echo.

REM Test deployment readiness
echo [2/5] Testing deployment readiness...
python scripts\test_deployment.py --skip-docker
echo.

REM Check database connectivity
echo [3/5] Testing database connectivity...
python -c "
import os
from dotenv import load_dotenv
load_dotenv()

try:
    import django
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'electra_server.settings.dev')
    django.setup()
    
    from django.db import connection
    cursor = connection.cursor()
    cursor.execute('SELECT 1')
    print('✓ Database connection: OK')
    
    from electra_server.apps.auth.models import User
    user_count = User.objects.count()
    print(f'✓ Users in database: {user_count}')
    
except Exception as e:
    print(f'✗ Database test failed: {e}')
"
echo.

REM Test API endpoints
echo [4/5] Testing API endpoints...
echo Starting temporary server for API tests...

REM Start Django server in background
start /b python manage.py runserver 127.0.0.1:8001 >nul 2>&1

REM Wait for server to start
timeout /t 3 /nobreak >nul

REM Test health endpoint
echo Testing health endpoint...
python -c "
import requests
import time

# Wait for server to be ready
for i in range(10):
    try:
        response = requests.get('http://localhost:8001/api/health/', timeout=5)
        if response.status_code == 200:
            print('✓ Health endpoint: OK')
            print(f'  Response: {response.json()}')
            break
    except:
        time.sleep(1)
        continue
else:
    print('✗ Health endpoint: Failed to respond')
"

REM Stop the temporary server
taskkill /f /im python.exe /fi "WINDOWTITLE eq *runserver*" >nul 2>&1

echo.

REM Test Flutter setup if available
echo [5/5] Testing Flutter setup...
if exist "electra_flutter" (
    cd electra_flutter
    
    flutter --version >nul 2>&1
    if errorlevel 1 (
        echo ⚠ Flutter not installed - skipping Flutter tests
    ) else (
        echo Running Flutter doctor...
        flutter doctor --android-licenses >nul 2>&1
        flutter doctor
        
        echo.
        echo Running Flutter analysis...
        flutter analyze --no-congratulate
        
        echo.
        echo Running Flutter tests...
        flutter test --reporter compact
    )
    
    cd ..
) else (
    echo ⚠ Flutter directory not found - skipping Flutter tests
)

echo.
echo ========================================
echo      Validation Complete!
echo ========================================
echo.

REM Generate validation report
python -c "
import json
import datetime
from pathlib import Path

# Basic validation report
report = {
    'validation_date': datetime.datetime.now().isoformat(),
    'python_version': None,
    'django_status': 'unknown',
    'flutter_status': 'unknown',
    'database_status': 'unknown',
    'environment_status': 'unknown'
}

try:
    import sys
    report['python_version'] = sys.version
    
    import django
    django.setup()
    report['django_status'] = 'ok'
    
    from django.db import connection
    cursor = connection.cursor()
    cursor.execute('SELECT 1')
    report['database_status'] = 'ok'
    
    if Path('.env').exists():
        report['environment_status'] = 'configured'
    
except Exception as e:
    print(f'Error generating validation report: {e}')

# Save report
with open('validation_report.json', 'w') as f:
    json.dump(report, f, indent=2)

print('Validation report saved to: validation_report.json')
"

echo.
echo Status Summary:
echo - Environment: Check validation_report.json for details
echo - Backend: Ready if no errors shown above
echo - Frontend: Ready if Flutter doctor shows no issues
echo - Database: Ready if connection test passed
echo.
echo To start development:
echo 1. Run start_backend.bat
echo 2. Run start_frontend.bat
echo.
pause