<# 
.SYNOPSIS
  Auto-detect repo root and run DoD (Strict) with Policy↔Exclusions parity.

.USAGE
  pwsh -NoProfile -File .\Run-DoD-Auto.ps1
#>

[CmdletBinding()]
param(
  [switch]$VerboseScan   # optional: prints all candidates scored
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Note([string]$m){ Write-Host $m -ForegroundColor Cyan }
function Warn([string]$m){ Write-Host $m -ForegroundColor Yellow }
function Fail([string]$m){ Write-Error $m; exit 1 }

# --- Helpers ---------------------------------------------------------------

function Get-FixedDriveRoots {
  Get-PSDrive -PSProvider FileSystem |
    Where-Object { $_.Root -and $_.DisplayRoot -eq $null } |
    ForEach-Object { $_.Root } |
    Where-Object {
      try {
        # 3 = fixed disk (best-effort; skip optical/removable)
        ($_.Substring(0,1) -match '^[A-Z]$') -and
        ((Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($_)'").DriveType -eq 3)
      } catch { $true }
    }
}

function Test-File($p){ try { Test-Path -LiteralPath $p -PathType Leaf } catch { $false } }
function Test-Dir($p){ try { Test-Path -LiteralPath $p -PathType Container } catch { $false } }

function Score-Candidate([string]$root){
  $score = 0
  $paths = @{
    Policy     = Join-Path $root 'Policy.json'
    Exclusions = Join-Path $root 'apply_exclusions.json'
    Logs       = Join-Path $root '2-Logs'
    CheckDod   = Join-Path $root 'scripts\check-dod.ps1'
    WF         = Join-Path $root '.github\workflows\validate.yml'
    BrainCaps  = Join-Path $root 'brain\Brain_MegaCapsule.md'
  }

  if(Test-File $paths.Policy)     { $score += 40 }
  if(Test-File $paths.Exclusions) { $score += 40 }
  if(Test-Dir  $paths.Logs)       { $score += 10 }
  if(Test-File $paths.CheckDod)   { $score += 20 }
  if(Test-File $paths.WF)         { $score += 10 }
  if(Test-File $paths.BrainCaps)  { $score += 5  }

  # Bonus if both policy+exclusions AND DoD exist together
  if((Test-File $paths.Policy) -and (Test-File $paths.Exclusions) -and (Test-File $paths.CheckDod)){ $score += 20 }

  [pscustomobject]@{
    Root = $root
    Score = $score
    Paths = $paths
  }
}

function Find-CheckDod-Near([string]$root){
  # Prefer canonical path; else search nearby
  $canonical = Join-Path $root 'scripts\check-dod.ps1'
  if(Test-File $canonical){ return $canonical }

  $hit = Get-ChildItem -LiteralPath $root -Recurse -File -Filter 'check-dod.ps1' -Depth 6 -ErrorAction SilentlyContinue |
         Select-Object -First 1
  if($hit){ return $hit.FullName }
  $null
}

# --- Candidate discovery ---------------------------------------------------

# (1) Prefer current directory if it already looks like the repo
$current = (Resolve-Path ".").Path
$candidates = New-Object System.Collections.Generic.List[object]

$candidates.Add((Score-Candidate $current))

# (2) Scan fixed drives up to reasonable depth for directories that have Policy.json + apply_exclusions.json
foreach($drive in Get-FixedDriveRoots){
  try {
    Get-ChildItem -LiteralPath $drive -Directory -Recurse -Depth 6 -ErrorAction SilentlyContinue |
      ForEach-Object {
        $p = Join-Path $_.FullName 'Policy.json'
        $e = Join-Path $_.FullName 'apply_exclusions.json'
        if(Test-File $p -and Test-File $e){
          $candidates.Add((Score-Candidate $_.FullName))
        }
      }
  } catch { }
}

# Add a known common location (if exists) to bias selection without hardcoding user edits
$likely = @(
  'D:\UserData\Pakks\Drive Deep Dive',
  'D:\Drive Deep Dive',
  'C:\Users\tyler\Drive Deep Dive'
) | Where-Object { Test-Dir $_ }

foreach($l in $likely){ $candidates.Add((Score-Candidate $l)) }

# Deduplicate by root, then sort by score
$candidates = $candidates | Group-Object Root | ForEach-Object { $_.Group | Select-Object -First 1 }
if($VerboseScan){ $candidates | Sort-Object Score -Descending | Format-Table -AutoSize | Out-String | Write-Host }

$best = $candidates | Sort-Object Score -Descending | Select-Object -First 1
if(-not $best -or $best.Score -lt 60){
  Warn "No strong repo candidate found (need Policy.json + apply_exclusions.json)."
  Warn "Falling back to current directory: $current"
  $best = (Score-Candidate $current)
}

$RepoRoot = $best.Root
$CheckDod = Find-CheckDod-Near $RepoRoot

if(-not $CheckDod){
  Fail "Could not locate scripts\check-dod.ps1 under '$RepoRoot'. Run your bootstrap once, then re-run this script."
}

Note "RepoRoot: $RepoRoot"
Note "check-dod.ps1: $CheckDod"

# --- Sanity touches (ensure minimal logs exist so DoD won’t fail on emptiness)
$logs = Join-Path $RepoRoot '2-Logs'
if(-not (Test-Dir $logs)){ New-Item -ItemType Directory -Path $logs | Out-Null }
$init = Join-Path $logs 'restore_map_init.json'
if(-not (Test-File $init)){ '{}' | Set-Content -LiteralPath $init -Encoding UTF8 }

# --- Execute DoD (Strict + Parity) ----------------------------------------
$cmd = "pwsh -NoProfile -File `"$CheckDod`" -Strict -ComparePolicyExclusions -RepoRoot `"$RepoRoot`""
Note "Running: $cmd"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "pwsh"
$psi.ArgumentList = @("-NoProfile","-File",$CheckDod,"-Strict","-ComparePolicyExclusions","-RepoRoot",$RepoRoot)
$psi.WorkingDirectory = $RepoRoot
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false

$p = New-Object System.Diagnostics.Process
$p.StartInfo = $psi
$p.Start() | Out-Null
$p.WaitForExit()

$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()

if($stdout){ Write-Host $stdout }
if($st
