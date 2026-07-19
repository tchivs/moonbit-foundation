[CmdletBinding()]
param(
  [switch]$ContractOnly,
  [switch]$Focused,
  [switch]$QualificationIntegration
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$policyPath = Join-Path $repoRoot 'policy\release-control.json'
$schemaPath = Join-Path $repoRoot 'release\intent\schema.json'
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')

function Read-IntentJson {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "REL01-MISSING-CONTRACT: $Path" }
  try { return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100 } catch { throw "REL01-INVALID-JSON: $Path" }
}

function Get-IntentHistoryRecordSha256 {
  param([Parameter(Mandatory)][object]$Record)
  $projection = [ordered]@{}
  foreach ($name in @($Record.PSObject.Properties.Name | Where-Object { $_ -cne 'record_sha256' })) { $projection[$name] = $Record.$name }
  return Get-ReleaseTextSha256 -Text ($projection | ConvertTo-Json -Depth 30 -Compress)
}

function Get-IntentHistorySetSha256 {
  param([Parameter(Mandatory)][object[]]$History)
  return Get-ReleaseTextSha256 -Text ((@($History.record_sha256) -join "`n"))
}

function Assert-Phase08AttemptSchemas {
  $policy = Read-IntentJson -Path $policyPath
  $history = @($policy.initial_attempt_family.terminal_negative_history)
  if ($history.Count -ne 9 -or ($history.attempt -join ',') -cne 'attempt_zero,r1,r2,r3,r4,r5,r6,r7,r8') {
    throw 'REL04-HISTORY-ORDER: authority requires attempt-zero through r8 in canonical order.'
  }
  $historyFields = [ordered]@{
    historical_attempt_zero_sha256 = [string]$history[0].record_sha256
    historical_r1_sha256 = [string]$history[1].record_sha256
    historical_r2_sha256 = [string]$history[2].record_sha256
    historical_r3_sha256 = [string]$history[3].record_sha256
    historical_r4_sha256 = [string]$history[4].record_sha256
    historical_r5_sha256 = [string]$history[5].record_sha256
    historical_r6_sha256 = [string]$history[6].record_sha256
    historical_r7_sha256 = [string]$history[7].record_sha256
    historical_r8_sha256 = [string]$history[8].record_sha256
    historical_history_set_sha256 = [string]$policy.initial_attempt_family.history_set_sha256
  }
  $authority = Read-IntentJson -Path (Join-Path $repoRoot 'release\qualification\phase-08-authority-schema.json')
  $receipt = Read-IntentJson -Path (Join-Path $repoRoot 'release\qualification\phase-08-authorization-receipt-schema.json')
  $handoff = Read-IntentJson -Path (Join-Path $repoRoot 'release\qualification\phase-08-handoff-schema.json')
  foreach ($branch in @('mutationAuthorizationPacket','exactExistingAuthority','moduleAuthority')) {
    $schemaBranch = $authority.'$defs'.$branch
    if ($schemaBranch.properties.release_ref.const -cne 'refs/tags/modules-v0.1.0-r9') {
      throw "REL04-AUTHORITY-REF: $branch does not require r9."
    }
    foreach ($entry in $historyFields.GetEnumerator()) {
      if (@($schemaBranch.required) -cnotcontains $entry.Key -or $schemaBranch.properties.($entry.Key).const -cne $entry.Value) {
        throw "REL04-AUTHORITY-HISTORY: $branch does not bind $($entry.Key)."
      }
    }
  }
  $receiptFields = @('schema_version','release_ref','boundary_sha','source_sha','packet_sha256','historical_attempt_zero_sha256','historical_r1_sha256','historical_r2_sha256','historical_r3_sha256','historical_r4_sha256','historical_r5_sha256','historical_r6_sha256','historical_r7_sha256','historical_r8_sha256','historical_history_set_sha256','response','created_at_utc','receipt_sha256')
  if ($receipt.type -cne 'object' -or $receipt.additionalProperties -ne $false -or
      (@($receipt.required) -join ',') -cne ($receiptFields -join ',') -or
       $receipt.properties.release_ref.const -cne 'refs/tags/modules-v0.1.0-r9' -or
      $receipt.properties.response.const -cne 'authorize-core' -or
      $receipt.properties.created_at_utc.pattern -cne '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$') {
    throw 'REL04-RECEIPT-SCHEMA: authorization receipt is not the exact closed r9 contract.'
  }
  foreach ($entry in $historyFields.GetEnumerator()) {
    if ($receipt.properties.($entry.Key).const -cne $entry.Value) { throw "REL04-RECEIPT-HISTORY: receipt does not bind $($entry.Key)." }
  }
  if (@($handoff.oneOf).Count -ne 2) { throw 'REL04-HANDOFF-SCHEMA: handoff must expose two exclusive branches.' }
  $mutation = $handoff.'$defs'.mutationHandoff; $exact = $handoff.'$defs'.exactExistingHandoff
  foreach ($branch in @($mutation,$exact)) {
    if ($branch.type -cne 'object' -or $branch.additionalProperties -ne $false -or
      $branch.properties.release_ref.const -cne 'refs/tags/modules-v0.1.0-r9' -or
        $branch.properties.created_at_utc.'$ref' -cne '#/$defs/utc' -or
        $handoff.'$defs'.utc.pattern -cne '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$') {
      throw 'REL04-HANDOFF-SCHEMA: handoff branch is not closed, r9-bound, and UTC-canonical.'
    }
    foreach ($entry in ([ordered]@{
      attempt_zero_history_sha256=$historyFields.historical_attempt_zero_sha256
      r1_history_sha256=$historyFields.historical_r1_sha256
      r2_history_sha256=$historyFields.historical_r2_sha256
      r3_history_sha256=$historyFields.historical_r3_sha256
      r4_history_sha256=$historyFields.historical_r4_sha256
      r5_history_sha256=$historyFields.historical_r5_sha256
      r6_history_sha256=$historyFields.historical_r6_sha256
      r7_history_sha256=$historyFields.historical_r7_sha256
      r8_history_sha256=$historyFields.historical_r8_sha256
      historical_history_set_sha256=$historyFields.historical_history_set_sha256
    }).GetEnumerator()) {
      if (@($branch.required) -cnotcontains $entry.Key -or $branch.properties.($entry.Key).const -cne $entry.Value) { throw "REL04-HANDOFF-HISTORY: handoff branch does not bind $($entry.Key)." }
    }
    foreach ($field in @('r2_history_path','r2_history_sha256','r3_history_path','r3_history_sha256','r4_history_path','r4_history_sha256','r5_history_path','r5_history_sha256','r6_history_path','r6_history_sha256','r7_history_path','r7_history_sha256','r8_history_path','r8_history_sha256')) {
      if (@($branch.required) -cnotcontains $field) { throw "REL04-HANDOFF-HISTORY: handoff branch omits $field." }
    }
  }
  foreach ($field in @('mutation_authorization_packet_path','mutation_authorization_packet_sha256','authorization_receipt_path','authorization_receipt_sha256')) {
    if (@($mutation.required) -cnotcontains $field -or $mutation.properties.$field.'$ref' -eq $null -and $mutation.properties.$field.type -eq $null) {
      throw "REL04-HANDOFF-MUTATION: mutation handoff is missing $field."
    }
    if ($exact.properties.$field.type -cne 'null') { throw "REL04-HANDOFF-EXACT: exact-existing does not forbid $field." }
  }
  if (@($exact.required) -cnotcontains 'exact_existing_authority_path' -or $mutation.properties.exact_existing_authority_path.type -cne 'null') {
    throw 'REL04-HANDOFF-BRANCH: exact-existing authority path is not exclusive.'
  }
  if (@($mutation.required) -ccontains 'stop' -or @($exact.required) -ccontains 'stop') { throw 'REL04-HANDOFF-STOP: stop cannot be eligible.' }

  $receiptFixture = [pscustomobject][ordered]@{
    schema_version='mnf-phase08-authorization-receipt/1';release_ref='refs/tags/modules-v0.1.0-r9'
    boundary_sha=('1'*40);source_sha=('2'*40);packet_sha256=('3'*64)
    historical_attempt_zero_sha256=$historyFields.historical_attempt_zero_sha256
    historical_r1_sha256=$historyFields.historical_r1_sha256
    historical_r2_sha256=$historyFields.historical_r2_sha256
    historical_r3_sha256=$historyFields.historical_r3_sha256
    historical_r4_sha256=$historyFields.historical_r4_sha256
    historical_r5_sha256=$historyFields.historical_r5_sha256
    historical_r6_sha256=$historyFields.historical_r6_sha256
    historical_r7_sha256=$historyFields.historical_r7_sha256
    historical_r8_sha256=$historyFields.historical_r8_sha256
    historical_history_set_sha256=$historyFields.historical_history_set_sha256
    response='authorize-core';created_at_utc='2026-07-19T00:00:00Z';receipt_sha256=('4'*64)
  }
  $receiptSchemaPath = Join-Path $repoRoot 'release\qualification\phase-08-authorization-receipt-schema.json'
  if (-not (($receiptFixture | ConvertTo-Json -Depth 30 -Compress) | Test-Json -SchemaFile $receiptSchemaPath -ErrorAction Stop)) { throw 'REL04-RECEIPT-SCHEMA: valid r9 receipt fixture failed.' }
  foreach ($mutate in @(
    { param($x) $x.release_ref='refs/tags/modules-v0.1.0-r7' },
    { param($x) $x.historical_r1_sha256=$x.historical_attempt_zero_sha256 },
    { param($x) $t=$x.historical_r2_sha256;$x.historical_r2_sha256=$x.historical_r3_sha256;$x.historical_r3_sha256=$t },
    { param($x) $x.historical_r4_sha256=$x.historical_r3_sha256 },
    { param($x) $x.historical_r5_sha256=$x.historical_r4_sha256 },
    { param($x) $x.historical_r6_sha256=$x.historical_r5_sha256 },
    { param($x) $x.historical_r7_sha256=$x.historical_r6_sha256 },
    { param($x) $x.historical_r8_sha256=$x.historical_r7_sha256 },
    { param($x) $x.historical_history_set_sha256=('f'*64) },
    { param($x) $x.created_at_utc='2026-07-19T08:00:00+08:00' },
    { param($x) $x|Add-Member unexpected x }
  )) {
    $bad=$receiptFixture|ConvertTo-Json -Depth 30|ConvertFrom-Json -Depth 30;&$mutate $bad
    if (($bad|ConvertTo-Json -Depth 30 -Compress)|Test-Json -SchemaFile $receiptSchemaPath -ErrorAction SilentlyContinue) { throw 'REL04-RECEIPT-NEGATIVE: invalid replacement/mix/order/aggregate/UTC/unknown fixture passed.' }
  }

  $handoffSchemaPath = Join-Path $repoRoot 'release\qualification\phase-08-handoff-schema.json'
  $handoffBase = [ordered]@{
    schema_version='mnf-phase08-handoff/1';release_ref='refs/tags/modules-v0.1.0-r9';boundary_sha=('1'*40)
    execution_root='C:\mnf-phase08-r9\source';boundary_locator_path='C:\mnf-phase08-r9\boundary-locator.json';boundary_locator_sha256=('1'*64)
    active_attempt_path='C:\mnf-phase08-r9\attempt.json';active_attempt_sha256=('2'*64);artifact_root='C:\mnf-phase08-r9\artifacts'
    artifact_index_path='C:\mnf-phase08-r9\index.json';artifact_index_sha256=('3'*64)
    attempt_zero_history_path='C:\mnf-phase08-r9\history\attempt-zero.json';attempt_zero_history_sha256=$historyFields.historical_attempt_zero_sha256
    r1_history_path='C:\mnf-phase08-r9\history\r1.json';r1_history_sha256=$historyFields.historical_r1_sha256
    r2_history_path='C:\mnf-phase08-r9\history\r2.json';r2_history_sha256=$historyFields.historical_r2_sha256
    r3_history_path='C:\mnf-phase08-r9\history\r3.json';r3_history_sha256=$historyFields.historical_r3_sha256
    r4_history_path='C:\mnf-phase08-r9\history\r4.json';r4_history_sha256=$historyFields.historical_r4_sha256
    r5_history_path='C:\mnf-phase08-r9\history\r5.json';r5_history_sha256=$historyFields.historical_r5_sha256
    r6_history_path='C:\mnf-phase08-r9\history\r6.json';r6_history_sha256=$historyFields.historical_r6_sha256
    r7_history_path='C:\mnf-phase08-r9\history\r7.json';r7_history_sha256=$historyFields.historical_r7_sha256
    r8_history_path='C:\mnf-phase08-r9\history\r8.json';r8_history_sha256=$historyFields.historical_r8_sha256
    historical_history_set_sha256=$historyFields.historical_history_set_sha256
    authority_variant='mutation_authorized';mutation_authorization_packet_path='C:\mnf-phase08-r9\packet.json';mutation_authorization_packet_sha256=('4'*64)
    authorization_receipt_path='C:\mnf-phase08-r9\receipt.json';authorization_receipt_sha256=('5'*64)
    exact_existing_authority_path=$null;exact_existing_authority_sha256=$null;created_at_utc='2026-07-19T00:00:00Z';handoff_sha256=('6'*64)
  }
  if (-not (($handoffBase | ConvertTo-Json -Depth 30 -Compress) | Test-Json -SchemaFile $handoffSchemaPath -ErrorAction Stop)) { throw 'REL04-HANDOFF-SCHEMA: valid r9 mutation handoff failed.' }
  $exactFixture = $handoffBase | ConvertTo-Json -Depth 30 | ConvertFrom-Json -Depth 30
  $exactFixture.authority_variant='exact_existing';$exactFixture.mutation_authorization_packet_path=$null;$exactFixture.mutation_authorization_packet_sha256=$null
  $exactFixture.authorization_receipt_path=$null;$exactFixture.authorization_receipt_sha256=$null
  $exactFixture.exact_existing_authority_path='C:\mnf-phase08-r9\exact-existing.json';$exactFixture.exact_existing_authority_sha256=('7'*64)
  if (-not (($exactFixture | ConvertTo-Json -Depth 30 -Compress) | Test-Json -SchemaFile $handoffSchemaPath -ErrorAction Stop)) { throw 'REL04-HANDOFF-SCHEMA: valid r9 exact-existing handoff failed.' }
  foreach ($mutate in @(
    { param($x) $x.release_ref='refs/tags/modules-v0.1.0-r7' },
    { param($x) $x.authority_variant='stop' },
    { param($x) $x.authorization_receipt_path=$null },
    { param($x) $t=$x.r7_history_sha256;$x.r7_history_sha256=$x.r8_history_sha256;$x.r8_history_sha256=$t },
    { param($x) $x.historical_history_set_sha256=('f'*64) },
    { param($x) $x.created_at_utc='2026-07-19T08:00:00+08:00' }
  )) {
    $bad=$handoffBase|ConvertTo-Json -Depth 30|ConvertFrom-Json -Depth 30;&$mutate $bad
    if (($bad|ConvertTo-Json -Depth 30 -Compress)|Test-Json -SchemaFile $handoffSchemaPath -ErrorAction SilentlyContinue) { throw 'REL04-HANDOFF-NEGATIVE: stale-r7/stop/receipt/history/set/UTC fixture passed.' }
  }
}

function Assert-IntentContract {
  $policy = Read-IntentJson -Path $policyPath
  $schema = Read-IntentJson -Path $schemaPath
  $preparedSchema = Read-IntentJson -Path (Join-Path $repoRoot 'release\prepared\schema.json')
  Assert-Phase08AttemptSchemas
  if ($policy.schema_version -cne 'mnf-release-control/1' -or $policy.repository -cne 'tchivs/moonbit-foundation' -or
      $policy.owner -cne 'tchivs' -or $policy.sole_maintainer -cne 'tchivs') { throw 'REL01-POLICY-IDENTITY: release-control identity drifted.' }
  $history = @($policy.initial_attempt_family.terminal_negative_history)
  if ($history.Count -ne 9) { throw 'REL01-HISTORICAL-ATTEMPT: exact attempt-zero/r1/r2/r3/r4/r5/r6/r7/r8 history is required.' }
  $attemptZero = $history[0]
  if ($attemptZero.attempt -cne 'attempt_zero' -or $attemptZero.release_ref -cne 'refs/tags/modules-v0.1.0' -or
      $attemptZero.source_sha -cne '198436a45b7403a3c28c98d5fa0d5ed6a958455f' -or
      $attemptZero.hosted_run_present -ne $true -or $attemptZero.run_id -cne '29652468948' -or
      $attemptZero.run_attempt -ne 1 -or $attemptZero.mutation_performed -ne $false -or
      $attemptZero.authority_acquired -ne $false -or $attemptZero.reason -cne 'terminal_setup_failure') {
    throw 'REL01-HISTORICAL-ATTEMPT: protected attempt-zero evidence drifted.'
  }
  $r1 = $history[1]
  if ($r1.attempt -cne 'r1' -or $r1.release_ref -cne 'refs/tags/modules-v0.1.0-r1' -or
      $r1.source_sha -cne '09548df948f58ec1bdfff7494757596c03e4c9bd' -or
      $r1.hosted_run_present -ne $false -or $null -ne $r1.run_id -or $null -ne $r1.run_attempt -or
      $r1.mutation_performed -ne $false -or $r1.authority_acquired -ne $false -or
      $r1.reason -cne 'terminal_local_preparation_failure') {
    throw 'REL01-HISTORICAL-ATTEMPT: protected r1 evidence drifted.'
  }
  $r2 = $history[2]
  if ($r2.attempt -cne 'r2' -or $r2.release_ref -cne 'refs/tags/modules-v0.1.0-r2' -or
      $r2.source_sha -cne '73a3af920fc3938f49e93d14f16f79f116475f1e' -or
      $r2.hosted_run_present -ne $false -or $null -ne $r2.run_id -or $null -ne $r2.run_attempt -or
      $r2.mutation_performed -ne $false -or $r2.authority_acquired -ne $false -or
      $r2.prepare_attempt_completed -ne $true -or $r2.registry_disposition -cne 'confirmed_absent' -or
      $r2.hosted_preflight_dispatched -ne $false -or $r2.failure_stage -cne 'before_hosted_preflight_dispatch' -or
      $r2.reason -cne 'terminal_hosted_field_construction_failure') {
    throw 'REL01-HISTORICAL-ATTEMPT: protected r2 evidence drifted.'
  }
  $r3 = $history[3]
  if ($r3.attempt -cne 'r3' -or $r3.release_ref -cne 'refs/tags/modules-v0.1.0-r3' -or
      $r3.source_sha -cne '67b1fbc9dd62288d19018c46a44c1e3293212b76' -or
      $r3.hosted_run_present -ne $false -or $null -ne $r3.run_id -or $null -ne $r3.run_attempt -or
      $r3.mutation_performed -ne $false -or $r3.authority_acquired -ne $false -or
      $r3.prepare_attempt_completed -ne $true -or $r3.registry_disposition -cne 'confirmed_absent' -or
      $r3.controller_input_count -ne 14 -or $r3.workflow_input_count -ne 17 -or
      $r3.missing_workflow_input -cne 'authorization_receipt_sha256' -or
      $r3.hosted_preflight_dispatched -ne $false -or $r3.failure_stage -cne 'before_gh_run_creation' -or
      $r3.reason -cne 'terminal_workflow_dispatch_input_parity_failure') {
    throw 'REL01-HISTORICAL-ATTEMPT: protected r3 evidence drifted.'
  }
  $r4 = $history[4]
  if ($r4.attempt -cne 'r4' -or $r4.release_ref -cne 'refs/tags/modules-v0.1.0-r4' -or
      $r4.source_sha -cne 'ee4a8eb9b8dca5d69b404c9a4a1cd81608a5462a' -or
      $r4.hosted_run_present -ne $true -or $r4.run_id -cne '29667231047' -or $r4.run_attempt -ne 1 -or
      $r4.mutation_performed -ne $false -or $r4.authority_acquired -ne $false -or
      $r4.prepare_attempt_completed -ne $true -or $r4.registry_disposition -cne 'confirmed_absent' -or
      $r4.hosted_preflight_dispatched -ne $true -or $r4.credential_accessed -ne $false -or
      $r4.failure_stage -cne 'credential_free_qualification_clean_snapshot_before_binding' -or
      $r4.publisher_dry_run_count -ne 0 -or $r4.authorization_packet_count -ne 0 -or
      $r4.authorization_receipt_count -ne 0 -or $r4.handoff_count -ne 0 -or $r4.mutation_count -ne 0 -or
      $r4.reason -cne 'terminal_clean_snapshot_binding_failure') {
    throw 'REL01-HISTORICAL-ATTEMPT: protected r4 evidence drifted.'
  }
  $r5 = $history[5]
  if ($r5.attempt -cne 'r5' -or $r5.release_ref -cne 'refs/tags/modules-v0.1.0-r5' -or
      $r5.source_sha -cne 'df105f06205298f1f82ac2f2cdca214d69d42e15' -or
      $r5.tag_object_sha -cne '4a11582cf9aeae15802cf4f6d7394b013ece63ac' -or
      $r5.hosted_run_present -ne $false -or $null -ne $r5.run_id -or $null -ne $r5.run_attempt -or
      $r5.mutation_performed -ne $false -or $r5.authority_acquired -ne $false -or
      $r5.prepare_attempt_completed -ne $true -or $r5.registry_disposition -cne 'confirmed_absent' -or
      $r5.hosted_preflight_dispatch_attempted -ne $true -or $r5.hosted_preflight_dispatched -ne $false -or
      $r5.failure_stage -cne 'hosted_dispatch_validation_before_run_creation' -or
      $r5.validation_error -cne 'duplicate_workflow_environment_key' -or
      $r5.publish_run_count -ne 0 -or $r5.publisher_dry_run_count -ne 0 -or
      $r5.authorization_packet_count -ne 0 -or $r5.authorization_receipt_count -ne 0 -or
      $r5.handoff_count -ne 0 -or $r5.publish_one_count -ne 0 -or $r5.mutation_count -ne 0 -or
      $r5.reason -cne 'terminal_workflow_duplicate_environment_key') {
    throw 'REL01-HISTORICAL-ATTEMPT: protected r5 no-run evidence drifted.'
  }
  $r6 = $history[6]
  if ($r6.attempt -cne 'r6' -or $r6.release_ref -cne 'refs/tags/modules-v0.1.0-r6' -or
      $r6.source_sha -cne 'c05cacbc3cfc583205c612f4bf293a4e251ec079' -or
      $r6.tag_object_sha -cne 'cdff825cc870a50c0393d5347f21351011092149' -or
      $r6.hosted_run_present -ne $true -or $r6.run_id -cne '29671691604' -or $r6.run_attempt -ne 1 -or
      $r6.prepare_job_id -cne '88151792308' -or $r6.prepare_attempt_completed -ne $true -or
      $r6.hosted_preflight_dispatched -ne $true -or $r6.credential_accessed -ne $false -or
      $r6.failure_stage -cne 'hosted_preflight_prepare_job' -or
      $r6.failure_code -cne 'P08-PREPARED-INTENT-BINDING' -or
      $r6.failure_detail -cne 'windows_linux_eol_dependent_zip_bytes' -or
      $r6.prepared_artifact_upload_count -ne 0 -or $r6.publisher_dry_run_count -ne 0 -or
      $r6.exact_existing_authority_count -ne 0 -or $r6.hosted_preflight_downstream_count -ne 0 -or
      $r6.publisher_count -ne 0 -or $r6.observation_count -ne 0 -or $r6.cold_consumer_count -ne 0 -or
      $r6.authorization_packet_count -ne 0 -or $r6.authorization_receipt_count -ne 0 -or
      $r6.handoff_count -ne 0 -or $r6.publish_one_count -ne 0 -or $r6.mutation_count -ne 0 -or
      $r6.successor_count -ne 0 -or $r6.mutation_performed -ne $false -or $r6.authority_acquired -ne $false -or
      $r6.reason -cne 'terminal_cross_platform_prepared_intent_binding_failure') {
    throw 'REL01-HISTORICAL-ATTEMPT: protected r6 hosted prepare failure evidence drifted.'
  }
  $r7 = $history[7]
  if ($r7.attempt -cne 'r7' -or $r7.release_ref -cne 'refs/tags/modules-v0.1.0-r7' -or
      $r7.source_sha -cne '195e08dc1f3a1dc561d98cc660af679926ae0198' -or
      $r7.tag_object_sha -cne '52a47cda33492fa490178ab195ecdca50b1cf382' -or
      $r7.hosted_run_present -ne $true -or $r7.run_id -cne '29673849108' -or $r7.run_attempt -ne 1 -or
      $r7.prepare_job_id -cne '88157456895' -or $r7.prepare_attempt_completed -ne $true -or
      $r7.hosted_preflight_dispatched -ne $true -or $r7.credential_accessed -ne $false -or
      $r7.failure_stage -cne 'hosted_preflight_prepare_job' -or
      $r7.failure_code -cne 'P08-PREPARED-INTENT-BINDING' -or
      $r7.failure_detail -cne 'windows_linux_raw_moon_zip_container_bytes_despite_lf_entry_payloads' -or
      $r7.prepared_artifact_upload_count -ne 0 -or $r7.publisher_dry_run_count -ne 0 -or
      $r7.exact_existing_authority_count -ne 0 -or $r7.hosted_preflight_downstream_count -ne 0 -or
      $r7.publisher_count -ne 0 -or $r7.observation_count -ne 0 -or $r7.cold_consumer_count -ne 0 -or
      $r7.authorization_packet_count -ne 0 -or $r7.authorization_receipt_count -ne 0 -or
      $r7.handoff_count -ne 0 -or $r7.publish_one_count -ne 0 -or $r7.mutation_count -ne 0 -or
      $r7.successor_count -ne 0 -or $r7.mutation_performed -ne $false -or $r7.authority_acquired -ne $false -or
      $r7.reason -cne 'terminal_cross_platform_raw_moon_zip_container_intent_binding_failure') {
    throw 'REL01-HISTORICAL-ATTEMPT: protected r7 raw-container prepare failure evidence drifted.'
  }
  $r8 = $history[8]
  if ($r8.attempt -cne 'r8' -or $r8.release_ref -cne 'refs/tags/modules-v0.1.0-r8' -or
      $r8.source_sha -cne '8d0f050a2ea2a5f136d87f913987d59ea99a13d4' -or
      $r8.tag_object_sha -cne '20907c7bbd11b91d4482dd113d149b3a107c9672' -or
      $r8.hosted_run_present -ne $false -or $null -ne $r8.run_id -or $null -ne $r8.run_attempt -or
      $r8.boundary_locator_count -ne 0 -or $r8.active_attempt_count -ne 0 -or
      $r8.prepared_artifact_upload_count -ne 0 -or $r8.publisher_dry_run_count -ne 0 -or
      $r8.exact_existing_authority_count -ne 0 -or $r8.hosted_preflight_downstream_count -ne 0 -or
      $r8.publisher_count -ne 0 -or $r8.observation_count -ne 0 -or $r8.cold_consumer_count -ne 0 -or
      $r8.authorization_packet_count -ne 0 -or $r8.authorization_receipt_count -ne 0 -or
      $r8.handoff_count -ne 0 -or $r8.publish_one_count -ne 0 -or $r8.mutation_count -ne 0 -or
      $r8.successor_count -ne 0 -or $r8.credential_accessed -ne $false -or $r8.mutation_performed -ne $false -or
      $r8.authority_acquired -ne $false -or $r8.failure_stage -cne 'prepared_bundle_raw_archive_validation_before_locator' -or
      $r8.failure_code -cne 'PREP15-CANONICAL-ARCHIVE' -or $r8.failure_detail -cne 'REL-XPLAT-NONCANONICAL' -or
      $r8.reason -cne 'terminal_pre_locator_canonical_archive_failure') {
    throw 'REL01-HISTORICAL-ATTEMPT: protected r8 pre-locator canonical-copy seam failure evidence drifted.'
  }
  if (($history.attempt -join ',') -cne 'attempt_zero,r1,r2,r3,r4,r5,r6,r7,r8') { throw 'REL01-HISTORY-ORDER: terminal history order drifted.' }
  foreach ($record in $history) {
    if ($record.record_sha256 -cne (Get-IntentHistoryRecordSha256 $record)) { throw "REL01-HISTORY-DIGEST: $($record.attempt) record digest drifted." }
  }
  if (@($history.record_sha256 | Select-Object -Unique).Count -ne 9) { throw 'REL01-HISTORY-DIGEST: terminal history digests are not distinct.' }
  if ($policy.initial_attempt_family.history_set_profile -cne 'sha256-of-lf-joined-record-sha256-in-canonical-attempt-order' -or
      $policy.initial_attempt_family.history_set_sha256 -cne (Get-IntentHistorySetSha256 $history)) {
    throw 'REL01-HISTORY-SET: ordered terminal history set drifted.'
  }
  if ($policy.initial_attempt_family.current_attempt -cne 'r9' -or
      $policy.initial_profile.release_ref -cne 'refs/tags/modules-v0.1.0-r9' -or $policy.initial_profile.correction_sequence -ne 0 -or
      $policy.initial_profile.serialized_root_intent_sha256 -cne 'forbidden') { throw 'REL01-INITIAL-PROFILE: initial root/ref contract drifted.' }
  if ($policy.correction_profile.release_ref_pattern -cne '^refs/tags/modules-correction-[1-9][0-9]*$' -or
      $policy.correction_profile.sequence_rule -cne 'predecessor_sequence_plus_one' -or
      $policy.correction_profile.successor_rule -cne 'one_authorized_successor_per_predecessor') { throw 'REL01-CORRECTION-PROFILE: correction ref/sequence contract drifted.' }
  if (($policy.module_order.identity -join ',') -cne 'tchivs/mb-core,tchivs/mb-color,tchivs/mb-image') { throw 'REL01-MODULE-ORDER: module identity order drifted.' }
  if ($policy.authority_semantics.intent_sha256 -cne 'content_identity_only' -or
      $policy.authority_semantics.credentials_read -ne $false -or $policy.authority_semantics.publication_performed -ne $false) { throw 'REL02-AUTHORITY-CONFLATION: digest or credential semantics drifted.' }
  if (@($schema.oneOf).Count -ne 2 -or $schema.'$defs'.initialIntent.additionalProperties -ne $false -or
      $schema.'$defs'.forwardCorrectionIntent.additionalProperties -ne $false) { throw 'REL01-CLOSED-SCHEMA: intent oneOf branches are not closed.' }
  if ($schema.'$defs'.initialIntent.properties.release_ref.const -cne 'refs/tags/modules-v0.1.0-r9') {
    throw 'REL01-INITIAL-PROFILE: initial schema does not require r9.'
  }
  if ($preparedSchema.properties.release_ref.pattern -cne '^refs/tags/modules-(v0[.]1[.]0-r9|correction-[1-9][0-9]*)$') {
    throw 'REL01-INITIAL-PROFILE: prepared schema does not require r9 or a correction ref.'
  }
  $initialRequired = @($schema.'$defs'.initialIntent.required)
  if ($initialRequired -contains 'root_intent_sha256' -or $initialRequired -contains 'predecessor_intent_sha256') { throw 'REL01-HASH-CYCLE: initial intent serializes root/predecessor.' }
  $correctionRequired = @($schema.'$defs'.forwardCorrectionIntent.required)
  foreach ($required in @('root_intent_sha256','predecessor_intent_sha256','correction_sequence','correction_evidence')) {
    if ($correctionRequired -cnotcontains $required) { throw "REL01-CORRECTION-EVIDENCE: missing $required." }
  }
  if ($schema.'$defs'.forwardCorrectionIntent.properties.release_ref.pattern -cne '^refs/tags/modules-correction-[1-9][0-9]*$') { throw 'REL01-CORRECTION-TAG: correction tag pattern drifted.' }
  $actor = [pscustomobject][ordered]@{
    expected_actor='tchivs'; observed_actor='tchivs'; actor_check_classification='moon_whoami_exact'
    actor_exit_code=0; actor_stdout_line_count=1; actor_stderr_empty=$true; actor_match=$true
    actor_raw_output_persisted=$false; credential_state_removed=$true; mutation_performed=$false
    command_classification='moon_whoami_dry_run_only'
  }
  Assert-ReleaseActorEvidence -Evidence $actor -Policy $policy
  foreach ($mutation in @(
    { param($x) $x.observed_actor='other' },
    { param($x) $x.actor_stdout_line_count=2 },
    { param($x) $x.actor_stderr_empty=$false },
    { param($x) $x.actor_exit_code=1 },
    { param($x) $x.actor_raw_output_persisted=$true },
    { param($x) $x.credential_state_removed=$false },
    { param($x) $x.mutation_performed=$true }
  )) {
    $bad = $actor | ConvertTo-Json -Compress | ConvertFrom-Json
    & $mutation $bad
    Confirm-IntentRule 'REL03-ACTOR' { Assert-ReleaseActorEvidence -Evidence $bad -Policy $policy }
  }
  Write-Host 'Release intent contracts passed: closed initial root, monotonic correction profile, credential-free authority semantics.'
}

function Confirm-IntentRule {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][scriptblock]$Action)
  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure -or -not $failure.StartsWith("$Id`: ", [StringComparison]::Ordinal)) {
    throw "Focused negative '$Id' passed or failed for the wrong reason: '$failure'."
  }
}

function Invoke-FocusedIntentTests {
  $generator = Join-Path $PSScriptRoot 'New-ReleaseIntent.ps1'
  if (-not (Test-Path -LiteralPath $generator -PathType Leaf)) { throw 'REL01-GENERATOR-MISSING: canonical generator is absent.' }
  $policy = Read-IntentJson -Path $policyPath
  $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-release-intent-' + [Guid]::NewGuid().ToString('N'))
  $null = New-Item -ItemType Directory -Force -Path $tempRoot
  try {
    $head = (& git -C $repoRoot rev-parse HEAD).Trim()
    $cloneA = Join-Path $tempRoot 'source-a'
    $cloneB = Join-Path $tempRoot 'source-b'
    & git clone --quiet --no-hardlinks $repoRoot $cloneA
    if ($LASTEXITCODE -ne 0) { throw 'REL01-TEST-CLONE: unable to create clean source A.' }
    & git clone --quiet --no-hardlinks $repoRoot $cloneB
    if ($LASTEXITCODE -ne 0) { throw 'REL01-TEST-CLONE: unable to create clean source B.' }
    $archives = [ordered]@{ 'mb-core' = ('1' * 64); 'mb-color' = ('2' * 64); 'mb-image' = ('3' * 64) }
    $common = @{
      Check = $true
      IntentKind = 'initial'
      ReleaseRef = 'refs/tags/modules-v0.1.0-r9'
      SourceSha = $head
      QualificationRootSha256 = ('4' * 64)
      RequiredStableSha256 = ('5' * 64)
      ArchiveSha256ByModule = $archives
    }
    $a = & $generator @common -SourceRoot $cloneA -OutputDirectory (Join-Path $tempRoot 'initial-a')
    $b = & $generator @common -SourceRoot $cloneB -OutputDirectory (Join-Path $tempRoot 'initial-b')
    $aBytes = [IO.File]::ReadAllBytes($a.intent_path)
    $bBytes = [IO.File]::ReadAllBytes($b.intent_path)
    if (-not [Linq.Enumerable]::SequenceEqual([byte[]]$aBytes, [byte[]]$bBytes) -or $a.intent_sha256 -cne $b.intent_sha256) {
      throw 'REL01-DETERMINISM: independent initial constructions differ.'
    }
    if ($aBytes.Length -ge 3 -and $aBytes[0] -eq 0xEF -and $aBytes[1] -eq 0xBB -and $aBytes[2] -eq 0xBF) { throw 'REL01-ENCODING: intent contains a UTF-8 BOM.' }
    $initial = Read-ReleaseCanonicalJson -Path $a.intent_path
    $null = Assert-ReleaseIntentObject -Intent $initial -PolicyPath $policyPath -ExpectedCurrentSha256 $a.intent_sha256
    Assert-ReleaseIntentAuthorizationBinding -Intent $initial -IntentSha256 $a.intent_sha256 -RootIntentSha256 $a.intent_sha256

    $reordered = [ordered]@{}
    foreach ($property in @($initial.PSObject.Properties.Name) | Sort-Object -Descending) { $reordered[$property] = $initial.$property }
    if ((ConvertTo-ReleaseCanonicalJson -Value $reordered -Profile ReleaseIntent) -cne [Text.UTF8Encoding]::new($false).GetString($aBytes)) {
      throw 'REL01-CANONICAL-EQUALITY: equivalent object construction changed canonical bytes.'
    }

    foreach ($case in @(
      @{ id='REL01-EMPTY'; mutate={ param($x) $x.source_sha = '' } },
      @{ id='REL01-DIGEST'; mutate={ param($x) $x.source_sha = ('f' * 40) } },
      @{ id='REL01-UNKNOWN-PROPERTY'; mutate={ param($x) $x | Add-Member -NotePropertyName unexpected -NotePropertyValue 'x' } },
      @{ id='REL01-MODULE-ORDER'; mutate={ param($x) [Array]::Reverse($x.modules) } },
      @{ id='REL01-AUTHORITY-CONFLATION'; mutate={ param($x) $x.credentials_read = $true } },
      @{ id='REL01-REF'; mutate={ param($x) $x.release_ref = 'refs/heads/main' } },
      @{ id='REL01-TOOLCHAIN'; mutate={ param($x) $x.toolchain.moon = 'moon latest' } },
      @{ id='REL01-PACKAGE-INVENTORY'; mutate={ param($x) $x.modules[0].public_packages += 'tchivs/mb-core/extra' } },
      @{ id='REL01-DIGEST'; mutate={ param($x) $x.modules[0].archive_sha256 = ('f' * 64) } },
      @{ id='REL01-DIGEST'; mutate={ param($x) $x.modules[0].interface_sha256 = ('f' * 64) } },
      @{ id='REL01-DIGEST'; mutate={ param($x) $x.evidence.qualification_root_sha256 = ('f' * 64) } },
      @{ id='REL01-INITIAL-VERSION'; mutate={ param($x) $x.modules[0].version = '0.1.1' } },
      @{ id='REL01-DEPENDENCY-CLOSURE'; mutate={ param($x) $x.modules[1].dependencies[0].version = '0.1.1' } }
    )) {
      Confirm-IntentRule $case.id {
        $copy = ($initial | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100)
        & $case.mutate $copy
        Assert-ReleaseIntentObject -Intent $copy -PolicyPath $policyPath -ExpectedCurrentSha256 $a.intent_sha256
      }
    }

    $bomPath = Join-Path $tempRoot 'bom.json'
    [IO.File]::WriteAllBytes($bomPath, [byte[]](0xEF,0xBB,0xBF) + [Text.UTF8Encoding]::new($false).GetBytes('{}'))
    Confirm-IntentRule 'REL01-ENCODING' { Read-ReleaseCanonicalJson -Path $bomPath | Out-Null }
    Confirm-IntentRule 'REL01-CONTROLLED-ASCII' {
      $copy = ($initial | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100); $copy.owner = "tchivs$([char]0x301)"
      ConvertTo-ReleaseCanonicalJson -Value $copy -Profile ReleaseIntent | Out-Null
    }
    Confirm-IntentRule 'REL01-TERMINAL-MISMATCH' { Assert-ReleaseIntentRecovery -IntentKind initial -ObservedMismatch }
    foreach ($oldRef in @('refs/tags/modules-v0.1.0','refs/tags/modules-v0.1.0-r1','refs/tags/modules-v0.1.0-r2','refs/tags/modules-v0.1.0-r3','refs/tags/modules-v0.1.0-r4','refs/tags/modules-v0.1.0-r5','refs/tags/modules-v0.1.0-r6','refs/tags/modules-v0.1.0-r7','refs/tags/modules-v0.1.0-r8')) {
      Confirm-IntentRule 'REL01-REF' {
        $old = ($initial | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100); $old.release_ref = $oldRef
        Assert-ReleaseIntentObject -Intent $old -PolicyPath $policyPath
      }
    }
    foreach ($badInitial in @(
      @{ id='REL01-HASH-CYCLE'; values=@{ RootIntentSha256=('a'*64) } },
      @{ id='REL01-HASH-CYCLE'; values=@{ PredecessorIntentSha256=('b'*64) } },
      @{ id='REL01-HASH-CYCLE'; values=@{ CorrectionSequence=1 } },
      @{ id='REL01-CORRECTION-EVIDENCE'; values=@{ IncidentSha256=('c'*64) } }
    )) {
      $bad = @{} + $common; foreach ($entry in $badInitial.values.GetEnumerator()) { $bad[$entry.Key] = $entry.Value }
      Confirm-IntentRule $badInitial.id { & $generator @bad -SourceRoot $cloneA -OutputDirectory (Join-Path $tempRoot ('bad-initial-' + $badInitial.id)) | Out-Null }
    }

    $correctionCommon = @{
      Check = $true
      IntentKind = 'forward_correction'
      RootIntentSha256 = $a.intent_sha256
      PredecessorIntentSha256 = $a.intent_sha256
      PredecessorSourceSha = $head
      PredecessorSequence = 0
      CorrectionSequence = 1
      QualificationRootSha256 = ('6' * 64)
      RequiredStableSha256 = ('7' * 64)
      IncidentSha256 = ('8' * 64)
      AdvisorySha256 = ('9' * 64)
      CompatibilityResultSha256 = ('a' * 64)
      VersionAbsenceSha256 = ('b' * 64)
      CorrectedVersions = [ordered]@{ 'mb-core'='0.1.1'; 'mb-color'='0.1.1'; 'mb-image'='0.1.1' }
    }
    foreach ($entry in @(@($cloneA,'candidate-a'),@($cloneB,'candidate-b'))) {
      $root = $entry[0]; Set-Content -LiteralPath (Join-Path $root "$($entry[1]).txt") -Value $entry[1] -NoNewline
      & git -C $root config user.name 'MNF Intent Test'; & git -C $root config user.email 'intent-test@invalid.local'
      & git -C $root add -- "$($entry[1]).txt"; & git -C $root commit --quiet -m $entry[1]
      if ($LASTEXITCODE -ne 0) { throw 'REL01-TEST-COMMIT: unable to create correction source.' }
    }
    $sourceA = (& git -C $cloneA rev-parse HEAD).Trim(); $sourceB = (& git -C $cloneB rev-parse HEAD).Trim()
    $candidateA = & $generator @correctionCommon -ReleaseRef 'refs/tags/modules-correction-1' -SourceSha $sourceA -SourceRoot $cloneA -ArchiveSha256ByModule ([ordered]@{ 'mb-core'=('c'*64); 'mb-color'=('d'*64); 'mb-image'=('e'*64) }) -OutputDirectory (Join-Path $tempRoot 'correction-a')
    $candidateB = & $generator @correctionCommon -ReleaseRef 'refs/tags/modules-correction-2' -SourceSha $sourceB -SourceRoot $cloneB -ArchiveSha256ByModule ([ordered]@{ 'mb-core'=('d'*64); 'mb-color'=('e'*64); 'mb-image'=('f'*64) }) -OutputDirectory (Join-Path $tempRoot 'correction-b')
    if ($candidateA.intent_sha256 -ceq $candidateB.intent_sha256) { throw 'REL01-CORRECTION-DIGEST: distinct corrections share a digest.' }
    $correctionA = Read-ReleaseCanonicalJson -Path $candidateA.intent_path
    $correctionB = Read-ReleaseCanonicalJson -Path $candidateB.intent_path
    if ($correctionA.root_intent_sha256 -cne $a.intent_sha256 -or $correctionB.root_intent_sha256 -cne $a.intent_sha256) { throw 'REL01-ROOT-DRIFT: correction root changed.' }
    $null = Assert-ReleaseIntentObject -Intent $correctionA -PolicyPath $policyPath -ExpectedCurrentSha256 $candidateA.intent_sha256 -ExpectedRootSha256 $a.intent_sha256 -ExpectedPredecessorSha256 $a.intent_sha256 -ExpectedPredecessorSequence 0 -AuthorizedSuccessorSha256 $candidateA.intent_sha256
    Confirm-IntentRule 'REL01-STALE-FORK' {
      Assert-ReleaseIntentObject -Intent $correctionB -PolicyPath $policyPath -ExpectedCurrentSha256 $candidateB.intent_sha256 -ExpectedRootSha256 $a.intent_sha256 -ExpectedPredecessorSha256 $a.intent_sha256 -ExpectedPredecessorSequence 0 -AuthorizedSuccessorSha256 $candidateA.intent_sha256
    }
    Confirm-IntentRule 'REL01-CORRECTION-TAG' { & $generator @correctionCommon -ReleaseRef 'refs/tags/modules-correction-0' -SourceSha $sourceA -SourceRoot $cloneA -ArchiveSha256ByModule $archives -OutputDirectory (Join-Path $tempRoot 'bad-tag') | Out-Null }
    $nonconsecutive = @{} + $correctionCommon; $nonconsecutive.CorrectionSequence = 2
    Confirm-IntentRule 'REL01-SEQUENCE' { & $generator @nonconsecutive -ReleaseRef 'refs/tags/modules-correction-3' -SourceSha $sourceA -SourceRoot $cloneA -ArchiveSha256ByModule $archives -OutputDirectory (Join-Path $tempRoot 'bad-sequence') | Out-Null }
    Write-Host 'Release intent focused tests passed: deterministic initial/correction bytes, canonical equality, terminal mismatch, monotonic root, and stale-fork rejection.'
  } finally {
    if (Test-Path -LiteralPath $tempRoot) {
      $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
      $full = [IO.Path]::GetFullPath($tempRoot)
      if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
          -not (Split-Path -Leaf $full).StartsWith('mnf-release-intent-', [StringComparison]::Ordinal)) { throw "Refusing to remove unverified intent test path: $full" }
      Remove-Item -LiteralPath $full -Recurse -Force
    }
  }
}

function Invoke-QualificationIntegrationTests {
  $source = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Invoke-ReleaseQualification.ps1') -Raw
  $archivePosition = $source.IndexOf('Assert-ReleaseTrackedSnapshot -Before $initialDiff -After $finalDiff', [StringComparison]::Ordinal)
  $reportPosition = $source.IndexOf('Assert-WrittenReleaseReport -Path $reportPath', [StringComparison]::Ordinal)
  $intentPosition = $source.IndexOf('Write-InitialReleaseIntentBinding -ReleaseReport $report', [StringComparison]::Ordinal)
  if ($archivePosition -lt 0 -or $reportPosition -le $archivePosition -or $intentPosition -le $reportPosition) {
    throw 'REL01-INTEGRATION-ORDER: intent generation is not after tracked-diff and report validation.'
  }
  foreach ($forbidden in @('moon login','moon publish','credentials.json','MOONCAKES_TOKEN','Authorization:','Bearer ')) {
    if ($source.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "REL01-INTEGRATION-CREDENTIAL: qualification contains forbidden '$forbidden'." }
  }
  $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-intent-integration-' + [Guid]::NewGuid().ToString('N'))
  $null = New-Item -ItemType Directory -Force -Path $tempRoot
  try {
    $result = & (Join-Path $PSScriptRoot 'Invoke-ReleaseQualification.ps1') -Check -IntentIntegrationOnly -OutputDirectory $tempRoot
    $binding = Get-Content -LiteralPath $result.binding_path -Raw | ConvertFrom-Json -Depth 100
    $intent = Read-ReleaseCanonicalJson -Path $result.intent_path
    if ($binding.schema_version -cne 'mnf-release-intent-binding/1' -or $binding.intent_kind -cne 'initial' -or
        $binding.release_ref -cne 'refs/tags/modules-v0.1.0-r1' -or $binding.root_intent_sha256 -cne $binding.intent_sha256 -or
        $binding.intent_sha256 -cne $result.intent_sha256) { throw 'REL01-INITIAL-ROOT-BINDING: integration binding drifted.' }
    if ($null -ne $intent.PSObject.Properties['root_intent_sha256']) { throw 'REL01-HASH-CYCLE: integration serialized initial root inside intent.' }
    if ($binding.credentials_read -ne $false -or $binding.publication_performed -ne $false -or
        $intent.credentials_read -ne $false -or $intent.publication_performed -ne $false) { throw 'REL01-INTEGRATION-MUTATION: integration crossed credential/publication boundary.' }
    foreach ($field in @('qualification_root_sha256','required_stable_sha256','phase_06_ledger_sha256','interface_manifest_sha256')) {
      if ([string]$binding.$field -cnotmatch '^[0-9a-f]{64}$') { throw "REL01-INTEGRATION-EVIDENCE: missing $field." }
    }
    Write-Host 'Release intent qualification integration passed: one-way initial root/current binding after stable credential-free evidence.'
  } finally {
    if (Test-Path -LiteralPath $tempRoot) {
      $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
      $full = [IO.Path]::GetFullPath($tempRoot)
      if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
          -not (Split-Path -Leaf $full).StartsWith('mnf-intent-integration-', [StringComparison]::Ordinal)) { throw "Refusing to remove unverified integration path: $full" }
      Remove-Item -LiteralPath $full -Recurse -Force
    }
  }
}

if (-not ($ContractOnly -or $Focused -or $QualificationIntegration)) { $ContractOnly = $true; $Focused = $true }
Assert-IntentContract
if ($Focused) { Invoke-FocusedIntentTests }
if ($QualificationIntegration) { Invoke-QualificationIntegrationTests }
