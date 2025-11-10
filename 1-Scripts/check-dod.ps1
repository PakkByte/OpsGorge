[CmdletBinding()]
param([switch]$Strict)

$ErrorActionPreference = "Stop"

# --- repo root (parent of 1-Scripts) ---
$Repo = Split-Path -Parent $PSScriptRoot

# --- exclusions (substr match on normalized FullName) ---
$ExcludePaths = @(
  # envs (we track only *.sample)
  "automation/.env",
  "automation/.env.mac", "automation/.env.mac.local", "automation/.env.mac.sample",
  "automation/.env.pc",  "automation/.env.pc.local",  "automation/.env.pc.sample",

  # runtime blobs / caches
  "automation/ollama/models",
  "automation/workflows/n8n-data/imports",
  "automation/workflows/n8n-data/crash.journal",
  "automation/workflows/n8n-data/nodes/node_modules"
)
$ExcludeRegex = (($ExcludePaths | ForEach-Object { [regex]::Escape(($_ -replace "\\","/")) }) -join "|")

# --- patterns to flag ---
# allow env-var references after password (e.g., ${POSTGRES_PASSWORD} or $POSTGRES_PASSWORD)
$Patterns = @(
  '(?i)\bpassword\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?)(?!\$[A-Z0-9_]+).+'
)

# --- gather candidates ---
$files = Get-ChildItem $Repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    (($_.FullName -replace "\\","/") -notmatch $ExcludeRegex) -and
    ($_.Name -notlike '.env*')
  }

# --- scan ---
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
if ($hits.Count) {
  $hits | Sort-Object Path, Pattern | Format-Table -AutoSize
  if ($Strict) { throw "Secret scan found $($hits.Count) potential hit(s)." }
  else { Write-Warning "Secret scan found $($hits.Count) potential hit(s). (non-strict mode)" }
} else {
  Write-Host "OK: no hits." -ForegroundColor Green
}
