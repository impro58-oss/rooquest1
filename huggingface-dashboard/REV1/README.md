---
title: Roo Crypto Intelligence Dashboard
emoji: 📊
colorFrom: blue
colorTo: green
sdk: streamlit
sdk_version: "1.28.0"
python_version: "3.9"
app_file: app.py
pinned: false
---

# Roo Crypto Intelligence Dashboard

Real-time visualization of TrojanLogic4H crypto trading signals.

## Data Source

This dashboard pulls data from:
- **Latest Scan**: https://raw.githubusercontent.com/impro58-oss/rooquest1/main/data/crypto/crypto_latest.json
- **Historical Data**: https://raw.githubusercontent.com/impro58-oss/rooquest1/main/data/crypto/crypto_history.json

Data is updated every 3 hours via automated scans.

## Features

- **Signal Distribution**: Visual breakdown of LONG/SHORT/HOLD signals
- **Confidence Analysis**: Distribution of confidence scores across all symbols
- **Top Opportunities**: High-confidence trading opportunities (65%+)
- **Symbol Trends**: Historical price and signal tracking for individual cryptos
- **Real-time Updates**: Data refreshes automatically from GitHub

## Strategy

**TrojanLogic4H** uses:
- CS RSI MTF (13/64 cycle)
- RtoM Channels (200-day lookback)
- Multi-source data (Binance, CoinGecko, Kraken, CryptoCompare)

## Classification

- **FUTURES**: High-confidence trades (65%+ confidence)
- **HOLD**: Core convictions (BTC, ETH, SOL, XRP, DOGE, BNB, LINK)
- **MONITOR**: Watch list

## Links

- **Live Dashboard**: https://roowoo-roo-crypto-dashboard.hf.space
- GitHub Repository: https://github.com/impro58-oss/rooquest1
- Notion Dashboard: https://notion.so/3230491758dd819c90e4fce960777521
