[CmdletBinding()]
param(
  [switch]$Strict,
  [switch]$ComparePolicyExclusions,
  [switch]$SchemaOnly,
  [string]$RepoRoot = (Resolve-Path ".").Path
)
$ErrorActionPreference="Stop"; Set-StrictMode -Version Latest
function Fail($m){ Write-Error $m; exit 1 }
function Note($m){ Write-Host $m -ForegroundColor Cyan }
function Read-Json($p){ if(-not(Test-Path $p)){ return $null } try{ Get-Content -LiteralPath $p -Raw | ConvertFrom-Json -ErrorAction Stop }catch{ Fail "Invalid JSON: $p" } }

$policyPath = Join-Path $RepoRoot 'Policy.json'
$exclPath   = Join-Path $RepoRoot 'apply_exclusions.json'
$policy = Read-Json $policyPath
$excl   = Read-Json $exclPath
if(-not $policy){ Fail "Missing Policy.json" }
if(-not $excl){   Fail "Missing apply_exclusions.json" }

if($ComparePolicyExclusions){
  $polSkip = @($policy.skipPaths) | Sort-Object -Unique
  $excSkip = @($excl.skipPaths)   | Sort-Object -Unique
  $diff = Compare-Object -ReferenceObject $polSkip -DifferenceObject $excSkip
  if($diff){
    $diff | Format-Table -AutoSize | Out-String | Write-Host
    if($Strict){ Fail "Drift detected in skipPaths." }
  } else { Note "skipPaths parity: OK" }
  if($policy.MinSizeMB -ne $null -and $excl.MinSizeMB -ne $null){
    if([int]$policy.MinSizeMB -ne [int]$excl.MinSizeMB){ Fail "MinSizeMB mismatch: Policy=$($policy.MinSizeMB) vs Exclusions=$($excl.MinSizeMB)" }
    else { Note "MinSizeMB parity: OK ($($policy.MinSizeMB))" }
  } else { Note "MinSizeMB check skipped (not present on both)." }
}

# Secret scan (light regexes, ignoring heavy dirs)
$deny = '(^|/)\.git/|node_modules/|/bin/|/obj/|\.github/|2-Logs/|/dist/|/build/|(^|/)\.venv?/'
$pats = @('(?i)aws(.{0,20})?(secret|access)_?key','(?i)ghp_[0-9A-Za-z]{36,}','(?i)azure(.{0,20})?(client|tenant|secret)','(?i)google(.{0,20})?(api|key|secret)','(?i)password\s*[:=]\s*.+','(?i)token\s*[:=]\s*[A-Za-z0-9\-\._]{20,}')
$hits=@()
Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -Force | ForEach-Object {
  $rel=[IO.Path]::GetRelativePath($RepoRoot,$_.FullName) -replace '\\','/'
  if($rel -match $deny){ return }
  try{
    $t=Get-Content -LiteralPath $_.FullName -Raw -ErrorAction Stop
    foreach($rx in $pats){ if($t -match $rx){ $hits += [pscustomobject]@{Path=$rel;Pattern=$rx} } }
  }catch{}
}
if($hits.Count -gt 0){
  $hits | Sort-Object Path,Pattern | Format-Table -AutoSize | Out-String | Write-Host
  if($Strict){ Fail "Secret scan found $($hits.Count) potential hit(s)." }
} else { Note "Secret scan: OK" }

# Logs sanity
$logDir = Join-Path $RepoRoot '2-Logs'
if(-not(Test-Path $logDir)){ Fail "Missing 2-Logs/ directory." }
$maps = Get-ChildItem -LiteralPath $logDir -Filter 'restore_map_*.json' -File -ErrorAction SilentlyContinue
if(-not $maps){
  $init = Join-Path $logDir 'restore_map_init.json'
  if(-not(Test-Path $init)){ if($Strict){ Fail "No restore_map_* artifacts or init stub present." } }
  else{ if(-not(Read-Json $init)){ Fail "restore_map_init.json is not valid JSON." } }
} else {
  foreach($m in $maps){ if(-not(Read-Json $m.FullName)){ Fail "Invalid JSON: $($m.Name)" } }
}

# PL rubric score (advisory)
$pl = Join-Path $RepoRoot 'PL.md'
if(Test-Path $pl){
  $raw = Get-Content -LiteralPath $pl -Raw
  if($raw -match 'PL-Score:\s*(\d+)/10'){
    $s=[int]$Matches[1]; Note "PL-Score detected: $s/10"; if($Strict -and $s -lt 9){ Fail "PL-Score below 9/10 (=$s)." }
  } else { Note "PL-Score not found; add 'PL-Score: 10/10' to PL.md." }
} else { Note "PL.md not found; skipping rubric check." }

Note "DoD checks completed."
