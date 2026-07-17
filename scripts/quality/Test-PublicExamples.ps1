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
    [Parameter(Mandatory)][string]$Package,
    [Parameter(Mandatory)][string]$RunTarget,
    [Parameter(Mandatory)][string]$Expected
  )

  $output = @(& moon run $Package --target $RunTarget --frozen 2>&1 | ForEach-Object { $_.ToString().TrimEnd() })
  if ($LASTEXITCODE -ne 0) {
    throw "Public example failed on $RunTarget (exit $LASTEXITCODE): $($output -join [Environment]::NewLine)"
  }
  $semantic = @($output | Where-Object { $_ -ne '' -and $_ -notmatch '^(Finished|Warning:)' })
  if ($semantic.Count -ne 1 -or $semantic[0] -cne $Expected) {
    throw "Public example output drifted on ${RunTarget}: '$($semantic -join ' | ')'"
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
    Invoke-MoonExample -Package 'examples/ppm-portable/main' -RunTarget $runTarget -Expected 'example=portable bytes_read=17 bytes_written=17 width=2 height=1 transform=flip_horizontal disposition=5 digest=806175100'
  }
}
if ($Example -in @('native', 'all')) {
  Assert-ExampleSource -Root $nativeRoot -Files @('moon.mod.json', 'main\moon.pkg', 'main\adapter.mbt', 'main\main.mbt')
}

if ($Mode -ceq 'qualify') {
  throw 'RED: copied-source isolation, registry-resolution classification, and report qualification are not implemented yet.'
}

Write-Host 'workspace_examples: pass'
