[CmdletBinding()]
param(
  [switch]$WorkflowOnly,
  [switch]$LedgerOnly,
  [switch]$Focused,
  [string]$ReportPath,
  [switch]$HostedSettings
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Assert-P07Workflow {
  $path=Join-Path $repoRoot '.github/workflows/publish-modules.yml'
  $schemaPath=Join-Path $repoRoot 'release/prepared/schema.json'
  $text=Get-Content -LiteralPath $path -Raw
  $schema=Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json -Depth 100
  if ($schema.type -cne 'object' -or $schema.additionalProperties -ne $false -or $schema.properties.schema_version.const -cne 'mnf-release-prepared/1') { throw 'P07-WORKFLOW-SCHEMA: prepared schema is not closed.' }
  foreach ($required in @(
    'workflow_dispatch:','permissions: {}','group: mnf-release-${{ github.repository }}-${{ inputs.root_intent_sha256 }}',
    'cancel-in-progress: false','contents: read','actions: read','persist-credentials: false',
    'root_intent_sha256:','intent_sha256:','prior_run_id:','prior_artifact_name:',
    'run-id: ${{ github.run_id }}','needs.prepare.outputs.prepared_artifact_name',
    'needs.prepare.outputs.prepared_manifest_sha256','environment: mooncakes-production',
    'P07-WORKFLOW-INITIAL-ROOT','P07-WORKFLOW-CORRECTION-RESUME','P07-WORKFLOW-MANIFEST-DIGEST',
    'P07-WORKFLOW-EXACT-INVENTORY','P07-WORKFLOW-PAYLOAD-DIGEST','P07-WORKFLOW-BINDING'
  )) { if (-not $text.Contains($required)) { throw "P07-WORKFLOW-STRUCTURE: missing '$required'." } }
  $uses=@([regex]::Matches($text,'(?m)^\s*uses:\s*[^@\r\n]+@([0-9a-f]{40})\s*$'))
  if ($uses.Count -lt 6) { throw 'P07-WORKFLOW-ACTION-PIN: action coverage is incomplete.' }
  if (@([regex]::Matches($text,'secrets[.]MOONCAKES_TOKEN')).Count -ne 1) { throw 'P07-WORKFLOW-SECRET: Mooncakes secret must occur exactly once.' }
  $publisher=$text.Substring($text.IndexOf('  publisher:',[StringComparison]::Ordinal))
  if ($publisher.Contains('actions/checkout@') -or -not [regex]::IsMatch($publisher,'permissions:\s*\r?\n\s+actions: read')) { throw 'P07-WORKFLOW-PUBLISHER-PERMISSIONS: publisher privilege drifted.' }
  Write-Host 'Phase 7 workflow/schema static contract passed.'
}

function Assert-P07Ledger {
  $path=Join-Path $repoRoot 'release/qualification/phase-07-requirements.json'
  $ledger=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -Depth 100
  $expected=@('schema_version','phase','required_entrypoint','requirement_order','selectors','requirements','artifact_contracts','edge_probes','prohibitions','evidence','phase_08_handoff')
  if ((@($ledger.PSObject.Properties.Name) -join ',') -cne ($expected -join ',')) { throw 'P07-LEDGER-CLOSED: top-level contract drifted.' }
  if ((@($ledger.requirement_order) -join ',') -cne 'REL-01,REL-02,REL-03,REL-04,REL-05') { throw 'P07-LEDGER-ORDER: requirement order drifted.' }
  $selectorIds=@($ledger.selectors.id); $artifactIds=@($ledger.artifact_contracts.id)
  if (@($selectorIds|Select-Object -Unique).Count -ne $selectorIds.Count -or @($artifactIds|Select-Object -Unique).Count -ne $artifactIds.Count) { throw 'P07-LEDGER-UNIQUE: duplicate selector or artifact id.' }
  foreach($requirement in @($ledger.requirement_order)) {
    if ($null -eq $ledger.requirements.PSObject.Properties[$requirement] -or @($ledger.requirements.$requirement).Count -lt 2) { throw "P07-LEDGER-RECIPROCAL: $requirement lacks reciprocal selectors." }
    foreach($selector in @($ledger.requirements.$requirement)) { if ($selectorIds -cnotcontains $selector) { throw "P07-LEDGER-RECIPROCAL: unknown selector $selector." } }
  }
  foreach($edge in @($ledger.edge_probes)) {
    if ($selectorIds -cnotcontains $edge.selector_id -or $artifactIds -cnotcontains $edge.artifact_id -or @($ledger.requirement_order) -cnotcontains $edge.requirement_id) { throw "P07-LEDGER-EDGE: broken edge $($edge.id)." }
  }
  foreach($artifact in @($ledger.artifact_contracts | Where-Object { $null -ne $_.PSObject.Properties['sha256'] })) {
    $artifactPath=Join-Path $repoRoot ([string]$artifact.path)
    if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf) -or (Get-FileHash -Algorithm SHA256 $artifactPath).Hash.ToLowerInvariant() -cne [string]$artifact.sha256) { throw "P07-LEDGER-ARTIFACT-DIGEST: $($artifact.id) drifted." }
  }
  foreach($prohibition in @($ledger.prohibitions)) {
    if ($prohibition.flagged -ne $true -or $selectorIds -cnotcontains $prohibition.selector_id -or $artifactIds -cnotcontains $prohibition.artifact_id) { throw "P07-LEDGER-PROHIBITION: broken prohibition $($prohibition.id)." }
  }
  if ($ledger.evidence.credentials_read -ne $false -or $ledger.evidence.publication_performed -ne $false -or $ledger.evidence.network_performed -ne $false -or $ledger.evidence.hosted_settings_checked_by_required -ne $false) { throw 'P07-LEDGER-BOUNDARY: credential-free evidence drifted.' }
  Write-Host 'Phase 7 reciprocal requirement ledger passed.'
}

function Assert-P07Focused {
  Assert-P07Workflow
  Assert-P07Ledger
  & (Join-Path $PSScriptRoot 'Test-ReleaseIntent.ps1') -ContractOnly
  & (Join-Path $PSScriptRoot 'Test-ReleasePublisherNegative.ps1')
  $requiredSource=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-MoonQuality.ps1') -Raw
  foreach($forbidden in @('Test-Phase07Qualification.ps1 -HostedSettings','-Mode LiveOneStep','secrets.MOONCAKES_TOKEN','moon publish','gh api','github.token')) {
    if ($requiredSource.IndexOf($forbidden,[StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "P07-REQUIRED-LIVE-REACHABILITY: Required contains '$forbidden'." }
  }
  $schema=Get-Content -LiteralPath (Join-Path $repoRoot 'release/prepared/schema.json') -Raw | ConvertFrom-Json -Depth 100
  $roles=@($schema.'$defs'.payload.properties.role.enum)
  if (@($roles|Select-Object -Unique).Count -ne 12 -or $roles.Count -ne 12) { throw 'P07-PREPARED-ROLES: payload roles are missing or duplicated.' }
  Write-Host 'Phase 7 focused credential-free control-plane tests passed.'
}

function Assert-P07Report {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'P07-REPORT-MISSING: Required report is missing.' }
  $report=Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100
  if ($null -eq $report.PSObject.Properties['phase_07']) { throw 'P07-REPORT-PHASE: Phase 7 evidence is missing.' }
  $p=$report.phase_07
  if ($p.credentials_read -ne $false -or $p.publication_performed -ne $false -or $p.network_performed -ne $false -or $p.hosted_settings_checked -ne $false -or $p.workflow_static_validation -cne 'pass' -or $p.recovery_rehearsal -cne 'pass') { throw 'P07-REPORT-BOUNDARY: Required report crossed the non-live boundary.' }
  if ((@($p.requirement_order) -join ',') -cne 'REL-01,REL-02,REL-03,REL-04,REL-05') { throw 'P07-REPORT-ORDER: requirement order drifted.' }
  Write-Host 'Phase 7 Required report evidence passed.'
}

function Assert-P07HostedSettings {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'P07-HOSTED-GH: GitHub CLI is required.' }
  $repo='tchivs/moonbit-foundation'
  $environment=(& gh api "repos/$repo/environments/mooncakes-production" 2>$null | ConvertFrom-Json -Depth 100)
  if ($null -eq $environment) { throw 'P07-HOSTED-ENVIRONMENT: mooncakes-production is missing.' }
  $secretNames=@((& gh api "repos/$repo/environments/mooncakes-production/secrets" 2>$null | ConvertFrom-Json -Depth 100).secrets.name)
  if (($secretNames -join ',') -cne 'MOONCAKES_TOKEN') { throw 'P07-HOSTED-SECRET-NAME: exact environment secret name is missing or extra names exist.' }
  $rulesets=@(& gh api "repos/$repo/rulesets" 2>$null | ConvertFrom-Json -Depth 100)
  $matches=@($rulesets | Where-Object { $_.target -ceq 'tag' -and $_.enforcement -ceq 'active' })
  $valid=@($matches | Where-Object {
    (@($_.conditions.ref_name.include) -join ',') -ceq 'refs/tags/modules-v0.1.0,refs/tags/modules-correction-*' -and
    @($_.conditions.ref_name.exclude).Count -eq 0 -and @($_.bypass_actors).Count -eq 0 -and
    @($_.rules.type) -ccontains 'deletion' -and @($_.rules.type) -ccontains 'non_fast_forward' -and @($_.rules.type) -cnotcontains 'creation'
  })
  if ($valid.Count -ne 1) { throw 'P07-HOSTED-RULESET: exactly one active exact tag ruleset without bypass is required.' }
  Write-Host 'Phase 7 hosted settings passed (names and structural rules only; no secret value inspected).'
}

if (-not ($WorkflowOnly -or $LedgerOnly -or $Focused -or $HostedSettings -or -not [string]::IsNullOrWhiteSpace($ReportPath))) { throw 'P07-SELECTOR: choose a selector.' }
if ($WorkflowOnly) { Assert-P07Workflow; return }
if ($LedgerOnly) { Assert-P07Ledger; return }
if ($Focused) { Assert-P07Focused; return }
if ($HostedSettings) { Assert-P07HostedSettings; return }
Assert-P07Report -Path $ReportPath
