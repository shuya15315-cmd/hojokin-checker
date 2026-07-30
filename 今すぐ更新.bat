@echo off
rem === Update the subsidy / tax checker now ===
rem (Normally it auto-updates weekly. Double-click this only when you want it right now.)
chcp 65001 >nul
echo Collecting the latest info. This takes a few minutes. Please keep this window open...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update.ps1"
echo.
echo Done. Reopen index.html to see the latest.
pause
