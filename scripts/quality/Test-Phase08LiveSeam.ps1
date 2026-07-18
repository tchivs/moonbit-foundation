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
  [pscustomobject][ordered]@{ schema_version='1.0.0'; evidence_mode='live_registry'; module=$Module; verified=$true; content_sha256=('b'*64) }
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

Write-Host 'Phase 8 live adapter fixtures: PASS.'
if ($AdapterOnly) { return }

$workflowPath = Join-Path (Split-Path -Parent $PSScriptRoot) '..\.github\workflows\publish-modules.yml'
$workflow = Get-Content -LiteralPath $workflowPath -Raw
foreach ($required in @('Invoke-MooncakesLiveMutation','Invoke-ColdRegistryConsumer','MOONCAKES_TOKEN')) {
  if ($workflow.IndexOf($required,[StringComparison]::Ordinal) -lt 0) { throw "P08-WORKFLOW-MISSING: '$required'." }
}
Write-Host 'Phase 8 live workflow fixtures: PASS.'
