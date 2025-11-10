# QuickScanner-LargeFolders.ps1  (safe: writes one audit JSON; no changes)
$ErrorActionPreference='Stop'

# Settings you can tweak
$Roots   = @('D:\','T:\') | Where-Object { Test-Path $_ }
$MinGB   = 5        # flag folders >= this size
$Exclude = @(
  'D:\Windows','D:\Program Files','D:\Program Files (x86)',
  'D:\ProgramData','D:\Users\Public','D:\$Recycle.Bin',
  'D:\UserData\Pakks\Drive Deep Dive',   # your pack
  'D:\UserData\Archives'                 # your archive base
)

# Resolve logs folder like your other scripts
$PackRoot = 'D:\UserData\Pakks\Drive Deep Dive'
$LogsRoot = Join-Path $PackRoot '2-Logs'
New-Item -ItemType Directory -Force -Path $LogsRoot | Out-Null

function Is-Excluded([string]$p){
  foreach($ex in $Exclude){ if ($p -like ($ex + '*')) { return $true } }
  return $false
}
function Get-DirSizeBytes([string]$path){
  try { (Get-ChildItem -LiteralPath $path -Recurse -File -EA SilentlyContinue | Measure-Object Length -Sum).Sum } catch { 0 }
}

$items = @()

foreach($root in $Roots){
  # top-level and one level down tends to be enough signal/noise
  $cands = @(Get-ChildItem -LiteralPath $root -Directory -EA SilentlyContinue)
  foreach($d in $cands){
    if (Is-Excluded $d.FullName) { continue }
    # optionally peek one level deeper
    $level1 = @($d) + @(Get-ChildItem -LiteralPath $d.FullName -Directory -EA SilentlyContinue)
    foreach($dir in $level1){
      if (Is-Excluded $dir.FullName) { continue }
      $sz = Get-DirSizeBytes $dir.FullName
      if ($sz -ge ($MinGB * 1GB)){
        $items += [pscustomobject]@{
          Type      = 'LargeNonGames'
          Path      = $dir.FullName
          SizeBytes = $sz
          Notes     = ">= ${MinGB}GB"
          GroupId   = $null
        }
      }
    }
  }
}

# keep the harmless seed so the pipeline always has at least 1 record
$items += [pscustomobject]@{ Type='Keep'; Path=$env:TEMP; SizeBytes=0; Notes='seed'; GroupId=$null }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$out   = Join-Path $LogsRoot ("cleanup_audit_{0}.json" -f $stamp)
$items | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -LiteralPath $out
Write-Host "[+] Audit written -> $out  (items: $($items.Count))" -ForegroundColor Green
