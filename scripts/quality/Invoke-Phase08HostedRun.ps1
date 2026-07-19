[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet(
    'InitializeBoundary','PrepareAttempt','HostedPreflight','PublisherDryRun','MaterializePublicSurface','ObserveOnly',
    'IndexSanitizedArtifact','AssembleAuthorizationPacket','PersistAuthorizationReceipt','WriteHandoff',
    'SelectExactExistingAuthority','SelectPublishedNowAuthority','PublishOne'
  )][string]$Mode,
  [string]$Repository,
  [string]$Workflow,
  [string]$ReleaseRef,
  [string]$SourceSha,
  [string]$RootIntentSha256,
  [string]$IntentSha256,
  [string]$PreparedManifestSha256,
  [ValidateSet('mb-core','mb-color','mb-image')][string]$TargetModule,
  [string]$LocatorPath,
  [string]$ArtifactRoot,
  [string]$ExecutionRoot,
  [string]$BoundarySha,
  [string]$BoundaryLocatorPath,
  [string]$HistoricalRunId,
  [int]$HistoricalRunAttempt,
  [string]$HistoricalReleaseRef,
  [string]$HistoricalSourceSha,
  [string]$PreparedRoot,
  [string]$StateRoot,
  [ValidateSet('exact-existing','post-publish')][string]$ObservationPhase,
  [string]$MutationAuthorizationPacketPath,
  [string]$ExactExistingAuthorityPath,
  [string]$PriorAuthorityRecordPath,
  [string]$ObservationRecordPath,
  [string]$ColdProofPath,
  [string]$ReducerRecordPath,
  [Alias('HistoricalRecordPath')][string]$HistoricalNegativeRecordPath,
  [string]$SurfaceFixturePath,
  [ValidateSet('PublicSurface','Observation','ColdProof','ReducerRecord','HistoricalNegative')][string]$ArtifactKind,
  [string]$ArtifactPath,
  [string]$ArtifactFileSha256,
  [string]$ArtifactContentSha256,
  [string]$NativeToolchainBin,
  [string]$AuthorizationPacketPath,
  [string]$AuthorizationResponse,
  [string]$AuthorizationReceiptPath,
  [string]$ActiveAttemptPath,
  [string]$AttemptZeroHistoryPath,
  [string]$R1HistoryPath,
  [string]$R2HistoryPath,
  [string]$R3HistoryPath,
  [string]$R4HistoryPath,
  [string]$R5HistoryPath,
  [string]$R6HistoryPath,
  [ValidateSet('mutation_authorized','exact_existing')][string]$AuthorityVariant,
  [string]$HandoffPath,
  [string]$TempRoot,
  [object]$CreatedAt,
  [string]$PriorRunId='',
  [string]$PriorArtifactName='',
  [switch]$LibraryOnly,
  [scriptblock]$GhCommand,
  [scriptblock]$GitCommand,
  [scriptblock]$SurfaceProvider,
  [scriptblock]$PrepareProvider
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')

function Throw-P08HostedRule([string]$Id,[string]$Message) { throw "$Id`: $Message" }

function Get-P08Sha256([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Throw-P08HostedRule 'P08-HOSTED-FILE' "Missing file '$Path'." }
  (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-P08CanonicalJson([object]$Value) {
  ($Value | ConvertTo-Json -Depth 100 -Compress)
}

function Get-P08ObjectDigest([object]$Value) {
  $bytes=[Text.UTF8Encoding]::new($false).GetBytes((Get-P08CanonicalJson $Value))
  ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))).ToLowerInvariant()
}

function Get-P08SelfExcludingDigest([object]$Value,[string]$DigestProperty) {
  $projection=[ordered]@{}
  foreach($property in $Value.PSObject.Properties){if($property.Name -cne $DigestProperty){$projection[$property.Name]=$property.Value}}
  Get-P08ObjectDigest ([pscustomobject]$projection)
}

function Get-P08ActiveAttemptProjection([object]$Value) {
  $projection=[ordered]@{}
  foreach($property in $Value.PSObject.Properties){
    if($property.Name -ceq 'active_attempt_sha256'){continue}
    $projection[$property.Name]=if($property.Name -ceq 'updated_at_utc'){ConvertTo-ReleaseCanonicalUtc $property.Value}else{$property.Value}
  }
  [pscustomobject]$projection
}

function Write-P08AuthorizationReceipt {
  param(
    [Parameter(Mandatory)][string]$PacketPath,[Parameter(Mandatory)][string]$ReceiptPath,
    [Parameter(Mandatory)][string]$BoundarySha,[Parameter(Mandatory)][string]$Response,[Parameter(Mandatory)][object]$CreatedAt
  )
  if($Response -cne 'authorize-core'){Throw-P08HostedRule 'P08-RECEIPT-LITERAL' 'Only the exact literal authorize-core may be persisted.'}
  $packet=Get-Content -LiteralPath $PacketPath -Raw|ConvertFrom-Json -Depth 100
  if($packet.schema_version -cne 'mnf-phase08-mutation-authorization-packet/1' -or $packet.release_ref -cne 'refs/tags/modules-v0.1.0-r7' -or
      $packet.boundary_sha -cne $BoundarySha -or $packet.packet_sha256 -cnotmatch '^[0-9a-f]{64}$' -or
      $packet.packet_sha256 -cne (Get-P08SelfExcludingDigest $packet 'packet_sha256')){
    Throw-P08HostedRule 'P08-RECEIPT-PACKET' 'Authorization packet is not the exact digest-bound r7 packet.'
  }
  $receipt=New-ReleaseAuthorizationReceipt -BoundarySha $BoundarySha -SourceSha $BoundarySha -PacketSha256 ([string]$packet.packet_sha256) -CreatedAt $CreatedAt
  Write-P08ExclusiveJson -Path $ReceiptPath -Value $receipt
  $reload=Get-Content -LiteralPath $ReceiptPath -Raw|ConvertFrom-Json -Depth 30
  $null=Assert-ReleaseAuthorizationReceipt -Receipt $reload -ExpectedBoundarySha $BoundarySha -ExpectedPacketSha256 ([string]$packet.packet_sha256)
  $reload
}

function Write-P08ActiveAttempt {
  param(
    [Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][object]$Bindings,
    [Parameter(Mandatory)][ValidateSet('mutation_authorized','exact_existing')][string]$AuthorityVariant,
    [Parameter(Mandatory)][object]$UpdatedAt
  )
  $root=[IO.Path]::GetFullPath([string]$Bindings.execution_root)
  $pathFields=@('boundary_locator_path','artifact_index_path','attempt_zero_history_path','r1_history_path','r2_history_path','r3_history_path','r4_history_path','r5_history_path','r6_history_path')
  foreach($name in $pathFields){$null=Test-P08SafePath ([string]$Bindings.$name) $root;if(-not(Test-Path -LiteralPath ([string]$Bindings.$name) -PathType Leaf)){Throw-P08HostedRule 'P08-ACTIVE-FILE' "Active attempt file '$name' is missing."}}
  $packet=$Bindings.mutation_authorization_packet_path;$receipt=$Bindings.authorization_receipt_path;$exact=$Bindings.exact_existing_authority_path
  if($AuthorityVariant -ceq 'mutation_authorized'){
    if([string]::IsNullOrWhiteSpace([string]$packet)-or[string]::IsNullOrWhiteSpace([string]$receipt)-or$null-ne$exact){Throw-P08HostedRule 'P08-ACTIVE-BRANCH' 'Mutation active attempt requires packet+receipt and forbids exact-existing.'}
  }elseif($null-ne$packet-or$null-ne$receipt-or[string]::IsNullOrWhiteSpace([string]$exact)){Throw-P08HostedRule 'P08-ACTIVE-BRANCH' 'Exact active attempt forbids packet/receipt and requires exact authority.'}
  foreach($candidate in @($packet,$receipt,$exact)|Where-Object{$null-ne$_}){$null=Test-P08SafePath ([string]$candidate) $root;if(-not(Test-Path -LiteralPath ([string]$candidate) -PathType Leaf)){Throw-P08HostedRule 'P08-ACTIVE-FILE' 'Authority file is missing.'}}
  $value=[pscustomobject][ordered]@{
    schema_version='mnf-phase08-active-attempt/1';release_ref='refs/tags/modules-v0.1.0-r7';boundary_sha=[string]$Bindings.boundary_sha;execution_root=$root
    boundary_locator_path=[IO.Path]::GetFullPath([string]$Bindings.boundary_locator_path);boundary_locator_sha256=Get-P08Sha256 ([string]$Bindings.boundary_locator_path)
    artifact_root=[IO.Path]::GetFullPath([string]$Bindings.artifact_root);artifact_index_path=[IO.Path]::GetFullPath([string]$Bindings.artifact_index_path);artifact_index_sha256=Get-P08Sha256 ([string]$Bindings.artifact_index_path)
    attempt_zero_history_path=[IO.Path]::GetFullPath([string]$Bindings.attempt_zero_history_path);attempt_zero_history_sha256=Get-P08Sha256 ([string]$Bindings.attempt_zero_history_path)
    r1_history_path=[IO.Path]::GetFullPath([string]$Bindings.r1_history_path);r1_history_sha256=Get-P08Sha256 ([string]$Bindings.r1_history_path)
    r2_history_path=[IO.Path]::GetFullPath([string]$Bindings.r2_history_path);r2_history_sha256=Get-P08Sha256 ([string]$Bindings.r2_history_path)
    r3_history_path=[IO.Path]::GetFullPath([string]$Bindings.r3_history_path);r3_history_sha256=Get-P08Sha256 ([string]$Bindings.r3_history_path)
    r4_history_path=[IO.Path]::GetFullPath([string]$Bindings.r4_history_path);r4_history_sha256=Get-P08Sha256 ([string]$Bindings.r4_history_path)
    r5_history_path=[IO.Path]::GetFullPath([string]$Bindings.r5_history_path);r5_history_sha256=Get-P08Sha256 ([string]$Bindings.r5_history_path)
    r6_history_path=[IO.Path]::GetFullPath([string]$Bindings.r6_history_path);r6_history_sha256=Get-P08Sha256 ([string]$Bindings.r6_history_path)
    historical_history_set_sha256=[string]$Bindings.historical_history_set_sha256
    authority_variant=$AuthorityVariant
    mutation_authorization_packet_path=if($null-eq$packet){$null}else{[IO.Path]::GetFullPath([string]$packet)};mutation_authorization_packet_sha256=if($null-eq$packet){$null}else{Get-P08Sha256 ([string]$packet)}
    authorization_receipt_path=if($null-eq$receipt){$null}else{[IO.Path]::GetFullPath([string]$receipt)};authorization_receipt_sha256=if($null-eq$receipt){$null}else{Get-P08Sha256 ([string]$receipt)}
    exact_existing_authority_path=if($null-eq$exact){$null}else{[IO.Path]::GetFullPath([string]$exact)};exact_existing_authority_sha256=if($null-eq$exact){$null}else{Get-P08Sha256 ([string]$exact)}
    updated_at_utc=ConvertTo-ReleaseCanonicalUtc $UpdatedAt;active_attempt_sha256=''
  }
  $value.active_attempt_sha256=Get-P08ObjectDigest (Get-P08ActiveAttemptProjection $value)
  Write-P08ExclusiveJson -Path $Path -Value $value
  $value
}

function Open-P08ActiveAttempt([Parameter(Mandatory)][string]$Path) {
  $value=Get-Content -LiteralPath $Path -Raw|ConvertFrom-Json -Depth 50
  $names=@('schema_version','release_ref','boundary_sha','execution_root','boundary_locator_path','boundary_locator_sha256','artifact_root','artifact_index_path','artifact_index_sha256','attempt_zero_history_path','attempt_zero_history_sha256','r1_history_path','r1_history_sha256','r2_history_path','r2_history_sha256','r3_history_path','r3_history_sha256','r4_history_path','r4_history_sha256','r5_history_path','r5_history_sha256','r6_history_path','r6_history_sha256','historical_history_set_sha256','authority_variant','mutation_authorization_packet_path','mutation_authorization_packet_sha256','authorization_receipt_path','authorization_receipt_sha256','exact_existing_authority_path','exact_existing_authority_sha256','updated_at_utc','active_attempt_sha256')
  if((@($value.PSObject.Properties.Name)-join ',')-cne($names-join ',')-or$value.schema_version-cne'mnf-phase08-active-attempt/1'-or$value.release_ref-cne'refs/tags/modules-v0.1.0-r7'){Throw-P08HostedRule 'P08-ACTIVE-CLOSED' 'Active attempt shape drifted.'}
  $history=Get-ReleaseInitialHistoryBinding
  if($value.attempt_zero_history_sha256-cne$history.historical_attempt_zero_sha256-or$value.r1_history_sha256-cne$history.historical_r1_sha256-or$value.r2_history_sha256-cne$history.historical_r2_sha256-or$value.r3_history_sha256-cne$history.historical_r3_sha256-or$value.r4_history_sha256-cne$history.historical_r4_sha256-or$value.r5_history_sha256-cne$history.historical_r5_sha256-or$value.r6_history_sha256-cne$history.historical_r6_sha256-or$value.historical_history_set_sha256-cne$history.historical_history_set_sha256){Throw-P08HostedRule 'P08-ACTIVE-DIGEST' 'Active attempt history family drifted.'}
  $expectedActiveDigest=Get-P08ObjectDigest (Get-P08ActiveAttemptProjection $value)
  $canonicalActiveUtc=ConvertTo-ReleaseCanonicalUtc $value.updated_at_utc
  if($value.updated_at_utc -is [string] -and [string]$value.updated_at_utc -cne $canonicalActiveUtc){Throw-P08HostedRule 'P08-ACTIVE-DIGEST' 'Active attempt UTC is not canonical Z.'}
  if([string]$value.active_attempt_sha256 -cne $expectedActiveDigest){Throw-P08HostedRule 'P08-ACTIVE-DIGEST' 'Active attempt digest drifted.'}
  foreach($pair in @(@('boundary_locator_path','boundary_locator_sha256'),@('artifact_index_path','artifact_index_sha256'),@('attempt_zero_history_path','attempt_zero_history_sha256'),@('r1_history_path','r1_history_sha256'),@('r2_history_path','r2_history_sha256'),@('r3_history_path','r3_history_sha256'),@('r4_history_path','r4_history_sha256'),@('r5_history_path','r5_history_sha256'),@('r6_history_path','r6_history_sha256'),@('mutation_authorization_packet_path','mutation_authorization_packet_sha256'),@('authorization_receipt_path','authorization_receipt_sha256'),@('exact_existing_authority_path','exact_existing_authority_sha256'))){
    $p=$value.($pair[0]);$d=$value.($pair[1]);if($null-eq$p){if($null-ne$d){Throw-P08HostedRule 'P08-ACTIVE-DIGEST' 'Null active path has a digest.'};continue};$null=Test-P08SafePath ([string]$p) ([string]$value.execution_root);if((Get-P08Sha256 ([string]$p))-cne[string]$d){Throw-P08HostedRule 'P08-ACTIVE-DIGEST' "Active digest drifted for $($pair[0])."}
  }
  $value
}

function Write-P08HostedHandoff {
  param([Parameter(Mandatory)][string]$ActiveAttemptPath,[Parameter(Mandatory)][string]$HandoffPath,[Parameter(Mandatory)][object]$CreatedAt)
  $active=Open-P08ActiveAttempt $ActiveAttemptPath
  $bindings=[ordered]@{
    schema_version='mnf-phase08-handoff/1';release_ref=$active.release_ref;boundary_sha=$active.boundary_sha;execution_root=$active.execution_root
    boundary_locator_path=$active.boundary_locator_path;boundary_locator_sha256=$active.boundary_locator_sha256
    active_attempt_path=[IO.Path]::GetFullPath($ActiveAttemptPath);active_attempt_sha256=Get-P08Sha256 $ActiveAttemptPath
    artifact_root=$active.artifact_root;artifact_index_path=$active.artifact_index_path;artifact_index_sha256=$active.artifact_index_sha256
    attempt_zero_history_path=$active.attempt_zero_history_path;attempt_zero_history_sha256=$active.attempt_zero_history_sha256
    r1_history_path=$active.r1_history_path;r1_history_sha256=$active.r1_history_sha256
    r2_history_path=$active.r2_history_path;r2_history_sha256=$active.r2_history_sha256;r3_history_path=$active.r3_history_path;r3_history_sha256=$active.r3_history_sha256;r4_history_path=$active.r4_history_path;r4_history_sha256=$active.r4_history_sha256;r5_history_path=$active.r5_history_path;r5_history_sha256=$active.r5_history_sha256;r6_history_path=$active.r6_history_path;r6_history_sha256=$active.r6_history_sha256;historical_history_set_sha256=$active.historical_history_set_sha256
    mutation_authorization_packet_path=$active.mutation_authorization_packet_path;mutation_authorization_packet_sha256=$active.mutation_authorization_packet_sha256
    authorization_receipt_path=$active.authorization_receipt_path;authorization_receipt_sha256=$active.authorization_receipt_sha256
    exact_existing_authority_path=$active.exact_existing_authority_path;exact_existing_authority_sha256=$active.exact_existing_authority_sha256
  }
  $handoff=New-ReleasePhase08Handoff -Bindings $bindings -AuthorityVariant ([string]$active.authority_variant) -CreatedAt $CreatedAt
  Write-P08ExclusiveJson -Path $HandoffPath -Value $handoff
  $reload=Get-Content -LiteralPath $HandoffPath -Raw|ConvertFrom-Json -Depth 50;$null=Assert-ReleasePhase08Handoff $reload;$reload
}

function Test-P08SafePath([string]$Path,[string]$Root,[switch]$AllowRoot) {
  $full=[IO.Path]::GetFullPath($Path); $rootFull=[IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
  if (($AllowRoot -and $full -ceq $rootFull) -or $full.StartsWith($rootFull + [IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)) { return $full }
  Throw-P08HostedRule 'P08-STORE-ESCAPE' "Path '$full' escapes '$rootFull'."
}

function Write-P08ExclusiveJson([string]$Path,[object]$Value) {
  if (Test-Path -LiteralPath $Path) { Throw-P08HostedRule 'P08-STORE-COLLISION' "Immutable path '$Path' already exists." }
  $parent=Split-Path -Parent $Path; $null=New-Item -ItemType Directory -Force $parent
  $temp=Join-Path $parent ('.' + [IO.Path]::GetFileName($Path) + '.' + [Guid]::NewGuid().ToString('N') + '.tmp')
  try {
    [IO.File]::WriteAllText($temp,(Get-P08CanonicalJson $Value),[Text.UTF8Encoding]::new($false))
    [IO.File]::Move($temp,$Path,$false)
  } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
}

function Write-P08ReplaceJson([string]$Path,[object]$Value) {
  $parent=Split-Path -Parent $Path; $null=New-Item -ItemType Directory -Force $parent
  $temp=Join-Path $parent ('.' + [IO.Path]::GetFileName($Path) + '.' + [Guid]::NewGuid().ToString('N') + '.tmp')
  try {
    [IO.File]::WriteAllText($temp,(Get-P08CanonicalJson $Value),[Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temp -Destination $Path -Force
  } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
}

function Get-P08ExpectedStore([string]$RootIntent) {
  $base=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08'))
  [pscustomobject][ordered]@{
    locator=[IO.Path]::GetFullPath((Join-Path $base 'phase-08-live-locator.json'))
    root=[IO.Path]::GetFullPath((Join-Path $base "artifacts/$RootIntent"))
    index=[IO.Path]::GetFullPath((Join-Path $base "artifacts/$RootIntent/index.json"))
  }
}

function Get-P08LocatorProjection([object]$Locator) {
  [pscustomobject][ordered]@{
    schema_version=[string]$Locator.schema_version; artifact_root=[string]$Locator.artifact_root; index_path=[string]$Locator.index_path
    repository=[string]$Locator.repository; workflow=[string]$Locator.workflow; release_ref=[string]$Locator.release_ref
    source_sha=[string]$Locator.source_sha; root_intent_sha256=[string]$Locator.root_intent_sha256; intent_sha256=[string]$Locator.intent_sha256
    authorization_packet_path=$Locator.authorization_packet_path; authorization_packet_sha256=$Locator.authorization_packet_sha256
    created_at_utc=[string]$Locator.created_at_utc
  }
}

function Assert-P08NoLinks([string]$Root) {
  $rootItem=Get-Item -LiteralPath $Root -Force
  if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Throw-P08HostedRule 'P08-STORE-LINK' 'Artifact root is a link.' }
  foreach($item in @(Get-ChildItem -LiteralPath $Root -Recurse -Force)) {
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Throw-P08HostedRule 'P08-STORE-LINK' "Linked evidence path '$($item.FullName)' is forbidden." }
  }
}

function Open-P08ArtifactStore {
  param([string]$Locator,[string]$Root,[string]$Repo,[string]$WorkflowPath,[string]$Ref,[string]$Sha,[string]$RootIntent,[string]$CurrentIntent)
  $expected=Get-P08ExpectedStore $RootIntent
  $locatorFull=[IO.Path]::GetFullPath($Locator); $rootFull=[IO.Path]::GetFullPath($Root)
  if ($locatorFull -cne $expected.locator -or $rootFull -cne $expected.root) { Throw-P08HostedRule 'P08-STORE-PATH' 'Explicit locator/root do not equal deterministic paths.' }
  if ($Repo -cne 'tchivs/moonbit-foundation' -or $WorkflowPath -cne 'publish-modules.yml' -or $Ref -cne 'refs/tags/modules-v0.1.0' -or $Sha -notmatch '^[0-9a-f]{40}$' -or $RootIntent -notmatch '^[0-9a-f]{64}$' -or $CurrentIntent -notmatch '^[0-9a-f]{64}$') { Throw-P08HostedRule 'P08-STORE-BINDING' 'Repository/workflow/tag/SHA/intent binding is invalid.' }
  if (-not (Test-Path -LiteralPath $locatorFull)) {
    foreach($directory in @($rootFull,(Join-Path $rootFull 'runs'),(Join-Path $rootFull 'observations'),(Join-Path $rootFull 'authorization'))) {
      if (Test-Path -LiteralPath $directory) { Throw-P08HostedRule 'P08-STORE-PARTIAL' 'Store exists without its locator.' }
      $null=New-Item -ItemType Directory -Path $directory
    }
    $index=[pscustomobject][ordered]@{ schema_version='mnf-phase08-live-index/1'; root_intent_sha256=$RootIntent; records=@() }
    Write-P08ExclusiveJson $expected.index $index
    $locatorValue=[pscustomobject][ordered]@{
      schema_version='mnf-phase08-live-locator/1'; artifact_root=$rootFull; index_path=$expected.index; repository=$Repo; workflow=$WorkflowPath
      release_ref=$Ref; source_sha=$Sha; root_intent_sha256=$RootIntent; intent_sha256=$CurrentIntent
      authorization_packet_path=$null; authorization_packet_sha256=$null; created_at_utc=[DateTime]::UtcNow.ToString('o'); locator_sha256=''
    }
    $locatorValue.locator_sha256=Get-P08ObjectDigest (Get-P08LocatorProjection $locatorValue)
    Write-P08ExclusiveJson $locatorFull $locatorValue
  }
  $locatorValue=Get-Content -LiteralPath $locatorFull -Raw | ConvertFrom-Json -Depth 100
  $expectedNames=@('schema_version','artifact_root','index_path','repository','workflow','release_ref','source_sha','root_intent_sha256','intent_sha256','authorization_packet_path','authorization_packet_sha256','created_at_utc','locator_sha256')
  if ((@($locatorValue.PSObject.Properties.Name) -join ',') -cne ($expectedNames -join ',')) { Throw-P08HostedRule 'P08-STORE-LOCATOR-CLOSED' 'Locator fields drifted.' }
  if ($locatorValue.schema_version -cne 'mnf-phase08-live-locator/1' -or [IO.Path]::GetFullPath([string]$locatorValue.artifact_root) -cne $rootFull -or [IO.Path]::GetFullPath([string]$locatorValue.index_path) -cne $expected.index -or $locatorValue.repository -cne $Repo -or $locatorValue.workflow -cne $WorkflowPath -or $locatorValue.release_ref -cne $Ref -or $locatorValue.source_sha -cne $Sha -or $locatorValue.root_intent_sha256 -cne $RootIntent -or $locatorValue.intent_sha256 -cne $CurrentIntent) { Throw-P08HostedRule 'P08-STORE-LOCATOR-BINDING' 'Locator binding drifted.' }
  if ($locatorValue.locator_sha256 -cne (Get-P08ObjectDigest (Get-P08LocatorProjection $locatorValue))) { Throw-P08HostedRule 'P08-STORE-LOCATOR-DIGEST' 'Locator digest drifted.' }
  Assert-P08NoLinks $rootFull
  $index=Get-Content -LiteralPath $expected.index -Raw | ConvertFrom-Json -Depth 100
  if ((@($index.PSObject.Properties.Name) -join ',') -cne 'schema_version,root_intent_sha256,records' -or $index.schema_version -cne 'mnf-phase08-live-index/1' -or $index.root_intent_sha256 -cne $RootIntent) { Throw-P08HostedRule 'P08-STORE-INDEX' 'Index binding drifted.' }
  $seen=@{}; $logicalSeen=@{}; foreach($record in @($index.records)) {
    if ((@($record.PSObject.Properties.Name) -join ',') -cne 'logical_key,kind,run_id,run_attempt,artifact_name,path,sha256') { Throw-P08HostedRule 'P08-STORE-RECORD-CLOSED' 'Index record fields drifted.' }
    $relative=[string]$record.path; if ($seen.ContainsKey($relative)) { Throw-P08HostedRule 'P08-STORE-DUPLICATE' "Duplicate indexed path '$relative'." }; $seen[$relative]=$true
    $logical=[string]$record.logical_key; if ([string]::IsNullOrWhiteSpace($logical) -or $logicalSeen.ContainsKey($logical)) { Throw-P08HostedRule 'P08-STORE-DUPLICATE' "Duplicate indexed logical evidence '$logical'." }; $logicalSeen[$logical]=$true
    $absolute=Test-P08SafePath (Join-Path $rootFull $relative) $rootFull
    if ((Get-P08Sha256 $absolute) -cne [string]$record.sha256) { Throw-P08HostedRule 'P08-STORE-INDEX-DIGEST' "Indexed digest drifted for '$relative'." }
  }
  $actual=@(Get-ChildItem -LiteralPath $rootFull -Recurse -File | Where-Object FullName -cne $expected.index | ForEach-Object { [IO.Path]::GetRelativePath($rootFull,$_.FullName).Replace('\','/') })
  foreach($relative in $actual) { if (-not $seen.ContainsKey($relative)) { Throw-P08HostedRule 'P08-STORE-UNINDEXED' "Unindexed evidence '$relative'." } }
  [pscustomobject]@{ locator=$locatorValue; index=$index; paths=$expected }
}

function Assert-P08NoSecretShape([object]$Value) {
  $json=Get-P08CanonicalJson $Value
  foreach($pattern in @('(?i)gh[opusr]_[A-Za-z0-9_]{12,}','(?i)bearer\s+[A-Za-z0-9._-]+','(?i)MOONCAKES_TOKEN','(?i)credentials[.]json','(?i)authorization\s*:','(?i)token\s*[:=]')) {
    if ($json -match $pattern) { Throw-P08HostedRule 'P08-HOSTED-SECRET-SHAPE' 'Sanitized evidence contains a forbidden secret-shaped value.' }
  }
}

function Assert-P08HostedEvidence {
  param([ValidateSet('PublisherDryRun','HostedPreflight')][string]$Operation,[object]$Evidence,[object]$Run,[object]$Store,[string]$PreparedDigest,[string]$Module)
  Assert-P08NoSecretShape $Evidence
  $common=@('schema_version','mode','repository','workflow','run_id','run_attempt','release_ref','source_sha','root_intent_sha256','intent_sha256','prepared_manifest_sha256','target_module')
  foreach($name in $common) { if ($null -eq $Evidence.PSObject.Properties[$name]) { Throw-P08HostedRule 'P08-HOSTED-EVIDENCE-CLOSED' "Missing evidence field '$name'." } }
  if ([string]$Evidence.mode -cne $Operation -or [string]$Evidence.repository -cne [string]$Store.locator.repository -or
      [string]$Evidence.workflow -cne [string]$Store.locator.workflow -or [string]$Evidence.run_id -cne [string]$Run.databaseId -or
      [int]$Evidence.run_attempt -ne [int]$Run.attempt -or [string]$Evidence.release_ref -cne [string]$Store.locator.release_ref -or
      [string]$Evidence.source_sha -cne [string]$Store.locator.source_sha -or [string]$Evidence.root_intent_sha256 -cne [string]$Store.locator.root_intent_sha256 -or
      [string]$Evidence.intent_sha256 -cne [string]$Store.locator.intent_sha256 -or [string]$Evidence.prepared_manifest_sha256 -cne $PreparedDigest -or
      [string]$Evidence.target_module -cne $Module) { Throw-P08HostedRule 'P08-HOSTED-EVIDENCE-BINDING' 'Sanitized evidence does not bind the exact run and release inputs.' }
  foreach($field in @('started_at_utc','completed_at_utc')) {
    if ($null -eq $Evidence.PSObject.Properties[$field]) { Throw-P08HostedRule 'P08-HOSTED-EVIDENCE-STALE' "Missing '$field'." }
    try { $time=[DateTimeOffset]::Parse([string]$Evidence.$field) } catch { Throw-P08HostedRule 'P08-HOSTED-EVIDENCE-STALE' "Invalid '$field'." }
    if ($time -lt [DateTimeOffset]::UtcNow.AddHours(-6) -or $time -gt [DateTimeOffset]::UtcNow.AddMinutes(5)) { Throw-P08HostedRule 'P08-HOSTED-EVIDENCE-STALE' "Stale '$field'." }
  }
  if ($Operation -ceq 'PublisherDryRun') {
    if ([string]$Evidence.schema_version -cne 'mnf-publisher-dry-run/1' -or [string]$Evidence.command_classification -cne 'moon_publish_frozen_dry_run' -or
        [string]$Evidence.observed_actor -cne 'tchivs' -or [string]$Evidence.actor_check_classification -cne 'moon_whoami_exact' -or
        [int]$Evidence.actor_stdout_line_count -ne 1 -or $Evidence.actor_stderr_empty -ne $true -or
        [int]$Evidence.exit_code -ne 0 -or $Evidence.mutation_performed -ne $false -or $Evidence.credential_state_removed -ne $true -or
        $Evidence.raw_output_persisted -ne $false -or [string]$Evidence.module_identity -cne 'tchivs/mb-core@0.1.0' -or
        [string]$Evidence.module_manifest_sha256 -notmatch '^[0-9a-f]{64}$' -or [string]$Evidence.archive_sha256 -notmatch '^[0-9a-f]{64}$') { Throw-P08HostedRule 'P08-HOSTED-DRYRUN-EVIDENCE' 'PublisherDryRun evidence is incomplete or mutation-indicating.' }
  } else {
    if ([string]$Evidence.schema_version -cne 'mnf-hosted-preflight/1' -or $Evidence.native_runtime_verified -ne $true -or $Evidence.compile_only -ne $false -or
        [int]$Evidence.exit_code -ne 0 -or $Evidence.sentinel_match -ne $true -or
        [string]$Evidence.expected_sentinel_sha256 -notmatch '^[0-9a-f]{64}$' -or [string]$Evidence.observed_sentinel_sha256 -cne [string]$Evidence.expected_sentinel_sha256 -or
        [string]::IsNullOrWhiteSpace([string]$Evidence.toolchain_identity) -or [string]::IsNullOrWhiteSpace([string]$Evidence.linker_identity) -or
        [string]::IsNullOrWhiteSpace([string]$Evidence.runtime_identity) -or $Evidence.raw_output_persisted -ne $false) { Throw-P08HostedRule 'P08-HOSTED-PREFLIGHT-EVIDENCE' 'HostedPreflight evidence is incomplete, compile-only, or drifted.' }
  }
}

function Add-P08ArtifactRecord {
  param([object]$Store,[string]$Kind,[string]$RunId,[int]$RunAttempt,[string]$ArtifactName,[string]$SourcePath)
  $safeName=($ArtifactName -replace '[^A-Za-z0-9._-]','_'); $relative="runs/$Kind-$RunId-$RunAttempt-$safeName.json"
  $destination=Test-P08SafePath (Join-Path $Store.paths.root $relative) $Store.paths.root
  $digest=Get-P08Sha256 $SourcePath
  $logical="$Kind|$RunId|$RunAttempt|$ArtifactName"
  $matches=@($Store.index.records | Where-Object { $_.logical_key -ceq $logical })
  if ($matches.Count -gt 1) { Throw-P08HostedRule 'P08-STORE-DUPLICATE' "Ambiguous logical evidence '$logical'." }
  if ($matches.Count -eq 1) {
    if ($matches[0].path -cne $relative -or $matches[0].sha256 -cne $digest -or (Get-P08Sha256 $destination) -cne $digest) { Throw-P08HostedRule 'P08-STORE-RESUME-DRIFT' "Immutable evidence '$logical' changed." }
    return $matches[0]
  }
  $bytes=[IO.File]::ReadAllBytes($SourcePath); $parent=Split-Path -Parent $destination; $null=New-Item -ItemType Directory -Force $parent
  $temp=Join-Path $parent ('.' + [IO.Path]::GetFileName($destination) + '.' + [Guid]::NewGuid().ToString('N') + '.tmp')
  try { [IO.File]::WriteAllBytes($temp,$bytes); [IO.File]::Move($temp,$destination,$false) } finally { if(Test-Path $temp){Remove-Item $temp -Force} }
  $record=[pscustomobject][ordered]@{ logical_key=$logical; kind=$Kind; run_id=$RunId; run_attempt=$RunAttempt; artifact_name=$ArtifactName; path=$relative; sha256=$digest }
  $records=@($Store.index.records)+@($record); $Store.index=[pscustomobject][ordered]@{ schema_version='mnf-phase08-live-index/1'; root_intent_sha256=[string]$Store.index.root_intent_sha256; records=$records }
  Write-P08ReplaceJson $Store.paths.index $Store.index
  $record
}

function Add-P08DerivedEvidenceRecord {
  param([object]$Store,[string]$Kind,[string]$LogicalKey,[string]$RelativePath,[string]$SourcePath,[string]$RunId='derived',[int]$RunAttempt=0,[string]$ArtifactName)
  if ($RelativePath -notmatch '^(observations|authorization)/[A-Za-z0-9._/-]+[.]json$') { Throw-P08HostedRule 'P08-STORE-DERIVED-PATH' 'Derived evidence path is not allowlisted.' }
  $destination=Test-P08SafePath (Join-Path $Store.paths.root $RelativePath) $Store.paths.root
  $digest=Get-P08Sha256 $SourcePath
  $matches=@($Store.index.records | Where-Object { $_.logical_key -ceq $LogicalKey })
  if ($matches.Count -gt 1) { Throw-P08HostedRule 'P08-STORE-DUPLICATE' "Ambiguous logical evidence '$LogicalKey'." }
  if ($matches.Count -eq 1) {
    if ($matches[0].path -cne $RelativePath -or $matches[0].sha256 -cne $digest -or (Get-P08Sha256 $destination) -cne $digest) { Throw-P08HostedRule 'P08-STORE-RESUME-DRIFT' "Immutable evidence '$LogicalKey' changed." }
    return $matches[0]
  }
  if (Test-Path -LiteralPath $destination) { Throw-P08HostedRule 'P08-STORE-COLLISION' "Unindexed destination '$RelativePath' exists." }
  $parent=Split-Path -Parent $destination; $null=New-Item -ItemType Directory -Force $parent
  $temp=Join-Path $parent ('.' + [IO.Path]::GetFileName($destination) + '.' + [Guid]::NewGuid().ToString('N') + '.tmp')
  try { [IO.File]::WriteAllBytes($temp,[IO.File]::ReadAllBytes($SourcePath)); [IO.File]::Move($temp,$destination,$false) } finally { if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Force} }
  $record=[pscustomobject][ordered]@{logical_key=$LogicalKey;kind=$Kind;run_id=$RunId;run_attempt=$RunAttempt;artifact_name=$ArtifactName;path=$RelativePath;sha256=$digest}
  $Store.index=[pscustomobject][ordered]@{schema_version='mnf-phase08-live-index/1';root_intent_sha256=[string]$Store.index.root_intent_sha256;records=@($Store.index.records)+@($record)}
  Write-P08ReplaceJson $Store.paths.index $Store.index
  $record
}

function New-P08AuthorizationPacket {
  param([object]$Store,[string]$PreparedDigest,[object]$DryRunRecord,[object]$DryRunEvidence,[object]$AbsenceRecord,[object]$AbsenceEvidence,[object]$PreflightRecord,[object]$PreflightEvidence,[object]$GateDigests)
  if ($Store.locator.authorization_packet_path -or $Store.locator.authorization_packet_sha256) { Throw-P08HostedRule 'P08-PACKET-ALREADY-BOUND' 'Authorization packet is already bound.' }
  if ([string]$AbsenceEvidence.outcome -cne 'absent' -or $AbsenceEvidence.mutation_authorized -ne $false -or [string]$AbsenceEvidence.identity -cne 'tchivs/mb-core' -or [string]$AbsenceEvidence.version -cne '0.1.0') { Throw-P08HostedRule 'P08-PACKET-ABSENCE' 'Fresh exact core absence is required.' }
  $dryProjection=[ordered]@{};foreach($p in $DryRunEvidence.PSObject.Properties){$dryProjection[$p.Name]=$p.Value};$dryProjection.path=[string]$DryRunRecord.path;$dryProjection.sha256=[string]$DryRunRecord.sha256;$dryProjection.artifact_name=[string]$DryRunRecord.artifact_name
  $nativeProjection=[ordered]@{};foreach($p in $PreflightEvidence.PSObject.Properties){$nativeProjection[$p.Name]=$p.Value};$nativeProjection.path=[string]$PreflightRecord.path;$nativeProjection.sha256=[string]$PreflightRecord.sha256;$nativeProjection.artifact_name=[string]$PreflightRecord.artifact_name
  $absenceProjection=[ordered]@{outcome='absent';mutation_authorized=$false;identity='tchivs/mb-core@0.1.0';observed_at_utc=[string]$AbsenceEvidence.completed_at_utc;path=[string]$AbsenceRecord.path;sha256=[string]$AbsenceRecord.sha256}
  $packet=[ordered]@{
    schema_version='mnf-phase08-authorization-packet/1';repository=[string]$Store.locator.repository;workflow=[string]$Store.locator.workflow
    release_ref=[string]$Store.locator.release_ref;source_sha=[string]$Store.locator.source_sha;root_intent_sha256=[string]$Store.locator.root_intent_sha256
    intent_sha256=[string]$Store.locator.intent_sha256;prepared_manifest_sha256=$PreparedDigest;target_module='mb-core'
    publisher_dry_run=[pscustomobject]$dryProjection;fresh_absence=[pscustomobject]$absenceProjection;hosted_preflight=[pscustomobject]$nativeProjection
    gate_digests=$GateDigests;created_at_utc=[DateTime]::UtcNow.ToString('o');packet_sha256=''
  }
  $projection=[ordered]@{};foreach($entry in $packet.GetEnumerator()){if($entry.Key -cne 'packet_sha256'){$projection[$entry.Key]=$entry.Value}}
  $packet.packet_sha256=Get-P08ObjectDigest ([pscustomobject]$projection)
  $temporary=Join-Path ([IO.Path]::GetTempPath()) ('mnf-p08-packet-'+[Guid]::NewGuid().ToString('N')+'.json')
  try {
    [IO.File]::WriteAllText($temporary,(Get-P08CanonicalJson ([pscustomobject]$packet)),[Text.UTF8Encoding]::new($false))
    $record=Add-P08DerivedEvidenceRecord -Store $Store -Kind 'authorization-packet' -LogicalKey 'authorization|authorize-core' -RelativePath 'authorization/authorize-core.json' -SourcePath $temporary -ArtifactName 'authorize-core.json'
  } finally { if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force} }
  $locatorProjection=Get-P08LocatorProjection $Store.locator
  $Store.locator.authorization_packet_path=[string]$record.path;$Store.locator.authorization_packet_sha256=[string]$record.sha256
  $Store.locator.locator_sha256=Get-P08ObjectDigest (Get-P08LocatorProjection $Store.locator)
  Write-P08ReplaceJson $Store.paths.locator $Store.locator
  [pscustomobject]@{packet_path=(Join-Path $Store.paths.root $record.path);packet_sha256=[string]$packet.packet_sha256;file_sha256=[string]$record.sha256;record=$record}
}

function Invoke-P08Git {
  param([string]$Root,[string[]]$Arguments)
  if ($null -ne $script:GitCommand) { return @(& $script:GitCommand $Root $Arguments) }
  $result=@(& git -C $Root @Arguments 2>&1)
  if ($LASTEXITCODE -ne 0) { Throw-P08HostedRule 'P08-BOUNDARY-GIT' "git $($Arguments -join ' ') failed." }
  return $result
}

function Get-P08ModeScriptInventory([string]$Operation) {
  $common=@('scripts/quality/Invoke-Phase08HostedRun.ps1','scripts/quality/Test-Phase08Qualification.ps1','scripts/quality/ReleaseQualification.Common.ps1')
  switch ($Operation) {
    'PrepareAttempt' { return $common + @(
      'scripts/quality/Invoke-ReleaseQualification.ps1','scripts/quality/New-ReleaseIntent.ps1',
      'scripts/quality/New-PreparedReleaseBundle.ps1','scripts/quality/ReleasePublisher.Common.ps1',
      'policy/release-control.json','release/journal/record-schema.json'
    ) }
    'HostedPreflight' { return $common + @('.github/workflows/publish-modules.yml') }
    'PublisherDryRun' { return $common + @('.github/workflows/publish-modules.yml','scripts/quality/Invoke-ReleasePublisher.ps1') }
    'MaterializePublicSurface' { return $common + @('scripts/quality/Get-MooncakesObservation.ps1','policy/phase-08-distribution.json') }
    'ObserveOnly' { return $common + @('scripts/quality/Get-MooncakesObservation.ps1','scripts/quality/Invoke-ColdRegistryConsumer.ps1') }
    'PublishOne' { return $common + @('.github/workflows/publish-modules.yml','scripts/quality/Invoke-ReleasePublisher.ps1','scripts/quality/Invoke-MooncakesLiveMutation.ps1') }
    default { return $common }
  }
}

function Assert-P08ExecutionBoundary {
  param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][string]$Boundary,[string[]]$RelativePaths=@())
  $rootFull=[IO.Path]::GetFullPath($Root)
  if (-not (Test-Path -LiteralPath $rootFull -PathType Container)) { Throw-P08HostedRule 'P08-BOUNDARY-ROOT' 'Execution root is missing.' }
  if ($Boundary -cnotmatch '^[0-9a-f]{40}$') { Throw-P08HostedRule 'P08-BOUNDARY-SHA' 'Boundary SHA is invalid.' }
  $status=((Invoke-P08Git $rootFull @('status','--porcelain=v1','--untracked-files=all')) -join "`n").Trim()
  if (-not [string]::IsNullOrEmpty($status)) { Throw-P08HostedRule 'P08-BOUNDARY-DIRTY' 'Execution root is not clean.' }
  $head=((Invoke-P08Git $rootFull @('rev-parse','HEAD')) -join '').Trim()
  if ($head -cne $Boundary) { Throw-P08HostedRule 'P08-BOUNDARY-HEAD' 'Execution root HEAD differs from the durable boundary.' }
  foreach($relative in @($RelativePaths | Sort-Object -Unique)) {
    if ([IO.Path]::IsPathRooted($relative) -or $relative -match '(^|/)[.][.](/|$)') { Throw-P08HostedRule 'P08-BOUNDARY-PATH' "Invalid boundary path '$relative'." }
    $absolute=Test-P08SafePath (Join-Path $rootFull $relative) $rootFull
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) { Throw-P08HostedRule 'P08-BOUNDARY-FILE' "Boundary file '$relative' is missing." }
    $expected=((Invoke-P08Git $rootFull @('rev-parse',"$Boundary`:$relative")) -join '').Trim()
    $actual=((Invoke-P08Git $rootFull @('hash-object','--',$absolute)) -join '').Trim()
    if ($expected -cnotmatch '^[0-9a-f]{40}$' -or $actual -cne $expected) { Throw-P08HostedRule 'P08-BOUNDARY-BLOB' "Boundary blob drifted for '$relative'." }
  }
  [pscustomobject][ordered]@{execution_root=$rootFull;boundary_sha=$Boundary;verified_paths=@($RelativePaths)}
}

function Get-P08BoundaryLocatorProjection([object]$Locator) {
  $projection=[ordered]@{}
  foreach($property in $Locator.PSObject.Properties) {
    if($property.Name -ceq 'locator_sha256'){continue}
    $projection[$property.Name]=if($property.Name -ceq 'created_at_utc'){
      if($property.Value -is [DateTime]){([DateTime]$property.Value).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')}
      else{([DateTimeOffset]::Parse([string]$property.Value)).UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ')}
    }else{$property.Value}
  }
  [pscustomobject]$projection
}

function New-P08BoundaryLocator {
  param([string]$Root,[string]$Boundary,[string]$State)
  $null=Assert-P08ExecutionBoundary -Root $Root -Boundary $Boundary -RelativePaths (Get-P08ModeScriptInventory 'InitializeBoundary')
  $stateFull=[IO.Path]::GetFullPath($State)
  if(Test-Path -LiteralPath $stateFull){
    if(@(Get-ChildItem -LiteralPath $stateFull -Force).Count -ne 0){Throw-P08HostedRule 'P08-BOUNDARY-STATE-NONEMPTY' 'Boundary state root must be fresh and empty.'}
  }else{$null=New-Item -ItemType Directory -Path $stateFull}
  $locatorFull=Join-Path $stateFull 'boundary-locator.json'
  $artifactFull=Join-Path $stateFull 'boundary-artifacts'
  $indexFull=Join-Path $artifactFull 'index.json'
  if (Test-Path -LiteralPath $locatorFull) { Throw-P08HostedRule 'P08-BOUNDARY-LOCATOR-EXISTS' 'Boundary locator is immutable.' }
  if (Test-Path -LiteralPath $artifactFull) { Throw-P08HostedRule 'P08-BOUNDARY-PARTIAL' 'Boundary artifact root exists without its locator.' }
  $null=New-Item -ItemType Directory -Force $artifactFull
  $index=[pscustomobject][ordered]@{schema_version='mnf-phase08-boundary-index/1';repository=$Repository;workflow=$Workflow;boundary_sha=$Boundary;records=@()}
  Write-P08ExclusiveJson $indexFull $index
  $value=[pscustomobject][ordered]@{
    schema_version='mnf-phase08-boundary-locator/1';repository=$Repository;workflow=$Workflow;boundary_sha=$Boundary
    execution_root=[IO.Path]::GetFullPath($Root);state_root=$stateFull;locator_path=$locatorFull
    artifact_root=$artifactFull;index_path=$indexFull;created_at_utc=[DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ');locator_sha256=''
  }
  $value.locator_sha256=Get-P08ObjectDigest (Get-P08BoundaryLocatorProjection $value)
  Write-P08ExclusiveJson $locatorFull $value
  $value
}

function Open-P08BoundaryLocator {
  param([Parameter(Mandatory)][string]$Locator,[Parameter(Mandatory)][string]$Operation)
  $locatorFull=[IO.Path]::GetFullPath($Locator)
  if(-not (Test-Path -LiteralPath $locatorFull -PathType Leaf)){Throw-P08HostedRule 'P08-BOUNDARY-LOCATOR' 'Durable boundary locator is missing.'}
  $value=Get-Content -LiteralPath $locatorFull -Raw|ConvertFrom-Json -Depth 100
  $names=@('schema_version','repository','workflow','boundary_sha','execution_root','state_root','locator_path','artifact_root','index_path','created_at_utc','locator_sha256')
  if((@($value.PSObject.Properties.Name)-join ',') -cne ($names-join ',') -or $value.schema_version -cne 'mnf-phase08-boundary-locator/1'){
    Throw-P08HostedRule 'P08-BOUNDARY-LOCATOR-CLOSED' 'Boundary locator field inventory drifted.'
  }
  if($value.repository -cne 'tchivs/moonbit-foundation' -or $value.workflow -cne 'publish-modules.yml' -or
      $value.boundary_sha -cnotmatch '^[0-9a-f]{40}$' -or [IO.Path]::GetFullPath([string]$value.locator_path) -cne $locatorFull -or
      [IO.Path]::GetFullPath([string]$value.state_root) -cne [IO.Path]::GetFullPath((Split-Path -Parent $locatorFull))){
    Throw-P08HostedRule 'P08-BOUNDARY-LOCATOR-BINDING' 'Boundary locator binding drifted.'
  }
  if($value.locator_sha256 -cne (Get-P08ObjectDigest (Get-P08BoundaryLocatorProjection $value))){Throw-P08HostedRule 'P08-BOUNDARY-LOCATOR-DIGEST' 'Boundary locator digest drifted.'}
  $index=Get-Content -LiteralPath ([string]$value.index_path) -Raw|ConvertFrom-Json -Depth 100
  if((@($index.PSObject.Properties.Name)-join ',') -cne 'schema_version,repository,workflow,boundary_sha,records' -or
      $index.schema_version -cne 'mnf-phase08-boundary-index/1' -or $index.repository -cne $value.repository -or
      $index.workflow -cne $value.workflow -or $index.boundary_sha -cne $value.boundary_sha -or @($index.records).Count -ne 0){
    Throw-P08HostedRule 'P08-BOUNDARY-INDEX' 'Boundary index binding drifted.'
  }
  $null=Assert-P08ExecutionBoundary -Root ([string]$value.execution_root) -Boundary ([string]$value.boundary_sha) -RelativePaths (Get-P08ModeScriptInventory $Operation)
  $value
}

function Copy-P08PreparedInput {
  param([Parameter(Mandatory)][string]$Source,[Parameter(Mandatory)][string]$InputRoot,[Parameter(Mandatory)][string]$RelativePath)
  if(-not (Test-Path -LiteralPath $Source -PathType Leaf)){Throw-P08HostedRule 'P08-PREPARE-INPUT' "Missing prepared input '$RelativePath'."}
  $destination=Test-P08SafePath (Join-Path $InputRoot $RelativePath) $InputRoot
  $null=New-Item -ItemType Directory -Force (Split-Path -Parent $destination)
  Copy-Item -LiteralPath $Source -Destination $destination
}

function Get-P08PrepareMaterials {
  param([Parameter(Mandatory)][object]$Boundary,[Parameter(Mandatory)][string]$WorkRoot)
  $context=[pscustomobject][ordered]@{execution_root=[string]$Boundary.execution_root;boundary_sha=[string]$Boundary.boundary_sha;work_root=[IO.Path]::GetFullPath($WorkRoot)}
  if($null -ne $script:PrepareProvider){$result=& $script:PrepareProvider $context}
  else {
    $qualificationRoot=Join-Path $WorkRoot 'qualification'
    & (Join-Path ([string]$Boundary.execution_root) 'scripts/quality/Invoke-ReleaseQualification.ps1') -Check -OutputDirectory $qualificationRoot
    if($LASTEXITCODE){Throw-P08HostedRule 'P08-PREPARE-QUALIFICATION' 'Release qualification failed.'}
    $archivePaths=@{}
    foreach($module in @('mb-core','mb-color','mb-image')){
      & moon -C (Join-Path ([string]$Boundary.execution_root) "modules/$module") package --frozen --list
      if($LASTEXITCODE){Throw-P08HostedRule 'P08-PREPARE-PACKAGE' "Packaging failed for '$module'."}
      $archivePaths[$module]=Join-Path ([string]$Boundary.execution_root) "_build/publish/tchivs-$module-0.1.0.zip"
    }
    $moonPath=(Get-Command moon -CommandType Application -ErrorAction Stop).Source
    $clang=Get-Command clang.exe -CommandType Application -ErrorAction SilentlyContinue
    $result=[pscustomobject][ordered]@{
      qualification_root=$qualificationRoot
      archive_paths=$archivePaths
      toolchain_root=Split-Path -Parent (Split-Path -Parent $moonPath)
      native_toolchain_bin=if($null -eq $clang){''}else{Split-Path -Parent $clang.Source}
    }
  }
  if($null -eq $result -or [string]::IsNullOrWhiteSpace([string]$result.qualification_root) -or
      [string]::IsNullOrWhiteSpace([string]$result.toolchain_root) -or $null -eq $result.archive_paths){
    Throw-P08HostedRule 'P08-PREPARE-PROVIDER' 'Prepare material provider returned an incomplete contract.'
  }
  $qualificationFull=[IO.Path]::GetFullPath([string]$result.qualification_root)
  foreach($relative in @('intent/intent.json','intent/intent.sha256','release-intent-binding.json')){
    if(-not (Test-Path -LiteralPath (Join-Path $qualificationFull $relative) -PathType Leaf)){Throw-P08HostedRule 'P08-PREPARE-QUALIFICATION' "Qualification output '$relative' is missing."}
  }
  foreach($module in @('mb-core','mb-color','mb-image')){
    if(-not $result.archive_paths.ContainsKey($module) -or -not (Test-Path -LiteralPath ([string]$result.archive_paths[$module]) -PathType Leaf)){
      Throw-P08HostedRule 'P08-PREPARE-ARCHIVE' "Prepared archive '$module' is missing."
    }
  }
  [pscustomobject][ordered]@{
    qualification_root=$qualificationFull;archive_paths=$result.archive_paths
    toolchain_root=[IO.Path]::GetFullPath([string]$result.toolchain_root)
    native_toolchain_bin=if([string]::IsNullOrWhiteSpace([string]$result.native_toolchain_bin)){''}else{[IO.Path]::GetFullPath([string]$result.native_toolchain_bin)}
  }
}

function New-P08PrepareIndexRecord {
  param([string]$LogicalKey,[string]$Kind,[string]$RelativePath,[string]$AbsolutePath,[string]$ContentDigest,[object]$Binding)
  [pscustomobject][ordered]@{
    logical_key=$LogicalKey;kind=$Kind;module=$null;observation_phase='prepare';path=$RelativePath
    file_sha256=Get-P08Sha256 $AbsolutePath;content_sha256=$ContentDigest;source_sha=[string]$Binding.source_sha
    root_intent_sha256=[string]$Binding.root_intent_sha256;intent_sha256=[string]$Binding.intent_sha256
    prepared_manifest_sha256=[string]$Binding.prepared_manifest_sha256;prior_authority_sha256=$null
  }
}

function New-P08PreparedAttempt {
  param([Parameter(Mandatory)][object]$Boundary)
  $prepareBindings=[ordered]@{
    BoundaryLocatorPath=$BoundaryLocatorPath;ReleaseRef=$ReleaseRef
    HistoricalReleaseRef=$HistoricalReleaseRef;HistoricalSourceSha=$HistoricalSourceSha
  }
  $missing=@($prepareBindings.GetEnumerator()|Where-Object{[string]::IsNullOrWhiteSpace([string]$_.Value)}|ForEach-Object Key)
  if($missing.Count -ne 0){Throw-P08HostedRule 'P08-PREPARE-MISSING-BINDING' ('PrepareAttempt requires: '+($missing-join ', ')+'.')}
  if($ReleaseRef -cne 'refs/tags/modules-v0.1.0-r7'){Throw-P08HostedRule 'P08-PREPARE-R7-BINDING' 'PrepareAttempt requires the exact r7 release ref.'}
  $executionRoot=[IO.Path]::GetFullPath([string]$Boundary.execution_root)
  $control=Get-Content -LiteralPath (Join-Path $executionRoot 'policy/release-control.json') -Raw|ConvertFrom-Json -Depth 100
  $history=@($control.initial_attempt_family.terminal_negative_history)
  if($control.initial_attempt_family.current_attempt -cne 'r7' -or $history.Count -ne 7 -or ($history.attempt -join ',') -cne 'attempt_zero,r1,r2,r3,r4,r5,r6' -or
      ($history.release_ref -join ',') -cne 'refs/tags/modules-v0.1.0,refs/tags/modules-v0.1.0-r1,refs/tags/modules-v0.1.0-r2,refs/tags/modules-v0.1.0-r3,refs/tags/modules-v0.1.0-r4,refs/tags/modules-v0.1.0-r5,refs/tags/modules-v0.1.0-r6' -or
      @($history|Where-Object{$_.mutation_performed-ne$false-or$_.authority_acquired-ne$false}).Count -ne 0){
    Throw-P08HostedRule 'P08-PREPARE-HISTORY' 'The exact seven-entry terminal-negative history is required.'
  }
  $historicalPolicy=$history[6]
  if(-not [string]::IsNullOrWhiteSpace($HistoricalRunId) -or $HistoricalRunAttempt -ne 0 -or $historicalPolicy.hosted_run_present -ne $false -or $null -ne $historicalPolicy.run_id -or $null -ne $historicalPolicy.run_attempt -or
      $HistoricalReleaseRef -cne [string]$historicalPolicy.release_ref -or $HistoricalSourceSha -cne [string]$historicalPolicy.source_sha -or
      $historicalPolicy.reason -cne 'terminal_workflow_duplicate_environment_key' -or $historicalPolicy.hosted_preflight_dispatch_attempted -ne $true -or $historicalPolicy.hosted_preflight_dispatched -ne $false -or
      $historicalPolicy.failure_stage -cne 'hosted_dispatch_validation_before_run_creation' -or $historicalPolicy.validation_error -cne 'duplicate_workflow_environment_key' -or
      [int]$historicalPolicy.publish_run_count -ne 0 -or [int]$historicalPolicy.mutation_count -ne 0 -or [int]$historicalPolicy.authorization_receipt_count -ne 0){
    Throw-P08HostedRule 'P08-PREPARE-HISTORICAL-BINDING' 'Historical failed-attempt binding differs from release control.'
  }
  $resolvedRef=((Invoke-P08Git $executionRoot @('rev-parse',"$ReleaseRef^{}"))-join '').Trim()
  if($resolvedRef -cne [string]$Boundary.boundary_sha){Throw-P08HostedRule 'P08-PREPARE-REF' 'The r7 ref does not peel to the durable boundary.'}
  $stateRoot=[IO.Path]::GetFullPath([string]$Boundary.state_root)
  $locatorPath=Join-Path $stateRoot 'phase-08-live-locator.json'
  if(Test-Path -LiteralPath $locatorPath){Throw-P08HostedRule 'P08-PREPARE-EXISTS' 'An active attempt locator already exists.'}
  $workRoot=Join-Path $stateRoot ('.prepare-'+[Guid]::NewGuid().ToString('N'))
  $null=New-Item -ItemType Directory -Force $workRoot
  try {
    $materials=Get-P08PrepareMaterials -Boundary $Boundary -WorkRoot $workRoot
    $qualificationRoot=[string]$materials.qualification_root
    $intentPath=Join-Path $qualificationRoot 'intent/intent.json'
    $intentDigest=(Get-Content -LiteralPath (Join-Path $qualificationRoot 'intent/intent.sha256') -Raw).Trim()
    $binding=Get-Content -LiteralPath (Join-Path $qualificationRoot 'release-intent-binding.json') -Raw|ConvertFrom-Json -Depth 100
    if($intentDigest -cnotmatch '^[0-9a-f]{64}$' -or (Get-P08Sha256 $intentPath) -cne $intentDigest -or
        $binding.release_ref -cne $ReleaseRef -or $binding.source_sha -cne [string]$Boundary.boundary_sha -or
        $binding.root_intent_sha256 -cne $intentDigest -or $binding.intent_sha256 -cne $intentDigest -or
        $binding.credentials_read -ne $false -or $binding.publication_performed -ne $false){
      Throw-P08HostedRule 'P08-PREPARE-INTENT-BINDING' 'Fresh r7 intent/root binding is invalid.'
    }
    $artifactRoot=Join-Path $stateRoot "artifacts/$intentDigest"
    if(Test-Path -LiteralPath $artifactRoot){Throw-P08HostedRule 'P08-PREPARE-PARTIAL' 'Fresh attempt artifact root already exists.'}
    $stageRoot=Join-Path $workRoot 'store'
    $inputRoot=Join-Path $workRoot 'prepared-input'
    $preparedRoot=Join-Path $stageRoot 'prepared'
    $null=New-Item -ItemType Directory -Force $inputRoot
    $historyProjections=@()
    foreach($record in $history){$projection=[ordered]@{};foreach($property in $record.PSObject.Properties){if($property.Name -cne 'record_sha256'){$projection[$property.Name]=$property.Value}};$historyProjections+=,[pscustomobject]$projection}
    $attemptZero=$historyProjections[0];$r1Negative=$historyProjections[1];$r2Negative=$historyProjections[2];$r3Negative=$historyProjections[3];$r4Negative=$historyProjections[4];$r5Negative=$historyProjections[5];$r6Negative=$historyProjections[6]
    $attemptZeroPath=Join-Path $stageRoot 'historical/attempt-zero.json';Write-P08ExclusiveJson $attemptZeroPath $attemptZero
    $r1HistoryPath=Join-Path $stageRoot 'historical/r1.json';Write-P08ExclusiveJson $r1HistoryPath $r1Negative
    $r2HistoryPath=Join-Path $stageRoot 'historical/r2.json';Write-P08ExclusiveJson $r2HistoryPath $r2Negative
    $r3HistoryPath=Join-Path $stageRoot 'historical/r3.json';Write-P08ExclusiveJson $r3HistoryPath $r3Negative
    $r4HistoryPath=Join-Path $stageRoot 'historical/r4.json';Write-P08ExclusiveJson $r4HistoryPath $r4Negative
    $r5HistoryPath=Join-Path $stageRoot 'historical/r5.json';Write-P08ExclusiveJson $r5HistoryPath $r5Negative
    $r6HistoryPath=Join-Path $stageRoot 'historical/r6.json';Write-P08ExclusiveJson $r6HistoryPath $r6Negative
    $attemptZeroDigest=Get-P08Sha256 $attemptZeroPath;$r1HistoryDigest=Get-P08Sha256 $r1HistoryPath;$r2HistoryDigest=Get-P08Sha256 $r2HistoryPath;$r3HistoryDigest=Get-P08Sha256 $r3HistoryPath;$r4HistoryDigest=Get-P08Sha256 $r4HistoryPath;$r5HistoryDigest=Get-P08Sha256 $r5HistoryPath;$r6HistoryDigest=Get-P08Sha256 $r6HistoryPath
    $historySet=([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes((@($attemptZeroDigest,$r1HistoryDigest,$r2HistoryDigest,$r3HistoryDigest,$r4HistoryDigest,$r5HistoryDigest,$r6HistoryDigest)-join"`n"))))).ToLowerInvariant()
    foreach($module in @('mb-core','mb-color','mb-image')){Copy-P08PreparedInput -Source ([string]$materials.archive_paths[$module]) -InputRoot $inputRoot -RelativePath "archives/$module.zip"}
    Copy-P08PreparedInput -Source $intentPath -InputRoot $inputRoot -RelativePath 'intent/current.json'
    Copy-P08PreparedInput -Source (Join-Path $qualificationRoot 'intent/intent.sha256') -InputRoot $inputRoot -RelativePath 'intent/current.sha256'
    Copy-P08PreparedInput -Source (Join-Path $qualificationRoot 'release-intent-binding.json') -InputRoot $inputRoot -RelativePath 'intent/root-binding.json'
    foreach($pair in @(
      @('scripts/quality/New-PreparedReleaseBundle.ps1','scripts/quality/New-PreparedReleaseBundle.ps1'),
      @('scripts/quality/Invoke-ReleasePublisher.ps1','scripts/quality/Invoke-ReleasePublisher.ps1'),
      @('scripts/quality/Invoke-MooncakesLiveMutation.ps1','scripts/quality/Invoke-MooncakesLiveMutation.ps1'),
      @('scripts/quality/ReleasePublisher.Common.ps1','scripts/quality/ReleasePublisher.Common.ps1'),
      @('policy/release-qualification.json','policy/release-qualification.json'),
      @('release/prepared/schema.json','schemas/prepared.json'),@('release/intent/schema.json','schemas/intent.json'),
      @('release/journal/record-schema.json','schemas/journal-record.json'),
      @('release/qualification/phase-07-requirements.json','qualification/phase-07-requirements.json'),
      @('compatibility/baselines/0.1.0/manifest.json','compatibility/interface-digests.json'),
      @('release/registry/authority-observation.json','registry/authority-observation.json')
    )){Copy-P08PreparedInput -Source (Join-Path $executionRoot $pair[0]) -InputRoot $inputRoot -RelativePath $pair[1]}
    $request=[pscustomobject][ordered]@{
      repository='tchivs/moonbit-foundation';actor='tchivs';release_ref=$ReleaseRef;source_sha=[string]$Boundary.boundary_sha
      root_intent_sha256=$intentDigest;intent_sha256=$intentDigest;intent_kind='initial';correction_sequence=0
      predecessor_intent_sha256=$null;authorization_valid=$true;evidence_valid=$true;dry_run_passed=$true;authority_account='tchivs'
      historical_attempt_zero_sha256=$attemptZeroDigest;historical_r1_sha256=$r1HistoryDigest;historical_r2_sha256=$r2HistoryDigest;historical_r3_sha256=$r3HistoryDigest;historical_r4_sha256=$r4HistoryDigest;historical_r5_sha256=$r5HistoryDigest;historical_r6_sha256=$r6HistoryDigest;historical_history_set_sha256=$historySet
    }
    [IO.File]::WriteAllText((Join-Path $inputRoot 'request.json'),(Get-P08CanonicalJson $request),[Text.UTF8Encoding]::new($false))
    $bundleArgs=@{Repository='tchivs/moonbit-foundation';Actor='tchivs';RunId='1';RunAttempt=1;ReleaseRef=$ReleaseRef;SourceSha=[string]$Boundary.boundary_sha;RootIntentSha256=$intentDigest;IntentSha256=$intentDigest;RunMode='start';HistoricalAttemptZeroSha256=$attemptZeroDigest;HistoricalR1Sha256=$r1HistoryDigest;HistoricalR2Sha256=$r2HistoryDigest;HistoricalR3Sha256=$r3HistoryDigest;HistoricalR4Sha256=$r4HistoryDigest;HistoricalR5Sha256=$r5HistoryDigest;HistoricalR6Sha256=$r6HistoryDigest;HistoricalHistorySetSha256=$historySet}
    $prepared=& (Join-Path $executionRoot 'scripts/quality/New-PreparedReleaseBundle.ps1') -InputRoot $inputRoot -OutputRoot $preparedRoot @bundleArgs
    & (Join-Path $executionRoot 'scripts/quality/New-PreparedReleaseBundle.ps1') -ValidateOnly -OutputRoot $preparedRoot @bundleArgs|Out-Null
    if($prepared.manifest_sha256 -cne (Get-P08Sha256 (Join-Path $preparedRoot 'prepared-bundle.json'))){Throw-P08HostedRule 'P08-PREPARE-MANIFEST' 'Prepared manifest digest drifted.'}
    . (Join-Path $executionRoot 'scripts/quality/ReleasePublisher.Common.ps1')
    $commitTime=((Invoke-P08Git $executionRoot @('show','-s','--format=%cI',[string]$Boundary.boundary_sha))-join '').Trim()
    $genesisCommand=[pscustomobject][ordered]@{
      journal_sequence=0;prior_record_sha256=('0'*64);root_intent_sha256=$intentDigest;intent_sha256=$intentDigest;intent_kind='initial'
      correction_sequence=0;predecessor_intent_sha256=$null;state='intent_authorized';module=$null;operation='authorize'
      observation=ConvertTo-PublisherSanitizedObservation -Status not_observed -Identity not_applicable -ReasonCode none -ReobservationRequired $false
      outcome='accepted';recorded_at_utc=$commitTime;run_identity=[pscustomobject][ordered]@{repository='tchivs/moonbit-foundation';run_id='1';artifact_name='publisher-genesis-r7';artifact_sequence=0}
    }
    $genesis=(Resolve-PublisherTransition -Records @() -Command $genesisCommand).record
    $journalPath=Join-Path $stageRoot 'journal/genesis.json';Write-P08ExclusiveJson $journalPath $genesis
    $preparedDigest=[string]$prepared.manifest_sha256
    $indexBinding=[pscustomobject]@{source_sha=[string]$Boundary.boundary_sha;root_intent_sha256=$intentDigest;intent_sha256=$intentDigest;prepared_manifest_sha256=$preparedDigest}
    $records=@(
      New-P08PrepareIndexRecord -LogicalKey 'prepare|intent|root-current' -Kind 'ReleaseIntent' -RelativePath 'prepared/intent/current.json' -AbsolutePath (Join-Path $preparedRoot 'intent/current.json') -ContentDigest $intentDigest -Binding $indexBinding
      New-P08PrepareIndexRecord -LogicalKey 'prepare|journal|genesis' -Kind 'GenesisJournal' -RelativePath 'journal/genesis.json' -AbsolutePath $journalPath -ContentDigest ([string]$genesis.record_sha256) -Binding $indexBinding
      New-P08PrepareIndexRecord -LogicalKey 'prepare|bundle|manifest' -Kind 'PreparedManifest' -RelativePath 'prepared/prepared-bundle.json' -AbsolutePath (Join-Path $preparedRoot 'prepared-bundle.json') -ContentDigest $preparedDigest -Binding $indexBinding
      New-P08PrepareIndexRecord -LogicalKey 'prepare|historical|attempt-zero' -Kind 'HistoricalNegative' -RelativePath 'historical/attempt-zero.json' -AbsolutePath $attemptZeroPath -ContentDigest $attemptZeroDigest -Binding $indexBinding
      New-P08PrepareIndexRecord -LogicalKey 'prepare|historical|r1' -Kind 'HistoricalNegative' -RelativePath 'historical/r1.json' -AbsolutePath $r1HistoryPath -ContentDigest $r1HistoryDigest -Binding $indexBinding
      New-P08PrepareIndexRecord -LogicalKey 'prepare|historical|r2' -Kind 'HistoricalNegative' -RelativePath 'historical/r2.json' -AbsolutePath $r2HistoryPath -ContentDigest $r2HistoryDigest -Binding $indexBinding
      New-P08PrepareIndexRecord -LogicalKey 'prepare|historical|r3' -Kind 'HistoricalNegative' -RelativePath 'historical/r3.json' -AbsolutePath $r3HistoryPath -ContentDigest $r3HistoryDigest -Binding $indexBinding
      New-P08PrepareIndexRecord -LogicalKey 'prepare|historical|r4' -Kind 'HistoricalNegative' -RelativePath 'historical/r4.json' -AbsolutePath $r4HistoryPath -ContentDigest $r4HistoryDigest -Binding $indexBinding
      New-P08PrepareIndexRecord -LogicalKey 'prepare|historical|r5' -Kind 'HistoricalNegative' -RelativePath 'historical/r5.json' -AbsolutePath $r5HistoryPath -ContentDigest $r5HistoryDigest -Binding $indexBinding
      New-P08PrepareIndexRecord -LogicalKey 'prepare|historical|r6' -Kind 'HistoricalNegative' -RelativePath 'historical/r6.json' -AbsolutePath $r6HistoryPath -ContentDigest $r6HistoryDigest -Binding $indexBinding
    )
    $index=[pscustomobject][ordered]@{schema_version='mnf-phase08-artifact-index/2';boundary_sha=[string]$Boundary.boundary_sha;prepared_manifest_sha256=$preparedDigest;records=$records}
    Write-P08ExclusiveJson (Join-Path $stageRoot 'index.json') $index
    $null=New-Item -ItemType Directory -Force (Split-Path -Parent $artifactRoot)
    [IO.Directory]::Move($stageRoot,$artifactRoot)
    $locator=[pscustomobject][ordered]@{
      schema_version='mnf-phase08-live-locator/2';repository='tchivs/moonbit-foundation';workflow='publish-modules.yml';release_ref=$ReleaseRef
      boundary_sha=[string]$Boundary.boundary_sha;execution_root=$executionRoot;source_sha=[string]$Boundary.boundary_sha
      root_intent_sha256=$intentDigest;intent_sha256=$intentDigest;prepared_manifest_sha256=$preparedDigest;artifact_root=[IO.Path]::GetFullPath($artifactRoot)
      index_path=[IO.Path]::GetFullPath((Join-Path $artifactRoot 'index.json'));mutation_authorization_packet_path=$null;mutation_authorization_packet_sha256=$null
      created_at_utc=ConvertTo-ReleaseCanonicalUtc $commitTime;locator_sha256=''
    }
    $locator.locator_sha256=Get-P08ObjectDigest (Get-P08BoundaryLocatorProjection $locator)
    Write-P08ExclusiveJson $locatorPath $locator
    [pscustomobject][ordered]@{
      mode='PrepareAttempt';locator_path=[IO.Path]::GetFullPath($locatorPath);artifact_root=[IO.Path]::GetFullPath($artifactRoot)
      index_path=[IO.Path]::GetFullPath((Join-Path $artifactRoot 'index.json'));root_intent_sha256=$intentDigest;intent_sha256=$intentDigest
      prepared_manifest_sha256=$preparedDigest;historical_record_path=[IO.Path]::GetFullPath((Join-Path $artifactRoot 'historical/r6.json'))
      attempt_zero_history_path=[IO.Path]::GetFullPath((Join-Path $artifactRoot 'historical/attempt-zero.json'));r1_history_path=[IO.Path]::GetFullPath((Join-Path $artifactRoot 'historical/r1.json'));r2_history_path=[IO.Path]::GetFullPath((Join-Path $artifactRoot 'historical/r2.json'));r3_history_path=[IO.Path]::GetFullPath((Join-Path $artifactRoot 'historical/r3.json'));r4_history_path=[IO.Path]::GetFullPath((Join-Path $artifactRoot 'historical/r4.json'));r5_history_path=[IO.Path]::GetFullPath((Join-Path $artifactRoot 'historical/r5.json'));r6_history_path=[IO.Path]::GetFullPath((Join-Path $artifactRoot 'historical/r6.json'));historical_history_set_sha256=$historySet
      genesis_record_path=[IO.Path]::GetFullPath((Join-Path $artifactRoot 'journal/genesis.json'));prepared_root=[IO.Path]::GetFullPath((Join-Path $artifactRoot 'prepared'))
      toolchain_root=[string]$materials.toolchain_root;native_toolchain_bin=[string]$materials.native_toolchain_bin;mutation_count=0
    }
  } finally {
    if(Test-Path -LiteralPath $workRoot){Remove-Item -LiteralPath $workRoot -Recurse -Force}
  }
}

function Open-P08BoundaryStore {
  param([string]$Locator,[string]$Artifacts,[string]$Operation)
  if (-not (Test-Path -LiteralPath $Locator -PathType Leaf)) { Throw-P08HostedRule 'P08-BOUNDARY-LOCATOR' 'Durable locator is missing.' }
  $value=Get-Content -LiteralPath $Locator -Raw | ConvertFrom-Json -Depth 100
  $names=@('schema_version','repository','workflow','release_ref','boundary_sha','execution_root','source_sha','root_intent_sha256','intent_sha256','prepared_manifest_sha256','artifact_root','index_path','mutation_authorization_packet_path','mutation_authorization_packet_sha256','created_at_utc','locator_sha256')
  if ((@($value.PSObject.Properties.Name)-join ',') -cne ($names-join ',') -or $value.schema_version -cne 'mnf-phase08-live-locator/2') { Throw-P08HostedRule 'P08-BOUNDARY-LOCATOR-CLOSED' 'Locator field inventory drifted.' }
  if ([IO.Path]::GetFullPath([string]$value.artifact_root) -cne [IO.Path]::GetFullPath($Artifacts) -or
      $value.repository -cne $Repository -or $value.workflow -cne $Workflow -or $value.release_ref -cne 'refs/tags/modules-v0.1.0-r7' -or
      $value.source_sha -cne $SourceSha -or $value.boundary_sha -cne $BoundarySha -or $value.source_sha -cne $value.boundary_sha -or
      $value.root_intent_sha256 -cne $RootIntentSha256 -or $value.intent_sha256 -cne $IntentSha256 -or $value.prepared_manifest_sha256 -cne $PreparedManifestSha256) {
    Throw-P08HostedRule 'P08-BOUNDARY-BINDING' 'Locator binding drifted.'
  }
  if ($value.locator_sha256 -cne (Get-P08ObjectDigest (Get-P08BoundaryLocatorProjection $value))) { Throw-P08HostedRule 'P08-BOUNDARY-LOCATOR-DIGEST' 'Locator digest drifted.' }
  $null=Assert-P08ExecutionBoundary -Root ([string]$value.execution_root) -Boundary ([string]$value.boundary_sha) -RelativePaths (Get-P08ModeScriptInventory $Operation)
  $index=Get-Content -LiteralPath ([string]$value.index_path) -Raw | ConvertFrom-Json -Depth 100
  if ($index.schema_version -cne 'mnf-phase08-artifact-index/2' -or $index.boundary_sha -cne $value.boundary_sha -or $index.prepared_manifest_sha256 -cne $value.prepared_manifest_sha256) { Throw-P08HostedRule 'P08-STORE-INDEX' 'Artifact index binding drifted.' }
  $seen=@{};$logical=@{}
  foreach($record in @($index.records)) {
    $recordNames=@('logical_key','kind','module','observation_phase','path','file_sha256','content_sha256','source_sha','root_intent_sha256','intent_sha256','prepared_manifest_sha256','prior_authority_sha256')
    if ((@($record.PSObject.Properties.Name)-join ',') -cne ($recordNames-join ',')) { Throw-P08HostedRule 'P08-STORE-RECORD-CLOSED' 'Indexed artifact fields drifted.' }
    if ($seen.ContainsKey([string]$record.path) -or $logical.ContainsKey([string]$record.logical_key)) { Throw-P08HostedRule 'P08-STORE-DUPLICATE' 'Duplicate indexed artifact.' }
    $seen[[string]$record.path]=$true;$logical[[string]$record.logical_key]=$true
    $absolute=Test-P08SafePath (Join-Path ([string]$value.artifact_root) ([string]$record.path)) ([string]$value.artifact_root)
    if ((Get-P08Sha256 $absolute) -cne [string]$record.file_sha256) { Throw-P08HostedRule 'P08-STORE-INDEX-DIGEST' 'Indexed artifact digest drifted.' }
  }
  [pscustomobject]@{locator=$value;index=$index;paths=[pscustomobject]@{locator=[IO.Path]::GetFullPath($Locator);root=[IO.Path]::GetFullPath($Artifacts);index=[IO.Path]::GetFullPath([string]$value.index_path)}}
}

function Add-P08SanitizedArtifact {
  param([object]$Store,[string]$Kind,[string]$Module,[string]$Phase,[string]$SourcePath,[string]$FileDigest,[string]$ContentDigest,[string]$PriorAuthorityPath)
  if ($FileDigest -cnotmatch '^[0-9a-f]{64}$' -or $ContentDigest -cnotmatch '^[0-9a-f]{64}$' -or (Get-P08Sha256 $SourcePath) -cne $FileDigest) { Throw-P08HostedRule 'P08-INDEX-DIGEST' 'Sanitized artifact digest is invalid.' }
  $sourceFull=[IO.Path]::GetFullPath($SourcePath);$root=[IO.Path]::GetFullPath([string]$Store.locator.artifact_root)
  $relative=[IO.Path]::GetRelativePath($root,$sourceFull).Replace('\','/')
  $null=Test-P08SafePath $sourceFull $root
  $priorDigest=$null
  if (-not [string]::IsNullOrWhiteSpace($PriorAuthorityPath)) { $priorDigest=Get-P08Sha256 $PriorAuthorityPath }
  $logical="$Kind|$Module|$Phase"
  if (@($Store.index.records|Where-Object {$_.logical_key -ceq $logical -or $_.path -ceq $relative}).Count -ne 0) { Throw-P08HostedRule 'P08-STORE-DUPLICATE' 'Duplicate indexed artifact.' }
  $record=[pscustomobject][ordered]@{logical_key=$logical;kind=$Kind;module=$Module;observation_phase=$Phase;path=$relative;file_sha256=$FileDigest;content_sha256=$ContentDigest;source_sha=[string]$Store.locator.source_sha;root_intent_sha256=[string]$Store.locator.root_intent_sha256;intent_sha256=[string]$Store.locator.intent_sha256;prepared_manifest_sha256=[string]$Store.locator.prepared_manifest_sha256;prior_authority_sha256=$priorDigest}
  $Store.index.records=@($Store.index.records)+@($record);Write-P08ReplaceJson ([string]$Store.locator.index_path) $Store.index
  $record
}

function Resolve-P08ObservationOutcome {
  param([Parameter(Mandatory)][object]$Observation,[Parameter(Mandatory)][string]$Module,[string]$PriorAuthorityPath)
  if ([string]$Observation.outcome -cnotin @('absent','exact','mismatch','unknown')) { Throw-P08HostedRule 'P08-OUTCOME-CLOSED' 'Observation outcome is outside the closed switch.' }
  if ($Module -cne 'mb-core' -and [string]::IsNullOrWhiteSpace($PriorAuthorityPath)) { Throw-P08HostedRule 'P08-PREDECESSOR-REQUIRED' 'Successor outcome requires explicit predecessor authority.' }
  switch ([string]$Observation.outcome) {
    'absent' { [pscustomobject][ordered]@{classification='mutation_candidate';module=$Module;may_assemble_packet=($Module -ceq 'mb-core');may_publish=$false;terminal=$false} }
    'exact' { [pscustomobject][ordered]@{classification='exact_existing';module=$Module;may_assemble_packet=$false;may_publish=$false;terminal=$false} }
    'mismatch' { [pscustomobject][ordered]@{classification='terminal_forward_correction';module=$Module;may_assemble_packet=$false;may_publish=$false;terminal=$true} }
    default { [pscustomobject][ordered]@{classification='terminal_stop';module=$Module;may_assemble_packet=$false;may_publish=$false;terminal=$true} }
  }
}

function Select-P08AuthorityUnion {
  param([string]$MutationPacketPath,[string]$ExactAuthorityPath)
  $hasPacket=-not [string]::IsNullOrWhiteSpace($MutationPacketPath)
  $hasExact=-not [string]::IsNullOrWhiteSpace($ExactAuthorityPath)
  if ($hasPacket -and $hasExact) { Throw-P08HostedRule 'P08-AUTHORITY-BOTH' 'AuthorityUnion accepts exactly one authority variant.' }
  if (-not $hasPacket -and -not $hasExact) { Throw-P08HostedRule 'P08-AUTHORITY-NEITHER' 'AuthorityUnion requires one authority variant.' }
  $path=if($hasPacket){$MutationPacketPath}else{$ExactAuthorityPath}
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Throw-P08HostedRule 'P08-AUTHORITY-FILE' 'Authority record is missing.' }
  $record=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -Depth 100
  if ($hasPacket -and $record.schema_version -cne 'mnf-phase08-mutation-authorization-packet/1') { Throw-P08HostedRule 'P08-AUTHORITY-PACKET' 'MutationAuthorizationPacket schema drifted.' }
  if ($hasExact -and $record.schema_version -cne 'mnf-phase08-exact-existing-authority/1') { Throw-P08HostedRule 'P08-AUTHORITY-EXACT' 'ExactExistingAuthority schema drifted.' }
  [pscustomobject][ordered]@{variant=if($hasPacket){'MutationAuthorizationPacket'}else{'ExactExistingAuthority'};path=[IO.Path]::GetFullPath($path);sha256=Get-P08Sha256 $path;record=$record}
}

function New-P08ExactExistingAuthority {
  param([object]$Store,[string]$Module,[string]$ObservationPath,[string]$ColdPath,[string]$PriorAuthorityPath,[string]$ReducerPath,[string]$HistoricalNegativePath)
  $observation=Get-Content -LiteralPath $ObservationPath -Raw | ConvertFrom-Json -Depth 100
  $cold=Get-Content -LiteralPath $ColdPath -Raw | ConvertFrom-Json -Depth 100
  if ($observation.outcome -cne 'exact' -or $cold.evidence_mode -cne 'live_registry' -or $cold.verified -ne $true -or (@($cold.targets.name)-join ',') -cne 'js,wasm,wasm-gc,native' -or $cold.targets[3].runtime -cne 'pass') { Throw-P08HostedRule 'P08-EXACT-EVIDENCE' 'Exact-existing authority requires exact observation and real four-target cold proof.' }
  if ([string]::IsNullOrWhiteSpace($ReducerPath) -or [string]::IsNullOrWhiteSpace($HistoricalNegativePath)) { Throw-P08HostedRule 'P08-EXACT-REDUCER' 'Exact-existing authority requires explicit reducer and historical-negative records.' }
  $reducer=Get-Content -LiteralPath $ReducerPath -Raw|ConvertFrom-Json -Depth 100
  $expectedState="$($Module.Replace('mb-',''))_checkpoint_verified"
  if ($reducer.schema_version -cne 'mnf-release-journal-record/1' -or $reducer.state -cne $expectedState -or $reducer.module -cne $Module -or
      $reducer.root_intent_sha256 -cne [string]$Store.locator.root_intent_sha256 -or $reducer.intent_sha256 -cne [string]$Store.locator.intent_sha256 -or
      $reducer.observation.status -cne 'exact_match' -or $reducer.record_sha256 -cnotmatch '^[0-9a-f]{64}$') { Throw-P08HostedRule 'P08-EXACT-REDUCER' 'Reducer record is not the exact verified checkpoint.' }
  $historical=Get-Content -LiteralPath $HistoricalNegativePath -Raw|ConvertFrom-Json -Depth 100
  if ([string]$historical.run_id -cne '29652468948' -or [int]$historical.run_attempt -ne 1 -or [string]$historical.classification -cne 'terminal_historical_failure') { Throw-P08HostedRule 'P08-EXACT-HISTORICAL' 'Historical failed hosted attempt is not the indexed terminal negative.' }
  $priorDigest=if([string]::IsNullOrWhiteSpace($PriorAuthorityPath)){$null}else{Get-P08Sha256 $PriorAuthorityPath}
  [pscustomobject][ordered]@{
    schema_version='mnf-phase08-exact-existing-authority/1';source='exact_existing';module=$Module;repository=[string]$Store.locator.repository
    release_ref=[string]$Store.locator.release_ref;boundary_sha=[string]$Store.locator.boundary_sha;source_sha=[string]$Store.locator.source_sha
    execution_root=[string]$Store.locator.execution_root;locator_sha256=[string]$Store.locator.locator_sha256;artifact_root=[string]$Store.locator.artifact_root;index_path=[string]$Store.locator.index_path
    root_intent_sha256=[string]$Store.locator.root_intent_sha256;intent_sha256=[string]$Store.locator.intent_sha256;prepared_manifest_sha256=[string]$Store.locator.prepared_manifest_sha256
    observation_sha256=Get-P08Sha256 $ObservationPath;observation_content_sha256=[string]$observation.content_sha256;archive_sha256=[string]$cold.archive_sha256;downloaded_manifest_sha256=[string]$cold.downloaded_manifest_sha256
    cold_proof_sha256=Get-P08Sha256 $ColdPath;cold_content_sha256=[string]$cold.content_sha256;targets=@($cold.targets.name);native_runtime='pass';toolchain_root_sha256=[string]$cold.toolchain.root_sha256
    predecessor_authority_sha256=$priorDigest;reducer_state=$expectedState;reducer_record_sha256=[string]$reducer.record_sha256;historical_negative_run='29652468948/1';historical_negative_sha256=Get-P08Sha256 $HistoricalNegativePath
    mutation_authorization_required=$false;mutation_authorization_used=$false;publisher_dry_run_used=$false;mutation_count=0;authorization_packet_sha256=$null;authority_sha256=''
  }
}

function Invoke-P08Gh([string[]]$Arguments) {
  if ($null -ne $script:GhCommand) { return (& $script:GhCommand $Arguments) }
  $output=& gh @Arguments 2>&1; if ($LASTEXITCODE -ne 0) { Throw-P08HostedRule 'P08-HOSTED-GH' 'GitHub CLI operation failed.' }; $output
}

function Get-P08Runs([string]$Repo,[string]$WorkflowPath) {
  $json=(Invoke-P08Gh @('run','list','--repo',$Repo,'--workflow',$WorkflowPath,'--event','workflow_dispatch','--limit','100','--json','databaseId,headBranch,headSha,status,conclusion,displayTitle,workflowName,url,createdAt,updatedAt')) -join "`n"
  if ([string]::IsNullOrWhiteSpace($json)) { return @() }
  @($json | ConvertFrom-Json -Depth 30)
}

function Select-P08NewRun([hashtable]$Before,[object[]]$Runs,[string]$Sha,[string]$Title,[string]$DispatchRef) {
  $matches=@($Runs | Where-Object { -not $Before.ContainsKey([string]$_.databaseId) -and $_.headBranch -ceq $DispatchRef -and $_.headSha -ceq $Sha -and $_.displayTitle -ceq $Title })
  if ($matches.Count -gt 1) { Throw-P08HostedRule 'P08-HOSTED-AMBIGUOUS-RUN' 'Multiple new bound runs exist.' }
  if ($matches.Count -eq 1) { return $matches[0] }
  $null
}

function Select-P08Artifact([object]$Response,[string]$Prefix) {
  $matches=@($Response.artifacts | Where-Object { -not $_.expired -and $_.name.StartsWith($Prefix,[StringComparison]::Ordinal) })
  if ($matches.Count -ne 1) { Throw-P08HostedRule 'P08-HOSTED-AMBIGUOUS-ARTIFACT' 'Expected exactly one bound sanitized artifact.' }
  $matches[0]
}

function Invoke-P08HostedDispatch {
  param([string]$Operation,[string]$Repo,[string]$WorkflowPath,[string]$Ref,[string]$Sha,[string]$RootIntent,[string]$CurrentIntent,[string]$PreparedDigest,[string]$Module,[string]$PriorId,[string]$PriorArtifact,[string]$Packet,[string]$Receipt,[string]$AttemptZeroHistory,[string]$R1History,[string]$R2History,[string]$R3History,[string]$R4History,[string]$R5History,[string]$R6History)
  $before=@{}; foreach($run in @(Get-P08Runs $Repo $WorkflowPath)){ $before[[string]$run.databaseId]=$true }
  if([string]::IsNullOrWhiteSpace($AttemptZeroHistory)-or[string]::IsNullOrWhiteSpace($R1History)-or[string]::IsNullOrWhiteSpace($R2History)-or[string]::IsNullOrWhiteSpace($R3History)-or[string]::IsNullOrWhiteSpace($R4History)-or[string]::IsNullOrWhiteSpace($R5History)-or[string]::IsNullOrWhiteSpace($R6History)){Throw-P08HostedRule 'P08-HOSTED-HISTORY' 'All seven terminal-negative history files are required for dispatch.'}
  $history=Get-ReleaseInitialHistoryBinding
  $historyFiles=@($AttemptZeroHistory,$R1History,$R2History,$R3History,$R4History,$R5History,$R6History);$historyDigests=@($historyFiles|ForEach-Object{Get-P08Sha256 $_})
  if(($historyDigests-join',')-cne(@($history.historical_attempt_zero_sha256,$history.historical_r1_sha256,$history.historical_r2_sha256,$history.historical_r3_sha256,$history.historical_r4_sha256,$history.historical_r5_sha256,$history.historical_r6_sha256)-join',')){Throw-P08HostedRule 'P08-HOSTED-HISTORY' 'Individual terminal-negative history files drifted.'}
  $computedSet=([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes(($historyDigests-join"`n"))))).ToLowerInvariant()
  if($computedSet-cne$history.historical_history_set_sha256){Throw-P08HostedRule 'P08-HOSTED-HISTORY' 'Ordered terminal-negative history set drifted.'}
  $hasPacket=-not[string]::IsNullOrWhiteSpace($Packet);$hasReceipt=-not[string]::IsNullOrWhiteSpace($Receipt)
  if($hasPacket-ne$hasReceipt-or($Operation-ceq'PublishOne'-and(-not$hasPacket))-or($Operation-cne'PublishOne'-and$hasPacket)){Throw-P08HostedRule 'P08-HOSTED-AUTHORITY' 'Packet and receipt must form the exact PublishOne resume pair.'}
  $fields=@(
    ('operation_mode='+$Operation),
    ('run_mode='+$(if([string]::IsNullOrWhiteSpace($PriorId)){'start'}else{'resume'})),
    ('release_ref='+$Ref),
    ('source_sha='+$Sha),
    ('root_intent_sha256='+$RootIntent),
    ('intent_sha256='+$CurrentIntent),
    ('prepared_manifest_sha256='+$PreparedDigest),
    ('historical_attempts_sha256='+$computedSet),
    ('target_module='+$Module),
    ('live_authorization='+$(if($Operation -ceq 'PublishOne'){'true'}else{'false'})),
    ('prior_run_id='+$PriorId),
    ('prior_artifact_name='+$PriorArtifact),
    ('authorization_packet_sha256='+$(if($hasPacket){Get-P08Sha256 $Packet}else{''})),
    ('authorization_receipt_sha256='+$(if($hasReceipt){Get-P08Sha256 $Receipt}else{''}))
  )
  $dispatchRef=if($Ref.StartsWith('refs/tags/',[StringComparison]::Ordinal)){$Ref.Substring(10)}else{$Ref}
  $args=@('workflow','run',$WorkflowPath,'--repo',$Repo,'--ref',$dispatchRef); foreach($field in $fields){$args+=@('-f',$field)}
  $null=Invoke-P08Gh $args
  $title="MNF $Operation $Module $RootIntent $CurrentIntent $PreparedDigest"
  $deadline=[DateTime]::UtcNow.AddMinutes(45); $candidate=$null
  do {
    $candidate=Select-P08NewRun -Before $before -Runs @(Get-P08Runs $Repo $WorkflowPath) -Sha $Sha -Title $title -DispatchRef $dispatchRef
    if ($null -ne $candidate -and $candidate.status -ceq 'completed') { break }
    Start-Sleep -Seconds 10
  } while([DateTime]::UtcNow -lt $deadline)
  if ($null -eq $candidate -or $candidate.status -cne 'completed' -or $candidate.conclusion -cne 'success') { Throw-P08HostedRule 'P08-HOSTED-RUN' 'Unique bound run did not complete successfully.' }
  $viewJson=(Invoke-P08Gh @('run','view',[string]$candidate.databaseId,'--repo',$Repo,'--json','databaseId,attempt,headBranch,headSha,event,status,conclusion,displayTitle,workflowName,url,createdAt,updatedAt')) -join "`n"
  $view=$viewJson | ConvertFrom-Json -Depth 30
  if ($view.databaseId -ne $candidate.databaseId -or $view.attempt -lt 1 -or $view.headBranch -cne $dispatchRef -or $view.headSha -cne $Sha -or $view.event -cne 'workflow_dispatch' -or $view.displayTitle -cne $title -or $view.conclusion -cne 'success') { Throw-P08HostedRule 'P08-HOSTED-RUN-BINDING' 'Terminal run binding drifted.' }
  $view
}

function Receive-P08HostedArtifact {
  param([object]$Run,[string]$Repo,[string]$Prefix,[string]$StoreKind,[object]$Store,[string]$Operation,[string]$PreparedDigest,[string]$Module)
  $response=((Invoke-P08Gh @('api',"repos/$Repo/actions/runs/$($Run.databaseId)/artifacts")) -join "`n") | ConvertFrom-Json -Depth 30
  $selected=Select-P08Artifact -Response $response -Prefix $Prefix
  $download=Join-Path ([IO.Path]::GetTempPath()) ('mnf-p08-download-' + [Guid]::NewGuid().ToString('N'))
  try {
    $null=New-Item -ItemType Directory -Path $download
    $null=Invoke-P08Gh @('run','download',[string]$Run.databaseId,'--repo',$Repo,'--name',[string]$selected.name,'--dir',$download)
    $files=@(Get-ChildItem -LiteralPath $download -Recurse -File -Filter '*.json')
    if ($files.Count -ne 1) { Throw-P08HostedRule 'P08-HOSTED-ARTIFACT-CONTENT' 'Sanitized artifact must contain exactly one JSON file.' }
    $value=Get-Content -LiteralPath $files[0].FullName -Raw | ConvertFrom-Json -Depth 100
    Assert-P08HostedEvidence -Operation $Operation -Evidence $value -Run $Run -Store $Store -PreparedDigest $PreparedDigest -Module $Module
    $record=Add-P08ArtifactRecord -Store $Store -Kind $StoreKind -RunId ([string]$Run.databaseId) -RunAttempt ([int]$Run.attempt) -ArtifactName ([string]$selected.name) -SourcePath $files[0].FullName
    [pscustomobject]@{ value=$value; record=$record; github_artifact_id=[string]$selected.id; github_artifact_digest=[string]$selected.digest }
  } finally { if(Test-Path $download){Remove-Item -LiteralPath $download -Recurse -Force} }
}

if(-not $LibraryOnly -and (-not [string]::IsNullOrWhiteSpace($HandoffPath) -or -not [string]::IsNullOrWhiteSpace($TempRoot))){
  Throw-P08HostedRule 'P08-HANDOFF-PRODUCTION-OVERRIDE' 'Production handoff and temp roots are fixed and cannot be overridden.'
}
if ($LibraryOnly) { return }
$script:GhCommand=$GhCommand
$script:GitCommand=$GitCommand
$script:PrepareProvider=$PrepareProvider
if ($Mode -ceq 'InitializeBoundary') {
  if ($Repository -cne 'tchivs/moonbit-foundation' -or $Workflow -cne 'publish-modules.yml' -or [string]::IsNullOrWhiteSpace($ExecutionRoot) -or
      [string]::IsNullOrWhiteSpace($BoundarySha) -or [string]::IsNullOrWhiteSpace($StateRoot)) {
    Throw-P08HostedRule 'P08-BOUNDARY-INITIALIZE' 'InitializeBoundary requires the exact repository/workflow plus boundary SHA, execution root, and state root.'
  }
  New-P08BoundaryLocator -Root $ExecutionRoot -Boundary $BoundarySha -State $StateRoot
  return
}
if($Mode -ceq 'PrepareAttempt'){
  if([string]::IsNullOrWhiteSpace($BoundaryLocatorPath)){Throw-P08HostedRule 'P08-PREPARE-MISSING-BINDING' 'PrepareAttempt requires: BoundaryLocatorPath.'}
  $boundary=Open-P08BoundaryLocator -Locator $BoundaryLocatorPath -Operation $Mode
  if((-not [string]::IsNullOrWhiteSpace($Repository) -and $Repository -cne [string]$boundary.repository) -or
      (-not [string]::IsNullOrWhiteSpace($Workflow) -and $Workflow -cne [string]$boundary.workflow) -or
      (-not [string]::IsNullOrWhiteSpace($BoundarySha) -and $BoundarySha -cne [string]$boundary.boundary_sha) -or
      (-not [string]::IsNullOrWhiteSpace($ExecutionRoot) -and [IO.Path]::GetFullPath($ExecutionRoot) -cne [IO.Path]::GetFullPath([string]$boundary.execution_root))){
    Throw-P08HostedRule 'P08-PREPARE-BOUNDARY-BINDING' 'Caller-supplied boundary fields disagree with the durable locator.'
  }
  New-P08PreparedAttempt -Boundary $boundary
  return
}
$laterBindings=[ordered]@{
  ReleaseRef=$ReleaseRef;SourceSha=$SourceSha;RootIntentSha256=$RootIntentSha256;IntentSha256=$IntentSha256
  PreparedManifestSha256=$PreparedManifestSha256;TargetModule=$TargetModule;BoundaryLocatorPath=$BoundaryLocatorPath;LocatorPath=$LocatorPath;ArtifactRoot=$ArtifactRoot
}
$missingBindings=@($laterBindings.GetEnumerator() | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.Value) } | ForEach-Object Key)
if ($missingBindings.Count -ne 0) { Throw-P08HostedRule 'P08-HOSTED-MISSING-BINDING' ('Mode ' + $Mode + ' requires: ' + ($missingBindings -join ', ') + '.') }
$boundary=Open-P08BoundaryLocator -Locator $BoundaryLocatorPath -Operation $Mode
if((-not [string]::IsNullOrWhiteSpace($Repository) -and $Repository -cne [string]$boundary.repository) -or
    (-not [string]::IsNullOrWhiteSpace($Workflow) -and $Workflow -cne [string]$boundary.workflow) -or
    (-not [string]::IsNullOrWhiteSpace($BoundarySha) -and $BoundarySha -cne [string]$boundary.boundary_sha) -or
    $SourceSha -cne [string]$boundary.boundary_sha){Throw-P08HostedRule 'P08-HOSTED-BOUNDARY-BINDING' 'Later-mode binding disagrees with the durable boundary.'}
$Repository=[string]$boundary.repository
$Workflow=[string]$boundary.workflow
$BoundarySha=[string]$boundary.boundary_sha
$ExecutionRoot=[string]$boundary.execution_root
if ($ReleaseRef -cne 'refs/tags/modules-v0.1.0-r7' -or $SourceSha -cnotmatch '^[0-9a-f]{40}$' -or $RootIntentSha256 -cnotmatch '^[0-9a-f]{64}$' -or
    $IntentSha256 -cnotmatch '^[0-9a-f]{64}$' -or $PreparedManifestSha256 -cnotmatch '^[0-9a-f]{64}$') {
  Throw-P08HostedRule 'P08-HOSTED-R7-BINDING' 'Only the exact r7 release binding is accepted.'
}
$store=Open-P08BoundaryStore -Locator $LocatorPath -Artifacts $ArtifactRoot -Operation $Mode
switch ($Mode) {
  'MaterializePublicSurface' {
    if ([string]::IsNullOrWhiteSpace($ObservationPhase) -or $null -eq $SurfaceProvider) { Throw-P08HostedRule 'P08-SURFACE-PARAMETERS' 'MaterializePublicSurface requires a phase and structured provider.' }
    if ($TargetModule -cne 'mb-core' -and [string]::IsNullOrWhiteSpace($PriorAuthorityRecordPath)) { Throw-P08HostedRule 'P08-PREDECESSOR-REQUIRED' 'Successor surface materialization requires predecessor authority.' }
    $value=& $SurfaceProvider $TargetModule $ObservationPhase
    Assert-P08NoSecretShape $value
    if ((@($value.PSObject.Properties.Name)-join ',') -cne 'schema_version,attempts' -or $value.schema_version -cne '1.0.0') { Throw-P08HostedRule 'P08-SURFACE-CLOSED' 'Structured public surface projection is not closed.' }
    $path=Join-Path $ArtifactRoot "surfaces/$TargetModule/$ObservationPhase/public-surface.json"
    Write-P08ExclusiveJson $path $value
    $digest=Get-P08Sha256 $path
    $record=Add-P08SanitizedArtifact -Store $store -Kind PublicSurface -Module $TargetModule -Phase $ObservationPhase -SourcePath $path -FileDigest $digest -ContentDigest $digest -PriorAuthorityPath $PriorAuthorityRecordPath
    [pscustomobject][ordered]@{fixture_path=[IO.Path]::GetFullPath($path);file_sha256=$digest;index_record=$record};return
  }
  'IndexSanitizedArtifact' {
    if ([string]::IsNullOrWhiteSpace($ObservationPhase) -or [string]::IsNullOrWhiteSpace($ArtifactPath)) { Throw-P08HostedRule 'P08-INDEX-PARAMETERS' 'IndexSanitizedArtifact requires phase and path.' }
    Add-P08SanitizedArtifact -Store $store -Kind $ArtifactKind -Module $TargetModule -Phase $ObservationPhase -SourcePath $ArtifactPath -FileDigest $ArtifactFileSha256 -ContentDigest $ArtifactContentSha256 -PriorAuthorityPath $PriorAuthorityRecordPath
    return
  }
  'ObserveOnly' {
    if ([string]::IsNullOrWhiteSpace($ObservationRecordPath)) { Throw-P08HostedRule 'P08-OBSERVE-PATH' 'ObserveOnly requires an indexed observation record.' }
    $observation=Get-Content -LiteralPath $ObservationRecordPath -Raw | ConvertFrom-Json -Depth 100
    Resolve-P08ObservationOutcome -Observation $observation -Module $TargetModule -PriorAuthorityPath $PriorAuthorityRecordPath
    return
  }
  'AssembleAuthorizationPacket' {
    if ($TargetModule -cne 'mb-core' -or [string]::IsNullOrWhiteSpace($ObservationRecordPath)) { Throw-P08HostedRule 'P08-PACKET-CORE-ONLY' 'MutationAuthorizationPacket is core-entry only.' }
    $observation=Get-Content -LiteralPath $ObservationRecordPath -Raw | ConvertFrom-Json -Depth 100
    if ($observation.outcome -cne 'absent') { Throw-P08HostedRule 'P08-PACKET-ABSENT' 'Only confirmed absent core can assemble mutation authorization.' }
    $records=@($store.index.records);foreach($kind in @('HostedPreflight','PublisherDryRun','Observation')){if(@($records|Where-Object kind -ceq $kind).Count -ne 1){Throw-P08HostedRule 'P08-PACKET-EVIDENCE' "Exactly one $kind record is required."}}
    $history=Get-ReleaseInitialHistoryBinding
    $packet=[pscustomobject][ordered]@{schema_version='mnf-phase08-mutation-authorization-packet/1';repository=$Repository;release_ref=$ReleaseRef;boundary_sha=$BoundarySha;source_sha=$SourceSha;execution_root=[string]$store.locator.execution_root;locator_sha256=[string]$store.locator.locator_sha256;root_intent_sha256=$RootIntentSha256;intent_sha256=$IntentSha256;prepared_manifest_sha256=$PreparedManifestSha256;historical_attempt_zero_sha256=$history.historical_attempt_zero_sha256;historical_r1_sha256=$history.historical_r1_sha256;historical_r2_sha256=$history.historical_r2_sha256;historical_r3_sha256=$history.historical_r3_sha256;historical_r4_sha256=$history.historical_r4_sha256;historical_r5_sha256=$history.historical_r5_sha256;historical_r6_sha256=$history.historical_r6_sha256;historical_history_set_sha256=$history.historical_history_set_sha256;target_module='mb-core';observation_sha256=(Get-P08Sha256 $ObservationRecordPath);hosted_preflight_sha256=[string](@($records|Where-Object kind -ceq 'HostedPreflight')[0].file_sha256);publisher_dry_run_sha256=[string](@($records|Where-Object kind -ceq 'PublisherDryRun')[0].file_sha256);actor='tchivs';mutation_count=0;packet_sha256=''}
    $packet.packet_sha256=Get-P08SelfExcludingDigest $packet 'packet_sha256'
    $packetPath=Join-Path $ArtifactRoot 'authorization/mutation-authorization-packet.json';Write-P08ExclusiveJson $packetPath $packet
    [pscustomobject][ordered]@{packet_path=$packetPath;packet_sha256=[string]$packet.packet_sha256};return
  }
  'PersistAuthorizationReceipt' {
    if($TargetModule -cne 'mb-core' -or [string]::IsNullOrWhiteSpace($MutationAuthorizationPacketPath) -or
       [string]::IsNullOrWhiteSpace($AttemptZeroHistoryPath) -or [string]::IsNullOrWhiteSpace($R1HistoryPath) -or [string]::IsNullOrWhiteSpace($R2HistoryPath) -or [string]::IsNullOrWhiteSpace($R3HistoryPath) -or [string]::IsNullOrWhiteSpace($R4HistoryPath) -or [string]::IsNullOrWhiteSpace($R5HistoryPath) -or [string]::IsNullOrWhiteSpace($R6HistoryPath)){
      Throw-P08HostedRule 'P08-RECEIPT-BINDINGS' 'Core packet and all six terminal-negative histories are required.'
    }
    $receiptFull=Join-Path $ArtifactRoot 'authorization/authorization-receipt.json'
    $activeFull=Join-Path $ArtifactRoot 'active-attempt.json'
    $stamp=if($null-eq$CreatedAt){[DateTime]::UtcNow}else{$CreatedAt}
    $receipt=Write-P08AuthorizationReceipt -PacketPath $MutationAuthorizationPacketPath -ReceiptPath $receiptFull -BoundarySha $BoundarySha -Response $AuthorizationResponse -CreatedAt $stamp
    $bindings=[pscustomobject][ordered]@{
      boundary_sha=$BoundarySha;execution_root=$ExecutionRoot;boundary_locator_path=$BoundaryLocatorPath;artifact_root=$ArtifactRoot;artifact_index_path=[string]$store.locator.index_path
      attempt_zero_history_path=$AttemptZeroHistoryPath;r1_history_path=$R1HistoryPath;r2_history_path=$R2HistoryPath;r3_history_path=$R3HistoryPath;r4_history_path=$R4HistoryPath;r5_history_path=$R5HistoryPath;r6_history_path=$R6HistoryPath;historical_history_set_sha256=(Get-ReleaseInitialHistoryBinding).historical_history_set_sha256;mutation_authorization_packet_path=$MutationAuthorizationPacketPath
      authorization_receipt_path=$receiptFull;exact_existing_authority_path=$null
    }
    $active=Write-P08ActiveAttempt -Path $activeFull -Bindings $bindings -AuthorityVariant mutation_authorized -UpdatedAt $stamp
    [pscustomobject][ordered]@{receipt_path=$receiptFull;receipt_sha256=[string]$receipt.receipt_sha256;active_attempt_path=$activeFull;active_attempt_sha256=[string]$active.active_attempt_sha256};return
  }
  'WriteHandoff' {
    if([string]::IsNullOrWhiteSpace($AttemptZeroHistoryPath) -or [string]::IsNullOrWhiteSpace($R1HistoryPath) -or [string]::IsNullOrWhiteSpace($R2HistoryPath) -or [string]::IsNullOrWhiteSpace($R3HistoryPath) -or [string]::IsNullOrWhiteSpace($R4HistoryPath) -or [string]::IsNullOrWhiteSpace($R5HistoryPath) -or [string]::IsNullOrWhiteSpace($R6HistoryPath)){Throw-P08HostedRule 'P08-HANDOFF-HISTORY' 'All seven terminal-negative histories are required.'}
    $activeFull=Join-Path $ArtifactRoot 'active-attempt.json'
    $stamp=if($null-eq$CreatedAt){[DateTime]::UtcNow}else{$CreatedAt}
    if(-not(Test-Path -LiteralPath $activeFull -PathType Leaf)){
      if($AuthorityVariant -cne 'exact_existing' -or [string]::IsNullOrWhiteSpace($ExactExistingAuthorityPath)){Throw-P08HostedRule 'P08-HANDOFF-ACTIVE' 'Only an exact-existing branch may create a packet-free active attempt.'}
      $bindings=[pscustomobject][ordered]@{
        boundary_sha=$BoundarySha;execution_root=$ExecutionRoot;boundary_locator_path=$BoundaryLocatorPath;artifact_root=$ArtifactRoot;artifact_index_path=[string]$store.locator.index_path
        attempt_zero_history_path=$AttemptZeroHistoryPath;r1_history_path=$R1HistoryPath;r2_history_path=$R2HistoryPath;r3_history_path=$R3HistoryPath;r4_history_path=$R4HistoryPath;r5_history_path=$R5HistoryPath;r6_history_path=$R6HistoryPath;historical_history_set_sha256=(Get-ReleaseInitialHistoryBinding).historical_history_set_sha256;mutation_authorization_packet_path=$null
        authorization_receipt_path=$null;exact_existing_authority_path=$ExactExistingAuthorityPath
      }
      $null=Write-P08ActiveAttempt -Path $activeFull -Bindings $bindings -AuthorityVariant exact_existing -UpdatedAt $stamp
    }
    $fixed=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r7-handoff.json'))
    Write-P08HostedHandoff -ActiveAttemptPath $activeFull -HandoffPath $fixed -CreatedAt $stamp;return
  }
  'SelectExactExistingAuthority' {
    if ([string]::IsNullOrWhiteSpace($ObservationRecordPath) -or [string]::IsNullOrWhiteSpace($ColdProofPath)) { Throw-P08HostedRule 'P08-EXACT-PATHS' 'Exact-existing selection requires observation and cold proof.' }
    $record=New-P08ExactExistingAuthority -Store $store -Module $TargetModule -ObservationPath $ObservationRecordPath -ColdPath $ColdProofPath -PriorAuthorityPath $PriorAuthorityRecordPath -ReducerPath $ReducerRecordPath -HistoricalNegativePath $HistoricalNegativeRecordPath
    $record.authority_sha256=Get-P08SelfExcludingDigest $record 'authority_sha256'
    $path=Join-Path $ArtifactRoot "authority/$TargetModule/exact-existing.json";Write-P08ExclusiveJson $path $record
    [pscustomobject][ordered]@{authority_path=$path;authority_sha256=[string]$record.authority_sha256;source='exact_existing'};return
  }
  'SelectPublishedNowAuthority' {
    if ([string]::IsNullOrWhiteSpace($ObservationRecordPath) -or [string]::IsNullOrWhiteSpace($ColdProofPath)) { Throw-P08HostedRule 'P08-PUBLISHED-PATHS' 'Published-now selection requires observation and cold proof.' }
    if ($TargetModule -ceq 'mb-core') { $null=Select-P08AuthorityUnion -MutationPacketPath $MutationAuthorizationPacketPath -ExactAuthorityPath '' }
    elseif ([string]::IsNullOrWhiteSpace($PriorAuthorityRecordPath)) { Throw-P08HostedRule 'P08-PREDECESSOR-REQUIRED' 'Published successor requires explicit predecessor authority.' }
    $base=New-P08ExactExistingAuthority -Store $store -Module $TargetModule -ObservationPath $ObservationRecordPath -ColdPath $ColdProofPath -PriorAuthorityPath $PriorAuthorityRecordPath -ReducerPath $ReducerRecordPath -HistoricalNegativePath $HistoricalNegativeRecordPath
    $base.schema_version='mnf-phase08-module-authority/1';$base.source='published_now';$base.mutation_authorization_required=$true;$base.mutation_authorization_used=$true;$base.mutation_count=1;$base.authorization_packet_sha256=if($TargetModule -ceq 'mb-core'){Get-P08Sha256 $MutationAuthorizationPacketPath}else{$null};$base.authority_sha256=Get-P08SelfExcludingDigest $base 'authority_sha256'
    $path=Join-Path $ArtifactRoot "authority/$TargetModule/published-now.json";Write-P08ExclusiveJson $path $base
    [pscustomobject][ordered]@{authority_path=$path;authority_sha256=[string]$base.authority_sha256;source='published_now'};return
  }
  'PublishOne' {
    $union=Select-P08AuthorityUnion -MutationPacketPath $MutationAuthorizationPacketPath -ExactAuthorityPath $ExactExistingAuthorityPath
    if ($union.variant -ceq 'ExactExistingAuthority') { Throw-P08HostedRule 'P08-NO-REPUBLISH' 'Exact-existing authority cannot reach PublishOne.' }
    if ($TargetModule -cne 'mb-core' -and [string]::IsNullOrWhiteSpace($PriorAuthorityRecordPath)) { Throw-P08HostedRule 'P08-PREDECESSOR-REQUIRED' 'Successor PublishOne requires explicit predecessor authority.' }
  }
}
$run=Invoke-P08HostedDispatch -Operation $Mode -Repo $Repository -WorkflowPath $Workflow -Ref $ReleaseRef -Sha $SourceSha -RootIntent $RootIntentSha256 -CurrentIntent $IntentSha256 -PreparedDigest $PreparedManifestSha256 -Module $TargetModule -PriorId $PriorRunId -PriorArtifact $PriorArtifactName -Packet $MutationAuthorizationPacketPath -Receipt $AuthorizationReceiptPath -AttemptZeroHistory $AttemptZeroHistoryPath -R1History $R1HistoryPath -R2History $R2HistoryPath -R3History $R3HistoryPath -R4History $R4HistoryPath -R5History $R5HistoryPath -R6History $R6HistoryPath
$prefix=if($Mode -ceq 'PublisherDryRun'){'mnf-publisher-dry-run-'}elseif($Mode -ceq 'HostedPreflight'){'mnf-hosted-preflight-'}else{'mnf-checkpoint-'}
$kind=if($Mode -ceq 'PublisherDryRun'){'PublisherDryRun'}elseif($Mode -ceq 'HostedPreflight'){'HostedPreflight'}else{'PublishOne'}
$artifact=Receive-P08HostedArtifact -Run $run -Repo $Repository -Prefix $prefix -StoreKind $kind -Store $store -Operation $Mode -PreparedDigest $PreparedManifestSha256 -Module $TargetModule
[pscustomobject][ordered]@{mode=$Mode;run_id=[string]$run.databaseId;run_attempt=[int]$run.attempt;conclusion=[string]$run.conclusion;artifact_name=[string]$artifact.record.artifact_name;artifact_sha256=[string]$artifact.record.sha256;artifact_path=[string]$artifact.record.path;evidence=$artifact.value}
