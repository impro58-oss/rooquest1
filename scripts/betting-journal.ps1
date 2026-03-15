# betting-journal.ps1
# Track and analyze betting performance over time

$JournalFile = "$env:USERPROFILE\.openclaw\workspace\memory\betting-journal.csv"
$WalletAddress = "0x2d8c75c3fcbbFe50f92c2eDb00ab7dcF89578071"

function Show-Menu {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  BETTING JOURNAL" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    Write-Host "1. Log new bet" -ForegroundColor White
    Write-Host "2. Log bet result (win/loss)" -ForegroundColor White
    Write-Host "3. View performance stats" -ForegroundColor White
    Write-Host "4. Export to Notion" -ForegroundColor White
    Write-Host "5. Exit`n" -ForegroundColor White
}

function Log-NewBet {
    $date = Get-Date -Format "yyyy-MM-dd"
    $market = Read-Host "Market name"
    $outcome = Read-Host "Your position (Yes/No)"
    $odds = Read-Host "Entry odds (%)"
    $betSize = Read-Host "Bet size (USDC)"
    $edge = Read-Host "Estimated edge (%)"
    $notes = Read-Host "Notes (optional)"
    
    $entry = "$date,$market,$outcome,$odds,$betSize,$edge,OPEN,,,$notes"
    
    if (!(Test-Path $JournalFile)) {
        "Date,Market,Outcome,EntryOdds,BetSize,Edge,Status,ExitOdds,PnL,Notes" | Out-File $JournalFile -Encoding utf8
    }
    
    $entry | Out-File $JournalFile -Append -Encoding utf8
    Write-Host "`nBet logged!`n" -ForegroundColor Green
}

function Log-Result {
    if (!(Test-Path $JournalFile)) {
        Write-Host "`nNo journal found. Log some bets first.`n" -ForegroundColor Yellow
        return
    }
    
    $bets = Import-Csv $JournalFile | Where-Object { $_.Status -eq "OPEN" }
    
    if ($bets.Count -eq 0) {
        Write-Host "`nNo open bets found.`n" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`nOpen bets:" -ForegroundColor Cyan
    $i = 1
    $bets | ForEach-Object {
        Write-Host "$i. $($_.Market) - $($_.Outcome) @ $($_.EntryOdds)%" -ForegroundColor White
        $i++
    }
    
    $selection = Read-Host "`nSelect bet number"
    if ([int]::TryParse($selection, [ref]$null) -and [int]$selection -le $bets.Count) {
        $selected = $bets[[int]$selection - 1]
        $exitOdds = Read-Host "Exit odds (%) or final result"
        $status = Read-Host "Result (WIN/LOSS/PARTIAL)"
        
        # Calculate P&L
        $entryP = [decimal]$selected.EntryOdds / 100
        $bet = [decimal]$selected.BetSize
        
        if ($status -eq "WIN") {
            $pnl = $bet * ((1 / $entryP) - 1)
        } elseif ($status -eq "LOSS") {
            $pnl = -$bet
        } else {
            $pnl = Read-Host "P&L amount (USDC)"
        }
        
        # Update CSV
        $csv = Import-Csv $JournalFile
        $csv | ForEach-Object {
            if ($_.Market -eq $selected.Market -and $_.Status -eq "OPEN") {
                $_.Status = $status
                $_.ExitOdds = $exitOdds
                $_.PnL = $pnl
            }
        }
        $csv | Export-Csv $JournalFile -NoTypeInformation -Encoding utf8
        
        Write-Host "`nResult logged! P&L: $([math]::Round($pnl, 2)) USDC`n" -ForegroundColor $(if($pnl -gt 0){"Green"}else{"Red"})
    }
}

function Show-Stats {
    if (!(Test-Path $JournalFile)) {
        Write-Host "`nNo journal found.`n" -ForegroundColor Yellow
        return
    }
    
    $bets = Import-Csv $JournalFile | Where-Object { $_.Status -ne "OPEN" }
    
    if ($bets.Count -eq 0) {
        Write-Host "`nNo completed bets yet.`n" -ForegroundColor Yellow
        return
    }
    
    $totalBets = $bets.Count
    $wins = ($bets | Where-Object { $_.Status -eq "WIN" }).Count
    $losses = ($bets | Where-Object { $_.Status -eq "LOSS" }).Count
    $winRate = if ($totalBets -gt 0) { ($wins / $totalBets) * 100 } else { 0 }
    
    $totalPnL = ($bets | Measure-Object -Property PnL -Sum).Sum
    $avgPnL = $totalPnL / $totalBets
    
    $totalBet = ($bets | Measure-Object -Property BetSize -Sum).Sum
    $roi = if ($totalBet -gt 0) { ($totalPnL / $totalBet) * 100 } else { 0 }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  PERFORMANCE STATS" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Total Bets:     $totalBets" -ForegroundColor White
    Write-Host "Wins:           $wins" -ForegroundColor Green
    Write-Host "Losses:         $losses" -ForegroundColor Red
    Write-Host "Win Rate:       $([math]::Round($winRate, 2))%" -ForegroundColor $(if($winRate -gt 50){"Green"}else{"Yellow"})
    Write-Host "`nTotal P&L:      $([math]::Round($totalPnL, 2)) USDC" -ForegroundColor $(if($totalPnL -gt 0){"Green"}else{"Red"})
    Write-Host "Avg P&L/Bet:    $([math]::Round($avgPnL, 2)) USDC" -ForegroundColor White
    Write-Host "Total Wagered:  $([math]::Round($totalBet, 2)) USDC" -ForegroundColor White
    Write-Host "ROI:            $([math]::Round($roi, 2))%" -ForegroundColor $(if($roi -gt 0){"Green"}else{"Red"})
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    # Best and worst
    $best = $bets | Sort-Object PnL -Descending | Select-Object -First 1
    $worst = $bets | Sort-Object PnL | Select-Object -First 1
    
    Write-Host "Best Trade:  $($best.Market) - $([math]::Round($best.PnL, 2)) USDC" -ForegroundColor Green
    Write-Host "Worst Trade: $($worst.Market) - $([math]::Round($worst.PnL, 2)) USDC`n" -ForegroundColor Red
}

# Main loop
$running = $true
while ($running) {
    Show-Menu
    $choice = Read-Host "Select option"
    
    switch ($choice) {
        "1" { Log-NewBet }
        "2" { Log-Result }
        "3" { Show-Stats }
        "4" { Write-Host "`nNotion export coming soon...`n" -ForegroundColor Yellow }
        "5" { $running = $false }
        default { Write-Host "`nInvalid option`n" -ForegroundColor Red }
    }
}

Write-Host "`nGood luck!`n" -ForegroundColor Green
