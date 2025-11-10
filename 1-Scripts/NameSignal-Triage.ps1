param(
  [string]$LogsRoot    = 'D:\Repos\OpsGorgeStaging\2-Logs',   # where name_signal_* lives
  [string]$RepoRoot    = 'D:\Repos\OpsGorge',                 # your SoT working copy
  [string]$StageRoot   = 'D:\Repos\OpsGorgeStaging\_ingest',  # where we will stage "keep" picks
  [switch]$AlsoStageKeep                                   # copy keep candidates into StageRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- find latest Name-Signal run
$runDir = Get-ChildItem $LogsRoot -Directory |
  Where-Object Name -match '^name_signal_' |
  Sort-Object LastWriteTime -Desc | Select-Object -First 1
if(-not $runDir){ throw "No name_signal_* run found under $LogsRoot" }

$hitsCsv = Join-Path $runDir.FullName 'name_signal_hits.csv'
if(-not (Test-Path $hitsCsv)){ throw "Missing: $hitsCsv" }
$hits = Import-Csv $hitsCsv

# --- rules
$KeepNames = @(
  'PL.md','README.md','INDEX.md',
  'Prompt_Pack.md','Performance_Loop.md','System_Brief.md',
  'Project_Seed.md','Tests.md','Lessons.md',
  'Chat_Brief.md','Examples.md','Error_Log.md',
  'validate.yml','validate.yaml','.gitignore','.gitattributes'
)
$KeepPathParts = @('.github','brain_global','projects','chats','2-Logs')

$IgnoreVendors = @(
  'obs-studio','cue_qml_plugins','iCUE','corsair','govee','razer','nvidia',
  'fallback_docs','locale','localization','msi afterburner','tmp\download'
)

function Is-Keep($row){
  if ($row.Kind -ne 'File') { return $false }
  $n = $row.Name.ToLowerInvariant()
  if ($KeepNames -contains $row.Name) { return $true }
  $full = $row.FullPath.ToLowerInvariant()
  foreach($p in $KeepPathParts){ if($full -match [regex]::Escape($p.ToLowerInvariant())){ return $true } }
  return $false
}
function Is-Ignore($row){
  $full = $row.FullPath.ToLowerInvariant()
  foreach($v in $IgnoreVendors){ if($full -like "*$v*"){ return $true } }
  return $false
}

# --- classify
$keep     = New-Object System.Collections.Generic.List[object]
$ignore   = New-Object System.Collections.Generic.List[object]
$undecide = New-Object System.Collections.Generic.List[object]

foreach($r in $hits){
  if (Is-Keep $r)       { $keep.Add($r)     | Out-Null; continue }
  if (Is-Ignore $r)     { $ignore.Add($r)   | Out-Null; continue }
  $undecide.Add($r)     | Out-Null
}

# --- write artifacts
$outDir = Join-Path $runDir.FullName 'triage'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$keepCsv     = Join-Path $outDir 'keep_candidates.csv'
$ignoreCsv   = Join-Path $outDir 'ignore_candidates.csv'
$undecCsv    = Join-Path $outDir 'undecided.csv'
$mdChecklist = Join-Path $outDir 'checklist.md'

$keep     | Export-Csv -Path $keepCsv   -NoTypeInformation -Encoding UTF8
$ignore   | Export-Csv -Path $ignoreCsv -NoTypeInformation -Encoding UTF8
$undecide | Export-Csv -Path $undecCsv  -NoTypeInformation -Encoding UTF8

$nl="`r`n"
$md = @()
$md += "# Name-Signal Triage Checklist"
$md += "**Run:** $($runDir.Name)  "
$md += "**Keep candidates:** $($keep.Count)  — **Ignore candidates:** $($ignore.Count)  — **Undecided:** $($undecide.Count)$nl"
$md += "## Keep (proposed)";  foreach($k in $keep){   $md += "- [ ] `$($k.FullPath)`" }
$md += "$nl## Ignore (proposed)"; foreach($i in $ignore){ $md += "- [ ] `$($i.FullPath)`" }
$md += "$nl## Undecided (review)"; foreach($u in $undecide){ $md += "- [ ] `$($u.FullPath)`" }
$md -join $nl | Set-Content -LiteralPath $mdChecklist -Encoding UTF8

Write-Host ("Keep: {0}  Ignore: {1}  Undecided: {2}" -f $keep.Count,$ignore.Count,$undecide.Count) -ForegroundColor Cyan
Write-Host "Checklist: $mdChecklist" -ForegroundColor Cyan

# --- optional: stage "keep" files to staging bucket
if ($AlsoStageKeep -and $keep.Count -gt 0) {
  $bucket = Join-Path $StageRoot ("NameSignalKeep_{0}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
  New-Item -ItemType Directory -Path $bucket -Force | Out-Null
  $copied = 0
  foreach($k in $keep){
    try {
      $leaf = Split-Path $k.FullPath -Leaf
      Copy-Item -LiteralPath $k.FullPath -Destination (Join-Path $bucket $leaf) -Force
      $copied++
    } catch {
      Add-Content -LiteralPath (Join-Path $outDir 'errors.log') -Value ("copy fail: {0} — {1}" -f $k.FullPath,$_.Exception.Message)
    }
  }
  Write-Host "Staged $copied keep-candidates → $bucket" -ForegroundColor Green
}
