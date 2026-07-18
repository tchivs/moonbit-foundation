[CmdletBinding(DefaultParameterSetName = 'Live')]
param(
    [Parameter(Mandatory)][ValidateSet('mb-core', 'mb-color', 'mb-image')][string]$Module,
    [Parameter(Mandatory)][string]$OutputPath,
    [Parameter(Mandatory, ParameterSetName = 'Live')][string]$ToolchainRoot,
    [Parameter(Mandatory, ParameterSetName = 'Live')][string]$ObservationFixturePath,
    [Parameter(ParameterSetName = 'Live')][string]$NativeToolchainBin,
    [Parameter(Mandatory, ParameterSetName = 'Fixture')][string]$FixturePath,
    [string]$PolicyPath,
    [string]$SchemaPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if ([string]::IsNullOrWhiteSpace($PolicyPath)) { $PolicyPath = Join-Path $repoRoot 'policy\phase-08-distribution.json' }
if ([string]::IsNullOrWhiteSpace($SchemaPath)) { $SchemaPath = Join-Path $repoRoot 'release\consumers\proof-schema.json' }
$observerPath = Join-Path $PSScriptRoot 'Get-MooncakesObservation.ps1'
$observationSchemaPath = Join-Path $repoRoot 'release\registry\module-observation-schema.json'
$templateRoot = Join-Path $repoRoot 'qualification\registry-consumers'

function Get-TextSha256 {
    param([Parameter(Mandatory)][string]$Text)
    return ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($Text)))).ToLowerInvariant()
}

function Get-FileSha256 {
    param([Parameter(Mandatory)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-ExactProperties {
    param([object]$Value, [string[]]$Expected)
    if ($null -eq $Value) { return $false }
    $actual = @($Value.PSObject.Properties.Name)
    return $actual.Count -eq $Expected.Count -and (($actual -join '|') -ceq ($Expected -join '|'))
}

function Test-ExactGraph {
    param([Parameter(Mandatory)]$Actual, [Parameter(Mandatory)]$Expected)
    if (-not (Test-ExactProperties $Actual @('nodes', 'edges'))) { return $false }
    $actualNodes = @($Actual.nodes | ForEach-Object { [string]$_.identity } | Sort-Object)
    $expectedNodes = @($Expected.nodes | ForEach-Object { [string]$_.identity } | Sort-Object)
    $actualEdges = @($Actual.edges | ForEach-Object { "$($_.from)->$($_.to)" } | Sort-Object)
    $expectedEdges = @($Expected.edges | ForEach-Object { "$($_.from)->$($_.to)" } | Sort-Object)
    return (($actualNodes -join '|') -ceq ($expectedNodes -join '|')) -and
        (($actualEdges -join '|') -ceq ($expectedEdges -join '|'))
}

function Get-ExpectedGraph {
    param([object]$Policy, [string]$ModuleName)
    $moduleIndex = [Array]::IndexOf(@($Policy.module_order), $ModuleName)
    if ($moduleIndex -lt 0) { throw "COLD01-MODULE: unknown module '$ModuleName'." }
    $nodes = @($Policy.graph.nodes | Select-Object -First ($moduleIndex + 1) | ForEach-Object {
        [pscustomobject][ordered]@{ identity = [string]$_.identity }
    })
    $nodeIds = @($nodes.identity)
    $edges = @($Policy.graph.edges | Where-Object { $nodeIds -ccontains $_.from -and $nodeIds -ccontains $_.to } | ForEach-Object {
        [pscustomobject][ordered]@{ from = [string]$_.from; to = [string]$_.to }
    })
    return [pscustomobject][ordered]@{ nodes = $nodes; edges = $edges }
}

function Assert-Isolation {
    param([Parameter(Mandatory)]$Isolation)
    $properties = @(
        'consumer_root_outside_checkout', 'moon_home_initially_empty', 'credentials_absent',
        'workspace_absent', 'source_copy_absent', 'alternate_dependency_source_absent',
        'local_dependency_absent', 'path_dependency_absent', 'git_dependency_absent',
        'registry_cache_initially_empty', 'registry_index_cache_absent', 'archive_cache_absent',
        'mooncakes_state_absent', 'target_output_initially_absent', 'pinned_toolchain_explicit',
        'ambient_toolchain_ignored'
    )
    if (-not (Test-ExactProperties $Isolation $properties)) { throw 'COLD02-ISOLATION-SHAPE: isolation facts are missing, reordered, or extended.' }
    foreach ($property in $properties) {
        if ($Isolation.$property -ne $true) { throw "COLD03-CONTAMINATION: isolation fact '$property' is not true." }
    }
}

function Assert-Targets {
    param([Parameter(Mandatory)][object[]]$Targets, [Parameter(Mandatory)][string[]]$ExpectedNames)
    if ($Targets.Count -ne $ExpectedNames.Count) { throw 'COLD04-TARGETS: exact four-target result set is required.' }
    for ($index = 0; $index -lt $ExpectedNames.Count; $index++) {
        $target = $Targets[$index]
        if (-not (Test-ExactProperties $target @('name', 'check', 'test', 'runtime', 'output_sha256'))) { throw 'COLD04-TARGETS: target result shape is not closed.' }
        if ([string]$target.name -cne $ExpectedNames[$index] -or [string]$target.check -cne 'pass' -or
            [string]$target.test -cne 'pass' -or [string]$target.runtime -cne 'pass' -or
            [string]$target.output_sha256 -cnotmatch '^[0-9a-f]{64}$') {
            throw "COLD04-TARGETS: target '$($ExpectedNames[$index])' lacks check, test, real runtime, or output evidence."
        }
    }
}

function Assert-ProofFacts {
    param([Parameter(Mandatory)]$Facts, [Parameter(Mandatory)]$Policy, [Parameter(Mandatory)]$ExpectedModule)
    $expectedFacts = @('schema_version', 'isolation', 'observation', 'archive_sha256', 'downloaded_manifest_sha256', 'resolved_graph', 'toolchain', 'targets', 'behavior')
    if (-not (Test-ExactProperties $Facts $expectedFacts) -or [string]$Facts.schema_version -cne '1.0.0') { throw 'COLD05-FACTS: proof facts are missing, reordered, or extended.' }
    Assert-Isolation $Facts.isolation
    if (-not (Test-ExactProperties $Facts.observation @('outcome', 'content_sha256', 'strongest_identity')) -or
        [string]$Facts.observation.outcome -cne 'exact' -or
        [string]$Facts.observation.content_sha256 -cnotmatch '^[0-9a-f]{64}$' -or
        [string]$Facts.observation.strongest_identity -cnotmatch '^sha256:[0-9a-f]{64}$') {
        throw 'COLD06-OBSERVATION: exact sanitized observation with strongest SHA-256 identity is required.'
    }
    foreach ($property in @('archive_sha256', 'downloaded_manifest_sha256')) {
        if ([string]$Facts.$property -cnotmatch '^[0-9a-f]{64}$') { throw "COLD07-ARTIFACT: $property is missing or invalid." }
    }
    if ([string]$Facts.observation.strongest_identity -cne "sha256:$($Facts.archive_sha256)") { throw 'COLD07-ARTIFACT: strongest registry identity disagrees with the downloaded archive.' }
    if ([string]$Facts.downloaded_manifest_sha256 -cne [string]$ExpectedModule.manifest_sha256) { throw 'COLD07-ARTIFACT: downloaded manifest digest disagrees with qualified source.' }
    $expectedGraph = Get-ExpectedGraph $Policy $Module
    if (-not (Test-ExactGraph $Facts.resolved_graph $expectedGraph)) { throw 'COLD08-GRAPH: resolved graph is not node-for-node and edge-for-edge exact.' }
    if (-not (Test-ExactProperties $Facts.toolchain @('moon_version', 'moonc_version', 'moonrun_version', 'root_sha256')) -or
        @($Facts.toolchain.moon_version, $Facts.toolchain.moonc_version, $Facts.toolchain.moonrun_version | Where-Object { [string]::IsNullOrWhiteSpace([string]$_) }).Count -ne 0 -or
        [string]$Facts.toolchain.root_sha256 -cnotmatch '^[0-9a-f]{64}$') {
        throw 'COLD09-TOOLCHAIN: pinned toolchain identity is incomplete.'
    }
    Assert-Targets @($Facts.targets) @($Policy.required_targets)
    if (-not (Test-ExactProperties $Facts.behavior @('result', 'output_sha256')) -or
        [string]$Facts.behavior.result -cne 'pass' -or [string]$Facts.behavior.output_sha256 -cnotmatch '^[0-9a-f]{64}$') {
        throw 'COLD10-BEHAVIOR: deterministic public behavior result is incomplete.'
    }
    foreach ($target in @($Facts.targets)) {
        if ([string]$target.output_sha256 -cne [string]$Facts.behavior.output_sha256) { throw 'COLD10-BEHAVIOR: target output digests disagree.' }
    }
}

function Write-Proof {
    param(
        [Parameter(Mandatory)]$Facts,
        [Parameter(Mandatory)]$Policy,
        [Parameter(Mandatory)]$ExpectedModule,
        [Parameter(Mandatory)][ValidateSet('fixture', 'live_registry')][string]$EvidenceMode
    )
    $projection = [ordered]@{
        schema_version = '1.0.0'
        evidence_mode = $EvidenceMode
        policy_sha256 = Get-FileSha256 $PolicyPath
        module = $Module
        identity = [string]$ExpectedModule.identity
        version = [string]$ExpectedModule.version
        dependency_source = 'registry_only'
        isolation = $Facts.isolation
        observation = $Facts.observation
        archive_sha256 = [string]$Facts.archive_sha256
        downloaded_manifest_sha256 = [string]$Facts.downloaded_manifest_sha256
        resolved_graph = Get-ExpectedGraph $Policy $Module
        toolchain = $Facts.toolchain
        targets = @($Facts.targets)
        behavior = $Facts.behavior
        verified = $true
    }
    $projection.content_sha256 = Get-TextSha256 (([pscustomobject]$projection | ConvertTo-Json -Depth 100 -Compress))
    $json = [pscustomobject]$projection | ConvertTo-Json -Depth 100
    if (-not ($json | Test-Json -SchemaFile $SchemaPath -ErrorAction Stop)) { throw 'COLD11-SCHEMA: verified proof does not satisfy the closed schema.' }
    $parent = Split-Path -Parent $OutputPath
    if ([string]::IsNullOrWhiteSpace($parent)) { $parent = (Get-Location).Path }
    $null = New-Item -ItemType Directory -Path $parent -Force
    $temporary = Join-Path $parent ('.cold-proof-{0}.tmp' -f [guid]::NewGuid().ToString('N'))
    try {
        [IO.File]::WriteAllText($temporary, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $temporary -Destination $OutputPath -Force
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    }
}

function Get-BehaviorContract {
    switch ($Module) {
        'mb-core' {
            return [pscustomobject]@{
                dependencies = [ordered]@{ 'tchivs/mb-core' = '0.1.0' }
                imports = @('tchivs/mb-core/error', 'tchivs/mb-core/checked', 'tchivs/mb-core/budget', 'tchivs/mb-core/bytes', 'tchivs/mb-core/io', 'tchivs/mb-core/host')
                output = 'consumer=mb-core sum=42 bytes=4 position=0 clock=42'
            }
        }
        'mb-color' {
            return [pscustomobject]@{
                dependencies = [ordered]@{ 'tchivs/mb-core' = '0.1.0'; 'tchivs/mb-color' = '0.1.0' }
                imports = @('tchivs/mb-core/checked', 'tchivs/mb-color/model', 'tchivs/mb-color/quantize')
                output = 'consumer=mb-color sum=128 encoded=128 alpha=128 roundtrip=128'
            }
        }
        default {
            return [pscustomobject]@{
                dependencies = [ordered]@{ 'tchivs/mb-core' = '0.1.0'; 'tchivs/mb-color' = '0.1.0'; 'tchivs/mb-image' = '0.1.0' }
                imports = @('tchivs/mb-core/budget', 'tchivs/mb-core/bytes', 'tchivs/mb-core/error', 'tchivs/mb-core/io', 'tchivs/mb-color/model', 'tchivs/mb-image/codec', 'tchivs/mb-image/ppm')
                output = 'consumer=mb-image bytes_read=17 bytes_written=17 width=2 height=1 digest=237717273'
            }
        }
    }
}

function Write-Utf8Text {
    param([string]$Path, [string]$Text)
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Invoke-ColdProcess {
    param([string]$FilePath, [string[]]$Arguments, [string]$WorkingDirectory, [hashtable]$Environment)
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $FilePath
    $start.WorkingDirectory = $WorkingDirectory
    $start.UseShellExecute = $false
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.Environment.Clear()
    foreach ($entry in $Environment.GetEnumerator()) { $start.Environment[$entry.Key] = [string]$entry.Value }
    foreach ($argument in $Arguments) { $null = $start.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    $null = $process.Start()
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    return [pscustomobject]@{ exit_code = $process.ExitCode; stdout = $stdout; stderr = $stderr }
}

function Assert-ProcessPassed {
    param([string]$Label, $Result)
    if ($Result.exit_code -ne 0) { throw "COLD12-COMMAND: $Label failed ($($Result.exit_code)): $($Result.stderr.Trim())" }
}

function ConvertFrom-MoonTree {
    param([string]$Text)
    $lines = @($Text -split '\r?\n' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($lines.Count -eq 0 -or $lines[0] -cnotmatch '^(?<root>[a-z0-9_-]+/[a-z0-9_-]+@[0-9]+[.][0-9]+[.][0-9]+)') { throw 'COLD13-TREE: moon tree root is missing or unparseable.' }
    $nodes = [Collections.Generic.List[object]]::new()
    $edges = [Collections.Generic.List[object]]::new()
    $seenNodes = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $stack = @([string]$Matches.root)
    $null = $seenNodes.Add([string]$Matches.root)
    $nodes.Add([pscustomobject][ordered]@{ identity = [string]$Matches.root })
    foreach ($line in $lines | Select-Object -Skip 1) {
        if ($line -notmatch '^(?<prefix>(?:│  |   )*)(?:├─ |└─ )(?<name>[a-z0-9_-]+/[a-z0-9_-]+) -> (?<resolved>[a-z0-9_-]+/[a-z0-9_-]+@[0-9]+[.][0-9]+[.][0-9]+)') { throw "COLD13-TREE: unparseable dependency line '$line'." }
        $level = ([string]$Matches.prefix).Length / 3 + 1
        if ($level -gt $stack.Count) { throw 'COLD13-TREE: dependency indentation skipped a parent level.' }
        $parent = [string]$stack[$level - 1]
        $resolved = [string]$Matches.resolved
        $edges.Add([pscustomobject][ordered]@{ from = $parent; to = $resolved })
        if ($seenNodes.Add($resolved)) { $nodes.Add([pscustomobject][ordered]@{ identity = $resolved }) }
        if ($stack.Count -gt $level) { $stack[$level] = $resolved; $stack = @($stack | Select-Object -First ($level + 1)) } else { $stack += $resolved }
    }
    $canonicalNodes = @($nodes | Where-Object { [string]$_.identity -cmatch '^tchivs/mb-(?:core|color|image)@[0-9]+[.][0-9]+[.][0-9]+$' } | Sort-Object { $_.identity })
    $canonicalIds = @($canonicalNodes.identity)
    $canonicalEdges = @($edges | Where-Object { $canonicalIds -ccontains $_.from -and $canonicalIds -ccontains $_.to } | Sort-Object { "$($_.from)->$($_.to)" } -Unique)
    return [pscustomobject][ordered]@{ nodes = $canonicalNodes; edges = $canonicalEdges }
}

function Remove-ColdRoot {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $full = [IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($temp + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Split-Path -Leaf $full).StartsWith('mnf-cold-registry-', [StringComparison]::Ordinal)) {
        throw "Refusing to remove unverified cold consumer root: $full"
    }
    Remove-Item -LiteralPath $full -Recurse -Force
}

$policy = Get-Content -Raw -LiteralPath $PolicyPath | ConvertFrom-Json -Depth 100
$expectedModules = @($policy.modules | Where-Object { [string]$_.module -ceq $Module })
if ($expectedModules.Count -ne 1) { throw 'COLD01-MODULE: policy module is missing or duplicated.' }
$expectedModule = $expectedModules[0]

if ($PSCmdlet.ParameterSetName -ceq 'Fixture') {
    $facts = Get-Content -Raw -LiteralPath $FixturePath | ConvertFrom-Json -Depth 100
    Assert-ProofFacts $facts $policy $expectedModule
    Write-Proof $facts $policy $expectedModule -EvidenceMode fixture
    Write-Host "Cold registry consumer fixture proof: PASS ($Module)."
    exit 0
}

$coldRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-cold-registry-' + [guid]::NewGuid().ToString('N'))
$repoFull = [IO.Path]::GetFullPath($repoRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
if ([IO.Path]::GetFullPath($coldRoot).StartsWith($repoFull + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'COLD03-CONTAMINATION: disposable root is inside the checkout.' }
$null = New-Item -ItemType Directory -Path $coldRoot
try {
    if (@(Get-ChildItem -LiteralPath $coldRoot -Force).Count -ne 0) { throw 'COLD03-CONTAMINATION: disposable root was not newly empty.' }
    $moonHome = Join-Path $coldRoot 'moon-home'
    $consumerRoot = Join-Path $coldRoot 'consumer'
    $targetRoot = Join-Path $coldRoot 'target'
    $observationPath = Join-Path $coldRoot 'observation.json'
    $null = New-Item -ItemType Directory -Path $moonHome
    if (@(Get-ChildItem -LiteralPath $moonHome -Force).Count -ne 0) { throw 'COLD03-CONTAMINATION: new MOON_HOME was not empty.' }
    foreach ($forbidden in @('credentials.json', 'moon.work', '.mooncakes', 'target', '_build')) {
        if (Test-Path -LiteralPath (Join-Path $coldRoot $forbidden)) { throw "COLD03-CONTAMINATION: '$forbidden' existed before resolution." }
    }

    $contract = Get-BehaviorContract
    $manifest = [ordered]@{
        name = "mnf-registry-consumer/$Module"
        version = '0.0.0'
        license = 'Apache-2.0'
        'preferred-target' = 'native'
        'supported-targets' = '+js+wasm+wasm-gc+native'
        deps = $contract.dependencies
    }
    Write-Utf8Text (Join-Path $consumerRoot 'moon.mod.json') (($manifest | ConvertTo-Json -Depth 20) + [Environment]::NewLine)
    $packageLines = @('import {') + @($contract.imports | ForEach-Object { '  "' + $_ + '",' }) + @('}', '', 'supported_targets = "+js+wasm+wasm-gc+native"', '', 'pkgtype(kind: "executable")', '')
    Write-Utf8Text (Join-Path $consumerRoot 'main\moon.pkg') ($packageLines -join [Environment]::NewLine)
    Copy-Item -LiteralPath (Join-Path $templateRoot "$Module\main\main.mbt") -Destination (Join-Path $consumerRoot 'main\main.mbt')
    $manifestRaw = Get-Content -Raw -LiteralPath (Join-Path $consumerRoot 'moon.mod.json')
    if ($manifestRaw -cmatch '(?i)"(?:path|git|workspace|local)"\s*:|(?:^|[\\/])[.][.](?:[\\/]|$)') { throw 'COLD03-CONTAMINATION: generated manifest contains an alternate dependency source.' }

    $toolchainFull = [IO.Path]::GetFullPath($ToolchainRoot)
    $moonExe = Join-Path $toolchainFull 'bin\moon.exe'
    $mooncExe = Join-Path $toolchainFull 'bin\moonc.exe'
    $moonrunExe = Join-Path $toolchainFull 'bin\moonrun.exe'
    foreach ($tool in @($moonExe, $mooncExe, $moonrunExe)) { if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) { throw "COLD09-TOOLCHAIN: pinned executable missing: $tool" } }
    $pathParts = @((Join-Path $toolchainFull 'bin'))
    if (-not [string]::IsNullOrWhiteSpace($NativeToolchainBin)) {
        $nativeBin = [IO.Path]::GetFullPath($NativeToolchainBin)
        if (-not (Test-Path -LiteralPath (Join-Path $nativeBin 'clang.exe') -PathType Leaf)) { throw 'COLD09-TOOLCHAIN: explicit native compiler bin lacks clang.exe.' }
        $pathParts += $nativeBin
    }
    $environment = @{
        MOON_HOME = $moonHome
        MOON_TOOLCHAIN_ROOT = $toolchainFull
        PATH = ($pathParts -join [IO.Path]::PathSeparator)
        TEMP = [IO.Path]::GetTempPath()
        TMP = [IO.Path]::GetTempPath()
    }
    foreach ($name in @('SystemRoot', 'WINDIR', 'COMSPEC', 'PATHEXT')) { if (-not [string]::IsNullOrWhiteSpace([string][Environment]::GetEnvironmentVariable($name))) { $environment[$name] = [Environment]::GetEnvironmentVariable($name) } }

    $treeResult = Invoke-ColdProcess $moonExe @('-C', $consumerRoot, 'tree', '--target-dir', $targetRoot) $consumerRoot $environment
    Assert-ProcessPassed 'registry resolution and moon tree' $treeResult
    $resolvedGraph = ConvertFrom-MoonTree $treeResult.stdout
    $expectedGraph = Get-ExpectedGraph $policy $Module
    if (-not (Test-ExactGraph $resolvedGraph $expectedGraph)) { throw 'COLD08-GRAPH: resolved moon tree is not exact.' }

    & $observerPath -FixturePath $ObservationFixturePath -OutputPath $observationPath -Module $Module -PolicyPath $PolicyPath -SchemaPath $observationSchemaPath
    $observation = Get-Content -Raw -LiteralPath $observationPath | ConvertFrom-Json -Depth 100
    if ([string]$observation.outcome -cne 'exact' -or $null -eq $observation.observed -or
        -not (Test-ExactGraph $observation.observed.graph $expectedGraph)) { throw 'COLD06-OBSERVATION: registry observer did not produce exact graph-bound evidence.' }
    if ([string]$observation.observed.archive_sha256 -cnotmatch '^[0-9a-f]{64}$' -or
        [string]$observation.observed.manifest_sha256 -cne [string]$expectedModule.manifest_sha256) { throw 'COLD07-ARTIFACT: observed archive or manifest identity is incomplete.' }

    $moonVersion = Invoke-ColdProcess $moonExe @('version') $consumerRoot $environment
    $mooncVersion = Invoke-ColdProcess $mooncExe @('-v') $consumerRoot $environment
    $moonrunVersion = Invoke-ColdProcess $moonrunExe @('--version') $consumerRoot $environment
    foreach ($result in @($moonVersion, $mooncVersion, $moonrunVersion)) { Assert-ProcessPassed 'toolchain identity' $result }
    $toolchainDigest = Get-TextSha256 ((@($moonExe, $mooncExe, $moonrunExe) | ForEach-Object { Get-FileSha256 $_ }) -join '|')
    $behaviorDigest = Get-TextSha256 $contract.output
    $targetResults = [Collections.Generic.List[object]]::new()
    foreach ($target in @($policy.required_targets)) {
        $check = Invoke-ColdProcess $moonExe @('-C', $consumerRoot, 'check', 'main', '--target', [string]$target, '--deny-warn', '--frozen', '--target-dir', $targetRoot) $consumerRoot $environment
        Assert-ProcessPassed "$target check" $check
        $test = Invoke-ColdProcess $moonExe @('-C', $consumerRoot, 'test', 'main', '--target', [string]$target, '--frozen', '--target-dir', $targetRoot) $consumerRoot $environment
        Assert-ProcessPassed "$target test" $test
        $run = Invoke-ColdProcess $moonExe @('-C', $consumerRoot, 'run', 'main', '--target', [string]$target, '--frozen', '--target-dir', $targetRoot) $consumerRoot $environment
        Assert-ProcessPassed "$target runtime" $run
        $semantic = @($run.stdout -split '\r?\n' | Where-Object { $_ -ne '' -and $_ -notmatch '^(Finished|Warning:)' })
        if ($semantic.Count -ne 1 -or $semantic[0] -cne $contract.output) { throw "COLD10-BEHAVIOR: $target output drifted: '$($semantic -join ' | ')'" }
        $targetResults.Add([pscustomobject][ordered]@{ name = [string]$target; check = 'pass'; test = 'pass'; runtime = 'pass'; output_sha256 = $behaviorDigest })
    }
    $facts = [pscustomobject][ordered]@{
        schema_version = '1.0.0'
        isolation = [pscustomobject][ordered]@{
            consumer_root_outside_checkout = $true; moon_home_initially_empty = $true; credentials_absent = $true
            workspace_absent = $true; source_copy_absent = $true; alternate_dependency_source_absent = $true
            local_dependency_absent = $true; path_dependency_absent = $true; git_dependency_absent = $true
            registry_cache_initially_empty = $true; registry_index_cache_absent = $true; archive_cache_absent = $true
            mooncakes_state_absent = $true; target_output_initially_absent = $true; pinned_toolchain_explicit = $true
            ambient_toolchain_ignored = $true
        }
        observation = [pscustomobject][ordered]@{ outcome = 'exact'; content_sha256 = [string]$observation.content_sha256; strongest_identity = "sha256:$($observation.observed.archive_sha256)" }
        archive_sha256 = [string]$observation.observed.archive_sha256
        downloaded_manifest_sha256 = [string]$observation.observed.manifest_sha256
        resolved_graph = $resolvedGraph
        toolchain = [pscustomobject][ordered]@{
            moon_version = $moonVersion.stdout.Trim(); moonc_version = $mooncVersion.stdout.Trim(); moonrun_version = $moonrunVersion.stdout.Trim(); root_sha256 = $toolchainDigest
        }
        targets = @($targetResults)
        behavior = [pscustomobject][ordered]@{ result = 'pass'; output_sha256 = $behaviorDigest }
    }
    Assert-ProofFacts $facts $policy $expectedModule
    Write-Proof $facts $policy $expectedModule -EvidenceMode live_registry
    Write-Host "Cold registry consumer proof: PASS ($Module, exact registry graph, four runtime targets)."
}
finally {
    Remove-ColdRoot $coldRoot
}
