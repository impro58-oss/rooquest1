# Create Notion database for Opportunity Scout
# Run this to set up the opportunities tracking database

import requests
import json

NOTION_TOKEN = "ntn_R12262668454JRCXah04DVY4uPiw6HW9G1Z69TdAXJibKD"
PAGE_ID = "3230491758dd80a08614d4808e0af030"  # Roo Control Room

headers = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28"
}

def create_opportunities_database():
    """Create a database for tracking business opportunities."""
    
    url = "https://api.notion.com/v1/databases"
    
    data = {
        "parent": {"page_id": PAGE_ID},
        "title": [{"type": "text", "text": {"content": "💡 Opportunities & Ideas"}}],
        "properties": {
            "Opportunity Name": {
                "title": {}
            },
            "Type": {
                "select": {
                    "options": [
                        {"name": "Micro-SaaS", "color": "blue"},
                        {"name": "Digital Product", "color": "green"},
                        {"name": "Service Arbitrage", "color": "yellow"},
                        {"name": "Info Product", "color": "purple"},
                        {"name": "Newsletter", "color": "orange"},
                        {"name": "Community", "color": "pink"},
                        {"name": "Other", "color": "gray"}
                    ]
                }
            },
            "Status": {
                "select": {
                    "options": [
                        {"name": "Researching", "color": "gray"},
                        {"name": "Evaluating", "color": "yellow"},
                        {"name": "Pursuing", "color": "blue"},
                        {"name": "Building", "color": "orange"},
                        {"name": "Launched", "color": "green"},
                        {"name": "Paused", "color": "brown"},
                        {"name": "Abandoned", "color": "red"}
                    ]
                }
            },
            "Verdict": {
                "select": {
                    "options": [
                        {"name": "PURSUE", "color": "green"},
                        {"name": "WATCH", "color": "yellow"},
                        {"name": "PASS", "color": "red"}
                    ]
                }
            },
            "Confidence": {
                "select": {
                    "options": [
                        {"name": "High", "color": "green"},
                        {"name": "Medium", "color": "yellow"},
                        {"name": "Low", "color": "red"}
                    ]
                }
            },
            "Effort (Hours)": {
                "number": {}
            },
            "Capital Required": {
                "number": {
                    "format": "dollar"
                }
            },
            "Time to First $": {
                "rich_text": {}
            },
            "Monthly Revenue Potential": {
                "number": {
                    "format": "dollar"
                }
            },
            "Viability Score": {
                "number": {}
            },
            "Date Discovered": {
                "date": {}
            },
            "Priority": {
                "select": {
                    "options": [
                        {"name": "This Week", "color": "red"},
                        {"name": "This Month", "color": "orange"},
                        {"name": "This Quarter", "color": "yellow"},
                        {"name": "Backlog", "color": "gray"}
                    ]
                }
            },
            "Unfair Advantage": {
                "rich_text": {}
            },
            "Target Market": {
                "rich_text": {}
            },
            "Competition Level": {
                "select": {
                    "options": [
                        {"name": "Low", "color": "green"},
                        {"name": "Medium", "color": "yellow"},
                        {"name": "High", "color": "red"}
                    ]
                }
            },
            "Next Action": {
                "rich_text": {}
            },
            "Research Source": {
                "url": {}
            },
            "Full Analysis": {
                "rich_text": {}
            }
        }
    }
    
    response = requests.post(url, headers=headers, json=data)
    
    if response.status_code == 200:
        result = response.json()
        print(f"Database created successfully!")
        print(f"   Database ID: {result['id']}")
        print(f"   URL: {result['url']}")
        return result['id']
    else:
        print(f"Error creating database: {response.status_code}")
        print(f"   Response: {response.text}")
        return None

if __name__ == "__main__":
    db_id = create_opportunities_database()
    if db_id:
        print(f"\nAdd this to your config:")
        print(f"   OPPORTUNITIES_DATABASE_ID = \"{db_id}\"")
