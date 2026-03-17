# schedule-pdf-organization-1am-4am.ps1
# Creates scheduled task to run PDF organization from 1:00 AM to 4:00 AM
# Processes maximum files during the 3-hour window

$TaskName = "PDF Organization - E All (1AM-4AM)"
$ScriptPath = "C:\Users\impro\.openclaw\workspace\scripts\organize-e-all-pdfs-3hour.ps1"
$LogFile = "C:\Users\impro\.openclaw\logs\pdf-organization-nightly.log"

Write-Host "Creating scheduled task for PDF organization (1 AM - 4 AM)..." -ForegroundColor Cyan
Write-Host "Task: $TaskName" -ForegroundColor White
Write-Host "Time: 1:00 AM to 4:00 AM daily" -ForegroundColor White
Write-Host "Duration: 3 hours" -ForegroundColor White
Write-Host "Script: $ScriptPath" -ForegroundColor White
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (!$isAdmin) {
    Write-Host "ERROR: Must run as Administrator to create scheduled tasks" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Remove existing task if present
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed existing task" -ForegroundColor Green
}

# Also remove the old task if it exists
$oldTask = Get-ScheduledTask -TaskName "PDF Organization - E All" -ErrorAction SilentlyContinue
if ($oldTask) {
    Unregister-ScheduledTask -TaskName "PDF Organization - E All" -Confirm:$false
    Write-Host "Removed old task" -ForegroundColor Green
}

# Create the action - run the 3-hour script
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" *>>`"$LogFile`" 2>&1"

# Create trigger for 1:00 AM daily
$Trigger = New-ScheduledTaskTrigger -Daily -At "01:00"

# Create settings - run for maximum 3 hours (4 AM stop)
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 3)

# Register the task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Automatically organizes PDFs from E:\All into categorized folders. Runs nightly from 1:00 AM to 4:00 AM. Processes as many files as possible in the 3-hour window." -RunLevel Highest

Write-Host "✅ Scheduled task created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Task Details:" -ForegroundColor Cyan
Write-Host "  Name: $TaskName"
Write-Host "  Schedule: Daily 1:00 AM - 4:00 AM"
Write-Host "  Duration: 3 hours (auto-stops at 4 AM)"
Write-Host "  Log: $LogFile"
Write-Host ""
Write-Host "The task will:" -ForegroundColor Yellow
Write-Host "  - Start every night at 1:00 AM"
Write-Host "  - Process PDFs continuously for 3 hours"
Write-Host "  - Auto-stop at 4:00 AM"
Write-Host "  - Copy (not move) files to preserve originals"
Write-Host "  - Process approximately 500-800 PDFs per night"
Write-Host "  - Complete all 7,568 PDFs in ~10-15 nights"
Write-Host ""
Write-Host "To check progress:" -ForegroundColor Gray
Write-Host "  Get-Content $LogFile -Tail 50"
