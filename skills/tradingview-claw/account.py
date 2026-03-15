"""
account.py — Account management for TradingView-Claw
"""
from rich.console import Console
from lib.broker_client import BrokerClient

console = Console()


def status():
    """Show broker account balance and status."""
    broker = BrokerClient()
    info = broker.get_account()

    console.print(f"\n[bold]Account Status[/bold]")
    console.print(f"  Broker:        {info.get('broker', 'N/A')}")
    console.print(f"  Account ID:    [dim]{info.get('account_id', 'N/A')}[/dim]")
    console.print(f"  Cash:          ${info.get('cash', 0):.2f}")
    console.print(f"  Buying power:  ${info.get('buying_power', 0):.2f}")
    console.print(f"  Portfolio:     ${info.get('portfolio_value', 0):.2f}")
    console.print(f"  Status:        [green]{info.get('status', 'active')}[/green]")
    console.print()


def connect():
    """Interactive first-time broker connection setup."""
    console.print("\n[bold]🔗 Broker Connection Setup[/bold]\n")
    console.print("Supported brokers: Alpaca, IBKR, Binance, Bybit\n")

    broker_key = input("BROKER_API_KEY: ").strip()
    broker_secret = input("BROKER_API_SECRET: ").strip()

    if not broker_key or not broker_secret:
        console.print("[red]API credentials cannot be empty.[/red]")
        return

    console.print("\n🔧 Testing connection...")
    broker = BrokerClient(api_key=broker_key, api_secret=broker_secret)

    try:
        info = broker.get_account()
        console.print(f"[green]✅ Connected! Account: {info.get('account_id')}[/green]")
        console.print("\nAdd these to your openclaw.json env block:")
        console.print(f'  "BROKER_API_KEY": "{broker_key}"')
        console.print(f'  "BROKER_API_SECRET": "{broker_secret}"')
    except Exception as e:
        console.print(f"[red]❌ Connection failed: {e}[/red]")

    console.print()
