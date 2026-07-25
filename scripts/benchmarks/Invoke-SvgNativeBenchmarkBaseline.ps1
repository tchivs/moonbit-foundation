[CmdletBinding()]
param(
  [switch]$Audit
)

# This is evidence capture, not a performance gate.  It deliberately has no
# caller-configurable command, threshold, or comparison decision.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$baselinePath = Join-Path $repoRoot 'docs\benchmarks\mb-svg-native-release-baseline.md'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$nativeCommand = 'moon bench modules/mb-svg/svg --release --target native --frozen'
$workloadNames = @(
  'path-parse/1000-line-to',
  'transform-composition/50-segment',
  'parse-to-lower/50-rect'
)

function Get-Sha256Bytes([byte[]]$Bytes) {
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    [BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant()
  } finally {
    $sha.Dispose()
  }
}

function Get-Sha256Text([string]$Text) {
  Get-Sha256Bytes $utf8.GetBytes($Text)
}

function Get-Sha256File([string]$Path) {
  Get-Sha256Bytes ([IO.File]::ReadAllBytes($Path))
}

function Normalize-Text([string]$Text) {
  $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
  if (!$normalized.EndsWith("`n")) { $normalized += "`n" }
  $normalized
}

function Format-Number([double]$Value) {
  $Value.ToString('F9', [Globalization.CultureInfo]::InvariantCulture)
}

function Assert-CleanWorktree {
  $status = (& git status --porcelain=v1 --untracked-files=all | Out-String)
  if (![string]::IsNullOrEmpty($status)) {
    throw 'A clean worktree is required: git status --porcelain=v1 --untracked-files=all produced output.'
  }
}

function New-WorkloadRecords {
  $pathCorpus = 'M0 0'
  for ($i = 0; $i -lt 1000; $i++) {
    $pathCorpus += ' L' + ($i % 100).ToString([Globalization.CultureInfo]::InvariantCulture) + ' ' + ($i % 100).ToString([Globalization.CultureInfo]::InvariantCulture)
  }
  $transformCorpus = ''
  for ($i = 0; $i -lt 10; $i++) {
    $transformCorpus += 'translate(1,1) scale(2) rotate(15) skewX(5) skewY(3)'
  }
  $svgCorpus = '<svg>'
  for ($i = 0; $i -lt 50; $i++) {
    $svgCorpus += '<rect x="' + $i.ToString([Globalization.CultureInfo]::InvariantCulture) + '" y="0" width="1" height="1" fill="red"/>'
  }
  $svgCorpus += '</svg>'
  $records = @(
    [ordered]@{ name = $workloadNames[0]; corpus = $pathCorpus; correctness = 'v1|ok|commands=1001|first=M(0,0)|last=L(99,99)'; corpus_expected = 'e97e1c8a8e29fdb3e84c309e421de34d41cbab7583cf1e88cf94a67af51eb259'; correctness_expected = '0c7d3af32d324a136215c1158c4aab127d11e160f4b9239991114a0303762f22' },
    [ordered]@{ name = $workloadNames[1]; corpus = $transformCorpus; correctness = 'v1|ok|a=-764.5825470346006|b=981.6717123516748|c=-550.8736348781798|d=-664.151879387284|tx=-1060.1606213143448|ty=997.9648720635827|probe_x=1.25|probe_y=-2.5|out_x=-638.704717912146|out_y=3885.434210971386|tolerance=1e-9'; corpus_expected = 'c0ed3307e143d7cb20fd90e531e6208a14bbe2e42ce2816a0579d04cbd320840'; correctness_expected = 'ec32349185e19b24757e391c72ac5fa8709f889847a0035b7257fc3e0ba483ff' },
    [ordered]@{ name = $workloadNames[2]; corpus = $svgCorpus; correctness = 'v1|ok|ops=50|all=Fill'; corpus_expected = 'db053c95e904e016041f8b2f4a5e6471ed4bf1b144cfd0fc99c44d7d670cdddc'; correctness_expected = 'e76479b6744a5f062c21d7e5502971a45388346767e9d91aea0119c4340c18e5' }
  )
  foreach ($record in $records) {
    $null = $record.corpus_sha256 = Get-Sha256Text $record.corpus
    $null = $record.correctness_sha256 = Get-Sha256Text $record.correctness
    if ($record.corpus_sha256 -cne $record.corpus_expected -or $record.correctness_sha256 -cne $record.correctness_expected) {
      throw "Frozen digest literal mismatch: $($record.name)"
    }
  }
  $records
}

function Get-ToolOutput([string]$Command, [string[]]$Arguments) {
  $output = (& $Command @Arguments 2>&1 | Out-String).TrimEnd("`r", "`n")
  if ($LASTEXITCODE -ne 0) { throw "Tool identity command failed: $Command" }
  $output
}

function Get-Probe([string]$Attempted, [scriptblock]$Probe) {
  try {
    [ordered]@{ value = (& $Probe | Out-String).TrimEnd("`r", "`n"); attempted = $Attempted }
  } catch {
    [ordered]@{ value = 'unavailable'; attempted = $Attempted }
  }
}

function Get-HostFacts {
  $os = Get-Probe 'Get-CimInstance Win32_OperatingSystem' {
    $value = Get-CimInstance Win32_OperatingSystem
    "$($value.Caption) | version=$($value.Version) | build=$($value.BuildNumber) | architecture=$($value.OSArchitecture)"
  }
  $cpu = Get-Probe 'Get-CimInstance Win32_Processor | Select-Object -First 1' {
    $value = Get-CimInstance Win32_Processor | Select-Object -First 1
    "$($value.Name.Trim()) | physical_cores=$($value.NumberOfCores) | logical_processors=$($value.NumberOfLogicalProcessors)"
  }
  $memory = Get-Probe 'Get-CimInstance Win32_ComputerSystem' {
    (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory.ToString([Globalization.CultureInfo]::InvariantCulture)
  }
  $power = Get-Probe 'powercfg /GETACTIVESCHEME' { & powercfg /GETACTIVESCHEME }
  [ordered]@{
    powershell = $PSVersionTable.PSVersion.ToString()
    dotnet_runtime = [Environment]::Version.ToString()
    os = $os
    cpu = $cpu
    physical_memory_bytes = $memory
    active_power_scheme = $power
  }
}

function Get-PolicyAndToolchain {
  $policyPath = Join-Path $repoRoot 'policy\foundation.json'
  $policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json
  $raw = [ordered]@{
    moon = Get-ToolOutput 'moon' @('--version')
    moonc = Get-ToolOutput 'moonc' @('-v')
    moonrun = Get-ToolOutput 'moonrun' @('--version')
  }
  $expected = [ordered]@{
    moon = $policy.toolchain.moon.version + ' (' + $policy.toolchain.moon.commit + ' ' + $policy.toolchain.moon.release_date + ')'
    moonc = $policy.toolchain.moonc.version + ' (' + $policy.toolchain.moonc.release_date + ')'
    moonrun = $policy.toolchain.moonrun.version + ' (' + $policy.toolchain.moonrun.commit + ' ' + $policy.toolchain.moonrun.release_date + ')'
  }
  foreach ($key in @('moon', 'moonc', 'moonrun')) {
    foreach ($field in @('version', 'commit', 'release_date')) {
      $property = $policy.toolchain.$key.PSObject.Properties[$field]
      if ($null -ne $property -and $raw[$key] -notlike "*$($property.Value)*") {
        throw "Toolchain policy mismatch for ${key}: expected $field $($property.Value), observed $($raw[$key])"
      }
    }
  }
  [ordered]@{ raw = $raw; policy_expected = $expected }
}

function Convert-ToMilliseconds([double]$Value, [string]$Unit) {
  if ($Unit -eq 'ns') { return $Value / 1000000.0 }
  if ($Unit -eq (([char]0x00B5).ToString() + 's')) { return $Value / 1000.0 }
  if ($Unit -eq 'ms') { return $Value }
  if ($Unit -eq 's') { return $Value * 1000.0 }
  throw "Unknown benchmark unit: $Unit"
}

function Convert-BenchmarkOutput([string]$Text) {
  $summaries = @()
  $currentName = $null
  foreach ($line in ($Text -split "`n")) {
    if ($line -match '^\[.+\] bench .+ \("bench (?<name>[^\"]+)"\) ok$') {
      $currentName = $Matches.name
      continue
    }
    if ($null -ne $currentName -and $line -match '^\s*(?<mean>[0-9.]+)\s+(?<mu>ns|\u00b5s|ms|s)\s+\u00b1\s+(?<sigma>[0-9.]+)\s+(?<su>ns|\u00b5s|ms|s)\s+(?<min>[0-9.]+)\s+(?<minu>ns|\u00b5s|ms|s)\s+\u2026\s+(?<max>[0-9.]+)\s+(?<maxu>ns|\u00b5s|ms|s)\s+in\s+(?<batch>\d+)\s+\u00d7\s+(?<runs>\d+)\s+runs$') {
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
  if ($summaries.Count -ne $workloadNames.Count) { throw "Expected $($workloadNames.Count) workload summaries, parsed $($summaries.Count)." }
  for ($index = 0; $index -lt $workloadNames.Count; $index++) {
    if ($summaries[$index].name -cne $workloadNames[$index]) { throw "Runner workload order mismatch at index $index." }
  }
  $summaries
}

function Invoke-NativeCapture([string]$Id, [string]$Label) {
  $started = [DateTime]::UtcNow.ToString('o')
  # cmd.exe performs the literal command's 2>&1 redirection before PowerShell
  # sees it, avoiding PowerShell's NativeCommandError treatment of warnings.
  $startInfo = New-Object System.Diagnostics.ProcessStartInfo
  $startInfo.FileName = $env:ComSpec
  $startInfo.Arguments = '/d /c "' + $nativeCommand + ' 2>&1"'
  $startInfo.WorkingDirectory = $repoRoot
  $startInfo.UseShellExecute = $false
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true
  # Moon emits UTF-8; pin both redirected streams so evidence does not depend
  # on the host ANSI code page before it is normalized, hashed, and rendered.
  $startInfo.StandardOutputEncoding = $utf8
  $startInfo.StandardErrorEncoding = $utf8
  $process = New-Object System.Diagnostics.Process
  $process.StartInfo = $startInfo
  if (!$process.Start()) { throw "Could not start native benchmark $Label." }
  $stdoutTask = $process.StandardOutput.ReadToEndAsync()
  $stderrTask = $process.StandardError.ReadToEndAsync()
  $process.WaitForExit()
  $stdout = $stdoutTask.GetAwaiter().GetResult()
  $stderr = $stderrTask.GetAwaiter().GetResult()
  $exitCode = $process.ExitCode
  $merged = if ([string]::IsNullOrEmpty($stderr)) { $stdout } else { $stdout + "`n" + $stderr }
  $output = Normalize-Text $merged
  $ended = [DateTime]::UtcNow.ToString('o')
  if ($exitCode -ne 0) { throw "Native benchmark $Label failed with exit code $exitCode." }
  [ordered]@{
    id = $Id
    label = $Label
    started_utc = $started
    ended_utc = $ended
    exit_code = $exitCode
    output_sha256 = Get-Sha256Text $output
    summaries = @(Convert-BenchmarkOutput $output)
    output = $output
  }
}

function Get-Aggregate([double[]]$Samples) {
  if ($Samples.Count -ne 7) { throw 'A native evidence aggregate requires exactly seven retained samples.' }
  $sorted = @($Samples | Sort-Object)
  $mean = ($Samples | Measure-Object -Average).Average
  $sumSquares = 0.0
  foreach ($sample in $Samples) { $sumSquares += [Math]::Pow($sample - $mean, 2) }
  $stddev = [Math]::Sqrt($sumSquares / ($Samples.Count - 1))
  [ordered]@{
    mean_ms = [Math]::Round($mean, 9)
    median_ms = [Math]::Round($sorted[3], 9)
    sample_standard_deviation_ms = [Math]::Round($stddev, 9)
    minimum_ms = [Math]::Round($sorted[0], 9)
    maximum_ms = [Math]::Round($sorted[-1], 9)
    coefficient_of_variation = [Math]::Round($stddev / $mean, 9)
  }
}

function Add-Line([Text.StringBuilder]$Builder, [string]$Text = '') {
  [void]$Builder.Append($Text)
  [void]$Builder.Append("`n")
}

function Convert-ToHtmlPre([string]$Text) {
  $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace(' ', '&#32;')
}

function Convert-ToAsciiJson([object]$Value) {
  $json = $Value | ConvertTo-Json -Depth 12
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

function Get-NamedValue([object]$Object, [string]$Name) {
  if ($Object -is [Collections.IDictionary]) { return $Object[$Name] }
  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) { throw "Missing required evidence field: $Name" }
  $property.Value
}

function Add-RunMarkdown([Text.StringBuilder]$Builder, [object]$Run) {
  $title = if ($Run.id -eq 'warmup') { 'Warmup (excluded from summary)' } else { 'Capture ' + $Run.id }
  Add-Line $Builder ('### ' + $title)
  Add-Line $Builder ('- UTC start: `' + $Run.started_utc + '`')
  Add-Line $Builder ('- UTC end: `' + $Run.ended_utc + '`')
  Add-Line $Builder ('- Exit status: `' + $Run.exit_code + '`')
  Add-Line $Builder ('- Output SHA-256: `' + $Run.output_sha256 + '`')
  Add-Line $Builder '- Fixed workload order: `path-parse/1000-line-to`, `transform-composition/50-segment`, `parse-to-lower/50-rect`'
  Add-Line $Builder ''
  Add-Line $Builder '| Workload | Mean (ms) | Sigma (ms) | Minimum (ms) | Maximum (ms) | Batch | Runs |'
  Add-Line $Builder '| --- | ---: | ---: | ---: | ---: | ---: | ---: |'
  foreach ($summary in $Run.summaries) {
    Add-Line $Builder ('| ' + $summary.name + ' | ' + (Format-Number $summary.mean_ms) + ' | ' + (Format-Number $summary.sigma_ms) + ' | ' + (Format-Number $summary.min_ms) + ' | ' + (Format-Number $summary.max_ms) + ' | ' + $summary.batch_size + ' | ' + $summary.runs + ' |')
  }
  Add-Line $Builder ''
  Add-Line $Builder '<details>'
  Add-Line $Builder '<summary>Complete normalized UTF-8 merged stdout/stderr</summary>'
  Add-Line $Builder ''
  Add-Line $Builder '<pre class="svg-native-output">'
  [void]$Builder.Append((Convert-ToHtmlPre $Run.output.TrimEnd("`n".ToCharArray())))
  Add-Line $Builder ''
  Add-Line $Builder '</pre>'
  Add-Line $Builder '</details>'
  Add-Line $Builder ''
}

function New-BaselineDocument([object]$Evidence) {
  $builder = New-Object Text.StringBuilder
  Add-Line $builder '# mb-svg native release baseline'
  Add-Line $builder ''
  Add-Line $builder '**Scope:** A native-host observation for like-for-like reproduction only. It makes no cross-target comparison, threshold, ranking, CI gate, regression conclusion, or marketing claim.'
  Add-Line $builder ''
  Add-Line $builder '## Comparison identity'
  Add-Line $builder ''
  Add-Line $builder ('- Git commit: `' + $Evidence.identity.git_commit + '`')
  Add-Line $builder '- worktree: (clean)'
  Add-Line $builder ('- Working directory: `' + $Evidence.execution.working_directory + '`')
  Add-Line $builder ('- Exact native command: `' + $Evidence.execution.command + '`')
  Add-Line $builder '- Comparison rule: comparable only if workload order/names, command, target, release mode, frozen mode, source/corpus/correctness digests, toolchain identity, and every recorded host fact agree exactly. Otherwise the records are **not comparable** and no inference is made.'
  Add-Line $builder ''
  Add-Line $builder '## Functional qualification context (not timing evidence)'
  Add-Line $builder ''
  Add-Line $builder '- Qualification command: `moon bench modules/mb-svg/svg --target all --frozen`'
  Add-Line $builder '- Successful target labels: `wasm`, `wasm-gc`, `js`, `native`. No timing values from that command are retained here.'
  Add-Line $builder ''
  Add-Line $builder '## Workload and source provenance'
  Add-Line $builder ''
  Add-Line $builder '| Workload | Corpus SHA-256 | Canonical correctness SHA-256 |'
  Add-Line $builder '| --- | --- | --- |'
  foreach ($workload in $Evidence.workloads) {
    Add-Line $builder ('| ' + $workload.name + ' | `' + $workload.corpus_sha256 + '` | `' + $workload.correctness_sha256 + '` |')
  }
  Add-Line $builder ''
  Add-Line $builder ('- `svg_bench.mbt` SHA-256: `' + $Evidence.source.svg_bench_sha256 + '`')
  Add-Line $builder ('- `moon.pkg` SHA-256: `' + $Evidence.source.moon_pkg_sha256 + '`')
  Add-Line $builder ('- Combined source SHA-256: `' + $Evidence.source.combined_sha256 + '`')
  Add-Line $builder ''
  Add-Line $builder '## Toolchain and host facts'
  Add-Line $builder ''
  foreach ($key in @('moon', 'moonc', 'moonrun')) {
    Add-Line $builder ('- ' + $key + ' observed: `' + (Get-NamedValue $Evidence.toolchain.raw $key) + '`')
    Add-Line $builder ('- ' + $key + ' policy: `' + (Get-NamedValue $Evidence.toolchain.policy_expected $key) + '`')
  }
  Add-Line $builder ('- PowerShell: `' + $Evidence.host.powershell + '`; .NET runtime: `' + $Evidence.host.dotnet_runtime + '`')
  foreach ($key in @('os', 'cpu', 'physical_memory_bytes', 'active_power_scheme')) {
    $fact = Get-NamedValue $Evidence.host $key
    Add-Line $builder ('- ' + $key + ': `' + $fact.value + '` (probe: `' + $fact.attempted + '`)')
  }
  Add-Line $builder ''
  Add-Line $builder '## Captures'
  Add-Line $builder ''
  Add-Line $builder 'One successful warmup is retained for provenance and excluded from all statistics. Captures 1 through 7 are separate successful native release invocations.'
  Add-Line $builder ''
  foreach ($run in $Evidence.runs) { Add-RunMarkdown $builder $run }
  Add-Line $builder '## Native-host-specific seven-capture summary'
  Add-Line $builder ''
  Add-Line $builder '| Workload | Arithmetic mean (ms) | Median (ms) | Sample standard deviation (ms) | Minimum (ms) | Maximum (ms) | Coefficient of variation |'
  Add-Line $builder '| --- | ---: | ---: | ---: | ---: | ---: | ---: |'
  foreach ($aggregate in $Evidence.aggregates) {
    Add-Line $builder ('| ' + $aggregate.name + ' | ' + (Format-Number $aggregate.values.mean_ms) + ' | ' + (Format-Number $aggregate.values.median_ms) + ' | ' + (Format-Number $aggregate.values.sample_standard_deviation_ms) + ' | ' + (Format-Number $aggregate.values.minimum_ms) + ' | ' + (Format-Number $aggregate.values.maximum_ms) + ' | ' + (Format-Number $aggregate.values.coefficient_of_variation) + ' |')
  }
  Add-Line $builder ''
  Add-Line $builder '## Read-only audit'
  Add-Line $builder ''
  Add-Line $builder 'Run `powershell.exe -NoProfile -File scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1 -Audit` or `pwsh -NoProfile -File scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1 -Audit` from a clean checkout. Audit reads this Markdown and current fixed inputs only; it does not run MoonBit, write Markdown, or make a timing decision.'
  Add-Line $builder ''
  $auditEvidence = [ordered]@{}
  foreach ($key in $Evidence.Keys) {
    if ($key -ne 'runs') { $auditEvidence[$key] = $Evidence[$key] }
  }
  $auditEvidence.runs = @($Evidence.runs | ForEach-Object {
    [ordered]@{ id = $_.id; label = $_.label; started_utc = $_.started_utc; ended_utc = $_.ended_utc; exit_code = $_.exit_code; output_sha256 = $_.output_sha256; summaries = $_.summaries }
  })
  Add-Line $builder '<!-- SVG-BASELINE-DATA'
  Add-Line $builder (Convert-ToAsciiJson $auditEvidence)
  Add-Line $builder '-->'
  $builder.ToString()
}

function Get-AuditData([string]$Document) {
  $match = [regex]::Match($Document, '(?s)<!-- SVG-BASELINE-DATA\r?\n(?<json>.*?)\r?\n-->')
  if (!$match.Success) { throw 'Baseline audit data block is missing or malformed.' }
  $match.Groups['json'].Value | ConvertFrom-Json
}

function Get-VisibleRunSections([string]$Document) {
  $matches = [regex]::Matches($Document, '(?m)^### (?<title>Warmup \(excluded from summary\)|Capture [1-7])\r?$')
  if ($matches.Count -ne 8) { throw 'Baseline requires exactly one ordered visible section for the warmup and each of seven captures.' }
  $summaryIndex = $Document.IndexOf('## Native-host-specific seven-capture summary', [StringComparison]::Ordinal)
  if ($summaryIndex -lt 0) { throw 'Visible aggregate section is missing.' }
  $sections = @()
  for ($index = 0; $index -lt $matches.Count; $index++) {
    $expectedTitle = if ($index -eq 0) { 'Warmup (excluded from summary)' } else { 'Capture ' + $index }
    if ($matches[$index].Groups['title'].Value -cne $expectedTitle) { throw "Visible capture section order mismatch at $index." }
    $bodyStart = $matches[$index].Index + $matches[$index].Length
    $bodyEnd = if ($index -lt ($matches.Count - 1)) { $matches[$index + 1].Index } else { $summaryIndex }
    if ($bodyEnd -le $bodyStart) { throw "Visible capture section is malformed for $expectedTitle." }
    $sections += [PSCustomObject]@{ title = $expectedTitle; body = $Document.Substring($bodyStart, $bodyEnd - $bodyStart) }
  }
  $sections
}

function Get-DocumentOutput([string]$Section, [string]$Id) {
  $matches = [regex]::Matches($Section, '(?s)<summary>Complete normalized UTF-8 merged stdout/stderr</summary>\s*<pre class="svg-native-output">\r?\n(?<output>.*?)\r?\n</pre>')
  if ($matches.Count -ne 1) { throw "Complete raw output block missing or duplicated for $Id." }
  Normalize-Text ([Net.WebUtility]::HtmlDecode($matches[0].Groups['output'].Value))
}

function New-RenderedEvidence([object]$Data, [object[]]$Sections) {
  if ($Sections.Count -ne $Data.runs.Count) { throw 'Visible capture section count does not match audit data.' }
  $evidence = [ordered]@{}
  foreach ($property in $Data.PSObject.Properties) {
    if ($property.Name -ne 'runs') { $evidence[$property.Name] = $property.Value }
  }
  $runs = @()
  for ($index = 0; $index -lt $Data.runs.Count; $index++) {
    $renderedRun = [ordered]@{}
    foreach ($property in $Data.runs[$index].PSObject.Properties) { $renderedRun[$property.Name] = $property.Value }
    $renderedRun.output = Get-DocumentOutput $Sections[$index].body "$($Data.runs[$index].id)"
    $runs += $renderedRun
  }
  $evidence.runs = $runs
  $evidence
}

function Assert-RecordedToolchainMatchesPolicy([object]$Toolchain) {
  $policy = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'policy\foundation.json') | ConvertFrom-Json
  foreach ($key in @('moon', 'moonc', 'moonrun')) {
    $expected = if ($key -eq 'moonc') {
      $policy.toolchain.$key.version + ' (' + $policy.toolchain.$key.release_date + ')'
    } else {
      $policy.toolchain.$key.version + ' (' + $policy.toolchain.$key.commit + ' ' + $policy.toolchain.$key.release_date + ')'
    }
    if ($Toolchain.policy_expected.$key -cne $expected) { throw "Recorded toolchain policy text mismatch for $key." }
    foreach ($field in @('version', 'commit', 'release_date')) {
      $property = $policy.toolchain.$key.PSObject.Properties[$field]
      if ($null -ne $property -and $Toolchain.raw.$key -notlike "*$($property.Value)*") { throw "Recorded toolchain pin mismatch for $key $field." }
    }
  }
}

function Assert-VisibleDocumentMatchesData([string]$Document, [object]$RenderedEvidence) {
  $expected = New-BaselineDocument $RenderedEvidence
  if ($Document -cne $expected) {
    throw 'Visible Markdown or embedded audit data differs from the canonical rendering of verified evidence.'
  }
}

function Assert-SummariesEqual([object[]]$Expected, [object[]]$Actual, [string]$Label) {
  if ($Expected.Count -ne $workloadNames.Count -or $Actual.Count -ne $workloadNames.Count) { throw "Summary count mismatch for $Label." }
  for ($i = 0; $i -lt $workloadNames.Count; $i++) {
    foreach ($key in @('name', 'mean_ms', 'sigma_ms', 'min_ms', 'max_ms', 'batch_size', 'runs')) {
      if ("$($Expected[$i].$key)" -cne "$($Actual[$i].$key)") { throw "Runner summary mismatch for $Label workload $i field $key." }
    }
  }
}

function Assert-VisibleAggregate([string]$Document, [string]$Name, [object]$Aggregate) {
  $summaryMarker = '## Native-host-specific seven-capture summary'
  $summaryIndex = $Document.IndexOf($summaryMarker, [StringComparison]::Ordinal)
  if ($summaryIndex -lt 0) { throw 'Visible aggregate section is missing.' }
  $summarySection = $Document.Substring($summaryIndex + $summaryMarker.Length)
  $line = [regex]::Match($summarySection, '(?m)^\| ' + [regex]::Escape($Name) + ' \| (?<mean>[0-9.]+) \| (?<median>[0-9.]+) \| (?<std>[0-9.]+) \| (?<min>[0-9.]+) \| (?<max>[0-9.]+) \| (?<cv>[0-9.]+) \|$')
  if (!$line.Success) { throw "Visible aggregate row missing for $Name." }
  $expected = @((Format-Number $Aggregate.mean_ms), (Format-Number $Aggregate.median_ms), (Format-Number $Aggregate.sample_standard_deviation_ms), (Format-Number $Aggregate.minimum_ms), (Format-Number $Aggregate.maximum_ms), (Format-Number $Aggregate.coefficient_of_variation))
  $actual = @($line.Groups['mean'].Value, $line.Groups['median'].Value, $line.Groups['std'].Value, $line.Groups['min'].Value, $line.Groups['max'].Value, $line.Groups['cv'].Value)
  for ($i = 0; $i -lt $expected.Count; $i++) { if ($expected[$i] -cne $actual[$i]) { throw "Visible aggregate mismatch for $Name." } }
}

function Invoke-ReadOnlyAudit {
  Assert-CleanWorktree
  if (!(Test-Path -LiteralPath $baselinePath -PathType Leaf)) { throw "Baseline missing: $baselinePath" }
  # Get-Content in Windows PowerShell 5.1 assumes the active ANSI code page for
  # UTF-8 files without a BOM; read the evidence bytes with the declared encoder.
  $document = $utf8.GetString([IO.File]::ReadAllBytes($baselinePath))
  $data = Get-AuditData $document
  $sections = @(Get-VisibleRunSections $document)
  $renderedEvidence = New-RenderedEvidence $data $sections
  if ($data.schema_version -ne 1 -or $data.identity.worktree -cne '(clean)' -or $data.execution.command -cne $nativeCommand -or $data.execution.target -cne 'native' -or $data.execution.release -ne $true -or $data.execution.frozen -ne $true) { throw 'Baseline fixed comparison identity mismatch.' }
  Assert-RecordedToolchainMatchesPolicy $data.toolchain
  if ($data.runs.Count -ne 8 -or $data.runs[0].id -cne 'warmup') { throw 'Baseline requires one warmup and seven captures.' }
  $sourceA = Get-Sha256File (Join-Path $repoRoot 'modules\mb-svg\svg\svg_bench.mbt')
  $sourceB = Get-Sha256File (Join-Path $repoRoot 'modules\mb-svg\svg\moon.pkg')
  $combined = Get-Sha256Text ('v1|svg_bench.mbt=' + $sourceA + '|moon.pkg=' + $sourceB)
  if ($data.source.svg_bench_sha256 -cne $sourceA -or $data.source.moon_pkg_sha256 -cne $sourceB -or $data.source.combined_sha256 -cne $combined) { throw 'Current benchmark source digest mismatch.' }
  $workloads = @(New-WorkloadRecords)
  if ($data.workloads.Count -ne $workloadNames.Count) { throw 'Workload provenance count mismatch.' }
  for ($i = 0; $i -lt $workloadNames.Count; $i++) {
    if ($data.workloads[$i].name -cne $workloads[$i].name -or $data.workloads[$i].corpus_sha256 -cne $workloads[$i].corpus_sha256 -or $data.workloads[$i].correctness_sha256 -cne $workloads[$i].correctness_sha256) { throw "Workload provenance mismatch at $i." }
  }
  $samplesByWorkload = @{}
  foreach ($name in $workloadNames) { $samplesByWorkload[$name] = @() }
  for ($runIndex = 0; $runIndex -lt 8; $runIndex++) {
    $run = $data.runs[$runIndex]
    $expectedId = if ($runIndex -eq 0) { 'warmup' } else { "$runIndex" }
    if ("$($run.id)" -cne $expectedId -or [int]$run.exit_code -ne 0) { throw "Run identity or exit status mismatch at $runIndex." }
    $output = $renderedEvidence.runs[$runIndex].output
    if ($run.output_sha256 -cne (Get-Sha256Text $output)) { throw "Output digest mismatch for $($run.id)." }
    $parsed = @(Convert-BenchmarkOutput $output)
    Assert-SummariesEqual @($run.summaries) $parsed "run $($run.id)"
    if ($runIndex -gt 0) {
      for ($i = 0; $i -lt $workloadNames.Count; $i++) { $samplesByWorkload[$workloadNames[$i]] += [double]$parsed[$i].mean_ms }
    }
  }
  if ($data.aggregates.Count -ne $workloadNames.Count) { throw 'Aggregate count mismatch.' }
  for ($i = 0; $i -lt $workloadNames.Count; $i++) {
    $actual = Get-Aggregate ([double[]]$samplesByWorkload[$workloadNames[$i]])
    if ($data.aggregates[$i].name -cne $workloadNames[$i]) { throw "Aggregate workload order mismatch at $i." }
    foreach ($key in @('mean_ms', 'median_ms', 'sample_standard_deviation_ms', 'minimum_ms', 'maximum_ms', 'coefficient_of_variation')) {
      if ("$($data.aggregates[$i].values.$key)" -cne "$($actual.$key)") { throw "Stored aggregate mismatch for $($workloadNames[$i]) $key." }
    }
    Assert-VisibleAggregate $document $workloadNames[$i] $actual
  }
  Assert-VisibleDocumentMatchesData $document $renderedEvidence
  Write-Host 'SVG native baseline audit passed: clean worktree, complete rendered identity/provenance/toolchain/host/run evidence, eight output digests, ordered runner summaries, and seven-sample aggregates verified.'
}

$previousLocation = Get-Location
try {
  Set-Location -LiteralPath $repoRoot
  if ($Audit) {
    Invoke-ReadOnlyAudit
    exit 0
  }
  Assert-CleanWorktree
  $toolchain = Get-PolicyAndToolchain
  $sourceA = Get-Sha256File (Join-Path $repoRoot 'modules\mb-svg\svg\svg_bench.mbt')
  $sourceB = Get-Sha256File (Join-Path $repoRoot 'modules\mb-svg\svg\moon.pkg')
  $workloads = @(New-WorkloadRecords | ForEach-Object { [ordered]@{ name = $_.name; corpus_sha256 = $_.corpus_sha256; correctness_sha256 = $_.correctness_sha256 } })
  Write-Host 'Running one native release warmup (excluded from summary)...'
  $runs = @((Invoke-NativeCapture 'warmup' 'warmup'))
  for ($capture = 1; $capture -le 7; $capture++) {
    Write-Host "Recording native release capture $capture of 7..."
    $runs += Invoke-NativeCapture "$capture" "capture $capture"
  }
  $aggregates = @()
  for ($workloadIndex = 0; $workloadIndex -lt $workloadNames.Count; $workloadIndex++) {
    [double[]]$samples = @($runs | Select-Object -Skip 1 | ForEach-Object { [double]$_.summaries[$workloadIndex].mean_ms })
    $aggregates += [ordered]@{ name = $workloadNames[$workloadIndex]; values = Get-Aggregate $samples }
  }
  $evidence = [ordered]@{
    schema_version = 1
    claim = 'native-host observation only; no threshold, ranking, regression conclusion, CI gate, cross-target comparison, or performance claim'
    identity = [ordered]@{ git_commit = (& git rev-parse HEAD).Trim(); worktree = '(clean)' }
    execution = [ordered]@{ command = $nativeCommand; working_directory = '.'; target = 'native'; release = $true; frozen = $true; output_encoding = 'normalized UTF-8 without BOM' }
    source = [ordered]@{ svg_bench_sha256 = $sourceA; moon_pkg_sha256 = $sourceB; combined_sha256 = Get-Sha256Text ('v1|svg_bench.mbt=' + $sourceA + '|moon.pkg=' + $sourceB) }
    workloads = $workloads
    toolchain = $toolchain
    host = Get-HostFacts
    runs = $runs
    aggregates = $aggregates
  }
  $document = New-BaselineDocument $evidence
  $baselineDirectory = Split-Path -Parent $baselinePath
  if (!(Test-Path -LiteralPath $baselineDirectory -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $baselineDirectory -Force
  }
  [IO.File]::WriteAllText($baselinePath, $document, $utf8)
  Write-Host "SVG native baseline captured: $baselinePath"
} finally {
  Set-Location -LiteralPath $previousLocation
}
