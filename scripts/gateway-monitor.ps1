# gateway-monitor.ps1
# Monitors OpenClaw gateway and auto-restarts if it fails
# Run this as a scheduled task every 5 minutes

$LogFile = "$env:USERPROFILE\.openclaw\logs\gateway-monitor.log"
$MaxLogSize = 10MB

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Tee-Object -FilePath $LogFile -Append
}

# Rotate log if too large
if (Test-Path $LogFile) {
    $logSize = (Get-Item $LogFile).Length
    if ($logSize -gt $MaxLogSize) {
        Move-Item $LogFile "$LogFile.old" -Force
        Write-Log "Log rotated"
    }
}

Write-Log "Starting gateway health check..."

# Check if gateway is responding
try {
    $response = Invoke-RestMethod -Uri "http://127.0.0.1:18789/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Log "Gateway is healthy: $($response.status)"
    exit 0
} catch {
    Write-Log "Gateway health check FAILED: $($_.Exception.Message)"
}

# Check if gateway process is running
$gatewayProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*openclaw*gateway*" }

if ($gatewayProcess) {
    Write-Log "Gateway process found (PID: $($gatewayProcess.Id)) but not responding. Killing..."
    Stop-Process -Id $gatewayProcess.Id -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Restart gateway
Write-Log "Attempting to restart gateway..."
try {
    Start-Process -FilePath "openclaw" -ArgumentList "gateway", "start", "--daemon" -WindowStyle Hidden
    Start-Sleep -Seconds 5
    
    # Verify restart
    try {
        $verify = Invoke-RestMethod -Uri "http://127.0.0.1:18789/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
        Write-Log "Gateway restarted successfully: $($verify.status)"
    } catch {
        Write-Log "CRITICAL: Gateway restart failed - $($_.Exception.Message)"
        # Could add notification here (email, telegram, etc.)
    }
} catch {
    Write-Log "CRITICAL: Failed to start gateway - $($_.Exception.Message)"
}

Write-Log "Monitor cycle complete"
