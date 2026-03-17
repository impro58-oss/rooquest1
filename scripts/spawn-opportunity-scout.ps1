# Spawn Opportunity Scout Agent
# Research agent for daily business opportunity hunting

param(
    [string]$WorkingDir = "C:\Users\impro\.openclaw\workspace"
)

$AgentConfig = "$WorkingDir\agents\opportunity-scout.md"

Write-Host "=== SPAWNING OPPORTUNITY SCOUT AGENT ===" -ForegroundColor Cyan
Write-Host "Config: $AgentConfig" -ForegroundColor Gray
Write-Host ""

# Check if config exists
if (-not (Test-Path $AgentConfig)) {
    Write-Error "Agent config not found: $AgentConfig"
    exit 1
}

# Read the agent configuration
$AgentPrompt = Get-Content $AgentConfig -Raw

Write-Host "Agent Configuration Loaded:" -ForegroundColor Green
Write-Host "  Name: opportunity-scout" -ForegroundColor White
Write-Host "  Role: Daily Opportunity Research" -ForegroundColor White
Write-Host "  Focus: Micro-SaaS, Digital Products, Service Arbitrage" -ForegroundColor White
Write-Host ""

Write-Host "=== ACTIVATION INSTRUCTIONS ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "To activate this agent in Telegram:" -ForegroundColor White
Write-Host "  'Activate Opportunity Scout. Find today's business opportunities.'" -ForegroundColor Cyan
Write-Host ""
Write-Host "Or:" -ForegroundColor White
Write-Host "  'Opportunity mode. Research micro-SaaS ideas for traders.'" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== AGENT READY ===" -ForegroundColor Green
Write-Host ""
Write-Host "The agent will:" -ForegroundColor White
Write-Host "  - Research 3-5 opportunities daily" -ForegroundColor Gray
Write-Host "  - Deep-dive on top 1-2" -ForegroundColor Gray
Write-Host "  - Output structured reports to memory/YYYY-MM-DD.md" -ForegroundColor Gray
Write-Host "  - Include effort, capital, timeline, and unfair advantage analysis" -ForegroundColor Gray
Write-Host ""

# Log activation
$LogEntry = @"
## Entry $(Get-Date -Format 'HH:mm') - Opportunity Scout Agent Activated

**Agent:** opportunity-scout
**Status:** Active
**Focus:** Micro-SaaS, Digital Products, Service Arbitrage
**Schedule:** Daily research, report to memory files

**Activation Command:**
> Activate Opportunity Scout. Find today's business opportunities.

**Research Domains:**
1. Micro-SaaS for traders (calculators, screeners, alerts)
2. Digital products (Notion templates, spreadsheets, guides)
3. Service arbitrage (research-as-a-service, due diligence)
4. Information monetization (newsletters, data feeds, communities)

**Output Format:**
- Opportunity name and type
- Effort/capital/timeline estimates
- Market analysis and competition
- Your unfair advantage assessment
- Execution plan and risk analysis
- Verdict with confidence level

---
"@

$MemoryFile = "$WorkingDir\memory\$(Get-Date -Format 'yyyy-MM-dd').md"
Add-Content -Path $MemoryFile -Value $LogEntry -Encoding UTF8

Write-Host "Activation logged to: $MemoryFile" -ForegroundColor Gray
