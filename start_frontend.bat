@echo off
title Electra Flutter Frontend
echo ========================================
echo   Electra Flutter Frontend
echo ========================================
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Flutter is not installed or not in PATH!
    echo Please install Flutter first:
    echo   https://flutter.dev/docs/get-started/install/windows
    echo.
    pause
    exit /b 1
)

REM Check if we're in the right directory
if not exist "electra_flutter" (
    echo ERROR: electra_flutter directory not found!
    echo Make sure you're running this from the project root directory.
    echo.
    pause
    exit /b 1
)

REM Navigate to Flutter directory
cd electra_flutter

REM Check if dependencies are installed
if not exist "pubspec.lock" (
    echo Installing Flutter dependencies...
    flutter pub get
    echo.
)

REM Check if code generation is needed
if not exist "lib\**\*.g.dart" (
    echo Generating code...
    flutter packages pub run build_runner build --delete-conflicting-outputs
    echo.
)

REM Display startup information
echo.
echo Starting Flutter web development server...
echo.
echo Frontend will be available at:
echo   http://localhost:3000/
echo.
echo Flutter DevTools will be available at the URL shown below.
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

REM Start Flutter web server
flutter run -d chrome --web-port 3000

REM Keep window open if there's an error
if errorlevel 1 (
    echo.
    echo ========================================
    echo ERROR: Flutter server failed to start!
    echo ========================================
    echo.
    echo Common solutions:
    echo 1. Run: flutter doctor
    echo 2. Run: flutter clean && flutter pub get
    echo 3. Check if Chrome is installed
    echo 4. Check if port 3000 is available
    echo.
    echo For desktop app instead of web, run:
    echo   flutter run -d windows
    echo.
    pause
)

REM Return to project root
cd ..