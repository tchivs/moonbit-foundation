[CmdletBinding()]
param(
    [switch]$IsolationOnly,
    [switch]$BehaviorOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$policyPath = Join-Path $repoRoot 'policy\phase-08-distribution.json'
$schemaPath = Join-Path $repoRoot 'release\consumers\proof-schema.json'
$runnerPath = Join-Path $repoRoot 'scripts\quality\Invoke-ColdRegistryConsumer.ps1'
$templateRoot = Join-Path $repoRoot 'qualification\registry-consumers'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERTION FAILED: $Message" }
}

function Assert-Equal {
    param($Actual, $Expected, [string]$Message)
    if ($Actual -cne $Expected) {
        throw "ASSERTION FAILED: $Message`nExpected: $Expected`nActual:   $Actual"
    }
}

function Assert-Sequence {
    param([object[]]$Actual, [object[]]$Expected, [string]$Message)
    Assert-Equal (($Actual | ForEach-Object { [string]$_ }) -join '|') (($Expected | ForEach-Object { [string]$_ }) -join '|') $Message
}

function Copy-JsonObject {
    param([Parameter(Mandatory)]$Value)
    return $Value | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100
}

function Test-ExactGraph {
    param([Parameter(Mandatory)]$Actual, [Parameter(Mandatory)]$Expected)
    $actualNodes = @($Actual.nodes | ForEach-Object { [string]$_.identity } | Sort-Object)
    $expectedNodes = @($Expected.nodes | ForEach-Object { [string]$_.identity } | Sort-Object)
    $actualEdges = @($Actual.edges | ForEach-Object { "$($_.from)->$($_.to)" } | Sort-Object)
    $expectedEdges = @($Expected.edges | ForEach-Object { "$($_.from)->$($_.to)" } | Sort-Object)
    return (($actualNodes -join '|') -ceq ($expectedNodes -join '|')) -and
        (($actualEdges -join '|') -ceq ($expectedEdges -join '|'))
}

function Test-ColdIsolation {
    param([Parameter(Mandatory)]$State)
    return $State.consumer_root_outside_checkout -eq $true -and
        $State.moon_home_initially_empty -eq $true -and
        $State.credentials_absent -eq $true -and
        $State.workspace_absent -eq $true -and
        $State.source_copy_absent -eq $true -and
        $State.alternate_dependency_source_absent -eq $true -and
        $State.local_dependency_absent -eq $true -and
        $State.path_dependency_absent -eq $true -and
        $State.git_dependency_absent -eq $true -and
        $State.registry_cache_initially_empty -eq $true -and
        $State.registry_index_cache_absent -eq $true -and
        $State.archive_cache_absent -eq $true -and
        $State.mooncakes_state_absent -eq $true -and
        $State.target_output_initially_absent -eq $true -and
        $State.pinned_toolchain_explicit -eq $true -and
        $State.ambient_toolchain_ignored -eq $true
}

Assert-True (Test-Path -LiteralPath $policyPath -PathType Leaf) 'distribution policy must exist'
Assert-True (Test-Path -LiteralPath $schemaPath -PathType Leaf) 'cold proof schema must exist'

$policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json -Depth 100
$schema = Get-Content -Raw -LiteralPath $schemaPath | ConvertFrom-Json -Depth 100

Assert-Equal $schema.'$schema' 'https://json-schema.org/draft/2020-12/schema' 'proof schema dialect'
Assert-Equal $schema.additionalProperties $false 'proof schema must be closed'
Assert-Equal $schema.properties.dependency_source.const 'registry_only' 'dependency source must be registry-only'
Assert-Equal $schema.properties.verified.const $true 'schema represents verified proofs only'
Assert-Sequence $schema.required @(
    'schema_version', 'evidence_mode', 'policy_sha256', 'module', 'identity', 'version', 'dependency_source',
    'isolation', 'observation', 'archive_sha256', 'downloaded_manifest_sha256',
    'resolved_graph', 'toolchain', 'targets', 'behavior', 'verified', 'content_sha256'
) 'closed proof required facts'

$cleanIsolation = [pscustomobject][ordered]@{
    consumer_root_outside_checkout = $true
    moon_home_initially_empty = $true
    credentials_absent = $true
    workspace_absent = $true
    source_copy_absent = $true
    alternate_dependency_source_absent = $true
    local_dependency_absent = $true
    path_dependency_absent = $true
    git_dependency_absent = $true
    registry_cache_initially_empty = $true
    registry_index_cache_absent = $true
    archive_cache_absent = $true
    mooncakes_state_absent = $true
    target_output_initially_absent = $true
    pinned_toolchain_explicit = $true
    ambient_toolchain_ignored = $true
}
Assert-True (Test-ColdIsolation $cleanIsolation) 'clean isolation fixture must pass'

$contaminationFixtures = @(
    @{ name = 'in-checkout root'; property = 'consumer_root_outside_checkout' },
    @{ name = 'nonempty Moon home'; property = 'moon_home_initially_empty' },
    @{ name = 'credential material'; property = 'credentials_absent' },
    @{ name = 'moon.work discovery'; property = 'workspace_absent' },
    @{ name = 'copied module source'; property = 'source_copy_absent' },
    @{ name = 'alternate dependency source'; property = 'alternate_dependency_source_absent' },
    @{ name = 'local dependency'; property = 'local_dependency_absent' },
    @{ name = 'path dependency'; property = 'path_dependency_absent' },
    @{ name = 'Git dependency'; property = 'git_dependency_absent' },
    @{ name = 'registry cache'; property = 'registry_cache_initially_empty' },
    @{ name = 'registry index cache'; property = 'registry_index_cache_absent' },
    @{ name = 'archive cache'; property = 'archive_cache_absent' },
    @{ name = '.mooncakes state'; property = 'mooncakes_state_absent' },
    @{ name = 'target output'; property = 'target_output_initially_absent' },
    @{ name = 'ambient toolchain'; property = 'pinned_toolchain_explicit' },
    @{ name = 'ambient toolchain inheritance'; property = 'ambient_toolchain_ignored' }
)
foreach ($fixture in $contaminationFixtures) {
    $copy = Copy-JsonObject $cleanIsolation
    $copy.($fixture.property) = $false
    Assert-True (-not (Test-ColdIsolation $copy)) "$($fixture.name) contamination must fail"
}

foreach ($moduleName in @('mb-core', 'mb-color', 'mb-image')) {
    $moduleIndex = [Array]::IndexOf(@($policy.module_order), $moduleName)
    $nodes = @($policy.graph.nodes | Select-Object -First ($moduleIndex + 1))
    $nodeIds = @($nodes.identity)
    $edges = @($policy.graph.edges | Where-Object { $nodeIds -ccontains $_.from -and $nodeIds -ccontains $_.to })
    $expected = [pscustomobject][ordered]@{ nodes = $nodes; edges = $edges }
    Assert-True (Test-ExactGraph $expected $expected) "$moduleName exact graph must pass"

    $reordered = Copy-JsonObject $expected
    [array]::Reverse($reordered.nodes)
    [array]::Reverse($reordered.edges)
    Assert-True (Test-ExactGraph $reordered $expected) "$moduleName serialization-only order must not affect equality"

    $adjacent = Copy-JsonObject $expected
    $adjacent.nodes[0].identity = 'tchivs/mb-core@0.1.1'
    Assert-True (-not (Test-ExactGraph $adjacent $expected)) "$moduleName adjacent version must fail"

    $missingNode = Copy-JsonObject $expected
    $missingNode.nodes = @($missingNode.nodes | Select-Object -Skip 1)
    Assert-True (-not (Test-ExactGraph $missingNode $expected)) "$moduleName missing node must fail"

    $extraNode = Copy-JsonObject $expected
    $extraNode.nodes += [pscustomobject]@{ identity = 'tchivs/mb-extra@0.1.0' }
    Assert-True (-not (Test-ExactGraph $extraNode $expected)) "$moduleName extra node must fail"

    $empty = [pscustomobject]@{ nodes = @(); edges = @() }
    Assert-True (-not (Test-ExactGraph $empty $expected)) "$moduleName empty graph must fail"

    if ($edges.Count -gt 0) {
        $missingEdge = Copy-JsonObject $expected
        $missingEdge.edges = @($missingEdge.edges | Select-Object -Skip 1)
        Assert-True (-not (Test-ExactGraph $missingEdge $expected)) "$moduleName missing edge must fail"
    }
    $extraEdge = Copy-JsonObject $expected
    $extraEdge.edges += [pscustomobject]@{ from = $nodes[0].identity; to = $nodes[0].identity }
    Assert-True (-not (Test-ExactGraph $extraEdge $expected)) "$moduleName extra edge must fail"
}

$sha = 'a' * 64
$baseProof = [pscustomobject][ordered]@{
    schema_version = '1.0.0'
    evidence_mode = 'live_registry'
    policy_sha256 = $sha
    module = 'mb-core'
    identity = 'tchivs/mb-core'
    version = '0.1.0'
    dependency_source = 'registry_only'
    isolation = $cleanIsolation
    observation = [pscustomobject][ordered]@{ outcome = 'exact'; content_sha256 = $sha; strongest_identity = "sha256:$sha" }
    archive_sha256 = $sha
    downloaded_manifest_sha256 = $sha
    resolved_graph = [pscustomobject][ordered]@{ nodes = @([pscustomobject]@{ identity = 'tchivs/mb-core@0.1.0' }); edges = @() }
    toolchain = [pscustomobject][ordered]@{ moon_version = '0.1.20260713'; moonc_version = 'v0.10.4'; moonrun_version = '0.1.20260713'; root_sha256 = $sha }
    targets = @(
        [pscustomobject][ordered]@{ name = 'js'; check = 'pass'; test = 'pass'; runtime = 'pass'; output_sha256 = $sha },
        [pscustomobject][ordered]@{ name = 'wasm'; check = 'pass'; test = 'pass'; runtime = 'pass'; output_sha256 = $sha },
        [pscustomobject][ordered]@{ name = 'wasm-gc'; check = 'pass'; test = 'pass'; runtime = 'pass'; output_sha256 = $sha },
        [pscustomobject][ordered]@{ name = 'native'; check = 'pass'; test = 'pass'; runtime = 'pass'; output_sha256 = $sha }
    )
    behavior = [pscustomobject][ordered]@{ result = 'pass'; output_sha256 = $sha }
    verified = $true
    content_sha256 = $sha
}
Assert-True (($baseProof | ConvertTo-Json -Depth 100 | Test-Json -SchemaFile $schemaPath -ErrorAction Stop)) 'complete proof must satisfy schema'
foreach ($requiredFact in @($schema.required)) {
    $missing = Copy-JsonObject $baseProof
    $missing.PSObject.Properties.Remove([string]$requiredFact)
    Assert-True (-not ($missing | ConvertTo-Json -Depth 100 | Test-Json -SchemaFile $schemaPath -ErrorAction SilentlyContinue)) "missing $requiredFact must fail schema"
}

$emptyFactFixtures = @(
    @{ name = 'identity'; mutate = { param($x) $x.identity = '' } },
    @{ name = 'observation'; mutate = { param($x) $x.observation.strongest_identity = '' } },
    @{ name = 'archive digest'; mutate = { param($x) $x.archive_sha256 = '' } },
    @{ name = 'manifest digest'; mutate = { param($x) $x.downloaded_manifest_sha256 = '' } },
    @{ name = 'toolchain identity'; mutate = { param($x) $x.toolchain.moon_version = '' } },
    @{ name = 'toolchain root digest'; mutate = { param($x) $x.toolchain.root_sha256 = '' } },
    @{ name = 'target result'; mutate = { param($x) $x.targets[0].runtime = '' } },
    @{ name = 'target output digest'; mutate = { param($x) $x.targets[0].output_sha256 = '' } },
    @{ name = 'behavior result'; mutate = { param($x) $x.behavior.result = '' } },
    @{ name = 'behavior digest'; mutate = { param($x) $x.behavior.output_sha256 = '' } }
)
foreach ($fixture in $emptyFactFixtures) {
    $empty = Copy-JsonObject $baseProof
    & $fixture.mutate $empty
    Assert-True (-not ($empty | ConvertTo-Json -Depth 100 | Test-Json -SchemaFile $schemaPath -ErrorAction SilentlyContinue)) "empty $($fixture.name) must fail schema"
}

if ($IsolationOnly) {
    Write-Host "Cold registry consumer isolation selector: PASS ($($contaminationFixtures.Count) contamination fixtures; exact 1/2/3-node graph semantics)."
    exit 0
}

foreach ($moduleName in @('mb-core', 'mb-color', 'mb-image')) {
    Assert-True (Test-Path -LiteralPath (Join-Path $templateRoot "$moduleName\main\main.mbt") -PathType Leaf) "$moduleName behavior template must exist"
}

$behaviorContracts = [ordered]@{
    'mb-core' = [pscustomobject][ordered]@{
        dependencies = [ordered]@{ 'tchivs/mb-core' = '0.1.0' }
        imports = @('tchivs/mb-core/error', 'tchivs/mb-core/checked', 'tchivs/mb-core/budget', 'tchivs/mb-core/bytes', 'tchivs/mb-core/io', 'tchivs/mb-core/host')
        output = 'consumer=mb-core sum=42 bytes=4 position=0 clock=42'
    }
    'mb-color' = [pscustomobject][ordered]@{
        dependencies = [ordered]@{ 'tchivs/mb-core' = '0.1.0'; 'tchivs/mb-color' = '0.1.0' }
        imports = @('tchivs/mb-core/checked', 'tchivs/mb-color/model', 'tchivs/mb-color/quantize')
        output = 'consumer=mb-color sum=128 encoded=128 alpha=128 roundtrip=128'
    }
    'mb-image' = [pscustomobject][ordered]@{
        dependencies = [ordered]@{ 'tchivs/mb-core' = '0.1.0'; 'tchivs/mb-color' = '0.1.0'; 'tchivs/mb-image' = '0.1.0' }
        imports = @('tchivs/mb-core/budget', 'tchivs/mb-core/bytes', 'tchivs/mb-core/error', 'tchivs/mb-core/io', 'tchivs/mb-color/model', 'tchivs/mb-image/codec', 'tchivs/mb-image/ppm')
        output = 'consumer=mb-image bytes_read=17 bytes_written=17 width=2 height=1 digest=237717273'
    }
}

$manifestScratch = Join-Path ([IO.Path]::GetTempPath()) ("mnf-cold-manifest-test-{0}" -f [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $manifestScratch
try {
    foreach ($moduleName in @($behaviorContracts.Keys)) {
        $contract = $behaviorContracts[$moduleName]
        $templatePath = Join-Path $templateRoot "$moduleName\main\main.mbt"
        $source = Get-Content -Raw -LiteralPath $templatePath
        Assert-True ($source -cmatch [regex]::Escape("println(`"$($contract.output)`")")) "$moduleName deterministic output contract"
        Assert-True ($source -cnotmatch '(?i)(?:workspace|path dependency|git dependency|copied source|modules[/\\]mb-)') "$moduleName template must not reference an alternate source"

        $manifest = [pscustomobject][ordered]@{
            name = "mnf-registry-consumer/$moduleName"
            version = '0.0.0'
            preferred_target = 'native'
            supported_targets = '+js+wasm+wasm-gc+native'
            deps = [pscustomobject]$contract.dependencies
        }
        $manifestPath = Join-Path $manifestScratch "$moduleName-moon.mod.json"
        $manifest | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $manifestPath -Encoding utf8NoBOM
        $roundTrip = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json -Depth 20
        Assert-Sequence @($roundTrip.deps.PSObject.Properties.Name) @($contract.dependencies.Keys) "$moduleName generated dependency floors"
        foreach ($dependency in @($contract.dependencies.Keys)) {
            Assert-Equal ([string]$roundTrip.deps.$dependency) '0.1.0' "$moduleName $dependency dependency floor"
        }
        $manifestRaw = Get-Content -Raw -LiteralPath $manifestPath
        Assert-True ($manifestRaw -cnotmatch '(?i)"(?:path|git|workspace|local)"\s*:') "$moduleName generated manifest must be registry-only"

        $packageImports = @($contract.imports | ForEach-Object { "  `"$_`"," }) -join [Environment]::NewLine
        Assert-True (-not [string]::IsNullOrWhiteSpace($packageImports)) "$moduleName public import set must be nonempty"
        $expectedDigest = ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($contract.output)))).ToLowerInvariant()
        Assert-True ($expectedDigest -cmatch '^[0-9a-f]{64}$') "$moduleName behavior digest must be deterministic"
    }
}
finally {
    Remove-Item -LiteralPath $manifestScratch -Recurse -Force -ErrorAction SilentlyContinue
}
if ($BehaviorOnly) {
    Write-Host 'Cold registry consumer behavior selector: PASS (3 cumulative registry-only manifests and deterministic public outputs).'
    exit 0
}

Assert-True (Test-Path -LiteralPath $runnerPath -PathType Leaf) 'cold registry consumer runner must exist'
$runnerSource = Get-Content -Raw -LiteralPath $runnerPath
foreach ($requiredPattern in @(
    '[.]Environment[.]Clear[(][)]',
    'MOON_HOME',
    'MOON_TOOLCHAIN_ROOT',
    'Get-MooncakesObservation[.]ps1',
    "'tree'",
    "'check'",
    "'test'",
    "'run'",
    'Remove-ColdRoot',
    'canonicalNodes',
    'canonicalEdges',
    "EvidenceMode live_registry",
    "EvidenceMode fixture"
)) {
    Assert-True ($runnerSource -cmatch $requiredPattern) "runner source must retain boundary pattern $requiredPattern"
}
Assert-True ($runnerSource -cnotmatch '(?i)(?:build-only|compile[_-]only|MOONCAKES_(?:TOKEN|SECRET)|GITHUB_TOKEN|Authorization\s*:|Bearer\s+)') 'runner must reject compile-only evidence and contain no publisher credential input'

$runnerScratch = Join-Path ([IO.Path]::GetTempPath()) ("mnf-cold-runner-test-{0}" -f [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $runnerScratch
try {
    function New-RunnerFixture {
        param([string]$ModuleName)
        $moduleIndex = [Array]::IndexOf(@($policy.module_order), $ModuleName)
        $nodes = @($policy.graph.nodes | Select-Object -First ($moduleIndex + 1))
        $nodeIds = @($nodes.identity)
        $edges = @($policy.graph.edges | Where-Object { $nodeIds -ccontains $_.from -and $nodeIds -ccontains $_.to })
        $digest = ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($behaviorContracts[$ModuleName].output)))).ToLowerInvariant()
        $targets = @($policy.required_targets | ForEach-Object {
            [pscustomobject][ordered]@{ name = [string]$_; check = 'pass'; test = 'pass'; runtime = 'pass'; output_sha256 = $digest }
        })
        return [pscustomobject][ordered]@{
            schema_version = '1.0.0'
            isolation = Copy-JsonObject $cleanIsolation
            observation = [pscustomobject][ordered]@{ outcome = 'exact'; content_sha256 = $sha; strongest_identity = "sha256:$sha" }
            archive_sha256 = $sha
            downloaded_manifest_sha256 = [string]$policy.modules[$moduleIndex].manifest_sha256
            resolved_graph = [pscustomobject][ordered]@{ nodes = $nodes; edges = $edges }
            toolchain = [pscustomobject][ordered]@{ moon_version = 'moon 0.1.20260713'; moonc_version = 'v0.10.4'; moonrun_version = 'moonrun 0.1.20260713'; root_sha256 = $sha }
            targets = $targets
            behavior = [pscustomobject][ordered]@{ result = 'pass'; output_sha256 = $digest }
        }
    }

    function Invoke-RunnerFixture {
        param([string]$Name, [string]$ModuleName, $Fixture)
        $inputPath = Join-Path $runnerScratch "$Name-input.json"
        $outputPath = Join-Path $runnerScratch "$Name-proof.json"
        $Fixture | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $inputPath -Encoding utf8NoBOM
        & $runnerPath -Module $ModuleName -FixturePath $inputPath -OutputPath $outputPath -PolicyPath $policyPath -SchemaPath $schemaPath
        Assert-True (Test-Path -LiteralPath $outputPath -PathType Leaf) "$Name must emit a verified proof"
        $proof = Get-Content -Raw -LiteralPath $outputPath | ConvertFrom-Json -Depth 100
        Assert-True (($proof | ConvertTo-Json -Depth 100 | Test-Json -SchemaFile $schemaPath -ErrorAction Stop)) "$Name output must satisfy proof schema"
        Assert-Equal $proof.evidence_mode 'fixture' "$Name must remain explicitly non-live fixture evidence"
        $contentDigest = [string]$proof.content_sha256
        $proof.PSObject.Properties.Remove('content_sha256')
        $canonical = $proof | ConvertTo-Json -Depth 100 -Compress
        $computed = ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($canonical)))).ToLowerInvariant()
        Assert-Equal $contentDigest $computed "$Name content digest"
        return $proof
    }

    function Assert-RunnerFixtureFails {
        param([string]$Name, [string]$ModuleName, $Fixture)
        $inputPath = Join-Path $runnerScratch "$Name-input.json"
        $outputPath = Join-Path $runnerScratch "$Name-proof.json"
        $Fixture | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $inputPath -Encoding utf8NoBOM
        $failure = $null
        try { & $runnerPath -Module $ModuleName -FixturePath $inputPath -OutputPath $outputPath -PolicyPath $policyPath -SchemaPath $schemaPath } catch { $failure = $_.Exception.Message }
        Assert-True (-not [string]::IsNullOrWhiteSpace($failure)) "$Name fixture must fail"
        Assert-True (-not (Test-Path -LiteralPath $outputPath)) "$Name fixture must fail before verified evidence is written"
    }

    foreach ($moduleName in @('mb-core', 'mb-color', 'mb-image')) {
        $null = Invoke-RunnerFixture "exact-$moduleName" $moduleName (New-RunnerFixture $moduleName)
    }

    $reordered = New-RunnerFixture 'mb-image'
    [array]::Reverse($reordered.resolved_graph.nodes)
    [array]::Reverse($reordered.resolved_graph.edges)
    $reorderedProof = Invoke-RunnerFixture 'serialization-order-only' 'mb-image' $reordered
    Assert-Sequence @($reorderedProof.resolved_graph.nodes.identity) @($policy.graph.nodes.identity) 'proof canonicalizes node order while equality remains semantic'
    Assert-Sequence @($reorderedProof.resolved_graph.edges | ForEach-Object { "$($_.from)->$($_.to)" }) @($policy.graph.edges | ForEach-Object { "$($_.from)->$($_.to)" }) 'proof canonicalizes edge order while equality remains semantic'

    foreach ($property in @($cleanIsolation.PSObject.Properties.Name)) {
        $fixture = New-RunnerFixture 'mb-core'
        $fixture.isolation.$property = $false
        Assert-RunnerFixtureFails "contamination-$property" 'mb-core' $fixture
    }

    foreach ($property in @('schema_version', 'observation', 'archive_sha256', 'downloaded_manifest_sha256', 'resolved_graph', 'toolchain', 'targets', 'behavior')) {
        $fixture = New-RunnerFixture 'mb-core'
        $fixture.PSObject.Properties.Remove($property)
        Assert-RunnerFixtureFails "missing-$property" 'mb-core' $fixture
    }

    $graphCases = @(
        @{ name = 'adjacent-version'; mutate = { param($x) $x.resolved_graph.nodes[0].identity = 'tchivs/mb-core@0.1.1' } },
        @{ name = 'missing-node'; mutate = { param($x) $x.resolved_graph.nodes = @($x.resolved_graph.nodes | Select-Object -Skip 1) } },
        @{ name = 'extra-node'; mutate = { param($x) $x.resolved_graph.nodes += [pscustomobject]@{ identity = 'tchivs/mb-extra@0.1.0' } } },
        @{ name = 'empty-tree'; mutate = { param($x) $x.resolved_graph.nodes = @(); $x.resolved_graph.edges = @() } },
        @{ name = 'missing-edge'; mutate = { param($x) $x.resolved_graph.edges = @($x.resolved_graph.edges | Select-Object -Skip 1) } },
        @{ name = 'extra-edge'; mutate = { param($x) $x.resolved_graph.edges += [pscustomobject]@{ from = 'tchivs/mb-image@0.1.0'; to = 'tchivs/mb-image@0.1.0' } } }
    )
    foreach ($case in $graphCases) {
        $fixture = New-RunnerFixture 'mb-image'
        & $case.mutate $fixture
        Assert-RunnerFixtureFails "graph-$($case.name)" 'mb-image' $fixture
    }

    $gateCases = @(
        @{ name = 'observation-missing'; mutate = { param($x) $x.observation.outcome = 'unknown' } },
        @{ name = 'archive-identity-mismatch'; mutate = { param($x) $x.archive_sha256 = 'b' * 64 } },
        @{ name = 'manifest-mismatch'; mutate = { param($x) $x.downloaded_manifest_sha256 = 'b' * 64 } },
        @{ name = 'empty-toolchain'; mutate = { param($x) $x.toolchain.moon_version = '' } },
        @{ name = 'missing-target'; mutate = { param($x) $x.targets = @($x.targets | Select-Object -First 3) } },
        @{ name = 'target-order'; mutate = { param($x) [array]::Reverse($x.targets) } },
        @{ name = 'check-failed'; mutate = { param($x) $x.targets[0].check = 'fail' } },
        @{ name = 'test-failed'; mutate = { param($x) $x.targets[0].test = 'fail' } },
        @{ name = 'compile-only-native'; mutate = { param($x) $x.targets[3].runtime = 'compile_only' } },
        @{ name = 'target-output-mismatch'; mutate = { param($x) $x.targets[0].output_sha256 = 'b' * 64 } },
        @{ name = 'behavior-failed'; mutate = { param($x) $x.behavior.result = 'fail' } },
        @{ name = 'behavior-empty'; mutate = { param($x) $x.behavior.output_sha256 = '' } }
    )
    foreach ($case in $gateCases) {
        $fixture = New-RunnerFixture 'mb-core'
        & $case.mutate $fixture
        Assert-RunnerFixtureFails "gate-$($case.name)" 'mb-core' $fixture
    }

    Write-Host "Cold registry consumer selector: PASS (3 exact layers, 16 contamination cases, $($graphCases.Count) graph cases, $($gateCases.Count) closed-gate cases)."
}
finally {
    Remove-Item -LiteralPath $runnerScratch -Recurse -Force -ErrorAction SilentlyContinue
}
