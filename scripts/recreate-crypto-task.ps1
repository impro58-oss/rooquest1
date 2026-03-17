# Create improved TrojanLogic4H scheduled task with wake and retry settings

$TaskName = "TrojanLogic4H Auto Scanner"
$ScriptPath = "C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2\auto_crypto_scanner.ps1"

# Delete existing task
schtasks /delete /tn $TaskName /f 2>$null

# Create new task with better settings
# Runs every 3 hours, wakes PC if asleep, runs immediately if missed
$Action = "powershell.exe -ExecutionPolicy Bypass -File `"$ScriptPath`" >> C:\Users\impro\.openclaw\workspace\logs\crypto_scan.log 2>&1"

# Create task with XML for advanced settings
$XmlContent = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>TrojanLogic4H Crypto Scanner - Every 3 hours with wake</Description>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>2026-03-15T00:00:00</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
      <Repetition>
        <Interval>PT3H</Interval>
        <Duration>P1D</Duration>
      </Repetition>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>true</WakeToRun>
    <ExecutionTimeLimit>PT1H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -File "$ScriptPath" >> C:\Users\impro\.openclaw\workspace\logs\crypto_scan.log 2>&1</Arguments>
    </Exec>
  </Actions>
</Task>
"@

$XmlPath = "$env:TEMP\trojanlogic_task.xml"
$XmlContent | Out-File $XmlPath -Encoding Unicode

# Create task from XML
schtasks /create /tn $TaskName /xml $XmlPath /f

# Clean up
Remove-Item $XmlPath -Force

Write-Host ""
Write-Host "=== TASK CREATED ==="
Write-Host "Name: $TaskName"
Write-Host "Schedule: Every 3 hours (00:00, 03:00, 06:00, 09:00, 12:00, 15:00, 18:00, 21:00)"
Write-Host "WakeToRun: true (wakes PC from sleep)"
Write-Host "StartWhenAvailable: true (runs immediately after wake)"
Write-Host ""
Write-Host "Next run: 15:00 today"
