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
  -Name 'all installer step shells reject bash' `
  -Arrange {
    param($state)
    $installStep = @(
      '      - name: Install content-addressed MoonBit toolchain',
      '        shell: pwsh',
      '        run: ./scripts/ci/Install-PinnedMoonBit.ps1'
    ) -join "`n"
    $bashInstallStep = $installStep.Replace(
      '        shell: pwsh',
      '        shell: bash'
    )
    $state.Quality = $state.Quality.Replace(
      $installStep,
      $bashInstallStep
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'must bind the exact installer name'

Invoke-WorkflowPolicyCase `
  -Name 'installer shell cannot be omitted despite pwsh elsewhere' `
  -Arrange {
    param($state)
    $installStep = @(
      '      - name: Install content-addressed MoonBit toolchain',
      '        shell: pwsh',
      '        run: ./scripts/ci/Install-PinnedMoonBit.ps1'
    ) -join "`n"
    $state.Quality = $state.Quality.Replace(
      $installStep,
      $installStep.Replace("        shell: pwsh`n", '')
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'must bind the exact installer name'

Invoke-WorkflowPolicyCase `
  -Name 'installer shell cannot rely on an inherited pwsh default' `
  -Arrange {
    param($state)
    $installStep = @(
      '      - name: Install content-addressed MoonBit toolchain',
      '        shell: pwsh',
      '        run: ./scripts/ci/Install-PinnedMoonBit.ps1'
    ) -join "`n"
    $state.Quality = $state.Quality.Replace(
      "jobs:`n",
      "defaults:`n  run:`n    shell: pwsh`njobs:`n"
    ).Replace(
      $installStep,
      $installStep.Replace("        shell: pwsh`n", '')
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'must bind the exact installer name'

Invoke-WorkflowPolicyCase `
  -Name 'installer shell field cannot be duplicated' `
  -Arrange {
    param($state)
    $installStep = @(
      '      - name: Install content-addressed MoonBit toolchain',
      '        shell: pwsh',
      '        run: ./scripts/ci/Install-PinnedMoonBit.ps1'
    ) -join "`n"
    $state.Quality = $state.Quality.Replace(
      $installStep,
      $installStep.Replace(
        '        shell: pwsh',
        "        shell: pwsh`n        shell: pwsh"
      )
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'without extra, duplicated, or reordered fields'

Invoke-WorkflowPolicyCase `
  -Name 'installer shell and run fields cannot be reordered' `
  -Arrange {
    param($state)
    $installStep = @(
      '      - name: Install content-addressed MoonBit toolchain',
      '        shell: pwsh',
      '        run: ./scripts/ci/Install-PinnedMoonBit.ps1'
    ) -join "`n"
    $reorderedInstallStep = @(
      '      - name: Install content-addressed MoonBit toolchain',
      '        run: ./scripts/ci/Install-PinnedMoonBit.ps1',
      '        shell: pwsh'
    ) -join "`n"
    $state.Quality = $state.Quality.Replace(
      $installStep,
      $reorderedInstallStep
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'without extra, duplicated, or reordered fields'

Invoke-WorkflowPolicyCase `
  -Name 'installer run field cannot be duplicated' `
  -Arrange {
    param($state)
    $installStep = @(
      '      - name: Install content-addressed MoonBit toolchain',
      '        shell: pwsh',
      '        run: ./scripts/ci/Install-PinnedMoonBit.ps1'
    ) -join "`n"
    $state.Quality = $state.Quality.Replace(
      $installStep,
      (
        $installStep + "`n" +
        '        run: ./scripts/ci/Install-PinnedMoonBit.ps1'
      )
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'without extra, duplicated, or reordered fields'

Invoke-WorkflowPolicyCase `
  -Name 'Required outer timeout cannot drift independently' `
  -Arrange {
    param($state)
    $state.Quality = $state.Quality.Replace(
      "  required:`n    name: Required quality contract`n" +
        "    runs-on: ubuntu-latest`n    timeout-minutes: 25",
      "  required:`n    name: Required quality contract`n" +
        "    runs-on: ubuntu-latest`n    timeout-minutes: 26"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'exact paired timeout budget'

Invoke-WorkflowPolicyCase `
  -Name 'Required wrapper timeout cannot drift independently' `
  -Arrange {
    param($state)
    $state.Quality = $state.Quality.Replace(
      '-TimeoutSeconds 1200',
      '-TimeoutSeconds 1199'
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'exact paired timeout budget'

Invoke-WorkflowPolicyCase `
  -Name 'Required paired timeout cannot drift together' `
  -Arrange {
    param($state)
    $state.Quality = $state.Quality.Replace(
      "  required:`n    name: Required quality contract`n" +
        "    runs-on: ubuntu-latest`n    timeout-minutes: 25",
      "  required:`n    name: Required quality contract`n" +
        "    runs-on: ubuntu-latest`n    timeout-minutes: 30"
    ).Replace(
      '-TimeoutSeconds 1200',
      '-TimeoutSeconds 1500'
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'exact paired timeout budget'

Invoke-WorkflowPolicyCase `
  -Name 'Required timeout pair cannot invert cleanup margin' `
  -Arrange {
    param($state)
    $state.Quality = $state.Quality.Replace(
      "  required:`n    name: Required quality contract`n" +
        "    runs-on: ubuntu-latest`n    timeout-minutes: 25",
      "  required:`n    name: Required quality contract`n" +
        "    runs-on: ubuntu-latest`n    timeout-minutes: 19"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'must exceed its bounded wrapper timeout'

Invoke-WorkflowPolicyCase `
  -Name 'non-Required job budgets cannot expand' `
  -Arrange {
    param($state)
    $state.Quality = $state.Quality.Replace(
      "  font-qualification:`n    name: Portable font qualification`n" +
        "    runs-on: ubuntu-latest`n    timeout-minutes: 20",
      "  font-qualification:`n    name: Portable font qualification`n" +
        "    runs-on: ubuntu-latest`n    timeout-minutes: 25"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'Only the Required job may use the expanded'

Invoke-WorkflowPolicyCase `
  -Name 'Required bounded step remains fail-closed' `
  -Arrange {
    param($state)
    $state.Quality = $state.Quality.Replace(
      '        run: ./scripts/quality/Invoke-RequiredBounded.ps1 ' +
        '-EvidenceDirectory artifacts/release-qualification/ci-required ' +
        '-TimeoutSeconds 1200',
      '        continue-on-error: true' + "`n" +
        '        run: ./scripts/quality/Invoke-RequiredBounded.ps1 ' +
        '-EvidenceDirectory artifacts/release-qualification/ci-required ' +
        '-TimeoutSeconds 1200'
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'exact fail-closed bounded quality step'

Invoke-WorkflowPolicyCase `
  -Name 'Required diagnostic upload remains unconditional' `
  -Arrange {
    param($state)
    $state.Quality = $state.Quality.Replace(
      '        if: ${{ always() }}',
      '        if: ${{ success() }}'
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'must always upload'

Invoke-WorkflowPolicyCase `
  -Name 'Required POSIX containment gate cannot be removed' `
  -Arrange {
    param($state)
    $posixStep = @(
      '      - name: Verify Required POSIX process containment',
      '        shell: pwsh',
      '        run: ./scripts/quality/Test-RequiredProcessTreeTermination.ps1'
    ) -join "`n"
    $state.Quality = $state.Quality.Replace($posixStep + "`n", '')
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'blocking POSIX containment gate'

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
  -Name 'installer latest transport URL is forbidden' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      (
        'https://github.com/tchivs/moonbit-foundation/releases/download/' +
        'ci-toolchain-0.1.20260713-75c7e1f/' +
        'moonbit-linux-x86_64-0.1.20260713-75c7e1f.tar.gz'
      ),
      'https://cli.moonbitlang.com/binaries/latest/moonbit-linux-x86_64.tar.gz'
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'must not use mutable latest archive URLs'

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
  -Name 'executable member manifest rejects a missing helper' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      "  'bin/mooninfo',`n",
      ''
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'executable member manifest'

Invoke-WorkflowPolicyCase `
  -Name 'executable member manifest rejects an extra helper' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      "  'bin/moonrun'`n)",
      "  'bin/moonrun',`n  'bin/extra-helper'`n)"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'executable member manifest'

Invoke-WorkflowPolicyCase `
  -Name 'chmod scope cannot use a wildcard' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      "& `$chmodCommand.Source 'a+x' '--' @executablePaths",
      "& `$chmodCommand.Source 'a+x' '--' " +
        "(Join-Path `$stagingPath 'bin/*')"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'chmod exactly the executable manifest'

Invoke-WorkflowPolicyCase `
  -Name 'wasm data member cannot become executable' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      "  'bin/moonrun'`n)",
      "  'bin/moonrun',`n  'bin/moonlex.wasm'`n)"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'executable member manifest|must be disjoint'

Invoke-WorkflowPolicyCase `
  -Name 'chmod cannot precede binary digests' `
  -Arrange {
    param($state)
    $chmodLine = (
      "  & `$chmodCommand.Source 'a+x' '--' @executablePaths`n"
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
  -ExpectedFailurePattern 'verify executable and data mode bits'

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
      "  `$coreMarker = Join-Path `$coreStagingPath 'core/moon.mod'",
      "  `$coreMarker = Join-Path `$coreStagingPath 'core/moon.mod.json'"
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'isolated core staging'

Invoke-WorkflowPolicyCase `
  -Name 'core archive cannot extract directly into toolchain lib' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      '    -Destination $coreStagingPath `',
      '    -Destination $libraryPath `'
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'exact ./core/ layout'

Invoke-WorkflowPolicyCase `
  -Name 'core promotion cannot precede isolated validation' `
  -Arrange {
    param($state)
    $moveBlock = (
      "  Move-Item ```n" +
      "    -LiteralPath `$coreRoots[0].FullName ```n" +
      "    -Destination `$installedCorePath`n"
    )
    $state.Installer = $state.Installer.Replace($moveBlock, '')
    $state.Installer = $state.Installer.Replace(
      '  $coreRoots = @(Get-ChildItem -LiteralPath $coreStagingPath -Force)',
      (
        $moveBlock +
        '  $coreRoots = @(' +
        'Get-ChildItem -LiteralPath $coreStagingPath -Force)'
      )
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'validated before moving'

Invoke-WorkflowPolicyCase `
  -Name 'core bundle all-target command is required' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      '      --all',
      '      --target js'
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'pinned setup behavior'

Invoke-WorkflowPolicyCase `
  -Name 'core bundle commands cannot be reordered' `
  -Arrange {
    param($state)
    $allBlock = @(
      '    & $bundleMoonPath `',
      '      -C $finalCorePath `',
      '      bundle `',
      '      --warn-list `',
      '      -a `',
      '      --all',
      '    if ($LASTEXITCODE -ne 0) {',
      '      throw ''P08-TOOLCHAIN-CORE-BUNDLE: --all failed.''',
      '    }'
    ) -join "`n"
    $wasmGcBlock = @(
      '    & $bundleMoonPath `',
      '      -C $finalCorePath `',
      '      bundle `',
      '      --warn-list `',
      '      -a `',
      '      --target wasm-gc `',
      '      --quiet',
      '    if ($LASTEXITCODE -ne 0) {',
      '      throw ''P08-TOOLCHAIN-CORE-BUNDLE: wasm-gc failed.''',
      '    }'
    ) -join "`n"
    $state.Installer = $state.Installer.Replace(
      $allBlock,
      '__MNF_BUNDLE_ALL__'
    ).Replace(
      $wasmGcBlock,
      '__MNF_BUNDLE_WASM_GC__'
    ).Replace(
      '__MNF_BUNDLE_ALL__',
      $wasmGcBlock
    ).Replace(
      '__MNF_BUNDLE_WASM_GC__',
      $allBlock
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'pinned bundle commands'

Invoke-WorkflowPolicyCase `
  -Name 'core bundle PATH cannot expose the install root' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      (
        '      $binPath + [IO.Path]::PathSeparator + ' +
        '$bundlePreviousPath'
      ),
      (
        '      $destination + [IO.Path]::PathSeparator + ' +
        '$bundlePreviousPath'
      )
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'scoped process PATH'

Invoke-WorkflowPolicyCase `
  -Name 'core bundle PATH is restored in finally' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      '    $env:PATH = $bundlePreviousPath',
      '    $env:PATH = $binPath'
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'restored in finally'

Invoke-WorkflowPolicyCase `
  -Name 'core bundle verification requires all four targets' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      '$bundleTargets = @(''js'', ''wasm'', ''wasm-gc'', ''native'')',
      '$bundleTargets = @(''js'', ''wasm'', ''wasm-gc'')'
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'bundle targets'

Invoke-WorkflowPolicyCase `
  -Name 'core bundle verification requires both interface leaves' `
  -Arrange {
    param($state)
    $state.Installer = $state.Installer.Replace(
      '$bundleLeaves = @(''prelude/prelude.mi'', ''math/math.mi'')',
      '$bundleLeaves = @(''prelude/prelude.mi'')'
    )
  } `
  -ShouldPass $false `
  -ExpectedFailurePattern 'bundle leaves'

Write-Host 'Quality workflow content-addressed toolchain policy matrix passed.'
