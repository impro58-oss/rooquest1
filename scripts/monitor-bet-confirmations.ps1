# monitor-bet-confirmations.ps1
# Monitors Notion for user-confirmed bets and sends follow-up alerts
# Runs every 15 minutes via scheduled task

$NOTION_KEY = Get-Content "$env:USERPROFILE\.config\notion\api_key" -ErrorAction SilentlyContinue
$BotToken = "8758242941:AAFga397u6IC3BqT-n866h2cd_XB1xJYQsw"
$ChatId = "-5026664389"
$DatabaseId = "32304917-58dd-81f2-ad8a-c8254af3d9a9"

if (!$NOTION_KEY) { exit }

$Headers = @{
    "Authorization" = "Bearer $NOTION_KEY"
    "Notion-Version" = "2022-06-28"
    "Content-Type" = "application/json"
}

# Query for confirmed but not yet taken bets
$QueryBody = @{
    filter = @{
        and = @(
            @{ property = "User Confirmed"; checkbox = $true }
            @{ property = "Bet Taken"; checkbox = $false }
        )
    }
} | ConvertTo-Json -Depth 5

try {
    $Results = Invoke-RestMethod -Uri "https://api.notion.com/v1/databases/$DatabaseId/query" -Method POST -Headers $Headers -Body $QueryBody
    
    if ($Results.results.Count -gt 0) {
        $Message = "AWAITING YOUR ACTION`n`n"
        $Message += "You confirmed these bets but haven't logged them as taken:`n`n"
        
        $i = 1
        foreach ($Page in $Results.results) {
            $Name = $Page.properties.Name.title[0].text.content
            $RecBet = $Page.properties["Recommended Bet"].number
            $Edge = $Page.properties["Estimated Edge"].number
            
            $Message += "$i. $Name`n"
            $Message += "   Rec: `$$RecBet | Edge: $Edge%`n"
            $Message += "   Go bet now, then update Notion!`n`n"
            $i++
        }
        
        $Message += "Place bets on Polymarket, then check 'Bet Taken' in Notion."
        
        $Url = "https://api.telegram.org/bot$BotToken/sendMessage"
        $Body = @{
            chat_id = $ChatId
            text = $Message
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri $Url -Method POST -ContentType "application/json" -Body $Body | Out-Null
        Write-Host "Reminder sent for $($Results.results.Count) pending bets"
    }
} catch {
    Write-Host "Error checking confirmations: $_"
}

# Query for taken bets that need risk monitoring
$TakenQuery = @{
    filter = @{
        and = @(
            @{ property = "Bet Taken"; checkbox = $true }
            @{ property = "Status"; select = @{ equals = "ACTIVE" } }
        )
    }
} | ConvertTo-Json -Depth 5

try {
    $ActiveBets = Invoke-RestMethod -Uri "https://api.notion.com/v1/databases/$DatabaseId/query" -Method POST -Headers $Headers -Body $TakenQuery
    
    if ($ActiveBets.results.Count -gt 0) {
        # Run position analyzer and send risk alerts if needed
        # (Integration point for future)
        Write-Host "$($ActiveBets.results.Count) active bets being monitored"
    }
} catch {
    Write-Host "Error checking active bets: $_"
}
