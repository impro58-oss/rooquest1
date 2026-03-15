"""
trojanlogic_demo.py — Demo Runner for TrojanLogic4H
Tests the improved 4H strategy with simulated data
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import pandas as pd
from trojanlogic_4h import TrojanLogic4H, calculate_position_size_from_stop
from demo_data_feed import DemoDataFeed
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich import box

console = Console()


def run_trojanlogic_demo(scenario: str = 'rangebound'):
    """
    Run TrojanLogic4H demo with simulated 4H data.
    
    Args:
        scenario: Market scenario to simulate
    """
    console.print(f"\n[bold cyan]=== TROJANLOGIC 4H DEMO: {scenario.upper()} ===[/bold cyan]")
    
    # Generate demo data
    feed = DemoDataFeed()
    df = feed.generate_scenario_data(scenario)
    
    # Ensure we have OHLC columns
    if 'open' not in df.columns:
        df['open'] = df['close'].shift(1).fillna(df['close'])
    if 'high' not in df.columns:
        df['high'] = df[['open', 'close']].max(axis=1) * 1.02
    if 'low' not in df.columns:
        df['low'] = df[['open', 'close']].min(axis=1) * 0.98
    
    # Run analysis
    engine = TrojanLogic4H()
    result = engine.analyze(df)
    
    # Display results
    display_trojanlogic_result(result)
    
    return result


def display_trojanlogic_result(result: dict):
    """Display TrojanLogic4H analysis results."""
    
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
        f"[bold]Setup Type:[/bold] {setup_type}\n"
        f"[bold]Confidence:[/bold] {confidence:.1%} ({trade_plan.get('confidence_label', 'N/A')})\n"
        f"[bold]Current Price:[/bold] ${price:,.2f}",
        title="TRADING SIGNAL",
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
        
        # Calculate position size example
        if stop and entry_zone:
            try:
                position_size = calculate_position_size_from_stop(
                    account_balance=10000,  # Example $10k account
                    risk_percent=1.0,       # 1% risk
                    entry_price=entry_zone[1],
                    stop_price=stop
                )
                trade_details += f"[bold]Position Size (1% risk):[/bold] {position_size:.4f} units"
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
    console.print(reasons_panel)
    console.print()


def run_all_scenarios():
    """Run all demo scenarios and compare results."""
    console.print("\n[bold]=== TROJANLOGIC 4H STRATEGY DEMO ===[/bold]")
    console.print("Improved 4H-only trading engine with advanced signal detection\n")
    
    scenarios = ['uptrend', 'downtrend', 'rangebound', 'volatile', 'breakout']
    results = []
    
    for scenario in scenarios:
        try:
            result = run_trojanlogic_demo(scenario)
            trade_plan = result.get('trade_plan', {})
            results.append({
                'scenario': scenario,
                'signal': trade_plan.get('signal', 'hold'),
                'confidence': trade_plan.get('confidence', 0),
                'setup_type': trade_plan.get('setup_type', 'none'),
                'price': result.get('price', 0)
            })
        except Exception as e:
            console.print(f"[red]Error in {scenario}: {e}[/red]")
    
    # Summary table
    console.print("\n[bold]=== SUMMARY ===[/bold]")
    table = Table(
        title="TrojanLogic4H Scan Results",
        box=box.ROUNDED
    )
    table.add_column("Scenario", style="cyan")
    table.add_column("Signal", justify="center")
    table.add_column("Confidence", justify="right")
    table.add_column("Setup", justify="center")
    table.add_column("Price", justify="right")
    
    for r in results:
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
            r['scenario'].title(),
            sig_str,
            conf_str,
            r['setup_type'],
            f"${r['price']:,.0f}"
        )
    
    console.print(table)
    console.print("\n[dim]Note: These are simulated 4H results for testing only.[/dim]")


def interactive_demo():
    """Interactive demo mode."""
    console.print("\n[bold]=== TROJANLOGIC 4H INTERACTIVE DEMO ===[/bold]\n")
    console.print("Advanced 4H trading strategy with:")
    console.print("  • CS RSI MTF state detection")
    console.print("  • RtoM channel slope & regime analysis")
    console.print("  • Liquidity sweep detection")
    console.print("  • Wick rejection analysis")
    console.print("  • Weighted confidence scoring")
    console.print("  • Auto-calculated stops & targets\n")
    
    scenarios = {
        '1': ('uptrend', 'Strong upward trend'),
        '2': ('downtrend', 'Strong downward trend'),
        '3': ('rangebound', 'Sideways movement'),
        '4': ('volatile', 'High volatility'),
        '5': ('breakout', 'Consolidation then breakout'),
        '6': ('random', 'Random market conditions'),
    }
    
    while True:
        console.print("\n[bold]Select scenario:[/bold]")
        for key, (name, desc) in scenarios.items():
            console.print(f"  {key}. {name.title()}: {desc}")
        console.print("  7. Run all scenarios")
        console.print("  8. Exit")
        
        choice = input("\nEnter choice (1-8): ").strip()
        
        if choice in scenarios:
            try:
                run_trojanlogic_demo(scenarios[choice][0])
            except Exception as e:
                console.print(f"[red]Error: {e}[/red]")
        elif choice == '7':
            run_all_scenarios()
        elif choice == '8':
            console.print("\n[green]Goodbye![/green]")
            break
        else:
            console.print("[red]Invalid choice. Please try again.[/red]")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        scenario = sys.argv[1]
        if scenario in ['uptrend', 'downtrend', 'rangebound', 'volatile', 'breakout', 'random']:
            run_trojanlogic_demo(scenario)
        elif scenario == 'all':
            run_all_scenarios()
        else:
            console.print(f"[red]Unknown scenario: {scenario}[/red]")
    else:
        interactive_demo()
