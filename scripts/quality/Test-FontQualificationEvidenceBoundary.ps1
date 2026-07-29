$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'Invoke-FontQualification.ps1') -ImportOnly

if ($EvidenceMarkerSchema -cne 'mnf-font-qualification-evidence/v3') {
  throw "Evidence marker schema must be v3; received '$EvidenceMarkerSchema'."
}
if ($EvidenceWorkflowId -cne 'font-complete-public-v3') {
  throw "Evidence workflow must be v3; received '$EvidenceWorkflowId'."
}
$expectedRecordKeys = @(
  'schema_version',
  'workflow_id',
  'target',
  'toolchain',
  'fixtures',
  'oracle_facts',
  'generated_cff_facts',
  'licensed_cff_facts',
  'public_workflow_facts',
  'cff_hostile_outcomes',
  'mutation_atomicity_facts',
  'glyf_compatibility_facts',
  'benchmark_correctness_facts',
  'boundary_facts',
  'dependency_facts',
  'source_identities',
  'focused_assertions',
  'runner',
  'pass'
)
if (($expectedRecordKeys -join "`0") -cne ($RecordKeys -join "`0")) {
  throw 'Target evidence record keys must match the closed ordered v3 schema.'
}
$expectedProducts = @(
  'js.json',
  'wasm.json',
  'wasm-gc.json',
  'native.json',
  'comparison.json'
)
if (($expectedProducts -join "`0") -cne ($EvidenceProductNames -join "`0")) {
  throw 'Evidence cleanup must own exactly five ordered v3 products.'
}
if ((@('target', 'runner') -join "`0") -cne
    ($NormalizationRemoved -join "`0")) {
  throw 'Semantic normalization must remove only top-level target and runner.'
}
$expectedPublicAssertions = @(
  'font-cff1-v3 carrier-public generated-name standalone and selected tracer',
  'font-cff1-v3 carrier-public every standalone and selected workflow',
  'font-cff1-v3 carrier-public caller mutation is exact and atomic',
  'font-cff1-v3 carrier-public timing-free correctness workloads'
)
if (($expectedPublicAssertions -join "`0") -cne
    (@($PublicEvidenceAssertions.name) -join "`0")) {
  throw 'Public CFF evidence assertion identities or order drifted.'
}
$expectedPrivateAssertions = @(
  'font-cff1-v3 private fd oracle',
  'font-cff1-v3 private hostile outcomes',
  'font-cff1-v3 private mutation windows and atomic budgets'
)
if (($expectedPrivateAssertions -join "`0") -cne
    (@($PrivateFocusedAssertions.name) -join "`0")) {
  throw 'Private CFF assertion identities or order drifted.'
}
$runnerCommand = Get-Command Invoke-FontQualification
$defaultEvidenceDirectory = $runnerCommand.Parameters['EvidenceDirectory'].Attributes |
  Where-Object { $_ -is [Management.Automation.ParameterAttribute] } |
  Select-Object -First 1
if ($null -eq $defaultEvidenceDirectory) {
  throw 'Import-only runner seam is missing EvidenceDirectory.'
}
foreach ($parameter in @('ContractOnly', 'Target', 'TracerOnly')) {
  if (-not $runnerCommand.Parameters.ContainsKey($parameter)) {
    throw "Import-only runner seam is missing $parameter."
  }
}

$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
  [IO.Path]::DirectorySeparatorChar,
  [IO.Path]::AltDirectorySeparatorChar
)
$testRoot = Join-Path $temporaryBase (
  'mnf-font-qualification-boundary-' + [Guid]::NewGuid().ToString('N')
)
$managedRoot = Join-Path $testRoot 'managed'
$outsideRoot = Join-Path $testRoot 'caller-owned'
$linkPath = $null
$swapLinks = [Collections.Generic.List[string]]::new()

function Assert-Rejected {
  param(
    [Parameter(Mandatory)][scriptblock]$Action,
    [Parameter(Mandatory)][string]$Pattern
  )

  $failure = $null
  try {
    & $Action
  } catch {
    $failure = $_.Exception.Message
  }
  if ($null -eq $failure -or $failure -cnotmatch $Pattern) {
    throw "Expected rejection matching '$Pattern'; received '$failure'."
  }
}

try {
  [void](New-Item -ItemType Directory -Path $managedRoot -Force)
  [void](New-Item -ItemType Directory -Path $outsideRoot -Force)
  $outsideComparison = Join-Path $outsideRoot 'comparison.json'
  [IO.File]::WriteAllText($outsideComparison, 'caller-owned')

  Assert-Rejected {
    Resolve-FontQualificationEvidencePath `
      -EvidenceDirectory $outsideRoot `
      -ManagedRoot $managedRoot `
      -RepositoryRoot $testRoot
  } 'must be a child'
  Assert-Rejected {
    Resolve-FontQualificationEvidencePath `
      -EvidenceDirectory $managedRoot `
      -ManagedRoot $managedRoot `
      -RepositoryRoot $testRoot
  } 'must be a child'
  if ([IO.File]::ReadAllText($outsideComparison) -cne 'caller-owned') {
    throw 'Rejected caller-owned evidence was mutated.'
  }

  $unowned = Join-Path $managedRoot 'unowned'
  [void](New-Item -ItemType Directory -Path $unowned)
  $unownedJson = Join-Path $unowned 'native.json'
  [IO.File]::WriteAllText($unownedJson, 'caller-owned')
  Assert-Rejected {
    Initialize-FontQualificationEvidenceDirectory `
      -Directory $unowned `
      -ManagedRoot $managedRoot
  } 'non-empty unowned'
  if ([IO.File]::ReadAllText($unownedJson) -cne 'caller-owned') {
    throw 'Unowned managed-subtree evidence was mutated.'
  }

  $owned = Join-Path $managedRoot 'owned'
  Initialize-FontQualificationEvidenceDirectory `
    -Directory $owned `
    -ManagedRoot $managedRoot
  $ownedKnown = Join-Path $owned 'js.json'
  $ownedUnrelated = Join-Path $owned 'notes.json'
  $markerPath = Join-Path $owned $EvidenceMarkerName
  $markerBytes = [IO.File]::ReadAllBytes($markerPath)
  [IO.File]::WriteAllText($ownedKnown, 'stale evidence')
  [IO.File]::WriteAllText($ownedUnrelated, 'preserve me')
  Clear-FontQualificationEvidenceFiles `
    -Directory $owned `
    -ManagedRoot $managedRoot
  if (Test-Path -LiteralPath $ownedKnown) {
    throw 'Known stale evidence was not removed from an owned directory.'
  }
  if ([IO.File]::ReadAllText($ownedUnrelated) -cne 'preserve me') {
    throw 'Cleanup mutated an unrelated file in an owned directory.'
  }
  if (([Convert]::ToHexString([IO.File]::ReadAllBytes($markerPath))) -cne
      ([Convert]::ToHexString($markerBytes))) {
    throw 'Cleanup rewrote the exact v3 ownership marker.'
  }
  Assert-Rejected {
    Write-FontQualificationEvidenceJson `
      -Directory $owned `
      -ManagedRoot $managedRoot `
      -FileName 'notes.json' `
      -Value ([pscustomobject][ordered]@{ probe = $true })
  } 'not a managed qualification record'

  Write-FontQualificationJson `
    -Path $markerPath `
    -Value ([pscustomobject][ordered]@{
      schema = 'mnf-font-qualification-evidence/v2'
      workflow_id = 'font-complete-public-v2'
    })
  [IO.File]::WriteAllText($ownedKnown, 'preserve after version 2 marker')
  Assert-Rejected {
    Clear-FontQualificationEvidenceFiles `
      -Directory $owned `
      -ManagedRoot $managedRoot
  } 'marker is invalid'
  if ([IO.File]::ReadAllText($ownedKnown) -cne 'preserve after version 2 marker') {
    throw 'Version 2 marker authorized version 3 cleanup.'
  }

  [IO.File]::WriteAllText($markerPath, '{"schema":"wrong","workflow_id":"wrong"}')
  [IO.File]::WriteAllText($ownedKnown, 'preserve after marker corruption')
  Assert-Rejected {
    Clear-FontQualificationEvidenceFiles `
      -Directory $owned `
      -ManagedRoot $managedRoot
  } 'marker is invalid'
  if ([IO.File]::ReadAllText($ownedKnown) -cne 'preserve after marker corruption') {
    throw 'Cleanup ran after ownership-marker validation failed.'
  }

  $linkedOutside = Join-Path $outsideRoot 'linked-target'
  [void](New-Item -ItemType Directory -Path $linkedOutside)
  Write-FontQualificationJson `
    -Path (Join-Path $linkedOutside $EvidenceMarkerName) `
    -Value ([pscustomobject][ordered]@{
      schema = $EvidenceMarkerSchema
      workflow_id = $EvidenceWorkflowId
    })
  $linkedOutsideJson = Join-Path $linkedOutside 'js.json'
  [IO.File]::WriteAllText($linkedOutsideJson, 'outside caller-owned evidence')
  $linkPath = Join-Path $managedRoot 'linked-evidence'
  if ([OperatingSystem]::IsWindows()) {
    [void](New-Item -ItemType Junction -Path $linkPath -Target $linkedOutside)
  } else {
    [void](New-Item -ItemType SymbolicLink -Path $linkPath -Target $linkedOutside)
  }
  Assert-Rejected {
    $linked = Resolve-FontQualificationEvidencePath `
      -EvidenceDirectory $linkPath `
      -ManagedRoot $managedRoot `
      -RepositoryRoot $testRoot
    Initialize-FontQualificationEvidenceDirectory `
      -Directory $linked `
      -ManagedRoot $managedRoot
    Clear-FontQualificationEvidenceFiles `
      -Directory $linked `
      -ManagedRoot $managedRoot
  } 'link or reparse point'
  if ([IO.File]::ReadAllText($linkedOutsideJson) -cne 'outside caller-owned evidence') {
    throw 'Rejected linked evidence cleanup mutated the outside js.json.'
  }

  foreach ($swapName in @('target-write-swap', 'comparison-write-swap')) {
    $swapPath = Join-Path $managedRoot $swapName
    Initialize-FontQualificationEvidenceDirectory `
      -Directory $swapPath `
      -ManagedRoot $managedRoot
    Remove-Item -LiteralPath $swapPath -Recurse -Force
    $swapOutside = Join-Path $outsideRoot $swapName
    [void](New-Item -ItemType Directory -Path $swapOutside)
    if ([OperatingSystem]::IsWindows()) {
      [void](New-Item -ItemType Junction -Path $swapPath -Target $swapOutside)
    } else {
      [void](New-Item -ItemType SymbolicLink -Path $swapPath -Target $swapOutside)
    }
    $swapLinks.Add($swapPath)
    $fileName = if ($swapName -ceq 'target-write-swap') {
      'js.json'
    } else {
      'comparison.json'
    }
    Assert-Rejected {
      Write-FontQualificationEvidenceJson `
        -Directory $swapPath `
        -ManagedRoot $managedRoot `
        -FileName $fileName `
        -Value ([pscustomobject][ordered]@{ probe = $true })
    } 'link or reparse point'
    if (Test-Path -LiteralPath (Join-Path $swapOutside $fileName)) {
      throw "Post-initialization $fileName swap escaped the managed evidence root."
    }
  }

  Write-Host 'PASS: font qualification evidence destructive boundaries'
} finally {
  if ($null -ne $linkPath -and (Test-Path -LiteralPath $linkPath)) {
    Remove-Item -LiteralPath $linkPath -Force
  }
  foreach ($swapLink in $swapLinks) {
    if (Test-Path -LiteralPath $swapLink) {
      Remove-Item -LiteralPath $swapLink -Force
    }
  }
  $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
  $requiredPrefix = $temporaryBase + [IO.Path]::DirectorySeparatorChar
  if ($resolvedTestRoot.StartsWith($requiredPrefix, [StringComparison]::OrdinalIgnoreCase) -and
      (Split-Path -Leaf $resolvedTestRoot) -like 'mnf-font-qualification-boundary-*' -and
      (Test-Path -LiteralPath $resolvedTestRoot)) {
    Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
  }
}
