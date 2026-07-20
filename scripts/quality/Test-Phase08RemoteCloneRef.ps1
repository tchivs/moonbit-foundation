[CmdletBinding()]
param(
  [string]$Remote='https://github.com/tchivs/moonbit-foundation.git',
  [ValidatePattern('^refs/tags/modules-v0[.]1[.]0-r[1-9][0-9]*$')][string]$ReleaseRef='refs/tags/modules-v0.1.0-r11',
  [ValidatePattern('^[0-9a-f]{40}$')][string]$ExpectedTagObject='735ad67910dca97a95cfc1d4e94f6b003bcc3f30',
  [ValidatePattern('^[0-9a-f]{40}$')][string]$ExpectedPeeledSourceSha='30479a2546e0fc6416a9a26b10e39ed1f686c860',
  [string]$HistoricalReleaseRef='refs/tags/modules-v0.1.0-r10',
  [ValidatePattern('^[0-9a-f]{40}$')][string]$HistoricalSourceSha='d49edc53fb4ffca375e562a23789fb76bf8c41e2'
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Throw-P08RemoteCloneRef([string]$Id,[string]$Message) { throw "$Id`: $Message" }
function Invoke-P08RemoteCloneGit([string]$Root,[string[]]$Arguments) {
  $output=@(& git -C $Root @Arguments 2>&1)
  if($LASTEXITCODE -ne 0){Throw-P08RemoteCloneRef 'P08-REMOTE-CLONE-GIT' "git $($Arguments -join ' ') failed."}
  $output
}

$root=Join-Path ([IO.Path]::GetTempPath()) ('mnf-phase08-remote-clone-ref-'+[Guid]::NewGuid().ToString('N'))
$clone=Join-Path $root 'source'
try {
  $null=New-Item -ItemType Directory -Path $root
  & git clone --quiet --no-local --no-tags $Remote $clone
  if($LASTEXITCODE -ne 0){Throw-P08RemoteCloneRef 'P08-REMOTE-CLONE' 'Unable to create the disposable no-local/no-tags clone.'}
  & git -C $clone fetch --quiet --no-tags origin "$ReleaseRef`:$ReleaseRef"
  if($LASTEXITCODE -ne 0){Throw-P08RemoteCloneRef 'P08-REMOTE-FETCH' 'Unable to fetch the policy-selected immutable tag.'}

  $tagObject=((Invoke-P08RemoteCloneGit $clone @('rev-parse',$ReleaseRef))-join '').Trim()
  $peeled=((Invoke-P08RemoteCloneGit $clone @('rev-parse',"$ReleaseRef^{}"))-join '').Trim()
  if($tagObject -cne $ExpectedTagObject -or $peeled -cne $ExpectedPeeledSourceSha){
    Throw-P08RemoteCloneRef 'P08-REMOTE-TAG' 'Fetched tag object or peeled source differs from the immutable expected identity.'
  }
  & git -C $clone checkout --quiet --detach $peeled
  if($LASTEXITCODE -ne 0){Throw-P08RemoteCloneRef 'P08-REMOTE-CHECKOUT' 'Unable to check out the fetched tag peel.'}
  $head=((Invoke-P08RemoteCloneGit $clone @('rev-parse','HEAD'))-join '').Trim()
  if($head -cne $ExpectedPeeledSourceSha){Throw-P08RemoteCloneRef 'P08-REMOTE-HEAD' 'Detached clone HEAD differs from the fetched tag peel.'}

  $policyPath=Join-Path $clone 'policy/release-control.json'
  $policy=Get-Content -LiteralPath $policyPath -Raw|ConvertFrom-Json -Depth 100
  $policyRef=[string]$policy.initial_profile.release_ref
  if($policyRef -cne $ReleaseRef){Throw-P08RemoteCloneRef 'P08-REMOTE-POLICY' 'Clone-local policy did not select the fetched immutable tag.'}
  $hosted=Join-Path $clone 'scripts/quality/Invoke-Phase08HostedRun.ps1'
  if(-not(Test-Path -LiteralPath $hosted -PathType Leaf)){Throw-P08RemoteCloneRef 'P08-REMOTE-HOSTED' 'Fetched clone is missing the HostedRun entrypoint.'}

  $providerProbe=[pscustomobject]@{ calls=0 }
  $provider={
    param($Context)
    $providerProbe.calls++
    if([string]$Context.execution_root -cne $clone -or [string]$Context.control_policy_path -cne $policyPath -or [string]$Context.release_ref -cne $policyRef){
      Throw-P08RemoteCloneRef 'P08-REMOTE-CONTEXT' 'PrepareAttempt did not pass clone-local policy and canonical ref to its provider.'
    }
    throw 'P08-REMOTE-CLONE-PROVIDER: canonical clone-local ref gate passed.'
  }.GetNewClosure()

  $state=Join-Path $root 'canonical-state'
  $boundary=& $hosted -Mode InitializeBoundary -Repository tchivs/moonbit-foundation -Workflow publish-modules.yml `
    -BoundarySha $head -ExecutionRoot $clone -StateRoot $state
  if([string]$boundary.boundary_sha -cne $head){Throw-P08RemoteCloneRef 'P08-REMOTE-BOUNDARY' 'InitializeBoundary SHA differs from the detached clone HEAD.'}
  $failure=$null
  try {
    & $hosted -Mode PrepareAttempt -BoundaryLocatorPath ([string]$boundary.locator_path) -ReleaseRef $policyRef `
      -HistoricalReleaseRef $HistoricalReleaseRef -HistoricalSourceSha $HistoricalSourceSha -PrepareProvider $provider | Out-Null
  } catch { $failure=$_.Exception.Message }
  if($failure -notmatch '^P08-REMOTE-CLONE-PROVIDER:' -or $providerProbe.calls -ne 1){
    Throw-P08RemoteCloneRef 'P08-REMOTE-POSITIVE' "Canonical policy ref did not cross PrepareAttempt's clone-local gate: $failure"
  }

  $negativeState=Join-Path $root 'noncanonical-state'
  $negativeBoundary=& $hosted -Mode InitializeBoundary -Repository tchivs/moonbit-foundation -Workflow publish-modules.yml `
    -BoundarySha $head -ExecutionRoot $clone -StateRoot $negativeState
  $before=$providerProbe.calls;$negativeFailure=$null
  try {
    & $hosted -Mode PrepareAttempt -BoundaryLocatorPath ([string]$negativeBoundary.locator_path) -ReleaseRef "$policyRef^{}" `
      -HistoricalReleaseRef $HistoricalReleaseRef -HistoricalSourceSha $HistoricalSourceSha -PrepareProvider $provider | Out-Null
  } catch { $negativeFailure=$_.Exception.Message }
  if($negativeFailure -notmatch '^P08-PREPARE-REF:' -or $providerProbe.calls -ne $before -or (Test-Path -LiteralPath (Join-Path $negativeState 'phase-08-live-locator.json'))){
    Throw-P08RemoteCloneRef 'P08-REMOTE-NEGATIVE' "A noncanonical ReleaseRef crossed the clone-local gate: $negativeFailure"
  }

  [pscustomobject][ordered]@{
    release_ref=$policyRef;tag_object=$tagObject;peeled_source_sha=$peeled;head=$head;boundary_sha=[string]$boundary.boundary_sha
    provider_calls=$providerProbe.calls;mutation_count=0
  } | ConvertTo-Json -Compress
} finally {
  if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}
}
