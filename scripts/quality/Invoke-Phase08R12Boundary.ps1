[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$CloneRoot,
  [Parameter(Mandatory)][string]$StateRoot,
  [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{40}$')][string]$ExpectedTagObject,
  [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{40}$')][string]$ExpectedPeeledSourceSha,
  [Parameter(Mandatory)][string]$HistoricalReleaseRef,
  [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{40}$')][string]$HistoricalSourceSha,
  [scriptblock]$PrepareProvider
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Throw-P08R12Boundary([string]$Id,[string]$Message) { throw "$Id`: $Message" }
function Invoke-P08R12BoundaryGit([string]$Root,[string[]]$Arguments) {
  $output=@(& git -C $Root @Arguments 2>&1)
  if($LASTEXITCODE -ne 0){Throw-P08R12Boundary 'P08-R12-GIT' "git $($Arguments -join ' ') failed."}
  $output
}

$clone=[IO.Path]::GetFullPath($CloneRoot)
if(-not(Test-Path -LiteralPath $clone -PathType Container)){Throw-P08R12Boundary 'P08-R12-CLONE' 'Clone root is missing.'}
$gitRoot=((Invoke-P08R12BoundaryGit $clone @('rev-parse','--show-toplevel'))-join '').Trim()
if([IO.Path]::GetFullPath($gitRoot) -cne $clone){Throw-P08R12Boundary 'P08-R12-CLONE' 'Clone root is not the exact Git worktree root.'}

$policyPath=Join-Path $clone 'policy/release-control.json'
if(-not(Test-Path -LiteralPath $policyPath -PathType Leaf)){Throw-P08R12Boundary 'P08-R12-POLICY' 'Clone-local release-control policy is missing.'}
$policy=Get-Content -LiteralPath $policyPath -Raw|ConvertFrom-Json -Depth 100
$canonicalReleaseRef=[string]$policy.initial_profile.release_ref
if($canonicalReleaseRef -cnotmatch '^refs/tags/modules-v0[.]1[.]0-r[1-9][0-9]*$'){
  Throw-P08R12Boundary 'P08-R12-POLICY' 'Clone-local policy does not select one canonical immutable release tag.'
}
$tagObject=((Invoke-P08R12BoundaryGit $clone @('rev-parse','--verify',$canonicalReleaseRef))-join '').Trim()
$peeled=((Invoke-P08R12BoundaryGit $clone @('rev-parse','--verify',"$canonicalReleaseRef^{}"))-join '').Trim()
$head=((Invoke-P08R12BoundaryGit $clone @('rev-parse','HEAD'))-join '').Trim()
if($tagObject -cne $ExpectedTagObject -or $peeled -cne $ExpectedPeeledSourceSha -or $head -cne $ExpectedPeeledSourceSha){
  Throw-P08R12Boundary 'P08-R12-TAG' 'Clone policy ref, fetched tag object, peel, and detached HEAD do not match the immutable tag identity.'
}

$hosted=Join-Path $clone 'scripts/quality/Invoke-Phase08HostedRun.ps1'
if(-not(Test-Path -LiteralPath $hosted -PathType Leaf)){Throw-P08R12Boundary 'P08-R12-HOSTED' 'Clone is missing the HostedRun entrypoint.'}
$boundary=& $hosted -Mode InitializeBoundary -Repository tchivs/moonbit-foundation -Workflow publish-modules.yml `
  -BoundarySha $head -ExecutionRoot $clone -StateRoot $StateRoot
$prepared=& $hosted -Mode PrepareAttempt -BoundaryLocatorPath ([string]$boundary.locator_path) -ReleaseRef $canonicalReleaseRef `
  -HistoricalReleaseRef $HistoricalReleaseRef -HistoricalSourceSha $HistoricalSourceSha -PrepareProvider $PrepareProvider

[pscustomobject][ordered]@{
  release_ref=$canonicalReleaseRef
  tag_object=$tagObject
  peeled_source_sha=$peeled
  head=$head
  boundary_sha=[string]$boundary.boundary_sha
  mutation_count=0
}
