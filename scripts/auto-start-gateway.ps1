# Auto-start OpenClaw gateway on system boot
# Ensures gateway starts automatically after power cut or restart

param(
    [switch]$CheckOnly = $false
)

$GatewayUrl = "http://127.0.0.1:18789/health"
$MaxRetries = 3
$RetryDelay = 5

function Test-GatewayHealth {
    try {
        $Response = Invoke-WebRequest -Uri $GatewayUrl -Method GET -TimeoutSec 5 -ErrorAction Stop
        return $Response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Start-GatewayService {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Starting OpenClaw gateway..."
    
    # Start gateway
    try {
        $Output = openclaw gateway start 2>&1
        Write-Host $Output
    } catch {
        Write-Host "[ERROR] Failed to start gateway: $_"
        return $false
    }
    
    # Wait and verify
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Waiting for gateway to initialize..."
    Start-Sleep -Seconds 10
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        if (Test-GatewayHealth) {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Gateway is healthy!"
            return $true
        }
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Retry $i/$MaxRetries..."
        Start-Sleep -Seconds $RetryDelay
    }
    
    Write-Host "[ERROR] Gateway failed to start after $MaxRetries attempts"
    return $false
}

# Main logic
if ($CheckOnly) {
    # Just check status
    if (Test-GatewayHealth) {
        Write-Host "[OK] Gateway is running"
        exit 0
    } else {
        Write-Host "[WARN] Gateway is not running"
        exit 1
    }
} else {
    # Try to start if not running
    if (Test-GatewayHealth) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Gateway already running, no action needed"
        exit 0
    }
    
    $Success = Start-GatewayService
    exit ($Success ? 0 : 1)
}
