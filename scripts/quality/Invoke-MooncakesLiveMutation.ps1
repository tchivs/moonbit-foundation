[CmdletBinding()]
param(
  [string]$PreparedRoot,
  [string]$ToolchainRoot,
  [string]$JournalRoot,
  [string[]]$ProofPaths = @(),
  [string]$CredentialToken,
  [switch]$ExplicitLiveAuthorization,
  [scriptblock]$PublishCommand,
  [scriptblock]$PreparedValidator,
  [switch]$LibraryOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ReleasePublisher.Common.ps1')

function Throw-LiveRule {
  param([string]$Id,[string]$Message)
  throw "$Id`: $Message"
}

function Assert-LiveRequest {
  param([object]$Request)
  Assert-PublisherClosedProperties 'live request' $Request @(
    'repository','actor','actor_evidence','release_ref','source_sha','root_intent_sha256','intent_sha256','intent_kind','prepared_manifest_sha256',
    'historical_attempt_zero_sha256','historical_r1_sha256','historical_r2_sha256','historical_r3_sha256','historical_r4_sha256','historical_r5_sha256','historical_r6_sha256','historical_r7_sha256','historical_r8_sha256','historical_history_set_sha256',
    'correction_sequence','predecessor_intent_sha256','authorization_valid','evidence_valid','dry_run_passed','authority_account'
  )
  if ($Request.repository -cne 'tchivs/moonbit-foundation' -or $Request.actor -cne 'tchivs' -or
      $Request.authority_account -cne 'tchivs' -or $Request.authorization_valid -ne $true -or
      $Request.evidence_valid -ne $true -or $Request.dry_run_passed -ne $true) {
    Throw-LiveRule 'LIVE01-AUTHORIZATION' 'Exact actor, repository, authority, qualification, and dry-run authorization are required.'
  }
  $actor=$Request.actor_evidence
  $actorFields=@('expected_actor','observed_actor','actor_check_classification','actor_exit_code','actor_stdout_line_count','actor_stderr_empty','actor_match','actor_raw_output_persisted','credential_state_removed','mutation_performed','command_classification')
  try { Assert-PublisherClosedProperties 'live actor evidence' $actor $actorFields } catch { Throw-LiveRule 'LIVE01-AUTHORIZATION' $_.Exception.Message }
  if ($actor.expected_actor -cne 'tchivs' -or $actor.observed_actor -cne 'tchivs' -or $actor.actor_check_classification -cne 'moon_whoami_exact' -or
      [int]$actor.actor_exit_code -ne 0 -or [int]$actor.actor_stdout_line_count -ne 1 -or $actor.actor_stderr_empty -ne $true -or
      $actor.actor_match -ne $true -or $actor.actor_raw_output_persisted -ne $false -or $actor.credential_state_removed -ne $true -or
      $actor.mutation_performed -ne $false -or $actor.command_classification -cne 'moon_whoami_dry_run_only') {
    Throw-LiveRule 'LIVE01-AUTHORIZATION' 'Live actor evidence is not the exact sanitized dry-run projection.'
  }
  $history=@([string]$Request.historical_attempt_zero_sha256,[string]$Request.historical_r1_sha256,[string]$Request.historical_r2_sha256,[string]$Request.historical_r3_sha256,[string]$Request.historical_r4_sha256,[string]$Request.historical_r5_sha256,[string]$Request.historical_r6_sha256,[string]$Request.historical_r7_sha256,[string]$Request.historical_r8_sha256)
  $expectedHistory=@('b9bda5378ea339f4cdd42c417c1cc0cf8caabbd51ab11d453cd45ddae77d9b52','cba047dae2e6b4e1bbf0248653ed7848f144971b54a0a4ed30ef42ab97325653','aae8bee66e7dbfca7f3f22f1b52071e7888ae3ec8feee513d1c5d8eba6111609','cf29473b2b07ff9aa8fd8a4810ddc45f6aacd2fd4b74048f5d29b3b6fa939d41','d9b045bc65df87dc2701144ea7716defc67acb84ec9ea8e7ffdafd0118ba0906','1239b63f983bef86ac44c731171093ad67759de9cce7c15610b92f5df6214843','3f9c0d9916dbccfa9144488d2967ee1a7fb3fd1d9936f8cc4139c2734f2d0ad4','baf5d4921c75b2ba4a64cd234663a1b7086d6c45a653edd1ce4a63f56882933f','8a7729234a62425d0082a7b7a4615f2757ab4bc59938925b8ca031e2e00c10c8')
  $historySet=([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes(($history -join "`n"))))).ToLowerInvariant()
  if ($Request.release_ref -cne 'refs/tags/modules-v0.1.0-r9' -or $Request.source_sha -cnotmatch '^[0-9a-f]{40}$' -or
      $Request.source_sha -cin @('198436a45b7403a3c28c98d5fa0d5ed6a958455f','09548df948f58ec1bdfff7494757596c03e4c9bd','73a3af920fc3938f49e93d14f16f79f116475f1e','67b1fbc9dd62288d19018c46a44c1e3293212b76','ee4a8eb9b8dca5d69b404c9a4a1cd81608a5462a','df105f06205298f1f82ac2f2cdca214d69d42e15','c05cacbc3cfc583205c612f4bf293a4e251ec079','195e08dc1f3a1dc561d98cc660af679926ae0198') -or
      $Request.root_intent_sha256 -cnotmatch '^[0-9a-f]{64}$' -or $Request.intent_sha256 -cnotmatch '^[0-9a-f]{64}$' -or
      $Request.prepared_manifest_sha256 -cnotmatch '^[0-9a-f]{64}$' -or
      @($history | Where-Object { $_ -cnotmatch '^[0-9a-f]{64}$' }).Count -ne 0 -or (@($history | Select-Object -Unique)).Count -ne 9 -or
      ($history -join ',') -cne ($expectedHistory -join ',') -or $Request.historical_history_set_sha256 -cne $historySet -or
      $historySet -cne '39e45ed9aecf1788d106a043dd4b421243a577b66534d0748ca61937a0de86a8' -or
      $Request.intent_kind -cne 'initial' -or [int]$Request.correction_sequence -ne 0 -or
      $null -ne $Request.predecessor_intent_sha256 -or $Request.root_intent_sha256 -cne $Request.intent_sha256) {
    Throw-LiveRule 'LIVE02-BINDING' 'Only the exact qualified initial release binding is eligible.'
  }
}

function Assert-LiveReducerChain {
  param([object[]]$Records,[object]$Request)
  if ($Records.Count -eq 0) { return }
  $accepted = @()
  for ($i=0; $i -lt $Records.Count; $i++) {
    $record = $Records[$i]
    if ($record.root_intent_sha256 -cne $Request.root_intent_sha256 -or $record.intent_sha256 -cne $Request.intent_sha256) {
      Throw-LiveRule 'LIVE02-BINDING' 'Journal intent binding drifted.'
    }
    $command = [pscustomobject][ordered]@{
      journal_sequence=[int]$record.journal_sequence; prior_record_sha256=[string]$record.prior_record_sha256
      root_intent_sha256=[string]$record.root_intent_sha256; intent_sha256=[string]$record.intent_sha256
      intent_kind=[string]$record.intent_kind; correction_sequence=[int]$record.correction_sequence
      predecessor_intent_sha256=$record.predecessor_intent_sha256; state=[string]$record.state; module=$record.module
      operation=[string]$record.operation; observation=$record.observation; outcome=[string]$record.outcome
      recorded_at_utc=[string]$record.recorded_at_utc; run_identity=$record.run_identity
    }
    try { $decision = Resolve-PublisherTransition -Records $accepted -Command $command } catch {
      Throw-LiveRule 'LIVE03-JOURNAL' $_.Exception.Message
    }
    if ($decision.action -cne 'append' -or $decision.record.record_sha256 -cne $record.record_sha256) {
      Throw-LiveRule 'LIVE03-JOURNAL' 'Journal record is not the canonical reducer result.'
    }
    $accepted += $record
  }
}

function Assert-LiveProof {
  param([object]$Proof,[string]$ExpectedModule)
  $expected = @('schema_version','evidence_mode','policy_sha256','module','identity','version','dependency_source','isolation','observation','archive_sha256','downloaded_manifest_sha256','resolved_graph','toolchain','targets','behavior','verified','content_sha256')
  $actual = @($Proof.PSObject.Properties.Name)
  if ($actual.Count -ne $expected.Count -or ($actual -join ',') -cne ($expected -join ',')) {
    Throw-LiveRule 'LIVE04-INCOMPLETE-PROOF' 'Cold proof is missing, reordered, or extended.'
  }
  if ($Proof.schema_version -cne '1.0.0' -or $Proof.evidence_mode -cne 'live_registry' -or
      $Proof.module -cne $ExpectedModule -or $Proof.identity -cne "tchivs/$ExpectedModule" -or
      $Proof.version -cne '0.1.0' -or $Proof.dependency_source -cne 'registry_only' -or
      $Proof.verified -ne $true -or $Proof.content_sha256 -cnotmatch '^[0-9a-f]{64}$' -or
      $Proof.observation.outcome -cne 'exact' -or @($Proof.targets).Count -ne 4 -or
      @($Proof.targets | Where-Object { $_.check -cne 'pass' -or $_.test -cne 'pass' -or $_.runtime -cne 'pass' }).Count -ne 0 -or
      $Proof.behavior.result -cne 'pass') {
    Throw-LiveRule 'LIVE04-INCOMPLETE-PROOF' "Exact live four-target proof for '$ExpectedModule' is required."
  }
  $isolationNames=@('consumer_root_outside_checkout','moon_home_initially_empty','credentials_absent','workspace_absent','source_copy_absent','alternate_dependency_source_absent','local_dependency_absent','path_dependency_absent','git_dependency_absent','registry_cache_initially_empty','registry_index_cache_absent','archive_cache_absent','mooncakes_state_absent','target_output_initially_absent','pinned_toolchain_explicit','ambient_toolchain_ignored')
  if ((@($Proof.isolation.PSObject.Properties.Name) -join ',') -cne ($isolationNames -join ',') -or
      @($Proof.isolation.PSObject.Properties.Value | Where-Object { $_ -ne $true }).Count -ne 0) {
    Throw-LiveRule 'LIVE04-INCOMPLETE-PROOF' 'Cold proof isolation evidence is incomplete.'
  }
  if ((@($Proof.targets.name) -join ',') -cne 'js,wasm,wasm-gc,native' -or
      $Proof.observation.strongest_identity -cne "sha256:$($Proof.archive_sha256)" -or
      $Proof.behavior.output_sha256 -cne $Proof.targets[0].output_sha256 -or
      @($Proof.targets | Where-Object { $_.output_sha256 -cne $Proof.behavior.output_sha256 }).Count -ne 0) {
    Throw-LiveRule 'LIVE04-INCOMPLETE-PROOF' 'Cold proof graph target or artifact evidence is incomplete.'
  }
  $projection=[ordered]@{}
  foreach($property in $Proof.PSObject.Properties){ if($property.Name -cne 'content_sha256'){ $projection[$property.Name]=$property.Value } }
  $json=([pscustomobject]$projection | ConvertTo-Json -Depth 100 -Compress)
  $digest=([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.UTF8Encoding]::new($false).GetBytes($json)))).ToLowerInvariant()
  if ($Proof.content_sha256 -cne $digest) { Throw-LiveRule 'LIVE04-INCOMPLETE-PROOF' 'Cold proof content digest is invalid.' }
}

function Resolve-MooncakesLiveMutationTarget {
  param([object]$Request,[object[]]$Records=@(),[object[]]$Proofs=@())
  Assert-LiveRequest $Request
  Assert-LiveReducerChain -Records $Records -Request $Request
  $modules = @($Proofs | ForEach-Object { [string]$_.module })
  if (@($modules | Sort-Object -Unique).Count -ne $modules.Count) { Throw-LiveRule 'LIVE05-AMBIGUOUS' 'Duplicate exact proofs are ambiguous.' }
  if ($Records.Count -eq 0) {
    if ($Proofs.Count -ne 0) { Throw-LiveRule 'LIVE05-AMBIGUOUS' 'Genesis cannot carry predecessor proofs.' }
    return 'mb-core'
  }
  $last = $Records[-1]
  switch ([string]$last.state) {
    'core_checkpoint_verified' {
      if ($Proofs.Count -ne 1) { Throw-LiveRule 'LIVE04-INCOMPLETE-PROOF' 'Core proof is required before color.' }
      Assert-LiveProof $Proofs[0] 'mb-core'
      return 'mb-color'
    }
    'color_checkpoint_verified' {
      if ($Proofs.Count -ne 2 -or $modules[0] -cne 'mb-core' -or $modules[1] -cne 'mb-color') { Throw-LiveRule 'LIVE04-INCOMPLETE-PROOF' 'Ordered core and color proofs are required before image.' }
      Assert-LiveProof $Proofs[0] 'mb-core'; Assert-LiveProof $Proofs[1] 'mb-color'
      return 'mb-image'
    }
    'image_checkpoint_verified' { return $null }
    'handoff_ready' { return $null }
    default { return $null }
  }
}

function Invoke-LiveProcess {
  param([string]$FilePath,[string[]]$Arguments,[string]$WorkingDirectory,[hashtable]$Environment)
  $start=[Diagnostics.ProcessStartInfo]::new(); $start.FileName=$FilePath; $start.WorkingDirectory=$WorkingDirectory
  $start.UseShellExecute=$false; $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true; $start.Environment.Clear()
  foreach($entry in $Environment.GetEnumerator()){ $start.Environment[$entry.Key]=[string]$entry.Value }
  foreach($argument in $Arguments){ $null=$start.ArgumentList.Add($argument) }
  $process=[Diagnostics.Process]::new(); $process.StartInfo=$start; $null=$process.Start()
  $stdout=$process.StandardOutput.ReadToEnd(); $stderr=$process.StandardError.ReadToEnd(); $process.WaitForExit()
  [pscustomobject]@{ exit_code=$process.ExitCode; stdout=$stdout; stderr=$stderr }
}

function Invoke-PreparedLiveValidation {
  param([string]$Root,[object]$Request,[scriptblock]$Validator)
  $manifestPath=Join-Path $Root 'prepared-bundle.json'
  if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { Throw-LiveRule 'LIVE06-PREPARED' 'Prepared manifest is missing.' }
  $manifest=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -Depth 100
  $manifestDigest=(Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($null -ne $Validator) { & $Validator $Root $manifest $Request | Out-Null } else {
    $validatorPath=Join-Path $Root 'scripts/quality/New-PreparedReleaseBundle.ps1'
    if (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) { Throw-LiveRule 'LIVE06-PREPARED' 'Bundled prepared validator is missing.' }
    $args=@{
      ValidateOnly=$true; OutputRoot=$Root; Repository=[string]$manifest.repository; Actor=[string]$manifest.actor
      RunId=[string]$manifest.run_id; RunAttempt=[int]$manifest.run_attempt; ReleaseRef=[string]$manifest.release_ref
      SourceSha=[string]$manifest.source_sha; RootIntentSha256=[string]$manifest.root_intent_sha256
      IntentSha256=[string]$manifest.intent_sha256; RunMode=[string]$manifest.run_mode
      HistoricalAttemptZeroSha256=[string]$Request.historical_attempt_zero_sha256
      HistoricalR1Sha256=[string]$Request.historical_r1_sha256
      HistoricalR2Sha256=[string]$Request.historical_r2_sha256
      HistoricalR3Sha256=[string]$Request.historical_r3_sha256
      HistoricalR4Sha256=[string]$Request.historical_r4_sha256
      HistoricalR5Sha256=[string]$Request.historical_r5_sha256
      HistoricalR6Sha256=[string]$Request.historical_r6_sha256
      HistoricalR7Sha256=[string]$Request.historical_r7_sha256
      HistoricalR8Sha256=[string]$Request.historical_r8_sha256
      HistoricalHistorySetSha256=[string]$Request.historical_history_set_sha256
    }
    if ($manifest.run_mode -ceq 'resume') {
      $args.PriorRunId=[string]$manifest.journal_binding.prior_run_id
      $args.PriorArtifactName=[string]$manifest.journal_binding.prior_artifact_name
      $args.PriorTerminalRecordSha256=[string]$manifest.journal_binding.terminal_record_sha256
    }
    & $validatorPath @args | Out-Null
  }
  if ($manifest.repository -cne $Request.repository -or $manifest.actor -cne $Request.actor -or
      $manifest.release_ref -cne $Request.release_ref -or $manifest.source_sha -cne $Request.source_sha -or
      $manifest.root_intent_sha256 -cne $Request.root_intent_sha256 -or $manifest.intent_sha256 -cne $Request.intent_sha256 -or
      $manifest.historical_attempt_zero_sha256 -cne $Request.historical_attempt_zero_sha256 -or
      $manifest.historical_r1_sha256 -cne $Request.historical_r1_sha256 -or
      $manifest.historical_r2_sha256 -cne $Request.historical_r2_sha256 -or
      $manifest.historical_r3_sha256 -cne $Request.historical_r3_sha256 -or
      $manifest.historical_r4_sha256 -cne $Request.historical_r4_sha256 -or
      $manifest.historical_r5_sha256 -cne $Request.historical_r5_sha256 -or
      $manifest.historical_r6_sha256 -cne $Request.historical_r6_sha256 -or
      $manifest.historical_r7_sha256 -cne $Request.historical_r7_sha256 -or
      $manifest.historical_r8_sha256 -cne $Request.historical_r8_sha256 -or
      $manifest.historical_history_set_sha256 -cne $Request.historical_history_set_sha256 -or
      $manifestDigest -cne $Request.prepared_manifest_sha256) {
    Throw-LiveRule 'LIVE06-PREPARED' 'Prepared manifest and authorized request disagree.'
  }
  return $manifest
}

function Invoke-MooncakesLiveMutation {
  param(
    [object]$Request,[object[]]$Records=@(),[object[]]$Proofs=@(),[string]$PreparedRoot,[string]$ToolchainRoot,
    [string]$CredentialToken,[bool]$Authorized,[scriptblock]$PublishCommand,[scriptblock]$PreparedValidator
  )
  if (-not $Authorized) { Throw-LiveRule 'LIVE01-AUTHORIZATION' 'Explicit live authorization is required.' }
  $target=Resolve-MooncakesLiveMutationTarget -Request $Request -Records $Records -Proofs $Proofs
  if ($null -eq $target) { return [pscustomobject][ordered]@{ classification='not_eligible'; module=$null; mutation_count=0; reobservation_required=$false; raw_output_persisted=$false; credential_state_removed=$true } }
  $manifest=Invoke-PreparedLiveValidation -Root $PreparedRoot -Request $Request -Validator $PreparedValidator
  if ([string]::IsNullOrWhiteSpace($CredentialToken)) { Throw-LiveRule 'LIVE07-CREDENTIAL' 'The step-scoped credential is unavailable.' }
  $archiveRelative="archives/$target.zip"
  $archiveRecords=@($manifest.payloads | Where-Object { $_.path -ceq $archiveRelative -and $_.role -ceq 'exact_source_archive' })
  if ($archiveRecords.Count -ne 1) { Throw-LiveRule 'LIVE06-PREPARED' "Exact prepared archive for '$target' is missing or ambiguous." }
  $archivePath=Join-Path $PreparedRoot $archiveRelative
  $toolchain=[IO.Path]::GetFullPath($ToolchainRoot)
  $moonExe=Join-Path $toolchain 'bin/moon'
  if ($IsWindows) { $moonExe += '.exe' }
  if ($null -eq $PublishCommand -and -not (Test-Path -LiteralPath $moonExe -PathType Leaf)) { Throw-LiveRule 'LIVE08-TOOLCHAIN' 'Pinned moon executable is missing.' }
  $moonHome=Join-Path ([IO.Path]::GetTempPath()) ('mnf-live-publisher-' + [Guid]::NewGuid().ToString('N'))
  $sourceRoot=Join-Path $moonHome 'source'; $credentialPath=Join-Path $moonHome ('credentials' + '.json')
  $classification='unknown'; $callCount=0
  try {
    $null=New-Item -ItemType Directory -Path $moonHome
    [IO.File]::WriteAllText($credentialPath,(([pscustomobject][ordered]@{ username='tchivs'; token=$CredentialToken } | ConvertTo-Json -Compress)),[Text.UTF8Encoding]::new($false))
    Expand-Archive -LiteralPath $archivePath -DestinationPath $sourceRoot
    $environment=@{ MOON_HOME=$moonHome; MOON_TOOLCHAIN_ROOT=$toolchain; PATH=(Join-Path $toolchain 'bin'); TEMP=[IO.Path]::GetTempPath(); TMP=[IO.Path]::GetTempPath() }
    foreach($name in @('SystemRoot','WINDIR','COMSPEC','PATHEXT')){ $value=[Environment]::GetEnvironmentVariable($name); if(-not [string]::IsNullOrWhiteSpace($value)){ $environment[$name]=$value } }
    $arguments=@('-C',$sourceRoot,'publish','--frozen')
    $callCount++
    if ($callCount -ne 1) { Throw-LiveRule 'LIVE09-ONE-CALL' 'More than one mutation call was attempted.' }
    if ($null -ne $PublishCommand) {
      $classification=[string](& $PublishCommand ([pscustomobject][ordered]@{ file=$moonExe; arguments=$arguments; working_directory=$sourceRoot; environment=$environment; moon_home=$moonHome; credential_path=$credentialPath; module=$target }))
    } else {
      $result=Invoke-LiveProcess -FilePath $moonExe -Arguments $arguments -WorkingDirectory $sourceRoot -Environment $environment
      $classification=if($result.exit_code -eq 0){'attempted'}else{'nonzero'}
    }
    if ($classification -notin @('attempted','timeout','nonzero')) { Throw-LiveRule 'LIVE10-SANITIZE' 'Publish adapter returned a non-allowlisted classification.' }
  } finally {
    if (Test-Path -LiteralPath $moonHome) { Remove-Item -LiteralPath $moonHome -Recurse -Force }
  }
  if (Test-Path -LiteralPath $moonHome) { Throw-LiveRule 'LIVE11-TEARDOWN' 'Ephemeral publisher home survived.' }
  [pscustomobject][ordered]@{ classification=$classification; module=$target; mutation_count=$callCount; reobservation_required=$true; raw_output_persisted=$false; credential_state_removed=$true }
}

function Read-LiveJournalRecords {
  param([string]$Root)
  if ([string]::IsNullOrWhiteSpace($Root) -or -not (Test-Path -LiteralPath $Root)) { return @() }
  $records=@(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter '*.json' | ForEach-Object {
    try { $value=Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json -Depth 100 } catch { return }
    if ($value.schema_version -ceq 'mnf-release-journal-record/1') { $value }
  } | Sort-Object journal_sequence)
  return $records
}

if ($LibraryOnly) { return }
if ([string]::IsNullOrWhiteSpace($PreparedRoot) -or [string]::IsNullOrWhiteSpace($ToolchainRoot)) { Throw-LiveRule 'LIVE06-PREPARED' 'Prepared and pinned toolchain roots are required.' }
$request=Get-Content -LiteralPath (Join-Path $PreparedRoot 'request.json') -Raw | ConvertFrom-Json -Depth 100
$records=Read-LiveJournalRecords $JournalRoot
$proofs=@($ProofPaths | ForEach-Object { Get-Content -LiteralPath $_ -Raw | ConvertFrom-Json -Depth 100 })
Invoke-MooncakesLiveMutation -Request $request -Records $records -Proofs $proofs -PreparedRoot $PreparedRoot -ToolchainRoot $ToolchainRoot -CredentialToken $CredentialToken -Authorized ([bool]$ExplicitLiveAuthorization) -PublishCommand $PublishCommand -PreparedValidator $PreparedValidator
