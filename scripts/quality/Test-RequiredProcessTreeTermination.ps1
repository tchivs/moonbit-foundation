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
$startedProcesses = [Collections.Generic.List[Diagnostics.Process]]::new()
$publishedProcessIds = [Collections.Generic.HashSet[int]]::new()
$containedProcesses = [Collections.Generic.List[object]]::new()

function Start-RequiredProbe {
  param([Parameter(Mandatory)][string]$Script)

  $encoded = [Convert]::ToBase64String(
    [Text.Encoding]::Unicode.GetBytes($Script)
  )
  $startInfo = [Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $pwshPath
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $true
  [void]$startInfo.ArgumentList.Add('-NoProfile')
  [void]$startInfo.ArgumentList.Add('-EncodedCommand')
  [void]$startInfo.ArgumentList.Add($encoded)
  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $startInfo
  if (-not $process.Start()) {
    throw 'Process-tree probe root failed to start.'
  }
  $startedProcesses.Add($process)
  return $process
}

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
  $normalPidFile = (Join-Path $testRoot 'normal-child.pid').Replace("'", "''")
  $normalProbe = @"
`$child = Start-Process -FilePath '$quotedPwsh' -ArgumentList @(
  '-NoProfile', '-Command', 'Start-Sleep -Seconds 60'
) -PassThru
[IO.File]::WriteAllText('$normalPidFile', [string]`$child.Id)
Start-Sleep -Milliseconds 1500
exit 0
"@
  $normalRoot = Start-RequiredProbe $normalProbe
  $normalTracker = New-RequiredProcessTracker -RootProcessId $normalRoot.Id
  $normalChildId = Wait-RequiredProbePid $normalPidFile
  $normalExited = Wait-RequiredRootExitTracked `
    -Process $normalRoot `
    -Tracker $normalTracker `
    -TimeoutMilliseconds 10000
  if (-not $normalExited -or
      -not (Test-RequiredProcessAlive -ProcessId $normalChildId)) {
    throw 'Normal-exit probe did not retain a live descendant after root exit.'
  }
  $result = Stop-RequiredProcessTreeVerified `
    -Process $normalRoot `
    -Tracker $normalTracker `
    -RootExited `
    -CleanupTimeoutMilliseconds 10000
  if (-not $result.ProcessTreeTerminated -or
      $result.TerminationStatus -cne 'exited-descendants-drained-verified' -or
      (Test-RequiredProcessAlive -ProcessId $normalChildId)) {
    throw 'Normal root exit was accepted before its descendant was drained.'
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
  $lateRoot = Start-RequiredProbe $lateProbe
  $lateTracker = New-RequiredProcessTracker -RootProcessId $lateRoot.Id
  $firstChildId = Wait-RequiredProbePid $firstPidFile
  Update-RequiredProcessTracker $lateTracker
  if (Test-Path -LiteralPath $latePidFile) {
    throw 'Late descendant existed before the earlier tracker snapshot.'
  }
  $lateResult = Stop-RequiredProcessTreeVerified `
    -Process $lateRoot `
    -Tracker $lateTracker `
    -CleanupTimeoutMilliseconds 10000
  $lateChildId = Wait-RequiredProbePid $latePidFile
  if (-not $lateResult.ProcessTreeTerminated -or
      $lateResult.TerminationStatus -cne 'killed-verified' -or
      $lateResult.TrackedProcessIds -notcontains $lateChildId -or
      (Test-RequiredProcessAlive -ProcessId $firstChildId) -or
      (Test-RequiredProcessAlive -ProcessId $lateChildId)) {
    throw 'Late descendant escaped fixed-point timeout cleanup.'
  }

  Write-Host 'PASS: Required normal-exit and late-descendant termination'
} finally {
  foreach ($processId in $publishedProcessIds) {
    if (Test-RequiredProcessAlive -ProcessId $processId) {
      [Diagnostics.Process]::GetProcessById($processId).Kill($true)
    }
  }
  foreach ($process in $startedProcesses) {
    if (Test-RequiredProcessAlive -ProcessId $process.Id) {
      [Diagnostics.Process]::GetProcessById($process.Id).Kill($true)
    }
    $process.Dispose()
  }
  $resolvedTestRoot = [IO.Path]::GetFullPath($testRoot)
  $requiredPrefix = $temporaryBase + [IO.Path]::DirectorySeparatorChar
  if ($resolvedTestRoot.StartsWith($requiredPrefix, [StringComparison]::OrdinalIgnoreCase) -and
      (Split-Path -Leaf $resolvedTestRoot) -like 'mnf-required-process-tree-*' -and
      (Test-Path -LiteralPath $resolvedTestRoot)) {
    Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
  }
}
