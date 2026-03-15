# Schedule Polymarket Daily Cleanup Task
# Runs at 5:00 AM daily to clean old scan files

$TaskName = "Polymarket Daily Cleanup"
$ScriptPath = "C:\Users\impro\.openclaw\workspace\scripts\polymarket-cleanup.ps1"

# Create the action
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""

# Create the trigger - 5:00 AM daily
$Trigger = New-ScheduledTaskTrigger -Daily -At "05:00"

# Create the settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Register the task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Force

Write-Host "Scheduled task '$TaskName' created successfully"
Write-Host "Runs daily at 5:00 AM"
Write-Host "Cleans Polymarket scan files older than 7 days"
