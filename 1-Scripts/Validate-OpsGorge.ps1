<#  Validate-OpsGorge-NOEXIT.ps1
    Purpose: sanity-check repo layout & hygiene without auto-closing window
#>

param(
  [string]$RepoRoot = 'D:\Repos\OpsGorge'
)

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

function HasPathRel { param([string]$Rel)
  return (Test-Path -LiteralPath (Join-Path $RepoRoot $Rel))
}

# --- Start ---
if (-not (Test-Path -LiteralPath $RepoRoot)) {
  Write-Host "Repo root not found: $RepoRoot" -ForegroundColor Red
  Read-Host "Press Enter to close"
  return
}
Set-Location $RepoRoot

$rows = New-Object System.Collections.ArrayList

# Repo basics
$rows.Add( (Add-Row 'Repo root exists' $true 'OK' $RepoRoot) ) | Out-Null

# Git checks (don’t throw if missing)
$insideGit = $false
try { git rev-parse --is-inside-work-tree *> $null; if ($LASTEXITCODE -eq 0) { $insideGit = $true } } catch {}
$rows.Add( (Add-Row 'Git repo detected' $insideGit (if($insideGit){'OK'}else{'Not a git repo'}) $RepoRoot) ) | Out-Null

$remoteUrl = ''
if ($insideGit) {
  try { $remoteUrl = (git config --get remote.origin.url).Trim() } catch {}
}
$rows.Add( (Add-Row "Git remote 'origin' set" ($remoteUrl -ne '') ($remoteUrl -ne '' ? $remoteUrl : 'Missing') ($remoteUrl)) ) | Out-Null

# Folders that must exist
foreach ($rel in @('.github','2-Logs','brain_global','projects','scripts')) {
  $rows.Add( (Add-Row "Folder: $rel" (HasPathRel $rel) ((HasPathRel $rel)?'Found':'Missing') (Join-Path $RepoRoot $rel)) ) | Out-Null
}

# CI workflow & PR template
$rows.Add( (Add-Row 'CI workflow: validate.yml'
  (HasPathRel '.github\workflows\validate.yml')
  (if(HasPathRel '.github\workflows\validate.yml'){'Found'}else{'Missing'})
  (Join-Path $RepoRoot '.github\workflows\validate.yml')) ) | Out-Null

$rows.Add( (Add-Row 'PR template present'
  (HasPathRel '.github\PULL_REQUEST_TEMPLATE\default.md')
  (if(HasPathRel '.github\PULL_REQUEST_TEMPLATE\default.md'){'OK'}else{'Missing'})
  (Join-Path $RepoRoot '.github\PULL_REQUEST_TEMPLATE\default.md')) ) | Out-Null

# PL.md
$rows.Add( (Add-Row 'PL.md present' (HasPathRel 'PL.md') ((HasPathRel 'PL.md')?'Found':'Missing') (Join-Path $RepoRoot 'PL.md')) ) | Out-Null

# brain_global required files
$bgReq = @('INDEX.md','System_Brief.md','Prompt_Pack.md','Performance_Loop.md')
foreach ($f in $bgReq) {
  $p = "brain_global\$f"
  $rows.Add( (Add-Row "Global brain: $p" (HasPathRel $p) ((HasPathRel $p)?'Found':'Missing') (Join-Path $RepoRoot $p)) ) | Out-Null
}

# CT scaffold: project brains
$ctBrains = @('INDEX.md','Project_Seed.md','Tests.md','Lessons.md')
foreach ($f in $ctBrains) {
  $p = "projects\CT\brain\$f"
  $rows.Add( (Add-Row "CT brain: $p" (HasPathRel $p) ((HasPathRel $p)?'Found':'Missing') (Join-Path $RepoRoot $p)) ) | Out-Null
}

# CT chats (Audits, PR, Advising)
$roles = @('Audits','PR','Advising')
$chatFiles = @('INDEX.md','Chat_Brief.md','Examples.md','Error_Log.md')
foreach ($r in $roles) {
  $chatDir = "projects\CT\chats\$r\brain"
  $rows.Add( (Add-Row "CT chat folder: $r" (HasPathRel $chatDir) ((HasPathRel $chatDir)?'Found':'Missing') (Join-Path $RepoRoot $chatDir)) ) | Out-Null
  foreach ($cf in $chatFiles) {
    $p = "$chatDir\$cf"
    $rows.Add( (Add-Row "CT $r: $cf" (HasPathRel $p) ((HasPathRel $p)?'Found':'Missing') (Join-Path $RepoRoot $p)) ) | Out-Null
  }
}

# 2-Logs hygiene: only .md and restore_map_init.json allowed (everywhere under 2-Logs)
$badList = @()
if (HasPathRel '2-Logs') {
  $all = Get-ChildItem -LiteralPath (Join-Path $RepoRoot '2-Logs') -Recurse -File -Force
  foreach ($it in $all) {
    $ok = ($it.Extension -ieq '.md') -or ($it.Name -ieq 'restore_map_init.json')
    if (-not $ok) { $badList += $it.FullName }
  }
}
$logsOk = ($badList.Count -eq 0)
$rows.Add( (Add-Row '2-Logs hygiene'
  $logsOk
  (if($logsOk){'Only markdown (+ restore_map_init.json) present'}else{"Unexpected files: $($badList.Count)"})
  (Join-Path $RepoRoot '2-Logs')) ) | Out-Null

# --- Output ---
$failRows = @($rows | Where-Object { $_.Status -eq 'FAIL' })
$passRows = @($rows | Where-Object { $_.Status -eq 'PASS' })

# Colorized summary header
if ($failRows.Count -gt 0) {
  Write-Host "Overall: FAIL ($($failRows.Count) failing, $($passRows.Count) passing)" -ForegroundColor Red
} else {
  Write-Host "Overall: PASS ($($passRows.Count) passing)" -ForegroundColor Green
}

# Show table
$rows | Sort-Object Status, Check | Format-Table -AutoSize

# If hygiene failed, list offenders
if ($badList.Count -gt 0) {
  Write-Host "`nUnexpected files under 2-Logs (should be .md or restore_map_init.json):" -ForegroundColor Yellow
  $badList | ForEach-Object { Write-Host " - $_" }
}

# Pause so the window stays open when launched from Explorer/shortcut
Write-Host ""
Read-Host "Done. Press Enter to close"

