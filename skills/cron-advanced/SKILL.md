# Advanced Cron Skill

Enhanced scheduling with retry logic, dependencies, error handling, and monitoring.

## Commands

```bash
# Create advanced cron job
cron-advanced add --name "Crypto Scan" --command "python scan.py" --schedule "0 */4 * * *" --retry 3

# Add job with dependencies
cron-advanced add --name "Report" --command "generate.py" --after "Crypto Scan" --schedule "0 6 * * *"

# Monitor job status
cron-advanced status

# View job logs
cron-advanced logs --name "Crypto Scan" --lines 50

# Pause/resume jobs
cron-advanced pause --name "Crypto Scan"
cron-advanced resume --name "Crypto Scan"

# Job dependencies
cron-advanced depends --name "Report" --requires "Crypto Scan,Backup"
```

## Features

- **Retry Logic:** Auto-retry failed jobs (3 attempts by default)
- **Dependencies:** Job B waits for Job A to complete
- **Error Handling:** Continue on error or stop pipeline
- **Notifications:** Telegram alerts on failure/success
- **Logging:** Detailed execution logs with timestamps
- **Health Dashboard:** Web UI for job status
- **Concurrency Control:** Limit parallel jobs

## Configuration

Config file: `~/.openclaw/skills/cron-advanced/config.json`

```json
{
  "jobs": [
    {
      "name": "Crypto Scan",
      "command": "python skills/tradingview-claw-v2/analyze_top_50.py",
      "schedule": "0 */4 * * *",
      "retry": 3,
      "timeout": 300,
      "notify": {
        "onFailure": true,
        "onSuccess": false
      }
    },
    {
      "name": "Health Check",
      "command": "healthcheck run",
      "schedule": "*/30 * * * *",
      "dependsOn": []
    }
  ],
  "global": {
    "maxParallel": 2,
    "defaultTimeout": 600,
    "logRetention": "7d"
  }
}
```

## Output

```
Cron Dashboard - 2026-03-17 15:30
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Job                Status    Last Run    Next Run    Success
─────────────────────────────────────────────────────────
Crypto Scan        ✅ Active  12:00       16:00       98%
Health Check       ✅ Active  15:30       16:00       100%
Backup             ✅ Active  02:00       02:00+1d    100%
Report             ⏸️  Paused  06:00       --          95%
─────────────────────────────────────────────────────────
Queue: 0 pending | Running: 1 | Failed (24h): 0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```