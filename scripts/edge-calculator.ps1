# edge-calculator.ps1
# Calculate expected value and optimal bet sizing for Polymarket

function Calculate-Edge {
    param(
        [Parameter(Mandatory=$true)]
        [decimal]$YourProbability,    # Your estimated probability (0-100)
        
        [Parameter(Mandatory=$true)]
        [decimal]$MarketOdds,         # Current market odds (0-100)
        
        [Parameter(Mandatory=$true)]
        [decimal]$Bankroll,           # Total bankroll in USDC
        
        [Parameter(Mandatory=$false)]
        [decimal]$MaxBet = 50         # Max bet size (default $50)
    )
    
    # Convert to decimals
    $p = $YourProbability / 100
    $marketP = $MarketOdds / 100
    
    # Calculate implied odds
    $impliedOdds = 1 / $marketP
    
    # Calculate fair odds based on your probability
    $fairOdds = 1 / $p
    
    # Expected Value calculation
    # EV = (Probability of Win * Profit) - (Probability of Loss * Bet)
    $profit = $impliedOdds - 1
    $ev = ($p * $profit) - ((1 - $p) * 1)
    $evPct = $ev * 100
    
    # Kelly Criterion (fractional Kelly 0.25 for safety)
    $kellyFull = ($p * $impliedOdds - 1) / ($impliedOdds - 1)
    $kellyFractional = $kellyFull * 0.25
    $kellyBet = [math]::Round($Bankroll * $kellyFractional, 2)
    
    # Cap at max bet
    $recommendedBet = [math]::Min($kellyBet, $MaxBet)
    $recommendedBet = [math]::Max($recommendedBet, 0)  # No negative bets
    
    # Edge rating
    $edge = (($p / $marketP) - 1) * 100
    
    $rating = if ($edge -gt 20) { "STRONG EDGE" }
              elseif ($edge -gt 10) { "MODERATE EDGE" }
              elseif ($edge -gt 5) { "SLIGHT EDGE" }
              elseif ($edge -gt -5) { "FAIR VALUE" }
              else { "NO EDGE" }
    
    $ratingColor = if ($edge -gt 10) { "Green" }
                   elseif ($edge -gt 0) { "Yellow" }
                   else { "Red" }
    
    return [PSCustomObject]@{
        YourProbability = "$YourProbability%"
        MarketOdds = "$MarketOdds%"
        ImpliedOdds = [math]::Round($impliedOdds, 2)
        ExpectedValue = "$([math]::Round($evPct, 2))%"
        Edge = "$([math]::Round($edge, 2))%"
        Rating = $rating
        RatingColor = $ratingColor
        KellyFull = "$([math]::Round($kellyFull * 100, 2))% of bankroll"
        KellyRecommended = "$recommendedBet USDC"
        ProfitIfWin = "$([math]::Round($recommendedBet * $profit, 2)) USDC"
    }
}

# Interactive mode
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  POLYMARKET EDGE CALCULATOR" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "This calculator helps you find +EV bets.`n" -ForegroundColor Gray

$bankroll = Read-Host "Enter your total bankroll (USDC)"
if (-not [decimal]::TryParse($bankroll, [ref]$null)) {
    $bankroll = 100
    Write-Host "Invalid input. Using default: 100 USDC`n" -ForegroundColor Yellow
}

Write-Host "`nExample: Market says 70% Yes, you think it's 80% Yes = EDGE`n" -ForegroundColor DarkGray

$marketOdds = Read-Host "Current market odds (%)"
$yourProb = Read-Host "Your estimated probability (%)"

if ([decimal]::TryParse($marketOdds, [ref]$null) -and [decimal]::TryParse($yourProb, [ref]$null)) {
    $result = Calculate-Edge -YourProbability $yourProb -MarketOdds $marketOdds -Bankroll $bankroll
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "RESULTS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Your Probability:    $($result.YourProbability)" -ForegroundColor White
    Write-Host "Market Odds:       $($result.MarketOdds)" -ForegroundColor White
    Write-Host "Implied Odds:      $($result.ImpliedOdds)x" -ForegroundColor White
    Write-Host "Expected Value:    $($result.ExpectedValue)" -ForegroundColor $(if($result.ExpectedValue -match "^-"){"Red"}else{"Green"})
    Write-Host "Edge:              $($result.Edge)" -ForegroundColor $result.RatingColor
    Write-Host "Rating:            $($result.Rating)" -ForegroundColor $result.RatingColor
    Write-Host "`nKelly Criterion (Full): $($result.KellyFull)" -ForegroundColor Gray
    Write-Host "Recommended Bet:   $($result.KellyRecommended)" -ForegroundColor Cyan
    Write-Host "Profit if Win:     $($result.ProfitIfWin)" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Cyan
} else {
    Write-Host "Invalid input. Please enter numbers only." -ForegroundColor Red
}

Write-Host "Press Enter to exit..."
Read-Host
