# Fix TrojanLogic4H scheduled task to run after wake and retry on failure

$TaskName = "TrojanLogic4H Auto Scanner"

# Export current task
$ExportPath = "$env:TEMP\trojanlogic_task.xml"
schtasks /query /tn $TaskName /xml | Out-File $ExportPath

# Read and modify XML
$Xml = Get-Content $ExportPath -Raw

# Add WakeToRun if not present
if ($Xml -notmatch "<WakeToRun>") {
    $Xml = $Xml -replace "(<RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>)", "`$1`n    <WakeToRun>true</WakeToRun>"
}

# Ensure StartWhenAvailable is true
$Xml = $Xml -replace "<StartWhenAvailable>false</StartWhenAvailable>", "<StartWhenAvailable>true</StartWhenAvailable>"

# Add multiple triggers for each 3-hour slot to ensure coverage
$NewTriggers = @"
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
"@

# Replace triggers section
$Xml = $Xml -replace "<Triggers>.*?</Triggers>", $NewTriggers

# Save modified XML
$Xml | Out-File $ExportPath

# Delete and recreate task
schtasks /delete /tn $TaskName /f 2>$null
schtasks /create /tn $TaskName /xml $ExportPath /f

Write-Host "Task updated with:"
Write-Host "- WakeToRun: true (wakes PC to run)"
Write-Host "- StartWhenAvailable: true (runs after wake)"
Write-Host "- 3-hour repetition throughout day"

# Clean up
Remove-Item $ExportPath -Force
