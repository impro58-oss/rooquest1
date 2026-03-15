# Polymarket Trading System - Complete File Inventory

**Last Updated:** 2026-03-15 01:18 UTC
**Wallet:** 0x2d8c75c3fcbbFe50f92c2eDb00ab7dcF89578071

---

## 📊 DATA EXPORT FILES (for Hugging Face)

| File | Location | Purpose |
|------|----------|---------|
| `portfolio-data.json` | `C:\Users\impro\.openclaw\workspace\data\` | Live positions, P&L, values |
| `opportunities-data.json` | `C:\Users\impro\.openclaw\workspace\data\` | Hot bets, contrarian plays |
| `dashboard-data.json` | `C:\Users\impro\.openclaw\workspace\data\` | Combined data for viz |
| `index.html` | `C:\Users\impro\.openclaw\workspace\data\` | Standalone HTML dashboard |

**Hugging Face Deployment Folder:**
| File | Location | Purpose |
|------|----------|---------|
| All JSON files | `C:\Users\impro\.openclaw\workspace\huggingface-dashboard\` | Ready for HF Spaces upload |
| `README.md` | `C:\Users\impro\.openclaw\workspace\huggingface-dashboard\` | HF Space documentation |

---

## 🔧 SCRIPTS (in `C:\Users\impro\.openclaw\workspace\scripts\`)

| Script | Purpose | Schedule |
|--------|---------|----------|
| `polymarket-hourly-scanner.ps1` | Scans 6 categories for hot bets | Every hour |
| `contrarian-scanner.ps1` | Finds crowd overconfidence plays | Every hour |
| `quick-flip-scanner.ps1` | Finds scalp opportunities | Every hour |
| `polymarket-alert-telegram.ps1` | Sends Telegram alerts | On demand |
| `polymarket-cron-runner.ps1` | Orchestrates hourly scans | Every hour |
| `update-notion-next-bets.ps1` | Updates Notion + sends alerts | Every hour |
| `monitor-bet-confirmations.ps1` | Reminds to place confirmed bets | Every 15 min |
| `fetch-polymarket-portfolio.ps1` | Live portfolio via Data API | On demand |
| `position-analyzer.ps1` | Risk flags (stop loss, profit take) | On demand |
| `edge-calculator.ps1` | EV calculator + Kelly sizing | On demand |
| `betting-journal.ps1` | Track performance, ROI, win rate | On demand |
| `data-exporter.ps1` | Exports data to JSON for HF | On demand |
| `export-for-huggingface.ps1` | Prepares HF deployment | On demand |

---

## 📋 DOCUMENTATION (in `C:\Users\impro\.openclaw\workspace\work\`)

| File | Purpose |
|------|---------|
| `POLYMARKET-API-INTEGRATION.md` | API docs, endpoints, wallet info |
| `POLYMARKET-SYSTEM-FILES.md` | This file - complete inventory |

---

## 🗄️ MEMORY FILES (in `C:\Users\impro\.openclaw\workspace\memory\`)

| File | Purpose |
|------|---------|
| `polymarket-positions.md` | Screenshot-based position tracking |
| `betting-journal.csv` | CSV journal of all bets (created on first use) |

---

## 📱 TELEGRAM INTEGRATION

- **Bot Token:** 8758242941:AAFga397u6IC3BqT-n866h2cd_XB1xJYQsw
- **Chat ID:** -5026664389 (Poly2 group)
- **Alerts:** New opportunities, reminders, risk flags

---

## ⏰ SCHEDULED TASKS

| Task | Schedule | Command |
|------|----------|---------|
| Polymarket-Hourly-Scan | Every hour | `polymarket-cron-runner.ps1` |
| Polymarket-Bet-Monitor | Every 15 min | `monitor-bet-confirmations.ps1` |

---

## 🔄 WORKFLOW

1. **Hourly Scan** → Finds opportunities
2. **Telegram Alert** → Sent to Poly2
3. **Notion Update** → "PENDING CONFIRMATION" status
4. **You Confirm** → Check "User Confirmed" in Notion
5. **15-min Reminder** → Telegram nudge to place bet
6. **You Bet** → Place on Polymarket
7. **You Log** → Check "Bet Taken", fill size/price in Notion
8. **Daily Risk** → Position analyzer flags issues

---

## 🚀 HUGGING FACE DEPLOYMENT

**To deploy dashboard:**
1. Go to https://huggingface.co/spaces
2. Create new Space (Gradio or Static)
3. Upload files from `huggingface-dashboard\`
4. Dashboard auto-refreshes with live data

**Data update:**
- Run `data-exporter.ps1` to refresh JSON files
- Copy to HF Space or push to GitHub

---

## 📊 NOTION DATABASES

**Next Bets Database:** 32304917-58dd-81f2-ad8a-c8254af3d9a9
- Columns: Name, Market, Current Odds, Volume, Category, Priority, Status, Date Added, Recommended Position, Estimated Edge, Recommended Bet, User Confirmed, Bet Taken, Bet Size, Entry Price, Notes

---

*System built for research purposes. User makes all trading decisions.*
