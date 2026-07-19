[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

# Task 1 Step 2b — RED tests for the later-mode common path binding (lines 1042-1044) and
# the static r12->r13 source audit. Idiom mirrors Test-Phase08TagBoundHostedStore.ps1: a
# disposable --no-local --no-tags clone with the post-edit HostedRun staged and a clone-local
# r13 fixture tag.

function Throw-P08Binding([string]$Id,[string]$Message) { throw "$Id`: $Message" }

function Confirm-P08BindingFailure([string]$Id,[scriptblock]$Action) {
  $failure=$null
  try { & $Action } catch { $failure=$_.Exception.Message }
  if($null -eq $failure -or $failure -notmatch "^$([regex]::Escape($Id)):" ){Throw-P08Binding 'P08-BINDING-NEGATIVE' "Expected $Id, got '$failure'."}
  return $failure
}

function Confirm-P08BindingSuccess([scriptblock]$Action) {
  $failure=$null
  try { & $Action } catch { $failure=$_.Exception.Message }
  if($null -ne $failure){Throw-P08Binding 'P08-BINDING-POSITIVE' "Expected success, got '$failure'."}
}

$repoRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$hostedSourcePath=Join-Path $repoRoot 'scripts/quality/Invoke-Phase08HostedRun.ps1'
if(-not(Test-Path -LiteralPath $hostedSourcePath -PathType Leaf)){Throw-P08Binding 'P08-BINDING-HOSTED' 'Invoke-Phase08HostedRun.ps1 is missing.'}

# ---- Static-source audit (primary safety check). ----
# P08-HOSTED-R13-BINDING present (1), P08-HOSTED-R12-BINDING absent (0),
# 'Only the exact r13 release binding is accepted.' present, 'r12 release binding' absent.
# Pre-edit (RED): all four counts invert. Post-edit (GREEN): all four match.
$src=Get-Content -LiteralPath $hostedSourcePath -Raw
$r13BindingMatches=@([regex]::Matches($src,'P08-HOSTED-R13-BINDING'))
$r12BindingMatches=@([regex]::Matches($src,'P08-HOSTED-R12-BINDING'))
$r13MessageMatches=@([regex]::Matches($src,'Only the exact r13 release binding is accepted\.'))
$r12MessageMatches=@([regex]::Matches($src,'r12 release binding'))
if($r13BindingMatches.Count -ne 1 -or $r12BindingMatches.Count -ne 0 -or
   $r13MessageMatches.Count -ne 1 -or $r12MessageMatches.Count -ne 0){
  Throw-P08Binding 'P08-BINDING-STATIC' "Static audit failed: r13-binding=$($r13BindingMatches.Count) r12-binding=$($r12BindingMatches.Count) r13-msg=$($r13MessageMatches.Count) r12-msg=$($r12MessageMatches.Count)."
}

# ---- Runtime test: invoke HostedPreflight against a real boundary and assert the binding check. ----
# The binding check at line 1042 runs AFTER Open-P08BoundaryLocator (line 1032) and BEFORE
# Open-P08BoundaryStore (line 1046). We supply all nine laterBindings so line 1030's missing-
# bindings check passes; the boundary locator is real so Open-P08BoundaryLocator (line 1032)
# succeeds; then line 1042 either accepts r13 (post-edit) or rejects r12 (post-edit) /
# rejects r13 (pre-edit) based on the source under test. We do NOT use -LibraryOnly because
# that returns at line 1038 BEFORE the line 1042 binding check runs.

$root=Join-Path ([IO.Path]::GetTempPath()) ('mnf-phase08-r13-binding-'+[Guid]::NewGuid().ToString('N'))
$clone=Join-Path $root 'clone'
try {
  $null=New-Item -ItemType Directory -Path $root
  & git clone --quiet --no-local --no-tags $repoRoot $clone
  if($LASTEXITCODE -ne 0){Throw-P08Binding 'P08-BINDING-CLONE' 'Unable to create the disposable binding clone.'}
  & git -C $clone config user.name 'MNF r13 binding fixture'
  & git -C $clone config user.email 'r13-binding-fixture@moonbit-foundation.invalid'
  if($LASTEXITCODE -ne 0){Throw-P08Binding 'P08-BINDING-GIT' 'Unable to configure disposable clone identity.'}
  & git -C $clone remote set-url origin $clone
  if($LASTEXITCODE -ne 0){Throw-P08Binding 'P08-BINDING-GIT' 'Unable to reconfigure disposable clone origin.'}

  # Stage the post-edit HostedRun candidate.
  $cloneHostedPath=Join-Path $clone 'scripts/quality/Invoke-Phase08HostedRun.ps1'
  Copy-Item -LiteralPath $hostedSourcePath -Destination $cloneHostedPath -Force
  & git -C $clone add -- scripts/quality/Invoke-Phase08HostedRun.ps1
  $staged=@(& git -C $clone diff --cached --name-only)
  if($staged.Count -gt 0){
    & git -C $clone commit --quiet -m 'test: stage post-edit HostedRun binding candidate'
    if($LASTEXITCODE -ne 0){Throw-P08Binding 'P08-BINDING-CANDIDATE' 'Unable to commit the disposable HostedRun candidate.'}
  }

  # Synthesize a clone-local r13 fixture tag at HEAD; policy already selects r13 as current_attempt.
  $canonicalTag='modules-v0.1.0-r13'
  & git -C $clone tag -a $canonicalTag -m 'r13 binding fixture boundary' HEAD
  if($LASTEXITCODE -ne 0){Throw-P08Binding 'P08-BINDING-TAG' 'Unable to create the disposable clone-local r13 tag.'}
  $localObject=((& git -C $clone rev-parse "refs/tags/$canonicalTag")-join '').Trim()
  $localPeel=((& git -C $clone rev-parse "refs/tags/$canonicalTag^{}")-join '').Trim()
  if($localObject -cnotmatch '^[0-9a-f]{40}$' -or $localPeel -cnotmatch '^[0-9a-f]{40}$'){Throw-P08Binding 'P08-BINDING-TAG' 'Disposable r13 tag identity is malformed.'}
  # Detach at the peel so InitializeBoundary's Assert-P08ExecutionBoundary HEAD check passes.
  & git -C $clone checkout --quiet --detach $localPeel
  if($LASTEXITCODE -ne 0){Throw-P08Binding 'P08-BINDING-CHECKOUT' 'Unable to detach at the disposable r13 tag peel.'}

  # Initialize the boundary so Open-P08BoundaryLocator (line 1032) succeeds.
  $stateRoot=Join-Path $root 'state'
  $boundary=& $cloneHostedPath -Mode InitializeBoundary -Repository tchivs/moonbit-foundation -Workflow publish-modules.yml `
    -BoundarySha $localPeel -ExecutionRoot $clone -StateRoot $stateRoot

  # The laterBindings check at line 1030 requires non-empty LocatorPath and ArtifactRoot. These
  # do not have to point to real files because the binding check at line 1042 runs BEFORE
  # Open-P08BoundaryStore (line 1046) consumes them. Use sentinel non-empty strings; if the
  # binding check passes for the GREEN case, the call proceeds to Open-P08BoundaryStore which
  # will then throw P08-BOUNDARY-LOCATOR (the locator path doesn't exist) — still consistent
  # with GREEN (the binding itself accepted r13).
  $sentinelLocator=Join-Path $root 'sentinel-locator.json'
  $sentinelArtifacts=Join-Path $root 'sentinel-artifacts'

  # Case D — release_ref=r13. Post-edit: passes line 1042 binding check, then proceeds to
  # Open-P08BoundaryStore which throws P08-BOUNDARY-LOCATOR (the sentinel locator doesn't exist).
  # Pre-edit: throws P08-HOSTED-R12-BINDING at line 1042 because source expects r12.
  # Acceptable Case D outcomes: P08-HOSTED-R12-BINDING (RED pre-edit) OR P08-BOUNDARY-LOCATOR
  # (GREEN post-edit, binding accepted then store-open fails on sentinel path).
  $failureD=$null
  try {
    & $cloneHostedPath -Mode HostedPreflight `
      -BoundaryLocatorPath ([string]$boundary.locator_path) -LocatorPath $sentinelLocator -ArtifactRoot $sentinelArtifacts `
      -ReleaseRef "refs/tags/$canonicalTag" `
      -SourceSha $localPeel -BoundarySha $localPeel -Repository tchivs/moonbit-foundation `
      -Workflow publish-modules.yml -PreparedManifestSha256 ('1'*64) -RootIntentSha256 ('2'*64) -IntentSha256 ('3'*64) `
      -TargetModule mb-core | Out-Null
  } catch { $failureD=$_.Exception.Message }
  if($null -eq $failureD){Throw-P08Binding 'P08-BINDING-CASE-D' 'Case D unexpectedly completed; expected either P08-HOSTED-R12-BINDING (RED) or P08-BOUNDARY-LOCATOR (GREEN).'}
  if($failureD -cnotmatch '^(P08-HOSTED-R12-BINDING|P08-HOSTED-R13-BINDING|P08-BOUNDARY-LOCATOR):'){
    Throw-P08Binding 'P08-BINDING-CASE-D' "Unexpected Case D failure: $failureD"
  }
  # Post-edit, Case D must reach P08-BOUNDARY-LOCATOR (proves binding accepted r13).
  # Pre-edit, Case D throws P08-HOSTED-R12-BINDING (proves binding rejected r13).
  # The static-source audit above already pins which one applies to the source under test.

  # Case E — release_ref=r12. Post-edit: throws P08-HOSTED-R13-BINDING at line 1042 (binding rejects r12).
  # Pre-edit: passes line 1042 (binding accepts r12), then throws P08-BOUNDARY-LOCATOR.
  $r12Ref='refs/tags/modules-v0.1.0-r12'
  $failureE=$null
  try {
    & $cloneHostedPath -Mode HostedPreflight `
      -BoundaryLocatorPath ([string]$boundary.locator_path) -LocatorPath $sentinelLocator -ArtifactRoot $sentinelArtifacts `
      -ReleaseRef $r12Ref `
      -SourceSha $localPeel -BoundarySha $localPeel -Repository tchivs/moonbit-foundation `
      -Workflow publish-modules.yml -PreparedManifestSha256 ('1'*64) -RootIntentSha256 ('2'*64) -IntentSha256 ('3'*64) `
      -TargetModule mb-core | Out-Null
  } catch { $failureE=$_.Exception.Message }
  if($null -eq $failureE){Throw-P08Binding 'P08-BINDING-CASE-E' 'Case E unexpectedly completed; expected either P08-HOSTED-R13-BINDING (GREEN post-edit) or P08-BOUNDARY-LOCATOR (RED pre-edit).'}
  if($failureE -cnotmatch '^(P08-HOSTED-R12-BINDING|P08-HOSTED-R13-BINDING|P08-BOUNDARY-LOCATOR):'){
    Throw-P08Binding 'P08-BINDING-CASE-E' "Unexpected Case E failure: $failureE"
  }
  # Cross-check against the static audit: when the source is post-edit (1x R13-BINDING, 0x R12-BINDING),
  # Case E MUST throw P08-HOSTED-R13-BINDING (the binding now rejects stale r12).
  if($r13BindingMatches.Count -eq 1 -and $r12BindingMatches.Count -eq 0){
    if($failureE -cnotmatch '^P08-HOSTED-R13-BINDING:'){Throw-P08Binding 'P08-BINDING-CASE-E' "Post-edit Case E must throw P08-HOSTED-R13-BINDING; got '$failureE'."}
    if($failureD -cnotmatch '^P08-BOUNDARY-LOCATOR:'){Throw-P08Binding 'P08-BINDING-CASE-D' "Post-edit Case D must reach P08-BOUNDARY-LOCATOR (binding accepted r13); got '$failureD'."}
  }

  Write-Output 'PASS: Test-Phase08HostedBinding — static audit pins r13 binding; runtime Case D (r13 accepted) reaches store-open, Case E (r12 rejected by P08-HOSTED-R13-BINDING post-edit).'
} finally {
  if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}
}
