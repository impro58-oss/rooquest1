# Health Check Skill

Monitor system health, temperature, disk space, and OpenClaw status. Proactive alerting for issues.

## Commands

```bash
# Run full system health check
healthcheck run

# Check specific component
healthcheck check gateway
healthcheck check disk
healthcheck check temperature
healthcheck check memory

# Schedule automatic checks
healthcheck schedule --interval 30m
```

## Features

- **Gateway Status:** Check if OpenClaw gateway is running, port availability
- **System Resources:** CPU, memory, disk usage
- **Temperature:** Monitor thermal status (if available)
- **Process Health:** Check for zombie processes, memory leaks
- **Alerts:** Send Telegram notifications on critical issues

## Configuration

Config file: `~/.openclaw/skills/healthcheck/config.json`

```json
{
  "interval": 1800,
  "thresholds": {
    "cpu": 80,
    "memory": 85,
    "disk": 90,
    "temperature": 75
  },
  "alerts": {
    "telegram": true,
    "desktop": true
  }
}
```

## Output

```
System Health Report - 2026-03-17 15:30
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Gateway: Running (PID 10916)
✅ Port 18789: Listening
✅ CPU: 12% (Normal)
✅ Memory: 45% (Normal)
⚠️  Disk C: 87% (Warning)
✅ Temperature: 42°C (Normal)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status: HEALTHY (1 warning)
```