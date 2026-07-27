[CmdletBinding(DefaultParameterSetName = 'Run')]
param(
  [Parameter(ParameterSetName = 'Run')]
  [string]$EvidenceDirectory = 'artifacts/release-qualification/font',
  [Parameter(Mandatory, ParameterSetName = 'Import')]
  [switch]$ImportOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Utf8NoBom = [Text.UTF8Encoding]::new($false)
$Targets = @('js', 'wasm', 'wasm-gc', 'native')
$OutlineAssertionTestFile = 'font/font_qualification_test.mbt'
$OutlineAssertionTestName = 'font-complete-public freezes DejaVu Sans 2.37 public facts'
$OutlineAssertionPassSummary = 'Total tests: 1, passed: 1, failed: 0.'
$HostileAssertionTestFile = 'font/font_qualification_hostile_test.mbt'
$HostileAssertionTestName = 'font qualification executes the closed hostile outcome matrix'
$HostileAssertionPassSummary = 'Total tests: 1, passed: 1, failed: 0.'
$SupportedOutlineScalars = @('U+0041', 'U+034C', 'U+10300')
$EvidenceMarkerName = '.mnf-font-qualification-managed.json'
$EvidenceMarkerSchema = 'mnf-font-qualification-evidence/v1'
$RecordKeys = @(
  'schema_version',
  'workflow_id',
  'target',
  'toolchain',
  'fixtures',
  'public_facts',
  'hostile_outcomes',
  'dependency_facts',
  'runner',
  'pass'
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
      $marker.workflow_id -cne 'font-complete-public-v1') {
    throw "Managed font qualification evidence marker is invalid in '$Directory'."
  }
}

function Initialize-FontQualificationEvidenceDirectory {
  param([Parameter(Mandatory)][string]$Directory)

  if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $Directory)
  }
  $markerPath = Join-Path $Directory $EvidenceMarkerName
  if (Test-Path -LiteralPath $markerPath) {
    Assert-FontQualificationEvidenceMarker $Directory
    return
  }
  if (@(Get-ChildItem -LiteralPath $Directory -Force).Count -ne 0) {
    throw (
      "Refusing non-empty unowned font qualification evidence directory '$Directory'."
    )
  }
  Write-FontQualificationJson $markerPath ([pscustomobject][ordered]@{
    schema = $EvidenceMarkerSchema
    workflow_id = 'font-complete-public-v1'
  })
}

function Clear-FontQualificationEvidenceFiles {
  param([Parameter(Mandatory)][string]$Directory)

  Assert-FontQualificationEvidenceMarker $Directory
  foreach ($evidenceName in @($Targets | ForEach-Object { "$_.json" }) + 'comparison.json') {
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

function Assert-FontQualificationEvidenceRecord {
  param([Parameter(Mandatory)]$Record)

  Assert-FontQualificationClosedKeys $Record $RecordKeys "$($Record.target) record"
  Assert-FontQualificationClosedKeys $Record.toolchain @('moon','moonc','moonrun') "$($Record.target) toolchain"
  Assert-FontQualificationClosedKeys $Record.fixtures @(
    'dejavu_sans_237',
    'dejavu_license',
    'independent_oracle',
    'hostile_cases',
    'generated_source',
    'workflow_test',
    'hostile_test'
  ) "$($Record.target) fixtures"
  foreach ($fixture in $Record.fixtures.PSObject.Properties) {
    Assert-FontQualificationClosedKeys $fixture.Value @('path','length','sha256') "$($Record.target) fixture $($fixture.Name)"
  }
  Assert-FontQualificationClosedKeys $Record.public_facts @('compact','dejavu_sans_237') "$($Record.target) public facts"
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
  Assert-FontQualificationClosedKeys $Record.runner @(
    'generator_command',
    'check_command',
    'outline_assertion_test',
    'outline_assertion_command',
    'outline_assertion_passed',
    'hostile_assertion_test',
    'hostile_assertion_command',
    'hostile_assertion_passed',
    'test_command',
    'target_directory',
    'no_parallelize'
  ) "$($Record.target) runner"
  $expectedOutlineAssertion = 'font-complete-public freezes DejaVu Sans 2.37 public facts'
  if ($Record.runner.outline_assertion_test -cne $expectedOutlineAssertion -or
      $Record.runner.outline_assertion_passed -ne $true -or
      [string]$Record.runner.outline_assertion_command -cnotmatch [regex]::Escape("--target $($Record.target)")) {
    throw "$($Record.target) focused outline assertion evidence drifted."
  }
  $expectedHostileAssertion = 'font qualification executes the closed hostile outcome matrix'
  $expectedHostileCommand = (
    "moon -C modules/mb-font test $HostileAssertionTestFile " +
    "-f '$expectedHostileAssertion' --target $($Record.target) --frozen " +
    "--target-dir `"$($Record.runner.target_directory)`" --no-parallelize"
  )
  if ($Record.runner.hostile_assertion_test -cne $expectedHostileAssertion -or
      $Record.runner.hostile_assertion_passed -ne $true -or
      [string]$Record.runner.hostile_assertion_command -cne $expectedHostileCommand) {
    throw "$($Record.target) focused hostile assertion evidence drifted."
  }
  if ($Record.schema_version -cne '1.0.0' -or
      $Record.workflow_id -cne 'font-complete-public-v1' -or
      $Record.pass -ne $true) {
    throw "$($Record.target) qualification identity or pass state drifted."
  }
  $outcomes = @($Record.hostile_outcomes)
  if ($outcomes.Count -ne $HostileOutcomeIds.Count) {
    throw "$($Record.target) hostile outcome count drifted."
  }
  for ($index = 0; $index -lt $HostileOutcomeIds.Count; $index++) {
    Assert-FontQualificationClosedKeys $outcomes[$index] @(
      'id',
      'stage',
      'category',
      'code',
      'context',
      'requested',
      'limit',
      'publication'
    ) "$($Record.target) hostile outcome $index"
    if ($outcomes[$index].id -cne $HostileOutcomeIds[$index]) {
      throw "$($Record.target) hostile outcome ID drifted at index $index."
    }
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

function New-FontQualificationEvidenceRecord {
  param(
    [Parameter(Mandatory)][string]$Target,
    [Parameter(Mandatory)]$Toolchain,
    [Parameter(Mandatory)]$Fixtures,
    [Parameter(Mandatory)]$PublicFacts,
    [Parameter(Mandatory)]$HostileOutcomes,
    [Parameter(Mandatory)]$DependencyFacts,
    [Parameter(Mandatory)][string]$TargetDirectory,
    [Parameter(Mandatory)][string]$OutlineAssertionCommand,
    [Parameter(Mandatory)][string]$HostileAssertionCommand
  )

  return [pscustomobject][ordered]@{
    schema_version = '1.0.0'
    workflow_id = 'font-complete-public-v1'
    target = $Target
    toolchain = $Toolchain
    fixtures = $Fixtures
    public_facts = $PublicFacts
    hostile_outcomes = $HostileOutcomes
    dependency_facts = $DependencyFacts
    runner = [pscustomobject][ordered]@{
      generator_command = './scripts/fixtures/Generate-FontQualification.ps1 -Check'
      check_command = "moon -C modules/mb-font check --target $Target --frozen --target-dir `"$TargetDirectory`" --serial"
      outline_assertion_test = $OutlineAssertionTestName
      outline_assertion_command = $OutlineAssertionCommand
      outline_assertion_passed = $true
      hostile_assertion_test = $HostileAssertionTestName
      hostile_assertion_command = $HostileAssertionCommand
      hostile_assertion_passed = $true
      test_command = "moon -C modules/mb-font test font --target $Target --frozen --target-dir `"$TargetDirectory`" --no-parallelize"
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
        public_facts = $record.public_facts
        hostile_outcomes = $record.hostile_outcomes
        dependency_facts = $record.dependency_facts
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
    schema_version = '1.0.0'
    workflow_id = 'font-complete-public-v1'
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

if ($ImportOnly) {
  return
}

$managedEvidenceRoot = [IO.Path]::GetFullPath(
  (Join-Path $RepositoryRoot 'artifacts/release-qualification')
)
$resolvedEvidence = Resolve-FontQualificationEvidencePath `
  -EvidenceDirectory $EvidenceDirectory `
  -ManagedRoot $managedEvidenceRoot `
  -RepositoryRoot $RepositoryRoot
Initialize-FontQualificationEvidenceDirectory $resolvedEvidence

Push-Location $RepositoryRoot
try {
  & ./scripts/fixtures/Generate-FontQualification.ps1 -Check
  if (-not $?) {
    throw 'Font qualification generator check failed.'
  }

  . ./scripts/quality/Assert-Policy.ps1
  Assert-FontFoundationPolicy -PolicyPath ./policy/foundation.json

  Clear-FontQualificationEvidenceFiles $resolvedEvidence

  $oracle = Get-Content -Raw -LiteralPath (
    'fixtures/font/dejavu-sans-2.37/oracle.json'
  ) | ConvertFrom-Json
  $cases = Get-Content -Raw -LiteralPath (
    'fixtures/font/qualification-cases.json'
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
  $dependencyFacts = Get-FontQualificationDependencyFacts
  $records = @(
    foreach ($target in $Targets) {
      $targetDirectory = "target/phase100-font-qualification-$target"
      & moon -C modules/mb-font check --target $target --frozen `
        --target-dir $targetDirectory --serial | Out-Host
      if ($LASTEXITCODE -ne 0) {
        throw "Font qualification check for target $target failed with exit $LASTEXITCODE."
      }
      $outlineAssertionCommand = (
        "moon -C modules/mb-font test $OutlineAssertionTestFile " +
        "-f '$OutlineAssertionTestName' --target $target --frozen " +
        "--target-dir `"$targetDirectory`" --no-parallelize"
      )
      $outlineAssertionOutput = @(
        & moon -C modules/mb-font test $OutlineAssertionTestFile `
          -f $OutlineAssertionTestName --target $target --frozen `
          --target-dir $targetDirectory --no-parallelize 2>&1
      )
      $outlineAssertionExit = $LASTEXITCODE
      $outlineAssertionLines = @(
        $outlineAssertionOutput | ForEach-Object { [string]$_ }
      )
      $outlineAssertionLines | ForEach-Object { Write-Host $_ }
      if ($outlineAssertionExit -ne 0) {
        throw "Font qualification focused outline assertion for target $target failed with exit $outlineAssertionExit."
      }
      $passSummaries = @(
        $outlineAssertionLines | Where-Object { $_ -ceq $OutlineAssertionPassSummary }
      )
      if ($passSummaries.Count -ne 1) {
        throw "Font qualification focused outline assertion for target $target did not report exactly one passing test."
      }
      $hostileAssertionCommand = (
        "moon -C modules/mb-font test $HostileAssertionTestFile " +
        "-f '$HostileAssertionTestName' --target $target --frozen " +
        "--target-dir `"$targetDirectory`" --no-parallelize"
      )
      $hostileAssertionOutput = @(
        & moon -C modules/mb-font test $HostileAssertionTestFile `
          -f $HostileAssertionTestName --target $target --frozen `
          --target-dir $targetDirectory --no-parallelize 2>&1
      )
      $hostileAssertionExit = $LASTEXITCODE
      $hostileAssertionLines = @(
        $hostileAssertionOutput | ForEach-Object { [string]$_ }
      )
      $hostileAssertionLines | ForEach-Object { Write-Host $_ }
      if ($hostileAssertionExit -ne 0) {
        throw "Font qualification focused hostile assertion for target $target failed with exit $hostileAssertionExit."
      }
      $hostilePassSummaries = @(
        $hostileAssertionLines | Where-Object { $_ -ceq $HostileAssertionPassSummary }
      )
      if ($hostilePassSummaries.Count -ne 1) {
        throw "Font qualification focused hostile assertion for target $target did not report exactly one passing test."
      }
      & moon -C modules/mb-font test font --target $target --frozen `
        --target-dir $targetDirectory --no-parallelize | Out-Host
      if ($LASTEXITCODE -ne 0) {
        throw "Font qualification target $target failed with exit $LASTEXITCODE."
      }
      $record = New-FontQualificationEvidenceRecord `
        -Target $target `
        -Toolchain $toolchain `
        -Fixtures $fixtures `
        -PublicFacts $publicFacts `
        -HostileOutcomes $hostileOutcomes `
        -DependencyFacts $dependencyFacts `
        -TargetDirectory $targetDirectory `
        -OutlineAssertionCommand $outlineAssertionCommand `
        -HostileAssertionCommand $hostileAssertionCommand
      Assert-FontQualificationEvidenceRecord $record
      $record
    }
  )
  foreach ($record in $records) {
      $target = [string]$record.target
      $path = Join-Path $resolvedEvidence "$target.json"
      Write-FontQualificationJson $path $record
      $readBack = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
      Assert-FontQualificationEvidenceRecord $readBack
  }
  Confirm-FontQualificationEvidenceRejected 'missing target evidence record' {
    Compare-FontQualificationEvidence @($records | Select-Object -First 3) $resolvedEvidence
  } 'Exactly four target evidence records are required'
  $divergentRecords = @(
    $records | ForEach-Object {
      ConvertTo-FontQualificationJson $_ -Compress | ConvertFrom-Json
    }
  )
  $divergentRecords[3].public_facts.compact.source_length = 581
  Confirm-FontQualificationEvidenceRejected 'semantic evidence divergence' {
    Compare-FontQualificationEvidence $divergentRecords $resolvedEvidence
  } 'Four-target font qualification semantics differ'
  $comparison = Compare-FontQualificationEvidence $records $resolvedEvidence
  foreach ($target in $Targets) {
    $readmeTargetDirectory = "target/phase100-font-readme-$target"
    & moon -C modules/mb-font check README.mbt.md --target $target --frozen `
      --target-dir $readmeTargetDirectory --serial | Out-Host
    if ($LASTEXITCODE -ne 0) {
      throw "Font README check for target $target failed with exit $LASTEXITCODE."
    }
  }
  Write-Host (
    "Font qualification passed for $($Targets -join ', '); semantic SHA-256 $($comparison.semantic_sha256)."
  )
} finally {
  Pop-Location
}
