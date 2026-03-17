# openclaw-self-heal.ps1
# Comprehensive self-healing script for OpenClaw on Windows
# Run this manually or via scheduled task for automatic recovery

param(
    [switch]$Verbose,
    [switch]$AutoFix
)

$ErrorActionPreference = "Stop"

# Configuration
$WORKDIR = if ($env:OPENCLAW_WORKDIR) { $env:OPENCLAW_WORKDIR } else { "C:\Users\impro\.openclaw\workspace" }
$PORT = if ($env:OPENCLAW_PORT) { [int]$env:OPENCLAW_PORT } else { 18789 }
$LOCAL_URL = "http://127.0.0.1:$PORT"
$LOG_DIR = "$env:USERPROFILE\.openclaw\logs"
$HEAL_LOG = "$LOG_DIR\self-heal.log"
$MIN_DISK_GB = 1
$MAX_WAIT_SECONDS = 30
$NODE_MIN_VERSION = 22

# Ensure log directory exists
if (!(Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
}

function Write-HealLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $HEAL_LOG -Value $logEntry
    if ($Verbose -or $Level -eq "ERROR") {
        Write-Host $logEntry -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARN") { "Yellow" } else { "White" })
    }
}

function Test-Command {
    param($Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Get-DiskSpaceGB {
    try {
        $drive = (Get-Item $WORKDIR -ErrorAction Stop).PSDrive
        $freeGB = [math]::Round($drive.Free / 1GB, 2)
        return $freeGB
    } catch {
        # Fallback: check C: drive
        $drive = Get-PSDrive C
        $freeGB = [math]::Round($drive.Free / 1GB, 2)
        return $freeGB
    }
}

function Get-NodeVersion {
    try {
        $version = node -v 2>$null
        if ($version -match 'v(\d+)') {
            return [int]$Matches[1]
        }
    } catch {}
    return 0
}

function Test-PortListening {
    param($Port)
    try {
        $listener = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue
        return $listener.TcpTestSucceeded
    } catch {
        return $false
    }
}

function Test-HttpHealth {
    param($Url)
    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Stop-GatewayProcesses {
    Write-HealLog "Terminating stale OpenClaw gateway processes"
    
    # Find processes using the port
    try {
        $connections = Get-NetTCPConnection -LocalPort $PORT -ErrorAction SilentlyContinue
        foreach ($conn in $connections) {
            try {
                $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                if ($process) {
                    Write-HealLog "Killing process: $($process.ProcessName) (PID: $($process.Id))" "WARN"
                    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                }
            } catch {}
        }
    } catch {}
    
    # Kill any openclaw-related processes
    $processes = Get-Process | Where-Object { 
        $_.ProcessName -like "*openclaw*" -or 
        $_.ProcessName -like "*node*" -or
        $_.CommandLine -like "*openclaw*" 
    } -ErrorAction SilentlyContinue
    
    foreach ($proc in $processes) {
        try {
            Write-HealLog "Stopping process: $($proc.ProcessName) (PID: $($proc.Id))" "WARN"
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        } catch {}
    }
    
    Start-Sleep -Seconds 2
}

function Clear-StaleLocks {
    $lockDirs = @(
        "$env:USERPROFILE\.openclaw\locks",
        "$env:TEMP\openclaw-*"
    )
    
    foreach ($dir in $lockDirs) {
        if (Test-Path $dir) {
            Write-HealLog "Cleaning stale locks in $dir"
            Get-ChildItem -Path $dir -Filter "*.lock" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
}

function Install-Dependencies {
    Write-HealLog "Checking node_modules"
    if (!(Test-Path "$WORKDIR\node_modules")) {
        Write-HealLog "node_modules missing; reinstalling dependencies" "WARN"
        Set-Location $WORKDIR
        
        if (Test-Command "npm") {
            npm install 2>&1 | Out-Null
            Write-HealLog "Dependencies reinstalled with npm"
        } else {
            Write-HealLog "npm not found" "ERROR"
        }
    }
}

function Start-Gateway {
    Write-HealLog "Starting OpenClaw gateway"
    
    # Start gateway in background
    $gatewayJob = Start-Job -ScriptBlock {
        param($workdir)
        Set-Location $workdir
        openclaw gateway start 2>&1
    } -ArgumentList $WORKDIR
    
    # Wait for port to be ready
    Write-HealLog "Waiting for port $PORT to listen (max ${MAX_WAIT_SECONDS}s)"
    $waited = 0
    $listening = $false
    
    while ($waited -lt $MAX_WAIT_SECONDS) {
        if (Test-PortListening -Port $PORT) {
            $listening = $true
            break
        }
        Start-Sleep -Seconds 1
        $waited++
    }
    
    if (!$listening) {
        Write-HealLog "Port $PORT is not listening after ${MAX_WAIT_SECONDS}s" "ERROR"
        return $false
    }
    
    Write-HealLog "Port $PORT is listening"
    
    # Verify HTTP health
    Write-HealLog "Verifying local HTTP health"
    $healthOk = Test-HttpHealth -Url "$LOCAL_URL/health" -or (Test-HttpHealth -Url $LOCAL_URL)
    
    if (!$healthOk) {
        Write-HealLog "Local HTTP health check failed" "ERROR"
        return $false
    }
    
    Write-HealLog "Gateway health check passed"
    return $true
}

function Repair-Gateway {
    Write-HealLog "=== STARTING GATEWAY REPAIR ===" "WARN"
    
    Stop-GatewayProcesses
    Clear-StaleLocks
    Install-Dependencies
    
    $success = Start-Gateway
    
    if ($success) {
        Write-HealLog "=== GATEWAY REPAIR SUCCESSFUL ==="
    } else {
        Write-HealLog "=== GATEWAY REPAIR FAILED ===" "ERROR"
    }
    
    return $success
}

# ==================== MAIN EXECUTION ====================

Write-HealLog "=== OpenClaw Self-Heal Started ==="

# 1) Check prerequisites
Write-HealLog "Checking prerequisites"

if (!(Test-Command "node")) {
    Write-HealLog "Node.js not found in PATH" "ERROR"
    exit 1
}

$nodeVersion = Get-NodeVersion
if ($nodeVersion -lt $NODE_MIN_VERSION) {
    Write-HealLog "Node >= $NODE_MIN_VERSION required (found v$nodeVersion)" "ERROR"
    exit 1
}
Write-HealLog "Node.js v$nodeVersion OK"

if (!(Test-Command "openclaw")) {
    Write-HealLog "OpenClaw CLI not found in PATH" "ERROR"
    exit 1
}
Write-HealLog "OpenClaw CLI OK"

# 2) Check disk space
Write-HealLog "Checking disk space"
$diskGB = Get-DiskSpaceGB
if ($diskGB -lt $MIN_DISK_GB) {
    Write-HealLog "Less than ${MIN_DISK_GB}GB free on workspace drive ($diskGB GB available)" "ERROR"
    exit 1
}
Write-HealLog "Disk space OK: $diskGB GB available"

# 3) Ensure workspace exists
Write-HealLog "Ensuring workspace exists"
if (!(Test-Path $WORKDIR)) {
    Write-HealLog "WORKDIR not found: $WORKDIR" "ERROR"
    exit 1
}
Write-HealLog "Workspace OK: $WORKDIR"

# 4) Check if gateway is healthy
Write-HealLog "Checking gateway health"
$portListening = Test-PortListening -Port $PORT
$httpHealthy = if ($portListening) { Test-HttpHealth -Url $LOCAL_URL } else { $false }

if ($portListening -and $httpHealthy) {
    Write-HealLog "Gateway is healthy (port $PORT listening, HTTP responding)"
    Write-HealLog "=== Self-Heal Complete - No Action Needed ==="
    exit 0
}

# 5) Gateway is unhealthy - repair it
if (!$portListening) {
    Write-HealLog "Port $PORT is not listening" "WARN"
}
if (!$httpHealthy -and $portListening) {
    Write-HealLog "HTTP health check failed" "WARN"
}

if ($AutoFix) {
    $repaired = Repair-Gateway
    if ($repaired) {
        Write-HealLog "Gateway successfully repaired and running"
        exit 0
    } else {
        Write-HealLog "Failed to repair gateway" "ERROR"
        exit 1
    }
} else {
    Write-HealLog "Gateway needs repair. Run with -AutoFix to repair automatically" "WARN"
    exit 1
}
