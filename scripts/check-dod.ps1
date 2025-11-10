[CmdletBinding()]
param(
  [switch]$Strict,
  [switch]$ComparePolicyExclusions, # accepted but intentionally ignored
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)
$ErrorActionPreference = "Stop"

$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$root   = Split-Path -Parent $here
$target = Join-Path $root "1-Scripts\check-dod.ps1"
if (-not (Test-Path $target)) { Write-Error "check-dod.ps1 not found at $target"; exit 1 }

# Build forward args: keep -Strict if set, drop -ComparePolicyExclusions, pass through $Rest
$forward = @()
if ($Strict) { $forward += '-Strict' }
# (ComparePolicyExclusions intentionally not forwarded)
$forward += $Rest

& pwsh -NoProfile -File $target @forward
exit $LASTEXITCODE
