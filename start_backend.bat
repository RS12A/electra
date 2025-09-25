@echo off
title Electra Django Backend
echo ========================================
echo    Electra Django Backend Server
echo ========================================
echo.

REM Check if virtual environment exists
if not exist "venv\Scripts\activate.bat" (
    echo ERROR: Virtual environment not found!
    echo Please run setup first:
    echo   python -m venv venv
    echo   venv\Scripts\activate.bat
    echo   pip install -r requirements.txt
    echo.
    pause
    exit /b 1
)

REM Activate virtual environment
echo Activating Python virtual environment...
call venv\Scripts\activate.bat

REM Check if .env file exists
if not exist ".env" (
    echo WARNING: .env file not found!
    echo Copying from .env.example...
    copy .env.example .env
    echo Please edit .env file with your configuration.
    echo.
)

REM Display startup information
echo.
echo Starting Django development server...
echo.
echo Backend will be available at:
echo   http://localhost:8000/
echo.
echo API Health Check:
echo   http://localhost:8000/api/health/
echo.
echo Django Admin Panel:
echo   http://localhost:8000/admin/
echo   Default login: admin / admin123
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

REM Start Django server
python manage.py runserver 0.0.0.0:8000

REM Keep window open if there's an error
if errorlevel 1 (
    echo.
    echo ========================================
    echo ERROR: Django server failed to start!
    echo ========================================
    echo.
    echo Common solutions:
    echo 1. Check if PostgreSQL is running
    echo 2. Verify .env configuration
    echo 3. Run: python manage.py migrate
    echo 4. Check if port 8000 is available
    echo.
    pause
)