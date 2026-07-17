[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('Required', 'LlvmExperimental')]
  [string]$Lane,
  [string]$EvidenceDirectory = 'artifacts/release-qualification/current'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$previousLocation = Get-Location
try {
  Set-Location -LiteralPath $repoRoot
  . (Join-Path $PSScriptRoot 'quality/Invoke-MoonQuality.ps1')
  Invoke-MoonQuality -Lane $Lane -EvidenceDirectory $EvidenceDirectory
} finally {
  Set-Location -LiteralPath $previousLocation
}
