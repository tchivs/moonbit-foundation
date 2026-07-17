[CmdletBinding()]
param(
  [switch]$Focused,
  [string]$StaticLedger = 'release/qualification/v0.1-requirements.json',
  [string[]]$VerifyTwoRuns
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')
$ledgerPath = if ([IO.Path]::IsPathRooted($StaticLedger)) { [IO.Path]::GetFullPath($StaticLedger) } else { [IO.Path]::GetFullPath((Join-Path $repoRoot $StaticLedger)) }
$ledger = Assert-StaticRequirementLedger -Path $ledgerPath
Write-Host "Static v0.1 requirement ledger passed: $(@($ledger.selectors).Count) selectors, $(@($ledger.requirements.PSObject.Properties).Count) requirements, $(@($ledger.artifact_contracts).Count) artifact contracts."

if ($Focused) {
  $focusedDirectory = 'artifacts/release-qualification/focused'
  & (Join-Path $repoRoot 'scripts\quality.ps1') -Lane Required -EvidenceDirectory $focusedDirectory
  if ($LASTEXITCODE -ne 0) { throw 'Focused release qualification failed.' }
  $report = Assert-RequiredQualificationReport -Path (Join-Path $repoRoot "$focusedDirectory\report.json") -LedgerPath $ledgerPath
  Write-Host "Focused release qualification passed at HEAD $($report.head) with digest $($report.deterministic_evidence_digest)."
}

if ($null -ne $VerifyTwoRuns -and $VerifyTwoRuns.Count -ne 0) {
  $runPaths = @($VerifyTwoRuns | ForEach-Object { $_ -split ',' } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  if ($runPaths.Count -ne 2) { throw "-VerifyTwoRuns requires exactly two report paths; got $($runPaths.Count)." }
  $reports = @()
  foreach ($path in $runPaths) {
    $absolute = if ([IO.Path]::IsPathRooted($path)) { [IO.Path]::GetFullPath($path) } else { [IO.Path]::GetFullPath((Join-Path $repoRoot $path)) }
    $reports += Assert-RequiredQualificationReport -Path $absolute -LedgerPath $ledgerPath
  }
  if ($reports[0].head -cne $reports[1].head) { throw 'Required reports name different committed HEADs.' }
  if ($reports[0].deterministic_evidence_digest -cne $reports[1].deterministic_evidence_digest) {
    throw 'Required reports have different canonical deterministic evidence digests.'
  }
  $stableA = Get-RequiredRunStableObject -Report $reports[0] | ConvertTo-Json -Depth 100 -Compress
  $stableB = Get-RequiredRunStableObject -Report $reports[1] | ConvertTo-Json -Depth 100 -Compress
  if ($stableA -cne $stableB) { throw 'Required reports differ outside the declared run-local fields.' }
  Write-Host "Two-run qualification passed at HEAD $($reports[0].head) with canonical digest $($reports[0].deterministic_evidence_digest)."
}
