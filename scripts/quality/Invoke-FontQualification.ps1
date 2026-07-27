[CmdletBinding()]
param(
  [string]$EvidenceDirectory = 'artifacts/release-qualification/font'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Utf8NoBom = [Text.UTF8Encoding]::new($false)
$Targets = @('js', 'wasm', 'wasm-gc', 'native')
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
    [pscustomobject][ordered]@{
      status = 'path'
      command_count = [int]$OracleGlyph.path.command_count
      fingerprint_sha256 = [string]$OracleGlyph.path.fingerprint_sha256
      selected_commands = @($OracleGlyph.path.selected_commands)
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
    [Parameter(Mandatory)][string]$TargetDirectory
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
  $semanticPayloads = @(
    foreach ($record in $Records) {
      Assert-FontQualificationClosedKeys $record $RecordKeys "$($record.target) record"
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

Push-Location $RepositoryRoot
try {
  & ./scripts/fixtures/Generate-FontQualification.ps1 -Check
  if (-not $?) {
    throw 'Font qualification generator check failed.'
  }

  $resolvedEvidence = if ([IO.Path]::IsPathRooted($EvidenceDirectory)) {
    [IO.Path]::GetFullPath($EvidenceDirectory)
  } else {
    [IO.Path]::GetFullPath((Join-Path $RepositoryRoot $EvidenceDirectory))
  }
  [void](New-Item -ItemType Directory -Force -Path $resolvedEvidence)

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
        -TargetDirectory $targetDirectory
      Assert-FontQualificationClosedKeys $record $RecordKeys "$target record"
      $path = Join-Path $resolvedEvidence "$target.json"
      Write-FontQualificationJson $path $record
      $readBack = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
      Assert-FontQualificationClosedKeys $readBack $RecordKeys "$target persisted record"
      if ($readBack.pass -ne $true) {
        throw "$target evidence did not persist pass=true."
      }
      $record
    }
  )
  $comparison = Compare-FontQualificationEvidence $records $resolvedEvidence
  Write-Host (
    "Font qualification passed for $($Targets -join ', '); semantic SHA-256 $($comparison.semantic_sha256)."
  )
} finally {
  Pop-Location
}
