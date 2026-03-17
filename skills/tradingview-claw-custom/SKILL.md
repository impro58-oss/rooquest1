# TradingView-Claw Custom — Roo's Strategy

**Custom signal module for TradingView-Claw implementing Roo's CS RSI MTF + Dual Channel strategy.**

---

## 🎯 Strategy Overview

### CS RSI MTF (Multi-Timeframe RSI)
- **Red Line (13-cycle):** Short-term market momentum
- **Blue Lines (64-cycle):** Long-term market structure (dynamic support/resistance)
- **Signal:** Red line touching blue lines indicates potential reversal

### Dual Channel System
- **200-day lookback:** Long-term trend baseline
- **Inner Channel (1.0x):** First warning zone
- **Outer Channel (2.415x):** Extreme zone
- **Tunable:** Adjust multipliers to match historical bounce points

### Signal Logic
```
IF red_line(13) touches upper_blue(64):
    IF upper_blue < 50: → Trend continuation (more room)
    ELSE: → Overbought pullback

IF red_line(13) touches lower_blue(64):
    IF lower_blue > 50: → Bounce OR breakdown
    ELSE: → Oversold bounce
```

---

## 📁 Files

| File | Purpose |
|------|---------|
| `custom_indicators.py` | Core indicator calculations |
| `roo_signal_scanner.py` | Signal scanning and CLI |
| `SKILL.md` | This documentation |

---

## ⚙️ Default Parameters

```python
DEFAULT_PARAMS = {
    'rsi_short_cycle': 13,        # Red line
    'rsi_long_cycle': 64,         # Blue lines
    'channel_lookback': 200,      # 200-day SMA
    'inner_multiplier': 1.0,      # Inner channel
    'outer_multiplier': 2.415,    # Outer channel
    'max_risk_percent': 5.0       # Risk management
}
```

---

## 🚀 Usage

### Show Current Parameters
```bash
python roo_signal_scanner.py
```

### Scan Single Symbol (when integrated)
```python
from custom_indicators import RooSignalEngine

engine = RooSignalEngine()
analysis = engine.analyze(df)
print(analysis['combined_signal'])  # 'buy', 'sell', or 'neutral'
print(analysis['confidence'])       # 0.0 to 1.0
```

### Tune Parameters
```python
from roo_signal_scanner import cmd_tune_param

# Adjust for current market conditions
cmd_tune_param('outer_multiplier', 2.2)  # Tighter outer channel
cmd_tune_param('channel_lookback', 150)  # Shorter lookback
```

---

## 📊 Signal Tiers

| Tier | Confidence | Action |
|------|------------|--------|
| **S1** | ≥90% | Strong signal - both indicators aligned |
| **S2** | 75-90% | Moderate signal - caution on RSI |
| **S3** | 60-75% | Weak signal - channel only |
| **S4** | <60% | No trade |

---

## 🔧 Customization

### Adjust for Different Timeframes
```python
# For daily charts
engine = RooSignalEngine(
    rsi_short=9,      # Faster momentum
    rsi_long=21,      # Weekly structure
    channel_lookback=50
)

# For 4-hour charts
engine = RooSignalEngine(
    rsi_short=8,
    rsi_long=32,      # 4-day structure
    channel_lookback=100
)
```

### Tune Channel Multipliers
```python
# Tighter channels (more signals)
engine = RooSignalEngine(outer_mult=2.0)

# Wider channels (fewer, higher-quality signals)
engine = RooSignalEngine(outer_mult=3.0)
```

---

## ⚠️ Risk Management

- **Max risk per trade:** 5% of account
- **Position sizing:** Scaled by confidence
  - 90%+ confidence = Full 5%
  - 75% confidence = 3.75%
  - 60% confidence = 2.5%

---

## 📝 Notes

- Weekly timeframe (1W) is recommended for this strategy
- Adjust channel multipliers to match historical support/resistance
- CS RSI MTF provides early warning; Dual Channels provide confirmation
- Best used in ranging or trending markets with clear structure

---

**Created for Roo's Trading System**
**Based on TradingView-Claw by helenigtxu**
