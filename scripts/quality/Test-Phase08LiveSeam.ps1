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
  param([ValidateSet('core','color')][string]$Through)
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
  param([ValidateSet('mb-core','mb-color')][string]$Module)
  $outputDigest='c'*64
  [pscustomobject][ordered]@{
    schema_version='1.0.0'; evidence_mode='live_registry'; policy_sha256=('b'*64); module=$Module
    identity="tchivs/$Module"; version='0.1.0'; dependency_source='registry_only'
    isolation=[pscustomobject][ordered]@{ consumer_root_outside_checkout=$true }
    observation=[pscustomobject][ordered]@{ outcome='exact'; content_sha256=('d'*64); strongest_identity=('sha256:' + ('e'*64)) }
    archive_sha256=('e'*64); downloaded_manifest_sha256=('f'*64)
    resolved_graph=[pscustomobject][ordered]@{ nodes=@(); edges=@() }
    toolchain=[pscustomobject][ordered]@{ moon_version='pinned'; moonc_version='pinned'; moonrun_version='pinned'; root_sha256=('1'*64) }
    targets=@('js','wasm','wasm-gc','native' | ForEach-Object { [pscustomobject][ordered]@{ name=$_; check='pass'; test='pass'; runtime='pass'; output_sha256=$outputDigest } })
    behavior=[pscustomobject][ordered]@{ result='pass'; output_sha256=$outputDigest }; verified=$true; content_sha256=('2'*64)
  }
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

Write-Host 'Phase 8 live adapter fixtures: PASS.'
if ($AdapterOnly) { return }

$workflowPath = Join-Path (Split-Path -Parent $PSScriptRoot) '..\.github\workflows\publish-modules.yml'
$workflow = Get-Content -LiteralPath $workflowPath -Raw
foreach ($required in @('Invoke-MooncakesLiveMutation','Invoke-ColdRegistryConsumer','MOONCAKES_TOKEN')) {
  if ($workflow.IndexOf($required,[StringComparison]::Ordinal) -lt 0) { throw "P08-WORKFLOW-MISSING: '$required'." }
}
Write-Host 'Phase 8 live workflow fixtures: PASS.'
