# Fix OpenClaw Gateway Scheduled Task - Run without elevation
$TaskName = "OpenClaw Gateway"

# Export current task
$ExportPath = "$env:TEMP\openclaw-task.xml"
schtasks /query /xml /tn $TaskName > $ExportPath 2>$null

# Read and modify XML
$Xml = Get-Content $ExportPath -Raw

# Add RunLevel="LeastPrivilege" to Principal if not present
if ($Xml -notmatch 'RunLevel=') {
    $Xml = $Xml -replace '(?s)(<Principal[^/]*?)(>)', '$1 RunLevel="LeastPrivilege"$2'
}

# Save modified XML
$Xml | Set-Content $ExportPath

# Delete and recreate task with modified settings
schtasks /delete /tn $TaskName /f 2>$null
schtasks /create /tn $TaskName /xml $ExportPath /f

Write-Output "Task updated to run with least privileges (no UAC)"