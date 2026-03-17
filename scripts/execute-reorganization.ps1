# execute-reorganization.ps1
# Executes the folder reorganization with backup

$SourcePath = "E:\2025 Development Merge\1- Reading"
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmm'
$BackupPath = "E:\2025 Development Merge\1- Reading-BACKUP-$Timestamp"

Write-Host "=== OPENCLAW FOLDER REORGANIZATION ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create backup
Write-Host "Step 1: Creating backup..." -ForegroundColor Yellow
Write-Host "  Source: $SourcePath" -ForegroundColor Gray
Write-Host "  Backup: $BackupPath" -ForegroundColor Gray

Copy-Item -Path $SourcePath -Destination $BackupPath -Recurse -Force
Write-Host "  Backup complete!" -ForegroundColor Green
Write-Host ""

# Step 2: Create new folder structure
Write-Host "Step 2: Creating new folder structure..." -ForegroundColor Yellow

$NewStructure = @(
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

foreach ($folder in $NewStructure) {
    $fullPath = Join-Path $SourcePath $folder
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  Created: $folder" -ForegroundColor Gray
    }
}
Write-Host "  Folder structure created!" -ForegroundColor Green
Write-Host ""

# Step 3: Move files based on categorization
Write-Host "Step 3: Moving files to new locations..." -ForegroundColor Yellow

# Get all files and categorize them
$AllFiles = Get-ChildItem -Path $SourcePath -Recurse -File | Where-Object { $_.FullName -notlike "*$BackupPath*" }

$Categories = @{
    "01-Business-Finance\Trading-Investing" = @("technical analysis", "trading", "investing", "stock", "market", "dalio", "principles", "freakonomics", "economics")
    "01-Business-Finance\Entrepreneurship" = @("business planning", "trump", "success", "achievement", "rich", "think and grow rich", "born rich")
    "02-Personal-Development\Psychology" = @("flow", "psychology", "optimal experience", "csikszentmihalyi", "blink", "gladwell", "rational male")
    "02-Personal-Development\Success-Mindset" = @("maximum achievement", "speak to win", "stop thinking", "living", "happiness", "game", "neil strauss")
    "03-Fitness-Health\Strength-Training" = @("strength", "powerlifting", "bodybuilding", "wendler", "531", "starting strength", "texas method", "westside", "juggernaut", "cube", "strongman", "olympic", "weightlifting", "elitefts", "dinosaur", "convict", "kettlebell", "crossfit")
    "03-Fitness-Health\Nutrition" = @("diet", "nutrition", "anabolic", "ketogenic", "paleo", "renaissance", "ultimate diet", "dolce", "supplement")
    "03-Fitness-Health\Programs-Workouts" = @("program", "workout", "training", "routine", "phase", "week", "greyskull", "gladiator", "rebel", "level", "performance menu", "milo", "dino files")
    "03-Fitness-Health\Yoga-Wellness" = @("yoga", "pilates", "wellness", "stretch", "mobility", "supple", "becoming", "leopard")
    "04-Technical-Professional\Six-Sigma-Lean" = @("six sigma", "lean", "toyota way")
    "04-Technical-Professional\Technical-Writing" = @("technical writing", "style guide", "microsoft manual")
    "04-Technical-Professional\Engineering" = @("plastics", "polymer", "engineering", "fbi manual", "firebird")
    "05-Spiritual-Esoteric\Human-Design" = @("human design", "ra uru hu", "rave", "iching", "destinies")
    "05-Spiritual-Esoteric\Hypnosis-NLP" = @("hypnosis", "hypnotic", "nlp", "neuro linguistic", "brainwashing", "magic words", "scriptless")
    "05-Spiritual-Esoteric\Occult" = @("agrippa", "three books", "occult", "philosophy")
    "06-Reference-Manuals\Product-Manuals" = @("manual", "user guide", "handbook")
}

$MovedCount = 0
$DuplicateCount = 0

foreach ($file in $AllFiles) {
    # Skip if already in a new category folder
    if ($file.FullName -match "\\(0[0-9]-|00-)") { continue }
    
    $fileName = $file.Name.ToLower()
    $matched = $false
    $targetFolder = "00-Uncategorized"
    
    foreach ($category in $Categories.Keys) {
        foreach ($keyword in $Categories[$category]) {
            if ($fileName -like "*$keyword*") {
                $targetFolder = $category
                $matched = $true
                break
            }
        }
        if ($matched) { break }
    }
    
    $destFolder = Join-Path $SourcePath $targetFolder
    $destPath = Join-Path $destFolder $file.Name
    
    # Check for duplicates
    if (Test-Path $destPath) {
        # Compare file sizes to detect duplicates
        $existingSize = (Get-Item $destPath).Length
        $newSize = $file.Length
        
        if ($existingSize -eq $newSize) {
            Write-Host "  DUPLICATE (removed): $($file.Name)" -ForegroundColor Red
            Remove-Item -Path $file.FullName -Force
            $DuplicateCount++
            continue
        } else {
            # Rename to avoid conflict
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $extension = [System.IO.Path]::GetExtension($file.Name)
            $newName = "${baseName}_2$extension"
            $destPath = Join-Path $destFolder $newName
        }
    }
    
    try {
        Move-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction Stop
        Write-Host "  Moved: $($file.Name) -> $targetFolder" -ForegroundColor Gray
        $MovedCount++
    } catch {
        Write-Host "  ERROR moving $($file.Name): $_" -ForegroundColor Red
    }
}

Write-Host "  Files moved: $MovedCount" -ForegroundColor Green
Write-Host "  Duplicates removed: $DuplicateCount" -ForegroundColor Green
Write-Host ""

# Step 4: Clean up empty folders
Write-Host "Step 4: Cleaning up empty folders..." -ForegroundColor Yellow
$EmptyFolders = Get-ChildItem $SourcePath -Directory -Recurse | Where-Object { 
    $_.GetFiles().Count -eq 0 -and $_.GetDirectories().Count -eq 0 -and $_.Name -notmatch "BACKUP"
}

foreach ($folder in $EmptyFolders) {
    Remove-Item -Path $folder.FullName -Force
    Write-Host "  Removed empty: $($folder.Name)" -ForegroundColor Gray
}
Write-Host "  Cleanup complete!" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "=== REORGANIZATION COMPLETE ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backup location: $BackupPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "New structure:" -ForegroundColor Green
Get-ChildItem $SourcePath -Directory | ForEach-Object {
    $fileCount = (Get-ChildItem $_.FullName -Recurse -File).Count
    Write-Host "  $($_.Name): $fileCount files" -ForegroundColor White
}
Write-Host ""
Write-Host "Your files are now organized!" -ForegroundColor Green
