[CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0

.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0

) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0

.Name -notlike '.env*' )
  }?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0

.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0

) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0

.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0

.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0

) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0

.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0

.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0

) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    ( ([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.FullName -notmatch (($ExcludePaths | ForEach-Object { [regex]::Escape([CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
) }) -join '|')) ) -and
    ( [CmdletBinding()]
param(
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSCommandPath

# Exclusions
$ExcludePaths = @(
  'automation/ollama/models',
  'automation/workflows/n8n-data',
  'automation/.env',
  'automation/.env.mac', 'automation/.env.mac.local', 'automation/.env.mac.sample',
  'automation/.env.pc',  'automation/.env.pc.local',  'automation/.env.pc.sample'
)

# Allow env vars after password, flag literals
$PasswordRegex = '(?i)password\s*[:=]\s*(?!\$\{?[A-Z0-9_]+\}?\b).+'

# Enumerate files, respecting exclusions
$files = Get-ChildItem $repo -Recurse -File -ErrorAction Ignore |
  Where-Object {
    $_.FullName -notmatch ($ExcludePaths -join '|') -and $_.Name -notlike '.env*'
  }

$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0

.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0
.Name -notlike '.env*' )
  }$hits = @()
foreach ($f in $files) {
  $text = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Ignore
  if ($null -ne $text -and $text -match $PasswordRegex) {
    $hits += [pscustomobject]@{
      Path    = $f.FullName.Substring($repo.Length + 1)
      Pattern = $PasswordRegex
    }
  }
}

if ($hits.Count -gt 0) {
  "Path`tPattern"
  "----`t-------"
  $hits | ForEach-Object { "$($_.Path)`t$($PasswordRegex)" } | Write-Host
  throw "Secret scan found $($hits.Count) potential hit(s)."
}

Write-Host "Definition of Done (Strict): PASS"
exit 0


