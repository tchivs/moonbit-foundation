[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$EvidenceDirectory,
  [ValidateRange(1, 86400)]
  [int]$TimeoutSeconds = 900
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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
        $process.Kill($true)
        if ($process.WaitForExit(30000)) {
          $process.WaitForExit()
          $processTreeTerminated = $true
          $terminationStatus = 'killed'
        } else {
          $terminationStatus = 'kill-wait-timeout'
        }
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
