"""
demo_data_feed.py — Simulated Market Data Feed for Testing
Generates realistic OHLCV data for demo purposes
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List
import random


class DemoDataFeed:
    """
    Generates simulated weekly market data for testing Roo's strategy.
    Creates realistic price action with trends, reversals, and channel behavior.
    """
    
    def __init__(self, seed: int = 42):
        random.seed(seed)
        np.random.seed(seed)
    
    def generate_weekly_data(self, 
                            symbol: str = "BTCUSD",
                            weeks: int = 300,
                            start_price: float = 50000) -> pd.DataFrame:
        """
        Generate simulated weekly OHLCV data.
        
        Args:
            symbol: Trading pair name
            weeks: Number of weeks of data
            start_price: Starting price
        
        Returns:
            DataFrame with columns: timestamp, open, high, low, close, volume
        """
        data = []
        current_price = start_price
        
        # Generate dates (weekly)
        end_date = datetime.now()
        dates = [end_date - timedelta(weeks=i) for i in range(weeks)]
        dates.reverse()
        
        # Market regime parameters
        trend = 0  # -1 = down, 0 = sideways, 1 = up
        trend_duration = 0
        trend_strength = 0.02  # 2% weekly drift
        
        for i, date in enumerate(dates):
            # Change trend occasionally
            if trend_duration <= 0:
                trend = random.choice([-1, 0, 1])
                trend_duration = random.randint(10, 50)  # Weeks in trend
            
            trend_duration -= 1
            
            # Calculate weekly movement
            drift = trend * trend_strength + np.random.normal(0, 0.03)
            weekly_return = drift + np.random.normal(0, 0.05)
            
            # Open is previous close (with small gap)
            open_price = current_price * (1 + np.random.normal(0, 0.005))
            
            # Close with trend
            close_price = open_price * (1 + weekly_return)
            
            # High and low with intraweek volatility
            volatility = abs(weekly_return) + 0.03
            high_price = max(open_price, close_price) * (1 + np.random.uniform(0, volatility))
            low_price = min(open_price, close_price) * (1 - np.random.uniform(0, volatility))
            
            # Volume (higher on big moves)
            base_volume = random.uniform(10000, 50000)
            volume = base_volume * (1 + abs(weekly_return) * 10)
            
            data.append({
                'timestamp': date,
                'open': round(open_price, 2),
                'high': round(high_price, 2),
                'low': round(low_price, 2),
                'close': round(close_price, 2),
                'volume': round(volume, 2)
            })
            
            current_price = close_price
        
        df = pd.DataFrame(data)
        df.set_index('timestamp', inplace=True)
        return df
    
    def generate_scenario_data(self, scenario: str) -> pd.DataFrame:
        """
        Generate specific market scenarios for testing signals.
        
        Scenarios:
        - 'uptrend': Strong upward trend with pullbacks
        - 'downtrend': Strong downward trend with bounces
        - 'rangebound': Sideways movement in channels
        - 'volatile': High volatility with sharp reversals
        - 'breakout': Consolidation followed by breakout
        """
        if scenario == 'uptrend':
            return self._generate_uptrend()
        elif scenario == 'downtrend':
            return self._generate_downtrend()
        elif scenario == 'rangebound':
            return self._generate_rangebound()
        elif scenario == 'volatile':
            return self._generate_volatile()
        elif scenario == 'breakout':
            return self._generate_breakout()
        else:
            return self.generate_weekly_data()
    
    def _generate_uptrend(self) -> pd.DataFrame:
        """Generate uptrend scenario with periodic pullbacks."""
        data = []
        price = 40000
        dates = [datetime.now() - timedelta(weeks=i) for i in range(200)]
        dates.reverse()
        
        for date in dates:
            # Strong upward drift
            drift = 0.025 + np.random.normal(0, 0.02)
            
            # Occasional pullbacks (every 20-30 weeks)
            if random.random() < 0.05:
                drift = -0.05 + np.random.normal(0, 0.02)
            
            open_p = price * (1 + np.random.normal(0, 0.005))
            close_p = open_p * (1 + drift)
            high_p = max(open_p, close_p) * (1 + np.random.uniform(0, 0.03))
            low_p = min(open_p, close_p) * (1 - np.random.uniform(0, 0.02))
            
            data.append({
                'timestamp': date,
                'open': round(open_p, 2),
                'high': round(high_p, 2),
                'low': round(low_p, 2),
                'close': round(close_p, 2),
                'volume': random.uniform(20000, 60000)
            })
            price = close_p
        
        df = pd.DataFrame(data)
        df.set_index('timestamp', inplace=True)
        return df
    
    def _generate_downtrend(self) -> pd.DataFrame:
        """Generate downtrend scenario with periodic bounces."""
        data = []
        price = 60000
        dates = [datetime.now() - timedelta(weeks=i) for i in range(200)]
        dates.reverse()
        
        for date in dates:
            drift = -0.02 + np.random.normal(0, 0.02)
            
            # Occasional bounces
            if random.random() < 0.05:
                drift = 0.04 + np.random.normal(0, 0.02)
            
            open_p = price * (1 + np.random.normal(0, 0.005))
            close_p = open_p * (1 + drift)
            high_p = max(open_p, close_p) * (1 + np.random.uniform(0, 0.02))
            low_p = min(open_p, close_p) * (1 - np.random.uniform(0, 0.03))
            
            data.append({
                'timestamp': date,
                'open': round(open_p, 2),
                'high': round(high_p, 2),
                'low': round(low_p, 2),
                'close': round(close_p, 2),
                'volume': random.uniform(20000, 60000)
            })
            price = close_p
        
        df = pd.DataFrame(data)
        df.set_index('timestamp', inplace=True)
        return df
    
    def _generate_rangebound(self) -> pd.DataFrame:
        """Generate rangebound/scenario for testing channel signals."""
        data = []
        base_price = 50000
        dates = [datetime.now() - timedelta(weeks=i) for i in range(250)]
        dates.reverse()
        
        for date in dates:
            # Mean-reverting behavior
            noise = np.random.normal(0, 0.03)
            drift = -0.001 * (base_price - 50000) / 50000  # Pull to mean
            
            open_p = base_price * (1 + np.random.normal(0, 0.005))
            close_p = open_p * (1 + drift + noise)
            high_p = max(open_p, close_p) * (1 + np.random.uniform(0, 0.02))
            low_p = min(open_p, close_p) * (1 - np.random.uniform(0, 0.02))
            
            data.append({
                'timestamp': date,
                'open': round(open_p, 2),
                'high': round(high_p, 2),
                'low': round(low_p, 2),
                'close': round(close_p, 2),
                'volume': random.uniform(15000, 40000)
            })
            base_price = close_p
        
        df = pd.DataFrame(data)
        df.set_index('timestamp', inplace=True)
        return df
    
    def _generate_volatile(self) -> pd.DataFrame:
        """Generate high volatility scenario."""
        data = []
        price = 50000
        dates = [datetime.now() - timedelta(weeks=i) for i in range(150)]
        dates.reverse()
        
        for date in dates:
            # Large random moves
            drift = np.random.normal(0, 0.08)
            
            open_p = price * (1 + np.random.normal(0, 0.01))
            close_p = open_p * (1 + drift)
            high_p = max(open_p, close_p) * (1 + np.random.uniform(0, 0.05))
            low_p = min(open_p, close_p) * (1 - np.random.uniform(0, 0.05))
            
            data.append({
                'timestamp': date,
                'open': round(open_p, 2),
                'high': round(high_p, 2),
                'low': round(low_p, 2),
                'close': round(close_p, 2),
                'volume': random.uniform(30000, 100000)
            })
            price = close_p
        
        df = pd.DataFrame(data)
        df.set_index('timestamp', inplace=True)
        return df
    
    def _generate_breakout(self) -> pd.DataFrame:
        """Generate consolidation then breakout scenario."""
        data = []
        price = 45000
        dates = [datetime.now() - timedelta(weeks=i) for i in range(200)]
        dates.reverse()
        
        for i, date in enumerate(dates):
            if i < 150:  # Consolidation phase
                drift = np.random.normal(0, 0.015)
            else:  # Breakout phase
                drift = 0.04 + np.random.normal(0, 0.02)
            
            open_p = price * (1 + np.random.normal(0, 0.005))
            close_p = open_p * (1 + drift)
            high_p = max(open_p, close_p) * (1 + np.random.uniform(0, 0.02))
            low_p = min(open_p, close_p) * (1 - np.random.uniform(0, 0.02))
            
            data.append({
                'timestamp': date,
                'open': round(open_p, 2),
                'high': round(high_p, 2),
                'low': round(low_p, 2),
                'close': round(close_p, 2),
                'volume': random.uniform(15000, 50000) if i < 150 else random.uniform(40000, 90000)
            })
            price = close_p
        
        df = pd.DataFrame(data)
        df.set_index('timestamp', inplace=True)
        return df


# Demo scenarios for testing
DEMO_SCENARIOS = {
    'uptrend': 'Strong upward trend with periodic pullbacks',
    'downtrend': 'Strong downward trend with periodic bounces',
    'rangebound': 'Sideways movement - good for channel signals',
    'volatile': 'High volatility with sharp reversals',
    'breakout': 'Consolidation followed by breakout',
    'random': 'Random market conditions'
}


if __name__ == "__main__":
    # Test the demo feed
    feed = DemoDataFeed()
    
    print("=== Demo Data Feed Test ===\n")
    
    for scenario, description in DEMO_SCENARIOS.items():
        df = feed.generate_scenario_data(scenario)
        print(f"{scenario.upper()}: {description}")
        print(f"  Weeks: {len(df)}")
        print(f"  Price range: ${df['low'].min():,.0f} - ${df['high'].max():,.0f}")
        print(f"  Latest close: ${df['close'].iloc[-1]:,.2f}\n")
