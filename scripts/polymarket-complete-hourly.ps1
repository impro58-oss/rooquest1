# Polymarket Complete Hourly Scan + Smart Money Detection
# Runs scanner, detects smart money, sends alerts

$WorkingDir = "C:\Users\impro\.openclaw\workspace\scripts"
$Timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"

Write-Host "=== POLYMARKET HOURLY SCAN + SMART MONEY ==="
Write-Host "Time: $Timestamp"
Write-Host ""

# Step 1: Run the scanner (v4 with outcome descriptions)
$AlertFile = & "$WorkingDir\polymarket-hourly-scanner-v4.ps1"

if ($AlertFile -and (Test-Path $AlertFile)) {
    Write-Host ""
    Write-Host "Sending Telegram alert..."
    
    # Send regular alert using v5
    & "$WorkingDir\polymarket-alert-telegram-v5.ps1" -AlertFile $AlertFile
    
    # Export to GitHub for dashboard
    Write-Host "Exporting to GitHub..."
    & "$WorkingDir\export-polymarket-to-github.ps1"
    
    Write-Host "Done!"
} else {
    Write-Host "No alert file generated (no hot bets or error)"
}

# Step 2: Run Smart Money Detection
Write-Host ""
Write-Host "Running Smart Money Detection..."
$SmartMoneyFile = & "$WorkingDir\smart-money-detector.ps1"

if ($SmartMoneyFile -and (Test-Path $SmartMoneyFile)) {
    Write-Host ""
    Write-Host "Sending Smart Money alert..."
    & "$WorkingDir\smart-money-alert-telegram.ps1" -AlertFile $SmartMoneyFile
    
    Write-Host "Smart Money alert sent!"
} else {
    Write-Host "No smart money activity detected"
}

Write-Host ""
Write-Host "=== SCAN COMPLETE ==="
