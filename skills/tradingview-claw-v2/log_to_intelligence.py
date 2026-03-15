"""
log_to_intelligence.py — Log crypto analysis results to Notion database
"""
import json
import requests
from datetime import datetime

NOTION_TOKEN = "ntn_R12262668454JRCXah04DVY4uPiw6HW9G1Z69TdAXJibKD"
DATABASE_ID = "32304917-58dd-81d8-a31e-fe277bf4b0d1"

headers = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28"
}

def get_confidence_label(confidence):
    """Get confidence label."""
    if confidence >= 0.85:
        return "STRONG"
    elif confidence >= 0.65:
        return "MODERATE"
    elif confidence >= 0.45:
        return "WEAK"
    else:
        return "WATCH"

def log_analysis_result(result):
    """Log a single analysis result to Notion."""
    
    url = "https://api.notion.com/v1/pages"
    
    # Build properties
    properties = {
        "Symbol": {
            "title": [{"text": {"content": result.get('symbol', 'UNKNOWN')}}]
        },
        "Timestamp": {
            "date": {"start": result.get('timestamp', datetime.now().isoformat())}
        },
        "Price": {
            "number": result.get('price', 0)
        },
        "Signal": {
            "select": {"name": result.get('signal', 'hold').upper()}
        },
        "Confidence %": {
            "number": result.get('confidence', 0)
        },
        "Confidence Label": {
            "select": {"name": get_confidence_label(result.get('confidence', 0))}
        },
        "Setup Type": {
            "select": {"name": result.get('setup_type', 'none')}
        },
        "Strategy": {
            "select": {"name": result.get('strategy', 'MONITOR')}
        },
        "CS RSI State": {
            "select": {"name": result.get('csrsi_state', 'neutral')}
        },
        "CS RSI Red": {
            "number": result.get('csrsi_red', 0)
        },
        "CS RSI Upper Blue": {
            "number": result.get('csrsi_upper_blue', 0)
        },
        "CS RSI Lower Blue": {
            "number": result.get('csrsi_lower_blue', 0)
        },
        "RtoM Bias": {
            "select": {"name": result.get('rtom_bias', 'flat')}
        },
        "RtoM Regime": {
            "select": {"name": result.get('rtom_regime', 'stable')}
        },
        "RtoM Position": {
            "select": {"name": result.get('rtom_position', 'mid_zone')}
        },
        "200 SMA": {
            "number": result.get('rtom_200sma', 0)
        },
        "Compression": {
            "checkbox": result.get('compression', False)
        },
        "Liquidity Sweep": {
            "select": {"name": result.get('liquidity_sweep', 'none')}
        },
        "Wick Rejection": {
            "select": {"name": result.get('wick_rejection', 'none')}
        },
        "Data Source": {
            "select": {"name": result.get('data_source', 'Unknown')}
        },
        "Candles": {
            "number": result.get('candles', 0)
        },
        "Analysis Notes": {
            "rich_text": [{"text": {"content": ', '.join(result.get('reasons', []))[:500]}}]
        }
    }
    
    data = {
        "parent": {"database_id": DATABASE_ID},
        "properties": properties
    }
    
    response = requests.post(url, headers=headers, json=data)
    
    if response.status_code == 200:
        return True
    else:
        print(f"Error logging {result.get('symbol')}: {response.status_code}")
        return False

def log_batch_from_file(filename):
    """Log all results from an analysis file."""
    
    try:
        with open(filename, 'r') as f:
            data = json.load(f)
    except Exception as e:
        print(f"Error loading file: {e}")
        return
    
    results = data.get('results', [])
    print(f"Logging {len(results)} results to Notion...\n")
    
    success_count = 0
    for result in results:
        if 'error' not in result:
            if log_analysis_result(result):
                success_count += 1
                print(f"[OK] Logged {result.get('symbol')}")
        else:
            print(f"[SKIP] {result.get('symbol')} - has error")
    
    print(f"\n[OK] Successfully logged {success_count}/{len(results)} entries")
    print(f"Database: https://notion.so/{DATABASE_ID.replace('-', '')}")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        filename = sys.argv[1]
    else:
        # Find most recent analysis file
        import glob
        files = glob.glob('top_*_analysis_*.json')
        if files:
            filename = sorted(files)[-1]
        else:
            print("No analysis files found")
            sys.exit(1)
    
    print(f"=== Logging results from {filename} ===\n")
    log_batch_from_file(filename)
