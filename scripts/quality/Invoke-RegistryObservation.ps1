[CmdletBinding()]
param(
  [switch]$CaptureAuthority,
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
  if ($text -match '[\r\n]') {
    throw "REGOBS01-UNSAFE-PROJECTION: $Label must be one sanitized scalar."
  }
}

function Get-RegistryStableDigest {
  param([Parameter(Mandatory)][object]$Observation)
  $stable = $Observation | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100
  $stable.PSObject.Properties.Remove('stable_sha256')
  $stable.PSObject.Properties.Remove('run_local')
  # SHA256 is provided by the existing release evidence helper.
  return Get-ReleaseTextSha256 -Text ($stable | ConvertTo-Json -Depth 100 -Compress)
}

function Assert-ObservationShape {
  param(
    [Parameter(Mandatory)][object]$Observation,
    [Parameter(Mandatory)][object]$Policy
  )
  Assert-ReleaseClosedProperties -Label 'registry authority observation' -Object $Observation -Expected @(
    'schema_version', 'source_commit', 'observed_at_utc', 'credentials_read', 'publication_mutation_performed',
    'command', 'toolchain', 'intended_owner', 'authenticated_account', 'namespace_authority', 'facts',
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

$accountState = 'unknown'
$accountValue = $null
$accountSource = 'not_observed'
$reason = 'authentication_unavailable'
if ($commandExit -eq 0) {
  $match = [regex]::Match($joined, '(?i)(?:logged\s+in\s+as\s+|username\s*:\s*)?([a-z0-9](?:[a-z0-9._-]{0,98}[a-z0-9])?)\.?$')
  if ($match.Success) {
    $accountState = 'safely_observed'
    $accountValue = $match.Groups[1].Value
    $accountSource = 'moon_auth_status'
    $reason = 'authenticated_identity_observed_namespace_authority_unproven'
  } else {
    $reason = 'authenticated_identity_output_ambiguous'
  }
}
Assert-SafeProjectedScalar -Label 'authenticated account' -Value $accountValue -Policy $policy

$head = (& git -C $repoRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $head -cnotmatch '^[0-9a-f]{40}$') { throw 'REGOBS06-SOURCE-COMMIT: unable to bind source commit.' }
$factStates = [ordered]@{
  authenticated_account = $accountState
  namespace_authority = 'unknown'
  canonical_module_identities = 'unknown'
  pinned_toolchain = 'documented'
  exact_version_availability = 'unknown'
  authenticated_publish_seam = 'unknown'
  registry_observation = 'unknown'
  registry_resolution = 'unknown'
}
$facts = @($policy.required_current_facts | ForEach-Object {
  $id = [string]$_
  $state = [string]$factStates[$id]
  [ordered]@{
    id = $id
    state = $state
    source = if ($id -ceq 'pinned_toolchain') { 'policy/registry-authority.json' } elseif ($id -ceq 'authenticated_account' -and $state -ceq 'safely_observed') { 'moon_auth_status' } else { 'not_observed' }
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
  authenticated_account = [ordered]@{ state = $accountState; value = $accountValue; source = $accountSource }
  namespace_authority = [ordered]@{
    state = 'unknown'
    namespace = [string]$policy.intended_owner
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
if ($observation.namespace_authority.state -cne 'safely_observed') { exit 3 }
