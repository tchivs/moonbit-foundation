[CmdletBinding()]
param(
  [string]$EvidenceDirectory = 'artifacts/release-qualification/font-v3',
  [switch]$ImportOnly,
  [switch]$ContractOnly,
  [ValidateSet('js', 'wasm', 'wasm-gc', 'native')]
  [string]$Target,
  [switch]$TracerOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Utf8NoBom = [Text.UTF8Encoding]::new($false)
$Targets = @('js', 'wasm', 'wasm-gc', 'native')
$EvidenceWorkflowId = 'font-complete-public-v3'
$EvidenceSchemaVersion = '3.0.0'
$EvidenceMarkerName = '.mnf-font-qualification-managed.json'
$EvidenceMarkerSchema = 'mnf-font-qualification-evidence/v3'
$EvidenceProductNames = @(
  'js.json',
  'wasm.json',
  'wasm-gc.json',
  'native.json',
  'comparison.json'
)
$NormalizationRemoved = @('target', 'runner')
$FocusedPassSummary = 'Total tests: 1, passed: 1, failed: 0.'
$RecordKeys = @(
  'schema_version',
  'workflow_id',
  'target',
  'toolchain',
  'fixtures',
  'oracle_facts',
  'generated_cff_facts',
  'licensed_cff_facts',
  'public_workflow_facts',
  'cff_hostile_outcomes',
  'mutation_atomicity_facts',
  'glyf_compatibility_facts',
  'benchmark_correctness_facts',
  'boundary_facts',
  'dependency_facts',
  'source_identities',
  'focused_assertions',
  'runner',
  'pass'
)

$PublicEvidenceAssertions = @(
  [pscustomobject][ordered]@{
    kind = 'public'
    module = 'benchmarks/font-cff'
    file = 'cff_qualification_wbtest.mbt'
    name = 'font-cff1-v3 carrier-public generated-name standalone and selected tracer'
  },
  [pscustomobject][ordered]@{
    kind = 'public'
    module = 'benchmarks/font-cff'
    file = 'cff_qualification_wbtest.mbt'
    name = 'font-cff1-v3 carrier-public every standalone and selected workflow'
  },
  [pscustomobject][ordered]@{
    kind = 'public'
    module = 'benchmarks/font-cff'
    file = 'cff_qualification_wbtest.mbt'
    name = 'font-cff1-v3 carrier-public caller mutation is exact and atomic'
  },
  [pscustomobject][ordered]@{
    kind = 'public'
    module = 'benchmarks/font-cff'
    file = 'cff_qualification_wbtest.mbt'
    name = 'font-cff1-v3 carrier-public timing-free correctness workloads'
  }
)
$PrivateFocusedAssertions = @(
  [pscustomobject][ordered]@{
    kind = 'private'
    module = 'modules/mb-font'
    file = 'font/cff_cid_fixture_wbtest.mbt'
    name = 'font-cff1-v3 private fd oracle'
  },
  [pscustomobject][ordered]@{
    kind = 'private'
    module = 'modules/mb-font'
    file = 'font/cff_hostile_fixture_wbtest.mbt'
    name = 'font-cff1-v3 private hostile outcomes'
  },
  [pscustomobject][ordered]@{
    kind = 'private'
    module = 'modules/mb-font'
    file = 'font/cff_hostile_fixture_wbtest.mbt'
    name = 'font-cff1-v3 private mutation windows and atomic budgets'
  }
)
$FocusedAssertions = @($PublicEvidenceAssertions + $PrivateFocusedAssertions)

$ProductionSourcePaths = @(
  'modules/mb-font/moon.mod.json',
  'modules/mb-font/font/moon.pkg',
  'modules/mb-font/font/cmap.mbt',
  'modules/mb-font/font/collection.mbt',
  'modules/mb-font/font/collection_limits.mbt',
  'modules/mb-font/font/collection_parser.mbt',
  'modules/mb-font/font/cursor.mbt',
  'modules/mb-font/font/directory.mbt',
  'modules/mb-font/font/font.mbt',
  'modules/mb-font/font/kern.mbt',
  'modules/mb-font/font/limits.mbt',
  'modules/mb-font/font/metrics.mbt',
  'modules/mb-font/font/outline.mbt',
  'modules/mb-font/font/tables.mbt',
  'modules/mb-font/font/cff_index.mbt',
  'modules/mb-font/font/cff_dict.mbt',
  'modules/mb-font/font/cff_keying.mbt',
  'modules/mb-font/font/cff_type2_fixed.mbt',
  'modules/mb-font/font/cff_type2.mbt',
  'modules/mb-font/font/cff_type2_bounds.mbt',
  'modules/mb-font/font/cff_type2_path.mbt',
  'modules/mb-font/font/cff_admission.mbt'
)
$FontTestSourcePaths = @(
  'modules/mb-font/font/cff_admission_wbtest.mbt',
  'modules/mb-font/font/cff_cid_fixture_wbtest.mbt',
  'modules/mb-font/font/cff_dict_wbtest.mbt',
  'modules/mb-font/font/cff_hostile_fixture_wbtest.mbt',
  'modules/mb-font/font/cff_index_wbtest.mbt',
  'modules/mb-font/font/cff_keying_wbtest.mbt',
  'modules/mb-font/font/cff_name_keyed_fixture_wbtest.mbt',
  'modules/mb-font/font/cff_type2_bounds_wbtest.mbt',
  'modules/mb-font/font/cff_type2_fixed_wbtest.mbt',
  'modules/mb-font/font/cff_type2_fixture_wbtest.mbt',
  'modules/mb-font/font/cff_type2_path_wbtest.mbt',
  'modules/mb-font/font/cff_type2_wbtest.mbt',
  'modules/mb-font/font/collection_test.mbt',
  'modules/mb-font/font/collection_wbtest.mbt',
  'modules/mb-font/font/font_qualification_hostile_test.mbt',
  'modules/mb-font/font/font_qualification_test.mbt',
  'modules/mb-font/font/font_test.mbt',
  'modules/mb-font/font/font_wbtest.mbt',
  'modules/mb-font/font/generated_font_qualification_test.mbt',
  'modules/mb-font/font/generated_fonts_wbtest.mbt'
)
$EvidenceSourcePaths = @(
  'benchmarks/font-cff/moon.mod.json',
  'benchmarks/font-cff/moon.pkg',
  'benchmarks/font-cff/generated_cff_evidence.mbt',
  'benchmarks/font-cff/cff_qualification_wbtest.mbt'
)
$FixtureSourcePaths = @(
  'fixtures/manifest.json',
  'fixtures/font/cff-qualification-cases.json',
  'fixtures/font/cff-oracle-tools.json',
  'fixtures/font/cff/host-toolchain.lock.json',
  'fixtures/font/source-sans-3.052r/SourceSans3-Regular.otf',
  'fixtures/font/source-sans-3.052r/LICENSE.md',
  'fixtures/font/source-sans-3.052r/qualification.json',
  'fixtures/font/source-han-serif-2.003r/SourceHanSerifJP-Regular.otf',
  'fixtures/font/source-han-serif-2.003r/LICENSE.txt',
  'fixtures/font/source-han-serif-2.003r/qualification.json'
)
$OracleToolSourcePaths = @(
  'scripts/fixtures/Provision-CffQualificationTools.ps1',
  'scripts/fixtures/Test-CffQualificationTools.ps1',
  'scripts/fixtures/Test-CffQualificationContracts.ps1',
  'scripts/fixtures/oracles/fonttools_cff_oracle.py',
  'scripts/fixtures/oracles/Invoke-AfdkoCffOracle.ps1'
)
$QualificationToolSourcePaths = @(
  'scripts/fixtures/Generate-FontQualification.ps1',
  'scripts/quality/Assert-Policy.ps1',
  'scripts/quality/Invoke-FontQualification.ps1',
  'scripts/quality/Test-FontQualificationEvidenceBoundary.ps1'
)
$ProductionImports = @(
  'tchivs/mb-core/budget',
  'tchivs/mb-core/bytes',
  'tchivs/mb-core/checked',
  'tchivs/mb-core/error',
  'tchivs/mb-core/math'
)
$EvidencePackageImports = @(
  'moonbitlang/core/bench',
  'tchivs/mb-core/budget',
  'tchivs/mb-core/bytes',
  'tchivs/mb-core/error',
  'tchivs/mb-core/math',
  'tchivs/mb-font/font'
)
$EvidenceTestOnlyCoreImports = @(
  'tchivs/mb-core/budget',
  'tchivs/mb-core/bytes',
  'tchivs/mb-core/error',
  'tchivs/mb-core/math'
)
$script:ExpectedSemanticSections = $null

function Get-FontQualificationSha256 {
  param([Parameter(Mandatory)][byte[]]$Bytes)

  return [Convert]::ToHexString(
    [Security.Cryptography.SHA256]::HashData($Bytes)
  ).ToLowerInvariant()
}

function ConvertTo-FontQualificationJson {
  param(
    [Parameter(Mandatory)]$Value,
    [switch]$Compress
  )

  $json = if ($Compress) {
    $Value | ConvertTo-Json -Depth 100 -Compress
  } else {
    $Value | ConvertTo-Json -Depth 100
  }
  return $json.Replace("`r`n", "`n")
}

function Write-FontQualificationJson {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)]$Value
  )

  [IO.File]::WriteAllText(
    $Path,
    (ConvertTo-FontQualificationJson $Value) + "`n",
    $Utf8NoBom
  )
}

function Read-FontQualificationJson {
  param([Parameter(Mandatory)][string]$Path)

  return Get-Content -Raw -LiteralPath (Join-Path $RepositoryRoot $Path) |
    ConvertFrom-Json -Depth 100
}

function Assert-FontQualificationClosedKeys {
  param(
    [Parameter(Mandatory)]$Value,
    [Parameter(Mandatory)][string[]]$Expected,
    [Parameter(Mandatory)][string]$Label
  )

  $actual = @($Value.PSObject.Properties.Name)
  if (($actual -join "`0") -cne ($Expected -join "`0")) {
    throw "$Label keys or order drifted."
  }
}

function Assert-FontQualificationExactValue {
  param(
    [Parameter(Mandatory)]$Actual,
    [Parameter(Mandatory)]$Expected,
    [Parameter(Mandatory)][string]$Label
  )

  if ((ConvertTo-FontQualificationJson $Actual -Compress) -cne
      (ConvertTo-FontQualificationJson $Expected -Compress)) {
    throw "$Label exact ordered value drifted."
  }
}

function Get-FontQualificationFileFact {
  param([Parameter(Mandatory)][string]$Path)

  $resolved = (Resolve-Path -LiteralPath (Join-Path $RepositoryRoot $Path)).Path
  $bytes = [IO.File]::ReadAllBytes($resolved)
  return [pscustomobject][ordered]@{
    path = [IO.Path]::GetRelativePath($RepositoryRoot, $resolved).Replace('\', '/')
    length = [int64]$bytes.LongLength
    sha256 = Get-FontQualificationSha256 $bytes
  }
}

function Get-FontQualificationFileFacts {
  param([Parameter(Mandatory)][string[]]$Paths)

  return @($Paths | ForEach-Object { Get-FontQualificationFileFact $_ })
}

function Assert-FontQualificationExactPaths {
  param(
    [Parameter(Mandatory)][object[]]$Facts,
    [Parameter(Mandatory)][string[]]$Paths,
    [Parameter(Mandatory)][string]$Label
  )

  if ($Facts.Count -ne $Paths.Count) {
    throw "$Label count drifted."
  }
  for ($index = 0; $index -lt $Paths.Count; $index++) {
    Assert-FontQualificationClosedKeys `
      $Facts[$index] @('path','length','sha256') "$Label $index"
    if ([string]$Facts[$index].path -cne $Paths[$index]) {
      throw "$Label order drifted at $index."
    }
  }
}

function Get-FontQualificationExpectedToolchain {
  $policy = Read-FontQualificationJson 'policy/foundation.json'
  Assert-FontQualificationClosedKeys `
    $policy.toolchain @('moon','moonc','moonrun') 'Pinned toolchain'
  return [pscustomobject][ordered]@{
    moon = (
      "moon $($policy.toolchain.moon.version) " +
      "($($policy.toolchain.moon.commit) $($policy.toolchain.moon.release_date))"
    )
    moonc = (
      "moonc $($policy.toolchain.moonc.version) " +
      "($($policy.toolchain.moonc.release_date))"
    )
    moonrun = (
      "moonrun $($policy.toolchain.moonrun.version) " +
      "($($policy.toolchain.moonrun.commit) $($policy.toolchain.moonrun.release_date))"
    )
  }
}

function Get-FontQualificationToolchain {
  $lines = @(& moon version --all)
  if ($LASTEXITCODE -ne 0 -or $lines.Count -lt 3) {
    throw 'Unable to capture the complete MoonBit toolchain identity.'
  }
  $captured = [pscustomobject][ordered]@{
    moon = [regex]::Match($lines[0], '^moon \S+ \([^)]+\)').Value
    moonc = [regex]::Match($lines[1], '^moonc \S+ \([^)]+\)').Value
    moonrun = [regex]::Match($lines[2], '^moonrun \S+ \([^)]+\)').Value
  }
  Assert-FontQualificationExactValue `
    $captured (Get-FontQualificationExpectedToolchain) 'Pinned toolchain identity'
  return $captured
}

function Get-FontQualificationSemanticSections {
  if ($null -ne $script:ExpectedSemanticSections) {
    return $script:ExpectedSemanticSections
  }

  $cases = Read-FontQualificationJson 'fixtures/font/cff-qualification-cases.json'
  $sans = Read-FontQualificationJson (
    'fixtures/font/source-sans-3.052r/qualification.json'
  )
  $han = Read-FontQualificationJson (
    'fixtures/font/source-han-serif-2.003r/qualification.json'
  )
  $oracleTools = Read-FontQualificationJson 'fixtures/font/cff-oracle-tools.json'
  $hostLock = Read-FontQualificationJson 'fixtures/font/cff/host-toolchain.lock.json'
  $policy = Read-FontQualificationJson 'policy/foundation.json'
  $fontPolicy = @(
    $policy.modules | Where-Object { $_.name -ceq 'tchivs/mb-font' }
  )
  if ($fontPolicy.Count -ne 1) {
    throw 'Policy must contain exactly one tchivs/mb-font module.'
  }
  $fontPackage = @(
    $fontPolicy[0].public_packages |
      Where-Object { $_.name -ceq 'tchivs/mb-font/font' }
  )
  if ($fontPackage.Count -ne 1 -or
      @($fontPackage[0].semantic_interface).Count -ne 85) {
    throw 'Policy must retain the exact 85-line mb-font interface.'
  }
  $fontManifest = Read-FontQualificationJson 'modules/mb-font/moon.mod.json'
  $evidenceManifest = Read-FontQualificationJson 'benchmarks/font-cff/moon.mod.json'
  $productionPackageText = Get-Content -Raw -LiteralPath (
    Join-Path $RepositoryRoot 'modules/mb-font/font/moon.pkg'
  )
  $evidencePackageText = Get-Content -Raw -LiteralPath (
    Join-Path $RepositoryRoot 'benchmarks/font-cff/moon.pkg'
  )
  $productionImports = @(
    [regex]::Matches(
      $productionPackageText,
      '"(?<path>tchivs/mb-core/[^"]+)"'
    ) | ForEach-Object { $_.Groups['path'].Value }
  )
  $evidenceImports = @(
    [regex]::Matches(
      $evidencePackageText,
      '(?m)^\s*"(?<path>[^"]+)"(?:\s+@[A-Za-z0-9_]+)?,?\s*$'
    ) |
      ForEach-Object { $_.Groups['path'].Value }
  )
  if (($productionImports -join "`0") -cne ($ProductionImports -join "`0")) {
    throw 'mb-font production imports drifted from the exact five-import contract.'
  }
  if (($evidenceImports -join "`0") -cne ($EvidencePackageImports -join "`0")) {
    throw 'Non-published evidence package imports drifted.'
  }
  if (($cases.targets -join "`0") -cne ($Targets -join "`0")) {
    throw 'Canonical CFF target order drifted.'
  }
  $mutationGroup = @(
    $cases.hostile_groups | Where-Object { $_.id -ceq 'mutation' }
  )
  if ($mutationGroup.Count -ne 1) {
    throw 'Canonical CFF mutation group is missing or duplicated.'
  }
  $hostileCount = @(
    $cases.hostile_groups | ForEach-Object { @($_.rows).Count }
  ) | Measure-Object -Sum
  if ([int]$hostileCount.Sum -ne 53) {
    throw 'Canonical CFF hostile corpus must contain exactly 53 rows.'
  }

  $sourceIdentities = [pscustomobject][ordered]@{
    production = Get-FontQualificationFileFacts $ProductionSourcePaths
    mb_font_tests = Get-FontQualificationFileFacts $FontTestSourcePaths
    evidence_module = Get-FontQualificationFileFacts $EvidenceSourcePaths
    fixtures = Get-FontQualificationFileFacts $FixtureSourcePaths
    oracle_tools = Get-FontQualificationFileFacts $OracleToolSourcePaths
    qualification_tools = Get-FontQualificationFileFacts (
      $QualificationToolSourcePaths
    )
  }
  Assert-FontQualificationExactPaths `
    @($sourceIdentities.production) $ProductionSourcePaths 'production identities'
  Assert-FontQualificationExactPaths `
    @($sourceIdentities.mb_font_tests) $FontTestSourcePaths 'test identities'
  Assert-FontQualificationExactPaths `
    @($sourceIdentities.evidence_module) $EvidenceSourcePaths 'evidence identities'
  Assert-FontQualificationExactPaths `
    @($sourceIdentities.fixtures) $FixtureSourcePaths 'fixture identities'
  Assert-FontQualificationExactPaths `
    @($sourceIdentities.oracle_tools) $OracleToolSourcePaths 'oracle identities'
  Assert-FontQualificationExactPaths `
    @($sourceIdentities.qualification_tools) `
    $QualificationToolSourcePaths `
    'qualification identities'

  $sections = [pscustomobject][ordered]@{
    fixtures = [pscustomobject][ordered]@{
      canonical_corpus = Get-FontQualificationFileFact (
        'fixtures/font/cff-qualification-cases.json'
      )
      manifest = Get-FontQualificationFileFact 'fixtures/manifest.json'
      source_sans_font = Get-FontQualificationFileFact (
        'fixtures/font/source-sans-3.052r/SourceSans3-Regular.otf'
      )
      source_sans_notice = Get-FontQualificationFileFact (
        'fixtures/font/source-sans-3.052r/LICENSE.md'
      )
      source_han_font = Get-FontQualificationFileFact (
        'fixtures/font/source-han-serif-2.003r/SourceHanSerifJP-Regular.otf'
      )
      source_han_notice = Get-FontQualificationFileFact (
        'fixtures/font/source-han-serif-2.003r/LICENSE.txt'
      )
    }
    oracle_facts = [pscustomobject][ordered]@{
      tool_lock = Get-FontQualificationFileFact (
        'fixtures/font/cff/host-toolchain.lock.json'
      )
      tool_contract = Get-FontQualificationFileFact (
        'fixtures/font/cff-oracle-tools.json'
      )
      ordered_role_ids = @($hostLock.ordered_role_ids)
      ordered_command_ids = @($hostLock.ordered_command_ids)
      semantic_readers = $hostLock.semantic_readers
      structural_reader = $hostLock.structural_reader
      invoked_identities_sha256 = [string](
        $oracleTools.invoked_identities_sha256
      )
      adapters = $oracleTools.adapters
      independence = $oracleTools.independence
      provisioning_validated = [bool]$oracleTools.provisioning_validated
    }
    generated_cff_facts = [pscustomobject][ordered]@{
      schema = [string]$cases.schema
      license = [string]$cases.license
      recipes = @($cases.recipes)
      generated_workflows = @($cases.generated_workflows)
      expected_facts = @($cases.expected_facts)
    }
    licensed_cff_facts = [pscustomobject][ordered]@{
      source_sans = [pscustomobject][ordered]@{
        qualification = Get-FontQualificationFileFact (
          'fixtures/font/source-sans-3.052r/qualification.json'
        )
        upstream = $sans.upstream
        font = $sans.font
        notice = $sans.notice
        redistribution = $sans.redistribution
        profile = $sans.profile
        semantic_oracles = $sans.semantic_oracles
        structural_oracle = $sans.structural_oracle
        host_chain = $sans.host_chain
      }
      source_han = [pscustomobject][ordered]@{
        qualification = Get-FontQualificationFileFact (
          'fixtures/font/source-han-serif-2.003r/qualification.json'
        )
        upstream = $han.upstream
        font = $han.font
        notice = $han.notice
        redistribution = $han.redistribution
        profile = $han.profile
        semantic_oracles = $han.semantic_oracles
        structural_oracle = $han.structural_oracle
        host_chain = $han.host_chain
      }
    }
    public_workflow_facts = [pscustomobject][ordered]@{
      workflow_ids = @($cases.public_workflow_ids)
      generated_workflow_ids = @($cases.generated_workflows.id)
      observation_surface = @(
        'Font::open',
        'FontCollection::open',
        'FontCollection::open_face',
        'Font::glyph_for_scalar',
        'Font::horizontal_metrics',
        'Font::kerning',
        'Font::outline'
      )
      carrier_visibility = 'package-private'
      assertions = @($PublicEvidenceAssertions)
    }
    cff_hostile_outcomes = [pscustomobject][ordered]@{
      row_count = 53
      b8_order = @($cases.b8_order)
      groups = @($cases.hostile_groups)
    }
    mutation_atomicity_facts = [pscustomobject][ordered]@{
      b8_order = @($cases.b8_order)
      mutation_rows = @($mutationGroup[0].rows)
      precedence_cases = @($cases.precedence_cases)
      assertions = @($PrivateFocusedAssertions | Select-Object -Last 2)
    }
    glyf_compatibility_facts = [pscustomobject][ordered]@{
      lock_ids = @($cases.compatibility_lock_ids)
      assertion = 'font-cff1-v3 freezes static glyf semantic compatibility'
      source = Get-FontQualificationFileFact (
        'modules/mb-font/font/font_qualification_test.mbt'
      )
    }
    benchmark_correctness_facts = [pscustomobject][ordered]@{
      workloads = @($cases.workloads)
      timings_in_semantic_records = $false
      native_baseline = 'observation-only-separate-wave-6'
      comparison_or_threshold = 'forbidden'
    }
    boundary_facts = [pscustomobject][ordered]@{
      semantic_interface = @($fontPackage[0].semantic_interface)
      semantic_interface_count = 85
      production_sources = @($ProductionSourcePaths)
      production_source_count = $ProductionSourcePaths.Count
      production_imports = @($ProductionImports)
      public_cff_or_fixture_symbols = @()
      runtime_file_network_process_gui_ffi = @()
      target_specific_runtime_branches = @()
      deferred_profiles = @(
        'CFF2',
        'variable-font-instantiation',
        'WOFF1',
        'WOFF2',
        'shaping',
        'hint-execution',
        'rasterization',
        'color-bitmap',
        'authoring',
        'ambient-io',
        'ffi'
      )
      pure_moonbit_runtime = $true
    }
    dependency_facts = [pscustomobject][ordered]@{
      production = [pscustomobject][ordered]@{
        module_name = [string]$fontManifest.name
        module_version = [string]$fontManifest.version
        module_dependencies = @(
          [pscustomobject][ordered]@{
            name = 'tchivs/mb-core'
            version = [string]$fontManifest.deps.'tchivs/mb-core'
          }
        )
        package_imports = @($ProductionImports)
        supported_targets = [string]$fontManifest.'supported-targets'
      }
      evidence_module = [pscustomobject][ordered]@{
        published = $false
        module_name = [string]$evidenceManifest.name
        module_version = [string]$evidenceManifest.version
        module_dependencies = @(
          [pscustomobject][ordered]@{
            name = 'tchivs/mb-core'
            version = [string]$evidenceManifest.deps.'tchivs/mb-core'
          },
          [pscustomobject][ordered]@{
            name = 'tchivs/mb-font'
            version = [string]$evidenceManifest.deps.'tchivs/mb-font'
          }
        )
        package_imports = @($EvidencePackageImports)
        test_only_mb_core_imports = @($EvidenceTestOnlyCoreImports)
        supported_targets = [string]$evidenceManifest.'supported-targets'
        local_resolution = 'tracked-workspace-members-only-under-frozen'
        workspace_members = @(
          'modules/mb-core',
          'modules/mb-font',
          'benchmarks/font-cff'
        )
      }
    }
    source_identities = $sourceIdentities
  }
  $script:ExpectedSemanticSections = $sections
  return $sections
}

function Assert-FontQualificationEvidencePathHasNoLinks {
  param(
    [Parameter(Mandatory)][string]$Directory,
    [Parameter(Mandatory)][string]$ManagedRoot
  )

  $canonicalRoot = [IO.Path]::GetFullPath($ManagedRoot).TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
  )
  $candidate = [IO.Path]::GetFullPath($Directory).TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
  )
  $prefix = $canonicalRoot + [IO.Path]::DirectorySeparatorChar
  $comparison = if ([OperatingSystem]::IsWindows()) {
    [StringComparison]::OrdinalIgnoreCase
  } else {
    [StringComparison]::Ordinal
  }
  if ($candidate -cne $canonicalRoot -and
      -not $candidate.StartsWith($prefix, $comparison)) {
    throw "EvidenceDirectory must be contained by '$canonicalRoot'."
  }
  $components = [Collections.Generic.List[string]]::new()
  $components.Add($canonicalRoot)
  $relative = [IO.Path]::GetRelativePath($canonicalRoot, $candidate)
  if ($relative -cne '.') {
    $current = $canonicalRoot
    foreach ($segment in $relative.Split(
      [char[]]@(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
      ),
      [StringSplitOptions]::RemoveEmptyEntries
    )) {
      $current = Join-Path $current $segment
      $components.Add($current)
    }
  }
  foreach ($component in $components) {
    $item = Get-Item -Force -LiteralPath $component -ErrorAction SilentlyContinue
    if ($null -eq $item) { break }
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
      throw "EvidenceDirectory must not traverse a link or reparse point: '$component'."
    }
    if (-not $item.PSIsContainer) {
      throw "EvidenceDirectory component is not a directory: '$component'."
    }
  }
}

function Resolve-FontQualificationEvidencePath {
  param(
    [Parameter(Mandatory)][string]$EvidenceDirectory,
    [Parameter(Mandatory)][string]$ManagedRoot,
    [Parameter(Mandatory)][string]$RepositoryRoot
  )

  $canonicalRoot = [IO.Path]::GetFullPath($ManagedRoot).TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
  )
  $candidate = if ([IO.Path]::IsPathRooted($EvidenceDirectory)) {
    [IO.Path]::GetFullPath($EvidenceDirectory)
  } else {
    [IO.Path]::GetFullPath((Join-Path $RepositoryRoot $EvidenceDirectory))
  }
  $prefix = $canonicalRoot + [IO.Path]::DirectorySeparatorChar
  $comparison = if ([OperatingSystem]::IsWindows()) {
    [StringComparison]::OrdinalIgnoreCase
  } else {
    [StringComparison]::Ordinal
  }
  if (-not $candidate.StartsWith($prefix, $comparison)) {
    throw "EvidenceDirectory must be a child of '$canonicalRoot'."
  }
  Assert-FontQualificationEvidencePathHasNoLinks $candidate $canonicalRoot
  return $candidate
}

function Assert-FontQualificationEvidenceMarker {
  param([Parameter(Mandatory)][string]$Directory)

  $markerPath = Join-Path $Directory $EvidenceMarkerName
  if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) {
    throw "Managed font qualification evidence marker is missing from '$Directory'."
  }
  $markerItem = Get-Item -Force -LiteralPath $markerPath
  if (($markerItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw "Managed font qualification evidence marker must not be a link in '$Directory'."
  }
  try {
    $marker = Get-Content -Raw -LiteralPath $markerPath | ConvertFrom-Json
  } catch {
    throw "Managed font qualification evidence marker is invalid in '$Directory'."
  }
  Assert-FontQualificationClosedKeys `
    $marker @('schema','workflow_id') 'Managed evidence marker'
  if ($marker.schema -cne $EvidenceMarkerSchema -or
      $marker.workflow_id -cne $EvidenceWorkflowId) {
    throw "Managed font qualification evidence marker is invalid in '$Directory'."
  }
}

function Initialize-FontQualificationEvidenceDirectory {
  param(
    [Parameter(Mandatory)][string]$Directory,
    [Parameter(Mandatory)][string]$ManagedRoot
  )

  Assert-FontQualificationEvidencePathHasNoLinks $Directory $ManagedRoot
  if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $Directory)
  }
  Assert-FontQualificationEvidencePathHasNoLinks $Directory $ManagedRoot
  $markerPath = Join-Path $Directory $EvidenceMarkerName
  if (Test-Path -LiteralPath $markerPath) {
    Assert-FontQualificationEvidenceMarker $Directory
    return
  }
  if (@(Get-ChildItem -LiteralPath $Directory -Force).Count -ne 0) {
    throw "Refusing non-empty unowned font qualification evidence directory '$Directory'."
  }
  Write-FontQualificationJson $markerPath ([pscustomobject][ordered]@{
    schema = $EvidenceMarkerSchema
    workflow_id = $EvidenceWorkflowId
  })
}

function Clear-FontQualificationEvidenceFiles {
  param(
    [Parameter(Mandatory)][string]$Directory,
    [Parameter(Mandatory)][string]$ManagedRoot
  )

  Assert-FontQualificationEvidencePathHasNoLinks $Directory $ManagedRoot
  Assert-FontQualificationEvidenceMarker $Directory
  foreach ($evidenceName in $EvidenceProductNames) {
    Assert-FontQualificationEvidencePathHasNoLinks $Directory $ManagedRoot
    $path = Join-Path $Directory $evidenceName
    $item = Get-Item -Force -LiteralPath $path -ErrorAction SilentlyContinue
    if ($null -ne $item) {
      if ($item.PSIsContainer -or
          ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Managed evidence product must be a regular file: '$path'."
      }
      Remove-Item -LiteralPath $path -Force
    }
  }
}

function Assert-FontQualificationEvidenceWriteBoundary {
  param(
    [Parameter(Mandatory)][string]$Directory,
    [Parameter(Mandatory)][string]$ManagedRoot,
    [Parameter(Mandatory)][string]$FileName
  )

  if ([IO.Path]::GetFileName($FileName) -cne $FileName -or
      $FileName -cnotin $EvidenceProductNames) {
    throw "Evidence destination '$FileName' is not a managed qualification record."
  }
  Assert-FontQualificationEvidencePathHasNoLinks $Directory $ManagedRoot
  Assert-FontQualificationEvidenceMarker $Directory
  $destination = Join-Path $Directory $FileName
  if ([IO.Path]::GetFullPath((Split-Path -Parent $destination)) -cne
      [IO.Path]::GetFullPath($Directory)) {
    throw "Evidence destination '$destination' escaped its managed directory."
  }
  $item = Get-Item -Force -LiteralPath $destination -ErrorAction SilentlyContinue
  if ($null -ne $item -and
      ($item.PSIsContainer -or
       ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
    throw "Evidence destination must be a regular file: '$destination'."
  }
  return $destination
}

function Write-FontQualificationEvidenceJson {
  param(
    [Parameter(Mandatory)][string]$Directory,
    [Parameter(Mandatory)][string]$ManagedRoot,
    [Parameter(Mandatory)][string]$FileName,
    [Parameter(Mandatory)]$Value
  )

  $destination = Assert-FontQualificationEvidenceWriteBoundary `
    $Directory $ManagedRoot $FileName
  $temporaryPath = Join-Path $Directory (
    '.mnf-font-qualification-' + [Guid]::NewGuid().ToString('N') + '.tmp'
  )
  try {
    $bytes = $Utf8NoBom.GetBytes(
      (ConvertTo-FontQualificationJson $Value) + "`n"
    )
    $stream = [IO.FileStream]::new(
      $temporaryPath,
      [IO.FileMode]::CreateNew,
      [IO.FileAccess]::Write,
      [IO.FileShare]::None
    )
    try {
      $stream.Write($bytes, 0, $bytes.Length)
      $stream.Flush($true)
    } finally {
      $stream.Dispose()
    }
    Assert-FontQualificationEvidencePathHasNoLinks $Directory $ManagedRoot
    Assert-FontQualificationEvidenceMarker $Directory
    $item = Get-Item -Force -LiteralPath $temporaryPath
    if ($item.PSIsContainer -or
        ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
      throw 'Evidence staging destination is not a regular file.'
    }
    [IO.File]::Move($temporaryPath, $destination, $true)
    [void](Assert-FontQualificationEvidenceWriteBoundary `
      $Directory $ManagedRoot $FileName)
  } finally {
    if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
      Assert-FontQualificationEvidencePathHasNoLinks $Directory $ManagedRoot
      Remove-Item -LiteralPath $temporaryPath -Force
    }
  }
  return $destination
}

function Get-FontQualificationFocusedFacts {
  return @(
    $FocusedAssertions | ForEach-Object {
      [pscustomobject][ordered]@{
        kind = [string]$_.kind
        module = [string]$_.module
        file = [string]$_.file
        name = [string]$_.name
      }
    }
  )
}

function New-FontQualificationRunnerFact {
  param(
    [Parameter(Mandatory)][string]$Target,
    [Parameter(Mandatory)][ValidateSet('full','tracer')][string]$Mode,
    [Parameter(Mandatory)][object[]]$FocusedResults,
    [Parameter(Mandatory)][string]$FullPackageCommand,
    [Parameter(Mandatory)][int]$FullPackagePassTotal,
    [Parameter(Mandatory)][string]$FullPackageSummary
  )

  return [pscustomobject][ordered]@{
    mode = $Mode
    workspace_members = @(
      'modules/mb-core',
      'modules/mb-font',
      'benchmarks/font-cff'
    )
    manifest_sha256 = [pscustomobject][ordered]@{
      mb_core = (Get-FontQualificationFileFact (
        'modules/mb-core/moon.mod.json'
      )).sha256
      mb_font = (Get-FontQualificationFileFact (
        'modules/mb-font/moon.mod.json'
      )).sha256
      font_cff = (Get-FontQualificationFileFact (
        'benchmarks/font-cff/moon.mod.json'
      )).sha256
    }
    check_command = "moon check benchmarks/font-cff --target $Target --frozen"
    focused_commands = $FocusedResults
    full_package_command = $FullPackageCommand
    full_package_passed = $true
    full_package_pass_total = $FullPackagePassTotal
    full_package_summary = $FullPackageSummary
    target_directory = "isolated/phase107-font-v3-$Target"
    empty_cache = $true
    no_parallelize = $true
  }
}

function New-FontQualificationEvidenceRecord {
  param(
    [Parameter(Mandatory)][string]$Target,
    [Parameter(Mandatory)]$Toolchain,
    [Parameter(Mandatory)]$Runner
  )

  $sections = Get-FontQualificationSemanticSections
  return [pscustomobject][ordered]@{
    schema_version = $EvidenceSchemaVersion
    workflow_id = $EvidenceWorkflowId
    target = $Target
    toolchain = $Toolchain
    fixtures = $sections.fixtures
    oracle_facts = $sections.oracle_facts
    generated_cff_facts = $sections.generated_cff_facts
    licensed_cff_facts = $sections.licensed_cff_facts
    public_workflow_facts = $sections.public_workflow_facts
    cff_hostile_outcomes = $sections.cff_hostile_outcomes
    mutation_atomicity_facts = $sections.mutation_atomicity_facts
    glyf_compatibility_facts = $sections.glyf_compatibility_facts
    benchmark_correctness_facts = $sections.benchmark_correctness_facts
    boundary_facts = $sections.boundary_facts
    dependency_facts = $sections.dependency_facts
    source_identities = $sections.source_identities
    focused_assertions = Get-FontQualificationFocusedFacts
    runner = $Runner
    pass = $true
  }
}

function Assert-FontQualificationRunnerFact {
  param(
    [Parameter(Mandatory)]$Runner,
    [Parameter(Mandatory)][string]$Target
  )

  Assert-FontQualificationClosedKeys $Runner @(
    'mode',
    'workspace_members',
    'manifest_sha256',
    'check_command',
    'focused_commands',
    'full_package_command',
    'full_package_passed',
    'full_package_pass_total',
    'full_package_summary',
    'target_directory',
    'empty_cache',
    'no_parallelize'
  ) "$Target runner"
  Assert-FontQualificationClosedKeys `
    $Runner.manifest_sha256 @('mb_core','mb_font','font_cff') "$Target manifests"
  if ($Runner.mode -cnotin @('full','tracer') -or
      $Runner.full_package_passed -ne $true -or
      [int]$Runner.full_package_pass_total -lt 1 -or
      $Runner.empty_cache -ne $true -or
      $Runner.no_parallelize -ne $true -or
      $Runner.target_directory -cne "isolated/phase107-font-v3-$Target") {
    throw "$Target runner closed values drifted."
  }
  $expectedAssertions = if ($Runner.mode -ceq 'tracer') {
    @($PublicEvidenceAssertions[0]) + @($PrivateFocusedAssertions)
  } else {
    @($FocusedAssertions)
  }
  $results = @($Runner.focused_commands)
  if ($results.Count -ne $expectedAssertions.Count) {
    throw "$Target focused execution count drifted."
  }
  for ($index = 0; $index -lt $results.Count; $index++) {
    Assert-FontQualificationClosedKeys $results[$index] @(
      'kind','module','file','name','command','passed','pass_total'
    ) "$Target focused result $index"
    foreach ($key in @('kind','module','file','name')) {
      if ([string]$results[$index].$key -cne
          [string]$expectedAssertions[$index].$key) {
        throw "$Target focused assertion identity/order drifted at $index."
      }
    }
    if ($results[$index].passed -ne $true -or
        [int]$results[$index].pass_total -ne 1 -or
        [string]$results[$index].command -cnotmatch
          [regex]::Escape("--target $Target")) {
      throw "$Target focused assertion result drifted at $index."
    }
  }
}

function Assert-FontQualificationEvidenceRecord {
  param([Parameter(Mandatory)]$Record)

  Assert-FontQualificationClosedKeys `
    $Record $RecordKeys "$($Record.target) record"
  if ($Record.schema_version -cne $EvidenceSchemaVersion -or
      $Record.workflow_id -cne $EvidenceWorkflowId -or
      $Targets -cnotcontains [string]$Record.target -or
      $Record.pass -ne $true) {
    throw "$($Record.target) qualification identity or pass state drifted."
  }
  Assert-FontQualificationExactValue `
    $Record.toolchain `
    (Get-FontQualificationExpectedToolchain) `
    "$($Record.target) toolchain"
  $expected = Get-FontQualificationSemanticSections
  foreach ($key in @(
      'fixtures',
      'oracle_facts',
      'generated_cff_facts',
      'licensed_cff_facts',
      'public_workflow_facts',
      'cff_hostile_outcomes',
      'mutation_atomicity_facts',
      'glyf_compatibility_facts',
      'benchmark_correctness_facts',
      'boundary_facts',
      'dependency_facts',
      'source_identities'
    )) {
    Assert-FontQualificationExactValue `
      $Record.$key $expected.$key "$($Record.target) $key"
  }
  Assert-FontQualificationExactValue `
    $Record.focused_assertions `
    (Get-FontQualificationFocusedFacts) `
    "$($Record.target) focused assertions"
  Assert-FontQualificationRunnerFact $Record.runner ([string]$Record.target)
}

function Get-FontQualificationSemanticPayload {
  param([Parameter(Mandatory)]$Record)

  $semantic = [ordered]@{}
  foreach ($key in $RecordKeys) {
    if ($key -cnotin $NormalizationRemoved) {
      $semantic[$key] = $Record.$key
    }
  }
  return [pscustomobject]$semantic
}

function Assert-FontQualificationComparisonRecord {
  param(
    [Parameter(Mandatory)]$Comparison,
    [Parameter(Mandatory)][string]$Directory,
    [Parameter(Mandatory)][string]$ManagedRoot
  )

  Assert-FontQualificationClosedKeys $Comparison @(
    'schema_version',
    'workflow_id',
    'normalization_removed',
    'targets',
    'record_sha256',
    'semantic_sha256',
    'equal'
  ) 'font qualification comparison'
  Assert-FontQualificationClosedKeys `
    $Comparison.record_sha256 $Targets 'comparison record hashes'
  if ($Comparison.schema_version -cne $EvidenceSchemaVersion -or
      $Comparison.workflow_id -cne $EvidenceWorkflowId -or
      (@($Comparison.normalization_removed) -join "`0") -cne
        ($NormalizationRemoved -join "`0") -or
      (@($Comparison.targets) -join "`0") -cne ($Targets -join "`0") -or
      $Comparison.equal -ne $true) {
    throw 'Font qualification comparison identity or closed values drifted.'
  }
  $canonical = @(
    foreach ($target in $Targets) {
      $path = Assert-FontQualificationEvidenceWriteBoundary `
        $Directory $ManagedRoot "$target.json"
      $bytes = [IO.File]::ReadAllBytes($path)
      if ([string]$Comparison.record_sha256.$target -cne
          (Get-FontQualificationSha256 $bytes)) {
        throw "Font qualification comparison hash drifted for '$target'."
      }
      $record = $Utf8NoBom.GetString($bytes) | ConvertFrom-Json -Depth 100
      Assert-FontQualificationEvidenceRecord $record
      if ($record.target -cne $target) {
        throw "Font qualification comparison target drifted for '$target'."
      }
      ConvertTo-FontQualificationJson `
        (Get-FontQualificationSemanticPayload $record) -Compress
    }
  )
  if (@($canonical | Select-Object -Unique).Count -ne 1) {
    throw 'Font qualification comparison read-back semantics differ.'
  }
  if ($Comparison.semantic_sha256 -cne
      (Get-FontQualificationSha256 $Utf8NoBom.GetBytes($canonical[0]))) {
    throw 'Font qualification comparison semantic hash drifted.'
  }
}

function Compare-FontQualificationEvidence {
  param(
    [Parameter(Mandatory)][object[]]$Records,
    [Parameter(Mandatory)][string]$Directory,
    [Parameter(Mandatory)][string]$ManagedRoot
  )

  if ($Records.Count -ne 4) {
    throw 'Exactly four target evidence records are required.'
  }
  for ($index = 0; $index -lt $Targets.Count; $index++) {
    if ([string]$Records[$index].target -cne $Targets[$index]) {
      throw "Target evidence order drifted at index $index."
    }
  }
  if (@($Records.target | Select-Object -Unique).Count -ne 4) {
    throw 'Target evidence records must be unique.'
  }
  $canonical = @(
    foreach ($record in $Records) {
      Assert-FontQualificationEvidenceRecord $record
      ConvertTo-FontQualificationJson `
        (Get-FontQualificationSemanticPayload $record) -Compress
    }
  )
  if (@($canonical | Select-Object -Unique).Count -ne 1) {
    throw 'Four-target font qualification semantics differ.'
  }
  $recordHashes = [pscustomobject][ordered]@{}
  foreach ($target in $Targets) {
    $path = Join-Path $Directory "$target.json"
    $recordHashes | Add-Member `
      -NotePropertyName $target `
      -NotePropertyValue (
        Get-FontQualificationSha256 ([IO.File]::ReadAllBytes($path))
      )
  }
  $comparison = [pscustomobject][ordered]@{
    schema_version = $EvidenceSchemaVersion
    workflow_id = $EvidenceWorkflowId
    normalization_removed = @($NormalizationRemoved)
    targets = @($Targets)
    record_sha256 = $recordHashes
    semantic_sha256 = Get-FontQualificationSha256 (
      $Utf8NoBom.GetBytes($canonical[0])
    )
    equal = $true
  }
  [void](Write-FontQualificationEvidenceJson `
    $Directory $ManagedRoot 'comparison.json' $comparison)
  $readBack = Get-Content -Raw -LiteralPath (
    Join-Path $Directory 'comparison.json'
  ) | ConvertFrom-Json -Depth 100
  Assert-FontQualificationComparisonRecord $readBack $Directory $ManagedRoot
  return $readBack
}

function Confirm-FontQualificationEvidenceRejected {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][scriptblock]$Action,
    [Parameter(Mandatory)][string]$ExpectedPattern
  )

  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure -or $failure -cnotmatch $ExpectedPattern) {
    throw "Font evidence accepted negative probe '$Name': '$failure'."
  }
}

function New-FontQualificationContractRunner {
  param(
    [Parameter(Mandatory)][string]$Target,
    [ValidateSet('full','tracer')][string]$Mode = 'full'
  )

  $assertions = if ($Mode -ceq 'tracer') {
    @($PublicEvidenceAssertions[0]) + @($PrivateFocusedAssertions)
  } else {
    @($FocusedAssertions)
  }
  $results = @(
    $assertions | ForEach-Object {
      [pscustomobject][ordered]@{
        kind = [string]$_.kind
        module = [string]$_.module
        file = [string]$_.file
        name = [string]$_.name
        command = "moon test $($_.file) -f '$($_.name)' --target $Target --frozen"
        passed = $true
        pass_total = 1
      }
    }
  )
  return New-FontQualificationRunnerFact `
    $Target $Mode $results `
    "moon test modules/mb-font/font --target $Target --frozen" `
    1 `
    'Total tests: 1, passed: 1, failed: 0.'
}

function Invoke-FontQualificationContractNegatives {
  $record = New-FontQualificationEvidenceRecord `
    'native' `
    (Get-FontQualificationExpectedToolchain) `
    (New-FontQualificationContractRunner 'native')
  Assert-FontQualificationEvidenceRecord $record
  $probes = @(
    @{ Name = 'schema'; Path = 'schema_version'; Value = '2.0.0' },
    @{ Name = 'workflow'; Path = 'workflow_id'; Value = 'font-complete-public-v2' },
    @{ Name = 'fixture digest'; Path = 'fixtures.canonical_corpus.sha256'; Value = '00' },
    @{ Name = 'oracle lock'; Path = 'oracle_facts.invoked_identities_sha256'; Value = '00' },
    @{ Name = 'generated fact'; Path = 'generated_cff_facts.expected_facts.0.id'; Value = 'drift' },
    @{ Name = 'licensed profile'; Path = 'licensed_cff_facts.source_han.profile.high_gid_fd'; Value = 0 },
    @{ Name = 'public workflow'; Path = 'public_workflow_facts.workflow_ids.0'; Value = 'drift' },
    @{ Name = 'hostile error'; Path = 'cff_hostile_outcomes.groups.0.rows.0.code'; Value = 'drift' },
    @{ Name = 'hostile gid'; Path = 'cff_hostile_outcomes.groups.0.rows.0.gid'; Value = 999 },
    @{ Name = 'hostile publication'; Path = 'cff_hostile_outcomes.groups.0.rows.0.publication'; Value = 'drift' },
    @{ Name = 'hostile B8'; Path = 'cff_hostile_outcomes.groups.0.rows.0.caller_after.7'; Value = 999 },
    @{ Name = 'mutation'; Path = 'mutation_atomicity_facts.mutation_rows.0.context'; Value = 'drift' },
    @{ Name = 'glyf'; Path = 'glyf_compatibility_facts.lock_ids.0'; Value = 'drift' },
    @{ Name = 'workload'; Path = 'benchmark_correctness_facts.workloads.0.correctness_input_sha256'; Value = '00' },
    @{ Name = 'API'; Path = 'boundary_facts.semantic_interface_count'; Value = 86 },
    @{ Name = 'production import'; Path = 'dependency_facts.production.package_imports.0'; Value = 'other' },
    @{ Name = 'evidence import'; Path = 'dependency_facts.evidence_module.test_only_mb_core_imports.0'; Value = 'other' },
    @{ Name = 'source'; Path = 'source_identities.production.0.sha256'; Value = '00' },
    @{ Name = 'assertion'; Path = 'focused_assertions.0.name'; Value = 'drift' },
    @{ Name = 'pass'; Path = 'pass'; Value = $false }
  )
  foreach ($probe in $probes) {
    Confirm-FontQualificationEvidenceRejected $probe.Name {
      $copy = ConvertTo-FontQualificationJson $record -Compress |
        ConvertFrom-Json -Depth 100
      $segments = [string]$probe.Path -split '[.]'
      $owner = $copy
      for ($index = 0; $index -lt $segments.Count - 1; $index++) {
        $segment = $segments[$index]
        if ($segment -cmatch '^\d+$') {
          $owner = $owner[[int]$segment]
        } else {
          $owner = $owner.$segment
        }
      }
      $leaf = $segments[-1]
      if ($leaf -cmatch '^\d+$') {
        $owner[[int]$leaf] = $probe.Value
      } else {
        $owner.$leaf = $probe.Value
      }
      Assert-FontQualificationEvidenceRecord $copy
    } 'drifted'
  }
  Confirm-FontQualificationEvidenceRejected 'top-level extra key' {
    $copy = ConvertTo-FontQualificationJson $record -Compress |
      ConvertFrom-Json -Depth 100
    $copy | Add-Member unexpected $true
    Assert-FontQualificationEvidenceRecord $copy
  } 'keys or order drifted'
  Confirm-FontQualificationEvidenceRejected 'top-level key order' {
    $copy = [pscustomobject][ordered]@{}
    foreach ($key in @($RecordKeys[1], $RecordKeys[0]) + $RecordKeys[2..17]) {
      $copy | Add-Member -NotePropertyName $key -NotePropertyValue $record.$key
    }
    Assert-FontQualificationEvidenceRecord $copy
  } 'keys or order drifted'
  Write-Host (
    'PASS: FontQualification v3 closed contract and one-field negatives'
  )
}

function Invoke-FontQualificationMoon {
  param([Parameter(Mandatory)][string[]]$Arguments)

  $moon = (Get-Command moon -ErrorAction Stop).Source
  $info = [Diagnostics.ProcessStartInfo]::new()
  $info.FileName = $moon
  $info.UseShellExecute = $false
  $info.RedirectStandardOutput = $true
  $info.RedirectStandardError = $true
  $info.CreateNoWindow = $true
  foreach ($argument in $Arguments) {
    [void]$info.ArgumentList.Add($argument)
  }
  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $info
  [void]$process.Start()
  $stdout = $process.StandardOutput.ReadToEndAsync()
  $stderr = $process.StandardError.ReadToEndAsync()
  if (-not $process.WaitForExit(900000)) {
    $process.Kill($true)
    $process.WaitForExit()
    throw 'Font qualification MoonBit command timed out.'
  }
  $stdoutText = $stdout.GetAwaiter().GetResult()
  $stderrText = $stderr.GetAwaiter().GetResult()
  if ($stdoutText) { Write-Host $stdoutText.TrimEnd() }
  if ($stderrText) { Write-Host $stderrText.TrimEnd() }
  return [pscustomobject]@{
    exit_code = $process.ExitCode
    lines = @(
      (($stdoutText + "`n" + $stderrText) -split "`r?`n") |
        Where-Object { $_ -ne '' }
    )
  }
}

function Remove-FontQualificationTempRoot {
  param([Parameter(Mandatory)][string]$Path)

  $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
  )
  $full = [IO.Path]::GetFullPath($Path)
  $leaf = Split-Path -Leaf $full
  if (-not $full.StartsWith(
        $tempRoot + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
      ) -or
      -not $leaf.StartsWith(
        'mnf-font-qualification-v3-',
        [StringComparison]::Ordinal
      )) {
    throw "Refusing to remove unowned qualification workspace '$full'."
  }
  if (Test-Path -LiteralPath $full) {
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}

function Invoke-FontQualificationTarget {
  param(
    [Parameter(Mandatory)][string]$Target,
    [switch]$TracerOnly
  )

  $members = @(
    [IO.Path]::GetFullPath((Join-Path $RepositoryRoot 'modules/mb-core')),
    [IO.Path]::GetFullPath((Join-Path $RepositoryRoot 'modules/mb-font')),
    [IO.Path]::GetFullPath((Join-Path $RepositoryRoot 'benchmarks/font-cff'))
  )
  foreach ($member in $members) {
    if (-not (Test-Path -LiteralPath $member -PathType Container)) {
      throw "Tracked workspace member is missing: '$member'."
    }
    $item = Get-Item -Force -LiteralPath $member
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
      throw "Tracked workspace member must not be a link: '$member'."
    }
  }
  $tempRoot = Join-Path ([IO.Path]::GetTempPath()) (
    'mnf-font-qualification-v3-' + $Target + '-' +
    [Guid]::NewGuid().ToString('N')
  )
  $recordValidated = $false
  try {
    [void](New-Item -ItemType Directory -Path $tempRoot)
    [void](New-Item -ItemType Directory -Path (Join-Path $tempRoot '.repos'))
    $targetRoot = Join-Path $tempRoot 'target'
    $workspaceText = (
      "members = [`n" +
      (($members | ForEach-Object {
        '  "' + $_.Replace('\', '/') + '",'
      }) -join "`n") +
      "`n]`n"
    )
    [IO.File]::WriteAllText(
      (Join-Path $tempRoot 'moon.work'),
      $workspaceText,
      $Utf8NoBom
    )
    $check = Invoke-FontQualificationMoon @(
      '-C', $tempRoot,
      'check', $members[2],
      '--target', $Target,
      '--frozen',
      '--target-dir', $targetRoot,
      '--serial'
    )
    if ($check.exit_code -ne 0) {
      throw "CFF evidence check failed for $Target."
    }
    $assertions = if ($TracerOnly) {
      @($PublicEvidenceAssertions[0]) + @($PrivateFocusedAssertions)
    } else {
      @($FocusedAssertions)
    }
    $focusedResults = @(
      foreach ($assertion in $assertions) {
        $root = if ($assertion.kind -ceq 'public') {
          $members[2]
        } else {
          $members[1]
        }
        $testPath = Join-Path $root $assertion.file
        $command = (
          "moon test $($assertion.module)/$($assertion.file) " +
          "-f '$($assertion.name)' --target $Target --frozen " +
          '--no-parallelize'
        )
        $result = Invoke-FontQualificationMoon @(
          '-C', $tempRoot,
          'test', $testPath,
          '-f', $assertion.name,
          '--target', $Target,
          '--frozen',
          '--target-dir', $targetRoot,
          '--no-parallelize'
        )
        if ($result.exit_code -ne 0) {
          throw "Focused assertion '$($assertion.name)' failed for $Target."
        }
        $summaries = @($result.lines | Where-Object { $_ -ceq $FocusedPassSummary })
        if ($summaries.Count -ne 1) {
          throw "Focused assertion '$($assertion.name)' did not pass exactly once."
        }
        [pscustomobject][ordered]@{
          kind = [string]$assertion.kind
          module = [string]$assertion.module
          file = [string]$assertion.file
          name = [string]$assertion.name
          command = $command
          passed = $true
          pass_total = 1
        }
      }
    )
    $fullPackageCommand = (
      "moon test modules/mb-font/font --target $Target --frozen " +
      '--no-parallelize'
    )
    $full = Invoke-FontQualificationMoon @(
      '-C', $tempRoot,
      'test', (Join-Path $members[1] 'font'),
      '--target', $Target,
      '--frozen',
      '--target-dir', $targetRoot,
      '--no-parallelize'
    )
    if ($full.exit_code -ne 0) {
      throw "Complete mb-font suite failed for $Target."
    }
    $fullSummaries = @(
      $full.lines |
        Where-Object {
          $_ -cmatch '^Total tests: \d+, passed: \d+, failed: \d+\.$'
        }
    )
    if ($fullSummaries.Count -ne 1) {
      throw "Complete mb-font suite summary drifted for $Target."
    }
    $match = [regex]::Match(
      $fullSummaries[0],
      '^Total tests: (?<total>\d+), passed: (?<passed>\d+), failed: (?<failed>\d+)\.$'
    )
    $total = [int]$match.Groups['total'].Value
    $passed = [int]$match.Groups['passed'].Value
    $failed = [int]$match.Groups['failed'].Value
    if ($total -lt 1 -or $passed -ne $total -or $failed -ne 0) {
      throw "Complete mb-font suite did not pass its discovered total for $Target."
    }
    if (@(Get-ChildItem -LiteralPath (Join-Path $tempRoot '.repos') -Force).Count -ne 0) {
      throw "Frozen local resolution populated the empty cache for $Target."
    }
    $mode = if ($TracerOnly) { 'tracer' } else { 'full' }
    $runner = New-FontQualificationRunnerFact `
      $Target $mode $focusedResults $fullPackageCommand $passed $fullSummaries[0]
    $record = New-FontQualificationEvidenceRecord `
      $Target (Get-FontQualificationToolchain) $runner
    Assert-FontQualificationEvidenceRecord $record
    $recordValidated = $true
    return $record
  } finally {
    if ($recordValidated) {
      Remove-FontQualificationTempRoot $tempRoot
    } elseif (Test-Path -LiteralPath $tempRoot) {
      Write-Warning "Preserved failed qualification workspace for inspection: $tempRoot"
    }
  }
}

function Invoke-FontQualification {
  [CmdletBinding()]
  param(
    [string]$EvidenceDirectory = 'artifacts/release-qualification/font-v3',
    [switch]$ContractOnly,
    [ValidateSet('js', 'wasm', 'wasm-gc', 'native')]
    [string]$Target,
    [switch]$TracerOnly
  )

  Push-Location $RepositoryRoot
  try {
    if ($ContractOnly) {
      Invoke-FontQualificationContractNegatives
      return
    }
    & ./scripts/fixtures/Generate-FontQualification.ps1 -Check
    if (-not $?) {
      throw 'Font qualification generator check failed.'
    }
    if (-not $TracerOnly) {
      . ./scripts/quality/Assert-Policy.ps1
      Assert-FontFoundationPolicy -PolicyPath ./policy/foundation.json
    }
    $managedRoot = [IO.Path]::GetFullPath(
      (Join-Path $RepositoryRoot 'artifacts/release-qualification')
    )
    $resolved = Resolve-FontQualificationEvidencePath `
      $EvidenceDirectory $managedRoot $RepositoryRoot
    Initialize-FontQualificationEvidenceDirectory $resolved $managedRoot
    Clear-FontQualificationEvidenceFiles $resolved $managedRoot
    $selectedTargets = if ([string]::IsNullOrWhiteSpace($Target)) {
      @($Targets)
    } else {
      @($Target)
    }
    if (-not $TracerOnly -and $selectedTargets.Count -ne 4) {
      throw 'A complete v3 run requires exactly the four literal targets.'
    }
    $records = @(
      foreach ($selectedTarget in $selectedTargets) {
        $record = Invoke-FontQualificationTarget `
          $selectedTarget -TracerOnly:$TracerOnly
        Assert-FontQualificationEvidenceRecord $record
        $path = Write-FontQualificationEvidenceJson `
          $resolved $managedRoot "$selectedTarget.json" $record
        $readBack = Get-Content -Raw -LiteralPath $path |
          ConvertFrom-Json -Depth 100
        Assert-FontQualificationEvidenceRecord $readBack
        $readBack
      }
    )
    Invoke-FontQualificationContractNegatives
    if ($records.Count -eq 4) {
      $comparison = Compare-FontQualificationEvidence `
        $records $resolved $managedRoot
      Write-Host (
        "Font qualification v3 passed: targets=4, records=4, " +
        "normalization=target,runner, semantic-sha256=$($comparison.semantic_sha256)."
      )
    } else {
      Write-Host (
        "Font qualification v3 tracer passed: target=$($records[0].target), " +
        "record=$($records[0].target).json."
      )
    }
  } finally {
    Pop-Location
  }
}

if (-not $ImportOnly -and $MyInvocation.InvocationName -cne '.') {
  $invokeArguments = @{
    EvidenceDirectory = $EvidenceDirectory
    ContractOnly = [bool]$ContractOnly
    TracerOnly = [bool]$TracerOnly
  }
  if (-not [string]::IsNullOrWhiteSpace($Target)) {
    $invokeArguments.Target = $Target
  }
  Invoke-FontQualification @invokeArguments
}
