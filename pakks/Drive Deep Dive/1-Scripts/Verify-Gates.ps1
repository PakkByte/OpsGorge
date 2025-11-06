param([string]$Root = "D:\UserData\Pakks\Drive Deep Dive")
$pol = Get-Content (Join-Path $Root '1-Scripts\Policy.json') -Raw | ConvertFrom-Json
$ex  = Get-Content (Join-Path $Root '1-Scripts\apply_exclusions.json') -Raw | ConvertFrom-Json
$logs= Join-Path $Root '2-Logs'
$archLine = Select-String -Path "$logs\Apply_*.txt" -Pattern '^>>> Archive:' | Select-Object -Last 1
$minLine  = Select-String -Path "$logs\Apply_*.txt" -Pattern '^>>> MinSizeMB:' | Select-Object -Last 1
$runnerArchive = ($archLine.Line -replace '>>> Archive:\s*','').Trim()
$runnerMin     = [int]($minLine.Line -replace '[^\d]','')
$fail = @()
if(-not $pol.ArchiveBase){ $fail += 'Policy.ArchiveBase missing' }
if($pol.ArchiveBase -ne 'D:\_Archives'){ $fail += "ArchiveBase mismatch: $($pol.ArchiveBase)" }
if($pol.DuplicateRules.MinSizeMB -ne 100){ $fail += "Policy MinSizeMB != 100 (is $($pol.DuplicateRules.MinSizeMB))" }
if($runnerMin -ne 100){ $fail += "Runner MinSizeMB != 100 (is $runnerMin)" }
if($runnerArchive -notlike 'D:\_Archives*'){ $fail += "Runner Archive != D:\_Archives (is $runnerArchive)" }
$blanket = ($ex.skipPaths | ? { $_ -match '^D:\\\\UserData\\$' -or $_ -match '^T:\\\\Games\\$' })
if($blanket){ $fail += 'Exclusions contain blanket roots (D:\UserData\ or T:\Games\ )' }
$result = if($fail.Count){ 'FAIL' } else { 'PASS' }
[ordered]@{
  Result               = $result
  PolicyArchiveBase    = $pol.ArchiveBase
  RunnerArchiveBase    = $runnerArchive
  PolicyMinSizeMB      = $pol.DuplicateRules.MinSizeMB
  RunnerMinSizeMB      = $runnerMin
  BlanketRootsPresent  = [bool]$blanket
} | Format-List
if($fail){ "`nReasons:`n - " + ($fail -join "`n - ") | Write-Host -ForegroundColor Yellow }
