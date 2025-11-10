# .github/workflows/resolve-checkdod.ps1
# Finds check-dod.ps1 in either legacy scripts/ or canonical 1-Scripts/ and runs it.
param([string]$Strict = '-strict')

$repoRoot = Split-Path -Parent $PSScriptRoot
$paths = @(
  Join-Path $repoRoot 'scripts\check-dod.ps1'),
  Join-Path $repoRoot '1-Scripts\check-dod.ps1'
) | Where-Object { Test-Path $_ }

if (-not $paths) {
  Write-Error "check-dod.ps1 not found in scripts/ or 1-Scripts/"
  exit 1
}

& pwsh -NoProfile -File $paths[0] $Strict
exit $LASTEXITCODE
