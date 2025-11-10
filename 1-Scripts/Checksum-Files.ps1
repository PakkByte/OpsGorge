param([string]$Root = "D:\UserData\Pakks\Drive Deep Dive")
$pol = Join-Path $Root '1-Scripts\Policy.json'
$ex  = Join-Path $Root '1-Scripts\apply_exclusions.json'
foreach($p in @($pol,$ex)){
  if(Test-Path $p){
    $h = (Get-FileHash $p -Algorithm SHA256).Hash
    "# sha256: $h  $(Split-Path $p -Leaf)" | Write-Host
  }
}
