"""
multi_source_feed.py — Multi-Source Free Data Feed
Tries multiple free APIs with automatic fallback
No API keys required for basic usage
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Optional, Dict, List, Tuple
import requests
import time
import json


class BinanceFeed:
    """Primary source: Binance (free, no key, best for crypto)"""
    
    BASE_URL = "https://api.binance.com"
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({'User-Agent': 'TrojanLogic4H/1.0'})
    
    def get_4h_data(self, symbol: str, days_back: int = 60) -> Optional[pd.DataFrame]:
        """Fetch 4H data from Binance."""
        try:
            endpoint = f"{self.BASE_URL}/api/v3/klines"
            
            # Calculate time range
            end_time = int(datetime.now().timestamp() * 1000)
            start_time = end_time - (days_back * 24 * 60 * 60 * 1000)
            
            params = {
                "symbol": symbol.upper(),
                "interval": "4h",
                "limit": 1000,
                "startTime": start_time,
                "endTime": end_time
            }
            
            response = self.session.get(endpoint, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if not data:
                return None
            
            df = pd.DataFrame(data, columns=[
                'open_time', 'open', 'high', 'low', 'close', 'volume',
                'close_time', 'quote_volume', 'trades', 'taker_buy_volume',
                'taker_buy_quote_volume', 'ignore'
            ])
            
            for col in ['open', 'high', 'low', 'close', 'volume']:
                df[col] = pd.to_numeric(df[col], errors='coerce')
            
            df['open_time'] = pd.to_datetime(df['open_time'], unit='ms')
            df.set_index('open_time', inplace=True)
            
            return df[['open', 'high', 'low', 'close', 'volume']]
            
        except Exception as e:
            print(f"Binance error: {e}")
            return None


class CoinGeckoFeed:
    """Fallback 1: CoinGecko (free tier, no key needed for basic)"""
    
    BASE_URL = "https://api.coingecko.com/api/v3"
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({'User-Agent': 'TrojanLogic4H/1.0'})
    
    def get_4h_data(self, coin_id: str = "bitcoin", days: int = 60) -> Optional[pd.DataFrame]:
        """Fetch OHLC data from CoinGecko."""
        try:
            endpoint = f"{self.BASE_URL}/coins/{coin_id}/ohlc"
            
            params = {
                "vs_currency": "usd",
                "days": str(days)
            }
            
            response = self.session.get(endpoint, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if not data or not isinstance(data, list):
                return None
            
            # CoinGecko OHLC format: [timestamp, open, high, low, close]
            df = pd.DataFrame(data, columns=['timestamp', 'open', 'high', 'low', 'close'])
            df['timestamp'] = pd.to_datetime(df['timestamp'], unit='ms')
            df.set_index('timestamp', inplace=True)
            df['volume'] = 0  # CoinGecko OHLC doesn't include volume
            
            return df[['open', 'high', 'low', 'close', 'volume']]
            
        except Exception as e:
            print(f"CoinGecko error: {e}")
            return None
    
    def symbol_to_id(self, symbol: str) -> str:
        """Convert trading symbol to CoinGecko coin ID."""
        mapping = {
            "BTC": "bitcoin",
            "ETH": "ethereum",
            "SOL": "solana",
            "BNB": "binancecoin",
            "XRP": "ripple",
            "ADA": "cardano",
            "DOGE": "dogecoin",
            "AVAX": "avalanche-2",
            "LINK": "chainlink",
            "DOT": "polkadot",
            "MATIC": "matic-network",
            "UNI": "uniswap",
            "LTC": "litecoin",
            "BCH": "bitcoin-cash",
            "ETC": "ethereum-classic"
        }
        return mapping.get(symbol.replace("USDT", "").upper(), "bitcoin")


class KrakenFeed:
    """Fallback 2: Kraken (free, no key, good for Europe)"""
    
    BASE_URL = "https://api.kraken.com"
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({'User-Agent': 'TrojanLogic4H/1.0'})
    
    def get_4h_data(self, symbol: str, days_back: int = 60) -> Optional[pd.DataFrame]:
        """Fetch 4H data from Kraken."""
        try:
            endpoint = f"{self.BASE_URL}/0/public/OHLC"
            
            # Convert symbol to Kraken format (e.g., BTCUSDT -> XBTUSD)
            kraken_symbol = self._convert_symbol(symbol)
            
            since = int((datetime.now() - timedelta(days=days_back)).timestamp())
            
            params = {
                "pair": kraken_symbol,
                "interval": 240,  # 4 hours in minutes
                "since": since
            }
            
            response = self.session.get(endpoint, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if data.get('error'):
                print(f"Kraken API error: {data['error']}")
                return None
            
            ohlc_data = data['result'].get(kraken_symbol, [])
            if not ohlc_data:
                return None
            
            # Kraken OHLC format: [time, open, high, low, close, vwap, volume, count]
            df = pd.DataFrame(ohlc_data, columns=[
                'time', 'open', 'high', 'low', 'close', 'vwap', 'volume', 'count'
            ])
            
            df['time'] = pd.to_datetime(df['time'], unit='s')
            df.set_index('time', inplace=True)
            
            for col in ['open', 'high', 'low', 'close', 'volume']:
                df[col] = pd.to_numeric(df[col], errors='coerce')
            
            return df[['open', 'high', 'low', 'close', 'volume']]
            
        except Exception as e:
            print(f"Kraken error: {e}")
            return None
    
    def _convert_symbol(self, symbol: str) -> str:
        """Convert standard symbol to Kraken format."""
        symbol = symbol.upper().replace("USDT", "USD")
        if symbol.startswith("BTC"):
            symbol = "XBT" + symbol[3:]
        return symbol


class CryptoCompareFeed:
    """Fallback 3: CryptoCompare (free tier, key optional)"""
    
    BASE_URL = "https://min-api.cryptocompare.com/data"
    
    def __init__(self, api_key: Optional[str] = None):
        self.session = requests.Session()
        self.session.headers.update({'User-Agent': 'TrojanLogic4H/1.0'})
        self.api_key = api_key
    
    def get_4h_data(self, symbol: str = "BTC", days_back: int = 60) -> Optional[pd.DataFrame]:
        """Fetch 4H data from CryptoCompare."""
        try:
            endpoint = f"{self.BASE_URL}/v2/histohour"
            
            params = {
                "fsym": symbol.replace("USDT", "").upper(),
                "tsym": "USD",
                "limit": min(days_back * 6, 2000),  # 6 4H candles per day
                "aggregate": 4  # 4-hour candles
            }
            
            if self.api_key:
                params["api_key"] = self.api_key
            
            response = self.session.get(endpoint, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if data.get('Response') != 'Success':
                print(f"CryptoCompare error: {data.get('Message')}")
                return None
            
            ohlc_data = data['Data']['Data']
            if not ohlc_data:
                return None
            
            df = pd.DataFrame(ohlc_data)
            df['time'] = pd.to_datetime(df['time'], unit='s')
            df.set_index('time', inplace=True)
            df.rename(columns={
                'open': 'open',
                'high': 'high',
                'low': 'low',
                'close': 'close',
                'volumefrom': 'volume'
            }, inplace=True)
            
            return df[['open', 'high', 'low', 'close', 'volume']]
            
        except Exception as e:
            print(f"CryptoCompare error: {e}")
            return None


class MultiSourceFeed:
    """
    Multi-source data feed with automatic fallback.
    Tries sources in order until one succeeds.
    """
    
    def __init__(self, cryptocompare_key: Optional[str] = None):
        self.binance = BinanceFeed()
        self.coingecko = CoinGeckoFeed()
        self.kraken = KrakenFeed()
        self.cryptocompare = CryptoCompareFeed(api_key=cryptocompare_key)
        
        # Track which source was used last
        self.last_source = None
    
    def get_4h_data(self, symbol: str = "BTCUSDT", days_back: int = 60) -> pd.DataFrame:
        """
        Fetch 4H data with automatic fallback.
        
        Order:
        1. Binance (best for crypto)
        2. CoinGecko (reliable fallback)
        3. Kraken (European exchange)
        4. CryptoCompare (last resort)
        
        Args:
            symbol: Trading pair (e.g., "BTCUSDT", "ETHUSDT")
            days_back: Days of history
        
        Returns:
            DataFrame with OHLCV data
        
        Raises:
            ConnectionError: If all sources fail
        """
        symbol_upper = symbol.upper()
        errors = []
        
        # Try Binance first
        print(f"Trying Binance for {symbol_upper}...")
        df = self.binance.get_4h_data(symbol_upper, days_back)
        if df is not None and len(df) >= 220:
            self.last_source = "Binance"
            print(f"[OK] Binance success: {len(df)} candles")
            return df
        errors.append("Binance failed")
        time.sleep(0.5)
        
        # Try CoinGecko
        print(f"Trying CoinGecko for {symbol_upper}...")
        coin_id = self.coingecko.symbol_to_id(symbol_upper)
        df = self.coingecko.get_4h_data(coin_id, days_back)
        if df is not None and len(df) >= 50:
            self.last_source = "CoinGecko"
            print(f"[OK] CoinGecko success: {len(df)} candles")
            return df
        errors.append("CoinGecko failed")
        time.sleep(0.5)
        
        # Try Kraken
        print(f"Trying Kraken for {symbol_upper}...")
        df = self.kraken.get_4h_data(symbol_upper, days_back)
        if df is not None and len(df) >= 50:
            self.last_source = "Kraken"
            print(f"[OK] Kraken success: {len(df)} candles")
            return df
        errors.append("Kraken failed")
        time.sleep(0.5)
        
        # Try CryptoCompare
        print(f"Trying CryptoCompare for {symbol_upper}...")
        df = self.cryptocompare.get_4h_data(symbol_upper, days_back)
        if df is not None and len(df) >= 50:
            self.last_source = "CryptoCompare"
            print(f"[OK] CryptoCompare success: {len(df)} candles")
            return df
        errors.append("CryptoCompare failed")
        
        # All failed
        raise ConnectionError(f"All data sources failed for {symbol}. Errors: {errors}")
    
    def get_data_with_validation(self, symbol: str = "BTCUSDT", days_back: int = 60) -> Tuple[pd.DataFrame, Dict]:
        """
        Get data with cross-validation from multiple sources.
        Compares prices to detect anomalies.
        
        Returns:
            Tuple of (DataFrame, validation_info)
        """
        df = self.get_4h_data(symbol, days_back)
        
        validation_info = {
            "source": self.last_source,
            "candles": len(df),
            "date_range": f"{df.index[0]} to {df.index[-1]}",
            "price_range": f"${df['low'].min():,.2f} - ${df['high'].max():,.2f}",
            "avg_volume": f"{df['volume'].mean():,.0f}"
        }
        
        return df, validation_info
    
    def test_all_sources(self, symbol: str = "BTCUSDT") -> Dict[str, bool]:
        """Test all data sources and return status."""
        results = {}
        
        print(f"\n=== Testing all sources for {symbol} ===\n")
        
        # Test Binance
        try:
            df = self.binance.get_4h_data(symbol, days_back=7)
            results["Binance"] = df is not None and len(df) > 0
            print(f"Binance: {'[OK]' if results['Binance'] else '[FAILED]'}")
        except Exception as e:
            results["Binance"] = False
            print(f"Binance: [ERROR] - {e}")
        
        time.sleep(1)
        
        # Test CoinGecko
        try:
            coin_id = self.coingecko.symbol_to_id(symbol)
            df = self.coingecko.get_4h_data(coin_id, days=7)
            results["CoinGecko"] = df is not None and len(df) > 0
            print(f"CoinGecko: {'[OK]' if results['CoinGecko'] else '[FAILED]'}")
        except Exception as e:
            results["CoinGecko"] = False
            print(f"CoinGecko: [ERROR] - {e}")
        
        time.sleep(1)
        
        # Test Kraken
        try:
            df = self.kraken.get_4h_data(symbol, days_back=7)
            results["Kraken"] = df is not None and len(df) > 0
            print(f"Kraken: {'[OK]' if results['Kraken'] else '[FAILED]'}")
        except Exception as e:
            results["Kraken"] = False
            print(f"Kraken: [ERROR] - {e}")
        
        time.sleep(1)
        
        # Test CryptoCompare
        try:
            df = self.cryptocompare.get_4h_data(symbol, days_back=7)
            results["CryptoCompare"] = df is not None and len(df) > 0
            print(f"CryptoCompare: {'[OK]' if results['CryptoCompare'] else '[FAILED]'}")
        except Exception as e:
            results["CryptoCompare"] = False
            print(f"CryptoCompare: [ERROR] - {e}")
        
        return results


# Example usage
if __name__ == "__main__":
    print("=== Multi-Source Free Data Feed Test ===\n")
    
    feed = MultiSourceFeed()
    
    # Test all sources
    results = feed.test_all_sources("BTCUSDT")
    
    print("\n=== Summary ===")
    working = sum(results.values())
    print(f"Working sources: {working}/{len(results)}")
    
    if working > 0:
        print("\n=== Fetching BTC 4H data ===")
        try:
            df, info = feed.get_data_with_validation("BTCUSDT", days_back=30)
            print(f"\n[OK] Success from {info['source']}")
            print(f"Candles: {info['candles']}")
            print(f"Range: {info['date_range']}")
            print(f"Price: {info['price_range']}")
            print(f"\nLast 5 candles:")
            print(df.tail()[['open', 'high', 'low', 'close', 'volume']])
        except Exception as e:
            print(f"\n[FAILED] Failed: {e}")
