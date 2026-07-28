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

function Assert-ExactSequence {
  param([string]$Label, [object[]]$Actual, [string[]]$Expected)
  $actualStrings = @($Actual | ForEach-Object { [string]$_ })
  Assert-Condition ($actualStrings.Count -eq $Expected.Count) "$Label count mismatch: expected $($Expected.Count), got $($actualStrings.Count)."
  for ($index = 0; $index -lt $Expected.Count; $index++) {
    Assert-Condition ($actualStrings[$index] -ceq $Expected[$index]) "$Label order mismatch at index $index`: expected '$($Expected[$index])', got '$($actualStrings[$index])'."
  }
}

function Get-PackageImportSet {
  param([string]$Text, [string]$Label)
  $imports = [System.Collections.Generic.List[string]]::new()
  $singlePattern = '(?m)^\s*import\s+"(?<name>[^"]+)"(?:\s+(?:as\s+\w+|@\w+))?\s*$'
  foreach ($match in [regex]::Matches($Text, $singlePattern)) {
    $imports.Add($match.Groups['name'].Value)
  }
  $blockPattern = '(?ms)^\s*import\s*\{\s*\r?\n(?<body>.*?)^\s*\}(?:\s+for\s+"[^"]+")?\s*$'
  foreach ($block in [regex]::Matches($Text, $blockPattern)) {
    $bodyLines = @($block.Groups['body'].Value -split '\r?\n' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    foreach ($line in $bodyLines) {
      $entry = [regex]::Match($line, '^\s*"(?<name>[^"]+)"(?:\s+(?:as\s+\w+|@\w+))?\s*,?\s*$')
      Assert-Condition $entry.Success "$Label contains an unsupported import entry: $line."
      $imports.Add($entry.Groups['name'].Value)
    }
  }
  $recognized = [regex]::Replace($Text, $blockPattern, '')
  $recognized = [regex]::Replace($recognized, $singlePattern, '')
  $unparsed = @($recognized -split '\r?\n' | Where-Object { $_ -cmatch '^\s*import\b' })
  Assert-Condition ($unparsed.Count -eq 0) "$Label contains an unsupported import declaration: $($unparsed -join ' | ')."
  return @($imports)
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
  $matches = @(Get-RfcTransitionLedgerRows -RfcText $RfcText | Where-Object { $_.from -ceq $From -and $_.to -ceq $To })
  Assert-Condition ($matches.Count -eq 1) "RFC transition ledger lacks exact '$From -> $To' row."
  return $matches[0]
}

function Get-RfcTransitionLedgerRows {
  param([string]$RfcText)
  $sectionMatches = @([regex]::Matches($RfcText, '(?ms)^##\s+Transition history\s*\r?\n(?<body>.*?)(?=^##\s+|\z)'))
  Assert-Condition ($sectionMatches.Count -eq 1) 'RFC must contain exactly one Transition history section.'
  $section = $sectionMatches[0].Groups['body'].Value
  $tableBlocks = @([regex]::Matches($section, '(?ms)(?:^\|[^\r\n]+\|\s*\r?\n){2,}'))
  Assert-Condition ($tableBlocks.Count -eq 1) 'RFC Transition history section must contain exactly one Markdown table.'
  $table = $tableBlocks[0].Value
  Assert-Condition ($table -cmatch '(?m)^\|\s*From\s*\|\s*To\s*\|\s*Evidence\s*\|\s*$') 'RFC Transition history table must use the From, To, and Evidence columns.'
  Assert-Condition ($table -cmatch '(?m)^\|\s*:?-{3,}:?\s*\|\s*:?-{3,}:?\s*\|\s*:?-{3,}:?\s*\|\s*$') 'RFC Transition history table lacks a valid separator row.'
  $rows = [System.Collections.Generic.List[object]]::new()
  foreach ($match in [regex]::Matches($table, '(?m)^\|\s*(?<from>[^|]+?)\s*\|\s*(?<to>[^|]+?)\s*\|\s*(?<evidence>[^\r\n|]+?)\s*\|\s*$')) {
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
    Assert-ReferencesInLedgerRow -Label 'Historical RFC acceptance' -References @($Rfc.acceptance_evidence) -LedgerRow $acceptedRow
  }
  if ($hasImplementedHistory) {
    $implementedRow = @($rows | Where-Object { $_.from -ceq 'Accepted' -and $_.to -ceq 'Implemented' })[0]
    Assert-ReferencesInLedgerRow -Label 'Historical RFC implementation and qualification' -References @(@($Rfc.implementation_evidence) + @($Rfc.qualification_evidence)) -LedgerRow $implementedRow
  }
}

function Assert-ReferencesInLedgerRow {
  param([string]$Label, [object[]]$References, [object]$LedgerRow)
  Assert-Condition ($References.Count -gt 0) "$Label requires at least one evidence reference."
  $strings = @($References | ForEach-Object { [string]$_ })
  Assert-Condition (@($strings | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -eq 0) "$Label contains an empty evidence reference."
  Assert-Condition (@($strings | Group-Object -CaseSensitive | Where-Object Count -ne 1).Count -eq 0) "$Label contains duplicate evidence references."
  $evidenceCell = if ($LedgerRow -is [string]) { [string]$LedgerRow } else { [string]$LedgerRow.evidence }
  $actual = @($evidenceCell -split ';' | ForEach-Object { $_.Trim() })
  Assert-Condition (@($actual | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -eq 0) "$Label ledger evidence contains an empty delimited reference."
  Assert-Condition (@($actual | Group-Object -CaseSensitive | Where-Object Count -ne 1).Count -eq 0) "$Label ledger evidence contains duplicate references."
  Assert-ExactSet "$Label ledger evidence" $actual $strings
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

function Get-MarkdownSectionByAnchor {
  param([string]$Text, [string]$Anchor)
  foreach ($match in [regex]::Matches($Text, '(?ms)^#{1,6}\s+(?<heading>.+?)\s*#*\s*\r?\n(?<body>.*?)(?=^#{1,6}\s+|\z)')) {
    $slug = $match.Groups['heading'].Value.ToLowerInvariant()
    $slug = [regex]::Replace($slug, '[^\p{L}\p{N}\s_-]', '')
    $slug = [regex]::Replace($slug.Trim(), '\s+', '-')
    if ($slug -ceq $Anchor.ToLowerInvariant()) { return $match.Groups['body'].Value }
  }
  throw "Markdown anchor '$Anchor' does not identify a section."
}

function Assert-ApprovalReference {
  param([string]$Reference, [string]$Identity, [string]$Role, [string]$RepositoryRoot, [object[]]$ExternalVerifications = @(), [DateTimeOffset]$Now = [DateTimeOffset]::UtcNow)
  Assert-Condition (-not [string]::IsNullOrWhiteSpace($Reference)) "Approval for '$Identity' requires a reference."
  $isHttps = $Reference -cmatch '^https://[^\s]+$'
  $repositoryMatch = [regex]::Match($Reference, '^(?<path>(?:docs|reviews|[.]planning)/[^\s#]+)#(?<anchor>[^\s#]+)$')
  $commitMatch = [regex]::Match($Reference, '^commit:(?<sha>[0-9a-f]{7,40})$')
  Assert-Condition ($isHttps -or $repositoryMatch.Success -or $commitMatch.Success) "Approval for '$Identity' must use an HTTPS review URL or stable repository reference."
  Assert-Condition ($Reference -cnotmatch '(?i)(placeholder|example|todo|tbd|dummy|fake)') "Approval for '$Identity' uses placeholder evidence."
  if ($isHttps) {
    $uri = [uri]$Reference
    $evidenceHost = $uri.DnsSafeHost.ToLowerInvariant()
    $reserved = $evidenceHost -in @('localhost','example.com','example.net','example.org') -or $evidenceHost -cmatch '[.](?:invalid|test|example)$'
    Assert-Condition (-not $reserved) "Approval for '$Identity' uses a reserved non-evidentiary HTTPS host '$evidenceHost'."
    $records = @($ExternalVerifications | Where-Object { [string]$_.reference -ceq $Reference })
    Assert-Condition ($records.Count -eq 1) "External evidence '$Reference' requires exactly one verification record."
    $record = $records[0]
    Assert-Condition ([string]$record.method -ceq 'manual') "External evidence '$Reference' verification method must be manual."
    Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$record.verified_by)) "External evidence '$Reference' requires verified_by."
    $verifiedAtText = [string]$record.verified_at
    $verifiedAt = ConvertFrom-RfcTimestamp -Value $verifiedAtText -Label "External evidence '$Reference' verification timestamp"
    Assert-Condition ($verifiedAt -le $Now) "External evidence '$Reference' verification timestamp must have elapsed."
    $verificationMatch = [regex]::Match([string]$record.verification_reference, '^(?<path>(?:docs|reviews|[.]planning)/[^\s#]+)#(?<anchor>[^\s#]+)$')
    Assert-Condition $verificationMatch.Success "External evidence '$Reference' verification_reference must identify a repository Markdown anchor."
    $verificationFile = Resolve-RepositoryLeafFile -RepositoryRoot $RepositoryRoot -RelativePath $verificationMatch.Groups['path'].Value -Label "External evidence '$Reference' verification"
    $section = Get-MarkdownSectionByAnchor -Text (Get-Content -LiteralPath $verificationFile -Raw) -Anchor $verificationMatch.Groups['anchor'].Value
    foreach ($binding in @(
      [pscustomobject]@{ label='External-Reference'; value=$Reference },
      [pscustomobject]@{ label='Method'; value='manual' },
      [pscustomobject]@{ label='Verified-By'; value=[string]$record.verified_by },
      [pscustomobject]@{ label='Verified-At'; value=$verifiedAtText },
      [pscustomobject]@{ label='Disposition'; value='verified' }
    )) {
      Assert-Condition ($section -cmatch "(?m)^- \*\*$([regex]::Escape($binding.label)):\*\* $([regex]::Escape([string]$binding.value))\s*$") "External evidence verification artifact does not bind $($binding.label) for '$Reference'."
    }
    return
  }
  if ($repositoryMatch.Success) {
    $approvalFile = Resolve-RepositoryLeafFile -RepositoryRoot $RepositoryRoot -RelativePath $repositoryMatch.Groups['path'].Value -Label "Approval for '$Identity'"
    $section = Get-MarkdownSectionByAnchor -Text (Get-Content -LiteralPath $approvalFile -Raw) -Anchor $repositoryMatch.Groups['anchor'].Value
    Assert-Condition ($section -cmatch "(?m)^- \*\*Identity:\*\* $([regex]::Escape($Identity))\s*$") "Approval artifact does not bind identity '$Identity'."
    Assert-Condition ($section -cmatch "(?m)^- \*\*Role:\*\* $([regex]::Escape($Role))\s*$") "Approval artifact does not bind role '$Role'."
    Assert-Condition ($section -cmatch '(?m)^- \*\*Disposition:\*\* approved\s*$') "Approval artifact for '$Identity' is not approved."
    return
  }
  $sha = $commitMatch.Groups['sha'].Value
  & git -C $RepositoryRoot cat-file -e "$sha`^{commit}" 2>$null
  Assert-Condition ($LASTEXITCODE -eq 0) "Approval commit '$sha' does not exist in the repository."
  $message = (& git -C $RepositoryRoot show -s --format=%B $sha 2>$null) -join "`n"
  foreach ($trailer in @(
    [pscustomobject]@{ name='Approval-Identity'; expected=$Identity },
    [pscustomobject]@{ name='Approval-Role'; expected=$Role },
    [pscustomobject]@{ name='Approval-Disposition'; expected='approved' }
  )) {
    $matches = @([regex]::Matches($message, "(?m)^$([regex]::Escape($trailer.name)):[\t ]*(?<value>[^\r\n]*)[\t ]*\r?$"))
    Assert-Condition ($matches.Count -eq 1) "Approval commit '$sha' must contain exactly one $($trailer.name) trailer."
    Assert-Condition ($matches[0].Groups['value'].Value.Trim() -ceq [string]$trailer.expected) "Approval commit '$sha' has invalid $($trailer.name) disposition or binding."
  }
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

function Resolve-PhaseSourceAuditFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$RepositoryRoot,
    [Parameter(Mandatory)][string]$RelativePath,
    [Parameter(Mandatory)][string]$Label
  )

  $normalized = $RelativePath.Replace('\','/')
  $archivePhasePrefix = '.planning/milestones/v0.1-phases/01-foundation-charter-and-reproducible-workspace/'
  $isCanonicalArchive = (
    $normalized -ceq '.planning/milestones/v0.1-ROADMAP.md' -or
    $normalized -ceq '.planning/milestones/v0.1-REQUIREMENTS.md' -or
    $normalized.StartsWith($archivePhasePrefix, [System.StringComparison]::Ordinal)
  )
  Assert-Condition $isCanonicalArchive "$Label must identify the canonical v0.1 milestone archive, not a mutable active-milestone path."
  return Resolve-RepositoryLeafFile -RepositoryRoot $RepositoryRoot -RelativePath $normalized -Label $Label
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

function Resolve-RfcArtifactReference {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Reference,
    [Parameter(Mandatory)][ValidateSet('implementation','qualification')][string]$Purpose,
    [Parameter(Mandatory)][string]$RfcId,
    [Parameter(Mandatory)][string]$RepositoryRoot
  )
  if ($Purpose -ceq 'implementation') {
    $commitMatch = [regex]::Match($Reference, '^commit:(?<sha>[0-9a-f]{7,40})$')
    Assert-Condition $commitMatch.Success "Implementation evidence '$Reference' must use commit:<sha>."
    $sha = $commitMatch.Groups['sha'].Value
    $canonicalSha = (& git -C $RepositoryRoot rev-parse --verify "$sha`^{commit}" 2>$null) -join ''
    Assert-Condition ($LASTEXITCODE -eq 0 -and $canonicalSha -cmatch '^[0-9a-f]{40}$') "Implementation commit '$sha' does not exist in the repository."
    return [pscustomobject]@{ kind='commit'; target="commit:$canonicalSha" }
  }

  $reportMatch = [regex]::Match($Reference, '^report:(?<path>reports/[A-Za-z0-9._/-]+[.]md)#(?<anchor>[a-z0-9][a-z0-9-]*)$')
  Assert-Condition $reportMatch.Success "Qualification evidence '$Reference' must use report:reports/<file>.md#<anchor>."
  $reportPath = $reportMatch.Groups['path'].Value
  $reportFile = Resolve-RepositoryLeafFile -RepositoryRoot $RepositoryRoot -RelativePath $reportPath -Label 'Qualification report'
  $anchor = $reportMatch.Groups['anchor'].Value
  $section = Get-MarkdownSectionByAnchor -Text (Get-Content -LiteralPath $reportFile -Raw) -Anchor $anchor
  Assert-Condition ($section -cmatch "(?m)^- \*\*RFC:\*\* $([regex]::Escape($RfcId))\s*$") "Qualification report '$Reference' does not bind RFC $RfcId."
  Assert-Condition ($section -cmatch '(?m)^- \*\*Disposition:\*\* qualified\s*$') "Qualification report '$Reference' does not record a qualified disposition."
  return [pscustomobject]@{ kind='report'; target=('file:' + [System.IO.Path]::GetFullPath($reportFile).ToLowerInvariant()) }
}

function Assert-RfcImplementationArtifacts {
  param([object]$Rfc, [string]$RepositoryRoot)
  $implementationEvidence = @($Rfc.implementation_evidence)
  $qualificationEvidence = @($Rfc.qualification_evidence)
  Assert-Condition ($implementationEvidence.Count -gt 0) 'Implemented RFC implementation evidence requires at least one reference.'
  Assert-Condition ($qualificationEvidence.Count -gt 0) 'Implemented RFC qualification evidence requires at least one reference.'
  $implementationArtifacts = @($implementationEvidence | ForEach-Object { Resolve-RfcArtifactReference -Reference ([string]$_) -Purpose implementation -RfcId ([string]$Rfc.id) -RepositoryRoot $RepositoryRoot })
  $qualificationArtifacts = @($qualificationEvidence | ForEach-Object { Resolve-RfcArtifactReference -Reference ([string]$_) -Purpose qualification -RfcId ([string]$Rfc.id) -RepositoryRoot $RepositoryRoot })
  $overlap = @($implementationArtifacts.target | Where-Object { $qualificationArtifacts.target -ccontains $_ })
  Assert-Condition ($overlap.Count -eq 0) 'Implementation and qualification evidence must identify distinct artifacts.'
}

function Assert-FixtureManifest {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$ManifestPath,
    [Parameter(Mandatory)][string]$RepositoryRoot
  )
  $fixtureManifest = Read-QualityJson -Path $ManifestPath
  Assert-Condition ($fixtureManifest.schema_version -ceq '1.0.0') 'Fixture manifest schema_version must be 1.0.0.'
  Assert-Condition ($fixtureManifest.preferred_origin -ceq 'generated') 'Fixture preferred_origin must be generated.'
  Assert-ExactSet 'Fixture required fields' @($fixtureManifest.required_record_fields) @('id','path','origin','source','author','retrieval_date','sha256','license','redistribution_status','expected_use')
  Assert-ExactSet 'Fixture allowed origins' @($fixtureManifest.allowed_origins) @('generated','external')
  Assert-ExactSet 'Fixture redistribution statuses' @($fixtureManifest.allowed_redistribution_statuses) @('confirmed','not-applicable','unconfirmed')
  Assert-Condition ($fixtureManifest.external_requires_confirmed_redistribution -eq $true) 'External fixtures must always require confirmed redistribution.'
  $fixtureIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
  foreach ($record in @($fixtureManifest.records)) {
    foreach ($field in @($fixtureManifest.required_record_fields)) {
      Assert-Condition ($null -ne $record.$field -and -not [string]::IsNullOrWhiteSpace([string]$record.$field)) "Fixture record is missing '$field'."
    }
    Assert-Condition ($fixtureIds.Add([string]$record.id)) "Duplicate fixture id '$($record.id)'."
    Assert-Condition (@($fixtureManifest.allowed_origins) -ccontains $record.origin) "Fixture '$($record.id)' has invalid origin."
    Assert-Condition (@($fixtureManifest.allowed_redistribution_statuses) -ccontains $record.redistribution_status) "Fixture '$($record.id)' has invalid redistribution status."
    Assert-Condition ([string]$record.sha256 -cmatch '^[0-9a-f]{64}$') "Fixture '$($record.id)' has invalid SHA-256."
    $retrievalDate = [DateOnly]::MinValue
    $validRetrievalDate = [DateOnly]::TryParseExact([string]$record.retrieval_date, 'yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$retrievalDate)
    Assert-Condition $validRetrievalDate "Fixture '$($record.id)' has invalid retrieval date."
    if ($record.origin -ceq 'external') {
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
  $canonicalRosterPath = 'policy/maintainers.json'
  $canonicalRfcPath = 'docs/rfcs/0001-moonbit-native-foundation.md'
  $canonicalIndexPath = 'docs/rfcs/README.md'
  $canonicalDecisionPath = 'docs/governance/decisions/0001-sole-owner-bootstrap.md'
  $canonicalDecisionAnchors = @('owner-instruction','conversation-context-and-interpretation','authorization-and-conditions','edge-review-results')
  $canonicalEdgeReviewIds = @('EDGE-GOV-01-UNCLASSIFIED','EDGE-GOV-02-UNCLASSIFIED')
  Assert-Condition (@($rfcPolicy.allowed_statuses) -ccontains $rfc.status) "RFC status '$($rfc.status)' is not allowed."
  Assert-ExactSet 'RFC acceptance routes' @($rfcPolicy.acceptance_routes) @('maintainer','project-lead-public-review','sole-project-owner-bootstrap')
  Assert-Condition ([string]$rfcPolicy.sole_owner_bootstrap.decision_path -ceq $canonicalDecisionPath) 'Sole-owner policy decision path differs from the canonical artifact.'
  Assert-ExactSet 'Sole-owner policy decision anchors' @($rfcPolicy.sole_owner_bootstrap.required_anchors) $canonicalDecisionAnchors
  Assert-ExactSet 'Sole-owner policy edge review IDs' @($rfcPolicy.sole_owner_bootstrap.mandatory_edge_reviews) $canonicalEdgeReviewIds

  Assert-Condition ([string]$rfcPolicy.maintainer_roster_path -ceq $canonicalRosterPath) 'RFC policy maintainer roster path differs from the canonical artifact.'
  $canonicalRosterFile = Resolve-RepositoryLeafFile -RepositoryRoot $RepositoryRoot -RelativePath $canonicalRosterPath -Label 'Canonical maintainer roster'
  Assert-Condition ([System.IO.Path]::GetFullPath($RosterPath) -ceq $canonicalRosterFile) 'RFC acceptance must use the canonical maintainer roster path.'
  $roster = Read-QualityJson -Path $canonicalRosterFile
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

  Assert-Condition ([string]$rfc.path -ceq $canonicalRfcPath) 'Foundation RFC policy path differs from the canonical artifact.'
  $rfcPath = Resolve-RepositoryLeafFile -RepositoryRoot $RepositoryRoot -RelativePath $canonicalRfcPath -Label 'Canonical foundation RFC'
  $rfcText = Get-Content -LiteralPath $rfcPath -Raw
  Assert-Condition ($rfcText -cmatch "(?m)^- \*\*Status:\*\* $([regex]::Escape([string]$rfc.status))\s*$") 'RFC header status does not match policy.'
  $indexPath = Resolve-RepositoryLeafFile -RepositoryRoot $RepositoryRoot -RelativePath $canonicalIndexPath -Label 'Canonical RFC index'
  $indexText = Get-Content -LiteralPath $indexPath -Raw
  $indexRowPattern = "(?m)^\|\s*\[RFC 0001\]\(0001-moonbit-native-foundation[.]md\)\s*\|[^\r\n|]+\|\s*$([regex]::Escape([string]$rfc.status))\s*\|[^\r\n|]+\|\s*$"
  Assert-Condition ($indexText -cmatch $indexRowPattern) 'RFC index row must link the canonical RFC and match policy status.'

  $transition = Get-RequiredProperty $rfc 'transition' 'Foundation RFC'
  $transitionFrom = [string](Get-RequiredProperty $transition 'from' 'Foundation RFC transition')
  $transitionTo = [string](Get-RequiredProperty $transition 'to' 'Foundation RFC transition')
  $transitionEvidence = @(Get-RequiredProperty $transition 'evidence' 'Foundation RFC transition')
  $externalVerifications = @(Get-RequiredProperty $rfc 'external_evidence_verifications' 'Foundation RFC')
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
  $hasAcceptedHistory = [string]$rfc.status -in @('Accepted','Implemented') -or ([string]$rfc.status -ceq 'Superseded' -and $transitionFrom -in @('Accepted','Implemented'))
  $hasImplementedHistory = [string]$rfc.status -ceq 'Implemented' -or ([string]$rfc.status -ceq 'Superseded' -and $transitionFrom -ceq 'Implemented')

  if ($rfc.status -in @('Draft','Proposed')) {
    Assert-NullOrEmpty 'acceptance_route' $rfc.acceptance_route
    Assert-NullOrEmpty 'authority' $rfc.authority
    Assert-Condition (@($rfc.approvers).Count -eq 0) 'Proposed RFC must not record approvers.'
    Assert-NullOrEmpty 'project_lead' $rfc.project_lead
    Assert-NullOrEmpty 'public_review_url' $rfc.public_review_url
    Assert-NullOrEmpty 'public_review_started_at' $rfc.public_review_started_at
    Assert-NullOrEmpty 'public_review_ended_at' $rfc.public_review_ended_at
    Assert-NullOrEmpty 'public_review_evidence' $rfc.public_review_evidence
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
    $replacementRelativePath = 'docs/rfcs/' + $replacement[0].Name
    $replacementFile = Resolve-RepositoryLeafFile -RepositoryRoot $RepositoryRoot -RelativePath $replacementRelativePath -Label "Superseded RFC replacement '$replacementId'"
    $replacementText = Get-Content -LiteralPath $replacementFile -Raw
    $identityMatches = @([regex]::Matches($replacementText, "(?m)^# RFC $([regex]::Escape($replacementId)): [^\r\n]+\s*$"))
    Assert-Condition ($identityMatches.Count -eq 1) "Replacement RFC '$replacementId' must contain one canonical RFC identity heading."
    $statusMatches = @([regex]::Matches($replacementText, '(?m)^- \*\*Status:\*\* (?<status>Draft|Proposed|Accepted|Implemented|Rejected|Superseded)\s*$'))
    Assert-Condition ($statusMatches.Count -eq 1) "Replacement RFC '$replacementId' must contain one lifecycle status header."
    $replacementStatus = $statusMatches[0].Groups['status'].Value
    Assert-Condition ($replacementStatus -in @('Draft','Proposed','Accepted','Implemented')) "Replacement RFC '$replacementId' must have a non-terminal reviewable status."
    $currentRfcName = [System.IO.Path]::GetFileName($canonicalRfcPath)
    $backReferencePattern = "(?m)^- \*\*Supersedes:\*\* \[RFC $([regex]::Escape([string]$rfc.id))\]\($([regex]::Escape($currentRfcName))\)\s*$"
    Assert-Condition ($replacementText -cmatch $backReferencePattern) "Replacement RFC '$replacementId' must contain a canonical back-reference to RFC $($rfc.id)."
    $replacementLedgerRows = @(Get-RfcTransitionLedgerRows -RfcText $replacementText)
    Assert-Condition ($replacementLedgerRows.Count -gt 0 -and [string]$replacementLedgerRows[-1].to -ceq $replacementStatus) "Replacement RFC '$replacementId' transition ledger must end at its declared status."
    $supersessionEvidence = @($rfc.supersession_evidence)
    Assert-ReferencesInLedgerRow -Label 'Superseded RFC transition' -References $supersessionEvidence -LedgerRow $transitionRow
    Assert-ExactSet 'Superseded RFC transition evidence' $transitionEvidence $supersessionEvidence
    Assert-ExactSet 'Supersession evidence canonical replacement path' $supersessionEvidence @($replacementRelativePath)
    if ($hasImplementedHistory) {
      Assert-RfcImplementationArtifacts -Rfc $rfc -RepositoryRoot $RepositoryRoot
    } else {
      Assert-NullOrEmpty 'implementation_evidence' $rfc.implementation_evidence
      Assert-NullOrEmpty 'qualification_evidence' $rfc.qualification_evidence
    }
    Assert-NullOrEmpty 'rejection_disposition' $rfc.rejection_disposition
    if (-not $hasAcceptedHistory) {
      Assert-NullOrEmpty 'acceptance_route' $rfc.acceptance_route
      Assert-NullOrEmpty 'authority' $rfc.authority
      Assert-Condition (@($rfc.approvers).Count -eq 0 -and @($rfc.approval_records).Count -eq 0) 'Superseded RFC without Accepted history must not assert approvals.'
      Assert-NullOrEmpty 'project_lead' $rfc.project_lead; Assert-NullOrEmpty 'project_owner' $rfc.project_owner
      Assert-NullOrEmpty 'public_review_url' $rfc.public_review_url; Assert-NullOrEmpty 'public_review_started_at' $rfc.public_review_started_at; Assert-NullOrEmpty 'public_review_ended_at' $rfc.public_review_ended_at; Assert-NullOrEmpty 'public_review_evidence' $rfc.public_review_evidence
      Assert-NullOrEmpty 'decision_evidence_path' $rfc.decision_evidence_path
      Assert-Condition (@($rfc.decision_evidence_anchors).Count -eq 0 -and @($rfc.acceptance_evidence).Count -eq 0) 'Superseded RFC without Accepted history must not assert acceptance evidence.'
      Assert-Condition (@($externalVerifications).Count -eq 0) 'Superseded RFC without Accepted history must not assert external evidence verification.'
      return
    }
  }

  Assert-Condition (@($rfcPolicy.acceptance_routes) -ccontains $rfc.acceptance_route) 'Accepted RFC has an unknown acceptance route.'
  Assert-Condition ($rfc.blocking_objections -ceq 'none') 'Accepted RFC must have zero unresolved blocking objections.'
  Assert-Condition (-not [string]::IsNullOrWhiteSpace([string]$rfc.objection_disposition)) 'Accepted RFC requires an objection disposition.'
  Assert-Condition (@($rfc.acceptance_evidence).Count -gt 0) 'Accepted RFC requires acceptance evidence.'

  if ($rfc.status -ceq 'Accepted') {
    Assert-ExactSet 'Accepted RFC transition evidence' $transitionEvidence @($rfc.acceptance_evidence)
    Assert-NullOrEmpty 'implementation_evidence' $rfc.implementation_evidence
    Assert-NullOrEmpty 'qualification_evidence' $rfc.qualification_evidence
  } elseif ($rfc.status -ceq 'Implemented') {
    $implementationEvidence = @($rfc.implementation_evidence)
    $qualificationEvidence = @($rfc.qualification_evidence)
    Assert-Condition ($implementationEvidence.Count -gt 0) 'Implemented RFC implementation evidence requires at least one reference.'
    Assert-Condition ($qualificationEvidence.Count -gt 0) 'Implemented RFC qualification evidence requires at least one reference.'
    Assert-ReferencesInLedgerRow -Label 'Implemented RFC implementation and qualification evidence' -References @($implementationEvidence + $qualificationEvidence) -LedgerRow $transitionRow
    Assert-ExactSet 'Implemented RFC transition evidence' $transitionEvidence @($implementationEvidence + $qualificationEvidence)
    Assert-RfcImplementationArtifacts -Rfc $rfc -RepositoryRoot $RepositoryRoot
  } elseif (-not $hasImplementedHistory) {
    Assert-NullOrEmpty 'implementation_evidence' $rfc.implementation_evidence
    Assert-NullOrEmpty 'qualification_evidence' $rfc.qualification_evidence
  }
  Assert-NullOrEmpty 'rejection_disposition' $rfc.rejection_disposition
  if ($rfc.status -cne 'Superseded') {
    Assert-NullOrEmpty 'superseded_by' $rfc.superseded_by
    Assert-NullOrEmpty 'supersession_evidence' $rfc.supersession_evidence
  }

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
        Assert-ApprovalReference -Reference ([string]$approval.reference) -Identity ([string]$approval.identity) -Role 'maintainer' -RepositoryRoot $RepositoryRoot -ExternalVerifications $externalVerifications -Now $Now
      }
      Assert-ExactSet 'Maintainer acceptance evidence' @($rfc.acceptance_evidence) @($approvalRecords.reference)
      Assert-Condition ($rfc.authority -ceq 'maintainers') 'Maintainer route authority must be maintainers.'
      Assert-NullOrEmpty 'project_lead' $rfc.project_lead; Assert-NullOrEmpty 'project_owner' $rfc.project_owner
      Assert-NullOrEmpty 'public_review_url' $rfc.public_review_url; Assert-NullOrEmpty 'public_review_started_at' $rfc.public_review_started_at; Assert-NullOrEmpty 'public_review_ended_at' $rfc.public_review_ended_at
      Assert-NullOrEmpty 'public_review_evidence' $rfc.public_review_evidence
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
      Assert-ApprovalReference -Reference ([string]$leadApprovals[0].reference) -Identity ([string]$rfc.project_lead) -Role 'project-lead' -RepositoryRoot $RepositoryRoot -ExternalVerifications $externalVerifications -Now $Now
      $reviewEvidence = Get-RequiredProperty $rfc 'public_review_evidence' 'Project-lead RFC'
      Assert-Condition ($null -ne $reviewEvidence) 'Project-lead route requires structured public-review evidence.'
      $locationReference = [string](Get-RequiredProperty $reviewEvidence 'location_reference' 'Public-review evidence')
      $opened = Get-RequiredProperty $reviewEvidence 'opened' 'Public-review evidence'
      $closed = Get-RequiredProperty $reviewEvidence 'closed' 'Public-review evidence'
      $openedAt = [string](Get-RequiredProperty $opened 'at' 'Public-review opening evidence')
      $openedReference = [string](Get-RequiredProperty $opened 'reference' 'Public-review opening evidence')
      $closedAt = [string](Get-RequiredProperty $closed 'at' 'Public-review closing evidence')
      $closedReference = [string](Get-RequiredProperty $closed 'reference' 'Public-review closing evidence')
      Assert-Condition ($locationReference -ceq [string]$rfc.public_review_url) 'Public-review location evidence must equal the declared review URL.'
      Assert-Condition ($openedAt -ceq [string]$rfc.public_review_started_at -and $closedAt -ceq [string]$rfc.public_review_ended_at) 'Public-review opening and closing evidence must bind the declared interval values.'
      foreach ($reference in @($locationReference,$openedReference,$closedReference)) { Assert-ApprovalReference -Reference $reference -Identity 'public-review' -Role 'evidence' -RepositoryRoot $RepositoryRoot -ExternalVerifications $externalVerifications -Now $Now }
      $expectedLeadEvidence = @([string]$leadApprovals[0].reference,$locationReference,$openedReference,$closedReference)
      Assert-ExactSet 'Project-lead acceptance evidence' @($rfc.acceptance_evidence) $expectedLeadEvidence
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
      Assert-NullOrEmpty 'project_lead' $rfc.project_lead; Assert-NullOrEmpty 'public_review_url' $rfc.public_review_url; Assert-NullOrEmpty 'public_review_started_at' $rfc.public_review_started_at; Assert-NullOrEmpty 'public_review_ended_at' $rfc.public_review_ended_at; Assert-NullOrEmpty 'public_review_evidence' $rfc.public_review_evidence
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
      $authorizationSection = Get-MarkdownSection -Text $decisionText -Heading 'Authorization and conditions'
      $edgeSection = Get-MarkdownSection -Text $decisionText -Heading 'Edge review results'
      Assert-Condition ($ownerSection.Contains('现在只有我一个人开发，跳过', [System.StringComparison]::Ordinal) -and $contextSection -cmatch 'preauthoriz') 'Decision artifact does not preserve the authentic conditional preauthorization in its named sections.'
      $canonicalAuthorizationLines = @(
        '- `AUTH-ONE-OWNER`: Eligibility requires the canonical roster to contain exactly one unique maintainer identity with the project-owner role.',
        '- `AUTH-EXPIRES-SECOND-MAINTAINER`: Eligibility expires immediately when a second distinct maintainer is present.',
        '- `AUTH-TWO-EDGE-REVIEWS`: EDGE-GOV-01-UNCLASSIFIED and EDGE-GOV-02-UNCLASSIFIED must both be completed and dispositioned.',
        '- `AUTH-NO-LATER-APPROVAL`: The recorded owner instruction is consumed; no later approval may be synthesized.'
      )
      foreach ($line in $canonicalAuthorizationLines) {
        Assert-Condition ($authorizationSection.Contains($line, [System.StringComparison]::Ordinal)) "Decision artifact authorization section lacks canonical condition '$line'."
      }
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
  $httpsAcceptanceReferences = @($rfc.acceptance_evidence | ForEach-Object { [string]$_ } | Where-Object { $_ -cmatch '^https://' })
  Assert-ExactSet 'External evidence verification references' @($externalVerifications | ForEach-Object { [string]$_.reference }) $httpsAcceptanceReferences
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

  $expectedModules = @('tchivs/mb-core', 'tchivs/mb-color', 'tchivs/mb-image', 'tchivs/mb-canvas', 'tchivs/mb-font')
  $expectedPaths = @('modules/mb-core', 'modules/mb-color', 'modules/mb-image', 'modules/mb-canvas', 'modules/mb-font')
  Assert-ExactSet 'Policy modules' @($policy.modules.name) $expectedModules
  Assert-ExactSet 'Policy module paths' @($policy.modules.path) $expectedPaths
  Assert-AcyclicDependencyGraph -Modules @($policy.modules) -AllowedEdges @($policy.allowed_dependency_edges)

  $workText = Get-Content -LiteralPath (Join-Path $repoRoot 'moon.work') -Raw
  $workMembers = @([regex]::Matches($workText, '"\./([^"\r\n]+)"') | ForEach-Object { $_.Groups[1].Value })
  Assert-ExactSet 'moon.work members' $workMembers @($expectedPaths + @('modules/mb-svg', 'examples/ppm-portable', 'examples/ppm-native-cli', 'examples/qoi-portable', 'examples/png-portable', 'examples/mb-svg-demo'))

  foreach ($module in $policy.modules) {
    Assert-Condition ($module.version -ceq '0.1.0') "Policy version drift for $($module.name)."
    Assert-Condition (@($policy.stability.allowed_labels) -ccontains $module.stability) "Invalid stability label for $($module.name)."
    Assert-ExactSet "Policy targets for $($module.name)" @($module.supported_targets) @($policy.required_targets)
    $packages = @($module.public_packages)
    Assert-Condition ($packages.Count -gt 0) "$($module.name) must declare at least one public package."
    Assert-ExactSet "Public package names for $($module.name)" @($packages.name) @($packages | ForEach-Object { [string]$_.name })
    Assert-ExactSet "Public package paths for $($module.name)" @($packages.path) @($packages | ForEach-Object { [string]$_.path })

    if ($module.name -ceq 'tchivs/mb-core') {
      $corePackagePaths = @('error', 'checked', 'budget', 'bytes', 'io', 'host', 'math', 'bits', 'crc', 'text', 'unicode')
      $corePackageNames = @($corePackagePaths | ForEach-Object { "tchivs/mb-core/$_" })
      Assert-ExactSequence 'mb-core public package spine' @($packages.name) $corePackageNames
      Assert-ExactSequence 'mb-core public package paths' @($packages.path) $corePackagePaths
      foreach ($removedRootFile in @('moon.pkg', 'scaffold.mbt', 'scaffold_wbtest.mbt')) {
        Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $repoRoot "modules/mb-core/$removedRootFile"))) "Obsolete mb-core root scaffold file remains: $removedRootFile."
      }
    }

    if ($module.name -ceq 'tchivs/mb-color') {
      $colorPackagePaths = @('model', 'transfer', 'quantize', 'alpha', 'profile', 'blend')
      $colorPackageNames = @($colorPackagePaths | ForEach-Object { "tchivs/mb-color/$_" })
      Assert-ExactSequence 'mb-color publication package order' @($packages.name) $colorPackageNames
      Assert-ExactSequence 'mb-color public package paths' @($packages.path) $colorPackagePaths
      foreach ($removedRootFile in @('moon.pkg', 'scaffold.mbt', 'scaffold_wbtest.mbt')) {
        Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $repoRoot "modules/mb-color/$removedRootFile"))) "Obsolete mb-color root scaffold file remains: $removedRootFile."
      }

      $colorImports = @{}
      foreach ($colorPackage in $packages) {
        $colorImports[[string]$colorPackage.path] = @($colorPackage.allowed_imports)
      }
      Assert-ExactSet 'mb-color model DAG edges' $colorImports.model @('tchivs/mb-core/error')
      Assert-ExactSet 'mb-color transfer DAG edges' $colorImports.transfer @('tchivs/mb-color/model', 'moonbitlang/core/math')
      Assert-ExactSet 'mb-color quantize DAG edges' $colorImports.quantize @('tchivs/mb-color/model', 'tchivs/mb-core/error', 'tchivs/mb-core/checked')
      Assert-Condition (-not ($colorImports.quantize -ccontains 'tchivs/mb-color/transfer')) 'mb-color quantize must remain independent of transfer.'
      Assert-ExactSet 'mb-color alpha DAG edges' $colorImports.alpha @('tchivs/mb-color/model', 'tchivs/mb-color/quantize', 'tchivs/mb-core/error', 'tchivs/mb-core/checked')
      Assert-ExactSet 'mb-color profile DAG edges' $colorImports.profile @('tchivs/mb-core/error', 'tchivs/mb-core/budget', 'tchivs/mb-core/bytes')
      Assert-Condition (@($colorImports.profile | Where-Object { $_ -clike 'tchivs/mb-color/*' }).Count -eq 0) 'mb-color profile must remain independent of every color package.'
    }

    if ($module.name -ceq 'tchivs/mb-image') {
      $imagePackagePaths = @('metadata', 'model', 'storage', 'ops', 'codec', 'ppm', 'qoi', 'png')
      $imagePackageNames = @($imagePackagePaths | ForEach-Object { "tchivs/mb-image/$_" })
      Assert-ExactSequence 'mb-image publication package order' @($packages.name) $imagePackageNames
      Assert-ExactSequence 'mb-image public package paths' @($packages.path) $imagePackagePaths
      foreach ($removedRootFile in @('moon.pkg', 'scaffold.mbt', 'scaffold_wbtest.mbt')) {
        Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $repoRoot "modules/mb-image/$removedRootFile"))) "Obsolete mb-image root scaffold file remains: $removedRootFile."
      }

      $imageImports = @{}
      foreach ($imagePackage in $packages) {
        $imageImports[[string]$imagePackage.path] = @($imagePackage.allowed_imports)
      }
      Assert-ExactSet 'mb-image metadata DAG edges' $imageImports.metadata @('tchivs/mb-core/error', 'tchivs/mb-core/budget', 'tchivs/mb-core/bytes')
      Assert-ExactSet 'mb-image model DAG edges' $imageImports.model @('tchivs/mb-core/error', 'tchivs/mb-core/checked', 'tchivs/mb-core/budget', 'tchivs/mb-color/model', 'tchivs/mb-color/profile', 'tchivs/mb-image/metadata')
      Assert-ExactSet 'mb-image storage DAG edges' $imageImports.storage @('tchivs/mb-core/error', 'tchivs/mb-core/checked', 'tchivs/mb-core/budget', 'tchivs/mb-core/bytes', 'tchivs/mb-color/model', 'tchivs/mb-color/profile', 'tchivs/mb-image/metadata', 'tchivs/mb-image/model')
      Assert-ExactSet 'mb-image ppm DAG edges' $imageImports.ppm @('tchivs/mb-core/budget', 'tchivs/mb-core/bytes', 'tchivs/mb-core/checked', 'tchivs/mb-core/error', 'tchivs/mb-core/io', 'tchivs/mb-color/model', 'tchivs/mb-color/profile', 'tchivs/mb-image/codec', 'tchivs/mb-image/metadata', 'tchivs/mb-image/model', 'tchivs/mb-image/storage')
      $ppmPolicy = @($packages | Where-Object { $_.path -ceq 'ppm' })[0]
      Assert-ExactSequence 'mb-image ppm production source order' @($ppmPolicy.production_sources) @('moon.pkg', 'ppm.mbt', 'parser.mbt', 'decode.mbt', 'encode.mbt', 'generated_vectors.mbt')
      Assert-ExactSet 'mb-image qoi DAG edges' $imageImports.qoi @('tchivs/mb-core/budget', 'tchivs/mb-core/bytes', 'tchivs/mb-core/checked', 'tchivs/mb-core/error', 'tchivs/mb-core/io', 'tchivs/mb-color/model', 'tchivs/mb-color/profile', 'tchivs/mb-image/codec', 'tchivs/mb-image/metadata', 'tchivs/mb-image/model', 'tchivs/mb-image/storage')
      $qoiPolicy = @($packages | Where-Object { $_.path -ceq 'qoi' })[0]
      Assert-ExactSequence 'mb-image qoi production source order' @($qoiPolicy.production_sources) @('moon.pkg', 'qoi.mbt', 'decode.mbt', 'encode.mbt', 'generated_vectors.mbt', 'stream_decode.mbt', 'stream_encode.mbt')
      Assert-ExactSet 'mb-image ops DAG edges' $imageImports.ops @('tchivs/mb-core/error', 'tchivs/mb-core/checked', 'tchivs/mb-core/budget', 'tchivs/mb-core/bytes', 'tchivs/mb-color/alpha', 'tchivs/mb-color/model', 'tchivs/mb-color/profile', 'tchivs/mb-color/transfer', 'tchivs/mb-color/quantize', 'tchivs/mb-image/metadata', 'tchivs/mb-image/model', 'tchivs/mb-image/storage')
      Assert-ExactSet 'mb-image codec DAG edges' $imageImports.codec @('tchivs/mb-core/error', 'tchivs/mb-core/budget', 'tchivs/mb-core/bytes', 'tchivs/mb-core/io', 'tchivs/mb-image/metadata', 'tchivs/mb-image/model', 'tchivs/mb-image/storage')
      Assert-Condition (-not ($imageImports.codec -ccontains 'tchivs/mb-core/host')) 'mb-image codec must remain independent of host policy.'
      Assert-Condition (-not ($imageImports.codec -ccontains 'tchivs/mb-image/ops')) 'mb-image codec must remain independent of image operations.'

      $storagePolicy = @($packages | Where-Object { $_.path -ceq 'storage' })[0]
      $storageInterface = @($storagePolicy.semantic_interface)
      $safeOperationFactory = 'pub fn OwnedImage::new_operation(@model.ImageDescriptor, @budget.Budget, &@bytes.Allocator, UInt64) -> Result[Self, @error.CoreError]'
      $stableViewFactory = 'pub fn OwnedImage::view(Self) -> ImageView'
      Assert-Condition ($storageInterface -ccontains $safeOperationFactory) 'mb-image storage must expose only the descriptor-plus-work operation allocation seam.'
      Assert-Condition ($storageInterface -ccontains $stableViewFactory) 'OwnedImage::view() -> ImageView public interface drifted.'
      Assert-Condition (@($storageInterface | Where-Object { $_ -cmatch '^pub fn OwnedImage::new_operation' -and $_ -cne $safeOperationFactory }).Count -eq 0) 'A forgeable public image operation allocation seam is present.'
      Assert-Condition (@($storageInterface | Where-Object { $_ -cmatch '^pub fn OwnedImage::new_operation.*ResourceCharge' }).Count -eq 0) 'A public image allocation seam accepts ResourceCharge.'
    }

    $modulePath = Join-Path $repoRoot ([string]$module.path)
    $manifest = Read-QualityJson -Path (Join-Path $modulePath 'moon.mod.json')
    Assert-Condition ($manifest.name -ceq $module.name) "Manifest name drift in $($module.path)."
    Assert-Condition ($manifest.version -ceq $module.version) "Manifest version drift in $($module.path)."
    Assert-Condition ($manifest.description -ceq $module.description) "Manifest description drift in $($module.path)."
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

    foreach ($package in $packages) {
      $packagePath = [string]$package.path
      Assert-Condition ($packagePath -ceq '.' -or $packagePath -cmatch '^[a-z][a-z0-9-]*(?:/[a-z][a-z0-9-]*)*$') "Public package path '$packagePath' in $($module.name) is not canonical."
      $expectedName = if ($packagePath -ceq '.') { [string]$module.name } else { "$($module.name)/$packagePath" }
      Assert-Condition ($package.name -ceq $expectedName) "Public package identity drift for '$packagePath' in $($module.name): expected '$expectedName', got '$($package.name)'."
      Assert-Condition ($package.stability -ceq $module.stability) "Public package stability drift for $($package.name)."
      Assert-ExactSet "Public package targets for $($package.name)" @($package.supported_targets) @($policy.required_targets)
      Assert-Condition ($null -ne $package.PSObject.Properties['allowed_imports']) "Public package $($package.name) lacks allowed_imports."
      Assert-Condition ($null -ne $package.PSObject.Properties['semantic_interface'] -and @($package.semantic_interface).Count -gt 0) "Public package $($package.name) lacks a semantic_interface allowlist."
      Assert-Condition (@($package.semantic_interface)[0] -ceq "package `"$expectedName`"") "Public package $($package.name) semantic interface must begin with its exact package declaration."

      $packageDirectory = if ($packagePath -ceq '.') { $modulePath } else { Join-Path $modulePath $packagePath }
      $packageFile = Join-Path $packageDirectory 'moon.pkg'
      Assert-Condition (Test-Path -LiteralPath $packageFile -PathType Leaf) "Public package $($package.name) lacks moon.pkg at '$packageFile'."
      $packageText = Get-Content -LiteralPath $packageFile -Raw
      $packageMatch = [regex]::Match($packageText, '(?m)^supported_targets\s*=\s*"([^"]+)"\s*$')
      Assert-Condition $packageMatch.Success "moon.pkg for $($package.name) lacks supported_targets."
      Assert-ExactSet "moon.pkg targets for $($package.name)" (Get-CompactTargetSet $packageMatch.Groups[1].Value "package targets for $($package.name)") @($policy.required_targets)
      $actualImports = @(Get-PackageImportSet -Text $packageText -Label "moon.pkg for $($package.name)")
      Assert-ExactSet "moon.pkg imports for $($package.name)" $actualImports @($package.allowed_imports)
    }

    Assert-Condition ($null -ne $module.PSObject.Properties['publication_files'] -and @($module.publication_files).Count -gt 0) "$($module.name) lacks an exact publication_files allowlist."
    foreach ($file in @($module.publication_files)) {
      Assert-Condition ([string]$file -cmatch '^[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*$') "Publication file '$file' in $($module.name) is not canonical."
    }

    $readmeText = Get-Content -LiteralPath (Join-Path $modulePath 'README.mbt.md') -Raw
    Assert-Condition ($readmeText -cmatch '\bcandidate\b') "README for $($module.name) does not expose candidate stability."
    foreach ($target in @($policy.required_targets)) {
      Assert-Condition ($readmeText -cmatch [regex]::Escape($target)) "README for $($module.name) does not expose target '$target'."
    }
  }

  Assert-Condition ($policy.publication.blocked -eq $true) 'Public publication must remain blocked.'
  Assert-Condition ($policy.publication.owner_verified -eq $false) 'Owner namespace must remain unverified.'
  Assert-Condition ($policy.publication.intended_owner_namespace -ceq 'tchivs') 'Intended owner namespace drifted.'
  Assert-Condition ($policy.publication.umbrella_module_allowed -eq $false) 'Umbrella modules must remain forbidden.'
  Assert-Condition ($policy.publication.lockstep_versions_required -eq $false -and $policy.publication.independent_versions -eq $true) 'Independent versioning policy drifted.'
  Assert-Condition (-not [string]::IsNullOrWhiteSpace($policy.publication.block_reason)) 'Publication block requires a reason.'

  if ([string]::IsNullOrWhiteSpace($MaintainersPath)) { $MaintainersPath = Join-Path $repoRoot ([string]$policy.rfc.maintainer_roster_path) }
  Assert-RfcAcceptanceState -Policy $policy -RosterPath $MaintainersPath -RepositoryRoot $repoRoot

  $rfcProcessText = Get-Content -LiteralPath (Join-Path $repoRoot 'docs/governance/rfc-process.md') -Raw
  Assert-Condition ($rfcProcessText -cmatch 'RFC 0001 completed and dispositioned both checks' -and $rfcProcessText -cmatch 'decisions/0001-sole-owner-bootstrap[.]md#edge-review-results') 'RFC process must record RFC 0001 edge-review completion and link its canonical evidence.'
  Assert-Condition ($rfcProcessText -cnotmatch 'still-unclassified checks' -and $rfcProcessText -cnotmatch 'These checks are open review obligations') 'RFC process incorrectly describes completed RFC 0001 checks as open.'
  Assert-Condition ($rfcProcessText -cmatch 'public review location and evidenced interval for the `project-lead-public-review` route' -and $rfcProcessText -cnotmatch 'public review location and evidenced interval for the bootstrap route') 'RFC process must bind public-review evidence to the project-lead route without ambiguous bootstrap wording.'

  Assert-FixtureManifest -ManifestPath (Join-Path $repoRoot 'fixtures/manifest.json') -RepositoryRoot $repoRoot
  Assert-QoiFoundationPolicy -PolicyPath $PolicyPath
  Assert-FontFoundationPolicy -PolicyPath $PolicyPath

  Write-Host 'Foundation policy, RFC, workspace inventory, target metadata, fixtures, publication block, and dependency DAG verified.'
}

function Assert-QoiGeneratedInterface {
  param(
    [Parameter(Mandatory)][object]$QoiPolicy,
    [Parameter(Mandatory)][string]$RepositoryRoot
  )

  $interfacePath = Join-Path $RepositoryRoot 'modules/mb-image/qoi/pkg.generated.mbti'
  Assert-Condition (Test-Path -LiteralPath $interfacePath -PathType Leaf) "QOI interface classifier cannot find '$interfacePath'."
  $semanticLines = @(Get-Content -LiteralPath $interfacePath | ForEach-Object { $_.TrimEnd() } | Where-Object { $_ -ne '' -and -not $_.TrimStart().StartsWith('//') })
  Assert-ExactSequence 'QOI generated semantic interface' $semanticLines @($QoiPolicy.semantic_interface | ForEach-Object { [string]$_ })
}

function Assert-QoiFoundationPolicy {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$PolicyPath)

  $policy = Read-QualityJson -Path $PolicyPath
  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  $imagePolicy = @($policy.modules | Where-Object { $_.name -ceq 'tchivs/mb-image' })
  Assert-ExactSet 'QOI module selection' @($imagePolicy.name) @('tchivs/mb-image')
  $qoiPolicy = @($imagePolicy[0].public_packages | Where-Object { $_.path -ceq 'qoi' })
  Assert-ExactSet 'QOI public package selection' @($qoiPolicy.name) @('tchivs/mb-image/qoi')
  $qoi = $qoiPolicy[0]

  Assert-Condition ($qoi.stability -ceq 'candidate') 'QOI package stability must remain candidate.'
  Assert-ExactSet 'QOI policy imports' @($qoi.allowed_imports) @('tchivs/mb-core/budget', 'tchivs/mb-core/bytes', 'tchivs/mb-core/checked', 'tchivs/mb-core/error', 'tchivs/mb-core/io', 'tchivs/mb-color/model', 'tchivs/mb-color/profile', 'tchivs/mb-image/codec', 'tchivs/mb-image/metadata', 'tchivs/mb-image/model', 'tchivs/mb-image/storage')
  Assert-ExactSet 'QOI policy targets' @($qoi.supported_targets) @('js', 'wasm', 'wasm-gc', 'native')
  Assert-ExactSequence 'QOI policy production source order' @($qoi.production_sources) @('moon.pkg', 'qoi.mbt', 'decode.mbt', 'encode.mbt', 'generated_vectors.mbt', 'stream_decode.mbt', 'stream_encode.mbt')

  $workText = Get-Content -LiteralPath (Join-Path $repoRoot 'moon.work') -Raw
  $workMembers = @([regex]::Matches($workText, '"\./([^"\r\n]+)"') | ForEach-Object { $_.Groups[1].Value })
  Assert-ExactSet 'QOI workspace example selection' @($workMembers | Where-Object { $_ -ceq 'examples/qoi-portable' }) @('examples/qoi-portable')
  Assert-Condition (Test-Path -LiteralPath (Join-Path $repoRoot 'examples/qoi-portable/main/main.mbt') -PathType Leaf) 'QOI public example source is missing.'

  $packageText = Get-Content -LiteralPath (Join-Path $repoRoot 'modules/mb-image/qoi/moon.pkg') -Raw
  $packageMatch = [regex]::Match($packageText, '(?m)^supported_targets\s*=\s*"([^"]+)"\s*$')
  Assert-Condition $packageMatch.Success 'QOI moon.pkg lacks supported_targets.'
  Assert-ExactSet 'QOI moon.pkg targets' (Get-CompactTargetSet $packageMatch.Groups[1].Value 'QOI package targets') @('js', 'wasm', 'wasm-gc', 'native')
  Assert-ExactSet 'QOI moon.pkg imports' @(Get-PackageImportSet -Text $packageText -Label 'QOI moon.pkg') @($qoi.allowed_imports)

  $qoiFiles = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'modules/mb-image/qoi') -File | Where-Object { $_.Name -cne 'pkg.generated.mbti' } | ForEach-Object { $_.Name })
  Assert-ExactSet 'QOI directory contents' $qoiFiles @('moon.pkg', 'qoi.mbt', 'decode.mbt', 'decode_test.mbt', 'decode_wbtest.mbt', 'encode.mbt', 'encode_test.mbt', 'encode_wbtest.mbt', 'generated_vectors.mbt', 'stream_decode.mbt', 'stream_decode_test.mbt', 'stream_decode_wbtest.mbt', 'stream_encode.mbt', 'stream_encode_test.mbt', 'stream_encode_wbtest.mbt')

  $imageModulePath = Join-Path $repoRoot 'modules/mb-image'
  & moon -C $imageModulePath info --target all --frozen
  if ($LASTEXITCODE -ne 0) { throw "QOI interface generation failed (exit $LASTEXITCODE)." }
  if (Get-Command Assert-GeneratedInterface -ErrorAction SilentlyContinue) {
    $scopedModule = [pscustomobject]@{ name = 'tchivs/mb-image'; path = 'modules/mb-image'; public_packages = @($qoi) }
    Assert-GeneratedInterface -ModulePolicy $scopedModule -RepositoryRoot $repoRoot
  } else {
    Assert-QoiGeneratedInterface -QoiPolicy $qoi -RepositoryRoot $repoRoot
  }
  Write-Host 'QOI policy, interface, target, source-order, package, and public-example selection verified.'
}

function Assert-QoiQualificationNegativeFixtures {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$PolicyPath)

  $policy = Read-QualityJson -Path $PolicyPath
  $qoi = @(@($policy.modules | Where-Object { $_.name -ceq 'tchivs/mb-image' })[0].public_packages | Where-Object { $_.path -ceq 'qoi' })[0]
  function Confirm-QoiRejected([string]$Name, [scriptblock]$Action, [string]$ExpectedPattern) {
    $failure = $null
    try { & $Action } catch { $failure = $_.Exception.Message }
    if ($null -eq $failure -or $failure -cnotmatch $ExpectedPattern) {
      throw "QOI quality accepted negative fixture '$Name' or failed for the wrong reason: '$failure'."
    }
    Write-Host "QOI negative fixture rejected: $Name"
  }

  $imports = @($qoi.allowed_imports | ForEach-Object { [string]$_ })
  $sources = @($qoi.production_sources | ForEach-Object { [string]$_ })
  $temporaryPolicyPath = Join-Path ([System.IO.Path]::GetTempPath()) ("mnf-qoi-policy-" + [Guid]::NewGuid().ToString() + '.json')
  try {
    $temporaryPolicy = Read-QualityJson -Path $PolicyPath
    $temporaryImage = @($temporaryPolicy.modules | Where-Object { $_.name -ceq 'tchivs/mb-image' })[0]
    $temporaryOps = @($temporaryImage.public_packages | Where-Object { $_.path -ceq 'ops' })[0]
    $temporaryOps.allowed_imports = @('tchivs/mb-core/error', 'tchivs/mb-core/checked', 'tchivs/mb-core/budget', 'tchivs/mb-core/bytes', 'tchivs/mb-color/alpha', 'tchivs/mb-color/model', 'tchivs/mb-color/profile', 'tchivs/mb-color/transfer', 'tchivs/mb-color/quantize', 'tchivs/mb-image/metadata', 'tchivs/mb-image/model', 'tchivs/mb-image/storage')
    $temporaryPolicy | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $temporaryPolicyPath -Encoding utf8
    Assert-FoundationPolicy -PolicyPath $temporaryPolicyPath
    $reorderedPolicy = Read-QualityJson -Path $temporaryPolicyPath
    $reorderedQoi = @(@($reorderedPolicy.modules | Where-Object { $_.name -ceq 'tchivs/mb-image' })[0].public_packages | Where-Object { $_.path -ceq 'qoi' })[0]
    $reorderedQoi.production_sources = @('moon.pkg', 'qoi.mbt', 'decode.mbt', 'encode.mbt', 'generated_vectors.mbt', 'stream_encode.mbt', 'stream_decode.mbt')
    $reorderedPolicy | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $temporaryPolicyPath -Encoding utf8
    Confirm-QoiRejected 'broad reordered stream production order' { Assert-FoundationPolicy -PolicyPath $temporaryPolicyPath } 'mb-image qoi production source order order mismatch at index'
  } finally {
    if (Test-Path -LiteralPath $temporaryPolicyPath) { Remove-Item -LiteralPath $temporaryPolicyPath -Force }
  }
  Confirm-QoiRejected 'package presence' { Assert-ExactSet 'negative QOI package selection' @() @('tchivs/mb-image/qoi') } 'count mismatch'
  Confirm-QoiRejected 'missing import' { Assert-ExactSet 'negative QOI imports' @($imports | Select-Object -Skip 1) $imports } 'count mismatch'
  Confirm-QoiRejected 'extra import' { Assert-ExactSet 'negative QOI imports' @($imports + 'tchivs/mb-image/ops') $imports } 'count mismatch'
  Confirm-QoiRejected 'missing portable target' { Assert-ExactSet 'negative QOI targets' @('js', 'wasm', 'native') @('js', 'wasm', 'wasm-gc', 'native') } 'count mismatch'
  $publicTypes = @('QoiDecoder', 'QoiEncoder', 'QoiStreamDecoder', 'QoiStreamEncoder', 'QoiStreamPullResult', 'QoiStreamPullOutcome', 'QoiStreamPushResult', 'QoiStreamPushOutcome')
  Confirm-QoiRejected 'missing stream interface entry' { Assert-ExactSequence 'negative QOI interface' @('QoiDecoder', 'QoiEncoder', 'QoiStreamDecoder', 'QoiStreamEncoder', 'QoiStreamPullResult', 'QoiStreamPushResult', 'QoiStreamPushOutcome') $publicTypes } 'count mismatch'
  Confirm-QoiRejected 'extra stream interface entry' { Assert-ExactSequence 'negative QOI interface' @($publicTypes + 'QoiRegistry') $publicTypes } 'count mismatch'
  Confirm-QoiRejected 'wrong production order' { Assert-ExactSequence 'negative QOI source order' @('moon.pkg', 'qoi.mbt', 'decode.mbt', 'encode.mbt', 'generated_vectors.mbt', 'stream_encode.mbt', 'stream_decode.mbt') $sources } 'mismatch at index'
  Confirm-QoiRejected 'missing production content' { Assert-ExactSet 'negative QOI contents' @($sources | Select-Object -Skip 1) $sources } 'count mismatch'
  Confirm-QoiRejected 'extra production content' { Assert-ExactSet 'negative QOI contents' @($sources + 'registry.mbt') $sources } 'count mismatch'
  Confirm-QoiRejected 'missing stream production content' { Assert-ExactSet 'negative QOI contents' @($sources | Where-Object { $_ -cne 'stream_encode.mbt' }) $sources } 'count mismatch'
  $qoiFiles = @('moon.pkg', 'qoi.mbt', 'decode.mbt', 'decode_test.mbt', 'decode_wbtest.mbt', 'encode.mbt', 'encode_test.mbt', 'encode_wbtest.mbt', 'generated_vectors.mbt', 'stream_decode.mbt', 'stream_decode_test.mbt', 'stream_decode_wbtest.mbt', 'stream_encode.mbt', 'stream_encode_test.mbt', 'stream_encode_wbtest.mbt')
  Confirm-QoiRejected 'extra stream file' { Assert-ExactSet 'negative QOI files' @($qoiFiles + 'stream_registry.mbt') $qoiFiles } 'count mismatch'
  Write-Host 'QOI package, import, target, interface, source-order, and content negatives fail closed.'
}

function Assert-FontPhase102Surface {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string[]]$InterfaceLines)

  # Keep this classification independent from policy/foundation.json so a
  # coordinated policy and implementation edit cannot silently admit a private
  # parser fact or a deferred Phase 103+ capability. Every public line is
  # reviewed here independently.
  $approvedPhase102Lines = @(
    'package "tchivs/mb-font/font"',
    'import {',
    '  "tchivs/mb-core/budget",',
    '  "tchivs/mb-core/bytes",',
    '  "tchivs/mb-core/error",',
    '  "tchivs/mb-core/math",',
    '}',
    'pub struct Font {',
    '}',
    'pub fn Font::global_bounds(Self) -> Result[FontBounds, @error.CoreError]',
    'pub fn Font::glyph_for_scalar(Self, Int) -> Result[GlyphId, @error.CoreError]',
    'pub fn Font::glyph_id(Self, UInt64) -> Result[GlyphId, @error.CoreError]',
    'pub fn Font::hhea_line_metrics(Self) -> Result[FontLineMetrics, @error.CoreError]',
    'pub fn Font::horizontal_metrics(Self, GlyphId) -> Result[GlyphHorizontalMetrics, @error.CoreError]',
    'pub fn Font::kerning(Self, GlyphId, GlyphId) -> Result[Int, @error.CoreError]',
    'pub fn Font::open(@bytes.ByteView, FontLimits, @budget.Budget) -> Result[Self, @error.CoreError]',
    'pub fn Font::outline(Self, GlyphId, @budget.Budget) -> Result[@math.Path2, @error.CoreError]',
    'pub fn Font::typographic_line_metrics(Self) -> Result[FontLineMetrics, @error.CoreError]',
    'pub fn Font::units_per_em(Self) -> Result[UInt64, @error.CoreError]',
    'pub struct FontBounds {',
    '}',
    'pub fn FontBounds::x_max(Self) -> Int',
    'pub fn FontBounds::x_min(Self) -> Int',
    'pub fn FontBounds::y_max(Self) -> Int',
    'pub fn FontBounds::y_min(Self) -> Int',
    'pub struct FontCollection {',
    '}',
    'pub fn FontCollection::dsig_status(Self) -> Result[FontCollectionDsigStatus, @error.CoreError]',
    'pub fn FontCollection::face_count(Self) -> Result[UInt64, @error.CoreError]',
    'pub fn FontCollection::face_profile(Self, UInt64) -> Result[FontFaceProfile, @error.CoreError]',
    'pub fn FontCollection::open(@bytes.ByteView, FontCollectionLimits, @budget.Budget) -> Result[Self, @error.CoreError]',
    'pub fn FontCollection::open_face(Self, UInt64, FontLimits, @budget.Budget) -> Result[Font, @error.CoreError]',
    'pub(all) enum FontCollectionDsigStatus {',
    '  Absent',
    '  PresentUnverified',
    '} derive(Eq)',
    'pub struct FontCollectionLimits {',
    '}',
    'pub fn FontCollectionLimits::max_dsig_bytes(Self) -> UInt64',
    'pub fn FontCollectionLimits::max_dsig_records(Self) -> UInt64',
    'pub fn FontCollectionLimits::max_faces(Self) -> UInt64',
    'pub fn FontCollectionLimits::max_retained_bookkeeping_bytes(Self) -> UInt64',
    'pub fn FontCollectionLimits::max_source_bytes(Self) -> UInt64',
    'pub fn FontCollectionLimits::max_table_records(Self) -> UInt64',
    'pub fn FontCollectionLimits::max_tables_per_face(Self) -> UInt64',
    'pub fn FontCollectionLimits::max_work(Self) -> UInt64',
    'pub fn FontCollectionLimits::new(max_source_bytes~ : UInt64, max_faces~ : UInt64, max_tables_per_face~ : UInt64, max_table_records~ : UInt64, max_dsig_records~ : UInt64, max_dsig_bytes~ : UInt64, max_retained_bookkeeping_bytes~ : UInt64, max_work~ : UInt64) -> Result[Self, @error.CoreError]',
    'pub(all) enum FontFaceProfile {',
    '  StaticGlyf',
    '  Cff',
    '  Cff2',
    '  Variable',
    '  OtherUnsupported',
    '} derive(Eq)',
    'pub struct FontLimits {',
    '}',
    'pub fn FontLimits::max_cmap_records(Self) -> UInt64',
    'pub fn FontLimits::max_glyphs(Self) -> UInt64',
    'pub fn FontLimits::max_kern_pairs(Self) -> UInt64',
    'pub fn FontLimits::max_kern_subtables(Self) -> UInt64',
    'pub fn FontLimits::max_name_records(Self) -> UInt64',
    'pub fn FontLimits::max_outline_components(Self) -> UInt64',
    'pub fn FontLimits::max_outline_contours(Self) -> UInt64',
    'pub fn FontLimits::max_outline_instruction_bytes(Self) -> UInt64',
    'pub fn FontLimits::max_outline_points(Self) -> UInt64',
    'pub fn FontLimits::max_post_name_bytes(Self) -> UInt64',
    'pub fn FontLimits::max_source_bytes(Self) -> UInt64',
    'pub fn FontLimits::max_table_bytes(Self) -> UInt64',
    'pub fn FontLimits::max_tables(Self) -> UInt64',
    'pub fn FontLimits::max_work(Self) -> UInt64',
    'pub fn FontLimits::new(max_source_bytes~ : UInt64, max_tables~ : UInt64, max_table_bytes~ : UInt64, max_glyphs~ : UInt64, max_name_records~ : UInt64, max_cmap_records~ : UInt64, max_kern_subtables~ : UInt64, max_kern_pairs~ : UInt64, max_outline_points~ : UInt64, max_outline_contours~ : UInt64, max_outline_components~ : UInt64, max_outline_instruction_bytes~ : UInt64, max_post_name_bytes~ : UInt64, max_work~ : UInt64) -> Result[Self, @error.CoreError]',
    'pub struct FontLineMetrics {',
    '}',
    'pub fn FontLineMetrics::ascent(Self) -> Int',
    'pub fn FontLineMetrics::descent(Self) -> Int',
    'pub fn FontLineMetrics::line_gap(Self) -> Int',
    'pub struct GlyphHorizontalMetrics {',
    '}',
    'pub fn GlyphHorizontalMetrics::advance_width(Self) -> UInt64',
    'pub fn GlyphHorizontalMetrics::bounds(Self) -> FontBounds?',
    'pub fn GlyphHorizontalMetrics::left_side_bearing(Self) -> Int',
    'pub fn GlyphHorizontalMetrics::right_side_bearing(Self) -> Int',
    'pub struct GlyphId {',
    '}',
    'pub fn GlyphId::value(Self) -> UInt64'
  )
  Assert-ExactSequence `
    'Font semantic interface exposes a private or deferred Phase 103+ capability; Phase 102 exact interface' `
    $InterfaceLines `
    $approvedPhase102Lines

  $deferredLines = @(
    $InterfaceLines |
      ForEach-Object {
        $line = ([string]$_) -creplace '\bmax_cmap_records\b', ''
        $line = [regex]::Replace($line, '(?i)cmap', 'cmap')
        $line = [regex]::Replace($line, '(?<=[A-Z])(?=[A-Z][a-z])', ' ')
        $line = [regex]::Replace($line, '(?<=[a-z0-9])(?=[A-Z])', ' ')
        $line -creplace '_', ' '
      }
  )
  $deferredLeakPattern = '(?i)(\bfile\s*system\b|\bsystem\s+font\b|\bfont\s+(?:file|source)\b|\b(?:load|read|open|from)\b[^\r\n]*\b(?:file|path|disk|uri)\b|\bffi\b|\bforeign\s+function\s+interface\b|\bforeign(?:\s+call)?\b|\bnative\b|\bextern\b|\bbindings?\b|\bc\s+abi\b|\b(?:adapter|bridge)\b|\bhost(?:\s+discovery)?\b|\bshap(?:e|er|ing)\b|\bhint(?:er|ing)?\b|\bgrid\s*(?:fit|round)\w*\b|\braster(?:ize|izer|ization)?\b|\bnested\s+composite\b|\bphantom\s+point\b)'
  Assert-Condition (@($deferredLines | Where-Object { $_ -cmatch $deferredLeakPattern }).Count -eq 0) 'Font semantic interface exposes a private or deferred Phase 103+ capability.'
}

function Assert-FontQualificationFixtureManifest {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$ManifestPath,
    [Parameter(Mandatory)][string]$RepositoryRoot
  )

  Assert-FixtureManifest -ManifestPath $ManifestPath -RepositoryRoot $RepositoryRoot
  $manifest = Read-QualityJson -Path $ManifestPath
  $expectedIds = @(
    'image-operation-vectors',
    'ppm-p6-conformance-vectors',
    'qoi-1.0-conformance-vectors',
    'png-decode-vectors',
    'png-structural-safety-vectors',
    'color-srgb-reference-vectors',
    'color-derived-edge-vectors',
    'svg-subset-conformance-vectors',
    'font-dejavu-sans-2.37',
    'font-dejavu-sans-2.37-license',
    'font-qualification-cases',
    'font-collection-qualification-cases',
    'font-dejavu-sans-2.37-two-face-v1',
    'font-dejavu-sans-2.37-collection-oracle'
  )
  Assert-ExactSequence 'Fixture manifest record order' @($manifest.records.id) $expectedIds

  $expectedFontRecords = @(
    [pscustomobject][ordered]@{
      id = 'font-dejavu-sans-2.37'
      path = 'fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf'
      origin = 'external'
      source = 'https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-sans-ttf-2.37.zip'
      author = 'DejaVu Fonts project; derived from Bitstream Vera and Arev'
      retrieval_date = '2026-07-27'
      sha256 = '7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954'
      license = 'Bitstream-Vera AND LicenseRef-DejaVu-Arev'
      redistribution_status = 'confirmed'
      expected_use = 'Phase 100 licensed real-font public workflow and interoperability qualification'
    },
    [pscustomobject][ordered]@{
      id = 'font-dejavu-sans-2.37-license'
      path = 'fixtures/font/dejavu-sans-2.37/LICENSE'
      origin = 'external'
      source = 'https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-sans-ttf-2.37.zip'
      author = 'DejaVu Fonts project; Bitstream, Inc.; Tavmjong Bah'
      retrieval_date = '2026-07-27'
      sha256 = '7a083b136e64d064794c3419751e5c7dd10d2f64c108fe5ba161eae5e5958a93'
      license = 'Bitstream-Vera AND LicenseRef-DejaVu-Arev'
      redistribution_status = 'confirmed'
      expected_use = 'Phase 100 notice accompanying redistribution of DejaVu Sans 2.37'
    },
    [pscustomobject][ordered]@{
      id = 'font-qualification-cases'
      path = 'fixtures/font/qualification-cases.json'
      origin = 'generated'
      source = 'repository-derived:scripts/fixtures/Generate-FontQualification.ps1'
      author = 'MoonBit Native Foundation project generator'
      retrieval_date = '2026-07-27'
      sha256 = 'a9a86ed5c080571fffe3317eead29865c5fdad222475251423621fddb09c1d18'
      license = 'Apache-2.0'
      redistribution_status = 'not-applicable'
      expected_use = 'Phase 100 closed hostile-input and transactional font qualification matrix'
    },
    [pscustomobject][ordered]@{
      id = 'font-collection-qualification-cases'
      path = 'fixtures/font/collection-qualification-cases.json'
      origin = 'generated'
      source = 'repository-derived:scripts/fixtures/Generate-FontQualification.ps1'
      author = 'MoonBit Native Foundation project generator'
      retrieval_date = '2026-07-28'
      sha256 = '699be85f05e8e73b53b066eafe1e89fae5cc56a9dec513c62a48c8089cfc5070'
      license = 'Apache-2.0'
      redistribution_status = 'not-applicable'
      expected_use = 'Phase 103 closed public, hostile, mutation, limit, caller-budget, and ancestor-budget collection qualification matrix'
    },
    [pscustomobject][ordered]@{
      id = 'font-dejavu-sans-2.37-two-face-v1'
      path = 'fixtures/font/dejavu-sans-2.37/DejaVuSans-two-face-v1.ttc'
      origin = 'external'
      source = 'https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-sans-ttf-2.37.zip; parent=fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf@7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954; generator=scripts/fixtures/Generate-FontQualification.ps1#dejavu-two-face-exact-sharing-v1; notice=fixtures/font/dejavu-sans-2.37/LICENSE@7a083b136e64d064794c3419751e5c7dd10d2f64c108fe5ba161eae5e5958a93'
      author = 'DejaVu Fonts project; derived from Bitstream Vera and Arev'
      retrieval_date = '2026-07-28'
      sha256 = '833d406d389d4ef3b0a38f168af7d51ca16c88605e1727f6d631871a4e05f80b'
      license = 'Bitstream-Vera AND LicenseRef-DejaVu-Arev'
      redistribution_status = 'confirmed'
      expected_use = 'Phase 103 qualification-only licensed two-face exact-sharing TTC v1 derivative'
    },
    [pscustomobject][ordered]@{
      id = 'font-dejavu-sans-2.37-collection-oracle'
      path = 'fixtures/font/dejavu-sans-2.37/collection-oracle.json'
      origin = 'generated'
      source = 'repository-derived:scripts/fixtures/Generate-FontQualification.ps1; derivative=833d406d389d4ef3b0a38f168af7d51ca16c88605e1727f6d631871a4e05f80b; standalone-oracle=4247394c3795a56aaf28c1885403201cfc277b06125f5887e14a40f3b4c6229a; metadata-only-no-payload-bytes'
      author = 'MoonBit Native Foundation project generator'
      retrieval_date = '2026-07-28'
      sha256 = '87b1e980714850cbdabdf293011aa34acfa19039ba6846ccbdcdcfcbf273c435'
      license = 'Apache-2.0'
      redistribution_status = 'not-applicable'
      expected_use = 'Phase 103 independent metadata-only TTC structure, checksum, sharing, lineage, and standalone-oracle binding'
    }
  )
  foreach ($expected in $expectedFontRecords) {
    $actual = @($manifest.records | Where-Object { $_.id -ceq $expected.id })
    Assert-Condition ($actual.Count -eq 1) "Font fixture manifest record '$($expected.id)' must occur exactly once."
    Assert-ExactSequence "Font fixture '$($expected.id)' fields" @($actual[0].PSObject.Properties.Name) @($expected.PSObject.Properties.Name)
    foreach ($property in $expected.PSObject.Properties) {
      Assert-Condition ([string]$actual[0].($property.Name) -ceq [string]$property.Value) "Font fixture '$($expected.id)' field '$($property.Name)' drifted."
    }
  }
}

function Get-FontExecutableSourceText {
  param([Parameter(Mandatory)][string]$Path)

  $text = Get-Content -Raw -LiteralPath $Path
  $output = [Text.StringBuilder]::new($text.Length)
  $interpolations = [System.Collections.Generic.Stack[object]]::new()
  $state = 'code'
  $blockDepth = 0
  $lineStart = 0
  $index = 0
  $slash = [char]47
  $asterisk = [char]42
  $backslash = [char]92
  $doubleQuote = [char]34
  $singleQuote = [char]39
  $leftBrace = [char]123
  $rightBrace = [char]125
  $dollar = [char]36
  $hash = [char]35
  $verticalBar = [char]124
  $horizontalTab = [char]9
  $space = [char]32
  $lineFeed = [char]10
  $carriageReturn = [char]13

  while ($index -lt $text.Length) {
    $current = $text[$index]
    $next = if ($index + 1 -lt $text.Length) { $text[$index + 1] } else { [char]0 }

    switch ($state) {
      'code' {
        $isMultilinePrefix = (
          ($current -eq $dollar -or $current -eq $hash) -and
          $next -eq $verticalBar
        )
        if ($isMultilinePrefix) {
          for ($prefixIndex = $lineStart; $prefixIndex -lt $index; $prefixIndex += 1) {
            $prefixCharacter = $text[$prefixIndex]
            if ($prefixCharacter -ne $space -and $prefixCharacter -ne $horizontalTab) {
              $isMultilinePrefix = $false
              break
            }
          }
        }
        if ($isMultilinePrefix) {
          [void]$output.Append('  ')
          $state = if ($current -eq $dollar) { 'multiline-interpolated' } else { 'multiline-raw' }
          $index += 2
          continue
        }
        if ($current -eq $slash -and $next -eq $slash) {
          [void]$output.Append('  ')
          $state = 'line-comment'
          $index += 2
          continue
        }
        if ($current -eq $slash -and $next -eq $asterisk) {
          [void]$output.Append('  ')
          $state = 'block-comment'
          $blockDepth = 1
          $index += 2
          continue
        }
        if (
          $current -eq [char]98 -and
          ($next -eq $doubleQuote -or $next -eq $singleQuote)
        ) {
          [void]$output.Append('  ')
          $state = if ($next -eq $doubleQuote) { 'string' } else { 'character' }
          $index += 2
          continue
        }
        if ($current -eq $doubleQuote -or $current -eq $singleQuote) {
          [void]$output.Append(' ')
          $state = if ($current -eq $doubleQuote) { 'string' } else { 'character' }
          $index += 1
          continue
        }
        if ($interpolations.Count -gt 0 -and $current -eq $leftBrace) {
          $frame = $interpolations.Peek()
          $frame.BraceDepth += 1
          [void]$output.Append($current)
          $index += 1
          continue
        }
        if ($interpolations.Count -gt 0 -and $current -eq $rightBrace) {
          $frame = $interpolations.Peek()
          $frame.BraceDepth -= 1
          if ($frame.BraceDepth -eq 0) {
            [void]$output.Append(' ')
            [void]$interpolations.Pop()
            $state = $frame.ResumeState
          } else {
            [void]$output.Append($current)
          }
          $index += 1
          continue
        }
        if (
          $interpolations.Count -gt 0 -and
          ($current -eq $lineFeed -or $current -eq $carriageReturn)
        ) {
          throw "Font source '$Path' contains a newline inside string interpolation."
        }
        [void]$output.Append($current)
        if ($current -eq $lineFeed -or $current -eq $carriageReturn) {
          $lineStart = $index + 1
        }
        $index += 1
      }
      'line-comment' {
        if ($current -eq $lineFeed -or $current -eq $carriageReturn) {
          if ($interpolations.Count -gt 0) {
            throw "Font source '$Path' contains a line comment or newline inside string interpolation."
          }
          [void]$output.Append($current)
          $state = 'code'
          $lineStart = $index + 1
        } else {
          [void]$output.Append(' ')
        }
        $index += 1
      }
      'block-comment' {
        if ($current -eq $slash -and $next -eq $asterisk) {
          [void]$output.Append('  ')
          $blockDepth += 1
          $index += 2
          continue
        }
        if ($current -eq $asterisk -and $next -eq $slash) {
          [void]$output.Append('  ')
          $blockDepth -= 1
          $index += 2
          if ($blockDepth -eq 0) { $state = 'code' }
          continue
        }
        if ($current -eq $lineFeed -or $current -eq $carriageReturn) {
          if ($interpolations.Count -gt 0) {
            throw "Font source '$Path' contains a newline inside string interpolation."
          }
          [void]$output.Append($current)
          $lineStart = $index + 1
        } else {
          [void]$output.Append(' ')
        }
        $index += 1
      }
      'string' {
        if ($current -eq $backslash) {
          if ($next -eq $leftBrace) {
            [void]$output.Append('  ')
            $interpolations.Push([pscustomobject]@{
              ResumeState = $state
              BraceDepth = 1
            })
            $state = 'code'
            $index += 2
            continue
          }
          [void]$output.Append(' ')
          $index += 1
          if ($index -ge $text.Length) {
            throw "Font source '$Path' ends inside an escaped $state literal."
          }
          $escaped = $text[$index]
          if ($escaped -eq $lineFeed -or $escaped -eq $carriageReturn) {
            [void]$output.Append($escaped)
          } else {
            [void]$output.Append(' ')
          }
          $index += 1
          continue
        }
        if ($current -eq $doubleQuote) {
          [void]$output.Append(' ')
          $state = 'code'
          $index += 1
          continue
        }
        if ($current -eq $lineFeed -or $current -eq $carriageReturn) {
          throw "Font source '$Path' contains a newline inside a string literal."
        } else {
          [void]$output.Append(' ')
        }
        $index += 1
      }
      'character' {
        if ($current -eq $backslash) {
          [void]$output.Append(' ')
          $index += 1
          if ($index -ge $text.Length) {
            throw "Font source '$Path' ends inside an escaped $state literal."
          }
          $escaped = $text[$index]
          if ($escaped -eq $lineFeed -or $escaped -eq $carriageReturn) {
            throw "Font source '$Path' contains a newline inside a character literal."
          }
          [void]$output.Append(' ')
          $index += 1
          continue
        }
        if ($current -eq $singleQuote) {
          [void]$output.Append(' ')
          $state = 'code'
          $index += 1
          continue
        }
        if ($current -eq $lineFeed -or $current -eq $carriageReturn) {
          throw "Font source '$Path' contains a newline inside a character literal."
        }
        [void]$output.Append(' ')
        $index += 1
      }
      'multiline-interpolated' {
        if ($current -eq $backslash -and $next -eq $leftBrace) {
          [void]$output.Append('  ')
          $interpolations.Push([pscustomobject]@{
            ResumeState = $state
            BraceDepth = 1
          })
          $state = 'code'
          $index += 2
          continue
        }
        if ($current -eq $lineFeed -or $current -eq $carriageReturn) {
          [void]$output.Append($current)
          $state = 'code'
          $lineStart = $index + 1
        } else {
          [void]$output.Append(' ')
        }
        $index += 1
      }
      'multiline-raw' {
        if ($current -eq $lineFeed -or $current -eq $carriageReturn) {
          [void]$output.Append($current)
          $state = 'code'
          $lineStart = $index + 1
        } else {
          [void]$output.Append(' ')
        }
        $index += 1
      }
      default {
        throw "Font source lexer entered unknown state '$state' for '$Path'."
      }
    }
  }

  if ($interpolations.Count -gt 0) {
    throw "Font source '$Path' ends inside string interpolation."
  }
  if ($state -eq 'block-comment') {
    throw "Font source '$Path' ends inside a block comment."
  }
  if ($state -eq 'string' -or $state -eq 'character') {
    throw "Font source '$Path' ends inside a $state literal."
  }
  return $output.ToString()
}

function Assert-FontPortableSourceBoundary {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string[]]$SourcePaths,
    [string[]]$SemanticSourcePaths = @(),
    [string]$ExpectedSemanticSha256 = ''
  )

  $forbidden = [ordered]@{
    'FFI or native stub' = '(?im)(?:^\s*(?:extern\b|#(?:external|import)\b|#(?:if|elseif)\s+native\b)|\b(?:ffi|foreign_call|native_binding|c_abi)\w*\s*[(])'
    'filesystem or host-font discovery' = '(?i)(?:\b(?:file_system|filesystem|host_font|system_font|discover_font|open_file|from_path|load_file|read_file|open_path|read_uri|load_from_disk)\w*\s*[(]|@(?:fs|filesystem|path)\b)'
    'GUI canvas image or color dependency' = '(?i)(?:\b(?:gui|canvas|image|color)\w*\s*[(]|@(?:gui|canvas|image|color)\b)'
    'shaping execution' = '(?i)(?:\b(?:shape|shaper|shaping|bidi|layout)\w*\s*[(]|@(?:shape|shaping|layout)\b)'
    'hinting execution' = '(?i)(?:\b(?:hint|hinter|grid_fit|grid_round)\w*\s*[(]|@(?:hint|hinting)\b)'
    'CFF or CFF2 execution' = '(?i)(?:\b(?:cff|cff2)\w*\s*[(]|\b(?:(?:decode|execute|interpret|evaluate|run|apply|render|outline)\w*_(?:type2|charstring|cff2?)|(?:type2|charstring|cff2?)\w*_(?:decode|execute|interpret|evaluate|run|apply|render|outline))\w*\s*[(]|@(?:cff|cff2)\b)'
    'WOFF or WOFF2 admission' = '(?i)(?:\b(?:woff|woff2)\w*(?:open|admit|decode|decompress)\w*\s*[(]|\b(?:open|admit|decode|decompress)\w*(?:woff|woff2)\w*\s*[(]|\b(?:(?:inflate|decompress|decode|admit|open|reconstruct)\w*_(?:woff2?|sfnt|container)|(?:woff2?|sfnt|container)\w*_(?:inflate|decompress|decode|admit|open|reconstruct))\w*\s*[(]|@(?:woff|woff2)\b)'
    'variable-font execution' = '(?i)(?:\b(?:instantiate|apply|execute|resolve)\w*(?:variable|variation|axis)\w*\s*[(]|\b(?:variable|variation|axis)\w*(?:instantiate|apply|execute|resolve)\w*\s*[(]|\b(?:(?:apply|execute|instantiate|resolve|evaluate)\w*_(?:gvar|fvar|variation|delta)|(?:gvar|fvar|variation|delta)\w*_(?:apply|execute|instantiate|resolve|evaluate))\w*\s*[(]|@(?:variable_font|variations?)\b)'
    'rasterization execution' = '(?i)(?:\b(?:raster|rasterize|rasterizer|rasterization)\w*\s*[(]|@(?:raster|rasterizer)\b)'
  }
  foreach ($sourcePath in $SourcePaths) {
    Assert-Condition (Test-Path -LiteralPath $sourcePath -PathType Leaf) "Font source boundary cannot find '$sourcePath'."
    $rawSource = Get-Content -Raw -LiteralPath $sourcePath
    $source = Get-FontExecutableSourceText -Path $sourcePath
    foreach ($entry in $forbidden.GetEnumerator()) {
      Assert-Condition ($source -cnotmatch [string]$entry.Value) "Font source '$sourcePath' acquires forbidden $($entry.Key)."
    }
    foreach ($flow in @(
        [pscustomobject]@{
          Name = 'CFF/CFF2 tag-to-execution flow'
          Magic = '(?i)(?:0x43464620|0x43464632|["'']CFF ?2?["''])'
          Executable = '(?i)\b(?:type2|charstring|operator|cff_program)\w*\s*[(]'
        },
        [pscustomobject]@{
          Name = 'WOFF/WOFF2 magic-to-inflation flow'
          Magic = '(?i)(?:0x774F4646|0x774F4632|["'']wOF{1,2}2?["''])'
          Executable = '(?i)\b(?:inflate|decompress|reconstruct)\w*\s*[(]'
        },
        [pscustomobject]@{
          Name = 'fvar/gvar tag-to-delta flow'
          Magic = '(?i)(?:0x66766172|0x67766172|["''](?:fvar|gvar)["''])'
          Executable = '(?i)\b(?:delta|variation|axis)\w*\s*[(]'
        }
      )) {
      Assert-Condition (
        $rawSource -cnotmatch $flow.Magic -or
        $source -cnotmatch $flow.Executable
      ) "Font source '$sourcePath' acquires forbidden $($flow.Name)."
    }
  }
  if ($SemanticSourcePaths.Count -gt 0) {
    Assert-Condition (
      $ExpectedSemanticSha256 -cmatch '^[0-9a-f]{64}$'
    ) 'Font portable semantic source digest is missing or malformed.'
    $semanticText = @(
      foreach ($sourcePath in $SemanticSourcePaths) {
        Assert-Condition (
          Test-Path -LiteralPath $sourcePath -PathType Leaf
        ) "Font semantic source lock cannot find '$sourcePath'."
        $relative = [IO.Path]::GetRelativePath($RepositoryRoot, $sourcePath).
          Replace('\', '/')
        $executable = Get-FontExecutableSourceText -Path $sourcePath
        "$relative`n$executable"
      }
    ) -join "`n"
    $semanticDigest = [Convert]::ToHexString(
      [Security.Cryptography.SHA256]::HashData(
        [Text.UTF8Encoding]::new($false).GetBytes($semanticText)
      )
    ).ToLowerInvariant()
    Assert-Condition (
      $semanticDigest -ceq $ExpectedSemanticSha256
    ) 'Font portable production semantic digest drifted.'
  }
}

function Get-FontPortableCapabilityNegativeContract {
  return @(
    [pscustomobject][ordered]@{ Name = 'FFI'; Source = 'fn forbidden_probe() { foreign_call() }'; Pattern = 'forbidden FFI or native stub' },
    [pscustomobject][ordered]@{ Name = 'filesystem'; Source = 'fn forbidden_probe() { open_file() }'; Pattern = 'forbidden filesystem or host-font discovery' },
    [pscustomobject][ordered]@{ Name = 'GUI'; Source = 'fn forbidden_probe() { canvas_draw() }'; Pattern = 'forbidden GUI canvas image or color dependency' },
    [pscustomobject][ordered]@{ Name = 'shaping'; Source = 'fn forbidden_probe() { shape_text() }'; Pattern = 'forbidden shaping execution' },
    [pscustomobject][ordered]@{ Name = 'hinting'; Source = 'fn forbidden_probe() { hint_outline() }'; Pattern = 'forbidden hinting execution' },
    [pscustomobject][ordered]@{ Name = 'CFF'; Source = 'fn forbidden_probe() { cff_decode() }'; Pattern = 'forbidden CFF or CFF2 execution' },
    [pscustomobject][ordered]@{ Name = 'renamed Type2'; Source = 'fn decode_type2_charstring() { } fn forbidden_probe() { decode_type2_charstring() }'; Pattern = 'forbidden CFF or CFF2 execution' },
    [pscustomobject][ordered]@{ Name = 'WOFF'; Source = 'fn forbidden_probe() { decode_woff2() }'; Pattern = 'forbidden WOFF or WOFF2 admission' },
    [pscustomobject][ordered]@{ Name = 'renamed SFNT inflation'; Source = 'fn inflate_sfnt_container() { } fn forbidden_probe() { inflate_sfnt_container() }'; Pattern = 'forbidden WOFF or WOFF2 admission' },
    [pscustomobject][ordered]@{ Name = 'variable font'; Source = 'fn forbidden_probe() { instantiate_variable_font() }'; Pattern = 'forbidden variable-font execution' },
    [pscustomobject][ordered]@{ Name = 'renamed gvar delta'; Source = 'fn apply_gvar_deltas() { } fn forbidden_probe() { apply_gvar_deltas() }'; Pattern = 'forbidden variable-font execution' },
    [pscustomobject][ordered]@{ Name = 'WOFF magic flow'; Source = 'fn forbidden_probe() { let signature = 0x774F4646UL; inflate_payload() }'; Pattern = 'forbidden WOFF/WOFF2 magic-to-inflation flow' },
    [pscustomobject][ordered]@{ Name = 'rasterization'; Source = 'fn forbidden_probe() { rasterize_font() }'; Pattern = 'forbidden rasterization execution' }
  )
}

function Confirm-FontQualificationRejected {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][scriptblock]$Action,
    [Parameter(Mandatory)][string]$ExpectedPattern
  )

  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  Assert-Condition ($null -ne $failure -and $failure -cmatch $ExpectedPattern) "Font qualification accepted negative probe '$Name': '$failure'."
}

function Assert-FontCollectionCorpusContract {
  [CmdletBinding()]
  param([Parameter(Mandatory)][object]$Corpus)

  Assert-ExactSequence 'Font collection corpus schema' `
    @($Corpus.PSObject.Properties.Name) `
    @(
      'schema_version',
      'workflow_id',
      'license',
      'fixtures',
      'public_workflows',
      'hostile_cases',
      'mutation_cases',
      'limit_cases',
      'budget_cases'
    )
  Assert-Condition (
    $Corpus.schema_version -ceq '1.0.0' -and
    $Corpus.workflow_id -ceq 'font-collection-complete-public-v2' -and
    $Corpus.license -ceq 'Apache-2.0'
  ) 'Font collection corpus identity or license drifted.'
  Assert-Condition (
    @($Corpus.fixtures).Count -eq 7 -and
    @($Corpus.public_workflows).Count -eq 8 -and
    @($Corpus.hostile_cases).Count -eq 24 -and
    @($Corpus.mutation_cases).Count -eq 9 -and
    @($Corpus.limit_cases).Count -eq 44 -and
    @($Corpus.budget_cases).Count -eq 12
  ) 'Font collection corpus group counts drifted.'
  foreach ($fixture in @($Corpus.fixtures)) {
    Assert-ExactSequence "Font collection fixture '$($fixture.id)' schema" `
      @($fixture.PSObject.Properties.Name) `
      @(
        'id',
        'origin',
        'container_version',
        'face_count',
        'dsig_status',
        'profiles',
        'expected_use'
      )
  }
  $caseGroups = @(
    @($Corpus.public_workflows),
    @($Corpus.hostile_cases),
    @($Corpus.mutation_cases),
    @($Corpus.limit_cases),
    @($Corpus.budget_cases)
  )
  foreach ($group in $caseGroups) {
    foreach ($case in $group) {
      Assert-ExactSequence 'Font collection case schema' `
        @($case.PSObject.Properties.Name) `
        @(
          'id',
          'fixture_id',
          'stage',
          'entrypoint',
          'face_index',
          'mutation_window',
          'authority',
          'boundary',
          'error',
          'publication',
          'budget_before',
          'budget_after'
        )
      Assert-ExactSequence 'Font collection case error schema' `
        @($case.error.PSObject.Properties.Name) `
        @(
          'category',
          'code',
          'operation',
          'context',
          'source_offset',
          'requested',
          'limit'
        )
      foreach ($budgetName in @('budget_before', 'budget_after')) {
        Assert-ExactSequence "Font collection case $budgetName schema" `
          @($case.$budgetName.PSObject.Properties.Name) `
          @(
            'bytes',
            'allocations',
            'allocation_size',
            'width',
            'height',
            'pixels',
            'depth',
            'work'
          )
      }
      if ($case.boundary -in @('failure', 'one-short')) {
        Assert-Condition (
          ($case.budget_before | ConvertTo-Json -Depth 8 -Compress) -ceq
          ($case.budget_after | ConvertTo-Json -Depth 8 -Compress)
        ) "Font collection case '$($case.id)' failed budget atomicity drifted."
      }
    }
  }
  $orderedIds = @(
    @($Corpus.fixtures.id) +
    @($Corpus.public_workflows.id) +
    @($Corpus.hostile_cases.id) +
    @($Corpus.mutation_cases.id) +
    @($Corpus.limit_cases.id) +
    @($Corpus.budget_cases.id)
  )
  Assert-Condition (
    $orderedIds.Count -eq 104
  ) 'Font collection corpus IDs must be complete.'
  foreach ($group in @(
      @($Corpus.fixtures.id),
      @($Corpus.public_workflows.id),
      @($Corpus.hostile_cases.id),
      @($Corpus.mutation_cases.id),
      @($Corpus.limit_cases.id),
      @($Corpus.budget_cases.id)
    )) {
    Assert-Condition (
      @($group | Select-Object -Unique).Count -eq $group.Count
    ) 'Font collection corpus IDs must be unique within each ordered group.'
  }
  $identityBytes = [Text.UTF8Encoding]::new($false).GetBytes(
    $orderedIds -join "`n"
  )
  $identityDigest = [Convert]::ToHexString(
    [Security.Cryptography.SHA256]::HashData($identityBytes)
  ).ToLowerInvariant()
  Assert-Condition (
    $identityDigest -ceq
      '6f5564d1af06f0bccd2b7f867a739adb09c84c4ab3b0762cfeeff480f1fedd85'
  ) 'Font collection corpus ordered IDs drifted.'
  $semanticJson = $Corpus | ConvertTo-Json -Depth 32 -Compress
  $semanticDigest = [Convert]::ToHexString(
    [Security.Cryptography.SHA256]::HashData(
      [Text.UTF8Encoding]::new($false).GetBytes($semanticJson)
    )
  ).ToLowerInvariant()
  Assert-Condition (
    $semanticDigest -ceq
      '82c939e3a6818c27224d92d9901f9ee1b9d54f57344a2a0ef929c90ebba457bb'
  ) 'Font collection corpus exact semantic digest drifted.'
}

function Assert-FontCollectionOracleContract {
  [CmdletBinding()]
  param([Parameter(Mandatory)][object]$Oracle)

  Assert-ExactSequence 'Font collection oracle schema' `
    @($Oracle.PSObject.Properties.Name) `
    @(
      'schema_version',
      'oracle',
      'lineage',
      'derivative',
      'collection',
      'faces',
      'shared_tables',
      'standalone_oracle_binding'
    )
  Assert-Condition (
    $Oracle.schema_version -ceq '1.0.0' -and
    $Oracle.oracle.independence -ceq
      'offline parser; does not invoke tchivs/mb-font'
  ) 'Font collection oracle identity or independence drifted.'
  Assert-ExactSequence 'Font collection derivative schema' `
    @($Oracle.derivative.PSObject.Properties.Name) `
    @('path','length','sha256','signature','version','algorithm')
  Assert-Condition (
    [int64]$Oracle.derivative.length -eq 757428 -and
    $Oracle.derivative.sha256 -ceq
      '833d406d389d4ef3b0a38f168af7d51ca16c88605e1727f6d631871a4e05f80b' -and
    $Oracle.derivative.signature -ceq 'ttcf' -and
    $Oracle.derivative.version -ceq '0x00010000'
  ) 'Font licensed derivative identity drifted.'
  Assert-ExactSequence 'Font collection structure schema' `
    @($Oracle.collection.PSObject.Properties.Name) `
    @(
      'face_count',
      'face_offsets',
      'directory_length',
      'payload_start',
      'dsig_status',
      'profiles'
    )
  Assert-Condition (
    [int]$Oracle.collection.face_count -eq 2 -and
    (@($Oracle.collection.face_offsets) -join ',') -ceq '20,352' -and
    [int]$Oracle.collection.directory_length -eq 332 -and
    [int]$Oracle.collection.payload_start -eq 684 -and
    $Oracle.collection.dsig_status -ceq 'absent' -and
    (@($Oracle.collection.profiles) -join ',') -ceq
      'StaticGlyf,StaticGlyf' -and
    @($Oracle.shared_tables).Count -eq 20
  ) 'Font collection structure or exact sharing drifted.'
  Assert-Condition (
    $Oracle.lineage.notice_path -ceq
      'fixtures/font/dejavu-sans-2.37/LICENSE' -and
    -not [string]::IsNullOrWhiteSpace([string]$Oracle.lineage.notice_sha256) -and
    $Oracle.lineage.redistribution_status -ceq 'confirmed'
  ) 'Font collection derivative notice or redistribution facts drifted.'
  Assert-Condition (
    $Oracle.standalone_oracle_binding.sha256 -ceq
      '4247394c3795a56aaf28c1885403201cfc277b06125f5887e14a40f3b4c6229a' -and
    (@($Oracle.standalone_oracle_binding.face_indices) -join ',') -ceq '0,1'
  ) 'Font collection standalone-oracle binding drifted.'
}

function Assert-FontQualificationWorkflowContract {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$WorkflowText)

  Assert-Condition (
    $WorkflowText -cnotmatch "`t" -and
    $WorkflowText -cnotmatch '(?m)^\s*[^#\r\n]+[&*][A-Za-z0-9_-]+'
  ) 'Quality workflow FontQualification contract forbids tabs and YAML aliases.'
  $normalized = $WorkflowText.Replace("`r`n", "`n")
  $lines = @($normalized -split "`n")
  $jobsLine = [Array]::IndexOf($lines, 'jobs:')
  Assert-Condition ($jobsLine -ge 0) 'Quality workflow jobs mapping is missing.'
  $jobs = [ordered]@{}
  $currentJob = $null
  for ($index = $jobsLine + 1; $index -lt $lines.Count; $index++) {
    $line = $lines[$index]
    if ($line -cmatch '^[^ #]') { break }
    if ($line -cmatch '^  (?<key>[a-z0-9-]+):\s*$') {
      $currentJob = $Matches.key
      Assert-Condition (-not $jobs.Contains($currentJob)) (
        "Quality workflow duplicates job '$currentJob'."
      )
      $jobs[$currentJob] = [Collections.Generic.List[string]]::new()
      continue
    }
    if ($null -ne $currentJob) {
      $jobs[$currentJob].Add($line)
    }
  }

  $laneCommand = (
    'run: ./scripts/quality.ps1 -Lane FontQualification ' +
    '-EvidenceDirectory artifacts/release-qualification/ci-font-v2'
  )
  $fontJobKeys = @(
    foreach ($entry in $jobs.GetEnumerator()) {
      if (@($entry.Value | Where-Object {
        $_.Trim() -cmatch '^run:\s+[.]/scripts/quality[.]ps1\s+-Lane\s+FontQualification\b'
      }).Count -gt 0) {
        [string]$entry.Key
      }
    }
  )
  Assert-Condition (
    $fontJobKeys.Count -eq 1 -and
    $fontJobKeys[0] -ceq 'font-qualification' -and
    $jobs.Contains('font-qualification')
  ) 'Quality workflow must contain exactly one FontQualification job.'
  $fontJobLines = @($jobs['font-qualification'])
  $fontJobText = $fontJobLines -join "`n"
  Assert-Condition (
    @($fontJobLines | Where-Object { $_ -ceq '    timeout-minutes: 20' }).Count -eq 1
  ) 'Measured FontQualification timeout must remain 20 minutes.'
  Assert-Condition (
    @($fontJobLines | Where-Object { $_.Trim() -ceq $laneCommand }).Count -eq 1
  ) 'FontQualification CI command must own the fresh v2 evidence directory.'
  Assert-Condition (
    @($fontJobLines | Where-Object {
      $_ -cmatch '^    continue-on-error:'
    }).Count -eq 0
  ) 'FontQualification job must not continue on error.'

  $stepsLine = [Array]::IndexOf($fontJobLines, '    steps:')
  Assert-Condition ($stepsLine -ge 0) 'FontQualification steps sequence is missing.'
  $steps = [Collections.Generic.List[object]]::new()
  $currentStep = $null
  for ($index = $stepsLine + 1; $index -lt $fontJobLines.Count; $index++) {
    $line = $fontJobLines[$index]
    if ($line -cmatch '^      - (?<rest>.+)$') {
      $currentStep = [Collections.Generic.List[string]]::new()
      $currentStep.Add('      ' + $Matches.rest)
      $steps.Add($currentStep)
    } elseif ($null -ne $currentStep) {
      $currentStep.Add($line)
    }
  }
  $uploadSteps = @(
    $steps | Where-Object {
      @($_ | Where-Object {
        $_.Trim() -cmatch '^uses:\s*actions/upload-artifact@'
      }).Count -gt 0
    }
  )
  Assert-Condition (
    $uploadSteps.Count -eq 1 -and
    @($fontJobLines | Where-Object {
      $_.Trim() -cmatch '^uses:\s*actions/upload-artifact@'
    }).Count -eq 1
  ) 'FontQualification CI upload must be success-only, pinned, and v2-owned.'
  $upload = @(
    $uploadSteps[0] |
      ForEach-Object { $_.Trim() } |
      Where-Object { $_ -cne '' }
  )
  Assert-Condition (
    $upload.Count -eq 6 -and
    $upload[0] -ceq 'name: Upload passing font qualification evidence' -and
    $upload[1] -ceq 'if: ${{ success() }}' -and
    $upload[2] -ceq
      'uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02' -and
    $upload[4] -ceq 'name: font-qualification-evidence-v2' -and
    $upload[5] -ceq 'path: artifacts/release-qualification/ci-font-v2'
  ) 'FontQualification CI upload must be success-only, pinned, and v2-owned.'
  Assert-ExactSequence 'FontQualification upload step schema and values' `
    $upload `
    @(
      'name: Upload passing font qualification evidence',
      'if: ${{ success() }}',
      'uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02',
      'with:',
      'name: font-qualification-evidence-v2',
      'path: artifacts/release-qualification/ci-font-v2'
    )
  Assert-Condition (
    ([regex]::Matches(
      $fontJobText,
      [regex]::Escape('artifacts/release-qualification/ci-font-v2')
    )).Count -eq 2
  ) 'FontQualification evidence directory may appear only in its runner and upload steps.'
}

function Assert-QualityWorkflowToolchainTransport {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$QualityWorkflowText,
    [Parameter(Mandatory)][string]$AllWorkflowText,
    [Parameter(Mandatory)][string]$InstallerText
  )

  Assert-Condition (
    $AllWorkflowText -cnotmatch '(?m)^\s*version:\s*latest\s*$'
  ) 'CI workflows must not request setup action version latest.'
  Assert-Condition (
    $AllWorkflowText -cnotmatch 'hustcer/setup-moonbit'
  ) 'CI workflows must not use the unavailable setup-moonbit transport.'
  Assert-Condition (
    $AllWorkflowText -cnotmatch (
      "https://[^'`"\s]*latest[^'`"\s]*\.tar\.gz"
    )
  ) 'CI workflows must not use mutable latest archive URLs.'

  $installCommand = './scripts/ci/Install-PinnedMoonBit.ps1'
  $jobBodies = @{}
  $inJobs = $false
  $currentJob = $null
  $currentBody = $null
  foreach ($line in ($QualityWorkflowText -split "\r?\n")) {
    if ($line -ceq 'jobs:') {
      $inJobs = $true
      continue
    }
    if ($inJobs -and $line -match '^  ([A-Za-z0-9_-]+):\s*$') {
      if ($null -ne $currentJob) {
        $jobBodies[$currentJob] = $currentBody.ToString()
      }
      $currentJob = $Matches[1]
      $currentBody = [Text.StringBuilder]::new()
      continue
    }
    if ($null -ne $currentBody) {
      [void]$currentBody.AppendLine($line)
    }
  }
  if ($null -ne $currentJob) {
    $jobBodies[$currentJob] = $currentBody.ToString()
  }
  $jobTimeoutMinutes = @{}
  $jobStepBodies = @{}
  $expectedInstallStep = @(
    '      - name: Install content-addressed MoonBit toolchain',
    '        shell: pwsh',
    '        run: ./scripts/ci/Install-PinnedMoonBit.ps1'
  ) -join "`n"
  foreach ($jobName in @(
      'font-qualification',
      'required',
      'llvm-experimental'
    )) {
    Assert-Condition $jobBodies.ContainsKey($jobName) (
      "Quality workflow job '$jobName' is missing."
    )
    $jobBody = [string]$jobBodies[$jobName]
    $jobTimeoutMatches = @(
      [regex]::Matches(
        $jobBody,
        '(?m)^    timeout-minutes:\s*(?<minutes>\d+)\s*$'
      )
    )
    Assert-Condition ($jobTimeoutMatches.Count -eq 1) (
      "Quality workflow job '$jobName' must declare exactly one timeout."
    )
    $jobTimeoutMinutes[$jobName] = [int](
      $jobTimeoutMatches[0].Groups['minutes'].Value
    )
    $jobSteps = @(
      [regex]::Matches(
        $jobBody,
        '(?ms)^      - .*?(?=^      - |\z)'
      ) | ForEach-Object {
        $_.Value.Replace("`r`n", "`n").TrimEnd()
      }
    )
    $jobStepBodies[$jobName] = $jobSteps
    $installSteps = @(
      $jobSteps | Where-Object {
        $_.Contains(
          'name: Install content-addressed MoonBit toolchain',
          [StringComparison]::Ordinal
        ) -or
        $_.Contains($installCommand, [StringComparison]::Ordinal)
      }
    )
    Assert-Condition ($installSteps.Count -eq 1) (
      "Quality workflow job '$jobName' must contain exactly one installer " +
      'step candidate.'
    )
    Assert-Condition ($installSteps[0] -ceq $expectedInstallStep) (
      "Quality workflow job '$jobName' must bind the exact installer name, " +
      'immediate shell: pwsh, and exact run command without extra, ' +
      'duplicated, or reordered fields.'
    )
  }
  Assert-Condition (
    $jobTimeoutMinutes['font-qualification'] -eq 20 -and
    $jobTimeoutMinutes['llvm-experimental'] -eq 20
  ) 'Only the Required job may use the expanded timeout budget.'
  $requiredJobBody = [string]$jobBodies['required']
  $requiredWrapperTimeoutMatches = @(
    [regex]::Matches(
      $requiredJobBody,
      '(?m)-TimeoutSeconds\s+(?<seconds>\d+)\s*$'
    )
  )
  Assert-Condition ($requiredWrapperTimeoutMatches.Count -eq 1) (
    'Required job must declare exactly one bounded wrapper timeout.'
  )
  $requiredWrapperTimeoutSeconds = [int](
    $requiredWrapperTimeoutMatches[0].Groups['seconds'].Value
  )
  Assert-Condition (
    ($jobTimeoutMinutes['required'] * 60) -gt
    $requiredWrapperTimeoutSeconds
  ) (
    'Required runner timeout must exceed its bounded wrapper timeout to ' +
    'preserve cleanup and diagnostic upload time.'
  )
  Assert-Condition (
    $jobTimeoutMinutes['required'] -eq 35 -and
    $requiredWrapperTimeoutSeconds -eq 1800
  ) (
    'Required job must use the exact paired timeout budget: 35 runner ' +
    'minutes and 1800 wrapper seconds.'
  )
  $requiredSteps = @($jobStepBodies['required'])
  $expectedRequiredPosixStep = @(
    '      - name: Verify Required POSIX process containment',
    '        shell: pwsh',
    '        run: ./scripts/quality/Test-RequiredProcessTreeTermination.ps1'
  ) -join "`n"
  $requiredPosixSteps = @(
    $requiredSteps | Where-Object {
      $_.Contains(
        'name: Verify Required POSIX process containment',
        [StringComparison]::Ordinal
      ) -or
      $_.Contains(
        './scripts/quality/Test-RequiredProcessTreeTermination.ps1',
        [StringComparison]::Ordinal
      )
    }
  )
  Assert-Condition (
    $requiredPosixSteps.Count -eq 1 -and
    $requiredPosixSteps[0] -ceq $expectedRequiredPosixStep
  ) 'Required job must retain the exact blocking POSIX containment gate.'
  $expectedRequiredRunStep = @(
    '      - name: Run required quality lane',
    '        shell: pwsh',
    '        run: ./scripts/quality/Invoke-RequiredBounded.ps1 -EvidenceDirectory artifacts/release-qualification/ci-required -TimeoutSeconds 1800'
  ) -join "`n"
  $requiredRunSteps = @(
    $requiredSteps | Where-Object {
      $_.Contains(
        'name: Run required quality lane',
        [StringComparison]::Ordinal
      ) -or
      $_.Contains(
        './scripts/quality/Invoke-RequiredBounded.ps1',
        [StringComparison]::Ordinal
      )
    }
  )
  Assert-Condition (
    $requiredRunSteps.Count -eq 1 -and
    $requiredRunSteps[0] -ceq $expectedRequiredRunStep
  ) (
    'Required job must retain the exact fail-closed bounded quality step.'
  )
  $expectedRequiredUploadStep = @(
    '      - name: Upload Required diagnostic evidence',
    '        if: ${{ always() }}',
    '        uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02',
    '        with:',
    '          name: required-diagnostic',
    '          path: artifacts/release-qualification/ci-required'
  ) -join "`n"
  $requiredUploadSteps = @(
    $requiredSteps | Where-Object {
      $_.Contains(
        'name: Upload Required diagnostic evidence',
        [StringComparison]::Ordinal
      ) -or
      $_.Contains(
        'name: required-diagnostic',
        [StringComparison]::Ordinal
      )
    }
  )
  Assert-Condition (
    $requiredUploadSteps.Count -eq 1 -and
    $requiredUploadSteps[0] -ceq $expectedRequiredUploadStep
  ) (
    'Required job must always upload its exact diagnostic evidence path.'
  )
  Assert-Condition (
    ([regex]::Matches(
      $QualityWorkflowText,
      [regex]::Escape($installCommand)
    )).Count -eq 3
  ) 'Quality workflow must invoke the pinned MoonBit installer exactly three times.'
  Assert-Condition (
    ([regex]::Matches(
      $QualityWorkflowText,
      '(?m)^\s*- name: Install content-addressed MoonBit toolchain\s*$'
    )).Count -eq 3
  ) 'Quality workflow must expose exactly three content-addressed install steps.'

  $toolchainUrl = 'https://github.com/tchivs/moonbit-foundation/releases/download/ci-toolchain-0.1.20260713-75c7e1f/moonbit-linux-x86_64-0.1.20260713-75c7e1f.tar.gz'
  $coreUrl = 'https://github.com/tchivs/moonbit-foundation/releases/download/ci-toolchain-0.1.20260713-75c7e1f/moonbit-core-0.1.20260713-75c7e1f.tar.gz'
  Assert-Condition (
    $InstallerText -cnotmatch (
      "https://[^'`"\s]*latest[^'`"\s]*\.tar\.gz"
    )
  ) 'Pinned MoonBit installer must not use mutable latest archive URLs.'
  $archiveUrls = @(
    [regex]::Matches(
      $InstallerText,
      "https://[^'`"\s]*\.tar\.gz"
    ) | ForEach-Object Value
  )
  Assert-ExactSequence `
    'Pinned MoonBit immutable archive URL set' `
    $archiveUrls `
    @($toolchainUrl, $coreUrl)

  $toolchainBlock = [regex]::Match(
    $InstallerText,
    '(?ms)^\$ToolchainArchive\s*=.*?^\}'
  ).Value
  $coreBlock = [regex]::Match(
    $InstallerText,
    '(?ms)^\$CoreArchive\s*=.*?^\}'
  ).Value
  foreach ($expectation in @(
      [pscustomobject]@{
        Block = $toolchainBlock
        Values = @(
          $toolchainUrl,
          'Length = [long]73033507',
          "Sha256 = '31b7fc5cc78657964a6d545792ecd7fb8eed51b97c7431a17458b58734303381'"
        )
      },
      [pscustomobject]@{
        Block = $coreBlock
        Values = @(
          $coreUrl,
          'Length = [long]1302919',
          "Sha256 = '03ad55b99f3e431f3cb81b4e2bb28bb98173304e4a1b18a891ea027cabba5d1c'"
        )
      }
    )) {
    Assert-Condition (
      -not [string]::IsNullOrWhiteSpace($expectation.Block)
    ) 'Pinned MoonBit archive identity block is missing.'
    foreach ($requiredValue in $expectation.Values) {
      Assert-Condition (
        $expectation.Block.Contains(
          $requiredValue,
          [StringComparison]::Ordinal
        )
      ) "Pinned MoonBit archive identity drifted: '$requiredValue'."
    }
  }

  foreach ($requiredValue in @(
      "moon = '50913178bee7e904850fc37d5b16adda7e6c1616d2704994714b70ac86f9a7ab'",
      "moonc = '31633647318a571d6aac9a2144a0e1ba3c946ea806d1409778894fe76e604511'",
      "moonrun = '44b7d5427837c8c0f7379a9d4fa9f3e1aac0f433041b3ffe16e78e1c5f151ab4'",
      "moon = 'moon 0.1.20260713 (75c7e1f 2026-07-13)'",
      "moonc = 'v0.10.4+2cc641edf (2026-07-15)'",
      "moonrun = 'moonrun 0.1.20260713 (75c7e1f 2026-07-13)'"
    )) {
    Assert-Condition (
      $InstallerText.Contains($requiredValue, [StringComparison]::Ordinal)
    ) "Pinned MoonBit binary identity drifted: '$requiredValue'."
  }

  $identityCapture = [regex]::Matches(
    $InstallerText,
    '(?ms)^\s*\$output\s*=\s*@\(\s*\r?\n\s*switch\s*\(\$Name\)\s*\{'
  )
  Assert-Condition ($identityCapture.Count -eq 1) (
    'Pinned MoonBit identity output must use one outer array capture.'
  )
  $executableMemberScope = [regex]::Match(
    $InstallerText,
    '(?ms)^\$ExecutableMembers\s*=\s*@\(\s*(?<body>.*?)^\)\s*$'
  )
  Assert-Condition $executableMemberScope.Success (
    'Pinned MoonBit executable member manifest is missing.'
  )
  $executableMembers = @(
    [regex]::Matches(
      $executableMemberScope.Groups['body'].Value,
      "'([^']+)'"
    ) | ForEach-Object { $_.Groups[1].Value }
  )
  Assert-ExactSequence `
    'Pinned MoonBit executable member manifest' `
    $executableMembers `
    @(
      'bin/internal/tcc',
      'bin/moon',
      'bin/moon_cove_report',
      'bin/moon-cram',
      'bin/moon-ide',
      'bin/moon-lsp',
      'bin/moon-wasm-opt',
      'bin/moonc',
      'bin/mooncake',
      'bin/moondoc',
      'bin/moonfmt',
      'bin/mooninfo',
      'bin/moonrun'
    )
  $dataMemberScope = [regex]::Match(
    $InstallerText,
    '(?ms)^\$DataMembers\s*=\s*@\(\s*(?<body>.*?)^\)\s*$'
  )
  Assert-Condition $dataMemberScope.Success (
    'Pinned MoonBit data member manifest is missing.'
  )
  $dataMembers = @(
    [regex]::Matches(
      $dataMemberScope.Groups['body'].Value,
      "'([^']+)'"
    ) | ForEach-Object { $_.Groups[1].Value }
  )
  Assert-ExactSequence `
    'Pinned MoonBit data member manifest' `
    $dataMembers `
    @('bin/moonlex.wasm', 'bin/moonyacc.wasm')
  Assert-Condition (
    @($executableMembers | Where-Object { $dataMembers -ccontains $_ }).Count -eq 0
  ) 'Pinned MoonBit executable and data member manifests must be disjoint.'
  $verifiedBinaryScope = [regex]::Match(
    $InstallerText,
    '(?ms)^\s*\$verifiedBinaryPaths\s*=\s*@\(\s*(?<body>.*?)^\s*\)\s*$'
  )
  Assert-Condition $verifiedBinaryScope.Success (
    'Pinned MoonBit verified binary identity scope is missing.'
  )
  $verifiedBinaryNames = @(
    [regex]::Matches(
      $verifiedBinaryScope.Groups['body'].Value,
      "\`$binaryPaths\['([^']+)'\]"
    ) | ForEach-Object { $_.Groups[1].Value }
  )
  Assert-ExactSequence `
    'Pinned MoonBit verified binary identity scope' `
    $verifiedBinaryNames `
    @('moon', 'moonc', 'moonrun')
  $binDirectoryScope = [regex]::Match(
    $InstallerText,
    '(?m)^\$BinDirectories\s*=\s*@\((?<body>[^\r\n]+)\)\s*$'
  )
  Assert-Condition $binDirectoryScope.Success (
    'Pinned MoonBit bin directory manifest is missing.'
  )
  $binDirectories = @(
    [regex]::Matches(
      $binDirectoryScope.Groups['body'].Value,
      "'([^']+)'"
    ) | ForEach-Object { $_.Groups[1].Value }
  )
  Assert-ExactSequence `
    'Pinned MoonBit bin directory manifest' `
    $binDirectories `
    @('bin/internal')
  Assert-Condition (
    ([regex]::Matches(
      $InstallerText,
      "(?m)^\s*Assert-PinnedSequence\s*``\r?\n" +
        "\s*-Name 'BIN-DIRECTORIES'\s*``$"
    )).Count -eq 1 -and
    ([regex]::Matches(
      $InstallerText,
      "(?m)^\s*Assert-PinnedSequence\s*``\r?\n" +
        "\s*-Name 'BIN-LEAVES'\s*``$"
    )).Count -eq 1
  ) 'Pinned MoonBit installer must verify the exact extracted bin tree.'
  $executablePathScope = [regex]::Matches(
    $InstallerText,
    (
      '(?ms)^\s*\$executablePaths\s*=\s*@\(\s*' +
      '\$ExecutableMembers \| ForEach-Object\s*\{\s*' +
      'Join-Path \$stagingPath \$_\s*\}\s*\)'
    )
  )
  Assert-Condition ($executablePathScope.Count -eq 1) (
    'Pinned MoonBit executable paths must derive only from the manifest.'
  )
  Assert-Condition (
    ([regex]::Matches(
      $InstallerText,
      [regex]::Escape(
        "& `$chmodCommand.Source 'a+x' '--' @executablePaths"
      )
    )).Count -eq 1
  ) 'Pinned MoonBit installer must chmod exactly the executable manifest.'
  Assert-Condition (
    ([regex]::Matches(
      $InstallerText,
      (
        '(?ms)^\s*foreach \(\$path in \$executablePaths\)\s*\{' +
        '.*?\[IO\.File\]::GetUnixFileMode\(\$path\).*?' +
        'P08-TOOLCHAIN-BINARY-MODE.*?^\s*\}'
      )
    )).Count -eq 1
  ) 'Pinned MoonBit installer must verify executable mode bits.'
  Assert-Condition (
    ([regex]::Matches(
      $InstallerText,
      (
        '(?ms)^\s*\$dataPaths\s*=\s*@\(\s*' +
        '\$DataMembers \| ForEach-Object\s*\{\s*' +
        'Join-Path \$stagingPath \$_\s*\}\s*\)\s*' +
        'foreach \(\$path in \$dataPaths\)\s*\{' +
        '.*?\[IO\.File\]::GetUnixFileMode\(\$path\).*?' +
        '\[int\]\(\$mode -band \$executeMask\) -ne 0.*?' +
        'P08-TOOLCHAIN-DATA-MODE.*?^\s*\}'
      )
    )).Count -eq 1
  ) 'Pinned MoonBit installer must keep wasm data members non-executable.'
  Assert-Condition (
    ([regex]::Matches(
      $InstallerText,
      [regex]::Escape(
        "`$identityBinPath = [IO.Path]::GetFullPath((Join-Path " +
        "`$stagingPath 'bin'))"
      )
    )).Count -eq 1
  ) (
    'Pinned MoonBit identity PATH must expose exactly authenticated ' +
    'staging/bin.'
  )
  $identityPathValidation = [regex]::Matches(
    $InstallerText,
    (
      '(?ms)^\s*foreach\s*\(\$path in \$verifiedBinaryPaths\)\s*\{\s*' +
      '\$binaryParent\s*=\s*\[IO\.Path\]::GetDirectoryName\(\s*' +
      '\[IO\.Path\]::GetFullPath\(\$path\)\s*\)\s*' +
      'if\s*\(-not \[string\]::Equals\(\s*\$binaryParent,\s*' +
      '\$identityBinPath,\s*\[StringComparison\]::Ordinal\s*\)\)\s*\{' +
      '.*?P08-TOOLCHAIN-IDENTITY-PATH.*?^\s*\}'
    )
  )
  Assert-Condition ($identityPathValidation.Count -eq 1) (
    'Pinned MoonBit identity PATH must contain only authenticated binaries.'
  )
  $identityPathScope = [regex]::Matches(
    $InstallerText,
    (
      '(?ms)^\s*\$previousPath\s*=\s*\[string\]\$env:PATH\s*\r?\n' +
      '\s*try\s*\{\s*\r?\n' +
      '\s*\$env:PATH\s*=\s*if\s*' +
      '\(\[string\]::IsNullOrEmpty\(\$previousPath\)\)\s*\{\s*\r?\n' +
      '\s*\$identityBinPath\s*\r?\n\s*\}\s*else\s*\{\s*\r?\n' +
      '\s*\$identityBinPath\s*\+\s*\[IO\.Path\]::PathSeparator\s*\+' +
      '\s*\$previousPath\s*\r?\n\s*\}\s*\r?\n' +
      '\s*foreach\s*\(\$name in \$BinaryIdentities\.Keys\)\s*\{' +
      '.*?^\s*\}\s*\r?\n\s*\}\s*finally\s*\{\s*\r?\n' +
      '\s*\$env:PATH\s*=\s*\$previousPath\s*\r?\n\s*\}'
    )
  )
  Assert-Condition ($identityPathScope.Count -eq 1) (
    'Pinned MoonBit identity PATH must be scoped with finally restoration.'
  )
  Assert-Condition (
    ([regex]::Matches(
      $InstallerText,
      '(?m)^\s*\$env:PATH\s*='
    )).Count -eq 4
  ) 'Pinned MoonBit installer must not expose a broader process PATH.'
  Assert-Condition (
    ([regex]::Matches(
      $InstallerText,
      [regex]::Escape(
        "`$coreStagingPath = Join-Path `$workRoot 'core-staging'"
      )
    )).Count -eq 1
  ) (
    'Pinned MoonBit core extraction must use one dedicated work-root ' +
    'staging directory.'
  )
  $normalizedInstallerText = $InstallerText.Replace("`r`n", "`n")
  $coreArchiveLayout = @(
    '  Expand-PinnedArchive `',
    '    -TarPath $tarCommand.Source `',
    '    -ArchivePath $corePath `',
    '    -Destination $coreStagingPath `',
    '    -ExpectedRoot ''./core/'' `',
    '    -RequiredMember ''./core/moon.mod'' `',
    '    -ForbiddenMembers @(''./core/moon.mod.json'')'
  ) -join "`n"
  Assert-Condition (
    ([regex]::Matches(
      $normalizedInstallerText,
      [regex]::Escape($coreArchiveLayout)
    )).Count -eq 1
  ) (
    'Pinned MoonBit core archive must require only the exact ./core/ layout ' +
    'and ./core/moon.mod marker while rejecting the legacy marker.'
  )
  Assert-Condition (
    $InstallerText.Contains(
      '$member.StartsWith(',
      [StringComparison]::Ordinal
    ) -and
    $InstallerText.Contains(
      '$ExpectedRoot,',
      [StringComparison]::Ordinal
    ) -and
    $InstallerText.Contains(
      '$requiredCount -ne 1',
      [StringComparison]::Ordinal
    ) -and
    $InstallerText.Contains(
      '$normalizedMembers -ccontains $forbiddenMember',
      [StringComparison]::Ordinal
    )
  ) (
    'Pinned MoonBit archive member policy must reject unexpected roots, ' +
    'missing or duplicate markers, and forbidden legacy members.'
  )
  $coreInstallLayout = [regex]::Matches(
    $InstallerText,
    (
      '(?ms)^\s*\$coreRoots\s*=\s*@\(Get-ChildItem ' +
      '-LiteralPath \$coreStagingPath -Force\)\s*\r?\n' +
      '\s*if \(\$coreRoots\.Count -ne 1 -or\s*' +
      '\$coreRoots\[0\]\.Name -cne ''core'' -or\s*' +
      '-not \$coreRoots\[0\]\.PSIsContainer\)\s*\{.*?' +
      'P08-TOOLCHAIN-CORE-LAYOUT.*?^\s*\}\s*\r?\n' +
      '\s*\$coreMarker = Join-Path \$coreStagingPath ''core/moon\.mod''\s*' +
      '\r?\n\s*if \(-not \(Test-Path -LiteralPath \$coreMarker ' +
      '-PathType Leaf\)\)\s*\{.*?P08-TOOLCHAIN-CORE-MISSING: ' +
      'core/moon\.mod.*?^\s*\}\s*\r?\n' +
      '\s*\$legacyCoreMarker = Join-Path \$coreStagingPath ' +
      '''core/moon\.mod\.json''\s*\r?\n' +
      '\s*if \(Test-Path -LiteralPath \$legacyCoreMarker\)\s*\{' +
      '.*?P08-TOOLCHAIN-CORE-LEGACY: core/moon\.mod\.json.*?^\s*\}'
    )
  )
  Assert-Condition ($coreInstallLayout.Count -eq 1) (
    'Pinned MoonBit isolated core staging must contain only the core/ root ' +
    'and moon.mod and must reject the legacy moon.mod.json marker.'
  )
  $corePromotion = [regex]::Matches(
    $InstallerText,
    (
      '(?ms)^\s*\$installedCorePath = Join-Path \$libraryPath ''core''\s*' +
      '\r?\n\s*if \(Test-Path -LiteralPath \$installedCorePath\)\s*\{' +
      '.*?P08-TOOLCHAIN-CORE-DESTINATION.*?^\s*\}\s*\r?\n' +
      '\s*Move-Item\s*`\r?\n' +
      '\s*-LiteralPath \$coreRoots\[0\]\.FullName\s*`\r?\n' +
      '\s*-Destination \$installedCorePath\s*\r?\n' +
      '\s*\$installedCoreMarker = Join-Path \$installedCorePath ' +
      '''moon\.mod''\s*\r?\n' +
      '\s*if \(-not \(Test-Path -LiteralPath \$installedCoreMarker ' +
      '-PathType Leaf\)\)\s*\{.*?P08-TOOLCHAIN-CORE-INSTALL: ' +
      'core/moon\.mod.*?^\s*\}\s*\r?\n' +
      '\s*if \(Test-Path -LiteralPath \(\s*Join-Path ' +
      '\$installedCorePath ''moon\.mod\.json''\s*\)\)\s*\{' +
      '.*?P08-TOOLCHAIN-CORE-INSTALL-LEGACY: ' +
      'core/moon\.mod\.json.*?^\s*\}'
    )
  )
  Assert-Condition ($corePromotion.Count -eq 1) (
    'Pinned MoonBit core must be validated before moving only core/ into an ' +
    'absent toolchain lib/core destination and verifying the final marker.'
  )
  Assert-Condition (
    ([regex]::Matches(
      $InstallerText,
      [regex]::Escape(
        "`$binPath = [IO.Path]::GetFullPath((Join-Path " +
        "`$destination 'bin'))"
      )
    )).Count -eq 1
  ) 'Pinned MoonBit bundle PATH must use the exact installed bin directory.'
  $bundlePathExposure = [regex]::Matches(
    $InstallerText,
    (
      '(?ms)^\s*\$bundlePreviousPath = \[string\]\$env:PATH\s*\r?\n' +
      '\s*try\s*\{\s*\r?\n' +
      '\s*\$env:PATH = if ' +
      '\(\[string\]::IsNullOrEmpty\(\$bundlePreviousPath\)\)\s*\{' +
      '\s*\$binPath\s*\}\s*else\s*\{\s*' +
      '\$binPath \+ \[IO\.Path\]::PathSeparator \+ ' +
      '\$bundlePreviousPath\s*\}\s*\r?\n\s*& \$bundleMoonPath'
    )
  )
  Assert-Condition ($bundlePathExposure.Count -eq 1) (
    'Pinned MoonBit core bundling must expose only the exact installed bin ' +
    'directory through a scoped process PATH.'
  )
  Assert-Condition (
    ([regex]::Matches(
      $InstallerText,
      (
        '(?ms)^\s*\} finally \{\s*\r?\n' +
        '\s*\$env:PATH = \$bundlePreviousPath\s*\r?\n\s*\}'
      )
    )).Count -eq 1
  ) 'Pinned MoonBit core bundle PATH must be restored in finally.'
  $bundleAllCommand = @(
    '    & $bundleMoonPath `',
    '      -C $finalCorePath `',
    '      bundle `',
    '      --warn-list `',
    '      -a `',
    '      --all',
    '    if ($LASTEXITCODE -ne 0) {',
    '      throw ''P08-TOOLCHAIN-CORE-BUNDLE: --all failed.''',
    '    }'
  ) -join "`n"
  $bundleWasmGcCommand = @(
    '    & $bundleMoonPath `',
    '      -C $finalCorePath `',
    '      bundle `',
    '      --warn-list `',
    '      -a `',
    '      --target wasm-gc `',
    '      --quiet',
    '    if ($LASTEXITCODE -ne 0) {',
    '      throw ''P08-TOOLCHAIN-CORE-BUNDLE: wasm-gc failed.''',
    '    }'
  ) -join "`n"
  foreach ($bundleCommand in @($bundleAllCommand, $bundleWasmGcCommand)) {
    Assert-Condition (
      ([regex]::Matches(
        $normalizedInstallerText,
        [regex]::Escape($bundleCommand)
      )).Count -eq 1
    ) 'Pinned MoonBit core bundle commands must match pinned setup behavior.'
  }
  $bundleTargetScope = [regex]::Match(
    $InstallerText,
    '(?m)^\s*\$bundleTargets\s*=\s*@\((?<body>[^\r\n]+)\)\s*$'
  )
  Assert-Condition $bundleTargetScope.Success (
    'Pinned MoonBit core bundle target verification is missing.'
  )
  $bundleTargets = @(
    [regex]::Matches(
      $bundleTargetScope.Groups['body'].Value,
      "'([^']+)'"
    ) | ForEach-Object { $_.Groups[1].Value }
  )
  Assert-ExactSequence `
    'Pinned MoonBit core bundle targets' `
    $bundleTargets `
    @('js', 'wasm', 'wasm-gc', 'native')
  $bundleLeafScope = [regex]::Match(
    $InstallerText,
    '(?m)^\s*\$bundleLeaves\s*=\s*@\((?<body>[^\r\n]+)\)\s*$'
  )
  Assert-Condition $bundleLeafScope.Success (
    'Pinned MoonBit core bundle leaf verification is missing.'
  )
  $bundleLeaves = @(
    [regex]::Matches(
      $bundleLeafScope.Groups['body'].Value,
      "'([^']+)'"
    ) | ForEach-Object { $_.Groups[1].Value }
  )
  Assert-ExactSequence `
    'Pinned MoonBit core bundle leaves' `
    $bundleLeaves `
    @('prelude/prelude.mi', 'math/math.mi')
  $bundleOutputVerification = [regex]::Matches(
    $InstallerText,
    (
      '(?ms)^\s*foreach \(\$target in \$bundleTargets\)\s*\{' +
      '.*?\$bundleRoot = Join-Path .*?''bundle''.*?' +
      'foreach \(\$leaf in \$bundleLeaves\)\s*\{' +
      '.*?\$bundleLeaf = Join-Path \$bundleRoot \$leaf.*?' +
      'Test-Path -LiteralPath \$bundleLeaf -PathType Leaf.*?' +
      'P08-TOOLCHAIN-CORE-BUNDLE-MISSING.*?^\s*\}\s*^\s*\}'
    )
  )
  Assert-Condition ($bundleOutputVerification.Count -eq 1) (
    'Pinned MoonBit installer must verify both required bundle leaves for ' +
    'all four production targets.'
  )

  $toolchainArchiveCheck = $InstallerText.IndexOf(
    'Assert-PinnedArchive -Path $toolchainPath',
    [StringComparison]::Ordinal
  )
  $coreArchiveCheck = $InstallerText.IndexOf(
    'Assert-PinnedArchive -Path $corePath',
    [StringComparison]::Ordinal
  )
  $toolchainExtraction = $InstallerText.IndexOf(
    '-ArchivePath $toolchainPath',
    [StringComparison]::Ordinal
  )
  $binManifestVerification = $InstallerText.IndexOf(
    "-Name 'BIN-DIRECTORIES'",
    [StringComparison]::Ordinal
  )
  $binaryDigestCheck = $InstallerText.IndexOf(
    'foreach ($name in $BinaryHashes.Keys)',
    [StringComparison]::Ordinal
  )
  $chmodScopeIndex = $InstallerText.IndexOf(
    '$executablePaths = @(',
    [StringComparison]::Ordinal
  )
  $chmodInvocation = $InstallerText.IndexOf(
    "& `$chmodCommand.Source 'a+x' '--' @executablePaths",
    [StringComparison]::Ordinal
  )
  $executeVerification = $InstallerText.IndexOf(
    'foreach ($path in $executablePaths)',
    [StringComparison]::Ordinal
  )
  $dataModeVerification = $InstallerText.IndexOf(
    'foreach ($path in $dataPaths)',
    [StringComparison]::Ordinal
  )
  $identityBinScopeIndex = $InstallerText.IndexOf(
    '$identityBinPath = [IO.Path]::GetFullPath((Join-Path $stagingPath ''bin''))',
    [StringComparison]::Ordinal
  )
  $identityPathValidationIndex = $InstallerText.IndexOf(
    '$binaryParent = [IO.Path]::GetDirectoryName(',
    [StringComparison]::Ordinal
  )
  $identityPathCapture = $InstallerText.IndexOf(
    '$previousPath = [string]$env:PATH',
    [StringComparison]::Ordinal
  )
  $identityPathExposure = $InstallerText.IndexOf(
    '$env:PATH = if ([string]::IsNullOrEmpty($previousPath))',
    [StringComparison]::Ordinal
  )
  $binaryIdentityCheck = $InstallerText.IndexOf(
    'foreach ($name in $BinaryIdentities.Keys)',
    [StringComparison]::Ordinal
  )
  $identityPathRestoration = $InstallerText.IndexOf(
    '$env:PATH = $previousPath',
    [StringComparison]::Ordinal
  )
  $coreStagingAbsence = $InstallerText.IndexOf(
    'if (Test-Path -LiteralPath $coreStagingPath)',
    [StringComparison]::Ordinal
  )
  $coreStagingPreparation = $InstallerText.IndexOf(
    '[void](New-Item -ItemType Directory -Path $coreStagingPath)',
    [StringComparison]::Ordinal
  )
  $coreExtraction = $InstallerText.IndexOf(
    '-ArchivePath $corePath',
    [StringComparison]::Ordinal
  )
  $coreArchiveRootPolicy = $InstallerText.IndexOf(
    "-ExpectedRoot './core/'",
    [StringComparison]::Ordinal
  )
  $coreArchiveMarkerPolicy = $InstallerText.IndexOf(
    "-RequiredMember './core/moon.mod'",
    [StringComparison]::Ordinal
  )
  $coreArchiveLegacyPolicy = $InstallerText.IndexOf(
    "-ForbiddenMembers @('./core/moon.mod.json')",
    [StringComparison]::Ordinal
  )
  $coreRootVerification = $InstallerText.IndexOf(
    '$coreRoots = @(Get-ChildItem -LiteralPath $coreStagingPath -Force)',
    [StringComparison]::Ordinal
  )
  $coreMarkerVerification = $InstallerText.IndexOf(
    "`$coreMarker = Join-Path `$coreStagingPath 'core/moon.mod'",
    [StringComparison]::Ordinal
  )
  $legacyCoreRejection = $InstallerText.IndexOf(
    "`$legacyCoreMarker = Join-Path `$coreStagingPath 'core/moon.mod.json'",
    [StringComparison]::Ordinal
  )
  $coreDestinationAbsence = $InstallerText.IndexOf(
    'if (Test-Path -LiteralPath $installedCorePath)',
    [StringComparison]::Ordinal
  )
  $coreMove = $InstallerText.IndexOf(
    '-LiteralPath $coreRoots[0].FullName',
    [StringComparison]::Ordinal
  )
  $installedCoreVerification = $InstallerText.IndexOf(
    "`$installedCoreMarker = Join-Path `$installedCorePath 'moon.mod'",
    [StringComparison]::Ordinal
  )
  $finalInstall = $InstallerText.IndexOf(
    'Move-Item -LiteralPath $stagingPath -Destination $destination',
    [StringComparison]::Ordinal
  )
  $finalCoreVerification = $InstallerText.IndexOf(
    'P08-TOOLCHAIN-CORE-FINAL: core/moon.mod',
    [StringComparison]::Ordinal
  )
  $bundlePathCapture = $InstallerText.IndexOf(
    '$bundlePreviousPath = [string]$env:PATH',
    [StringComparison]::Ordinal
  )
  $bundlePathScope = $InstallerText.IndexOf(
    '$env:PATH = if ([string]::IsNullOrEmpty($bundlePreviousPath))',
    [StringComparison]::Ordinal
  )
  $bundleAll = $InstallerText.IndexOf(
    '--all',
    [StringComparison]::Ordinal
  )
  $bundleAllExit = $InstallerText.IndexOf(
    'P08-TOOLCHAIN-CORE-BUNDLE: --all failed.',
    [StringComparison]::Ordinal
  )
  $bundleWasmGc = $InstallerText.IndexOf(
    '--target wasm-gc',
    [StringComparison]::Ordinal
  )
  $bundleWasmGcExit = $InstallerText.IndexOf(
    'P08-TOOLCHAIN-CORE-BUNDLE: wasm-gc failed.',
    [StringComparison]::Ordinal
  )
  $bundlePathRestoration = $InstallerText.IndexOf(
    '$env:PATH = $bundlePreviousPath',
    [StringComparison]::Ordinal
  )
  $bundleTargetVerification = $InstallerText.IndexOf(
    '$bundleTargets = @(',
    [StringComparison]::Ordinal
  )
  $bundleLeafVerification = $InstallerText.IndexOf(
    '$bundleLeaves = @(',
    [StringComparison]::Ordinal
  )
  $bundleOutputVerificationIndex = $InstallerText.IndexOf(
    'foreach ($target in $bundleTargets)',
    [StringComparison]::Ordinal
  )
  $pathExport = $InstallerText.IndexOf(
    '-LiteralPath $env:GITHUB_PATH',
    [StringComparison]::Ordinal
  )
  Assert-Condition (
    $toolchainArchiveCheck -ge 0 -and
    $coreArchiveCheck -gt $toolchainArchiveCheck -and
    $toolchainExtraction -gt $coreArchiveCheck -and
    $binManifestVerification -gt $toolchainExtraction -and
    $binaryDigestCheck -gt $binManifestVerification -and
    $chmodScopeIndex -gt $binaryDigestCheck -and
    $chmodInvocation -gt $chmodScopeIndex -and
    $executeVerification -gt $chmodInvocation -and
    $dataModeVerification -gt $executeVerification -and
    $identityBinScopeIndex -gt $dataModeVerification -and
    $identityPathValidationIndex -gt $identityBinScopeIndex -and
    $identityPathCapture -gt $identityPathValidationIndex -and
    $identityPathExposure -gt $identityPathCapture -and
    $binaryIdentityCheck -gt $identityPathExposure -and
    $identityPathRestoration -gt $binaryIdentityCheck -and
    $coreStagingAbsence -gt $identityPathRestoration -and
    $coreStagingPreparation -gt $coreStagingAbsence -and
    $coreExtraction -gt $coreStagingPreparation -and
    $coreArchiveRootPolicy -gt $coreExtraction -and
    $coreArchiveMarkerPolicy -gt $coreArchiveRootPolicy -and
    $coreArchiveLegacyPolicy -gt $coreArchiveMarkerPolicy -and
    $coreRootVerification -gt $coreArchiveLegacyPolicy -and
    $coreMarkerVerification -gt $coreRootVerification -and
    $legacyCoreRejection -gt $coreMarkerVerification -and
    $coreDestinationAbsence -gt $legacyCoreRejection -and
    $coreMove -gt $coreDestinationAbsence -and
    $installedCoreVerification -gt $coreMove -and
    $finalInstall -gt $installedCoreVerification -and
    $finalCoreVerification -gt $finalInstall -and
    $bundlePathCapture -gt $finalCoreVerification -and
    $bundlePathScope -gt $bundlePathCapture -and
    $bundleAll -gt $bundlePathScope -and
    $bundleAllExit -gt $bundleAll -and
    $bundleWasmGc -gt $bundleAllExit -and
    $bundleWasmGcExit -gt $bundleWasmGc -and
    $bundlePathRestoration -gt $bundleWasmGcExit -and
    $bundleTargetVerification -gt $bundlePathRestoration -and
    $bundleLeafVerification -gt $bundleTargetVerification -and
    $bundleOutputVerificationIndex -gt $bundleLeafVerification -and
    $pathExport -gt $bundleOutputVerificationIndex
  ) (
    'Pinned MoonBit installer must authenticate both archives before ' +
    'extraction, verify the exact bin tree, hash binaries before scoped ' +
    'chmod, verify executable and data mode bits, ' +
    'expose only authenticated staging/bin for identity checks, restore ' +
    'PATH, bundle core last, validate it in isolation before promotion, ' +
    'install it, reproduce the pinned bundle commands with scoped PATH, ' +
    'verify four-target outputs, and only then export the toolchain path.'
  )
}

function Assert-FontQualificationArtifacts {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][object]$Policy,
    [Parameter(Mandatory)][string]$RepositoryRoot
  )

  $fontModule = @($Policy.modules | Where-Object { $_.name -ceq 'tchivs/mb-font' })[0]
  $font = @($fontModule.public_packages | Where-Object { $_.path -ceq 'font' })[0]
  $productionSources = @('moon.pkg', 'cmap.mbt', 'collection.mbt', 'collection_limits.mbt', 'collection_parser.mbt', 'cursor.mbt', 'directory.mbt', 'font.mbt', 'kern.mbt', 'limits.mbt', 'metrics.mbt', 'outline.mbt', 'tables.mbt')
  $testSources = @(
    'collection_test.mbt',
    'collection_wbtest.mbt',
    'font_test.mbt',
    'font_wbtest.mbt',
    'generated_fonts_wbtest.mbt',
    'generated_font_qualification_test.mbt',
    'font_qualification_test.mbt',
    'font_qualification_hostile_test.mbt'
  )
  $publicationFiles = @(
    'CHANGELOG.md',
    'README.mbt.md',
    'font',
    'font/cmap.mbt',
    'font/collection.mbt',
      'font/collection_limits.mbt',
      'font/collection_parser.mbt',
      'font/collection_test.mbt',
      'font/collection_wbtest.mbt',
      'font/cursor.mbt',
    'font/directory.mbt',
    'font/font.mbt',
    'font/font_qualification_hostile_test.mbt',
    'font/font_qualification_test.mbt',
    'font/font_test.mbt',
    'font/font_wbtest.mbt',
    'font/generated_font_qualification_test.mbt',
    'font/generated_fonts_wbtest.mbt',
    'font/kern.mbt',
    'font/limits.mbt',
    'font/metrics.mbt',
    'font/moon.pkg',
    'font/outline.mbt',
    'font/tables.mbt',
    'moon.mod.json'
  )
  Assert-ExactSequence 'Font qualification production source order' @($font.production_sources) $productionSources
  Assert-ExactSequence 'Font qualification test source order' @($font.test_sources) $testSources
  Assert-ExactSet 'Font qualification publication inventory' @($fontModule.publication_files) $publicationFiles
  Assert-Condition (@($font.semantic_interface).Count -eq 85) 'Font semantic interface must remain exactly 85 lines.'
  Assert-FontPhase102Surface -InterfaceLines @($font.semantic_interface | ForEach-Object { [string]$_ })
  Assert-ExactSet 'Font qualification module dependencies' @($fontModule.direct_dependencies) @('tchivs/mb-core')
  Assert-ExactSet 'Font qualification dependency edge' @($Policy.allowed_dependency_edges | Where-Object from -CEQ 'tchivs/mb-font' | ForEach-Object to) @('tchivs/mb-core')
  Assert-Condition (@($Policy.allowed_dependency_edges | Where-Object to -CEQ 'tchivs/mb-font').Count -eq 0) 'No foundation module may depend on mb-font during qualification.'

  $workflowDirectory = Join-Path $RepositoryRoot '.github/workflows'
  $qualityWorkflowText = Get-Content -Raw -LiteralPath (
    Join-Path $workflowDirectory 'quality.yml'
  )
  $allWorkflowText = @(
    Get-ChildItem -LiteralPath $workflowDirectory -File |
      Where-Object { $_.Extension -in @('.yml', '.yaml') } |
      Sort-Object Name |
      ForEach-Object { Get-Content -Raw -LiteralPath $_.FullName }
  ) -join "`n"
  $installerText = Get-Content -Raw -LiteralPath (
    Join-Path $RepositoryRoot 'scripts/ci/Install-PinnedMoonBit.ps1'
  )
  Assert-QualityWorkflowToolchainTransport `
    -QualityWorkflowText $qualityWorkflowText `
    -AllWorkflowText $allWorkflowText `
    -InstallerText $installerText
  Assert-FontQualificationWorkflowContract -WorkflowText $qualityWorkflowText
  Confirm-FontQualificationRejected 'v1 CI evidence directory' {
    Assert-FontQualificationWorkflowContract -WorkflowText (
      $qualityWorkflowText.Replace('ci-font-v2', 'ci-font')
    )
  } 'fresh v2 evidence directory'
  Confirm-FontQualificationRejected 'failing evidence upload' {
    Assert-FontQualificationWorkflowContract -WorkflowText (
      $qualityWorkflowText.Replace('${{ success() }}', '${{ always() }}')
    )
  } 'success-only'
  Confirm-FontQualificationRejected 'unpinned evidence upload' {
    Assert-FontQualificationWorkflowContract -WorkflowText (
      $qualityWorkflowText.Replace(
        'actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02',
        'actions/upload-artifact@v4'
      )
    )
  } 'success-only, pinned, and v2-owned'
  Confirm-FontQualificationRejected 'unmeasured timeout increase' {
    Assert-FontQualificationWorkflowContract -WorkflowText (
      $qualityWorkflowText.Replace('timeout-minutes: 20', 'timeout-minutes: 21')
    )
  } 'timeout must remain 20 minutes'
  Confirm-FontQualificationRejected 'second failing-evidence upload' {
    Assert-FontQualificationWorkflowContract -WorkflowText (
      $qualityWorkflowText.Replace(
        "`n  required:",
        @"
      - name: Upload failing font qualification evidence
        if: `${{ always() }}
        uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02
        with:
          name: font-qualification-evidence-v2-failure
          path: artifacts/release-qualification/ci-font-v2

  required:
"@
      )
    )
  } 'success-only, pinned, and v2-owned'
  Confirm-FontQualificationRejected 'aliased evidence path' {
    Assert-FontQualificationWorkflowContract -WorkflowText (
      $qualityWorkflowText.Replace(
        'path: artifacts/release-qualification/ci-font-v2',
        'path: *font-qualification-evidence'
      )
    )
  } 'forbids tabs and YAML aliases'
  Confirm-FontQualificationRejected 'FontQualification continue-on-error' {
    Assert-FontQualificationWorkflowContract -WorkflowText (
      $qualityWorkflowText.Replace(
        '    timeout-minutes: 20',
        "    timeout-minutes: 20`n    continue-on-error: true"
      )
    )
  } 'must not continue on error'
  Confirm-FontQualificationRejected 'shadow FontQualification job' {
    Assert-FontQualificationWorkflowContract -WorkflowText (
      $qualityWorkflowText + @"

  font-qualification-shadow:
    runs-on: ubuntu-latest
    steps:
      - name: Shadow qualification
        run: ./scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/ci-font-v2
"@
    )
  } 'exactly one FontQualification job'

  $runnerText = Get-Content -Raw -LiteralPath (
    Join-Path $RepositoryRoot 'scripts/quality/Invoke-FontQualification.ps1'
  )
  foreach ($runnerFact in @(
      'mnf-font-qualification-evidence/v2',
      'font-complete-public-v2',
      'artifacts/release-qualification/font-v2',
      'target/phase103-font-qualification-',
      'normalization_removed = @(''target'', ''runner'')'
    )) {
    Assert-Condition (
      $runnerText.Contains($runnerFact, [StringComparison]::Ordinal)
    ) "FontQualification runner fact drifted: $runnerFact"
  }

  $manifestPath = Join-Path $RepositoryRoot 'fixtures/manifest.json'
  Assert-FontQualificationFixtureManifest -ManifestPath $manifestPath -RepositoryRoot $RepositoryRoot

  $oracle = Read-QualityJson -Path (Join-Path $RepositoryRoot 'fixtures/font/dejavu-sans-2.37/oracle.json')
  Assert-ExactSequence 'Font oracle top-level schema' @($oracle.PSObject.Properties.Name) @('schema_version','oracle','source','tables','profile','metrics','cmap','glyphs','kern','maxp')
  Assert-Condition ($oracle.schema_version -ceq '1.1.0' -and $oracle.oracle.implementation -ceq 'mnf-powershell-closed-sfnt-reader' -and $oracle.oracle.version -ceq '1.1.0' -and $oracle.oracle.independence -ceq 'offline parser; does not invoke tchivs/mb-font') 'Font oracle identity or independence contract drifted.'
  Assert-ExactSequence 'Font oracle identity schema' @($oracle.oracle.PSObject.Properties.Name) @('implementation','version','independence')
  Assert-ExactSequence 'Font oracle source schema' @($oracle.source.PSObject.Properties.Name) @('path','length','sha256','sfnt_signature')
  Assert-ExactSequence 'Font oracle table schema' @($oracle.tables[0].PSObject.Properties.Name) @('tag','checksum','offset','length')
  Assert-ExactSequence 'Font oracle profile schema' @($oracle.profile.PSObject.Properties.Name) @('units_per_em','loca_format','glyph_count')
  Assert-ExactSequence 'Font oracle metrics schema' @($oracle.metrics.PSObject.Properties.Name) @('global_bounds','hhea','os2_typographic')
  Assert-ExactSequence 'Font oracle cmap schema' @($oracle.cmap.PSObject.Properties.Name) @('records','selected_record')
  Assert-ExactSequence 'Font oracle cmap record schema' @($oracle.cmap.records[0].PSObject.Properties.Name) @('platform_id','encoding_id','format','offset')
  Assert-ExactSequence 'Font oracle glyph schema' @($oracle.glyphs[0].PSObject.Properties.Name) @('scalar','glyph_id','horizontal_metrics','classification','contours','bounds','components','path')
  Assert-ExactSequence 'Font oracle path schema' @($oracle.glyphs[0].path.PSObject.Properties.Name) @('command_count','fingerprint_sha256','commands')
  $supportedOracleGlyphs = @(
    [ordered]@{ scalar = 'U+0041'; glyph_id = 36; command_count = 13 },
    [ordered]@{ scalar = 'U+034C'; glyph_id = 765; command_count = 48 },
    [ordered]@{ scalar = 'U+10300'; glyph_id = 5373; command_count = 13 }
  )
  foreach ($expectedGlyph in $supportedOracleGlyphs) {
    $matches = @($oracle.glyphs | Where-Object { $_.scalar -ceq $expectedGlyph.scalar })
    Assert-Condition ($matches.Count -eq 1) "Font oracle supported glyph $($expectedGlyph.scalar) is missing or duplicated."
    $glyph = $matches[0]
    Assert-Condition (
      [int]$glyph.glyph_id -eq [int]$expectedGlyph.glyph_id -and
      [int]$glyph.path.command_count -eq [int]$expectedGlyph.command_count -and
      @($glyph.path.commands).Count -eq [int]$expectedGlyph.command_count -and
      -not [string]::IsNullOrWhiteSpace([string]$glyph.path.fingerprint_sha256)
    ) "Font oracle supported glyph $($expectedGlyph.scalar) complete path drifted."
  }
  foreach ($glyph in @($oracle.glyphs)) {
    Assert-Condition ([int]$glyph.path.command_count -eq @($glyph.path.commands).Count) "Font oracle glyph $($glyph.scalar) command count/vector drifted."
  }
  Assert-ExactSequence 'Font oracle kern schema' @($oracle.kern.PSObject.Properties.Name) @('version','subtable_count','format','horizontal','pair_count','selected_pair')
  Assert-ExactSequence 'Font oracle maxp schema' @($oracle.maxp.PSObject.Properties.Name) @('max_points','max_contours','max_composite_points','max_composite_contours','max_instruction_bytes','max_component_elements','max_component_depth')

  $cases = Read-QualityJson -Path (Join-Path $RepositoryRoot 'fixtures/font/qualification-cases.json')
  Assert-ExactSequence 'Font hostile document schema' @($cases.PSObject.Properties.Name) @('schema_version','license','cases')
  Assert-Condition ($cases.schema_version -ceq '1.0.0' -and $cases.license -ceq 'Apache-2.0') 'Font hostile document identity or license drifted.'
  Assert-ExactSequence 'Font hostile case schema' @($cases.cases[0].PSObject.Properties.Name) @('id','stage','category','code','context','requested','limit','publication')
  Assert-ExactSequence 'Font hostile case IDs' @($cases.cases.id) @(
    'malformed-directory-range',
    'unsupported-outline-profile',
    'mutation-after-open',
    'checked-range-overflow',
    'limit-source-exact',
    'limit-source-one-short',
    'budget-open-exact',
    'budget-open-one-short',
    'budget-outline-exact',
    'budget-outline-one-short',
    'nested-composite-recognized'
  )

  $collectionCases = Read-QualityJson -Path (
    Join-Path $RepositoryRoot 'fixtures/font/collection-qualification-cases.json'
  )
  Assert-FontCollectionCorpusContract -Corpus $collectionCases
  Confirm-FontQualificationRejected 'collection corpus schema drift' {
    $copy = $collectionCases | ConvertTo-Json -Depth 32 -Compress |
      ConvertFrom-Json
    $copy.schema_version = '2.0.0'
    Assert-FontCollectionCorpusContract -Corpus $copy
  } 'identity or license drifted'
  Confirm-FontQualificationRejected 'collection corpus reordered IDs' {
    $copy = $collectionCases | ConvertTo-Json -Depth 32 -Compress |
      ConvertFrom-Json
    $first = $copy.public_workflows[0]
    $copy.public_workflows[0] = $copy.public_workflows[1]
    $copy.public_workflows[1] = $first
    Assert-FontCollectionCorpusContract -Corpus $copy
  } 'ordered IDs drifted'
  Confirm-FontQualificationRejected 'collection corpus case key drift' {
    $copy = $collectionCases | ConvertTo-Json -Depth 32 -Compress |
      ConvertFrom-Json
    $copy.hostile_cases[0].error |
      Add-Member -NotePropertyName unexpected -NotePropertyValue $true
    Assert-FontCollectionCorpusContract -Corpus $copy
  } 'schema count mismatch'
  Confirm-FontQualificationRejected 'second collection fixture key drift' {
    $copy = $collectionCases | ConvertTo-Json -Depth 32 -Compress |
      ConvertFrom-Json
    $copy.fixtures[1].PSObject.Properties.Remove('expected_use')
    Assert-FontCollectionCorpusContract -Corpus $copy
  } 'schema count mismatch'
  Confirm-FontQualificationRejected 'collection hostile context drift' {
    $copy = $collectionCases | ConvertTo-Json -Depth 32 -Compress |
      ConvertFrom-Json
    $copy.hostile_cases[0].error.context = 'drift'
    Assert-FontCollectionCorpusContract -Corpus $copy
  } 'exact semantic digest drifted'
  Confirm-FontQualificationRejected 'collection failed budget drift' {
    $copy = $collectionCases | ConvertTo-Json -Depth 32 -Compress |
      ConvertFrom-Json
    $copy.hostile_cases[0].budget_after.work++
    Assert-FontCollectionCorpusContract -Corpus $copy
  } 'failed budget atomicity drifted'

  $collectionOracle = Read-QualityJson -Path (
    Join-Path $RepositoryRoot (
      'fixtures/font/dejavu-sans-2.37/collection-oracle.json'
    )
  )
  Assert-FontCollectionOracleContract -Oracle $collectionOracle
  Confirm-FontQualificationRejected 'licensed derivative digest drift' {
    $copy = $collectionOracle | ConvertTo-Json -Depth 32 -Compress |
      ConvertFrom-Json
    $copy.derivative.sha256 = '00'
    Assert-FontCollectionOracleContract -Oracle $copy
  } 'licensed derivative identity drifted'
  Confirm-FontQualificationRejected 'licensed derivative notice drift' {
    $copy = $collectionOracle | ConvertTo-Json -Depth 32 -Compress |
      ConvertFrom-Json
    $copy.lineage.notice_path = ''
    Assert-FontCollectionOracleContract -Oracle $copy
  } 'notice or redistribution facts drifted'
  Confirm-FontQualificationRejected 'licensed sharing coordinate drift' {
    $copy = $collectionOracle | ConvertTo-Json -Depth 32 -Compress |
      ConvertFrom-Json
    $copy.collection.payload_start = 685
    Assert-FontCollectionOracleContract -Oracle $copy
  } 'structure or exact sharing drifted'

  $generatedPath = Join-Path $RepositoryRoot 'modules/mb-font/font/generated_font_qualification_test.mbt'
  $generatedHeader = @((Get-Content -LiteralPath $generatedPath -TotalCount 5))
  Assert-ExactSequence 'Generated font qualification provenance header' $generatedHeader @(
    '// Generated by scripts/fixtures/Generate-FontQualification.ps1. Do not edit.',
    '// Canonical source: fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf',
    '// SHA-256: 7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954',
    '// Upstream license: Bitstream-Vera AND LicenseRef-DejaVu-Arev',
    '// Literal chunk size: 4096 bytes'
  )
  $generatedSource = Get-Content -Raw -LiteralPath $generatedPath
  foreach ($symbol in @(
      'struct FontQualificationExpectedCommand',
      'struct FontQualificationOutlineExpectation',
      'fn font_qualification_dejavu_supported_outlines',
      'struct FontCollectionQualificationBudgetSnapshot',
      'struct FontCollectionQualificationError',
      'struct FontCollectionQualificationCase',
      'fn font_qualification_dejavu_two_face_ttc_v1_bytes',
      'fn font_collection_qualification_cases'
    )) {
    Assert-Condition ($generatedSource.Contains($symbol, [StringComparison]::Ordinal)) "Generated font qualification expectation symbol missing: $symbol"
  }

  $sourcePaths = @(
    @($productionSources | Where-Object { $_ -cne 'moon.pkg' })
    $testSources
  ) | ForEach-Object { Join-Path $RepositoryRoot "modules/mb-font/font/$_" }
  $semanticSourcePaths = @(
    $productionSources |
      Where-Object { $_ -cne 'moon.pkg' } |
      ForEach-Object { Join-Path $RepositoryRoot "modules/mb-font/font/$_" }
  )
  Assert-Condition (
    [string]$font.portable_source_semantic_sha256 -cmatch '^[0-9a-f]{64}$' -and
    [string]$font.capability_negative_contract_sha256 -cmatch '^[0-9a-f]{64}$'
  ) 'Font portable semantic and capability-negative locks are missing.'
  Assert-FontPortableSourceBoundary `
    -SourcePaths $sourcePaths `
    -SemanticSourcePaths $semanticSourcePaths `
    -ExpectedSemanticSha256 ([string]$font.portable_source_semantic_sha256)

  Confirm-FontQualificationRejected 'extra public interface line' {
    Assert-FontPhase102Surface -InterfaceLines @(@($font.semantic_interface) + 'pub fn Font::rasterize(Self) -> Unit')
  } 'private or deferred Phase 103[+] capability'
  Confirm-FontQualificationRejected 'extra dependency' {
    Assert-ExactSet 'Negative font dependency set' @($fontModule.direct_dependencies + 'tchivs/mb-image') @('tchivs/mb-core')
  } 'count mismatch'
  $negativeSource = Join-Path ([IO.Path]::GetTempPath()) ('mnf-font-boundary-' + [guid]::NewGuid().ToString('N') + '.mbt')
  try {
    $capabilityNegativeContract = Get-FontPortableCapabilityNegativeContract
    $negativeContractJson = $capabilityNegativeContract |
      ConvertTo-Json -Depth 8 -Compress
    $negativeContractDigest = [Convert]::ToHexString(
      [Security.Cryptography.SHA256]::HashData(
        [Text.UTF8Encoding]::new($false).GetBytes($negativeContractJson)
      )
    ).ToLowerInvariant()
    Assert-Condition (
      $negativeContractDigest -ceq
        [string]$font.capability_negative_contract_sha256
    ) 'Font capability-negative behavioral contract digest drifted.'
    foreach ($probe in $capabilityNegativeContract) {
      [IO.File]::WriteAllText(
        $negativeSource,
        ([string]$probe.Source),
        [Text.UTF8Encoding]::new($false)
      )
      Confirm-FontQualificationRejected "immutable $($probe.Name) capability negative" {
        Assert-FontPortableSourceBoundary -SourcePaths @($negativeSource)
      } ([string]$probe.Pattern)
    }

    $portableBoundaryProbes = @(
      [pscustomobject]@{ Name = 'FFI'; Call = 'foreign_call()'; Pattern = 'forbidden FFI or native stub' },
      [pscustomobject]@{ Name = 'filesystem'; Call = 'open_file()'; Pattern = 'forbidden filesystem or host-font discovery' },
      [pscustomobject]@{ Name = 'GUI'; Call = 'canvas_draw()'; Pattern = 'forbidden GUI canvas image or color dependency' },
      [pscustomobject]@{ Name = 'shaping'; Call = 'shape_text()'; Pattern = 'forbidden shaping execution' },
      [pscustomobject]@{ Name = 'hinting'; Call = 'hint_outline()'; Pattern = 'forbidden hinting execution' },
      [pscustomobject]@{ Name = 'CFF'; Call = 'cff_decode()'; Pattern = 'forbidden CFF or CFF2 execution' },
      [pscustomobject]@{ Name = 'WOFF'; Call = 'decode_woff2()'; Pattern = 'forbidden WOFF or WOFF2 admission' },
      [pscustomobject]@{ Name = 'variable font'; Call = 'instantiate_variable_font()'; Pattern = 'forbidden variable-font execution' },
      [pscustomobject]@{ Name = 'rasterization'; Call = 'rasterize_font()'; Pattern = 'forbidden rasterization execution' }
    )
    foreach ($probe in $portableBoundaryProbes) {
      $probeSource = @"
fn forbidden_probe() {
  let opening = "/*"
  $($probe.Call)
  let closing = "*/"
}
"@
      [IO.File]::WriteAllText($negativeSource, $probeSource, [Text.UTF8Encoding]::new($false))
      Confirm-FontQualificationRejected "comment delimiters in strings cannot hide $($probe.Name)" {
        Assert-FontPortableSourceBoundary -SourcePaths @($negativeSource)
      } $probe.Pattern

      $probeSource = 'fn forbidden_probe() { let hidden = "\{' + $probe.Call + '}" }'
      [IO.File]::WriteAllText($negativeSource, $probeSource, [Text.UTF8Encoding]::new($false))
      Confirm-FontQualificationRejected "string interpolation cannot hide $($probe.Name)" {
        Assert-FontPortableSourceBoundary -SourcePaths @($negativeSource)
      } $probe.Pattern

      $probeSource = 'fn forbidden_probe() { let hidden = b"\{' + $probe.Call + '}" }'
      [IO.File]::WriteAllText($negativeSource, $probeSource, [Text.UTF8Encoding]::new($false))
      Confirm-FontQualificationRejected "bytes interpolation cannot hide $($probe.Name)" {
        Assert-FontPortableSourceBoundary -SourcePaths @($negativeSource)
      } $probe.Pattern
    }
    [IO.File]::WriteAllText(
      $negativeSource,
      "fn forbidden_probe() {`n  let hidden = (`n    `$| \{rasterize_font()}`n  )`n}`n",
      [Text.UTF8Encoding]::new($false)
    )
    Confirm-FontQualificationRejected 'interpolated multiline string cannot hide rasterization' {
      Assert-FontPortableSourceBoundary -SourcePaths @($negativeSource)
    } 'forbidden rasterization execution'

    [IO.File]::WriteAllText(
      $negativeSource,
      'fn forbidden_probe() { let hidden = "\{if true { rasterize_font() } else { 0 }}" }',
      [Text.UTF8Encoding]::new($false)
    )
    Confirm-FontQualificationRejected 'nested expression braces retain executable interpolation' {
      Assert-FontPortableSourceBoundary -SourcePaths @($negativeSource)
    } 'forbidden rasterization execution'

    [IO.File]::WriteAllText(
      $negativeSource,
      'fn forbidden_probe() { let hidden = "\{/* } */ rasterize_font()}" }',
      [Text.UTF8Encoding]::new($false)
    )
    Confirm-FontQualificationRejected 'comment braces cannot close executable interpolation' {
      Assert-FontPortableSourceBoundary -SourcePaths @($negativeSource)
    } 'forbidden rasterization execution'

    [IO.File]::WriteAllText(
      $negativeSource,
      'fn forbidden_probe() { let marker = "//"; rasterize_font() }',
      [Text.UTF8Encoding]::new($false)
    )
    Confirm-FontQualificationRejected 'line-comment delimiter in a string cannot hide executable source' {
      Assert-FontPortableSourceBoundary -SourcePaths @($negativeSource)
    } 'forbidden rasterization execution'

    [IO.File]::WriteAllText(
      $negativeSource,
      (
        "/* quote-like text `" b'c' // remains comment text */`n" +
        "fn allowed_probe() { let marker = `"/* not a comment */`"; let escaped = `"\\{rasterize_font()}`"; let escaped_bytes = b`"\\{open_file()}`" }`n" +
        "fn allowed_multiline_probe() {`n  let raw = (`n    #| \{rasterize_font()} open_file()`n  )`n}`n"
      ),
      [Text.UTF8Encoding]::new($false)
    )
    Assert-FontPortableSourceBoundary -SourcePaths @($negativeSource)
  } finally {
    if (Test-Path -LiteralPath $negativeSource) { Remove-Item -LiteralPath $negativeSource -Force }
  }

  Write-Host 'Font qualification fixtures, schemas, inventories, dependencies, interface, and portable source boundary verified.'
}

function Assert-FontFoundationPolicy {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$PolicyPath)

  $policy = Read-QualityJson -Path $PolicyPath
  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  $fontModules = @($policy.modules | Where-Object { $_.name -ceq 'tchivs/mb-font' })
  Assert-ExactSet 'Font module selection' @($fontModules.name) @('tchivs/mb-font')
  $fontModule = $fontModules[0]
  Assert-Condition ($fontModule.path -ceq 'modules/mb-font') 'Font module path drifted.'
  Assert-Condition ($fontModule.stability -ceq 'candidate') 'Font module stability must remain candidate.'
  Assert-ExactSet 'Font module dependencies' @($fontModule.direct_dependencies) @('tchivs/mb-core')
  Assert-ExactSet 'Font module targets' @($fontModule.supported_targets) @('js', 'wasm', 'wasm-gc', 'native')
  $fontManifest = Read-QualityJson -Path (Join-Path $repoRoot 'modules/mb-font/moon.mod.json')
  Assert-Condition ($fontManifest.description -ceq $fontModule.description) 'Manifest description drift in modules/mb-font.'
  $expectedDescription = (
    'Portable bounded standalone TrueType and TTC/OTC version 1/version 2 ' +
    'inspection with selected static-glyf admission, named metrics, ' +
    'deterministic Unicode mapping, legacy kerning, and transactional Path2 ' +
    'outlines for MoonBit Native Foundation.'
  )
  Assert-Condition (
    $fontModule.description -ceq $expectedDescription -and
    $fontManifest.description -ceq $expectedDescription
  ) 'Font policy and manifest descriptions must expose the Phase 103 collection contract.'

  $fontEdges = @($policy.allowed_dependency_edges | Where-Object { $_.from -ceq 'tchivs/mb-font' })
  Assert-ExactSet 'Font dependency edges' @($fontEdges.to) @('tchivs/mb-core')
  Assert-Condition (@($policy.allowed_dependency_edges | Where-Object { $_.to -ceq 'tchivs/mb-font' }).Count -eq 0) 'No existing foundation module may depend on mb-font during Phase 102.'
  Assert-AcyclicDependencyGraph -Modules @($policy.modules) -AllowedEdges @($policy.allowed_dependency_edges)

  $publicationFiles = @(
    'CHANGELOG.md',
    'README.mbt.md',
    'font',
    'font/cmap.mbt',
    'font/collection.mbt',
    'font/collection_limits.mbt',
    'font/collection_parser.mbt',
    'font/collection_test.mbt',
    'font/collection_wbtest.mbt',
    'font/cursor.mbt',
    'font/directory.mbt',
    'font/font.mbt',
    'font/font_qualification_hostile_test.mbt',
    'font/font_qualification_test.mbt',
    'font/font_test.mbt',
    'font/font_wbtest.mbt',
    'font/generated_font_qualification_test.mbt',
    'font/generated_fonts_wbtest.mbt',
    'font/kern.mbt',
    'font/limits.mbt',
    'font/metrics.mbt',
    'font/moon.pkg',
    'font/outline.mbt',
    'font/tables.mbt',
    'moon.mod.json'
  )
  Assert-ExactSet 'Font publication inventory' @($fontModule.publication_files) $publicationFiles

  $fontPackages = @($fontModule.public_packages | Where-Object { $_.path -ceq 'font' })
  Assert-ExactSet 'Font public package selection' @($fontPackages.name) @('tchivs/mb-font/font')
  Assert-Condition (@($fontModule.public_packages).Count -eq 1) 'mb-font must publish exactly one public package.'
  $font = $fontPackages[0]
  $imports = @('tchivs/mb-core/budget', 'tchivs/mb-core/bytes', 'tchivs/mb-core/checked', 'tchivs/mb-core/error', 'tchivs/mb-core/math')
  $productionSources = @('moon.pkg', 'cmap.mbt', 'collection.mbt', 'collection_limits.mbt', 'collection_parser.mbt', 'cursor.mbt', 'directory.mbt', 'font.mbt', 'kern.mbt', 'limits.mbt', 'metrics.mbt', 'outline.mbt', 'tables.mbt')
    $testSources = @(
      'collection_test.mbt',
      'collection_wbtest.mbt',
      'font_test.mbt',
    'font_wbtest.mbt',
    'generated_fonts_wbtest.mbt',
    'generated_font_qualification_test.mbt',
    'font_qualification_test.mbt',
    'font_qualification_hostile_test.mbt'
  )
  Assert-ExactSet 'Font policy imports' @($font.allowed_imports) $imports
  Assert-ExactSet 'Font policy targets' @($font.supported_targets) @('js', 'wasm', 'wasm-gc', 'native')
  Assert-ExactSequence 'Font production source order' @($font.production_sources) $productionSources
  Assert-ExactSequence 'Font test source order' @($font.test_sources) $testSources

  $packageText = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'modules/mb-font/font/moon.pkg')
  $target = [regex]::Match($packageText, '(?m)^supported_targets\s*=\s*"([^"]+)"\s*$')
  Assert-Condition $target.Success 'Font moon.pkg lacks supported_targets.'
  Assert-ExactSet 'Font moon.pkg targets' (Get-CompactTargetSet $target.Groups[1].Value 'Font package targets') @('js', 'wasm', 'wasm-gc', 'native')
  Assert-ExactSet 'Font moon.pkg imports' @(Get-PackageImportSet -Text $packageText -Label 'Font moon.pkg') $imports

  $actualFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $repoRoot 'modules/mb-font/font') -File |
      Where-Object { $_.Name -cne 'pkg.generated.mbti' } |
      ForEach-Object Name
  )
  Assert-ExactSet 'Font package directory contents' $actualFiles @($productionSources + $testSources)
  Assert-FontQualificationArtifacts -Policy $policy -RepositoryRoot $repoRoot

  $readmeText = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'modules/mb-font/README.mbt.md')
  Assert-Condition ($readmeText -cmatch '\bcandidate\b') 'Font README must expose candidate stability.'
  foreach ($requiredTarget in @('js', 'wasm', 'wasm-gc', 'native')) {
    Assert-Condition ($readmeText -cmatch [regex]::Escape($requiredTarget)) "Font README must expose target '$requiredTarget'."
  }
  Assert-Condition ($readmeText -cmatch 'tchivs/mb-core' -and $readmeText -match 'only direct module dependency') 'Font README must document mb-core as its only direct dependency.'
  Assert-Condition ($readmeText -cmatch 'Phase 100' -and $readmeText -cmatch 'generated micro-font') 'Font README must preserve the Phase 100 real-font evidence boundary.'
  foreach ($readmeFact in @(
      'TTC/OTC versions 1 and 2',
      '757,428-byte',
      '833d406d389d4ef3b0a38f168af7d51ca16c88605e1727f6d631871a4e05f80b',
      'artifacts/release-qualification/font-v2',
      'exactly four',
      'target',
      'runner',
      'WOFF1/WOFF2',
      'PresentUnverified'
    )) {
    Assert-Condition (
      $readmeText.Contains($readmeFact, [StringComparison]::Ordinal)
    ) "Font README Phase 103 fact drifted: $readmeFact"
  }
  $outlineDataTaxonomy = [regex]::Match($readmeText, '(?ms)^- `Data`.*?(?=^- `Capability`)').Value
  $outlineResourceTaxonomy = [regex]::Match($readmeText, '(?ms)^- `Resource`.*?(?=^- `State`)').Value
  Assert-Condition (
    -not [string]::IsNullOrWhiteSpace($outlineResourceTaxonomy) -and
    $outlineResourceTaxonomy -cmatch 'FontLimits' -and
    $outlineResourceTaxonomy -cmatch 'max_work' -and
    $outlineResourceTaxonomy -cmatch 'Budget' -and
    $outlineResourceTaxonomy -cnotmatch 'maxp'
  ) 'Font README Resource taxonomy must contain only retained FontLimits, max_work, and caller Budget exhaustion.'
  Assert-Condition (
    -not [string]::IsNullOrWhiteSpace($outlineDataTaxonomy) -and
    $outlineDataTaxonomy -cmatch 'maxp' -and
    $outlineDataTaxonomy -cmatch '(underclaim|exceed)'
  ) 'Font README Data taxonomy does not classify maxp underclaims.'

  $changelogText = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'modules/mb-font/CHANGELOG.md')
  Assert-Condition ($changelogText -cmatch 'independent release lifecycle') 'Font changelog must declare an independent release lifecycle.'
  Assert-Condition ($changelogText -cmatch '0[.]1[.]0 candidate [(]unpublished[)]') 'Font changelog must record the unpublished 0.1.0 candidate.'
  Assert-Condition (
    $changelogText -cmatch 'TTC/OTC' -and
    $changelogText -cmatch '833d406d389d4ef3b0a38f168af7d51ca16c88605e1727f6d631871a4e05f80b' -and
    $changelogText -cmatch 'font-complete-public-v2'
  ) 'Font changelog must record the Phase 103 collection and evidence contract.'

  $licensePolicyText = Get-Content -Raw -LiteralPath (
    Join-Path $repoRoot 'docs/policies/licensing-and-fixtures.md'
  )
  Assert-Condition (
    $licensePolicyText -cmatch 'external derivative' -and
    $licensePolicyText -cmatch 'parent' -and
    $licensePolicyText -cmatch 'generator' -and
    $licensePolicyText -cmatch 'notice' -and
    $licensePolicyText -cmatch 'redistribution_status'
  ) 'Fixture policy must define the external derivative provenance rule.'

  $interfaceText = @($font.semantic_interface | ForEach-Object { [string]$_ })
  $privateLeakPattern = '(?i)(Cursor|TableWindow|TableRecord|DirectoryFacts|RequiredTableFacts|MetricIndexFacts|Collection(?:Face|Protected|Parse|Directory|Record|Range|Storage)Facts|Dsig(?:Record|Block|Payload)|CmapLookupFacts|CmapFormat4Facts|CmapFormat12Facts|KernState|KernFormat0Facts|SfntTag|RawOffset|WindowDescriptor|source_offset|retained_revision|mutation_revision|GlyphWindow|OutlinePoint|OutlineGeometry|F2Dot14|Composite(?:Placement|Descriptor|Parse|Frame|Classification)|OutlineWork|GraphColor|RealPoint|ImpliedPoint|PhantomPoint|Q15)'
  Assert-Condition (@($interfaceText | Where-Object { $_ -cmatch $privateLeakPattern }).Count -eq 0) 'Font semantic interface leaks a private collection, cmap, kern, outline, cursor, table, graph, Q15, tag, offset, range, revision, or window fact.'
  Assert-FontPhase102Surface -InterfaceLines $interfaceText
  $missingApprovedMethod = @(
    $interfaceText |
      Where-Object {
        $_ -cne 'pub fn FontCollection::open_face(Self, UInt64, FontLimits, @budget.Budget) -> Result[Font, @error.CoreError]'
      }
  )
  $negativeFailure = $null
  try {
    Assert-FontPhase102Surface -InterfaceLines $missingApprovedMethod
  } catch {
    $negativeFailure = $_.Exception.Message
  }
  Assert-Condition (
    $null -ne $negativeFailure -and
    $negativeFailure -cmatch 'count mismatch'
  ) 'Font Phase 102 exact selector accepted a removed approved method.'

  $duplicatedApprovedLine = @(
    $interfaceText +
      'pub fn FontCollection::open_face(Self, UInt64, FontLimits, @budget.Budget) -> Result[Font, @error.CoreError]'
  )
  $negativeFailure = $null
  try {
    Assert-FontPhase102Surface -InterfaceLines $duplicatedApprovedLine
  } catch {
    $negativeFailure = $_.Exception.Message
  }
  Assert-Condition (
    $null -ne $negativeFailure -and
    $negativeFailure -cmatch 'count mismatch'
  ) 'Font Phase 102 exact selector accepted a duplicated approved line.'

  $reorderedApprovedLines = @($interfaceText)
  $reorderedTemporary = $reorderedApprovedLines[0]
  $reorderedApprovedLines[0] = $reorderedApprovedLines[1]
  $reorderedApprovedLines[1] = $reorderedTemporary
  $negativeFailure = $null
  try {
    Assert-FontPhase102Surface -InterfaceLines $reorderedApprovedLines
  } catch {
    $negativeFailure = $_.Exception.Message
  }
  Assert-Condition (
    $null -ne $negativeFailure -and
    $negativeFailure -cmatch 'order mismatch'
  ) 'Font Phase 102 exact selector accepted reordered approved declarations.'

  $forbiddenConstructor = @(
    $interfaceText | ForEach-Object {
      if ($_ -cmatch '^pub fn FontLimits::new') {
        $_.Replace('max_work~ : UInt64)', 'max_work~ : UInt64, outline~ : Bool)')
      } else {
        $_
      }
    }
  )
  $negativeFailure = $null
  try {
    Assert-FontPhase102Surface -InterfaceLines $forbiddenConstructor
  } catch {
    $negativeFailure = $_.Exception.Message
  }
  Assert-Condition ($null -ne $negativeFailure -and $negativeFailure -cmatch 'private or deferred Phase 103[+] capability') 'Font Phase 102 selector accepted a forbidden constructor parameter.'
  foreach ($forbiddenLine in @(
    'pub fn Font::cmap_lookup(Self, UInt64) -> UInt64',
    'pub fn FontCollection::raw_record(Self, UInt64, UInt64) -> CollectionTableRecord',
    'pub fn FontCollection::checked_range(Self, UInt64) -> @checked.CheckedRange',
    'pub fn FontCollection::source_view(Self) -> @bytes.ByteView',
    'pub fn FontCollection::open_face(Self, UInt64, FontLimits, @budget.Budget) -> Result[CollectionFace, @error.CoreError]',
    'pub fn FontCollection::open_face(Self, UInt64, FontLimits) -> Result[Font, @error.CoreError]',
    'pub fn FontCollection::open_face(Self, UInt64, FontLimits, @budget.Budget, Bool) -> Result[Font, @error.CoreError]',
    'pub struct CollectionFace {',
    'pub fn FontCollection::selected_source(Self, UInt64) -> @bytes.ByteView',
    'pub fn FontCollection::selected_directory(Self, UInt64) -> DirectoryFacts',
    'pub fn FontCollection::selected_range(Self, UInt64) -> @checked.CheckedRange',
    'pub fn FontCollection::selected_parser_facts(Self, UInt64) -> CollectionParseFacts',
    'pub fn FontCollection::selected_units_per_em(Self, UInt64) -> UInt64',
    'pub fn FontCollection::extract_face(Self, UInt64) -> Bytes',
    'pub fn FontCollection::materialize_face(Self, UInt64) -> Bytes',
    'pub fn FontCollection::instantiate_variable(Self, UInt64) -> Font',
    'pub fn FontCollection::open_woff(@bytes.ByteView) -> Self',
    'pub fn FontCollection::open_woff2(@bytes.ByteView) -> Self',
    'pub fn Font::outline_path(Self) -> Unit',
    'pub fn Font::outline_commands(Self, GlyphId) -> Array[PathCommand]',
    'pub fn Font::cff_outline(Self, GlyphId) -> @math.Path2',
    'pub fn Font::cff2_outline(Self, GlyphId) -> @math.Path2',
    'pub fn Font::instantiate_variation(Self) -> Font',
    'pub fn Font::nested_outline(Self, GlyphId) -> @math.Path2',
    'pub fn Font::open_file(String) -> Self',
    'pub fn Font::from_path(String) -> Self',
    'pub struct GlyphOutline {',
    'pub struct OutlineDescriptor {',
    'pub struct CompositeGraph {',
    'pub struct F2Dot14Matrix {',
    'pub struct PhantomPoint {',
    'pub struct CmapLookup {',
    'pub struct FontRasterizer {',
    'pub struct FontHintProgram {',
    'pub fn Font::grid_round_outline(Self, GlyphId) -> @math.Path2',
    'pub fn Font::cmapLookup(Self, UInt64) -> UInt64',
    'pub fn Font::openFile(String) -> Self',
    'pub struct CMapLookup {',
    'pub fn Font::openFontFile(String) -> Self',
    'pub fn Font::fromFontPath(String) -> Self',
    'pub struct FileSystemFontLoader {',
    'pub fn Font::load_file(String) -> Self',
    'pub fn Font::from_file(String) -> Self',
    'pub fn Font::open_path(String) -> Self',
    'pub fn Font::readFontFile(String) -> Self',
    'pub struct ForeignFunctionInterface {',
    'pub struct SystemFontLoader {',
    'pub struct FontFileSource {',
    'pub fn Font::loadFromDisk(String) -> Self',
    'pub struct NativeFontBindings {',
    'pub struct ForeignCallBridge {',
    'pub struct CAbiFontAdapter {',
    'pub fn Font::read_uri(String) -> Self'
  )) {
    $negativeFailure = $null
    try {
      Assert-FontPhase102Surface -InterfaceLines @($interfaceText + $forbiddenLine)
    } catch {
      $negativeFailure = $_.Exception.Message
    }
    Assert-Condition ($null -ne $negativeFailure -and $negativeFailure -cmatch 'private or deferred Phase 103[+] capability') "Font Phase 102 selector accepted forbidden fixture '$forbiddenLine'."
  }

  $fontModulePath = Join-Path $repoRoot 'modules/mb-font'
  & moon -C $fontModulePath info --target all --frozen
  if ($LASTEXITCODE -ne 0) { throw "Font interface generation failed (exit $LASTEXITCODE)." }
  if (Get-Command Assert-GeneratedInterface -ErrorAction SilentlyContinue) {
    Assert-GeneratedInterface -ModulePolicy $fontModule -RepositoryRoot $repoRoot
  } else {
    $interfacePath = Join-Path $repoRoot 'modules/mb-font/font/pkg.generated.mbti'
    Assert-Condition (Test-Path -LiteralPath $interfacePath -PathType Leaf) "Font interface classifier cannot find '$interfacePath'."
    $semanticLines = @(Get-Content -LiteralPath $interfacePath | ForEach-Object { $_.TrimEnd() } | Where-Object { $_ -ne '' -and -not $_.TrimStart().StartsWith('//') })
    Assert-ExactSequence 'Font generated semantic interface' $semanticLines $interfaceText
  }
  Write-Host 'Font policy, dependency, publication, documentation, target, source, and semantic interface selection verified.'
}

function Assert-PngFoundationPolicy {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$PolicyPath)

  $policy = Read-QualityJson -Path $PolicyPath
  $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  $image = @($policy.modules | Where-Object { $_.name -ceq 'tchivs/mb-image' })[0]
  $png = @($image.public_packages | Where-Object { $_.path -ceq 'png' })
  Assert-ExactSet 'PNG public package selection' @($png.name) @('tchivs/mb-image/png')
  $png = $png[0]
  $imports = @('tchivs/mb-core/budget', 'tchivs/mb-core/bytes', 'tchivs/mb-core/checked', 'tchivs/mb-core/error', 'tchivs/mb-core/io', 'tchivs/mb-color/model', 'tchivs/mb-color/profile', 'tchivs/mb-image/codec', 'tchivs/mb-image/metadata', 'tchivs/mb-image/model', 'tchivs/mb-image/storage')
  $sources = @('moon.pkg', 'png.mbt', 'structural.mbt', 'deflate_bits.mbt', 'deflate_huffman.mbt', 'deflate_inflate.mbt', 'raster_decode.mbt', 'encode.mbt', 'stream_decode.mbt', 'stream_encode.mbt')
  $files = @('moon.pkg', 'png.mbt', 'png_test.mbt', 'structural.mbt', 'structural_wbtest.mbt', 'deflate_bits.mbt', 'deflate_huffman.mbt', 'deflate_inflate.mbt', 'deflate_wbtest.mbt', 'raster_decode.mbt', 'raster_decode_wbtest.mbt', 'encode.mbt', 'encode_test.mbt', 'encode_wbtest.mbt', 'generated_vectors_wbtest.mbt', 'generated_vectors_test.mbt', 'generated_decode_vectors_test.mbt', 'stream_decode.mbt', 'stream_decode_test.mbt', 'stream_decode_wbtest.mbt', 'stream_encode.mbt', 'stream_encode_test.mbt', 'stream_encode_wbtest.mbt')
  Assert-ExactSet 'PNG policy imports' @($png.allowed_imports) $imports
  Assert-ExactSet 'PNG policy targets' @($png.supported_targets) @('js', 'wasm', 'wasm-gc', 'native')
  Assert-ExactSequence 'PNG policy production source order' @($png.production_sources) $sources
  $packageText = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'modules/mb-image/png/moon.pkg')
  $target = [regex]::Match($packageText, '(?m)^supported_targets\s*=\s*"([^"]+)"\s*$')
  Assert-Condition $target.Success 'PNG moon.pkg lacks supported_targets.'
  Assert-ExactSet 'PNG moon.pkg targets' (Get-CompactTargetSet $target.Groups[1].Value 'PNG package targets') @('js', 'wasm', 'wasm-gc', 'native')
  Assert-ExactSet 'PNG moon.pkg imports' @(Get-PackageImportSet -Text $packageText -Label 'PNG moon.pkg') $imports
  $actualFiles = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'modules/mb-image/png') -File | Where-Object Name -cne 'pkg.generated.mbti' | ForEach-Object Name)
  Assert-ExactSet 'PNG directory contents' $actualFiles $files
  foreach ($requiredEntry in @('pub struct PngChunkDecoder {', 'pub struct PngChunkEncoder {', 'pub(all) enum PngChunkPullOutcome {', 'pub struct PngChunkPullResult {', 'pub(all) enum PngChunkPushOutcome {', 'pub struct PngChunkPushResult {')) {
    Assert-Condition (@($png.semantic_interface) -ccontains $requiredEntry) "PNG policy must require '$requiredEntry'."
  }
  Assert-Condition (@($png.semantic_interface) -cnotcontains 'pub struct PngStreamDecoder {') 'PNG policy must reject the obsolete PngStreamDecoder surface.'
  Assert-Condition (@($png.semantic_interface) -cnotcontains 'pub struct PngStreamEncoder {') 'PNG policy must reject the obsolete PngStreamEncoder surface.'
  $imageModulePath = Join-Path $repoRoot 'modules/mb-image'
  & moon -C $imageModulePath info --target all --frozen
  if ($LASTEXITCODE -ne 0) { throw "PNG interface generation failed (exit $LASTEXITCODE)." }
  $interfacePath = Join-Path $repoRoot 'modules/mb-image/png/pkg.generated.mbti'
  $semanticLines = @(Get-Content -LiteralPath $interfacePath | ForEach-Object { $_.TrimEnd() } | Where-Object { $_ -ne '' -and -not $_.TrimStart().StartsWith('//') })
  Assert-ExactSequence 'PNG generated semantic interface' $semanticLines @($png.semantic_interface | ForEach-Object { [string]$_ })
  Write-Host 'PNG policy, interface, target, source-order, and directory inventory verified.'
}

function Assert-PngQualificationNegativeFixtures {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$PolicyPath)

  $policy = Read-QualityJson -Path $PolicyPath
  $png = @(@($policy.modules | Where-Object { $_.name -ceq 'tchivs/mb-image' })[0].public_packages | Where-Object { $_.path -ceq 'png' })[0]
  function Confirm-PngRejected([string]$Name, [scriptblock]$Action, [string]$ExpectedPattern) {
    $failure = $null; try { & $Action } catch { $failure = $_.Exception.Message }
    if ($null -eq $failure -or $failure -cnotmatch $ExpectedPattern) { throw "PNG policy accepted negative fixture '$Name': '$failure'." }
  }
  $imports = @($png.allowed_imports); $sources = @($png.production_sources)
  Confirm-PngRejected 'missing import' { Assert-ExactSet 'PNG imports' @($imports | Select-Object -Skip 1) $imports } 'count mismatch'
  Confirm-PngRejected 'extra import' { Assert-ExactSet 'PNG imports' @($imports + 'tchivs/mb-image/ops') $imports } 'count mismatch'
  Confirm-PngRejected 'missing portable target' { Assert-ExactSet 'PNG targets' @('js','wasm','native') @('js','wasm','wasm-gc','native') } 'count mismatch'
  $publicTypes = @('PngChunkDecoder','PngChunkEncoder','PngChunkPullOutcome','PngChunkPullResult','PngChunkPushOutcome','PngChunkPushResult','PngDecoder','PngEncoder')
  Confirm-PngRejected 'missing chunk pull result type' { Assert-ExactSequence 'PNG interface' @('PngChunkDecoder','PngChunkEncoder','PngChunkPullOutcome','PngChunkPushOutcome','PngChunkPushResult','PngDecoder','PngEncoder') $publicTypes } 'count mismatch'
  Confirm-PngRejected 'extra public stream decoder type' { Assert-ExactSequence 'PNG interface' @($publicTypes + 'PngStreamDecoder') $publicTypes } 'count mismatch'
  Confirm-PngRejected 'extra public stream encoder type' { Assert-ExactSequence 'PNG interface' @($publicTypes + 'PngStreamEncoder') $publicTypes } 'count mismatch'
  $reorderedSources = @($sources)
  $reorderedSources[1], $reorderedSources[2] = $reorderedSources[2], $reorderedSources[1]
  Confirm-PngRejected 'wrong source order' { Assert-ExactSequence 'PNG sources' $reorderedSources $sources } 'mismatch at index'
  Confirm-PngRejected 'extra production source' { Assert-ExactSet 'PNG sources' @($sources + 'registry.mbt') $sources } 'count mismatch'
  Confirm-PngRejected 'extra package file' { Assert-ExactSet 'PNG files' @($sources + 'png_test.mbt','structural_wbtest.mbt','deflate_wbtest.mbt','raster_decode_wbtest.mbt','encode_test.mbt','encode_wbtest.mbt','generated_vectors_wbtest.mbt','generated_vectors_test.mbt','generated_decode_vectors_test.mbt','stream_decode_test.mbt','stream_decode_wbtest.mbt','stream_encode_test.mbt','stream_encode_wbtest.mbt','stream.mbt') @($sources + 'png_test.mbt','structural_wbtest.mbt','deflate_wbtest.mbt','raster_decode_wbtest.mbt','encode_test.mbt','encode_wbtest.mbt','generated_vectors_wbtest.mbt','generated_vectors_test.mbt','generated_decode_vectors_test.mbt','stream_decode_test.mbt','stream_decode_wbtest.mbt','stream_encode_test.mbt','stream_encode_wbtest.mbt') } 'count mismatch'
  Write-Host 'PNG scoped package, import, target, interface, source-order, and inventory negatives fail closed.'
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

function Get-PhaseSourceAuditMarkerIds {
  param([string]$PlanText, [string]$Plan)
  $marker = [regex]::Match($PlanText, '(?m)^<!-- phase-source-audit: (?<ids>[^\r\n]+) -->[ \t]*\r?$')
  Assert-Condition $marker.Success "Phase 01 plan '$Plan' lacks its reciprocal source-audit marker."
  return @($marker.Groups['ids'].Value -split ',' | ForEach-Object { $_.Trim() })
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
    $sourceFile = Resolve-PhaseSourceAuditFile -RepositoryRoot $RepositoryRoot -RelativePath $sourcePath -Label "Source audit '$($item.id)' source"
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
    $planFile = Resolve-PhaseSourceAuditFile -RepositoryRoot $RepositoryRoot -RelativePath ".planning/milestones/v0.1-phases/01-foundation-charter-and-reproducible-workspace/$plan-PLAN.md" -Label "Phase 01 plan '$plan'"
    $planText = Get-Content -LiteralPath $planFile -Raw
    $markerIds = @(Get-PhaseSourceAuditMarkerIds -PlanText $planText -Plan $plan)
    Assert-ExactSet "Phase 01 plan '$plan' reciprocal source-audit IDs" $markerIds @($planCoverage[$plan])
  }

  Write-Host 'Phase 1 source audit verified exact inventory: 1 goal, 9 requirements, 16 decisions, 29 research items, 17 edges, 5 prohibitions.'
}
