Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'Assert-Toolchain.ps1')
. (Join-Path $PSScriptRoot 'Assert-Policy.ps1')

function Invoke-QualityStage {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][scriptblock]$Action
  )

  Write-Host "==> $Name"
  try {
    & $Action
  } catch {
    throw "Quality stage '$Name' failed: $($_.Exception.Message)"
  }
}

function Invoke-MoonCommand {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Context,
    [Parameter(Mandatory)][string[]]$Arguments,
    [switch]$CaptureCombined
  )

  if ($CaptureCombined) {
    $output = @(& moon @Arguments 2>&1 | ForEach-Object { $_.ToString().TrimEnd() })
  } else {
    & moon @Arguments
    $output = @()
  }
  if ($LASTEXITCODE -ne 0) {
    throw "$Context failed (exit $LASTEXITCODE): moon $($Arguments -join ' ')"
  }
  return ,$output
}

function Assert-GeneratedInterface {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateSet('mb-core', 'mb-color', 'mb-image')][string]$Module
  )

  $interfacePath = Join-Path "modules/$Module" 'pkg.generated.mbti'
  if (-not (Test-Path -LiteralPath $interfacePath -PathType Leaf)) {
    throw "Interface classifier for $Module cannot find '$interfacePath'."
  }
  $semanticLines = @(Get-Content -LiteralPath $interfacePath | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' -and -not $_.StartsWith('//') })
  $expectedLine = "package `"moonbit-foundation/$Module`""
  if ($semanticLines.Count -ne 1 -or $semanticLines[0] -cne $expectedLine) {
    throw "Interface classifier for $Module expected exactly '$expectedLine'; got [$($semanticLines -join ' | ')]."
  }
  Write-Host "Interface verified for ${Module}: $expectedLine"
}

function Assert-PackageList {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateSet('mb-core', 'mb-color', 'mb-image')][string]$Module,
    [Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]]$Output
  )

  $expectedFiles = @('CHANGELOG.md', 'README.mbt.md', 'moon.mod.json', 'moon.pkg', 'scaffold.mbt', 'scaffold_wbtest.mbt')
  $listedFiles = [System.Collections.Generic.List[string]]::new()
  foreach ($line in @($Output | Where-Object { $_ -ne '' })) {
    if ($expectedFiles -ccontains $line) {
      $listedFiles.Add($line)
      continue
    }
    if ($line -cmatch "^Warning: 'repository' field is not set or empty in module manifest$" -or
        $line -ceq 'Running moon check ...' -or
        $line -cmatch '^Finished[.] moon: .+$' -or
        $line -ceq 'Check passed' -or
        $line -cmatch '^Package to .+[.]zip$') {
      continue
    }
    throw "Package list for $Module contained an unrecognized or forbidden line: '$line'."
  }
  Assert-ExactSet "Package contents for $Module" @($listedFiles) $expectedFiles
  Write-Host "Package contents verified for ${Module}: $($expectedFiles -join ', ')"
}

function Get-TrackedDiffSnapshot {
  $output = @(& git diff --binary --no-ext-diff HEAD -- 2>&1 | ForEach-Object { $_.ToString() })
  if ($LASTEXITCODE -ne 0) { throw "Unable to capture tracked diff (exit $LASTEXITCODE)." }
  return ($output -join "`n")
}

function Invoke-RequiredQuality {
  $policyPath = 'policy/foundation.json'
  $auditPath = 'policy/phase-01-source-audit.json'
  $requiredTargets = @('js', 'wasm', 'wasm-gc', 'native')
  $modules = @('mb-core', 'mb-color', 'mb-image')
  $initialTrackedDiff = Get-TrackedDiffSnapshot

  Invoke-QualityStage 'D-14 exact toolchain identity' {
    Assert-Toolchain -PolicyPath $policyPath
  }
  Invoke-QualityStage 'Foundation policy, RFC, fixtures, inventory, target metadata, and DAG' {
    Assert-FoundationPolicy -PolicyPath $policyPath
  }
  Invoke-QualityStage 'Exact Phase 1 source inventory (1/9/16/29/17/5)' {
    Assert-PhaseSourceAudit -AuditPath $auditPath
  }
  Invoke-QualityStage 'WORK-04 format check' {
    # The pinned toolchain's unscoped formatter always proposes the explicitly
    # deferred moon.mod.json -> moon.mod migration. Enumerating every MoonBit
    # source preserves the locked compatibility floor while remaining fail-closed.
    $sourceFiles = @(Get-ChildItem -LiteralPath 'modules' -Recurse -File | Where-Object { $_.Name -match '[.]mbt(?:[.]md)?$' } | ForEach-Object { $_.FullName })
    if ($sourceFiles.Count -eq 0) { throw 'No MoonBit source files were found for formatting.' }
    Invoke-MoonCommand -Context 'workspace MoonBit source format check' -Arguments (@('fmt', '--check') + $sourceFiles)
  }
  foreach ($target in $requiredTargets) {
    Invoke-QualityStage "WORK-05 check target $target" {
      Invoke-MoonCommand -Context "workspace check target $target" -Arguments @('check', '--target', $target, '--deny-warn', '--frozen')
    }
    Invoke-QualityStage "WORK-05 test target $target" {
      Invoke-MoonCommand -Context "workspace test target $target" -Arguments @('test', '--target', $target, '--frozen')
    }
  }
  foreach ($module in $modules) {
    Invoke-QualityStage "WORK-04 documentation generation for $module" {
      Invoke-MoonCommand -Context "moon doc for $module" -Arguments @('-C', "modules/$module", 'doc', '--frozen')
    }
    Invoke-QualityStage "D-15 interface generation and classification for $module" {
      Invoke-MoonCommand -Context "moon info for $module" -Arguments @('-C', "modules/$module", 'info', '--target', 'all', '--frozen')
      Assert-GeneratedInterface -Module $module
    }
  }
  foreach ($module in $modules) {
    Invoke-QualityStage "WORK-04 package allowlist for $module" {
      $packageOutput = Invoke-MoonCommand -Context "package list for $module" -Arguments @('-C', "modules/$module", 'package', '--frozen', '--list') -CaptureCombined
      Assert-PackageList -Module $module -Output $packageOutput
    }
  }
  Invoke-QualityStage 'Read-only tracked checkout proof' {
    $finalTrackedDiff = Get-TrackedDiffSnapshot
    if ($finalTrackedDiff -cne $initialTrackedDiff) {
      throw 'Required quality commands changed tracked files.'
    }
  }
  Write-Host 'Required quality lane passed.'
}

function Invoke-LlvmExperimentalQuality {
  $policyPath = 'policy/foundation.json'
  Write-Host 'LLVM is experimental, unsupported by the required target contract, and non-blocking in CI.'
  Invoke-QualityStage 'D-14 exact toolchain identity before LLVM experiment' {
    Assert-Toolchain -PolicyPath $policyPath
  }
  Invoke-QualityStage 'Experimental LLVM check' {
    Invoke-MoonCommand -Context 'experimental LLVM workspace check' -Arguments @('check', '--target', 'llvm', '--deny-warn', '--frozen')
  }
  Invoke-QualityStage 'Experimental LLVM test' {
    Invoke-MoonCommand -Context 'experimental LLVM workspace test' -Arguments @('test', '--target', 'llvm', '--frozen')
  }
  Write-Host 'Experimental LLVM lane passed; this does not establish supported-target status.'
}

function Invoke-MoonQuality {
  [CmdletBinding()]
  param([Parameter(Mandatory)][ValidateSet('Required', 'LlvmExperimental')][string]$Lane)

  if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "PowerShell 7 or newer is required; found $($PSVersionTable.PSVersion)."
  }
  switch ($Lane) {
    'Required' { Invoke-RequiredQuality }
    'LlvmExperimental' { Invoke-LlvmExperimentalQuality }
    default { throw "Unsupported quality lane '$Lane'." }
  }
}
