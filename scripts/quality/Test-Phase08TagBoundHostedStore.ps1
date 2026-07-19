[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Throw-P08TagBoundStore([string]$Id,[string]$Message) { throw "$Id`: $Message" }
function Get-P08TagBoundDigest([object]$Value) {
  $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($Value|ConvertTo-Json -Depth 100 -Compress))
  ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))).ToLowerInvariant()
}
function Write-P08TagBoundJson([string]$Path,[object]$Value) {
  $null=New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path)
  [IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 100 -Compress),[Text.UTF8Encoding]::new($false))
}
function New-P08TagBoundStore([string]$Root,[string]$StateRoot,[string]$ReleaseRef,[string]$BoundarySha,[string]$RootIntent,[string]$Intent,[string]$Prepared) {
  $artifactRoot=Join-Path $StateRoot ('artifacts-'+($ReleaseRef.Split('-')[-1]))
  $indexPath=Join-Path $artifactRoot 'index.json'
  Write-P08TagBoundJson $indexPath ([pscustomobject][ordered]@{schema_version='mnf-phase08-artifact-index/2';boundary_sha=$BoundarySha;prepared_manifest_sha256=$Prepared;records=@()})
  $locator=[pscustomobject][ordered]@{
    schema_version='mnf-phase08-live-locator/2';repository='tchivs/moonbit-foundation';workflow='publish-modules.yml';release_ref=$ReleaseRef
    boundary_sha=$BoundarySha;execution_root=[IO.Path]::GetFullPath($Root);source_sha=$BoundarySha;root_intent_sha256=$RootIntent;intent_sha256=$Intent
    prepared_manifest_sha256=$Prepared;artifact_root=[IO.Path]::GetFullPath($artifactRoot);index_path=[IO.Path]::GetFullPath($indexPath)
    mutation_authorization_packet_path=$null;mutation_authorization_packet_sha256=$null;created_at_utc='2026-07-19T00:00:00Z';locator_sha256=''
  }
  $projection=[ordered]@{}
  foreach($property in $locator.PSObject.Properties){if($property.Name -cne 'locator_sha256'){$projection[$property.Name]=$property.Value}}
  $locator.locator_sha256=Get-P08TagBoundDigest ([pscustomobject]$projection)
  $locatorPath=Join-Path $StateRoot ('store-'+($ReleaseRef.Split('-')[-1])+'.json')
  Write-P08TagBoundJson $locatorPath $locator
  [pscustomobject]@{locator_path=[IO.Path]::GetFullPath($locatorPath);artifact_root=[IO.Path]::GetFullPath($artifactRoot)}
}

$repoRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$hostedSource=Join-Path $repoRoot 'scripts/quality/Invoke-Phase08HostedRun.ps1'
$root=Join-Path ([IO.Path]::GetTempPath()) ('mnf-phase08-tag-bound-store-'+[Guid]::NewGuid().ToString('N'))
$clone=Join-Path $root 'clone'
try {
  $null=New-Item -ItemType Directory -Path $root
  & git clone --quiet --no-local --no-tags $repoRoot $clone
  if($LASTEXITCODE -ne 0){Throw-P08TagBoundStore 'P08-TAGBOUND-CLONE' 'Unable to create disposable no-local/no-tags clone.'}
  & git -C $clone config user.name 'MNF tag-bound store fixture'
  & git -C $clone config user.email 'tag-bound-store@moonbit-foundation.invalid'
  if($LASTEXITCODE -ne 0){Throw-P08TagBoundStore 'P08-TAGBOUND-GIT' 'Unable to configure disposable clone identity.'}
  Copy-Item -LiteralPath $hostedSource -Destination (Join-Path $clone 'scripts/quality/Invoke-Phase08HostedRun.ps1') -Force
  & git -C $clone add -- scripts/quality/Invoke-Phase08HostedRun.ps1
  & git -C $clone commit --quiet -m 'test: stage tag-bound HostedRun candidate'
  if($LASTEXITCODE -ne 0){Throw-P08TagBoundStore 'P08-TAGBOUND-CANDIDATE' 'Unable to commit the disposable HostedRun candidate source.'}

  $policy=Get-Content -LiteralPath (Join-Path $clone 'policy/release-control.json') -Raw|ConvertFrom-Json -Depth 100
  $fixtureReleaseRef=[string]$policy.initial_profile.release_ref
  if($fixtureReleaseRef -cne 'refs/tags/modules-v0.1.0-r12'){Throw-P08TagBoundStore 'P08-TAGBOUND-POLICY' 'Fixture policy must select r12.'}
  $tagName=$fixtureReleaseRef.Substring('refs/tags/'.Length)
  & git -C $clone tag -a $tagName -m 'disposable tag-bound hosted-store fixture' HEAD
  if($LASTEXITCODE -ne 0){Throw-P08TagBoundStore 'P08-TAGBOUND-TAG' 'Unable to create disposable r12 tag.'}
  $tagObject=(@(& git -C $clone rev-parse --verify $fixtureReleaseRef)-join '').Trim()
  $fixtureBoundarySha=(@(& git -C $clone rev-parse --verify "$fixtureReleaseRef^{}")-join '').Trim()
  & git -C $clone checkout --quiet --detach $fixtureBoundarySha
  if($LASTEXITCODE -ne 0){Throw-P08TagBoundStore 'P08-TAGBOUND-CHECKOUT' 'Unable to detach at the disposable r12 tag peel.'}
  if((@(& git -C $clone rev-parse HEAD)-join '').Trim() -cne $fixtureBoundarySha -or $tagObject -cnotmatch '^[0-9a-f]{40}$'){
    Throw-P08TagBoundStore 'P08-TAGBOUND-IDENTITY' 'Disposable tag object, peel, and detached HEAD disagree.'
  }

  $hosted=Join-Path $clone 'scripts/quality/Invoke-Phase08HostedRun.ps1'
  $fixtureStateRoot=Join-Path $root 'state'
  $boundary=& $hosted -Mode InitializeBoundary -Repository tchivs/moonbit-foundation -Workflow publish-modules.yml -BoundarySha $fixtureBoundarySha -ExecutionRoot $clone -StateRoot $fixtureStateRoot
  $rootIntent='1'*64;$intent='2'*64;$prepared='3'*64
  $store=New-P08TagBoundStore -Root $clone -StateRoot $fixtureStateRoot -ReleaseRef $fixtureReleaseRef -BoundarySha $fixtureBoundarySha -RootIntent $rootIntent -Intent $intent -Prepared $prepared
  $dispatchProbe=[pscustomobject]@{calls=0}
  $gh={param([string[]]$Arguments)$dispatchProbe.calls++;throw 'P08-TAGBOUND-DISPATCH: store opened before dispatch.'}.GetNewClosure()
  foreach($mode in @('HostedPreflight','PublisherDryRun')){
    $failure=$null
    try {
      & $hosted -Mode $mode -BoundaryLocatorPath ([string]$boundary.locator_path) -LocatorPath ([string]$store.locator_path) -ArtifactRoot ([string]$store.artifact_root) `
        -ReleaseRef $fixtureReleaseRef -SourceSha $fixtureBoundarySha -RootIntentSha256 $rootIntent -IntentSha256 $intent -PreparedManifestSha256 $prepared -TargetModule mb-core -GhCommand $gh | Out-Null
    } catch { $failure=$_.Exception.Message }
    if($failure -notmatch '^P08-TAGBOUND-DISPATCH:') {Throw-P08TagBoundStore 'P08-TAGBOUND-RUNTIME' "$mode did not open the tag-bound store before dispatch: $failure"}
  }
  if($dispatchProbe.calls -ne 2){Throw-P08TagBoundStore 'P08-TAGBOUND-RUNTIME' 'Each later mode must reach only its dispatch sentinel.'}

  # A future r13 pre-tag migration must not need to edit Open-P08BoundaryStore again.
  $futureRef='refs/tags/modules-v0.1.0-r13'
  & git -C $clone tag -a ($futureRef.Substring('refs/tags/'.Length)) -m 'disposable r13 pre-tag store fixture' $fixtureBoundarySha
  if($LASTEXITCODE -ne 0){Throw-P08TagBoundStore 'P08-TAGBOUND-R13-TAG' 'Unable to create disposable r13 pre-tag reference.'}
  . $hosted -Mode HostedPreflight -LibraryOnly
  $Repository='tchivs/moonbit-foundation';$Workflow='publish-modules.yml';$SourceSha=$fixtureBoundarySha;$BoundarySha=$fixtureBoundarySha
  $RootIntentSha256=$rootIntent;$IntentSha256=$intent;$PreparedManifestSha256=$prepared
  $futureStore=New-P08TagBoundStore -Root $clone -StateRoot $fixtureStateRoot -ReleaseRef $futureRef -BoundarySha $fixtureBoundarySha -RootIntent $rootIntent -Intent $intent -Prepared $prepared
  $null=Open-P08BoundaryStore -Locator ([string]$futureStore.locator_path) -Artifacts ([string]$futureStore.artifact_root) -Operation HostedPreflight -ReleaseRef $futureRef

  $source=Get-Content -LiteralPath $hostedSource -Raw
  $openBody=[regex]::Match($source,'(?s)function Open-P08BoundaryStore\s*\{.*?\r?\n\}\r?\n\r?\nfunction Add-P08SanitizedArtifact').Value
  if([string]::IsNullOrWhiteSpace($openBody) -or $openBody -notmatch '\[string\]\$ReleaseRef' -or $openBody -match 'refs/tags/modules-v0[.]1[.]0-r(?:10|11|12)'){
    Throw-P08TagBoundStore 'P08-TAGBOUND-STATIC' 'Open-P08BoundaryStore must bind the caller release ref and contain no historical or current fixed release-tag literal.'
  }
  if($source -notmatch '\$store=Open-P08BoundaryStore\s+-Locator\s+\$LocatorPath\s+-Artifacts\s+\$ArtifactRoot\s+-Operation\s+\$Mode\s+-ReleaseRef\s+\$ReleaseRef'){
    Throw-P08TagBoundStore 'P08-TAGBOUND-STATIC' 'Later-mode HostedRun must pass its release ref into Open-P08BoundaryStore.'
  }
  Write-Output 'PASS: detached tag-bound HostedPreflight/PublisherDryRun open r12 store before the dispatch sentinel; direct r13 pre-tag store simulation remains release-ref generic.'
} finally {
  if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}
}
