# Setup scheduled task for workspace auto-commit
param(
    [string]$WorkingDir = "C:\Users\impro\.openclaw\workspace",
    [string]$ScriptPath = "C:\Users\impro\.openclaw\workspace\scripts\auto-commit-workspace.ps1"
)

# Task name
$TaskName = "OpenClaw Workspace Auto-Commit"

# Check if task exists
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($ExistingTask) {
    Write-Host "Task already exists. Removing old version..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create action
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -WorkingDir `"$WorkingDir`""

# Create trigger (every 2 hours)
$Trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).Date `
    -RepetitionInterval (New-TimeSpan -Hours 2) `
    -RepetitionDuration (New-TimeSpan -Days 365)

# Create settings
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

# Register task
Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Description "Auto-commit OpenClaw workspace to GitHub every 2 hours"

Write-Host ""
Write-Host "=== TASK CREATED ==="
Write-Host "Name: $TaskName"
Write-Host "Schedule: Every 2 hours"
Write-Host "Script: $ScriptPath"
Write-Host ""
Write-Host "To run manually:"
Write-Host "  Start-ScheduledTask -TaskName '$TaskName'"
Write-Host ""
Write-Host "To check status:"
Write-Host "  Get-ScheduledTask -TaskName '$TaskName' | Select-Object State, LastRunTime, NextRunTime"
