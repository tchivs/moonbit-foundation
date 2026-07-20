[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$selector=Join-Path $PSScriptRoot 'Invoke-Phase08R9PreLive.ps1'
if(-not(Test-Path -LiteralPath $selector -PathType Leaf)){throw 'P08-R9-PRELIVE-MISSING: r9 zero-write selector is required.'}

$source=Get-Content -LiteralPath $selector -Raw
foreach($required in @('refs/tags/modules-v0.1.0-r9','attempt_zero,r1,r2,r3,r4,r5,r6,r7,r8','PREP15-CANONICAL-ARCHIVE','REL-XPLAT-NONCANONICAL','mnf-phase08-r9-handoff.json','git ls-remote --tags','historical_r8_sha256','historical_history_set_sha256','output_write_count=0')){
  if($source.IndexOf($required,[StringComparison]::Ordinal)-lt 0){throw "P08-R9-PRELIVE-STATIC: missing '$required'."}
}
foreach($forbidden in @('PublishOne','Invoke-MooncakesLiveMutation','MOONCAKES_TOKEN','gh workflow run','git tag ','git push ')){
  if($source.IndexOf($forbidden,[StringComparison]::Ordinal)-ge 0){throw "P08-R9-PRELIVE-NO-WRITE: forbidden live side effect token '$forbidden'."}
}

function Confirm-P08R9Failure([string]$Id,[scriptblock]$Action){
  $failure=$null;try{&$Action}catch{$failure=$_.Exception.Message}
  if($null -eq $failure -or -not $failure.StartsWith("$Id`: ",[StringComparison]::Ordinal)){throw "P08-R9-PRELIVE-NEGATIVE: expected $Id, got '$failure'."}
}

$root=Join-Path ([IO.Path]::GetTempPath()) ('mnf-r9-prelive-'+[Guid]::NewGuid().ToString('N'))
try{
  $null=New-Item -ItemType Directory -Path $root
  $policy=Get-Content -LiteralPath (Join-Path $repoRoot 'policy/release-control.json') -Raw|ConvertFrom-Json -Depth 100
  $fixture=Join-Path $root 'fixture.json'
  [IO.File]::WriteAllText($fixture,($policy|ConvertTo-Json -Depth 100 -Compress),[Text.UTF8Encoding]::new($false))
  $remote=@(
    "20907c7bbd11b91d4482dd113d149b3a107c9672`trefs/tags/modules-v0.1.0-r8",
    "8d0f050a2ea2a5f136d87f913987d59ea99a13d4`trefs/tags/modules-v0.1.0-r8^{}"
  )
  $result=& $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $fixture -RemoteTagRows $remote -LibraryOnly
  $value=$result|ConvertFrom-Json -Depth 30
  if((@($value.PSObject.Properties.Name)-join ',') -cne 'schema_version,release_ref,history_set_sha256,remote_tag_query_count,output_write_count,eligible'){throw 'P08-R9-PRELIVE-CLOSED: sanitized result shape drifted.'}
  if($value.release_ref -cne 'refs/tags/modules-v0.1.0-r9' -or $value.remote_tag_query_count -ne 1 -or $value.output_write_count -ne 0 -or $value.eligible -ne $true){throw 'P08-R9-PRELIVE-POSITIVE: valid fixture did not remain zero-write eligible.'}
  Confirm-P08R9Failure 'P08-R9-HISTORY' { $bad=$policy|ConvertTo-Json -Depth 100|ConvertFrom-Json -Depth 100;$bad.initial_attempt_family.terminal_negative_history[8].record_sha256=$bad.initial_attempt_family.terminal_negative_history[7].record_sha256;$path=Join-Path $root 'bad-history.json';[IO.File]::WriteAllText($path,($bad|ConvertTo-Json -Depth 100 -Compress),[Text.UTF8Encoding]::new($false));& $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $path -RemoteTagRows $remote -LibraryOnly }
  Confirm-P08R9Failure 'P08-R9-REMOTE-TAG' { & $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $fixture -RemoteTagRows @($remote[0]) -LibraryOnly }
  Confirm-P08R9Failure 'P08-R9-REMOTE-TAG' { & $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $fixture -RemoteTagRows @($remote + "f$('0'*39)`trefs/tags/modules-v0.1.0-r9") -LibraryOnly }
  Confirm-P08R9Failure 'P08-R9-HANDOFF' { $handoff=Join-Path $root 'mnf-phase08-r9-handoff.json';[IO.File]::WriteAllText($handoff,'x',[Text.UTF8Encoding]::new($false));& $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $fixture -RemoteTagRows $remote -HandoffPath $handoff -LibraryOnly }
}finally{if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}}

Write-Host 'Phase 8 r9 zero-write pre-live selector: PASS.'
