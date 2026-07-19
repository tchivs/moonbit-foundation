[CmdletBinding()]
param(
  [switch]$AdapterOnly,
  [switch]$WorkflowOnly,
  [switch]$HostedFieldsOnly,
  [switch]$PreflightOnly,
  [string]$LocatorPath,
  [string]$ArtifactRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$publisherSource=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-ReleasePublisher.ps1') -Raw
$adapterSource=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-MooncakesLiveMutation.ps1') -Raw
foreach($source in @($publisherSource,$adapterSource)){
  foreach($required in @('refs/tags/modules-v0.1.0-r12','historical_r11_sha256')){
    if($source.IndexOf($required,[StringComparison]::Ordinal)-lt 0){throw "P08-LIVE-R12-STATIC: missing '$required'."}
  }
}
$productionHandoff=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r11-handoff.json'))
if(Test-Path -LiteralPath $productionHandoff){throw 'P08-FIXED-HANDOFF-PREEXISTING: production fixed handoff must be absent before static fixtures.'}
$hostedSource=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-Phase08HostedRun.ps1') -Raw
foreach($required in @('refs/tags/modules-v0.1.0-r11','R10HistoryPath','historical_r10_sha256','mnf-phase08-r11-handoff.json','Copy-P08CanonicalPreparedArchive','ValidatePreAuthorization')){
  if($hostedSource.IndexOf($required,[StringComparison]::Ordinal) -lt 0){throw "P08-R10-HOSTED-STATIC: missing '$required'."}
}
if($hostedSource.IndexOf('mnf-phase08-r9-handoff.json',[StringComparison]::Ordinal) -ge 0){throw 'P08-R10-HOSTED-STATIC: prior fixed handoff remains reachable.'}

$adapterPath = Join-Path $PSScriptRoot 'Invoke-MooncakesLiveMutation.ps1'
if (-not (Test-Path -LiteralPath $adapterPath -PathType Leaf)) {
  throw 'P08-LIVE-ADAPTER-MISSING: tracked one-step adapter is required.'
}
. $adapterPath -LibraryOnly

function Confirm-LiveRule {
  param([string]$Id, [scriptblock]$Action)
  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure -or -not $failure.StartsWith("$Id`: ", [StringComparison]::Ordinal)) {
    throw "Live seam negative '$Id' passed or failed for the wrong reason: '$failure'."
  }
}

function New-LiveTestRequest {
  [pscustomobject][ordered]@{
    repository='tchivs/moonbit-foundation'; actor='tchivs'; actor_evidence=[pscustomobject][ordered]@{
      expected_actor='tchivs';observed_actor='tchivs';actor_check_classification='moon_whoami_exact';actor_exit_code=0
      actor_stdout_line_count=1;actor_stderr_empty=$true;actor_match=$true;actor_raw_output_persisted=$false
      credential_state_removed=$true;mutation_performed=$false;command_classification='moon_whoami_dry_run_only'
    }; release_ref='refs/tags/modules-v0.1.0-r11'
    source_sha=('1'*40); root_intent_sha256=('a'*64); intent_sha256=('a'*64); intent_kind='initial'
    prepared_manifest_sha256=('b'*64)
    historical_attempt_zero_sha256='b9bda5378ea339f4cdd42c417c1cc0cf8caabbd51ab11d453cd45ddae77d9b52'
    historical_r1_sha256='cba047dae2e6b4e1bbf0248653ed7848f144971b54a0a4ed30ef42ab97325653'
    historical_r2_sha256='aae8bee66e7dbfca7f3f22f1b52071e7888ae3ec8feee513d1c5d8eba6111609'
    historical_r3_sha256='cf29473b2b07ff9aa8fd8a4810ddc45f6aacd2fd4b74048f5d29b3b6fa939d41'
    historical_r4_sha256='d9b045bc65df87dc2701144ea7716defc67acb84ec9ea8e7ffdafd0118ba0906'
    historical_r5_sha256='1239b63f983bef86ac44c731171093ad67759de9cce7c15610b92f5df6214843'
    historical_r6_sha256='3f9c0d9916dbccfa9144488d2967ee1a7fb3fd1d9936f8cc4139c2734f2d0ad4'
    historical_r7_sha256='baf5d4921c75b2ba4a64cd234663a1b7086d6c45a653edd1ce4a63f56882933f'
    historical_r8_sha256='8a7729234a62425d0082a7b7a4615f2757ab4bc59938925b8ca031e2e00c10c8'
    historical_r9_sha256='6edf89e7afb98dca1e81e3d5db9ff8a47f96dbfb2919bdaeb176c76c52c581ec'
    historical_r10_sha256='1d524890dd5f0c11e58bcd2884c2d4623e02759a5ff801f2554fcc2ae654895f'
    historical_history_set_sha256='45330d06dec5aca59c07d592ca851c4441cf43d0e35014f9734b2746c293a41d'
    correction_sequence=0; predecessor_intent_sha256=$null; authorization_valid=$true
    evidence_valid=$true; dry_run_passed=$true; authority_account='tchivs'
  }
}

function New-LiveTestCommand {
  param([int]$Sequence,[string]$Prior,[string]$State,[string]$Operation,[AllowNull()][string]$Module=$null)
  [pscustomobject][ordered]@{
    journal_sequence=$Sequence; prior_record_sha256=$Prior; root_intent_sha256=('a'*64); intent_sha256=('a'*64)
    intent_kind='initial'; correction_sequence=0; predecessor_intent_sha256=$null; state=$State; module=$Module
    operation=$Operation; observation=[pscustomobject][ordered]@{ status='not_observed'; identity='not_applicable'; reason_code='none'; reobservation_required=$false }
    outcome=if ($State -clike '*checkpoint_verified') { 'checkpoint_verified' } elseif ($State -clike '*mutation_attempted') { 'mutation_pending_observation' } else { 'accepted' }
    recorded_at_utc='2026-07-18T00:00:00.0000000Z'
    run_identity=[pscustomobject][ordered]@{ repository='tchivs/moonbit-foundation'; run_id='1001'; artifact_name="publisher-$Sequence"; artifact_sequence=$Sequence }
  }
}

function New-LiveVerifiedChain {
  param([ValidateSet('core','color','image')][string]$Through)
  $records = [Collections.Generic.List[object]]::new()
  $states = @(
    @('intent_authorized','authorize',$null), @('preflight_passed','preflight',$null),
    @('core_mutation_attempted','attempt_mutation','mb-core'), @('core_registry_observed','observe_registry','mb-core'),
    @('core_checkpoint_verified','verify_checkpoint','mb-core')
  )
  if ($Through -ceq 'color') {
    $states += @(
      @('color_mutation_attempted','attempt_mutation','mb-color'), @('color_registry_observed','observe_registry','mb-color'),
      @('color_checkpoint_verified','verify_checkpoint','mb-color')
    )
  }
  if ($Through -ceq 'image') {
    $states += @(
      @('color_mutation_attempted','attempt_mutation','mb-color'), @('color_registry_observed','observe_registry','mb-color'),
      @('color_checkpoint_verified','verify_checkpoint','mb-color'), @('image_mutation_attempted','attempt_mutation','mb-image'),
      @('image_registry_observed','observe_registry','mb-image'), @('image_checkpoint_verified','verify_checkpoint','mb-image')
    )
  }
  $prior = '0' * 64
  for ($i=0; $i -lt $states.Count; $i++) {
    $command = New-LiveTestCommand -Sequence $i -Prior $prior -State $states[$i][0] -Operation $states[$i][1] -Module $states[$i][2]
    if ($command.state -clike '*registry_observed' -or $command.state -clike '*checkpoint_verified') {
      $command.observation.status='exact_match'; $command.observation.identity='exact'; $command.observation.reason_code='registry_exact_match'
    }
    $record = New-PublisherJournalRecord -Command $command
    $records.Add($record); $prior=$record.record_sha256
  }
  @($records)
}

function New-LiveProof {
  param([ValidateSet('mb-core','mb-color','mb-image')][string]$Module)
  $outputDigest='c'*64
  $isolation=[ordered]@{}
  foreach($name in @('consumer_root_outside_checkout','moon_home_initially_empty','credentials_absent','workspace_absent','source_copy_absent','alternate_dependency_source_absent','local_dependency_absent','path_dependency_absent','git_dependency_absent','registry_cache_initially_empty','registry_index_cache_absent','archive_cache_absent','mooncakes_state_absent','target_output_initially_absent','pinned_toolchain_explicit','ambient_toolchain_ignored')){ $isolation[$name]=$true }
  $proof=[pscustomobject][ordered]@{
    schema_version='1.0.0'; evidence_mode='live_registry'; policy_sha256=('b'*64); module=$Module
    identity="tchivs/$Module"; version='0.1.0'; dependency_source='registry_only'
    isolation=[pscustomobject]$isolation
    observation=[pscustomobject][ordered]@{ outcome='exact'; content_sha256=('d'*64); strongest_identity=('sha256:' + ('e'*64)) }
    archive_sha256=('e'*64); downloaded_manifest_sha256=('f'*64)
    resolved_graph=[pscustomobject][ordered]@{ nodes=@(); edges=@() }
    toolchain=[pscustomobject][ordered]@{ moon_version='pinned'; moonc_version='pinned'; moonrun_version='pinned'; root_sha256=('1'*64) }
    targets=@('js','wasm','wasm-gc','native' | ForEach-Object { [pscustomobject][ordered]@{ name=$_; check='pass'; test='pass'; runtime='pass'; output_sha256=$outputDigest } })
    behavior=[pscustomobject][ordered]@{ result='pass'; output_sha256=$outputDigest }; verified=$true; content_sha256=''
  }
  $projection=[ordered]@{}; foreach($property in $proof.PSObject.Properties){ if($property.Name -cne 'content_sha256'){ $projection[$property.Name]=$property.Value } }
  $json=([pscustomobject]$projection | ConvertTo-Json -Depth 100 -Compress)
  $proof.content_sha256=([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($json)))).ToLowerInvariant()
  $proof
}

$request = New-LiveTestRequest
if ((Resolve-MooncakesLiveMutationTarget -Request $request -Records @() -Proofs @()) -cne 'mb-core') { throw 'Empty verified journal did not select core.' }
$coreChain = New-LiveVerifiedChain -Through core
if ((Resolve-MooncakesLiveMutationTarget -Request $request -Records $coreChain -Proofs @((New-LiveProof mb-core))) -cne 'mb-color') { throw 'Verified core did not select color.' }
$colorChain = New-LiveVerifiedChain -Through color
if ((Resolve-MooncakesLiveMutationTarget -Request $request -Records $colorChain -Proofs @((New-LiveProof mb-core),(New-LiveProof mb-color))) -cne 'mb-image') { throw 'Verified color did not select image.' }

Confirm-LiveRule 'LIVE04-INCOMPLETE-PROOF' { Resolve-MooncakesLiveMutationTarget -Request $request -Records $coreChain -Proofs @() }
$duplicateProofs = @((New-LiveProof mb-core),(New-LiveProof mb-core))
Confirm-LiveRule 'LIVE05-AMBIGUOUS' { Resolve-MooncakesLiveMutationTarget -Request $request -Records $coreChain -Proofs $duplicateProofs }

$fixtureRoot=Join-Path ([IO.Path]::GetTempPath()) ('mnf-live-seam-' + [Guid]::NewGuid().ToString('N'))
$sentinel='fixture-token-never-persist'
$calls=[Collections.Generic.List[object]]::new()
try {
  $null=New-Item -ItemType Directory -Path (Join-Path $fixtureRoot 'prepared/archives') -Force
  $source=Join-Path $fixtureRoot 'source'; $null=New-Item -ItemType Directory -Path $source
  [IO.File]::WriteAllText((Join-Path $source 'moon.mod.json'),'{}',[Text.UTF8Encoding]::new($false))
  foreach($module in @('mb-core','mb-color','mb-image')) {
    Compress-Archive -Path (Join-Path $source '*') -DestinationPath (Join-Path $fixtureRoot "prepared/archives/$module.zip")
  }
  $manifest=[pscustomobject][ordered]@{
    repository=$request.repository; actor=$request.actor; release_ref=$request.release_ref; source_sha=$request.source_sha
    root_intent_sha256=$request.root_intent_sha256; intent_sha256=$request.intent_sha256
    historical_attempt_zero_sha256=$request.historical_attempt_zero_sha256;historical_r1_sha256=$request.historical_r1_sha256
    historical_r2_sha256=$request.historical_r2_sha256;historical_r3_sha256=$request.historical_r3_sha256;historical_r4_sha256=$request.historical_r4_sha256;historical_r5_sha256=$request.historical_r5_sha256;historical_r6_sha256=$request.historical_r6_sha256;historical_r7_sha256=$request.historical_r7_sha256;historical_r8_sha256=$request.historical_r8_sha256;historical_r9_sha256=$request.historical_r9_sha256;historical_r10_sha256=$request.historical_r10_sha256;historical_history_set_sha256=$request.historical_history_set_sha256
    payloads=@('mb-core','mb-color','mb-image' | ForEach-Object { [pscustomobject][ordered]@{ path="archives/$_.zip"; role='exact_source_archive'; size=1; sha256=('3'*64) } })
  }
  [IO.File]::WriteAllText((Join-Path $fixtureRoot 'prepared/prepared-bundle.json'),($manifest | ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
  $request.prepared_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $fixtureRoot 'prepared/prepared-bundle.json') -Algorithm SHA256).Hash.ToLowerInvariant()
  $validatorCalls=0
  $validator={ param($root,$prepared,$boundRequest) $script:validatorCalls++; if ($prepared.source_sha -cne $boundRequest.source_sha) { throw 'fixture binding drift' } }
  $fakePublish={
    param($context)
    $script:calls.Add($context)
    $credential=Get-Content -LiteralPath $context.credential_path -Raw | ConvertFrom-Json
    if ($credential.username -cne 'tchivs' -or $credential.token -cne $script:sentinel) { throw 'credential was not exact during child call' }
    if ($context.environment.MOON_HOME -cne $context.moon_home -or $context.environment.MOON_TOOLCHAIN_ROOT -cne [IO.Path]::GetFullPath((Join-Path $script:fixtureRoot 'toolchain'))) { throw 'child environment was not isolated' }
    if (($context.arguments -join ' ') -cne "-C $($context.working_directory) publish --frozen") { throw 'publish arguments drifted' }
    if (($context.arguments -join ' ').Contains($script:sentinel,[StringComparison]::Ordinal)) { throw 'secret entered command arguments' }
    'attempted'
  }
  $result=Invoke-MooncakesLiveMutation -Request $request -Records @() -Proofs @() -PreparedRoot (Join-Path $fixtureRoot 'prepared') -ToolchainRoot (Join-Path $fixtureRoot 'toolchain') -CredentialToken $sentinel -Authorized $true -PublishCommand $fakePublish -PreparedValidator $validator
  if ($result.module -cne 'mb-core' -or $result.mutation_count -ne 1 -or $calls.Count -ne 1 -or $validatorCalls -ne 1 -or
      $result.raw_output_persisted -ne $false -or $result.credential_state_removed -ne $true) { throw 'Eligible adapter did not make exactly one sanitized call.' }
  if (Test-Path -LiteralPath $calls[0].moon_home) { throw 'Credential state survived the successful fake child.' }
  if (($result | ConvertTo-Json -Compress).Contains($sentinel,[StringComparison]::Ordinal)) { throw 'Secret entered adapter diagnostics.' }

  $colorResult=Invoke-MooncakesLiveMutation -Request $request -Records $coreChain -Proofs @((New-LiveProof mb-core)) -PreparedRoot (Join-Path $fixtureRoot 'prepared') -ToolchainRoot (Join-Path $fixtureRoot 'toolchain') -CredentialToken $sentinel -Authorized $true -PublishCommand $fakePublish -PreparedValidator $validator
  $imageResult=Invoke-MooncakesLiveMutation -Request $request -Records $colorChain -Proofs @((New-LiveProof mb-core),(New-LiveProof mb-color)) -PreparedRoot (Join-Path $fixtureRoot 'prepared') -ToolchainRoot (Join-Path $fixtureRoot 'toolchain') -CredentialToken $sentinel -Authorized $true -PublishCommand $fakePublish -PreparedValidator $validator
  if ($colorResult.module -cne 'mb-color' -or $imageResult.module -cne 'mb-image' -or $calls.Count -ne 3 -or $validatorCalls -ne 3) { throw 'Eligible downstream states did not make one dependency-safe call each.' }

  $before=$calls.Count
  Confirm-LiveRule 'LIVE01-AUTHORIZATION' {
    Invoke-MooncakesLiveMutation -Request $request -Records @() -Proofs @() -PreparedRoot (Join-Path $fixtureRoot 'prepared') -ToolchainRoot (Join-Path $fixtureRoot 'toolchain') -CredentialToken $sentinel -Authorized $false -PublishCommand $fakePublish -PreparedValidator $validator
  }
  if ($calls.Count -ne $before) { throw 'Unauthorized path reached fake publish.' }

  $preflightRecords=@($coreChain | Select-Object -First 2)
  $stopped=Invoke-MooncakesLiveMutation -Request $request -Records $preflightRecords -Proofs @() -PreparedRoot (Join-Path $fixtureRoot 'prepared') -ToolchainRoot (Join-Path $fixtureRoot 'toolchain') -CredentialToken $sentinel -Authorized $true -PublishCommand $fakePublish -PreparedValidator $validator
  if ($stopped.mutation_count -ne 0 -or $calls.Count -ne $before) { throw 'Incomplete journal reached fake publish.' }
  $imageChain=New-LiveVerifiedChain -Through image
  $replay=Invoke-MooncakesLiveMutation -Request $request -Records $imageChain -Proofs @((New-LiveProof mb-core),(New-LiveProof mb-color),(New-LiveProof mb-image)) -PreparedRoot (Join-Path $fixtureRoot 'prepared') -ToolchainRoot (Join-Path $fixtureRoot 'toolchain') -CredentialToken $sentinel -Authorized $true -PublishCommand $fakePublish -PreparedValidator $validator
  if ($replay.mutation_count -ne 0 -or $calls.Count -ne $before) { throw 'Verified replay reached fake publish.' }

  $contaminated=New-LiveProof mb-core; $contaminated | Add-Member token $sentinel
  Confirm-LiveRule 'LIVE04-INCOMPLETE-PROOF' { Resolve-MooncakesLiveMutationTarget -Request $request -Records $coreChain -Proofs @($contaminated) }
  if ($calls.Count -ne $before) { throw 'Contaminated proof reached fake publish.' }

  $failureHome=$null
  $failingPublish={ param($context) $script:failureHome=$context.moon_home; throw 'fixture child failed' }
  try {
    Invoke-MooncakesLiveMutation -Request $request -Records @() -Proofs @() -PreparedRoot (Join-Path $fixtureRoot 'prepared') -ToolchainRoot (Join-Path $fixtureRoot 'toolchain') -CredentialToken $sentinel -Authorized $true -PublishCommand $failingPublish -PreparedValidator $validator
    throw 'Failing fake publish unexpectedly passed.'
  } catch {
    if ($_.Exception.Message -cne 'fixture child failed') { throw }
  }
  if ([string]::IsNullOrWhiteSpace($failureHome) -or (Test-Path -LiteralPath $failureHome)) { throw 'Credential state survived the failing fake child.' }

  $preparedText=Get-Content -LiteralPath (Join-Path $fixtureRoot 'prepared/prepared-bundle.json') -Raw
  if ($preparedText.Contains($sentinel,[StringComparison]::Ordinal)) { throw 'Secret entered prepared payloads.' }
} finally {
  if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}

. (Join-Path $PSScriptRoot 'Invoke-ReleasePublisher.ps1') -LibraryOnly
$controllerResult=Invoke-PublisherLiveOneStep -Request $request -Authorized $true -Adapter {
  param($boundRequest)
  if ($boundRequest.intent_sha256 -cne ('a'*64)) { throw 'controller request was not passed to adapter' }
  [pscustomobject][ordered]@{ classification='attempted'; module='mb-core'; mutation_count=1; reobservation_required=$true; raw_output_persisted=$false; credential_state_removed=$true }
}
if ($controllerResult.classification -cne 'attempted' -or $controllerResult.mutation_count -ne 1 -or $controllerResult.raw_output_persisted -ne $false) { throw 'Publisher did not retain only the sanitized adapter projection.' }
Confirm-LiveRule 'PUB14-LIVE-GUARD' { Invoke-PublisherLiveOneStep -Request $request -Authorized $false -Adapter { 'attempted' } }
Confirm-LiveRule 'PUB08-SANITIZE' {
  Invoke-PublisherLiveOneStep -Request $request -Authorized $true -Adapter {
    [pscustomobject][ordered]@{ classification='attempted'; module='mb-core'; mutation_count=2; raw_output_persisted=$false; credential_state_removed=$true }
  }
}

Write-Host 'Phase 8 live adapter fixtures: PASS.'
if ($AdapterOnly) { return }

$workflowPath = Join-Path (Split-Path -Parent $PSScriptRoot) '..\.github\workflows\publish-modules.yml'
$workflow = Get-Content -LiteralPath $workflowPath -Raw

function Assert-P08WorkflowMappingKeyUniqueness {
  param([Parameter(Mandatory)][string]$Source)
  $lines=[regex]::Split($Source,'\r?\n')
  $jobsSeen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $jobsFound=$false
  foreach($line in $lines){
    if($line -ceq 'jobs:'){$jobsFound=$true;continue}
    if($jobsFound -and $line -cmatch '^  (?<key>[A-Za-z_][A-Za-z0-9_-]*):\s*$' -and -not $jobsSeen.Add($Matches.key)){
      throw "P08-WORKFLOW-DUPLICATE-JOB-KEY: '$($Matches.key)'."
    }
  }
  if(-not $jobsFound -or $jobsSeen.Count -eq 0){throw 'P08-WORKFLOW-JOBS: jobs mapping is missing or empty.'}

  for($i=0;$i -lt $lines.Count;$i++){
    if($lines[$i] -cnotmatch '^(?<indent> *)env:\s*$'){continue}
    $childIndent=$Matches.indent.Length+2
    $envSeen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    for($j=$i+1;$j -lt $lines.Count;$j++){
      if([string]::IsNullOrWhiteSpace($lines[$j]) -or $lines[$j] -cmatch '^\s*#'){continue}
      $leading=[regex]::Match($lines[$j],'^ *').Value.Length
      if($leading -le ($childIndent-2)){break}
      if($leading -eq $childIndent -and $lines[$j] -cmatch ('^ {'+$childIndent+'}(?<key>[A-Za-z_][A-Za-z0-9_]*):')){
        if(-not $envSeen.Add($Matches.key)){throw "P08-WORKFLOW-DUPLICATE-ENV-KEY: '$($Matches.key)'."}
      }
    }
  }
}

Assert-P08WorkflowMappingKeyUniqueness -Source $workflow
$expectedDispatchInputs=@(
  'operation_mode','run_mode','release_ref','source_sha','root_intent_sha256','intent_sha256','prepared_manifest_sha256',
  'historical_attempts_sha256','target_module','live_authorization','prior_run_id','prior_artifact_name',
  'authorization_packet_sha256','authorization_receipt_sha256'
)
$dispatchInputMatch=[regex]::Match($workflow,'(?ms)^\s{4}inputs:\r?\n(?<body>.*?)(?=^permissions:)')
if(-not $dispatchInputMatch.Success){throw 'P08-WORKFLOW-DISPATCH-INPUTS: workflow_dispatch input block is missing.'}
$dispatchInputBlock=$dispatchInputMatch.Groups['body'].Value
$actualDispatchInputs=@([regex]::Matches($dispatchInputBlock,'(?m)^\s{6}([a-z0-9_]+):\s*$')|ForEach-Object{$_.Groups[1].Value})
$dispatchInputsSeen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach($dispatchInput in $actualDispatchInputs){
  if(-not $dispatchInputsSeen.Add($dispatchInput)){throw "P08-WORKFLOW-DUPLICATE-DISPATCH-INPUT: '$dispatchInput'."}
}
if($actualDispatchInputs.Count -ne 14 -or ($actualDispatchInputs-join ',') -cne ($expectedDispatchInputs-join ',')){
  throw "P08-WORKFLOW-DISPATCH-PARITY: expected exact 14 inputs '$($expectedDispatchInputs-join ',')', got '$($actualDispatchInputs-join ',')'."
}
$receiptInputMatch=[regex]::Match($dispatchInputBlock,"(?ms)^\s{6}authorization_receipt_sha256:\r?\n(?<body>(?:^\s{8}.*\r?\n?)+)")
if(-not $receiptInputMatch.Success -or $receiptInputMatch.Groups['body'].Value.IndexOf('required: false',[StringComparison]::Ordinal) -lt 0 -or
    $receiptInputMatch.Groups['body'].Value.IndexOf("default: ''",[StringComparison]::Ordinal) -lt 0 -or
    $receiptInputMatch.Groups['body'].Value.IndexOf('type: string',[StringComparison]::Ordinal) -lt 0){
  throw 'P08-WORKFLOW-RECEIPT-OPTIONAL: start must accept an explicitly empty authorization receipt digest.'
}
foreach ($required in @(
  'Invoke-MooncakesLiveMutation','Invoke-ColdRegistryConsumer','MOONCAKES_TOKEN','InitializeBoundary','PrepareAttempt',
  'PublisherDryRun','HostedPreflight','MaterializePublicSurface','ObserveOnly','IndexSanitizedArtifact',
  'AssembleAuthorizationPacket','SelectExactExistingAuthority','SelectPublishedNowAuthority','PublishOne',
  'refs/tags/modules-v0.1.0-r11','historical_attempts_sha256:','historical_r10_sha256','historical_history_set_sha256','publish --frozen --dry-run','native_runtime_verified','whoami.stdout','whoami.stderr',
  'exact_existing','published_now'
)) {
  if ($workflow.IndexOf($required,[StringComparison]::Ordinal) -lt 0) { throw "P08-WORKFLOW-MISSING: '$required'." }
}
if ($workflow.IndexOf("Join-Path `$env:RUNNER_TEMP 'structured-public-surfaces.json'",[StringComparison]::Ordinal) -ge 0) {
  throw 'P08-WORKFLOW-AMBIENT-SURFACE: observer still depends on an undeclared runner-temp file.'
}
$setupCount=@([regex]::Matches($workflow,'(?m)^\s+version: latest\s*$')).Count
$verifyCount=@([regex]::Matches($workflow,'(?m)^\s+- name: Verify exact MoonBit toolchain\s*$')).Count
if ($setupCount -ne 5 -or $verifyCount -ne $setupCount -or $workflow.Contains('version: 0.1.20260713+75c7e1f')) {
  throw 'P08-WORKFLOW-TOOLCHAIN-ROUTE: each hosted setup must use the reachable channel and immediately verify the exact pin.'
}
foreach($pin in @(
  '50913178bee7e904850fc37d5b16adda7e6c1616d2704994714b70ac86f9a7ab',
  '31633647318a571d6aac9a2144a0e1ba3c946ea806d1409778894fe76e604511',
  '44b7d5427837c8c0f7379a9d4fa9f3e1aac0f433041b3ffe16e78e1c5f151ab4',
  '0.1.20260713', '75c7e1f', 'v0.10.4+2cc641edf'
)) {
  if (@([regex]::Matches($workflow,[regex]::Escape($pin))).Count -lt $verifyCount) { throw "P08-WORKFLOW-TOOLCHAIN-PIN: '$pin' is not enforced after every setup." }
}
$publisherStart=$workflow.IndexOf("  publisher:",[StringComparison]::Ordinal)
$observerStart=$workflow.IndexOf("  observe_registry:",[StringComparison]::Ordinal)
$consumerStart=$workflow.IndexOf("  cold_consumer:",[StringComparison]::Ordinal)
if ($publisherStart -lt 0 -or $observerStart -le $publisherStart -or $consumerStart -le $observerStart) { throw 'P08-WORKFLOW-ORDER: publisher observation and consumer jobs are not ordered.' }
$publisherBlock=$workflow.Substring($publisherStart,$observerStart-$publisherStart)
$prepareStart=$workflow.IndexOf("  prepare:",[StringComparison]::Ordinal)
$dryRunStart=$workflow.IndexOf("  publisher_dry_run:",[StringComparison]::Ordinal)
if($prepareStart -lt 0 -or $dryRunStart -le $prepareStart){throw 'P08-WORKFLOW-PREPARE: prepare job block is missing.'}
$prepareBlock=$workflow.Substring($prepareStart,$dryRunStart-$prepareStart)
$propagationContracts=@(
  @($prepareBlock,'AUTHORIZATION_PACKET_SHA256: ${{ inputs.authorization_packet_sha256 }}'),
  @($prepareBlock,'AUTHORIZATION_RECEIPT_SHA256: ${{ inputs.authorization_receipt_sha256 }}'),
  @($prepareBlock,'P08-WORKFLOW-AUTHORITY-PAIR'),
  @($publisherBlock,'EXPECTED_AUTHORIZATION_PACKET_SHA256: ${{ inputs.authorization_packet_sha256 }}'),
  @($publisherBlock,'EXPECTED_AUTHORIZATION_RECEIPT_SHA256: ${{ inputs.authorization_receipt_sha256 }}'),
  @($publisherBlock,'AUTHORIZATION_PACKET_SHA256: ${{ inputs.authorization_packet_sha256 }}'),
  @($publisherBlock,'AUTHORIZATION_RECEIPT_SHA256: ${{ inputs.authorization_receipt_sha256 }}')
)
foreach($contract in $propagationContracts){
  if(([string]$contract[0]).IndexOf([string]$contract[1],[StringComparison]::Ordinal) -lt 0){throw "P08-WORKFLOW-RECEIPT-PROPAGATION: missing '$($contract[1])'."}
}
$observerBlock=$workflow.Substring($observerStart,$consumerStart-$observerStart)
$consumerBlock=$workflow.Substring($consumerStart)
if (@([regex]::Matches($workflow,[regex]::Escape('${{ secrets.MOONCAKES_TOKEN }}'))).Count -ne 2) { throw 'P08-WORKFLOW-SECRET: secret mapping must occur exactly once in each isolated publisher mode.' }
foreach($block in @($observerBlock,$consumerBlock)) {
  if ($block.IndexOf('MOONCAKES_TOKEN',[StringComparison]::Ordinal) -ge 0 -or $block.IndexOf('environment:',[StringComparison]::Ordinal) -ge 0) { throw 'P08-WORKFLOW-SECRET: downstream job can access publisher authority.' }
}
if ($publisherBlock.IndexOf('Invoke-ReleasePublisher.ps1 -Mode LiveOneStep',[StringComparison]::Ordinal) -lt 0 -or
    $publisherBlock.IndexOf('foreach ($module',[StringComparison]::OrdinalIgnoreCase) -ge 0 -or
    $observerBlock.IndexOf('needs: publisher',[StringComparison]::Ordinal) -lt 0 -or
    $consumerBlock.IndexOf('needs: [publisher, observe_registry]',[StringComparison]::Ordinal) -lt 0) { throw 'P08-WORKFLOW-ORDER: one-step dependency chain drifted.' }
$adapterSource=Get-Content -LiteralPath $adapterPath -Raw
if (@([regex]::Matches($adapterSource,"publish','--frozen",[Text.RegularExpressions.RegexOptions]::CultureInvariant)).Count -ne 1 -or
    $adapterSource.IndexOf('foreach($module',[StringComparison]::OrdinalIgnoreCase) -ge 0) { throw 'P08-WORKFLOW-LOOP: adapter is not structurally one-module.' }

$dryStart=$workflow.IndexOf('  publisher_dry_run:',[StringComparison]::Ordinal)
$preflightStart=$workflow.IndexOf('  hosted_preflight:',[StringComparison]::Ordinal)
if ($dryStart -lt 0 -or $preflightStart -le $dryStart -or $publisherStart -le $preflightStart) { throw 'P08-WORKFLOW-MODES: hosted modes are missing or ambiguously ordered.' }
$dryBlock=$workflow.Substring($dryStart,$preflightStart-$dryStart)
$preflightBlock=$workflow.Substring($preflightStart,$publisherStart-$preflightStart)
$expectedR4Env='EXPECTED_HISTORICAL_R4_SHA256: d9b045bc65df87dc2701144ea7716defc67acb84ec9ea8e7ffdafd0118ba0906'
$expectedR5Env='EXPECTED_HISTORICAL_R5_SHA256: 1239b63f983bef86ac44c731171093ad67759de9cce7c15610b92f5df6214843'
$expectedR6Env='EXPECTED_HISTORICAL_R6_SHA256: 3f9c0d9916dbccfa9144488d2967ee1a7fb3fd1d9936f8cc4139c2734f2d0ad4'
$expectedR8Env='EXPECTED_HISTORICAL_R8_SHA256: 8a7729234a62425d0082a7b7a4615f2757ab4bc59938925b8ca031e2e00c10c8'
foreach($contract in @(@('PublisherDryRun',$dryBlock),@('publisher verify',$publisherBlock))){
  if(@([regex]::Matches([string]$contract[1],('(?m)^\s+'+[regex]::Escape($expectedR4Env)+'\s*$'))).Count -ne 1){
    throw "P08-WORKFLOW-R4-PROPAGATION: $($contract[0]) must map the exact R4 digest once."
  }
  if(@([regex]::Matches([string]$contract[1],('(?m)^\s+'+[regex]::Escape($expectedR5Env)+'\s*$'))).Count -ne 1){
    throw "P08-WORKFLOW-R5-PROPAGATION: $($contract[0]) must map the exact R5 digest once."
  }
  if(@([regex]::Matches([string]$contract[1],('(?m)^\s+'+[regex]::Escape($expectedR6Env)+'\s*$'))).Count -ne 1){
    throw "P08-WORKFLOW-R6-PROPAGATION: $($contract[0]) must map the exact R6 digest once."
  }
  if(@([regex]::Matches([string]$contract[1],('(?m)^\s+'+[regex]::Escape($expectedR8Env)+'\s*$'))).Count -ne 1){
    throw "P08-WORKFLOW-R7-PROPAGATION: $($contract[0]) must map the exact R7 digest once."
  }
}
if ($dryBlock.IndexOf("inputs.operation_mode == 'PublisherDryRun'",[StringComparison]::Ordinal) -lt 0 -or
    $dryBlock.IndexOf('publish --frozen --dry-run',[StringComparison]::Ordinal) -lt 0 -or
    $dryBlock.IndexOf('credential_state_removed=$true',[StringComparison]::Ordinal) -lt 0 -or
    $dryBlock.IndexOf('mutation_performed=$false',[StringComparison]::Ordinal) -lt 0) { throw 'P08-WORKFLOW-DRYRUN: isolated dry-run contract drifted.' }
if ($dryBlock.IndexOf('moon publish --frozen`n',[StringComparison]::Ordinal) -ge 0) { throw 'P08-WORKFLOW-NONDRY: dry-run mode exposes a non-dry command.' }
if ($preflightBlock.IndexOf('MOONCAKES_TOKEN',[StringComparison]::Ordinal) -ge 0 -or
    $preflightBlock.IndexOf('environment: mooncakes-production',[StringComparison]::Ordinal) -ge 0 -or
    $preflightBlock.IndexOf('native_runtime_verified=$true',[StringComparison]::Ordinal) -lt 0 -or
    $preflightBlock.IndexOf('compile_only=$false',[StringComparison]::Ordinal) -lt 0) { throw 'P08-WORKFLOW-PREFLIGHT: secret-free native runtime contract drifted.' }
if ($publisherBlock.IndexOf("inputs.operation_mode == 'PublishOne'",[StringComparison]::Ordinal) -lt 0 -or
    $publisherBlock.IndexOf('inputs.live_authorization == true',[StringComparison]::Ordinal) -lt 0) { throw 'P08-WORKFLOW-PUBLISHONE: irreversible job reachability is not explicit.' }

if($WorkflowOnly){return}

$hostedPath=Join-Path $PSScriptRoot 'Invoke-Phase08HostedRun.ps1'
if (-not (Test-Path -LiteralPath $hostedPath -PathType Leaf)) { throw 'P08-HOSTED-HELPER-MISSING: hosted helper is required.' }
. $hostedPath -Mode PrepareAttempt -LibraryOnly

function Assert-P08HostedDispatchFields {
  param(
    [Parameter(Mandatory)][ValidateSet('HostedPreflight','PublishOne')][string]$Operation,
    [AllowEmptyString()][string]$PriorId,
    [AllowEmptyString()][string]$PriorArtifact,
    [AllowEmptyString()][string]$Packet,
    [AllowEmptyString()][string]$Receipt,
    [Parameter(Mandatory)][string[]]$ExpectedFields,
    [Parameter(Mandatory)][string]$AttemptZeroHistory,
    [Parameter(Mandatory)][string]$R1History,
    [Parameter(Mandatory)][string]$R2History,
    [Parameter(Mandatory)][string]$R3History,
    [Parameter(Mandatory)][string]$R4History,
    [Parameter(Mandatory)][string]$R5History,
    [Parameter(Mandatory)][string]$R6History,
    [Parameter(Mandatory)][string]$R7History,
    [Parameter(Mandatory)][string]$R8History,
    [Parameter(Mandatory)][string]$R9History,
    [Parameter(Mandatory)][string]$R10History
  )
  $script:p08HostedFieldsDispatched=$false
  $script:p08HostedFieldsArguments=$null
  $script:p08HostedFieldsRunId=if($Operation -ceq 'HostedPreflight'){'1001'}else{'1002'}
  $script:p08HostedFieldsTitle="MNF $Operation mb-core $('a'*64) $('b'*64) $('c'*64)"
  $script:p08HostedFieldsGh={
    param([string[]]$CommandArguments)
    if($CommandArguments[0] -ceq 'run' -and $CommandArguments[1] -ceq 'list'){
      if(-not $script:p08HostedFieldsDispatched){return '[]'}
      $run=[pscustomobject][ordered]@{
        databaseId=$script:p08HostedFieldsRunId;headBranch='modules-v0.1.0-r10';headSha=('1'*40);status='completed';conclusion='success'
        displayTitle=$script:p08HostedFieldsTitle;workflowName='publish-modules';url='https://fixture.invalid/run';createdAt='2026-07-19T00:00:00Z';updatedAt='2026-07-19T00:00:01Z'
      }
      return (ConvertTo-Json -InputObject @($run) -Depth 10 -Compress)
    }
    if($CommandArguments[0] -ceq 'workflow' -and $CommandArguments[1] -ceq 'run'){
      $script:p08HostedFieldsArguments=[string[]]@($CommandArguments)
      $script:p08HostedFieldsDispatched=$true
      return
    }
    if($CommandArguments[0] -ceq 'run' -and $CommandArguments[1] -ceq 'view'){
      return ([pscustomobject][ordered]@{
        databaseId=$script:p08HostedFieldsRunId;attempt=1;headBranch='modules-v0.1.0-r10';headSha=('1'*40);event='workflow_dispatch'
        status='completed';conclusion='success';displayTitle=$script:p08HostedFieldsTitle;workflowName='publish-modules';url='https://fixture.invalid/run'
        createdAt='2026-07-19T00:00:00Z';updatedAt='2026-07-19T00:00:01Z'
      }|ConvertTo-Json -Depth 10 -Compress)
    }
    throw "P08-HOSTED-FIELDS-BOUNDARY: unexpected gh fixture call '$($CommandArguments -join ' ')'."
  }
  $script:GhCommand=$script:p08HostedFieldsGh
  try{
    $null=Invoke-P08HostedDispatch -Operation $Operation -Repo 'tchivs/moonbit-foundation' -WorkflowPath 'publish-modules.yml' `
      -Ref 'refs/tags/modules-v0.1.0-r10' -Sha ('1'*40) -RootIntent ('a'*64) -CurrentIntent ('b'*64) -PreparedDigest ('c'*64) `
      -Module 'mb-core' -PriorId $PriorId -PriorArtifact $PriorArtifact -Packet $Packet -Receipt $Receipt `
      -AttemptZeroHistory $AttemptZeroHistory -R1History $R1History -R2History $R2History -R3History $R3History -R4History $R4History -R5History $R5History -R6History $R6History -R7History $R7History -R8History $R8History -R9History $R9History -R10History $R10History
  }finally{
    $script:GhCommand=$null
  }
  if(-not $script:p08HostedFieldsDispatched -or $null -eq $script:p08HostedFieldsArguments){throw 'P08-HOSTED-FIELDS-DISPATCH: fake dispatch was not reached exactly once.'}
  $expectedPrefix=@('workflow','run','publish-modules.yml','--repo','tchivs/moonbit-foundation','--ref','modules-v0.1.0-r10')
  $actualPrefix=@($script:p08HostedFieldsArguments[0..6])
  if(($actualPrefix -join ',') -cne ($expectedPrefix -join ',')){throw 'P08-HOSTED-FIELDS-PREFIX: dispatch prefix drifted.'}
  $actualFields=[Collections.Generic.List[string]]::new()
  for($i=7;$i -lt $script:p08HostedFieldsArguments.Count;$i+=2){
    if($script:p08HostedFieldsArguments[$i] -cne '-f' -or $i+1 -ge $script:p08HostedFieldsArguments.Count){throw 'P08-HOSTED-FIELDS-SHAPE: dispatch fields are not ordered -f pairs.'}
    $actualFields.Add($script:p08HostedFieldsArguments[$i+1])
  }
  if((@($actualFields)-join ',') -cne ($ExpectedFields-join ',')){throw "P08-HOSTED-FIELDS-ORDER: expected '$($ExpectedFields -join ',')', got '$(@($actualFields) -join ',')'."}
}

$hostedFieldsRoot=Join-Path ([IO.Path]::GetTempPath()) ('mnf-p08-hosted-fields-'+[Guid]::NewGuid().ToString('N'))
try{
  $null=New-Item -ItemType Directory -Path $hostedFieldsRoot
  $attemptZeroHistory=Join-Path $hostedFieldsRoot 'attempt-zero.json'
  $r1History=Join-Path $hostedFieldsRoot 'r1.json'
  $r2History=Join-Path $hostedFieldsRoot 'r2.json'
  $r3History=Join-Path $hostedFieldsRoot 'r3.json'
  $r4History=Join-Path $hostedFieldsRoot 'r4.json'
  $r5History=Join-Path $hostedFieldsRoot 'r5.json'
  $r6History=Join-Path $hostedFieldsRoot 'r6.json'
  $r7History=Join-Path $hostedFieldsRoot 'r7.json'
  $r8History=Join-Path $hostedFieldsRoot 'r8.json'
  $r9History=Join-Path $hostedFieldsRoot 'r9.json'
  $r10History=Join-Path $hostedFieldsRoot 'r10.json'
  $packet=Join-Path $hostedFieldsRoot 'packet.json'
  $receipt=Join-Path $hostedFieldsRoot 'receipt.json'
  $control=Get-Content -LiteralPath (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'policy/release-control.json') -Raw|ConvertFrom-Json -Depth 100
  $history=@($control.initial_attempt_family.terminal_negative_history)
  for($i=0;$i -lt 11;$i++){
    $projection=[ordered]@{};foreach($property in $history[$i].PSObject.Properties){if($property.Name -cne 'record_sha256'){$projection[$property.Name]=$property.Value}}
    [IO.File]::WriteAllText(@($attemptZeroHistory,$r1History,$r2History,$r3History,$r4History,$r5History,$r6History,$r7History,$r8History,$r9History,$r10History)[$i],($projection|ConvertTo-Json -Depth 30 -Compress),[Text.UTF8Encoding]::new($false))
  }
  [IO.File]::WriteAllText($packet,'{"authorization":"fixture"}',[Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText($receipt,'{"receipt":"fixture"}',[Text.UTF8Encoding]::new($false))
  $packetDigest=(Get-FileHash -LiteralPath $packet -Algorithm SHA256).Hash.ToLowerInvariant()
  $receiptDigest=(Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash.ToLowerInvariant()
  $commonFields=@(
    'release_ref=refs/tags/modules-v0.1.0-r10',('source_sha='+('1'*40)),('root_intent_sha256='+('a'*64)),('intent_sha256='+('b'*64)),
    ('prepared_manifest_sha256='+('c'*64)),('historical_attempts_sha256='+[string]$control.initial_attempt_family.history_set_sha256),'target_module=mb-core'
  )
  Assert-P08HostedDispatchFields -Operation HostedPreflight -PriorId '' -PriorArtifact '' -Packet '' -Receipt '' -AttemptZeroHistory $attemptZeroHistory -R1History $r1History -R2History $r2History -R3History $r3History -R4History $r4History -R5History $r5History -R6History $r6History -R7History $r7History -R8History $r8History -R9History $r9History -R10History $r10History -ExpectedFields (@(
    'operation_mode=HostedPreflight','run_mode=start')+$commonFields+@('live_authorization=false','prior_run_id=','prior_artifact_name=','authorization_packet_sha256=','authorization_receipt_sha256='))
  Assert-P08HostedDispatchFields -Operation PublishOne -PriorId '9001' -PriorArtifact 'mnf-checkpoint-9001-1' -Packet $packet -Receipt $receipt -AttemptZeroHistory $attemptZeroHistory -R1History $r1History -R2History $r2History -R3History $r3History -R4History $r4History -R5History $r5History -R6History $r6History -R7History $r7History -R8History $r8History -R9History $r9History -R10History $r10History -ExpectedFields (@(
    'operation_mode=PublishOne','run_mode=resume')+$commonFields+@('live_authorization=true','prior_run_id=9001','prior_artifact_name=mnf-checkpoint-9001-1',('authorization_packet_sha256='+$packetDigest),('authorization_receipt_sha256='+$receiptDigest)))
}finally{
  if(Test-Path -LiteralPath $hostedFieldsRoot){Remove-Item -LiteralPath $hostedFieldsRoot -Recurse -Force}
}
Write-Host 'Phase 8 hosted dispatch field fixtures: PASS.'
if($HostedFieldsOnly){return}

$offsetTimestamp='2026-07-19T04:08:31+08:00'
$locatorTimeFixture=[pscustomobject][ordered]@{schema_version='fixture';created_at_utc=$offsetTimestamp;locator_sha256=''}
$expectedLocatorTime='2026-07-18T20:08:31Z'
$locatorTimeFixture.locator_sha256=Get-P08ObjectDigest (Get-P08BoundaryLocatorProjection $locatorTimeFixture)
$reloadedLocatorTimeFixture=(Get-P08CanonicalJson $locatorTimeFixture)|ConvertFrom-Json -Depth 100
$stringTime=(Get-P08BoundaryLocatorProjection $locatorTimeFixture).created_at_utc
$reloadedTime=(Get-P08BoundaryLocatorProjection $reloadedLocatorTimeFixture).created_at_utc
$offsetTime=(Get-P08BoundaryLocatorProjection ([pscustomobject][ordered]@{created_at_utc=[DateTimeOffset]::Parse($offsetTimestamp);locator_sha256=''})).created_at_utc
$reloadedLocatorDigest=Get-P08ObjectDigest (Get-P08BoundaryLocatorProjection $reloadedLocatorTimeFixture)
if($stringTime -cne $expectedLocatorTime -or $reloadedTime -cne $expectedLocatorTime -or $offsetTime -cne $expectedLocatorTime -or
    $reloadedLocatorDigest -cne $locatorTimeFixture.locator_sha256){
  throw 'P08-BOUNDARY-LOCATOR-TIME: locator time projection or digest changed after JSON reload.'
}
Confirm-LiveRule 'P08-STORE-PATH' {
  Open-P08ArtifactStore -Locator (Join-Path ([IO.Path]::GetTempPath()) 'wrong-locator.json') -Root (Join-Path ([IO.Path]::GetTempPath()) 'wrong-root') -Repo tchivs/moonbit-foundation -WorkflowPath publish-modules.yml -Ref refs/tags/modules-v0.1.0 -Sha ('1'*40) -RootIntent ('a'*64) -CurrentIntent ('a'*64)
}
$runFixture={param([string]$id)[pscustomobject]@{databaseId=$id;headBranch='modules-v0.1.0';headSha=('1'*40);displayTitle='bound';status='completed';conclusion='success'}}
Confirm-LiveRule 'P08-HOSTED-AMBIGUOUS-RUN' { Select-P08NewRun -Before @{} -Runs @((&$runFixture '1001'),(&$runFixture '1002')) -Sha ('1'*40) -Title 'bound' -DispatchRef 'modules-v0.1.0' }
if ($null -ne (Select-P08NewRun -Before @{} -Runs @((&$runFixture '1001')) -Sha ('2'*40) -Title 'bound' -DispatchRef 'modules-v0.1.0')) { throw 'Stale run was selected.' }
Confirm-LiveRule 'P08-HOSTED-AMBIGUOUS-ARTIFACT' { Select-P08Artifact -Response ([pscustomobject]@{artifacts=@()}) -Prefix 'mnf-hosted-preflight-' }
Confirm-LiveRule 'P08-HOSTED-AMBIGUOUS-ARTIFACT' { Select-P08Artifact -Response ([pscustomobject]@{artifacts=@([pscustomobject]@{name='mnf-hosted-preflight-a';expired=$false},[pscustomobject]@{name='mnf-hosted-preflight-b';expired=$false})}) -Prefix 'mnf-hosted-preflight-' }
$fixtureStore=[pscustomobject]@{locator=[pscustomobject]@{repository='tchivs/moonbit-foundation';workflow='publish-modules.yml';release_ref='refs/tags/modules-v0.1.0';source_sha=('1'*40);root_intent_sha256=('a'*64);intent_sha256=('a'*64)}}
$fixtureRun=[pscustomobject]@{databaseId='1001';attempt=1}
$now=[DateTime]::UtcNow.ToString('o')
$dryEvidence=[pscustomobject][ordered]@{
  schema_version='mnf-publisher-dry-run/1';mode='PublisherDryRun';repository='tchivs/moonbit-foundation';workflow='publish-modules.yml';run_id='1001';run_attempt=1
  release_ref='refs/tags/modules-v0.1.0';source_sha=('1'*40);root_intent_sha256=('a'*64);intent_sha256=('a'*64);prepared_manifest_sha256=('b'*64)
  target_module='mb-core';module_identity='tchivs/mb-core@0.1.0';module_manifest_sha256=('d'*64);archive_sha256=('c'*64);command_classification='moon_publish_frozen_dry_run'
  observed_actor='tchivs';actor_check_classification='moon_whoami_exact';actor_stdout_line_count=1;actor_stderr_empty=$true
  exit_code=0;mutation_performed=$false;raw_output_persisted=$false;credential_state_removed=$true;started_at_utc=$now;completed_at_utc=$now
}
Assert-P08HostedEvidence -Operation PublisherDryRun -Evidence $dryEvidence -Run $fixtureRun -Store $fixtureStore -PreparedDigest ('b'*64) -Module mb-core
$bad=$dryEvidence.PSObject.Copy();$bad.exit_code=1
Confirm-LiveRule 'P08-HOSTED-DRYRUN-EVIDENCE' { Assert-P08HostedEvidence -Operation PublisherDryRun -Evidence $bad -Run $fixtureRun -Store $fixtureStore -PreparedDigest ('b'*64) -Module mb-core }
$bad=$dryEvidence.PSObject.Copy();$bad.credential_state_removed=$false
Confirm-LiveRule 'P08-HOSTED-DRYRUN-EVIDENCE' { Assert-P08HostedEvidence -Operation PublisherDryRun -Evidence $bad -Run $fixtureRun -Store $fixtureStore -PreparedDigest ('b'*64) -Module mb-core }
$bad=$dryEvidence.PSObject.Copy();$bad.command_classification='moon_publish_frozen'
Confirm-LiveRule 'P08-HOSTED-DRYRUN-EVIDENCE' { Assert-P08HostedEvidence -Operation PublisherDryRun -Evidence $bad -Run $fixtureRun -Store $fixtureStore -PreparedDigest ('b'*64) -Module mb-core }
$bad=$dryEvidence.PSObject.Copy();$bad.actor_stdout_line_count=2
Confirm-LiveRule 'P08-HOSTED-DRYRUN-EVIDENCE' { Assert-P08HostedEvidence -Operation PublisherDryRun -Evidence $bad -Run $fixtureRun -Store $fixtureStore -PreparedDigest ('b'*64) -Module mb-core }
$bad=$dryEvidence.PSObject.Copy();$bad.intent_sha256=('d'*64)
Confirm-LiveRule 'P08-HOSTED-EVIDENCE-BINDING' { Assert-P08HostedEvidence -Operation PublisherDryRun -Evidence $bad -Run $fixtureRun -Store $fixtureStore -PreparedDigest ('b'*64) -Module mb-core }
$bad=$dryEvidence.PSObject.Copy();$bad.started_at_utc=[DateTime]::UtcNow.AddDays(-1).ToString('o')
Confirm-LiveRule 'P08-HOSTED-EVIDENCE-STALE' { Assert-P08HostedEvidence -Operation PublisherDryRun -Evidence $bad -Run $fixtureRun -Store $fixtureStore -PreparedDigest ('b'*64) -Module mb-core }
$bad=$dryEvidence.PSObject.Copy();$bad | Add-Member note 'Bearer fixture-secret-value'
Confirm-LiveRule 'P08-HOSTED-SECRET-SHAPE' { Assert-P08HostedEvidence -Operation PublisherDryRun -Evidence $bad -Run $fixtureRun -Store $fixtureStore -PreparedDigest ('b'*64) -Module mb-core }
$native=[pscustomobject][ordered]@{
  schema_version='mnf-hosted-preflight/1';mode='HostedPreflight';repository='tchivs/moonbit-foundation';workflow='publish-modules.yml';run_id='1001';run_attempt=1
  release_ref='refs/tags/modules-v0.1.0';source_sha=('1'*40);root_intent_sha256=('a'*64);intent_sha256=('a'*64);prepared_manifest_sha256=('b'*64);target_module='mb-core'
  native_runtime_verified=$true;compile_only=$false;exit_code=0;sentinel_match=$true;expected_sentinel_sha256=('e'*64);observed_sentinel_sha256=('e'*64)
  toolchain_identity='moon 0.1.20260713 (75c7e1f)';linker_identity='clang fixture';runtime_identity='linux fixture';raw_output_persisted=$false;started_at_utc=$now;completed_at_utc=$now
}
Assert-P08HostedEvidence -Operation HostedPreflight -Evidence $native -Run $fixtureRun -Store $fixtureStore -PreparedDigest ('b'*64) -Module mb-core
$bad=$native.PSObject.Copy();$bad.compile_only=$true
Confirm-LiveRule 'P08-HOSTED-PREFLIGHT-EVIDENCE' { Assert-P08HostedEvidence -Operation HostedPreflight -Evidence $bad -Run $fixtureRun -Store $fixtureStore -PreparedDigest ('b'*64) -Module mb-core }
$bad=$native.PSObject.Copy();$bad.observed_sentinel_sha256=('f'*64)
Confirm-LiveRule 'P08-HOSTED-PREFLIGHT-EVIDENCE' { Assert-P08HostedEvidence -Operation HostedPreflight -Evidence $bad -Run $fixtureRun -Store $fixtureStore -PreparedDigest ('b'*64) -Module mb-core }
if ($PreflightOnly -and ([string]::IsNullOrWhiteSpace($LocatorPath) -or [string]::IsNullOrWhiteSpace($ArtifactRoot))) { throw 'P08-PREFLIGHT-PATHS: explicit locator and artifact root are required.' }

function New-R9HandoffFixture {
  param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][ValidateSet('mutation_authorized','exact_existing')][string]$Variant)
  $null=New-Item -ItemType Directory -Path $Root
  $paths=[ordered]@{}
  foreach($name in @('boundary-locator','index')){
    $paths[$name]=Join-Path $Root "$name.json"
    [IO.File]::WriteAllText($paths[$name],'{}',[Text.UTF8Encoding]::new($false))
  }
  $control=Get-Content -LiteralPath (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'policy/release-control.json') -Raw|ConvertFrom-Json -Depth 100
  $history=@($control.initial_attempt_family.terminal_negative_history)
  for($i=0;$i -lt 11;$i++){
    $name=@('attempt-zero','r1','r2','r3','r4','r5','r6','r7','r8','r9','r10')[$i];$paths[$name]=Join-Path $Root "$name.json"
    $projection=[ordered]@{};foreach($property in $history[$i].PSObject.Properties){if($property.Name -cne 'record_sha256'){$projection[$property.Name]=$property.Value}}
    [IO.File]::WriteAllText($paths[$name],($projection|ConvertTo-Json -Depth 30 -Compress),[Text.UTF8Encoding]::new($false))
  }
  $packetPath=$null;$receiptPath=$null;$exactPath=$null
  if($Variant -ceq 'mutation_authorized'){
    $packetPath=Join-Path $Root 'packet.json'
    $packet=[pscustomobject][ordered]@{schema_version='mnf-phase08-mutation-authorization-packet/1';release_ref='refs/tags/modules-v0.1.0-r11';boundary_sha=('1'*40);packet_sha256=''}
    $packet.packet_sha256=Get-P08SelfExcludingDigest $packet 'packet_sha256'
    [IO.File]::WriteAllText($packetPath,(Get-P08CanonicalJson $packet),[Text.UTF8Encoding]::new($false))
    $receiptPath=Join-Path $Root 'authorization-receipt.json'
    $null=Write-P08AuthorizationReceipt -PacketPath $packetPath -ReceiptPath $receiptPath -BoundarySha ('1'*40) -Response authorize-core -CreatedAt '2026-07-19T08:00:00+08:00'
  }else{
    $exactPath=Join-Path $Root 'exact-existing.json'
    [IO.File]::WriteAllText($exactPath,'{}',[Text.UTF8Encoding]::new($false))
  }
  $activePath=Join-Path $Root 'active-attempt.json'
  $bindings=[pscustomobject][ordered]@{
    release_ref='refs/tags/modules-v0.1.0-r11';boundary_sha=('1'*40);execution_root=[IO.Path]::GetFullPath($Root)
    boundary_locator_path=[IO.Path]::GetFullPath($paths.'boundary-locator');artifact_root=[IO.Path]::GetFullPath($Root);artifact_index_path=[IO.Path]::GetFullPath($paths.index)
    attempt_zero_history_path=[IO.Path]::GetFullPath($paths.'attempt-zero');r1_history_path=[IO.Path]::GetFullPath($paths.r1);r2_history_path=[IO.Path]::GetFullPath($paths.r2);r3_history_path=[IO.Path]::GetFullPath($paths.r3);r4_history_path=[IO.Path]::GetFullPath($paths.r4);r5_history_path=[IO.Path]::GetFullPath($paths.r5);r6_history_path=[IO.Path]::GetFullPath($paths.r6);r7_history_path=[IO.Path]::GetFullPath($paths.r7);r8_history_path=[IO.Path]::GetFullPath($paths.r8);r9_history_path=[IO.Path]::GetFullPath($paths.r9);r10_history_path=[IO.Path]::GetFullPath($paths.r10)
    historical_history_set_sha256='45330d06dec5aca59c07d592ca851c4441cf43d0e35014f9734b2746c293a41d'
    mutation_authorization_packet_path=$packetPath;authorization_receipt_path=$receiptPath;exact_existing_authority_path=$exactPath
  }
  $null=Write-P08ActiveAttempt -Path $activePath -Bindings $bindings -AuthorityVariant $Variant -UpdatedAt '2026-07-19T00:00:00Z'
  [pscustomobject]@{root=$Root;active_path=$activePath;handoff_path=(Join-Path $Root 'handoff.json');packet_path=$packetPath}
}

Confirm-LiveRule 'P08-HANDOFF-PRODUCTION-OVERRIDE' {& $hostedPath -Mode WriteHandoff -HandoffPath (Join-Path ([IO.Path]::GetTempPath()) 'caller.json')}
Confirm-LiveRule 'P08-HANDOFF-PRODUCTION-OVERRIDE' {& $hostedPath -Mode WriteHandoff -TempRoot (Join-Path ([IO.Path]::GetTempPath()) 'caller-root')}

$handoffParent=Join-Path ([IO.Path]::GetTempPath()) ('mnf-r9-handoff-fixtures-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $handoffParent
try{
  foreach($variant in @('mutation_authorized','exact_existing')){
    $ownedRoot=Join-Path $handoffParent ([Guid]::NewGuid().ToString('N'))
    try{
      $fixture=New-R9HandoffFixture -Root $ownedRoot -Variant $variant
      if($variant -ceq 'mutation_authorized'){
        Confirm-LiveRule 'P08-RECEIPT-LITERAL' {Write-P08AuthorizationReceipt -PacketPath $fixture.packet_path -ReceiptPath (Join-Path $ownedRoot 'nonliteral.json') -BoundarySha ('1'*40) -Response 'authorize-core ' -CreatedAt '2026-07-19T00:00:00Z'}
      }
      $handoff=Write-P08HostedHandoff -ActiveAttemptPath $fixture.active_path -HandoffPath $fixture.handoff_path -CreatedAt '2026-07-19T08:00:00+08:00'
      if($handoff.authority_variant -cne $variant -or (ConvertTo-ReleaseCanonicalUtc $handoff.created_at_utc) -cne '2026-07-19T00:00:00Z'){throw 'P08-R9-HANDOFF-FIXTURE: hosted handoff branch or UTC projection drifted.'}
    }finally{
      $ownedFull=[IO.Path]::GetFullPath($ownedRoot);$parentFull=[IO.Path]::GetFullPath($handoffParent).TrimEnd([IO.Path]::DirectorySeparatorChar)
      if(-not $ownedFull.StartsWith($parentFull+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)){throw 'P08-R4-FIXTURE-OWNERSHIP: fixture root escaped its owned parent.'}
      if(Test-Path -LiteralPath $ownedFull){Remove-Item -LiteralPath $ownedFull -Recurse -Force}
    }
  }
  $collisionRoot=Join-Path $handoffParent ([Guid]::NewGuid().ToString('N'))
  try{
    $collision=New-R9HandoffFixture -Root $collisionRoot -Variant exact_existing
    [IO.File]::WriteAllText($collision.handoff_path,'collision',[Text.UTF8Encoding]::new($false))
    Confirm-LiveRule 'P08-STORE-COLLISION' {Write-P08HostedHandoff -ActiveAttemptPath $collision.active_path -HandoffPath $collision.handoff_path -CreatedAt '2026-07-19T00:00:00Z'}
  }finally{
    $collisionFull=[IO.Path]::GetFullPath($collisionRoot);$parentFull=[IO.Path]::GetFullPath($handoffParent).TrimEnd([IO.Path]::DirectorySeparatorChar)
    if(-not $collisionFull.StartsWith($parentFull+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)){throw 'P08-R4-FIXTURE-OWNERSHIP: collision root escaped its owned parent.'}
    if(Test-Path -LiteralPath $collisionFull){Remove-Item -LiteralPath $collisionFull -Recurse -Force}
  }
}finally{
  if(Test-Path -LiteralPath $handoffParent){Remove-Item -LiteralPath $handoffParent -Recurse -Force}
}
if(Test-Path -LiteralPath $productionHandoff){throw 'P08-FIXED-HANDOFF-CREATED: static fixtures touched the real production handoff.'}
Write-Host 'Phase 8 live workflow fixtures: PASS.'
