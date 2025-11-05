param(
  [Parameter(Mandatory=$false)][string]$RepoRoot = (Get-Location).Path,
  [switch]$Strict
)

Write-Host "== DoD Core verification =="

# 1) Security: surface signed-commit expectation (rule enforced in GH)
Write-Host "[Info] Signed commits should be enforced via branch protection."

# 2) Restore-map presence (soft requirement unless -Strict)
$restore = Get-ChildItem -LiteralPath $RepoRoot -Recurse -Filter 'restore_map_*.json' -ErrorAction SilentlyContinue
if(-not $restore) {
  if($Strict){ Write-Error "Missing restore_map_* artifact(s) under repo."; exit 1 }
  else       { Write-Warning "No restore_map_* found (ok in bootstrap)." }
}

# 3) Secret scan (skip binaries/large files, allowlist this script)
$allow = @(
  [regex]::Escape("scripts\check-dod.ps1")
)
$secretPatterns = @(
  '(?i)\b(AI|API|APP|BOT|CLIENT|CONNECTION|DB|GITHUB|OAUTH|OPENAI|SECRET|TOKEN|KEY|PASSWORD|PWD)[_\-:]?[A-Z0-9\-_]{8,}\b',
  '(?i)sk\-[A-Za-z0-9]{20,}',
  '(?i)ghp_[A-Za-z0-9]{36,}'
)

$files = Get-ChildItem -Path $RepoRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
  Where-Object {
    $_.Length -lt 5MB -and
    ($_.Extension -notin '.png','.jpg','.jpeg','.gif','.exe','.dll','.zip','.7z','.mp4') -and
    ($allow | ForEach-Object { $_ -notmatch $_.FullName.Substring($RepoRoot.Length+1) }) -notcontains $false
  }

$hits = @()
$re = [regex]::new( ($secretPatterns -join '|') )
foreach($f in $files){
  $text = $null
  try { $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop } catch { continue }
  if([string]::IsNullOrEmpty($text)){ continue }
  if($re.IsMatch($text)) { $hits += $f.FullName; continue }
}

if($hits.Count -gt 0){
  if($Strict){ Write-Error ("Potential secrets detected in:`n - " + ($hits -join "`n - ")); exit 1 }
  else       { Write-Warning ("Potential secrets detected (bootstrap warn):`n - " + ($hits -join "`n - ")) }
}

Write-Host "DoD checks completed."
