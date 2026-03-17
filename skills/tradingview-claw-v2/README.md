# TrojanLogic4H — Improved 4H Trading Strategy

**Advanced 4H-only trading engine for Roo's indicator framework.**

This is the **v2 implementation** with significant improvements over the original:

## 🚀 Key Improvements

| Feature | Original (v1) | TrojanLogic4H (v2) |
|---------|---------------|---------------------|
| **RSI Calculation** | Simple SMA-based | EWM (exponentially weighted) — more responsive |
| **Signal Detection** | Proximity-based | State machine (reentry, detachment, hooks) |
| **Channel Analysis** | Static bands | Slope, width, regime detection (compression/expansion) |
| **Market Structure** | None | Liquidity sweep detection |
| **Wick Analysis** | None | Bullish/bearish rejection detection |
| **Cross Validation** | None | Cross failure detection |
| **Confidence** | Simple tiered | Weighted scoring (0-99%) |
| **Trade Plan** | Basic signal | Full plan: entry zone, stop, TP1, TP2, invalidation |
| **Position Sizing** | Fixed % | Stop-distance based sizing |

## 📁 Files

```
tradingview-claw-v2/
├── trojanlogic_4h.py      ← Core strategy engine
├── trojanlogic_demo.py    ← Demo runner (simulated data)
├── demo_data_feed.py      ← Simulated market data
├── free_data_feed.py      ← FREE live data from Binance (no API key!)
├── live_runner.py         ← Live trading with real market data
└── README.md              ← This file
```

## 🎯 Strategy Components

### 1. CSRSI4H (Improved RSI)
- **Red Line (13)**: Short-term momentum with EWM smoothing
- **Blue Lines (64)**: Long-term structure with dynamic bands
- **States Detected**:
  - `bullish_reentry` — Red crosses back above lower blue
  - `bearish_reentry` — Red crosses back below upper blue
  - `bullish_detachment` — Red breaks above upper blue
  - `bearish_detachment` — Red breaks below lower blue
  - `bullish_hook` / `bearish_hook` — Early reversal patterns
  - Cross failure detection (false breakout protection)

### 2. RtoM4H (Channel Structure)
- **200-period SMA** as baseline
- **Inner channel (1.0x)** and **Outer channel (2.415x)**
- **Slope analysis**: Improving vs weakening
- **Regime detection**:
  - `compression` — Channel narrowing (pre-breakout)
  - `expansion` — Channel widening (trending)
  - `stable` — Normal conditions
- **Position classification**: outside_upper, upper_half, mid_zone, lower_half, outside_lower

### 3. Market Structure Tools
- **Liquidity sweep detection**: Fake breakout then reversal
- **Wick rejection**: Long wicks indicating rejection
- **Structural stops**: Based on recent swing highs/lows

### 4. Confidence Model
Weighted scoring system (max 99%):
- Reentry state: +24%
- Detachment: +18%
- Cross confirmation: +16%
- Channel bias: +12%
- Compression: +10%
- Liquidity sweep: +14%
- Wick rejection: +10%
- Position zone: +8%
- Cross failure penalty: -30%

## 🚀 Launch Instructions

### Step 1: Install Dependencies
```bash
cd C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2
C:\Users\impro\AppData\Local\Programs\Python\Python311\python.exe -m pip install pandas numpy rich
```

### Step 2: Run Interactive Demo
```bash
C:\Users\impro\AppData\Local\Programs\Python\Python311\python.exe trojanlogic_demo.py
```

### Step 3: Run Specific Scenario
```bash
# Test uptrend scenario
C:\Users\impro\AppData\Local\Programs\Python\Python311\python.exe trojanlogic_demo.py uptrend

# Test rangebound scenario
C:\Users\impro\AppData\Local\Programs\Python\Python311\python.exe trojanlogic_demo.py rangebound

# Run all scenarios
C:\Users\impro\AppData\Local\Programs\Python\Python311\python.exe trojanlogic_demo.py all
```

## 📊 Example Output

```
=== TROJANLOGIC 4H DEMO: RANGEBOUND ===

┌─────────────────────────────────────────────────────────────┐
│ TRADING SIGNAL                                              │
├─────────────────────────────────────────────────────────────┤
│ 🟢 SIGNAL: LONG                                             │
│ Setup Type: reversal                                        │
│ Confidence: 76.0% (moderate)                                │
│ Current Price: $45,675.28                                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ CS RSI MTF State                                            │
├─────────────────────────────────────────────────────────────┤
│ State: bullish_reentry                                      │
│ Zone: neutral_transition                                    │
│ Red Line: 47.26                                             │
│ Upper Blue: 50.05                                           │
│ Lower Blue: 38.28                                           │
│ Cross: bullish_40_cross                                     │
│ Cross Failure: False                                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ RtoM Channel Structure                                      │
├─────────────────────────────────────────────────────────────┤
│ Bias: bullish                                               │
│ Regime: compression                                         │
│ Position: lower_half                                        │
│ Slope Shift: improving                                      │
│ Channel Width: 16,717.24                                    │
│ 200 SMA: $47,569.71                                         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Trade Plan                                                  │
├─────────────────────────────────────────────────────────────┤
│ Entry Zone: $45,538.05 - $45,675.28                         │
│ Stop Loss: $44,543.21                                       │
│ Target 1: $52,464.95                                        │
│ Target 2: $59,391.71                                        │
│ Invalidation: 4H close below 44543.21                     │
│ Position Size (1% risk): 0.1023 units                     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Analysis                                                    │
├─────────────────────────────────────────────────────────────┤
│ Reasons:                                                    │
│   • bullish re-entry back inside csRSI corridor           │
│   • bullish 40 cross confirmed                              │
│   • price positioned in lower to mid channel zone           │
│   • channel compression detected                            │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Using with Real Data

```python
import pandas as pd
from trojanlogic_4h import TrojanLogic4H

# Load your 4H OHLCV data
df = pd.read_csv("btc_4h_data.csv")

# Ensure columns: open, high, low, close
# Need at least 220 rows for stable calculations

# Initialize engine
engine = TrojanLogic4H()

# Analyze
result = engine.analyze(df)

# Access trade plan
trade = result['trade_plan']
print(f"Signal: {trade['signal']}")
print(f"Confidence: {trade['confidence']:.1%}")
print(f"Entry: {trade['entry_zone']}")
print(f"Stop: {trade['stop_loss']}")
```

## ⚙️ Customization

```python
# Adjust parameters
engine = TrojanLogic4H(
    rsi_short=9,           # Faster red line
    rsi_long=21,           # Faster blue lines
    channel_lookback=100,  # Shorter channel
    inner_mult=0.8,        # Tighter inner band
    outer_mult=2.0,        # Tighter outer band
    stop_buffer_pct=0.005  # Wider stops
)
```

## 🎯 Signal Types

### Reversal Signals (Highest Priority)
- **Bullish Reversal**: Reentry + 40 cross + lower zone + compression
- **Bearish Reversal**: Reentry + 60 cross + upper zone + compression

### Continuation Signals
- **Bullish Continuation**: Detachment + bullish bias + expansion
- **Bearish Continuation**: Detachment + bearish bias + expansion

### Warning Signals
- **Hooks**: Early warning of potential reversal
- **Cross Failures**: False breakout protection

## 📈 Risk Management

- **Base Risk**: 1% per trade (configurable)
- **Position Sizing**: Based on stop distance
- **Invalidation**: Clear 4H close beyond stop
- **Targets**: Inner channel (TP1), Outer channel (TP2)

## 🔄 Comparison with v1

| Scenario | v1 Signal | v1 Confidence | v2 Signal | v2 Confidence |
|----------|-----------|-----------------|-----------|---------------|
| Uptrend | SELL | 70% | SHORT | 85%+ |
| Downtrend | HOLD | 0% | LONG/SHORT | Context-dependent |
| Rangebound | HOLD | 0% | LONG/SHORT | 65-85% |
| Breakout | SELL | 90% | SHORT | 90%+ |

**v2 provides**: More nuanced signals, better timing, full trade plans, higher confidence accuracy.

---

**Ready to launch?** Run the demo and see the difference! 🚀
