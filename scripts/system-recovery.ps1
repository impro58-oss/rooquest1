# Complete system recovery after power cut or restart
# Run this if everything seems broken

param(
    [switch]$FullRecovery = $false
)

$WorkingDir = "C:\Users\impro\.openclaw\workspace"
$LogFile = "$WorkingDir\logs\system-recovery-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Ensure log directory
New-Item -ItemType Directory -Force -Path "$WorkingDir\logs" | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Level] $Timestamp - $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogFile -Value $LogEntry -Encoding UTF8
}

Write-Log "=== SYSTEM RECVERY STARTED ==="
Write-Log "Mode: $(if ($FullRecovery) { 'FULL' } else { 'QUICK' })"

# Step 1: Check OpenClaw gateway
Write-Log "Step 1: Checking OpenClaw gateway..."
try {
    $Status = openclaw status 2>$null
    if ($Status -match "healthy") {
        Write-Log "Gateway is healthy" "OK"
    } else {
        Write-Log "Gateway not running, attempting start..." "WARN"
        openclaw gateway start 2>$null
        Start-Sleep -Seconds 5
        
        $Status = openclaw status 2>$null
        if ($Status -match "healthy") {
            Write-Log "Gateway started successfully" "OK"
        } else {
            Write-Log "Gateway failed to start" "ERROR"
        }
    }
} catch {
    Write-Log "Error checking gateway: $_" "ERROR"
}

# Step 2: Check scheduled tasks
Write-Log "Step 2: Checking scheduled tasks..."
$Tasks = @(
    "TrojanLogic4H Auto Scanner",
    "OpenClaw Gateway Auto-Start",
    "OpenClaw Gateway Monitor",
    "OpenClaw Self-Heal"
)

foreach ($Task in $Tasks) {
    $TaskInfo = Get-ScheduledTask -TaskName $Task -ErrorAction SilentlyContinue
    if ($TaskInfo) {
        $State = $TaskInfo.State
        Write-Log "Task '$Task': $State" $(if ($State -eq "Ready") { "OK" } else { "WARN" })
    } else {
        Write-Log "Task '$Task': NOT FOUND" "WARN"
    }
}

# Step 3: Check data files
Write-Log "Step 3: Checking data files..."
$DataFiles = @(
    "$WorkingDir\data\crypto\crypto_latest.json",
    "$WorkingDir\data\crypto\crypto_history.json",
    "$WorkingDir\MEMORY.md"
)

foreach ($File in $DataFiles) {
    if (Test-Path $File) {
        $Size = (Get-Item $File).Length
        Write-Log "File exists: $File ($Size bytes)" "OK"
    } else {
        Write-Log "File missing: $File" "WARN"
    }
}

# Step 4: Check GitHub sync
Write-Log "Step 4: Checking GitHub sync..."
try {
    $GitPath = "C:\Program Files\Git\bin\git.exe"
    if (Test-Path $GitPath) {
        Set-Location $WorkingDir
        $Status = & $GitPath status --porcelain 2>$null
        if ($Status) {
            Write-Log "Uncommitted changes found, syncing..." "WARN"
            & $GitPath add -A 2>$null
            & $GitPath commit -m "Recovery sync $(Get-Date -Format 'yyyy-MM-dd HH:mm')" 2>$null
            & $GitPath push 2>$null
            
            Write-Log "Synced to GitHub" "OK"
        } else {
            Write-Log "GitHub sync: Up to date" "OK"
        }
    }
} catch {
    Write-Log "GitHub sync error: $_" "ERROR"
}

# Step 5: Full recovery (if requested)
if ($FullRecovery) {
    Write-Log "Step 5: Running full recovery..."
    
    # Reinstall scheduled tasks
    Write-Log "Reinstalling scheduled tasks..."
    
    $SetupScripts = @(
        "$WorkingDir\scripts\setup-auto-commit-task.ps1",
        "$WorkingDir\scripts\setup-gateway-autostart.ps1",
        "$WorkingDir\skills\tradingview-claw-v2\setup_auto_scan.ps1"
    )
    
    foreach ($Script in $SetupScripts) {
        if (Test-Path $Script) {
            Write-Log "Running: $Script"
            try {
                & $Script 2>$null
                Write-Log "Completed: $Script" "OK"
            } catch {
                Write-Log "Failed: $Script - $_" "ERROR"
            }
        }
    }
    
    Write-Log "Full recovery complete"
}

# Summary
Write-Log "=== RECOVERY COMPLETE ==="
Write-Log "Log saved to: $LogFile"
Write-Log ""
Write-Log "Next steps:"
Write-Log "  1. Check gateway: openclaw status"
Write-Log "  2. Check tasks: Get-ScheduledTask | Where-Object { `$_.TaskName -like '*OpenClaw*' }"
Write-Log "  3. Check data: dir $WorkingDir\data\crypto\"
Write-Log ""
Write-Log "If issues persist, check RESTART_PROTOCOL.md"
