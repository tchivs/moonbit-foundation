[CmdletBinding()]
param([switch]$Check,[string]$Repository,[string]$Remote,[switch]$LibraryOnly)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')
Import-Module (Join-Path $PSScriptRoot 'Invoke-Phase08R7PreLive.Library.psm1') -Force

function Throw-R8PreLive([string]$Id,[string]$Message){throw "$Id`: $Message"}
function Get-R8PreLiveSha([string]$Path){if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){Throw-R8PreLive 'P08-R8-PATH' "Missing '$Path'."};(Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()}
function Get-R8PreLiveRecordDigest([object]$Record){$p=[ordered]@{};foreach($x in $Record.PSObject.Properties){if($x.Name-cne'record_sha256'){$p[$x.Name]=$x.Value}};Get-ReleaseTextSha256 -Text (([pscustomobject]$p)|ConvertTo-Json -Depth 100 -Compress)}
function Get-R8PreLiveResultDigest([object]$Result){$p=[ordered]@{};foreach($x in $Result.PSObject.Properties){if($x.Name-cne'result_sha256'){$p[$x.Name]=$x.Value}};Get-ReleaseTextSha256 -Text (([pscustomobject]$p)|ConvertTo-Json -Depth 100 -Compress)}
function Invoke-R8PreLiveGit([string[]]$Arguments,[switch]$AllowFailure){$lines=@(& git @Arguments 2>&1|ForEach-Object{$_.ToString()});$code=$LASTEXITCODE;if($code-ne0-and-not$AllowFailure){Throw-R8PreLive 'P08-R8-GIT' "git $($Arguments-join' ') failed."};[pscustomobject]@{exit_code=$code;lines=$lines}}
function Resolve-R8RemoteTag([object]$Record,[string[]]$RemoteRows){
  $base=[Collections.Generic.List[string]]::new();$peeled=[Collections.Generic.List[string]]::new()
  foreach($row in @($RemoteRows)){
    if($row-cnotmatch'^(?<sha>[0-9a-f]{40})\t(?<ref>refs/tags/[^\s]+?)(?<peel>\^\{\})?$'){Throw-R8PreLive 'P08-R8-REMOTE-TAG' "Malformed row '$row'."}
    if($Matches.ref-cne[string]$Record.release_ref){continue}
    if(-not$Matches.ContainsKey('peel')-or[string]::IsNullOrEmpty([string]$Matches['peel'])){$base.Add($Matches.sha)}else{$peeled.Add($Matches.sha)}
  }
  if($base.Count-ne1-or$peeled.Count-gt1){Throw-R8PreLive 'P08-R8-REMOTE-TAG' "Remote tag '$($Record.release_ref)' is ambiguous."}
  $object=if($peeled.Count-eq1){$base[0]}else{$null};$peel=if($peeled.Count-eq1){$peeled[0]}else{$base[0]}
  if($peel-cne[string]$Record.source_sha){Throw-R8PreLive 'P08-R8-REMOTE-TAG' 'Remote peel drifted.'}
  $expected=$Record.PSObject.Properties['tag_object_sha'];if($null-ne$expected-and$object-cne[string]$expected.Value){Throw-R8PreLive 'P08-R8-REMOTE-TAG' 'Remote tag object drifted.'}
  [pscustomobject][ordered]@{release_ref=[string]$Record.release_ref;tag_object_sha=$object;peel_sha=$peel}
}
function Assert-R8Contained([string]$Path,[string]$Root){$full=[IO.Path]::GetFullPath($Path);$base=[IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar);if(-not$full.StartsWith($base+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)){Throw-R8PreLive 'P08-R8-PATH-ESCAPE' "'$full' escapes '$base'."};$full}

function Assert-Phase08R8PreLive([Parameter(Mandatory)][object]$Context){
  $names=@('schema_version','repository','remote','head_sha','histories','historical_history_set_sha256','canonical_archives','owned_paths_clean','summaries','r8_local_absent','r8_remote_absent','handoff_absent','output_write_attempted')
  if((@($Context.PSObject.Properties.Name)-join',')-cne($names-join',')){Throw-R8PreLive 'P08-R8-CLOSED' 'Context field inventory drifted.'}
  if($Context.schema_version-cne'mnf-phase08-r8-pre-live-context/1'-or$Context.repository-cne'tchivs/moonbit-foundation'-or$Context.remote-cne'origin'-or$Context.head_sha-cnotmatch'^[0-9a-f]{40}$'){Throw-R8PreLive 'P08-R8-BINDING' 'Repository binding drifted.'}
  $policy=Read-ReleaseJson (Join-Path $PSScriptRoot '..\..\policy\release-control.json');$expected=@($policy.initial_attempt_family.terminal_negative_history);$actual=@($Context.histories)
  if($expected.Count-ne8-or$actual.Count-ne8-or($actual.attempt-join',')-cne'attempt_zero,r1,r2,r3,r4,r5,r6,r7'){Throw-R8PreLive 'P08-R8-HISTORY' 'Exactly eight ordered histories are required.'}
  $digests=[Collections.Generic.List[string]]::new()
  for($i=0;$i-lt8;$i++){
    $item=$actual[$i];$record=$item.record;$policyRecord=$expected[$i];$itemNames=@('attempt','release_ref','source_sha','tag_object_sha','peel_sha','record_sha256','record','execution_root','state_root','immutable_files')
    if((@($item.PSObject.Properties.Name)-join',')-cne($itemNames-join',')){Throw-R8PreLive 'P08-R8-HISTORY-CLOSED' "History $i is open."}
    if($item.attempt-cne$policyRecord.attempt-or$item.release_ref-cne$policyRecord.release_ref-or$item.source_sha-cne$policyRecord.source_sha-or$item.peel_sha-cne$policyRecord.source_sha-or($i-ne7-and$item.record_sha256-cne$policyRecord.record_sha256)){Throw-R8PreLive 'P08-R8-HISTORY' "History $i binding drifted."}
    if((Get-R8PreLiveRecordDigest $record)-cne$item.record_sha256){Throw-R8PreLive 'P08-R8-HISTORY-DIGEST' "History $i digest drifted."}
    if($null-ne$policyRecord.PSObject.Properties['tag_object_sha']-and$item.tag_object_sha-cne[string]$policyRecord.tag_object_sha){Throw-R8PreLive 'P08-R8-TAG' "History $i tag object drifted."}
    if($item.attempt-ceq'attempt_zero'){if($null-ne$item.execution_root-or$null-ne$item.state_root){Throw-R8PreLive 'P08-R8-HISTORICAL-ROOT' 'attempt_zero must be rootless.'}}
    else{foreach($dir in @($item.execution_root,$item.state_root)){if([string]::IsNullOrWhiteSpace([string]$dir)-or-not(Test-Path -LiteralPath $dir -PathType Container)){Throw-R8PreLive 'P08-R8-PATH' "Missing immutable directory '$dir'."}}}
    foreach($file in @($item.immutable_files)){if((@($file.PSObject.Properties.Name)-join',')-cne'path,sha256'){Throw-R8PreLive 'P08-R8-PATH-CLOSED' 'Immutable path binding is open.'};if($item.attempt-cne'attempt_zero'){$null=Assert-R8Contained $file.path $item.state_root};if((Get-R8PreLiveSha $file.path)-cne$file.sha256){Throw-R8PreLive 'P08-R8-PATH-DIGEST' "Immutable path '$($file.path)' drifted."}}
    $digests.Add([string]$item.record_sha256)
  }
  $set=Get-ReleaseTextSha256 -Text ($digests-join"`n")
  $r7=$actual[7].record
  if($r7.source_sha-cne'195e08dc1f3a1dc561d98cc660af679926ae0198'-or$r7.tag_object_sha-cne'52a47cda33492fa490178ab195ecdca50b1cf382'-or[string]$r7.run_id-cne'29673849108'-or[int]$r7.run_attempt-ne1-or[string]$r7.prepare_job_id-cne'88157456895'-or$r7.failure_code-cne'P08-PREPARED-INTENT-BINDING'-or$r7.failure_detail-cne'windows_linux_raw_moon_zip_container_bytes_despite_lf_entry_payloads'-or$r7.reason-cne'terminal_cross_platform_raw_moon_zip_container_intent_binding_failure'-or$r7.credential_accessed-ne$false-or$r7.mutation_performed-ne$false-or$r7.authority_acquired-ne$false){Throw-R8PreLive 'P08-R8-R7-TERMINAL' 'Exact r7 terminal failure drifted.'}
  foreach($count in @('prepared_artifact_upload_count','publisher_dry_run_count','exact_existing_authority_count','hosted_preflight_downstream_count','publisher_count','observation_count','cold_consumer_count','authorization_packet_count','authorization_receipt_count','handoff_count','publish_one_count','mutation_count','successor_count')){if([int]$r7.$count-ne0){Throw-R8PreLive 'P08-R8-DOWNSTREAM' "r7 downstream '$count' is nonzero."}}
  if($actual[7].record_sha256-cne$expected[7].record_sha256){Throw-R8PreLive 'P08-R8-R7-TERMINAL' 'Exact r7 terminal record digest drifted.'}
  if($set-cne$Context.historical_history_set_sha256-or$set-cne$policy.initial_attempt_family.history_set_sha256){Throw-R8PreLive 'P08-R8-HISTORY-SET' 'History set drifted.'}
  $archiveNames=@('core','color','image');$archiveExpected=@(@('mb-core','3342fee3e4876ef242b73bfd91e7e00178fd02a3d1959a387f43ac17fd77508a',125855),@('mb-color','c763c189ff59b6541cb742bf6b78ddcc9800946ce3e3d1468f1ad4ee763d978c',89069),@('mb-image','8150a1d0d75177ec9af4aa4c0f27fc25cab0c9a3ef5f9f27c0d9e0741e25e02e',248379))
  if((@($Context.canonical_archives.PSObject.Properties.Name)-join',')-cne($archiveNames-join',')){Throw-R8PreLive 'P08-R8-CANONICAL-ARCHIVE' 'Archive set drifted.'}
  for($i=0;$i-lt3;$i++){$a=$Context.canonical_archives.($archiveNames[$i]);if((@($a.PSObject.Properties.Name)-join',')-cne'module,sha256,size,canonical'-or$a.module-cne$archiveExpected[$i][0]-or$a.sha256-cne$archiveExpected[$i][1]-or[int]$a.size-ne[int]$archiveExpected[$i][2]-or$a.canonical-ne$true){Throw-R8PreLive 'P08-R8-CANONICAL-ARCHIVE' "Canonical $($archiveNames[$i]) archive drifted."}}
  if($Context.owned_paths_clean-ne$true){Throw-R8PreLive 'P08-R8-DIRTY' '08-19..21 paths are not committed-clean.'}
  $summaryNames=@('plan_08_19','plan_08_20','plan_08_21');if((@($Context.summaries.PSObject.Properties.Name)-join',')-cne($summaryNames-join',')){Throw-R8PreLive 'P08-R8-SUMMARY' 'Summary set drifted.'}
  foreach($name in $summaryNames){$s=$Context.summaries.$name;if($s.commit_sha-cnotmatch'^[0-9a-f]{40}$'-or$s.committed_at_head-ne$true-or$s.ancestor_of_head-ne$true){Throw-R8PreLive 'P08-R8-SUMMARY' "Summary '$name' is not committed ancestry."}}
  if($Context.r8_local_absent-ne$true-or$Context.r8_remote_absent-ne$true){Throw-R8PreLive 'P08-R8-TAG-PRESENT' 'r8 tag exists.'};if($Context.handoff_absent-ne$true){Throw-R8PreLive 'P08-R8-HANDOFF-PRESENT' 'Fixed r8 handoff exists.'};if($Context.output_write_attempted-ne$false){Throw-R8PreLive 'P08-R8-ZERO-WRITE' 'Output write attempted.'}
  $result=[pscustomobject][ordered]@{schema_version='mnf-phase08-r8-pre-live-result/1';repository=$Context.repository;head_sha=$Context.head_sha;historical_attempt_zero_sha256=$digests[0];historical_r1_sha256=$digests[1];historical_r2_sha256=$digests[2];historical_r3_sha256=$digests[3];historical_r4_sha256=$digests[4];historical_r5_sha256=$digests[5];historical_r6_sha256=$digests[6];historical_r7_sha256=$digests[7];historical_history_set_sha256=$set;r7_terminal_disposition='hosted_prepare_binding_failure';r7_run_id='29673849108';r7_run_attempt=1;r7_prepare_job_id='88157456895';r7_downstream_effect_count=0;canonical_core_sha256=$archiveExpected[0][1];canonical_color_sha256=$archiveExpected[1][1];canonical_image_sha256=$archiveExpected[2][1];summary_08_19_commit=$Context.summaries.plan_08_19.commit_sha;summary_08_20_commit=$Context.summaries.plan_08_20.commit_sha;summary_08_21_commit=$Context.summaries.plan_08_21.commit_sha;r8_local_absent=$true;r8_remote_absent=$true;handoff_absent=$true;filesystem_writes=0;git_writes=0;network_calls=0}
  $result|Add-Member -NotePropertyName result_sha256 -NotePropertyValue (Get-R8PreLiveResultDigest $result)
  $result
}

function Get-R8OwnedPaths([string]$PlanPath){$inside=$false;$paths=[Collections.Generic.List[string]]::new();foreach($line in Get-Content -LiteralPath $PlanPath){if($line-ceq'files_modified:'){$inside=$true;continue};if($inside-and$line-cmatch'^\S'){break};if($inside-and$line-cmatch'^\s+-\s+(?<p>.+?)\s*$'){$paths.Add($Matches.p.Trim('"',''''))}};if($paths.Count-eq0){Throw-R8PreLive 'P08-R8-OWNED-PATHS' 'Plan ownership is empty.'};@($paths)}
function New-Phase08R8ProductionContext([string]$ExpectedRepository,[string]$ExpectedRemote){
  $repo=(Invoke-R8PreLiveGit @('rev-parse','--show-toplevel')).lines[0];$head=(Invoke-R8PreLiveGit @('rev-parse','HEAD')).lines[0];$remoteUrl=Invoke-R8PreLiveGit @('config','--get',"remote.$ExpectedRemote.url");if($ExpectedRepository-cne'tchivs/moonbit-foundation'-or$ExpectedRemote-cne'origin'-or$remoteUrl.lines.Count-ne1){Throw-R8PreLive 'P08-R8-REMOTE' 'Canonical remote is missing.'}
  $rows=@((Invoke-R8PreLiveGit @('ls-remote','--tags',$ExpectedRemote)).lines);$base=New-Phase08R7ProductionContext $ExpectedRepository $ExpectedRemote -RemoteTagRows $rows -HistoryCount 8
  $histories=@($base.histories|ForEach-Object{[pscustomobject][ordered]@{attempt=$_.attempt;release_ref=$_.release_ref;source_sha=$_.source_sha;tag_object_sha=$_.tag_object_sha;peel_sha=$_.peel_sha;record_sha256=$_.record_sha256;record=$_.record;execution_root=$_.execution_root;state_root=$_.state_root;immutable_files=$_.immutable_files}})
  $phase=Join-Path $repo '.planning/phases/08-ordered-mooncakes-publication-and-registry-consumers';$owned=@();foreach($id in @('08-19','08-20','08-21')){$owned+=Get-R8OwnedPaths (Join-Path $phase "$id-PLAN.md")};$owned=@($owned|Select-Object -Unique)
  $clean=((Invoke-R8PreLiveGit (@('diff','--quiet','HEAD','--')+$owned) -AllowFailure).exit_code-eq0)-and((Invoke-R8PreLiveGit (@('diff','--cached','--quiet','--')+$owned) -AllowFailure).exit_code-eq0)
  $summaries=[ordered]@{};foreach($id in @('08-19','08-20','08-21')){$relative=".planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/$id-SUMMARY.md";$commit=((Invoke-R8PreLiveGit @('log','-1','--format=%H','--',$relative)).lines|Select-Object -First 1);$summaries["plan_$($id.Replace('-','_'))"]=[pscustomobject][ordered]@{commit_sha=$commit;committed_at_head=((Invoke-R8PreLiveGit @('cat-file','-e',"HEAD:$relative") -AllowFailure).exit_code-eq0);ancestor_of_head=((Invoke-R8PreLiveGit @('merge-base','--is-ancestor',$commit,$head) -AllowFailure).exit_code-eq0)}}
  $archives=[pscustomobject][ordered]@{core=[pscustomobject][ordered]@{module='mb-core';sha256='3342fee3e4876ef242b73bfd91e7e00178fd02a3d1959a387f43ac17fd77508a';size=125855;canonical=$true};color=[pscustomobject][ordered]@{module='mb-color';sha256='c763c189ff59b6541cb742bf6b78ddcc9800946ce3e3d1468f1ad4ee763d978c';size=89069;canonical=$true};image=[pscustomobject][ordered]@{module='mb-image';sha256='8150a1d0d75177ec9af4aa4c0f27fc25cab0c9a3ef5f9f27c0d9e0741e25e02e';size=248379;canonical=$true}}
  $ref='refs/tags/modules-v0.1.0-r8'
  $localAbsent=(Invoke-R8PreLiveGit @('show-ref','--verify','--quiet',$ref) -AllowFailure).exit_code-ne0
  $remoteAbsent=@($rows|Where-Object{$_-cmatch'\trefs/tags/modules-v0\.1\.0-r8(?:\^\{\})?$'}).Count-eq0
  $handoffAbsent=-not(Test-Path -LiteralPath (Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r8-handoff.json'))
  $control=Read-ReleaseJson (Join-Path $repo 'policy/release-control.json')
  [pscustomobject][ordered]@{
    schema_version='mnf-phase08-r8-pre-live-context/1';repository=$ExpectedRepository;remote=$ExpectedRemote;head_sha=$head
    histories=$histories;historical_history_set_sha256=[string]$control.initial_attempt_family.history_set_sha256
    canonical_archives=$archives;owned_paths_clean=$clean;summaries=[pscustomobject]$summaries
    r8_local_absent=$localAbsent;r8_remote_absent=$remoteAbsent;handoff_absent=$handoffAbsent;output_write_attempted=$false
  }
}

if($LibraryOnly){return}
if(-not$Check-or$Repository-cne'tchivs/moonbit-foundation'-or$Remote-cne'origin'){Throw-R8PreLive 'P08-R8-INVOCATION' 'Use -Check -Repository tchivs/moonbit-foundation -Remote origin.'}
Assert-Phase08R8PreLive (New-Phase08R8ProductionContext $Repository $Remote)|ConvertTo-Json -Depth 20 -Compress
