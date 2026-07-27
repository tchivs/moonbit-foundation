$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'Invoke-RequiredBounded.ps1') -ImportOnly

$pwshPath = @(
  Get-Command pwsh -CommandType Application -ErrorAction Stop
)[0].Source
$pidFile = Join-Path ([IO.Path]::GetTempPath()) (
  'mnf-required-grandchild-' + [Guid]::NewGuid().ToString('N') + '.pid'
)
$quotedPwsh = $pwshPath.Replace("'", "''")
$quotedPidFile = $pidFile.Replace("'", "''")
$probe = @"
`$child = Start-Process -FilePath '$quotedPwsh' -ArgumentList @(
  '-NoProfile',
  '-Command',
  'Start-Sleep -Seconds 60'
) -PassThru
[IO.File]::WriteAllText('$quotedPidFile', [string]`$child.Id)
Start-Sleep -Seconds 60
"@
$encodedProbe = [Convert]::ToBase64String(
  [Text.Encoding]::Unicode.GetBytes($probe)
)
$startInfo = [Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $pwshPath
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
[void]$startInfo.ArgumentList.Add('-NoProfile')
[void]$startInfo.ArgumentList.Add('-EncodedCommand')
[void]$startInfo.ArgumentList.Add($encodedProbe)
$root = [Diagnostics.Process]::new()
$root.StartInfo = $startInfo
$rootId = $null
$grandchildId = $null

try {
  if (-not $root.Start()) {
    throw 'Process-tree probe root failed to start.'
  }
  $rootId = $root.Id
  $deadline = [DateTime]::UtcNow.AddSeconds(10)
  while (-not (Test-Path -LiteralPath $pidFile -PathType Leaf) -and
         [DateTime]::UtcNow -lt $deadline) {
    Start-Sleep -Milliseconds 100
  }
  if (-not (Test-Path -LiteralPath $pidFile -PathType Leaf)) {
    throw 'Process-tree probe did not publish its grandchild PID.'
  }
  $grandchildId = [int][IO.File]::ReadAllText($pidFile)
  $snapshot = @(Get-RequiredProcessSnapshot)
  $descendants = @(
    Get-RequiredDescendantProcessIds -RootProcessId $rootId -Snapshot $snapshot
  )
  if ($descendants -notcontains $grandchildId) {
    throw "Process-tree probe did not discover grandchild PID $grandchildId."
  }

  $result = Stop-RequiredProcessTreeVerified `
    -Process $root `
    -CleanupTimeoutMilliseconds 10000
  if (-not $result.ProcessTreeTerminated -or
      $result.TerminationStatus -cne 'killed-verified' -or
      (Test-RequiredProcessAlive -ProcessId $grandchildId)) {
    throw 'Tracked grandchild survived verified process-tree termination.'
  }
  Write-Host 'PASS: Required timeout verifies descendant termination'
} finally {
  if ($null -ne $grandchildId -and
      (Test-RequiredProcessAlive -ProcessId $grandchildId)) {
    [Diagnostics.Process]::GetProcessById($grandchildId).Kill($true)
  }
  if ($null -ne $rootId -and
      (Test-RequiredProcessAlive -ProcessId $rootId)) {
    [Diagnostics.Process]::GetProcessById($rootId).Kill($true)
  }
  $root.Dispose()
  if (Test-Path -LiteralPath $pidFile) {
    Remove-Item -LiteralPath $pidFile -Force
  }
}
