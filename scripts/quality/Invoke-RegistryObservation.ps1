[CmdletBinding()]
param(
  [switch]$CaptureAuthority,
  [switch]$LibraryOnly,
  [string]$OutputPath = 'release/registry/authority-observation.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')

function Assert-SafeProjectedScalar {
  param(
    [Parameter(Mandatory)][string]$Label,
    [AllowNull()][object]$Value,
    [Parameter(Mandatory)][object]$Policy
  )
  if ($null -eq $Value) { return }
  $text = [string]$Value
  foreach ($pattern in @($Policy.observation_policy.forbidden_value_patterns)) {
    if ($text -match [string]$pattern) {
      throw "REGOBS01-UNSAFE-PROJECTION: $Label matches a forbidden secret, header, cookie, or credential-path shape."
    }
  }
  if ($text -match '[\x00-\x1f\x7f]') {
    throw "REGOBS01-UNSAFE-PROJECTION: $Label must be one sanitized scalar."
  }
}

function Get-SanitizedAuthenticationProjection {
  param(
    [Parameter(Mandatory)][string]$Text,
    [Parameter(Mandatory)][int]$ExitCode,
    [Parameter(Mandatory)][object]$Policy
  )
  $projection = [ordered]@{
    session_state = if ($ExitCode -eq 0) { 'safely_observed' } else { 'unknown' }
    session_authenticated = if ($ExitCode -eq 0) { $true } else { $null }
    account_state = 'unknown'
    account_value = $null
    account_source = 'not_observed'
    reason = if ($ExitCode -eq 0) { 'session_authenticated_identity_not_observed' } else { 'authentication_unavailable' }
  }
  if ($ExitCode -ne 0 -or $Text -match '[\x00-\x1f\x7f]') { return $projection }

  $strict = [string]$Policy.observation_policy.username_pattern
  $candidate = $null
  foreach ($pattern in @(
    "^(?i:username)\s*:\s*(?<username>$strict)\s*$",
    "^(?i:logged\s+in\s+as)\s+(?<username>$strict)\s*[.!]?\s*$"
  )) {
    $match = [regex]::Match($Text.Trim(), $pattern)
    if ($match.Success) {
      if ($null -ne $candidate) { return $projection }
      $candidate = $match.Groups['username'].Value
    }
  }
  if ($null -eq $candidate -or @($Policy.observation_policy.reserved_identity_tokens) -ccontains $candidate) { return $projection }

  $projection.account_state = 'safely_observed'
  $projection.account_value = $candidate
  $projection.account_source = 'moon_auth_status'
  $projection.reason = 'authenticated_identity_observed_namespace_authority_unproven'
  return $projection
}

function Get-RegistryStableDigest {
  param([Parameter(Mandatory)][object]$Observation)
  $stable = $Observation | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100
  $stable.PSObject.Properties.Remove('stable_sha256')
  $stable.PSObject.Properties.Remove('run_local')
  # SHA256 is provided by the existing release evidence helper.
  return Get-ReleaseTextSha256 -Text ($stable | ConvertTo-Json -Depth 100 -Compress)
}

function Invoke-OfficialRegistryGet {
  param([Parameter(Mandatory)][uri]$Uri)
  foreach ($attempt in 1..3) {
    try {
      $response = Invoke-WebRequest -Uri $Uri -Method Get -Headers @{ Accept = 'application/json' } -SkipHttpErrorCheck -TimeoutSec 15
      $projectedJson = $null
      try { $projectedJson = $response.Content | ConvertFrom-Json -Depth 20 } catch { }
      return [ordered]@{ status_code = [int]$response.StatusCode; json = $projectedJson }
    } catch {
      if ($attempt -lt 3) { Start-Sleep -Seconds 1 }
    }
  }
  return [ordered]@{ status_code = 0; json = $null }
}

function Assert-ObservationShape {
  param(
    [Parameter(Mandatory)][object]$Observation,
    [Parameter(Mandatory)][object]$Policy
  )
  Assert-ReleaseClosedProperties -Label 'registry authority observation' -Object $Observation -Expected @(
    'schema_version', 'source_commit', 'observed_at_utc', 'credentials_read', 'publication_mutation_performed',
    'command', 'toolchain', 'intended_owner', 'session_authentication', 'authenticated_account', 'namespace_authority', 'facts',
    'sanitized_result', 'freshness', 'stable_sha256', 'run_local'
  )
  Assert-ReleaseClosedProperties -Label 'registry observation command' -Object $Observation.command -Expected @('id', 'arguments')
  $commandPolicy = @($Policy.observation_policy.allowlisted_commands | Where-Object { [string]$_.id -ceq [string]$Observation.command.id })
  if ($commandPolicy.Count -ne 1) { throw 'REGOBS02-COMMAND-NOT-ALLOWLISTED: observation command is not allowlisted.' }
  Assert-ReleaseExactSequence -Label 'registry observation command arguments' -Actual @($Observation.command.arguments) -Expected @($commandPolicy[0].arguments)
  if ($Observation.credentials_read -ne $false -or $Observation.publication_mutation_performed -ne $false) {
    throw 'REGOBS03-CREDENTIAL-OR-MUTATION: collector output must remain credential-free and read-only.'
  }
  foreach ($scalar in @(
    @('authenticated account', $Observation.authenticated_account.value),
    @('result reason', $Observation.sanitized_result.reason),
    @('namespace', $Observation.namespace_authority.namespace)
  )) {
    Assert-SafeProjectedScalar -Label ([string]$scalar[0]) -Value $scalar[1] -Policy $Policy
  }
}

if ($LibraryOnly) { return }

if (-not $CaptureAuthority) {
  throw 'REGOBS04-EXPLICIT-CAPTURE-REQUIRED: pass -CaptureAuthority for the operator-only read-only observation.'
}

$policyPath = Join-Path $repoRoot 'policy\registry-authority.json'
$schemaPath = Join-Path $repoRoot 'release\registry\authority-observation-schema.json'
$policy = Read-ReleaseJson -Path $policyPath
$schema = Read-ReleaseJson -Path $schemaPath
if ($schema.type -cne 'object' -or $schema.additionalProperties -ne $false -or $schema.properties.schema_version.const -cne '1.0.0') {
  throw 'REGOBS05-SCHEMA-NOT-CLOSED: authority observation schema must be a closed 1.0.0 object.'
}

$commandPolicy = @($policy.observation_policy.allowlisted_commands | Where-Object { [string]$_.id -ceq 'moon_auth_status' })
if ($commandPolicy.Count -ne 1) { throw 'REGOBS02-COMMAND-NOT-ALLOWLISTED: moon_auth_status must have one policy entry.' }
$arguments = @($commandPolicy[0].arguments | ForEach-Object { [string]$_ })
Assert-ReleaseExactSequence -Label 'moon auth status command' -Actual $arguments -Expected @('whoami')

$startedUtc = [DateTime]::UtcNow.ToString('o')
$captured = @(& moon @arguments 2>&1 | ForEach-Object { $_.ToString() })
$commandExit = $LASTEXITCODE
$completedUtc = [DateTime]::UtcNow.ToString('o')
$joined = ($captured -join ' ').Trim()

$auth = Get-SanitizedAuthenticationProjection -Text $joined -ExitCode $commandExit -Policy $policy
$accountState = [string]$auth.account_state
$accountValue = $auth.account_value
$accountSource = [string]$auth.account_source
$reason = [string]$auth.reason
Assert-SafeProjectedScalar -Label 'authenticated account' -Value $accountValue -Policy $policy

$owner = [string]$policy.intended_owner
$expectedIdentities = @($policy.module_order | ForEach-Object { [string]$_.identity })
$remoteAccount = Invoke-OfficialRegistryGet -Uri ([uri]"https://mooncakes.io/api/v0/user/$owner")
$remoteAccountExists = (
  $remoteAccount.status_code -eq 200 -and $null -ne $remoteAccount.json -and
  [string]$remoteAccount.json.username -ceq $owner -and
  $null -ne $remoteAccount.json.PSObject.Properties['modules'] -and
  $remoteAccount.json.modules -is [Collections.IEnumerable] -and
  $remoteAccount.json.modules -isnot [string]
)
$manifestAbsent = [Collections.Generic.List[string]]::new()
foreach ($identity in $expectedIdentities) {
  $manifest = Invoke-OfficialRegistryGet -Uri ([uri]"https://mooncakes.io/api/v0/manifest/$identity")
  if ($manifest.status_code -eq 404 -and $null -ne $manifest.json -and
      [string]$manifest.json.detail -ceq 'Package not found') {
    $manifestAbsent.Add($identity)
  }
}
$namespaceEvidenceObserved = (
  $accountState -ceq 'safely_observed' -and [string]$accountValue -ceq $owner -and
  $remoteAccountExists -and $manifestAbsent.Count -eq $expectedIdentities.Count
)
if ($namespaceEvidenceObserved) {
  $reason = 'namespace_identity_observed_current_token_authority_unproven'
}

$head = (& git -C $repoRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $head -cnotmatch '^[0-9a-f]{40}$') { throw 'REGOBS06-SOURCE-COMMIT: unable to bind source commit.' }
$factStates = [ordered]@{
  authenticated_account = $accountState
  namespace_authority = 'unknown'
  canonical_module_identities = 'documented'
  pinned_toolchain = 'documented'
  exact_version_availability = if ($namespaceEvidenceObserved) { 'safely_observed' } else { 'unknown' }
  authenticated_publish_seam = 'unknown'
  registry_observation = if ($remoteAccountExists) { 'safely_observed' } else { 'unknown' }
  registry_resolution = if ($manifestAbsent.Count -eq $expectedIdentities.Count) { 'safely_observed' } else { 'unknown' }
}
$factSources = [ordered]@{
  authenticated_account = if ($accountState -ceq 'safely_observed') { 'moon_auth_status' } else { 'not_observed' }
  namespace_authority = 'not_observed'
  canonical_module_identities = 'personal_namespace_contract'
  pinned_toolchain = 'policy/registry-authority.json'
  exact_version_availability = if ($namespaceEvidenceObserved) { 'official_manifest_absence_0.1.0' } else { 'not_observed' }
  authenticated_publish_seam = 'not_observed'
  registry_observation = if ($remoteAccountExists) { 'official_user_endpoint' } else { 'not_observed' }
  registry_resolution = if ($manifestAbsent.Count -eq $expectedIdentities.Count) { 'official_manifest_endpoints' } else { 'not_observed' }
}
$facts = @($policy.required_current_facts | ForEach-Object {
  $id = [string]$_
  $state = [string]$factStates[$id]
  [ordered]@{
    id = $id
    state = $state
    source = [string]$factSources[$id]
    disposition = if ($state -ceq 'unknown') { 'block_publication' } else { 'allow' }
  }
})

$observation = [ordered]@{
  schema_version = '1.0.0'
  source_commit = $head
  observed_at_utc = $completedUtc
  credentials_read = $false
  publication_mutation_performed = $false
  command = [ordered]@{ id = 'moon_auth_status'; arguments = $arguments }
  toolchain = [ordered]@{
    moon = [string]$policy.pinned_toolchain.moon
    moonc = [string]$policy.pinned_toolchain.moonc
    moonrun = [string]$policy.pinned_toolchain.moonrun
  }
  intended_owner = [string]$policy.intended_owner
  session_authentication = [ordered]@{ state = [string]$auth.session_state; authenticated = $auth.session_authenticated; source = if ($auth.session_state -ceq 'safely_observed') { 'moon_auth_status' } else { 'not_observed' } }
  authenticated_account = [ordered]@{ state = $accountState; value = $accountValue; source = $accountSource }
  namespace_authority = [ordered]@{
    state = 'unknown'
    namespace = $owner
    exact_module_identities = @()
    source = 'not_observed'
  }
  facts = $facts
  sanitized_result = [ordered]@{ outcome = 'unknown'; reason = $reason }
  freshness = [ordered]@{ status = 'current'; max_age_hours = [int]$policy.observation_policy.max_age_hours }
  stable_sha256 = ('0' * 64)
  run_local = [ordered]@{ captured_by = 'operator_collector'; started_utc = $startedUtc; completed_utc = $completedUtc }
}
$observation.stable_sha256 = Get-RegistryStableDigest -Observation $observation
$projectedObservation = $observation | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100
Assert-ObservationShape -Observation $projectedObservation -Policy $policy

$absoluteOutput = if ([IO.Path]::IsPathRooted($OutputPath)) { [IO.Path]::GetFullPath($OutputPath) } else { [IO.Path]::GetFullPath((Join-Path $repoRoot $OutputPath)) }
$parent = Split-Path -Parent $absoluteOutput
if (-not (Test-Path -LiteralPath $parent -PathType Container)) { $null = New-Item -ItemType Directory -Force -Path $parent }
$temporary = Join-Path $parent ('.registry-observation-' + [Guid]::NewGuid().ToString('N') + '.tmp')
try {
  [IO.File]::WriteAllText($temporary, (($observation | ConvertTo-Json -Depth 100) + "`n"), [Text.UTF8Encoding]::new($false))
  Move-Item -LiteralPath $temporary -Destination $absoluteOutput -Force
} finally {
  if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
}

Write-Host "Registry observation written with outcome '$($observation.sanitized_result.outcome)' and no raw command output."
if (@($observation.facts | Where-Object { [string]$_.state -ceq 'unknown' }).Count -ne 0) { exit 3 }
