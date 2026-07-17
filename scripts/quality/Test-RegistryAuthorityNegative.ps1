[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$validator = Join-Path $PSScriptRoot 'Test-RegistryAuthority.ps1'
$policyPath = Join-Path $repoRoot 'policy\registry-authority.json'
$observationPath = Join-Path $repoRoot 'release\registry\authority-observation.json'
$capabilityPath = Join-Path $repoRoot 'release\registry\capability-matrix.json'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-registry-negative-' + [Guid]::NewGuid().ToString('N'))
. (Join-Path $PSScriptRoot 'Invoke-RegistryObservation.ps1') -LibraryOnly
$parserPolicy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json -Depth 100

function Write-NegativeJson {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][object]$Value)
  [IO.File]::WriteAllText($Path, (($Value | ConvertTo-Json -Depth 100) + "`n"), [Text.UTF8Encoding]::new($false))
}

function Confirm-ExactRule {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][scriptblock]$Action)
  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure -or -not $failure.StartsWith("$Id`: ", [StringComparison]::Ordinal)) {
    throw "Negative '$Id' passed or failed for the wrong reason: '$failure'."
  }
  Write-Host "Registry negative rejected: $Id"
}

function Confirm-IdentityRejected {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][string]$Text)
  $projection = Get-SanitizedAuthenticationProjection -Text $Text -ExitCode 0 -Policy $parserPolicy
  if ($projection.session_state -cne 'safely_observed' -or $projection.session_authenticated -ne $true -or
      $projection.account_state -cne 'unknown' -or $null -ne $projection.account_value) {
    throw "$Id`: status-only, ambiguous, reserved, or control-tainted output was accepted as account identity."
  }
  Write-Host "Registry identity projection rejected: $Id"
}

function New-NegativeFiles {
  param([scriptblock]$MutateObservation, [scriptblock]$MutateCapability)
  $observation = Get-Content -LiteralPath $observationPath -Raw | ConvertFrom-Json -Depth 100
  $capability = Get-Content -LiteralPath $capabilityPath -Raw | ConvertFrom-Json -Depth 100
  if ($null -ne $MutateObservation) { & $MutateObservation $observation }
  if ($null -ne $MutateCapability) { & $MutateCapability $capability }
  $id = [Guid]::NewGuid().ToString('N')
  $observationOut = Join-Path $tempRoot "$id.observation.json"
  $capabilityOut = Join-Path $tempRoot "$id.capability.json"
  Write-NegativeJson -Path $observationOut -Value $observation
  Write-NegativeJson -Path $capabilityOut -Value $capability
  return @($observationOut, $capabilityOut)
}

$null = New-Item -ItemType Directory -Force -Path $tempRoot
try {
  Confirm-IdentityRejected 'REGOBS07-STATUS-ONLY-IDENTITY' 'Already logged in.'
  Confirm-IdentityRejected 'REGOBS08-AMBIGUOUS-IDENTITY' 'Logged in already; identity unavailable'
  Confirm-IdentityRejected 'REGOBS09-ANSI-TAINTED-IDENTITY' ("Username: " + [char]27 + '[32mmoonbit-foundation')
  Confirm-IdentityRejected 'REGOBS10-RESERVED-IN' 'Username: in'
  Confirm-IdentityRejected 'REGOBS11-RESERVED-LOGGED' 'Username: logged'
  Confirm-IdentityRejected 'REGOBS12-RESERVED-ALREADY' 'Logged in as already'
  Confirm-IdentityRejected 'REGOBS13-NONCANONICAL-CASE' 'Username: MoonBit-Foundation'
  $cases = @(
    @{ id = 'REG01-FACT-ORDER'; observation = { param($o) $o.facts = @($o.facts | Select-Object -SkipLast 1) }; capability = $null },
    @{ id = 'REG01-FACT-ORDER'; observation = { param($o) $o.facts += [pscustomobject]@{ id='authenticated_account'; state='unknown'; source='not_observed'; disposition='block_publication' } }; capability = $null },
    @{ id = 'REG01-CLOSED-CONTRACT'; observation = { param($o) $o | Add-Member -NotePropertyName unexpected -NotePropertyValue 'field' }; capability = $null },
    @{ id = 'REG01-IDENTITY'; observation = { param($o) $o.intended_owner = 'MoonBit-Foundation' }; capability = $null },
    @{ id = 'REG01-IDENTITY'; observation = { param($o) $o.intended_owner = ('moonbit' + '-foundation') }; capability = $null },
    @{ id = 'REG01-MOONCAKES-AUTHORITY'; observation = {
      param($o)
      $o.session_authentication = [pscustomobject]@{ state='safely_observed'; authenticated=$true; source='moon_auth_status' }
      $o.authenticated_account = [pscustomobject]@{ state='safely_observed'; value='tchivs'; source='github_identity' }
      $o.namespace_authority = [pscustomobject]@{ state='safely_observed'; namespace='tchivs'; exact_module_identities=@('tchivs/mb-core','tchivs/mb-color','tchivs/mb-image'); source='github_identity' }
    }; capability = $null },
    @{ id = 'REG01-MOONCAKES-AUTHORITY'; observation = {
      param($o)
      $o.authenticated_account = [pscustomobject]@{ state='unknown'; value=$null; source='not_observed' }
      $o.namespace_authority = [pscustomobject]@{ state='safely_observed'; namespace='tchivs'; exact_module_identities=@('tchivs/mb-core','tchivs/mb-color','tchivs/mb-image'); source='authenticated_read_only_registry' }
    }; capability = $null },
    @{ id = 'REG01-FRESHNESS'; observation = { param($o) $o.observed_at_utc = [DateTimeOffset]::UtcNow.AddHours(-25).ToString('o'); $o.freshness.status = 'stale' }; capability = $null },
    @{ id = 'REG01-STABLE-DIGEST'; observation = { param($o) $o.stable_sha256 = ('0' * 64) }; capability = $null },
    @{ id = 'REG01-UNSAFE-EVIDENCE'; observation = { param($o) $o.sanitized_result.reason = 'Authorization: Bearer redacted' }; capability = $null },
    @{ id = 'REG01-UNSAFE-EVIDENCE'; observation = { param($o) $o.sanitized_result.reason = 'cookie=redacted' }; capability = $null },
    @{ id = 'REG01-UNSAFE-EVIDENCE'; observation = { param($o) $o.sanitized_result.reason = 'C:\Users\operator\credentials.json' }; capability = $null },
    @{ id = 'REG01-UNSAFE-EVIDENCE'; observation = { param($o) $o.authenticated_account.value = ([char]27 + '[32mmoonbit-foundation') }; capability = $null },
    @{ id = 'REG02-CAPABILITY-STATE'; observation = $null; capability = { param($m) $m.capabilities[0].state = 'assumed' } },
    @{ id = 'REG03-REQUIRED-UNKNOWN-DISPOSITION'; observation = {
      param($o)
      $o.facts[1].state = 'unknown'
      $o.facts[1].source = 'not_observed'
      $o.facts[1].disposition = 'allow'
    }; capability = $null },
    @{ id = 'REG02-CAPABILITY-CLOSED'; observation = $null; capability = { param($m) $m.capabilities[5].PSObject.Properties.Remove('disposition') } }
  )
  foreach ($case in $cases) {
    Confirm-ExactRule -Id $case.id -Action {
      $paths = New-NegativeFiles -MutateObservation $case.observation -MutateCapability $case.capability
      & $validator -PolicyPath $policyPath -ObservationPath $paths[0] -CapabilityPath $paths[1]
    }
  }
  Write-Host 'Registry authority negative matrix passed with exact fail-closed rule ownership.'
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $full = [IO.Path]::GetFullPath($tempRoot)
    if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Split-Path -Leaf $full).StartsWith('mnf-registry-negative-', [StringComparison]::Ordinal)) {
      throw "Refusing to remove unverified registry negative path: $full"
    }
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}
