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
  [switch]$R6ContractOnly,
  [string]$LocatorPath,
  [string]$ArtifactRoot,
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
$productionHandoff=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r6-handoff.json'))

function Throw-P08Qualification([string]$Id,[string]$Message) { throw "$Id`: $Message" }
function Get-P08QualificationSha([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Throw-P08Qualification 'P08-QUAL-FILE' "Missing '$Path'." }
  (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}
function Assert-P08ClosedNames([object]$Value,[string[]]$Names,[string]$Id) {
  if ((@($Value.PSObject.Properties.Name) -join ',') -cne ($Names -join ',')) { Throw-P08Qualification $Id 'Closed field inventory drifted.' }
}
function Assert-P08R6Contract {
  if(Test-Path -LiteralPath $productionHandoff){Throw-P08Qualification 'P08-FIXED-HANDOFF-PREEXISTING' 'Production fixed handoff must be absent before qualification fixtures.'}
  . (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')
  foreach($command in @('New-ReleaseAuthorizationReceipt','Assert-ReleaseAuthorizationReceipt','New-ReleasePhase08Handoff','Assert-ReleasePhase08Handoff')) {
    if($null -eq (Get-Command $command -CommandType Function -ErrorAction SilentlyContinue)){Throw-P08Qualification 'P08-R2-COMPOSITION' "Missing $command."}
  }
  $prepared=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'New-PreparedReleaseBundle.ps1') -Raw
  foreach($required in @('refs/tags/modules-v0.1.0-r6','HistoricalAttemptZeroSha256','HistoricalR1Sha256','HistoricalR2Sha256','HistoricalR3Sha256','HistoricalR4Sha256','HistoricalR5Sha256','HistoricalHistorySetSha256','PREP14-HISTORICAL-BINDING')){
    if($prepared.IndexOf($required,[StringComparison]::Ordinal) -lt 0){Throw-P08Qualification 'P08-R6-PREPARED' "Missing prepared r6 contract '$required'."}
  }
  $qualification=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-ReleaseQualification.ps1') -Raw
  if($qualification.IndexOf('refs/tags/modules-v0.1.0-r6',[StringComparison]::Ordinal) -lt 0){Throw-P08Qualification 'P08-R6-QUALIFICATION' 'Qualification does not emit r6 initial identity.'}
  $hosted=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-Phase08HostedRun.ps1') -Raw
  foreach($required in @('refs/tags/modules-v0.1.0-r6','R5HistoryPath','historical_attempts_sha256','authorization_receipt_sha256','mnf-phase08-r6-handoff.json')){
    if($hosted.IndexOf($required,[StringComparison]::Ordinal) -lt 0){Throw-P08Qualification 'P08-R6-HOSTED' "Missing hosted r6 seam '$required'."}
  }
  if($hosted.IndexOf('mnf-phase08-r5-handoff.json',[StringComparison]::Ordinal) -ge 0){Throw-P08Qualification 'P08-R6-HOSTED' 'Hosted production path still names the r5 handoff.'}
  $qualificationSource=Get-Content -LiteralPath $PSCommandPath -Raw
  if($qualificationSource -cnotmatch '(?m)^\s*& git -c core[.]autocrlf=false clone --quiet --no-hardlinks --no-tags [$]repoRoot [$]prepareExecutionRoot\s*$'){Throw-P08Qualification 'P08-R5-LF-NO-TAGS' 'Qualification fixture clone must force LF-safe checkout behavior and exclude permanent tags.'}
  function Confirm-R2Failure([string]$Id,[scriptblock]$Action){$failure=$null;try{&$Action}catch{$failure=$_.Exception.Message};if($null -eq $failure -or -not $failure.StartsWith("$Id`: ",[StringComparison]::Ordinal)){Throw-P08Qualification 'P08-R2-NEGATIVE' "Expected $Id, got '$failure'."}}
  function Write-R2File([string]$Path,[string]$Text){$null=New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path);[IO.File]::WriteAllText($Path,$Text,[Text.UTF8Encoding]::new($false))}
  $temp=Join-Path ([IO.Path]::GetTempPath()) ('mnf-phase08-r2-contract-'+[Guid]::NewGuid().ToString('N'))
  $null=New-Item -ItemType Directory -Force -Path $temp
  try{
    $paths=[ordered]@{}
    foreach($name in @('boundary','active','index','attempt-zero','r1','r2','r3','r4','r5','packet','exact')){$paths[$name]=Join-Path $temp "$name.json";Write-R2File $paths[$name] "fixture-$name"}
    $control=Get-Content -LiteralPath (Join-Path $repoRoot 'policy/release-control.json') -Raw|ConvertFrom-Json -Depth 100
    $history=@($control.initial_attempt_family.terminal_negative_history)
    for($i=0;$i -lt $history.Count;$i++){
      $projection=[ordered]@{};foreach($property in $history[$i].PSObject.Properties){if($property.Name -cne 'record_sha256'){$projection[$property.Name]=$property.Value}}
      Write-R2File $paths[@('attempt-zero','r1','r2','r3','r4','r5')[$i]] ($projection|ConvertTo-Json -Depth 30 -Compress)
    }
    $packetSha=Get-P08QualificationSha $paths.packet
    $receiptA=New-ReleaseAuthorizationReceipt -BoundarySha ('1'*40) -SourceSha ('2'*40) -PacketSha256 $packetSha -CreatedAt '2026-07-19T08:00:00+08:00'
    $receiptB=New-ReleaseAuthorizationReceipt -BoundarySha ('1'*40) -SourceSha ('2'*40) -PacketSha256 $packetSha -CreatedAt '2026-07-19T00:00:00Z'
    $receiptChanged=New-ReleaseAuthorizationReceipt -BoundarySha ('1'*40) -SourceSha ('2'*40) -PacketSha256 $packetSha -CreatedAt '2026-07-19T00:00:01Z'
    if($receiptA.created_at_utc -cne '2026-07-19T00:00:00Z' -or $receiptA.receipt_sha256 -cne $receiptB.receipt_sha256 -or $receiptA.receipt_sha256 -ceq $receiptChanged.receipt_sha256){Throw-P08Qualification 'P08-R2-UTC' 'UTC equivalence or changed-instant identity drifted.'}
    $receiptPath=Join-Path $temp 'receipt.json';Write-R2File $receiptPath ($receiptA|ConvertTo-Json -Depth 20 -Compress)
    $receiptReload=Get-Content -LiteralPath $receiptPath -Raw|ConvertFrom-Json -Depth 20
    $null=Assert-ReleaseAuthorizationReceipt -Receipt $receiptReload -ExpectedBoundarySha ('1'*40) -ExpectedSourceSha ('2'*40) -ExpectedPacketSha256 $packetSha
    $bindings=[ordered]@{
      schema_version='mnf-phase08-handoff/1';release_ref='refs/tags/modules-v0.1.0-r6';boundary_sha=('1'*40);execution_root=[IO.Path]::GetFullPath($temp)
      boundary_locator_path=[IO.Path]::GetFullPath($paths.boundary);boundary_locator_sha256=Get-P08QualificationSha $paths.boundary
      active_attempt_path=[IO.Path]::GetFullPath($paths.active);active_attempt_sha256=Get-P08QualificationSha $paths.active
      artifact_root=[IO.Path]::GetFullPath($temp);artifact_index_path=[IO.Path]::GetFullPath($paths.index);artifact_index_sha256=Get-P08QualificationSha $paths.index
      attempt_zero_history_path=[IO.Path]::GetFullPath($paths.'attempt-zero');attempt_zero_history_sha256=Get-P08QualificationSha $paths.'attempt-zero'
      r1_history_path=[IO.Path]::GetFullPath($paths.r1);r1_history_sha256=Get-P08QualificationSha $paths.r1
      r2_history_path=[IO.Path]::GetFullPath($paths.r2);r2_history_sha256=Get-P08QualificationSha $paths.r2
      r3_history_path=[IO.Path]::GetFullPath($paths.r3);r3_history_sha256=Get-P08QualificationSha $paths.r3
      r4_history_path=[IO.Path]::GetFullPath($paths.r4);r4_history_sha256=Get-P08QualificationSha $paths.r4
      r5_history_path=[IO.Path]::GetFullPath($paths.r5);r5_history_sha256=Get-P08QualificationSha $paths.r5
      historical_history_set_sha256=[string]$control.initial_attempt_family.history_set_sha256
      mutation_authorization_packet_path=[IO.Path]::GetFullPath($paths.packet);mutation_authorization_packet_sha256=$packetSha
      authorization_receipt_path=[IO.Path]::GetFullPath($receiptPath);authorization_receipt_sha256=Get-P08QualificationSha $receiptPath
      exact_existing_authority_path=$null;exact_existing_authority_sha256=$null
    }
    $mutation=New-ReleasePhase08Handoff -Bindings $bindings -AuthorityVariant mutation_authorized -CreatedAt '2026-07-19T08:00:00+08:00'
    $mutationPath=Join-Path $temp 'mutation-handoff.json';Write-R2File $mutationPath ($mutation|ConvertTo-Json -Depth 30 -Compress)
    $mutationJson=Get-Content -LiteralPath $mutationPath -Raw
    if(-not($mutationJson|Test-Json -SchemaFile (Join-Path $repoRoot 'release/qualification/phase-08-handoff-schema.json') -ErrorAction Stop)){Throw-P08Qualification 'P08-R2-SCHEMA' 'Mutation handoff failed schema.'}
    $null=Assert-ReleasePhase08Handoff -Handoff ($mutationJson|ConvertFrom-Json -Depth 30)
    $exactBindings=[ordered]@{};foreach($entry in $bindings.GetEnumerator()){$exactBindings[$entry.Key]=$entry.Value}
    $exactBindings.mutation_authorization_packet_path=$null;$exactBindings.mutation_authorization_packet_sha256=$null;$exactBindings.authorization_receipt_path=$null;$exactBindings.authorization_receipt_sha256=$null
    $exactBindings.exact_existing_authority_path=[IO.Path]::GetFullPath($paths.exact);$exactBindings.exact_existing_authority_sha256=Get-P08QualificationSha $paths.exact
    $exact=New-ReleasePhase08Handoff -Bindings $exactBindings -AuthorityVariant exact_existing -CreatedAt '2026-07-19T00:00:00Z'
    $exactJson=$exact|ConvertTo-Json -Depth 30 -Compress
    if(-not($exactJson|Test-Json -SchemaFile (Join-Path $repoRoot 'release/qualification/phase-08-handoff-schema.json') -ErrorAction Stop)){Throw-P08Qualification 'P08-R2-SCHEMA' 'Exact-existing handoff failed schema.'}
    $null=Assert-ReleasePhase08Handoff -Handoff ($exactJson|ConvertFrom-Json -Depth 30)
    foreach($case in @(
      @{id='REL04-HANDOFF-CLOSED';mutate={param($x)$x|Add-Member unexpected x}},
      @{id='REL04-HANDOFF-PATH';mutate={param($x)$x.boundary_locator_path='relative.json'}},
      @{id='REL04-HANDOFF-PATH';mutate={param($x)$x.boundary_locator_path=[IO.Path]::GetFullPath((Join-Path $temp '..\escape.json'))}},
      @{id='REL04-HANDOFF-DIGEST';mutate={param($x)$x.r1_history_sha256='f'*64}},
      @{id='REL04-HISTORY-BINDING';mutate={param($x)$x.r3_history_path=$x.r2_history_path;$x.r3_history_sha256=$x.r2_history_sha256}},
      @{id='REL04-HISTORY-BINDING';mutate={param($x)$x.historical_history_set_sha256='f'*64}},
      @{id='REL04-HANDOFF-BRANCH';mutate={param($x)$x.authorization_receipt_path=$null;$x.authorization_receipt_sha256=$null}},
      @{id='REL04-HANDOFF-BRANCH';mutate={param($x)$x.authority_variant='stop'}}
    )){$copy=$mutation|ConvertTo-Json -Depth 30|ConvertFrom-Json -Depth 30;&$case.mutate $copy;Confirm-R2Failure $case.id {Assert-ReleasePhase08Handoff $copy|Out-Null}}
    $receiptOnExact=$exact|ConvertTo-Json -Depth 30|ConvertFrom-Json -Depth 30;$receiptOnExact.authorization_receipt_path=[IO.Path]::GetFullPath($receiptPath);$receiptOnExact.authorization_receipt_sha256=Get-P08QualificationSha $receiptPath
    Confirm-R2Failure 'REL04-HANDOFF-BRANCH' {Assert-ReleasePhase08Handoff $receiptOnExact|Out-Null}
    $badReceipt=$receiptA|ConvertTo-Json -Depth 20|ConvertFrom-Json -Depth 20;$badReceipt.packet_sha256='f'*64
    Confirm-R2Failure 'REL04-RECEIPT-BINDING' {Assert-ReleaseAuthorizationReceipt $badReceipt -ExpectedBoundarySha ('1'*40) -ExpectedSourceSha ('2'*40) -ExpectedPacketSha256 $packetSha|Out-Null}
    $mixedReceipt=$receiptA|ConvertTo-Json -Depth 20|ConvertFrom-Json -Depth 20;$mixedReceipt.historical_r3_sha256=$mixedReceipt.historical_r2_sha256
    Confirm-R2Failure 'REL04-HISTORY-BINDING' {Assert-ReleaseAuthorizationReceipt $mixedReceipt|Out-Null}
  }finally{if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Recurse -Force}}
  if(Test-Path -LiteralPath $productionHandoff){Throw-P08Qualification 'P08-FIXED-HANDOFF-CREATED' 'Qualification fixtures touched the production fixed handoff.'}
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
    'PriorAuthorityRecordPath','refs/tags/modules-v0.1.0-r6','R5HistoryPath','historical_attempts_sha256','authorization_receipt_sha256','P08-HOSTED-AMBIGUOUS-RUN','P08-HOSTED-AMBIGUOUS-ARTIFACT',
    'P08-STORE-UNINDEXED','P08-STORE-RESUME-DRIFT','P08-AUTHORITY-BOTH','P08-AUTHORITY-NEITHER'
  )) {
    if ($helper.IndexOf($required,[StringComparison]::Ordinal) -lt 0) { Throw-P08Qualification 'P08-QUAL-HELPER' "Missing helper contract '$required'." }
  }
  foreach($required in @('operation_mode:','prepared_manifest_sha256:','target_module:','PublisherDryRun','HostedPreflight','PublishOne','publish --frozen --dry-run','native_runtime_verified')) {
    if ($workflow.IndexOf($required,[StringComparison]::Ordinal) -lt 0) { Throw-P08Qualification 'P08-QUAL-WORKFLOW' "Missing workflow contract '$required'." }
  }
  if (@([regex]::Matches($workflow,[regex]::Escape('${{ secrets.MOONCAKES_TOKEN }}'))).Count -ne 2) { Throw-P08Qualification 'P08-QUAL-SECRET' 'Secret must occur once in dry-run and once in PublishOne, each in isolated jobs.' }
  if ($workflow.IndexOf('moon publish --frozen`n',[StringComparison]::Ordinal) -ge 0) { Throw-P08Qualification 'P08-QUAL-NONDRY' 'An unclassified inline non-dry command is forbidden.' }
  $schema=Get-Content -LiteralPath $authoritySchema -Raw | ConvertFrom-Json -Depth 100
  foreach($definition in @('mutationAuthorizationPacket','exactExistingAuthority','moduleAuthority')) {
    if ($null -eq $schema.'$defs'.PSObject.Properties[$definition] -or $schema.'$defs'.$definition.additionalProperties -ne $false) { Throw-P08Qualification 'P08-QUAL-AUTHORITY-SCHEMA' "Authority definition '$definition' is missing or open." }
  }

  $boundary='1'*40
  . (Join-Path $PSScriptRoot 'Invoke-Phase08HostedRun.ps1') -Mode InitializeBoundary -Repository tchivs/moonbit-foundation -Workflow publish-modules.yml `
    -ReleaseRef refs/tags/modules-v0.1.0-r6 -SourceSha $boundary -RootIntentSha256 ('a'*64) -IntentSha256 ('a'*64) `
    -PreparedManifestSha256 ('b'*64) -TargetModule mb-core -LocatorPath $LocatorPath -ArtifactRoot $ArtifactRoot -LibraryOnly

  function Confirm-P08FixtureFailure([string]$Id,[scriptblock]$Action) {
    $failure=$null;try{& $Action}catch{$failure=$_.Exception.Message}
    if ($null -eq $failure -or -not $failure.StartsWith("$Id`: ",[StringComparison]::Ordinal)) { Throw-P08Qualification 'P08-QUAL-NEGATIVE' "Expected $Id, got '$failure'." }
  }

  $boundaryState=Join-Path ([IO.Path]::GetTempPath()) ('mnf-phase08-boundary-fixture-' + [Guid]::NewGuid().ToString('N'))
  $dispatchProbe=[pscustomobject]@{called=$false}
  $ghFixture={ $dispatchProbe.called=$true }.GetNewClosure()
  $gitFixture={
    param($root,$arguments)
    switch($arguments[0]) {
      'status' { '' }
      'rev-parse' { if($arguments[1] -ceq 'HEAD'){$boundary}else{'2'*40} }
      'hash-object' { '2'*40 }
    }
  }.GetNewClosure()
  try {
    $initialized=& (Join-Path $PSScriptRoot 'Invoke-Phase08HostedRun.ps1') -Mode InitializeBoundary -Repository tchivs/moonbit-foundation `
      -Workflow publish-modules.yml -BoundarySha $boundary -ExecutionRoot $repoRoot -StateRoot $boundaryState -GitCommand $gitFixture
    $boundaryLocatorPath=Join-Path $boundaryState 'boundary-locator.json'
    $boundaryLocator=Get-Content -LiteralPath $boundaryLocatorPath -Raw | ConvertFrom-Json -Depth 100
    $boundaryNames=@('schema_version','repository','workflow','boundary_sha','execution_root','state_root','locator_path','artifact_root','index_path','created_at_utc','locator_sha256')
    if ((@($boundaryLocator.PSObject.Properties.Name)-join ',') -cne ($boundaryNames-join ',') -or
        $boundaryLocator.schema_version -cne 'mnf-phase08-boundary-locator/1' -or $boundaryLocator.boundary_sha -cne $boundary -or
        $boundaryLocator.execution_root -cne [IO.Path]::GetFullPath($repoRoot) -or $boundaryLocator.state_root -cne [IO.Path]::GetFullPath($boundaryState) -or
        $boundaryLocator.locator_path -cne [IO.Path]::GetFullPath($boundaryLocatorPath) -or -not (Test-Path -LiteralPath ([string]$boundaryLocator.artifact_root) -PathType Container)) {
      Throw-P08Qualification 'P08-QUAL-BOUNDARY-INITIALIZE' 'Minimal InitializeBoundary did not create the exact durable boundary binding.'
    }
    $boundaryLocatorDigest=Get-P08ObjectDigest (Get-P08BoundaryLocatorProjection $boundaryLocator)
    if ($boundaryLocator.locator_sha256 -cne $boundaryLocatorDigest) {
      $memoryProjection=Get-P08CanonicalJson (Get-P08BoundaryLocatorProjection $initialized)
      $diskProjection=Get-P08CanonicalJson (Get-P08BoundaryLocatorProjection $boundaryLocator)
      Throw-P08Qualification 'P08-QUAL-BOUNDARY-DIGEST' "Boundary locator digest drifted: stored=$($boundaryLocator.locator_sha256), calculated=$boundaryLocatorDigest, memory=$memoryProjection, disk=$diskProjection."
    }
    $boundaryIndex=Get-Content -LiteralPath ([string]$boundaryLocator.index_path) -Raw | ConvertFrom-Json -Depth 100
    if ((@($boundaryIndex.PSObject.Properties.Name)-join ',') -cne 'schema_version,repository,workflow,boundary_sha,records' -or
        $boundaryIndex.schema_version -cne 'mnf-phase08-boundary-index/1' -or @($boundaryIndex.records).Count -ne 0 -or $boundaryIndex.boundary_sha -cne $boundary -or
        @(Get-ChildItem -LiteralPath ([string]$boundaryLocator.artifact_root) -Recurse -File).Count -ne 1) {
      Throw-P08Qualification 'P08-QUAL-BOUNDARY-INDEX' 'Boundary root/index is not closed, empty, and boundary-bound.'
    }
    foreach($laterMode in @('PrepareAttempt','HostedPreflight','PublisherDryRun','MaterializePublicSurface','ObserveOnly','IndexSanitizedArtifact','AssembleAuthorizationPacket','SelectExactExistingAuthority','SelectPublishedNowAuthority','PublishOne')) {
      $laterFailure=$null
      try {
        & (Join-Path $PSScriptRoot 'Invoke-Phase08HostedRun.ps1') -Mode $laterMode -Repository tchivs/moonbit-foundation `
          -Workflow publish-modules.yml -GhCommand $ghFixture -GitCommand $gitFixture
      } catch { $laterFailure=$_.Exception.Message }
      $expectedMissing=if($laterMode -ceq 'PrepareAttempt'){'P08-PREPARE-MISSING-BINDING'}else{'P08-HOSTED-MISSING-BINDING'}
      if ($null -eq $laterFailure -or $dispatchProbe.called -or $laterFailure -notmatch $expectedMissing) {
        Throw-P08Qualification 'P08-QUAL-LATER-MODE-OPEN' "Incomplete $laterMode did not fail closed before dispatch: '$laterFailure'."
      }
    }
  } finally {
    if (Test-Path -LiteralPath $boundaryState) { Remove-Item -LiteralPath $boundaryState -Recurse -Force }
  }

  $prepareFixtureRoot=Join-Path ([IO.Path]::GetTempPath()) ('mnf-phase08-prepare-fixture-' + [Guid]::NewGuid().ToString('N'))
  try {
    $prepareExecutionRoot=Join-Path $prepareFixtureRoot 'execution'
    $prepareStateRoot=Join-Path $prepareFixtureRoot 'state'
    & git -c core.autocrlf=false clone --quiet --no-hardlinks --no-tags $repoRoot $prepareExecutionRoot
    if($LASTEXITCODE){Throw-P08Qualification 'P08-QUAL-PREPARE-CLONE' 'Unable to create the local-only PrepareAttempt execution clone.'}
    foreach($relative in @('scripts/quality/Invoke-Phase08HostedRun.ps1','scripts/quality/New-PreparedReleaseBundle.ps1')){
      Copy-Item -LiteralPath (Join-Path $repoRoot $relative) -Destination (Join-Path $prepareExecutionRoot $relative) -Force
    }
    & git -C $prepareExecutionRoot config user.name 'MNF fixture'
    & git -C $prepareExecutionRoot config user.email 'fixture@moonbit-foundation.invalid'
    & git -C $prepareExecutionRoot add -- scripts/quality/Invoke-Phase08HostedRun.ps1 scripts/quality/New-PreparedReleaseBundle.ps1
    & git -C $prepareExecutionRoot commit --quiet --allow-empty -m 'test: prepare attempt fixture boundary'
    if($LASTEXITCODE){Throw-P08Qualification 'P08-QUAL-PREPARE-COMMIT' 'Unable to create the local-only PrepareAttempt fixture boundary.'}
    $prepareBoundary=(& git -C $prepareExecutionRoot rev-parse HEAD).Trim()
    & git -C $prepareExecutionRoot tag modules-v0.1.0-r6 $prepareBoundary
    if($LASTEXITCODE){Throw-P08Qualification 'P08-QUAL-PREPARE-TAG' 'Unable to create the local-only r6 fixture tag.'}
    $prepareHosted=Join-Path $prepareExecutionRoot 'scripts/quality/Invoke-Phase08HostedRun.ps1'
    $prepareBoundaryLocator=& $prepareHosted -Mode InitializeBoundary -Repository tchivs/moonbit-foundation -Workflow publish-modules.yml `
      -BoundarySha $prepareBoundary -ExecutionRoot $prepareExecutionRoot -StateRoot $prepareStateRoot

    $prepareProvider={
      param($Context)
      $qualificationRoot=Join-Path ([string]$Context.work_root) 'qualification'
      $archivePaths=@{}
      $archiveDigests=@{}
      foreach($module in @('mb-core','mb-color','mb-image')){
        $archivePath=Join-Path ([string]$Context.work_root) "archives/$module.zip"
        $null=New-Item -ItemType Directory -Force (Split-Path -Parent $archivePath)
        [IO.File]::WriteAllText($archivePath,"fixture archive $module",[Text.UTF8Encoding]::new($false))
        $archivePaths[$module]=$archivePath
        $archiveDigests[$module]=(Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
      }
      $intent=& (Join-Path ([string]$Context.execution_root) 'scripts/quality/New-ReleaseIntent.ps1') -Check -IntentKind initial `
        -ReleaseRef refs/tags/modules-v0.1.0-r6 -SourceSha ([string]$Context.boundary_sha) -SourceRoot ([string]$Context.execution_root) `
        -QualificationRootSha256 ('3'*64) -RequiredStableSha256 ('4'*64) -ArchiveSha256ByModule $archiveDigests `
        -OutputDirectory (Join-Path $qualificationRoot 'intent')
      $binding=[pscustomobject][ordered]@{
        schema_version='mnf-release-intent-binding/1';intent_kind='initial';release_ref='refs/tags/modules-v0.1.0-r6'
        source_sha=[string]$Context.boundary_sha;root_intent_sha256=[string]$intent.intent_sha256;intent_sha256=[string]$intent.intent_sha256
        qualification_root_sha256=('3'*64);required_stable_sha256=('4'*64);phase_06_ledger_sha256=('5'*64);interface_manifest_sha256=('6'*64)
        credentials_read=$false;publication_performed=$false
      }
      $null=New-Item -ItemType Directory -Force $qualificationRoot
      [IO.File]::WriteAllText((Join-Path $qualificationRoot 'release-intent-binding.json'),($binding|ConvertTo-Json -Depth 20 -Compress),[Text.UTF8Encoding]::new($false))
      $moonPath=(Get-Command moon -CommandType Application -ErrorAction Stop).Source
      [pscustomobject][ordered]@{
        qualification_root=$qualificationRoot
        archive_paths=$archivePaths
        toolchain_root=Split-Path -Parent (Split-Path -Parent $moonPath)
        native_toolchain_bin=''
      }
    }.GetNewClosure()
    $prepared=& $prepareHosted -Mode PrepareAttempt -BoundaryLocatorPath ([string]$prepareBoundaryLocator.locator_path) `
      -ReleaseRef refs/tags/modules-v0.1.0-r6 `
      -HistoricalReleaseRef refs/tags/modules-v0.1.0-r5 -HistoricalSourceSha df105f06205298f1f82ac2f2cdca214d69d42e15 `
      -PrepareProvider $prepareProvider
    $preparedNames=@('mode','locator_path','artifact_root','index_path','root_intent_sha256','intent_sha256','prepared_manifest_sha256','historical_record_path','attempt_zero_history_path','r1_history_path','r2_history_path','r3_history_path','r4_history_path','r5_history_path','historical_history_set_sha256','genesis_record_path','prepared_root','toolchain_root','native_toolchain_bin','mutation_count')
    if((@($prepared.PSObject.Properties.Name)-join ',') -cne ($preparedNames-join ',') -or $prepared.mode -cne 'PrepareAttempt' -or
        $prepared.root_intent_sha256 -cne $prepared.intent_sha256 -or $prepared.root_intent_sha256 -cnotmatch '^[0-9a-f]{64}$' -or
        $prepared.prepared_manifest_sha256 -cnotmatch '^[0-9a-f]{64}$' -or [int]$prepared.mutation_count -ne 0){
      Throw-P08Qualification 'P08-QUAL-PREPARE-RESULT' 'PrepareAttempt did not return the exact fresh r6 binding.'
    }
    $prepareLocator=Get-Content -LiteralPath ([string]$prepared.locator_path) -Raw|ConvertFrom-Json -Depth 100
    $prepareIndex=Get-Content -LiteralPath ([string]$prepared.index_path) -Raw|ConvertFrom-Json -Depth 100
    if($prepareLocator.schema_version -cne 'mnf-phase08-live-locator/2' -or $prepareLocator.boundary_sha -cne $prepareBoundary -or
        $prepareLocator.release_ref -cne 'refs/tags/modules-v0.1.0-r6' -or $prepareLocator.root_intent_sha256 -cne $prepared.root_intent_sha256 -or
        $prepareLocator.prepared_manifest_sha256 -cne $prepared.prepared_manifest_sha256 -or $prepareIndex.schema_version -cne 'mnf-phase08-artifact-index/2' -or
        @($prepareIndex.records|Where-Object kind -ceq 'HistoricalNegative').Count -ne 6 -or @($prepareIndex.records|Where-Object kind -ceq 'GenesisJournal').Count -ne 1 -or
        @($prepareIndex.records|Where-Object kind -ceq 'PreparedManifest').Count -ne 1){
      Throw-P08Qualification 'P08-QUAL-PREPARE-STORE' 'PrepareAttempt locator/index/store evidence is incomplete.'
    }
    $historical=Get-Content -LiteralPath ([string]$prepared.historical_record_path) -Raw|ConvertFrom-Json -Depth 100
    $genesis=Get-Content -LiteralPath ([string]$prepared.genesis_record_path) -Raw|ConvertFrom-Json -Depth 100
    if($null -ne $historical.run_id -or $null -ne $historical.run_attempt -or $historical.hosted_run_present -ne $false -or
        $historical.release_ref -cne 'refs/tags/modules-v0.1.0-r5' -or $historical.source_sha -cne 'df105f06205298f1f82ac2f2cdca214d69d42e15' -or
        $historical.reason -cne 'terminal_workflow_duplicate_environment_key' -or $historical.hosted_preflight_dispatch_attempted -ne $true -or $historical.hosted_preflight_dispatched -ne $false -or
        $historical.publish_run_count -ne 0 -or $historical.mutation_performed -ne $false -or $historical.authority_acquired -ne $false -or $genesis.schema_version -cne 'mnf-release-journal-record/1' -or
        $genesis.journal_sequence -ne 0 -or $genesis.state -cne 'intent_authorized' -or $genesis.root_intent_sha256 -cne $prepared.root_intent_sha256){
      Throw-P08Qualification 'P08-QUAL-PREPARE-EVIDENCE' 'PrepareAttempt historical or genesis evidence drifted.'
    }
    & (Join-Path $prepareExecutionRoot 'scripts/quality/New-PreparedReleaseBundle.ps1') -ValidateOnly -OutputRoot ([string]$prepared.prepared_root) `
      -Repository tchivs/moonbit-foundation -Actor tchivs -RunId 1 -RunAttempt 1 -ReleaseRef refs/tags/modules-v0.1.0-r6 `
      -SourceSha $prepareBoundary -RootIntentSha256 ([string]$prepared.root_intent_sha256) -IntentSha256 ([string]$prepared.intent_sha256) -RunMode start `
      -HistoricalAttemptZeroSha256 (Get-P08QualificationSha ([string]$prepared.attempt_zero_history_path)) -HistoricalR1Sha256 (Get-P08QualificationSha ([string]$prepared.r1_history_path)) `
      -HistoricalR2Sha256 (Get-P08QualificationSha ([string]$prepared.r2_history_path)) -HistoricalR3Sha256 (Get-P08QualificationSha ([string]$prepared.r3_history_path)) -HistoricalR4Sha256 (Get-P08QualificationSha ([string]$prepared.r4_history_path)) -HistoricalR5Sha256 (Get-P08QualificationSha ([string]$prepared.r5_history_path)) -HistoricalHistorySetSha256 ([string]$prepared.historical_history_set_sha256) | Out-Null

    $missingState=Join-Path $prepareFixtureRoot 'missing-state'
    $missingBoundary=& $prepareHosted -Mode InitializeBoundary -Repository tchivs/moonbit-foundation -Workflow publish-modules.yml `
      -BoundarySha $prepareBoundary -ExecutionRoot $prepareExecutionRoot -StateRoot $missingState
    Confirm-P08FixtureFailure 'P08-PREPARE-MISSING-BINDING' {
      & $prepareHosted -Mode PrepareAttempt -BoundaryLocatorPath ([string]$missingBoundary.locator_path) -ReleaseRef refs/tags/modules-v0.1.0-r6 `
        -HistoricalReleaseRef refs/tags/modules-v0.1.0-r5 -PrepareProvider $prepareProvider
    }
    $mismatchState=Join-Path $prepareFixtureRoot 'mismatch-state'
    $mismatchBoundary=& $prepareHosted -Mode InitializeBoundary -Repository tchivs/moonbit-foundation -Workflow publish-modules.yml `
      -BoundarySha $prepareBoundary -ExecutionRoot $prepareExecutionRoot -StateRoot $mismatchState
    Confirm-P08FixtureFailure 'P08-PREPARE-HISTORICAL-BINDING' {
      & $prepareHosted -Mode PrepareAttempt -BoundaryLocatorPath ([string]$mismatchBoundary.locator_path) -ReleaseRef refs/tags/modules-v0.1.0-r6 `
        -HistoricalReleaseRef refs/tags/modules-v0.1.0-r5 -HistoricalSourceSha ('9'*40) -PrepareProvider $prepareProvider
    }
  } finally {
    if(Test-Path -LiteralPath $prepareFixtureRoot){Remove-Item -LiteralPath $prepareFixtureRoot -Recurse -Force}
  }
  $cases=@{
    absent='mutation_candidate';exact='exact_existing';mismatch='terminal_forward_correction';unknown='terminal_stop'
  }
  foreach($outcome in @('absent','exact','mismatch','unknown')) {
    $decision=Resolve-P08ObservationOutcome -Observation ([pscustomobject]@{outcome=$outcome}) -Module mb-core
    if ($decision.classification -cne $cases[$outcome] -or ($outcome -cne 'absent' -and $decision.may_assemble_packet)) { Throw-P08Qualification 'P08-QUAL-OUTCOME' "Closed outcome '$outcome' drifted." }
  }
  foreach($reason in @('disagreement','timeout')) {
    $decision=Resolve-P08ObservationOutcome -Observation ([pscustomobject]@{outcome='unknown';reason=$reason}) -Module mb-core
    if ($decision.classification -cne 'terminal_stop' -or -not $decision.terminal) { Throw-P08Qualification 'P08-QUAL-OUTCOME' "$reason did not stop." }
  }
  Confirm-P08FixtureFailure 'P08-OUTCOME-CLOSED' { Resolve-P08ObservationOutcome -Observation ([pscustomobject]@{outcome='retry'}) -Module mb-core }
  Confirm-P08FixtureFailure 'P08-PREDECESSOR-REQUIRED' { Resolve-P08ObservationOutcome -Observation ([pscustomobject]@{outcome='absent'}) -Module mb-color }
  Confirm-P08FixtureFailure 'P08-AUTHORITY-BOTH' { Select-P08AuthorityUnion -MutationPacketPath 'packet.json' -ExactAuthorityPath 'exact.json' }
  Confirm-P08FixtureFailure 'P08-AUTHORITY-NEITHER' { Select-P08AuthorityUnion -MutationPacketPath '' -ExactAuthorityPath '' }

  $script:GitCommand={param($root,$arguments) switch($arguments[0]){'status'{''};'rev-parse'{if($arguments[1] -ceq 'HEAD'){$script:boundary}else{'2'*40}};'hash-object'{'2'*40}}}
  $script:boundary=$boundary
  $boundaryResult=Assert-P08ExecutionBoundary -Root $repoRoot -Boundary $boundary -RelativePaths @('scripts/quality/Invoke-Phase08HostedRun.ps1')
  if ($boundaryResult.execution_root -cne [IO.Path]::GetFullPath($repoRoot)) { Throw-P08Qualification 'P08-QUAL-BOUNDARY' 'Execution root was not canonicalized.' }
  $script:GitCommand={param($root,$arguments) if($arguments[0] -ceq 'status'){' M drift'}elseif($arguments[1] -ceq 'HEAD'){$script:boundary}else{'2'*40}}
  Confirm-P08FixtureFailure 'P08-BOUNDARY-DIRTY' { Assert-P08ExecutionBoundary -Root $repoRoot -Boundary $boundary -RelativePaths @() }
  $script:GitCommand=$null
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

function Assert-P08AuthorityFile {
  param([Parameter(Mandatory)][string]$Path,[string[]]$AllowedSchemas)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Throw-P08Qualification 'P08-QUAL-AUTHORITY-FILE' "Missing authority file '$Path'." }
  $schemaPath=Join-Path $repoRoot 'release/qualification/phase-08-authority-schema.json'
  $json=Get-Content -LiteralPath $Path -Raw
  if (-not ($json|Test-Json -SchemaFile $schemaPath -ErrorAction Stop)) { Throw-P08Qualification 'P08-QUAL-AUTHORITY-SCHEMA' 'Authority record failed its closed schema.' }
  $record=$json|ConvertFrom-Json -Depth 100
  if ($AllowedSchemas -cnotcontains [string]$record.schema_version -or $record.repository -cne 'tchivs/moonbit-foundation' -or $record.release_ref -cne 'refs/tags/modules-v0.1.0-r6' -or
      $record.boundary_sha -cne $record.source_sha -or $record.root_intent_sha256 -cne $record.intent_sha256 -or $record.prepared_manifest_sha256 -cnotmatch '^[0-9a-f]{64}$') {
    Throw-P08Qualification 'P08-QUAL-AUTHORITY-BINDING' 'Authority record binding drifted.'
  }
  if ($record.schema_version -ceq 'mnf-phase08-exact-existing-authority/1' -and
      ($record.source -cne 'exact_existing' -or $record.mutation_authorization_required -ne $false -or $record.mutation_authorization_used -ne $false -or
       $record.publisher_dry_run_used -ne $false -or [int]$record.mutation_count -ne 0 -or $null -ne $record.authorization_packet_sha256)) {
    Throw-P08Qualification 'P08-QUAL-EXACT-NO-MUTATION' 'Exact-existing authority contains mutation or dry-run authorization.'
  }
  if ((@($record.targets)-join ',') -cne 'js,wasm,wasm-gc,native' -or $record.native_runtime -cne 'pass') { Throw-P08Qualification 'P08-QUAL-AUTHORITY-COLD' 'Authority does not bind the exact four-target native proof.' }
  $record
}

function Assert-P08AuthorityUnionSelector {
  $packetPath=if(-not [string]::IsNullOrWhiteSpace($MutationAuthorizationPacketPath)){$MutationAuthorizationPacketPath}else{$PacketPath}
  $hasPacket=-not [string]::IsNullOrWhiteSpace($packetPath);$hasExact=-not [string]::IsNullOrWhiteSpace($ExactExistingAuthorityPath)
  if($hasPacket -and $hasExact){Throw-P08Qualification 'P08-QUAL-AUTHORITY-BOTH' 'AuthorityUnion rejects both variants.'}
  if(-not $hasPacket -and -not $hasExact){Throw-P08Qualification 'P08-QUAL-AUTHORITY-NEITHER' 'AuthorityUnion rejects neither variant.'}
  if($hasPacket){
    $json=Get-Content -LiteralPath $packetPath -Raw
    if(-not ($json|Test-Json -SchemaFile (Join-Path $repoRoot 'release/qualification/phase-08-authority-schema.json') -ErrorAction Stop)){Throw-P08Qualification 'P08-QUAL-PACKET-SCHEMA' 'MutationAuthorizationPacket failed schema.'}
    $record=$json|ConvertFrom-Json -Depth 100
    if($record.schema_version -cne 'mnf-phase08-mutation-authorization-packet/1' -or $record.target_module -cne 'mb-core' -or [int]$record.mutation_count -ne 0){Throw-P08Qualification 'P08-QUAL-PACKET-BINDING' 'MutationAuthorizationPacket drifted.'}
    Write-Host 'Phase 8 MutationAuthorizationPacket selector: PASS.';return $record
  }
  $record=Assert-P08AuthorityFile -Path $ExactExistingAuthorityPath -AllowedSchemas @('mnf-phase08-exact-existing-authority/1')
  Write-Host 'Phase 8 ExactExistingAuthority selector: PASS.';return $record
}

if (-not ($FixtureOnly -or $CoreColorArtifacts -or $LiveArtifacts -or $AuthorizationPacket -or $MutationAuthorizationPacket -or $ExactExistingAuthority -or $AuthorityUnion -or $ReciprocalArtifacts -or $R6ContractOnly)) { $R6ContractOnly=$true }
if($R6ContractOnly){Assert-P08R6Contract;Write-Host 'Phase 8 r6 receipt/handoff composition: PASS.';return}
if ($FixtureOnly) { Assert-P08FixtureContract; return }
if ($AuthorizationPacket) { Assert-P08AuthorizationPacket; return }
if ($MutationAuthorizationPacket -or $ExactExistingAuthority -or $AuthorityUnion) { Assert-P08AuthorityUnionSelector; return }
if ($CoreColorArtifacts -or $LiveArtifacts -or $ReciprocalArtifacts) {
  $paths=@($CoreAuthorityRecordPath,$ColorAuthorityRecordPath,$ImageAuthorityRecordPath | Where-Object {-not [string]::IsNullOrWhiteSpace($_)})
  $minimum=if($ReciprocalArtifacts){3}elseif($CoreColorArtifacts){2}else{1}
  if($paths.Count -lt $minimum){Throw-P08Qualification 'P08-QUAL-AUTHORITY-PATHS' "Selector requires at least $minimum explicit normalized authority records."}
  $expected=@('mb-core','mb-color','mb-image')
  for($i=0;$i -lt $paths.Count;$i++){
    $record=Assert-P08AuthorityFile -Path $paths[$i] -AllowedSchemas @('mnf-phase08-exact-existing-authority/1','mnf-phase08-module-authority/1')
    if($record.module -cne $expected[$i]){Throw-P08Qualification 'P08-QUAL-AUTHORITY-ORDER' 'Authority records are not in canonical predecessor order.'}
    if($i -gt 0 -and [string]$record.predecessor_authority_sha256 -cne (Get-P08QualificationSha $paths[$i-1])){Throw-P08Qualification 'P08-QUAL-PREDECESSOR' 'Successor authority does not bind the unique predecessor file.'}
  }
  Write-Host 'Phase 8 normalized authority artifacts selector: PASS.';return
}
$store=Open-P08QualificationStore
$requiredKinds=if($CoreColorArtifacts){@('publisher-dry-run','hosted-preflight')}else{@('publisher-dry-run','hosted-preflight','absence-observation')}
foreach($kind in $requiredKinds) { if (@($store.index.records|Where-Object kind -ceq $kind).Count -ne 1) { Throw-P08Qualification 'P08-QUAL-LIVE-ARTIFACT' "Expected one '$kind' record." } }
Write-Host 'Phase 8 indexed artifact selector: PASS.'
