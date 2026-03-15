# Setup scheduled task for automated crypto scanning
param(
    [string]$WorkingDir = "C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2",
    [string]$PythonPath = "C:\Users\impro\AppData\Local\Programs\Python\Python311\python.exe"
)

# Create logs directory
New-Item -ItemType Directory -Force -Path "$WorkingDir\logs" | Out-Null

# Task name
$TaskName = "TrojanLogic4H Auto Scanner"

# Check if task exists
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($ExistingTask) {
    Write-Host "Task already exists. Removing old version..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create action
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$WorkingDir\auto_crypto_scanner.ps1`" -WorkingDir `"$WorkingDir`" -PythonPath `"$PythonPath`""

# Create trigger (every 4 hours)
$Trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).Date `
    -RepetitionInterval (New-TimeSpan -Hours 4) `
    -RepetitionDuration (New-TimeSpan -Days 365)

# Create settings
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

# Register task
Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Description "Automated crypto scanning with TrojanLogic4H - runs every 4 hours"

Write-Host ""
Write-Host "=== TASK CREATED ==="
Write-Host "Name: $TaskName"
Write-Host "Schedule: Every 4 hours"
Write-Host "Logs: $WorkingDir\logs\"
Write-Host ""
Write-Host "To run manually:"
Write-Host "  Start-ScheduledTask -TaskName '$TaskName'"
Write-Host ""
Write-Host "To disable:"
Write-Host "  Disable-ScheduledTask -TaskName '$TaskName'"
Write-Host ""
Write-Host "To remove:"
Write-Host "  Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
