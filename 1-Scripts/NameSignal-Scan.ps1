<#  NameSignal-Scan.ps1  (ASCII-safe, PS 7+)
    Scans a drive for files that "look like" SoT/repo material (brains, PL, CI, logs),
    writes a CSV + summary.md, and can stage a safe subset to Staging.

    Usage (report only):
      & 'D:\Repos\OpsGorge\scripts\NameSignal-Scan.ps1' `
        -ScanRoot 'D:\' -ExcludeRoot 'D:\Repos' `
        -LogRoot 'D:\Repos\OpsGorgeStaging\2-Logs' -Action report

    Usage (stage a subset too):
      & 'D:\Repos\OpsGorge\scripts\NameSignal-Scan.ps1' `
        -ScanRoot 'D:\' -ExcludeRoot 'D:\Repos' `
        -LogRoot 'D:\Repos\OpsGorgeStaging\2-Logs' -Action stage
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]  [string]$ScanRoot,
  [Parameter(Mandatory=$true)]  [string]$ExcludeRoot,
  [Parameter(Mandatory=$true)]  [string]$LogRoot,
  [ValidateSet('report','stage')] [string]$Action = 'report',
  [int]$StageMaxMB = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-Abs([string]$p) {
  if (-not $p) { return $null }
  if (Test-Path -LiteralPath $p) { return (Resolve-Path -LiteralPath $p).Path }
  throw "Path not found: $p"
}

# ---- Inputs (absolute)
$scanAbs    = Resolve-Abs $ScanRoot
$excludeAbs = Resolve-Abs $ExcludeRoot
$logAbs     = Resolve-Abs $LogRoot

# ---- Run folder
$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDir = Join-Path $logAbs ("name_signal_{0}" -f $stamp)
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

# ---- Name/Path signals that hint at repo/brains/ci content
$nameSignals = @(
  'PL.md','PL.yml','PL.yaml',
  'validate.yml','validate.yaml',
  'pull_request_template.md','pull_request_template.yml','CODEOWNERS',
  'INDEX.md','System_Brief.md','Prompt_Pack.md','Performance_Loop.md',
  'Project_Seed.md','Tests.md','Lessons.md','Chat_Brief.md','Examples.md',
  'Error_Log.md','README.md'
)

$pathSignals = @(
  '\brain_global\','\projects\','\chats\','\.github\','\2-Logs\'
)

# ---- Helper: is under excluded subtree?
function Is-UnderExclude([string]$full) {
  if (-not $excludeAbs) { return $false }
  $a = $full.ToLowerInvariant()
  $b = $excludeAbs.ToLowerInvariant()
  return $a.StartsWith($b)
}

# ---- Collect candidates
Write-Host "Scanning: $scanAbs" -ForegroundColor Cyan
Write-Host "Excluding: $excludeAbs" -ForegroundColor DarkCyan

$items = @()
Get-ChildItem -LiteralPath $scanAbs -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
  $f = $_
  $full = $f.FullName
  if (Is-UnderExclude $full) { return }

  $nameHit = $false
  foreach ($n in $nameSignals) {
    if ($f.Name -ieq $n) { $nameHit = $true; break }
  }

  $pathHit = $false
  $low = $full.ToLowerInvariant()
  foreach ($p in $pathSignals) {
    if ($low -like "*$($p.ToLowerInvariant())*") { $pathHit = $true; break }
  }

  if ($nameHit -or $pathHit) {
    $items += [PSCustomObject]@{
      FullName = $full
      Name     = $f.Name
      Dir      = $f.DirectoryName
      Length   = $f.Length
      LastUtc  = $f.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm:ssZ')
      NameHit  = $nameHit
      PathHit  = $pathHit
    }
  }
}

# ---- Duplicates by file name
$dupNames = $items | Group-Object Name | Where-Object { $_.Count -gt 1 } |
  Select-Object @{n='Name';e={$_.Name}}, @{n='Count';e={$_.Count}}

# ---- Top directories by count
$topDirs = $items | Group-Object Dir | Sort-Object Count -Descending | Select-Object -First 10

# ---- Export CSV
$csvPath = Join-Path $runDir 'name_signal_hits.csv'
$items | Sort-Object Name,Dir | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

# ---- Optional staging (small, safe text files)
$stageNote = $null
if ($Action -eq 'stage') {
  $stageDir = Join-Path (Split-Path $logAbs -Parent) ("_ingest\NameSignal_{0}" -f $stamp)
  New-Item -ItemType Directory -Path $stageDir -Force | Out-Null

  $maxBytes = [int64]$StageMaxMB * 1MB
  $toStage = $items | Where-Object {
    $_.Length -le $maxBytes -and $_.Name -match '\.(md|yml|yaml|json|txt)$'
  }

  foreach ($row in $toStage) {
    $dest = Join-Path $stageDir $row.Name
    Copy-Item -LiteralPath $row.FullName -Destination $dest -Force -ErrorAction SilentlyContinue
  }
  $stageNote = $stageDir
}

# ---- Summary.md (ASCII only)
$sumPath = Join-Path $runDir 'summary.md'
$NL = [Environment]::NewLine
$lines = @()
$lines += "# Name-Signal -- $stamp"
$lines += ""
$lines += ("*Generated:* {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss (zzz)'))
$lines += "*Scope:* " + $scanAbs
$lines += "*Exclude:* " + $excludeAbs
$lines += ""
$lines += "## Stats"
$lines += ("- Candidates: {0}" -f $items.Count)
$lines += ("- Duplicate names: {0}" -f $dupNames.Count)
$lines += ""
$lines += "## Top directories"
if ($topDirs) {
  foreach ($g in $topDirs) { $lines += ("- {0} - {1}" -f $g.Name, $g.Count) }
} else { $lines += "- (none)" }
$lines += ""
$lines += "## Duplicate names"
if ($dupNames) {
  foreach ($d in $dupNames) { $lines += ("- {0} - {1}x" -f $d.Name, $d.Count) }
} else { $lines += "- (none)" }
if ($stageNote) {
  $lines += ""
  $lines += "## Staging"
  $lines += ("- Staged subset to: {0}" -f $stageNote)
}
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($sumPath, ($lines -join $NL), $utf8NoBom)

# ---- Console outputs
Write-Host ("CSV   => {0}" -f $csvPath) -ForegroundColor Green
Write-Host ("SUM   => {0}" -f $sumPath) -ForegroundColor Green
if ($stageNote) { Write-Host ("STAGE => {0}" -f $stageNote) -ForegroundColor Green }
