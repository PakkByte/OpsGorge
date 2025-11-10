@'
[CmdletBinding()]
param(
  [string]$Stamp,   # e.g. 20251102-102522; if omitted we infer from newest Apply_*.txt
  [string]$LogsRoot = "D:\UserData\Pakks\Drive Deep Dive\2-Logs"
)

$ErrorActionPreference = 'Stop'

# 1) Pick Apply log
$log = if ($Stamp) {
  Join-Path $LogsRoot ("Apply_{0}.txt" -f $Stamp)
} else {
  Get-ChildItem $LogsRoot -Filter 'Apply_*.txt' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1 -Expand FullName
}
if (-not $log -or -not (Test-Path -LiteralPath $log)) { throw "Apply log not found: $log" }

# 2) Infer stamp if needed
if (-not $Stamp) {
  $base = Split-Path $log -Leaf
  if ($base -match '^Apply_(\d{8}-\d{6})\.txt$') { $Stamp = $Matches[1] }
  else { throw "Cannot infer stamp from $base" }
}

# 3) Parse MOVE lines (both DRY and REAL forms)
#    DRY:  MOVE  -> SRC  DST  [### MB]
#    With WhatIf lines nearby; we ignore those. We want the SRC and DST after the arrow.
$lines = Get-Content -LiteralPath $log -Raw -Encoding UTF8 -EA Stop -ReadCount 0 -TotalCount 0
$mapItems = New-Object System.Collections.Generic.List[object]

# Regex captures: 'MOVE  -> <src>  <dst>  [..]'
$rx = [regex]'(?m)^\s*MOVE\s*->\s*(?<src>.+?)\s{2,}(?<dst>[A-Za-z]:\\.+?)\s{2,}\['

foreach ($m in $rx.Matches($lines)) {
  $src = $m.Groups['src'].Value.Trim()
  $dst = $m.Groups['dst'].Value.Trim()
  # normalize (strip any duplicated leaf that might appear in DRY paths later during restore)
  $mapItems.Add([pscustomobject]@{ fromPath = $dst; toPath = $src })
}

# 4) Write restore_map_<stamp>.json that Restore-FromQuarantine.ps1 expects
$map = [pscustomobject]@{ items = $mapItems }
$mapFile = Join-Path $LogsRoot ("restore_map_{0}.json" -f $Stamp)
$map | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -LiteralPath $mapFile

Write-Host "[map] $($mapItems.Count) entries -> $mapFile" -ForegroundColor Green
'@ | Set-Content -Encoding UTF8 -LiteralPath "D:\UserData\Pakks\Drive Deep Dive\1-Scripts\New-RestoreMapFromApplyLog.ps1"
