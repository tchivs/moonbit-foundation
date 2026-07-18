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
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')

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

function Confirm-IntentRule {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][scriptblock]$Action)
  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure -or -not $failure.StartsWith("$Id`: ", [StringComparison]::Ordinal)) {
    throw "Focused negative '$Id' passed or failed for the wrong reason: '$failure'."
  }
}

function Invoke-FocusedIntentTests {
  $generator = Join-Path $PSScriptRoot 'New-ReleaseIntent.ps1'
  if (-not (Test-Path -LiteralPath $generator -PathType Leaf)) { throw 'REL01-GENERATOR-MISSING: canonical generator is absent.' }
  $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-release-intent-' + [Guid]::NewGuid().ToString('N'))
  $null = New-Item -ItemType Directory -Force -Path $tempRoot
  try {
    $head = (& git -C $repoRoot rev-parse HEAD).Trim()
    $archives = [ordered]@{ 'mb-core' = ('1' * 64); 'mb-color' = ('2' * 64); 'mb-image' = ('3' * 64) }
    $common = @{
      Check = $true
      IntentKind = 'initial'
      ReleaseRef = 'refs/tags/modules-v0.1.0'
      SourceSha = $head
      QualificationRootSha256 = ('4' * 64)
      RequiredStableSha256 = ('5' * 64)
      ArchiveSha256ByModule = $archives
    }
    $a = & $generator @common -OutputDirectory (Join-Path $tempRoot 'initial-a')
    $b = & $generator @common -OutputDirectory (Join-Path $tempRoot 'initial-b')
    $aBytes = [IO.File]::ReadAllBytes($a.intent_path)
    $bBytes = [IO.File]::ReadAllBytes($b.intent_path)
    if (-not [Linq.Enumerable]::SequenceEqual([byte[]]$aBytes, [byte[]]$bBytes) -or $a.intent_sha256 -cne $b.intent_sha256) {
      throw 'REL01-DETERMINISM: independent initial constructions differ.'
    }
    if ($aBytes.Length -ge 3 -and $aBytes[0] -eq 0xEF -and $aBytes[1] -eq 0xBB -and $aBytes[2] -eq 0xBF) { throw 'REL01-ENCODING: intent contains a UTF-8 BOM.' }
    $initial = Read-ReleaseCanonicalJson -Path $a.intent_path
    Assert-ReleaseIntentObject -Intent $initial -PolicyPath $policyPath -ExpectedCurrentSha256 $a.intent_sha256
    Assert-ReleaseIntentAuthorizationBinding -Intent $initial -IntentSha256 $a.intent_sha256 -RootIntentSha256 $a.intent_sha256

    $reordered = [ordered]@{}
    foreach ($property in @($initial.PSObject.Properties.Name) | Sort-Object -Descending) { $reordered[$property] = $initial.$property }
    if ((ConvertTo-ReleaseCanonicalJson -Value $reordered -Profile ReleaseIntent) -cne [Text.UTF8Encoding]::new($false).GetString($aBytes)) {
      throw 'REL01-CANONICAL-EQUALITY: equivalent object construction changed canonical bytes.'
    }

    foreach ($case in @(
      @{ id='REL01-EMPTY'; mutate={ param($x) $x.source_sha = '' } },
      @{ id='REL01-UNKNOWN-PROPERTY'; mutate={ param($x) $x | Add-Member -NotePropertyName unexpected -NotePropertyValue 'x' } },
      @{ id='REL01-MODULE-ORDER'; mutate={ param($x) [Array]::Reverse($x.modules) } },
      @{ id='REL01-AUTHORITY-CONFLATION'; mutate={ param($x) $x.credentials_read = $true } },
      @{ id='REL01-REF'; mutate={ param($x) $x.release_ref = 'refs/heads/main' } }
    )) {
      Confirm-IntentRule $case.id {
        $copy = ($initial | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100)
        & $case.mutate $copy
        Assert-ReleaseIntentObject -Intent $copy -PolicyPath $policyPath -ExpectedCurrentSha256 $a.intent_sha256
      }
    }

    $bomPath = Join-Path $tempRoot 'bom.json'
    [IO.File]::WriteAllBytes($bomPath, [byte[]](0xEF,0xBB,0xBF) + [Text.UTF8Encoding]::new($false).GetBytes('{}'))
    Confirm-IntentRule 'REL01-ENCODING' { Read-ReleaseCanonicalJson -Path $bomPath | Out-Null }
    Confirm-IntentRule 'REL01-TERMINAL-MISMATCH' { Assert-ReleaseIntentRecovery -IntentKind initial -ObservedMismatch }

    $correctionCommon = @{
      Check = $true
      IntentKind = 'forward_correction'
      RootIntentSha256 = $a.intent_sha256
      PredecessorIntentSha256 = $a.intent_sha256
      PredecessorSequence = 0
      CorrectionSequence = 1
      QualificationRootSha256 = ('6' * 64)
      RequiredStableSha256 = ('7' * 64)
      IncidentSha256 = ('8' * 64)
      AdvisorySha256 = ('9' * 64)
      CompatibilityResultSha256 = ('a' * 64)
      VersionAbsenceSha256 = ('b' * 64)
      CorrectedVersions = [ordered]@{ 'mb-core'='0.1.1'; 'mb-color'='0.1.1'; 'mb-image'='0.1.1' }
    }
    $candidateA = & $generator @correctionCommon -ReleaseRef 'refs/tags/modules-correction-1' -SourceSha ('b' * 40) -ArchiveSha256ByModule ([ordered]@{ 'mb-core'=('c'*64); 'mb-color'=('d'*64); 'mb-image'=('e'*64) }) -OutputDirectory (Join-Path $tempRoot 'correction-a')
    $candidateB = & $generator @correctionCommon -ReleaseRef 'refs/tags/modules-correction-2' -SourceSha ('c' * 40) -ArchiveSha256ByModule ([ordered]@{ 'mb-core'=('d'*64); 'mb-color'=('e'*64); 'mb-image'=('f'*64) }) -OutputDirectory (Join-Path $tempRoot 'correction-b')
    if ($candidateA.intent_sha256 -ceq $candidateB.intent_sha256) { throw 'REL01-CORRECTION-DIGEST: distinct corrections share a digest.' }
    $correctionA = Read-ReleaseCanonicalJson -Path $candidateA.intent_path
    $correctionB = Read-ReleaseCanonicalJson -Path $candidateB.intent_path
    if ($correctionA.root_intent_sha256 -cne $a.intent_sha256 -or $correctionB.root_intent_sha256 -cne $a.intent_sha256) { throw 'REL01-ROOT-DRIFT: correction root changed.' }
    Assert-ReleaseIntentObject -Intent $correctionA -PolicyPath $policyPath -ExpectedCurrentSha256 $candidateA.intent_sha256 -ExpectedRootSha256 $a.intent_sha256 -ExpectedPredecessorSha256 $a.intent_sha256 -ExpectedPredecessorSequence 0 -AuthorizedSuccessorSha256 $candidateA.intent_sha256
    Confirm-IntentRule 'REL01-STALE-FORK' {
      Assert-ReleaseIntentObject -Intent $correctionB -PolicyPath $policyPath -ExpectedCurrentSha256 $candidateB.intent_sha256 -ExpectedRootSha256 $a.intent_sha256 -ExpectedPredecessorSha256 $a.intent_sha256 -ExpectedPredecessorSequence 0 -AuthorizedSuccessorSha256 $candidateA.intent_sha256
    }
    Confirm-IntentRule 'REL01-CORRECTION-TAG' { & $generator @correctionCommon -ReleaseRef 'refs/tags/modules-correction-0' -SourceSha ('d'*40) -ArchiveSha256ByModule $archives -OutputDirectory (Join-Path $tempRoot 'bad-tag') | Out-Null }
    $nonconsecutive = @{} + $correctionCommon; $nonconsecutive.CorrectionSequence = 2
    Confirm-IntentRule 'REL01-SEQUENCE' { & $generator @nonconsecutive -ReleaseRef 'refs/tags/modules-correction-3' -SourceSha ('e'*40) -ArchiveSha256ByModule $archives -OutputDirectory (Join-Path $tempRoot 'bad-sequence') | Out-Null }
    Write-Host 'Release intent focused tests passed: deterministic initial/correction bytes, canonical equality, terminal mismatch, monotonic root, and stale-fork rejection.'
  } finally {
    if (Test-Path -LiteralPath $tempRoot) {
      $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
      $full = [IO.Path]::GetFullPath($tempRoot)
      if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
          -not (Split-Path -Leaf $full).StartsWith('mnf-release-intent-', [StringComparison]::Ordinal)) { throw "Refusing to remove unverified intent test path: $full" }
      Remove-Item -LiteralPath $full -Recurse -Force
    }
  }
}

if (-not ($ContractOnly -or $Focused -or $QualificationIntegration)) { throw 'REL01-SELECTOR-REQUIRED: choose -ContractOnly, -Focused, or -QualificationIntegration.' }
Assert-IntentContract
if ($Focused) { Invoke-FocusedIntentTests }
if ($QualificationIntegration) { throw 'REL01-INTEGRATION-NOT-IMPLEMENTED: qualification integration belongs to Task 3.' }
