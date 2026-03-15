"""
roo_signal_scanner.py — Custom Signal Scanner for Roo's Strategy
Integrates with TradingView-Claw
"""
import json
import os
from datetime import datetime
from typing import List, Dict, Optional
from rich.console import Console
from rich.table import Table
from rich.panel import Panel

# Import custom indicators
from custom_indicators import RooSignalEngine, DEFAULT_PARAMS

console = Console()


class RooSignalScanner:
    """
    Scanner for Roo's CS RSI MTF + Dual Channel strategy
    """
    
    def __init__(self, params: Optional[Dict] = None):
        self.params = params or DEFAULT_PARAMS
        self.engine = RooSignalEngine(
            rsi_short=self.params['rsi_short_cycle'],
            rsi_long=self.params['rsi_long_cycle'],
            channel_lookback=self.params['channel_lookback'],
            inner_mult=self.params['inner_multiplier'],
            outer_mult=self.params['outer_multiplier']
        )
    
    def scan_symbol(self, symbol: str, timeframe: str = "1W") -> Dict:
        """
        Scan a single symbol for signals.
        
        Args:
            symbol: Trading symbol (e.g., "BTCUSD", "AAPL")
            timeframe: Chart timeframe (default "1W" for weekly)
        
        Returns:
            Signal analysis dictionary
        """
        # This would integrate with TradingView-Claw's TVClient
        # For now, returning structure
        
        return {
            'symbol': symbol,
            'timeframe': timeframe,
            'timestamp': datetime.now().isoformat(),
            'params': self.params,
            'signal': None,  # Would be populated with real data
            'confidence': 0.0
        }
    
    def scan_multiple(self, symbols: List[str], timeframe: str = "1W") -> List[Dict]:
        """Scan multiple symbols and return ranked results."""
        results = []
        
        for symbol in symbols:
            result = self.scan_symbol(symbol, timeframe)
            if result['signal'] is not None:
                results.append(result)
        
        # Sort by confidence (highest first)
        results.sort(key=lambda x: x['confidence'], reverse=True)
        return results
    
    def display_signal(self, analysis: Dict):
        """Display signal analysis in formatted output."""
        
        # CS RSI MTF Panel
        rsi_data = analysis.get('cs_rsi', {})
        rsi_panel = Panel(
            f"[bold]Red Line (13):[/bold] {rsi_data.get('red_line', 'N/A'):.2f}\n"
            f"[bold]Upper Blue (64):[/bold] {rsi_data.get('upper_blue', 'N/A'):.2f}\n"
            f"[bold]Lower Blue (64):[/bold] {rsi_data.get('lower_blue', 'N/A'):.2f}\n"
            f"[bold]Signal:[/bold] {rsi_data.get('signal', 'N/A')}\n"
            f"[dim]{rsi_data.get('context', '')}[/dim]",
            title="CS RSI MTF",
            border_style="cyan"
        )
        
        # Dual Channel Panel
        ch_data = analysis.get('channels', {})
        channel_panel = Panel(
            f"[bold]200 SMA:[/bold] ${ch_data.get('sma', 0):.2f}\n"
            f"[bold]Inner Upper (1.0x):[/bold] ${ch_data.get('inner_upper', 0):.2f}\n"
            f"[bold]Inner Lower (1.0x):[/bold] ${ch_data.get('inner_lower', 0):.2f}\n"
            f"[bold]Outer Upper (2.415x):[/bold] ${ch_data.get('outer_upper', 0):.2f}\n"
            f"[bold]Outer Lower (2.415x):[/bold] ${ch_data.get('outer_lower', 0):.2f}\n"
            f"[bold]Zone:[/bold] {ch_data.get('zone', 'N/A')}",
            title="Dual Channels (200-day)",
            border_style="blue"
        )
        
        # Combined Signal Panel
        signal = analysis.get('combined_signal', 'neutral')
        confidence = analysis.get('confidence', 0.0)
        
        if signal == 'buy':
            signal_color = "green"
        elif signal == 'sell':
            signal_color = "red"
        else:
            signal_color = "yellow"
        
        signal_panel = Panel(
            f"[bold {signal_color}]Signal: {signal.upper()}[/bold {signal_color}]\n"
            f"[bold]Confidence:[/bold] {confidence:.0%}\n"
            f"[bold]Action:[/bold] {analysis.get('suggested_action', 'HOLD')}",
            title="Combined Signal",
            border_style=signal_color
        )
        
        console.print(rsi_panel)
        console.print(channel_panel)
        console.print(signal_panel)
    
    def display_scan_results(self, results: List[Dict]):
        """Display scan results in table format."""
        
        table = Table(title="🔍 Roo's Strategy Scan Results")
        table.add_column("Rank", justify="center", style="bold")
        table.add_column("Symbol", style="cyan")
        table.add_column("Signal", justify="center")
        table.add_column("Confidence", justify="right")
        table.add_column("CS RSI", justify="center")
        table.add_column("Channel", justify="center")
        
        for i, result in enumerate(results[:10], 1):  # Top 10
            signal = result.get('combined_signal', 'neutral')
            confidence = result.get('confidence', 0.0)
            
            # Color code signal
            if signal == 'buy':
                signal_str = f"[green]BUY[/green]"
            elif signal == 'sell':
                signal_str = f"[red]SELL[/red]"
            else:
                signal_str = f"[yellow]HOLD[/yellow]"
            
            # Confidence tier
            if confidence >= 0.90:
                conf_str = f"[bold green]{confidence:.0%}[/bold green]"
            elif confidence >= 0.75:
                conf_str = f"[green]{confidence:.0%}[/green]"
            elif confidence >= 0.60:
                conf_str = f"[yellow]{confidence:.0%}[/yellow]"
            else:
                conf_str = f"[dim]{confidence:.0%}[/dim]"
            
            table.add_row(
                str(i),
                result.get('symbol', 'N/A'),
                signal_str,
                conf_str,
                result.get('cs_rsi', {}).get('signal', 'N/A'),
                result.get('channels', {}).get('zone', 'N/A')
            )
        
        console.print(table)


def save_params_to_file(params: Dict, filepath: str = "roo_strategy_params.json"):
    """Save strategy parameters to JSON file."""
    with open(filepath, 'w') as f:
        json.dump(params, f, indent=2)
    console.print(f"[green]✓ Parameters saved to {filepath}[/green]")


def load_params_from_file(filepath: str = "roo_strategy_params.json") -> Dict:
    """Load strategy parameters from JSON file."""
    if os.path.exists(filepath):
        with open(filepath, 'r') as f:
            params = json.load(f)
        console.print(f"[green]✓ Parameters loaded from {filepath}[/green]")
        return params
    return DEFAULT_PARAMS.copy()


# Command-line interface functions
def cmd_scan(symbol: str, timeframe: str = "1W"):
    """CLI command: Scan single symbol."""
    scanner = RooSignalScanner()
    result = scanner.scan_symbol(symbol, timeframe)
    scanner.display_signal(result)


def cmd_scan_multiple(symbols: List[str], timeframe: str = "1W"):
    """CLI command: Scan multiple symbols."""
    scanner = RooSignalScanner()
    results = scanner.scan_multiple(symbols, timeframe)
    scanner.display_scan_results(results)


def cmd_tune_param(param_name: str, value: float):
    """CLI command: Tune a strategy parameter."""
    params = load_params_from_file()
    
    if param_name in params:
        old_value = params[param_name]
        params[param_name] = value
        save_params_to_file(params)
        console.print(f"[green]✓ {param_name}: {old_value} → {value}[/green]")
    else:
        console.print(f"[red]✗ Unknown parameter: {param_name}[/red]")
        console.print(f"[dim]Available: {', '.join(params.keys())}[/dim]")


def cmd_show_params():
    """CLI command: Display current parameters."""
    params = load_params_from_file()
    
    table = Table(title="📊 Roo's Strategy Parameters")
    table.add_column("Parameter", style="cyan")
    table.add_column("Value", justify="right")
    table.add_column("Description")
    
    descriptions = {
        'rsi_short_cycle': 'CS RSI red line (momentum)',
        'rsi_long_cycle': 'CS RSI blue lines (structure)',
        'channel_lookback': 'Dual channel SMA period',
        'inner_multiplier': 'Inner channel width (1.0x)',
        'outer_multiplier': 'Outer channel width (2.415x)',
        'max_risk_percent': 'Max risk per trade (5%)'
    }
    
    for key, value in params.items():
        table.add_row(key, str(value), descriptions.get(key, ''))
    
    console.print(table)


if __name__ == "__main__":
    # Example usage
    console.print("[bold]Roo's Custom TradingView-Claw Strategy[/bold]")
    console.print("CS RSI MTF (13/64) + Dual Channels (200-day, 1.0x/2.415x)\n")
    
    cmd_show_params()
