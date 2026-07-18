[CmdletBinding()]
param(
    [switch]$SchemaOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$policyPath = Join-Path $repoRoot 'policy\phase-08-distribution.json'
$schemaPath = Join-Path $repoRoot 'release\registry\module-observation-schema.json'
$observerPath = Join-Path $repoRoot 'scripts\quality\Get-MooncakesObservation.ps1'

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

function Assert-ClosedObjectSchema {
    param($Schema, [string]$Path)
    if (($Schema.PSObject.Properties.Name -contains 'type') -and $Schema.type -eq 'object') {
        Assert-True ($Schema.PSObject.Properties.Name -contains 'additionalProperties') "$Path must declare additionalProperties"
        Assert-Equal $Schema.additionalProperties $false "$Path must be closed"
    }
    if ($Schema.PSObject.Properties.Name -contains 'properties') {
        foreach ($property in $Schema.properties.PSObject.Properties) {
            Assert-ClosedObjectSchema $property.Value "$Path.$($property.Name)"
        }
    }
    if ($Schema.PSObject.Properties.Name -contains 'items' -and $null -ne $Schema.items) {
        Assert-ClosedObjectSchema $Schema.items "$Path[]"
    }
    if ($Schema.PSObject.Properties.Name -contains '$defs') {
        foreach ($definition in $Schema.'$defs'.PSObject.Properties) {
            Assert-ClosedObjectSchema $definition.Value "$Path.#/`$defs/$($definition.Name)"
        }
    }
}

Assert-True (Test-Path -LiteralPath $policyPath -PathType Leaf) 'distribution policy must exist'
Assert-True (Test-Path -LiteralPath $schemaPath -PathType Leaf) 'observation schema must exist'

$policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json -Depth 100
$schema = Get-Content -Raw -LiteralPath $schemaPath | ConvertFrom-Json -Depth 100

Assert-Equal $policy.schema_version '1.0.0' 'policy schema version'
Assert-Equal $policy.dependency_source 'registry_only' 'dependency source must be registry-only'
Assert-Sequence $policy.module_order @('mb-core', 'mb-color', 'mb-image') 'canonical module order'
Assert-Sequence $policy.required_targets @('js', 'wasm', 'wasm-gc', 'native') 'required target order'
Assert-Sequence $policy.metadata_fields @('name', 'version', 'description', 'license', 'repository', 'readme', 'preferred-target', 'supported-targets') 'closed metadata field order'
Assert-Sequence $policy.package_inventory_order @('mb-core', 'mb-color', 'mb-image') 'package inventory order'
Assert-Sequence $policy.surface_order @('publish_preflight', 'authenticated_account', 'public_user', 'public_module', 'registry_index', 'archive', 'downloaded_manifest', 'versioned_assets') 'surface order'
Assert-Sequence $policy.surface_classifications @('exact', 'absent', 'mismatch', 'unknown') 'surface classifications'
Assert-Sequence $policy.polling.states @('pending', 'exact', 'absent', 'mismatch', 'timeout', 'unknown') 'polling states'
Assert-Equal $policy.polling.interval_seconds 15 'polling interval'
Assert-Equal $policy.polling.max_attempts 20 'polling attempt bound'
Assert-Sequence $policy.terminal_dispositions @('exact_match', 'confirmed_absent', 'mismatch_incident', 'timeout_unknown', 'observation_unknown') 'terminal dispositions'
Assert-Equal $policy.mutation_authority $false 'observation must never authorize mutation'

Assert-Sequence ($policy.graph.nodes | ForEach-Object { $_.identity }) @('tchivs/mb-core@0.1.0', 'tchivs/mb-color@0.1.0', 'tchivs/mb-image@0.1.0') 'exact graph nodes'
Assert-Sequence ($policy.graph.edges | ForEach-Object { "$($_.from)->$($_.to)" }) @('tchivs/mb-color@0.1.0->tchivs/mb-core@0.1.0', 'tchivs/mb-image@0.1.0->tchivs/mb-core@0.1.0', 'tchivs/mb-image@0.1.0->tchivs/mb-color@0.1.0') 'exact graph edges'

Assert-Equal $schema.'$schema' 'https://json-schema.org/draft/2020-12/schema' 'schema dialect'
Assert-ClosedObjectSchema $schema '$'
Assert-Sequence $schema.properties.outcome.enum @('exact', 'absent', 'mismatch', 'unknown') 'schema outcomes'
Assert-Sequence $schema.properties.terminal_disposition.enum $policy.terminal_dispositions 'schema dispositions'
Assert-Equal $schema.properties.mutation_authorized.const $false 'schema forbids mutation authority'

$invalidPolicyFixtures = @(
    @{ name = 'missing module'; mutate = { param($copy) $copy.modules = @($copy.modules | Select-Object -First 2) } },
    @{ name = 'extra module'; mutate = { param($copy) $copy.modules += [pscustomobject]@{ module = 'mb-extra' } } },
    @{ name = 'reordered module'; mutate = { param($copy) [array]::Reverse($copy.module_order) } },
    @{ name = 'adjacent version'; mutate = { param($copy) $copy.modules[0].version = '0.1.1' } },
    @{ name = 'unrecognized surface'; mutate = { param($copy) $copy.surface_order += 'spa_html' } },
    @{ name = 'unrecognized disposition'; mutate = { param($copy) $copy.terminal_dispositions += 'retry_publish' } }
)
foreach ($fixture in $invalidPolicyFixtures) {
    $copy = ($policy | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100)
    & $fixture.mutate $copy
    $isExact = (($copy.module_order -join '|') -ceq ($policy.module_order -join '|')) -and
        (($copy.surface_order -join '|') -ceq ($policy.surface_order -join '|')) -and
        (($copy.terminal_dispositions -join '|') -ceq ($policy.terminal_dispositions -join '|')) -and
        (($copy.modules | ConvertTo-Json -Depth 20 -Compress) -ceq ($policy.modules | ConvertTo-Json -Depth 20 -Compress))
    Assert-True (-not $isExact) "$($fixture.name) policy fixture must be rejected"
}

if ($SchemaOnly) {
    Write-Host 'Mooncakes observation policy/schema selector: PASS'
    exit 0
}

Assert-True (Test-Path -LiteralPath $observerPath -PathType Leaf) 'observer must exist'
$observerSource=Get-Content -LiteralPath $observerPath -Raw
foreach($binding in @(
    '[Parameter(Mandatory)][string]$FixturePath',
    '[Parameter(Mandatory)][string]$PolicyPath',
    '[Parameter(Mandatory)][string]$SchemaPath'
)) {
    Assert-True ($observerSource.Contains($binding,[StringComparison]::Ordinal)) "observer must require explicit clone-rooted binding $binding"
}
$hostedSource=Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\quality\Invoke-Phase08HostedRun.ps1') -Raw
foreach($binding in @('MaterializePublicSurface','IndexSanitizedArtifact','surfaces/$TargetModule/$ObservationPhase/public-surface.json','exact-existing','post-publish')) {
    Assert-True ($hostedSource.Contains($binding,[StringComparison]::Ordinal)) "hosted materialization/index binding missing $binding"
}

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ("mnf-observation-test-{0}" -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch | Out-Null
try {
    $base = [ordered]@{
        schema_version = '1.0.0'
        attempts = @(
            [ordered]@{
                attempt = 1
                observed_at_utc = '2026-07-18T00:00:00.0000000Z'
                surfaces = [ordered]@{
                    publish_preflight = [ordered]@{ classification = 'exact'; status = 'not_run_credential_free' }
                    authenticated_account = [ordered]@{ classification = 'exact'; status = 'not_observed_credential_free' }
                    public_user = [ordered]@{ classification = 'exact'; owner = 'tchivs' }
                    public_module = [ordered]@{ classification = 'exact'; identity = 'tchivs/mb-core'; version = '0.1.0' }
                    registry_index = [ordered]@{ classification = 'exact'; identity = 'tchivs/mb-core'; version = '0.1.0'; dependencies = [ordered]@{}; checksum = 'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' }
                    archive = [ordered]@{ classification = 'exact'; sha256 = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' }
                    downloaded_manifest = [ordered]@{ classification = 'exact'; metadata = $policy.modules[0].metadata; dependencies = [ordered]@{}; packages = $policy.modules[0].public_packages; manifest_sha256 = $policy.modules[0].manifest_sha256 }
                    versioned_assets = [ordered]@{ classification = 'exact'; readme_sha256 = $policy.modules[0].readme_sha256 }
                }
            }
        )
    }

    function Invoke-Fixture {
        param([string]$Name, $Fixture)
        $fixturePath = Join-Path $scratch "$Name-input.json"
        $outputPath = Join-Path $scratch "$Name-output.json"
        $Fixture | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $fixturePath -Encoding utf8NoBOM
        & $observerPath -FixturePath $fixturePath -OutputPath $outputPath -PolicyPath $policyPath -SchemaPath $schemaPath
        Assert-True (Test-Path -LiteralPath $outputPath -PathType Leaf) "$Name must emit sanitized observation"
        return Get-Content -Raw -LiteralPath $outputPath | ConvertFrom-Json -Depth 100
    }

    $agreement = Invoke-Fixture 'agreement' $base
    Assert-Equal $agreement.outcome 'exact' "agreement outcome ($($agreement.reason))"
    Assert-Equal $agreement.terminal_disposition 'exact_match' 'agreement disposition'
    Assert-Equal $agreement.mutation_authorized $false 'agreement cannot authorize mutation'
    Assert-True ($agreement.content_sha256 -cmatch '^[0-9a-f]{64}$') 'agreement content digest'
    Assert-True (-not (($agreement | ConvertTo-Json -Depth 100) -cmatch '(?i)token|secret|password|cookie|raw_body')) 'observation projection must exclude secret/raw fields'
    $agreementRepeat = Invoke-Fixture 'agreement-repeat' $base
    Assert-Equal $agreementRepeat.content_sha256 $agreement.content_sha256 'agreement content digest must be deterministic'

    $cases = @(
        @{ name = 'empty'; expected = 'unknown'; mutate = { param($x) $x.attempts[0].surfaces.public_module.identity = '' } },
        @{ name = 'adjacent'; expected = 'mismatch'; mutate = { param($x) $x.attempts[0].surfaces.public_module.version = '0.1.1' } },
        @{ name = 'drifted'; expected = 'mismatch'; mutate = { param($x) $x.attempts[0].surfaces.downloaded_manifest.metadata.description = 'drifted' } },
        @{ name = 'ambiguous'; expected = 'unknown'; mutate = { param($x) $x.attempts[0].surfaces.registry_index.classification = 'unknown' } },
        @{ name = 'reordered-surface'; expected = 'unknown'; mutate = { param($x) $module = $x.attempts[0].surfaces.public_module; $x.attempts[0].surfaces.public_module = [pscustomobject][ordered]@{ version = $module.version; identity = $module.identity; classification = $module.classification } } },
        @{ name = 'weaker-checksum'; expected = 'unknown'; mutate = { param($x) $x.attempts[0].surfaces.registry_index.checksum = 'etag:abc' } },
        @{ name = 'conflicting-checksum'; expected = 'mismatch'; mutate = { param($x) $x.attempts[0].surfaces.archive.sha256 = ('b' * 64) } },
        @{ name = 'secret-bearing'; expected = 'unknown'; mutate = { param($x) $x.attempts[0].surfaces.public_user | Add-Member -NotePropertyName token -NotePropertyValue 'secret-value' } }
    )
    foreach ($case in $cases) {
        $fixture = ($base | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100)
        & $case.mutate $fixture
        $result = Invoke-Fixture $case.name $fixture
        Assert-Equal $result.outcome $case.expected "$($case.name) outcome"
        Assert-Equal $result.mutation_authorized $false "$($case.name) cannot authorize mutation"
    }

    $timeout = ($base | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100)
    $timeout.attempts = @()
    foreach ($attempt in 1..$policy.polling.max_attempts) {
        $timeout.attempts += [pscustomobject]@{
            attempt = $attempt
            observed_at_utc = ([datetimeoffset]'2026-07-18T00:00:00Z').AddSeconds(($attempt - 1) * $policy.polling.interval_seconds).ToString('O')
            surfaces = [pscustomobject]@{ public_module = [pscustomobject]@{ classification = 'absent' } }
        }
    }
    $timeoutResult = Invoke-Fixture 'bounded-timeout' $timeout
    Assert-Equal $timeoutResult.outcome 'unknown' 'bounded timeout outcome'
    Assert-Equal $timeoutResult.terminal_disposition 'timeout_unknown' 'bounded timeout disposition'
    Assert-Equal $timeoutResult.attempt_count $policy.polling.max_attempts 'bounded timeout attempt count'

    Write-Host 'Mooncakes observation selector: PASS'
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
