"""
broker_client.py — Broker/exchange API wrapper for TradingView-Claw
Supports: Alpaca (default), extensible to IBKR, Binance, Bybit
"""
import os
import uuid
import httpx
from typing import Optional


class BrokerClient:
    """Broker client wrapper. Defaults to Alpaca Paper Trading."""

    ALPACA_BASE = "https://paper-api.alpaca.markets/v2"

    def __init__(self, api_key: Optional[str] = None, api_secret: Optional[str] = None):
        self.api_key = api_key or os.environ.get("BROKER_API_KEY", "")
        self.api_secret = api_secret or os.environ.get("BROKER_API_SECRET", "")
        self.headers = {
            "APCA-API-KEY-ID": self.api_key,
            "APCA-API-SECRET-KEY": self.api_secret,
        }

    def get_account(self) -> dict:
        """Fetch account balance and status."""
        r = httpx.get(f"{self.ALPACA_BASE}/account", headers=self.headers, timeout=10)
        r.raise_for_status()
        data = r.json()
        return {
            "broker": "Alpaca",
            "account_id": data.get("id", ""),
            "cash": float(data.get("cash", 0)),
            "buying_power": float(data.get("buying_power", 0)),
            "portfolio_value": float(data.get("portfolio_value", 0)),
            "status": data.get("status", "active"),
        }

    def place_order(self, symbol: str, side: str, qty: float) -> dict:
        """Place a market order."""
        payload = {
            "symbol": symbol,
            "qty": str(qty),
            "side": side,
            "type": "market",
            "time_in_force": "gtc",
        }
        r = httpx.post(
            f"{self.ALPACA_BASE}/orders",
            json=payload,
            headers=self.headers,
            timeout=10,
        )
        r.raise_for_status()
        data = r.json()
        return {
            "id": data.get("id", str(uuid.uuid4())),
            "status": data.get("status", "accepted"),
            "symbol": symbol,
            "side": side,
            "qty": qty,
        }
