"""
custom_indicators.py — Roo's Custom Trading Indicators for TradingView-Claw
Implements CS RSI MTF and Dual Channel system
"""
import pandas as pd
import numpy as np
from typing import Dict, List, Tuple, Optional


class CSRSIMTF:
    """
    CS RSI MTF (Multi-Timeframe RSI)
    - Red line: Short cycle (default 13)
    - Blue lines: Long cycle (default 64)
    - Dynamic overbought/oversold zones
    """
    
    def __init__(self, short_cycle: int = 13, long_cycle: int = 64):
        self.short_cycle = short_cycle
        self.long_cycle = long_cycle
    
    def compute_rsi(self, prices: pd.Series, period: int) -> pd.Series:
        """Calculate RSI for given period."""
        delta = prices.diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
        rs = gain / loss
        rsi = 100 - (100 / (1 + rs))
        return rsi
    
    def calculate(self, df: pd.DataFrame) -> Dict:
        """
        Calculate CS RSI MTF values.
        
        Returns:
            Dict with:
            - red_line: Short-term RSI (cycle 13)
            - upper_blue: Long-term RSI upper band proxy
            - lower_blue: Long-term RSI lower band proxy
            - blue_mid: Long-term RSI middle
        """
        closes = df['close']
        
        # Red line - short cycle momentum
        red_line = self.compute_rsi(closes, self.short_cycle)
        
        # Blue lines - long cycle structure (using RSI-based channels)
        long_rsi = self.compute_rsi(closes, self.long_cycle)
        
        # Calculate dynamic bands based on long-term RSI extremes
        rolling_window = min(self.long_cycle * 2, len(closes) // 4)
        if rolling_window < 10:
            rolling_window = 10
            
        upper_blue = long_rsi.rolling(window=rolling_window).max()
        lower_blue = long_rsi.rolling(window=rolling_window).min()
        blue_mid = long_rsi.rolling(window=rolling_window).mean()
        
        return {
            'red_line': red_line,
            'upper_blue': upper_blue,
            'lower_blue': lower_blue,
            'blue_mid': blue_mid,
            'long_rsi': long_rsi
        }


class DualChannel:
    """
    Dual Channel System (Roo's Custom Bollinger-style Channels)
    - 200-day lookback
    - Inner multiplier: 1.0
    - Outer multiplier: 2.415
    - Tunable to historical bounces
    """
    
    def __init__(self, 
                 lookback: int = 200,
                 inner_multiplier: float = 1.0,
                 outer_multiplier: float = 2.415):
        self.lookback = lookback
        self.inner_mult = inner_multiplier
        self.outer_mult = outer_multiplier
    
    def calculate(self, df: pd.DataFrame) -> Dict:
        """
        Calculate dual channel bands.
        
        Returns:
            Dict with:
            - sma: Simple moving average (center line)
            - std: Standard deviation
            - inner_upper: SMA + (1.0 × STD)
            - inner_lower: SMA - (1.0 × STD)
            - outer_upper: SMA + (2.415 × STD)
            - outer_lower: SMA - (2.415 × STD)
        """
        closes = df['close']
        
        # 200-day SMA
        sma = closes.rolling(window=self.lookback).mean()
        
        # 200-day Standard Deviation
        std = closes.rolling(window=self.lookback).std()
        
        # Inner channel (1.0x)
        inner_upper = sma + (std * self.inner_mult)
        inner_lower = sma - (std * self.inner_mult)
        
        # Outer channel (2.415x)
        outer_upper = sma + (std * self.outer_mult)
        outer_lower = sma - (std * self.outer_mult)
        
        return {
            'sma': sma,
            'std': std,
            'inner_upper': inner_upper,
            'inner_lower': inner_lower,
            'outer_upper': outer_upper,
            'outer_lower': outer_lower
        }


class RooSignalEngine:
    """
    Combined signal engine using CS RSI MTF + Dual Channels
    Implements Roo's exact trading logic
    """
    
    def __init__(self,
                 rsi_short: int = 13,
                 rsi_long: int = 64,
                 channel_lookback: int = 200,
                 inner_mult: float = 1.0,
                 outer_mult: float = 2.415):
        self.rsi_indicator = CSRSIMTF(rsi_short, rsi_long)
        self.channel_indicator = DualChannel(channel_lookback, inner_mult, outer_mult)
    
    def analyze(self, df: pd.DataFrame) -> Dict:
        """
        Analyze current market conditions and generate signals.
        
        Returns signal dict with:
        - cs_rsi_signals: CS RSI MTF analysis
        - channel_signals: Dual channel analysis
        - combined_signal: Overall signal
        - confidence: Signal confidence score
        """
        # Calculate indicators
        rsi_data = self.rsi_indicator.calculate(df)
        channel_data = self.channel_indicator.calculate(df)
        
        # Get current values
        current_price = df['close'].iloc[-1]
        red_line = rsi_data['red_line'].iloc[-1]
        upper_blue = rsi_data['upper_blue'].iloc[-1]
        lower_blue = rsi_data['lower_blue'].iloc[-1]
        blue_mid = rsi_data['blue_mid'].iloc[-1]
        
        inner_upper = channel_data['inner_upper'].iloc[-1]
        inner_lower = channel_data['inner_lower'].iloc[-1]
        outer_upper = channel_data['outer_upper'].iloc[-1]
        outer_lower = channel_data['outer_lower'].iloc[-1]
        sma = channel_data['sma'].iloc[-1]
        
        # CS RSI MTF Signal Logic
        rsi_signal = "neutral"
        rsi_context = ""
        
        # Check if red line is near upper blue (overbought zone)
        if not pd.isna(red_line) and not pd.isna(upper_blue):
            if red_line >= upper_blue * 0.98:  # Within 2% of upper
                if upper_blue < 50:  # Blue upper is low = more room
                    rsi_signal = "caution_overbought"
                    rsi_context = "Red at upper blue, but upper is low - trend continuation possible"
                else:
                    rsi_signal = "overbought"
                    rsi_context = "Red at upper blue, upper is elevated - pullback likely"
        
        # Check if red line is near lower blue (oversold zone)
        if not pd.isna(red_line) and not pd.isna(lower_blue):
            if red_line <= lower_blue * 1.02:  # Within 2% of lower
                if lower_blue > 50:  # Blue lower is high = potential bounce
                    rsi_signal = "caution_oversold"
                    rsi_context = "Red at lower blue, lower is high - bounce OR breakdown"
                else:
                    rsi_signal = "oversold"
                    rsi_context = "Red at lower blue, lower is low - bounce likely"
        
        # Dual Channel Signal Logic
        channel_signal = "neutral"
        channel_zone = "middle"
        
        if not pd.isna(current_price):
            if current_price >= outer_upper:
                channel_signal = "extreme_overbought"
                channel_zone = "outer_upper"
            elif current_price >= inner_upper:
                channel_signal = "overbought"
                channel_zone = "inner_upper"
            elif current_price <= outer_lower:
                channel_signal = "extreme_oversold"
                channel_zone = "outer_lower"
            elif current_price <= inner_lower:
                channel_signal = "oversold"
                channel_zone = "inner_lower"
        
        # Combined Signal Logic
        combined_signal = "neutral"
        confidence = 0.0
        
        # High confidence: Both indicators align
        if rsi_signal in ["overbought", "caution_overbought"] and channel_signal in ["overbought", "extreme_overbought"]:
            combined_signal = "sell"
            confidence = 0.90 if rsi_signal == "overbought" else 0.75
        elif rsi_signal in ["oversold", "caution_oversold"] and channel_signal in ["oversold", "extreme_oversold"]:
            combined_signal = "buy"
            confidence = 0.90 if rsi_signal == "oversold" else 0.75
        # Medium confidence: Channel only
        elif channel_signal in ["extreme_overbought", "extreme_oversold"]:
            combined_signal = "sell" if "overbought" in channel_signal else "buy"
            confidence = 0.70
        # Low confidence: RSI only
        elif rsi_signal in ["overbought", "oversold"]:
            combined_signal = "sell" if rsi_signal == "overbought" else "buy"
            confidence = 0.60
        
        return {
            'current_price': current_price,
            'cs_rsi': {
                'red_line': red_line,
                'upper_blue': upper_blue,
                'lower_blue': lower_blue,
                'blue_mid': blue_mid,
                'signal': rsi_signal,
                'context': rsi_context
            },
            'channels': {
                'sma': sma,
                'inner_upper': inner_upper,
                'inner_lower': inner_lower,
                'outer_upper': outer_upper,
                'outer_lower': outer_lower,
                'signal': channel_signal,
                'zone': channel_zone
            },
            'combined_signal': combined_signal,
            'confidence': confidence,
            'suggested_action': self._get_action(combined_signal, confidence)
        }
    
    def _get_action(self, signal: str, confidence: float) -> str:
        """Convert signal to human-readable action."""
        if signal == "buy":
            if confidence >= 0.90:
                return "STRONG BUY - Both indicators aligned"
            elif confidence >= 0.75:
                return "MODERATE BUY - Caution on RSI"
            else:
                return "WEAK BUY - Channel signal only"
        elif signal == "sell":
            if confidence >= 0.90:
                return "STRONG SELL - Both indicators aligned"
            elif confidence >= 0.75:
                return "MODERATE SELL - Caution on RSI"
            else:
                return "WEAK SELL - Channel signal only"
        return "HOLD - No clear signal"


def calculate_position_size(confidence: float, account_balance: float, 
                           max_risk_percent: float = 5.0) -> float:
    """
    Calculate position size based on confidence.
    
    Args:
        confidence: Signal confidence (0.0 to 1.0)
        account_balance: Total account balance
        max_risk_percent: Maximum risk per trade (default 5%)
    
    Returns:
        Position size in base currency
    """
    # Scale position by confidence
    # 90%+ confidence = full max risk
    # 75% confidence = 75% of max risk
    # 60% confidence = 50% of max risk
    
    if confidence >= 0.90:
        risk_multiplier = 1.0
    elif confidence >= 0.75:
        risk_multiplier = 0.75
    elif confidence >= 0.60:
        risk_multiplier = 0.50
    else:
        risk_multiplier = 0.0  # No trade
    
    position_size = account_balance * (max_risk_percent / 100) * risk_multiplier
    return position_size


# Default parameters for Roo's system
DEFAULT_PARAMS = {
    'rsi_short_cycle': 13,
    'rsi_long_cycle': 64,
    'channel_lookback': 200,
    'inner_multiplier': 1.0,
    'outer_multiplier': 2.415,
    'max_risk_percent': 5.0
}
