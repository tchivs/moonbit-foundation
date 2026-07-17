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

if ($Example -in @('portable', 'all')) {
  Assert-ExampleSource -Root $portableRoot -Files @('moon.mod.json', 'main\moon.pkg', 'main\main.mbt')
}
if ($Example -in @('native', 'all')) {
  Assert-ExampleSource -Root $nativeRoot -Files @('moon.mod.json', 'main\moon.pkg', 'main\adapter.mbt', 'main\main.mbt')
}

throw 'RED: public-example execution, source audit, isolation, and report qualification are not implemented yet.'
