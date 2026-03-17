# POWER-CUT RESILIENCE SYSTEM
## Complete Auto-Recovery for RooQuest

**Created:** 2026-03-15 00:00 UTC
**Purpose:** Ensure system comes back online automatically after power cut or restart

---

## 🎯 WHAT HAPPENS AFTER POWER CUT

### **Automatic (No Action Needed):**
1. ✅ Windows boots normally
2. ✅ Scheduled tasks resume (Task Scheduler)
3. ✅ OpenClaw gateway **auto-starts** (NEW!)
4. ✅ Crypto scans continue every 3 hours
5. ✅ Data commits to GitHub
6. ✅ I come online automatically

### **Manual (Only if auto-start fails):**
1. Run: `openclaw gateway start`
2. Or: Run recovery script

---

## 🛡️ RESILIENCE LAYERS

### **Layer 1: Gateway Auto-Start** ✅ NEW

**Task:** `OpenClaw Gateway Auto-Start`
**Trigger:** At system startup
**Action:** Runs `auto-start-gateway.ps1`
**Result:** Gateway starts within 2 minutes of boot

**Setup:**
```powershell
# Run as Administrator
& "C:\Users\impro\.openclaw\workspace\scripts\setup-gateway-autostart.ps1"
```

---

### **Layer 2: Scheduled Tasks** ✅ EXISTING

| Task | Frequency | Survives Reboot |
|------|-----------|-----------------|
| TrojanLogic4H Auto Scanner | Every 3 hours | ✅ Yes |
| OpenClaw Gateway Monitor | Every 5 minutes | ✅ Yes |
| OpenClaw Self-Heal | Every 5 minutes | ✅ Yes |
| Workspace Auto-Commit | Every 2 hours | ✅ Yes |

**All resume automatically on Windows startup**

---

### **Layer 3: Data Persistence** ✅ EXISTING

| Data | Location | Survives Power Cut |
|------|----------|-------------------|
| Crypto scans | `data/crypto/` | ✅ Yes (disk) |
| GitHub backup | `github.com/impro58-oss/rooquest1` | ✅ Yes (cloud) |
| Memory files | `memory/` | ✅ Yes (disk) |
| Configs | `.openclaw/` | ✅ Yes (disk) |

---

### **Layer 4: Recovery Scripts** ✅ NEW

**Quick Recovery:**
```powershell
# One-command recovery
& "C:\Users\impro\.openclaw\workspace\scripts\system-recovery.ps1"
```

**Full Recovery:**
```powershell
# Reinstalls everything
& "C:\Users\impro\.openclaw\workspace\scripts\system-recovery.ps1" -FullRecovery
```

---

## 📋 SETUP CHECKLIST

**Run these as Administrator:**

```powershell
# 1. Gateway auto-start (ESSENTIAL)
& "C:\Users\impro\.openclaw\workspace\scripts\setup-gateway-autostart.ps1"

# 2. Workspace auto-commit (RECOMMENDED)
& "C:\Users\impro\.openclaw\workspace\scripts\setup-auto-commit-task.ps1"

# 3. Crypto scanner (if not done)
& "C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2\setup_auto_scan.ps1"
```

**Verify all tasks:**
```powershell
Get-ScheduledTask | Where-Object { $_.TaskName -like '*OpenClaw*' -or $_.TaskName -like '*Trojan*' }
```

**Should show 4+ tasks:**
- OpenClaw Gateway Auto-Start
- OpenClaw Gateway Monitor
- OpenClaw Self-Heal
- TrojanLogic4H Auto Scanner
- OpenClaw Workspace Auto-Commit

---

## 🧪 TESTING

**Simulate Power Cut:**
1. Restart computer
2. Wait 2-3 minutes
3. Check: `openclaw status`
4. Should show: "Gateway: healthy"

**If not:**
1. Check Task Scheduler: `taskschd.msc`
2. Look for failed tasks
3. Run recovery script

---

## 📊 MONITORING

**Check System Health:**
```powershell
# Quick check
& "C:\Users\impro\.openclaw\workspace\scripts\auto-start-gateway.ps1" -CheckOnly

# Full diagnostic
& "C:\Users\impro\.openclaw\workspace\scripts\system-recovery.ps1"
```

**View Logs:**
```powershell
# Recovery logs
Get-Content "C:\Users\impro\.openclaw\workspace\logs\system-recovery-*.log" -Tail 50

# Auto-commit logs
Get-Content "C:\Users\impro\.openclaw\workspace\logs\auto-commit-*.log" -Tail 20

# Gateway logs
Get-Content "C:\Users\impro\.openclaw\logs\gateway-monitor.log" -Tail 20
```

---

## 🚨 TROUBLESHOOTING

### **Gateway Won't Auto-Start**

**Check:**
```powershell
Get-ScheduledTask -TaskName "OpenClaw Gateway Auto-Start"
```

**Fix:**
```powershell
# Reinstall task
& "C:\Users\impro\.openclaw\workspace\scripts\setup-gateway-autostart.ps1"
```

---

### **Scheduled Tasks Missing**

**Fix:**
```powershell
# Full recovery
& "C:\Users\impro\.openclaw\workspace\scripts\system-recovery.ps1" -FullRecovery
```

---

### **Data Not Syncing to GitHub**

**Check:**
```powershell
cd C:\Users\impro\.openclaw\workspace
git status
```

**Fix:**
```powershell
# Manual sync
git add -A
git commit -m "Manual sync"
git push
```

---

## 💾 BACKUP SUMMARY

**Every 2 hours:**
- ✅ Workspace auto-commits to GitHub
- ✅ All code, scripts, data backed up

**Every 4 hours:**
- ✅ Crypto scans run
- ✅ Data saved locally + GitHub

**Every 5 minutes:**
- ✅ Gateway health checked
- ✅ Auto-restart if failed

**On boot:**
- ✅ Gateway auto-starts
- ✅ All scheduled tasks resume

---

## 🎯 SUCCESS CRITERIA

**System is resilient when:**
- ✅ Gateway starts automatically after boot
- ✅ Scheduled tasks run without manual intervention
- ✅ Data syncs to GitHub within 2 hours of changes
- ✅ Recovery script fixes most issues in one command
- ✅ You can be away for days and system keeps running

---

## 📞 EMERGENCY CONTACTS

**If everything fails:**
1. Check: `RESTART_PROTOCOL.md`
2. Check: `QUICK_RESTART_CARD.txt`
3. Check: `BACKUP_STRATEGY.md`
4. Run: `system-recovery.ps1 -FullRecovery`

---

**Your system is now power-cut proof!** 🛡️⚡
