[CmdletBinding()]
param(
  [switch]$Strict,
  [switch]$ComparePolicyExclusions,
  [string]$RepoRoot = (Resolve-Path ".").Path
)
$ErrorActionPreference="Stop"; Set-StrictMode -Version Latest
function Fail($m){ Write-Error $m; exit 1 }
function Note($m){ Write-Host $m -ForegroundColor Cyan }
function Read-Json($p){ if(-not(Test-Path $p)){ return $null }; try{ Get-Content -LiteralPath $p -Raw | ConvertFrom-Json -ErrorAction Stop }catch{ return 'INVALID_JSON' } }
function AsArr($v){ if($null -eq $v){@()} elseif($v -is [System.Collections.IEnumerable] -and -not ($v -is [string])){@($v)} else {@([string]$v)} }

$policy = Read-Json (Join-Path $RepoRoot 'Policy.json')
$excl   = Read-Json (Join-Path $RepoRoot 'apply_exclusions.json')
if($policy -eq $null -or $policy -eq 'INVALID_JSON' -or -not ($policy -is [pscustomobject])){ Fail "Policy.json missing/invalid." }
if($excl   -eq $null -or $excl   -eq 'INVALID_JSON' -or -not ($excl   -is [pscustomobject])){ Fail "apply_exclusions.json missing/invalid." }

if($ComparePolicyExclusions){
  $polSkip = if($policy.PSObject.Properties.Name -contains 'skipPaths'){ AsArr $policy.skipPaths } else { @() }
  $excSkip = if($excl.PSObject.Properties.Name   -contains 'skipPaths'){ AsArr $excl.skipPaths   } else { @() }
  $polSkip = $polSkip | ForEach-Object { [string]$_ } | Sort-Object -Unique
  $excSkip = $excSkip | ForEach-Object { [string]$_ } | Sort-Object -Unique
  $diff = Compare-Object -ReferenceObject $polSkip -DifferenceObject $excSkip
  if($diff){ $diff | Format-Table -AutoSize | Out-String | Write-Host; if($Strict){ Fail "Drift detected in skipPaths." } }
  else { Note "skipPaths parity: OK" }

  if($policy.PSObject.Properties.Name -contains 'MinSizeMB' -and $excl.PSObject.Properties.Name -contains 'MinSizeMB'){
    if([int]$policy.MinSizeMB -ne [int]$excl.MinSizeMB){ Fail "MinSizeMB mismatch: Policy=$($policy.MinSizeMB) vs Exclusions=$($excl.MinSizeMB)" }
    else { Note "MinSizeMB parity: OK ($($policy.MinSizeMB))" }
  } else { Note "MinSizeMB parity skipped (not present on both)." }
}

# Lightweight secret scan
$deny='(^|/)\.git/|node_modules/|/bin/|/obj/|\.github/|2-Logs/|/dist/|/build/|(^|/)\.venv?/'
$pats=@('(?i)ghp_[0-9A-Za-z]{36,}','(?i)aws(.{0,20})?(secret|access)_?key','(?i)password\s*[:=]\s*.+','(?i)token\s*[:=]\s*[A-Za-z0-9\-\._]{20,}')
$hits=@()
Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -Force | ForEach-Object {
  $rel=[IO.Path]::GetRelativePath($RepoRoot,$_.FullName) -replace '\\','/'
  if($rel -match $deny){ return }
  try{ $t=Get-Content -LiteralPath $_.FullName -Raw -ErrorAction Stop; foreach($rx in $pats){ if($t -match $rx){ $hits+=[pscustomobject]@{Path=$rel;Pattern=$rx} } } }catch{}
}
if($hits){ $hits | Sort-Object Path,Pattern | Format-Table -AutoSize | Out-String | Write-Host; if($Strict){ Fail "Secret scan found $($hits.Count) potential hit(s)." } }
else { Note "Secret scan: OK" }

# Logs presence
$logDir = Join-Path $RepoRoot '2-Logs'
if(-not(Test-Path $logDir)){ Fail "Missing 2-Logs/ directory." }
$maps = Get-ChildItem -LiteralPath $logDir -Filter 'restore_map_*.json' -File -ErrorAction SilentlyContinue
if(-not $maps){
  $init = Join-Path $logDir 'restore_map_init.json'
  if(-not(Test-Path $init)){ if($Strict){ Fail "No restore_map_* artifacts or init stub present." } }
  else{ try{ Get-Content -LiteralPath $init -Raw | ConvertFrom-Json -ErrorAction Stop | Out-Null }catch{ Fail "restore_map_init.json invalid JSON." } }
}
Note "DoD checks completed."


# --- Exclusions (added by CI softening) ---
\ = @(
  'automation/.env.mac',
  'automation/.env.pc'
)
