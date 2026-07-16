[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Assert-Policy.ps1')

function Copy-TestObject([object]$Value) {
  return ($Value | ConvertTo-Json -Depth 30 | ConvertFrom-Json)
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
  @'
# Decision 0001

## Owner instruction

> 现在只有我一个人开发，跳过

## Conversation context and interpretation

Conditional preauthorization for RFC 0001.

## Authorization and conditions

No second approval and no seven-day public review are claimed.

## Edge review results

Both mandatory edge reviews completed with no unresolved blocker.
'@ | Set-Content -LiteralPath (Join-Path $root 'docs/governance/decisions/0001-sole-owner-bootstrap.md') -Encoding utf8
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
    acceptance_route = $Route; authority = 'sole-project-owner'; approvers = @()
    project_lead = $null; project_owner = 'sole-project-owner'
    public_review_url = $null; public_review_started_at = $null; public_review_ended_at = $null
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
  $transition = $Policy.rfc.current_foundation_rfc.transition
  $evidence = @($transition.evidence) -join '; '
  @("# RFC 0001", "", "- **Status:** $status", "", "## Transition history", "", "| From | To | Evidence |", "|---|---|---|", "| $($transition.from) | $($transition.to) | $evidence |") | Set-Content -LiteralPath (Join-Path $Root 'docs/rfcs/0001-moonbit-native-foundation.md') -Encoding utf8
  @("# RFC index", "", "| RFC | Status |", "|---|---|", "| RFC 0001 | $status |") | Set-Content -LiteralPath (Join-Path $Root 'docs/rfcs/README.md') -Encoding utf8
  Write-TestJson (Join-Path $Root 'policy/maintainers.json') $Roster
}

function Invoke-AcceptanceCase([string]$Name, [object]$Policy, [object]$Roster, [bool]$ShouldPass, [scriptblock]$Arrange) {
  $root = New-TestRepository
  try {
    Write-TestState $root $Policy $Roster
    if ($Arrange) { & $Arrange $root $Policy $Roster }
    $passed = $true
    $failureMessage = $null
    try { Assert-RfcAcceptanceState -Policy $Policy -RosterPath (Join-Path $root 'policy/maintainers.json') -RepositoryRoot $root -Now ([DateTimeOffset]'2026-07-16T00:00:00Z') }
    catch { $passed = $false; $failureMessage = $_.Exception.Message }
    if ($passed -ne $ShouldPass) { throw "RFC acceptance case '$Name' expected pass=$ShouldPass but got pass=$passed. Validation result: $failureMessage" }
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
Invoke-AcceptanceCase 'accepted requires transition ledger row' $missingLedger $roster $false { param($root) '# RFC 0001`n`n- **Status:** Accepted' | Set-Content -LiteralPath (Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md') }
$illegalPrior = Copy-TestObject $accepted; $illegalPrior.rfc.current_foundation_rfc.transition.from='Draft'
Invoke-AcceptanceCase 'accepted rejects illegal prior state' $illegalPrior $roster $false $null
$implemented = Copy-TestObject $accepted; $implemented.rfc.current_foundation_rfc.status='Implemented'; $implemented.rfc.current_foundation_rfc.transition.from='Accepted'; $implemented.rfc.current_foundation_rfc.transition.to='Implemented'; $implemented.rfc.current_foundation_rfc.transition.evidence=@('commit:implementation','report:qualification'); $implemented.rfc.current_foundation_rfc.implementation_evidence=@('commit:implementation'); $implemented.rfc.current_foundation_rfc.qualification_evidence=@('report:qualification')
Invoke-AcceptanceCase 'implemented requires implementation evidence' $implemented $roster $true $null
$missingImplementation = Copy-TestObject $implemented; $missingImplementation.rfc.current_foundation_rfc.implementation_evidence=@(); $missingImplementation.rfc.current_foundation_rfc.transition.evidence=@('report:qualification')
Invoke-AcceptanceCase 'implemented rejects missing implementation evidence' $missingImplementation $roster $false $null
$superseded = Copy-TestObject $proposed; $superseded.rfc.current_foundation_rfc.status='Superseded'; $superseded.rfc.current_foundation_rfc.transition.from='Proposed'; $superseded.rfc.current_foundation_rfc.transition.to='Superseded'; $superseded.rfc.current_foundation_rfc.transition.evidence=@('docs/rfcs/0002-replacement.md'); $superseded.rfc.current_foundation_rfc.superseded_by='0002'; $superseded.rfc.current_foundation_rfc.supersession_evidence=@('docs/rfcs/0002-replacement.md')
Invoke-AcceptanceCase 'superseded requires existing replacement RFC' $superseded $roster $true { param($root) '# RFC 0002' | Set-Content -LiteralPath (Join-Path $root 'docs/rfcs/0002-replacement.md') }
Invoke-AcceptanceCase 'superseded rejects missing replacement RFC' $superseded $roster $false $null

$cases = @(
  @{ n='duplicate roster identity'; mutate={ param($p,$r) $r.maintainers=@($r.maintainers[0],(Copy-TestObject $r.maintainers[0])) } },
  @{ n='zero maintainers'; mutate={ param($p,$r) $r.maintainers=@() } },
  @{ n='multiple maintainers'; mutate={ param($p,$r) $r.maintainers += [pscustomobject]@{identity='other';roles=@('maintainer');evidence='local'} } },
  @{ n='owner mismatch'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.project_owner='other' } },
  @{ n='missing decision anchor'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.decision_evidence_anchors=@('owner-instruction') } },
  @{ n='drive rooted path'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.decision_evidence_path='C:\outside.md' } },
  @{ n='UNC rooted path'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.decision_evidence_path='\\server\share\outside.md' } },
  @{ n='parent traversal'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.decision_evidence_path='../outside.md' } },
  @{ n='sibling prefix escape'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.decision_evidence_path='../repo-escape/outside.md' } },
  @{ n='wrong decision artifact'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.decision_evidence_path='docs/governance/decisions/wrong.md' } },
  @{ n='missing edge review'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.edge_reviews=@($p.rfc.current_foundation_rfc.edge_reviews[0]) } },
  @{ n='legacy approver assertion'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.approvers=@('sole-project-owner') } },
  @{ n='legacy lead assertion'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.project_lead='sole-project-owner' } },
  @{ n='legacy review assertion'; mutate={ param($p,$r) $p.rfc.current_foundation_rfc.public_review_started_at='2026-07-01' } }
)
foreach ($case in $cases) {
  $policy = Copy-TestObject $accepted; $caseRoster = Copy-TestObject $roster
  & $case.mutate $policy $caseRoster
  Invoke-AcceptanceCase $case.n $policy $caseRoster $false $null
}

$maintainer = Copy-TestObject $accepted
$m=$maintainer.rfc.current_foundation_rfc; $m.acceptance_route='maintainer';$m.authority='maintainers';$m.approvers=@('alice','bob');$m.project_owner=$null;$m.decision_evidence_path=$null;$m.decision_evidence_anchors=@();$m.edge_reviews=@();$m.acceptance_evidence=@('approval:alice','approval:bob');$m.transition.evidence=@('approval:alice','approval:bob')
$maintainerRoster=[pscustomobject]@{schema_version='1.0.0';maintainers=@([pscustomobject]@{identity='alice';roles=@('maintainer');evidence='local'},[pscustomobject]@{identity='bob';roles=@('maintainer');evidence='local'})}
Invoke-AcceptanceCase 'maintainer route' $maintainer $maintainerRoster $true $null
$oneApproval=Copy-TestObject $maintainer;$oneApproval.rfc.current_foundation_rfc.approvers=@('alice')
Invoke-AcceptanceCase 'maintainer route needs two approvals' $oneApproval $maintainerRoster $false $null

$lead=Copy-TestObject $accepted
$l=$lead.rfc.current_foundation_rfc;$l.acceptance_route='project-lead-public-review';$l.authority='project-lead';$l.approvers=@();$l.project_lead='lead';$l.project_owner=$null;$l.public_review_url='https://example.invalid/review/1';$l.public_review_started_at='2026-07-01T00:00:00Z';$l.public_review_ended_at='2026-07-08T00:00:00Z';$l.decision_evidence_path=$null;$l.decision_evidence_anchors=@();$l.edge_reviews=@();$l.acceptance_evidence=@('https://example.invalid/review/1');$l.transition.evidence=@('https://example.invalid/review/1')
$leadRoster=[pscustomobject]@{schema_version='1.0.0';maintainers=@([pscustomobject]@{identity='lead';roles=@('maintainer','project-lead');evidence='local'})}
Invoke-AcceptanceCase 'project lead seven-day route' $lead $leadRoster $true $null
$short=Copy-TestObject $lead;$short.rfc.current_foundation_rfc.public_review_ended_at='2026-07-07T00:00:00Z'
Invoke-AcceptanceCase 'project lead route needs seven elapsed days' $short $leadRoster $false $null
$boundary=Copy-TestObject $lead;$boundary.rfc.current_foundation_rfc.public_review_started_at='2026-07-09T00:00:00+00:00';$boundary.rfc.current_foundation_rfc.public_review_ended_at='2026-07-16T00:00:00+00:00'
Invoke-AcceptanceCase 'project lead exact seven-day elapsed boundary' $boundary $leadRoster $true $null
$futureStart=Copy-TestObject $lead;$futureStart.rfc.current_foundation_rfc.public_review_started_at='2099-01-01T00:00:00Z';$futureStart.rfc.current_foundation_rfc.public_review_ended_at='2099-01-08T00:00:00Z'
Invoke-AcceptanceCase 'project lead rejects future review window' $futureStart $leadRoster $false $null
$futureEnd=Copy-TestObject $lead;$futureEnd.rfc.current_foundation_rfc.public_review_started_at='2026-07-10T00:00:00Z';$futureEnd.rfc.current_foundation_rfc.public_review_ended_at='2026-07-17T00:00:00Z'
Invoke-AcceptanceCase 'project lead rejects future review end' $futureEnd $leadRoster $false $null
$reversed=Copy-TestObject $lead;$reversed.rfc.current_foundation_rfc.public_review_started_at='2026-07-10T00:00:00Z';$reversed.rfc.current_foundation_rfc.public_review_ended_at='2026-07-09T00:00:00Z'
Invoke-AcceptanceCase 'project lead rejects reversed window' $reversed $leadRoster $false $null
$malformedOffset=Copy-TestObject $lead;$malformedOffset.rfc.current_foundation_rfc.public_review_started_at='2026-07-01T00:00:00+99:00'
Invoke-AcceptanceCase 'project lead rejects malformed offset' $malformedOffset $leadRoster $false $null

$mismatch=Copy-TestObject $accepted
Invoke-AcceptanceCase 'RFC status mismatch' $mismatch $roster $false { param($root) '# RFC 0001`n`n- **Status:** Proposed' | Set-Content -LiteralPath (Join-Path $root 'docs/rfcs/0001-moonbit-native-foundation.md') }
$indexMismatch=Copy-TestObject $accepted
Invoke-AcceptanceCase 'RFC index status mismatch' $indexMismatch $roster $false { param($root) '| RFC 0001 | Proposed |' | Set-Content -LiteralPath (Join-Path $root 'docs/rfcs/README.md') }
$fileAnchorMissing=Copy-TestObject $accepted
Invoke-AcceptanceCase 'decision file missing anchor' $fileAnchorMissing $roster $false { param($root) (Get-Content -Raw (Join-Path $root 'docs/governance/decisions/0001-sole-owner-bootstrap.md')).Replace('## Edge review results','## Missing') | Set-Content -LiteralPath (Join-Path $root 'docs/governance/decisions/0001-sole-owner-bootstrap.md') }

$linkRoot = New-TestRepository
$externalDecision = Join-Path ([System.IO.Path]::GetTempPath()) ("mnf-rfc-external-" + [guid]::NewGuid().ToString('N') + '.md')
try {
  Write-TestState $linkRoot $accepted $roster
  $canonicalDecision = Join-Path $linkRoot 'docs/governance/decisions/0001-sole-owner-bootstrap.md'
  Copy-Item -LiteralPath $canonicalDecision -Destination $externalDecision
  Remove-Item -LiteralPath $canonicalDecision -Force
  [void](New-Item -ItemType SymbolicLink -Path $canonicalDecision -Target $externalDecision -ErrorAction Stop)
  $linkAccepted = $true
  try { Assert-RfcAcceptanceState -Policy $accepted -RosterPath (Join-Path $linkRoot 'policy/maintainers.json') -RepositoryRoot $linkRoot }
  catch { $linkAccepted = $false }
  if ($linkAccepted) { throw 'RFC acceptance case canonical decision symlink escape expected rejection but was accepted.' }
  Write-Host 'PASS: canonical decision symlink escape'
} finally {
  Remove-Item -LiteralPath $linkRoot -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $externalDecision -Force -ErrorAction SilentlyContinue
}

Write-Host 'RFC acceptance route matrix passed.'
