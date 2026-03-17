# OpenClaw Slash Commands Reference
## Complete Command Guide for Roo's Workspace

---

## 🎯 Core Commands

| Command | Description | Usage | Example |
|---------|-------------|-------|---------|
| `/new` | Start fresh session (reset context) | `/new` | Clear conversation |
| `/reset` | Alias for /new | `/reset` | Same as above |
| `/status` | Show system status | `/status` | Check gateway health |
| `/reasoning` | Toggle reasoning mode | `/reasoning on` | Enable detailed thinking |

---

## 🤖 Agent Commands

| Command | Description | Usage | Output |
|---------|-------------|-------|--------|
| `/agent` | List active agents | `/agent list` | Shows all agents |
| `/agent spawn` | Create new agent | `/agent spawn [name]` | Spawns sub-agent |
| `/agent status` | Check agent health | `/agent status [name]` | Agent state |
| `/sync` | Sync with agent | `/sync [agent-name]` | Pull latest from agent |

---

## 💰 Crypto & Trading Commands

| Command | Description | Usage | Example |
|---------|-------------|-------|---------|
| `/crypto scan` | Run TrojanLogic4H scan | `/crypto scan` | Top 50 analysis |
| `/crypto status` | Check scan status | `/crypto status` | Last run results |
| `/polymarket` | Check bets | `/polymarket status` | P&L summary |
| `/income` | Research opportunities | `/income search [query]` | Find methods |

---

## 🏥 Research Commands

| Command | Description | Usage | Example |
|---------|-------------|-------|---------|
| `/research` | Web research | `/research [topic]` | Auto research |
| `/pdf extract` | Extract PDF text | `/pdf extract [file]` | Text output |
| `/pdf tables` | Extract tables | `/pdf tables [file]` | CSV output |
| `/neurovascular` | Medtech research | `/neurovascular search` | Find opportunities |

---

## 🔧 System Commands

| Command | Description | Usage | Example |
|---------|-------------|-------|---------|
| `/health` | Run health check | `/health` | System status |
| `/health gateway` | Check gateway | `/health gateway` | Port status |
| `/health disk` | Check disk space | `/health disk` | Storage report |
| `/backup` | Run backup | `/backup now` | Git + snapshots |
| `/backup status` | Check backups | `/backup status` | Last commit info |

---

## 📊 Notion Commands

| Command | Description | Usage | Example |
|---------|-------------|-------|---------|
| `/notion sync` | Sync to Notion | `/notion sync` | Update databases |
| `/notion task` | Create task | `/notion task [name]` | Add to Tasks |
| `/notion project` | Create project | `/notion project [name]` | Add to Projects |
| `/control-room` | Open control room | `/control-room` | Show dashboard |

---

## 🎭 Persona Commands

| Command | Description | Usage | Context |
|---------|-------------|-------|---------|
| `/persona scout` | Opportunity Scout | `/persona scout` | Income research |
| `/persona stockward` | BD Director | `/persona stockward` | Partnerships |
| `/persona medtech` | Neurovascular | `/persona medtech` | Medtech research |
| `/persona crypto` | Crypto Analyst | `/persona crypto` | Trading signals |
| `/sync me up` | Sync context | `/sync me up` | Resume where left off |

---

## ⏰ Automation Commands

| Command | Description | Usage | Example |
|---------|-------------|-------|---------|
| `/cron add` | Add scheduled job | `/cron add [name]` | Schedule task |
| `/cron list` | List jobs | `/cron list` | Show all jobs |
| `/cron status` | Check job status | `/cron status [name]` | Job health |
| `/schedule backup` | Schedule backup | `/schedule backup daily` | Auto backup |
| `/schedule health` | Schedule health | `/schedule health 30m` | Every 30 min |

---

## 🌐 Web Commands

| Command | Description | Usage | Example |
|---------|-------------|-------|---------|
| `/browse` | Open browser | `/browse [url]` | Visit site |
| `/fetch` | Fetch webpage | `/fetch [url]` | Get content |
| `/search` | Web search | `/search [query]` | Brave search |
| `/monitor` | Monitor site | `/monitor [url]` | Change detection |

---

## 💾 Memory Commands

| Command | Description | Usage | Example |
|---------|-------------|-------|---------|
| `/memory` | Show memory | `/memory today` | Today's log |
| `/memory search` | Search memory | `/memory search [term]` | Find entries |
| `/log` | Log to memory | `/log [message]` | Save entry |
| `/archive` | Archive old logs | `/archive` | Clean up |

---

## 🆘 Help Commands

| Command | Description | Usage | Output |
|---------|-------------|-------|--------|
| `/help` | Show help | `/help` | Command list |
| `/help [skill]` | Skill help | `/health help` | Health docs |
| `/skills` | List skills | `/skills` | All skills |
| `/tools` | List tools | `/tools` | Available tools |

---

## 🚀 Quick Reference

### Most Used Commands
```
/sync me up          - Resume session
/health               - System check
/backup               - Run backup
/crypto scan          - Run analysis
/research [topic]     - Web research
```

### Agent Workflow
```
/persona [name]       - Activate persona
[do work]
/sync me up           - Save context
```

### Emergency Commands
```
/status               - Check system
/health gateway       - Check gateway
/backup status        - Check backups
```

---

## 📋 Implementation Status

| Command | Status | Notes |
|---------|--------|-------|
| Core commands | ✅ Ready | Built-in |
| Health check | ✅ Ready | New skill |
| Backup | ✅ Ready | New skill |
| Web research | ✅ Ready | New skill |
| PDF tools | ✅ Ready | New skill |
| Advanced cron | ✅ Ready | New skill |
| Persona sync | ✅ Ready | Notion integration |
| Agent spawn | ⚠️ Partial | Manual only |

---

*Last Updated: 2026-03-17*
*Version: 1.0*
