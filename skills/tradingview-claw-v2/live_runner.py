"""
live_runner.py — Live TrojanLogic4H with Real Market Data
Uses free Binance API to fetch live 4H candles and generate signals
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import pandas as pd
from datetime import datetime
from trojanlogic_4h import TrojanLogic4H
from free_data_feed import DataFeedManager
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich import box

console = Console()


def analyze_symbol(symbol: str, days_back: int = 60):
    """
    Fetch live data and run TrojanLogic4H analysis.
    
    Args:
        symbol: Trading pair (e.g., "BTCUSDT", "ETHUSDT")
        days_back: Days of history to fetch
    """
    console.print(f"\n[bold cyan]=== LIVE ANALYSIS: {symbol} ===[/bold cyan]")
    console.print(f"[dim]Fetching {days_back} days of 4H data from Binance...[/dim]\n")
    
    # Initialize data feed
    feed = DataFeedManager()
    
    try:
        # Fetch data
        df = feed.get_crypto_4h(symbol, days_back=days_back)
        
        console.print(f"[green]✓ Retrieved {len(df)} candles[/green]")
        console.print(f"[dim]Range: {df.index[0]} → {df.index[-1]}[/dim]\n")
        
        # Run analysis
        engine = TrojanLogic4H()
        result = engine.analyze(df)
        
        # Display results
        display_live_result(symbol, result, df)
        
        return result
        
    except Exception as e:
        console.print(f"[red]✗ Error: {e}[/red]")
        return None


def display_live_result(symbol: str, result: dict, df: pd.DataFrame):
    """Display live analysis results."""
    
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
        signal_emoji = '🟢'
    elif signal == 'short':
        signal_color = 'red'
        signal_emoji = '🔴'
    else:
        signal_color = 'yellow'
        signal_emoji = '⚪'
    
    # Main Signal Panel
    signal_panel = Panel(
        f"{signal_emoji} [bold {signal_color}]SIGNAL: {signal.upper()}[/bold {signal_color}]\n"
        f"[bold]Symbol:[/bold] {symbol}\n"
        f"[bold]Setup Type:[/bold] {setup_type}\n"
        f"[bold]Confidence:[/bold] {confidence:.1%} ({trade_plan.get('confidence_label', 'N/A')})\n"
        f"[bold]Current Price:[/bold] ${price:,.2f}",
        title="LIVE TRADING SIGNAL",
        border_style=signal_color,
        box=box.ROUNDED
    )
    
    # CS RSI State Panel
    csrsi_panel = Panel(
        f"[bold]State:[/bold] {csrsi.get('state', 'N/A')}\n"
        f"[bold]Zone:[/bold] {csrsi.get('zone', 'N/A')}\n"
        f"[bold]Red Line:[/bold] {csrsi.get('red_now', 0):.2f}\n"
        f"[bold]Upper Blue:[/bold] {csrsi.get('upper_blue_now', 0):.2f}\n"
        f"[bold]Lower Blue:[/bold] {csrsi.get('lower_blue_now', 0):.2f}\n"
        f"[bold]Cross:[/bold] {csrsi.get('cross', 'None')}\n"
        f"[bold]Cross Failure:[/bold] {csrsi.get('cross_failure', False)}",
        title="CS RSI MTF State",
        border_style="cyan",
        box=box.ROUNDED
    )
    
    # RtoM Structure Panel
    rtom_panel = Panel(
        f"[bold]Bias:[/bold] {rtom.get('bias', 'N/A')}\n"
        f"[bold]Regime:[/bold] {rtom.get('regime', 'N/A')}\n"
        f"[bold]Position:[/bold] {rtom.get('position', 'N/A')}\n"
        f"[bold]Slope Shift:[/bold] {rtom.get('slope_shift', 'N/A')}\n"
        f"[bold]Channel Width:[/bold] {rtom.get('width_now', 0):.2f}\n"
        f"[bold]200 SMA:[/bold] ${rtom.get('mid_now', 0):,.2f}",
        title="RtoM Channel Structure",
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
            f"[bold]Entry Zone:[/bold] ${entry_zone[0]:,.2f} - ${entry_zone[1]:,.2f}\n"
            f"[bold]Stop Loss:[/bold] ${stop:,.2f}\n"
            f"[bold]Target 1:[/bold] ${tp1:,.2f}\n"
            f"[bold]Target 2:[/bold] ${tp2:,.2f}\n"
            f"[bold]Invalidation:[/bold] {trade_plan.get('invalidation', 'N/A')}\n"
        )
        
        # Calculate position size
        if stop and entry_zone:
            from trojanlogic_4h import calculate_position_size_from_stop
            try:
                position_size = calculate_position_size_from_stop(
                    account_balance=10000,  # Example $10k
                    risk_percent=1.0,
                    entry_price=entry_zone[1],
                    stop_price=stop
                )
                trade_details += f"[bold]Position Size (1% risk):[/bold] {position_size:.6f} {symbol.replace('USDT', '')}"
            except:
                pass
    else:
        trade_details = "No active trade setup.\n"
    
    trade_panel = Panel(
        trade_details,
        title="Trade Plan",
        border_style=signal_color,
        box=box.ROUNDED
    )
    
    # Market Context Panel
    recent = df.tail(5)
    context_text = (
        f"[bold]Last 5 candles (4H):[/bold]\n"
        f"High: ${recent['high'].max():,.2f}\n"
        f"Low: ${recent['low'].min():,.2f}\n"
        f"Volume: {recent['volume'].sum():,.0f}\n"
        f"Range: {((recent['high'].max() - recent['low'].min()) / recent['close'].iloc[-1] * 100):.2f}%"
    )
    
    context_panel = Panel(
        context_text,
        title="Recent Market Context",
        border_style="dim",
        box=box.ROUNDED
    )
    
    # Reasons Panel
    reasons = trade_plan.get('reasons', [])
    warnings = trade_plan.get('warnings', [])
    
    reasons_text = ""
    if reasons:
        reasons_text += "[bold green]Reasons:[/bold green]\n" + "\n".join(f"  • {r}" for r in reasons)
    if warnings:
        reasons_text += "\n\n[bold yellow]Warnings:[/bold yellow]\n" + "\n".join(f"  ⚠ {w}" for w in warnings)
    
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
    console.print(context_panel)
    console.print(reasons_panel)
    console.print()


def scan_multiple(symbols: list, days_back: int = 60):
    """
    Scan multiple symbols and show summary.
    
    Args:
        symbols: List of trading pairs
        days_back: Days of history
    """
    console.print(f"\n[bold]=== SCANNING {len(symbols)} SYMBOLS ===[/bold]\n")
    
    results = []
    feed = DataFeedManager()
    engine = TrojanLogic4H()
    
    for symbol in symbols:
        try:
            console.print(f"[dim]Scanning {symbol}...[/dim]", end=" ")
            df = feed.get_crypto_4h(symbol, days_back=days_back)
            result = engine.analyze(df)
            trade_plan = result.get('trade_plan', {})
            
            results.append({
                'symbol': symbol,
                'signal': trade_plan.get('signal', 'hold'),
                'confidence': trade_plan.get('confidence', 0),
                'setup_type': trade_plan.get('setup_type', 'none'),
                'price': result.get('price', 0)
            })
            
            sig = trade_plan.get('signal', 'hold')
            conf = trade_plan.get('confidence', 0)
            
            if sig == 'long':
                console.print(f"[green]LONG {conf:.0%}[/green]")
            elif sig == 'short':
                console.print(f"[red]SHORT {conf:.0%}[/red]")
            else:
                console.print(f"[dim]HOLD[/dim]")
                
        except Exception as e:
            console.print(f"[red]ERROR: {e}[/red]")
    
    # Summary table
    console.print("\n[bold]=== SCAN RESULTS ===[/bold]")
    table = Table(
        title="TrojanLogic4H Market Scan",
        box=box.ROUNDED
    )
    table.add_column("Symbol", style="cyan")
    table.add_column("Signal", justify="center")
    table.add_column("Confidence", justify="right")
    table.add_column("Setup", justify="center")
    table.add_column("Price", justify="right")
    
    # Sort by confidence (highest first)
    results_sorted = sorted(results, key=lambda x: x['confidence'], reverse=True)
    
    for r in results_sorted:
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
        
        table.add_row(
            r['symbol'],
            sig_str,
            conf_str,
            r['setup_type'],
            f"${r['price']:,.2f}"
        )
    
    console.print(table)
    
    # Best opportunities
    opportunities = [r for r in results if r['signal'] != 'hold' and r['confidence'] >= 0.65]
    if opportunities:
        console.print(f"\n[bold green]🎯 {len(opportunities)} TRADE OPPORTUNITIES FOUND[/bold green]")
        for opp in sorted(opportunities, key=lambda x: x['confidence'], reverse=True):
            console.print(f"  {opp['symbol']}: {opp['signal'].upper()} @ {opp['confidence']:.0%} confidence")
    else:
        console.print("\n[dim]No high-confidence opportunities at this time.[/dim]")


def interactive_live_mode():
    """Interactive mode for live trading."""
    console.print("\n[bold]=== TROJANLOGIC4H LIVE MODE ===[/bold]\n")
    console.print("Using FREE Binance API (no key required)\n")
    
    popular_pairs = [
        "BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT",
        "XRPUSDT", "DOGEUSDT", "ADAUSDT", "AVAXUSDT",
        "LINKUSDT", "DOTUSDT", "MATICUSDT", "UNIUSDT"
    ]
    
    while True:
        console.print("\n[bold]Options:[/bold]")
        console.print("  1. Analyze single symbol")
        console.print("  2. Scan popular pairs")
        console.print("  3. Custom scan (enter symbols)")
        console.print("  4. Exit")
        
        choice = input("\nEnter choice (1-4): ").strip()
        
        if choice == '1':
            symbol = input("Enter symbol (e.g., BTCUSDT): ").strip().upper()
            if symbol:
                analyze_symbol(symbol, days_back=60)
                
        elif choice == '2':
            scan_multiple(popular_pairs, days_back=60)
            
        elif choice == '3':
            symbols_input = input("Enter symbols (comma-separated, e.g., BTCUSDT,ETHUSDT): ").strip()
            if symbols_input:
                symbols = [s.strip().upper() for s in symbols_input.split(',')]
                scan_multiple(symbols, days_back=60)
                
        elif choice == '4':
            console.print("\n[green]Goodbye![/green]")
            break
        else:
            console.print("[red]Invalid choice.[/red]")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        command = sys.argv[1].lower()
        
        if command == 'scan':
            # Scan popular pairs
            popular = ["BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT", "XRPUSDT"]
            scan_multiple(popular)
        elif command == 'btc':
            analyze_symbol("BTCUSDT")
        elif command == 'eth':
            analyze_symbol("ETHUSDT")
        else:
            # Analyze specific symbol
            analyze_symbol(command.upper())
    else:
        interactive_live_mode()
