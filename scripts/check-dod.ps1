[CmdletBinding()]
param([switch]$Strict)

$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$root   = Split-Path -Parent $here
$target = Join-Path $root "1-Scripts\check-dod.ps1"
if (-not (Test-Path $target)) { Write-Error "check-dod.ps1 not found at $target"; exit 1 }

$argv = @()
if ($Strict) { $argv += "-Strict" }

& pwsh -NoProfile -File $target @argv
exit $LASTEXITCODE
