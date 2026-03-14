"""
crypto_data_manager.py — Manage crypto scan data for GitHub storage
Writes to JSON files, auto-commits to GitHub, supports trend analysis
"""
import json
import os
from datetime import datetime
from pathlib import Path

# Config
DATA_DIR = Path("C:\\Users\\impro\\.openclaw\\workspace\\data\\crypto")
GITHUB_REPO = "impro58-oss/rooquest1"

def ensure_data_dir():
    """Ensure data directory exists."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    return DATA_DIR

def save_scan_results(results, timestamp=None):
    """
    Save scan results to JSON files for GitHub storage.
    
    Creates:
    - crypto_latest.json (overwritten each scan - for HF dashboard)
    - crypto_history.json (appended - for trend analysis)
    - YYYY-MM/YYYY-MM-DD.json (archived by date)
    """
    if timestamp is None:
        timestamp = datetime.now()
    
    data_dir = ensure_data_dir()
    
    # Prepare data structure
    scan_data = {
        "scan_timestamp": timestamp.isoformat(),
        "scan_date": timestamp.strftime("%Y-%m-%d"),
        "scan_time": timestamp.strftime("%H:%M:%S"),
        "total_symbols": len([r for r in results if 'error' not in r]),
        "signals_found": len([r for r in results if r.get('signal') in ['long', 'short'] and r.get('confidence', 0) >= 0.45]),
        "futures_opportunities": len([r for r in results if r.get('strategy') == 'FUTURES']),
        "hold_opportunities": len([r for r in results if r.get('strategy') == 'HOLD']),
        "results": results
    }
    
    # 1. Save to crypto_latest.json (for HF dashboard - single file)
    latest_file = data_dir / "crypto_latest.json"
    with open(latest_file, 'w', encoding='utf-8') as f:
        json.dump(scan_data, f, indent=2, default=str)
    
    # 2. Append to crypto_history.json (for trend analysis - cumulative)
    history_file = data_dir / "crypto_history.json"
    
    history_data = []
    if history_file.exists():
        try:
            with open(history_file, 'r', encoding='utf-8') as f:
                history_data = json.load(f)
        except:
            history_data = []
    
    # Add new scan to history
    history_data.append(scan_data)
    
    # Keep only last 30 days to manage file size (or last 500 scans)
    if len(history_data) > 500:
        history_data = history_data[-500:]
    
    with open(history_file, 'w', encoding='utf-8') as f:
        json.dump(history_data, f, indent=2, default=str)
    
    # 3. Save to dated archive (YYYY-MM/YYYY-MM-DD_HHMMSS.json)
    month_dir = data_dir / timestamp.strftime("%Y-%m")
    month_dir.mkdir(exist_ok=True)
    
    dated_file = month_dir / timestamp.strftime("%Y-%m-%d_%H%M%S.json")
    with open(dated_file, 'w', encoding='utf-8') as f:
        json.dump(scan_data, f, indent=2, default=str)
    
    return {
        "latest_file": str(latest_file),
        "history_file": str(history_file),
        "dated_file": str(dated_file),
        "scan_data": scan_data
    }

def get_trend_data(symbol=None, days=7):
    """
    Get trend data for analysis.
    
    Args:
        symbol: Specific symbol to analyze (None = all)
        days: Number of days to look back
    
    Returns:
        List of scan entries with trend analysis
    """
    history_file = DATA_DIR / "crypto_history.json"
    
    if not history_file.exists():
        return []
    
    with open(history_file, 'r', encoding='utf-8') as f:
        history = json.load(f)
    
    # Filter by date if needed
    cutoff = datetime.now() - __import__('datetime').timedelta(days=days)
    
    trend_data = []
    for scan in history:
        scan_time = datetime.fromisoformat(scan['scan_timestamp'])
        if scan_time >= cutoff:
            if symbol:
                # Filter to specific symbol
                symbol_results = [r for r in scan['results'] if r.get('symbol') == symbol and 'error' not in r]
                if symbol_results:
                    trend_data.append({
                        "timestamp": scan['scan_timestamp'],
                        "symbol_data": symbol_results[0]
                    })
            else:
                trend_data.append(scan)
    
    return trend_data

def generate_summary():
    """Generate summary statistics for dashboard."""
    history_file = DATA_DIR / "crypto_history.json"
    
    if not history_file.exists():
        return {"error": "No history data available"}
    
    with open(history_file, 'r', encoding='utf-8') as f:
        history = json.load(f)
    
    if not history:
        return {"error": "Empty history"}
    
    # Calculate metrics
    total_scans = len(history)
    total_signals = sum(s.get('signals_found', 0) for s in history)
    total_futures = sum(s.get('futures_opportunities', 0) for s in history)
    total_hold = sum(s.get('hold_opportunities', 0) for s in history)
    
    # Get unique symbols
    all_symbols = set()
    for scan in history:
        for result in scan.get('results', []):
            if 'symbol' in result:
                all_symbols.add(result['symbol'])
    
    # Latest scan info
    latest = history[-1] if history else {}
    
    return {
        "total_scans": total_scans,
        "total_signals": total_signals,
        "total_futures_opportunities": total_futures,
        "total_hold_opportunities": total_hold,
        "unique_symbols_tracked": len(all_symbols),
        "latest_scan": {
            "timestamp": latest.get('scan_timestamp'),
            "date": latest.get('scan_date'),
            "time": latest.get('scan_time'),
            "signals_found": latest.get('signals_found'),
            "total_symbols": latest.get('total_symbols')
        },
        "data_source": "github",
        "repo": GITHUB_REPO,
        "last_updated": datetime.now().isoformat()
    }

def export_for_huggingface():
    """
    Export data in format optimized for Hugging Face dashboard.
    Creates a single file with all necessary data.
    """
    data_dir = ensure_data_dir()
    
    # Load history
    history_file = data_dir / "crypto_history.json"
    if history_file.exists():
        with open(history_file, 'r', encoding='utf-8') as f:
            history = json.load(f)
    else:
        history = []
    
    # Load latest
    latest_file = data_dir / "crypto_latest.json"
    if latest_file.exists():
        with open(latest_file, 'r', encoding='utf-8') as f:
            latest = json.load(f)
    else:
        latest = {}
    
    # Generate summary
    summary = generate_summary()
    
    # Create HF-optimized export
    hf_data = {
        "summary": summary,
        "latest_scan": latest,
        "history": history[-30:] if len(history) > 30 else history,  # Last 30 scans
        "export_timestamp": datetime.now().isoformat(),
        "version": "1.0"
    }
    
    # Save to huggingface_data.json
    hf_file = data_dir / "huggingface_data.json"
    with open(hf_file, 'w', encoding='utf-8') as f:
        json.dump(hf_data, f, indent=2, default=str)
    
    return str(hf_file)

if __name__ == "__main__":
    # Test
    print("Crypto Data Manager")
    print(f"Data directory: {DATA_DIR}")
    
    # Show summary if data exists
    summary = generate_summary()
    print("\nSummary:")
    print(json.dumps(summary, indent=2))
