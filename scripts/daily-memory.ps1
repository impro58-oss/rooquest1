# daily-memory.ps1
# Daily memory logging script for OpenClaw workspace
# Run this at end of day to capture work summary

$WorkspaceDir = "C:\Users\impro\.openclaw\workspace"
$MemoryDir = "$WorkspaceDir\memory"
$DateStamp = Get-Date -Format "yyyy-MM-dd"
$TimeStamp = Get-Date -Format "HH:mm"
$MemoryFile = "$MemoryDir\$DateStamp.md"

# Create memory directory if it doesn't exist
if (!(Test-Path $MemoryDir)) {
    New-Item -ItemType Directory -Force -Path $MemoryDir | Out-Null
}

# Check if today's memory file exists
if (Test-Path $MemoryFile) {
    # Append to existing file
    $Mode = "Append"
} else {
    # Create new file with header
    $Mode = "Create"
}

# Build memory entry
$Entry = @"

## Entry $TimeStamp

**What we worked on:**
- 

**Decisions made:**
- 

**Key insights:**
- 

**Next steps:**
- 

---
"@

if ($Mode -eq "Create") {
    # Create new file with header
    $Header = @"# Memory Log - $DateStamp

*Daily log of work, decisions, and insights*

$Entry
"@
    Set-Content -Path $MemoryFile -Value $Header
    Write-Host "Created new memory file: $MemoryFile"
} else {
    # Append to existing file
    Add-Content -Path $MemoryFile -Value $Entry
    Write-Host "Appended to memory file: $MemoryFile"
}

Write-Host "`nMemory logging complete. Edit the file to fill in details."
Write-Host "File location: $MemoryFile"
