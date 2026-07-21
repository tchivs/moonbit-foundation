[CmdletBinding()]
param([switch]$Check)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Utf8NoBom = [Text.UTF8Encoding]::new($false)
$Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$CasesPath = Join-Path $Root 'fixtures\png\decode-cases.json'
$OutputPath = Join-Path $Root 'modules\mb-image\png\generated_decode_vectors_test.mbt'
$ManifestPath = Join-Path $Root 'fixtures\manifest.json'

function Join-Bytes([object[]]$Parts) {
  $out = [Collections.Generic.List[byte]]::new()
  foreach ($part in $Parts) { if ($null -ne $part) { $out.AddRange([byte[]]$part) } }
  return ,$out.ToArray()
}
function U32([uint64]$Value) { [byte[]]@([byte](($Value -shr 24) -band 255),[byte](($Value -shr 16) -band 255),[byte](($Value -shr 8) -band 255),[byte]($Value -band 255)) }
function Crc32([byte[]]$Bytes) {
  [uint64]$mask = [Convert]::ToUInt64('ffffffff', 16)
  [uint64]$polynomial = [Convert]::ToUInt64('edb88320', 16)
  [uint64]$crc = $mask
  foreach ($byte in $Bytes) { $crc = $crc -bxor [uint64]$byte; for ($bit = 0; $bit -lt 8; $bit++) { $crc = if (($crc -band [uint64]1) -eq [uint64]1) { (($crc -shr 1) -bxor $polynomial) -band $mask } else { ($crc -shr 1) -band $mask } } }
  ($crc -bxor $mask) -band $mask
}
function Chunk([string]$Type, [object]$Payload = $null) {
  [byte[]]$PayloadBytes = [byte[]]::new(0)
  if ($null -ne $Payload) { $PayloadBytes = [byte[]]$Payload }
  $kind = [Text.Encoding]::ASCII.GetBytes($Type)
  Join-Bytes @((U32 $PayloadBytes.Length), $kind, $PayloadBytes, (U32 (Crc32 (Join-Bytes @($kind,$PayloadBytes)))))
}
function HeaderOnly-Chunk([string]$Type, [uint64]$DeclaredLength) {
  Join-Bytes @((U32 $DeclaredLength), [Text.Encoding]::ASCII.GetBytes($Type))
}
function Hex([string]$Value) {
  if ([string]::IsNullOrEmpty($Value)) { return [byte[]]@() }
  if ($Value.Length % 2) { throw "Odd hex length: $Value" }
  [byte[]]@((0..(($Value.Length/2)-1) | ForEach-Object { [Convert]::ToByte($Value.Substring($_*2,2),16) }))
}
function Moon-Bytes([byte[]]$Value) { (($Value | ForEach-Object { '\x{0:x2}' -f $_ }) -join '') }
function New-IccpZlib($Description) {
  $kind = if ($null -ne $Description.PSObject.Properties['iccp_profile']) { [string]$Description.iccp_profile } elseif ($null -ne $Description.PSObject.Properties['iccp_rgb_profile'] -and [bool]$Description.iccp_rgb_profile) { 'rgb' } else { return ,([byte[]]@()) }
  if ($kind -notin @('rgb','header','size','signature','gray','inflated')) { throw "Invalid iCCP profile fixture kind: $kind" }
  $length = if ($kind -eq 'header') { 127 } elseif ($kind -eq 'inflated') { 256 } else { 128 }
  $profile = [byte[]]::new($length); (U32 ([uint64]$length)).CopyTo($profile,0)
  [Text.Encoding]::ASCII.GetBytes($(if ($kind -eq 'gray') { 'GRAY' } else { 'RGB ' })).CopyTo($profile,16)
  [Text.Encoding]::ASCII.GetBytes('acsp').CopyTo($profile,36)
  if ($kind -eq 'size') { $profile[3] = 127 }
  if ($kind -eq 'signature') { $profile[36] = [byte][char]'x' }
  [uint64]$s1 = 1; [uint64]$s2 = 0
  foreach ($byte in $profile) { $s1 = ($s1 + $byte) % 65521; $s2 = ($s2 + $s1) % 65521 }
  $zlib = [Collections.Generic.List[byte]]::new()
  $zlib.AddRange([byte[]]@(0x78,0x01,0x01,[byte]($length -band 255),[byte]($length -shr 8),[byte]((-bnot $length) -band 255),[byte](((-bnot $length) -shr 8) -band 255)))
  $zlib.AddRange($profile)
  $zlib.AddRange([byte[]]@([byte]($s2 -shr 8),[byte]($s2 -band 255),[byte]($s1 -shr 8),[byte]($s1 -band 255)))
  return ,$zlib.ToArray()
}
function Colour-Payload($Description) {
  $payload = if ($null -ne $Description.PSObject.Properties['payload_hex']) { Hex ([string]$Description.payload_hex) } else { [byte[]]@() }
  $zlib = New-IccpZlib $Description
  if ($zlib.Length) {
    $joined = [Collections.Generic.List[byte]]::new(); $joined.AddRange($payload); $joined.AddRange($zlib)
    $payload = $joined.ToArray()
  }
  if ($null -ne $Description.PSObject.Properties['payload_repeat_hex']) {
    $unit = Hex ([string]$Description.payload_repeat_hex)
    $count = [int]$Description.payload_repeat_count
    if ($unit.Length -eq 0 -or $count -lt 0) { throw 'Invalid repeated colour payload description.' }
    $expanded = [Collections.Generic.List[byte]]::new()
    for ($index = 0; $index -lt $count; $index++) { $expanded.AddRange($unit) }
    $expanded.AddRange($payload)
    return ,$expanded.ToArray()
  }
  return ,$payload
}
function Colour-Placement($Description) {
  if ($null -eq $Description.PSObject.Properties['placement']) { return 'before-plte' }
  [string]$Description.placement
}
function Test-HeaderOnlyColour($Description) {
  if ($null -eq $Description.PSObject.Properties['header_only']) { return $false }
  if ($Description.header_only -isnot [bool] -or -not [bool]$Description.header_only) { throw 'header_only colour chunks must use the boolean true marker.' }
  return $true
}
function Assert-HeaderOnlyColourDescription($Description) {
  $kind = [string]$Description.kind
  if ($kind -notin @('sRGB','gAMA','cHRM')) { throw "Header-only colour chunks must be fixed-size: $kind" }
  if ($null -eq $Description.PSObject.Properties['declared_length']) { throw 'Header-only colour chunks require declared_length.' }
  if ($null -ne $Description.PSObject.Properties['payload_hex'] -or $null -ne $Description.PSObject.Properties['payload_repeat_hex'] -or $null -ne $Description.PSObject.Properties['payload_repeat_count']) { throw 'Header-only colour chunks cannot carry payload fields.' }
  if ((Colour-Placement $Description) -ne 'before-plte') { throw 'Header-only colour chunks must precede PLTE and IDAT.' }
  $declaredText = [string]$Description.declared_length
  if ($declaredText -notmatch '^\d+$') { throw 'Header-only declared_length must be an unsigned integer.' }
  [uint64]$declaredLength = $declaredText
  if ($declaredLength -ne 2147483647) { throw 'Header-only colour chunks must declare the PNG global maximum of 2147483647 bytes.' }
  return $declaredLength
}
function HeaderOnly-ColourChunkCount($Case) {
  $count = 0
  if ($null -ne $Case.PSObject.Properties['colour_chunks']) { foreach ($description in @($Case.colour_chunks)) { if (Test-HeaderOnlyColour $description) { $count++ } } }
  return $count
}
function Add-ColourChunks($Parts, $Case, [string]$Placement) {
  if ($null -eq $Case.PSObject.Properties['colour_chunks']) { return }
  foreach ($description in @($Case.colour_chunks)) {
    if ((Colour-Placement $description) -eq $Placement) {
      $kind = [string]$description.kind
      if ($kind -notin @('sRGB','gAMA','cHRM','iCCP')) { throw "Unsupported colour chunk description: $kind" }
      if (Test-HeaderOnlyColour $description) {
        [uint64]$declaredLength = Assert-HeaderOnlyColourDescription $description
        $Parts.Add((HeaderOnly-Chunk -Type $kind -DeclaredLength $declaredLength))
        continue
      }
      if ($null -ne $description.PSObject.Properties['declared_length']) { throw 'declared_length is supported only with header_only colour chunks.' }
      [byte[]]$payload = @()
      if ($null -ne $description.PSObject.Properties['payload_hex']) { $payload = [byte[]](Hex ([string]$description.payload_hex)) }
      if ($null -ne $description.PSObject.Properties['payload_repeat_hex']) {
        [byte[]]$unit = Hex ([string]$description.payload_repeat_hex); $count = [int]$description.payload_repeat_count
        if ($unit.Length -eq 0 -or $count -lt 0) { throw 'Invalid repeated colour payload description.' }
        $expanded = [Collections.Generic.List[byte]]::new()
        $expanded.AddRange($payload)
        for ($index = 0; $index -lt $count; $index++) { $expanded.AddRange($unit) }
        $payload = $expanded.ToArray()
      }
      $zlib = New-IccpZlib $description
      if ($zlib.Length) {
        $joined = [Collections.Generic.List[byte]]::new(); $joined.AddRange($payload); $joined.AddRange($zlib)
        $payload = $joined.ToArray()
      }
      if ($null -ne $description.PSObject.Properties['iccp_compressed_repeat']) {
        $count = [int]$description.iccp_compressed_repeat
        if ($count -le 0) { throw 'iCCP compressed repeat must be positive.' }
        $expanded = [Collections.Generic.List[byte]]::new(); $expanded.AddRange($payload)
        for ($index = 0; $index -lt $count; $index++) { $expanded.Add(0) }
        $payload = $expanded.ToArray()
      }
      $Parts.Add((Chunk -Type $kind -Payload ([byte[]]$payload)));
    }
  }
}
function Read-U32([byte[]]$Bytes, [int]$Offset) {
  ([uint64]$Bytes[$Offset] -shl 24) -bor ([uint64]$Bytes[$Offset + 1] -shl 16) -bor ([uint64]$Bytes[$Offset + 2] -shl 8) -bor [uint64]$Bytes[$Offset + 3]
}
function Assert-ColourPayloadOracle([string]$Kind, [object]$Payload = $null) {
  [byte[]]$PayloadBytes = [byte[]]::new(0)
  if ($null -ne $Payload) { $PayloadBytes = [byte[]]$Payload }
  $Payload = $PayloadBytes
  if ($Kind -eq 'sRGB') { if ($Payload.Length -ne 1) { return 'png-srgb-length' }; if ($Payload[0] -gt 3) { return 'png-srgb-intent' }; return '' }
  if ($Kind -eq 'gAMA') { if ($Payload.Length -ne 4) { return 'png-gama-length' }; if ((Read-U32 $Payload 0) -eq 0) { return 'png-gama-zero' }; return '' }
  if ($Kind -eq 'cHRM') { if ($Payload.Length -ne 32) { return 'png-chrm-length' }; return '' }
  $nul = [Array]::IndexOf($Payload, [byte]0)
  if ($nul -eq -1) { return 'png-iccp-envelope' }
  if ($nul -eq 0) { return 'png-iccp-name' }
  if ($nul -gt 79) { return 'png-iccp-name' }
  $lastSpace = $false
  for ($index = 0; $index -lt $nul; $index++) {
    $byte = $Payload[$index]
    $printable = ($byte -ge 32 -and $byte -le 126) -or ($byte -ge 161 -and $byte -le 255)
    if (-not $printable -or ($index -eq 0 -and $byte -eq 32) -or ($byte -eq 32 -and $lastSpace)) { return 'png-iccp-name' }
    $lastSpace = $byte -eq 32
  }
  if ($lastSpace) { return 'png-iccp-name' }
  if ($nul + 1 -ge $Payload.Length) { return 'png-iccp-envelope' }
  if ($Payload[$nul + 1] -ne 0) { return 'png-iccp-method' }
  if ($nul + 2 -ge $Payload.Length) { return 'png-iccp-data' }
  return ''
}
function Assert-PngAssemblyOracle([byte[]]$Png, $Case) {
  $signature = [byte[]](0x89,80,78,71,13,10,26,10)
  if ($Png.Length -lt 20 -or -not [Linq.Enumerable]::SequenceEqual([byte[]]$Png[0..7], $signature)) { throw "PNG assembly oracle signature mismatch: $($Case.id)" }
  $at = 8; $seenPalette = $false; $seenIdat = $false; $seen = @{}; $colourCount = 0; $expectedColourCount = if ($null -eq $Case.PSObject.Properties['colour_chunks']) { 0 } else { @($Case.colour_chunks).Count }
  while ($at -lt $Png.Length) {
    if ($at + 12 -gt $Png.Length) {
      if ($at + 8 -ne $Png.Length -or (HeaderOnly-ColourChunkCount $Case) -ne 1) { throw "PNG assembly oracle truncation: $($Case.id)" }
      $headerOnly = @($Case.colour_chunks | Where-Object { Test-HeaderOnlyColour $_ })
      if ($headerOnly.Count -ne 1) { throw "PNG assembly oracle ambiguous header-only colour chunk: $($Case.id)" }
      $kind = [Text.Encoding]::ASCII.GetString($Png, $at + 4, 4)
      [uint64]$declaredLength = Assert-HeaderOnlyColourDescription $headerOnly[0]
      if ($kind -cne [string]$headerOnly[0].kind -or (Read-U32 $Png $at) -ne $declaredLength) { throw "PNG assembly oracle header-only mismatch: $($Case.id)" }
      $failure = Assert-ColourPayloadOracle $kind ([byte[]]@())
      if (-not $failure -or ([string]$Case.context) -cne $failure) { throw "PNG header-only oracle context mismatch: $($Case.id)" }
      if ($colourCount + 1 -ne $expectedColourCount) { throw "PNG colour chunk count mismatch: $($Case.id)" }
      return
    }
    $length = [int](Read-U32 $Png $at); $kind = [Text.Encoding]::ASCII.GetString($Png, $at + 4, 4); $payloadAt = $at + 8; $end = $payloadAt + $length
    if ($end + 4 -gt $Png.Length) { throw "PNG assembly oracle length mismatch: $($Case.id)" }
    $payload = if ($length) { [byte[]]$Png[$payloadAt..($end - 1)] } else { [byte[]]@() }
    if ((Read-U32 $Png $end) -ne (Crc32 (Join-Bytes @([Text.Encoding]::ASCII.GetBytes($kind),$payload)))) {
      if ([string]$Case.context -ne 'png-crc') { throw "PNG assembly oracle CRC mismatch: $($Case.id)" }
    }
    if ($kind -in @('sRGB','gAMA','cHRM','iCCP')) {
      $colourCount++
      if ($seenPalette -or $seenIdat) { $failure = 'png-colour-order' } elseif ($seen.ContainsKey($kind)) { $failure = "png-$($kind.ToLowerInvariant())-duplicate" } else { $failure = Assert-ColourPayloadOracle $kind $payload }
      $seen[$kind] = $true
      if ($failure -and ([string]$Case.context) -ne $failure) { throw "PNG colour oracle context mismatch: $($Case.id): expected $failure" }
    }
    if ($kind -eq 'PLTE') { $seenPalette = $true }
    if ($kind -eq 'IDAT') { $seenIdat = $true }
    $at = $end + 4
  }
  if ($colourCount -ne $expectedColourCount) { throw "PNG colour chunk count mismatch: $($Case.id)" }
}
function Convert-Adam7ToNonInterlaced([byte[]]$Scan, [int]$Width, [int]$Height, [int]$BitDepth, [int]$Channels) {
  # This is deliberately an oracle-side implementation: it independently undoes
  # Adam7 pass filtering and scatters pass-local samples into ordinary scanlines.
  # The decoder under test is never used to construct expected pixels.
  if ($Width -le 0 -or $Height -le 0) { throw 'Adam7 oracle requires positive dimensions.' }
  $packed = $BitDepth -lt 8
  if ($packed -and $Channels -ne 1) { throw 'Adam7 oracle only permits packed one-channel pixels.' }
  if ($packed -and $BitDepth -notin @(1,2,4)) { throw 'Invalid packed Adam7 depth.' }
  if (-not $packed -and $BitDepth -notin @(8,16)) { throw 'Invalid byte-aligned Adam7 depth.' }
  $bytesPerPixel = if ($packed) { 1 } else { $Channels * ($BitDepth / 8) }
  $passes = @(
    [int[]]@(0,0,8,8), [int[]]@(4,0,8,8), [int[]]@(0,4,4,8),
    [int[]]@(2,0,4,4), [int[]]@(0,2,2,4), [int[]]@(1,0,2,2), [int[]]@(0,1,1,2)
  )
  [byte[]]$full = if ($packed) { [byte[]]::new($Width * $Height) } else { [byte[]]::new($Width * $Height * $bytesPerPixel) }
  $at = 0
  foreach ($pass in $passes) {
    $startX = $pass[0]; $startY = $pass[1]; $stepX = $pass[2]; $stepY = $pass[3]
    $passWidth = if ($Width -le $startX) { 0 } else { [int][Math]::Floor(($Width - $startX + $stepX - 1) / $stepX) }
    $passHeight = if ($Height -le $startY) { 0 } else { [int][Math]::Floor(($Height - $startY + $stepY - 1) / $stepY) }
    if ($passWidth -eq 0 -or $passHeight -eq 0) { continue }
    $stride = if ($packed) { [int][Math]::Ceiling(([double]$passWidth * $BitDepth) / 8) } else { $passWidth * $bytesPerPixel }
    [byte[]]$previous = [byte[]]::new($stride)
    for ($passY = 0; $passY -lt $passHeight; $passY++) {
      if ($at -ge $Scan.Length) { throw 'Adam7 scanline oracle input is truncated.' }
      $filter = $Scan[$at++]
      if ($filter -gt 4) { throw 'Invalid Adam7 source filter oracle input.' }
      [byte[]]$current = [byte[]]::new($stride)
      for ($column = 0; $column -lt $stride; $column++) {
        if ($at -ge $Scan.Length) { throw 'Adam7 scanline oracle input is truncated.' }
        $raw = $Scan[$at++]
        $left = if ($column -ge $bytesPerPixel) { $current[$column - $bytesPerPixel] } else { 0 }
        $above = if ($passY) { $previous[$column] } else { 0 }
        $upperLeft = if ($passY -and $column -ge $bytesPerPixel) { $previous[$column - $bytesPerPixel] } else { 0 }
        $predict = if ($filter -eq 0) { 0 } elseif ($filter -eq 1) { $left } elseif ($filter -eq 2) { $above } elseif ($filter -eq 3) { ($left + $above) -shr 1 } else {
          $p = $left + $above - $upperLeft; $pa = [Math]::Abs($p - $left); $pb = [Math]::Abs($p - $above); $pc = [Math]::Abs($p - $upperLeft)
          if ($pa -le $pb -and $pa -le $pc) { $left } elseif ($pb -le $pc) { $above } else { $upperLeft }
        }
        $current[$column] = ($raw + $predict) % 256
      }
      $y = $startY + $passY * $stepY
      for ($passX = 0; $passX -lt $passWidth; $passX++) {
        $x = $startX + $passX * $stepX
        if ($packed) {
          $bit = $passX * $BitDepth
          $sample = ($current[[int][Math]::Floor($bit / 8)] -shr (8 - $BitDepth - ($bit % 8))) -band ((1 -shl $BitDepth) - 1)
          $full[$y * $Width + $x] = $sample
        } else {
          [Array]::Copy($current, $passX * $bytesPerPixel, $full, ($y * $Width + $x) * $bytesPerPixel, $bytesPerPixel)
        }
      }
      $previous = $current
    }
  }
  if ($at -ne $Scan.Length) { throw 'Adam7 scanline oracle input has trailing bytes.' }
  $normal = [Collections.Generic.List[byte]]::new()
  for ($y = 0; $y -lt $Height; $y++) {
    $normal.Add(0)
    if ($packed) {
      $stride = [int][Math]::Ceiling(([double]$Width * $BitDepth) / 8)
      [byte[]]$row = [byte[]]::new($stride)
      for ($x = 0; $x -lt $Width; $x++) {
        $bit = $x * $BitDepth; $shift = 8 - $BitDepth - ($bit % 8)
        $row[[int][Math]::Floor($bit / 8)] = $row[[int][Math]::Floor($bit / 8)] -bor ($full[$y * $Width + $x] -shl $shift)
      }
      $normal.AddRange($row)
    } else {
      $rowOffset = $y * $Width * $bytesPerPixel
      [byte[]]$row = $full[$rowOffset..($rowOffset + $Width * $bytesPerPixel - 1)]
      $normal.AddRange($row)
    }
  }
  return ,$normal.ToArray()
}
function New-Png($Case, [int[]]$Splits) {
  $zlib = Hex $Case.zlib_hex
  $parts = [Collections.Generic.List[object]]::new()
  $bitDepth = if ($null -ne $Case.PSObject.Properties['bit_depth']) { [byte]$Case.bit_depth } else { [byte]8 }
  $interlaceMethod = if ($null -ne $Case.PSObject.Properties['interlace_method']) { [byte]$Case.interlace_method } else { [byte]0 }
  if ($Case.outcome -eq 'accepted' -and $interlaceMethod -notin @([byte]0,[byte]1)) { throw "Invalid PNG interlace method fixture input: $($Case.id)" }
  $parts.Add((Chunk 'IHDR' (Join-Bytes @((U32 $Case.width),(U32 $Case.height),[byte[]]($bitDepth,$Case.colour_type,0,0,$interlaceMethod)))))
  $hasPlte = $null -ne $Case.PSObject.Properties['plte_length'] -or $null -ne $Case.PSObject.Properties['plte_hex']
  [byte[]]$plte = @()
  if ($null -ne $Case.PSObject.Properties['plte_length']) { $plte = [byte[]]::new([int]$Case.plte_length) }
  elseif ($null -ne $Case.PSObject.Properties['plte_hex']) { $plte = Hex $Case.plte_hex }
  $variant = if ($Case.PSObject.Properties['variant']) { [string]$Case.variant } else { 'normal' }
  $trns = if ($null -ne $Case.PSObject.Properties['trns_hex']) { Hex $Case.trns_hex } elseif ($variant -like 'trns*') { [byte[]]@(0) } else { $null }
  if ((HeaderOnly-ColourChunkCount $Case) -gt 1) { throw "Only one header-only colour chunk is allowed: $($Case.id)" }
  Add-ColourChunks $parts $Case 'before-plte'
  if ((HeaderOnly-ColourChunkCount $Case) -eq 1) {
    $png = Join-Bytes @([byte[]](0x89,80,78,71,13,10,26,10), (Join-Bytes $parts.ToArray()))
    Assert-PngAssemblyOracle $png $Case
    return $png
  }
  if ($null -ne $trns -and $variant -eq 'trns-before-plte') { $parts.Add((Chunk 'tRNS' $trns)) }
  if ($hasPlte -and $variant -ne 'missing-plte') {
    $chunk = Chunk 'PLTE' $plte
    if ($variant -eq 'plte-crc') { $chunk = [byte[]]$chunk.Clone(); $chunk[$chunk.Length - 1] = $chunk[$chunk.Length - 1] -bxor 1 }
    $parts.Add($chunk)
    if ($variant -eq 'plte-duplicate') { $parts.Add((Chunk 'PLTE' $plte)) }
  }
  Add-ColourChunks $parts $Case 'after-plte'
  if ($null -ne $trns -and $variant -ne 'trns-before-plte' -and $variant -ne 'trns-after-idat') {
    $chunk = Chunk 'tRNS' $trns
    if ($variant -eq 'trns-crc') { $chunk = [byte[]]$chunk.Clone(); $chunk[$chunk.Length - 1] = $chunk[$chunk.Length - 1] -bxor 1 }
    $parts.Add($chunk)
    if ($variant -eq 'trns-duplicate') { $parts.Add((Chunk 'tRNS' $trns)) }
  }
  $offset = 0
  foreach ($split in $Splits) { $count = [int]$split; if ($count -le 0 -or $offset + $count -gt $zlib.Length) { throw "Invalid IDAT split: $($Case.id)" }; $parts.Add((Chunk 'IDAT' $zlib[$offset..($offset+$count-1)])); $offset += $count }
  if ($offset -ne $zlib.Length) { throw "IDAT splits do not cover zlib payload: $($Case.id)" }
  Add-ColourChunks $parts $Case 'after-idat'
  if ($hasPlte -and $variant -eq 'plte-after-idat') { $parts.Add((Chunk 'PLTE' $plte)) }
  if ($null -ne $trns -and $variant -eq 'trns-after-idat') { $parts.Add((Chunk 'tRNS' $trns)) }
  $parts.Add((Chunk 'IEND' ([byte[]]@())))
  $png = Join-Bytes @([byte[]](0x89,80,78,71,13,10,26,10), (Join-Bytes $parts.ToArray()))
  Assert-PngAssemblyOracle $png $Case
  $png
}
function Assert-Oracle($Case) {
  $zlib = Hex $Case.zlib_hex
  if (($Case.colour_type -eq 4 -or $Case.colour_type -eq 6) -and $null -ne $Case.PSObject.Properties['trns_hex'] -and $Case.outcome -eq 'accepted') { throw "Native-alpha tRNS must be hostile evidence: $($Case.id)" }
  if ($Case.outcome -eq 'accepted') {
    Add-Type -AssemblyName System.IO.Compression
    $input = [IO.MemoryStream]::new($zlib); $stream = [IO.Compression.ZLibStream]::new($input,[IO.Compression.CompressionMode]::Decompress); $output = [IO.MemoryStream]::new(); $stream.CopyTo($output); $stream.Dispose()
    if ($output.Length -eq 0) { throw "Independent zlib oracle produced no scanlines: $($Case.id)" }
    $interlaceMethod = if ($null -ne $Case.PSObject.Properties['interlace_method']) { [int]$Case.interlace_method } else { 0 }
    if ($interlaceMethod -notin @(0,1)) { throw "Invalid PNG interlace method oracle input: $($Case.id)" }
    $decodedScan = $output.ToArray()
    if ($interlaceMethod -eq 1) {
      $depth = if ($null -ne $Case.PSObject.Properties['bit_depth']) { [int]$Case.bit_depth } else { 8 }
      $channels = if ($Case.colour_type -eq 0 -or $Case.colour_type -eq 3) { 1 } elseif ($Case.colour_type -eq 2) { 3 } elseif ($Case.colour_type -eq 4) { 2 } elseif ($Case.colour_type -eq 6) { 4 } else { throw "Invalid Adam7 colour type oracle input: $($Case.id)" }
      $decodedScan = Convert-Adam7ToNonInterlaced $decodedScan ([int]$Case.width) ([int]$Case.height) $depth $channels
    }
    $btype = ($zlib[2] -shr 1) -band 3
    if ($Case.id -notlike 'lowbit-*' -and (($Case.block -eq 'fixed' -and $btype -ne 1) -or ($Case.block -eq 'dynamic' -and $btype -ne 2))) { throw "Unexpected DEFLATE block type: $($Case.id)" }
    if ($Case.colour_type -eq 0 -or $Case.colour_type -eq 2) {
      $sourceChannels = if ($Case.colour_type -eq 0) { 1 } else { 3 }
      $depth = if ($null -ne $Case.PSObject.Properties['bit_depth']) { [int]$Case.bit_depth } else { 8 }
      if ($Case.colour_type -eq 0 -and $depth -notin @(1,2,4,8,16)) { throw "Invalid grayscale depth oracle input: $($Case.id)" }
      if ($Case.colour_type -eq 2 -and $depth -notin @(8,16)) { throw "Invalid truecolour depth oracle input: $($Case.id)" }
      $sampleBytes = if ($depth -eq 16) { 2 } else { 1 }
      $stride = if ($Case.colour_type -eq 0 -and $depth -lt 8) { [int][Math]::Ceiling(([double]$Case.width * $depth) / 8) } else { [int]$Case.width * $sourceChannels * $sampleBytes }
      $bpp = if ($depth -eq 16) { $sourceChannels * 2 } elseif ($Case.colour_type -eq 0) { 1 } else { $sourceChannels }
      $scan = $decodedScan; $previous = [byte[]]::new($stride); $pixels = [Collections.Generic.List[byte]]::new(); [byte[]]$key = [byte[]]::new(0); if ($null -ne $Case.PSObject.Properties['trns_hex']) { $key = Hex $Case.trns_hex }; $at = 0
      $mask = if ($depth -eq 1) { 1 } elseif ($depth -eq 2) { 3 } elseif ($depth -eq 4) { 15 } else { 255 }
      $invalidKey = if ($Case.colour_type -eq 0) {
        $key.Length -ne 2 -or ($depth -ne 16 -and ($key[0] -ne 0 -or $key[1] -gt $mask))
      } else {
        $key.Length -ne 6 -or ($depth -ne 16 -and ($key[0] -ne 0 -or $key[2] -ne 0 -or $key[4] -ne 0))
      }
      if ($key.Length -and $invalidKey) { throw "Invalid tRNS key oracle input: $($Case.id)" }
      for ($y = 0; $y -lt $Case.height; $y++) {
        $filter = $scan[$at++]; if ($filter -gt 4) { throw "Invalid source filter oracle input: $($Case.id)" }; $current = [byte[]]::new($stride)
        for ($column = 0; $column -lt $stride; $column++) {
          $raw=$scan[$at++]; $left=if($column -ge $bpp){$current[$column-$bpp]}else{0}; $above=if($y){$previous[$column]}else{0}; $ul=if($y -and $column -ge $bpp){$previous[$column-$bpp]}else{0}; $predict=if($filter -eq 0){0}elseif($filter -eq 1){$left}elseif($filter -eq 2){$above}elseif($filter -eq 3){($left+$above) -shr 1}else{$p=$left+$above-$ul;$pa=[Math]::Abs($p-$left);$pb=[Math]::Abs($p-$above);$pc=[Math]::Abs($p-$ul);if($pa -le $pb -and $pa -le $pc){$left}elseif($pb -le $pc){$above}else{$ul}}; $current[$column]=($raw+$predict)%256
        }
        for ($x = 0; $x -lt $Case.width; $x++) {
          if ($Case.colour_type -eq 0) {
            if ($depth -eq 16) {
              $base = $x * 2; $high = $current[$base]; $low = $current[$base+1]; $pixels.Add($high); $pixels.Add($high); $pixels.Add($high); if ($key.Length) { $pixels.Add($(if($high -eq $key[0] -and $low -eq $key[1]){0}else{255})) }
            } else {
              $bit = $x * $depth; $raw = ($current[[int][Math]::Floor($bit / 8)] -shr (8 - $depth - ($bit % 8))) -band $mask; $value = if ($depth -eq 1) { $raw * 255 } elseif ($depth -eq 2) { $raw * 85 } elseif ($depth -eq 4) { $raw * 17 } else { $raw }; $pixels.Add($value); $pixels.Add($value); $pixels.Add($value); if ($key.Length) { $pixels.Add($(if($raw -eq $key[1]){0}else{255})) }
            }
          } else {
            if ($depth -eq 16) {
              $base = $x * 6; $red=$current[$base]; $redLow=$current[$base+1]; $green=$current[$base+2]; $greenLow=$current[$base+3]; $blue=$current[$base+4]; $blueLow=$current[$base+5]; $pixels.Add($red); $pixels.Add($green); $pixels.Add($blue); if ($key.Length) { $pixels.Add($(if($red -eq $key[0] -and $redLow -eq $key[1] -and $green -eq $key[2] -and $greenLow -eq $key[3] -and $blue -eq $key[4] -and $blueLow -eq $key[5]){0}else{255})) }
            } else {
              $base = $x * 3; $red=$current[$base]; $green=$current[$base+1]; $blue=$current[$base+2]; $pixels.Add($red); $pixels.Add($green); $pixels.Add($blue); if ($key.Length) { $pixels.Add($(if($red -eq $key[1] -and $green -eq $key[3] -and $blue -eq $key[5]){0}else{255})) }
            }
          }
        }
        $previous=$current
      }
      if ((Moon-Bytes $pixels.ToArray()) -cne (Moon-Bytes (Hex $Case.pixels_hex))) { throw "Source-bpp tRNS oracle mismatch: $($Case.id)" }
    } elseif ($Case.colour_type -eq 4 -or $Case.colour_type -eq 6) {
      $depth = if ($null -ne $Case.PSObject.Properties['bit_depth']) { [int]$Case.bit_depth } else { 8 }
      if ($depth -notin @(8,16)) { throw "Invalid native-alpha depth oracle input: $($Case.id)" }
      $sourceChannels = if ($Case.colour_type -eq 4) { 2 } else { 4 }; $sampleBytes = if ($depth -eq 16) { 2 } else { 1 }; $sourceBpp = $sourceChannels * $sampleBytes
      $scan = $decodedScan; $stride = [int]$Case.width * $sourceBpp; if ($scan.Length -ne ($stride + 1) * $Case.height) { throw "Native-alpha filtered size oracle mismatch: $($Case.id)" }; $previous = [byte[]]::new($stride); $pixels = [Collections.Generic.List[byte]]::new(); $at = 0
      for ($y = 0; $y -lt $Case.height; $y++) {
        $filter = $scan[$at++]; if ($filter -gt 4) { throw "Invalid native-alpha filter oracle input: $($Case.id)" }; $current = [byte[]]::new($stride)
        for ($column = 0; $column -lt $stride; $column++) { $raw=$scan[$at++]; $left=if($column -ge $sourceBpp){$current[$column-$sourceBpp]}else{0}; $above=if($y){$previous[$column]}else{0}; $ul=if($y -and $column -ge $sourceBpp){$previous[$column-$sourceBpp]}else{0}; $predict=if($filter -eq 0){0}elseif($filter -eq 1){$left}elseif($filter -eq 2){$above}elseif($filter -eq 3){($left+$above) -shr 1}else{$p=$left+$above-$ul;$pa=[Math]::Abs($p-$left);$pb=[Math]::Abs($p-$above);$pc=[Math]::Abs($p-$ul);if($pa -le $pb -and $pa -le $pc){$left}elseif($pb -le $pc){$above}else{$ul}}; $current[$column]=($raw+$predict)%256 }
        for ($x = 0; $x -lt $Case.width; $x++) { $base = $x * $sourceBpp; if ($Case.colour_type -eq 4) { $gray=$current[$base]; $pixels.Add($gray);$pixels.Add($gray);$pixels.Add($gray);$pixels.Add($current[$base+$sampleBytes]) } else { $pixels.Add($current[$base]);$pixels.Add($current[$base+$sampleBytes]);$pixels.Add($current[$base+2*$sampleBytes]);$pixels.Add($current[$base+3*$sampleBytes]) } }
        $previous=$current
      }
      if ((Moon-Bytes $pixels.ToArray()) -cne (Moon-Bytes (Hex $Case.pixels_hex))) { throw "Native-alpha RGBA oracle mismatch: $($Case.id)" }
    } elseif ($Case.colour_type -eq 3) {
      $palette = Hex $Case.plte_hex
      if ($palette.Length -lt 3 -or $palette.Length -gt 768 -or $palette.Length % 3) { throw "Invalid indexed PLTE oracle input: $($Case.id)" }
      $depth = if ($null -ne $Case.PSObject.Properties['bit_depth']) { [int]$Case.bit_depth } else { 8 }
      if ($depth -notin @(1,2,4,8)) { throw "Invalid indexed depth oracle input: $($Case.id)" }
      $entries = [int]($palette.Length / 3); if ($entries -gt (1 -shl $depth)) { throw "Indexed PLTE exceeds active depth: $($Case.id)" }
      $scan = $decodedScan; $stride = [int][Math]::Ceiling(([double]$Case.width * $depth) / 8); $previous = [byte[]]::new($stride); $pixels = [Collections.Generic.List[byte]]::new(); [byte[]]$alpha = [byte[]]::new(0); if ($null -ne $Case.PSObject.Properties['trns_hex']) { $alpha = Hex $Case.trns_hex }; if ($alpha.Length -gt $entries) { throw "Indexed tRNS exceeds PLTE: $($Case.id)" }; $at = 0; $mask = (1 -shl $depth) - 1
      for ($y = 0; $y -lt $Case.height; $y++) {
        $filter = $scan[$at++]; if ($filter -gt 4) { throw "Invalid indexed filter oracle input: $($Case.id)" }; $current = [byte[]]::new($stride)
        for ($column = 0; $column -lt $stride; $column++) { $raw=$scan[$at++]; $left=if($column){$current[$column-1]}else{0}; $above=if($y){$previous[$column]}else{0}; $ul=if($column -and $y){$previous[$column-1]}else{0}; $predict=if($filter -eq 0){0}elseif($filter -eq 1){$left}elseif($filter -eq 2){$above}elseif($filter -eq 3){($left+$above) -shr 1}else{$p=$left+$above-$ul;$pa=[Math]::Abs($p-$left);$pb=[Math]::Abs($p-$above);$pc=[Math]::Abs($p-$ul);if($pa -le $pb -and $pa -le $pc){$left}elseif($pb -le $pc){$above}else{$ul}}; $current[$column]=($raw+$predict)%256 }
        for ($x = 0; $x -lt $Case.width; $x++) { $bit=$x*$depth; $index=($current[[int][Math]::Floor($bit / 8)] -shr (8-$depth-($bit%8))) -band $mask; if ($index -ge $entries) { throw "Indexed sample exceeds PLTE: $($Case.id)" }; $base=$index*3; $pixels.Add($palette[$base]);$pixels.Add($palette[$base+1]);$pixels.Add($palette[$base+2]); if($alpha.Length){$pixels.Add($(if($index -lt $alpha.Length){$alpha[$index]}else{255}))} }
        $previous=$current
      }
      if ((Moon-Bytes $pixels.ToArray()) -cne (Moon-Bytes (Hex $Case.pixels_hex))) { throw "Indexed RGB oracle mismatch: $($Case.id)" }
    }
  }
}

$corpus = Get-Content -Raw -LiteralPath $CasesPath | ConvertFrom-Json
$required = @('fixed-rgb-filters-every-idat-byte','fixed-grayscale-filters-every-idat-boundary','lowbit-gray-1-filters','lowbit-gray-2-filters','lowbit-gray-4-filters','lowbit-gray-8-filters','lowbit-trns-gray-1','lowbit-trns-gray-2','lowbit-trns-gray-4','lowbit-trns-gray-high-byte','lowbit-trns-gray-mask','lowbit-indexed-1-filters','lowbit-indexed-2-filters','lowbit-indexed-4-filters','lowbit-trns-indexed-2-filters','lowbit-indexed-depth','lowbit-indexed-plte-depth','lowbit-indexed-palette-index','dynamic-rgba-filters-semantic-idat-split','indexed-filters-every-idat-boundary','trns-grayscale-filters','trns-rgb-filters','trns-indexed-filters','indexed-missing-plte','indexed-plte-length-0','indexed-plte-length-1','indexed-plte-length-2','indexed-plte-length-4','indexed-plte-length-5','indexed-plte-length-769','indexed-plte-duplicate','indexed-plte-after-idat','indexed-plte-crc','indexed-palette-index','trns-duplicate','trns-after-idat','trns-before-plte','trns-crc','trns-gray-length','trns-gray-sample','trns-rgb-length','trns-rgb-sample','trns-indexed-length','trns-type6','hostile-zlib-header','hostile-truncated-deflate','hostile-adler','hostile-filter','hostile-dynamic-incomplete-tree','hostile-fixed-distance-before-history','hostile-filtered-output-expansion','gray-alpha-filters','gray-alpha-depth-1','gray-alpha-depth-2','gray-alpha-depth-4','gray-alpha-depth-16','gray-alpha-trns','gray-alpha-trns-after-idat','gray-alpha-trns-crc','gray-alpha-filter','gray-alpha-malformed','gray-alpha-limit','16gray-filters','16gray-trns','16rgb-filters','16rgb-trns','16gray-trns-length','16gray-trns-duplicate','16rgb-trns-after-idat','16rgb-trns-crc','16gray-filter','16rgb-malformed','16rgb-depth-4','16gray-alpha-depth-16','16rgba-depth-16','16gray-limit-image','16rgb-limit-output','16rgb-limit-work')
$required += @('16gray-alpha-filters','16rgba-filters','16gray-alpha-trns','16gray-alpha-trns-duplicate','16gray-alpha-trns-after-idat','16gray-alpha-trns-crc','16rgba-depth-4','16rgba-trns','16rgba-trns-duplicate','16rgba-trns-after-idat','16rgba-trns-crc','16gray-alpha-filter','16rgba-malformed','16gray-alpha-limit-image','16gray-alpha-limit-output','16gray-alpha-limit-work','16rgba-limit-image','16rgba-limit-output','16rgba-limit-work','adam7-rgba8-all-passes-idat-boundaries','adam7-gray2-trns-all-passes','adam7-indexed2-plte-trns-all-passes','adam7-rgb16-trns-all-passes','adam7-gray-alpha16-all-passes','adam7-rgba16-all-passes','adam7-invalid-interlace-method','adam7-truncated-pass-scanline','adam7-extra-pass-scanline','adam7-invalid-pass-filter','adam7-limit-output','adam7-gray1-opaque-all-passes','adam7-gray1-trns-all-passes','adam7-gray2-opaque-all-passes','adam7-gray4-opaque-all-passes','adam7-gray4-trns-all-passes','adam7-gray8-opaque-all-passes','adam7-gray8-trns-all-passes','adam7-gray16-opaque-all-passes','adam7-gray16-trns-all-passes','adam7-indexed1-opaque-all-passes','adam7-indexed1-trns-all-passes','adam7-indexed2-opaque-all-passes','adam7-indexed4-opaque-all-passes','adam7-indexed4-trns-all-passes','adam7-indexed8-opaque-all-passes','adam7-indexed8-trns-all-passes','adam7-rgb8-opaque-all-passes','adam7-rgb8-trns-all-passes','adam7-rgb16-opaque-all-passes','adam7-rgb16-trns-low-byte-all-passes','adam7-gray-alpha8-all-passes','adam7-indexed-missing-plte','adam7-indexed-palette-index','adam7-trns-after-idat','adam7-trns-duplicate','adam7-trns-crc','adam7-trns-indexed-length','adam7-malformed-compression')
$required += @('srgb-rgb-intent-0','srgb-rgba-intent-1','srgb-palette-intent-2','srgb-grayscale-intent-3','srgb-rgb16-intent-0','srgb-adam7-intent-1-split-idat','srgb-compatible-legacy','srgb-payload-empty','srgb-payload-long','srgb-intent-out-of-range','srgb-duplicate','srgb-after-plte','srgb-after-idat','gama-length','gama-zero','gama-duplicate','chrm-length','srgb-header-only-2gib','gama-header-only-2gib','chrm-header-only-2gib','srgb-legacy-conflict','gama-non-srgb-metadata','chrm-non-srgb-metadata','iccp-empty-name','iccp-overlong-name','iccp-control-name','iccp-leading-space','iccp-trailing-space','iccp-consecutive-spaces','iccp-no-nul','iccp-no-profile-data','iccp-bad-method','iccp-valid-authoritative','iccp-invalid-zlib','iccp-header','iccp-size','iccp-signature','iccp-incompatible-space','iccp-compressed-limit','iccp-inflated-limit','iccp-allocation-limit','iccp-work-limit')
if ($corpus.schema_version -ne '2.7.0' -or (Compare-Object $required @($corpus.cases.id))) { throw 'PNG decode corpus is stale or incomplete.' }
$records = [Collections.Generic.List[object]]::new()
foreach ($case in $corpus.cases) {
  $zlib = Hex $case.zlib_hex
  $group = if ($null -ne $case.PSObject.Properties['comparison_group']) { [string]$case.comparison_group } else { '' }
  if ($group.Length) {
    if ($zlib.Length -lt 2) { throw "Exhaustive IDAT vector is too short: $($case.id)" }
    $records.Add([pscustomobject]@{ case = $case; id = "$($case.id)-unsplit"; splits = [int[]]@($zlib.Length); group = $group; baseline = $true })
    for ($offset = 1; $offset -lt $zlib.Length; $offset++) {
      $records.Add([pscustomobject]@{ case = $case; id = "$($case.id)-split-$offset"; splits = [int[]]@($offset, ($zlib.Length - $offset)); group = $group; baseline = $false })
    }
  } elseif ($case.PSObject.Properties['exhaustive_idat_splits'] -and $case.exhaustive_idat_splits) {
    if ($zlib.Length -lt 2) { throw "Exhaustive IDAT vector is too short: $($case.id)" }
    for ($offset = 1; $offset -lt $zlib.Length; $offset++) {
      $records.Add([pscustomobject]@{ case = $case; id = "$($case.id)-split-$offset"; splits = [int[]]@($offset, ($zlib.Length - $offset)); group = ''; baseline = $false })
    }
  } else {
    $records.Add([pscustomobject]@{ case = $case; id = [string]$case.id; splits = [int[]]$case.idat_splits; group = ''; baseline = $false })
  }
}
$rows = [Collections.Generic.List[string]]::new()
$rows.Add('// Generated by scripts/fixtures/Generate-PngDecodeVectors.ps1. Do not edit.')
$rows.Add('')
$rows.Add('///|')
$rows.Add('priv struct PngDecodeVector { id : String; bytes : Bytes; width : UInt64; height : UInt64; channels : UInt64; pixels : Bytes; outcome : String; max_output : UInt64; max_work : UInt64; budget_bytes : UInt64; budget_allocations : UInt64; budget_allocation_size : UInt64; srgb_intent : Int; metadata_key : String; metadata_value : Bytes; icc_profile_length : UInt64; category : String; code : String; context : String; comparison_group : String; baseline : Bool }')
$rows.Add('')
$rows.Add('///|')
$rows.Add('fn _generated_png_decode_cases() -> Array[PngDecodeVector] {')
$rows.Add('  [')
foreach ($record in $records) {
  $case = $record.case
  Assert-Oracle $case
  $png = New-Png $case $record.splits; $pixels = if ($case.outcome -eq 'accepted') { Moon-Bytes (Hex $case.pixels_hex) } else { '' }; $channels = if ($case.colour_type -eq 4 -or $case.colour_type -eq 6 -or $null -ne $case.PSObject.Properties['trns_hex']) { 4 } else { 3 }; $context = if ($null -eq $case.PSObject.Properties['context']) { '' } else { [string]$case.context }; $maxOutput = if ($null -eq $case.PSObject.Properties['max_output']) { 1024 } else { [uint64]$case.max_output }; $hasIccp = $null -ne $case.PSObject.Properties['colour_chunks'] -and @($case.colour_chunks | Where-Object { $_.kind -eq 'iCCP' }).Count -gt 0; $maxWork = if ($null -ne $case.PSObject.Properties['max_work']) { [uint64]$case.max_work } elseif ($hasIccp) { 1048576 } else { 4096 }; $budgetBytes = if ($null -ne $case.PSObject.Properties['budget_bytes']) { [uint64]$case.budget_bytes } elseif ($hasIccp) { 65536 } else { 4096 }; $budgetAllocations = if ($null -eq $case.PSObject.Properties['budget_allocations']) { 8 } else { [uint64]$case.budget_allocations }; $budgetAllocationSize = if ($null -ne $case.PSObject.Properties['budget_allocation_size']) { [uint64]$case.budget_allocation_size } elseif ($hasIccp) { 32768 } else { 1024 }; $srgbIntent = if ($null -eq $case.PSObject.Properties['srgb_intent']) { -1 } else { [int]$case.srgb_intent }; $metadataKey = if ($null -eq $case.PSObject.Properties['metadata_key']) { '' } else { [string]$case.metadata_key }; $metadataValue = if ($null -eq $case.PSObject.Properties['metadata_hex']) { '' } else { Moon-Bytes (Hex $case.metadata_hex) }; $iccProfileLength = if ($null -eq $case.PSObject.Properties['icc_profile_length']) { 0 } else { [uint64]$case.icc_profile_length }; $category = if ($null -eq $case.PSObject.Properties['category']) { if ($case.outcome -eq 'limit') { 'resource' } else { 'data' } } else { [string]$case.category }; $code = if ($null -eq $case.PSObject.Properties['code']) { if ($case.outcome -eq 'limit') { 'budget-exceeded' } else { 'invalid-encoding' } } else { [string]$case.code }; $baseline = if ($record.baseline) { 'true' } else { 'false' }
  $rows.Add(('    PngDecodeVector::{{ id: "{0}", bytes: b"{1}", width: {2}UL, height: {3}UL, channels: {4}UL, pixels: b"{5}", outcome: "{6}", max_output: {7}UL, max_work: {8}UL, budget_bytes: {9}UL, budget_allocations: {10}UL, budget_allocation_size: {11}UL, srgb_intent: {12}, metadata_key: "{13}", metadata_value: b"{14}", icc_profile_length: {15}UL, category: "{16}", code: "{17}", context: "{18}", comparison_group: "{19}", baseline: {20} }},' -f $record.id,(Moon-Bytes $png),$case.width,$case.height,$channels,$pixels,$case.outcome,$maxOutput,$maxWork,$budgetBytes,$budgetAllocations,$budgetAllocationSize,$srgbIntent,$metadataKey,$metadataValue,$iccProfileLength,$category,$code,$context,$record.group,$baseline))
}
$rows.Add('  ]'); $rows.Add('}'); $rows.Add('')
$text = $rows -join "`n"
$sha = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([IO.File]::ReadAllBytes($CasesPath))).ToLowerInvariant()
$manifest = Get-Content -Raw $ManifestPath | ConvertFrom-Json
$record = @($manifest.records | Where-Object { $_.id -ceq 'png-decode-vectors' })
if ($record.Count -ne 1 -or $record[0].path -cne 'fixtures/png/decode-cases.json' -or $record[0].origin -cne 'generated' -or $record[0].license -cne 'Apache-2.0') { throw 'PNG decode fixture manifest identity is invalid.' }
if ($Check) {
  if ($record[0].sha256 -cne $sha) { throw 'PNG decode fixture manifest digest is stale.' }
  if (-not (Test-Path $OutputPath) -or ([IO.File]::ReadAllText($OutputPath,$Utf8NoBom).Replace("`r`n","`n")) -cne $text) { throw "Generated artifact stale: $OutputPath" }
} else {
  $record[0].sha256 = $sha
  [IO.File]::WriteAllText($ManifestPath, (($manifest | ConvertTo-Json -Depth 20) + "`n"), $Utf8NoBom)
  [IO.File]::WriteAllText($OutputPath,$text,$Utf8NoBom)
}
Write-Host "PNG decode vector generation/check passed ($($records.Count) executable cases)."
