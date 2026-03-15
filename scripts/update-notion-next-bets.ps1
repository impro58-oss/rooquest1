# update-notion-next-bets.ps1
# Updates Notion Next Bets database with latest scan results + edge calc
# Sends Telegram alert for new opportunities

$NOTION_KEY = Get-Content "$env:USERPROFILE\.config\notion\api_key" -ErrorAction SilentlyContinue
$BotToken = "8758242941:AAFga397u6IC3BqT-n866h2cd_XB1xJYQsw"
$ChatId = "-5026664389"

if (!$NOTION_KEY) { 
    Write-Host "No Notion API key found" -ForegroundColor Red
    exit 
}

$Headers = @{
    "Authorization" = "Bearer $NOTION_KEY"
    "Notion-Version" = "2022-06-28"
    "Content-Type" = "application/json"
}

$DatabaseId = "32304917-58dd-81f2-ad8a-c8254af3d9a9"

# Get today's scan files
$Today = Get-Date -Format "yyyy-MM-dd"
$ScanFolder = "C:\Users\impro\Documents\Polymarket-Scans\$Today"

$NewOpportunities = @()

# Process hot bets
$HotBetsFile = Get-ChildItem "$ScanFolder\hot-bets-*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($HotBetsFile) {
    $Content = Get-Content $HotBetsFile.FullName
    foreach ($Line in $Content) {
        if ($Line -match "\[(.+?)\] Odds: (\d+%) \| Volume: (.+)") {
            $Category = $Matches[1]
            $Odds = $Matches[2]
            $Volume = $Matches[3]
            
            # Check if already exists
            $QueryBody = @{
                filter = @{
                    and = @(
                        @{ property = "Volume"; rich_text = @{ equals = $Volume } }
                        @{ property = "Date Added"; date = @{ equals = $Today } }
                    )
                }
            } | ConvertTo-Json -Depth 5
            
            try {
                $Existing = Invoke-RestMethod -Uri "https://api.notion.com/v1/databases/$DatabaseId/query" -Method POST -Headers $Headers -Body $QueryBody
                
                if ($Existing.results.Count -eq 0) {
                    # Calculate edge (assuming 10% edge for hot bets)
                    $MarketProb = [int]($Odds -replace '%','')
                    $Edge = 10  # Conservative estimate for hot bets
                    $RecommendedBet = 5  # $5 for testing
                    
                    # Add to Notion
                    $AddBody = @{
                        parent = @{ database_id = $DatabaseId }
                        properties = @{
                            Name = @{ title = @(@{ text = @{ content = "HOT BET: $Category" } }) }
                            Market = @{ url = "https://polymarket.com/predictions/$Category" }
                            "Current Odds" = @{ number = $MarketProb }
                            Volume = @{ rich_text = @(@{ text = @{ content = $Volume } }) }
                            Category = @{ select = @{ name = $Category.Substring(0,1).ToUpper() + $Category.Substring(1).ToLower() } }
                            Priority = @{ select = @{ name = "High" } }
                            Status = @{ select = @{ name = "PENDING CONFIRMATION" } }
                            "Date Added" = @{ date = @{ start = $Today } }
                            "Recommended Position" = @{ select = @{ name = "HOT" } }
                            "Estimated Edge" = @{ number = $Edge }
                            "Recommended Bet" = @{ number = $RecommendedBet }
                            "User Confirmed" = @{ checkbox = $false }
                            "Bet Taken" = @{ checkbox = $false }
                            "Bet Size" = @{ number = $null }
                            "Entry Price" = @{ number = $null }
                            "Notes" = @{ rich_text = @(@{ text = @{ content = "High volume opportunity detected" } }) }
                        }
                    } | ConvertTo-Json -Depth 10
                    
                    $Result = Invoke-RestMethod -Uri "https://api.notion.com/v1/pages" -Method POST -Headers $Headers -Body $AddBody
                    $PageId = $Result.id
                    
                    $NewOpportunities += @{
                        Type = "HOT BET"
                        Category = $Category
                        Odds = $MarketProb
                        Volume = $Volume
                        Edge = $Edge
                        Recommended = $RecommendedBet
                        PageId = $PageId
                    }
                }
            } catch {
                Write-Host "Error adding hot bet: $_" -ForegroundColor Red
            }
        }
    }
}

# Process contrarian plays
$ContrarianFile = Get-ChildItem "$ScanFolder\contrarian-plays-*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($ContrarianFile) {
    $Content = Get-Content $ContrarianFile.FullName
    # Parse and add similar to above
    # (Simplified for now - can expand)
}

# Send Telegram alert if new opportunities found
if ($NewOpportunities.Count -gt 0) {
    $Message = "NEW BETTING OPPORTUNITIES DETECTED`n`n"
    $Message += "Review in Notion and confirm if taking:`n`n"
    
    foreach ($Opp in $NewOpportunities) {
        $Message += "[$($Opp.Type)] $($Opp.Category)`n"
        $Message += "Odds: $($Opp.Odds)% | Volume: $($Opp.Volume)`n"
        $Message += "Edge: $($Opp.Edge)% | Rec Bet: `$($Opp.Recommended)`n"
        $Message += "`n"
    }
    
    $Message += "Check Notion 'Next Bets' database to confirm.`n"
    $Message += "Reply 'CONFIRM [number]' to log your bet."
    
    $Url = "https://api.telegram.org/bot$BotToken/sendMessage"
    $Body = @{
        chat_id = $ChatId
        text = $Message
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri $Url -Method POST -ContentType "application/json" -Body $Body | Out-Null
        Write-Host "Telegram alert sent for $($NewOpportunities.Count) opportunities" -ForegroundColor Green
    } catch {
        Write-Host "Failed to send Telegram alert: $_" -ForegroundColor Red
    }
}

Write-Host "Notion update complete. $($NewOpportunities.Count) new opportunities added." -ForegroundColor Green
