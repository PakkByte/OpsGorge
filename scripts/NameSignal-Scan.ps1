# File: D:\Repos\OpsGorge\scripts\NameSignal-Scan.ps1
param(
  [string]$ScanRoot    = 'D:\',
  [string]$ExcludeRoot = 'D:\Repos',
  [string]$LogRoot     = 'D:\Repos\OpsGorgeStaging\2-Logs',
  [switch]$WithHash,
  [ValidateSet('report','stage')]
  [string]$Action      = 'report',
  [string]$StagingRoot = 'D:\Repos\OpsGorgeStaging\_ingest'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Signals ---------------------------------------------------------------
$FileNameSignals = @(
  'PL.md','README.md','INDEX.md',
  'Prompt_Pack.md','Performance_Loop.md','System_Brief.md',
  'Project_Seed.md','Tests.md','Lessons.md',
  'Chat_Brief.md','Examples.md','Error_Log.md',
  'validate.yml','validate.yaml','.gitattributes','.gitignore'
)
$PathComponentSignals = @(
  '.github','brain_global','projects','chats','2-Logs'
)

function Matches-NameSignal([string]$name){
  $n = $name.ToLowerInvariant()
  foreach($s in $FileNameSignals){
    if($n -eq $s.ToLowerInvariant()){ return $true }
  }
  return $false
}
function Matches-PathSignal([string]$full){
  $f = $full.ToLowerInvariant()
  foreach($p in $PathComponentSignals){
    if($f -match [regex]::Escape($p.ToLowerInvariant())){ return $true }
  }
  return $false
}
function File-Hash([string]$p){
  try { (Get-FileHash -LiteralPath $p -Algorithm SHA256 -ErrorAction Stop).Hash } catch { $null }
}

# --- Setup -----------------------------------------------------------------
$ts     = Get-Date -Format 'yyyyMMdd-HHmmss'
$runId  = "name_signal_${ts}"
$outDir = Join-Path $LogRoot $runId
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$csv    = Join-Path $outDir 'name_signal_hits.csv'
$md     = Join-Path $outDir 'summary.md'
$errors = Join-Path $outDir 'errors.log'

Write-Host "Scanning $ScanRoot (excluding $ExcludeRoot)..." -ForegroundColor Cyan

$files = Get-ChildItem -LiteralPath $ScanRoot -Recurse -Force -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notlike "$ExcludeRoot*" }

$dirs  = Get-ChildItem -LiteralPath $ScanRoot -Recurse -Force -Directory -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notlike "$ExcludeRoot*" }

$hits = New-Object System.Collections.Generic.List[object]

# --- Directory path-component signals -------------------------------------
foreach($d in $dirs){
  if (Matches-PathSignal $d.FullName){
    $hits.Add([pscustomobject]@{
      Kind='Directory'; FullPath=$d.FullName; Name=$d.Name;
      Signal='PathComponent'; SizeMB=$null;
      ModifiedUtc=$d.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm:ssZ');
      Sha256=$null
    }) | Out-Null
  }
}

# --- File name/path signals (fixed logic; no ternary) ----------------------
foreach($f in $files){
  $nameHit = Matches-NameSignal $f.Name
  $pathHit = Matches-PathSignal $f.FullName
  if($nameHit -or $pathHit){
    $signals = @()
    if($nameHit){ $signals += 'Name' }
    if($pathHit){ $signals += 'PathComponent' }
    $signalStr = if($signals.Count -gt 0){ $signals -join '+' } else { '(none)' }

    $sha = if($WithHash){ File-Hash $f.FullName } else { $null }

    $hits.Add([pscustomobject]@{
      Kind='File'; FullPath=$f.FullName; Name=$f.Name;
      Signal=$signalStr;
      SizeMB=[math]::Round($f.Length/1MB,3);
      ModifiedUtc=$f.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm:ssZ');
      Sha256=$sha
    }) | Out-Null
  }
}

# --- Outputs ---------------------------------------------------------------
$hits | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

if ($Action -eq 'stage' -and $hits.Count -gt 0){
  $bucket = Join-Path $StagingRoot ("NameSignal_{0}" -f $ts)
  New-Item -ItemType Directory -Path $bucket -Force | Out-Null
  $filesToStage = $hits | Where-Object { $_.Kind -eq 'File' } | Select-Object -ExpandProperty FullPath -Unique
  foreach($p in $filesToStage){
    try {
      Copy-Item -LiteralPath $p -Destination (Join-Path $bucket (Split-Path $p -Leaf)) -Force
    } catch {
      "[$(Get-Date -Format 's')] stage error: $p — $($_.Exception.Message)" | Add-Content -LiteralPath $errors -Encoding UTF8
    }
  }
  Write-Host "Staged $(($filesToStage|Measure-Object).Count) files → $bucket" -ForegroundColor Green
}

# Summary MD
$nl="`r`n"
$bd=@()
$bd+="# Name-Signal Scan"
$bd+="**Run:** $runId  "
$bd+="**Scope:** $ScanRoot (excluding $ExcludeRoot)  "
$bd+="**Hits:** $($hits.Count)  "
$bd+="**Action:** $Action  "
$bd+="**CSV:** $(Split-Path $csv -Leaf)  "
if (Test-Path $errors){ $bd+="**Errors:** $(Split-Path $errors -Leaf)  " }
$bd -join $nl | Set-Content -LiteralPath $md -Encoding UTF8

Write-Host "`nDone. Reports in $outDir" -ForegroundColor Cyan
