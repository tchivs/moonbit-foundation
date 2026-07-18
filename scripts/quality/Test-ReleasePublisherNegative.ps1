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
