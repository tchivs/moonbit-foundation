[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$selector=Join-Path $PSScriptRoot 'Invoke-Phase08R7PreLive.ps1'
if(-not(Test-Path -LiteralPath $selector -PathType Leaf)){throw 'P08-R7-PRELIVE-MISSING: selector is required.'}
. $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -LibraryOnly
if(-not(Get-Command Assert-Phase08R7PreLive -ErrorAction SilentlyContinue)){throw 'P08-R7-PRELIVE-API: validator function is missing.'}
if(-not(Get-Command Resolve-R7RemoteTag -ErrorAction SilentlyContinue)){throw 'P08-R7-REMOTE-TAG-API: remote tag resolver is missing.'}
$source=Get-Content -LiteralPath $selector -Raw
if($source-cnotmatch'Invoke-R7PreLiveGit\s+@\(''ls-remote'',''--tags'',\$ExpectedRemote\)'-or$source-cmatch'refs/remotes/\$ExpectedRemote/tags'){throw 'P08-R7-REMOTE-TAG-SURFACE: production must read exact remote tags without local remote-tracking refs.'}
foreach($forbidden in @('git push','git fetch','git tag ','git checkout','git reset','gh ','MOONCAKES_TOKEN','StateRoot','PublishOne -','Invoke-MooncakesLiveMutation')){
  if($source.IndexOf($forbidden,[StringComparison]::OrdinalIgnoreCase)-ge0){throw "P08-R7-STATIC-ZERO-WRITE: forbidden selector surface '$forbidden'."}
}
$productionHandoff=Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r7-handoff.json'
if(Test-Path -LiteralPath $productionHandoff){throw 'P08-R7-HANDOFF-PREEXISTING: production handoff must be absent.'}

function Confirm-R7Failure([string]$Id,[scriptblock]$Action){
  $failure=$null;try{&$Action|Out-Null}catch{$failure=$_.Exception.Message}
  if($null-eq$failure-or-not$failure.StartsWith("$Id`: ",[StringComparison]::Ordinal)){throw "P08-R7-NEGATIVE: expected $Id, got '$failure'."}
}
function Copy-R7Context([object]$Value){($Value|ConvertTo-Json -Depth 100 -Compress)|ConvertFrom-Json -Depth 100}

$root=Join-Path ([IO.Path]::GetTempPath()) ('mnf-r7-prelive-fixtures-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $root
try{
  $policy=Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\..\policy\release-control.json') -Raw|ConvertFrom-Json -Depth 100
  $remoteRows=[Collections.Generic.List[string]]::new()
  for($tagIndex=0;$tagIndex-lt 7;$tagIndex++){
    $tagRecord=@($policy.initial_attempt_family.terminal_negative_history)[$tagIndex]
    if($tagRecord.attempt-ceq'attempt_zero'){$remoteRows.Add("$($tagRecord.source_sha)`t$($tagRecord.release_ref)");continue}
    $tagObject=if($tagRecord.attempt-cin @('r5','r6')){[string]$tagRecord.tag_object_sha}else{('{0:x40}' -f ($tagIndex+1))}
    $remoteRows.Add("$tagObject`t$($tagRecord.release_ref)");$remoteRows.Add("$($tagRecord.source_sha)`t$($tagRecord.release_ref)^{}")
  }
  foreach($tagRecord in @($policy.initial_attempt_family.terminal_negative_history)){
    $resolved=Resolve-R7RemoteTag $tagRecord @($remoteRows)
    if($resolved.peel_sha-cne$tagRecord.source_sha-or($tagRecord.attempt-cin @('r5','r6')-and$resolved.tag_object_sha-cne$tagRecord.tag_object_sha)){throw 'P08-R7-REMOTE-TAG-POSITIVE: exact remote binding drifted.'}
  }
  $tagRecord=@($policy.initial_attempt_family.terminal_negative_history)[1]
  Confirm-R7Failure 'P08-R7-REMOTE-TAG' {Resolve-R7RemoteTag $tagRecord @($remoteRows|Where-Object{$_-notmatch([regex]::Escape($tagRecord.release_ref)+'(?:\^\{\})?$')})}
  Confirm-R7Failure 'P08-R7-REMOTE-TAG' {Resolve-R7RemoteTag $tagRecord @($remoteRows+@($remoteRows|Where-Object{$_-cmatch("`t$([regex]::Escape($tagRecord.release_ref))$")}))}
  $driftRows=@($remoteRows|ForEach-Object{if($_-cmatch("`t$([regex]::Escape($tagRecord.release_ref))\^\{\}$")){('9'*40)+"`t$($tagRecord.release_ref)^{}"}else{$_}})
  Confirm-R7Failure 'P08-R7-REMOTE-TAG' {Resolve-R7RemoteTag $tagRecord $driftRows}
  $r5Record=@($policy.initial_attempt_family.terminal_negative_history)[5]
  $objectDriftRows=@($remoteRows|ForEach-Object{if($_-cmatch("`t$([regex]::Escape($r5Record.release_ref))$")){('9'*40)+"`t$($r5Record.release_ref)"}else{$_}})
  Confirm-R7Failure 'P08-R7-REMOTE-TAG' {Resolve-R7RemoteTag $r5Record $objectDriftRows}
  $r6Record=@($policy.initial_attempt_family.terminal_negative_history)[6]
  $r6ObjectDriftRows=@($remoteRows|ForEach-Object{if($_-cmatch("`t$([regex]::Escape($r6Record.release_ref))$")){('8'*40)+"`t$($r6Record.release_ref)"}else{$_}})
  Confirm-R7Failure 'P08-R7-REMOTE-TAG' {Resolve-R7RemoteTag $r6Record $r6ObjectDriftRows}
  $histories=[Collections.Generic.List[object]]::new()
  foreach($record in @($policy.initial_attempt_family.terminal_negative_history)){
    $attemptRoot=Join-Path $root ([string]$record.attempt);$execution=Join-Path $attemptRoot 'execution';$state=Join-Path $attemptRoot 'state';$store=Join-Path $state 'store'
    $null=New-Item -ItemType Directory -Force $attemptRoot
    $historicalArtifact=Join-Path $attemptRoot 'historical.json'
    $historicalProjection=[ordered]@{};foreach($property in $record.PSObject.Properties){if($property.Name-cne'record_sha256'){$historicalProjection[$property.Name]=$property.Value}}
    [IO.File]::WriteAllText($historicalArtifact,(([pscustomobject]$historicalProjection)|ConvertTo-Json -Depth 100 -Compress),[Text.UTF8Encoding]::new($false))
    if($record.attempt-cne'attempt_zero'){$null=New-Item -ItemType Directory -Force $execution,$store}
    $boundary=Join-Path $state 'boundary-locator.json';$index=Join-Path $store 'index.json';$active=Join-Path $state 'phase-08-live-locator.json'
    if($record.attempt-cne'attempt_zero'){
      [IO.File]::WriteAllText($boundary,'{"kind":"boundary"}',[Text.UTF8Encoding]::new($false));[IO.File]::WriteAllText($index,'{"kind":"index"}',[Text.UTF8Encoding]::new($false));[IO.File]::WriteAllText($active,'{"kind":"active"}',[Text.UTF8Encoding]::new($false))
    }
    $histories.Add([pscustomobject][ordered]@{
      attempt=[string]$record.attempt;release_ref=[string]$record.release_ref;source_sha=[string]$record.source_sha
      tag_object_sha=if($record.attempt-cin @('r5','r6')){[string]$record.tag_object_sha}else{$null};peel_sha=[string]$record.source_sha
      record_sha256=[string]$record.record_sha256;record=$record
      execution_root=if($record.attempt-ceq'attempt_zero'){$null}else{[IO.Path]::GetFullPath($execution)};state_root=if($record.attempt-ceq'attempt_zero'){$null}else{[IO.Path]::GetFullPath($state)}
      boundary_locator_path=if($record.attempt-ceq'attempt_zero'){$null}else{[IO.Path]::GetFullPath($boundary)};active_locator_path=if($record.attempt-ceq'attempt_zero'){$null}else{[IO.Path]::GetFullPath($active)};index_path=if($record.attempt-ceq'attempt_zero'){$null}else{[IO.Path]::GetFullPath($index)};store_root=if($record.attempt-ceq'attempt_zero'){$null}else{[IO.Path]::GetFullPath($store)}
      immutable_files=if($record.attempt-ceq'attempt_zero'){@([pscustomobject][ordered]@{path=[IO.Path]::GetFullPath($historicalArtifact);sha256=(Get-FileHash $historicalArtifact -Algorithm SHA256).Hash.ToLowerInvariant()})}else{@(
        [pscustomobject][ordered]@{path=[IO.Path]::GetFullPath($boundary);sha256=(Get-FileHash $boundary -Algorithm SHA256).Hash.ToLowerInvariant()},
        [pscustomobject][ordered]@{path=[IO.Path]::GetFullPath($active);sha256=(Get-FileHash $active -Algorithm SHA256).Hash.ToLowerInvariant()},
        [pscustomobject][ordered]@{path=[IO.Path]::GetFullPath($index);sha256=(Get-FileHash $index -Algorithm SHA256).Hash.ToLowerInvariant()}
      )}
    })
  }
  $context=[pscustomobject][ordered]@{
    schema_version='mnf-phase08-r7-pre-live-context/1';repository='tchivs/moonbit-foundation';remote='origin';head_sha=('a'*40);histories=@($histories)
    historical_history_set_sha256=[string]$policy.initial_attempt_family.history_set_sha256;owned_paths_clean=$true
    summaries=[pscustomobject][ordered]@{plan_08_17=[pscustomobject][ordered]@{commit_sha=('b'*40);committed_at_head=$true;ancestor_of_head=$true};plan_08_18=[pscustomobject][ordered]@{commit_sha=('c'*40);committed_at_head=$true;ancestor_of_head=$true}}
    r7_local_absent=$true;r7_remote_absent=$true;handoff_absent=$true;output_write_attempted=$false
  }
  $before=@(Get-ChildItem -LiteralPath $root -Recurse -File|Sort-Object FullName|ForEach-Object{"$($_.FullName)|$((Get-FileHash $_.FullName -Algorithm SHA256).Hash)"})-join"`n"
  $result=Assert-Phase08R7PreLive $context
  $after=@(Get-ChildItem -LiteralPath $root -Recurse -File|Sort-Object FullName|ForEach-Object{"$($_.FullName)|$((Get-FileHash $_.FullName -Algorithm SHA256).Hash)"})-join"`n"
  if($before-cne$after-or(@($result.PSObject.Properties.Name)-join',')-cne'schema_version,repository,head_sha,historical_attempt_zero_sha256,historical_r1_sha256,historical_r2_sha256,historical_r3_sha256,historical_r4_sha256,historical_r5_sha256,historical_r6_sha256,historical_history_set_sha256,r6_terminal_disposition,r6_run_id,r6_run_attempt,r6_prepare_job_id,r6_downstream_effect_count,summary_08_17_commit,summary_08_18_commit,r7_local_absent,r7_remote_absent,handoff_absent,filesystem_writes,git_writes,network_calls'){throw 'P08-R7-POSITIVE: output or zero-write boundary drifted.'}

  $bad=Copy-R7Context $context;$bad.histories[0].peel_sha=('9'*40);Confirm-R7Failure 'P08-R7-HISTORY' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.histories[0].state_root=[IO.Path]::GetFullPath($root);Confirm-R7Failure 'P08-R7-HISTORICAL-ROOT' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.histories[0].immutable_files[0].sha256=('9'*64);Confirm-R7Failure 'P08-R7-HISTORICAL-ARTIFACT' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.histories[1].state_root=$null;Confirm-R7Failure 'P08-R7-PATH' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.histories[5].tag_object_sha=('9'*40);Confirm-R7Failure 'P08-R7-TAG' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.histories[5].record.hosted_run_present=$true;Confirm-R7Failure 'P08-R7-HISTORY-DIGEST' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.histories[5].record.registry_disposition='unknown';$bad.histories[5].record_sha256=Get-R7PreLiveRecordDigest $bad.histories[5].record;Confirm-R7Failure 'P08-R7-HISTORY' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.histories[5].record.publish_run_count=1;$bad.histories[5].record_sha256=Get-R7PreLiveRecordDigest $bad.histories[5].record;Confirm-R7Failure 'P08-R7-HISTORY' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.histories[6].tag_object_sha=('9'*40);Confirm-R7Failure 'P08-R7-TAG' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.histories[6].record.run_id='29671691605';$bad.histories[6].record_sha256=Get-R7PreLiveRecordDigest $bad.histories[6].record;Confirm-R7Failure 'P08-R7-HISTORY' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.histories[6].record.prepare_job_id='88151792309';$bad.histories[6].record_sha256=Get-R7PreLiveRecordDigest $bad.histories[6].record;Confirm-R7Failure 'P08-R7-HISTORY' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.histories[6].record.publisher_dry_run_count=1;$bad.histories[6].record_sha256=Get-R7PreLiveRecordDigest $bad.histories[6].record;Confirm-R7Failure 'P08-R7-HISTORY' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.histories[2].immutable_files[0].sha256=('9'*64);Confirm-R7Failure 'P08-R7-PATH-DIGEST' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.owned_paths_clean=$false;Confirm-R7Failure 'P08-R7-DIRTY' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.summaries.plan_08_18.ancestor_of_head=$false;Confirm-R7Failure 'P08-R7-SUMMARY' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.r7_local_absent=$false;Confirm-R7Failure 'P08-R7-TAG-PRESENT' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.handoff_absent=$false;Confirm-R7Failure 'P08-R7-HANDOFF-PRESENT' {Assert-Phase08R7PreLive $bad}
  $bad=Copy-R7Context $context;$bad.output_write_attempted=$true;Confirm-R7Failure 'P08-R7-ZERO-WRITE' {Assert-Phase08R7PreLive $bad}
}finally{if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}}

if(Test-Path -LiteralPath $productionHandoff){throw 'P08-R7-HANDOFF-CREATED: selector fixtures touched the production handoff.'}

Write-Host 'Phase 8 r7 pre-live selector fixtures: PASS.'
