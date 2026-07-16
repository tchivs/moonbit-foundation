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
    [Parameter(Mandatory)][object]$ModulePolicy
  )

  foreach ($package in @($ModulePolicy.public_packages)) {
    $interfacePath = if ([string]$package.path -ceq '.') {
      Join-Path ([string]$ModulePolicy.path) 'pkg.generated.mbti'
    } else {
      Join-Path (Join-Path ([string]$ModulePolicy.path) ([string]$package.path)) 'pkg.generated.mbti'
    }
    if (-not (Test-Path -LiteralPath $interfacePath -PathType Leaf)) {
      throw "Interface classifier for $($package.name) cannot find '$interfacePath'."
    }
    $semanticLines = @(Get-Content -LiteralPath $interfacePath | ForEach-Object { $_.TrimEnd() } | Where-Object { $_ -ne '' -and -not $_.TrimStart().StartsWith('//') })
    $expectedLines = @($package.semantic_interface | ForEach-Object { [string]$_ })
    if ($semanticLines.Count -ne $expectedLines.Count) {
      throw "Interface classifier for $($package.name) line count mismatch: expected $($expectedLines.Count), got $($semanticLines.Count)."
    }
    for ($index = 0; $index -lt $expectedLines.Count; $index++) {
      if ($semanticLines[$index] -cne $expectedLines[$index]) {
        throw "Interface classifier for $($package.name) mismatch at semantic line $($index + 1): expected '$($expectedLines[$index])', got '$($semanticLines[$index])'."
      }
    }
    Write-Host "Interface verified for $($package.name): $($expectedLines.Count) semantic line(s)"
  }
}

function Assert-PackageList {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][object]$ModulePolicy,
    [Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]]$Output
  )

  $expectedFiles = @($ModulePolicy.publication_files | ForEach-Object { [string]$_ })
  $listedFiles = [System.Collections.Generic.List[string]]::new()
  foreach ($line in @($Output | Where-Object { $_ -ne '' })) {
    $normalizedLine = $line.Replace('\', '/')
    if ($expectedFiles -ccontains $normalizedLine) {
      $listedFiles.Add($normalizedLine)
      continue
    }
    if ($line -cmatch "^Warning: 'repository' field is not set or empty in module manifest$" -or
        $line -ceq 'Running moon check ...' -or
        $line -cmatch '^Finished[.] moon: .+$' -or
        $line -ceq 'Check passed' -or
        $line -cmatch '^Package to .+[.]zip$') {
      continue
    }
    throw "Package list for $($ModulePolicy.name) contained an unrecognized or forbidden line: '$line'."
  }
  Assert-ExactSet "Package contents for $($ModulePolicy.name)" @($listedFiles) $expectedFiles
  Write-Host "Package contents verified for $($ModulePolicy.name): $($expectedFiles -join ', ')"
}

function Assert-CoreSourceTextProhibitions {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$RelativePath,
    [Parameter(Mandatory)][string]$Text
  )

  $publicLines = @($Text -split '\r?\n' | Where-Object { $_ -cmatch '^\s*pub(?:\([^)]*\))?\s' })
  foreach ($line in $publicLines) {
    if ($line -cmatch '\b(?:FixedArray|MutArrayView)\b') {
      throw "Raw mutable backing escaped through a public declaration in $RelativePath`: $line"
    }
    if ($RelativePath -like 'modules/mb-core/host/*' -and $line -cmatch '\b(?:Host|Environment|NativeAdapter)\b') {
      throw "Ambient, aggregate, or native host surface escaped in $RelativePath`: $line"
    }
  }

  if ($RelativePath -cne 'modules/mb-core/checked/checked.mbt' -and $Text -cmatch '[.]to_int\s*\(') {
    throw "Unchecked UInt64-to-Int narrowing exists outside checked_narrow_int in '$RelativePath'."
  }
  if ($RelativePath -like 'modules/mb-core/host/*' -and $Text -cmatch '(?i)@(?:env|fs|process)\b|\bgetenv\s*\(|\bglobal_(?:host|clock|files?)\b') {
    throw "Ambient process or host access token found in '$RelativePath'."
  }
}

function Assert-CoreReadmeProhibitions {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Readme)

  $normalizedReadme = [regex]::Replace($Readme, '\s+', ' ')
  foreach ($requiredPhrase in @(
    'Budget rejection and injected allocator rejection are portable structured results.',
    'Built-in physical runtime OOM is unrecoverable',
    'is not claimed as a catchable `CoreError`',
    'There is no ambient fallback'
  )) {
    if (-not $normalizedReadme.Contains($requiredPhrase)) {
      throw "mb-core README lacks required portable-safety statement: $requiredPhrase"
    }
  }
  if ($Readme -cmatch '(?i)physical(?: runtime)? OOM\s+(?:is|remains)\s+(?:recoverable|catchable)|catch(?:es|ing)?\s+(?:built-in\s+)?physical(?: runtime)? OOM') {
    throw 'mb-core README falsely claims built-in physical OOM is recoverable.'
  }
}

function Assert-CorePortableProhibitions {
  [CmdletBinding()]
  param()

  $coreRoot = 'modules/mb-core'
  $sourceFiles = @(Get-ChildItem -LiteralPath $coreRoot -Recurse -File -Filter '*.mbt')
  if ($sourceFiles.Count -eq 0) { throw 'No mb-core MoonBit sources were found for prohibition scanning.' }

  foreach ($sourceFile in $sourceFiles) {
    $text = Get-Content -LiteralPath $sourceFile.FullName -Raw
    $relative = [System.IO.Path]::GetRelativePath((Resolve-Path '.').Path, $sourceFile.FullName).Replace('\', '/')
    Assert-CoreSourceTextProhibitions -RelativePath $relative -Text $text
  }

  $readme = Get-Content -LiteralPath (Join-Path $coreRoot 'README.mbt.md') -Raw
  Assert-CoreReadmeProhibitions -Readme $readme

  Write-Host 'mb-core portable prohibitions verified: no raw mutable public backing, unchecked narrowing, ambient host/native aggregate, or false catchable-OOM prose.'
}

function Assert-CoreQualificationNegativeFixtures {
  [CmdletBinding()]
  param()

  function Confirm-Rejected([string]$Name, [scriptblock]$Action) {
    $rejected = $false
    try { & $Action } catch { $rejected = $true }
    if (-not $rejected) { throw "Required quality accepted negative fixture '$Name'." }
    Write-Host "Negative fixture rejected: $Name"
  }

  $packageSpine = @('error', 'checked', 'budget', 'bytes', 'io', 'host')
  Confirm-Rejected 'root package topology' {
    Assert-ExactSequence 'negative package spine' @('.', 'error', 'checked', 'budget', 'bytes', 'io', 'host') $packageSpine
  }
  Confirm-Rejected 'extra public package' {
    Assert-ExactSequence 'negative package spine' @('error', 'checked', 'budget', 'bytes', 'io', 'host', 'extra') $packageSpine
  }
  Confirm-Rejected 'missing public package' {
    Assert-ExactSequence 'negative package spine' @('error', 'checked', 'budget', 'bytes', 'io') $packageSpine
  }
  Confirm-Rejected 'reverse dependency' {
    Assert-ExactSet 'negative imports' @('moonbit-foundation/mb-core/host') @('moonbit-foundation/mb-core/error')
  }
  Confirm-Rejected 'undeclared public surface' {
    Assert-ExactSequence 'negative semantic interface' @('package "fixture"', 'pub fn unexpected() -> Unit') @('package "fixture"')
  }
  Confirm-Rejected 'raw mutable backing' {
    Assert-CoreSourceTextProhibitions -RelativePath 'modules/mb-core/bytes/fixture.mbt' -Text 'pub fn backing() -> FixedArray[Byte] { abort("fixture") }'
  }
  Confirm-Rejected 'unchecked narrowing' {
    Assert-CoreSourceTextProhibitions -RelativePath 'modules/mb-core/io/fixture.mbt' -Text 'fn narrow(value : UInt64) -> Int { value.to_int() }'
  }
  Confirm-Rejected 'ambient host access' {
    Assert-CoreSourceTextProhibitions -RelativePath 'modules/mb-core/host/fixture.mbt' -Text 'fn ambient() -> Unit { ignore(@fs.open("fixture")) }'
  }
  Confirm-Rejected 'false recoverable physical OOM prose' {
    Assert-CoreReadmeProhibitions -Readme 'Budget rejection and injected allocator rejection are portable structured results. Built-in physical runtime OOM is unrecoverable and is not claimed as a catchable `CoreError`. There is no ambient fallback. Physical runtime OOM is recoverable.'
  }
  Confirm-Rejected 'broken literate documentation input' {
    Invoke-MoonCommand -Context 'negative missing README fixture' -Arguments @('-C', 'modules/mb-core', 'check', 'README.missing.mbt.md', '--target', 'native', '--frozen')
  }

  Write-Host 'Core topology, public surface, docs, capability, backing, narrowing, and OOM negative fixtures all fail closed.'
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
  $policy = Read-QualityJson -Path $policyPath
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
  Invoke-QualityStage 'CORE portable source and documentation prohibitions' {
    Assert-CorePortableProhibitions
  }
  Invoke-QualityStage 'CORE fail-closed negative fixtures' {
    Assert-CoreQualificationNegativeFixtures
  }
  foreach ($target in $requiredTargets) {
    Invoke-QualityStage "CORE literate README check target $target" {
      Invoke-MoonCommand -Context "mb-core README check target $target" -Arguments @('-C', 'modules/mb-core', 'check', 'README.mbt.md', '--target', $target, '--frozen')
    }
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
      $modulePolicy = @($policy.modules | Where-Object { [string]$_.path -ceq "modules/$module" })[0]
      Assert-GeneratedInterface -ModulePolicy $modulePolicy
    }
  }
  foreach ($module in $modules) {
    Invoke-QualityStage "WORK-04 package allowlist for $module" {
      $packageOutput = Invoke-MoonCommand -Context "package list for $module" -Arguments @('-C', "modules/$module", 'package', '--frozen', '--list') -CaptureCombined
      $modulePolicy = @($policy.modules | Where-Object { [string]$_.path -ceq "modules/$module" })[0]
      Assert-PackageList -ModulePolicy $modulePolicy -Output $packageOutput
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
