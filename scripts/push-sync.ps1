<#
.SYNOPSIS
    Push sync entry to memory file for cross-group knowledge sharing
.DESCRIPTION
    Writes standardized sync entries to memory/YYYY-MM-DD.md for all sessions to read
.PARAMETER Group
    Source group: CRYPTO, POLY, SYSTEM, DECISION
.PARAMETER Type
    Entry type: signal, opportunity, error, config, decision
.PARAMETER Data
    JSON string with structured data
.PARAMETER Message
    Human-readable summary
.PARAMETER Decision
    What was decided (optional)
.PARAMETER Action
    What to do (optional)
.PARAMETER Context
    Background information (optional)
.EXAMPLE
    .\push-sync.ps1 -Group "CRYPTO" -Type "signal" -Data '{"symbol":"BTC"}' -Message "BTC LONG detected"
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("CRYPTO", "POLY", "SYSTEM", "DECISION")]
    [string]$Group,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("signal", "opportunity", "error", "config", "decision", "update")]
    [string]$Type,
    
    [Parameter(Mandatory=$true)]
    [string]$Data,
    
    [Parameter(Mandatory=$true)]
    [string]$Message,
    
    [string]$Decision = "",
    [string]$Action = "",
    [string]$Context = "",
    [string]$FilesChanged = "",
    [string]$NextSteps = ""
)

# Config
$MemoryDir = "C:\Users\impro\.openclaw\workspace\memory"
$Date = Get-Date -Format "yyyy-MM-dd"
$Time = Get-Date -Format "HH:mm"
$MemoryFile = Join-Path $MemoryDir "$Date.md"

# Ensure memory directory exists
if (-not (Test-Path $MemoryDir)) {
    New-Item -ItemType Directory -Force -Path $MemoryDir | Out-Null
}

# Build entry
$Entry = @"

## Entry $Time - [$Group] SYNC: $Message

**Source:** $Group Group
**Type:** $Type
**Timestamp:** $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
"@

if ($Decision) {
    $Entry += "`n**Decision:** $Decision"
}

if ($Action) {
    $Entry += "`n**Action:** $Action"
}

if ($Context) {
    $Entry += "`n**Context:** $Context"
}

if ($FilesChanged) {
    $Entry += "`n**Files Changed:** $FilesChanged"
}

if ($NextSteps) {
    $Entry += "`n**Next Steps:** $NextSteps"
}

$Entry += @"

**Data:**
```json
$Data
```

---
"@

# Append to memory file
Add-Content -Path $MemoryFile -Value $Entry -Encoding UTF8

Write-Host "[OK] Sync pushed to $MemoryFile"
Write-Host "[INFO] All sessions will see this on next startup"

# Also update MEMORY.md if this is a major decision
if ($Type -eq "decision" -or $Type -eq "config") {
    $MemoryMain = "C:\Users\impro\.openclaw\workspace\MEMORY.md"
    $Summary = "- **$(Get-Date -Format 'yyyy-MM-dd')**: [$Group] $Message"
    
    # Find "## 💡 KEY DECISIONS LOG" section and append
    $Content = Get-Content $MemoryMain -Raw
    if ($Content -match "### \*\*$(Get-Date -Format 'yyyy-MM-dd')\*\*") {
        # Date section exists, append to it
        $Content = $Content -replace "(### \*\*$(Get-Date -Format 'yyyy-MM-dd')\*\*.*?)(?=\n### |\n## |\Z)", "`$1`n$Summary"
    } else {
        # Add new date section
        $Content = $Content -replace "(## 💡 KEY DECISIONS LOG.*?)(?=\n## |\Z)", "`$1`n`n### **$(Get-Date -Format 'yyyy-MM-dd')**`n$Summary"
    }
    
    Set-Content -Path $MemoryMain -Value $Content -Encoding UTF8
    Write-Host "[OK] Also updated MEMORY.md"
}
