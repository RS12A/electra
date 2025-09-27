# Electra Frontend Start Script - PowerShell
# Starts the Flutter web development server

param(
    [Parameter(HelpMessage="Port to run the frontend on")]
    [int]$Port = 3000,
    
    [Parameter(HelpMessage="Target device (chrome, windows, etc.)")]
    [string]$Device = "chrome",
    
    [Parameter(HelpMessage="Show help information")]
    [switch]$Help
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$FlutterPath = Join-Path $ProjectRoot "electra_flutter"

function Show-Help {
    @"
Electra Frontend Start Script

DESCRIPTION:
    Starts the Flutter development server for the Electra frontend.
    Automatically navigates to the Flutter project directory and starts the app.

USAGE:
    PowerShell -ExecutionPolicy Bypass -File setup/start_frontend.ps1 [parameters]

PARAMETERS:
    -Port <int>      Port to run the frontend on (default: 3000)
    -Device <string> Target device: chrome, windows, emulator (default: chrome)
    -Help            Show this help information

EXAMPLES:
    # Start web version on default port 3000
    PowerShell -ExecutionPolicy Bypass -File setup/start_frontend.ps1
    
    # Start on custom port
    PowerShell -ExecutionPolicy Bypass -File setup/start_frontend.ps1 -Port 4000
    
    # Start Windows desktop version
    PowerShell -ExecutionPolicy Bypass -File setup/start_frontend.ps1 -Device windows

URLS:
    Frontend Web App: http://localhost:$Port/

"@
}

if ($Help) {
    Show-Help
    exit 0
}

Write-Host "🎨 Starting Electra Flutter Frontend" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Check if Flutter directory exists
if (-not (Test-Path $FlutterPath)) {
    Write-Host "❌ Flutter project directory not found: $FlutterPath" -ForegroundColor Red
    Write-Host "Please ensure the Flutter project exists in the correct location." -ForegroundColor Yellow
    exit 1
}

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter not found"
    }
    Write-Host "✅ Flutter is available" -ForegroundColor Green
}
catch {
    Write-Host "❌ Flutter SDK not found in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter SDK from: https://flutter.dev/docs/get-started/install/windows" -ForegroundColor Yellow
    exit 1
}

Write-Host "📍 Frontend Configuration:" -ForegroundColor Cyan
Write-Host "  Device: $Device"
Write-Host "  Port: $Port"
Write-Host "  Project: $FlutterPath"
Write-Host ""

Write-Host "🌐 Access URL:" -ForegroundColor Cyan
Write-Host "  Frontend Web App: http://localhost:$Port/"
Write-Host ""

# Change to Flutter directory
Set-Location $FlutterPath

Write-Host "📦 Checking Flutter dependencies..." -ForegroundColor Yellow

# Check if dependencies are installed
$pubspecExists = Test-Path "pubspec.yaml"
if (-not $pubspecExists) {
    Write-Host "❌ pubspec.yaml not found in Flutter directory" -ForegroundColor Red
    exit 1
}

# Get dependencies if needed
try {
    Write-Host "📥 Getting Flutter dependencies..." -ForegroundColor Yellow
    flutter pub get
    Write-Host "✅ Dependencies updated" -ForegroundColor Green
}
catch {
    Write-Host "⚠️  Failed to get dependencies, but continuing..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🚀 Starting Flutter development server..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

try {
    # Start Flutter based on device type
    switch ($Device.ToLower()) {
        "chrome" {
            flutter run -d chrome --web-port $Port
        }
        "windows" {
            flutter run -d windows
        }
        "web" {
            flutter run -d chrome --web-port $Port
        }
        default {
            # Try to run on specified device
            flutter run -d $Device --web-port $Port
        }
    }
}
catch {
    Write-Host "❌ Failed to start frontend server: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "👋 Frontend server stopped" -ForegroundColor Yellow