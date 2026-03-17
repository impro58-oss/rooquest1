@echo off
REM Polymarket Hourly Scan Runner
cd /d "C:\Users\impro\.openclaw\workspace\scripts"
powershell -ExecutionPolicy Bypass -File "polymarket-cron-runner.ps1"
