<#  DeepInventory-Safe.ps1 — hardened v1.1
    Scans a drive (default D:\) excluding a subtree (default D:\Repos),
    writes CSV + JSONL + summary.md to LogRoot, and never assumes .Count on scalars.
#>

[CmdletBinding()]
param(
  [string]$ScanRoot       = 'D:\',
  [string]$ExcludeRoot    = 'D:\Repos',
  [string]$LogRoot        = 'D:\Repos\OpsGorgeStaging\2-Logs',
  [string]$ExcludeFile,
  [int]   $TextPreviewBytes = 0   # 0 = off
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Normalize-Array([object]$x) {
  if ($null -eq $x) { return @() }
  if ($x -is [System.Collections.IEnumerable] -and -not ($x -is [string])) { return @($x) }
  return @($x)
}
function Safe-Rel([string]$base,[string]$full) {
  try { return [IO.Path]::GetRelativePath($base,$full) } catch { return $full }
}

# --- Paths -------------------------------------------------------------------
$rootAbs    = (Resolve-Path -LiteralPath $ScanRoot).Path
$excludeAbs = $null
try { if (Test-Path -LiteralPath $ExcludeRoot) { $excludeAbs = (Resolve-Path -LiteralPath $ExcludeRoot).Path } } catch {}

$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$outDir = Join-Path $LogRoot "deep_inventory_$stamp"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

Write-Host ("Scanning everything under: {0}" -f $rootAbs) -ForegroundColor Cyan
if ($excludeAbs) { Write-Host ("Excluding subtree: {0}" -f $excludeAbs) -ForegroundColor Cyan }

# --- Load exclusions (optional) ----------------------------------------------
$ex = @()
if ($ExcludeFile) {
  try {
    if (Test-Path -LiteralPath $ExcludeFile) {
      $ex = Get-Content -LiteralPath $ExcludeFile -ErrorAction Stop |
            Where-Object { $_ -and $_.Trim() -ne '' } |
            ForEach-Object { $_.Trim() }
    }
  } catch { Write-Warning "ExcludeFile read failed: $($_.Exception.Message)" }
}
$ex = Normalize-Array $ex
Write-Host ("Loaded {0} exclusion patterns" -f ($ex | Measure-Object | Select-Object -ExpandProperty Count)) -ForegroundColor DarkCyan

# --- Collect files -----------------------------------------------------------
$files = @(Get-ChildItem -LiteralPath $rootAbs -Recurse -File -ErrorAction SilentlyContinue)

# exclude subtree
if ($excludeAbs) {
  $files = @($files | Where-Object { $_.FullName -notlike "$excludeAbs*" })
}

# apply pattern exclusions (substring)
if (($ex | Measure-Object).Count -gt 0) {
  $files = @($files | Where-Object {
    $p = $_.FullName
    -not ($ex | ForEach-Object { $p -like "*$_*" } | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count)
  })
}

# --- Emit CSV + JSONL --------------------------------------------------------
$csvPath = Join-Path $outDir 'files_index.csv'
$jsonl   = Join-Path $outDir 'files.jsonl'

$rows = @()
foreach ($f in $files) {
  $rows += [PSCustomObject]@{
    FullName  = $f.FullName
    Dir       = $f.DirectoryName
    Name      = $f.Name
    Ext       = $f.Extension.ToLowerInvariant()
    Size      = $f.Length
    LastWrite = $f.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm:ssZ')
    Sha256    = $null
  }
}

$rows | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

# JSONL (no BOM)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$sw = [System.IO.StreamWriter]::new($jsonl,$false,$utf8NoBom)
try {
  foreach($r in $rows) { $sw.WriteLine( ($r | ConvertTo-Json -Compress) ) }
} finally { $sw.Dispose() }

# --- Optional tiny previews --------------------------------------------------
if ($TextPreviewBytes -gt 0) {
  $previewCount = 0
  foreach ($f in $files) {
    try {
      if ($f.Length -gt 0 -and $f.Length -le 1048576) {
        $bytes = [IO.File]::ReadAllBytes($f.FullName)
        $n = [Math]::Min($TextPreviewBytes, $bytes.Length)
        $isText = ($bytes[0..([Math]::Min(512,[Math]::Max(0,$bytes.Length-1)))] -notcontains 0)
        if ($isText -and $n -gt 0) {
          $previewCount++
          $obj = [PSCustomObject]@{
            FullName = $f.FullName
            Preview  = [System.Text.Encoding]::UTF8.GetString($bytes,0,$n)
          }
          Add-Content -LiteralPath $jsonl -Value ($obj | ConvertTo-Json -Compress)
        }
      }
    } catch { }
  }
}

# --- Summary.md --------------------------------------------------------------
$filesCount   = ($files | Measure-Object).Count
$rowsCount    = ($rows  | Measure-Object).Count
$largeCount   = ($rows  | Where-Object { $_.Size -ge 200MB } | Measure-Object).Count

$sum   = Join-Path $outDir 'summary.md'
$lines = @()
$lines += "# Deep Inventory — $ScanRoot (excluding $ExcludeRoot)"
$lines += ""
$lines += ("**Run ID:** deep_inventory_{0}" -f $stamp)
$lines += ("**Files:** {0}" -f $rowsCount)
$lines += ("**Large (≥ 200MB):** {0}" -f $largeCount)
$lines += ("**Has SHA256:** 0")
$lines += ("**Text previews:** 0")
$lines += ("**Errors logged:** 0")
$lines += ""
$lines += "## Outputs"
$lines += ("- **CSV:** {0}"   -f (Safe-Rel $outDir $csvPath))
$lines += ("- **JSONL:** {0}" -f (Safe-Rel $outDir $jsonl))
$lines -join "`r`n" | Set-Content -LiteralPath $sum -Encoding UTF8

Write-Host ("CSV   => {0}" -f $csvPath) -ForegroundColor Green
Write-Host ("JSONL => {0}" -f $jsonl)   -ForegroundColor Green
Write-Host ("MD    => {0}" -f $sum)     -ForegroundColor Green
Write-Host ("Logs  → {0}" -f $outDir)   -ForegroundColor Cyan
