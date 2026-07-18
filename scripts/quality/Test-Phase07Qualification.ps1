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

if (-not ($WorkflowOnly -or $LedgerOnly -or $Focused -or $HostedSettings -or -not [string]::IsNullOrWhiteSpace($ReportPath))) { throw 'P07-SELECTOR: choose a selector.' }
if ($WorkflowOnly) { Assert-P07Workflow; return }
throw 'P07-NOT-YET-IMPLEMENTED: Task 2 selectors are pending.'
