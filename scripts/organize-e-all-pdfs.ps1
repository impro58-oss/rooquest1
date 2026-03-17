# organize-e-all-pdfs.ps1
# Systematically organizes PDFs from E:\All into appropriate folders
# Processes in batches to handle large volume

param(
    [int]$BatchSize = 100,
    [switch]$WhatIf,
    [string]$SourcePath = "E:\All"
)

$ReadingPath = "E:\2025 Development Merge\1- Reading"
$JournalPath = "E:\2025 Development Merge\2- Journal Papers"
$LogFile = "$env:USERPROFILE\.openclaw\workspace\memory\pdf-organization-log.txt"

function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry
    Write-Host $logEntry -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARN") { "Yellow" } else { "White" })
}

Write-Log "=== Starting PDF Organization from $SourcePath ==="

# Create journal paper categories
$JournalCategories = @(
    "01-Neurovascular-Engineering",
    "02-Medical-Devices",
    "03-Quality-Regulatory",
    "04-Manufacturing",
    "05-Statistics-Methods",
    "06-Business-Management",
    "07-Academic-Research"
)

foreach ($cat in $JournalCategories) {
    $catPath = Join-Path $JournalPath $cat
    if (!(Test-Path $catPath)) {
        New-Item -ItemType Directory -Path $catPath -Force | Out-Null
        Write-Log "Created: $catPath"
    }
}

# Get all PDFs
Write-Log "Scanning for PDFs..."
$AllPdfs = Get-ChildItem -Path $SourcePath -Filter "*.pdf" -Recurse -ErrorAction SilentlyContinue
Write-Log "Found $($AllPdfs.Count) PDFs total"

# Classification rules
$ClassificationRules = @{
    # Books (go to Reading folder)
    "BOOKS" = @(
        "freakonomics",
        "super brain",
        "unleashing",
        "mind",
        "happiness",
        "textbook",
        "guide",
        "manual",
        "handbook",
        "encyclopedia",
        "principles",
        "strategies",
        "complete",
        "introduction",
        "fundamentals",
        "essentials"
    )
    
    # Journal papers by topic
    "01-Neurovascular-Engineering" = @(
        "neurovascular",
        "microcatheter",
        "catheter",
        "stroke",
        "aneurysm",
        "thrombectomy",
        "embolization",
        "interventional",
        "neuroradiology",
        "endovascular"
    )
    
    "02-Medical-Devices" = @(
        "medical device",
        "implant",
        "stent",
        "balloon",
        "delivery system",
        "phenox",
        "microvention",
        "terumo",
        "medtronic",
        "stryker",
        "penumbra"
    )
    
    "03-Quality-Regulatory" = @(
        "iso 13485",
        "iso 9001",
        "fda",
        "regulatory",
        "quality agreement",
        "supplier",
        "certification",
        "accreditation",
        "gmp",
        "hpra",
        "notified body",
        "technical file",
        "510k",
        "pma"
    )
    
    "04-Manufacturing" = @(
        "manufacturing",
        "production",
        "assembly",
        "workmanship",
        "test method",
        "validation",
        "verification",
        "calibration",
        "gauge r&r",
        "inspection"
    )
    
    "05-Statistics-Methods" = @(
        "statistics",
        "statistical",
        "t-test",
        "anova",
        "gauge",
        "measurement",
        "analysis",
        "method",
        "procedure",
        "sop",
        "protocol"
    )
    
    "06-Business-Management" = @(
        "business plan",
        "strategy",
        "management",
        "corporate",
        "overview",
        "insurance",
        "contract",
        "nda",
        "cv",
        "resume",
        "biography"
    )
    
    "07-Academic-Research" = @(
        "research",
        "study",
        "paper",
        "journal",
        "conference",
        "proceedings",
        "thesis",
        "dissertation",
        "academic"
    )
}

# Process in batches
$ProcessedCount = 0
$BookCount = 0
$JournalCount = 0
$UncategorizedCount = 0

foreach ($pdf in $AllPdfs | Select-Object -First $BatchSize) {
    $fileName = $pdf.Name.ToLower()
    $fileSizeMB = [math]::Round($pdf.Length / 1MB, 2)
    $categorized = $false
    $targetPath = $null
    
    # Check if it's a book (larger files, comprehensive titles)
    $isBook = $false
    foreach ($bookKeyword in $ClassificationRules["BOOKS"]) {
        if ($fileName -like "*$bookKeyword*" -and $fileSizeMB -gt 1) {
            $isBook = $true
            break
        }
    }
    
    if ($isBook) {
        # Try to categorize into existing reading folders
        $targetCategory = "00-Uncategorized"
        
        foreach ($cat in @("01-Business-Finance", "02-Personal-Development", "03-Fitness-Health", 
                          "04-Technical-Professional", "05-Spiritual-Esoteric", "06-Reference-Manuals")) {
            $catPath = Join-Path $ReadingPath $cat
            if (Test-Path $catPath) {
                # Check if any files in this category match
                $sampleFiles = Get-ChildItem -Path $catPath -Filter "*.pdf" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 5
                foreach ($sample in $sampleFiles) {
                    $sampleName = $sample.Name.ToLower()
                    # Simple similarity check
                    $fileWords = $fileName -split '[\s\-_]' | Where-Object { $_.Length -gt 3 }
                    $sampleWords = $sampleName -split '[\s\-_]' | Where-Object { $_.Length -gt 3 }
                    $commonWords = $fileWords | Where-Object { $sampleWords -contains $_ }
                    if ($commonWords.Count -ge 2) {
                        $targetCategory = $cat
                        break
                    }
                }
            }
            if ($targetCategory -ne "00-Uncategorized") { break }
        }
        
        $targetPath = Join-Path $ReadingPath $targetCategory
        $BookCount++
    } else {
        # Categorize as journal paper
        foreach ($category in $JournalCategories) {
            $keywords = $ClassificationRules[$category]
            if ($keywords) {
                foreach ($keyword in $keywords) {
                    if ($fileName -like "*$keyword*") {
                        $targetPath = Join-Path $JournalPath $category
                        $categorized = $true
                        break
                    }
                }
            }
            if ($categorized) { break }
        }
        
        if (!$categorized) {
            $targetPath = Join-Path $JournalPath "00-Uncategorized-Papers"
            if (!(Test-Path $targetPath)) {
                New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
            }
            $UncategorizedCount++
        } else {
            $JournalCount++
        }
    }
    
    # Move the file
    if ($targetPath) {
        $destFile = Join-Path $targetPath $pdf.Name
        
        # Handle duplicates
        if (Test-Path $destFile) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($pdf.Name)
            $extension = [System.IO.Path]::GetExtension($pdf.Name)
            $counter = 1
            while (Test-Path $destFile) {
                $newName = "${baseName}_${counter}${extension}"
                $destFile = Join-Path $targetPath $newName
                $counter++
            }
        }
        
        if (!$WhatIf) {
            try {
                Copy-Item -Path $pdf.FullName -Destination $destFile -Force
                Write-Log "Moved: $($pdf.Name) -> $targetPath"
            } catch {
                Write-Log "ERROR moving $($pdf.Name): $_" "ERROR"
            }
        } else {
            Write-Log "WOULD MOVE: $($pdf.Name) -> $targetPath"
        }
    }
    
    $ProcessedCount++
    
    if ($ProcessedCount % 10 -eq 0) {
        Write-Log "Progress: $ProcessedCount / $($AllPdfs.Count) processed"
    }
}

Write-Log ""
Write-Log "=== BATCH PROCESSING COMPLETE ==="
Write-Log "Processed: $ProcessedCount"
Write-Log "Books: $BookCount"
Write-Log "Journal Papers: $JournalCount"
Write-Log "Uncategorized: $UncategorizedCount"
Write-Log ""
Write-Log "Remaining: $($AllPdfs.Count - $ProcessedCount)"

if ($ProcessedCount -lt $AllPdfs.Count) {
    Write-Log "Run again to process next batch"
}
