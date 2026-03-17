# daily-intelligence-cron.ps1
# Creates daily 6:30 AM intelligence brief cron job

$cronJob = @{
    name = "daily-intelligence-brief"
    schedule = @{
        kind = "cron"
        cron = "30 6 * * *"
        timezone = "Europe/Dublin"
    }
    payload = @{
        kind = "agentTurn"
        message = @"
DAILY INTELLIGENCE BRIEF - 6:30 AM

Tasks:
1. Check neurovascular industry news (use blogwatcher skill)
2. Review Stockward research priorities
3. Check Notion for urgent tasks
4. Summarize findings
5. Send brief to Telegram

Be concise. Focus on actionable intelligence.
"@
    }
    sessionTarget = "isolated"
    delivery = @{
        mode = "announce"
        channel = "telegram"
        to = "1018254667"
    }
    agentId = "main"
} | ConvertTo-Json -Depth 10

Write-Host "Creating daily intelligence cron job..."
Write-Host "Schedule: 6:30 AM daily (Europe/Dublin)"
Write-Host ""
Write-Host "To install, run:"
Write-Host "openclaw cron add --name 'daily-intelligence-brief' --cron '30 6 * * *' --tz 'Europe/Dublin' --session isolated --message 'Daily intelligence brief' --announce --channel telegram --to '1018254667'"
