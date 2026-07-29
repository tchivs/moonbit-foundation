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
  keying = 'name'
  reader = 'afdko'
  reader_version = '5.0.1'
}
$result | ConvertTo-Json -Depth 10 -Compress
