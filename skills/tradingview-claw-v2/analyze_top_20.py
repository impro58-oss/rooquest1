"""
analyze_top_20.py — Run TrojanLogic4H on top 20 cryptos
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import json
from datetime import datetime
from trojanlogic_4h import TrojanLogic4H
from multi_source_feed import MultiSourceFeed

# Get top 20 from Binance
def get_top_20():
    import requests
    url = 'https://api.binance.com/api/v3/ticker/24hr'
    response = requests.get(url, timeout=30)
    data = response.json()
    
    # Filter USDT pairs, exclude stablecoins
    exclude = ['USDCUSDT', 'USDTUSDT', 'BUSDUSDT', 'DAIUSDT', 'TUSDUSDT']
    usdt_pairs = [d for d in data if d['symbol'].endswith('USDT') and d['symbol'] not in exclude]
    usdt_pairs.sort(key=lambda x: float(x['quoteVolume']), reverse=True)
    
    return [p['symbol'] for p in usdt_pairs[:20]]

def analyze_all():
    """Analyze top 20 and generate report."""
    print("=== TROJANLOGIC4H: TOP 20 CRYPTO ANALYSIS ===\n")
    print(f"Analysis Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}\n")
    
    TOP_20 = get_top_20()
    print(f"Analyzing: {', '.join(TOP_20)}\n")
    
    feed = MultiSourceFeed()
    engine = TrojanLogic4H()
    
    results = []
    
    for symbol in TOP_20:
        try:
            print(f"Analyzing {symbol}...", end=" ")
            df, info = feed.get_data_with_validation(symbol, days_back=60)
            result = engine.analyze(df)
            
            trade_plan = result.get('trade_plan', {})
            csrsi = result.get('csrsi_state', {})
            rtom = result.get('rtom_structure', {})
            
            analysis = {
                'symbol': symbol,
                'timestamp': datetime.now().isoformat(),
                'price': result.get('price', 0),
                'signal': trade_plan.get('signal', 'hold'),
                'confidence': trade_plan.get('confidence', 0),
                'confidence_label': trade_plan.get('confidence_label', 'none'),
                'setup_type': trade_plan.get('setup_type', 'none'),
                'csrsi_state': csrsi.get('state', 'neutral'),
                'csrsi_zone': csrsi.get('zone', 'unknown'),
                'csrsi_red': csrsi.get('red_now', 0),
                'csrsi_upper_blue': csrsi.get('upper_blue_now', 0),
                'csrsi_lower_blue': csrsi.get('lower_blue_now', 0),
                'rtom_bias': rtom.get('bias', 'flat'),
                'rtom_regime': rtom.get('regime', 'stable'),
                'rtom_position': rtom.get('position', 'mid_zone'),
                'rtom_slope_shift': rtom.get('slope_shift', 'neutral'),
                'rtom_200sma': rtom.get('mid_now', 0),
                'compression': result.get('compression', False),
                'liquidity_sweep': result.get('liquidity_sweep', 'none'),
                'wick_rejection': result.get('wick_rejection', 'none'),
                'reasons': trade_plan.get('reasons', []),
                'warnings': trade_plan.get('warnings', []),
                'entry_zone': trade_plan.get('entry_zone'),
                'stop_loss': trade_plan.get('stop_loss'),
                'tp1': trade_plan.get('tp1'),
                'tp2': trade_plan.get('tp2'),
                'invalidation': trade_plan.get('invalidation'),
                'data_source': info['source'],
                'candles': info['candles']
            }
            
            results.append(analysis)
            
            sig = analysis['signal']
            conf = analysis['confidence']
            
            if sig == 'long':
                print(f"[LONG {conf:.0%}]")
            elif sig == 'short':
                print(f"[SHORT {conf:.0%}]")
            else:
                print(f"[HOLD]")
                
        except Exception as e:
            print(f"[ERROR: {e}]")
            results.append({
                'symbol': symbol,
                'timestamp': datetime.now().isoformat(),
                'error': str(e)
            })
    
    # Save results
    output_file = f"top_20_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(output_file, 'w') as f:
        json.dump({
            'analysis_time': datetime.now().isoformat(),
            'strategy': 'TrojanLogic4H',
            'parameters': {
                'rsi_short': 13,
                'rsi_long': 64,
                'channel_lookback': 200,
                'inner_mult': 1.0,
                'outer_mult': 2.415
            },
            'results': results
        }, f, indent=2)
    
    print(f"\n=== SUMMARY ===")
    print(f"Analysis saved to: {output_file}")
    
    # Show opportunities
    opportunities = [r for r in results if r.get('signal') in ['long', 'short'] and r.get('confidence', 0) >= 0.45]
    
    if opportunities:
        print(f"\n>>> {len(opportunities)} TRADE OPPORTUNITIES <<<")
        for opp in sorted(opportunities, key=lambda x: x['confidence'], reverse=True):
            print(f"  {opp['symbol']}: {opp['signal'].upper()} @ {opp['confidence']:.0%} confidence")
    else:
        print("\nNo high-confidence trade opportunities at this time.")
    
    return results

if __name__ == "__main__":
    analyze_all()
