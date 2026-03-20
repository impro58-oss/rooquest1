# TODO List - Roo's Tasks

## 🔴 HIGH PRIORITY

### MedTech Intelligence - Vueroo API Setup
**Status:** Data cleaned, awaiting GitHub setup
**Created:** 2026-03-20 10:31

**Prerequisites:**
- [ ] Create GitHub private repository: `medtech-intelligence-data`
- [ ] Upload cleaned JSON files:
  - `epidemiological-data.json`
  - `competition-data.json`
- [ ] Generate GitHub Personal Access Token (scopes: `repo`)
- [ ] Share token securely with Lumina

**Then Lumina will:**
- [ ] Build Vueroo API endpoint: `https://vueroo.com/api/medtech/data`
- [ ] Configure environment variable for GitHub token
- [ ] Update local HTML files to use API instead of local JSON
- [ ] Test end-to-end flow

**Files ready at:**
`C:\Users\impro\.openclaw\workspace\medtech-intelligence\dashboard\data\clean\`

**Architecture:**
```
Local HTML → Vueroo API → GitHub Private Repo (token hidden)
```

**Benefits:**
- Token never exposed to client
- Data protected behind authentication
- HTML shell contains no proprietary data
- Scrapers see nothing without login

---

## 🟡 MEDIUM PRIORITY

### TradingView Pine Script Installation
**Status:** Scripts created, awaiting installation on TradingView
**Created:** 2026-03-20 10:43

**Files Ready:**
- `trojanlogic4h-indicator.pine` — Main overlay indicator with RtoM channels
- `trojanlogic4h-oscillator.pine` — Composite Score oscillator panel
- `trojanlogic4h-strategy.pine` — Strategy Tester with risk management

**Location:**
`C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2\`

**Installation Steps:**
1. Open TradingView → Pine Editor
2. Copy script contents
3. Paste and "Add to chart"
4. Configure settings:
   - Primary RSI: 14
   - MTF weights: 25% (1H), 15% (4H), 10% (Daily)
   - Long Threshold: 65
   - Short Threshold: 35

**See also:** `README-PINE-SCRIPTS.md` for full documentation

---

### AWS Instance Knowledge Export
**Status:** Deferred from 2026-03-17
**Task:** Export knowledge from earlier model on AWS server
**Steps:**
- Review AWS instance contents
- Export relevant knowledge/work
- Compare with current home + VPS systems
- Cleanup and consolidation
- Determine what to keep vs. discard

**Estimated Time:** 30-60 minutes

---

## 🟢 LOW PRIORITY / BACKLOG

### Persistent Memory Layer (Requested 2026-03-20)
**Scope:** Build /memory directory with three files:
- `recent-memory.md` - rolling 48hr context
- `long-term-memory.md` - distilled facts, preferences, patterns
- `project-memory.md` - active project state

**Plus:**
- Create skill at `/skills/consolidate-memory`
- Schedule nightly automatic consolidation
- Update SOUL.md to load recent-memory.md at startup

---

## ✅ RECENTLY COMPLETED

- [x] 2026-03-20: MedTech data cleaning and structuring
- [x] 2026-03-20: Git sync to GitHub
- [x] 2026-03-18: Competitive intelligence analysis (11 competitors mapped)
- [x] 2026-03-18: Global stroke dashboard created

---

*Last Updated: 2026-03-20 10:31*
