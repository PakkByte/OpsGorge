<# ======================================================================
DeepRepoAudit.ps1  —  Deep inventory + dupe/delta detector (PowerShell 7+)
====================================================================== #>

[CmdletBinding()]
param(
  [string[]]$Roots = @('D:\Repos\OpsGorge','D:\UserData','D:\_Archives'),
  [switch]$HashLarge,
  [string]$HashAlgo = 'SHA256',
  [int]$MaxParallel = 6,
  [string]$LogRoot = 'D:\Repos\OpsGorge\2-Logs'
)

function New-Dir([string]$p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Flatten-Path([string]$p){ return ($p -replace '/','\').ToLowerInvariant() }

function Get-LastInventoryFile([string]$logRoot){
  $dirs = Get-ChildItem -Path $logRoot -Directory -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -like 'inventory_*' } |
          Sort-Object Name -Descending
  foreach($d in $dirs){
    $f = Join-Path $d.FullName 'inventory.json'
    if(Test-Path $f){ return $f }
  }
  return $null
}

function Load-PreviousAssessment([string]$logRoot){
  $dirs = Get-ChildItem -Path $logRoot -Directory -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -like 'assessment_*' } |
          Sort-Object Name -Descending
  foreach($d in $dirs){
    $f = Join-Path $d.FullName 'assessment.json'
    if(Test-Path $f){
      try { return Get-Content -Raw -LiteralPath $f | ConvertFrom-Json -Depth 50 } catch { return $null }
    }
  }
  return $null
}

# --- Prep output dirs
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
New-Dir $LogRoot
$invDir = Join-Path $LogRoot ("inventory_{0}" -f $ts)
New-Dir $invDir

Write-Host "Scanning roots: $($Roots -join ', ')" -ForegroundColor Cyan

# --- Parallel scan (job script defines its own helper)
$scanScript = {
  param($root,$HashAlgo,$HashLarge)

  function Safe-GetFileHash {
    param([string]$Path,[string]$Algorithm='SHA256',[switch]$DoLarge)
    try {
      $fi = Get-Item -LiteralPath $Path -ErrorAction Stop
      if(-not $DoLarge -and $fi.Length -gt 1GB){
        return [pscustomobject]@{ Algorithm=$Algorithm; Hash=$null; Reason='Size>1GB'; Length=$fi.Length }
      }
      $h = Get-FileHash -LiteralPath $Path -Algorithm $Algorithm -ErrorAction Stop
      return [pscustomobject]@{ Algorithm=$h.Algorithm; Hash=$h.Hash; Reason=$null; Length=$fi.Length }
    } catch {
      return [pscustomobject]@{ Algorithm=$Algorithm; Hash=$null; Reason=$_.Exception.Message; Length=0 }
    }
  }

  Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    $h = Safe-GetFileHash -Path $_.FullName -Algorithm $HashAlgo -DoLarge:$HashLarge
    [pscustomobject]@{
      Root           = $root
      FullName       = $_.FullName
      PathNorm       = ( ($_.FullName -replace '/','\').ToLowerInvariant() )
      Dir            = $_.DirectoryName
      Name           = $_.Name
      Extension      = $_.Extension.ToLowerInvariant()
      Length         = $_.Length
      LastWriteTime  = $_.LastWriteTimeUtc.ToString('o')
      CreatedTime    = $_.CreationTimeUtc.ToString('o')
      HashAlgo       = $h.Algorithm
      Hash           = $h.Hash
      HashNote       = $h.Reason
    }
  }
}

$jobs = foreach($r in $Roots){
  Start-ThreadJob -ScriptBlock $scanScript -ArgumentList $r,$HashAlgo,$HashLarge.IsPresent
}

try {
  $inv = Receive-Job -Job $jobs -Wait -AutoRemoveJob
} finally {
  $jobs | Remove-Job -Force -ErrorAction SilentlyContinue
}

$inv = $inv | Sort-Object FullName

# --- Lookups
$byHash = $inv | Where-Object { $_.Hash } | Group-Object -Property Hash
$byPath = @{}
foreach($i in $inv){ $byPath[(Flatten-Path $i.FullName)] = $i }

# --- Load previous snapshot & assessment
$lastInvPath = Get-LastInventoryFile -logRoot $LogRoot
$prevInv = $null
if($lastInvPath){
  try { $prevInv = Get-Content -Raw -LiteralPath $lastInvPath | ConvertFrom-Json -Depth 100 } catch {}
}
$prevPaths = @{}
if($prevInv){
  foreach($p in $prevInv){ $prevPaths[(Flatten-Path $p.FullName)] = $p }
}

$prevAssess = Load-PreviousAssessment -logRoot $LogRoot
$assessedPaths = @{}
if($prevAssess -and $prevAssess.files){
  foreach($kv in $prevAssess.files.PSObject.Properties){
    foreach($entry in $kv.Value){
      # best effort mapping back to repo (this is just for "already looked" counts)
      $assessedPaths[(Flatten-Path $entry.path)] = $true
    }
  }
}

# --- Delta
$newFiles      = New-Object System.Collections.Generic.List[object]
$removedFiles  = New-Object System.Collections.Generic.List[object]
$modifiedFiles = New-Object System.Collections.Generic.List[object]
$unchanged     = New-Object System.Collections.Generic.List[object]
$alreadyLooked = New-Object System.Collections.Generic.List[object]

foreach($p in $byPath.Keys){
  $cur = $byPath[$p]
  if($prevPaths.ContainsKey($p)){
    $old = $prevPaths[$p]
    if( ($old.Hash -and $cur.Hash -and $old.Hash -ne $cur.Hash) -or
        ($old.Length -ne $cur.Length) -or
        ($old.LastWriteTime -ne $cur.LastWriteTime) ){
      $modifiedFiles.Add([pscustomobject]@{ Current=$cur; Previous=$old })
    } else {
      $unchanged.Add($cur)
    }
  } else {
    $newFiles.Add($cur)
  }
  if($assessedPaths.ContainsKey($p)){ $alreadyLooked.Add($cur) }
}

foreach($p in $prevPaths.Keys){
  if(-not $byPath.ContainsKey($p)){ $removedFiles.Add($prevPaths[$p]) }
}

# --- Dupes
$dupeGroups = @()
foreach($g in $byHash){
  if($g.Count -gt 1){
    $items = $g.Group | Sort-Object { [datetime]::Parse($_.LastWriteTime) }
    $latest = $items[-1]
    $dupeGroups += [pscustomobject]@{
      Hash       = $g.Name
      Count      = $g.Count
      LatestPath = $latest.FullName
      LatestTime = $latest.LastWriteTime
      Members    = $items | ForEach-Object {
        [pscustomobject]@{
          FullName      = $_.FullName
          LastWriteTime = $_.LastWriteTime
          Length        = $_.Length
          IsLatest      = ($_.FullName -eq $latest.FullName)
          Root          = $_.Root
        }
      }
    }
  }
}

# --- Write outputs
$invJson   = Join-Path $invDir 'inventory.json'
$invCsv    = Join-Path $invDir 'inventory.csv'
$dupJson   = Join-Path $invDir 'dupes.json'
$dupCsv    = Join-Path $invDir 'dupes.csv'
$deltaJson = Join-Path $invDir 'delta.json'
$deltaCsv  = Join-Path $invDir 'delta.csv'
$summaryMd = Join-Path $invDir 'summary.md'

$inv | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $invJson -Encoding UTF8
$inv | Select-Object Root,FullName,Length,LastWriteTime,HashAlgo,Hash,HashNote |
  Export-Csv -Path $invCsv -Encoding UTF8 -NoTypeInformation

$dupeGroups | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $dupJson -Encoding UTF8
$dupeGroups | ForEach-Object {
  foreach($m in $_.Members){
    [pscustomobject]@{
      Hash=$_.Hash; LatestPath=$_.LatestPath; LatestTime=$_.LatestTime;
      FullName=$m.FullName; LastWriteTime=$m.LastWriteTime; Length=$m.Length; IsLatest=$m.IsLatest; Root=$m.Root
    }
  }
} | Export-Csv -Path $dupCsv -Encoding UTF8 -NoTypeInformation

$deltaObj = [pscustomobject]@{
  New        = $newFiles
  Removed    = $removedFiles
  Modified   = $modifiedFiles
  Unchanged  = $unchanged.Count
  AlreadySeen= $alreadyLooked.Count
}
$deltaObj | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $deltaJson -Encoding UTF8

$rows = @()
$rows += $newFiles      | ForEach-Object { [pscustomobject]@{ Status='NEW';      Path=$_.FullName;  Length=$_.Length;  LastWrite=$_.LastWriteTime; Root=$_.Root } }
$rows += $removedFiles  | ForEach-Object { [pscustomobject]@{ Status='REMOVED';  Path=$_.FullName;  Length=$_.Length;  LastWrite=$_.LastWriteTime; Root=$_.Root } }
$rows += $modifiedFiles | ForEach-Object { [pscustomobject]@{ Status='MODIFIED'; Path=$_.Current.FullName; Length=$_.Current.Length; LastWrite=$_.Current.LastWriteTime; Root=$_.Current.Root } }
$rows | Export-Csv -Path $deltaCsv -Encoding UTF8 -NoTypeInformation

$lines = @()
$lines += "# Deep Repo Audit — $ts"
$lines += ""
$lines += "Roots: $($Roots -join ', ')"
$lines += ""
$lines += "## Counts"
$lines += ("- Files scanned: {0}" -f $inv.Count)
$lines += ("- New vs last snapshot: {0}" -f $newFiles.Count)
$lines += ("- Modified vs last snapshot: {0}" -f $modifiedFiles.Count)
$lines += ("- Removed vs last snapshot: {0}" -f $removedFiles.Count)
$lines += ("- Unchanged: {0}" -f $unchanged.Count)
$lines += ("- Already looked (from prior assessment listing): {0}" -f $alreadyLooked.Count)
$lines += ("- Dupe groups: {0}" -f $dupeGroups.Count)
$lines += ""
$lines += "## Notes"
$lines += "- Large files (>1GB) hashing is " + ($(if($HashLarge){"ENABLED"} else {"SKIPPED (size/timestamp only)"}))
$lines += "- Latest prior snapshot: " + ($(if($lastInvPath){ Split-Path -Leaf (Split-Path -Parent $lastInvPath) } else { "(none)" }))
$lines += ""
$lines += "## Next steps"
$lines += "- Review dupes.csv; consider keeping only the LatestPath per hash."
$lines += "- Review delta.csv for unexpected NEW/MODIFIED/REMOVED."
$lines += "- Re-run with -HashLarge to hash >1GB files if needed."
$lines += ""
$lines -join "`r`n" | Set-Content -LiteralPath $summaryMd -Encoding UTF8

Write-Host "`n=== Deep Repo Audit complete ===" -ForegroundColor Cyan
Write-Host ("Inventory: {0}" -f $invJson)
Write-Host ("Dupes:    {0}" -f $dupJson)
Write-Host ("Delta:    {0}" -f $deltaJson)
Write-Host ("Summary:  {0}" -f $summaryMd)
