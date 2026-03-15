# Polymarket Hourly Scan
# Runs every hour, sends Telegram alerts for hot bets and contrarian plays

cd "C:\Users\impro\.openclaw\workspace\scripts"

# Get today's date for file paths
$Today = Get-Date -Format "yyyy-MM-dd"

# 1. Run hot bets scanner
Write-Host "Running hot bets scanner..."
$HotBets = .\polymarket-hourly-scanner.ps1

# If hot bets found, send Telegram alert
if ($HotBets) {
    $LatestHot = Get-ChildItem "C:\Users\impro\Documents\Polymarket-Scans\$Today\hot-bets-*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($LatestHot) {
        .\polymarket-alert-telegram.ps1 -AlertFile $LatestHot.FullName
    }
}

# 2. Run contrarian scanner (for $50 value plays)
Write-Host "Running contrarian scanner..."
$Contrarian = .\contrarian-scanner.ps1

# If contrarian plays found, send alert
if ($Contrarian -and $Contrarian.Count -gt 0) {
    $LatestContrarian = Get-ChildItem "C:\Users\impro\Documents\Polymarket-Scans\$Today\contrarian-plays-*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($LatestContrarian) {
        .\polymarket-alert-telegram.ps1 -AlertFile $LatestContrarian.FullName
    }
}

# 3. Update Notion with new opportunities
.\update-notion-next-bets.ps1

Write-Host "Hourly scan complete!"
