# HEARTBEAT.md - Daily Check Tasks

## Daily Checks (Rotate through these)

### Morning (08:00-10:00)
- [ ] Check calendar for today's events
- [ ] Review ACTIVE.md for priority tasks
- [ ] Run backup script if not done today
- [ ] Check for any urgent messages
- [ ] **Sync group contexts** - Check crypto/polymarket groups for updates

### Afternoon (14:00-16:00)
- [ ] Review project progress
- [ ] Update task statuses
- [ ] Check income tracker for new opportunities
- [ ] **Sync group contexts** - Pull latest from all groups

### Evening (18:00-20:00)
- [ ] Summarize day's work to memory file
- [ ] Update MEMORY.md with key insights
- [ ] Prepare tomorrow's priorities
- [ ] **Final group sync** - Ensure all decisions logged

## Every 30 Minutes (Automated)
- [ ] **Group Sync Check** - Scan for new messages in crypto/polymarket groups
- [ ] Push important decisions to memory/YYYY-MM-DD.md
- [ ] Tag with [CRYPTO], [POLY], [SYSTEM], or [DECISION]

## Weekly (Sundays)
- [ ] Review and archive completed tasks
- [ ] Update project statuses
- [ ] Review income tracker
- [ ] Clean up old backups
- [ ] **Archive old group sync entries** (keep last 7 days active)

## Automation
- Daily backup runs automatically via scheduled task
- Git commits pushed weekly
- Group sync runs every 30 minutes via heartbeat

## Group Sync Protocol
**Purpose:** Bridge knowledge across Direct Chat, Crypto Group, Polymarket Group
**Mechanism:** Read/write to memory/YYYY-MM-DD.md with [GROUP] SYNC: entries
**Format:** See GROUP_SYNC_PROTOCOL.md for details

---
*If nothing needs attention, reply: HEARTBEAT_OK*
