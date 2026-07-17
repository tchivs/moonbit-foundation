Set-StrictMode -Version Latest

function Throw-ReleaseRule {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][string]$Message)
  throw "$Id`: $Message"
}

function Read-ReleaseJson {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required JSON is missing: $Path" }
  try { return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100 } catch { throw "Invalid JSON '$Path': $($_.Exception.Message)" }
}

function Assert-ReleaseExactSequence {
  param([string]$Label, [object[]]$Actual, [object[]]$Expected)
  if ($Actual.Count -ne $Expected.Count) { throw "$Label count mismatch: expected $($Expected.Count), got $($Actual.Count)." }
  for ($i = 0; $i -lt $Expected.Count; $i++) {
    if ([string]$Actual[$i] -cne [string]$Expected[$i]) { throw "$Label mismatch at index $i`: expected '$($Expected[$i])', got '$($Actual[$i])'." }
  }
}

function Assert-ReleaseExactSet {
  param([string]$Label, [object[]]$Actual, [object[]]$Expected)
  $actualText = @($Actual | ForEach-Object { [string]$_ } | Sort-Object -CaseSensitive)
  $expectedText = @($Expected | ForEach-Object { [string]$_ } | Sort-Object -CaseSensitive)
  Assert-ReleaseExactSequence -Label $Label -Actual $actualText -Expected $expectedText
}

function Assert-ReleaseClosedProperties {
  param([string]$Label, [object]$Object, [string[]]$Expected)
  if ($null -eq $Object) { throw "$Label is missing." }
  Assert-ReleaseExactSet -Label "$Label properties" -Actual @($Object.PSObject.Properties | ForEach-Object { $_.Name }) -Expected $Expected
}

function Get-ReleaseTrackedDiffSnapshot {
  $output = @(& git diff --binary --no-ext-diff HEAD -- 2>&1 | ForEach-Object { $_.ToString() })
  if ($LASTEXITCODE -ne 0) { throw "Unable to capture tracked diff (exit $LASTEXITCODE)." }
  return ($output -join "`n")
}

function Get-ReleaseSha256 {
  param([Parameter(Mandatory)][string]$Path)
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-ReleaseTextSha256 {
  param([Parameter(Mandatory)][string]$Text)
  $algorithm = [Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text)
    return ([Convert]::ToHexString($algorithm.ComputeHash($bytes))).ToLowerInvariant()
  } finally { $algorithm.Dispose() }
}

function Assert-StaticRequirementLedger {
  param([Parameter(Mandatory)][string]$Path)
  $ledger = Read-ReleaseJson -Path $Path
  Assert-ReleaseClosedProperties -Label 'v0.1 requirement ledger' -Object $ledger -Expected @(
    'schema_version', 'candidate', 'required_entrypoint', 'selectors', 'requirements', 'artifact_contracts', 'allowed_blocked_outcomes'
  )
  if ($ledger.schema_version -cne '1.0.0' -or $ledger.candidate -cne 'v0.1' -or
      $ledger.required_entrypoint -cne 'pwsh -NoProfile -File scripts/quality.ps1 -Lane Required -EvidenceDirectory <untracked-evidence-directory>') {
    throw 'Static requirement ledger identity or Required entrypoint drifted.'
  }
  $forbiddenProperties = [Collections.Generic.List[string]]::new()
  function Find-DynamicProperty([object]$Value, [string]$At) {
    if ($null -eq $Value) { return }
    if ($Value -is [string] -or $Value -is [ValueType]) { return }
    if ($Value -is [Collections.IEnumerable] -and $Value -isnot [Management.Automation.PSCustomObject]) {
      $index = 0
      foreach ($item in $Value) { Find-DynamicProperty -Value $item -At "$At[$index]"; $index++ }
      return
    }
    foreach ($property in @($Value.PSObject.Properties)) {
      if ($property.Name -cmatch '^(?:run(?:_?id)?|timestamp|commit|result|environment|digest|sha256|head)$') {
        $forbiddenProperties.Add("$At.$($property.Name)")
      }
      Find-DynamicProperty -Value $property.Value -At "$At.$($property.Name)"
    }
  }
  Find-DynamicProperty -Value $ledger -At '$'
  if ($forbiddenProperties.Count -ne 0) {
    throw "Static requirement ledger contains dynamic evidence properties: $($forbiddenProperties -join ', ')."
  }

  $selectorIds = @($ledger.selectors | ForEach-Object { [string]$_.id })
  if ($selectorIds.Count -ne 19 -or @($selectorIds | Sort-Object -Unique).Count -ne $selectorIds.Count) {
    throw 'Static requirement ledger must contain exactly 19 unique ordered selectors.'
  }
  foreach ($selector in @($ledger.selectors)) {
    Assert-ReleaseClosedProperties -Label "selector $($selector.id)" -Object $selector -Expected @('id', 'focused_command', 'proves', 'policy_rule_ids')
    if ([string]::IsNullOrWhiteSpace([string]$selector.focused_command) -or @($selector.proves).Count -eq 0) {
      throw "Selector '$($selector.id)' lacks an executable focused command or requirement ownership."
    }
  }
  $requirementIds = @('WORK-06', 'QUAL-01', 'QUAL-02', 'QUAL-03', 'QUAL-04', 'QUAL-05', 'QUAL-06')
  Assert-ReleaseExactSet -Label 'ledger requirement IDs' -Actual @($ledger.requirements.PSObject.Properties.Name) -Expected $requirementIds
  foreach ($id in $requirementIds) {
    $mapped = @($ledger.requirements.$id | ForEach-Object { [string]$_ })
    if ($mapped.Count -eq 0) { throw "Requirement '$id' has no selectors." }
    foreach ($selectorId in $mapped) {
      if ($selectorIds -cnotcontains $selectorId) { throw "Requirement '$id' references unknown selector '$selectorId'." }
      $owner = @($ledger.selectors | Where-Object { [string]$_.id -ceq $selectorId })[0]
      if (@($owner.proves | ForEach-Object { [string]$_ }) -cnotcontains $id) {
        throw "Selector '$selectorId' does not reciprocally claim requirement '$id'."
      }
    }
  }
  Assert-ReleaseExactSequence -Label 'artifact contracts' -Actual @($ledger.artifact_contracts.id) -Expected @(
    'foundation-policy', 'fixture-manifest', 'example-consumers', 'benchmark-baseline', 'release-packages'
  )
  foreach ($artifact in @($ledger.artifact_contracts)) {
    $properties = @($artifact.PSObject.Properties.Name)
    if ($properties.Count -ne 3 -or $properties -cnotcontains 'id' -or $properties -cnotcontains 'schema' -or
        (($properties -ccontains 'tracked_path') -eq ($properties -ccontains 'dynamic_path'))) {
      throw "Artifact contract '$($artifact.id)' is not a closed tracked-or-dynamic schema mapping."
    }
  }
  Assert-ReleaseExactSequence -Label 'allowed blocked outcomes' -Actual @($ledger.allowed_blocked_outcomes) -Expected @(
    'mb-color.artifact_consumer=blocked_unpublished_dependency',
    'mb-color.registry_resolution=blocked_unpublished_namespace',
    'mb-image.artifact_consumer=blocked_unpublished_dependency',
    'mb-image.registry_resolution=blocked_unpublished_namespace'
  )
  return $ledger
}

function Get-RequiredRunStableObject {
  param([Parameter(Mandatory)][object]$Report)
  return [ordered]@{
    schema_version = [string]$Report.schema_version
    head = [string]$Report.head
    ledger_sha256 = [string]$Report.ledger_sha256
    selector_order = @($Report.selector_order)
    selectors = @($Report.selectors)
    artifacts = @($Report.artifacts)
    publication = $Report.publication
    tracked_diff_unchanged = [bool]$Report.tracked_diff_unchanged
  }
}

function Write-RequiredQualificationReport {
  param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$EvidenceDirectory,
    [Parameter(Mandatory)][string]$StartedUtc
  )
  $ledgerPath = Join-Path $RepoRoot 'release\qualification\v0.1-requirements.json'
  $ledger = Assert-StaticRequirementLedger -Path $ledgerPath
  $absoluteEvidence = if ([IO.Path]::IsPathRooted($EvidenceDirectory)) { [IO.Path]::GetFullPath($EvidenceDirectory) } else { [IO.Path]::GetFullPath((Join-Path $RepoRoot $EvidenceDirectory)) }
  $null = New-Item -ItemType Directory -Force -Path $absoluteEvidence
  $head = (& git -C $RepoRoot rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0 -or $head -cnotmatch '^[0-9a-f]{40}$') { throw 'Unable to identify Required report HEAD.' }
  $artifacts = [Collections.Generic.List[object]]::new()
  foreach ($contract in @($ledger.artifact_contracts)) {
    $schemaPath = Join-Path $RepoRoot ([string]$contract.schema)
    $evidencePath = if ($null -ne $contract.PSObject.Properties['tracked_path']) {
      Join-Path $RepoRoot ([string]$contract.tracked_path)
    } else {
      Join-Path $absoluteEvidence ([string]$contract.dynamic_path)
    }
    if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $evidencePath -PathType Leaf)) {
      throw "Required artifact '$($contract.id)' is missing its schema or evidence."
    }
    $artifacts.Add([ordered]@{
      id = [string]$contract.id
      schema_sha256 = Get-ReleaseSha256 -Path $schemaPath
      evidence_sha256 = Get-ReleaseSha256 -Path $evidencePath
    })
  }
  $releaseReport = Read-ReleaseJson -Path (Join-Path $absoluteEvidence 'release\report.json')
  if ($releaseReport.head -cne $head) { throw 'Nested release report HEAD differs from Required report HEAD.' }
  Assert-ReleaseCandidateOutcomes -ReportPath (Join-Path $absoluteEvidence 'release\report.json')
  $selectors = @($ledger.selectors | ForEach-Object { [ordered]@{ id = [string]$_.id; status = 'pass' } })
  $stable = [ordered]@{
    schema_version = '1.0.0'
    head = $head
    ledger_sha256 = Get-ReleaseSha256 -Path $ledgerPath
    selector_order = @($ledger.selectors.id)
    selectors = $selectors
    artifacts = @($artifacts)
    publication = [ordered]@{
      performed = $false
      credentials_read = $false
      namespace_verified = $false
      blocked_reason = 'unverified_mooncakes_owner_namespace'
    }
    tracked_diff_unchanged = $true
  }
  $digest = Get-ReleaseTextSha256 -Text ($stable | ConvertTo-Json -Depth 100 -Compress)
  $report = [ordered]@{}
  foreach ($entry in $stable.GetEnumerator()) { $report[$entry.Key] = $entry.Value }
  $report.deterministic_evidence_digest = $digest
  $report.run_local = [ordered]@{
    started_utc = $StartedUtc
    completed_utc = [DateTime]::UtcNow.ToString('o')
    evidence_directory = $absoluteEvidence
    os = [Environment]::OSVersion.VersionString
    powershell = $PSVersionTable.PSVersion.ToString()
  }
  $path = Join-Path $absoluteEvidence 'report.json'
  [IO.File]::WriteAllText($path, (($report | ConvertTo-Json -Depth 100) + "`n"), [Text.UTF8Encoding]::new($false))
  return $path
}

function Assert-RequiredQualificationReport {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$LedgerPath)
  $ledger = Assert-StaticRequirementLedger -Path $LedgerPath
  $report = Read-ReleaseJson -Path $Path
  Assert-ReleaseClosedProperties -Label 'Required run report' -Object $report -Expected @(
    'schema_version', 'head', 'ledger_sha256', 'selector_order', 'selectors', 'artifacts', 'publication',
    'tracked_diff_unchanged', 'deterministic_evidence_digest', 'run_local'
  )
  if ($report.schema_version -cne '1.0.0' -or $report.head -cnotmatch '^[0-9a-f]{40}$' -or
      $report.ledger_sha256 -cne (Get-ReleaseSha256 -Path $LedgerPath) -or $report.tracked_diff_unchanged -ne $true) {
    throw "Required run report identity or static-ledger binding failed: $Path"
  }
  Assert-ReleaseExactSequence -Label 'Required selector order' -Actual @($report.selector_order) -Expected @($ledger.selectors.id)
  Assert-ReleaseExactSequence -Label 'Required selector result order' -Actual @($report.selectors.id) -Expected @($ledger.selectors.id)
  if (@($report.selectors | Where-Object { [string]$_.status -cne 'pass' }).Count -ne 0) { throw 'Required run report contains a non-passing selector.' }
  Assert-ReleaseExactSequence -Label 'Required artifact order' -Actual @($report.artifacts.id) -Expected @($ledger.artifact_contracts.id)
  foreach ($artifact in @($report.artifacts)) {
    Assert-ReleaseClosedProperties -Label "Required artifact $($artifact.id)" -Object $artifact -Expected @('id', 'schema_sha256', 'evidence_sha256')
    if ([string]$artifact.schema_sha256 -cnotmatch '^[0-9a-f]{64}$' -or [string]$artifact.evidence_sha256 -cnotmatch '^[0-9a-f]{64}$') {
      throw "Required artifact '$($artifact.id)' has an invalid digest."
    }
  }
  Assert-ReleaseClosedProperties -Label 'Required publication result' -Object $report.publication -Expected @('performed', 'credentials_read', 'namespace_verified', 'blocked_reason')
  if ($report.publication.performed -ne $false -or $report.publication.credentials_read -ne $false -or
      $report.publication.namespace_verified -ne $false -or $report.publication.blocked_reason -cne 'unverified_mooncakes_owner_namespace') {
    throw 'Required run report fabricated publication or credential evidence.'
  }
  Assert-ReleaseClosedProperties -Label 'Required run-local fields' -Object $report.run_local -Expected @('started_utc', 'completed_utc', 'evidence_directory', 'os', 'powershell')
  $stable = Get-RequiredRunStableObject -Report $report
  $expectedDigest = Get-ReleaseTextSha256 -Text ($stable | ConvertTo-Json -Depth 100 -Compress)
  if ($report.deterministic_evidence_digest -cne $expectedDigest) { throw 'Required run canonical deterministic evidence digest is invalid.' }
  return $report
}

function Assert-ReleaseTrackedSnapshot {
  param([Parameter(Mandatory)][string]$Before, [Parameter(Mandatory)][string]$After)
  if ($Before -cne $After) {
    Throw-ReleaseRule -Id 'REL14-TRACKED-SOURCE-MUTATION' -Message 'tracked source differs from the captured baseline.'
  }
}

function Assert-ReleaseHashedArtifact {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$ExpectedSha256)
  if ((Get-ReleaseSha256 -Path $Path) -cne $ExpectedSha256.ToLowerInvariant()) {
    Throw-ReleaseRule -Id 'REL13-ARTIFACT-DIGEST' -Message "artifact bytes no longer match the recorded SHA-256: $Path"
  }
}

function Assert-ReleaseManifestDependencies {
  param(
    [Parameter(Mandatory)][ValidateSet('mb-core', 'mb-color', 'mb-image')][string]$ShortName,
    [Parameter(Mandatory)][string]$ManifestPath,
    [Parameter(Mandatory)][string]$PolicyPath
  )
  $manifest = Read-ReleaseJson -Path $ManifestPath
  $policy = Read-ReleaseJson -Path $PolicyPath
  $expected = $policy.modules.$ShortName.dependencies
  $actual = if ($null -ne $manifest.PSObject.Properties['deps']) { $manifest.deps } else { [pscustomobject]@{} }
  $actualNames = @($actual.PSObject.Properties | ForEach-Object { $_.Name })
  $expectedNames = @($expected.PSObject.Properties | ForEach-Object { $_.Name })
  try { Assert-ReleaseExactSet -Label "$ShortName manifest dependency names" -Actual $actualNames -Expected $expectedNames } catch {
    Throw-ReleaseRule -Id 'REL03-PATH-SUBSTITUTION' -Message $_.Exception.Message
  }
  foreach ($name in $expectedNames) {
    $value = $actual.$name
    if ($value -isnot [string] -or [string]$value -cne [string]$expected.$name) {
      Throw-ReleaseRule -Id 'REL03-PATH-SUBSTITUTION' -Message "$ShortName dependency '$name' is not the exact scalar named version requirement."
    }
  }
  $raw = Get-Content -LiteralPath $ManifestPath -Raw
  if ($raw -cmatch '"path"\s*:|(?:^|[\\/])[.][.](?:[\\/]|$)') {
    Throw-ReleaseRule -Id 'REL03-PATH-SUBSTITUTION' -Message "$ShortName manifest contains a workspace/path substitution."
  }
}

function Assert-ReleaseModuleImports {
  param(
    [Parameter(Mandatory)][ValidateSet('mb-core', 'mb-color', 'mb-image')][string]$ShortName,
    [Parameter(Mandatory)][string]$PackagePath
  )
  $raw = Get-Content -LiteralPath $PackagePath -Raw
  $imports = @([regex]::Matches($raw, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
  $forbidden = @(switch ($ShortName) {
    'mb-core' { @($imports | Where-Object { $_ -cmatch '^moonbit-foundation/(?:mb-color|mb-image)(?:/|$)' }) }
    'mb-color' { @($imports | Where-Object { $_ -cmatch '^moonbit-foundation/mb-image(?:/|$)' }) }
    default { @() }
  })
  if ($forbidden.Count -ne 0) {
    Throw-ReleaseRule -Id 'REL04-HIGHER-LAYER-DEPENDENCY' -Message "$ShortName imports a higher release layer: $($forbidden -join ', ')"
  }
}

function Assert-ReleasePackageList {
  param(
    [Parameter(Mandatory)][ValidateSet('mb-core', 'mb-color', 'mb-image')][string]$ShortName,
    [Parameter(Mandatory)][string]$ListPath,
    [Parameter(Mandatory)][string]$PolicyPath
  )
  $policy = Read-ReleaseJson -Path $PolicyPath
  $actual = @(Get-Content -LiteralPath $ListPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Replace('\', '/') })
  try { Assert-ReleaseExactSet -Label "$ShortName package inventory" -Actual $actual -Expected @($policy.modules.$ShortName.package_allowlist) } catch {
    Throw-ReleaseRule -Id 'REL05-ARCHIVE-ENTRY' -Message $_.Exception.Message
  }
}

function Assert-ReleaseCandidateOutcomes {
  param([Parameter(Mandatory)][string]$ReportPath)
  $report = Read-ReleaseJson -Path $ReportPath
  if ($report.publication.performed -ne $false -or $report.publication.credentials_read -ne $false -or
      $report.publication.namespace_verified -ne $false -or
      $report.modules.'mb-color'.source_isolation -cne 'pass' -or
      $report.modules.'mb-image'.source_isolation -cne 'pass' -or
      $report.modules.'mb-color'.artifact_consumer -cne 'blocked_unpublished_dependency' -or
      $report.modules.'mb-image'.artifact_consumer -cne 'blocked_unpublished_dependency' -or
      $report.modules.'mb-color'.registry_resolution -cne 'blocked_unpublished_namespace' -or
      $report.modules.'mb-image'.registry_resolution -cne 'blocked_unpublished_namespace') {
    Throw-ReleaseRule -Id 'REL02-FABRICATED-REGISTRY-PASS' -Message 'candidate report fabricated publication or downstream registry/artifact success.'
  }
}

function Assert-PpmQualificationContract {
  param([Parameter(Mandatory)][string]$FoundationPath)
  $foundation = Read-ReleaseJson -Path $FoundationPath
  $image = @($foundation.modules | Where-Object { [string]$_.path -ceq 'modules/mb-image' })
  if ($image.Count -ne 1) { Throw-ReleaseRule -Id 'PPM06-WRONG-PUBLICATION-ORDER' -Message 'mb-image policy owner is missing or duplicated.' }
  $expectedPackageOrder = @(
    'moonbit-foundation/mb-image/metadata', 'moonbit-foundation/mb-image/model',
    'moonbit-foundation/mb-image/storage', 'moonbit-foundation/mb-image/ops',
    'moonbit-foundation/mb-image/codec', 'moonbit-foundation/mb-image/ppm'
  )
  try { Assert-ReleaseExactSequence -Label 'PPM publication order' -Actual @($image[0].public_packages.name) -Expected $expectedPackageOrder } catch {
    Throw-ReleaseRule -Id 'PPM06-WRONG-PUBLICATION-ORDER' -Message $_.Exception.Message
  }
  $ppm = @($image[0].public_packages | Where-Object { [string]$_.path -ceq 'ppm' })
  if ($ppm.Count -ne 1) { Throw-ReleaseRule -Id 'PPM07-UNREGISTERED-CONTENT' -Message 'PPM package owner is missing or duplicated.' }
  $expectedImports = @(
    'moonbit-foundation/mb-core/budget', 'moonbit-foundation/mb-core/bytes',
    'moonbit-foundation/mb-core/checked', 'moonbit-foundation/mb-core/error',
    'moonbit-foundation/mb-core/io', 'moonbit-foundation/mb-color/model',
    'moonbit-foundation/mb-color/profile', 'moonbit-foundation/mb-image/codec',
    'moonbit-foundation/mb-image/metadata', 'moonbit-foundation/mb-image/model',
    'moonbit-foundation/mb-image/storage'
  )
  $actualImports = @($ppm[0].allowed_imports)
  if ($actualImports.Count -lt $expectedImports.Count) { Throw-ReleaseRule -Id 'PPM01-MISSING-IMPORT' -Message 'PPM import allowlist is incomplete.' }
  if ($actualImports.Count -gt $expectedImports.Count) { Throw-ReleaseRule -Id 'PPM02-EXTRA-IMPORT' -Message 'PPM import allowlist contains an extra edge.' }
  try { Assert-ReleaseExactSequence -Label 'PPM imports' -Actual $actualImports -Expected $expectedImports } catch {
    Throw-ReleaseRule -Id 'PPM02-EXTRA-IMPORT' -Message $_.Exception.Message
  }
  try { Assert-ReleaseExactSequence -Label 'PPM targets' -Actual @($ppm[0].supported_targets) -Expected @('js', 'wasm', 'wasm-gc', 'native') } catch {
    Throw-ReleaseRule -Id 'PPM03-WRONG-TARGET' -Message $_.Exception.Message
  }
  $canonical = Read-ReleaseJson -Path (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'policy\foundation.json')
  $canonicalPpm = @((@($canonical.modules | Where-Object { [string]$_.path -ceq 'modules/mb-image' })[0]).public_packages | Where-Object { [string]$_.path -ceq 'ppm' })[0]
  $actualInterface = @($ppm[0].semantic_interface)
  $expectedInterface = @($canonicalPpm.semantic_interface)
  if ($actualInterface.Count -lt $expectedInterface.Count) { Throw-ReleaseRule -Id 'PPM04-MISSING-INTERFACE' -Message 'PPM semantic interface is incomplete.' }
  if ($actualInterface.Count -gt $expectedInterface.Count) { Throw-ReleaseRule -Id 'PPM05-EXTRA-INTERFACE' -Message 'PPM semantic interface contains an unregistered declaration.' }
  try { Assert-ReleaseExactSequence -Label 'PPM semantic interface' -Actual $actualInterface -Expected $expectedInterface } catch {
    Throw-ReleaseRule -Id 'PPM05-EXTRA-INTERFACE' -Message $_.Exception.Message
  }
  try { Assert-ReleaseExactSequence -Label 'PPM production sources' -Actual @($ppm[0].production_sources) -Expected @('moon.pkg', 'ppm.mbt', 'parser.mbt', 'decode.mbt', 'encode.mbt', 'generated_vectors.mbt') } catch {
    Throw-ReleaseRule -Id 'PPM07-UNREGISTERED-CONTENT' -Message $_.Exception.Message
  }
}

function Remove-ReleaseTemp {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
  $full = [IO.Path]::GetFullPath($Path)
  $leaf = Split-Path -Leaf $full
  if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
      -not $leaf.StartsWith('mnf-release-qualification-', [StringComparison]::Ordinal)) {
    throw "Refusing to remove unverified release qualification path: $full"
  }
  Remove-Item -LiteralPath $full -Recurse -Force
}

function Assert-ReleaseSchema {
  param([Parameter(Mandatory)][string]$SchemaPath)
  $schema = Read-ReleaseJson -Path $SchemaPath
  if ($schema.type -cne 'object' -or $schema.additionalProperties -ne $false -or $schema.properties.schema_version.const -cne '1.0.0') {
    throw 'Release report schema is not a closed 1.0.0 object.'
  }
  Assert-ReleaseExactSequence -Label 'schema module order' -Actual @($schema.properties.module_order.const) -Expected @('mb-core', 'mb-color', 'mb-image')
  if ($schema.properties.publication.properties.performed.const -ne $false -or
      $schema.properties.publication.properties.credentials_read.const -ne $false -or
      $schema.'$defs'.coreModule.properties.artifact_consumer.const -cne 'pass' -or
      $schema.'$defs'.downstreamModule.properties.source_isolation.const -cne 'pass' -or
      $schema.'$defs'.downstreamModule.properties.registry_resolution.const -cne 'blocked_unpublished_namespace') {
    throw 'Release report schema does not freeze the honest publication and consumer outcomes.'
  }
}

function Assert-ReleasePolicy {
  param(
    [Parameter(Mandatory)][string]$PolicyPath,
    [Parameter(Mandatory)][string]$FoundationPath,
    [Parameter(Mandatory)][string]$FixtureManifestPath,
    [Parameter(Mandatory)][string]$SchemaPath,
    [Parameter(Mandatory)][string]$RepoRoot
  )

  $policy = Read-ReleaseJson -Path $PolicyPath
  $foundation = Read-ReleaseJson -Path $FoundationPath
  $fixtures = Read-ReleaseJson -Path $FixtureManifestPath
  Assert-ReleaseSchema -SchemaPath $SchemaPath

  Assert-ReleaseClosedProperties -Label 'release policy' -Object $policy -Expected @(
    'schema_version', 'module_order', 'required_targets', 'candidate_status', 'license', 'repository',
    'fixture_manifest', 'fixture_records', 'forbidden_archive_patterns', 'post_publish_order', 'publication', 'modules'
  )
  if ($policy.candidate_status -cne 'candidate') {
    Throw-ReleaseRule -Id 'REL09-WRONG-STATUS' -Message 'release policy candidate status drifted.'
  }
  if ($policy.license -cne 'Apache-2.0') {
    Throw-ReleaseRule -Id 'REL10-MISSING-LICENSE' -Message 'release policy license is missing or drifted.'
  }
  if ($policy.schema_version -cne '1.0.0' -or $policy.repository -cne 'https://github.com/moonbit-foundation/moonbit-foundation' -or
      $policy.fixture_manifest -cne 'fixtures/manifest.json') {
    throw 'Release policy identity, repository, or fixture manifest drifted.'
  }
  try { Assert-ReleaseExactSequence -Label 'release module order' -Actual @($policy.module_order) -Expected @('mb-core', 'mb-color', 'mb-image') } catch {
    Throw-ReleaseRule -Id 'REL01-MODULE-ORDER' -Message $_.Exception.Message
  }
  Assert-ReleaseExactSequence -Label 'release targets' -Actual @($policy.required_targets) -Expected @('js', 'wasm', 'wasm-gc', 'native')
  Assert-ReleaseExactSequence -Label 'post-publication order' -Actual @($policy.post_publish_order) -Expected @(
    'publish:moonbit-foundation/mb-core@0.1.0', 'resolve:moonbit-foundation/mb-core@0.1.0',
    'publish:moonbit-foundation/mb-color@0.1.0', 'resolve:moonbit-foundation/mb-color@0.1.0',
    'publish:moonbit-foundation/mb-image@0.1.0', 'resolve:moonbit-foundation/mb-image@0.1.0'
  )
  Assert-ReleaseClosedProperties -Label 'publication policy' -Object $policy.publication -Expected @('performed', 'credentials_read', 'namespace_verified', 'blocked_reason')
  if ($policy.publication.performed -ne $false -or $policy.publication.credentials_read -ne $false -or
      $policy.publication.namespace_verified -ne $false -or $policy.publication.blocked_reason -cne 'unverified_mooncakes_owner_namespace') {
    throw 'Publication policy must remain non-executing, credential-free, namespace-unverified, and explicitly blocked.'
  }

  $fixtureIds = @($fixtures.records | ForEach-Object { [string]$_.id })
  try { Assert-ReleaseExactSequence -Label 'fixture provenance records' -Actual @($policy.fixture_records) -Expected $fixtureIds } catch {
    Throw-ReleaseRule -Id 'REL11-MISSING-PROVENANCE' -Message $_.Exception.Message
  }
  foreach ($record in @($fixtures.records)) {
    $fixturePath = Join-Path $RepoRoot ([string]$record.path)
    if (-not (Test-Path -LiteralPath $fixturePath -PathType Leaf) -or (Get-ReleaseSha256 -Path $fixturePath) -cne ([string]$record.sha256).ToLowerInvariant()) {
      Throw-ReleaseRule -Id 'REL12-PROVENANCE-CHECKSUM' -Message "fixture provenance bytes drifted for '$($record.id)'."
    }
  }

  Assert-ReleaseClosedProperties -Label 'release modules' -Object $policy.modules -Expected @('mb-core', 'mb-color', 'mb-image')
  $expectedDependencies = @{
    'mb-core' = [ordered]@{}
    'mb-color' = [ordered]@{ 'moonbit-foundation/mb-core' = '0.1.0' }
    'mb-image' = [ordered]@{ 'moonbit-foundation/mb-core' = '0.1.0'; 'moonbit-foundation/mb-color' = '0.1.0' }
  }
  $expectedOutcomes = @{
    'mb-core' = @('not_required_leaf_artifact_consumer', 'pass', 'not_required_no_dependencies')
    'mb-color' = @('pass', 'blocked_unpublished_dependency', 'blocked_unpublished_namespace')
    'mb-image' = @('pass', 'blocked_unpublished_dependency', 'blocked_unpublished_namespace')
  }

  foreach ($shortName in @('mb-core', 'mb-color', 'mb-image')) {
    $module = $policy.modules.$shortName
    if ($null -eq $module.manifest.PSObject.Properties['version'] -or [string]::IsNullOrWhiteSpace([string]$module.manifest.version)) {
      Throw-ReleaseRule -Id 'REL08-MISSING-VERSION' -Message "$shortName manifest version is missing."
    }
    Assert-ReleaseClosedProperties -Label "$shortName release policy" -Object $module -Expected @(
      'manifest', 'dependencies', 'public_packages', 'package_allowlist', 'source_isolation', 'artifact_consumer', 'registry_resolution'
    )
    Assert-ReleaseClosedProperties -Label "$shortName manifest policy" -Object $module.manifest -Expected @(
      'name', 'version', 'description', 'license', 'repository', 'readme', 'preferred-target', 'supported-targets'
    )
    $foundationModule = @($foundation.modules | Where-Object { [string]$_.path -ceq "modules/$shortName" })
    if ($foundationModule.Count -ne 1) { throw "Foundation policy must contain exactly one $shortName module." }
    $foundationModule = $foundationModule[0]
    $manifestPath = Join-Path $RepoRoot "modules\$shortName\moon.mod.json"
    $manifest = Read-ReleaseJson -Path $manifestPath
    Assert-ReleaseManifestDependencies -ShortName $shortName -ManifestPath $manifestPath -PolicyPath $PolicyPath
    foreach ($packageManifest in @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot "modules\$shortName") -Recurse -File -Filter 'moon.pkg')) {
      Assert-ReleaseModuleImports -ShortName $shortName -PackagePath $packageManifest.FullName
    }
    foreach ($field in @('name', 'version', 'description', 'license', 'repository', 'readme', 'preferred-target', 'supported-targets')) {
      if ([string]$module.manifest.$field -cne [string]$manifest.$field) { throw "$shortName manifest field '$field' drifted from release policy." }
    }
    if ($module.manifest.name -cne [string]$foundationModule.name -or $module.manifest.version -cne [string]$foundationModule.version -or
        $module.manifest.description -cne [string]$foundationModule.description -or $module.manifest.repository -cne [string]$foundationModule.repository) {
      throw "$shortName release metadata drifted from foundation policy."
    }
    Assert-ReleaseExactSequence -Label "$shortName package allowlist" -Actual @($module.package_allowlist) -Expected @($foundationModule.publication_files)
    Assert-ReleaseExactSequence -Label "$shortName public packages" -Actual @($module.public_packages) -Expected @($foundationModule.public_packages | ForEach-Object { [string]$_.name })

    $wantedDeps = $expectedDependencies[$shortName]
    Assert-ReleaseExactSet -Label "$shortName dependency names" -Actual @($module.dependencies.PSObject.Properties | ForEach-Object { $_.Name }) -Expected @($wantedDeps.Keys)
    foreach ($dep in @($wantedDeps.Keys)) {
      if ($module.dependencies.$dep -isnot [string] -or [string]$module.dependencies.$dep -cne [string]$wantedDeps[$dep]) {
        throw "$shortName dependency '$dep' must be the exact scalar 0.1.0 named requirement."
      }
    }
    if (@($manifest.PSObject.Properties | ForEach-Object { $_.Name }) -contains 'deps') {
      Assert-ReleaseExactSet -Label "$shortName manifest dependency names" -Actual @($manifest.deps.PSObject.Properties | ForEach-Object { $_.Name }) -Expected @($wantedDeps.Keys)
      foreach ($dep in @($wantedDeps.Keys)) { if ([string]$manifest.deps.$dep -cne '0.1.0') { throw "$shortName manifest dependency '$dep' drifted." } }
    } elseif ($wantedDeps.Count -ne 0) { throw "$shortName manifest dependencies are missing." }

    $actualOutcomes = @([string]$module.source_isolation, [string]$module.artifact_consumer, [string]$module.registry_resolution)
    Assert-ReleaseExactSequence -Label "$shortName outcomes" -Actual $actualOutcomes -Expected $expectedOutcomes[$shortName]
    foreach ($entry in @($module.package_allowlist)) {
      $text = ([string]$entry).Replace('\', '/')
      if ([IO.Path]::IsPathRooted($text) -or $text -match '(^|/)\.\.(/|$)') { throw "$shortName package allowlist contains an absolute or traversal entry: $text" }
      foreach ($pattern in @($policy.forbidden_archive_patterns)) { if ($text -match [string]$pattern) { throw "$shortName package allowlist contains forbidden entry '$text'." } }
    }
  }

  return $policy
}
