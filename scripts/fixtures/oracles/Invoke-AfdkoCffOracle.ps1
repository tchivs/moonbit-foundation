[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$PythonPath,

  [Parameter(Mandatory)]
  [string]$AfdkoSiteRoot,

  [Parameter(Mandatory)]
  [string]$TxRunnerPath,

  [Parameter(Mandatory)]
  [string]$FontPath,

  [string]$Scalar = 'U+0041'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-U16BE {
  param([byte[]]$Bytes, [int]$Offset)
  return ([int]$Bytes[$Offset] -shl 8) -bor [int]$Bytes[$Offset + 1]
}

function Read-I16BE {
  param([byte[]]$Bytes, [int]$Offset)
  $value = Read-U16BE $Bytes $Offset
  if ($value -ge 0x8000) { return $value - 0x10000 }
  return $value
}

function Read-U32BE {
  param([byte[]]$Bytes, [int]$Offset)
  return [uint64](
    ([uint64]$Bytes[$Offset] -shl 24) -bor
    ([uint64]$Bytes[$Offset + 1] -shl 16) -bor
    ([uint64]$Bytes[$Offset + 2] -shl 8) -bor
    [uint64]$Bytes[$Offset + 3]
  )
}

function Get-TableRecord {
  param([byte[]]$Bytes, [string]$Tag)
  $count = Read-U16BE $Bytes 4
  for ($index = 0; $index -lt $count; $index++) {
    $offset = 12 + $index * 16
    $actual = [Text.Encoding]::ASCII.GetString($Bytes, $offset, 4)
    if ($actual -ceq $Tag) {
      return [ordered]@{
        offset = [int](Read-U32BE $Bytes ($offset + 8))
        length = [int](Read-U32BE $Bytes ($offset + 12))
      }
    }
  }
  throw "Required table '$Tag' is missing."
}

function Read-CffOffset {
  param([byte[]]$Bytes, [int]$Offset, [int]$Size)
  [uint64]$value = 0
  for ($index = 0; $index -lt $Size; $index++) {
    $value = ($value -shl 8) -bor [uint64]$Bytes[$Offset + $index]
  }
  return $value
}

function Read-CffIndex {
  param([byte[]]$Bytes, [int]$Offset, [int]$Limit)
  if ($Offset -lt 0 -or $Offset + 2 -gt $Limit) {
    throw 'CFF INDEX count is out of range.'
  }
  $count = Read-U16BE $Bytes $Offset
  if ($count -eq 0) {
    return [ordered]@{ entries = @(); next = $Offset + 2 }
  }
  if ($Offset + 3 -gt $Limit) { throw 'CFF INDEX offSize is out of range.' }
  $offSize = [int]$Bytes[$Offset + 2]
  if ($offSize -lt 1 -or $offSize -gt 4) { throw 'CFF INDEX offSize is invalid.' }
  $offsetBase = $Offset + 3
  $dataBase = $offsetBase + ($count + 1) * $offSize
  if ($dataBase -gt $Limit) { throw 'CFF INDEX offset array is out of range.' }
  $offsets = [Collections.Generic.List[uint64]]::new()
  for ($index = 0; $index -le $count; $index++) {
    $value = Read-CffOffset $Bytes ($offsetBase + $index * $offSize) $offSize
    if ($value -lt 1 -or ($index -gt 0 -and $value -lt $offsets[$index - 1])) {
      throw 'CFF INDEX offsets are not monotonic one-based values.'
    }
    $offsets.Add($value)
  }
  $end = $dataBase + [int]$offsets[$count] - 1
  if ($end -gt $Limit) { throw 'CFF INDEX data is out of range.' }
  $entries = [Collections.Generic.List[object]]::new()
  for ($index = 0; $index -lt $count; $index++) {
    $start = $dataBase + [int]$offsets[$index] - 1
    $entryEnd = $dataBase + [int]$offsets[$index + 1] - 1
    $length = $entryEnd - $start
    $entry = [byte[]]::new($length)
    if ($length -gt 0) {
      [Array]::Copy($Bytes, $start, $entry, 0, $length)
    }
    $entries.Add($entry)
  }
  return [ordered]@{ entries = @($entries); next = $end }
}

function Read-CffDict {
  param([byte[]]$Bytes)
  $result = @{}
  $operands = [Collections.Generic.List[object]]::new()
  $offset = 0
  while ($offset -lt $Bytes.Length) {
    $first = [int]$Bytes[$offset]
    $offset++
    if ($first -ge 32 -and $first -le 246) {
      $operands.Add([int64]($first - 139))
      continue
    }
    if ($first -ge 247 -and $first -le 250) {
      if ($offset -ge $Bytes.Length) { throw 'CFF DICT positive number is truncated.' }
      $operands.Add([int64](($first - 247) * 256 + [int]$Bytes[$offset] + 108))
      $offset++
      continue
    }
    if ($first -ge 251 -and $first -le 254) {
      if ($offset -ge $Bytes.Length) { throw 'CFF DICT negative number is truncated.' }
      $operands.Add([int64](-(($first - 251) * 256 + [int]$Bytes[$offset] + 108)))
      $offset++
      continue
    }
    if ($first -eq 28) {
      if ($offset + 2 -gt $Bytes.Length) { throw 'CFF DICT short integer is truncated.' }
      $operands.Add([int64](Read-I16BE $Bytes $offset))
      $offset += 2
      continue
    }
    if ($first -eq 29) {
      if ($offset + 4 -gt $Bytes.Length) { throw 'CFF DICT long integer is truncated.' }
      [uint64]$unsigned = Read-U32BE $Bytes $offset
      [int64]$signed = if ($unsigned -ge 0x80000000L) {
        [int64]$unsigned - 0x100000000L
      } else {
        [int64]$unsigned
      }
      $operands.Add($signed)
      $offset += 4
      continue
    }
    if ($first -eq 30) {
      $text = [Text.StringBuilder]::new()
      $done = $false
      while (-not $done) {
        if ($offset -ge $Bytes.Length) { throw 'CFF DICT real is truncated.' }
        $pair = [int]$Bytes[$offset]
        $offset++
        foreach ($nibble in @(
            (($pair -shr 4) -band 15),
            ($pair -band 15)
          )) {
          switch ($nibble) {
            0 { [void]$text.Append('0') }
            1 { [void]$text.Append('1') }
            2 { [void]$text.Append('2') }
            3 { [void]$text.Append('3') }
            4 { [void]$text.Append('4') }
            5 { [void]$text.Append('5') }
            6 { [void]$text.Append('6') }
            7 { [void]$text.Append('7') }
            8 { [void]$text.Append('8') }
            9 { [void]$text.Append('9') }
            10 { [void]$text.Append('.') }
            11 { [void]$text.Append('E') }
            12 { [void]$text.Append('E-') }
            14 { [void]$text.Append('-') }
            15 { $done = $true }
            default { throw 'CFF DICT real contains a reserved nibble.' }
          }
          if ($done) { break }
        }
      }
      $operands.Add([double]::Parse(
        $text.ToString(),
        [Globalization.CultureInfo]::InvariantCulture
      ))
      continue
    }
    if ($first -eq 255) {
      if ($offset + 4 -gt $Bytes.Length) { throw 'CFF DICT fixed number is truncated.' }
      [uint64]$unsigned = Read-U32BE $Bytes $offset
      [int64]$signed = if ($unsigned -ge 0x80000000L) {
        [int64]$unsigned - 0x100000000L
      } else {
        [int64]$unsigned
      }
      $operands.Add([double]$signed / 65536.0)
      $offset += 4
      continue
    }
    $operator = [string]$first
    if ($first -eq 12) {
      if ($offset -ge $Bytes.Length) { throw 'CFF DICT escaped operator is truncated.' }
      $operator = "12 $([int]$Bytes[$offset])"
      $offset++
    }
    $result[$operator] = @($operands)
    $operands.Clear()
  }
  if ($operands.Count -ne 0) { throw 'CFF DICT has trailing operands.' }
  return $result
}

function Get-CffProfileFacts {
  param([byte[]]$Bytes, [int]$GlyphId)
  $cffTable = Get-TableRecord $Bytes 'CFF '
  $cffBase = [int]$cffTable.offset
  $cffLimit = $cffBase + [int]$cffTable.length
  if ($cffTable.length -lt 4) { throw 'CFF header is truncated.' }
  $cursor = $cffBase + [int]$Bytes[$cffBase + 2]
  $nameIndex = Read-CffIndex $Bytes $cursor $cffLimit
  $topIndex = Read-CffIndex $Bytes $nameIndex.next $cffLimit
  if ($topIndex.entries.Count -ne 1) { throw 'CFF Top DICT count is not one.' }
  $stringIndex = Read-CffIndex $Bytes $topIndex.next $cffLimit
  $top = Read-CffDict ([byte[]]$topIndex.entries[0])
  $rosOperands = $top['12 30']
  if ($null -eq $rosOperands) {
    return [ordered]@{
      keying = 'name'
      ros = $null
      fd_count = $null
      used_fds = @()
      selected_fd = $null
      fd_select_format = $null
    }
  }
  if ($rosOperands.Count -ne 3 -or
      $null -eq $top['12 36'] -or $null -eq $top['12 37']) {
    throw 'CID CFF Top DICT lacks ROS, FDArray, or FDSelect facts.'
  }
  $resolveSid = {
    param([int]$Sid)
    if ($Sid -lt 391) {
      throw "CID ROS unexpectedly uses unsupported standard SID $Sid."
    }
    $index = $Sid - 391
    if ($index -lt 0 -or $index -ge $stringIndex.entries.Count) {
      throw "CID ROS SID is outside the String INDEX: $Sid."
    }
    return [Text.Encoding]::ASCII.GetString([byte[]]$stringIndex.entries[$index])
  }
  $fdArrayOffset = $cffBase + [int]$top['12 36'][0]
  $fdArray = Read-CffIndex $Bytes $fdArrayOffset $cffLimit
  $fdSelectOffset = $cffBase + [int]$top['12 37'][0]
  if ($fdSelectOffset -ge $cffLimit) { throw 'CFF FDSelect is out of range.' }
  $format = [int]$Bytes[$fdSelectOffset]
  $maxp = Get-TableRecord $Bytes 'maxp'
  $glyphCount = Read-U16BE $Bytes ($maxp.offset + 4)
  $gidArray = [int[]]::new($glyphCount)
  if ($format -eq 0) {
    if ($fdSelectOffset + 1 + $glyphCount -gt $cffLimit) {
      throw 'CFF FDSelect format 0 is truncated.'
    }
    for ($index = 0; $index -lt $glyphCount; $index++) {
      $gidArray[$index] = [int]$Bytes[$fdSelectOffset + 1 + $index]
    }
  } elseif ($format -eq 3) {
    $rangeCount = Read-U16BE $Bytes ($fdSelectOffset + 1)
    $rangesOffset = $fdSelectOffset + 3
    $sentinelOffset = $rangesOffset + $rangeCount * 3
    if ($sentinelOffset + 2 -gt $cffLimit) { throw 'CFF FDSelect format 3 is truncated.' }
    $sentinel = Read-U16BE $Bytes $sentinelOffset
    if ($sentinel -ne $glyphCount) { throw 'CFF FDSelect sentinel mismatches glyph count.' }
    for ($range = 0; $range -lt $rangeCount; $range++) {
      $first = Read-U16BE $Bytes ($rangesOffset + $range * 3)
      $next = if ($range + 1 -lt $rangeCount) {
        Read-U16BE $Bytes ($rangesOffset + ($range + 1) * 3)
      } else {
        $sentinel
      }
      $fd = [int]$Bytes[$rangesOffset + $range * 3 + 2]
      for ($index = $first; $index -lt $next; $index++) { $gidArray[$index] = $fd }
    }
  } else {
    throw "Unsupported CFF FDSelect format: $format"
  }
  foreach ($fd in $gidArray) {
    if ($fd -lt 0 -or $fd -ge $fdArray.entries.Count) {
      throw "CFF FDSelect references out-of-range FD $fd."
    }
  }
  return [ordered]@{
    keying = 'cid'
    ros = @(
      (& $resolveSid ([int]$rosOperands[0])),
      (& $resolveSid ([int]$rosOperands[1])),
      [int]$rosOperands[2]
    )
    fd_count = $fdArray.entries.Count
    used_fds = @($gidArray | Sort-Object -Unique)
    selected_fd = [int]$gidArray[$GlyphId]
    fd_select_format = $format
  }
}

function Get-CmapGlyph {
  param([byte[]]$Bytes, [uint64]$Codepoint)
  $table = Get-TableRecord $Bytes 'cmap'
  $base = [int]$table.offset
  $count = Read-U16BE $Bytes ($base + 2)
  $selected = $null
  for ($index = 0; $index -lt $count; $index++) {
    $record = $base + 4 + $index * 8
    $platform = Read-U16BE $Bytes $record
    $encoding = Read-U16BE $Bytes ($record + 2)
    $subtable = $base + [int](Read-U32BE $Bytes ($record + 4))
    $format = Read-U16BE $Bytes $subtable
    if (($platform -eq 0 -or $platform -eq 3) -and $format -in @(4, 12)) {
      if ($null -eq $selected -or $format -eq 12) {
        $selected = [ordered]@{ offset = $subtable; format = $format; encoding = $encoding }
      }
    }
  }
  if ($null -eq $selected) { throw 'No supported Unicode cmap exists.' }
  $subtable = [int]$selected.offset
  if ($selected.format -eq 12) {
    $groups = [int](Read-U32BE $Bytes ($subtable + 12))
    for ($index = 0; $index -lt $groups; $index++) {
      $group = $subtable + 16 + $index * 12
      $start = Read-U32BE $Bytes $group
      $end = Read-U32BE $Bytes ($group + 4)
      if ($Codepoint -ge $start -and $Codepoint -le $end) {
        return [int]((Read-U32BE $Bytes ($group + 8)) + ($Codepoint - $start))
      }
    }
    throw 'Scalar is unmapped.'
  }

  if ($Codepoint -gt 0xFFFF) { throw 'Scalar is unmapped.' }
  $segments = (Read-U16BE $Bytes ($subtable + 6)) / 2
  $endCodes = $subtable + 14
  $startCodes = $endCodes + $segments * 2 + 2
  $deltas = $startCodes + $segments * 2
  $rangeOffsets = $deltas + $segments * 2
  for ($index = 0; $index -lt $segments; $index++) {
    $start = Read-U16BE $Bytes ($startCodes + $index * 2)
    $end = Read-U16BE $Bytes ($endCodes + $index * 2)
    if ($Codepoint -lt $start -or $Codepoint -gt $end) { continue }
    $delta = Read-I16BE $Bytes ($deltas + $index * 2)
    $range = Read-U16BE $Bytes ($rangeOffsets + $index * 2)
    if ($range -eq 0) {
      return [int](($Codepoint + $delta) -band 0xFFFF)
    }
    $glyphOffset = $rangeOffsets + $index * 2 + $range +
      ([int]$Codepoint - $start) * 2
    $glyph = Read-U16BE $Bytes $glyphOffset
    if ($glyph -eq 0) { throw 'Scalar is unmapped.' }
    return [int](($glyph + $delta) -band 0xFFFF)
  }
  throw 'Scalar is unmapped.'
}

function Get-HorizontalMetric {
  param([byte[]]$Bytes, [int]$GlyphId)
  $hhea = Get-TableRecord $Bytes 'hhea'
  $hmtx = Get-TableRecord $Bytes 'hmtx'
  $metricCount = Read-U16BE $Bytes ($hhea.offset + 34)
  if ($GlyphId -lt $metricCount) {
    return [ordered]@{
      advance = Read-U16BE $Bytes ($hmtx.offset + $GlyphId * 4)
      lsb = Read-I16BE $Bytes ($hmtx.offset + $GlyphId * 4 + 2)
    }
  }
  return [ordered]@{
    advance = Read-U16BE $Bytes ($hmtx.offset + ($metricCount - 1) * 4)
    lsb = Read-I16BE $Bytes (
      $hmtx.offset + $metricCount * 4 + ($GlyphId - $metricCount) * 2
    )
  }
}

function Convert-Number {
  param([string]$Text)
  $number = [double]::Parse($Text, [Globalization.CultureInfo]::InvariantCulture)
  if ($number -eq [Math]::Truncate($number)) { return [int64]$number }
  return $number
}

foreach ($path in @($PythonPath, $TxRunnerPath, $FontPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "AFDKO reader input is missing: $path"
  }
}
if (-not (Test-Path -LiteralPath $AfdkoSiteRoot -PathType Container)) {
  throw "AFDKO site root is missing: $AfdkoSiteRoot"
}

$bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $FontPath).Path)
[void](Get-TableRecord $bytes 'CFF ')
try {
  [void](Get-TableRecord $bytes 'CFF2')
  throw 'Reader rejects CFF2.'
} catch {
  if ($_.Exception.Message -cne "Required table 'CFF2' is missing.") { throw }
}
try {
  [void](Get-TableRecord $bytes 'glyf')
  throw 'Reader rejects mixed glyf outlines.'
} catch {
  if ($_.Exception.Message -cne "Required table 'glyf' is missing.") { throw }
}

$codepoint = [Convert]::ToUInt64($Scalar.Substring(2), 16)
$gid = Get-CmapGlyph $bytes $codepoint
$metric = Get-HorizontalMetric $bytes $gid
$cffFacts = Get-CffProfileFacts $bytes $gid

$dump = & $PythonPath $TxRunnerPath $AfdkoSiteRoot -dump -6 -g "$gid" $FontPath 2>&1
if ($LASTEXITCODE -ne 0) { throw "AFDKO tx dump failed: $($dump -join "`n")" }
$dumpText = $dump -join "`n"
$header = [regex]::Match($dumpText, 'glyph\[(?<gid>\d+)\] \{(?<name>[^,]+),')
if (-not $header.Success -or [int]$header.Groups['gid'].Value -ne $gid) {
  throw 'AFDKO tx glyph header drifted.'
}
$glyphName = $header.Groups['name'].Value
$commands = [Collections.Generic.List[object]]::new()
foreach ($line in ($dumpText -split "`n")) {
  $match = [regex]::Match($line, '^\s*(-?[\d.]+)\s+(-?[\d.]+)\s+move\s*$')
  if ($match.Success) {
    $commands.Add([ordered]@{
      op = 'MoveTo'
      points = @((Convert-Number $match.Groups[1].Value), (Convert-Number $match.Groups[2].Value))
    })
    continue
  }
  $match = [regex]::Match($line, '^\s*(-?[\d.]+)\s+(-?[\d.]+)\s+line\s*$')
  if ($match.Success) {
    $commands.Add([ordered]@{
      op = 'LineTo'
      points = @((Convert-Number $match.Groups[1].Value), (Convert-Number $match.Groups[2].Value))
    })
    continue
  }
  $match = [regex]::Match(
    $line,
    '^\s*(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+(-?[\d.]+)\s+curve\s*$'
  )
  if ($match.Success) {
    $points = @()
    for ($index = 1; $index -le 6; $index++) {
      $points += Convert-Number $match.Groups[$index].Value
    }
    $commands.Add([ordered]@{ op = 'CubicTo'; points = $points })
    continue
  }
  if ($line.Trim() -ceq 'endchar}') {
    $commands.Add([ordered]@{ op = 'Close'; points = @() })
  }
}
if ($commands.Count -eq 0 -or $commands[$commands.Count - 1].op -cne 'Close') {
  throw 'AFDKO tx did not emit one closed path.'
}

$metrics = & $PythonPath $TxRunnerPath $AfdkoSiteRoot -mtx -g "$gid" $FontPath 2>&1
if ($LASTEXITCODE -ne 0) { throw "AFDKO tx metrics failed: $($metrics -join "`n")" }
$metricMatch = [regex]::Match(
  ($metrics -join "`n"),
  'glyph\[\d+\] \{[^,]+,[^,]+,[^,]+,\{(-?[\d.]+),(-?[\d.]+),(-?[\d.]+),(-?[\d.]+)\}\}'
)
if (-not $metricMatch.Success) { throw 'AFDKO tx bounds output drifted.' }
$bounds = @()
for ($index = 1; $index -le 4; $index++) {
  $bounds += Convert-Number $metricMatch.Groups[$index].Value
}

$result = [ordered]@{
  schema = 'cff-semantic-reader/1.0.0'
  source_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $FontPath).Hash.ToLowerInvariant()
  face_index = 0
  scalar = $Scalar
  glyph_name = $glyphName
  gid = $gid
  advance = $metric.advance
  lsb = $metric.lsb
  bounds = $bounds
  commands = @($commands)
  cff_profile = 'CFF1'
  keying = $cffFacts.keying
  ros = $cffFacts.ros
  fd_count = $cffFacts.fd_count
  used_fds = @($cffFacts.used_fds)
  selected_fd = $cffFacts.selected_fd
  fd_select_format = $cffFacts.fd_select_format
  reader = 'afdko'
  reader_version = '5.0.1'
}
$result | ConvertTo-Json -Depth 10 -Compress
