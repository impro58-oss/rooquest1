# Polymarket HTML Exporter
# Creates mobile-friendly HTML version of hot bets for remote viewing

param(
    [string]$InputFile,
    [string]$OutputDir = "C:\Users\impro\.openclaw\workspace\data\polymarket"
)

if (!(Test-Path $InputFile)) {
    Write-Error "Input file not found: $InputFile"
    exit 1
}

# Ensure output directory exists
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Get timestamp from filename
$FileName = Split-Path $InputFile -Leaf
$Timestamp = $FileName -replace 'hot-bets-', '' -replace '\.txt$', ''

# Read the content
$Content = Get-Content $InputFile -Raw

# Parse the bets
$Lines = $Content -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
$TotalCount = 0
if ($Lines[1] -match "Found (\d+) opportunities") {
    $TotalCount = $Matches[1]
}

# Build HTML
$Html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Polymarket Hot Bets - $Timestamp</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
            background: #0a0a0a; 
            color: #fff; 
            padding: 16px;
            line-height: 1.5;
        }
        .header { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
            padding: 20px; 
            border-radius: 12px; 
            margin-bottom: 20px;
            text-align: center;
        }
        .header h1 { font-size: 24px; margin-bottom: 8px; }
        .header p { opacity: 0.9; font-size: 14px; }
        .stats { 
            display: flex; 
            justify-content: space-around; 
            margin-bottom: 20px;
            flex-wrap: wrap;
        }
        .stat { 
            background: #1a1a1a; 
            padding: 15px; 
            border-radius: 8px; 
            text-align: center;
            margin: 5px;
            flex: 1;
            min-width: 100px;
        }
        .stat-value { font-size: 28px; font-weight: bold; color: #667eea; }
        .stat-label { font-size: 12px; opacity: 0.7; margin-top: 5px; }
        .bet { 
            background: #1a1a1a; 
            border-left: 4px solid #667eea;
            padding: 16px; 
            margin-bottom: 12px; 
            border-radius: 8px;
        }
        .bet-category { 
            display: inline-block; 
            background: #667eea; 
            color: #fff; 
            padding: 4px 12px; 
            border-radius: 20px; 
            font-size: 11px; 
            font-weight: bold;
            text-transform: uppercase;
            margin-bottom: 8px;
        }
        .bet-name { font-size: 16px; font-weight: 600; margin-bottom: 8px; }
        .bet-outcome { font-size: 14px; opacity: 0.8; margin-bottom: 8px; }
        .bet-odds { 
            display: flex; 
            justify-content: space-between; 
            align-items: center;
            margin-bottom: 12px;
        }
        .odds-value { font-size: 20px; font-weight: bold; color: #4ade80; }
        .edge-type { 
            background: #374151; 
            padding: 4px 12px; 
            border-radius: 4px; 
            font-size: 12px;
        }
        .bet-link { 
            display: block; 
            background: #667eea; 
            color: #fff; 
            text-align: center; 
            padding: 12px; 
            border-radius: 8px; 
            text-decoration: none;
            font-weight: 600;
        }
        .bet-link:active { background: #5a67d8; }
        .footer { 
            text-align: center; 
            margin-top: 30px; 
            padding: 20px; 
            opacity: 0.6;
            font-size: 12px;
        }
        .filter-btn {
            background: #374151;
            border: none;
            color: #fff;
            padding: 8px 16px;
            margin: 4px;
            border-radius: 20px;
            cursor: pointer;
            font-size: 12px;
        }
        .filter-btn.active {
            background: #667eea;
        }
        .filters {
            text-align: center;
            margin-bottom: 20px;
            position: sticky;
            top: 0;
            background: #0a0a0a;
            padding: 10px 0;
            z-index: 100;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔥 Polymarket Hot Bets</h1>
        <p>$Timestamp | $TotalCount Opportunities</p>
    </div>
    
    <div class="stats">
        <div class="stat">
            <div class="stat-value">$TotalCount</div>
            <div class="stat-label">Total</div>
        </div>
        <div class="stat">
            <div class="stat-value" id="closeCalls">0</div>
            <div class="stat-label">Close Calls</div>
        </div>
        <div class="stat">
            <div class="stat-value" id="categories">0</div>
            <div class="stat-label">Categories</div>
        </div>
    </div>

    <div class="filters">
        <button class="filter-btn active" onclick="filterBets('all')">All</button>
        <button class="filter-btn" onclick="filterBets('sports')">Sports</button>
        <button class="filter-btn" onclick="filterBets('politics')">Politics</button>
        <button class="filter-btn" onclick="filterBets('crypto')">Crypto</button>
        <button class="filter-btn" onclick="filterBets('finance')">Finance</button>
        <button class="filter-btn" onclick="filterBets('entertainment')">Entertainment</button>
    </div>

    <div id="bets-container">
"@

# Parse and add each bet
$Bets = @()
$CurrentBet = $null
$CloseCalls = 0
$Categories = @{}

for ($i = 2; $i -lt $Lines.Count; $i++) {
    $Line = $Lines[$i]
    
    if ($Line -match '^\[([A-Z]+)\]\s+(.+)$') {
        if ($CurrentBet) {
            $Bets += $CurrentBet
        }
        $CurrentBet = @{
            Category = $Matches[1].ToLower()
            Name = $Matches[2]
            Outcome = ""
            Odds = ""
            EdgeType = ""
            Url = ""
        }
        if (!$Categories.ContainsKey($Matches[1])) {
            $Categories[$Matches[1]] = 0
        }
        $Categories[$Matches[1]]++
    }
    elseif ($Line -match '^Outcome:\s+(.+)$') {
        $CurrentBet.Outcome = $Matches[1]
    }
    elseif ($Line -match 'Odds:\s+(\d+)%') {
        $CurrentBet.Odds = $Matches[0]
        $OddsNum = [int]$Matches[1]
        if ($OddsNum -ge 40 -and $OddsNum -le 60) {
            $CurrentBet.EdgeType = "CLOSE_CALL"
            $CloseCalls++
        }
        elseif ($OddsNum -lt 40) {
            $CurrentBet.EdgeType = "UNDERDOG"
        }
        else {
            $CurrentBet.EdgeType = "FAVORITE"
        }
    }
    elseif ($Line -match '^Link:\s+(.+)$') {
        $CurrentBet.Url = $Matches[1]
    }
}

if ($CurrentBet) {
    $Bets += $CurrentBet
}

# Add bets to HTML
foreach ($Bet in $Bets) {
    $EdgeClass = if ($Bet.EdgeType -eq "CLOSE_CALL") { "background: #f59e0b; color: #000;" } elseif ($Bet.EdgeType -eq "UNDERDOG") { "background: #ef4444;" } else { "background: #22c55e;" }
    
    $Html += @"
        <div class="bet" data-category="$($Bet.Category)">
            <div class="bet-category">$($Bet.Category.ToUpper())</div>
            <div class="bet-name">$($Bet.Name)</div>
            <div class="bet-outcome">🎯 $($Bet.Outcome)</div>
            <div class="bet-odds">
                <span class="odds-value">$($Bet.Odds)</span>
                <span class="edge-type" style="$EdgeClass">$($Bet.EdgeType)</span>
            </div>
            <a href="$($Bet.Url)" class="bet-link" target="_blank">View Market →</a>
        </div>
"@
}

$CategoryCount = $Categories.Count

$Html += @"
    </div>

    <div class="footer">
        <p>Generated by Roo Intelligence System</p>
        <p>Data refreshes hourly</p>
    </div>

    <script>
        // Update stats
        document.getElementById('closeCalls').textContent = '$CloseCalls';
        document.getElementById('categories').textContent = '$CategoryCount';

        // Filter functionality
        function filterBets(category) {
            const bets = document.querySelectorAll('.bet');
            const buttons = document.querySelectorAll('.filter-btn');
            
            buttons.forEach(btn => btn.classList.remove('active'));
            event.target.classList.add('active');
            
            bets.forEach(bet => {
                if (category === 'all' || bet.dataset.category === category) {
                    bet.style.display = 'block';
                } else {
                    bet.style.display = 'none';
                }
            });
        }
    </script>
</body>
</html>
"@

# Save HTML file
$HtmlFile = "$OutputDir\hot-bets-$Timestamp.html"
$Html | Out-File -FilePath $HtmlFile -Encoding UTF8

Write-Host "Created HTML: $HtmlFile"

# Also save as latest
$LatestHtml = "$OutputDir\hot-bets-latest.html"
$Html | Out-File -FilePath $LatestHtml -Encoding UTF8

Write-Host "Also saved as: $LatestHtml"

# Return the URL path for Telegram
Write-Output "https://raw.githubusercontent.com/impro58-oss/rooquest1/master/data/polymarket/hot-bets-latest.html"
