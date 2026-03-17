# data-exporter.ps1
# Exports betting data to JSON for Hugging Face visualization
# Creates: betting-data.json, portfolio-data.json, opportunities-data.json

$DataDir = "$env:USERPROFILE\.openclaw\workspace\data"
if (!(Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

$WalletAddress = "0x2d8c75c3fcbbFe50f92c2eDb00ab7dcF89578071"
$DataApiBase = "https://data-api.polymarket.com"

Write-Host "Exporting data for Hugging Face visualization..." -ForegroundColor Cyan

# 1. Export Portfolio Data
try {
    $Positions = Invoke-RestMethod -Uri "$DataApiBase/positions?user=$WalletAddress" -Method GET
    
    $PortfolioData = @{
        lastUpdated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        totalPositions = $Positions.Count
        totalInvested = ($Positions | Measure-Object -Property initialValue -Sum).Sum
        totalCurrent = ($Positions | Measure-Object -Property currentValue -Sum).Sum
        totalPnL = ($Positions | Measure-Object -Property cashPnl -Sum).Sum
        positions = @()
    }
    
    $Positions | ForEach-Object {
        $PortfolioData.positions += @{
            market = $_.title
            outcome = $_.outcome
            shares = [math]::Round($_.size, 4)
            avgPrice = $_.avgPrice
            curPrice = $_.curPrice
            invested = $_.initialValue
            currentValue = $_.currentValue
            pnl = $_.cashPnl
            pnlPercent = $_.percentPnl
            marketUrl = "https://polymarket.com/event/$($_.slug)"
            endDate = $_.endDate
        }
    }
    
    $PortfolioData | ConvertTo-Json -Depth 10 | Out-File "$DataDir\portfolio-data.json" -Encoding utf8
    Write-Host "  Portfolio data exported" -ForegroundColor Green
} catch {
    Write-Host "  Error exporting portfolio: $_" -ForegroundColor Red
}

# 2. Export Opportunities Data (from scan files)
$Today = Get-Date -Format "yyyy-MM-dd"
$ScanFolder = "C:\Users\impro\Documents\Polymarket-Scans\$Today"

$OpportunitiesData = @{
    lastUpdated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    hotBets = @()
    contrarianPlays = @()
    quickFlips = @()
}

# Parse hot bets
$HotBetsFile = Get-ChildItem "$ScanFolder\hot-bets-*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($HotBetsFile) {
    $Content = Get-Content $HotBetsFile.FullName -Raw
    $OpportunitiesData.hotBets = @{
        file = $HotBetsFile.Name
        content = $Content
        timestamp = $HotBetsFile.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
}

# Parse contrarian plays
$ContrarianFile = Get-ChildItem "$ScanFolder\contrarian-plays-*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($ContrarianFile) {
    $Content = Get-Content $ContrarianFile.FullName -Raw
    $OpportunitiesData.contrarianPlays = @{
        file = $ContrarianFile.Name
        content = $Content
        timestamp = $ContrarianFile.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
}

$OpportunitiesData | ConvertTo-Json -Depth 5 | Out-File "$DataDir\opportunities-data.json" -Encoding utf8
Write-Host "  Opportunities data exported" -ForegroundColor Green

# 3. Export Journal Data (if exists)
$JournalFile = "$env:USERPROFILE\.openclaw\workspace\memory\betting-journal.csv"
if (Test-Path $JournalFile) {
    $Journal = Import-Csv $JournalFile
    $JournalData = @{
        lastUpdated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        totalBets = $Journal.Count
        completedBets = ($Journal | Where-Object { $_.Status -ne "OPEN" }).Count
        openBets = ($Journal | Where-Object { $_.Status -eq "OPEN" }).Count
        bets = $Journal
    }
    $JournalData | ConvertTo-Json -Depth 5 | Out-File "$DataDir\journal-data.json" -Encoding utf8
    Write-Host "  Journal data exported" -ForegroundColor Green
}

# 4. Create combined dashboard data
$DashboardData = @{
    lastUpdated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    wallet = $WalletAddress
    portfolio = $PortfolioData
    opportunities = $OpportunitiesData
    links = @{
        polymarket = "https://polymarket.com"
        portfolio = "https://polymarket.com/portfolio"
        dataApi = "https://data-api.polymarket.com"
    }
}

$DashboardData | ConvertTo-Json -Depth 10 | Out-File "$DataDir\dashboard-data.json" -Encoding utf8
Write-Host "  Dashboard data exported" -ForegroundColor Green

# 5. Create README for Hugging Face
$Readme = @"
# Polymarket Trading Dashboard Data

This repository contains live data for the Polymarket trading dashboard.

## Files

- \`portfolio-data.json\` - Current positions, P&L, values
- \`opportunities-data.json\` - Latest scan results (hot bets, contrarian plays)
- \`journal-data.json\` - Betting journal and performance tracking
- \`dashboard-data.json\` - Combined data for visualization

## Update Frequency

- Portfolio: Every 15 minutes
- Opportunities: Every hour
- Journal: On each bet

## Wallet

\`0x2d8c75c3fcbbFe50f92c2eDb00ab7dcF89578071\`

## Links

- [Polymarket](https://polymarket.com)
- [Portfolio](https://polymarket.com/portfolio)

---

*Last updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

$Readme | Out-File "$DataDir\README.md" -Encoding utf8

Write-Host "`nData export complete!" -ForegroundColor Green
Write-Host "Files in: $DataDir" -ForegroundColor Cyan
Write-Host "`nNext: Commit to GitHub for Hugging Face visualization" -ForegroundColor Yellow
