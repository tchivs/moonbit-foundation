[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$guard = Join-Path $PSScriptRoot 'Assert-Phase08R13DirtyBaseline.ps1'
$root = Join-Path ([IO.Path]::GetTempPath()) ('mnf-r13-baseline-test-' + [Guid]::NewGuid().ToString('N'))
$baseline = Join-Path $root 'baseline.json'
$protected = @(
  '.planning/config.json',
  'docs/governance/decisions/0001-sole-owner-bootstrap.md',
  'docs/governance/rfc-process.md',
  '.codebase-memory/',
  '.planning/phases/08-ordered-mooncakes-publication-and-registry-consumers/research-plan-input.json',
  '.planning/research/.cache/',
  '.github/workflows/quality.yml',
  '.planning/quick/260719-fix-github-actions-ci/PLAN.md'
)

function Assert-Rejected {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][scriptblock]$Action)
  $failed = $false
  try { & $Action } catch { $failed = $true }
  if (-not $failed) { throw "${Id}: expected rejection." }
}

try {
  foreach ($path in $protected) {
    $full = Join-Path $root $path.TrimEnd('/')
    $parent = Split-Path -Parent $full
    $null = New-Item -ItemType Directory -Force -Path $parent
    if ($path.EndsWith('/')) { $null = New-Item -ItemType Directory -Force -Path $full; Set-Content -LiteralPath (Join-Path $full 'member.txt') -Value $path -NoNewline }
    else { Set-Content -LiteralPath $full -Value $path -NoNewline }
  }
  $task = 'scripts/quality/task-owned.ps1'
  $taskFull = Join-Path $root $task; $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $taskFull); Set-Content -LiteralPath $taskFull -Value 'task' -NoNewline
  git -C $root init --quiet
  git -C $root add -- .
  git -C $root -c user.name=baseline-test -c user.email=baseline-test@invalid.local commit --quiet -m baseline

  & $guard -Mode Capture -RepositoryRoot $root -BaselinePath $baseline -TaskOwnedPath $task
  & $guard -Mode Verify -RepositoryRoot $root -BaselinePath $baseline -TaskOwnedPath $task

  Add-Content -LiteralPath (Join-Path $root '.planning/config.json') -Value 'status-drift'
  Assert-Rejected 'P08-R13-STATUS-DRIFT' { & $guard -Mode Verify -RepositoryRoot $root -BaselinePath $baseline -TaskOwnedPath $task }
  git -C $root checkout -- .planning/config.json

  Add-Content -LiteralPath (Join-Path $root 'docs/governance/rfc-process.md') -Value 'content-drift'
  Assert-Rejected 'P08-R13-CONTENT-DRIFT' { & $guard -Mode Verify -RepositoryRoot $root -BaselinePath $baseline -TaskOwnedPath $task }
  git -C $root checkout -- docs/governance/rfc-process.md

  Add-Content -LiteralPath (Join-Path $root '.codebase-memory/member.txt') -Value 'directory-drift'
  Assert-Rejected 'P08-R13-DIRECTORY-DRIFT' { & $guard -Mode Verify -RepositoryRoot $root -BaselinePath $baseline -TaskOwnedPath $task }
  git -C $root checkout -- .codebase-memory/member.txt

  Set-Content -LiteralPath (Join-Path $root 'unexpected.txt') -Value 'unexpected' -NoNewline
  Assert-Rejected 'P08-R13-UNEXPECTED-DRIFT' { & $guard -Mode Verify -RepositoryRoot $root -BaselinePath $baseline -TaskOwnedPath $task }
  Remove-Item -LiteralPath (Join-Path $root 'unexpected.txt') -Force

  Set-Content -LiteralPath $baseline -Value '{}' -NoNewline
  Assert-Rejected 'P08-R13-MALFORMED-BASELINE' { & $guard -Mode Verify -RepositoryRoot $root -BaselinePath $baseline -TaskOwnedPath $task }
  & $guard -Mode Capture -RepositoryRoot $root -BaselinePath $baseline -TaskOwnedPath $task
  $doc = Get-Content -LiteralPath $baseline -Raw | ConvertFrom-Json -Depth 20
  $doc.records += [pscustomobject]@{ path = 'ninth-path'; status = ''; sha256 = ('0' * 64) }
  $doc | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $baseline -NoNewline
  Assert-Rejected 'P08-R13-NINTH-PATH' { & $guard -Mode Verify -RepositoryRoot $root -BaselinePath $baseline -TaskOwnedPath $task }
  & $guard -Mode Capture -RepositoryRoot $root -BaselinePath $baseline -TaskOwnedPath $task
  Assert-Rejected 'P08-R13-WILDCARD-TASK' { & $guard -Mode Verify -RepositoryRoot $root -BaselinePath $baseline -TaskOwnedPath 'scripts/*' }
  Assert-Rejected 'P08-R13-PROTECTED-TASK' { & $guard -Mode Verify -RepositoryRoot $root -BaselinePath $baseline -TaskOwnedPath '.planning/config.json' }
  Assert-Rejected 'P08-R13-UNDECLARED-TASK' { & $guard -Mode Verify -RepositoryRoot $root -BaselinePath $baseline -TaskOwnedPath 'scripts/quality/other.ps1' }
  Write-Host 'Phase 08 r13 dirty-baseline tests passed.'
} finally {
  if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
