[CmdletBinding()]
param(
  [string]$LogsRoot = (Join-Path (Split-Path (Split-Path -Parent $MyInvocation.MyCommand.Path)) "2-Logs")
)
$snaps = Get-ChildItem $LogsRoot -Filter "Policy_Snapshot_*.json" | Sort-Object LastWriteTime
if ($snaps.Count -lt 2){ Write-Host "Need 2+ snapshots for diff" -ForegroundColor Yellow; return }
$old = $snaps[$snaps.Count-2].FullName
$new = $snaps[$snaps.Count-1].FullName
$o = Get-Content -Raw -LiteralPath $old | ConvertFrom-Json
$n = Get-Content -Raw -LiteralPath $new | ConvertFrom-Json
$lines = @()
$lines += "Policy Diff"
$lines += "OLD: $old"
$lines += "NEW: $new"
$lines += ("-"*60)

function Compare-Objects($a,$b,$prefix){
  $keys = [System.Linq.Enumerable]::ToArray([System.Linq.Enumerable]::Distinct([string[]]($a.PSObject.Properties.Name + $b.PSObject.Properties.Name)))
  foreach($k in $keys){
    $av = $a.$k; $bv = $b.$k
    $path = "$prefix$k"
    if ($null -eq $av -and $null -eq $bv){ continue }
    elseif ($null -eq $av){ $lines += "ADD   : $path" }
    elseif ($null -eq $bv){ $lines += "REMOVE: $path" }
    elseif ($av -is [System.Management.Automation.PSObject] -or $av -is [hashtable]){
      Compare-Objects $av $bv "$path."
    } else {
      $sa = ($av | ConvertTo-Json -Depth 6)
      $sb = ($bv | ConvertTo-Json -Depth 6)
      if ($sa -ne $sb){ $lines += "CHANGE: $path" }
    }
  }
}

Compare-Objects $o $n ""
$out = Join-Path $LogsRoot ("Policy_Diff_{0}.txt" -f ((Get-Date).ToString("yyyyMMdd-HHmmss")))
$lines | Set-Content -LiteralPath $out -Encoding UTF8
Write-Host "Diff -> $out" -ForegroundColor Green
