"""
analyze_trends.py — Analyze historical crypto data for patterns
"""
import json
import requests
from datetime import datetime, timedelta
from collections import defaultdict

NOTION_TOKEN = "ntn_R12262668454JRCXah04DVY4uPiw6HW9G1Z69TdAXJibKD"
DATABASE_ID = "32304917-58dd-81d8-a31e-fe277bf4b0d1"

headers = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28"
}

def query_database(filter_obj=None):
    """Query Notion database."""
    url = f"https://api.notion.com/v1/databases/{DATABASE_ID}/query"
    
    data = {}
    if filter_obj:
        data["filter"] = filter_obj
    
    response = requests.post(url, headers=headers, json=data)
    
    if response.status_code == 200:
        return response.json().get('results', [])
    else:
        print(f"Error querying database: {response.status_code}")
        return []

def analyze_symbol_trends(symbol, days=7):
    """Analyze trends for a specific symbol."""
    
    # Query last N days
    since = (datetime.now() - timedelta(days=days)).isoformat()
    
    filter_obj = {
        "and": [
            {
                "property": "Symbol",
                "title": {"equals": symbol}
            },
            {
                "property": "Timestamp",
                "date": {"after": since}
            }
        ]
    }
    
    results = query_database(filter_obj)
    
    if not results:
        return None
    
    # Extract data
    signals = []
    prices = []
    confidences = []
    csrsi_values = []
    
    for r in results:
        props = r.get('properties', {})
        
        signal = props.get('Signal', {}).get('select', {}).get('name', 'HOLD')
        price = props.get('Price', {}).get('number', 0)
        confidence = props.get('Confidence %', {}).get('number', 0)
        csrsi = props.get('CS RSI Red', {}).get('number', 0)
        
        signals.append(signal)
        prices.append(price)
        confidences.append(confidence)
        csrsi_values.append(csrsi)
    
    # Calculate trends
    analysis = {
        'symbol': symbol,
        'data_points': len(results),
        'signals': {
            'LONG': signals.count('LONG'),
            'SHORT': signals.count('SHORT'),
            'HOLD': signals.count('HOLD')
        },
        'avg_confidence': sum(confidences) / len(confidences) if confidences else 0,
        'price_change': ((prices[-1] - prices[0]) / prices[0] * 100) if len(prices) > 1 and prices[0] > 0 else 0,
        'csrsi_trend': 'rising' if len(csrsi_values) > 1 and csrsi_values[-1] > csrsi_values[0] else 'falling',
        'latest_signal': signals[-1] if signals else 'HOLD',
        'latest_confidence': confidences[-1] if confidences else 0,
        'dominant_signal': max(set(signals), key=signals.count) if signals else 'HOLD'
    }
    
    return analysis

def generate_trend_report():
    """Generate comprehensive trend report."""
    
    print("=== CRYPTO INTELLIGENCE TREND REPORT ===\n")
    print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}\n")
    
    # Get unique symbols from last 7 days
    since = (datetime.now() - timedelta(days=7)).isoformat()
    
    filter_obj = {
        "property": "Timestamp",
        "date": {"after": since}
    }
    
    results = query_database(filter_obj)
    
    if not results:
        print("No data found in last 7 days")
        return
    
    # Extract unique symbols
    symbols = set()
    for r in results:
        symbol = r.get('properties', {}).get('Symbol', {}).get('title', [{}])[0].get('text', {}).get('content', '')
        if symbol:
            symbols.add(symbol)
    
    print(f"Analyzing {len(symbols)} symbols...\n")
    
    # Analyze each symbol
    all_analysis = []
    for symbol in sorted(symbols):
        analysis = analyze_symbol_trends(symbol, days=7)
        if analysis:
            all_analysis.append(analysis)
    
    # Summary statistics
    print("=== SIGNAL DISTRIBUTION ===")
    total_longs = sum(a['signals']['LONG'] for a in all_analysis)
    total_shorts = sum(a['signals']['SHORT'] for a in all_analysis)
    total_holds = sum(a['signals']['HOLD'] for a in all_analysis)
    
    print(f"LONG signals: {total_longs}")
    print(f"SHORT signals: {total_shorts}")
    print(f"HOLD signals: {total_holds}")
    print(f"Total data points: {sum(a['data_points'] for a in all_analysis)}\n")
    
    # Top movers
    print("=== TOP MOVERS (7 Days) ===")
    movers = sorted(all_analysis, key=lambda x: abs(x['price_change']), reverse=True)[:5]
    for m in movers:
        direction = "📈" if m['price_change'] > 0 else "📉"
        print(f"{direction} {m['symbol']}: {m['price_change']:+.2f}% ({m['signals']['LONG']}L/{m['signals']['SHORT']}S/{m['signals']['HOLD']}H)")
    
    print("\n=== HIGH CONFIDENCE SIGNALS ===")
    high_conf = [a for a in all_analysis if a['avg_confidence'] >= 0.45]
    if high_conf:
        for h in sorted(high_conf, key=lambda x: x['avg_confidence'], reverse=True)[:5]:
            print(f"🔥 {h['symbol']}: {h['avg_confidence']:.0%} avg confidence, {h['dominant_signal']} dominant")
    else:
        print("No high-confidence signals in last 7 days")
    
    print("\n=== CURRENT OPPORTUNITIES ===")
    opportunities = [a for a in all_analysis if a['latest_signal'] in ['LONG', 'SHORT'] and a['latest_confidence'] >= 0.45]
    if opportunities:
        for o in sorted(opportunities, key=lambda x: x['latest_confidence'], reverse=True):
            emoji = "🟢" if o['latest_signal'] == 'LONG' else "🔴"
            print(f"{emoji} {o['symbol']}: {o['latest_signal']} @ {o['latest_confidence']:.0%} confidence")
    else:
        print("No active opportunities")
    
    print("\n=== DATABASE STATS ===")
    print(f"Total symbols tracked: {len(symbols)}")
    print(f"Database URL: https://notion.so/{DATABASE_ID.replace('-', '')}")
    
    return all_analysis

if __name__ == "__main__":
    generate_trend_report()
