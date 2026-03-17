# Web Research Skill

Automated web scraping and research for opportunities, news, and market data.

## Commands

```bash
# Research specific topic
web-research query "AI income opportunities 2026"

# Monitor website for changes
web-research monitor https://example.com/jobs --interval 1h

# Scrape job boards
web-research jobs --source indeed --query "remote AI"

# Research competitors
web-research competitors --domain example.com

# Extract data from page
web-research extract https://example.com/data --format table
```

## Features

- **Job Board Scraping:** Indeed, LinkedIn, AngelList, etc.
- **News Aggregation:** Tech news, crypto updates, market signals
- **Competitor Analysis:** Pricing, features, positioning
- **Change Detection:** Monitor pages for updates
- **Data Extraction:** Tables, lists, structured data
- **Notion Export:** Save research directly to databases

## Configuration

Config file: `~/.openclaw/skills/web-research/config.json`

```json
{
  "sources": {
    "jobs": ["indeed", "linkedin", "angel"],
    "news": ["techcrunch", "hackernews", "reddit"],
    "crypto": ["coindesk", "cointelegraph"]
  },
  "rateLimit": {
    "requestsPerMinute": 10
  },
  "output": {
    "format": "markdown",
    "saveToNotion": true
  }
}
```

## Output

```
Research Report: AI Income Opportunities
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sources: 5 job boards, 3 news sites
Results: 12 opportunities found

1. AI Content Creator - $50-100/hr (Upwork)
2. ML Model Trainer - $75-150/hr (Turing)
3. Chatbot Developer - $60-120/hr (AngelList)
...

Saved to Notion: 💰 Income Opportunities
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```