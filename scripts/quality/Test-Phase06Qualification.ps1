[CmdletBinding()]
param([switch]$LedgerOnly)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')

function Assert-ExactSequence {
  param([string]$Label, [object[]]$Actual, [object[]]$Expected)
  if (($Actual -join "`n") -cne ($Expected -join "`n")) {
    throw "$Label mismatch.`nExpected: $($Expected -join ', ')`nActual: $($Actual -join ', ')"
  }
}

function Assert-Unique {
  param([string]$Label, [object[]]$Values)
  if (@($Values | Sort-Object -Unique).Count -ne $Values.Count) { throw "$Label contains duplicates." }
}

function Get-PlanFrontmatter {
  param([string]$Plan)
  $path = Join-Path $repoRoot ".planning/phases/06-namespace-authority-and-compatibility-contract/$Plan-PLAN.md"
  $text = Get-Content -LiteralPath $path -Raw
  $match = [regex]::Match($text, '\A---\r?\n(?<body>.*?)\r?\n---', [Text.RegularExpressions.RegexOptions]::Singleline)
  if (-not $match.Success) { throw "$Plan has no closed frontmatter." }
  return $match.Groups['body'].Value
}

function Get-Declarations {
  param([string]$Plan, [ValidateSet('EDGE','PROH')][string]$Kind)
  $frontmatter = Get-PlanFrontmatter -Plan $Plan
  $pattern = if ($Kind -ceq 'EDGE') {
    '\{\s*id:\s*(?<id>EDGE-[A-Z0-9-]+),'
  } else {
    '\{\s*id:\s*(?<id>PROH-[A-Z0-9-]+),\s*requirement_id:\s*(?<requirement>[A-Z]+-[0-9]+),'
  }
  return @([regex]::Matches($frontmatter, $pattern) | ForEach-Object {
    [pscustomobject]@{ id = $_.Groups['id'].Value; requirement_id = $_.Groups['requirement'].Value; plan = $Plan }
  })
}

$ledgerPath = Join-Path $repoRoot 'release/qualification/phase-06-requirements.json'
$ledger = Read-ReleaseJson -Path $ledgerPath
$expectedRequirements = @('REG-01','REG-02','REG-03','COMP-01','COMP-02','COMP-03','COMP-04','PROV-03')
$expectedEdges = @(
  'EDGE-REG-01-BOUNDARY','EDGE-REG-01-ADJACENCY','EDGE-REG-01-EMPTY','EDGE-REG-01-ENCODING','EDGE-REG-01-ORDERING','EDGE-REG-01-PRECISION',
  'EDGE-REG-02-UNCLASSIFIED','EDGE-REG-03-UNCLASSIFIED','EDGE-COMP-01-ADJACENCY','EDGE-COMP-01-EMPTY','EDGE-COMP-01-ENCODING','EDGE-COMP-01-ORDERING',
  'EDGE-COMP-02-ADJACENCY','EDGE-COMP-02-EMPTY','EDGE-COMP-02-ORDERING','EDGE-COMP-03-BOUNDARY','EDGE-COMP-03-PRECISION','EDGE-COMP-03-CONCURRENCY',
  'EDGE-COMP-04-UNCLASSIFIED','EDGE-PROV-03-ADJACENCY','EDGE-PROV-03-EMPTY','EDGE-PROV-03-ORDERING'
)
$expectedProhibitions = @(
  'PROH-REG-CREDENTIALS','PROH-REG-MUTATION','PROH-COMP-SEMANTICS','PROH-PROV-POLICY-OVERRIDE',
  'PROH-IDENTITY-HISTORY-REWRITE','PROH-REPOSITORY-LIVE-CLAIM','PROH-PHASE06-HISTORY'
)

Assert-ReleaseClosedProperties -Label 'Phase 6 ledger' -Object $ledger -Expected @(
  'schema_version','phase','required_entrypoint','selectors','requirements','artifact_contracts','edge_probes','prohibitions','evidence','phase_07_handoff'
)
if ($ledger.schema_version -cne '1.0.0' -or $ledger.phase -cne '06') { throw 'Phase 6 ledger identity drifted.' }
Assert-ExactSequence 'Phase 6 requirements' @($ledger.requirements.PSObject.Properties.Name) $expectedRequirements
Assert-ExactSequence 'Phase 6 selector proofs' @($ledger.selectors.proves | ForEach-Object { [string]$_ }) $expectedRequirements
Assert-Unique 'Phase 6 selector IDs' @($ledger.selectors.id)

$selectorById = @{}
foreach ($selector in @($ledger.selectors)) {
  Assert-ReleaseClosedProperties -Label "selector $($selector.id)" -Object $selector -Expected (@('id','focused_command','proves','rule_ids','artifact_ids') + $(if ($selector.PSObject.Properties['expected_outcome']) { 'expected_outcome' }))
  if (@($selector.proves).Count -ne 1) { throw "Selector '$($selector.id)' must prove exactly one requirement." }
  $selectorById[[string]$selector.id] = $selector
  $requirement = [string]$selector.proves[0]
  Assert-ExactSequence "reverse requirement $requirement" @($ledger.requirements.$requirement) @([string]$selector.id)
}

$artifactById = @{}
Assert-Unique 'artifact IDs' @($ledger.artifact_contracts.id)
foreach ($artifact in @($ledger.artifact_contracts)) {
  Assert-ReleaseClosedProperties -Label "artifact $($artifact.id)" -Object $artifact -Expected @('id','tracked_path','sha256')
  if ([string]$artifact.sha256 -cnotmatch '^[0-9a-f]{64}$') { throw "Artifact '$($artifact.id)' has an invalid digest." }
  $path = Join-Path $repoRoot ([string]$artifact.tracked_path)
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Artifact '$($artifact.id)' is absent." }
  Assert-ReleaseHashedArtifact -Path $path -ExpectedSha256 ([string]$artifact.sha256)
  $artifactById[[string]$artifact.id] = $artifact
}
if ([string]$artifactById['phase-01-source-audit'].sha256 -cne '52f118333892cfe1044b8105a6ea5d03f1ab087d3f7875d13b79c4e5b7640a7a') {
  throw 'Immutable Phase 1 source-audit digest is not bound exactly.'
}

$planOrder = @('06-01','06-02','06-03','06-05','06-07','06-10','06-11','06-06')
$declaredEdges = @($planOrder | ForEach-Object { Get-Declarations -Plan $_ -Kind EDGE })
$declaredProhibitions = @($planOrder | ForEach-Object { Get-Declarations -Plan $_ -Kind PROH })
Assert-Unique 'frontmatter edge declarations' @($declaredEdges.id)
Assert-Unique 'frontmatter prohibition declarations' @($declaredProhibitions.id)
Assert-ExactSequence 'declared edge inventory' @($declaredEdges.id) $expectedEdges
Assert-ExactSequence 'declared prohibition inventory' @($declaredProhibitions.id) $expectedProhibitions
Assert-ExactSequence 'ledger edge inventory' @($ledger.edge_probes.id) $expectedEdges
Assert-ExactSequence 'ledger prohibition inventory' @($ledger.prohibitions.id) $expectedProhibitions

$evidenceById = @{}
Assert-Unique 'evidence IDs' @($ledger.evidence.id)
Assert-ExactSequence 'evidence inventory' @($ledger.evidence.id) @($expectedEdges + $expectedProhibitions)
foreach ($evidence in @($ledger.evidence)) {
  Assert-ReleaseClosedProperties -Label "evidence $($evidence.id)" -Object $evidence -Expected @('id','status')
  if ($evidence.status -cne 'pass') { throw "Evidence '$($evidence.id)' is not passing." }
  $evidenceById[[string]$evidence.id] = $evidence
}

foreach ($record in @($ledger.edge_probes) + @($ledger.prohibitions)) {
  Assert-ReleaseClosedProperties -Label "coverage $($record.id)" -Object $record -Expected @('id','requirement_id','selector_id','rule_id','artifact_id','evidence_id')
  $selector = $selectorById[[string]$record.selector_id]
  if ($null -eq $selector) { throw "Coverage '$($record.id)' references an unknown selector." }
  if ([string]$selector.proves[0] -cne [string]$record.requirement_id) { throw "Coverage '$($record.id)' crosses requirement ownership." }
  if (@($selector.rule_ids) -cnotcontains [string]$record.rule_id) { throw "Coverage '$($record.id)' references an unknown selector rule." }
  if (@($selector.artifact_ids) -cnotcontains [string]$record.artifact_id -or -not $artifactById.ContainsKey([string]$record.artifact_id)) { throw "Coverage '$($record.id)' references an unknown artifact." }
  if ([string]$record.evidence_id -cne [string]$record.id -or -not $evidenceById.ContainsKey([string]$record.evidence_id)) { throw "Coverage '$($record.id)' lacks same-ID passing evidence." }
}

$declaredProhibitionById = @{}; foreach ($item in $declaredProhibitions) { $declaredProhibitionById[$item.id] = $item }
foreach ($record in @($ledger.prohibitions)) {
  $source = $declaredProhibitionById[[string]$record.id]
  if ($null -eq $source -or [string]$source.requirement_id -cne [string]$record.requirement_id) { throw "Prohibition '$($record.id)' does not reciprocate its declaration source." }
}
if ($declaredProhibitionById['PROH-IDENTITY-HISTORY-REWRITE'].plan -cne '06-07') { throw '06-07 is not the sole identity-history declaration owner.' }
if ($declaredProhibitionById['PROH-REPOSITORY-LIVE-CLAIM'].plan -cne '06-10') { throw '06-10 is not the sole repository-liveness declaration owner.' }
if (@(Get-Declarations -Plan '06-11' -Kind PROH).Count -ne 0) { throw '06-11 must contribute verification only, not prohibition declarations.' }
$plan11 = Get-PlanFrontmatter -Plan '06-11'
$summary11Path = Join-Path $repoRoot '.planning/phases/06-namespace-authority-and-compatibility-contract/06-11-SUMMARY.md'
$summary11 = Get-Content -LiteralPath $summary11Path -Raw
if ($plan11 -cnotmatch '22 edge IDs and seven uniquely owned prohibitions' -or $summary11 -cnotmatch '105 old-identity occurrences' -or
    $summary11 -cnotmatch 'preserved all 22 edge IDs, seven prohibition owners') { throw '06-11 verification contribution is missing.' }
Assert-ReleaseHashedArtifact -Path $summary11Path -ExpectedSha256 '5fc8389f8cb163a3847bcbc70b3ca6897b82d4d7d96517a778396fdf5567cc88'
$identitySource = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/quality/Test-IdentityMigration.ps1') -Raw
if ($identitySource -cnotmatch '52f118333892cfe1' -or $identitySource -cnotmatch 'Records[.]Count -ne 105') { throw '06-11 occurrence-level history evidence is incomplete.' }
$repositorySource = Get-PlanFrontmatter -Plan '06-10'
if ($repositorySource -cnotmatch 'intended/unverified' -or $repositorySource -cnotmatch 'MUST NOT describe the intended GitHub repository') { throw 'Repository liveness is not bound to intended/unverified negative evidence.' }

$requirementsText = Get-Content -LiteralPath (Join-Path $repoRoot '.planning/REQUIREMENTS.md') -Raw
foreach ($id in $expectedRequirements) { if ($requirementsText -cnotmatch ('(?m)^- \[[ x]\] \*\*' + [regex]::Escape($id) + '\*\*:')) { throw "Requirement '$id' is absent from current requirements." } }
if ($requirementsText -cnotmatch '(?m)^- \[[ x]\] \*\*PROV-05\*\*:' -or $requirementsText -cnotmatch 'Phase 8') { throw 'PROV-05 is not exclusively deferred to Phase 8.' }

$ledgerRaw = Get-Content -LiteralPath $ledgerPath -Raw
foreach ($forbidden in @('dynamic_path','PROV-05','credential_path','authorization_header','cookie_path','token_path','publish:tchivs','resolve:tchivs','repository_verified_live','destructive_recovery_assumed')) {
  if ($ledgerRaw -cmatch [regex]::Escape($forbidden)) { throw "Ledger contains forbidden dynamic, credential, live-repository, destructive, or post-publication claim '$forbidden'." }
}
if ($ledger.phase_07_handoff -cnotmatch 'before any production mutation') { throw 'Phase 7 authenticated-publish seam handoff is missing.' }

Write-Host 'Phase 6 reciprocal ledger passed: 8 requirements, 22 edges, 7 prohibitions, exact declaration ownership, and content-addressed artifacts.'
