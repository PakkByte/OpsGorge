param(
  [string]$Src  = "D:\UserData\Pakks",
  [string]$Dest = "D:\Repos\OpsGorge\pakks",
  [switch]$IncludeLarge,
  [int]$LargeMB = 100
)
$skipDirs  = ".git",".idea",".vscode","__pycache__","node_modules","2-Logs","logs","output","outputs","dist","build"
$excludeByExt = @(".env",".key",".pem",".pfx",".sqlite",".db")

New-Item -ItemType Directory -Force -Path $Dest | Out-Null
$items = Get-ChildItem -Path $Src -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
  $p = $_.FullName.ToLower()
  -not ($skipDirs | ForEach-Object { $p -like "*\$_\*" })
}
$report = @()
foreach($f in $items){
  if(-not $IncludeLarge -and ($f.Length/1MB) -gt $LargeMB){
    $report += [pscustomobject]@{ Status='SKIPPED_LARGE'; Path=$f.FullName; SizeMB=[math]::Round($f.Length/1MB,1) }; continue
  }
  if($excludeByExt -contains $f.Extension.ToLower()){
    $report += [pscustomobject]@{ Status='SKIPPED_SECRETLIKE'; Path=$f.FullName; SizeMB=[math]::Round($f.Length/1MB,1) }; continue
  }
  $rel = $f.FullName.Substring($Src.Length).TrimStart('\','/')
  $destFile = Join-Path $Dest $rel
  New-Item -ItemType Directory -Force -Path (Split-Path $destFile -Parent) | Out-Null
  Copy-Item -LiteralPath $f.FullName -Destination $destFile -Force
  $report += [pscustomobject]@{ Status='COPIED'; Path=$f.FullName; Dest=$destFile; SizeMB=[math]::Round($f.Length/1MB,1) }
}
$logDir = "D:\Repos\OpsGorge\2-Logs"; New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$csv = Join-Path $logDir "pakks_migrate_report_$ts.csv"
$report | Export-Csv -NoTypeInformation -Path $csv -Encoding UTF8
Write-Host "Pakks migration complete. Report: $csv" -ForegroundColor Green
