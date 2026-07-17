[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$harness = Join-Path $repoRoot 'scripts/benchmarks/Invoke-PpmBenchmarks.ps1'
$baseline = Join-Path $repoRoot 'release/qualification/ppm-native-release-baseline.json'
$benchmarkRoot = Join-Path $repoRoot 'benchmarks/ppm'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-benchmark-negative-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Force -Path $tempRoot

function Assert-BenchmarkIdentity {
  $manifestPath = Join-Path $benchmarkRoot 'moon.mod.json'
  $packagePath = Join-Path $benchmarkRoot 'moon.pkg'
  $manifestText = Get-Content -LiteralPath $manifestPath -Raw
  if ($manifestText -cmatch '"path"\s*:|(?:^|[\\/])[.][.](?:[\\/]|$)') {
    throw 'Benchmark manifest uses a path substitution.'
  }
  $manifest = $manifestText | ConvertFrom-Json -Depth 20
  $expectedDependencies = @('tchivs/mb-core', 'tchivs/mb-image')
  $actualDependencies = @($manifest.deps.PSObject.Properties.Name | Sort-Object)
  if (($actualDependencies -join "`n") -cne (($expectedDependencies | Sort-Object) -join "`n")) {
    throw 'Benchmark manifest dependency set drifted from the canonical graph.'
  }
  foreach ($dependency in $expectedDependencies) {
    if ([string]$manifest.deps.$dependency -cne '0.1.0') {
      throw "Benchmark dependency '$dependency' is not pinned to exact 0.1.0."
    }
  }

  $packageText = Get-Content -LiteralPath $packagePath -Raw
  $actualImports = @([regex]::Matches($packageText, '"([A-Za-z0-9._/-]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object)
  $expectedImports = @(
    'moonbitlang/core/bench',
    'tchivs/mb-core/budget',
    'tchivs/mb-core/bytes',
    'tchivs/mb-core/error',
    'tchivs/mb-core/io',
    'tchivs/mb-image/codec',
    'tchivs/mb-image/ops',
    'tchivs/mb-image/ppm',
    'tchivs/mb-image/storage'
  ) | Sort-Object
  if (($actualImports -join "`n") -cne ($expectedImports -join "`n")) {
    throw 'Benchmark package imports drifted from the canonical allowlist.'
  }
}

function Get-CurrentBenchmarkSourceDigest {
  $sourceText = (Get-Content -Raw (Join-Path $benchmarkRoot 'moon.pkg')) +
    (Get-Content -Raw (Join-Path $benchmarkRoot 'ppm_bench.mbt'))
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    ([Convert]::ToHexString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($sourceText)))).ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Write-CanonicalBaselineCopy([string]$Path, [scriptblock]$Mutate) {
  $record = Get-Content -Raw $baseline | ConvertFrom-Json
  $record.benchmark_source_sha256 = Get-CurrentBenchmarkSourceDigest
  if ($null -ne $Mutate) { & $Mutate $record }
  [IO.File]::WriteAllText($Path, (($record | ConvertTo-Json -Depth 12) + "`n"), [Text.UTF8Encoding]::new($false))
}

function Invoke-ExpectedFailure([string]$Id, [scriptblock]$Mutate) {
  $copy = Join-Path $tempRoot "$Id.json"
  Write-CanonicalBaselineCopy -Path $copy -Mutate $Mutate
  & pwsh -NoProfile -File $harness -Check -SkipMeasurement -BaselinePath $copy *> $null
  if ($LASTEXITCODE -eq 0) { throw "Benchmark negative unexpectedly passed: $Id" }
  Write-Host "Benchmark negative rejected: $Id"
}

try {
  Assert-BenchmarkIdentity
  $positive = Join-Path $tempRoot 'canonical-positive.json'
  Write-CanonicalBaselineCopy -Path $positive -Mutate $null
  & pwsh -NoProfile -File $harness -Check -SkipMeasurement -BaselinePath $positive
  if ($LASTEXITCODE -ne 0) { throw 'Static benchmark baseline validation failed' }
  Invoke-ExpectedFailure 'BENCH01-EXTRA-CLAIM' { param($r) $r | Add-Member NoteProperty marketing_claim 'fastest codec' }
  Invoke-ExpectedFailure 'BENCH02-ORDER' { param($r) [Array]::Reverse($r.workloads) }
  Invoke-ExpectedFailure 'BENCH03-ENVIRONMENT' { param($r) $r.environment.PSObject.Properties.Remove('cpu') }
  Invoke-ExpectedFailure 'BENCH04-DIGEST' { param($r) $r.workloads[0].correctness_sha256 = ('0' * 64) }
  Invoke-ExpectedFailure 'BENCH05-SAMPLES' { param($r) $r.workloads[0].samples_ms = @($r.workloads[0].samples_ms | Select-Object -First 6) }
  Write-Host 'Benchmark qualification passed: closed schema, exact order/digests, seven samples, no marketing fields.'
} finally {
  Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
