[CmdletBinding()]
param(
  [switch]$Check,
  [switch]$SkipMeasurement,
  [string]$BaselinePath = 'release/qualification/ppm-native-release-baseline.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$baselineFile = if ([IO.Path]::IsPathRooted($BaselinePath)) { $BaselinePath } else { Join-Path $repoRoot $BaselinePath }
$schemaFile = Join-Path $repoRoot 'release/qualification/benchmark-schema.json'
$workloadNames = @(
  'ppm/decode/64x64', 'ppm/decode/256x256', 'ppm/decode/1024x1024',
  'ppm/encode/64x64', 'ppm/encode/256x256', 'ppm/encode/1024x1024',
  'ppm/reject/header-token-limit', 'ppm/pipeline/decode-flip-encode/256x256'
)

function Get-Sha256Bytes([byte[]]$Bytes) {
  $sha = [Security.Cryptography.SHA256]::Create()
  try { ([Convert]::ToHexString($sha.ComputeHash($Bytes))).ToLowerInvariant() } finally { $sha.Dispose() }
}

function Get-Sha256Text([string]$Text) {
  Get-Sha256Bytes ([Text.Encoding]::UTF8.GetBytes($Text))
}

function Get-Sha256File([string]$Path) {
  (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function New-PixelBytes([int]$Width, [int]$Height, [bool]$Flipped) {
  $bytes = [byte[]]::new($Width * $Height * 3)
  $offset = 0
  for ($y = 0; $y -lt $Height; $y++) {
    for ($x = 0; $x -lt $Width; $x++) {
      $sourceX = if ($Flipped) { $Width - 1 - $x } else { $x }
      for ($channel = 0; $channel -lt 3; $channel++) {
        $index = (($y * $Width + $sourceX) * 3 + $channel)
        $bytes[$offset++] = [byte](($index * 17 + 31) % 256)
      }
    }
  }
  $bytes
}

function New-PpmBytes([int]$Width, [int]$Height, [bool]$Flipped) {
  $header = [Text.Encoding]::ASCII.GetBytes("P6`n$Width $Height`n255`n")
  $pixels = New-PixelBytes $Width $Height $Flipped
  $result = [byte[]]::new($header.Length + $pixels.Length)
  [Array]::Copy($header, 0, $result, 0, $header.Length)
  [Array]::Copy($pixels, 0, $result, $header.Length, $pixels.Length)
  $result
}

function Get-CorrectnessDigests {
  $records = [ordered]@{}
  foreach ($size in @(64, 256, 1024)) {
    $ppm = New-PpmBytes $size $size $false
    $pixels = New-PixelBytes $size $size $false
    $records["ppm/decode/${size}x${size}"] = @{ corpus = Get-Sha256Bytes $ppm; correctness = Get-Sha256Bytes $pixels }
    $records["ppm/encode/${size}x${size}"] = @{ corpus = Get-Sha256Bytes $ppm; correctness = Get-Sha256Bytes $ppm }
  }
  $reject = [Text.Encoding]::ASCII.GetBytes("P6`n12345 1`n255`n")
  $records['ppm/reject/header-token-limit'] = @{
    corpus = Get-Sha256Bytes $reject
    correctness = Get-Sha256Text 'Resource|BudgetExceeded|ppm-header|header-token-bytes'
  }
  $source = New-PpmBytes 256 256 $false
  $flipped = New-PpmBytes 256 256 $true
  $records['ppm/pipeline/decode-flip-encode/256x256'] = @{
    corpus = Get-Sha256Bytes $source
    correctness = Get-Sha256Bytes $flipped
  }
  $records
}

function Get-ToolLine([string]$Command, [string[]]$Arguments) {
  $text = (& $Command @Arguments 2>&1 | Out-String).Trim()
  if ($LASTEXITCODE -ne 0) { throw "$Command identity failed" }
  ($text -split "`r?`n")[0].Trim()
}

function Get-EnvironmentRecord {
  $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
  $computer = Get-CimInstance Win32_ComputerSystem
  $cpuName = ([string]$cpu.Name).Trim()
  $cores = [int]$cpu.NumberOfLogicalProcessors
  $memory = [long]$computer.TotalPhysicalMemory
  $fingerprint = Get-Sha256Text "$cpuName|$cores|$memory"
  [ordered]@{
    moon = Get-ToolLine 'moon' @('--version')
    moonc = Get-ToolLine 'moonc' @('-v')
    moonrun = Get-ToolLine 'moonrun' @('--version')
    os = [Runtime.InteropServices.RuntimeInformation]::OSDescription
    runtime = "PowerShell $($PSVersionTable.PSVersion)"
    architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    cpu = $cpuName
    logical_cores = $cores
    memory_bytes = $memory
    hardware_fingerprint = $fingerprint
  }
}

function Convert-ToMilliseconds([double]$Value, [string]$Unit) {
  switch ($Unit) {
    'ns' { $Value / 1000000.0 }
    'µs' { $Value / 1000.0 }
    'ms' { $Value }
    's' { $Value * 1000.0 }
    default { throw "Unknown benchmark unit: $Unit" }
  }
}

function Convert-BenchmarkOutput([string]$Text) {
  $summaries = @()
  $currentName = $null
  foreach ($line in ($Text -split "`r?`n")) {
    if ($line -match '^\[.+\] bench .+ \("(?<name>[^\"]+)"\) ok$') {
      $currentName = $Matches.name
      continue
    }
    if ($null -ne $currentName -and $line -match '^\s*(?<mean>[0-9.]+)\s+(?<mu>ns|µs|ms|s)\s+±\s+(?<sigma>[0-9.]+)\s+(?<su>ns|µs|ms|s)\s+(?<min>[0-9.]+)\s+(?<minu>ns|µs|ms|s)\s+…\s+(?<max>[0-9.]+)\s+(?<maxu>ns|µs|ms|s)\s+in\s+(?<batch>\d+)\s+×\s+(?<runs>\d+)\s+runs$') {
      $summaries += [ordered]@{
        name = $currentName
        mean_ms = [Math]::Round((Convert-ToMilliseconds ([double]$Matches.mean) $Matches.mu), 9)
        sigma_ms = [Math]::Round((Convert-ToMilliseconds ([double]$Matches.sigma) $Matches.su), 9)
        min_ms = [Math]::Round((Convert-ToMilliseconds ([double]$Matches.min) $Matches.minu), 9)
        max_ms = [Math]::Round((Convert-ToMilliseconds ([double]$Matches.max) $Matches.maxu), 9)
        batch_size = [int]$Matches.batch
        runs = [int]$Matches.runs
      }
      $currentName = $null
    }
  }
  if ($summaries.Count -ne 8) { throw "Expected 8 benchmark summaries, parsed $($summaries.Count)" }
  for ($index = 0; $index -lt $workloadNames.Count; $index++) {
    if ($summaries[$index].name -cne $workloadNames[$index]) { throw "Benchmark order mismatch at $index" }
  }
  $summaries
}

function Invoke-BenchmarkRun([string]$OutputPath) {
  $lines = @(& moon -C benchmarks bench --release --target native --frozen ppm 2>&1 | ForEach-Object { "$_" })
  $code = $LASTEXITCODE
  $text = $lines -join "`n"
  [IO.File]::WriteAllText($OutputPath, $text + "`n", [Text.UTF8Encoding]::new($false))
  if ($code -ne 0) { throw "moon bench failed with exit code $code; see $OutputPath" }
  [ordered]@{ summaries = @(Convert-BenchmarkOutput $text); output_sha256 = Get-Sha256File $OutputPath }
}

function Get-Aggregate([double[]]$Samples) {
  $sorted = @($Samples | Sort-Object)
  $mean = ($Samples | Measure-Object -Average).Average
  $median = $sorted[[int][Math]::Floor($sorted.Count / 2)]
  $sumSquares = 0.0
  foreach ($sample in $Samples) { $sumSquares += [Math]::Pow($sample - $mean, 2) }
  $stddev = if ($Samples.Count -gt 1) { [Math]::Sqrt($sumSquares / ($Samples.Count - 1)) } else { 0.0 }
  [ordered]@{
    mean_ms = [Math]::Round($mean, 9)
    median_ms = [Math]::Round($median, 9)
    standard_deviation_ms = [Math]::Round($stddev, 9)
    coefficient_of_variation = [Math]::Round($(if ($mean -eq 0) { 0 } else { $stddev / $mean }), 9)
    min_ms = [Math]::Round($sorted[0], 9)
    max_ms = [Math]::Round($sorted[-1], 9)
  }
}

function Assert-Closed([object]$Value, [string[]]$Keys, [string]$Label) {
  $actual = @($Value.PSObject.Properties.Name)
  if (($actual -join '|') -cne ($Keys -join '|')) { throw "$Label keys/order mismatch: $($actual -join ',')" }
}

function Assert-StaticBaseline([object]$Baseline) {
  Assert-Closed $Baseline @('schema_version','policy','benchmark_commit','benchmark_source_sha256','captured_at','target','optimization','frozen','warmup_invocations','captured_invocations','environment','workloads','raw_runs','claim') 'baseline'
  if ($Baseline.schema_version -ne 1 -or $Baseline.policy -cne 'catastrophic-regression-only' -or $Baseline.target -cne 'native' -or $Baseline.optimization -cne 'release' -or !$Baseline.frozen -or $Baseline.warmup_invocations -ne 1 -or $Baseline.captured_invocations -ne 7) { throw 'Baseline fixed policy fields mismatch' }
  if ($Baseline.claim -cne 'local catastrophic-regression evidence only; not a performance or marketing claim; hosted timing is informational') { throw 'Baseline claim must remain exact and non-marketing' }
  if ($Baseline.benchmark_commit -notmatch '^[0-9a-f]{40}$' -or $Baseline.benchmark_source_sha256 -notmatch '^[0-9a-f]{64}$') { throw 'Baseline commit/source digest malformed' }
  Assert-Closed $Baseline.environment @('moon','moonc','moonrun','os','runtime','architecture','cpu','logical_cores','memory_bytes','hardware_fingerprint') 'environment'
  if ($Baseline.environment.hardware_fingerprint -notmatch '^[0-9a-f]{64}$') { throw 'Hardware fingerprint malformed' }
  if ($Baseline.workloads.Count -ne 8 -or $Baseline.raw_runs.Count -ne 7) { throw 'Baseline cardinality mismatch' }
  $digests = Get-CorrectnessDigests
  for ($i = 0; $i -lt 8; $i++) {
    $workload = $Baseline.workloads[$i]
    Assert-Closed $workload @('name','corpus_sha256','correctness_sha256','correctness','samples_ms','aggregate','threshold') "workload[$i]"
    if ($workload.name -cne $workloadNames[$i]) { throw "Workload order mismatch at $i" }
    if ($workload.corpus_sha256 -cne $digests[$workload.name].corpus -or $workload.correctness_sha256 -cne $digests[$workload.name].correctness) { throw "Workload digest mismatch: $($workload.name)" }
    if ($workload.correctness -cne 'passed-before-timing' -or $workload.samples_ms.Count -ne 7) { throw "Workload evidence incomplete: $($workload.name)" }
    Assert-Closed $workload.aggregate @('mean_ms','median_ms','standard_deviation_ms','coefficient_of_variation','min_ms','max_ms') "aggregate[$i]"
    Assert-Closed $workload.threshold @('kind','multiplier','additive_ms','baseline_median_ms') "threshold[$i]"
    if ($workload.threshold.kind -cne 'max-multiplier-or-additive' -or $workload.threshold.multiplier -ne 4 -or $workload.threshold.additive_ms -ne 5 -or $workload.threshold.baseline_median_ms -ne $workload.aggregate.median_ms) { throw "Threshold mismatch: $($workload.name)" }
  }
  for ($runIndex = 0; $runIndex -lt 7; $runIndex++) {
    $run = $Baseline.raw_runs[$runIndex]
    Assert-Closed $run @('index','captured_at','output_sha256','summaries') "raw_run[$runIndex]"
    if ($run.index -ne ($runIndex + 1) -or $run.output_sha256 -notmatch '^[0-9a-f]{64}$' -or $run.summaries.Count -ne 8) { throw "Raw run mismatch: $runIndex" }
    for ($i = 0; $i -lt 8; $i++) {
      $summary = $run.summaries[$i]
      Assert-Closed $summary @('name','mean_ms','sigma_ms','min_ms','max_ms','batch_size','runs') "summary[$runIndex,$i]"
      if ($summary.name -cne $workloadNames[$i]) { throw "Raw summary order mismatch: $runIndex,$i" }
    }
  }
  $sourceText = (Get-Content -Raw (Join-Path $repoRoot 'benchmarks/ppm/moon.pkg')) + (Get-Content -Raw (Join-Path $repoRoot 'benchmarks/ppm/ppm_bench.mbt'))
  if ($Baseline.benchmark_source_sha256 -cne (Get-Sha256Text $sourceText)) { throw 'Tracked benchmark source digest mismatch' }
  & git cat-file -e "$($Baseline.benchmark_commit)^{commit}" 2>$null
  if ($LASTEXITCODE -ne 0) { throw 'Benchmark commit is not present in repository history' }
  $null = Get-Content -Raw $schemaFile | ConvertFrom-Json
}

$previous = Get-Location
try {
  Set-Location -LiteralPath $repoRoot
  if ($Check) {
    if (!(Test-Path -LiteralPath $baselineFile -PathType Leaf)) { throw "Baseline missing: $baselineFile" }
    $baseline = Get-Content -Raw -LiteralPath $baselineFile | ConvertFrom-Json
    Assert-StaticBaseline $baseline
    if (!$SkipMeasurement) {
      $environment = Get-EnvironmentRecord
      $evidenceRoot = Join-Path $repoRoot ('artifacts/benchmarks/check-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'))
      $null = New-Item -ItemType Directory -Force -Path $evidenceRoot
      $current = Invoke-BenchmarkRun (Join-Path $evidenceRoot 'run-01.txt')
      $hosted = [bool]$env:CI
      $comparable = $environment.hardware_fingerprint -ceq $baseline.environment.hardware_fingerprint
      for ($i = 0; $i -lt 8; $i++) {
        $currentMedian = [double]$current.summaries[$i].mean_ms
        $baselineMedian = [double]$baseline.workloads[$i].aggregate.median_ms
        $limit = [Math]::Max(4.0 * $baselineMedian, $baselineMedian + 5.0)
        if (!$hosted -and $comparable -and $currentMedian -gt $limit) { throw "Catastrophic local regression: $($workloadNames[$i]) current=${currentMedian}ms limit=${limit}ms" }
      }
      $mode = if ($hosted -or !$comparable) { 'informational' } else { 'local-comparable-gated' }
      Write-Host "Benchmark measurement passed: mode=$mode workloads=8 evidence=$evidenceRoot"
    }
    Write-Host 'Benchmark baseline validation passed: schema=closed samples=7 workloads=8 correctness=verified claim=non-marketing'
    exit 0
  }

  $captureRoot = Join-Path $repoRoot ('artifacts/benchmarks/capture-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'))
  $null = New-Item -ItemType Directory -Force -Path $captureRoot
  Write-Host 'Running one untimed-for-evidence warmup invocation...'
  $null = Invoke-BenchmarkRun (Join-Path $captureRoot 'warmup.txt')
  $rawRuns = @()
  for ($run = 1; $run -le 7; $run++) {
    Write-Host "Capturing benchmark invocation $run/7..."
    $record = Invoke-BenchmarkRun (Join-Path $captureRoot ("run-{0:d2}.txt" -f $run))
    $rawRuns += [ordered]@{
      index = $run
      captured_at = [DateTime]::UtcNow.ToString('o')
      output_sha256 = $record.output_sha256
      summaries = $record.summaries
    }
  }
  $digests = Get-CorrectnessDigests
  $workloads = @()
  for ($i = 0; $i -lt 8; $i++) {
    $name = $workloadNames[$i]
    [double[]]$samples = @($rawRuns | ForEach-Object { [double]$_.summaries[$i].mean_ms })
    $aggregate = Get-Aggregate $samples
    $workloads += [ordered]@{
      name = $name
      corpus_sha256 = $digests[$name].corpus
      correctness_sha256 = $digests[$name].correctness
      correctness = 'passed-before-timing'
      samples_ms = $samples
      aggregate = $aggregate
      threshold = [ordered]@{
        kind = 'max-multiplier-or-additive'
        multiplier = 4
        additive_ms = 5
        baseline_median_ms = $aggregate.median_ms
      }
    }
  }
  $sourceText = (Get-Content -Raw 'benchmarks/ppm/moon.pkg') + (Get-Content -Raw 'benchmarks/ppm/ppm_bench.mbt')
  $baseline = [ordered]@{
    schema_version = 1
    policy = 'catastrophic-regression-only'
    benchmark_commit = (& git rev-parse HEAD).Trim()
    benchmark_source_sha256 = Get-Sha256Text $sourceText
    captured_at = [DateTime]::UtcNow.ToString('o')
    target = 'native'
    optimization = 'release'
    frozen = $true
    warmup_invocations = 1
    captured_invocations = 7
    environment = Get-EnvironmentRecord
    workloads = $workloads
    raw_runs = $rawRuns
    claim = 'local catastrophic-regression evidence only; not a performance or marketing claim; hosted timing is informational'
  }
  $json = $baseline | ConvertTo-Json -Depth 12
  $parent = Split-Path -Parent $baselineFile
  $null = New-Item -ItemType Directory -Force -Path $parent
  [IO.File]::WriteAllText($baselineFile, $json + "`n", [Text.UTF8Encoding]::new($false))
  Assert-StaticBaseline (Get-Content -Raw $baselineFile | ConvertFrom-Json)
  Write-Host "Benchmark baseline captured: $baselineFile (dynamic raw evidence: $captureRoot)"
} finally {
  Set-Location -LiteralPath $previous
}
