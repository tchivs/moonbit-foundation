[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$oldOwner = 'moonbit' + '-foundation'
$identities = [ordered]@{
  core = "$oldOwner/mb-core"
  color = "$oldOwner/mb-color"
  image = "$oldOwner/mb-image"
}
$expectedInventorySha256 = '50e8f367fde0bc961cee75b86178ab6a0516ff55601754031553dc1958db7d0f'
$expectedAuditSha256 = '52f118333892cfe1044b8105a6ea5d03f1ab087d3f7875d13b79c4e5b7640a7a'

# These are exact completed-history files, not a directory or filename-pattern allowance.
$archivedOrCompletedPaths = @(
  '.planning/milestones/v0.1-phases/01-foundation-charter-and-reproducible-workspace/01-03-PLAN.md',
  '.planning/milestones/v0.1-phases/01-foundation-charter-and-reproducible-workspace/01-04-PLAN.md',
  '.planning/milestones/v0.1-phases/01-foundation-charter-and-reproducible-workspace/01-04-SUMMARY.md',
  '.planning/milestones/v0.1-phases/01-foundation-charter-and-reproducible-workspace/01-05-PLAN.md',
  '.planning/milestones/v0.1-phases/01-foundation-charter-and-reproducible-workspace/01-05-SUMMARY.md',
  '.planning/milestones/v0.1-phases/01-foundation-charter-and-reproducible-workspace/01-06-PLAN.md',
  '.planning/milestones/v0.1-phases/01-foundation-charter-and-reproducible-workspace/01-06-SUMMARY.md',
  '.planning/milestones/v0.1-phases/01-foundation-charter-and-reproducible-workspace/01-CONTEXT.md',
  '.planning/milestones/v0.1-phases/01-foundation-charter-and-reproducible-workspace/01-PATTERNS.md',
  '.planning/milestones/v0.1-phases/01-foundation-charter-and-reproducible-workspace/01-RESEARCH.md',
  '.planning/milestones/v0.1-phases/01-foundation-charter-and-reproducible-workspace/01-VERIFICATION.md',
  '.planning/milestones/v0.1-phases/02-bounded-core-primitives/02-CONTEXT.md',
  '.planning/milestones/v0.1-phases/03-reference-color-semantics/03-01-PLAN.md',
  '.planning/milestones/v0.1-phases/03-reference-color-semantics/03-RESEARCH.md',
  '.planning/milestones/v0.1-phases/04-image-model-views-and-operations/04-01-PLAN.md',
  '.planning/milestones/v0.1-phases/04-image-model-views-and-operations/04-03-PLAN.md',
  '.planning/milestones/v0.1-phases/04-image-model-views-and-operations/04-06-PLAN.md',
  '.planning/milestones/v0.1-phases/04-image-model-views-and-operations/04-07-PLAN.md',
  '.planning/milestones/v0.1-phases/05-reference-codec-and-release-qualification/05-01-PLAN.md',
  '.planning/milestones/v0.1-phases/05-reference-codec-and-release-qualification/05-01-SUMMARY.md',
  '.planning/milestones/v0.1-phases/05-reference-codec-and-release-qualification/05-02-PLAN.md',
  '.planning/milestones/v0.1-phases/05-reference-codec-and-release-qualification/05-02-SUMMARY.md',
  '.planning/milestones/v0.1-phases/05-reference-codec-and-release-qualification/05-03-PLAN.md',
  '.planning/milestones/v0.1-phases/05-reference-codec-and-release-qualification/05-03-SUMMARY.md',
  '.planning/milestones/v0.1-phases/05-reference-codec-and-release-qualification/05-VERIFICATION.md',
  '.planning/phases/06-namespace-authority-and-compatibility-contract/06-08-SUMMARY.md'
)
$mappingPath = '.planning/phases/06-namespace-authority-and-compatibility-contract/06-RESEARCH.md'
$sourceAuditPath = 'policy/phase-01-source-audit.json'
$negativeFixturePaths = @(
  'scripts/quality/Invoke-MoonQuality.ps1',
  'scripts/quality/Test-PublicInterfaceBaseline.ps1'
)

function Get-TextSha256 {
  param([Parameter(Mandatory)][string]$Text)
  [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text))).ToLowerInvariant()
}

function Get-OccurrenceClassification {
  param([Parameter(Mandatory)][string]$Path)
  if ($archivedOrCompletedPaths -ccontains $Path) { return 'archived_or_completed_history' }
  if ($Path -ceq $sourceAuditPath) { return 'immutable_source_audit' }
  if ($Path -ceq $mappingPath) { return 'explicit_old_to_new_mapping' }
  if ($negativeFixturePaths -ccontains $Path) { return 'negative_fixture' }
  throw "Unclassified old canonical identity occurrence in '$Path'."
}

function Get-OldIdentityOccurrences {
  $candidatePaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  foreach ($identity in $identities.Values) {
    $paths = @(& git -C $repoRoot grep -l -I -F -- $identity 2>$null | ForEach-Object { $_.Replace('\', '/') })
    if ($LASTEXITCODE -notin @(0, 1)) { throw "Unable to scan tracked files for '$identity'." }
    foreach ($path in $paths) { $null = $candidatePaths.Add($path) }
  }

  $records = [Collections.Generic.List[object]]::new()
  foreach ($path in @($candidatePaths | Sort-Object)) {
    $absolute = Join-Path $repoRoot $path
    foreach ($line in [IO.File]::ReadLines($absolute)) {
      foreach ($identityKey in $identities.Keys) {
        $identity = [string]$identities[$identityKey]
        $start = 0
        $occurrence = 0
        while (($index = $line.IndexOf($identity, $start, [StringComparison]::Ordinal)) -ge 0) {
          $occurrence++
          $records.Add([pscustomobject][ordered]@{
            path = $path
            identity = $identityKey
            occurrence = $occurrence
            classification = Get-OccurrenceClassification -Path $path
            owner_id = ''
            context_sha256 = Get-TextSha256 -Text $line
          })
          $start = $index + $identity.Length
        }
      }
    }
  }
  for ($index = 0; $index -lt $records.Count; $index++) {
    $records[$index].owner_id = 'OLDID-{0:D3}' -f ($index + 1)
  }
  return $records.ToArray()
}

function Get-InventorySha256 {
  param([Parameter(Mandatory)][object[]]$Records)
  $lines = @($Records | ForEach-Object {
    "$($_.path)|$($_.identity)|$($_.occurrence)|$($_.classification)|$($_.owner_id)|$($_.context_sha256)"
  })
  Get-TextSha256 -Text ($lines -join "`n")
}

function Assert-OccurrenceInventory {
  param([Parameter(Mandatory)][object[]]$Records)
  if ($Records.Count -ne 105) { throw "Old-identity occurrence count mismatch: expected 105, got $($Records.Count)." }
  if (@($Records.owner_id | Sort-Object -Unique).Count -ne 105) { throw 'Old-identity owner IDs are not unique.' }
  if ((Get-InventorySha256 -Records $Records) -cne $expectedInventorySha256) {
    throw 'Old-identity occurrence inventory differs: missing, extra, moved, reclassified, or context-drifted record.'
  }
  $expectedClasses = [ordered]@{
    archived_or_completed_history = 65
    explicit_old_to_new_mapping = 3
    immutable_source_audit = 3
    negative_fixture = 34
  }
  foreach ($classification in $expectedClasses.Keys) {
    $actual = @($Records | Where-Object classification -CEQ $classification).Count
    if ($actual -ne $expectedClasses[$classification]) { throw "Classification '$classification' count mismatch." }
  }
}

$records = @(Get-OldIdentityOccurrences)
Assert-OccurrenceInventory -Records $records

function Confirm-InventoryRejected {
  param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][object[]]$Candidate)
  $failure = $null
  try { Assert-OccurrenceInventory -Records $Candidate } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure) { throw "Identity inventory negative '$Name' unexpectedly passed." }
}
Confirm-InventoryRejected -Name 'missing occurrence' -Candidate @($records | Select-Object -SkipLast 1)
Confirm-InventoryRejected -Name 'extra occurrence' -Candidate @($records + $records[0])
$contextDrift = @(($records | ConvertTo-Json -Depth 10) | ConvertFrom-Json -Depth 10)
$contextDrift[0].context_sha256 = '0' * 64
Confirm-InventoryRejected -Name 'context drift' -Candidate $contextDrift

$mapping = Get-Content -LiteralPath (Join-Path $repoRoot $mappingPath) -Raw
foreach ($key in $identities.Keys) {
  $expected = '| `' + $identities[$key] + '` | `tchivs/mb-' + $key + '` |'
  if (@($mapping -split '\r?\n' | Where-Object { $_ -ceq $expected }).Count -ne 1) {
    throw "Explicit same-suffix mapping row for '$key' is not exact and unique."
  }
}

$patterns = Get-Content -LiteralPath (Join-Path $repoRoot '.planning/phases/06-namespace-authority-and-compatibility-contract/06-PATTERNS.md') -Raw
foreach ($identity in $identities.Values) {
  if ($patterns.Contains($identity)) { throw '06-PATTERNS.md contains an old positive canonical identity.' }
}

$auditHash = (Get-FileHash -LiteralPath (Join-Path $repoRoot $sourceAuditPath) -Algorithm SHA256).Hash.ToLowerInvariant()
if ($auditHash -cne $expectedAuditSha256) { throw 'Historical Phase 1 source audit digest changed.' }

$research = Get-Content -LiteralPath (Join-Path $repoRoot $mappingPath) -Raw
foreach ($decision in 1..18) {
  if ($research -cnotmatch "(?m)^- \*\*D-$('{0:D2}' -f $decision):\*\*") { throw "Phase 6 decision D-$('{0:D2}' -f $decision) is missing." }
}
foreach ($brandPath in @('.planning/PROJECT.md', 'docs/rfcs/0001-moonbit-native-foundation.md')) {
  if (-not (Get-Content -LiteralPath (Join-Path $repoRoot $brandPath) -Raw).Contains('MoonBit Native Foundation')) {
    throw "Foundation branding is missing from '$brandPath'."
  }
}

$qualificationPlan = Get-Content -LiteralPath (Join-Path $repoRoot '.planning/phases/06-namespace-authority-and-compatibility-contract/06-06-PLAN.md') -Raw
$edgeIds = @([regex]::Matches($qualificationPlan, 'EDGE-[A-Z0-9-]+') | ForEach-Object Value | Sort-Object -Unique)
$prohibitionIds = @([regex]::Matches($qualificationPlan, 'PROH-[A-Z0-9-]+') | ForEach-Object Value | Sort-Object -Unique)
if ($edgeIds.Count -ne 22 -or $prohibitionIds.Count -ne 7) { throw 'Planned edge/prohibition inventory drift.' }

Write-Host "Identity migration closure passed: $($records.Count) exact occurrences, 22 edges, 7 prohibitions, immutable history."
