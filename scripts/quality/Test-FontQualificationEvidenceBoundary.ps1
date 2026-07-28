$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'Invoke-FontQualification.ps1') -ImportOnly

if ($EvidenceMarkerSchema -cne 'mnf-font-qualification-evidence/v2') {
  throw "Evidence marker schema must be v2; received '$EvidenceMarkerSchema'."
}
if ($EvidenceWorkflowId -cne 'font-complete-public-v2') {
  throw "Evidence workflow must be v2; received '$EvidenceWorkflowId'."
}
$expectedRecordKeys = @(
  'schema_version',
  'workflow_id',
  'target',
  'toolchain',
  'fixtures',
  'standalone_baseline',
  'generated_collection_facts',
  'licensed_derivative_facts',
  'collection_hostile_outcomes',
  'mutation_atomicity_facts',
  'boundary_facts',
  'dependency_facts',
  'focused_assertions',
  'source_identities',
  'runner',
  'pass'
)
if ((Compare-Object -CaseSensitive $expectedRecordKeys $RecordKeys)) {
  throw 'Target evidence record keys must match the closed v2 schema.'
}
$defaultEvidenceDirectory = (
  Get-Command Invoke-FontQualification
).Parameters['EvidenceDirectory'].Attributes |
  Where-Object { $_ -is [Management.Automation.ParameterAttribute] } |
  Select-Object -First 1
if ($null -eq $defaultEvidenceDirectory) {
  throw 'Import-only runner seam is missing EvidenceDirectory.'
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

  $markerPath = Join-Path $owned $EvidenceMarkerName
  Write-FontQualificationJson `
    -Path $markerPath `
    -Value ([pscustomobject][ordered]@{
      schema = 'mnf-font-qualification-evidence/v1'
      workflow_id = 'font-complete-public-v1'
    })
  [IO.File]::WriteAllText($ownedKnown, 'preserve after version 1 marker')
  Assert-Rejected {
    Clear-FontQualificationEvidenceFiles `
      -Directory $owned `
      -ManagedRoot $managedRoot
  } 'marker is invalid'
  if ([IO.File]::ReadAllText($ownedKnown) -cne 'preserve after version 1 marker') {
    throw 'Version 1 marker authorized version 2 cleanup.'
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
