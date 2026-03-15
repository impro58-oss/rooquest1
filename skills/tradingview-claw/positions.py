"""
positions.py — Position tracking and P&L for TradingView-Claw
"""
from rich.console import Console
from rich.table import Table
from lib.position_storage import PositionStorage
from lib.tv_client import TVClient

console = Console()


def list_positions():
    """Display all open positions with live P&L."""
    storage = PositionStorage()
    tv = TVClient()
    positions = storage.get_all_positions()

    if not positions:
        console.print("[dim]No open positions.[/dim]")
        return

    table = Table(title="📊 Open Positions")
    table.add_column("ID", style="dim")
    table.add_column("Symbol", style="bold cyan")
    table.add_column("Side")
    table.add_column("Qty", justify="right")
    table.add_column("Entry", justify="right")
    table.add_column("Current", justify="right")
    table.add_column("P&L", justify="right")

    for pos in positions:
        current = tv.get_price(pos["symbol"])
        pnl = (current - pos["entry_price"]) * pos["qty"]
        pnl_str = f"[green]+${pnl:.2f}[/green]" if pnl >= 0 else f"[red]-${abs(pnl):.2f}[/red]"
        table.add_row(
            pos["id"][:8],
            pos["symbol"],
            pos["side"],
            str(pos["qty"]),
            f"${pos['entry_price']:.2f}",
            f"${current:.2f}",
            pnl_str,
        )

    console.print(table)


def show_position(position_id: str):
    """Detailed view of a single position."""
    storage = PositionStorage()
    tv = TVClient()
    pos = storage.get_position(position_id)

    if not pos:
        console.print(f"[red]Position '{position_id}' not found.[/red]")
        return

    current = tv.get_price(pos["symbol"])
    pnl = (current - pos["entry_price"]) * pos["qty"]

    console.print(f"\n[bold]Position: {pos['id']}[/bold]")
    console.print(f"  Symbol:      {pos['symbol']}")
    console.print(f"  Side:        {pos['side']}")
    console.print(f"  Quantity:    {pos['qty']}")
    console.print(f"  Entry price: ${pos['entry_price']:.2f}")
    console.print(f"  Current:     ${current:.2f}")
    pnl_color = "green" if pnl >= 0 else "red"
    console.print(f"  P&L:         [{pnl_color}]{'+' if pnl >= 0 else ''}{pnl:.2f}[/{pnl_color}]")
    console.print()
