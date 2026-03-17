# Daily cleanup of old Polymarket scan files
# Run at end of day to remove old files, keep last 7 days

param(
    [int]$KeepDays = 7,
    [string]$BasePath = "C:\Users\impro\Documents\Polymarket-Scans"
)

$CutoffDate = (Get-Date).AddDays(-$KeepDays)
Write-Host "Cleaning up Polymarket scans older than $CutoffDate..."

$DeletedCount = 0
$DeletedSize = 0

# Get all date folders
$DateFolders = Get-ChildItem -Path $BasePath -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}$' }

foreach ($Folder in $DateFolders) {
    try {
        $FolderDate = [datetime]::ParseExact($Folder.Name, 'yyyy-MM-dd', $null)
        
        if ($FolderDate -lt $CutoffDate) {
            $Size = (Get-ChildItem $Folder.FullName -Recurse | Measure-Object -Property Length -Sum).Sum
            Remove-Item -Path $Folder.FullName -Recurse -Force
            $DeletedCount++
            $DeletedSize += $Size
            Write-Host "  Deleted: $($Folder.Name) ($([math]::Round($Size/1MB, 2)) MB)"
        }
    } catch {
        Write-Host "  Skipped: $($Folder.Name) (invalid date format)"
    }
}

# Also clean old scan-log.txt entries
$LogFile = "$BasePath\scan-log.txt"
if (Test-Path $LogFile) {
    $Lines = Get-Content $LogFile | Where-Object { 
        $_ -match '^(\d{4}-\d{2}-\d{2})' 
        $lineDate = [datetime]::ParseExact($matches[1], 'yyyy-MM-dd', $null)
        $lineDate -ge $CutoffDate
    }
    $Lines | Out-File -FilePath $LogFile -Encoding UTF8
    Write-Host "  Cleaned scan-log.txt"
}

Write-Host ""
Write-Host "Cleanup complete:"
Write-Host "  Folders deleted: $DeletedCount"
Write-Host "  Space freed: $([math]::Round($DeletedSize/1MB, 2)) MB"
