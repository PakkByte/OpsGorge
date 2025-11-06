<# ===================== Analyze_LastApplyLog.ps1 =====================
Purpose: Inspect the most recent Apply_*.txt log and summarize:
  - Nested archive / destination-subdirectory errors
  - MOVE / QUAR / DELETE tallies
  - Final SUMMARY block (if present)
Also writes a JSON summary next to the log file.

Usage:
  & "D:\UserData\Pakks\Drive Deep Dive\1-Scripts\Analyze_LastApplyLog.ps1"
  # or with explicit file:
  & "...\Analyze_LastApplyLog.ps1" -LogFile "D:\...\2-Logs\Apply_20251102-102250.txt"
===================================================================== #>

[CmdletBinding()]
param(
  [string]$PackRoot = 'D:\UserData\Pakks\Drive Deep Dive',
  [string]$LogFile
)

$ErrorActionPreference = 'Stop'
$LogsDir = Join-Path $PackRoot '2-Logs'

# 1) Resolve which log to analyze
if (-not $LogFile) {
  $latest = Get-ChildItem -LiteralPath $LogsDir -Filter 'Apply_*.txt' -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $latest) { throw "No Apply_*.txt logs found under $LogsDir." }
  $LogFile = $latest.FullName
}
if (-not (Test-Path -LiteralPath $LogFile)) { throw "Log not found: $LogFile" }

Write-Host ("[scan] {0}" -f $LogFile) -ForegroundColor Cyan

# 2) Load lines
$lines = Get-Content -LiteralPath $LogFile -ErrorAction Stop

# 3) Tally actions
$rxMove   = '^\s*MOVE\s*->'
$rxQuar   = '^\s*QUAR\s*->'
$rxDelete = '^\s*DELETE\s*->'

$moveHits   = Select-String -InputObject $lines -Pattern $rxMove
$quarHits   = Select-String -InputObject $lines -Pattern $rxQuar
$deleteHits = Select-String -InputObject $lines -Pattern $rxDelete

# 4) Look for nested-archive/blocked-destination errors
#    We handle both PowerShell Move-Item errors and our guard messages.
$errPatterns = @(
  'Destination path cannot be a subdirectory',
  'NESTED-ARCHIVE BLOCKED'
)
$errHits = @()
foreach ($p in $errPatterns) {
  $errHits += Select-String -InputObject $lines -Pattern $p
}

# Try to extract SRC/DST if our guard printed them like "SRC=..., DST=..."
$errDetails = @()
foreach ($hit in $errHits) {
  $txt = $hit.Line
  $src = $null; $dst = $null
  if ($txt -match 'SRC\s*=\s*([^\|]+)') { $src = $Matches[1].Trim() }
  if ($txt -match 'DST\s*=\s*(.+)$')    { $dst = $Matches[1].Trim() }
  $errDetails += [pscustomobject]@{
    LineNumber = $hit.LineNumber
    Text       = $txt
    SRC        = $src
    DST        = $dst
  }
}

# 5) Extract SUMMARY block if present
$summaryBlock = @()
$startIdx = ($lines | Select-String -Pattern '^\s*==\s*SUMMARY\s*==' | Select-Object -First 1).LineNumber
if ($startIdx) {
  for ($i = $startIdx; $i -le $lines.Count; $i++) {
    $line = $lines[$i-1]
    if ([string]::IsNullOrWhiteSpace($line)) { break }
    $summaryBlock += $line
  }
}

# 6) Build structured summary
$report = [ordered]@{
  LogFile         = $LogFile
  MoveCount       = $moveHits.Count
  QuarantineCount = $quarHits.Count
  DeleteCount     = $deleteHits.Count
  Errors          = @()
  SummaryLines    = $summaryBlock
}

foreach ($e in $errDetails) {
  $report.Errors += [ordered]@{
    Line = $e.LineNumber
    Text = $e.Text
    SRC  = $e.SRC
    DST  = $e.DST
  }
}

# 7) Print human-readable view
Write-Host "`n== ACTION TALLY ==" -ForegroundColor Green
"{0,-12} : {1}" -f 'MOVE',   $report.MoveCount
"{0,-12} : {1}" -f 'QUAR',   $report.QuarantineCount
"{0,-12} : {1}" -f 'DELETE', $report.DeleteCount

if ($report.Errors.Count -gt 0) {
  Write-Host "`n== ERRORS ==" -ForegroundColor Yellow
  foreach ($e in $report.Errors) {
    Write-Host ("[line {0}] {1}" -f $e.Line, $e.Text)
    if ($e.SRC -or $e.DST) {
      Write-Host ("      SRC: {0}" -f ($e.SRC ?? '<unknown>'))
      Write-Host ("      DST: {0}" -f ($e.DST ?? '<unknown>'))
    }
  }
} else {
  Write-Host "`n== ERRORS ==" -ForegroundColor Yellow
  Write-Host "None detected."
}

if ($report.SummaryLines -and $report.SummaryLines.Count) {
  Write-Host "`n== SUMMARY BLOCK ==" -ForegroundColor Cyan
  $report.SummaryLines | ForEach-Object { Write-Host $_ }
} else {
  Write-Host "`n(no explicit SUMMARY block found; counts above reflect tallies)" -ForegroundColor DarkGray
}

# 8) Save JSON next to the log (ApplySummary_<stamp>.json)
$stamp = (Split-Path $LogFile -Leaf) -replace '^Apply_(\d{8}-\d{6})\.txt$','$1'
if ($stamp -eq (Split-Path $LogFile -Leaf)) { $stamp = (Get-Date -Format 'yyyyMMdd-HHmmss') }
$outJson = Join-Path (Split-Path $LogFile -Parent) ("ApplySummary_{0}.json" -f $stamp)
$report | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 -LiteralPath $outJson
Write-Host ("`n[save] Summary JSON -> {0}" -f $outJson) -ForegroundColor DarkCyan

# 9) If we saw nested-archive symptoms, print a ready-to-paste exclusion hint
if ($report.Errors.Count -gt 0) {
  Write-Host "`n== SUGGESTED EXCLUSIONS (if DST falls under a source you don't want touched) ==" -ForegroundColor Magenta
  Write-Host "Edit: D:\UserData\Pakks\Drive Deep Dive\1-Scripts\apply_exclusions.json"
  Write-Host 'Add (examples):'
  Write-Host '  {'
  Write-Host '    "skipPaths": ['
  Write-Host '      "D:\\UserData\\Archives\\",'
  Write-Host '      "D:\\UserData\\Pakks\\Drive Deep Dive\\3-Quarantine (Pack Specific)\\"'
  Write-Host '    ],'
  Write-Host '    "skipTypes": []'
  Write-Host '  }'
}
