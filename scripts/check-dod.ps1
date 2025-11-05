param(
  [string]$RepoRoot = (Resolve-Path ".").Path,
  [string]$LogsGlob = "**/2-Logs/*",
  [switch]$VerboseOutput
)
$ErrorActionPreference = "Stop"

Write-Host "== DoD Core verification =="

# 1) Signed commit is enforced via branch protection; here we only note it.
Write-Host "[Info] Signed commits should be enforced via branch protection."

# 2) Schema + self-tests: assume validate.yml ran earlier; we fail here only if artifacts signal errors (optional extension point).

# 3) Secrets scan quick heuristics (basic): block obvious keys in repo (customize for your org)
$forbidden = @('AWS_SECRET_ACCESS_KEY','GOOGLE_APPLICATION_CREDENTIALS','BEGIN PRIVATE KEY')
$hits = @()
Get-ChildItem -Path $RepoRoot -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -notin '.png','.jpg','.jpeg','.gif','.ico','.exe','.dll' } |
  ForEach-Object {
    try {
      $t = Get-Content $_.FullName -Raw -ErrorAction Stop
      foreach($f in $forbidden){ if($t -match [regex]::Escape($f)){ $hits += $_.FullName; break } }
    } catch {}
  }
if($hits.Count -gt 0){
  # Ignore this checker file to avoid self-flagging
  $hits = $hits | ForEach-Object { "param(
  [string]$RepoRoot = (Resolve-Path ".").Path,
  [string]$LogsGlob = "**/2-Logs/*",
  [switch]$VerboseOutput
)
$ErrorActionPreference = "Stop"

Write-Host "== DoD Core verification =="

# 1) Signed commit is enforced via branch protection; here we only note it.
Write-Host "[Info] Signed commits should be enforced via branch protection."

# 2) Schema + self-tests: assume validate.yml ran earlier; we fail here only if artifacts signal errors (optional extension point).

# 3) Secrets scan quick heuristics (basic): block obvious keys in repo (customize for your org)
$forbidden = @('AWS_SECRET_ACCESS_KEY','GOOGLE_APPLICATION_CREDENTIALS','BEGIN PRIVATE KEY')
$hits = @()
Get-ChildItem -Path $RepoRoot -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -notin '.png','.jpg','.jpeg','.gif','.ico','.exe','.dll' } |
  ForEach-Object {
    try {
      $t = Get-Content $_.FullName -Raw -ErrorAction Stop
      foreach($f in $forbidden){ if($t -match [regex]::Escape($f)){ $hits += $_.FullName; break } }
    } catch {}
  }
if($hits.Count -gt 0){
  Write-Error -Message ("Potential secrets detected in:`n - " + ($hits -join "`n - "))
}

# 4) Docs updated (README changed in PR) – in CI, diff check preferred; locally, ensure README exists
$readme = Join-Path $RepoRoot "README.md"
if(-not (Test-Path $readme)){ Write-Error "README.md missing." }

# 5) Logs + restore-map presence (at least one recent file)
$logFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter "restore_map_*.json" -ErrorAction SilentlyContinue
if(-not $logFiles){ Write-Error "No restore_map_*.json found. Ensure your run produces and archives restore maps." }

# 6) Issue/Changelog linked – CI-friendly regex against PR body is ideal; here we only warn if missing a local marker file
$prMeta = Join-Path $RepoRoot ".github\PR_BODY.txt"
if(Test-Path $prMeta){
  $pb = Get-Content $prMeta -Raw
  if($pb -notmatch '(Fixes|Closes)\s+#\d+'){ Write-Error "PR does not reference an issue (expected 'Fixes #<id>')." }
} else {
  Write-Host "[Info] Skipping PR body reference check (no .github/PR_BODY.txt)."
}

Write-Host "All Core checks completed."

" }
  $hits = $hits | Where-Object { param(
  [string]$RepoRoot = (Resolve-Path ".").Path,
  [string]$LogsGlob = "**/2-Logs/*",
  [switch]$VerboseOutput
)
$ErrorActionPreference = "Stop"

Write-Host "== DoD Core verification =="

# 1) Signed commit is enforced via branch protection; here we only note it.
Write-Host "[Info] Signed commits should be enforced via branch protection."

# 2) Schema + self-tests: assume validate.yml ran earlier; we fail here only if artifacts signal errors (optional extension point).

# 3) Secrets scan quick heuristics (basic): block obvious keys in repo (customize for your org)
$forbidden = @('AWS_SECRET_ACCESS_KEY','GOOGLE_APPLICATION_CREDENTIALS','BEGIN PRIVATE KEY')
$hits = @()
Get-ChildItem -Path $RepoRoot -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -notin '.png','.jpg','.jpeg','.gif','.ico','.exe','.dll' } |
  ForEach-Object {
    try {
      $t = Get-Content $_.FullName -Raw -ErrorAction Stop
      foreach($f in $forbidden){ if($t -match [regex]::Escape($f)){ $hits += $_.FullName; break } }
    } catch {}
  }
if($hits.Count -gt 0){
  Write-Error -Message ("Potential secrets detected in:`n - " + ($hits -join "`n - "))
}

# 4) Docs updated (README changed in PR) – in CI, diff check preferred; locally, ensure README exists
$readme = Join-Path $RepoRoot "README.md"
if(-not (Test-Path $readme)){ Write-Error "README.md missing." }

# 5) Logs + restore-map presence (at least one recent file)
$logFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter "restore_map_*.json" -ErrorAction SilentlyContinue
if(-not $logFiles){ Write-Error "No restore_map_*.json found. Ensure your run produces and archives restore maps." }

# 6) Issue/Changelog linked – CI-friendly regex against PR body is ideal; here we only warn if missing a local marker file
$prMeta = Join-Path $RepoRoot ".github\PR_BODY.txt"
if(Test-Path $prMeta){
  $pb = Get-Content $prMeta -Raw
  if($pb -notmatch '(Fixes|Closes)\s+#\d+'){ Write-Error "PR does not reference an issue (expected 'Fixes #<id>')." }
} else {
  Write-Host "[Info] Skipping PR body reference check (no .github/PR_BODY.txt)."
}

Write-Host "All Core checks completed."

 -notmatch [regex]::Escape($PSCommandPath) }
  Write-Error -Message ("Potential secrets detected in:`n - " + ($hits -join "`n - "))
}

# 4) Docs updated (README changed in PR) – in CI, diff check preferred; locally, ensure README exists
$readme = Join-Path $RepoRoot "README.md"
if(-not (Test-Path $readme)){ Write-Error "README.md missing." }

# 5) Logs + restore-map presence (at least one recent file)
$logFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter "restore_map_*.json" -ErrorAction SilentlyContinue
if(-not $logFiles){ Write-Error "No restore_map_*.json found. Ensure your run produces and archives restore maps." }

# 6) Issue/Changelog linked – CI-friendly regex against PR body is ideal; here we only warn if missing a local marker file
$prMeta = Join-Path $RepoRoot ".github\PR_BODY.txt"
if(Test-Path $prMeta){
  $pb = Get-Content $prMeta -Raw
  if($pb -notmatch '(Fixes|Closes)\s+#\d+'){ Write-Error "PR does not reference an issue (expected 'Fixes #<id>')." }
} else {
  Write-Host "[Info] Skipping PR body reference check (no .github/PR_BODY.txt)."
}

Write-Host "All Core checks completed."


