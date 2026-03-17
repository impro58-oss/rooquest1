#!/usr/bin/env pwsh
# Backup Skill Implementation
# Usage: .\backup.ps1 [command]

param(
    [Parameter(Mandatory=$false)]
    [string]$Command = "run",
    
    [Parameter(Mandatory=$false)]
    [string]$Directory = ""
)

$Workspace = "$env:USERPROFILE\.openclaw\workspace"
$BackupDir = "$env:USERPROFILE\.openclaw\backups"
$LogFile = "$env:TEMP\backup.log"

function Write-Log {
    param($Message, $Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp [$Level] $Message" | Tee-Object -FilePath $LogFile -Append | Write-Output
}

function Backup-Git {
    Write-Log "Running git backup..."
    
    Set-Location $Workspace
    
    # Check if git repo exists
    if (-not (Test-Path ".git")) {
        Write-Log "Initializing git repository..." "WARN"
        git init
        git remote add origin https://github.com/impro58-oss/rooquest1.git 2>$null
    }
    
    # Stage all changes
    git add -A
    
    # Check if there are changes to commit
    $Status = git status --porcelain
    if ($Status) {
        $CommitMessage = "Daily backup - $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        git commit -m $CommitMessage
        Write-Log "✅ Git commit: $CommitMessage" "SUCCESS"
        
        # Push to remote (if configured)
        try {
            git push origin main 2>$null
            Write-Log "✅ Pushed to remote" "SUCCESS"
        } catch {
            Write-Log "⚠️  Push failed (remote may not be configured)" "WARN"
        }
    } else {
        Write-Log "No changes to commit" "INFO"
    }
}

function Backup-Directory {
    param($SourceDir, $BackupName)
    
    $SourcePath = Join-Path $Workspace $SourceDir
    if (-not (Test-Path $SourcePath)) {
        Write-Log "Directory not found: $SourceDir" "WARN"
        return
    }
    
    $Date = Get-Date -Format "yyyy-MM-dd"
    $ZipFile = Join-Path $BackupDir "${BackupName}-${Date}.zip"
    
    Write-Log "Backing up $SourceDir to $ZipFile..."
    
    try {
        Compress-Archive -Path "$SourcePath\*" -DestinationPath $ZipFile -Force
        $Size = (Get-Item $ZipFile).Length / 1MB
        Write-Log "✅ Backup: $BackupName ($("{0:N2}" -f $Size)MB)" "SUCCESS"
    } catch {
        Write-Log "❌ Backup failed: $_" "ERROR"
    }
}

function Cleanup-OldBackups {
    Write-Log "Cleaning up old backups..."
    
    $Cutoff = (Get-Date).AddDays(-30)
    $OldBackups = Get-ChildItem -Path $BackupDir -Filter "*.zip" | Where-Object { $_.LastWriteTime -lt $Cutoff }
    
    foreach ($Backup in $OldBackups) {
        Remove-Item $Backup.FullName -Force
        Write-Log "Deleted old backup: $($Backup.Name)" "INFO"
    }
    
    Write-Log "✅ Cleanup complete ($($OldBackups.Count) files removed)" "SUCCESS"
}

function Show-Status {
    Write-Log "=== Backup Status ==="
    
    # Git status
    Set-Location $Workspace
    $LastCommit = git log -1 --format="%h - %s (%cr)" 2>$null
    if ($LastCommit) {
        Write-Log "Last commit: $LastCommit" "INFO"
    }
    
    # Backup files
    $Backups = Get-ChildItem -Path $BackupDir -Filter "*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    Write-Log "Recent backups:"
    foreach ($Backup in $Backups) {
        $Size = $Backup.Length / 1MB
        Write-Log "  $($Backup.Name) - $("{0:N2}" -f $Size)MB - $($Backup.LastWriteTime)" "INFO"
    }
    
    # Total size
    $TotalSize = (Get-ChildItem -Path $BackupDir -Filter "*.zip" | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Log "Total backup size: $("{0:N2}" -f $TotalSize)MB" "INFO"
}

# Ensure backup directory exists
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

# Main execution
Write-Log "=== Backup Started ==="

switch ($Command) {
    "run" {
        Backup-Git
        Backup-Directory -SourceDir "memory" -BackupName "memory"
        Backup-Directory -SourceDir "skills" -BackupName "skills"
        Backup-Directory -SourceDir "agents" -BackupName "agents"
        Backup-Directory -SourceDir "scripts" -BackupName "scripts"
        Cleanup-OldBackups
        Write-Log "=== Backup Complete ===" "SUCCESS"
    }
    "status" {
        Show-Status
    }
    "dir" {
        if ($Directory) {
            Backup-Directory -SourceDir $Directory -BackupName $Directory
        } else {
            Write-Log "Usage: backup.ps1 dir -Directory <name>" "ERROR"
        }
    }
    default {
        Write-Log "Unknown command: $Command" "ERROR"
        Write-Log "Usage: backup.ps1 [run|status|dir]" "INFO"
    }
}