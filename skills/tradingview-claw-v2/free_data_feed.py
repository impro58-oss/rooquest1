"""
free_data_feed.py — Free Crypto Data Feed for TrojanLogic4H
Uses Binance API (free, no key required) for OHLCV data
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Optional, Dict, List
import requests
import time


class BinanceDataFeed:
    """
    Free data feed from Binance API.
    No API key required for public endpoints.
    """
    
    BASE_URL = "https://api.binance.com"
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'TrojanLogic4H/1.0'
        })
    
    def get_klines(
        self,
        symbol: str,
        interval: str = "4h",
        limit: int = 500,
        start_time: Optional[int] = None,
        end_time: Optional[int] = None
    ) -> pd.DataFrame:
        """
        Fetch OHLCV data from Binance.
        
        Args:
            symbol: Trading pair (e.g., "BTCUSDT", "ETHUSDT")
            interval: Candle interval (1m, 5m, 15m, 1h, 4h, 1d, etc.)
            limit: Number of candles (max 1000)
            start_time: Start time in milliseconds (optional)
            end_time: End time in milliseconds (optional)
        
        Returns:
            DataFrame with columns: open, high, low, close, volume, close_time
        """
        endpoint = f"{self.BASE_URL}/api/v3/klines"
        
        params = {
            "symbol": symbol.upper(),
            "interval": interval,
            "limit": min(limit, 1000)
        }
        
        if start_time:
            params["startTime"] = start_time
        if end_time:
            params["endTime"] = end_time
        
        try:
            response = self.session.get(endpoint, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if not data:
                raise ValueError(f"No data returned for {symbol}")
            
            # Binance kline format:
            # [open_time, open, high, low, close, volume, close_time, ...]
            df = pd.DataFrame(data, columns=[
                'open_time', 'open', 'high', 'low', 'close', 'volume',
                'close_time', 'quote_volume', 'trades', 'taker_buy_volume',
                'taker_buy_quote_volume', 'ignore'
            ])
            
            # Convert to numeric
            for col in ['open', 'high', 'low', 'close', 'volume']:
                df[col] = pd.to_numeric(df[col], errors='coerce')
            
            # Convert timestamps
            df['open_time'] = pd.to_datetime(df['open_time'], unit='ms')
            df['close_time'] = pd.to_datetime(df['close_time'], unit='ms')
            
            # Set index
            df.set_index('open_time', inplace=True)
            
            return df[['open', 'high', 'low', 'close', 'volume', 'close_time']]
            
        except requests.exceptions.RequestException as e:
            raise ConnectionError(f"Failed to fetch data from Binance: {e}")
    
    def get_4h_data(
        self,
        symbol: str,
        days_back: int = 30
    ) -> pd.DataFrame:
        """
        Get 4H data for TrojanLogic4H analysis.
        
        Args:
            symbol: Trading pair (e.g., "BTCUSDT")
            days_back: How many days of history (default 30 = ~180 4H candles)
        
        Returns:
            DataFrame with OHLCV data (needs 220+ rows for TrojanLogic4H)
        """
        # Calculate start time
        end_time = int(datetime.now().timestamp() * 1000)
        start_time = end_time - (days_back * 24 * 60 * 60 * 1000)
        
        # Fetch in chunks if needed (Binance max 1000 per request)
        all_data = []
        current_start = start_time
        
        while current_start < end_time:
            chunk = self.get_klines(
                symbol=symbol,
                interval="4h",
                limit=1000,
                start_time=current_start,
                end_time=end_time
            )
            
            if len(chunk) == 0:
                break
                
            all_data.append(chunk)
            
            # Move start time to after last candle
            last_time = chunk.index[-1]
            current_start = int(last_time.timestamp() * 1000) + 1
            
            # Rate limit protection
            time.sleep(0.1)
        
        if not all_data:
            raise ValueError(f"No data retrieved for {symbol}")
        
        # Combine chunks
        df = pd.concat(all_data)
        df = df[~df.index.duplicated(keep='last')]  # Remove duplicates
        df.sort_index(inplace=True)
        
        return df
    
    def get_available_symbols(self, quote_asset: str = "USDT") -> List[str]:
        """
        Get list of available trading pairs.
        
        Args:
            quote_asset: Filter by quote currency (e.g., "USDT", "BTC")
        
        Returns:
            List of symbol strings
        """
        endpoint = f"{self.BASE_URL}/api/v3/exchangeInfo"
        
        try:
            response = self.session.get(endpoint, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            symbols = []
            for symbol_info in data['symbols']:
                if (symbol_info['quoteAsset'] == quote_asset and 
                    symbol_info['status'] == 'TRADING'):
                    symbols.append(symbol_info['symbol'])
            
            return sorted(symbols)
            
        except requests.exceptions.RequestException as e:
            raise ConnectionError(f"Failed to fetch exchange info: {e}")
    
    def get_ticker_24h(self, symbol: str) -> Dict:
        """
        Get 24h ticker data (price, volume, change).
        
        Args:
            symbol: Trading pair
        
        Returns:
            Dictionary with ticker data
        """
        endpoint = f"{self.BASE_URL}/api/v3/ticker/24hr"
        
        params = {"symbol": symbol.upper()}
        
        try:
            response = self.session.get(endpoint, params=params, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            raise ConnectionError(f"Failed to fetch ticker: {e}")


class YahooFinanceFeed:
    """
    Alternative: Yahoo Finance (for stocks, forex, some crypto).
    Uses yfinance library.
    """
    
    def __init__(self):
        try:
            import yfinance as yf
            self.yf = yf
        except ImportError:
            raise ImportError("yfinance not installed. Run: pip install yfinance")
    
    def get_data(
        self,
        symbol: str,
        period: str = "60d",
        interval: str = "1h"
    ) -> pd.DataFrame:
        """
        Get data from Yahoo Finance.
        
        Args:
            symbol: Ticker symbol (e.g., "BTC-USD", "ETH-USD", "AAPL")
            period: Data period (1d, 5d, 1mo, 3mo, 6mo, 1y, etc.)
            interval: Candle interval (1m, 2m, 5m, 15m, 30m, 60m, 1d)
        
        Returns:
            DataFrame with OHLCV
        """
        ticker = self.yf.Ticker(symbol)
        df = ticker.history(period=period, interval=interval)
        
        if df.empty:
            raise ValueError(f"No data returned for {symbol}")
        
        # Rename columns to lowercase
        df.columns = [c.lower().replace(' ', '_') for c in df.columns]
        
        # Ensure required columns exist
        required = ['open', 'high', 'low', 'close']
        for col in required:
            if col not in df.columns:
                raise ValueError(f"Missing required column: {col}")
        
        return df


class DataFeedManager:
    """
    Unified interface for multiple free data sources.
    Easy to upgrade to CoinGlass later.
    """
    
    def __init__(self):
        self.binance = BinanceDataFeed()
        self.yahoo = None  # Lazy load
    
    def get_crypto_4h(self, symbol: str, days_back: int = 30) -> pd.DataFrame:
        """
        Get 4H crypto data (Binance preferred).
        
        Args:
            symbol: Trading pair (e.g., "BTCUSDT", "ETHUSDT")
            days_back: Days of history
        
        Returns:
            DataFrame ready for TrojanLogic4H
        """
        return self.binance.get_4h_data(symbol, days_back)
    
    def get_stock_data(self, symbol: str, period: str = "6mo") -> pd.DataFrame:
        """
        Get stock data (Yahoo Finance).
        
        Args:
            symbol: Stock ticker (e.g., "AAPL", "TSLA")
            period: Data period
        """
        if self.yahoo is None:
            self.yahoo = YahooFinanceFeed()
        return self.yahoo.get_data(symbol, period=period, interval="1h")
    
    def list_crypto_pairs(self, quote: str = "USDT") -> List[str]:
        """List available crypto trading pairs."""
        return self.binance.get_available_symbols(quote)


# Example usage
if __name__ == "__main__":
    print("=== Free Data Feed Demo ===\n")
    
    feed = DataFeedManager()
    
    # List available pairs
    print("Fetching available USDT pairs...")
    pairs = feed.list_crypto_pairs("USDT")
    print(f"Found {len(pairs)} pairs")
    print(f"Top 10: {pairs[:10]}\n")
    
    # Get BTC 4H data
    print("Fetching BTC 4H data...")
    try:
        df = feed.get_crypto_4h("BTCUSDT", days_back=30)
        print(f"Retrieved {len(df)} candles")
        print(f"Date range: {df.index[0]} to {df.index[-1]}")
        print(f"\nLast 5 candles:")
        print(df.tail()[['open', 'high', 'low', 'close', 'volume']])
    except Exception as e:
        print(f"Error: {e}")
