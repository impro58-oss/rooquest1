# Polymarket API Integration Plan

**Wallet Address:** `0x2d8c75c3fcbbFe50f92c2eDb00ab7dcF89578071`
**Last Updated:** 2026-03-15

---

## API Structure

Polymarket operates three separate APIs:

### 1. Gamma API (Public)
- **URL:** `https://gamma-api.polymarket.com`
- **Auth:** None required
- **Use:** Market discovery, events, tags, series, comments, sports, search, public profiles

### 2. Data API (Public) ⭐ PRIMARY FOR PORTFOLIO
- **URL:** `https://data-api.polymarket.com`
- **Auth:** None required
- **Use:** User positions, trades, activity, holder data, open interest, leaderboards
- **Key Endpoints:**
  - `GET /positions?user={wallet}` - Current positions
  - `GET /trades?user={wallet}` - Trade history
  - `GET /portfolio?user={wallet}` - Portfolio summary

### 3. CLOB API (Mixed)
- **URL:** `https://clob.polymarket.com`
- **Auth:** Public for market data, Required for trading
- **Use:** Orderbook, pricing, order placement/cancellation

### 4. Bridge API
- **URL:** `https://bridge.polymarket.com`
- **Note:** Proxy for fun.xyz service (deposits/withdrawals)

---

## Wallet Details

**Address:** `0x2d8c75c3fcbbFe50f92c2eDb00ab7dcF89578071`
**Type:** Polymarket ProxyWallet (1-of-1 multisig)
**Deployed:** 2026-01-03 (via Proxy Wallet Factory)
**Network:** Polygon
**Current POL Balance:** $0.00

---

## Integration Options

### Option A: Direct API Calls (Recommended)
- Use Data API for portfolio tracking
- No authentication needed
- Real-time position data
- Free, no rate limits mentioned

### Option B: PMXT Library
- Python/Node.js unified API
- Supports multiple prediction markets
- `pip install pmxt` / `npm install pmxtjs`
- GitHub: https://github.com/pmxt-dev/pmxt

### Option C: Official SDKs
- TypeScript, Python, Rust libraries available
- See: https://docs.polymarket.com/api-reference/clients-sdks

---

## Data API Endpoints for Portfolio

```
# Current Positions
GET https://data-api.polymarket.com/positions?user=0x2d8c75c3fcbbFe50f92c2eDb00ab7dcF89578071

# Trade History
GET https://data-api.polymarket.com/trades?user=0x2d8c75c3fcbbFe50f92c2eDb00ab7dcF89578071

# Portfolio Summary
GET https://data-api.polymarket.com/portfolio?user=0x2d8c75c3fcbbFe50f92c2eDb00ab7dcF89578071
```

---

## Current System Status

| Component | Status | Notes |
|-----------|--------|-------|
| Hourly Market Scanner | ✅ Active | Runs every hour, sends alerts to Poly2 |
| Telegram Alerts | ✅ Working | Fixed encoding issues |
| Screenshot Tracker | ✅ Active | Monitors Pictures/Polymarket folder |
| API Integration | ⏳ Planned | This document |
| Auto-Trading | ❌ Not Planned | Manual execution only |

---

## Next Steps

1. [ ] Build Data API portfolio fetcher script
2. [ ] Test position retrieval with wallet address
3. [ ] Create P&L calculation from trade history
4. [ ] Integrate with Notion Current Bets database
5. [ ] Compare API data vs screenshot data for validation

---

## Documentation

- Full API docs: https://docs.polymarket.com
- LLM-friendly index: https://docs.polymarket.com/llms.txt
- PMXT Library: https://github.com/pmxt-dev/pmxt

---

**Note:** User will place bets manually based on alerts. System provides intelligence, not automated trading.
