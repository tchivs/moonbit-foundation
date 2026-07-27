[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('Required', 'FontQualification', 'LlvmExperimental')]
  [string]$Lane,
  [string]$EvidenceDirectory = 'artifacts/release-qualification/current'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$previousLocation = Get-Location
try {
  Set-Location -LiteralPath $repoRoot
  if ($Lane -ceq 'FontQualification') {
    & (Join-Path $PSScriptRoot 'quality/Invoke-FontQualification.ps1') -EvidenceDirectory $EvidenceDirectory
  } else {
    & (Join-Path $PSScriptRoot 'quality/Invoke-MoonQuality.ps1') -Lane $Lane -EvidenceDirectory $EvidenceDirectory
  }
  if (-not $?) {
    throw "Quality lane '$Lane' failed."
  }
} finally {
  Set-Location -LiteralPath $previousLocation
}
