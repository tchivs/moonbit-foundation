[CmdletBinding()]
param(
  [switch]$ContractOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$harness = Join-Path $repoRoot 'scripts/benchmarks/Invoke-PpmBenchmarks.ps1'
$baseline = Join-Path $repoRoot 'release/qualification/ppm-native-release-baseline.json'
$benchmarkRoot = Join-Path $repoRoot 'benchmarks/ppm'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-benchmark-negative-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Force -Path $tempRoot
$cffHarness = Join-Path $repoRoot 'scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1'
$cffBenchmark = Join-Path $repoRoot 'benchmarks/font-cff/cff_bench.mbt'
$benchmarkWorkspace = Join-Path $repoRoot 'benchmarks/moon.work'

function Assert-ExactText([string]$Actual, [string]$Expected, [string]$Label) {
  $normalized = $Actual.Replace("`r`n", "`n").Replace("`r", "`n")
  if ($normalized -cne $Expected) {
    throw "$Label drifted from the exact closed contract."
  }
}

function Assert-CffBenchmarkSourceContract {
  $expectedWorkspace = @'
members = [
  "../modules/mb-core",
  "../modules/mb-color",
  "../modules/mb-image",
  "../modules/mb-font",
  "./ppm",
  "./font-cff",
]
'@.Replace("`r`n", "`n") + "`n"
  Assert-ExactText (Get-Content -Raw -LiteralPath $benchmarkWorkspace) `
    $expectedWorkspace 'CFF benchmark workspace'

  if (-not (Test-Path -LiteralPath $cffBenchmark -PathType Leaf)) {
    throw 'CFF benchmark source is missing.'
  }
  $source = Get-Content -Raw -LiteralPath $cffBenchmark
  $tests = @(
    [regex]::Matches(
      $source,
      '(?m)^test "bench cff/(?<name>[^"]+)" \(b : @bench[.]T\) \{$'
    ) | ForEach-Object { $_.Groups['name'].Value }
  )
  $expectedTests = @(
    'latin-full-admission',
    'cjk-full-admission',
    'latin-fixed-outline-batch',
    'cjk-high-gid-multi-fd-outline-batch'
  )
  if (($tests -join "`n") -cne ($expectedTests -join "`n")) {
    throw 'CFF benchmark workload names or source order drifted.'
  }
  if ([regex]::Matches($source, '@bench[.]T').Count -ne 4) {
    throw 'CFF benchmark source must contain exactly four benchmark tests.'
  }
  foreach ($required in @(
      'cff_evidence_source_sans_payload()',
      'cff_evidence_source_han_payload()',
      'cff_evidence_workloads()',
      'cff_benchmark_budget()',
      'b.bench(fn()',
      'b.keep('
    )) {
    if (-not $source.Contains($required)) {
      throw "CFF benchmark source is missing required contract: $required"
    }
  }
  if ($source -cmatch '(?i)\b(?:read_file|open_file|filesystem|ffi|extern)\b' -or
      $source -cmatch '(?m)^\s*(?:let|const)\s+\w+\s*=\s*\[(?:\s*(?:b)?''\\x[0-9A-Fa-f]{2}'',?){16,}') {
    throw 'CFF benchmark source duplicates payload bytes or performs runtime I/O/FFI.'
  }
  if ($source -cmatch '(?i)\b(?:reset|reuse|shared_budget|mutable_budget)\b') {
    throw 'CFF benchmark source contains a forbidden Budget reuse/reset seam.'
  }
}

function Assert-CffBenchmarkHarnessContract {
  if (-not (Test-Path -LiteralPath $cffHarness -PathType Leaf)) {
    throw 'CFF native baseline harness is missing.'
  }
  $source = Get-Content -Raw -LiteralPath $cffHarness
  foreach ($required in @(
      "[switch]`$CheckWorkspaceResolution",
      "[switch]`$ContractOnly",
      "[switch]`$Record",
      "[switch]`$Audit",
      "`$nativeCommand = 'moon -C benchmarks bench font-cff/cff_bench.mbt --release --target native --frozen'",
      'one excluded warmup',
      'seven retained',
      'sample_standard_deviation_ms',
      'coefficient_of_variation',
      'observation_only'
    )) {
    if (-not $source.Contains($required)) {
      throw "CFF native baseline harness is missing required contract: $required"
    }
  }
  foreach ($forbidden in @(
      '[string]$Command',
      '[string]$Target',
      '[string]$Workload',
      '[string]$Output',
      '[int]$SampleCount',
      '--package',
      '--file',
      '--index'
    )) {
    if ($source.Contains($forbidden)) {
      throw "CFF native baseline harness exposes forbidden caller control: $forbidden"
    }
  }
  & $cffHarness -ContractOnly
}

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
  Assert-CffBenchmarkSourceContract
  Assert-CffBenchmarkHarnessContract
  if ($ContractOnly) {
    Write-Host 'CFF benchmark qualification contract passed.'
    return
  }
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
