@echo off
rem OpenClaw UI Launcher - Waits for gateway then opens Chrome
echo Waiting for OpenClaw gateway to start...
timeout /t 45 /nobreak >nul
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" http://127.0.0.1:18789/