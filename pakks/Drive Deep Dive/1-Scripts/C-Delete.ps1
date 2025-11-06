<# =========================  C-Delete.ps1  =========================
Purpose : Purge old Quarantine runs and (optionally) Archive runs.
Safety  : DRY by default (no changes unless -Execute). Preserves
          RegBackups in Archive unless -IncludeRegBackups is used.
Params  :
  -Execute              => actually delete (omit to preview)
  -IncludeArchive       => also process Archive runs
  -IncludeRegBackups    => allow deletion of RegBackups under Archive runs
  -OlderThanDays <int>  => minimum age of run folder to be eligible
  -MinSizeMB <int>      => minimum size of run folder (0 = ignore size)
  -RunStamp <stamp>     => target a single run (e.g., 20251102-111613)
  -ArchiveRoot <path>   => override auto-detected archive root
Notes   :
  Quarantine root is inferred from the pack. Archive root auto-detects
  between D:\_Archives and D:\UserData\Archives unless overridden.
=================================================================== #>

[CmdletBinding()]
param(
  [switch]$Execute,
  [switch]$IncludeArchive,
  [switch]$IncludeRegBackups,
  [int]$OlderThanDays = 30,
  [int]$MinSizeMB = 0,
  [string]$RunStamp,
  [string]$ArchiveRoot
)

$ErrorActionPreference = 'Stop'

# --- Constants / roots ---
$PackRoot        = 'D:\UserData\Pakks\Drive Deep Dive'
$QuarantineRoot  = Join-Path $PackRoot '3-Quarantine (Pack Specific)'
$LogsRoot        = Join-Path $PackRoot '2-Logs'

# --- Resolve Archive root if requested ---
if ($IncludeArchive) {
  if (-not $ArchiveRoot) {
    $candidates = @('D:\_Archives','D:\UserData\Archives')
    $ArchiveRoot = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
  }
  if (-not $ArchiveRoot -or -not (Test-Path -LiteralPath $ArchiveRoot)) {
    Write-Host "-- Archive root not found; skipping Archive." -ForegroundColor Yellow
    $IncludeArchive = $false
  }
}

# --- Transcript / banner ---
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log   = Join-Path $LogsRoot ("Purge_{0}.txt" -f $stamp)
try {
  New-Item -ItemType Directory -Force -Path $LogsRoot | Out-Null
  Start-Transcript -Path $log -NoClobber | Out-Null
} catch { }

Write-Host "Mode 3 (PURGE) — $([bool]$Execute ? 'EXECUTE' : 'DRY RUN')" -ForegroundColor Cyan
Write-Host ("OlderThanDays: {0}   MinSizeMB: {1}   RunStamp: {2}" -f $OlderThanDays,$MinSizeMB,($RunStamp ?? '')) 
Write-Host ("Targets: {0}{1}" -f 'Quarantine', ($IncludeArchive ? ' + Archive' : ''))
if (-not $IncludeRegBackups) { Write-Host "RegBackups: protected (add -IncludeRegBackups to purge)" -ForegroundColor Yellow }
Write-Host ""

# --- Helpers ---
function Get-DirSizeMB([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return 0 }
  $sum = 0L
  Get-ChildItem -LiteralPath $Path -Recurse -Force -File -EA SilentlyContinue | ForEach-Object { $sum += $_.Length }
  [math]::Round($sum / 1MB, 2)
}

function Is-Eligible([System.IO.DirectoryInfo]$dir) {
  if (-not $dir) { return $false }
  $ageDays = ((Get-Date) - $dir.LastWriteTime).TotalDays
  if ($OlderThanDays -gt 0 -and $ageDays -lt $OlderThanDays) { return $false }
  if ($MinSizeMB -gt 0) {
    $size = Get-DirSizeMB $dir.FullName
    if ($size -lt $MinSizeMB) { return $false }
  }
  return $true
}

function Remove-RunFolder([string]$RunPath, [switch]$Archive, [switch]$ProtectRegBackups) {
  if (-not (Test-Path -LiteralPath $RunPath)) { return }

  $dir = Get-Item -LiteralPath $RunPath
  if (-not (Is-Eligible $dir) -and -not $RunStamp) {
    Write-Host ("  SKIP (age/size): {0}" -f $RunPath) -ForegroundColor DarkYellow
    return
  }

  if ($Archive -and $ProtectRegBackups) {
    $regPath = Join-Path $RunPath 'RegBackups'
    # Delete children except RegBackups
    Get-ChildItem -LiteralPath $RunPath -Force | Where-Object {
      $_.FullName -ne $regPath
    } | ForEach-Object {
      $target = $_.FullName
      if ($PSBoundParameters.ContainsKey('WhatIf')) { }
      Write-Host ("  DEL -> {0}" -f $target)
      Remove-Item -LiteralPath $target -Recurse -Force -WhatIf:(!$Execute)
    }
    # If only RegBackups remains and folder is empty besides it, we keep the run dir as a shell
    # You can choose to remove the empty run folder too — here we keep it for clarity.
  } else {
    Write-Host ("  RMDIR -> {0}" -f $RunPath)
    Remove-Item -LiteralPath $RunPath -Recurse -Force -WhatIf:(!$Execute)
  }
}

# --- Process QUARANTINE ---
Write-Host ("-- QUARANTINE: {0}" -f $QuarantineRoot) -ForegroundColor Gray
if (Test-Path -LiteralPath $QuarantineRoot) {
  $qRuns = @()
  if ($RunStamp) {
    $p = Join-Path $QuarantineRoot ("Run_{0}" -f $RunStamp)
    if (Test-Path -LiteralPath $p) { $qRuns += Get-Item -LiteralPath $p }
  } else {
    $qRuns = Get-ChildItem -LiteralPath $QuarantineRoot -Directory -EA SilentlyContinue |
      Where-Object { $_.Name -match '^Run_\d{8}-\d{6}$' }
  }
  foreach ($r in $qRuns) {
    Write-Host ("  RUN -> {0} (LastWrite: {1})" -f $r.FullName, $r.LastWriteTime)
    Remove-RunFolder -RunPath $r.FullName -ProtectRegBackups:$false
  }
} else {
  Write-Host "  (Quarantine root not found)" -ForegroundColor Yellow
}

# --- Process ARCHIVE (optional) ---
if ($IncludeArchive) {
  Write-Host ""
  Write-Host ("-- ARCHIVE: {0}" -f $ArchiveRoot) -ForegroundColor Gray
  $aRuns = @()
  if ($RunStamp) {
    $p = Join-Path $ArchiveRoot ("T-nonGames_{0}" -f $RunStamp)
    if (Test-Path -LiteralPath $p) { $aRuns += Get-Item -LiteralPath $p }
  } else {
    $aRuns = Get-ChildItem -LiteralPath $ArchiveRoot -Directory -EA SilentlyContinue |
      Where-Object { $_.Name -match '^T-nonGames_\d{8}-\d{6}$' }
  }
  if (-not $aRuns) {
    Write-Host "  (No archive runs matched criteria.)" -ForegroundColor DarkYellow
  } else {
    foreach ($r in $aRuns) {
      Write-Host ("  RUN -> {0} (LastWrite: {1})" -f $r.FullName, $r.LastWriteTime)
      Remove-RunFolder -RunPath $r.FullName -Archive -ProtectRegBackups:(!$IncludeRegBackups)
    }
  }
}

Write-Host ("Purge transcript: {0}" -f $log)
try { Stop-Transcript | Out-Null } catch { }
