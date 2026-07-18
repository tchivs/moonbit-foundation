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
  $preparedSchema = Read-IntentJson -Path (Join-Path $repoRoot 'release\prepared\schema.json')
  if ($policy.schema_version -cne 'mnf-release-control/1' -or $policy.repository -cne 'tchivs/moonbit-foundation' -or
      $policy.owner -cne 'tchivs' -or $policy.sole_maintainer -cne 'tchivs') { throw 'REL01-POLICY-IDENTITY: release-control identity drifted.' }
  $history = @($policy.initial_attempt_family.terminal_negative_history)
  if ($history.Count -ne 2) { throw 'REL01-HISTORICAL-ATTEMPT: exact attempt-zero/r1 history is required.' }
  $attemptZero = $history[0]
  if ($attemptZero.attempt -cne 'attempt_zero' -or $attemptZero.release_ref -cne 'refs/tags/modules-v0.1.0' -or
      $attemptZero.source_sha -cne '198436a45b7403a3c28c98d5fa0d5ed6a958455f' -or
      $attemptZero.hosted_run_present -ne $true -or $attemptZero.run_id -cne '29652468948' -or
      $attemptZero.run_attempt -ne 1 -or $attemptZero.mutation_performed -ne $false -or
      $attemptZero.authority_acquired -ne $false -or $attemptZero.reason -cne 'terminal_setup_failure') {
    throw 'REL01-HISTORICAL-ATTEMPT: protected attempt-zero evidence drifted.'
  }
  $r1 = $history[1]
  if ($r1.attempt -cne 'r1' -or $r1.release_ref -cne 'refs/tags/modules-v0.1.0-r1' -or
      $r1.source_sha -cne '09548df948f58ec1bdfff7494757596c03e4c9bd' -or
      $r1.hosted_run_present -ne $false -or $null -ne $r1.run_id -or $null -ne $r1.run_attempt -or
      $r1.mutation_performed -ne $false -or $r1.authority_acquired -ne $false -or
      $r1.reason -cne 'terminal_local_preparation_failure') {
    throw 'REL01-HISTORICAL-ATTEMPT: protected r1 evidence drifted.'
  }
  if ($policy.initial_profile.release_ref -cne 'refs/tags/modules-v0.1.0-r2' -or $policy.initial_profile.correction_sequence -ne 0 -or
      $policy.initial_profile.serialized_root_intent_sha256 -cne 'forbidden') { throw 'REL01-INITIAL-PROFILE: initial root/ref contract drifted.' }
  if ($policy.correction_profile.release_ref_pattern -cne '^refs/tags/modules-correction-[1-9][0-9]*$' -or
      $policy.correction_profile.sequence_rule -cne 'predecessor_sequence_plus_one' -or
      $policy.correction_profile.successor_rule -cne 'one_authorized_successor_per_predecessor') { throw 'REL01-CORRECTION-PROFILE: correction ref/sequence contract drifted.' }
  if (($policy.module_order.identity -join ',') -cne 'tchivs/mb-core,tchivs/mb-color,tchivs/mb-image') { throw 'REL01-MODULE-ORDER: module identity order drifted.' }
  if ($policy.authority_semantics.intent_sha256 -cne 'content_identity_only' -or
      $policy.authority_semantics.credentials_read -ne $false -or $policy.authority_semantics.publication_performed -ne $false) { throw 'REL02-AUTHORITY-CONFLATION: digest or credential semantics drifted.' }
  if (@($schema.oneOf).Count -ne 2 -or $schema.'$defs'.initialIntent.additionalProperties -ne $false -or
      $schema.'$defs'.forwardCorrectionIntent.additionalProperties -ne $false) { throw 'REL01-CLOSED-SCHEMA: intent oneOf branches are not closed.' }
  if ($schema.'$defs'.initialIntent.properties.release_ref.const -cne 'refs/tags/modules-v0.1.0-r2') {
    throw 'REL01-INITIAL-PROFILE: initial schema does not require r2.'
  }
  if ($preparedSchema.properties.release_ref.pattern -cne '^refs/tags/modules-(v0[.]1[.]0-r2|correction-[1-9][0-9]*)$') {
    throw 'REL01-INITIAL-PROFILE: prepared schema does not require r2 or a correction ref.'
  }
  $initialRequired = @($schema.'$defs'.initialIntent.required)
  if ($initialRequired -contains 'root_intent_sha256' -or $initialRequired -contains 'predecessor_intent_sha256') { throw 'REL01-HASH-CYCLE: initial intent serializes root/predecessor.' }
  $correctionRequired = @($schema.'$defs'.forwardCorrectionIntent.required)
  foreach ($required in @('root_intent_sha256','predecessor_intent_sha256','correction_sequence','correction_evidence')) {
    if ($correctionRequired -cnotcontains $required) { throw "REL01-CORRECTION-EVIDENCE: missing $required." }
  }
  if ($schema.'$defs'.forwardCorrectionIntent.properties.release_ref.pattern -cne '^refs/tags/modules-correction-[1-9][0-9]*$') { throw 'REL01-CORRECTION-TAG: correction tag pattern drifted.' }
  $actor = [pscustomobject][ordered]@{
    expected_actor='tchivs'; observed_actor='tchivs'; actor_check_classification='moon_whoami_exact'
    actor_exit_code=0; actor_stdout_line_count=1; actor_stderr_empty=$true; actor_match=$true
    actor_raw_output_persisted=$false; credential_state_removed=$true; mutation_performed=$false
    command_classification='moon_whoami_dry_run_only'
  }
  Assert-ReleaseActorEvidence -Evidence $actor -Policy $policy
  foreach ($mutation in @(
    { param($x) $x.observed_actor='other' },
    { param($x) $x.actor_stdout_line_count=2 },
    { param($x) $x.actor_stderr_empty=$false },
    { param($x) $x.actor_exit_code=1 },
    { param($x) $x.actor_raw_output_persisted=$true },
    { param($x) $x.credential_state_removed=$false },
    { param($x) $x.mutation_performed=$true }
  )) {
    $bad = $actor | ConvertTo-Json -Compress | ConvertFrom-Json
    & $mutation $bad
    Confirm-IntentRule 'REL03-ACTOR' { Assert-ReleaseActorEvidence -Evidence $bad -Policy $policy }
  }
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
    $cloneA = Join-Path $tempRoot 'source-a'
    $cloneB = Join-Path $tempRoot 'source-b'
    & git clone --quiet --no-hardlinks $repoRoot $cloneA
    if ($LASTEXITCODE -ne 0) { throw 'REL01-TEST-CLONE: unable to create clean source A.' }
    & git clone --quiet --no-hardlinks $repoRoot $cloneB
    if ($LASTEXITCODE -ne 0) { throw 'REL01-TEST-CLONE: unable to create clean source B.' }
    $archives = [ordered]@{ 'mb-core' = ('1' * 64); 'mb-color' = ('2' * 64); 'mb-image' = ('3' * 64) }
    $common = @{
      Check = $true
      IntentKind = 'initial'
      ReleaseRef = 'refs/tags/modules-v0.1.0-r2'
      SourceSha = $head
      QualificationRootSha256 = ('4' * 64)
      RequiredStableSha256 = ('5' * 64)
      ArchiveSha256ByModule = $archives
    }
    $a = & $generator @common -SourceRoot $cloneA -OutputDirectory (Join-Path $tempRoot 'initial-a')
    $b = & $generator @common -SourceRoot $cloneB -OutputDirectory (Join-Path $tempRoot 'initial-b')
    $aBytes = [IO.File]::ReadAllBytes($a.intent_path)
    $bBytes = [IO.File]::ReadAllBytes($b.intent_path)
    if (-not [Linq.Enumerable]::SequenceEqual([byte[]]$aBytes, [byte[]]$bBytes) -or $a.intent_sha256 -cne $b.intent_sha256) {
      throw 'REL01-DETERMINISM: independent initial constructions differ.'
    }
    if ($aBytes.Length -ge 3 -and $aBytes[0] -eq 0xEF -and $aBytes[1] -eq 0xBB -and $aBytes[2] -eq 0xBF) { throw 'REL01-ENCODING: intent contains a UTF-8 BOM.' }
    $initial = Read-ReleaseCanonicalJson -Path $a.intent_path
    $null = Assert-ReleaseIntentObject -Intent $initial -PolicyPath $policyPath -ExpectedCurrentSha256 $a.intent_sha256
    Assert-ReleaseIntentAuthorizationBinding -Intent $initial -IntentSha256 $a.intent_sha256 -RootIntentSha256 $a.intent_sha256

    $reordered = [ordered]@{}
    foreach ($property in @($initial.PSObject.Properties.Name) | Sort-Object -Descending) { $reordered[$property] = $initial.$property }
    if ((ConvertTo-ReleaseCanonicalJson -Value $reordered -Profile ReleaseIntent) -cne [Text.UTF8Encoding]::new($false).GetString($aBytes)) {
      throw 'REL01-CANONICAL-EQUALITY: equivalent object construction changed canonical bytes.'
    }

    foreach ($case in @(
      @{ id='REL01-EMPTY'; mutate={ param($x) $x.source_sha = '' } },
      @{ id='REL01-DIGEST'; mutate={ param($x) $x.source_sha = ('f' * 40) } },
      @{ id='REL01-UNKNOWN-PROPERTY'; mutate={ param($x) $x | Add-Member -NotePropertyName unexpected -NotePropertyValue 'x' } },
      @{ id='REL01-MODULE-ORDER'; mutate={ param($x) [Array]::Reverse($x.modules) } },
      @{ id='REL01-AUTHORITY-CONFLATION'; mutate={ param($x) $x.credentials_read = $true } },
      @{ id='REL01-REF'; mutate={ param($x) $x.release_ref = 'refs/heads/main' } },
      @{ id='REL01-TOOLCHAIN'; mutate={ param($x) $x.toolchain.moon = 'moon latest' } },
      @{ id='REL01-PACKAGE-INVENTORY'; mutate={ param($x) $x.modules[0].public_packages += 'tchivs/mb-core/extra' } },
      @{ id='REL01-DIGEST'; mutate={ param($x) $x.modules[0].archive_sha256 = ('f' * 64) } },
      @{ id='REL01-DIGEST'; mutate={ param($x) $x.modules[0].interface_sha256 = ('f' * 64) } },
      @{ id='REL01-DIGEST'; mutate={ param($x) $x.evidence.qualification_root_sha256 = ('f' * 64) } },
      @{ id='REL01-INITIAL-VERSION'; mutate={ param($x) $x.modules[0].version = '0.1.1' } },
      @{ id='REL01-DEPENDENCY-CLOSURE'; mutate={ param($x) $x.modules[1].dependencies[0].version = '0.1.1' } }
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
    Confirm-IntentRule 'REL01-CONTROLLED-ASCII' {
      $copy = ($initial | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100); $copy.owner = "tchivs$([char]0x301)"
      ConvertTo-ReleaseCanonicalJson -Value $copy -Profile ReleaseIntent | Out-Null
    }
    Confirm-IntentRule 'REL01-TERMINAL-MISMATCH' { Assert-ReleaseIntentRecovery -IntentKind initial -ObservedMismatch }
    foreach ($oldRef in @('refs/tags/modules-v0.1.0','refs/tags/modules-v0.1.0-r1')) {
      Confirm-IntentRule 'REL01-REF' {
        $old = ($initial | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100); $old.release_ref = $oldRef
        Assert-ReleaseIntentObject -Intent $old -PolicyPath $policyPath
      }
    }
    foreach ($badInitial in @(
      @{ id='REL01-HASH-CYCLE'; values=@{ RootIntentSha256=('a'*64) } },
      @{ id='REL01-HASH-CYCLE'; values=@{ PredecessorIntentSha256=('b'*64) } },
      @{ id='REL01-HASH-CYCLE'; values=@{ CorrectionSequence=1 } },
      @{ id='REL01-CORRECTION-EVIDENCE'; values=@{ IncidentSha256=('c'*64) } }
    )) {
      $bad = @{} + $common; foreach ($entry in $badInitial.values.GetEnumerator()) { $bad[$entry.Key] = $entry.Value }
      Confirm-IntentRule $badInitial.id { & $generator @bad -SourceRoot $cloneA -OutputDirectory (Join-Path $tempRoot ('bad-initial-' + $badInitial.id)) | Out-Null }
    }

    $correctionCommon = @{
      Check = $true
      IntentKind = 'forward_correction'
      RootIntentSha256 = $a.intent_sha256
      PredecessorIntentSha256 = $a.intent_sha256
      PredecessorSourceSha = $head
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
    foreach ($entry in @(@($cloneA,'candidate-a'),@($cloneB,'candidate-b'))) {
      $root = $entry[0]; Set-Content -LiteralPath (Join-Path $root "$($entry[1]).txt") -Value $entry[1] -NoNewline
      & git -C $root config user.name 'MNF Intent Test'; & git -C $root config user.email 'intent-test@invalid.local'
      & git -C $root add -- "$($entry[1]).txt"; & git -C $root commit --quiet -m $entry[1]
      if ($LASTEXITCODE -ne 0) { throw 'REL01-TEST-COMMIT: unable to create correction source.' }
    }
    $sourceA = (& git -C $cloneA rev-parse HEAD).Trim(); $sourceB = (& git -C $cloneB rev-parse HEAD).Trim()
    $candidateA = & $generator @correctionCommon -ReleaseRef 'refs/tags/modules-correction-1' -SourceSha $sourceA -SourceRoot $cloneA -ArchiveSha256ByModule ([ordered]@{ 'mb-core'=('c'*64); 'mb-color'=('d'*64); 'mb-image'=('e'*64) }) -OutputDirectory (Join-Path $tempRoot 'correction-a')
    $candidateB = & $generator @correctionCommon -ReleaseRef 'refs/tags/modules-correction-2' -SourceSha $sourceB -SourceRoot $cloneB -ArchiveSha256ByModule ([ordered]@{ 'mb-core'=('d'*64); 'mb-color'=('e'*64); 'mb-image'=('f'*64) }) -OutputDirectory (Join-Path $tempRoot 'correction-b')
    if ($candidateA.intent_sha256 -ceq $candidateB.intent_sha256) { throw 'REL01-CORRECTION-DIGEST: distinct corrections share a digest.' }
    $correctionA = Read-ReleaseCanonicalJson -Path $candidateA.intent_path
    $correctionB = Read-ReleaseCanonicalJson -Path $candidateB.intent_path
    if ($correctionA.root_intent_sha256 -cne $a.intent_sha256 -or $correctionB.root_intent_sha256 -cne $a.intent_sha256) { throw 'REL01-ROOT-DRIFT: correction root changed.' }
    $null = Assert-ReleaseIntentObject -Intent $correctionA -PolicyPath $policyPath -ExpectedCurrentSha256 $candidateA.intent_sha256 -ExpectedRootSha256 $a.intent_sha256 -ExpectedPredecessorSha256 $a.intent_sha256 -ExpectedPredecessorSequence 0 -AuthorizedSuccessorSha256 $candidateA.intent_sha256
    Confirm-IntentRule 'REL01-STALE-FORK' {
      Assert-ReleaseIntentObject -Intent $correctionB -PolicyPath $policyPath -ExpectedCurrentSha256 $candidateB.intent_sha256 -ExpectedRootSha256 $a.intent_sha256 -ExpectedPredecessorSha256 $a.intent_sha256 -ExpectedPredecessorSequence 0 -AuthorizedSuccessorSha256 $candidateA.intent_sha256
    }
    Confirm-IntentRule 'REL01-CORRECTION-TAG' { & $generator @correctionCommon -ReleaseRef 'refs/tags/modules-correction-0' -SourceSha $sourceA -SourceRoot $cloneA -ArchiveSha256ByModule $archives -OutputDirectory (Join-Path $tempRoot 'bad-tag') | Out-Null }
    $nonconsecutive = @{} + $correctionCommon; $nonconsecutive.CorrectionSequence = 2
    Confirm-IntentRule 'REL01-SEQUENCE' { & $generator @nonconsecutive -ReleaseRef 'refs/tags/modules-correction-3' -SourceSha $sourceA -SourceRoot $cloneA -ArchiveSha256ByModule $archives -OutputDirectory (Join-Path $tempRoot 'bad-sequence') | Out-Null }
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

function Invoke-QualificationIntegrationTests {
  $source = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-ReleaseQualification.ps1') -Raw
  $archivePosition = $source.IndexOf('Assert-ReleaseTrackedSnapshot -Before $initialDiff -After $finalDiff', [StringComparison]::Ordinal)
  $reportPosition = $source.IndexOf('Assert-WrittenReleaseReport -Path $reportPath', [StringComparison]::Ordinal)
  $intentPosition = $source.IndexOf('Write-InitialReleaseIntentBinding -ReleaseReport $report', [StringComparison]::Ordinal)
  if ($archivePosition -lt 0 -or $reportPosition -le $archivePosition -or $intentPosition -le $reportPosition) {
    throw 'REL01-INTEGRATION-ORDER: intent generation is not after tracked-diff and report validation.'
  }
  foreach ($forbidden in @('moon login','moon publish','credentials.json','MOONCAKES_TOKEN','Authorization:','Bearer ')) {
    if ($source.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "REL01-INTEGRATION-CREDENTIAL: qualification contains forbidden '$forbidden'." }
  }
  $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-intent-integration-' + [Guid]::NewGuid().ToString('N'))
  $null = New-Item -ItemType Directory -Force -Path $tempRoot
  try {
    $result = & (Join-Path $PSScriptRoot 'Invoke-ReleaseQualification.ps1') -Check -IntentIntegrationOnly -OutputDirectory $tempRoot
    $binding = Get-Content -LiteralPath $result.binding_path -Raw | ConvertFrom-Json -Depth 100
    $intent = Read-ReleaseCanonicalJson -Path $result.intent_path
    if ($binding.schema_version -cne 'mnf-release-intent-binding/1' -or $binding.intent_kind -cne 'initial' -or
        $binding.release_ref -cne 'refs/tags/modules-v0.1.0-r1' -or $binding.root_intent_sha256 -cne $binding.intent_sha256 -or
        $binding.intent_sha256 -cne $result.intent_sha256) { throw 'REL01-INITIAL-ROOT-BINDING: integration binding drifted.' }
    if ($null -ne $intent.PSObject.Properties['root_intent_sha256']) { throw 'REL01-HASH-CYCLE: integration serialized initial root inside intent.' }
    if ($binding.credentials_read -ne $false -or $binding.publication_performed -ne $false -or
        $intent.credentials_read -ne $false -or $intent.publication_performed -ne $false) { throw 'REL01-INTEGRATION-MUTATION: integration crossed credential/publication boundary.' }
    foreach ($field in @('qualification_root_sha256','required_stable_sha256','phase_06_ledger_sha256','interface_manifest_sha256')) {
      if ([string]$binding.$field -cnotmatch '^[0-9a-f]{64}$') { throw "REL01-INTEGRATION-EVIDENCE: missing $field." }
    }
    Write-Host 'Release intent qualification integration passed: one-way initial root/current binding after stable credential-free evidence.'
  } finally {
    if (Test-Path -LiteralPath $tempRoot) {
      $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
      $full = [IO.Path]::GetFullPath($tempRoot)
      if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
          -not (Split-Path -Leaf $full).StartsWith('mnf-intent-integration-', [StringComparison]::Ordinal)) { throw "Refusing to remove unverified integration path: $full" }
      Remove-Item -LiteralPath $full -Recurse -Force
    }
  }
}

if (-not ($ContractOnly -or $Focused -or $QualificationIntegration)) { $ContractOnly = $true; $Focused = $true }
Assert-IntentContract
if ($Focused) { Invoke-FocusedIntentTests }
if ($QualificationIntegration) { Invoke-QualificationIntegrationTests }
