[CmdletBinding()]
param(
  [switch]$Check,
  [Parameter(Mandatory)][ValidateSet('initial','forward_correction')][string]$IntentKind,
  [Parameter(Mandatory)][string]$ReleaseRef,
  [Parameter(Mandatory)][string]$OutputDirectory,
  [string]$SourceSha,
  [string]$SourceRoot,
  [Parameter(Mandatory)][string]$QualificationRootSha256,
  [Parameter(Mandatory)][string]$RequiredStableSha256,
  [Parameter(Mandatory)][hashtable]$ArchiveSha256ByModule,
  [string]$RootIntentSha256,
  [string]$PredecessorIntentSha256,
  [string]$PredecessorSourceSha,
  [int]$PredecessorSequence = -1,
  [int]$CorrectionSequence = 0,
  [string]$IncidentSha256,
  [string]$AdvisorySha256,
  [string]$CompatibilityResultSha256,
  [string]$VersionAbsenceSha256,
  [hashtable]$CorrectedVersions
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')

if (-not $Check) { Throw-ReleaseRule -Id 'REL01-CHECK-REQUIRED' -Message 'intent generation is evidence-only and requires -Check.' }
$releasePolicyPath = Join-Path $repoRoot 'policy\release-qualification.json'
$controlPolicyPath = Join-Path $repoRoot 'policy\release-control.json'
$compatibilityPolicyPath = Join-Path $repoRoot 'policy\compatibility.json'
$baselineManifestPath = Join-Path $repoRoot 'compatibility\baselines\0.1.0\manifest.json'
$phase06LedgerPath = Join-Path $repoRoot 'release\qualification\phase-06-requirements.json'
$releasePolicy = Read-ReleaseJson -Path $releasePolicyPath
$control = Read-ReleaseJson -Path $controlPolicyPath
$baseline = Read-ReleaseJson -Path $baselineManifestPath

function Get-InitialHistoryRecordSha256 {
  param([Parameter(Mandatory)][object]$Record)
  $projection = [ordered]@{}
  foreach ($name in @($Record.PSObject.Properties.Name | Where-Object { $_ -cne 'record_sha256' })) { $projection[$name] = $Record.$name }
  return Get-ReleaseTextSha256 -Text ($projection | ConvertTo-Json -Depth 30 -Compress)
}

function Assert-InitialAttemptFamily {
  param([Parameter(Mandatory)][object]$Control)
  $history = @($Control.initial_attempt_family.terminal_negative_history)
  if ($history.Count -ne 5 -or ($history.attempt -join ',') -cne 'attempt_zero,r1,r2,r3,r4') {
    Throw-ReleaseRule -Id 'REL01-HISTORY-ORDER' -Message 'attempt-zero, r1, r2, r3, and r4 are required in canonical order.'
  }
  foreach ($record in $history) {
    if ($record.record_sha256 -cne (Get-InitialHistoryRecordSha256 $record)) {
      Throw-ReleaseRule -Id 'REL01-HISTORY-DIGEST' -Message "terminal history digest drifted for $($record.attempt)."
    }
  }
  if (@($history.record_sha256 | Select-Object -Unique).Count -ne 5) {
    Throw-ReleaseRule -Id 'REL01-HISTORY-DIGEST' -Message 'terminal history digests must be distinct.'
  }
  $setDigest = Get-ReleaseTextSha256 -Text ((@($history.record_sha256) -join "`n"))
  if ($Control.initial_attempt_family.history_set_profile -cne 'sha256-of-lf-joined-record-sha256-in-canonical-attempt-order' -or
      $Control.initial_attempt_family.history_set_sha256 -cne $setDigest -or $Control.initial_attempt_family.current_attempt -cne 'r5') {
    Throw-ReleaseRule -Id 'REL01-HISTORY-SET' -Message 'ordered terminal history set or current attempt drifted.'
  }
  return $history
}

$initialHistory = @(Assert-InitialAttemptFamily -Control $control)

if ([string]::IsNullOrEmpty($SourceSha)) {
  $SourceSha = (& git -C $repoRoot rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0) { Throw-ReleaseRule -Id 'REL01-SOURCE' -Message 'unable to resolve source HEAD.' }
}
if ($SourceSha -cnotmatch '^[0-9a-f]{40}$') { Throw-ReleaseRule -Id 'REL01-EMPTY' -Message 'source SHA is missing or malformed.' }
$absoluteSourceRoot = if ([string]::IsNullOrEmpty($SourceRoot)) { $repoRoot } elseif ([IO.Path]::IsPathRooted($SourceRoot)) { [IO.Path]::GetFullPath($SourceRoot) } else { [IO.Path]::GetFullPath((Join-Path $repoRoot $SourceRoot)) }
$observedSourceSha = (& git -C $absoluteSourceRoot rev-parse HEAD 2>$null).Trim()
if ($LASTEXITCODE -ne 0 -or $observedSourceSha -cne $SourceSha) { Throw-ReleaseRule -Id 'REL01-SOURCE' -Message 'source root HEAD does not equal the bound source SHA.' }
$sourceStatus = @(& git -C $absoluteSourceRoot status --porcelain=v1 --untracked-files=all 2>$null)
if ($LASTEXITCODE -ne 0 -or $sourceStatus.Count -ne 0) { Throw-ReleaseRule -Id 'REL01-DIRTY-SOURCE' -Message 'source root is not a clean Git checkout.' }
$resolvedRef = (& git -C $absoluteSourceRoot rev-parse "$ReleaseRef^{}" 2>$null).Trim()
if ($LASTEXITCODE -eq 0 -and $resolvedRef -cne $SourceSha) { Throw-ReleaseRule -Id 'REL01-REF-TARGET' -Message 'existing release ref does not peel to the bound source SHA.' }
foreach ($digest in @($QualificationRootSha256,$RequiredStableSha256)) { if (-not (Test-ReleaseSha256Text $digest)) { Throw-ReleaseRule -Id 'REL01-EVIDENCE' -Message 'qualification digest is missing or malformed.' } }

if ($IntentKind -ceq 'initial') {
  if ($ReleaseRef -cne $control.initial_profile.release_ref) { Throw-ReleaseRule -Id 'REL01-REF' -Message 'initial release ref is not the dedicated immutable tag.' }
  if (@($control.initial_attempt_family.terminal_negative_history.source_sha) -ccontains $SourceSha) { Throw-ReleaseRule -Id 'REL01-HISTORICAL-SOURCE' -Message 'a terminal-negative source cannot be reused as r5 current authority.' }
  if ($CorrectionSequence -ne 0 -or -not [string]::IsNullOrEmpty($RootIntentSha256) -or -not [string]::IsNullOrEmpty($PredecessorIntentSha256)) {
    Throw-ReleaseRule -Id 'REL01-HASH-CYCLE' -Message 'initial intent must not serialize root, predecessor, or a correction sequence.'
  }
  if (-not [string]::IsNullOrEmpty($PredecessorSourceSha) -or $PredecessorSequence -ne -1 -or
      -not [string]::IsNullOrEmpty($IncidentSha256) -or -not [string]::IsNullOrEmpty($AdvisorySha256) -or
      -not [string]::IsNullOrEmpty($CompatibilityResultSha256) -or -not [string]::IsNullOrEmpty($VersionAbsenceSha256) -or
      $null -ne $CorrectedVersions) {
    Throw-ReleaseRule -Id 'REL01-CORRECTION-EVIDENCE' -Message 'initial r5 cannot carry correction-lane evidence.'
  }
} else {
  if ($ReleaseRef -cnotmatch $control.correction_profile.release_ref_pattern) { Throw-ReleaseRule -Id 'REL01-CORRECTION-TAG' -Message 'correction tag is noncanonical.' }
  foreach ($digest in @($RootIntentSha256,$PredecessorIntentSha256,$IncidentSha256,$AdvisorySha256,$CompatibilityResultSha256,$VersionAbsenceSha256)) {
    if (-not (Test-ReleaseSha256Text $digest)) { Throw-ReleaseRule -Id 'REL01-CORRECTION-EVIDENCE' -Message 'correction digest is missing or malformed.' }
  }
  if ($CorrectionSequence -ne ($PredecessorSequence + 1) -or $CorrectionSequence -lt 1) { Throw-ReleaseRule -Id 'REL01-SEQUENCE' -Message 'correction sequence must equal predecessor plus one.' }
  if ($PredecessorSourceSha -cnotmatch '^[0-9a-f]{40}$' -or $SourceSha -ceq $PredecessorSourceSha) { Throw-ReleaseRule -Id 'REL01-FRESH-SOURCE' -Message 'correction source must differ from its predecessor source.' }
  if ($null -eq $CorrectedVersions) { Throw-ReleaseRule -Id 'REL01-FORWARD-VERSION' -Message 'corrected versions are missing.' }
}

$modules = [Collections.Generic.List[object]]::new()
foreach ($shortName in @($releasePolicy.module_order)) {
  if (-not $ArchiveSha256ByModule.ContainsKey($shortName) -or -not (Test-ReleaseSha256Text $ArchiveSha256ByModule[$shortName])) { Throw-ReleaseRule -Id 'REL01-EVIDENCE' -Message "archive digest is missing for $shortName." }
  $modulePolicy = $releasePolicy.modules.$shortName
  $version = if ($IntentKind -ceq 'initial') { [string]$modulePolicy.manifest.version } else {
    if (-not $CorrectedVersions.ContainsKey($shortName)) { Throw-ReleaseRule -Id 'REL01-FORWARD-VERSION' -Message "corrected version missing for $shortName." }
    [string]$CorrectedVersions[$shortName]
  }
  if ($IntentKind -ceq 'forward_correction' -and ([version]$version -le [version]'0.1.0' -or $version -cnotmatch '^0[.][0-9]+[.][0-9]+$')) { Throw-ReleaseRule -Id 'REL01-FORWARD-VERSION' -Message "corrected version is not a forward pre-1.0 version for $shortName." }
  $dependencies = [Collections.Generic.List[object]]::new()
  foreach ($dependencyName in @($modulePolicy.dependencies.PSObject.Properties | ForEach-Object { $_.Name })) {
    $dependencyShort = $dependencyName.Substring('tchivs/'.Length)
    $dependencyVersion = if ($IntentKind -ceq 'initial') { [string]$modulePolicy.dependencies.$dependencyName } else { [string]$CorrectedVersions[$dependencyShort] }
    $dependencies.Add([ordered]@{ identity = $dependencyName; version = $dependencyVersion })
  }
  $interfaceRecords = @($baseline.packages | Where-Object { [string]$_.module -ceq $shortName } | ForEach-Object { "$($_.package):$($_.baseline_sha256):$($_.raw_sha256)" })
  if ($interfaceRecords.Count -ne @($modulePolicy.public_packages).Count) { Throw-ReleaseRule -Id 'REL01-INTERFACE-EVIDENCE' -Message "interface baseline inventory drifted for $shortName." }
  $modules.Add([ordered]@{
    module = $shortName
    identity = [string]$modulePolicy.manifest.name
    version = $version
    dependencies = [object[]]$dependencies.ToArray()
    public_packages = [object[]]@($modulePolicy.public_packages)
    archive_sha256 = [string]$ArchiveSha256ByModule[$shortName]
    interface_sha256 = Get-ReleaseTextSha256 -Text ($interfaceRecords -join "`n")
  })
}

$intent = [ordered]@{
  schema_version = 'mnf-release-intent/1'
  intent_kind = $IntentKind
  repository = [string]$control.repository
  owner = [string]$control.owner
  release_ref = $ReleaseRef
  source_sha = $SourceSha
}
if ($IntentKind -ceq 'forward_correction') {
  $intent.root_intent_sha256 = $RootIntentSha256
  $intent.predecessor_intent_sha256 = $PredecessorIntentSha256
}
$intent.correction_sequence = $CorrectionSequence
$intent.toolchain = [ordered]@{
  moon = [string]$control.pinned_toolchain.moon
  moonc = [string]$control.pinned_toolchain.moonc
  moonrun = [string]$control.pinned_toolchain.moonrun
}
$intent.modules = [object[]]$modules.ToArray()
$intent.evidence = [ordered]@{
  qualification_root_sha256 = $QualificationRootSha256
  required_stable_sha256 = $RequiredStableSha256
  phase_06_ledger_sha256 = Get-ReleaseSha256 -Path $phase06LedgerPath
  release_policy_sha256 = Get-ReleaseSha256 -Path $releasePolicyPath
  compatibility_policy_sha256 = Get-ReleaseSha256 -Path $compatibilityPolicyPath
}
if ($IntentKind -ceq 'forward_correction') {
  $intent.correction_evidence = [ordered]@{
    superseded_intent_sha256 = $PredecessorIntentSha256
    incident_sha256 = $IncidentSha256
    advisory_sha256 = $AdvisorySha256
    compatibility_result_sha256 = $CompatibilityResultSha256
    version_absence_sha256 = $VersionAbsenceSha256
  }
}
$intent.tracked_source_clean = $true
$intent.credentials_read = $false
$intent.publication_performed = $false

$canonical = ConvertTo-ReleaseCanonicalJson -Value $intent -Profile ReleaseIntent
$digest = Get-ReleaseTextSha256 -Text $canonical
$null = Assert-ReleaseIntentObject -Intent ([pscustomobject]$intent) -PolicyPath $controlPolicyPath -ExpectedCurrentSha256 $digest `
  -ExpectedRootSha256 $(if ($IntentKind -ceq 'forward_correction') { $RootIntentSha256 } else { '' }) `
  -ExpectedPredecessorSha256 $(if ($IntentKind -ceq 'forward_correction') { $PredecessorIntentSha256 } else { '' }) `
  -ExpectedPredecessorSequence $PredecessorSequence

$absoluteOutput = if ([IO.Path]::IsPathRooted($OutputDirectory)) { [IO.Path]::GetFullPath($OutputDirectory) } else { [IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory)) }
$null = New-Item -ItemType Directory -Force -Path $absoluteOutput
$intentPath = Join-Path $absoluteOutput 'intent.json'
$digestPath = Join-Path $absoluteOutput 'intent.sha256'
$nonce = [Guid]::NewGuid().ToString('N')
$intentTemp = Join-Path $absoluteOutput ".intent.$nonce.tmp"
$digestTemp = Join-Path $absoluteOutput ".intent-sha.$nonce.tmp"
try {
  [IO.File]::WriteAllText($intentTemp, $canonical, [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText($digestTemp, $digest, [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $intentTemp -Destination $intentPath -Force
  Move-Item -LiteralPath $digestTemp -Destination $digestPath -Force
} finally {
  if (Test-Path -LiteralPath $intentTemp) { Remove-Item -LiteralPath $intentTemp -Force }
  if (Test-Path -LiteralPath $digestTemp) { Remove-Item -LiteralPath $digestTemp -Force }
}

return [pscustomobject]@{
  intent_path = $intentPath
  digest_path = $digestPath
  intent_sha256 = $digest
  root_intent_sha256 = if ($IntentKind -ceq 'initial') { $digest } else { $RootIntentSha256 }
  credentials_read = $false
  publication_performed = $false
}
