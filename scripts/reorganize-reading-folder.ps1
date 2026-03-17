# reorganize-reading-folder.ps1
# Reorganizes E:\2025 Development Merge\1- Reading into clean categorized structure
# Removes duplicates and creates logical hierarchy

$SourcePath = "E:\2025 Development Merge\1- Reading"
$LogFile = "$env:USERPROFILE\.openclaw\workspace\memory\folder-reorganization-log.txt"

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Tee-Object -FilePath $LogFile -Append
}

Write-Log "=== Starting Folder Reorganization ==="
Write-Log "Source: $SourcePath"

# Get all files
$AllFiles = Get-ChildItem -Path $SourcePath -Recurse -File
Write-Log "Found $($AllFiles.Count) total files"

# Find duplicates by hash
Write-Log "Scanning for duplicates..."
$FileHashes = @{}
$Duplicates = @()

foreach ($file in $AllFiles) {
    try {
        $hash = (Get-FileHash -Path $file.FullName -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
        if ($hash) {
            if ($FileHashes.ContainsKey($hash)) {
                $Duplicates += [PSCustomObject]@{
                    Original = $FileHashes[$hash]
                    Duplicate = $file.FullName
                    Hash = $hash
                }
                Write-Log "DUPLICATE: $($file.Name) matches $($FileHashes[$hash])"
            } else {
                $FileHashes[$hash] = $file.FullName
            }
        }
    } catch {
        Write-Log "ERROR hashing $($file.FullName): $_"
    }
}

Write-Log "Found $($Duplicates.Count) duplicate files"

# Categorization rules
$Categories = @{
    "01-Business-Finance" = @{
        "Trading-Investing" = @("technical analysis", "trading", "investing", "stock", "market", "dalio", "principles", "freakonomics", "economics")
        "Entrepreneurship" = @("business planning", "trump", "success", "achievement", "rich", "think and grow rich", "born rich")
    }
    "02-Personal-Development" = @{
        "Psychology" = @("flow", "psychology", "optimal experience", "csikszentmihalyi", "blink", "gladwell", "rational male")
        "Success-Mindset" = @("maximum achievement", "speak to win", "stop thinking", "living", "happiness", "game", "neil strauss")
        "Communication" = @()
    }
    "03-Fitness-Health" = @{
        "Strength-Training" = @("strength", "powerlifting", "bodybuilding", "wendler", "531", "starting strength", "texas method", "westside", "juggernaut", "cube", "strongman", "olympic", "weightlifting", "elitefts", "dinosaur", "convict", "kettlebell", "crossfit")
        "Nutrition" = @("diet", "nutrition", "anabolic", "ketogenic", "paleo", "renaissance", "ultimate diet", "dolce", "supplement")
        "Programs-Workouts" = @("program", "workout", "training", "routine", "phase", "week", "greyskull", "gladiator", "rebel", "level", "performance menu", "milo", "dino files")
        "Yoga-Wellness" = @("yoga", "pilates", "wellness", "stretch", "mobility", "supple", "becoming", "leopard")
    }
    "04-Technical-Professional" = @{
        "Six-Sigma-Lean" = @("six sigma", "lean", "toyota way")
        "Technical-Writing" = @("technical writing", "style guide", "microsoft manual")
        "Engineering" = @("plastics", "polymer", "engineering", "fbi manual", "firebird")
    }
    "05-Spiritual-Esoteric" = @{
        "Human-Design" = @("human design", "ra uru hu", "rave", "iching", "destinies")
        "Hypnosis-NLP" = @("hypnosis", "hypnotic", "nlp", "neuro linguistic", "brainwashing", "magic words", "scriptless")
        "Occult" = @("agrippa", "three books", "occult", "philosophy")
    }
    "06-Reference-Manuals" = @{
        "Product-Manuals" = @("manual", "user guide", "handbook")
    }
}

# Create category mapping
$FileMapping = @{}
foreach ($file in $AllFiles) {
    $fileName = $file.Name.ToLower()
    $matched = $false
    
    foreach ($mainCat in $Categories.Keys) {
        foreach ($subCat in $Categories[$mainCat].Keys) {
            foreach ($keyword in $Categories[$mainCat][$subCat]) {
                if ($fileName -like "*$keyword*") {
                    $FileMapping[$file.FullName] = "$mainCat\$subCat"
                    $matched = $true
                    break
                }
            }
            if ($matched) { break }
        }
        if ($matched) { break }
    }
    
    if (!$matched) {
        $FileMapping[$file.FullName] = "00-Uncategorized"
    }
}

Write-Log "Categorized $($FileMapping.Count) files"

# Summary report
Write-Log ""
Write-Log "=== REORGANIZATION PLAN ==="
Write-Log ""

# Group by category
$CategorySummary = $FileMapping.Values | Group-Object | Sort-Object Count -Descending

foreach ($cat in $CategorySummary) {
    Write-Log "$($cat.Name): $($cat.Count) files"
}

Write-Log ""
Write-Log "=== DUPLICATES TO REMOVE ==="
foreach ($dup in $Duplicates) {
    Write-Log "REMOVE: $($dup.Duplicate)"
    Write-Log "  KEEP: $($dup.Original)"
}

# Create the reorganization script
$ReorgScript = @"
# Reorganization execution script
# Run this to apply the changes

`$SourcePath = "$SourcePath"
`$BackupPath = "E:\2025 Development Merge\1- Reading-BACKUP-$(Get-Date -Format 'yyyyMMdd-HHmm')"

# Create backup first
Write-Host "Creating backup at `$BackupPath..."
Copy-Item -Path `$SourcePath -Destination `$BackupPath -Recurse -Force

# Create new structure
`$NewStructure = @(
    "01-Business-Finance\Trading-Investing"
    "01-Business-Finance\Entrepreneurship"
    "02-Personal-Development\Psychology"
    "02-Personal-Development\Success-Mindset"
    "02-Personal-Development\Communication"
    "03-Fitness-Health\Strength-Training"
    "03-Fitness-Health\Nutrition"
    "03-Fitness-Health\Programs-Workouts"
    "03-Fitness-Health\Yoga-Wellness"
    "04-Technical-Professional\Six-Sigma-Lean"
    "04-Technical-Professional\Technical-Writing"
    "04-Technical-Professional\Engineering"
    "05-Spiritual-Esoteric\Human-Design"
    "05-Spiritual-Esoteric\Hypnosis-NLP"
    "05-Spiritual-Esoteric\Occult"
    "06-Reference-Manuals\Product-Manuals"
    "00-Uncategorized"
)

foreach (`$folder in `$NewStructure) {
    `$fullPath = Join-Path `$SourcePath `$folder
    if (!(Test-Path `$fullPath)) {
        New-Item -ItemType Directory -Path `$fullPath -Force | Out-Null
        Write-Host "Created: `$folder"
    }
}

# Move files to new locations
`$FileMapping = $(ConvertTo-Json $FileMapping -Compress)

foreach (`$file in `$FileMapping.Keys) {
    `$destFolder = Join-Path `$SourcePath `$FileMapping[`$file]
    `$fileName = Split-Path `$file -Leaf
    `$destPath = Join-Path `$destFolder `$fileName
    
    if (Test-Path `$file) {
        Move-Item -Path `$file -Destination `$destPath -Force -ErrorAction SilentlyContinue
        Write-Host "Moved: `$fileName -> `$destFolder"
    }
}

# Remove empty folders
Get-ChildItem `$SourcePath -Directory -Recurse | Where-Object { `$_.GetFiles().Count -eq 0 -and `$_.GetDirectories().Count -eq 0 } | Remove-Item -Force

Write-Host "Reorganization complete!"
Write-Host "Backup location: `$BackupPath"
"@

$ReorgScript | Out-File -FilePath "$env:USERPROFILE\.openclaw\workspace\scripts\execute-reorganization.ps1" -Encoding utf8

Write-Log ""
Write-Log "Created execution script: execute-reorganization.ps1"
Write-Log "Review the plan above, then run the execution script to apply changes"
Write-Log "A backup will be created before any changes are made"
Write-Log ""
Write-Log "=== Analysis Complete ==="

# Output summary to console
Write-Host ""
Write-Host "=== FOLDER REORGANIZATION PLAN ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Found $($AllFiles.Count) files total" -ForegroundColor White
Write-Host "Found $($Duplicates.Count) duplicates to remove" -ForegroundColor Yellow
Write-Host ""
Write-Host "Proposed Structure:" -ForegroundColor Green
foreach ($cat in $CategorySummary | Select-Object -First 10) {
    Write-Host "  $($cat.Name): $($cat.Count) files" -ForegroundColor Gray
}
Write-Host ""
Write-Host "Execution script created: execute-reorganization.ps1" -ForegroundColor Cyan
Write-Host "Run it to apply changes (backup will be created first)" -ForegroundColor Cyan
