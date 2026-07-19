[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet('Capture','Verify')][string]$Mode,
  [Parameter(Mandatory)][string]$BaselinePath,
  [Parameter(Mandatory)][string[]]$TaskOwnedPath,
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) {
  $RepositoryRoot = (& git -C $PSScriptRoot rev-parse --show-toplevel).Trim()
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($RepositoryRoot)) { throw 'P08-R13-GIT: unable to resolve repository root.' }
} else {
  $RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
}

$protectedPaths = @(
  '.planning/config.json',
  'docs/governance/decisions/0001-sole-owner-bootstrap.md',
  'docs/governance/rfc-process.md',
  '.codebase-memory/',
  '.planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/research-plan-input.json',
  '.planning/research/.cache/',
  '.github/workflows/quality.yml',
  '.planning/quick/260719-fix-github-actions-ci/PLAN.md'
)

function Fail-Baseline([string]$Id, [string]$Message) { throw "$Id`: $Message" }

function Normalize-RepositoryPath([string]$Path) {
  if ([string]::IsNullOrWhiteSpace($Path)) { Fail-Baseline 'P08-R13-TASK-PATH' 'Task-owned path is empty.' }
  $value = $Path.Replace('\','/').Trim()
  if ($value.StartsWith('./', [StringComparison]::Ordinal)) { $value = $value.Substring(2) }
  if ($value.Contains('*') -or $value.Contains('?') -or $value.Contains('..') -or [IO.Path]::IsPathRooted($value) -or $value.EndsWith('/')) {
    Fail-Baseline 'P08-R13-TASK-PATH' "Task-owned path '$Path' is not one exact repository file."
  }
  return $value
}

function Test-UnderPath([string]$Candidate, [string]$Root) {
  return $Candidate -ceq $Root -or ($Root.EndsWith('/') -and $Candidate.StartsWith($Root, [StringComparison]::Ordinal))
}

function Get-TaskOwnedPaths {
  $normalized = @($TaskOwnedPath | ForEach-Object { $_ -split ',' } | ForEach-Object { Normalize-RepositoryPath $_ } | Sort-Object -Unique)
  if ($normalized.Count -eq 0) { Fail-Baseline 'P08-R13-TASK-PATH' 'At least one task-owned path is required.' }
  foreach ($path in $normalized) {
    foreach ($protected in $protectedPaths) {
      if (Test-UnderPath $path $protected) { Fail-Baseline 'P08-R13-TASK-PATH' "Task-owned path '$path' overlaps protected user dirties." }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $RepositoryRoot $path) -PathType Leaf)) { Fail-Baseline 'P08-R13-TASK-PATH' "Task-owned path '$path' does not exist as a file." }
  }
  return $normalized
}

function Get-PorcelainEntries {
  $lines = @(& git -C $RepositoryRoot status --porcelain=v1 --untracked-files=all)
  if ($LASTEXITCODE -ne 0) { Fail-Baseline 'P08-R13-GIT' 'Unable to inspect worktree status.' }
  $entries = @()
  foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line.Length -lt 4 -or $line[2] -ne ' ') { Fail-Baseline 'P08-R13-GIT' "Unsupported porcelain entry '$line'." }
    if ($line.StartsWith('R') -or $line.StartsWith('C') -or $line.Substring(0,2).Contains('R') -or $line.Substring(0,2).Contains('C')) {
      Fail-Baseline 'P08-R13-GIT' 'Rename and copy status entries are rejected fail-closed.'
    }
    $entries += [pscustomobject]@{ status=$line.Substring(0,2); path=$line.Substring(3).Replace('\','/') }
  }
  return $entries
}

function Get-ContentSha256([string]$RelativePath) {
  $full = Join-Path $RepositoryRoot $RelativePath.TrimEnd('/')
  if (Test-Path -LiteralPath $full -PathType Leaf) { return (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant() }
  if (-not (Test-Path -LiteralPath $full -PathType Container)) { Fail-Baseline 'P08-R13-PROTECTED-MISSING' "Protected path '$RelativePath' is absent." }
  $entries = @(
    Get-ChildItem -LiteralPath $full -Recurse -File -Force | Sort-Object FullName | ForEach-Object {
      $relative = [IO.Path]::GetRelativePath($full, $_.FullName).Replace('\','/')
      "$relative=$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant())"
    }
  )
  $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($entries -join "`n"))
  return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
}

function Get-Projection {
  $status = Get-PorcelainEntries
  $records = foreach ($protected in $protectedPaths) {
    $pathStatus = @($status | Where-Object { Test-UnderPath $_.path $protected } | ForEach-Object { "$($_.status) $($_.path)" } | Sort-Object) -join "`n"
    [pscustomobject][ordered]@{ path=$protected; status=$pathStatus; sha256=(Get-ContentSha256 $protected) }
  }
  return @($records)
}

function Assert-NoUnexpectedDirty([string[]]$TaskPaths) {
  foreach ($entry in Get-PorcelainEntries) {
    $allowed = $false
    foreach ($protected in $protectedPaths) { if (Test-UnderPath $entry.path $protected) { $allowed = $true; break } }
    if (-not $allowed) { foreach ($task in $TaskPaths) { if ($entry.path -ceq $task) { $allowed = $true; break } } }
    if (-not $allowed) { Fail-Baseline 'P08-R13-UNEXPECTED-DRIFT' "Dirty path '$($entry.path)' is neither protected nor task-owned." }
  }
}

function Read-Baseline {
  if (-not (Test-Path -LiteralPath $BaselinePath -PathType Leaf)) { Fail-Baseline 'P08-R13-BASELINE' "Baseline '$BaselinePath' is absent." }
  try { $doc = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json -Depth 20 } catch { Fail-Baseline 'P08-R13-BASELINE' 'Baseline is not valid JSON.' }
  if ((@($doc.PSObject.Properties.Name) -join ',') -cne 'schema_version,protected_paths,records' -or $doc.schema_version -cne 'mnf-phase08-r13-dirty-baseline/1') {
    Fail-Baseline 'P08-R13-BASELINE' 'Baseline schema is not the exact closed version.'
  }
  if ((@($doc.protected_paths) -join "`n") -cne ($protectedPaths -join "`n") -or @($doc.records).Count -ne $protectedPaths.Count) { Fail-Baseline 'P08-R13-BASELINE' 'Baseline path set is not the exact protected eight.' }
  for ($i=0; $i -lt $protectedPaths.Count; $i++) {
    $record = $doc.records[$i]
    if ((@($record.PSObject.Properties.Name) -join ',') -cne 'path,status,sha256' -or $record.path -cne $protectedPaths[$i] -or $record.status -isnot [string] -or $record.sha256 -cnotmatch '^[0-9a-f]{64}$') {
      Fail-Baseline 'P08-R13-BASELINE' 'Baseline record is malformed or includes a ninth path.'
    }
  }
  return $doc
}

$taskPaths = Get-TaskOwnedPaths
Assert-NoUnexpectedDirty -TaskPaths $taskPaths
if ($Mode -ceq 'Capture') {
  $baselineDirectory = Split-Path -Parent $BaselinePath
  if ([string]::IsNullOrWhiteSpace($baselineDirectory) -or -not (Test-Path -LiteralPath $baselineDirectory -PathType Container)) { Fail-Baseline 'P08-R13-BASELINE' 'Baseline parent directory must already exist.' }
  $document = [pscustomobject][ordered]@{ schema_version='mnf-phase08-r13-dirty-baseline/1'; protected_paths=$protectedPaths; records=(Get-Projection) }
  [IO.File]::WriteAllText($BaselinePath, ($document | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
  exit 0
}

$baseline = Read-Baseline
$current = Get-Projection
for ($i=0; $i -lt $protectedPaths.Count; $i++) {
  if ($baseline.records[$i].status -cne $current[$i].status -or $baseline.records[$i].sha256 -cne $current[$i].sha256) {
    Fail-Baseline 'P08-R13-PROTECTED-DRIFT' "Protected path '$($protectedPaths[$i])' status or content changed."
  }
}
