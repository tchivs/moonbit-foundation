[CmdletBinding()]
param(
  [switch]$CheckWorkspaceResolution,
  [switch]$ContractOnly,
  [switch]$Record,
  [switch]$Audit
)

# This is evidence capture, not a timing gate. The command, target,
# workloads, order, sample count, destination, and interpretation are closed.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$baselinePath = Join-Path $repoRoot 'docs\benchmarks\mb-font-cff-native-release-baseline.md'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$nativeCommand = 'moon -C benchmarks bench font-cff/cff_bench.mbt --release --target native --frozen'
$workloadNames = @(
  'latin-full-admission',
  'cjk-full-admission',
  'latin-fixed-outline-batch',
  'cjk-high-gid-multi-fd-outline-batch'
)
$testNames = @($workloadNames | ForEach-Object { 'cff/' + $_ })
$workspaceMembers = @(
  '../modules/mb-core',
  '../modules/mb-color',
  '../modules/mb-image',
  '../modules/mb-font',
  './ppm',
  './font-cff'
)
$sourcePaths = @(
  'fixtures/font/cff-qualification-cases.json',
  'fixtures/font/source-sans-3.052r/SourceSans3-Regular.otf',
  'fixtures/font/source-sans-3.052r/qualification.json',
  'fixtures/font/source-han-serif-2.003r/SourceHanSerifJP-Regular.otf',
  'fixtures/font/source-han-serif-2.003r/qualification.json',
  'benchmarks/font-cff/generated_cff_evidence.mbt',
  'benchmarks/font-cff/moon.mod.json',
  'benchmarks/font-cff/moon.pkg',
  'benchmarks/font-cff/cff_bench.mbt',
  'benchmarks/moon.work',
  'scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1',
  'scripts/quality/Test-BenchmarkQualification.ps1'
)
$allowedAutoChainPath = '.planning/config.json'

function Get-CffBenchmarkSha256Bytes([byte[]]$Bytes) {
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    [BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Get-CffBenchmarkSha256Text([string]$Text) {
  Get-CffBenchmarkSha256Bytes $utf8.GetBytes($Text)
}

function Get-CffBenchmarkSha256File([string]$Path) {
  Get-CffBenchmarkSha256Bytes ([IO.File]::ReadAllBytes($Path))
}

function Normalize-CffBenchmarkText([string]$Text) {
  $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
  if (-not $normalized.EndsWith("`n")) {
    $normalized += "`n"
  }
  $normalized
}

function Format-CffBenchmarkNumber([double]$Value) {
  $Value.ToString('F9', [Globalization.CultureInfo]::InvariantCulture)
}

function Assert-CffBenchmarkExactSequence(
  [string]$Label,
  [object[]]$Actual,
  [object[]]$Expected
) {
  if ($Actual.Count -ne $Expected.Count) {
    throw "$Label count drifted: expected $($Expected.Count), got $($Actual.Count)."
  }
  for ($index = 0; $index -lt $Expected.Count; $index++) {
    if ("$($Actual[$index])" -cne "$($Expected[$index])") {
      throw "$Label order/value drifted at index $index."
    }
  }
}

function Assert-CffBenchmarkClosedKeys(
  [object]$Value,
  [string[]]$Expected,
  [string]$Label
) {
  $actual = if ($Value -is [Collections.IDictionary]) {
    @($Value.Keys)
  } else {
    @($Value.PSObject.Properties.Name)
  }
  Assert-CffBenchmarkExactSequence $Label `
    $actual @($Expected)
}

function Assert-CffBenchmarkSha256([string]$Value, [string]$Label) {
  if ($Value -cnotmatch '^[0-9a-f]{64}$') {
    throw "$Label must be one lowercase SHA-256."
  }
}

function Assert-CffBenchmarkFiniteNonnegative([object]$Value, [string]$Label) {
  $number = [double]$Value
  if ([double]::IsNaN($number) -or [double]::IsInfinity($number) -or
      $number -lt 0.0) {
    throw "$Label must be finite and nonnegative."
  }
}

function Get-CffBenchmarkCanonicalRelativePath([string]$Path) {
  $full = [IO.Path]::GetFullPath($Path)
  $root = [IO.Path]::GetFullPath($repoRoot).TrimEnd('\') + '\'
  if (-not $full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Path is outside the repository: $full"
  }
  $full.Substring($root.Length).Replace('\', '/')
}

function Assert-CffBenchmarkNoReparsePath([string]$Path, [string]$Label) {
  $full = [IO.Path]::GetFullPath($Path)
  $root = [IO.Path]::GetPathRoot($full)
  $current = $root
  foreach ($part in $full.Substring($root.Length).Split(
      [char[]]@('\', '/'),
      [StringSplitOptions]::RemoveEmptyEntries
    )) {
    $current = Join-Path $current $part
    if ((Get-Item -LiteralPath $current -Force).Attributes -band
        [IO.FileAttributes]::ReparsePoint) {
      throw "$Label contains a link/reparse-point component: $current"
    }
  }
}

function Get-CffBenchmarkAutoChainDiff {
  $diff = (& git diff -- $allowedAutoChainPath | Out-String).Replace("`r`n", "`n")
  $expected = @'
diff --git a/.planning/config.json b/.planning/config.json
index 27d12bf8..d024a770 100644
--- a/.planning/config.json
+++ b/.planning/config.json
@@ -10,7 +10,7 @@
     "verifier": true,
     "nyquist_validation": false,
     "auto_advance": true,
-    "_auto_chain_active": false,
+    "_auto_chain_active": true,
     "ai_integration_phase": true
   },
   "plan_review": {
'@.Replace("`r`n", "`n") + "`n"
  if ($diff -cne $expected) {
    throw 'The orchestrator auto-chain marker differs from its one allowed change.'
  }
  $diff
}

function Assert-CffBenchmarkCleanTrackedState {
  $lines = @(
    & git status --porcelain=v1 --untracked-files=all |
      ForEach-Object { "$_" }
  )
  if ($lines.Count -eq 0) {
    return '(clean)'
  }
  if ($lines.Count -eq 1 -and
      $lines[0] -ceq ' M .planning/config.json') {
    $null = Get-CffBenchmarkAutoChainDiff
    return '(clean benchmark inputs; orchestrator auto-chain marker excluded)'
  }
  throw (
    'Clean committed benchmark inputs are required; unexpected git status: ' +
    ($lines -join '; ')
  )
}

function Assert-CffBenchmarkTracked([string]$RelativePath) {
  & git ls-files --error-unmatch -- $RelativePath *> $null
  if ($LASTEXITCODE -ne 0) {
    throw "Benchmark input is not tracked at HEAD: $RelativePath"
  }
}

function Get-CffBenchmarkExpectedWorkspaceText {
  @'
members = [
  "../modules/mb-core",
  "../modules/mb-color",
  "../modules/mb-image",
  "../modules/mb-font",
  "./ppm",
  "./font-cff",
]
'@.Replace("`r`n", "`n") + "`n"
}

function Assert-CffBenchmarkWorkspaceContract {
  $workspacePath = Join-Path $repoRoot 'benchmarks\moon.work'
  $actual = (Get-Content -Raw -LiteralPath $workspacePath).Replace("`r`n", "`n")
  if ($actual -cne (Get-CffBenchmarkExpectedWorkspaceText)) {
    throw 'Benchmark workspace member order drifted.'
  }
  $fontRoot = Join-Path $repoRoot 'modules\mb-font'
  $evidenceRoot = Join-Path $repoRoot 'benchmarks\font-cff'
  foreach ($path in @($fontRoot, $evidenceRoot)) {
    Assert-CffBenchmarkNoReparsePath $path 'Benchmark workspace member'
    if ((Get-CffBenchmarkCanonicalRelativePath $path) -notin
        @('modules/mb-font', 'benchmarks/font-cff')) {
      throw 'Benchmark workspace member is not one exact tracked local root.'
    }
  }
  $fontManifestPath = Join-Path $fontRoot 'moon.mod.json'
  $fontManifest = Get-Content -Raw -LiteralPath $fontManifestPath |
    ConvertFrom-Json
  if ($fontManifest.name -cne 'tchivs/mb-font' -or
      $fontManifest.version -cne '0.1.0') {
    throw 'Tracked mb-font name/version drifted.'
  }
  $evidenceManifest = Get-Content -Raw -LiteralPath (
    Join-Path $evidenceRoot 'moon.mod.json'
  ) | ConvertFrom-Json
  if ($evidenceManifest.name -cne 'moonbit-foundation/font-cff-evidence' -or
      $evidenceManifest.version -cne '0.0.0' -or
      $evidenceManifest.deps.'tchivs/mb-font' -cne '0.1.0') {
    throw 'CFF evidence module or mb-font dependency identity drifted.'
  }
  Assert-CffBenchmarkTracked 'modules/mb-font/moon.mod.json'
  Assert-CffBenchmarkTracked 'benchmarks/font-cff/moon.mod.json'
  [ordered]@{
    member_order = @($workspaceMembers)
    resolution = [ordered]@{
      module = 'tchivs/mb-font'
      version = '0.1.0'
      manifest_sha256 = Get-CffBenchmarkSha256File $fontManifestPath
      source_root = 'modules/mb-font'
      local = $true
      tracked = $true
      empty_cache_entries = 0
    }
  }
}

function Remove-CffBenchmarkTempRoot([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    return
  }
  $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
  $full = [IO.Path]::GetFullPath($Path)
  $leaf = Split-Path -Leaf $full
  if (-not $full.StartsWith($temp, [StringComparison]::OrdinalIgnoreCase) -or
      -not $leaf.StartsWith(
        'mnf-cff-benchmark-resolution-',
        [StringComparison]::Ordinal
      )) {
    throw "Refusing to remove unowned benchmark temp root: $full"
  }
  Remove-Item -LiteralPath $full -Recurse -Force
}

function Invoke-CffBenchmarkMoon(
  [string[]]$Arguments,
  [string]$WorkingDirectory
) {
  $savedPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $previous = Get-Location
    Set-Location -LiteralPath $WorkingDirectory
    $output = (& moon @Arguments 2>&1 | Out-String)
    $exitCode = $LASTEXITCODE
    [pscustomobject]@{
      exit_code = $exitCode
      output = Normalize-CffBenchmarkText $output
    }
  } finally {
    Set-Location -LiteralPath $previous
    $ErrorActionPreference = $savedPreference
  }
}

function Invoke-CffBenchmarkWorkspaceResolution {
  $workspace = Assert-CffBenchmarkWorkspaceContract
  $tempRoot = Join-Path ([IO.Path]::GetTempPath()) (
    'mnf-cff-benchmark-resolution-' + [guid]::NewGuid().ToString('N')
  )
  try {
    [void](New-Item -ItemType Directory -Path $tempRoot)
    $cacheRoot = Join-Path $tempRoot '.repos'
    [void](New-Item -ItemType Directory -Path $cacheRoot)
    $targetRoot = Join-Path $tempRoot 'target'
    $canonicalRoots = @(
      'modules/mb-core',
      'modules/mb-color',
      'modules/mb-image',
      'modules/mb-font',
      'benchmarks/ppm',
      'benchmarks/font-cff'
    ) | ForEach-Object {
      [IO.Path]::GetFullPath((Join-Path $repoRoot $_)).Replace('\', '/')
    }
    $memberLines = @($canonicalRoots | ForEach-Object { '  "' + $_ + '",' })
    [IO.File]::WriteAllText(
      (Join-Path $tempRoot 'moon.work'),
      "members = [`n$($memberLines -join "`n")`n]`n",
      $utf8
    )
    $benchmarkPath = [IO.Path]::GetFullPath(
      (Join-Path $repoRoot 'benchmarks\font-cff\cff_bench.mbt')
    )
    $result = Invoke-CffBenchmarkMoon @(
      '-C', $tempRoot,
      '-v',
      'bench', $benchmarkPath,
      '--release',
      '--target', 'native',
      '--frozen',
      '--build-only',
      '--target-dir', $targetRoot
    ) $repoRoot
    if ($result.exit_code -ne 0) {
      throw "Tracked-local frozen CFF benchmark resolution failed.`n$($result.output)"
    }
    if (@(Get-ChildItem -LiteralPath $cacheRoot -Force).Count -ne 0) {
      throw 'CFF benchmark populated the newly empty external cache.'
    }
    $normalizedFontRoot = ([IO.Path]::GetFullPath(
      (Join-Path $repoRoot 'modules\mb-font')
    )).Replace('\', '/')
    $normalizedOutput = $result.output.Replace('\', '/')
    if (-not $normalizedOutput.Contains($normalizedFontRoot)) {
      throw 'Verbose frozen resolution did not identify the tracked mb-font root.'
    }

    $withoutFont = @($canonicalRoots | Where-Object {
      $_ -cne $normalizedFontRoot
    })
    $withoutLines = @($withoutFont | ForEach-Object { '  "' + $_ + '",' })
    [IO.File]::WriteAllText(
      (Join-Path $tempRoot 'moon.work'),
      "members = [`n$($withoutLines -join "`n")`n]`n",
      $utf8
    )
    $negative = Invoke-CffBenchmarkMoon @(
      '-C', $tempRoot,
      'bench', $benchmarkPath,
      '--release',
      '--target', 'native',
      '--frozen',
      '--build-only',
      '--target-dir', (Join-Path $tempRoot 'negative-target')
    ) $repoRoot
    if ($negative.exit_code -eq 0) {
      throw 'Removing the tracked mb-font workspace member resolved unexpectedly.'
    }
    if (@(Get-ChildItem -LiteralPath $cacheRoot -Force).Count -ne 0) {
      throw 'Missing-member negative populated the empty external cache.'
    }
    Write-Host (
      'CFF benchmark workspace resolution passed: exact tracked members, ' +
      'verbose local mb-font source, empty cache, and missing-member rejection.'
    )
    $workspace
  } finally {
    Remove-CffBenchmarkTempRoot $tempRoot
  }
}

function Assert-CffBenchmarkSourceContract {
  $path = Join-Path $repoRoot 'benchmarks\font-cff\cff_bench.mbt'
  $source = Get-Content -Raw -LiteralPath $path
  $actual = @(
    [regex]::Matches(
      $source,
      '(?m)^test "bench cff/(?<name>[^"]+)" \(b : @bench[.]T\) \{$'
    ) | ForEach-Object { $_.Groups['name'].Value }
  )
  Assert-CffBenchmarkExactSequence 'CFF benchmark workloads' $actual $workloadNames
  if ([regex]::Matches($source, '@bench[.]T').Count -ne 4) {
    throw 'CFF benchmark must contain exactly four @bench.T tests.'
  }
  if ([regex]::Matches($source, 'fn cff_benchmark_budget[(][)]').Count -ne 1) {
    throw 'CFF benchmark must define one exact Budget factory.'
  }
  if ($source -cmatch '(?i)\b(?:reset|reuse|shared_budget|mutable_budget)\b') {
    throw 'CFF benchmark contains a Budget reuse/reset seam.'
  }
  foreach ($forbidden in @(
      'read_file',
      'open_file',
      'filesystem',
      'subprocess',
      'network',
      'extern',
      'ffi'
    )) {
    if ($source -cmatch ('(?i)\b' + [regex]::Escape($forbidden) + '\b')) {
      throw "CFF benchmark contains forbidden runtime seam: $forbidden"
    }
  }
  if ($source -cmatch '(?m)^\s*(?:const|let)\s+\w+\s*=\s*\[(?:[^\]\r\n]{0,20},){64,}') {
    throw 'CFF benchmark appears to duplicate a payload literal.'
  }
  foreach ($call in @(
      '@bytes.OwnedBytes::from_bytes(source, cff_benchmark_budget())',
      'cff_benchmark_open(owner)',
      'font.outline(glyph, cff_benchmark_budget())',
      'cff_benchmark_assert_outlines(font, glyphs)'
    )) {
    if (-not $source.Contains($call)) {
      throw "CFF benchmark fresh-budget contract is missing: $call"
    }
  }
  $measuredOpen = [regex]::Matches(
    $source,
    '(?s)b[.]bench[(]fn[(][)]\s*\{\s*b[.]keep[(]\s*@font[.]Font::open[(].*?cff_benchmark_budget[(][)]'
  ).Count
  if ($measuredOpen -ne 2) {
    throw 'Both measured admission operations must construct a fresh Budget.'
  }
  $measuredOutline = [regex]::Matches(
    $source,
    '(?s)b[.]bench[(]fn[(][)]\s*\{\s*for glyph in glyphs \{\s*b[.]keep[(]font[.]outline[(]glyph, cff_benchmark_budget[(][)]'
  ).Count
  if ($measuredOutline -ne 2) {
    throw 'Both measured outline batches must construct a fresh Budget per glyph.'
  }
}

function Get-CffBenchmarkWorkloads {
  $corpusPath = Join-Path $repoRoot 'fixtures\font\cff-qualification-cases.json'
  $corpus = Get-Content -Raw -LiteralPath $corpusPath | ConvertFrom-Json
  $rows = @($corpus.workloads)
  Assert-CffBenchmarkExactSequence 'Canonical CFF workload IDs' `
    @($rows.id) $workloadNames
  $expectedGids = @(
    @(),
    @(),
    @(2, 3, 34, 97, 321, 1024, 2477),
    @(2, 256, 2048, 8192, 16384, 17922)
  )
  $expectedFixtures = @(
    'source-sans-3.052R',
    'source-han-serif-jp-2.003R',
    'source-sans-3.052R',
    'source-han-serif-jp-2.003R'
  )
  $result = @()
  for ($index = 0; $index -lt $rows.Count; $index++) {
    Assert-CffBenchmarkExactSequence "CFF workload GIDs $index" `
      @($rows[$index].gids) @($expectedGids[$index])
    Assert-CffBenchmarkSha256 `
      ([string]$rows[$index].correctness_output_sha256) `
      "CFF workload correctness digest $index"
    if ($rows[$index].fixture_id -cne $expectedFixtures[$index] -or
        [bool]$rows[$index].timing) {
      throw "CFF workload fixture/timing identity drifted at $index."
    }
    $result += [ordered]@{
      id = [string]$rows[$index].id
      test_name = $testNames[$index]
      fixture_id = [string]$rows[$index].fixture_id
      operation = [string]$rows[$index].operation
      gids = @($rows[$index].gids)
      correctness_input = [string]$rows[$index].correctness_input
      correctness_sha256 = [string]$rows[$index].correctness_output_sha256
    }
  }
  $result
}

function Get-CffBenchmarkSourceFacts {
  param([switch]$AllowTaskSources)
  $facts = @()
  foreach ($relativePath in $sourcePaths) {
    $path = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw "CFF benchmark source is missing: $relativePath"
    }
    if ($AllowTaskSources -and $relativePath -in @(
        'benchmarks/font-cff/cff_bench.mbt',
        'scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1'
      )) {
      & git ls-files --error-unmatch -- $relativePath *> $null
      if ($LASTEXITCODE -ne 0) {
        $status = & git status --porcelain=v1 --untracked-files=all -- $relativePath
        if ("$status" -cne "?? $relativePath") {
          throw "Task source is neither tracked nor the exact new file: $relativePath"
        }
      }
    } else {
      Assert-CffBenchmarkTracked $relativePath
    }
    $item = Get-Item -LiteralPath $path
    $facts += [ordered]@{
      path = $relativePath
      length = [int64]$item.Length
      sha256 = Get-CffBenchmarkSha256File $path
    }
  }
  $facts
}

function Get-CffBenchmarkCommandVersion([string]$Name, [string[]]$Arguments) {
  $command = Get-Command $Name -ErrorAction Stop
  $savedPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $output = ((& $command.Source @Arguments 2>&1 | Out-String).
      Replace("`r`n", "`n").Trim())
    if ($LASTEXITCODE -ne 0) {
      throw "Tool identity command failed: $Name"
    }
  } finally {
    $ErrorActionPreference = $savedPreference
  }
  [ordered]@{
    executable = [IO.Path]::GetFileName($command.Source)
    executable_sha256 = Get-CffBenchmarkSha256File $command.Source
    version_output_sha256 = Get-CffBenchmarkSha256Text $output
    version = $output
  }
}

function Get-CffBenchmarkToolchain {
  $policy = Get-Content -Raw -LiteralPath (
    Join-Path $repoRoot 'policy\foundation.json'
  ) | ConvertFrom-Json
  $facts = [ordered]@{
    moon = Get-CffBenchmarkCommandVersion 'moon' @('--version')
    moonc = Get-CffBenchmarkCommandVersion 'moonc' @('-v')
    moonrun = Get-CffBenchmarkCommandVersion 'moonrun' @('--version')
  }
  foreach ($name in @('moon', 'moonc', 'moonrun')) {
    foreach ($field in @('version', 'commit', 'release_date')) {
      $pin = $policy.toolchain.$name.PSObject.Properties[$field]
      if ($null -ne $pin -and
          $facts[$name].version -notlike "*$($pin.Value)*") {
        throw "Toolchain policy mismatch for $name $field."
      }
    }
  }
  $facts
}

function Get-CffBenchmarkProbe([string]$Attempted, [scriptblock]$Probe) {
  try {
    [ordered]@{
      value = ((& $Probe | Out-String).Replace("`r`n", "`n").Trim())
      attempted = $Attempted
    }
  } catch {
    [ordered]@{ value = 'unavailable'; attempted = $Attempted }
  }
}

function Get-CffBenchmarkHostFacts {
  $compiler = Get-Command clang -ErrorAction SilentlyContinue
  if ($null -eq $compiler) {
    $compiler = Get-Command cc -ErrorAction Stop
  }
  $compilerVersion = Get-CffBenchmarkProbe (
    [IO.Path]::GetFileName($compiler.Source) + ' --version'
  ) {
    & $compiler.Source --version
  }
  $shellPath = (Get-Process -Id $PID).Path
  [ordered]@{
    powershell = [ordered]@{
      version = $PSVersionTable.PSVersion.ToString()
      edition = if ($PSVersionTable.PSObject.Properties['PSEdition']) {
        [string]$PSVersionTable.PSEdition
      } else {
        'Desktop'
      }
      executable = [IO.Path]::GetFileName($shellPath)
      executable_sha256 = Get-CffBenchmarkSha256File $shellPath
    }
    dotnet_runtime = [Environment]::Version.ToString()
    os = Get-CffBenchmarkProbe 'Get-CimInstance Win32_OperatingSystem' {
      $value = Get-CimInstance Win32_OperatingSystem
      "$($value.Caption) | version=$($value.Version) | build=$($value.BuildNumber) | architecture=$($value.OSArchitecture)"
    }
    cpu = Get-CffBenchmarkProbe (
      'Get-CimInstance Win32_Processor | Select-Object -First 1'
    ) {
      $value = Get-CimInstance Win32_Processor | Select-Object -First 1
      "$($value.Name.Trim()) | physical_cores=$($value.NumberOfCores) | logical_processors=$($value.NumberOfLogicalProcessors)"
    }
    physical_memory_bytes = Get-CffBenchmarkProbe (
      'Get-CimInstance Win32_ComputerSystem'
    ) {
      (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory.ToString(
        [Globalization.CultureInfo]::InvariantCulture
      )
    }
    active_power_scheme = Get-CffBenchmarkProbe 'powercfg /GETACTIVESCHEME' {
      $powerOutput = (& powercfg /GETACTIVESCHEME | Out-String)
      $powerGuid = [regex]::Match(
        $powerOutput,
        '(?i)\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b'
      )
      if (-not $powerGuid.Success) {
        throw 'Active power-scheme GUID was unavailable.'
      }
      $powerGuid.Value.ToLowerInvariant()
    }
    native_compiler = [ordered]@{
      executable = [IO.Path]::GetFileName($compiler.Source)
      executable_sha256 = Get-CffBenchmarkSha256File $compiler.Source
      version = $compilerVersion.value
      probe = $compilerVersion.attempted
    }
  }
}

function Convert-CffBenchmarkMilliseconds([double]$Value, [string]$Unit) {
  if ($Unit -ceq 'ns') { return $Value / 1000000.0 }
  if ($Unit -ceq (([char]0x00B5).ToString() + 's')) {
    return $Value / 1000.0
  }
  if ($Unit -ceq 'ms') { return $Value }
  if ($Unit -ceq 's') { return $Value * 1000.0 }
  throw "Unknown CFF benchmark unit: $Unit"
}

function Convert-CffBenchmarkOutput([string]$Text) {
  $summaries = @()
  $current = $null
  foreach ($line in ($Text -split "`n")) {
    if ($line -match '^\[.+\] bench .+ \("bench (?<name>cff/[^"]+)"\) ok$') {
      $current = $Matches.name
      continue
    }
    if ($null -ne $current -and
        $line -match '^\s*(?<mean>[0-9.]+)\s+(?<mu>ns|\u00b5s|ms|s)\s+\u00b1\s+(?<sigma>[0-9.]+)\s+(?<su>ns|\u00b5s|ms|s)\s+(?<min>[0-9.]+)\s+(?<minu>ns|\u00b5s|ms|s)\s+\u2026\s+(?<max>[0-9.]+)\s+(?<maxu>ns|\u00b5s|ms|s)\s+in\s+(?<batch>\d+)\s+\u00d7\s+(?<runs>\d+)\s+runs$') {
      $summaries += [ordered]@{
        name = $current.Substring(4)
        mean_ms = [Math]::Round((
          Convert-CffBenchmarkMilliseconds ([double]$Matches.mean) $Matches.mu
        ), 9)
        sigma_ms = [Math]::Round((
          Convert-CffBenchmarkMilliseconds ([double]$Matches.sigma) $Matches.su
        ), 9)
        minimum_ms = [Math]::Round((
          Convert-CffBenchmarkMilliseconds ([double]$Matches.min) $Matches.minu
        ), 9)
        maximum_ms = [Math]::Round((
          Convert-CffBenchmarkMilliseconds ([double]$Matches.max) $Matches.maxu
        ), 9)
        batch_size = [int]$Matches.batch
        runs = [int]$Matches.runs
      }
      $current = $null
    }
  }
  Assert-CffBenchmarkExactSequence 'Runner workload order' `
    @($summaries.name) $workloadNames
  $summaries
}

function Invoke-CffNativeCapture([string]$Id, [string]$Label) {
  $started = [DateTime]::UtcNow.ToString('o')
  $info = New-Object Diagnostics.ProcessStartInfo
  $info.FileName = $env:ComSpec
  $info.Arguments = '/d /c "' + $nativeCommand + ' 2>&1"'
  $info.WorkingDirectory = $repoRoot
  $info.UseShellExecute = $false
  $info.RedirectStandardOutput = $true
  $info.RedirectStandardError = $true
  $info.CreateNoWindow = $true
  $info.StandardOutputEncoding = $utf8
  $info.StandardErrorEncoding = $utf8
  $process = New-Object Diagnostics.Process
  $process.StartInfo = $info
  if (-not $process.Start()) {
    throw "Could not start CFF native benchmark $Label."
  }
  $stdoutTask = $process.StandardOutput.ReadToEndAsync()
  $stderrTask = $process.StandardError.ReadToEndAsync()
  if (-not $process.WaitForExit(900000)) {
    $process.Kill()
    $process.WaitForExit()
    throw "CFF native benchmark $Label timed out."
  }
  $stdout = $stdoutTask.GetAwaiter().GetResult()
  $stderr = $stderrTask.GetAwaiter().GetResult()
  $merged = if ([string]::IsNullOrEmpty($stderr)) {
    $stdout
  } else {
    $stdout + "`n" + $stderr
  }
  $output = Normalize-CffBenchmarkText $merged
  if ($process.ExitCode -ne 0) {
    throw "CFF native benchmark $Label failed with exit code $($process.ExitCode)."
  }
  [ordered]@{
    id = $Id
    label = $Label
    started_utc = $started
    ended_utc = [DateTime]::UtcNow.ToString('o')
    exit_code = [int]$process.ExitCode
    output_sha256 = Get-CffBenchmarkSha256Text $output
    summaries = @(Convert-CffBenchmarkOutput $output)
    output = $output
  }
}

function Get-CffBenchmarkAggregate([double[]]$Samples) {
  if ($Samples.Count -ne 7) {
    throw 'A CFF native aggregate requires exactly seven retained samples.'
  }
  foreach ($sample in $Samples) {
    Assert-CffBenchmarkFiniteNonnegative $sample 'CFF retained sample'
  }
  $sorted = @($Samples | Sort-Object)
  $mean = ($Samples | Measure-Object -Average).Average
  $sumSquares = 0.0
  foreach ($sample in $Samples) {
    $sumSquares += [Math]::Pow($sample - $mean, 2)
  }
  $sampleStandardDeviation = [Math]::Sqrt($sumSquares / 6.0)
  [ordered]@{
    mean_ms = [Math]::Round($mean, 9)
    median_ms = [Math]::Round($sorted[3], 9)
    sample_standard_deviation_ms = [Math]::Round(
      $sampleStandardDeviation,
      9
    )
    minimum_ms = [Math]::Round($sorted[0], 9)
    maximum_ms = [Math]::Round($sorted[-1], 9)
    coefficient_of_variation = if ($mean -eq 0.0) {
      0.0
    } else {
      [Math]::Round($sampleStandardDeviation / $mean, 9)
    }
  }
}

function Add-CffBenchmarkLine(
  [Text.StringBuilder]$Builder,
  [string]$Text = ''
) {
  [void]$Builder.Append($Text)
  [void]$Builder.Append("`n")
}

function Convert-CffBenchmarkHtml([string]$Text) {
  $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace(
    '>',
    '&gt;'
  ).Replace(' ', '&#32;')
}

function Convert-CffBenchmarkAsciiJson([object]$Value) {
  $json = $Value | ConvertTo-Json -Depth 30
  $builder = New-Object Text.StringBuilder
  foreach ($character in $json.ToCharArray()) {
    $codePoint = [int][char]$character
    if ($codePoint -gt 127) {
      [void]$builder.Append(('\u{0:X4}' -f $codePoint))
    } else {
      [void]$builder.Append($character)
    }
  }
  $builder.ToString()
}

function Add-CffBenchmarkRunMarkdown(
  [Text.StringBuilder]$Builder,
  [object]$Run
) {
  $title = if ($Run.id -ceq 'warmup') {
    'Warmup (excluded)'
  } else {
    'Retained capture ' + $Run.id
  }
  Add-CffBenchmarkLine $Builder ('### ' + $title)
  Add-CffBenchmarkLine $Builder ('- UTC start: `' + $Run.started_utc + '`')
  Add-CffBenchmarkLine $Builder ('- UTC end: `' + $Run.ended_utc + '`')
  Add-CffBenchmarkLine $Builder ('- Exit status: `' + $Run.exit_code + '`')
  Add-CffBenchmarkLine $Builder (
    '- Normalized raw output SHA-256: `' + $Run.output_sha256 + '`'
  )
  Add-CffBenchmarkLine $Builder ''
  Add-CffBenchmarkLine $Builder (
    '| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | ' +
    'Maximum (ms) | Batch | Runs |'
  )
  Add-CffBenchmarkLine $Builder '| --- | ---: | ---: | ---: | ---: | ---: | ---: |'
  foreach ($summary in $Run.summaries) {
    Add-CffBenchmarkLine $Builder (
      '| ' + $summary.name + ' | ' +
      (Format-CffBenchmarkNumber $summary.mean_ms) + ' | ' +
      (Format-CffBenchmarkNumber $summary.sigma_ms) + ' | ' +
      (Format-CffBenchmarkNumber $summary.minimum_ms) + ' | ' +
      (Format-CffBenchmarkNumber $summary.maximum_ms) + ' | ' +
      $summary.batch_size + ' | ' + $summary.runs + ' |'
    )
  }
  Add-CffBenchmarkLine $Builder ''
  Add-CffBenchmarkLine $Builder '<details>'
  Add-CffBenchmarkLine $Builder '<summary>Complete normalized UTF-8 merged stdout/stderr</summary>'
  Add-CffBenchmarkLine $Builder ''
  Add-CffBenchmarkLine $Builder '<pre class="cff-native-output">'
  [void]$Builder.Append((
    Convert-CffBenchmarkHtml $Run.output.TrimEnd("`n".ToCharArray())
  ))
  Add-CffBenchmarkLine $Builder ''
  Add-CffBenchmarkLine $Builder '</pre>'
  Add-CffBenchmarkLine $Builder '</details>'
  Add-CffBenchmarkLine $Builder ''
}

function New-CffBenchmarkDocument([object]$Evidence) {
  $builder = New-Object Text.StringBuilder
  Add-CffBenchmarkLine $builder '# mb-font CFF1 native release baseline'
  Add-CffBenchmarkLine $builder ''
  Add-CffBenchmarkLine $builder (
    '**Scope:** `observation_only` native release measurements for exact ' +
    'reproduction facts. The record establishes no threshold, regression ' +
    'verdict, cross-library comparison, ranking, superiority, CI timing gate, ' +
    'release decision, or marketing claim.'
  )
  Add-CffBenchmarkLine $builder ''
  Add-CffBenchmarkLine $builder '## Closed identity'
  Add-CffBenchmarkLine $builder ''
  Add-CffBenchmarkLine $builder (
    '- Source Git commit: `' + $Evidence.identity.git_commit + '`'
  )
  Add-CffBenchmarkLine $builder (
    '- Source tree state: `' + $Evidence.identity.tree_status + '`'
  )
  Add-CffBenchmarkLine $builder (
    '- Exact command: `' + $Evidence.execution.command + '`'
  )
  Add-CffBenchmarkLine $builder (
    '- Fixed sequence: one excluded warmup followed by seven retained complete captures.'
  )
  Add-CffBenchmarkLine $builder ''
  Add-CffBenchmarkLine $builder '## Workspace and workload provenance'
  Add-CffBenchmarkLine $builder ''
  Add-CffBenchmarkLine $builder (
    '- Workspace members: `' + ($Evidence.workspace.member_order -join ',') + '`'
  )
  Add-CffBenchmarkLine $builder (
    '- mb-font: `' + $Evidence.workspace.resolution.module + '@' +
    $Evidence.workspace.resolution.version + '` from tracked `' +
    $Evidence.workspace.resolution.source_root + '`; manifest SHA-256 `' +
    $Evidence.workspace.resolution.manifest_sha256 + '`; empty cache entries `' +
    $Evidence.workspace.resolution.empty_cache_entries + '`.'
  )
  Add-CffBenchmarkLine $builder ''
  Add-CffBenchmarkLine $builder (
    '| Workload | Fixture | Operation | GIDs | Correctness SHA-256 |'
  )
  Add-CffBenchmarkLine $builder '| --- | --- | --- | --- | --- |'
  foreach ($workload in $Evidence.workloads) {
    Add-CffBenchmarkLine $builder (
      '| ' + $workload.id + ' | ' + $workload.fixture_id + ' | ' +
      $workload.operation + ' | ' + (@($workload.gids) -join ',') + ' | `' +
      $workload.correctness_sha256 + '` |'
    )
  }
  Add-CffBenchmarkLine $builder ''
  Add-CffBenchmarkLine $builder '## Tracked source identities'
  Add-CffBenchmarkLine $builder ''
  Add-CffBenchmarkLine $builder '| Path | Length | SHA-256 |'
  Add-CffBenchmarkLine $builder '| --- | ---: | --- |'
  foreach ($source in $Evidence.sources) {
    Add-CffBenchmarkLine $builder (
      '| `' + $source.path + '` | ' + $source.length + ' | `' +
      $source.sha256 + '` |'
    )
  }
  Add-CffBenchmarkLine $builder ''
  Add-CffBenchmarkLine $builder '## Toolchain and host'
  Add-CffBenchmarkLine $builder ''
  foreach ($name in @('moon', 'moonc', 'moonrun')) {
    $tool = $Evidence.toolchain.$name
    Add-CffBenchmarkLine $builder (
      '- ' + $name + ': `' + $tool.executable + '` SHA-256 `' +
      $tool.executable_sha256 + '`; version output SHA-256 `' +
      $tool.version_output_sha256 + '`.'
    )
  }
  Add-CffBenchmarkLine $builder (
    '- PowerShell: `' + $Evidence.host.powershell.version + '` (`' +
    $Evidence.host.powershell.edition + '`, `' +
    $Evidence.host.powershell.executable + '`, SHA-256 `' +
    $Evidence.host.powershell.executable_sha256 + '`).'
  )
  Add-CffBenchmarkLine $builder (
    '- Native compiler: `' + $Evidence.host.native_compiler.executable +
    '`, SHA-256 `' + $Evidence.host.native_compiler.executable_sha256 +
    '`, probe `' + $Evidence.host.native_compiler.probe + '`.'
  )
  foreach ($name in @(
      'os',
      'cpu',
      'physical_memory_bytes',
      'active_power_scheme'
    )) {
    Add-CffBenchmarkLine $builder (
      '- ' + $name + ': `' + $Evidence.host.$name.value + '` (probe `' +
      $Evidence.host.$name.attempted + '`).'
    )
  }
  Add-CffBenchmarkLine $builder ''
  Add-CffBenchmarkLine $builder '## Captures'
  Add-CffBenchmarkLine $builder ''
  foreach ($run in $Evidence.runs) {
    Add-CffBenchmarkRunMarkdown $builder $run
  }
  Add-CffBenchmarkLine $builder '## Seven-capture descriptive statistics'
  Add-CffBenchmarkLine $builder ''
  Add-CffBenchmarkLine $builder (
    '| Workload | Mean (ms) | Median (ms) | Sample standard deviation ' +
    '(ms, n-1=6) | Minimum (ms) | Maximum (ms) | Coefficient of variation |'
  )
  Add-CffBenchmarkLine $builder '| --- | ---: | ---: | ---: | ---: | ---: | ---: |'
  foreach ($aggregate in $Evidence.aggregates) {
    Add-CffBenchmarkLine $builder (
      '| ' + $aggregate.name + ' | ' +
      (Format-CffBenchmarkNumber $aggregate.values.mean_ms) + ' | ' +
      (Format-CffBenchmarkNumber $aggregate.values.median_ms) + ' | ' +
      (Format-CffBenchmarkNumber (
        $aggregate.values.sample_standard_deviation_ms
      )) + ' | ' +
      (Format-CffBenchmarkNumber $aggregate.values.minimum_ms) + ' | ' +
      (Format-CffBenchmarkNumber $aggregate.values.maximum_ms) + ' | ' +
      (Format-CffBenchmarkNumber (
        $aggregate.values.coefficient_of_variation
      )) + ' |'
    )
  }
  Add-CffBenchmarkLine $builder ''
  Add-CffBenchmarkLine $builder '## Read-only audit'
  Add-CffBenchmarkLine $builder ''
  Add-CffBenchmarkLine $builder (
    'Run `./scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1 -Audit`. ' +
    'Audit reads tracked inputs and this committed document only; it executes ' +
    'no MoonBit command and writes no file.'
  )
  Add-CffBenchmarkLine $builder ''
  $audit = [ordered]@{}
  foreach ($key in $Evidence.Keys) {
    if ($key -ceq 'runs') {
      $audit[$key] = @($Evidence.runs | ForEach-Object {
        [ordered]@{
          id = $_.id
          label = $_.label
          started_utc = $_.started_utc
          ended_utc = $_.ended_utc
          exit_code = $_.exit_code
          output_sha256 = $_.output_sha256
          summaries = $_.summaries
        }
      })
    } else {
      $audit[$key] = $Evidence[$key]
    }
  }
  Add-CffBenchmarkLine $builder '<!-- CFF-BASELINE-DATA'
  Add-CffBenchmarkLine $builder (Convert-CffBenchmarkAsciiJson $audit)
  Add-CffBenchmarkLine $builder '-->'
  $builder.ToString()
}

function Get-CffBenchmarkAuditData([string]$Document) {
  $match = [regex]::Match(
    $Document,
    '(?s)<!-- CFF-BASELINE-DATA\r?\n(?<json>.*?)\r?\n-->'
  )
  if (-not $match.Success) {
    throw 'CFF baseline audit data block is missing or malformed.'
  }
  $match.Groups['json'].Value | ConvertFrom-Json
}

function Get-CffBenchmarkVisibleSections([string]$Document) {
  $matches = [regex]::Matches(
    $Document,
    '(?m)^### (?<title>Warmup \(excluded\)|Retained capture [1-7])\r?$'
  )
  if ($matches.Count -ne 8) {
    throw 'CFF baseline needs one warmup and seven retained visible sections.'
  }
  $summaryIndex = $Document.IndexOf(
    '## Seven-capture descriptive statistics',
    [StringComparison]::Ordinal
  )
  if ($summaryIndex -lt 0) {
    throw 'CFF visible aggregate section is missing.'
  }
  $sections = @()
  for ($index = 0; $index -lt $matches.Count; $index++) {
    $expected = if ($index -eq 0) {
      'Warmup (excluded)'
    } else {
      'Retained capture ' + $index
    }
    if ($matches[$index].Groups['title'].Value -cne $expected) {
      throw "CFF visible capture order drifted at $index."
    }
    $start = $matches[$index].Index + $matches[$index].Length
    $end = if ($index -lt 7) {
      $matches[$index + 1].Index
    } else {
      $summaryIndex
    }
    $sections += [pscustomobject]@{
      title = $expected
      body = $Document.Substring($start, $end - $start)
    }
  }
  $sections
}

function Get-CffBenchmarkDocumentOutput([string]$Section, [string]$Id) {
  $matches = [regex]::Matches(
    $Section,
    '(?s)<summary>Complete normalized UTF-8 merged stdout/stderr</summary>\s*<pre class="cff-native-output">\r?\n(?<output>.*?)\r?\n</pre>'
  )
  if ($matches.Count -ne 1) {
    throw "CFF raw output is missing or duplicated for $Id."
  }
  Normalize-CffBenchmarkText (
    [Net.WebUtility]::HtmlDecode($matches[0].Groups['output'].Value)
  )
}

function New-CffBenchmarkRenderedEvidence(
  [object]$Data,
  [object[]]$Sections
) {
  $runs = @()
  for ($index = 0; $index -lt $Data.runs.Count; $index++) {
    $run = [ordered]@{}
    foreach ($property in $Data.runs[$index].PSObject.Properties) {
      $run[$property.Name] = if (
        $property.Name -in @('started_utc', 'ended_utc') -and
        $property.Value -is [DateTime]
      ) {
        $property.Value.ToUniversalTime().ToString('o')
      } else {
        $property.Value
      }
    }
    $run.output = Get-CffBenchmarkDocumentOutput `
      $Sections[$index].body "$($run.id)"
    $runs += $run
  }
  $evidence = [ordered]@{}
  foreach ($property in $Data.PSObject.Properties) {
    $evidence[$property.Name] = if ($property.Name -ceq 'runs') {
      $runs
    } else {
      $property.Value
    }
  }
  $evidence
}

function Assert-CffBenchmarkEvidence(
  [object]$Data,
  [switch]$VerifyCurrentInputs
) {
  Assert-CffBenchmarkClosedKeys $Data @(
    'schema_version',
    'claim',
    'identity',
    'execution',
    'workspace',
    'sources',
    'workloads',
    'toolchain',
    'host',
    'runs',
    'aggregates'
  ) 'CFF baseline root schema'
  if ($Data.schema_version -cne 'mnf-mb-font-cff-native-baseline/1.0.0') {
    throw 'CFF baseline schema identity drifted.'
  }
  Assert-CffBenchmarkClosedKeys $Data.claim @(
    'type',
    'interpretation'
  ) 'CFF baseline claim schema'
  if ($Data.claim.type -cne 'observation_only' -or
      $Data.claim.interpretation -cne
        'native release measurements for exact reproduction facts only') {
    throw 'CFF baseline claim must remain observation_only.'
  }
  Assert-CffBenchmarkClosedKeys $Data.identity @(
    'git_commit',
    'tree_status'
  ) 'CFF baseline Git identity'
  if ($Data.identity.git_commit -cnotmatch '^[0-9a-f]{40}$' -or
      $Data.identity.tree_status -cnotin @(
        '(clean)',
        '(clean benchmark inputs; orchestrator auto-chain marker excluded)'
      )) {
    throw 'CFF baseline Git identity is invalid.'
  }
  Assert-CffBenchmarkClosedKeys $Data.execution @(
    'command',
    'working_directory',
    'target',
    'release',
    'frozen',
    'output_encoding',
    'warmup_count',
    'retained_capture_count'
  ) 'CFF baseline execution schema'
  if ($Data.execution.command -cne $nativeCommand -or
      $Data.execution.working_directory -cne '.' -or
      $Data.execution.target -cne 'native' -or
      -not [bool]$Data.execution.release -or
      -not [bool]$Data.execution.frozen -or
      $Data.execution.output_encoding -cne 'normalized UTF-8 without BOM' -or
      [int]$Data.execution.warmup_count -ne 1 -or
      [int]$Data.execution.retained_capture_count -ne 7) {
    throw 'CFF baseline fixed execution identity drifted.'
  }
  if ($Data.execution.command -cmatch
      '(?:--package|--file|--index|--target\s+(?!native)|\bbench\s+(?!font-cff/cff_bench[.]mbt))') {
    throw 'CFF baseline command contains a filter, selector, or unscoped invocation.'
  }
  Assert-CffBenchmarkClosedKeys $Data.workspace @(
    'member_order',
    'resolution'
  ) 'CFF workspace evidence schema'
  Assert-CffBenchmarkExactSequence 'CFF workspace evidence members' `
    @($Data.workspace.member_order) $workspaceMembers
  Assert-CffBenchmarkClosedKeys $Data.workspace.resolution @(
    'module',
    'version',
    'manifest_sha256',
    'source_root',
    'local',
    'tracked',
    'empty_cache_entries'
  ) 'CFF workspace resolution schema'
  if ($Data.workspace.resolution.module -cne 'tchivs/mb-font' -or
      $Data.workspace.resolution.version -cne '0.1.0' -or
      $Data.workspace.resolution.source_root -cne 'modules/mb-font' -or
      -not [bool]$Data.workspace.resolution.local -or
      -not [bool]$Data.workspace.resolution.tracked -or
      [int]$Data.workspace.resolution.empty_cache_entries -ne 0) {
    throw 'CFF tracked-local workspace resolution drifted.'
  }
  Assert-CffBenchmarkSha256 `
    ([string]$Data.workspace.resolution.manifest_sha256) `
    'CFF workspace manifest digest'
  Assert-CffBenchmarkExactSequence 'CFF source paths' `
    @($Data.sources.path) $sourcePaths
  foreach ($source in $Data.sources) {
    Assert-CffBenchmarkClosedKeys $source @(
      'path',
      'length',
      'sha256'
    ) "CFF source $($source.path)"
    if ([int64]$source.length -le 0) {
      throw "CFF source length is invalid: $($source.path)"
    }
    Assert-CffBenchmarkSha256 ([string]$source.sha256) `
      "CFF source digest $($source.path)"
    if ($source.path -like 'artifacts/release-qualification/font-v3/*') {
      throw 'CFF benchmark source depends on ignored v3 evidence.'
    }
  }
  $canonicalSources = @(Get-CffBenchmarkSourceFacts -AllowTaskSources)
  if (($Data.sources | ConvertTo-Json -Depth 10) -cne
      ($canonicalSources | ConvertTo-Json -Depth 10)) {
    throw 'CFF tracked source length or digest facts drifted.'
  }
  Assert-CffBenchmarkExactSequence 'CFF evidence workload IDs' `
    @($Data.workloads.id) $workloadNames
  for ($index = 0; $index -lt $Data.workloads.Count; $index++) {
    $workload = $Data.workloads[$index]
    Assert-CffBenchmarkClosedKeys $workload @(
      'id',
      'test_name',
      'fixture_id',
      'operation',
      'gids',
      'correctness_input',
      'correctness_sha256'
    ) "CFF workload $index"
    if ($workload.test_name -cne $testNames[$index]) {
      throw "CFF benchmark test identity drifted at $index."
    }
    Assert-CffBenchmarkSha256 ([string]$workload.correctness_sha256) `
      "CFF workload digest $index"
  }
  $canonicalWorkloads = @(Get-CffBenchmarkWorkloads)
  if (($Data.workloads | ConvertTo-Json -Depth 10) -cne
      ($canonicalWorkloads | ConvertTo-Json -Depth 10)) {
    throw 'CFF canonical workload, GID, fixture, or correctness facts drifted.'
  }
  Assert-CffBenchmarkClosedKeys $Data.toolchain @(
    'moon',
    'moonc',
    'moonrun'
  ) 'CFF toolchain schema'
  foreach ($name in @('moon', 'moonc', 'moonrun')) {
    Assert-CffBenchmarkClosedKeys $Data.toolchain.$name @(
      'executable',
      'executable_sha256',
      'version_output_sha256',
      'version'
    ) "CFF toolchain $name"
    Assert-CffBenchmarkSha256 `
      ([string]$Data.toolchain.$name.executable_sha256) `
      "CFF toolchain executable $name"
    Assert-CffBenchmarkSha256 `
      ([string]$Data.toolchain.$name.version_output_sha256) `
      "CFF toolchain version $name"
  }
  Assert-CffBenchmarkClosedKeys $Data.host @(
    'powershell',
    'dotnet_runtime',
    'os',
    'cpu',
    'physical_memory_bytes',
    'active_power_scheme',
    'native_compiler'
  ) 'CFF host schema'
  foreach ($name in @('os', 'cpu', 'physical_memory_bytes', 'active_power_scheme')) {
    Assert-CffBenchmarkClosedKeys $Data.host.$name @(
      'value',
      'attempted'
    ) "CFF host $name"
    if ([string]::IsNullOrWhiteSpace([string]$Data.host.$name.value) -or
        [string]::IsNullOrWhiteSpace([string]$Data.host.$name.attempted)) {
      throw "CFF host fact is empty: $name"
    }
  }
  if ($Data.host.active_power_scheme.value -ne 'unavailable' -and
      $Data.host.active_power_scheme.value -cnotmatch
        '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
    throw 'CFF active power-scheme identity must be its locale-independent GUID.'
  }
  if ($Data.runs.Count -ne 8) {
    throw 'CFF baseline requires one excluded warmup and seven retained captures.'
  }
  $samples = @{}
  foreach ($name in $workloadNames) {
    $samples[$name] = @()
  }
  for ($runIndex = 0; $runIndex -lt 8; $runIndex++) {
    $run = $Data.runs[$runIndex]
    Assert-CffBenchmarkClosedKeys $run @(
      'id',
      'label',
      'started_utc',
      'ended_utc',
      'exit_code',
      'output_sha256',
      'summaries',
      'output'
    ) "CFF capture $runIndex"
    $expectedId = if ($runIndex -eq 0) { 'warmup' } else { "$runIndex" }
    $expectedLabel = if ($runIndex -eq 0) {
      'excluded warmup'
    } else {
      "retained capture $runIndex"
    }
    if ("$($run.id)" -cne $expectedId -or
        $run.label -cne $expectedLabel -or
        [int]$run.exit_code -ne 0) {
      throw "CFF capture identity/completeness drifted at $runIndex."
    }
    Assert-CffBenchmarkSha256 ([string]$run.output_sha256) `
      "CFF capture raw hash $runIndex"
    if ($run.output_sha256 -cne (
        Get-CffBenchmarkSha256Text (
          Normalize-CffBenchmarkText ([string]$run.output)
        )
      )) {
      throw "CFF capture raw output hash drifted at $runIndex."
    }
    Assert-CffBenchmarkExactSequence "CFF capture workload order $runIndex" `
      @($run.summaries.name) $workloadNames
    foreach ($summary in $run.summaries) {
      Assert-CffBenchmarkClosedKeys $summary @(
        'name',
        'mean_ms',
        'sigma_ms',
        'minimum_ms',
        'maximum_ms',
        'batch_size',
        'runs'
      ) "CFF capture summary $runIndex/$($summary.name)"
      foreach ($field in @(
          'mean_ms',
          'sigma_ms',
          'minimum_ms',
          'maximum_ms'
        )) {
        Assert-CffBenchmarkFiniteNonnegative $summary.$field `
          "CFF capture $runIndex $($summary.name) $field"
      }
      if ([double]$summary.minimum_ms -gt [double]$summary.mean_ms -or
          [double]$summary.mean_ms -gt [double]$summary.maximum_ms -or
          [int]$summary.batch_size -le 0 -or [int]$summary.runs -le 0) {
        throw "CFF capture summary is incomplete at $runIndex/$($summary.name)."
      }
    }
    if ($runIndex -gt 0) {
      foreach ($summary in $run.summaries) {
        $samples[$summary.name] += [double]$summary.mean_ms
      }
    }
  }
  Assert-CffBenchmarkExactSequence 'CFF aggregate order' `
    @($Data.aggregates.name) $workloadNames
  for ($index = 0; $index -lt $workloadNames.Count; $index++) {
    $aggregate = $Data.aggregates[$index]
    Assert-CffBenchmarkClosedKeys $aggregate @(
      'name',
      'values'
    ) "CFF aggregate $index"
    Assert-CffBenchmarkClosedKeys $aggregate.values @(
      'mean_ms',
      'median_ms',
      'sample_standard_deviation_ms',
      'minimum_ms',
      'maximum_ms',
      'coefficient_of_variation'
    ) "CFF aggregate values $index"
    $expected = Get-CffBenchmarkAggregate (
      [double[]]$samples[$workloadNames[$index]]
    )
    foreach ($field in @(
        'mean_ms',
        'median_ms',
        'sample_standard_deviation_ms',
        'minimum_ms',
        'maximum_ms',
        'coefficient_of_variation'
      )) {
      Assert-CffBenchmarkFiniteNonnegative $aggregate.values.$field `
        "CFF aggregate $index $field"
      if ("$($aggregate.values.$field)" -cne "$($expected.$field)") {
        throw "CFF aggregate statistic drifted at $index/$field."
      }
    }
  }
  if ($VerifyCurrentInputs) {
    $treeStatus = Assert-CffBenchmarkCleanTrackedState
    if ($Data.identity.tree_status -cne $treeStatus) {
      throw 'Current clean-tree exclusion identity drifted.'
    }
    $workspace = Assert-CffBenchmarkWorkspaceContract
    if ($Data.workspace.resolution.manifest_sha256 -cne
        $workspace.resolution.manifest_sha256) {
      throw 'Current tracked mb-font manifest identity drifted.'
    }
    $currentSources = @(Get-CffBenchmarkSourceFacts)
    for ($index = 0; $index -lt $currentSources.Count; $index++) {
      if ($Data.sources[$index].length -ne $currentSources[$index].length -or
          $Data.sources[$index].sha256 -cne
            $currentSources[$index].sha256) {
        throw "Current CFF source identity drifted at $index."
      }
    }
    $currentToolchain = Get-CffBenchmarkToolchain
    if (($Data.toolchain | ConvertTo-Json -Depth 10) -cne
        ($currentToolchain | ConvertTo-Json -Depth 10)) {
      throw 'Current CFF toolchain identity drifted.'
    }
    $currentHost = Get-CffBenchmarkHostFacts
    if (($Data.host | ConvertTo-Json -Depth 10) -cne
        ($currentHost | ConvertTo-Json -Depth 10)) {
      throw 'Current CFF host/compiler identity drifted.'
    }
    & git cat-file -e ($Data.identity.git_commit + '^{commit}') 2>$null
    if ($LASTEXITCODE -ne 0) {
      throw 'Recorded CFF source Git commit is unavailable.'
    }
  }
}

function New-CffBenchmarkContractEvidence {
  $workspace = Assert-CffBenchmarkWorkspaceContract
  $sources = @(Get-CffBenchmarkSourceFacts -AllowTaskSources)
  $workloads = @(Get-CffBenchmarkWorkloads)
  $runs = @()
  for ($runIndex = 0; $runIndex -lt 8; $runIndex++) {
    $summaries = @()
    $outputBuilder = New-Object Text.StringBuilder
    for ($workloadIndex = 0; $workloadIndex -lt 4; $workloadIndex++) {
      $mean = [Math]::Round(
        1.0 + $workloadIndex + ($runIndex * 0.1),
        9
      )
      $summary = [ordered]@{
        name = $workloadNames[$workloadIndex]
        mean_ms = $mean
        sigma_ms = 0.01
        minimum_ms = [Math]::Round($mean - 0.01, 9)
        maximum_ms = [Math]::Round($mean + 0.01, 9)
        batch_size = 1
        runs = 64
      }
      $summaries += $summary
      [void]$outputBuilder.Append(
        "[font-cff] bench cff_bench.mbt (`"bench $($testNames[$workloadIndex])`") ok`n"
      )
      [void]$outputBuilder.Append(
        ('  {0:F3} ms ± 0.010 ms {1:F3} ms … {2:F3} ms in 1 × 64 runs' -f
          $mean, ($mean - 0.01), ($mean + 0.01)) + "`n"
      )
    }
    $output = Normalize-CffBenchmarkText $outputBuilder.ToString()
    $runs += [ordered]@{
      id = if ($runIndex -eq 0) { 'warmup' } else { "$runIndex" }
      label = if ($runIndex -eq 0) {
        'excluded warmup'
      } else {
        "retained capture $runIndex"
      }
      started_utc = '2026-07-29T00:00:00.0000000Z'
      ended_utc = '2026-07-29T00:00:01.0000000Z'
      exit_code = 0
      output_sha256 = Get-CffBenchmarkSha256Text $output
      summaries = $summaries
      output = $output
    }
  }
  $aggregates = @()
  for ($workloadIndex = 0; $workloadIndex -lt 4; $workloadIndex++) {
    [double[]]$samples = @(
      $runs | Select-Object -Skip 1 |
        ForEach-Object { [double]$_.summaries[$workloadIndex].mean_ms }
    )
    $aggregates += [ordered]@{
      name = $workloadNames[$workloadIndex]
      values = Get-CffBenchmarkAggregate $samples
    }
  }
  $fakeTool = [ordered]@{
    executable = 'tool.exe'
    executable_sha256 = ('1' * 64)
    version_output_sha256 = ('2' * 64)
    version = 'tool 1.0'
  }
  [ordered]@{
    schema_version = 'mnf-mb-font-cff-native-baseline/1.0.0'
    claim = [ordered]@{
      type = 'observation_only'
      interpretation = 'native release measurements for exact reproduction facts only'
    }
    identity = [ordered]@{
      git_commit = ('a' * 40)
      tree_status = '(clean benchmark inputs; orchestrator auto-chain marker excluded)'
    }
    execution = [ordered]@{
      command = $nativeCommand
      working_directory = '.'
      target = 'native'
      release = $true
      frozen = $true
      output_encoding = 'normalized UTF-8 without BOM'
      warmup_count = 1
      retained_capture_count = 7
    }
    workspace = $workspace
    sources = $sources
    workloads = $workloads
    toolchain = [ordered]@{
      moon = $fakeTool
      moonc = $fakeTool
      moonrun = $fakeTool
    }
    host = [ordered]@{
      powershell = [ordered]@{
        version = '7.0'
        edition = 'Core'
        executable = 'pwsh.exe'
        executable_sha256 = ('3' * 64)
      }
      dotnet_runtime = '8.0'
      os = [ordered]@{ value = 'test-os'; attempted = 'test-os-probe' }
      cpu = [ordered]@{ value = 'test-cpu'; attempted = 'test-cpu-probe' }
      physical_memory_bytes = [ordered]@{
        value = '1'
        attempted = 'test-memory-probe'
      }
      active_power_scheme = [ordered]@{
        value = '381b4222-f694-41f0-9685-ff5bb260df2e'
        attempted = 'test-power-probe'
      }
      native_compiler = [ordered]@{
        executable = 'clang.exe'
        executable_sha256 = ('4' * 64)
        version = 'clang 1'
        probe = 'clang.exe --version'
      }
    }
    runs = $runs
    aggregates = $aggregates
  }
}

function Invoke-CffBenchmarkSyntheticPostProcessing {
  $treeStatus = Assert-CffBenchmarkCleanTrackedState
  $evidence = New-CffBenchmarkContractEvidence
  $evidence.identity.git_commit = (& git rev-parse HEAD).Trim()
  $evidence.identity.tree_status = $treeStatus
  $evidence.sources = @(Get-CffBenchmarkSourceFacts)
  $evidence.toolchain = Get-CffBenchmarkToolchain
  $evidence.host = Get-CffBenchmarkHostFacts
  Assert-CffBenchmarkEvidence $evidence -VerifyCurrentInputs

  $relativePath = (
    'docs/benchmarks/.cff-contract-' + [guid]::NewGuid().ToString('N') + '.md'
  )
  $destination = Join-Path $repoRoot $relativePath
  if (Test-Path -LiteralPath $destination) {
    throw "Synthetic CFF post-processing destination already exists: $relativePath"
  }
  try {
    Write-CffBenchmarkDocumentAtomically $evidence $destination
    Write-CffBenchmarkDocumentAtomically $evidence $destination
    $document = $utf8.GetString([IO.File]::ReadAllBytes($destination))
    Test-CffBenchmarkDocument $document
    $bytes = [IO.File]::ReadAllBytes($destination)
    $digest = Get-CffBenchmarkSha256Bytes $bytes
    $policy = Get-Content -Raw -LiteralPath (
      Join-Path $repoRoot 'policy/foundation.json'
    ) | ConvertFrom-Json
    $fontModule = @(
      $policy.modules | Where-Object { $_.name -ceq 'tchivs/mb-font' }
    )[0]
    $staged = $fontModule.qualification.native_benchmark_baseline |
      ConvertTo-Json -Depth 10 |
      ConvertFrom-Json
    $staged.status = 'recorded-observation-only'
    $staged.length = [int64]$bytes.Length
    $staged.sha256 = $digest
    Assert-CffBenchmarkClosedKeys $staged @(
      'status',
      'path',
      'length',
      'sha256',
      'schema_version',
      'claim',
      'command',
      'workload_order',
      'warmup_count',
      'retained_capture_count',
      'statistics',
      'audit_owner'
    ) 'Synthetic CFF policy digest staging'
    if ($staged.path -cne
          'docs/benchmarks/mb-font-cff-native-release-baseline.md' -or
        $staged.status -cne 'recorded-observation-only' -or
        $staged.length -ne $bytes.Length -or
        $staged.sha256 -cne (Get-CffBenchmarkSha256File $destination) -or
        $staged.claim -cne 'observation_only') {
      throw 'Synthetic CFF policy/baseline digest staging drifted.'
    }
  } finally {
    if (Test-Path -LiteralPath $destination) {
      Remove-Item -LiteralPath $destination -Force
    }
  }
  $afterStatus = Assert-CffBenchmarkCleanTrackedState
  if ($afterStatus -cne $treeStatus) {
    throw 'Synthetic CFF post-processing cleanup changed clean-tree identity.'
  }
  Write-Host (
    'CFF synthetic post-processing passed: pre-temp current inputs, atomic ' +
    'round-trip, audit reconstruction, policy digest staging, and cleanup.'
  )
}

function Copy-CffBenchmarkEvidence([object]$Evidence) {
  $Evidence | ConvertTo-Json -Depth 30 | ConvertFrom-Json
}

function Confirm-CffBenchmarkRejected(
  [string]$Label,
  [object]$Evidence,
  [scriptblock]$Mutate,
  [string]$Pattern
) {
  $copy = Copy-CffBenchmarkEvidence $Evidence
  & $Mutate $copy
  try {
    Assert-CffBenchmarkEvidence $copy
  } catch {
    if ($_.Exception.Message -notmatch $Pattern) {
      throw "CFF negative '$Label' failed for the wrong reason: $($_.Exception.Message)"
    }
    Write-Host "CFF benchmark negative rejected: $Label"
    return
  }
  throw "CFF benchmark negative unexpectedly passed: $Label"
}

function Invoke-CffBenchmarkContractOnly {
  Assert-CffBenchmarkWorkspaceContract | Out-Null
  Assert-CffBenchmarkSourceContract
  $contractOutputs = @(New-CffBenchmarkContractEvidence)
  if ($contractOutputs.Count -ne 1) {
    throw (
      'CFF contract fixture leaked pipeline values: ' +
      (@($contractOutputs | ForEach-Object { $_.GetType().FullName }) -join ', ')
    )
  }
  $evidence = $contractOutputs[0]
  Assert-CffBenchmarkEvidence $evidence
  $parsed = Convert-CffBenchmarkOutput $evidence.runs[0].output
  Assert-CffBenchmarkExactSequence 'Synthetic parser workloads' `
    @($parsed.name) $workloadNames
  $document = New-CffBenchmarkDocument $evidence
  $roundTripData = Get-CffBenchmarkAuditData $document
  $roundTripSections = @(Get-CffBenchmarkVisibleSections $document)
  $roundTripEvidence = New-CffBenchmarkRenderedEvidence `
    $roundTripData $roundTripSections
  Assert-CffBenchmarkEvidence $roundTripEvidence
  Assert-CffBenchmarkVisibleDocument $document $roundTripEvidence
  $negatives = @(
    @('workspace-order', { param($e) [Array]::Reverse($e.workspace.member_order) }, 'workspace evidence members'),
    @('external-fallback', { param($e) $e.workspace.resolution.local = $false }, 'tracked-local workspace'),
    @('fixture-id', { param($e) $e.workloads[0].fixture_id = 'other' }, 'Current canonical|workload'),
    @('workload-order', { param($e) [Array]::Reverse($e.workloads) }, 'workload IDs'),
    @('gid', { param($e) $e.workloads[2].gids[0] = 999 }, 'Current canonical|workload'),
    @('correctness-digest', { param($e) $e.workloads[0].correctness_sha256 = ('0' * 64) }, 'canonical workload'),
    @('source-digest', { param($e) $e.sources[0].sha256 = ('0' * 64) }, 'tracked source'),
    @('toolchain-digest', { param($e) $e.toolchain.moon.executable_sha256 = ('0' * 63) }, 'toolchain executable'),
    @('host-fact', { param($e) $e.host.cpu.value = '' }, 'host fact'),
    @('git-digest', { param($e) $e.identity.git_commit = ('0' * 39) }, 'Git identity'),
    @('warmup-count', { param($e) $e.execution.warmup_count = 0 }, 'execution identity'),
    @('capture-count', { param($e) $e.runs = @($e.runs | Select-Object -First 7) }, 'one excluded warmup'),
    @('capture-completeness', { param($e) $e.runs[1].summaries = @($e.runs[1].summaries | Select-Object -First 3) }, 'workload order'),
    @('raw-hash', { param($e) $e.runs[0].output_sha256 = ('0' * 64) }, 'raw output hash'),
    @('mean', { param($e) $e.aggregates[0].values.mean_ms = 999 }, 'statistic'),
    @('median', { param($e) $e.aggregates[0].values.median_ms = 999 }, 'statistic'),
    @('sample-standard-deviation', { param($e) $e.aggregates[0].values.sample_standard_deviation_ms = 999 }, 'statistic'),
    @('minimum', { param($e) $e.aggregates[0].values.minimum_ms = 999 }, 'statistic'),
    @('maximum', { param($e) $e.aggregates[0].values.maximum_ms = 999 }, 'statistic'),
    @('coefficient-of-variation', { param($e) $e.aggregates[0].values.coefficient_of_variation = 999 }, 'statistic'),
    @('negative-sample', { param($e) $e.runs[1].summaries[0].mean_ms = -1 }, 'finite and nonnegative'),
    @('nonfinite-sample', { param($e) $e.runs[1].summaries[0].mean_ms = [double]::NaN }, 'finite and nonnegative'),
    @('command', { param($e) $e.execution.command += ' --index 0' }, 'execution identity'),
    @('ignored-v3-input', { param($e) $e.sources[0].path = 'artifacts/release-qualification/font-v3/js.json' }, 'source paths|ignored v3'),
    @('forbidden-claim-field', { param($e) $e.claim | Add-Member NoteProperty threshold_ms 1 }, 'claim schema'),
    @('claim-type', { param($e) $e.claim.type = 'regression_verdict' }, 'observation_only')
  )
  foreach ($negative in $negatives) {
    Confirm-CffBenchmarkRejected $negative[0] $evidence $negative[1] $negative[2]
  }
  $scriptText = Get-Content -Raw -LiteralPath $PSCommandPath
  $auditBody = [regex]::Match(
    $scriptText,
    '(?s)function Invoke-CffBenchmarkReadOnlyAudit \{(?<body>.*?)\n\}'
  ).Groups['body'].Value
  if (-not $auditBody -or
      $auditBody -cmatch
        '(?i)Invoke-CffNativeCapture|WriteAllText|Move-Item|Start-Process|&\s*moon\b') {
    throw 'CFF audit mutation/read-only source contract drifted.'
  }
  $recordBody = [regex]::Match(
    $scriptText,
    '(?s)function Invoke-CffBenchmarkRecord \{(?<body>.*?)\n\}'
  ).Groups['body'].Value
  if (-not $recordBody -or
      ([regex]::Matches(
        $recordBody,
        'Assert-CffBenchmarkEvidence \$evidence -VerifyCurrentInputs'
      )).Count -ne 1 -or
      $recordBody -cmatch
        'Assert-CffBenchmarkEvidence \$roundTripEvidence -VerifyCurrentInputs') {
    throw (
      'CFF record must verify current inputs before temp creation and validate ' +
      'the in-repository temp round-trip without reclassifying its own temp file.'
    )
  }
  $atomicBody = [regex]::Match(
    $scriptText,
    '(?s)function Write-CffBenchmarkDocumentAtomically\(.*?\) \{(?<body>.*?)\n\}'
  ).Groups['body'].Value
  if (-not $atomicBody -or
      $atomicBody -cnotmatch 'Test-CffBenchmarkDocument \$roundTrip' -or
      $atomicBody -cmatch 'VerifyCurrentInputs') {
    throw 'CFF atomic round-trip must validate content without dirty-state recursion.'
  }
  Invoke-CffBenchmarkSyntheticPostProcessing
  Write-Host (
    'CFF benchmark contract passed: exact workspace/workloads/fresh budgets, ' +
    'closed one-plus-seven evidence, six statistics, read-only audit, and negatives.'
  )
}

function Assert-CffBenchmarkVisibleDocument(
  [string]$Document,
  [object]$Evidence
) {
  $expected = New-CffBenchmarkDocument $Evidence
  if ($Document -cne $expected) {
    throw 'CFF baseline Markdown differs from canonical rendering.'
  }
}

function Test-CffBenchmarkDocument(
  [string]$Document,
  [switch]$VerifyCurrentInputs
) {
  $data = Get-CffBenchmarkAuditData $Document
  $sections = @(Get-CffBenchmarkVisibleSections $Document)
  $evidence = New-CffBenchmarkRenderedEvidence $data $sections
  Assert-CffBenchmarkEvidence $evidence `
    -VerifyCurrentInputs:$VerifyCurrentInputs
  for ($index = 0; $index -lt $evidence.runs.Count; $index++) {
    $parsed = @(Convert-CffBenchmarkOutput $evidence.runs[$index].output)
    if (($parsed | ConvertTo-Json -Depth 10) -cne
        ($evidence.runs[$index].summaries | ConvertTo-Json -Depth 10)) {
      throw "CFF raw output summary drifted at capture $index."
    }
  }
  Assert-CffBenchmarkVisibleDocument $Document $evidence
}

function Write-CffBenchmarkDocumentAtomically(
  [object]$Evidence,
  [string]$Destination
) {
  $document = New-CffBenchmarkDocument $Evidence
  $directory = Split-Path -Parent $Destination
  if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $directory)
  }
  $tempPath = Join-Path $directory (
    '.' + [IO.Path]::GetFileNameWithoutExtension($Destination) + '.' +
    [guid]::NewGuid().ToString('N') + '.tmp'
  )
  $backupPath = $tempPath + '.bak'
  try {
    [IO.File]::WriteAllText($tempPath, $document, $utf8)
    $roundTrip = $utf8.GetString([IO.File]::ReadAllBytes($tempPath))
    Test-CffBenchmarkDocument $roundTrip
    if (Test-Path -LiteralPath $Destination) {
      [IO.File]::Replace($tempPath, $Destination, $backupPath, $true)
    } else {
      [IO.File]::Move($tempPath, $Destination)
    }
  } finally {
    if (Test-Path -LiteralPath $tempPath) {
      Remove-Item -LiteralPath $tempPath -Force
    }
    if (Test-Path -LiteralPath $backupPath) {
      Remove-Item -LiteralPath $backupPath -Force
    }
  }
}

function Invoke-CffBenchmarkReadOnlyAudit {
  $null = Assert-CffBenchmarkCleanTrackedState
  if (-not (Test-Path -LiteralPath $baselinePath -PathType Leaf)) {
    throw "CFF baseline is missing: $baselinePath"
  }
  $document = $utf8.GetString([IO.File]::ReadAllBytes($baselinePath))
  Test-CffBenchmarkDocument $document -VerifyCurrentInputs
  Write-Host (
    'CFF native baseline audit passed: tracked inputs, workspace, raw hashes, ' +
    'one excluded warmup, seven retained captures, and six statistics verified read-only.'
  )
}

function Invoke-CffBenchmarkRecord {
  $treeStatus = Assert-CffBenchmarkCleanTrackedState
  Assert-CffBenchmarkSourceContract
  $workspace = Invoke-CffBenchmarkWorkspaceResolution
  $sources = @(Get-CffBenchmarkSourceFacts)
  $workloads = @(Get-CffBenchmarkWorkloads)
  $toolchain = Get-CffBenchmarkToolchain
  $hostFacts = Get-CffBenchmarkHostFacts
  Write-Host 'Running one excluded warmup...'
  $runs = @((Invoke-CffNativeCapture 'warmup' 'excluded warmup'))
  for ($capture = 1; $capture -le 7; $capture++) {
    Write-Host "Recording retained capture $capture of 7..."
    $runs += Invoke-CffNativeCapture "$capture" "retained capture $capture"
  }
  $aggregates = @()
  for ($workloadIndex = 0; $workloadIndex -lt 4; $workloadIndex++) {
    [double[]]$samples = @(
      $runs | Select-Object -Skip 1 |
        ForEach-Object { [double]$_.summaries[$workloadIndex].mean_ms }
    )
    $aggregates += [ordered]@{
      name = $workloadNames[$workloadIndex]
      values = Get-CffBenchmarkAggregate $samples
    }
  }
  $evidence = [ordered]@{
    schema_version = 'mnf-mb-font-cff-native-baseline/1.0.0'
    claim = [ordered]@{
      type = 'observation_only'
      interpretation = 'native release measurements for exact reproduction facts only'
    }
    identity = [ordered]@{
      git_commit = (& git rev-parse HEAD).Trim()
      tree_status = $treeStatus
    }
    execution = [ordered]@{
      command = $nativeCommand
      working_directory = '.'
      target = 'native'
      release = $true
      frozen = $true
      output_encoding = 'normalized UTF-8 without BOM'
      warmup_count = 1
      retained_capture_count = 7
    }
    workspace = $workspace
    sources = $sources
    workloads = $workloads
    toolchain = $toolchain
    host = $hostFacts
    runs = $runs
    aggregates = $aggregates
  }
  Assert-CffBenchmarkEvidence $evidence -VerifyCurrentInputs
  Write-CffBenchmarkDocumentAtomically $evidence $baselinePath
  Write-Host "CFF native baseline recorded atomically: $baselinePath"
}

$modeCount = @(
  $CheckWorkspaceResolution,
  $ContractOnly,
  $Record,
  $Audit
) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
if ($modeCount -ne 1) {
  throw 'Select exactly one CFF benchmark mode.'
}

$previousLocation = Get-Location
try {
  Set-Location -LiteralPath $repoRoot
  if ($CheckWorkspaceResolution) {
    Invoke-CffBenchmarkWorkspaceResolution | Out-Null
    return
  }
  if ($ContractOnly) {
    Invoke-CffBenchmarkContractOnly
    return
  }
  if ($Record) {
    Invoke-CffBenchmarkRecord
    return
  }
  Invoke-CffBenchmarkReadOnlyAudit
} finally {
  Set-Location -LiteralPath $previousLocation
}
