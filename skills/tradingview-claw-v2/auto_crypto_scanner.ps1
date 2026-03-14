# Automated crypto scanner with logging
param(
    [string]$WorkingDir = "C:\Users\impro\.openclaw\workspace\skills\tradingview-claw-v2",
    [string]$PythonPath = "C:\Users\impro\AppData\Local\Programs\Python\Python311\python.exe",
    [switch]$SendToTelegram = $false,
    [string]$TelegramBotToken = "",
    [string]$TelegramChatId = ""
)

# Set working directory
Set-Location $WorkingDir

# Log file
$LogFile = "$WorkingDir\logs\auto_scan_$(Get-Date -Format 'yyyyMMdd').log"
New-Item -ItemType Directory -Force -Path "$WorkingDir\logs" | Out-Null

function Write-Log {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Tee-Object -FilePath $LogFile -Append
}

Write-Log "=== Starting Auto Crypto Scan ==="

# Step 1: Run analysis
Write-Log "Running top 50 analysis..."
try {
    $AnalysisOutput = & $PythonPath analyze_top_50.py 2>&1
    $AnalysisOutput | ForEach-Object { Write-Log $_ }
    
    # Find the generated file
    $LatestFile = Get-ChildItem -Path $WorkingDir -Filter "top_50_analysis_*.json" | 
                  Sort-Object LastWriteTime -Descending | 
                  Select-Object -First 1
    
    if ($LatestFile) {
        Write-Log "Analysis complete: $($LatestFile.Name)"
        
        # Step 2: Log to Notion
        Write-Log "Logging to Notion..."
        $LogOutput = & $PythonPath log_to_intelligence.py $LatestFile.FullName 2>&1
        $LogOutput | ForEach-Object { Write-Log $_ }
        
        # Step 3: Generate trend report
        Write-Log "Generating trend report..."
        $TrendOutput = & $PythonPath analyze_trends.py 2>&1
        $TrendOutput | ForEach-Object { Write-Log $_ }
        
        # Step 4: Commit to GitHub
        Write-Log "Committing data to GitHub..."
        try {
            $CommitOutput = & "C:\Users\impro\.openclaw\workspace\scripts\auto-commit-crypto-data.ps1" -WorkingDir "C:\Users\impro\.openclaw\workspace" 2>&1
            $CommitOutput | ForEach-Object { Write-Log $_ }
        } catch {
            Write-Log "[WARN] Git commit error: $_"
        }
        
        # Step 5: Send to Telegram if enabled
        if ($SendToTelegram -and $TelegramBotToken -and $TelegramChatId) {
            Write-Log "Sending to Telegram..."
            
            # Parse results for summary
            $Results = Get-Content $LatestFile.FullName | ConvertFrom-Json
            $Opportunities = $Results.results | Where-Object { 
                $_.signal -in @('long', 'short') -and $_.confidence -ge 0.45 
            }
            
            $Message = "Crypto Scan Results`n`n"
            $Message += "$(Get-Date -Format 'yyyy-MM-dd HH:mm UTC')`n`n"
            
            if ($Opportunities) {
                $Message += "$($Opportunities.Count) OPPORTUNITIES:`n"
                foreach ($Opp in ($Opportunities | Sort-Object confidence -Descending)) {
                    $Emoji = if ($Opp.signal -eq 'long') { "LONG" } else { "SHORT" }
                    $Message += "$Emoji $($Opp.symbol): $($Opp.signal.ToUpper()) @ $([math]::Round($Opp.confidence * 100))%`n"
                    $Message += "   Price: $($Opp.price)`n"
                }
            } else {
                $Message += "No high-confidence opportunities.`n"
                $Message += "Market is in a holding pattern.`n"
            }
            
            $Message += "`nFull dashboard: https://notion.so/3230491758dd81d8a31efe277bf4b0d1"
            
            # Send Telegram message
            $TelegramUrl = "https://api.telegram.org/bot$TelegramBotToken/sendMessage"
            $Body = @{
                chat_id = $TelegramChatId
                text = $Message
                parse_mode = "HTML"
            } | ConvertTo-Json
            
            Invoke-RestMethod -Uri $TelegramUrl -Method Post -ContentType "application/json" -Body $Body | Out-Null
            Write-Log "Telegram notification sent"
        }
        
        Write-Log "=== Auto scan complete ==="
    } else {
        Write-Log "ERROR: No analysis file generated"
    }
} catch {
    Write-Log "ERROR: $_"
}

Write-Log ""
