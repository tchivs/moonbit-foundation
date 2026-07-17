Set-StrictMode -Version Latest

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
  if ($policy.schema_version -cne '1.0.0' -or $policy.candidate_status -cne 'candidate' -or
      $policy.license -cne 'Apache-2.0' -or $policy.repository -cne 'https://github.com/moonbit-foundation/moonbit-foundation' -or
      $policy.fixture_manifest -cne 'fixtures/manifest.json') {
    throw 'Release policy identity, candidate status, license, repository, or fixture manifest drifted.'
  }
  Assert-ReleaseExactSequence -Label 'release module order' -Actual @($policy.module_order) -Expected @('mb-core', 'mb-color', 'mb-image')
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
  Assert-ReleaseExactSequence -Label 'fixture provenance records' -Actual @($policy.fixture_records) -Expected $fixtureIds
  foreach ($record in @($fixtures.records)) {
    $fixturePath = Join-Path $RepoRoot ([string]$record.path)
    if (-not (Test-Path -LiteralPath $fixturePath -PathType Leaf) -or (Get-ReleaseSha256 -Path $fixturePath) -cne ([string]$record.sha256).ToLowerInvariant()) {
      throw "Fixture provenance bytes drifted for '$($record.id)'."
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
