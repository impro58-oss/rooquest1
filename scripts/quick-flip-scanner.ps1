# quick-flip-scanner.ps1
# Scans for quick flip opportunities on Polymarket
# Looks for: High volatility + volume spikes + price divergence

$OutputFolder = "C:\Users\impro\Documents\Polymarket-Scans"
$Timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$DateFolder = Get-Date -Format "yyyy-MM-dd"
$FullPath = "$OutputFolder\$DateFolder"

if (!(Test-Path $FullPath)) {
    New-Item -ItemType Directory -Path $FullPath -Force | Out-Null
}

$FlipFile = "$FullPath\quick-flips-$Timestamp.txt"

Write-Host "Scanning for quick flip opportunities..." -ForegroundColor Cyan

# Categories to scan
$Categories = @(
    "https://polymarket.com/predictions/trending-markets",
    "https://polymarket.com/predictions/politics",
    "https://polymarket.com/predictions/crypto",
    "https://polymarket.com/predictions/sports"
)

$QuickFlips = @()

foreach ($Category in $Categories) {
    try {
        Write-Host "  Scanning: $Category" -ForegroundColor Gray
        $Response = curl.exe -s -L "$Category" -A "Mozilla/5.0" --max-time 15 2>$null
        
        if ($Response) {
            # Look for markets with tight spreads and high volume
            # Pattern: Yes X% / No Y% with volume
            $YesPattern = 'Yes\s+(\d+)%'
            $NoPattern = 'No\s+(\d+)%'
            $VolPattern = '\$([\d.]+)([KM])\s*Vol'
            
            $YesMatches = [regex]::Matches($Response, $YesPattern)
            $NoMatches = [regex]::Matches($Response, $NoPattern)
            $VolMatches = [regex]::Matches($Response, $VolPattern)
            
            for ($i = 0; $i -lt [math]::Min($YesMatches.Count, $NoMatches.Count); $i++) {
                $YesOdds = [int]$YesMatches[$i].Groups[1].Value
                $NoOdds = [int]$NoMatches[$i].Groups[1].Value
                
                # Calculate spread
                $Spread = 100 - ($YesOdds + $NoOdds)
                
                # Get volume if available
                $VolumeNum = 0
                if ($i -lt $VolMatches.Count) {
                    $Amount = $VolMatches[$i].Groups[1].Value
                    $Unit = $VolMatches[$i].Groups[2].Value
                    $VolumeNum = [decimal]$Amount
                    if ($Unit -eq "M") { $VolumeNum *= 1000000 }
                    if ($Unit -eq "K") { $VolumeNum *= 1000 }
                }
                
                # QUICK FLIP CRITERIA:
                # 1. Tight spread (< 5%) = liquid, easy exit
                # 2. High volume (> $100K) = can get in/out
                # 3. Odds near 50% = high volatility potential
                if ($Spread -lt 5 -and $VolumeNum -gt 100000 -and $YesOdds -gt 40 -and $YesOdds -lt 60) {
                    $QuickFlips += [PSCustomObject]@{
                        Category = ($Category -split '/')[4]
                        YesOdds = $YesOdds
                        NoOdds = $NoOdds
                        Spread = $Spread
                        Volume = "$([math]::Round($VolumeNum/1000, 0))K"
                        Edge = "Tight spread ($Spread%), near 50/50, liquid"
                        Play = "Scalp volatility - enter on dip, exit on pop"
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
if ($QuickFlips.Count -gt 0) {
    "QUICK FLIP OPPORTUNITIES - $Timestamp`n" | Out-File -FilePath $FlipFile -Encoding utf8
    "Markets with tight spreads + high volume + near 50/50:`n" | Out-File -FilePath $FlipFile -Append -Encoding utf8
    
    $QuickFlips | Sort-Object Spread | ForEach-Object {
        "[$($_.Category)]" | Out-File -FilePath $FlipFile -Append -Encoding utf8
        "  Yes: $($_.YesOdds)% | No: $($_.NoOdds)% | Spread: $($_.Spread)%" | Out-File -FilePath $FlipFile -Append -Encoding utf8
        "  Volume: $($_.Volume)" | Out-File -FilePath $FlipFile -Append -Encoding utf8
        "  Strategy: $($_.Play)" | Out-File -FilePath $FlipFile -Append -Encoding utf8
        "  Edge: $($_.Edge)" | Out-File -FilePath $FlipFile -Append -Encoding utf8
        "" | Out-File -FilePath $FlipFile -Append -Encoding utf8
    }
    
    Write-Host "`nFound $($QuickFlips.Count) quick flip opportunities!" -ForegroundColor Green
    $QuickFlips | Format-Table -AutoSize
} else {
    Write-Host "`nNo quick flip opportunities found." -ForegroundColor Yellow
    "No quick flips found at $Timestamp" | Out-File -FilePath $FlipFile -Encoding utf8
}

# Log
"$Timestamp - Quick flips: $($QuickFlips.Count)" | Out-File -FilePath "$OutputFolder\quick-flip-log.txt" -Append -Encoding utf8

Write-Host "Done! Saved to $FlipFile" -ForegroundColor Green
