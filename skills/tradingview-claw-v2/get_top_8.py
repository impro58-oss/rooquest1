import requests
import json

# Get top symbols by 24h volume from Binance
url = 'https://api.binance.com/api/v3/ticker/24hr'
response = requests.get(url, timeout=30)
data = response.json()

# Filter USDT pairs and sort by volume
usdt_pairs = [d for d in data if d['symbol'].endswith('USDT')]
usdt_pairs.sort(key=lambda x: float(x['quoteVolume']), reverse=True)

# Top 8
top_8 = usdt_pairs[:8]

print('=== TOP 8 CRYPTO BY VOLUME ===')
for i, pair in enumerate(top_8, 1):
    print(f"{i}. {pair['symbol']} - Price: ${float(pair['lastPrice']):,.2f} - 24h Vol: ${float(pair['quoteVolume']):,.0f}")

# Save to file for analysis
with open('top_8_cryptos.json', 'w') as f:
    json.dump([{'symbol': p['symbol'], 'price': float(p['lastPrice']), 'volume': float(p['quoteVolume'])} for p in top_8], f, indent=2)

print('\nSaved to top_8_cryptos.json')
