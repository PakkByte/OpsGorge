[CmdletBinding()]
param(
  [string]$ArchiveRoot = "D:\_Archives",
  [switch]$Execute
)
$ErrorActionPreference = "Stop"
$runs = Get-ChildItem -LiteralPath $ArchiveRoot -Directory -ErrorAction SilentlyContinue
foreach($r in $runs){
  $kids = Get-ChildItem -LiteralPath $r.FullName -Directory -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -ne "RegBackups" }
  foreach($k in $kids){
    $hasFiles = (Get-ChildItem -LiteralPath $k.FullName -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1)
    if (-not $hasFiles){
      if ($Execute){ Remove-Item -LiteralPath $k.FullName -Recurse -Force; Write-Host "DEL -> $($k.FullName)" -ForegroundColor Yellow }
      else { Write-Host "DRY DEL -> $($k.FullName)" -ForegroundColor DarkYellow }
    }
  }
}
