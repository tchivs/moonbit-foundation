[CmdletBinding()]
param(
  [ValidateSet('Rehearsal','Preflight','LiveOneStep')][string]$Mode = 'Rehearsal',
  [ValidateSet('timeout','nonzero','partial_success','existing_exact','existing_mismatch','absent','unknown','invalid_credential','evidence_failure','cancelled')][string]$Scenario = 'absent',
  [string]$RequestPath,
  [string]$PreparedRoot,
  [string]$ToolchainRoot,
  [string]$JournalRoot,
  [string[]]$ProofPaths = @(),
  [switch]$ExplicitLiveAuthorization,
  [scriptblock]$LiveMutationAdapter,
  [switch]$LibraryOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ReleasePublisher.Common.ps1')
$liveAdapterPath = Join-Path $PSScriptRoot 'Invoke-MooncakesLiveMutation.ps1'

function Assert-PublisherRequest {
  param([object]$Request)
  Assert-PublisherClosedProperties 'publisher request' $Request @(
    'repository','actor','release_ref','source_sha','root_intent_sha256','intent_sha256','intent_kind',
    'correction_sequence','predecessor_intent_sha256','authorization_valid','evidence_valid','dry_run_passed','authority_account'
  )
  if ($Request.repository -cne 'tchivs/moonbit-foundation' -or $Request.actor -cne 'tchivs' -or $Request.authority_account -cne 'tchivs') { Throw-PublisherRule 'PUB12-AUTH' 'Actor, account, or repository binding is invalid.' }
  if ($Request.source_sha -cnotmatch '^[0-9a-f]{40}$' -or $Request.root_intent_sha256 -cnotmatch '^[0-9a-f]{64}$' -or $Request.intent_sha256 -cnotmatch '^[0-9a-f]{64}$') { Throw-PublisherRule 'PUB01-CLOSED' 'Request digest is invalid.' }
  if ($Request.authorization_valid -ne $true) { Throw-PublisherRule 'PUB12-AUTH' 'Fresh exact authorization is required.' }
  if ($Request.evidence_valid -ne $true -or $Request.dry_run_passed -ne $true) { Throw-PublisherRule 'PUB13-EVIDENCE' 'Qualification, archive, identity, or dry-run evidence failed.' }
  if ($Request.intent_kind -ceq 'initial') {
    if ($Request.release_ref -cne 'refs/tags/modules-v0.1.0' -or $Request.root_intent_sha256 -cne $Request.intent_sha256 -or [int]$Request.correction_sequence -ne 0 -or $null -ne $Request.predecessor_intent_sha256) { Throw-PublisherRule 'PUB04-ROOT' 'Initial request binding is invalid.' }
  }
}

function Assert-PublisherCorrectionRequest {
  param([object]$Request,[string]$LatestIntentSha256,[int]$LatestCorrectionSequence,[string]$ExpectedRoot=$Request.root_intent_sha256)
  Assert-PublisherRequest $Request
  if ($Request.intent_kind -cne 'forward_correction' -or $Request.release_ref -cnotmatch '^refs/tags/modules-correction-[1-9][0-9]*$') { Throw-PublisherRule 'PUB11-CORRECTION-SEQUENCE' 'Correction profile is invalid.' }
  if ($Request.root_intent_sha256 -cne $ExpectedRoot) { Throw-PublisherRule 'PUB04-ROOT' 'Correction changed the canonical initial root.' }
  if ($Request.predecessor_intent_sha256 -cne $LatestIntentSha256) { Throw-PublisherRule 'PUB10-STALE-FORK' 'Correction names a stale or forked predecessor.' }
  if ([int]$Request.correction_sequence -ne ($LatestCorrectionSequence+1)) { Throw-PublisherRule 'PUB11-CORRECTION-SEQUENCE' 'Correction sequence is not predecessor plus one.' }
  if ($Request.intent_sha256 -ceq $LatestIntentSha256 -or $Request.intent_sha256 -ceq $Request.root_intent_sha256) { Throw-PublisherRule 'PUB05-INTENT' 'Correction did not advance current intent.' }
  return $true
}

function Invoke-PublisherRehearsal {
  param([object]$Request,[string]$Scenario)
  if ($Scenario -eq 'invalid_credential') {
    return [pscustomobject]@{ scenario=$Scenario; reobserved=$false; disposition='authentication_rejected'; mutation_count=0; credentials_read=$false; network_performed=$false; destructive_recovery_available=$false }
  }
  if ($Scenario -eq 'evidence_failure') {
    return [pscustomobject]@{ scenario=$Scenario; reobserved=$false; disposition='evidence_rejected'; mutation_count=0; credentials_read=$false; network_performed=$false; destructive_recovery_available=$false }
  }
  Assert-PublisherRequest $Request
  $map=@{
    timeout=@('fresh_authorization_required',$true)
    nonzero=@('fresh_authorization_required',$true)
    partial_success=@('checkpoint_verified',$true)
    existing_exact=@('idempotent_checkpoint',$true)
    existing_mismatch=@('incident_opened',$true)
    absent=@('fresh_authorization_required',$true)
    unknown=@('unknown_stopped',$true)
    cancelled=@('unknown_stopped',$true)
  }
  if (-not $map.ContainsKey($Scenario)) { Throw-PublisherRule 'PUB08-SANITIZE' 'Unknown rehearsal scenario.' }
  [pscustomobject]@{
    scenario=$Scenario; reobserved=[bool]$map[$Scenario][1]; disposition=[string]$map[$Scenario][0]
    mutation_count=0; credentials_read=$false; network_performed=$false; destructive_recovery_available=$false
    lock_identity=(Get-PublisherLockIdentity -Repository $Request.repository -RootIntentSha256 $Request.root_intent_sha256)
  }
}

function Invoke-PublisherCorrectionRaceRehearsal {
  param([Alias('First')][object]$CorrectionA,[Alias('Second')][object]$CorrectionB)
  $root=[string]$CorrectionA.root_intent_sha256
  $null=Assert-PublisherCorrectionRequest -Request $CorrectionA -LatestIntentSha256 ([string]$CorrectionA.predecessor_intent_sha256) -LatestCorrectionSequence (([int]$CorrectionA.correction_sequence) - 1) -ExpectedRoot $root
  $firstLock=Get-PublisherLockIdentity $CorrectionA.repository $root
  $secondLock=Get-PublisherLockIdentity $CorrectionB.repository $CorrectionB.root_intent_sha256
  $second='accepted'
  try { $null=Assert-PublisherCorrectionRequest -Request $CorrectionB -LatestIntentSha256 $CorrectionA.intent_sha256 -LatestCorrectionSequence $CorrectionA.correction_sequence -ExpectedRoot $root } catch {
    if (-not $_.Exception.Message.StartsWith('PUB10-STALE-FORK: ',[StringComparison]::Ordinal)) { throw }
    $second='stale_fork'
  }
  [pscustomobject]@{ first='accepted'; second=$second; first_lock=$firstLock; second_lock=$secondLock; mutation_count=0; reobserved=$true }
}

function Invoke-PublisherLiveOneStep {
  param([object]$Request,[scriptblock]$Adapter,[bool]$Authorized)
  Assert-PublisherRequest $Request
  if (-not $Authorized -or $null -eq $Adapter) { Throw-PublisherRule 'PUB14-LIVE-GUARD' 'LiveOneStep requires explicit authorization and an injected one-step adapter.' }
  $adapterOutcome=& $Adapter $Request
  $classification=if($adapterOutcome -is [string]){[string]$adapterOutcome}else{[string]$adapterOutcome.classification}
  if ($classification -notin @('attempted','timeout','nonzero','not_eligible')) { Throw-PublisherRule 'PUB08-SANITIZE' 'Live adapter returned an unsupported classification.' }
  if ($adapterOutcome -isnot [string] -and (
      [int]$adapterOutcome.mutation_count -gt 1 -or $adapterOutcome.raw_output_persisted -ne $false -or
      $adapterOutcome.credential_state_removed -ne $true)) {
    Throw-PublisherRule 'PUB08-SANITIZE' 'Live adapter did not preserve the one-call sanitized boundary.'
  }
  $attempted=$classification -in @('attempted','timeout','nonzero')
  return [pscustomobject][ordered]@{
    classification=$classification; module=if($adapterOutcome -is [string]){$null}else{$adapterOutcome.module}
    mutation_attempted=$attempted; mutation_count=if($attempted){1}else{0}
    reobservation_required=$attempted; raw_output_persisted=$false; credential_state_removed=$true
  }
}

if ($LibraryOnly) { return }
if ([string]::IsNullOrWhiteSpace($RequestPath) -or -not (Test-Path -LiteralPath $RequestPath -PathType Leaf)) { Throw-PublisherRule 'PUB01-CLOSED' 'A closed request JSON file is required.' }
$request=Get-Content -LiteralPath $RequestPath -Raw | ConvertFrom-Json -Depth 30
switch ($Mode) {
  'Rehearsal' { Invoke-PublisherRehearsal -Request $request -Scenario $Scenario }
  'Preflight' { Assert-PublisherRequest $request; [pscustomobject]@{ status='preflight_passed'; credentials_read=$false; mutation_performed=$false } }
  'LiveOneStep' {
    if ($null -eq $LiveMutationAdapter) {
      if (-not (Test-Path -LiteralPath $liveAdapterPath -PathType Leaf)) { Throw-PublisherRule 'PUB14-LIVE-GUARD' 'Tracked live adapter is missing.' }
      if ([string]::IsNullOrWhiteSpace($PreparedRoot) -or [string]::IsNullOrWhiteSpace($ToolchainRoot)) { Throw-PublisherRule 'PUB14-LIVE-GUARD' 'Prepared and pinned toolchain roots are required.' }
      . $liveAdapterPath -LibraryOnly
      $records=Read-LiveJournalRecords $JournalRoot
      $proofs=@($ProofPaths | ForEach-Object { Get-Content -LiteralPath $_ -Raw | ConvertFrom-Json -Depth 100 })
      $token=[Environment]::GetEnvironmentVariable(('MOONCAKES' + '_TOKEN'))
      $LiveMutationAdapter={
        param($liveRequest)
        Invoke-MooncakesLiveMutation -Request $liveRequest -Records $records -Proofs $proofs -PreparedRoot $PreparedRoot -ToolchainRoot $ToolchainRoot -CredentialToken $token -Authorized ([bool]$ExplicitLiveAuthorization)
      }.GetNewClosure()
    }
    Invoke-PublisherLiveOneStep -Request $request -Adapter $LiveMutationAdapter -Authorized ([bool]$ExplicitLiveAuthorization)
  }
}
