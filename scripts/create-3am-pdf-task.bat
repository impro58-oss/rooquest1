@echo off
echo ==========================================
echo PDF Organization Task Scheduler (1AM-4AM)
echo ==========================================
echo.
echo This will create a scheduled task to organize
echo PDFs from E:\All every night from 1:00 AM to 4:00 AM
echo.
echo The task will process as many files as possible
echo in the 3-hour window each night.
echo.
echo Press any key to continue as Administrator...
pause > nul

powershell -Command "Start-Process powershell -Verb runAs -ArgumentList '-ExecutionPolicy Bypass -File ""C:\Users\impro\.openclaw\workspace\scripts\schedule-pdf-organization-1am-4am.ps1""'"

echo.
echo Task creation initiated in elevated PowerShell.
echo.
pause
