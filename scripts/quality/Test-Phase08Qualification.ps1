[CmdletBinding()]
param(
  [switch]$FixtureOnly,
  [switch]$CoreColorArtifacts,
  [switch]$LiveArtifacts,
  [switch]$AuthorizationPacket,
  [switch]$MutationAuthorizationPacket,
  [switch]$ExactExistingAuthority,
  [switch]$AuthorityUnion,
  [switch]$ReciprocalArtifacts,
  [Parameter(Mandatory)][string]$LocatorPath,
  [Parameter(Mandatory)][string]$ArtifactRoot,
  [string]$PacketPath,
  [string]$MutationAuthorizationPacketPath,
  [string]$ExactExistingAuthorityPath,
  [string]$CoreAuthorityRecordPath,
  [string]$ColorAuthorityRecordPath,
  [string]$ImageAuthorityRecordPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Throw-P08Qualification([string]$Id,[string]$Message) { throw "$Id`: $Message" }
function Get-P08QualificationSha([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Throw-P08Qualification 'P08-QUAL-FILE' "Missing '$Path'." }
  (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Assert-P08ClosedNames([object]$Value,[string[]]$Names,[string]$Id) {
  if ((@($Value.PSObject.Properties.Name) -join ',') -cne ($Names -join ',')) { Throw-P08Qualification $Id 'Closed field inventory drifted.' }
}
function Get-P08ExpectedPaths([string]$RootIntent) {
  $base=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08'))
  [pscustomobject]@{
    locator=[IO.Path]::GetFullPath((Join-Path $base 'phase-08-live-locator.json'))
    root=[IO.Path]::GetFullPath((Join-Path $base "artifacts/$RootIntent"))
    index=[IO.Path]::GetFullPath((Join-Path $base "artifacts/$RootIntent/index.json"))
  }
}
function Assert-P08UnderRoot([string]$Path,[string]$Root) {
  $full=[IO.Path]::GetFullPath($Path); $rootFull=[IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
  if (-not $full.StartsWith($rootFull+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)) { Throw-P08Qualification 'P08-QUAL-ESCAPE' "'$full' escapes '$rootFull'." }
  $full
}
function Open-P08QualificationStore {
  if (-not (Test-Path -LiteralPath $LocatorPath -PathType Leaf)) { Throw-P08Qualification 'P08-QUAL-LOCATOR' 'Durable locator is missing.' }
  $locator=Get-Content -LiteralPath $LocatorPath -Raw | ConvertFrom-Json -Depth 100
  Assert-P08ClosedNames $locator @('schema_version','artifact_root','index_path','repository','workflow','release_ref','source_sha','root_intent_sha256','intent_sha256','authorization_packet_path','authorization_packet_sha256','created_at_utc','locator_sha256') 'P08-QUAL-LOCATOR-CLOSED'
  $expected=Get-P08ExpectedPaths ([string]$locator.root_intent_sha256)
  if ([IO.Path]::GetFullPath($LocatorPath) -cne $expected.locator -or [IO.Path]::GetFullPath($ArtifactRoot) -cne $expected.root -or
      [IO.Path]::GetFullPath([string]$locator.artifact_root) -cne $expected.root -or [IO.Path]::GetFullPath([string]$locator.index_path) -cne $expected.index) { Throw-P08Qualification 'P08-QUAL-PATH' 'Locator, root, or index is not deterministically derived.' }
  if ($locator.schema_version -cne 'mnf-phase08-live-locator/1' -or $locator.repository -cne 'tchivs/moonbit-foundation' -or
      $locator.workflow -cne 'publish-modules.yml' -or $locator.release_ref -cne 'refs/tags/modules-v0.1.0' -or
      $locator.source_sha -notmatch '^[0-9a-f]{40}$' -or $locator.root_intent_sha256 -notmatch '^[0-9a-f]{64}$' -or $locator.intent_sha256 -notmatch '^[0-9a-f]{64}$') { Throw-P08Qualification 'P08-QUAL-BINDING' 'Immutable store binding is invalid.' }
  $locatorProjection=[ordered]@{};foreach($property in $locator.PSObject.Properties){if($property.Name -cne 'locator_sha256'){$locatorProjection[$property.Name]=$property.Value}}
  $locatorBytes=[Text.UTF8Encoding]::new($false).GetBytes(([pscustomobject]$locatorProjection|ConvertTo-Json -Depth 100 -Compress))
  $locatorDigest=([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($locatorBytes))).ToLowerInvariant()
  if ([string]$locator.locator_sha256 -cne $locatorDigest) { Throw-P08Qualification 'P08-QUAL-LOCATOR-DIGEST' 'Locator digest drifted.' }
  foreach($item in @(Get-Item -LiteralPath $expected.root -Force; Get-ChildItem -LiteralPath $expected.root -Recurse -Force)) {
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Throw-P08Qualification 'P08-QUAL-LINK' 'Linked evidence is forbidden.' }
  }
  $index=Get-Content -LiteralPath $expected.index -Raw | ConvertFrom-Json -Depth 100
  Assert-P08ClosedNames $index @('schema_version','root_intent_sha256','records') 'P08-QUAL-INDEX-CLOSED'
  if ($index.schema_version -cne 'mnf-phase08-live-index/1' -or $index.root_intent_sha256 -cne $locator.root_intent_sha256) { Throw-P08Qualification 'P08-QUAL-INDEX' 'Index binding drifted.' }
  $seen=@{}; $logical=@{}
  foreach($record in @($index.records)) {
    Assert-P08ClosedNames $record @('logical_key','kind','run_id','run_attempt','artifact_name','path','sha256') 'P08-QUAL-RECORD-CLOSED'
    if ($seen.ContainsKey([string]$record.path) -or $logical.ContainsKey([string]$record.logical_key)) { Throw-P08Qualification 'P08-QUAL-DUPLICATE' 'Duplicate indexed evidence.' }
    $seen[[string]$record.path]=$true; $logical[[string]$record.logical_key]=$true
    $absolute=Assert-P08UnderRoot (Join-Path $expected.root ([string]$record.path)) $expected.root
    if ((Get-P08QualificationSha $absolute) -cne [string]$record.sha256) { Throw-P08Qualification 'P08-QUAL-DIGEST' "Digest drifted for '$($record.path)'." }
  }
  foreach($file in @(Get-ChildItem -LiteralPath $expected.root -Recurse -File)) {
    if ($file.FullName -ceq $expected.index) { continue }
    $relative=[IO.Path]::GetRelativePath($expected.root,$file.FullName).Replace('\','/')
    if (-not $seen.ContainsKey($relative)) { Throw-P08Qualification 'P08-QUAL-UNINDEXED' "Unindexed evidence '$relative'." }
  }
  [pscustomobject]@{ locator=$locator; index=$index; paths=$expected }
}

function Assert-P08FixtureContract {
  $helper=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-Phase08HostedRun.ps1') -Raw
  $workflow=Get-Content -LiteralPath (Join-Path $repoRoot '.github/workflows/publish-modules.yml') -Raw
  $authoritySchema=Join-Path $repoRoot 'release/qualification/phase-08-authority-schema.json'
  if (-not (Test-Path -LiteralPath $authoritySchema -PathType Leaf)) { Throw-P08Qualification 'P08-QUAL-AUTHORITY-SCHEMA' 'Closed authority schema is missing.' }
  foreach($required in @(
    'InitializeBoundary','PrepareAttempt','PublisherDryRun','HostedPreflight','MaterializePublicSurface','ObserveOnly',
    'IndexSanitizedArtifact','AssembleAuthorizationPacket','SelectExactExistingAuthority','SelectPublishedNowAuthority','PublishOne',
    'Assert-P08ExecutionBoundary','execution_root','boundary_sha','MutationAuthorizationPacketPath','ExactExistingAuthorityPath',
    'PriorAuthorityRecordPath','refs/tags/modules-v0.1.0-r1','P08-HOSTED-AMBIGUOUS-RUN','P08-HOSTED-AMBIGUOUS-ARTIFACT',
    'P08-STORE-UNINDEXED','P08-STORE-RESUME-DRIFT','P08-AUTHORITY-BOTH','P08-AUTHORITY-NEITHER'
  )) {
    if ($helper.IndexOf($required,[StringComparison]::Ordinal) -lt 0) { Throw-P08Qualification 'P08-QUAL-HELPER' "Missing helper contract '$required'." }
  }
  foreach($required in @('operation_mode:','prepared_manifest_sha256:','target_module:','PublisherDryRun','HostedPreflight','PublishOne','publish --frozen --dry-run','native_runtime_verified')) {
    if ($workflow.IndexOf($required,[StringComparison]::Ordinal) -lt 0) { Throw-P08Qualification 'P08-QUAL-WORKFLOW' "Missing workflow contract '$required'." }
  }
  if (@([regex]::Matches($workflow,[regex]::Escape('${{ secrets.MOONCAKES_TOKEN }}'))).Count -ne 2) { Throw-P08Qualification 'P08-QUAL-SECRET' 'Secret must occur once in dry-run and once in PublishOne, each in isolated jobs.' }
  if ($workflow.IndexOf('moon publish --frozen`n',[StringComparison]::Ordinal) -ge 0) { Throw-P08Qualification 'P08-QUAL-NONDRY' 'An unclassified inline non-dry command is forbidden.' }
  Write-Host 'Phase 8 qualification fixtures/static contract: PASS.'
}

function Assert-P08AuthorizationPacket {
  if ([string]::IsNullOrWhiteSpace($PacketPath)) { Throw-P08Qualification 'P08-QUAL-PACKET-PATH' 'AuthorizationPacket requires -PacketPath.' }
  $store=Open-P08QualificationStore
  $packetFull=[IO.Path]::GetFullPath($PacketPath); $expectedPacket=Join-Path $store.paths.root 'authorization/authorize-core.json'
  if ($packetFull -cne $expectedPacket) { Throw-P08Qualification 'P08-QUAL-PACKET-PATH' 'Packet path is not canonical.' }
  $packet=Get-Content -LiteralPath $packetFull -Raw | ConvertFrom-Json -Depth 100
  $required=@('schema_version','repository','workflow','release_ref','source_sha','root_intent_sha256','intent_sha256','prepared_manifest_sha256','target_module','publisher_dry_run','fresh_absence','hosted_preflight','gate_digests','created_at_utc','packet_sha256')
  Assert-P08ClosedNames $packet $required 'P08-QUAL-PACKET-CLOSED'
  if ($packet.schema_version -cne 'mnf-phase08-authorization-packet/1' -or $packet.repository -cne $store.locator.repository -or $packet.workflow -cne $store.locator.workflow -or
      $packet.release_ref -cne $store.locator.release_ref -or $packet.source_sha -cne $store.locator.source_sha -or $packet.root_intent_sha256 -cne $store.locator.root_intent_sha256 -or
      $packet.intent_sha256 -cne $store.locator.intent_sha256 -or $packet.target_module -cne 'mb-core') { Throw-P08Qualification 'P08-QUAL-PACKET-BINDING' 'Packet binding drifted.' }
  if ([string]$store.locator.authorization_packet_path -cne 'authorization/authorize-core.json' -or [IO.Path]::GetFullPath((Join-Path $store.paths.root ([string]$store.locator.authorization_packet_path))) -cne $packetFull -or
      [string]$packet.prepared_manifest_sha256 -notmatch '^[0-9a-f]{64}$') { Throw-P08Qualification 'P08-QUAL-PACKET-BINDING' 'Locator packet or prepared binding is incomplete.' }
  $dry=$packet.publisher_dry_run; $native=$packet.hosted_preflight; $absence=$packet.fresh_absence
  if ($dry.mode -cne 'PublisherDryRun' -or $dry.command_classification -cne 'moon_publish_frozen_dry_run' -or [int]$dry.exit_code -ne 0 -or $dry.credential_state_removed -ne $true -or $dry.mutation_performed -ne $false -or
      $dry.raw_output_persisted -ne $false -or $dry.repository -cne $packet.repository -or $dry.workflow -cne $packet.workflow -or $dry.release_ref -cne $packet.release_ref -or $dry.source_sha -cne $packet.source_sha -or
      $dry.root_intent_sha256 -cne $packet.root_intent_sha256 -or $dry.intent_sha256 -cne $packet.intent_sha256 -or $dry.prepared_manifest_sha256 -cne $packet.prepared_manifest_sha256 -or
      $dry.target_module -cne 'mb-core' -or $dry.module_identity -cne 'tchivs/mb-core@0.1.0' -or [string]$dry.run_id -notmatch '^[1-9][0-9]*$' -or [int]$dry.run_attempt -lt 1) { Throw-P08Qualification 'P08-QUAL-DRYRUN' 'Dry-run evidence is unsafe or incomplete.' }
  if ($native.mode -cne 'HostedPreflight' -or $native.native_runtime_verified -ne $true -or $native.compile_only -ne $false -or [int]$native.exit_code -ne 0 -or $native.sentinel_match -ne $true -or
      $native.expected_sentinel_sha256 -cne $native.observed_sentinel_sha256 -or $native.repository -cne $packet.repository -or $native.workflow -cne $packet.workflow -or $native.release_ref -cne $packet.release_ref -or
      $native.source_sha -cne $packet.source_sha -or $native.root_intent_sha256 -cne $packet.root_intent_sha256 -or $native.intent_sha256 -cne $packet.intent_sha256 -or
      $native.prepared_manifest_sha256 -cne $packet.prepared_manifest_sha256 -or [string]$native.run_id -notmatch '^[1-9][0-9]*$' -or [int]$native.run_attempt -lt 1 -or
      [string]$native.toolchain_identity -notmatch '0[.]1[.]20260713|75c7e1f' -or [string]::IsNullOrWhiteSpace([string]$native.linker_identity) -or [string]::IsNullOrWhiteSpace([string]$native.runtime_identity)) { Throw-P08Qualification 'P08-QUAL-NATIVE' 'Hosted native evidence is incomplete or compile-only.' }
  if ($absence.outcome -cne 'absent' -or $absence.mutation_authorized -ne $false -or $absence.identity -cne 'tchivs/mb-core@0.1.0') { Throw-P08Qualification 'P08-QUAL-ABSENCE' 'Fresh absence evidence is missing or mutation-indicating.' }
  foreach($entry in @($dry,$native,$absence)) {
    if ($entry.sha256 -notmatch '^[0-9a-f]{64}$' -or [string]::IsNullOrWhiteSpace([string]$entry.path)) { Throw-P08Qualification 'P08-QUAL-EVIDENCE' 'Evidence identity is incomplete.' }
    $absolute=Assert-P08UnderRoot (Join-Path $store.paths.root ([string]$entry.path)) $store.paths.root
    if ((Get-P08QualificationSha $absolute) -cne [string]$entry.sha256) { Throw-P08Qualification 'P08-QUAL-EVIDENCE-DIGEST' 'Bound evidence changed.' }
  }
  $projection=[ordered]@{}; foreach($property in $packet.PSObject.Properties){ if($property.Name -cne 'packet_sha256'){ $projection[$property.Name]=$property.Value } }
  $bytes=[Text.UTF8Encoding]::new($false).GetBytes(([pscustomobject]$projection|ConvertTo-Json -Depth 100 -Compress))
  $digest=([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))).ToLowerInvariant()
  if ($packet.packet_sha256 -cne $digest -or (Get-P08QualificationSha $packetFull) -cne [string]$store.locator.authorization_packet_sha256) { Throw-P08Qualification 'P08-QUAL-PACKET-DIGEST' 'Packet or locator digest drifted.' }
  Write-Host 'Phase 8 AuthorizationPacket selector: PASS.'
  $packet
}

if (-not ($FixtureOnly -or $CoreColorArtifacts -or $LiveArtifacts -or $AuthorizationPacket -or $MutationAuthorizationPacket -or $ExactExistingAuthority -or $AuthorityUnion -or $ReciprocalArtifacts)) { Throw-P08Qualification 'P08-QUAL-SELECTOR' 'Choose a selector.' }
if ($FixtureOnly) { Assert-P08FixtureContract; return }
if ($AuthorizationPacket) { Assert-P08AuthorizationPacket; return }
$store=Open-P08QualificationStore
$requiredKinds=if($CoreColorArtifacts){@('publisher-dry-run','hosted-preflight')}else{@('publisher-dry-run','hosted-preflight','absence-observation')}
foreach($kind in $requiredKinds) { if (@($store.index.records|Where-Object kind -ceq $kind).Count -ne 1) { Throw-P08Qualification 'P08-QUAL-LIVE-ARTIFACT' "Expected one '$kind' record." } }
Write-Host 'Phase 8 indexed artifact selector: PASS.'
