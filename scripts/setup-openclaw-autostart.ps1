# OpenClaw Gateway Auto-Start Task
# Creates a scheduled task to start OpenClaw gateway on login

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `openclaw gateway start`"
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$Principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive

Register-ScheduledTask -TaskName "OpenClaw Gateway AutoStart" -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force

Write-Output "Scheduled task 'OpenClaw Gateway AutoStart' created successfully."
Write-Output "The gateway will start automatically when you log in."