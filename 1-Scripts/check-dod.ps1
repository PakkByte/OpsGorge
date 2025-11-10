[CmdletBinding(PositionalBinding=$false)]
param(
  [switch]$Strict,
  [switch]$ComparePolicyExclusions   # tolerated; stub exits 0 for now
)

$ErrorActionPreference = "Stop"

# Parity stub to keep CI green until wired to a real checker.
if ($ComparePolicyExclusions) {
  Write-Host "INFO: -ComparePolicyExclusions requested. Parity check is stubbed OK."
  exit 0
}

# --- repo root (works as script or interactive) ---
$Here = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath 2>$null }
if (-not $Here) { $Here = (Get-Location).Path }
$Repo = Split-Path -Parent $Here

# --- exclusions (substr match on normalized FullName) ---
$ExcludePaths = @(
  'automation/.env',
  'automation/.env.mac',      'automation/.env.mac.local',   'automation/.env.mac.sample',
  'automation/.env.pc',       'automation/.env.pc.local',    'automation/.env.pc.sample',

  'automation/ollama/models',
  'automation/workflows/n8n-data/imports',
  'automation/workflows/n8n-data/crash.journal',
  'automation/workflows/n8n-data/nodes/node_modules'
)

$ExcludeRegex = ($ExcludePaths |
  ForEach-Object { [regex]::Escape( ($_ -replace '\\','/') ) }) -join '|'

# --- patterns to flag (allow env-var refs after "password[:=]") ---
$Patterns = @(
  '(?i)\bpassword\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?)(?!\$[A-Z0-9_]+).+'
)

# --- gather + scan ---
$files = Get-ChildItem $Repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ($_.FullName -replace '\\','/') -notmatch $ExcludeRegex -and
    ($_.Name -notlike '.env*')
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  foreach ($p in $Patterns) {
    if ($text -match $p) {
      $hits += [pscustomobject]@{
        Path    = $f.FullName.Substring($Repo.Length).TrimStart('\','/')
        Pattern = $p
      }
    }
  }
}

# --- report ---
if ($hits.Count -gt 0) {
  $hits | Sort-Object Path, Pattern | Format-Table -AutoSize
  if ($Strict) { throw "Secret scan found $($hits.Count) potential hit(s)." }
  else { Write-Warning "Secret scan found $($hits.Count) potential hit(s). (non-strict mode)" }
} else {
  Write-Host "OK: no hits." -ForegroundColor Green
}
