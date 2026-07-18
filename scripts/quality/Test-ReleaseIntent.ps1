[CmdletBinding()]
param(
  [switch]$ContractOnly,
  [switch]$Focused,
  [switch]$QualificationIntegration
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$policyPath = Join-Path $repoRoot 'policy\release-control.json'
$schemaPath = Join-Path $repoRoot 'release\intent\schema.json'

function Read-IntentJson {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "REL01-MISSING-CONTRACT: $Path" }
  try { return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100 } catch { throw "REL01-INVALID-JSON: $Path" }
}

function Assert-IntentContract {
  $policy = Read-IntentJson -Path $policyPath
  $schema = Read-IntentJson -Path $schemaPath
  if ($policy.schema_version -cne 'mnf-release-control/1' -or $policy.repository -cne 'tchivs/moonbit-foundation' -or
      $policy.owner -cne 'tchivs' -or $policy.sole_maintainer -cne 'tchivs') { throw 'REL01-POLICY-IDENTITY: release-control identity drifted.' }
  if ($policy.initial_profile.release_ref -cne 'refs/tags/modules-v0.1.0' -or $policy.initial_profile.correction_sequence -ne 0 -or
      $policy.initial_profile.serialized_root_intent_sha256 -cne 'forbidden') { throw 'REL01-INITIAL-PROFILE: initial root/ref contract drifted.' }
  if ($policy.correction_profile.release_ref_pattern -cne '^refs/tags/modules-correction-[1-9][0-9]*$' -or
      $policy.correction_profile.sequence_rule -cne 'predecessor_sequence_plus_one' -or
      $policy.correction_profile.successor_rule -cne 'one_authorized_successor_per_predecessor') { throw 'REL01-CORRECTION-PROFILE: correction ref/sequence contract drifted.' }
  if (($policy.module_order.identity -join ',') -cne 'tchivs/mb-core,tchivs/mb-color,tchivs/mb-image') { throw 'REL01-MODULE-ORDER: module identity order drifted.' }
  if ($policy.authority_semantics.intent_sha256 -cne 'content_identity_only' -or
      $policy.authority_semantics.credentials_read -ne $false -or $policy.authority_semantics.publication_performed -ne $false) { throw 'REL02-AUTHORITY-CONFLATION: digest or credential semantics drifted.' }
  if (@($schema.oneOf).Count -ne 2 -or $schema.'$defs'.initialIntent.additionalProperties -ne $false -or
      $schema.'$defs'.forwardCorrectionIntent.additionalProperties -ne $false) { throw 'REL01-CLOSED-SCHEMA: intent oneOf branches are not closed.' }
  $initialRequired = @($schema.'$defs'.initialIntent.required)
  if ($initialRequired -contains 'root_intent_sha256' -or $initialRequired -contains 'predecessor_intent_sha256') { throw 'REL01-HASH-CYCLE: initial intent serializes root/predecessor.' }
  $correctionRequired = @($schema.'$defs'.forwardCorrectionIntent.required)
  foreach ($required in @('root_intent_sha256','predecessor_intent_sha256','correction_sequence','correction_evidence')) {
    if ($correctionRequired -cnotcontains $required) { throw "REL01-CORRECTION-EVIDENCE: missing $required." }
  }
  if ($schema.'$defs'.forwardCorrectionIntent.properties.release_ref.pattern -cne '^refs/tags/modules-correction-[1-9][0-9]*$') { throw 'REL01-CORRECTION-TAG: correction tag pattern drifted.' }
  Write-Host 'Release intent contracts passed: closed initial root, monotonic correction profile, credential-free authority semantics.'
}

if (-not ($ContractOnly -or $Focused -or $QualificationIntegration)) { throw 'REL01-SELECTOR-REQUIRED: choose -ContractOnly, -Focused, or -QualificationIntegration.' }
Assert-IntentContract
if ($Focused) { throw 'REL01-FOCUSED-NOT-IMPLEMENTED: focused generator tests belong to Task 2.' }
if ($QualificationIntegration) { throw 'REL01-INTEGRATION-NOT-IMPLEMENTED: qualification integration belongs to Task 3.' }
