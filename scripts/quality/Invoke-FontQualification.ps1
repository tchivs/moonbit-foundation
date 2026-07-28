[CmdletBinding(DefaultParameterSetName = 'Run')]
param(
  [Parameter(ParameterSetName = 'Run')]
  [string]$EvidenceDirectory = 'artifacts/release-qualification/font-v2',
  [Parameter(Mandatory, ParameterSetName = 'Import')]
  [switch]$ImportOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Utf8NoBom = [Text.UTF8Encoding]::new($false)
$Targets = @('js', 'wasm', 'wasm-gc', 'native')
$EvidenceWorkflowId = 'font-complete-public-v2'
$EvidenceSchemaVersion = '2.0.0'
$FocusedPassSummary = 'Total tests: 1, passed: 1, failed: 0.'
$SupportedOutlineScalars = @('U+0041', 'U+034C', 'U+10300')
$EvidenceMarkerName = '.mnf-font-qualification-managed.json'
$EvidenceMarkerSchema = 'mnf-font-qualification-evidence/v2'
$RecordKeys = @(
  'schema_version',
  'workflow_id',
  'target',
  'toolchain',
  'fixtures',
  'standalone_baseline',
  'generated_collection_facts',
  'licensed_derivative_facts',
  'collection_hostile_outcomes',
  'mutation_atomicity_facts',
  'boundary_facts',
  'dependency_facts',
  'focused_assertions',
  'runner',
  'pass'
)
$FocusedAssertions = @(
  [pscustomobject][ordered]@{
    group = 'standalone'
    file = 'font/font_qualification_test.mbt'
    name = 'font-complete-public freezes compact public workflow facts'
  },
  [pscustomobject][ordered]@{
    group = 'standalone'
    file = 'font/font_qualification_test.mbt'
    name = 'font-complete-public exercises the compact format-4 branch'
  },
  [pscustomobject][ordered]@{
    group = 'standalone'
    file = 'font/font_qualification_test.mbt'
    name = 'font-complete-public freezes DejaVu Sans 2.37 public facts'
  },
  [pscustomobject][ordered]@{
    group = 'standalone-hostile'
    file = 'font/font_qualification_hostile_test.mbt'
    name = 'font qualification executes the closed hostile outcome matrix'
  },
  [pscustomobject][ordered]@{
    group = 'standalone-capability'
    file = 'font/font_test.mbt'
    name = 'unsupported containers outlines variations color and bitmap profiles are capabilities'
  },
  [pscustomobject][ordered]@{
    group = 'generated-collection'
    file = 'font/font_qualification_test.mbt'
    name = 'font-complete-public qualifies generated collection workflows'
  },
  [pscustomobject][ordered]@{
    group = 'licensed-collection'
    file = 'font/font_qualification_test.mbt'
    name = 'font-complete-public qualifies licensed DejaVu collection faces'
  },
  [pscustomobject][ordered]@{
    group = 'collection-hostile'
    file = 'font/font_qualification_hostile_test.mbt'
    name = 'font qualification executes the closed collection hostile outcome matrix'
  },
  [pscustomobject][ordered]@{
    group = 'public-mutation'
    file = 'font/font_qualification_hostile_test.mbt'
    name = 'font qualification preserves public collection mutation atomicity'
  },
  [pscustomobject][ordered]@{
    group = 'private-collection-mutation'
    file = 'font/collection_wbtest.mbt'
    name = 'collection qualification preserves mid-operation mutation atomicity'
  },
  [pscustomobject][ordered]@{
    group = 'inherited-query-mutation'
    file = 'font/font_wbtest.mbt'
    name = 'glyph_for_scalar rejects post-read revision drift'
  },
  [pscustomobject][ordered]@{
    group = 'inherited-query-mutation'
    file = 'font/font_wbtest.mbt'
    name = 'kerning rejects post-read revision drift'
  },
  [pscustomobject][ordered]@{
    group = 'inherited-query-mutation'
    file = 'font/font_wbtest.mbt'
    name = 'outline rejects post-decode revision drift without path publication'
  },
  [pscustomobject][ordered]@{
    group = 'inherited-query-mutation'
    file = 'font/font_wbtest.mbt'
    name = 'composite outline rejects post-decode revision drift without publication'
  }
)
$HostileOutcomeIds = @(
  'malformed-directory-range',
  'unsupported-outline-profile',
  'mutation-after-open',
  'checked-range-overflow',
  'limit-source-exact',
  'limit-source-one-short',
  'budget-open-exact',
  'budget-open-one-short',
  'budget-outline-exact',
  'budget-outline-one-short',
  'nested-composite-recognized'
)

function Get-FontQualificationSha256 {
  param([Parameter(Mandatory)][byte[]]$Bytes)

  return [Convert]::ToHexString(
    [Security.Cryptography.SHA256]::HashData($Bytes)
  ).ToLowerInvariant()
}

function Get-FontQualificationFileFact {
  param([Parameter(Mandatory)][string]$Path)

  $resolved = (Resolve-Path -LiteralPath $Path).Path
  $bytes = [IO.File]::ReadAllBytes($resolved)
  return [pscustomobject][ordered]@{
    path = [IO.Path]::GetRelativePath($RepositoryRoot, $resolved).Replace('\', '/')
    length = $bytes.Length
    sha256 = Get-FontQualificationSha256 $bytes
  }
}

function ConvertTo-FontQualificationJson {
  param(
    [Parameter(Mandatory)]$Value,
    [switch]$Compress
  )

  $json = if ($Compress) {
    $Value | ConvertTo-Json -Depth 32 -Compress
  } else {
    $Value | ConvertTo-Json -Depth 32
  }
  return $json.Replace("`r`n", "`n")
}

function Write-FontQualificationJson {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)]$Value
  )

  $json = (ConvertTo-FontQualificationJson $Value) + "`n"
  [IO.File]::WriteAllText($Path, $json, $Utf8NoBom)
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
    if ($null -eq $item) {
      break
    }
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
  Assert-FontQualificationEvidencePathHasNoLinks `
    -Directory $candidate `
    -ManagedRoot $canonicalRoot
  return $candidate
}

function Assert-FontQualificationEvidenceMarker {
  param([Parameter(Mandatory)][string]$Directory)

  $markerPath = Join-Path $Directory $EvidenceMarkerName
  if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) {
    throw "Managed font qualification evidence marker is missing from '$Directory'."
  }
  try {
    $marker = Get-Content -Raw -LiteralPath $markerPath | ConvertFrom-Json
  } catch {
    throw "Managed font qualification evidence marker is invalid in '$Directory'."
  }
  $keys = @($marker.PSObject.Properties.Name)
  if ($keys.Count -ne 2 -or
      $keys[0] -cne 'schema' -or
      $keys[1] -cne 'workflow_id' -or
      $marker.schema -cne $EvidenceMarkerSchema -or
      $marker.workflow_id -cne $EvidenceWorkflowId) {
    throw "Managed font qualification evidence marker is invalid in '$Directory'."
  }
}

function Initialize-FontQualificationEvidenceDirectory {
  param(
    [Parameter(Mandatory)][string]$Directory,
    [Parameter(Mandatory)][string]$ManagedRoot
  )

  Assert-FontQualificationEvidencePathHasNoLinks `
    -Directory $Directory `
    -ManagedRoot $ManagedRoot
  if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $Directory)
  }
  Assert-FontQualificationEvidencePathHasNoLinks `
    -Directory $Directory `
    -ManagedRoot $ManagedRoot
  $markerPath = Join-Path $Directory $EvidenceMarkerName
  if (Test-Path -LiteralPath $markerPath) {
    Assert-FontQualificationEvidencePathHasNoLinks `
      -Directory $Directory `
      -ManagedRoot $ManagedRoot
    Assert-FontQualificationEvidenceMarker $Directory
    return
  }
  if (@(Get-ChildItem -LiteralPath $Directory -Force).Count -ne 0) {
    throw (
      "Refusing non-empty unowned font qualification evidence directory '$Directory'."
    )
  }
  Assert-FontQualificationEvidencePathHasNoLinks `
    -Directory $Directory `
    -ManagedRoot $ManagedRoot
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

  Assert-FontQualificationEvidencePathHasNoLinks `
    -Directory $Directory `
    -ManagedRoot $ManagedRoot
  Assert-FontQualificationEvidenceMarker $Directory
  foreach ($evidenceName in @($Targets | ForEach-Object { "$_.json" }) + 'comparison.json') {
    Assert-FontQualificationEvidencePathHasNoLinks `
      -Directory $Directory `
      -ManagedRoot $ManagedRoot
    $staleEvidence = Join-Path $Directory $evidenceName
    if (Test-Path -LiteralPath $staleEvidence -PathType Leaf) {
      Remove-Item -LiteralPath $staleEvidence -Force
    }
  }
}

function Assert-FontQualificationClosedKeys {
  param(
    [Parameter(Mandatory)]$Value,
    [Parameter(Mandatory)][string[]]$Expected,
    [Parameter(Mandatory)][string]$Label
  )

  $actual = @($Value.PSObject.Properties.Name)
  if ($actual.Count -ne $Expected.Count) {
    throw "$Label key count drifted."
  }
  for ($index = 0; $index -lt $Expected.Count; $index++) {
    if ($actual[$index] -cne $Expected[$index]) {
      throw "$Label key order drifted at ${index}: expected $($Expected[$index]), got $($actual[$index])."
    }
  }
}

function Assert-FontQualificationCaseFact {
  param(
    [Parameter(Mandatory)]$Case,
    [Parameter(Mandatory)][string]$Label
  )

  Assert-FontQualificationClosedKeys $Case @(
    'id',
    'fixture_id',
    'stage',
    'entrypoint',
    'face_index',
    'mutation_window',
    'authority',
    'boundary',
    'error',
    'publication',
    'budget_before',
    'budget_after'
  ) $Label
  Assert-FontQualificationClosedKeys $Case.error @(
    'category',
    'code',
    'operation',
    'context',
    'source_offset',
    'requested',
    'limit'
  ) "$Label error"
  foreach ($budgetName in @('budget_before', 'budget_after')) {
    Assert-FontQualificationClosedKeys $Case.$budgetName @(
      'bytes',
      'allocations',
      'allocation_size',
      'width',
      'height',
      'pixels',
      'depth',
      'work'
    ) "$Label $budgetName"
  }
  if ($Case.boundary -cnotin @('success', 'failure') -or
      $Case.publication -cnotin @('none', 'collection', 'font')) {
    throw "$Label enum drifted."
  }
}

function Assert-FontQualificationEvidenceRecord {
  param([Parameter(Mandatory)]$Record)

  Assert-FontQualificationClosedKeys $Record $RecordKeys "$($Record.target) record"
  Assert-FontQualificationClosedKeys $Record.toolchain @('moon','moonc','moonrun') "$($Record.target) toolchain"
  Assert-FontQualificationClosedKeys $Record.fixtures @(
    'dejavu_sans_237',
    'dejavu_license',
    'independent_oracle',
    'hostile_cases',
    'collection_cases',
    'licensed_derivative',
    'collection_oracle',
    'generated_source',
    'workflow_test',
    'hostile_test'
  ) "$($Record.target) fixtures"
  foreach ($fixture in $Record.fixtures.PSObject.Properties) {
    Assert-FontQualificationClosedKeys $fixture.Value @('path','length','sha256') "$($Record.target) fixture $($fixture.Name)"
  }
  Assert-FontQualificationClosedKeys $Record.standalone_baseline @(
    'public_facts',
    'hostile_outcomes',
    'capability_assertion'
  ) "$($Record.target) standalone baseline"
  Assert-FontQualificationClosedKeys $Record.standalone_baseline.public_facts @(
    'compact',
    'dejavu_sans_237'
  ) "$($Record.target) standalone public facts"
  if (@($Record.standalone_baseline.hostile_outcomes).Count -ne $HostileOutcomeIds.Count) {
    throw "$($Record.target) standalone hostile outcome count drifted."
  }
  for ($index = 0; $index -lt $HostileOutcomeIds.Count; $index++) {
    $outcome = $Record.standalone_baseline.hostile_outcomes[$index]
    Assert-FontQualificationClosedKeys $outcome @(
      'id',
      'stage',
      'category',
      'code',
      'context',
      'requested',
      'limit',
      'publication'
    ) "$($Record.target) standalone hostile outcome $index"
    if ($outcome.id -cne $HostileOutcomeIds[$index]) {
      throw "$($Record.target) standalone hostile outcome ID drifted at index $index."
    }
  }
  if ($Record.standalone_baseline.capability_assertion -cne
      'unsupported containers outlines variations color and bitmap profiles are capabilities') {
    throw "$($Record.target) standalone capability assertion drifted."
  }
  Assert-FontQualificationClosedKeys $Record.generated_collection_facts @(
    'corpus_schema_version',
    'corpus_workflow_id',
    'corpus_sha256',
    'fixture_ids',
    'public_workflow_ids'
  ) "$($Record.target) generated collection facts"
  if ($Record.generated_collection_facts.corpus_schema_version -cne '1.0.0' -or
      $Record.generated_collection_facts.corpus_workflow_id -cne
        'font-collection-complete-public-v2' -or
      @($Record.generated_collection_facts.fixture_ids).Count -ne 6 -or
      @($Record.generated_collection_facts.public_workflow_ids).Count -ne 6) {
    throw "$($Record.target) generated collection contract drifted."
  }
  Assert-FontQualificationClosedKeys $Record.licensed_derivative_facts @(
    'path',
    'length',
    'sha256',
    'face_count',
    'face_offsets',
    'payload_start',
    'shared_table_count',
    'shared_table_coordinates',
    'profiles',
    'standalone_oracle_sha256',
    'both_faces_equal_standalone'
  ) "$($Record.target) licensed derivative facts"
  if ([int64]$Record.licensed_derivative_facts.length -ne 757428 -or
      $Record.licensed_derivative_facts.sha256 -cne
        '833d406d389d4ef3b0a38f168af7d51ca16c88605e1727f6d631871a4e05f80b' -or
      [int]$Record.licensed_derivative_facts.face_count -ne 2 -or
      [int]$Record.licensed_derivative_facts.shared_table_count -ne 20 -or
      $Record.licensed_derivative_facts.both_faces_equal_standalone -ne $true) {
    throw "$($Record.target) licensed derivative identity or sharing drifted."
  }
  Assert-FontQualificationClosedKeys $Record.collection_hostile_outcomes @(
    'hostile',
    'limits',
    'budgets'
  ) "$($Record.target) collection hostile outcomes"
  foreach ($groupName in @('hostile', 'limits', 'budgets')) {
    foreach ($case in @($Record.collection_hostile_outcomes.$groupName)) {
      Assert-FontQualificationCaseFact $case "$($Record.target) $groupName case"
    }
  }
  if (@($Record.collection_hostile_outcomes.hostile).Count -ne 24 -or
      @($Record.collection_hostile_outcomes.limits).Count -ne 44 -or
      @($Record.collection_hostile_outcomes.budgets).Count -ne 12) {
    throw "$($Record.target) collection hostile/limit/budget counts drifted."
  }
  Assert-FontQualificationClosedKeys $Record.mutation_atomicity_facts @(
    'cases',
    'public_assertion',
    'private_collection_assertion',
    'inherited_query_assertions'
  ) "$($Record.target) mutation atomicity facts"
  foreach ($case in @($Record.mutation_atomicity_facts.cases)) {
    Assert-FontQualificationCaseFact $case "$($Record.target) mutation case"
  }
  if (@($Record.mutation_atomicity_facts.cases).Count -ne 9 -or
      @($Record.mutation_atomicity_facts.inherited_query_assertions).Count -ne 4) {
    throw "$($Record.target) mutation atomicity contract drifted."
  }
  Assert-FontQualificationClosedKeys $Record.boundary_facts @(
    'semantic_interface',
    'semantic_interface_count',
    'production_sources',
    'production_source_count',
    'container_capabilities',
    'no_ffi',
    'no_ambient_io'
  ) "$($Record.target) boundary facts"
  Assert-FontQualificationClosedKeys $Record.boundary_facts.container_capabilities @(
    'woff1',
    'woff2',
    'otto',
    'cff',
    'cff2',
    'variable',
    'dsig'
  ) "$($Record.target) container capabilities"
  if ([int]$Record.boundary_facts.semantic_interface_count -ne 85 -or
      @($Record.boundary_facts.semantic_interface).Count -ne 85 -or
      [int]$Record.boundary_facts.production_source_count -ne 13 -or
      @($Record.boundary_facts.production_sources).Count -ne 13 -or
      $Record.boundary_facts.no_ffi -ne $true -or
      $Record.boundary_facts.no_ambient_io -ne $true -or
      $Record.boundary_facts.container_capabilities.woff1 -cne 'CapabilityUnavailable' -or
      $Record.boundary_facts.container_capabilities.woff2 -cne 'CapabilityUnavailable' -or
      $Record.boundary_facts.container_capabilities.otto -cne 'CapabilityUnavailable' -or
      $Record.boundary_facts.container_capabilities.cff -cne 'inspect-only' -or
      $Record.boundary_facts.container_capabilities.cff2 -cne 'inspect-only' -or
      $Record.boundary_facts.container_capabilities.variable -cne 'inspect-only' -or
      $Record.boundary_facts.container_capabilities.dsig -cne 'present-unverified') {
    throw "$($Record.target) API/source/capability boundary drifted."
  }
  Assert-FontQualificationClosedKeys $Record.dependency_facts @(
    'module_name',
    'module_version',
    'module_dependencies',
    'package_imports',
    'supported_targets'
  ) "$($Record.target) dependency facts"
  if ($Record.dependency_facts.module_name -cne 'tchivs/mb-font' -or
      @($Record.dependency_facts.module_dependencies).Count -ne 1 -or
      $Record.dependency_facts.module_dependencies[0].name -cne 'tchivs/mb-core' -or
      $Record.dependency_facts.supported_targets -cne '+js+wasm+wasm-gc+native') {
    throw "$($Record.target) dependency evidence drifted."
  }
  $expectedImports = @(
    'tchivs/mb-core/budget',
    'tchivs/mb-core/bytes',
    'tchivs/mb-core/checked',
    'tchivs/mb-core/error',
    'tchivs/mb-core/math'
  )
  if ((Compare-Object $expectedImports @($Record.dependency_facts.package_imports))) {
    throw "$($Record.target) package-import evidence drifted."
  }
  $focused = @($Record.focused_assertions)
  if ($focused.Count -ne $FocusedAssertions.Count) {
    throw "$($Record.target) focused assertion count drifted."
  }
  for ($index = 0; $index -lt $FocusedAssertions.Count; $index++) {
    Assert-FontQualificationClosedKeys $focused[$index] @(
      'group',
      'file',
      'name'
    ) "$($Record.target) focused assertion $index"
    foreach ($key in @('group', 'file', 'name')) {
      if ([string]$focused[$index].$key -cne [string]$FocusedAssertions[$index].$key) {
        throw "$($Record.target) focused assertion identity/order drifted at $index."
      }
    }
  }
  Assert-FontQualificationClosedKeys $Record.runner @(
    'generator_command',
    'policy_command',
    'check_command',
    'focused_commands',
    'focused_gate_count',
    'full_package_command',
    'full_package_passed',
    'full_package_pass_total',
    'full_package_summary',
    'target_directory',
    'no_parallelize'
  ) "$($Record.target) runner"
  if ([int]$Record.runner.focused_gate_count -ne $FocusedAssertions.Count -or
      @($Record.runner.focused_commands).Count -ne $FocusedAssertions.Count -or
      $Record.runner.full_package_passed -ne $true -or
      [int]$Record.runner.full_package_pass_total -lt 1 -or
      $Record.runner.no_parallelize -ne $true -or
      $Record.runner.target_directory -cne
        "target/phase103-font-qualification-$($Record.target)") {
    throw "$($Record.target) runner result drifted."
  }
  foreach ($result in @($Record.runner.focused_commands)) {
    Assert-FontQualificationClosedKeys $result @(
      'group',
      'file',
      'name',
      'command',
      'passed',
      'pass_total'
    ) "$($Record.target) focused command"
    if ($result.passed -ne $true -or [int]$result.pass_total -ne 1 -or
        [string]$result.command -cnotmatch
          [regex]::Escape("--target $($Record.target)")) {
      throw "$($Record.target) focused command result drifted."
    }
  }
  if ($Record.schema_version -cne $EvidenceSchemaVersion -or
      $Record.workflow_id -cne $EvidenceWorkflowId -or
      $Targets -cnotcontains [string]$Record.target -or
      $Record.pass -ne $true) {
    throw "$($Record.target) qualification identity or pass state drifted."
  }
}

function Get-FontQualificationToolchain {
  $lines = @(& moon version --all)
  if ($LASTEXITCODE -ne 0 -or $lines.Count -lt 3) {
    throw 'Unable to capture the complete MoonBit toolchain identity.'
  }
  $moon = [regex]::Match($lines[0], '^moon \S+ \([^)]+\)').Value
  $moonc = [regex]::Match($lines[1], '^moonc \S+ \([^)]+\)').Value
  $moonrun = [regex]::Match($lines[2], '^moonrun \S+ \([^)]+\)').Value
  if (-not $moon -or -not $moonc -or -not $moonrun) {
    throw 'MoonBit toolchain identity format drifted.'
  }
  return [pscustomobject][ordered]@{
    moon = $moon
    moonc = $moonc
    moonrun = $moonrun
  }
}

function Get-FontQualificationGlyphFact {
  param(
    [Parameter(Mandatory)]$OracleGlyph,
    [switch]$SupportedOutline
  )

  $outline = if ($SupportedOutline) {
    $commands = @($OracleGlyph.path.commands)
    if ([int]$OracleGlyph.path.command_count -ne $commands.Count -or
        [string]::IsNullOrWhiteSpace([string]$OracleGlyph.path.fingerprint_sha256)) {
      throw "Independent oracle $($OracleGlyph.scalar) complete outline drifted."
    }
    [pscustomobject][ordered]@{
      status = 'path'
      command_count = [int]$OracleGlyph.path.command_count
      fingerprint_sha256 = [string]$OracleGlyph.path.fingerprint_sha256
      selected_commands = @($commands | Select-Object -First 8)
    }
  } else {
    [pscustomobject][ordered]@{
      status = 'capability'
      category = 'Capability'
      code = 'CapabilityUnavailable'
      context = 'font-outline-grid-rounding'
    }
  }
  return [pscustomobject][ordered]@{
    scalar = [string]$OracleGlyph.scalar
    glyph_id = [int]$OracleGlyph.glyph_id
    horizontal_metrics = [pscustomobject][ordered]@{
      advance = [int]$OracleGlyph.horizontal_metrics.advance
      lsb = [int]$OracleGlyph.horizontal_metrics.lsb
    }
    bounds = [pscustomobject][ordered]@{
      x_min = [int]$OracleGlyph.bounds.x_min
      y_min = [int]$OracleGlyph.bounds.y_min
      x_max = [int]$OracleGlyph.bounds.x_max
      y_max = [int]$OracleGlyph.bounds.y_max
    }
    outline = $outline
  }
}

function Get-FontQualificationPublicFacts {
  param([Parameter(Mandatory)]$Oracle)

  $glyphs = @{}
  foreach ($glyph in @($Oracle.glyphs)) {
    $glyphs[[string]$glyph.scalar] = $glyph
  }
  foreach ($scalar in @('U+0041', 'U+00E9', 'U+034C', 'U+10300')) {
    if (-not $glyphs.ContainsKey($scalar)) {
      throw "Independent oracle is missing public scalar $scalar."
    }
  }
  $supported = @(
    $Oracle.glyphs |
      Where-Object { $SupportedOutlineScalars -ccontains [string]$_.scalar }
  )
  if ($supported.Count -ne $SupportedOutlineScalars.Count -or
      (Compare-Object -CaseSensitive $SupportedOutlineScalars @($supported.scalar))) {
    throw 'Independent oracle supported complete-outline set drifted.'
  }
  foreach ($glyph in $supported) {
    $commands = @($glyph.path.commands)
    if ([int]$glyph.path.command_count -ne $commands.Count -or
        [string]::IsNullOrWhiteSpace([string]$glyph.path.fingerprint_sha256)) {
      throw "Independent oracle supported glyph $($glyph.scalar) vector/count drifted."
    }
    $actualFingerprint = Get-FontQualificationSha256 (
      $Utf8NoBom.GetBytes($commands -join '|')
    )
    if ($actualFingerprint -cne [string]$glyph.path.fingerprint_sha256) {
      throw "Independent oracle supported glyph $($glyph.scalar) fingerprint drifted."
    }
  }

  $compactSimple = @(
    'M:0,0',
    'Q:50,0:75,0',
    'Q:100,0:100,100',
    'L:0,100',
    'Z'
  )
  $compactComposite = @(
    'M:10,-4',
    'Q:35,-4:47.5,-4',
    'Q:60,-4:60,46',
    'L:10,46',
    'Z',
    'M:60,46',
    'Q:85,46:97.5,46',
    'Q:110,46:110,96',
    'L:60,96',
    'Z'
  )
  return [pscustomobject][ordered]@{
    compact = [pscustomobject][ordered]@{
      source_length = 580
      units_per_em = 1000
      mappings = @(
        [pscustomobject][ordered]@{ scalar = 'U+0041'; glyph_id = 1 },
        [pscustomobject][ordered]@{ scalar = 'U+10300'; glyph_id = 2 }
      )
      global_bounds = [pscustomobject][ordered]@{
        x_min = 0; y_min = 0; x_max = 0; y_max = 0
      }
      hhea = [pscustomobject][ordered]@{
        ascent = 0; descent = 0; line_gap = 0
      }
      typographic = [pscustomobject][ordered]@{
        ascent = 0; descent = 0; line_gap = 0
      }
      simple_path = [pscustomobject][ordered]@{
        command_count = $compactSimple.Count
        fingerprint_sha256 = Get-FontQualificationSha256 (
          $Utf8NoBom.GetBytes($compactSimple -join '|')
        )
        commands = $compactSimple
      }
      composite_path = [pscustomobject][ordered]@{
        command_count = $compactComposite.Count
        fingerprint_sha256 = Get-FontQualificationSha256 (
          $Utf8NoBom.GetBytes($compactComposite -join '|')
        )
        commands = $compactComposite
      }
      kerning = [pscustomobject][ordered]@{
        left_glyph = 1; right_glyph = 2; adjustment = -37
      }
      format4_lookup = [pscustomobject][ordered]@{
        scalar = 'U+0041'; glyph_id = 1
      }
    }
    dejavu_sans_237 = [pscustomobject][ordered]@{
      units_per_em = [int]$Oracle.profile.units_per_em
      global_bounds = [pscustomobject][ordered]@{
        x_min = [int]$Oracle.metrics.global_bounds.x_min
        y_min = [int]$Oracle.metrics.global_bounds.y_min
        x_max = [int]$Oracle.metrics.global_bounds.x_max
        y_max = [int]$Oracle.metrics.global_bounds.y_max
      }
      hhea = [pscustomobject][ordered]@{
        ascent = [int]$Oracle.metrics.hhea.ascent
        descent = [int]$Oracle.metrics.hhea.descent
        line_gap = [int]$Oracle.metrics.hhea.line_gap
      }
      typographic = [pscustomobject][ordered]@{
        ascent = [int]$Oracle.metrics.os2_typographic.ascent
        descent = [int]$Oracle.metrics.os2_typographic.descent
        line_gap = [int]$Oracle.metrics.os2_typographic.line_gap
      }
      glyphs = @(
        (Get-FontQualificationGlyphFact $glyphs['U+0041'] -SupportedOutline),
        (Get-FontQualificationGlyphFact $glyphs['U+00E9']),
        (Get-FontQualificationGlyphFact $glyphs['U+034C'] -SupportedOutline),
        (Get-FontQualificationGlyphFact $glyphs['U+10300'] -SupportedOutline)
      )
      kerning = [pscustomobject][ordered]@{
        left_glyph = [int]$Oracle.kern.selected_pair.left_glyph
        right_glyph = [int]$Oracle.kern.selected_pair.right_glyph
        adjustment = [int]$Oracle.kern.selected_pair.adjustment
      }
    }
  }
}

function Get-FontQualificationHostileOutcomes {
  param([Parameter(Mandatory)]$CasesDocument)

  $outcomes = @(
    foreach ($case in @($CasesDocument.cases)) {
      [pscustomobject][ordered]@{
        id = [string]$case.id
        stage = [string]$case.stage
        category = [string]$case.category
        code = [string]$case.code
        context = [string]$case.context
        requested = $case.requested
        limit = $case.limit
        publication = [string]$case.publication
      }
    }
  )
  if ($outcomes.Count -ne 11 -or (@($outcomes.id) | Select-Object -Unique).Count -ne 11) {
    throw 'Closed hostile qualification matrix is incomplete or duplicated.'
  }
  return $outcomes
}

function Get-FontQualificationDependencyFacts {
  $module = Get-Content -Raw -LiteralPath 'modules/mb-font/moon.mod.json' |
    ConvertFrom-Json
  $dependencyNames = @($module.deps.PSObject.Properties.Name)
  if ($dependencyNames.Count -ne 1 -or $dependencyNames[0] -cne 'tchivs/mb-core') {
    throw 'mb-font module dependency boundary drifted.'
  }
  $packageText = Get-Content -Raw -LiteralPath 'modules/mb-font/font/moon.pkg'
  $imports = @(
    [regex]::Matches($packageText, '"(tchivs/mb-core/[^"]+)"') |
      ForEach-Object { $_.Groups[1].Value }
  )
  $expectedImports = @(
    'tchivs/mb-core/budget',
    'tchivs/mb-core/bytes',
    'tchivs/mb-core/checked',
    'tchivs/mb-core/error',
    'tchivs/mb-core/math'
  )
  if ((Compare-Object $expectedImports $imports)) {
    throw 'mb-font package import boundary drifted.'
  }
  return [pscustomobject][ordered]@{
    module_name = [string]$module.name
    module_version = [string]$module.version
    module_dependencies = @(
      [pscustomobject][ordered]@{
        name = 'tchivs/mb-core'
        version = [string]$module.deps.'tchivs/mb-core'
      }
    )
    package_imports = $expectedImports
    supported_targets = [string]$module.'supported-targets'
  }
}

function Get-FontQualificationCollectionFacts {
  param(
    [Parameter(Mandatory)]$Corpus,
    [Parameter(Mandatory)]$CollectionOracle,
    [Parameter(Mandatory)]$Fixtures
  )

  $generatedFixtures = @(
    $Corpus.fixtures | Where-Object { $_.origin -ceq 'generated' }
  )
  $generatedWorkflows = @(
    $Corpus.public_workflows | Where-Object { $_.authority -ceq 'generated' }
  )
  $licensedFixture = $Fixtures.licensed_derivative
  $sharedCoordinates = @(
    $CollectionOracle.shared_tables | ForEach-Object {
      [pscustomobject][ordered]@{
        tag = [string]$_.tag
        root_offset = [int64]$_.root_offset
        length = [int64]$_.length
      }
    }
  )
  return [pscustomobject][ordered]@{
    generated = [pscustomobject][ordered]@{
      corpus_schema_version = [string]$Corpus.schema_version
      corpus_workflow_id = [string]$Corpus.workflow_id
      corpus_sha256 = [string]$Fixtures.collection_cases.sha256
      fixture_ids = @($generatedFixtures.id)
      public_workflow_ids = @($generatedWorkflows.id)
    }
    licensed = [pscustomobject][ordered]@{
      path = [string]$licensedFixture.path
      length = [int64]$licensedFixture.length
      sha256 = [string]$licensedFixture.sha256
      face_count = [int]$CollectionOracle.collection.face_count
      face_offsets = @($CollectionOracle.collection.face_offsets)
      payload_start = [int64]$CollectionOracle.collection.payload_start
      shared_table_count = $sharedCoordinates.Count
      shared_table_coordinates = $sharedCoordinates
      profiles = @($CollectionOracle.collection.profiles)
      standalone_oracle_sha256 = [string](
        $CollectionOracle.standalone_oracle_binding.sha256
      )
      both_faces_equal_standalone = (
        @($CollectionOracle.standalone_oracle_binding.face_indices).Count -eq 2
      )
    }
    hostile = [pscustomobject][ordered]@{
      hostile = @($Corpus.hostile_cases)
      limits = @($Corpus.limit_cases)
      budgets = @($Corpus.budget_cases)
    }
    mutation = [pscustomobject][ordered]@{
      cases = @($Corpus.mutation_cases)
      public_assertion = 'font qualification preserves public collection mutation atomicity'
      private_collection_assertion = 'collection qualification preserves mid-operation mutation atomicity'
      inherited_query_assertions = @(
        $FocusedAssertions |
          Where-Object { $_.group -ceq 'inherited-query-mutation' } |
          ForEach-Object { $_.name }
      )
    }
  }
}

function Get-FontQualificationBoundaryFacts {
  $policy = Get-Content -Raw -LiteralPath 'policy/foundation.json' |
    ConvertFrom-Json
  $module = @(
    $policy.modules | Where-Object { $_.name -ceq 'tchivs/mb-font' }
  )
  if ($module.Count -ne 1) {
    throw 'Foundation policy must contain exactly one mb-font module.'
  }
  $package = @(
    $module[0].public_packages |
      Where-Object { $_.name -ceq 'tchivs/mb-font/font' }
  )
  if ($package.Count -ne 1) {
    throw 'Foundation policy must contain exactly one public mb-font package.'
  }
  return [pscustomobject][ordered]@{
    semantic_interface = @($package[0].semantic_interface)
    semantic_interface_count = @($package[0].semantic_interface).Count
    production_sources = @($package[0].production_sources)
    production_source_count = @($package[0].production_sources).Count
    container_capabilities = [pscustomobject][ordered]@{
      woff1 = 'CapabilityUnavailable'
      woff2 = 'CapabilityUnavailable'
      otto = 'CapabilityUnavailable'
      cff = 'inspect-only'
      cff2 = 'inspect-only'
      variable = 'inspect-only'
      dsig = 'present-unverified'
    }
    no_ffi = $true
    no_ambient_io = $true
  }
}

function New-FontQualificationEvidenceRecord {
  param(
    [Parameter(Mandatory)][string]$Target,
    [Parameter(Mandatory)]$Toolchain,
    [Parameter(Mandatory)]$Fixtures,
    [Parameter(Mandatory)]$PublicFacts,
    [Parameter(Mandatory)]$HostileOutcomes,
    [Parameter(Mandatory)]$CollectionFacts,
    [Parameter(Mandatory)]$BoundaryFacts,
    [Parameter(Mandatory)]$DependencyFacts,
    [Parameter(Mandatory)][string]$TargetDirectory,
    [Parameter(Mandatory)][object[]]$FocusedResults,
    [Parameter(Mandatory)][string]$FullPackageCommand,
    [Parameter(Mandatory)][int]$FullPackagePassTotal,
    [Parameter(Mandatory)][string]$FullPackageSummary
  )

  return [pscustomobject][ordered]@{
    schema_version = $EvidenceSchemaVersion
    workflow_id = $EvidenceWorkflowId
    target = $Target
    toolchain = $Toolchain
    fixtures = $Fixtures
    standalone_baseline = [pscustomobject][ordered]@{
      public_facts = $PublicFacts
      hostile_outcomes = $HostileOutcomes
      capability_assertion = (
        'unsupported containers outlines variations color and bitmap profiles are capabilities'
      )
    }
    generated_collection_facts = $CollectionFacts.generated
    licensed_derivative_facts = $CollectionFacts.licensed
    collection_hostile_outcomes = $CollectionFacts.hostile
    mutation_atomicity_facts = $CollectionFacts.mutation
    boundary_facts = $BoundaryFacts
    dependency_facts = $DependencyFacts
    focused_assertions = @(
      $FocusedAssertions | ForEach-Object {
        [pscustomobject][ordered]@{
          group = [string]$_.group
          file = [string]$_.file
          name = [string]$_.name
        }
      }
    )
    runner = [pscustomobject][ordered]@{
      generator_command = './scripts/fixtures/Generate-FontQualification.ps1 -Check'
      policy_command = 'Assert-FontFoundationPolicy -PolicyPath ./policy/foundation.json'
      check_command = "moon -C modules/mb-font check --target $Target --frozen --target-dir `"$TargetDirectory`" --serial"
      focused_commands = $FocusedResults
      focused_gate_count = $FocusedResults.Count
      full_package_command = $FullPackageCommand
      full_package_passed = $true
      full_package_pass_total = $FullPackagePassTotal
      full_package_summary = $FullPackageSummary
      target_directory = $TargetDirectory.Replace('\', '/')
      no_parallelize = $true
    }
    pass = $true
  }
}

function Compare-FontQualificationEvidence {
  param(
    [Parameter(Mandatory)][object[]]$Records,
    [Parameter(Mandatory)][string]$Directory
  )

  if ($Records.Count -ne 4) {
    throw 'Exactly four target evidence records are required.'
  }
  $recordTargets = @($Records | ForEach-Object { [string]$_.target })
  if (@($recordTargets | Select-Object -Unique).Count -ne $Targets.Count) {
    throw 'Target evidence records must be unique.'
  }
  for ($index = 0; $index -lt $Targets.Count; $index++) {
    if ($recordTargets[$index] -cne $Targets[$index]) {
      throw "Target evidence order drifted at index ${index}: expected $($Targets[$index]), got $($recordTargets[$index])."
    }
  }
  $semanticPayloads = @(
    foreach ($record in $Records) {
      Assert-FontQualificationEvidenceRecord $record
      [pscustomobject][ordered]@{
        schema_version = $record.schema_version
        workflow_id = $record.workflow_id
        toolchain = $record.toolchain
        fixtures = $record.fixtures
        standalone_baseline = $record.standalone_baseline
        generated_collection_facts = $record.generated_collection_facts
        licensed_derivative_facts = $record.licensed_derivative_facts
        collection_hostile_outcomes = $record.collection_hostile_outcomes
        mutation_atomicity_facts = $record.mutation_atomicity_facts
        boundary_facts = $record.boundary_facts
        dependency_facts = $record.dependency_facts
        focused_assertions = $record.focused_assertions
        pass = $record.pass
      }
    }
  )
  $canonical = @(
    $semanticPayloads |
      ForEach-Object { ConvertTo-FontQualificationJson $_ -Compress }
  )
  $equal = @($canonical | Select-Object -Unique).Count -eq 1
  if (-not $equal) {
    throw 'Four-target font qualification semantics differ.'
  }
  $recordHashes = [pscustomobject][ordered]@{}
  foreach ($record in $Records) {
    $path = Join-Path $Directory "$($record.target).json"
    $recordHashes | Add-Member -NotePropertyName $record.target -NotePropertyValue (
      Get-FontQualificationSha256 ([IO.File]::ReadAllBytes($path))
    )
  }
  $semanticHash = Get-FontQualificationSha256 $Utf8NoBom.GetBytes($canonical[0])
  $comparison = [pscustomobject][ordered]@{
    schema_version = $EvidenceSchemaVersion
    workflow_id = $EvidenceWorkflowId
    normalization_removed = @('target', 'runner')
    targets = $Targets
    record_sha256 = $recordHashes
    semantic_sha256 = $semanticHash
    equal = $true
  }
  Write-FontQualificationJson (Join-Path $Directory 'comparison.json') $comparison
  return $comparison
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

function Invoke-FontQualification {
  [CmdletBinding()]
  param(
    [string]$EvidenceDirectory = 'artifacts/release-qualification/font-v2'
  )

  $managedEvidenceRoot = [IO.Path]::GetFullPath(
    (Join-Path $RepositoryRoot 'artifacts/release-qualification')
  )
  $resolvedEvidence = Resolve-FontQualificationEvidencePath `
    -EvidenceDirectory $EvidenceDirectory `
    -ManagedRoot $managedEvidenceRoot `
    -RepositoryRoot $RepositoryRoot
  Initialize-FontQualificationEvidenceDirectory `
    -Directory $resolvedEvidence `
    -ManagedRoot $managedEvidenceRoot

  Push-Location $RepositoryRoot
  try {
    & ./scripts/fixtures/Generate-FontQualification.ps1 -Check
    if ($LASTEXITCODE -ne 0) {
      throw 'Font qualification generator check failed.'
    }

    . ./scripts/quality/Assert-Policy.ps1
    Assert-FontFoundationPolicy -PolicyPath ./policy/foundation.json

    Clear-FontQualificationEvidenceFiles `
      -Directory $resolvedEvidence `
      -ManagedRoot $managedEvidenceRoot

    $oracle = Get-Content -Raw -LiteralPath (
      'fixtures/font/dejavu-sans-2.37/oracle.json'
    ) | ConvertFrom-Json
    $cases = Get-Content -Raw -LiteralPath (
      'fixtures/font/qualification-cases.json'
    ) | ConvertFrom-Json
    $collectionCases = Get-Content -Raw -LiteralPath (
      'fixtures/font/collection-qualification-cases.json'
    ) | ConvertFrom-Json
    $collectionOracle = Get-Content -Raw -LiteralPath (
      'fixtures/font/dejavu-sans-2.37/collection-oracle.json'
    ) | ConvertFrom-Json
    $toolchain = Get-FontQualificationToolchain
    $fixtures = [pscustomobject][ordered]@{
      dejavu_sans_237 = Get-FontQualificationFileFact (
        'fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf'
      )
      dejavu_license = Get-FontQualificationFileFact (
        'fixtures/font/dejavu-sans-2.37/LICENSE'
      )
      independent_oracle = Get-FontQualificationFileFact (
        'fixtures/font/dejavu-sans-2.37/oracle.json'
      )
      hostile_cases = Get-FontQualificationFileFact (
        'fixtures/font/qualification-cases.json'
      )
      collection_cases = Get-FontQualificationFileFact (
        'fixtures/font/collection-qualification-cases.json'
      )
      licensed_derivative = Get-FontQualificationFileFact (
        'fixtures/font/dejavu-sans-2.37/DejaVuSans-two-face-v1.ttc'
      )
      collection_oracle = Get-FontQualificationFileFact (
        'fixtures/font/dejavu-sans-2.37/collection-oracle.json'
      )
      generated_source = Get-FontQualificationFileFact (
        'modules/mb-font/font/generated_font_qualification_test.mbt'
      )
      workflow_test = Get-FontQualificationFileFact (
        'modules/mb-font/font/font_qualification_test.mbt'
      )
      hostile_test = Get-FontQualificationFileFact (
        'modules/mb-font/font/font_qualification_hostile_test.mbt'
      )
    }
    $publicFacts = Get-FontQualificationPublicFacts $oracle
    $hostileOutcomes = Get-FontQualificationHostileOutcomes $cases
    $collectionFacts = Get-FontQualificationCollectionFacts `
      -Corpus $collectionCases `
      -CollectionOracle $collectionOracle `
      -Fixtures $fixtures
    $boundaryFacts = Get-FontQualificationBoundaryFacts
    $dependencyFacts = Get-FontQualificationDependencyFacts
    $records = @(
      foreach ($target in $Targets) {
        $targetDirectory = "target/phase103-font-qualification-$target"
        & moon -C modules/mb-font check --target $target --frozen `
          --target-dir $targetDirectory --serial | Out-Host
        if ($LASTEXITCODE -ne 0) {
          throw "Font qualification check for target $target failed with exit $LASTEXITCODE."
        }

        $focusedResults = @(
          foreach ($assertion in $FocusedAssertions) {
            $command = (
              "moon -C modules/mb-font test $($assertion.file) " +
              "-f '$($assertion.name)' --target $target --frozen " +
              "--target-dir `"$targetDirectory`" --no-parallelize"
            )
            $output = @(
              & moon -C modules/mb-font test $assertion.file `
                -f $assertion.name --target $target --frozen `
                --target-dir $targetDirectory --no-parallelize 2>&1
            )
            $exitCode = $LASTEXITCODE
            $lines = @($output | ForEach-Object { [string]$_ })
            $lines | ForEach-Object { Write-Host $_ }
            if ($exitCode -ne 0) {
              throw (
                "Focused assertion '$($assertion.name)' for target $target " +
                "failed with exit $exitCode."
              )
            }
            $passSummaries = @(
              $lines | Where-Object { $_ -ceq $FocusedPassSummary }
            )
            if ($passSummaries.Count -ne 1) {
              throw (
                "Focused assertion '$($assertion.name)' for target $target " +
                'did not report exactly one passing test.'
              )
            }
            [pscustomobject][ordered]@{
              group = [string]$assertion.group
              file = [string]$assertion.file
              name = [string]$assertion.name
              command = $command
              passed = $true
              pass_total = 1
            }
          }
        )

        $fullPackageCommand = (
          "moon -C modules/mb-font test font --target $target --frozen " +
          "--target-dir `"$targetDirectory`" --no-parallelize"
        )
        $fullOutput = @(
          & moon -C modules/mb-font test font --target $target --frozen `
            --target-dir $targetDirectory --no-parallelize 2>&1
        )
        $fullExit = $LASTEXITCODE
        $fullLines = @($fullOutput | ForEach-Object { [string]$_ })
        $fullLines | ForEach-Object { Write-Host $_ }
        if ($fullExit -ne 0) {
          throw "Font qualification target $target failed with exit $fullExit."
        }
        $fullSummaries = @(
          $fullLines |
            Where-Object {
              $_ -cmatch '^Total tests: \d+, passed: \d+, failed: \d+\.$'
            }
        )
        if ($fullSummaries.Count -ne 1) {
          throw "Font qualification target $target has no unique full-package summary."
        }
        $fullMatch = [regex]::Match(
          $fullSummaries[0],
          '^Total tests: (?<total>\d+), passed: (?<passed>\d+), failed: (?<failed>\d+)\.$'
        )
        $fullTotal = [int]$fullMatch.Groups['total'].Value
        $fullPassed = [int]$fullMatch.Groups['passed'].Value
        $fullFailed = [int]$fullMatch.Groups['failed'].Value
        if ($fullTotal -lt 1 -or $fullPassed -ne $fullTotal -or $fullFailed -ne 0) {
          throw "Font qualification target $target did not pass its discovered package total."
        }

        $record = New-FontQualificationEvidenceRecord `
          -Target $target `
          -Toolchain $toolchain `
          -Fixtures $fixtures `
          -PublicFacts $publicFacts `
          -HostileOutcomes $hostileOutcomes `
          -CollectionFacts $collectionFacts `
          -BoundaryFacts $boundaryFacts `
          -DependencyFacts $dependencyFacts `
          -TargetDirectory $targetDirectory `
          -FocusedResults $focusedResults `
          -FullPackageCommand $fullPackageCommand `
          -FullPackagePassTotal $fullPassed `
          -FullPackageSummary $fullSummaries[0]
        Assert-FontQualificationEvidenceRecord $record
        $path = Join-Path $resolvedEvidence "$target.json"
        Write-FontQualificationJson $path $record
        $readBack = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
        Assert-FontQualificationEvidenceRecord $readBack
        $readBack
      }
    )

    $negativeProbeCount = 0
    $probe = {
      param([string]$Name, [scriptblock]$Action, [string]$Pattern)
      Confirm-FontQualificationEvidenceRejected $Name $Action $Pattern
      $script:fontQualificationNegativeProbeCount++
    }
    $script:fontQualificationNegativeProbeCount = 0
    & $probe 'missing target evidence record' {
      Compare-FontQualificationEvidence @($records | Select-Object -First 3) $resolvedEvidence
    } 'Exactly four target evidence records are required'
    & $probe 'duplicate target evidence record' {
      $copy = @($records | ForEach-Object {
        ConvertTo-FontQualificationJson $_ -Compress | ConvertFrom-Json
      })
      $copy[3].target = 'js'
      Compare-FontQualificationEvidence $copy $resolvedEvidence
    } 'unique'
    & $probe 'reordered target evidence record' {
      Compare-FontQualificationEvidence @(
        $records[1], $records[0], $records[2], $records[3]
      ) $resolvedEvidence
    } 'Target evidence order drifted'
    & $probe 'unknown target evidence record' {
      $copy = @($records | ForEach-Object {
        ConvertTo-FontQualificationJson $_ -Compress | ConvertFrom-Json
      })
      $copy[3].target = 'native-unknown'
      Compare-FontQualificationEvidence $copy $resolvedEvidence
    } 'Target evidence order drifted'
    foreach ($identityProbe in @(
      @{ Name = 'schema'; Key = 'schema_version'; Value = '1.0.0' },
      @{ Name = 'workflow'; Key = 'workflow_id'; Value = 'font-complete-public-v1' },
      @{ Name = 'false pass'; Key = 'pass'; Value = $false }
    )) {
      & $probe "$($identityProbe.Name) divergence" {
        $copy = ConvertTo-FontQualificationJson $records[0] -Compress |
          ConvertFrom-Json
        $copy.($identityProbe.Key) = $identityProbe.Value
        Assert-FontQualificationEvidenceRecord $copy
      } 'qualification identity or pass state drifted'
    }
    & $probe 'top-level extra key' {
      $copy = ConvertTo-FontQualificationJson $records[0] -Compress |
        ConvertFrom-Json
      $copy | Add-Member -NotePropertyName unexpected -NotePropertyValue $true
      Assert-FontQualificationEvidenceRecord $copy
    } 'key count drifted'
    & $probe 'nested extra key' {
      $copy = ConvertTo-FontQualificationJson $records[0] -Compress |
        ConvertFrom-Json
      $copy.boundary_facts | Add-Member `
        -NotePropertyName unexpected `
        -NotePropertyValue $true
      Assert-FontQualificationEvidenceRecord $copy
    } 'key count drifted'
    & $probe 'licensed derivative digest divergence' {
      $copy = ConvertTo-FontQualificationJson $records[0] -Compress |
        ConvertFrom-Json
      $copy.licensed_derivative_facts.sha256 = '00'
      Assert-FontQualificationEvidenceRecord $copy
    } 'licensed derivative identity'
    & $probe 'shared coordinate semantic divergence' {
      $copy = @($records | ForEach-Object {
        ConvertTo-FontQualificationJson $_ -Compress | ConvertFrom-Json
      })
      $copy[3].licensed_derivative_facts.shared_table_coordinates[0].root_offset++
      Compare-FontQualificationEvidence $copy $resolvedEvidence
    } 'Four-target font qualification semantics differ'
    & $probe 'hostile error semantic divergence' {
      $copy = @($records | ForEach-Object {
        ConvertTo-FontQualificationJson $_ -Compress | ConvertFrom-Json
      })
      $copy[3].collection_hostile_outcomes.hostile[0].error.code = 'Drift'
      Compare-FontQualificationEvidence $copy $resolvedEvidence
    } 'Four-target font qualification semantics differ'
    & $probe 'budget after semantic divergence' {
      $copy = @($records | ForEach-Object {
        ConvertTo-FontQualificationJson $_ -Compress | ConvertFrom-Json
      })
      $copy[3].collection_hostile_outcomes.budgets[0].budget_after.work++
      Compare-FontQualificationEvidence $copy $resolvedEvidence
    } 'Four-target font qualification semantics differ'
    & $probe 'WOFF boundary divergence' {
      $copy = ConvertTo-FontQualificationJson $records[0] -Compress |
        ConvertFrom-Json
      $copy.boundary_facts.container_capabilities.woff1 = 'supported'
      Assert-FontQualificationEvidenceRecord $copy
    } 'API/source/capability boundary'
    & $probe 'dependency boundary divergence' {
      $copy = ConvertTo-FontQualificationJson $records[0] -Compress |
        ConvertFrom-Json
      $copy.dependency_facts.module_dependencies[0].name = 'other'
      Assert-FontQualificationEvidenceRecord $copy
    } 'dependency evidence drifted'
    & $probe 'assertion identity divergence' {
      $copy = ConvertTo-FontQualificationJson $records[0] -Compress |
        ConvertFrom-Json
      $copy.focused_assertions[0].name = 'drift'
      Assert-FontQualificationEvidenceRecord $copy
    } 'focused assertion identity/order'
    & $probe 'assertion order divergence' {
      $copy = ConvertTo-FontQualificationJson $records[0] -Compress |
        ConvertFrom-Json
      $first = $copy.focused_assertions[0]
      $copy.focused_assertions[0] = $copy.focused_assertions[1]
      $copy.focused_assertions[1] = $first
      Assert-FontQualificationEvidenceRecord $copy
    } 'focused assertion identity/order'
    & $probe 'semantic evidence divergence' {
      $copy = @($records | ForEach-Object {
        ConvertTo-FontQualificationJson $_ -Compress | ConvertFrom-Json
      })
      $copy[3].toolchain.moon = "$($copy[3].toolchain.moon)-drift"
      Compare-FontQualificationEvidence $copy $resolvedEvidence
    } 'Four-target font qualification semantics differ'
    $negativeProbeCount = $script:fontQualificationNegativeProbeCount
    Remove-Variable fontQualificationNegativeProbeCount -Scope Script

    $fullPassTotals = @(
      $records.runner.full_package_pass_total | Select-Object -Unique
    )
    if ($fullPassTotals.Count -ne 1) {
      throw 'Four-target discovered full-package pass totals differ.'
    }
    $comparison = Compare-FontQualificationEvidence $records $resolvedEvidence
    $writtenTargets = @(
      Get-ChildItem -LiteralPath $resolvedEvidence -Filter '*.json' |
        Where-Object { $_.Name -cne 'comparison.json' } |
        ForEach-Object { $_.BaseName }
    )
    if ($writtenTargets.Count -ne $Targets.Count -or
        (Compare-Object -CaseSensitive $Targets $writtenTargets)) {
      throw 'Written target evidence record count or identity drifted.'
    }
    foreach ($target in $Targets) {
      $readmeTargetDirectory = "target/phase103-font-readme-$target"
      & moon -C modules/mb-font check README.mbt.md --target $target --frozen `
        --target-dir $readmeTargetDirectory --serial | Out-Host
      if ($LASTEXITCODE -ne 0) {
        throw "Font README check for target $target failed with exit $LASTEXITCODE."
      }
    }
    Write-Host (
      "Font qualification v2 passed: targets=$($writtenTargets.Count), " +
      "records=$($records.Count), focused-gates-per-target=$($FocusedAssertions.Count), " +
      "full-package-passes=$($fullPassTotals[0]), negative-probes=$negativeProbeCount, " +
      "comparison-gates=1, semantic-sha256=$($comparison.semantic_sha256)."
    )
  } finally {
    Pop-Location
  }
}

if (-not $ImportOnly -and $MyInvocation.InvocationName -cne '.') {
  Invoke-FontQualification -EvidenceDirectory $EvidenceDirectory
}
