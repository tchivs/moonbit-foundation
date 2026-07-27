$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'Invoke-FontQualification.ps1') -ImportOnly

$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
  [IO.Path]::DirectorySeparatorChar,
  [IO.Path]::AltDirectorySeparatorChar
)
$testRoot = Join-Path $temporaryBase (
  'mnf-font-qualification-boundary-' + [Guid]::NewGuid().ToString('N')
)
$managedRoot = Join-Path $testRoot 'managed'
$outsideRoot = Join-Path $testRoot 'caller-owned'

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
    Initialize-FontQualificationEvidenceDirectory $unowned
  } 'non-empty unowned'
  if ([IO.File]::ReadAllText($unownedJson) -cne 'caller-owned') {
    throw 'Unowned managed-subtree evidence was mutated.'
  }

  $owned = Join-Path $managedRoot 'owned'
  Initialize-FontQualificationEvidenceDirectory $owned
  $ownedKnown = Join-Path $owned 'js.json'
  $ownedUnrelated = Join-Path $owned 'notes.json'
  [IO.File]::WriteAllText($ownedKnown, 'stale evidence')
  [IO.File]::WriteAllText($ownedUnrelated, 'preserve me')
  Clear-FontQualificationEvidenceFiles $owned
  if (Test-Path -LiteralPath $ownedKnown) {
    throw 'Known stale evidence was not removed from an owned directory.'
  }
  if ([IO.File]::ReadAllText($ownedUnrelated) -cne 'preserve me') {
    throw 'Cleanup mutated an unrelated file in an owned directory.'
  }

  $markerPath = Join-Path $owned $EvidenceMarkerName
  [IO.File]::WriteAllText($markerPath, '{"schema":"wrong","workflow_id":"wrong"}')
  [IO.File]::WriteAllText($ownedKnown, 'preserve after marker corruption')
  Assert-Rejected {
    Clear-FontQualificationEvidenceFiles $owned
  } 'marker is invalid'
  if ([IO.File]::ReadAllText($ownedKnown) -cne 'preserve after marker corruption') {
    throw 'Cleanup ran after ownership-marker validation failed.'
  }

  Write-Host 'PASS: font qualification evidence destructive boundaries'
} finally {
  $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
  $requiredPrefix = $temporaryBase + [IO.Path]::DirectorySeparatorChar
  if ($resolvedTestRoot.StartsWith($requiredPrefix, [StringComparison]::OrdinalIgnoreCase) -and
      (Split-Path -Leaf $resolvedTestRoot) -like 'mnf-font-qualification-boundary-*' -and
      (Test-Path -LiteralPath $resolvedTestRoot)) {
    Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
  }
}
