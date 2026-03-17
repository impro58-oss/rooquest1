# Setup OpenClaw gateway to auto-start on system boot
# This ensures gateway starts automatically after power cut

param(
    [string]$ScriptPath = "C:\Users\impro\.openclaw\workspace\scripts\auto-start-gateway.ps1"
)

$TaskName = "OpenClaw Gateway Auto-Start"

# Check if task exists
$ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($ExistingTask) {
    Write-Host "Task already exists. Removing old version..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create action - runs at startup with delay
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""

# Create trigger - at system startup (with 2 minute delay for network)
$Trigger = New-ScheduledTaskTrigger -AtStartup

# Create settings
$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

# Run with highest privileges (needed for some network operations)
$Principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Highest

# Register task
Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Principal $Principal `
    -Description "Auto-start OpenClaw gateway on system boot (for power cut recovery)"

Write-Host ""
Write-Host "=== GATEWAY AUTO-START CONFIGURED ==="
Write-Host "Task: $TaskName"
Write-Host "Trigger: At system startup"
Write-Host "Delay: 2 minutes (for network initialization)"
Write-Host ""
Write-Host "The gateway will now start automatically when Windows boots."
Write-Host ""
Write-Host "To test:"
Write-Host "  Restart computer, then check: openclaw status"
Write-Host ""
Write-Host "To disable:"
Write-Host "  Disable-ScheduledTask -TaskName '$TaskName'"
Write-Host ""
Write-Host "To remove:"
Write-Host "  Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
