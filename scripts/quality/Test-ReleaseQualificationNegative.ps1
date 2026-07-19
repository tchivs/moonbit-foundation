[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')
. (Join-Path $PSScriptRoot 'Assert-Policy.ps1')

$releasePolicy = Join-Path $repoRoot 'policy\release-qualification.json'
$foundationPolicy = Join-Path $repoRoot 'policy\foundation.json'
$fixtureManifest = Join-Path $repoRoot 'fixtures\manifest.json'
$negativeRoot = Join-Path $repoRoot 'qualification\negative'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-release-negative-' + [Guid]::NewGuid().ToString('N'))

function Write-NegativeJson {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][object]$Value)
  $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path)
  [IO.File]::WriteAllText($Path, (($Value | ConvertTo-Json -Depth 100) + "`n"), [Text.UTF8Encoding]::new($false))
}

function Confirm-ExactRule {
  param(
    [Parameter(Mandatory)][string]$Id,
    [Parameter(Mandatory)][scriptblock]$Action
  )
  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure -or -not $failure.StartsWith("$Id`: ", [StringComparison]::Ordinal)) {
    throw "Negative '$Id' passed or failed for the wrong reason: '$failure'."
  }
  Write-Host "Release negative rejected: $Id"
}

function Copy-NegativeFixture {
  param([Parameter(Mandatory)][string]$RelativePath)
  $source = Join-Path $negativeRoot $RelativePath
  $destination = Join-Path $tempRoot $RelativePath
  $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination)
  Copy-Item -LiteralPath $source -Destination $destination
  return $destination
}

function New-MutatedFoundation {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][scriptblock]$Mutate)
  $value = Read-ReleaseJson -Path $foundationPolicy
  & $Mutate $value
  $path = Join-Path $tempRoot "$Id.foundation.json"
  Write-NegativeJson -Path $path -Value $value
  return $path
}

function New-NegativeZip {
  param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$EntryName)
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $file=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
  try{
    $archive=[IO.Compression.ZipArchive]::new($file,[IO.Compression.ZipArchiveMode]::Create,$true)
    try{$entry=$archive.CreateEntry($EntryName,[IO.Compression.CompressionLevel]::Optimal);$stream=$entry.Open();try{$stream.WriteByte(0x41)}finally{$stream.Dispose()}}finally{$archive.Dispose()}
  }finally{$file.Dispose()}
}

function Set-NegativeZipMetadataVariant {
  param([Parameter(Mandatory)][string]$Path)
  $bytes=[IO.File]::ReadAllBytes($Path);$changed=$false
  for($offset=0;$offset-le$bytes.Length-46;$offset++){
    if($bytes[$offset]-eq0x50-and$bytes[$offset+1]-eq0x4b-and$bytes[$offset+2]-eq0x01-and$bytes[$offset+3]-eq0x02){$bytes[$offset+5]=0;$changed=$true;break}
  }
  if(-not$changed){throw 'REL-XPLAT-TEST: central entry is missing.'}
  [IO.File]::WriteAllBytes($Path,$bytes)
}

$null = New-Item -ItemType Directory -Force -Path $tempRoot
try {
  $fixtureHashes = @{}
  foreach ($relative in @(
    'path-dependency\mb-color.moon.mod.json',
    'higher-layer-dependency\mb-core.moon.pkg',
    'unexpected-package\package-list.txt',
    'false-registry-pass\report.json'
  )) {
    $fixtureHashes[$relative] = Get-ReleaseSha256 -Path (Join-Path $negativeRoot $relative)
  }

  Confirm-ExactRule 'REL03-PATH-SUBSTITUTION' {
    Assert-ReleaseManifestDependencies -ShortName 'mb-color' -ManifestPath (Copy-NegativeFixture 'path-dependency\mb-color.moon.mod.json') -PolicyPath $releasePolicy
  }
  Confirm-ExactRule 'REL04-HIGHER-LAYER-DEPENDENCY' {
    Assert-ReleaseModuleImports -ShortName 'mb-core' -PackagePath (Copy-NegativeFixture 'higher-layer-dependency\mb-core.moon.pkg')
  }
  Confirm-ExactRule 'REL05-ARCHIVE-ENTRY' {
    Assert-ReleasePackageList -ShortName 'mb-core' -ListPath (Copy-NegativeFixture 'unexpected-package\package-list.txt') -PolicyPath $releasePolicy
  }
  Confirm-ExactRule 'REL02-FABRICATED-REGISTRY-PASS' {
    Assert-ReleaseCandidateOutcomes -ReportPath (Copy-NegativeFixture 'false-registry-pass\report.json')
  }

  $ppmCases = @(
    @{ id = 'PPM01-MISSING-IMPORT'; mutate = { param($p) $ppm = @($p.modules | Where-Object path -ceq 'modules/mb-image')[0].public_packages | Where-Object path -ceq 'ppm'; $ppm.allowed_imports = @($ppm.allowed_imports | Select-Object -Skip 1) } },
    @{ id = 'PPM02-EXTRA-IMPORT'; mutate = { param($p) $ppm = @($p.modules | Where-Object path -ceq 'modules/mb-image')[0].public_packages | Where-Object path -ceq 'ppm'; $ppm.allowed_imports += 'tchivs/mb-image/ops' } },
    @{ id = 'PPM03-WRONG-TARGET'; mutate = { param($p) $ppm = @($p.modules | Where-Object path -ceq 'modules/mb-image')[0].public_packages | Where-Object path -ceq 'ppm'; $ppm.supported_targets = @('js', 'wasm', 'native') } },
    @{ id = 'PPM04-MISSING-INTERFACE'; mutate = { param($p) $ppm = @($p.modules | Where-Object path -ceq 'modules/mb-image')[0].public_packages | Where-Object path -ceq 'ppm'; $ppm.semantic_interface = @($ppm.semantic_interface | Select-Object -SkipLast 1) } },
    @{ id = 'PPM05-EXTRA-INTERFACE'; mutate = { param($p) $ppm = @($p.modules | Where-Object path -ceq 'modules/mb-image')[0].public_packages | Where-Object path -ceq 'ppm'; $ppm.semantic_interface += 'pub fn forbidden_registry() -> Unit' } },
    @{ id = 'PPM06-WRONG-PUBLICATION-ORDER'; mutate = { param($p) $image = @($p.modules | Where-Object path -ceq 'modules/mb-image')[0]; [Array]::Reverse($image.public_packages) } },
    @{ id = 'PPM07-UNREGISTERED-CONTENT'; mutate = { param($p) $ppm = @($p.modules | Where-Object path -ceq 'modules/mb-image')[0].public_packages | Where-Object path -ceq 'ppm'; $ppm.production_sources += 'registry.mbt' } }
  )
  foreach ($case in $ppmCases) {
    Confirm-ExactRule $case.id {
      $path = New-MutatedFoundation -Id $case.id -Mutate $case.mutate
      Assert-PpmQualificationContract -FoundationPath $path
    }
  }

  $metadataCases = @(
    @{ id = 'REL08-MISSING-VERSION'; mutate = { param($p) $p.modules.'mb-core'.manifest.PSObject.Properties.Remove('version') } },
    @{ id = 'REL09-WRONG-STATUS'; mutate = { param($p) $p.candidate_status = 'stable' } },
    @{ id = 'REL10-MISSING-LICENSE'; mutate = { param($p) $p.license = '' } },
    @{ id = 'REL11-MISSING-PROVENANCE'; mutate = { param($p) $p.fixture_records = @($p.fixture_records | Select-Object -SkipLast 1) } },
    @{ id = 'REL01-MODULE-ORDER'; mutate = { param($p) [Array]::Reverse($p.module_order) } }
  )
  foreach ($case in $metadataCases) {
    Confirm-ExactRule $case.id {
      $value = Read-ReleaseJson -Path $releasePolicy
      & $case.mutate $value
      $path = Join-Path $tempRoot "$($case.id).release.json"
      Write-NegativeJson -Path $path -Value $value
      Assert-ReleasePolicy -PolicyPath $path -FoundationPath $foundationPolicy -FixtureManifestPath $fixtureManifest -SchemaPath (Join-Path $repoRoot 'release\qualification\package-schema.json') -RepoRoot $repoRoot | Out-Null
    }
  }

  Confirm-ExactRule 'REL12-PROVENANCE-CHECKSUM' {
    $manifest = Read-ReleaseJson -Path $fixtureManifest
    $manifest.records[0].sha256 = ('0' * 64)
    $path = Join-Path $tempRoot 'REL12.fixture-manifest.json'
    Write-NegativeJson -Path $path -Value $manifest
    Assert-ReleasePolicy -PolicyPath $releasePolicy -FoundationPath $foundationPolicy -FixtureManifestPath $path -SchemaPath (Join-Path $repoRoot 'release\qualification\package-schema.json') -RepoRoot $repoRoot | Out-Null
  }
  Confirm-ExactRule 'REL13-ARTIFACT-DIGEST' {
    $artifact = Join-Path $tempRoot 'artifact.bin'
    [IO.File]::WriteAllBytes($artifact, [byte[]](1, 2, 3))
    $expected = Get-ReleaseSha256 -Path $artifact
    [IO.File]::WriteAllBytes($artifact, [byte[]](1, 2, 4))
    Assert-ReleaseHashedArtifact -Path $artifact -ExpectedSha256 $expected
  }
  Assert-ReleaseTrackedSnapshot -Before '' -After ''
  Confirm-ExactRule 'REL14-TRACKED-SOURCE-MUTATION' {
    Assert-ReleaseTrackedSnapshot -Before 'clean-a' -After 'changed-b'
  }
  $unsafeZip=Join-Path $tempRoot 'unsafe-path.zip';New-NegativeZip -Path $unsafeZip -EntryName './moon.mod.json'
  Confirm-ExactRule 'REL-XPLAT-ENTRY' { ConvertTo-ReleaseCanonicalZip -Path $unsafeZip | Out-Null }
  $metadataZip=Join-Path $tempRoot 'metadata-drift.zip';New-NegativeZip -Path $metadataZip -EntryName 'moon.mod.json';$null=ConvertTo-ReleaseCanonicalZip -Path $metadataZip
  $canonicalDigest=Get-ReleaseSha256 -Path $metadataZip;$null=Assert-ReleaseCanonicalZip -Path $metadataZip
  Set-NegativeZipMetadataVariant -Path $metadataZip
  if((Get-ReleaseSha256 -Path $metadataZip)-ceq$canonicalDigest){throw 'REL-XPLAT-TEST: metadata drift did not change raw identity.'}
  Confirm-ExactRule 'REL-XPLAT-NONCANONICAL' { Assert-ReleaseCanonicalZip -Path $metadataZip | Out-Null }

  foreach ($relative in $fixtureHashes.Keys) {
    if ((Get-ReleaseSha256 -Path (Join-Path $negativeRoot $relative)) -cne $fixtureHashes[$relative]) {
      throw "Negative fixture changed during classification: $relative"
    }
  }
  Write-Host 'Release qualification negative matrix passed with exact fail-closed rule ownership.'
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $full = [IO.Path]::GetFullPath($tempRoot)
    if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Split-Path -Leaf $full).StartsWith('mnf-release-negative-', [StringComparison]::Ordinal)) {
      throw "Refusing to remove unverified negative path: $full"
    }
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}
