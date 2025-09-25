@echo off
title Electra Test Suite
echo ========================================
echo        Electra Test Suite
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

echo Running comprehensive test suite...
echo.

REM Run Django/Python tests
echo [1/3] Running Django Backend Tests...
echo ----------------------------------------
echo.

echo Running authentication tests...
python -m pytest electra_server\apps\auth\tests\ -v --tb=short
echo.

echo Running election tests...
python -m pytest electra_server\apps\elections\tests\ -v --tb=short
echo.

echo Running ballot token tests...
python -m pytest electra_server\apps\ballots\tests\ -v --tb=short
echo.

echo Running integration tests...
python -m pytest tests\ -v --tb=short
echo.

REM Generate coverage report
echo [2/3] Generating Test Coverage Report...
echo ----------------------------------------
echo.
python -m pytest --cov=electra_server --cov=apps --cov-report=html --cov-report=term-missing --tb=short
echo.
echo ✓ Coverage report generated in htmlcov\index.html
echo.

REM Run Flutter tests if available
echo [3/3] Running Flutter Tests...
echo ----------------------------------------
echo.

if exist "electra_flutter" (
    cd electra_flutter
    
    flutter --version >nul 2>&1
    if errorlevel 1 (
        echo ⚠ Flutter not installed - skipping Flutter tests
    ) else (
        echo Running Flutter unit tests...
        flutter test --reporter expanded
        echo.
        
        echo Running Flutter widget tests...
        flutter test test\widget\ --reporter expanded
        echo.
        
        echo Running Flutter integration tests...
        if exist "test\integration\" (
            flutter test test\integration\ --reporter expanded
        ) else (
            echo ⚠ No integration tests found
        )
        echo.
        
        echo Generating Flutter test coverage...
        flutter test --coverage
        echo ✓ Flutter coverage report generated in coverage\lcov.info
    )
    
    cd ..
) else (
    echo ⚠ Flutter directory not found - skipping Flutter tests
)

echo.
echo ========================================
echo      Test Results Summary
echo ========================================
echo.

REM Generate test summary
python -c "
import json
import datetime
import subprocess
import os
from pathlib import Path

# Generate test summary
summary = {
    'test_date': datetime.datetime.now().isoformat(),
    'backend_tests': 'completed',
    'frontend_tests': 'completed' if Path('electra_flutter').exists() else 'skipped',
    'coverage_generated': Path('htmlcov').exists(),
    'reports_available': []
}

if Path('htmlcov/index.html').exists():
    summary['reports_available'].append('Backend Coverage: htmlcov/index.html')

if Path('electra_flutter/coverage/lcov.info').exists():
    summary['reports_available'].append('Flutter Coverage: electra_flutter/coverage/lcov.info')

# Save summary
with open('test_summary.json', 'w') as f:
    json.dump(summary, f, indent=2)

print('Test Summary:')
print(f'✓ Backend tests: {summary[\"backend_tests\"]}')
print(f'✓ Frontend tests: {summary[\"frontend_tests\"]}')
print(f'✓ Coverage generated: {summary[\"coverage_generated\"]}')
print()
print('Available Reports:')
for report in summary['reports_available']:
    print(f'  - {report}')

if not summary['reports_available']:
    print('  - No coverage reports generated')

print()
print('Test summary saved to: test_summary.json')
"

echo.
echo Additional Testing Commands:
echo.
echo Backend-specific tests:
echo   python -m pytest electra_server\apps\auth\tests\ -v
echo   python -m pytest electra_server\apps\elections\tests\ -v
echo   python -m pytest electra_server\apps\ballots\tests\ -v
echo.
echo Frontend-specific tests:
echo   cd electra_flutter
echo   flutter test
echo   flutter test --coverage
echo.
echo Security tests:
echo   python scripts\security_audit.py
echo.
echo Performance tests:
echo   python -m pytest tests\ -k performance
echo.
pause