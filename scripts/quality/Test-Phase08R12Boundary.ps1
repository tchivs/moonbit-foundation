[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Throw-P08R12Boundary([string]$Id,[string]$Message) { throw "$Id`: $Message" }
function Invoke-P08R12Git([string]$Root,[string[]]$Arguments) {
  $output=@(& git -C $Root @Arguments 2>&1)
  if($LASTEXITCODE -ne 0){Throw-P08R12Boundary 'P08-R12-GIT' "git $($Arguments -join ' ') failed."}
  $output
}
function Confirm-P08R12Failure([string]$Id,[scriptblock]$Action) {
  $failure=$null
  try { & $Action } catch { $failure=$_.Exception.Message }
  if($failure -notmatch "^$([regex]::Escape($Id)):" ){Throw-P08R12Boundary 'P08-R12-NEGATIVE' "Expected $Id, got '$failure'."}
}

$repoRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$wrapper=Join-Path $PSScriptRoot 'Invoke-Phase08R12Boundary.ps1'
if(-not(Test-Path -LiteralPath $wrapper -PathType Leaf)){Throw-P08R12Boundary 'P08-R12-WRAPPER' 'The canonical clone-policy boundary wrapper is missing.'}
$wrapperSource=Get-Content -LiteralPath $wrapper -Raw
if($wrapperSource -cmatch '(?im)^\s*\[string\]\$ReleaseRef\b' -or $wrapperSource -cmatch '(?im)\bReleaseRef\s*='){
  Throw-P08R12Boundary 'P08-R12-OVERRIDE' 'The r12 wrapper must not expose a caller-controlled ReleaseRef.'
}
foreach($required in @('policy/release-control.json','InitializeBoundary','PrepareAttempt','tag_object','peeled_source_sha','boundary_sha','mutation_count=0')){
  if($wrapperSource.IndexOf($required,[StringComparison]::Ordinal)-lt 0){Throw-P08R12Boundary 'P08-R12-WRAPPER' "Wrapper is missing '$required'."}
}

$root=Join-Path ([IO.Path]::GetTempPath()) ('mnf-phase08-r12-boundary-'+[Guid]::NewGuid().ToString('N'))
$clone=Join-Path $root 'clone'
try {
  $null=New-Item -ItemType Directory -Path $root
  & git clone --quiet --no-local --no-tags $repoRoot $clone
  if($LASTEXITCODE -ne 0){Throw-P08R12Boundary 'P08-R12-CLONE' 'Unable to create the disposable boundary clone.'}
  & git -C $clone config user.name 'MNF r12 boundary fixture'
  & git -C $clone config user.email 'r12-boundary-fixture@moonbit-foundation.invalid'
  if($LASTEXITCODE -ne 0){Throw-P08R12Boundary 'P08-R12-GIT' 'Unable to configure the disposable clone identity.'}
  $policy=Get-Content -LiteralPath (Join-Path $clone 'policy/release-control.json') -Raw|ConvertFrom-Json -Depth 100
  $canonicalRef=[string]$policy.initial_profile.release_ref
  $tagName=$canonicalRef.Substring('refs/tags/'.Length)
  & git -C $clone tag -a $tagName -m 'r12 wrapper fixture boundary' HEAD
  if($LASTEXITCODE -ne 0){Throw-P08R12Boundary 'P08-R12-TAG' 'Unable to create the disposable clone-local policy tag.'}
  $tagObject=((Invoke-P08R12Git $clone @('rev-parse',$canonicalRef))-join '').Trim()
  $peeled=((Invoke-P08R12Git $clone @('rev-parse',"$canonicalRef^{}"))-join '').Trim()
  $probe=[pscustomobject]@{calls=0;release_ref='';execution_root='';control_policy_path=''}
  $provider={
    param($Context)
    $probe.calls++
    $probe.release_ref=[string]$Context.release_ref
    $probe.execution_root=[string]$Context.execution_root
    $probe.control_policy_path=[string]$Context.control_policy_path
    throw 'P08-R12-PROVIDER: canonical policy ref reached provider.'
  }.GetNewClosure()
  $state=Join-Path $root 'canonical-state'
  Confirm-P08R12Failure 'P08-R12-PROVIDER' {
    & $wrapper -CloneRoot $clone -StateRoot $state -ExpectedTagObject $tagObject -ExpectedPeeledSourceSha $peeled `
      -HistoricalReleaseRef refs/tags/modules-v0.1.0-r11 -HistoricalSourceSha 30479a2546e0fc6416a9a26b10e39ed1f686c860 -PrepareProvider $provider
  }
  if($probe.calls -ne 1 -or $probe.release_ref -cne $canonicalRef -or $probe.execution_root -cne [IO.Path]::GetFullPath($clone) -or
      $probe.control_policy_path -cne (Join-Path ([IO.Path]::GetFullPath($clone)) 'policy/release-control.json')){
    Throw-P08R12Boundary 'P08-R12-POSITIVE' 'Wrapper did not derive and pass the clone-policy canonical ref exactly once.'
  }

  $rejectedState=Join-Path $root 'rejected-state'
  $before=$probe.calls
  Confirm-P08R12Failure 'P08-R12-TAG' {
    & $wrapper -CloneRoot $clone -StateRoot $rejectedState -ExpectedTagObject ('0'*40) -ExpectedPeeledSourceSha $peeled `
      -HistoricalReleaseRef refs/tags/modules-v0.1.0-r11 -HistoricalSourceSha 30479a2546e0fc6416a9a26b10e39ed1f686c860 -PrepareProvider $provider
  }
  if($probe.calls -ne $before -or (Test-Path -LiteralPath $rejectedState)){
    Throw-P08R12Boundary 'P08-R12-NEGATIVE' 'A tag-identity mismatch reached provider or created boundary state.'
  }
  Write-Output 'PASS: r12 boundary derives the clone-local canonical ref and rejects mismatched tag identity before state/provider work.'
} finally {
  if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}
}
