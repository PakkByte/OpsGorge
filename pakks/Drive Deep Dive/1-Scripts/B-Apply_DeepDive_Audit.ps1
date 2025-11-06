<# ===================== B-Apply_DeepDive_Audit.ps1 =====================
Applies cleanup actions from cleanup_audit_*.json.

• DRY RUN by default (pass -Execute to make changes)
• MinSizeMB filter supported
• Moves LargeNonGames to Archive (avoids “dest is inside source” traps)
• Quarantines Duplicates (keeps best; others moved)
• Deletes DeadLnk .lnk files
• Cleans StaleUninstall registry keys (backs up .reg under Archive\RegBackups)
• Writes restore_map_<RunStamp>.json so Restore-FromQuarantine.ps1 can put things back

Author: Pakksbyte (metabase signature)
Version: 1.6.5-apply+map
======================================================================= #>

[CmdletBinding()]
param(
  [string]$AuditJson,
  [int]$MinSizeMB = 0,
  [switch]$Execute,

  # === Default destinations (safe & outside user trees) ===
  [string]$QuarantineRoot = 'D:\UserData\Pakks\Drive Deep Dive\3-Quarantine (Pack Specific)',
  # NOTE: ArchiveBase defaults to D:\_Archives to avoid nesting inside D:\UserData
  [string]$ArchiveBase    = 'D:\_Archives'
)

$ErrorActionPreference = 'Stop'
$WhatIf   = -not $Execute
$minBytes = [int64]$MinSizeMB * 1MB

# ---------- helpers ----------
function First-NonNull { param([Parameter(ValueFromRemainingArguments=$true)] $Values) foreach ($v in $Values) { if ($null -ne $v -and $v -ne '') { return $v } } return $null }
function Get-DirSizeBytes { param([string]$Path) try { (Get-ChildItem -LiteralPath $Path -Recurse -File -EA SilentlyContinue | Measure-Object Length -Sum).Sum } catch { 0 } }
function Safe-DeleteFile { param([string]$LiteralPath,[switch]$WhatIf) if (Test-Path -LiteralPath $LiteralPath) { Remove-Item -LiteralPath $LiteralPath -Recurse -Force -EA Continue -WhatIf:$WhatIf } }

# create a deterministic quarantine leaf name (valid on NTFS)
function Get-QuarantineLeaf([string]$p) {
  return ($p -replace '[:\\]','_')
}

# normalize full path (no trailing slashes, case-insensitive compare)
function Normalize-Full([string]$p) {
  [System.IO.Path]::GetFullPath($p)
}

# is A an ancestor of B?
function Is-Ancestor([string]$a,[string]$b) {
  try {
    $A = Normalize-Full $a
    $B = Normalize-Full $b
    return $B.StartsWith($A, [System.StringComparison]::OrdinalIgnoreCase)
  } catch { return $false }
}

# select a safe archive root (fallback to drive root _Archives if needed)
function Resolve-ArchiveRoot([string]$srcPath,[string]$defaultArchiveBase) {
  $src = Normalize-Full $srcPath
  $def = Normalize-Full $defaultArchiveBase
  if (-not (Test-Path -LiteralPath $def)) {
    New-Item -ItemType Directory -Force -Path $def | Out-Null
  }
  if (-not (Is-Ancestor $src $def)) { return $def }
  # If default archive lives inside the source (bad), pick <Drive>:\_Archives
  $drive = [System.IO.Path]::GetPathRoot($src)
  $alt   = Normalize-Full (Join-Path $drive '_Archives')
  if (-not (Test-Path -LiteralPath $alt)) { New-Item -ItemType Directory -Force -Path $alt | Out-Null }
  return $alt
}

# ---------- resolve pack/log paths ----------
$PackRoot = Split-Path $PSScriptRoot -Parent
$LogsRoot = Join-Path $PackRoot '2-Logs'
if (-not (Test-Path -LiteralPath $LogsRoot)) { New-Item -ItemType Directory -Force -Path $LogsRoot | Out-Null }

# ---------- resolve audit JSON ----------
if (-not $AuditJson) {
  $maybe = Get-ChildItem -Path $LogsRoot -Recurse -Filter 'cleanup_audit_*.json' -EA SilentlyContinue |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($maybe) { $AuditJson = $maybe.FullName }
}
if (-not $AuditJson -or -not (Test-Path -LiteralPath $AuditJson)) {
  throw "Audit JSON not found. Pass -AuditJson 'FULL\PATH\cleanup_audit_YYYYMMDD-HHMMSS.json'."
}

# ---------- derive run stamp from filename ----------
$leaf     = Split-Path $AuditJson -Leaf
$RunStamp = ($leaf -replace '^cleanup_audit_(\d{8}-\d{6})\.json$','$1')
if ($RunStamp -eq $leaf) { $RunStamp = (Get-Date -Format 'yyyyMMdd-HHmmss') }

# ---------- transcript ----------
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$TranscriptPath = Join-Path $LogsRoot ("Apply_{0}.txt" -f $ts)
Start-Transcript -Path $TranscriptPath -Append | Out-Null

# ---------- restore-map setup ----------
$RestoreMapFile = Join-Path $LogsRoot ("restore_map_{0}.json" -f $RunStamp)
$restoreItems   = New-Object System.Collections.Generic.List[object]
function Add-RestoreMap { param([string]$From,[string]$To)
  $restoreItems.Add([pscustomobject]@{ fromPath=$From; toPath=$To })
}

try {
  # ---------- prep action dirs ----------
  $ArchiveRoot   = Join-Path (Resolve-ArchiveRoot -srcPath $PackRoot -defaultArchiveBase $ArchiveBase) ("T-nonGames_{0}" -f $RunStamp)
  $RegBackupDir  = Join-Path $ArchiveRoot 'RegBackups'
  $QuarantineDir = Join-Path $QuarantineRoot ("Run_{0}" -f $RunStamp)
  New-Item -ItemType Directory -Force -Path $ArchiveRoot,$RegBackupDir,$QuarantineDir | Out-Null

  # ---------- load audit (array OR {items:[...]}) ----------
  $raw   = Get-Content $AuditJson -Raw
  $AUD   = $raw | ConvertFrom-Json
  $items = if ($AUD.PSObject.Properties.Name -contains 'items') { $AUD.items } else { $AUD }
  if (-not $items) { throw "No items found in audit JSON: $AuditJson" }

  Write-Host ">>> Using audit: $AuditJson"
  Write-Host ">>> RunStamp:    $RunStamp"
  Write-Host ">>> Quarantine:  $QuarantineDir"
  Write-Host ">>> Archive:     $ArchiveRoot"
  Write-Host ">>> Mode:        " -NoNewline; if ($WhatIf) { Write-Host "DRY RUN (-WhatIf)" -ForegroundColor Yellow } else { Write-Host "EXECUTE (changes will be made!)" -ForegroundColor Green }
  Write-Host ">>> MinSizeMB:   $MinSizeMB MB"

  # ---------- normalize fields ----------
  $norm = foreach ($row in $items) {
    [pscustomobject]@{
      Type      = $row.Type
      Path      = $row.Path
      Notes     = First-NonNull $row.Notes $row.Reason
      Rule      = First-NonNull $row.Rule  $row.ruleId
      SizeBytes = $row.sizeBytes
      GroupId   = First-NonNull $row.groupId $row.hash $row.duplicateGroupId
    }
  }

  # ---------- apply exclusions if present ----------
  $exFile = Join-Path $PSScriptRoot 'apply_exclusions.json'
  if (Test-Path -LiteralPath $exFile) {
    $ex = Get-Content $exFile -Raw | ConvertFrom-Json
    if ($ex.skipTypes) { $norm = $norm | Where-Object { $_.Type -notin $ex.skipTypes } }
    if ($ex.skipPaths) {
      $norm = $norm | Where-Object {
        $p = $_.Path
        $ok = $true
        foreach ($sp in $ex.skipPaths) { if ($null -ne $p -and $p -like ($sp + "*")) { $ok = $false; break } }
        $ok
      }
    }
  }

  # ---------- buckets ----------
  $keepLink      = @($norm | Where-Object { $_.Type -in @('Keep','Link') })
  $largeNonGames = @($norm | Where-Object { $_.Type -eq 'LargeNonGames' -and $_.Path })
  $deadLnk       = @($norm | Where-Object { $_.Type -eq 'DeadLnk' -and $_.Path })
  $staleUninst   = @($norm | Where-Object { $_.Type -eq 'StaleUninstall' -and $_.Path })
  $dupes         = @($norm | Where-Object { $_.Type -eq 'Duplicate' -and $_.Path })

  # ---------- MinSize filter and size enrichment ----------
  if ($MinSizeMB -gt 0) {
    # enrich directory sizes lazily
    foreach ($n in $largeNonGames) {
      if (-not $n.SizeBytes -and (Test-Path -LiteralPath $n.Path)) {
        $n | Add-Member SizeBytes (Get-DirSizeBytes -Path $n.Path) -Force
      }
    }
    $largeNonGames = @($largeNonGames | Where-Object { $_.SizeBytes -ge $minBytes })
    if ($dupes.Count) { $dupes = @($dupes | Where-Object { $_.SizeBytes -ge $minBytes }) }
  }

  # ---------- 1) keep/link (skip) ----------
  if ($keepLink.Count) { Write-Host "`n-- SKIP (Keep/Link): $($keepLink.Count) items" }

  # ---------- 2) archive large non-games ----------
  if ($largeNonGames.Count) {
    Write-Host "`n-- ARCHIVE LargeNonGames: $($largeNonGames.Count) items"
    foreach ($n in $largeNonGames) {
      if (-not (Test-Path -LiteralPath $n.Path)) { Write-Warning "  Missing path (skipped): $($n.Path)"; continue }
      $safeLeaf = Split-Path $n.Path -Leaf
      $destBase = Resolve-ArchiveRoot -srcPath $n.Path -defaultArchiveBase $ArchiveBase
      $dest     = Join-Path (Join-Path $destBase ("T-nonGames_{0}" -f $RunStamp)) ($safeLeaf -replace '[:\\]','_')

      # If destination is inside source → fallback to drive root _Archives\<stamp>\<leaf>
      if (Is-Ancestor $n.Path $dest) {
        $driveRoot = [System.IO.Path]::GetPathRoot( (Normalize-Full $n.Path) )
        $driveArch = Normalize-Full (Join-Path $driveRoot ("_Archives\T-nonGames_{0}" -f $RunStamp))
        if (-not (Test-Path -LiteralPath $driveArch)) { New-Item -ItemType Directory -Force -Path $driveArch | Out-Null }
        $dest = Join-Path $driveArch ($safeLeaf -replace '[:\\]','_')
      }

      if (-not (Test-Path -LiteralPath (Split-Path $dest -Parent))) {
        New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
      }

      $mb = if ($n.SizeBytes) { [math]::Round(($n.SizeBytes/1MB),1) } else { 0 }
      Write-Host ("  MOVE  -> {0}`n           {1}  [{2} MB]" -f $n.Path, $dest, $mb)
      Move-Item -LiteralPath $n.Path -Destination $dest -Force -ErrorAction Continue -WhatIf:$WhatIf
      if (-not $WhatIf) { Add-RestoreMap -From $n.Path -To $dest }
    }
  }

  # ---------- 3) delete dead .lnk ----------
  if ($deadLnk.Count) {
    Write-Host "`n-- DELETE DeadLnk: $($deadLnk.Count) items"
    foreach ($d in $deadLnk) {
      if (-not $d.Path) { continue }
      Write-Host ("  DELETE -> {0}   [target: {1}]" -f $d.Path, $d.Notes)
      Safe-DeleteFile -LiteralPath $d.Path -WhatIf:$WhatIf
    }
  }

  # ---------- 4) clean stale uninstall keys ----------
  if ($staleUninst.Count) {
    Write-Host "`n-- CLEAN StaleUninstall: $($staleUninst.Count) registry keys"
    foreach ($s in $staleUninst) {
      $key = $s.Path; if (-not $key) { continue }
      $safeName = ($key -replace '[\\/:*?"<>|]','_') + ".reg"
      $outReg   = Join-Path $RegBackupDir $safeName
      try { & reg.exe export $key $outReg /y | Out-Null; Write-Host "  EXPORT -> $key" } catch { Write-Warning "  Export failed (maybe missing): $key" }
      try { Remove-Item -Path ("Registry::{0}" -f $key) -Recurse -Force -EA Stop -WhatIf:$WhatIf; Write-Host "  REMOVE -> $key   [$($s.Notes)]" } catch { Write-Warning "  Delete failed or key not present: $key" }
    }
  }

  # ---------- 5) quarantine duplicates ----------
  if ($dupes.Count) {
    Write-Host "`n-- QUARANTINE Duplicates: $($dupes.Count) entries"
    $groups = if ($dupes | Where-Object { $_.GroupId }) { $dupes | Group-Object GroupId } else { $dupes | Group-Object { Split-Path $_.Path -Leaf } }
    foreach ($g in $groups) {
      $keep   = $g.Group | Sort-Object SizeBytes -Descending | Select-Object -First 1
      $others = $g.Group | Where-Object { $_.Path -ne $keep.Path }
      $keepMB = if ($keep.SizeBytes) { [math]::Round(($keep.SizeBytes/1MB),1) } else { 0 }
      Write-Host ("  GROUP: {0}  -> keep: {1}  [{2} MB]" -f ($g.Name), $keep.Path, $keepMB)
      foreach ($o in $others) {
        if (Test-Path -LiteralPath $o.Path) {
          $oMB = if ($o.SizeBytes) { [math]::Round(($o.SizeBytes/1MB),1) } else { 0 }
          $qLeaf = Get-QuarantineLeaf $o.Path
          $qDest = Join-Path $QuarantineDir $qLeaf
          Write-Host "    QUAR -> $($o.Path)"
          Move-Item -LiteralPath $o.Path -Destination $qDest -Force -ErrorAction Continue -WhatIf:$WhatIf
          if (-not $WhatIf) { Add-RestoreMap -From $o.Path -To $qDest }
        } else {
          Write-Warning "    Missing duplicate (skipped): $($o.Path)"
        }
      }
    }
  }

  # ---------- summary ----------
  $counts = [ordered]@{
    KeepOrLink   = $keepLink.Count
    Archived     = $largeNonGames.Count
    DeadLnk      = $deadLnk.Count
    StaleUninst  = $staleUninst.Count
    Duplicates   = $dupes.Count
  }
  Write-Host "`n== SUMMARY ==" -ForegroundColor Cyan
  $counts.GetEnumerator() | Sort-Object Name | ForEach-Object { "{0,-12} : {1}" -f $_.Name, $_.Value } | Write-Host

  if ($WhatIf) {
    Write-Host "`nDRY RUN complete. Re-run with -Execute to apply changes." -ForegroundColor Yellow
  } else {
    Write-Host "`nEXECUTION complete. Quarantine: $QuarantineDir  |  Archive: $ArchiveRoot" -ForegroundColor Green
    Write-Host "Registry backups stored in: $RegBackupDir"
  }
}
finally {
  # ---------- write restore map ----------
  $mapOut = [pscustomobject]@{
    runStamp  = $RunStamp
    generated = (Get-Date).ToString('s')
    items     = $restoreItems
  }
  $mapOut | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -LiteralPath $RestoreMapFile
  Write-Host ("[map] Restore mapping -> {0}  (items: {1})" -f $RestoreMapFile, $restoreItems.Count)

  Stop-Transcript | Out-Null
  Write-Host "Apply transcript saved to: $TranscriptPath"
}

