function Get-GoldenPath {
  param(
    [ValidateSet("allow","block")]
    [string]$Kind
  )
  $root = Split-Path -Parent $PSScriptRoot
  $local = Join-Path $root "config\golden.local\golden_${Kind}.csv"
  $sample = Join-Path $root "config\golden\golden_${Kind}.csv.sample"
  if (Test-Path $local) { return $local }
  if (Test-Path $sample){ return $sample }
  throw "Missing golden ${Kind} CSV (neither local nor sample found)."
}

function Load-GoldenCsv {
  param(
    [ValidateSet("allow","block")]
    [string]$Kind
  )
  $p = Get-GoldenPath -Kind $Kind
  Import-Csv -LiteralPath $p
}
