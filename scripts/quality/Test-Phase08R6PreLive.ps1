[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$selector=Join-Path $PSScriptRoot 'Invoke-Phase08R6PreLive.ps1'
if(-not(Test-Path -LiteralPath $selector -PathType Leaf)){throw 'P08-R6-PRELIVE-MISSING: selector is required.'}
. $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -LibraryOnly
if(-not(Get-Command Assert-Phase08R6PreLive -ErrorAction SilentlyContinue)){throw 'P08-R6-PRELIVE-API: validator function is missing.'}
$source=Get-Content -LiteralPath $selector -Raw
foreach($forbidden in @('git push','git fetch','git tag ','git checkout','git reset','gh ','MOONCAKES_TOKEN','StateRoot','PublishOne -','Invoke-MooncakesLiveMutation')){
  if($source.IndexOf($forbidden,[StringComparison]::OrdinalIgnoreCase)-ge0){throw "P08-R6-STATIC-ZERO-WRITE: forbidden selector surface '$forbidden'."}
}
$productionHandoff=Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r6-handoff.json'
if(Test-Path -LiteralPath $productionHandoff){throw 'P08-R6-HANDOFF-PREEXISTING: production handoff must be absent.'}

function Confirm-R6Failure([string]$Id,[scriptblock]$Action){
  $failure=$null;try{&$Action|Out-Null}catch{$failure=$_.Exception.Message}
  if($null-eq$failure-or-not$failure.StartsWith("$Id`: ",[StringComparison]::Ordinal)){throw "P08-R6-NEGATIVE: expected $Id, got '$failure'."}
}
function Copy-R6Context([object]$Value){($Value|ConvertTo-Json -Depth 100 -Compress)|ConvertFrom-Json -Depth 100}

$root=Join-Path ([IO.Path]::GetTempPath()) ('mnf-r6-prelive-fixtures-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $root
try{
  $policy=Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\..\policy\release-control.json') -Raw|ConvertFrom-Json -Depth 100
  $histories=[Collections.Generic.List[object]]::new()
  foreach($record in @($policy.initial_attempt_family.terminal_negative_history)){
    $attemptRoot=Join-Path $root ([string]$record.attempt);$execution=Join-Path $attemptRoot 'execution';$state=Join-Path $attemptRoot 'state';$store=Join-Path $state 'store'
    $null=New-Item -ItemType Directory -Force $execution,$store
    $boundary=Join-Path $state 'boundary-locator.json';$index=Join-Path $store 'index.json';$active=Join-Path $state 'phase-08-live-locator.json'
    [IO.File]::WriteAllText($boundary,'{"kind":"boundary"}',[Text.UTF8Encoding]::new($false));[IO.File]::WriteAllText($index,'{"kind":"index"}',[Text.UTF8Encoding]::new($false));[IO.File]::WriteAllText($active,'{"kind":"active"}',[Text.UTF8Encoding]::new($false))
    $histories.Add([pscustomobject][ordered]@{
      attempt=[string]$record.attempt;release_ref=[string]$record.release_ref;source_sha=[string]$record.source_sha
      tag_object_sha=if($record.attempt-ceq'r5'){'4a11582cf9aeae15802cf4f6d7394b013ece63ac'}else{$null};peel_sha=[string]$record.source_sha
      record_sha256=[string]$record.record_sha256;record=$record;execution_root=[IO.Path]::GetFullPath($execution);state_root=[IO.Path]::GetFullPath($state)
      boundary_locator_path=[IO.Path]::GetFullPath($boundary);active_locator_path=[IO.Path]::GetFullPath($active);index_path=[IO.Path]::GetFullPath($index);store_root=[IO.Path]::GetFullPath($store)
      immutable_files=@(
        [pscustomobject][ordered]@{path=[IO.Path]::GetFullPath($boundary);sha256=(Get-FileHash $boundary -Algorithm SHA256).Hash.ToLowerInvariant()},
        [pscustomobject][ordered]@{path=[IO.Path]::GetFullPath($active);sha256=(Get-FileHash $active -Algorithm SHA256).Hash.ToLowerInvariant()},
        [pscustomobject][ordered]@{path=[IO.Path]::GetFullPath($index);sha256=(Get-FileHash $index -Algorithm SHA256).Hash.ToLowerInvariant()}
      )
    })
  }
  $context=[pscustomobject][ordered]@{
    schema_version='mnf-phase08-r6-pre-live-context/1';repository='tchivs/moonbit-foundation';remote='origin';head_sha=('a'*40);histories=@($histories)
    historical_history_set_sha256=[string]$policy.initial_attempt_family.history_set_sha256;owned_paths_clean=$true
    summaries=[pscustomobject][ordered]@{plan_08_15=[pscustomobject][ordered]@{commit_sha=('b'*40);committed_at_head=$true;ancestor_of_head=$true};plan_08_16=[pscustomobject][ordered]@{commit_sha=('c'*40);committed_at_head=$true;ancestor_of_head=$true}}
    r6_local_absent=$true;r6_remote_absent=$true;handoff_absent=$true;output_write_attempted=$false
  }
  $before=@(Get-ChildItem -LiteralPath $root -Recurse -File|Sort-Object FullName|ForEach-Object{"$($_.FullName)|$((Get-FileHash $_.FullName -Algorithm SHA256).Hash)"})-join"`n"
  $result=Assert-Phase08R6PreLive $context
  $after=@(Get-ChildItem -LiteralPath $root -Recurse -File|Sort-Object FullName|ForEach-Object{"$($_.FullName)|$((Get-FileHash $_.FullName -Algorithm SHA256).Hash)"})-join"`n"
  if($before-cne$after-or(@($result.PSObject.Properties.Name)-join',')-cne'schema_version,repository,head_sha,historical_attempt_zero_sha256,historical_r1_sha256,historical_r2_sha256,historical_r3_sha256,historical_r4_sha256,historical_r5_sha256,historical_history_set_sha256,r5_terminal_disposition,r5_publish_run_count,r5_downstream_effect_count,summary_08_15_commit,summary_08_16_commit,r6_local_absent,r6_remote_absent,handoff_absent,filesystem_writes,git_writes,network_calls'){throw 'P08-R6-POSITIVE: output or zero-write boundary drifted.'}

  $bad=Copy-R6Context $context;$bad.histories[0].peel_sha=('9'*40);Confirm-R6Failure 'P08-R6-HISTORY' {Assert-Phase08R6PreLive $bad}
  $bad=Copy-R6Context $context;$bad.histories[5].tag_object_sha=('9'*40);Confirm-R6Failure 'P08-R6-TAG' {Assert-Phase08R6PreLive $bad}
  $bad=Copy-R6Context $context;$bad.histories[5].record.hosted_run_present=$true;Confirm-R6Failure 'P08-R6-HISTORY-DIGEST' {Assert-Phase08R6PreLive $bad}
  $bad=Copy-R6Context $context;$bad.histories[5].record.registry_disposition='unknown';$bad.histories[5].record_sha256=Get-R6PreLiveRecordDigest $bad.histories[5].record;Confirm-R6Failure 'P08-R6-HISTORY' {Assert-Phase08R6PreLive $bad}
  $bad=Copy-R6Context $context;$bad.histories[5].record.publish_run_count=1;$bad.histories[5].record_sha256=Get-R6PreLiveRecordDigest $bad.histories[5].record;Confirm-R6Failure 'P08-R6-HISTORY' {Assert-Phase08R6PreLive $bad}
  $bad=Copy-R6Context $context;$bad.histories[2].immutable_files[0].sha256=('9'*64);Confirm-R6Failure 'P08-R6-PATH-DIGEST' {Assert-Phase08R6PreLive $bad}
  $bad=Copy-R6Context $context;$bad.owned_paths_clean=$false;Confirm-R6Failure 'P08-R6-DIRTY' {Assert-Phase08R6PreLive $bad}
  $bad=Copy-R6Context $context;$bad.summaries.plan_08_16.ancestor_of_head=$false;Confirm-R6Failure 'P08-R6-SUMMARY' {Assert-Phase08R6PreLive $bad}
  $bad=Copy-R6Context $context;$bad.r6_local_absent=$false;Confirm-R6Failure 'P08-R6-TAG-PRESENT' {Assert-Phase08R6PreLive $bad}
  $bad=Copy-R6Context $context;$bad.handoff_absent=$false;Confirm-R6Failure 'P08-R6-HANDOFF-PRESENT' {Assert-Phase08R6PreLive $bad}
  $bad=Copy-R6Context $context;$bad.output_write_attempted=$true;Confirm-R6Failure 'P08-R6-ZERO-WRITE' {Assert-Phase08R6PreLive $bad}
}finally{if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}}

if(Test-Path -LiteralPath $productionHandoff){throw 'P08-R6-HANDOFF-CREATED: selector fixtures touched the production handoff.'}

Write-Host 'Phase 8 r6 pre-live selector fixtures: PASS.'
