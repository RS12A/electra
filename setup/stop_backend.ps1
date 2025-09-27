# Electra Backend Stop Script - PowerShell
# Stops any running Django development servers

param(
    [Parameter(HelpMessage="Show help information")]
    [switch]$Help
)

function Show-Help {
    @"
Electra Backend Stop Script

DESCRIPTION:
    Stops any running Django development servers for the Electra backend.
    Finds and terminates Python processes running manage.py.

USAGE:
    PowerShell -ExecutionPolicy Bypass -File setup/stop_backend.ps1

PARAMETERS:
    -Help    Show this help information

"@
}

if ($Help) {
    Show-Help
    exit 0
}

Write-Host "🛑 Stopping Electra Django Backend Server" -ForegroundColor Red
Write-Host "===========================================" -ForegroundColor Red
Write-Host ""

try {
    # Find Django processes
    $djangoProcesses = Get-Process -Name "python" -ErrorAction SilentlyContinue | 
        Where-Object {$_.CommandLine -like "*manage.py*runserver*"}
    
    if ($djangoProcesses) {
        Write-Host "📍 Found $($djangoProcesses.Count) Django server process(es)" -ForegroundColor Yellow
        
        foreach ($process in $djangoProcesses) {
            Write-Host "🔪 Terminating process ID: $($process.Id)" -ForegroundColor Yellow
            Stop-Process -Id $process.Id -Force
        }
        
        # Wait a moment for processes to terminate
        Start-Sleep -Seconds 2
        
        # Verify processes are stopped
        $remainingProcesses = Get-Process -Name "python" -ErrorAction SilentlyContinue | 
            Where-Object {$_.CommandLine -like "*manage.py*runserver*"}
        
        if ($remainingProcesses) {
            Write-Host "⚠️  Some processes may still be running" -ForegroundColor Yellow
        } else {
            Write-Host "✅ All Django server processes stopped" -ForegroundColor Green
        }
    } else {
        Write-Host "ℹ️  No Django server processes found running" -ForegroundColor Blue
    }
    
    Write-Host ""
    Write-Host "✅ Backend stop operation completed" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error stopping backend servers: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}