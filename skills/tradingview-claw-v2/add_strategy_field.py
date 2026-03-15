"""
add_strategy_field.py — Add Strategy field to existing Crypto Intelligence Database
"""
import requests

NOTION_TOKEN = "ntn_R12262668454JRCXah04DVY4uPiw6HW9G1Z69TdAXJibKD"
DATABASE_ID = "32304917-58dd-81d8-a31e-fe277bf4b0d1"

headers = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28"
}

def add_strategy_property():
    """Add Strategy property to database."""
    
    url = f"https://api.notion.com/v1/databases/{DATABASE_ID}"
    
    data = {
        "properties": {
            "Strategy": {
                "select": {
                    "options": [
                        {"name": "FUTURES", "color": "red"},
                        {"name": "HOLD", "color": "green"},
                        {"name": "MONITOR", "color": "gray"}
                    ]
                }
            }
        }
    }
    
    response = requests.patch(url, headers=headers, json=data)
    
    if response.status_code == 200:
        print("[OK] Added Strategy property to database")
        return True
    else:
        print(f"[FAIL] Error: {response.status_code}")
        print(response.text)
        return False

if __name__ == "__main__":
    add_strategy_property()
