[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Assert-Policy.ps1')

function Write-TestJson([string]$Path, [object]$Value) {
  $Value | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Path -Encoding utf8
}

function New-TestManifest([string]$Path, [string]$Digest) {
  return [ordered]@{
    schema_version = '1.0.0'
    preferred_origin = 'generated'
    required_record_fields = @('id','path','origin','source','author','retrieval_date','sha256','license','redistribution_status','expected_use')
    allowed_origins = @('generated','external')
    allowed_redistribution_statuses = @('confirmed','not-applicable','unconfirmed')
    external_requires_confirmed_redistribution = $true
    records = @([ordered]@{
      id='fixture-1'; path=$Path; origin='generated'; source='test generator'; author='MNF'; retrieval_date='2026-07-16'
      sha256=$Digest; license='Apache-2.0'; redistribution_status='not-applicable'; expected_use='validator test'
    })
  }
}

function Invoke-FixtureCase([string]$Name, [scriptblock]$Arrange, [bool]$ShouldPass, [string]$ExpectedFailurePattern) {
  $root = Join-Path ([System.IO.Path]::GetTempPath()) ('mnf-fixture-' + [guid]::NewGuid().ToString('N'))
  [void](New-Item -ItemType Directory -Force -Path (Join-Path $root 'fixtures'))
  try {
    $fixturePath = Join-Path $root 'fixtures/valid.bin'
    [System.IO.File]::WriteAllBytes($fixturePath, [byte[]](0,1,2,3,255))
    $digest = (Get-FileHash -LiteralPath $fixturePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $manifest = New-TestManifest -Path 'fixtures/valid.bin' -Digest $digest
    if ($Arrange) { & $Arrange $root $manifest }
    Write-TestJson -Path (Join-Path $root 'fixtures/manifest.json') -Value $manifest
    $passed = $true
    $failure = $null
    try { Assert-FixtureManifest -ManifestPath (Join-Path $root 'fixtures/manifest.json') -RepositoryRoot $root }
    catch { $passed = $false; $failure = $_.Exception.Message }
    if ($ShouldPass -and -not $passed) { throw "Fixture case '$Name' expected success but failed: $failure" }
    if (-not $ShouldPass -and ($passed -or $failure -cnotmatch $ExpectedFailurePattern)) { throw "Fixture case '$Name' expected failure '$ExpectedFailurePattern'; got '$failure'." }
    Write-Host "PASS: $Name"
  } finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
  }
}

Invoke-FixtureCase 'valid fixture digest' $null $true $null
Invoke-FixtureCase 'mismatched fixture digest' { param($root,$manifest) $manifest.records[0].sha256='0' * 64 } $false 'SHA-256 does not match'
Invoke-FixtureCase 'missing fixture file' { param($root,$manifest) $manifest.records[0].path='fixtures/missing.bin' } $false 'component.*does not exist'
Invoke-FixtureCase 'parent traversal fixture path' { param($root,$manifest) $manifest.records[0].path='../outside.bin' } $false 'parent traversal'
Invoke-FixtureCase 'rooted fixture path' { param($root,$manifest) $manifest.records[0].path=(Join-Path $root 'fixtures/valid.bin') } $false 'repository-relative'
Invoke-FixtureCase 'external fixture requires immutable confirmation policy' { param($root,$manifest) $manifest.external_requires_confirmed_redistribution=$false;$manifest.records[0].origin='external';$manifest.records[0].redistribution_status='unconfirmed' } $false 'must always require confirmed redistribution'
Invoke-FixtureCase 'allowed origin set is canonical' { param($root,$manifest) $manifest.allowed_origins+=@('unknown') } $false 'Fixture allowed origins count mismatch'
Invoke-FixtureCase 'redistribution status set is canonical' { param($root,$manifest) $manifest.allowed_redistribution_statuses=@('unconfirmed') } $false 'Fixture redistribution statuses count mismatch'
Invoke-FixtureCase 'retrieval date rejects invalid month' { param($root,$manifest) $manifest.records[0].retrieval_date='2026-99-01' } $false 'invalid retrieval date'
Invoke-FixtureCase 'retrieval date rejects invalid day' { param($root,$manifest) $manifest.records[0].retrieval_date='2026-02-30' } $false 'invalid retrieval date'
Invoke-FixtureCase 'retrieval date rejects non-leap February 29' { param($root,$manifest) $manifest.records[0].retrieval_date='2025-02-29' } $false 'invalid retrieval date'
Invoke-FixtureCase 'retrieval date accepts leap February 29' { param($root,$manifest) $manifest.records[0].retrieval_date='2024-02-29' } $true $null

$external = Join-Path ([System.IO.Path]::GetTempPath()) ('mnf-fixture-external-' + [guid]::NewGuid().ToString('N') + '.bin')
try {
  [System.IO.File]::WriteAllBytes($external, [byte[]](4,5,6))
  Invoke-FixtureCase 'fixture symlink escape' {
    param($root,$manifest)
    $link = Join-Path $root 'fixtures/link.bin'
    [void](New-Item -ItemType SymbolicLink -Path $link -Target $external -ErrorAction Stop)
    $manifest.records[0].path='fixtures/link.bin'
    $manifest.records[0].sha256=(Get-FileHash -LiteralPath $external -Algorithm SHA256).Hash.ToLowerInvariant()
  } $false 'symbolic link or reparse point'
} finally {
  Remove-Item -LiteralPath $external -Force -ErrorAction SilentlyContinue
}

Write-Host 'Fixture identity and containment matrix passed.'
