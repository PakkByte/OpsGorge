<# 
New-StandardPack_v2.1.ps1
- Prompts for PackRoot (defaults to D:\UserData\Pakks), refuses System32
- Creates: 1-Scripts, 2-Logs, and (optionally) 3-Quarantine (Pack Specific)
- Places INDEX.md + Master README.md (from params / Downloads / picker, or stubs)
- Optional: create Desktop shortcut; open pack when done
- Extensible: -IncludeQuarantine (default off) and -AdditionalDirs for future needs
#>

[CmdletBinding()]
param(
  [string]$PackRoot,
  [string]$IndexPath,
  [string]$ReadmePath,
  [string]$SearchDownloads = 'D:\UserData\Downloads',
  [switch]$AllowStubs = $true,
  [switch]$CreateDesktopShortcut,
  [switch]$OpenWhenDone,

  # New: make per-pack Quarantine optional (default off)
  [switch]$IncludeQuarantine,

  # New: create any extra subfolders now or later without editing the script
  [string[]]$AdditionalDirs
)

$ErrorActionPreference = 'Stop'

function Prompt-Folder([string]$Title, [string]$StartPath){
  try{
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = $Title
    $dlg.ShowNewFolderButton = $true
    if($StartPath -and (Test-Path $StartPath)){ $dlg.SelectedPath = $StartPath }
    $r = $dlg.ShowDialog()
    if($r -eq [System.Windows.Forms.DialogResult]::OK){ return $dlg.SelectedPath }
  }catch{}
  return $null
}

function Prompt-File([string]$Title){
  try{
    Add-Type -AssemblyName PresentationFramework | Out-Null
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Title = $Title
    $dlg.Filter = "Markdown (*.md)|*.md|All files (*.*)|*.*"
    if($dlg.ShowDialog() -eq $true){ return (Get-Item $dlg.FileName) }
  }catch{}
  return $null
}

# ----- PackRoot guard + prompt -----
$defaultBase = 'D:\UserData\Pakks'
if(-not [System.IO.Path]::IsPathRooted($PackRoot) -or [string]::IsNullOrWhiteSpace($PackRoot)){
  if(-not (Test-Path $defaultBase)){ New-Item -ItemType Directory -Path $defaultBase | Out-Null }
  $picked = Prompt-Folder -Title 'Pick or create your PackRoot (choose a folder on D:)' -StartPath $defaultBase
  if(-not $picked){ throw "Pack creation cancelled (no PackRoot chosen)." }
  $PackRoot = $picked
}
if($PackRoot -match '^[Cc]:\\Windows\\System32(\\|$)'){
  throw "Refusing to create a pack in C:\Windows\System32. Choose a folder on D:\ instead."
}

# ----- Ensure structure -----
$ScriptsDir = Join-Path $PackRoot '1-Scripts'
$LogsDir    = Join-Path $PackRoot '2-Logs'
$dirs = @($PackRoot, $ScriptsDir, $LogsDir)

if($IncludeQuarantine){
  $QuarDir = Join-Path $PackRoot '3-Quarantine (Pack Specific)'
  $dirs += $QuarDir
}

if($AdditionalDirs){
  foreach($d in $AdditionalDirs){
    if(-not [string]::IsNullOrWhiteSpace($d)){
      $dirs += (Join-Path $PackRoot $d)
    }
  }
}

foreach($d in $dirs){
  if(-not (Test-Path -LiteralPath $d)){ New-Item -ItemType Directory -Path $d | Out-Null }
}

# ----- INDEX.md -----
$destIndex = Join-Path $PackRoot 'INDEX.md'
$srcIndexItem = $null
if($IndexPath -and (Test-Path -LiteralPath $IndexPath)){ $srcIndexItem = Get-Item -LiteralPath $IndexPath }
elseif($SearchDownloads){
  $cand = Join-Path $SearchDownloads 'INDEX.md'
  if(Test-Path -LiteralPath $cand){ $srcIndexItem = Get-Item -LiteralPath $cand }
}
if(-not $srcIndexItem){
  $commonIndex = @(
    (Join-Path $env:USERPROFILE 'Downloads\INDEX.md'),
    (Join-Path $env:USERPROFILE 'Desktop\INDEX.md'),
    (Join-Path (Get-Location).Path 'INDEX.md')
  )
  foreach($c in $commonIndex){
    if(Test-Path -LiteralPath $c){ $srcIndexItem = Get-Item -LiteralPath $c; break }
  }
}
if(-not $srcIndexItem){ $srcIndexItem = Prompt-File -Title 'Select INDEX.md (Cancel to create stub)' }

if($srcIndexItem){
  Copy-Item -LiteralPath $srcIndexItem.FullName -Destination $destIndex -Force
}elseif($AllowStubs -and -not (Test-Path -LiteralPath $destIndex)){
@"
# Pack Index

**Start here:**
- 👉 **[Master README (Canonical)](./Master%20README.md)**
- ▶️ Run audit: `.\1-Scripts\DriveAudit_v4.1.ps1` (Admin PowerShell)

**Shortcuts:** [1-Scripts](./1-Scripts/) • [2-Logs](./2-Logs/)$(if($IncludeQuarantine){' • [3-Quarantine (Pack Specific)](./3-Quarantine%20(Pack%20Specific)/)'} )
"@ | Out-File -Encoding utf8 -LiteralPath $destIndex
}else{
  Write-Warning "INDEX.md not placed (no source and stubs disabled)."
}

# ----- Master README.md -----
$destReadme = Join-Path $PackRoot 'Master README.md'
$srcReadmeItem = $null
if($ReadmePath -and (Test-Path -LiteralPath $ReadmePath)){ $srcReadmeItem = Get-Item -LiteralPath $ReadmePath }
elseif($SearchDownloads){
  $cand = Join-Path $SearchDownloads 'Master README.md'
  if(Test-Path -LiteralPath $cand){ $srcReadmeItem = Get-Item -LiteralPath $cand }
}
if(-not $srcReadmeItem){
  $commonReadme = @(
    (Join-Path $env:USERPROFILE 'Downloads\Master README.md'),
    (Join-Path $env:USERPROFILE 'Desktop\Master README.md'),
    (Join-Path (Get-Location).Path 'Master README.md')
  )
  foreach($c in $commonReadme){
    if(Test-Path -LiteralPath $c){ $srcReadmeItem = Get-Item -LiteralPath $c; break }
  }
}
if(-not $srcReadmeItem){ $srcReadmeItem = Prompt-File -Title 'Select Master README.md (Cancel to create stub)' }

if($srcReadmeItem){
  Copy-Item -LiteralPath $srcReadmeItem.FullName -Destination $destReadme -Force
}elseif($AllowStubs -and -not (Test-Path -LiteralPath $destReadme)){
@"
# Master README (Stub)

Use this as the canonical source for this pack.

**Policy:** C = launchers/apps, T = games payloads, D = archives/exports.  
**Layout:** `1-Scripts/`, `2-Logs/`$(if($IncludeQuarantine){', `3-Quarantine (Pack Specific)/`'}).  
**How to run audits:** see `1-Scripts`.  
**DoD:** clean reports, no orphans, verified launcher paths, T:\Games is default.  
**Change log:** add meaningful edits with date/time here.
"@ | Out-File -Encoding utf8 -LiteralPath $destReadme
}else{
  Write-Warning "Master README.md not placed (no source and stubs disabled)."
}

# ----- Optional: Desktop shortcut -----
if($CreateDesktopShortcut -and (Test-Path -LiteralPath $destReadme)){
  try{
    $desktop = [Environment]::GetFolderPath('Desktop')
    $lnk = Join-Path $desktop 'Pack – Master README.lnk'
    $wsh = New-Object -ComObject WScript.Shell
    $sc  = $wsh.CreateShortcut($lnk)
    $sc.TargetPath = $destReadme
    $sc.WorkingDirectory = $PackRoot
    $sc.IconLocation = "$env:SystemRoot\system32\shell32.dll,13"
    $sc.Save()
  }catch{
    Write-Warning "Could not create Desktop shortcut: $($_.Exception.Message)"
  }
}

# ----- Report + open -----
Write-Host ""
Write-Host ("Pack ready at: " + $PackRoot) -ForegroundColor Green
"{0,-34} {1}" -f 'INDEX.md present:',  (Test-Path -LiteralPath $destIndex)
"{0,-34} {1}" -f 'Master README present:', (Test-Path -LiteralPath $destReadme)
"{0,-34} {1}" -f 'Scripts dir:', (Test-Path -LiteralPath $ScriptsDir)
"{0,-34} {1}" -f 'Logs dir:',    (Test-Path -LiteralPath $LogsDir)
if($IncludeQuarantine){
  "{0,-34} {1}" -f 'Quarantine dir:', (Test-Path -LiteralPath $QuarDir)
}
if($AdditionalDirs){
  foreach($a in $AdditionalDirs){
    if(-not [string]::IsNullOrWhiteSpace($a)){
      "{0,-34} {1}" -f ("Dir: " + $a), (Test-Path -LiteralPath (Join-Path $PackRoot $a))
    }
  }
}

if($OpenWhenDone){
  Start-Process explorer.exe $PackRoot
  if(Test-Path -LiteralPath $destReadme){ Start-Process $destReadme }
}
