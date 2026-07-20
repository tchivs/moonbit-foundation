[CmdletBinding()]
param(
  [switch]$Check,
  [Parameter(Mandatory)][string]$Repository,
  [Parameter(Mandatory)][string]$Remote,
  [string]$FixturePolicyPath,
  [string[]]$RemoteTagRows,
  [string]$HandoffPath,
  [switch]$LibraryOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Throw-P08R10([string]$Id,[string]$Message){throw "$Id`: $Message"}
function Get-P08R10Sha([string]$Text){([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($Text)))).ToLowerInvariant()}

if(-not $Check){Throw-P08R10 'P08-R10-CHECK' 'Only -Check is supported by the zero-write selector.'}
if($Repository -cne 'tchivs/moonbit-foundation' -or [string]::IsNullOrWhiteSpace($Remote)){Throw-P08R10 'P08-R10-REPOSITORY' 'The exact repository and one remote are required.'}
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$policyPath=if([string]::IsNullOrWhiteSpace($FixturePolicyPath)){Join-Path $repoRoot 'policy/release-control.json'}else{[IO.Path]::GetFullPath($FixturePolicyPath)}
if(-not(Test-Path -LiteralPath $policyPath -PathType Leaf)){Throw-P08R10 'P08-R10-POLICY' 'Release control policy is missing.'}
$policy=Get-Content -LiteralPath $policyPath -Raw|ConvertFrom-Json -Depth 100
$history=@($policy.initial_attempt_family.terminal_negative_history)
$expectedAttempts='attempt_zero,r1,r2,r3,r4,r5,r6,r7,r8,r9'
$expectedDigests=@('b9bda5378ea339f4cdd42c417c1cc0cf8caabbd51ab11d453cd45ddae77d9b52','cba047dae2e6b4e1bbf0248653ed7848f144971b54a0a4ed30ef42ab97325653','aae8bee66e7dbfca7f3f22f1b52071e7888ae3ec8feee513d1c5d8eba6111609','cf29473b2b07ff9aa8fd8a4810ddc45f6aacd2fd4b74048f5d29b3b6fa939d41','d9b045bc65df87dc2701144ea7716defc67acb84ec9ea8e7ffdafd0118ba0906','1239b63f983bef86ac44c731171093ad67759de9cce7c15610b92f5df6214843','3f9c0d9916dbccfa9144488d2967ee1a7fb3fd1d9936f8cc4139c2734f2d0ad4','baf5d4921c75b2ba4a64cd234663a1b7086d6c45a653edd1ce4a63f56882933f','8a7729234a62425d0082a7b7a4615f2757ab4bc59938925b8ca031e2e00c10c8','6edf89e7afb98dca1e81e3d5db9ff8a47f96dbfb2919bdaeb176c76c52c581ec')
$historical_r9_sha256=$expectedDigests[9]
$historical_history_set_sha256='ea679099fbb3201708368847e0530c024e08fa9da5fd9100391cab61f1a1e7ee'
if($policy.initial_attempt_family.current_attempt -cne 'r10' -or $policy.initial_profile.release_ref -cne 'refs/tags/modules-v0.1.0-r10' -or $history.Count -ne 10 -or ($history.attempt -join ',') -cne $expectedAttempts -or (($history.record_sha256)-join ',') -cne ($expectedDigests-join ',')){Throw-P08R10 'P08-R10-HISTORY' 'Only the ordered ten terminal-negative histories may authorize r10 pre-live.'}
if([string]$policy.initial_attempt_family.history_set_sha256 -cne (Get-P08R10Sha ($expectedDigests-join "`n")) -or [string]$policy.initial_attempt_family.history_set_sha256 -cne $historical_history_set_sha256){Throw-P08R10 'P08-R10-HISTORY' 'The LF-ordered history set digest drifted.'}
$r8=$history[8]
if($r8.release_ref -cne 'refs/tags/modules-v0.1.0-r8' -or $r8.source_sha -cne '8d0f050a2ea2a5f136d87f913987d59ea99a13d4' -or $r8.tag_object_sha -cne '20907c7bbd11b91d4482dd113d149b3a107c9672' -or $r8.failure_code -cne 'PREP15-CANONICAL-ARCHIVE' -or $r8.failure_detail -cne 'REL-XPLAT-NONCANONICAL'){Throw-P08R10 'P08-R10-HISTORY' 'r8 must remain the exact protected legacy terminal record.'}
$r9=$history[9]
if($r9.release_ref -cne 'refs/tags/modules-v0.1.0-r9' -or $r9.source_sha -cne '4158dff7d3b6629861d4f5325573c45f3e3e3436' -or $r9.tag_object_sha -cne '79d4fa715c6d306e5435d5920c5f92111d5ce13a' -or $r9.tag_peeled_source_sha -cne '4158dff7d3b6629861d4f5325573c45f3e3e3436' -or $r9.prepare_attempt_completed -ne $false -or $r9.active_locator_created -ne $false -or $r9.failure_stage -cne 'pre_locator_strict_mode_history_schema_failure' -or $r9.failure_code -cne 'P08-PREPARE-HISTORY-SCHEMA' -or $r9.failure_detail -cne 'r8_legacy_history_field_access_under_strictmode' -or @('locator_count','boundary_locator_count','active_attempt_count','prepared_artifact_upload_count','publisher_dry_run_count','exact_existing_authority_count','hosted_preflight_downstream_count','publisher_count','observation_count','cold_consumer_count','authorization_packet_count','authorization_receipt_count','handoff_count','publish_one_count','mutation_count','successor_count').Where({[int]$r9.$_ -ne 0}).Count -ne 0){Throw-P08R10 'P08-R10-R9-TERMINAL' 'r9 must remain exact pre-locator terminal evidence and never become a candidate run.'}

if($null -eq $RemoteTagRows){$RemoteTagRows=@(& git ls-remote --tags $Remote)}
$remoteTagQueryCount=1
$r8Object=@($RemoteTagRows|Where-Object{$_ -ceq "20907c7bbd11b91d4482dd113d149b3a107c9672`trefs/tags/modules-v0.1.0-r8"});$r8Peeled=@($RemoteTagRows|Where-Object{$_ -ceq "8d0f050a2ea2a5f136d87f913987d59ea99a13d4`trefs/tags/modules-v0.1.0-r8^{}"})
$r9Object=@($RemoteTagRows|Where-Object{$_ -ceq "79d4fa715c6d306e5435d5920c5f92111d5ce13a`trefs/tags/modules-v0.1.0-r9"});$r9Peeled=@($RemoteTagRows|Where-Object{$_ -ceq "4158dff7d3b6629861d4f5325573c45f3e3e3436`trefs/tags/modules-v0.1.0-r9^{}"})
if($r8Object.Count -ne 1 -or $r8Peeled.Count -ne 1 -or $r9Object.Count -ne 1 -or $r9Peeled.Count -ne 1 -or @($RemoteTagRows|Where-Object{$_ -match 'refs/tags/modules-v0[.]1[.]0-r10(?:\^\{\})?$'}).Count -ne 0){Throw-P08R10 'P08-R10-REMOTE-TAG' 'Remote tags must bind immutable r8/r9 evidence and prove r10 absence.'}
$fixedHandoff=if([string]::IsNullOrWhiteSpace($HandoffPath)){[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r10-handoff.json'))}else{[IO.Path]::GetFullPath($HandoffPath)}
if(Test-Path -LiteralPath $fixedHandoff){Throw-P08R10 'P08-R10-HANDOFF' 'The fixed r10 handoff must be absent before pre-live eligibility.'}
if(-not $LibraryOnly){
  foreach($summary in @('.planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/08-23-SUMMARY.md','.planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/08-24-SUMMARY.md')){if(-not(Test-Path -LiteralPath (Join-Path $repoRoot $summary) -PathType Leaf) -or [string]::IsNullOrWhiteSpace((& git -C $repoRoot log -1 --format=%H -- $summary)) -or -not [string]::IsNullOrWhiteSpace((& git -C $repoRoot status --porcelain -- $summary))){Throw-P08R10 'P08-R10-COMMITTED-CLEAN' "Required summary '$summary' is not committed-clean."}}
  & git -C $repoRoot show-ref --verify --quiet refs/tags/modules-v0.1.0-r10
  if($LASTEXITCODE -eq 0){Throw-P08R10 'P08-R10-LOCAL-TAG' 'The r10 tag must be absent before pre-live eligibility.'}
}
[pscustomobject][ordered]@{schema_version='mnf-phase08-r10-prelive/1';release_ref='refs/tags/modules-v0.1.0-r10';historical_r9_sha256=$historical_r9_sha256;history_set_sha256=$historical_history_set_sha256;remote_tag_query_count=$remoteTagQueryCount;active_attempt_path=$null;exact_existing_authority_path=$null;mutation_authorization_packet_path=$null;authorization_receipt_path=$null;fixed_handoff_path=$fixedHandoff;observation_path=$null;mutation_count=0;output_write_count=0;eligible=$true}|ConvertTo-Json -Compress
