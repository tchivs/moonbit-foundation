[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$generatorPath = Join-Path $PSScriptRoot 'Generate-FontQualification.ps1'
$oracleToolsPath = Join-Path $repositoryRoot 'fixtures/font/cff-oracle-tools.json'
$casesPath = Join-Path $repositoryRoot 'fixtures/font/cff-qualification-cases.json'

foreach ($path in @($generatorPath, $oracleToolsPath, $casesPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Task 2 contract file is missing: $path"
  }
}

$before = @(
  (Get-FileHash -Algorithm SHA256 -LiteralPath $oracleToolsPath).Hash,
  (Get-FileHash -Algorithm SHA256 -LiteralPath $casesPath).Hash
)
foreach ($switchName in @(
    'CheckContracts',
    'CheckGeneratedRecipes',
    'CheckOracleAdapters',
    'CheckSchemaNegatives'
  )) {
  $arguments = @{}
  $arguments[$switchName] = $true
  & $generatorPath @arguments
}
$after = @(
  (Get-FileHash -Algorithm SHA256 -LiteralPath $oracleToolsPath).Hash,
  (Get-FileHash -Algorithm SHA256 -LiteralPath $casesPath).Hash
)
if (($before -join "`n") -cne ($after -join "`n")) {
  throw 'Task 2 read-only checks modified a canonical contract.'
}

Write-Host 'CFF qualification canonical contract tests passed.'
