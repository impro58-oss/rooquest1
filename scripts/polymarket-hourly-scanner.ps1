# polymarket-hourly-scanner.ps1
# Hourly scan of Polymarket for trending markets and hot bets

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

Write-Host "Scanning Polymarket at $Timestamp..."

# Categories to scan
$Categories = @(
    "https://polymarket.com/predictions/trending-markets",
    "https://polymarket.com/predictions/politics",
    "https://polymarket.com/predictions/crypto",
    "https://polymarket.com/predictions/sports",
    "https://polymarket.com/predictions/finance",
    "https://polymarket.com/predictions/entertainment"
)

$AllMarkets = @()
$HotBets = @()

foreach ($Category in $Categories) {
    try {
        Write-Host "  Scanning: $Category"
        $Response = curl.exe -s -L "$Category" -A "Mozilla/5.0" --max-time 15 2>$null
        
        if ($Response) {
            # Extract market links
            $Matches = [regex]::Matches($Response, 'href="(/event/[^"]+)"[^\u003e]*\u003e([^\u003c]+)\u003c/a\u003e')
            
            foreach ($Match in $Matches) {
                $MarketUrl = "https://polymarket.com" + $Match.Groups[1].Value
                $MarketName = $Match.Groups[2].Value.Trim()
                
                if ($MarketName -and ($AllMarkets.Url -notcontains $MarketUrl)) {
                    $AllMarkets += [PSCustomObject]@{
                        Name = $MarketName
                        Url = $MarketUrl
                        Category = ($Category -split '/')[4]
                    }
                }
            }
            
            # Look for high volume
            $VolumeMatches = [regex]::Matches($Response, '(\d+%)[^$]*\$([\d.]+)([KM]) Vol')
            
            foreach ($VolMatch in $VolumeMatches) {
                $Odds = $VolMatch.Groups[1].Value
                $Amount = $VolMatch.Groups[2].Value
                $Unit = $VolMatch.Groups[3].Value
                
                $VolumeNum = [decimal]$Amount
                if ($Unit -eq "M") { $VolumeNum *= 1000000 }
                if ($Unit -eq "K") { $VolumeNum *= 1000 }
                
                if ($VolumeNum -gt 100000 -and $Odds -match "^[2-7]") {
                    $HotBets += [PSCustomObject]@{
                        Odds = $Odds
                        Volume = "$Amount$Unit"
                        Category = ($Category -split '/')[4]
                    }
                }
            }
        }
        
        Start-Sleep -Milliseconds 500
        
    } catch {
        Write-Host "    Error: $_"
    }
}

# Save links
$Header = "POLYMARKET SCAN - $Timestamp`nTotal Markets: $($AllMarkets.Count)`n`n"
$Header | Out-File -FilePath $LinksFile -Encoding utf8

foreach ($Market in $AllMarkets | Sort-Object Category, Name) {
    "[$($Market.Category)] $($Market.Name)" | Out-File -FilePath $LinksFile -Append -Encoding utf8
    "$($Market.Url)" | Out-File -FilePath $LinksFile -Append -Encoding utf8
    "" | Out-File -FilePath $LinksFile -Append -Encoding utf8
}

Write-Host "  Saved $($AllMarkets.Count) links"

# Save hot bets
if ($HotBets.Count -gt 0) {
    "HOT BETS - $Timestamp`n`n" | Out-File -FilePath $AlertFile -Encoding utf8
    
    foreach ($Bet in $HotBets | Sort-Object Volume -Descending | Select-Object -First 10) {
        "[$($Bet.Category)] Odds: $($Bet.Odds) | Volume: $($Bet.Volume)" | Out-File -FilePath $AlertFile -Append -Encoding utf8
    }
    
    Write-Host "  Found $($HotBets.Count) hot bets!"
    $HotBets
} else {
    Write-Host "  No hot bets found"
    $null
}

# Log
"$Timestamp - Markets: $($AllMarkets.Count), Hot: $($HotBets.Count)" | Out-File -FilePath "$OutputFolder\scan-log.txt" -Append -Encoding utf8

Write-Host "Done!"
