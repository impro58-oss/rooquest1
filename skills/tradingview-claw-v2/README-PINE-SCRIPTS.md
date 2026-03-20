# TrojanLogic4H TradingView Pine Scripts

## Overview

Three Pine Script indicators/strategies implementing the **CS RSI MTF + RtoM Channels** trading system from our crypto intelligence dashboard.

## Files

### 1. `trojanlogic4h-indicator.pine` — Main Overlay Indicator
**Type:** Overlay (plots on price chart)
**Purpose:** Full system with visual signals

**Features:**
- RtoM Channels (Regression to Mean) — Upper, Middle, Lower bands
- Composite Score calculation from multiple timeframes
- Background color changes (Green=LONG, Red=SHORT, Gray=HOLD)
- Signal arrows on chart (LONG/SHORT)
- Real-time info table with RSI values and signal status

**Default Settings:**
- Primary RSI: 14-period
- MTF 1 (30m): 25% weight
- MTF 2 (4H): 15% weight
- MTF 3 (Daily): 10% weight
- Long Threshold: 65
- Short Threshold: 35

---

### 2. `trojanlogic4h-oscillator.pine` — Oscillator Panel
**Type:** Oscillator (separate panel below price)
**Purpose:** Clean composite score visualization

**Features:**
- Composite Score line plot
- Configurable MTF weights
- Overbought (>70) / Oversold (<30) zones
- Moving average of Composite Score
- Signal arrows for crossovers
- Info panel with all RSI values

**Best For:**
- Quick signal identification
- MTF confluence analysis
- Clean chart view

---

### 3. `trojanlogic4h-strategy.pine` — Strategy Tester
**Type:** Strategy (for backtesting)
**Purpose:** Automated trading with risk management

**Features:**
- Automated LONG/SHORT entries based on thresholds
- Stop Loss and Take Profit levels
- Trailing stop option
- Time filter (trade only specific hours)
- RtoM channel filter
- Position sizing (% of equity)

**Risk Management:**
- Max position size: 5% default
- Stop Loss: 5% default
- Take Profit: 10% default
- Trailing Stop: 3% default (optional)

---

## Installation Instructions

### Step 1: Open TradingView
1. Go to [tradingview.com](https://tradingview.com)
2. Open any chart

### Step 2: Open Pine Editor
1. Click "Pine Editor" tab at bottom of screen
2. Or press `</>` icon on right sidebar

### Step 3: Copy Script
1. Copy contents of desired `.pine` file
2. Paste into Pine Editor
3. Click "Add to chart" (or Ctrl+S)

### Step 4: Configure
1. Click the gear icon ⚙️ on the indicator
2. Adjust settings as needed
3. Click "OK"

---

## Recommended Settings by Timeframe

### 30-Minute Chart (Primary)
```
Primary RSI: 14
MTF 1: 60 (1H) — Weight: 25%
MTF 2: 240 (4H) — Weight: 15%
MTF 3: D (Daily) — Weight: 10%
Long Threshold: 65
Short Threshold: 35
```

### 1-Hour Chart
```
Primary RSI: 14
MTF 1: 240 (4H) — Weight: 30%
MTF 2: D (Daily) — Weight: 20%
MTF 3: W (Weekly) — Weight: 10%
Long Threshold: 65
Short Threshold: 35
```

### Daily Chart
```
Primary RSI: 14
MTF 1: W (Weekly) — Weight: 35%
MTF 2: M (Monthly) — Weight: 15%
Long Threshold: 60
Short Threshold: 40
```

---

## How to Use

### LONG Signal
1. Composite Score crosses above 65
2. Price near or below RtoM middle line
3. Background turns GREEN
4. Arrow appears below candle

**Action:** Consider LONG position with 5% max size

### SHORT Signal
1. Composite Score crosses below 35
2. Price near or above RtoM middle line
3. Background turns RED
4. Arrow appears above candle

**Action:** Consider SHORT position with 5% max size

### HOLD Signal
- Composite Score between 35-65
- Background is GRAY
- No arrows

**Action:** Wait for clear signal

---

## Alerts Setup

### In TradingView:
1. Right-click indicator on chart
2. Select "Add Alert" 🔔
3. Choose condition:
   - LONG Signal → Message: "LONG {{ticker}} at {{close}}"
   - SHORT Signal → Message: "SHORT {{ticker}} at {{close}}"
4. Set notification (app, email, webhook)

### Telegram Integration (Optional)
Use webhook URL from your Telegram bot to receive alerts directly.

---

## Strategy Tester Backtesting

### To Backtest:
1. Load `trojanlogic4h-strategy.pine`
2. Click "Strategy Tester" tab
3. Select asset and timeframe
4. Adjust settings
5. Click "Add to chart"
6. Review results in Strategy Tester panel

### Key Metrics to Watch:
- **Net Profit:** Total return
- **Profit Factor:** Gross profit / Gross loss
- **Win Rate:** % of winning trades
- **Max Drawdown:** Largest peak-to-trough decline
- **Sharpe Ratio:** Risk-adjusted returns

---

## Advanced Configuration

### Custom Timeframes
Edit the `mtf1Period`, `mtf2Period`, `mtf3Period` inputs to match your preferred higher timeframes.

### Custom Weights
Adjust `weightMTF1`, `weightMTF2`, `weightMTF3` to change how much each timeframe affects the Composite Score.

**Example:** For trend-following, increase daily/weekly weights. For scalping, increase hourly weights.

### Risk Adjustment
In strategy script, modify:
- `maxPositionSize` — % of equity per trade
- `stopLossPerc` — Stop loss distance
- `takeProfitPerc` — Take profit distance
- `trailingStopPerc` — Trailing stop distance

---

## Troubleshooting

### "No signals appearing"
- Check that all MTF periods are available for the asset
- Try reducing number of MTF periods
- Check thresholds aren't too extreme

### "Signals too frequent"
- Increase threshold values (e.g., 70/30 instead of 65/35)
- Enable RtoM filter
- Add time filter

### "Signals too rare"
- Decrease threshold values (e.g., 60/40 instead of 65/35)
- Disable RtoM filter
- Reduce MTF weights

### "Strategy not entering trades"
- Ensure sufficient historical data (MTF needs lookback)
- Check that `inSession` time filter includes current time
- Verify position size calculation (may be rounding to 0)

---

## Updates & Maintenance

These scripts will be updated as the CS RSI MTF system evolves. Check for:
- New MTF combinations
- Improved RtoM calculations
- Additional filters (volume, volatility)
- Machine learning integration (future)

---

## License

Mozilla Public License 2.0 — Free to use, modify, and distribute. Attribution appreciated.

---

**Last Updated:** 2026-03-20  
**Version:** 1.0  
**Author:** rooquest_trading
