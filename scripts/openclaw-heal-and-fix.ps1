# openclaw-heal-and-fix.ps1
# One-click self-heal with auto-fix enabled
# Use this for manual repairs or scheduled tasks

param(
    [switch]$Silent
)

$LogFile = "$env:USERPROFILE\.openclaw\logs\self-heal.log"

if (!$Silent) {
    Write-Host "OpenClaw Self-Heal Starting..." -ForegroundColor Cyan
    Write-Host "Log file: $LogFile" -ForegroundColor Gray
    Write-Host ""
}

# Run the self-heal script with auto-fix
& "$env:USERPROFILE\.openclaw\workspace\scripts\openclaw-self-heal.ps1" -AutoFix -Verbose:$(!$Silent)

$exitCode = $LASTEXITCODE

if (!$Silent) {
    Write-Host ""
    if ($exitCode -eq 0) {
        Write-Host "✅ Self-heal completed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Self-heal failed (exit code: $exitCode)" -ForegroundColor Red
        Write-Host "Check log: $LogFile" -ForegroundColor Yellow
    }
}

exit $exitCode
