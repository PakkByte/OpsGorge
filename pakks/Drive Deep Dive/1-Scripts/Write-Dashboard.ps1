param([string]$Root = "D:\UserData\Pakks\Drive Deep Dive")
$logs = Join-Path $Root "2-Logs"
$dash = Join-Path $logs "Dashboard.md"
function GL([string]$pat){ Get-ChildItem -Path $logs -File -EA SilentlyContinue | ? { $_.Name -like $pat } | sort LastWriteTimeUtc | select -Last 1 }
$apply=GL "Apply_*.txt"; $sum=GL "Apply_Summary_*.csv"; $audit=GL "cleanup_audit_filtered_*.json"; if(-not $audit){$audit=GL "cleanup_audit_*.json"}
$snap=GL "Policy_Snapshot_*.json"; $diff=GL "Policy_Diff_*.txt"
$pol=Get-Content (Join-Path $Root "1-Scripts\Policy.json") -Raw | ConvertFrom-Json
$ab=$pol.ArchiveBase; $mm=$pol.DuplicateRules.MinSizeMB
$L=@("# Drive Deep Dive — Dashboard","","| KPI | Value |","|---|---|",
"| ArchiveBase | " + $ab + " |",
"| MinSizeMB | " + $mm + " |",
"| Latest Apply Log | " + ($apply?.Name ?? "(none)") + " |",
"| Latest Summary | " + ($sum?.Name ?? "(none)") + " |",
"| Latest Audit | " + ($audit?.Name ?? "(none)") + " |",
"| Latest Snapshot | " + ($snap?.Name ?? "(none)") + " |",
"| Latest Diff | " + ($diff?.Name ?? "(none)") + " |","",
"## Artifacts",
"- Apply Log:      " + ($apply?.FullName ?? "(none)"),
"- Summary CSV:    " + ($sum?.FullName ?? "(none)"),
"- Audit JSON:     " + ($audit?.FullName ?? "(none)"),
"- Policy Snapshot:" + ($snap?.FullName ?? "(none)"),
"- Policy Diff:    " + ($diff?.FullName ?? "(none)"),
"",
"> Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
ni -ItemType Directory -Force -Path $logs | Out-Null
$L | Set-Content -Enc UTF8 -LiteralPath $dash
Write-Host "Dashboard written: $dash" -ForegroundColor Green
