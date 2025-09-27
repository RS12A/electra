# Windows PowerShell script to verify Electra backend
# This script runs the migration fixer, schema verification, and test suite

param(
    [switch]$Verbose,
    [switch]$SkipTests,
    [switch]$DryRun,
    [switch]$Help
)

# Color functions
function Write-Info($Message) {
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

function Write-Success($Message) {
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning($Message) {
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error($Message) {
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Header($Message) {
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan -NoNewline
    Write-Host "  " -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Help {
    Write-Host "Electra Backend Verification Script"
    Write-Host ""
    Write-Host "USAGE:"
    Write-Host "  .\scripts\verify_backend.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "OPTIONS:"
    Write-Host "  -Verbose      Enable verbose output"
    Write-Host "  -SkipTests    Skip running the test suite"
    Write-Host "  -DryRun       Show what would be done without making changes"
    Write-Host "  -Help         Show this help message"
    Write-Host ""
    Write-Host "EXAMPLES:"
    Write-Host "  .\scripts\verify_backend.ps1"
    Write-Host "  .\scripts\verify_backend.ps1 -Verbose"
    Write-Host "  .\scripts\verify_backend.ps1 -SkipTests -Verbose"
    Write-Host "  .\scripts\verify_backend.ps1 -DryRun"
    Write-Host ""
    Write-Host "This script will:"
    Write-Host "  1. Check that Python virtual environment is activated"
    Write-Host "  2. Run the migration fix script"
    Write-Host "  3. Run schema verification"
    Write-Host "  4. Run the test suite (unless -SkipTests is specified)"
    Write-Host "  5. Provide a clear success/failure status"
    Write-Host ""
}

function Test-VirtualEnvironment {
    Write-Info "Checking Python virtual environment..."
    
    # Check if we're in a virtual environment
    if (-not $env:VIRTUAL_ENV) {
        Write-Warning "No virtual environment detected"
        Write-Info "Looking for venv directory..."
        
        if (Test-Path "venv\Scripts\activate.ps1") {
            Write-Info "Found venv, activating..."
            & "venv\Scripts\activate.ps1"
            return $true
        }
        elseif (Test-Path "venv\Scripts\Activate.ps1") {
            Write-Info "Found venv, activating..."
            & "venv\Scripts\Activate.ps1"
            return $true
        }
        else {
            Write-Error "Virtual environment not found. Please create one:"
            Write-Host "  python -m venv venv"
            Write-Host "  venv\Scripts\activate"
            Write-Host "  pip install -r requirements.txt"
            return $false
        }
    }
    else {
        Write-Success "Virtual environment is active: $env:VIRTUAL_ENV"
        return $true
    }
}

function Test-Dependencies {
    Write-Info "Checking Python dependencies..."
    
    try {
        $result = python -c "import django; print('Django', django.get_version())" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Dependencies check passed: $result"
            return $true
        }
        else {
            Write-Error "Dependencies check failed: $result"
            Write-Info "Please install dependencies:"
            Write-Host "  pip install -r requirements.txt"
            return $false
        }
    }
    catch {
        Write-Error "Failed to check dependencies: $_"
        return $false
    }
}

function Test-DatabaseConnection {
    Write-Info "Testing database connection..."
    
    try {
        $verboseFlag = if ($Verbose) { "--verbose" } else { "" }
        $result = python -c "
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'electra_server.settings.dev')
django.setup()
from django.db import connection
try:
    with connection.cursor() as cursor:
        cursor.execute('SELECT 1')
        result = cursor.fetchone()
        if result and result[0] == 1:
            print('Database connection successful')
        else:
            print('Database connection failed')
            exit(1)
except Exception as e:
    print(f'Database connection error: {e}')
    exit(1)
" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Database connection test passed"
            return $true
        }
        else {
            Write-Error "Database connection failed: $result"
            Write-Info "Please check your database configuration and ensure PostgreSQL is running"
            return $false
        }
    }
    catch {
        Write-Error "Failed to test database connection: $_"
        return $false
    }
}

function Invoke-MigrationFixer {
    Write-Info "Running migration fixer..."
    
    $args = @()
    if ($Verbose) { $args += "--verbose" }
    if ($DryRun) { $args += "--dry-run" }
    
    try {
        $result = python "scripts\fix_migrations_windows.py" @args
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Migration fixer completed successfully"
            return $true
        }
        else {
            Write-Error "Migration fixer failed with exit code $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Write-Error "Failed to run migration fixer: $_"
        return $false
    }
}

function Invoke-SchemaVerification {
    Write-Info "Running schema verification..."
    
    try {
        if ($DryRun) {
            Write-Info "DRY RUN: Would run schema verification"
            return $true
        }
        
        $verboseFlag = if ($Verbose) { "--verbose" } else { "" }
        $result = python "manage.py" "verify_schema" $verboseFlag
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Schema verification passed"
            return $true
        }
        else {
            Write-Error "Schema verification failed with exit code $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Write-Error "Failed to run schema verification: $_"
        return $false
    }
}

function Invoke-TestSuite {
    if ($SkipTests) {
        Write-Info "Skipping test suite (--SkipTests specified)"
        return $true
    }
    
    Write-Info "Running test suite..."
    
    try {
        if ($DryRun) {
            Write-Info "DRY RUN: Would run test suite"
            return $true
        }
        
        # Run pytest with coverage if available
        $testCommand = if (Get-Command pytest -ErrorAction SilentlyContinue) {
            "pytest", "--tb=short"
        } else {
            "python", "-m", "pytest", "--tb=short"
        }
        
        if ($Verbose) {
            $testCommand += "-v"
        }
        
        Write-Info "Running: $($testCommand -join ' ')"
        & $testCommand[0] $testCommand[1..$testCommand.Length]
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "All tests passed"
            return $true
        }
        else {
            Write-Error "Some tests failed (exit code $LASTEXITCODE)"
            return $false
        }
    }
    catch {
        Write-Error "Failed to run test suite: $_"
        return $false
    }
}

function Main {
    # Show help if requested
    if ($Help) {
        Show-Help
        return
    }
    
    # Print header
    Write-Header "Electra Backend Verification"
    
    if ($DryRun) {
        Write-Warning "DRY RUN MODE - No changes will be made"
        Write-Host ""
    }
    
    # Track results
    $results = @{
        "VirtualEnvironment" = $false
        "Dependencies" = $false
        "DatabaseConnection" = $false
        "MigrationFixer" = $false
        "SchemaVerification" = $false
        "TestSuite" = $false
    }
    
    # Step 1: Check virtual environment
    Write-Header "Step 1: Virtual Environment Check"
    $results.VirtualEnvironment = Test-VirtualEnvironment
    
    if (-not $results.VirtualEnvironment) {
        Write-Error "Cannot proceed without virtual environment"
        exit 1
    }
    
    # Step 2: Check dependencies
    Write-Header "Step 2: Dependencies Check"
    $results.Dependencies = Test-Dependencies
    
    if (-not $results.Dependencies) {
        Write-Error "Cannot proceed without required dependencies"
        exit 1
    }
    
    # Step 3: Test database connection
    Write-Header "Step 3: Database Connection Test"
    $results.DatabaseConnection = Test-DatabaseConnection
    
    if (-not $results.DatabaseConnection) {
        Write-Error "Cannot proceed without database connection"
        exit 1
    }
    
    # Step 4: Run migration fixer
    Write-Header "Step 4: Migration Fixer"
    $results.MigrationFixer = Invoke-MigrationFixer
    
    # Step 5: Run schema verification
    Write-Header "Step 5: Schema Verification"
    $results.SchemaVerification = Invoke-SchemaVerification
    
    # Step 6: Run test suite
    Write-Header "Step 6: Test Suite"
    $results.TestSuite = Invoke-TestSuite
    
    # Print final results
    Write-Header "VERIFICATION RESULTS"
    
    $allPassed = $true
    foreach ($key in $results.Keys) {
        if ($results[$key]) {
            Write-Success "$key : PASSED"
        }
        else {
            Write-Error "$key : FAILED"
            $allPassed = $false
        }
    }
    
    Write-Host ""
    if ($allPassed) {
        Write-Success "🎉 ALL VERIFICATION CHECKS PASSED!"
        Write-Success "✅ Electra backend is ready for use"
        exit 0
    }
    else {
        Write-Error "💥 SOME VERIFICATION CHECKS FAILED!"
        Write-Error "❌ Please fix the issues above before proceeding"
        exit 1
    }
}

# Run main function
Main