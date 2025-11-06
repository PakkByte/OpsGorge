[CmdletBinding()]
param(
  [string]$LogsRoot = (Join-Path (Split-Path (Split-Path -Parent $MyInvocation.MyCommand.Path)) "2-Logs"),
  [switch]$Latest,
  [string]$RunStamp,
  [switch]$WhatIf
)
$map = $null
if ($Latest){
  $map = Get-ChildItem $LogsRoot -Filter "restore_map_*.json" | Sort-Object LastWriteTime -Desc | Select-Object -First 1
} elseif ($RunStamp) {
  $map = Join-Path $LogsRoot ("restore_map_{0}.json" -f $RunStamp)
}
if (-not $map){ Write-Host "No restore map found." -ForegroundColor Yellow; return }
$data = Get-Content -Raw -LiteralPath $map | ConvertFrom-Json
foreach($m in $data){
  $src = $m.Source; $dst = $m.Destination
  if ($WhatIf){ Write-Host "RESTORE (WhatIf): $src -> $dst" -ForegroundColor Cyan }
  else {
    New-Item -ItemType Directory -Force -Path (Split-Path $dst -Parent) | Out-Null
    Move-Item -LiteralPath $src -Destination $dst -Force
    Write-Host "RESTORE: $src -> $dst" -ForegroundColor Green
  }
}
