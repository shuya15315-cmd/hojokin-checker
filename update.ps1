<#
  補助金・税制改正チェッカー  自動更新スクリプト (update.ps1)
  --------------------------------------------------------------
  Claude Code (claude.exe) をヘッドレスで呼び出し、update-prompt.md の
  指示に従って data.js を最新化します。
  ・公開情報を「取りに行く」だけ。こちらのデータは一切送りません。
  ・Windowsタスクスケジューラから週1回自動実行される想定。
  ・手動で最新化したい時は「今すぐ更新.bat」をダブルクリックしてもOK。
#>

# ---- 文字化け対策：入出力をUTF-8に固定 ----
try {
  chcp 65001 > $null
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# ---- 設定（必要ならここだけ変更）----
$proj        = Split-Path -Parent $MyInvocation.MyCommand.Path   # このファイルのある場所＝プロジェクト
$model       = "sonnet"      # 使うモデル。精度重視なら "opus" に変更可
$keepLogs    = 12            # 残すログ数

# ---- 準備 ----
$logDir = Join-Path $proj "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$log   = Join-Path $logDir ("update_$stamp.log")

function Write-Log($msg) {
  $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $msg
  $line | Out-File -FilePath $log -Encoding utf8 -Append
  Write-Host $line
}

Write-Log "=== 自動更新を開始します ==="
Write-Log "プロジェクト: $proj"

# ---- claude.exe を探す ----
$claudeExe = (Get-Command claude -ErrorAction SilentlyContinue).Source
if (-not $claudeExe) {
  $cand = Join-Path $env:USERPROFILE ".local\bin\claude.exe"
  if (Test-Path $cand) { $claudeExe = $cand }
}
if (-not $claudeExe) {
  Write-Log "エラー: claude が見つかりません。Claude Code がインストール・ログイン済みか確認してください。"
  exit 1
}
Write-Log "claude: $claudeExe / モデル: $model"

# ---- 更新前に data.js をバックアップ（壊れた更新が来ても戻せる保険）----
$dataFile = Join-Path $proj "data.js"
if (Test-Path $dataFile) {
  $bkDir = Join-Path $proj "backups"
  if (-not (Test-Path $bkDir)) { New-Item -ItemType Directory -Path $bkDir | Out-Null }
  Copy-Item $dataFile (Join-Path $bkDir ("data_$stamp.js")) -Force
  # 直近8世代だけ残す
  Get-ChildItem $bkDir -Filter "data_*.js" | Sort-Object LastWriteTime -Descending |
    Select-Object -Skip 8 | Remove-Item -Force -ErrorAction SilentlyContinue
  Write-Log "data.js をバックアップしました（backups フォルダ）"
}

# ---- Claude をヘッドレス実行（日本語の詳細指示は update-prompt.md をClaudeが読む）----
$prompt = "Read the file 'update-prompt.md' in this directory and follow its instructions exactly to refresh 'data.js' with the latest Japanese subsidy and tax-reform information. Use only web search and public official sources. Do not send any private data."

$claudeArgs = @(
  "-p", $prompt,
  "--add-dir", $proj,
  "--allowedTools", "WebSearch,WebFetch,Read,Write,Edit,Glob,Grep",
  "--permission-mode", "acceptEdits",
  "--model", $model,
  "--output-format", "text"
)

Write-Log "Claudeに更新を依頼中…（数分かかります）"
Push-Location $proj
try {
  # 呼び出し演算子 & ＋ 配列スプラットで、空白入り引数も正しく渡す
  & $claudeExe @claudeArgs 2>&1 | Out-File -FilePath $log -Encoding utf8 -Append
  $code = $LASTEXITCODE
} catch {
  Write-Log ("実行時エラー: " + $_.Exception.Message)
  $code = 1
} finally {
  Pop-Location
}

if ($code -eq 0) {
  Write-Log "=== 完了しました（data.js を更新）==="
} else {
  Write-Log "=== 失敗またはエラー終了 (exit=$code)。上のログを確認してください ==="
}

# ---- GitHub へ自動反映（remote 'origin' が設定されている時だけ）----
if ($code -eq 0 -and (Get-Command git -ErrorAction SilentlyContinue)) {
  git -C $proj remote get-url origin 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) {
    git -C $proj add -A 2>&1 | Out-File -FilePath $log -Encoding utf8 -Append
    git -C $proj diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {   # 変更あり
      $cmsg = "auto update " + (Get-Date -Format "yyyy-MM-dd")
      git -C $proj commit -m $cmsg 2>&1 | Out-File -FilePath $log -Encoding utf8 -Append
      git -C $proj push 2>&1     | Out-File -FilePath $log -Encoding utf8 -Append
      if ($LASTEXITCODE -eq 0) { Write-Log "GitHub へ push 完了（Teamsタブに自動反映されます）" }
      else { Write-Log "【注意】git push に失敗。認証(PAT)・ネットワーク・upstream設定を確認してください" }
    } else {
      Write-Log "内容に変更なし。push はスキップしました。"
    }
  } else {
    Write-Log "GitHub連携は未設定（remote origin なし）。ローカル更新のみ行いました。"
  }
}

# ---- 古いログの掃除 ----
Get-ChildItem $logDir -Filter "update_*.log" | Sort-Object LastWriteTime -Descending |
  Select-Object -Skip $keepLogs | Remove-Item -Force -ErrorAction SilentlyContinue

exit $code
