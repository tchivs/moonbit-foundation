[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ToolchainArchive = [pscustomobject][ordered]@{
  Url = 'https://cli.moonbitlang.com/binaries/latest/moonbit-linux-x86_64.tar.gz'
  Length = [long]73033507
  Sha256 = '31b7fc5cc78657964a6d545792ecd7fb8eed51b97c7431a17458b58734303381'
}
$CoreArchive = [pscustomobject][ordered]@{
  Url = 'https://cli.moonbitlang.com/cores/core-latest.tar.gz'
  Length = [long]1302919
  Sha256 = '03ad55b99f3e431f3cb81b4e2bb28bb98173304e4a1b18a891ea027cabba5d1c'
}
$BinaryHashes = [ordered]@{
  moon = '50913178bee7e904850fc37d5b16adda7e6c1616d2704994714b70ac86f9a7ab'
  moonc = '31633647318a571d6aac9a2144a0e1ba3c946ea806d1409778894fe76e604511'
  moonrun = '44b7d5427837c8c0f7379a9d4fa9f3e1aac0f433041b3ffe16e78e1c5f151ab4'
}
$BinaryIdentities = [ordered]@{
  moon = 'moon 0.1.20260713 (75c7e1f 2026-07-13)'
  moonc = 'v0.10.4+2cc641edf (2026-07-15)'
  moonrun = 'moonrun 0.1.20260713 (75c7e1f 2026-07-13)'
}

function Assert-PinnedArchive {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)]$Identity
  )

  $actualLength = (Get-Item -LiteralPath $Path).Length
  if ($actualLength -ne $Identity.Length) {
    throw (
      "P08-TOOLCHAIN-ARCHIVE-LENGTH: '$Path' length=$actualLength " +
      "expected=$($Identity.Length)"
    )
  }
  $actualHash = (
    Get-FileHash -LiteralPath $Path -Algorithm SHA256
  ).Hash.ToLowerInvariant()
  if ($actualHash -cne $Identity.Sha256) {
    throw (
      "P08-TOOLCHAIN-ARCHIVE-DIGEST: '$Path' sha256=$actualHash " +
      "expected=$($Identity.Sha256)"
    )
  }
}

function Assert-PinnedArchiveMembers {
  param(
    [Parameter(Mandatory)][string]$TarPath,
    [Parameter(Mandatory)][string]$ArchivePath,
    [string]$ExpectedRoot,
    [string]$RequiredMember,
    [string[]]$ForbiddenMembers = @()
  )

  $members = @(& $TarPath -tzf $ArchivePath 2>&1)
  if ($LASTEXITCODE -ne 0) {
    throw "P08-TOOLCHAIN-ARCHIVE-LIST: $($members -join ' ')"
  }
  if ($members.Count -eq 0) {
    throw "P08-TOOLCHAIN-ARCHIVE-EMPTY: '$ArchivePath'"
  }
  $normalizedMembers = @()
  foreach ($memberValue in $members) {
    $member = ([string]$memberValue).Replace('\', '/')
    $normalizedMembers += $member
    $segments = @(
      $member.Split(
        '/',
        [StringSplitOptions]::RemoveEmptyEntries
      )
    )
    if ($member.StartsWith('/', [StringComparison]::Ordinal) -or
        $segments -contains '..') {
      throw (
        "P08-TOOLCHAIN-ARCHIVE-PATH: '$ArchivePath' contains '$member'."
      )
    }
  }
  $hasExpectedRoot = -not [string]::IsNullOrEmpty($ExpectedRoot)
  $hasRequiredMember = -not [string]::IsNullOrEmpty($RequiredMember)
  if ($hasExpectedRoot -ne $hasRequiredMember -or
      ($ForbiddenMembers.Count -gt 0 -and -not $hasExpectedRoot)) {
    throw 'P08-TOOLCHAIN-ARCHIVE-LAYOUT-POLICY'
  }
  if ($hasExpectedRoot) {
    foreach ($member in $normalizedMembers) {
      if (-not $member.StartsWith(
          $ExpectedRoot,
          [StringComparison]::Ordinal
        )) {
        throw (
          "P08-TOOLCHAIN-ARCHIVE-ROOT: '$ArchivePath' contains '$member'; " +
          "expected root '$ExpectedRoot'."
        )
      }
    }
    $requiredCount = @(
      $normalizedMembers | Where-Object { $_ -ceq $RequiredMember }
    ).Count
    if ($requiredCount -ne 1) {
      throw (
        "P08-TOOLCHAIN-ARCHIVE-MARKER: '$RequiredMember' count=" +
        "$requiredCount."
      )
    }
    foreach ($forbiddenMember in $ForbiddenMembers) {
      if ($normalizedMembers -ccontains $forbiddenMember) {
        throw "P08-TOOLCHAIN-ARCHIVE-FORBIDDEN: '$forbiddenMember'"
      }
    }
  }
}

function Expand-PinnedArchive {
  param(
    [Parameter(Mandatory)][string]$TarPath,
    [Parameter(Mandatory)][string]$ArchivePath,
    [Parameter(Mandatory)][string]$Destination,
    [string]$ExpectedRoot,
    [string]$RequiredMember,
    [string[]]$ForbiddenMembers = @()
  )

  Assert-PinnedArchiveMembers `
    -TarPath $TarPath `
    -ArchivePath $ArchivePath `
    -ExpectedRoot $ExpectedRoot `
    -RequiredMember $RequiredMember `
    -ForbiddenMembers $ForbiddenMembers
  & $TarPath -xzf $ArchivePath -C $Destination
  if ($LASTEXITCODE -ne 0) {
    throw "P08-TOOLCHAIN-ARCHIVE-EXTRACT: '$ArchivePath'"
  }
}

function Get-PinnedBinaryIdentity {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Path
  )

  $output = @(
    switch ($Name) {
      'moon' { & $Path version }
      'moonc' { & $Path -v }
      'moonrun' { & $Path --version }
      default { throw "Unexpected pinned MoonBit binary '$Name'." }
    }
  )
  if ($LASTEXITCODE -ne 0 -or $output.Count -eq 0) {
    throw "P08-TOOLCHAIN-IDENTITY: '$Name' did not report its identity."
  }
  return [string]$output[0]
}

if (-not [OperatingSystem]::IsLinux()) {
  throw 'Pinned MoonBit CI transport supports only Linux.'
}
if ($env:GITHUB_ACTIONS -cne 'true' -or
    [string]::IsNullOrWhiteSpace($env:GITHUB_PATH)) {
  throw 'Pinned MoonBit CI transport may run only inside GitHub Actions.'
}
if ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne
    [Runtime.InteropServices.Architecture]::X64) {
  throw 'Pinned MoonBit CI transport requires Linux x86_64.'
}

$tarCommand = @(
  Get-Command tar -CommandType Application -ErrorAction Stop
)[0]
$chmodCommand = @(
  Get-Command chmod -CommandType Application -ErrorAction Stop
)[0]
$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
  [IO.Path]::DirectorySeparatorChar
)
$workRoot = Join-Path $temporaryBase (
  'mnf-pinned-moonbit-' + [Guid]::NewGuid().ToString('N')
)
$toolchainPath = Join-Path $workRoot 'moonbit-linux-x86_64.tar.gz'
$corePath = Join-Path $workRoot 'core-latest.tar.gz'
$stagingPath = Join-Path $workRoot 'staging'
$coreStagingPath = Join-Path $workRoot 'core-staging'
$destination = Join-Path $HOME '.moon'

try {
  if (Test-Path -LiteralPath $destination) {
    throw (
      "P08-TOOLCHAIN-DESTINATION: '$destination' must not already exist."
    )
  }
  [void](New-Item -ItemType Directory -Path $stagingPath)
  Invoke-WebRequest `
    -Uri $ToolchainArchive.Url `
    -OutFile $toolchainPath `
    -MaximumRetryCount 3 `
    -RetryIntervalSec 2
  Invoke-WebRequest `
    -Uri $CoreArchive.Url `
    -OutFile $corePath `
    -MaximumRetryCount 3 `
    -RetryIntervalSec 2

  # Mutable "latest" URLs are transport only. Both compressed byte streams are
  # authenticated before tar sees either archive.
  Assert-PinnedArchive -Path $toolchainPath -Identity $ToolchainArchive
  Assert-PinnedArchive -Path $corePath -Identity $CoreArchive
  Expand-PinnedArchive `
    -TarPath $tarCommand.Source `
    -ArchivePath $toolchainPath `
    -Destination $stagingPath

  $binaryPaths = [ordered]@{}
  foreach ($name in $BinaryHashes.Keys) {
    $path = Join-Path $stagingPath "bin/$name"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw "P08-TOOLCHAIN-BINARY-MISSING: '$path'"
    }
    $actualHash = (
      Get-FileHash -LiteralPath $path -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    if ($actualHash -cne $BinaryHashes[$name]) {
      throw (
        "P08-TOOLCHAIN-BINARY-DIGEST: $name path=$path " +
        "actual=$actualHash expected=$($BinaryHashes[$name])"
      )
    }
    $binaryPaths[$name] = $path
  }
  $verifiedBinaryPaths = @(
    $binaryPaths['moon'],
    $binaryPaths['moonc'],
    $binaryPaths['moonrun']
  )
  & $chmodCommand.Source 'a+x' '--' @verifiedBinaryPaths
  if ($LASTEXITCODE -ne 0) {
    throw 'P08-TOOLCHAIN-BINARY-MODE: chmod a+x failed.'
  }
  $executeMask = (
    [IO.UnixFileMode]::UserExecute -bor
    [IO.UnixFileMode]::GroupExecute -bor
    [IO.UnixFileMode]::OtherExecute
  )
  foreach ($path in $verifiedBinaryPaths) {
    $mode = [IO.File]::GetUnixFileMode($path)
    if (($mode -band $executeMask) -ne $executeMask) {
      throw "P08-TOOLCHAIN-BINARY-MODE: '$path' is not executable."
    }
  }

  $identityBinPath = [IO.Path]::GetFullPath((Join-Path $stagingPath 'bin'))
  foreach ($path in $verifiedBinaryPaths) {
    $binaryParent = [IO.Path]::GetDirectoryName(
      [IO.Path]::GetFullPath($path)
    )
    if (-not [string]::Equals(
        $binaryParent,
        $identityBinPath,
        [StringComparison]::Ordinal
      )) {
      throw "P08-TOOLCHAIN-IDENTITY-PATH: '$path'"
    }
  }
  $previousPath = [string]$env:PATH
  try {
    $env:PATH = if ([string]::IsNullOrEmpty($previousPath)) {
      $identityBinPath
    } else {
      $identityBinPath + [IO.Path]::PathSeparator + $previousPath
    }
    foreach ($name in $BinaryIdentities.Keys) {
      $actualIdentity = Get-PinnedBinaryIdentity `
        -Name $name `
        -Path $binaryPaths[$name]
      if ($actualIdentity -cne $BinaryIdentities[$name]) {
        throw (
          "P08-TOOLCHAIN-IDENTITY: $name actual='$actualIdentity' " +
          "expected='$($BinaryIdentities[$name])'"
        )
      }
    }
  } finally {
    $env:PATH = $previousPath
  }

  # Core is bundled only after the executable digests and identities pass.
  $libraryPath = Join-Path $stagingPath 'lib'
  if (Test-Path -LiteralPath $coreStagingPath) {
    throw "P08-TOOLCHAIN-CORE-STAGING: '$coreStagingPath' already exists."
  }
  [void](New-Item -ItemType Directory -Path $coreStagingPath)
  Expand-PinnedArchive `
    -TarPath $tarCommand.Source `
    -ArchivePath $corePath `
    -Destination $coreStagingPath `
    -ExpectedRoot './core/' `
    -RequiredMember './core/moon.mod' `
    -ForbiddenMembers @('./core/moon.mod.json')
  $coreRoots = @(Get-ChildItem -LiteralPath $coreStagingPath -Force)
  if ($coreRoots.Count -ne 1 -or
      $coreRoots[0].Name -cne 'core' -or
      -not $coreRoots[0].PSIsContainer) {
    throw 'P08-TOOLCHAIN-CORE-LAYOUT: expected only core/'
  }
  $coreMarker = Join-Path $coreStagingPath 'core/moon.mod'
  if (-not (Test-Path -LiteralPath $coreMarker -PathType Leaf)) {
    throw 'P08-TOOLCHAIN-CORE-MISSING: core/moon.mod'
  }
  $legacyCoreMarker = Join-Path $coreStagingPath 'core/moon.mod.json'
  if (Test-Path -LiteralPath $legacyCoreMarker) {
    throw 'P08-TOOLCHAIN-CORE-LEGACY: core/moon.mod.json'
  }
  $installedCorePath = Join-Path $libraryPath 'core'
  if (Test-Path -LiteralPath $installedCorePath) {
    throw "P08-TOOLCHAIN-CORE-DESTINATION: '$installedCorePath' exists."
  }
  Move-Item `
    -LiteralPath $coreRoots[0].FullName `
    -Destination $installedCorePath
  $installedCoreMarker = Join-Path $installedCorePath 'moon.mod'
  if (-not (Test-Path -LiteralPath $installedCoreMarker -PathType Leaf)) {
    throw 'P08-TOOLCHAIN-CORE-INSTALL: core/moon.mod'
  }
  if (Test-Path -LiteralPath (
      Join-Path $installedCorePath 'moon.mod.json'
    )) {
    throw 'P08-TOOLCHAIN-CORE-INSTALL-LEGACY: core/moon.mod.json'
  }

  Move-Item -LiteralPath $stagingPath -Destination $destination
  $binPath = [IO.Path]::GetFullPath((Join-Path $destination 'bin'))
  $finalCorePath = [IO.Path]::GetFullPath((
    Join-Path $destination 'lib/core'
  ))
  if (-not (Test-Path -LiteralPath (
        Join-Path $finalCorePath 'moon.mod'
      ) -PathType Leaf)) {
    throw 'P08-TOOLCHAIN-CORE-FINAL: core/moon.mod'
  }
  $bundleMoonPath = Join-Path $binPath 'moon'
  $bundlePreviousPath = [string]$env:PATH
  try {
    $env:PATH = if ([string]::IsNullOrEmpty($bundlePreviousPath)) {
      $binPath
    } else {
      $binPath + [IO.Path]::PathSeparator + $bundlePreviousPath
    }
    & $bundleMoonPath `
      -C $finalCorePath `
      bundle `
      --warn-list `
      -a `
      --all
    if ($LASTEXITCODE -ne 0) {
      throw 'P08-TOOLCHAIN-CORE-BUNDLE: --all failed.'
    }
    & $bundleMoonPath `
      -C $finalCorePath `
      bundle `
      --warn-list `
      -a `
      --target wasm-gc `
      --quiet
    if ($LASTEXITCODE -ne 0) {
      throw 'P08-TOOLCHAIN-CORE-BUNDLE: wasm-gc failed.'
    }
  } finally {
    $env:PATH = $bundlePreviousPath
  }
  $bundleTargets = @('js', 'wasm', 'wasm-gc', 'native')
  $bundleLeaves = @('prelude/prelude.mi', 'math/math.mi')
  foreach ($target in $bundleTargets) {
    $bundleRoot = Join-Path (
      Join-Path $finalCorePath "_build/$target/release"
    ) 'bundle'
    foreach ($leaf in $bundleLeaves) {
      $bundleLeaf = Join-Path $bundleRoot $leaf
      if (-not (Test-Path -LiteralPath $bundleLeaf -PathType Leaf)) {
        throw "P08-TOOLCHAIN-CORE-BUNDLE-MISSING: $target/$leaf"
      }
    }
  }
  Add-Content `
    -LiteralPath $env:GITHUB_PATH `
    -Value $binPath `
    -Encoding utf8NoBOM
  Write-Host (
    'Installed content-addressed MoonBit toolchain ' +
    "$($BinaryIdentities.moon) with verified core archive."
  )
} finally {
  $resolvedWorkRoot = [IO.Path]::GetFullPath($workRoot)
  $requiredPrefix = $temporaryBase + [IO.Path]::DirectorySeparatorChar
  if ($resolvedWorkRoot.StartsWith(
      $requiredPrefix,
      [StringComparison]::Ordinal
    ) -and
      (Split-Path -Leaf $resolvedWorkRoot) -like 'mnf-pinned-moonbit-*' -and
      (Test-Path -LiteralPath $resolvedWorkRoot)) {
    Remove-Item -LiteralPath $resolvedWorkRoot -Recurse -Force
  }
}
