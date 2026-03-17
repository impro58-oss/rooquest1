#!/usr/bin/env pwsh
# Health Check Implementation
# Usage: .\healthcheck.ps1 [command]

param(
    [Parameter(Mandatory=$false)]
    [string]$Command = "run",
    
    [Parameter(Mandatory=$false)]
    [string]$Component = "all"
)

$LogFile = "$env:TEMP\healthcheck.log"
$ConfigPath = "$env:USERPROFILE\.openclaw\skills\healthcheck\config.json"

function Write-Log {
    param($Message, $Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp [$Level] $Message" | Tee-Object -FilePath $LogFile -Append | Write-Output
}

function Check-Gateway {
    Write-Log "Checking OpenClaw gateway..."
    
    # Check if port 18789 is listening
    $PortCheck = Get-NetTCPConnection -LocalPort 18789 -ErrorAction SilentlyContinue | Where-Object { $_.State -eq "Listen" }
    
    if ($PortCheck) {
        Write-Log "✅ Gateway: Running on port 18789" "SUCCESS"
        return $true
    } else {
        Write-Log "❌ Gateway: Not running" "ERROR"
        return $false
    }
}

function Check-Disk {
    Write-Log "Checking disk space..."
    
    $Disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    $Issues = @()
    
    foreach ($Disk in $Disks) {
        $FreePercent = [math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 1)
        $UsedPercent = 100 - $FreePercent
        $Drive = $Disk.DeviceID
        
        if ($UsedPercent -gt 90) {
            Write-Log "❌ Disk $Drive`: ${UsedPercent}% used (CRITICAL)" "ERROR"
            $Issues += "Disk $Drive`: $UsedPercent% used"
        } elseif ($UsedPercent -gt 80) {
            Write-Log "⚠️  Disk $Drive`: ${UsedPercent}% used (WARNING)" "WARN"
            $Issues += "Disk $Drive`: $UsedPercent% used"
        } else {
            Write-Log "✅ Disk $Drive`: ${UsedPercent}% used (OK)" "SUCCESS"
        }
    }
    
    return $Issues
}

function Check-Memory {
    Write-Log "Checking memory..."
    
    $Memory = Get-WmiObject -Class Win32_OperatingSystem
    $TotalGB = [math]::Round($Memory.TotalVisibleMemorySize / 1MB, 2)
    $FreeGB = [math]::Round($Memory.FreePhysicalMemory / 1MB, 2)
    $UsedPercent = [math]::Round((($Memory.TotalVisibleMemorySize - $Memory.FreePhysicalMemory) / $Memory.TotalVisibleMemorySize) * 100, 1)
    
    if ($UsedPercent -gt 90) {
        Write-Log "❌ Memory: ${UsedPercent}% used (${FreeGB}GB free of ${TotalGB}GB) (CRITICAL)" "ERROR"
        return @("Memory: $UsedPercent% used")
    } elseif ($UsedPercent -gt 80) {
        Write-Log "⚠️  Memory: ${UsedPercent}% used (${FreeGB}GB free of ${TotalGB}GB) (WARNING)" "WARN"
        return @("Memory: $UsedPercent% used")
    } else {
        Write-Log "✅ Memory: ${UsedPercent}% used (${FreeGB}GB free of ${TotalGB}GB) (OK)" "SUCCESS"
        return @()
    }
}

function Check-CPU {
    Write-Log "Checking CPU..."
    
    $CPU = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
    $Load = $CPU.LoadPercentage
    
    if ($Load -gt 90) {
        Write-Log "❌ CPU: ${Load}% load (CRITICAL)" "ERROR"
        return @("CPU: $Load% load")
    } elseif ($Load -gt 70) {
        Write-Log "⚠️  CPU: ${Load}% load (WARNING)" "WARN"
        return @("CPU: $Load% load")
    } else {
        Write-Log "✅ CPU: ${Load}% load (OK)" "SUCCESS"
        return @()
    }
}

function Send-Alert {
    param($Message)
    
    # Could integrate with Telegram here
    Write-Log "ALERT: $Message" "ALERT"
}

# Main execution
Write-Log "=== Health Check Started ==="

$Issues = @()
$GatewayOK = $true

switch ($Component) {
    "gateway" { $GatewayOK = Check-Gateway }
    "disk" { $Issues = Check-Disk }
    "memory" { $Issues = Check-Memory }
    "cpu" { $Issues = Check-CPU }
    "all" {
        $GatewayOK = Check-Gateway
        $Issues = Check-Disk
        $Issues += Check-Memory
        $Issues += Check-CPU
    }
}

Write-Log "=== Health Check Complete ==="

$IssueCount = if ($Issues) { $Issues.Count } else { 0 }

if ($IssueCount -gt 0 -or -not $GatewayOK) {
    Write-Log "Status: UNHEALTHY ($IssueCount issues found)" "ERROR"
    exit 1
} else {
    Write-Log "Status: HEALTHY" "SUCCESS"
    exit 0
}