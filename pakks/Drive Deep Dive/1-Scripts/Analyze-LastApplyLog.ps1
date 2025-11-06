[CmdletBinding()]
param(
  [string]$LogsRoot = (Join-Path (Split-Path (Split-Path -Parent $MyInvocation.MyCommand.Path)) "2-Logs")
)
$log = Get-ChildItem $LogsRoot -Filter "Apply_*.txt" | Sort-Object LastWriteTime -Desc | Select-Object -First 1
if (-not $log){ Write-Host "No Apply logs found." -ForegroundColor Yellow; return }
$rows = @()
$pattern = '^\s*(MOVE|WARNING|SKIP|What if:|== SUMMARY ==|Archived|KeepOrLink|Duplicates|DeadLnk|StaleUninst).*'
Get-Content -LiteralPath $log.FullName | ForEach-Object {
  if ($_ -match $pattern){ $rows += [pscustomobject]@{ Line = $_ } }
}
$out = Join-Path $LogsRoot ("Apply_Summary_{0}.csv" -f ((Get-Date).ToString("yyyyMMdd-HHmmss")))
$rows | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
Write-Host "CSV -> $out" -ForegroundColor Green
