"""
charts.py — Market data and chart commands for TradingView-Claw
"""
from rich.console import Console
from rich.table import Table
from lib.tv_client import TVClient

console = Console()


def trending(limit: int = 10):
    """Fetch and display trending symbols by 24h volume."""
    client = TVClient()
    symbols = client.get_trending(limit=limit)

    table = Table(title=f"📈 Trending Symbols (top {limit})")
    table.add_column("Symbol", style="bold cyan")
    table.add_column("Price", justify="right")
    table.add_column("Change %", justify="right")
    table.add_column("Volume", justify="right")

    for s in symbols:
        change_style = "green" if s["change_pct"] >= 0 else "red"
        table.add_row(
            s["symbol"],
            f"${s['price']:.2f}",
            f"[{change_style}]{s['change_pct']:+.2f}%[/{change_style}]",
            f"{s['volume']:,.0f}",
        )

    console.print(table)


def search(query: str):
    """Search symbols by keyword."""
    client = TVClient()
    results = client.search_symbols(query=query)

    table = Table(title=f"🔍 Search: '{query}'")
    table.add_column("Symbol", style="bold cyan")
    table.add_column("Name")
    table.add_column("Exchange")
    table.add_column("Type")

    for r in results:
        table.add_row(r["symbol"], r["name"], r["exchange"], r["type"])

    console.print(table)


def detail(symbol: str):
    """Show OHLCV + technical indicators for a symbol."""
    client = TVClient()
    data = client.get_symbol_detail(symbol=symbol.upper())

    console.print(f"\n[bold cyan]{symbol.upper()}[/bold cyan] — {data.get('name', '')}")
    console.print(f"  Price:   [bold]${data['price']:.2f}[/bold]")
    console.print(f"  Open:    ${data['open']:.2f}")
    console.print(f"  High:    ${data['high']:.2f}")
    console.print(f"  Low:     ${data['low']:.2f}")
    console.print(f"  Volume:  {data['volume']:,.0f}")
    console.print()
    console.print(f"  RSI(14): {data['rsi']:.1f}")
    console.print(f"  MACD:    {data['macd']:.4f}  Signal: {data['macd_signal']:.4f}")
    console.print(f"  BB Upper: ${data['bb_upper']:.2f}  Lower: ${data['bb_lower']:.2f}")
    console.print()
