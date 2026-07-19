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
function Throw-P08R11([string]$Id,[string]$Message){throw "$Id`: $Message"}
function Get-P08R11Sha([string]$Text){([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($Text)))).ToLowerInvariant()}
if(-not $Check){Throw-P08R11 'P08-R11-CHECK' 'Only -Check is supported by the zero-write selector.'}
if($Repository -cne 'tchivs/moonbit-foundation' -or [string]::IsNullOrWhiteSpace($Remote)){Throw-P08R11 'P08-R11-REPOSITORY' 'The exact repository and one remote are required.'}
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$policyPath=if([string]::IsNullOrWhiteSpace($FixturePolicyPath)){Join-Path $repoRoot 'policy/release-control.json'}else{[IO.Path]::GetFullPath($FixturePolicyPath)}
if(-not(Test-Path -LiteralPath $policyPath -PathType Leaf)){Throw-P08R11 'P08-R11-POLICY' 'Release control policy is missing.'}
$policy=Get-Content -LiteralPath $policyPath -Raw|ConvertFrom-Json -Depth 100
$history=@($policy.initial_attempt_family.terminal_negative_history)
$expectedAttempts='attempt_zero,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10'
$expectedDigests=@('b9bda5378ea339f4cdd42c417c1cc0cf8caabbd51ab11d453cd45ddae77d9b52','cba047dae2e6b4e1bbf0248653ed7848f144971b54a0a4ed30ef42ab97325653','aae8bee66e7dbfca7f3f22f1b52071e7888ae3ec8feee513d1c5d8eba6111609','cf29473b2b07ff9aa8fd8a4810ddc45f6aacd2fd4b74048f5d29b3b6fa939d41','d9b045bc65df87dc2701144ea7716defc67acb84ec9ea8e7ffdafd0118ba0906','1239b63f983bef86ac44c731171093ad67759de9cce7c15610b92f5df6214843','3f9c0d9916dbccfa9144488d2967ee1a7fb3fd1d9936f8cc4139c2734f2d0ad4','baf5d4921c75b2ba4a64cd234663a1b7086d6c45a653edd1ce4a63f56882933f','8a7729234a62425d0082a7b7a4615f2757ab4bc59938925b8ca031e2e00c10c8','6edf89e7afb98dca1e81e3d5db9ff8a47f96dbfb2919bdaeb176c76c52c581ec','1d524890dd5f0c11e58bcd2884c2d4623e02759a5ff801f2554fcc2ae654895f')
$historical_r10_sha256=$expectedDigests[10]
$historical_history_set_sha256=(Get-P08R11Sha ($expectedDigests-join "`n"))
if($policy.initial_attempt_family.current_attempt -cne 'r11' -or $policy.initial_profile.release_ref -cne 'refs/tags/modules-v0.1.0-r11' -or $history.Count -ne 11 -or ($history.attempt -join ',') -cne $expectedAttempts -or (($history.record_sha256)-join ',') -cne ($expectedDigests-join ',')){Throw-P08R11 'P08-R11-HISTORY' 'Only the ordered eleven terminal-negative histories may authorize r11 pre-live.'}
if([string]$policy.initial_attempt_family.history_set_sha256 -cne $historical_history_set_sha256){Throw-P08R11 'P08-R11-HISTORY' 'The LF-ordered history set digest drifted.'}
$r10=$history[10]
$zeroFields=@('prepared_bundle_count','publisher_dry_run_count','observation_count','authorization_packet_count','authorization_receipt_count','handoff_count','publish_one_count','registry_operation_count','mutation_count','successor_count')
if($r10.PSObject.Properties.Name -ccontains 'active_attempt_path' -or $r10.attempt -cne 'r10' -or $r10.release_ref -cne 'refs/tags/modules-v0.1.0-r10' -or $r10.source_sha -cne 'd49edc53fb4ffca375e562a23789fb76bf8c41e2' -or $r10.tag_object_sha -cne '0546025c61d08a0973a2bb6040cbb19104ae64d1' -or $r10.tag_peeled_source_sha -cne 'd49edc53fb4ffca375e562a23789fb76bf8c41e2' -or $r10.failure_code -cne 'REL01-REF' -or @($zeroFields|Where-Object{[int]$r10.$_ -ne 0}).Count -ne 0){Throw-P08R11 'P08-R11-R10-TERMINAL' 'r10 must remain exact REL01-REF terminal evidence and never become active state.'}
if($null -eq $RemoteTagRows){$RemoteTagRows=@(& git ls-remote --tags $Remote)}
$remoteTagQueryCount=1
$object=@($RemoteTagRows|Where-Object{$_ -ceq "$($r10.tag_object_sha)`trefs/tags/modules-v0.1.0-r10"});$peeled=@($RemoteTagRows|Where-Object{$_ -ceq "$($r10.tag_peeled_source_sha)`trefs/tags/modules-v0.1.0-r10`^{}"})
if($object.Count -ne 1 -or $peeled.Count -ne 1 -or @($RemoteTagRows|Where-Object{$_ -match 'refs/tags/modules-v0[.]1[.]0-r11(?:\^\{\})?$'}).Count -ne 0){Throw-P08R11 'P08-R11-REMOTE-TAG' 'Remote tags must bind immutable r10 evidence and prove r11 absence.'}
$fixedHandoff=if([string]::IsNullOrWhiteSpace($HandoffPath)){[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r11-handoff.json'))}else{[IO.Path]::GetFullPath($HandoffPath)}
if(Test-Path -LiteralPath $fixedHandoff){Throw-P08R11 'P08-R11-HANDOFF' 'The fixed r11 handoff must be absent before pre-live eligibility.'}
if(-not $LibraryOnly){
  foreach($summary in @('.planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/08-26-SUMMARY.md','.planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/08-27-SUMMARY.md')){if(-not(Test-Path -LiteralPath (Join-Path $repoRoot $summary) -PathType Leaf) -or [string]::IsNullOrWhiteSpace((& git -C $repoRoot log -1 --format=%H -- $summary)) -or -not [string]::IsNullOrWhiteSpace((& git -C $repoRoot status --porcelain -- $summary))){Throw-P08R11 'P08-R11-COMMITTED-CLEAN' "Required summary '$summary' is not committed-clean."}}
  & git -C $repoRoot show-ref --verify --quiet refs/tags/modules-v0.1.0-r11
  if($LASTEXITCODE -eq 0){Throw-P08R11 'P08-R11-LOCAL-TAG' 'The r11 tag must be absent before pre-live eligibility.'}
}
[pscustomobject][ordered]@{schema_version='mnf-phase08-r11-prelive/1';release_ref='refs/tags/modules-v0.1.0-r11';historical_r10_sha256=$historical_r10_sha256;history_set_sha256=$historical_history_set_sha256;remote_tag_query_count=$remoteTagQueryCount;active_attempt_path=$null;exact_existing_authority_path=$null;mutation_authorization_packet_path=$null;authorization_receipt_path=$null;fixed_handoff_path=$fixedHandoff;observation_path=$null;mutation_count=0;output_write_count=0;eligible=$true}|ConvertTo-Json -Compress
