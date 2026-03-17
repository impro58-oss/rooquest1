# Add Smart Money Detection to Notion Self-Improvement

$NOTION_KEY = Get-Content "C:\Users\impro\.config\notion\api_key" -Raw

$body = @'
{
  "parent": {"database_id": "32304917-58dd-81b8-a8a5-000b04a0c287"},
  "properties": {
    "Name": {"title": [{"text": {"content": "Smart Money Detection System"}}]},
    "Category": {"select": {"name": "Performance Optimization"}},
    "Status": {"select": {"name": "Approved"}},
    "Priority": {"select": {"name": "High"}},
    "Date Proposed": {"date": {"start": "2026-03-15"}},
    "Date Approved": {"date": {"start": "2026-03-15"}},
    "Description": {"rich_text": [{"text": {"content": "Tracks odds movements to detect whale activity. Compares current vs previous scan, alerts on >5% movement toward 50% (uncertainty). Integrated into dashboard and Telegram alerts."}}]},
    "Expected Impact": {"select": {"name": "High"}},
    "Roo Approval": {"checkbox": true}
  }
}
'@

$response = Invoke-RestMethod -Uri "https://api.notion.com/v1/pages" -Method POST -Headers @{
  "Authorization" = "Bearer $NOTION_KEY"
  "Notion-Version" = "2025-09-03"
  "Content-Type" = "application/json"
} -Body $body

Write-Host "Created Self-Improvement entry: $($response.id)"
