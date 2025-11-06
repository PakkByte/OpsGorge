<# 
PostPack_Enhancements_v2.ps1
Enhances an existing pack with optional upgrades:
  1) Register in Packs.json (open-by-name later)
  2) Add per-pack profile helpers (dm-open, dm-logs-latest)
  3) Initialize Git repo (version history for README/scripts)
  4) Code-sign all .ps1 in 1-Scripts using a local cert
  5) (Optional) Install a global 'dm-pack' helper to manage/open packs by name

Usage (your Drive Maintenance pack):
& 'D:\UserData\Pakks\_Templates\PostPack_Enhancements_v2.ps1' `
  -PackName 'Drive Maintenance' `
  -PackRoot 'D:\UserData\Pakks\Drive Maintaince' `
  -RegisterPack -AddProfileHelpers -InitGit

Turn everything on:
& 'D:\UserData\Pakks\_Templates\PostPack_Enhancements_v2.ps1' `
  -PackName 'Drive Maintenance' `
  -PackRoot 'D:\UserData\Pakks\Drive Maintaince' `
  -DoAll -InstallGlobalHelper

Notes:
- Idempotent: safe to re-run. It updates/overwrites profile blocks for this pack, merges the registry, skips Git if already a repo, and re-signs as needed.
- PowerShell 5+ compatible (no '??' or '?' ternary).
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$PackName,
  [Parameter(Mandatory=$true)][string]$PackRoot,

  # Toggles (all default OFF; choose what to run)
  [switch]$RegisterPack,
  [switch]$AddProfileHelpers,
  [switch]$InitGit,
  [switch]$SignScripts,

  # Convenience: flip everything above ON
  [switch]$DoAll,

  # Optional: also install a global dm-pack helper (list/add/open any pack by name)
  [switch]$InstallGlobalHelper,

  # Options (paths / names)
  [string]$RegistryPath = 'D:\UserData\Pakks\Packs.json',
  [string]$ScriptsSubdir = '1-Scripts',
  [string]$ProfileHelperPrefix = 'dm'   # will create e.g. dm-open, dm-logs-latest
)

$ErrorActionPreference = 'Stop'

# ---------- normalize toggles ----------
if($DoAll){
  $RegisterPack = $true
  $AddProfileHelpers = $true
  $InitGit = $true
  $SignScripts = $true
}

# ---------- basic checks ----------
if(-not (Test-Path -LiteralPath $PackRoot)){
  throw "PackRoot not found: $PackRoot"
}
$scriptsDir = Join-Path $PackRoot $ScriptsSubdir

function _ok($m){ Write-Host "[OK]  $m" -ForegroundColor Green }
function _skip($m){ Write-Host "[SKIP] $m" -ForegroundColor Yellow }
function _info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function _err($m){ Write-Host "[ERR] $m" -ForegroundColor Red }

# ---------- 1) Pack registry ----------
if($RegisterPack){
  try{
    # Ensure registry folder exists
    $regDir = Split-Path $RegistryPath -Parent
    if(-not (Test-Path -LiteralPath $regDir)){ New-Item -ItemType Directory -Path $regDir -Force | Out-Null }

    # Load existing or empty
    $data = @()
    if(Test-Path -LiteralPath $RegistryPath){
      $raw = Get-Content -LiteralPath $RegistryPath -Raw
      if(-not [string]::IsNullOrWhiteSpace($raw)){
        try { $data = $raw | ConvertFrom-Json } catch { $data = @() }
      }
    } else {
      New-Item -ItemType File -Path $RegistryPath -Force | Out-Null
    }

    # Merge (replace same name)
    $entry = [pscustomobject]@{ name=$PackName; path=$PackRoot }
    $data = @($data | Where-Object name -ne $PackName) + $entry
    $data | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $RegistryPath -Encoding UTF8
    _ok "Registered '$PackName' → $RegistryPath"
  }catch{
    _err "Could not update registry: $($_.Exception.Message)"
  }
}else{ _skip "RegisterPack" }

# ---------- 2) Per-pack profile helpers ----------
if($AddProfileHelpers){
  try{
    if(-not (Test-Path -LiteralPath $PROFILE)){
      New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    $fnOpen = "$ProfileHelperPrefix-open"
    $fnLogs = "$ProfileHelperPrefix-logs-latest"
    $markerA = "# >>> PACK_HELPERS:$($PackName):BEGIN"
    $markerB = "# >>> PACK_HELPERS:$($PackName):END"

$block = @"
$markerA
function $fnOpen {
  ii '$PackRoot'
  start '$PackRoot\Master README.md'
}
function $fnLogs {
  \$p = '$PackRoot\2-Logs'
  \$latest = Get-ChildItem \$p -Directory -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Desc | Select-Object -First 1
  if(\$latest){ ii \$latest.FullName } else { Write-Host 'No logs yet.' -ForegroundColor Yellow }
}
$markerB
"@

    $profileText = Get-Content -LiteralPath $PROFILE -Raw
    $hasBlock = $false
    if($profileText -match [regex]::Escape($markerA)){ $hasBlock = $true }

    if($hasBlock){
      $pattern = "$([regex]::Escape($markerA)).*?$([regex]::Escape($markerB))"
      $profileText = [regex]::Replace($profileText, $pattern, { param($m) $block }, 'Singleline')
      Set-Content -LiteralPath $PROFILE -Value $profileText -Encoding UTF8
      _ok "Updated profile helpers ($fnOpen, $fnLogs). Restart PowerShell to use them."
    } else {
      Add-Content -LiteralPath $PROFILE -Value "`r`n$block"
      _ok "Added profile helpers ($fnOpen, $fnLogs). Restart PowerShell to use them."
    }
  }catch{
    _err "Could not modify `$PROFILE: $($_.Exception.Message)"
  }
}else{ _skip "AddProfileHelpers" }

# ---------- 3) Git init ----------
if($InitGit){
  try{
    $gitOk = $false
    try { $null = git --version 2>$null; $gitOk = $true } catch {}
    if(-not $gitOk){ _skip "Git not found in PATH; skipping init." }
    else{
      Push-Location $PackRoot
      if(-not (Test-Path '.git')){
        git init | Out-Null
        git add 'Master README.md' 'INDEX.md' $ScriptsSubdir -f | Out-Null
        git commit -m "Initial pack snapshot" | Out-Null
        _ok "Initialized git repo + first commit"
      } else {
        _skip "Git repo already exists; no action taken."
      }
      Pop-Location
    }
  }catch{
    _err "Git init failed: $($_.Exception.Message)"
  }
}else{ _skip "InitGit" }

# ---------- 4) Sign scripts ----------
if($SignScripts){
  try{
    # find/create local signing cert
    $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -like '*Tyler Local Signing*' } | Select-Object -First 1
    if(-not $cert){
      $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=Tyler Local Signing" -CertStoreLocation Cert:\CurrentUser\My
      Copy-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)" "Cert:\CurrentUser\TrustedPublisher"
      _ok "Created and trusted local code-signing cert"
    }
    if(Test-Path -LiteralPath $scriptsDir){
      $files = Get-ChildItem -LiteralPath $scriptsDir -File -Recurse -Filter *.ps1 -ErrorAction SilentlyContinue
      if($files -and $files.Count -gt 0){
        foreach($f in $files){ Set-AuthenticodeSignature -FilePath $f.FullName -Certificate $cert | Out-Null }
        _ok "Signed $($files.Count) scripts under $scriptsDir"
      } else {
        _skip "No .ps1 files under $scriptsDir"
      }
    } else {
      _skip "Scripts directory not found: $scriptsDir"
    }
  }catch{
    _err "Signing failed: $($_.Exception.Message)"
  }
}else{ _skip "SignScripts" }

# ---------- 5) Global dm-pack helper (optional) ----------
if($InstallGlobalHelper){
  try{
    if(-not (Test-Path -LiteralPath $PROFILE)){
      New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }
    $markerGA = "# >>> PACK_HELPERS:GLOBAL:BEGIN"
    $markerGB = "# >>> PACK_HELPERS:GLOBAL:END"

$globalBlock = @"
$markerGA
function __dm-get-registry {
  param([string]\$Path = '$RegistryPath')
  if(!(Test-Path -LiteralPath \$Path)){ return @() }
  \$raw = Get-Content -LiteralPath \$Path -Raw
  if([string]::IsNullOrWhiteSpace(\$raw)){ return @() }
  try { \$raw | ConvertFrom-Json } catch { @() }
}
function __dm-save-registry {
  param([object[]]\$Data, [string]\$Path = '$RegistryPath')
  if(!(Test-Path -LiteralPath (Split-Path \$Path))){ New-Item -ItemType Directory -Path (Split-Path \$Path) -Force | Out-Null }
  \$Data | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath \$Path -Encoding UTF8
}
function dm-pack {
  [CmdletBinding(DefaultParameterSetName='Open')]
  param(
    [Parameter(ParameterSetName='List')][switch]\$List,
    [Parameter(ParameterSetName='Add')][switch]\$Add,
    [Parameter(ParameterSetName='Open')][switch]\$Open,
    [Parameter(ParameterSetName='Logs',Mandatory=\$true)][switch]\$Logs,
    [Parameter(ParameterSetName='Add')][string]\$Path,
    [Parameter(ParameterSetName='Add')][Parameter(ParameterSetName='Open')][Parameter(ParameterSetName='Logs')][string]\$Name,
    [Parameter(ParameterSetName='Open')][switch]\$Readme
  )
  if(\$List){
    \$data = __dm-get-registry
    if(!\$data){ Write-Host "No packs registered at: $RegistryPath" -ForegroundColor Yellow; return }
    \$data | Sort-Object name | Format-Table name, path -Auto; return
  }
  if(\$Add){
    if([string]::IsNullOrWhiteSpace(\$Name) -or [string]::IsNullOrWhiteSpace(\$Path)){ throw "dm-pack add requires -Name and -Path" }
    if(!(Test-Path -LiteralPath \$Path)){ throw "Path not found: \$Path" }
    \$data = __dm-get-registry
    \$data = @(\$data | Where-Object name -ne \$Name) + ([pscustomobject]@{name=\$Name;path=\$Path})
    __dm-save-registry -Data \$data
    Write-Host "[OK] Registered '\$Name' → \$Path" -ForegroundColor Green; return
  }
  if(\$Logs){
    if([string]::IsNullOrWhiteSpace(\$Name)){ throw "dm-pack logs requires -Name" }
    \$hit = (__dm-get-registry | Where-Object name -eq \$Name)
    if(!\$hit){ throw "Not found in registry: \$Name" }
    \$packPath = \$hit.path
    \$logs = Join-Path \$packPath '2-Logs'
    if(!(Test-Path -LiteralPath \$logs)){ Write-Host "No logs dir for: \$Name" -ForegroundColor Yellow; return }
    \$latest = Get-ChildItem \$logs -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Desc | Select-Object -First 1
    if(\$latest){ ii \$latest.FullName } else { Write-Host "No log runs yet in: \$logs" -ForegroundColor Yellow }
    return
  }
  if([string]::IsNullOrWhiteSpace(\$Name)){
    Write-Host "Tip: dm-pack list | dm-pack add -Name '<pack>' -Path '<folder>' | dm-pack -Name '<pack>' [-Readme]" -ForegroundColor Cyan; return
  }
  \$hit = (__dm-get-registry | Where-Object name -eq \$Name)
  if(!\$hit){ throw "Not found in registry: \$Name" }
  \$packPath = \$hit.path
  if(!(Test-Path -LiteralPath \$packPath)){ throw "Path missing on disk: \$packPath" }
  ii \$packPath
  if(\$Readme){
    \$readme = Join-Path \$packPath 'Master README.md'
    if(Test-Path -LiteralPath \$readme){ Start-Process \$readme } else { Write-Host "No Master README.md in \$packPath" -ForegroundColor Yellow }
  }
}
$markerGB
"@

    $prof = Get-Content -LiteralPath $PROFILE -Raw
    if($prof -match [regex]::Escape($markerGA)){
      $pattern = "$([regex]::Escape($markerGA)).*?$([regex]::Escape($markerGB))"
      $prof = [regex]::Replace($prof, $pattern, { param($m) $globalBlock }, 'Singleline')
      Set-Content -LiteralPath $PROFILE -Value $prof -Encoding UTF8
      _ok "Updated global dm-pack helper. Restart PowerShell to use it."
    } else {
      Add-Content -LiteralPath $PROFILE -Value "`r`n$globalBlock"
      _ok "Added global dm-pack helper. Restart PowerShell to use it."
    }
  }catch{
    _err "Could not install global helper: $($_.Exception.Message)"
  }
}else{ _skip "InstallGlobalHelper" }

# ---------- summary ----------
Write-Host ""
_info "Done. Summary:"
"{0,-20} {1}" -f 'Pack name:', $PackName
"{0,-20} {1}" -f 'Pack root:', $PackRoot
"{0,-20} {1}" -f 'Registry:', (if(Test-Path -LiteralPath $RegistryPath){"Present → $RegistryPath"}else{"<none>"})
"{0,-20} {1}" -f 'Profile file:', $PROFILE
"{0,-20} {1}" -f 'Scripts dir:', (if(Test-Path -LiteralPath $scriptsDir){$scriptsDir}else{"<missing>"})
