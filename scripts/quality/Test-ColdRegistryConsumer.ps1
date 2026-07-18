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
    'schema_version', 'policy_sha256', 'module', 'identity', 'version', 'dependency_source',
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
if ($BehaviorOnly) {
    Write-Host 'Cold registry consumer behavior selector: PASS'
    exit 0
}

Assert-True (Test-Path -LiteralPath $runnerPath -PathType Leaf) 'cold registry consumer runner must exist'
Write-Host 'Cold registry consumer selector: PASS'
