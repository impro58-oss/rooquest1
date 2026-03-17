# schedule-pdf-organization.ps1
# Creates scheduled task to run PDF organization at 1:00 AM

$TaskName = "PDF Organization - E All"
$ScriptPath = "C:\Users\impro\.openclaw\workspace\scripts\organize-e-all-pdfs.ps1"
$LogFile = "C:\Users\impro\.openclaw\logs\pdf-organization-1am.log"

Write-Host "Creating scheduled task for PDF organization..." -ForegroundColor Cyan
Write-Host "Task: $TaskName" -ForegroundColor White
Write-Host "Time: 1:00 AM daily" -ForegroundColor White
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

# Create the action - run the script with batch size 200 (process ~200 files per run)
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -BatchSize 200 *>>`"$LogFile`""

# Create trigger for 1:00 AM daily
$Trigger = New-ScheduledTaskTrigger -Daily -At "01:00"

# Create settings - run whether user is logged on or not, with highest privileges
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

# Register the task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Automatically organizes PDFs from E:\All into categorized folders. Runs at 1:00 AM daily." -RunLevel Highest

Write-Host "✅ Scheduled task created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Task Details:" -ForegroundColor Cyan
Write-Host "  Name: $TaskName"
Write-Host "  Schedule: Daily at 1:00 AM"
Write-Host "  Action: Process 200 PDFs per run"
Write-Host "  Log: $LogFile"
Write-Host ""
Write-Host "The task will:" -ForegroundColor Yellow
Write-Host "  - Run every night at 1:00 AM"
Write-Host "  - Process 200 PDFs each time"
Write-Host "  - Copy (not move) files to preserve originals"
Write-Host "  - Continue until all 7,568 PDFs are organized"
Write-Host "  - Take approximately 38 nights to complete"
Write-Host ""
Write-Host "To check progress:" -ForegroundColor Gray
Write-Host "  Get-Content $LogFile -Tail 50"
Write-Host ""
Write-Host "To run manually now:" -ForegroundColor Gray
Write-Host "  .\organize-e-all-pdfs.ps1 -BatchSize 100"
