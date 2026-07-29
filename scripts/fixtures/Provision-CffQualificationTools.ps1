[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$HostToolchainInputPath,

  [Parameter(Mandatory)]
  [string]$ExecutionHandoffPath,

  [Parameter(Mandatory)]
  [string]$StagingRoot,

  [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Utf8NoBom = [Text.UTF8Encoding]::new($false)
$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$LockPath = Join-Path $RepositoryRoot 'fixtures/font/cff/host-toolchain.lock.json'
$FontToolsAdapterPath = Join-Path $PSScriptRoot 'oracles/fonttools_cff_oracle.py'
$AfdkoAdapterPath = Join-Path $PSScriptRoot 'oracles/Invoke-AfdkoCffOracle.ps1'
$ProvisionedManifestPath = Join-Path $StagingRoot 'provisioned-tools.json'

function Get-Sha256 {
  param([Parameter(Mandatory)][string]$Path)
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Get-StringSha256 {
  param([Parameter(Mandatory)][string]$Text)
  return [Convert]::ToHexString(
    [Security.Cryptography.SHA256]::HashData($Utf8NoBom.GetBytes($Text))
  ).ToLowerInvariant()
}

function Assert-OrderedKeys {
  param(
    [Parameter(Mandatory)]$Value,
    [Parameter(Mandatory)][string[]]$Expected,
    [Parameter(Mandatory)][string]$Label
  )
  $actual = @($Value.psobject.Properties.Name)
  if ((Compare-Object -CaseSensitive $Expected $actual) -or
      ($Expected -join "`n") -cne ($actual -join "`n")) {
    throw "$Label ordered keys drifted."
  }
}

function Assert-OrderedValues {
  param(
    [Parameter(Mandatory)][object[]]$Actual,
    [Parameter(Mandatory)][object[]]$Expected,
    [Parameter(Mandatory)][string]$Label
  )
  if (($Actual -join "`n") -cne ($Expected -join "`n")) {
    throw "$Label order or membership drifted."
  }
}

function Assert-NoReparseComponents {
  param([Parameter(Mandatory)][string]$Path)
  $currentPath = [IO.Path]::GetFullPath($Path)
  while ($null -ne $currentPath) {
    $current = Get-Item -LiteralPath $currentPath -Force
    if (($current.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
      throw "Reparse-point path component is forbidden: $($current.FullName)"
    }
    $parent = [IO.Directory]::GetParent($currentPath)
    $currentPath = if ($null -eq $parent) { $null } else { $parent.FullName }
  }
}

function Assert-CanonicalAbsolutePath {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][bool]$Directory,
    [Parameter(Mandatory)][string]$Label
  )
  if (-not [IO.Path]::IsPathFullyQualified($Path) -or
      $Path.IndexOf('%') -ge 0 -or
      $Path.IndexOf('$') -ge 0) {
    throw "$Label path is not literal and absolute."
  }
  $full = [IO.Path]::GetFullPath($Path)
  $resolved = (Resolve-Path -LiteralPath $Path).Path
  if ($full -cne $resolved) { throw "$Label path is not canonical." }
  if ($Directory) {
    if (-not (Test-Path -LiteralPath $resolved -PathType Container)) {
      throw "$Label directory is missing."
    }
  } elseif (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
    throw "$Label regular file is missing."
  }
  Assert-NoReparseComponents $resolved
  if (-not $Directory) {
    $item = Get-Item -LiteralPath $resolved -Force
    if ($item.Mode -cne $item.ModeWithoutHardLink) {
      throw "$Label has a hardlink alias."
    }
  }
  return $resolved
}

function Test-PathWithinRoot {
  param([string]$Path, [string]$Root)
  $pathFull = [IO.Path]::GetFullPath($Path).TrimEnd('\')
  $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\')
  return $pathFull.Equals($rootFull, [StringComparison]::OrdinalIgnoreCase) -or
    $pathFull.StartsWith($rootFull + '\', [StringComparison]::OrdinalIgnoreCase)
}

function Invoke-LockedProcess {
  param(
    [Parameter(Mandatory)][string]$Executable,
    [Parameter(Mandatory)][string[]]$Arguments,
    [Parameter(Mandatory)][string]$WorkingDirectory,
    [Parameter(Mandatory)]$Manifest,
    [string]$Label = 'locked process'
  )
  $info = [Diagnostics.ProcessStartInfo]::new()
  $info.FileName = $Executable
  $info.WorkingDirectory = $WorkingDirectory
  $info.UseShellExecute = $false
  $info.RedirectStandardOutput = $true
  $info.RedirectStandardError = $true
  $info.CreateNoWindow = $true
  foreach ($argument in $Arguments) { [void]$info.ArgumentList.Add($argument) }
  $info.Environment.Clear()
  $info.Environment['SystemRoot'] = $env:SystemRoot
  $info.Environment['TEMP'] = Join-Path $StagingRoot 'tmp'
  $info.Environment['TMP'] = Join-Path $StagingRoot 'tmp'
  $info.Environment['PATH'] = (@($Manifest.sanitized_environment.PATH) -join ';')
  foreach ($name in @('NINJA','VSINSTALLDIR','PYTHONPATH','PYTHONHOME','CC','CXX','AR','LD','PKG_CONFIG_PATH','PKG_CONFIG_LIBDIR')) {
    $value = [string]$Manifest.sanitized_environment.$name
    $info.Environment[$name] = $value
  }
  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $info
  if (-not $process.Start()) { throw "$Label did not start." }
  $stdoutTask = $process.StandardOutput.ReadToEndAsync()
  $stderrTask = $process.StandardError.ReadToEndAsync()
  $process.WaitForExit()
  $stdout = $stdoutTask.GetAwaiter().GetResult()
  $stderr = $stderrTask.GetAwaiter().GetResult()
  if ($process.ExitCode -ne 0) {
    throw "$Label failed with exit $($process.ExitCode).`n$stdout`n$stderr"
  }
  return [ordered]@{ stdout = $stdout; stderr = $stderr }
}

function Assert-Inventory {
  param(
    [Parameter(Mandatory)]$Inventory,
    [Parameter(Mandatory)][string]$Label,
    [switch]$SkipHashes
  )
  Assert-OrderedKeys $Inventory @(
    'root','file_count','total_bytes','inventory_sha256','files'
  ) $Label
  $root = Assert-CanonicalAbsolutePath $Inventory.root $true "$Label root"
  $files = @(Get-ChildItem -LiteralPath $root -Recurse -File -Force |
    Sort-Object -CaseSensitive -Property FullName)
  $declared = @($Inventory.files)
  if ($files.Count -ne [int]$Inventory.file_count -or
      $declared.Count -ne [int]$Inventory.file_count) {
    throw "$Label file count drifted."
  }
  $actualPaths = @($files | ForEach-Object { $_.FullName })
  $declaredPaths = @($declared | ForEach-Object { [string]$_.path })
  Assert-OrderedValues $declaredPaths $actualPaths "$Label files"
  for ($index = 0; $index -lt $declared.Count; $index++) {
    $record = $declared[$index]
    Assert-OrderedKeys $record @('path','length','sha256') "$Label file $index"
    $path = Assert-CanonicalAbsolutePath $record.path $false "$Label file $index"
    if (-not (Test-PathWithinRoot $path $root)) {
      throw "$Label file escapes its root."
    }
    $item = Get-Item -LiteralPath $path
    if ($item.Length -ne [int64]$record.length) {
      throw "$Label file length drifted: $path"
    }
    if (-not $SkipHashes -and (Get-Sha256 $path) -cne [string]$record.sha256) {
      throw "$Label file SHA-256 drifted: $path"
    }
  }
}

function Assert-HostManifest {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)]$Lock,
    [switch]$SkipPinnedManifestHash,
    [switch]$SkipInventoryHashes,
    [switch]$SkipInventories,
    [switch]$SkipVersionInvocations
  )
  $manifestPath = Assert-CanonicalAbsolutePath $Path $false 'caller manifest'
  if (-not $SkipPinnedManifestHash -and
      (Get-Sha256 $manifestPath) -cne [string]$Lock.approved_manifest_sha256) {
    throw 'Caller manifest SHA-256 differs from the approved lock.'
  }
  $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
  Assert-OrderedKeys $manifest @(
    'schema','platform','created_at','permitted_roots','ordered_role_ids','roles',
    'runtime_inventories','sdk_inventories','sdk_inventory_sha256',
    'sanitized_environment','commands','preflight_result','preflight_validated'
  ) 'caller manifest'
  if ($manifest.schema -cne $Lock.approved_manifest_schema -or
      $manifest.platform -cne $Lock.platform -or
      $manifest.preflight_validated -ne $true) {
    throw 'Caller manifest header or approval drifted.'
  }
  Assert-OrderedValues @($manifest.ordered_role_ids) @($Lock.ordered_role_ids) 'caller roles'
  if (@($manifest.roles).Count -ne @($Lock.ordered_role_ids).Count) {
    throw 'Caller role cardinality drifted.'
  }

  $permittedRoots = @()
  foreach ($root in @($manifest.permitted_roots)) {
    $permittedRoots += Assert-CanonicalAbsolutePath $root $true 'permitted root'
  }
  $roleById = @{}
  for ($index = 0; $index -lt @($manifest.roles).Count; $index++) {
    $role = $manifest.roles[$index]
    Assert-OrderedKeys $role @($Lock.required_role_keys) "role $index"
    if ($role.id -cne $Lock.ordered_role_ids[$index] -or
        $roleById.ContainsKey([string]$role.id)) {
      throw "Role order or uniqueness drifted at $index."
    }
    $roleById[[string]$role.id] = $role
    if (-not $role.purpose -or -not $role.provenance) {
      throw "Role metadata is incomplete: $($role.id)"
    }
    if ($null -ne $role.version_invocation -and
        [string]$role.version -cne [string]$role.version_invocation.expected) {
      throw "Role version contract is internally inconsistent: $($role.id)"
    }
    $isSdk = $role.kind -ceq 'sdk-root'
    $resolved = Assert-CanonicalAbsolutePath $role.path $isSdk "role $($role.id)"
    $parent = Assert-CanonicalAbsolutePath $role.permitted_parent_root $true "role $($role.id) parent"
    if (-not (Test-PathWithinRoot $resolved $parent) -or
        -not (@($permittedRoots | Where-Object { Test-PathWithinRoot $resolved $_ }))) {
      throw "Role path is outside declared authority: $($role.id)"
    }
    if (-not $isSdk) {
      $item = Get-Item -LiteralPath $resolved
      if ($item.Length -ne [int64]$role.length -or
          (Get-Sha256 $resolved) -cne [string]$role.sha256) {
        throw "Role identity drifted: $($role.id)"
      }
      if ($null -ne $role.hardlink_aliases -and [int]$role.hardlink_aliases -ne 1) {
        throw "Role hardlink count is not closed: $($role.id)"
      }
    }
  }

  if (@($manifest.sdk_inventories).Count -ne 1) {
    throw 'Exactly one SDK inventory is required.'
  }
  if (-not $SkipInventories) {
    foreach ($inventory in @($manifest.runtime_inventories)) {
      Assert-Inventory $inventory 'runtime inventory' -SkipHashes:$SkipInventoryHashes
    }
    Assert-Inventory $manifest.sdk_inventories[0] 'SDK inventory' -SkipHashes:$SkipInventoryHashes
  }
  if ($manifest.sdk_inventory_sha256 -cne $Lock.sdk_inventory_sha256 -or
      $manifest.sdk_inventories[0].inventory_sha256 -cne $Lock.sdk_inventory_sha256 -or
      $roleById['sdk.llvm-mingw-x86_64'].sha256 -cne $Lock.sdk_inventory_sha256) {
    throw 'SDK inventory digest drifted.'
  }

  Assert-OrderedValues @($manifest.commands.id) @($Lock.ordered_command_ids) 'OTS commands'
  if ($manifest.commands[0].executable -cne $roleById['runtime.cpython'].path -or
      $manifest.commands[1].executable -cne $roleById['build.ninja'].path -or
      $manifest.commands[2].executable -cne $roleById['build.ninja'].path) {
    throw 'OTS command executable drifted.'
  }
  $configureArgs = @($manifest.commands[0].arguments)
  if ('--wrap-mode=nodownload' -cnotin $configureArgs -or
      $roleById['config.meson-native'].path -cnotin $configureArgs) {
    throw 'OTS configure command permits dependency discovery.'
  }
  if (@($manifest.sanitized_environment.PATH).Count -ne 1 -or
      -not (Test-PathWithinRoot $manifest.sanitized_environment.PATH[0] $roleById['sdk.llvm-mingw-x86_64'].path)) {
    throw 'Sanitized PATH is not closed over the SDK.'
  }
  foreach ($name in @('PYTHONPATH','PYTHONHOME','CC','CXX','AR','LD','PKG_CONFIG_PATH','PKG_CONFIG_LIBDIR')) {
    if ([string]$manifest.sanitized_environment.$name -cne '') {
      throw "Ambient environment field is not empty: $name"
    }
  }

  if (-not $SkipVersionInvocations) {
    foreach ($role in @($manifest.roles | Where-Object { $null -ne $_.version_invocation })) {
      $invocation = $role.version_invocation
      $result = Invoke-LockedProcess `
        -Executable $invocation.executable `
        -Arguments @($invocation.arguments) `
        -WorkingDirectory $StagingRoot `
        -Manifest $manifest `
        -Label "version $($role.id)"
      $line = @((($result.stdout + "`n" + $result.stderr) -split "`r?`n") |
        Where-Object { $_ })[0]
      if ($line -cne [string]$invocation.expected) {
        throw "Role version drifted: $($role.id): $line"
      }
    }
  }
  return [ordered]@{ manifest = $manifest; roles = $roleById }
}

function Expand-LinkFreeArchive {
  param(
    [Parameter(Mandatory)][string]$ArchivePath,
    [Parameter(Mandatory)][string]$Destination
  )
  if (Test-Path -LiteralPath $Destination) {
    throw "Archive destination already exists: $Destination"
  }
  [void](New-Item -ItemType Directory -Path $Destination)
  $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
  try {
    foreach ($entry in $archive.Entries) {
      $mode = ($entry.ExternalAttributes -shr 16) -band 0xF000
      if ($mode -eq 0xA000) { throw "Archive contains a symbolic link: $($entry.FullName)" }
      $target = [IO.Path]::GetFullPath((Join-Path $Destination $entry.FullName))
      if (-not (Test-PathWithinRoot $target $Destination)) {
        throw "Archive member escapes destination: $($entry.FullName)"
      }
    }
  } finally {
    $archive.Dispose()
  }
  [IO.Compression.ZipFile]::ExtractToDirectory($ArchivePath, $Destination)
  foreach ($item in Get-ChildItem -LiteralPath $Destination -Recurse -Force) {
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
      throw "Extracted archive contains a reparse point: $($item.FullName)"
    }
  }
}

function Receive-PinnedFile {
  param([Parameter(Mandatory)]$Record, [Parameter(Mandatory)][string]$Destination)
  if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
    Invoke-WebRequest -UseBasicParsing -Uri $Record.url -OutFile $Destination
  }
  $item = Get-Item -LiteralPath $Destination
  if ($item.Length -ne [int64]$Record.length -or
      (Get-Sha256 $Destination) -cne [string]$Record.sha256) {
    throw "Pinned acquisition identity drifted: $($Record.id)"
  }
}

function Write-AtomicJson {
  param([string]$Path, [Parameter(Mandatory)]$Value)
  $json = ($Value | ConvertTo-Json -Depth 20) + "`n"
  $temporary = "$Path.tmp-$([guid]::NewGuid().ToString('N'))"
  [IO.File]::WriteAllText($temporary, $json, $Utf8NoBom)
  Move-Item -LiteralPath $temporary -Destination $Path -Force
}

if (-not (Test-Path -LiteralPath $LockPath -PathType Leaf)) {
  throw "Host-toolchain lock is missing: $LockPath"
}
$lock = Get-Content -Raw -LiteralPath $LockPath | ConvertFrom-Json
if ($lock.schema -cne 'host-toolchain-lock/1.0.0') {
  throw 'Host-toolchain lock schema drifted.'
}

$handoffFull = [IO.Path]::GetFullPath((Join-Path $RepositoryRoot $ExecutionHandoffPath))
if (-not (Test-PathWithinRoot $handoffFull (Join-Path $RepositoryRoot 'artifacts/release-qualification/phase-107'))) {
  throw 'Execution handoff is outside the ignored Phase 107 artifact root.'
}
if (-not (Test-Path -LiteralPath $handoffFull -PathType Leaf)) {
  throw 'Execution handoff is missing.'
}
$handoff = Get-Content -Raw -LiteralPath $handoffFull | ConvertFrom-Json
if ($handoff.schema -cne 'mnf-phase107-host-toolchain-handoff/1.0.0' -or
    $handoff.preflight_validated -ne $true) {
  throw 'Execution handoff preflight is not approved.'
}
$hostInputFull = Assert-CanonicalAbsolutePath $HostToolchainInputPath $false 'host input'
if ($hostInputFull -cne [string]$handoff.manifest_path -or
    (Get-Sha256 $hostInputFull) -cne [string]$handoff.manifest_sha256 -or
    $handoff.manifest_sha256 -cne [string]$lock.approved_manifest_sha256) {
  throw 'Execution handoff does not bind the approved caller manifest.'
}

[void](New-Item -ItemType Directory -Force -Path $StagingRoot)
[void](New-Item -ItemType Directory -Force -Path (Join-Path $StagingRoot 'tmp'))
$validated = Assert-HostManifest $hostInputFull $lock `
  -SkipInventoryHashes:$Check `
  -SkipVersionInvocations:$Check
$manifest = $validated.manifest
$roles = $validated.roles

if ($Check) {
  if (-not (Test-Path -LiteralPath $ProvisionedManifestPath -PathType Leaf)) {
    throw 'Provisioned tool manifest is missing.'
  }
  $provisioned = Get-Content -Raw -LiteralPath $ProvisionedManifestPath | ConvertFrom-Json
  if ($provisioned.schema -cne 'cff-provisioned-tools/1.0.0' -or
      $provisioned.provisioning_validated -ne $true) {
    throw 'Provisioned tool manifest is incomplete.'
  }
  foreach ($entry in @($provisioned.invoked_identities)) {
    if (-not (Test-Path -LiteralPath $entry.path -PathType Leaf) -or
        (Get-Sha256 $entry.path) -cne [string]$entry.sha256) {
      throw "Provisioned invoked identity drifted: $($entry.id)"
    }
  }

  $negativeCases = @(
    [ordered]@{ id='missing-role'; mutate={
      param($copy); $copy.roles = @($copy.roles | Select-Object -SkipLast 1)
    }},
    [ordered]@{ id='extra-role'; mutate={
      param($copy); $copy.roles = @($copy.roles) + @($copy.roles[-1])
    }},
    [ordered]@{ id='relative-path'; mutate={
      param($copy); $copy.roles[0].path = 'python.exe'
    }},
    [ordered]@{ id='global-path'; mutate={
      param($copy); $copy.roles[0].path = Join-Path $env:SystemRoot 'System32/cmd.exe'
    }},
    [ordered]@{ id='version-mismatch'; mutate={
      param($copy); $copy.roles[0].version = 'Python 0'
    }},
    [ordered]@{ id='hash-mismatch'; mutate={
      param($copy); $copy.roles[0].sha256 = ('0' * 64)
    }},
    [ordered]@{ id='provenance-missing'; mutate={
      param($copy); $copy.roles[0].provenance = ''
    }},
    [ordered]@{ id='dependency-omission'; mutate={
      param($copy); $copy.ordered_role_ids = @($copy.ordered_role_ids | Where-Object { $_ -cne 'source.zlib' })
    }},
    [ordered]@{ id='wrap-download'; mutate={
      param($copy); $copy.commands[0].arguments = @($copy.commands[0].arguments | Where-Object { $_ -cne '--wrap-mode=nodownload' })
    }},
    [ordered]@{ id='undeclared-child'; mutate={
      param($copy); $copy.commands = @($copy.commands) + [pscustomobject]@{ id='ambient.child'; executable='cmd.exe'; arguments=@() }
    }}
  )
  foreach ($negative in $negativeCases) {
    $copy = ($manifest | ConvertTo-Json -Depth 20 | ConvertFrom-Json)
    & $negative.mutate $copy
    $path = Join-Path $StagingRoot "negative-$($negative.id).json"
    Write-AtomicJson $path $copy
    $failed = $false
    try {
      [void](Assert-HostManifest $path $lock -SkipPinnedManifestHash -SkipInventoryHashes -SkipInventories -SkipVersionInvocations)
    } catch {
      $failed = $true
    }
    if (-not $failed) { throw "Negative did not fail closed: $($negative.id)" }
  }
  Write-Host 'CFF qualification provisioner negatives passed.'
  return
}

$downloadsRoot = Join-Path $StagingRoot 'downloads'
$fontToolsSite = Join-Path $StagingRoot 'fonttools-site'
$afdkoSite = Join-Path $StagingRoot 'afdko-site'
[void](New-Item -ItemType Directory -Force -Path $downloadsRoot)
$fontToolsWheel = Join-Path $downloadsRoot 'fonttools-4.63.0.whl'
$afdkoWheel = Join-Path $downloadsRoot 'afdko-5.0.1.whl'
Receive-PinnedFile $lock.semantic_readers[0] $fontToolsWheel
Receive-PinnedFile $lock.semantic_readers[1] $afdkoWheel
if (-not (Test-Path -LiteralPath $fontToolsSite)) {
  $zip = "$fontToolsWheel.zip"
  Copy-Item -LiteralPath $fontToolsWheel -Destination $zip
  Expand-LinkFreeArchive $zip $fontToolsSite
}
if (-not (Test-Path -LiteralPath $afdkoSite)) {
  $zip = "$afdkoWheel.zip"
  Copy-Item -LiteralPath $afdkoWheel -Destination $zip
  Expand-LinkFreeArchive $zip $afdkoSite
}

$txRunnerPath = Join-Path $StagingRoot 'tx_runner.py'
$txRunner = @'
import pathlib
import sys
site = pathlib.Path(sys.argv[1]).resolve(strict=True)
sys.path.insert(0, str(site))
from afdko import _internal
sys.argv = ["tx"] + sys.argv[2:]
raise SystemExit(_internal.tx())
'@
[IO.File]::WriteAllText($txRunnerPath, $txRunner.Replace("`r`n", "`n"), $Utf8NoBom)

$otsRoot = Join-Path $StagingRoot 'ots'
$otsSourceContainer = Join-Path $otsRoot 'source'
$otsBuildRoot = Join-Path $otsRoot 'build'
$otsExecutable = Join-Path $otsBuildRoot 'ots-sanitize.exe'
if (-not (Test-Path -LiteralPath $otsExecutable -PathType Leaf)) {
  [void](New-Item -ItemType Directory -Force -Path $otsRoot)
  Expand-LinkFreeArchive $roles['source.ots'].path $otsSourceContainer
  $sourceRoots = @(Get-ChildItem -LiteralPath $otsSourceContainer -Directory)
  if ($sourceRoots.Count -ne 1) { throw 'OTS source archive root drifted.' }
  $otsSourceRoot = $sourceRoots[0].FullName
  $packageCache = Join-Path $otsSourceRoot 'subprojects/packagecache'
  [void](New-Item -ItemType Directory -Force -Path $packageCache)
  foreach ($roleId in @(
      'source.zlib','patch.zlib','source.woff2','patch.woff2',
      'source.brotli','patch.brotli','source.lz4','patch.lz4',
      'source.gtest','patch.gtest'
    )) {
    Copy-Item -LiteralPath $roles[$roleId].path -Destination $packageCache
  }
  $configureArgs = @($manifest.commands[0].arguments | ForEach-Object {
    if ($_ -ceq '{build_root}') { $otsBuildRoot } else { [string]$_ }
  })
  [void](Invoke-LockedProcess `
    -Executable $manifest.commands[0].executable `
    -Arguments $configureArgs `
    -WorkingDirectory $otsSourceRoot `
    -Manifest $manifest `
    -Label 'OTS configure')
  foreach ($command in @($manifest.commands[1], $manifest.commands[2])) {
    $arguments = @($command.arguments | ForEach-Object {
      if ($_ -ceq '{build_root}') { $otsBuildRoot } else { [string]$_ }
    })
    [void](Invoke-LockedProcess `
      -Executable $command.executable `
      -Arguments $arguments `
      -WorkingDirectory $otsSourceRoot `
      -Manifest $manifest `
      -Label $command.id)
  }
}
if (-not (Test-Path -LiteralPath $otsExecutable -PathType Leaf)) {
  throw 'OTS build completed without ots-sanitize.'
}

$invoked = @(
  [ordered]@{ id='runtime.cpython'; path=$roles['runtime.cpython'].path; sha256=$roles['runtime.cpython'].sha256 },
  [ordered]@{ id='build.meson'; path=$roles['build.meson'].path; sha256=$roles['build.meson'].sha256 },
  [ordered]@{ id='build.ninja'; path=$roles['build.ninja'].path; sha256=$roles['build.ninja'].sha256 },
  [ordered]@{ id='compiler.c'; path=$roles['compiler.c'].path; sha256=$roles['compiler.c'].sha256 },
  [ordered]@{ id='compiler.cpp'; path=$roles['compiler.cpp'].path; sha256=$roles['compiler.cpp'].sha256 },
  [ordered]@{ id='linker'; path=$roles['linker'].path; sha256=$roles['linker'].sha256 },
  [ordered]@{ id='ots-sanitize'; path=$otsExecutable; sha256=(Get-Sha256 $otsExecutable) },
  [ordered]@{ id='fonttools-adapter'; path=$FontToolsAdapterPath; sha256=(Get-Sha256 $FontToolsAdapterPath) },
  [ordered]@{ id='afdko-adapter'; path=$AfdkoAdapterPath; sha256=(Get-Sha256 $AfdkoAdapterPath) },
  [ordered]@{ id='tx-runner'; path=$txRunnerPath; sha256=(Get-Sha256 $txRunnerPath) }
)
$invokedCanonical = $invoked | ConvertTo-Json -Depth 5 -Compress
$provisioned = [ordered]@{
  schema = 'cff-provisioned-tools/1.0.0'
  manifest_sha256 = $handoff.manifest_sha256
  lock_sha256 = Get-Sha256 $LockPath
  sdk_inventory_sha256 = $manifest.sdk_inventory_sha256
  fonttools_site_root = $fontToolsSite
  afdko_site_root = $afdkoSite
  tx_runner_path = $txRunnerPath
  ots_sanitize_path = $otsExecutable
  invoked_identities = $invoked
  invoked_identities_sha256 = Get-StringSha256 $invokedCanonical
  adapter_sha256 = [ordered]@{
    fonttools = Get-Sha256 $FontToolsAdapterPath
    afdko = Get-Sha256 $AfdkoAdapterPath
  }
  provisioning_validated = $true
}
Write-AtomicJson $ProvisionedManifestPath $provisioned

$updatedHandoff = [ordered]@{
  schema = $handoff.schema
  manifest_path = $handoff.manifest_path
  manifest_sha256 = $handoff.manifest_sha256
  preflight_timestamp = $handoff.preflight_timestamp
  ordered_role_ids = @($handoff.ordered_role_ids)
  preflight_sdk_inventory_sha256 = $handoff.sdk_inventory_sha256
  preflight_validated = $true
  lock_sha256 = $provisioned.lock_sha256
  provisioned_tools_root = (Resolve-Path -LiteralPath $StagingRoot).Path
  sdk_inventory_sha256 = $provisioned.sdk_inventory_sha256
  invoked_identities = @($provisioned.invoked_identities)
  invoked_identities_sha256 = $provisioned.invoked_identities_sha256
  adapter_sha256 = $provisioned.adapter_sha256
  ots_executable_sha256 = (Get-Sha256 $otsExecutable)
  provisioning_validated = $true
}
Write-AtomicJson $handoffFull $updatedHandoff
Write-Host 'CFF qualification tools provisioned through the locked host chain.'
