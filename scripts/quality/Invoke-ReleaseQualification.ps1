[CmdletBinding()]
param(
  [switch]$Check,
  [switch]$StaticOnly,
  [string]$PolicyPath = 'policy/release-qualification.json',
  [string]$OutputDirectory = 'artifacts/release-qualification/current'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')

$absolutePolicy = if ([IO.Path]::IsPathRooted($PolicyPath)) { $PolicyPath } else { Join-Path $repoRoot $PolicyPath }
$policy = Assert-ReleasePolicy `
  -PolicyPath $absolutePolicy `
  -FoundationPath (Join-Path $repoRoot 'policy\foundation.json') `
  -FixtureManifestPath (Join-Path $repoRoot 'fixtures\manifest.json') `
  -SchemaPath (Join-Path $repoRoot 'release\qualification\package-schema.json') `
  -RepoRoot $repoRoot

Write-Host 'Release policy: pass (closed modules, manifests, dependencies, contents, provenance, outcomes, and post-publication order).'
if ($StaticOnly) { return }

throw 'Dynamic release qualification is not implemented yet.'
