Set-StrictMode -Version Latest

$toolchainHelper = Join-Path $PSScriptRoot 'Assert-Toolchain.ps1'
if (-not (Get-Command Read-QualityJson -ErrorAction SilentlyContinue)) {
  . $toolchainHelper
}

function Assert-Condition {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw $Message }
}

function Assert-ExactSet {
  param([string]$Label, [object[]]$Actual, [string[]]$Expected)
  $actualStrings = @($Actual | ForEach-Object { [string]$_ })
  $duplicates = @($actualStrings | Group-Object -CaseSensitive | Where-Object Count -ne 1)
  $duplicateNames = @($duplicates | ForEach-Object Name)
  Assert-Condition ($duplicates.Count -eq 0) "$Label contains duplicate value(s): $($duplicateNames -join ', ')."
  $actualSorted = @($actualStrings | Sort-Object -CaseSensitive)
  $expectedSorted = @($Expected | Sort-Object -CaseSensitive)
  Assert-Condition ($actualSorted.Count -eq $expectedSorted.Count) "$Label count mismatch: expected $($expectedSorted.Count), got $($actualSorted.Count)."
  for ($index = 0; $index -lt $expectedSorted.Count; $index++) {
    Assert-Condition ($actualSorted[$index] -ceq $expectedSorted[$index]) "$Label mismatch: expected [$($expectedSorted -join ', ')], got [$($actualSorted -join ', ')]."
  }
}

function Get-CompactTargetSet {
  param([string]$Value, [string]$Label)
  Assert-Condition (-not [string]::IsNullOrWhiteSpace($Value)) "$Label is empty."
  Assert-Condition ($Value -match '^\+[a-z0-9-]+(?:\+[a-z0-9-]+)*$') "$Label is not a compact target set: '$Value'."
  return @($Value.Split('+', [System.StringSplitOptions]::RemoveEmptyEntries))
}

function Assert-AcyclicDependencyGraph {
  param([object[]]$Modules, [object[]]$AllowedEdges)
  $moduleNames = @($Modules.name)
  $adjacency = @{}
  foreach ($name in $moduleNames) { $adjacency[$name] = [System.Collections.Generic.List[string]]::new() }
  $edgeKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
  foreach ($edge in $AllowedEdges) {
    $from = [string]$edge.from
    $to = [string]$edge.to
    Assert-Condition ($moduleNames -ccontains $from) "Dependency edge has unknown source '$from'."
    Assert-Condition ($moduleNames -ccontains $to) "Dependency edge has unknown destination '$to'."
    Assert-Condition ($from -cne $to) "Dependency graph contains self-edge '$from'."
    Assert-Condition ($edgeKeys.Add("$from->$to")) "Dependency graph contains duplicate edge '$from->$to'."
    $adjacency[$from].Add($to)
  }

  $visiting = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
  $visited = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
  function Visit-PolicyNode([string]$Name) {
    if ($visiting.Contains($Name)) { throw "Dependency graph contains a cycle at '$Name'." }
    if ($visited.Contains($Name)) { return }
    [void]$visiting.Add($Name)
    foreach ($next in $adjacency[$Name]) { Visit-PolicyNode $next }
    [void]$visiting.Remove($Name)
    [void]$visited.Add($Name)
  }
  foreach ($name in $moduleNames) { Visit-PolicyNode $name }

  foreach ($module in $Modules) {
    $declared = @($module.direct_dependencies)
    $allowed = @($AllowedEdges | Where-Object from -CEQ $module.name | ForEach-Object to)
    Assert-ExactSet "Allowed dependency edges for $($module.name)" $allowed $declared
  }
}

function Assert-NullOrEmpty {
  param([string]$Label, [object]$Value)
  $count = if ($null -eq $Value) { 0 } else { @($Value).Count }
  $text = if ($null -eq $Value) { '' } else { [string]$Value }
  Assert-Condition ($null -eq $Value -or $count -eq 0 -or [string]::IsNullOrWhiteSpace($text)) "$Label must be empty for this RFC state or route."
}

function Get-RequiredProperty {
  param([object]$Object, [string]$Name, [string]$Context)
  if ($Object -is [System.Collections.IDictionary]) {
    Assert-Condition ($Object.Contains($Name)) "$Context is missing required property '$Name'."
    return $Object[$Name]
  }
  $property = $Object.PSObject.Properties[$Name]
  Assert-Condition ($null -ne $property) "$Context is missing required property '$Name'."
  return $property.Value
}

function Get-RfcTransitionLedgerRow {
  param([string]$RfcText, [string]$From, [string]$To)
  $escapedFrom = [regex]::Escape($From)
  $escapedTo = [regex]::Escape($To)
  $match = [regex]::Match($RfcText, "(?m)^\|\s*$escapedFrom\s*\|\s*$escapedTo\s*\|[^\r\n]+\|\s*$")
  Assert-Condition $match.Success "RFC transition ledger lacks exact '$From -> $To' row."
  return $match.Value
}

function Get-RfcTransitionLedgerRows {
  param([string]$RfcText)
  $rows = [System.Collections.Generic.List[object]]::new()
  foreach ($match in [regex]::Matches($RfcText, '(?m)^\|\s*(?<from>[^|]+?)\s*\|\s*(?<to>[^|]+?)\s*\|\s*(?<evidence>[^\r\n|]+?)\s*\|\s*$')) {
    $from = $match.Groups['from'].Value.Trim()
    $to = $match.Groups['to'].Value.Trim()
    if ($from -ceq 'From' -or $from -cmatch '^-+$') { continue }
    $rows.Add([pscustomobject]@{ from=$from; to=$to; evidence=$match.Groups['evidence'].Value.Trim(); text=$match.Value })
  }
  return @($rows)
}

function Assert-RfcLifecycleLedger {
  param([object]$Rfc, [string]$RfcText)
  $status = [string]$Rfc.status
  $latestFrom = [string]$Rfc.transition.from
  $expectedPairs = [System.Collections.Generic.List[object]]::new()
  $expectedPairs.Add([pscustomobject]@{ from='—'; to='Draft' })
  if ($status -cne 'Draft' -and -not ($status -ceq 'Rejected' -and $latestFrom -ceq 'Draft')) {
    $expectedPairs.Add([pscustomobject]@{ from='Draft'; to='Proposed' })
  }
  $hasAcceptedHistory = $status -in @('Accepted','Implemented') -or ($status -ceq 'Superseded' -and $latestFrom -in @('Accepted','Implemented'))
  $hasImplementedHistory = $status -ceq 'Implemented' -or ($status -ceq 'Superseded' -and $latestFrom -ceq 'Implemented')
  if ($hasAcceptedHistory) { $expectedPairs.Add([pscustomobject]@{ from='Proposed'; to='Accepted' }) }
  if ($hasImplementedHistory) { $expectedPairs.Add([pscustomobject]@{ from='Accepted'; to='Implemented' }) }
  if ($status -in @('Rejected','Superseded')) { $expectedPairs.Add([pscustomobject]@{ from=$latestFrom; to=$status }) }

  $rows = @(Get-RfcTransitionLedgerRows -RfcText $RfcText)
  Assert-Condition ($rows.Count -eq $expectedPairs.Count) "RFC transition ledger row count mismatch: expected $($expectedPairs.Count), got $($rows.Count)."
  for ($index=0; $index -lt $expectedPairs.Count; $index++) {
    $expected = $expectedPairs[$index]
    $actual = $rows[$index]
    Assert-Condition ($actual.from -ceq $expected.from -and $actual.to -ceq $expected.to) "RFC transition ledger is not a complete ordered chain at row $($index + 1): expected '$($expected.from) -> $($expected.to)', got '$($actual.from) -> $($actual.to)'."
    Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$actual.evidence)) "RFC transition ledger row '$($actual.from) -> $($actual.to)' has empty evidence."
  }

  if ($hasAcceptedHistory) {
    $acceptedRow = @($rows | Where-Object { $_.from -ceq 'Proposed' -and $_.to -ceq 'Accepted' })[0]
    Assert-ReferencesInLedgerRow -Label 'Historical RFC acceptance' -References @($Rfc.acceptance_evidence) -LedgerRow $acceptedRow.text
  }
  if ($hasImplementedHistory) {
    $implementedRow = @($rows | Where-Object { $_.from -ceq 'Accepted' -and $_.to -ceq 'Implemented' })[0]
    Assert-ReferencesInLedgerRow -Label 'Historical RFC implementation' -References @($Rfc.implementation_evidence) -LedgerRow $implementedRow.text
    Assert-ReferencesInLedgerRow -Label 'Historical RFC qualification' -References @($Rfc.qualification_evidence) -LedgerRow $implementedRow.text
  }
}

function Assert-ReferencesInLedgerRow {
  param([string]$Label, [object[]]$References, [string]$LedgerRow)
  Assert-Condition ($References.Count -gt 0) "$Label requires at least one evidence reference."
  $strings = @($References | ForEach-Object { [string]$_ })
  Assert-Condition (@($strings | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -eq 0) "$Label contains an empty evidence reference."
  Assert-Condition (@($strings | Group-Object -CaseSensitive | Where-Object Count -ne 1).Count -eq 0) "$Label contains duplicate evidence references."
  foreach ($reference in $strings) {
    Assert-Condition ($LedgerRow.Contains($reference, [System.StringComparison]::Ordinal)) "$Label reference '$reference' is not bound to the RFC transition ledger row."
  }
}

function ConvertFrom-RfcTimestamp {
  param([string]$Value, [string]$Label)
  Assert-Condition ($Value -cmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:Z|[+-]\d{2}:\d{2})$') "$Label must be an RFC 3339 timestamp with an explicit offset."
  $parsed = [DateTimeOffset]::MinValue
  $valid = [DateTimeOffset]::TryParse($Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)
  Assert-Condition $valid "$Label is not a valid timestamp."
  return $parsed
}

function Get-MarkdownSection {
  param([string]$Text, [string]$Heading)
  $match = [regex]::Match($Text, "(?ms)^##\s+$([regex]::Escape($Heading))\s*\r?\n(?<body>.*?)(?=^##\s+|\z)")
  Assert-Condition $match.Success "Decision artifact lacks section '$Heading'."
  return $match.Groups['body'].Value
}

function Assert-ApprovalReference {
  param([string]$Reference, [string]$Identity)
  Assert-Condition (-not [string]::IsNullOrWhiteSpace($Reference)) "Approval for '$Identity' requires a reference."
  $isHttps = $Reference -cmatch '^https://[^\s]+$'
  $isRepositoryReference = $Reference -cmatch '^(?:docs|reviews|[.]planning)/[^\s#]+(?:#[^\s#]+)?$' -or $Reference -cmatch '^commit:[0-9a-f]{7,40}$'
  Assert-Condition ($isHttps -or $isRepositoryReference) "Approval for '$Identity' must use an HTTPS review URL or stable repository reference."
  Assert-Condition ($Reference -cnotmatch '(?i)(placeholder|example|todo|tbd|dummy|fake)') "Approval for '$Identity' uses placeholder evidence."
}

function Resolve-RepositoryLeafFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$RepositoryRoot,
    [Parameter(Mandatory)][string]$RelativePath,
    [Parameter(Mandatory)][string]$Label
  )

  Assert-Condition (-not [System.IO.Path]::IsPathRooted($RelativePath)) "$Label must be repository-relative."
  $segments = @($RelativePath -split '[\\/]')
  Assert-Condition (-not ($segments -ccontains '..')) "$Label must not contain a parent traversal segment."

  $rootFull = [System.IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
  $rootPrefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
  $fullPath = [System.IO.Path]::GetFullPath((Join-Path $rootFull $RelativePath))
  Assert-Condition ($fullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) "$Label escapes the repository root."
  $currentPath = $rootFull
  for ($index = 0; $index -lt $segments.Count; $index++) {
    $segment = [string]$segments[$index]
    Assert-Condition (-not [string]::IsNullOrWhiteSpace($segment) -and $segment -cne '.') "$Label contains an invalid segment."
    $currentPath = Join-Path $currentPath $segment
    Assert-Condition (Test-Path -LiteralPath $currentPath) "$Label component '$segment' does not exist."
    $item = Get-Item -LiteralPath $currentPath -Force
    $isReparsePoint = ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
    Assert-Condition (-not $isReparsePoint) "$Label component '$segment' must not be a symbolic link or reparse point."
    if ($index -lt ($segments.Count - 1)) {
      Assert-Condition ($item.PSIsContainer) "$Label ancestor '$segment' must be a directory."
    }
  }
  Assert-Condition (Test-Path -LiteralPath $fullPath -PathType Leaf) "$Label must resolve to an existing leaf file."
  return $fullPath
}

function Resolve-RfcEvidenceFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$RepositoryRoot,
    [Parameter(Mandatory)][string]$RelativePath,
    [Parameter(Mandatory)][string]$ExpectedRelativePath
  )
  $resolved = Resolve-RepositoryLeafFile -RepositoryRoot $RepositoryRoot -RelativePath $RelativePath -Label 'RFC evidence path'
  Assert-Condition ($RelativePath.Replace('\','/') -ceq $ExpectedRelativePath.Replace('\','/')) 'RFC evidence path does not identify the canonical decision artifact.'
  return $resolved
}

function Assert-FixtureManifest {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$ManifestPath,
    [Parameter(Mandatory)][string]$RepositoryRoot
  )
  $fixtureManifest = Read-QualityJson -Path $ManifestPath
  Assert-Condition ($fixtureManifest.schema_version -ceq '1.0.0') 'Fixture manifest schema_version must be 1.0.0.'
  Assert-ExactSet 'Fixture required fields' @($fixtureManifest.required_record_fields) @('id','path','origin','source','author','retrieval_date','sha256','license','redistribution_status','expected_use')
  $fixtureIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
  foreach ($record in @($fixtureManifest.records)) {
    foreach ($field in @($fixtureManifest.required_record_fields)) {
      Assert-Condition ($null -ne $record.$field -and -not [string]::IsNullOrWhiteSpace([string]$record.$field)) "Fixture record is missing '$field'."
    }
    Assert-Condition ($fixtureIds.Add([string]$record.id)) "Duplicate fixture id '$($record.id)'."
    Assert-Condition (@($fixtureManifest.allowed_origins) -ccontains $record.origin) "Fixture '$($record.id)' has invalid origin."
    Assert-Condition (@($fixtureManifest.allowed_redistribution_statuses) -ccontains $record.redistribution_status) "Fixture '$($record.id)' has invalid redistribution status."
    Assert-Condition ([string]$record.sha256 -cmatch '^[0-9a-f]{64}$') "Fixture '$($record.id)' has invalid SHA-256."
    Assert-Condition ([string]$record.retrieval_date -cmatch '^\d{4}-\d{2}-\d{2}$') "Fixture '$($record.id)' has invalid retrieval date."
    if ($record.origin -ceq 'external' -and $fixtureManifest.external_requires_confirmed_redistribution) {
      Assert-Condition ($record.redistribution_status -ceq 'confirmed') "External fixture '$($record.id)' lacks confirmed redistribution."
    }
    $fixturePath = Resolve-RepositoryLeafFile -RepositoryRoot $RepositoryRoot -RelativePath ([string]$record.path) -Label "Fixture '$($record.id)' path"
    $actualDigest = (Get-FileHash -LiteralPath $fixturePath -Algorithm SHA256).Hash.ToLowerInvariant()
    Assert-Condition ($actualDigest -ceq [string]$record.sha256) "Fixture '$($record.id)' SHA-256 does not match its bytes."
  }
}

function Assert-RfcAcceptanceState {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][object]$Policy,
    [Parameter(Mandatory)][string]$RosterPath,
    [Parameter(Mandatory)][string]$RepositoryRoot,
    [DateTimeOffset]$Now = [DateTimeOffset]::UtcNow
  )

  $rfcPolicy = $Policy.rfc
  $rfc = $rfcPolicy.current_foundation_rfc
  $canonicalDecisionPath = 'docs/governance/decisions/0001-sole-owner-bootstrap.md'
  $canonicalDecisionAnchors = @('owner-instruction','conversation-context-and-interpretation','authorization-and-conditions','edge-review-results')
  $canonicalEdgeReviewIds = @('EDGE-GOV-01-UNCLASSIFIED','EDGE-GOV-02-UNCLASSIFIED')
  Assert-Condition (@($rfcPolicy.allowed_statuses) -ccontains $rfc.status) "RFC status '$($rfc.status)' is not allowed."
  Assert-ExactSet 'RFC acceptance routes' @($rfcPolicy.acceptance_routes) @('maintainer','project-lead-public-review','sole-project-owner-bootstrap')
  Assert-Condition ([string]$rfcPolicy.sole_owner_bootstrap.decision_path -ceq $canonicalDecisionPath) 'Sole-owner policy decision path differs from the canonical artifact.'
  Assert-ExactSet 'Sole-owner policy decision anchors' @($rfcPolicy.sole_owner_bootstrap.required_anchors) $canonicalDecisionAnchors
  Assert-ExactSet 'Sole-owner policy edge review IDs' @($rfcPolicy.sole_owner_bootstrap.mandatory_edge_reviews) $canonicalEdgeReviewIds

  $expectedRosterPath = [System.IO.Path]::GetFullPath((Join-Path $RepositoryRoot ([string]$rfcPolicy.maintainer_roster_path)))
  Assert-Condition ([System.IO.Path]::GetFullPath($RosterPath) -ceq $expectedRosterPath) 'RFC acceptance must use the canonical maintainer roster path.'
  $roster = Read-QualityJson -Path $RosterPath
  Assert-Condition ($roster.schema_version -ceq '1.0.0') 'Maintainer roster schema_version must be 1.0.0.'
  $maintainers = @($roster.maintainers)
  $identities = @($maintainers | ForEach-Object { [string]$_.identity })
  Assert-Condition (@($identities | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -eq 0) 'Maintainer identities must be non-empty.'
  $identityGroups = @($identities | Group-Object -CaseSensitive)
  Assert-Condition (@($identityGroups | Where-Object Count -ne 1).Count -eq 0) 'Maintainer roster contains duplicate identities.'
  foreach ($maintainer in $maintainers) {
    Assert-Condition (@($maintainer.roles) -ccontains 'maintainer') "Roster identity '$($maintainer.identity)' lacks the maintainer role."
    Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$maintainer.evidence)) "Roster identity '$($maintainer.identity)' lacks evidence."
  }

  $rfcPath = Join-Path $RepositoryRoot ([string]$rfc.path)
  Assert-Condition (Test-Path -LiteralPath $rfcPath -PathType Leaf) 'Foundation RFC path does not exist.'
  $rfcText = Get-Content -LiteralPath $rfcPath -Raw
  Assert-Condition ($rfcText -cmatch "(?m)^- \*\*Status:\*\* $([regex]::Escape([string]$rfc.status))\s*$") 'RFC header status does not match policy.'
  $indexPath = Join-Path $RepositoryRoot 'docs/rfcs/README.md'
  Assert-Condition (Test-Path -LiteralPath $indexPath -PathType Leaf) 'RFC index does not exist.'
  $indexText = Get-Content -LiteralPath $indexPath -Raw
  Assert-Condition ($indexText -cmatch "(?m)^\|[^\r\n]*RFC 0001[^\r\n]*\|\s*$([regex]::Escape([string]$rfc.status))\s*\|") 'RFC index status does not match policy.'

  $transition = Get-RequiredProperty $rfc 'transition' 'Foundation RFC'
  $transitionFrom = [string](Get-RequiredProperty $transition 'from' 'Foundation RFC transition')
  $transitionTo = [string](Get-RequiredProperty $transition 'to' 'Foundation RFC transition')
  $transitionEvidence = @(Get-RequiredProperty $transition 'evidence' 'Foundation RFC transition')
  Assert-Condition ($transitionTo -ceq [string]$rfc.status) 'RFC transition target does not match current status.'
  $legalPriorStates = @{
    'Draft' = @('—')
    'Proposed' = @('Draft')
    'Accepted' = @('Proposed')
    'Implemented' = @('Accepted')
    'Rejected' = @('Draft','Proposed')
    'Superseded' = @('Proposed','Accepted','Implemented')
  }
  Assert-Condition (@($legalPriorStates[[string]$rfc.status]) -ccontains $transitionFrom) "Illegal RFC transition '$transitionFrom -> $($rfc.status)'."
  $transitionRow = Get-RfcTransitionLedgerRow -RfcText $rfcText -From $transitionFrom -To ([string]$rfc.status)
  Assert-ReferencesInLedgerRow -Label 'RFC transition' -References $transitionEvidence -LedgerRow $transitionRow
  Assert-RfcLifecycleLedger -Rfc $rfc -RfcText $rfcText

  if ($rfc.status -in @('Draft','Proposed')) {
    Assert-NullOrEmpty 'acceptance_route' $rfc.acceptance_route
    Assert-NullOrEmpty 'authority' $rfc.authority
    Assert-Condition (@($rfc.approvers).Count -eq 0) 'Proposed RFC must not record approvers.'
    Assert-NullOrEmpty 'project_lead' $rfc.project_lead
    Assert-NullOrEmpty 'public_review_url' $rfc.public_review_url
    Assert-NullOrEmpty 'public_review_started_at' $rfc.public_review_started_at
    Assert-NullOrEmpty 'public_review_ended_at' $rfc.public_review_ended_at
    Assert-NullOrEmpty 'decision_evidence_path' $rfc.decision_evidence_path
    Assert-Condition (@($rfc.decision_evidence_anchors).Count -eq 0) 'Proposed RFC must not record decision evidence anchors.'
    Assert-Condition (@($rfc.acceptance_evidence).Count -eq 0) 'Proposed RFC must not record acceptance evidence.'
    Assert-NullOrEmpty 'objection_disposition' $rfc.objection_disposition
    foreach ($review in @($rfc.edge_reviews)) {
      $pending = $review.status -ceq 'pending' -and $null -eq $review.disposition
      $completed = $review.status -ceq 'completed' -and -not [string]::IsNullOrWhiteSpace([string]$review.disposition) -and [string]$review.disposition -cne 'unresolved'
      Assert-Condition ($pending -or $completed) 'Proposed RFC edge-review records must be pending or completed with a resolved disposition.'
    }
    Assert-NullOrEmpty 'implementation_evidence' $rfc.implementation_evidence
    Assert-NullOrEmpty 'qualification_evidence' $rfc.qualification_evidence
    Assert-NullOrEmpty 'rejection_disposition' $rfc.rejection_disposition
    Assert-NullOrEmpty 'superseded_by' $rfc.superseded_by
    Assert-NullOrEmpty 'supersession_evidence' $rfc.supersession_evidence
    return
  }

  if ($rfc.status -ceq 'Rejected') {
    Assert-NullOrEmpty 'acceptance_route' $rfc.acceptance_route
    Assert-NullOrEmpty 'authority' $rfc.authority
    Assert-Condition (@($rfc.approvers).Count -eq 0 -and @($rfc.acceptance_evidence).Count -eq 0) 'Rejected RFC must not assert acceptance evidence.'
    Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$rfc.rejection_disposition)) 'Rejected RFC requires a rejecting disposition.'
    Assert-ReferencesInLedgerRow -Label 'Rejected RFC transition' -References $transitionEvidence -LedgerRow $transitionRow
    Assert-NullOrEmpty 'implementation_evidence' $rfc.implementation_evidence
    Assert-NullOrEmpty 'qualification_evidence' $rfc.qualification_evidence
    Assert-NullOrEmpty 'superseded_by' $rfc.superseded_by
    Assert-NullOrEmpty 'supersession_evidence' $rfc.supersession_evidence
    return
  }

  if ($rfc.status -ceq 'Superseded') {
    $replacementId = [string]$rfc.superseded_by
    Assert-Condition ($replacementId -cmatch '^\d{4}$' -and $replacementId -cne [string]$rfc.id) 'Superseded RFC requires a distinct four-digit replacement RFC id.'
    $replacement = @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot 'docs/rfcs') -File | Where-Object Name -CLike "$replacementId-*.md")
    Assert-Condition ($replacement.Count -eq 1) "Superseded RFC replacement '$replacementId' must identify exactly one existing RFC file."
    $supersessionEvidence = @($rfc.supersession_evidence)
    Assert-ReferencesInLedgerRow -Label 'Superseded RFC transition' -References $supersessionEvidence -LedgerRow $transitionRow
    Assert-ExactSet 'Superseded RFC transition evidence' $transitionEvidence $supersessionEvidence
    Assert-Condition (@($supersessionEvidence | Where-Object { ([string]$_) -cmatch "(?:^|/)${replacementId}-[^#]+[.]md(?:#|$)" }).Count -gt 0) 'Supersession evidence must reference the replacement RFC.'
    Assert-NullOrEmpty 'implementation_evidence' $rfc.implementation_evidence
    Assert-NullOrEmpty 'qualification_evidence' $rfc.qualification_evidence
    Assert-NullOrEmpty 'rejection_disposition' $rfc.rejection_disposition
    return
  }

  Assert-Condition (@($rfcPolicy.acceptance_routes) -ccontains $rfc.acceptance_route) 'Accepted RFC has an unknown acceptance route.'
  Assert-Condition ($rfc.blocking_objections -ceq 'none') 'Accepted RFC must have zero unresolved blocking objections.'
  Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$rfc.objection_disposition)) 'Accepted RFC requires an objection disposition.'
  Assert-Condition (@($rfc.acceptance_evidence).Count -gt 0) 'Accepted RFC requires acceptance evidence.'

  if ($rfc.status -ceq 'Accepted') {
    Assert-ExactSet 'Accepted RFC transition evidence' $transitionEvidence @($rfc.acceptance_evidence)
    Assert-NullOrEmpty 'implementation_evidence' $rfc.implementation_evidence
    Assert-NullOrEmpty 'qualification_evidence' $rfc.qualification_evidence
  } else {
    $implementationEvidence = @($rfc.implementation_evidence)
    $qualificationEvidence = @($rfc.qualification_evidence)
    Assert-ReferencesInLedgerRow -Label 'Implemented RFC implementation evidence' -References $implementationEvidence -LedgerRow $transitionRow
    Assert-ReferencesInLedgerRow -Label 'Implemented RFC qualification evidence' -References $qualificationEvidence -LedgerRow $transitionRow
    Assert-ExactSet 'Implemented RFC transition evidence' $transitionEvidence @($implementationEvidence + $qualificationEvidence)
  }
  Assert-NullOrEmpty 'rejection_disposition' $rfc.rejection_disposition
  Assert-NullOrEmpty 'superseded_by' $rfc.superseded_by
  Assert-NullOrEmpty 'supersession_evidence' $rfc.supersession_evidence

  switch -CaseSensitive ([string]$rfc.acceptance_route) {
    'maintainer' {
      $approvers = @($rfc.approvers | ForEach-Object { [string]$_ })
      Assert-Condition ($approvers.Count -ge 2 -and @($approvers | Select-Object -Unique).Count -eq $approvers.Count) 'Maintainer route requires two distinct approvals.'
      foreach ($approver in $approvers) { Assert-Condition ($identities -ccontains $approver) "Approver '$approver' is not a canonical maintainer." }
      $approvalRecords = @($rfc.approval_records)
      Assert-ExactSet 'Maintainer approval identities' @($approvalRecords.identity) $approvers
      Assert-Condition (@($approvalRecords.reference | Group-Object -CaseSensitive | Where-Object Count -ne 1).Count -eq 0) 'Maintainer approval references must be distinct.'
      foreach ($approval in $approvalRecords) {
        Assert-Condition ([string]$approval.role -ceq 'maintainer') "Approval for '$($approval.identity)' must record the maintainer role."
        Assert-ApprovalReference -Reference ([string]$approval.reference) -Identity ([string]$approval.identity)
      }
      Assert-ExactSet 'Maintainer acceptance evidence' @($rfc.acceptance_evidence) @($approvalRecords.reference)
      Assert-Condition ($rfc.authority -ceq 'maintainers') 'Maintainer route authority must be maintainers.'
      Assert-NullOrEmpty 'project_lead' $rfc.project_lead; Assert-NullOrEmpty 'project_owner' $rfc.project_owner
      Assert-NullOrEmpty 'public_review_url' $rfc.public_review_url; Assert-NullOrEmpty 'public_review_started_at' $rfc.public_review_started_at; Assert-NullOrEmpty 'public_review_ended_at' $rfc.public_review_ended_at
      Assert-NullOrEmpty 'decision_evidence_path' $rfc.decision_evidence_path
      Assert-Condition (@($rfc.decision_evidence_anchors).Count -eq 0 -and @($rfc.edge_reviews).Count -eq 0) 'Maintainer route must not assert sole-owner evidence.'
    }
    'project-lead-public-review' {
      Assert-Condition ($rfc.authority -ceq 'project-lead') 'Project-lead route authority must be project-lead.'
      $lead = @($maintainers | Where-Object { [string]$_.identity -ceq [string]$rfc.project_lead -and @($_.roles) -ccontains 'project-lead' })
      Assert-Condition ($lead.Count -eq 1 -and $identities.Count -lt 2) 'Project-lead route requires an eligible project lead while fewer than two maintainers exist.'
      Assert-Condition ([string]$rfc.public_review_url -cmatch '^https?://') 'Project-lead route requires a public review URL.'
      $leadApprovals = @($rfc.approval_records)
      Assert-Condition ($leadApprovals.Count -eq 1 -and [string]$leadApprovals[0].identity -ceq [string]$rfc.project_lead -and [string]$leadApprovals[0].role -ceq 'project-lead') 'Project-lead route requires one approval record bound to the canonical project lead.'
      Assert-ApprovalReference -Reference ([string]$leadApprovals[0].reference) -Identity ([string]$rfc.project_lead)
      Assert-Condition (@($rfc.acceptance_evidence) -ccontains [string]$leadApprovals[0].reference) 'Project-lead approval reference must be part of acceptance evidence.'
      $started = ConvertFrom-RfcTimestamp -Value ([string]$rfc.public_review_started_at) -Label 'Public review start'
      $ended = ConvertFrom-RfcTimestamp -Value ([string]$rfc.public_review_ended_at) -Label 'Public review end'
      Assert-Condition ($started -le $ended) 'Public review start must not follow its end.'
      Assert-Condition ($ended -le $Now) 'Public review end must have elapsed before acceptance.'
      Assert-Condition (($ended - $started).TotalDays -ge 7) 'Project-lead route requires seven elapsed days of public review.'
      Assert-Condition (@($rfc.approvers).Count -eq 0) 'Project-lead route must not assert maintainer approvals.'
      Assert-NullOrEmpty 'project_owner' $rfc.project_owner; Assert-NullOrEmpty 'decision_evidence_path' $rfc.decision_evidence_path
      Assert-Condition (@($rfc.decision_evidence_anchors).Count -eq 0 -and @($rfc.edge_reviews).Count -eq 0) 'Project-lead route must not assert sole-owner evidence.'
    }
    'sole-project-owner-bootstrap' {
      Assert-Condition ($identities.Count -eq 1 -and $identityGroups.Count -eq 1) 'Sole-owner route requires exactly one unique canonical maintainer.'
      $sole = $maintainers[0]
      Assert-Condition (@($sole.roles) -ccontains 'project-owner') 'Sole canonical maintainer must have the project-owner role.'
      $expectedOwnerEvidence = "$canonicalDecisionPath#owner-instruction"
      Assert-Condition ([string]$sole.evidence -ceq $expectedOwnerEvidence) 'Sole project-owner roster evidence must point to the canonical owner-instruction anchor.'
      Assert-Condition ([string]$rfc.project_owner -ceq [string]$sole.identity -and [string]$rfc.authority -ceq [string]$sole.identity) 'Sole-owner authority must match the canonical project owner.'
      Assert-Condition (@($rfc.approvers).Count -eq 0) 'Sole-owner route must not assert a multi-approver list.'
      Assert-Condition (@($rfc.approval_records).Count -eq 0) 'Sole-owner route must not assert maintainer or project-lead approval records.'
      Assert-NullOrEmpty 'project_lead' $rfc.project_lead; Assert-NullOrEmpty 'public_review_url' $rfc.public_review_url; Assert-NullOrEmpty 'public_review_started_at' $rfc.public_review_started_at; Assert-NullOrEmpty 'public_review_ended_at' $rfc.public_review_ended_at
      $expectedDecision = $canonicalDecisionPath
      $decisionFile = Resolve-RfcEvidenceFile -RepositoryRoot $RepositoryRoot -RelativePath ([string]$rfc.decision_evidence_path) -ExpectedRelativePath $expectedDecision
      Assert-ExactSet 'Sole-owner decision anchors' @($rfc.decision_evidence_anchors) $canonicalDecisionAnchors
      $decisionText = Get-Content -LiteralPath $decisionFile -Raw
      $headingByAnchor = @{
        'owner-instruction'='Owner instruction'; 'conversation-context-and-interpretation'='Conversation context and interpretation'
        'authorization-and-conditions'='Authorization and conditions'; 'edge-review-results'='Edge review results'
      }
      foreach ($anchor in $canonicalDecisionAnchors) {
        Assert-Condition ($headingByAnchor.ContainsKey([string]$anchor)) "Unknown required decision anchor '$anchor'."
        Assert-Condition ($decisionText -cmatch "(?m)^## $([regex]::Escape($headingByAnchor[[string]$anchor]))\s*$") "Decision artifact lacks required anchor '$anchor'."
      }
      $ownerSection = Get-MarkdownSection -Text $decisionText -Heading 'Owner instruction'
      $contextSection = Get-MarkdownSection -Text $decisionText -Heading 'Conversation context and interpretation'
      $edgeSection = Get-MarkdownSection -Text $decisionText -Heading 'Edge review results'
      Assert-Condition ($ownerSection.Contains('现在只有我一个人开发，跳过', [System.StringComparison]::Ordinal) -and $contextSection -cmatch 'preauthoriz') 'Decision artifact does not preserve the authentic conditional preauthorization in its named sections.'
      $reviews = @($rfc.edge_reviews)
      Assert-ExactSet 'Sole-owner edge review IDs' @($reviews.id) $canonicalEdgeReviewIds
      foreach ($review in $reviews) {
        Assert-Condition ($review.status -ceq 'completed') "Edge review '$($review.id)' is not completed."
        Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$review.disposition) -and [string]$review.disposition -cne 'unresolved') "Edge review '$($review.id)' lacks a resolved disposition."
        $edgePattern = '(?m)^-\s+`' + [regex]::Escape([string]$review.id) + '`:[^\r\n]*Disposition:\s*' + [regex]::Escape([string]$review.disposition) + '[.]'
        Assert-Condition ($edgeSection -cmatch $edgePattern) "Decision artifact edge-review section does not bind '$($review.id)' to disposition '$($review.disposition)'."
      }
      $expectedAcceptanceEvidence = @("$expectedDecision#owner-instruction", "$expectedDecision#edge-review-results")
      Assert-ExactSet 'Sole-owner acceptance evidence' @($rfc.acceptance_evidence) $expectedAcceptanceEvidence
    }
  }
}

function Assert-FoundationPolicy {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$PolicyPath,
    [string]$MaintainersPath
  )

  $policy = Read-QualityJson -Path $PolicyPath
  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  Assert-Condition ($policy.schema_version -ceq '1.0.0') 'Foundation policy schema_version must be 1.0.0.'
  Assert-Condition ($policy.license -ceq 'Apache-2.0') 'Foundation policy license must be Apache-2.0.'
  Assert-Condition ($policy.module_manifest_format -ceq 'moon.mod.json') 'Module manifest format must be moon.mod.json.'
  Assert-ExactSet 'Required targets' @($policy.required_targets) @('js', 'wasm', 'wasm-gc', 'native')
  Assert-ExactSet 'Experimental targets' @($policy.experimental_targets) @('llvm')
  Assert-ExactSet 'Stability labels' @($policy.stability.allowed_labels) @('experimental', 'candidate', 'stable')
  Assert-Condition ($policy.stability.default_label -ceq 'candidate') 'Default stability label must be candidate.'

  $expectedModules = @('moonbit-foundation/mb-core', 'moonbit-foundation/mb-color', 'moonbit-foundation/mb-image')
  $expectedPaths = @('modules/mb-core', 'modules/mb-color', 'modules/mb-image')
  Assert-ExactSet 'Policy modules' @($policy.modules.name) $expectedModules
  Assert-ExactSet 'Policy module paths' @($policy.modules.path) $expectedPaths
  Assert-AcyclicDependencyGraph -Modules @($policy.modules) -AllowedEdges @($policy.allowed_dependency_edges)

  $workText = Get-Content -LiteralPath (Join-Path $repoRoot 'moon.work') -Raw
  $workMembers = @([regex]::Matches($workText, '"\./([^"\r\n]+)"') | ForEach-Object { $_.Groups[1].Value })
  Assert-ExactSet 'moon.work members' $workMembers $expectedPaths

  foreach ($module in $policy.modules) {
    Assert-Condition ($module.version -ceq '0.1.0') "Policy version drift for $($module.name)."
    Assert-Condition (@($policy.stability.allowed_labels) -ccontains $module.stability) "Invalid stability label for $($module.name)."
    Assert-ExactSet "Policy targets for $($module.name)" @($module.supported_targets) @($policy.required_targets)
    Assert-Condition (@($module.public_packages).Count -eq 1) "$($module.name) must declare exactly one public package."
    $package = @($module.public_packages)[0]
    Assert-Condition ($package.name -ceq $module.name -and $package.path -ceq '.') "Public package identity drift for $($module.name)."
    Assert-Condition ($package.stability -ceq $module.stability) "Public package stability drift for $($module.name)."
    Assert-ExactSet "Public package targets for $($module.name)" @($package.supported_targets) @($policy.required_targets)

    $modulePath = Join-Path $repoRoot ([string]$module.path)
    $manifest = Read-QualityJson -Path (Join-Path $modulePath 'moon.mod.json')
    Assert-Condition ($manifest.name -ceq $module.name) "Manifest name drift in $($module.path)."
    Assert-Condition ($manifest.version -ceq $module.version) "Manifest version drift in $($module.path)."
    Assert-Condition ($manifest.license -ceq $policy.license) "Manifest license drift in $($module.path)."
    Assert-Condition ($manifest.readme -ceq 'README.mbt.md') "Manifest readme drift in $($module.path)."
    Assert-Condition ($manifest.'preferred-target' -ceq $module.preferred_target) "Preferred target drift in $($module.path)."
    Assert-ExactSet "Manifest targets for $($module.name)" (Get-CompactTargetSet $manifest.'supported-targets' "manifest targets for $($module.name)") @($policy.required_targets)
    $depsProperty = $manifest.PSObject.Properties['deps']
    $manifestDeps = @()
    if ($null -ne $depsProperty) {
      $manifestDeps = @($depsProperty.Value.PSObject.Properties.Name)
    }
    Assert-ExactSet "Manifest dependencies for $($module.name)" $manifestDeps @($module.direct_dependencies)
    foreach ($dep in $manifestDeps) {
      Assert-Condition ($manifest.deps.$dep -ceq '0.1.0') "Dependency '$dep' in $($module.name) must pin 0.1.0."
    }

    $packageText = Get-Content -LiteralPath (Join-Path $modulePath 'moon.pkg') -Raw
    $packageMatch = [regex]::Match($packageText, '(?m)^supported_targets\s*=\s*"([^"]+)"\s*$')
    Assert-Condition $packageMatch.Success "moon.pkg in $($module.path) lacks supported_targets."
    Assert-ExactSet "moon.pkg targets for $($module.name)" (Get-CompactTargetSet $packageMatch.Groups[1].Value "package targets for $($module.name)") @($policy.required_targets)

    $readmeText = Get-Content -LiteralPath (Join-Path $modulePath 'README.mbt.md') -Raw
    Assert-Condition ($readmeText -cmatch '\bcandidate\b') "README for $($module.name) does not expose candidate stability."
    foreach ($target in @($policy.required_targets)) {
      Assert-Condition ($readmeText -cmatch [regex]::Escape($target)) "README for $($module.name) does not expose target '$target'."
    }
  }

  Assert-Condition ($policy.publication.blocked -eq $true) 'Public publication must remain blocked.'
  Assert-Condition ($policy.publication.owner_verified -eq $false) 'Owner namespace must remain unverified.'
  Assert-Condition ($policy.publication.intended_owner_namespace -ceq 'moonbit-foundation') 'Intended owner namespace drifted.'
  Assert-Condition ($policy.publication.umbrella_module_allowed -eq $false) 'Umbrella modules must remain forbidden.'
  Assert-Condition ($policy.publication.lockstep_versions_required -eq $false -and $policy.publication.independent_versions -eq $true) 'Independent versioning policy drifted.'
  Assert-Condition (-not [string]::IsNullOrWhiteSpace($policy.publication.block_reason)) 'Publication block requires a reason.'

  if ([string]::IsNullOrWhiteSpace($MaintainersPath)) { $MaintainersPath = Join-Path $repoRoot ([string]$policy.rfc.maintainer_roster_path) }
  Assert-RfcAcceptanceState -Policy $policy -RosterPath $MaintainersPath -RepositoryRoot $repoRoot

  $rfcProcessText = Get-Content -LiteralPath (Join-Path $repoRoot 'docs/governance/rfc-process.md') -Raw
  Assert-Condition ($rfcProcessText -cmatch 'RFC 0001 completed and dispositioned both checks' -and $rfcProcessText -cmatch 'decisions/0001-sole-owner-bootstrap[.]md#edge-review-results') 'RFC process must record RFC 0001 edge-review completion and link its canonical evidence.'
  Assert-Condition ($rfcProcessText -cnotmatch 'still-unclassified checks' -and $rfcProcessText -cnotmatch 'These checks are open review obligations') 'RFC process incorrectly describes completed RFC 0001 checks as open.'

  Assert-FixtureManifest -ManifestPath (Join-Path $repoRoot 'fixtures/manifest.json') -RepositoryRoot $repoRoot

  Write-Host 'Foundation policy, RFC, workspace inventory, target metadata, fixtures, publication block, and dependency DAG verified.'
}

function Assert-AuditCollection {
  param([string]$Label, [object[]]$Items, [string[]]$ExpectedIds)
  Assert-Condition ($Items.Count -eq $ExpectedIds.Count) "$Label count mismatch: expected $($ExpectedIds.Count), got $($Items.Count)."
  Assert-ExactSet "$Label IDs" @($Items.id) $ExpectedIds
  foreach ($item in $Items) {
    Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$item.source)) "$Label '$($item.id)' has empty source."
    Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$item.description)) "$Label '$($item.id)' has empty description."
    Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$item.covering_plan)) "$Label '$($item.id)' has empty covering_plan."
    Assert-Condition ($item.status -ceq 'covered') "$Label '$($item.id)' status must be covered."
  }
}

function Get-MarkdownAnchorSet {
  param([string]$Path)
  $anchors = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
  $duplicates = @{}
  foreach ($line in Get-Content -LiteralPath $Path) {
    if ($line -cnotmatch '^#{1,6}\s+(?<heading>.+?)\s*#*\s*$') { continue }
    $slug = $Matches.heading.ToLowerInvariant()
    $slug = [regex]::Replace($slug, '[^\p{L}\p{N}\s_-]', '')
    $slug = [regex]::Replace($slug.Trim(), '\s+', '-')
    if ([string]::IsNullOrWhiteSpace($slug)) { continue }
    $ordinal = if ($duplicates.ContainsKey($slug)) { [int]$duplicates[$slug] + 1 } else { 0 }
    $duplicates[$slug] = $ordinal
    if ($ordinal -gt 0) { $slug = "$slug-$ordinal" }
    [void]$anchors.Add($slug)
  }
  return $anchors
}

function Assert-PhaseSourceAudit {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$AuditPath,
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  )

  $audit = Read-QualityJson -Path $AuditPath
  Assert-Condition ($audit.schema_version -ceq '1.0.0') 'Source audit schema_version must be 1.0.0.'
  Assert-Condition ($audit.phase -ceq '01-foundation-charter-and-reproducible-workspace') 'Source audit phase identity drifted.'

  $expectedGoals = @('GOAL-01')
  $expectedRequirements = @('GOV-01','GOV-02','GOV-03','GOV-04','WORK-01','WORK-02','WORK-03','WORK-04','WORK-05')
  $expectedDecisions = 1..16 | ForEach-Object { 'D-{0:D2}' -f $_ }
  $expectedResearch = @(
    (1..5 | ForEach-Object { 'RESEARCH-PATTERN-{0:D2}' -f $_ })
    (1..9 | ForEach-Object { 'RESEARCH-ANTI-{0:D2}' -f $_ })
    (1..7 | ForEach-Object { 'RESEARCH-DONT-HAND-ROLL-{0:D2}' -f $_ })
    (1..8 | ForEach-Object { 'RESEARCH-PITFALL-{0:D2}' -f $_ })
  )
  $expectedEdges = @(
    'EDGE-GOV-03-ADJACENCY','EDGE-GOV-03-EMPTY','EDGE-GOV-03-ORDERING',
    'EDGE-WORK-03-ADJACENCY','EDGE-WORK-03-EMPTY','EDGE-WORK-03-ORDERING',
    'EDGE-WORK-04-ADJACENCY','EDGE-WORK-04-EMPTY','EDGE-WORK-04-ORDERING',
    'EDGE-WORK-05-ADJACENCY','EDGE-WORK-05-EMPTY','EDGE-WORK-05-ORDERING',
    'EDGE-GOV-01-UNCLASSIFIED','EDGE-GOV-02-UNCLASSIFIED','EDGE-GOV-04-UNCLASSIFIED','EDGE-WORK-01-UNCLASSIFIED','EDGE-WORK-02-UNCLASSIFIED'
  )
  $expectedProhibitions = @('PROH-GOV-02-EVIDENCE','PROH-GOV-03-PREMATURE-STABLE','PROH-GOV-04-EXTERNAL-FIXTURE','PROH-GOV-04-NAMESPACE-PUBLISH','PROH-WORK-05-LLVM-SUPPORT')

  Assert-AuditCollection 'goals' @($audit.goals) $expectedGoals
  Assert-AuditCollection 'requirements' @($audit.requirements) $expectedRequirements
  Assert-AuditCollection 'decisions' @($audit.decisions) $expectedDecisions
  Assert-AuditCollection 'research_items' @($audit.research_items) $expectedResearch
  Assert-AuditCollection 'edge_items' @($audit.edge_items) $expectedEdges
  Assert-AuditCollection 'prohibitions' @($audit.prohibitions) $expectedProhibitions

  $allowedPlans = 1..8 | ForEach-Object { '01-{0:D2}' -f $_ }
  $planCoverage = @{}
  foreach ($plan in $allowedPlans) { $planCoverage[$plan] = [System.Collections.Generic.List[string]]::new() }
  $anchorCache = @{}
  $allItems = @($audit.goals) + @($audit.requirements) + @($audit.decisions) + @($audit.research_items) + @($audit.edge_items) + @($audit.prohibitions)
  foreach ($item in $allItems) {
    $sourceMatch = [regex]::Match([string]$item.source, '^(?<path>[^#]+)#(?<anchor>[^#]+)$')
    Assert-Condition $sourceMatch.Success "Source audit '$($item.id)' must use a repository path plus Markdown anchor."
    $sourcePath = $sourceMatch.Groups['path'].Value
    $sourceFile = Resolve-RepositoryLeafFile -RepositoryRoot $RepositoryRoot -RelativePath $sourcePath -Label "Source audit '$($item.id)' source"
    if (-not $anchorCache.ContainsKey($sourceFile)) {
      $anchorCache[$sourceFile] = [pscustomobject]@{ anchors=(Get-MarkdownAnchorSet -Path $sourceFile); text=(Get-Content -LiteralPath $sourceFile -Raw) }
    }
    $sourceAnchor = $sourceMatch.Groups['anchor'].Value
    $anchorAsHeading = $anchorCache[$sourceFile].anchors.Contains($sourceAnchor.ToLowerInvariant())
    $anchorAsStructuredId = $anchorCache[$sourceFile].text -cmatch "(?m)(?:\*\*|\|\s*)$([regex]::Escape($sourceAnchor))(?:\*\*|:|\s*\|)"
    $anchorAsFrontmatterKey = $anchorCache[$sourceFile].text -cmatch "(?m)^\s*$([regex]::Escape($sourceAnchor)):\s*"
    Assert-Condition ($anchorAsHeading -or $anchorAsStructuredId -or $anchorAsFrontmatterKey) "Source audit '$($item.id)' anchor '$sourceAnchor' does not exist in '$sourcePath'."

    $plans = @(([string]$item.covering_plan -split ',') | ForEach-Object { $_.Trim() })
    Assert-Condition ($plans.Count -gt 0 -and @($plans | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -eq 0) "Source audit '$($item.id)' has an empty covering plan."
    Assert-Condition (@($plans | Group-Object -CaseSensitive | Where-Object Count -ne 1).Count -eq 0) "Source audit '$($item.id)' has duplicate covering plan IDs."
    foreach ($plan in $plans) {
      Assert-Condition ($allowedPlans -ccontains $plan) "Source audit '$($item.id)' references unknown Phase 01 plan '$plan'."
      $planCoverage[$plan].Add([string]$item.id)
    }
  }

  foreach ($plan in $allowedPlans) {
    $planFile = Resolve-RepositoryLeafFile -RepositoryRoot $RepositoryRoot -RelativePath ".planning/phases/01-foundation-charter-and-reproducible-workspace/$plan-PLAN.md" -Label "Phase 01 plan '$plan'"
    $planText = Get-Content -LiteralPath $planFile -Raw
    $marker = [regex]::Match($planText, '(?m)^<!-- phase-source-audit: (?<ids>[^\r\n]+) -->$')
    Assert-Condition $marker.Success "Phase 01 plan '$plan' lacks its reciprocal source-audit marker."
    $markerIds = @($marker.Groups['ids'].Value -split ',' | ForEach-Object { $_.Trim() })
    Assert-ExactSet "Phase 01 plan '$plan' reciprocal source-audit IDs" $markerIds @($planCoverage[$plan])
  }

  Write-Host 'Phase 1 source audit verified exact inventory: 1 goal, 9 requirements, 16 decisions, 29 research items, 17 edges, 5 prohibitions.'
}
