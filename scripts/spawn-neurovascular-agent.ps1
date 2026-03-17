# Spawn Neurovascular Upstream Marketing Director Agent
# This agent provides strategic analysis for neurovascular medtech opportunities

param(
    [string]$Task = "Analyze current neurovascular market landscape and identify top 3 unmet opportunities"
)

$AgentConfig = @{
    Name = "neurovascular-upstream-director"
    Role = "Upstream Marketing Director - Neurovascular MedTech"
    PromptFile = "C:\Users\impro\.openclaw\workspace\agents\neurovascular-upstream-director.md"
    KnowledgeBase = "C:\Users\impro\Documents\Reading\Neuro"
    NotionDatabase = "32304917-58dd-81c7-874a-faea129de1bd"  # Stockward Research
    OutputDir = "C:\Users\impro\.openclaw\workspace\output\neurovascular"
}

# Ensure output directory exists
if (!(Test-Path $AgentConfig.OutputDir)) {
    New-Item -ItemType Directory -Path $AgentConfig.OutputDir -Force | Out-Null
}

$Timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
$OutputFile = "$($AgentConfig.OutputDir)\analysis-$Timestamp.md"

Write-Host "=== SPAWNING NEUROVASCULAR UPSTREAM DIRECTOR ==="
Write-Host "Task: $Task"
Write-Host "Output: $OutputFile"
Write-Host ""

# Load agent prompt
$SystemPrompt = Get-Content $AgentConfig.PromptFile -Raw

# Create task prompt
$TaskPrompt = @"
$SystemPrompt

CURRENT TASK:
$Task

AVAILABLE KNOWLEDGE:
- Neurovascular PDFs: $($AgentConfig.KnowledgeBase)
- Patent databases (via web search)
- Market reports (via web search)
- Clinical trial databases

OUTPUT REQUIREMENTS:
Follow the 7-section output structure defined in your system role.
Save analysis to: $OutputFile
Log key findings to Notion database: $($AgentConfig.NotionDatabase)

Begin analysis.
"@

# Save task prompt for reference
$TaskPrompt | Out-File "$($AgentConfig.OutputDir)\task-prompt-$Timestamp.txt"

Write-Host "Agent prompt saved. Ready for execution."
Write-Host ""
Write-Host "To execute manually:"
Write-Host "  1. Load prompt from: $($AgentConfig.PromptFile)"
Write-Host "  2. Provide task: $Task"
Write-Host "  3. Save output to: $OutputFile"

# Return config for OpenClaw integration
return $AgentConfig
