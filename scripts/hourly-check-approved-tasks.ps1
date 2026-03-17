# hourly-check-approved-tasks.ps1
# Wrapper script for cron job - checks and implements approved tasks

Write-Host "Starting hourly check for approved self-improvement tasks..."

# Run the implementation script
& "$env:USERPROFILE\.openclaw\workspace\scripts\auto-approved-tasks-implementer.ps1"

Write-Host "Hourly check complete."
