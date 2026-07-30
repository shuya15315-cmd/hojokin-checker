<#
  setup.ps1 — このフォルダを「自動更新する本番PC」としてセットアップする
  ------------------------------------------------------------------
  別のPC（Claude Code 入り）にこのフォルダごとコピーしたら、
  「セットアップ.bat」をダブルクリック（または本ファイルをPowerShellで実行）してください。
    ・毎週月曜 8:00 の自動更新タスクを登録
    ・デスクトップに閲覧用ショートカットを作成
  ※ このスクリプトは自分の置き場所を自動認識するので、どこに置いてもOKです。
#>
try { chcp 65001 > $null; [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$proj = Split-Path -Parent $MyInvocation.MyCommand.Path
$taskName = "補助金税制チェッカー_自動更新"
Write-Host "==== 補助金・税制改正チェッカー セットアップ ===="
Write-Host "セットアップ先フォルダ: $proj"
Write-Host ""

# 1) Claude Code の確認
$claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
if (-not $claude) { $c = Join-Path $env:USERPROFILE ".local\bin\claude.exe"; if (Test-Path $c) { $claude = $c } }
if (-not $claude) {
  Write-Host "【中止】Claude Code (claude) が見つかりません。" -ForegroundColor Red
  Write-Host "先に Claude Code をインストール・ログインしてから、もう一度実行してください。"
  Read-Host "Enterキーで終了"; exit 1
}
Write-Host "[1/3] Claude Code を確認: $claude  → OK"

# 2) 自動更新タスクの登録（毎週月曜 8:00）
$ps = Join-Path $proj "update.ps1"
if (-not (Test-Path $ps)) { Write-Host "【中止】update.ps1 が見つかりません。フォルダが不完全です。" -ForegroundColor Red; Read-Host "Enterで終了"; exit 1 }
$action   = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ps`""
$trigger  = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 8:00am
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)
$principal= New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
try {
  Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal `
    -Description "毎週月曜8:00に公式サイトから補助金・税制改正を集めてdata.jsを更新（公開情報を読むだけ）。" -Force -ErrorAction Stop | Out-Null
  Write-Host "[2/3] 自動更新タスクを登録: 毎週月曜 8:00  → OK"
} catch {
  Write-Host ("[2/3] 【注意】タスク登録に失敗: " + $_.Exception.Message) -ForegroundColor Yellow
  Write-Host "      （管理者権限が必要な場合があります。手動登録の手順は『引き渡し手順.md』参照）"
}

# 3) デスクトップショートカット
try {
  $ws = New-Object -ComObject WScript.Shell
  $lnk = $ws.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "補助金・税制改正チェッカー.lnk"))
  $lnk.TargetPath = Join-Path $proj "index.html"
  $lnk.WorkingDirectory = $proj
  $lnk.Description = "補助金・税制改正チェッカー"
  $lnk.Save()
  Write-Host "[3/3] デスクトップにショートカットを作成  → OK"
} catch { Write-Host "[3/3] ショートカット作成はスキップしました" -ForegroundColor Yellow }

Write-Host ""
Write-Host "==== セットアップ完了 ====" -ForegroundColor Green
Write-Host "・閲覧            : デスクトップのショートカット、または index.html をダブルクリック"
Write-Host "・すぐ最新化       : 『今すぐ更新.bat』をダブルクリック"
Write-Host "・自動更新の停止   : タスクスケジューラで『$taskName』を無効化/削除"
Write-Host ""
Read-Host "Enterキーで終了"
