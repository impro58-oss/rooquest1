# polymarket-alert-telegram.ps1
# Send Telegram alert for hot Polymarket bets
# Called by hourly scanner when hot bets found

param(
    [Parameter(Mandatory=$true)]
    [string]$AlertFile
)

$BotToken = "YOUR_BOT_TOKEN"  # Will be replaced by OpenClaw
$ChatId = "1018254667"

if (!(Test-Path $AlertFile)) {
    Write-Error "Alert file not found: $AlertFile"
    exit 1
}

$Content = Get-Content $AlertFile -Raw

# Format for Telegram
$Message = @"
🔥 POLYMARKET HOT BETS ALERT

$Content

Check full links in Documents/Polymarket-Scans/
"@

# Send via Telegram API
$Url = "https://api.telegram.org/bot$BotToken/sendMessage"
$Body = @{
    chat_id = $ChatId
    text = $Message
    parse_mode = "HTML"
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri $Url -Method POST -ContentType "application/json" -Body $Body
    Write-Host "Alert sent to Telegram"
} catch {
    Write-Error "Failed to send Telegram alert: $_"
}
