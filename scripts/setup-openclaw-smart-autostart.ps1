# OpenClaw Gateway Smart Auto-Start Task
# Creates a scheduled task to check/start OpenClaw gateway on login

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"C:\Users\impro\.openclaw\workspace\scripts\openclaw-gateway-smart-start.ps1`""

$Trigger = New-ScheduledTaskTrigger -AtLogOn

$Settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew

$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive

try {
    Unregister-ScheduledTask -TaskName "OpenClaw Gateway AutoStart" -Confirm:$false -ErrorAction SilentlyContinue
} catch {}

try {
    Unregister-ScheduledTask -TaskName "OpenClaw Gateway SmartStart" -Confirm:$false -ErrorAction SilentlyContinue
} catch {}

Register-ScheduledTask `
    -TaskName "OpenClaw Gateway SmartStart" `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Principal $Principal `
    -Force

Write-Output "Scheduled task 'OpenClaw Gateway SmartStart' created successfully."
Write-Output "The gateway will check if running and start only if needed."
Write-Output "Log file: %TEMP%\openclaw-gateway-autostart.log"