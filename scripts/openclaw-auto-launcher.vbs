' OpenClaw Gateway Launcher - Runs without UAC
' VBS wrapper to hide window and avoid elevation

Set WshShell = CreateObject("WScript.Shell")

' Wait 30 seconds for system to stabilize
WScript.Sleep 30000

' Start gateway in hidden window
WshShell.Run "cmd /c ""C:\Users\impro\.openclaw\gateway.cmd""", 0, False

' Wait 20 seconds for gateway to initialize
WScript.Sleep 20000

' Open Chrome with OpenClaw UI in NEW window (force foreground)
WshShell.Run "C:\Program Files\Google\Chrome\Application\chrome.exe --new-window http://127.0.0.1:18789/", 1, False

' Bring window to front
WScript.Sleep 2000
WshShell.AppActivate "OpenClaw"