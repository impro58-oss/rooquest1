# create-self-heal-task.ps1
# Creates Windows Scheduled Task for automatic self-healing
# Run as Administrator

param(
    [switch]$Force
)

$TaskName = "OpenClaw Self-Heal"
$ScriptPath = "C:\Users\impro\.openclaw\workspace\scripts\openclaw-heal-and-fix.ps1"
$LogPath = "C:\Users\impro\.openclaw\logs\self-heal-task.log"

Write-Host "Creating OpenClaw Self-Heal Scheduled Task..." -ForegroundColor Cyan

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!$isAdmin) {
    Write-Host "ERROR: Must run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask -and !$Force) {
    Write-Host "Task '$TaskName' already exists. Use -Force to recreate." -ForegroundColor Yellow
    exit 0
}

# Remove existing task if Force
if ($existingTask -and $Force) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed existing task" -ForegroundColor Green
}

# Create the action
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -Silent"

# Create triggers (every 5 minutes)
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)

# Create settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

# Register the task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Automatically heals OpenClaw gateway if it becomes unresponsive" -RunLevel Highest

Write-Host "✅ Scheduled task '$TaskName' created successfully" -ForegroundColor Green
Write-Host ""
Write-Host "Task Details:" -ForegroundColor Cyan
Write-Host "  Name: $TaskName"
Write-Host "  Schedule: Every 5 minutes"
Write-Host "  Script: $ScriptPath"
Write-Host "  Log: C:\Users\impro\.openclaw\logs\self-heal.log"
Write-Host ""
Write-Host "To test: Run 'openclaw-heal-and-fix.ps1' manually" -ForegroundColor Gray
Write-Host "To view logs: Get-Content C:\Users\impro\.openclaw\logs\self-heal.log -Tail 50" -ForegroundColor Gray
