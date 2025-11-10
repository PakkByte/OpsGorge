param([string]$Strict = "-strict")
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$target = Join-Path $root "1-Scripts\check-dod.ps1"
if(-not (Test-Path $target)){ Write-Error "check-dod.ps1 not found"; exit 1 }
& pwsh -NoProfile -File $target $Strict; exit $LASTEXITCODE
