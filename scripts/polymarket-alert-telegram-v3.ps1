# Polymarket Telegram Alert - FIXED VERSION
# Sends formatted alerts with UTF-8 encoding

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

# Read content with UTF-8 encoding
$Content = Get-Content $AlertFile -Raw -Encoding UTF8

# Check if it's a "NO HOT BETS" message
if ($Content -match "NO HOT BETS") {
    $Message = "POLYMARKET: No hot bets found at $(Get-Date -Format 'HH:mm')."
} else {
    # Simple format - just take first 5 bets to avoid length issues
    $Lines = $Content -split "`n" | Where-Object { $_.Trim() -ne "" }
    
    $Message = "POLYMARKET HOT BETS - $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n`n"
    
    # Extract count
    if ($Lines[1] -match "Found (\d+) opportunities") {
        $Message += "Found $matches[1] opportunities`n`n"
    }
    
    # Parse bets - simplified
    $BetCount = 0
    for ($i = 2; $i -lt $Lines.Count; $i++) {
        $Line = $Lines[$i]
        
        # Category and name line
        if ($Line -match "^\[([A-Z]+)\] (.+)$") {
            $Category = $matches[1]
            $Name = $matches[2]
            
            # Clean up name - remove special chars that cause encoding issues
            $Name = $Name -replace '[^\x00-\x7F]', '?'  # Replace non-ASCII with ?
            
            $Message += "• [$Category] $Name`n"
            $BetCount++
            
            if ($BetCount -ge 5) { break }  # Limit to 5 bets
        }
        # Odds line
        elseif ($Line -match "Odds: (\d+%)") {
            $Message += "  Odds: $matches[1]`n"
        }
        # Link line
        elseif ($Line -match "^Link: (.+)$") {
            $Message += "  $matches[1]`n"
            $Message += "`n"
        }
    }
}

# Send via Telegram API with proper UTF-8
$Url = "https://api.telegram.org/bot$BotToken/sendMessage"

# Create JSON body manually to ensure UTF-8
$JsonBody = @{
    chat_id = $ChatId
    text = $Message
    parse_mode = "HTML"
    disable_web_page_preview = $true
} | ConvertTo-Json

# Convert to UTF-8 bytes
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$BodyBytes = $Utf8NoBom.GetBytes($JsonBody)

try {
    $Response = Invoke-RestMethod -Uri $Url -Method POST -ContentType "application/json; charset=utf-8" -Body $BodyBytes
    Write-Host "Alert sent to Telegram"
} catch {
    Write-Error "Failed to send Telegram alert: $_"
}
