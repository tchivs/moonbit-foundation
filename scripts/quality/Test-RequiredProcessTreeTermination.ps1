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
