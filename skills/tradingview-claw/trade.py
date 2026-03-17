"""
trade.py — Order execution for TradingView-Claw
"""
from rich.console import Console
from lib.broker_client import BrokerClient
from lib.tv_client import TVClient
from lib.position_storage import PositionStorage

console = Console()


def execute_buy(symbol: str, amount: float):
    """Execute a buy order for the given symbol and dollar amount."""
    symbol = symbol.upper()
    broker = BrokerClient()
    tv = TVClient()
    storage = PositionStorage()

    price = tv.get_price(symbol)
    qty = round(amount / price, 6)

    console.print(f"\n🟢 Buying [bold]{symbol}[/bold]")
    console.print(f"   Amount:   ${amount:.2f}")
    console.print(f"   Price:    ${price:.2f}")
    console.print(f"   Quantity: {qty}")

    order = broker.place_order(symbol=symbol, side="buy", qty=qty)
    console.print(f"   Order ID: [dim]{order['id']}[/dim]")
    console.print(f"   Status:   [green]{order['status']}[/green]")

    storage.add_position({
        "id": order["id"],
        "symbol": symbol,
        "side": "long",
        "qty": qty,
        "entry_price": price,
        "amount_usd": amount,
    })
    console.print("\n✅ Position recorded.\n")


def execute_sell(symbol: str, amount: float = None):
    """Close or reduce a position."""
    symbol = symbol.upper()
    broker = BrokerClient()
    tv = TVClient()
    storage = PositionStorage()

    price = tv.get_price(symbol)
    positions = storage.get_positions_for_symbol(symbol)

    if not positions:
        console.print(f"[red]No open positions found for {symbol}.[/red]")
        return

    pos = positions[0]
    qty = pos["qty"] if amount is None else round(amount / price, 6)

    console.print(f"\n🔴 Selling [bold]{symbol}[/bold]")
    console.print(f"   Quantity: {qty}")
    console.print(f"   Price:    ${price:.2f}")

    order = broker.place_order(symbol=symbol, side="sell", qty=qty)
    console.print(f"   Order ID: [dim]{order['id']}[/dim]")
    console.print(f"   Status:   [green]{order['status']}[/green]")

    pnl = (price - pos["entry_price"]) * qty
    pnl_str = f"[green]+${pnl:.2f}[/green]" if pnl >= 0 else f"[red]-${abs(pnl):.2f}[/red]"
    console.print(f"   P&L:      {pnl_str}")

    storage.close_position(pos["id"])
    console.print("\n✅ Position closed.\n")
