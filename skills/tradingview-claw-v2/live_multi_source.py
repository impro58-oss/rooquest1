"""
live_multi_source.py — Live TrojanLogic4H with Multi-Source Free Data
Uses multiple free APIs with automatic fallback
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import pandas as pd
from datetime import datetime
from trojanlogic_4h import TrojanLogic4H
from multi_source_feed import MultiSourceFeed
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich import box

console = Console()


def analyze_live(symbol: str = "BTCUSDT", days_back: int = 60):
    """
    Fetch live data from multiple free sources and analyze.
    
    Args:
        symbol: Trading pair (e.g., "BTCUSDT", "ETHUSDT")
        days_back: Days of history to fetch
    """
    console.print(f"\n[bold cyan]=== LIVE ANALYSIS: {symbol} ===[/bold cyan]")
    console.print(f"[dim]Fetching {days_back} days from free data sources...[/dim]\n")
    
    # Initialize multi-source feed
    feed = MultiSourceFeed()
    
    try:
        # Fetch data with fallback
        df, info = feed.get_data_with_validation(symbol, days_back)
        
        console.print(f"[green][OK] Data from {info['source']}[/green]")
        console.print(f"[dim]Candles: {info['candles']} | Range: {info['date_range']}[/dim]\n")
        
        # Check if we have enough data for TrojanLogic4H
        if len(df) < 220:
            console.print(f"[yellow]Warning: Only {len(df)} candles, need 220+ for stable signals[/yellow]")
        
        # Run analysis
        engine = TrojanLogic4H()
        result = engine.analyze(df)
        
        # Display results
        display_result(symbol, result, df, info['source'])
        
        return result
        
    except Exception as e:
        console.print(f"[red][FAILED] {e}[/red]")
        return None


def display_result(symbol: str, result: dict, df: pd.DataFrame, source: str):
    """Display analysis results."""
    
    price = result.get('price', 0)
    trade_plan = result.get('trade_plan', {})
    csrsi = result.get('csrsi_state', {})
    rtom = result.get('rtom_structure', {})
    
    signal = trade_plan.get('signal', 'hold')
    confidence = trade_plan.get('confidence', 0)
    setup_type = trade_plan.get('setup_type', 'none')
    
    # Color based on signal
    if signal == 'long':
        signal_color = 'green'
        signal_emoji = 'LONG'
    elif signal == 'short':
        signal_color = 'red'
        signal_emoji = 'SHORT'
    else:
        signal_color = 'yellow'
        signal_emoji = 'HOLD'
    
    # Main Signal Panel
    signal_panel = Panel(
        f"[bold {signal_color}]{signal_emoji} SIGNAL[/bold {signal_color}]\n"
        f"[bold]Symbol:[/bold] {symbol}\n"
        f"[bold]Source:[/bold] {source}\n"
        f"[bold]Setup:[/bold] {setup_type}\n"
        f"[bold]Confidence:[/bold] {confidence:.1%} ({trade_plan.get('confidence_label', 'N/A')})\n"
        f"[bold]Price:[/bold] ${price:,.2f}",
        title="LIVE TRADING SIGNAL",
        border_style=signal_color,
        box=box.ROUNDED
    )
    
    # CS RSI Panel
    csrsi_panel = Panel(
        f"[bold]State:[/bold] {csrsi.get('state', 'N/A')}\n"
        f"[bold]Zone:[/bold] {csrsi.get('zone', 'N/A')}\n"
        f"[bold]Red:[/bold] {csrsi.get('red_now', 0):.2f}\n"
        f"[bold]Upper Blue:[/bold] {csrsi.get('upper_blue_now', 0):.2f}\n"
        f"[bold]Lower Blue:[/bold] {csrsi.get('lower_blue_now', 0):.2f}\n"
        f"[bold]Cross:[/bold] {csrsi.get('cross', 'None')}",
        title="CS RSI MTF",
        border_style="cyan",
        box=box.ROUNDED
    )
    
    # RtoM Panel
    rtom_panel = Panel(
        f"[bold]Bias:[/bold] {rtom.get('bias', 'N/A')}\n"
        f"[bold]Regime:[/bold] {rtom.get('regime', 'N/A')}\n"
        f"[bold]Position:[/bold] {rtom.get('position', 'N/A')}\n"
        f"[bold]Slope:[/bold] {rtom.get('slope_shift', 'N/A')}\n"
        f"[bold]200 SMA:[/bold] ${rtom.get('mid_now', 0):,.2f}",
        title="RtoM Channels",
        border_style="blue",
        box=box.ROUNDED
    )
    
    # Trade Plan Panel
    if signal != 'hold':
        entry_zone = trade_plan.get('entry_zone', [])
        stop = trade_plan.get('stop_loss')
        tp1 = trade_plan.get('tp1')
        tp2 = trade_plan.get('tp2')
        
        trade_details = (
            f"[bold]Entry:[/bold] ${entry_zone[0]:,.2f} - ${entry_zone[1]:,.2f}\n"
            f"[bold]Stop:[/bold] ${stop:,.2f}\n"
            f"[bold]TP1:[/bold] ${tp1:,.2f}\n"
            f"[bold]TP2:[/bold] ${tp2:,.2f}\n"
            f"[bold]Invalid:[/bold] {trade_plan.get('invalidation', 'N/A')}\n"
        )
        
        # Position size
        if stop and entry_zone:
            from trojanlogic_4h import calculate_position_size_from_stop
            try:
                size = calculate_position_size_from_stop(
                    account_balance=10000,
                    risk_percent=1.0,
                    entry_price=entry_zone[1],
                    stop_price=stop
                )
                trade_details += f"[bold]Size (1% risk):[/bold] {size:.4f}"
            except:
                pass
    else:
        trade_details = "No active setup.\n"
    
    trade_panel = Panel(
        trade_details,
        title="Trade Plan",
        border_style=signal_color,
        box=box.ROUNDED
    )
    
    # Reasons Panel
    reasons = trade_plan.get('reasons', [])
    warnings = trade_plan.get('warnings', [])
    
    reasons_text = ""
    if reasons:
        reasons_text += "[bold green]Reasons:[/bold green]\n" + "\n".join(f"  - {r}" for r in reasons)
    if warnings:
        reasons_text += "\n\n[bold yellow]Warnings:[/bold yellow]\n" + "\n".join(f"  ! {w}" for w in warnings)
    
    reasons_panel = Panel(
        reasons_text if reasons_text else "No specific reasons.",
        title="Analysis",
        border_style="dim",
        box=box.ROUNDED
    )
    
    # Print all panels
    console.print(signal_panel)
    console.print(csrsi_panel)
    console.print(rtom_panel)
    console.print(trade_panel)
    console.print(reasons_panel)
    console.print()


def scan_market(symbols: list, days_back: int = 60):
    """Scan multiple symbols and show opportunities."""
    console.print(f"\n[bold]=== MARKET SCAN: {len(symbols)} SYMBOLS ===[/bold]\n")
    
    results = []
    feed = MultiSourceFeed()
    engine = TrojanLogic4H()
    
    for symbol in symbols:
        try:
            console.print(f"[dim]Scanning {symbol}...[/dim]", end=" ")
            df, _ = feed.get_data_with_validation(symbol, days_back)
            result = engine.analyze(df)
            trade_plan = result.get('trade_plan', {})
            
            sig = trade_plan.get('signal', 'hold')
            conf = trade_plan.get('confidence', 0)
            
            results.append({
                'symbol': symbol,
                'signal': sig,
                'confidence': conf,
                'setup': trade_plan.get('setup_type', 'none'),
                'price': result.get('price', 0)
            })
            
            if sig == 'long':
                console.print(f"[green]LONG {conf:.0%}[/green]")
            elif sig == 'short':
                console.print(f"[red]SHORT {conf:.0%}[/red]")
            else:
                console.print(f"[dim]HOLD[/dim]")
                
        except Exception as e:
            console.print(f"[red]ERROR[/red]")
    
    # Summary table
    console.print("\n[bold]=== RESULTS ===[/bold]")
    table = Table(box=box.ROUNDED)
    table.add_column("Symbol", style="cyan")
    table.add_column("Signal", justify="center")
    table.add_column("Confidence", justify="right")
    table.add_column("Setup", justify="center")
    table.add_column("Price", justify="right")
    
    for r in sorted(results, key=lambda x: x['confidence'], reverse=True):
        sig = r['signal']
        conf = r['confidence']
        
        if sig == 'long':
            sig_str = "[green]LONG[/green]"
        elif sig == 'short':
            sig_str = "[red]SHORT[/red]"
        else:
            sig_str = "[dim]HOLD[/dim]"
        
        if conf >= 0.85:
            conf_str = f"[bold green]{conf:.0%}[/bold green]"
        elif conf >= 0.65:
            conf_str = f"[green]{conf:.0%}[/green]"
        elif conf >= 0.45:
            conf_str = f"[yellow]{conf:.0%}[/yellow]"
        else:
            conf_str = f"[dim]{conf:.0%}[/dim]"
        
        table.add_row(r['symbol'], sig_str, conf_str, r['setup'], f"${r['price']:,.2f}")
    
    console.print(table)
    
    # Opportunities
    opps = [r for r in results if r['signal'] != 'hold' and r['confidence'] >= 0.65]
    if opps:
        console.print(f"\n[bold green]>>> {len(opps)} OPPORTUNITIES <<<[/bold green]")
        for o in sorted(opps, key=lambda x: x['confidence'], reverse=True):
            console.print(f"  {o['symbol']}: {o['signal'].upper()} @ {o['confidence']:.0%}")
    else:
        console.print("\n[dim]No high-confidence setups.[/dim]")


def interactive_mode():
    """Interactive trading mode."""
    console.print("\n[bold]=== TROJANLOGIC4H LIVE ===[/bold]\n")
    console.print("Multi-source free data feed")
    console.print("Sources: Binance, CoinGecko, Kraken, CryptoCompare\n")
    
    popular = [
        "BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT",
        "XRPUSDT", "DOGEUSDT", "ADAUSDT", "AVAXUSDT",
        "LINKUSDT", "DOTUSDT", "MATICUSDT", "UNIUSDT"
    ]
    
    while True:
        console.print("\n[bold]Menu:[/bold]")
        console.print("  1. Analyze single symbol")
        console.print("  2. Scan popular pairs")
        console.print("  3. Custom scan")
        console.print("  4. Test data sources")
        console.print("  5. Exit")
        
        choice = input("\nChoice (1-5): ").strip()
        
        if choice == '1':
            sym = input("Symbol (e.g., BTCUSDT): ").strip().upper()
            if sym:
                analyze_live(sym)
        elif choice == '2':
            scan_market(popular)
        elif choice == '3':
            syms = input("Symbols (comma-separated): ").strip()
            if syms:
                scan_market([s.strip().upper() for s in syms.split(',')])
        elif choice == '4':
            feed = MultiSourceFeed()
            feed.test_all_sources("BTCUSDT")
        elif choice == '5':
            console.print("\n[green]Goodbye![/green]")
            break
        else:
            console.print("[red]Invalid choice.[/red]")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        cmd = sys.argv[1].lower()
        
        if cmd == 'scan':
            scan_market(["BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT", "XRPUSDT"])
        elif cmd == 'btc':
            analyze_live("BTCUSDT")
        elif cmd == 'eth':
            analyze_live("ETHUSDT")
        else:
            analyze_live(cmd.upper())
    else:
        interactive_mode()
