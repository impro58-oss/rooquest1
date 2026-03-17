# OPENCLAW SYSTEM RESTART PROTOCOL
## Quick Recovery Guide for Roo

**Last Updated:** 2026-03-14 22:07 UTC
**Systems Active:** Crypto Intelligence, Scheduled Tasks, Notion Integration

---

## ⚡ 30-SECOND STATUS CHECK

Open PowerShell and run:
```powershell
openclaw status
```

**If you see:**
- ✅ "Gateway: healthy" → Continue to Step 2
- ❌ "Gateway: unreachable" → Run Step 1

---

## 🔧 STEP 1: START GATEWAY (If Down)

**Option A - Quick Start:**
```powershell
openclaw gateway start
```

**Option B - Full Recovery (if Option A fails):**
```powershell
# Kill any stuck processes
Get-Process | Where-Object {$_.ProcessName -like "*openclaw*"} | Stop-Process -Force

# Start fresh
openclaw gateway start

# Verify
openclaw status
```

**Wait 10 seconds, then check:** http://127.0.0.1:18789/

---

## 📊 STEP 2: VERIFY CRYPTO INTELLIGENCE SYSTEM

**Check if scheduled task is running:**
```powershell
Get-ScheduledTask -TaskName "TrojanLogic4H Auto Scanner" | Select-Object State, LastRunTime, NextRunTime
```

**If State = "Ready" → ✅ System is active**

**Schedule:** Every 3 hours (00:00, 03:00, 06:00, 09:00, 12:00, 15:00, 18:00, 21:00 UTC)

**If missing or Disabled:**
```powershell
# Re-create the task (run as Administrator)
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2\setup_auto_scan.ps1"
```

---

## 🔄 STEP 3: MANUAL SCAN (If You Need Data NOW)

**Run immediate analysis:**
```powershell
cd C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2
& "C:\Users\impro\AppData\Local\Programs\Python\Python311\python.exe" analyze_top_50.py
```

**Log results to Notion:**
```powershell
& "C:\Users\impro\AppData\Local\Programs\Python\Python311\python.exe" log_to_intelligence.py
```

---

## 📋 QUICK REFERENCE: ALL SYSTEMS

### **Critical URLs**
| System | URL |
|--------|-----|
| OpenClaw Dashboard | http://127.0.0.1:18789/ |
| Crypto Visual Dashboard | https://notion.so/3230491758dd819c90e4fce960777521 |
| Crypto Intelligence DB | https://notion.so/3230491758dd81d8a31efe277bf4b0d1 |
| Roo Control Room | https://notion.so/3230491758dd80a08614d4808e0af030 |

### **File Locations**
```
C:\Users\impro\.openclaw\workspace\                    # Main workspace
C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2\  # Crypto system
C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2\logs\  # Scan logs
C:\Users\impro\.openclaw\openclaw.json                 # Config file
```

### **Key Commands**
```powershell
# Check everything
openclaw status

# Start gateway
openclaw gateway start

# Stop gateway
openclaw gateway stop

# Restart gateway
openclaw gateway restart

# Check scheduled task
Get-ScheduledTask -TaskName "TrojanLogic4H Auto Scanner"

# Run task manually
Start-ScheduledTask -TaskName "TrojanLogic4H Auto Scanner"

# View recent logs
Get-Content "C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2\logs\auto_scan_$(Get-Date -Format 'yyyyMM').log" -Tail 50
```

---

## 🚨 TROUBLESHOOTING

### **Problem: "openclaw" command not found**
**Fix:**
```powershell
# Find openclaw
where.exe openclaw

# If not found, reinstall
npm install -g openclaw
```

### **Problem: Python scripts fail**
**Fix:**
```powershell
# Verify Python
& "C:\Users\impro\AppData\Local\Programs\Python\Python311\python.exe" --version

# Should show: Python 3.11.x
```

### **Problem: Notion logging fails**
**Check:**
- Notion token exists: `C:\Users\impro\.config\notion\api_key`
- Database accessible: https://notion.so/3230491758dd81d8a31efe277bf4b0d1

### **Problem: Scheduled task won't run**
**Check permissions:**
```powershell
# Run as Administrator, then:
Get-ScheduledTaskInfo -TaskName "TrojanLogic4H Auto Scanner"
```

---

## 📱 TELEGRAM GROUP ACCESS

**If group bot not responding:**
1. Check OpenClaw gateway is running
2. Verify `openclaw.json` has `"groupPolicy": "open"`
3. Restart gateway: `openclaw gateway restart`

---

## 🎯 DAILY CHECKLIST (Optional)

**Morning (08:00):**
- [ ] Check overnight scans in Notion
- [ ] Review any FUTURES opportunities
- [ ] Verify scheduled task ran

**Evening (20:00):**
- [ ] Check day's accumulated data
- [ ] Review trend analysis
- [ ] Confirm next scan scheduled

---

## 💾 BACKUP REMINDER

**Workspace backed up to:**
- GitHub: https://github.com/impro58-oss/rooquest1
- Local: `C:\Users\impro\.openclaw\workspace\`

**To push latest changes:**
```powershell
cd C:\Users\impro\.openclaw\workspace
git add .
git commit -m "Update $(Get-Date -Format 'yyyy-MM-dd')"
git push
```

---

## 🆘 EMERGENCY CONTACT

**If all else fails:**
1. Check this file: `C:\Users\impro\.openclaw\workspace\RESTART_PROTOCOL.md`
2. Review logs: `C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2\logs\`
3. Check memory: `C:\Users\impro\.openclaw\workspace\memory\2026-03-14.md`

---

**Protocol Version:** 1.0
**Created:** 2026-03-14
**Systems Covered:** OpenClaw Gateway, TrojanLogic4H Crypto Scanner, Notion Integration, Scheduled Tasks
