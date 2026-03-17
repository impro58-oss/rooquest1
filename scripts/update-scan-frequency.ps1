# Update crypto scan frequency
# Changes from 4 hours to 3 hours (8 scans per day)

param(
    [int]$Hours = 3,
    [string]$TaskName = "TrojanLogic4H Auto Scanner"
)

Write-Host "=== UPDATING CRYPTO SCAN FREQUENCY ==="
Write-Host "Changing from 4 hours to $Hours hours"
Write-Host ""

# Remove existing task
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($ExistingTask) {
    Write-Host "Removing existing task..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "[OK] Old task removed"
}

# Create new task with updated frequency
$WorkingDir = "C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2"
$ScriptPath = "$WorkingDir\auto_crypto_scanner.ps1"

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -WorkingDir `"$WorkingDir`""

$Trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).Date `
    -RepetitionInterval (New-TimeSpan -Hours $Hours) `
    -RepetitionDuration (New-TimeSpan -Days 365)

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Description "Automated crypto scanning with TrojanLogic4H - runs every $Hours hours"

Write-Host ""
Write-Host "=== TASK UPDATED ==="
Write-Host "Name: $TaskName"
Write-Host "New Schedule: Every $Hours hours"
Write-Host "Scans per day: $([math]::Floor(24/$Hours))"
Write-Host ""
Write-Host "Next runs (UTC):"
for ($i = 0; $i -lt [math]::Floor(24/$Hours); $i++) {
    $hour = ($i * $Hours) % 24
    Write-Host "  $($hour.ToString().PadLeft(2,'0')):00"
}
Write-Host ""
Write-Host "To verify:"
Write-Host "  Get-ScheduledTask -TaskName '$TaskName' | Select-Object State, LastRunTime, NextRunTime"
