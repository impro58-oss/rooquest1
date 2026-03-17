#!/usr/bin/env python3
"""
TradingView-Claw — CLI dispatcher
"""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import typer
from rich.console import Console

app = typer.Typer(help="TradingView-Claw: trading skill for OpenClaw")
console = Console()

# ── Sub-apps ──────────────────────────────────────────────────────────────────

charts_app = typer.Typer(help="Chart and market data commands")
account_app = typer.Typer(help="Account management commands")
signal_app = typer.Typer(help="LLM signal discovery commands")

app.add_typer(charts_app, name="charts")
app.add_typer(account_app, name="account")
app.add_typer(signal_app, name="signal")

# ── Charts ────────────────────────────────────────────────────────────────────

@charts_app.command("trending")
def charts_trending(limit: int = typer.Option(10, "--limit", "-l")):
    """Top symbols by volume."""
    from scripts.charts import trending
    trending(limit=limit)

@charts_app.command("search")
def charts_search(query: str):
    """Search symbols by keyword."""
    from scripts.charts import search
    search(query=query)

@app.command("chart")
def chart(symbol: str):
    """Symbol detail with OHLCV + indicators."""
    from scripts.charts import detail
    detail(symbol=symbol)

# ── Trading ───────────────────────────────────────────────────────────────────

@app.command("buy")
def buy(symbol: str, amount: float):
    """Open a long position."""
    from scripts.trade import execute_buy
    execute_buy(symbol=symbol, amount=amount)

@app.command("sell")
def sell(symbol: str, amount: float = typer.Argument(None)):
    """Close / open short position."""
    from scripts.trade import execute_sell
    execute_sell(symbol=symbol, amount=amount)

# ── Positions ─────────────────────────────────────────────────────────────────

@app.command("positions")
def positions():
    """List all open positions with live P&L."""
    from scripts.positions import list_positions
    list_positions()

@app.command("position")
def position(position_id: str):
    """Detailed view of a single position."""
    from scripts.positions import show_position
    show_position(position_id=position_id)

# ── Account ───────────────────────────────────────────────────────────────────

@account_app.command("status")
def account_status():
    """Show account balance and info."""
    from scripts.account import status
    status()

@account_app.command("connect")
def account_connect():
    """First-time broker/exchange connection setup."""
    from scripts.account import connect
    connect()

# ── Signals ───────────────────────────────────────────────────────────────────

@signal_app.command("scan")
def signal_scan(
    query: str = typer.Option(None, "--query", "-q"),
    limit: int = typer.Option(10, "--limit", "-l"),
    model: str = typer.Option("nvidia/nemotron-nano-9b-v2:free", "--model"),
):
    """Scan for LLM-analyzed trade signals."""
    from scripts.signals import scan
    scan(query=query, limit=limit, model=model)

@signal_app.command("analyze")
def signal_analyze(symbol1: str, symbol2: str):
    """Compare signal strength between two symbols."""
    from scripts.signals import analyze
    analyze(symbol1=symbol1, symbol2=symbol2)


if __name__ == "__main__":
    app()
