# Polymarket Telegram Alert - IMPROVED VERSION
# Sends formatted alerts with actual bet descriptions

param(
    [Parameter(Mandatory=$true)]
    [string]$AlertFile
)

$BotToken = "8758242941:AAFga397u6IC3BqT-n866h2cd_XB1xJYQsw"
$ChatId = "-5026664389"  # Poly2 group chat

if (!(Test-Path $AlertFile)) {
    Write-Error "Alert file not found: $AlertFile"
    exit 1
}

$Content = Get-Content $AlertFile -Raw

# Check if it's a "NO HOT BETS" message
if ($Content -match "NO HOT BETS") {
    # Send one-liner
    $Message = "POLYMARKET: No hot bets found at $(Get-Date -Format 'HH:mm')."
} else {
    # Format hot bets properly
    $Lines = $Content -split "`n" | Where-Object { $_.Trim() -ne "" }
    
    $Message = "POLYMARKET HOT BETS - $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n`n"
    
    # Extract the count
    if ($Lines[1] -match "Found (\d+) opportunities") {
        $Message += "Found $matches[1] opportunities`n`n"
    }
    
    # Parse each bet
    $InBet = $false
    $CurrentBet = @{}
    
    foreach ($Line in $Lines) {
        if ($Line -match "^\[([A-Z]+)\] (.+)$") {
            # New bet category and name
            if ($CurrentBet.Count -gt 0) {
                # Output previous bet
                $Message += "• [$($CurrentBet.Category)] $($CurrentBet.Name)`n"
                $Message += "  Odds: $($CurrentBet.Odds) | Vol: $($CurrentBet.Volume)`n"
                if ($CurrentBet.Link) {
                    $Message += "  $($CurrentBet.Link)`n"
                }
                $Message += "`n"
            }
            
            $CurrentBet = @{
                Category = $matches[1]
                Name = $matches[2]
            }
            $InBet = $true
        }
        elseif ($Line -match "Odds: (\d+%) \| Volume: ([\d.KM]+)(?: \| Type: ([A-Z_]+))?") {
            $CurrentBet.Odds = $matches[1]
            $CurrentBet.Volume = $matches[2]
            $CurrentBet.Type = $matches[3]
        }
        elseif ($Line -match "^Link: (.+)$") {
            $CurrentBet.Link = $matches[1]
        }
    }
    
    # Output last bet
    if ($CurrentBet.Count -gt 0) {
        $Message += "• [$($CurrentBet.Category)] $($CurrentBet.Name)`n"
        $Message += "  Odds: $($CurrentBet.Odds) | Vol: $($CurrentBet.Volume)`n"
        if ($CurrentBet.Link) {
            $Message += "  $($CurrentBet.Link)`n"
        }
    }
}

# Send via Telegram API
$Url = "https://api.telegram.org/bot$BotToken/sendMessage"
$Body = @{
    chat_id = $ChatId
    text = $Message
    parse_mode = "HTML"
    disable_web_page_preview = $true
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri $Url -Method POST -ContentType "application/json" -Body $Body
    Write-Host "Alert sent to Telegram"
} catch {
    Write-Error "Failed to send Telegram alert: $_"
}
