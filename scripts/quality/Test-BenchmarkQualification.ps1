[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$harness = Join-Path $repoRoot 'scripts/benchmarks/Invoke-PpmBenchmarks.ps1'
$baseline = Join-Path $repoRoot 'release/qualification/ppm-native-release-baseline.json'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-benchmark-negative-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Force -Path $tempRoot

function Invoke-ExpectedFailure([string]$Id, [scriptblock]$Mutate) {
  $copy = Join-Path $tempRoot "$Id.json"
  $record = Get-Content -Raw $baseline | ConvertFrom-Json
  & $Mutate $record
  [IO.File]::WriteAllText($copy, (($record | ConvertTo-Json -Depth 12) + "`n"), [Text.UTF8Encoding]::new($false))
  & pwsh -NoProfile -File $harness -Check -SkipMeasurement -BaselinePath $copy *> $null
  if ($LASTEXITCODE -eq 0) { throw "Benchmark negative unexpectedly passed: $Id" }
  Write-Host "Benchmark negative rejected: $Id"
}

try {
  & pwsh -NoProfile -File $harness -Check -SkipMeasurement -BaselinePath $baseline
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
