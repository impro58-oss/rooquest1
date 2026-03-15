# polymarket-alert-telegram.ps1
# Send Telegram alert for hot Polymarket bets
# Called by hourly scanner when hot bets found

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

# Format for Telegram
$Message = "POLYMARKET HOT BETS ALERT" + "`n`n" + $Content + "`n`nCheck full links in Documents/Polymarket-Scans/"

# Send via Telegram API
$Url = "https://api.telegram.org/bot$BotToken/sendMessage"
$Body = @{
    chat_id = $ChatId
    text = $Message
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri $Url -Method POST -ContentType "application/json" -Body $Body
    Write-Host "Alert sent to Telegram"
} catch {
    Write-Error "Failed to send Telegram alert: $_"
}
