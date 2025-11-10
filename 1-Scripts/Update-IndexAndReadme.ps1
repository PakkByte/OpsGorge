[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$Root,
  [string]$Logs = (Join-Path $Root "2-Logs")
)

function Get-LatestPath {
  param([Parameter(Mandatory)][string]$Glob)
  # Use -Path so wildcards expand
  $f = Get-ChildItem -Path $Glob -ErrorAction SilentlyContinue |
       Sort-Object LastWriteTime -Desc | Select-Object -First 1
  if ($null -eq $f) { return @{ Path="(none)"; When=$null } }
  return @{ Path=$f.FullName; When=$f.LastWriteTime }
}

function Write-Utf8 {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][object]$Lines
  )
  # Coerce Lines into an array of strings safely
  $arr = @()
  if ($null -eq $Lines) {
    $arr = @("(empty)")
  } elseif ($Lines -is [System.Collections.IEnumerable] -and -not ($Lines -is [string])) {
    $arr = @($Lines | ForEach-Object { [string]$_ })
  } else {
    $arr = @([string]$Lines)
  }

  $dir = [System.IO.Path]::GetDirectoryName($Path)
  if ($dir -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
  Set-Content -LiteralPath $Path -Value ($arr -join [Environment]::NewLine) -Encoding UTF8
}

$index  = Join-Path $Root 'INDEX.md'
$readme = Join-Path $Root 'Master README.md'
$now    = Get-Date

# Lookups
$latestAudit  = Get-LatestPath (Join-Path $Logs 'cleanup_audit_*.json')
$latestApply  = Get-LatestPath (Join-Path $Logs 'Apply_*.txt')
$latestCsv    = Get-LatestPath (Join-Path $Logs 'Apply_Summary_*.csv')
$latestSnap   = Get-LatestPath (Join-Path $Logs 'Policy_Snapshot_*.json')
$latestDiff   = Get-LatestPath (Join-Path $Logs 'Policy_Diff_*.txt')

# Normalize date display
function FmtDate($d) { if ($d) { return ('{0:MM/dd/yyyy HH:mm:ss}' -f $d) } '(n/a)' }

# Build INDEX as a real array
$idx = @()
$idx += '# Drive Deep Dive — Index'
$idx += ''
$idx += ('Updated: {0:yyyy-MM-dd HH:mm:ss}' -f $now)
$idx += ''
$idx += ('* **Latest Audit JSON** → `{0}`  (_{1}_)' -f $latestAudit.Path, (FmtDate $latestAudit.When))
$idx += ('* **Latest Apply Log** → `{0}`  (_{1}_)'  -f $latestApply.Path, (FmtDate $latestApply.When))
$idx += ('* **Latest Apply CSV** → `{0}`  (_{1}_)'  -f $latestCsv.Path,   (FmtDate $latestCsv.When))
$idx += ('* **Latest Policy Snapshot** → `{0}`  (_{1}_)' -f $latestSnap.Path, (FmtDate $latestSnap.When))
$idx += ('* **Latest Policy Diff** → `{0}`' -f $latestDiff.Path)
$idx += ''
$idx += 'Scripts: `1-Scripts\`  | Logs: `2-Logs\`  | Quarantine: `3-Quarantine (Pack Specific)\`  | Restores: `4-Restores\`'
Write-Utf8 -Path $index -Lines $idx

# Build README as a real array
$mr = @()
$mr += '# Home_PC_Storage_Cleanup_Master_README (Auto)'
$mr += ''
$mr += 'This README is auto-refreshed by Update-IndexAndReadme.ps1.'
$mr += ''
$mr += '## Quick Links'
$mr += ('- Latest Apply Log → `{0}`'          -f $latestApply.Path)
$mr += ('- Latest Apply CSV → `{0}`'          -f $latestCsv.Path)
$mr += ('- Latest Policy Snapshot → `{0}`'    -f $latestSnap.Path)
$mr += ('- Latest Policy Diff → `{0}`'        -f $latestDiff.Path)
$mr += ''
$mr += '## Notes'
$mr += '- DRY-first pipeline active.'
$mr += '- Exclusions honored via `apply_exclusions.json`.'
$mr += '- Archives compacted safely (only empties outside `RegBackups/`).'

Write-Utf8 -Path $readme -Lines $mr

Write-Host "Refreshed: $index"  -ForegroundColor Green
Write-Host "Refreshed: $readme" -ForegroundColor Green
