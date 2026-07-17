[CmdletBinding()]
param(
  [string]$BaselineRoot,
  [string]$CandidateRoot,
  [string]$CandidateReleasePath,
  [string]$PolicyPath,
  [string]$OutputPath,
  [switch]$ClassifyOnly,
  [switch]$LibraryMode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:CompatibilityClaimScope = 'public-interface-text-and-declared-release-facts-only; no behavioral, semantic, resource, representation-layout, performance, or full compatibility claim'

function Throw-CompatibilityRule {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][string]$Message)
  throw "$Id`: $Message"
}

function Read-CompatibilityJson {
  param([Parameter(Mandatory)][string]$Path, [string]$MissingRule = 'COMP02-INPUT-CLOSED')
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Throw-CompatibilityRule -Id $MissingRule -Message "required JSON is missing: $Path"
  }
  try { return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100 } catch {
    Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message "invalid JSON '$Path': $($_.Exception.Message)"
  }
}

function Assert-CompatibilityClosedProperties {
  param([Parameter(Mandatory)][string]$Label, [Parameter(Mandatory)]$Value, [Parameter(Mandatory)][string[]]$Expected)
  $actual = @($Value.PSObject.Properties.Name | Sort-Object -CaseSensitive)
  $wanted = @($Expected | Sort-Object -CaseSensitive)
  if ($actual.Count -ne $wanted.Count) {
    Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message "$Label property count mismatch."
  }
  for ($i = 0; $i -lt $wanted.Count; $i++) {
    if ([string]$actual[$i] -cne [string]$wanted[$i]) {
      Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message "$Label has unexpected or missing property."
    }
  }
}

function Get-CompatibilitySha256 {
  param([Parameter(Mandatory)][string]$Path)
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-CompatibilityDeclarationIdentity {
  param([Parameter(Mandatory)][string]$Header)
  if ($Header -cnotmatch '^(?<visibility>pub(?:\([^)]*\))?|priv|internal)\s+(?<kind>fn(?:\[[^]]+\])?|struct|enum|trait|impl|type)\s+(?<rest>.+)$') {
    Throw-CompatibilityRule -Id 'COMP02-UNKNOWN-SYNTAX' -Message "unrepresented declaration header '$Header'."
  }
  $visibility = [string]$Matches.visibility
  $kind = [string]$Matches.kind
  $rest = [string]$Matches.rest
  $baseKind = if ($kind.StartsWith('fn', [StringComparison]::Ordinal)) { 'fn' } else { $kind }
  $name = switch ($baseKind) {
    'fn' {
      if ($rest -cnotmatch '^(?<name>[^ (]+)\s*\(') { Throw-CompatibilityRule -Id 'COMP02-UNKNOWN-SYNTAX' -Message "unrepresented function header '$Header'." }
      [string]$Matches.name
    }
    'impl' { $rest.TrimEnd() }
    default {
      if ($rest -cnotmatch '^(?<name>[A-Za-z_][A-Za-z0-9_]*)') { Throw-CompatibilityRule -Id 'COMP02-UNKNOWN-SYNTAX' -Message "unrepresented declaration identity '$Header'." }
      [string]$Matches.name
    }
  }
  return [pscustomobject]@{ key = "$baseKind`:$name"; visibility = $visibility; kind = $baseKind }
}

function Read-NormalizedInterface {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Throw-CompatibilityRule -Id 'COMP02-INCOMPLETE-CANDIDATE' -Message "normalized interface is missing: $Path"
  }
  $text = [IO.File]::ReadAllText($Path, [Text.UTF8Encoding]::new($false)).Replace("`r`n", "`n").Replace("`r", "`n")
  $lines = @($text -split "`n")
  $package = $null
  $imports = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $declarations = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
  $inImports = $false
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = [string]$lines[$i]
    if ($inImports) {
      if ($line -ceq '}') { $inImports = $false; continue }
      if ([string]::IsNullOrWhiteSpace($line)) { continue }
      if ($line -cnotmatch '^\s+"(?<name>[^"]+)",?$') {
        Throw-CompatibilityRule -Id 'COMP02-UNKNOWN-SYNTAX' -Message "unrepresented import syntax in '$Path'."
      }
      if (-not $imports.Add([string]$Matches.name)) {
        Throw-CompatibilityRule -Id 'COMP02-AMBIGUOUS-MATCH' -Message "duplicate import in '$Path'."
      }
      continue
    }
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('//', [StringComparison]::Ordinal)) { continue }
    if ($line -cmatch '^package "(?<name>[^"]+)"$') {
      if ($null -ne $package) { Throw-CompatibilityRule -Id 'COMP02-AMBIGUOUS-MATCH' -Message "duplicate package declaration in '$Path'." }
      $package = [string]$Matches.name
      continue
    }
    if ($line -ceq 'import {') { $inImports = $true; continue }
    if ($line -cmatch '^(?:pub(?:\([^)]*\))?|priv|internal)\s+' -or $line -cmatch '^type\s+') {
      $identityHeader = if ($line -cmatch '^type\s+') { "internal $line" } else { $line }
      $identity = Get-CompatibilityDeclarationIdentity -Header $identityHeader
      $block = [Collections.Generic.List[string]]::new()
      $block.Add($line)
      $depth = ([regex]::Matches($line, '\{')).Count - ([regex]::Matches($line, '\}')).Count
      while ($depth -gt 0) {
        $i++
        if ($i -ge $lines.Count) { Throw-CompatibilityRule -Id 'COMP02-UNKNOWN-SYNTAX' -Message "unterminated declaration in '$Path'." }
        $body = [string]$lines[$i]
        $block.Add($body)
        $depth += ([regex]::Matches($body, '\{')).Count - ([regex]::Matches($body, '\}')).Count
      }
      if ($depth -ne 0) { Throw-CompatibilityRule -Id 'COMP02-UNKNOWN-SYNTAX' -Message "unbalanced declaration in '$Path'." }
      if ($declarations.ContainsKey([string]$identity.key)) {
        Throw-CompatibilityRule -Id 'COMP02-AMBIGUOUS-MATCH' -Message "duplicate declaration identity '$($identity.key)' in '$Path'."
      }
      $declarations.Add([string]$identity.key, [pscustomobject]@{
        key = [string]$identity.key
        visibility = [string]$identity.visibility
        kind = [string]$identity.kind
        text = ($block -join "`n")
      })
      continue
    }
    Throw-CompatibilityRule -Id 'COMP02-UNKNOWN-SYNTAX' -Message "unrepresented normalized interface syntax '$line' in '$Path'."
  }
  if ($inImports -or [string]::IsNullOrWhiteSpace([string]$package)) {
    Throw-CompatibilityRule -Id 'COMP02-UNKNOWN-SYNTAX' -Message "incomplete package or import block in '$Path'."
  }
  return [pscustomobject]@{ package = $package; imports = $imports; declarations = $declarations; text = $text }
}

function Read-CompatibilityTree {
  param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][ValidateSet('baseline','candidate')][string]$Role)
  $missingRule = if ($Role -ceq 'baseline') { 'COMP02-MISSING-BASELINE' } else { 'COMP02-INCOMPLETE-CANDIDATE' }
  if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
    Throw-CompatibilityRule -Id $missingRule -Message "$Role tree is missing: $Root"
  }
  $manifestPath = Join-Path $Root 'manifest.json'
  $manifest = Read-CompatibilityJson -Path $manifestPath -MissingRule $missingRule
  Assert-CompatibilityClosedProperties -Label "$Role manifest" -Value $manifest -Expected @(
    'schema_version','normalization_schema_version','baseline_version','source_snapshot_sha256','source_commit','toolchain','targets',
    'package_count','record_count','packages','two_run_equal','claim_scope'
  )
  Assert-CompatibilityClosedProperties -Label "$Role toolchain" -Value $manifest.toolchain -Expected @('moon','moonc','moonrun')
  if ([string]$manifest.schema_version -cne 'mnf-public-interface-baseline-manifest/1' -or
      [string]$manifest.normalization_schema_version -cne 'moon-mbti-lossless-lines/1') {
    Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message "$Role manifest schema identity drifted."
  }
  if ([string]$manifest.source_snapshot_sha256 -cnotmatch '^[0-9a-f]{64}$') {
    Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message "$Role manifest source snapshot digest is missing or malformed."
  }
  if ($manifest.two_run_equal -ne $true) {
    Throw-CompatibilityRule -Id 'COMP02-INTERRUPTED-RESULT' -Message "$Role generation is not a completed equal two-run result."
  }
  $targets = @($manifest.targets | ForEach-Object { [string]$_ })
  if ($targets.Count -eq 0 -or @($targets | Sort-Object -Unique -CaseSensitive).Count -ne $targets.Count) {
    Throw-CompatibilityRule -Id 'COMP02-DUPLICATE-RECORD' -Message "$Role target inventory is empty or duplicated."
  }
  if ([int]$manifest.package_count -ne @($manifest.packages).Count) {
    Throw-CompatibilityRule -Id $missingRule -Message "$Role package count is partial."
  }
  $packages = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
  $recordCount = 0
  foreach ($entry in @($manifest.packages)) {
    Assert-CompatibilityClosedProperties -Label "$Role package manifest entry" -Value $entry -Expected @(
      'module','package','baseline_path','baseline_sha256','raw_path','raw_sha256'
    )
    $packageName = [string]$entry.package
    if ($packages.ContainsKey($packageName)) {
      Throw-CompatibilityRule -Id 'COMP02-DUPLICATE-RECORD' -Message "$Role package '$packageName' is duplicated."
    }
    foreach ($relative in @([string]$entry.baseline_path, [string]$entry.raw_path)) {
      if ([IO.Path]::IsPathRooted($relative) -or $relative -cmatch '(^|/)[.][.](/|$)|\\') {
        Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message "$Role path '$relative' is unsafe."
      }
    }
    $documentPath = Join-Path $Root ([string]$entry.baseline_path)
    $rawPath = Join-Path $Root ([string]$entry.raw_path)
    if (-not (Test-Path -LiteralPath $documentPath -PathType Leaf) -or -not (Test-Path -LiteralPath $rawPath -PathType Leaf)) {
      Throw-CompatibilityRule -Id $missingRule -Message "$Role package '$packageName' is partial."
    }
    if ((Get-CompatibilitySha256 $documentPath) -cne [string]$entry.baseline_sha256 -or
        (Get-CompatibilitySha256 $rawPath) -cne [string]$entry.raw_sha256) {
      Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message "$Role package '$packageName' digest binding failed."
    }
    $document = Read-CompatibilityJson -Path $documentPath -MissingRule $missingRule
    Assert-CompatibilityClosedProperties -Label "$Role package document" -Value $document -Expected @(
      'schema_version','normalization_schema_version','source_snapshot_sha256','source_commit','toolchain','module','package','raw_path',
      'raw_sha256','records','two_run_equal','claim_scope'
    )
    Assert-CompatibilityClosedProperties -Label "$Role package toolchain" -Value $document.toolchain -Expected @('moon','moonc','moonrun')
    if ([string]$document.package -cne $packageName -or [string]$document.module -cne [string]$entry.module -or
        [string]$document.raw_path -cne [string]$entry.raw_path -or [string]$document.raw_sha256 -cne [string]$entry.raw_sha256 -or
        [string]$document.source_snapshot_sha256 -cne [string]$manifest.source_snapshot_sha256 -or
        [string]$document.source_commit -cne [string]$manifest.source_commit -or
        [string]$document.schema_version -cne 'mnf-public-interface-baseline-package/1' -or
        [string]$document.normalization_schema_version -cne 'moon-mbti-lossless-lines/1' -or
        [string]$document.claim_scope -cne 'public-interface-text-only; no behavioral, semantic, resource, layout, or performance compatibility claim' -or
        ($document.toolchain | ConvertTo-Json -Compress) -cne ($manifest.toolchain | ConvertTo-Json -Compress) -or
        $document.two_run_equal -ne $true) {
      Throw-CompatibilityRule -Id $missingRule -Message "$Role package '$packageName' identity or completion failed."
    }
    if (@($document.records).Count -ne $targets.Count) {
      Throw-CompatibilityRule -Id $missingRule -Message "$Role package '$packageName' has a partial target inventory."
    }
    $records = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
    foreach ($record in @($document.records)) {
      Assert-CompatibilityClosedProperties -Label "$Role package-target record" -Value $record -Expected @('target','normalized_path','normalized_sha256','target_inspection')
      Assert-CompatibilityClosedProperties -Label "$Role target inspection" -Value $record.target_inspection -Expected @('command','status','raw_sha256','matches_canonical')
      $target = [string]$record.target
      if ($records.ContainsKey($target)) { Throw-CompatibilityRule -Id 'COMP02-DUPLICATE-RECORD' -Message "$Role package-target '$packageName|$target' is duplicated." }
      if ($targets -cnotcontains $target) { Throw-CompatibilityRule -Id $missingRule -Message "$Role package-target '$packageName|$target' is not declared." }
      $normalizedRelative = [string]$record.normalized_path
      if ([IO.Path]::IsPathRooted($normalizedRelative) -or $normalizedRelative -cmatch '(^|/)[.][.](/|$)|\\') {
        Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message "$Role normalized path '$normalizedRelative' is unsafe."
      }
      if ([string]$record.target_inspection.status -cne 'pass' -or $record.target_inspection.matches_canonical -ne $true -or
          [string]$record.target_inspection.raw_sha256 -cne [string]$document.raw_sha256) {
        Throw-CompatibilityRule -Id 'COMP02-TARGET-DIVERGENCE' -Message "$Role package-target '$packageName|$target' diverged."
      }
      $normalizedPath = Join-Path $Root ([string]$record.normalized_path)
      if (-not (Test-Path -LiteralPath $normalizedPath -PathType Leaf)) { Throw-CompatibilityRule -Id $missingRule -Message "$Role normalized record '$packageName|$target' is missing." }
      if ((Get-CompatibilitySha256 $normalizedPath) -cne [string]$record.normalized_sha256) { Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message "$Role normalized digest '$packageName|$target' failed." }
      $parsed = Read-NormalizedInterface -Path $normalizedPath
      if ([string]$parsed.package -cne $packageName) { Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message "$Role normalized package identity differs for '$packageName|$target'." }
      $records.Add($target, $parsed)
      $recordCount++
    }
    $canonicalTexts = @($records.Values | ForEach-Object { [string]$_.text } | Sort-Object -Unique -CaseSensitive)
    if ($canonicalTexts.Count -ne 1) { Throw-CompatibilityRule -Id 'COMP02-TARGET-DIVERGENCE' -Message "$Role package '$packageName' has divergent target interfaces." }
    $packages.Add($packageName, [pscustomobject]@{ module = [string]$entry.module; records = $records })
  }
  if ([int]$manifest.record_count -ne $recordCount) { Throw-CompatibilityRule -Id $missingRule -Message "$Role record count is partial." }
  return [pscustomobject]@{ manifest = $manifest; targets = $targets; packages = $packages }
}

function Read-CandidateReleaseFacts {
  param([Parameter(Mandatory)][string]$Path)
  $facts = Read-CompatibilityJson -Path $Path
  Assert-CompatibilityClosedProperties -Label 'candidate release facts' -Value $facts -Expected @(
    'schema_version','complete','baseline_version','candidate_version','supported_targets','minimum_toolchain','dependency_floors','evidence'
  )
  Assert-CompatibilityClosedProperties -Label 'candidate minimum toolchain' -Value $facts.minimum_toolchain -Expected @('moon','moonc','moonrun')
  Assert-CompatibilityClosedProperties -Label 'candidate dependency floors' -Value $facts.dependency_floors -Expected @('mb-core','mb-color','mb-image')
  Assert-CompatibilityClosedProperties -Label 'candidate evidence' -Value $facts.evidence -Expected @(
    'changelog_present','change_class','added_surface_report_present','migration_present','rfc_present','rfc_impacts'
  )
  if ([string]$facts.schema_version -cne 'mnf-public-compatibility-candidate/1') { Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message 'candidate release-fact schema identity drifted.' }
  if ($facts.complete -ne $true) { Throw-CompatibilityRule -Id 'COMP02-INTERRUPTED-RESULT' -Message 'candidate release facts are incomplete.' }
  foreach ($module in @('mb-core','mb-color','mb-image')) {
    foreach ($property in @($facts.dependency_floors.$module.PSObject.Properties)) {
      if ($property.Name -cnotmatch '^tchivs/mb-(core|color|image)$' -or [string]$property.Value -cnotmatch '^(0|[1-9][0-9]*)[.](0|[1-9][0-9]*)[.](0|[1-9][0-9]*)$') {
        Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message "invalid dependency floor '$module.$($property.Name)'."
      }
    }
  }
  $impacts = @($facts.evidence.rfc_impacts | ForEach-Object { [string]$_ })
  foreach ($impact in $impacts) { if (@('boundary','architecture','governance') -cnotcontains $impact) { Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message "unknown RFC impact '$impact'." } }
  if (@($impacts | Sort-Object -Unique -CaseSensitive).Count -ne $impacts.Count) { Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message 'RFC impacts are duplicated.' }
  return $facts
}

function Get-CanonicalVersion {
  param([Parameter(Mandatory)][string]$Value)
  if ($Value -cnotmatch '^(?<major>0|[1-9][0-9]*)[.](?<minor>0|[1-9][0-9]*)[.](?<patch>0|[1-9][0-9]*)(?<suffix>(?:-[0-9A-Za-z-]+(?:[.][0-9A-Za-z-]+)*)?(?:[+][0-9A-Za-z-]+(?:[.][0-9A-Za-z-]+)*)?)$') {
    Throw-CompatibilityRule -Id 'COMP03-VERSION-NONCANONICAL' -Message "version '$Value' is not canonical SemVer."
  }
  return [pscustomobject]@{
    major = [Numerics.BigInteger]::Parse([string]$Matches.major)
    minor = [Numerics.BigInteger]::Parse([string]$Matches.minor)
    patch = [Numerics.BigInteger]::Parse([string]$Matches.patch)
    suffix = [string]$Matches.suffix
  }
}

function Test-VersionSufficient {
  param([Parameter(Mandatory)]$Baseline, [Parameter(Mandatory)]$Candidate, [Parameter(Mandatory)][ValidateSet('patch','minor')][string]$MinimumIncrement)
  if (-not [string]::IsNullOrEmpty([string]$Candidate.suffix)) { return $false }
  if ($Candidate.major -gt $Baseline.major) { return $true }
  if ($Candidate.major -lt $Baseline.major) { return $false }
  if ($MinimumIncrement -ceq 'patch') {
    return ($Candidate.minor -gt $Baseline.minor -or ($Candidate.minor -eq $Baseline.minor -and $Candidate.patch -gt $Baseline.patch))
  }
  return ($Candidate.minor -gt $Baseline.minor)
}

function Add-CompatibilityChange {
  param([Parameter(Mandatory)]$Set, [Parameter(Mandatory)][string]$Value)
  $null = $Set.Add($Value)
}

function Invoke-PublicInterfaceComparison {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$BaselineRoot,
    [Parameter(Mandatory)][string]$CandidateRoot,
    [Parameter(Mandatory)][string]$CandidateReleasePath,
    [Parameter(Mandatory)][string]$PolicyPath
  )
  $baselineVersion = '0.0.0'; $candidateVersion = '0.0.0'
  $added = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $removed = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $changed = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $factChanges = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $classificationRules = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $blockingRules = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $facts = $null
  try {
    $policy = Read-CompatibilityJson -Path $PolicyPath
    Assert-CompatibilityClosedProperties -Label 'compatibility policy' -Value $policy -Expected @(
      'schema_version','classification_precedence','claim_scope','controlled_facts','baseline_profiles','version_rules','rfc_condition','rule_ids'
    )
    if ([string]$policy.schema_version -cne 'mnf-public-compatibility-policy/1' -or [string]$policy.claim_scope -cne $script:CompatibilityClaimScope) {
      Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message 'compatibility policy identity or claim scope drifted.'
    }
    if ((@($policy.classification_precedence | ForEach-Object { [string]$_ }) -join ',') -cne 'unknown,incompatible,additive,exact') {
      Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message 'compatibility policy precedence drifted.'
    }
    Assert-CompatibilityClosedProperties -Label 'compatibility controlled facts' -Value $policy.controlled_facts -Expected @('public_api','supported_targets','minimum_toolchain','dependency_floors')
    Assert-CompatibilityClosedProperties -Label 'compatibility version rules' -Value $policy.version_rules -Expected @('exact','additive','incompatible','unknown')
    foreach ($policyClass in @('exact','additive','incompatible','unknown')) {
      Assert-CompatibilityClosedProperties -Label "compatibility version rule $policyClass" -Value $policy.version_rules.$policyClass -Expected @(
        'minimum_increment','release_allowed','changelog_required','added_surface_report_required','migration_required'
      )
    }
    Assert-CompatibilityClosedProperties -Label 'compatibility RFC condition' -Value $policy.rfc_condition -Expected @(
      'trigger_impacts','accepted_rfc_required_when_triggered','not_required_for_ordinary_incompatible_api_delta'
    )
    $facts = Read-CandidateReleaseFacts -Path $CandidateReleasePath
    $baselineVersion = [string]$facts.baseline_version; $candidateVersion = [string]$facts.candidate_version
    $baselineSemVer = Get-CanonicalVersion $baselineVersion; $candidateSemVer = Get-CanonicalVersion $candidateVersion
    $profileProperty = $policy.baseline_profiles.PSObject.Properties[$baselineVersion]
    if ($null -eq $profileProperty) { Throw-CompatibilityRule -Id 'COMP02-MISSING-BASELINE' -Message "no policy profile exists for baseline '$baselineVersion'." }
    $profile = $profileProperty.Value
    Assert-CompatibilityClosedProperties -Label 'baseline policy profile' -Value $profile -Expected @('supported_targets','minimum_toolchain','dependency_floors')
    $baseline = Read-CompatibilityTree -Root $BaselineRoot -Role baseline
    $candidate = Read-CompatibilityTree -Root $CandidateRoot -Role candidate
    if ([string]$baseline.manifest.baseline_version -cne $baselineVersion) { Throw-CompatibilityRule -Id 'COMP02-MISSING-BASELINE' -Message 'baseline tree version differs from candidate facts.' }
    if (($baseline.manifest.toolchain | ConvertTo-Json -Compress) -cne ($candidate.manifest.toolchain | ConvertTo-Json -Compress)) {
      Throw-CompatibilityRule -Id 'COMP02-TOOLCHAIN-MISMATCH' -Message 'candidate generation toolchain differs from the approved baseline toolchain.'
    }
    $candidateManifestTargets = @($candidate.manifest.targets | ForEach-Object { [string]$_ } | Sort-Object -CaseSensitive)
    $candidateFactTargets = @($facts.supported_targets | ForEach-Object { [string]$_ } | Sort-Object -CaseSensitive)
    if (($candidateManifestTargets -join "`n") -cne ($candidateFactTargets -join "`n")) {
      Throw-CompatibilityRule -Id 'COMP02-TARGET-DIVERGENCE' -Message 'candidate generated targets differ from declared supported targets.'
    }
    foreach ($packageName in @($baseline.packages.Keys)) {
      if (-not $candidate.packages.ContainsKey($packageName)) { Throw-CompatibilityRule -Id 'COMP02-INCOMPLETE-CANDIDATE' -Message "candidate package '$packageName' is missing." }
    }
    foreach ($packageName in @($candidate.packages.Keys)) {
      if (-not $baseline.packages.ContainsKey($packageName)) { Add-CompatibilityChange $added "package:$packageName"; continue }
      foreach ($target in @($baseline.targets)) {
        if (-not $candidate.packages[$packageName].records.ContainsKey($target)) {
          if (@($facts.supported_targets | ForEach-Object { [string]$_ }) -cnotcontains $target) {
            Add-CompatibilityChange $factChanges "supported-target-removed:$target"
            continue
          }
          Throw-CompatibilityRule -Id 'COMP02-INCOMPLETE-CANDIDATE' -Message "candidate target '$packageName|$target' is missing."
        }
        $before = $baseline.packages[$packageName].records[$target]
        $after = $candidate.packages[$packageName].records[$target]
        $beforeImports = @($before.imports | Sort-Object -CaseSensitive); $afterImports = @($after.imports | Sort-Object -CaseSensitive)
        if (($beforeImports -join "`n") -cne ($afterImports -join "`n")) { Add-CompatibilityChange $changed "import:$packageName|$target" }
        foreach ($key in @($before.declarations.Keys)) {
          if (-not $after.declarations.ContainsKey($key)) { Add-CompatibilityChange $removed "$packageName|$target|$key"; continue }
          $old = $before.declarations[$key]; $new = $after.declarations[$key]
          if ([string]$old.visibility -cne [string]$new.visibility) { Add-CompatibilityChange $changed "visibility:$packageName|$target|$key" }
          elseif ([string]$old.text -cne [string]$new.text) { Add-CompatibilityChange $changed "declaration:$packageName|$target|$key" }
        }
        foreach ($key in @($after.declarations.Keys)) {
          if (-not $before.declarations.ContainsKey($key) -and [string]$after.declarations[$key].visibility -cmatch '^pub') { Add-CompatibilityChange $added "$packageName|$target|$key" }
        }
      }
    }
    $baselineTargets = @($profile.supported_targets | ForEach-Object { [string]$_ })
    $candidateTargets = @($facts.supported_targets | ForEach-Object { [string]$_ })
    if (@($candidateTargets | Sort-Object -Unique -CaseSensitive).Count -ne $candidateTargets.Count) { Throw-CompatibilityRule -Id 'COMP02-DUPLICATE-RECORD' -Message 'candidate supported targets are duplicated.' }
    foreach ($target in $baselineTargets) { if ($candidateTargets -cnotcontains $target) { Add-CompatibilityChange $factChanges "supported-target-removed:$target" } }
    foreach ($target in $candidateTargets) { if ($baselineTargets -cnotcontains $target) { Add-CompatibilityChange $factChanges "supported-target-added:$target" } }
    foreach ($name in @('moon','moonc','moonrun')) {
      if ([string]$facts.minimum_toolchain.$name -cne [string]$profile.minimum_toolchain.$name) { Add-CompatibilityChange $factChanges "minimum-toolchain:$name" }
    }
    foreach ($module in @('mb-core','mb-color','mb-image')) {
      $expectedNames = @($profile.dependency_floors.$module.PSObject.Properties | ForEach-Object { $_.Name } | Sort-Object -CaseSensitive)
      $actualNames = @($facts.dependency_floors.$module.PSObject.Properties | ForEach-Object { $_.Name } | Sort-Object -CaseSensitive)
      if (($expectedNames -join "`n") -cne ($actualNames -join "`n")) { Add-CompatibilityChange $factChanges "dependency-floor-set:$module"; continue }
      foreach ($name in $expectedNames) { if ([string]$facts.dependency_floors.$module.$name -cne [string]$profile.dependency_floors.$module.$name) { Add-CompatibilityChange $factChanges "dependency-floor:${module}:$name" } }
    }
    if (@($removed).Count -ne 0) { $null = $classificationRules.Add('COMP02-DECLARATION-REMOVED') }
    if (@($changed | Where-Object { $_ -clike 'visibility:*' }).Count -ne 0) { $null = $classificationRules.Add('COMP02-VISIBILITY-CHANGED') }
    if (@($changed | Where-Object { $_ -clike 'declaration:*' }).Count -ne 0) { $null = $classificationRules.Add('COMP02-DECLARATION-CHANGED') }
    if (@($changed | Where-Object { $_ -clike 'import:*' }).Count -ne 0) { $null = $classificationRules.Add('COMP02-IMPORT-CHANGED') }
    if (@($factChanges | Where-Object { $_ -clike 'supported-target-removed:*' }).Count -ne 0) { $null = $classificationRules.Add('COMP02-SUPPORTED-TARGET-REMOVED') }
    if (@($factChanges | Where-Object { $_ -clike 'minimum-toolchain:*' }).Count -ne 0) { $null = $classificationRules.Add('COMP03-MINIMUM-TOOLCHAIN-DRIFT') }
    if (@($factChanges | Where-Object { $_ -clike 'dependency-floor*' }).Count -ne 0) { $null = $classificationRules.Add('COMP03-DEPENDENCY-FLOOR-DRIFT') }
    $incompatible = $removed.Count -gt 0 -or $changed.Count -gt 0 -or @($factChanges | Where-Object { $_ -notlike 'supported-target-added:*' }).Count -gt 0
    if ($incompatible) { $classification = 'incompatible' }
    elseif ($added.Count -gt 0 -or $factChanges.Count -gt 0) {
      $classification = 'additive'
      $null = $classificationRules.Add('COMP02-CLASS-ADDITIVE')
      if (@($factChanges | Where-Object { $_ -clike 'supported-target-added:*' }).Count -ne 0) { $null = $classificationRules.Add('COMP02-SUPPORTED-TARGET-ADDED') }
    } else { $classification = 'exact'; $null = $classificationRules.Add('COMP02-CLASS-EXACT') }
    $classPolicy = $policy.version_rules.$classification
    if ($classPolicy.release_allowed -ne $true) { $null = $blockingRules.Add('COMP02-INTERRUPTED-RESULT') }
    if (-not (Test-VersionSufficient -Baseline $baselineSemVer -Candidate $candidateSemVer -MinimumIncrement ([string]$classPolicy.minimum_increment))) { $null = $blockingRules.Add('COMP03-VERSION-INSUFFICIENT') }
    if ($classPolicy.changelog_required -eq $true -and $facts.evidence.changelog_present -ne $true) { $null = $blockingRules.Add('COMP04-CHANGELOG-REQUIRED') }
    elseif ([string]$facts.evidence.change_class -cne $classification) { $null = $blockingRules.Add('COMP04-CHANGE-CLASS-MISMATCH') }
    if ($classPolicy.added_surface_report_required -eq $true -and $facts.evidence.added_surface_report_present -ne $true) { $null = $blockingRules.Add('COMP04-ADDED-SURFACE-REPORT-REQUIRED') }
    if ($classPolicy.migration_required -eq $true -and $facts.evidence.migration_present -ne $true) { $null = $blockingRules.Add('COMP04-MIGRATION-REQUIRED') }
    $rfcImpacts = @($facts.evidence.rfc_impacts | ForEach-Object { [string]$_ })
    $triggeredImpacts = @($rfcImpacts | Where-Object { @($policy.rfc_condition.trigger_impacts | ForEach-Object { [string]$_ }) -ccontains $_ })
    if ($policy.rfc_condition.accepted_rfc_required_when_triggered -eq $true -and $triggeredImpacts.Count -gt 0 -and $facts.evidence.rfc_present -ne $true) { $null = $blockingRules.Add('COMP04-RFC-REQUIRED') }
    $releaseAuthorized = $blockingRules.Count -eq 0
  } catch {
    $message = $_.Exception.Message
    Write-Verbose "Compatibility classification failed closed: $message"
    $rule = if ($message -cmatch '^(?<id>COMP(?:02|03|04)-[A-Z0-9-]+):') { [string]$Matches.id } else { 'COMP02-INPUT-CLOSED' }
    $classification = 'unknown'; $releaseAuthorized = $false
    $null = $classificationRules.Add($rule); $null = $blockingRules.Add($rule)
    $rfcImpacts = if ($null -ne $facts) { @($facts.evidence.rfc_impacts | ForEach-Object { [string]$_ }) } else { @() }
  }
  $evidence = [ordered]@{
    changelog = ($null -ne $facts -and $facts.evidence.changelog_present -eq $true)
    added_surface_report = ($null -ne $facts -and $facts.evidence.added_surface_report_present -eq $true)
    migration = ($null -ne $facts -and $facts.evidence.migration_present -eq $true)
    rfc = ($null -ne $facts -and $facts.evidence.rfc_present -eq $true)
    rfc_impacts = @($rfcImpacts | Sort-Object -CaseSensitive)
  }
  return [pscustomobject][ordered]@{
    schema_version = 'mnf-public-compatibility-comparison/1'
    baseline_version = $baselineVersion
    candidate_version = $candidateVersion
    classification = $classification
    release_authorized = [bool]$releaseAuthorized
    classification_rule_ids = @($classificationRules | Sort-Object -CaseSensitive)
    blocking_rule_ids = @($blockingRules | Sort-Object -CaseSensitive)
    changes = [ordered]@{
      added = @($added | Sort-Object -CaseSensitive)
      removed = @($removed | Sort-Object -CaseSensitive)
      changed = @($changed | Sort-Object -CaseSensitive)
      fact_changes = @($factChanges | Sort-Object -CaseSensitive)
    }
    evidence = $evidence
    complete = ($null -ne $facts -and $facts.complete -eq $true -and $classification -cne 'unknown')
    claim_scope = $script:CompatibilityClaimScope
  }
}

function Assert-PublicCompatibilityAuthorized {
  param([Parameter(Mandatory)]$Result)
  if ($Result.release_authorized -ne $true) {
    $id = if (@($Result.blocking_rule_ids).Count -gt 0) { [string]$Result.blocking_rule_ids[0] } else { 'COMP02-INTERRUPTED-RESULT' }
    Throw-CompatibilityRule -Id $id -Message "public compatibility release gate rejected class '$($Result.classification)'."
  }
}

if ($LibraryMode) { return }
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
if ([string]::IsNullOrWhiteSpace($BaselineRoot)) { $BaselineRoot = Join-Path $repoRoot 'compatibility/baselines/0.1.0' }
if ([string]::IsNullOrWhiteSpace($PolicyPath)) { $PolicyPath = Join-Path $repoRoot 'policy/compatibility.json' }
if ([string]::IsNullOrWhiteSpace($CandidateRoot) -or [string]::IsNullOrWhiteSpace($CandidateReleasePath)) {
  Throw-CompatibilityRule -Id 'COMP02-INPUT-CLOSED' -Message 'CandidateRoot and CandidateReleasePath are required.'
}
$result = Invoke-PublicInterfaceComparison -BaselineRoot ([IO.Path]::GetFullPath($BaselineRoot)) -CandidateRoot ([IO.Path]::GetFullPath($CandidateRoot)) -CandidateReleasePath ([IO.Path]::GetFullPath($CandidateReleasePath)) -PolicyPath ([IO.Path]::GetFullPath($PolicyPath))
if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
  [IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath), (($result | ConvertTo-Json -Depth 100) + "`n"), [Text.UTF8Encoding]::new($false))
}
if (-not $ClassifyOnly) { Assert-PublicCompatibilityAuthorized -Result $result }
$result | ConvertTo-Json -Depth 100
