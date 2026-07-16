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

function Resolve-RfcEvidenceFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$RepositoryRoot,
    [Parameter(Mandatory)][string]$RelativePath,
    [Parameter(Mandatory)][string]$ExpectedRelativePath
  )

  Assert-Condition (-not [System.IO.Path]::IsPathRooted($RelativePath)) 'RFC evidence path must be repository-relative.'
  $segments = @($RelativePath -split '[\\/]')
  Assert-Condition (-not ($segments -ccontains '..')) 'RFC evidence path must not contain a parent traversal segment.'
  Assert-Condition ($RelativePath.Replace('\','/') -ceq $ExpectedRelativePath.Replace('\','/')) 'RFC evidence path does not identify the canonical decision artifact.'

  $rootFull = [System.IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
  $rootPrefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar
  $fullPath = [System.IO.Path]::GetFullPath((Join-Path $rootFull $RelativePath))
  Assert-Condition ($fullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) 'RFC evidence path escapes the repository root.'
  $currentPath = $rootFull
  for ($index = 0; $index -lt $segments.Count; $index++) {
    $segment = [string]$segments[$index]
    Assert-Condition (-not [string]::IsNullOrWhiteSpace($segment) -and $segment -cne '.') 'RFC evidence path contains an invalid segment.'
    $currentPath = Join-Path $currentPath $segment
    Assert-Condition (Test-Path -LiteralPath $currentPath) "RFC evidence path component '$segment' does not exist."
    $item = Get-Item -LiteralPath $currentPath -Force
    $isReparsePoint = ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
    Assert-Condition (-not $isReparsePoint) "RFC evidence path component '$segment' must not be a symbolic link or reparse point."
    if ($index -lt ($segments.Count - 1)) {
      Assert-Condition ($item.PSIsContainer) "RFC evidence ancestor '$segment' must be a directory."
    }
  }
  Assert-Condition (Test-Path -LiteralPath $fullPath -PathType Leaf) 'RFC evidence path must resolve to an existing leaf file.'
  return $fullPath
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
  Assert-Condition (@($rfcPolicy.allowed_statuses) -ccontains $rfc.status) "RFC status '$($rfc.status)' is not allowed."
  Assert-ExactSet 'RFC acceptance routes' @($rfcPolicy.acceptance_routes) @('maintainer','project-lead-public-review','sole-project-owner-bootstrap')

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
      $expectedOwnerEvidence = "$([string]$rfcPolicy.sole_owner_bootstrap.decision_path)#owner-instruction"
      Assert-Condition ([string]$sole.evidence -ceq $expectedOwnerEvidence) 'Sole project-owner roster evidence must point to the canonical owner-instruction anchor.'
      Assert-Condition ([string]$rfc.project_owner -ceq [string]$sole.identity -and [string]$rfc.authority -ceq [string]$sole.identity) 'Sole-owner authority must match the canonical project owner.'
      Assert-Condition (@($rfc.approvers).Count -eq 0) 'Sole-owner route must not assert a multi-approver list.'
      Assert-NullOrEmpty 'project_lead' $rfc.project_lead; Assert-NullOrEmpty 'public_review_url' $rfc.public_review_url; Assert-NullOrEmpty 'public_review_started_at' $rfc.public_review_started_at; Assert-NullOrEmpty 'public_review_ended_at' $rfc.public_review_ended_at
      $expectedDecision = [string]$rfcPolicy.sole_owner_bootstrap.decision_path
      $decisionFile = Resolve-RfcEvidenceFile -RepositoryRoot $RepositoryRoot -RelativePath ([string]$rfc.decision_evidence_path) -ExpectedRelativePath $expectedDecision
      Assert-ExactSet 'Sole-owner decision anchors' @($rfc.decision_evidence_anchors) @($rfcPolicy.sole_owner_bootstrap.required_anchors)
      $decisionText = Get-Content -LiteralPath $decisionFile -Raw
      $headingByAnchor = @{
        'owner-instruction'='Owner instruction'; 'conversation-context-and-interpretation'='Conversation context and interpretation'
        'authorization-and-conditions'='Authorization and conditions'; 'edge-review-results'='Edge review results'
      }
      foreach ($anchor in @($rfcPolicy.sole_owner_bootstrap.required_anchors)) {
        Assert-Condition ($headingByAnchor.ContainsKey([string]$anchor)) "Unknown required decision anchor '$anchor'."
        Assert-Condition ($decisionText -cmatch "(?m)^## $([regex]::Escape($headingByAnchor[[string]$anchor]))\s*$") "Decision artifact lacks required anchor '$anchor'."
      }
      Assert-Condition ($decisionText.Contains('现在只有我一个人开发，跳过') -and $decisionText -cmatch 'preauthoriz') 'Decision artifact does not preserve the authentic conditional preauthorization.'
      $reviews = @($rfc.edge_reviews)
      Assert-ExactSet 'Sole-owner edge review IDs' @($reviews.id) @($rfcPolicy.sole_owner_bootstrap.mandatory_edge_reviews)
      foreach ($review in $reviews) {
        Assert-Condition ($review.status -ceq 'completed') "Edge review '$($review.id)' is not completed."
        Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$review.disposition) -and [string]$review.disposition -cne 'unresolved') "Edge review '$($review.id)' lacks a resolved disposition."
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

  $fixtureManifest = Read-QualityJson -Path (Join-Path $repoRoot 'fixtures/manifest.json')
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
    Assert-Condition (Test-Path -LiteralPath (Join-Path $repoRoot ([string]$record.path)) -PathType Leaf) "Fixture '$($record.id)' path does not exist."
  }

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

function Assert-PhaseSourceAudit {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$AuditPath)

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

  Write-Host 'Phase 1 source audit verified exact inventory: 1 goal, 9 requirements, 16 decisions, 29 research items, 17 edges, 5 prohibitions.'
}
