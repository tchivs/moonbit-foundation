[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$requiredTargets = @('js', 'wasm', 'wasm-gc', 'native')
$compactTargets = '+js+wasm+wasm-gc+native'
$candidateDocument = 'docs/release/v0.1-candidate.md'
$moduleRows = @(
  [ordered]@{ name = 'moonbit-foundation/mb-core'; path = 'modules/mb-core'; fixtures = @() },
  [ordered]@{ name = 'moonbit-foundation/mb-color'; path = 'modules/mb-color'; fixtures = @('color-srgb-reference-vectors', 'color-derived-edge-vectors') },
  [ordered]@{ name = 'moonbit-foundation/mb-image'; path = 'modules/mb-image'; fixtures = @('image-operation-vectors', 'ppm-p6-conformance-vectors') }
)

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

  foreach ($row in $moduleRows) {
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

function Copy-CandidateFixture {
  $root = Join-Path ([System.IO.Path]::GetTempPath()) ('mnf-candidate-docs-' + [guid]::NewGuid().ToString('N'))
  foreach ($relative in @('policy/foundation.json', 'fixtures/manifest.json', $candidateDocument)) {
    $destination = Join-Path $root $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot $relative) -Destination $destination
  }
  foreach ($row in $moduleRows) {
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

Assert-CandidateTree -Root $repoRoot

$writeUtf8 = { param($path, $text) [System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false)) }
Invoke-NegativeCase 'missing changelog' 'QUAL04-DOC-REQUIRED' { param($root) Remove-Item -LiteralPath (Join-Path $root 'modules/mb-core/CHANGELOG.md') }
Invoke-NegativeCase 'missing support target' 'QUAL04-SUPPORT-MATRIX' { param($root) $p=Join-Path $root 'modules/mb-color/README.mbt.md'; & $writeUtf8 $p ((Get-Content -Raw $p).Replace('`wasm-gc`', '`wasm_gc`')) }
Invoke-NegativeCase 'manifest repository drift' 'QUAL04-MANIFEST-METADATA' { param($root) $p=Join-Path $root 'modules/mb-image/moon.mod.json'; & $writeUtf8 $p ((Get-Content -Raw $p).Replace('https://github.com/moonbit-foundation/moonbit-foundation', 'https://invalid.example/mismatch')) }
Invoke-NegativeCase 'package DAG omission' 'QUAL04-PACKAGE-DAG' { param($root) $p=Join-Path $root $candidateDocument; & $writeUtf8 $p ((Get-Content -Raw $p).Replace('moonbit-foundation/mb-image/ppm->[', 'moonbit-foundation/mb-image/ppm-omitted->[')) }
Invoke-NegativeCase 'fixture digest drift' 'QUAL04-FIXTURE-PROVENANCE' { param($root) $p=Join-Path $root $candidateDocument; & $writeUtf8 $p ((Get-Content -Raw $p).Replace('6e1f367c78839e8e06237a784ebe75732ee3fd2a27d3dc56434c7e6e12676967', ('0' * 64))) }
Invoke-NegativeCase 'missing runnable example' 'QUAL04-EXAMPLE-RUNNABLE' { param($root) Remove-Item -LiteralPath (Join-Path $root 'examples/ppm-portable/main/main.mbt') }
foreach ($claim in @('stable', 'full-ppm-conformance', 'published', 'llvm-required', 'performance-superiority')) {
  Invoke-NegativeCase "prohibited $claim claim" 'QUAL04-CLAIM-BOUNDARY' { param($root) $p=Join-Path $root $candidateDocument; & $writeUtf8 $p ((Get-Content -Raw $p) + "`nMNF CLAIM: $claim`n") }
}

foreach ($target in $requiredTargets) {
  foreach ($module in @('mb-core', 'mb-color', 'mb-image')) {
    & moon -C (Join-Path $repoRoot "modules/$module") check README.mbt.md --target $target --frozen
    if ($LASTEXITCODE -ne 0) {
      Fail-Rule 'QUAL04-EXAMPLE-RUNNABLE' "Literate README failed for $module on $target."
    }
  }
}
& (Join-Path $repoRoot 'scripts/quality/Test-PublicExamples.ps1') -Example all -Mode workspace -Target all
if ($LASTEXITCODE -ne 0) {
  Fail-Rule 'QUAL04-EXAMPLE-RUNNABLE' 'Standalone public examples failed.'
}

Write-Host 'QUAL-04 candidate documentation, metadata, support, DAG, provenance, examples, and claim negatives passed.'
