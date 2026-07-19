[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$selector=Join-Path $PSScriptRoot 'Invoke-Phase08R13PreLive.ps1'
if(-not(Test-Path -LiteralPath $selector -PathType Leaf)){throw 'P08-R13-PRELIVE-MISSING: r13 zero-write selector is required.'}
$source=Get-Content -LiteralPath $selector -Raw
foreach($required in @('refs/tags/modules-v0.1.0-r13','attempt_zero,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12','historical_r12_sha256','57b76c9f9044d3190acc1e4c3fb7ada516f4dece','5e7b19cdc74ec11d5c524ff34a36c266b15bba39','Invoke-Phase08R13Boundary.ps1','Test-Phase08R13Boundary.ps1','mnf-phase08-r13-handoff.json','output_write_count=0')){
  if($source.IndexOf($required,[StringComparison]::Ordinal)-lt 0){throw "P08-R13-PRELIVE-STATIC: missing '$required'."}
}
foreach($forbidden in @('PublishOne','Invoke-MooncakesLiveMutation','MOONCAKES_TOKEN','gh workflow run','git tag ','git push ')){
  if($source.IndexOf($forbidden,[StringComparison]::Ordinal)-ge 0){throw "P08-R13-PRELIVE-NO-WRITE: forbidden live side effect token '$forbidden'."}
}
function Confirm-P08R13Failure([string]$Id,[scriptblock]$Action){$failure=$null;try{&$Action}catch{$failure=$_.Exception.Message};if($null -eq $failure -or -not $failure.StartsWith("$Id`: ",[StringComparison]::Ordinal)){throw "P08-R13-PRELIVE-NEGATIVE: expected $Id, got '$failure'."}}
$root=Join-Path ([IO.Path]::GetTempPath()) ('mnf-r13-prelive-'+[Guid]::NewGuid().ToString('N'))
try{
  $null=New-Item -ItemType Directory -Path $root
  $policy=Get-Content -LiteralPath (Join-Path $repoRoot 'policy/release-control.json') -Raw|ConvertFrom-Json -Depth 100
  $fixture=Join-Path $root 'fixture.json';[IO.File]::WriteAllText($fixture,($policy|ConvertTo-Json -Depth 100 -Compress),[Text.UTF8Encoding]::new($false))
  $r12=$policy.initial_attempt_family.terminal_negative_history[12]
  $remote=@("$($r12.tag_object_sha)`trefs/tags/modules-v0.1.0-r12","$($r12.tag_peeled_source_sha)`trefs/tags/modules-v0.1.0-r12`^{}")
  $value=(& $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $fixture -RemoteTagRows $remote -LibraryOnly)|ConvertFrom-Json -Depth 30
  if($value.release_ref -cne 'refs/tags/modules-v0.1.0-r13' -or $value.historical_r12_sha256 -cne $r12.record_sha256 -or $value.remote_tag_query_count -ne 1 -or $value.output_write_count -ne 0 -or $value.mutation_count -ne 0 -or $value.eligible -ne $true){throw 'P08-R13-PRELIVE-POSITIVE: valid r13 fixture did not remain zero-write eligible.'}
  if($null -ne $value.active_attempt_path -or $null -ne $value.exact_existing_authority_path -or $null -ne $value.mutation_authorization_packet_path -or $null -ne $value.authorization_receipt_path -or $null -ne $value.observation_path){throw 'P08-R13-PRELIVE-ZERO-MUTATION: selector leaked authority or mutation artifacts.'}
  Confirm-P08R13Failure 'P08-R13-R12-TERMINAL' {$bad=$policy|ConvertTo-Json -Depth 100|ConvertFrom-Json -Depth 100;$bad.initial_attempt_family.terminal_negative_history[12].mutation_count=1;$path=Join-Path $root 'bad-r12.json';[IO.File]::WriteAllText($path,($bad|ConvertTo-Json -Depth 100 -Compress),[Text.UTF8Encoding]::new($false));& $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $path -RemoteTagRows $remote -LibraryOnly}
  Confirm-P08R13Failure 'P08-R13-REMOTE-TAG' {& $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $fixture -RemoteTagRows @() -LibraryOnly}
  Confirm-P08R13Failure 'P08-R13-REMOTE-TAG' {& $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -FixturePolicyPath $fixture -RemoteTagRows @($remote + "$('0'*39)`trefs/tags/modules-v0.1.0-r13") -LibraryOnly}
}finally{if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}}
Write-Host 'Phase 8 r13 zero-write pre-live selector: PASS.'
