param([string]$RepoRoot=(Get-Location).Path,[switch]$Strict)

Write-Host "== DoD Core verification =="

Write-Host "[Info] Signed commits should be enforced via branch protection."

# 1) Restore-map presence (soft unless -Strict)
$restore = Get-ChildItem -LiteralPath $RepoRoot -Recurse -Filter "restore_map_*.json" -ErrorAction SilentlyContinue
if(-not $restore){ if($Strict){ Write-Error "Missing restore_map_* artifacts"; exit 1 } else { Write-Warning "No restore_map_* (bootstrap OK)" } }

# 2) Secret scan (skip noisy dirs/files; scan text only)
$skipDirs = @('\.git\','\.github\','\b2-Logs\b','\bnode_modules\b','\bbin\b','\bobj\b','\bdist\b')
$textExt  = @('.ps1','.psm1','.psd1','.md','.txt','.json','.yml','.yaml','.csv','.ini','.cfg','.toml')
$allowRel = @('scripts\check-dod.ps1','.github\workflows\validate.yml','brain\TIER_A_README.md')

$secretPatterns = @(
  '(?i)\b(AI|API|APP|BOT|CLIENT|CONNECTION|DB|GITHUB|OAUTH|OPENAI|SECRET|TOKEN|KEY|PASSWORD|PWD)[_\-:]?[A-Z0-9\-_]{8,}\b',
  '(?i)sk\-[A-Za-z0-9]{20,}',
  '(?i)ghp_[A-Za-z0-9]{36,}'
)
$re = [regex]::new(($secretPatterns -join '|'))

$files = Get-ChildItem -Path $RepoRoot -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
  # only small-ish text files
  $_.Length -lt 5MB -and
  $textExt -contains ([string]$_.Extension).ToLower() -and
  # not in skipped dirs
  -not ($skipDirs | ForEach-Object { $_ -as [regex] } | Where-Object { $_.IsMatch($_.FullName) }) -and
  # and not explicitly allowlisted by relative path
  -not ($allowRel | ForEach-Object {
    $rel = [IO.Path]::GetRelativePath($RepoRoot, $_.FullName)
    $rel.Equals($_, [System.StringComparison]::OrdinalIgnoreCase)
  } | Where-Object { $_ })
}

$hits = @()
foreach($f in $files){
  $text = $null
  try { $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop } catch { continue }
  if([string]::IsNullOrWhiteSpace($text)){ continue }
  if($re.IsMatch($text)){ $hits += [IO.Path]::GetRelativePath($RepoRoot, $f.FullName) }
}

if($hits.Count -gt 0){
  if($Strict){ Write-Error ("Potential secrets:`n - " + ($hits -join "`n - ")); exit 1 }
  else       { Write-Warning ("Potential secrets (bootstrap):`n - " + ($hits -join "`n - ")) }
}

Write-Host "DoD checks completed."
