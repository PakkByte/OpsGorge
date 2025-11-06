param(
  [ValidateSet("DRY","REAL")][string]$Mode = "DRY",
  [int]$MinSizeMB = 100,
  [int]$MaxRealMoves = 5
)

$ErrorActionPreference = 'Stop'
$root = "D:\UserData\Pakks\Drive Deep Dive"
$ss   = Join-Path $root '1-Scripts'
$logs = Join-Path $root '2-Logs'
function Say([string]$m,[string]$lvl="INFO"){ $c=@{INFO="Gray";OK="Green";WARN="Yellow";ERR="Red"}[$lvl]; Write-Host "[$lvl] $m" -ForegroundColor $c }

New-Item -ItemType Directory -Force -Path $ss,$logs | Out-Null
$polPath  = Join-Path $ss 'Policy.json'
$exclPath = Join-Path $ss 'apply_exclusions.json'
$dashW    = Join-Path $ss 'Write-Dashboard.ps1'

# --- ensure exclusions (refined, no blanket roots) ---
if(-not (Test-Path $exclPath)){
  @"
{
  " + '"skipPaths"' + @": [
    " + '"D:\\UserData\\Pakks\\**","D:\\UserData\\Archives\\**","D:\\UserData\\Documents\\**","D:\\UserData\\Desktop\\**","D:\\UserData\\Projects\\**","D:\\UserData\\Media\\**","T:\\\\SteamLibrary\\\\steamapps\\\\**","T:\\\\XboxGames\\\\**","T:\\\\Autodesk\\\\**","T:\\\\EA\\\\**","T:\\\\Epic\\\\**","T:\\\\Ubisoft\\\\**"' + @"
  ],
  " + '"skipTypes"' + @": []
}
"@ | Set-Content -Enc UTF8 -LiteralPath $exclPath
} else {
  $ex = Get-Content $exclPath -Raw | ConvertFrom-Json
  $ex.skipPaths = @($ex.skipPaths | Where-Object {$_ -notin @('D:\UserData\','T:\Games\')})
  ($ex | ConvertTo-Json -Depth 8) | Set-Content -Enc UTF8 -LiteralPath $exclPath
}

# --- ensure policy & align keys ---
if(-not (Test-Path $polPath)){
  @"
{
  " + '"Version"' + @": " + '"1.7.0-SuperBrain-seed"' + @",
  " + '"ArchiveBase"' + @": " + '"D:\\_Archives"' + @",
  " + '"DuplicateRules"' + @": { " + '"MinSizeMB"' + @": 100 },
  " + '"Canonical"' + @": {
    " + '"D"' + @": [" + '"D:\\UserData","D:\\UserData\\Pakks","D\\:UserData\\Archives","D:\\UserData\\Media","D:\\UserData\\Projects"' + @"],
    " + '"T"' + @": [" + '"T:\\Games","T:\\SteamLibrary","T:\\SteamLibrary\\steamapps","T:\\EA","T:\\Epic","T:\\Ubisoft","T:\\XboxGames"' + @"]
  },
  " + '"KeepPrefer"' + @": [" + '"D:\\UserData","D:\\UserData\\Pakks","T:\\SteamLibrary","T:\\SteamLibrary\\steamapps","T:\\EA","T:\\Epic","T:\\Ubisoft","T:\\XboxGames"' + @"]
}
"@ | Set-Content -Enc UTF8 -LiteralPath $polPath
} else {
  $p = Get-Content $polPath -Raw | ConvertFrom-Json
  if(-not $p.ArchiveBase){ $p.ArchiveBase = 'D:\_Archives' }
  if(-not $p.DuplicateRules){ $p | Add-Member -NotePropertyName DuplicateRules -NotePropertyValue (@{}) }
  $p.DuplicateRules.MinSizeMB = $MinSizeMB
  foreach($d in 'D:\UserData\Media','D:\UserData\Projects'){ if(-not ($p.Canonical.D -contains $d)){ $p.Canonical.D += $d } }
  foreach($t in 'T:\SteamLibrary\steamapps'){ if(-not ($p.Canonical.T -contains $t)){ $p.Canonical.T += $t } }
  foreach($k in 'T:\SteamLibrary\steamapps','T:\XboxGames'){ if(-not ($p.KeepPrefer -contains $k)){ $p.KeepPrefer += $k } }
  ($p | ConvertTo-Json -Depth 25) | Set-Content -Enc UTF8 -LiteralPath $polPath
}

# --- tiny dashboard writer (self-contained) ---
@(
  'param([string]$Root = "D:\UserData\Pakks\Drive Deep Dive")',
  '$logs = Join-Path $Root "2-Logs"',
  '$dash = Join-Path $logs "Dashboard.md"',
  'function GL([string]$pat){ Get-ChildItem -Path $logs -File -EA SilentlyContinue | ? { $_.Name -like $pat } | sort LastWriteTimeUtc | select -Last 1 }',
  '$apply=GL "Apply_*.txt"; $sum=GL "Apply_Summary_*.csv"; $audit=GL "cleanup_audit_filtered_*.json"; if(-not $audit){$audit=GL "cleanup_audit_*.json"}',
  '$snap=GL "Policy_Snapshot_*.json"; $diff=GL "Policy_Diff_*.txt"',
  '$pol=Get-Content (Join-Path $Root "1-Scripts\Policy.json") -Raw | ConvertFrom-Json',
  '$ab=$pol.ArchiveBase; $mm=$pol.DuplicateRules.MinSizeMB',
  '$L=@("# Drive Deep Dive — Dashboard","","| KPI | Value |","|---|---|",',
  '"| ArchiveBase | " + $ab + " |",',
  '"| MinSizeMB | " + $mm + " |",',
  '"| Latest Apply Log | " + ($apply?.Name ?? "(none)") + " |",',
  '"| Latest Summary | " + ($sum?.Name ?? "(none)") + " |",',
  '"| Latest Audit | " + ($audit?.Name ?? "(none)") + " |",',
  '"| Latest Snapshot | " + ($snap?.Name ?? "(none)") + " |",',
  '"| Latest Diff | " + ($diff?.Name ?? "(none)") + " |","",',
  '"## Artifacts",',
  '"- Apply Log:      " + ($apply?.FullName ?? "(none)"),',
  '"- Summary CSV:    " + ($sum?.FullName ?? "(none)"),',
  '"- Audit JSON:     " + ($audit?.FullName ?? "(none)"),',
  '"- Policy Snapshot:" + ($snap?.FullName ?? "(none)"),',
  '"- Policy Diff:    " + ($diff?.FullName ?? "(none)"),',
  '"",',
  '"> Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))',
  'ni -ItemType Directory -Force -Path $logs | Out-Null',
  '$L | Set-Content -Enc UTF8 -LiteralPath $dash',
  'Write-Host "Dashboard written: $dash" -ForegroundColor Green'
) | Set-Content -Enc UTF8 -LiteralPath $dashW

# --- preflight: audit + DRY apply + index refresh ---
& (Join-Path $ss 'Preflight_DRY_Checks.ps1') -Root $root -MinSizeMB $MinSizeMB
& (Join-Path $ss 'Update-IndexAndReadme.ps1') -Root $root

# --- gate checks ---
$pol = Get-Content $polPath -Raw | ConvertFrom-Json
$ex  = Get-Content $exclPath -Raw | ConvertFrom-Json
$archLine = Select-String -Path (Join-Path $logs 'Apply_*.txt') -Pattern '^>>> Archive:'   | Select -Last 1
$minLine  = Select-String -Path (Join-Path $logs 'Apply_*.txt') -Pattern '^>>> MinSizeMB:' | Select -Last 1
$audit = Get-ChildItem $logs -Filter 'cleanup_audit_filtered_*.json' | Sort LastWriteTime -Desc | Select -First 1
if(-not $audit){ $audit = Get-ChildItem $logs -Filter 'cleanup_audit_*.json' | Sort LastWriteTime -Desc | Select -First 1 }
$planned = 0; if($audit){ $planned = @((Get-Content $audit.FullName -Raw | ConvertFrom-Json)).Count }

$gate = [ordered]@{
  ArchiveBasePolicy = $pol.ArchiveBase
  ArchiveBaseRunner = ($archLine?.Line -replace '>>> Archive:\s*','').Trim()
  MinSizeMBPolicy   = $pol.DuplicateRules.MinSizeMB
  MinSizeMBRunner   = [int]($minLine?.Line -replace '[^\d]','')
  BlanketExclusions = ($ex.skipPaths | ? { $_ -match '^D:\\UserData\\$' -or $_ -match '^T:\\Games\\$' })
  PlannedCount      = $planned
  MaxRealMoves      = $MaxRealMoves
}
$pass=$true; $why=@()
if($gate.ArchiveBasePolicy -ne $gate.ArchiveBaseRunner){$pass=$false;$why+='ArchiveBase mismatch'}
if($gate.MinSizeMBPolicy -ne $MinSizeMB){$pass=$false;$why+='Policy.MinSizeMB mismatch'}
if($gate.MinSizeMBRunner -ne $MinSizeMB){$pass=$false;$why+='Runner MinSizeMB mismatch'}
if($gate.BlanketExclusions){$pass=$false;$why+='Blanket skipPaths present'}
if($gate.PlannedCount -gt $gate.MaxRealMoves){$pass=$false;$why+="Planned $($gate.PlannedCount) > Max $MaxRealMoves"}

"`n=== GATE ==="; $gate | Format-List
if($pass){ Say "GATE: PASS" "OK" } else { Say ("GATE: FAIL — " + ($why -join '; ')) "ERR" }

& $dashW -Root $root | Out-Null
if($Mode -eq 'DRY'){ Say "Mode=DRY complete. Nothing applied." "INFO"; return }

if(-not $pass){ throw "REAL requested but gate failed: $($why -join '; ')" }

$envFile = Join-Path $logs ("ARM_Approve_{0}.yaml" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
@(
  'ENVELOPE v1',
  'FROM: Tyler','TO: Ops','CMD: RUN REAL','ARTIFACTS:','- type: approval','  name: ARM','  body: |',
  "    ARM & EXECUTE (Monthly). Confirm ArchiveBase=$($pol.ArchiveBase), MinSizeMB=$MinSizeMB, MaxRealMoves=$MaxRealMoves, restore_map required."
) | Set-Content -Enc UTF8 -LiteralPath $envFile

& (Join-Path $ss 'B-Apply_DeepDive_Audit.ps1') -AuditJson $audit.FullName -MinSizeMB $MinSizeMB -Execute

$applyLog = Get-ChildItem $logs -Filter 'Apply_*.txt'         | Sort LastWriteTime -Desc | Select -First 1
$summary  = Get-ChildItem $logs -Filter 'Apply_Summary_*.csv' | Sort LastWriteTime -Desc | Select -First 1
$map      = Get-ChildItem $logs -Filter 'restore_map_*.json'  | Sort LastWriteTime -Desc | Select -First 1
& $dashW -Root $root | Out-Null
[ordered]@{ApplyLog=$applyLog.FullName;SummaryCSV=$summary.FullName;RestoreMap=$map.FullName} | Format-List
