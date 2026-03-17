# Polymarket Hourly Scanner - IMPROVED VERSION
# Extracts actual bet descriptions and filters for real opportunities

$OutputFolder = "C:\Users\impro\Documents\Polymarket-Scans"
$Timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$DateFolder = Get-Date -Format "yyyy-MM-dd"
$FullPath = "$OutputFolder\$DateFolder"

# Create folders
if (!(Test-Path $FullPath)) {
    New-Item -ItemType Directory -Path $FullPath -Force | Out-Null
}

$LinksFile = "$FullPath\polymarket-links-$Timestamp.txt"
$AlertFile = "$FullPath\hot-bets-$Timestamp.txt"
$JsonFile = "$FullPath\markets-$Timestamp.json"

Write-Host "Scanning Polymarket at $Timestamp..."

# Categories to scan
$Categories = @(
    @{Url="https://polymarket.com/predictions/trending-markets"; Name="trending"},
    @{Url="https://polymarket.com/predictions/politics"; Name="politics"},
    @{Url="https://polymarket.com/predictions/crypto"; Name="crypto"},
    @{Url="https://polymarket.com/predictions/sports"; Name="sports"},
    @{Url="https://polymarket.com/predictions/finance"; Name="finance"},
    @{Url="https://polymarket.com/predictions/entertainment"; Name="entertainment"}
)

$AllMarkets = @()
$HotBets = @()

foreach ($Cat in $Categories) {
    try {
        Write-Host "  Scanning: $($Cat.Name)"
        $Response = curl.exe -s -L "$($Cat.Url)" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" --max-time 15 2>$null
        
        if ($Response) {
            # Extract market cards with full details
            # Pattern: Market title, odds, volume, and link
            $MarketPattern = 'data-testid="market-card".*?<a[^>]*href="(/event/[^"]+)"[^>]*>.*?<h[1-6][^>]*>([^<]+)</h[1-6]>.*?<span[^>]*>(\d+%)</span>.*?\$([\d.]+)([KM]) Vol'
            
            $Matches = [regex]::Matches($Response, $MarketPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
            
            foreach ($Match in $Matches) {
                $MarketUrl = "https://polymarket.com" + $Match.Groups[1].Value
                $MarketName = $Match.Groups[2].Value.Trim() -replace '\s+', ' '
                $Odds = $Match.Groups[3].Value
                $Amount = $Match.Groups[4].Value
                $Unit = $Match.Groups[5].Value
                
                # Calculate actual volume
                $VolumeNum = [decimal]$Amount
                if ($Unit -eq "M") { $VolumeNum *= 1000000 }
                if ($Unit -eq "K") { $VolumeNum *= 1000 }
                
                # Skip if already seen
                if ($AllMarkets.Url -contains $MarketUrl) { continue }
                
                $Market = [PSCustomObject]@{
                    Name = $MarketName
                    Url = $MarketUrl
                    Category = $Cat.Name
                    Odds = $Odds
                    Volume = "$Amount$Unit"
                    VolumeNum = $VolumeNum
                    Timestamp = $Timestamp
                }
                
                $AllMarkets += $Market
                
                # HOT BET CRITERIA:
                # 1. Volume > $100K
                # 2. Odds between 20-80% (not too certain)
                # 3. Clear opportunity (not just noise)
                $OddsNum = [int]($Odds -replace '%','')
                if ($VolumeNum -ge 100000 -and $OddsNum -ge 20 -and $OddsNum -le 80) {
                    # Calculate edge potential
                    $Edge = ""
                    if ($OddsNum -ge 40 -and $OddsNum -le 60) { $Edge = "CLOSE_CALL" }
                    elseif ($OddsNum -lt 40) { $Edge = "UNDERDOG" }
                    elseif ($OddsNum -gt 60) { $Edge = "FAVORITE" }
                    
                    $Market | Add-Member -NotePropertyName "EdgeType" -NotePropertyValue $Edge
                    $HotBets += $Market
                }
            }
        }
        
        Start-Sleep -Milliseconds 500
        
    } catch {
        Write-Host "    Error scanning $($Cat.Name): $_"
    }
}

# Save all markets to JSON for analysis
$AllMarkets | ConvertTo-Json -Depth 3 | Out-File -FilePath $JsonFile -Encoding utf8

# Save links file
$Header = "POLYMARKET SCAN - $Timestamp`nTotal Markets: $($AllMarkets.Count) | Hot Bets: $($HotBets.Count)`n`n"
$Header | Out-File -FilePath $LinksFile -Encoding utf8

foreach ($Market in $AllMarkets | Sort-Object Category, Name) {
    "[$($Market.Category.ToUpper())] $($Market.Name)" | Out-File -FilePath $LinksFile -Append -Encoding utf8
    "Odds: $($Market.Odds) | Volume: $($Market.Volume)" | Out-File -FilePath $LinksFile -Append -Encoding utf8
    "$($Market.Url)" | Out-File -FilePath $LinksFile -Append -Encoding utf8
    "" | Out-File -FilePath $LinksFile -Append -Encoding utf8
}

Write-Host "  Saved $($AllMarkets.Count) markets"

# Generate alert content
if ($HotBets.Count -gt 0) {
    # Sort by volume, take top 5
    $TopBets = $HotBets | Sort-Object VolumeNum -Descending | Select-Object -First 5
    
    $AlertContent = @()
    $AlertContent += "HOT BETS - $Timestamp"
    $AlertContent += "Found $($HotBets.Count) opportunities with volume >$100K and odds 20-80%"
    $AlertContent += ""
    
    foreach ($Bet in $TopBets) {
        $AlertContent += "---"
        $AlertContent += "[$($Bet.Category.ToUpper())] $($Bet.Name)"
        $AlertContent += "Odds: $($Bet.Odds) | Volume: $($Bet.Volume) | Type: $($Bet.EdgeType)"
        $AlertContent += "Link: $($Bet.Url)"
        $AlertContent += ""
    }
    
    $AlertContent | Out-File -FilePath $AlertFile -Encoding utf8
    
    Write-Host "  Found $($HotBets.Count) hot bets!"
    
    # Return alert file path for Telegram
    $AlertFile
} else {
    # No hot bets - create one-liner
    "NO HOT BETS - $Timestamp`nNo markets with >$100K volume and 20-80% odds found." | Out-File -FilePath $AlertFile -Encoding utf8
    
    Write-Host "  No hot bets found"
    $null
}

# Log
"$Timestamp - Markets: $($AllMarkets.Count), Hot: $($HotBets.Count)" | Out-File -FilePath "$OutputFolder\scan-log.txt" -Append -Encoding utf8

Write-Host "Done!"
