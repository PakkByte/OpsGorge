[CmdletBinding(PositionalBinding=$false)]
param(
  [switch]$Strict,
  [switch]$ComparePolicyExclusions,
  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$Rest
)

$ErrorActionPreference = "Stop"
$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$root   = Split-Path -Parent $here
$target = Join-Path $root "1-Scripts\check-dod.ps1"
if (-not (Test-Path $target)) { Write-Error "check-dod.ps1 not found at $target"; exit 1 }

$args = @()
if ($Strict) { $args += '-Strict' }
if ($ComparePolicyExclusions) { $args += '-ComparePolicyExclusions' }
if ($Rest) { $args += $Rest }

& pwsh -NoProfile -File $target @args
exit $LASTEXITCODE
