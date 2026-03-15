# Polymarket Hourly Scanner - VERSION 4
# Parses JSON-LD and extracts outcome context from market names

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

# Categories to scan (ALL categories)
$Categories = @(
    @{Url="https://polymarket.com/predictions/trending-markets"; Name="trending"},
    @{Url="https://polymarket.com/predictions/politics"; Name="politics"},
    @{Url="https://polymarket.com/predictions/crypto"; Name="crypto"},
    @{Url="https://polymarket.com/predictions/sports"; Name="sports"},
    @{Url="https://polymarket.com/predictions/finance"; Name="finance"},
    @{Url="https://polymarket.com/predictions/entertainment"; Name="entertainment"}
)

function Get-OutcomeDescription {
    param([string]$MarketName, [string]$Category)
    
    $Outcome = ""
    
    # Sports matches: "Team A vs Team B"
    if ($MarketName -match "(.+?)\s+vs\.?\s+(.+?)(\s+-|$)") {
        $TeamA = $Matches[1].Trim()
        $TeamB = $Matches[2].Trim()
        
        # Check if it's a "More Markets" link (specific outcomes)
        if ($MarketName -match "More Markets") {
            $Outcome = "Various outcomes (check link)"
        } else {
            # Standard match - odds usually for Team B or specific outcome
            $Outcome = "Likely: $TeamB wins or specific outcome"
        }
    }
    # Will/Does/Is questions
    elseif ($MarketName -match "^(Will|Does|Is|Can|Are)\s+(.+)\?") {
        $Question = $Matches[2].Trim()
        $Outcome = "YES: $Question"
    }
    # By when/When questions
    elseif ($MarketName -match "(By when|When will|What will)") {
        $Outcome = "Specific date/time outcome"
    }
    # Default
    else {
        $Outcome = "Check market for outcomes"
    }
    
    return $Outcome
}

$AllMarkets = @()
$HotBets = @()

foreach ($Cat in $Categories) {
    try {
        Write-Host "  Scanning: $($Cat.Name)"
        $Response = curl.exe -s -L "$($Cat.Url)" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" --max-time 15 2>$null
        
        if ($Response) {
            # Extract JSON-LD data
            $JsonLdPattern = '<script type="application/ld\+json"[^>]*>(.*?)</script>'
            $JsonMatches = [regex]::Matches($Response, $JsonLdPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
            
            foreach ($Match in $JsonMatches) {
                try {
                    $JsonText = $Match.Groups[1].Value.Trim()
                    $Data = $JsonText | ConvertFrom-Json -ErrorAction Stop
                    
                    # Check if this is a CollectionPage with Event items
                    if ($Data.'@type' -eq "CollectionPage" -and $Data.mainEntity -and $Data.mainEntity.itemListElement) {
                        foreach ($Item in $Data.mainEntity.itemListElement) {
                            if ($Item.item -and $Item.item.'@type' -eq "Event") {
                                $Event = $Item.item
                                
                                $MarketName = $Event.name
                                $MarketUrl = $Event.url
                                $Category = $Cat.Name
                                
                                # Extract odds from offers (price is decimal, e.g., 0.76 = 76%)
                                $OddsDecimal = 0
                                if ($Event.offers -and $Event.offers.price) {
                                    $OddsDecimal = [decimal]$Event.offers.price
                                }
                                $OddsPercent = [math]::Round($OddsDecimal * 100)
                                $Odds = "$OddsPercent%"
                                
                                # Get outcome description
                                $OutcomeDesc = Get-OutcomeDescription -MarketName $MarketName -Category $Category
                                
                                # Skip if already seen
                                if ($AllMarkets.Url -contains $MarketUrl) { continue }
                                
                                $Market = [PSCustomObject]@{
                                    Name = $MarketName
                                    Url = $MarketUrl
                                    Category = $Category
                                    Odds = $Odds
                                    OddsNum = $OddsPercent
                                    Outcome = $OutcomeDesc
                                    Timestamp = $Timestamp
                                }
                                
                                $AllMarkets += $Market
                                
                                # HOT BET CRITERIA
                                if ($OddsPercent -ge 20 -and $OddsPercent -le 80) {
                                    $Edge = ""
                                    if ($OddsPercent -ge 40 -and $OddsPercent -le 60) { $Edge = "CLOSE_CALL" }
                                    elseif ($OddsPercent -lt 40) { $Edge = "UNDERDOG" }
                                    elseif ($OddsPercent -gt 60) { $Edge = "FAVORITE" }
                                    
                                    $Market | Add-Member -NotePropertyName "EdgeType" -NotePropertyValue $Edge -Force
                                    $HotBets += $Market
                                }
                            }
                        }
                    }
                } catch {
                    continue
                }
            }
        }
        
        Start-Sleep -Milliseconds 500
        
    } catch {
        Write-Host "    Error scanning $($Cat.Name): $_"
    }
}

# Save all markets to JSON
$AllMarkets | ConvertTo-Json -Depth 3 | Out-File -FilePath $JsonFile -Encoding utf8

# Save links file
$Header = "POLYMARKET SCAN - $Timestamp`nTotal Markets: $($AllMarkets.Count) | Hot Bets: $($HotBets.Count)`n`n"
$Header | Out-File -FilePath $LinksFile -Encoding utf8

foreach ($Market in $AllMarkets | Sort-Object Category, Name) {
    "[$($Market.Category.ToUpper())] $($Market.Name)" | Out-File -FilePath $LinksFile -Append -Encoding utf8
    "Odds: $($Market.Odds) | Outcome: $($Market.Outcome)" | Out-File -FilePath $LinksFile -Append -Encoding utf8
    "$($Market.Url)" | Out-File -FilePath $LinksFile -Append -Encoding utf8
    "" | Out-File -FilePath $LinksFile -Append -Encoding utf8
}

Write-Host "  Saved $($AllMarkets.Count) markets"

# Generate alert content
if ($HotBets.Count -gt 0) {
    # Sort by odds (closest to 50% first)
    $TopBets = $HotBets | Sort-Object @{Expression={[math]::Abs($_.OddsNum - 50)}} | Select-Object -First 5
    
    $AlertContent = @()
    $AlertContent += "HOT BETS - $Timestamp"
    $AlertContent += "Found $($HotBets.Count) opportunities with 20-80% odds"
    $AlertContent += ""
    
    foreach ($Bet in $TopBets) {
        $AlertContent += "---"
        $AlertContent += "[$($Bet.Category.ToUpper())] $($Bet.Name)"
        $AlertContent += "Outcome: $($Bet.Outcome)"
        $AlertContent += "Odds: $($Bet.Odds) | Type: $($Bet.EdgeType)"
        $AlertContent += "Link: $($Bet.Url)"
        $AlertContent += ""
    }
    
    $AlertContent | Out-File -FilePath $AlertFile -Encoding utf8
    
    Write-Host "  Found $($HotBets.Count) hot bets!"
    $AlertFile
} else {
    "NO HOT BETS - $Timestamp`nNo markets with 20-80% odds found." | Out-File -FilePath $AlertFile -Encoding utf8
    Write-Host "  No hot bets found"
    $null
}

# Log
"$Timestamp - Markets: $($AllMarkets.Count), Hot: $($HotBets.Count)" | Out-File -FilePath "$OutputFolder\scan-log.txt" -Append -Encoding utf8
