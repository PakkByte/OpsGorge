[CmdletBinding()]
param(
  [string]$Root = (Split-Path (Split-Path -Parent $MyInvocation.MyCommand.Path)),
  [int]$MinSizeMB = 100
)
$ErrorActionPreference = "Stop"
$Scripts = Join-Path $Root "1-Scripts"
$Logs    = Join-Path $Root "2-Logs"

$need = @("A-Run_DeepDive_Audit.ps1","B-Apply_DeepDive_Audit.ps1","C-Delete.ps1","apply_exclusions.json","PreFilter_And_Apply.ps1","Update-IndexAndReadme.ps1")
$missing = foreach($n in $need){ if (-not (Test-Path (Join-Path $Scripts $n))) { $n } }
if ($missing){ Write-Host "Missing scripts:" -ForegroundColor Yellow; $missing | ForEach-Object{Write-Host " - $_"}; return }

# Policy snapshot + diff
& (Join-Path $Scripts "New-PolicySnapshot.ps1")     2>$null
& (Join-Path $Scripts "Policy_Diff.ps1")            2>$null

# Run AUDIT (Mode 1) via A-Run script (writes JSON in 2-Logs)
& (Join-Path $Scripts "A-Run_DeepDive_Audit.ps1")   2>$null

# Pick latest audit
$audit = Get-ChildItem $Logs -Filter "cleanup_audit_*.json" | Sort-Object LastWriteTime -Desc | Select-Object -First 1
if (-not $audit){ throw "No audit JSON produced." }

# Prefilter + DRY Apply
& (Join-Path $Scripts "PreFilter_And_Apply.ps1") -AuditJson $audit.FullName -MinSizeMB $MinSizeMB

# Telemetry CSV from latest Apply log
& (Join-Path $Scripts "Analyze-LastApplyLog.ps1")  2>$null

# Refresh docs
& (Join-Path $Scripts "Update-IndexAndReadme.ps1") -Root $Root

Write-Host "Preflight + DRY complete." -ForegroundColor Green
