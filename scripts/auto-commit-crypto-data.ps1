# Auto-commit crypto data to GitHub after scan
param(
    [string]$WorkingDir = "C:\Users\impro\.openclaw\workspace",
    [string]$CommitMessage = ""
)

Set-Location $WorkingDir

# Check if there are changes
$Status = git status --porcelain 2>$null

if ($Status) {
    Write-Host "[GIT] Changes detected, committing..."
    
    # Add data files
    git add data/crypto/*.json
    git add data/crypto/*/*.json
    
    # Create commit message
    if (-not $CommitMessage) {
        $CommitMessage = "Crypto scan data update $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    }
    
    # Commit and push
    git commit -m $CommitMessage
    git push
    
    Write-Host "[OK] Data committed to GitHub"
    Write-Host "[INFO] Hugging Face can now access: https://raw.githubusercontent.com/impro58-oss/rooquest1/main/data/crypto/crypto_latest.json"
} else {
    Write-Host "[INFO] No changes to commit"
}
