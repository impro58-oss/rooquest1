"""
indicators.py — Technical indicator helpers for TradingView-Claw
Thin wrappers around pandas-ta for local computation when needed.
"""
import pandas as pd
try:
    import pandas_ta as ta
except ImportError:
    ta = None


def compute_rsi(closes: list[float], period: int = 14) -> float:
    if ta is None:
        raise ImportError("pandas-ta is required: uv sync")
    s = pd.Series(closes)
    result = ta.rsi(s, length=period)
    return float(result.iloc[-1]) if result is not None else float("nan")


def compute_macd(closes: list[float]) -> dict:
    if ta is None:
        raise ImportError("pandas-ta is required: uv sync")
    s = pd.Series(closes)
    result = ta.macd(s)
    if result is None or result.empty:
        return {"macd": float("nan"), "signal": float("nan"), "hist": float("nan")}
    return {
        "macd": float(result["MACD_12_26_9"].iloc[-1]),
        "signal": float(result["MACDs_12_26_9"].iloc[-1]),
        "hist": float(result["MACDh_12_26_9"].iloc[-1]),
    }


def compute_bollinger(closes: list[float], period: int = 20) -> dict:
    if ta is None:
        raise ImportError("pandas-ta is required: uv sync")
    s = pd.Series(closes)
    result = ta.bbands(s, length=period)
    if result is None or result.empty:
        return {"upper": float("nan"), "mid": float("nan"), "lower": float("nan")}
    return {
        "upper": float(result[f"BBU_{period}_2.0"].iloc[-1]),
        "mid": float(result[f"BBM_{period}_2.0"].iloc[-1]),
        "lower": float(result[f"BBL_{period}_2.0"].iloc[-1]),
    }
