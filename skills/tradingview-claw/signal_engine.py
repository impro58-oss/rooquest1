"""
signal_engine.py — Signal scoring and tier classification for TradingView-Claw
"""
import json
from lib.tv_client import TVClient
from lib.llm_client import LLMClient

SYSTEM_PROMPT = """
You are a professional technical analyst. Given OHLCV data and indicator values for a symbol,
analyze the setup and return ONLY valid JSON with these fields:
{
  "signal_type": "LONG" | "SHORT" | "NEUTRAL",
  "score": <float 0-100, confidence percentage>,
  "entry": <float, suggested entry price>,
  "target": <float, price target>,
  "stop": <float, stop loss>,
  "reason": "<1 sentence explanation>"
}
Only return valid JSON. No explanation text, no markdown, no backticks.
Only recommend LONG or SHORT if score >= 85. Otherwise return NEUTRAL.
"""

TIER_THRESHOLDS = {
    "S1": 95.0,
    "S2": 90.0,
    "S3": 85.0,
}


def score_to_tier(score: float) -> str:
    if score >= TIER_THRESHOLDS["S1"]:
        return "S1"
    if score >= TIER_THRESHOLDS["S2"]:
        return "S2"
    if score >= TIER_THRESHOLDS["S3"]:
        return "S3"
    return "S4"


class SignalEngine:
    def __init__(self, tv_client: TVClient, llm_client: LLMClient):
        self.tv = tv_client
        self.llm = llm_client

    def scan(self, query: str = None, limit: int = 10) -> list[dict]:
        """Fetch symbols and return LLM-scored signals above S3 threshold."""
        if query:
            symbols_raw = self.tv.search_symbols(query)[:limit]
            symbols = [s["symbol"] for s in symbols_raw]
        else:
            trending = self.tv.get_trending(limit=limit)
            symbols = [s["symbol"] for s in trending]

        results = []
        for sym in symbols:
            try:
                detail = self.tv.get_symbol_detail(sym)
                sig = self._analyze_symbol(detail)
                if sig and sig["signal_type"] != "NEUTRAL" and sig["score"] >= 85.0:
                    sig["symbol"] = sym
                    sig["tier"] = score_to_tier(sig["score"])
                    results.append(sig)
            except Exception:
                continue

        results.sort(key=lambda x: x["score"], reverse=True)
        return results

    def compare(self, symbol1: str, symbol2: str) -> dict:
        """Compare signal strength between two symbols."""
        d1 = self.tv.get_symbol_detail(symbol1)
        d2 = self.tv.get_symbol_detail(symbol2)
        s1 = self._analyze_symbol(d1)
        s2 = self._analyze_symbol(d2)

        lines = [
            f"\n[bold]{symbol1}[/bold]",
            f"  Signal: {s1.get('signal_type')}  Score: {s1.get('score'):.1f}%",
            f"  {s1.get('reason', '')}",
            f"\n[bold]{symbol2}[/bold]",
            f"  Signal: {s2.get('signal_type')}  Score: {s2.get('score'):.1f}%",
            f"  {s2.get('reason', '')}",
        ]
        winner = symbol1 if (s1.get("score", 0) >= s2.get("score", 0)) else symbol2
        lines.append(f"\n🏆 Stronger setup: [bold cyan]{winner}[/bold cyan]")

        return {"summary": "\n".join(lines)}

    def _analyze_symbol(self, detail: dict) -> dict | None:
        """Ask the LLM to analyze a single symbol's technicals."""
        user_msg = (
            f"Symbol: {detail['symbol']}\n"
            f"Price: {detail['price']}\n"
            f"Open: {detail['open']}, High: {detail['high']}, Low: {detail['low']}\n"
            f"Volume: {detail['volume']}\n"
            f"RSI(14): {detail['rsi']}\n"
            f"MACD: {detail['macd']}, Signal: {detail['macd_signal']}\n"
            f"Bollinger Upper: {detail['bb_upper']}, Lower: {detail['bb_lower']}\n"
        )
        try:
            raw = self.llm.complete(system=SYSTEM_PROMPT, user=user_msg, max_tokens=256)
            clean = raw.strip().replace("```json", "").replace("```", "").strip()
            return json.loads(clean)
        except Exception:
            return None
