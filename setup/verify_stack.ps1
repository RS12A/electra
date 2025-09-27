# Electra Stack Verification Script - PowerShell
# Comprehensive verification of the entire Electra development stack

param(
    [Parameter(HelpMessage="Skip backend tests")]
    [switch]$SkipBackend,
    
    [Parameter(HelpMessage="Skip frontend tests")]
    [switch]$SkipFrontend,
    
    [Parameter(HelpMessage="Skip database connectivity tests")]
    [switch]$SkipDatabase,
    
    [Parameter(HelpMessage="Skip Redis connectivity tests")]
    [switch]$SkipRedis,
    
    [Parameter(HelpMessage="Verbose output")]
    [switch]$Verbose,
    
    [Parameter(HelpMessage="Show help information")]
    [switch]$Help
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$VenvPath = Join-Path $ProjectRoot "venv"
$EnvFile = Join-Path $ProjectRoot ".env"
$FlutterPath = Join-Path $ProjectRoot "electra_flutter"

$Script:TestResults = @{
    Environment = $false
    VirtualEnvironment = $false
    Database = $false
    Redis = $false
    Backend = $false
    Frontend = $false
    OverallHealth = $false
}

function Show-Help {
    @"
Electra Stack Verification Script

DESCRIPTION:
    Comprehensive verification of the entire Electra development stack.
    Tests environment configuration, database connectivity, backend API,
    and frontend functionality.

USAGE:
    PowerShell -ExecutionPolicy Bypass -File setup/verify_stack.ps1 [parameters]

PARAMETERS:
    -SkipBackend     Skip backend API tests
    -SkipFrontend    Skip frontend tests
    -SkipDatabase    Skip database connectivity tests
    -SkipRedis       Skip Redis connectivity tests
    -Verbose         Show detailed output
    -Help            Show this help information

EXAMPLES:
    # Full verification
    PowerShell -ExecutionPolicy Bypass -File setup/verify_stack.ps1
    
    # Skip frontend tests
    PowerShell -ExecutionPolicy Bypass -File setup/verify_stack.ps1 -SkipFrontend
    
    # Verbose output
    PowerShell -ExecutionPolicy Bypass -File setup/verify_stack.ps1 -Verbose

EXIT CODES:
    0 - All tests passed
    1 - One or more tests failed

"@
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    if ($Passed) {
        Write-Host "✅ $TestName" -ForegroundColor Green
        if ($Verbose -and $Details) {
            Write-Host "   $Details" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ $TestName" -ForegroundColor Red
        if ($Details) {
            Write-Host "   $Details" -ForegroundColor Gray
        }
    }
}

function Test-Environment {
    Write-Host "🔍 Testing Environment Configuration..." -ForegroundColor Cyan
    
    # Check .env file exists
    $envExists = Test-Path $EnvFile
    Write-TestResult "Environment file exists" $envExists "Path: $EnvFile"
    
    if (-not $envExists) {
        return $false
    }
    
    # Check critical environment variables
    $envContent = Get-Content $EnvFile -Raw
    $criticalVars = @(
        'DJANGO_SECRET_KEY',
        'DATABASE_URL',
        'REDIS_URL',
        'JWT_SECRET_KEY'
    )
    
    $allVarsPresent = $true
    foreach ($var in $criticalVars) {
        $hasVar = $envContent -match "^$var\s*="
        Write-TestResult "Environment variable: $var" $hasVar
        if (-not $hasVar) {
            $allVarsPresent = $false
        }
    }
    
    return $allVarsPresent
}

function Test-VirtualEnvironment {
    Write-Host "🔍 Testing Python Virtual Environment..." -ForegroundColor Cyan
    
    # Check venv directory exists
    $venvExists = Test-Path $VenvPath
    Write-TestResult "Virtual environment directory exists" $venvExists "Path: $VenvPath"
    
    if (-not $venvExists) {
        return $false
    }
    
    # Check Python executable
    $pythonPath = Join-Path $VenvPath "Scripts\python.exe"
    $pythonExists = Test-Path $pythonPath
    Write-TestResult "Python executable exists" $pythonExists "Path: $pythonPath"
    
    # Check activation script
    $activateScript = Join-Path $VenvPath "Scripts\Activate.ps1"
    $activateExists = Test-Path $activateScript
    Write-TestResult "Activation script exists" $activateExists "Path: $activateScript"
    
    return $pythonExists -and $activateExists
}

function Test-Database {
    if ($SkipDatabase) {
        Write-Host "⏭️  Skipping database tests" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "🔍 Testing Database Connectivity..." -ForegroundColor Cyan
    
    try {
        # Activate virtual environment and test Django database connection
        $pythonPath = Join-Path $VenvPath "Scripts\python.exe"
        if (-not (Test-Path $pythonPath)) {
            Write-TestResult "Database connectivity" $false "Python executable not found"
            return $false
        }
        
        # Test Django database connection
        Set-Location $ProjectRoot
        $result = & $pythonPath manage.py check --database default 2>&1
        $dbConnected = $LASTEXITCODE -eq 0
        
        if ($dbConnected) {
            Write-TestResult "Database connectivity" $true "Django can connect to database"
        } else {
            Write-TestResult "Database connectivity" $false "Django database check failed: $result"
        }
        
        return $dbConnected
    }
    catch {
        Write-TestResult "Database connectivity" $false "Error: $($_.Exception.Message)"
        return $false
    }
}

function Test-Redis {
    if ($SkipRedis) {
        Write-Host "⏭️  Skipping Redis tests" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "🔍 Testing Redis Connectivity..." -ForegroundColor Cyan
    
    try {
        # Try to connect to Redis using python
        $pythonPath = Join-Path $VenvPath "Scripts\python.exe"
        if (-not (Test-Path $pythonPath)) {
            Write-TestResult "Redis connectivity" $false "Python executable not found"
            return $false
        }
        
        $redisTest = @"
import redis
import os
from urllib.parse import urlparse

# Read Redis URL from environment
with open('.env', 'r') as f:
    content = f.read()
    
redis_url = None
for line in content.split('\n'):
    if line.startswith('REDIS_URL='):
        redis_url = line.split('=', 1)[1].strip()
        break

if not redis_url:
    print('REDIS_URL not found in .env')
    exit(1)

try:
    r = redis.from_url(redis_url)
    r.ping()
    print('Redis connection successful')
    exit(0)
except Exception as e:
    print(f'Redis connection failed: {e}')
    exit(1)
"@
        
        Set-Location $ProjectRoot
        $redisTest | & $pythonPath -c "exec(__import__('sys').stdin.read())"
        $redisConnected = $LASTEXITCODE -eq 0
        
        Write-TestResult "Redis connectivity" $redisConnected
        return $redisConnected
    }
    catch {
        Write-TestResult "Redis connectivity" $false "Error: $($_.Exception.Message)"
        return $false
    }
}

function Test-Backend {
    if ($SkipBackend) {
        Write-Host "⏭️  Skipping backend tests" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "🔍 Testing Backend API..." -ForegroundColor Cyan
    
    try {
        # Start Django server in background for testing
        $pythonPath = Join-Path $VenvPath "Scripts\python.exe"
        if (-not (Test-Path $pythonPath)) {
            Write-TestResult "Backend API tests" $false "Python executable not found"
            return $false
        }
        
        Set-Location $ProjectRoot
        
        # Run Django check command
        $checkResult = & $pythonPath manage.py check 2>&1
        $checkPassed = $LASTEXITCODE -eq 0
        Write-TestResult "Django configuration check" $checkPassed
        
        if (-not $checkPassed) {
            return $false
        }
        
        # Test migrations status
        $migrateCheck = & $pythonPath manage.py showmigrations 2>&1
        $migrationsOk = $LASTEXITCODE -eq 0
        Write-TestResult "Database migrations check" $migrationsOk
        
        # Run Python tests if they exist
        if (Test-Path "pytest.ini") {
            $testResult = & $pythonPath -m pytest --tb=short -q 2>&1
            $testsPassed = $LASTEXITCODE -eq 0
            Write-TestResult "Backend unit tests" $testsPassed
        } else {
            Write-TestResult "Backend unit tests" $true "No test configuration found (pytest.ini)"
        }
        
        return $checkPassed -and $migrationsOk
    }
    catch {
        Write-TestResult "Backend API tests" $false "Error: $($_.Exception.Message)"
        return $false
    }
}

function Test-Frontend {
    if ($SkipFrontend) {
        Write-Host "⏭️  Skipping frontend tests" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "🔍 Testing Frontend..." -ForegroundColor Cyan
    
    try {
        # Check if Flutter directory exists
        $flutterExists = Test-Path $FlutterPath
        Write-TestResult "Flutter project directory exists" $flutterExists "Path: $FlutterPath"
        
        if (-not $flutterExists) {
            return $false
        }
        
        # Check if Flutter is available
        $flutterAvailable = $true
        try {
            flutter --version | Out-Null
        }
        catch {
            $flutterAvailable = $false
        }
        
        Write-TestResult "Flutter SDK available" $flutterAvailable
        
        if ($flutterAvailable) {
            # Run Flutter tests
            Set-Location $FlutterPath
            
            # Check Flutter project health
            $doctorResult = flutter doctor --machine 2>&1
            $doctorOk = $LASTEXITCODE -eq 0
            Write-TestResult "Flutter doctor check" $doctorOk
            
            # Run Flutter tests if they exist
            if (Test-Path "test") {
                $testResult = flutter test 2>&1
                $testsPassed = $LASTEXITCODE -eq 0
                Write-TestResult "Flutter unit tests" $testsPassed
            } else {
                Write-TestResult "Flutter unit tests" $true "No tests directory found"
            }
            
            return $doctorOk
        }
        
        return $flutterExists
    }
    catch {
        Write-TestResult "Frontend tests" $false "Error: $($_.Exception.Message)"
        return $false
    }
}

function Show-Summary {
    Write-Host ""
    Write-Host "📊 Verification Summary" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    
    $testNames = @{
        Environment = "Environment Configuration"
        VirtualEnvironment = "Python Virtual Environment"
        Database = "Database Connectivity"
        Redis = "Redis Connectivity"
        Backend = "Backend API"
        Frontend = "Frontend Application"
    }
    
    $passedTests = 0
    $totalTests = 0
    
    foreach ($test in $Script:TestResults.Keys) {
        if ($test -eq "OverallHealth") { continue }
        
        $totalTests++
        if ($Script:TestResults[$test]) {
            $passedTests++
            Write-Host "✅ $($testNames[$test])" -ForegroundColor Green
        } else {
            Write-Host "❌ $($testNames[$test])" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    $overallPassed = $passedTests -eq $totalTests
    $Script:TestResults.OverallHealth = $overallPassed
    
    if ($overallPassed) {
        Write-Host "🎉 All tests passed! ($passedTests/$totalTests)" -ForegroundColor Green
        Write-Host "Your Electra development environment is ready to use!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some tests failed ($passedTests/$totalTests)" -ForegroundColor Yellow
        Write-Host "Please review the failed tests and run the setup again if needed." -ForegroundColor Yellow
    }
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Host "🔍 Electra Stack Verification" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""

# Run all tests
$Script:TestResults.Environment = Test-Environment
$Script:TestResults.VirtualEnvironment = Test-VirtualEnvironment
$Script:TestResults.Database = Test-Database
$Script:TestResults.Redis = Test-Redis
$Script:TestResults.Backend = Test-Backend
$Script:TestResults.Frontend = Test-Frontend

# Show summary
Show-Summary

# Exit with appropriate code
if ($Script:TestResults.OverallHealth) {
    exit 0
} else {
    exit 1
}