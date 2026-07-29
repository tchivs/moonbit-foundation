[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$HostToolchainInputPath,

  [Parameter(Mandatory)]
  [string]$ExecutionHandoffPath,

  [Parameter(Mandatory)]
  [string]$StagingRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provisionerPath = Join-Path $PSScriptRoot 'Provision-CffQualificationTools.ps1'
$generatorPath = Join-Path $PSScriptRoot 'Generate-FontQualification.ps1'
$lockPath = Join-Path $repositoryRoot 'fixtures/font/cff/host-toolchain.lock.json'
$fontToolsAdapterPath = Join-Path $PSScriptRoot 'oracles/fonttools_cff_oracle.py'
$afdkoAdapterPath = Join-Path $PSScriptRoot 'oracles/Invoke-AfdkoCffOracle.ps1'

foreach ($path in @(
    $provisionerPath,
    $generatorPath,
    $lockPath,
    $fontToolsAdapterPath,
    $afdkoAdapterPath
  )) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Task 1 contract file is missing: $path"
  }
}

$lock = Get-Content -Raw -LiteralPath $lockPath | ConvertFrom-Json
if ($lock.schema -cne 'host-toolchain-lock/1.0.0') {
  throw 'Host-toolchain lock schema drifted.'
}

$expectedRoleIds = @(
  'runtime.cpython',
  'build.meson',
  'build.ninja',
  'compiler.c',
  'compiler.cpp',
  'linker',
  'build.archiver',
  'build.strip',
  'build.windres',
  'runtime.libcxx',
  'runtime.libunwind',
  'sdk.llvm-mingw-x86_64',
  'config.meson-native',
  'config.timersub-compat',
  'source.ots',
  'source.zlib',
  'patch.zlib',
  'source.woff2',
  'patch.woff2',
  'source.brotli',
  'patch.brotli',
  'source.lz4',
  'patch.lz4',
  'source.gtest',
  'patch.gtest',
  'package.cpython-embed',
  'package.meson-wheel',
  'package.ninja-wheel'
)
if ((Compare-Object -CaseSensitive $expectedRoleIds @($lock.ordered_role_ids))) {
  throw 'Host-toolchain lock role order drifted.'
}

$fontToolsSource = Get-Content -Raw -LiteralPath $fontToolsAdapterPath
$afdkoSource = Get-Content -Raw -LiteralPath $afdkoAdapterPath
if ($fontToolsSource -match '(?im)^\s*(from|import)\s+afdko\b') {
  throw 'fontTools adapter aliases the AFDKO semantic backend.'
}
if ($afdkoSource -match '(?im)\bfonttools\b') {
  throw 'AFDKO adapter aliases the fontTools semantic backend.'
}

& $provisionerPath `
  -HostToolchainInputPath $HostToolchainInputPath `
  -ExecutionHandoffPath $ExecutionHandoffPath `
  -StagingRoot $StagingRoot `
  -Check

& $generatorPath `
  -CheckGeneratedTracer `
  -ExecutionHandoffPath $ExecutionHandoffPath `
  -ProvisionedToolsRoot $StagingRoot

Write-Host 'CFF qualification tool contract tests passed.'
