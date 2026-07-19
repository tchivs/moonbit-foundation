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
function Throw-P08R13([string]$Id,[string]$Message){throw "$Id`: $Message"}
function Get-P08R13Sha([string]$Text){([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($Text)))).ToLowerInvariant()}

if(-not $Check){Throw-P08R13 'P08-R13-CHECK' 'Only -Check is supported by the zero-write selector.'}
if($Repository -cne 'tchivs/moonbit-foundation' -or [string]::IsNullOrWhiteSpace($Remote)){Throw-P08R13 'P08-R13-REPOSITORY' 'The exact repository and one remote are required.'}
$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$policyPath=if([string]::IsNullOrWhiteSpace($FixturePolicyPath)){Join-Path $repoRoot 'policy/release-control.json'}else{[IO.Path]::GetFullPath($FixturePolicyPath)}
if(-not(Test-Path -LiteralPath $policyPath -PathType Leaf)){Throw-P08R13 'P08-R13-POLICY' 'Release control policy is missing.'}
foreach($required in @('Invoke-Phase08R13Boundary.ps1','Test-Phase08R13Boundary.ps1')){if(-not(Test-Path -LiteralPath (Join-Path $PSScriptRoot $required) -PathType Leaf)){Throw-P08R13 'P08-R13-WRAPPER' "Required canonical wrapper contract '$required' is missing."}}
$policy=Get-Content -LiteralPath $policyPath -Raw|ConvertFrom-Json -Depth 100
$history=@($policy.initial_attempt_family.terminal_negative_history)
$expectedAttempts='attempt_zero,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12'
$expectedDigests=@('b9bda5378ea339f4cdd42c417c1cc0cf8caabbd51ab11d453cd45ddae77d9b52','cba047dae2e6b4e1bbf0248653ed7848f144971b54a0a4ed30ef42ab97325653','aae8bee66e7dbfca7f3f22f1b52071e7888ae3ec8feee513d1c5d8eba6111609','cf29473b2b07ff9aa8fd8a4810ddc45f6aacd2fd4b74048f5d29b3b6fa939d41','d9b045bc65df87dc2701144ea7716defc67acb84ec9ea8e7ffdafd0118ba0906','1239b63f983bef86ac44c731171093ad67759de9cce7c15610b92f5df6214843','3f9c0d9916dbccfa9144488d2967ee1a7fb3fd1d9936f8cc4139c2734f2d0ad4','baf5d4921c75b2ba4a64cd234663a1b7086d6c45a653edd1ce4a63f56882933f','8a7729234a62425d0082a7b7a4615f2757ab4bc59938925b8ca031e2e00c10c8','6edf89e7afb98dca1e81e3d5db9ff8a47f96dbfb2919bdaeb176c76c52c581ec','1d524890dd5f0c11e58bcd2884c2d4623e02759a5ff801f2554fcc2ae654895f','def1bf53a3305c72360bebb651f56d28cdcaac83150e76e3c3134962ade4e9d1','92397fbdfc679f154382928ee6f94c57e46b40b7c5f7e8d65759b0165d6c96a8')
$historical_r12_sha256=$expectedDigests[12]
$historical_history_set_sha256=(Get-P08R13Sha ($expectedDigests-join "`n"))
if($policy.initial_attempt_family.current_attempt -cne 'r13' -or $policy.initial_profile.release_ref -cne 'refs/tags/modules-v0.1.0-r13' -or $history.Count -ne 13 -or ($history.attempt -join ',') -cne $expectedAttempts -or (($history.record_sha256)-join ',') -cne ($expectedDigests-join ',')){Throw-P08R13 'P08-R13-HISTORY' 'Only the ordered thirteen terminal-negative histories may authorize r13 pre-live.'}
if([string]$policy.initial_attempt_family.history_set_sha256 -cne $historical_history_set_sha256){Throw-P08R13 'P08-R13-HISTORY' 'The LF-ordered history set digest drifted.'}
$r12=$history[12]
$zeroFields=@('prepared_bundle_count','publisher_dry_run_count','observation_count','authorization_packet_count','authorization_receipt_count','handoff_count','publish_one_count','registry_operation_count','mutation_count','successor_count')
if($r12.PSObject.Properties.Name -ccontains 'active_attempt_path' -or $r12.attempt -cne 'r12' -or $r12.release_ref -cne 'refs/tags/modules-v0.1.0-r12' -or $r12.source_sha -cne '5e7b19cdc74ec11d5c524ff34a36c266b15bba39' -or $r12.tag_object_sha -cne '57b76c9f9044d3190acc1e4c3fb7ada516f4dece' -or $r12.tag_peeled_source_sha -cne '5e7b19cdc74ec11d5c524ff34a36c266b15bba39' -or $r12.failure_code -cne 'REL01-REF' -or @($zeroFields|Where-Object{$r12.PSObject.Properties.Name -ccontains $_ -and [int]$r12.$_ -ne 0}).Count -ne 0){Throw-P08R13 'P08-R13-R12-TERMINAL' 'r12 must remain exact canonical-wrapper terminal evidence and never become active state.'}
if($null -eq $RemoteTagRows){$RemoteTagRows=@(& git ls-remote --tags $Remote)}
$remoteTagQueryCount=1
$object=@($RemoteTagRows|Where-Object{$_ -ceq "$($r12.tag_object_sha)`trefs/tags/modules-v0.1.0-r12"});$peeled=@($RemoteTagRows|Where-Object{$_ -ceq "$($r12.tag_peeled_source_sha)`trefs/tags/modules-v0.1.0-r12`^{}"})
if($object.Count -ne 1 -or $peeled.Count -ne 1 -or @($RemoteTagRows|Where-Object{$_ -match 'refs/tags/modules-v0[.]1[.]0-r13(?:\^\{\})?$'}).Count -ne 0){Throw-P08R13 'P08-R13-REMOTE-TAG' 'Remote tags must bind immutable r12 evidence and prove r13 absence.'}
$fixedHandoff=if([string]::IsNullOrWhiteSpace($HandoffPath)){[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r13-handoff.json'))}else{[IO.Path]::GetFullPath($HandoffPath)}
if(Test-Path -LiteralPath $fixedHandoff){Throw-P08R13 'P08-R13-HANDOFF' 'The fixed r13 handoff must be absent before pre-live eligibility.'}
if(-not $LibraryOnly){
  foreach($summary in @('.planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/08-35-SUMMARY.md','.planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/08-36-SUMMARY.md')){if(-not(Test-Path -LiteralPath (Join-Path $repoRoot $summary) -PathType Leaf) -or [string]::IsNullOrWhiteSpace((& git -C $repoRoot log -1 --format=%H -- $summary)) -or -not [string]::IsNullOrWhiteSpace((& git -C $repoRoot status --porcelain -- $summary))){Throw-P08R13 'P08-R13-COMMITTED-CLEAN' "Required summary '$summary' is not committed-clean."}}
  & git -C $repoRoot show-ref --verify --quiet refs/tags/modules-v0.1.0-r13
  if($LASTEXITCODE -eq 0){Throw-P08R13 'P08-R13-LOCAL-TAG' 'The r13 tag must be absent before pre-live eligibility.'}
}
[pscustomobject][ordered]@{schema_version='mnf-phase08-r13-prelive/1';release_ref='refs/tags/modules-v0.1.0-r13';historical_r12_sha256=$historical_r12_sha256;history_set_sha256=$historical_history_set_sha256;remote_tag_query_count=$remoteTagQueryCount;active_attempt_path=$null;exact_existing_authority_path=$null;mutation_authorization_packet_path=$null;authorization_receipt_path=$null;fixed_handoff_path=$fixedHandoff;observation_path=$null;mutation_count=0;output_write_count=0;eligible=$true}|ConvertTo-Json -Compress
