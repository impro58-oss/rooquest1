# Polymarket Telegram Alert - V6 WITH MOBILE HTML LINK
# Shows bet recommendation and mobile-friendly HTML link

param(
    [Parameter(Mandatory=$true)]
    [string]$AlertFile,
    
    [Parameter(Mandatory=$true)]
    [string]$HtmlUrl
)

$BotToken = "8758242941:AAFga397u6IC3BqT-n866h2cd_XB1xJYQsw"
$ChatId = "-5026664389"

if (!(Test-Path $AlertFile)) {
    Write-Error "Alert file not found: $AlertFile"
    exit 1
}

# Read content
$Content = Get-Content $AlertFile -Raw

# Check if no hot bets
if ($Content -match "NO HOT BETS") {
    $Message = "POLYMARKET: No hot bets found at $(Get-Date -Format 'HH:mm')."
} else {
    # Start message
    $Message = "POLYMARKET HOT BETS - $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n`n"
    
    # Extract count from line 2
    $Lines = $Content -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
    
    if ($Lines[1] -match "Found (\d+) opportunities") {
        $Count = $Matches[1]
        $Message += "Found $Count opportunities (showing top 5)`n`n"
    }
    
    # Parse bets
    $BetCount = 0
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        
        # Look for category line: [CATEGORY] Name
        if ($Line -match '^\[([A-Z]+)\]\s+(.+)$') {
            $Category = $Matches[1]
            $Name = $Matches[2]
            
            # Clean special characters
            $Name = $Name -replace '[^\x00-\x7F]', ''
            $Name = $Name -replace '\s+', ' '
            $Name = $Name.Trim()
            
            # Add to message
            $Message += "- [$Category] $Name`n"
            $BetCount++
            
            if ($BetCount -ge 5) { break }
        }
        # Look for odds line
        elseif ($Line -match 'Odds:\s+(\d+%)') {
            $Odds = $Matches[1]
            $OddsNum = [int]($Odds -replace '%','')
            
            # Recommendation based on odds
            $Rec = ""
            if ($OddsNum -lt 40) { $Rec = "UNDERDOG (high upside)" }
            elseif ($OddsNum -gt 60) { $Rec = "FAVORITE (likely but low return)" }
            else { $Rec = "CLOSE CALL (research needed)" }
            
            $Message += "  Odds: $Odds - $Rec`n"
        }
        # Look for link line
        elseif ($Line -match '^Link:\s+(.+)$') {
            $Link = $Matches[1]
            $Message += "  $Link`n`n"
        }
    }
    
    # Add mobile-friendly HTML link
    $Message += "---`n"
    $Message += "📱 View ALL $Count opportunities (mobile-friendly):`n"
    $Message += "$HtmlUrl`n`n"
    $Message += "Tap link to view full list with filters"
}

# Send to Telegram
$Url = "https://api.telegram.org/bot$BotToken/sendMessage"

$Body = @{
    chat_id = $ChatId
    text = $Message
    disable_web_page_preview = $true
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri $Url -Method POST -ContentType "application/json" -Body $Body
    Write-Host "Alert sent to Telegram"
} catch {
    Write-Error "Failed to send Telegram alert: $_"
}
