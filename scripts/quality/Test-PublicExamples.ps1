[CmdletBinding()]
param(
  [ValidateSet('portable', 'native', 'all')]
  [string]$Example = 'all',
  [ValidateSet('workspace', 'qualify')]
  [string]$Mode = 'workspace',
  [ValidateSet('all', 'js', 'wasm', 'wasm-gc', 'native')]
  [string]$Target = 'all',
  [string]$Report
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$portableRoot = Join-Path $repoRoot 'examples\ppm-portable'
$nativeRoot = Join-Path $repoRoot 'examples\ppm-native-cli'
$schemaPath = Join-Path $repoRoot 'release\qualification\example-consumers-schema.json'

function Assert-QualificationSchema {
  if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) {
    throw "Example-consumer qualification schema is missing: $schemaPath"
  }
  $schema = Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json -Depth 100
  if ($schema.properties.schema_version.const -cne '1.0.0' -or
      $schema.properties.source_audit.const -cne 'pass' -or
      $schema.properties.source_isolation.const -cne 'pass' -or
      $schema.properties.registry_resolution.const -cne 'blocked_unpublished_namespace') {
    throw 'Example-consumer qualification schema does not freeze the required independent outcomes.'
  }
}

Assert-QualificationSchema

function Assert-ExampleSource {
  param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string[]]$Files)

  foreach ($relative in $Files) {
    $path = Join-Path $Root $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw "Public example source is missing: $path"
    }
  }
}

function Invoke-MoonExample {
  param(
    [Parameter(Mandatory)][string]$WorkingRoot,
    [Parameter(Mandatory)][string]$Package,
    [Parameter(Mandatory)][string]$RunTarget,
    [Parameter(Mandatory)][string]$Expected
  )

  $output = @(& moon -C $WorkingRoot run $Package --target $RunTarget --frozen 2>&1 | ForEach-Object { $_.ToString().TrimEnd() })
  if ($LASTEXITCODE -ne 0) {
    throw "Public example failed on $RunTarget (exit $LASTEXITCODE): $($output -join [Environment]::NewLine)"
  }
  $semantic = @($output | Where-Object { $_ -ne '' -and $_ -notmatch '^(Finished|Warning:)' })
  if ($semantic.Count -ne 1 -or $semantic[0] -cne $Expected) {
    throw "Public example output drifted on ${RunTarget}: '$($semantic -join ' | ')'"
  }
}

function Assert-NamedDependencies {
  param(
    [Parameter(Mandatory)][string]$Manifest,
    [Parameter(Mandatory)][string[]]$Expected
  )

  $text = Get-Content -LiteralPath $Manifest -Raw
  if ($text -cmatch '"path"\s*:|(?:^|[\\/])[.][.](?:[\\/]|$)') {
    throw "Example manifest uses a path substitution: $Manifest"
  }
  $module = $text | ConvertFrom-Json -Depth 20
  $actual = @($module.deps.PSObject.Properties.Name | Sort-Object)
  $wanted = @($Expected | Sort-Object)
  if (($actual -join "`n") -cne ($wanted -join "`n")) {
    throw "Example manifest dependency set drifted: $Manifest"
  }
  foreach ($name in $Expected) {
    if ([string]$module.deps.$name -cne '0.1.0') {
      throw "Example manifest dependency '$name' is not the exact named 0.1.0 requirement."
    }
  }
}

function Copy-SourceTree {
  param([Parameter(Mandatory)][string]$Source, [Parameter(Mandatory)][string]$Destination)

  New-Item -ItemType Directory -Path $Destination -Force | Out-Null
  foreach ($file in Get-ChildItem -LiteralPath $Source -Recurse -File) {
    $relative = [System.IO.Path]::GetRelativePath($Source, $file.FullName)
    if ($relative -cmatch '(?:^|[\\/])(?:_build|[.]repos|target)(?:[\\/]|$)') { continue }
    $destinationFile = Join-Path $Destination $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $destinationFile) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $destinationFile
  }
}

function Remove-QualifiedTemp {
  param([Parameter(Mandatory)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) { return }
  $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
  $full = [System.IO.Path]::GetFullPath($Path)
  $leaf = Split-Path -Leaf $full
  if (-not $full.StartsWith($tempRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or
      -not $leaf.StartsWith('mnf-public-examples-', [System.StringComparison]::Ordinal)) {
    throw "Refusing to remove an unverified qualification path: $full"
  }
  Remove-Item -LiteralPath $full -Recurse -Force
}

function Invoke-SourceIsolation {
  $root = Join-Path ([System.IO.Path]::GetTempPath()) ('mnf-public-examples-source-' + [guid]::NewGuid().ToString('N'))
  try {
    Copy-SourceTree -Source (Join-Path $repoRoot 'modules\mb-core') -Destination (Join-Path $root 'modules\mb-core')
    Copy-SourceTree -Source (Join-Path $repoRoot 'modules\mb-color') -Destination (Join-Path $root 'modules\mb-color')
    Copy-SourceTree -Source (Join-Path $repoRoot 'modules\mb-image') -Destination (Join-Path $root 'modules\mb-image')
    Copy-SourceTree -Source $portableRoot -Destination (Join-Path $root 'examples\ppm-portable')
    Copy-SourceTree -Source $nativeRoot -Destination (Join-Path $root 'examples\ppm-native-cli')
    Copy-Item -LiteralPath (Join-Path $repoRoot 'moon.work') -Destination (Join-Path $root 'moon.work')
    foreach ($runTarget in @('js', 'wasm', 'wasm-gc', 'native')) {
      Invoke-MoonExample -WorkingRoot $root -Package 'examples/ppm-portable/main' -RunTarget $runTarget -Expected 'example=portable bytes_read=17 bytes_written=17 width=2 height=1 transform=flip_horizontal disposition=5 digest=806175100'
    }
    Invoke-MoonExample -WorkingRoot $root -Package 'examples/ppm-native-cli/main' -RunTarget 'native' -Expected 'example=native bytes_read=17 bytes_written=17 transform=flip_horizontal disposition=5 digest=806175100 short_progress=pass'
    return 'pass'
  } finally {
    Remove-QualifiedTemp -Path $root
  }
}

function Invoke-RegistryResolutionProbe {
  $root = Join-Path ([System.IO.Path]::GetTempPath()) ('mnf-public-examples-registry-' + [guid]::NewGuid().ToString('N'))
  try {
    $probeModule = Join-Path $root 'ppm-portable'
    Copy-SourceTree -Source $portableRoot -Destination $probeModule
    $sourceHash = (Get-FileHash -LiteralPath (Join-Path $portableRoot 'moon.mod.json') -Algorithm SHA256).Hash
    $probeHash = (Get-FileHash -LiteralPath (Join-Path $probeModule 'moon.mod.json') -Algorithm SHA256).Hash
    if ($sourceHash -cne $probeHash) {
      throw 'Registry probe changed the named dependency manifest.'
    }
    $output = @(& moon -C $probeModule check --target native --frozen 2>&1 | ForEach-Object { $_.ToString().TrimEnd() })
    if ($LASTEXITCODE -eq 0) {
      throw 'Registry probe fabricated a downstream dependency-resolution pass.'
    }
    $text = $output -join "`n"
    if ($text -cnotmatch 'Failed to resolve registry dependency `moonbit-foundation/mb-core`' -or
        $text -cnotmatch 'Failed to resolve registry dependency `moonbit-foundation/mb-image`' -or
        $text -cnotmatch 'module was not found in the registry') {
      throw "Registry probe failed for an unrelated reason: $text"
    }
    return 'blocked_unpublished_namespace'
  } finally {
    Remove-QualifiedTemp -Path $root
  }
}

function Write-QualificationReport {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$SourceIsolation,
    [Parameter(Mandatory)][string]$RegistryResolution
  )

  $reportObject = [ordered]@{
    schema_version = '1.0.0'
    workspace_examples = [ordered]@{
      portable = [ordered]@{
        status = 'pass'
        targets = @('js', 'wasm', 'wasm-gc', 'native')
        digest = 'rolling257-mod1000000007:806175100'
      }
      native = [ordered]@{
        status = 'pass'
        target = 'native'
        digest = 'rolling257-mod1000000007:806175100'
        short_progress = 'pass'
      }
    }
    source_audit = 'pass'
    source_isolation = $SourceIsolation
    registry_resolution = $RegistryResolution
  }
  $absolute = if ([System.IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $repoRoot $Path }
  New-Item -ItemType Directory -Path (Split-Path -Parent $absolute) -Force | Out-Null
  $json = $reportObject | ConvertTo-Json -Depth 20
  [System.IO.File]::WriteAllText($absolute, $json + "`n", [System.Text.UTF8Encoding]::new($false))
  $roundTrip = Get-Content -LiteralPath $absolute -Raw | ConvertFrom-Json -Depth 20
  if ($roundTrip.source_audit -cne 'pass' -or
      $roundTrip.source_isolation -cne 'pass' -or
      $roundTrip.registry_resolution -cne 'blocked_unpublished_namespace' -or
      $roundTrip.workspace_examples.portable.digest -cne 'rolling257-mod1000000007:806175100' -or
      $roundTrip.workspace_examples.native.short_progress -cne 'pass') {
    throw 'Written example-consumer report does not conform to the frozen qualification outcomes.'
  }
}

function Assert-PublicImports {
  param(
    [Parameter(Mandatory)][string]$Root,
    [Parameter(Mandatory)][string[]]$AllowedImports
  )

  $packageFiles = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter 'moon.pkg')
  $imports = @()
  foreach ($packageFile in $packageFiles) {
    $text = Get-Content -LiteralPath $packageFile.FullName -Raw
    $importBlock = [regex]::Match($text, '(?s)\bimport\s*\{(?<body>.*?)\}')
    if ($importBlock.Success) {
      $imports += @([regex]::Matches($importBlock.Groups['body'].Value, '"([A-Za-z0-9._/-]+)"') | ForEach-Object { $_.Groups[1].Value })
    }
  }
  $unexpected = @($imports | Where-Object { $AllowedImports -cnotcontains $_ })
  if ($unexpected.Count -ne 0) {
    throw "Public example imports a non-allowlisted package: $($unexpected -join ', ')"
  }
  $source = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.mbt' | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"
  if ($source -cmatch '(?i)\b(?:priv|private)\b|@(?:fs|env|process)\b|\b(?:argv|getenv|registry|seeker)\b') {
    throw 'Public example source contains a private or ambient capability token.'
  }
}

if ($Example -in @('portable', 'all')) {
  Assert-ExampleSource -Root $portableRoot -Files @('moon.mod.json', 'main\moon.pkg', 'main\main.mbt')
  Assert-PublicImports -Root $portableRoot -AllowedImports @(
    'moonbit-foundation/mb-core/budget',
    'moonbit-foundation/mb-core/bytes',
    'moonbit-foundation/mb-core/error',
    'moonbit-foundation/mb-core/io',
    'moonbit-foundation/mb-image/codec',
    'moonbit-foundation/mb-image/ops',
    'moonbit-foundation/mb-image/ppm'
  )
  $targets = if ($Target -ceq 'all') { @('js', 'wasm', 'wasm-gc', 'native') } else { @($Target) }
  foreach ($runTarget in $targets) {
    Invoke-MoonExample -WorkingRoot $repoRoot -Package 'examples/ppm-portable/main' -RunTarget $runTarget -Expected 'example=portable bytes_read=17 bytes_written=17 width=2 height=1 transform=flip_horizontal disposition=5 digest=806175100'
  }
}
if ($Example -in @('native', 'all')) {
  Assert-ExampleSource -Root $nativeRoot -Files @('moon.mod.json', 'main\moon.pkg', 'main\adapter.mbt', 'main\main.mbt')
  Assert-NamedDependencies -Manifest (Join-Path $nativeRoot 'moon.mod.json') -Expected @('moonbit-foundation/mb-core', 'moonbit-foundation/mb-image')
  Assert-PublicImports -Root $nativeRoot -AllowedImports @(
    'moonbit-foundation/mb-core/budget',
    'moonbit-foundation/mb-core/bytes',
    'moonbit-foundation/mb-core/error',
    'moonbit-foundation/mb-core/io',
    'moonbit-foundation/mb-image/codec',
    'moonbit-foundation/mb-image/ops',
    'moonbit-foundation/mb-image/ppm'
  )
  Invoke-MoonExample -WorkingRoot $repoRoot -Package 'examples/ppm-native-cli/main' -RunTarget 'native' -Expected 'example=native bytes_read=17 bytes_written=17 transform=flip_horizontal disposition=5 digest=806175100 short_progress=pass'
}

if ($Mode -ceq 'qualify') {
  if ($Example -cne 'all') {
    throw 'Qualification mode requires -Example all so neither public consumer can be omitted.'
  }
  if ([string]::IsNullOrWhiteSpace($Report)) {
    throw 'Qualification mode requires a machine-readable -Report path.'
  }
  $sourceIsolation = Invoke-SourceIsolation
  $registryResolution = Invoke-RegistryResolutionProbe
  Write-QualificationReport -Path $Report -SourceIsolation $sourceIsolation -RegistryResolution $registryResolution
  Write-Host "source_isolation: $sourceIsolation"
  Write-Host "registry_resolution: $registryResolution"
}

Write-Host 'workspace_examples: pass'
  Assert-NamedDependencies -Manifest (Join-Path $portableRoot 'moon.mod.json') -Expected @('moonbit-foundation/mb-core', 'moonbit-foundation/mb-image')
