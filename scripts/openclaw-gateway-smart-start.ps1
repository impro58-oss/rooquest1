# OpenClaw Gateway Smart Auto-Start
# Checks if gateway is running before starting to avoid conflicts

$LogFile = "$env:TEMP\openclaw-gateway-autostart.log"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Log {
    param($Message)
    "$Timestamp - $Message" | Add-Content -Path $LogFile
    Write-Output $Message
}

# Check if OpenClaw gateway is already running
$GatewayProcess = Get-Process | Where-Object { $_.ProcessName -like "*openclaw*" -or $_.ProcessName -like "*claw*" } | Select-Object -First 1

if ($GatewayProcess) {
    Write-Log "Gateway already running (PID: $($GatewayProcess.Id)). Skipping start."
    exit 0
}

# Check if port 18789 is already in use
$PortCheck = Get-NetTCPConnection -LocalPort 18789 -ErrorAction SilentlyContinue | Select-Object -First 1

if ($PortCheck) {
    Write-Log "Port 18789 already in use. Gateway likely running. Skipping start."
    exit 0
}

# Try to start the gateway
Write-Log "Gateway not running. Starting now..."

try {
    # Start OpenClaw gateway in background
    $Process = Start-Process -FilePath "openclaw" -ArgumentList "gateway start" -WindowStyle Hidden -PassThru
    
    # Wait a few seconds to confirm it started
    Start-Sleep -Seconds 5
    
    # Verify it's running
    $VerifyProcess = Get-Process | Where-Object { $_.ProcessName -like "*openclaw*" -or $_.ProcessName -like "*claw*" } | Select-Object -First 1
    
    if ($VerifyProcess) {
        Write-Log "Gateway started successfully (PID: $($VerifyProcess.Id))"
    } else {
        Write-Log "WARNING: Gateway start command issued but process not detected."
    }
} catch {
    Write-Log "ERROR: Failed to start gateway: $_"
    exit 1
}

Write-Log "Auto-start complete."