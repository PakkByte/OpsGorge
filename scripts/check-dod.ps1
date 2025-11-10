# Wrapper: keep legacy CI path working; forward to 1-Scripts\check-dod.ps1
$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$root   = Resolve-Path (Join-Path $here '..')
$target = Join-Path $root '1-Scripts\check-dod.ps1'

if (Test-Path $target) {
  & $target @args
  exit $LASTEXITCODE
} else {
  Write-Error "Missing $target"
  exit 1
}
