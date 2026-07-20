[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$selector=Join-Path $PSScriptRoot 'Invoke-Phase08R10PreLive.ps1'
if(-not(Test-Path -LiteralPath $selector -PathType Leaf)){throw 'P08-R10-PRELIVE-MISSING: r10 zero-write selector is required.'}

$source=Get-Content -LiteralPath $selector -Raw
foreach($required in @('refs/tags/modules-v0.1.0-r10','attempt_zero,r1,r2,r3,r4,r5,r6,r7,r8,r9','P08-PREPARE-HISTORY-SCHEMA','mnf-phase08-r10-handoff.json','git ls-remote --tags','historical_r9_sha256','historical_history_set_sha256','output_write_count=0')){
  if($source.IndexOf($required,[StringComparison]::Ordinal)-lt 0){throw "P08-R10-PRELIVE-STATIC: missing '$required'."}
}
foreach($forbidden in @('PublishOne','Invoke-MooncakesLiveMutation','MOONCAKES_TOKEN','gh workflow run','git tag ','git push ')){
  if($source.IndexOf($forbidden,[StringComparison]::Ordinal)-ge 0){throw "P08-R10-PRELIVE-NO-WRITE: forbidden live side effect token '$forbidden'."}
}

function Confirm-P08R10Failure([string]$Id,[scriptblock]$Action){
  $failure=$null;try{&$Action}catch{$failure=$_.Exception.Message}
  if($null -eq $failure -or -not $failure.StartsWith("$Id`: ",[StringComparison]::Ordinal)){throw "P08-R10-PRELIVE-NEGATIVE: expected $Id, got '$failure'."}
}

$root=Join-Path ([IO.Path]::GetTempPath()) ('mnf-r10-prelive-'+[Guid]::NewGuid().ToString('N'))
try{
  $null=New-Item -ItemType Directory -Path $root
  $policy=Get-Content -LiteralPath (Join-Path $repoRoot 'policy/release-control.json') -Raw|ConvertFrom-Json -Depth 100
  $fixture=Join-Path $root 'fixture.json'
  [IO.File]::WriteAllText($fixture,($policy|ConvertTo-Json -Depth 100 -Compress),[Text.UTF8Encoding]::new($false))
  $remote=@(
    "20907c7bbd11b91d4482dd113d149b3a107c9672`trefs/tags/modules-v0.1.0-r8",
    "8d0f050a2ea2a5f136d87f913987d59ea99a13d4`trefs/tags/modules-v0.1.0-r8^{}",
    "79d4fa715c6d306e5435d5920c5f92111d5ce13a`trefs/tags/modules-v0.1.0-r9",
    "4158dff7d3b6629861d4f5325573c45f3e3e3436`trefs/tags/modules-v0.1.0-r9^{}"
  )
  $result=& $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $fixture -RemoteTagRows $remote -LibraryOnly
  $value=$result|ConvertFrom-Json -Depth 30
  if((@($value.PSObject.Properties.Name)-join ',') -cne 'schema_version,release_ref,historical_r9_sha256,history_set_sha256,remote_tag_query_count,active_attempt_path,exact_existing_authority_path,mutation_authorization_packet_path,authorization_receipt_path,fixed_handoff_path,observation_path,mutation_count,output_write_count,eligible'){throw 'P08-R10-PRELIVE-CLOSED: sanitized result shape drifted.'}
  if($value.release_ref -cne 'refs/tags/modules-v0.1.0-r10' -or $value.remote_tag_query_count -ne 1 -or $value.output_write_count -ne 0 -or $value.mutation_count -ne 0 -or $value.eligible -ne $true){throw 'P08-R10-PRELIVE-POSITIVE: valid fixture did not remain zero-write eligible.'}
  if($null -ne $value.active_attempt_path -or $null -ne $value.exact_existing_authority_path -or $null -ne $value.mutation_authorization_packet_path -or $null -ne $value.authorization_receipt_path -or $null -ne $value.observation_path){throw 'P08-R10-PRELIVE-ZERO-MUTATION: selector leaked authority or mutation artifacts.'}
  Confirm-P08R10Failure 'P08-R10-HISTORY' { $bad=$policy|ConvertTo-Json -Depth 100|ConvertFrom-Json -Depth 100;$bad.initial_attempt_family.terminal_negative_history[8].record_sha256=$bad.initial_attempt_family.terminal_negative_history[7].record_sha256;$path=Join-Path $root 'bad-r8.json';[IO.File]::WriteAllText($path,($bad|ConvertTo-Json -Depth 100 -Compress),[Text.UTF8Encoding]::new($false));& $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $path -RemoteTagRows $remote -LibraryOnly }
  Confirm-P08R10Failure 'P08-R10-R9-TERMINAL' { $bad=$policy|ConvertTo-Json -Depth 100|ConvertFrom-Json -Depth 100;$bad.initial_attempt_family.terminal_negative_history[9].active_attempt_count=1;$path=Join-Path $root 'bad-r9.json';[IO.File]::WriteAllText($path,($bad|ConvertTo-Json -Depth 100 -Compress),[Text.UTF8Encoding]::new($false));& $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $path -RemoteTagRows $remote -LibraryOnly }
  Confirm-P08R10Failure 'P08-R10-REMOTE-TAG' { & $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $fixture -RemoteTagRows @($remote[0..2]) -LibraryOnly }
  Confirm-P08R10Failure 'P08-R10-REMOTE-TAG' { & $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $fixture -RemoteTagRows @($remote + "f$('0'*39)`trefs/tags/modules-v0.1.0-r10") -LibraryOnly }
  Confirm-P08R10Failure 'P08-R10-HANDOFF' { $handoff=Join-Path $root 'mnf-phase08-r10-handoff.json';[IO.File]::WriteAllText($handoff,'x',[Text.UTF8Encoding]::new($false));& $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $fixture -RemoteTagRows $remote -HandoffPath $handoff -LibraryOnly }
}finally{if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}}

Write-Host 'Phase 8 r10 zero-write pre-live selector: PASS.'
