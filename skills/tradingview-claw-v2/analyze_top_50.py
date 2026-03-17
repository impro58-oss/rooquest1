"""
analyze_top_50.py — Run TrojanLogic4H on top 50 cryptos with strategy tagging
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import json
import time
from datetime import datetime
from trojanlogic_4h import TrojanLogic4H
from multi_source_feed import MultiSourceFeed
from crypto_data_manager import save_scan_results, export_for_huggingface

# Get top 50 from Binance
def get_top_50():
    import requests
    url = 'https://api.binance.com/api/v3/ticker/24hr'
    response = requests.get(url, timeout=30)
    data = response.json()
    
    # Filter USDT pairs, exclude stablecoins
    exclude = ['USDCUSDT', 'USDTUSDT', 'BUSDUSDT', 'DAIUSDT', 'TUSDUSDT', 'FDUSDUSDT']
    usdt_pairs = [d for d in data if d['symbol'].endswith('USDT') and d['symbol'] not in exclude]
    usdt_pairs.sort(key=lambda x: float(x['quoteVolume']), reverse=True)
    
    return [p['symbol'] for p in usdt_pairs[:50]]

def determine_strategy(symbol, result):
    """Determine if this is a FUTURES trade or HOLD accumulation."""
    
    # Long-term hold list (your core convictions)
    HOLD_LIST = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'XRPUSDT', 'DOGEUSDT', 'BNBUSDT', 'LINKUSDT']
    
    signal = result.get('signal', 'hold')
    confidence = result.get('confidence', 0)
    setup_type = result.get('setup_type', 'none')
    rtom_regime = result.get('rtom_structure', {}).get('regime', 'stable')
    
    # If it's in hold list and we have a signal, mark as HOLD strategy
    if symbol in HOLD_LIST and signal in ['long', 'short'] and confidence >= 0.45:
        return 'HOLD'
    
    # If it's a high-confidence reversal in compression, could be futures
    if signal in ['long', 'short'] and confidence >= 0.65 and setup_type == 'reversal':
        return 'FUTURES'
    
    # If it's a continuation signal, could be futures
    if signal in ['long', 'short'] and confidence >= 0.55 and setup_type == 'continuation':
        return 'FUTURES'
    
    # Default: no strategy (just monitoring)
    return 'MONITOR'

def analyze_all():
    """Analyze top 50 and generate report."""
    print("=== TROJANLOGIC4H: TOP 50 CRYPTO ANALYSIS ===\n")
    print(f"Analysis Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}\n")
    
    TOP_50 = get_top_50()
    print(f"Analyzing top {len(TOP_50)} symbols by 24h volume...\n")
    
    feed = MultiSourceFeed()
    engine = TrojanLogic4H()
    
    results = []
    futures_opportunities = []
    hold_opportunities = []
    
    for i, symbol in enumerate(TOP_50, 1):
        try:
            print(f"[{i}/50] Analyzing {symbol}...", end=" ")
            df, info = feed.get_data_with_validation(symbol, days_back=60)
            result = engine.analyze(df)
            
            trade_plan = result.get('trade_plan', {})
            csrsi = result.get('csrsi_state', {})
            rtom = result.get('rtom_structure', {})
            
            # Determine strategy
            strategy = determine_strategy(symbol, result)
            
            analysis = {
                'symbol': symbol,
                'timestamp': datetime.now().isoformat(),
                'price': result.get('price', 0),
                'signal': trade_plan.get('signal', 'hold'),
                'confidence': trade_plan.get('confidence', 0),
                'confidence_label': trade_plan.get('confidence_label', 'none'),
                'setup_type': trade_plan.get('setup_type', 'none'),
                'strategy': strategy,
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
            
            # Categorize opportunities
            sig = analysis['signal']
            conf = analysis['confidence']
            
            if sig in ['long', 'short'] and conf >= 0.45:
                if strategy == 'FUTURES':
                    futures_opportunities.append(analysis)
                elif strategy == 'HOLD':
                    hold_opportunities.append(analysis)
            
            # Visual output
            if sig == 'long':
                print(f"[LONG {conf:.0%}] [{strategy}]")
            elif sig == 'short':
                print(f"[SHORT {conf:.0%}] [{strategy}]")
            else:
                print(f"[HOLD]")
            
            # Rate limiting
            time.sleep(0.1)
                
        except Exception as e:
            print(f"[ERROR: {str(e)[:30]}]")
            results.append({
                'symbol': symbol,
                'timestamp': datetime.now().isoformat(),
                'error': str(e)
            })
    
    # Save results
    output_file = f"top_50_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
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
            'results': results,
            'summary': {
                'total_scanned': len([r for r in results if 'error' not in r]),
                'futures_opportunities': len(futures_opportunities),
                'hold_opportunities': len(hold_opportunities),
                'futures_list': [{'symbol': o['symbol'], 'signal': o['signal'], 'confidence': o['confidence']} for o in futures_opportunities],
                'hold_list': [{'symbol': o['symbol'], 'signal': o['signal'], 'confidence': o['confidence']} for o in hold_opportunities]
            }
        }, f, indent=2)
    
    print(f"\n=== SUMMARY ===")
    print(f"Analysis saved to: {output_file}")
    print(f"Total scanned: {len([r for r in results if 'error' not in r])}/50")
    
    # Save to GitHub data files
    print("\n[SAVING] Exporting to GitHub data files...")
    try:
        data_info = save_scan_results(results, timestamp=datetime.now())
        print(f"[OK] Latest scan: {data_info['latest_file']}")
        print(f"[OK] History: {data_info['history_file']}")
        print(f"[OK] Archive: {data_info['dated_file']}")
        
        # Export for Hugging Face
        hf_file = export_for_huggingface()
        print(f"[OK] Hugging Face export: {hf_file}")
    except Exception as e:
        print(f"[WARN] Data export error: {e}")
    
    print(f"\n>>> FUTURES OPPORTUNITIES ({len(futures_opportunities)}) <<<")
    if futures_opportunities:
        for opp in sorted(futures_opportunities, key=lambda x: x['confidence'], reverse=True):
            emoji = "🟢" if opp['signal'] == 'long' else "🔴"
            print(f"  {emoji} {opp['symbol']}: {opp['signal'].upper()} @ {opp['confidence']:.0%} confidence")
    else:
        print("  No futures opportunities at this time")
    
    print(f"\n>>> HOLD ACCUMULATION OPPORTUNITIES ({len(hold_opportunities)}) <<<")
    if hold_opportunities:
        for opp in sorted(hold_opportunities, key=lambda x: x['confidence'], reverse=True):
            emoji = "🟢" if opp['signal'] == 'long' else "🔴"
            print(f"  {emoji} {opp['symbol']}: {opp['signal'].upper()} @ {opp['confidence']:.0%} confidence")
    else:
        print("  No hold opportunities at this time")
    
    return results, futures_opportunities, hold_opportunities

if __name__ == "__main__":
    analyze_all()
