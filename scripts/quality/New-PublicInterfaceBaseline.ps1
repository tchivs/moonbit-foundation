[CmdletBinding(DefaultParameterSetName = 'Batch')]
param(
  [Parameter(ParameterSetName = 'Schema', Mandatory)][switch]$CheckSchema,
  [Parameter(ParameterSetName = 'Library', Mandatory)][switch]$LibraryMode,
  [Parameter(ParameterSetName = 'Batch', Mandatory)][string[]]$Packages,
  [Parameter(ParameterSetName = 'Finalize', Mandatory)][switch]$Finalize,
  [Parameter(ParameterSetName = 'Batch', Mandatory)][Parameter(ParameterSetName = 'Finalize', Mandatory)][string]$SourceSnapshot,
  [Parameter(ParameterSetName = 'Batch')][Parameter(ParameterSetName = 'Finalize')][switch]$Check,
  [Parameter(ParameterSetName = 'Batch')][Parameter(ParameterSetName = 'Finalize')][string]$BaselineVersion = '0.1.0',
  [Parameter(ParameterSetName = 'Batch')][Parameter(ParameterSetName = 'Finalize')][string]$OutputRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SchemaVersion = 'mnf-public-interface-baseline-package/1'
$script:ManifestSchemaVersion = 'mnf-public-interface-baseline-manifest/1'
$script:NormalizationVersion = 'moon-mbti-lossless-lines/1'
$script:Targets = @('js', 'wasm', 'wasm-gc', 'native')
$script:CanonicalModules = @('tchivs/mb-core', 'tchivs/mb-color', 'tchivs/mb-image')
$script:RequiredSnapshotPath = 'compatibility/source-snapshots/0.1.0.json'
$script:ClaimScope = 'public-interface-text-only; no behavioral, semantic, resource, layout, or performance compatibility claim'
$script:Utf8NoBom = [Text.UTF8Encoding]::new($false)

function Get-BaselineRepoRoot { [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')) }
function Get-Sha256Hex { param([Parameter(Mandatory)][byte[]]$Bytes) [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant() }
function ConvertTo-StableJsonText { param([Parameter(Mandatory)]$Value) ((($Value | ConvertTo-Json -Depth 100) -replace "`r`n", "`n") + "`n") }

function Write-AtomicUtf8 {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Text)
  $directory = Split-Path -Parent $Path
  $null = New-Item -ItemType Directory -Path $directory -Force
  $temporary = Join-Path $directory ('.' + [IO.Path]::GetFileName($Path) + '.' + [guid]::NewGuid().ToString('N') + '.tmp')
  try { [IO.File]::WriteAllText($temporary, $Text, $script:Utf8NoBom); [IO.File]::Move($temporary, $Path, $true) }
  finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force } }
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
    foreach ($package in @($policy.modules.$module.public_packages)) {
      $packageName = [string]$package; $prefix = "tchivs/$module/"
      if (-not $packageName.StartsWith($prefix, [StringComparison]::Ordinal)) { throw "Unsafe package '$packageName'." }
      $leaf = $packageName.Substring($prefix.Length)
      if ($leaf -cnotmatch '^[a-z][a-z0-9-]*$') { throw "Unsafe package leaf '$leaf'." }
      $items.Add([pscustomobject][ordered]@{ module = [string]$module; package = $packageName; leaf = $leaf })
    }
  }
  if ($items.Count -ne 17) { throw "Public package inventory has $($items.Count) records; expected 17." }
  $items.ToArray()
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
  } finally { if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force } }
}

function Get-ModuleTreeSha256 {
  param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$Commit)
  $paths = @(& git -C $RepoRoot ls-tree -r --name-only $Commit -- modules/mb-core modules/mb-color modules/mb-image | Sort-Object)
  if ($LASTEXITCODE -ne 0 -or $paths.Count -eq 0) { throw 'Unable to enumerate anchored module tree.' }
  $temporary = Join-Path ([IO.Path]::GetTempPath()) ('mnf-source-tree-' + [guid]::NewGuid().ToString('N'))
  try {
    New-CleanArchiveCopy -RepoRoot $RepoRoot -Commit $Commit -Destination $temporary
    $hasher = [Security.Cryptography.SHA256]::Create()
    foreach ($path in $paths) {
      $pathBytes = [Text.Encoding]::UTF8.GetBytes([string]$path)
      $fileBytes = [IO.File]::ReadAllBytes((Join-Path $temporary $path))
      $lengthBytes = [BitConverter]::GetBytes([UInt64]$fileBytes.Length)
      if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($lengthBytes) }
      $null = $hasher.TransformBlock($pathBytes, 0, $pathBytes.Length, $null, 0)
      $separator = [byte[]](0); $null = $hasher.TransformBlock($separator, 0, 1, $null, 0)
      $null = $hasher.TransformBlock($lengthBytes, 0, 8, $null, 0)
      $null = $hasher.TransformBlock($fileBytes, 0, $fileBytes.Length, $null, 0)
    }
    $null = $hasher.TransformFinalBlock([byte[]]::new(0), 0, 0)
    [Convert]::ToHexString($hasher.Hash).ToLowerInvariant()
  } finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force } }
}

function Assert-SourceSnapshot {
  param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$Path, [switch]$SkipToolchainProbe)
  if ($Path -cne $script:RequiredSnapshotPath) { throw "SourceSnapshot must be the literal path '$($script:RequiredSnapshotPath)'." }
  $absolute = Join-Path $RepoRoot $Path
  if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) { throw "Source snapshot '$Path' is missing." }
  $bytes = [IO.File]::ReadAllBytes($absolute); $raw = $script:Utf8NoBom.GetString($bytes)
  $snapshot = $raw | ConvertFrom-Json -Depth 100
  if ((ConvertTo-StableJsonText $snapshot) -cne $raw) { throw 'Source snapshot is not canonical JSON.' }
  if ([string]$snapshot.baseline_version -cne '0.1.0') { throw 'Source snapshot baseline version mismatch.' }
  if ((@($snapshot.canonical_modules) -join "`n") -cne ($script:CanonicalModules -join "`n")) { throw 'Source snapshot canonical module identity mismatch.' }
  if ([string]$snapshot.source_commit -cnotmatch '^[0-9a-f]{40}$') { throw 'Source snapshot commit is invalid.' }
  if ([string]$snapshot.module_tree_sha256 -cnotmatch '^[0-9a-f]{64}$') { throw 'Source snapshot module-tree digest is invalid.' }
  & git -C $RepoRoot cat-file -e "$($snapshot.source_commit)^{commit}" 2>$null
  if ($LASTEXITCODE -ne 0) { throw 'Source snapshot commit does not exist.' }
  if ((Get-ModuleTreeSha256 -RepoRoot $RepoRoot -Commit $snapshot.source_commit) -cne [string]$snapshot.module_tree_sha256) { throw 'Source snapshot module-tree digest mismatch.' }
  $expected = [ordered]@{
    moon = 'moon 0.1.20260713 (75c7e1f 2026-07-13)'
    moonc = 'v0.10.4+2cc641edf (2026-07-15)'
    moonrun = 'moonrun 0.1.20260713 (75c7e1f 2026-07-13)'
  }
  if (($snapshot.toolchain | ConvertTo-Json -Compress) -cne ($expected | ConvertTo-Json -Compress)) { throw 'Source snapshot pinned toolchain mismatch.' }
  if (-not $SkipToolchainProbe -and ((Get-ToolchainIdentity | ConvertTo-Json -Compress) -cne ($expected | ConvertTo-Json -Compress))) { throw 'Active toolchain does not match source snapshot.' }
  [pscustomobject]@{ document = $snapshot; sha256 = Get-Sha256Hex $bytes; path = $absolute }
}

function Assert-ExactPackages {
  param([Parameter(Mandatory)][object[]]$Inventory, [Parameter(Mandatory)][string[]]$Selected)
  if ($Selected.Count -eq 0 -or @($Selected | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) { throw 'Packages must be a nonempty exact ordered array.' }
  $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal); $last = -1
  foreach ($package in $Selected) {
    if (-not $seen.Add($package)) { throw "Duplicate package '$package'." }
    $index = -1
    for ($i = 0; $i -lt $Inventory.Count; $i++) { if ([string]$Inventory[$i].package -ceq $package) { $index = $i; break } }
    if ($index -lt 0) { throw "Unknown package '$package'." }
    if ($index -le $last) { throw 'Packages are not in canonical policy order.' }
    $last = $index
  }
}

function Convert-MbtiToNormalizedText {
  param([Parameter(Mandatory)][byte[]]$Bytes, [Parameter(Mandatory)][string]$ExpectedPackage)
  $strictUtf8 = [Text.UTF8Encoding]::new($false, $true)
  try { $text = $strictUtf8.GetString($Bytes) } catch { throw "Unknown .mbti encoding for '$ExpectedPackage': expected UTF-8." }
  if ($text.Contains([char]0)) { throw "Unknown .mbti syntax for '$ExpectedPackage': NUL byte." }
  $lines = @(($text -replace "`r`n", "`n" -replace "`r", "`n").Split("`n"))
  if ($lines.Count -lt 2 -or $lines[0] -cne '// Generated using `moon info`, DON''T EDIT IT' -or $lines[1] -cne "package `"$ExpectedPackage`"") { throw "Unknown .mbti header for '$ExpectedPackage'." }
  $depth = 0
  for ($i = 2; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].TrimEnd(); $lines[$i] = $line
    if ($line -ceq '' -or $line -cmatch '^// (Values|Errors|Types and methods|Type aliases|Traits|private fields)$') { continue }
    if ($line -ceq 'import {') { if ($depth -ne 0) { throw "Unknown nested import at line $($i + 1)." }; $depth = 1; continue }
    if ($depth -eq 1 -and $line -cmatch '^  "tchivs/mb-(core|color|image)(/[a-z][a-z0-9-]*)?",$') { continue }
    if ($depth -eq 1 -and $line -ceq '}') { $depth = 0; continue }
    if ($depth -eq 0 -and ($line -cmatch '^type [A-Z][A-Za-z0-9_]*(\[[^]]+\])?$' -or $line -cmatch '^pub fn(?:\[[^]]+\])? .+$' -or $line -cmatch '^pub impl .+$')) { continue }
    if ($depth -eq 0 -and $line -cmatch '^pub(?:\((?:all|open)\))? (?:struct|enum|error|trait) [A-Z][A-Za-z0-9_]*(?:\[[^]]+\])?(?: .*)? \{$') { $depth = 2; continue }
    if ($depth -eq 2 -and ($line -cmatch '^  // private fields$' -or $line -cmatch '^  (?:fn |[A-Z_a-z@&]).*$')) { continue }
    if ($depth -eq 2 -and $line -cmatch '^}(?: derive\([A-Za-z0-9_, ]+\))?$') { $depth = 0; continue }
    throw "Unknown .mbti syntax for '$ExpectedPackage' at line $($i + 1): '$line'."
  }
  if ($depth -ne 0) { throw "Unknown unterminated .mbti construct for '$ExpectedPackage'." }
  while ($lines.Count -gt 0 -and $lines[-1] -ceq '') { $lines = @($lines | Select-Object -First ($lines.Count - 1)) }
  (($lines -join "`n") + "`n")
}

function Invoke-MoonInfo {
  param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Module, [Parameter(Mandatory)][string]$Target)
  Push-Location $Root
  try { $output = @(& moon -C "modules/$Module" info --target $Target --frozen 2>&1 | ForEach-Object { $_.ToString() }); if ($LASTEXITCODE -ne 0) { throw "moon info failed for $Module/$Target`: $($output -join ' | ')" } }
  finally { Pop-Location }
}

function New-GeneratedBatchTree {
  param([Parameter(Mandatory)][string]$SourceRoot, [Parameter(Mandatory)][string]$Destination, [Parameter(Mandatory)][object[]]$SelectedItems, [Parameter(Mandatory)]$Snapshot, [Parameter(Mandatory)][string]$SnapshotSha)
  foreach ($module in @('mb-core','mb-color','mb-image')) {
    $items = @($SelectedItems | Where-Object module -CEQ $module); if ($items.Count -eq 0) { continue }
    Invoke-MoonInfo -Root $SourceRoot -Module $module -Target 'all'; $canonical = @{}
    foreach ($item in $items) {
      $path = Join-Path $SourceRoot "modules/$module/$($item.leaf)/pkg.generated.mbti"; if (-not (Test-Path -LiteralPath $path)) { throw "Missing canonical raw interface '$path'." }
      $bytes = [IO.File]::ReadAllBytes($path); $canonical[$item.package] = [pscustomobject]@{ bytes=$bytes; sha=Get-Sha256Hex $bytes; normalized=Convert-MbtiToNormalizedText -Bytes $bytes -ExpectedPackage $item.package }
    }
    $inspections = @{}
    foreach ($target in $script:Targets) {
      Invoke-MoonInfo -Root $SourceRoot -Module $module -Target $target
      foreach ($item in $items) { $bytes=[IO.File]::ReadAllBytes((Join-Path $SourceRoot "modules/$module/$($item.leaf)/pkg.generated.mbti")); $sha=Get-Sha256Hex $bytes; if($sha -cne $canonical[$item.package].sha){throw "Target divergence is unknown for $($item.package)/$target; generation stopped."}; $inspections["$($item.package)|$target"]=$sha }
    }
    foreach ($item in $items) {
      $relative="$module/$($item.leaf)"; $raw="$relative/raw.mbti"; $rawPath=Join-Path $Destination $raw; $null=New-Item -ItemType Directory -Path (Split-Path -Parent $rawPath) -Force; [IO.File]::WriteAllBytes($rawPath,$canonical[$item.package].bytes)
      $records=[Collections.Generic.List[object]]::new()
      foreach($target in $script:Targets){$normalized="$relative/$target.mbti";$text=[string]$canonical[$item.package].normalized;Write-AtomicUtf8 (Join-Path $Destination $normalized) $text;$records.Add([pscustomobject][ordered]@{target=$target;normalized_path=$normalized;normalized_sha256=Get-Sha256Hex ([Text.Encoding]::UTF8.GetBytes($text));target_inspection=[pscustomobject][ordered]@{command="moon -C modules/$module info --target $target --frozen";status='pass';raw_sha256=$inspections["$($item.package)|$target"];matches_canonical=$true}})}
      $document=[pscustomobject][ordered]@{schema_version=$script:SchemaVersion;normalization_schema_version=$script:NormalizationVersion;source_snapshot_sha256=$SnapshotSha;source_commit=[string]$Snapshot.source_commit;toolchain=$Snapshot.toolchain;module=$module;package=$item.package;raw_path=$raw;raw_sha256=$canonical[$item.package].sha;records=$records.ToArray();two_run_equal=$true;claim_scope=$script:ClaimScope}
      Write-AtomicUtf8 (Join-Path $Destination "$relative/baseline.json") (ConvertTo-StableJsonText $document)
    }
  }
}

function Get-TreeDigestMap { param([Parameter(Mandatory)][string]$Root) $map=[ordered]@{}; foreach($f in @(Get-ChildItem -LiteralPath $Root -Recurse -File|Sort-Object FullName)){$map[[IO.Path]::GetRelativePath($Root,$f.FullName).Replace('\','/')]=Get-Sha256Hex ([IO.File]::ReadAllBytes($f.FullName))}; $map }
function Assert-TreeMapsEqual { param([Parameter(Mandatory)]$First,[Parameter(Mandatory)]$Second) if(($First|ConvertTo-Json -Compress)-cne($Second|ConvertTo-Json -Compress)){throw 'Unstable second run: independently generated baseline trees differ.'} }

function Publish-BatchTree {
  param([Parameter(Mandatory)][string]$Generated,[Parameter(Mandatory)][string]$Destination,[Parameter(Mandatory)][object[]]$Items,[switch]$Check)
  foreach($item in $Items){$relative="$($item.module)/$($item.leaf)";$source=Join-Path $Generated $relative;$files=@(Get-ChildItem $source -File);if($files.Count-ne 6){throw "Generated package '$($item.package)' must contain exactly six files."};$target=Join-Path $Destination $relative;if($Check){if(-not(Test-Path $target)){throw "Checked package '$($item.package)' is missing."};Assert-TreeMapsEqual (Get-TreeDigestMap $source) (Get-TreeDigestMap $target)}else{$parent=Split-Path -Parent $target;$null=New-Item -ItemType Directory -Path $parent -Force;$stage=Join-Path $parent ('.package-'+[guid]::NewGuid().ToString('N'));Copy-Item $source $stage -Recurse;if(Test-Path $target){Remove-Item $target -Recurse -Force};[IO.Directory]::Move($stage,$target)}}
}

function Assert-ExactPackageTree {
  param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][object[]]$Inventory,[Parameter(Mandatory)]$Snapshot,[Parameter(Mandatory)][string]$SnapshotSha)
  $entries = [Collections.Generic.List[object]]::new()
  $expected = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $pairs = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  foreach ($item in $Inventory) {
    $relative = "$($item.module)/$($item.leaf)"; $baseline = "$relative/baseline.json"; $raw = "$relative/raw.mbti"
    foreach ($path in @($baseline,$raw) + @($script:Targets | ForEach-Object { "$relative/$_.mbti" })) {
      $null = $expected.Add($path)
      if (-not (Test-Path (Join-Path $Root $path))) { throw "Incomplete baseline output: missing '$path'." }
    }
    $document = Get-Content (Join-Path $Root $baseline) -Raw | ConvertFrom-Json -Depth 100
    if ([string]$document.package -cne [string]$item.package -or [string]$document.module -cne [string]$item.module) { throw "Mixed identity for '$($item.package)'." }
    if ([string]$document.source_snapshot_sha256 -cne $SnapshotSha -or [string]$document.source_commit -cne [string]$Snapshot.source_commit) { throw "Stale or anchor-mismatched output for '$($item.package)'." }
    if (($document.toolchain | ConvertTo-Json -Compress) -cne ($Snapshot.toolchain | ConvertTo-Json -Compress)) { throw "Toolchain mismatch for '$($item.package)'." }
    if (@($document.records).Count -ne 4) { throw "Package '$($item.package)' does not contain exactly four records." }
    for ($index = 0; $index -lt 4; $index++) {
      $record = @($document.records)[$index]
      if ([string]$record.target -cne $script:Targets[$index]) { throw "Missing or out-of-order package-target pair for '$($item.package)'." }
      if (-not $pairs.Add("$($item.package)|$($record.target)")) { throw "Duplicate package-target pair for '$($item.package)'." }
      $normalizedPath = Join-Path $Root ([string]$record.normalized_path)
      if ((Get-Sha256Hex ([IO.File]::ReadAllBytes($normalizedPath))) -cne [string]$record.normalized_sha256) { throw "Normalized digest drift for '$($item.package)'." }
    }
    $rawPath = Join-Path $Root $raw
    if ((Get-Sha256Hex ([IO.File]::ReadAllBytes($rawPath))) -cne [string]$document.raw_sha256) { throw "Raw digest drift for '$($item.package)'." }
    $entries.Add([pscustomobject][ordered]@{
      module = $item.module; package = $item.package; baseline_path = $baseline
      baseline_sha256 = Get-Sha256Hex ([IO.File]::ReadAllBytes((Join-Path $Root $baseline)))
      raw_path = $raw; raw_sha256 = [string]$document.raw_sha256
    })
  }
  $actual = @(Get-ChildItem $Root -Recurse -File | ForEach-Object { [IO.Path]::GetRelativePath($Root,$_.FullName).Replace('\','/') } | Where-Object { $_ -cne 'manifest.json' })
  if ($expected.Count -ne 102 -or $actual.Count -ne 102 -or $pairs.Count -ne 68) { throw 'Finalization requires exactly 102 package files and 68 target records.' }
  foreach ($file in $actual) { if (-not $expected.Contains($file)) { throw "Extra baseline output '$file'." } }
  $entries.ToArray()
}

function New-FinalManifest {
  param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][object[]]$Inventory,[Parameter(Mandatory)]$Snapshot,[Parameter(Mandatory)][string]$SnapshotSha,[Parameter(Mandatory)][string]$Version)
  $entries=Assert-ExactPackageTree $Root $Inventory $Snapshot $SnapshotSha
  [pscustomobject][ordered]@{schema_version=$script:ManifestSchemaVersion;normalization_schema_version=$script:NormalizationVersion;baseline_version=$Version;source_snapshot_sha256=$SnapshotSha;source_commit=[string]$Snapshot.source_commit;toolchain=$Snapshot.toolchain;targets=$script:Targets;package_count=17;record_count=68;packages=$entries;two_run_equal=$true;claim_scope=$script:ClaimScope}
}

function Assert-BaselineSchemaContract {$schema=Get-Content (Join-Path (Get-BaselineRepoRoot) 'compatibility/schema/baseline-schema.json') -Raw|ConvertFrom-Json -Depth 100;if($schema.type-cne'object'-or$schema.additionalProperties-ne$false){throw 'Baseline schema root must be a closed object.'};Write-Host 'Baseline schema is valid JSON and closed at every object boundary.'}

if($LibraryMode){return};if($CheckSchema){Assert-BaselineSchemaContract;return}
$repoRoot=Get-BaselineRepoRoot
if($BaselineVersion-cne'0.1.0'){throw 'Only BaselineVersion 0.1.0 is allowed.'}
$anchor=Assert-SourceSnapshot -RepoRoot $repoRoot -Path $SourceSnapshot
$destination=if($OutputRoot){[IO.Path]::GetFullPath($OutputRoot)}else{Join-Path $repoRoot "compatibility/baselines/$BaselineVersion"}
$temporary=Join-Path ([IO.Path]::GetTempPath()) ('mnf-baseline-'+[guid]::NewGuid().ToString('N'))
try{
  $sourceA=Join-Path $temporary 'source-a';New-CleanArchiveCopy $repoRoot $anchor.document.source_commit $sourceA;$inventory=@(Get-PublicPackageInventory $sourceA)
  if($Finalize){$manifest=New-FinalManifest $destination $inventory $anchor.document $anchor.sha256 $BaselineVersion;$text=ConvertTo-StableJsonText $manifest;$path=Join-Path $destination 'manifest.json';if($Check){if(-not(Test-Path $path)-or(Get-Content $path -Raw)-cne$text){throw 'Final manifest differs from anchored reproducible output.'}}else{Write-AtomicUtf8 $path $text};Write-Host 'Public interface baseline finalization passed.';return}
  Assert-ExactPackages $inventory $Packages;$selected=@($inventory|Where-Object{$Packages-ccontains$_.package});$sourceB=Join-Path $temporary 'source-b';New-CleanArchiveCopy $repoRoot $anchor.document.source_commit $sourceB;$treeA=Join-Path $temporary 'tree-a';$treeB=Join-Path $temporary 'tree-b';New-GeneratedBatchTree $sourceA $treeA $selected $anchor.document $anchor.sha256;New-GeneratedBatchTree $sourceB $treeB $selected $anchor.document $anchor.sha256;Assert-TreeMapsEqual (Get-TreeDigestMap $treeA) (Get-TreeDigestMap $treeB);Publish-BatchTree $treeA $destination $selected -Check:$Check;Write-Host "Public interface baseline batch passed for $($Packages.Count) package(s)."
}finally{if(Test-Path $temporary){Remove-Item $temporary -Recurse -Force}}
