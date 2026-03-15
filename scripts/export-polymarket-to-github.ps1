# Polymarket Data Exporter
# Exports scan results to JSON for GitHub/Hugging Face integration

param(
    [string]$OutputDir = "C:\Users\impro\.openclaw\workspace\data\polymarket"
)

# Ensure output directory exists
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Find latest scan file
$ScanDir = "C:\Users\impro\Documents\Polymarket-Scans"
$LatestFolder = Get-ChildItem -Path $ScanDir -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (!$LatestFolder) {
    Write-Error "No scan folders found"
    exit 1
}

$LatestFile = Get-ChildItem -Path $LatestFolder.FullName -Filter "hot-bets-*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (!$LatestFile) {
    Write-Error "No hot bets file found"
    exit 1
}

Write-Host "Processing: $($LatestFile.FullName)"

# Parse the file
$Content = Get-Content $LatestFile.FullName -Raw
$Lines = $Content -split "`r?`n" | Where-Object { $_.Trim() -ne "" }

# Extract metadata
$Timestamp = ""
$TotalCount = 0
if ($Lines[0] -match "HOT BETS - (\d{4}-\d{2}-\d{2}-\d{4})") {
    $Timestamp = $Matches[1]
}
if ($Lines[1] -match "Found (\d+) opportunities") {
    $TotalCount = [int]$Matches[1]
}

# Parse bets
$HotBets = @()
$CurrentBet = $null

for ($i = 2; $i -lt $Lines.Count; $i++) {
    $Line = $Lines[$i]
    
    # Category and name
    if ($Line -match '^\[([A-Z]+)\]\s+(.+)$') {
        if ($CurrentBet) {
            $HotBets += $CurrentBet
        }
        $CurrentBet = @{
            Category = $Matches[1]
            Name = $Matches[2] -replace '[^\x00-\x7F]', ''
            Odds = ""
            OddsNum = 0
            EdgeType = ""
            Outcome = ""
            Url = ""
        }
    }
    # Outcome line (new in v4)
    elseif ($Line -match '^Outcome:\s+(.+)$') {
        $CurrentBet.Outcome = $Matches[1]
    }
    # Odds line
    elseif ($Line -match 'Odds:\s+(\d+)%') {
        $OddsNum = [int]$Matches[1]
        $CurrentBet.Odds = "$OddsNum%"
        $CurrentBet.OddsNum = $OddsNum
        
        # Determine edge type
        if ($OddsNum -ge 40 -and $OddsNum -le 60) { $CurrentBet.EdgeType = "CLOSE_CALL" }
        elseif ($OddsNum -lt 40) { $CurrentBet.EdgeType = "UNDERDOG" }
        else { $CurrentBet.EdgeType = "FAVORITE" }
    }
    # Link line
    elseif ($Line -match '^Link:\s+(.+)$') {
        $CurrentBet.Url = $Matches[1]
    }
}

# Add last bet
if ($CurrentBet) {
    $HotBets += $CurrentBet
}

# Create output structure
$Output = @{
    timestamp = $Timestamp
    scan_time = [datetime]::Now.ToString("yyyy-MM-dd HH:mm:ss")
    total_opportunities = $TotalCount
    hot_bets = $HotBets
}

# Save to JSON
$OutputFile = "$OutputDir\polymarket_latest.json"
$Output | ConvertTo-Json -Depth 3 | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "Exported $($HotBets.Count) bets to $OutputFile"

# Also save dated copy
$DatedFile = "$OutputDir\polymarket_$Timestamp.json"
$Output | ConvertTo-Json -Depth 3 | Out-File -FilePath $DatedFile -Encoding UTF8

Write-Host "Also saved to $DatedFile"
