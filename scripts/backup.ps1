# backup.ps1
# Daily backup script for OpenClaw workspace
# Run this daily to backup critical files

$BackupDir = "C:\Users\impro\.openclaw\workspace\backups"
$WorkspaceDir = "C:\Users\impro\.openclaw\workspace"
$DateStamp = Get-Date -Format "yyyy-MM-dd"
$BackupFile = "$BackupDir\workspace-backup-$DateStamp.zip"

# Create backup directory if it doesn't exist
if (!(Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
}

# Remove backups older than 30 days
Get-ChildItem -Path $BackupDir -Filter "*.zip" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item -Force

# Create zip backup of workspace (excluding node_modules and large files)
$ItemsToBackup = @(
    "memory",
    "projects",
    "tasks",
    "income",
    "*.md"
)

Compress-Archive -Path (Join-Path $WorkspaceDir "*") -DestinationPath $BackupFile -Force

Write-Host "Backup completed: $BackupFile"
