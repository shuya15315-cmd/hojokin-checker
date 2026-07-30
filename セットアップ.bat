@echo off
rem === 補助金・税制改正チェッカー を この本番PCにセットアップ ===
rem 別PCにこのフォルダをコピーしたら、これをダブルクリックしてください。
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
