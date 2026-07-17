[CmdletBinding()]
param(
  [string]$PolicyPath,
  [string]$ObservationPath,
  [string]$CapabilityPath,
  [switch]$AssertPublishReady
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')

function Fail-RegistryRule {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][string]$Message)
  throw "$Id`: $Message"
}

function Assert-RegistryClosed {
  param([string]$Label, [object]$Value, [string[]]$Expected, [string]$Rule)
  try { Assert-ReleaseClosedProperties -Label $Label -Object $Value -Expected $Expected } catch {
    Fail-RegistryRule -Id $Rule -Message $_.Exception.Message
  }
}

function Assert-RegistrySequence {
  param([string]$Label, [object[]]$Actual, [object[]]$Expected, [string]$Rule)
  try { Assert-ReleaseExactSequence -Label $Label -Actual $Actual -Expected $Expected } catch {
    Fail-RegistryRule -Id $Rule -Message $_.Exception.Message
  }
}

function Get-RegistryStableDigest {
  param([Parameter(Mandatory)][object]$Value)
  $stable = $Value | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100
  $stable.PSObject.Properties.Remove('stable_sha256')
  $stable.PSObject.Properties.Remove('run_local')
  return Get-ReleaseTextSha256 -Text ($stable | ConvertTo-Json -Depth 100 -Compress)
}

function Assert-NoUnsafeRegistryValue {
  param([Parameter(Mandatory)][object]$Value, [Parameter(Mandatory)][object]$Policy)
  $unsafe = [Collections.Generic.List[string]]::new()
  function Visit-RegistryValue([object]$Current, [string]$At) {
    if ($null -eq $Current) { return }
    if ($Current -is [string]) {
      if ([string]$Current -match '[\x00-\x1f\x7f]') { $unsafe.Add($At); return }
      foreach ($pattern in @($Policy.observation_policy.forbidden_value_patterns)) {
        if ([string]$Current -match [string]$pattern) { $unsafe.Add($At); break }
      }
      return
    }
    if ($Current -is [ValueType]) { return }
    if ($Current -is [Collections.IEnumerable] -and $Current -isnot [Management.Automation.PSCustomObject]) {
      $index = 0
      foreach ($item in $Current) { Visit-RegistryValue -Current $item -At "$At[$index]"; $index++ }
      return
    }
    foreach ($property in @($Current.PSObject.Properties)) {
      Visit-RegistryValue -Current $property.Value -At "$At.$($property.Name)"
    }
  }
  Visit-RegistryValue -Current $Value -At '$'
  if ($unsafe.Count -ne 0) {
    Fail-RegistryRule -Id 'REG01-UNSAFE-EVIDENCE' -Message "observation contains a forbidden secret, header, cookie, or credential-path shape at $($unsafe[0])."
  }
}

if ([string]::IsNullOrWhiteSpace($PolicyPath)) { $PolicyPath = Join-Path $repoRoot 'policy\registry-authority.json' }
if ([string]::IsNullOrWhiteSpace($ObservationPath)) { $ObservationPath = Join-Path $repoRoot 'release\registry\authority-observation.json' }
if ([string]::IsNullOrWhiteSpace($CapabilityPath)) { $CapabilityPath = Join-Path $repoRoot 'release\registry\capability-matrix.json' }

$policy = Read-ReleaseJson -Path $PolicyPath
$observation = Read-ReleaseJson -Path $ObservationPath
$observationRaw = Get-Content -LiteralPath $ObservationPath -Raw
$matrix = Read-ReleaseJson -Path $CapabilityPath
$observationSchema = Read-ReleaseJson -Path (Join-Path $repoRoot 'release\registry\authority-observation-schema.json')
$matrixSchema = Read-ReleaseJson -Path (Join-Path $repoRoot 'release\registry\capability-matrix-schema.json')

Assert-RegistryClosed 'registry authority policy' $policy @(
  'schema_version', 'intended_owner', 'module_order', 'pinned_toolchain', 'required_current_facts',
  'observation_policy', 'capability_order', 'publication_readiness'
) 'REG01-CLOSED-CONTRACT'
Assert-RegistryClosed 'authority observation' $observation @(
  'schema_version', 'source_commit', 'observed_at_utc', 'credentials_read', 'publication_mutation_performed',
  'command', 'toolchain', 'intended_owner', 'session_authentication', 'authenticated_account', 'namespace_authority', 'facts',
  'sanitized_result', 'freshness', 'stable_sha256', 'run_local'
) 'REG01-CLOSED-CONTRACT'
Assert-RegistryClosed 'capability matrix' $matrix @(
  'schema_version', 'source_commit', 'observed_at_utc', 'capabilities', 'stable_sha256', 'run_local'
) 'REG02-CAPABILITY-CLOSED'
foreach ($schema in @($observationSchema, $matrixSchema)) {
  if ($schema.type -cne 'object' -or $schema.additionalProperties -ne $false -or $schema.properties.schema_version.const -cne '1.0.0') {
    Fail-RegistryRule -Id 'REG01-CLOSED-CONTRACT' -Message 'registry schemas must be closed 1.0.0 objects.'
  }
}
if ($policy.schema_version -cne '1.0.0' -or $observation.schema_version -cne '1.0.0' -or $matrix.schema_version -cne '1.0.0') {
  Fail-RegistryRule -Id 'REG01-CLOSED-CONTRACT' -Message 'registry contract version drifted.'
}

$expectedModules = @('mb-core', 'mb-color', 'mb-image')
$expectedIdentities = @('tchivs/mb-core', 'tchivs/mb-color', 'tchivs/mb-image')
$expectedVersions = @('0.1.0', '0.1.0', '0.1.0')
Assert-RegistrySequence 'registry module order' @($policy.module_order.module) $expectedModules 'REG01-IDENTITY'
Assert-RegistrySequence 'registry module identities' @($policy.module_order.identity) $expectedIdentities 'REG01-IDENTITY'
Assert-RegistrySequence 'registry module versions' @($policy.module_order.version) $expectedVersions 'REG01-IDENTITY'
foreach ($module in @($policy.module_order)) {
  Assert-RegistryClosed "registry module $($module.module)" $module @('module', 'identity', 'version') 'REG01-CLOSED-CONTRACT'
}
if ($policy.intended_owner -cne 'tchivs' -or $observation.intended_owner -cne $policy.intended_owner -or
    $observation.namespace_authority.namespace -cne $policy.intended_owner) {
  Fail-RegistryRule -Id 'REG01-IDENTITY' -Message 'intended owner or namespace identity drifted.'
}

Assert-RegistryClosed 'pinned toolchain policy' $policy.pinned_toolchain @('moon', 'moonc', 'moonrun') 'REG01-TOOLCHAIN'
Assert-RegistryClosed 'observed toolchain' $observation.toolchain @('moon', 'moonc', 'moonrun') 'REG01-TOOLCHAIN'
foreach ($tool in @('moon', 'moonc', 'moonrun')) {
  if ([string]$observation.toolchain.$tool -cne [string]$policy.pinned_toolchain.$tool) {
    Fail-RegistryRule -Id 'REG01-TOOLCHAIN' -Message "observed $tool version differs from pinned policy."
  }
}

Assert-RegistryClosed 'observation policy' $policy.observation_policy @('max_age_hours', 'username_pattern', 'reserved_identity_tokens', 'states', 'dispositions', 'allowlisted_commands', 'forbidden_value_patterns') 'REG01-CLOSED-CONTRACT'
Assert-RegistryClosed 'observation command' $observation.command @('id', 'arguments') 'REG01-CLOSED-CONTRACT'
$command = @($policy.observation_policy.allowlisted_commands | Where-Object { [string]$_.id -ceq [string]$observation.command.id })
if ($command.Count -ne 1) { Fail-RegistryRule -Id 'REG01-COMMAND-SHAPE' -Message 'observation command ID is not allowlisted.' }
Assert-RegistrySequence 'observation command arguments' @($observation.command.arguments) @($command[0].arguments) 'REG01-COMMAND-SHAPE'
if ($observation.credentials_read -ne $false -or $observation.publication_mutation_performed -ne $false) {
  Fail-RegistryRule -Id 'REG01-UNSAFE-EVIDENCE' -Message 'observation claims credential access or registry mutation.'
}
Assert-NoUnsafeRegistryValue -Value $observation -Policy $policy

Assert-RegistryClosed 'session authentication' $observation.session_authentication @('state', 'authenticated', 'source') 'REG01-CLOSED-CONTRACT'
Assert-RegistryClosed 'authenticated account' $observation.authenticated_account @('state', 'value', 'source') 'REG01-CLOSED-CONTRACT'
Assert-RegistryClosed 'namespace authority' $observation.namespace_authority @('state', 'namespace', 'exact_module_identities', 'source') 'REG01-CLOSED-CONTRACT'
Assert-RegistryClosed 'sanitized result' $observation.sanitized_result @('outcome', 'reason') 'REG01-CLOSED-CONTRACT'
Assert-RegistryClosed 'freshness' $observation.freshness @('status', 'max_age_hours') 'REG01-CLOSED-CONTRACT'
Assert-RegistryClosed 'observation run-local' $observation.run_local @('captured_by', 'started_utc', 'completed_utc') 'REG01-CLOSED-CONTRACT'
if (@('safely_observed', 'unknown') -cnotcontains [string]$observation.session_authentication.state -or
    @('safely_observed', 'unknown') -cnotcontains [string]$observation.authenticated_account.state -or
    @('safely_observed', 'unknown') -cnotcontains [string]$observation.namespace_authority.state -or
    @('safely_observed', 'unknown') -cnotcontains [string]$observation.sanitized_result.outcome) {
  Fail-RegistryRule -Id 'REG01-STATE' -Message 'authority observation contains an unsupported state.'
}
if ($observation.session_authentication.state -ceq 'unknown' -and ($null -ne $observation.session_authentication.authenticated -or $observation.session_authentication.source -cne 'not_observed')) {
  Fail-RegistryRule -Id 'REG01-STATE' -Message 'unknown session authentication must not carry an authenticated result.'
}
if ($observation.session_authentication.state -ceq 'safely_observed' -and ($observation.session_authentication.authenticated -ne $true -or $observation.session_authentication.source -cne 'moon_auth_status')) {
  Fail-RegistryRule -Id 'REG01-STATE' -Message 'observed session authentication must be a true moon_auth_status result.'
}
if ($observation.authenticated_account.state -ceq 'unknown' -and $null -ne $observation.authenticated_account.value) {
  Fail-RegistryRule -Id 'REG01-STATE' -Message 'unknown authenticated account must not carry a value.'
}
if ($observation.authenticated_account.state -ceq 'safely_observed') {
  $accountValue = [string]$observation.authenticated_account.value
  if ($accountValue -cnotmatch ('^' + [string]$policy.observation_policy.username_pattern + '$') -or
      @($policy.observation_policy.reserved_identity_tokens) -ccontains $accountValue) {
    Fail-RegistryRule -Id 'REG01-IDENTITY-TOKEN' -Message 'authenticated account is not a strict non-status username token.'
  }
}
if ($observation.namespace_authority.state -ceq 'unknown' -and @($observation.namespace_authority.exact_module_identities).Count -ne 0) {
  Fail-RegistryRule -Id 'REG01-STATE' -Message 'unknown namespace authority must not carry module authorization.'
}
if ([string]$observation.authenticated_account.source -cmatch '(?i)github' -or
    [string]$observation.namespace_authority.source -cmatch '(?i)github') {
  Fail-RegistryRule -Id 'REG01-MOONCAKES-AUTHORITY' -Message 'GitHub identity is repository metadata and cannot prove Mooncakes account or namespace authority.'
}
if ($observation.namespace_authority.state -ceq 'safely_observed') {
  if ($observation.authenticated_account.state -cne 'safely_observed' -or
      [string]$observation.authenticated_account.value -cne [string]$policy.intended_owner) {
    Fail-RegistryRule -Id 'REG01-MOONCAKES-AUTHORITY' -Message 'namespace authority requires the exact safely observed Mooncakes account.'
  }
  Assert-RegistrySequence 'observed namespace module identities' @($observation.namespace_authority.exact_module_identities) $expectedIdentities 'REG01-MOONCAKES-AUTHORITY'
}

Assert-RegistrySequence 'required authority fact order' @($observation.facts.id) @($policy.required_current_facts) 'REG01-FACT-ORDER'
foreach ($fact in @($observation.facts)) {
  Assert-RegistryClosed "authority fact $($fact.id)" $fact @('id', 'state', 'source', 'disposition') 'REG01-FACT-CLOSED'
  if (@($policy.observation_policy.states) -cnotcontains [string]$fact.state) {
    Fail-RegistryRule -Id 'REG01-STATE' -Message "fact '$($fact.id)' has an unsupported state."
  }
  if (@($policy.observation_policy.dispositions) -cnotcontains [string]$fact.disposition) {
    Fail-RegistryRule -Id 'REG03-REQUIRED-UNKNOWN-DISPOSITION' -Message "fact '$($fact.id)' has an unsupported disposition."
  }
  if ($fact.state -ceq 'unknown' -and $fact.disposition -cne 'block_publication') {
    Fail-RegistryRule -Id 'REG03-REQUIRED-UNKNOWN-DISPOSITION' -Message "required unknown fact '$($fact.id)' must block publication."
  }
}

if ($null -eq $observation.observed_at_utc) {
  if ($observation.freshness.status -cne 'not_observed') {
    Fail-RegistryRule -Id 'REG01-FRESHNESS' -Message 'missing observation time must be not_observed.'
  }
} else {
  if ($observationRaw -cnotmatch '"observed_at_utc"\s*:\s*"[^"]+Z"') {
    Fail-RegistryRule -Id 'REG01-FRESHNESS' -Message 'observation timestamp must use the UTC Z suffix.'
  }
  try { $observedAt = ([DateTimeOffset]$observation.observed_at_utc).ToUniversalTime() } catch {
    Fail-RegistryRule -Id 'REG01-FRESHNESS' -Message 'observation timestamp is not a valid UTC instant.'
  }
  $age = [DateTimeOffset]::UtcNow - $observedAt
  if ($age.TotalMinutes -lt -5 -or $age.TotalHours -gt [double]$policy.observation_policy.max_age_hours -or $observation.freshness.status -cne 'current') {
    Fail-RegistryRule -Id 'REG01-FRESHNESS' -Message 'authority evidence is stale, future-dated, or not marked current.'
  }
}
if ([int]$observation.freshness.max_age_hours -ne [int]$policy.observation_policy.max_age_hours) {
  Fail-RegistryRule -Id 'REG01-FRESHNESS' -Message 'freshness threshold drifted from policy.'
}

if ([string]$observation.run_local.captured_by -ceq 'tracked_seed') {
  $trackedSeedOverclaim = (
    $null -ne $observation.observed_at_utc -or
    [string]$observation.command.id -cne 'none' -or @($observation.command.arguments).Count -ne 0 -or
    [string]$observation.session_authentication.state -cne 'unknown' -or $null -ne $observation.session_authentication.authenticated -or [string]$observation.session_authentication.source -cne 'not_observed' -or
    [string]$observation.authenticated_account.state -cne 'unknown' -or $null -ne $observation.authenticated_account.value -or [string]$observation.authenticated_account.source -cne 'not_observed' -or
    [string]$observation.namespace_authority.state -cne 'unknown' -or @($observation.namespace_authority.exact_module_identities).Count -ne 0 -or [string]$observation.namespace_authority.source -cne 'not_observed' -or
    [string]$observation.sanitized_result.outcome -cne 'unknown' -or [string]$observation.sanitized_result.reason -cne 'authority_not_observed' -or
    [string]$observation.freshness.status -cne 'not_observed' -or $null -ne $observation.run_local.started_utc -or $null -ne $observation.run_local.completed_utc
  )
  if ($trackedSeedOverclaim) {
    Fail-RegistryRule -Id 'REG01-TRACKED-SEED-OVERCLAIM' -Message 'tracked seed cannot fabricate account, namespace, module, command, timestamp, or freshness evidence.'
  }
  foreach ($fact in @($observation.facts)) {
    $isPinnedToolchain = [string]$fact.id -ceq 'pinned_toolchain'
    $validTrackedFact = if ($isPinnedToolchain) {
      [string]$fact.state -ceq 'documented' -and [string]$fact.source -ceq 'policy/registry-authority.json' -and [string]$fact.disposition -ceq 'allow'
    } else {
      [string]$fact.state -ceq 'unknown' -and [string]$fact.source -ceq 'not_observed' -and [string]$fact.disposition -ceq 'block_publication'
    }
    if (-not $validTrackedFact) {
      Fail-RegistryRule -Id 'REG01-TRACKED-SEED-OVERCLAIM' -Message "tracked seed fact '$($fact.id)' is not exact unknown-first evidence."
    }
  }
}

Assert-RegistrySequence 'capability order' @($matrix.capabilities.id) @($policy.capability_order) 'REG02-CAPABILITY-ORDER'
foreach ($capability in @($matrix.capabilities)) {
  Assert-RegistryClosed "capability $($capability.id)" $capability @('id', 'state', 'source', 'required_for_publish', 'disposition') 'REG02-CAPABILITY-CLOSED'
  Assert-RegistryClosed "capability source $($capability.id)" $capability.source @('kind', 'reference') 'REG02-CAPABILITY-CLOSED'
  if (@($policy.observation_policy.states) -cnotcontains [string]$capability.state) {
    Fail-RegistryRule -Id 'REG02-CAPABILITY-STATE' -Message "capability '$($capability.id)' has an unsupported state."
  }
  if (@($policy.observation_policy.dispositions) -cnotcontains [string]$capability.disposition) {
    Fail-RegistryRule -Id 'REG02-CAPABILITY-DISPOSITION' -Message "capability '$($capability.id)' has an unsupported disposition."
  }
  if ($capability.state -ceq 'unknown' -and $capability.disposition -ceq 'allow') {
    Fail-RegistryRule -Id 'REG02-CAPABILITY-DISPOSITION' -Message "unknown capability '$($capability.id)' cannot allow publication."
  }
  if ($capability.state -ceq 'unknown' -and $capability.required_for_publish -eq $true -and $capability.disposition -cne 'block_publication') {
    Fail-RegistryRule -Id 'REG02-CAPABILITY-DISPOSITION' -Message "required unknown capability '$($capability.id)' must block publication."
  }
}

$destructiveRecovery = @($matrix.capabilities | Where-Object { [string]$_.id -ceq 'destructive_recovery' })
if ($destructiveRecovery.Count -ne 1 -or [string]$destructiveRecovery[0].state -cne 'unknown' -or
    [string]$destructiveRecovery[0].source.kind -cne 'not_observed' -or
    $destructiveRecovery[0].required_for_publish -ne $false -or
    [string]$destructiveRecovery[0].disposition -cne 'forward_only_recovery') {
  Fail-RegistryRule -Id 'REG02-FORWARD-ONLY-RECOVERY' -Message 'rename, transfer, overwrite, delete, unpublish, and yank remain unobserved and cannot replace forward-only recovery.'
}

$intendedRepository = 'https://github.com/tchivs/moonbit-foundation'
$supportText = Get-Content -LiteralPath (Join-Path $repoRoot 'docs\support.md') -Raw
$securityText = Get-Content -LiteralPath (Join-Path $repoRoot 'SECURITY.md') -Raw
foreach ($route in @(
  [pscustomobject]@{ label = 'support'; text = $supportText },
  [pscustomobject]@{ label = 'security'; text = $securityText }
)) {
  if (-not $route.text.Contains($intendedRepository, [StringComparison]::Ordinal) -or
      $route.text -cnotmatch '(?i)\bunverified\b' -or $route.text -cnotmatch '(?i)\bnot operational\b' -or
      $route.text -cnotmatch '(?i)read-only.+existence proof' -or
      $route.text -cmatch 'https://github[.]com/tchivs/moonbit-foundation/(?:issues/new|security/advisories/new)') {
    Fail-RegistryRule -Id 'REG01-REPOSITORY-LIVENESS' -Message "$($route.label) route must keep intended repository metadata distinct from verified-live reporting infrastructure."
  }
}
$projectText = Get-Content -LiteralPath (Join-Path $repoRoot 'README.md') -Raw
foreach ($term in @('rename', 'transfer', 'overwrite', 'delete', 'unpublish', 'yank')) {
  if ($projectText -cnotmatch ('(?i)does not assume[^\r\n]+' + [regex]::Escape($term))) {
    Fail-RegistryRule -Id 'REG02-FORWARD-ONLY-RECOVERY' -Message "project policy omits forward-only '$term' recovery semantics."
  }
}

if ([string]$observation.stable_sha256 -cne (Get-RegistryStableDigest -Value $observation)) {
  Fail-RegistryRule -Id 'REG01-STABLE-DIGEST' -Message 'authority observation stable SHA-256 is invalid.'
}
if ([string]$matrix.stable_sha256 -cne (Get-RegistryStableDigest -Value $matrix)) {
  Fail-RegistryRule -Id 'REG02-STABLE-DIGEST' -Message 'capability matrix stable SHA-256 is invalid.'
}

if ($AssertPublishReady) {
  $unknownFacts = @($observation.facts | Where-Object { [string]$_.state -ceq 'unknown' })
  $unknownRequiredCapabilities = @($matrix.capabilities | Where-Object { $_.required_for_publish -eq $true -and [string]$_.state -ceq 'unknown' })
  if ($unknownFacts.Count -ne 0 -or $unknownRequiredCapabilities.Count -ne 0) {
    Fail-RegistryRule -Id 'REG03-REQUIRED-FACT-UNKNOWN' -Message 'publication readiness requires every required current fact and capability to be known.'
  }
  if ($observation.session_authentication.state -cne 'safely_observed' -or $observation.session_authentication.authenticated -ne $true -or
      $observation.authenticated_account.state -cne 'safely_observed' -or [string]::IsNullOrWhiteSpace([string]$observation.authenticated_account.value)) {
    Fail-RegistryRule -Id 'REG01-AUTHENTICATED-ACCOUNT' -Message 'authenticated account identity is not safely observed.'
  }
  if ($observation.namespace_authority.state -cne 'safely_observed') {
    Fail-RegistryRule -Id 'REG01-NAMESPACE-AUTHORITY' -Message 'account authentication does not prove namespace authorization.'
  }
  Assert-RegistrySequence 'authorized module identities' @($observation.namespace_authority.exact_module_identities) $expectedIdentities 'REG01-NAMESPACE-AUTHORITY'
  if ($observation.sanitized_result.outcome -cne 'safely_observed' -or $observation.freshness.status -cne 'current') {
    Fail-RegistryRule -Id 'REG01-NAMESPACE-AUTHORITY' -Message 'authority proof is not a fresh safely observed result.'
  }
}

Write-Host "Registry authority contract passed (publish-ready assertion: $([bool]$AssertPublishReady))."
