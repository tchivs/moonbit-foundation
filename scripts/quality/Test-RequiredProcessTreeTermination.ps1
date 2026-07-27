$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'Invoke-RequiredBounded.ps1') -ImportOnly

$pwshPath = @(
  Get-Command pwsh -CommandType Application -ErrorAction Stop
)[0].Source
$temporaryBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd(
  [IO.Path]::DirectorySeparatorChar,
  [IO.Path]::AltDirectorySeparatorChar
)
$testRoot = Join-Path $temporaryBase (
  'mnf-required-process-tree-' + [Guid]::NewGuid().ToString('N')
)
[void](New-Item -ItemType Directory -Path $testRoot)
$publishedProcessIds = [Collections.Generic.HashSet[int]]::new()
$containedProcesses = [Collections.Generic.List[object]]::new()
$posixContainments = [Collections.Generic.List[object]]::new()

function Wait-RequiredProbePid {
  param([Parameter(Mandatory)][string]$Path)

  $deadline = [DateTime]::UtcNow.AddSeconds(10)
  while ([DateTime]::UtcNow -lt $deadline) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
      try {
        $processId = 0
        if ([int]::TryParse([IO.File]::ReadAllText($Path), [ref]$processId) -and
            $processId -gt 0) {
          [void]$publishedProcessIds.Add($processId)
          return $processId
        }
      } catch [IO.IOException] {
        # The publishing process has created but not yet closed the PID file.
      }
    }
    Start-Sleep -Milliseconds 100
  }
  throw "Process-tree probe did not publish '$Path'."
}

function Start-RequiredContainedProbe {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Script
  )

  $encoded = [Convert]::ToBase64String(
    [Text.Encoding]::Unicode.GetBytes($Script)
  )
  $containment = Start-RequiredWindowsJobProcess `
    -FileName $pwshPath `
    -Arguments @('-NoProfile', '-EncodedCommand', $encoded) `
    -WorkingDirectory $testRoot `
    -StdoutPath (Join-Path $testRoot "$Name.stdout.log") `
    -StderrPath (Join-Path $testRoot "$Name.stderr.log")
  $containedProcesses.Add($containment)
  return $containment
}

function Start-RequiredPosixProbe {
  param([Parameter(Mandatory)][string]$Script)

  $encoded = [Convert]::ToBase64String(
    [Text.Encoding]::Unicode.GetBytes($Script)
  )
  $containment = Start-RequiredPosixSessionProcess `
    -FileName $pwshPath `
    -Arguments @('-NoProfile', '-EncodedCommand', $encoded) `
    -WorkingDirectory $testRoot
  $posixContainments.Add($containment)
  return $containment
}

if ([OperatingSystem]::IsWindows()) {
  try {
    $quotedPwsh = $pwshPath.Replace("'", "''")

    $normalPidFile = (Join-Path $testRoot 'normal-child.pid').Replace("'", "''")
    $normalProbe = @"
`$child = Start-Process -FilePath '$quotedPwsh' -ArgumentList @(
  '-NoProfile', '-Command', 'Start-Sleep -Seconds 60'
) -PassThru
[IO.File]::WriteAllText('$normalPidFile', [string]`$child.Id)
Start-Sleep -Milliseconds 500
exit 0
"@
    $normalJob = Start-RequiredContainedProbe -Name normal -Script $normalProbe
    $normalChildId = Wait-RequiredProbePid $normalPidFile
    if (-not $normalJob.WaitForRootExit(10000) -or
        -not (Test-RequiredProcessAlive -ProcessId $normalChildId)) {
      throw 'Normal-exit job probe did not retain a live descendant.'
    }
    $normalResult = Stop-RequiredWindowsJobVerified `
      -Containment $normalJob `
      -RootExited `
      -CleanupTimeoutMilliseconds 10000
    if (-not $normalResult.ProcessTreeTerminated -or
        $normalResult.TerminationStatus -cne 'exited-job-terminated-verified' -or
        $normalResult.ActiveBeforeTermination -eq 0 -or
        $normalResult.ActiveAfterTermination -ne 0 -or
        (Test-RequiredProcessAlive -ProcessId $normalChildId)) {
      throw 'Normal root exit was accepted before its Job Object became empty.'
    }

    $firstPidFile = (Join-Path $testRoot 'first-child.pid').Replace("'", "''")
    $latePidFile = (Join-Path $testRoot 'late-child.pid').Replace("'", "''")
    $lateProbe = @"
`$first = Start-Process -FilePath '$quotedPwsh' -ArgumentList @(
  '-NoProfile', '-Command', 'Start-Sleep -Seconds 60'
) -PassThru
[IO.File]::WriteAllText('$firstPidFile', [string]`$first.Id)
Start-Sleep -Milliseconds 250
`$late = Start-Process -FilePath '$quotedPwsh' -ArgumentList @(
  '-NoProfile', '-Command', 'Start-Sleep -Seconds 60'
) -PassThru
[IO.File]::WriteAllText('$latePidFile', [string]`$late.Id)
Start-Sleep -Seconds 60
"@
    $lateJob = Start-RequiredContainedProbe -Name late -Script $lateProbe
    $firstChildId = Wait-RequiredProbePid $firstPidFile
    $lateChildId = Wait-RequiredProbePid $latePidFile
    $lateResult = Stop-RequiredWindowsJobVerified `
      -Containment $lateJob `
      -CleanupTimeoutMilliseconds 10000
    if (-not $lateResult.ProcessTreeTerminated -or
        $lateResult.ActiveAfterTermination -ne 0 -or
        (Test-RequiredProcessAlive -ProcessId $firstChildId) -or
        (Test-RequiredProcessAlive -ProcessId $lateChildId)) {
      throw 'Late descendant escaped Job Object timeout cleanup.'
    }

    $intermediaryPidFile = (
      Join-Path $testRoot 'ephemeral-intermediary.pid'
    ).Replace("'", "''")
    $leafPidFile = (
      Join-Path $testRoot 'ephemeral-leaf.pid'
    ).Replace("'", "''")
    $intermediaryProbe = @"
`$leaf = Start-Process -FilePath '$quotedPwsh' -ArgumentList @(
  '-NoProfile', '-Command', 'Start-Sleep -Seconds 60'
) -PassThru
[IO.File]::WriteAllText('$leafPidFile', [string]`$leaf.Id)
exit 0
"@
    $encodedIntermediary = [Convert]::ToBase64String(
      [Text.Encoding]::Unicode.GetBytes($intermediaryProbe)
    )
    $ephemeralProbe = @"
`$intermediary = Start-Process -FilePath '$quotedPwsh' -ArgumentList @(
  '-NoProfile', '-EncodedCommand', '$encodedIntermediary'
) -PassThru
[IO.File]::WriteAllText('$intermediaryPidFile', [string]`$intermediary.Id)
exit 0
"@
    $ephemeralJob = Start-RequiredContainedProbe `
      -Name ephemeral `
      -Script $ephemeralProbe
    $intermediaryId = Wait-RequiredProbePid $intermediaryPidFile
    $leafId = Wait-RequiredProbePid $leafPidFile
    if (-not $ephemeralJob.WaitForRootExit(10000)) {
      throw 'Ephemeral probe root did not exit.'
    }
    $ancestorDeadline = [DateTime]::UtcNow.AddSeconds(10)
    while ((Test-RequiredProcessAlive -ProcessId $intermediaryId) -and
           [DateTime]::UtcNow -lt $ancestorDeadline) {
      Start-Sleep -Milliseconds 50
    }
    if ((Test-RequiredProcessAlive -ProcessId $ephemeralJob.ProcessId) -or
        (Test-RequiredProcessAlive -ProcessId $intermediaryId) -or
        -not (Test-RequiredProcessAlive -ProcessId $leafId)) {
      throw 'Ephemeral probe did not reach vanished ancestors with a live leaf.'
    }
    $ephemeralResult = Stop-RequiredWindowsJobVerified `
      -Containment $ephemeralJob `
      -RootExited `
      -CleanupTimeoutMilliseconds 10000
    if (-not $ephemeralResult.ProcessTreeTerminated -or
        $ephemeralResult.ActiveBeforeTermination -eq 0 -or
        $ephemeralResult.ActiveAfterTermination -ne 0 -or
        (Test-RequiredProcessAlive -ProcessId $leafId)) {
      throw 'Ephemeral intermediary leaf escaped Job Object containment.'
    }

    Write-Host (
      'PASS: Required Job Object contains normal, late, and ephemeral descendants'
    )
  } finally {
    foreach ($containment in $containedProcesses) {
      try {
        if ($containment.ActiveProcessCount -gt 0) {
          $containment.Terminate(1)
          [void]$containment.WaitForEmpty(10000)
        }
      } catch {
        # Dispose below still enforces kill-on-close.
      } finally {
        $containment.Dispose()
      }
    }
    foreach ($processId in $publishedProcessIds) {
      if (Test-RequiredProcessAlive -ProcessId $processId) {
        [Diagnostics.Process]::GetProcessById($processId).Kill($true)
      }
    }
    $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
    $requiredPrefix = $temporaryBase + [IO.Path]::DirectorySeparatorChar
    if ($resolvedTestRoot.StartsWith(
        $requiredPrefix,
        [StringComparison]::OrdinalIgnoreCase
      ) -and
        (Split-Path -Leaf $resolvedTestRoot) -like 'mnf-required-process-tree-*' -and
        (Test-Path -LiteralPath $resolvedTestRoot)) {
      Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
  }
  return
}

try {
  $quotedPwsh = $pwshPath.Replace("'", "''")
  $directProbe = @"
Write-Output 'required-posix-stdout'
[Console]::Error.WriteLine('required-posix-stderr')
exit 7
"@
  $directContainment = Start-RequiredPosixProbe $directProbe
  if (-not $directContainment.Process.WaitForExit(10000)) {
    throw 'Direct POSIX session probe did not exit.'
  }
  $directContainment.Process.WaitForExit()
  $directExitCode = [int]$directContainment.Process.ExitCode
  $directResult = Stop-RequiredPosixSessionVerified `
    -Containment $directContainment `
    -RootExited `
    -CleanupTimeoutMilliseconds 10000
  $directStdout = $directContainment.StdoutTask.GetAwaiter().GetResult().Trim()
  $directStderr = $directContainment.StderrTask.GetAwaiter().GetResult().Trim()
  if ($directExitCode -ne 7 -or
      $directStdout -cne 'required-posix-stdout' -or
      $directStderr -cne 'required-posix-stderr' -or
      -not $directResult.ProcessTreeTerminated -or
      $directResult.TerminationStatus -cne
        'exited-session-terminated-verified' -or
      $directResult.ActiveAfterTermination -ne 0) {
    throw 'Direct POSIX session exit/output semantics were not preserved.'
  }

  $timeoutContainment = Start-RequiredPosixProbe 'Start-Sleep -Seconds 60'
  if ($timeoutContainment.Process.WaitForExit(250)) {
    throw 'POSIX timeout probe exited before its timeout.'
  }
  $timeoutResult = Stop-RequiredPosixSessionVerified `
    -Containment $timeoutContainment `
    -CleanupTimeoutMilliseconds 10000
  if (-not $timeoutResult.ProcessTreeTerminated -or
      $timeoutResult.TerminationStatus -cne 'session-terminated-verified' -or
      $timeoutResult.ActiveBeforeTermination -eq 0 -or
      $timeoutResult.ActiveAfterTermination -ne 0) {
    throw 'Timed-out POSIX session was not terminated and verified empty.'
  }

  $intermediaryPidFile = (
    Join-Path $testRoot 'ephemeral-intermediary.pid'
  ).Replace("'", "''")
  $leafPidFile = (
    Join-Path $testRoot 'ephemeral-leaf.pid'
  ).Replace("'", "''")
  $intermediaryProbe = @"
`$leaf = Start-Process -FilePath '$quotedPwsh' -ArgumentList @(
  '-NoProfile', '-Command', 'Start-Sleep -Seconds 60'
) -PassThru
[IO.File]::WriteAllText('$leafPidFile', [string]`$leaf.Id)
exit 0
"@
  $encodedIntermediary = [Convert]::ToBase64String(
    [Text.Encoding]::Unicode.GetBytes($intermediaryProbe)
  )
  $ephemeralProbe = @"
`$intermediary = Start-Process -FilePath '$quotedPwsh' -ArgumentList @(
  '-NoProfile', '-EncodedCommand', '$encodedIntermediary'
) -PassThru
[IO.File]::WriteAllText('$intermediaryPidFile', [string]`$intermediary.Id)
exit 0
"@
  $ephemeralContainment = Start-RequiredPosixProbe $ephemeralProbe
  $intermediaryId = Wait-RequiredProbePid $intermediaryPidFile
  $leafId = Wait-RequiredProbePid $leafPidFile
  if (-not $ephemeralContainment.Process.WaitForExit(10000)) {
    throw 'Ephemeral POSIX probe root did not exit.'
  }
  $ancestorDeadline = [DateTime]::UtcNow.AddSeconds(10)
  while ((Test-RequiredProcessAlive -ProcessId $intermediaryId) -and
         [DateTime]::UtcNow -lt $ancestorDeadline) {
    Start-Sleep -Milliseconds 50
  }
  $liveMembers = @(
    Get-RequiredPosixSessionMembers $ephemeralContainment
  )
  if ((Test-RequiredProcessAlive -ProcessId $ephemeralContainment.ProcessId) -or
      (Test-RequiredProcessAlive -ProcessId $intermediaryId) -or
      -not (Test-RequiredProcessAlive -ProcessId $leafId) -or
      $liveMembers.ProcessId -notcontains $leafId) {
    throw (
      'Ephemeral POSIX probe did not reach vanished ancestors with a ' +
      'session-contained live leaf.'
    )
  }
  $ephemeralResult = Stop-RequiredPosixSessionVerified `
    -Containment $ephemeralContainment `
    -RootExited `
    -CleanupTimeoutMilliseconds 10000
  if (-not $ephemeralResult.ProcessTreeTerminated -or
      $ephemeralResult.ActiveBeforeTermination -eq 0 -or
      $ephemeralResult.ActiveAfterTermination -ne 0 -or
      (Test-RequiredProcessAlive -ProcessId $leafId)) {
    throw 'Ephemeral intermediary leaf escaped POSIX session containment.'
  }

  Write-Host (
    'PASS: Required POSIX session preserves output and contains timed-out ' +
    'and ephemeral descendants'
  )
} finally {
  foreach ($containment in $posixContainments) {
    try {
      if ((Get-RequiredPosixSessionMembers $containment).Count -gt 0) {
        [void](Stop-RequiredPosixSessionVerified `
          -Containment $containment `
          -CleanupTimeoutMilliseconds 10000)
      }
    } catch {
      # PID cleanup below is a final test-only fallback.
    } finally {
      if (Test-RequiredProcessAlive -ProcessId $containment.ProcessId) {
        $containment.Process.Kill($true)
        [void]$containment.Process.WaitForExit(5000)
      }
      $containment.Process.Dispose()
    }
  }
  foreach ($processId in $publishedProcessIds) {
    if (Test-RequiredProcessAlive -ProcessId $processId) {
      [Diagnostics.Process]::GetProcessById($processId).Kill($true)
    }
  }
  $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
  $requiredPrefix = $temporaryBase + [IO.Path]::DirectorySeparatorChar
  if ($resolvedTestRoot.StartsWith($requiredPrefix, [StringComparison]::OrdinalIgnoreCase) -and
      (Split-Path -Leaf $resolvedTestRoot) -like 'mnf-required-process-tree-*' -and
      (Test-Path -LiteralPath $resolvedTestRoot)) {
    Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
  }
}
