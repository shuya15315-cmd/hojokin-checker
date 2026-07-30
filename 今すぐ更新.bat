@echo off
rem === 補助金・税制改正チェッカー を今すぐ最新化する ===
rem （普段は週1回自動で更新されます。すぐ最新にしたい時だけこれをダブルクリック）
chcp 65001 >nul
echo 最新の情報を集めています。数分かかります。ウィンドウは閉じずにお待ちください...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update.ps1"
echo.
echo 完了しました。index.html を開き直すと最新の内容が表示されます。
pause
