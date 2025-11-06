[CmdletBinding()]
param(
  [string]$ScriptsRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path),
  [string]$OutDir = (Join-Path (Split-Path $ScriptsRoot) "2-Logs")
)
$Policy = Join-Path $ScriptsRoot "Policy.json"
$Excl   = Join-Path $ScriptsRoot "apply_exclusions.json"
$stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$dst    = Join-Path $OutDir "Policy_Snapshot_$stamp.json"
$obj = [ordered]@{}
foreach($p in @($Policy,$Excl)){
  if (Test-Path $p){
    $raw = Get-Content -Raw -LiteralPath $p
    $sha = [System.BitConverter]::ToString((New-Object System.Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($raw))).Replace("-","")
    $obj[(Split-Path $p -Leaf)] = @{ sha256=$sha; content=($raw | ConvertFrom-Json) }
  }
}
$obj | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $dst -Encoding UTF8
Write-Host "Snapshot -> $dst" -ForegroundColor Green
