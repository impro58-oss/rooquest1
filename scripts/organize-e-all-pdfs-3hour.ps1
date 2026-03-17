# organize-e-all-pdfs-3hour.ps1
# Organizes PDFs from E:\All for 3 hours (1 AM to 4 AM window)
# Processes maximum files during the time window

param(
    [int]$DurationMinutes = 180,  # 3 hours default
    [switch]$WhatIf
)

$SourcePath = "E:\All"
$ReadingPath = "E:\2025 Development Merge\1- Reading"
$JournalPath = "E:\2025 Development Merge\2- Journal Papers"
$LogFile = "$env:USERPROFILE\.openclaw\logs\pdf-organization-nightly.log"

function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry
    Write-Host $logEntry -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARN") { "Yellow" } else { "White" })
}

$StartTime = Get-Date
$EndTime = $StartTime.AddMinutes($DurationMinutes)

Write-Log "=== Starting 3-Hour PDF Organization ==="
Write-Log "Start: $StartTime"
Write-Log "End: $EndTime"
Write-Log "Source: $SourcePath"

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
    }
}

# Create Uncategorized folder if needed
$UncategorizedPath = Join-Path $JournalPath "00-Uncategorized-Papers"
if (!(Test-Path $UncategorizedPath)) {
    New-Item -ItemType Directory -Path $UncategorizedPath -Force | Out-Null
}

# Classification rules
$ClassificationRules = @{
    "BOOKS" = @("freakonomics", "super brain", "unleashing", "mind", "happiness", "textbook", "guide", "manual", "handbook", "encyclopedia", "principles", "strategies", "complete", "introduction", "fundamentals", "essentials")
    "01-Neurovascular-Engineering" = @("neurovascular", "microcatheter", "catheter", "stroke", "aneurysm", "thrombectomy", "embolization", "interventional", "neuroradiology", "endovascular")
    "02-Medical-Devices" = @("medical device", "implant", "stent", "balloon", "delivery system", "phenox", "microvention", "terumo", "medtronic", "stryker", "penumbra")
    "03-Quality-Regulatory" = @("iso 13485", "iso 9001", "fda", "regulatory", "quality agreement", "supplier", "certification", "accreditation", "gmp", "hpra", "notified body", "technical file", "510k", "pma")
    "04-Manufacturing" = @("manufacturing", "production", "assembly", "workmanship", "test method", "validation", "verification", "calibration", "gauge r&r", "inspection")
    "05-Statistics-Methods" = @("statistics", "statistical", "t-test", "anova", "gauge", "measurement", "analysis", "method", "procedure", "sop", "protocol")
    "06-Business-Management" = @("business plan", "strategy", "management", "corporate", "overview", "insurance", "contract", "nda", "cv", "resume", "biography")
    "07-Academic-Research" = @("research", "study", "paper", "journal", "conference", "proceedings", "thesis", "dissertation", "academic")
}

# Get all PDFs
Write-Log "Scanning for PDFs..."
$AllPdfs = Get-ChildItem -Path $SourcePath -Filter "*.pdf" -Recurse -ErrorAction SilentlyContinue
$TotalCount = $AllPdfs.Count
Write-Log "Found $TotalCount PDFs total"

# Check for already processed files (in destination folders)
$ProcessedHashes = @{}
$DestFolders = @($ReadingPath, $JournalPath)
foreach ($folder in $DestFolders) {
    if (Test-Path $folder) {
        $existingFiles = Get-ChildItem -Path $folder -Filter "*.pdf" -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $existingFiles) {
            try {
                $hash = (Get-FileHash -Path $file.FullName -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
                if ($hash) { $ProcessedHashes[$hash] = $true }
            } catch {}
        }
    }
}
Write-Log "Already processed: $($ProcessedHashes.Count) files"

# Filter out already processed files
$PdfsToProcess = $AllPdfs | Where-Object {
    try {
        $hash = (Get-FileHash -Path $_.FullName -Algorithm MD5 -ErrorAction SilentlyContinue).Hash
        return !$ProcessedHashes.ContainsKey($hash)
    } catch { return $true }
}

$RemainingCount = $PdfsToProcess.Count
Write-Log "Remaining to process: $RemainingCount"

if ($RemainingCount -eq 0) {
    Write-Log "All PDFs already organized! Nothing to do."
    exit 0
}

# Process files until time runs out
$ProcessedCount = 0
$BookCount = 0
$JournalCount = 0
$UncategorizedCount = 0
$ErrorCount = 0

foreach ($pdf in $PdfsToProcess) {
    # Check if we've run out of time
    $CurrentTime = Get-Date
    if ($CurrentTime -ge $EndTime) {
        Write-Log "Time limit reached ($DurationMinutes minutes). Stopping."
        break
    }
    
    $fileName = $pdf.Name.ToLower()
    $fileSizeMB = [math]::Round($pdf.Length / 1MB, 2)
    $categorized = $false
    $targetPath = $null
    
    # Check if it's a book
    $isBook = $false
    foreach ($bookKeyword in $ClassificationRules["BOOKS"]) {
        if ($fileName -like "*$bookKeyword*" -and $fileSizeMB -gt 1) {
            $isBook = $true
            break
        }
    }
    
    if ($isBook) {
        $targetCategory = "00-Uncategorized"
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
            $targetPath = $UncategorizedPath
            $UncategorizedCount++
        } else {
            $JournalCount++
        }
    }
    
    # Copy the file
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
                $ProcessedCount++
            } catch {
                Write-Log "ERROR copying $($pdf.Name): $_" "ERROR"
                $ErrorCount++
            }
        } else {
            Write-Log "WOULD COPY: $($pdf.Name)"
            $ProcessedCount++
        }
    }
    
    # Progress update every 50 files
    if ($ProcessedCount % 50 -eq 0) {
        $elapsed = ($CurrentTime - $StartTime).TotalMinutes
        $filesPerMin = if ($elapsed -gt 0) { [math]::Round($ProcessedCount / $elapsed, 1) } else { 0 }
        Write-Log "Progress: $ProcessedCount processed ($filesPerMin files/min)"
    }
}

# Summary
$FinalTime = Get-Date
$TotalElapsed = ($FinalTime - $StartTime).ToString("hh\:mm\:ss")
Write-Log ""
Write-Log "=== SESSION COMPLETE ==="
Write-Log "Duration: $TotalElapsed"
Write-Log "Processed: $ProcessedCount"
Write-Log "Books: $BookCount"
Write-Log "Journal Papers: $JournalCount"
Write-Log "Uncategorized: $UncategorizedCount"
Write-Log "Errors: $ErrorCount"
Write-Log "Remaining: $($RemainingCount - $ProcessedCount)"
Write-Log ""

if (($RemainingCount - $ProcessedCount) -le 0) {
    Write-Log "🎉 ALL PDFs ORGANIZED! Task complete."
} else {
    $pctComplete = [math]::Round((($TotalCount - ($RemainingCount - $ProcessedCount)) / $TotalCount) * 100, 1)
    Write-Log "Overall progress: $pctComplete% complete"
    Write-Log "Will continue tomorrow night at 1 AM"
}
