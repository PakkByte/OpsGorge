[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string]$AuditJson,
  [int]$MinSizeMB = 100
)
$ErrorActionPreference = "Stop"
$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$apply  = Join-Path $here "B-Apply_DeepDive_Audit.ps1"
$exFile = Join-Path $here "apply_exclusions.json"

if (-not (Test-Path $apply))     { throw "Apply script missing: $apply" }
if (-not (Test-Path $AuditJson)) { throw "Audit JSON missing: $AuditJson" }

$ex = @{ skipPaths=@(); skipTypes=@() }
if (Test-Path $exFile) { try { $ex = Get-Content -Raw -LiteralPath $exFile | ConvertFrom-Json } catch {} }

function Test-UnderSkipPath([string]$p){
  if (-not $p) {return $false}
  foreach($sp in $ex.skipPaths){
    if ([string]::IsNullOrWhiteSpace($sp)) {continue}
    $spn = ($sp -replace '/','\'); if (-not $spn.EndsWith('\')){$spn += '\'}
    $pn  = ($p  -replace '/','\')
    if ($pn.StartsWith($spn,[StringComparison]::OrdinalIgnoreCase)) {return $true}
  }
  return $false
}

$items = Get-Content -Raw -LiteralPath $AuditJson | ConvertFrom-Json
$keep,$skip = @(),@()
foreach($n in $items){ if (Test-UnderSkipPath $n.Path -or ($ex.skipTypes -contains $n.Type)) { $skip += $n } else { $keep += $n } }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logs  = Split-Path -Parent $AuditJson
$filt  = Join-Path $logs "cleanup_audit_filtered_$stamp.json"
$keep | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $filt -Encoding UTF8
Write-Host "[prefilter] input:$($items.Count) skip:$($skip.Count) keep:$($keep.Count) -> $filt" -ForegroundColor Cyan

# DRY by default; -Execute must be passed to B-Apply_DeepDive_Audit.ps1 explicitly
& $apply -AuditJson $filt -MinSizeMB $MinSizeMB
