[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Compare-PublicInterfaceBaseline.ps1') -LibraryMode

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$baselineRoot = Join-Path $repoRoot 'compatibility/baselines/0.1.0'
$policyPath = Join-Path $repoRoot 'policy/compatibility.json'
$schemaPath = Join-Path $repoRoot 'compatibility/schema/comparison-schema.json'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-public-compatibility-' + [guid]::NewGuid().ToString('N'))
$utf8 = [Text.UTF8Encoding]::new($false)

function Write-TestJson {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)]$Value)
  [IO.File]::WriteAllText($Path, (($Value | ConvertTo-Json -Depth 100) + "`n"), $utf8)
}

function Get-TestTreeDigest {
  param([Parameter(Mandatory)][string]$Root)
  return (@(Get-ChildItem -LiteralPath $Root -Recurse -File | Sort-Object FullName | ForEach-Object {
    ([IO.Path]::GetRelativePath($Root, $_.FullName).Replace('\','/') + '=' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant())
  }) -join "`n")
}

function Get-TrackedSnapshot {
  $lines = @(& git -C $repoRoot diff --binary --no-ext-diff HEAD -- 2>&1 | ForEach-Object { $_.ToString() })
  if ($LASTEXITCODE -ne 0) { throw 'Unable to capture tracked source snapshot.' }
  return ($lines -join "`n")
}

function New-DefaultFacts {
  return [pscustomobject][ordered]@{
    schema_version = 'mnf-public-compatibility-candidate/1'
    complete = $true
    baseline_version = '0.1.0'
    candidate_version = '0.1.1'
    supported_targets = @('js','wasm','wasm-gc','native')
    minimum_toolchain = [pscustomobject][ordered]@{ moon = '0.1.20260713'; moonc = '0.10.4'; moonrun = '0.1.20260713' }
    dependency_floors = [pscustomobject][ordered]@{
      'mb-core' = [pscustomobject][ordered]@{}
      'mb-color' = [pscustomobject][ordered]@{ 'tchivs/mb-core' = '0.1.0' }
      'mb-image' = [pscustomobject][ordered]@{
        'tchivs/mb-core' = '0.1.0'
        'tchivs/mb-color' = '0.1.0'
      }
    }
    evidence = [pscustomobject][ordered]@{
      changelog_present = $true
      change_class = 'exact'
      added_surface_report_present = $false
      migration_present = $false
      rfc_present = $false
      rfc_impacts = @()
    }
  }
}

function New-TestCase {
  param([Parameter(Mandatory)][string]$Name)
  $root = Join-Path $tempRoot $Name
  $candidate = Join-Path $root 'candidate'
  $null = New-Item -ItemType Directory -Path $root -Force
  Copy-Item -LiteralPath $baselineRoot -Destination $candidate -Recurse
  $facts = New-DefaultFacts
  $factsPath = Join-Path $root 'candidate-release.json'
  Write-TestJson -Path $factsPath -Value $facts
  return [pscustomobject]@{ name = $Name; root = $root; candidate = $candidate; facts = $facts; facts_path = $factsPath }
}

function Save-TestFacts {
  param([Parameter(Mandatory)]$Case)
  Write-TestJson -Path $Case.facts_path -Value $Case.facts
}

function Update-FirstPackageInterfaces {
  param([Parameter(Mandatory)]$Case, [Parameter(Mandatory)][scriptblock]$Mutate, [string]$OnlyTarget)
  $manifestPath = Join-Path $Case.candidate 'manifest.json'
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -Depth 100
  $entry = $manifest.packages[0]
  $documentPath = Join-Path $Case.candidate ([string]$entry.baseline_path)
  $document = Get-Content -LiteralPath $documentPath -Raw | ConvertFrom-Json -Depth 100
  foreach ($record in @($document.records)) {
    if (-not [string]::IsNullOrEmpty($OnlyTarget) -and [string]$record.target -cne $OnlyTarget) { continue }
    $path = Join-Path $Case.candidate ([string]$record.normalized_path)
    $text = [IO.File]::ReadAllText($path, $utf8)
    $updated = [string](& $Mutate $text ([string]$record.target))
    [IO.File]::WriteAllText($path, $updated, $utf8)
    $record.normalized_sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
  }
  Write-TestJson -Path $documentPath -Value $document
  $entry.baseline_sha256 = (Get-FileHash -LiteralPath $documentPath -Algorithm SHA256).Hash.ToLowerInvariant()
  Write-TestJson -Path $manifestPath -Value $manifest
}

function Remove-CandidateTarget {
  param([Parameter(Mandatory)]$Case, [Parameter(Mandatory)][string]$Target)
  $manifestPath = Join-Path $Case.candidate 'manifest.json'
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -Depth 100
  $manifest.targets = @($manifest.targets | Where-Object { [string]$_ -cne $Target })
  $manifest.record_count = [int]$manifest.package_count * @($manifest.targets).Count
  foreach ($entry in @($manifest.packages)) {
    $documentPath = Join-Path $Case.candidate ([string]$entry.baseline_path)
    $document = Get-Content -LiteralPath $documentPath -Raw | ConvertFrom-Json -Depth 100
    $document.records = @($document.records | Where-Object { [string]$_.target -cne $Target })
    Write-TestJson -Path $documentPath -Value $document
    $entry.baseline_sha256 = (Get-FileHash -LiteralPath $documentPath -Algorithm SHA256).Hash.ToLowerInvariant()
  }
  Write-TestJson -Path $manifestPath -Value $manifest
  $Case.facts.supported_targets = @($Case.facts.supported_targets | Where-Object { [string]$_ -cne $Target })
  Save-TestFacts $Case
}

function Set-CandidateGenerationToolchain {
  param([Parameter(Mandatory)]$Case, [Parameter(Mandatory)][string]$Moon)
  $manifestPath = Join-Path $Case.candidate 'manifest.json'
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -Depth 100
  $manifest.toolchain.moon = $Moon
  foreach ($entry in @($manifest.packages)) {
    $documentPath = Join-Path $Case.candidate ([string]$entry.baseline_path)
    $document = Get-Content -LiteralPath $documentPath -Raw | ConvertFrom-Json -Depth 100
    $document.toolchain.moon = $Moon
    Write-TestJson -Path $documentPath -Value $document
    $entry.baseline_sha256 = (Get-FileHash -LiteralPath $documentPath -Algorithm SHA256).Hash.ToLowerInvariant()
  }
  Write-TestJson -Path $manifestPath -Value $manifest
}

function Invoke-TestCase {
  param([Parameter(Mandatory)]$Case, [string]$Baseline = $baselineRoot, [string]$Policy = $policyPath)
  return Invoke-PublicInterfaceComparison -BaselineRoot $Baseline -CandidateRoot $Case.candidate -CandidateReleasePath $Case.facts_path -PolicyPath $Policy
}

function Assert-ClassificationRule {
  param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)]$Result, [Parameter(Mandatory)][string]$Class, [Parameter(Mandatory)][string]$Rule)
  if ([string]$Result.classification -cne $Class -or @($Result.classification_rule_ids) -cnotcontains $Rule) {
    throw "Compatibility case '$Name' expected class '$Class' and rule '$Rule', got '$($Result.classification)' / '$(@($Result.classification_rule_ids) -join ',')'."
  }
  Write-Host "Compatibility class proved: $Name -> $Class ($Rule)"
}

function Assert-Authorized {
  param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)]$Result, [Parameter(Mandatory)][string]$Class)
  if ([string]$Result.classification -cne $Class -or $Result.release_authorized -ne $true -or @($Result.blocking_rule_ids).Count -ne 0) {
    throw "Compatibility positive '$Name' was not authorized as '$Class': $($Result | ConvertTo-Json -Compress -Depth 100)"
  }
  Assert-PublicCompatibilityAuthorized -Result $Result
  Write-Host "Compatibility positive authorized: $Name -> $Class"
}

function Assert-BlockedRule {
  param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)]$Result, [Parameter(Mandatory)][string]$Rule)
  if ($Result.release_authorized -ne $false -or @($Result.blocking_rule_ids) -cnotcontains $Rule) {
    throw "Compatibility negative '$Name' did not block under '$Rule': $($Result | ConvertTo-Json -Compress -Depth 100)"
  }
  $failure = $null
  try { Assert-PublicCompatibilityAuthorized -Result $Result } catch { $failure = $_.Exception.Message }
  if ([string]::IsNullOrEmpty($failure) -or $failure -cnotmatch '^COMP(?:02|03|04)-') {
    throw "Compatibility negative '$Name' did not fail the executable authorization gate."
  }
  Write-Host "Compatibility negative rejected: $Name ($Rule)"
}

$null = New-Item -ItemType Directory -Path $tempRoot -Force
$baselineDigestBefore = Get-TestTreeDigest $baselineRoot
$trackedBefore = Get-TrackedSnapshot
try {
  $policy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json -Depth 100
  $schema = Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json -Depth 100
  if ($schema.additionalProperties -ne $false -or $schema.properties.classification.enum.Count -ne 4 -or
      (@($schema.properties.classification.enum) -join ',') -cne 'exact,additive,incompatible,unknown') {
    throw 'Comparison schema is not a closed exact four-class contract.'
  }
  if ((@($policy.classification_precedence) -join ',') -cne 'unknown,incompatible,additive,exact') {
    throw 'Compatibility policy precedence is not unknown-first.'
  }
  if ([string]$policy.claim_scope -cnotmatch '^public-interface-text-and-declared-release-facts-only; no behavioral, semantic, resource, representation-layout, performance, or full compatibility claim$' -or
      [string]$schema.properties.claim_scope.const -cne [string]$policy.claim_scope) {
    throw 'Compatibility policy or result schema overclaims semantic compatibility.'
  }

  $case = New-TestCase 'positive-exact'
  Assert-Authorized 'exact' (Invoke-TestCase $case) 'exact'

  $case = New-TestCase 'positive-additive'
  Update-FirstPackageInterfaces $case { param($text,$target) $text + "`npub fn compatibility_added_surface() -> Unit`n" }
  $case.facts.candidate_version = '0.2.0'; $case.facts.evidence.change_class = 'additive'; $case.facts.evidence.added_surface_report_present = $true; Save-TestFacts $case
  Assert-Authorized 'additive' (Invoke-TestCase $case) 'additive'

  $case = New-TestCase 'positive-incompatible'
  Update-FirstPackageInterfaces $case { param($text,$target) $text.Replace('pub fn map_host_failure(String, String) -> CoreError','pub fn map_host_failure(String, String, String) -> CoreError') }
  $case.facts.candidate_version = '0.2.0'; $case.facts.evidence.change_class = 'incompatible'; $case.facts.evidence.migration_present = $true; Save-TestFacts $case
  Assert-Authorized 'incompatible ordinary API delta without RFC' (Invoke-TestCase $case) 'incompatible'

  $case = New-TestCase 'unknown-syntax'
  Update-FirstPackageInterfaces $case { param($text,$target) $text + "`nmystery syntax`n" }
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'unknown syntax' $result 'unknown' 'COMP02-UNKNOWN-SYNTAX'
  Assert-BlockedRule 'unknown syntax' $result 'COMP02-UNKNOWN-SYNTAX'

  $case = New-TestCase 'missing-baseline'
  $result = Invoke-TestCase $case (Join-Path $tempRoot 'does-not-exist')
  Assert-ClassificationRule 'missing baseline' $result 'unknown' 'COMP02-MISSING-BASELINE'
  Assert-BlockedRule 'missing baseline' $result 'COMP02-MISSING-BASELINE'

  $case = New-TestCase 'ambiguous-match'
  Update-FirstPackageInterfaces $case { param($text,$target) $text + "`npub fn map_host_failure(String, String) -> CoreError`n" }
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'ambiguous declaration match' $result 'unknown' 'COMP02-AMBIGUOUS-MATCH'
  Assert-BlockedRule 'ambiguous declaration match' $result 'COMP02-AMBIGUOUS-MATCH'

  $case = New-TestCase 'adjacent-overload-ambiguity'
  Update-FirstPackageInterfaces $case { param($text,$target) $text + "`npub fn map_host_failure(String, String, String) -> CoreError`n" }
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'adjacent overload ambiguity' $result 'unknown' 'COMP02-AMBIGUOUS-MATCH'
  Assert-BlockedRule 'adjacent overload ambiguity' $result 'COMP02-AMBIGUOUS-MATCH'

  $case = New-TestCase 'unknown-precedes-incompatible'
  Update-FirstPackageInterfaces $case { param($text,$target) $text.Replace('pub fn map_host_failure(String, String) -> CoreError','pub fn map_host_failure(String, String, String) -> CoreError') + "`nmystery syntax`n" }
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'unknown precedes incompatible evidence' $result 'unknown' 'COMP02-UNKNOWN-SYNTAX'
  Assert-BlockedRule 'unknown precedes incompatible evidence' $result 'COMP02-UNKNOWN-SYNTAX'

  $case = New-TestCase 'target-divergence'
  Update-FirstPackageInterfaces $case { param($text,$target) $text + "`npub fn js_only_surface() -> Unit`n" } -OnlyTarget js
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'target divergence' $result 'unknown' 'COMP02-TARGET-DIVERGENCE'
  Assert-BlockedRule 'target divergence' $result 'COMP02-TARGET-DIVERGENCE'

  $case = New-TestCase 'toolchain-mismatch'
  Set-CandidateGenerationToolchain $case 'moon unapproved'
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'generation toolchain mismatch' $result 'unknown' 'COMP02-TOOLCHAIN-MISMATCH'
  Assert-BlockedRule 'generation toolchain mismatch' $result 'COMP02-TOOLCHAIN-MISMATCH'

  $case = New-TestCase 'duplicate-record'
  $manifestPath = Join-Path $case.candidate 'manifest.json'; $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -Depth 100
  $entry = $manifest.packages[0]; $documentPath = Join-Path $case.candidate ([string]$entry.baseline_path); $document = Get-Content -LiteralPath $documentPath -Raw | ConvertFrom-Json -Depth 100
  $document.records[1].target = $document.records[0].target; Write-TestJson $documentPath $document; $entry.baseline_sha256 = (Get-FileHash $documentPath -Algorithm SHA256).Hash.ToLowerInvariant(); Write-TestJson $manifestPath $manifest
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'duplicate package-target record' $result 'unknown' 'COMP02-DUPLICATE-RECORD'
  Assert-BlockedRule 'duplicate package-target record' $result 'COMP02-DUPLICATE-RECORD'

  $case = New-TestCase 'unexpected-field'
  $case.facts | Add-Member -NotePropertyName unexpected -NotePropertyValue $true; Save-TestFacts $case
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'unexpected candidate field' $result 'unknown' 'COMP02-INPUT-CLOSED'
  Assert-BlockedRule 'unexpected candidate field' $result 'COMP02-INPUT-CLOSED'

  $case = New-TestCase 'interrupted-result'
  $case.facts.complete = $false; Save-TestFacts $case
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'interrupted result' $result 'unknown' 'COMP02-INTERRUPTED-RESULT'
  Assert-BlockedRule 'interrupted result' $result 'COMP02-INTERRUPTED-RESULT'

  $case = New-TestCase 'empty-candidate-inventory'
  $manifestPath = Join-Path $case.candidate 'manifest.json'; $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -Depth 100
  $manifest.packages = @(); $manifest.package_count = 0; $manifest.record_count = 0; Write-TestJson $manifestPath $manifest
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'empty candidate inventory' $result 'unknown' 'COMP02-INCOMPLETE-CANDIDATE'
  Assert-BlockedRule 'empty candidate inventory' $result 'COMP02-INCOMPLETE-CANDIDATE'

  $case = New-TestCase 'declaration-removal'
  Update-FirstPackageInterfaces $case { param($text,$target) $text.Replace("pub fn map_host_failure(String, String) -> CoreError`r`n",'').Replace("pub fn map_host_failure(String, String) -> CoreError`n",'') }
  $case.facts.candidate_version = '0.2.0'; $case.facts.evidence.change_class = 'incompatible'; $case.facts.evidence.migration_present = $true; Save-TestFacts $case
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'declaration removal' $result 'incompatible' 'COMP02-DECLARATION-REMOVED'; Assert-Authorized 'declaration removal with evidence' $result 'incompatible'

  $case = New-TestCase 'signature-change'
  Update-FirstPackageInterfaces $case { param($text,$target) $text.Replace('pub fn map_host_failure(String, String) -> CoreError','pub fn map_host_failure(String, String, String) -> CoreError') }
  $case.facts.candidate_version = '0.2.0'; $case.facts.evidence.change_class = 'incompatible'; $case.facts.evidence.migration_present = $true; Save-TestFacts $case
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'signature change' $result 'incompatible' 'COMP02-DECLARATION-CHANGED'; Assert-Authorized 'signature change with evidence' $result 'incompatible'

  $case = New-TestCase 'visibility-change'
  Update-FirstPackageInterfaces $case { param($text,$target) $text.Replace('pub fn map_host_failure(String, String) -> CoreError','priv fn map_host_failure(String, String) -> CoreError') }
  $case.facts.candidate_version = '0.2.0'; $case.facts.evidence.change_class = 'incompatible'; $case.facts.evidence.migration_present = $true; Save-TestFacts $case
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'visibility change' $result 'incompatible' 'COMP02-VISIBILITY-CHANGED'; Assert-Authorized 'visibility change with evidence' $result 'incompatible'

  $case = New-TestCase 'target-removal'
  Remove-CandidateTarget $case native
  $case.facts.candidate_version = '0.2.0'; $case.facts.evidence.change_class = 'incompatible'; $case.facts.evidence.migration_present = $true; Save-TestFacts $case
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'supported target removal' $result 'incompatible' 'COMP02-SUPPORTED-TARGET-REMOVED'; Assert-Authorized 'target removal with migration' $result 'incompatible'

  $case = New-TestCase 'minimum-toolchain-drift'
  $case.facts.minimum_toolchain.moon = '0.1.20260714'; $case.facts.candidate_version = '0.2.0'; $case.facts.evidence.change_class = 'incompatible'; $case.facts.evidence.migration_present = $true; Save-TestFacts $case
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'minimum toolchain drift' $result 'incompatible' 'COMP03-MINIMUM-TOOLCHAIN-DRIFT'; Assert-Authorized 'minimum toolchain drift with migration' $result 'incompatible'

  $case = New-TestCase 'dependency-floor-drift'
  $case.facts.dependency_floors.'mb-color'.'tchivs/mb-core' = '0.2.0'; $case.facts.candidate_version = '0.2.0'; $case.facts.evidence.change_class = 'incompatible'; $case.facts.evidence.migration_present = $true; Save-TestFacts $case
  $result = Invoke-TestCase $case
  Assert-ClassificationRule 'dependency floor drift' $result 'incompatible' 'COMP03-DEPENDENCY-FLOOR-DRIFT'; Assert-Authorized 'dependency floor drift with migration' $result 'incompatible'

  $case = New-TestCase 'insufficient-additive-bump'
  Update-FirstPackageInterfaces $case { param($text,$target) $text + "`npub fn insufficient_bump_surface() -> Unit`n" }
  $case.facts.evidence.change_class = 'additive'; $case.facts.evidence.added_surface_report_present = $true; Save-TestFacts $case
  Assert-BlockedRule 'additive patch bump' (Invoke-TestCase $case) 'COMP03-VERSION-INSUFFICIENT'

  $case = New-TestCase 'incompatible-patch-bump'
  Update-FirstPackageInterfaces $case { param($text,$target) $text.Replace('pub fn map_host_failure(String, String) -> CoreError','pub fn map_host_failure(String, String, String) -> CoreError') }
  $case.facts.evidence.change_class = 'incompatible'; $case.facts.evidence.migration_present = $true; Save-TestFacts $case
  Assert-BlockedRule 'incompatible patch bump' (Invoke-TestCase $case) 'COMP03-VERSION-INSUFFICIENT'

  $case = New-TestCase 'noncanonical-version'
  $case.facts.candidate_version = '00.1.1'; Save-TestFacts $case
  Assert-BlockedRule 'leading-zero version' (Invoke-TestCase $case) 'COMP03-VERSION-NONCANONICAL'

  $case = New-TestCase 'big-integer-version'
  $case.facts.candidate_version = '999999999999999999999999999999999999.0.0'; Save-TestFacts $case
  Assert-Authorized 'arbitrary precision canonical version' (Invoke-TestCase $case) 'exact'

  $case = New-TestCase 'missing-changelog'
  $case.facts.evidence.changelog_present = $false; Save-TestFacts $case
  Assert-BlockedRule 'missing changelog' (Invoke-TestCase $case) 'COMP04-CHANGELOG-REQUIRED'

  $case = New-TestCase 'policy-owned-minimum-increment'
  $policyCopyPath = Join-Path $case.root 'compatibility-policy.json'
  $policyCopy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json -Depth 100
  $policyCopy.version_rules.exact.minimum_increment = 'minor'; Write-TestJson $policyCopyPath $policyCopy
  Assert-BlockedRule 'policy-owned exact minimum increment' (Invoke-TestCase $case -Policy $policyCopyPath) 'COMP03-VERSION-INSUFFICIENT'

  $case = New-TestCase 'change-class-mismatch'
  $case.facts.evidence.change_class = 'additive'; Save-TestFacts $case
  Assert-BlockedRule 'changelog class mismatch' (Invoke-TestCase $case) 'COMP04-CHANGE-CLASS-MISMATCH'

  $case = New-TestCase 'missing-added-surface-report'
  Update-FirstPackageInterfaces $case { param($text,$target) $text + "`npub fn undocumented_added_surface() -> Unit`n" }
  $case.facts.candidate_version = '0.2.0'; $case.facts.evidence.change_class = 'additive'; Save-TestFacts $case
  Assert-BlockedRule 'missing added-surface report' (Invoke-TestCase $case) 'COMP04-ADDED-SURFACE-REPORT-REQUIRED'

  $case = New-TestCase 'missing-migration'
  Update-FirstPackageInterfaces $case { param($text,$target) $text.Replace('pub fn map_host_failure(String, String) -> CoreError','pub fn map_host_failure(String, String, String) -> CoreError') }
  $case.facts.candidate_version = '0.2.0'; $case.facts.evidence.change_class = 'incompatible'; Save-TestFacts $case
  Assert-BlockedRule 'missing migration' (Invoke-TestCase $case) 'COMP04-MIGRATION-REQUIRED'

  $case = New-TestCase 'missing-conditional-rfc'
  Update-FirstPackageInterfaces $case { param($text,$target) $text.Replace('pub fn map_host_failure(String, String) -> CoreError','pub fn map_host_failure(String, String, String) -> CoreError') }
  $case.facts.candidate_version = '0.2.0'; $case.facts.evidence.change_class = 'incompatible'; $case.facts.evidence.migration_present = $true; $case.facts.evidence.rfc_impacts = @('boundary'); Save-TestFacts $case
  Assert-BlockedRule 'missing conditional RFC' (Invoke-TestCase $case) 'COMP04-RFC-REQUIRED'
  $case.facts.evidence.rfc_present = $true; Save-TestFacts $case
  Assert-Authorized 'conditional RFC supplied' (Invoke-TestCase $case) 'incompatible'

  $baselineDigestAfter = Get-TestTreeDigest $baselineRoot
  if ($baselineDigestBefore -cne $baselineDigestAfter) { throw 'Compatibility suite mutated the committed baseline fixtures.' }
  $trackedAfter = Get-TrackedSnapshot
  if ($trackedBefore -cne $trackedAfter) { throw 'Compatibility suite mutated tracked source.' }
  Write-Host 'Public compatibility suite passed: four classes, unknown-first precedence, version boundaries, evidence consequences, closed inputs, and immutable fixtures.'
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $full = [IO.Path]::GetFullPath($tempRoot)
    if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Split-Path -Leaf $full).StartsWith('mnf-public-compatibility-', [StringComparison]::Ordinal)) {
      throw "Refusing to remove unverified compatibility test path '$full'."
    }
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}
