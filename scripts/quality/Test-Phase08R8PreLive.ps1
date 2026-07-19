[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$selector=Join-Path $PSScriptRoot 'Invoke-Phase08R8PreLive.ps1'
if(-not(Test-Path -LiteralPath $selector -PathType Leaf)){throw 'P08-R8-PRELIVE-MISSING: selector is required.'}
. $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -LibraryOnly
foreach($command in @('Assert-Phase08R8PreLive','Resolve-R8RemoteTag')){
  if(-not(Get-Command $command -CommandType Function -ErrorAction SilentlyContinue)){throw "P08-R8-PRELIVE-API: $command is missing."}
}
$source=Get-Content -LiteralPath $selector -Raw
if($source-cnotmatch'Invoke-R8PreLiveGit\s+@\(''ls-remote'',''--tags'',\$ExpectedRemote\)'-or$source-cmatch'refs/remotes/\$ExpectedRemote/tags'){throw 'P08-R8-REMOTE-TAG-SURFACE: selector must use one exact remote query.'}
foreach($forbidden in @('git push','git fetch','git tag ','git checkout','git reset','gh ','MOONCAKES_TOKEN','StateRoot','PublishOne -','Invoke-MooncakesLiveMutation')){
  if($source.IndexOf($forbidden,[StringComparison]::OrdinalIgnoreCase)-ge0){throw "P08-R8-STATIC-ZERO-WRITE: forbidden selector surface '$forbidden'."}
}
$productionHandoff=Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r8-handoff.json'
if(Test-Path -LiteralPath $productionHandoff){throw 'P08-R8-HANDOFF-PREEXISTING: production handoff must be absent.'}

function Confirm-R8Failure([string]$Id,[scriptblock]$Action){
  $failure=$null;try{&$Action|Out-Null}catch{$failure=$_.Exception.Message}
  if($null-eq$failure-or-not$failure.StartsWith("$Id`: ",[StringComparison]::Ordinal)){throw "P08-R8-NEGATIVE: expected $Id, got '$failure'."}
}
function Copy-R8Context([object]$Value){($Value|ConvertTo-Json -Depth 100 -Compress)|ConvertFrom-Json -Depth 100}

$root=Join-Path ([IO.Path]::GetTempPath()) ('mnf-r8-prelive-fixtures-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $root
try{
  $policy=Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\..\policy\release-control.json') -Raw|ConvertFrom-Json -Depth 100
  $remoteRows=[Collections.Generic.List[string]]::new();$histories=[Collections.Generic.List[object]]::new()
  $records=@($policy.initial_attempt_family.terminal_negative_history)
  for($i=0;$i-lt$records.Count;$i++){
    $record=$records[$i];$tagObject=if($null-ne$record.PSObject.Properties['tag_object_sha']){[string]$record.tag_object_sha}else{('{0:x40}'-f($i+1))}
    if($record.attempt-ceq'attempt_zero'){$remoteRows.Add("$($record.source_sha)`t$($record.release_ref)")}else{$remoteRows.Add("$tagObject`t$($record.release_ref)");$remoteRows.Add("$($record.source_sha)`t$($record.release_ref)^{}")}
    $attemptRoot=Join-Path $root ([string]$record.attempt);$null=New-Item -ItemType Directory -Force $attemptRoot
    $recordPath=Join-Path $attemptRoot 'record.json';$projection=[ordered]@{};foreach($p in $record.PSObject.Properties){if($p.Name-cne'record_sha256'){$projection[$p.Name]=$p.Value}}
    [IO.File]::WriteAllText($recordPath,(([pscustomobject]$projection)|ConvertTo-Json -Depth 100 -Compress),[Text.UTF8Encoding]::new($false))
    if($record.attempt-ceq'attempt_zero'){$execution=$null;$state=$null;$immutable=@([pscustomobject][ordered]@{path=[IO.Path]::GetFullPath($recordPath);sha256=[string]$record.record_sha256})}
    else{$execution=Join-Path $attemptRoot 'execution';$state=$attemptRoot;$null=New-Item -ItemType Directory -Force $execution;$immutable=@([pscustomobject][ordered]@{path=[IO.Path]::GetFullPath($recordPath);sha256=[string]$record.record_sha256})}
    $histories.Add([pscustomobject][ordered]@{attempt=[string]$record.attempt;release_ref=[string]$record.release_ref;source_sha=[string]$record.source_sha;tag_object_sha=if($record.attempt-ceq'attempt_zero'){$null}else{$tagObject};peel_sha=[string]$record.source_sha;record_sha256=[string]$record.record_sha256;record=$record;execution_root=if($null-eq$execution){$null}else{[IO.Path]::GetFullPath($execution)};state_root=if($null-eq$state){$null}else{[IO.Path]::GetFullPath($state)};immutable_files=$immutable})
  }
  foreach($record in $records){$null=Resolve-R8RemoteTag $record @($remoteRows)}
  $archives=[pscustomobject][ordered]@{
    core=[pscustomobject][ordered]@{module='mb-core';sha256='3342fee3e4876ef242b73bfd91e7e00178fd02a3d1959a387f43ac17fd77508a';size=125855;canonical=$true}
    color=[pscustomobject][ordered]@{module='mb-color';sha256='c763c189ff59b6541cb742bf6b78ddcc9800946ce3e3d1468f1ad4ee763d978c';size=89069;canonical=$true}
    image=[pscustomobject][ordered]@{module='mb-image';sha256='8150a1d0d75177ec9af4aa4c0f27fc25cab0c9a3ef5f9f27c0d9e0741e25e02e';size=248379;canonical=$true}
  }
  $summary=[pscustomobject][ordered]@{commit_sha=('a'*40);committed_at_head=$true;ancestor_of_head=$true}
  $context=[pscustomobject][ordered]@{schema_version='mnf-phase08-r8-pre-live-context/1';repository='tchivs/moonbit-foundation';remote='origin';head_sha=('b'*40);histories=@($histories);historical_history_set_sha256=[string]$policy.initial_attempt_family.history_set_sha256;canonical_archives=$archives;owned_paths_clean=$true;summaries=[pscustomobject][ordered]@{plan_08_19=$summary;plan_08_20=$summary;plan_08_21=$summary};r8_local_absent=$true;r8_remote_absent=$true;handoff_absent=$true;output_write_attempted=$false}
  $before=@(Get-ChildItem $root -Recurse -File|Sort-Object FullName|ForEach-Object{"$($_.FullName)|$((Get-FileHash $_.FullName -Algorithm SHA256).Hash)"})-join"`n"
  $result=Assert-Phase08R8PreLive $context
  $after=@(Get-ChildItem $root -Recurse -File|Sort-Object FullName|ForEach-Object{"$($_.FullName)|$((Get-FileHash $_.FullName -Algorithm SHA256).Hash)"})-join"`n"
  $expected='schema_version,repository,head_sha,historical_attempt_zero_sha256,historical_r1_sha256,historical_r2_sha256,historical_r3_sha256,historical_r4_sha256,historical_r5_sha256,historical_r6_sha256,historical_r7_sha256,historical_history_set_sha256,r7_terminal_disposition,r7_run_id,r7_run_attempt,r7_prepare_job_id,r7_downstream_effect_count,canonical_core_sha256,canonical_color_sha256,canonical_image_sha256,summary_08_19_commit,summary_08_20_commit,summary_08_21_commit,r8_local_absent,r8_remote_absent,handoff_absent,filesystem_writes,git_writes,network_calls'
  if($before-cne$after-or(@($result.PSObject.Properties.Name)-join',')-cne$expected){throw 'P08-R8-POSITIVE: result or zero-write boundary drifted.'}
  $bad=Copy-R8Context $context;$bad.histories[7].record.run_id='29673849109';$bad.histories[7].record_sha256=Get-R8PreLiveRecordDigest $bad.histories[7].record;Confirm-R8Failure 'P08-R8-R7-TERMINAL' {Assert-Phase08R8PreLive $bad}
  $bad=Copy-R8Context $context;$bad.histories[7].record.publisher_dry_run_count=1;$bad.histories[7].record_sha256=Get-R8PreLiveRecordDigest $bad.histories[7].record;Confirm-R8Failure 'P08-R8-DOWNSTREAM' {Assert-Phase08R8PreLive $bad}
  $bad=Copy-R8Context $context;$bad.canonical_archives.core.sha256=('9'*64);Confirm-R8Failure 'P08-R8-CANONICAL-ARCHIVE' {Assert-Phase08R8PreLive $bad}
  $bad=Copy-R8Context $context;$bad.summaries.plan_08_21.ancestor_of_head=$false;Confirm-R8Failure 'P08-R8-SUMMARY' {Assert-Phase08R8PreLive $bad}
  $bad=Copy-R8Context $context;$bad.owned_paths_clean=$false;Confirm-R8Failure 'P08-R8-DIRTY' {Assert-Phase08R8PreLive $bad}
  $bad=Copy-R8Context $context;$bad.r8_remote_absent=$false;Confirm-R8Failure 'P08-R8-TAG-PRESENT' {Assert-Phase08R8PreLive $bad}
  $bad=Copy-R8Context $context;$bad.handoff_absent=$false;Confirm-R8Failure 'P08-R8-HANDOFF-PRESENT' {Assert-Phase08R8PreLive $bad}
  $bad=Copy-R8Context $context;$bad.output_write_attempted=$true;Confirm-R8Failure 'P08-R8-ZERO-WRITE' {Assert-Phase08R8PreLive $bad}
}finally{if(Test-Path $root){Remove-Item $root -Recurse -Force}}
if(Test-Path $productionHandoff){throw 'P08-R8-HANDOFF-CREATED: fixture touched production handoff.'}
Write-Host 'Phase 8 r8 pre-live selector fixtures: PASS.'
