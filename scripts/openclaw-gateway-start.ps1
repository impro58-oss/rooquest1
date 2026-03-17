# OpenClaw Gateway Auto-Start with Chrome Launch
# Starts gateway if not running, then opens UI in Chrome

$LogFile = "$env:TEMP\openclaw-gateway-autostart.log"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$DashboardUrl = "http://127.0.0.1:18789/"

function Write-Log {
    param($Message)
    "$Timestamp - $Message" | Add-Content -Path $LogFile
}

Write-Log "=== OpenClaw Auto-Start Sequence ==="

# Check if port 18789 is already listening
$PortInUse = Get-NetTCPConnection -LocalPort 18789 -ErrorAction SilentlyContinue
if ($PortInUse) {
    Write-Log "Port 18789 already in use. Gateway running."
} else {
    # Start the gateway
    Write-Log "Starting OpenClaw gateway..."
    Start-Process -FilePath "openclaw" -ArgumentList "gateway start" -WindowStyle Hidden
    
    # Wait for startup
    Write-Log "Waiting for gateway to initialize..."
    Start-Sleep -Seconds 15
    
    # Verify it's running
    $PortCheck = Get-NetTCPConnection -LocalPort 18789 -ErrorAction SilentlyContinue
    if ($PortCheck) {
        Write-Log "Gateway started successfully."
    } else {
        Write-Log "WARNING: Gateway may not have started."
    }
}

# Wait a moment for gateway to be fully ready
Start-Sleep -Seconds 3

# Open Chrome with the dashboard
Write-Log "Opening Chrome with OpenClaw UI..."
$ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (Test-Path $ChromePath) {
    Start-Process -FilePath $ChromePath -ArgumentList $DashboardUrl
    Write-Log "Chrome launched with UI."
} else {
    # Try alternative Chrome location
    $ChromePathAlt = "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    if (Test-Path $ChromePathAlt) {
        Start-Process -FilePath $ChromePathAlt -ArgumentList $DashboardUrl
        Write-Log "Chrome launched with UI (alt path)."
    } else {
        Write-Log "Chrome not found. Opening with default browser..."
        Start-Process $DashboardUrl
    }
}

Write-Log "Auto-start sequence complete."
Write-Log "UI ready at: $DashboardUrl"