# setup-polymarket-cron.ps1
# Creates hourly cron job for Polymarket scanning

Write-Host "Setting up hourly Polymarket monitoring..."

# Create the cron command file
$CronScript = @"
# Polymarket Hourly Scan
# Runs every hour, sends Telegram alert if hot bets found

cd "C:\Users\impro\.openclaw\workspace\scripts"

# Run scanner and capture output
`$HotBets = .\polymarket-hourly-scanner.ps1

# If hot bets found, send Telegram alert
if (`$HotBets) {
    `$LatestAlert = Get-ChildItem "C:\Users\impro\Documents\Polymarket-Scans\$(Get-Date -Format 'yyyy-MM-dd')\hot-bets-*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (`$LatestAlert) {
        .\polymarket-alert-telegram.ps1 -AlertFile `$LatestAlert.FullName
    }
}

# Update Notion with new opportunities
.\update-notion-next-bets.ps1
"@

$CronScript | Out-File -FilePath "$env:USERPROFILE\.openclaw\workspace\scripts\polymarket-cron-runner.ps1" -Encoding utf8

Write-Host "Created cron runner script"

# Create Notion updater script
$NotionUpdater = @'
# update-notion-next-bets.ps1
# Updates Notion Next Bets database with latest scan results

$NOTION_KEY = Get-Content "$env:USERPROFILE\.config\notion\api_key" -ErrorAction SilentlyContinue
if (!$NOTION_KEY) { exit }

$Headers = @{
    "Authorization" = "Bearer $NOTION_KEY"
    "Notion-Version" = "2022-06-28"
    "Content-Type" = "application/json"
}

# Get latest hot bets file
$Today = Get-Date -Format "yyyy-MM-dd"
$HotBetsFile = Get-ChildItem "C:\Users\impro\Documents\Polymarket-Scans\$Today\hot-bets-*.txt" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (!$HotBetsFile) { exit }

# Parse hot bets and add to Notion
$Content = Get-Content $HotBetsFile.FullName

foreach ($Line in $Content) {
    if ($Line -match "\[(.+?)\] Odds: (\d+%) \| Volume: (.+)") {
        $Category = $Matches[1]
        $Odds = $Matches[2]
        $Volume = $Matches[3]
        
        # Check if already exists
        $QueryBody = @{
            filter = @{
                property = "Volume"
                rich_text = @{ equals = $Volume }
            }
        } | ConvertTo-Json
        
        try {
            $Existing = Invoke-RestMethod -Uri "https://api.notion.com/v1/databases/32304917-58dd-81f2-ad8a-c8254af3d9a9/query" -Method POST -Headers $Headers -Body $QueryBody
            
            if ($Existing.results.Count -eq 0) {
                # Add new bet
                $AddBody = @{
                    parent = @{ database_id = "32304917-58dd-81f2-ad8a-c8254af3d9a9" }
                    properties = @{
                        Name = @{ title = @(@{ text = @{ content = "Auto-detected $Category Opportunity" } }) }
                        Market = @{ url = "https://polymarket.com/predictions/$Category" }
                        "Current Odds" = @{ number = ([int]($Odds -replace '%','')) / 100 }
                        Volume = @{ rich_text = @(@{ text = @{ content = $Volume } }) }
                        Category = @{ select = @{ name = $Category.Substring(0,1).ToUpper() + $Category.Substring(1).ToLower() } }
                        Priority = @{ select = @{ name = "High" } }
                        Status = @{ select = @{ name = "Pending" } }
                        "Date Added" = @{ date = @{ start = (Get-Date -Format "yyyy-MM-dd") } }
                        "Recommended Position" = @{ select = @{ name = "WATCH" } }
                    }
                } | ConvertTo-Json -Depth 10
                
                Invoke-RestMethod -Uri "https://api.notion.com/v1/pages" -Method POST -Headers $Headers -Body $AddBody | Out-Null
            }
        } catch {}
    }
}
'@

$NotionUpdater | Out-File -FilePath "$env:USERPROFILE\.openclaw\workspace\scripts\update-notion-next-bets.ps1" -Encoding utf8

Write-Host "Created Notion updater script"

# Instructions for manual cron setup
Write-Host @"

=== SETUP COMPLETE ===

To activate hourly monitoring, add this to your OpenClaw cron:

Command: powershell -ExecutionPolicy Bypass -File C:\Users\impro\.openclaw\workspace\scripts\polymarket-cron-runner.ps1
Schedule: 0 * * * * (every hour)
Timezone: Europe/Dublin

Or run manually:
  openclaw cron add --name "polymarket-hourly" --cron "0 * * * *" --tz "Europe/Dublin"

=== WHAT HAPPENS EVERY HOUR ===
1. Scans all 6 Polymarket categories
2. Saves links to Documents/Polymarket-Scans/
3. Identifies hot bets (high volume + uncertain odds)
4. Sends Telegram alert if hot bets found
5. Updates Notion Next Bets database

=== FILES CREATED ===
- scripts/polymarket-cron-runner.ps1 (main cron script)
- scripts/update-notion-next-bets.ps1 (Notion updater)
- Documents/Polymarket-Scans/ (output folder)

"@
