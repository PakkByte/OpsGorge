[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$Root,
  [Parameter(Mandatory=$true)][string]$OtherPath,
  [string]$Project='CT'
)
$ErrorActionPreference='Stop'
$targets=@(
  'PL.md',
  '.github\pull_request_template.md',
  '.github\workflows\validate.yml',
  'brain_global\System_Brief.md',
  'brain_global\Prompt_Pack.md',
  'brain_global\Performance_Loop.md',
  'brain_global\INDEX.md',
  "projects\$Project\brain\Project_Seed.md",
  "projects\$Project\brain\Tests.md",
  "projects\$Project\brain\Lessons.md",
  "projects\$Project\brain\INDEX.md",
  "projects\$Project\chats\Audits\brain\Chat_Brief.md",
  "projects\$Project\chats\Audits\brain\Examples.md",
  "projects\$Project\chats\Audits\brain\Error_Log.md",
  "projects\$Project\chats\Audits\brain\INDEX.md",
  "projects\$Project\chats\PR\brain\Chat_Brief.md",
  "projects\$Project\chats\PR\brain\Examples.md",
  "projects\$Project\chats\PR\brain\Error_Log.md",
  "projects\$Project\chats\PR\brain\INDEX.md",
  "projects\$Project\chats\Advising\brain\Chat_Brief.md",
  "projects\$Project\chats\Advising\brain\Examples.md",
  "projects\$Project\chats\Advising\brain\Error_Log.md",
  "projects\$Project\chats\Advising\brain\INDEX.md",
  'docker-compose.yml',
  'gpv1*.md'
)
function HashSet($base,$rel){
  $p = if($rel -like '*gpv1*.md'){ Get-ChildItem -Path (Join-Path $base $rel) -File -ErrorAction SilentlyContinue }
       else{ Get-Item -LiteralPath (Join-Path $base $rel) -ErrorAction SilentlyContinue }
  foreach($f in ($p | Where-Object { $_ })){
    [PSCustomObject]@{
      RelPath=$f.FullName.Replace((Resolve-Path $base).Path,'').TrimStart('\','/')
      Full=$f.FullName
      Sha256=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
      Size=$f.Length
      Utc=$f.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm:ssZ')
    }
  }
}
$rootAbs=(Resolve-Path -LiteralPath $Root).Path
$otherAbs=(Resolve-Path -LiteralPath $OtherPath).Path
$L=foreach($t in $targets){ HashSet $rootAbs $t }
$R=foreach($t in $targets){ HashSet $otherAbs $t }
$LBy=$L|Group-Object RelPath -AsHashTable -AsString
$RBy=$R|Group-Object RelPath -AsHashTable -AsString
$all=@($L.RelPath+$R.RelPath)|Sort-Object -Unique
$added=@();$removed=@();$changed=@();$identical=0
foreach($k in $all){
  $l=$LBy[$k];$r=$RBy[$k]
  if($l -and -not $r){ $removed+=$l }
  elseif($r -and -not $l){ $added+=$r }
  else{
    if($l.Sha256 -ne $r.Sha256){
      $changed += [PSCustomObject]@{ RelPath=$k; Left=$l.Full; Right=$r.Full; LHash=$l.Sha256; RHash=$r.Sha256; LUtc=$l.Utc; RUtc=$r.Utc }
    } else { $identical++ }
  }
}
"Root:  $rootAbs"
"Other: $otherAbs"
"`n== Added in Other ==";    if($added){$added|Select RelPath,Full,Sha256,Size,Utc|ft -AutoSize}else{"(none)"}
"`n== Removed from Other ==";if($removed){$removed|Select RelPath,Full,Sha256,Size,Utc|ft -AutoSize}else{"(none)"}
"`n== Changed ==";           if($changed){$changed|ft RelPath,LUtc,RUtc,LHash,RHash -AutoSize}else{"(none)"}
"`nIdentical count: $identical"
