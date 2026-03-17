"""
notion_crypto_dashboard_v2.py — Enhanced Visual Crypto Dashboard for Notion
Uses actual emojis for visual indicators
"""
import json
import requests
from datetime import datetime

NOTION_TOKEN = "ntn_R12262668454JRCXah04DVY4uPiw6HW9G1Z69TdAXJibKD"
PARENT_PAGE_ID = "3230491758dd80a08614d4808e0af030"

headers = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28"
}

def create_visual_dashboard():
    """Create enhanced visual Crypto Dashboard."""
    
    # Load analysis results
    try:
        with open('top_20_analysis_20260314_212806.json', 'r') as f:
            analysis_data = json.load(f)
    except:
        print("No analysis file found")
        return
    
    results = analysis_data.get('results', [])
    
    # Create page
    url = "https://api.notion.com/v1/pages"
    
    data = {
        "parent": {"page_id": PARENT_PAGE_ID},
        "properties": {
            "title": {
                "title": [
                    {"text": {"content": "Crypto Dashboard V2 - Visual Edition"}}
                ]
            }
        },
        "children": [
            {
                "object": "block",
                "type": "callout",
                "callout": {
                    "rich_text": [
                        {"text": {"content": "TrojanLogic4H Live Trading Dashboard\n\nReal-time analysis of TOP 20 cryptocurrencies with visual signal indicators.\n\nLast Updated: " + datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}}
                    ],
                    "icon": {"emoji": "📊"},
                    "color": "blue_background"
                }
            },
            {
                "object": "block",
                "type": "divider",
                "divider": {}
            },
            {
                "object": "block",
                "type": "heading_2",
                "heading_2": {
                    "rich_text": [{"text": {"content": "🔥 ACTIVE TRADE OPPORTUNITIES"}}]
                }
            }
        ]
    }
    
    # Add opportunities section
    opportunities = [r for r in results if r.get('signal') in ['long', 'short'] and r.get('confidence', 0) >= 0.45]
    
    if opportunities:
        for opp in sorted(opportunities, key=lambda x: x['confidence'], reverse=True):
            signal_emoji = "🟢" if opp['signal'] == 'long' else "🔴"
            color = "green" if opp['signal'] == 'long' else "red"
            
            data['children'].append({
                "object": "block",
                "type": "callout",
                "callout": {
                    "rich_text": [
                        {"text": {"content": f"{opp['symbol'].replace('USDT', '')}\n\nSignal: {opp['signal'].upper()}\nConfidence: {opp['confidence']:.0%}\nPrice: ${opp['price']:,.4f}\nSetup: {opp['setup_type']}\n\nCS RSI: {opp['csrsi_state']}\nRtoM Bias: {opp['rtom_bias']}\nPosition: {opp['rtom_position']}"}}
                    ],
                    "icon": {"emoji": signal_emoji},
                    "color": f"{color}_background"
                }
            })
    else:
        data['children'].append({
            "object": "block",
            "type": "callout",
            "callout": {
                "rich_text": [
                    {"text": {"content": "No high-confidence trade opportunities at this time.\n\nMarket is in a holding pattern. Check back in 4 hours for new signals."}}
                ],
                "icon": {"emoji": "⏸️"},
                "color": "yellow_background"
            }
        })
    
    # Add divider
    data['children'].append({
        "object": "block",
        "type": "divider",
        "divider": {}
    })
    
    # Add full market table
    data['children'].append({
        "object": "block",
        "type": "heading_2",
        "heading_2": {
            "rich_text": [{"text": {"content": "📈 TOP 20 MARKET OVERVIEW"}}]
        }
    })
    
    # Create table with visual indicators
    table_block = {
        "object": "block",
        "type": "table",
        "table": {
            "table_width": 7,
            "has_column_header": True,
            "has_row_header": False,
            "children": [
                {
                    "object": "block",
                    "type": "table_row",
                    "table_row": {
                        "cells": [
                            [{"text": {"content": "RANK"}}],
                            [{"text": {"content": "SYMBOL"}}],
                            [{"text": {"content": "SIGNAL"}}],
                            [{"text": {"content": "CONFIDENCE"}}],
                            [{"text": {"content": "PRICE"}}],
                            [{"text": {"content": "CS RSI"}}],
                            [{"text": {"content": "STATUS"}}]
                        ]
                    }
                }
            ]
        }
    }
    
    # Add rows with color coding
    for i, r in enumerate(results[:20], 1):
        signal = r.get('signal', 'hold').upper()
        confidence = r.get('confidence', 0)
        
        # Visual signal indicator
        if signal == 'LONG':
            signal_display = "🟢 LONG"
            status = "✅ BUY"
        elif signal == 'SHORT':
            signal_display = "🔴 SHORT"
            status = "⚠️ SELL"
        else:
            signal_display = "⚪ HOLD"
            status = "⏸️ WAIT"
        
        conf_display = f"{confidence:.0%}"
        
        row = {
            "object": "block",
            "type": "table_row",
            "table_row": {
                "cells": [
                    [{"text": {"content": str(i)}}],
                    [{"text": {"content": r.get('symbol', 'N/A').replace('USDT', '')}}],
                    [{"text": {"content": signal_display}}],
                    [{"text": {"content": conf_display}}],
                    [{"text": {"content": f"${r.get('price', 0):,.4f}"}}],
                    [{"text": {"content": f"{r.get('csrsi_red', 0):.1f}"}}],
                    [{"text": {"content": status}}]
                ]
            }
        }
        table_block['table']['children'].append(row)
    
    data['children'].append(table_block)
    
    # Add strategy info
    data['children'].extend([
        {
            "object": "block",
            "type": "divider",
            "divider": {}
        },
        {
            "object": "block",
            "type": "heading_2",
            "heading_2": {
                "rich_text": [{"text": {"content": "⚙️ Strategy Configuration"}}]
            }
        },
        {
            "object": "block",
            "type": "bulleted_list_item",
            "bulleted_list_item": {
                "rich_text": [{"text": {"content": "CS RSI MTF: Short Cycle=13, Long Cycle=64"}}]
            }
        },
        {
            "object": "block",
            "type": "bulleted_list_item",
            "bulleted_list_item": {
                "rich_text": [{"text": {"content": "RtoM Channels: 200-day lookback, Inner=1.0x, Outer=2.415x"}}]
            }
        },
        {
            "object": "block",
            "type": "bulleted_list_item",
            "bulleted_list_item": {
                "rich_text": [{"text": {"content": "Data Sources: Binance (primary), CoinGecko (fallback), Kraken (backup)"}}]
            }
        },
        {
            "object": "block",
            "type": "bulleted_list_item",
            "bulleted_list_item": {
                "rich_text": [{"text": {"content": "Signal Threshold: 45%+ confidence for trade consideration"}}]
            }
        },
        {
            "object": "block",
            "type": "divider",
            "divider": {}
        },
        {
            "object": "block",
            "type": "heading_2",
            "heading_2": {
                "rich_text": [{"text": {"content": "📋 Legend"}}]
            }
        },
        {
            "object": "block",
            "type": "bulleted_list_item",
            "bulleted_list_item": {
                "rich_text": [{"text": {"content": "🟢 LONG = Buy signal detected"}}]
            }
        },
        {
            "object": "block",
            "type": "bulleted_list_item",
            "bulleted_list_item": {
                "rich_text": [{"text": {"content": "🔴 SHORT = Sell signal detected"}}]
            }
        },
        {
            "object": "block",
            "type": "bulleted_list_item",
            "bulleted_list_item": {
                "rich_text": [{"text": {"content": "⚪ HOLD = No valid setup, wait for next signal"}}]
            }
        },
        {
            "object": "block",
            "type": "bulleted_list_item",
            "bulleted_list_item": {
                "rich_text": [{"text": {"content": "Confidence: STRONG (85%+), MODERATE (65-84%), WEAK (45-64%), WATCH (<45%)"}}]
            }
        }
    ])
    
    response = requests.post(url, headers=headers, json=data)
    
    if response.status_code == 200:
        page_id = response.json()['id']
        print(f"[OK] Created Visual Crypto Dashboard: {page_id}")
        return page_id
    else:
        print(f"[FAIL] Error: {response.status_code}")
        return None

if __name__ == "__main__":
    print("=== Creating Visual Crypto Dashboard V2 ===\n")
    page_id = create_visual_dashboard()
    if page_id:
        print(f"\nDashboard URL: https://notion.so/{page_id.replace('-', '')}")
