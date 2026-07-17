[CmdletBinding()]
param([switch]$ToolingOnly)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
. (Join-Path $PSScriptRoot 'New-PublicInterfaceBaseline.ps1') -LibraryMode
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-baseline-negative-' + [guid]::NewGuid().ToString('N'))
$utf8 = [Text.UTF8Encoding]::new($false)

function Confirm-Rejected {
  param([Parameter(Mandatory)][string]$Name,[Parameter(Mandatory)][string]$Pattern,[Parameter(Mandatory)][scriptblock]$Action)
  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure -or $failure -cnotmatch $Pattern) { throw "Baseline negative '$Name' passed or failed for the wrong reason: '$failure'." }
  Write-Host "Baseline negative rejected: $Name"
}

function Write-TestJson { param([string]$Path,$Value) $null=New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force; [IO.File]::WriteAllText($Path,(ConvertTo-StableJsonText $Value),$utf8) }

function New-SyntheticPackageTree {
  param([string]$Root,[object[]]$Inventory,$Snapshot,[string]$SnapshotSha)
  foreach ($item in $Inventory) {
    $relative="$($item.module)/$($item.leaf)"; $null=New-Item -ItemType Directory -Path (Join-Path $Root $relative) -Force
    $rawBytes=[Text.Encoding]::UTF8.GetBytes("raw:$($item.package)`n"); [IO.File]::WriteAllBytes((Join-Path $Root "$relative/raw.mbti"),$rawBytes)
    $records=[Collections.Generic.List[object]]::new()
    foreach($target in $script:Targets){$text="normalized:$($item.package):$target`n";$path="$relative/$target.mbti";[IO.File]::WriteAllText((Join-Path $Root $path),$text,$utf8);$records.Add([pscustomobject][ordered]@{target=$target;normalized_path=$path;normalized_sha256=Get-Sha256Hex ([Text.Encoding]::UTF8.GetBytes($text));target_inspection=[pscustomobject][ordered]@{command="synthetic $target";status='pass';raw_sha256=Get-Sha256Hex $rawBytes;matches_canonical=$true}})}
    $document=[pscustomobject][ordered]@{schema_version=$script:SchemaVersion;normalization_schema_version=$script:NormalizationVersion;source_snapshot_sha256=$SnapshotSha;source_commit=[string]$Snapshot.source_commit;toolchain=$Snapshot.toolchain;module=$item.module;package=$item.package;raw_path="$relative/raw.mbti";raw_sha256=Get-Sha256Hex $rawBytes;records=$records.ToArray();two_run_equal=$true;claim_scope=$script:ClaimScope}
    Write-TestJson (Join-Path $Root "$relative/baseline.json") $document
  }
}

function Copy-TestTree { param([string]$Source,[string]$Name) $path=Join-Path $tempRoot $Name;Copy-Item $Source $path -Recurse;return $path }

function Get-TrackedSnapshot {
  $lines=@(& git -C $repoRoot diff --binary --no-ext-diff HEAD -- 2>&1|ForEach-Object{$_.ToString()})
  if($LASTEXITCODE-ne 0){throw 'Unable to capture tracked source snapshot.'};$lines-join"`n"
}

$null=New-Item -ItemType Directory -Path $tempRoot -Force
try {
  $anchor=Assert-SourceSnapshot -RepoRoot $repoRoot -Path 'compatibility/source-snapshots/0.1.0.json' -SkipToolchainProbe
  $source=Join-Path $tempRoot 'anchored-source';New-CleanArchiveCopy $repoRoot $anchor.document.source_commit $source
  $inventory=@(Get-PublicPackageInventory $source)
  if($inventory.Count-ne 17){throw 'Positive package policy did not produce 17 packages.'}

  Confirm-Rejected 'empty packages' 'nonempty|empty string' { Assert-ExactPackages $inventory @('') }
  Confirm-Rejected 'duplicate packages' 'Duplicate package' { Assert-ExactPackages $inventory @($inventory[0].package,$inventory[0].package) }
  Confirm-Rejected 'unknown package' 'Unknown package' { Assert-ExactPackages $inventory @('tchivs/mb-core/not-real') }
  Confirm-Rejected 'out-of-order packages' 'canonical policy order' { Assert-ExactPackages $inventory @($inventory[1].package,$inventory[0].package) }
  Confirm-Rejected 'wrong source snapshot path' 'literal path' { Assert-SourceSnapshot $repoRoot './compatibility/source-snapshots/0.1.0.json' -SkipToolchainProbe }
  Confirm-Rejected 'unknown syntax' 'Unknown [.]mbti' { Convert-MbtiToNormalizedText ([Text.Encoding]::UTF8.GetBytes("// Generated using ``moon info``, DON'T EDIT IT`npackage `"tchivs/mb-core/error`"`nmystery syntax`n")) 'tchivs/mb-core/error' }

  $full=Join-Path $tempRoot 'full';New-SyntheticPackageTree $full $inventory $anchor.document $anchor.sha256
  $manifest=New-FinalManifest $full $inventory $anchor.document $anchor.sha256 '0.1.0'
  if($manifest.package_count-ne 17-or$manifest.record_count-ne 68-or@($manifest.packages).Count-ne 17){throw 'Positive finalization did not prove exact inventory.'}
  if([string]$manifest.source_commit-cne[string]$anchor.document.source_commit-or[string]$manifest.source_snapshot_sha256-cne$anchor.sha256){throw 'Final manifest is not anchor-bound.'}

  $partial=Copy-TestTree $full 'partial';Remove-Item (Join-Path $partial 'mb-core/error/raw.mbti') -Force
  Confirm-Rejected 'premature finalization' 'Incomplete baseline output' { New-FinalManifest $partial $inventory $anchor.document $anchor.sha256 '0.1.0' }
  $extra=Copy-TestTree $full 'extra';[IO.File]::WriteAllText((Join-Path $extra 'extra.txt'),'extra',$utf8)
  Confirm-Rejected 'extra output' 'Extra baseline output|exactly 102' { New-FinalManifest $extra $inventory $anchor.document $anchor.sha256 '0.1.0' }
  $stale=Copy-TestTree $full 'stale';$stalePath=Join-Path $stale 'mb-core/error/baseline.json';$staleDoc=Get-Content $stalePath -Raw|ConvertFrom-Json -Depth 100;$staleDoc.source_commit='0000000000000000000000000000000000000000';Write-TestJson $stalePath $staleDoc
  Confirm-Rejected 'stale output' 'anchor-mismatched' { New-FinalManifest $stale $inventory $anchor.document $anchor.sha256 '0.1.0' }
  $mixed=Copy-TestTree $full 'mixed';$mixedPath=Join-Path $mixed 'mb-core/error/baseline.json';$mixedDoc=Get-Content $mixedPath -Raw|ConvertFrom-Json -Depth 100;$mixedDoc.package='moonbit-foundation/mb-core/error';Write-TestJson $mixedPath $mixedDoc
  Confirm-Rejected 'mixed identity' 'Mixed identity' { New-FinalManifest $mixed $inventory $anchor.document $anchor.sha256 '0.1.0' }
  $mismatch=Copy-TestTree $full 'anchor-mismatch';$mismatchPath=Join-Path $mismatch 'mb-core/error/baseline.json';$mismatchDoc=Get-Content $mismatchPath -Raw|ConvertFrom-Json -Depth 100;$mismatchDoc.source_snapshot_sha256=('0'*64);Write-TestJson $mismatchPath $mismatchDoc
  Confirm-Rejected 'anchor mismatch' 'anchor-mismatched' { New-FinalManifest $mismatch $inventory $anchor.document $anchor.sha256 '0.1.0' }

  $batchSource=Join-Path $tempRoot 'batch-source';$batchDest=Join-Path $tempRoot 'batch-destination';$selected=@($inventory[0]);New-SyntheticPackageTree $batchSource $selected $anchor.document $anchor.sha256;$null=New-Item -ItemType Directory -Path $batchDest -Force
  [IO.File]::WriteAllText((Join-Path $batchDest 'manifest.json'),'obsolete-manifest',$utf8);$null=New-Item -ItemType Directory -Path (Join-Path $batchDest 'mb-color/model') -Force;[IO.File]::WriteAllText((Join-Path $batchDest 'mb-color/model/marker.txt'),'untouched',$utf8)
  $manifestBefore=[IO.File]::ReadAllBytes((Join-Path $batchDest 'manifest.json'));$markerBefore=[IO.File]::ReadAllBytes((Join-Path $batchDest 'mb-color/model/marker.txt'))
  Publish-BatchTree $batchSource $batchDest $selected
  $manifestAfter=[IO.File]::ReadAllBytes((Join-Path $batchDest 'manifest.json'));$markerAfter=[IO.File]::ReadAllBytes((Join-Path $batchDest 'mb-color/model/marker.txt'))
  if((Get-Sha256Hex $manifestBefore) -cne (Get-Sha256Hex $manifestAfter) -or (Get-Sha256Hex $markerBefore) -cne (Get-Sha256Hex $markerAfter)){throw 'Batch mutated manifest or another package subtree.'}
  $beforeCheck=Get-TreeDigestMap $batchDest;Publish-BatchTree $batchSource $batchDest $selected -Check;Assert-TreeMapsEqual $beforeCheck (Get-TreeDigestMap $batchDest)
  Write-Host 'Batch isolation and read-only check proved no cross-batch or manifest mutation.'

  $obsolete=Copy-TestTree $full 'obsolete-manifest';$obsoleteManifest=[pscustomobject]@{source_commit=('f'*40)};Write-TestJson (Join-Path $obsolete 'manifest.json') $obsoleteManifest
  $final=New-FinalManifest $obsolete $inventory $anchor.document $anchor.sha256 '0.1.0'
  if([string]$final.source_commit-cne[string]$anchor.document.source_commit){throw 'Obsolete manifest source_commit overrode the anchor.'}
  Write-Host 'Obsolete manifest source_commit proved irrelevant to finalization.'

  $fixture=Join-Path $tempRoot 'later-head-repo';$null=New-Item -ItemType Directory -Path (Join-Path $fixture 'modules/mb-core') -Force;$null=New-Item -ItemType Directory -Path (Join-Path $fixture 'modules/mb-color') -Force;$null=New-Item -ItemType Directory -Path (Join-Path $fixture 'modules/mb-image') -Force
  foreach($module in @('mb-core','mb-color','mb-image')){[IO.File]::WriteAllText((Join-Path $fixture "modules/$module/source.mbt"),"anchored $module`n",$utf8)}
  & git -C $fixture init -q;& git -C $fixture config user.name test;& git -C $fixture config user.email test@example.invalid;& git -C $fixture add modules;& git -C $fixture commit -q -m anchor;$fixtureCommit=(& git -C $fixture rev-parse HEAD).Trim();$fixtureDigest=Get-ModuleTreeSha256 $fixture $fixtureCommit
  $fixtureAnchor=[ordered]@{baseline_version='0.1.0';canonical_modules=$script:CanonicalModules;toolchain=[ordered]@{moon='moon 0.1.20260713 (75c7e1f 2026-07-13)';moonc='v0.10.4+2cc641edf (2026-07-15)';moonrun='moonrun 0.1.20260713 (75c7e1f 2026-07-13)'};source_commit=$fixtureCommit;module_tree_sha256=$fixtureDigest};Write-TestJson (Join-Path $fixture 'compatibility/source-snapshots/0.1.0.json') $fixtureAnchor
  [IO.File]::WriteAllText((Join-Path $fixture 'modules/mb-core/source.mbt'),"later HEAD`n",$utf8);& git -C $fixture add modules;& git -C $fixture commit -q -m later
  $laterAnchor=Assert-SourceSnapshot $fixture 'compatibility/source-snapshots/0.1.0.json' -SkipToolchainProbe
  if([string]$laterAnchor.document.source_commit-cne$fixtureCommit-or(& git -C $fixture rev-parse HEAD).Trim()-ceq$fixtureCommit){throw 'Later HEAD was not isolated from anchor.'}
  Write-Host 'Later synthetic HEAD proved irrelevant to anchored source resolution.'
  $mutatedPath=Join-Path $fixture 'compatibility/source-snapshots/0.1.0.json';$mutated=Get-Content $mutatedPath -Raw|ConvertFrom-Json -Depth 100;$mutated.module_tree_sha256=('f'*64);Write-TestJson $mutatedPath $mutated
  Confirm-Rejected 'mutated anchor' 'module-tree digest mismatch' { Assert-SourceSnapshot $fixture 'compatibility/source-snapshots/0.1.0.json' -SkipToolchainProbe }

  $trackedBefore=Get-TrackedSnapshot
  $null=Assert-SourceSnapshot $repoRoot 'compatibility/source-snapshots/0.1.0.json' -SkipToolchainProbe
  $trackedAfter=Get-TrackedSnapshot
  if($trackedBefore-cne$trackedAfter){throw 'Tooling-only checks mutated tracked source.'}
  Write-Host 'Public interface baseline tooling suite passed: immutable anchor, exact batches, 102-file finalization, full negatives, and read-only checks.'
} finally {
  if(Test-Path $tempRoot){$base=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar);$fullPath=[IO.Path]::GetFullPath($tempRoot);if(-not$fullPath.StartsWith($base+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)-or-not(Split-Path -Leaf $fullPath).StartsWith('mnf-baseline-negative-',[StringComparison]::Ordinal)){throw "Refusing to remove unverified test path '$fullPath'."};Remove-Item $fullPath -Recurse -Force}
}
