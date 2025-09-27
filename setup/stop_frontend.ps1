# Electra Frontend Stop Script - PowerShell
# Stops any running Flutter development servers

param(
    [Parameter(HelpMessage="Show help information")]
    [switch]$Help
)

function Show-Help {
    @"
Electra Frontend Stop Script

DESCRIPTION:
    Stops any running Flutter development servers for the Electra frontend.
    Finds and terminates Flutter processes.

USAGE:
    PowerShell -ExecutionPolicy Bypass -File setup/stop_frontend.ps1

PARAMETERS:
    -Help    Show this help information

"@
}

if ($Help) {
    Show-Help
    exit 0
}

Write-Host "🛑 Stopping Electra Flutter Frontend" -ForegroundColor Red
Write-Host "=====================================" -ForegroundColor Red
Write-Host ""

try {
    # Find Flutter processes
    $flutterProcesses = Get-Process -Name "flutter*" -ErrorAction SilentlyContinue
    $dartProcesses = Get-Process -Name "dart*" -ErrorAction SilentlyContinue
    
    $allProcesses = @()
    if ($flutterProcesses) { $allProcesses += $flutterProcesses }
    if ($dartProcesses) { $allProcesses += $dartProcesses }
    
    if ($allProcesses) {
        Write-Host "📍 Found $($allProcesses.Count) Flutter/Dart process(es)" -ForegroundColor Yellow
        
        foreach ($process in $allProcesses) {
            Write-Host "🔪 Terminating process: $($process.Name) (ID: $($process.Id))" -ForegroundColor Yellow
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        }
        
        # Wait a moment for processes to terminate
        Start-Sleep -Seconds 2
        
        Write-Host "✅ Flutter processes stopped" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  No Flutter/Dart processes found running" -ForegroundColor Blue
    }
    
    # Also check for any web servers on common Flutter ports
    $commonPorts = @(3000, 3001, 8080, 8081)
    foreach ($port in $commonPorts) {
        try {
            $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
            if ($connections) {
                Write-Host "ℹ️  Port $port is still in use" -ForegroundColor Blue
            }
        }
        catch {
            # Ignore errors checking ports
        }
    }
    
    Write-Host ""
    Write-Host "✅ Frontend stop operation completed" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error stopping frontend servers: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}