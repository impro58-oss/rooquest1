"""
signals.py — LLM-powered signal discovery for TradingView-Claw
"""
from rich.console import Console
from rich.table import Table
from lib.tv_client import TVClient
from lib.llm_client import LLMClient
from lib.signal_engine import SignalEngine

console = Console()

TIER_COLORS = {
    "S1": "bold green",
    "S2": "green",
    "S3": "yellow",
    "S4": "dim red",
}


def scan(query: str = None, limit: int = 10, model: str = "nvidia/nemotron-nano-9b-v2:free"):
    """Scan for LLM-analyzed trade signals."""
    tv = TVClient()
    llm = LLMClient(model=model)
    engine = SignalEngine(tv_client=tv, llm_client=llm)

    console.print(f"\n🔍 Scanning {'for: ' + query if query else 'trending symbols'} ...")
    console.print(f"   Model: [dim]{model}[/dim]")
    console.print(f"   Limit: {limit}\n")

    with console.status("Fetching symbols and running indicator analysis..."):
        signals = engine.scan(query=query, limit=limit)

    if not signals:
        console.print("[yellow]No signals found above threshold.[/yellow]")
        return

    table = Table(title="📡 Signal Scan Results")
    table.add_column("Tier", justify="center")
    table.add_column("Symbol", style="bold cyan")
    table.add_column("Signal")
    table.add_column("Score", justify="right")
    table.add_column("Entry", justify="right")
    table.add_column("Target", justify="right")
    table.add_column("Stop", justify="right")

    for sig in signals:
        tier_style = TIER_COLORS.get(sig["tier"], "white")
        table.add_row(
            f"[{tier_style}]{sig['tier']}[/{tier_style}]",
            sig["symbol"],
            sig["signal_type"],
            f"{sig['score']:.1f}%",
            f"${sig['entry']:.2f}",
            f"${sig['target']:.2f}",
            f"${sig['stop']:.2f}",
        )

    console.print(table)
    console.print(
        "\nTiers: [bold green]S1[/bold green] ≥95%  "
        "[green]S2[/green] 90–95%  "
        "[yellow]S3[/yellow] 85–90%\n"
    )


def analyze(symbol1: str, symbol2: str):
    """Compare signal strength between two symbols."""
    tv = TVClient()
    llm = LLMClient()
    engine = SignalEngine(tv_client=tv, llm_client=llm)

    console.print(f"\n🔬 Analyzing: [bold cyan]{symbol1}[/bold cyan] vs [bold cyan]{symbol2}[/bold cyan]\n")

    with console.status("Running analysis..."):
        result = engine.compare(symbol1=symbol1.upper(), symbol2=symbol2.upper())

    console.print(result["summary"])
