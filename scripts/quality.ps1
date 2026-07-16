[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('Required', 'LlvmExperimental')]
  [string]$Lane
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$previousLocation = Get-Location
try {
  Set-Location -LiteralPath $repoRoot
  if ($Lane -ceq 'Required') {
    try {
      & (Join-Path $PSScriptRoot 'quality/Test-RfcAcceptance.ps1')
    } catch {
      throw "RFC acceptance test matrix failed: $($_.Exception.Message)"
    }
  }
  . (Join-Path $PSScriptRoot 'quality/Invoke-MoonQuality.ps1')
  Invoke-MoonQuality -Lane $Lane
} finally {
  Set-Location -LiteralPath $previousLocation
}
