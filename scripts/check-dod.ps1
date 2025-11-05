param(
  [string]$RepoRoot = (Get-Location).Path,
  [switch]$Strict
)

Write-Host "== DoD Core verification =="

Write-Host "[Info] Signed commits should be enforced via branch protection."

# 1) Restore-map presence (soft unless -Strict)
$restore = Get-ChildItem -LiteralPath $RepoRoot -Recurse -Filter "restore_map_*.json" -ErrorAction SilentlyContinue
if(-not $restore){
  if($Strict){ Write-Error "Missing restore_map_* artifacts"; exit 1 }
  else       { Write-Warning "No restore_map_* (bootstrap OK)" }
}

# 2) Secret scan (skip noisy dirs; text-only; allowlist some files)
$skipDirPatterns = @('\.git\\', '\.github\\', '(^|\\)2-Logs(\\|$)', '(^|\\)node_modules(\\|$)', '(^|\\)bin(\\|$)', '(^|\\)obj(\\|$)', '(^|\\)dist(\\|$)')
$skipDirRegexes  = $skipDirPatterns | ForEach-Object { [regex]::new($_, 'IgnoreCase') }

$textExt  = @('.ps1','.psm1','.psd1','.md','.txt','.json','.yml','.yaml','.csv','.ini','.cfg','.toml')
$allowRel = @(
  'scripts\check-dod.ps1',
  '.github\workflows\validate.yml',
  'brain\TIER_A_README.md'
)

$secretPatterns = @(
  '(?i)\b(AI|API|APP|BOT|CLIENT|CONNECTION|DB|GITHUB|OAUTH|OPENAI|SECRET|TOKEN|KEY|PASSWORD|PWD)[_\-:]?[A-Z0-9\-_]{8,}\b',
  '(?i)sk\-[A-Za-z0-9]{20,}',
  '(?i)ghp_[A-Za-z0-9]{36,}'
)
$re = [regex]::new(($secretPatterns -join '|'))

# Normalize path helper
function Get-Rel([string]$abs, [string]$root){
  $rel = [IO.Path]::GetRelativePath($root, $abs)
  # Normalize separators to backslash
  return $rel -replace '/', '\'
}

$hits = New-Object System.Collections.Generic.List[string]

# Enumerate candidate files
$all = Get-ChildItem -Path $RepoRoot -Recurse -File -Force -ErrorAction SilentlyContinue
foreach($f in $all){
  # Extension filter
  $ext = ([string]$f.Extension).ToLowerInvariant()
  if($f.Length -ge 5MB -or -not ($textExt -contains $ext)){ continue }

  # Skip directories by RELATIVE PATH match
  $relPath = Get-Rel -abs $f.FullName -root $RepoRoot
  $skip = $false
  foreach($rx in $skipDirRegexes){
    if($rx.IsMatch($relPath)){ $skip = $true; break }
  }
  if($skip){ continue }

  # Allowlist certain rel paths exactly
  $isAllowed = $false
  foreach($a in $allowRel){
    if($relPath.Equals($a, [System.StringComparison]::OrdinalIgnoreCase)){ $isAllowed = $true; break }
  }
  if($isAllowed){ continue }

  # Read text safely
  $text = $null
  try { $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop } catch { continue }
  if([string]::IsNullOrWhiteSpace($text)){ continue }

  # Regex hit?
  if($re.IsMatch($text)){ $hits.Add($relPath) }
}

if($hits.Count -gt 0){
  $msg = "Potential secrets:`n - " + ($hits -join "`n - ")
  if($Strict){ Write-Error $msg; exit 1 }
  else       { Write-Warning $msg }
}

Write-Host "DoD checks completed."
