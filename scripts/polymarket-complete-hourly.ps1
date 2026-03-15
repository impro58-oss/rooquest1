# Polymarket Complete Hourly Scan + Alert
# Runs scanner and sends Telegram alert if hot bets found

$WorkingDir = "C:\Users\impro\.openclaw\workspace\scripts"
$Timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"

Write-Host "=== POLYMARKET HOURLY SCAN ==="
Write-Host "Time: $Timestamp"
Write-Host ""

# Run the improved scanner (v4 with outcome descriptions)
$AlertFile = & "$WorkingDir\polymarket-hourly-scanner-v4.ps1"

if ($AlertFile -and (Test-Path $AlertFile)) {
    Write-Host ""
    Write-Host "Sending Telegram alert..."
    
    # Send alert using v5 (enhanced with recommendations)
    & "$WorkingDir\polymarket-alert-telegram-v5.ps1" -AlertFile $AlertFile
    
    # Export to GitHub for dashboard
    Write-Host "Exporting to GitHub..."
    & "$WorkingDir\export-polymarket-to-github.ps1"
    
    Write-Host "Done!"
} else {
    Write-Host "No alert file generated (no hot bets or error)"
}

Write-Host ""
Write-Host "=== SCAN COMPLETE ==="
