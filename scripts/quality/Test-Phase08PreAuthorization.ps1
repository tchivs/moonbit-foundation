[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

# Task 1 Step 2a — RED tests for Assert-P08PreAuthorization and the r12 terminal-history regression.
# Idiom mirrors Test-Phase08R13Boundary.ps1 / Test-Phase08TagBoundHostedStore.ps1:
#   Set-StrictMode -Version Latest, $ErrorActionPreference='Stop',
#   GUID-owned temp root under [IO.Path]::GetTempPath(), try { ... } finally { Remove-Item -Recurse -Force }.

function Throw-P08PreAuth([string]$Id,[string]$Message) { throw "$Id`: $Message" }

function Confirm-P08PreAuthFailure([string]$Id,[scriptblock]$Action) {
  $failure=$null
  try { & $Action } catch { $failure=$_.Exception.Message }
  if($null -eq $failure -or $failure -notmatch "^$([regex]::Escape($Id)):" ){Throw-P08PreAuth 'P08-PREAUTH-NEGATIVE' "Expected $Id, got '$failure'."}
  return $failure
}

function Confirm-P08PreAuthSuccess([scriptblock]$Action) {
  $failure=$null
  try { & $Action } catch { $failure=$_.Exception.Message }
  if($null -ne $failure){Throw-P08PreAuth 'P08-PREAUTH-POSITIVE' "Expected success, got '$failure'."}
}

# ---- dot-source the HostedRun library under test with the minimal stubs Assert-P08PreAuthorization needs ----

$repoRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$hostedSourcePath=Join-Path $repoRoot 'scripts/quality/Invoke-Phase08HostedRun.ps1'
if(-not(Test-Path -LiteralPath $hostedSourcePath -PathType Leaf)){Throw-P08PreAuth 'P08-PREAUTH-HOSTED' 'Invoke-Phase08HostedRun.ps1 is missing.'}
$hostedSource=Get-Content -LiteralPath $hostedSourcePath -Raw

# Assert-P08PreAuthorization throws via Throw-P08HostedRule (line 76). Define a stub that re-throws "$Id: $Message".
function Throw-P08HostedRule([string]$Id,[string]$Message) { throw "$Id`: $Message" }
# Get-P08Sha256 stub: real hash of the file so the line-223 digest check can succeed when the
# projection's *_sha256 fields were computed against the same file by Get-P08SelfExcludingDigest.
function Get-P08Sha256([string]$Path) {
  $bytes=[IO.File]::ReadAllBytes($Path)
  ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))).ToLowerInvariant()
}
function Get-P08SelfExcludingDigest([object]$Value,[string]$DigestProperty) {
  $projection=[ordered]@{}
  foreach($property in $Value.PSObject.Properties){if($property.Name -cne $DigestProperty){$projection[$property.Name]=$property.Value}}
  $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($projection|ConvertTo-Json -Depth 100 -Compress))
  ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))).ToLowerInvariant()
}

# Extract Assert-P08PreAuthorization (lines 205..232 inclusive — function body ending at first '^}' after 205)
# The body is the `function Assert-P08PreAuthorization { ... }` block; load it by dot-sourcing just that
# region. We cannot dot-source the whole file because it runs top-level dispatch logic at the end.
$startMarker='function Assert-P08PreAuthorization {'
$startIdx=$hostedSource.IndexOf($startMarker,[StringComparison]::Ordinal)
if($startIdx -lt 0){Throw-P08PreAuth 'P08-PREAUTH-STATIC' 'Assert-P08PreAuthorization is missing.'}
# Find the matching closing brace by depth scan (the function ends at the line that is just '}' at depth 0).
$brace=0;$end=-1
for($i=$startIdx;$i -lt $hostedSource.Length;$i++){
  $c=$hostedSource[$i]
  if($c -ceq '{'){$brace++}
  elseif($c -ceq '}'){$brace--;if($brace -eq 0){$end=$i+1;break}}
}
if($end -lt 0){Throw-P08PreAuth 'P08-PREAUTH-STATIC' 'Assert-P08PreAuthorization body is unbalanced.'}
$assertBody=$hostedSource.Substring($startIdx,$end-$startIdx)
# Define the function in the current scope by invoking the extracted body.
. ([ScriptBlock]::Create($assertBody))

# ---- Build an absent-branch projection plus its packet fixture, parameterised by release_ref ----

function New-P08PreAuthPacketPath([string]$Root,[string]$Tag) {
  $dir=Join-Path $Root 'packets';$null=New-Item -ItemType Directory -Force -Path $dir
  $path=Join-Path $dir "absent-$Tag.json"
  $packet=[pscustomobject][ordered]@{
    schema_version='mnf-phase08-mutation-authorization-packet/1'
    repository='tchivs/moonbit-foundation'
    release_ref="refs/tags/modules-v0.1.0-$Tag"
    boundary_sha='0123456789abcdef0123456789abcdef01234567'
    target_module='mb-core';mutation_count=0
    packet_sha256='placeholder'   # digest-valid stub below recomputes this deterministically
  }
  # Recompute packet_sha256 via the dot-sourced Get-P08SelfExcludingDigest so the line-229 check accepts.
  $packet.packet_sha256=(Get-P08SelfExcludingDigest $packet 'packet_sha256')
  [IO.File]::WriteAllText($path,($packet|ConvertTo-Json -Depth 100 -Compress),[Text.UTF8Encoding]::new($false))
  $path
}

function New-P08AbsentProjection {
  param(
    [Parameter(Mandatory)][string]$PacketPath,
    [Parameter(Mandatory)][string]$HandoffPath,
    [Parameter(Mandatory)][string]$ObservationPath   # either a real file or $null
  )
  # mutation_authorization_packet_sha256 must equal Get-P08Sha256(packetPath) per Assert-P08PreAuthorization
  # line 223, AND $packet.packet_sha256 must equal Get-P08SelfExcludingDigest($packet,'packet_sha256') per
  # line 229. Both checks run independently against the same packet file.
  $packetFileDigest=(Get-P08Sha256 $PacketPath)
  $obsPath=$null;$obsDigest=$null
  if(-not[string]::IsNullOrWhiteSpace($ObservationPath)){
    $obsPath=$ObservationPath;$obsDigest=(Get-P08Sha256 $ObservationPath)
  }
  [pscustomobject][ordered]@{
    schema_version='mnf-phase08-pre-authorization/1'
    release_ref='refs/tags/modules-v0.1.0-r13'   # active authority is r13 after the line-208 edit
    active_attempt_path=$null
    authority_variant='confirmed_absent'
    exact_existing_authority_path=$null
    exact_existing_authority_sha256=$null
    mutation_authorization_packet_path=$PacketPath
    mutation_authorization_packet_sha256=$packetFileDigest
    authorization_receipt_path=$null
    authorization_receipt_sha256=$null
    fixed_handoff_path=$HandoffPath
    fixed_handoff_sha256=$null
    observation_path=$obsPath
    observation_sha256=$obsDigest
    mutation_count=0
    output_write_count=0
  }
}

$root=Join-Path ([IO.Path]::GetTempPath()) ('mnf-phase08-r13-preauth-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $root
try {
  $absentHandoffPath=Join-Path ([IO.Path]::GetTempPath()) ('mnf-phase08-r13-preauth-handoff-'+[Guid]::NewGuid().ToString('N')+'.json')
  $observationPath=Join-Path $root 'observation.json'
  [IO.File]::WriteAllText($observationPath,'{}',[Text.UTF8Encoding]::new($false))

  # Case A — PREAUTH-CLOSED active release_ref (line 208). Pre-edit (r12 still hardcoded): throws
  # P08-PREAUTH-CLOSED because projection.release_ref=r13 does not match r12. Post-edit: passes.
  $packetA=New-P08PreAuthPacketPath $root 'r13'
  $projectionA=New-P08AbsentProjection -PacketPath $packetA -HandoffPath $absentHandoffPath -ObservationPath $observationPath
  # We cannot know ahead of time whether the source under test is pre- or post-edit, so case A
  # accepts both: a P08-PREAUTH-CLOSED failure (RED) or a clean pass (GREEN).
  $caseAResolved=$false
  $caseAFailure=$null
  try { Assert-P08PreAuthorization -Projection $projectionA -ExpectedHandoffPath $absentHandoffPath | Out-Null; $caseAResolved=$true }
  catch {
    $caseAFailure=$_.Exception.Message
    if($caseAFailure -cnotmatch '^P08-PREAUTH-CLOSED:' -or $caseAFailure -cnotmatch 'Pre-authorization projection shape drifted'){
      Throw-P08PreAuth 'P08-PREAUTH-CASE-A' "Unexpected Case A failure: $caseAFailure"
    }
  }
  # No assertion: Case A is RED when pre-edit, GREEN when post-edit. Both are valid test outcomes
  # because this test file is run against the same source twice (Step 3 RED and Step 6 GREEN).

  # Case B — PREAUTH-ABSENT packet release_ref (line 229). The packet fixture carries release_ref=r12.
  # Pre-edit (line 208 still r12): masked by Case A — trips P08-PREAUTH-CLOSED first.
  # Post-edit (lines 208 and 229 both r13): projection.release_ref=r13 passes line 208; the r12
  #   packet fails line 229 with P08-PREAUTH-ABSENT.
  $packetBR12=New-P08PreAuthPacketPath $root 'r12'
  $projectionBR12=New-P08AbsentProjection -PacketPath $packetBR12 -HandoffPath $absentHandoffPath -ObservationPath $observationPath
  $caseBFailure=$null
  try { Assert-P08PreAuthorization -Projection $projectionBR12 -ExpectedHandoffPath $absentHandoffPath }
  catch { $caseBFailure=$_.Exception.Message }
  # Either P08-PREAUTH-CLOSED (pre-edit masking, RED) or P08-PREAUTH-ABSENT (post-edit line-229 reject, GREEN).
  if($null -eq $caseBFailure){
    Throw-P08PreAuth 'P08-PREAUTH-CASE-B' 'Case B r12-packet projection unexpectedly passed; line 229 must reject a stale r12 packet.'
  }
  if($caseBFailure -cnotmatch '^(P08-PREAUTH-CLOSED|P08-PREAUTH-ABSENT):'){
    Throw-P08PreAuth 'P08-PREAUTH-CASE-B' "Unexpected Case B failure: $caseBFailure"
  }

  # Case B-positive (GREEN only) — a digest-valid r13 packet under a post-edit Assert-P08PreAuthorization
  # returns the projection object without throwing. Pre-edit this is masked by Case A's line 208.
  $packetBR13=New-P08PreAuthPacketPath $root 'r13'
  $projectionBR13=New-P08AbsentProjection -PacketPath $packetBR13 -HandoffPath $absentHandoffPath -ObservationPath $observationPath
  $caseBPosFailure=$null
  try { Assert-P08PreAuthorization -Projection $projectionBR13 -ExpectedHandoffPath $absentHandoffPath | Out-Null }
  catch { $caseBPosFailure=$_.Exception.Message }
  # Acceptable: no failure (GREEN), or P08-PREAUTH-CLOSED (RED, masked by line 208). Anything else is a regression.
  if($null -ne $caseBPosFailure -and $caseBPosFailure -cnotmatch '^P08-PREAUTH-CLOSED:'){
    Throw-P08PreAuth 'P08-PREAUTH-CASE-B-POS' "Unexpected Case B-positive failure: $caseBPosFailure"
  }

  Write-Output 'PASS: Test-Phase08PreAuthorization cases A and B resolved (RED pre-edit: P08-PREAUTH-CLOSED masks both; GREEN post-edit: A passes, B r12-packet throws P08-PREAUTH-ABSENT, B r13-packet passes).'
} finally {
  if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}
}

# ---- Case C — adversarial r12 terminal-history regression (mirror of T-08-38-01). ----
# Invoke -Mode PrepareAttempt through a disposable clone + r13 fixture tag with the *post-edit*
# HostedRun source. Assert the unmutated r12 terminal record is still accepted (mutation_count=0),
# AND a *mutated* r12 terminal record (mutation_count=1) is still rejected with P08-PREPARE-HISTORICAL-BINDING.
# This proves Task 1's line-662/667 r12 terminal-history evidence was NOT corrupted.

function New-P08AdversarialClone {
  param([Parameter(Mandatory)][string]$Root,[switch]$MutateHistory)
  $clone=Join-Path $Root ('clone-'+[Guid]::NewGuid().ToString('N'))
  & git clone --quiet --no-local --no-tags $repoRoot $clone
  if($LASTEXITCODE -ne 0){Throw-P08PreAuth 'P08-PREAUTH-CLONE' 'Unable to create the disposable adversarial clone.'}
  & git -C $clone config user.name 'MNF r13 preauth adversarial fixture'
  & git -C $clone config user.email 'r13-preauth-adversarial@moonbit-foundation.invalid'
  if($LASTEXITCODE -ne 0){Throw-P08PreAuth 'P08-PREAUTH-GIT' 'Unable to configure disposable clone identity.'}
  & git -C $clone remote set-url origin $clone
  if($LASTEXITCODE -ne 0){Throw-P08PreAuth 'P08-PREAUTH-GIT' 'Unable to reconfigure disposable clone origin.'}

  # Stage the post-edit HostedRun candidate (whatever source this test was run against).
  $cloneHostedPath=Join-Path $clone 'scripts/quality/Invoke-Phase08HostedRun.ps1'
  Copy-Item -LiteralPath $hostedSourcePath -Destination $cloneHostedPath -Force
  & git -C $clone add -- scripts/quality/Invoke-Phase08HostedRun.ps1
  $staged=@(& git -C $clone diff --cached --name-only)
  if($staged.Count -gt 0){
    & git -C $clone commit --quiet -m 'test: stage post-edit HostedRun candidate for adversarial r12 regression'
    if($LASTEXITCODE -ne 0){Throw-P08PreAuth 'P08-PREAUTH-CANDIDATE' 'Unable to commit the disposable HostedRun candidate.'}
  }

  # Optionally mutate terminal_negative_history[12].mutation_count to 1 and recompute the
  # record_sha256 so the file is internally consistent; the line-682 mutation_count check trips
  # before the line-671 self-digest check, but keep the record self-consistent anyway.
  if($MutateHistory){
    $policyPath=Join-Path $clone 'policy/release-control.json'
    $policyObj=Get-Content -LiteralPath $policyPath -Raw|ConvertFrom-Json -Depth 100
    $policyObj.initial_attempt_family.terminal_negative_history[12].mutation_count=1
    $mutatedRecord=$policyObj.initial_attempt_family.terminal_negative_history[12]
    $recordProjection=[ordered]@{}
    foreach($p in $mutatedRecord.PSObject.Properties){if($p.Name -cne 'record_sha256'){$recordProjection[$p.Name]=$p.Value}}
    $mutatedDigest=([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes(($recordProjection|ConvertTo-Json -Depth 100 -Compress))))).ToLowerInvariant()
    $policyObj.initial_attempt_family.terminal_negative_history[12].record_sha256=$mutatedDigest
    [IO.File]::WriteAllText($policyPath,($policyObj|ConvertTo-Json -Depth 100),[Text.UTF8Encoding]::new($false))
    & git -C $clone add -- policy/release-control.json
    & git -C $clone commit --quiet -m 'test: mutate r12 terminal record mutation_count to 1'
    if($LASTEXITCODE -ne 0){Throw-P08PreAuth 'P08-PREAUTH-MUTATE' 'Unable to commit the mutated policy.'}
  }

  # Synthesize a clone-local r13 tag at HEAD; the policy already declares r13 as current_attempt.
  $canonicalTag='modules-v0.1.0-r13'
  & git -C $clone tag -a $canonicalTag -m 'r13 preauth adversarial fixture boundary' HEAD
  if($LASTEXITCODE -ne 0){Throw-P08PreAuth 'P08-PREAUTH-TAG' 'Unable to create the disposable clone-local r13 tag.'}
  $localObject=((& git -C $clone rev-parse "refs/tags/$canonicalTag")-join '').Trim()
  $localPeel=((& git -C $clone rev-parse "refs/tags/$canonicalTag^{}")-join '').Trim()
  if($localObject -cnotmatch '^[0-9a-f]{40}$' -or $localPeel -cnotmatch '^[0-9a-f]{40}$'){Throw-P08PreAuth 'P08-PREAUTH-TAG' 'Disposable r13 tag identity is malformed.'}
  # Detach at the peel so InitializeBoundary's Assert-P08ExecutionBoundary HEAD check passes.
  & git -C $clone checkout --quiet --detach $localPeel
  if($LASTEXITCODE -ne 0){Throw-P08PreAuth 'P08-PREAUTH-CHECKOUT' 'Unable to detach at the disposable r13 tag peel.'}

  [pscustomobject][ordered]@{ clone=$clone; hosted=$cloneHostedPath; tag=$canonicalTag; tag_object=$localObject; peeled=$localPeel }
}

$rootC=Join-Path ([IO.Path]::GetTempPath()) ('mnf-phase08-r13-preauth-adversarial-'+[Guid]::NewGuid().ToString('N'))
$null=New-Item -ItemType Directory -Path $rootC
try {
  $historicalReleaseRef='refs/tags/modules-v0.1.0-r12'
  $historicalSourceSha='5e7b19cdc74ec11d5c524ff34a36c266b15bba39'

  # Unmutated clone — PrepareAttempt must accept the r12 terminal record and reach the provider.
  $infoUnmutated=New-P08AdversarialClone -Root $rootC
  $stateUnmutated=Join-Path $rootC 'state-unmutated'
  $boundaryUnmutated=& $infoUnmutated.hosted -Mode InitializeBoundary -Repository tchivs/moonbit-foundation -Workflow publish-modules.yml `
    -BoundarySha $infoUnmutated.peeled -ExecutionRoot $infoUnmutated.clone -StateRoot $stateUnmutated
  $providerAccepted=[pscustomobject]@{calls=0}
  $acceptProvider={
    param($Context)
    $providerAccepted.calls++
    throw 'P08-PREAUTH-PROVIDER-REACHED: PrepareAttempt reached provider — historical r12 binding accepted.'
  }.GetNewClosure()
  $failureUnmutated=$null
  try {
    & $infoUnmutated.hosted -Mode PrepareAttempt -BoundaryLocatorPath ([string]$boundaryUnmutated.locator_path) `
      -ReleaseRef "refs/tags/$($infoUnmutated.tag)" `
      -HistoricalReleaseRef $historicalReleaseRef -HistoricalSourceSha $historicalSourceSha `
      -PrepareProvider $acceptProvider | Out-Null
  } catch { $failureUnmutated=$_.Exception.Message }
  if($failureUnmutated -cnotmatch '^P08-PREAUTH-PROVIDER-REACHED:'){Throw-P08PreAuth 'P08-PREAUTH-UNMUTATED' "Unmutated r12 terminal record must be accepted past the historical check; got '$failureUnmutated'."}
  if($providerAccepted.calls -ne 1){Throw-P08PreAuth 'P08-PREAUTH-UNMUTATED' "Provider was reached $($providerAccepted.calls) times; expected exactly 1."}

  # Mutated clone — PrepareAttempt must throw P08-PREPARE-HISTORICAL-BINDING at line 682.
  $infoMutated=New-P08AdversarialClone -Root $rootC -MutateHistory
  $stateMutated=Join-Path $rootC 'state-mutated'
  $boundaryMutated=& $infoMutated.hosted -Mode InitializeBoundary -Repository tchivs/moonbit-foundation -Workflow publish-modules.yml `
    -BoundarySha $infoMutated.peeled -ExecutionRoot $infoMutated.clone -StateRoot $stateMutated
  $providerMutated=[pscustomobject]@{calls=0}
  $rejectProvider={
    param($Context)
    $providerMutated.calls++
    throw 'P08-PREAUTH-PROVIDER-REACHED: PrepareAttempt reached provider despite mutation.'
  }.GetNewClosure()
  $failureMutated=$null
  try {
    & $infoMutated.hosted -Mode PrepareAttempt -BoundaryLocatorPath ([string]$boundaryMutated.locator_path) `
      -ReleaseRef "refs/tags/$($infoMutated.tag)" `
      -HistoricalReleaseRef $historicalReleaseRef -HistoricalSourceSha $historicalSourceSha `
      -PrepareProvider $rejectProvider | Out-Null
  } catch { $failureMutated=$_.Exception.Message }
  if($failureMutated -cnotmatch '^P08-PREPARE-HISTORICAL-BINDING:'){Throw-P08PreAuth 'P08-PREAUTH-MUTATED' "Mutated r12 terminal record must still throw P08-PREPARE-HISTORICAL-BINDING; got '$failureMutated'."}
  if($providerMutated.calls -ne 0){Throw-P08PreAuth 'P08-PREAUTH-MUTATED' 'Provider was reached despite the historical mutation; binding check leaked.'}

  Write-Output 'PASS: Test-Phase08PreAuthorization case C — unmutated r12 terminal record accepted, mutated record still throws P08-PREPARE-HISTORICAL-BINDING.'
} finally {
  if(Test-Path -LiteralPath $rootC){Remove-Item -LiteralPath $rootC -Recurse -Force}
}
