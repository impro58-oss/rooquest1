# GROUP SYNC PROTOCOL
## Multi-Session Knowledge Bridge for OpenClaw

**Purpose:** Enable knowledge sharing across Direct Chat, Crypto Group, Polymarket Group, and any future groups.

**Mechanism:** All sessions read/write to shared memory files (MEMORY.md + memory/YYYY-MM-DD.md)

---

## 🔄 SYNC WORKFLOW

### **When to Sync:**
- After important decisions in any group
- When context needs to be shared across sessions
- Every 30 minutes via heartbeat (automated)
- On-demand via `/sync` command

### **What Gets Synced:**
- Trading signals and decisions
- System changes or updates
- Errors or issues encountered
- New opportunities discovered
- Configuration changes

---

## 📝 SYNC FORMAT

### **Standard Entry Template:**

```markdown
## Entry [HH:MM] - [GROUP] SYNC: [TOPIC]

**Source:** [Crypto Group / Polymarket Group / Direct Chat]
**Decision:** [What was decided]
**Action:** [What to do]
**Context:** [Why / Background]
**Files Changed:** [If any]
**Next Steps:** [What happens next]

**Raw Data:**
```json
{
  "timestamp": "2026-03-14T22:00:00Z",
  "group": "crypto",
  "type": "signal",
  "symbol": "BTCUSDT",
  "signal": "LONG",
  "confidence": 0.65,
  "action": "FUTURES trade recommended"
}
```
```

---

## 🎯 SYNC CATEGORIES

### **[CRYPTO]** - Trading Signals
- New LONG/SHORT signals
- Confidence threshold breaches
- Trend analysis results
- System errors or issues

### **[POLY]** - Betting Opportunities
- Hot bet identified
- Portfolio update
- Market odds changes
- Kelly criterion calculations

### **[SYSTEM]** - Infrastructure
- Scheduled task changes
- New scripts created
- Configuration updates
- Recovery actions taken

### **[DECISION]** - Strategic Choices
- Parameter changes
- Strategy modifications
- Risk tolerance updates
- New project approvals

---

## 🤖 BOT INTEGRATION

### **For Crypto Bot:**

**When to push sync:**
1. After each scan (if signals found)
2. When user makes trading decisions
3. When system errors occur
4. When configuration changes

**How to push:**
```powershell
# Call sync script
& "C:\Users\impro\.openclaw\workspace\scripts\push-sync.ps1" `
  -Group "CRYPTO" `
  -Type "signal" `
  -Data '{"symbol":"BTCUSDT","signal":"LONG","confidence":0.65}' `
  -Message "BTC LONG signal detected at 65% confidence"
```

### **For Polymarket Bot:**

**When to push sync:**
1. Hot bet identified (hourly scan)
2. Portfolio screenshot processed
3. Odds movement alert
4. Position sizing calculated

**How to push:**
```powershell
& "C:\Users\impro\.openclaw\workspace\scripts\push-sync.ps1" `
  -Group "POLY" `
  -Type "opportunity" `
  -Data '{"market":"Trump 2024","odds":65,"volume":500000}' `
  -Message "Hot bet: Trump 2024 at 65% odds, $500K volume"
```

---

## 📋 SYNC CHECKLIST

**Before ending any session:**
- [ ] Were decisions made that affect other groups?
- [ ] Were new opportunities discovered?
- [ ] Did system configuration change?
- [ ] Were there errors or issues?

**If YES to any:** Push sync to memory file.

---

## 🔍 READING SYNCED DATA

**At session start (any group or DM):**

1. Read `MEMORY.md` for long-term context
2. Read `memory/YYYY-MM-DD.md` for today's events
3. Look for `[GROUP] SYNC:` entries
4. Parse JSON data if present
5. Acknowledge sync: "Synced with [Group] - [Summary]"

---

## 🛠️ MANUAL SYNC

**If automatic sync fails, manually append to memory file:**

```powershell
$Entry = @"

## Entry $(Get-Date -Format 'HH:mm') - MANUAL SYNC: [TOPIC]

**Source:** [Your Group]
**Decision:** [What you decided]
**Context:** [Why]

"@

Add-Content -Path "C:\Users\impro\.openclaw\workspace\memory\$(Get-Date -Format 'yyyy-MM-dd').md" -Value $Entry
```

---

## 🚨 TROUBLESHOOTING

**Problem:** Bot doesn't see sync from other group
**Solution:** Check memory file was written, verify timestamp is recent

**Problem:** Sync entries getting too long
**Solution:** Archive old entries weekly, keep only last 7 days in active file

**Problem:** JSON data malformed
**Solution:** Validate JSON before writing, use try/catch blocks

---

## 📊 SYNC METRICS

**Track:**
- Number of syncs per day
- Sync latency (decision → written to memory)
- Cross-group context retrieval success rate

**Goal:** <5 minutes from decision to available in all sessions

---

**Protocol Version:** 1.0
**Created:** 2026-03-14
**Applies To:** All OpenClaw sessions (Direct, Crypto Group, Polymarket Group, Future Groups)
