param(
  [string]$Root = "D:\UserData\Pakks\Drive Deep Dive"
)
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$bundleDir = Join-Path $Root ("5-Share\CoreBundle_{0}" -f $stamp)
$zipPath   = "$bundleDir.zip"
$pick = @{
  Policy           = Join-Path $Root '1-Scripts\Policy.json'
  Exclusions       = Join-Path $Root '1-Scripts\apply_exclusions.json'
  Index            = Join-Path $Root 'INDEX.md'
  MasterReadme     = Join-Path $Root 'Master README.md'
  MegaSeed         = Join-Path $Root 'Brain_MegaSeed.txt'
  MegaCapsule      = Join-Path $Root 'Brain_MegaCapsule.md'
  MegaBullets      = Join-Path $Root 'Brain_MegaBullets.txt'
  SuperSeedPolicy  = Join-Path $Root '1-Scripts\SuperSeed_Policy.json'
}
$logs = Join-Path $Root '2-Logs'
function Latest($pat){ Get-ChildItem $logs -Filter $pat -ErrorAction SilentlyContinue | Sort LastWriteTime | Select -Last 1 }
$latest = @{
  ApplyLog   = Latest 'Apply_*.txt'
  ApplyCSV   = Latest 'Apply_Summary_*.csv'
  Audit1     = Latest 'cleanup_audit_filtered_*.json'
  Audit2     = Latest 'cleanup_audit_*.json'
  Snapshot   = Latest 'Policy_Snapshot_*.json'
  Diff       = Latest 'Policy_Diff_*.txt'
}
ni $bundleDir -ItemType Directory -Force | Out-Null
$manifest = @()
foreach($k in $pick.Keys){
  if(Test-Path $pick[$k]){ Copy-Item $pick[$k] $bundleDir -Force; $manifest += "$k | $(Split-Path $pick[$k] -Leaf)" }
}
foreach($k in $latest.Keys){
  $f = $latest[$k]
  if($f){ Copy-Item $f.FullName $bundleDir -Force; $manifest += "$k | $($f.Name)" }
}
$manifest | Set-Content (Join-Path $bundleDir 'MANIFEST_Sources.md')
# checksums
Get-ChildItem $bundleDir -File | ForEach-Object {
  $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
  '{0}  {1}' -f $h, $_.Name
} | Set-Content (Join-Path $bundleDir 'SHA256SUMS.txt')
if(Test-Path $zipPath){ Remove-Item $zipPath -Force }
Compress-Archive -Path $bundleDir\* -DestinationPath $zipPath -Force
Write-Host "Core bundle ready:" $zipPath -ForegroundColor Green
