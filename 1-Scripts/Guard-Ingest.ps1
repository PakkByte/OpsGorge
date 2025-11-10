<#
Blocks accidental re-triage of an already-promoted _ingest batch.
#>

[CmdletBinding()]
param(
  [string]$StagingRoot = 'D:\Repos\OpsGorgeStaging',
  [switch]$ShowWhy
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-LatestIngest {
  param([string]$Root)
  $ing = Join-Path $Root '_ingest'
  if (-not (Test-Path -LiteralPath $ing)) { throw "No _ingest folder under: $Root" }
  $dir = Get-ChildItem -LiteralPath $ing -Directory |
         Sort-Object LastWriteTime -Descending |
         Select-Object -First 1
  if (-not $dir) { throw "No From_* batch folders under: $ing" }
  return $dir
}

$batch  = Get-LatestIngest -Root $StagingRoot
$marker = Join-Path $batch.FullName '_PROMOTED.ok'

if (Test-Path -LiteralPath $marker) {
  Write-Error ("Batch already promoted: {0}`nMarker: {1}" -f $batch.FullName,$marker)
  if ($ShowWhy) {
    Write-Host "`n== Marker details ==" -ForegroundColor Yellow
    Get-Content -LiteralPath $marker -ErrorAction SilentlyContinue | Write-Host
  }
  exit 2
}

Write-Host ("OK to proceed on batch: {0}" -f $batch.FullName) -ForegroundColor Green
