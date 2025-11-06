<# ======================================================================
Assess-BrainAndCIPack.ps1  (clean, parser-safe)
Purpose:
  - Inventory CI + PL gate + brain folders (Global/Project/Chat)
  - Parse headers (INHERITS_FROM/SCOPE/INTENT)
  - Validate Tests.md (T1..T4), Lessons.md presence
  - Parse PL schema (YAML block) or PL-Score line
  - Detect PR template and validate key checklist markers
  - Find potential overlap across layers (long duplicate lines)
  - Capture git facts (branch, tags brain-*)
  - Emit: JSON summary + Markdown report + raw snapshots
====================================================================== #>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$false)][string]$ProjectName,
  [Parameter(Mandatory=$false)][string]$ChatRole
)

function New-Dir([string]$p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Read-File([string]$path){ if(Test-Path $path){ Get-Content -Raw -LiteralPath $path } else { $null } }

function Get-HeaderInfo([string]$text){
  if(-not $text){ return $null }
  [ordered]@{
    INHERITS_FROM = ($text | Select-String -Pattern '^\s*INHERITS_FROM:\s*(.+)$' -AllMatches).Matches.Value
    SCOPE         = ($text | Select-String -Pattern '^\s*SCOPE:\s*(.+)$' -AllMatches).Matches.Value
    INTENT        = ($text | Select-String -Pattern '^\s*INTENT:\s*(.+)$' -AllMatches).Matches.Value
  }
}

function Parse-Tests([string]$text){
  if(-not $text){ return $null }
  $expect = 'T1','T2','T3','T4'
  $present = @{}
  foreach($t in $expect){ $present[$t] = ($text -match "(?m)^\s*$t\b") }
  [ordered]@{
    PresentT1 = $present['T1']; PresentT2 = $present['T2']
    PresentT3 = $present['T3']; PresentT4 = $present['T4']
    AllPresent = ($present.Values -notcontains $false)
  }
}

function Parse-PL([string]$text){
  if(-not $text){ return $null }
  $yamlFound = $false
  if($text -match '(?s)^\s*pl\s*:\s*[\r\n]+.*'){ $yamlFound = $true }
  $score = $null
  $m = [regex]::Match($text, 'PL-Score:\s*(\d+)\s*/\s*10', 'IgnoreCase')
  if($m.Success){ $score = [int]$m.Groups[1].Value }
  [ordered]@{ FoundYAML=[bool]$yamlFound; FoundScore=[bool]$score; Score=$score }
}

function LongLines([string]$text,[int]$minLen=80){
  if(-not $text){ return @() }
  ($text -split "`r?`n") | Where-Object { $_.Trim().Length -ge $minLen } | Select-Object -Unique
}

function Compare-Overlap($aLines,$bLines){
  if(-not $aLines -or -not $bLines){ return @() }
  $hash = [System.Collections.Generic.HashSet[string]]::new()
  foreach($l in $aLines){ $hash.Add($l.Trim()) | Out-Null }
  $over=@()
  foreach($l in $bLines){
    $lt=$l.Trim()
    if($hash.Contains($lt)){ $over+=$lt }
  }
  $over | Select-Object -Unique
}

function Git-Facts([string]$root){
  $facts=[ordered]@{ gitAvailable=$false; branch=$null; tags=@() }
  try{ $git=(Get-Command git -ErrorAction Stop).Path; if($git){ $facts.gitAvailable=$true } }catch{}
  if($facts.gitAvailable){
    Push-Location $root
    try{ $facts.branch = (git rev-parse --abbrev-ref HEAD 2>$null) }catch{}
    try{ $facts.tags   = (git tag --list "brain-*-v*" 2>$null) }catch{}
    Pop-Location
  }
  return $facts
}

# --- Setup output dirs
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$outDir  = Join-Path $RepoRoot ("2-Logs/assessment_{0}" -f $ts)
$snapDir = Join-Path $outDir "snapshots"
New-Dir $outDir; New-Dir $snapDir

# --- Targets
$paths = [ordered]@{
  WorkflowValidate = ".github/workflows/validate.yml"
  PRTemplate       = ".github/pull_request_template.md"
  PLFallback       = "PL.md"
  DoDScript        = "scripts/check-dod.ps1"
  Global_System    = "brain_global/System_Brief.md"
  Global_Prompts   = "brain_global/Prompt_Pack.md"
  Global_PLSpec    = "brain_global/Performance_Loop.md"
  Global_Index     = "brain_global/INDEX.md"
}

$projectRoot = if($ProjectName){ "projects/$ProjectName" } else { "projects/*" }
$chatRoot    = if($ProjectName -and $ChatRole){ "projects/$ProjectName/chats/$ChatRole" } elseif($ProjectName){ "projects/$ProjectName/chats/*" } else { "projects/*/chats/*" }

$paths['Project_Seed']    = "$projectRoot/brain/Project_Seed.md"
$paths['Project_Tests']   = "$projectRoot/brain/Tests.md"
$paths['Project_Lessons'] = "$projectRoot/brain/Lessons.md"
$paths['Project_Index']   = "$projectRoot/brain/INDEX.md"

$paths['Chat_Brief']      = "$chatRoot/brain/Chat_Brief.md"
$paths['Chat_Examples']   = "$chatRoot/brain/Examples.md"
$paths['Chat_Errors']     = "$chatRoot/brain/Error_Log.md"
$paths['Chat_Index']      = "$chatRoot/brain/INDEX.md"

# --- Collect
$results = [ordered]@{
  repoRoot=$RepoRoot; timestamp=$ts; files=@{}; tests=@{}; pl=@{}
  headers=@{}; overlaps=@{}; git=(Git-Facts $RepoRoot); notes=@()
}

foreach($k in $paths.Keys){
  $rel = $paths[$k]
  $full = Join-Path $RepoRoot $rel
  $found = Get-ChildItem -LiteralPath $full -ErrorAction SilentlyContinue
  if(-not $found -and $rel -like "*/*"){
    $glob = Get-ChildItem -Path (Join-Path $RepoRoot $rel) -ErrorAction SilentlyContinue -Recurse:$false
    if($glob){ $found = $glob }
  }
  $entries=@()
  if($found){
    foreach($f in @($found)){
      $text = $null
      try{ if($f.Extension -in ".md",".yml",".yaml",".ps1"){ $text = Read-File $f.FullName } }catch{}
      $e=[ordered]@{
        path = $f.FullName.Substring($RepoRoot.Length).TrimStart('\','/')
        size = $f.Length
        lastWrite = $f.LastWriteTimeUtc.ToString("u")
        header = if($f.Extension -eq ".md"){ Get-HeaderInfo $text } else { $null }
        tests  = if($f.Name -eq "Tests.md"){ Parse-Tests $text } else { $null }
        pl     = if($f.Name -eq "PL.md"){ Parse-PL $text } else { $null }
        previewPath = $null
      }
      if($text){
        $pp = Join-Path $snapDir ($f.Name.Replace('.','_') + ".txt")
        Set-Content -LiteralPath $pp -Value $text -Encoding UTF8
        $e.previewPath = $pp.Substring($RepoRoot.Length).TrimStart('\','/')
      }
      $entries += $e
    }
  }
  $results.files[$k] = $entries
}

# --- Overlap checks
$gText = Read-File (Join-Path $RepoRoot $paths.Global_System)
$gLong = LongLines $gText

$overProject=@{}
$pSeeds = @(Get-ChildItem -Path (Join-Path $RepoRoot $paths.Project_Seed) -ErrorAction SilentlyContinue)
foreach($ps in $pSeeds){
  $pt = Read-File $ps.FullName
  $plong = LongLines $pt
  $over = Compare-Overlap $gLong $plong
  if($over.Count -gt 0){ $overProject[$ps.FullName.Substring($RepoRoot.Length).TrimStart('\','/')] = $over }
}

$overChat=@{}
$cBriefs = @(Get-ChildItem -Path (Join-Path $RepoRoot $paths.Chat_Brief) -ErrorAction SilentlyContinue)
foreach($cb in $cBriefs){
  $ct = Read-File $cb.FullName
  $clong = LongLines $ct
  $over = Compare-Overlap $gLong $clong
  if($over.Count -gt 0){ $overChat[$cb.FullName.Substring($RepoRoot.Length).TrimStart('\','/')] = $over }
}

$results.overlaps.Global_vs_Project = $overProject
$results.overlaps.Global_vs_Chat    = $overChat

# --- Aggregate summaries
$testsFiles = $results.files.GetEnumerator() | Where-Object { $_.Key -eq 'Project_Tests' } | ForEach-Object { $_.Value } | Select-Object -ExpandProperty tests -ErrorAction SilentlyContinue
if($testsFiles){ $any = $testsFiles | Where-Object { $_ -ne $null } | Select-Object -First 1; $results.tests = $any }
$plFiles = $results.files.GetEnumerator() | Where-Object { $_.Key -eq 'PLFallback' } | ForEach-Object { $_.Value } | Select-Object -ExpandProperty pl -ErrorAction SilentlyContinue
if($plFiles){ $any = $plFiles | Where-Object { $_ -ne $null } | Select-Object -First 1; $results.pl = $any }

# --- Markdown report (parser-safe; no backticks in inline expr)
$md = @()
$md += "# Assessment — CI + PL + Brain Structure"
$md += ""
$md += ("Repo: {0}" -f $results.repoRoot)
$md += ("When: {0} UTC" -f $results.timestamp)
$md += ""
$md += "## Summary"
$branch = if($results.git.branch){ $results.git.branch } else { "(n/a)" }
$tags   = if($results.git.tags -and $results.git.tags.Count -gt 0){ ($results.git.tags -join ", ") } else { "(none found)" }
$testsPresent = if($results.tests){ $results.tests.AllPresent } else { "(n/a)" }
$plFoundScore = if($results.pl){ $results.pl.FoundScore } else { "(n/a)" }
$plScore = if($results.pl -and $results.pl.Score){ $results.pl.Score } else { "(n/a)" }
$md += (" - Git branch: {0}" -f $branch)
$md += (" - Brain tags: {0}" -f $tags)
$md += (" - Tests.md T1..T4 present: {0}" -f $testsPresent)
$md += (" - PL.md score line found: {0} (Score: {1})" -f $plFoundScore, $plScore)
$md += ""
$md += "## Files Found"
foreach($entry in $results.files.GetEnumerator()){
  $md += ("### {0}" -f $entry.Key)
  if($entry.Value.Count -eq 0){ $md += "- (none)" }
  foreach($f in $entry.Value){
    $md += ("- {0}  | {1} KB | {2} UTC" -f $f.path, [Math]::Round($f.size/1KB,2), $f.lastWrite)
    if($f.header){
      $hdr = ($f.header.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, ($_.Value -replace '^(INHERITS_FROM:|SCOPE:|INTENT:)\s*','') }) -join '; '
      $md += ("  - Header: {0}" -f $hdr)
    }
    if($f.tests){  $md += ("  - Tests: T1={0}, T2={1}, T3={2}, T4={3}" -f $f.tests.PresentT1, $f.tests.PresentT2, $f.tests.PresentT3, $f.tests.PresentT4) }
    if($f.pl){     $md += ("  - PL: FoundScore={0} Score={1}" -f $f.pl.FoundScore, $f.pl.Score) }
  }
}
$md += ""
$md += "## Overlap (long identical lines ≥80 chars)"
if($results.overlaps.Global_vs_Project.Keys.Count -eq 0 -and $results.overlaps.Global_vs_Chat.Keys.Count -eq 0){
  $md += "- None detected."
} else {
  foreach($k in $results.overlaps.Global_vs_Project.Keys){
    $md += ("### Global vs Project — {0}" -f $k)
    $results.overlaps.Global_vs_Project[$k] | ForEach-Object { $md += ("- {0}" -f $_) }
  }
  foreach($k in $results.overlaps.Global_vs_Chat.Keys){
    $md += ("### Global vs Chat — {0}" -f $k)
    $results.overlaps.Global_vs_Chat[$k] | ForEach-Object { $md += ("- {0}" -f $_) }
  }
}
$md += ""
$md += "## Opinions & Flags"
$md += "- Prefer repo-relative paths (no drive letters) in CI."
$md += "- Keep Tests.md short with T1..T4 so [QA CHECK] is fast."
$md += "- PL.md: include 'PL-Score: X/10' or tiny YAML block for parsing."
$md += "- Every *.md should start with 'INHERITS_FROM / SCOPE / INTENT' header."
$md += "- Remove duplicated long lines across Global → Project → Chat."
$md += ""
$md += "## What to send me back"
$md += "- The generated assessment.md + assessment.json."
$md += "- Any snapshots/*.txt you want me to read closely."

# --- Save
$mdPath   = Join-Path $outDir "assessment.md"
$jsonPath = Join-Path $outDir "assessment.json"
$results | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
($md -join "`r`n") | Set-Content -LiteralPath $mdPath -Encoding UTF8

Write-Host ""
Write-Host "=== Assessment Pack Ready ===" -ForegroundColor Cyan
Write-Host ("Report:    {0}" -f $mdPath)
Write-Host ("JSON:      {0}" -f $jsonPath)
Write-Host ("Snapshots: {0}" -f $snapDir)
