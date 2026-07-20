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

function Throw-P08R9([string]$Id,[string]$Message){throw "$Id`: $Message"}
function Get-P08R9Sha([string]$Text){
  ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($Text)))).ToLowerInvariant()
}

if(-not $Check){Throw-P08R9 'P08-R9-CHECK' 'Only -Check is supported by the zero-write selector.'}
if($Repository -cne 'tchivs/moonbit-foundation' -or [string]::IsNullOrWhiteSpace($Remote)){Throw-P08R9 'P08-R9-REPOSITORY' 'The exact repository and one remote are required.'}

$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$policyPath=if([string]::IsNullOrWhiteSpace($FixturePolicyPath)){Join-Path $repoRoot 'policy/release-control.json'}else{[IO.Path]::GetFullPath($FixturePolicyPath)}
if(-not(Test-Path -LiteralPath $policyPath -PathType Leaf)){Throw-P08R9 'P08-R9-POLICY' 'Release control policy is missing.'}
$policy=Get-Content -LiteralPath $policyPath -Raw|ConvertFrom-Json -Depth 100
$history=@($policy.initial_attempt_family.terminal_negative_history)
$expectedAttempts='attempt_zero,r1,r2,r3,r4,r5,r6,r7,r8'
$expectedDigests=@(
  'b9bda5378ea339f4cdd42c417c1cc0cf8caabbd51ab11d453cd45ddae77d9b52',
  'cba047dae2e6b4e1bbf0248653ed7848f144971b54a0a4ed30ef42ab97325653',
  'aae8bee66e7dbfca7f3f22f1b52071e7888ae3ec8feee513d1c5d8eba6111609',
  'cf29473b2b07ff9aa8fd8a4810ddc45f6aacd2fd4b74048f5d29b3b6fa939d41',
  'd9b045bc65df87dc2701144ea7716defc67acb84ec9ea8e7ffdafd0118ba0906',
  '1239b63f983bef86ac44c731171093ad67759de9cce7c15610b92f5df6214843',
  '3f9c0d9916dbccfa9144488d2967ee1a7fb3fd1d9936f8cc4139c2734f2d0ad4',
  'baf5d4921c75b2ba4a64cd234663a1b7086d6c45a653edd1ce4a63f56882933f',
  '8a7729234a62425d0082a7b7a4615f2757ab4bc59938925b8ca031e2e00c10c8'
)
$historical_r8_sha256=$expectedDigests[8]
$historical_history_set_sha256='39e45ed9aecf1788d106a043dd4b421243a577b66534d0748ca61937a0de86a8'
if($policy.initial_attempt_family.current_attempt -cne 'r9' -or $policy.initial_profile.release_ref -cne 'refs/tags/modules-v0.1.0-r9' -or $history.Count -ne 9 -or ($history.attempt -join ',') -cne $expectedAttempts -or (($history.record_sha256)-join ',') -cne ($expectedDigests-join ',')){Throw-P08R9 'P08-R9-HISTORY' 'Only the ordered nine terminal-negative histories may authorize r9 pre-live.'}
if([string]$policy.initial_attempt_family.history_set_sha256 -cne (Get-P08R9Sha ($expectedDigests-join "`n")) -or [string]$policy.initial_attempt_family.history_set_sha256 -cne $historical_history_set_sha256){Throw-P08R9 'P08-R9-HISTORY' 'The LF-ordered history set digest drifted.'}
$r8=$history[8]
if($r8.release_ref -cne 'refs/tags/modules-v0.1.0-r8' -or $r8.source_sha -cne '8d0f050a2ea2a5f136d87f913987d59ea99a13d4' -or $r8.tag_object_sha -cne '20907c7bbd11b91d4482dd113d149b3a107c9672' -or $r8.failure_code -cne 'PREP15-CANONICAL-ARCHIVE' -or $r8.failure_detail -cne 'REL-XPLAT-NONCANONICAL' -or $r8.hosted_run_present -ne $false -or @('boundary_locator_count','active_attempt_count','prepared_artifact_upload_count','publisher_dry_run_count','exact_existing_authority_count','hosted_preflight_downstream_count','publisher_count','observation_count','cold_consumer_count','authorization_packet_count','authorization_receipt_count','handoff_count','publish_one_count','mutation_count','successor_count').Where({[int]$r8.$_ -ne 0}).Count -ne 0){Throw-P08R9 'P08-R9-R8-TERMINAL' 'r8 must remain the exact pre-locator, no-run, zero-downstream terminal record.'}

if($null -eq $RemoteTagRows){$RemoteTagRows=@(& git ls-remote --tags $Remote)}
$remoteTagQueryCount=1
$r8Object=@($RemoteTagRows|Where-Object{$_ -ceq "20907c7bbd11b91d4482dd113d149b3a107c9672`trefs/tags/modules-v0.1.0-r8"})
$r8Peeled=@($RemoteTagRows|Where-Object{$_ -ceq "8d0f050a2ea2a5f136d87f913987d59ea99a13d4`trefs/tags/modules-v0.1.0-r8^{}"})
if($r8Object.Count -ne 1 -or $r8Peeled.Count -ne 1 -or @($RemoteTagRows|Where-Object{$_ -match 'refs/tags/modules-v0[.]1[.]0-r9(?:\^\{\})?$'}).Count -ne 0){Throw-P08R9 'P08-R9-REMOTE-TAG' 'Remote tags must bind r8 object/peel exactly and prove r9 absence.'}

$fixedHandoff=if([string]::IsNullOrWhiteSpace($HandoffPath)){[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r9-handoff.json'))}else{[IO.Path]::GetFullPath($HandoffPath)}
if(Test-Path -LiteralPath $fixedHandoff){Throw-P08R9 'P08-R9-HANDOFF' 'The fixed r9 handoff must be absent before pre-live eligibility.'}
if(-not $LibraryOnly){
  foreach($summary in @('.planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/08-22-SUMMARY.md','.planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/08-23-SUMMARY.md')){
    if(-not(Test-Path -LiteralPath (Join-Path $repoRoot $summary) -PathType Leaf) -or [string]::IsNullOrWhiteSpace((& git -C $repoRoot log -1 --format=%H -- $summary)) -or -not [string]::IsNullOrWhiteSpace((& git -C $repoRoot status --porcelain -- $summary))){Throw-P08R9 'P08-R9-COMMITTED-CLEAN' "Required summary '$summary' is not committed-clean."}
  }
  & git -C $repoRoot show-ref --verify --quiet refs/tags/modules-v0.1.0-r9
  if($LASTEXITCODE -eq 0){Throw-P08R9 'P08-R9-LOCAL-TAG' 'The r9 tag must be absent before pre-live eligibility.'}
}

[pscustomobject][ordered]@{schema_version='mnf-phase08-r9-prelive/1';release_ref='refs/tags/modules-v0.1.0-r9';history_set_sha256='39e45ed9aecf1788d106a043dd4b421243a577b66534d0748ca61937a0de86a8';remote_tag_query_count=$remoteTagQueryCount;output_write_count=0;eligible=$true}|ConvertTo-Json -Compress
