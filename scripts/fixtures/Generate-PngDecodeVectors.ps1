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
  $parts.Add((Chunk 'IHDR' (Join-Bytes @((U32 $Case.width),(U32 $Case.height),[byte[]](8,$Case.colour_type,0,0,0)))))
  $hasPlte = $null -ne $Case.PSObject.Properties['plte_length'] -or $null -ne $Case.PSObject.Properties['plte_hex']
  [byte[]]$plte = @()
  if ($null -ne $Case.PSObject.Properties['plte_length']) { $plte = [byte[]]::new([int]$Case.plte_length) }
  elseif ($null -ne $Case.PSObject.Properties['plte_hex']) { $plte = Hex $Case.plte_hex }
  $variant = if ($Case.PSObject.Properties['variant']) { [string]$Case.variant } else { 'normal' }
  if ($hasPlte -and $variant -ne 'missing-plte') {
    $chunk = Chunk 'PLTE' $plte
    if ($variant -eq 'plte-crc') { $chunk = [byte[]]$chunk.Clone(); $chunk[$chunk.Length - 1] = $chunk[$chunk.Length - 1] -bxor 1 }
    $parts.Add($chunk)
    if ($variant -eq 'plte-duplicate') { $parts.Add((Chunk 'PLTE' $plte)) }
  }
  if ($variant -eq 'trns') { $parts.Add((Chunk 'tRNS' ([byte[]]@(0)))) }
  $offset = 0
  foreach ($split in $Splits) { $count = [int]$split; if ($count -le 0 -or $offset + $count -gt $zlib.Length) { throw "Invalid IDAT split: $($Case.id)" }; $parts.Add((Chunk 'IDAT' $zlib[$offset..($offset+$count-1)])); $offset += $count }
  if ($offset -ne $zlib.Length) { throw "IDAT splits do not cover zlib payload: $($Case.id)" }
  if ($hasPlte -and $variant -eq 'plte-after-idat') { $parts.Add((Chunk 'PLTE' $plte)) }
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
    if (($Case.block -eq 'fixed' -and $btype -ne 1) -or ($Case.block -eq 'dynamic' -and $btype -ne 2)) { throw "Unexpected DEFLATE block type: $($Case.id)" }
    if ($Case.colour_type -eq 3) {
      $palette = Hex $Case.plte_hex
      if ($palette.Length -lt 3 -or $palette.Length -gt 768 -or $palette.Length % 3) { throw "Invalid indexed PLTE oracle input: $($Case.id)" }
      $scan = $output.ToArray(); $stride = [int]$Case.width; $previous = [byte[]]::new($stride); $pixels = [Collections.Generic.List[byte]]::new(); $at = 0
      for ($y = 0; $y -lt $Case.height; $y++) {
        $filter = $scan[$at++]; if ($filter -gt 4) { throw "Invalid indexed filter oracle input: $($Case.id)" }; $current = [byte[]]::new($stride)
        for ($x = 0; $x -lt $stride; $x++) { $raw=$scan[$at++]; $left=if($x){$current[$x-1]}else{0}; $above=if($y){$previous[$x]}else{0}; $ul=if($x -and $y){$previous[$x-1]}else{0}; $predict=if($filter -eq 0){0}elseif($filter -eq 1){$left}elseif($filter -eq 2){$above}elseif($filter -eq 3){($left+$above) -shr 1}else{$p=$left+$above-$ul;$pa=[Math]::Abs($p-$left);$pb=[Math]::Abs($p-$above);$pc=[Math]::Abs($p-$ul);if($pa -le $pb -and $pa -le $pc){$left}elseif($pb -le $pc){$above}else{$ul}}; $current[$x]=($raw+$predict)%256; $base=$current[$x]*3; $pixels.Add($palette[$base]);$pixels.Add($palette[$base+1]);$pixels.Add($palette[$base+2]) }
        $previous=$current
      }
      if ((Moon-Bytes $pixels.ToArray()) -cne (Moon-Bytes (Hex $Case.pixels_hex))) { throw "Indexed RGB oracle mismatch: $($Case.id)" }
    }
  }
}

$corpus = Get-Content -Raw -LiteralPath $CasesPath | ConvertFrom-Json
$required = @('fixed-rgb-filters-every-idat-byte','fixed-grayscale-filters-every-idat-boundary','dynamic-rgba-filters-semantic-idat-split','indexed-filters-every-idat-boundary','indexed-missing-plte','indexed-plte-length-0','indexed-plte-length-1','indexed-plte-length-2','indexed-plte-length-4','indexed-plte-length-5','indexed-plte-length-769','indexed-plte-duplicate','indexed-plte-after-idat','indexed-plte-crc','indexed-palette-index','indexed-trns','hostile-zlib-header','hostile-truncated-deflate','hostile-adler','hostile-filter','hostile-dynamic-incomplete-tree','hostile-fixed-distance-before-history','hostile-filtered-output-expansion')
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
  $png = New-Png $case $record.splits; $pixels = if ($case.outcome -eq 'accepted') { Moon-Bytes (Hex $case.pixels_hex) } else { '' }; $channels = if ($case.colour_type -eq 6) { 4 } else { 3 }; $context = if ($null -eq $case.PSObject.Properties['context']) { '' } else { [string]$case.context }; $maxOutput = if ($null -eq $case.PSObject.Properties['max_output']) { 1024 } else { [uint64]$case.max_output }
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
