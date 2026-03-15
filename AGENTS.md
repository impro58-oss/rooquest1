# Agent Orchestration Framework - Option A (Simple Control)
# All agents report to memory, Lumina compiles daily brief

## AGENT REPORTING PROTOCOL

### 1. Agent Completion Report Template

Every agent MUST write to `memory/YYYY-MM-DD.md` using this format:

```markdown
## Entry HH:MM - [AGENT NAME] Task Complete

**Agent:** [agent-name]
**Task:** [brief description]
**Status:** [completed/partial/failed]
**Runtime:** [duration]

### Summary
[2-3 sentence overview of findings]

### Key Findings
- [bullet 1]
- [bullet 2]
- [bullet 3]

### Data/Files Created
- [file path 1]
- [file path 2]

### Notion Updates
- Database: [name]
- Entries: [count]

### Recommendations
- [Action item 1]
- [Action item 2]

### Confidence Level
[High/Medium/Low] - [reasoning]

### Next Steps
[What should happen next]

---
```

### 2. Agent Status Tracking

**Active Agents:**
- neurovascular-upstream-director: [status]
- [future agents listed here]

**Last Check-in:** [timestamp]
**Pending Tasks:** [count]
**Completed Today:** [count]

### 3. Daily Brief Compilation

**Time:** 6:30 AM daily
**Compiled by:** Lumina
**Includes:**
- All agent activity from previous 24h
- Key findings summary
- Recommended actions
- Escalation items (if any)

### 4. Control Gates

**NO autonomous actions without approval:**
- No external outreach
- No financial transactions
- No commitments or contracts
- No database deletions

**Lumina reviews all agent outputs before presenting to Roo**

### 5. Escalation Triggers

**Immediate alert to Roo:**
- High-confidence opportunity (>80%)
- Critical error or failure
- Time-sensitive finding
- Unexpected result

**Batch in daily brief:**
- Routine analysis complete
- Background research
- Data updates
- Monitoring reports

---

## AGENT REGISTRY

| Agent Name | Role | Status | Last Active | Output Location |
|------------|------|--------|-------------|-----------------|
| neurovascular-upstream-director | MedTech Strategy | Active | 2026-03-15 14:46 | memory/2026-03-15.md |
| [pending] | Stockward BD | Pending | - | - |
| [pending] | LUXBRIDGE Research | Pending | - | - |

---

## DAILY BRIEF TEMPLATE

```markdown
# Daily Agent Activity Brief - [DATE]

## Summary
[X] agents active, [Y] tasks completed, [Z] findings requiring review

## Agent Reports

### 1. [Agent Name]
**Task:** [what they did]
**Key Finding:** [most important result]
**Recommendation:** [what Lumina suggests]
**Action Required:** [yes/no - what]

### 2. [Next Agent]
...

## Priority Actions
1. [Highest priority item]
2. [Second priority]
3. [Third priority]

## Escalations
- [None / list items needing immediate attention]

## System Health
- All agents: [operational/degraded/offline]
- Scheduled tasks: [running/on time/delayed]
- Data sync: [current/stale]

---
Compiled by Lumina at [TIME]
```
