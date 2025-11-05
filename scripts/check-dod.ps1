param(
  [Parameter(Mandatory=$false)]
  [string]$RepoRoot = (Get-Location).Path,

  [Parameter(Mandatory=$false)]
  [string[]]$LogsGlob    = @('**/2-Logs/*'),

  [Parameter(Mandatory=$false)]
  [string[]]$IgnoreGlobs = @(),

  [switch]$Strict
)

Write-Host "== DoD Core verification =="

# 1) Signed commits gate (informational; enforcement via branch protection)
Write-Host "[Info] Signed commits should be enforced via branch protection."

# 2) Lightweight secret scan (ignore this script, .git, node_modules)
$patterns = @(
  'AKIA[0-9A-Z]{16}',             # AWS access key
  'AIza[0-9A-Za-z\-_]{35}',       # Google API key
  'ghp_[0-9A-Za-z]{36}',          # GitHub PAT
  'xox[baprs]-[0-9A-Za-z-]{10,48}'# Slack token
) | ForEach-Object { [regex]$_ }

$all = Get-ChildItem -Recurse -File -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notmatch '\\node_modules\\' }

# Build ignore list (always ignore this script)
$ignore = New-Object System.Collections.Generic.HashSet[string] ([StringComparer]::OrdinalIgnoreCase)
$ignore.Add($PSCommandPath) | Out-Null

foreach ($g in $IgnoreGlobs) {
  # very simple glob→regex for **,*,?
  $rx = '^' + [regex]::Escape(($g -replace '\*\*','(?>.*)' -replace '\*','[^\\\/]*' -replace '\?','.')) + '$'
  foreach ($f in $all) {
    if ($f.FullName -match $rx) { $ignore.Add($f.FullName) | Out-Null }
  }
}

$hits = @()
foreach ($f in $all) {
  if ($ignore.Contains($f.FullName)) { continue }
  $text = try { Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop } catch { '' }
  foreach ($re in $patterns) {
    if ($re.IsMatch($text)) { $hits += $f.FullName; break }
  }
}

if ($hits.Count -gt 0) {
  $msg = "Potential secrets detected in:`n - " + ($hits -join "`n - ")
  if ($Strict) { Write-Error -Message $msg; exit 1 } else { Write-Warning $msg }
}

# 3) Restore-map presence (only warn in bootstrap)
$restore = $all | Where-Object { $_.FullName -match '\\2-Logs\\restore_map_.*\.json$' }
if (-not $restore) {
  $msg = "No restore_map_*.json found in 2-Logs (bootstrap ok)."
  if ($Strict) { Write-Error -Message $msg; exit 1 } else { Write-Warning $msg }
}

Write-Host "DoD checks completed."
exit 0
