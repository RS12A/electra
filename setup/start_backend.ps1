# Electra Backend Start Script - PowerShell
# Starts the Django development server with proper environment activation

param(
    [Parameter(HelpMessage="Port to run the server on")]
    [int]$Port = 8000,
    
    [Parameter(HelpMessage="Host to bind to")]
    [string]$Host = "0.0.0.0",
    
    [Parameter(HelpMessage="Show help information")]
    [switch]$Help
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$VenvPath = Join-Path $ProjectRoot "venv"
$ActivateScript = Join-Path $VenvPath "Scripts" "Activate.ps1"

function Show-Help {
    @"
Electra Backend Start Script

DESCRIPTION:
    Starts the Django development server for the Electra backend.
    Automatically activates the Python virtual environment and runs the server.

USAGE:
    PowerShell -ExecutionPolicy Bypass -File setup/start_backend.ps1 [parameters]

PARAMETERS:
    -Port <int>     Port to run the server on (default: 8000)
    -Host <string>  Host to bind to (default: 0.0.0.0)
    -Help           Show this help information

EXAMPLES:
    # Start on default port 8000
    PowerShell -ExecutionPolicy Bypass -File setup/start_backend.ps1
    
    # Start on custom port
    PowerShell -ExecutionPolicy Bypass -File setup/start_backend.ps1 -Port 9000
    
    # Start on localhost only
    PowerShell -ExecutionPolicy Bypass -File setup/start_backend.ps1 -Host localhost

URLS:
    Backend API: http://localhost:$Port/
    Admin Panel: http://localhost:$Port/admin/
    Health Check: http://localhost:$Port/api/health/

"@
}

if ($Help) {
    Show-Help
    exit 0
}

Write-Host "🚀 Starting Electra Django Backend Server" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Check if virtual environment exists
if (-not (Test-Path $VenvPath)) {
    Write-Host "❌ Virtual environment not found at: $VenvPath" -ForegroundColor Red
    Write-Host "Please run the setup script first:" -ForegroundColor Yellow
    Write-Host "  python setup/windows_setup.py" -ForegroundColor Yellow
    exit 1
}

# Check if activation script exists
if (-not (Test-Path $ActivateScript)) {
    Write-Host "❌ Virtual environment activation script not found" -ForegroundColor Red
    Write-Host "Virtual environment may be incomplete. Please re-run setup." -ForegroundColor Yellow
    exit 1
}

# Check if .env file exists
$EnvFile = Join-Path $ProjectRoot ".env"
if (-not (Test-Path $EnvFile)) {
    Write-Host "❌ Environment file not found: $EnvFile" -ForegroundColor Red
    Write-Host "Please run the setup script first to generate .env file:" -ForegroundColor Yellow
    Write-Host "  python setup/windows_setup.py" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Virtual environment found" -ForegroundColor Green
Write-Host "✅ Environment file found" -ForegroundColor Green
Write-Host ""

Write-Host "📍 Server Configuration:" -ForegroundColor Cyan
Write-Host "  Host: $Host"
Write-Host "  Port: $Port"
Write-Host "  Project: $ProjectRoot"
Write-Host ""

Write-Host "🌐 Access URLs:" -ForegroundColor Cyan
Write-Host "  Backend API: http://localhost:$Port/"
Write-Host "  Admin Panel: http://localhost:$Port/admin/"
Write-Host "  Health Check: http://localhost:$Port/api/health/"
Write-Host ""

Write-Host "⏳ Activating virtual environment..." -ForegroundColor Yellow

try {
    # Activate virtual environment
    & $ActivateScript
    
    # Change to project directory
    Set-Location $ProjectRoot
    
    Write-Host "✅ Virtual environment activated" -ForegroundColor Green
    Write-Host "🚀 Starting Django development server..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
    Write-Host ""
    
    # Start Django server
    python manage.py runserver "${Host}:$Port"
}
catch {
    Write-Host "❌ Failed to start backend server: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "👋 Backend server stopped" -ForegroundColor Yellow