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
      $depth = if ($null -ne $Case.PSObject.Properties['bit_depth']) { [int]$Case.bit_depth } else { 8 }
      if ($Case.colour_type -eq 0 -and $depth -notin @(1,2,4,8,16)) { throw "Invalid grayscale depth oracle input: $($Case.id)" }
      if ($Case.colour_type -eq 2 -and $depth -notin @(8,16)) { throw "Invalid truecolour depth oracle input: $($Case.id)" }
      $sampleBytes = if ($depth -eq 16) { 2 } else { 1 }
      $stride = if ($Case.colour_type -eq 0 -and $depth -lt 8) { [int][Math]::Ceiling(([double]$Case.width * $depth) / 8) } else { [int]$Case.width * $sourceChannels * $sampleBytes }
      $bpp = if ($depth -eq 16) { $sourceChannels * 2 } elseif ($Case.colour_type -eq 0) { 1 } else { $sourceChannels }
      $scan = $output.ToArray(); $previous = [byte[]]::new($stride); $pixels = [Collections.Generic.List[byte]]::new(); [byte[]]$key = [byte[]]::new(0); if ($null -ne $Case.PSObject.Properties['trns_hex']) { $key = Hex $Case.trns_hex }; $at = 0
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
    } elseif ($Case.colour_type -eq 4) {
      $scan = $output.ToArray(); $stride = [int]$Case.width * 2; $previous = [byte[]]::new($stride); $pixels = [Collections.Generic.List[byte]]::new(); $at = 0
      for ($y = 0; $y -lt $Case.height; $y++) {
        $filter = $scan[$at++]; if ($filter -gt 4) { throw "Invalid grayscale-alpha filter oracle input: $($Case.id)" }; $current = [byte[]]::new($stride)
        for ($column = 0; $column -lt $stride; $column++) { $raw=$scan[$at++]; $left=if($column -ge 2){$current[$column-2]}else{0}; $above=if($y){$previous[$column]}else{0}; $ul=if($y -and $column -ge 2){$previous[$column-2]}else{0}; $predict=if($filter -eq 0){0}elseif($filter -eq 1){$left}elseif($filter -eq 2){$above}elseif($filter -eq 3){($left+$above) -shr 1}else{$p=$left+$above-$ul;$pa=[Math]::Abs($p-$left);$pb=[Math]::Abs($p-$above);$pc=[Math]::Abs($p-$ul);if($pa -le $pb -and $pa -le $pc){$left}elseif($pb -le $pc){$above}else{$ul}}; $current[$column]=($raw+$predict)%256 }
        for ($x = 0; $x -lt $Case.width; $x++) { $gray=$current[$x*2]; $pixels.Add($gray);$pixels.Add($gray);$pixels.Add($gray);$pixels.Add($current[$x*2+1]) }
        $previous=$current
      }
      if ((Moon-Bytes $pixels.ToArray()) -cne (Moon-Bytes (Hex $Case.pixels_hex))) { throw "Grayscale-alpha RGBA oracle mismatch: $($Case.id)" }
    } elseif ($Case.colour_type -eq 3) {
      $palette = Hex $Case.plte_hex
      if ($palette.Length -lt 3 -or $palette.Length -gt 768 -or $palette.Length % 3) { throw "Invalid indexed PLTE oracle input: $($Case.id)" }
      $depth = if ($null -ne $Case.PSObject.Properties['bit_depth']) { [int]$Case.bit_depth } else { 8 }
      if ($depth -notin @(1,2,4,8)) { throw "Invalid indexed depth oracle input: $($Case.id)" }
      $entries = [int]($palette.Length / 3); if ($entries -gt (1 -shl $depth)) { throw "Indexed PLTE exceeds active depth: $($Case.id)" }
      $scan = $output.ToArray(); $stride = [int][Math]::Ceiling(([double]$Case.width * $depth) / 8); $previous = [byte[]]::new($stride); $pixels = [Collections.Generic.List[byte]]::new(); [byte[]]$alpha = [byte[]]::new(0); if ($null -ne $Case.PSObject.Properties['trns_hex']) { $alpha = Hex $Case.trns_hex }; if ($alpha.Length -gt $entries) { throw "Indexed tRNS exceeds PLTE: $($Case.id)" }; $at = 0; $mask = (1 -shl $depth) - 1
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
if ($corpus.schema_version -ne '2.4.0' -or (Compare-Object $required @($corpus.cases.id))) { throw 'PNG decode corpus is stale or incomplete.' }
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
$rows.Add('priv struct PngDecodeVector { id : String; bytes : Bytes; width : UInt64; height : UInt64; channels : UInt64; pixels : Bytes; outcome : String; max_output : UInt64; max_work : UInt64; category : String; code : String; context : String; comparison_group : String; baseline : Bool }')
$rows.Add('')
$rows.Add('///|')
$rows.Add('fn _generated_png_decode_cases() -> Array[PngDecodeVector] {')
$rows.Add('  [')
foreach ($record in $records) {
  $case = $record.case
  Assert-Oracle $case
  $png = New-Png $case $record.splits; $pixels = if ($case.outcome -eq 'accepted') { Moon-Bytes (Hex $case.pixels_hex) } else { '' }; $channels = if ($case.colour_type -eq 4 -or $case.colour_type -eq 6 -or $null -ne $case.PSObject.Properties['trns_hex']) { 4 } else { 3 }; $context = if ($null -eq $case.PSObject.Properties['context']) { '' } else { [string]$case.context }; $maxOutput = if ($null -eq $case.PSObject.Properties['max_output']) { 1024 } else { [uint64]$case.max_output }; $maxWork = if ($null -eq $case.PSObject.Properties['max_work']) { 4096 } else { [uint64]$case.max_work }; $category = if ($null -eq $case.PSObject.Properties['category']) { if ($case.outcome -eq 'limit') { 'resource' } else { 'data' } } else { [string]$case.category }; $code = if ($null -eq $case.PSObject.Properties['code']) { if ($case.outcome -eq 'limit') { 'budget-exceeded' } else { 'invalid-encoding' } } else { [string]$case.code }; $baseline = if ($record.baseline) { 'true' } else { 'false' }
  $rows.Add(('    PngDecodeVector::{{ id: "{0}", bytes: b"{1}", width: {2}UL, height: {3}UL, channels: {4}UL, pixels: b"{5}", outcome: "{6}", max_output: {7}UL, max_work: {8}UL, category: "{9}", code: "{10}", context: "{11}", comparison_group: "{12}", baseline: {13} }},' -f $record.id,(Moon-Bytes $png),$case.width,$case.height,$channels,$pixels,$case.outcome,$maxOutput,$maxWork,$category,$code,$context,$record.group,$baseline))
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
