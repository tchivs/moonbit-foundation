[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Assert-Policy.ps1')

function Copy-TestObject([object]$Value) {
  return ($Value | ConvertTo-Json -Depth 30 | ConvertFrom-Json -DateKind String)
}

function Write-TestJson([string]$Path, [object]$Value) {
  $parent = Split-Path -Parent $Path
  if ($parent) { [void](New-Item -ItemType Directory -Force -Path $parent) }
  $Value | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $Path -Encoding utf8
}

function New-TestRepository {
  $root = Join-Path ([System.IO.Path]::GetTempPath()) ("mnf-rfc-" + [guid]::NewGuid().ToString('N'))
  [void](New-Item -ItemType Directory -Force -Path (Join-Path $root 'docs/governance/decisions'))
  [void](New-Item -ItemType Directory -Force -Path (Join-Path $root 'docs/rfcs'))
  [void](New-Item -ItemType Directory -Force -Path (Join-Path $root 'policy'))
  [void](New-Item -ItemType Directory -Force -Path (Join-Path $root 'reviews'))
  [void](New-Item -ItemType Directory -Force -Path (Join-Path $root 'reports'))
  @'
# Decision 0001

## Owner instruction

> 现在只有我一个人开发，跳过

## Conversation context and interpretation

Conditional preauthorization for RFC 0001.

## Authorization and conditions

No second approval and no seven-day public review are claimed.

- `AUTH-ONE-OWNER`: Eligibility requires the canonical roster to contain exactly one unique maintainer identity with the project-owner role.
- `AUTH-EXPIRES-SECOND-MAINTAINER`: Eligibility expires immediately when a second distinct maintainer is present.
- `AUTH-TWO-EDGE-REVIEWS`: EDGE-GOV-01-UNCLASSIFIED and EDGE-GOV-02-UNCLASSIFIED must both be completed and dispositioned.
- `AUTH-NO-LATER-APPROVAL`: The recorded owner instruction is consumed; no later approval may be synthesized.

## Edge review results

- `EDGE-GOV-01-UNCLASSIFIED`: Completed. Disposition: no-omission-found.
- `EDGE-GOV-02-UNCLASSIFIED`: Completed. Disposition: no-omission-found.
- Unresolved blocking objections: none.
'@ | Set-Content -LiteralPath (Join-Path $root 'docs/governance/decisions/0001-sole-owner-bootstrap.md') -Encoding utf8
  @'
# RFC 0001 maintainer approvals

## Alice approval

- **Identity:** alice
- **Role:** maintainer
- **Disposition:** approved

## Bob approval

- **Identity:** bob
- **Role:** maintainer
- **Disposition:** approved
'@ | Set-Content -LiteralPath (Join-Path $root 'reviews/rfc-0001.md') -Encoding utf8
  @'
# External evidence verifications

## Review location

- **External-Reference:** https://reviews.moonbit-foundation.org/rfc/1
- **Method:** manual
- **Verified-By:** test-reviewer
- **Verified-At:** 2026-07-08T01:00:00Z
- **Disposition:** verified

## Review opened

- **External-Reference:** https://reviews.moonbit-foundation.org/rfc/1#opened
- **Method:** manual
- **Verified-By:** test-reviewer
- **Verified-At:** 2026-07-08T01:00:00Z
- **Disposition:** verified

## Review closed

- **External-Reference:** https://reviews.moonbit-foundation.org/rfc/1#closed
- **Method:** manual
- **Verified-By:** test-reviewer
- **Verified-At:** 2026-07-08T01:00:00Z
- **Disposition:** verified

## Lead approval verification

- **External-Reference:** https://reviews.moonbit-foundation.org/rfc/1#lead-approval
- **Method:** manual
- **Verified-By:** test-reviewer
- **Verified-At:** 2026-07-08T01:00:00Z
- **Disposition:** verified
'@ | Set-Content -LiteralPath (Join-Path $root 'reviews/external-verification.md') -Encoding utf8
  @'
# RFC 0001 qualification

## Qualification

- **RFC:** 0001
- **Disposition:** qualified
'@ | Set-Content -LiteralPath (Join-Path $root 'reports/rfc-0001-qualification.md') -Encoding utf8
  'implementation marker' | Set-Content -LiteralPath (Join-Path $root 'implementation.txt') -Encoding utf8
  & git -C $root init -q
  & git -C $root config user.name 'MNF Test'
  & git -C $root config user.email 'mnf-test@example.invalid'
  & git -C $root add implementation.txt
  & git -C $root commit -q -m 'test implementation evidence'
  return $root
}

function New-TestRoster {
  return [pscustomobject]@{
    schema_version = '1.0.0'
    maintainers = @([pscustomobject]@{
      identity = 'sole-project-owner'
      roles = @('maintainer', 'project-owner')
      evidence = 'docs/governance/decisions/0001-sole-owner-bootstrap.md#owner-instruction'
    })
  }
}

function New-TestPolicy([string]$Status = 'Accepted', [string]$Route = 'sole-project-owner-bootstrap') {
  $current = [ordered]@{
    id = '0001'; status = $Status; path = 'docs/rfcs/0001-moonbit-native-foundation.md'
    transition = [ordered]@{ from='Proposed'; to=$Status; evidence=@('docs/governance/decisions/0001-sole-owner-bootstrap.md#owner-instruction','docs/governance/decisions/0001-sole-owner-bootstrap.md#edge-review-results') }
    acceptance_route = $Route; authority = 'sole-project-owner'; approvers = @(); approval_records = @()
    project_lead = $null; project_owner = 'sole-project-owner'
    public_review_url = $null; public_review_started_at = $null; public_review_ended_at = $null; public_review_evidence = $null
    external_evidence_verifications = @()
    decision_evidence_path = 'docs/governance/decisions/0001-sole-owner-bootstrap.md'
    decision_evidence_anchors = @('owner-instruction','conversation-context-and-interpretation','authorization-and-conditions','edge-review-results')
    edge_reviews = @(
      [pscustomobject]@{ id='EDGE-GOV-01-UNCLASSIFIED'; status='completed'; disposition='no-omission-found' },
      [pscustomobject]@{ id='EDGE-GOV-02-UNCLASSIFIED'; status='completed'; disposition='no-omission-found' }
    )
    blocking_objections = 'none'; objection_disposition = 'none-open'
    acceptance_evidence = @('docs/governance/decisions/0001-sole-owner-bootstrap.md#owner-instruction','docs/governance/decisions/0001-sole-owner-bootstrap.md#edge-review-results')
    implementation_evidence = @(); qualification_evidence = @(); rejection_disposition = $null
    superseded_by = $null; supersession_evidence = @()
  }
  return [pscustomobject]@{
    rfc = [pscustomobject]@{
      allowed_statuses = @('Draft','Proposed','Accepted','Implemented','Rejected','Superseded')
      acceptance_routes = @('maintainer','project-lead-public-review','sole-project-owner-bootstrap')
      maintainer_roster_path = 'policy/maintainers.json'
      sole_owner_bootstrap = [pscustomobject]@{
        decision_path = 'docs/governance/decisions/0001-sole-owner-bootstrap.md'
        required_anchors = @('owner-instruction','conversation-context-and-interpretation','authorization-and-conditions','edge-review-results')
        mandatory_edge_reviews = @('EDGE-GOV-01-UNCLASSIFIED','EDGE-GOV-02-UNCLASSIFIED')
      }
      current_foundation_rfc = [pscustomobject]$current
    }
  }
}

function Write-TestState([string]$Root, [object]$Policy, [object]$Roster) {
  $status = [string]$Policy.rfc.current_foundation_rfc.status
  $rfc = $Policy.rfc.current_foundation_rfc
  $rows = [System.Collections.Generic.List[string]]::new()
  $rows.Add('| — | Draft | repository:initial-draft |')
  if ($status -cne 'Draft' -and -not ($status -ceq 'Rejected' -and [string]$rfc.transition.from -ceq 'Draft')) { $rows.Add('| Draft | Proposed | repository:proposed-revision |') }
  $hasAcceptedHistory = $status -in @('Accepted','Implemented') -or ($status -ceq 'Superseded' -and [string]$rfc.transition.from -in @('Accepted','Implemented'))
  $hasImplementedHistory = $status -ceq 'Implemented' -or ($status -ceq 'Superseded' -and [string]$rfc.transition.from -ceq 'Implemented')
  if ($hasAcceptedHistory) { $rows.Add('| Proposed | Accepted | ' + (@($rfc.acceptance_evidence) -join '; ') + ' |') }
  if ($hasImplementedHistory) { $rows.Add('| Accepted | Implemented | ' + (@($rfc.implementation_evidence) + @($rfc.qualification_evidence) -join '; ') + ' |') }
  if ($status -in @('Rejected','Superseded')) { $rows.Add("| $($rfc.transition.from) | $status | " + (@($rfc.transition.evidence) -join '; ') + ' |') }
  @("# RFC 0001", "", "- **Status:** $status", "", "## Transition history", "", "| From | To | Evidence |", "|---|---|---|") + @($rows) | Set-Content -LiteralPath (Join-Path $Root 'docs/rfcs/0001-moonbit-native-foundation.md') -Encoding utf8
  @("# RFC index", "", "| RFC | Title | Status | Scope |", "|---|---|---|---|", "| [RFC 0001](0001-moonbit-native-foundation.md) | Foundation | $status | Charter |") | Set-Content -LiteralPath (Join-Path $Root 'docs/rfcs/README.md') -Encoding utf8
  Write-TestJson (Join-Path $Root 'policy/maintainers.json') $Roster
}

function New-TestCommitEvidence([string]$Root, [string]$Message) {
  $tree = (& git -C $Root write-tree).Trim()
  $sha = ($Message | & git -C $Root commit-tree $tree -p HEAD).Trim()
  if ($LASTEXITCODE -ne 0 -or $sha -cnotmatch '^[0-9a-f]{40}$') { throw 'Failed to create test evidence commit.' }
  return $sha
}

function Set-TestMaintainerCommitApproval([string]$Root, [object]$Policy, [object]$Roster, [string]$Message) {
  $sha = New-TestCommitEvidence -Root $Root -Message $Message
  $rfc = $Policy.rfc.current_foundation_rfc
  $reference = "commit:$sha"
  $rfc.approval_records[0].reference = $reference
  $rfc.acceptance_evidence = @($reference, [string]$rfc.approval_records[1].reference)
  $rfc.transition.evidence = @($rfc.acceptance_evidence)
  Write-TestState $Root $Policy $Roster
}

function Write-TestReplacementRfc([string]$Root, [string]$Status = 'Proposed') {
  $rows = @('| — | Draft | repository:initial-draft |')
  if ($Status -cne 'Draft') { $rows += '| Draft | Proposed | repository:proposal |' }
  if ($Status -in @('Accepted','Implemented')) { $rows += '| Proposed | Accepted | reviews/rfc-0002.md#approval |' }
  if ($Status -ceq 'Implemented') { $rows += '| Accepted | Implemented | commit:1234567; report:reports/rfc-0002.md#qualification |' }
  @('# RFC 0002: Replacement foundation','',("- **Status:** $Status"),'- **Supersedes:** [RFC 0001](0001-moonbit-native-foundation.md)','','## Transition history','','| From | To | Evidence |','|---|---|---|') + $rows | Set-Content -LiteralPath (Join-Path $Root 'docs/rfcs/0002-replacement.md') -Encoding utf8
}

function Invoke-AcceptanceCase([string]$Name, [object]$Policy, [object]$Roster, [bool]$ShouldPass, [scriptblock]$Arrange, [string]$ExpectedFailurePattern) {
  $root = New-TestRepository
  try {
    Write-TestState $root $Policy $Roster
    if ($Arrange) { & $Arrange $root $Policy $Roster }
    $passed = $true
    $failureMessage = $null
    try { Assert-RfcAcceptanceState -Policy $Policy -RosterPath (Join-Path $root 'policy/maintainers.json') -RepositoryRoot $root -Now ([DateTimeOffset]'2026-07-16T00:00:00Z') }
    catch { $passed = $false; $failureMessage = $_.Exception.Message }
    if ($ShouldPass -and -not $passed) { throw "RFC acceptance case '$Name' expected success but failed: $failureMessage" }
    if (-not $ShouldPass) {
      if ([string]::IsNullOrWhiteSpace($ExpectedFailurePattern)) { throw "RFC acceptance case '$Name' is negative but has no expected failure pattern." }
      if ($passed) { throw "RFC acceptance case '$Name' expected rejection matching '$ExpectedFailurePattern' but validation passed." }
      if ($failureMessage -cnotmatch $ExpectedFailurePattern) { throw "RFC acceptance case '$Name' rejected for the wrong reason. Expected '$ExpectedFailurePattern'; got '$failureMessage'." }
    }
    Write-Host "PASS: $Name"
  } finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
  }
}

$roster = New-TestRoster
$accepted = New-TestPolicy
Invoke-AcceptanceCase 'sole owner accepted' $accepted $roster $true $null

$proposed = New-TestPolicy -Status 'Proposed' -Route $null
$p = $proposed.rfc.current_foundation_rfc
$p.transition.from='Draft'; $p.transition.evidence=@('repository:proposed-revision')
$p.authority=$null; $p.decision_evidence_path=$null; $p.decision_evidence_anchors=@(); $p.edge_reviews=@(); $p.blocking_objections='not-assessed'; $p.objection_disposition=$null; $p.acceptance_evidence=@()
Invoke-AcceptanceCase 'proposed empty evidence' $proposed $roster $true $null
$proposedReviewed = Copy-TestObject $proposed
$proposedReviewed.rfc.current_foundation_rfc.edge_reviews = @(
  [pscustomobject]@{ id='EDGE-GOV-01-UNCLASSIFIED'; status='completed'; disposition='no-omission-found' },
  [pscustomobject]@{ id='EDGE-GOV-02-UNCLASSIFIED'; status='completed'; disposition='no-omission-found' }
)
Invoke-AcceptanceCase 'proposed with completed edge reviews' $proposedReviewed $roster $true $null

$missingLedger = Copy-TestObject $accepted
Invoke-AcceptanceCase 'accepted requires transition ledger row' $missingLedger $roster $false { param($root) @('# RFC 0001','','- **Status:** Accepted') | Set-Content -LiteralPath (Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md') } 'exactly one Transition history section'
$illegalPrior = Copy-TestObject $accepted; $illegalPrior.rfc.current_foundation_rfc.transition.from='Draft'
Invoke-AcceptanceCase 'accepted rejects illegal prior state' $illegalPrior $roster $false $null 'Illegal RFC transition'
$ledgerSuffix = Copy-TestObject $accepted
Invoke-AcceptanceCase 'ledger rejects suffix evidence injection' $ledgerSuffix $roster $false { param($root) $path=Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md'; (Get-Content -Raw $path).Replace('#owner-instruction;','#owner-instruction-forged;') | Set-Content -LiteralPath $path } 'ledger evidence.*mismatch'
$ledgerPrefix = Copy-TestObject $accepted
Invoke-AcceptanceCase 'ledger rejects prefix evidence injection' $ledgerPrefix $roster $false { param($root) $path=Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md'; (Get-Content -Raw $path).Replace('docs/governance/decisions/0001-sole-owner-bootstrap.md#owner-instruction','docs/governance/decisions/0001-sole-owner-bootstrap.md#owner') | Set-Content -LiteralPath $path } 'ledger evidence.*mismatch'
$ledgerExtra = Copy-TestObject $accepted
Invoke-AcceptanceCase 'ledger rejects extra evidence token' $ledgerExtra $roster $false { param($root) $path=Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md'; (Get-Content -Raw $path).Replace('edge-review-results |','edge-review-results; reviews/extra.md#approval |') | Set-Content -LiteralPath $path } 'ledger evidence.*mismatch'
$ledgerDuplicate = Copy-TestObject $accepted
Invoke-AcceptanceCase 'ledger rejects duplicate evidence token' $ledgerDuplicate $roster $false { param($root) $path=Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md'; $ref='docs/governance/decisions/0001-sole-owner-bootstrap.md#edge-review-results'; (Get-Content -Raw $path).Replace("$ref |","$ref; $ref |") | Set-Content -LiteralPath $path } 'ledger evidence contains duplicate'
$ledgerEmpty = Copy-TestObject $accepted
Invoke-AcceptanceCase 'ledger rejects empty delimited evidence token' $ledgerEmpty $roster $false { param($root) $path=Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md'; (Get-Content -Raw $path).Replace('; docs/governance',';; docs/governance') | Set-Content -LiteralPath $path } 'ledger evidence contains an empty'
$ledgerReordered = Copy-TestObject $accepted
Invoke-AcceptanceCase 'ledger accepts reordered exact evidence set' $ledgerReordered $roster $true { param($root) $path=Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md'; $text=Get-Content -Raw $path; $a='docs/governance/decisions/0001-sole-owner-bootstrap.md#owner-instruction'; $b='docs/governance/decisions/0001-sole-owner-bootstrap.md#edge-review-results'; $text.Replace("$a; $b","$b; $a") | Set-Content -LiteralPath $path }
$unrelatedTable = Copy-TestObject $accepted
Invoke-AcceptanceCase 'ledger ignores unrelated three-column table' $unrelatedTable $roster $true { param($root) $path=Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md'; Add-Content -LiteralPath $path -Value @('','## Appendix','','| Name | Value | Note |','|---|---|---|','| alpha | beta | gamma |') }
$outsideTransition = Copy-TestObject $accepted
Invoke-AcceptanceCase 'ledger ignores transition-like table outside section' $outsideTransition $roster $true { param($root) $path=Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md'; Add-Content -LiteralPath $path -Value @('','## Appendix','','| From | To | Evidence |','|---|---|---|','| Accepted | Implemented | forged |') }
$multipleLedgerTables = Copy-TestObject $accepted
Invoke-AcceptanceCase 'ledger rejects multiple tables in transition section' $multipleLedgerTables $roster $false { param($root) $path=Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md'; Add-Content -LiteralPath $path -Value @('','Separate table follows.','','| Extra | Table | Here |','|---|---|---|','| a | b | c |') } 'exactly one Markdown table'
$implemented = Copy-TestObject $accepted; $implemented.rfc.current_foundation_rfc.status='Implemented'; $implemented.rfc.current_foundation_rfc.transition.from='Accepted'; $implemented.rfc.current_foundation_rfc.transition.to='Implemented'; $implemented.rfc.current_foundation_rfc.transition.evidence=@('commit:0000000','report:reports/rfc-0001-qualification.md#qualification'); $implemented.rfc.current_foundation_rfc.implementation_evidence=@('commit:0000000'); $implemented.rfc.current_foundation_rfc.qualification_evidence=@('report:reports/rfc-0001-qualification.md#qualification')
$arrangeValidImplemented = { param($root,$policy,$caseRoster) $sha=(& git -C $root rev-parse HEAD).Trim(); $i=$policy.rfc.current_foundation_rfc; $i.implementation_evidence=@("commit:$sha"); $i.qualification_evidence=@('report:reports/rfc-0001-qualification.md#qualification'); $i.transition.evidence=@($i.implementation_evidence + $i.qualification_evidence); Write-TestState $root $policy $caseRoster }
Invoke-AcceptanceCase 'implemented resolves commit and qualification report evidence' $implemented $roster $true $arrangeValidImplemented
$implementedMissingAcceptanceRow = Copy-TestObject $implemented
Invoke-AcceptanceCase 'implemented preserves historical acceptance row' $implementedMissingAcceptanceRow $roster $false { param($root) $path=Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md'; (Get-Content $path | Where-Object { $_ -cnotmatch '^\| Proposed \| Accepted \|' }) | Set-Content -LiteralPath $path } 'ledger row count mismatch'
$missingImplementation = Copy-TestObject $implemented; $missingImplementation.rfc.current_foundation_rfc.implementation_evidence=@(); $missingImplementation.rfc.current_foundation_rfc.transition.evidence=@('report:reports/rfc-0001-qualification.md#qualification')
Invoke-AcceptanceCase 'implemented rejects missing implementation evidence' $missingImplementation $roster $false $null 'implementation.*requires at least one'
$missingCommit = Copy-TestObject $implemented
$missingCommit.rfc.current_foundation_rfc.implementation_evidence=@('commit:ffffffffffffffffffffffffffffffffffffffff')
$missingCommit.rfc.current_foundation_rfc.transition.evidence=@('commit:ffffffffffffffffffffffffffffffffffffffff','report:reports/rfc-0001-qualification.md#qualification')
Invoke-AcceptanceCase 'implemented rejects nonexistent commit evidence' $missingCommit $roster $false $null 'Implementation commit.*does not exist'
$unknownImplementation = Copy-TestObject $implemented; $unknownImplementation.rfc.current_foundation_rfc.implementation_evidence=@('ticket:123'); $unknownImplementation.rfc.current_foundation_rfc.transition.evidence=@('ticket:123','report:reports/rfc-0001-qualification.md#qualification')
Invoke-AcceptanceCase 'implemented rejects unknown implementation scheme' $unknownImplementation $roster $false $null 'must use commit:<sha>'
$unknownQualification = Copy-TestObject $implemented; $unknownQualification.rfc.current_foundation_rfc.qualification_evidence=@('repository:reports/rfc-0001-qualification.md'); $unknownQualification.rfc.current_foundation_rfc.transition.evidence=@('commit:0000000','repository:reports/rfc-0001-qualification.md')
Invoke-AcceptanceCase 'implemented rejects unknown qualification scheme' $unknownQualification $roster $false { param($root,$policy,$caseRoster) $sha=(& git -C $root rev-parse HEAD).Trim(); $policy.rfc.current_foundation_rfc.implementation_evidence=@("commit:$sha"); $policy.rfc.current_foundation_rfc.transition.evidence=@("commit:$sha",'repository:reports/rfc-0001-qualification.md'); Write-TestState $root $policy $caseRoster } 'must use report:reports'
$missingReport = Copy-TestObject $implemented; $missingReport.rfc.current_foundation_rfc.qualification_evidence=@('report:reports/missing.md#qualification'); $missingReport.rfc.current_foundation_rfc.transition.evidence=@('commit:0000000','report:reports/missing.md#qualification')
Invoke-AcceptanceCase 'implemented rejects missing qualification report' $missingReport $roster $false { param($root,$policy,$caseRoster) $sha=(& git -C $root rev-parse HEAD).Trim(); $policy.rfc.current_foundation_rfc.implementation_evidence=@("commit:$sha"); $policy.rfc.current_foundation_rfc.transition.evidence=@("commit:$sha",'report:reports/missing.md#qualification'); Write-TestState $root $policy $caseRoster } 'Qualification report component.*does not exist'
$missingReportAnchor = Copy-TestObject $implemented; $missingReportAnchor.rfc.current_foundation_rfc.qualification_evidence=@('report:reports/rfc-0001-qualification.md#missing'); $missingReportAnchor.rfc.current_foundation_rfc.transition.evidence=@('commit:0000000','report:reports/rfc-0001-qualification.md#missing')
Invoke-AcceptanceCase 'implemented rejects missing qualification anchor' $missingReportAnchor $roster $false { param($root,$policy,$caseRoster) $sha=(& git -C $root rev-parse HEAD).Trim(); $policy.rfc.current_foundation_rfc.implementation_evidence=@("commit:$sha"); $policy.rfc.current_foundation_rfc.transition.evidence=@("commit:$sha",'report:reports/rfc-0001-qualification.md#missing'); Write-TestState $root $policy $caseRoster } 'Markdown anchor.*does not identify'
$unqualifiedReport = Copy-TestObject $implemented
Invoke-AcceptanceCase 'implemented rejects unqualified report disposition' $unqualifiedReport $roster $false { param($root,$policy,$caseRoster) & $arrangeValidImplemented $root $policy $caseRoster; $path=Join-Path $root 'reports/rfc-0001-qualification.md'; (Get-Content -Raw $path).Replace('**Disposition:** qualified','**Disposition:** rejected') | Set-Content -LiteralPath $path } 'does not record a qualified disposition'
$superseded = Copy-TestObject $proposed; $superseded.rfc.current_foundation_rfc.status='Superseded'; $superseded.rfc.current_foundation_rfc.transition.from='Proposed'; $superseded.rfc.current_foundation_rfc.transition.to='Superseded'; $superseded.rfc.current_foundation_rfc.transition.evidence=@('docs/rfcs/0002-replacement.md'); $superseded.rfc.current_foundation_rfc.project_owner=$null; $superseded.rfc.current_foundation_rfc.superseded_by='0002'; $superseded.rfc.current_foundation_rfc.supersession_evidence=@('docs/rfcs/0002-replacement.md')
Invoke-AcceptanceCase 'superseded requires canonical replacement RFC' $superseded $roster $true { param($root) Write-TestReplacementRfc $root }
Invoke-AcceptanceCase 'superseded rejects missing replacement RFC' $superseded $roster $false $null 'must identify exactly one existing RFC file'
$placeholderReplacement = Copy-TestObject $superseded
Invoke-AcceptanceCase 'superseded rejects placeholder replacement RFC' $placeholderReplacement $roster $false { param($root) '# RFC 0002' | Set-Content -LiteralPath (Join-Path $root 'docs/rfcs/0002-replacement.md') } 'canonical RFC identity heading'
$wrongReplacementId = Copy-TestObject $superseded
Invoke-AcceptanceCase 'superseded rejects wrong replacement RFC identity' $wrongReplacementId $roster $false { param($root) Write-TestReplacementRfc $root; $path=Join-Path $root 'docs/rfcs/0002-replacement.md'; (Get-Content -Raw $path).Replace('# RFC 0002:','# RFC 0003:') | Set-Content -LiteralPath $path } 'canonical RFC identity heading'
$terminalReplacement = Copy-TestObject $superseded
Invoke-AcceptanceCase 'superseded rejects terminal replacement RFC' $terminalReplacement $roster $false { param($root) Write-TestReplacementRfc $root 'Superseded' } 'non-terminal reviewable status'
$missingBackReference = Copy-TestObject $superseded
Invoke-AcceptanceCase 'superseded rejects replacement without canonical back-reference' $missingBackReference $roster $false { param($root) Write-TestReplacementRfc $root; $path=Join-Path $root 'docs/rfcs/0002-replacement.md'; (Get-Content -Raw $path).Replace('- **Supersedes:** [RFC 0001](0001-moonbit-native-foundation.md)','- **Supersedes:** none') | Set-Content -LiteralPath $path } 'canonical back-reference'
$mismatchedReplacementLedger = Copy-TestObject $superseded
Invoke-AcceptanceCase 'superseded rejects replacement lifecycle mismatch' $mismatchedReplacementLedger $roster $false { param($root) Write-TestReplacementRfc $root; $path=Join-Path $root 'docs/rfcs/0002-replacement.md'; (Get-Content -Raw $path).Replace('- **Status:** Proposed','- **Status:** Accepted') | Set-Content -LiteralPath $path } 'transition ledger must end'
$supersededAccepted = Copy-TestObject $accepted; $supersededAccepted.rfc.current_foundation_rfc.status='Superseded'; $supersededAccepted.rfc.current_foundation_rfc.transition.from='Accepted'; $supersededAccepted.rfc.current_foundation_rfc.transition.to='Superseded'; $supersededAccepted.rfc.current_foundation_rfc.transition.evidence=@('docs/rfcs/0002-replacement.md'); $supersededAccepted.rfc.current_foundation_rfc.superseded_by='0002'; $supersededAccepted.rfc.current_foundation_rfc.supersession_evidence=@('docs/rfcs/0002-replacement.md')
Invoke-AcceptanceCase 'superseded from Accepted authenticates sole-owner history' $supersededAccepted $roster $true { param($root) Write-TestReplacementRfc $root }
$forgedAcceptedHistory = Copy-TestObject $supersededAccepted; $forgedAcceptedHistory.rfc.current_foundation_rfc.acceptance_route='forged-route'
Invoke-AcceptanceCase 'superseded rejects forged historical acceptance route' $forgedAcceptedHistory $roster $false { param($root) Write-TestReplacementRfc $root } 'unknown acceptance route'
$acceptedWithImplementationEvidence = Copy-TestObject $supersededAccepted; $acceptedWithImplementationEvidence.rfc.current_foundation_rfc.implementation_evidence=@('commit:0000000')
Invoke-AcceptanceCase 'superseded from Accepted rejects implementation evidence' $acceptedWithImplementationEvidence $roster $false { param($root) Write-TestReplacementRfc $root } 'implementation_evidence must be empty'
$proposedWithAcceptance = Copy-TestObject $superseded; $proposedWithAcceptance.rfc.current_foundation_rfc.acceptance_route='forged-route'; $proposedWithAcceptance.rfc.current_foundation_rfc.authority='forged'; $proposedWithAcceptance.rfc.current_foundation_rfc.acceptance_evidence=@('forged')
Invoke-AcceptanceCase 'superseded from Proposed rejects dormant acceptance assertions' $proposedWithAcceptance $roster $false { param($root) Write-TestReplacementRfc $root } 'acceptance_route must be empty'
$supersededImplemented = Copy-TestObject $implemented; $supersededImplemented.rfc.current_foundation_rfc.status='Superseded'; $supersededImplemented.rfc.current_foundation_rfc.transition.from='Implemented'; $supersededImplemented.rfc.current_foundation_rfc.transition.to='Superseded'; $supersededImplemented.rfc.current_foundation_rfc.transition.evidence=@('docs/rfcs/0002-replacement.md'); $supersededImplemented.rfc.current_foundation_rfc.superseded_by='0002'; $supersededImplemented.rfc.current_foundation_rfc.supersession_evidence=@('docs/rfcs/0002-replacement.md')
Invoke-AcceptanceCase 'superseded from Implemented preserves implementation history' $supersededImplemented $roster $true { param($root,$policy,$caseRoster) $sha=(& git -C $root rev-parse HEAD).Trim(); $policy.rfc.current_foundation_rfc.implementation_evidence=@("commit:$sha"); Write-TestState $root $policy $caseRoster; Write-TestReplacementRfc $root }
$supersededImplementedMissingEvidence = Copy-TestObject $supersededImplemented; $supersededImplementedMissingEvidence.rfc.current_foundation_rfc.implementation_evidence=@()
Invoke-AcceptanceCase 'superseded from Implemented rejects erased implementation history' $supersededImplementedMissingEvidence $roster $false { param($root) Write-TestReplacementRfc $root } 'implementation and qualification.*requires at least one|implementation evidence requires at least one'

$cases = @(
  @{ n='duplicate roster identity'; e='duplicate identities'; mutate={ param($p,$r) $r.maintainers=@($r.maintainers[0],(Copy-TestObject $r.maintainers[0])) } },
  @{ n='zero maintainers'; e='exactly one unique canonical maintainer'; mutate={ param($p,$r) $r.maintainers=@() } },
  @{ n='multiple maintainers'; e='exactly one unique canonical maintainer'; mutate={ param($p,$r) $r.maintainers += [pscustomobject]@{identity='other';roles=@('maintainer');evidence='local'} } },
  @{ n='owner mismatch'; e='authority must match'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.project_owner='other' } },
  @{ n='missing decision anchor'; e='decision anchors count mismatch'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.decision_evidence_anchors=@('owner-instruction') } },
  @{ n='mutable canonical decision path'; e='policy decision path differs'; mutate={ param($p,$r) $p.rfc.sole_owner_bootstrap.decision_path='docs/governance/decisions/attacker.md'; $p.rfc.current_foundation_rfc.decision_evidence_path='docs/governance/decisions/attacker.md' } },
  @{ n='mutable canonical anchor set'; e='policy decision anchors count mismatch'; mutate={ param($p,$r) $p.rfc.sole_owner_bootstrap.required_anchors=@('owner-instruction') } },
  @{ n='mutable canonical edge ids'; e='policy edge review IDs count mismatch'; mutate={ param($p,$r) $p.rfc.sole_owner_bootstrap.mandatory_edge_reviews=@('FAKE'); $p.rfc.current_foundation_rfc.edge_reviews=@([pscustomobject]@{id='FAKE';status='completed';disposition='no-omission-found'}) } },
  @{ n='drive rooted path'; e='must be repository-relative'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.decision_evidence_path='C:\outside.md' } },
  @{ n='UNC rooted path'; e='must be repository-relative'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.decision_evidence_path='\\server\share\outside.md' } },
  @{ n='parent traversal'; e='must not contain a parent traversal'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.decision_evidence_path='../outside.md' } },
  @{ n='sibling prefix escape'; e='must not contain a parent traversal'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.decision_evidence_path='../repo-escape/outside.md' } },
  @{ n='wrong decision artifact'; e='does not identify the canonical decision artifact'; arrange={ param($root) '# wrong' | Set-Content -LiteralPath (Join-Path $root 'docs/governance/decisions/wrong.md') }; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.decision_evidence_path='docs/governance/decisions/wrong.md' } },
  @{ n='missing edge review'; e='edge review IDs count mismatch'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.edge_reviews=@($p.rfc.current_foundation_rfc.edge_reviews[0]) } },
  @{ n='legacy approver assertion'; e='must not assert a multi-approver list'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.approvers=@('sole-project-owner') } },
  @{ n='legacy lead assertion'; e='project_lead must be empty'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.project_lead='sole-project-owner' } },
  @{ n='legacy review assertion'; e='public_review_started_at must be empty'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.public_review_started_at='2026-07-01' } }
)
foreach ($case in $cases) {
  $policy = Copy-TestObject $accepted; $caseRoster = Copy-TestObject $roster
  & $case.mutate $policy $caseRoster
  $arrange = if ($case.ContainsKey('arrange')) { $case.arrange } else { $null }
  Invoke-AcceptanceCase $case.n $policy $caseRoster $false $arrange $case.e
}

$maintainer = Copy-TestObject $accepted
$m=$maintainer.rfc.current_foundation_rfc; $m.acceptance_route='maintainer';$m.authority='maintainers';$m.approvers=@('alice','bob');$m.approval_records=@([pscustomobject]@{identity='alice';role='maintainer';reference='reviews/rfc-0001.md#alice-approval'},[pscustomobject]@{identity='bob';role='maintainer';reference='reviews/rfc-0001.md#bob-approval'});$m.project_owner=$null;$m.decision_evidence_path=$null;$m.decision_evidence_anchors=@();$m.edge_reviews=@();$m.acceptance_evidence=@('reviews/rfc-0001.md#alice-approval','reviews/rfc-0001.md#bob-approval');$m.transition.evidence=@('reviews/rfc-0001.md#alice-approval','reviews/rfc-0001.md#bob-approval')
$maintainerRoster=[pscustomobject]@{schema_version='1.0.0';maintainers=@([pscustomobject]@{identity='alice';roles=@('maintainer');evidence='local'},[pscustomobject]@{identity='bob';roles=@('maintainer');evidence='local'})}
Invoke-AcceptanceCase 'maintainer route' $maintainer $maintainerRoster $true $null
$oneApproval=Copy-TestObject $maintainer;$oneApproval.rfc.current_foundation_rfc.approvers=@('alice')
Invoke-AcceptanceCase 'maintainer route needs two approvals' $oneApproval $maintainerRoster $false $null 'requires two distinct approvals'
$placeholderApproval=Copy-TestObject $maintainer;$placeholderApproval.rfc.current_foundation_rfc.approval_records[0].reference='placeholder';$placeholderApproval.rfc.current_foundation_rfc.acceptance_evidence[0]='placeholder';$placeholderApproval.rfc.current_foundation_rfc.transition.evidence[0]='placeholder'
Invoke-AcceptanceCase 'maintainer route rejects placeholder evidence' $placeholderApproval $maintainerRoster $false $null 'must use an HTTPS review URL or stable repository reference'
$duplicateApproval=Copy-TestObject $maintainer;$duplicateApproval.rfc.current_foundation_rfc.approval_records[1].reference=$duplicateApproval.rfc.current_foundation_rfc.approval_records[0].reference;$duplicateApproval.rfc.current_foundation_rfc.acceptance_evidence=@($duplicateApproval.rfc.current_foundation_rfc.approval_records[0].reference);$duplicateApproval.rfc.current_foundation_rfc.transition.evidence=@($duplicateApproval.rfc.current_foundation_rfc.approval_records[0].reference)
Invoke-AcceptanceCase 'maintainer route rejects duplicate evidence' $duplicateApproval $maintainerRoster $false $null 'references must be distinct'
$unboundApproval=Copy-TestObject $maintainer;$unboundApproval.rfc.current_foundation_rfc.approval_records[1].identity='mallory'
Invoke-AcceptanceCase 'maintainer route rejects unbound identity' $unboundApproval $maintainerRoster $false $null 'Maintainer approval identities mismatch'
$unboundLedger=Copy-TestObject $maintainer;$unboundLedger.rfc.current_foundation_rfc.transition.evidence=@('reviews/rfc-0001.md#alice-approval','reviews/rfc-0001.md#different')
Invoke-AcceptanceCase 'maintainer route rejects evidence unbound from ledger' $unboundLedger $maintainerRoster $false $null 'ledger evidence.*mismatch'
$missingApprovalFile=Copy-TestObject $maintainer;$missingApprovalFile.rfc.current_foundation_rfc.approval_records[0].reference='reviews/missing.md#alice-approval';$missingApprovalFile.rfc.current_foundation_rfc.acceptance_evidence[0]='reviews/missing.md#alice-approval';$missingApprovalFile.rfc.current_foundation_rfc.transition.evidence[0]='reviews/missing.md#alice-approval'
Invoke-AcceptanceCase 'maintainer route rejects nonexistent approval file' $missingApprovalFile $maintainerRoster $false $null "Approval for 'alice' component 'missing.md' does not exist"
$missingApprovalAnchor=Copy-TestObject $maintainer;$missingApprovalAnchor.rfc.current_foundation_rfc.approval_records[0].reference='reviews/rfc-0001.md#missing';$missingApprovalAnchor.rfc.current_foundation_rfc.acceptance_evidence[0]='reviews/rfc-0001.md#missing';$missingApprovalAnchor.rfc.current_foundation_rfc.transition.evidence[0]='reviews/rfc-0001.md#missing'
Invoke-AcceptanceCase 'maintainer route rejects nonexistent approval anchor' $missingApprovalAnchor $maintainerRoster $false $null "Markdown anchor 'missing' does not identify"
$commitApproval = Copy-TestObject $maintainer
$approvedCommitMessage = "Approve RFC 0001`n`nApproval-Identity: alice`nApproval-Role: maintainer`nApproval-Disposition: approved"
Invoke-AcceptanceCase 'maintainer route accepts approved commit trailers' $commitApproval $maintainerRoster $true { param($root,$policy,$caseRoster) Set-TestMaintainerCommitApproval $root $policy $caseRoster $approvedCommitMessage }
$missingDispositionCommit = Copy-TestObject $maintainer
Invoke-AcceptanceCase 'maintainer route rejects missing approval disposition trailer' $missingDispositionCommit $maintainerRoster $false { param($root,$policy,$caseRoster) Set-TestMaintainerCommitApproval $root $policy $caseRoster "Approve RFC 0001`n`nApproval-Identity: alice`nApproval-Role: maintainer" } 'exactly one Approval-Disposition trailer'
$rejectedCommit = Copy-TestObject $maintainer
Invoke-AcceptanceCase 'maintainer route rejects rejected commit disposition' $rejectedCommit $maintainerRoster $false { param($root,$policy,$caseRoster) Set-TestMaintainerCommitApproval $root $policy $caseRoster "Reject RFC 0001`n`nApproval-Identity: alice`nApproval-Role: maintainer`nApproval-Disposition: rejected" } 'invalid Approval-Disposition'
$duplicateDispositionCommit = Copy-TestObject $maintainer
Invoke-AcceptanceCase 'maintainer route rejects duplicate approval disposition trailer' $duplicateDispositionCommit $maintainerRoster $false { param($root,$policy,$caseRoster) Set-TestMaintainerCommitApproval $root $policy $caseRoster "Approve RFC 0001`n`nApproval-Identity: alice`nApproval-Role: maintainer`nApproval-Disposition: approved`nApproval-Disposition: rejected" } 'exactly one Approval-Disposition trailer'
$duplicateIdentityCommit = Copy-TestObject $maintainer
Invoke-AcceptanceCase 'maintainer route rejects duplicate approval identity trailer' $duplicateIdentityCommit $maintainerRoster $false { param($root,$policy,$caseRoster) Set-TestMaintainerCommitApproval $root $policy $caseRoster "Approve RFC 0001`n`nApproval-Identity: alice`nApproval-Identity: mallory`nApproval-Role: maintainer`nApproval-Disposition: approved" } 'exactly one Approval-Identity trailer'
$supersededMaintainer = Copy-TestObject $maintainer; $supersededMaintainer.rfc.current_foundation_rfc.status='Superseded'; $supersededMaintainer.rfc.current_foundation_rfc.transition.from='Accepted'; $supersededMaintainer.rfc.current_foundation_rfc.transition.to='Superseded'; $supersededMaintainer.rfc.current_foundation_rfc.transition.evidence=@('docs/rfcs/0002-replacement.md'); $supersededMaintainer.rfc.current_foundation_rfc.superseded_by='0002'; $supersededMaintainer.rfc.current_foundation_rfc.supersession_evidence=@('docs/rfcs/0002-replacement.md')
Invoke-AcceptanceCase 'superseded authenticates maintainer acceptance history' $supersededMaintainer $maintainerRoster $true { param($root) Write-TestReplacementRfc $root }

$lead=Copy-TestObject $accepted
$l=$lead.rfc.current_foundation_rfc;$l.acceptance_route='project-lead-public-review';$l.authority='project-lead';$l.approvers=@();$l.approval_records=@([pscustomobject]@{identity='lead';role='project-lead';reference='https://reviews.moonbit-foundation.org/rfc/1#lead-approval'});$l.project_lead='lead';$l.project_owner=$null;$l.public_review_url='https://reviews.moonbit-foundation.org/rfc/1';$l.public_review_started_at='2026-07-01T00:00:00Z';$l.public_review_ended_at='2026-07-08T00:00:00Z';$l.public_review_evidence=[pscustomobject]@{location_reference='https://reviews.moonbit-foundation.org/rfc/1';opened=[pscustomobject]@{at='2026-07-01T00:00:00Z';reference='https://reviews.moonbit-foundation.org/rfc/1#opened'};closed=[pscustomobject]@{at='2026-07-08T00:00:00Z';reference='https://reviews.moonbit-foundation.org/rfc/1#closed'}};$l.decision_evidence_path=$null;$l.decision_evidence_anchors=@();$l.edge_reviews=@();$l.acceptance_evidence=@('https://reviews.moonbit-foundation.org/rfc/1','https://reviews.moonbit-foundation.org/rfc/1#opened','https://reviews.moonbit-foundation.org/rfc/1#closed','https://reviews.moonbit-foundation.org/rfc/1#lead-approval');$l.transition.evidence=@($l.acceptance_evidence)
$l.external_evidence_verifications=@(
  [pscustomobject]@{reference='https://reviews.moonbit-foundation.org/rfc/1';verification_reference='reviews/external-verification.md#review-location';verified_at='2026-07-08T01:00:00Z';verified_by='test-reviewer';method='manual'},
  [pscustomobject]@{reference='https://reviews.moonbit-foundation.org/rfc/1#opened';verification_reference='reviews/external-verification.md#review-opened';verified_at='2026-07-08T01:00:00Z';verified_by='test-reviewer';method='manual'},
  [pscustomobject]@{reference='https://reviews.moonbit-foundation.org/rfc/1#closed';verification_reference='reviews/external-verification.md#review-closed';verified_at='2026-07-08T01:00:00Z';verified_by='test-reviewer';method='manual'},
  [pscustomobject]@{reference='https://reviews.moonbit-foundation.org/rfc/1#lead-approval';verification_reference='reviews/external-verification.md#lead-approval-verification';verified_at='2026-07-08T01:00:00Z';verified_by='test-reviewer';method='manual'}
)
$leadRoster=[pscustomobject]@{schema_version='1.0.0';maintainers=@([pscustomobject]@{identity='lead';roles=@('maintainer','project-lead');evidence='local'})}
Invoke-AcceptanceCase 'project lead seven-day route' $lead $leadRoster $true $null
$supersededLead = Copy-TestObject $lead; $supersededLead.rfc.current_foundation_rfc.status='Superseded'; $supersededLead.rfc.current_foundation_rfc.transition.from='Accepted'; $supersededLead.rfc.current_foundation_rfc.transition.to='Superseded'; $supersededLead.rfc.current_foundation_rfc.transition.evidence=@('docs/rfcs/0002-replacement.md'); $supersededLead.rfc.current_foundation_rfc.superseded_by='0002'; $supersededLead.rfc.current_foundation_rfc.supersession_evidence=@('docs/rfcs/0002-replacement.md')
Invoke-AcceptanceCase 'superseded authenticates project-lead review history' $supersededLead $leadRoster $true { param($root) Write-TestReplacementRfc $root }
$reservedLead = ((Copy-TestObject $lead | ConvertTo-Json -Depth 30).Replace('reviews.moonbit-foundation.org','reviews.invalid') | ConvertFrom-Json -DateKind String)
Invoke-AcceptanceCase 'project lead rejects reserved invalid HTTPS host' $reservedLead $leadRoster $false $null 'reserved non-evidentiary HTTPS host'
$exampleLead = ((Copy-TestObject $lead | ConvertTo-Json -Depth 30).Replace('reviews.moonbit-foundation.org','example.com') | ConvertFrom-Json -DateKind String)
Invoke-AcceptanceCase 'project lead rejects reserved example HTTPS host' $exampleLead $leadRoster $false $null 'placeholder evidence|reserved non-evidentiary HTTPS host'
$missingExternalVerification = Copy-TestObject $lead; $missingExternalVerification.rfc.current_foundation_rfc.external_evidence_verifications=@($missingExternalVerification.rfc.current_foundation_rfc.external_evidence_verifications | Select-Object -Skip 1)
Invoke-AcceptanceCase 'project lead requires external verification record' $missingExternalVerification $leadRoster $false $null 'requires exactly one verification record'
$futureExternalVerification = Copy-TestObject $lead; $futureExternalVerification.rfc.current_foundation_rfc.external_evidence_verifications[0].verified_at='2099-01-01T00:00:00Z'
Invoke-AcceptanceCase 'project lead rejects future external verification' $futureExternalVerification $leadRoster $false $null 'verification timestamp must have elapsed'
$missingVerificationAnchor = Copy-TestObject $lead; $missingVerificationAnchor.rfc.current_foundation_rfc.external_evidence_verifications[0].verification_reference='reviews/external-verification.md#missing'
Invoke-AcceptanceCase 'project lead rejects missing verification anchor' $missingVerificationAnchor $leadRoster $false $null 'Markdown anchor.*does not identify'
$leadMissingLocation=Copy-TestObject $lead;$leadMissingLocation.rfc.current_foundation_rfc.acceptance_evidence=@($leadMissingLocation.rfc.current_foundation_rfc.acceptance_evidence|Where-Object{$_ -cne 'https://reviews.moonbit-foundation.org/rfc/1'});$leadMissingLocation.rfc.current_foundation_rfc.transition.evidence=@($leadMissingLocation.rfc.current_foundation_rfc.acceptance_evidence)
Invoke-AcceptanceCase 'project lead binds review location in ledger' $leadMissingLocation $leadRoster $false $null 'Project-lead acceptance evidence count mismatch'
$leadMissingOpen=Copy-TestObject $lead;$leadMissingOpen.rfc.current_foundation_rfc.acceptance_evidence=@($leadMissingOpen.rfc.current_foundation_rfc.acceptance_evidence|Where-Object{$_ -cne 'https://reviews.moonbit-foundation.org/rfc/1#opened'});$leadMissingOpen.rfc.current_foundation_rfc.transition.evidence=@($leadMissingOpen.rfc.current_foundation_rfc.acceptance_evidence)
Invoke-AcceptanceCase 'project lead binds review opening in ledger' $leadMissingOpen $leadRoster $false $null 'Project-lead acceptance evidence count mismatch'
$leadMissingClose=Copy-TestObject $lead;$leadMissingClose.rfc.current_foundation_rfc.acceptance_evidence=@($leadMissingClose.rfc.current_foundation_rfc.acceptance_evidence|Where-Object{$_ -cne 'https://reviews.moonbit-foundation.org/rfc/1#closed'});$leadMissingClose.rfc.current_foundation_rfc.transition.evidence=@($leadMissingClose.rfc.current_foundation_rfc.acceptance_evidence)
Invoke-AcceptanceCase 'project lead binds review closing in ledger' $leadMissingClose $leadRoster $false $null 'Project-lead acceptance evidence count mismatch'
$short=Copy-TestObject $lead;$short.rfc.current_foundation_rfc.public_review_ended_at='2026-07-07T00:00:00Z';$short.rfc.current_foundation_rfc.public_review_evidence.closed.at='2026-07-07T00:00:00Z'
Invoke-AcceptanceCase 'project lead route needs seven elapsed days' $short $leadRoster $false $null 'requires seven elapsed days'
$boundary=Copy-TestObject $lead;$boundary.rfc.current_foundation_rfc.public_review_started_at='2026-07-09T00:00:00+00:00';$boundary.rfc.current_foundation_rfc.public_review_evidence.opened.at='2026-07-09T00:00:00+00:00';$boundary.rfc.current_foundation_rfc.public_review_ended_at='2026-07-16T00:00:00+00:00';$boundary.rfc.current_foundation_rfc.public_review_evidence.closed.at='2026-07-16T00:00:00+00:00'
Invoke-AcceptanceCase 'project lead exact seven-day elapsed boundary' $boundary $leadRoster $true $null
$futureStart=Copy-TestObject $lead;$futureStart.rfc.current_foundation_rfc.public_review_started_at='2099-01-01T00:00:00Z';$futureStart.rfc.current_foundation_rfc.public_review_evidence.opened.at='2099-01-01T00:00:00Z';$futureStart.rfc.current_foundation_rfc.public_review_ended_at='2099-01-08T00:00:00Z';$futureStart.rfc.current_foundation_rfc.public_review_evidence.closed.at='2099-01-08T00:00:00Z'
Invoke-AcceptanceCase 'project lead rejects future review window' $futureStart $leadRoster $false $null 'end must have elapsed'
$futureEnd=Copy-TestObject $lead;$futureEnd.rfc.current_foundation_rfc.public_review_started_at='2026-07-10T00:00:00Z';$futureEnd.rfc.current_foundation_rfc.public_review_evidence.opened.at='2026-07-10T00:00:00Z';$futureEnd.rfc.current_foundation_rfc.public_review_ended_at='2026-07-17T00:00:00Z';$futureEnd.rfc.current_foundation_rfc.public_review_evidence.closed.at='2026-07-17T00:00:00Z'
Invoke-AcceptanceCase 'project lead rejects future review end' $futureEnd $leadRoster $false $null 'end must have elapsed'
$reversed=Copy-TestObject $lead;$reversed.rfc.current_foundation_rfc.public_review_started_at='2026-07-10T00:00:00Z';$reversed.rfc.current_foundation_rfc.public_review_evidence.opened.at='2026-07-10T00:00:00Z';$reversed.rfc.current_foundation_rfc.public_review_ended_at='2026-07-09T00:00:00Z';$reversed.rfc.current_foundation_rfc.public_review_evidence.closed.at='2026-07-09T00:00:00Z'
Invoke-AcceptanceCase 'project lead rejects reversed window' $reversed $leadRoster $false $null 'start must not follow its end'
$malformedOffset=Copy-TestObject $lead;$malformedOffset.rfc.current_foundation_rfc.public_review_started_at='2026-07-01T00:00:00+99:00';$malformedOffset.rfc.current_foundation_rfc.public_review_evidence.opened.at='2026-07-01T00:00:00+99:00'
Invoke-AcceptanceCase 'project lead rejects malformed offset' $malformedOffset $leadRoster $false $null 'not a valid timestamp'

$mismatch=Copy-TestObject $accepted
Invoke-AcceptanceCase 'RFC status mismatch' $mismatch $roster $false { param($root) '# RFC 0001`n`n- **Status:** Proposed' | Set-Content -LiteralPath (Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md') } 'RFC header status does not match policy'
$indexMismatch=Copy-TestObject $accepted
Invoke-AcceptanceCase 'RFC index status mismatch' $indexMismatch $roster $false { param($root) '| [RFC 0001](0001-moonbit-native-foundation.md) | Foundation | Proposed | Charter |' | Set-Content -LiteralPath (Join-Path $root 'docs/rfcs/README.md') } 'index row must link the canonical RFC and match policy status'
$alternateRfc=Copy-TestObject $accepted;$alternateRfc.rfc.current_foundation_rfc.path='docs/rfcs/alternate.md'
Invoke-AcceptanceCase 'RFC policy path is canonical' $alternateRfc $roster $false { param($root) Copy-Item (Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md') (Join-Path $root 'docs/rfcs/alternate.md') } 'Foundation RFC policy path differs'
$alternateRoster=Copy-TestObject $accepted;$alternateRoster.rfc.maintainer_roster_path='policy/alternate.json'
Invoke-AcceptanceCase 'roster policy path is canonical' $alternateRoster $roster $false { param($root,$p,$r) Write-TestJson (Join-Path $root 'policy/alternate.json') $r } 'maintainer roster path differs'
$wrongIndexLink=Copy-TestObject $accepted
Invoke-AcceptanceCase 'RFC index link is canonical' $wrongIndexLink $roster $false { param($root) $path=Join-Path $root 'docs/rfcs/README.md'; (Get-Content -Raw $path).Replace('(0001-moonbit-native-foundation.md)','(alternate.md)') | Set-Content -LiteralPath $path } 'index row must link the canonical RFC'
$fileAnchorMissing=Copy-TestObject $accepted
Invoke-AcceptanceCase 'decision file missing anchor' $fileAnchorMissing $roster $false { param($root) (Get-Content -Raw (Join-Path $root 'docs/governance/decisions/0001-sole-owner-bootstrap.md')).Replace('## Edge review results','## Missing') | Set-Content -LiteralPath (Join-Path $root 'docs/governance/decisions/0001-sole-owner-bootstrap.md') } 'lacks required anchor'
$artifactEdgeMissing=Copy-TestObject $accepted
Invoke-AcceptanceCase 'decision file missing edge record' $artifactEdgeMissing $roster $false { param($root) (Get-Content -Raw (Join-Path $root 'docs/governance/decisions/0001-sole-owner-bootstrap.md')).Replace('- `EDGE-GOV-02-UNCLASSIFIED`: Completed. Disposition: no-omission-found.','') | Set-Content -LiteralPath (Join-Path $root 'docs/governance/decisions/0001-sole-owner-bootstrap.md') } 'does not bind.*EDGE-GOV-02'
$ownerInstructionMoved=Copy-TestObject $accepted
Invoke-AcceptanceCase 'owner instruction must remain in named section' $ownerInstructionMoved $roster $false { param($root) (Get-Content -Raw (Join-Path $root 'docs/governance/decisions/0001-sole-owner-bootstrap.md')).Replace('> 现在只有我一个人开发，跳过','> instruction moved').Replace('Conditional preauthorization for RFC 0001.','Conditional preauthorization for RFC 0001.`n`n> 现在只有我一个人开发，跳过') | Set-Content -LiteralPath (Join-Path $root 'docs/governance/decisions/0001-sole-owner-bootstrap.md') } 'does not preserve.*named sections'
$authorizationMissing=Copy-TestObject $accepted
Invoke-AcceptanceCase 'authorization section requires canonical conditions' $authorizationMissing $roster $false { param($root) $path=Join-Path $root 'docs/governance/decisions/0001-sole-owner-bootstrap.md'; (Get-Content -Raw $path).Replace('- `AUTH-NO-LATER-APPROVAL`: The recorded owner instruction is consumed; no later approval may be synthesized.','Unrelated authorization text.') | Set-Content -LiteralPath $path } 'authorization section lacks canonical condition'

$arrangeFailureWasRejected = $false
try {
  Invoke-AcceptanceCase 'harness arrange failure sentinel' $accepted $roster $false { throw 'ARRANGE-SENTINEL' } 'validation-pattern-that-must-not-match'
} catch {
  $arrangeFailureWasRejected = $_.Exception.Message -ceq 'ARRANGE-SENTINEL'
}
if (-not $arrangeFailureWasRejected) { throw 'Acceptance harness counted an arrange/setup exception as a successful negative validation.' }
Write-Host 'PASS: harness rejects arrange/setup exceptions'

$externalRoster = Join-Path ([System.IO.Path]::GetTempPath()) ('mnf-roster-external-' + [guid]::NewGuid().ToString('N') + '.json')
$externalRfc = Join-Path ([System.IO.Path]::GetTempPath()) ('mnf-rfc-external-' + [guid]::NewGuid().ToString('N') + '.md')
$externalReplacement = Join-Path ([System.IO.Path]::GetTempPath()) ('mnf-replacement-external-' + [guid]::NewGuid().ToString('N') + '.md')
try {
  Invoke-AcceptanceCase 'canonical roster rejects symlink' $accepted $roster $false {
    param($root)
    $canonical=Join-Path $root 'policy/maintainers.json';Copy-Item $canonical $externalRoster;Remove-Item $canonical;[void](New-Item -ItemType SymbolicLink -Path $canonical -Target $externalRoster -ErrorAction Stop)
  } 'Canonical maintainer roster component.*symbolic link or reparse point'
  Invoke-AcceptanceCase 'canonical RFC rejects symlink' $accepted $roster $false {
    param($root)
    $canonical=Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md';Copy-Item $canonical $externalRfc;Remove-Item $canonical;[void](New-Item -ItemType SymbolicLink -Path $canonical -Target $externalRfc -ErrorAction Stop)
  } 'Canonical foundation RFC component.*symbolic link or reparse point'
  Invoke-AcceptanceCase 'replacement RFC rejects symlink' $superseded $roster $false {
    param($root)
    Write-TestReplacementRfc $root; $replacement=Join-Path $root 'docs/rfcs/0002-replacement.md'; Copy-Item $replacement $externalReplacement; Remove-Item $replacement; [void](New-Item -ItemType SymbolicLink -Path $replacement -Target $externalReplacement -ErrorAction Stop)
  } "Superseded RFC replacement '0002' component.*symbolic link or reparse point"
} finally {
  Remove-Item $externalRoster,$externalRfc,$externalReplacement -Force -ErrorAction SilentlyContinue
}

$linkRoot = New-TestRepository
$externalDecision = Join-Path ([System.IO.Path]::GetTempPath()) ("mnf-rfc-external-" + [guid]::NewGuid().ToString('N') + '.md')
try {
  Write-TestState $linkRoot $accepted $roster
  $canonicalDecision = Join-Path $linkRoot 'docs/governance/decisions/0001-sole-owner-bootstrap.md'
  Copy-Item -LiteralPath $canonicalDecision -Destination $externalDecision
  Remove-Item -LiteralPath $canonicalDecision -Force
  [void](New-Item -ItemType SymbolicLink -Path $canonicalDecision -Target $externalDecision -ErrorAction Stop)
  $linkAccepted = $true
  $linkFailure = $null
  try { Assert-RfcAcceptanceState -Policy $accepted -RosterPath (Join-Path $linkRoot 'policy/maintainers.json') -RepositoryRoot $linkRoot }
  catch { $linkAccepted = $false; $linkFailure = $_.Exception.Message }
  if ($linkAccepted) { throw 'RFC acceptance case canonical decision symlink escape expected rejection but was accepted.' }
  if ($linkFailure -cnotmatch 'symbolic link or reparse point') { throw "RFC acceptance case canonical decision symlink escape rejected for the wrong reason: $linkFailure" }
  Write-Host 'PASS: canonical decision symlink escape'
} finally {
  Remove-Item -LiteralPath $linkRoot -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $externalDecision -Force -ErrorAction SilentlyContinue
}

Write-Host 'RFC acceptance route matrix passed.'
