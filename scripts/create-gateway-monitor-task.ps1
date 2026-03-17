# create-gateway-monitor-task.ps1
# Creates a scheduled task to monitor gateway every 5 minutes

$TaskName = "OpenClaw Gateway Monitor"
$ScriptPath = "$env:USERPROFILE\.openclaw\workspace\scripts\gateway-monitor.ps1"
$LogDir = "$env:USERPROFILE\.openclaw\logs"

# Ensure log directory exists
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
}

# Create the scheduled task action
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""

# Create trigger (every 5 minutes)
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)

# Create settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

# Register the task
try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Monitors OpenClaw gateway health and auto-restarts if it fails" -Force
    Write-Host "✅ Scheduled task '$TaskName' created successfully"
    Write-Host "   - Runs every 5 minutes"
    Write-Host "   - Monitors gateway health"
    Write-Host "   - Auto-restarts if failed"
    Write-Host "   - Logs to: $LogDir\gateway-monitor.log"
} catch {
    Write-Error "Failed to create scheduled task: $_"
}

# Start the task immediately
Start-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
Write-Host "   - Task started"
