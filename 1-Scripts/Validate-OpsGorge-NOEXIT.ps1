# D:\Repos\OpsGorge\scripts\Validate-OpsGorge-NOEXIT.ps1
param([string]$RepoRoot = 'D:\Repos\OpsGorge')

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Add-Row {
  param([string]$Check,[bool]$Pass,[string]$Details,[string]$Path='')
  [pscustomobject]@{
    Check   = $Check
    Status  = if ($Pass) { 'PASS' } else { 'FAIL' }
    Details = $Details
    Path    = $Path
  }
}
function Has([string]$Rel) { Test-Path -LiteralPath (Join-Path $RepoRoot $Rel) }

# --- Start ---
if (-not (Test-Path -LiteralPath $RepoRoot)) {
  Write-Host "Repo root not found: $RepoRoot" -ForegroundColor Red
  Read-Host "Press Enter to close"
  exit 1
}
Set-Location $RepoRoot

$rows = @()

# Basics
$rows += Add-Row 'Repo root exists' $true 'OK' $RepoRoot

$insideGit = $false
try { git rev-parse --is-inside-work-tree *> $null; if ($LASTEXITCODE -eq 0) { $insideGit = $true } } catch {}
$rows += Add-Row 'Git repo detected' $insideGit ($(if($insideGit){'OK'}else{'Not a git repo'})) $RepoRoot

$remoteUrl = ''
if ($insideGit) { try { $remoteUrl = (git config --get remote.origin.url).Trim() } catch {} }
$rows += Add-Row "Git remote 'origin' set" ($remoteUrl -ne '') ($(if($remoteUrl){$remoteUrl}else{'Missing'})) $remoteUrl

# Folder presence
foreach ($rel in @('.github','2-Logs','brain_global','projects','scripts')) {
  $exists = Has $rel
  $rows += Add-Row "Folder: $rel" $exists ($(if($exists){'Found'}else{'Missing'})) (Join-Path $RepoRoot $rel)
}

# CI workflow
$wf = '.github\workflows\validate.yml'
$wfOk = Has $wf
$rows += Add-Row 'CI workflow: validate.yml' $wfOk ($(if($wfOk){'Found'}else{'Missing'})) (Join-Path $RepoRoot $wf)

# PR template
$prt = '.github\PULL_REQUEST_TEMPLATE\default.md'
$prtOk = Has $prt
$rows += Add-Row 'PR template present' $prtOk ($(if($prtOk){'OK'}else{'Missing'})) (Join-Path $RepoRoot $prt)

# PL.md
$plp = 'PL.md'
$plOk = Has $plp
$rows += Add-Row 'PL.md present' $plOk ($(if($plOk){'Found'}else{'Missing'})) (Join-Path $RepoRoot $plp)

# brain_global required files
foreach ($f in 'INDEX.md','System_Brief.md','Prompt_Pack.md','Performance_Loop.md') {
  $p = "brain_global\$f"
  $ok = Has $p
  $rows += Add-Row "Global brain: $p" $ok ($(if($ok){'Found'}else{'Missing'})) (Join-Path $RepoRoot $p)
}

# CT project brains
foreach ($f in 'INDEX.md','Project_Seed.md','Tests.md','Lessons.md') {
  $p = "projects\CT\brain\$f"
  $ok = Has $p
  $rows += Add-Row "CT brain: $p" $ok ($(if($ok){'Found'}else{'Missing'})) (Join-Path $RepoRoot $p)
}

# CT chats (Audits, PR, Advising)
$roles = 'Audits','PR','Advising'
$chatFiles = 'INDEX.md','Chat_Brief.md','Examples.md','Error_Log.md'
foreach ($r in $roles) {
  $chatDir = "projects\CT\chats\$r\brain"
  $dirOk = Has $chatDir
  $rows += Add-Row "CT chat folder: ${r}" $dirOk ($(if($dirOk){'Found'}else{'Missing'})) (Join-Path $RepoRoot $chatDir)
  foreach ($cf in $chatFiles) {
    $p = "$chatDir\$cf"
    $ok = Has $p
    $rows += Add-Row "CT ${r}: $cf" $ok ($(if($ok){'Found'}else{'Missing'})) (Join-Path $RepoRoot $p)
  }
}

# 2-Logs hygiene (only .md or restore_map_init.json)
$badList = @()
if (Has '2-Logs') {
  $all = @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot '2-Logs') -Recurse -File -Force)
  foreach ($it in $all) {
    $isMd   = ($it.Extension -ieq '.md')
    $isStub = ($it.Name -ieq 'restore_map_init.json')
    if (-not ($isMd -or $isStub)) { $badList += $it.FullName }
  }
}
$logsOk = (@($badList).Count -eq 0)
$rows += Add-Row '2-Logs hygiene' $logsOk ($(if($logsOk){'Only markdown (+ restore_map_init.json) present'}else{"Unexpected files: $(@($badList).Count)"})) (Join-Path $RepoRoot '2-Logs')

# Output (force arrays so .Count is safe)
$failRows = @($rows | Where-Object { $_.Status -eq 'FAIL' })
$passRows = @($rows | Where-Object { $_.Status -eq 'PASS' })

if ($failRows.Count -gt 0) {
  Write-Host "Overall: FAIL ($($failRows.Count) failing, $($passRows.Count) passing)" -ForegroundColor Red
} else {
  Write-Host "Overall: PASS ($($passRows.Count) passing)" -ForegroundColor Green
}

$rows | Sort-Object Status, Check | Format-Table -AutoSize

if (@($badList).Count -gt 0) {
  Write-Host "`nUnexpected files under 2-Logs (should be .md or restore_map_init.json):" -ForegroundColor Yellow
  @($badList) | ForEach-Object { Write-Host " - $_" }
}

Write-Host ''
Read-Host 'Done. Press Enter to close'
