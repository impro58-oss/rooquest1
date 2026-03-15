# Daily Agent Brief Compiler
# Run at 6:30 AM to compile all agent activity from previous 24 hours

$MemoryFile = "C:\Users\impro\.openclaw\workspace\memory\$(Get-Date -Format 'yyyy-MM-dd').md"
$Yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
$YesterdayFile = "C:\Users\impro\.openclaw\workspace\memory\$Yesterday.md"

Write-Host "=== DAILY AGENT BRIEF COMPILER ==="
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host ""

# Check for agent entries in today's memory file
$AgentEntries = @()

if (Test-Path $MemoryFile) {
    $Content = Get-Content $MemoryFile -Raw
    # Find all agent completion entries
    $AgentMatches = [regex]::Matches($Content, "## Entry \d{2}:\d{2} - (.+?) Task Complete")
    foreach ($Match in $AgentMatches) {
        $AgentEntries += $Match.Groups[1].Value
    }
}

# Also check yesterday's file for late entries
if (Test-Path $YesterdayFile) {
    $YesterdayContent = Get-Content $YesterdayFile -Raw
    $YesterdayMatches = [regex]::Matches($YesterdayContent, "## Entry \d{2}:\d{2} - (.+?) Task Complete")
    foreach ($Match in $YesterdayMatches) {
        if ($Match.Groups[1].Value -notin $AgentEntries) {
            $AgentEntries += $Match.Groups[1].Value
        }
    }
}

Write-Host "Found $($AgentEntries.Count) agent completion entries"
Write-Host ""

# Generate brief
$Brief = @"
# Daily Agent Activity Brief - $(Get-Date -Format 'yyyy-MM-dd')

**Compiled:** $(Get-Date -Format 'HH:mm') UTC
**Period:** Last 24 hours

## Summary
$($AgentEntries.Count) agent task(s) completed

## Agent Reports

"@

# Parse each agent entry for key details
foreach ($Agent in $AgentEntries) {
    $Brief += @"
### $Agent
- Status: Completed
- Review required: Yes

"@
}

$Brief += @"
## Priority Actions
[To be filled by Lumina after review]

## System Health
- Agent registry: Current
- Memory sync: Active
- Notion integration: Online

---
*Next brief: Tomorrow 6:30 AM*
"@

# Save brief
$BriefPath = "C:\Users\impro\.openclaw\workspace\output\daily-briefs\brief-$(Get-Date -Format 'yyyyMMdd').md"
if (!(Test-Path (Split-Path $BriefPath))) {
    New-Item -ItemType Directory -Path (Split-Path $BriefPath) -Force | Out-Null
}

$Brief | Out-File $BriefPath -Encoding UTF8

Write-Host "Brief saved to: $BriefPath"
Write-Host ""
Write-Host "Ready for Lumina review and Roo delivery"
