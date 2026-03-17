# contrarian-scanner.ps1
# Finds contrarian value plays on Polymarket
# Looks for: High crowd bias (>70%) + still value in underdog
# Works for small bets ($50) - doesn't move the line

$OutputFolder = "C:\Users\impro\Documents\Polymarket-Scans"
$Timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$DateFolder = Get-Date -Format "yyyy-MM-dd"
$FullPath = "$OutputFolder\$DateFolder"

if (!(Test-Path $FullPath)) {
    New-Item -ItemType Directory -Path $FullPath -Force | Out-Null
}

$ContrarianFile = "$FullPath\contrarian-plays-$Timestamp.txt"

Write-Host "Scanning for contrarian value plays..." -ForegroundColor Cyan

# Categories to scan
$Categories = @(
    "https://polymarket.com/predictions/trending-markets",
    "https://polymarket.com/predictions/politics",
    "https://polymarket.com/predictions/crypto",
    "https://polymarket.com/predictions/sports",
    "https://polymarket.com/predictions/finance",
    "https://polymarket.com/predictions/entertainment"
)

$ContrarianPlays = @()

foreach ($Category in $Categories) {
    try {
        Write-Host "  Scanning: $Category" -ForegroundColor Gray
        $Response = curl.exe -s -L "$Category" -A "Mozilla/5.0" --max-time 15 2>$null
        
        if ($Response) {
            # Pattern: "Yes 85%" or "No 15%" with volume
            $Pattern = '(Yes|No)\s+(\d+)%[^$]*\$([\d.]+)([KM])\s*Vol'
            $Matches = [regex]::Matches($Response, $Pattern)
            
            foreach ($Match in $Matches) {
                $Outcome = $Matches.Groups[1].Value
                $Odds = [int]$Matches.Groups[2].Value
                $Amount = $Matches.Groups[3].Value
                $Unit = $Matches.Groups[4].Value
                
                $VolumeNum = [decimal]$Amount
                if ($Unit -eq "M") { $VolumeNum *= 1000000 }
                if ($Unit -eq "K") { $VolumeNum *= 1000 }
                
                # CONTRARIAN CRITERIA:
                # 1. High crowd bias (>75% on one side)
                # 2. Decent volume (>$50K) = liquid enough
                # 3. Underdog has >15% chance (not impossible)
                if ($VolumeNum -gt 50000 -and $Odds -ge 75 -and $Odds -le 90) {
                    $ImpliedProbability = $Odds / 100
                    $FairOdds = 1 / $ImpliedProbability
                    $Edge = (1 / (1 - $ImpliedProbability)) - 1
                    
                    $ContrarianPlays += [PSCustomObject]@{
                        Category = ($Category -split '/')[4]
                        CrowdFavorite = "$Outcome at $Odds%"
                        UnderdogOdds = (100 - $Odds)
                        Volume = "$Amount$Unit"
                        Edge = [math]::Round($Edge, 2)
                        Play = "Bet AGAINST: $Outcome (crowd is $Odds% confident)"
                        Rationale = "Crowd overconfident. If underdog wins, $50 → $([math]::Round(50 * (100-$Odds)/$Odds, 2))"
                    }
                }
            }
        }
        Start-Sleep -Milliseconds 500
    } catch {
        Write-Host "    Error: $_" -ForegroundColor Red
    }
}

# Save results
if ($ContrarianPlays.Count -gt 0) {
    "CONTRARIAN VALUE PLAYS - $Timestamp`n" | Out-File -FilePath $ContrarianFile -Encoding utf8
    "Found $($ContrarianPlays.Count) opportunities where crowd is overconfident:`n" | Out-File -FilePath $ContrarianFile -Append -Encoding utf8
    
    $ContrarianPlays | Sort-Object Edge -Descending | ForEach-Object {
        "[$($_.Category)]" | Out-File -FilePath $ContrarianFile -Append -Encoding utf8
        "  Play: $($_.Play)" | Out-File -FilePath $ContrarianFile -Append -Encoding utf8
        "  Volume: $($_.Volume) | Edge: $($_.Edge)x" | Out-File -FilePath $ContrarianFile -Append -Encoding utf8
        "  $($_)" | Out-File -FilePath $ContrarianFile -Append -Encoding utf8
        "" | Out-File -FilePath $ContrarianFile -Append -Encoding utf8
    }
    
    Write-Host "`nFound $($ContrarianPlays.Count) contrarian plays!" -ForegroundColor Green
    $ContrarianPlays | Format-Table -AutoSize
} else {
    Write-Host "`nNo contrarian opportunities found." -ForegroundColor Yellow
    "No contrarian plays found at $Timestamp" | Out-File -FilePath $ContrarianFile -Encoding utf8
}

# Log
"$Timestamp - Contrarian plays: $($ContrarianPlays.Count)" | Out-File -FilePath "$OutputFolder\contrarian-log.txt" -Append -Encoding utf8

Write-Host "Done! Saved to $ContrarianFile" -ForegroundColor Green
