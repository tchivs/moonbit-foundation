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

  $expectedModules = @('tchivs/mb-core', 'tchivs/mb-color', 'tchivs/mb-image')
  $expectedPaths = @('modules/mb-core', 'modules/mb-color', 'modules/mb-image')
  Assert-ExactSet 'Policy modules' @($policy.modules.name) $expectedModules
  Assert-ExactSet 'Policy module paths' @($policy.modules.path) $expectedPaths
  Assert-AcyclicDependencyGraph -Modules @($policy.modules) -AllowedEdges @($policy.allowed_dependency_edges)

  $workText = Get-Content -LiteralPath (Join-Path $repoRoot 'moon.work') -Raw
  $workMembers = @([regex]::Matches($workText, '"\./([^"\r\n]+)"') | ForEach-Object { $_.Groups[1].Value })
  Assert-ExactSet 'moon.work members' $workMembers @($expectedPaths + @('examples/ppm-portable', 'examples/ppm-native-cli', 'examples/qoi-portable'))

  foreach ($module in $policy.modules) {
    Assert-Condition ($module.version -ceq '0.1.0') "Policy version drift for $($module.name)."
    Assert-Condition (@($policy.stability.allowed_labels) -ccontains $module.stability) "Invalid stability label for $($module.name)."
    Assert-ExactSet "Policy targets for $($module.name)" @($module.supported_targets) @($policy.required_targets)
    $packages = @($module.public_packages)
    Assert-Condition ($packages.Count -gt 0) "$($module.name) must declare at least one public package."
    Assert-ExactSet "Public package names for $($module.name)" @($packages.name) @($packages | ForEach-Object { [string]$_.name })
    Assert-ExactSet "Public package paths for $($module.name)" @($packages.path) @($packages | ForEach-Object { [string]$_.path })

    if ($module.name -ceq 'tchivs/mb-core') {
      $corePackagePaths = @('error', 'checked', 'budget', 'bytes', 'io', 'host')
      $corePackageNames = @($corePackagePaths | ForEach-Object { "tchivs/mb-core/$_" })
      Assert-ExactSequence 'mb-core public package spine' @($packages.name) $corePackageNames
      Assert-ExactSequence 'mb-core public package paths' @($packages.path) $corePackagePaths
      foreach ($removedRootFile in @('moon.pkg', 'scaffold.mbt', 'scaffold_wbtest.mbt')) {
        Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $repoRoot "modules/mb-core/$removedRootFile"))) "Obsolete mb-core root scaffold file remains: $removedRootFile."
      }
    }

    if ($module.name -ceq 'tchivs/mb-color') {
      $colorPackagePaths = @('model', 'transfer', 'quantize', 'alpha', 'profile')
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
      $imagePackagePaths = @('metadata', 'model', 'storage', 'ops', 'codec', 'ppm', 'qoi')
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

  Write-Host 'Foundation policy, RFC, workspace inventory, target metadata, fixtures, publication block, and dependency DAG verified.'
}

function Assert-QoiGeneratedInterface {
  param([Parameter(Mandatory)][object]$QoiPolicy)

  $interfacePath = 'modules/mb-image/qoi/pkg.generated.mbti'
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

  & moon -C modules/mb-image info --target all --frozen
  if ($LASTEXITCODE -ne 0) { throw "QOI interface generation failed (exit $LASTEXITCODE)." }
  if (Get-Command Assert-GeneratedInterface -ErrorAction SilentlyContinue) {
    $scopedModule = [pscustomobject]@{ name = 'tchivs/mb-image'; path = 'modules/mb-image'; public_packages = @($qoi) }
    Assert-GeneratedInterface -ModulePolicy $scopedModule
  } else {
    Assert-QoiGeneratedInterface -QoiPolicy $qoi
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
  $sources = @('moon.pkg', 'png.mbt', 'structural.mbt', 'deflate_bits.mbt', 'deflate_huffman.mbt', 'deflate_inflate.mbt', 'raster_decode.mbt', 'encode.mbt', 'generated_vectors.mbt', 'stream_decode.mbt', 'stream_encode.mbt')
  $files = @('moon.pkg', 'png.mbt', 'png_test.mbt', 'structural.mbt', 'structural_wbtest.mbt', 'deflate_bits.mbt', 'deflate_huffman.mbt', 'deflate_inflate.mbt', 'deflate_wbtest.mbt', 'raster_decode.mbt', 'raster_decode_wbtest.mbt', 'encode.mbt', 'encode_test.mbt', 'encode_wbtest.mbt', 'generated_vectors.mbt', 'generated_vectors_test.mbt', 'generated_decode_vectors_test.mbt', 'stream_decode.mbt', 'stream_decode_test.mbt', 'stream_decode_wbtest.mbt', 'stream_encode.mbt', 'stream_encode_test.mbt', 'stream_encode_wbtest.mbt')
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
  & moon -C modules/mb-image info --target all --frozen
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
  Confirm-PngRejected 'wrong source order' { Assert-ExactSequence 'PNG sources' @('moon.pkg','png.mbt','generated_vectors.mbt','structural.mbt') $sources } 'count mismatch'
  Confirm-PngRejected 'extra production source' { Assert-ExactSet 'PNG sources' @($sources + 'registry.mbt') $sources } 'count mismatch'
  Confirm-PngRejected 'extra package file' { Assert-ExactSet 'PNG files' @($sources + 'png_test.mbt','structural_wbtest.mbt','deflate_wbtest.mbt','raster_decode_wbtest.mbt','encode_test.mbt','encode_wbtest.mbt','generated_vectors_test.mbt','generated_decode_vectors_test.mbt','stream_decode_test.mbt','stream_decode_wbtest.mbt','stream_encode_test.mbt','stream_encode_wbtest.mbt','stream.mbt') @($sources + 'png_test.mbt','structural_wbtest.mbt','deflate_wbtest.mbt','raster_decode_wbtest.mbt','encode_test.mbt','encode_wbtest.mbt','generated_vectors_test.mbt','generated_decode_vectors_test.mbt','stream_decode_test.mbt','stream_decode_wbtest.mbt','stream_encode_test.mbt','stream_encode_wbtest.mbt') } 'count mismatch'
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
