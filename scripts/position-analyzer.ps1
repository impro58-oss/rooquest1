# position-analyzer.ps1
# Analyzes Polymarket portfolio and flags positions needing attention
# Uses wallet: 0x2d8c75c3fcbbFe50f92c2eDb00ab7dcF89578071

$WalletAddress = "0x2d8c75c3fcbbFe50f92c2eDb00ab7dcF89578071"
$DataApiBase = "https://data-api.polymarket.com"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  POLYMARKET POSITION ANALYZER" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Risk thresholds
$MAX_POSITION_PCT = 25       # No single position > 25% of portfolio
$STOP_LOSS_PCT = -50         # Review positions down > 50%
$PROFIT_TAKE_PCT = 100       # Consider taking profits > 100%
$DEAD_POSITION_PCT = -90     # Likely dead if down > 90%

# Fetch positions
try {
    $Positions = Invoke-RestMethod -Uri "$DataApiBase/positions?user=$WalletAddress" -Method GET
    
    if (!$Positions -or $Positions.Count -eq 0) {
        Write-Host "No positions found." -ForegroundColor Yellow
        exit
    }
    
    # Calculate totals
    $TotalInvested = ($Positions | Measure-Object -Property initialValue -Sum).Sum
    $TotalCurrent = ($Positions | Measure-Object -Property currentValue -Sum).Sum
    $TotalPnL = ($Positions | Measure-Object -Property cashPnl -Sum).Sum
    
    Write-Host "PORTFOLIO SUMMARY" -ForegroundColor Green
    Write-Host "Total Invested: $([math]::Round($TotalInvested, 2)) USDC" -ForegroundColor White
    Write-Host "Current Value:  $([math]::Round($TotalCurrent, 2)) USDC" -ForegroundColor White
    $PnLColor = if ($TotalPnL -ge 0) { "Green" } else { "Red" }
    Write-Host "Total P&L:      $([math]::Round($TotalPnL, 2)) USDC`n" -ForegroundColor $PnLColor
    
    # Categorize positions
    $DeadPositions = @()
    $StopLossPositions = @()
    $ProfitTakePositions = @()
    $ConcentrationRisks = @()
    $Holds = @()
    
    $Positions | ForEach-Object {
        $PositionPct = ($_.initialValue / $TotalInvested) * 100
        $PnLPct = $_.percentPnl
        
        $PositionData = [PSCustomObject]@{
            Title = $_.title
            Outcome = $_.outcome
            Shares = [math]::Round($_.size, 2)
            Invested = [math]::Round($_.initialValue, 2)
            CurrentValue = [math]::Round($_.currentValue, 2)
            PnL = [math]::Round($_.cashPnl, 2)
            PnLPct = [math]::Round($PnLPct, 1)
            PositionPct = [math]::Round($PositionPct, 1)
            AvgPrice = [math]::Round($_.avgPrice, 4)
            CurPrice = [math]::Round($_.curPrice, 4)
        }
        
        # Categorize
        if ($PnLPct -le $DEAD_POSITION_PCT) {
            $DeadPositions += $PositionData
        } elseif ($PnLPct -le $STOP_LOSS_PCT) {
            $StopLossPositions += $PositionData
        } elseif ($PnLPct -ge $PROFIT_TAKE_PCT) {
            $ProfitTakePositions += $PositionData
        } elseif ($PositionPct -gt $MAX_POSITION_PCT) {
            $ConcentrationRisks += $PositionData
        } else {
            $Holds += $PositionData
        }
    }
    
    # Display alerts
    if ($DeadPositions.Count -gt 0) {
        Write-Host "`n⚠️  DEAD POSITIONS (Likely worthless)" -ForegroundColor Red
        Write-Host "   Consider closing to free up capital" -ForegroundColor DarkGray
        $DeadPositions | ForEach-Object {
            Write-Host "   • $($_.Title)" -ForegroundColor Red
            Write-Host "     Invested: $($_.Invested) USDC → Current: $($_.CurrentValue) USDC ($($_.PnLPct)%)" -ForegroundColor Gray
        }
    }
    
    if ($StopLossPositions.Count -gt 0) {
        Write-Host "`n🛑 STOP LOSS HIT (Down > 50%)" -ForegroundColor DarkRed
        Write-Host "   Review if thesis still valid" -ForegroundColor DarkGray
        $StopLossPositions | ForEach-Object {
            Write-Host "   • $($_.Title)" -ForegroundColor DarkRed
            Write-Host "     P&L: $($_.PnL) USDC ($($_.PnLPct)%) | Current Price: $($_.CurPrice)" -ForegroundColor Gray
        }
    }
    
    if ($ConcentrationRisks.Count -gt 0) {
        Write-Host "`n⚡ CONCENTRATION RISK (> 25% of portfolio)" -ForegroundColor Yellow
        Write-Host "   Diversify to reduce single-market risk" -ForegroundColor DarkGray
        $ConcentrationRisks | ForEach-Object {
            Write-Host "   • $($_.Title)" -ForegroundColor Yellow
            Write-Host "     Position size: $($_.PositionPct)% of portfolio ($($_.Invested) USDC)" -ForegroundColor Gray
        }
    }
    
    if ($ProfitTakePositions.Count -gt 0) {
        Write-Host "`n💰 PROFIT TAKE CANDIDATES (Up > 100%)" -ForegroundColor Green
        Write-Host "   Consider taking some profits" -ForegroundColor DarkGray
        $ProfitTakePositions | ForEach-Object {
            Write-Host "   • $($_.Title)" -ForegroundColor Green
            Write-Host "     P&L: +$($_.PnL) USDC (+$($_.PnLPct)%) | Current: $($_.CurPrice)" -ForegroundColor Gray
        }
    }
    
    if ($Holds.Count -gt 0) {
        Write-Host "`n✅ HOLD (Within normal ranges)" -ForegroundColor Cyan
        $Holds | ForEach-Object {
            $Color = if ($_.PnL -gt 0) { "Green" } elseif ($_.PnL -lt 0) { "Red" } else { "White" }
            Write-Host "   • $($_.Title)" -ForegroundColor $Color
            Write-Host "     P&L: $($_.PnL) USDC ($($_.PnLPct)%) | Size: $($_.PositionPct)% of portfolio" -ForegroundColor Gray
        }
    }
    
    # Risk summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "RISK SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Dead positions:     $($DeadPositions.Count)" -ForegroundColor $(if($DeadPositions.Count -gt 0){"Red"}else{"Green"})
    Write-Host "Stop loss hits:     $($StopLossPositions.Count)" -ForegroundColor $(if($StopLossPositions.Count -gt 0){"DarkRed"}else{"Green"})
    Write-Host "Concentration risk: $($ConcentrationRisks.Count)" -ForegroundColor $(if($ConcentrationRisks.Count -gt 0){"Yellow"}else{"Green"})
    Write-Host "Profit candidates:  $($ProfitTakePositions.Count)" -ForegroundColor $(if($ProfitTakePositions.Count -gt 0){"Green"}else{"Gray"})
    Write-Host "Normal holds:       $($Holds.Count)" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Recommendations
    Write-Host "RECOMMENDED ACTIONS:" -ForegroundColor Yellow
    if ($DeadPositions.Count -gt 0) {
        Write-Host "  1. Close dead positions to free up capital" -ForegroundColor White
    }
    if ($StopLossPositions.Count -gt 0) {
        Write-Host "  2. Review stop-loss hits — cut or hold?" -ForegroundColor White
    }
    if ($ConcentrationRisks.Count -gt 0) {
        Write-Host "  3. Reduce concentration — no position > 25%" -ForegroundColor White
    }
    if ($ProfitTakePositions.Count -gt 0) {
        Write-Host "  4. Consider taking profits on big winners" -ForegroundColor White
    }
    if ($DeadPositions.Count -eq 0 -and $StopLossPositions.Count -eq 0 -and $ConcentrationRisks.Count -eq 0) {
        Write-Host "  • Portfolio looks healthy — no immediate action needed" -ForegroundColor Green
    }
    
} catch {
    Write-Error "Failed to analyze portfolio: $_"
}

Write-Host "`nDone! Run this daily to monitor risk.`n" -ForegroundColor Green
