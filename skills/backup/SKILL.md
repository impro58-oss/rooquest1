# Backup Skill

Automated workspace backup with git commits, file snapshots, and cloud sync.

## Commands

```bash
# Run backup now
backup run

# Schedule daily backups
backup schedule --daily --time 02:00

# Backup specific directories
backup dir memory/
backup dir skills/
backup dir agents/

# Check backup status
backup status

# Restore from backup
backup restore --date 2026-03-17
```

## Features

- **Git Auto-Commit:** Daily commits of workspace changes
- **File Snapshots:** ZIP archives of critical directories
- **Cloud Sync:** Optional sync to cloud storage (OneDrive, Dropbox)
- **Retention:** Auto-delete backups older than 30 days
- **Verification:** Check backup integrity

## Configuration

Config file: `~/.openclaw/skills/backup/config.json`

```json
{
  "schedule": {
    "enabled": true,
    "frequency": "daily",
    "time": "02:00"
  },
  "directories": [
    "memory/",
    "skills/",
    "agents/",
    "scripts/",
    "data/"
  ],
  "git": {
    "autoCommit": true,
    "commitMessage": "Daily backup - {{date}}"
  },
  "retention": {
    "days": 30
  }
}
```

## Output

```
Backup Report - 2026-03-17 02:00
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Git commit: 47 files changed
✅ Memory snapshot: memory-2026-03-17.zip (2.3MB)
✅ Skills snapshot: skills-2026-03-17.zip (1.1MB)
✅ Total size: 15.7MB
✅ Backup location: ~/.openclaw/backups/
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status: SUCCESS
```