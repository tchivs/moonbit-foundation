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

function Assert-ExactDependencyMap {
  param([string]$Label, [object]$Actual, [Collections.Specialized.OrderedDictionary]$Expected)
  $actualProperties = @($Actual.PSObject.Properties)
  Assert-ReleaseExactSequence -Label "$Label keys" -Actual @($actualProperties | ForEach-Object { $_.Name }) -Expected @($Expected.Keys)
  foreach ($key in @($Expected.Keys)) {
    if ([string]$Actual.$key -cne [string]$Expected[$key]) { throw "$Label value drifted for '$key'." }
  }
}

$releasePolicyPath = Join-Path $repoRoot 'policy\release-qualification.json'
$releasePolicy = Read-ReleaseJson -Path $releasePolicyPath
$expectedModuleOrder = @('mb-core', 'mb-color', 'mb-image')
Assert-ReleaseExactSequence -Label 'positive qualification module order' -Actual @($releasePolicy.module_order) -Expected $expectedModuleOrder
$expectedDependencies = [ordered]@{
  'mb-core' = [ordered]@{}
  'mb-color' = [ordered]@{ 'tchivs/mb-core' = '0.1.0' }
  'mb-image' = [ordered]@{ 'tchivs/mb-core' = '0.1.0'; 'tchivs/mb-color' = '0.1.0' }
}
foreach ($shortName in $expectedModuleOrder) {
  $module = $releasePolicy.modules.$shortName
  if ([string]$module.manifest.name -cne "tchivs/$shortName" -or [string]$module.manifest.version -cne '0.1.0') {
    throw "Positive qualification identity drifted for $shortName."
  }
  Assert-ExactDependencyMap -Label "$shortName positive dependency graph" -Actual $module.dependencies -Expected $expectedDependencies[$shortName]
}
$coreConsumer = Read-ReleaseJson -Path (Join-Path $repoRoot 'qualification\consumers\mb-core\moon.mod.json')
Assert-ExactDependencyMap -Label 'positive mb-core consumer dependencies' -Actual $coreConsumer.deps -Expected ([ordered]@{ 'tchivs/mb-core' = '0.1.0' })
Write-Host 'Positive release identity graph passed: tchivs/mb-core -> tchivs/mb-color -> tchivs/mb-image at 0.1.0.'

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
