<# 
Update_Master_README.ps1
- Safely archive old "Master README.md" and replace with a new one you downloaded.
- Optional: create a dated logs run, git commit, and register/refresh pack in Packs.json.

Examples:
& 'D:\UserData\Pakks\_Templates\Update_Master_README.ps1' `
  -PackName 'Drive Maintenance' `
  -PackRoot 'D:\UserData\Pakks\Drive Maintaince' `
  -NewReadmePath 'C:\Users\tyler\Downloads\Master_README_Home_PC_Storage_Cleanup.md' `
  -CreateLogRun -Commit -Register -OpenAfter

#>

[CmdletBinding()]
param(
  [string]$PackName = 'Drive Maintenance',
  [string]$PackRoot,
  [string]$NewReadmePath,

  [switch]$CreateLogRun,
  [switch]$Commit,
  [switch]$Register,
  [switch]$OpenAfter,

  [string]$RegistryPath = 'D:\UserData\Pakks\Packs.json'
)

$ErrorActionPreference = 'Stop'

function _ok($m){ Write-Host "[OK]  $m" -ForegroundColor Green }
function _info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function _warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function _err($m){ Write-Host "[ERR] $m" -ForegroundColor Red }

function Prompt-Folder([string]$Title, [string]$StartPath){
  try{
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = $Title
    $dlg.ShowNewFolderButton = $true
    if($StartPath -and (Test-Path $StartPath)){ $dlg.SelectedPath = $StartPath }
    if($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){ return $dlg.SelectedPath }
  }catch{}
  return $null
}

function Prompt-File([string]$Title, [string]$StartDir){
  try{
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Title = $Title
    $ofd.Filter = "Markdown (*.md)|*.md|All files (*.*)|*.*"
    if($StartDir -and (Test-Path $StartDir)){ $ofd.InitialDirectory = $StartDir }
    if($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){ return $ofd.FileName }
  }catch{}
  return $null
}

# --- Resolve PackRoot ---
if([string]::IsNullOrWhiteSpace($PackRoot)){
  $PackRoot = Prompt-Folder -Title 'Pick your Pack Root (folder that contains Master README.md)' -StartPath 'D:\UserData\Pakks'
  if([string]::IsNullOrWhiteSpace($PackRoot)){ throw "Cancelled (no PackRoot chosen)." }
}
if(!(Test-Path -LiteralPath $PackRoot)){ throw "PackRoot not found: $PackRoot" }

$destReadme = Join-Path $PackRoot 'Master README.md'
$archiveDir = Join-Path $PackRoot 'Archive'
$logsDir    = Join-Path $PackRoot '2-Logs'

# --- Optional: create a dated log run folder ---
$runDir = $null
if($CreateLogRun){
  $stamp = (Get-Date).ToString('yyyy-MM-dd_HHmm')
  if(!(Test-Path -LiteralPath $logsDir)){ New-Item -ItemType Directory -Path $logsDir | Out-Null }
  $runDir = Join-Path $logsDir $stamp
  New-Item -ItemType Directory -Path $runDir | Out-Null
  _ok "Created log run: $runDir"
}

# --- Resolve the new README source file ---
if([string]::IsNullOrWhiteSpace($NewReadmePath) -or !(Test-Path -LiteralPath $NewReadmePath)){
  $guess1 = Join-Path $env:USERPROFILE 'Downloads\Master_README_Home_PC_Storage_Cleanup.md'
  $guess2 = Join-Path $env:USERPROFILE 'Downloads\Master README.md'
  if(Test-Path -LiteralPath $guess1){ $NewReadmePath = $guess1 }
  elseif(Test-Path -LiteralPath $guess2){ $NewReadmePath = $guess2 }
  else{
    $NewReadmePath = Prompt-File -Title 'Select the NEW Master README.md you downloaded' -StartDir (Join-Path $env:USERPROFILE 'Downloads')
    if([string]::IsNullOrWhiteSpace($NewReadmePath)){ throw "Cancelled (no new README selected)." }
  }
}
if(!(Test-Path -LiteralPath $NewReadmePath)){ throw "NewReadmePath not found: $NewReadmePath" }

# --- Archive old README if present ---
if(Test-Path -LiteralPath $destReadme){
  if(!(Test-Path -LiteralPath $archiveDir)){ New-Item -ItemType Directory -Path $archiveDir | Out-Null }
  $ts = (Get-Date).ToString('yyyy-MM-dd_HHmm')
  $archName = "Master README ($ts prev).md"
  $archPath = Join-Path $archiveDir $archName
  Move-Item -LiteralPath $destReadme -Destination $archPath -Force
  _ok "Archived old README → $archPath"
}else{
  _info "No existing Master README.md found (fresh placement)."
}

# --- Place the new README ---
Copy-Item -LiteralPath $NewReadmePath -Destination $destReadme -Force
_ok "Installed NEW Master README.md"

# --- Optional: Git commit ---
if($Commit){
  try{
    $gitOk = $false
    try{ $null = git --version 2>$null; $gitOk = $true }catch{}
    if($gitOk){
      Push-Location $PackRoot
      if(!(Test-Path '.git')){ git init | Out-Null }
      git add 'Master README.md' | Out-Null
      $msg = "Update canonical Master README (" + (Get-Date).ToString('yyyy-MM-dd') + ")"
      git commit -m $msg | Out-Null
      Pop-Location
      _ok "Git commit recorded."
    } else {
      _warn "Git not found in PATH; skipping commit."
    }
  }catch{
    _err "Git step failed: $($_.Exception.Message)"
  }
}

# --- Optional: Register/refresh Packs.json ---
if($Register){
  try{
    $regDir = Split-Path $RegistryPath -Parent
    if(!(Test-Path -LiteralPath $regDir)){ New-Item -ItemType Directory -Path $regDir -Force | Out-Null }
    $data = @()
    if(Test-Path -LiteralPath $RegistryPath){
      $raw = Get-Content -LiteralPath $RegistryPath -Raw
      if(-not [string]::IsNullOrWhiteSpace($raw)){
        try{ $data = $raw | ConvertFrom-Json }catch{ $data = @() }
      }
    } else { New-Item -ItemType File -Path $RegistryPath -Force | Out-Null }
    $entry = [pscustomobject]@{ name=$PackName; path=$PackRoot }
    $data = @($data | Where-Object name -ne $PackName) + $entry
    $data | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $RegistryPath -Encoding UTF8
    _ok "Registered pack '$PackName' → $RegistryPath"
  }catch{
    _err "Registry update failed: $($_.Exception.Message)"
  }
}

# --- Write a small note in the log run (if created) ---
if($runDir){
  $note = Join-Path $runDir 'README_update.txt'
  @"
Updated Master README
Pack:   $PackName
Root:   $PackRoot
Time:   $((Get-Date).ToString('yyyy-MM-dd HH:mm'))
Source: $NewReadmePath
"@ | Out-File -LiteralPath $note -Encoding utf8
}

# --- Open after completion ---
Write-Host ""
Write-Host "Done." -ForegroundColor Green
"{0,-14} {1}" -f 'Pack root:', $PackRoot
"{0,-14} {1}" -f 'README now:', $destReadme
if($runDir){ "{0,-14} {1}" -f 'Log run:', $runDir }
if($OpenAfter){
  Start-Process explorer.exe $PackRoot
  Start-Process $destReadme
}
