"""
tv_client.py — TradingView data client for TradingView-Claw
"""
import os
import httpx
from typing import Optional


class TVClient:
    """Lightweight TradingView data client using session authentication."""

    BASE_URL = "https://scanner.tradingview.com"
    SYMBOL_URL = "https://symbol-search.tradingview.com/symbol_search"

    def __init__(self, session: Optional[str] = None):
        self.session = session or os.environ.get("TRADINGVIEW_SESSION", "")
        self.headers = {
            "User-Agent": "Mozilla/5.0",
            "Cookie": f"sessionid={self.session}" if self.session else "",
        }

    def get_trending(self, limit: int = 10) -> list[dict]:
        """Fetch top symbols by 24h volume from TradingView scanner."""
        payload = {
            "filter": [{"left": "volume", "operation": "greater", "right": 1_000_000}],
            "sort": {"sortBy": "volume", "sortOrder": "desc"},
            "columns": ["name", "close", "change", "volume"],
            "range": [0, limit],
        }
        r = httpx.post(f"{self.BASE_URL}/america/scan", json=payload, headers=self.headers, timeout=15)
        r.raise_for_status()
        data = r.json().get("data", [])
        return [
            {
                "symbol": row["d"][0],
                "price": row["d"][1],
                "change_pct": row["d"][2],
                "volume": row["d"][3],
            }
            for row in data
        ]

    def search_symbols(self, query: str) -> list[dict]:
        """Search TradingView symbols by keyword."""
        r = httpx.get(
            self.SYMBOL_URL,
            params={"text": query, "type": "", "exchange": "", "lang": "en"},
            headers=self.headers,
            timeout=10,
        )
        r.raise_for_status()
        return [
            {
                "symbol": s.get("symbol", ""),
                "name": s.get("description", ""),
                "exchange": s.get("exchange", ""),
                "type": s.get("type", ""),
            }
            for s in r.json()
        ]

    def get_symbol_detail(self, symbol: str) -> dict:
        """Get OHLCV and basic technical indicators for a symbol."""
        payload = {
            "filter": [{"left": "name", "operation": "equal", "right": symbol}],
            "columns": [
                "name", "description", "close", "open", "high", "low", "volume",
                "RSI", "MACD.macd", "MACD.signal", "BB.upper", "BB.lower",
            ],
            "range": [0, 1],
        }
        r = httpx.post(f"{self.BASE_URL}/america/scan", json=payload, headers=self.headers, timeout=15)
        r.raise_for_status()
        rows = r.json().get("data", [])
        if not rows:
            raise ValueError(f"Symbol not found: {symbol}")
        d = rows[0]["d"]
        return {
            "symbol": d[0], "name": d[1], "price": d[2], "open": d[3],
            "high": d[4], "low": d[5], "volume": d[6],
            "rsi": d[7], "macd": d[8], "macd_signal": d[9],
            "bb_upper": d[10], "bb_lower": d[11],
        }

    def get_price(self, symbol: str) -> float:
        """Get current price for a symbol."""
        detail = self.get_symbol_detail(symbol)
        return detail["price"]
