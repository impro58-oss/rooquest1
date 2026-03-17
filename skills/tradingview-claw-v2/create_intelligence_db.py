"""
create_crypto_intelligence_db.py — Create Notion database for historical crypto data
"""
import requests
import json

NOTION_TOKEN = "ntn_R12262668454JRCXah04DVY4uPiw6HW9G1Z69TdAXJibKD"
PARENT_PAGE_ID = "3230491758dd80a08614d4808e0af030"

headers = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28"
}

def create_database():
    """Create Crypto Intelligence Database in Notion."""
    
    url = "https://api.notion.com/v1/databases"
    
    data = {
        "parent": {"page_id": PARENT_PAGE_ID},
        "title": [
            {"text": {"content": "Crypto Intelligence Database"}}
        ],
        "properties": {
            "Symbol": {
                "title": {}
            },
            "Timestamp": {
                "date": {}
            },
            "Price": {
                "number": {
                    "format": "dollar"
                }
            },
            "Signal": {
                "select": {
                    "options": [
                        {"name": "LONG", "color": "green"},
                        {"name": "SHORT", "color": "red"},
                        {"name": "HOLD", "color": "gray"}
                    ]
                }
            },
            "Confidence %": {
                "number": {
                    "format": "percent"
                }
            },
            "Confidence Label": {
                "select": {
                    "options": [
                        {"name": "STRONG", "color": "green"},
                        {"name": "MODERATE", "color": "yellow"},
                        {"name": "WEAK", "color": "orange"},
                        {"name": "WATCH", "color": "gray"}
                    ]
                }
            },
            "Setup Type": {
                "select": {
                    "options": [
                        {"name": "reversal", "color": "blue"},
                        {"name": "continuation", "color": "purple"},
                        {"name": "warning", "color": "yellow"},
                        {"name": "none", "color": "gray"}
                    ]
                }
            },
            "CS RSI State": {
                "select": {
                    "options": [
                        {"name": "bullish_reentry", "color": "green"},
                        {"name": "bearish_reentry", "color": "red"},
                        {"name": "bullish_detachment", "color": "green"},
                        {"name": "bearish_detachment", "color": "red"},
                        {"name": "bullish_hook", "color": "yellow"},
                        {"name": "bearish_hook", "color": "yellow"},
                        {"name": "neutral", "color": "gray"},
                        {"name": "oversold", "color": "green"},
                        {"name": "overextended_up", "color": "red"}
                    ]
                }
            },
            "CS RSI Red": {
                "number": {
                    "format": "number"
                }
            },
            "CS RSI Upper Blue": {
                "number": {
                    "format": "number"
                }
            },
            "CS RSI Lower Blue": {
                "number": {
                    "format": "number"
                }
            },
            "RtoM Bias": {
                "select": {
                    "options": [
                        {"name": "bullish", "color": "green"},
                        {"name": "bearish", "color": "red"},
                        {"name": "flat", "color": "gray"}
                    ]
                }
            },
            "RtoM Regime": {
                "select": {
                    "options": [
                        {"name": "compression", "color": "yellow"},
                        {"name": "expansion", "color": "blue"},
                        {"name": "stable", "color": "gray"}
                    ]
                }
            },
            "RtoM Position": {
                "select": {
                    "options": [
                        {"name": "outside_upper", "color": "red"},
                        {"name": "upper_half", "color": "orange"},
                        {"name": "mid_zone", "color": "yellow"},
                        {"name": "lower_half", "color": "green"},
                        {"name": "outside_lower", "color": "green"}
                    ]
                }
            },
            "200 SMA": {
                "number": {
                    "format": "dollar"
                }
            },
            "Compression": {
                "checkbox": {}
            },
            "Liquidity Sweep": {
                "select": {
                    "options": [
                        {"name": "bullish_sweep", "color": "green"},
                        {"name": "bearish_sweep", "color": "red"},
                        {"name": "none", "color": "gray"}
                    ]
                }
            },
            "Wick Rejection": {
                "select": {
                    "options": [
                        {"name": "bullish_rejection", "color": "green"},
                        {"name": "bearish_rejection", "color": "red"},
                        {"name": "none", "color": "gray"}
                    ]
                }
            },
            "Data Source": {
                "select": {
                    "options": [
                        {"name": "Binance", "color": "blue"},
                        {"name": "CoinGecko", "color": "green"},
                        {"name": "Kraken", "color": "purple"},
                        {"name": "CryptoCompare", "color": "orange"}
                    ]
                }
            },
            "Candles": {
                "number": {
                    "format": "number"
                }
            },
            "Analysis Notes": {
                "rich_text": {}
            }
        }
    }
    
    response = requests.post(url, headers=headers, json=data)
    
    if response.status_code == 200:
        db_id = response.json()['id']
        print(f"[OK] Created Crypto Intelligence Database: {db_id}")
        return db_id
    else:
        print(f"[FAIL] Error: {response.status_code}")
        print(response.text)
        return None

if __name__ == "__main__":
    print("=== Creating Crypto Intelligence Database ===\n")
    db_id = create_database()
    if db_id:
        print(f"\nDatabase ID: {db_id}")
        print(f"URL: https://notion.so/{db_id.replace('-', '')}")
