[CmdletBinding(DefaultParameterSetName = 'Generate')]
param(
  [Parameter(ParameterSetName = 'Schema')][switch]$CheckSchema,
  [Parameter(ParameterSetName = 'Generate')][switch]$Check,
  [Parameter(ParameterSetName = 'Library')][switch]$LibraryMode,
  [Parameter(ParameterSetName = 'Generate')][string]$BaselineVersion = '0.1.0',
  [Parameter(ParameterSetName = 'Generate')][string]$OutputRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SchemaVersion = 'mnf-public-interface-baseline-package/1'
$script:NormalizationVersion = 'moon-mbti-lossless-lines/1'
$script:Targets = @('js', 'wasm', 'wasm-gc', 'native')
$script:ClaimScope = 'public-interface-text-only; no behavioral, semantic, resource, layout, or performance compatibility claim'
$script:Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Get-BaselineRepoRoot {
  [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
}

function Get-Sha256Hex {
  param([Parameter(Mandatory)][byte[]]$Bytes)
  return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()
}

function Write-AtomicUtf8 {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Text)
  $directory = Split-Path -Parent $Path
  $null = New-Item -ItemType Directory -Path $directory -Force
  $temporary = Join-Path $directory ('.' + [IO.Path]::GetFileName($Path) + '.' + [guid]::NewGuid().ToString('N') + '.tmp')
  try {
    [IO.File]::WriteAllText($temporary, $Text, $script:Utf8NoBom)
    [IO.File]::Move($temporary, $Path, $true)
  } finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
  }
}

function ConvertTo-StableJsonText {
  param([Parameter(Mandatory)]$Value)
  return (($Value | ConvertTo-Json -Depth 100) + "`n")
}

function Get-ToolchainIdentity {
  $root = Get-BaselineRepoRoot
  . (Join-Path $root 'scripts/quality/Assert-Toolchain.ps1')
  Assert-Toolchain -PolicyPath (Join-Path $root 'policy/foundation.json')
  $moon = @(& moon version 2>&1 | ForEach-Object { $_.ToString().TrimEnd() } | Where-Object { $_ })
  $moonc = @(& moonc -v 2>&1 | ForEach-Object { $_.ToString().TrimEnd() } | Where-Object { $_ })
  $moonrun = @(& moonrun --version 2>&1 | ForEach-Object { $_.ToString().TrimEnd() } | Where-Object { $_ })
  [ordered]@{ moon = $moon[0]; moonc = $moonc[0]; moonrun = $moonrun[0] }
}

function Get-PublicPackageInventory {
  param([Parameter(Mandatory)][string]$Root)
  $policy = Get-Content -LiteralPath (Join-Path $Root 'policy/release-qualification.json') -Raw | ConvertFrom-Json -Depth 100
  $items = [Collections.Generic.List[object]]::new()
  foreach ($module in @($policy.module_order)) {
    if ($module -cnotmatch '^mb-(core|color|image)$') { throw "Unknown module '$module' in release qualification policy." }
    $entry = $policy.modules.$module
    foreach ($package in @($entry.public_packages)) {
      $packageName = [string]$package
      $prefix = "moonbit-foundation/$module/"
      if (-not $packageName.StartsWith($prefix, [StringComparison]::Ordinal)) { throw "Unsafe package '$packageName'." }
      $leaf = $packageName.Substring($prefix.Length)
      if ($leaf -cnotmatch '^[a-z][a-z0-9-]*$') { throw "Unsafe package leaf '$leaf'." }
      $items.Add([pscustomobject][ordered]@{ module = [string]$module; package = $packageName; leaf = $leaf })
    }
  }
  if ($items.Count -ne 17) { throw "Public package inventory has $($items.Count) records; expected 17." }
  return $items.ToArray()
}

function Convert-MbtiToNormalizedText {
  param([Parameter(Mandatory)][byte[]]$Bytes, [Parameter(Mandatory)][string]$ExpectedPackage)
  $strictUtf8 = [Text.UTF8Encoding]::new($false, $true)
  try { $text = $strictUtf8.GetString($Bytes) } catch { throw "Unknown .mbti encoding for '$ExpectedPackage': expected UTF-8." }
  if ($text.Contains([char]0)) { throw "Unknown .mbti syntax for '$ExpectedPackage': NUL byte." }
  $normalizedInput = ($text -replace "`r`n", "`n") -replace "`r", "`n"
  $lines = @($normalizedInput.Split("`n"))
  if ($lines.Count -lt 2 -or $lines[0] -cne '// Generated using `moon info`, DON''T EDIT IT') { throw "Unknown .mbti header for '$ExpectedPackage'." }
  if ($lines[1] -cne "package `"$ExpectedPackage`"") { throw "Unknown .mbti package declaration for '$ExpectedPackage'." }
  $depth = 0
  for ($index = 2; $index -lt $lines.Count; $index++) {
    $line = $lines[$index].TrimEnd()
    $lines[$index] = $line
    if ($line -ceq '') { continue }
    if ($line -cmatch '^// (Values|Errors|Types and methods|Type aliases|Traits|private fields)$') { continue }
    if ($line -ceq 'import {') { if ($depth -ne 0) { throw "Unknown nested import at line $($index + 1)." }; $depth = 1; continue }
    if ($depth -eq 1 -and $line -cmatch '^  "moonbit-foundation/mb-(core|color|image)(/[a-z][a-z0-9-]*)?",$') { continue }
    if ($depth -eq 1 -and $line -ceq '}') { $depth = 0; continue }
    if ($depth -eq 0 -and $line -cmatch '^type [A-Z][A-Za-z0-9_]*(\[[^]]+\])?$') { continue }
    if ($depth -eq 0 -and $line -cmatch '^pub fn(?:\[[^]]+\])? .+$') { continue }
    if ($depth -eq 0 -and $line -cmatch '^pub impl .+$') { continue }
    if ($depth -eq 0 -and $line -cmatch '^pub(?:\((?:all|open)\))? (?:struct|enum|error|trait) [A-Z][A-Za-z0-9_]*(?:\[[^]]+\])?(?: .*)? \{$') { $depth = 2; continue }
    if ($depth -eq 2 -and $line -cmatch '^  // private fields$') { continue }
    if ($depth -eq 2 -and $line -cmatch '^  (?:fn |[A-Z_a-z@&]).*$') { continue }
    if ($depth -eq 2 -and $line -cmatch '^}(?: derive\([A-Za-z0-9_, ]+\))?$') { $depth = 0; continue }
    throw "Unknown .mbti syntax for '$ExpectedPackage' at line $($index + 1): '$line'."
  }
  if ($depth -ne 0) { throw "Unknown unterminated .mbti construct for '$ExpectedPackage'." }
  while ($lines.Count -gt 0 -and $lines[-1] -ceq '') { $lines = @($lines | Select-Object -First ($lines.Count - 1)) }
  return (($lines -join "`n") + "`n")
}

function Invoke-MoonInfo {
  param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Module, [Parameter(Mandatory)][string]$Target)
  $arguments = @('-C', "modules/$Module", 'info', '--target', $Target, '--frozen')
  Push-Location $Root
  try {
    $output = @(& moon @arguments 2>&1 | ForEach-Object { $_.ToString() })
    if ($LASTEXITCODE -ne 0) { throw "moon info failed for $Module/$Target`: $($output -join ' | ')" }
  } finally {
    Pop-Location
  }
}

function New-CleanArchiveCopy {
  param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$Commit, [Parameter(Mandatory)][string]$Destination)
  $zip = "$Destination.zip"
  try {
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $Destination) -Force
    & git -C $RepoRoot archive --format=zip $Commit -o $zip
    if ($LASTEXITCODE -ne 0) { throw "git archive failed for '$Commit'." }
    $null = New-Item -ItemType Directory -Path $Destination -Force
    Expand-Archive -LiteralPath $zip -DestinationPath $Destination
  } finally {
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
  }
}

function New-GeneratedBaselineTree {
  param(
    [Parameter(Mandatory)][string]$SourceRoot,
    [Parameter(Mandatory)][string]$Destination,
    [Parameter(Mandatory)][string]$SourceCommit,
    [Parameter(Mandatory)]$Toolchain
  )
  $inventory = @(Get-PublicPackageInventory -Root $SourceRoot)
  $packages = [Collections.Generic.List[object]]::new()
  foreach ($module in @('mb-core', 'mb-color', 'mb-image')) {
    $moduleItems = @($inventory | Where-Object { $_.module -ceq $module })
    Invoke-MoonInfo -Root $SourceRoot -Module $module -Target 'all'
    $canonical = @{}
    foreach ($item in $moduleItems) {
      $rawFile = Join-Path $SourceRoot "modules/$module/$($item.leaf)/pkg.generated.mbti"
      if (-not (Test-Path -LiteralPath $rawFile -PathType Leaf)) { throw "Missing canonical raw interface '$rawFile'." }
      $bytes = [IO.File]::ReadAllBytes($rawFile)
      $canonical[$item.package] = [pscustomobject]@{ bytes = $bytes; sha = Get-Sha256Hex $bytes; normalized = Convert-MbtiToNormalizedText -Bytes $bytes -ExpectedPackage $item.package }
    }
    $inspections = @{}
    foreach ($target in $script:Targets) {
      Invoke-MoonInfo -Root $SourceRoot -Module $module -Target $target
      foreach ($item in $moduleItems) {
        $rawFile = Join-Path $SourceRoot "modules/$module/$($item.leaf)/pkg.generated.mbti"
        if (-not (Test-Path -LiteralPath $rawFile -PathType Leaf)) { throw "Missing target inspection interface for $($item.package)/$target." }
        $bytes = [IO.File]::ReadAllBytes($rawFile)
        $sha = Get-Sha256Hex $bytes
        if ($sha -cne $canonical[$item.package].sha) { throw "Target divergence is unknown for $($item.package)/$target; generation stopped." }
        $inspections["$($item.package)|$target"] = $sha
      }
    }
    foreach ($item in $moduleItems) {
      $relativeDirectory = "$module/$($item.leaf)"
      $rawRelative = "$relativeDirectory/raw.mbti"
      $rawOutput = Join-Path $Destination $rawRelative
      $null = New-Item -ItemType Directory -Path (Split-Path -Parent $rawOutput) -Force
      [IO.File]::WriteAllBytes($rawOutput, $canonical[$item.package].bytes)
      $records = [Collections.Generic.List[object]]::new()
      foreach ($target in $script:Targets) {
        $normalizedRelative = "$relativeDirectory/$target.mbti"
        $normalizedText = [string]$canonical[$item.package].normalized
        Write-AtomicUtf8 -Path (Join-Path $Destination $normalizedRelative) -Text $normalizedText
        $normalizedSha = Get-Sha256Hex ([Text.Encoding]::UTF8.GetBytes($normalizedText))
        $records.Add([pscustomobject][ordered]@{
          target = $target
          normalized_path = $normalizedRelative
          normalized_sha256 = $normalizedSha
          target_inspection = [pscustomobject][ordered]@{
            command = "moon -C modules/$module info --target $target --frozen"
            status = 'pass'
            raw_sha256 = $inspections["$($item.package)|$target"]
            matches_canonical = $true
          }
        })
      }
      $document = [pscustomobject][ordered]@{
        schema_version = $script:SchemaVersion
        normalization_schema_version = $script:NormalizationVersion
        source_commit = $SourceCommit
        toolchain = $Toolchain
        module = $module
        package = $item.package
        raw_path = $rawRelative
        raw_sha256 = $canonical[$item.package].sha
        records = $records.ToArray()
        two_run_equal = $true
        claim_scope = $script:ClaimScope
      }
      $baselineRelative = "$relativeDirectory/baseline.json"
      Write-AtomicUtf8 -Path (Join-Path $Destination $baselineRelative) -Text (ConvertTo-StableJsonText $document)
      $packages.Add([pscustomobject][ordered]@{
        module = $module; package = $item.package; baseline_path = $baselineRelative
        baseline_sha256 = Get-Sha256Hex ([IO.File]::ReadAllBytes((Join-Path $Destination $baselineRelative)))
        raw_path = $rawRelative; raw_sha256 = $canonical[$item.package].sha
      })
    }
  }
  $manifest = [pscustomobject][ordered]@{
    schema_version = 'mnf-public-interface-baseline-manifest/1'
    normalization_schema_version = $script:NormalizationVersion
    baseline_version = $BaselineVersion
    source_commit = $SourceCommit
    toolchain = $Toolchain
    targets = $script:Targets
    package_count = 17
    record_count = 68
    packages = $packages.ToArray()
    two_run_equal = $true
    claim_scope = $script:ClaimScope
  }
  Write-AtomicUtf8 -Path (Join-Path $Destination 'manifest.json') -Text (ConvertTo-StableJsonText $manifest)
}

function Get-TreeDigestMap {
  param([Parameter(Mandatory)][string]$Root)
  $map = [ordered]@{}
  foreach ($file in @(Get-ChildItem -LiteralPath $Root -Recurse -File | Sort-Object FullName)) {
    $relative = [IO.Path]::GetRelativePath($Root, $file.FullName).Replace('\', '/')
    $map[$relative] = Get-Sha256Hex ([IO.File]::ReadAllBytes($file.FullName))
  }
  return $map
}

function Assert-TreeMapsEqual {
  param([Parameter(Mandatory)]$First, [Parameter(Mandatory)]$Second)
  if (($First | ConvertTo-Json -Compress) -cne ($Second | ConvertTo-Json -Compress)) {
    throw 'Unstable second run: independently generated baseline trees differ.'
  }
}

function Assert-ExactBaselineInventory {
  param([Parameter(Mandatory)][string]$Root)
  $manifestPath = Join-Path $Root 'manifest.json'
  if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw 'Partial baseline output: manifest.json is missing.' }
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -Depth 100
  if ($manifest.package_count -ne 17 -or @($manifest.packages).Count -ne 17) { throw 'Baseline package inventory must contain exactly 17 packages.' }
  if ($manifest.record_count -ne 68) { throw 'Baseline record inventory must contain exactly 68 records.' }
  $pairs = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $policyInventory = @(Get-PublicPackageInventory -Root (Get-BaselineRepoRoot))
  $expectedFiles = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $null = $expectedFiles.Add('manifest.json')
  for ($packageIndex = 0; $packageIndex -lt @($manifest.packages).Count; $packageIndex++) {
    $package = @($manifest.packages)[$packageIndex]
    if ([string]$package.module -cne [string]$policyInventory[$packageIndex].module -or [string]$package.package -cne [string]$policyInventory[$packageIndex].package) {
      throw "Baseline package inventory order mismatch at index $packageIndex."
    }
    foreach ($property in @('baseline_path','raw_path')) { if ([string]$package.$property -cmatch '(^|/)[.]?([.])(/|$)|\\|^/') { throw "Unsafe baseline path '$($package.$property)'." } }
    foreach ($path in @([string]$package.baseline_path, [string]$package.raw_path)) { $null = $expectedFiles.Add($path) }
    $baselinePath = Join-Path $Root ([string]$package.baseline_path)
    $rawPath = Join-Path $Root ([string]$package.raw_path)
    if (-not (Test-Path -LiteralPath $baselinePath -PathType Leaf) -or -not (Test-Path -LiteralPath $rawPath -PathType Leaf)) { throw "Partial baseline output for '$($package.package)'." }
    if ((Get-Sha256Hex ([IO.File]::ReadAllBytes($baselinePath))) -cne [string]$package.baseline_sha256) { throw "Baseline digest drift for '$($package.package)'." }
    if ((Get-Sha256Hex ([IO.File]::ReadAllBytes($rawPath))) -cne [string]$package.raw_sha256) { throw "Raw digest drift for '$($package.package)'." }
    $document = Get-Content -LiteralPath $baselinePath -Raw | ConvertFrom-Json -Depth 100
    if ([string]$document.schema_version -cne $script:SchemaVersion -or [string]$document.normalization_schema_version -cne $script:NormalizationVersion) { throw "Baseline schema version mismatch for '$($package.package)'." }
    if ([string]$document.module -cne [string]$package.module -or [string]$document.package -cne [string]$package.package) { throw "Baseline identity mismatch for '$($package.package)'." }
    if ([string]$document.source_commit -cne [string]$manifest.source_commit) { throw "Source commit mismatch for '$($package.package)'." }
    if (@($document.records).Count -ne 4) { throw "Package '$($package.package)' does not contain exactly four records." }
    for ($recordIndex = 0; $recordIndex -lt 4; $recordIndex++) {
      $record = @($document.records)[$recordIndex]
      if ([string]$record.target -cne $script:Targets[$recordIndex]) { throw "Missing or out-of-order package-target pair for '$($document.package)' at index $recordIndex." }
      $pair = "$($document.package)|$($record.target)"
      if (-not $pairs.Add($pair)) { throw "Duplicate package-target pair '$pair'." }
      $null = $expectedFiles.Add([string]$record.normalized_path)
      $normalizedPath = Join-Path $Root ([string]$record.normalized_path)
      if (-not (Test-Path -LiteralPath $normalizedPath -PathType Leaf)) { throw "Missing normalized record '$pair'." }
      if ((Get-Sha256Hex ([IO.File]::ReadAllBytes($normalizedPath))) -cne [string]$record.normalized_sha256) { throw "Normalized digest drift for '$pair'." }
      if (-not $record.target_inspection.matches_canonical -or $record.target_inspection.raw_sha256 -cne $document.raw_sha256) { throw "Target divergence for '$pair'." }
      if (($document.toolchain | ConvertTo-Json -Compress) -cne ($manifest.toolchain | ConvertTo-Json -Compress)) { throw "Toolchain mismatch for '$pair'." }
    }
  }
  if ($pairs.Count -ne 68) { throw "Baseline has $($pairs.Count) unique package-target records; expected 68." }
  $actualFiles = @(Get-ChildItem -LiteralPath $Root -Recurse -File | ForEach-Object { [IO.Path]::GetRelativePath($Root, $_.FullName).Replace('\','/') })
  if ($actualFiles.Count -ne $expectedFiles.Count) { throw "Baseline file inventory count mismatch: expected $($expectedFiles.Count), got $($actualFiles.Count)." }
  foreach ($file in $actualFiles) { if (-not $expectedFiles.Contains($file)) { throw "Unmanifested baseline file '$file'." } }
  return $manifest
}

function Assert-BaselineSchemaContract {
  $root = Get-BaselineRepoRoot
  $schemaPath = Join-Path $root 'compatibility/schema/baseline-schema.json'
  $schema = Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json -Depth 100
  if ($schema.type -cne 'object' -or $schema.additionalProperties -ne $false) { throw 'Baseline schema root must be a closed object.' }
  if ($schema.properties.records.items.'$ref' -cne '#/$defs/record') { throw 'Baseline schema must bind records to the closed record definition.' }
  foreach ($definition in @('toolchain','inspection','record')) { if ($schema.'$defs'.$definition.additionalProperties -ne $false) { throw "Baseline schema definition '$definition' is not closed." } }
  Write-Host 'Baseline schema is valid JSON and closed at every object boundary.'
}

if ($LibraryMode) { return }
if ($CheckSchema) { Assert-BaselineSchemaContract; return }

$repoRoot = Get-BaselineRepoRoot
Push-Location $repoRoot
try {
  $destination = if ($OutputRoot) { [IO.Path]::GetFullPath($OutputRoot) } else { Join-Path $repoRoot "compatibility/baselines/$BaselineVersion" }
  $recordedCommit = $null
  if ($Check -and (Test-Path -LiteralPath (Join-Path $destination 'manifest.json'))) {
    $recordedCommit = [string]((Get-Content -LiteralPath (Join-Path $destination 'manifest.json') -Raw | ConvertFrom-Json -Depth 100).source_commit)
  } else {
    $recordedCommit = (& git rev-parse HEAD).Trim()
  }
  if ($recordedCommit -cnotmatch '^[0-9a-f]{40}$') { throw "Invalid source commit '$recordedCommit'." }
  $toolchain = Get-ToolchainIdentity
  $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-baseline-' + [guid]::NewGuid().ToString('N'))
  try {
    $copyA = Join-Path $temporaryRoot 'source-a'; $copyB = Join-Path $temporaryRoot 'source-b'
    $treeA = Join-Path $temporaryRoot 'tree-a'; $treeB = Join-Path $temporaryRoot 'tree-b'
    New-CleanArchiveCopy -RepoRoot $repoRoot -Commit $recordedCommit -Destination $copyA
    New-CleanArchiveCopy -RepoRoot $repoRoot -Commit $recordedCommit -Destination $copyB
    New-GeneratedBaselineTree -SourceRoot $copyA -Destination $treeA -SourceCommit $recordedCommit -Toolchain $toolchain
    New-GeneratedBaselineTree -SourceRoot $copyB -Destination $treeB -SourceCommit $recordedCommit -Toolchain $toolchain
    $mapA = Get-TreeDigestMap $treeA; $mapB = Get-TreeDigestMap $treeB
    Assert-TreeMapsEqual -First $mapA -Second $mapB
    $null = Assert-ExactBaselineInventory -Root $treeA
    if ($Check) {
      if (-not (Test-Path -LiteralPath $destination -PathType Container)) { throw "Baseline destination '$destination' is missing." }
      $currentMap = Get-TreeDigestMap $destination
      if (($mapA | ConvertTo-Json -Compress) -cne ($currentMap | ConvertTo-Json -Compress)) { throw 'Checked baseline differs from the reproducible generated tree.' }
      $null = Assert-ExactBaselineInventory -Root $destination
      Write-Host 'Public interface baseline check passed: 17 packages, 68 records, two clean copies, byte-identical output.'
    } else {
      $parent = Split-Path -Parent $destination
      $null = New-Item -ItemType Directory -Path $parent -Force
      $staging = Join-Path $parent ('.baseline-' + [guid]::NewGuid().ToString('N'))
      Copy-Item -LiteralPath $treeA -Destination $staging -Recurse
      if (Test-Path -LiteralPath $destination) { Remove-Item -LiteralPath $destination -Recurse -Force }
      [IO.Directory]::Move($staging, $destination)
      Write-Host "Generated public interface baseline at '$destination'."
    }
  } finally {
    if (Test-Path -LiteralPath $temporaryRoot) { Remove-Item -LiteralPath $temporaryRoot -Recurse -Force }
  }
} finally {
  Pop-Location
}
