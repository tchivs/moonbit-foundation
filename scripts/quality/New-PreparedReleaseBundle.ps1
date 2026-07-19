[CmdletBinding(DefaultParameterSetName='Generate')]
param(
  [Parameter(Mandatory,ParameterSetName='Generate')][string]$InputRoot,
  [Parameter(Mandatory)][string]$OutputRoot,
  [Parameter(Mandatory)][string]$Repository,
  [Parameter(Mandatory)][string]$Actor,
  [Parameter(Mandatory)][string]$RunId,
  [Parameter(Mandatory)][int]$RunAttempt,
  [Parameter(Mandatory)][string]$ReleaseRef,
  [Parameter(Mandatory)][string]$SourceSha,
  [Parameter(Mandatory)][string]$RootIntentSha256,
  [Parameter(Mandatory)][string]$IntentSha256,
  [Parameter(Mandatory)][string]$HistoricalAttemptZeroSha256,
  [Parameter(Mandatory)][string]$HistoricalR1Sha256,
  [Parameter(Mandatory)][string]$HistoricalR2Sha256,
  [Parameter(Mandatory)][string]$HistoricalR3Sha256,
  [Parameter(Mandatory)][string]$HistoricalHistorySetSha256,
  [Parameter(Mandatory)][ValidateSet('start','resume')][string]$RunMode,
  [string]$PriorRunId,
  [string]$PriorArtifactName,
  [string]$PriorTerminalRecordSha256,
  [Parameter(Mandatory,ParameterSetName='Validate')][switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$expectedToolchain = [ordered]@{
  moon = '0.1.20260713 (75c7e1f 2026-07-13)'
  moonc = 'v0.10.4+2cc641edf (2026-07-15)'
  moonrun = '0.1.20260713 (75c7e1f 2026-07-13)'
}
$expectedInitialHistory = [ordered]@{
  attempt_zero = 'b9bda5378ea339f4cdd42c417c1cc0cf8caabbd51ab11d453cd45ddae77d9b52'
  r1 = 'cba047dae2e6b4e1bbf0248653ed7848f144971b54a0a4ed30ef42ab97325653'
  r2 = 'aae8bee66e7dbfca7f3f22f1b52071e7888ae3ec8feee513d1c5d8eba6111609'
  r3 = 'cf29473b2b07ff9aa8fd8a4810ddc45f6aacd2fd4b74048f5d29b3b6fa939d41'
  set = '1646412aae84a40c5012aeae4f374c3b5c03bf3c3027c914bc0765ea0aa2493e'
}
$inventory = @(
  [pscustomobject]@{ path='archives/mb-core.zip'; role='exact_source_archive' }
  [pscustomobject]@{ path='archives/mb-color.zip'; role='exact_source_archive' }
  [pscustomobject]@{ path='archives/mb-image.zip'; role='exact_source_archive' }
  [pscustomobject]@{ path='intent/current.json'; role='current_intent' }
  [pscustomobject]@{ path='intent/current.sha256'; role='current_intent_digest' }
  [pscustomobject]@{ path='intent/root-binding.json'; role='initial_root_intent_evidence' }
  [pscustomobject]@{ path='request.json'; role='journal_or_genesis' }
  [pscustomobject]@{ path='scripts/quality/New-PreparedReleaseBundle.ps1'; role='publisher_script' }
  [pscustomobject]@{ path='scripts/quality/Invoke-ReleasePublisher.ps1'; role='publisher_script' }
  [pscustomobject]@{ path='scripts/quality/Invoke-MooncakesLiveMutation.ps1'; role='publisher_script' }
  [pscustomobject]@{ path='scripts/quality/ReleasePublisher.Common.ps1'; role='publisher_common' }
  [pscustomobject]@{ path='policy/release-qualification.json'; role='release_policy' }
  [pscustomobject]@{ path='schemas/prepared.json'; role='contract_schema' }
  [pscustomobject]@{ path='schemas/intent.json'; role='contract_schema' }
  [pscustomobject]@{ path='schemas/journal-record.json'; role='contract_schema' }
  [pscustomobject]@{ path='qualification/phase-07-requirements.json'; role='qualification_evidence' }
  [pscustomobject]@{ path='compatibility/interface-digests.json'; role='archive_interface_digests' }
  [pscustomobject]@{ path='registry/authority-observation.json'; role='sanitized_authority_observation' }
)

function Throw-PreparedRule {
  param([Parameter(Mandatory)][string]$Id,[Parameter(Mandatory)][string]$Message)
  throw "$Id`: $Message"
}

function Get-PreparedSha256 {
  param([Parameter(Mandatory)][string]$Path)
  (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Read-PreparedJson {
  param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Rule)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Throw-PreparedRule $Rule "Missing JSON '$Path'." }
  try { Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100 } catch { Throw-PreparedRule $Rule "Invalid JSON '$Path'." }
}

function Assert-PreparedClosedProperties {
  param([string]$Label,[object]$Value,[string[]]$Expected)
  if ($null -eq $Value) { Throw-PreparedRule 'PREP03-INVENTORY' "$Label is missing." }
  $actual = @($Value.PSObject.Properties.Name)
  if ($actual.Count -ne $Expected.Count) { Throw-PreparedRule 'PREP03-INVENTORY' "$Label property count drifted." }
  for ($i=0; $i -lt $Expected.Count; $i++) {
    if ($actual[$i] -cne $Expected[$i]) { Throw-PreparedRule 'PREP03-INVENTORY' "$Label property order drifted at $i." }
  }
}

function Assert-PreparedSafePath {
  param([Parameter(Mandatory)][string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path) -or [IO.Path]::IsPathRooted($Path) -or $Path.Contains('\',[StringComparison]::Ordinal) -or
      $Path -cmatch '(^|/)[.][.]?(/|$)' -or $Path -cnotmatch '^[a-zA-Z0-9_.-]+(?:/[a-zA-Z0-9_.-]+)*$') {
    Throw-PreparedRule 'PREP02-PAYLOAD-PATH' "Unsafe payload path '$Path'."
  }
}

function Assert-NoPreparedSecretMaterial {
  param([Parameter(Mandatory)][string]$Path)
  $bytes = [IO.File]::ReadAllBytes($Path)
  $text = [Text.Encoding]::UTF8.GetString($bytes)
  $isCredentialAdapter = [IO.Path]::GetFileName($Path) -ceq 'Invoke-MooncakesLiveMutation.ps1'
  $forbiddenValues = @(
    ('Authorization' + ':'),('Bearer' + ' '),
    ('BEGIN PRIVATE' + ' KEY')
  )
  if (-not $isCredentialAdapter) { $forbiddenValues += @(('MOONCAKES' + '_TOKEN'),('credentials' + '.json')) }
  foreach ($forbidden in $forbiddenValues) {
    if ($text.IndexOf($forbidden,[StringComparison]::OrdinalIgnoreCase) -ge 0) {
      Throw-PreparedRule 'PREP13-SECRET-MATERIAL' "Forbidden secret material in '$Path'."
    }
  }
}

function Assert-PreparedBindings {
  param([Parameter(Mandatory)][object]$Manifest)
  if ($Manifest.repository -cne $Repository -or $Manifest.actor -cne $Actor -or [string]$Manifest.run_id -cne $RunId -or
      [int]$Manifest.run_attempt -ne $RunAttempt -or $Manifest.release_ref -cne $ReleaseRef -or
      $Manifest.source_sha -cne $SourceSha -or $Manifest.root_intent_sha256 -cne $RootIntentSha256 -or
      $Manifest.intent_sha256 -cne $IntentSha256 -or $Manifest.run_mode -cne $RunMode) {
    Throw-PreparedRule 'PREP09-BINDING' 'Manifest dispatch binding drifted.'
  }
  if ($Repository -cne 'tchivs/moonbit-foundation' -or $Actor -cne 'tchivs' -or $RunId -cnotmatch '^[1-9][0-9]*$' -or
      $RunAttempt -lt 1 -or $ReleaseRef -cnotmatch '^refs/tags/modules-(v0[.]1[.]0-r4|correction-[1-9][0-9]*)$' -or
      $SourceSha -cnotmatch '^[0-9a-f]{40}$' -or $SourceSha -cin @('198436a45b7403a3c28c98d5fa0d5ed6a958455f','09548df948f58ec1bdfff7494757596c03e4c9bd','73a3af920fc3938f49e93d14f16f79f116475f1e','67b1fbc9dd62288d19018c46a44c1e3293212b76') -or $RootIntentSha256 -cnotmatch '^[0-9a-f]{64}$' -or
      $IntentSha256 -cnotmatch '^[0-9a-f]{64}$') { Throw-PreparedRule 'PREP09-BINDING' 'Expected dispatch binding is invalid.' }
  $history = @($HistoricalAttemptZeroSha256,$HistoricalR1Sha256,$HistoricalR2Sha256,$HistoricalR3Sha256)
  if (@($history | Where-Object { $_ -cnotmatch '^[0-9a-f]{64}$' }).Count -ne 0 -or @($history | Select-Object -Unique).Count -ne 4 -or
      $HistoricalHistorySetSha256 -cnotmatch '^[0-9a-f]{64}$') { Throw-PreparedRule 'PREP14-HISTORICAL-BINDING' 'Four distinct historical-negative digests and their ordered set are required.' }
  $expectedSet = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($history -join "`n")))).ToLowerInvariant()
  if ($HistoricalHistorySetSha256 -cne $expectedSet -or $HistoricalAttemptZeroSha256 -cne $expectedInitialHistory.attempt_zero -or
      $HistoricalR1Sha256 -cne $expectedInitialHistory.r1 -or $HistoricalR2Sha256 -cne $expectedInitialHistory.r2 -or $HistoricalR3Sha256 -cne $expectedInitialHistory.r3 -or
      $HistoricalHistorySetSha256 -cne $expectedInitialHistory.set) { Throw-PreparedRule 'PREP14-HISTORICAL-BINDING' 'Exact ordered historical-negative family drifted.' }
}

function Assert-PreparedToolchain {
  param([Parameter(Mandatory)][object]$Toolchain)
  Assert-PreparedClosedProperties 'toolchain' $Toolchain @('moon','moonc','moonrun')
  foreach ($name in @('moon','moonc','moonrun')) {
    if ([string]$Toolchain.$name -cne [string]$expectedToolchain[$name]) { Throw-PreparedRule 'PREP11-TOOLCHAIN' "Toolchain '$name' drifted." }
  }
}

function Assert-PreparedJournalBinding {
  param([Parameter(Mandatory)][string]$Root)
  $request = Read-PreparedJson -Path (Join-Path $Root 'request.json') -Rule 'PREP10-JOURNAL-BINDING'
  try {
    Assert-PreparedClosedProperties 'request' $request @(
      'repository','actor','release_ref','source_sha','root_intent_sha256','intent_sha256','intent_kind','correction_sequence',
      'predecessor_intent_sha256','authorization_valid','evidence_valid','dry_run_passed','authority_account',
      'historical_attempt_zero_sha256','historical_r1_sha256','historical_r2_sha256','historical_r3_sha256','historical_history_set_sha256'
    )
  } catch { Throw-PreparedRule 'PREP10-JOURNAL-BINDING' $_.Exception.Message }
  foreach ($pair in @(
    @('repository',$Repository),@('actor',$Actor),@('release_ref',$ReleaseRef),@('source_sha',$SourceSha),
    @('root_intent_sha256',$RootIntentSha256),@('intent_sha256',$IntentSha256)
  )) {
    if ([string]$request.($pair[0]) -cne [string]$pair[1]) { Throw-PreparedRule 'PREP10-JOURNAL-BINDING' "Request '$($pair[0])' drifted." }
  }
  if ($request.authorization_valid -ne $true -or $request.evidence_valid -ne $true -or $request.dry_run_passed -ne $true -or
      $request.authority_account -cne 'tchivs') { Throw-PreparedRule 'PREP10-JOURNAL-BINDING' 'Request authority evidence is incomplete.' }
  if ([string]$request.historical_attempt_zero_sha256 -cne $HistoricalAttemptZeroSha256 -or
      [string]$request.historical_r1_sha256 -cne $HistoricalR1Sha256 -or
      [string]$request.historical_r2_sha256 -cne $HistoricalR2Sha256 -or
      [string]$request.historical_r3_sha256 -cne $HistoricalR3Sha256 -or
      [string]$request.historical_history_set_sha256 -cne $HistoricalHistorySetSha256) {
    Throw-PreparedRule 'PREP14-HISTORICAL-BINDING' 'Request terminal-negative history binding drifted.'
  }
  if ($ReleaseRef -ceq 'refs/tags/modules-v0.1.0-r4' -and
      ($request.intent_kind -cne 'initial' -or [int]$request.correction_sequence -ne 0 -or $null -ne $request.predecessor_intent_sha256 -or
       [string]$request.root_intent_sha256 -cne [string]$request.intent_sha256)) {
    Throw-PreparedRule 'PREP10-JOURNAL-BINDING' 'r4 must be a fresh initial root with no predecessor.'
  }
}

function Assert-PreparedIntentBinding {
  param([Parameter(Mandatory)][string]$Root,[Parameter(Mandatory)][object]$Manifest)
  $intentPath = Join-Path $Root 'intent/current.json'
  $digestPath = Join-Path $Root 'intent/current.sha256'
  $bindingPath = Join-Path $Root 'intent/root-binding.json'
  $intent = Read-PreparedJson -Path $intentPath -Rule 'PREP09-BINDING'
  $binding = Read-PreparedJson -Path $bindingPath -Rule 'PREP09-BINDING'
  $digestText = (Get-Content -LiteralPath $digestPath -Raw).Trim()
  if ((Get-PreparedSha256 $intentPath) -cne $IntentSha256 -or $digestText -cne $IntentSha256 -or
      $intent.repository -cne $Repository -or $intent.owner -cne $Actor -or $intent.release_ref -cne $ReleaseRef -or
      $intent.source_sha -cne $SourceSha -or [string]$binding.root_intent_sha256 -cne $RootIntentSha256 -or
      [string]$binding.intent_sha256 -cne $IntentSha256 -or [string]$binding.source_sha -cne $SourceSha -or
      [string]$binding.release_ref -cne $ReleaseRef) { Throw-PreparedRule 'PREP09-BINDING' 'Intent or root evidence drifted.' }
  Assert-PreparedToolchain $intent.toolchain
  if ([string]$Manifest.intent_kind -cne [string]$intent.intent_kind -or [int]$Manifest.correction_sequence -ne [int]$intent.correction_sequence) {
    Throw-PreparedRule 'PREP09-BINDING' 'Intent kind or correction sequence drifted.'
  }
  $predecessor = if ($null -ne $intent.PSObject.Properties['predecessor_intent_sha256']) { $intent.predecessor_intent_sha256 } else { $null }
  if ([string]$Manifest.predecessor_intent_sha256 -cne [string]$predecessor) { Throw-PreparedRule 'PREP09-BINDING' 'Predecessor intent drifted.' }
}

function Test-PreparedReleaseBundle {
  param([Parameter(Mandatory)][string]$Root)
  $absoluteRoot = [IO.Path]::GetFullPath($Root)
  $manifestPath = Join-Path $absoluteRoot 'prepared-bundle.json'
  $manifest = Read-PreparedJson -Path $manifestPath -Rule 'PREP03-INVENTORY'
  Assert-PreparedClosedProperties 'manifest' $manifest @(
    'schema_version','repository','actor','run_id','run_attempt','release_ref','source_sha','root_intent_sha256','intent_sha256',
    'intent_kind','correction_sequence','predecessor_intent_sha256','run_mode','journal_binding','toolchain','payloads'
  )
  if ($manifest.schema_version -cne 'mnf-release-prepared/1') { Throw-PreparedRule 'PREP03-INVENTORY' 'Schema version drifted.' }
  Assert-PreparedBindings $manifest
  Assert-PreparedToolchain $manifest.toolchain
  Assert-PreparedClosedProperties 'journal binding' $manifest.journal_binding @('kind','prior_run_id','prior_artifact_name','terminal_record_sha256')
  if ($RunMode -ceq 'start') {
    if ($manifest.journal_binding.kind -cne 'genesis' -or $null -ne $manifest.journal_binding.prior_run_id -or
        $null -ne $manifest.journal_binding.prior_artifact_name -or $null -ne $manifest.journal_binding.terminal_record_sha256) {
      Throw-PreparedRule 'PREP10-JOURNAL-BINDING' 'Start journal binding is not genesis.'
    }
  } elseif ($manifest.journal_binding.kind -cne 'verified_prior_chain' -or [string]$manifest.journal_binding.prior_run_id -cne $PriorRunId -or
            [string]$manifest.journal_binding.prior_artifact_name -cne $PriorArtifactName -or
            [string]$manifest.journal_binding.terminal_record_sha256 -cne $PriorTerminalRecordSha256) {
    Throw-PreparedRule 'PREP10-JOURNAL-BINDING' 'Resume journal binding drifted.'
  }

  $payloads = @($manifest.payloads)
  if ($payloads.Count -ne $inventory.Count) { Throw-PreparedRule 'PREP03-INVENTORY' 'Payload count drifted.' }
  for ($i=0; $i -lt $payloads.Count; $i++) {
    $entry = $payloads[$i]
    Assert-PreparedClosedProperties "payload[$i]" $entry @('path','role','size','sha256')
    Assert-PreparedSafePath $entry.path
    if ($entry.path -ceq 'prepared-bundle.json') { Throw-PreparedRule 'PREP12-SELF-REFERENCE' 'Manifest cannot inventory itself.' }
    if ($entry.path -cne $inventory[$i].path -or $entry.role -cne $inventory[$i].role) { Throw-PreparedRule 'PREP03-INVENTORY' "Payload[$i] is not the fixed inventory record." }
  }

  $expectedFiles = @('prepared-bundle.json') + @($inventory.path)
  $actualFiles = @(
    Get-ChildItem -LiteralPath $absoluteRoot -Recurse -File | ForEach-Object {
      $_.FullName.Substring($absoluteRoot.Length).TrimStart([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar).Replace('\','/')
    } | Sort-Object -CaseSensitive
  )
  $expectedSorted = @($expectedFiles | Sort-Object -CaseSensitive)
  foreach ($expected in $expectedSorted) {
    if ($actualFiles -cnotcontains $expected) { Throw-PreparedRule 'PREP04-MISSING-PAYLOAD' "Missing '$expected'." }
  }
  foreach ($actual in $actualFiles) {
    if ($expectedSorted -cnotcontains $actual) { Throw-PreparedRule 'PREP06-EXTRA-PAYLOAD' "Unexpected '$actual'." }
  }

  foreach ($entry in $payloads) {
    $path = Join-Path $absoluteRoot ([string]$entry.path)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Throw-PreparedRule 'PREP04-MISSING-PAYLOAD' "Missing '$($entry.path)'." }
    $length = (Get-Item -LiteralPath $path).Length
    if ($length -le 0) { Throw-PreparedRule 'PREP05-EMPTY-PAYLOAD' "Empty '$($entry.path)'." }
    Assert-NoPreparedSecretMaterial $path
  }
  Assert-PreparedJournalBinding -Root $absoluteRoot
  Assert-PreparedIntentBinding -Root $absoluteRoot -Manifest $manifest
  foreach ($entry in $payloads) {
    $path = Join-Path $absoluteRoot ([string]$entry.path)
    $length = (Get-Item -LiteralPath $path).Length
    if ([Int64]$entry.size -ne $length) { Throw-PreparedRule 'PREP08-PAYLOAD-SIZE' "Size drifted for '$($entry.path)'." }
    if ([string]$entry.sha256 -cne (Get-PreparedSha256 $path)) { Throw-PreparedRule 'PREP07-PAYLOAD-DIGEST' "Digest drifted for '$($entry.path)'." }
  }
  return [pscustomobject]@{ manifest_path=$manifestPath; manifest_sha256=(Get-PreparedSha256 $manifestPath); payload_count=$payloads.Count }
}

if ($ValidateOnly) {
  Test-PreparedReleaseBundle -Root $OutputRoot
  return
}

$inputAbsolute = [IO.Path]::GetFullPath($InputRoot)
$outputAbsolute = [IO.Path]::GetFullPath($OutputRoot)
if ($inputAbsolute -eq $outputAbsolute) { Throw-PreparedRule 'PREP03-INVENTORY' 'Input and output roots must differ.' }
if (Test-Path -LiteralPath $outputAbsolute) {
  if (@(Get-ChildItem -LiteralPath $outputAbsolute -Force).Count -ne 0) { Throw-PreparedRule 'PREP03-INVENTORY' 'Output root must be empty.' }
} else { $null = New-Item -ItemType Directory -Force -Path $outputAbsolute }

foreach ($entry in $inventory) {
  Assert-PreparedSafePath $entry.path
  $source = Join-Path $inputAbsolute $entry.path
  if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { Throw-PreparedRule 'PREP04-MISSING-PAYLOAD' "Missing input '$($entry.path)'." }
  if ((Get-Item -LiteralPath $source).Length -le 0) { Throw-PreparedRule 'PREP05-EMPTY-PAYLOAD' "Empty input '$($entry.path)'." }
  Assert-NoPreparedSecretMaterial $source
  $destination = Join-Path $outputAbsolute $entry.path
  $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination)
  Copy-Item -LiteralPath $source -Destination $destination
}

$intent = Read-PreparedJson -Path (Join-Path $outputAbsolute 'intent/current.json') -Rule 'PREP09-BINDING'
$predecessor = if ($null -ne $intent.PSObject.Properties['predecessor_intent_sha256']) { $intent.predecessor_intent_sha256 } else { $null }
$journalBinding = if ($RunMode -ceq 'start') {
  [ordered]@{ kind='genesis'; prior_run_id=$null; prior_artifact_name=$null; terminal_record_sha256=$null }
} else {
  if ($PriorRunId -cnotmatch '^[1-9][0-9]*$' -or $PriorArtifactName -cnotmatch '^mnf-checkpoint-[a-z0-9-]+$' -or
      $PriorTerminalRecordSha256 -cnotmatch '^[0-9a-f]{64}$') { Throw-PreparedRule 'PREP10-JOURNAL-BINDING' 'Resume requires exact prior chain evidence.' }
  [ordered]@{ kind='verified_prior_chain'; prior_run_id=$PriorRunId; prior_artifact_name=$PriorArtifactName; terminal_record_sha256=$PriorTerminalRecordSha256 }
}
$payloads = foreach ($entry in $inventory) {
  $path = Join-Path $outputAbsolute $entry.path
  [ordered]@{ path=$entry.path; role=$entry.role; size=[Int64](Get-Item -LiteralPath $path).Length; sha256=(Get-PreparedSha256 $path) }
}
$manifest = [ordered]@{
  schema_version='mnf-release-prepared/1'; repository=$Repository; actor=$Actor; run_id=$RunId; run_attempt=$RunAttempt
  release_ref=$ReleaseRef; source_sha=$SourceSha; root_intent_sha256=$RootIntentSha256; intent_sha256=$IntentSha256
  intent_kind=[string]$intent.intent_kind; correction_sequence=[int]$intent.correction_sequence; predecessor_intent_sha256=$predecessor
  run_mode=$RunMode; journal_binding=$journalBinding; toolchain=$expectedToolchain; payloads=@($payloads)
}
$manifestPath = Join-Path $outputAbsolute 'prepared-bundle.json'
[IO.File]::WriteAllText($manifestPath,($manifest | ConvertTo-Json -Depth 100 -Compress),[Text.UTF8Encoding]::new($false))
$result = Test-PreparedReleaseBundle -Root $outputAbsolute
$artifactName = "mnf-prepared-$RootIntentSha256-$IntentSha256-$($result.manifest_sha256)"
[pscustomobject]@{ manifest_path=$result.manifest_path; manifest_sha256=$result.manifest_sha256; artifact_name=$artifactName; payload_count=$result.payload_count }
