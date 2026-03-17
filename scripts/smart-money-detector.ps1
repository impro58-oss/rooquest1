# Smart Money Detection System
# Tracks odds movements to detect whale activity

param(
    [string]$DataDir = "C:\Users\impro\.openclaw\workspace\data\polymarket",
    [decimal]$MovementThreshold = 5.0  # Alert if odds move >5%
)

# Ensure data directory exists
if (!(Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

$HistoryFile = "$DataDir\odds_history.json"
$AlertsFile = "$DataDir\smart_money_alerts.json"

Write-Host "=== SMART MONEY DETECTION ==="
Write-Host "Threshold: $MovementThreshold% movement"
Write-Host ""

# Find latest scan data
$ScanDir = "C:\Users\impro\Documents\Polymarket-Scans"
$LatestFolder = Get-ChildItem -Path $ScanDir -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (!$LatestFolder) {
    Write-Error "No scan data found"
    exit 1
}

$LatestJson = Get-ChildItem -Path $LatestFolder.FullName -Filter "markets-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (!$LatestJson) {
    Write-Error "No market data file found"
    exit 1
}

# Load current data
$CurrentData = Get-Content $LatestJson.FullName -Raw | ConvertFrom-Json
$CurrentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "Loaded $($CurrentData.Count) markets from $($LatestJson.Name)"

# Load historical data
$History = @{}
if (Test-Path $HistoryFile) {
    $HistoryJson = Get-Content $HistoryFile -Raw | ConvertFrom-Json
    # Convert PSCustomObject to Hashtable
    $HistoryJson.PSObject.Properties | ForEach-Object { $History[$_.Name] = $_.Value }
    Write-Host "Loaded history for $($History.Count) markets"
} else {
    Write-Host "No history file - creating new"
}

# Detect movements
$Movements = @()
$SmartMoneyAlerts = @()

foreach ($Market in $CurrentData) {
    $MarketKey = $Market.Url
    $CurrentOdds = $Market.OddsNum
    
    if ($History.ContainsKey($MarketKey)) {
        $PreviousOdds = $History[$MarketKey].odds
        $PreviousTime = $History[$MarketKey].timestamp
        
        # Calculate movement
        $Movement = $CurrentOdds - $PreviousOdds
        $MovementPercent = [math]::Abs($Movement)
        
        if ($MovementPercent -ge $MovementThreshold) {
            $Direction = if ($Movement -gt 0) { "UP" } else { "DOWN" }
            $Confidence = if ($MovementPercent -ge 10) { "HIGH" } elseif ($MovementPercent -ge 7) { "MEDIUM" } else { "LOW" }
            
            $MovementData = [PSCustomObject]@{
                Market = $Market.Name
                Category = $Market.Category
                Url = $Market.Url
                PreviousOdds = $PreviousOdds
                CurrentOdds = $CurrentOdds
                Movement = $Movement
                MovementPercent = $MovementPercent
                Direction = $Direction
                Confidence = $Confidence
                PreviousTime = $PreviousTime
                CurrentTime = $CurrentTime
            }
            
            $Movements += $MovementData
            
            # Only alert on significant movements toward uncertainty (close to 50%)
            $DistanceTo50 = [math]::Abs($CurrentOdds - 50)
            if ($DistanceTo50 -le 15 -and $Confidence -ne "LOW") {
                $SmartMoneyAlerts += $MovementData
            }
        }
    }
    
    # Update history
    $History[$MarketKey] = @{
        odds = $CurrentOdds
        timestamp = $CurrentTime
        name = $Market.Name
        category = $Market.Category
    }
}

# Save updated history
$History | ConvertTo-Json -Depth 3 | Out-File -FilePath $HistoryFile -Encoding UTF8

# Generate report
Write-Host ""
Write-Host "=== ANALYSIS RESULTS ==="
Write-Host "Markets with movement >$MovementThreshold%: $($Movements.Count)"
Write-Host "Smart Money Alerts: $($SmartMoneyAlerts.Count)"

if ($SmartMoneyAlerts.Count -gt 0) {
    Write-Host ""
    Write-Host "🚨 SMART MONEY DETECTED:"
    Write-Host ""
    
    foreach ($Alert in $SmartMoneyAlerts | Sort-Object MovementPercent -Descending) {
        Write-Host "  [$($Alert.Confidence)] $($Alert.Market)"
        Write-Host "    Odds: $($Alert.PreviousOdds)% → $($Alert.CurrentOdds)% ($($Alert.Direction) $($Alert.MovementPercent)%)"
        Write-Host "    Category: $($Alert.Category)"
        Write-Host ""
    }
    
    # Save alerts
    $AlertOutput = @{
        timestamp = $CurrentTime
        total_movements = $Movements.Count
        smart_money_alerts = $SmartMoneyAlerts
        all_movements = $Movements
    }
    
    $AlertOutput | ConvertTo-Json -Depth 3 | Out-File -FilePath $AlertsFile -Encoding UTF8
    Write-Host "Alerts saved to: $AlertsFile"
    
    # Return for Telegram
    $AlertsFile
} else {
    Write-Host ""
    Write-Host "No smart money activity detected above threshold"
    $null
}

# Also export movements to GitHub
$GitHubOutput = @{
    timestamp = $CurrentTime
    scan_file = $LatestJson.Name
    threshold = $MovementThreshold
    total_markets = $CurrentData.Count
    markets_with_movement = $Movements.Count
    smart_money_alerts = $SmartMoneyAlerts.Count
    movements = $Movements
    top_opportunities = $SmartMoneyAlerts | Sort-Object MovementPercent -Descending | Select-Object -First 10
}

$GitHubFile = "$DataDir\smart_money_latest.json"
$GitHubOutput | ConvertTo-Json -Depth 3 | Out-File -FilePath $GitHubFile -Encoding UTF8
Write-Host "Exported to GitHub: $GitHubFile"
