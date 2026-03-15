# Crypto Intelligence System - Complete Setup

**Automated crypto analysis with historical tracking, trend detection, and GitHub visualization.**

**Last Updated:** 2026-03-15 01:48 UTC  
**Scan Frequency:** Every 3 hours (8 scans/day)  
**Scope:** Top 50 cryptocurrencies by volume

---

## 🎯 What This System Does

1. **Scans** top 50 cryptocurrencies every 3 hours
2. **Analyzes** using TrojanLogic4H strategy (CS RSI MTF + RtoM Channels)
3. **Logs** all results to Notion database with timestamps
4. **Saves** to GitHub for visualization (Hugging Face dashboard)
5. **Tracks** trends over time to validate signal accuracy
6. **Alerts** Telegram group when opportunities arise

---

## 📁 Files Overview

| File | Purpose |
|------|---------|
| `trojanlogic_4h.py` | Core strategy engine |
| `multi_source_feed.py` | Free data from multiple sources |
| `analyze_top_50.py` | Scan top 50 cryptos |
| `crypto_data_manager.py` | Save to JSON, GitHub export |
| `create_intelligence_db.py` | Create Notion database |
| `log_to_intelligence.py` | Save results to Notion |
| `analyze_trends.py` | Historical trend analysis |
| `auto_crypto_scanner.ps1` | Automated scanner script |
| `setup_auto_scan.ps1` | Setup scheduled task |
| `update-scan-frequency.ps1` | Change scan frequency |

---

## 🚀 Quick Start

### Manual Scan:
```powershell
cd C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2
& "C:\Users\impro\AppData\Local\Programs\Python\Python311\python.exe" analyze_top_50.py
```

### Log Results to Notion:
```powershell
& "C:\Users\impro\AppData\Local\Programs\Python\Python311\python.exe" log_to_intelligence.py
```

### View Trends:
```powershell
& "C:\Users\impro\AppData\Local\Programs\Python\Python311\python.exe" analyze_trends.py
```

---

## ⚙️ Setup Automation

### Option 1: Scheduled Task (Recommended)
```powershell
# Run as Administrator
& "C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2\setup_auto_scan.ps1"
```

This creates a Windows scheduled task that runs every 3 hours automatically.

**Schedule:** 00:00, 03:00, 06:00, 09:00, 12:00, 15:00, 18:00, 21:00 UTC

### Change Scan Frequency:
```powershell
# Run as Administrator
& "C:\Users\impro\.openclaw\workspace\scripts\update-scan-frequency.ps1" -Hours 3
```

---

## 📊 Data Pipeline

### Local Storage:
```
data/crypto/
├── crypto_latest.json          # Latest scan (for HF dashboard)
├── crypto_history.json         # All scans (for trend analysis)
├── huggingface_data.json       # Optimized HF export
└── 2026-03/                    # Monthly archives
    └── 2026-03-15_010000.json  # Individual scan files
```

### GitHub Backup:
- **Repo:** https://github.com/impro58-oss/rooquest1
- **Path:** `data/crypto/`
- **Raw URL:** https://raw.githubusercontent.com/impro58-oss/rooquest1/main/data/crypto/crypto_latest.json

### Notion Databases:
| Resource | URL |
|----------|-----|
| **Visual Dashboard** | https://notion.so/3230491758dd819c90e4fce960777521 |
| **Intelligence Database** | https://notion.so/3230491758dd81d8a31efe277bf4b0d1 |

---

## 🎯 Signal Interpretation

| Indicator | Meaning |
|-----------|---------|
| 🟢 LONG | Buy signal detected |
| 🔴 SHORT | Sell signal detected |
| ⚪ HOLD | No valid setup, wait |
| **STRONG** | 85%+ confidence |
| **MODERATE** | 65-84% confidence |
| **WEAK** | 45-64% confidence |
| **WATCH** | <45% confidence |

### Strategy Classification:
- **FUTURES:** High-confidence trades (65%+, reversal/continuation)
- **HOLD:** Core convictions with signals (BTC, ETH, SOL, XRP, DOGE, BNB, LINK)
- **MONITOR:** Everything else

---

## 📈 Trend Analysis

The system tracks:
- Signal frequency per symbol
- Price changes over time
- CS RSI momentum trends
- Confidence score patterns
- Win/loss validation (manual entry)
- Data from 8 scans per day (56 scans/week)

---

## 🔧 Customization

### Add Telegram Alerts:
Edit `auto_crypto_scanner.ps1`:
```powershell
$TelegramBotToken = "YOUR_BOT_TOKEN"
$TelegramChatId = "YOUR_CHAT_ID"
$SendToTelegram = $true
```

### Change Symbol Count:
Edit `analyze_top_50.py`:
```python
TOP_50 = get_top_50()  # Change to get_top_20() or get_top_100()
```

---

## 📝 Logs

All activity logged to:
```
C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2\logs\auto_scan_YYYYMM.log
C:\Users\impro\.openclaw\workspace\logs\auto-commit-YYYYMM.log
```

---

## 🎓 Strategy Parameters

- **CS RSI MTF:** Short=13, Long=64
- **RtoM Channels:** 200-day lookback, Inner=1.0x, Outer=2.415x
- **Signal Threshold:** 45%+ confidence
- **Data Sources:** Binance (primary), CoinGecko (fallback), Kraken (backup)
- **Scan Frequency:** Every 3 hours (8 scans/day)

---

## 🔄 Workflow

```
Every 3 Hours:
  ↓
Scan Top 50 Cryptos
  ↓
Analyze with TrojanLogic4H
  ↓
Save to JSON Files (4 files)
  ↓
Commit to GitHub
  ↓
Log Results to Notion
  ↓
Generate Trend Report
  ↓
(Optional) Send Telegram Alert
```

---

## 🛠️ Troubleshooting

**No data from Binance:**
- Check internet connection
- Try fallback: data will auto-switch to CoinGecko

**Notion logging fails:**
- Verify NOTION_TOKEN is valid
- Check database ID is correct

**Scheduled task not running:**
- Check Task Scheduler (taskschd.msc)
- Verify PowerShell execution policy
- Check logs in `logs\` folder

**GitHub sync failing:**
- Check git status: `git status`
- Verify credentials
- Run manual commit: `git add -A && git commit -m "sync" && git push`

---

## 📞 Support

For issues or questions, check:
1. Log files in `logs\` directory
2. Notion database for data integrity
3. Visual dashboard for current status
4. GitHub repo for data backup

---

**Built for Roo by Lumina** 🚀
