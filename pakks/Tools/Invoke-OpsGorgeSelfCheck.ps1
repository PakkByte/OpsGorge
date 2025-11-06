[CmdletBinding()] param([string]$RepoRoot="D:\Repos\OpsGorge",[switch]$Fix)
$ErrorActionPreference='Stop'; Set-StrictMode -Version Latest
function Note($m){Write-Host $m -ForegroundColor Cyan}
function Test-File($p){try{Test-Path -LiteralPath $p -PathType Leaf}catch{$false}}
function Test-Dir($p){try{Test-Path -LiteralPath $p -PathType Container}catch{$false}}
# (… full body unchanged …)
# minimal tail so you *see* it start:
Note "Self-check starting… RepoRoot => $RepoRoot"
# Paths
$pol=Join-Path $RepoRoot 'Policy.json'; $exc=Join-Path $RepoRoot 'apply_exclusions.json'
$logDir=Join-Path $RepoRoot '2-Logs'; $scr=Join-Path $RepoRoot 'scripts'
$dod=Join-Path $scr 'check-dod.ps1'; $pl=Join-Path $RepoRoot 'PL.md'
# Quick existence report
"{0}`n- {1}`n- {2}`n- {3}" -f "Key files:", $pol,$exc,$dod | Write-Host
# Run DoD
if(Test-File $dod){
  Note "Running DoD (Strict + Parity)…"
  & pwsh -NoProfile -File $dod -Strict -ComparePolicyExclusions -RepoRoot $RepoRoot
}else{
  Write-Host "DoD script missing: $dod" -ForegroundColor Yellow
}
Write-Host "`n===== OpsGorge Self-Check (done) ====="
Read-Host "Press Enter to close"
