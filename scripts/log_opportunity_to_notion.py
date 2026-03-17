# Log Opportunity Scout findings to Notion database
# Usage: python log_opportunity_to_notion.py <opportunity_json_file>

import json
import requests
import sys
from datetime import datetime

NOTION_TOKEN = "ntn_R12262668454JRCXah04DVY4uPiw6HW9G1Z69TdAXJibKD"
DATABASE_ID = "32404917-58dd-816a-83a4-d020d6be7e6d"  # Opportunities database

headers = {
    "Authorization": f"Bearer {NOTION_TOKEN}",
    "Content-Type": "application/json",
    "Notion-Version": "2022-06-28"
}

def log_opportunity(opportunity):
    """Log a single opportunity to Notion."""
    
    url = "https://api.notion.com/v1/pages"
    
    # Build properties
    properties = {
        "Opportunity Name": {
            "title": [{"text": {"content": opportunity.get('name', 'Unnamed Opportunity')}}]
        },
        "Type": {
            "select": {"name": opportunity.get('type', 'Other')}
        },
        "Status": {
            "select": {"name": "Researching"}
        },
        "Verdict": {
            "select": {"name": opportunity.get('verdict', 'WATCH')}
        },
        "Confidence": {
            "select": {"name": opportunity.get('confidence', 'Medium')}
        },
        "Effort (Hours)": {
            "number": opportunity.get('effort_hours', 0)
        },
        "Capital Required": {
            "number": opportunity.get('capital_required', 0)
        },
        "Time to First $": {
            "rich_text": [{"text": {"content": opportunity.get('time_to_revenue', 'Unknown')}}]
        },
        "Monthly Revenue Potential": {
            "number": opportunity.get('monthly_revenue_potential', 0)
        },
        "Viability Score": {
            "number": opportunity.get('viability_score', 0)
        },
        "Date Discovered": {
            "date": {"start": datetime.now().strftime('%Y-%m-%d')}
        },
        "Priority": {
            "select": {"name": opportunity.get('priority', 'Backlog')}
        },
        "Unfair Advantage": {
            "rich_text": [{"text": {"content": opportunity.get('unfair_advantage', '')[:2000]}}]
        },
        "Target Market": {
            "rich_text": [{"text": {"content": opportunity.get('target_market', '')[:2000]}}]
        },
        "Competition Level": {
            "select": {"name": opportunity.get('competition', 'Medium')}
        },
        "Next Action": {
            "rich_text": [{"text": {"content": opportunity.get('next_action', '')[:2000]}}]
        },
        "Research Source": {
            "url": opportunity.get('source_url', None) if opportunity.get('source_url') else None
        },
        "Full Analysis": {
            "rich_text": [{"text": {"content": opportunity.get('full_analysis', '')[:2000]}}]
        }
    }
    
    # Remove None values
    properties = {k: v for k, v in properties.items() if v is not None}
    
    data = {
        "parent": {"database_id": DATABASE_ID},
        "properties": properties
    }
    
    response = requests.post(url, headers=headers, json=data)
    
    if response.status_code == 200:
        result = response.json()
        print(f"Logged to Notion: {opportunity.get('name', 'Unnamed')}")
        print(f"  Page ID: {result['id']}")
        return True
    else:
        print(f"Error logging to Notion: {response.status_code}")
        print(f"  Response: {response.text}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage: python log_opportunity_to_notion.py <opportunity_json_file>")
        print("Or: python log_opportunity_to_notion.py (reads from stdin)")
        return
    
    json_file = sys.argv[1]
    
    try:
        with open(json_file, 'r') as f:
            data = json.load(f)
        
        # Handle single opportunity or list
        if isinstance(data, list):
            opportunities = data
        else:
            opportunities = [data]
        
        success_count = 0
        for opp in opportunities:
            if log_opportunity(opp):
                success_count += 1
        
        print(f"\nLogged {success_count}/{len(opportunities)} opportunities to Notion")
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
