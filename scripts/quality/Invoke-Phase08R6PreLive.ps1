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

function Throw-R6PreLive([string]$Id,[string]$Message){throw "$Id`: $Message"}
function Get-R6PreLiveSha([string]$Path){
  if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){Throw-R6PreLive 'P08-R6-PATH' "Missing immutable file '$Path'."}
  (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Get-R6PreLiveRecordDigest([object]$Record){
  $projection=[ordered]@{}
  foreach($property in $Record.PSObject.Properties){if($property.Name -cne 'record_sha256'){$projection[$property.Name]=$property.Value}}
  Get-ReleaseTextSha256 -Text (([pscustomobject]$projection)|ConvertTo-Json -Depth 100 -Compress)
}
function Invoke-R6PreLiveGit([string[]]$Arguments,[switch]$AllowFailure){
  $output=@(& git @Arguments 2>&1|ForEach-Object{$_.ToString()});$code=$LASTEXITCODE
  if($code-ne0-and-not$AllowFailure){Throw-R6PreLive 'P08-R6-GIT' "git $($Arguments-join' ') failed."}
  [pscustomobject]@{exit_code=$code;lines=$output}
}
function Assert-R6Contained([string]$Path,[string]$Root){
  $full=[IO.Path]::GetFullPath($Path);$base=[IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
  if($full -cne $base -and -not $full.StartsWith($base+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)){Throw-R6PreLive 'P08-R6-PATH-ESCAPE' "'$full' escapes '$base'."}
  $full
}

function Assert-Phase08R6PreLive {
  param([Parameter(Mandatory)][object]$Context)
  $expectedContext=@('schema_version','repository','remote','head_sha','histories','historical_history_set_sha256','owned_paths_clean','summaries','r6_local_absent','r6_remote_absent','handoff_absent','output_write_attempted')
  if((@($Context.PSObject.Properties.Name)-join ',')-cne($expectedContext-join ',')){Throw-R6PreLive 'P08-R6-CLOSED' 'Pre-live context field inventory drifted.'}
  if($Context.schema_version -cne 'mnf-phase08-r6-pre-live-context/1' -or $Context.repository -cne 'tchivs/moonbit-foundation' -or $Context.remote -cne 'origin' -or $Context.head_sha -cnotmatch '^[0-9a-f]{40}$'){Throw-R6PreLive 'P08-R6-BINDING' 'Repository, remote, or HEAD binding drifted.'}
  $policy=Read-ReleaseJson (Join-Path $PSScriptRoot '..\..\policy\release-control.json')
  $expected=@($policy.initial_attempt_family.terminal_negative_history);$actual=@($Context.histories)
  if($expected.Count-ne 6-or$actual.Count-ne 6-or($actual.attempt-join',')-cne'attempt_zero,r1,r2,r3,r4,r5'){Throw-R6PreLive 'P08-R6-HISTORY' 'Exactly six ordered histories are required.'}
  $digests=[Collections.Generic.List[string]]::new()
  for($i=0;$i-lt 6;$i++){
    $item=$actual[$i];$record=$item.record;$policyRecord=$expected[$i]
    $itemNames=@('attempt','release_ref','source_sha','tag_object_sha','peel_sha','record_sha256','record','execution_root','state_root','boundary_locator_path','active_locator_path','index_path','store_root','immutable_files')
    if((@($item.PSObject.Properties.Name)-join',')-cne($itemNames-join',')){Throw-R6PreLive 'P08-R6-HISTORY-CLOSED' "History $i field inventory drifted."}
    if($item.attempt-cne$policyRecord.attempt-or$item.release_ref-cne$policyRecord.release_ref-or$item.source_sha-cne$policyRecord.source_sha-or$item.peel_sha-cne$policyRecord.source_sha-or$item.record_sha256-cne$policyRecord.record_sha256){Throw-R6PreLive 'P08-R6-HISTORY' "History '$($item.attempt)' binding drifted."}
    if((Get-R6PreLiveRecordDigest $record)-cne$item.record_sha256){Throw-R6PreLive 'P08-R6-HISTORY-DIGEST' "History '$($item.attempt)' record digest drifted."}
    if($item.attempt-ceq'r5' -and $item.tag_object_sha-cne'4a11582cf9aeae15802cf4f6d7394b013ece63ac'){Throw-R6PreLive 'P08-R6-TAG' 'r5 annotated tag object drifted.'}
    if($null-ne$item.tag_object_sha-and$item.tag_object_sha-cnotmatch'^[0-9a-f]{40}$'){Throw-R6PreLive 'P08-R6-TAG' "History '$($item.attempt)' tag object is invalid."}
    if($item.attempt-ceq'attempt_zero'){
      if($null-ne$item.execution_root-or$null-ne$item.state_root-or$null-ne$item.boundary_locator_path-or$null-ne$item.active_locator_path-or$null-ne$item.index_path-or$null-ne$item.store_root){Throw-R6PreLive 'P08-R6-HISTORICAL-ROOT' 'attempt_zero must not claim a Phase 8 local root, locator, index, or store.'}
      if($record.hosted_run_present-ne$true-or[string]$record.run_id-cne'29652468948'-or[int]$record.run_attempt-ne1-or$record.mutation_performed-ne$false-or$record.authority_acquired-ne$false-or$record.reason-cne'terminal_setup_failure'){Throw-R6PreLive 'P08-R6-HISTORY' 'attempt_zero terminal hosted evidence drifted.'}
      if(@($item.immutable_files).Count-ne1-or[string]$item.immutable_files[0].sha256-cne[string]$item.record_sha256){Throw-R6PreLive 'P08-R6-HISTORICAL-ARTIFACT' 'attempt_zero requires exactly one digest-bound terminal artifact.'}
    }else{
      foreach($directory in @($item.execution_root,$item.state_root,$item.store_root)){if([string]::IsNullOrWhiteSpace([string]$directory)-or-not(Test-Path -LiteralPath $directory -PathType Container)){Throw-R6PreLive 'P08-R6-PATH' "Missing immutable directory '$directory'."}}
      foreach($path in @($item.boundary_locator_path,$item.index_path)){if([string]::IsNullOrWhiteSpace([string]$path)){Throw-R6PreLive 'P08-R6-PATH' 'Persisted history path is missing.'};$null=Assert-R6Contained $path $item.state_root;if(-not(Test-Path -LiteralPath $path -PathType Leaf)){Throw-R6PreLive 'P08-R6-PATH' "Missing immutable path '$path'."}}
      if($null-ne$item.active_locator_path){$null=Assert-R6Contained $item.active_locator_path $item.state_root;if(-not(Test-Path -LiteralPath $item.active_locator_path -PathType Leaf)){Throw-R6PreLive 'P08-R6-PATH' 'Active locator is missing.'}}
    }
    foreach($file in @($item.immutable_files)){
      if((@($file.PSObject.Properties.Name)-join',')-cne'path,sha256'){Throw-R6PreLive 'P08-R6-PATH-CLOSED' 'Immutable file binding is not closed.'}
      if($item.attempt-cne'attempt_zero'){$null=Assert-R6Contained $file.path $item.state_root}
      if((Get-R6PreLiveSha $file.path)-cne$file.sha256){Throw-R6PreLive 'P08-R6-PATH-DIGEST' "Immutable file '$($file.path)' drifted."}
    }
    $digests.Add([string]$item.record_sha256)
  }
  $set=Get-ReleaseTextSha256 -Text ($digests-join"`n")
  if($set-cne$Context.historical_history_set_sha256-or$set-cne$policy.initial_attempt_family.history_set_sha256){Throw-R6PreLive 'P08-R6-HISTORY-SET' 'Canonical history-set digest drifted.'}
  $r5=$actual[5].record
  if($r5.source_sha-cne'df105f06205298f1f82ac2f2cdca214d69d42e15'-or$r5.tag_object_sha-cne'4a11582cf9aeae15802cf4f6d7394b013ece63ac'-or$r5.prepare_attempt_completed-ne$true-or$r5.registry_disposition-cne'confirmed_absent'-or$r5.hosted_preflight_dispatch_attempted-ne$true-or$r5.hosted_preflight_dispatched-ne$false-or$r5.hosted_run_present-ne$false-or$null-ne$r5.run_id-or$null-ne$r5.run_attempt-or$r5.failure_stage-cne'hosted_dispatch_validation_before_run_creation'-or$r5.validation_error-cne'duplicate_workflow_environment_key'){Throw-R6PreLive 'P08-R6-R5-TERMINAL' 'r5 terminal no-run facts drifted.'}
  foreach($count in @('publish_run_count','publisher_dry_run_count','authorization_packet_count','authorization_receipt_count','handoff_count','publish_one_count','mutation_count')){if([int]$r5.$count-ne0){Throw-R6PreLive 'P08-R6-DOWNSTREAM' "r5 downstream count '$count' is nonzero."}}
  if($Context.owned_paths_clean-ne$true){Throw-R6PreLive 'P08-R6-DIRTY' '08-15/16 owned paths are not committed-clean.'}
  $summaryNames=@('plan_08_15','plan_08_16')
  if((@($Context.summaries.PSObject.Properties.Name)-join',')-cne($summaryNames-join',')){Throw-R6PreLive 'P08-R6-SUMMARY' 'Summary commit bindings are not closed.'}
  foreach($name in $summaryNames){$summary=$Context.summaries.$name;if($summary.commit_sha-cnotmatch'^[0-9a-f]{40}$'-or$summary.committed_at_head-ne$true-or$summary.ancestor_of_head-ne$true){Throw-R6PreLive 'P08-R6-SUMMARY' "Summary '$name' is not committed at an ancestor of HEAD."}}
  if($Context.r6_local_absent-ne$true-or$Context.r6_remote_absent-ne$true){Throw-R6PreLive 'P08-R6-TAG-PRESENT' 'r6 tag already exists.'}
  if($Context.handoff_absent-ne$true){Throw-R6PreLive 'P08-R6-HANDOFF-PRESENT' 'Fixed r6 handoff already exists.'}
  if($Context.output_write_attempted-ne$false){Throw-R6PreLive 'P08-R6-ZERO-WRITE' 'Selector output attempted a filesystem write.'}
  [pscustomobject][ordered]@{
    schema_version='mnf-phase08-r6-pre-live-result/1';repository=$Context.repository;head_sha=$Context.head_sha
    historical_attempt_zero_sha256=$digests[0];historical_r1_sha256=$digests[1];historical_r2_sha256=$digests[2];historical_r3_sha256=$digests[3];historical_r4_sha256=$digests[4];historical_r5_sha256=$digests[5]
    historical_history_set_sha256=$set;r5_terminal_disposition='duplicate_env_rejected_before_run';r5_publish_run_count=0;r5_downstream_effect_count=0
    summary_08_15_commit=$Context.summaries.plan_08_15.commit_sha;summary_08_16_commit=$Context.summaries.plan_08_16.commit_sha
    r6_local_absent=$true;r6_remote_absent=$true;handoff_absent=$true;filesystem_writes=0;git_writes=0;network_calls=0
  }
}

function Get-Phase08OwnedPaths([string]$PlanPath){
  $lines=Get-Content -LiteralPath $PlanPath;$inside=$false;$paths=[Collections.Generic.List[string]]::new()
  foreach($line in $lines){
    if($line-ceq'files_modified:'){$inside=$true;continue}
    if($inside-and$line-cmatch'^\S') {break}
    if($inside-and$line-cmatch'^\s+-\s+(?<path>.+?)\s*$'){$paths.Add($Matches.path.Trim('"',''''))}
  }
  if($paths.Count-eq0){Throw-R6PreLive 'P08-R6-OWNED-PATHS' "No plan-owned paths found in '$PlanPath'."}
  @($paths)
}

function Find-R6HistoricalBoundary([object]$Record){
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
  if($candidates.Count-ne1){Throw-R6PreLive 'P08-R6-HISTORICAL-ROOT' "Expected one immutable state root for '$($Record.attempt)', got $($candidates.Count)."}
  $candidates[0]
}

function New-Phase08R6ProductionContext([string]$ExpectedRepository,[string]$ExpectedRemote){
  $repoRoot=(Invoke-R6PreLiveGit @('rev-parse','--show-toplevel')).lines[0];$head=(Invoke-R6PreLiveGit @('rev-parse','HEAD')).lines[0]
  $remoteUrl=Invoke-R6PreLiveGit @('config','--get',"remote.$ExpectedRemote.url")
  if($ExpectedRepository-cne'tchivs/moonbit-foundation'-or$ExpectedRemote-cne'origin'-or$remoteUrl.lines.Count-ne1){Throw-R6PreLive 'P08-R6-REMOTE' 'Canonical repository remote is missing.'}
  $policy=Read-ReleaseJson (Join-Path $repoRoot 'policy/release-control.json');$histories=[Collections.Generic.List[object]]::new()
  $foundByAttempt=@{}
  foreach($persistedRecord in @($policy.initial_attempt_family.terminal_negative_history|Where-Object{$_.attempt-cne'attempt_zero'})){$foundByAttempt[[string]$persistedRecord.attempt]=Find-R6HistoricalBoundary $persistedRecord}
  $r5Found=$foundByAttempt.r5;$r5IndexPath=[string]$r5Found.active.index_path;$r5StoreRoot=Split-Path -Parent $r5IndexPath
  $r5Index=Get-Content -LiteralPath $r5IndexPath -Raw|ConvertFrom-Json -Depth 100
  $attemptZeroRecord=@($policy.initial_attempt_family.terminal_negative_history)[0]
  $attemptZeroEntries=@($r5Index.records|Where-Object{$_.logical_key-ceq'prepare|historical|attempt-zero'-and$_.kind-ceq'HistoricalNegative'-and$_.path-ceq'historical/attempt-zero.json'-and$_.file_sha256-ceq$attemptZeroRecord.record_sha256-and$_.content_sha256-ceq$attemptZeroRecord.record_sha256})
  if($attemptZeroEntries.Count-ne1){Throw-R6PreLive 'P08-R6-HISTORICAL-ARTIFACT' "Expected one r5-indexed attempt_zero artifact, got $($attemptZeroEntries.Count)."}
  $attemptZeroArtifact=[IO.Path]::GetFullPath((Join-Path $r5StoreRoot ([string]$attemptZeroEntries[0].path)));$null=Assert-R6Contained $attemptZeroArtifact ([string]$r5Found.directory)
  if((Get-R6PreLiveSha $attemptZeroArtifact)-cne[string]$attemptZeroRecord.record_sha256){Throw-R6PreLive 'P08-R6-HISTORICAL-ARTIFACT' 'attempt_zero terminal artifact digest drifted.'}
  foreach($record in @($policy.initial_attempt_family.terminal_negative_history)){
    $object=(Invoke-R6PreLiveGit @('rev-parse',$record.release_ref)).lines[0]
    $peel=(Invoke-R6PreLiveGit @('rev-parse',"$($record.release_ref)^{}" )).lines[0]
    $type=(Invoke-R6PreLiveGit @('cat-file','-t',$object)).lines[0]
    $tagObject=if($type-ceq'tag'){$object}else{$null}
    if($record.attempt-ceq'r5'-and$tagObject-cne$record.tag_object_sha){Throw-R6PreLive 'P08-R6-TAG' 'r5 tag object drifted.'}
    if($record.attempt-ceq'attempt_zero'){
      $histories.Add([pscustomobject][ordered]@{attempt=[string]$record.attempt;release_ref=[string]$record.release_ref;source_sha=[string]$record.source_sha;tag_object_sha=$tagObject;peel_sha=$peel;record_sha256=[string]$record.record_sha256;record=$record;execution_root=$null;state_root=$null;boundary_locator_path=$null;active_locator_path=$null;index_path=$null;store_root=$null;immutable_files=@([pscustomobject][ordered]@{path=$attemptZeroArtifact;sha256=[string]$record.record_sha256})})
      continue
    }
    $found=$foundByAttempt[[string]$record.attempt];$boundary=$found.boundary
    if($boundary.repository-cne$ExpectedRepository-or$boundary.execution_root-cne[IO.Path]::GetFullPath([string]$boundary.execution_root)-or$boundary.state_root-cne[IO.Path]::GetFullPath([string]$found.directory)){Throw-R6PreLive 'P08-R6-HISTORICAL-BINDING' "Boundary '$($record.attempt)' drifted."}
    $indexPath=if($null-ne$found.active){[string]$found.active.index_path}else{[string]$boundary.index_path};$storeRoot=Split-Path -Parent $indexPath
    $immutable=[Collections.Generic.List[object]]::new()
    foreach($path in @($found.boundary_path,$found.active_path,$indexPath)|Where-Object{$null-ne$_}){$immutable.Add([pscustomobject][ordered]@{path=[IO.Path]::GetFullPath($path);sha256=Get-R6PreLiveSha $path})}
    $index=Get-Content -LiteralPath $indexPath -Raw|ConvertFrom-Json -Depth 100
    foreach($entry in @($index.records)){
      if($null-eq$entry.path-or$null-eq$entry.file_sha256){continue}
      $path=[IO.Path]::GetFullPath((Join-Path $storeRoot ([string]$entry.path)))
      if((Get-R6PreLiveSha $path)-cne[string]$entry.file_sha256){Throw-R6PreLive 'P08-R6-PATH-DIGEST' "Indexed path '$path' drifted."}
      $immutable.Add([pscustomobject][ordered]@{path=$path;sha256=[string]$entry.file_sha256})
    }
    $histories.Add([pscustomobject][ordered]@{attempt=[string]$record.attempt;release_ref=[string]$record.release_ref;source_sha=[string]$record.source_sha;tag_object_sha=$tagObject;peel_sha=$peel;record_sha256=[string]$record.record_sha256;record=$record;execution_root=[IO.Path]::GetFullPath([string]$boundary.execution_root);state_root=[IO.Path]::GetFullPath([string]$boundary.state_root);boundary_locator_path=[IO.Path]::GetFullPath($found.boundary_path);active_locator_path=if($null-eq$found.active_path){$null}else{[IO.Path]::GetFullPath($found.active_path)};index_path=[IO.Path]::GetFullPath($indexPath);store_root=[IO.Path]::GetFullPath($storeRoot);immutable_files=@($immutable)})
  }
  $phase=Join-Path $repoRoot '.planning/phases/08-ordered-mooncakes-publication-and-registry-consumers';$owned=@((Get-Phase08OwnedPaths (Join-Path $phase '08-15-PLAN.md'))+(Get-Phase08OwnedPaths (Join-Path $phase '08-16-PLAN.md'))|Select-Object -Unique)
  $clean=((Invoke-R6PreLiveGit (@('diff','--quiet','HEAD','--')+$owned) -AllowFailure).exit_code-eq0)-and((Invoke-R6PreLiveGit (@('diff','--cached','--quiet','--')+$owned) -AllowFailure).exit_code-eq0)
  $summaries=[ordered]@{}
  foreach($id in @('08-15','08-16')){$relative=".planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/$id-SUMMARY.md";$commit=((Invoke-R6PreLiveGit @('log','-1','--format=%H','--',$relative)).lines|Select-Object -First 1);$cat=Invoke-R6PreLiveGit @('cat-file','-e',"HEAD:$relative") -AllowFailure;$ancestor=Invoke-R6PreLiveGit @('merge-base','--is-ancestor',$commit,$head) -AllowFailure;$summaries["plan_$($id.Replace('-','_'))"]=[pscustomobject][ordered]@{commit_sha=$commit;committed_at_head=($cat.exit_code-eq0);ancestor_of_head=($ancestor.exit_code-eq0)}}
  $r6Ref='refs/tags/modules-v0.1.0-r6';$r6Local=(Invoke-R6PreLiveGit @('show-ref','--verify','--quiet',$r6Ref) -AllowFailure).exit_code-ne0
  $r6Remote=(Invoke-R6PreLiveGit @('show-ref','--verify','--quiet',"refs/remotes/$ExpectedRemote/tags/modules-v0.1.0-r6") -AllowFailure).exit_code-ne0
  $handoffPath=Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r6-handoff.json'
  [pscustomobject][ordered]@{
    schema_version='mnf-phase08-r6-pre-live-context/1';repository=$ExpectedRepository;remote=$ExpectedRemote;head_sha=$head;histories=@($histories)
    historical_history_set_sha256=[string]$policy.initial_attempt_family.history_set_sha256;owned_paths_clean=$clean;summaries=[pscustomobject]$summaries
    r6_local_absent=$r6Local;r6_remote_absent=$r6Remote;handoff_absent=(-not(Test-Path -LiteralPath $handoffPath));output_write_attempted=$false
  }
}

if($LibraryOnly){return}
if(-not$Check-or$Repository-cne'tchivs/moonbit-foundation'-or$Remote-cne'origin'){Throw-R6PreLive 'P08-R6-INVOCATION' 'Use -Check -Repository tchivs/moonbit-foundation -Remote origin.'}
$result=Assert-Phase08R6PreLive (New-Phase08R6ProductionContext $Repository $Remote)
$result|ConvertTo-Json -Depth 20 -Compress
