[CmdletBinding(DefaultParameterSetName = 'Run')]
param(
  [Parameter(Mandatory, ParameterSetName = 'Run')]
  [string]$EvidenceDirectory,
  [Parameter(ParameterSetName = 'Run')]
  [ValidateRange(1, 86400)]
  [int]$TimeoutSeconds = 900,
  [Parameter(Mandatory, ParameterSetName = 'Import')]
  [switch]$ImportOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RequiredProcessSnapshot {
  if ([OperatingSystem]::IsWindows()) {
    return @(
      Get-CimInstance -ClassName Win32_Process -ErrorAction Stop |
        ForEach-Object {
          [pscustomobject]@{
            Id = [int]$_.ProcessId
            ParentId = [int]$_.ParentProcessId
          }
        }
    )
  }

  $output = @(& ps -e -o pid=,ppid= 2>&1)
  if ($LASTEXITCODE -ne 0) {
    throw "Unable to enumerate processes with ps: $($output -join ' ')"
  }
  return @(
    foreach ($line in $output) {
      if ([string]$line -match '^\s*(\d+)\s+(\d+)\s*$') {
        [pscustomobject]@{
          Id = [int]$Matches[1]
          ParentId = [int]$Matches[2]
        }
      }
    }
  )
}

function Get-RequiredDescendantProcessIds {
  param(
    [Parameter(Mandatory)][int]$RootProcessId,
    [Parameter(Mandatory)][object[]]$Snapshot
  )

  $descendants = [Collections.Generic.HashSet[int]]::new()
  $parents = [Collections.Generic.Queue[int]]::new()
  $parents.Enqueue($RootProcessId)
  while ($parents.Count -gt 0) {
    $parent = $parents.Dequeue()
    foreach ($candidate in $Snapshot) {
      if ($candidate.ParentId -eq $parent -and
          $descendants.Add([int]$candidate.Id)) {
        $parents.Enqueue([int]$candidate.Id)
      }
    }
  }
  return @($descendants | Sort-Object)
}

function Test-RequiredProcessAlive {
  param([Parameter(Mandatory)][int]$ProcessId)

  try {
    $candidate = [Diagnostics.Process]::GetProcessById($ProcessId)
    try {
      return -not $candidate.HasExited
    } finally {
      $candidate.Dispose()
    }
  } catch [ArgumentException] {
    return $false
  }
}

function New-RequiredProcessTracker {
  param([Parameter(Mandatory)][int]$RootProcessId)

  $processIds = [Collections.Generic.HashSet[int]]::new()
  [void]$processIds.Add($RootProcessId)
  return [pscustomobject]@{
    RootProcessId = $RootProcessId
    ProcessIds = $processIds
  }
}

function Update-RequiredProcessTracker {
  param([Parameter(Mandatory)]$Tracker)

  $snapshot = @(Get-RequiredProcessSnapshot)
  $added = $true
  while ($added) {
    $added = $false
    foreach ($candidate in $snapshot) {
      if ($Tracker.ProcessIds.Contains([int]$candidate.ParentId) -and
          $Tracker.ProcessIds.Add([int]$candidate.Id)) {
        $added = $true
      }
    }
  }
}

function Get-RequiredLiveTrackedProcessIds {
  param([Parameter(Mandatory)]$Tracker)

  return @($Tracker.ProcessIds | Where-Object {
    Test-RequiredProcessAlive -ProcessId $_
  })
}

function Wait-RequiredRootExitTracked {
  param(
    [Parameter(Mandatory)][Diagnostics.Process]$Process,
    [Parameter(Mandatory)]$Tracker,
    [Parameter(Mandatory)][ValidateRange(1, 86400000)]
    [int]$TimeoutMilliseconds
  )

  $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
  do {
    Update-RequiredProcessTracker $Tracker
    if ($Process.HasExited) {
      $Process.WaitForExit()
      Update-RequiredProcessTracker $Tracker
      return $true
    }
    $remaining = [int][Math]::Ceiling(
      ($deadline - [DateTime]::UtcNow).TotalMilliseconds
    )
    if ($remaining -le 0) {
      break
    }
    $wait = [Math]::Min(500, $remaining)
    if ($Process.WaitForExit($wait)) {
      $Process.WaitForExit()
      Update-RequiredProcessTracker $Tracker
      return $true
    }
  } while ([DateTime]::UtcNow -lt $deadline)
  Update-RequiredProcessTracker $Tracker
  return $false
}

function Stop-RequiredProcessTreeVerified {
  param(
    [Parameter(Mandatory)][Diagnostics.Process]$Process,
    [Parameter(Mandatory)]$Tracker,
    [switch]$RootExited,
    [ValidateRange(1, 120000)]
    [int]$CleanupTimeoutMilliseconds = 30000
  )

  $deadline = [DateTime]::UtcNow.AddMilliseconds($CleanupTimeoutMilliseconds)

  # Reach a fixed point over repeated snapshots before termination. This closes
  # the single-snapshot gap when a tracked process creates another descendant
  # while cleanup is beginning.
  $stableDiscoveryPasses = 0
  while ($stableDiscoveryPasses -lt 3 -and
         [DateTime]::UtcNow -lt $deadline) {
    $before = $Tracker.ProcessIds.Count
    Update-RequiredProcessTracker $Tracker
    if ($Tracker.ProcessIds.Count -eq $before) {
      $stableDiscoveryPasses = $stableDiscoveryPasses + 1
    } else {
      $stableDiscoveryPasses = 0
    }
    Start-Sleep -Milliseconds 100
  }

  $stableEmptyPasses = 0
  do {
    Update-RequiredProcessTracker $Tracker
    $ordered = @($Tracker.RootProcessId) + @(
      $Tracker.ProcessIds |
        Where-Object { $_ -ne $Tracker.RootProcessId } |
        Sort-Object -Descending
    )
    foreach ($processId in $ordered) {
      try {
        $trackedProcess = [Diagnostics.Process]::GetProcessById($processId)
        try {
          if (-not $trackedProcess.HasExited) {
            $trackedProcess.Kill($true)
          }
        } finally {
          $trackedProcess.Dispose()
        }
      } catch [ArgumentException] {
        # The tracked process has already exited.
      }
    }

    # Discover again after kill requests so descendants born after an earlier
    # snapshot are added before their parents disappear from the process table.
    Update-RequiredProcessTracker $Tracker
    $live = @(Get-RequiredLiveTrackedProcessIds $Tracker)
    if ($live.Count -eq 0) {
      $stableEmptyPasses = $stableEmptyPasses + 1
      if ($stableEmptyPasses -ge 2) {
        break
      }
    } else {
      $stableEmptyPasses = 0
    }
    Start-Sleep -Milliseconds 100
  } while ([DateTime]::UtcNow -lt $deadline)

  $terminated = $stableEmptyPasses -ge 2
  return [pscustomobject]@{
    ProcessTreeTerminated = $terminated
    TerminationStatus = if ($terminated) {
      if ($RootExited) {
        'exited-descendants-drained-verified'
      } else {
        'killed-verified'
      }
    } else {
      if ($RootExited) {
        'exit-drain-verification-timeout'
      } else {
        'kill-verification-timeout'
      }
    }
    TrackedProcessIds = @($Tracker.ProcessIds | Sort-Object)
  }
}

function Invoke-RequiredBounded {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$EvidenceDirectory,
    [Parameter(Mandatory)]
    [ValidateRange(1, 86400)]
    [int]$TimeoutSeconds
  )

  $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
  $qualityPath = Join-Path $repositoryRoot 'scripts\quality.ps1'
  $resolvedEvidence = if ([IO.Path]::IsPathRooted($EvidenceDirectory)) {
    [IO.Path]::GetFullPath($EvidenceDirectory)
  } else {
    [IO.Path]::GetFullPath((Join-Path $repositoryRoot $EvidenceDirectory))
  }
  $relativeEvidence = [IO.Path]::GetRelativePath(
    $repositoryRoot,
    $resolvedEvidence
  ).Replace('\', '/')
  $requiredSegments = @(
    $relativeEvidence.Split(
      [char[]]@('/', '\'),
      [StringSplitOptions]::RemoveEmptyEntries
    ) | Where-Object { $_ -match '(?i)required' }
  )
  if ($relativeEvidence -ceq '.' -or $requiredSegments.Count -eq 0) {
    throw (
      'EvidenceDirectory must be a dedicated Required path with a path segment ' +
      "containing 'required'; received '$relativeEvidence'."
    )
  }

  [void](New-Item -ItemType Directory -Force -Path $resolvedEvidence)
  $stdoutPath = Join-Path $resolvedEvidence 'required.stdout.log'
  $stderrPath = Join-Path $resolvedEvidence 'required.stderr.log'
  $recordPath = Join-Path $resolvedEvidence 'required-invocation.json'
  $utf8NoBom = [Text.UTF8Encoding]::new($false)
  $displayCommand = (
    'pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required ' +
    "-EvidenceDirectory $relativeEvidence"
  )

  $timedOut = $false
  $exitCode = $null
  $processTreeTerminated = $false
  $terminationStatus = 'start-failed'
  $stdout = ''
  $stderr = ''
  $process = $null
  $processTracker = $null
  $stdoutTask = $null
  $stderrTask = $null

  try {
    $pwshCommand = @(
      Get-Command pwsh -CommandType Application -ErrorAction Stop
    ) | Select-Object -First 1
    $pwshPath = $pwshCommand.Source
    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $pwshPath
    $startInfo.WorkingDirectory = $repositoryRoot
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    [void]$startInfo.ArgumentList.Add('-NoProfile')
    [void]$startInfo.ArgumentList.Add('-File')
    [void]$startInfo.ArgumentList.Add($qualityPath)
    [void]$startInfo.ArgumentList.Add('-Lane')
    [void]$startInfo.ArgumentList.Add('Required')
    [void]$startInfo.ArgumentList.Add('-EvidenceDirectory')
    [void]$startInfo.ArgumentList.Add($resolvedEvidence)

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
      throw 'System.Diagnostics.Process.Start returned false.'
    }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $processTracker = New-RequiredProcessTracker -RootProcessId $process.Id
    $timeoutMilliseconds = $TimeoutSeconds * 1000
    if (Wait-RequiredRootExitTracked `
        -Process $process `
        -Tracker $processTracker `
        -TimeoutMilliseconds $timeoutMilliseconds) {
      $exitCode = [int]$process.ExitCode
      try {
        $termination = Stop-RequiredProcessTreeVerified `
          -Process $process `
          -Tracker $processTracker `
          -RootExited `
          -CleanupTimeoutMilliseconds 30000
        $processTreeTerminated = $termination.ProcessTreeTerminated
        $terminationStatus = $termination.TerminationStatus
      } catch {
        $terminationStatus = 'exit-drain-failed'
        $stderr = "Required process-tree exit drain failed: $($_.Exception.Message)`n"
      }
    } else {
      $timedOut = $true
      try {
        $termination = Stop-RequiredProcessTreeVerified `
          -Process $process `
          -Tracker $processTracker `
          -CleanupTimeoutMilliseconds 30000
        $processTreeTerminated = $termination.ProcessTreeTerminated
        $terminationStatus = $termination.TerminationStatus
      } catch {
        $terminationStatus = 'kill-failed'
        $stderr = "Required process-tree termination failed: $($_.Exception.Message)`n"
      }
    }

    if ($processTreeTerminated) {
      $stdout = $stdoutTask.GetAwaiter().GetResult()
      $stderr += $stderrTask.GetAwaiter().GetResult()
    } else {
      if ($stdoutTask.IsCompletedSuccessfully) {
        $stdout = $stdoutTask.GetAwaiter().GetResult()
      }
      if ($stderrTask.IsCompletedSuccessfully) {
        $stderr += $stderrTask.GetAwaiter().GetResult()
      }
      $stderr += (
        "Required process tree did not terminate; status=$terminationStatus.`n"
      )
    }
  } catch {
    $stderr += "Required invocation failed: $($_.Exception.Message)`n"
  } finally {
    if ($null -ne $process) {
      $process.Dispose()
    }
  }

  [IO.File]::WriteAllText(
    $stdoutPath,
    $stdout.Replace("`r`n", "`n"),
    $utf8NoBom
  )
  [IO.File]::WriteAllText(
    $stderrPath,
    $stderr.Replace("`r`n", "`n"),
    $utf8NoBom
  )

  $passed = (
    -not $timedOut -and
    $processTreeTerminated -and
    $null -ne $exitCode -and
    $exitCode -eq 0
  )
  $record = [pscustomobject][ordered]@{
    command = $displayCommand
    timeout_seconds = $TimeoutSeconds
    timed_out = $timedOut
    exit_code = $exitCode
    stdout_path = [IO.Path]::GetRelativePath(
      $repositoryRoot,
      $stdoutPath
    ).Replace('\', '/')
    stderr_path = [IO.Path]::GetRelativePath(
      $repositoryRoot,
      $stderrPath
    ).Replace('\', '/')
    process_tree_terminated = $processTreeTerminated
    termination_status = $terminationStatus
    status = if ($passed) { 'pass' } else { 'failure' }
  }
  $json = (($record | ConvertTo-Json -Depth 4).Replace("`r`n", "`n")) + "`n"
  [IO.File]::WriteAllText($recordPath, $json, $utf8NoBom)

  return [pscustomobject]@{
    Passed = $passed
    RecordPath = $recordPath
    Record = $record
  }
}

if ($ImportOnly) {
  return
}

$result = Invoke-RequiredBounded `
  -EvidenceDirectory $EvidenceDirectory `
  -TimeoutSeconds $TimeoutSeconds
if (-not $result.Passed) {
  Write-Error (
    "Required lane failed; outcome recorded at '$($result.RecordPath)'."
  ) -ErrorAction Continue
  exit 1
}
Write-Host "Required lane passed; outcome recorded at '$($result.RecordPath)'."
exit 0
