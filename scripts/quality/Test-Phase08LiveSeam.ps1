[CmdletBinding()]
param(
  [switch]$AdapterOnly,
  [switch]$WorkflowOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
    repository='tchivs/moonbit-foundation'; actor='tchivs'; release_ref='refs/tags/modules-v0.1.0'
    source_sha=('1'*40); root_intent_sha256=('a'*64); intent_sha256=('a'*64); intent_kind='initial'
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
    payloads=@('mb-core','mb-color','mb-image' | ForEach-Object { [pscustomobject][ordered]@{ path="archives/$_.zip"; role='exact_source_archive'; size=1; sha256=('3'*64) } })
  }
  [IO.File]::WriteAllText((Join-Path $fixtureRoot 'prepared/prepared-bundle.json'),($manifest | ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
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
foreach ($required in @('Invoke-MooncakesLiveMutation','Invoke-ColdRegistryConsumer','MOONCAKES_TOKEN')) {
  if ($workflow.IndexOf($required,[StringComparison]::Ordinal) -lt 0) { throw "P08-WORKFLOW-MISSING: '$required'." }
}
$publisherStart=$workflow.IndexOf("  publisher:",[StringComparison]::Ordinal)
$observerStart=$workflow.IndexOf("  observe_registry:",[StringComparison]::Ordinal)
$consumerStart=$workflow.IndexOf("  cold_consumer:",[StringComparison]::Ordinal)
if ($publisherStart -lt 0 -or $observerStart -le $publisherStart -or $consumerStart -le $observerStart) { throw 'P08-WORKFLOW-ORDER: publisher observation and consumer jobs are not ordered.' }
$publisherBlock=$workflow.Substring($publisherStart,$observerStart-$publisherStart)
$observerBlock=$workflow.Substring($observerStart,$consumerStart-$observerStart)
$consumerBlock=$workflow.Substring($consumerStart)
if (@([regex]::Matches($workflow,[regex]::Escape('${{ secrets.MOONCAKES_TOKEN }}'))).Count -ne 1) { throw 'P08-WORKFLOW-SECRET: secret mapping must occur exactly once.' }
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
Write-Host 'Phase 8 live workflow fixtures: PASS.'
