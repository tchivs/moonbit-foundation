[CmdletBinding()]
param(
  [switch]$Check,
  [switch]$StaticOnly,
  [switch]$IntentIntegrationOnly,
  [string]$PolicyPath = 'policy/release-qualification.json',
  [string]$OutputDirectory = 'artifacts/release-qualification/current'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')

if (-not $Check) { throw 'Release qualification is evidence-only and requires -Check.' }

$absolutePolicy = if ([IO.Path]::IsPathRooted($PolicyPath)) { $PolicyPath } else { Join-Path $repoRoot $PolicyPath }
$policy = Assert-ReleasePolicy `
  -PolicyPath $absolutePolicy `
  -FoundationPath (Join-Path $repoRoot 'policy\foundation.json') `
  -FixtureManifestPath (Join-Path $repoRoot 'fixtures\manifest.json') `
  -SchemaPath (Join-Path $repoRoot 'release\qualification\package-schema.json') `
  -RepoRoot $repoRoot

Write-Host 'Release policy: pass (closed modules, manifests, dependencies, contents, provenance, outcomes, and post-publication order).'
if ($StaticOnly) { return }

function Invoke-ReleaseNativeCommand {
  param(
    [Parameter(Mandatory)][string]$Context,
    [Parameter(Mandatory)][string]$Command,
    [Parameter(Mandatory)][string[]]$Arguments,
    [switch]$ExpectFailure
  )
  $output = @(& $Command @Arguments 2>&1 | ForEach-Object { $_.ToString().TrimEnd() })
  $exitCode = $LASTEXITCODE
  if (-not $ExpectFailure -and $exitCode -ne 0) { throw "$Context failed (exit $exitCode): $($output -join [Environment]::NewLine)" }
  if ($ExpectFailure -and $exitCode -eq 0) { throw "$Context unexpectedly succeeded." }
  return [pscustomobject]@{ exit_code = $exitCode; output = $output }
}

function New-CleanReleaseClone {
  param([string]$Destination, [string]$ExpectedHead)
  $null = Invoke-ReleaseNativeCommand -Context "clean clone $Destination" -Command 'git' -Arguments @('clone', '--quiet', '--no-hardlinks', $repoRoot, $Destination)
  $head = (& git -C $Destination rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0 -or $head -cne $ExpectedHead) { throw "Clean clone HEAD drifted: expected $ExpectedHead, got $head." }
  $status = @(& git -C $Destination status --porcelain=v1 --untracked-files=all)
  if ($LASTEXITCODE -ne 0 -or $status.Count -ne 0) { throw "Clean clone is not clean: $($status -join ', ')." }
  & git -C $Destination diff --quiet HEAD -- moon.work
  if ($LASTEXITCODE -ne 0) { throw 'Clean clone changed the checked moon.work.' }
  return [ordered]@{ head = $head; clean = $true; moon_work_unchanged = $true }
}

function Get-PackageList {
  param([object]$ModulePolicy, [string]$CopyRoot, [string]$ShortName)
  $result = Invoke-ReleaseNativeCommand -Context "package $ShortName" -Command 'moon' -Arguments @('-C', (Join-Path $CopyRoot "modules\$ShortName"), 'package', '--frozen', '--list')
  $expected = @($ModulePolicy.package_allowlist | ForEach-Object { [string]$_ })
  $actual = [Collections.Generic.List[string]]::new()
  foreach ($raw in @($result.output | Where-Object { $_ -ne '' })) {
    $line = [regex]::Replace([string]$raw, "`e\[[0-9;]*[A-Za-z]", '')
    $normalized = $line.Replace('\', '/')
    if ($expected -ccontains $normalized) { $actual.Add($normalized); continue }
    if ($line -ceq 'Running moon check ...' -or $line -ceq 'Check passed' -or
        $line -cmatch '^Finished[.] moon: .+$' -or $line -cmatch '^Package to .+[.]zip$') { continue }
    throw "Package list for $ShortName contained unrecognized output '$line'."
  }
  Assert-ReleaseExactSet -Label "$ShortName closed package inventory" -Actual @($actual) -Expected $expected
  return @($actual)
}

function Get-ZipEvidence {
  param([string]$ZipPath, [object]$ModulePolicy, [string]$SourceManifest)
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive = [IO.Compression.ZipFile]::OpenRead($ZipPath)
  try {
    $entries = [Collections.Generic.List[string]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($entry in $archive.Entries) {
      $name = $entry.FullName.Replace('\', '/').TrimEnd('/')
      if ([string]::IsNullOrEmpty($name) -or [IO.Path]::IsPathRooted($name) -or $name -match '(^|/)\.\.(/|$)') {
        throw "Archive contains an empty, absolute, or traversal entry: '$($entry.FullName)'."
      }
      if (-not $seen.Add($name)) { throw "Archive contains duplicate normalized entry '$name'." }
      foreach ($pattern in @($policy.forbidden_archive_patterns)) { if ($name -match [string]$pattern) { throw "Archive contains forbidden entry '$name'." } }
      $entries.Add($name)
    }
    Assert-ReleaseExactSet -Label "archive entries for $($ModulePolicy.manifest.name)" -Actual @($entries) -Expected @($ModulePolicy.package_allowlist)
    $manifestEntry = @($archive.Entries | Where-Object { $_.FullName.Replace('\', '/').TrimEnd('/') -ceq 'moon.mod.json' })
    if ($manifestEntry.Count -ne 1) { throw 'Package archive must contain exactly one root moon.mod.json.' }
    $stream = $manifestEntry[0].Open()
    try {
      $memory = [IO.MemoryStream]::new()
      try { $stream.CopyTo($memory); $archiveManifestBytes = $memory.ToArray() } finally { $memory.Dispose() }
    } finally { $stream.Dispose() }
    $sourceBytes = [IO.File]::ReadAllBytes($SourceManifest)
    if (-not [Linq.Enumerable]::SequenceEqual([byte[]]$archiveManifestBytes, [byte[]]$sourceBytes)) { throw 'Packaged moon.mod.json bytes differ from committed source manifest.' }
    return [ordered]@{
      archive_entries = @($entries)
      sha256 = Get-ReleaseSha256 -Path $ZipPath
      size = (Get-Item -LiteralPath $ZipPath).Length
      manifest_exact = $true
    }
  } finally { $archive.Dispose() }
}

function Assert-ByteIdenticalFiles {
  param([string]$Left, [string]$Right, [string]$Label)
  $leftInfo = Get-Item -LiteralPath $Left
  $rightInfo = Get-Item -LiteralPath $Right
  if ($leftInfo.Length -ne $rightInfo.Length) { throw "$Label sizes differ." }
  $leftBytes = [IO.File]::ReadAllBytes($Left)
  $rightBytes = [IO.File]::ReadAllBytes($Right)
  if (-not [Linq.Enumerable]::SequenceEqual([byte[]]$leftBytes, [byte[]]$rightBytes)) { throw "$Label bytes differ." }
  Assert-ReleaseHashedArtifact -Path $Right -ExpectedSha256 (Get-ReleaseSha256 -Path $Left)
}

function Write-TempText {
  param([string]$Path, [string]$Text)
  $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path)
  [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Assert-CoreConsumerDefinition {
  $manifestPath = Join-Path $repoRoot 'qualification\consumers\mb-core\moon.mod.json'
  $consumer = Read-ReleaseJson -Path $manifestPath
  if ($consumer.name -cne 'mnf-qualification/mb-core-consumer' -or $consumer.version -cne '0.0.0' -or
      [string]$consumer.deps.'tchivs/mb-core' -cne '0.1.0') { throw 'mb-core consumer manifest must use the exact tchivs/mb-core 0.1.0 dependency.' }
  $raw = Get-Content -LiteralPath $manifestPath -Raw
  if ($raw -cmatch '"path"\s*:|(?:^|[\\/])[.][.](?:[\\/]|$)') { throw 'mb-core consumer manifest contains a path substitution.' }
}

function Invoke-CoreArtifactConsumer {
  param([string]$ZipPath, [string]$WorkingRoot)
  Assert-CoreConsumerDefinition
  $artifactRoot = Join-Path $WorkingRoot 'mb-core-artifact'
  [IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $artifactRoot)
  if (@(Get-ChildItem -LiteralPath $artifactRoot -Recurse -File -Filter 'moon.work').Count -ne 0) { throw 'Extracted core artifact unexpectedly contains moon.work.' }
  $consumerRoot = Join-Path $repoRoot 'qualification\consumers\mb-core\main'
  $consumerPackage = Join-Path $artifactRoot 'qualification-consumer'
  $null = New-Item -ItemType Directory -Force -Path $consumerPackage
  Copy-Item -LiteralPath (Join-Path $consumerRoot 'moon.pkg') -Destination $consumerPackage
  Copy-Item -LiteralPath (Join-Path $consumerRoot 'main.mbt') -Destination $consumerPackage
  foreach ($target in @($policy.required_targets)) {
    $null = Invoke-ReleaseNativeCommand -Context "core artifact consumer check $target" -Command 'moon' -Arguments @('-C', $artifactRoot, 'check', '--target', [string]$target, '--deny-warn', '--frozen', 'qualification-consumer')
    $null = Invoke-ReleaseNativeCommand -Context "core artifact consumer test $target" -Command 'moon' -Arguments @('-C', $artifactRoot, 'test', '--target', [string]$target, '--frozen', 'qualification-consumer')
  }
  return 'pass'
}

function Get-ConsumerPackageText {
  param([string[]]$Imports)
  $lines = [Collections.Generic.List[string]]::new()
  $lines.Add('import {')
  foreach ($import in $Imports) { $lines.Add('  "' + $import + '",') }
  $lines.Add('}')
  $lines.Add('')
  $lines.Add('supported_targets = "+js+wasm+wasm-gc+native"')
  return ($lines -join "`n") + "`n"
}

function Invoke-SourceIsolation {
  param([string]$ShortName, [string]$CloneRoot)
  & git -C $CloneRoot diff --quiet HEAD -- moon.work modules/mb-core/moon.mod.json modules/mb-color/moon.mod.json modules/mb-image/moon.mod.json
  if ($LASTEXITCODE -ne 0) { throw 'Source-isolation clone changed a workspace or module manifest.' }
  $consumerPath = Join-Path $CloneRoot "modules\$ShortName\qualification-consumer"
  $imports = @($policy.modules.$ShortName.public_packages | ForEach-Object { [string]$_ })
  Write-TempText -Path (Join-Path $consumerPath 'moon.pkg') -Text (Get-ConsumerPackageText -Imports $imports)
  Copy-Item -LiteralPath (Join-Path $repoRoot 'qualification\consumers\downstream-public\main.mbt') -Destination (Join-Path $consumerPath 'main.mbt')
  $moduleIndex = [Array]::IndexOf([object[]]@($policy.module_order), $ShortName)
  if ($moduleIndex -lt 1) { throw "Source-isolation module '$ShortName' is not a downstream module in the canonical order." }
  $dependencyOrder = @($policy.module_order | Select-Object -First ($moduleIndex + 1))
  foreach ($target in @($policy.required_targets)) {
    foreach ($dependency in $dependencyOrder) {
      $modulePrefix = "tchivs/$dependency/"
      foreach ($publicPackage in @($policy.modules.$dependency.public_packages)) {
        $packageName = [string]$publicPackage
        if (-not $packageName.StartsWith($modulePrefix, [StringComparison]::Ordinal)) {
          throw "Source-isolation package '$packageName' is outside canonical module '$dependency'."
        }
        $packagePath = "modules/$dependency/" + $packageName.Substring($modulePrefix.Length)
        $null = Invoke-ReleaseNativeCommand -Context "$ShortName source dependency $packageName check $target" -Command 'moon' -Arguments @(
          '-C', $CloneRoot, 'check', '--target', [string]$target, '--deny-warn', '--frozen', $packagePath
        )
      }
    }
    $packagePath = "modules/$ShortName/qualification-consumer"
    $null = Invoke-ReleaseNativeCommand -Context "$ShortName source consumer check $target" -Command 'moon' -Arguments @('-C', $CloneRoot, 'check', '--target', [string]$target, '--frozen', $packagePath)
    $null = Invoke-ReleaseNativeCommand -Context "$ShortName source consumer test $target" -Command 'moon' -Arguments @('-C', $CloneRoot, 'test', '--target', [string]$target, '--frozen', $packagePath)
  }
  & git -C $CloneRoot diff --quiet HEAD -- moon.work modules/mb-core/moon.mod.json modules/mb-color/moon.mod.json modules/mb-image/moon.mod.json
  if ($LASTEXITCODE -ne 0) { throw 'Source-isolation qualification rewrote a workspace or module manifest.' }
  return 'pass'
}

function Invoke-RegistryProbe {
  param([string]$ShortName, [string]$WorkingRoot)
  $probeRoot = Join-Path $WorkingRoot "$ShortName-registry-probe"
  $moduleName = [string]$policy.modules.$ShortName.manifest.name
  if ($moduleName -cne "tchivs/$ShortName" -or [string]$policy.modules.$ShortName.manifest.version -cne '0.1.0') {
    throw "$ShortName registry probe requires the exact canonical tchivs identity at 0.1.0."
  }
  $manifestObject = [ordered]@{
    name = "mnf-qualification/$ShortName-registry-probe"
    version = '0.0.0'
    license = 'Apache-2.0'
    'preferred-target' = 'native'
    'supported-targets' = '+js+wasm+wasm-gc+native'
    deps = [ordered]@{ $moduleName = '0.1.0' }
  }
  $manifestPath = Join-Path $probeRoot 'moon.mod.json'
  Write-TempText -Path $manifestPath -Text (($manifestObject | ConvertTo-Json -Depth 10) + "`n")
  Write-TempText -Path (Join-Path $probeRoot 'main\moon.pkg') -Text (Get-ConsumerPackageText -Imports @($policy.modules.$ShortName.public_packages | ForEach-Object { [string]$_ }))
  Copy-Item -LiteralPath (Join-Path $repoRoot 'qualification\consumers\downstream-public\main.mbt') -Destination (Join-Path $probeRoot 'main\main.mbt')
  if (Test-Path -LiteralPath (Join-Path $probeRoot 'moon.work')) { throw 'Registry probe must not contain moon.work.' }
  $before = Get-ReleaseSha256 -Path $manifestPath
  $probe = Invoke-ReleaseNativeCommand -Context "$ShortName unchanged registry probe" -Command 'moon' -Arguments @('-C', $probeRoot, 'check', '--target', 'native', '--frozen') -ExpectFailure
  if ((Get-ReleaseSha256 -Path $manifestPath) -cne $before) { throw "$ShortName registry probe rewrote its named-dependency manifest." }
  $text = $probe.output -join "`n"
  $escapedName = [regex]::Escape($moduleName)
  if ($text -notmatch "Failed to resolve registry dependency ``$escapedName``" -or $text -notmatch 'module was not found in the registry') {
    throw "$ShortName registry probe failed for an unrelated reason: $text"
  }
  return 'blocked_unpublished_namespace'
}

function Write-ReleaseReport {
  param([object]$Report, [string]$Directory)
  $absolute = if ([IO.Path]::IsPathRooted($Directory)) { $Directory } else { Join-Path $repoRoot $Directory }
  $null = New-Item -ItemType Directory -Force -Path $absolute
  $path = Join-Path $absolute 'report.json'
  [IO.File]::WriteAllText($path, (($Report | ConvertTo-Json -Depth 100) + "`n"), [Text.UTF8Encoding]::new($false))
  return $path
}

function Assert-WrittenReleaseReport {
  param([string]$Path, [string]$ExpectedHead)
  $report = Read-ReleaseJson -Path $Path
  Assert-ReleaseClosedProperties -Label 'release report' -Object $report -Expected @(
    'schema_version', 'head', 'module_order', 'copies', 'modules', 'post_publish_order', 'publication', 'tracked_diff_unchanged'
  )
  if ($report.schema_version -cne '1.0.0' -or $report.head -cne $ExpectedHead -or $report.tracked_diff_unchanged -ne $true) {
    throw 'Release report identity or read-only evidence drifted.'
  }
  Assert-ReleaseExactSequence -Label 'report module order' -Actual @($report.module_order) -Expected @($policy.module_order)
  Assert-ReleaseExactSequence -Label 'report post-publication order' -Actual @($report.post_publish_order) -Expected @($policy.post_publish_order)
  Assert-ReleaseClosedProperties -Label 'report copies' -Object $report.copies -Expected @('copy_a', 'copy_b')
  foreach ($copy in @($report.copies.copy_a, $report.copies.copy_b)) {
    Assert-ReleaseClosedProperties -Label 'report clean copy' -Object $copy -Expected @('head', 'clean', 'moon_work_unchanged')
    if ($copy.head -cne $ExpectedHead -or $copy.clean -ne $true -or $copy.moon_work_unchanged -ne $true) { throw 'Release report clean-copy evidence drifted.' }
  }
  Assert-ReleaseClosedProperties -Label 'report modules' -Object $report.modules -Expected @('mb-core', 'mb-color', 'mb-image')
  foreach ($shortName in @($policy.module_order)) {
    $module = $report.modules.$shortName
    $package = $module.package
    Assert-ReleaseExactSequence -Label "$shortName report ordered list" -Actual @($package.ordered_list) -Expected @($moduleReports[$shortName].package.ordered_list)
    Assert-ReleaseExactSequence -Label "$shortName report archive entries" -Actual @($package.archive_entries) -Expected @($moduleReports[$shortName].package.archive_entries)
    if ([string]$package.sha256 -cnotmatch '^[0-9a-f]{64}$' -or [Int64]$package.size -le 0 -or
        $package.zip_bytes_equal -ne $true -or $package.manifest_exact -ne $true) { throw "$shortName report package evidence is incomplete." }
  }
  if ($report.modules.'mb-core'.artifact_consumer -cne 'pass' -or
      $report.modules.'mb-color'.source_isolation -cne 'pass' -or $report.modules.'mb-image'.source_isolation -cne 'pass' -or
      $report.modules.'mb-color'.registry_resolution -cne 'blocked_unpublished_namespace' -or
      $report.modules.'mb-image'.registry_resolution -cne 'blocked_unpublished_namespace' -or
      $report.modules.'mb-color'.artifact_consumer -cne 'blocked_unpublished_dependency' -or
      $report.modules.'mb-image'.artifact_consumer -cne 'blocked_unpublished_dependency') {
    throw 'Release report fabricated or omitted a consumer outcome.'
  }
  if ($report.publication.performed -ne $false -or $report.publication.credentials_read -ne $false -or
      $report.publication.namespace_verified -ne $false -or $report.publication.blocked_reason -cne 'unverified_mooncakes_owner_namespace') {
    throw 'Release report fabricated publication, credential, or namespace evidence.'
  }
}

function Write-InitialReleaseIntentBinding {
  param(
    [Parameter(Mandatory)][object]$ReleaseReport,
    [Parameter(Mandatory)][string]$SourceRoot,
    [Parameter(Mandatory)][string]$Directory
  )
  $absolute = if ([IO.Path]::IsPathRooted($Directory)) { [IO.Path]::GetFullPath($Directory) } else { [IO.Path]::GetFullPath((Join-Path $repoRoot $Directory)) }
  $null = New-Item -ItemType Directory -Force -Path $absolute
  $phase06LedgerPath = Join-Path $repoRoot 'release\qualification\phase-06-requirements.json'
  $interfaceManifestPath = Join-Path $repoRoot 'compatibility\baselines\0.1.0\manifest.json'
  $releaseStableText = $ReleaseReport | ConvertTo-Json -Depth 100 -Compress
  $qualificationRoot = Get-ReleaseTextSha256 -Text $releaseStableText
  $phase06Digest = Get-ReleaseSha256 -Path $phase06LedgerPath
  $interfaceDigest = Get-ReleaseSha256 -Path $interfaceManifestPath
  $requiredProjection = [ordered]@{
    release_qualification_sha256 = $qualificationRoot
    phase_06_ledger_sha256 = $phase06Digest
    interface_manifest_sha256 = $interfaceDigest
  }
  $requiredStable = Get-ReleaseTextSha256 -Text ($requiredProjection | ConvertTo-Json -Depth 10 -Compress)
  $archives = [ordered]@{}
  foreach ($shortName in @($policy.module_order)) {
    $digest = [string]$ReleaseReport.modules.$shortName.package.sha256
    if ($digest -cnotmatch '^[0-9a-f]{64}$') { Throw-ReleaseRule -Id 'REL01-EVIDENCE' -Message "qualified archive digest is missing for $shortName." }
    $archives[$shortName] = $digest
  }
  $intentResult = & (Join-Path $PSScriptRoot 'New-ReleaseIntent.ps1') `
    -Check -IntentKind initial -ReleaseRef 'refs/tags/modules-v0.1.0-r3' -SourceSha ([string]$ReleaseReport.head) -SourceRoot $SourceRoot `
    -QualificationRootSha256 $qualificationRoot -RequiredStableSha256 $requiredStable -ArchiveSha256ByModule $archives `
    -OutputDirectory (Join-Path $absolute 'intent')
  if ($intentResult.root_intent_sha256 -cne $intentResult.intent_sha256 -or $intentResult.credentials_read -ne $false -or $intentResult.publication_performed -ne $false) {
    Throw-ReleaseRule -Id 'REL01-INITIAL-ROOT-BINDING' -Message 'initial intent root/current or mutation boundary drifted.'
  }
  $intent = Read-ReleaseCanonicalJson -Path $intentResult.intent_path
  if ($null -ne $intent.PSObject.Properties['root_intent_sha256']) { Throw-ReleaseRule -Id 'REL01-HASH-CYCLE' -Message 'initial intent serialized its root digest.' }
  $binding = [ordered]@{
    schema_version = 'mnf-release-intent-binding/1'
    intent_kind = 'initial'
    release_ref = 'refs/tags/modules-v0.1.0-r3'
    source_sha = [string]$ReleaseReport.head
    root_intent_sha256 = [string]$intentResult.intent_sha256
    intent_sha256 = [string]$intentResult.intent_sha256
    qualification_root_sha256 = $qualificationRoot
    required_stable_sha256 = $requiredStable
    phase_06_ledger_sha256 = $phase06Digest
    interface_manifest_sha256 = $interfaceDigest
    credentials_read = $false
    publication_performed = $false
  }
  $bindingPath = Join-Path $absolute 'release-intent-binding.json'
  [IO.File]::WriteAllText($bindingPath, (($binding | ConvertTo-Json -Depth 10 -Compress)), [Text.UTF8Encoding]::new($false))
  return [pscustomobject]@{ binding_path = $bindingPath; intent_path = $intentResult.intent_path; intent_sha256 = $intentResult.intent_sha256 }
}

if ($IntentIntegrationOnly) {
  $integrationTemp = Join-Path ([IO.Path]::GetTempPath()) ('mnf-release-qualification-' + [Guid]::NewGuid().ToString('N'))
  $null = New-Item -ItemType Directory -Force -Path $integrationTemp
  try {
    $integrationSource = Join-Path $integrationTemp 'clean-source'
    $head = (& git -C $repoRoot rev-parse HEAD).Trim()
    $null = New-CleanReleaseClone -Destination $integrationSource -ExpectedHead $head
    $fixtureReport = [ordered]@{
      schema_version = '1.0.0'
      head = $head
      module_order = @($policy.module_order)
      modules = [ordered]@{
        'mb-core' = [ordered]@{ package = [ordered]@{ sha256 = ('1' * 64) } }
        'mb-color' = [ordered]@{ package = [ordered]@{ sha256 = ('2' * 64) } }
        'mb-image' = [ordered]@{ package = [ordered]@{ sha256 = ('3' * 64) } }
      }
      publication = [ordered]@{ performed = $false; credentials_read = $false; namespace_verified = $false; blocked_reason = 'unverified_mooncakes_owner_namespace' }
      tracked_diff_unchanged = $true
    }
    return Write-InitialReleaseIntentBinding -ReleaseReport $fixtureReport -SourceRoot $integrationSource -Directory $OutputDirectory
  } finally { Remove-ReleaseTemp -Path $integrationTemp }
}

$initialDiff = Get-ReleaseTrackedDiffSnapshot
$head = (& git -C $repoRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $head -cnotmatch '^[0-9a-f]{40}$') { throw 'Unable to identify the committed release-qualification HEAD.' }
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-release-qualification-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Force -Path $tempRoot
try {
  $copyA = Join-Path $tempRoot 'copy-a'
  $copyB = Join-Path $tempRoot 'copy-b'
  $copySource = Join-Path $tempRoot 'source-isolation'
  $copyAEvidence = New-CleanReleaseClone -Destination $copyA -ExpectedHead $head
  $copyBEvidence = New-CleanReleaseClone -Destination $copyB -ExpectedHead $head
  $null = New-CleanReleaseClone -Destination $copySource -ExpectedHead $head
  $moduleReports = [ordered]@{}

  foreach ($shortName in @($policy.module_order)) {
    $modulePolicy = $policy.modules.$shortName
    $listA = Get-PackageList -ModulePolicy $modulePolicy -CopyRoot $copyA -ShortName $shortName
    $listB = Get-PackageList -ModulePolicy $modulePolicy -CopyRoot $copyB -ShortName $shortName
    Assert-ReleaseExactSequence -Label "$shortName clean-copy package lists" -Actual $listA -Expected $listB
    $archiveName = ([string]$modulePolicy.manifest.name).Replace('/', '-') + '-' + [string]$modulePolicy.manifest.version + '.zip'
    $zipA = Join-Path $copyA "_build\publish\$archiveName"
    $zipB = Join-Path $copyB "_build\publish\$archiveName"
    if (-not (Test-Path -LiteralPath $zipA -PathType Leaf) -or -not (Test-Path -LiteralPath $zipB -PathType Leaf)) { throw "$shortName package ZIP is missing." }
    Assert-ByteIdenticalFiles -Left $zipA -Right $zipB -Label "$shortName clean-copy ZIP"
    $zipEvidenceA = Get-ZipEvidence -ZipPath $zipA -ModulePolicy $modulePolicy -SourceManifest (Join-Path $copyA "modules\$shortName\moon.mod.json")
    $zipEvidenceB = Get-ZipEvidence -ZipPath $zipB -ModulePolicy $modulePolicy -SourceManifest (Join-Path $copyB "modules\$shortName\moon.mod.json")
    if ($zipEvidenceA.sha256 -cne $zipEvidenceB.sha256 -or $zipEvidenceA.size -ne $zipEvidenceB.size) { throw "$shortName ZIP hash or size differs across clean copies." }
    $packageReport = [ordered]@{
      ordered_list = $listA
      archive_entries = $zipEvidenceA.archive_entries
      sha256 = $zipEvidenceA.sha256
      size = $zipEvidenceA.size
      zip_bytes_equal = $true
      manifest_exact = $true
    }
    if ($shortName -ceq 'mb-core') {
      $moduleReports[$shortName] = [ordered]@{
        package = $packageReport
        artifact_consumer = Invoke-CoreArtifactConsumer -ZipPath $zipA -WorkingRoot $tempRoot
        registry_resolution = 'not_required_no_dependencies'
      }
    } else {
      $moduleReports[$shortName] = [ordered]@{
        package = $packageReport
        source_isolation = Invoke-SourceIsolation -ShortName $shortName -CloneRoot $copySource
        artifact_consumer = 'blocked_unpublished_dependency'
        registry_resolution = Invoke-RegistryProbe -ShortName $shortName -WorkingRoot $tempRoot
      }
    }
    Write-Host "$shortName package: list/hash/bytes/archive/manifest pass ($($zipEvidenceA.sha256), $($zipEvidenceA.size) bytes)."
  }

  $finalDiff = Get-ReleaseTrackedDiffSnapshot
  Assert-ReleaseTrackedSnapshot -Before $initialDiff -After $finalDiff
  $report = [ordered]@{
    schema_version = '1.0.0'
    head = $head
    module_order = @($policy.module_order)
    copies = [ordered]@{ copy_a = $copyAEvidence; copy_b = $copyBEvidence }
    modules = $moduleReports
    post_publish_order = @($policy.post_publish_order)
    publication = [ordered]@{
      performed = $false
      credentials_read = $false
      namespace_verified = $false
      blocked_reason = 'unverified_mooncakes_owner_namespace'
    }
    tracked_diff_unchanged = $true
  }
  $reportPath = Write-ReleaseReport -Report $report -Directory $OutputDirectory
  Assert-WrittenReleaseReport -Path $reportPath -ExpectedHead $head
  Assert-ReleaseCandidateOutcomes -ReportPath $reportPath
  $intentSource = Join-Path $tempRoot 'intent-source'
  $null = New-CleanReleaseClone -Destination $intentSource -ExpectedHead $head
  $intentBinding = Write-InitialReleaseIntentBinding -ReleaseReport $report -SourceRoot $intentSource -Directory $OutputDirectory
  Write-Host "Release qualification report: $reportPath"
  Write-Host "Release intent binding: $($intentBinding.binding_path) ($($intentBinding.intent_sha256))"
  Write-Host 'Post-publication contract: mb-core publish/resolve, then mb-color publish/resolve, then mb-image publish/resolve.'
} finally {
  Remove-ReleaseTemp -Path $tempRoot
}
