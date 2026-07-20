[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Throw-P08R13Boundary([string]$Id,[string]$Message) { throw "$Id`: $Message" }
function Invoke-P08R13Git([string]$Root,[string[]]$Arguments) {
  $output=@(& git -C $Root @Arguments 2>&1)
  if($LASTEXITCODE -ne 0){Throw-P08R13Boundary 'P08-R13-GIT' "git $($Arguments -join ' ') failed."}
  $output
}
function Confirm-P08R13Failure([string]$Id,[scriptblock]$Action) {
  $failure=$null
  try { & $Action } catch { $failure=$_.Exception.Message }
  if($failure -notmatch "^$([regex]::Escape($Id)):" ){Throw-P08R13Boundary 'P08-R13-NEGATIVE' "Expected $Id, got '$failure'."}
}

$repoRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$wrapper=Join-Path $PSScriptRoot 'Invoke-Phase08R13Boundary.ps1'
if(-not(Test-Path -LiteralPath $wrapper -PathType Leaf)){Throw-P08R13Boundary 'P08-R13-WRAPPER' 'The canonical clone-policy boundary wrapper is missing.'}
$wrapperSource=Get-Content -LiteralPath $wrapper -Raw
if($wrapperSource -cmatch '(?im)^\s*\[string\]\$ReleaseRef\b' -or $wrapperSource -cmatch '(?im)\bReleaseRef\s*='){
  Throw-P08R13Boundary 'P08-R13-OVERRIDE' 'The r13 wrapper must not expose a caller-controlled ReleaseRef.'
}
foreach($required in @('policy/release-control.json','InitializeBoundary','PrepareAttempt','tag_object','peeled_source_sha','boundary_sha','mutation_count=0')){
  if($wrapperSource.IndexOf($required,[StringComparison]::Ordinal)-lt 0){Throw-P08R13Boundary 'P08-R13-WRAPPER' "Wrapper is missing '$required'."}
}

$root=Join-Path ([IO.Path]::GetTempPath()) ('mnf-phase08-r13-boundary-'+[Guid]::NewGuid().ToString('N'))
$clone=Join-Path $root 'clone'
try {
  $null=New-Item -ItemType Directory -Path $root
  & git clone --quiet --no-local --no-tags $repoRoot $clone
  if($LASTEXITCODE -ne 0){Throw-P08R13Boundary 'P08-R13-CLONE' 'Unable to create the disposable boundary clone.'}
  & git -C $clone config user.name 'MNF r13 boundary fixture'
  & git -C $clone config user.email 'r13-boundary-fixture@moonbit-foundation.invalid'
  if($LASTEXITCODE -ne 0){Throw-P08R13Boundary 'P08-R13-GIT' 'Unable to configure the disposable clone identity.'}
  # Re-point origin at the clone itself so PrepareAttempt's clone-policy ref fetch
  # (Assert-P08PrepareCloneRefBeforeBoundary) resolves the fixture-local r13 tag.
  # The wrapper still derives the canonical ref from clone-local policy and rejects
  # any tag-identity mismatch before the fetch is reached.
  & git -C $clone remote set-url origin $clone
  if($LASTEXITCODE -ne 0){Throw-P08R13Boundary 'P08-R13-GIT' 'Unable to reconfigure disposable clone origin.'}
  $policy=Get-Content -LiteralPath (Join-Path $clone 'policy/release-control.json') -Raw|ConvertFrom-Json -Depth 100
  $canonicalRef=[string]$policy.initial_profile.release_ref
  $tagName=$canonicalRef.Substring('refs/tags/'.Length)
  & git -C $clone tag -a $tagName -m 'r13 wrapper fixture boundary' HEAD
  if($LASTEXITCODE -ne 0){Throw-P08R13Boundary 'P08-R13-TAG' 'Unable to create the disposable clone-local policy tag.'}
  $tagObject=((Invoke-P08R13Git $clone @('rev-parse',$canonicalRef))-join '').Trim()
  $peeled=((Invoke-P08R13Git $clone @('rev-parse',"$canonicalRef^{}"))-join '').Trim()
  $probe=[pscustomobject]@{calls=0;release_ref='';execution_root='';control_policy_path=''}
  $provider={
    param($Context)
    $probe.calls++
    $probe.release_ref=[string]$Context.release_ref
    $probe.execution_root=[string]$Context.execution_root
    $probe.control_policy_path=[string]$Context.control_policy_path
    throw 'P08-R13-PROVIDER: canonical policy ref reached provider.'
  }.GetNewClosure()
  $state=Join-Path $root 'canonical-state'
  Confirm-P08R13Failure 'P08-R13-PROVIDER' {
    & $wrapper -CloneRoot $clone -StateRoot $state -ExpectedTagObject $tagObject -ExpectedPeeledSourceSha $peeled `
      -HistoricalReleaseRef refs/tags/modules-v0.1.0-r12 -HistoricalSourceSha 5e7b19cdc74ec11d5c524ff34a36c266b15bba39 -PrepareProvider $provider
  }
  if($probe.calls -ne 1 -or $probe.release_ref -cne $canonicalRef -or $probe.execution_root -cne [IO.Path]::GetFullPath($clone) -or
      $probe.control_policy_path -cne (Join-Path ([IO.Path]::GetFullPath($clone)) 'policy/release-control.json')){
    Throw-P08R13Boundary 'P08-R13-POSITIVE' 'Wrapper did not derive and pass the clone-policy canonical ref exactly once.'
  }

  $rejectedState=Join-Path $root 'rejected-state'
  $before=$probe.calls
  Confirm-P08R13Failure 'P08-R13-TAG' {
    & $wrapper -CloneRoot $clone -StateRoot $rejectedState -ExpectedTagObject ('0'*40) -ExpectedPeeledSourceSha $peeled `
      -HistoricalReleaseRef refs/tags/modules-v0.1.0-r12 -HistoricalSourceSha 5e7b19cdc74ec11d5c524ff34a36c266b15bba39 -PrepareProvider $provider
  }
  if($probe.calls -ne $before -or (Test-Path -LiteralPath $rejectedState)){
    Throw-P08R13Boundary 'P08-R13-NEGATIVE' 'A tag-identity mismatch reached provider or created boundary state.'
  }
  Write-Output 'PASS: r13 boundary derives the clone-local canonical ref and rejects mismatched tag identity before state/provider work.'
} finally {
  if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}
}
