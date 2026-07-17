[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
. (Join-Path $PSScriptRoot 'New-PublicInterfaceBaseline.ps1') -LibraryMode
$baselineRoot = Join-Path $repoRoot 'compatibility/baselines/0.1.0'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-baseline-negative-' + [guid]::NewGuid().ToString('N'))
$utf8 = [Text.UTF8Encoding]::new($false)

function Write-TestJson {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)]$Value)
  [IO.File]::WriteAllText($Path, (($Value | ConvertTo-Json -Depth 100) + "`n"), $utf8)
}

function New-TestTree {
  param([Parameter(Mandatory)][string]$Name)
  $path = Join-Path $tempRoot $Name
  Copy-Item -LiteralPath $baselineRoot -Destination $path -Recurse
  return $path
}

function Confirm-Rejected {
  param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Pattern, [Parameter(Mandatory)][scriptblock]$Action)
  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure -or $failure -cnotmatch $Pattern) { throw "Baseline negative '$Name' passed or failed for the wrong reason: '$failure'." }
  Write-Host "Baseline negative rejected: $Name"
}

function Update-PackageDocument {
  param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][scriptblock]$Mutate)
  $manifestPath = Join-Path $Root 'manifest.json'
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -Depth 100
  $entry = $manifest.packages[0]
  $documentPath = Join-Path $Root ([string]$entry.baseline_path)
  $document = Get-Content -LiteralPath $documentPath -Raw | ConvertFrom-Json -Depth 100
  & $Mutate $document
  Write-TestJson -Path $documentPath -Value $document
  $entry.baseline_sha256 = Get-Sha256Hex ([IO.File]::ReadAllBytes($documentPath))
  Write-TestJson -Path $manifestPath -Value $manifest
}

function Get-TrackedSnapshot {
  $lines = @(& git -C $repoRoot diff --binary --no-ext-diff HEAD -- 2>&1 | ForEach-Object { $_.ToString() })
  if ($LASTEXITCODE -ne 0) { throw 'Unable to capture tracked source snapshot.' }
  return ($lines -join "`n")
}

$null = New-Item -ItemType Directory -Path $tempRoot -Force
try {
  $manifest = Assert-ExactBaselineInventory -Root $baselineRoot
  if (@($manifest.packages).Count -ne 17 -or $manifest.record_count -ne 68) { throw 'Positive baseline inventory did not prove 17 packages and 68 records.' }

  foreach ($case in @(@{ name = '67 records'; count = 67 }, @{ name = '69 records'; count = 69 })) {
    Confirm-Rejected -Name $case.name -Pattern 'exactly 68 records' -Action {
      $tree = New-TestTree $case.name.Replace(' ', '-')
      $value = Get-Content -LiteralPath (Join-Path $tree 'manifest.json') -Raw | ConvertFrom-Json -Depth 100
      $value.record_count = $case.count
      Write-TestJson -Path (Join-Path $tree 'manifest.json') -Value $value
      Assert-ExactBaselineInventory -Root $tree | Out-Null
    }
  }

  Confirm-Rejected -Name 'duplicate package-target pair' -Pattern 'Missing or out-of-order|Duplicate' -Action {
    $tree = New-TestTree 'duplicate-pair'
    Update-PackageDocument -Root $tree -Mutate { param($d) $d.records[1].target = $d.records[0].target }
    Assert-ExactBaselineInventory -Root $tree | Out-Null
  }
  Confirm-Rejected -Name 'missing package-target pair' -Pattern 'Missing or out-of-order' -Action {
    $tree = New-TestTree 'missing-pair'
    Update-PackageDocument -Root $tree -Mutate { param($d) $d.records[3].target = 'llvm' }
    Assert-ExactBaselineInventory -Root $tree | Out-Null
  }
  Confirm-Rejected -Name 'unknown syntax' -Pattern 'Unknown [.]mbti syntax' -Action {
    $bad = "// Generated using ``moon info``, DON'T EDIT IT`npackage `"moonbit-foundation/mb-core/error`"`nmystery syntax`n"
    Convert-MbtiToNormalizedText -Bytes ([Text.Encoding]::UTF8.GetBytes($bad)) -ExpectedPackage 'moonbit-foundation/mb-core/error' | Out-Null
  }
  Confirm-Rejected -Name 'target divergence' -Pattern 'Target divergence' -Action {
    $tree = New-TestTree 'target-divergence'
    Update-PackageDocument -Root $tree -Mutate { param($d) $d.records[0].target_inspection.matches_canonical = $false }
    Assert-ExactBaselineInventory -Root $tree | Out-Null
  }
  Confirm-Rejected -Name 'toolchain mismatch' -Pattern 'Toolchain mismatch' -Action {
    $tree = New-TestTree 'toolchain-mismatch'
    Update-PackageDocument -Root $tree -Mutate { param($d) $d.toolchain.moon = 'moon mismatch' }
    Assert-ExactBaselineInventory -Root $tree | Out-Null
  }
  Confirm-Rejected -Name 'unstable second run' -Pattern 'Unstable second run' -Action {
    $treeA = New-TestTree 'run-a'; $treeB = New-TestTree 'run-b'
    [IO.File]::AppendAllText((Join-Path $treeB 'mb-core/error/js.mbti'), "// drift`n", $utf8)
    Assert-TreeMapsEqual -First (Get-TreeDigestMap $treeA) -Second (Get-TreeDigestMap $treeB)
  }
  Confirm-Rejected -Name 'digest drift' -Pattern 'Normalized digest drift' -Action {
    $tree = New-TestTree 'digest-drift'
    [IO.File]::AppendAllText((Join-Path $tree 'mb-core/error/js.mbti'), "// drift`n", $utf8)
    Assert-ExactBaselineInventory -Root $tree | Out-Null
  }
  Confirm-Rejected -Name 'partial output' -Pattern 'Partial baseline output' -Action {
    $tree = New-TestTree 'partial-output'
    Remove-Item -LiteralPath (Join-Path $tree 'mb-core/error/raw.mbti') -Force
    Assert-ExactBaselineInventory -Root $tree | Out-Null
  }

  $before = Get-TrackedSnapshot
  & (Join-Path $PSScriptRoot 'New-PublicInterfaceBaseline.ps1') -Check
  $after = Get-TrackedSnapshot
  if ($before -cne $after) { throw 'Tracked mutation: baseline check changed tracked source.' }
  Write-Host 'Tracked mutation negative proved check mode is read-only.'
  Write-Host 'Public interface baseline suite passed: exact 17 packages, 68 records, digests, negatives, and two clean generations.'
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $full = [IO.Path]::GetFullPath($tempRoot)
    if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or -not (Split-Path -Leaf $full).StartsWith('mnf-baseline-negative-', [StringComparison]::Ordinal)) {
      throw "Refusing to remove unverified baseline test path '$full'."
    }
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}
