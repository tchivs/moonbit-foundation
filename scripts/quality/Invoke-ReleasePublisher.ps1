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
    'repository','actor','actor_evidence','release_ref','source_sha','root_intent_sha256','intent_sha256','intent_kind','prepared_manifest_sha256',
    'historical_attempt_zero_sha256','historical_r1_sha256','historical_r2_sha256','historical_r3_sha256','historical_r4_sha256','historical_history_set_sha256',
    'correction_sequence','predecessor_intent_sha256','authorization_valid','evidence_valid','dry_run_passed','authority_account'
  )
  if ($Request.repository -cne 'tchivs/moonbit-foundation' -or $Request.actor -cne 'tchivs' -or $Request.authority_account -cne 'tchivs') { Throw-PublisherRule 'PUB12-AUTH' 'Actor, account, or repository binding is invalid.' }
  if ($Request.source_sha -cnotmatch '^[0-9a-f]{40}$' -or $Request.root_intent_sha256 -cnotmatch '^[0-9a-f]{64}$' -or $Request.intent_sha256 -cnotmatch '^[0-9a-f]{64}$') { Throw-PublisherRule 'PUB01-CLOSED' 'Request digest is invalid.' }
  if ($Request.prepared_manifest_sha256 -cnotmatch '^[0-9a-f]{64}$') { Throw-PublisherRule 'PUB13-EVIDENCE' 'Prepared manifest digest is invalid.' }
  $history=@([string]$Request.historical_attempt_zero_sha256,[string]$Request.historical_r1_sha256,[string]$Request.historical_r2_sha256,[string]$Request.historical_r3_sha256,[string]$Request.historical_r4_sha256)
  $expectedHistory=@(
    'b9bda5378ea339f4cdd42c417c1cc0cf8caabbd51ab11d453cd45ddae77d9b52',
    'cba047dae2e6b4e1bbf0248653ed7848f144971b54a0a4ed30ef42ab97325653',
    'aae8bee66e7dbfca7f3f22f1b52071e7888ae3ec8feee513d1c5d8eba6111609',
    'cf29473b2b07ff9aa8fd8a4810ddc45f6aacd2fd4b74048f5d29b3b6fa939d41',
    'd9b045bc65df87dc2701144ea7716defc67acb84ec9ea8e7ffdafd0118ba0906'
  )
  $historySet=([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes(($history -join "`n"))))).ToLowerInvariant()
  if (@($history | Where-Object { $_ -cnotmatch '^[0-9a-f]{64}$' }).Count -ne 0 -or (@($history | Select-Object -Unique)).Count -ne 5 -or
      ($history -join ',') -cne ($expectedHistory -join ',') -or $Request.historical_history_set_sha256 -cne $historySet -or
      $historySet -cne 'cdf78268b443dd3bc81026cbfda2a8a6a6ced3af6daeaa2351b658823649b2be') {
    Throw-PublisherRule 'PUB16-HISTORY' 'The exact five terminal-negative histories and their ordered set digest are required.'
  }
  $actorFields=@('expected_actor','observed_actor','actor_check_classification','actor_exit_code','actor_stdout_line_count','actor_stderr_empty','actor_match','actor_raw_output_persisted','credential_state_removed','mutation_performed','command_classification')
  try { Assert-PublisherClosedProperties 'actor evidence' $Request.actor_evidence $actorFields } catch { Throw-PublisherRule 'PUB12-ACTOR' $_.Exception.Message }
  $actor=$Request.actor_evidence
  if ($actor.expected_actor -cne 'tchivs' -or $actor.observed_actor -cne 'tchivs' -or
      $actor.actor_check_classification -cne 'moon_whoami_exact' -or [int]$actor.actor_exit_code -ne 0 -or
      [int]$actor.actor_stdout_line_count -ne 1 -or $actor.actor_stderr_empty -ne $true -or $actor.actor_match -ne $true -or
      $actor.actor_raw_output_persisted -ne $false -or $actor.credential_state_removed -ne $true -or
      $actor.mutation_performed -ne $false -or $actor.command_classification -cne 'moon_whoami_dry_run_only' -or
      [string]$actor.observed_actor -cmatch '(?i)(token|secret|password|cookie|authorization|bearer)|[\r\n]') {
    Throw-PublisherRule 'PUB12-ACTOR' 'Actor evidence is not the exact closed sanitized tchivs dry-run projection.'
  }
  if ($Request.authorization_valid -ne $true) { Throw-PublisherRule 'PUB12-AUTH' 'Fresh exact authorization is required.' }
  if ($Request.evidence_valid -ne $true -or $Request.dry_run_passed -ne $true) { Throw-PublisherRule 'PUB13-EVIDENCE' 'Qualification, archive, identity, or dry-run evidence failed.' }
  if ($Request.intent_kind -ceq 'initial') {
    if ($Request.release_ref -cne 'refs/tags/modules-v0.1.0-r5' -or $Request.source_sha -cin @('198436a45b7403a3c28c98d5fa0d5ed6a958455f','09548df948f58ec1bdfff7494757596c03e4c9bd','73a3af920fc3938f49e93d14f16f79f116475f1e','67b1fbc9dd62288d19018c46a44c1e3293212b76','ee4a8eb9b8dca5d69b404c9a4a1cd81608a5462a') -or $Request.root_intent_sha256 -cne $Request.intent_sha256 -or [int]$Request.correction_sequence -ne 0 -or $null -ne $Request.predecessor_intent_sha256) { Throw-PublisherRule 'PUB04-ROOT' 'Initial r5 request binding is invalid.' }
  }
}

function Assert-PublisherExactExistingCheckpoint {
  param([object]$Checkpoint,[object]$Request)
  Assert-PublisherRequest $Request | Out-Null
  Assert-PublisherClosedProperties 'exact-existing checkpoint' $Checkpoint @(
    'classification','repository','release_ref','source_sha','root_intent_sha256','intent_sha256','prepared_manifest_sha256',
    'observation_sha256','cold_proof_sha256','reducer_record_sha256','mutation_authorization_required',
    'mutation_authorization_used','publisher_dry_run_used','mutation_count','mutation_performed'
  )
  foreach($field in @('root_intent_sha256','intent_sha256','prepared_manifest_sha256','observation_sha256','cold_proof_sha256','reducer_record_sha256')) {
    if ([string]$Checkpoint.$field -cnotmatch '^[0-9a-f]{64}$') { Throw-PublisherRule 'PUB15-EXACT-EXISTING' "Checkpoint digest '$field' is invalid." }
  }
  if ($Checkpoint.classification -cne 'exact_existing_verified' -or $Checkpoint.repository -cne $Request.repository -or
      $Checkpoint.release_ref -cne $Request.release_ref -or $Checkpoint.source_sha -cne $Request.source_sha -or
      $Checkpoint.root_intent_sha256 -cne $Request.root_intent_sha256 -or $Checkpoint.intent_sha256 -cne $Request.intent_sha256 -or
      $Checkpoint.prepared_manifest_sha256 -cne $Request.prepared_manifest_sha256 -or
      $Checkpoint.mutation_authorization_required -ne $false -or $Checkpoint.mutation_authorization_used -ne $false -or
      $Checkpoint.publisher_dry_run_used -ne $false -or [int]$Checkpoint.mutation_count -ne 0 -or $Checkpoint.mutation_performed -ne $false) {
    Throw-PublisherRule 'PUB15-EXACT-EXISTING' 'Exact-existing checkpoint is drifted or mutation-authorized.'
  }
  return $true
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
      [int]$adapterOutcome.mutation_count -ne $(if($classification -eq 'not_eligible'){0}else{1}) -or $adapterOutcome.raw_output_persisted -ne $false -or
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
