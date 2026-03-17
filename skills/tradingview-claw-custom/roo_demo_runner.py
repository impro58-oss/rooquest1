"""
roo_demo_runner.py — Demo Runner for Roo's Strategy
Tests the strategy with simulated data (no real money, no API keys needed)
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from demo_data_feed import DemoDataFeed, DEMO_SCENARIOS
from custom_indicators import RooSignalEngine
from rich.console import Console
from rich.table import Table
from rich.panel import Panel

console = Console()


def run_demo_scenario(scenario: str = 'rangebound'):
    """
    Run a demo scenario with simulated data.
    
    Args:
        scenario: One of 'uptrend', 'downtrend', 'rangebound', 'volatile', 'breakout', 'random'
    """
    console.print(f"\n[bold cyan]=== DEMO: {scenario.upper()} ===[/bold cyan]")
    console.print(f"[dim]{DEMO_SCENARIOS.get(scenario, 'Random market data')}[/dim]\n")
    
    # Generate demo data
    feed = DemoDataFeed()
    df = feed.generate_scenario_data(scenario)
    
    # Run analysis
    engine = RooSignalEngine()
    analysis = engine.analyze(df)
    
    # Display results
    display_analysis(analysis, scenario)
    
    return analysis


def display_analysis(analysis: dict, scenario: str):
    """Display signal analysis."""
    
    # Price info
    current_price = analysis.get('current_price', 0)
    console.print(f"[bold]Current Price:[/bold] ${current_price:,.2f}")
    
    # CS RSI MTF Panel
    rsi = analysis.get('cs_rsi', {})
    rsi_panel = Panel(
        f"[bold]Red Line (13):[/bold] {rsi.get('red_line', 0):.2f}\n"
        f"[bold]Upper Blue (64):[/bold] {rsi.get('upper_blue', 0):.2f}\n"
        f"[bold]Lower Blue (64):[/bold] {rsi.get('lower_blue', 0):.2f}\n"
        f"[bold]Signal:[/bold] {rsi.get('signal', 'N/A')}\n"
        f"[dim]{rsi.get('context', '')}[/dim]",
        title="CS RSI MTF",
        border_style="cyan"
    )
    
    # Dual Channel Panel
    ch = analysis.get('channels', {})
    channel_panel = Panel(
        f"[bold]200 SMA:[/bold] ${ch.get('sma', 0):,.2f}\n"
        f"[bold]Inner Upper (1.0x):[/bold] ${ch.get('inner_upper', 0):,.2f}\n"
        f"[bold]Inner Lower (1.0x):[/bold] ${ch.get('inner_lower', 0):,.2f}\n"
        f"[bold]Outer Upper (2.415x):[/bold] ${ch.get('outer_upper', 0):,.2f}\n"
        f"[bold]Outer Lower (2.415x):[/bold] ${ch.get('outer_lower', 0):,.2f}\n"
        f"[bold]Zone:[/bold] {ch.get('zone', 'N/A')}",
        title="Dual Channels",
        border_style="blue"
    )
    
    # Combined Signal
    signal = analysis.get('combined_signal', 'neutral')
    confidence = analysis.get('confidence', 0.0)
    action = analysis.get('suggested_action', 'HOLD')
    
    if signal == 'buy':
        color = "green"
    elif signal == 'sell':
        color = "red"
    else:
        color = "yellow"
    
    signal_panel = Panel(
        f"[bold {color}]SIGNAL: {signal.upper()}[/bold {color}]\n"
        f"[bold]Confidence:[/bold] {confidence:.0%}\n"
        f"[bold]Action:[/bold] {action}",
        title="TRADING SIGNAL",
        border_style=color
    )
    
    console.print(rsi_panel)
    console.print(channel_panel)
    console.print(signal_panel)
    console.print()


def run_all_scenarios():
    """Run all demo scenarios and compare results."""
    console.print("\n[bold]=== ROO'S STRATEGY DEMO ===[/bold]")
    console.print("Testing with simulated market data (no real money)\n")
    
    results = []
    
    for scenario in ['uptrend', 'downtrend', 'rangebound', 'volatile', 'breakout']:
        analysis = run_demo_scenario(scenario)
        results.append({
            'scenario': scenario,
            'signal': analysis.get('combined_signal'),
            'confidence': analysis.get('confidence', 0),
            'price': analysis.get('current_price', 0)
        })
    
    # Summary table
    console.print("\n[bold]=== SUMMARY ===[/bold]")
    table = Table()
    table.add_column("Scenario", style="cyan")
    table.add_column("Signal", justify="center")
    table.add_column("Confidence", justify="right")
    table.add_column("Price", justify="right")
    
    for r in results:
        sig = r['signal']
        conf = r['confidence']
        
        if sig == 'buy':
            sig_str = "[green]BUY[/green]"
        elif sig == 'sell':
            sig_str = "[red]SELL[/red]"
        else:
            sig_str = "[yellow]HOLD[/yellow]"
        
        if conf >= 0.90:
            conf_str = f"[bold green]{conf:.0%}[/bold green]"
        elif conf >= 0.75:
            conf_str = f"[green]{conf:.0%}[/green]"
        elif conf >= 0.60:
            conf_str = f"[yellow]{conf:.0%}[/yellow]"
        else:
            conf_str = f"[dim]{conf:.0%}[/dim]"
        
        table.add_row(
            r['scenario'].title(),
            sig_str,
            conf_str,
            f"${r['price']:,.0f}"
        )
    
    console.print(table)
    console.print("\n[dim]Note: These are simulated results for testing only.[/dim]")


def interactive_demo():
    """Interactive demo mode."""
    console.print("\n[bold]=== ROO'S TRADING STRATEGY DEMO ===[/bold]\n")
    console.print("This demo uses simulated market data to test the strategy.")
    console.print("No real money, no API keys needed.\n")
    
    while True:
        console.print("\n[bold]Choose a scenario:[/bold]")
        for i, (key, desc) in enumerate(DEMO_SCENARIOS.items(), 1):
            console.print(f"  {i}. {key.title()}: {desc}")
        console.print("  7. Run all scenarios")
        console.print("  8. Exit")
        
        choice = input("\nEnter choice (1-8): ").strip()
        
        if choice == '1':
            run_demo_scenario('uptrend')
        elif choice == '2':
            run_demo_scenario('downtrend')
        elif choice == '3':
            run_demo_scenario('rangebound')
        elif choice == '4':
            run_demo_scenario('volatile')
        elif choice == '5':
            run_demo_scenario('breakout')
        elif choice == '6':
            run_demo_scenario('random')
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
        if scenario in DEMO_SCENARIOS:
            run_demo_scenario(scenario)
        elif scenario == 'all':
            run_all_scenarios()
        else:
            console.print(f"[red]Unknown scenario: {scenario}[/red]")
            console.print(f"Available: {', '.join(DEMO_SCENARIOS.keys())}")
    else:
        interactive_demo()
