[CmdletBinding()]
param(
  [switch]$Check,
  [string]$Repository,
  [string]$Remote,
  [switch]$LibraryOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')

function Throw-R7PreLive([string]$Id,[string]$Message){throw "$Id`: $Message"}
function Get-R7PreLiveSha([string]$Path){
  if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){Throw-R7PreLive 'P08-R7-PATH' "Missing immutable file '$Path'."}
  (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Get-R7PreLiveRecordDigest([object]$Record){
  $projection=[ordered]@{}
  foreach($property in $Record.PSObject.Properties){if($property.Name -cne 'record_sha256'){$projection[$property.Name]=$property.Value}}
  Get-ReleaseTextSha256 -Text (([pscustomobject]$projection)|ConvertTo-Json -Depth 100 -Compress)
}
function Invoke-R7PreLiveGit([string[]]$Arguments,[switch]$AllowFailure){
  $output=@(& git @Arguments 2>&1|ForEach-Object{$_.ToString()});$code=$LASTEXITCODE
  if($code-ne0-and-not$AllowFailure){Throw-R7PreLive 'P08-R7-GIT' "git $($Arguments-join' ') failed."}
  [pscustomobject]@{exit_code=$code;lines=$output}
}
function Resolve-R7RemoteTag([object]$Record,[string[]]$RemoteRows){
  $base=[Collections.Generic.List[string]]::new();$peeled=[Collections.Generic.List[string]]::new()
  foreach($row in @($RemoteRows)){
    if($row-cnotmatch'^(?<sha>[0-9a-f]{40})\t(?<ref>refs/tags/[^\s]+?)(?<peel>\^\{\})?$'){Throw-R7PreLive 'P08-R7-REMOTE-TAG' "Malformed remote tag row '$row'."}
    if($Matches.ref-cne[string]$Record.release_ref){continue}
    if(-not$Matches.ContainsKey('peel')-or[string]::IsNullOrEmpty([string]$Matches['peel'])){$base.Add($Matches.sha)}else{$peeled.Add($Matches.sha)}
  }
  if($base.Count-ne1-or$peeled.Count-gt1){Throw-R7PreLive 'P08-R7-REMOTE-TAG' "Remote tag '$($Record.release_ref)' must have one object row and at most one peeled row."}
  $tagObject=if($peeled.Count-eq1){$base[0]}else{$null};$peel=if($peeled.Count-eq1){$peeled[0]}else{$base[0]}
  if($peel-cne[string]$Record.source_sha){Throw-R7PreLive 'P08-R7-REMOTE-TAG' "Remote tag '$($Record.release_ref)' peeled source drifted."}
  $expectedTagObject=$Record.PSObject.Properties['tag_object_sha']
  if($null-ne$expectedTagObject-and$tagObject-cne[string]$expectedTagObject.Value){Throw-R7PreLive 'P08-R7-REMOTE-TAG' "Remote tag '$($Record.release_ref)' object drifted."}
  [pscustomobject][ordered]@{release_ref=[string]$Record.release_ref;tag_object_sha=$tagObject;peel_sha=$peel}
}
function Assert-R7Contained([string]$Path,[string]$Root){
  $full=[IO.Path]::GetFullPath($Path);$base=[IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
  if($full -cne $base -and -not $full.StartsWith($base+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)){Throw-R7PreLive 'P08-R7-PATH-ESCAPE' "'$full' escapes '$base'."}
  $full
}

function Assert-Phase08R7PreLive {
  param([Parameter(Mandatory)][object]$Context)
  $expectedContext=@('schema_version','repository','remote','head_sha','histories','historical_history_set_sha256','owned_paths_clean','summaries','r7_local_absent','r7_remote_absent','handoff_absent','output_write_attempted')
  if((@($Context.PSObject.Properties.Name)-join ',')-cne($expectedContext-join ',')){Throw-R7PreLive 'P08-R7-CLOSED' 'Pre-live context field inventory drifted.'}
  if($Context.schema_version -cne 'mnf-phase08-r7-pre-live-context/1' -or $Context.repository -cne 'tchivs/moonbit-foundation' -or $Context.remote -cne 'origin' -or $Context.head_sha -cnotmatch '^[0-9a-f]{40}$'){Throw-R7PreLive 'P08-R7-BINDING' 'Repository, remote, or HEAD binding drifted.'}
  $policy=Read-ReleaseJson (Join-Path $PSScriptRoot '..\..\policy\release-control.json')
  $expected=@($policy.initial_attempt_family.terminal_negative_history|Select-Object -First 7);$actual=@($Context.histories)
  if($expected.Count-ne 7-or$actual.Count-ne 7-or($actual.attempt-join',')-cne'attempt_zero,r1,r2,r3,r4,r5,r6'){Throw-R7PreLive 'P08-R7-HISTORY' 'Exactly seven ordered histories are required.'}
  $digests=[Collections.Generic.List[string]]::new()
  for($i=0;$i-lt 7;$i++){
    $item=$actual[$i];$record=$item.record;$policyRecord=$expected[$i]
    $itemNames=@('attempt','release_ref','source_sha','tag_object_sha','peel_sha','record_sha256','record','execution_root','state_root','boundary_locator_path','active_locator_path','index_path','store_root','immutable_files')
    if((@($item.PSObject.Properties.Name)-join',')-cne($itemNames-join',')){Throw-R7PreLive 'P08-R7-HISTORY-CLOSED' "History $i field inventory drifted."}
    if($item.attempt-cne$policyRecord.attempt-or$item.release_ref-cne$policyRecord.release_ref-or$item.source_sha-cne$policyRecord.source_sha-or$item.peel_sha-cne$policyRecord.source_sha-or$item.record_sha256-cne$policyRecord.record_sha256){Throw-R7PreLive 'P08-R7-HISTORY' "History '$($item.attempt)' binding drifted."}
    if((Get-R7PreLiveRecordDigest $record)-cne$item.record_sha256){Throw-R7PreLive 'P08-R7-HISTORY-DIGEST' "History '$($item.attempt)' record digest drifted."}
    if($item.attempt-ceq'r5' -and $item.tag_object_sha-cne'4a11582cf9aeae15802cf4f6d7394b013ece63ac'){Throw-R7PreLive 'P08-R7-TAG' 'r5 annotated tag object drifted.'}
    if($item.attempt-ceq'r6' -and $item.tag_object_sha-cne'cdff825cc870a50c0393d5347f21351011092149'){Throw-R7PreLive 'P08-R7-TAG' 'r6 annotated tag object drifted.'}
    if($null-ne$item.tag_object_sha-and$item.tag_object_sha-cnotmatch'^[0-9a-f]{40}$'){Throw-R7PreLive 'P08-R7-TAG' "History '$($item.attempt)' tag object is invalid."}
    if($item.attempt-ceq'attempt_zero'){
      if($null-ne$item.execution_root-or$null-ne$item.state_root-or$null-ne$item.boundary_locator_path-or$null-ne$item.active_locator_path-or$null-ne$item.index_path-or$null-ne$item.store_root){Throw-R7PreLive 'P08-R7-HISTORICAL-ROOT' 'attempt_zero must not claim a Phase 8 local root, locator, index, or store.'}
      if($record.hosted_run_present-ne$true-or[string]$record.run_id-cne'29652468948'-or[int]$record.run_attempt-ne1-or$record.mutation_performed-ne$false-or$record.authority_acquired-ne$false-or$record.reason-cne'terminal_setup_failure'){Throw-R7PreLive 'P08-R7-HISTORY' 'attempt_zero terminal hosted evidence drifted.'}
      if(@($item.immutable_files).Count-ne1-or[string]$item.immutable_files[0].sha256-cne[string]$item.record_sha256){Throw-R7PreLive 'P08-R7-HISTORICAL-ARTIFACT' 'attempt_zero requires exactly one digest-bound terminal artifact.'}
    }else{
      foreach($directory in @($item.execution_root,$item.state_root,$item.store_root)){if([string]::IsNullOrWhiteSpace([string]$directory)-or-not(Test-Path -LiteralPath $directory -PathType Container)){Throw-R7PreLive 'P08-R7-PATH' "Missing immutable directory '$directory'."}}
      foreach($path in @($item.boundary_locator_path,$item.index_path)){if([string]::IsNullOrWhiteSpace([string]$path)){Throw-R7PreLive 'P08-R7-PATH' 'Persisted history path is missing.'};$null=Assert-R7Contained $path $item.state_root;if(-not(Test-Path -LiteralPath $path -PathType Leaf)){Throw-R7PreLive 'P08-R7-PATH' "Missing immutable path '$path'."}}
      if($null-ne$item.active_locator_path){$null=Assert-R7Contained $item.active_locator_path $item.state_root;if(-not(Test-Path -LiteralPath $item.active_locator_path -PathType Leaf)){Throw-R7PreLive 'P08-R7-PATH' 'Active locator is missing.'}}
    }
    foreach($file in @($item.immutable_files)){
      if((@($file.PSObject.Properties.Name)-join',')-cne'path,sha256'){Throw-R7PreLive 'P08-R7-PATH-CLOSED' 'Immutable file binding is not closed.'}
      if($item.attempt-cne'attempt_zero'){$null=Assert-R7Contained $file.path $item.state_root}
      if((Get-R7PreLiveSha $file.path)-cne$file.sha256){Throw-R7PreLive 'P08-R7-PATH-DIGEST' "Immutable file '$($file.path)' drifted."}
    }
    $digests.Add([string]$item.record_sha256)
  }
  $set=Get-ReleaseTextSha256 -Text ($digests-join"`n")
  $expectedSet=Get-ReleaseTextSha256 -Text (@($expected.record_sha256)-join"`n")
  if($set-cne$Context.historical_history_set_sha256-or$set-cne$expectedSet){Throw-R7PreLive 'P08-R7-HISTORY-SET' 'Canonical history-set digest drifted.'}
  $r6=$actual[6].record
  if($r6.source_sha-cne'c05cacbc3cfc583205c612f4bf293a4e251ec079'-or$r6.tag_object_sha-cne'cdff825cc870a50c0393d5347f21351011092149'-or$r6.hosted_run_present-ne$true-or[string]$r6.run_id-cne'29671691604'-or[int]$r6.run_attempt-ne1-or[string]$r6.prepare_job_id-cne'88151792308'-or$r6.prepare_attempt_completed-ne$true-or$r6.hosted_preflight_dispatched-ne$true-or$r6.credential_accessed-ne$false-or$r6.failure_stage-cne'hosted_preflight_prepare_job'-or$r6.failure_code-cne'P08-PREPARED-INTENT-BINDING'-or$r6.failure_detail-cne'windows_linux_eol_dependent_zip_bytes'-or$r6.mutation_performed-ne$false-or$r6.authority_acquired-ne$false-or$r6.reason-cne'terminal_cross_platform_prepared_intent_binding_failure'){Throw-R7PreLive 'P08-R7-R6-TERMINAL' 'r6 exact hosted prepare failure drifted.'}
  foreach($count in @('prepared_artifact_upload_count','publisher_dry_run_count','exact_existing_authority_count','hosted_preflight_downstream_count','publisher_count','observation_count','cold_consumer_count','authorization_packet_count','authorization_receipt_count','handoff_count','publish_one_count','mutation_count','successor_count')){if([int]$r6.$count-ne0){Throw-R7PreLive 'P08-R7-DOWNSTREAM' "r6 downstream count '$count' is nonzero."}}
  if($Context.owned_paths_clean-ne$true){Throw-R7PreLive 'P08-R7-DIRTY' '08-17/18 owned paths are not committed-clean.'}
  $summaryNames=@('plan_08_17','plan_08_18')
  if((@($Context.summaries.PSObject.Properties.Name)-join',')-cne($summaryNames-join',')){Throw-R7PreLive 'P08-R7-SUMMARY' 'Summary commit bindings are not closed.'}
  foreach($name in $summaryNames){$summary=$Context.summaries.$name;if($summary.commit_sha-cnotmatch'^[0-9a-f]{40}$'-or$summary.committed_at_head-ne$true-or$summary.ancestor_of_head-ne$true){Throw-R7PreLive 'P08-R7-SUMMARY' "Summary '$name' is not committed at an ancestor of HEAD."}}
  if($Context.r7_local_absent-ne$true-or$Context.r7_remote_absent-ne$true){Throw-R7PreLive 'P08-R7-TAG-PRESENT' 'r7 tag already exists.'}
  if($Context.handoff_absent-ne$true){Throw-R7PreLive 'P08-R7-HANDOFF-PRESENT' 'Fixed r7 handoff already exists.'}
  if($Context.output_write_attempted-ne$false){Throw-R7PreLive 'P08-R7-ZERO-WRITE' 'Selector output attempted a filesystem write.'}
  [pscustomobject][ordered]@{
    schema_version='mnf-phase08-r7-pre-live-result/1';repository=$Context.repository;head_sha=$Context.head_sha
    historical_attempt_zero_sha256=$digests[0];historical_r1_sha256=$digests[1];historical_r2_sha256=$digests[2];historical_r3_sha256=$digests[3];historical_r4_sha256=$digests[4];historical_r5_sha256=$digests[5];historical_r6_sha256=$digests[6]
    historical_history_set_sha256=$set;r6_terminal_disposition='hosted_prepare_binding_failure';r6_run_id='29671691604';r6_run_attempt=1;r6_prepare_job_id='88151792308';r6_downstream_effect_count=0
    summary_08_17_commit=$Context.summaries.plan_08_17.commit_sha;summary_08_18_commit=$Context.summaries.plan_08_18.commit_sha
    r7_local_absent=$true;r7_remote_absent=$true;handoff_absent=$true;filesystem_writes=0;git_writes=0;network_calls=0
  }
}

function Get-Phase08OwnedPaths([string]$PlanPath){
  $lines=Get-Content -LiteralPath $PlanPath;$inside=$false;$paths=[Collections.Generic.List[string]]::new()
  foreach($line in $lines){
    if($line-ceq'files_modified:'){$inside=$true;continue}
    if($inside-and$line-cmatch'^\S') {break}
    if($inside-and$line-cmatch'^\s+-\s+(?<path>.+?)\s*$'){$paths.Add($Matches.path.Trim('"',''''))}
  }
  if($paths.Count-eq0){Throw-R7PreLive 'P08-R7-OWNED-PATHS' "No plan-owned paths found in '$PlanPath'."}
  @($paths)
}

function Find-R7HistoricalBoundary([object]$Record){
  $temp=[IO.Path]::GetTempPath();$candidates=[Collections.Generic.List[object]]::new()
  foreach($directory in @(Get-ChildItem -LiteralPath $temp -Directory -Filter 'mnf-phase08*' -ErrorAction SilentlyContinue)){
    $boundaryPath=Join-Path $directory.FullName 'boundary-locator.json'
    if(-not(Test-Path -LiteralPath $boundaryPath -PathType Leaf)){continue}
    try{$boundary=Get-Content -LiteralPath $boundaryPath -Raw|ConvertFrom-Json -Depth 100}catch{continue}
    if($boundary.boundary_sha-cne$Record.source_sha){continue}
    $activePath=Join-Path $directory.FullName 'phase-08-live-locator.json';$active=$null
    if(Test-Path -LiteralPath $activePath -PathType Leaf){try{$active=Get-Content -LiteralPath $activePath -Raw|ConvertFrom-Json -Depth 100}catch{continue}}
    if($null-eq$active-or$active.release_ref-cne$Record.release_ref){continue}
    $candidates.Add([pscustomobject]@{directory=$directory.FullName;boundary_path=$boundaryPath;boundary=$boundary;active_path=if($null-eq$active){$null}else{$activePath};active=$active})
  }
  if($candidates.Count-ne1){Throw-R7PreLive 'P08-R7-HISTORICAL-ROOT' "Expected one immutable state root for '$($Record.attempt)', got $($candidates.Count)."}
  $candidates[0]
}

function New-Phase08R7ProductionContext([string]$ExpectedRepository,[string]$ExpectedRemote,[AllowNull()][string[]]$RemoteTagRows=$null,[ValidateSet(7,8)][int]$HistoryCount=7){
  $repoRoot=(Invoke-R7PreLiveGit @('rev-parse','--show-toplevel')).lines[0];$head=(Invoke-R7PreLiveGit @('rev-parse','HEAD')).lines[0]
  $remoteUrl=Invoke-R7PreLiveGit @('config','--get',"remote.$ExpectedRemote.url")
  if($ExpectedRepository-cne'tchivs/moonbit-foundation'-or$ExpectedRemote-cne'origin'-or$remoteUrl.lines.Count-ne1){Throw-R7PreLive 'P08-R7-REMOTE' 'Canonical repository remote is missing.'}
  if($null-eq$RemoteTagRows){$RemoteTagRows=@((Invoke-R7PreLiveGit @('ls-remote','--tags',$ExpectedRemote)).lines)}
  $policy=Read-ReleaseJson (Join-Path $repoRoot 'policy/release-control.json');$records=@($policy.initial_attempt_family.terminal_negative_history|Select-Object -First $HistoryCount);$historySet=Get-ReleaseTextSha256 -Text (@($records.record_sha256)-join"`n");$histories=[Collections.Generic.List[object]]::new()
  $foundByAttempt=@{}
  foreach($persistedRecord in @($records|Where-Object{$_.attempt-cne'attempt_zero'})){$foundByAttempt[[string]$persistedRecord.attempt]=Find-R7HistoricalBoundary $persistedRecord}
  $r5Found=$foundByAttempt.r5;$r5IndexPath=[string]$r5Found.active.index_path;$r5StoreRoot=Split-Path -Parent $r5IndexPath
  $r5Index=Get-Content -LiteralPath $r5IndexPath -Raw|ConvertFrom-Json -Depth 100
  $attemptZeroRecord=$records[0]
  $attemptZeroEntries=@($r5Index.records|Where-Object{$_.logical_key-ceq'prepare|historical|attempt-zero'-and$_.kind-ceq'HistoricalNegative'-and$_.path-ceq'historical/attempt-zero.json'-and$_.file_sha256-ceq$attemptZeroRecord.record_sha256-and$_.content_sha256-ceq$attemptZeroRecord.record_sha256})
  if($attemptZeroEntries.Count-ne1){Throw-R7PreLive 'P08-R7-HISTORICAL-ARTIFACT' "Expected one r5-indexed attempt_zero artifact, got $($attemptZeroEntries.Count)."}
  $attemptZeroArtifact=[IO.Path]::GetFullPath((Join-Path $r5StoreRoot ([string]$attemptZeroEntries[0].path)));$null=Assert-R7Contained $attemptZeroArtifact ([string]$r5Found.directory)
  if((Get-R7PreLiveSha $attemptZeroArtifact)-cne[string]$attemptZeroRecord.record_sha256){Throw-R7PreLive 'P08-R7-HISTORICAL-ARTIFACT' 'attempt_zero terminal artifact digest drifted.'}
  foreach($record in $records){
    $remoteTag=Resolve-R7RemoteTag $record $RemoteTagRows;$peel=[string]$remoteTag.peel_sha;$tagObject=$remoteTag.tag_object_sha
    if($record.attempt-cin @('r5','r6')-and$tagObject-cne$record.tag_object_sha){Throw-R7PreLive 'P08-R7-TAG' "$($record.attempt) tag object drifted."}
    if($record.attempt-ceq'attempt_zero'){
      $histories.Add([pscustomobject][ordered]@{attempt=[string]$record.attempt;release_ref=[string]$record.release_ref;source_sha=[string]$record.source_sha;tag_object_sha=$tagObject;peel_sha=$peel;record_sha256=[string]$record.record_sha256;record=$record;execution_root=$null;state_root=$null;boundary_locator_path=$null;active_locator_path=$null;index_path=$null;store_root=$null;immutable_files=@([pscustomobject][ordered]@{path=$attemptZeroArtifact;sha256=[string]$record.record_sha256})})
      continue
    }
    $found=$foundByAttempt[[string]$record.attempt];$boundary=$found.boundary
    if($boundary.repository-cne$ExpectedRepository-or$boundary.execution_root-cne[IO.Path]::GetFullPath([string]$boundary.execution_root)-or$boundary.state_root-cne[IO.Path]::GetFullPath([string]$found.directory)){Throw-R7PreLive 'P08-R7-HISTORICAL-BINDING' "Boundary '$($record.attempt)' drifted."}
    $indexPath=if($null-ne$found.active){[string]$found.active.index_path}else{[string]$boundary.index_path};$storeRoot=Split-Path -Parent $indexPath
    $immutable=[Collections.Generic.List[object]]::new()
    foreach($path in @($found.boundary_path,$found.active_path,$indexPath)|Where-Object{$null-ne$_}){$immutable.Add([pscustomobject][ordered]@{path=[IO.Path]::GetFullPath($path);sha256=Get-R7PreLiveSha $path})}
    $index=Get-Content -LiteralPath $indexPath -Raw|ConvertFrom-Json -Depth 100
    foreach($entry in @($index.records)){
      if($null-eq$entry.path-or$null-eq$entry.file_sha256){continue}
      $path=[IO.Path]::GetFullPath((Join-Path $storeRoot ([string]$entry.path)))
      if((Get-R7PreLiveSha $path)-cne[string]$entry.file_sha256){Throw-R7PreLive 'P08-R7-PATH-DIGEST' "Indexed path '$path' drifted."}
      $immutable.Add([pscustomobject][ordered]@{path=$path;sha256=[string]$entry.file_sha256})
    }
    $histories.Add([pscustomobject][ordered]@{attempt=[string]$record.attempt;release_ref=[string]$record.release_ref;source_sha=[string]$record.source_sha;tag_object_sha=$tagObject;peel_sha=$peel;record_sha256=[string]$record.record_sha256;record=$record;execution_root=[IO.Path]::GetFullPath([string]$boundary.execution_root);state_root=[IO.Path]::GetFullPath([string]$boundary.state_root);boundary_locator_path=[IO.Path]::GetFullPath($found.boundary_path);active_locator_path=if($null-eq$found.active_path){$null}else{[IO.Path]::GetFullPath($found.active_path)};index_path=[IO.Path]::GetFullPath($indexPath);store_root=[IO.Path]::GetFullPath($storeRoot);immutable_files=@($immutable)})
  }
  $phase=Join-Path $repoRoot '.planning/phases/08-ordered-mooncakes-publication-and-registry-consumers';$owned=@((Get-Phase08OwnedPaths (Join-Path $phase '08-17-PLAN.md'))+(Get-Phase08OwnedPaths (Join-Path $phase '08-18-PLAN.md'))|Select-Object -Unique)
  $clean=((Invoke-R7PreLiveGit (@('diff','--quiet','HEAD','--')+$owned) -AllowFailure).exit_code-eq0)-and((Invoke-R7PreLiveGit (@('diff','--cached','--quiet','--')+$owned) -AllowFailure).exit_code-eq0)
  $summaries=[ordered]@{}
  foreach($id in @('08-17','08-18')){$relative=".planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/$id-SUMMARY.md";$commit=((Invoke-R7PreLiveGit @('log','-1','--format=%H','--',$relative)).lines|Select-Object -First 1);$cat=Invoke-R7PreLiveGit @('cat-file','-e',"HEAD:$relative") -AllowFailure;$ancestor=Invoke-R7PreLiveGit @('merge-base','--is-ancestor',$commit,$head) -AllowFailure;$summaries["plan_$($id.Replace('-','_'))"]=[pscustomobject][ordered]@{commit_sha=$commit;committed_at_head=($cat.exit_code-eq0);ancestor_of_head=($ancestor.exit_code-eq0)}}
  $r7Ref='refs/tags/modules-v0.1.0-r7';$r7Local=(Invoke-R7PreLiveGit @('show-ref','--verify','--quiet',$r7Ref) -AllowFailure).exit_code-ne0
  $r7Remote=@($RemoteTagRows|Where-Object{$_-cmatch'\trefs/tags/modules-v0\.1\.0-r7(?:\^\{\})?$'}).Count-eq0
  $handoffPath=Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r7-handoff.json'
  [pscustomobject][ordered]@{
    schema_version='mnf-phase08-r7-pre-live-context/1';repository=$ExpectedRepository;remote=$ExpectedRemote;head_sha=$head;histories=@($histories)
    historical_history_set_sha256=$historySet;owned_paths_clean=$clean;summaries=[pscustomobject]$summaries
    r7_local_absent=$r7Local;r7_remote_absent=$r7Remote;handoff_absent=(-not(Test-Path -LiteralPath $handoffPath));output_write_attempted=$false
  }
}

if($LibraryOnly){return}
if(-not$Check-or$Repository-cne'tchivs/moonbit-foundation'-or$Remote-cne'origin'){Throw-R7PreLive 'P08-R7-INVOCATION' 'Use -Check -Repository tchivs/moonbit-foundation -Remote origin.'}
$result=Assert-Phase08R7PreLive (New-Phase08R7ProductionContext $Repository $Remote)
$result|ConvertTo-Json -Depth 20 -Compress
