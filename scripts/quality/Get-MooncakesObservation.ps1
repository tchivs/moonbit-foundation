[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$FixturePath,
    [Parameter(Mandatory)][string]$OutputPath,
    [ValidateSet('mb-core', 'mb-color', 'mb-image')][string]$Module = 'mb-core',
    [Parameter(Mandatory)][string]$PolicyPath,
    [Parameter(Mandatory)][string]$SchemaPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Get-Utf8Sha256 {
    param([Parameter(Mandatory)][string]$Text)
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text)
    return ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))).ToLowerInvariant()
}

function Get-FileSha256 {
    param([Parameter(Mandatory)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-ExactProperties {
    param([object]$Value, [string[]]$Expected)
    if ($null -eq $Value) { return $false }
    $actual = @($Value.PSObject.Properties.Name)
    if ($actual.Count -ne $Expected.Count) { return $false }
    for ($index = 0; $index -lt $Expected.Count; $index++) {
        if ($actual[$index] -cne $Expected[$index]) { return $false }
    }
    return $true
}

function Test-ForbiddenShape {
    param([object]$Value, [object]$Policy)
    $forbiddenNames = @($Policy.redaction.forbidden_field_names)
    function Visit-Value([object]$Current) {
        if ($null -eq $Current) { return $false }
        if ($Current -is [string]) {
            foreach ($pattern in @($Policy.redaction.forbidden_value_patterns)) {
                if ([string]$Current -cmatch [string]$pattern) { return $true }
            }
            return $false
        }
        if ($Current -is [ValueType]) { return $false }
        if ($Current -is [Collections.IEnumerable] -and $Current -isnot [pscustomobject] -and $Current -isnot [Collections.IDictionary]) {
            foreach ($item in $Current) { if (Visit-Value $item) { return $true } }
            return $false
        }
        foreach ($property in @($Current.PSObject.Properties)) {
            if ($forbiddenNames -ccontains [string]$property.Name) { return $true }
            if (Visit-Value $property.Value) { return $true }
        }
        return $false
    }
    return Visit-Value $Value
}

function ConvertTo-Dependencies {
    param([object]$Value)
    if ($null -eq $Value) { return @() }
    $result = [Collections.Generic.List[object]]::new()
    if ($Value -is [pscustomobject]) {
        foreach ($property in @($Value.PSObject.Properties)) {
            $result.Add([pscustomobject][ordered]@{ identity = [string]$property.Name; version = [string]$property.Value })
        }
    } else {
        foreach ($dependency in @($Value)) {
            if (-not (Test-ExactProperties $dependency @('identity', 'version'))) { return $null }
            $result.Add([pscustomobject][ordered]@{ identity = [string]$dependency.identity; version = [string]$dependency.version })
        }
    }
    return @($result)
}

function Test-JsonEqual {
    param([object]$Actual, [object]$Expected)
    return (($Actual | ConvertTo-Json -Depth 100 -Compress) -ceq ($Expected | ConvertTo-Json -Depth 100 -Compress))
}

function Get-ExpectedGraph {
    param([object]$Policy, [string]$ModuleName)
    $moduleIndex = [Array]::IndexOf(@($Policy.module_order), $ModuleName)
    $selected = @($Policy.modules | Select-Object -First ($moduleIndex + 1))
    $nodes = @($selected | ForEach-Object { [pscustomobject][ordered]@{ identity = "$($_.identity)@$($_.version)" } })
    $identities = @($nodes.identity)
    $edges = @($Policy.graph.edges | Where-Object { $identities -ccontains $_.from -and $identities -ccontains $_.to } | ForEach-Object {
        [pscustomobject][ordered]@{ from = [string]$_.from; to = [string]$_.to }
    })
    return [pscustomobject][ordered]@{ nodes = $nodes; edges = $edges }
}

function New-SanitizedResult {
    param(
        [object]$Policy,
        [object]$ExpectedModule,
        [string]$PolicySha256,
        [ValidateSet('exact', 'absent', 'mismatch', 'unknown')][string]$Outcome,
        [string]$Reason,
        [string]$Disposition,
        [int]$AttemptCount,
        [string]$StartedAt,
        [string]$CompletedAt,
        [object[]]$Surfaces,
        [AllowNull()][object]$Observed
    )
    $projection = [ordered]@{
        schema_version = '1.0.0'
        policy_sha256 = $PolicySha256
        identity = [string]$ExpectedModule.identity
        version = [string]$ExpectedModule.version
        outcome = $Outcome
        reason = $Reason
        terminal_disposition = $Disposition
        mutation_authorized = $false
        attempt_count = $AttemptCount
        started_at_utc = $StartedAt
        completed_at_utc = $CompletedAt
        surfaces = @($Surfaces)
    }
    if ($null -ne $Observed) { $projection.observed = $Observed }
    $projection.content_sha256 = Get-Utf8Sha256 (([pscustomobject]$projection) | ConvertTo-Json -Depth 100 -Compress)
    return [pscustomobject]$projection
}

function Write-SanitizedResult {
    param([object]$Result, [string]$Path, [string]$Schema)
    $json = $Result | ConvertTo-Json -Depth 100
    if (-not ($json | Test-Json -SchemaFile $Schema -ErrorAction Stop)) {
        throw 'OBS01-SCHEMA: sanitized observation does not satisfy its closed schema.'
    }
    $parent = Split-Path -Parent $Path
    if ([string]::IsNullOrWhiteSpace($parent)) { $parent = (Get-Location).Path }
    $null = New-Item -ItemType Directory -Path $parent -Force
    $temporary = Join-Path $parent ('.observation-{0}.tmp' -f [guid]::NewGuid().ToString('N'))
    try {
        [IO.File]::WriteAllText($temporary, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $temporary -Destination $Path -Force
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    }
}

$policy = Get-Content -Raw -LiteralPath $PolicyPath | ConvertFrom-Json -Depth 100
$null = Get-Content -Raw -LiteralPath $SchemaPath | ConvertFrom-Json -Depth 100
$expectedModule = @($policy.modules | Where-Object { [string]$_.module -ceq $Module })
if ($expectedModule.Count -ne 1) { throw 'OBS01-POLICY: selected module is not unique in policy.' }
$expectedModule = $expectedModule[0]
$policySha256 = Get-FileSha256 $PolicyPath

$fallbackTime = '1970-01-01T00:00:00.0000000Z'
$input = $null
$unsafe = $false
try {
    $raw = Get-Content -Raw -LiteralPath $FixturePath
    $input = $raw | ConvertFrom-Json -Depth 100
    $unsafe = Test-ForbiddenShape -Value $input -Policy $policy
} catch {
    $input = $null
}

if ($null -eq $input -or $unsafe -or -not (Test-ExactProperties $input @('schema_version', 'attempts')) -or $input.schema_version -cne '1.0.0') {
    $result = New-SanitizedResult $policy $expectedModule $policySha256 'unknown' 'malformed_or_secret_shaped_input' 'observation_unknown' 1 $fallbackTime $fallbackTime @(
        [pscustomobject][ordered]@{ name = 'public_module'; classification = 'unknown'; attempt = 1; observed_at_utc = $fallbackTime }
    ) $null
    Write-SanitizedResult $result $OutputPath $SchemaPath
    exit 0
}

$attempts = @($input.attempts)
if ($attempts.Count -eq 0 -or $attempts.Count -gt [int]$policy.polling.max_attempts) {
    $result = New-SanitizedResult $policy $expectedModule $policySha256 'unknown' 'invalid_attempt_count' 'observation_unknown' 1 $fallbackTime $fallbackTime @(
        [pscustomobject][ordered]@{ name = 'public_module'; classification = 'unknown'; attempt = 1; observed_at_utc = $fallbackTime }
    ) $null
    Write-SanitizedResult $result $OutputPath $SchemaPath
    exit 0
}

$attemptShapeValid = $true
for ($index = 0; $index -lt $attempts.Count; $index++) {
    $attempt = $attempts[$index]
    if (-not (Test-ExactProperties $attempt @('attempt', 'observed_at_utc', 'surfaces')) -or [int]$attempt.attempt -ne ($index + 1)) {
        $attemptShapeValid = $false
        break
    }
    try { $null = [datetimeoffset]::Parse([string]$attempt.observed_at_utc) } catch { $attemptShapeValid = $false; break }
    if ($index -gt 0) {
        $priorTime=[datetimeoffset]::Parse([string]$attempts[$index-1].observed_at_utc)
        $currentTime=[datetimeoffset]::Parse([string]$attempt.observed_at_utc)
        if (($currentTime-$priorTime).TotalSeconds -ne [int]$policy.polling.interval_seconds) { $attemptShapeValid=$false;break }
    }
}
if (-not $attemptShapeValid) {
    $result = New-SanitizedResult $policy $expectedModule $policySha256 'unknown' 'malformed_attempt_sequence' 'observation_unknown' $attempts.Count $fallbackTime $fallbackTime @(
        [pscustomobject][ordered]@{ name = 'public_module'; classification = 'unknown'; attempt = 1; observed_at_utc = $fallbackTime }
    ) $null
    Write-SanitizedResult $result $OutputPath $SchemaPath
    exit 0
}

$finalAttempt = $attempts[-1]
$startedAt = [string]$attempts[0].observed_at_utc
$completedAt = [string]$finalAttempt.observed_at_utc
$surfaceRecords = [Collections.Generic.List[object]]::new()
foreach ($surfaceName in @($policy.surface_order)) {
    if ($finalAttempt.surfaces.PSObject.Properties.Name -ccontains [string]$surfaceName) {
        $surface = $finalAttempt.surfaces.$surfaceName
        $classification = if ($surface.PSObject.Properties.Name -ccontains 'classification') { [string]$surface.classification } else { 'unknown' }
        if (@($policy.surface_classifications) -cnotcontains $classification) { $classification = 'unknown' }
        $surfaceRecords.Add([pscustomobject][ordered]@{
            name = [string]$surfaceName
            classification = $classification
            attempt = [int]$finalAttempt.attempt
            observed_at_utc = $completedAt
        })
    }
}

if ($surfaceRecords.Count -eq 0) {
    $surfaceRecords.Add([pscustomobject][ordered]@{ name = 'public_module'; classification = 'unknown'; attempt = [int]$finalAttempt.attempt; observed_at_utc = $completedAt })
}

$presentNames = @($surfaceRecords.name)
if ($attempts.Count -eq [int]$policy.polling.max_attempts -and $presentNames -ccontains 'public_module' -and
    [string]$finalAttempt.surfaces.public_module.classification -ceq 'absent') {
    $result = New-SanitizedResult $policy $expectedModule $policySha256 'unknown' 'bounded_polling_timeout' 'timeout_unknown' $attempts.Count $startedAt $completedAt @($surfaceRecords) $null
    Write-SanitizedResult $result $OutputPath $SchemaPath
    exit 0
}

$requiredSurfaces = @($policy.surface_order)
$missing = @($requiredSurfaces | Where-Object { $presentNames -cnotcontains $_ })
$classifications = @($surfaceRecords.classification)
if ($classifications -ccontains 'mismatch') {
    $result = New-SanitizedResult $policy $expectedModule $policySha256 'mismatch' 'surface_reported_mismatch' 'mismatch_incident' $attempts.Count $startedAt $completedAt @($surfaceRecords) $null
    Write-SanitizedResult $result $OutputPath $SchemaPath
    exit 0
}
if ($missing.Count -ne 0 -or $classifications -ccontains 'unknown') {
    $result = New-SanitizedResult $policy $expectedModule $policySha256 'unknown' 'missing_or_ambiguous_surface' 'observation_unknown' $attempts.Count $startedAt $completedAt @($surfaceRecords) $null
    Write-SanitizedResult $result $OutputPath $SchemaPath
    exit 0
}
if ($classifications -ccontains 'absent') {
    $allPublicAbsent = @('public_module', 'registry_index', 'archive', 'downloaded_manifest', 'versioned_assets') | ForEach-Object {
        $finalAttempt.surfaces.$_.classification -ceq 'absent'
    }
    if ($allPublicAbsent -contains $false) {
        $result = New-SanitizedResult $policy $expectedModule $policySha256 'unknown' 'conflicting_absence_surfaces' 'observation_unknown' $attempts.Count $startedAt $completedAt @($surfaceRecords) $null
    } else {
        $result = New-SanitizedResult $policy $expectedModule $policySha256 'absent' 'exact_version_absent' 'confirmed_absent' $attempts.Count $startedAt $completedAt @($surfaceRecords) $null
    }
    Write-SanitizedResult $result $OutputPath $SchemaPath
    exit 0
}

$surfaces = $finalAttempt.surfaces
$shapeMap = [ordered]@{
    publish_preflight = @('classification', 'status')
    authenticated_account = @('classification', 'status')
    public_user = @('classification', 'owner')
    public_module = @('classification', 'identity', 'version')
    registry_index = @('classification', 'identity', 'version', 'dependencies', 'checksum')
    archive = @('classification', 'sha256')
    downloaded_manifest = @('classification', 'metadata', 'dependencies', 'packages', 'manifest_sha256')
    versioned_assets = @('classification', 'readme_sha256')
}
$exactShape = $true
foreach ($entry in $shapeMap.GetEnumerator()) {
    if (-not (Test-ExactProperties $surfaces.($entry.Key) $entry.Value)) { $exactShape = $false; break }
}

$dependencies = @(ConvertTo-Dependencies $surfaces.registry_index.dependencies)
$manifestDependencies = @(ConvertTo-Dependencies $surfaces.downloaded_manifest.dependencies)
$expectedDependencies = @($expectedModule.dependencies)
$metadataExact = Test-JsonEqual $surfaces.downloaded_manifest.metadata $expectedModule.metadata
$packagesExact = Test-JsonEqual @($surfaces.downloaded_manifest.packages) @($expectedModule.public_packages)
$dependenciesExact = (Test-JsonEqual @($dependencies) $expectedDependencies) -and
    (Test-JsonEqual @($manifestDependencies) $expectedDependencies)
$identityExact = [string]$surfaces.public_user.owner -ceq 'tchivs' -and
    [string]$surfaces.public_module.identity -ceq [string]$expectedModule.identity -and
    [string]$surfaces.public_module.version -ceq [string]$expectedModule.version -and
    [string]$surfaces.registry_index.identity -ceq [string]$expectedModule.identity -and
    [string]$surfaces.registry_index.version -ceq [string]$expectedModule.version
$checksum = [string]$surfaces.registry_index.checksum
$archiveSha = [string]$surfaces.archive.sha256
$checksumStrong = $checksum -cmatch '^sha256:[0-9a-f]{64}$'
$checksumExact = $checksumStrong -and $checksum.Substring(7) -ceq $archiveSha
$assetExact = [string]$surfaces.versioned_assets.readme_sha256 -ceq [string]$expectedModule.readme_sha256
$manifestExact = [string]$surfaces.downloaded_manifest.manifest_sha256 -ceq [string]$expectedModule.manifest_sha256
Write-Verbose ("exact checks: shape={0}; identity={1}; metadata={2}; packages={3}; dependencies={4}; checksum={5}; asset={6}; manifest={7}" -f $exactShape, $identityExact, $metadataExact, $packagesExact, $dependenciesExact, $checksumExact, $assetExact, $manifestExact)

if (-not $exactShape) {
    $result = New-SanitizedResult $policy $expectedModule $policySha256 'unknown' 'unrecognized_or_missing_surface_shape' 'observation_unknown' $attempts.Count $startedAt $completedAt @($surfaceRecords) $null
    Write-SanitizedResult $result $OutputPath $SchemaPath
    exit 0
}
$requiredStrings = @(
    $surfaces.public_user.owner,
    $surfaces.public_module.identity,
    $surfaces.public_module.version,
    $surfaces.registry_index.identity,
    $surfaces.registry_index.version,
    $surfaces.registry_index.checksum,
    $surfaces.archive.sha256,
    $surfaces.downloaded_manifest.manifest_sha256,
    $surfaces.versioned_assets.readme_sha256
)
if (@($requiredStrings | Where-Object { [string]::IsNullOrWhiteSpace([string]$_) }).Count -ne 0) {
    $result = New-SanitizedResult $policy $expectedModule $policySha256 'unknown' 'empty_required_surface_fact' 'observation_unknown' $attempts.Count $startedAt $completedAt @($surfaceRecords) $null
    Write-SanitizedResult $result $OutputPath $SchemaPath
    exit 0
}

if (-not $checksumStrong) {
    $result = New-SanitizedResult $policy $expectedModule $policySha256 'unknown' 'strong_sha256_identity_unavailable' 'observation_unknown' $attempts.Count $startedAt $completedAt @($surfaceRecords) $null
    Write-SanitizedResult $result $OutputPath $SchemaPath
    exit 0
}
if (-not $identityExact -or -not $metadataExact -or -not $packagesExact -or -not $dependenciesExact -or
    -not $checksumExact -or -not $assetExact -or -not $manifestExact) {
    $result = New-SanitizedResult $policy $expectedModule $policySha256 'mismatch' 'cross_surface_exact_equality_failed' 'mismatch_incident' $attempts.Count $startedAt $completedAt @($surfaceRecords) $null
    Write-SanitizedResult $result $OutputPath $SchemaPath
    exit 0
}

$expectedGraph = Get-ExpectedGraph $policy $Module
$observed = [pscustomobject][ordered]@{
    metadata = $expectedModule.metadata
    dependencies = $expectedDependencies
    public_packages = @($expectedModule.public_packages)
    targets = @($policy.required_targets)
    graph = $expectedGraph
    manifest_sha256 = [string]$expectedModule.manifest_sha256
    readme_sha256 = [string]$expectedModule.readme_sha256
    archive_sha256 = $archiveSha
}
$result = New-SanitizedResult $policy $expectedModule $policySha256 'exact' 'all_required_surfaces_agree' 'exact_match' $attempts.Count $startedAt $completedAt @($surfaceRecords) $observed
Write-SanitizedResult $result $OutputPath $SchemaPath
