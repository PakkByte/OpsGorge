<# ===================== A-Run_DeepDive_Audit.ps1 =====================
Purpose:
  1) (Optional) Launch your Mode 1 Audit script.
  2) Auto-find newest cleanup_audit_*.json under ..\2-Logs.
  3) Run B-Apply_DeepDive_Audit.ps1 as DRY RUN, then prompt to EXECUTE.

Safe defaults:
  - Pack-local quarantine and Archives are pre-wired.
  - Asks for MinSizeMB (press Enter for 0 = no filter).
====================================================================== #>

[CmdletBinding()]
param(
  [int]$MinSizeMB,
  [switch]$SkipAuditLaunch
)

# ====== PACK PATHS (edit once here if your root moves) ======
$PackRoot       = 'D:\UserData\Pakks\Drive Deep Dive'
$LogsRoot       = Join-Path $PackRoot '2-Logs'
$ScriptsRoot    = Join-Path $PackRoot '1-Scripts'
$AuditScript    = Join-Path $ScriptsRoot 'DeepDive_Audit.ps1'  # your existing Mode-1 scanner (optional)

# Prompt for MinSizeMB if not supplied
if (-not $PSBoundParameters.ContainsKey('MinSizeMB')) {
  $in = Read-Host "Minimum size (MB) to act on (Enter = 0, no filter)"
  if ([string]::IsNullOrWhiteSpace($in)) { $MinSizeMB = 0 }
  else {
    $ok = [int]::TryParse($in, [ref]$MinSizeMB)
    if (-not $ok) { Write-Warning "Invalid number. Using 0."; $MinSizeMB = 0 }
  }
}
Write-Host "MinSizeMB: $MinSizeMB MB"

# 1) Optionally run your Mode 1 audit (spawn a clean pwsh)
if (-not $SkipAuditLaunch) {
  if (Test-Path -LiteralPath $AuditScript) {
    Write-Host "`n>>> Running Mode 1 (Audit): $AuditScript"
    try {
      & pwsh -NoProfile -ExecutionPolicy Bypass -File $AuditScript
    } catch {
      Write-Host "[error] Audit launch failed: $($_.Exception.Message)" -ForegroundColor Red
      throw
    }
  } else {
    Write-Host "Audit launch skipped (no script at: $AuditScript)."
  }
}


# 2) Find newest audit JSON
if (-not (Test-Path -LiteralPath $LogsRoot)) { throw "Logs folder not found: $LogsRoot" }
$latest = Get-ChildItem $LogsRoot -Recurse -Filter 'cleanup_audit_*.json' -ErrorAction SilentlyContinue |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $latest) { throw "No cleanup_audit_*.json found under $LogsRoot. Run Mode 1 first." }

# 3) Run Part B (DRY) then ask to Execute
$ApplyScript = Join-Path $ScriptsRoot 'B-Apply_DeepDive_Audit.ps1'
if (-not (Test-Path -LiteralPath $ApplyScript)) { throw "Missing: $ApplyScript" }

Write-Host "`nAudit loaded:"
Write-Host "  $($latest.FullName)"

Write-Host "`nRunning Mode 2 (APPLY) as a DRY RUN..." -ForegroundColor Yellow
& $ApplyScript -AuditJson $latest.FullName -MinSizeMB $MinSizeMB
Write-Host "`n--- DRY RUN finished ---" -ForegroundColor Yellow

$go = Read-Host "Apply for REAL now? Type YES to proceed (anything else cancels)"
if ($go -match '^(?i:yes|y)$') {
  & $ApplyScript -AuditJson $latest.FullName -MinSizeMB $MinSizeMB -Execute
  Write-Host "`nEXECUTION finished."
} else {
  Write-Host "Canceled. To apply later, run:"
  Write-Host "  & `"$ApplyScript`" -AuditJson `"$($latest.FullName)`" -MinSizeMB $MinSizeMB -Execute"
}

Read-Host "Done. Press Enter to close" | Out-Null
