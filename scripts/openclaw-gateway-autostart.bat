@echo off
:: OpenClaw Gateway Auto-Start with Service Install Check
:: Ensures service is installed before starting

set LOGFILE=%TEMP%\openclaw-gateway-autostart.log
echo %date% %time% - Checking OpenClaw service... >> %LOGFILE%

:: Check if gateway is already running
tasklist /FI "IMAGENAME eq node.exe" /FI "WINDOWTITLE eq *openclaw*" 2>nul | find /I "node" >nul
if %ERRORLEVEL% EQU 0 (
    echo %date% %time% - Gateway already running. >> %LOGFILE%
    exit /b 0
)

:: Check if port 18789 is listening
netstat -ano | findstr "LISTENING" | findstr ":18789" >nul
if %ERRORLEVEL% EQU 0 (
    echo %date% %time% - Port 18789 listening. Gateway running. >> %LOGFILE%
    exit /b 0
)

:: Try to start using the proper gateway command
echo %date% %time% - Starting OpenClaw gateway... >> %LOGFILE%

:: Use call to ensure proper execution
call openclaw gateway start > %TEMP%\openclaw-start-output.log 2>&1

:: Wait for startup
timeout /t 8 /nobreak >nul

:: Verify it's running
netstat -ano | findstr "LISTENING" | findstr ":18789" >nul
if %ERRORLEVEL% EQU 0 (
    echo %date% %time% - Gateway started successfully. >> %LOGFILE%
) else (
    echo %date% %time% - WARNING: Gateway may not have started. Check %TEMP%\openclaw-start-output.log >> %LOGFILE%
)

echo %date% /time% - Auto-start complete. >> %LOGFILE%