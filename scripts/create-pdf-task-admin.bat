@echo off
echo ==========================================
echo PDF Organization Task Scheduler
echo ==========================================
echo.
echo This will create a scheduled task to organize
echo PDFs from E:\All every night at 1:00 AM
echo.
echo Press any key to continue as Administrator...
pause > nul

powershell -Command "Start-Process powershell -Verb runAs -ArgumentList '-ExecutionPolicy Bypass -File ""C:\Users\impro\.openclaw\workspace\scripts\schedule-pdf-organization.ps1""'"

echo.
echo Task creation initiated in elevated PowerShell.
echo.
pause
