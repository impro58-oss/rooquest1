# fetch-polymarket-portfolio.ps1
# Fetch Polymarket portfolio via Data API (public, no auth required)
# Uses wallet address: 0x2d8c75c3fcbbFe50f92c2eDb00ab7dcF89578071

$WalletAddress = "0x2d8c75c3fcbbFe50f92c2eDb00ab7dcF89578071"
$DataApiBase = "https://data-api.polymarket.com"

Write-Host "Fetching Polymarket portfolio for $WalletAddress..." -ForegroundColor Cyan

# Helper function to convert Unix timestamp
function Convert-UnixTime($timestamp) {
    $epoch = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0
    return $epoch.AddSeconds($timestamp).ToString('yyyy-MM-dd HH:mm')
}

# Fetch positions
try {
    $PositionsUrl = "$DataApiBase/positions?user=$WalletAddress"
    Write-Host "  Calling: $PositionsUrl" -ForegroundColor Gray
    $Positions = Invoke-RestMethod -Uri $PositionsUrl -Method GET -ContentType "application/json"
    
    Write-Host "`n=== CURRENT POSITIONS ===" -ForegroundColor Green
    if ($Positions -and $Positions.Count -gt 0) {
        $TotalInvested = 0
        $TotalCurrent = 0
        $TotalPnL = 0
        
        $Positions | ForEach-Object {
            $Title = $_.title
            $Outcome = $_.outcome
            $Shares = [math]::Round($_.size, 2)
            $AvgPrice = [math]::Round($_.avgPrice, 4)
            $CurPrice = [math]::Round($_.curPrice, 4)
            $InitialValue = [math]::Round($_.initialValue, 2)
            $CurrentValue = [math]::Round($_.currentValue, 2)
            $CashPnL = [math]::Round($_.cashPnl, 2)
            $PercentPnL = [math]::Round($_.percentPnl, 2)
            
            Write-Host "Market: $Title" -ForegroundColor Yellow
            Write-Host "  Outcome: $Outcome | Shares: $Shares" -ForegroundColor White
            Write-Host "  Avg Buy: $AvgPrice USDC | Current: $CurPrice USDC" -ForegroundColor White
            Write-Host "  Invested: $InitialValue USDC | Current Value: $CurrentValue USDC" -ForegroundColor Cyan
            
            $PnLColor = if ($CashPnL -gt 0) { "Green" } elseif ($CashPnL -lt 0) { "Red" } else { "White" }
            Write-Host "  P&L: $CashPnL USDC ($PercentPnL%)" -ForegroundColor $PnLColor
            Write-Host ""
            
            $TotalInvested += $InitialValue
            $TotalCurrent += $CurrentValue
            $TotalPnL += $CashPnL
        }
        
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Total Positions: $($Positions.Count)" -ForegroundColor Green
        Write-Host "Total Invested: $TotalInvested USDC" -ForegroundColor Cyan
        Write-Host "Current Value: $TotalCurrent USDC" -ForegroundColor Cyan
        $TotalPnLColor = if ($TotalPnL -gt 0) { "Green" } elseif ($TotalPnL -lt 0) { "Red" } else { "White" }
        $TotalPercent = if ($TotalInvested -gt 0) { [math]::Round(($TotalPnL / $TotalInvested) * 100, 2) } else { 0 }
        Write-Host "Total P&L: $TotalPnL USDC ($TotalPercent%)" -ForegroundColor $TotalPnLColor
        Write-Host "========================================" -ForegroundColor Green
    } else {
        Write-Host "No active positions found." -ForegroundColor Yellow
    }
} catch {
    Write-Error "Failed to fetch positions: $_"
}

# Fetch recent trades
try {
    $TradesUrl = "$DataApiBase/trades?user=$WalletAddress&limit=20"
    Write-Host "`n=== RECENT TRADES (Last 20) ===" -ForegroundColor Green
    $Trades = Invoke-RestMethod -Uri $TradesUrl -Method GET -ContentType "application/json"
    
    if ($Trades -and $Trades.Count -gt 0) {
        $Trades | ForEach-Object {
            $SideColor = if($_.side -eq "buy"){"Green"}else{"Red"}
            $Side = $_.side.ToUpper()
            $Title = $_.title
            $Shares = [math]::Round($_.size, 2)
            $Price = [math]::Round($_.price, 4)
            $TimeStr = Convert-UnixTime $_.timestamp
            $Total = [math]::Round($Shares * $Price, 2)
            
            Write-Host "$Side | $Title" -ForegroundColor $SideColor
            Write-Host "  Shares: $Shares @ $Price USDC = $Total USDC" -ForegroundColor White
            Write-Host "  Time: $TimeStr" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "No recent trades found." -ForegroundColor Yellow
    }
} catch {
    Write-Error "Failed to fetch trades: $_"
}

Write-Host "`nDone!" -ForegroundColor Green
