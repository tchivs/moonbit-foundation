[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('js', 'wasm', 'wasm-gc', 'native')]
  [string]$Target
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$targetDirectory = Join-Path $repositoryRoot (Join-Path '_build\png-encode-evidence' $Target)
$filter = '*PNG encoder isolated four-target evidence*'
$arguments = @(
  '-C', 'modules/mb-image', 'test', 'png', '--target', $Target,
  '--target-dir', $targetDirectory, '--frozen', '-f', $filter
)

Push-Location $repositoryRoot
try {
  & moon @arguments
  $result = $LASTEXITCODE
} finally {
  Pop-Location
}

if ($result -ne 0) {
  Write-Error "PNG encode evidence target=$Target result=failed exit=$result"
  exit $result
}

Write-Output "PNG encode evidence target=$Target result=passed"
