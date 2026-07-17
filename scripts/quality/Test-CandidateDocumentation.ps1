[CmdletBinding()]
param(
  [ValidateSet('all', 'mb-core', 'mb-color', 'mb-image')]
  [string]$Module = 'all',
  [switch]$ContractSelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$requiredTargets = @('js', 'wasm', 'wasm-gc', 'native')
$compactTargets = '+js+wasm+wasm-gc+native'
$candidateDocument = 'docs/release/v0.1-candidate.md'
$moduleRows = @(
  [pscustomobject][ordered]@{ short = 'mb-core'; name = 'tchivs/mb-core'; path = 'modules/mb-core'; fixtures = @() },
  [pscustomobject][ordered]@{ short = 'mb-color'; name = 'tchivs/mb-color'; path = 'modules/mb-color'; fixtures = @('color-srgb-reference-vectors', 'color-derived-edge-vectors') },
  [pscustomobject][ordered]@{ short = 'mb-image'; name = 'tchivs/mb-image'; path = 'modules/mb-image'; fixtures = @('image-operation-vectors', 'ppm-p6-conformance-vectors') }
)
[array]$selectedRows = if ($Module -ceq 'all') { $moduleRows } else { $moduleRows | Where-Object short -ceq $Module }

function Fail-Rule {
  param([Parameter(Mandatory)][string]$Rule, [Parameter(Mandatory)][string]$Message)
  throw "[$Rule] $Message"
}

function Read-RequiredText {
  param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Relative, [Parameter(Mandatory)][string]$Rule)
  $path = Join-Path $Root $Relative
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Fail-Rule $Rule "Required file is missing: $Relative"
  }
  return Get-Content -LiteralPath $path -Raw
}

function Read-RequiredJson {
  param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Relative, [Parameter(Mandatory)][string]$Rule)
  $text = Read-RequiredText -Root $Root -Relative $Relative -Rule $Rule
  try { return $text | ConvertFrom-Json -Depth 100 } catch {
    Fail-Rule $Rule "Invalid JSON in ${Relative}: $($_.Exception.Message)"
  }
}

function Assert-Contains {
  param([string]$Text, [string]$Needle, [string]$Rule, [string]$Label)
  if (-not $Text.Contains($Needle, [System.StringComparison]::Ordinal)) {
    Fail-Rule $Rule "$Label lacks exact token '$Needle'."
  }
}

function Assert-ExactSet {
  param([string[]]$Actual, [string[]]$Expected, [string]$Rule, [string]$Label)
  $actualSorted = @($Actual | Sort-Object -Unique)
  $expectedSorted = @($Expected | Sort-Object -Unique)
  if (($actualSorted -join "`n") -cne ($expectedSorted -join "`n")) {
    Fail-Rule $Rule "$Label mismatch: expected [$($expectedSorted -join ', ')], got [$($actualSorted -join ', ')]."
  }
}

function Assert-CandidateTree {
  param([Parameter(Mandatory)][string]$Root)

  $policy = Read-RequiredJson -Root $Root -Relative 'policy/foundation.json' -Rule 'QUAL04-MANIFEST-METADATA'
  $fixtureManifest = Read-RequiredJson -Root $Root -Relative 'fixtures/manifest.json' -Rule 'QUAL04-FIXTURE-PROVENANCE'
  $candidate = Read-RequiredText -Root $Root -Relative $candidateDocument -Rule 'QUAL04-DOC-REQUIRED'
  Assert-Contains $candidate '## Exact module metadata' 'QUAL04-DOC-REQUIRED' 'candidate index'
  Assert-Contains $candidate '## Public package DAG' 'QUAL04-PACKAGE-DAG' 'candidate index'
  Assert-Contains $candidate '## Fixture provenance' 'QUAL04-FIXTURE-PROVENANCE' 'candidate index'
  Assert-Contains $candidate '## Deferred and prohibited claims' 'QUAL04-DOC-REQUIRED' 'candidate index'
  Assert-Contains $candidate 'MNF strict PPM P6/sRGB subset' 'QUAL04-CLAIM-BOUNDARY' 'candidate index'
  Assert-Contains $candidate 'source_isolation: pass' 'QUAL04-EXAMPLE-RUNNABLE' 'candidate index'
  Assert-Contains $candidate 'registry_resolution: blocked_unpublished_namespace' 'QUAL04-CLAIM-BOUNDARY' 'candidate index'

  $positiveClaimPatterns = [ordered]@{
    'stable' = '(?im)^\s*MNF CLAIM:\s*stable\s*$'
    'full-codec' = '(?im)^\s*MNF CLAIM:\s*full-ppm-conformance\s*$'
    'published' = '(?im)^\s*MNF CLAIM:\s*published\s*$'
    'llvm' = '(?im)^\s*MNF CLAIM:\s*llvm-required\s*$'
    'marketing' = '(?im)^\s*MNF CLAIM:\s*performance-superiority\s*$'
  }
  foreach ($entry in $positiveClaimPatterns.GetEnumerator()) {
    if ($candidate -cmatch $entry.Value) {
      Fail-Rule 'QUAL04-CLAIM-BOUNDARY' "Candidate index contains prohibited positive claim '$($entry.Key)'."
    }
  }

  Assert-Contains $candidate '[portable in-memory PPM consumer](../../examples/ppm-portable/main/main.mbt)' 'QUAL04-EXAMPLE-RUNNABLE' 'candidate index'
  Assert-Contains $candidate '[Native CLI-shaped injected adapter](../../examples/ppm-native-cli/main/adapter.mbt)' 'QUAL04-EXAMPLE-RUNNABLE' 'candidate index'
  foreach ($relative in @('examples/ppm-portable/main/main.mbt', 'examples/ppm-native-cli/main/adapter.mbt')) {
    if (-not (Test-Path -LiteralPath (Join-Path $Root $relative) -PathType Leaf)) {
      Fail-Rule 'QUAL04-EXAMPLE-RUNNABLE' "Linked public example is missing: $relative"
    }
  }

  foreach ($row in $selectedRows) {
    $modulePolicy = @($policy.modules | Where-Object { [string]$_.name -ceq $row.name })
    if ($modulePolicy.Count -ne 1) {
      Fail-Rule 'QUAL04-MANIFEST-METADATA' "Policy must contain exactly one module '$($row.name)'."
    }
    $modulePolicy = $modulePolicy[0]
    $manifestRelative = "$($row.path)/moon.mod.json"
    $readmeRelative = "$($row.path)/README.mbt.md"
    $changelogRelative = "$($row.path)/CHANGELOG.md"
    $manifestText = Read-RequiredText -Root $Root -Relative $manifestRelative -Rule 'QUAL04-MANIFEST-METADATA'
    $manifest = Read-RequiredJson -Root $Root -Relative $manifestRelative -Rule 'QUAL04-MANIFEST-METADATA'
    $readme = Read-RequiredText -Root $Root -Relative $readmeRelative -Rule 'QUAL04-DOC-REQUIRED'
    $changelog = Read-RequiredText -Root $Root -Relative $changelogRelative -Rule 'QUAL04-DOC-REQUIRED'

    foreach ($field in @('description', 'repository')) {
      if ([string]::IsNullOrWhiteSpace([string]$modulePolicy.$field)) {
        Fail-Rule 'QUAL04-MANIFEST-METADATA' "Policy module '$($row.name)' lacks $field."
      }
    }
    foreach ($fact in @(
      @('name', [string]$modulePolicy.name),
      @('version', [string]$modulePolicy.version),
      @('description', [string]$modulePolicy.description),
      @('license', [string]$policy.license),
      @('repository', [string]$modulePolicy.repository),
      @('readme', 'README.mbt.md'),
      @('preferred-target', [string]$modulePolicy.preferred_target),
      @('supported-targets', $compactTargets)
    )) {
      $field = [string]$fact[0]
      $expected = [string]$fact[1]
      if ([string]$manifest.$field -cne $expected) {
        Fail-Rule 'QUAL04-MANIFEST-METADATA' "$manifestRelative field '$field' must equal '$expected'."
      }
    }
    if ($manifestText -cmatch '"path"\s*:|(?:^|[\\/])[.][.](?:[\\/]|$)') {
      Fail-Rule 'QUAL04-MANIFEST-METADATA' "$manifestRelative contains a path substitution."
    }
    $depProperty = $manifest.PSObject.Properties['deps']
    $actualDeps = if ($null -eq $depProperty) { @() } else { @($depProperty.Value.PSObject.Properties.Name) }
    Assert-ExactSet $actualDeps @($modulePolicy.direct_dependencies) 'QUAL04-MANIFEST-METADATA' "$manifestRelative dependency names"
    foreach ($dependency in $actualDeps) {
      if ([string]$manifest.deps.$dependency -cne '0.1.0') {
        Fail-Rule 'QUAL04-MANIFEST-METADATA' "$manifestRelative dependency '$dependency' must equal 0.1.0."
      }
    }

    foreach ($token in @($row.name, '0.1.0', 'candidate', 'Apache-2.0', [string]$modulePolicy.repository, $compactTargets, 'CHANGELOG.md')) {
      Assert-Contains $readme $token 'QUAL04-DOC-REQUIRED' $readmeRelative
    }
    foreach ($target in $requiredTargets) {
      Assert-Contains $readme "``$target``" 'QUAL04-SUPPORT-MATRIX' $readmeRelative
    }
    if ($readme -cnotmatch '(?i)\bdefer(?:red|s)\b') {
      Fail-Rule 'QUAL04-DOC-REQUIRED' "$readmeRelative lacks explicit deferred scope."
    }
    foreach ($token in @('0.1.0 candidate (unpublished)', 'Compatibility status: candidate', 'Deferred:')) {
      Assert-Contains $changelog $token 'QUAL04-DOC-REQUIRED' $changelogRelative
    }
    $dagParts = @()
    foreach ($package in @($modulePolicy.public_packages)) {
      $dagParts += ('{0}->[{1}]' -f [string]$package.name, (@($package.allowed_imports) -join ','))
    }
    $dagFingerprint = "<!-- exact-public-dag: $($modulePolicy.name): $($dagParts -join '|') -->"
    Assert-Contains $candidate $dagFingerprint 'QUAL04-PACKAGE-DAG' 'candidate index'
    foreach ($fixtureId in @($row.fixtures)) {
      $record = @($fixtureManifest.records | Where-Object { [string]$_.id -ceq $fixtureId })
      if ($record.Count -ne 1) {
        Fail-Rule 'QUAL04-FIXTURE-PROVENANCE' "Fixture '$fixtureId' is missing or duplicated."
      }
      Assert-Contains $candidate $fixtureId 'QUAL04-FIXTURE-PROVENANCE' 'candidate index'
      Assert-Contains $candidate ([string]$record[0].sha256) 'QUAL04-FIXTURE-PROVENANCE' 'candidate index'
      Assert-Contains $readme $fixtureId 'QUAL04-FIXTURE-PROVENANCE' $readmeRelative
      Assert-Contains $readme ([string]$record[0].sha256) 'QUAL04-FIXTURE-PROVENANCE' $readmeRelative
    }
  }

  foreach ($record in @($fixtureManifest.records)) {
    foreach ($field in @('id', 'path', 'origin', 'source', 'author', 'retrieval_date', 'sha256', 'license', 'redistribution_status', 'expected_use')) {
      if ([string]::IsNullOrWhiteSpace([string]$record.$field)) {
        Fail-Rule 'QUAL04-FIXTURE-PROVENANCE' "Fixture '$($record.id)' has empty provenance field '$field'."
      }
    }
  }
}

function Assert-ClosedProperties {
  param([object]$Value, [string[]]$Allowed, [string]$Rule, [string]$Label)
  $actual = @($Value.PSObject.Properties | ForEach-Object { $_.Name })
  Assert-ExactSet -Actual $actual -Expected $Allowed -Rule $Rule -Label "$Label fields"
}

function Get-PublicationSourceRecords {
  param([string]$Text, [string]$Label)
  $matches = [regex]::Matches($Text, '(?m)^(?<ordinal>[0-9]{2})\|(?<name>[a-z][a-z0-9-]*)\|(?<value>.*)$')
  $expectedNames = @(
    'install', 'imports', 'status', 'targets', 'toolchain', 'class',
    'support', 'security', 'changelog', 'migration', 'rfc', 'impacts',
    'registry-source', 'registry-render', 'ambiguity'
  )
  $matchedNames = @($matches | ForEach-Object { $_.Groups['name'].Value })
  if (@($matchedNames | Sort-Object -Unique).Count -ne $matchedNames.Count) {
    Fail-Rule 'PROV03-DUPLICATE-RECORD' "$Label contains a duplicate publication-source record."
  }
  if ($matches.Count -ne $expectedNames.Count) {
    Fail-Rule 'PROV03-RECORD-ORDER' "$Label must contain exactly $($expectedNames.Count) publication-source records."
  }
  $records = [ordered]@{}
  for ($index = 0; $index -lt $matches.Count; $index++) {
    $expectedOrdinal = '{0:D2}' -f ($index + 1)
    $ordinal = $matches[$index].Groups['ordinal'].Value
    $name = $matches[$index].Groups['name'].Value
    $value = $matches[$index].Groups['value'].Value
    if ($ordinal -cne $expectedOrdinal -or $name -cne $expectedNames[$index]) {
      Fail-Rule 'PROV03-RECORD-ORDER' "$Label record $($index + 1) must be '$expectedOrdinal|$($expectedNames[$index])|...'."
    }
    if ($records.Contains($name)) {
      Fail-Rule 'PROV03-DUPLICATE-RECORD' "$Label duplicates publication-source record '$name'."
    }
    if ([string]::IsNullOrWhiteSpace($value)) {
      Fail-Rule 'PROV03-EMPTY-AMBIGUITY' "$Label record '$name' is empty or ambiguous."
    }
    $records[$name] = $value
  }
  return $records
}

function Assert-PublicationSourceContract {
  param([Parameter(Mandatory)][string]$Root)

  $compatibility = Read-RequiredJson -Root $Root -Relative 'policy/compatibility.json' -Rule 'PROV03-POLICY'
  $release = Read-RequiredJson -Root $Root -Relative 'policy/release-qualification.json' -Rule 'PROV03-POLICY'
  $support = Read-RequiredText -Root $Root -Relative 'docs/support.md' -Rule 'PROV03-SUPPORT-ROUTE'
  $security = Read-RequiredText -Root $Root -Relative 'SECURITY.md' -Rule 'PROV03-SECURITY-ROUTE'
  if ([string]::IsNullOrWhiteSpace($support) -or [string]::IsNullOrWhiteSpace($security)) {
    Fail-Rule 'PROV03-SUPPORT-ROUTE' 'Shared support and security routes must be non-empty.'
  }
  $profile = $compatibility.baseline_profiles.'0.1.0'
  if ($null -eq $profile) { Fail-Rule 'PROV03-POLICY' 'Compatibility policy lacks baseline profile 0.1.0.' }

  foreach ($row in $selectedRows) {
    $modulePolicyProperty = $release.modules.PSObject.Properties[$row.short]
    if ($null -eq $modulePolicyProperty) { Fail-Rule 'PROV03-POLICY' "Release policy lacks $($row.short)." }
    $modulePolicy = $modulePolicyProperty.Value
    $manifestRelative = "$($row.path)/moon.mod.json"
    $readmeRelative = "$($row.path)/README.mbt.md"
    $changelogRelative = "$($row.path)/CHANGELOG.md"
    $manifest = Read-RequiredJson -Root $Root -Relative $manifestRelative -Rule 'PROV03-MANIFEST-CLOSED'
    $readme = Read-RequiredText -Root $Root -Relative $readmeRelative -Rule 'PROV03-DOCUMENT-REQUIRED'
    $changelog = Read-RequiredText -Root $Root -Relative $changelogRelative -Rule 'PROV03-DOCUMENT-REQUIRED'
    $records = Get-PublicationSourceRecords -Text $readme -Label $readmeRelative

    $allowedManifestFields = @('name', 'version', 'description', 'license', 'repository', 'readme', 'preferred-target', 'supported-targets')
    if (@($modulePolicy.dependencies.PSObject.Properties).Count -gt 0) { $allowedManifestFields += 'deps' }
    Assert-ClosedProperties -Value $manifest -Allowed $allowedManifestFields -Rule 'PROV03-MANIFEST-CLOSED' -Label $manifestRelative
    foreach ($field in @('name', 'version', 'description', 'license', 'repository', 'readme', 'preferred-target', 'supported-targets')) {
      if ([string]$manifest.$field -cne [string]$modulePolicy.manifest.$field) {
        Fail-Rule 'PROV03-MANIFEST-METADATA' "$manifestRelative field '$field' disagrees with release policy."
      }
    }

    $expectedDependencies = $profile.dependency_floors.PSObject.Properties[$row.short].Value
    $expectedDependencyNames = @($expectedDependencies.PSObject.Properties | ForEach-Object { $_.Name })
    $actualDependencyNames = if ($null -eq $manifest.PSObject.Properties['deps']) { @() } else { @($manifest.deps.PSObject.Properties | ForEach-Object { $_.Name }) }
    if (($actualDependencyNames -join "`n") -cne ($expectedDependencyNames -join "`n")) {
      Fail-Rule 'PROV03-DEPENDENCY-FLOOR' "$manifestRelative dependency order or names disagree with compatibility policy."
    }
    foreach ($dependency in $expectedDependencyNames) {
      if ([string]$manifest.deps.$dependency -cne [string]$expectedDependencies.$dependency) {
        Fail-Rule 'PROV03-DEPENDENCY-FLOOR' "$manifestRelative dependency '$dependency' disagrees with compatibility policy."
      }
    }

    $expectedImports = @($modulePolicy.public_packages | ForEach-Object { [string]$_ })
    $documentImports = @([regex]::Matches($readme, '(?m)^\s*- path: (?<path>tchivs/' + [regex]::Escape($row.short) + '/[^\s]+)\s*$') | ForEach-Object { $_.Groups['path'].Value })
    if (($documentImports -join "`n") -cne ($expectedImports -join "`n")) {
      Fail-Rule 'PROV03-IMPORT-ORDER' "$readmeRelative own-package imports must appear exactly once in policy order."
    }

    $expectedValues = [ordered]@{
      install = "moon add $($modulePolicy.manifest.name)@$($modulePolicy.manifest.version)"
      imports = ($expectedImports -join ',')
      status = [string]$release.candidate_status
      targets = (@($profile.supported_targets) -join ',')
      toolchain = "moon=$($profile.minimum_toolchain.moon);moonc=$($profile.minimum_toolchain.moonc);moonrun=$($profile.minimum_toolchain.moonrun)"
      support = 'docs/support.md'
      security = 'SECURITY.md'
      changelog = 'CHANGELOG.md'
      'registry-source' = 'moon.mod.json'
      'registry-render' = 'unknown;proof=PROV-05;phase=8'
      ambiguity = 'none'
    }
    foreach ($entry in $expectedValues.GetEnumerator()) {
      if ([string]$records[$entry.Key] -cne [string]$entry.Value) {
        Fail-Rule ('PROV03-' + $entry.Key.ToUpperInvariant().Replace('-', '-')) "$readmeRelative record '$($entry.Key)' must equal '$($entry.Value)'."
      }
    }

    $class = [string]$records['class']
    $classPolicyProperty = $compatibility.version_rules.PSObject.Properties[$class]
    if ($null -eq $classPolicyProperty -or $class -ceq 'unknown') {
      Fail-Rule 'PROV03-CLASS' "$readmeRelative has non-releasable or unsupported change class '$class'."
    }
    $classPolicy = $classPolicyProperty.Value
    Assert-Contains $changelog "Change class: $class" 'PROV03-CLASS' $changelogRelative
    if ($classPolicy.changelog_required -ne $true) {
      Fail-Rule 'PROV03-POLICY' "Releasable class '$class' must be changelog-owned by policy."
    }
    if ($classPolicy.migration_required -eq $true) {
      if ([string]$records['migration'] -ceq 'not-required') {
        Fail-Rule 'COMP04-MIGRATION-REQUIRED' "$readmeRelative lacks policy-required migration evidence."
      }
      Assert-Contains $changelog "Migration: $($records['migration'])" 'COMP04-MIGRATION-REQUIRED' $changelogRelative
    } elseif ([string]$records['migration'] -cne 'not-required') {
      Fail-Rule 'PROV03-MIGRATION' "$readmeRelative must record migration as not-required for class '$class'."
    }

    $impacts = @(([string]$records['impacts']).Split(',', [System.StringSplitOptions]::RemoveEmptyEntries))
    if ($impacts.Count -eq 0) { Fail-Rule 'PROV03-EMPTY-AMBIGUITY' "$readmeRelative has empty impact evidence." }
    $triggered = @($impacts | Where-Object { @($compatibility.rfc_condition.trigger_impacts) -ccontains $_ }).Count -gt 0
    if ($triggered -and [string]$records['rfc'] -ceq 'not-required') {
      Fail-Rule 'COMP04-RFC-REQUIRED' "$readmeRelative declares an RFC-triggering impact without accepted RFC evidence."
    }
    if (-not $triggered -and [string]$records['rfc'] -cne 'not-required') {
      Fail-Rule 'PROV03-RFC' "$readmeRelative must record RFC as not-required when no trigger impact is declared."
    }
    Assert-Contains $changelog "Migration: $($records['migration'])" 'PROV03-MIGRATION' $changelogRelative
    Assert-Contains $changelog "RFC: $($records['rfc']); impacts: $($records['impacts'])" 'PROV03-RFC' $changelogRelative

    if ($readme -cmatch '(?im)^\s*(actual\s+)?mooncakes\s+render(?:ing)?\s*(?:status)?\s*:\s*(?:pass|verified|match(?:es|ed)?)\s*$') {
      Fail-Rule 'PROV03-FABRICATED-RENDER' "$readmeRelative fabricates live Mooncakes rendering proof; only PROV-05 in Phase 8 may establish it."
    }
  }
}

function Copy-CandidateFixture {
  $root = Join-Path ([System.IO.Path]::GetTempPath()) ('mnf-candidate-docs-' + [guid]::NewGuid().ToString('N'))
  foreach ($relative in @(
    'policy/foundation.json', 'policy/compatibility.json',
    'policy/release-qualification.json', 'fixtures/manifest.json',
    $candidateDocument, 'docs/support.md', 'SECURITY.md'
  )) {
    $destination = Join-Path $root $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot $relative) -Destination $destination
  }
  foreach ($row in $selectedRows) {
    foreach ($name in @('moon.mod.json', 'README.mbt.md', 'CHANGELOG.md')) {
      $relative = "$($row.path)/$name"
      $destination = Join-Path $root $relative
      New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
      Copy-Item -LiteralPath (Join-Path $repoRoot $relative) -Destination $destination
    }
  }
  foreach ($relative in @('examples/ppm-portable/main/main.mbt', 'examples/ppm-native-cli/main/adapter.mbt')) {
    $destination = Join-Path $root $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot $relative) -Destination $destination
  }
  return $root
}

function Remove-CandidateFixture {
  param([Parameter(Mandatory)][string]$Path)
  $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
  $full = [System.IO.Path]::GetFullPath($Path)
  if (-not $full.StartsWith($tempRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or
      -not (Split-Path -Leaf $full).StartsWith('mnf-candidate-docs-', [System.StringComparison]::Ordinal)) {
    throw "Refusing to remove unverified negative-fixture path: $full"
  }
  Remove-Item -LiteralPath $full -Recurse -Force
}

function Invoke-NegativeCase {
  param([string]$Name, [string]$ExpectedRule, [scriptblock]$Mutate)
  $root = Copy-CandidateFixture
  try {
    & $Mutate $root
    try {
      Assert-CandidateTree -Root $root
      throw "Negative candidate case unexpectedly passed: $Name"
    } catch {
      if (-not $_.Exception.Message.StartsWith("[$ExpectedRule]", [System.StringComparison]::Ordinal)) {
        throw "Negative candidate case '$Name' failed with wrong rule: $($_.Exception.Message)"
      }
    }
  } finally {
    Remove-CandidateFixture -Path $root
  }
}

$writeUtf8 = { param($path, $text) [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false)) }

function Add-ValidPublicationSourceRecords {
  param([Parameter(Mandatory)][string]$Root)
  $compatibility = Read-RequiredJson -Root $Root -Relative 'policy/compatibility.json' -Rule 'PROV03-POLICY'
  $release = Read-RequiredJson -Root $Root -Relative 'policy/release-qualification.json' -Rule 'PROV03-POLICY'
  $profile = $compatibility.baseline_profiles.'0.1.0'
  foreach ($row in $selectedRows) {
    $modulePolicy = $release.modules.PSObject.Properties[$row.short].Value
    $imports = @($modulePolicy.public_packages | ForEach-Object { [string]$_ }) -join ','
    $records = @(
      "01|install|moon add $($modulePolicy.manifest.name)@$($modulePolicy.manifest.version)",
      "02|imports|$imports",
      "03|status|$($release.candidate_status)",
      "04|targets|$(@($profile.supported_targets) -join ',')",
      "05|toolchain|moon=$($profile.minimum_toolchain.moon);moonc=$($profile.minimum_toolchain.moonc);moonrun=$($profile.minimum_toolchain.moonrun)",
      '06|class|exact',
      '07|support|docs/support.md',
      '08|security|SECURITY.md',
      '09|changelog|CHANGELOG.md',
      '10|migration|not-required',
      '11|rfc|not-required',
      '12|impacts|none',
      '13|registry-source|moon.mod.json',
      '14|registry-render|unknown;proof=PROV-05;phase=8',
      '15|ambiguity|none'
    )
    $readmePath = Join-Path $Root "$($row.path)/README.mbt.md"
    $readme = Get-Content -LiteralPath $readmePath -Raw
    $readme = [regex]::Replace($readme, '(?ms)\r?\n<!-- mnf-publication-source:v1 -->.*?<!-- /mnf-publication-source -->\r?\n?', '')
    & $writeUtf8 $readmePath ($readme.TrimEnd() + "`n`n<!-- mnf-publication-source:v1 -->`n" + ($records -join "`n") + "`n<!-- /mnf-publication-source -->`n")
    $changelogPath = Join-Path $Root "$($row.path)/CHANGELOG.md"
    $changelog = Get-Content -LiteralPath $changelogPath -Raw
    $changelog = [regex]::Replace($changelog, '(?m)^Change class: .*$\r?\n^Migration: .*$\r?\n^RFC: .*$', '')
    & $writeUtf8 $changelogPath ($changelog.TrimEnd() + "`n`nChange class: exact`nMigration: not-required`nRFC: not-required; impacts: none`n")
  }
}

function Invoke-SourceNegativeCase {
  param([string]$Name, [string]$ExpectedRule, [scriptblock]$Mutate)
  $root = Copy-CandidateFixture
  try {
    Add-ValidPublicationSourceRecords -Root $root
    $mutationRow = $selectedRows[0]
    & $Mutate $root $mutationRow
    $failure = $null
    try { Assert-PublicationSourceContract -Root $root } catch { $failure = $_.Exception.Message }
    if ($null -eq $failure -or -not $failure.StartsWith("[$ExpectedRule]", [System.StringComparison]::Ordinal)) {
      throw "Source negative '$Name' passed or failed for the wrong rule: '$failure'."
    }
  } finally {
    Remove-CandidateFixture -Path $root
  }
}

if ($ContractSelfTest) {
  $root = Copy-CandidateFixture
  try {
    Add-ValidPublicationSourceRecords -Root $root
    Assert-PublicationSourceContract -Root $root
  } finally { Remove-CandidateFixture -Path $root }

  Invoke-SourceNegativeCase 'missing install command' 'PROV03-RECORD-ORDER' { param($root,$row) $p=Join-Path $root "$($row.path)/README.mbt.md"; & $writeUtf8 $p ((Get-Content -Raw $p) -replace '(?m)^01\|install\|.*\r?\n','') }
  Invoke-SourceNegativeCase 'incorrect install command' 'PROV03-INSTALL' { param($root,$row) $p=Join-Path $root "$($row.path)/README.mbt.md"; & $writeUtf8 $p ((Get-Content -Raw $p).Replace("moon add $($row.name)@0.1.0", "moon add $($row.name)@latest")) }
  Invoke-SourceNegativeCase 'support route drift' 'PROV03-SUPPORT' { param($root,$row) $p=Join-Path $root "$($row.path)/README.mbt.md"; & $writeUtf8 $p ((Get-Content -Raw $p).Replace('07|support|docs/support.md','07|support|docs/help.md')) }
  Invoke-SourceNegativeCase 'class disagreement' 'PROV03-CLASS' { param($root,$row) $p=Join-Path $root "$($row.path)/CHANGELOG.md"; & $writeUtf8 $p ((Get-Content -Raw $p).Replace('Change class: exact','Change class: additive')) }
  Invoke-SourceNegativeCase 'dependency floor disagreement' 'PROV03-DEPENDENCY-FLOOR' {
    param($root,$row)
    $p = Join-Path $root 'policy/compatibility.json'
    $j = Get-Content -Raw $p | ConvertFrom-Json -Depth 100
    $floors = $j.baseline_profiles.'0.1.0'.dependency_floors.PSObject.Properties[$row.short].Value
    $floors | Add-Member NoteProperty 'tchivs/mb-unexpected' '9.9.9'
    & $writeUtf8 $p (($j | ConvertTo-Json -Depth 100) + "`n")
  }
  Invoke-SourceNegativeCase 'missing migration' 'COMP04-MIGRATION-REQUIRED' { param($root,$row) $rp=Join-Path $root "$($row.path)/README.mbt.md"; $cp=Join-Path $root "$($row.path)/CHANGELOG.md"; & $writeUtf8 $rp ((Get-Content -Raw $rp).Replace('06|class|exact','06|class|incompatible')); & $writeUtf8 $cp ((Get-Content -Raw $cp).Replace('Change class: exact','Change class: incompatible')) }
  Invoke-SourceNegativeCase 'missing RFC' 'COMP04-RFC-REQUIRED' { param($root,$row) $p=Join-Path $root "$($row.path)/README.mbt.md"; & $writeUtf8 $p ((Get-Content -Raw $p).Replace('12|impacts|none','12|impacts|boundary')) }
  Invoke-SourceNegativeCase 'unsupported manifest field' 'PROV03-MANIFEST-CLOSED' { param($root,$row) $p=Join-Path $root "$($row.path)/moon.mod.json"; $j=Get-Content -Raw $p | ConvertFrom-Json; $j | Add-Member NoteProperty unsupported 'no'; & $writeUtf8 $p (($j | ConvertTo-Json -Depth 20) + "`n") }
  Invoke-SourceNegativeCase 'empty ambiguity' 'PROV03-EMPTY-AMBIGUITY' { param($root,$row) $p=Join-Path $root "$($row.path)/README.mbt.md"; & $writeUtf8 $p ((Get-Content -Raw $p).Replace('15|ambiguity|none','15|ambiguity|')) }
  Invoke-SourceNegativeCase 'duplicate record' 'PROV03-DUPLICATE-RECORD' { param($root,$row) $p=Join-Path $root "$($row.path)/README.mbt.md"; & $writeUtf8 $p ((Get-Content -Raw $p).Replace('<!-- /mnf-publication-source -->',"15|ambiguity|none`n<!-- /mnf-publication-source -->")) }
  Invoke-SourceNegativeCase 'reordered records' 'PROV03-RECORD-ORDER' { param($root,$row) $p=Join-Path $root "$($row.path)/README.mbt.md"; $t=Get-Content -Raw $p; $t=$t.Replace("01|install|moon add $($row.name)@0.1.0`n02|imports|","02|imports|"); $t=$t.Replace('03|status|',"01|install|moon add $($row.name)@0.1.0`n03|status|"); & $writeUtf8 $p $t }
  Invoke-SourceNegativeCase 'fabricated registry render' 'PROV03-FABRICATED-RENDER' { param($root,$row) $p=Join-Path $root "$($row.path)/README.mbt.md"; & $writeUtf8 $p ((Get-Content -Raw $p) + "`nMooncakes render status: pass`n") }
  Write-Host "PROV-03 source-document contract self-test passed for selector '$Module'; current module documents remain intentionally unpromoted until Plan 06-05."
  exit 0
}

Assert-CandidateTree -Root $repoRoot
Assert-PublicationSourceContract -Root $repoRoot

if ($Module -ceq 'all') {
  Invoke-NegativeCase 'missing changelog' 'QUAL04-DOC-REQUIRED' { param($root) Remove-Item -LiteralPath (Join-Path $root 'modules/mb-core/CHANGELOG.md') }
  Invoke-NegativeCase 'missing support target' 'QUAL04-SUPPORT-MATRIX' { param($root) $p=Join-Path $root 'modules/mb-color/README.mbt.md'; & $writeUtf8 $p ((Get-Content -Raw $p).Replace('`wasm-gc`', '`wasm_gc`')) }
  Invoke-NegativeCase 'manifest repository drift' 'QUAL04-MANIFEST-METADATA' { param($root) $p=Join-Path $root 'modules/mb-image/moon.mod.json'; & $writeUtf8 $p ((Get-Content -Raw $p).Replace('https://github.com/tchivs/moonbit-foundation', 'https://invalid.example/mismatch')) }
  Invoke-NegativeCase 'package DAG omission' 'QUAL04-PACKAGE-DAG' { param($root) $p=Join-Path $root $candidateDocument; & $writeUtf8 $p ((Get-Content -Raw $p).Replace('tchivs/mb-image/ppm->[', 'tchivs/mb-image/ppm-omitted->[')) }
  Invoke-NegativeCase 'fixture digest drift' 'QUAL04-FIXTURE-PROVENANCE' { param($root) $p=Join-Path $root $candidateDocument; & $writeUtf8 $p ((Get-Content -Raw $p).Replace('6e1f367c78839e8e06237a784ebe75732ee3fd2a27d3dc56434c7e6e12676967', ('0' * 64))) }
  Invoke-NegativeCase 'missing runnable example' 'QUAL04-EXAMPLE-RUNNABLE' { param($root) Remove-Item -LiteralPath (Join-Path $root 'examples/ppm-portable/main/main.mbt') }
  foreach ($claim in @('stable', 'full-ppm-conformance', 'published', 'llvm-required', 'performance-superiority')) {
    Invoke-NegativeCase "prohibited $claim claim" 'QUAL04-CLAIM-BOUNDARY' { param($root) $p=Join-Path $root $candidateDocument; & $writeUtf8 $p ((Get-Content -Raw $p) + "`nMNF CLAIM: $claim`n") }
  }
}

foreach ($target in $requiredTargets) {
  foreach ($row in $selectedRows) {
    & moon -C (Join-Path $repoRoot $row.path) check README.mbt.md --target $target --frozen
    if ($LASTEXITCODE -ne 0) {
      Fail-Rule 'QUAL04-EXAMPLE-RUNNABLE' "Literate README failed for $($row.short) on $target."
    }
  }
}
if ($Module -ceq 'all') {
  & (Join-Path $repoRoot 'scripts/quality/Test-PublicExamples.ps1') -Example all -Mode workspace -Target all
  if ($LASTEXITCODE -ne 0) {
    Fail-Rule 'QUAL04-EXAMPLE-RUNNABLE' 'Standalone public examples failed.'
  }
}

Write-Host "QUAL-04/PROV-03 candidate source documentation contract passed for selector '$Module'; actual Mooncakes rendering remains unknown until PROV-05 in Phase 8."
