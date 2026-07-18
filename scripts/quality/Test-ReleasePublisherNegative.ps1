[CmdletBinding()]
param([switch]$ReducerOnly)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
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

$secret = ConvertTo-PublisherSanitizedObservation -Status unknown -Identity insufficient -ReasonCode ambiguous_result -ReobservationRequired $true
if (($secret.PSObject.Properties.Name -join ',') -cne 'status,identity,reason_code,reobservation_required') { throw 'Sanitized observation is not closed.' }

Write-Host 'Publisher reducer negative matrix passed.'
if ($ReducerOnly) { return }

if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'Invoke-ReleasePublisher.ps1'))) {
  throw 'PUB00-MISSING-CONTROLLER: Invoke-ReleasePublisher.ps1 is required.'
}
. (Join-Path $PSScriptRoot 'Invoke-ReleasePublisher.ps1') -LibraryOnly

$root = 'a' * 64
$base = [pscustomobject]@{
  repository='tchivs/moonbit-foundation'; actor='tchivs'; release_ref='refs/tags/modules-v0.1.0'
  source_sha=('1'*40); root_intent_sha256=$root; intent_sha256=$root; intent_kind='initial'
  correction_sequence=0; predecessor_intent_sha256=$null; authorization_valid=$true
  evidence_valid=$true; dry_run_passed=$true; authority_account='tchivs'
}

$ambiguous = Invoke-PublisherRehearsal -Request $base -Scenario timeout
if ($ambiguous.reobserved -ne $true -or $ambiguous.disposition -cne 'fresh_authorization_required' -or $ambiguous.mutation_count -ne 0) { throw 'Timeout did not re-observe absent and stop for fresh authorization.' }
$partial = Invoke-PublisherRehearsal -Request $base -Scenario partial_success
if ($partial.reobserved -ne $true -or $partial.disposition -cne 'checkpoint_verified' -or $partial.mutation_count -ne 0) { throw 'Partial success did not re-observe exact match without republishing.' }
$mismatch = Invoke-PublisherRehearsal -Request $base -Scenario existing_mismatch
if ($mismatch.disposition -cne 'incident_opened' -or $mismatch.destructive_recovery_available -ne $false) { throw 'Mismatch did not terminate forward-only.' }
$unknown = Invoke-PublisherRehearsal -Request $base -Scenario unknown
if ($unknown.disposition -cne 'unknown_stopped' -or $unknown.reobserved -ne $true) { throw 'Unknown observation did not stop.' }
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

Write-Host 'Publisher controller recovery rehearsal matrix passed.'
