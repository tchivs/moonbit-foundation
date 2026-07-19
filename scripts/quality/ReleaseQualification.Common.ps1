Set-StrictMode -Version Latest

function Throw-ReleaseRule {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][string]$Message)
  throw "$Id`: $Message"
}

function Read-ReleaseJson {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required JSON is missing: $Path" }
  try { return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100 } catch { throw "Invalid JSON '$Path': $($_.Exception.Message)" }
}

function Assert-ReleaseExactSequence {
  param([string]$Label, [object[]]$Actual, [object[]]$Expected)
  if ($Actual.Count -ne $Expected.Count) { throw "$Label count mismatch: expected $($Expected.Count), got $($Actual.Count)." }
  for ($i = 0; $i -lt $Expected.Count; $i++) {
    if ([string]$Actual[$i] -cne [string]$Expected[$i]) { throw "$Label mismatch at index $i`: expected '$($Expected[$i])', got '$($Actual[$i])'." }
  }
}

function Assert-ReleaseExactSet {
  param([string]$Label, [object[]]$Actual, [object[]]$Expected)
  $actualText = @($Actual | ForEach-Object { [string]$_ } | Sort-Object -CaseSensitive)
  $expectedText = @($Expected | ForEach-Object { [string]$_ } | Sort-Object -CaseSensitive)
  Assert-ReleaseExactSequence -Label $Label -Actual $actualText -Expected $expectedText
}

function Assert-ReleaseClosedProperties {
  param([string]$Label, [object]$Object, [string[]]$Expected)
  if ($null -eq $Object) { throw "$Label is missing." }
  Assert-ReleaseExactSet -Label "$Label properties" -Actual @($Object.PSObject.Properties | ForEach-Object { $_.Name }) -Expected $Expected
}

function Get-ReleaseTrackedDiffSnapshot {
  $output = @(& git diff --binary --no-ext-diff HEAD -- 2>&1 | ForEach-Object { $_.ToString() })
  if ($LASTEXITCODE -ne 0) { throw "Unable to capture tracked diff (exit $LASTEXITCODE)." }
  return ($output -join "`n")
}

function Get-ReleaseSha256 {
  param([Parameter(Mandatory)][string]$Path)
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function ConvertTo-ReleaseCanonicalZip {
  param([Parameter(Mandatory)][string]$Path)
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $full = [IO.Path]::GetFullPath($Path)
  if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { Throw-ReleaseRule -Id 'REL-XPLAT-ARCHIVE' -Message "Archive is missing: $full" }
  $records = [Collections.Generic.List[object]]::new()
  $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $source = [IO.Compression.ZipFile]::OpenRead($full)
  try {
    foreach ($entry in $source.Entries) {
      $name = [string]$entry.FullName
      if ([string]::IsNullOrEmpty($name) -or $name.Contains('\') -or [IO.Path]::IsPathRooted($name) -or $name -match '(^|/)[.][.](/|$)' -or -not $seen.Add($name)) { Throw-ReleaseRule -Id 'REL-XPLAT-ENTRY' -Message "Archive path is unsafe or duplicated: '$name'." }
      $stream = $entry.Open();$memory = [IO.MemoryStream]::new()
      try { $stream.CopyTo($memory);$bytes = $memory.ToArray() } finally { $memory.Dispose();$stream.Dispose() }
      $records.Add([pscustomobject][ordered]@{name=$name;is_directory=$name.EndsWith('/',[StringComparison]::Ordinal);bytes=[byte[]]$bytes})
    }
  } finally { $source.Dispose() }
  $before = Get-ReleaseSha256 -Path $full;$temporary = "$full.canonical-$([Guid]::NewGuid().ToString('N'))"
  try {
    $file = [IO.File]::Open($temporary,[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    try {
      $archive = [IO.Compression.ZipArchive]::new($file,[IO.Compression.ZipArchiveMode]::Create,$true,[Text.UTF8Encoding]::new($false))
      try {
        foreach ($record in $records) {
          $entry = $archive.CreateEntry([string]$record.name,[IO.Compression.CompressionLevel]::NoCompression)
          $entry.LastWriteTime = [DateTimeOffset]::new(1980,1,1,0,0,0,[TimeSpan]::Zero)
          $attributes = if ($record.is_directory) { [uint32]::Parse('41ED0000',[Globalization.NumberStyles]::HexNumber) } else { [uint32]::Parse('81A40000',[Globalization.NumberStyles]::HexNumber) }
          $entry.ExternalAttributes = [BitConverter]::ToInt32([BitConverter]::GetBytes($attributes),0)
          if (-not $record.is_directory) { $output = $entry.Open();try { $output.Write([byte[]]$record.bytes,0,$record.bytes.Length) } finally { $output.Dispose() } }
        }
      } finally { $archive.Dispose() }
    } finally { $file.Dispose() }
    $bytes = [IO.File]::ReadAllBytes($temporary);$centralCount=0
    for($offset=0;$offset-le$bytes.Length-46;$offset++){
      if($bytes[$offset]-ne0x50-or$bytes[$offset+1]-ne0x4b-or$bytes[$offset+2]-ne0x01-or$bytes[$offset+3]-ne0x02){continue}
      $nameLength=[BitConverter]::ToUInt16($bytes,$offset+28);$extraLength=[BitConverter]::ToUInt16($bytes,$offset+30);$commentLength=[BitConverter]::ToUInt16($bytes,$offset+32)
      if($offset+46+$nameLength+$extraLength+$commentLength-gt$bytes.Length){Throw-ReleaseRule -Id 'REL-XPLAT-ARCHIVE' -Message 'Canonical ZIP central directory is truncated.'}
      $name=[Text.Encoding]::UTF8.GetString($bytes,$offset+46,$nameLength);$bytes[$offset+4]=0x14;$bytes[$offset+5]=0x03
      $attributes=if($name.EndsWith('/',[StringComparison]::Ordinal)){[uint32]::Parse('41ED0000',[Globalization.NumberStyles]::HexNumber)}else{[uint32]::Parse('81A40000',[Globalization.NumberStyles]::HexNumber)};[BitConverter]::GetBytes($attributes).CopyTo($bytes,$offset+38)
      $centralCount++;$offset += 45+$nameLength+$extraLength+$commentLength
    }
    if($centralCount-ne$records.Count){Throw-ReleaseRule -Id 'REL-XPLAT-ARCHIVE' -Message "Canonical ZIP central count drifted: $centralCount vs $($records.Count)."}
    [IO.File]::WriteAllBytes($temporary,$bytes);[IO.File]::Move($temporary,$full,$true)
  } finally { if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force} }
  [pscustomobject][ordered]@{path=$full;entry_count=$records.Count;source_sha256=$before;canonical_sha256=Get-ReleaseSha256 -Path $full}
}

function Get-ReleaseTextSha256 {
  param([Parameter(Mandatory)][string]$Text)
  $algorithm = [Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text)
    return ([Convert]::ToHexString($algorithm.ComputeHash($bytes))).ToLowerInvariant()
  } finally { $algorithm.Dispose() }
}

function Get-ReleaseCanonicalPropertyOrder {
  param([Parameter(Mandatory)][object]$Object, [Parameter(Mandatory)][string]$Path)
  $actual = @($Object.PSObject.Properties.Name)
  $orders = @{
    '$.initial' = @('schema_version','intent_kind','repository','owner','release_ref','source_sha','correction_sequence','toolchain','modules','evidence','tracked_source_clean','credentials_read','publication_performed')
    '$.forward_correction' = @('schema_version','intent_kind','repository','owner','release_ref','source_sha','root_intent_sha256','predecessor_intent_sha256','correction_sequence','toolchain','modules','evidence','correction_evidence','tracked_source_clean','credentials_read','publication_performed')
    'toolchain' = @('moon','moonc','moonrun')
    'module' = @('module','identity','version','dependencies','public_packages','archive_sha256','interface_sha256')
    'dependency' = @('identity','version')
    'evidence' = @('qualification_root_sha256','required_stable_sha256','phase_06_ledger_sha256','release_policy_sha256','compatibility_policy_sha256')
    'correction_evidence' = @('superseded_intent_sha256','incident_sha256','advisory_sha256','compatibility_result_sha256','version_absence_sha256')
  }
  $kind = if ($Path -ceq '$') {
    if ($null -eq $Object.PSObject.Properties['intent_kind']) { Throw-ReleaseRule -Id 'REL01-UNKNOWN-PROPERTY' -Message 'canonical root lacks intent_kind.' }
    '$.' + [string]$Object.intent_kind
  } elseif ($Path -cmatch '[.]toolchain$') { 'toolchain' }
    elseif ($Path -cmatch '[.]modules\[[0-9]+\]$') { 'module' }
    elseif ($Path -cmatch '[.]dependencies\[[0-9]+\]$') { 'dependency' }
    elseif ($Path -cmatch '[.]evidence$') { 'evidence' }
    elseif ($Path -cmatch '[.]correction_evidence$') { 'correction_evidence' }
    else { Throw-ReleaseRule -Id 'REL01-UNSUPPORTED-SHAPE' -Message "unsupported canonical object at $Path." }
  $expected = @($orders[$kind])
  if ($expected.Count -eq 0) { Throw-ReleaseRule -Id 'REL01-UNSUPPORTED-SHAPE' -Message "unsupported canonical object at $Path." }
  try { Assert-ReleaseExactSet -Label "canonical properties at $Path" -Actual $actual -Expected $expected } catch {
    Throw-ReleaseRule -Id 'REL01-UNKNOWN-PROPERTY' -Message $_.Exception.Message
  }
  return $expected
}

function ConvertTo-ReleaseCanonicalValue {
  param([AllowNull()][object]$Value, [Parameter(Mandatory)][string]$Path)
  if ($null -eq $Value) { return $null }
  if ($Value -is [string]) {
    if ([string]::IsNullOrEmpty($Value)) { Throw-ReleaseRule -Id 'REL01-EMPTY' -Message "empty canonical string at $Path." }
    if ([string]$Value -cmatch '[^\x20-\x7e]') { Throw-ReleaseRule -Id 'REL01-CONTROLLED-ASCII' -Message "unexpected Unicode/control value at $Path." }
    return [string]$Value
  }
  if ($Value -is [bool]) { return [bool]$Value }
  if ($Value -is [byte] -or $Value -is [sbyte] -or $Value -is [int16] -or $Value -is [uint16] -or
      $Value -is [int32] -or $Value -is [uint32] -or $Value -is [int64] -or $Value -is [uint64]) {
    $number = [Int64]$Value
    if ($number -lt 0 -or $number -gt [Int32]::MaxValue) { Throw-ReleaseRule -Id 'REL01-NUMBER' -Message "integer outside canonical range at $Path." }
    return $number
  }
  if ($Value -is [float] -or $Value -is [double] -or $Value -is [decimal]) { Throw-ReleaseRule -Id 'REL01-NUMBER' -Message "floating-point value at $Path." }
  if ($Value -is [Collections.IDictionary]) {
    $object = [pscustomobject]$Value
    $order = Get-ReleaseCanonicalPropertyOrder -Object $object -Path $Path
    $result = [ordered]@{}
    foreach ($name in $order) {
      $child = $Value[$name]
      if ($name -cin @('modules','dependencies','public_packages')) {
        $items = [Collections.Generic.List[object]]::new(); $index = 0
        foreach ($item in @($child)) { $items.Add((ConvertTo-ReleaseCanonicalValue -Value $item -Path "$Path.$name[$index]")); $index++ }
        $result[$name] = [object[]]$items.ToArray()
      } else { $result[$name] = ConvertTo-ReleaseCanonicalValue -Value $child -Path "$Path.$name" }
    }
    return $result
  }
  if ($Value -is [Management.Automation.PSCustomObject]) {
    $order = Get-ReleaseCanonicalPropertyOrder -Object $Value -Path $Path
    $result = [ordered]@{}
    foreach ($name in $order) {
      $child = $Value.$name
      if ($name -cin @('modules','dependencies','public_packages')) {
        $items = [Collections.Generic.List[object]]::new(); $index = 0
        foreach ($item in @($child)) { $items.Add((ConvertTo-ReleaseCanonicalValue -Value $item -Path "$Path.$name[$index]")); $index++ }
        $result[$name] = [object[]]$items.ToArray()
      } else { $result[$name] = ConvertTo-ReleaseCanonicalValue -Value $child -Path "$Path.$name" }
    }
    return $result
  }
  if ($Value -is [Collections.IEnumerable]) {
    $items = [Collections.Generic.List[object]]::new()
    $index = 0
    foreach ($item in $Value) { $items.Add((ConvertTo-ReleaseCanonicalValue -Value $item -Path "$Path[$index]")); $index++ }
    return @($items)
  }
  Throw-ReleaseRule -Id 'REL01-UNSUPPORTED-SHAPE' -Message "unsupported canonical value type '$($Value.GetType().FullName)' at $Path."
}

function ConvertTo-ReleaseCanonicalJson {
  param([Parameter(Mandatory)][object]$Value, [ValidateSet('ReleaseIntent')][string]$Profile = 'ReleaseIntent')
  if ($Profile -cne 'ReleaseIntent') { Throw-ReleaseRule -Id 'REL01-CANONICAL-PROFILE' -Message "unsupported canonical profile '$Profile'." }
  $canonical = ConvertTo-ReleaseCanonicalValue -Value $Value -Path '$'
  return ($canonical | ConvertTo-Json -Depth 100 -Compress)
}

function Get-ReleaseCanonicalSha256 {
  param([Parameter(Mandatory)][object]$Value, [ValidateSet('ReleaseIntent')][string]$Profile = 'ReleaseIntent')
  return Get-ReleaseTextSha256 -Text (ConvertTo-ReleaseCanonicalJson -Value $Value -Profile $Profile)
}

function Read-ReleaseCanonicalJson {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Throw-ReleaseRule -Id 'REL01-MISSING-INTENT' -Message $Path }
  $bytes = [IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { Throw-ReleaseRule -Id 'REL01-ENCODING' -Message 'UTF-8 BOM is forbidden.' }
  try { $text = [Text.UTF8Encoding]::new($false, $true).GetString($bytes) } catch { Throw-ReleaseRule -Id 'REL01-ENCODING' -Message 'invalid UTF-8.' }
  if ([string]::IsNullOrEmpty($text) -or $text.Trim() -cne $text) { Throw-ReleaseRule -Id 'REL01-ENCODING' -Message 'empty or non-compact canonical bytes.' }
  try { $value = $text | ConvertFrom-Json -Depth 100 } catch { Throw-ReleaseRule -Id 'REL01-INVALID-JSON' -Message $_.Exception.Message }
  $canonical = ConvertTo-ReleaseCanonicalJson -Value $value -Profile ReleaseIntent
  if ($canonical -cne $text) { Throw-ReleaseRule -Id 'REL01-NONCANONICAL' -Message 'intent bytes are not the canonical schema-order projection.' }
  return $value
}

function Test-ReleaseSha256Text {
  param([AllowNull()][object]$Value)
  return $Value -is [string] -and [string]$Value -cmatch '^[0-9a-f]{64}$'
}

function ConvertTo-ReleaseCanonicalUtc {
  param([Parameter(Mandatory)][object]$Value)
  try {
    $instant = if ($Value -is [DateTimeOffset]) { $Value } elseif ($Value -is [DateTime]) { [DateTimeOffset]$Value } else {
      [DateTimeOffset]::Parse([string]$Value,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::RoundtripKind)
    }
  } catch { Throw-ReleaseRule -Id 'REL04-UTC' -Message 'timestamp is invalid.' }
  return $instant.UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ssZ',[Globalization.CultureInfo]::InvariantCulture)
}

function Get-ReleaseInitialHistoryBinding {
  $policy = Read-ReleaseJson -Path (Join-Path $PSScriptRoot '..\..\policy\release-control.json')
  $history = @($policy.initial_attempt_family.terminal_negative_history)
  if ($history.Count -ne 7 -or ($history.attempt -join ',') -cne 'attempt_zero,r1,r2,r3,r4,r5,r6') { Throw-ReleaseRule -Id 'REL04-HISTORY-BINDING' -Message 'canonical seven-attempt history is missing or reordered.' }
  $digests = @($history.record_sha256)
  if (@($digests | Where-Object { -not (Test-ReleaseSha256Text $_) } | Select-Object -Unique).Count -ne 0 -or @($digests | Select-Object -Unique).Count -ne 7) { Throw-ReleaseRule -Id 'REL04-HISTORY-BINDING' -Message 'history record digests are missing or duplicated.' }
  $set = Get-ReleaseTextSha256 -Text ($digests -join "`n")
  if ($set -cne [string]$policy.initial_attempt_family.history_set_sha256) { Throw-ReleaseRule -Id 'REL04-HISTORY-BINDING' -Message 'ordered history-set digest drifted.' }
  return [pscustomobject][ordered]@{
    historical_attempt_zero_sha256=[string]$digests[0];historical_r1_sha256=[string]$digests[1]
    historical_r2_sha256=[string]$digests[2];historical_r3_sha256=[string]$digests[3];historical_r4_sha256=[string]$digests[4];historical_r5_sha256=[string]$digests[5];historical_r6_sha256=[string]$digests[6];historical_history_set_sha256=$set
  }
}

function Get-ReleaseAuthorizationReceiptProjection {
  param([Parameter(Mandatory)][object]$Receipt)
  return [pscustomobject][ordered]@{
    schema_version=[string]$Receipt.schema_version;release_ref=[string]$Receipt.release_ref;boundary_sha=[string]$Receipt.boundary_sha;source_sha=[string]$Receipt.source_sha
    packet_sha256=[string]$Receipt.packet_sha256;historical_attempt_zero_sha256=[string]$Receipt.historical_attempt_zero_sha256
    historical_r1_sha256=[string]$Receipt.historical_r1_sha256;historical_r2_sha256=[string]$Receipt.historical_r2_sha256;historical_r3_sha256=[string]$Receipt.historical_r3_sha256;historical_r4_sha256=[string]$Receipt.historical_r4_sha256;historical_r5_sha256=[string]$Receipt.historical_r5_sha256;historical_r6_sha256=[string]$Receipt.historical_r6_sha256
    historical_history_set_sha256=[string]$Receipt.historical_history_set_sha256;response=[string]$Receipt.response;created_at_utc=(ConvertTo-ReleaseCanonicalUtc $Receipt.created_at_utc)
  }
}

function New-ReleaseAuthorizationReceipt {
  param([Parameter(Mandatory)][string]$BoundarySha,[Parameter(Mandatory)][string]$SourceSha,[Parameter(Mandatory)][string]$PacketSha256,[Parameter(Mandatory)][object]$CreatedAt)
  $history=Get-ReleaseInitialHistoryBinding
  $value=[pscustomobject][ordered]@{
    schema_version='mnf-phase08-authorization-receipt/1';release_ref='refs/tags/modules-v0.1.0-r7';boundary_sha=$BoundarySha;source_sha=$SourceSha
    packet_sha256=$PacketSha256;historical_attempt_zero_sha256=$history.historical_attempt_zero_sha256;historical_r1_sha256=$history.historical_r1_sha256
    historical_r2_sha256=$history.historical_r2_sha256;historical_r3_sha256=$history.historical_r3_sha256;historical_r4_sha256=$history.historical_r4_sha256;historical_r5_sha256=$history.historical_r5_sha256;historical_r6_sha256=$history.historical_r6_sha256;historical_history_set_sha256=$history.historical_history_set_sha256
    response='authorize-core';created_at_utc=(ConvertTo-ReleaseCanonicalUtc $CreatedAt);receipt_sha256=''
  }
  $value.receipt_sha256=Get-ReleaseTextSha256 -Text ((Get-ReleaseAuthorizationReceiptProjection $value)|ConvertTo-Json -Depth 20 -Compress)
  $null=Assert-ReleaseAuthorizationReceipt -Receipt $value -ExpectedBoundarySha $BoundarySha -ExpectedSourceSha $SourceSha -ExpectedPacketSha256 $PacketSha256
  return $value
}

function Assert-ReleaseAuthorizationReceipt {
  param([Parameter(Mandatory)][object]$Receipt,[string]$ExpectedBoundarySha,[string]$ExpectedSourceSha,[string]$ExpectedPacketSha256)
  try { Assert-ReleaseExactSequence -Label 'authorization receipt properties' -Actual @($Receipt.PSObject.Properties.Name) -Expected @('schema_version','release_ref','boundary_sha','source_sha','packet_sha256','historical_attempt_zero_sha256','historical_r1_sha256','historical_r2_sha256','historical_r3_sha256','historical_r4_sha256','historical_r5_sha256','historical_r6_sha256','historical_history_set_sha256','response','created_at_utc','receipt_sha256') } catch {
    Throw-ReleaseRule -Id 'REL04-RECEIPT-CLOSED' -Message $_.Exception.Message
  }
  if ($Receipt.schema_version -cne 'mnf-phase08-authorization-receipt/1' -or $Receipt.release_ref -cne 'refs/tags/modules-v0.1.0-r7' -or
      $Receipt.boundary_sha -cnotmatch '^[0-9a-f]{40}$' -or $Receipt.source_sha -cnotmatch '^[0-9a-f]{40}$' -or $Receipt.packet_sha256 -cnotmatch '^[0-9a-f]{64}$' -or $Receipt.response -cne 'authorize-core') {
    Throw-ReleaseRule -Id 'REL04-RECEIPT-BINDING' -Message 'receipt identity, response, or digest binding drifted.'
  }
  $receiptUtc=ConvertTo-ReleaseCanonicalUtc $Receipt.created_at_utc
  if ($Receipt.created_at_utc -is [string] -and [string]$Receipt.created_at_utc -cne $receiptUtc) { Throw-ReleaseRule -Id 'REL04-UTC' -Message 'receipt time is not canonical UTC Z.' }
  $history=Get-ReleaseInitialHistoryBinding
  foreach($name in @('historical_attempt_zero_sha256','historical_r1_sha256','historical_r2_sha256','historical_r3_sha256','historical_r4_sha256','historical_r5_sha256','historical_r6_sha256','historical_history_set_sha256')){if([string]$Receipt.$name -cne [string]$history.$name){Throw-ReleaseRule -Id 'REL04-HISTORY-BINDING' -Message "receipt history binding drifted for $name."}}
  if (-not [string]::IsNullOrEmpty($ExpectedBoundarySha) -and $Receipt.boundary_sha -cne $ExpectedBoundarySha -or
      -not [string]::IsNullOrEmpty($ExpectedSourceSha) -and $Receipt.source_sha -cne $ExpectedSourceSha -or
      -not [string]::IsNullOrEmpty($ExpectedPacketSha256) -and $Receipt.packet_sha256 -cne $ExpectedPacketSha256) { Throw-ReleaseRule -Id 'REL04-RECEIPT-BINDING' -Message 'receipt does not bind the expected packet/boundary.' }
  $digest=Get-ReleaseTextSha256 -Text ((Get-ReleaseAuthorizationReceiptProjection $Receipt)|ConvertTo-Json -Depth 20 -Compress)
  if ($Receipt.receipt_sha256 -cne $digest) { Throw-ReleaseRule -Id 'REL04-RECEIPT-DIGEST' -Message 'receipt digest drifted.' }
  return $digest
}

function Get-ReleasePhase08HandoffProjection {
  param([Parameter(Mandatory)][object]$Handoff)
  $projection=[ordered]@{}
  foreach($name in @('schema_version','release_ref','boundary_sha','execution_root','boundary_locator_path','boundary_locator_sha256','active_attempt_path','active_attempt_sha256','artifact_root','artifact_index_path','artifact_index_sha256','attempt_zero_history_path','attempt_zero_history_sha256','r1_history_path','r1_history_sha256','r2_history_path','r2_history_sha256','r3_history_path','r3_history_sha256','r4_history_path','r4_history_sha256','r5_history_path','r5_history_sha256','r6_history_path','r6_history_sha256','historical_history_set_sha256','authority_variant','mutation_authorization_packet_path','mutation_authorization_packet_sha256','authorization_receipt_path','authorization_receipt_sha256','exact_existing_authority_path','exact_existing_authority_sha256','created_at_utc')){$projection[$name]=if($name -ceq 'created_at_utc'){ConvertTo-ReleaseCanonicalUtc $Handoff.$name}else{$Handoff.$name}}
  return [pscustomobject]$projection
}

function Assert-ReleasePhase08RootedPath {
  param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$Root)
  if (-not [IO.Path]::IsPathRooted($Path)) { Throw-ReleaseRule -Id 'REL04-HANDOFF-PATH' -Message "relative path '$Path' is forbidden." }
  $full=[IO.Path]::GetFullPath($Path);$rootFull=[IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
  if ($full -cne $rootFull -and -not $full.StartsWith($rootFull+[IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)) { Throw-ReleaseRule -Id 'REL04-HANDOFF-PATH' -Message "path '$full' escapes execution root." }
  return $full
}

function New-ReleasePhase08Handoff {
  param([Parameter(Mandatory)][Collections.IDictionary]$Bindings,[Parameter(Mandatory)][ValidateSet('mutation_authorized','exact_existing')][string]$AuthorityVariant,[Parameter(Mandatory)][object]$CreatedAt)
  $value=[ordered]@{}
  foreach($name in @('schema_version','release_ref','boundary_sha','execution_root','boundary_locator_path','boundary_locator_sha256','active_attempt_path','active_attempt_sha256','artifact_root','artifact_index_path','artifact_index_sha256','attempt_zero_history_path','attempt_zero_history_sha256','r1_history_path','r1_history_sha256','r2_history_path','r2_history_sha256','r3_history_path','r3_history_sha256','r4_history_path','r4_history_sha256','r5_history_path','r5_history_sha256','r6_history_path','r6_history_sha256','historical_history_set_sha256')){
    if(-not $Bindings.Contains($name)){Throw-ReleaseRule -Id 'REL04-HANDOFF-CLOSED' -Message "missing binding '$name'."};$value[$name]=$Bindings[$name]
  }
  $value.authority_variant=$AuthorityVariant
  foreach($name in @('mutation_authorization_packet_path','mutation_authorization_packet_sha256','authorization_receipt_path','authorization_receipt_sha256','exact_existing_authority_path','exact_existing_authority_sha256')){
    if(-not $Bindings.Contains($name)){Throw-ReleaseRule -Id 'REL04-HANDOFF-CLOSED' -Message "missing authority binding '$name'."};$value[$name]=$Bindings[$name]
  }
  $value.created_at_utc=ConvertTo-ReleaseCanonicalUtc $CreatedAt;$value.handoff_sha256=''
  $result=[pscustomobject]$value
  $result.handoff_sha256=Get-ReleaseTextSha256 -Text ((Get-ReleasePhase08HandoffProjection $result)|ConvertTo-Json -Depth 30 -Compress)
  $null=Assert-ReleasePhase08Handoff -Handoff $result
  return $result
}

function Assert-ReleasePhase08Handoff {
  param([Parameter(Mandatory)][object]$Handoff)
  $fields=@('schema_version','release_ref','boundary_sha','execution_root','boundary_locator_path','boundary_locator_sha256','active_attempt_path','active_attempt_sha256','artifact_root','artifact_index_path','artifact_index_sha256','attempt_zero_history_path','attempt_zero_history_sha256','r1_history_path','r1_history_sha256','r2_history_path','r2_history_sha256','r3_history_path','r3_history_sha256','r4_history_path','r4_history_sha256','r5_history_path','r5_history_sha256','r6_history_path','r6_history_sha256','historical_history_set_sha256','authority_variant','mutation_authorization_packet_path','mutation_authorization_packet_sha256','authorization_receipt_path','authorization_receipt_sha256','exact_existing_authority_path','exact_existing_authority_sha256','created_at_utc','handoff_sha256')
  try { Assert-ReleaseExactSequence -Label 'phase 8 handoff properties' -Actual @($Handoff.PSObject.Properties.Name) -Expected $fields } catch { Throw-ReleaseRule -Id 'REL04-HANDOFF-CLOSED' -Message $_.Exception.Message }
  if ($Handoff.schema_version -cne 'mnf-phase08-handoff/1' -or $Handoff.release_ref -cne 'refs/tags/modules-v0.1.0-r7' -or $Handoff.boundary_sha -cnotmatch '^[0-9a-f]{40}$') { Throw-ReleaseRule -Id 'REL04-HANDOFF-BINDING' -Message 'handoff identity drifted.' }
  $handoffUtc=ConvertTo-ReleaseCanonicalUtc $Handoff.created_at_utc
  if ($Handoff.created_at_utc -is [string] -and [string]$Handoff.created_at_utc -cne $handoffUtc) { Throw-ReleaseRule -Id 'REL04-UTC' -Message 'handoff time is not canonical UTC Z.' }
  $root=Assert-ReleasePhase08RootedPath $Handoff.execution_root $Handoff.execution_root
  $filePairs=@('boundary_locator_path','boundary_locator_sha256','active_attempt_path','active_attempt_sha256','artifact_index_path','artifact_index_sha256','attempt_zero_history_path','attempt_zero_history_sha256','r1_history_path','r1_history_sha256','r2_history_path','r2_history_sha256','r3_history_path','r3_history_sha256','r4_history_path','r4_history_sha256','r5_history_path','r5_history_sha256','r6_history_path','r6_history_sha256')
  $null=Assert-ReleasePhase08RootedPath $Handoff.artifact_root $root
  for($i=0;$i -lt $filePairs.Count;$i+=2){$pathName=$filePairs[$i];$digestName=$filePairs[$i+1];$path=Assert-ReleasePhase08RootedPath ([string]$Handoff.$pathName) $root;if(-not(Test-Path -LiteralPath $path -PathType Leaf)-or(Get-ReleaseSha256 $path)-cne [string]$Handoff.$digestName){Throw-ReleaseRule -Id 'REL04-HANDOFF-DIGEST' -Message "digest drifted for $pathName."}}
  $history=Get-ReleaseInitialHistoryBinding
  foreach($pair in @(@('attempt_zero_history_sha256','historical_attempt_zero_sha256'),@('r1_history_sha256','historical_r1_sha256'),@('r2_history_sha256','historical_r2_sha256'),@('r3_history_sha256','historical_r3_sha256'),@('r4_history_sha256','historical_r4_sha256'),@('r5_history_sha256','historical_r5_sha256'),@('r6_history_sha256','historical_r6_sha256'))){if([string]$Handoff.($pair[0]) -cne [string]$history.($pair[1])){Throw-ReleaseRule -Id 'REL04-HISTORY-BINDING' -Message "handoff history binding drifted for $($pair[0])."}}
  if([string]$Handoff.historical_history_set_sha256 -cne [string]$history.historical_history_set_sha256){Throw-ReleaseRule -Id 'REL04-HISTORY-BINDING' -Message 'handoff history-set digest drifted.'}
  if ($Handoff.authority_variant -ceq 'mutation_authorized') {
    if ([string]::IsNullOrWhiteSpace([string]$Handoff.mutation_authorization_packet_path) -or [string]::IsNullOrWhiteSpace([string]$Handoff.authorization_receipt_path) -or
        $null -ne $Handoff.exact_existing_authority_path -or $null -ne $Handoff.exact_existing_authority_sha256) { Throw-ReleaseRule -Id 'REL04-HANDOFF-BRANCH' -Message 'mutation branch requires packet+receipt and forbids exact-existing.' }
    $filePairs=@('mutation_authorization_packet_path','mutation_authorization_packet_sha256','authorization_receipt_path','authorization_receipt_sha256')
  } elseif ($Handoff.authority_variant -ceq 'exact_existing') {
    if ($null -ne $Handoff.mutation_authorization_packet_path -or $null -ne $Handoff.mutation_authorization_packet_sha256 -or $null -ne $Handoff.authorization_receipt_path -or $null -ne $Handoff.authorization_receipt_sha256 -or
        [string]::IsNullOrWhiteSpace([string]$Handoff.exact_existing_authority_path)) { Throw-ReleaseRule -Id 'REL04-HANDOFF-BRANCH' -Message 'exact-existing forbids packet/receipt and requires exact authority.' }
    $filePairs=@('exact_existing_authority_path','exact_existing_authority_sha256')
  } else { Throw-ReleaseRule -Id 'REL04-HANDOFF-BRANCH' -Message 'stop or unknown authority is ineligible.' }
  for($i=0;$i -lt $filePairs.Count;$i+=2){$pathName=$filePairs[$i];$digestName=$filePairs[$i+1];$path=Assert-ReleasePhase08RootedPath ([string]$Handoff.$pathName) $root;if(-not(Test-Path -LiteralPath $path -PathType Leaf)-or(Get-ReleaseSha256 $path)-cne [string]$Handoff.$digestName){Throw-ReleaseRule -Id 'REL04-HANDOFF-DIGEST' -Message "digest drifted for $pathName."}}
  $digest=Get-ReleaseTextSha256 -Text ((Get-ReleasePhase08HandoffProjection $Handoff)|ConvertTo-Json -Depth 30 -Compress)
  if($Handoff.handoff_sha256 -cne $digest){Throw-ReleaseRule -Id 'REL04-HANDOFF-DIGEST' -Message 'handoff digest drifted.'}
  return $digest
}

function Assert-ReleaseActorEvidence {
  param([Parameter(Mandatory)][object]$Evidence, [Parameter(Mandatory)][object]$Policy)
  $fields = @(
    'expected_actor','observed_actor','actor_check_classification','actor_exit_code','actor_stdout_line_count',
    'actor_stderr_empty','actor_match','actor_raw_output_persisted','credential_state_removed','mutation_performed',
    'command_classification'
  )
  try { Assert-ReleaseClosedProperties -Label 'publisher actor evidence' -Object $Evidence -Expected $fields } catch {
    Throw-ReleaseRule -Id 'REL03-ACTOR' -Message $_.Exception.Message
  }
  $expected = $Policy.actor_policy
  foreach ($field in $fields) {
    if ($null -eq $expected.PSObject.Properties[$field] -or [string]$Evidence.$field -cne [string]$expected.$field) {
      Throw-ReleaseRule -Id 'REL03-ACTOR' -Message "actor evidence field '$field' is not the exact sanitized policy value."
    }
  }
  foreach ($value in @($Evidence.expected_actor,$Evidence.observed_actor)) {
    if ([string]$value -cmatch '(?i)(token|secret|password|cookie|authorization|bearer)|[\r\n]') {
      Throw-ReleaseRule -Id 'REL03-ACTOR' -Message 'actor evidence contains a secret-shaped or multiline value.'
    }
  }
  return $true
}

function Assert-ReleaseIntentObject {
  param(
    [Parameter(Mandatory)][object]$Intent,
    [Parameter(Mandatory)][string]$PolicyPath,
    [string]$ExpectedCurrentSha256,
    [string]$ExpectedRootSha256,
    [string]$ExpectedPredecessorSha256,
    [int]$ExpectedPredecessorSequence = -1,
    [string]$AuthorizedSuccessorSha256
  )
  $policy = Read-ReleaseJson -Path $PolicyPath
  $kind = [string]$Intent.intent_kind
  if ($kind -cnotin @('initial','forward_correction')) { Throw-ReleaseRule -Id 'REL01-INTENT-KIND' -Message 'unknown intent kind.' }
  $null = ConvertTo-ReleaseCanonicalJson -Value $Intent -Profile ReleaseIntent
  if ($Intent.schema_version -cne 'mnf-release-intent/1' -or $Intent.repository -cne $policy.repository -or $Intent.owner -cne $policy.owner) {
    Throw-ReleaseRule -Id 'REL01-IDENTITY' -Message 'intent identity drifted.'
  }
  foreach ($tool in @('moon','moonc','moonrun')) {
    if ([string]$Intent.toolchain.$tool -cne [string]$policy.pinned_toolchain.$tool) { Throw-ReleaseRule -Id 'REL01-TOOLCHAIN' -Message "pinned $tool identity drifted." }
  }
  if ([string]$Intent.source_sha -cnotmatch '^[0-9a-f]{40}$') { Throw-ReleaseRule -Id 'REL01-EMPTY' -Message 'source SHA is missing or malformed.' }
  if ($Intent.tracked_source_clean -ne $true) { Throw-ReleaseRule -Id 'REL01-DIRTY-SOURCE' -Message 'source is not qualified clean.' }
  if ($Intent.credentials_read -ne $false -or $Intent.publication_performed -ne $false) { Throw-ReleaseRule -Id 'REL01-AUTHORITY-CONFLATION' -Message 'intent fabricated credentials or publication.' }
  foreach ($field in @('qualification_root_sha256','required_stable_sha256','phase_06_ledger_sha256','release_policy_sha256','compatibility_policy_sha256')) {
    if (-not (Test-ReleaseSha256Text $Intent.evidence.$field)) { Throw-ReleaseRule -Id 'REL01-EVIDENCE' -Message "missing or malformed evidence $field." }
  }
  try { Assert-ReleaseExactSequence -Label 'intent module order' -Actual @($Intent.modules.module) -Expected @($policy.module_order.module) } catch {
    Throw-ReleaseRule -Id 'REL01-MODULE-ORDER' -Message $_.Exception.Message
  }
  for ($i = 0; $i -lt $policy.module_order.Count; $i++) {
    $expected = $policy.module_order[$i]
    $module = $Intent.modules[$i]
    if ($module.identity -cne $expected.identity -or -not (Test-ReleaseSha256Text $module.archive_sha256) -or -not (Test-ReleaseSha256Text $module.interface_sha256)) {
      Throw-ReleaseRule -Id 'REL01-MODULE-BINDING' -Message "module binding drifted for $($expected.module)."
    }
    if (@($module.public_packages).Count -eq 0) { Throw-ReleaseRule -Id 'REL01-EMPTY' -Message "package inventory is empty for $($expected.module)." }
    $releasePolicy = Read-ReleaseJson -Path (Join-Path (Split-Path -Parent $PolicyPath) 'release-qualification.json')
    try { Assert-ReleaseExactSequence -Label "$($expected.module) public packages" -Actual @($module.public_packages) -Expected @($releasePolicy.modules.$($expected.module).public_packages) } catch {
      Throw-ReleaseRule -Id 'REL01-PACKAGE-INVENTORY' -Message $_.Exception.Message
    }
    if ($kind -ceq 'initial') {
      if ($module.version -cne $expected.initial_version) { Throw-ReleaseRule -Id 'REL01-INITIAL-VERSION' -Message "initial version drifted for $($expected.module)." }
      $deps = @($module.dependencies | ForEach-Object { "$($_.identity)@$($_.version)" })
      try { Assert-ReleaseExactSequence -Label "$($expected.module) initial dependencies" -Actual $deps -Expected @($expected.initial_dependencies) } catch {
        Throw-ReleaseRule -Id 'REL01-DEPENDENCY-CLOSURE' -Message $_.Exception.Message
      }
    }
  }
  $current = Get-ReleaseCanonicalSha256 -Value $Intent -Profile ReleaseIntent
  if ($kind -ceq 'initial') {
    if ($Intent.release_ref -cne $policy.initial_profile.release_ref -or $Intent.correction_sequence -ne 0) { Throw-ReleaseRule -Id 'REL01-REF' -Message 'initial ref or sequence drifted.' }
    if (@($policy.initial_attempt_family.terminal_negative_history.source_sha) -ccontains [string]$Intent.source_sha) { Throw-ReleaseRule -Id 'REL01-HISTORICAL-SOURCE' -Message 'terminal attempt-zero, r1, r2, r3, r4, r5, or r6 source cannot be current r7 authority.' }
  } else {
    if ($Intent.release_ref -cnotmatch $policy.correction_profile.release_ref_pattern) { Throw-ReleaseRule -Id 'REL01-CORRECTION-TAG' -Message 'correction tag is noncanonical.' }
    if (-not (Test-ReleaseSha256Text $Intent.root_intent_sha256) -or $Intent.root_intent_sha256 -ceq $current) { Throw-ReleaseRule -Id 'REL01-ROOT-DRIFT' -Message 'correction root is invalid or conflated with current digest.' }
    if (-not [string]::IsNullOrEmpty($ExpectedRootSha256) -and $Intent.root_intent_sha256 -cne $ExpectedRootSha256) { Throw-ReleaseRule -Id 'REL01-ROOT-DRIFT' -Message 'immutable root changed.' }
    if (-not [string]::IsNullOrEmpty($ExpectedPredecessorSha256) -and $Intent.predecessor_intent_sha256 -cne $ExpectedPredecessorSha256) { Throw-ReleaseRule -Id 'REL01-STALE-PREDECESSOR' -Message 'predecessor is not latest.' }
    if ($ExpectedPredecessorSequence -ge 0 -and $Intent.correction_sequence -ne ($ExpectedPredecessorSequence + 1)) { Throw-ReleaseRule -Id 'REL01-SEQUENCE' -Message 'correction sequence is not predecessor plus one.' }
    if (-not [string]::IsNullOrEmpty($AuthorizedSuccessorSha256) -and $current -cne $AuthorizedSuccessorSha256) { Throw-ReleaseRule -Id 'REL01-STALE-FORK' -Message 'candidate is not the selected successor.' }
    foreach ($field in @('superseded_intent_sha256','incident_sha256','advisory_sha256','compatibility_result_sha256','version_absence_sha256')) {
      if (-not (Test-ReleaseSha256Text $Intent.correction_evidence.$field)) { Throw-ReleaseRule -Id 'REL01-CORRECTION-EVIDENCE' -Message "missing correction evidence $field." }
    }
    if ($Intent.correction_evidence.superseded_intent_sha256 -cne $Intent.predecessor_intent_sha256) { Throw-ReleaseRule -Id 'REL01-STALE-PREDECESSOR' -Message 'superseded digest differs from predecessor.' }
    $versions = @{}; foreach ($module in @($Intent.modules)) { $versions[[string]$module.identity] = [string]$module.version }
    foreach ($module in @($Intent.modules)) {
      if ([string]$module.version -cnotmatch '^0[.]([1-9][0-9]*|0)[.]([0-9]+)$' -or [version]$module.version -le [version]'0.1.0') { Throw-ReleaseRule -Id 'REL01-FORWARD-VERSION' -Message "correction version is not forward for $($module.module)." }
      foreach ($dep in @($module.dependencies)) {
        if (-not $versions.ContainsKey([string]$dep.identity) -or $dep.version -cne $versions[[string]$dep.identity]) { Throw-ReleaseRule -Id 'REL01-DEPENDENCY-CLOSURE' -Message "stale correction dependency in $($module.module)." }
      }
    }
  }
  if (-not [string]::IsNullOrEmpty($ExpectedCurrentSha256) -and $current -cne $ExpectedCurrentSha256) { Throw-ReleaseRule -Id 'REL01-DIGEST' -Message 'current intent digest mismatch.' }
  return $current
}

function Assert-ReleaseIntentAuthorizationBinding {
  param([Parameter(Mandatory)][object]$Intent, [Parameter(Mandatory)][string]$IntentSha256, [Parameter(Mandatory)][string]$RootIntentSha256)
  if ($Intent.intent_kind -ceq 'initial' -and $IntentSha256 -cne $RootIntentSha256) { Throw-ReleaseRule -Id 'REL01-INITIAL-ROOT-BINDING' -Message 'initial root must equal current intent digest.' }
  if ($Intent.intent_kind -ceq 'forward_correction' -and $Intent.root_intent_sha256 -cne $RootIntentSha256) { Throw-ReleaseRule -Id 'REL01-ROOT-DRIFT' -Message 'correction root binding drifted.' }
}

function Assert-ReleaseIntentRecovery {
  param([ValidateSet('initial','forward_correction')][string]$IntentKind, [switch]$ObservedMismatch)
  if ($ObservedMismatch) { Throw-ReleaseRule -Id 'REL01-TERMINAL-MISMATCH' -Message "$IntentKind intent is terminal after mismatch; create a fresh forward correction." }
}

function Assert-StaticRequirementLedger {
  param([Parameter(Mandatory)][string]$Path)
  $ledger = Read-ReleaseJson -Path $Path
  Assert-ReleaseClosedProperties -Label 'v0.1 requirement ledger' -Object $ledger -Expected @(
    'schema_version', 'candidate', 'required_entrypoint', 'selectors', 'requirements', 'artifact_contracts', 'allowed_blocked_outcomes'
  )
  if ($ledger.schema_version -cne '1.0.0' -or $ledger.candidate -cne 'v0.1' -or
      $ledger.required_entrypoint -cne 'pwsh -NoProfile -File scripts/quality.ps1 -Lane Required -EvidenceDirectory <untracked-evidence-directory>') {
    throw 'Static requirement ledger identity or Required entrypoint drifted.'
  }
  $forbiddenProperties = [Collections.Generic.List[string]]::new()
  function Find-DynamicProperty([object]$Value, [string]$At) {
    if ($null -eq $Value) { return }
    if ($Value -is [string] -or $Value -is [ValueType]) { return }
    if ($Value -is [Collections.IEnumerable] -and $Value -isnot [Management.Automation.PSCustomObject]) {
      $index = 0
      foreach ($item in $Value) { Find-DynamicProperty -Value $item -At "$At[$index]"; $index++ }
      return
    }
    foreach ($property in @($Value.PSObject.Properties)) {
      if ($property.Name -cmatch '^(?:run(?:_?id)?|timestamp|commit|result|environment|digest|sha256|head)$') {
        $forbiddenProperties.Add("$At.$($property.Name)")
      }
      Find-DynamicProperty -Value $property.Value -At "$At.$($property.Name)"
    }
  }
  Find-DynamicProperty -Value $ledger -At '$'
  if ($forbiddenProperties.Count -ne 0) {
    throw "Static requirement ledger contains dynamic evidence properties: $($forbiddenProperties -join ', ')."
  }

  $selectorIds = @($ledger.selectors | ForEach-Object { [string]$_.id })
  if ($selectorIds.Count -ne 19 -or @($selectorIds | Sort-Object -Unique).Count -ne $selectorIds.Count) {
    throw 'Static requirement ledger must contain exactly 19 unique ordered selectors.'
  }
  foreach ($selector in @($ledger.selectors)) {
    Assert-ReleaseClosedProperties -Label "selector $($selector.id)" -Object $selector -Expected @('id', 'focused_command', 'proves', 'policy_rule_ids')
    if ([string]::IsNullOrWhiteSpace([string]$selector.focused_command) -or @($selector.proves).Count -eq 0) {
      throw "Selector '$($selector.id)' lacks an executable focused command or requirement ownership."
    }
  }
  $requirementIds = @('WORK-06', 'QUAL-01', 'QUAL-02', 'QUAL-03', 'QUAL-04', 'QUAL-05', 'QUAL-06')
  Assert-ReleaseExactSet -Label 'ledger requirement IDs' -Actual @($ledger.requirements.PSObject.Properties.Name) -Expected $requirementIds
  foreach ($id in $requirementIds) {
    $mapped = @($ledger.requirements.$id | ForEach-Object { [string]$_ })
    if ($mapped.Count -eq 0) { throw "Requirement '$id' has no selectors." }
    foreach ($selectorId in $mapped) {
      if ($selectorIds -cnotcontains $selectorId) { throw "Requirement '$id' references unknown selector '$selectorId'." }
      $owner = @($ledger.selectors | Where-Object { [string]$_.id -ceq $selectorId })[0]
      if (@($owner.proves | ForEach-Object { [string]$_ }) -cnotcontains $id) {
        throw "Selector '$selectorId' does not reciprocally claim requirement '$id'."
      }
    }
  }
  Assert-ReleaseExactSequence -Label 'artifact contracts' -Actual @($ledger.artifact_contracts.id) -Expected @(
    'foundation-policy', 'fixture-manifest', 'example-consumers', 'benchmark-baseline', 'release-packages'
  )
  foreach ($artifact in @($ledger.artifact_contracts)) {
    $properties = @($artifact.PSObject.Properties.Name)
    if ($properties.Count -ne 3 -or $properties -cnotcontains 'id' -or $properties -cnotcontains 'schema' -or
        (($properties -ccontains 'tracked_path') -eq ($properties -ccontains 'dynamic_path'))) {
      throw "Artifact contract '$($artifact.id)' is not a closed tracked-or-dynamic schema mapping."
    }
  }
  Assert-ReleaseExactSequence -Label 'allowed blocked outcomes' -Actual @($ledger.allowed_blocked_outcomes) -Expected @(
    'mb-color.artifact_consumer=blocked_unpublished_dependency',
    'mb-color.registry_resolution=blocked_unpublished_namespace',
    'mb-image.artifact_consumer=blocked_unpublished_dependency',
    'mb-image.registry_resolution=blocked_unpublished_namespace'
  )
  return $ledger
}

function Get-RequiredRunStableObject {
  param([Parameter(Mandatory)][object]$Report)
  return [ordered]@{
    schema_version = [string]$Report.schema_version
    head = [string]$Report.head
    ledger_sha256 = [string]$Report.ledger_sha256
    selector_order = @($Report.selector_order)
    selectors = @($Report.selectors)
    artifacts = @($Report.artifacts)
    publication = $Report.publication
    tracked_diff_unchanged = [bool]$Report.tracked_diff_unchanged
  }
}

function Write-RequiredQualificationReport {
  param(
    [Parameter(Mandatory)][string]$RepoRoot,
    [Parameter(Mandatory)][string]$EvidenceDirectory,
    [Parameter(Mandatory)][string]$StartedUtc
  )
  $ledgerPath = Join-Path $RepoRoot 'release\qualification\v0.1-requirements.json'
  $ledger = Assert-StaticRequirementLedger -Path $ledgerPath
  $absoluteEvidence = if ([IO.Path]::IsPathRooted($EvidenceDirectory)) { [IO.Path]::GetFullPath($EvidenceDirectory) } else { [IO.Path]::GetFullPath((Join-Path $RepoRoot $EvidenceDirectory)) }
  $null = New-Item -ItemType Directory -Force -Path $absoluteEvidence
  $head = (& git -C $RepoRoot rev-parse HEAD).Trim()
  if ($LASTEXITCODE -ne 0 -or $head -cnotmatch '^[0-9a-f]{40}$') { throw 'Unable to identify Required report HEAD.' }
  $artifacts = [Collections.Generic.List[object]]::new()
  foreach ($contract in @($ledger.artifact_contracts)) {
    $schemaPath = Join-Path $RepoRoot ([string]$contract.schema)
    $evidencePath = if ($null -ne $contract.PSObject.Properties['tracked_path']) {
      Join-Path $RepoRoot ([string]$contract.tracked_path)
    } else {
      Join-Path $absoluteEvidence ([string]$contract.dynamic_path)
    }
    if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $evidencePath -PathType Leaf)) {
      throw "Required artifact '$($contract.id)' is missing its schema or evidence."
    }
    $artifacts.Add([ordered]@{
      id = [string]$contract.id
      schema_sha256 = Get-ReleaseSha256 -Path $schemaPath
      evidence_sha256 = Get-ReleaseSha256 -Path $evidencePath
    })
  }
  $releaseReport = Read-ReleaseJson -Path (Join-Path $absoluteEvidence 'release\report.json')
  if ($releaseReport.head -cne $head) { throw 'Nested release report HEAD differs from Required report HEAD.' }
  Assert-ReleaseCandidateOutcomes -ReportPath (Join-Path $absoluteEvidence 'release\report.json')
  $selectors = @($ledger.selectors | ForEach-Object { [ordered]@{ id = [string]$_.id; status = 'pass' } })
  $stable = [ordered]@{
    schema_version = '1.0.0'
    head = $head
    ledger_sha256 = Get-ReleaseSha256 -Path $ledgerPath
    selector_order = @($ledger.selectors.id)
    selectors = $selectors
    artifacts = @($artifacts)
    publication = [ordered]@{
      performed = $false
      credentials_read = $false
      namespace_verified = $false
      blocked_reason = 'unverified_mooncakes_owner_namespace'
    }
    tracked_diff_unchanged = $true
  }
  $digest = Get-ReleaseTextSha256 -Text ($stable | ConvertTo-Json -Depth 100 -Compress)
  $report = [ordered]@{}
  foreach ($entry in $stable.GetEnumerator()) { $report[$entry.Key] = $entry.Value }
  $report.deterministic_evidence_digest = $digest
  $report.run_local = [ordered]@{
    started_utc = $StartedUtc
    completed_utc = [DateTime]::UtcNow.ToString('o')
    evidence_directory = $absoluteEvidence
    os = [Environment]::OSVersion.VersionString
    powershell = $PSVersionTable.PSVersion.ToString()
  }
  $path = Join-Path $absoluteEvidence 'report.json'
  [IO.File]::WriteAllText($path, (($report | ConvertTo-Json -Depth 100) + "`n"), [Text.UTF8Encoding]::new($false))
  return $path
}

function Assert-RequiredQualificationReport {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$LedgerPath)
  $ledger = Assert-StaticRequirementLedger -Path $LedgerPath
  $report = Read-ReleaseJson -Path $Path
  Assert-ReleaseClosedProperties -Label 'Required run report' -Object $report -Expected @(
    'schema_version', 'head', 'ledger_sha256', 'selector_order', 'selectors', 'artifacts', 'publication',
    'tracked_diff_unchanged', 'deterministic_evidence_digest', 'run_local'
  )
  if ($report.schema_version -cne '1.0.0' -or $report.head -cnotmatch '^[0-9a-f]{40}$' -or
      $report.ledger_sha256 -cne (Get-ReleaseSha256 -Path $LedgerPath) -or $report.tracked_diff_unchanged -ne $true) {
    throw "Required run report identity or static-ledger binding failed: $Path"
  }
  Assert-ReleaseExactSequence -Label 'Required selector order' -Actual @($report.selector_order) -Expected @($ledger.selectors.id)
  Assert-ReleaseExactSequence -Label 'Required selector result order' -Actual @($report.selectors.id) -Expected @($ledger.selectors.id)
  if (@($report.selectors | Where-Object { [string]$_.status -cne 'pass' }).Count -ne 0) { throw 'Required run report contains a non-passing selector.' }
  Assert-ReleaseExactSequence -Label 'Required artifact order' -Actual @($report.artifacts.id) -Expected @($ledger.artifact_contracts.id)
  foreach ($artifact in @($report.artifacts)) {
    Assert-ReleaseClosedProperties -Label "Required artifact $($artifact.id)" -Object $artifact -Expected @('id', 'schema_sha256', 'evidence_sha256')
    if ([string]$artifact.schema_sha256 -cnotmatch '^[0-9a-f]{64}$' -or [string]$artifact.evidence_sha256 -cnotmatch '^[0-9a-f]{64}$') {
      throw "Required artifact '$($artifact.id)' has an invalid digest."
    }
  }
  Assert-ReleaseClosedProperties -Label 'Required publication result' -Object $report.publication -Expected @('performed', 'credentials_read', 'namespace_verified', 'blocked_reason')
  if ($report.publication.performed -ne $false -or $report.publication.credentials_read -ne $false -or
      $report.publication.namespace_verified -ne $false -or $report.publication.blocked_reason -cne 'unverified_mooncakes_owner_namespace') {
    throw 'Required run report fabricated publication or credential evidence.'
  }
  Assert-ReleaseClosedProperties -Label 'Required run-local fields' -Object $report.run_local -Expected @('started_utc', 'completed_utc', 'evidence_directory', 'os', 'powershell')
  $stable = Get-RequiredRunStableObject -Report $report
  $expectedDigest = Get-ReleaseTextSha256 -Text ($stable | ConvertTo-Json -Depth 100 -Compress)
  if ($report.deterministic_evidence_digest -cne $expectedDigest) { throw 'Required run canonical deterministic evidence digest is invalid.' }
  return $report
}

function Assert-ReleaseTrackedSnapshot {
  param(
    [Parameter(Mandatory)][AllowEmptyString()][string]$Before,
    [Parameter(Mandatory)][AllowEmptyString()][string]$After
  )
  if ($Before -cne $After) {
    Throw-ReleaseRule -Id 'REL14-TRACKED-SOURCE-MUTATION' -Message 'tracked source differs from the captured baseline.'
  }
}

function Assert-ReleaseHashedArtifact {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$ExpectedSha256)
  if ((Get-ReleaseSha256 -Path $Path) -cne $ExpectedSha256.ToLowerInvariant()) {
    Throw-ReleaseRule -Id 'REL13-ARTIFACT-DIGEST' -Message "artifact bytes no longer match the recorded SHA-256: $Path"
  }
}

function Assert-ReleaseManifestDependencies {
  param(
    [Parameter(Mandatory)][ValidateSet('mb-core', 'mb-color', 'mb-image')][string]$ShortName,
    [Parameter(Mandatory)][string]$ManifestPath,
    [Parameter(Mandatory)][string]$PolicyPath
  )
  $manifest = Read-ReleaseJson -Path $ManifestPath
  $policy = Read-ReleaseJson -Path $PolicyPath
  $expected = $policy.modules.$ShortName.dependencies
  $actual = if ($null -ne $manifest.PSObject.Properties['deps']) { $manifest.deps } else { [pscustomobject]@{} }
  $actualNames = @($actual.PSObject.Properties | ForEach-Object { $_.Name })
  $expectedNames = @($expected.PSObject.Properties | ForEach-Object { $_.Name })
  try { Assert-ReleaseExactSet -Label "$ShortName manifest dependency names" -Actual $actualNames -Expected $expectedNames } catch {
    Throw-ReleaseRule -Id 'REL03-PATH-SUBSTITUTION' -Message $_.Exception.Message
  }
  foreach ($name in $expectedNames) {
    $value = $actual.$name
    if ($value -isnot [string] -or [string]$value -cne [string]$expected.$name) {
      Throw-ReleaseRule -Id 'REL03-PATH-SUBSTITUTION' -Message "$ShortName dependency '$name' is not the exact scalar named version requirement."
    }
  }
  $raw = Get-Content -LiteralPath $ManifestPath -Raw
  if ($raw -cmatch '"path"\s*:|(?:^|[\\/])[.][.](?:[\\/]|$)') {
    Throw-ReleaseRule -Id 'REL03-PATH-SUBSTITUTION' -Message "$ShortName manifest contains a workspace/path substitution."
  }
}

function Assert-ReleaseModuleImports {
  param(
    [Parameter(Mandatory)][ValidateSet('mb-core', 'mb-color', 'mb-image')][string]$ShortName,
    [Parameter(Mandatory)][string]$PackagePath
  )
  $raw = Get-Content -LiteralPath $PackagePath -Raw
  $imports = @([regex]::Matches($raw, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
  $forbidden = @(switch ($ShortName) {
    'mb-core' { @($imports | Where-Object { $_ -cmatch '^tchivs/(?:mb-color|mb-image)(?:/|$)' }) }
    'mb-color' { @($imports | Where-Object { $_ -cmatch '^tchivs/mb-image(?:/|$)' }) }
    default { @() }
  })
  if ($forbidden.Count -ne 0) {
    Throw-ReleaseRule -Id 'REL04-HIGHER-LAYER-DEPENDENCY' -Message "$ShortName imports a higher release layer: $($forbidden -join ', ')"
  }
}

function Assert-ReleasePackageList {
  param(
    [Parameter(Mandatory)][ValidateSet('mb-core', 'mb-color', 'mb-image')][string]$ShortName,
    [Parameter(Mandatory)][string]$ListPath,
    [Parameter(Mandatory)][string]$PolicyPath
  )
  $policy = Read-ReleaseJson -Path $PolicyPath
  $actual = @(Get-Content -LiteralPath $ListPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Replace('\', '/') })
  try { Assert-ReleaseExactSet -Label "$ShortName package inventory" -Actual $actual -Expected @($policy.modules.$ShortName.package_allowlist) } catch {
    Throw-ReleaseRule -Id 'REL05-ARCHIVE-ENTRY' -Message $_.Exception.Message
  }
}

function Assert-ReleaseCandidateOutcomes {
  param([Parameter(Mandatory)][string]$ReportPath)
  $report = Read-ReleaseJson -Path $ReportPath
  if ($report.publication.performed -ne $false -or $report.publication.credentials_read -ne $false -or
      $report.publication.namespace_verified -ne $false -or
      $report.modules.'mb-color'.source_isolation -cne 'pass' -or
      $report.modules.'mb-image'.source_isolation -cne 'pass' -or
      $report.modules.'mb-color'.artifact_consumer -cne 'blocked_unpublished_dependency' -or
      $report.modules.'mb-image'.artifact_consumer -cne 'blocked_unpublished_dependency' -or
      $report.modules.'mb-color'.registry_resolution -cne 'blocked_unpublished_namespace' -or
      $report.modules.'mb-image'.registry_resolution -cne 'blocked_unpublished_namespace') {
    Throw-ReleaseRule -Id 'REL02-FABRICATED-REGISTRY-PASS' -Message 'candidate report fabricated publication or downstream registry/artifact success.'
  }
}

function Assert-PpmQualificationContract {
  param([Parameter(Mandatory)][string]$FoundationPath)
  $foundation = Read-ReleaseJson -Path $FoundationPath
  $image = @($foundation.modules | Where-Object { [string]$_.path -ceq 'modules/mb-image' })
  if ($image.Count -ne 1) { Throw-ReleaseRule -Id 'PPM06-WRONG-PUBLICATION-ORDER' -Message 'mb-image policy owner is missing or duplicated.' }
  $expectedPackageOrder = @(
    'tchivs/mb-image/metadata', 'tchivs/mb-image/model',
    'tchivs/mb-image/storage', 'tchivs/mb-image/ops',
    'tchivs/mb-image/codec', 'tchivs/mb-image/ppm'
  )
  try { Assert-ReleaseExactSequence -Label 'PPM publication order' -Actual @($image[0].public_packages.name) -Expected $expectedPackageOrder } catch {
    Throw-ReleaseRule -Id 'PPM06-WRONG-PUBLICATION-ORDER' -Message $_.Exception.Message
  }
  $ppm = @($image[0].public_packages | Where-Object { [string]$_.path -ceq 'ppm' })
  if ($ppm.Count -ne 1) { Throw-ReleaseRule -Id 'PPM07-UNREGISTERED-CONTENT' -Message 'PPM package owner is missing or duplicated.' }
  $expectedImports = @(
    'tchivs/mb-core/budget', 'tchivs/mb-core/bytes',
    'tchivs/mb-core/checked', 'tchivs/mb-core/error',
    'tchivs/mb-core/io', 'tchivs/mb-color/model',
    'tchivs/mb-color/profile', 'tchivs/mb-image/codec',
    'tchivs/mb-image/metadata', 'tchivs/mb-image/model',
    'tchivs/mb-image/storage'
  )
  $actualImports = @($ppm[0].allowed_imports)
  if ($actualImports.Count -lt $expectedImports.Count) { Throw-ReleaseRule -Id 'PPM01-MISSING-IMPORT' -Message 'PPM import allowlist is incomplete.' }
  if ($actualImports.Count -gt $expectedImports.Count) { Throw-ReleaseRule -Id 'PPM02-EXTRA-IMPORT' -Message 'PPM import allowlist contains an extra edge.' }
  try { Assert-ReleaseExactSequence -Label 'PPM imports' -Actual $actualImports -Expected $expectedImports } catch {
    Throw-ReleaseRule -Id 'PPM02-EXTRA-IMPORT' -Message $_.Exception.Message
  }
  try { Assert-ReleaseExactSequence -Label 'PPM targets' -Actual @($ppm[0].supported_targets) -Expected @('js', 'wasm', 'wasm-gc', 'native') } catch {
    Throw-ReleaseRule -Id 'PPM03-WRONG-TARGET' -Message $_.Exception.Message
  }
  $canonical = Read-ReleaseJson -Path (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'policy\foundation.json')
  $canonicalPpm = @((@($canonical.modules | Where-Object { [string]$_.path -ceq 'modules/mb-image' })[0]).public_packages | Where-Object { [string]$_.path -ceq 'ppm' })[0]
  $actualInterface = @($ppm[0].semantic_interface)
  $expectedInterface = @($canonicalPpm.semantic_interface)
  if ($actualInterface.Count -lt $expectedInterface.Count) { Throw-ReleaseRule -Id 'PPM04-MISSING-INTERFACE' -Message 'PPM semantic interface is incomplete.' }
  if ($actualInterface.Count -gt $expectedInterface.Count) { Throw-ReleaseRule -Id 'PPM05-EXTRA-INTERFACE' -Message 'PPM semantic interface contains an unregistered declaration.' }
  try { Assert-ReleaseExactSequence -Label 'PPM semantic interface' -Actual $actualInterface -Expected $expectedInterface } catch {
    Throw-ReleaseRule -Id 'PPM05-EXTRA-INTERFACE' -Message $_.Exception.Message
  }
  try { Assert-ReleaseExactSequence -Label 'PPM production sources' -Actual @($ppm[0].production_sources) -Expected @('moon.pkg', 'ppm.mbt', 'parser.mbt', 'decode.mbt', 'encode.mbt', 'generated_vectors.mbt') } catch {
    Throw-ReleaseRule -Id 'PPM07-UNREGISTERED-CONTENT' -Message $_.Exception.Message
  }
}

function Remove-ReleaseTemp {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
  $full = [IO.Path]::GetFullPath($Path)
  $leaf = Split-Path -Leaf $full
  if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
      -not $leaf.StartsWith('mnf-release-qualification-', [StringComparison]::Ordinal)) {
    throw "Refusing to remove unverified release qualification path: $full"
  }
  Remove-Item -LiteralPath $full -Recurse -Force
}

function Assert-ReleaseSchema {
  param([Parameter(Mandatory)][string]$SchemaPath)
  $schema = Read-ReleaseJson -Path $SchemaPath
  if ($schema.type -cne 'object' -or $schema.additionalProperties -ne $false -or $schema.properties.schema_version.const -cne '1.0.0') {
    throw 'Release report schema is not a closed 1.0.0 object.'
  }
  Assert-ReleaseExactSequence -Label 'schema module order' -Actual @($schema.properties.module_order.const) -Expected @('mb-core', 'mb-color', 'mb-image')
  if ($schema.properties.publication.properties.performed.const -ne $false -or
      $schema.properties.publication.properties.credentials_read.const -ne $false -or
      $schema.'$defs'.coreModule.properties.artifact_consumer.const -cne 'pass' -or
      $schema.'$defs'.downstreamModule.properties.source_isolation.const -cne 'pass' -or
      $schema.'$defs'.downstreamModule.properties.registry_resolution.const -cne 'blocked_unpublished_namespace') {
    throw 'Release report schema does not freeze the honest publication and consumer outcomes.'
  }
}

function Assert-ReleasePolicy {
  param(
    [Parameter(Mandatory)][string]$PolicyPath,
    [Parameter(Mandatory)][string]$FoundationPath,
    [Parameter(Mandatory)][string]$FixtureManifestPath,
    [Parameter(Mandatory)][string]$SchemaPath,
    [Parameter(Mandatory)][string]$RepoRoot
  )

  $policy = Read-ReleaseJson -Path $PolicyPath
  $foundation = Read-ReleaseJson -Path $FoundationPath
  $fixtures = Read-ReleaseJson -Path $FixtureManifestPath
  Assert-ReleaseSchema -SchemaPath $SchemaPath

  Assert-ReleaseClosedProperties -Label 'release policy' -Object $policy -Expected @(
    'schema_version', 'module_order', 'required_targets', 'candidate_status', 'license', 'repository',
    'fixture_manifest', 'fixture_records', 'forbidden_archive_patterns', 'post_publish_order', 'publication', 'modules'
  )
  if ($policy.candidate_status -cne 'candidate') {
    Throw-ReleaseRule -Id 'REL09-WRONG-STATUS' -Message 'release policy candidate status drifted.'
  }
  if ($policy.license -cne 'Apache-2.0') {
    Throw-ReleaseRule -Id 'REL10-MISSING-LICENSE' -Message 'release policy license is missing or drifted.'
  }
  if ($policy.schema_version -cne '1.0.0' -or $policy.repository -cne 'https://github.com/tchivs/moonbit-foundation' -or
      $policy.fixture_manifest -cne 'fixtures/manifest.json') {
    throw 'Release policy identity, repository, or fixture manifest drifted.'
  }
  try { Assert-ReleaseExactSequence -Label 'release module order' -Actual @($policy.module_order) -Expected @('mb-core', 'mb-color', 'mb-image') } catch {
    Throw-ReleaseRule -Id 'REL01-MODULE-ORDER' -Message $_.Exception.Message
  }
  Assert-ReleaseExactSequence -Label 'release targets' -Actual @($policy.required_targets) -Expected @('js', 'wasm', 'wasm-gc', 'native')
  Assert-ReleaseExactSequence -Label 'post-publication order' -Actual @($policy.post_publish_order) -Expected @(
    'publish:tchivs/mb-core@0.1.0', 'resolve:tchivs/mb-core@0.1.0',
    'publish:tchivs/mb-color@0.1.0', 'resolve:tchivs/mb-color@0.1.0',
    'publish:tchivs/mb-image@0.1.0', 'resolve:tchivs/mb-image@0.1.0'
  )
  Assert-ReleaseClosedProperties -Label 'publication policy' -Object $policy.publication -Expected @('performed', 'credentials_read', 'namespace_verified', 'blocked_reason')
  if ($policy.publication.performed -ne $false -or $policy.publication.credentials_read -ne $false -or
      $policy.publication.namespace_verified -ne $false -or $policy.publication.blocked_reason -cne 'unverified_mooncakes_owner_namespace') {
    throw 'Publication policy must remain non-executing, credential-free, namespace-unverified, and explicitly blocked.'
  }

  $fixtureIds = @($fixtures.records | ForEach-Object { [string]$_.id })
  try { Assert-ReleaseExactSequence -Label 'fixture provenance records' -Actual @($policy.fixture_records) -Expected $fixtureIds } catch {
    Throw-ReleaseRule -Id 'REL11-MISSING-PROVENANCE' -Message $_.Exception.Message
  }
  foreach ($record in @($fixtures.records)) {
    $fixturePath = Join-Path $RepoRoot ([string]$record.path)
    if (-not (Test-Path -LiteralPath $fixturePath -PathType Leaf) -or (Get-ReleaseSha256 -Path $fixturePath) -cne ([string]$record.sha256).ToLowerInvariant()) {
      Throw-ReleaseRule -Id 'REL12-PROVENANCE-CHECKSUM' -Message "fixture provenance bytes drifted for '$($record.id)'."
    }
  }

  Assert-ReleaseClosedProperties -Label 'release modules' -Object $policy.modules -Expected @('mb-core', 'mb-color', 'mb-image')
  $expectedDependencies = @{
    'mb-core' = [ordered]@{}
    'mb-color' = [ordered]@{ 'tchivs/mb-core' = '0.1.0' }
    'mb-image' = [ordered]@{ 'tchivs/mb-core' = '0.1.0'; 'tchivs/mb-color' = '0.1.0' }
  }
  $expectedOutcomes = @{
    'mb-core' = @('not_required_leaf_artifact_consumer', 'pass', 'not_required_no_dependencies')
    'mb-color' = @('pass', 'blocked_unpublished_dependency', 'blocked_unpublished_namespace')
    'mb-image' = @('pass', 'blocked_unpublished_dependency', 'blocked_unpublished_namespace')
  }

  foreach ($shortName in @('mb-core', 'mb-color', 'mb-image')) {
    $module = $policy.modules.$shortName
    if ($null -eq $module.manifest.PSObject.Properties['version'] -or [string]::IsNullOrWhiteSpace([string]$module.manifest.version)) {
      Throw-ReleaseRule -Id 'REL08-MISSING-VERSION' -Message "$shortName manifest version is missing."
    }
    Assert-ReleaseClosedProperties -Label "$shortName release policy" -Object $module -Expected @(
      'manifest', 'dependencies', 'public_packages', 'package_allowlist', 'source_isolation', 'artifact_consumer', 'registry_resolution'
    )
    Assert-ReleaseClosedProperties -Label "$shortName manifest policy" -Object $module.manifest -Expected @(
      'name', 'version', 'description', 'license', 'repository', 'readme', 'preferred-target', 'supported-targets'
    )
    $foundationModule = @($foundation.modules | Where-Object { [string]$_.path -ceq "modules/$shortName" })
    if ($foundationModule.Count -ne 1) { throw "Foundation policy must contain exactly one $shortName module." }
    $foundationModule = $foundationModule[0]
    $manifestPath = Join-Path $RepoRoot "modules\$shortName\moon.mod.json"
    $manifest = Read-ReleaseJson -Path $manifestPath
    Assert-ReleaseManifestDependencies -ShortName $shortName -ManifestPath $manifestPath -PolicyPath $PolicyPath
    foreach ($packageManifest in @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot "modules\$shortName") -Recurse -File -Filter 'moon.pkg')) {
      Assert-ReleaseModuleImports -ShortName $shortName -PackagePath $packageManifest.FullName
    }
    foreach ($field in @('name', 'version', 'description', 'license', 'repository', 'readme', 'preferred-target', 'supported-targets')) {
      if ([string]$module.manifest.$field -cne [string]$manifest.$field) { throw "$shortName manifest field '$field' drifted from release policy." }
    }
    if ($module.manifest.name -cne [string]$foundationModule.name -or $module.manifest.version -cne [string]$foundationModule.version -or
        $module.manifest.description -cne [string]$foundationModule.description -or $module.manifest.repository -cne [string]$foundationModule.repository) {
      throw "$shortName release metadata drifted from foundation policy."
    }
    Assert-ReleaseExactSequence -Label "$shortName package allowlist" -Actual @($module.package_allowlist) -Expected @($foundationModule.publication_files)
    Assert-ReleaseExactSequence -Label "$shortName public packages" -Actual @($module.public_packages) -Expected @($foundationModule.public_packages | ForEach-Object { [string]$_.name })

    $wantedDeps = $expectedDependencies[$shortName]
    Assert-ReleaseExactSet -Label "$shortName dependency names" -Actual @($module.dependencies.PSObject.Properties | ForEach-Object { $_.Name }) -Expected @($wantedDeps.Keys)
    foreach ($dep in @($wantedDeps.Keys)) {
      if ($module.dependencies.$dep -isnot [string] -or [string]$module.dependencies.$dep -cne [string]$wantedDeps[$dep]) {
        throw "$shortName dependency '$dep' must be the exact scalar 0.1.0 named requirement."
      }
    }
    if (@($manifest.PSObject.Properties | ForEach-Object { $_.Name }) -contains 'deps') {
      Assert-ReleaseExactSet -Label "$shortName manifest dependency names" -Actual @($manifest.deps.PSObject.Properties | ForEach-Object { $_.Name }) -Expected @($wantedDeps.Keys)
      foreach ($dep in @($wantedDeps.Keys)) { if ([string]$manifest.deps.$dep -cne '0.1.0') { throw "$shortName manifest dependency '$dep' drifted." } }
    } elseif ($wantedDeps.Count -ne 0) { throw "$shortName manifest dependencies are missing." }

    $actualOutcomes = @([string]$module.source_isolation, [string]$module.artifact_consumer, [string]$module.registry_resolution)
    Assert-ReleaseExactSequence -Label "$shortName outcomes" -Actual $actualOutcomes -Expected $expectedOutcomes[$shortName]
    foreach ($entry in @($module.package_allowlist)) {
      $text = ([string]$entry).Replace('\', '/')
      if ([IO.Path]::IsPathRooted($text) -or $text -match '(^|/)\.\.(/|$)') { throw "$shortName package allowlist contains an absolute or traversal entry: $text" }
      foreach ($pattern in @($policy.forbidden_archive_patterns)) { if ($text -match [string]$pattern) { throw "$shortName package allowlist contains forbidden entry '$text'." } }
    }
  }

  return $policy
}
