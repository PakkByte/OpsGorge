param(
  [string]$ScanRoot              = 'D:\',
  [string]$ExcludeRoot           = 'D:\Repos',
  [string]$LogRoot               = 'D:\Repos\OpsGorgeStaging\2-Logs',
  [int]   $MaxPreviewKB          = 0,
  [int]   $LargeMB               = 200,
  [switch]$SkipHash,
  [string]$ExcludePatternsPath   = 'D:\Repos\OpsGorge\1-Scripts\scan_exclusions.txt'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

$ts    = Get-Date -Format 'yyyyMMdd-HHmmss'
$runId = "deep_inventory_${ts}"

$OutDir  = Join-Path $LogRoot $runId
$CSVPath = Join-Path $OutDir 'files_index.csv'
$MDPath  = Join-Path $OutDir 'summary.md'
$JSONL   = Join-Path $OutDir 'files.jsonl'
$ErrLog  = Join-Path $OutDir 'errors.log'
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

# --- Helpers ---------------------------------------------------------------
function Load-Excludes([string]$path){
  if(-not $path -or -not (Test-Path -LiteralPath $path)){ return @() }
  (Get-Content -LiteralPath $path | Where-Object { $_ -and $_ -notmatch '^\s*#' }) |
    ForEach-Object { $_.Trim() }
}
function Is-Excluded([string]$full,[string[]]$patterns){
  foreach($p in $patterns){ if($full -match $p){ return $true } }
  return $false
}
function Test-IsTextChunk([byte[]]$bytes){
  if(-not $bytes -or $bytes.Length -eq 0){ return $true }
  if(($bytes | Where-Object { $_ -eq 0 }).Count){ return $false }
  $nonPrintable = ($bytes | Where-Object { ($_ -lt 9) -or (($_ -gt 13) -and ($_ -lt 32)) }).Count
  ($nonPrintable / [double]$bytes.Length) -lt 0.05
}
function Get-TextPreview([string]$path,[int]$maxKB){
  if($maxKB -le 0){ return $null }
  try{
    $bytes = [IO.File]::ReadAllBytes($path)
    $take  = [Math]::Min($bytes.Length, $maxKB * 1024)
    if($take -le 0){ return $null }
    $head  = $bytes[0..($take-1)]
  } catch { return $null }
  if(-not (Test-IsTextChunk $head)){ return $null }
  try { [Text.Encoding]::UTF8.GetString($head) } catch { [Text.Encoding]::Default.GetString($head) }
}
function Safe-GetHash([string]$path){
  try { (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash } catch { $null }
}
function Append-JSONL([hashtable]$obj){
  try { ($obj | ConvertTo-Json -Depth 8 -Compress) + "`n" | Add-Content -LiteralPath $JSONL -Encoding UTF8 }
  catch { ("[{0}] JSONL write: {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $_.Exception.Message) | Add-Content -LiteralPath $ErrLog -Encoding UTF8 }
}
function Log-Error([string]$msg){
  ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg) | Add-Content -LiteralPath $ErrLog -Encoding UTF8
}
function CountOf($seq){ ($seq | Measure-Object).Count }

# --- Paths & excludes ------------------------------------------------------
$scanRootAbs    = (Resolve-Path $ScanRoot).Path
$excludeRootAbs = (Resolve-Path $ExcludeRoot).Path
$__ex           = Load-Excludes -path $ExcludePatternsPath

Write-Host "Scanning: $scanRootAbs" -ForegroundColor Cyan
Write-Host "Excluding subtree: $excludeRootAbs" -ForegroundColor Cyan
if($__ex.Count){ Write-Host ("Loaded {0} exclusion patterns" -f $__ex.Count) -ForegroundColor DarkCyan }
Write-Host "Logs → $OutDir" -ForegroundColor Cyan

# --- Enumerate -------------------------------------------------------------
$allFiles = Get-ChildItem -LiteralPath $scanRootAbs -Recurse -Force -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notlike "$excludeRootAbs*" -and -not (Is-Excluded $_.FullName $__ex) }

$allDirs  = Get-ChildItem -LiteralPath $scanRootAbs -Recurse -Force -Directory -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notlike "$excludeRootAbs*" -and -not (Is-Excluded $_.FullName $__ex) }

# --- Process files ---------------------------------------------------------
$rows = New-Object System.Collections.Generic.List[object]
$sw   = [Diagnostics.Stopwatch]::StartNew()
$proc = 0

foreach($f in $allFiles){
  try{
    $proc++; if(($proc % 1000) -eq 0){ Write-Host ("Processed {0:N0} files..." -f $proc) -ForegroundColor DarkGray }
    $hash    = $null; if(-not $SkipHash){ $hash = Safe-GetHash $f.FullName }
    $preview = Get-TextPreview -path $f.FullName -maxKB $MaxPreviewKB
    $row = [PSCustomObject]@{
      FullPath=$f.FullName; Directory=$f.DirectoryName; Name=$f.Name; Extension=$f.Extension
      SizeBytes=$f.Length; SizeMB=[Math]::Round($f.Length/1MB,3)
      CreatedUtc=$f.CreationTimeUtc.ToString('yyyy-MM-dd HH:mm:ssZ')
      ModifiedUtc=$f.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm:ssZ')
      Attributes=$f.Attributes.ToString(); Sha256=$hash
      IsTextPreview=[bool]$preview; PreviewSample=$preview
    }
    $rows.Add($row) | Out-Null
    Append-JSONL @{ type='file'; data=$row }
  } catch {
    Log-Error "File error [$($f.FullName)]: $($_.Exception.Message)"
  }
}

# --- Process dirs (for context in JSONL) -----------------------------------
foreach($d in $allDirs){
  try{
    $drow = [PSCustomObject]@{
      FullPath=$d.FullName; Name=$d.Name; Parent=$d.Parent
      CreatedUtc=$d.CreationTimeUtc.ToString('yyyy-MM-dd HH:mm:ssZ')
      ModifiedUtc=$d.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm:ssZ')
      Attributes=$d.Attributes.ToString()
    }
    Append-JSONL @{ type='dir'; data=$drow }
  } catch {
    Log-Error "Dir error [$($d.FullName)]: $($_.Exception.Message)"
  }
}

# --- Write outputs ---------------------------------------------------------
$sw.Stop()
$rows | Export-Csv -Path $CSVPath -NoTypeInformation -Encoding UTF8

$TotalFiles = $rows.Count
$TotalDirs  = $allDirs.Count
$LargeCount = CountOf ($rows | Where-Object { $_.SizeMB -ge $LargeMB })
$PreviewCnt = CountOf ($rows | Where-Object { $_.IsTextPreview })
$HashCnt    = CountOf ($rows | Where-Object { $_.Sha256 })
$ErrCnt     = (Test-Path $ErrLog) ? (CountOf (Get-Content $ErrLog)) : 0

$nl="`r`n"
$md = @()
$md += "# Deep Inventory — D:\ (excluding D:\Repos)"; $md += ""
$md += "**Run ID:** $runId  "; $md += ("**Elapsed:** {0} seconds  " -f [int]$sw.Elapsed.TotalSeconds)
$md += "**Files:** $TotalFiles  "; $md += "**Folders:** $TotalDirs  "
$md += "**Large (≥ ${LargeMB}MB):** $LargeCount  "; $md += "**Has SHA256:** $HashCnt  "
$md += "**Text previews:** $PreviewCnt  "; $md += "**Errors logged:** $ErrCnt  "; $md += ""
$md += "## Outputs"; $md += "- CSV: $(Split-Path $CSVPath -Leaf)"; $md += "- JSONL: $(Split-Path $JSONL -Leaf)"
if(Test-Path $ErrLog){ $md += "- Errors: $(Split-Path $ErrLog -Leaf)" }
$md -join $nl | Set-Content -LiteralPath $MDPath -Encoding UTF8

Write-Host "`n=== DONE ===" -ForegroundColor Green
Write-Host "CSV  => $CSVPath"; Write-Host "JSONL=> $JSONL"; Write-Host "MD   => $MDPath"
if(Test-Path $ErrLog){ Write-Host "ERR  => $ErrLog" }
