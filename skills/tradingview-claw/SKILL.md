# TradingView-Claw Skill

## Skill metadata

```yaml
name: tvclaw
version: 1.0.0
description: Trading-enabled TradingView skill for OpenClaw — browse charts, execute trades, track positions, and discover signals via LLM-powered technical analysis.
entry: uv run python scripts/tvclaw.py
requires:
  - python >= 3.10
  - uv
env:
  - TRADINGVIEW_SESSION
  - BROKER_API_KEY
  - BROKER_API_SECRET
  - OPENROUTER_API_KEY
```

---

## Commands

| Command | Description |
|---|---|
| `tvclaw charts trending` | Top symbols by volume |
| `tvclaw charts search <query>` | Search symbols |
| `tvclaw chart <symbol>` | Symbol details + indicators |
| `tvclaw buy <symbol> <amount>` | Open long position |
| `tvclaw sell <symbol> <amount>` | Open short / close position |
| `tvclaw positions` | List positions with P&L |
| `tvclaw position <id>` | Single position detail |
| `tvclaw account status` | Account balance + info |
| `tvclaw account connect` | First-time broker setup |
| `tvclaw signal scan` | LLM signal discovery |
| `tvclaw signal scan --query <q>` | Signal scan with filter |
| `tvclaw signal analyze <s1> <s2>` | Compare two symbols |

---

## Prompt examples

```
What's trending on TradingView?
Show me a chart for AAPL
Find me strong trading signals right now
Run signal scan limit 10
Buy $500 of NVDA
Show my TradingView-Claw positions
Sell my TSLA position
What's my account balance?
```

---

## Signal tiers

| Tier | Coverage | Label |
|---|---|---|
| S1 | ≥ 95% | STRONG |
| S2 | 90–95% | GOOD |
| S3 | 85–90% | MODERATE |
| S4 | < 85% | WEAK (filtered) |

---

## Notes

- Positions are stored locally at `~/.openclaw/tvclaw/positions.json`
- Broker connection is one-time: `tvclaw account connect`
- Signal scan uses `nvidia/nemotron-nano-9b-v2:free` by default via OpenRouter
- Pass `--model <model_id>` to override the LLM model
