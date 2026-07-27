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

function Wait-RequiredTrackedProcessesExit {
  param(
    [Parameter(Mandatory)][int[]]$ProcessIds,
    [Parameter(Mandatory)][ValidateRange(1, 120000)]
    [int]$TimeoutMilliseconds
  )

  $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
  do {
    $live = @($ProcessIds | Where-Object {
      Test-RequiredProcessAlive -ProcessId $_
    })
    if ($live.Count -eq 0) {
      return $true
    }
    Start-Sleep -Milliseconds 100
  } while ([DateTime]::UtcNow -lt $deadline)
  return $false
}

function Stop-RequiredProcessTreeVerified {
  param(
    [Parameter(Mandatory)][Diagnostics.Process]$Process,
    [ValidateRange(1, 120000)]
    [int]$CleanupTimeoutMilliseconds = 30000
  )

  $snapshot = @(Get-RequiredProcessSnapshot)
  $descendants = @(
    Get-RequiredDescendantProcessIds `
      -RootProcessId $Process.Id `
      -Snapshot $snapshot
  )
  $tracked = @([int]$Process.Id) + $descendants
  try {
    if (-not $Process.HasExited) {
      $Process.Kill($true)
    }
  } catch {
    # Individual tracked termination below remains authoritative.
  }
  foreach ($processId in @($descendants | Sort-Object -Descending)) {
    try {
      $descendant = [Diagnostics.Process]::GetProcessById($processId)
      try {
        if (-not $descendant.HasExited) {
          $descendant.Kill($true)
        }
      } finally {
        $descendant.Dispose()
      }
    } catch [ArgumentException] {
      # The tracked descendant has already exited.
    }
  }
  $terminated = Wait-RequiredTrackedProcessesExit `
    -ProcessIds $tracked `
    -TimeoutMilliseconds $CleanupTimeoutMilliseconds
  return [pscustomobject]@{
    ProcessTreeTerminated = $terminated
    TerminationStatus = if ($terminated) {
      'killed-verified'
    } else {
      'kill-verification-timeout'
    }
    TrackedProcessIds = $tracked
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
    $timeoutMilliseconds = $TimeoutSeconds * 1000
    if ($process.WaitForExit($timeoutMilliseconds)) {
      $process.WaitForExit()
      $processTreeTerminated = $true
      $terminationStatus = 'exited'
      $exitCode = [int]$process.ExitCode
    } else {
      $timedOut = $true
      try {
        $termination = Stop-RequiredProcessTreeVerified `
          -Process $process `
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
