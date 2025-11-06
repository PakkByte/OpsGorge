<# ===================== DeepDive_Audit.ps1 (param-safe) =====================
Purpose: Make cleanup_audit_<stamp>.json under ..\2-Logs.
Safe: Only writes JSON; no system changes.
Robust: Uses $PSCommandPath and .NET path APIs (no Split-Path param issues).
============================================================================ #>

$ErrorActionPreference = 'Stop'

# --- Resolve PackRoot robustly (no Split-Path) ---
$scriptPath = $PSCommandPath  # full path when running as a .ps1; empty if pasted
if ([string]::IsNullOrWhiteSpace($scriptPath)) {
  # Pasted in the console → hardcode your pack root:
  $PackRoot = 'D:\UserData\Pakks\Drive Deep Dive'
} else {
  $scriptsDir = [System.IO.Path]::GetDirectoryName($scriptPath)
  $PackRoot   = [System.IO.Path]::GetDirectoryName($scriptsDir)
}
$LogsRoot = [System.IO.Path]::Combine($PackRoot, '2-Logs')
New-Item -ItemType Directory -Force -Path $LogsRoot | Out-Null

# --- Optional: find broken .lnk on Desktop/Documents (safe) ---
function Get-DeadLinks {
  $out = @()
  try { $sh = New-Object -ComObject WScript.Shell } catch { return @() }
  foreach($folder in @("$env:USERPROFILE\Desktop","$env:USERPROFILE\Documents")){
    if (-not (Test-Path -LiteralPath $folder)) { continue }
    foreach($lnk in (Get-ChildItem -LiteralPath $folder -Filter *.lnk -EA SilentlyContinue)) {
      try {
        $sc = $sh.CreateShortcut($lnk.FullName)
        $t  = $sc.TargetPath
        if ($t -and -not (Test-Path -LiteralPath $t)) {
          $out += [pscustomobject]@{
            Type      = 'DeadLnk'
            Path      = $lnk.FullName
            SizeBytes = $lnk.Length
            Notes     = "target:$t"
            GroupId   = $null
          }
        }
      } catch {}
    }
  }
  $out
}

# --- Seed minimal, harmless audit items ---
$items = @(
  [pscustomobject]@{
    Type      = 'Keep'      # Apply script will skip
    Path      = $env:TEMP
    SizeBytes = 0
    Notes     = 'seed'
    GroupId   = $null
  }
)
$items += Get-DeadLinks

# --- Write audit JSON ---
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$out   = [System.IO.Path]::Combine($LogsRoot, "cleanup_audit_$stamp.json")
$items | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -LiteralPath $out

Write-Host "[+] Audit written -> $out  (items: $($items.Count))" -ForegroundColor Green
Write-Host "    Next: run A-Run_DeepDive_Audit.ps1 (it will pick up this newest audit)."
