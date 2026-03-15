# Smart Money Telegram Alert
# Sends alerts when significant odds movements detected

param(
    [Parameter(Mandatory=$true)]
    [string]$AlertFile
)

$BotToken = "8758242941:AAFga397u6IC3BqT-n866h2cd_XB1xJYQsw"
$ChatId = "-5026664389"

if (!(Test-Path $AlertFile)) {
    Write-Host "No alert file to send"
    exit 0
}

$Data = Get-Content $AlertFile -Raw | ConvertFrom-Json
$Alerts = $Data.smart_money_alerts

if ($Alerts.Count -eq 0) {
    Write-Host "No smart money alerts to send"
    exit 0
}

# Build message
$Message = "🚨 SMART MONEY DETECTED - $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n`n"
$Message += "Markets with significant odds movement:`n`n"

$Count = 0
foreach ($Alert in $Alerts | Sort-Object MovementPercent -Descending | Select-Object -First 5) {
    $Emoji = if ($Alert.Confidence -eq "HIGH") { "🔥" } elseif ($Alert.Confidence -eq "MEDIUM") { "⚡" } else { "📊" }
    
    $Message += "$Emoji [$($Alert.Confidence)] $($Alert.Market)`n"
    $Message += "   Odds: $($Alert.PreviousOdds)% → $($Alert.CurrentOdds)%`n"
    $Message += "   Move: $($Alert.Direction) $($Alert.MovementPercent)%`n"
    $Message += "   Cat: $($Alert.Category)`n"
    $Message += "   [View Market]($($Alert.Url))`n`n"
    
    $Count++
    if ($Count -ge 5) { break }
}

$Message += "---`n"
$Message += "Total movements detected: $($Data.markets_with_movement)`n"
$Message += "Smart money alerts: $($Data.smart_money_alerts)`n"
$Message += "Full data: GitHub dashboard"

# Send to Telegram
$Url = "https://api.telegram.org/bot$BotToken/sendMessage"
$Body = @{
    chat_id = $ChatId
    text = $Message
    parse_mode = "Markdown"
    disable_web_page_preview = $true
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri $Url -Method POST -ContentType "application/json" -Body $Body
    Write-Host "Smart Money alert sent to Telegram"
} catch {
    Write-Error "Failed to send alert: $_"
}
