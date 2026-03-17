# TradingView-Claw Original vs TrojanLogic4H Comparison Scanner
# Uses existing scan data and adds simplified TV-Claw signals

import sys
sys.path.insert(0, r'C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2')

from multi_source_feed import MultiSourceFeed
from trojanlogic_4h import TrojanLogic4H
import json
import pandas as pd
import numpy as np
from datetime import datetime

# Top 20 symbols to compare
SYMBOLS = [
    'BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'XRPUSDT', 'DOGEUSDT',
    'BNBUSDT', 'LINKUSDT', 'TRUMPUSDT', 'ADAUSDT', 'SUIUSDT',
    'AVAXUSDT', 'DOTUSDT', 'LTCUSDT', 'NEARUSDT', 'FILUSDT',
    'ICPUSDT', 'BCHUSDT', 'HBARUSDT', 'RENDERUSDT', 'FETUSDT'
]

def compute_rsi_manual(prices, period=14):
    """Manual RSI calculation"""
    deltas = np.diff(prices)
    gains = np.where(deltas > 0, deltas, 0)
    losses = np.where(deltas < 0, -deltas, 0)
    
    avg_gain = np.mean(gains[:period])
    avg_loss = np.mean(losses[:period])
    
    for i in range(period, len(gains)):
        avg_gain = (avg_gain * (period - 1) + gains[i]) / period
        avg_loss = (avg_loss * (period - 1) + losses[i]) / period
    
    if avg_loss == 0:
        return 100
    rs = avg_gain / avg_loss
    return 100 - (100 / (1 + rs))

def compute_ema(prices, period):
    """Calculate EMA"""
    multiplier = 2 / (period + 1)
    ema_values = [np.mean(prices[:period])]
    for price in prices[period:]:
        ema_values.append((price - ema_values[-1]) * multiplier + ema_values[-1])
    return np.array(ema_values)

def compute_macd_manual(prices, fast=12, slow=26, signal=9):
    """Manual MACD calculation - align arrays properly"""
    # Calculate both EMAs from the same starting point
    ema_fast_full = compute_ema(prices, fast)
    ema_slow_full = compute_ema(prices, slow)
    
    # Align to same length (slow EMA starts later)
    offset = slow - fast
    ema_fast_aligned = ema_fast_full[offset:]
    ema_slow_aligned = ema_slow_full
    
    # MACD line
    macd_line = ema_fast_aligned[-1] - ema_slow_aligned[-1]
    
    # Signal line is EMA of MACD
    macd_series = ema_fast_aligned - ema_slow_aligned
    signal_line_vals = compute_ema(macd_series, signal)
    signal_line = signal_line_vals[-1]
    
    histogram = macd_line - signal_line
    
    return macd_line, signal_line, histogram

def compute_bollinger_manual(prices, period=20, std_dev=2.0):
    """Manual Bollinger Bands calculation"""
    sma = np.mean(prices[-period:])
    std = np.std(prices[-period:])
    upper = sma + (std * std_dev)
    lower = sma - (std * std_dev)
    return upper, sma, lower

print("=== SIGNAL ENGINE COMPARISON ===")
print(f"Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"Symbols: {len(SYMBOLS)}")
print("")

# Initialize data feed
feed = MultiSourceFeed()

results = []

for symbol in SYMBOLS:
    print(f"\nAnalyzing {symbol}...")
    
    try:
        # Get data
        df = feed.get_4h_data(symbol, days_back=60)
        
        if df is None or len(df) < 220:
            print(f"  [SKIP] Insufficient data")
            continue
        
        closes = df['close'].values
        current_price = closes[-1]
        
        # Calculate TrojanLogic4H signals
        trojan = TrojanLogic4H()
        trojan_result = trojan.analyze(df)
        trojan_signal = trojan_result.get('signal', 'HOLD')
        trojan_conf = trojan_result.get('confidence', 0)
        
        # Calculate original TradingView-Claw signals (manual implementation)
        # RSI 14
        rsi = compute_rsi_manual(closes, period=14)
        
        # MACD 12/26/9
        macd_line, macd_signal_line, macd_hist = compute_macd_manual(closes, fast=12, slow=26, signal=9)
        
        # Bollinger Bands 20/2.0
        bb_upper, bb_mid, bb_lower = compute_bollinger_manual(closes, period=20, std_dev=2.0)
        
        # Original TV-Claw signal logic
        tv_signal = "HOLD"
        tv_confidence = 0
        
        # RSI logic
        if rsi > 70:
            tv_signal = "SHORT"
            tv_confidence = min(60 + (rsi - 70) * 2, 90)
        elif rsi < 30:
            tv_signal = "LONG"
            tv_confidence = min(60 + (30 - rsi) * 2, 90)
        
        # MACD confirmation
        if macd_hist > 0 and tv_signal == "LONG":
            tv_confidence = min(tv_confidence + 10, 95)
        elif macd_hist < 0 and tv_signal == "SHORT":
            tv_confidence = min(tv_confidence + 10, 95)
        
        # Bollinger Bands
        if current_price > bb_upper and tv_signal != "SHORT":
            tv_signal = "SHORT"
            tv_confidence = max(tv_confidence, 55)
        elif current_price < bb_lower and tv_signal != "LONG":
            tv_signal = "LONG"
            tv_confidence = max(tv_confidence, 55)
        
        if tv_confidence == 0:
            tv_signal = "HOLD"
            tv_confidence = 0
        
        # Compare
        agreement = "MATCH" if trojan_signal == tv_signal else "DIFF"
        
        result = {
            'symbol': symbol,
            'price': round(current_price, 2),
            'trojan_signal': trojan_signal,
            'trojan_confidence': trojan_conf,
            'tv_signal': tv_signal,
            'tv_confidence': round(tv_confidence),
            'agreement': agreement,
            'rsi_14': round(rsi, 2),
            'macd_hist': round(macd_hist, 4),
            'bb_position': 'above' if current_price > bb_upper else 'below' if current_price < bb_lower else 'inside'
        }
        
        results.append(result)
        
        print(f"  Trojan: {trojan_signal} {trojan_conf}% | TV-Claw: {tv_signal} {tv_confidence}% | {agreement}")
        
    except Exception as e:
        print(f"  [ERROR] {e}")
        continue

# Save results
output_file = r'C:\Users\impro\.openclaw\workspace\data\crypto\signal_comparison.json'

if results:
    agreement_rate = len([r for r in results if r['agreement'] == 'MATCH']) / len(results) * 100
    
    with open(output_file, 'w') as f:
        json.dump({
            'timestamp': datetime.now().isoformat(),
            'symbols_analyzed': len(results),
            'agreement_rate': round(agreement_rate, 1),
            'results': results
        }, f, indent=2)
    
    print(f"\n=== COMPARISON COMPLETE ===")
    print(f"Analyzed: {len(results)} symbols")
    print(f"Agreement rate: {agreement_rate:.1f}%")
    print(f"Output: {output_file}")
    
    # Show disagreements
    disagreements = [r for r in results if r['agreement'] == 'DIFF']
    if disagreements:
        print(f"\n=== SIGNAL DISAGREEMENTS ({len(disagreements)}) ===")
        for r in disagreements:
            print(f"{r['symbol']}: Trojan {r['trojan_signal']} vs TV-Claw {r['tv_signal']}")
    else:
        print("\n=== ALL SIGNALS AGREE ===")
else:
    print("\n[ERROR] No results generated")
