[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runner = Join-Path $repoRoot 'scripts\quality\Invoke-ReleaseQualification.ps1'
$policy = Join-Path $repoRoot 'policy\release-qualification.json'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-release-negative-' + [Guid]::NewGuid().ToString('N'))

function Invoke-ExpectedPolicyFailure {
  param(
    [Parameter(Mandatory)][string]$Id,
    [Parameter(Mandatory)][scriptblock]$Mutate
  )

  $copy = Join-Path $tempRoot "$Id.json"
  $record = Get-Content -LiteralPath $policy -Raw | ConvertFrom-Json -Depth 100
  & $Mutate $record
  [IO.File]::WriteAllText($copy, (($record | ConvertTo-Json -Depth 100) + "`n"), [Text.UTF8Encoding]::new($false))
  & pwsh -NoProfile -File $runner -Check -StaticOnly -PolicyPath $copy *> $null
  if ($LASTEXITCODE -eq 0) {
    throw "Release qualification negative unexpectedly passed: $Id"
  }
  Write-Host "Release qualification negative rejected: $Id"
}

if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
  throw "Release qualification runner is missing: $runner"
}
if (-not (Test-Path -LiteralPath $policy -PathType Leaf)) {
  throw "Release qualification policy is missing: $policy"
}

$null = New-Item -ItemType Directory -Force -Path $tempRoot
try {
  & pwsh -NoProfile -File $runner -Check -StaticOnly -PolicyPath $policy
  if ($LASTEXITCODE -ne 0) { throw 'Static release qualification policy validation failed.' }

  Invoke-ExpectedPolicyFailure 'REL01-MODULE-ORDER' {
    param($p)
    [Array]::Reverse($p.module_order)
  }
  Invoke-ExpectedPolicyFailure 'REL02-FABRICATED-REGISTRY-PASS' {
    param($p)
    $p.modules.'mb-color'.registry_resolution = 'pass'
  }
  Invoke-ExpectedPolicyFailure 'REL03-PATH-SUBSTITUTION' {
    param($p)
    $p.modules.'mb-color'.dependencies.'moonbit-foundation/mb-core' = @{ path = '..\mb-core' }
  }
  Invoke-ExpectedPolicyFailure 'REL04-HIGHER-LAYER-DEPENDENCY' {
    param($p)
    $p.modules.'mb-core'.dependencies | Add-Member NoteProperty 'moonbit-foundation/mb-color' '0.1.0'
  }
  Invoke-ExpectedPolicyFailure 'REL05-ARCHIVE-ENTRY' {
    param($p)
    $p.modules.'mb-image'.package_allowlist += '_build/forbidden.bin'
  }
  Invoke-ExpectedPolicyFailure 'REL06-METADATA' {
    param($p)
    $p.modules.'mb-core'.manifest.repository = ''
  }
  Invoke-ExpectedPolicyFailure 'REL07-POSTPUBLISH-ORDER' {
    param($p)
    [Array]::Reverse($p.post_publish_order)
  }

  & pwsh -NoProfile -File $runner -Check -OutputDirectory 'artifacts/release-qualification/required'
  if ($LASTEXITCODE -ne 0) { throw 'Dynamic release qualification failed.' }
  Write-Host 'Release qualification passed: closed policy negatives, deterministic packages, exact core artifact consumer, and honest downstream blockers.'
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $full = [IO.Path]::GetFullPath($tempRoot)
    if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Split-Path -Leaf $full).StartsWith('mnf-release-negative-', [StringComparison]::Ordinal)) {
      throw "Refusing to remove unverified release-negative path: $full"
    }
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}
