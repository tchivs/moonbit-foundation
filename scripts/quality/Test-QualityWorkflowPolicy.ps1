[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Assert-Policy.ps1')

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$workflowDirectory = Join-Path $repositoryRoot '.github/workflows'
$canonicalQuality = Get-Content -Raw -LiteralPath (
  Join-Path $workflowDirectory 'quality.yml'
)
$canonicalAll = @(
  Get-ChildItem -LiteralPath $workflowDirectory -File |
    Where-Object { $_.Extension -in @('.yml', '.yaml') } |
    Sort-Object Name |
    ForEach-Object { Get-Content -Raw -LiteralPath $_.FullName }
) -join "`n"
$canonicalInstaller = Get-Content -Raw -LiteralPath (
  Join-Path $repositoryRoot 'scripts/ci/Install-PinnedMoonBit.ps1'
)

function Invoke-WorkflowPolicyCase {
  param(
    [Parameter(Mandatory)][string]$Name,
    [scriptblock]$Arrange,
    [Parameter(Mandatory)][bool]$ShouldPass,
    [string]$ExpectedFailurePattern
  )

  $state = [pscustomobject]@{
    Quality = $canonicalQuality
    All = $canonicalAll
    Installer = $canonicalInstaller
  }
  if ($null -ne $Arrange) {
    & $Arrange $state
  }
  $failure = $null
  try {
    Assert-QualityWorkflowToolchainTransport `
      -QualityWorkflowText $state.Quality `
      -AllWorkflowText $state.All `
      -InstallerText $state.Installer
  } catch {
    $failure = $_.Exception.Message
  }
  if ($ShouldPass -and $null -ne $failure) {
    throw "Workflow policy case '$Name' expected success: $failure"
  }
  if (-not $ShouldPass -and (
      $null -eq $failure -or
      $failure -cnotmatch $ExpectedFailurePattern
    )) {
    throw (
      "Workflow policy case '$Name' expected '$ExpectedFailurePattern'; " +
      "got '$failure'."
    )
  }
  Write-Host "PASS: $Name"
}

Invoke-WorkflowPolicyCase `
  -Name 'content-addressed MoonBit transport' `
  -ShouldPass $true

Invoke-WorkflowPolicyCase `
  -Name 'setup action latest is forbidden' `
  -Arrange {
    param($state)
    $state.All += "`nversion: latest`n"
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'version latest'

Invoke-WorkflowPolicyCase `
  -Name 'setup-moonbit transport is forbidden' `
  -Arrange {
    param($state)
    $state.All += "`nuses: hustcer/setup-moonbit@deadbeef`n"
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'setup-moonbit transport'

Invoke-WorkflowPolicyCase `
  -Name 'toolchain archive digest is exact' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      '31b7fc5cc78657964a6d545792ecd7fb8eed51b97c7431a17458b58734303381',
      ('0' * 64)
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'archive identity drifted'

Invoke-WorkflowPolicyCase `
  -Name 'core archive digest is exact' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      '03ad55b99f3e431f3cb81b4e2bb28bb98173304e4a1b18a891ea027cabba5d1c',
      ('f' * 64)
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'archive identity drifted'

Invoke-WorkflowPolicyCase `
  -Name 'unapproved latest transport URL is forbidden' `
  -Arrange {
    param($state)
    $state.Installer += (
      "`n`$Unapproved = " +
      "'https://cli.moonbitlang.com/binaries/latest/other.tar.gz'`n"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'mutable transport URL set'

Invoke-WorkflowPolicyCase `
  -Name 'core cannot precede binary verification' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      'foreach ($name in $BinaryHashes.Keys)',
      (
        "Expand-PinnedArchive -ArchivePath `$corePath`n  " +
        'foreach ($name in $BinaryHashes.Keys)'
      )
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'bundle core last'

Invoke-WorkflowPolicyCase `
  -Name 'chmod scope is exactly three verified binaries' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      "    `$binaryPaths['moonrun']`n",
      (
        "    `$binaryPaths['moonrun'],`n" +
        "    `$binaryPaths['moonfmt']`n"
      )
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'executable permission scope'

Invoke-WorkflowPolicyCase `
  -Name 'chmod cannot precede binary digests' `
  -Arrange {
    param($state)
    $chmodLine = (
      "  & `$chmodCommand.Source 'a+x' '--' @verifiedBinaryPaths`n"
    )
    $state.Installer = $state.Installer.Replace($chmodLine, '')
    $state.Installer = $state.Installer.Replace(
      "  `$binaryPaths = [ordered]@{}`n",
      ($chmodLine + "  `$binaryPaths = [ordered]@{}`n")
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'hash binaries before scoped chmod'

Invoke-WorkflowPolicyCase `
  -Name 'identity output requires outer array capture' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      "  `$output = @(`n    switch (`$Name) {",
      "  `$output = (`n    switch (`$Name) {"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'outer array capture'

Invoke-WorkflowPolicyCase `
  -Name 'identity PATH is exactly authenticated staging bin' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      (
        "`$identityBinPath = [IO.Path]::GetFullPath((Join-Path " +
        "`$stagingPath 'bin'))"
      ),
      '$identityBinPath = [IO.Path]::GetFullPath($stagingPath)'
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'exactly authenticated staging/bin'

Invoke-WorkflowPolicyCase `
  -Name 'identity PATH cannot precede execute-bit verification' `
  -Arrange {
    param($state)
    $scopeStartMarker = "  `$previousPath = [string]`$env:PATH`n"
    $scopeEndMarker = (
      "  } finally {`n" +
      "    `$env:PATH = `$previousPath`n" +
      "  }`n"
    )
    $scopeStart = $state.Installer.IndexOf(
      $scopeStartMarker,
      [StringComparison]::Ordinal
    )
    $scopeEnd = $state.Installer.IndexOf(
      $scopeEndMarker,
      $scopeStart,
      [StringComparison]::Ordinal
    ) + $scopeEndMarker.Length
    $scope = $state.Installer.Substring(
      $scopeStart,
      $scopeEnd - $scopeStart
    )
    $state.Installer = $state.Installer.Remove(
      $scopeStart,
      $scopeEnd - $scopeStart
    )
    $executeCheck = $state.Installer.IndexOf(
      '  $executeMask = (',
      [StringComparison]::Ordinal
    )
    $state.Installer = $state.Installer.Insert($executeCheck, $scope)
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'verify execute bits'

Invoke-WorkflowPolicyCase `
  -Name 'identity PATH is restored in finally' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      '    $env:PATH = $previousPath',
      '    $env:PATH = $identityBinPath'
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'finally restoration'

Invoke-WorkflowPolicyCase `
  -Name 'identity checks cannot expose a broader process PATH' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      '  $previousPath = [string]$env:PATH',
      "  `$env:PATH = `$stagingPath`n  `$previousPath = [string]`$env:PATH"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'broader process PATH'

Invoke-WorkflowPolicyCase `
  -Name 'core archive requires the current moon.mod marker' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      "    -RequiredMember './core/moon.mod' ``",
      "    -RequiredMember './core/README.md' ``"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'exact ./core/ layout'

Invoke-WorkflowPolicyCase `
  -Name 'core archive rejects a legacy-only marker policy' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      "    -RequiredMember './core/moon.mod' ``",
      "    -RequiredMember './core/moon.mod.json' ``"
    ).Replace(
      "    -ForbiddenMembers @('./core/moon.mod.json')",
      "    -ForbiddenMembers @('./core/moon.mod')"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'exact ./core/ layout'

Invoke-WorkflowPolicyCase `
  -Name 'core archive rejects ambiguous current and legacy markers' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      "    -ForbiddenMembers @('./core/moon.mod.json')",
      '    -ForbiddenMembers @()'
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'exact ./core/ layout'

Invoke-WorkflowPolicyCase `
  -Name 'core archive rejects a broadened root layout' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      "    -ExpectedRoot './core/' ``",
      "    -ExpectedRoot './' ``"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'exact ./core/ layout'

Invoke-WorkflowPolicyCase `
  -Name 'extracted core cannot regress to the legacy marker' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      "  `$coreMarker = Join-Path `$libraryPath 'core/moon.mod'",
      "  `$coreMarker = Join-Path `$libraryPath 'core/moon.mod.json'"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'extracted core'

Write-Host 'Quality workflow content-addressed toolchain policy matrix passed.'
