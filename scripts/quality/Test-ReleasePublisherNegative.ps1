[CmdletBinding()]
param([switch]$ReducerOnly)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$common = Join-Path $PSScriptRoot 'ReleasePublisher.Common.ps1'
if (-not (Test-Path -LiteralPath $common -PathType Leaf)) {
  throw 'PUB00-MISSING-REDUCER: ReleasePublisher.Common.ps1 is required.'
}
. $common

function Confirm-PublisherRule {
  param([string]$Id, [scriptblock]$Action)
  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure -or -not $failure.StartsWith("$Id`: ", [StringComparison]::Ordinal)) {
    throw "Publisher negative '$Id' passed or failed for the wrong reason: '$failure'."
  }
}

function Confirm-LiveRule {
  param([string]$Id, [scriptblock]$Action)
  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure -or -not $failure.StartsWith("$Id`: ", [StringComparison]::Ordinal)) {
    throw "Live negative '$Id' passed or failed for the wrong reason: '$failure'."
  }
}

function New-TestCommand {
  param(
    [int]$Sequence,
    [string]$Prior,
    [string]$State,
    [string]$Operation,
    [AllowNull()][string]$Module = $null,
    [string]$ObservationStatus = 'not_observed',
    [string]$Outcome = 'accepted'
  )
  [pscustomobject][ordered]@{
    journal_sequence = $Sequence
    prior_record_sha256 = $Prior
    root_intent_sha256 = ('a' * 64)
    intent_sha256 = ('a' * 64)
    intent_kind = 'initial'
    correction_sequence = 0
    predecessor_intent_sha256 = $null
    state = $State
    module = $Module
    operation = $Operation
    observation = [pscustomobject][ordered]@{
      status = $ObservationStatus
      identity = 'not_applicable'
      reason_code = 'none'
      reobservation_required = $false
    }
    outcome = $Outcome
    recorded_at_utc = '2026-07-18T00:00:00.0000000Z'
    run_identity = [pscustomobject][ordered]@{
      repository = 'tchivs/moonbit-foundation'
      run_id = '1001'
      artifact_name = "publisher-$Sequence"
      artifact_sequence = $Sequence
    }
  }
}

$genesis = New-TestCommand -Sequence 0 -Prior ('0' * 64) -State 'intent_authorized' -Operation 'authorize'
$record0 = New-PublisherJournalRecord -Command $genesis
if (-not (Test-PublisherJournalChain -Records @($record0))) { throw 'Legal genesis chain did not validate.' }

$preflight = New-TestCommand -Sequence 1 -Prior $record0.record_sha256 -State 'preflight_passed' -Operation 'preflight'
$decision = Resolve-PublisherTransition -Records @($record0) -Command $preflight
if ($decision.action -cne 'append' -or $decision.record.state -cne 'preflight_passed') { throw 'Legal preflight did not append.' }
$record1 = $decision.record

Confirm-PublisherRule 'PUB02-SEQUENCE' { Resolve-PublisherTransition -Records @($record0, $record1) -Command (New-TestCommand -Sequence 3 -Prior $record1.record_sha256 -State 'core_mutation_attempted' -Operation 'attempt_mutation' -Module 'mb-core') }
Confirm-PublisherRule 'PUB03-PRIOR-DIGEST' { Resolve-PublisherTransition -Records @($record0, $record1) -Command (New-TestCommand -Sequence 2 -Prior ('f' * 64) -State 'core_mutation_attempted' -Operation 'attempt_mutation' -Module 'mb-core') }
Confirm-PublisherRule 'PUB04-ROOT' { $c = New-TestCommand -Sequence 2 -Prior $record1.record_sha256 -State 'core_mutation_attempted' -Operation 'attempt_mutation' -Module 'mb-core'; $c.root_intent_sha256 = ('b' * 64); Resolve-PublisherTransition -Records @($record0, $record1) -Command $c }
Confirm-PublisherRule 'PUB05-INTENT' { $c = New-TestCommand -Sequence 2 -Prior $record1.record_sha256 -State 'core_mutation_attempted' -Operation 'attempt_mutation' -Module 'mb-core'; $c.intent_sha256 = ('b' * 64); Resolve-PublisherTransition -Records @($record0, $record1) -Command $c }
Confirm-PublisherRule 'PUB06-ORDER' { Resolve-PublisherTransition -Records @($record0, $record1) -Command (New-TestCommand -Sequence 2 -Prior $record1.record_sha256 -State 'color_mutation_attempted' -Operation 'attempt_mutation' -Module 'mb-color') }
Confirm-PublisherRule 'PUB01-CLOSED' { $c = New-TestCommand -Sequence 2 -Prior $record1.record_sha256 -State 'core_mutation_attempted' -Operation 'attempt_mutation' -Module 'mb-core'; $c | Add-Member unexpected 'x'; Resolve-PublisherTransition -Records @($record0, $record1) -Command $c }

$mismatchCommand = New-TestCommand -Sequence 2 -Prior $record1.record_sha256 -State 'terminal_mismatch' -Operation 'stop' -ObservationStatus 'mismatch' -Outcome 'incident_opened'
$terminal = (Resolve-PublisherTransition -Records @($record0,$record1) -Command $mismatchCommand).record
Confirm-PublisherRule 'PUB09-TERMINAL' { Resolve-PublisherTransition -Records @($record0,$record1,$terminal) -Command (New-TestCommand -Sequence 3 -Prior $terminal.record_sha256 -State 'core_mutation_attempted' -Operation 'attempt_mutation' -Module 'mb-core') }

$secret = ConvertTo-PublisherSanitizedObservation -Status unknown -Identity insufficient -ReasonCode ambiguous_result -ReobservationRequired $true
if (($secret.PSObject.Properties.Name -join ',') -cne 'status,identity,reason_code,reobservation_required') { throw 'Sanitized observation is not closed.' }

Write-Host 'Publisher reducer negative matrix passed.'
if ($ReducerOnly) { return }

if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'Invoke-ReleasePublisher.ps1'))) {
  throw 'PUB00-MISSING-CONTROLLER: Invoke-ReleasePublisher.ps1 is required.'
}
. (Join-Path $PSScriptRoot 'Invoke-ReleasePublisher.ps1') -LibraryOnly

$root = 'a' * 64
$actorEvidence = [pscustomobject][ordered]@{
  expected_actor='tchivs'; observed_actor='tchivs'; actor_check_classification='moon_whoami_exact'
  actor_exit_code=0; actor_stdout_line_count=1; actor_stderr_empty=$true; actor_match=$true
  actor_raw_output_persisted=$false; credential_state_removed=$true; mutation_performed=$false
  command_classification='moon_whoami_dry_run_only'
}
$base = [pscustomobject]@{
  repository='tchivs/moonbit-foundation'; actor='tchivs'; actor_evidence=$actorEvidence; release_ref='refs/tags/modules-v0.1.0-r1'
  source_sha=('1'*40); root_intent_sha256=$root; intent_sha256=$root; intent_kind='initial'
  prepared_manifest_sha256=('9'*64)
  correction_sequence=0; predecessor_intent_sha256=$null; authorization_valid=$true
  evidence_valid=$true; dry_run_passed=$true; authority_account='tchivs'
}

Assert-PublisherRequest $base
Confirm-PublisherRule 'PUB04-ROOT' { $bad=$base.PSObject.Copy(); $bad.release_ref='refs/tags/modules-v0.1.0'; Assert-PublisherRequest $bad }
Confirm-PublisherRule 'PUB04-ROOT' { $bad=$base.PSObject.Copy(); $bad.source_sha='198436a45b7403a3c28c98d5fa0d5ed6a958455f'; Assert-PublisherRequest $bad }
Confirm-PublisherRule 'PUB04-ROOT' { $bad=$base.PSObject.Copy(); $bad.predecessor_intent_sha256=('8'*64); Assert-PublisherRequest $bad }
Confirm-PublisherRule 'PUB13-EVIDENCE' { $bad=$base.PSObject.Copy(); $bad.prepared_manifest_sha256=''; Assert-PublisherRequest $bad }
Confirm-PublisherRule 'PUB12-ACTOR' { $bad=$base.PSObject.Copy(); $bad.actor_evidence=($actorEvidence | ConvertTo-Json -Compress | ConvertFrom-Json); $bad.actor_evidence.actor_stdout_line_count=2; Assert-PublisherRequest $bad }
Confirm-PublisherRule 'PUB12-ACTOR' { $bad=$base.PSObject.Copy(); $bad.actor_evidence=($actorEvidence | ConvertTo-Json -Compress | ConvertFrom-Json); $bad.actor_evidence.actor_stderr_empty=$false; Assert-PublisherRequest $bad }

$exactExisting = [pscustomobject][ordered]@{
  classification='exact_existing_verified'; repository='tchivs/moonbit-foundation'; release_ref='refs/tags/modules-v0.1.0-r1'
  source_sha=('1'*40); root_intent_sha256=$root; intent_sha256=$root; prepared_manifest_sha256=('9'*64)
  observation_sha256=('6'*64); cold_proof_sha256=('7'*64); reducer_record_sha256=('8'*64)
  mutation_authorization_required=$false; mutation_authorization_used=$false; publisher_dry_run_used=$false
  mutation_count=0; mutation_performed=$false
}
if (-not (Assert-PublisherExactExistingCheckpoint -Checkpoint $exactExisting -Request $base)) { throw 'Exact-existing checkpoint was not accepted.' }
Confirm-PublisherRule 'PUB15-EXACT-EXISTING' { $bad=$exactExisting.PSObject.Copy(); $bad.mutation_count=1; Assert-PublisherExactExistingCheckpoint -Checkpoint $bad -Request $base }
Confirm-PublisherRule 'PUB15-EXACT-EXISTING' { $bad=$exactExisting.PSObject.Copy(); $bad.intent_sha256=('b'*64); Assert-PublisherExactExistingCheckpoint -Checkpoint $bad -Request $base }

$preparedSchema=Get-Content -LiteralPath (Join-Path $repoRoot 'release/prepared/schema.json') -Raw | ConvertFrom-Json -Depth 100
if ($preparedSchema.properties.release_ref.pattern -cne '^refs/tags/modules-(v0[.]1[.]0-r1|correction-[1-9][0-9]*)$') {
  throw 'PREP09-BINDING: prepared schema still accepts the terminal attempt-zero ref.'
}
. (Join-Path $PSScriptRoot 'Invoke-MooncakesLiveMutation.ps1') -LibraryOnly
Assert-LiveRequest $base
Confirm-LiveRule 'LIVE02-BINDING' { $bad=$base.PSObject.Copy(); $bad.release_ref='refs/tags/modules-v0.1.0'; Assert-LiveRequest $bad }
Confirm-LiveRule 'LIVE01-AUTHORIZATION' { $bad=$base.PSObject.Copy(); $bad.actor_evidence=($actorEvidence | ConvertTo-Json -Compress | ConvertFrom-Json); $bad.actor_evidence.actor_match=$false; Assert-LiveRequest $bad }
$preparedRoot=Join-Path ([IO.Path]::GetTempPath()) ('mnf-r1-prepared-' + [Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $preparedRoot
try {
  $manifest=[pscustomobject][ordered]@{ repository=$base.repository; actor=$base.actor; release_ref=$base.release_ref; source_sha=$base.source_sha; root_intent_sha256=$base.root_intent_sha256; intent_sha256=$base.intent_sha256 }
  $manifestPath=Join-Path $preparedRoot 'prepared-bundle.json'
  [IO.File]::WriteAllText($manifestPath,($manifest|ConvertTo-Json -Compress),[Text.UTF8Encoding]::new($false))
  $bound=$base.PSObject.Copy(); $bound.prepared_manifest_sha256=(Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
  $null=Invoke-PreparedLiveValidation -Root $preparedRoot -Request $bound -Validator { param($root,$value,$request) }
  Confirm-LiveRule 'LIVE06-PREPARED' { Invoke-PreparedLiveValidation -Root $preparedRoot -Request $base -Validator { param($root,$value,$request) } }
} finally { Remove-Item -LiteralPath $preparedRoot -Recurse -Force }

$ambiguous = Invoke-PublisherRehearsal -Request $base -Scenario timeout
if ($ambiguous.reobserved -ne $true -or $ambiguous.disposition -cne 'fresh_authorization_required' -or $ambiguous.mutation_count -ne 0) { throw 'Timeout did not re-observe absent and stop for fresh authorization.' }
$partial = Invoke-PublisherRehearsal -Request $base -Scenario partial_success
if ($partial.reobserved -ne $true -or $partial.disposition -cne 'checkpoint_verified' -or $partial.mutation_count -ne 0) { throw 'Partial success did not re-observe exact match without republishing.' }
$mismatch = Invoke-PublisherRehearsal -Request $base -Scenario existing_mismatch
if ($mismatch.disposition -cne 'incident_opened' -or $mismatch.destructive_recovery_available -ne $false) { throw 'Mismatch did not terminate forward-only.' }
$unknown = Invoke-PublisherRehearsal -Request $base -Scenario unknown
if ($unknown.disposition -cne 'unknown_stopped' -or $unknown.reobserved -ne $true) { throw 'Unknown observation did not stop.' }
$exact = Invoke-PublisherRehearsal -Request $base -Scenario existing_exact
if ($exact.disposition -cne 'idempotent_checkpoint' -or $exact.mutation_count -ne 0) { throw 'Exact replay attempted republish.' }
$nonzero = Invoke-PublisherRehearsal -Request $base -Scenario nonzero
if ($nonzero.disposition -cne 'fresh_authorization_required' -or $nonzero.reobserved -ne $true) { throw 'Nonzero outcome did not re-observe.' }
$cancelled = Invoke-PublisherRehearsal -Request $base -Scenario cancelled
if ($cancelled.disposition -cne 'unknown_stopped' -or $cancelled.reobserved -ne $true) { throw 'Interrupted run did not re-observe and stop.' }
$auth = Invoke-PublisherRehearsal -Request $base -Scenario invalid_credential
if ($auth.disposition -cne 'authentication_rejected' -or $auth.mutation_count -ne 0) { throw 'Invalid auth reached mutation.' }
$evidence = Invoke-PublisherRehearsal -Request $base -Scenario evidence_failure
if ($evidence.disposition -cne 'evidence_rejected' -or $evidence.mutation_count -ne 0) { throw 'Invalid evidence reached mutation.' }

$correctionA = $base.PSObject.Copy(); $correctionA.intent_kind='forward_correction'; $correctionA.intent_sha256=('b'*64); $correctionA.correction_sequence=1; $correctionA.predecessor_intent_sha256=$root; $correctionA.release_ref='refs/tags/modules-correction-1'; $correctionA.source_sha=('2'*40)
$correctionB = $base.PSObject.Copy(); $correctionB.intent_kind='forward_correction'; $correctionB.intent_sha256=('c'*64); $correctionB.correction_sequence=1; $correctionB.predecessor_intent_sha256=$root; $correctionB.release_ref='refs/tags/modules-correction-1'; $correctionB.source_sha=('3'*40)
$race = Invoke-PublisherCorrectionRaceRehearsal -First $correctionA -Second $correctionB
if ($race.first -cne 'accepted' -or $race.second -cne 'stale_fork' -or $race.first_lock -cne $race.second_lock -or $race.mutation_count -ne 0) { throw 'Competing corrections were not serialized on immutable root.' }

Confirm-PublisherRule 'PUB11-CORRECTION-SEQUENCE' { $bad=$correctionA.PSObject.Copy(); $bad.correction_sequence=2; Assert-PublisherCorrectionRequest -Request $bad -LatestIntentSha256 $root -LatestCorrectionSequence 0 }
Confirm-PublisherRule 'PUB10-STALE-FORK' { Assert-PublisherCorrectionRequest -Request $correctionB -LatestIntentSha256 $correctionA.intent_sha256 -LatestCorrectionSequence 1 }
Confirm-PublisherRule 'PUB04-ROOT' { $bad=$correctionA.PSObject.Copy(); $bad.root_intent_sha256=('d'*64); Assert-PublisherCorrectionRequest -Request $bad -LatestIntentSha256 $root -LatestCorrectionSequence 0 -ExpectedRoot $root }
Confirm-PublisherRule 'PUB14-LIVE-GUARD' { Invoke-PublisherLiveOneStep -Request $base -Adapter $null -Authorized $false }
$correction2=$correctionA.PSObject.Copy(); $correction2.intent_sha256=('d'*64); $correction2.correction_sequence=2; $correction2.predecessor_intent_sha256=$correctionA.intent_sha256; $correction2.release_ref='refs/tags/modules-correction-2'; $correction2.source_sha=('4'*40)
if (-not (Assert-PublisherCorrectionRequest -Request $correction2 -LatestIntentSha256 $correctionA.intent_sha256 -LatestCorrectionSequence 1 -ExpectedRoot $root)) { throw 'Sequence+2 correction was not accepted after naming sequence+1.' }

Write-Host 'Publisher controller recovery rehearsal matrix passed.'
