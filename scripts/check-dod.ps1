param([string]$RepoRoot=(Get-Location).Path,[switch]$Strict)
Write-Host "== DoD Core verification =="
Write-Host "[Info] Signed commits should be enforced via branch protection."
$restore = Get-ChildItem -LiteralPath $RepoRoot -Recurse -Filter "restore_map_*.json" -ErrorAction SilentlyContinue
if(-not $restore){ if($Strict){ Write-Error "Missing restore_map_* artifacts"; exit 1 } else { Write-Warning "No restore_map_* (bootstrap OK)" } }
$allow = @([regex]::Escape("scripts\check-dod.ps1"))
$secretPatterns = @(
  '(?i)\b(AI|API|APP|BOT|CLIENT|CONNECTION|DB|GITHUB|OAUTH|OPENAI|SECRET|TOKEN|KEY|PASSWORD|PWD)[_\-:]?[A-Z0-9\-_]{8,}\b',
  '(?i)sk\-[A-Za-z0-9]{20,}',
  '(?i)ghp_[A-Za-z0-9]{36,}'
)
$files = Get-ChildItem -Path $RepoRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Length -lt 5MB -and ($_.Extension -notin '.png','.jpg','.jpeg','.gif','.exe','.dll','.zip','.7z','.mp4') }
$hits=@()
$re=[regex]::new(($secretPatterns -join '|'))
foreach($f in $files){
  $text=$null; try{$text=Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop}catch{continue}
  if([string]::IsNullOrEmpty($text)){continue}
  if($re.IsMatch($text)){ $hits+=$f.FullName; continue }
}
if($hits.Count -gt 0){ if($Strict){ Write-Error ("Potential secrets:`n - "+($hits -join "`n - ")); exit 1 } else { Write-Warning ("Potential secrets (bootstrap):`n - "+($hits -join "`n - ")) } }
Write-Host "DoD checks completed."
