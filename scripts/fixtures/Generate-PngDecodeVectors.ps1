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
function Chunk([string]$Type, [byte[]]$Payload) {
  $kind = [Text.Encoding]::ASCII.GetBytes($Type)
  Join-Bytes @((U32 $Payload.Length), $kind, $Payload, (U32 (Crc32 (Join-Bytes @($kind,$Payload)))))
}
function Hex([string]$Value) {
  if ([string]::IsNullOrEmpty($Value)) { return [byte[]]@() }
  if ($Value.Length % 2) { throw "Odd hex length: $Value" }
  [byte[]]@((0..(($Value.Length/2)-1) | ForEach-Object { [Convert]::ToByte($Value.Substring($_*2,2),16) }))
}
function Moon-Bytes([byte[]]$Value) { (($Value | ForEach-Object { '\x{0:x2}' -f $_ }) -join '') }
function New-Png($Case, [int[]]$Splits) {
  $zlib = Hex $Case.zlib_hex
  $parts = [Collections.Generic.List[object]]::new()
  $bitDepth = if ($null -ne $Case.PSObject.Properties['bit_depth']) { [byte]$Case.bit_depth } else { [byte]8 }
  $parts.Add((Chunk 'IHDR' (Join-Bytes @((U32 $Case.width),(U32 $Case.height),[byte[]]($bitDepth,$Case.colour_type,0,0,0)))))
  $hasPlte = $null -ne $Case.PSObject.Properties['plte_length'] -or $null -ne $Case.PSObject.Properties['plte_hex']
  [byte[]]$plte = @()
  if ($null -ne $Case.PSObject.Properties['plte_length']) { $plte = [byte[]]::new([int]$Case.plte_length) }
  elseif ($null -ne $Case.PSObject.Properties['plte_hex']) { $plte = Hex $Case.plte_hex }
  $variant = if ($Case.PSObject.Properties['variant']) { [string]$Case.variant } else { 'normal' }
  $trns = if ($null -ne $Case.PSObject.Properties['trns_hex']) { Hex $Case.trns_hex } elseif ($variant -like 'trns*') { [byte[]]@(0) } else { $null }
  if ($null -ne $trns -and $variant -eq 'trns-before-plte') { $parts.Add((Chunk 'tRNS' $trns)) }
  if ($hasPlte -and $variant -ne 'missing-plte') {
    $chunk = Chunk 'PLTE' $plte
    if ($variant -eq 'plte-crc') { $chunk = [byte[]]$chunk.Clone(); $chunk[$chunk.Length - 1] = $chunk[$chunk.Length - 1] -bxor 1 }
    $parts.Add($chunk)
    if ($variant -eq 'plte-duplicate') { $parts.Add((Chunk 'PLTE' $plte)) }
  }
  if ($null -ne $trns -and $variant -ne 'trns-before-plte' -and $variant -ne 'trns-after-idat') {
    $chunk = Chunk 'tRNS' $trns
    if ($variant -eq 'trns-crc') { $chunk = [byte[]]$chunk.Clone(); $chunk[$chunk.Length - 1] = $chunk[$chunk.Length - 1] -bxor 1 }
    $parts.Add($chunk)
    if ($variant -eq 'trns-duplicate') { $parts.Add((Chunk 'tRNS' $trns)) }
  }
  $offset = 0
  foreach ($split in $Splits) { $count = [int]$split; if ($count -le 0 -or $offset + $count -gt $zlib.Length) { throw "Invalid IDAT split: $($Case.id)" }; $parts.Add((Chunk 'IDAT' $zlib[$offset..($offset+$count-1)])); $offset += $count }
  if ($offset -ne $zlib.Length) { throw "IDAT splits do not cover zlib payload: $($Case.id)" }
  if ($hasPlte -and $variant -eq 'plte-after-idat') { $parts.Add((Chunk 'PLTE' $plte)) }
  if ($null -ne $trns -and $variant -eq 'trns-after-idat') { $parts.Add((Chunk 'tRNS' $trns)) }
  $parts.Add((Chunk 'IEND' ([byte[]]@())))
  Join-Bytes @([byte[]](0x89,80,78,71,13,10,26,10), (Join-Bytes $parts.ToArray()))
}
function Assert-Oracle($Case) {
  $zlib = Hex $Case.zlib_hex
  if ($Case.outcome -eq 'accepted') {
    Add-Type -AssemblyName System.IO.Compression
    $input = [IO.MemoryStream]::new($zlib); $stream = [IO.Compression.ZLibStream]::new($input,[IO.Compression.CompressionMode]::Decompress); $output = [IO.MemoryStream]::new(); $stream.CopyTo($output); $stream.Dispose()
    if ($output.Length -eq 0) { throw "Independent zlib oracle produced no scanlines: $($Case.id)" }
    $btype = ($zlib[2] -shr 1) -band 3
    if ($Case.id -notlike 'lowbit-*' -and (($Case.block -eq 'fixed' -and $btype -ne 1) -or ($Case.block -eq 'dynamic' -and $btype -ne 2))) { throw "Unexpected DEFLATE block type: $($Case.id)" }
    if ($Case.colour_type -eq 0 -or $Case.colour_type -eq 2) {
      $sourceChannels = if ($Case.colour_type -eq 0) { 1 } else { 3 }
      $depth = if ($Case.colour_type -eq 0 -and $null -ne $Case.PSObject.Properties['bit_depth']) { [int]$Case.bit_depth } else { 8 }
      if ($Case.colour_type -eq 0 -and $depth -notin @(1,2,4,8)) { throw "Invalid grayscale depth oracle input: $($Case.id)" }
      $stride = if ($Case.colour_type -eq 0) { [int][Math]::Ceiling(([double]$Case.width * $depth) / 8) } else { [int]$Case.width * $sourceChannels }
      $bpp = if ($Case.colour_type -eq 0) { 1 } else { $sourceChannels }
      $scan = $output.ToArray(); $previous = [byte[]]::new($stride); $pixels = [Collections.Generic.List[byte]]::new(); [byte[]]$key = [byte[]]::new(0); if ($null -ne $Case.PSObject.Properties['trns_hex']) { $key = Hex $Case.trns_hex }; $at = 0
      $mask = if ($depth -eq 1) { 1 } elseif ($depth -eq 2) { 3 } elseif ($depth -eq 4) { 15 } else { 255 }
      if ($key.Length -and (($Case.colour_type -eq 0 -and ($key.Length -ne 2 -or $key[0] -ne 0 -or $key[1] -gt $mask)) -or ($Case.colour_type -eq 2 -and ($key.Length -ne 6 -or $key[0] -ne 0 -or $key[2] -ne 0 -or $key[4] -ne 0)))) { throw "Invalid tRNS key oracle input: $($Case.id)" }
      for ($y = 0; $y -lt $Case.height; $y++) {
        $filter = $scan[$at++]; if ($filter -gt 4) { throw "Invalid source filter oracle input: $($Case.id)" }; $current = [byte[]]::new($stride)
        for ($column = 0; $column -lt $stride; $column++) {
          $raw=$scan[$at++]; $left=if($column -ge $bpp){$current[$column-$bpp]}else{0}; $above=if($y){$previous[$column]}else{0}; $ul=if($y -and $column -ge $bpp){$previous[$column-$bpp]}else{0}; $predict=if($filter -eq 0){0}elseif($filter -eq 1){$left}elseif($filter -eq 2){$above}elseif($filter -eq 3){($left+$above) -shr 1}else{$p=$left+$above-$ul;$pa=[Math]::Abs($p-$left);$pb=[Math]::Abs($p-$above);$pc=[Math]::Abs($p-$ul);if($pa -le $pb -and $pa -le $pc){$left}elseif($pb -le $pc){$above}else{$ul}}; $current[$column]=($raw+$predict)%256
        }
        for ($x = 0; $x -lt $Case.width; $x++) {
          if ($Case.colour_type -eq 0) {
            $bit = $x * $depth; $raw = ($current[[int][Math]::Floor($bit / 8)] -shr (8 - $depth - ($bit % 8))) -band $mask; $value = if ($depth -eq 1) { $raw * 255 } elseif ($depth -eq 2) { $raw * 85 } elseif ($depth -eq 4) { $raw * 17 } else { $raw }; $pixels.Add($value); $pixels.Add($value); $pixels.Add($value); if ($key.Length) { $pixels.Add($(if($raw -eq $key[1]){0}else{255})) }
          } else {
            $base = $x * 3; $red=$current[$base]; $green=$current[$base+1]; $blue=$current[$base+2]; $pixels.Add($red); $pixels.Add($green); $pixels.Add($blue); if ($key.Length) { $pixels.Add($(if($red -eq $key[1] -and $green -eq $key[3] -and $blue -eq $key[5]){0}else{255})) }
          }
        }
        $previous=$current
      }
      if ((Moon-Bytes $pixels.ToArray()) -cne (Moon-Bytes (Hex $Case.pixels_hex))) { throw "Source-bpp tRNS oracle mismatch: $($Case.id)" }
    } elseif ($Case.colour_type -eq 3) {
      $palette = Hex $Case.plte_hex
      if ($palette.Length -lt 3 -or $palette.Length -gt 768 -or $palette.Length % 3) { throw "Invalid indexed PLTE oracle input: $($Case.id)" }
      $scan = $output.ToArray(); $stride = [int]$Case.width; $previous = [byte[]]::new($stride); $pixels = [Collections.Generic.List[byte]]::new(); [byte[]]$alpha = [byte[]]::new(0); if ($null -ne $Case.PSObject.Properties['trns_hex']) { $alpha = Hex $Case.trns_hex }; $at = 0
      for ($y = 0; $y -lt $Case.height; $y++) {
        $filter = $scan[$at++]; if ($filter -gt 4) { throw "Invalid indexed filter oracle input: $($Case.id)" }; $current = [byte[]]::new($stride)
        for ($x = 0; $x -lt $stride; $x++) { $raw=$scan[$at++]; $left=if($x){$current[$x-1]}else{0}; $above=if($y){$previous[$x]}else{0}; $ul=if($x -and $y){$previous[$x-1]}else{0}; $predict=if($filter -eq 0){0}elseif($filter -eq 1){$left}elseif($filter -eq 2){$above}elseif($filter -eq 3){($left+$above) -shr 1}else{$p=$left+$above-$ul;$pa=[Math]::Abs($p-$left);$pb=[Math]::Abs($p-$above);$pc=[Math]::Abs($p-$ul);if($pa -le $pb -and $pa -le $pc){$left}elseif($pb -le $pc){$above}else{$ul}}; $current[$x]=($raw+$predict)%256; $base=$current[$x]*3; $pixels.Add($palette[$base]);$pixels.Add($palette[$base+1]);$pixels.Add($palette[$base+2]); if($alpha.Length){$pixels.Add($(if($current[$x] -lt $alpha.Length){$alpha[$current[$x]]}else{255}))} }
        $previous=$current
      }
      if ((Moon-Bytes $pixels.ToArray()) -cne (Moon-Bytes (Hex $Case.pixels_hex))) { throw "Indexed RGB oracle mismatch: $($Case.id)" }
    }
  }
}

$corpus = Get-Content -Raw -LiteralPath $CasesPath | ConvertFrom-Json
$required = @('fixed-rgb-filters-every-idat-byte','fixed-grayscale-filters-every-idat-boundary','lowbit-gray-1-filters','lowbit-gray-2-filters','lowbit-gray-4-filters','lowbit-gray-8-filters','lowbit-trns-gray-1','lowbit-trns-gray-2','lowbit-trns-gray-4','lowbit-trns-gray-high-byte','lowbit-trns-gray-mask','dynamic-rgba-filters-semantic-idat-split','indexed-filters-every-idat-boundary','trns-grayscale-filters','trns-rgb-filters','trns-indexed-filters','indexed-missing-plte','indexed-plte-length-0','indexed-plte-length-1','indexed-plte-length-2','indexed-plte-length-4','indexed-plte-length-5','indexed-plte-length-769','indexed-plte-duplicate','indexed-plte-after-idat','indexed-plte-crc','indexed-palette-index','trns-duplicate','trns-after-idat','trns-before-plte','trns-crc','trns-gray-length','trns-gray-sample','trns-rgb-length','trns-rgb-sample','trns-indexed-length','trns-type6','hostile-zlib-header','hostile-truncated-deflate','hostile-adler','hostile-filter','hostile-dynamic-incomplete-tree','hostile-fixed-distance-before-history','hostile-filtered-output-expansion')
if ($corpus.schema_version -ne '2.1.0' -or (Compare-Object $required @($corpus.cases.id))) { throw 'PNG decode corpus is stale or incomplete.' }
$records = [Collections.Generic.List[object]]::new()
foreach ($case in $corpus.cases) {
  $zlib = Hex $case.zlib_hex
  if ($case.PSObject.Properties['exhaustive_idat_splits'] -and $case.exhaustive_idat_splits) {
    if ($zlib.Length -lt 2) { throw "Exhaustive IDAT vector is too short: $($case.id)" }
    for ($offset = 1; $offset -lt $zlib.Length; $offset++) {
      $records.Add([pscustomobject]@{ case = $case; id = "$($case.id)-split-$offset"; splits = [int[]]@($offset, ($zlib.Length - $offset)) })
    }
  } else {
    $records.Add([pscustomobject]@{ case = $case; id = [string]$case.id; splits = [int[]]$case.idat_splits })
  }
}
$rows = [Collections.Generic.List[string]]::new()
$rows.Add('// Generated by scripts/fixtures/Generate-PngDecodeVectors.ps1. Do not edit.')
$rows.Add('')
$rows.Add('///|')
$rows.Add('priv struct PngDecodeVector { id : String; bytes : Bytes; width : UInt64; height : UInt64; channels : UInt64; pixels : Bytes; outcome : String; max_output : UInt64; context : String }')
$rows.Add('')
$rows.Add('///|')
$rows.Add('fn _generated_png_decode_cases() -> Array[PngDecodeVector] {')
$rows.Add('  [')
foreach ($record in $records) {
  $case = $record.case
  Assert-Oracle $case
  $png = New-Png $case $record.splits; $pixels = if ($case.outcome -eq 'accepted') { Moon-Bytes (Hex $case.pixels_hex) } else { '' }; $channels = if ($case.colour_type -eq 6 -or $null -ne $case.PSObject.Properties['trns_hex']) { 4 } else { 3 }; $context = if ($null -eq $case.PSObject.Properties['context']) { '' } else { [string]$case.context }; $maxOutput = if ($null -eq $case.PSObject.Properties['max_output']) { 1024 } else { [uint64]$case.max_output }
  $rows.Add(('    PngDecodeVector::{{ id: "{0}", bytes: b"{1}", width: {2}UL, height: {3}UL, channels: {4}UL, pixels: b"{5}", outcome: "{6}", max_output: {7}UL, context: "{8}" }},' -f $record.id,(Moon-Bytes $png),$case.width,$case.height,$channels,$pixels,$case.outcome,$maxOutput,$context))
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
