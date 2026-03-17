"""
trojanlogic_4h.py

Improved 4H-only trading engine for Roo's indicator framework.
Designed around:
- csRSI behavior, not simple proximity
- RtoM channel slope and width
- Compression and expansion detection
- Liquidity sweep and wick rejection logic
- Cross failure detection
- Weighted confidence scoring
- Structural stop and target suggestions

Expected input DataFrame columns:
["open", "high", "low", "close"]

This is a 4H-only decision engine.
"""

from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Dict, List, Optional, Literal, Any

import numpy as np
import pandas as pd


Signal = Literal["long", "short", "hold"]
SetupType = Literal["reversal", "continuation", "warning", "none"]
BiasType = Literal["bullish", "bearish", "flat"]
RegimeType = Literal["compression", "expansion", "stable"]
PositionType = Literal[
    "outside_upper",
    "upper_half",
    "mid_zone",
    "lower_half",
    "outside_lower",
]
RejectionType = Literal["bullish_rejection", "bearish_rejection", "none"]
SweepType = Literal["bullish_sweep", "bearish_sweep", "none"]


@dataclass
class CSRSIState:
    state: str
    cross: Optional[str]
    cross_failure: bool
    zone: str
    red_now: float
    red_prev: float
    upper_blue_now: float
    lower_blue_now: float
    blue_mid_now: float


@dataclass
class RtoMStructure:
    bias: BiasType
    regime: RegimeType
    position: PositionType
    slope_shift: str
    width_now: float
    width_prev: float
    slope_now: float
    slope_prev: float
    mid_now: float
    inner_upper_now: float
    inner_lower_now: float
    outer_upper_now: float
    outer_lower_now: float


@dataclass
class TradePlan:
    signal: Signal
    setup_type: SetupType
    confidence: float
    confidence_label: str
    entry_zone: Optional[List[float]]
    stop_loss: Optional[float]
    tp1: Optional[float]
    tp2: Optional[float]
    invalidation: Optional[str]
    reasons: List[str]
    warnings: List[str]


class CSRSI4H:
    def __init__(self, short_cycle: int = 13, long_cycle: int = 64):
        self.short_cycle = short_cycle
        self.long_cycle = long_cycle

    @staticmethod
    def _compute_rsi(prices: pd.Series, period: int) -> pd.Series:
        delta = prices.diff()

        gain = delta.clip(lower=0)
        loss = -delta.clip(upper=0)

        avg_gain = gain.ewm(alpha=1 / period, adjust=False, min_periods=period).mean()
        avg_loss = loss.ewm(alpha=1 / period, adjust=False, min_periods=period).mean()

        rs = avg_gain / avg_loss.replace(0, np.nan)
        rsi = 100 - (100 / (1 + rs))
        return rsi.clip(lower=0, upper=100)

    def calculate(self, df: pd.DataFrame) -> Dict[str, pd.Series]:
        closes = df["close"].astype(float)

        red = self._compute_rsi(closes, self.short_cycle)
        blue_base = self._compute_rsi(closes, self.long_cycle)

        rolling_window = max(10, min(self.long_cycle * 2, max(10, len(closes) // 4)))
        upper_blue = blue_base.rolling(window=rolling_window, min_periods=rolling_window).max()
        lower_blue = blue_base.rolling(window=rolling_window, min_periods=rolling_window).min()
        blue_mid = blue_base.rolling(window=rolling_window, min_periods=rolling_window).mean()

        return {
            "red": red,
            "blue_base": blue_base,
            "upper_blue": upper_blue,
            "lower_blue": lower_blue,
            "blue_mid": blue_mid,
        }

    @staticmethod
    def _zone_label(value: float) -> str:
        if np.isnan(value):
            return "unknown"
        if value >= 80:
            return "overextended_up"
        if value >= 60:
            return "bullish_control"
        if value >= 40:
            return "neutral_transition"
        if value >= 20:
            return "bearish_control"
        return "oversold"

    def detect_state(self, data: Dict[str, pd.Series]) -> CSRSIState:
        red = data["red"]
        upper = data["upper_blue"]
        lower = data["lower_blue"]
        blue_mid = data["blue_mid"]

        if len(red) < 4:
            return CSRSIState(
                state="insufficient_data",
                cross=None,
                cross_failure=False,
                zone="unknown",
                red_now=np.nan,
                red_prev=np.nan,
                upper_blue_now=np.nan,
                lower_blue_now=np.nan,
                blue_mid_now=np.nan,
            )

        r0 = float(red.iloc[-1])
        r1 = float(red.iloc[-2])
        r2 = float(red.iloc[-3])
        r3 = float(red.iloc[-4])

        u0 = float(upper.iloc[-1])
        u1 = float(upper.iloc[-2])
        l0 = float(lower.iloc[-1])
        l1 = float(lower.iloc[-2])
        m0 = float(blue_mid.iloc[-1])

        cross = None
        cross_failure = False
        state = "neutral"

        if pd.notna(r1) and pd.notna(r0):
            if r1 < 40 <= r0:
                cross = "bullish_40_cross"
            elif r1 > 60 >= r0:
                cross = "bearish_60_cross"

        if pd.notna(r2) and pd.notna(r1) and pd.notna(r0):
            if r2 < 40 <= r1 and r0 < 40:
                cross_failure = True
            elif r2 > 60 >= r1 and r0 > 60:
                cross_failure = True

        if pd.notna(l1) and pd.notna(l0) and pd.notna(r1) and pd.notna(r0):
            if r1 < l1 and r0 >= l0:
                state = "bullish_reentry"

        if pd.notna(u1) and pd.notna(u0) and pd.notna(r1) and pd.notna(r0):
            if r1 > u1 and r0 <= u0:
                state = "bearish_reentry"

        if state == "neutral":
            if pd.notna(u0) and r0 > u0:
                state = "bullish_detachment"
            elif pd.notna(l0) and r0 < l0:
                state = "bearish_detachment"

        if state == "neutral" and all(pd.notna(x) for x in [r3, r2, r1, r0]):
            if r3 > r2 < r1 <= r0 and 20 <= r0 <= 50:
                state = "bullish_hook"
            elif r3 < r2 > r1 >= r0 and 50 <= r0 <= 80:
                state = "bearish_hook"

        if state == "neutral":
            if r0 >= 80:
                state = "overextended_up"
            elif r0 <= 20:
                state = "oversold"

        return CSRSIState(
            state=state,
            cross=cross,
            cross_failure=cross_failure,
            zone=self._zone_label(r0),
            red_now=r0,
            red_prev=r1,
            upper_blue_now=u0,
            lower_blue_now=l0,
            blue_mid_now=m0,
        )


class RtoM4H:
    def __init__(
        self,
        lookback: int = 200,
        inner_mult: float = 1.0,
        outer_mult: float = 2.415,
        slope_lookback: int = 5,
    ):
        self.lookback = lookback
        self.inner_mult = inner_mult
        self.outer_mult = outer_mult
        self.slope_lookback = slope_lookback

    def calculate(self, df: pd.DataFrame) -> Dict[str, pd.Series]:
        close = df["close"].astype(float)

        mid = close.rolling(window=self.lookback, min_periods=self.lookback).mean()
        std = close.rolling(window=self.lookback, min_periods=self.lookback).std()

        inner_upper = mid + std * self.inner_mult
        inner_lower = mid - std * self.inner_mult
        outer_upper = mid + std * self.outer_mult
        outer_lower = mid - std * self.outer_mult

        width = outer_upper - outer_lower
        slope = mid.diff(self.slope_lookback)

        return {
            "mid": mid,
            "std": std,
            "inner_upper": inner_upper,
            "inner_lower": inner_lower,
            "outer_upper": outer_upper,
            "outer_lower": outer_lower,
            "width": width,
            "slope": slope,
        }

    @staticmethod
    def _classify_bias(slope_now: float) -> BiasType:
        if np.isnan(slope_now):
            return "flat"
        if slope_now > 0:
            return "bullish"
        if slope_now < 0:
            return "bearish"
        return "flat"

    @staticmethod
    def _classify_regime(width_now: float, width_prev: float, tolerance: float = 0.005) -> RegimeType:
        if any(np.isnan(x) for x in [width_now, width_prev]):
            return "stable"
        if width_prev == 0:
            return "stable"

        pct_change = (width_now - width_prev) / abs(width_prev)

        if pct_change > tolerance:
            return "expansion"
        if pct_change < -tolerance:
            return "compression"
        return "stable"

    @staticmethod
    def _classify_position(
        price: float,
        inner_upper: float,
        inner_lower: float,
        outer_upper: float,
        outer_lower: float,
    ) -> PositionType:
        if price >= outer_upper:
            return "outside_upper"
        if price >= inner_upper:
            return "upper_half"
        if price <= outer_lower:
            return "outside_lower"
        if price <= inner_lower:
            return "lower_half"
        return "mid_zone"

    def detect_structure(self, data: Dict[str, pd.Series], df: pd.DataFrame) -> RtoMStructure:
        close = df["close"].astype(float)
        price = float(close.iloc[-1])

        mid = data["mid"]
        inner_upper = data["inner_upper"]
        inner_lower = data["inner_lower"]
        outer_upper = data["outer_upper"]
        outer_lower = data["outer_lower"]
        width = data["width"]
        slope = data["slope"]

        width_now = float(width.iloc[-1])
        width_prev = float(width.iloc[-2]) if len(width) >= 2 else np.nan
        slope_now = float(slope.iloc[-1])
        slope_prev = float(slope.iloc[-2]) if len(slope) >= 2 else np.nan

        bias = self._classify_bias(slope_now)
        regime = self._classify_regime(width_now, width_prev)
        position = self._classify_position(
            price,
            float(inner_upper.iloc[-1]),
            float(inner_lower.iloc[-1]),
            float(outer_upper.iloc[-1]),
            float(outer_lower.iloc[-1]),
        )

        slope_shift = "improving"
        if pd.notna(slope_now) and pd.notna(slope_prev):
            slope_shift = "improving" if slope_now > slope_prev else "weakening"

        return RtoMStructure(
            bias=bias,
            regime=regime,
            position=position,
            slope_shift=slope_shift,
            width_now=width_now,
            width_prev=width_prev,
            slope_now=slope_now,
            slope_prev=slope_prev,
            mid_now=float(mid.iloc[-1]),
            inner_upper_now=float(inner_upper.iloc[-1]),
            inner_lower_now=float(inner_lower.iloc[-1]),
            outer_upper_now=float(outer_upper.iloc[-1]),
            outer_lower_now=float(outer_lower.iloc[-1]),
        )


class MarketStructureTools:
    @staticmethod
    def detect_compression(width_series: pd.Series, short_window: int = 5, long_window: int = 10) -> bool:
        clean = width_series.dropna()
        if len(clean) < long_window:
            return False

        recent = clean.iloc[-short_window:]
        earlier = clean.iloc[-long_window:-short_window]

        if len(earlier) < short_window:
            return False

        return float(recent.mean()) < float(earlier.mean())

    @staticmethod
    def detect_liquidity_sweep(df: pd.DataFrame, lookback: int = 20) -> SweepType:
        if len(df) < lookback + 2:
            return "none"

        last = df.iloc[-1]
        prev_lows = df["low"].rolling(lookback).min().iloc[-2]
        prev_highs = df["high"].rolling(lookback).max().iloc[-2]

        if pd.notna(prev_lows) and last["low"] < prev_lows and last["close"] > prev_lows:
            return "bullish_sweep"

        if pd.notna(prev_highs) and last["high"] > prev_highs and last["close"] < prev_highs:
            return "bearish_sweep"

        return "none"

    @staticmethod
    def detect_wick_rejection(df: pd.DataFrame) -> RejectionType:
        if len(df) < 1:
            return "none"

        candle = df.iloc[-1]

        body = abs(float(candle["close"]) - float(candle["open"]))
        if body == 0:
            body = 1e-9

        upper_wick = float(candle["high"]) - max(float(candle["open"]), float(candle["close"]))
        lower_wick = min(float(candle["open"]), float(candle["close"])) - float(candle["low"])

        if lower_wick > body * 2:
            return "bullish_rejection"
        if upper_wick > body * 2:
            return "bearish_rejection"

        return "none"

    @staticmethod
    def recent_structural_stop(df: pd.DataFrame, direction: Signal, candles: int = 5, buffer_pct: float = 0.002) -> Optional[float]:
        if len(df) < candles:
            return None

        if direction == "long":
            base = float(df["low"].tail(candles).min())
            return round(base * (1 - buffer_pct), 6)

        if direction == "short":
            base = float(df["high"].tail(candles).max())
            return round(base * (1 + buffer_pct), 6)

        return None

    @staticmethod
    def build_entry_zone(price: float, direction: Signal, offset_pct: float = 0.003) -> Optional[List[float]]:
        if direction == "hold":
            return None

        low = price * (1 - offset_pct)
        high = price * (1 + offset_pct)

        if direction == "long":
            return [round(low, 6), round(price, 6)]
        return [round(price, 6), round(high, 6)]


class ConfidenceModel:
    @staticmethod
    def score(
        direction: Signal,
        csrsi: CSRSIState,
        rtom: RtoMStructure,
        compression: bool,
        sweep: SweepType,
        rejection: RejectionType,
    ) -> float:
        if direction == "hold":
            return 0.0

        score = 0.0

        if direction == "long":
            if csrsi.state == "bullish_reentry":
                score += 0.24
            if csrsi.state == "bullish_detachment":
                score += 0.18
            if csrsi.cross == "bullish_40_cross":
                score += 0.16
            if rtom.bias == "bullish":
                score += 0.12
            if rtom.regime == "compression":
                score += 0.10
            if rtom.regime == "expansion" and csrsi.state == "bullish_detachment":
                score += 0.08
            if sweep == "bullish_sweep":
                score += 0.14
            if rejection == "bullish_rejection":
                score += 0.10
            if rtom.position in {"outside_lower", "lower_half", "mid_zone"}:
                score += 0.08

        elif direction == "short":
            if csrsi.state == "bearish_reentry":
                score += 0.24
            if csrsi.state == "bearish_detachment":
                score += 0.18
            if csrsi.cross == "bearish_60_cross":
                score += 0.16
            if rtom.bias == "bearish":
                score += 0.12
            if rtom.regime == "compression":
                score += 0.10
            if rtom.regime == "expansion" and csrsi.state == "bearish_detachment":
                score += 0.08
            if sweep == "bearish_sweep":
                score += 0.14
            if rejection == "bearish_rejection":
                score += 0.10
            if rtom.position in {"outside_upper", "upper_half", "mid_zone"}:
                score += 0.08

        if compression:
            score += 0.06

        if csrsi.cross_failure:
            score -= 0.30

        return max(0.0, min(round(score, 4), 0.99))

    @staticmethod
    def label(confidence: float) -> str:
        if confidence >= 0.85:
            return "strong"
        if confidence >= 0.65:
            return "moderate"
        if confidence >= 0.45:
            return "weak"
        return "watch"


class TrojanLogic4H:
    def __init__(
        self,
        rsi_short: int = 13,
        rsi_long: int = 64,
        channel_lookback: int = 200,
        inner_mult: float = 1.0,
        outer_mult: float = 2.415,
        stop_buffer_pct: float = 0.002,
    ):
        self.csrsi = CSRSI4H(short_cycle=rsi_short, long_cycle=rsi_long)
        self.rtom = RtoM4H(
            lookback=channel_lookback,
            inner_mult=inner_mult,
            outer_mult=outer_mult,
        )
        self.tools = MarketStructureTools()
        self.confidence_model = ConfidenceModel()
        self.stop_buffer_pct = stop_buffer_pct

    @staticmethod
    def _validate_df(df: pd.DataFrame) -> None:
        required = {"open", "high", "low", "close"}
        missing = required - set(df.columns)
        if missing:
            raise ValueError(f"Missing required columns: {sorted(missing)}")
        if len(df) < 220:
            raise ValueError("Need at least 220 rows for stable 4H channel calculations.")

    def _classify_setup(
        self,
        csrsi: CSRSIState,
        rtom: RtoMStructure,
        compression: bool,
        sweep: SweepType,
        rejection: RejectionType,
    ) -> Dict[str, Any]:
        signal: Signal = "hold"
        setup_type: SetupType = "none"
        reasons: List[str] = []
        warnings: List[str] = []

        if csrsi.cross_failure:
            warnings.append("cross failure detected within two candles")
            return {
                "signal": "hold",
                "setup_type": "warning",
                "reasons": reasons,
                "warnings": warnings,
            }

        bullish_reversal = (
            csrsi.state == "bullish_reentry"
            and csrsi.cross == "bullish_40_cross"
            and rtom.position in {"outside_lower", "lower_half", "mid_zone"}
            and (compression or rtom.regime in {"compression", "stable"})
        )

        bearish_reversal = (
            csrsi.state == "bearish_reentry"
            and csrsi.cross == "bearish_60_cross"
            and rtom.position in {"outside_upper", "upper_half", "mid_zone"}
            and (compression or rtom.regime in {"compression", "stable"})
        )

        bullish_continuation = (
            csrsi.state == "bullish_detachment"
            and rtom.bias == "bullish"
            and rtom.regime == "expansion"
        )

        bearish_continuation = (
            csrsi.state == "bearish_detachment"
            and rtom.bias == "bearish"
            and rtom.regime == "expansion"
        )

        if bullish_reversal:
            signal = "long"
            setup_type = "reversal"
            reasons.extend(
                [
                    "bullish re-entry back inside csRSI corridor",
                    "bullish 40 cross confirmed",
                    "price positioned in lower to mid channel zone",
                ]
            )

        elif bearish_reversal:
            signal = "short"
            setup_type = "reversal"
            reasons.extend(
                [
                    "bearish re-entry back inside csRSI corridor",
                    "bearish 60 cross confirmed",
                    "price positioned in upper to mid channel zone",
                ]
            )

        elif bullish_continuation:
            signal = "long"
            setup_type = "continuation"
            reasons.extend(
                [
                    "bullish csRSI detachment",
                    "upward channel slope with expansion",
                ]
            )

        elif bearish_continuation:
            signal = "short"
            setup_type = "continuation"
            reasons.extend(
                [
                    "bearish csRSI detachment",
                    "downward channel slope with expansion",
                ]
            )

        elif csrsi.state in {"bullish_hook", "bearish_hook"}:
            signal = "hold"
            setup_type = "warning"
            warnings.append("hook detected, early warning only")

        if sweep != "none":
            reasons.append(f"{sweep.replace('_', ' ')} detected")

        if rejection != "none":
            reasons.append(f"{rejection.replace('_', ' ')} detected")

        if compression:
            reasons.append("channel compression detected")

        if signal == "hold" and not reasons:
            reasons.append("no valid 4H setup")

        return {
            "signal": signal,
            "setup_type": setup_type,
            "reasons": reasons,
            "warnings": warnings,
        }

    def _build_trade_plan(
        self,
        df: pd.DataFrame,
        signal: Signal,
        setup_type: SetupType,
        confidence: float,
        reasons: List[str],
        warnings: List[str],
        rtom: RtoMStructure,
    ) -> TradePlan:
        price = float(df["close"].iloc[-1])

        if signal == "hold":
            return TradePlan(
                signal="hold",
                setup_type=setup_type,
                confidence=confidence,
                confidence_label=self.confidence_model.label(confidence),
                entry_zone=None,
                stop_loss=None,
                tp1=None,
                tp2=None,
                invalidation=None,
                reasons=reasons,
                warnings=warnings,
            )

        entry_zone = self.tools.build_entry_zone(price, signal, offset_pct=0.003)
        stop_loss = self.tools.recent_structural_stop(
            df,
            signal,
            candles=5,
            buffer_pct=self.stop_buffer_pct,
        )

        if signal == "long":
            tp1 = rtom.inner_upper_now if price < rtom.inner_upper_now else rtom.mid_now
            tp2 = rtom.outer_upper_now
            invalidation = f"4H close below {stop_loss}"
        else:
            tp1 = rtom.inner_lower_now if price > rtom.inner_lower_now else rtom.mid_now
            tp2 = rtom.outer_lower_now
            invalidation = f"4H close above {stop_loss}"

        return TradePlan(
            signal=signal,
            setup_type=setup_type,
            confidence=confidence,
            confidence_label=self.confidence_model.label(confidence),
            entry_zone=entry_zone,
            stop_loss=round(float(stop_loss), 6) if stop_loss is not None else None,
            tp1=round(float(tp1), 6) if tp1 is not None and pd.notna(tp1) else None,
            tp2=round(float(tp2), 6) if tp2 is not None and pd.notna(tp2) else None,
            invalidation=invalidation,
            reasons=reasons,
            warnings=warnings,
        )

    def analyze(self, df: pd.DataFrame) -> Dict[str, Any]:
        self._validate_df(df)

        csrsi_data = self.csrsi.calculate(df)
        csrsi_state = self.csrsi.detect_state(csrsi_data)

        rtom_data = self.rtom.calculate(df)
        rtom_structure = self.rtom.detect_structure(rtom_data, df)

        compression = self.tools.detect_compression(rtom_data["width"])
        sweep = self.tools.detect_liquidity_sweep(df, lookback=20)
        rejection = self.tools.detect_wick_rejection(df)

        setup = self._classify_setup(
            csrsi=csrsi_state,
            rtom=rtom_structure,
            compression=compression,
            sweep=sweep,
            rejection=rejection,
        )

        confidence = self.confidence_model.score(
            direction=setup["signal"],
            csrsi=csrsi_state,
            rtom=rtom_structure,
            compression=compression,
            sweep=sweep,
            rejection=rejection,
        )

        trade_plan = self._build_trade_plan(
            df=df,
            signal=setup["signal"],
            setup_type=setup["setup_type"],
            confidence=confidence,
            reasons=setup["reasons"],
            warnings=setup["warnings"],
            rtom=rtom_structure,
        )

        return {
            "price": float(df["close"].iloc[-1]),
            "csrsi_state": asdict(csrsi_state),
            "rtom_structure": asdict(rtom_structure),
            "compression": compression,
            "liquidity_sweep": sweep,
            "wick_rejection": rejection,
            "trade_plan": asdict(trade_plan),
        }


def calculate_position_risk(account_balance: float, risk_percent: float = 1.0) -> float:
    """
    Risk amount in account currency.
    """
    if account_balance < 0:
        raise ValueError("account_balance must be non-negative")
    if not 0 <= risk_percent <= 100:
        raise ValueError("risk_percent must be between 0 and 100")
    return round(account_balance * (risk_percent / 100.0), 6)


def calculate_position_size_from_stop(
    account_balance: float,
    risk_percent: float,
    entry_price: float,
    stop_price: float,
) -> float:
    """
    Position size in units of the asset, based on stop distance.
    """
    if entry_price <= 0 or stop_price <= 0:
        raise ValueError("entry_price and stop_price must be positive")

    risk_amount = calculate_position_risk(account_balance, risk_percent)
    stop_distance = abs(entry_price - stop_price)

    if stop_distance == 0:
        raise ValueError("entry_price and stop_price cannot be equal")

    return round(risk_amount / stop_distance, 6)


DEFAULT_PARAMS = {
    "rsi_short_cycle": 13,
    "rsi_long_cycle": 64,
    "channel_lookback": 200,
    "inner_multiplier": 1.0,
    "outer_multiplier": 2.415,
    "stop_buffer_pct": 0.002,
    "base_risk_percent": 1.0,
}


if __name__ == "__main__":
    # Example usage:
    # df = pd.read_csv("your_4h_ohlc.csv")
    # engine = TrojanLogic4H()
    # result = engine.analyze(df)
    # print(result)
    pass
