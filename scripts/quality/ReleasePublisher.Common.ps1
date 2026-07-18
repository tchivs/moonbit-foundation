Set-StrictMode -Version Latest

function Throw-PublisherRule {
  param([string]$Id, [string]$Message)
  throw "$Id`: $Message"
}

function Assert-PublisherClosedProperties {
  param([string]$Label, [object]$Object, [string[]]$Expected)
  if ($null -eq $Object) { Throw-PublisherRule 'PUB01-CLOSED' "$Label is null." }
  $actual = @($Object.PSObject.Properties.Name)
  if ($actual.Count -ne $Expected.Count) { Throw-PublisherRule 'PUB01-CLOSED' "$Label property count is invalid." }
  for ($i = 0; $i -lt $Expected.Count; $i++) {
    if ($actual[$i] -cne $Expected[$i]) { Throw-PublisherRule 'PUB01-CLOSED' "$Label property '$($actual[$i])' is not '$($Expected[$i])'." }
  }
}

function ConvertTo-PublisherSanitizedObservation {
  param(
    [ValidateSet('not_observed','absent','exact_match','mismatch','unknown')][string]$Status,
    [ValidateSet('not_applicable','exact','insufficient')][string]$Identity,
    [ValidateSet('none','ambiguous_result','registry_absent','registry_exact_match','registry_mismatch','authentication_failed','evidence_invalid','artifact_expired','cancelled_or_interrupted')][string]$ReasonCode,
    [bool]$ReobservationRequired
  )
  [pscustomobject][ordered]@{ status=$Status; identity=$Identity; reason_code=$ReasonCode; reobservation_required=$ReobservationRequired }
}

function ConvertTo-PublisherCanonicalValue {
  param([AllowNull()][object]$Value)
  if ($null -eq $Value) { return $null }
  if ($Value -is [string] -or $Value -is [bool] -or $Value -is [int] -or $Value -is [long]) { return $Value }
  if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [pscustomobject] -and $Value -isnot [System.Collections.IDictionary]) {
    return @($Value | ForEach-Object { ConvertTo-PublisherCanonicalValue $_ })
  }
  $ordered = [ordered]@{}
  foreach ($p in $Value.PSObject.Properties) { $ordered[$p.Name] = ConvertTo-PublisherCanonicalValue $p.Value }
  return [pscustomobject]$ordered
}

function Get-PublisherRecordSha256 {
  param([object]$Record)
  $projection = [ordered]@{}
  foreach ($p in $Record.PSObject.Properties) { if ($p.Name -cne 'record_sha256') { $projection[$p.Name] = ConvertTo-PublisherCanonicalValue $p.Value } }
  $json = ([pscustomobject]$projection | ConvertTo-Json -Depth 30 -Compress)
  $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json)
  ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))).ToLowerInvariant()
}

function Assert-PublisherObservation {
  param([object]$Observation)
  Assert-PublisherClosedProperties 'observation' $Observation @('status','identity','reason_code','reobservation_required')
  if ([string]$Observation.status -notin @('not_observed','absent','exact_match','mismatch','unknown') -or
      [string]$Observation.identity -notin @('not_applicable','exact','insufficient') -or
      [string]$Observation.reason_code -notin @('none','ambiguous_result','registry_absent','registry_exact_match','registry_mismatch','authentication_failed','evidence_invalid','artifact_expired','cancelled_or_interrupted') -or
      $Observation.reobservation_required -isnot [bool]) { Throw-PublisherRule 'PUB08-SANITIZE' 'Observation is outside the allowlist.' }
}

function Assert-PublisherCommand {
  param([object]$Command)
  Assert-PublisherClosedProperties 'command' $Command @('journal_sequence','prior_record_sha256','root_intent_sha256','intent_sha256','intent_kind','correction_sequence','predecessor_intent_sha256','state','module','operation','observation','outcome','recorded_at_utc','run_identity')
  Assert-PublisherObservation $Command.observation
  Assert-PublisherClosedProperties 'run identity' $Command.run_identity @('repository','run_id','artifact_name','artifact_sequence')
  foreach ($digest in @($Command.prior_record_sha256,$Command.root_intent_sha256,$Command.intent_sha256)) { if ([string]$digest -cnotmatch '^[0-9a-f]{64}$') { Throw-PublisherRule 'PUB01-CLOSED' 'Digest is invalid.' } }
  if ([string]$Command.run_identity.repository -cne 'tchivs/moonbit-foundation') { Throw-PublisherRule 'PUB12-AUTH' 'Repository binding is invalid.' }
}

function New-PublisherJournalRecord {
  param([object]$Command)
  Assert-PublisherCommand $Command
  $record = [pscustomobject][ordered]@{
    schema_version='mnf-release-journal-record/1'; journal_sequence=[int]$Command.journal_sequence
    prior_record_sha256=[string]$Command.prior_record_sha256; root_intent_sha256=[string]$Command.root_intent_sha256
    intent_sha256=[string]$Command.intent_sha256; intent_kind=[string]$Command.intent_kind
    correction_sequence=[int]$Command.correction_sequence; predecessor_intent_sha256=$Command.predecessor_intent_sha256
    state=[string]$Command.state; module=$Command.module; operation=[string]$Command.operation
    observation=ConvertTo-PublisherCanonicalValue $Command.observation; outcome=[string]$Command.outcome
    recorded_at_utc=[string]$Command.recorded_at_utc; run_identity=ConvertTo-PublisherCanonicalValue $Command.run_identity
    record_sha256=''
  }
  $record.record_sha256 = Get-PublisherRecordSha256 $record
  return $record
}

function Test-PublisherJournalChain {
  param([object[]]$Records)
  $prior = '0' * 64
  for ($i=0; $i -lt $Records.Count; $i++) {
    $r=$Records[$i]
    Assert-PublisherClosedProperties 'record' $r @('schema_version','journal_sequence','prior_record_sha256','root_intent_sha256','intent_sha256','intent_kind','correction_sequence','predecessor_intent_sha256','state','module','operation','observation','outcome','recorded_at_utc','run_identity','record_sha256')
    if ([int]$r.journal_sequence -ne $i) { Throw-PublisherRule 'PUB02-SEQUENCE' 'Journal sequence is not contiguous.' }
    if ([string]$r.prior_record_sha256 -cne $prior) { Throw-PublisherRule 'PUB03-PRIOR-DIGEST' 'Prior record digest does not match.' }
    if ([string]$r.record_sha256 -cne (Get-PublisherRecordSha256 $r)) { Throw-PublisherRule 'PUB03-PRIOR-DIGEST' 'Record digest is invalid.' }
    if ($i -eq 0 -and $r.intent_kind -ceq 'initial' -and $r.root_intent_sha256 -cne $r.intent_sha256) { Throw-PublisherRule 'PUB04-ROOT' 'Initial root/current intent must match.' }
    $prior=[string]$r.record_sha256
  }
  return $true
}

function Get-PublisherLockIdentity {
  param([string]$Repository,[string]$RootIntentSha256)
  if ($RootIntentSha256 -cnotmatch '^[0-9a-f]{64}$') { Throw-PublisherRule 'PUB04-ROOT' 'Lock root digest is invalid.' }
  "mnf-release::$Repository::$RootIntentSha256"
}

function Resolve-PublisherTransition {
  param([object[]]$Records, [object]$Command)
  Assert-PublisherCommand $Command
  if ($Records.Count -eq 0) {
    if ([int]$Command.journal_sequence -ne 0 -or $Command.prior_record_sha256 -cne ('0'*64)) { Throw-PublisherRule 'PUB02-SEQUENCE' 'Genesis must be sequence zero.' }
    if ($Command.state -cne 'intent_authorized') { Throw-PublisherRule 'PUB06-ORDER' 'Genesis must authorize intent.' }
    if ($Command.intent_kind -ceq 'initial') {
      if ($Command.root_intent_sha256 -cne $Command.intent_sha256 -or [int]$Command.correction_sequence -ne 0 -or $null -ne $Command.predecessor_intent_sha256) { Throw-PublisherRule 'PUB04-ROOT' 'Initial genesis binding is invalid.' }
    } else {
      if ([int]$Command.correction_sequence -lt 1 -or [string]$Command.predecessor_intent_sha256 -cnotmatch '^[0-9a-f]{64}$' -or $Command.root_intent_sha256 -ceq $Command.intent_sha256) { Throw-PublisherRule 'PUB11-CORRECTION-SEQUENCE' 'Corrected genesis binding is invalid.' }
    }
    return [pscustomobject]@{ action='append'; record=(New-PublisherJournalRecord $Command) }
  }
  $null=Test-PublisherJournalChain $Records
  $last=$Records[-1]
  if ($last.state -ceq 'terminal_mismatch') { Throw-PublisherRule 'PUB09-TERMINAL' 'Mismatched intent cannot append.' }
  if ([int]$Command.journal_sequence -ne ([int]$last.journal_sequence+1)) { Throw-PublisherRule 'PUB02-SEQUENCE' 'Next sequence is not contiguous.' }
  if ($Command.prior_record_sha256 -cne $last.record_sha256) { Throw-PublisherRule 'PUB03-PRIOR-DIGEST' 'Next prior digest is invalid.' }
  if ($Command.root_intent_sha256 -cne $last.root_intent_sha256) { Throw-PublisherRule 'PUB04-ROOT' 'Immutable root drifted.' }
  if ($Command.intent_sha256 -cne $last.intent_sha256 -or $Command.correction_sequence -ne $last.correction_sequence) { Throw-PublisherRule 'PUB05-INTENT' 'Current intent was substituted.' }
  $states=@('intent_authorized','preflight_passed','core_mutation_attempted','core_registry_observed','core_checkpoint_verified','color_mutation_attempted','color_registry_observed','color_checkpoint_verified','image_mutation_attempted','image_registry_observed','image_checkpoint_verified','handoff_ready')
  $index=[Array]::IndexOf($states,[string]$last.state)
  $expected=if($index -ge 0 -and $index+1 -lt $states.Count){$states[$index+1]}else{$null}
  $terminal=@('terminal_mismatch','stopped_absent','stopped_unknown','stopped_invalid_auth')
  if ($Command.state -notin $terminal -and $Command.state -cne $expected) { Throw-PublisherRule 'PUB06-ORDER' "Expected '$expected'." }
  $moduleByState=@{core_mutation_attempted='mb-core';core_registry_observed='mb-core';core_checkpoint_verified='mb-core';color_mutation_attempted='mb-color';color_registry_observed='mb-color';color_checkpoint_verified='mb-color';image_mutation_attempted='mb-image';image_registry_observed='mb-image';image_checkpoint_verified='mb-image'}
  if ($moduleByState.ContainsKey([string]$Command.state) -and $Command.module -cne $moduleByState[[string]$Command.state]) { Throw-PublisherRule 'PUB06-ORDER' 'Module does not own the requested state.' }
  return [pscustomobject]@{ action='append'; record=(New-PublisherJournalRecord $Command) }
}
