# MEMORY.md - Long-Term Memory for Lumina

**Last Updated:** 2026-03-14 22:13 UTC
**Session:** Direct chat with Roo

---

## ðŸ§  CORE SYSTEMS BUILT

### **Crypto Intelligence System (TrojanLogic4H)**
- **Status:** LIVE - Running every 4 hours via scheduled task
- **Scope:** Top 50 cryptocurrencies by volume
- **Strategy:** CS RSI MTF (13/64) + RtoM Channels (200-day)
- **Data Sources:** Binance (primary), CoinGecko, Kraken, CryptoCompare (auto-fallback)
- **Classification:** FUTURES (high-confidence trades) / HOLD (core convictions) / MONITOR (watch)
- **Output:** Notion database + visual dashboard + trend analysis

**Key Files:**
- `skills/tradingview-claw-v2/analyze_top_50.py` - Main scanner
- `skills/tradingview-claw-v2/trojanlogic_4h.py` - Core engine
- `skills/tradingview-claw-v2/multi_source_feed.py` - 4-source data feed
- `skills/tradingview-claw-v2/log_to_intelligence.py` - Notion logger
- `skills/tradingview-claw-v2/analyze_trends.py` - Historical analysis

**Notion Resources:**
- Visual Dashboard: https://notion.so/3230491758dd819c90e4fce960777521
- Intelligence Database: https://notion.so/3230491758dd81d8a31efe277bf4b0d1

**Scheduled Task:** `TrojanLogic4H Auto Scanner` - Runs every 4 hours

---

### **Notion Control Room**
- **Status:** ACTIVE - 10+ databases created
- **Integration Token:** Stored at `C:\Users\impro\.config\notion\api_key`
- **Page ID:** 3230491758dd80a08614d4808e0af030

**Databases:**
1. ðŸ“Š Projects - Active initiatives
2. ðŸ“° News & Intelligence - Research tracking
3. âœ… Tasks & Actions - Current work
4. âœ… Completed Tasks - Archived work
5. ðŸ¤– Sub-Agent Status - Agent tracking
6. ðŸš€ Stockward - Business partnership
7. ðŸ”¬ Stockward Research - Research notes
8. ðŸ§  Lumina Self-Improvement - Optimization proposals
9. ðŸ’° Polymarket Current Bets - Betting tracker
10. ðŸŽ¯ Polymarket Next Bets - Opportunities
11. ðŸ“Š Crypto Intelligence Database - Historical crypto data

---

### **Automation Infrastructure**
- **Gateway:** Port 18789, auto-restart configured
- **Scheduled Tasks:**
  - Crypto scanner (every 4 hours)
  - Gateway monitor (every 5 minutes)
  - Self-heal script (every 5 minutes)
- **Backup Model:** Llama 3 (local Ollama) as API fallback
- **Git Repository:** https://github.com/impro58-oss/rooquest1 (private)

---

## ðŸŽ¯ ROO'S PREFERENCES

### **Trading Strategy**
- **Core Holdings:** BTC, ETH, SOL, XRP, DOGE, BNB, LINK
- **Risk Management:** Max 5% per trade, scaled by confidence
- **Timeframe:** 4H primary, weekly for context
- **Signal Threshold:** 45%+ for consideration, 65%+ for action
- **Data Priority:** Free sources first (Binance), paid later (CoinGlass $29/mo)

### **Communication Style**
- Direct, no fluff
- Visual dashboards preferred
- Color-coded signals (ðŸŸ¢ LONG, ðŸ”´ SHORT, âšª HOLD)
- Historical tracking essential for validation

### **Security Boundaries**
- Never handle login credentials for financial platforms
- Private documents use "Roo" only
- "Field Architect" designation kept private
- GitHub repo stays private

---

## ðŸ“š ACTIVE PROJECTS

### **High Priority**
1. **Crypto Intelligence System** - âœ… LIVE, building historical dataset
2. **Stockward Partnership** - â³ Awaiting business materials from Roo
3. **Avaark Development** - â³ MVP scope pending definition

### **Medium Priority**
4. **LUXBRIDGE Sites** - â³ Research international locations
5. **Neurovascular Intelligence** - â³ PDF extraction blocked (Python env issues)
6. **Polymarket Monitoring** - â³ Awaiting Telegram bot token

---

## ðŸ”§ TECHNICAL NOTES

### **Working Environment**
- **OS:** Windows 10.0.22631
- **Shell:** PowerShell
- **Python:** 3.11 at `C:\Users\impro\AppData\Local\Programs\Python\Python311\`
- **Node:** v24.14.0
- **OpenClaw:** 2026.3.13

### **Known Issues**
- Python environment: Windows Store alias conflict resolved
- Gateway scope error: "unreachable (missing scope: operator.read)" - cosmetic, doesn't affect function
- External `clawhub` CLI not available - using `npx -y clawhub` workaround

### **Recovery Protocols**
- **Quick Restart:** `openclaw gateway start`
- **Full Recovery:** See `RESTART_PROTOCOL.md`
- **Quick Reference:** See `QUICK_RESTART_CARD.txt`

---

## ðŸ’¡ KEY DECISIONS LOG

### **2026-03-14**
- âœ… Keep v1 (RooSignalEngine) as baseline, v2 (TrojanLogic4H) as primary
- âœ… Free data priority: Binance primary, multi-source fallback
- âœ… Historical tracking enables pattern validation
- âœ… Top 50 scan every 4 hours with strategy classification
- âœ… Visual dashboard + database for dual analysis approach

### **Earlier**
- âœ… Use browser skill instead of Google API (cost avoidance)
- âœ… Notion workspace remains private (no public sharing)
- âœ… Auto-implement approved self-improvements without further prompting
- âœ… Token-saving: 2-hour heartbeat instead of 30-min

---

## ðŸ“ DAILY CONTEXT

**Current Date:** 2026-03-14 (Saturday)
**Timezone:** Europe/Dublin (GMT/IST)
**Last Session:** Built Top 50 crypto scanner with automated logging

**Next Expected Actions:**
- Monitor first automated scans (every 4 hours)
- Build historical dataset over 1-2 weeks
- Validate signal accuracy
- Await Stockward materials from Roo

---

## ðŸ”„ MEMORY MAINTENANCE

**Daily:** Append to `memory/YYYY-MM-DD.md`
**Weekly:** Review and distill into MEMORY.md
**Monthly:** Archive old daily files, update core learnings

**Never Overwrite:** MEMORY.md, SOUL.md, TOOLS.md, AGENTS.md, BOOTSTRAP.md

---

*This is my long-term memory. I read this at session start to maintain continuity.*

