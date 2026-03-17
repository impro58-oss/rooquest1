# categorize-uncategorized.ps1
# Deep categorization of files in 00-Uncategorized

$SourcePath = "E:\2025 Development Merge\1- Reading\00-Uncategorized"
$BasePath = "E:\2025 Development Merge\1- Reading"

Write-Host "Analyzing Uncategorized files..." -ForegroundColor Cyan

# Define categorization based on content analysis
$FileCategories = @{
    # Fitness - Programs & Workouts
    "03-Fitness-Health\Programs-Workouts" = @(
        "10 Ways to Modify or Regress a Movement.pdf",
        "365SBL.pdf",
        "3-Day Food Log.pdf",
        "50 Recommended Recipes.pdf",
        "50more.pdf",
        "5Mil.pdf",
        "AFGHAN PRE-DEPLOYMENT.pdf",
        "Aguas Profundas.pdf",
        "BB.pdf",
        "Built Like a Badass.pdf",
        "CnP-Issuance-of-Insanity.pdf",
        "Destroy the Opposition by Jamie Lewis.pdf",
        "DropthePanties.pdf",
        "Fatal Fitness - USAF TACP.pdf",
        "Gymnast Strong.pdf",
        "Johnny_Pain_-_Swole.pdf",
        "Kelsos Shrug Book.pdf",
        "Lift-run-bang-365.pdf",
        "mastodon.pdf",
        "Maximal Tension for Maximal Results.pdf",
        "NeverLetGo.pdf",
        "Powerbuilding.pdf",
        "Quick Reference Video Guide.pdf",
        "Reader_Created_Coconut_Cookbook-Final.pdf",
        "Ripped-to-Shreds.pdf",
        "Strong-Man-Manifesto.pdf",
        "SWOLE2.pdf",
        "Troubleshooting Single-Leg Exercises.pdf"
    )
    
    # Fitness - Nutrition
    "03-Fitness-Health\Nutrition" = @(
        "1. Anastasia Thriving Meal Plans by @anastasiathriving.pdf",
        "12. Gut Health Recipe Bundle by @natural_minded_mama.pdf",
        "20. Healthy Fairy Food by @laurafruitfairy.pdf",
        "The-Primal-Blueprint-Reader-Created-Cookbook12292010-1.pdf",
        "Primal Blueprint Fitness eBook 01172011 - Mark Sisson.pdf",
        "Primal_Blueprint_Fitness_eBook_01172011.pdf"
    )
    
    # Fitness - Yoga/Wellness
    "03-Fitness-Health\Yoga-Wellness" = @(
        "16. Move 2 Glow by @sarahgluschke.pdf",
        "21. Naturally Aligning With Your Cycle by @bellaanya.pdf",
        "27. 7 Day Gut Health Reset by @puresoulholistichealth.pdf",
        "29. Happy & Healthy Every Day by @beccineumann (2).pdf"
    )
    
    # Personal Development
    "02-Personal-Development\Psychology" = @(
        "Hacking The Mind.pdf",
        "Understanding Sleep and Dreaming-MT.pdf",
        "4. Journaling for Self-Care by @selfcaresupply.pdf"
    )
    
    # Spiritual/Esoteric
    "05-Spiritual-Esoteric\Hypnosis-NLP" = @(
        "Karen E. Wells - Full Certification & Accredited Past Life Regression Therapy Course_ Advanced Hypnotherapy Techniques.pdf"
    )
    
    # Technical - AI/ML
    "04-Technical-Professional\AI-Machine-Learning" = @(
        "SocherBengioManning-DeepLearning-ACL2012-20120707-NoMargin.pdf"
    )
    
    # Technical - Engineering
    "04-Technical-Professional\Engineering" = @(
        "grey_lci.pdf"
    )
    
    # Science/Physics
    "07-Science-Physics" = @(
        "(Routledge Classics) David Bohm - Wholeness and the Implicate Order -Routledge (2002).pdf"
    )
    
    # Medical - Neurovascular (move to your neuro folder)
    "08-Medical-Neurovascular" = @(
        "fneur-11-00923.pdf",
        "Hellstern-2024-fneur-15-1415861.pdf",
        "ABC WIN 2023 Congress Report Day 1.pdf",
        "ABC WIN 2023 Congress Report Day 4.pdf",
        "ABC WIN 2023 Congress Report Day 5.pdf",
        "Brain-hemorrhage.webp"
    )
    
    # Reference - Charts/Divination
    "09-Reference-Divination" = @(
        "baj_pendulums_dowsing_chart_01.pdf",
        "baj_pendulums_dowsing_chart_02.pdf"
    )
    
    # Images (keep in Uncategorized or create Images folder)
    "10-Images" = @(
        "0918_EVT_FT2_Fig1.png",
        "1679894405049.jpg",
        "SAH-source-ASA.jpg"
    )
}

# Create new categories if they don't exist
$NewCategories = @(
    "04-Technical-Professional\AI-Machine-Learning",
    "07-Science-Physics",
    "08-Medical-Neurovascular",
    "09-Reference-Divination",
    "10-Images"
)

foreach ($cat in $NewCategories) {
    $fullPath = Join-Path $BasePath $cat
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  Created: $cat" -ForegroundColor Gray
    }
}

# Move files
$MovedCount = 0
$ErrorCount = 0

foreach ($category in $FileCategories.Keys) {
    $destFolder = Join-Path $BasePath $category
    
    foreach ($fileName in $FileCategories[$category]) {
        $sourceFile = Join-Path $SourcePath $fileName
        $destFile = Join-Path $destFolder $fileName
        
        if (Test-Path $sourceFile) {
            try {
                Move-Item -Path $sourceFile -Destination $destFile -Force
                Write-Host "  Moved: $fileName -> $category" -ForegroundColor Green
                $MovedCount++
            } catch {
                Write-Host "  ERROR: $fileName - $_" -ForegroundColor Red
                $ErrorCount++
            }
        }
    }
}

Write-Host ""
Write-Host "=== CATEGORIZATION COMPLETE ===" -ForegroundColor Cyan
Write-Host "Files moved: $MovedCount" -ForegroundColor Green
Write-Host "Errors: $ErrorCount" -ForegroundColor $(if ($ErrorCount -gt 0) { "Red" } else { "Green" })

# Show remaining files
$Remaining = Get-ChildItem -Path $SourcePath -File
if ($Remaining.Count -gt 0) {
    Write-Host ""
    Write-Host "Remaining in Uncategorized:" -ForegroundColor Yellow
    foreach ($file in $Remaining) {
        Write-Host "  - $($file.Name)" -ForegroundColor Gray
    }
} else {
    Write-Host ""
    Write-Host "00-Uncategorized is now empty!" -ForegroundColor Green
}
