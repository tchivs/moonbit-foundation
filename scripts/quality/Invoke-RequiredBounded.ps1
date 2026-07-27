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

function Initialize-RequiredWindowsJobInterop {
  if (-not [OperatingSystem]::IsWindows() -or
      $null -ne ('Mnf.RequiredJobProcess' -as [type])) {
    return
  }

  Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace Mnf
{
    public sealed class RequiredJobProcess : IDisposable
    {
        private const uint CREATE_SUSPENDED = 0x00000004;
        private const uint CREATE_NO_WINDOW = 0x08000000;
        private const uint STARTF_USESTDHANDLES = 0x00000100;
        private const uint JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x00002000;
        private const uint GENERIC_READ = 0x80000000;
        private const uint GENERIC_WRITE = 0x40000000;
        private const uint FILE_SHARE_READ = 0x00000001;
        private const uint FILE_SHARE_WRITE = 0x00000002;
        private const uint CREATE_ALWAYS = 2;
        private const uint OPEN_EXISTING = 3;
        private const uint FILE_ATTRIBUTE_NORMAL = 0x00000080;
        private const uint WAIT_OBJECT_0 = 0;
        private const uint WAIT_TIMEOUT = 258;
        private const int JobObjectBasicAccountingInformation = 1;
        private const int JobObjectExtendedLimitInformation = 9;
        private static readonly IntPtr InvalidHandle = new IntPtr(-1);

        private IntPtr jobHandle;
        private IntPtr processHandle;
        private bool disposed;

        public int ProcessId { get; private set; }

        private RequiredJobProcess(IntPtr job, IntPtr process, int processId)
        {
            jobHandle = job;
            processHandle = process;
            ProcessId = processId;
        }

        public static RequiredJobProcess Start(
            string fileName,
            string[] arguments,
            string workingDirectory,
            string stdoutPath,
            string stderrPath)
        {
            IntPtr job = IntPtr.Zero;
            IntPtr stdout = InvalidHandle;
            IntPtr stderr = InvalidHandle;
            IntPtr stdin = InvalidHandle;
            PROCESS_INFORMATION process = new PROCESS_INFORMATION();
            bool assigned = false;
            try
            {
                job = CreateJobObject(IntPtr.Zero, null);
                ThrowIfInvalid(job, "CreateJobObject");
                SetKillOnClose(job);

                SECURITY_ATTRIBUTES security = new SECURITY_ATTRIBUTES();
                security.nLength = Marshal.SizeOf(typeof(SECURITY_ATTRIBUTES));
                security.bInheritHandle = true;
                stdout = CreateFile(
                    stdoutPath,
                    GENERIC_WRITE,
                    FILE_SHARE_READ | FILE_SHARE_WRITE,
                    ref security,
                    CREATE_ALWAYS,
                    FILE_ATTRIBUTE_NORMAL,
                    IntPtr.Zero);
                ThrowIfInvalid(stdout, "CreateFile(stdout)");
                stderr = CreateFile(
                    stderrPath,
                    GENERIC_WRITE,
                    FILE_SHARE_READ | FILE_SHARE_WRITE,
                    ref security,
                    CREATE_ALWAYS,
                    FILE_ATTRIBUTE_NORMAL,
                    IntPtr.Zero);
                ThrowIfInvalid(stderr, "CreateFile(stderr)");
                stdin = CreateFile(
                    "NUL",
                    GENERIC_READ,
                    FILE_SHARE_READ | FILE_SHARE_WRITE,
                    ref security,
                    OPEN_EXISTING,
                    FILE_ATTRIBUTE_NORMAL,
                    IntPtr.Zero);
                ThrowIfInvalid(stdin, "CreateFile(stdin)");

                STARTUPINFO startup = new STARTUPINFO();
                startup.cb = Marshal.SizeOf(typeof(STARTUPINFO));
                startup.dwFlags = STARTF_USESTDHANDLES;
                startup.hStdInput = stdin;
                startup.hStdOutput = stdout;
                startup.hStdError = stderr;
                StringBuilder commandLine = new StringBuilder(
                    BuildCommandLine(fileName, arguments));
                if (!CreateProcess(
                    fileName,
                    commandLine,
                    IntPtr.Zero,
                    IntPtr.Zero,
                    true,
                    CREATE_SUSPENDED | CREATE_NO_WINDOW,
                    IntPtr.Zero,
                    workingDirectory,
                    ref startup,
                    out process))
                {
                    throw new Win32Exception(
                        Marshal.GetLastWin32Error(),
                        "CreateProcess suspended failed");
                }

                if (!AssignProcessToJobObject(job, process.hProcess))
                {
                    throw new Win32Exception(
                        Marshal.GetLastWin32Error(),
                        "AssignProcessToJobObject failed");
                }
                assigned = true;
                uint resumeResult = ResumeThread(process.hThread);
                if (resumeResult == UInt32.MaxValue)
                {
                    throw new Win32Exception(
                        Marshal.GetLastWin32Error(),
                        "ResumeThread failed");
                }
                CloseHandle(process.hThread);
                process.hThread = IntPtr.Zero;
                RequiredJobProcess result = new RequiredJobProcess(
                    job,
                    process.hProcess,
                    unchecked((int)process.dwProcessId));
                job = IntPtr.Zero;
                process.hProcess = IntPtr.Zero;
                return result;
            }
            catch
            {
                if (assigned && job != IntPtr.Zero)
                {
                    TerminateJobObject(job, 1);
                }
                else if (process.hProcess != IntPtr.Zero)
                {
                    TerminateProcess(process.hProcess, 1);
                }
                throw;
            }
            finally
            {
                CloseIfValid(stdout);
                CloseIfValid(stderr);
                CloseIfValid(stdin);
                CloseIfValid(process.hThread);
                CloseIfValid(process.hProcess);
                CloseIfValid(job);
            }
        }

        public bool WaitForRootExit(int timeoutMilliseconds)
        {
            EnsureNotDisposed();
            uint result = WaitForSingleObject(
                processHandle,
                unchecked((uint)timeoutMilliseconds));
            if (result == WAIT_OBJECT_0)
            {
                return true;
            }
            if (result == WAIT_TIMEOUT)
            {
                return false;
            }
            throw new Win32Exception(
                Marshal.GetLastWin32Error(),
                "WaitForSingleObject failed");
        }

        public int GetRootExitCode()
        {
            EnsureNotDisposed();
            uint code;
            if (!GetExitCodeProcess(processHandle, out code))
            {
                throw new Win32Exception(
                    Marshal.GetLastWin32Error(),
                    "GetExitCodeProcess failed");
            }
            return unchecked((int)code);
        }

        public uint ActiveProcessCount
        {
            get
            {
                EnsureNotDisposed();
                JOBOBJECT_BASIC_ACCOUNTING_INFORMATION accounting;
                if (!QueryInformationJobObject(
                    jobHandle,
                    JobObjectBasicAccountingInformation,
                    out accounting,
                    Marshal.SizeOf(
                        typeof(JOBOBJECT_BASIC_ACCOUNTING_INFORMATION)),
                    IntPtr.Zero))
                {
                    throw new Win32Exception(
                        Marshal.GetLastWin32Error(),
                        "QueryInformationJobObject failed");
                }
                return accounting.ActiveProcesses;
            }
        }

        public void Terminate(uint exitCode)
        {
            EnsureNotDisposed();
            if (!TerminateJobObject(jobHandle, exitCode))
            {
                throw new Win32Exception(
                    Marshal.GetLastWin32Error(),
                    "TerminateJobObject failed");
            }
        }

        public bool WaitForEmpty(int timeoutMilliseconds)
        {
            EnsureNotDisposed();
            long deadline = Environment.TickCount64 + timeoutMilliseconds;
            do
            {
                if (ActiveProcessCount == 0)
                {
                    return true;
                }
                Thread.Sleep(50);
            }
            while (Environment.TickCount64 < deadline);
            return ActiveProcessCount == 0;
        }

        public void Dispose()
        {
            if (disposed)
            {
                return;
            }
            disposed = true;
            CloseIfValid(processHandle);
            processHandle = IntPtr.Zero;
            // Kill-on-close remains a final fail-closed backstop.
            CloseIfValid(jobHandle);
            jobHandle = IntPtr.Zero;
        }

        private void EnsureNotDisposed()
        {
            if (disposed)
            {
                throw new ObjectDisposedException("RequiredJobProcess");
            }
        }

        private static void SetKillOnClose(IntPtr job)
        {
            JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits =
                new JOBOBJECT_EXTENDED_LIMIT_INFORMATION();
            limits.BasicLimitInformation.LimitFlags =
                JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
            int size = Marshal.SizeOf(
                typeof(JOBOBJECT_EXTENDED_LIMIT_INFORMATION));
            IntPtr buffer = Marshal.AllocHGlobal(size);
            try
            {
                Marshal.StructureToPtr(limits, buffer, false);
                if (!SetInformationJobObject(
                    job,
                    JobObjectExtendedLimitInformation,
                    buffer,
                    unchecked((uint)size)))
                {
                    throw new Win32Exception(
                        Marshal.GetLastWin32Error(),
                        "SetInformationJobObject failed");
                }
            }
            finally
            {
                Marshal.FreeHGlobal(buffer);
            }
        }

        private static string BuildCommandLine(
            string fileName,
            string[] arguments)
        {
            StringBuilder result = new StringBuilder();
            result.Append(QuoteArgument(fileName));
            foreach (string argument in arguments)
            {
                result.Append(' ');
                result.Append(QuoteArgument(argument));
            }
            return result.ToString();
        }

        private static string QuoteArgument(string argument)
        {
            if (argument.Length == 0)
            {
                return "\"\"";
            }
            bool needsQuotes = false;
            foreach (char value in argument)
            {
                if (Char.IsWhiteSpace(value) || value == '"')
                {
                    needsQuotes = true;
                    break;
                }
            }
            if (!needsQuotes)
            {
                return argument;
            }
            StringBuilder result = new StringBuilder();
            result.Append('"');
            int backslashes = 0;
            foreach (char value in argument)
            {
                if (value == '\\')
                {
                    backslashes++;
                    continue;
                }
                if (value == '"')
                {
                    result.Append('\\', backslashes * 2 + 1);
                    result.Append('"');
                    backslashes = 0;
                    continue;
                }
                result.Append('\\', backslashes);
                backslashes = 0;
                result.Append(value);
            }
            result.Append('\\', backslashes * 2);
            result.Append('"');
            return result.ToString();
        }

        private static void ThrowIfInvalid(IntPtr handle, string operation)
        {
            if (handle == IntPtr.Zero || handle == InvalidHandle)
            {
                throw new Win32Exception(
                    Marshal.GetLastWin32Error(),
                    operation + " failed");
            }
        }

        private static void CloseIfValid(IntPtr handle)
        {
            if (handle != IntPtr.Zero && handle != InvalidHandle)
            {
                CloseHandle(handle);
            }
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct SECURITY_ATTRIBUTES
        {
            public int nLength;
            public IntPtr lpSecurityDescriptor;
            [MarshalAs(UnmanagedType.Bool)]
            public bool bInheritHandle;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct STARTUPINFO
        {
            public int cb;
            public string lpReserved;
            public string lpDesktop;
            public string lpTitle;
            public int dwX;
            public int dwY;
            public int dwXSize;
            public int dwYSize;
            public int dwXCountChars;
            public int dwYCountChars;
            public int dwFillAttribute;
            public uint dwFlags;
            public short wShowWindow;
            public short cbReserved2;
            public IntPtr lpReserved2;
            public IntPtr hStdInput;
            public IntPtr hStdOutput;
            public IntPtr hStdError;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct PROCESS_INFORMATION
        {
            public IntPtr hProcess;
            public IntPtr hThread;
            public uint dwProcessId;
            public uint dwThreadId;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct JOBOBJECT_BASIC_LIMIT_INFORMATION
        {
            public long PerProcessUserTimeLimit;
            public long PerJobUserTimeLimit;
            public uint LimitFlags;
            public UIntPtr MinimumWorkingSetSize;
            public UIntPtr MaximumWorkingSetSize;
            public uint ActiveProcessLimit;
            public UIntPtr Affinity;
            public uint PriorityClass;
            public uint SchedulingClass;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct IO_COUNTERS
        {
            public ulong ReadOperationCount;
            public ulong WriteOperationCount;
            public ulong OtherOperationCount;
            public ulong ReadTransferCount;
            public ulong WriteTransferCount;
            public ulong OtherTransferCount;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION
        {
            public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
            public IO_COUNTERS IoInfo;
            public UIntPtr ProcessMemoryLimit;
            public UIntPtr JobMemoryLimit;
            public UIntPtr PeakProcessMemoryUsed;
            public UIntPtr PeakJobMemoryUsed;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct JOBOBJECT_BASIC_ACCOUNTING_INFORMATION
        {
            public long TotalUserTime;
            public long TotalKernelTime;
            public long ThisPeriodTotalUserTime;
            public long ThisPeriodTotalKernelTime;
            public uint TotalPageFaultCount;
            public uint TotalProcesses;
            public uint ActiveProcesses;
            public uint TotalTerminatedProcesses;
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr CreateJobObject(
            IntPtr jobAttributes,
            string name);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool SetInformationJobObject(
            IntPtr job,
            int informationClass,
            IntPtr information,
            uint informationLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool QueryInformationJobObject(
            IntPtr job,
            int informationClass,
            out JOBOBJECT_BASIC_ACCOUNTING_INFORMATION information,
            int informationLength,
            IntPtr returnLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool AssignProcessToJobObject(
            IntPtr job,
            IntPtr process);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool CreateProcess(
            string applicationName,
            StringBuilder commandLine,
            IntPtr processAttributes,
            IntPtr threadAttributes,
            [MarshalAs(UnmanagedType.Bool)] bool inheritHandles,
            uint creationFlags,
            IntPtr environment,
            string currentDirectory,
            ref STARTUPINFO startupInfo,
            out PROCESS_INFORMATION processInformation);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr CreateFile(
            string fileName,
            uint desiredAccess,
            uint shareMode,
            ref SECURITY_ATTRIBUTES securityAttributes,
            uint creationDisposition,
            uint flagsAndAttributes,
            IntPtr templateFile);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern uint ResumeThread(IntPtr thread);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern uint WaitForSingleObject(
            IntPtr handle,
            uint milliseconds);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool GetExitCodeProcess(
            IntPtr process,
            out uint exitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool TerminateJobObject(
            IntPtr job,
            uint exitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool TerminateProcess(
            IntPtr process,
            uint exitCode);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool CloseHandle(IntPtr handle);
    }
}
'@
}

function Start-RequiredWindowsJobProcess {
  param(
    [Parameter(Mandatory)][string]$FileName,
    [Parameter(Mandatory)][string[]]$Arguments,
    [Parameter(Mandatory)][string]$WorkingDirectory,
    [Parameter(Mandatory)][string]$StdoutPath,
    [Parameter(Mandatory)][string]$StderrPath
  )

  Initialize-RequiredWindowsJobInterop
  return [Mnf.RequiredJobProcess]::Start(
    $FileName,
    $Arguments,
    $WorkingDirectory,
    $StdoutPath,
    $StderrPath
  )
}

function Stop-RequiredWindowsJobVerified {
  param(
    [Parameter(Mandatory)]$Containment,
    [switch]$RootExited,
    [ValidateRange(1, 120000)]
    [int]$CleanupTimeoutMilliseconds = 30000
  )

  $activeBeforeTermination = [uint32]$Containment.ActiveProcessCount
  $Containment.Terminate(1)
  $empty = $Containment.WaitForEmpty($CleanupTimeoutMilliseconds)
  $activeAfterTermination = [uint32]$Containment.ActiveProcessCount
  $verified = $empty -and $activeAfterTermination -eq 0
  return [pscustomobject]@{
    ProcessTreeTerminated = $verified
    TerminationStatus = if ($verified) {
      if ($RootExited) {
        'exited-job-terminated-verified'
      } else {
        'job-terminated-verified'
      }
    } else {
      'job-termination-verification-timeout'
    }
    ActiveBeforeTermination = $activeBeforeTermination
    ActiveAfterTermination = $activeAfterTermination
  }
}

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
  $windowsContainment = $null
  $useWindowsContainment = [OperatingSystem]::IsWindows()

  try {
    $pwshCommand = @(
      Get-Command pwsh -CommandType Application -ErrorAction Stop
    ) | Select-Object -First 1
    $pwshPath = $pwshCommand.Source
    $timeoutMilliseconds = $TimeoutSeconds * 1000
    if ($useWindowsContainment) {
      $windowsContainment = Start-RequiredWindowsJobProcess `
        -FileName $pwshPath `
        -Arguments @(
          '-NoProfile',
          '-File',
          $qualityPath,
          '-Lane',
          'Required',
          '-EvidenceDirectory',
          $resolvedEvidence
        ) `
        -WorkingDirectory $repositoryRoot `
        -StdoutPath $stdoutPath `
        -StderrPath $stderrPath
      $rootExited = $windowsContainment.WaitForRootExit($timeoutMilliseconds)
      if ($rootExited) {
        $exitCode = [int]$windowsContainment.GetRootExitCode()
      } else {
        $timedOut = $true
      }
      $termination = Stop-RequiredWindowsJobVerified `
        -Containment $windowsContainment `
        -RootExited:$rootExited `
        -CleanupTimeoutMilliseconds 30000
      $processTreeTerminated = $termination.ProcessTreeTerminated
      $terminationStatus = $termination.TerminationStatus
    } else {
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
      }
    }
    if (-not $processTreeTerminated) {
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
    if ($null -ne $windowsContainment) {
      $windowsContainment.Dispose()
    }
  }

  if ($useWindowsContainment) {
    $wrapperStderr = $stderr
    $stdout = if (Test-Path -LiteralPath $stdoutPath -PathType Leaf) {
      [IO.File]::ReadAllText($stdoutPath)
    } else {
      ''
    }
    $stderr = if (Test-Path -LiteralPath $stderrPath -PathType Leaf) {
      [IO.File]::ReadAllText($stderrPath) + $wrapperStderr
    } else {
      $wrapperStderr
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
