# Setup improved Polymarket hourly scan
# Replaces old scanner with new version that extracts bet descriptions

$TaskName = "Polymarket Hourly Scan"
$ScriptPath = "C:\Users\impro\.openclaw\workspace\scripts\polymarket-complete-hourly.ps1"

# Remove old task if exists
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($ExistingTask) {
    Write-Host "Removing old task..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create new task - runs every hour
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""

$Trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).Date `
    -RepetitionInterval (New-TimeSpan -Hours 1) `
    -RepetitionDuration (New-TimeSpan -Days 365)

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Description "Polymarket hourly scan with improved bet descriptions and Telegram alerts"

Write-Host ""
Write-Host "=== TASK CREATED ==="
Write-Host "Name: $TaskName"
Write-Host "Schedule: Every hour"
Write-Host "Script: $ScriptPath"
Write-Host ""
Write-Host "IMPROVEMENTS:"
Write-Host "  - Extracts actual bet descriptions (not just category)"
Write-Host "  - Shows market name, odds, volume, and link"
Write-Host "  - Sends 'No hot bets' one-liner when nothing found"
Write-Host "  - Filters for real opportunities (>$100K, 20-80% odds)"
Write-Host ""
Write-Host "To test manually:"
Write-Host "  & '$ScriptPath'"
