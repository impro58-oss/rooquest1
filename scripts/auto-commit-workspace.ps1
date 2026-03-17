# Auto-commit entire workspace to GitHub
# Runs every 2 hours to ensure all work is backed up

param(
    [string]$WorkingDir = "C:\Users\impro\.openclaw\workspace",
    [string]$GitPath = "C:\Program Files\Git\bin\git.exe",
    [switch]$Force = $false
)

# Change to working directory
Set-Location $WorkingDir

# Log file
$LogDir = "$WorkingDir\logs"
$LogFile = "$LogDir\auto-commit-$(Get-Date -Format 'yyyyMM').log"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp - $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogFile -Value $LogEntry -Encoding UTF8
}

Write-Log "=== Starting Workspace Auto-Commit ==="

# Check if git is available
if (-not (Test-Path $GitPath)) {
    Write-Log "[ERROR] Git not found at $GitPath"
    exit 1
}

# Check if this is a git repo
if (-not (Test-Path "$WorkingDir\.git")) {
    Write-Log "[ERROR] Not a git repository: $WorkingDir"
    exit 1
}

# Configure git user if not set
& $GitPath config --local user.email "roo@rooquest.local" 2>$null
& $GitPath config --local user.name "Roo Auto-Commit" 2>$null

# Check for changes
Write-Log "Checking for changes..."
$Status = & $GitPath status --porcelain 2>$null

if ($Status -or $Force) {
    if ($Status) {
        $ChangeCount = ($Status | Measure-Object).Count
        Write-Log "Found $ChangeCount changed files"
    } else {
        Write-Log "[FORCE] Committing even with no changes"
    }
    
    # Stage all changes
    Write-Log "Staging changes..."
    
    # Add specific directories (exclude large binaries)
    $DirsToAdd = @(
        "data",
        "memory",
        "scripts",
        "skills",
        "security",
        "*.md",
        "*.json",
        "*.txt",
        "*.ps1",
        "*.py"
    )
    
    foreach ($Dir in $DirsToAdd) {
        try {
            & $GitPath add $Dir 2>$null
        } catch {
            Write-Log "[WARN] Could not add $Dir"
        }
    }
    
    # Check if there's anything staged
    $Staged = & $GitPath diff --cached --name-only 2>$null
    
    if ($Staged -or $Force) {
        # Create commit message
        $CommitMsg = "Auto-commit workspace $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        
        # Add summary of changes
        if ($Staged) {
            $FileCount = ($Staged | Measure-Object).Count
            $CommitMsg += " ($FileCount files)"
        }
        
        Write-Log "Committing: $CommitMsg"
        
        # Commit
        $CommitOutput = & $GitPath commit -m $CommitMsg 2>$null
        Write-Log $CommitOutput
        
        # Push to GitHub
        Write-Log "Pushing to GitHub..."
        $PushOutput = & $GitPath push origin master 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "[OK] Successfully pushed to GitHub"
            
            # Get commit hash
            $CommitHash = (& $GitPath rev-parse --short HEAD 2>$null)
            Write-Log "Commit: $CommitHash"
        } else {
            Write-Log "[ERROR] Push failed"
            Write-Log $PushOutput
        }
    } else {
        Write-Log "[INFO] Nothing to commit"
    }
} else {
    Write-Log "[INFO] No changes detected"
}

Write-Log "=== Auto-commit complete ==="
Write-Log ""
