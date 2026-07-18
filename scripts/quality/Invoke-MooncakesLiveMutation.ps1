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
    'repository','actor','release_ref','source_sha','root_intent_sha256','intent_sha256','intent_kind',
    'correction_sequence','predecessor_intent_sha256','authorization_valid','evidence_valid','dry_run_passed','authority_account'
  )
  if ($Request.repository -cne 'tchivs/moonbit-foundation' -or $Request.actor -cne 'tchivs' -or
      $Request.authority_account -cne 'tchivs' -or $Request.authorization_valid -ne $true -or
      $Request.evidence_valid -ne $true -or $Request.dry_run_passed -ne $true) {
    Throw-LiveRule 'LIVE01-AUTHORIZATION' 'Exact actor, repository, authority, qualification, and dry-run authorization are required.'
  }
  if ($Request.release_ref -cne 'refs/tags/modules-v0.1.0' -or $Request.source_sha -cnotmatch '^[0-9a-f]{40}$' -or
      $Request.root_intent_sha256 -cnotmatch '^[0-9a-f]{64}$' -or $Request.intent_sha256 -cnotmatch '^[0-9a-f]{64}$' -or
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
  if ($null -ne $Validator) { & $Validator $Root $manifest $Request | Out-Null; return $manifest }
  $validatorPath=Join-Path $Root 'scripts/quality/New-PreparedReleaseBundle.ps1'
  if (-not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) { Throw-LiveRule 'LIVE06-PREPARED' 'Bundled prepared validator is missing.' }
  $args=@{
    ValidateOnly=$true; OutputRoot=$Root; Repository=[string]$manifest.repository; Actor=[string]$manifest.actor
    RunId=[string]$manifest.run_id; RunAttempt=[int]$manifest.run_attempt; ReleaseRef=[string]$manifest.release_ref
    SourceSha=[string]$manifest.source_sha; RootIntentSha256=[string]$manifest.root_intent_sha256
    IntentSha256=[string]$manifest.intent_sha256; RunMode=[string]$manifest.run_mode
  }
  if ($manifest.run_mode -ceq 'resume') {
    $args.PriorRunId=[string]$manifest.journal_binding.prior_run_id
    $args.PriorArtifactName=[string]$manifest.journal_binding.prior_artifact_name
    $args.PriorTerminalRecordSha256=[string]$manifest.journal_binding.terminal_record_sha256
  }
  & $validatorPath @args | Out-Null
  if ($manifest.repository -cne $Request.repository -or $manifest.actor -cne $Request.actor -or
      $manifest.release_ref -cne $Request.release_ref -or $manifest.source_sha -cne $Request.source_sha -or
      $manifest.root_intent_sha256 -cne $Request.root_intent_sha256 -or $manifest.intent_sha256 -cne $Request.intent_sha256) {
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
  if ([string]::IsNullOrWhiteSpace($CredentialToken)) { Throw-LiveRule 'LIVE07-CREDENTIAL' 'The step-scoped credential is unavailable.' }
  $target=Resolve-MooncakesLiveMutationTarget -Request $Request -Records $Records -Proofs $Proofs
  if ($null -eq $target) { return [pscustomobject][ordered]@{ classification='not_eligible'; module=$null; mutation_count=0; reobservation_required=$false; raw_output_persisted=$false; credential_state_removed=$true } }
  $manifest=Invoke-PreparedLiveValidation -Root $PreparedRoot -Request $Request -Validator $PreparedValidator
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
