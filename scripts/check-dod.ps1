param(
  [string]$RepoRoot = (Get-Location).Path,
  [switch]$Strict
)

Write-Host "== DoD Core verification =="

# 1) Restore-map presence (useful for real runs)
$restore = Get-ChildItem -LiteralPath $RepoRoot -Recurse -Filter "restore_map_*.json" -ErrorAction SilentlyContinue
if(-not $restore){
  if($Strict){ Write-Error "Missing restore_map_* artifacts"; exit 1 }
  else{ Write-Warning "No restore_map_* (bootstrap OK)" }
}

# 2) Secret scan with safe ignores
$ignoreDirRegex = '(?i)\\(?:\.git|\.github|brain|node_modules|bin|obj|dist)\\'
$ignoreExact    = @('scripts\check-dod.ps1') # don't flag itself

$secretPatterns = @(
  '(?i)\b(AI|API|APP|BOT|CLIENT|CONNECTION|DB|GITHUB|OAUTH|OPENAI|SECRET|TOKEN|KEY|PASSWORD|PWD)[_\-:]?[A-Z0-9\-_]{8,}\b',
  '(?i)sk\-[A-Za-z0-9]{20,}',
  '(?i)ghp_[A-Za-z0-9]{36,}'
)
$re = [regex]::new(($secretPatterns -join '|'))

$files = Get-ChildItem -Path $RepoRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Length -lt 5MB -and ($_.FullName -notmatch $ignoreDirRegex) }

$hits = @()
foreach($f in $files){
  $rel = [IO.Path]::GetRelativePath($RepoRoot, $f.FullName)
  if ($ignoreExact | Where-Object { $rel.Equals($_, [StringComparison]::OrdinalIgnoreCase) }) { continue }
  $text = $null
  try   { $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop } catch { continue }
  if ([string]::IsNullOrEmpty($text)) { continue }
  if ($re.IsMatch($text)) { $hits += $rel }
}
if ($hits.Count -gt 0) {
  $list = ($hits | Sort-Object -Unique) -join "`n - "
  if ($Strict) { Write-Error "Potential secrets:`n - $list"; exit 1 }
  else         { Write-Warning "Potential secrets (bootstrap):`n - $list" }
}

Write-Host "DoD checks completed."
