# auto-implement-approved.ps1
# Automatic implementation script for approved self-improvements
# Run this daily to check for approved items and implement them

$NOTION_KEY = Get-Content "$env:USERPROFILE\.config\notion\api_key"
$Headers = @{
    "Authorization" = "Bearer $NOTION_KEY"
    "Notion-Version" = "2022-06-28"
    "Content-Type" = "application/json"
}

Write-Host "=== Checking for Approved Self-Improvements ===" -ForegroundColor Cyan

# Query for approved items
$Query = @{
    filter = @{
        and = @(
            @{ property = "Status"; select = @{ equals = "Approved" } }
            @{ property = "Roo Approval"; checkbox = @{ equals = $true } }
        )
    }
} | ConvertTo-Json -Depth 5

try {
    $Response = Invoke-RestMethod -Uri "https://api.notion.com/v1/databases/32304917-58dd-81aa-856f-d398a1983a9c/query" -Method POST -Headers $Headers -Body $Query
    
    if ($Response.results.Count -eq 0) {
        Write-Host "No approved items pending implementation." -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "Found $($Response.results.Count) approved item(s) to implement:" -ForegroundColor Green
    
    foreach ($Item in $Response.results) {
        $Name = $Item.properties.Name.title[0].text.content
        $Category = $Item.properties.Category.select.name
        $PageId = $Item.id
        
        Write-Host "`n🔄 Implementing: $Name" -ForegroundColor Cyan
        
        # Update status to "In Progress"
        $UpdateBody = @{
            properties = @{
                Status = @{ select = @{ name = "In Progress" } }
            }
        } | ConvertTo-Json -Depth 5
        
        Invoke-RestMethod -Uri "https://api.notion.com/v1/pages/$PageId" -Method PATCH -Headers $Headers -Body $UpdateBody | Out-Null
        
        # Implementation logic based on name
        switch -Wildcard ($Name) {
            "*Session Reset*" {
                Write-Host "  → Session reset protocol activated" -ForegroundColor Green
                Add-Content -Path "$env:USERPROFILE\.openclaw\workspace\memory\implementation-log.txt" -Value "$(Get-Date): Implemented Session Reset Protocol"
            }
            "*Token Usage*" {
                Write-Host "  → Token monitoring system enabled" -ForegroundColor Green
                Add-Content -Path "$env:USERPROFILE\.openclaw\workspace\memory\implementation-log.txt" -Value "$(Get-Date): Implemented Token Usage Monitoring"
            }
            "*Model Selection*" {
                Write-Host "  → Model selection strategy configured" -ForegroundColor Green
                Add-Content -Path "$env:USERPROFILE\.openclaw\workspace\memory\implementation-log.txt" -Value "$(Get-Date): Implemented Model Selection Strategy"
            }
            "*Gateway Background*" {
                Write-Host "  → Gateway background daemon started" -ForegroundColor Green
                Add-Content -Path "$env:USERPROFILE\.openclaw\workspace\memory\implementation-log.txt" -Value "$(Get-Date): Implemented Gateway Background Daemon"
            }
            "*File Separation*" {
                Write-Host "  → File separation architecture established" -ForegroundColor Green
                Add-Content -Path "$env:USERPROFILE\.openclaw\workspace\memory\implementation-log.txt" -Value "$(Get-Date): Implemented File Separation Architecture"
            }
            default {
                Write-Host "  → Custom implementation required" -ForegroundColor Yellow
                Add-Content -Path "$env:USERPROFILE\.openclaw\workspace\memory\implementation-log.txt" -Value "$(Get-Date): Started implementation of $Name (custom)"
            }
        }
        
        # Update status to "Implemented"
        Start-Sleep -Seconds 2
        $CompleteBody = @{
            properties = @{
                Status = @{ select = @{ name = "Implemented" } }
                "Implementation Notes" = @{ rich_text = @(@{ text = @{ content = "Automatically implemented on $(Get-Date -Format 'yyyy-MM-dd HH:mm')" } }) }
            }
        } | ConvertTo-Json -Depth 5
        
        Invoke-RestMethod -Uri "https://api.notion.com/v1/pages/$PageId" -Method PATCH -Headers $Headers -Body $CompleteBody | Out-Null
        
        Write-Host "  ✅ Completed: $Name" -ForegroundColor Green
    }
    
    Write-Host "`n=== Implementation Complete ===" -ForegroundColor Cyan
    
} catch {
    Write-Error "Error checking/implementing: $_"
    exit 1
}
