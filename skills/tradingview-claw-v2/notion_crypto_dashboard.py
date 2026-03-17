"""
notion_crypto_dashboard.py — Create/update Notion Crypto Dashboard
"""
import json
import requests
from datetime import datetime

# Notion API config
NOTION_TOKEN = "ntn_R12262668454JRCXah04DVY4uPiw6HW9G1Z69TdAXJibKD"
PARENT_PAGE_ID = "3230491758dd80a08614d4808e0af030"  # Roo Control Room

headers = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28"
}

def create_crypto_dashboard():
    """Create Crypto Dashboard page in Notion."""
    
    # Create page
    url = "https://api.notion.com/v1/pages"
    
    data = {
        "parent": {"page_id": PARENT_PAGE_ID},
        "properties": {
            "title": {
                "title": [
                    {"text": {"content": "[DASHBOARD] Crypto Dashboard"}}
                ]
            }
        },
        "children": [
            {
                "object": "block",
                "type": "heading_1",
                "heading_1": {
                    "rich_text": [{"text": {"content": "[ROCKET] TrojanLogic4H Live Dashboard"}}]
                }
            },
            {
                "object": "block",
                "type": "paragraph",
                "paragraph": {
                    "rich_text": [
                        {"text": {"content": "Real-time analysis of top 8 cryptocurrencies using TrojanLogic4H strategy."}}
                    ]
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
                    "rich_text": [{"text": {"content": "[DATE] Last Updated"}}]
                }
            },
            {
                "object": "block",
                "type": "paragraph",
                "paragraph": {
                    "rich_text": [
                        {"text": {"content": f"Analysis Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}"}}
                    ]
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
                    "rich_text": [{"text": {"content": "[CHART] Strategy Parameters"}}]
                }
            },
            {
                "object": "block",
                "type": "bulleted_list_item",
                "bulleted_list_item": {
                    "rich_text": [{"text": {"content": "CS RSI MTF: Short=13, Long=64"}}]
                }
            },
            {
                "object": "block",
                "type": "bulleted_list_item",
                "bulleted_list_item": {
                    "rich_text": [{"text": {"content": "RtoM Channels: Lookback=200, Inner=1.0x, Outer=2.415x"}}]
                }
            },
            {
                "object": "block",
                "type": "bulleted_list_item",
                "bulleted_list_item": {
                    "rich_text": [{"text": {"content": "Data Source: Binance (free API)"}}]
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
                    "rich_text": [{"text": {"content": "[FIRE] Top 8 Analysis Results"}}]
                }
            }
        ]
    }
    
    response = requests.post(url, headers=headers, json=data)
    
    if response.status_code == 200:
        page_id = response.json()['id']
        print(f"[OK] Created Crypto Dashboard: {page_id}")
        return page_id
    else:
        print(f"[FAIL] Error: {response.status_code}")
        print(response.text)
        return None

def add_crypto_table(page_id):
    """Add crypto analysis table to dashboard."""
    
    url = f"https://api.notion.com/v1/blocks/{page_id}/children"
    
    # Load analysis results
    try:
        with open('top_8_analysis_20260314_212304.json', 'r') as f:
            analysis_data = json.load(f)
    except:
        print("[WARN] No analysis file found")
        return
    
    results = analysis_data.get('results', [])
    
    # Create table
    table_data = {
        "children": [
            {
                "object": "block",
                "type": "table",
                "table": {
                    "table_width": 8,
                    "has_column_header": True,
                    "has_row_header": False,
                    "children": [
                        # Header row
                        {
                            "object": "block",
                            "type": "table_row",
                            "table_row": {
                                "cells": [
                                    [{"text": {"content": "Symbol"}}],
                                    [{"text": {"content": "Price"}}],
                                    [{"text": {"content": "Signal"}}],
                                    [{"text": {"content": "Confidence"}}],
                                    [{"text": {"content": "CS RSI State"}}],
                                    [{"text": {"content": "RtoM Bias"}}],
                                    [{"text": {"content": "Position"}}],
                                    [{"text": {"content": "Notes"}}]
                                ]
                            }
                        }
                    ]
                }
            }
        ]
    }
    
    # Add data rows
    for r in results:
        signal = r.get('signal', 'hold').upper()
        confidence = f"{r.get('confidence', 0):.0%}"
        
        row = {
            "object": "block",
            "type": "table_row",
            "table_row": {
                "cells": [
                    [{"text": {"content": r.get('symbol', 'N/A')}}],
                    [{"text": {"content": f"${r.get('price', 0):,.2f}"}}],
                    [{"text": {"content": signal}}],
                    [{"text": {"content": confidence}}],
                    [{"text": {"content": r.get('csrsi_state', 'N/A')}}],
                    [{"text": {"content": r.get('rtom_bias', 'N/A')}}],
                    [{"text": {"content": r.get('rtom_position', 'N/A')}}],
                    [{"text": {"content": ', '.join(r.get('reasons', []))[:50]}}]
                ]
            }
        }
        table_data['children'][0]['table']['children'].append(row)
    
    response = requests.patch(url, headers=headers, json=table_data)
    
    if response.status_code == 200:
        print("[OK] Added crypto analysis table")
    else:
        print(f"[FAIL] Error adding table: {response.status_code}")
        print(response.text)

if __name__ == "__main__":
    print("=== Creating Notion Crypto Dashboard ===\n")
    
    page_id = create_crypto_dashboard()
    if page_id:
        add_crypto_table(page_id)
        print(f"\n🔗 Dashboard URL: https://notion.so/{page_id.replace('-', '')}")
