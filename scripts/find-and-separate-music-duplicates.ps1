# find-and-separate-music-duplicates.ps1
# Scans E:\2025 Music merge for duplicates and moves them to a separate folder

$SourcePath = "E:\2025 Music merge"
$DuplicatesPath = "E:\2025 Music merge\00-DUPLICATES-FOR-DELETION"
$LogFile = "$env:USERPROFILE\.openclaw\workspace\memory\music-duplicates-log.txt"

function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry
    Write-Host $logEntry -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARN") { "Yellow" } else { "White" })
}

Write-Log "=== Starting Music Duplicate Scan ==="
Write-Log "Source: $SourcePath"

# Create duplicates folder
if (!(Test-Path $DuplicatesPath)) {
    New-Item -ItemType Directory -Path $DuplicatesPath -Force | Out-Null
    Write-Log "Created duplicates folder: $DuplicatesPath"
}

# Get all music files
$MusicExtensions = @("*.mp3", "*.m4a", "*.flac", "*.wav", "*.aac", "*.ogg", "*.wma", "*.aiff")
$AllMusicFiles = @()

Write-Log "Scanning for music files..."
foreach ($ext in $MusicExtensions) {
    $files = Get-ChildItem -Path $SourcePath -Filter $ext -Recurse -ErrorAction SilentlyContinue
    $AllMusicFiles += $files
}

$TotalFiles = $AllMusicFiles.Count
Write-Log "Found $TotalFiles music files"

if ($TotalFiles -eq 0) {
    Write-Log "No music files found!"
    exit 0
}

# Find duplicates by hash
Write-Log "Computing file hashes to find duplicates..."
$FileHashes = @{}
$Duplicates = @()
$Processed = 0

foreach ($file in $AllMusicFiles) {
    $Processed++
    
    # Skip the duplicates folder itself
    if ($file.FullName -like "*$DuplicatesPath*") { continue }
    
    # Skip macOS resource fork files (._ files)
    if ($file.Name -match "^\._") {
        Write-Log "Found macOS resource fork: $($file.Name)" "WARN"
        $Duplicates += [PSCustomObject]@{
            File = $file
            Reason = "macOS resource fork"
            Original = $null
        }
        continue
    }
    
    try {
        $hash = (Get-FileHash -Path $file.FullName -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
        
        if ($hash) {
            if ($FileHashes.ContainsKey($hash)) {
                # This is a duplicate
                $original = $FileHashes[$hash]
                $Duplicates += [PSCustomObject]@{
                    File = $file
                    Reason = "Exact duplicate (hash match)"
                    Original = $original
                }
                Write-Log "DUPLICATE: $($file.Name) matches $($original.Name)"
            } else {
                $FileHashes[$hash] = $file
            }
        }
    } catch {
        Write-Log "ERROR hashing $($file.Name): $_" "ERROR"
    }
    
    if ($Processed % 100 -eq 0) {
        Write-Log "Progress: $Processed / $TotalFiles files scanned"
    }
}

Write-Log "Scan complete. Found $($Duplicates.Count) duplicates."

if ($Duplicates.Count -eq 0) {
    Write-Log "No duplicates found!"
    exit 0
}

# Move duplicates to separate folder
Write-Log ""
Write-Log "Moving duplicates to $DuplicatesPath..."

$MovedCount = 0
$ErrorCount = 0

foreach ($dup in $Duplicates) {
    $file = $dup.File
    $destFile = Join-Path $DuplicatesPath $file.Name
    
    # Handle name conflicts
    if (Test-Path $destFile) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $extension = [System.IO.Path]::GetExtension($file.Name)
        $counter = 1
        while (Test-Path $destFile) {
            $newName = "${baseName}_${counter}${extension}"
            $destFile = Join-Path $DuplicatesPath $newName
            $counter++
        }
    }
    
    try {
        Move-Item -Path $file.FullName -Destination $destFile -Force
        Write-Log "MOVED: $($file.Name) - $($dup.Reason)"
        $MovedCount++
    } catch {
        Write-Log "ERROR moving $($file.Name): $_" "ERROR"
        $ErrorCount++
    }
}

# Summary
Write-Log ""
Write-Log "=== DUPLICATE SEPARATION COMPLETE ==="
Write-Log "Total files scanned: $TotalFiles"
Write-Log "Duplicates found: $($Duplicates.Count)"
Write-Log "Successfully moved: $MovedCount"
Write-Log "Errors: $ErrorCount"
Write-Log ""
Write-Log "Duplicates folder: $DuplicatesPath"
Write-Log "Review and delete when ready"

# Group duplicates by reason
Write-Log ""
Write-Log "Breakdown by type:"
$Duplicates | Group-Object Reason | ForEach-Object {
    Write-Log "  $($_.Name): $($_.Count) files"
}
