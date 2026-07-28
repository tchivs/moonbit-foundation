[CmdletBinding()]
param(
  [switch]$Intake,
  [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$FixtureDirectory = Join-Path $RepositoryRoot 'fixtures/font/dejavu-sans-2.37'
$FontPath = Join-Path $FixtureDirectory 'DejaVuSans.ttf'
$LicensePath = Join-Path $FixtureDirectory 'LICENSE'
$OraclePath = Join-Path $FixtureDirectory 'oracle.json'
$CasesPath = Join-Path $RepositoryRoot 'fixtures/font/qualification-cases.json'
$CollectionCasesPath = Join-Path $RepositoryRoot 'fixtures/font/collection-qualification-cases.json'
$CollectionFontPath = Join-Path $FixtureDirectory 'DejaVuSans-two-face-v1.ttc'
$CollectionOraclePath = Join-Path $FixtureDirectory 'collection-oracle.json'
$ManifestPath = Join-Path $RepositoryRoot 'fixtures/manifest.json'
$GeneratedSourcePath = Join-Path $RepositoryRoot 'modules/mb-font/font/generated_font_qualification_test.mbt'

$ArchiveUrl = 'https://github.com/dejavu-fonts/dejavu-fonts/releases/download/version_2_37/dejavu-sans-ttf-2.37.zip'
$ArchiveLength = 417746L
$ArchiveSha256 = '5c6e497a2f36552cb5ffb112c413a6af39c0f3c47653662b90b4fa6499822fd7'
$ArchiveFontMember = 'dejavu-sans-ttf-2.37/ttf/DejaVuSans.ttf'
$ArchiveLicenseMember = 'dejavu-sans-ttf-2.37/LICENSE'
$FontLength = 757076L
$FontSha256 = '7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954'
$LicenseLength = 8816L
$LicenseSha256 = '7a083b136e64d064794c3419751e5c7dd10d2f64c108fe5ba161eae5e5958a93'
$UpstreamLicense = 'Bitstream-Vera AND LicenseRef-DejaVu-Arev'
$RetrievalDate = '2026-07-27'
$CollectionGenerationDate = '2026-07-28'
$CollectionFontLength = 757428L
$CollectionFontSha256 = '833d406d389d4ef3b0a38f168af7d51ca16c88605e1727f6d631871a4e05f80b'
$StandaloneOracleSha256 = '4247394c3795a56aaf28c1885403201cfc277b06125f5887e14a40f3b4c6229a'
$StandaloneCasesSha256 = 'a9a86ed5c080571fffe3317eead29865c5fdad222475251423621fddb09c1d18'
$PreCollectionManifestRecordsSha256 = 'ee6446eea92e311e5722183531ca86d1225a028df56aad7891af7da8ba30d856'
$GeneratedChunkSize = 4096

function Get-FontQualificationSha256 {
  [CmdletBinding()]
  param([Parameter(Mandatory)][byte[]]$Bytes)

  return [Convert]::ToHexString(
    [System.Security.Cryptography.SHA256]::HashData($Bytes)
  ).ToLowerInvariant()
}

function Format-FontQualificationCoordinate {
  param([Parameter(Mandatory)][double]$Value)

  return $Value.ToString(
    '0.################',
    [Globalization.CultureInfo]::InvariantCulture
  )
}

function Assert-ExactBytesIdentity {
  param(
    [Parameter(Mandatory)][string]$Label,
    [Parameter(Mandatory)][byte[]]$Bytes,
    [Parameter(Mandatory)][long]$ExpectedLength,
    [Parameter(Mandatory)][string]$ExpectedSha256
  )

  if ($Bytes.LongLength -ne $ExpectedLength) {
    throw "$Label length drift: expected $ExpectedLength, got $($Bytes.LongLength)."
  }
  $actualSha256 = Get-FontQualificationSha256 -Bytes $Bytes
  if ($actualSha256 -cne $ExpectedSha256) {
    throw "$Label SHA-256 drift: expected $ExpectedSha256, got $actualSha256."
  }
}

function Read-U16BE {
  param([byte[]]$Bytes, [int]$Offset)
  if ($Offset -lt 0 -or $Offset + 2 -gt $Bytes.Length) {
    throw "Oracle u16 range exceeds source at $Offset."
  }
  return ([uint64]$Bytes[$Offset] -shl 8) -bor [uint64]$Bytes[$Offset + 1]
}

function Read-I16BE {
  param([byte[]]$Bytes, [int]$Offset)
  $value = [int](Read-U16BE $Bytes $Offset)
  if ($value -ge 0x8000) { return $value - 0x10000 }
  return $value
}

function Read-U32BE {
  param([byte[]]$Bytes, [int]$Offset)
  if ($Offset -lt 0 -or $Offset + 4 -gt $Bytes.Length) {
    throw "Oracle u32 range exceeds source at $Offset."
  }
  return (
    ([uint64]$Bytes[$Offset] -shl 24) -bor
    ([uint64]$Bytes[$Offset + 1] -shl 16) -bor
    ([uint64]$Bytes[$Offset + 2] -shl 8) -bor
    [uint64]$Bytes[$Offset + 3]
  )
}

function Get-TableBytes {
  param(
    [byte[]]$Bytes,
    [Parameter(Mandatory)]$Record
  )
  $offset = [int]$Record.offset
  $length = [int]$Record.length
  if ($offset -lt 0 -or $length -lt 0 -or $offset + $length -gt $Bytes.Length) {
    throw "Oracle table '$($Record.tag)' exceeds source."
  }
  $result = [byte[]]::new($length)
  [Array]::Copy($Bytes, $offset, $result, 0, $length)
  return $result
}

function Get-CmapGlyph {
  param(
    [byte[]]$Cmap,
    [int]$SubtableOffset,
    [uint64]$Scalar
  )

  $format = Read-U16BE $Cmap $SubtableOffset
  if ($format -eq 12) {
    $length = [int](Read-U32BE $Cmap ($SubtableOffset + 4))
    if ($SubtableOffset + $length -gt $Cmap.Length) {
      throw 'Oracle cmap format-12 envelope exceeds table.'
    }
    $groupCount = [int](Read-U32BE $Cmap ($SubtableOffset + 12))
    for ($index = 0; $index -lt $groupCount; $index++) {
      $group = $SubtableOffset + 16 + $index * 12
      $start = Read-U32BE $Cmap $group
      $end = Read-U32BE $Cmap ($group + 4)
      if ($Scalar -ge $start -and $Scalar -le $end) {
        return (Read-U32BE $Cmap ($group + 8)) + ($Scalar - $start)
      }
    }
    return 0UL
  }

  if ($format -eq 4) {
    if ($Scalar -gt 0xFFFFUL) { return 0UL }
    $length = [int](Read-U16BE $Cmap ($SubtableOffset + 2))
    if ($SubtableOffset + $length -gt $Cmap.Length) {
      throw 'Oracle cmap format-4 envelope exceeds table.'
    }
    $segmentCount = [int](Read-U16BE $Cmap ($SubtableOffset + 6)) / 2
    $endCodes = $SubtableOffset + 14
    $startCodes = $endCodes + $segmentCount * 2 + 2
    $idDeltas = $startCodes + $segmentCount * 2
    $idRangeOffsets = $idDeltas + $segmentCount * 2
    for ($index = 0; $index -lt $segmentCount; $index++) {
      $end = Read-U16BE $Cmap ($endCodes + $index * 2)
      $start = Read-U16BE $Cmap ($startCodes + $index * 2)
      if ($Scalar -lt $start -or $Scalar -gt $end) { continue }
      $delta = Read-I16BE $Cmap ($idDeltas + $index * 2)
      $rangeOffset = [int](Read-U16BE $Cmap ($idRangeOffsets + $index * 2))
      if ($rangeOffset -eq 0) {
        return [uint64](([int64]$Scalar + $delta) -band 0xFFFF)
      }
      $glyphOffset = $idRangeOffsets + $index * 2 + $rangeOffset +
        ([int]$Scalar - [int]$start) * 2
      if ($glyphOffset + 2 -gt $SubtableOffset + $length) {
        throw 'Oracle cmap format-4 glyph range exceeds subtable.'
      }
      $glyph = [int](Read-U16BE $Cmap $glyphOffset)
      if ($glyph -eq 0) { return 0UL }
      return [uint64](($glyph + $delta) -band 0xFFFF)
    }
    return 0UL
  }

  throw "Oracle does not map cmap format $format."
}

function Get-GlyphRange {
  param(
    [byte[]]$Loca,
    [int]$GlyphId,
    [int]$LocaFormat
  )
  if ($LocaFormat -eq 1) {
    return @(
      [int](Read-U32BE $Loca ($GlyphId * 4)),
      [int](Read-U32BE $Loca (($GlyphId + 1) * 4))
    )
  }
  return @(
    [int](Read-U16BE $Loca ($GlyphId * 2)) * 2,
    [int](Read-U16BE $Loca (($GlyphId + 1) * 2)) * 2
  )
}

function Read-SimpleGlyphGeometry {
  param(
    [byte[]]$Glyf,
    [int]$Start,
    [int]$End
  )

  $contourCount = Read-I16BE $Glyf $Start
  if ($contourCount -lt 0) { throw 'Oracle simple geometry received a composite glyph.' }
  $offset = $Start + 10
  $endpoints = [Collections.Generic.List[int]]::new()
  for ($index = 0; $index -lt $contourCount; $index++) {
    $endpoints.Add([int](Read-U16BE $Glyf $offset))
    $offset += 2
  }
  $instructionLength = [int](Read-U16BE $Glyf $offset)
  $offset += 2 + $instructionLength
  if ($offset -gt $End) { throw 'Oracle simple instructions exceed glyph.' }
  $pointCount = if ($contourCount -eq 0) { 0 } else { $endpoints[$endpoints.Count - 1] + 1 }
  $flags = [Collections.Generic.List[int]]::new()
  while ($flags.Count -lt $pointCount) {
    if ($offset -ge $End) { throw 'Oracle simple flags exceed glyph.' }
    $flag = [int]$Glyf[$offset]
    $offset++
    $flags.Add($flag)
    if (($flag -band 0x08) -ne 0) {
      if ($offset -ge $End) { throw 'Oracle simple repeat exceeds glyph.' }
      $repeat = [int]$Glyf[$offset]
      $offset++
      for ($count = 0; $count -lt $repeat; $count++) { $flags.Add($flag) }
    }
  }
  if ($flags.Count -ne $pointCount) { throw 'Oracle simple flag count drift.' }

  $xs = [Collections.Generic.List[int]]::new()
  $x = 0
  foreach ($flag in $flags) {
    if (($flag -band 0x02) -ne 0) {
      if ($offset -ge $End) { throw 'Oracle simple x byte exceeds glyph.' }
      $delta = [int]$Glyf[$offset]
      $offset++
      if (($flag -band 0x10) -eq 0) { $delta = -$delta }
    } elseif (($flag -band 0x10) -ne 0) {
      $delta = 0
    } else {
      $delta = Read-I16BE $Glyf $offset
      $offset += 2
    }
    $x += $delta
    $xs.Add($x)
  }

  $ys = [Collections.Generic.List[int]]::new()
  $y = 0
  foreach ($flag in $flags) {
    if (($flag -band 0x04) -ne 0) {
      if ($offset -ge $End) { throw 'Oracle simple y byte exceeds glyph.' }
      $delta = [int]$Glyf[$offset]
      $offset++
      if (($flag -band 0x20) -eq 0) { $delta = -$delta }
    } elseif (($flag -band 0x20) -ne 0) {
      $delta = 0
    } else {
      $delta = Read-I16BE $Glyf $offset
      $offset += 2
    }
    $y += $delta
    $ys.Add($y)
  }

  $points = [Collections.Generic.List[object]]::new()
  for ($index = 0; $index -lt $pointCount; $index++) {
    $points.Add([ordered]@{
      x = $xs[$index]
      y = $ys[$index]
      on_curve = (($flags[$index] -band 0x01) -ne 0)
    })
  }
  return [ordered]@{
    contour_count = $contourCount
    endpoints = @($endpoints)
    instruction_bytes = $instructionLength
    points = @($points)
  }
}

function Read-CompositeGlyphFacts {
  param(
    [byte[]]$Glyf,
    [int]$Start,
    [int]$End
  )

  $offset = $Start + 10
  $components = [Collections.Generic.List[object]]::new()
  do {
    if ($offset + 4 -gt $End) { throw 'Oracle composite record exceeds glyph.' }
    $flags = [int](Read-U16BE $Glyf $offset)
    $glyphId = [int](Read-U16BE $Glyf ($offset + 2))
    $offset += 4
    $words = (($flags -band 0x0001) -ne 0)
    $xyValues = (($flags -band 0x0002) -ne 0)
    if ($words) {
      $arg1 = Read-I16BE $Glyf $offset
      $arg2 = Read-I16BE $Glyf ($offset + 2)
      $offset += 4
    } else {
      $arg1Byte = [int]$Glyf[$offset]
      $arg2Byte = [int]$Glyf[$offset + 1]
      $arg1 = if ($arg1Byte -ge 128) { $arg1Byte - 256 } else { $arg1Byte }
      $arg2 = if ($arg2Byte -ge 128) { $arg2Byte - 256 } else { $arg2Byte }
      $offset += 2
    }
    $a = 16384; $b = 0; $c = 0; $d = 16384
    if (($flags -band 0x0008) -ne 0) {
      $a = Read-I16BE $Glyf $offset; $d = $a; $offset += 2
    } elseif (($flags -band 0x0040) -ne 0) {
      $a = Read-I16BE $Glyf $offset
      $d = Read-I16BE $Glyf ($offset + 2)
      $offset += 4
    } elseif (($flags -band 0x0080) -ne 0) {
      $a = Read-I16BE $Glyf $offset
      $b = Read-I16BE $Glyf ($offset + 2)
      $c = Read-I16BE $Glyf ($offset + 4)
      $d = Read-I16BE $Glyf ($offset + 6)
      $offset += 8
    }
    $components.Add([ordered]@{
      glyph_id = $glyphId
      arguments_are_xy = $xyValues
      arg1 = $arg1
      arg2 = $arg2
      transform_q14 = @($a, $b, $c, $d)
    })
    $more = (($flags -band 0x0020) -ne 0)
  } while ($more)

  return [ordered]@{
    components = @($components)
    instruction_bytes = 0
  }
}

function Convert-GeometryToCommands {
  param([Parameter(Mandatory)]$Geometry)

  $commands = [Collections.Generic.List[string]]::new()
  $contourStart = 0
  foreach ($endpointValue in $Geometry.endpoints) {
    $endpoint = [int]$endpointValue
    $first = $Geometry.points[$contourStart]
    $last = $Geometry.points[$endpoint]
    if ($first.on_curve) {
      $startX = [int]$first.x; $startY = [int]$first.y
      $index = $contourStart + 1
    } elseif ($last.on_curve) {
      $startX = [int]$last.x; $startY = [int]$last.y
      $index = $contourStart
    } else {
      $startX = ($first.x + $last.x) / 2.0
      $startY = ($first.y + $last.y) / 2.0
      $index = $contourStart
    }
    $commands.Add(
      "M:$(Format-FontQualificationCoordinate $startX),$(Format-FontQualificationCoordinate $startY)"
    )
    $traversalEnd = if (-not $first.on_curve -and $last.on_curve) {
      $endpoint - 1
    } else {
      $endpoint
    }
    $control = $null
    while ($index -le $traversalEnd) {
      $point = $Geometry.points[$index]
      if ($point.on_curve) {
        if ($null -eq $control) {
          $commands.Add("L:$($point.x),$($point.y)")
        } else {
          $commands.Add("Q:$($control.x),$($control.y):$($point.x),$($point.y)")
          $control = $null
        }
      } else {
        if ($null -eq $control) {
          $control = $point
        } else {
          $midX = ($control.x + $point.x) / 2.0
          $midY = ($control.y + $point.y) / 2.0
          $commands.Add(
            "Q:$($control.x),$($control.y):$(Format-FontQualificationCoordinate $midX),$(Format-FontQualificationCoordinate $midY)"
          )
          $control = $point
        }
      }
      $index++
    }
    if ($null -ne $control) {
      $commands.Add("Q:$($control.x),$($control.y):$startX,$startY")
    }
    $commands.Add('Z')
    $contourStart = $endpoint + 1
  }
  return @($commands)
}

function Get-GlyphGeometry {
  param(
    [byte[]]$Glyf,
    [byte[]]$Loca,
    [int]$LocaFormat,
    [int]$GlyphId,
    [int]$Depth = 0
  )

  if ($Depth -gt 8) { throw 'Oracle composite depth exceeded closed parser limit.' }
  $range = Get-GlyphRange $Loca $GlyphId $LocaFormat
  $start = [int]$range[0]
  $end = [int]$range[1]
  if ($start -lt 0 -or $end -lt $start -or $end -gt $Glyf.Length) {
    throw "Oracle glyph $GlyphId range exceeds glyf."
  }
  if ($start -eq $end) {
    return [ordered]@{
      contour_count = 0
      endpoints = @()
      instruction_bytes = 0
      points = @()
      components = @()
      classification = 'empty'
    }
  }
  $contourCount = Read-I16BE $Glyf $start
  if ($contourCount -ge 0) {
    $simple = Read-SimpleGlyphGeometry $Glyf $start $end
    $simple.components = @()
    $simple.classification = 'simple'
    return $simple
  }

  $composite = Read-CompositeGlyphFacts $Glyf $start $end
  $allPoints = [Collections.Generic.List[object]]::new()
  $allEndpoints = [Collections.Generic.List[int]]::new()
  foreach ($component in $composite.components) {
    if (-not $component.arguments_are_xy) {
      throw "Oracle selected composite glyph $GlyphId uses point attachment."
    }
    $child = Get-GlyphGeometry $Glyf $Loca $LocaFormat $component.glyph_id ($Depth + 1)
    $base = $allPoints.Count
    foreach ($point in $child.points) {
      $x = [int][Math]::Round(
        ($component.transform_q14[0] * $point.x +
          $component.transform_q14[2] * $point.y) / 16384.0
      ) + [int]$component.arg1
      $y = [int][Math]::Round(
        ($component.transform_q14[1] * $point.x +
          $component.transform_q14[3] * $point.y) / 16384.0
      ) + [int]$component.arg2
      $allPoints.Add([ordered]@{
        x = $x
        y = $y
        on_curve = [bool]$point.on_curve
      })
    }
    foreach ($endpoint in $child.endpoints) {
      $allEndpoints.Add($base + [int]$endpoint)
    }
  }
  return [ordered]@{
    contour_count = $allEndpoints.Count
    endpoints = @($allEndpoints)
    instruction_bytes = $composite.instruction_bytes
    points = @($allPoints)
    components = $composite.components
    classification = 'composite'
  }
}

function Get-HorizontalMetric {
  param(
    [byte[]]$Hmtx,
    [int]$GlyphId,
    [int]$LongMetricCount
  )
  if ($GlyphId -lt $LongMetricCount) {
    return [ordered]@{
      advance = [int](Read-U16BE $Hmtx ($GlyphId * 4))
      lsb = Read-I16BE $Hmtx ($GlyphId * 4 + 2)
    }
  }
  return [ordered]@{
    advance = [int](Read-U16BE $Hmtx (($LongMetricCount - 1) * 4))
    lsb = Read-I16BE $Hmtx ($LongMetricCount * 4 + ($GlyphId - $LongMetricCount) * 2)
  }
}

function Read-FontQualificationSfntOracle {
  [CmdletBinding()]
  param([Parameter(Mandatory)][byte[]]$Bytes)

  Assert-ExactBytesIdentity 'DejaVuSans.ttf' $Bytes $FontLength $FontSha256
  $signature = Read-U32BE $Bytes 0
  $tableCount = [int](Read-U16BE $Bytes 4)
  if ($signature -ne 0x00010000UL -or $tableCount -ne 20) {
    throw 'Oracle SFNT profile or table count drift.'
  }

  $tables = [Collections.Generic.List[object]]::new()
  $tableByTag = @{}
  for ($index = 0; $index -lt $tableCount; $index++) {
    $recordOffset = 12 + $index * 16
    $tag = [Text.Encoding]::ASCII.GetString($Bytes, $recordOffset, 4)
    $record = [ordered]@{
      tag = $tag
      checksum = ('{0:x8}' -f (Read-U32BE $Bytes ($recordOffset + 4)))
      offset = [int](Read-U32BE $Bytes ($recordOffset + 8))
      length = [int](Read-U32BE $Bytes ($recordOffset + 12))
    }
    if ($tableByTag.ContainsKey($tag)) { throw "Oracle duplicate table '$tag'." }
    $tables.Add($record)
    $tableByTag[$tag] = $record
  }
  $expectedTags = @(
    'FFTM','GDEF','GPOS','GSUB','MATH','OS/2','cmap','cvt ','fpgm','gasp',
    'glyf','head','hhea','hmtx','kern','loca','maxp','name','post','prep'
  )
  if ((Compare-Object -CaseSensitive $expectedTags @($tables.tag))) {
    throw 'Oracle table inventory drift.'
  }

  $head = Get-TableBytes $Bytes $tableByTag['head']
  $hhea = Get-TableBytes $Bytes $tableByTag['hhea']
  $os2 = Get-TableBytes $Bytes $tableByTag['OS/2']
  $maxp = Get-TableBytes $Bytes $tableByTag['maxp']
  $hmtx = Get-TableBytes $Bytes $tableByTag['hmtx']
  $cmap = Get-TableBytes $Bytes $tableByTag['cmap']
  $loca = Get-TableBytes $Bytes $tableByTag['loca']
  $glyf = Get-TableBytes $Bytes $tableByTag['glyf']
  $kern = Get-TableBytes $Bytes $tableByTag['kern']
  $locaFormat = Read-I16BE $head 50
  $glyphCount = [int](Read-U16BE $maxp 4)
  $longMetricCount = [int](Read-U16BE $hhea 34)

  $cmapCount = [int](Read-U16BE $cmap 2)
  $cmapRecords = [Collections.Generic.List[object]]::new()
  for ($index = 0; $index -lt $cmapCount; $index++) {
    $recordOffset = 4 + $index * 8
    $subtableOffset = [int](Read-U32BE $cmap ($recordOffset + 4))
    if ($subtableOffset + 2 -gt $cmap.Length) { throw 'Oracle cmap record exceeds table.' }
    $cmapRecords.Add([ordered]@{
      platform_id = [int](Read-U16BE $cmap $recordOffset)
      encoding_id = [int](Read-U16BE $cmap ($recordOffset + 2))
      format = [int](Read-U16BE $cmap $subtableOffset)
      offset = $subtableOffset
    })
  }
  $selectedCmap = @($cmapRecords | Where-Object {
    $_.platform_id -eq 0 -and $_.encoding_id -eq 4 -and $_.format -eq 12
  })
  if ($selectedCmap.Count -ne 1) {
    $selectedCmap = @($cmapRecords | Where-Object {
      $_.platform_id -eq 3 -and $_.encoding_id -eq 10 -and $_.format -eq 12
    })
  }
  if ($selectedCmap.Count -ne 1) { throw 'Oracle canonical cmap selection drift.' }

  $glyphSpecs = @(
    [ordered]@{ scalar='U+0041'; value=0x41UL; expected=36 },
    [ordered]@{ scalar='U+00E9'; value=0xE9UL; expected=171 },
    [ordered]@{ scalar='U+034C'; value=0x34CUL; expected=765 },
    [ordered]@{ scalar='U+10300'; value=0x10300UL; expected=5373 }
  )
  $glyphFacts = [Collections.Generic.List[object]]::new()
  foreach ($spec in $glyphSpecs) {
    $glyphId = [int](Get-CmapGlyph $cmap $selectedCmap[0].offset $spec.value)
    if ($glyphId -ne $spec.expected) {
      throw "Oracle mapping $($spec.scalar) drift: expected $($spec.expected), got $glyphId."
    }
    $range = Get-GlyphRange $loca $glyphId $locaFormat
    $geometry = Get-GlyphGeometry $glyf $loca $locaFormat $glyphId
    $commands = @(Convert-GeometryToCommands $geometry)
    $fingerprint = Get-FontQualificationSha256 -Bytes $Utf8NoBom.GetBytes(
      $commands -join '|'
    )
    $components = @($geometry.components | ForEach-Object {
      [ordered]@{
        glyph_id = [int]$_.glyph_id
        x = if ($_.arguments_are_xy) { [int]$_.arg1 } else { $null }
        y = if ($_.arguments_are_xy) { [int]$_.arg2 } else { $null }
        transform_q14 = @($_.transform_q14)
      }
    })
    $glyphFacts.Add([ordered]@{
      scalar = $spec.scalar
      glyph_id = $glyphId
      horizontal_metrics = Get-HorizontalMetric $hmtx $glyphId $longMetricCount
      classification = $geometry.classification
      contours = [int]$geometry.contour_count
      bounds = [ordered]@{
        x_min = Read-I16BE $glyf ([int]$range[0] + 2)
        y_min = Read-I16BE $glyf ([int]$range[0] + 4)
        x_max = Read-I16BE $glyf ([int]$range[0] + 6)
        y_max = Read-I16BE $glyf ([int]$range[0] + 8)
      }
      components = $components
      path = [ordered]@{
        command_count = $commands.Count
        fingerprint_sha256 = $fingerprint
        commands = @($commands)
      }
    })
  }

  $kernVersion = [int](Read-U16BE $kern 0)
  $kernSubtableCount = [int](Read-U16BE $kern 2)
  if ($kernVersion -ne 0 -or $kernSubtableCount -ne 1) {
    throw 'Oracle kern envelope drift.'
  }
  $kernCoverage = [int](Read-U16BE $kern 8)
  $kernPairCount = [int](Read-U16BE $kern 10)
  $kerning = $null
  for ($index = 0; $index -lt $kernPairCount; $index++) {
    $pairOffset = 18 + $index * 6
    if ((Read-U16BE $kern $pairOffset) -eq 36 -and
        (Read-U16BE $kern ($pairOffset + 2)) -eq 57) {
      $kerning = Read-I16BE $kern ($pairOffset + 4)
      break
    }
  }
  if ($kerning -ne -131) { throw 'Oracle A/V kerning drift.' }

  $oracle = [ordered]@{
    schema_version = '1.1.0'
    oracle = [ordered]@{
      implementation = 'mnf-powershell-closed-sfnt-reader'
      version = '1.1.0'
      independence = 'offline parser; does not invoke tchivs/mb-font'
    }
    source = [ordered]@{
      path = 'fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf'
      length = $Bytes.Length
      sha256 = $FontSha256
      sfnt_signature = '0x00010000'
    }
    tables = @($tables)
    profile = [ordered]@{
      units_per_em = [int](Read-U16BE $head 18)
      loca_format = if ($locaFormat -eq 1) { 'long' } else { 'short' }
      glyph_count = $glyphCount
    }
    metrics = [ordered]@{
      global_bounds = [ordered]@{
        x_min = Read-I16BE $head 36
        y_min = Read-I16BE $head 38
        x_max = Read-I16BE $head 40
        y_max = Read-I16BE $head 42
      }
      hhea = [ordered]@{
        ascent = Read-I16BE $hhea 4
        descent = Read-I16BE $hhea 6
        line_gap = Read-I16BE $hhea 8
        long_metric_count = $longMetricCount
      }
      os2_typographic = [ordered]@{
        ascent = Read-I16BE $os2 68
        descent = Read-I16BE $os2 70
        line_gap = Read-I16BE $os2 72
      }
    }
    cmap = [ordered]@{
      records = @($cmapRecords)
      selected_record = [ordered]@{
        platform_id = [int]$selectedCmap[0].platform_id
        encoding_id = [int]$selectedCmap[0].encoding_id
        format = [int]$selectedCmap[0].format
      }
    }
    glyphs = @($glyphFacts)
    kern = [ordered]@{
      version = $kernVersion
      subtable_count = $kernSubtableCount
      format = (($kernCoverage -shr 8) -band 0xFF)
      horizontal = (($kernCoverage -band 0x0001) -ne 0)
      pair_count = $kernPairCount
      selected_pair = [ordered]@{
        left_glyph = 36
        right_glyph = 57
        adjustment = $kerning
      }
    }
    maxp = [ordered]@{
      max_points = [int](Read-U16BE $maxp 6)
      max_contours = [int](Read-U16BE $maxp 8)
      max_composite_points = [int](Read-U16BE $maxp 10)
      max_composite_contours = [int](Read-U16BE $maxp 12)
      max_instruction_bytes = [int](Read-U16BE $maxp 26)
      max_component_elements = [int](Read-U16BE $maxp 28)
      max_component_depth = [int](Read-U16BE $maxp 30)
    }
  }
  return $oracle
}

function ConvertTo-StableJson {
  param([Parameter(Mandatory)]$Value)
  return (($Value | ConvertTo-Json -Depth 30).Replace("`r`n", "`n") + "`n")
}

function Get-ExternalManifestRecords {
  return @(
    [ordered]@{
      id = 'font-dejavu-sans-2.37'
      path = 'fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf'
      origin = 'external'
      source = $ArchiveUrl
      author = 'DejaVu Fonts project; derived from Bitstream Vera and Arev'
      retrieval_date = $RetrievalDate
      sha256 = $FontSha256
      license = $UpstreamLicense
      redistribution_status = 'confirmed'
      expected_use = 'Phase 100 licensed real-font public workflow and interoperability qualification'
    },
    [ordered]@{
      id = 'font-dejavu-sans-2.37-license'
      path = 'fixtures/font/dejavu-sans-2.37/LICENSE'
      origin = 'external'
      source = $ArchiveUrl
      author = 'DejaVu Fonts project; Bitstream, Inc.; Tavmjong Bah'
      retrieval_date = $RetrievalDate
      sha256 = $LicenseSha256
      license = $UpstreamLicense
      redistribution_status = 'confirmed'
      expected_use = 'Phase 100 notice accompanying redistribution of DejaVu Sans 2.37'
    }
  )
}

function Assert-ManifestRecord {
  param(
    [Parameter(Mandatory)]$Actual,
    [Parameter(Mandatory)]$Expected
  )
  $expectedKeys = @(
    'id','path','origin','source','author','retrieval_date','sha256','license',
    'redistribution_status','expected_use'
  )
  $actualKeys = @($Actual.PSObject.Properties.Name)
  if ((Compare-Object -CaseSensitive $expectedKeys $actualKeys) -or
      (($actualKeys -join "`0") -cne ($expectedKeys -join "`0"))) {
    throw "Manifest record '$($Expected.id)' keys or order drifted."
  }
  foreach ($key in $expectedKeys) {
    if ([string]$Actual.$key -cne [string]$Expected[$key]) {
      throw "Manifest record '$($Expected.id)' field '$key' drifted."
    }
  }
}

function Update-OrCheckManifest {
  param([switch]$CheckOnly)

  $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
  $expected = @(Get-ExternalManifestRecords)
  $existing = @($manifest.records)
  $matches = @($existing | Where-Object {
    $_.id -ceq $expected[0].id -or $_.id -ceq $expected[1].id
  })
  $fontIndex = -1
  $licenseIndex = -1
  for ($index = 0; $index -lt $existing.Count; $index++) {
    if ($existing[$index].id -ceq $expected[0].id) { $fontIndex = $index }
    if ($existing[$index].id -ceq $expected[1].id) { $licenseIndex = $index }
  }
  if ($CheckOnly) {
    if ($matches.Count -ne 2 -or $existing.Count -lt 2) {
      throw 'DejaVu manifest records are missing or duplicated.'
    }
    if ($fontIndex -lt 0 -or $licenseIndex -ne $fontIndex + 1) {
      throw 'DejaVu manifest records must remain adjacent in canonical order.'
    }
    Assert-ManifestRecord $existing[$fontIndex] $expected[0]
    Assert-ManifestRecord $existing[$licenseIndex] $expected[1]
    return
  }
  if ($matches.Count -eq 2 -and
      $fontIndex -ge 0 -and $licenseIndex -eq $fontIndex + 1) {
    Assert-ManifestRecord $existing[$fontIndex] $expected[0]
    Assert-ManifestRecord $existing[$licenseIndex] $expected[1]
    return
  }
  if ($matches.Count -ne 0) {
    throw 'Refusing partial, duplicate, or reordered DejaVu manifest records.'
  }
  $manifest.records = @($existing) + $expected
  [IO.File]::WriteAllText(
    $ManifestPath,
    (($manifest | ConvertTo-Json -Depth 30) + "`n"),
    $Utf8NoBom
  )
}

function Invoke-FontQualificationIntake {
  $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) (
    'mnf-font-qualification-' + [guid]::NewGuid().ToString('N')
  )
  [void](New-Item -ItemType Directory -Path $temporaryRoot)
  try {
    $archivePath = Join-Path $temporaryRoot 'dejavu-sans-ttf-2.37.zip'
    Invoke-WebRequest -Uri $ArchiveUrl -OutFile $archivePath -UseBasicParsing
    $archiveBytes = [IO.File]::ReadAllBytes($archivePath)
    Assert-ExactBytesIdentity 'DejaVu archive' $archiveBytes $ArchiveLength $ArchiveSha256

    Add-Type -AssemblyName System.IO.Compression
    $stream = [IO.MemoryStream]::new($archiveBytes, $false)
    $archive = [IO.Compression.ZipArchive]::new(
      $stream,
      [IO.Compression.ZipArchiveMode]::Read,
      $false
    )
    try {
      $fontEntries = @($archive.Entries | Where-Object FullName -CEQ $ArchiveFontMember)
      $licenseEntries = @($archive.Entries | Where-Object FullName -CEQ $ArchiveLicenseMember)
      if ($fontEntries.Count -ne 1 -or $licenseEntries.Count -ne 1) {
        throw 'DejaVu archive exact member set is missing or duplicated.'
      }
      $fontStream = $fontEntries[0].Open()
      $licenseStream = $licenseEntries[0].Open()
      try {
        $fontMemory = [IO.MemoryStream]::new()
        $licenseMemory = [IO.MemoryStream]::new()
        $fontStream.CopyTo($fontMemory)
        $licenseStream.CopyTo($licenseMemory)
        $fontBytes = $fontMemory.ToArray()
        $licenseBytes = $licenseMemory.ToArray()
      } finally {
        $fontStream.Dispose()
        $licenseStream.Dispose()
        if ($null -ne $fontMemory) { $fontMemory.Dispose() }
        if ($null -ne $licenseMemory) { $licenseMemory.Dispose() }
      }
    } finally {
      $archive.Dispose()
      $stream.Dispose()
    }

    # Both archive members are proven before the first repository mutation.
    Assert-ExactBytesIdentity 'DejaVuSans.ttf member' $fontBytes $FontLength $FontSha256
    Assert-ExactBytesIdentity 'DejaVu LICENSE member' $licenseBytes $LicenseLength $LicenseSha256
    $oracle = Read-FontQualificationSfntOracle -Bytes $fontBytes

    [void](New-Item -ItemType Directory -Force -Path $FixtureDirectory)
    [IO.File]::WriteAllBytes($FontPath, $fontBytes)
    [IO.File]::WriteAllBytes($LicensePath, $licenseBytes)
    [IO.File]::WriteAllText($OraclePath, (ConvertTo-StableJson $oracle), $Utf8NoBom)
    Update-OrCheckManifest
  } finally {
    Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

function Read-FontQualificationCases {
  if (-not (Test-Path -LiteralPath $CasesPath -PathType Leaf)) {
    throw "Font qualification cases are missing: $CasesPath"
  }
  $casesDocument = Get-Content -Raw -LiteralPath $CasesPath | ConvertFrom-Json
  $documentKeys = @($casesDocument.PSObject.Properties.Name)
  if (($documentKeys -join "`0") -cne ('schema_version','license','cases' -join "`0") -or
      $casesDocument.schema_version -cne '1.0.0' -or
      $casesDocument.license -cne 'Apache-2.0') {
    throw 'Font qualification case document schema or license drifted.'
  }
  $expectedIds = @(
    'malformed-directory-range',
    'unsupported-outline-profile',
    'mutation-after-open',
    'checked-range-overflow',
    'limit-source-exact',
    'limit-source-one-short',
    'budget-open-exact',
    'budget-open-one-short',
    'budget-outline-exact',
    'budget-outline-one-short',
    'nested-composite-recognized'
  )
  $actualCases = @($casesDocument.cases)
  if (($actualCases.id -join "`0") -cne ($expectedIds -join "`0")) {
    throw 'Font qualification case ID sequence drifted.'
  }
  $caseKeys = @(
    'id','stage','category','code','context','requested','limit','publication'
  )
  $allowedStages = @('open','query','outline')
  $allowedCategories = @('','Data','Capability','State','Resource')
  $allowedCodes = @('','InvalidEncoding','CapabilityUnavailable','InvalidRange','BudgetExceeded')
  $allowedPublications = @('none','font','path','existing-font-only','font-only')
  foreach ($case in $actualCases) {
    if ((@($case.PSObject.Properties.Name) -join "`0") -cne ($caseKeys -join "`0")) {
      throw "Font qualification case '$($case.id)' key set or order drifted."
    }
    if ($allowedStages -cnotcontains [string]$case.stage -or
        $allowedCategories -cnotcontains [string]$case.category -or
        $allowedCodes -cnotcontains [string]$case.code -or
        $allowedPublications -cnotcontains [string]$case.publication) {
      throw "Font qualification case '$($case.id)' contains an unknown closed value."
    }
    if (($case.category -ceq '') -ne ($case.code -ceq '') -or
        ($case.category -ceq '') -ne ($case.context -ceq '')) {
      throw "Font qualification case '$($case.id)' success/error fields are inconsistent."
    }
    foreach ($field in @('requested','limit')) {
      $value = $case.$field
      if ($null -ne $value -and ([int64]$value -lt 0)) {
        throw "Font qualification case '$($case.id)' has a negative $field."
      }
    }
  }
  return $casesDocument
}

function Assert-FontQualificationOrderedKeys {
  param(
    [Parameter(Mandatory)]$Value,
    [Parameter(Mandatory)][string[]]$Expected,
    [Parameter(Mandatory)][string]$Label
  )

  $actual = if ($Value -is [Collections.IDictionary]) {
    @($Value.Keys)
  } else {
    @($Value.PSObject.Properties.Name)
  }
  if (($actual -join "`0") -cne ($Expected -join "`0")) {
    throw "$Label keys or order drifted."
  }
}

function Get-FontCollectionQualificationExpectedIds {
  $fixtureIds = @(
    'generated-ttc-v1-static-selected',
    'generated-ttc-v2-dsig-absent',
    'generated-ttc-v2-dsig-present-unverified',
    'generated-ttc-v1-exact-sharing',
    'generated-ttc-v2-mixed-profiles',
    'generated-ttc-v1-nonzero-directory-base',
    'licensed-dejavu-two-face-v1'
  )
  $publicWorkflowIds = @(
    'generated-ttc-v1-static-selected',
    'generated-ttc-v2-dsig-absent',
    'generated-ttc-v2-dsig-present-unverified',
    'generated-ttc-v1-exact-sharing',
    'generated-ttc-v2-mixed-profiles',
    'generated-ttc-v1-nonzero-directory-base',
    'licensed-dejavu-two-face-v1-face-0',
    'licensed-dejavu-two-face-v1-face-1'
  )
  $hostileIds = @(
    'collection-header-truncated',
    'collection-signature-invalid',
    'collection-version-unsupported',
    'collection-face-count-zero',
    'collection-offset-array-truncated',
    'collection-face-directory-truncated',
    'collection-directory-search-facts-invalid',
    'collection-directory-tags-unordered',
    'collection-table-range-overflow',
    'collection-protected-range-overlap',
    'collection-same-face-overlap',
    'collection-cross-face-partial-overlap',
    'collection-shared-range-metadata-conflict',
    'collection-dsig-partial-zero-tuple',
    'collection-dsig-range-not-at-eof',
    'collection-dsig-envelope-malformed',
    'collection-dsig-version-unsupported',
    'collection-dsig-format-unsupported',
    'collection-dsig-block-overlap',
    'collection-face-index-equal-count',
    'collection-select-cff',
    'collection-select-cff2',
    'collection-select-variable',
    'collection-checked-pair-work-overflow'
  )
  $mutationIds = @(
    'mutation-collection-after-open-before-query',
    'mutation-collection-mid-open-final-guard',
    'mutation-selection-before-open-face',
    'mutation-selection-mid-admission-final-guard',
    'mutation-selected-font-after-publication',
    'mutation-glyph-lookup-mid-query',
    'mutation-kerning-mid-query',
    'mutation-simple-outline-mid-query',
    'mutation-composite-outline-mid-query'
  )
  $limitIds = [Collections.Generic.List[string]]::new()
  foreach ($dimension in @(
      'source-bytes','faces','tables-per-face','table-records','dsig-records',
      'dsig-bytes','retained-bookkeeping-bytes','work'
    )) {
    $limitIds.Add("limit-collection-$dimension-exact")
    $limitIds.Add("limit-collection-$dimension-one-short")
  }
  foreach ($dimension in @(
      'source-bytes','tables','table-bytes','glyphs','name-records',
      'cmap-records','kern-subtables','kern-pairs','outline-points',
      'outline-contours','outline-components','instruction-bytes',
      'post-name-bytes','work'
    )) {
    $limitIds.Add("limit-selected-$dimension-exact")
    $limitIds.Add("limit-selected-$dimension-one-short")
  }
  $budgetIds = [Collections.Generic.List[string]]::new()
  foreach ($dimension in @('bytes','allocations','allocation-size','work')) {
    $budgetIds.Add("budget-caller-$dimension-exact")
    $budgetIds.Add("budget-caller-$dimension-one-short")
  }
  foreach ($dimension in @('bytes','work')) {
    $budgetIds.Add("budget-ancestor-$dimension-exact")
    $budgetIds.Add("budget-ancestor-$dimension-one-short")
  }
  return [ordered]@{
    fixtures = $fixtureIds
    public_workflows = $publicWorkflowIds
    hostile_cases = $hostileIds
    mutation_cases = $mutationIds
    limit_cases = @($limitIds)
    budget_cases = @($budgetIds)
  }
}

function Read-FontCollectionQualificationCases {
  param([AllowNull()]$Document)
  if ($null -eq $Document) {
    if (-not (Test-Path -LiteralPath $CollectionCasesPath -PathType Leaf)) {
      throw "Font collection qualification cases are missing: $CollectionCasesPath"
    }
    $bytes = [IO.File]::ReadAllBytes($CollectionCasesPath)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and
        $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
      throw 'Font collection qualification cases must be UTF-8 without BOM.'
    }
    $text = $Utf8NoBom.GetString($bytes)
    if ($text.Contains("`r", [StringComparison]::Ordinal) -or
        -not $text.EndsWith("`n", [StringComparison]::Ordinal)) {
      throw 'Font collection qualification cases must use LF and one trailing newline.'
    }
    $document = $text | ConvertFrom-Json
  } else {
    $document = $Document
  }
  Assert-FontQualificationOrderedKeys $document @(
    'schema_version','workflow_id','license','fixtures','public_workflows',
    'hostile_cases','mutation_cases','limit_cases','budget_cases'
  ) 'Font collection qualification document'
  if ($document.schema_version -cne '1.0.0' -or
      $document.workflow_id -cne 'font-collection-complete-public-v2' -or
      $document.license -cne 'Apache-2.0') {
    throw 'Font collection qualification document identity or license drifted.'
  }

  $expectedIds = Get-FontCollectionQualificationExpectedIds
  $fixtureKeys = @(
    'id','origin','container_version','face_count','dsig_status','profiles','expected_use'
  )
  foreach ($fixture in @($document.fixtures)) {
    Assert-FontQualificationOrderedKeys $fixture $fixtureKeys "Collection fixture '$($fixture.id)'"
    if ($fixture.origin -cnotin @('generated','external') -or
        [int64]$fixture.face_count -lt 1 -or
        $fixture.dsig_status -cnotin @('absent','present-unverified') -or
        @($fixture.profiles).Count -ne [int]$fixture.face_count) {
      throw "Collection fixture '$($fixture.id)' contains an invalid closed value."
    }
  }

  $caseKeys = @(
    'id','fixture_id','stage','entrypoint','face_index','mutation_window',
    'authority','boundary','error','publication','budget_before','budget_after'
  )
  $errorKeys = @(
    'category','code','operation','context','source_offset','requested','limit'
  )
  $budgetKeys = @(
    'bytes','allocations','allocation_size','width','height','pixels','depth','work'
  )
  foreach ($group in @(
      'public_workflows','hostile_cases','mutation_cases','limit_cases','budget_cases'
    )) {
    $actual = @($document.$group)
    if (($actual.id -join "`0") -cne (@($expectedIds[$group]) -join "`0")) {
      throw "Font collection qualification $group ID sequence drifted."
    }
    foreach ($case in $actual) {
      Assert-FontQualificationOrderedKeys $case $caseKeys "Collection case '$($case.id)'"
      Assert-FontQualificationOrderedKeys $case.error $errorKeys "Collection case '$($case.id)' error"
      Assert-FontQualificationOrderedKeys $case.budget_before $budgetKeys "Collection case '$($case.id)' budget_before"
      Assert-FontQualificationOrderedKeys $case.budget_after $budgetKeys "Collection case '$($case.id)' budget_after"
      if ($case.stage -cnotin @('open','inspect','select','query') -or
          $case.entrypoint -cnotin @(
            'FontCollection::open','FontCollection::face_profile',
            'FontCollection::open_face','Font::query'
          ) -or
          $case.boundary -cnotin @('success','failure','exact','one-short') -or
          $case.publication -cnotin @(
            'none','collection','font','existing-collection-only','existing-font-only'
          )) {
        throw "Collection case '$($case.id)' contains an unknown closed value."
      }
      $errorIsEmpty = $null -eq $case.error.category
      if (-not $errorIsEmpty -and
          ($case.error.category -cnotin @('Data','Capability','State','Resource','Input') -or
           $case.error.code -cnotin @(
             'InvalidEncoding','CapabilityUnavailable','InvalidRange',
             'BudgetExceeded','InvalidInput'
           ))) {
        throw "Collection case '$($case.id)' has an unknown closed error identity."
      }
      foreach ($field in @('code','operation','context')) {
        if (($null -eq $case.error.$field) -ne $errorIsEmpty) {
          throw "Collection case '$($case.id)' has a partial error identity."
        }
      }
      if (($case.boundary -in @('success','exact')) -ne $errorIsEmpty) {
        throw "Collection case '$($case.id)' success/error boundary is inconsistent."
      }
      foreach ($snapshot in @($case.budget_before, $case.budget_after)) {
        foreach ($field in $budgetKeys) {
          if ([int64]$snapshot.$field -lt 0) {
            throw "Collection case '$($case.id)' has a negative budget field '$field'."
          }
        }
      }
      if (-not $errorIsEmpty -and
          (ConvertTo-StableJson $case.budget_before) -cne
          (ConvertTo-StableJson $case.budget_after)) {
        throw "Collection case '$($case.id)' failure is not budget-atomic."
      }
    }
  }
  if ((@($document.fixtures).id -join "`0") -cne
      (@($expectedIds.fixtures) -join "`0")) {
    throw 'Font collection qualification fixture ID sequence drifted.'
  }
  return $document
}

function New-FontCollectionQualificationBudgetSnapshot {
  param(
    [uint64]$Bytes = 0UL,
    [uint64]$Allocations = 0UL,
    [uint64]$AllocationSize = 0UL,
    [uint64]$Width = 0UL,
    [uint64]$Height = 0UL,
    [uint64]$Pixels = 0UL,
    [uint64]$Depth = 0UL,
    [uint64]$Work = 0UL
  )
  return [ordered]@{
    bytes = $Bytes
    allocations = $Allocations
    allocation_size = $AllocationSize
    width = $Width
    height = $Height
    pixels = $Pixels
    depth = $Depth
    work = $Work
  }
}

function New-FontCollectionQualificationCase {
  param(
    [Parameter(Mandatory)][string]$Id,
    [Parameter(Mandatory)][string]$FixtureId,
    [Parameter(Mandatory)][string]$Stage,
    [Parameter(Mandatory)][string]$Entrypoint,
    [AllowNull()]$FaceIndex,
    [string]$MutationWindow = 'none',
    [Parameter(Mandatory)][string]$Authority,
    [Parameter(Mandatory)][string]$Boundary,
    [AllowNull()]$Category,
    [AllowNull()]$Code,
    [AllowNull()]$Operation,
    [AllowNull()]$Context,
    [AllowNull()]$SourceOffset,
    [AllowNull()]$Requested,
    [AllowNull()]$Limit,
    [Parameter(Mandatory)][string]$Publication,
    [Parameter(Mandatory)]$BudgetBefore,
    [Parameter(Mandatory)]$BudgetAfter
  )
  return [ordered]@{
    id = $Id
    fixture_id = $FixtureId
    stage = $Stage
    entrypoint = $Entrypoint
    face_index = $FaceIndex
    mutation_window = $MutationWindow
    authority = $Authority
    boundary = $Boundary
    error = [ordered]@{
      category = $Category
      code = $Code
      operation = $Operation
      context = $Context
      source_offset = $SourceOffset
      requested = $Requested
      limit = $Limit
    }
    publication = $Publication
    budget_before = $BudgetBefore
    budget_after = $BudgetAfter
  }
}

function New-FontCollectionQualificationCases {
  $expectedIds = Get-FontCollectionQualificationExpectedIds
  $zero = New-FontCollectionQualificationBudgetSnapshot
  $fixtures = @(
    [ordered]@{
      id = 'generated-ttc-v1-static-selected'
      origin = 'generated'
      container_version = '1.0'
      face_count = 1
      dsig_status = 'absent'
      profiles = @('StaticGlyf')
      expected_use = 'public v1 inspection and static selected-face admission'
    },
    [ordered]@{
      id = 'generated-ttc-v2-dsig-absent'
      origin = 'generated'
      container_version = '2.0'
      face_count = 1
      dsig_status = 'absent'
      profiles = @('StaticGlyf')
      expected_use = 'public v2 all-zero DSIG tuple inspection'
    },
    [ordered]@{
      id = 'generated-ttc-v2-dsig-present-unverified'
      origin = 'generated'
      container_version = '2.0'
      face_count = 1
      dsig_status = 'present-unverified'
      profiles = @('StaticGlyf')
      expected_use = 'public v2 bounded DSIG envelope inspection without trust'
    },
    [ordered]@{
      id = 'generated-ttc-v1-exact-sharing'
      origin = 'generated'
      container_version = '1.0'
      face_count = 2
      dsig_status = 'absent'
      profiles = @('StaticGlyf','StaticGlyf')
      expected_use = 'exact root-range sharing and repeated selected-face admission'
    },
    [ordered]@{
      id = 'generated-ttc-v2-mixed-profiles'
      origin = 'generated'
      container_version = '2.0'
      face_count = 5
      dsig_status = 'absent'
      profiles = @('StaticGlyf','Cff','Cff2','Variable','OtherUnsupported')
      expected_use = 'inspectable mixed profiles with unsupported selected siblings'
    },
    [ordered]@{
      id = 'generated-ttc-v1-nonzero-directory-base'
      origin = 'generated'
      container_version = '1.0'
      face_count = 1
      dsig_status = 'absent'
      profiles = @('StaticGlyf')
      expected_use = 'root-relative table coordinates at a nonzero face directory'
    },
    [ordered]@{
      id = 'licensed-dejavu-two-face-v1'
      origin = 'external'
      container_version = '1.0'
      face_count = 2
      dsig_status = 'absent'
      profiles = @('StaticGlyf','StaticGlyf')
      expected_use = 'licensed exact-sharing interoperability bound to standalone facts'
    }
  )

  $publicWorkflows = [Collections.Generic.List[object]]::new()
  foreach ($id in @($expectedIds.public_workflows)) {
    $isLicensed = $id.StartsWith('licensed-', [StringComparison]::Ordinal)
    $fixtureId = if ($isLicensed) {
      'licensed-dejavu-two-face-v1'
    } else {
      $id
    }
    $faceIndex = if ($id.EndsWith('-face-0', [StringComparison]::Ordinal)) {
      0
    } elseif ($id.EndsWith('-face-1', [StringComparison]::Ordinal)) {
      1
    } else {
      0
    }
    $publicWorkflows.Add((New-FontCollectionQualificationCase `
      -Id $id -FixtureId $fixtureId -Stage 'select' `
      -Entrypoint 'FontCollection::open_face' -FaceIndex $faceIndex `
      -Authority $(if ($isLicensed) { 'licensed' } else { 'generated' }) `
      -Boundary 'success' -Category $null -Code $null -Operation $null `
      -Context $null -SourceOffset $null -Requested $null -Limit $null `
      -Publication 'font' -BudgetBefore $zero -BudgetAfter $zero))
  }

  $hostile = [Collections.Generic.List[object]]::new()
  foreach ($id in @($expectedIds.hostile_cases)) {
    $entrypoint = 'FontCollection::open'
    $stage = 'open'
    $faceIndex = $null
    $category = 'Data'
    $code = 'InvalidEncoding'
    $operation = 'font-collection-open'
    $context = $id
    $sourceOffset = $null
    $requested = $null
    $limit = $null
    if ($id -in @(
        'collection-version-unsupported','collection-dsig-version-unsupported',
        'collection-dsig-format-unsupported','collection-select-cff',
        'collection-select-cff2','collection-select-variable'
      )) {
      $category = 'Capability'
      $code = 'CapabilityUnavailable'
    }
    if ($id -eq 'collection-face-index-equal-count') {
      $entrypoint = 'FontCollection::open_face'
      $stage = 'select'
      $faceIndex = 2
      $category = 'Input'
      $code = 'InvalidInput'
      $operation = 'font-collection-face'
      $context = 'font-collection-face-index'
      $requested = 2
      $limit = 2
    } elseif ($id -in @(
        'collection-select-cff','collection-select-cff2','collection-select-variable'
      )) {
      $entrypoint = 'FontCollection::open_face'
      $stage = 'select'
      $faceIndex = switch ($id) {
        'collection-select-cff' { 1 }
        'collection-select-cff2' { 2 }
        default { 3 }
      }
      $operation = 'font-collection-face'
      $context = 'font-collection-face-profile'
    } elseif ($id -eq 'collection-checked-pair-work-overflow') {
      $operation = 'font-collection-open'
      $context = 'font-collection-pair-work'
    }
    $hostile.Add((New-FontCollectionQualificationCase `
      -Id $id -FixtureId 'generated-ttc-v2-mixed-profiles' -Stage $stage `
      -Entrypoint $entrypoint -FaceIndex $faceIndex -Authority 'hostile' `
      -Boundary 'failure' -Category $category -Code $code `
      -Operation $operation -Context $context -SourceOffset $sourceOffset `
      -Requested $requested -Limit $limit -Publication 'none' `
      -BudgetBefore $zero -BudgetAfter $zero))
  }

  $mutation = [Collections.Generic.List[object]]::new()
  foreach ($id in @($expectedIds.mutation_cases)) {
    $isCollection = $id -like 'mutation-collection-*'
    $isSelection = $id -like 'mutation-selection-*'
    $entrypoint = if ($isCollection) {
      'FontCollection::face_profile'
    } elseif ($isSelection) {
      'FontCollection::open_face'
    } else {
      'Font::query'
    }
    $stage = if ($isCollection) {
      'inspect'
    } elseif ($isSelection) {
      'select'
    } else {
      'query'
    }
    $publication = if ($isCollection -or $isSelection) {
      'existing-collection-only'
    } else {
      'existing-font-only'
    }
    $mutation.Add((New-FontCollectionQualificationCase `
      -Id $id -FixtureId 'generated-ttc-v1-exact-sharing' -Stage $stage `
      -Entrypoint $entrypoint -FaceIndex $(if ($isCollection) { $null } else { 0 }) `
      -MutationWindow $id -Authority 'mutation' -Boundary 'failure' `
      -Category 'State' -Code 'InvalidRange' `
      -Operation $(if ($entrypoint -ceq 'Font::query') { 'font-query' } else { 'font-collection-revision' }) `
      -Context $(if ($entrypoint -ceq 'Font::query') { 'font-source-revision-drift' } else { 'font-collection-source-revision-drift' }) `
      -SourceOffset $null -Requested $null -Limit $null `
      -Publication $publication -BudgetBefore $zero -BudgetAfter $zero))
  }

  $limits = [Collections.Generic.List[object]]::new()
  foreach ($id in @($expectedIds.limit_cases)) {
    $selected = $id.StartsWith('limit-selected-', [StringComparison]::Ordinal)
    $oneShort = $id.EndsWith('-one-short', [StringComparison]::Ordinal)
    $dimension = $id.Substring($(if ($selected) { 15 } else { 17 }))
    $dimension = $dimension.Substring(
      0,
      $dimension.Length - $(if ($oneShort) { 10 } else { 6 })
    )
    $limits.Add((New-FontCollectionQualificationCase `
      -Id $id `
      -FixtureId $(if ($selected) { 'generated-ttc-v1-static-selected' } else { 'generated-ttc-v1-exact-sharing' }) `
      -Stage $(if ($selected) { 'select' } else { 'open' }) `
      -Entrypoint $(if ($selected) { 'FontCollection::open_face' } else { 'FontCollection::open' }) `
      -FaceIndex $(if ($selected) { 0 } else { $null }) `
      -Authority $(if ($selected) { 'selected-limit' } else { 'collection-limit' }) `
      -Boundary $(if ($oneShort) { 'one-short' } else { 'exact' }) `
      -Category $(if ($oneShort) { 'Resource' } else { $null }) `
      -Code $(if ($oneShort) { 'BudgetExceeded' } else { $null }) `
      -Operation $(if ($oneShort) { $(if ($selected) { 'font-open' } else { 'font-collection-open' }) } else { $null }) `
      -Context $(if ($oneShort) { "max-$dimension" } else { $null }) `
      -SourceOffset $null -Requested 1 -Limit $(if ($oneShort) { 0 } else { 1 }) `
      -Publication $(if ($oneShort) { 'none' } elseif ($selected) { 'font' } else { 'collection' }) `
      -BudgetBefore $zero -BudgetAfter $zero))
  }

  $budgets = [Collections.Generic.List[object]]::new()
  foreach ($id in @($expectedIds.budget_cases)) {
    $ancestor = $id.StartsWith('budget-ancestor-', [StringComparison]::Ordinal)
    $oneShort = $id.EndsWith('-one-short', [StringComparison]::Ordinal)
    $dimension = $id.Substring($(if ($ancestor) { 16 } else { 14 }))
    $dimension = $dimension.Substring(
      0,
      $dimension.Length - $(if ($oneShort) { 10 } else { 6 })
    )
    $requested = switch ($dimension) {
      'bytes' { 248UL }
      'allocations' { 2UL }
      'allocation-size' { 80UL }
      'work' { 66UL }
    }
    $limit = if ($oneShort) { $requested - 1UL } else { $requested }
    $before = New-FontCollectionQualificationBudgetSnapshot `
      -Bytes $(if ($dimension -ceq 'bytes') { $limit } else { 248UL }) `
      -Allocations $(if ($dimension -ceq 'allocations') { $limit } else { 2UL }) `
      -AllocationSize $(if ($dimension -ceq 'allocation-size') { $limit } else { 80UL }) `
      -Work $(if ($dimension -ceq 'work') { $limit } else { 66UL })
    $after = if ($oneShort) {
      $before
    } else {
      New-FontCollectionQualificationBudgetSnapshot `
        -Bytes 0UL -Allocations 0UL -AllocationSize $before.allocation_size -Work 0UL
    }
    $budgets.Add((New-FontCollectionQualificationCase `
      -Id $id -FixtureId 'generated-ttc-v1-exact-sharing' -Stage 'open' `
      -Entrypoint 'FontCollection::open' -FaceIndex $null `
      -Authority $(if ($ancestor) { 'ancestor-budget' } else { 'caller-budget' }) `
      -Boundary $(if ($oneShort) { 'one-short' } else { 'exact' }) `
      -Category $(if ($oneShort) { 'Resource' } else { $null }) `
      -Code $(if ($oneShort) { 'BudgetExceeded' } else { $null }) `
      -Operation $(if ($oneShort) { 'budget_charge' } else { $null }) `
      -Context $(if ($oneShort) { $dimension.Replace('-', '_') } else { $null }) `
      -SourceOffset $null -Requested $requested -Limit $limit `
      -Publication $(if ($oneShort) { 'none' } else { 'collection' }) `
      -BudgetBefore $before -BudgetAfter $after))
  }

  return [ordered]@{
    schema_version = '1.0.0'
    workflow_id = 'font-collection-complete-public-v2'
    license = 'Apache-2.0'
    fixtures = $fixtures
    public_workflows = @($publicWorkflows)
    hostile_cases = @($hostile)
    mutation_cases = @($mutation)
    limit_cases = @($limits)
    budget_cases = @($budgets)
  }
}

function Write-U32BE {
  param(
    [Parameter(Mandatory)][byte[]]$Bytes,
    [Parameter(Mandatory)][int]$Offset,
    [Parameter(Mandatory)][uint64]$Value
  )
  if ($Offset -lt 0 -or $Offset + 4 -gt $Bytes.Length -or
      $Value -gt [uint32]::MaxValue) {
    throw "Oracle u32 write range or value is invalid at $Offset."
  }
  $Bytes[$Offset] = [byte](($Value -shr 24) -band 0xFF)
  $Bytes[$Offset + 1] = [byte](($Value -shr 16) -band 0xFF)
  $Bytes[$Offset + 2] = [byte](($Value -shr 8) -band 0xFF)
  $Bytes[$Offset + 3] = [byte]($Value -band 0xFF)
}

function New-FontQualificationDejaVuTtc {
  param([Parameter(Mandatory)][byte[]]$FontBytes)

  Assert-ExactBytesIdentity 'DejaVuSans.ttf' $FontBytes $FontLength $FontSha256
  $tableCount = [int](Read-U16BE $FontBytes 4)
  $directoryLength = 12L + 16L * $tableCount
  if ($tableCount -ne 20 -or $directoryLength -ne 332L) {
    throw 'DejaVu standalone directory facts drifted before TTC derivation.'
  }
  $output = [byte[]]::new($CollectionFontLength)
  Write-U32BE $output 0 0x74746366UL
  Write-U32BE $output 4 0x00010000UL
  Write-U32BE $output 8 2UL
  Write-U32BE $output 12 20UL
  Write-U32BE $output 16 352UL
  [Array]::Copy($FontBytes, 0, $output, 20, [int]$directoryLength)
  [Array]::Copy($FontBytes, 0, $output, 352, [int]$directoryLength)
  for ($index = 0; $index -lt $tableCount; $index++) {
    $offsetField = 12 + $index * 16 + 8
    $standaloneOffset = Read-U32BE $FontBytes $offsetField
    if ($standaloneOffset -lt $directoryLength) {
      throw "DejaVu table $index begins inside the standalone directory."
    }
    $collectionOffset = 684UL + ($standaloneOffset - $directoryLength)
    Write-U32BE $output (20 + $offsetField) $collectionOffset
    Write-U32BE $output (352 + $offsetField) $collectionOffset
  }
  [Array]::Copy(
    $FontBytes,
    [int]$directoryLength,
    $output,
    684,
    $FontBytes.Length - [int]$directoryLength
  )
  Assert-ExactBytesIdentity `
    'DejaVuSans-two-face-v1.ttc' `
    $output `
    $CollectionFontLength `
    $CollectionFontSha256
  return $output
}

function Get-FontQualificationTableChecksum {
  param(
    [Parameter(Mandatory)][byte[]]$Bytes,
    [Parameter(Mandatory)][int]$Offset,
    [Parameter(Mandatory)][int]$Length,
    [switch]$ZeroHeadAdjustment
  )
  if ($Offset -lt 0 -or $Length -lt 0 -or $Offset + $Length -gt $Bytes.Length) {
    throw 'TTC oracle table checksum range exceeds source.'
  }
  [uint64]$sum = 0UL
  $paddedLength = [int](($Length + 3) -band -4)
  for ($relative = 0; $relative -lt $paddedLength; $relative += 4) {
    [uint64]$word = 0UL
    for ($byteIndex = 0; $byteIndex -lt 4; $byteIndex++) {
      $position = $relative + $byteIndex
      $value = if ($position -ge $Length -or
          ($ZeroHeadAdjustment -and $position -ge 8 -and $position -lt 12)) {
        0
      } else {
        [int]$Bytes[$Offset + $position]
      }
      $word = ($word -shl 8) -bor [uint64]$value
    }
    $sum = ($sum + $word) -band 0xFFFFFFFFUL
  }
  return $sum
}

function Read-FontQualificationTtcOracle {
  param(
    [Parameter(Mandatory)][byte[]]$TtcBytes,
    [Parameter(Mandatory)][byte[]]$FontBytes,
    [Parameter(Mandatory)]$StandaloneOracle
  )

  Assert-ExactBytesIdentity `
    'DejaVuSans-two-face-v1.ttc' `
    $TtcBytes `
    $CollectionFontLength `
    $CollectionFontSha256
  Assert-ExactBytesIdentity 'DejaVuSans.ttf' $FontBytes $FontLength $FontSha256
  if ((Read-U32BE $TtcBytes 0) -ne 0x74746366UL -or
      (Read-U32BE $TtcBytes 4) -ne 0x00010000UL -or
      (Read-U32BE $TtcBytes 8) -ne 2UL) {
    throw 'Independent TTC oracle header identity drifted.'
  }
  $faceOffsets = @(
    [int](Read-U32BE $TtcBytes 12),
    [int](Read-U32BE $TtcBytes 16)
  )
  if (($faceOffsets -join ',') -cne '20,352') {
    throw 'Independent TTC oracle face coordinates drifted.'
  }

  $faces = [Collections.Generic.List[object]]::new()
  $faceRecords = @()
  for ($faceIndex = 0; $faceIndex -lt 2; $faceIndex++) {
    $directoryOffset = $faceOffsets[$faceIndex]
    $signature = Read-U32BE $TtcBytes $directoryOffset
    $tableCount = [int](Read-U16BE $TtcBytes ($directoryOffset + 4))
    $searchRange = [int](Read-U16BE $TtcBytes ($directoryOffset + 6))
    $entrySelector = [int](Read-U16BE $TtcBytes ($directoryOffset + 8))
    $rangeShift = [int](Read-U16BE $TtcBytes ($directoryOffset + 10))
    if ($signature -ne 0x00010000UL -or $tableCount -ne 20 -or
        $searchRange -ne [int](Read-U16BE $FontBytes 6) -or
        $entrySelector -ne [int](Read-U16BE $FontBytes 8) -or
        $rangeShift -ne [int](Read-U16BE $FontBytes 10)) {
      throw "Independent TTC oracle face $faceIndex directory facts drifted."
    }
    $records = [Collections.Generic.List[object]]::new()
    for ($recordIndex = 0; $recordIndex -lt $tableCount; $recordIndex++) {
      $recordOffset = $directoryOffset + 12 + $recordIndex * 16
      $tag = [Text.Encoding]::ASCII.GetString($TtcBytes, $recordOffset, 4)
      $record = [ordered]@{
        tag = $tag
        checksum = ('{0:x8}' -f (Read-U32BE $TtcBytes ($recordOffset + 4)))
        offset = [int](Read-U32BE $TtcBytes ($recordOffset + 8))
        length = [int](Read-U32BE $TtcBytes ($recordOffset + 12))
      }
      if ($record.offset -lt 684 -or
          [int64]$record.offset + [int64]$record.length -gt $TtcBytes.Length) {
        throw "Independent TTC oracle face $faceIndex table '$tag' range drifted."
      }
      $records.Add($record)
    }
    if ((@($records.tag) -join "`0") -cne (@($StandaloneOracle.tables.tag) -join "`0")) {
      throw "Independent TTC oracle face $faceIndex table order drifted."
    }
    $faceRecords += ,@($records)
    $faces.Add([ordered]@{
      index = $faceIndex
      directory_offset = $directoryOffset
      sfnt_signature = '0x00010000'
      table_count = $tableCount
      search_range = $searchRange
      entry_selector = $entrySelector
      range_shift = $rangeShift
      profile = 'StaticGlyf'
      records = @($records)
    })
  }

  $sharedTables = [Collections.Generic.List[object]]::new()
  for ($index = 0; $index -lt 20; $index++) {
    $first = $faceRecords[0][$index]
    $second = $faceRecords[1][$index]
    $source = $StandaloneOracle.tables[$index]
    $expectedOffset = 684 + ([int]$source.offset - 332)
    if ((ConvertTo-StableJson $first) -cne (ConvertTo-StableJson $second) -or
        $first.tag -cne $source.tag -or
        $first.checksum -cne $source.checksum -or
        $first.offset -ne $expectedOffset -or
        $first.length -ne [int]$source.length) {
      throw "Independent TTC oracle shared record $index drifted."
    }
    $sourcePayload = [byte[]]::new([int]$source.length)
    $collectionPayload = [byte[]]::new([int]$first.length)
    [Array]::Copy($FontBytes, [int]$source.offset, $sourcePayload, 0, $sourcePayload.Length)
    [Array]::Copy($TtcBytes, [int]$first.offset, $collectionPayload, 0, $collectionPayload.Length)
    if (-not [Linq.Enumerable]::SequenceEqual(
        [byte[]]$sourcePayload,
        [byte[]]$collectionPayload
      )) {
      throw "Independent TTC oracle shared table '$($first.tag)' payload drifted."
    }
    $checksum = Get-FontQualificationTableChecksum `
      -Bytes $TtcBytes `
      -Offset ([int]$first.offset) `
      -Length ([int]$first.length) `
      -ZeroHeadAdjustment:($first.tag -ceq 'head')
    $checksumHex = '{0:x8}' -f $checksum
    if ($checksumHex -cne $first.checksum) {
      throw "Independent TTC oracle shared table '$($first.tag)' checksum drifted."
    }
    $sharedTables.Add([ordered]@{
      tag = $first.tag
      root_offset = $first.offset
      length = $first.length
      stored_checksum = $first.checksum
      recomputed_checksum = $checksumHex
      source_offset = [int]$source.offset
      source_payload_sha256 = Get-FontQualificationSha256 -Bytes $sourcePayload
    })
  }

  $standaloneOracleBytes = [IO.File]::ReadAllBytes($OraclePath)
  Assert-ExactBytesIdentity `
    'standalone oracle' `
    $standaloneOracleBytes `
    $standaloneOracleBytes.Length `
    $StandaloneOracleSha256
  return [ordered]@{
    schema_version = '1.0.0'
    oracle = [ordered]@{
      implementation = 'mnf-powershell-closed-ttc-reader'
      version = '1.0.0'
      independence = 'offline parser; does not invoke tchivs/mb-font'
    }
    lineage = [ordered]@{
      source_path = 'fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf'
      source_length = $FontLength
      source_sha256 = $FontSha256
      source_archive = $ArchiveUrl
      source_retrieval_date = $RetrievalDate
      generator_path = 'scripts/fixtures/Generate-FontQualification.ps1'
      generator_identity = 'dejavu-two-face-exact-sharing-v1'
      generation_date = $CollectionGenerationDate
      author = 'DejaVu Fonts project; derived from Bitstream Vera and Arev'
      license = $UpstreamLicense
      redistribution_status = 'confirmed'
      notice_path = 'fixtures/font/dejavu-sans-2.37/LICENSE'
      notice_sha256 = $LicenseSha256
    }
    derivative = [ordered]@{
      path = 'fixtures/font/dejavu-sans-2.37/DejaVuSans-two-face-v1.ttc'
      length = $CollectionFontLength
      sha256 = $CollectionFontSha256
      signature = 'ttcf'
      version = '0x00010000'
      algorithm = 'dejavu-two-face-exact-sharing-v1'
    }
    collection = [ordered]@{
      face_count = 2
      face_offsets = @(20, 352)
      directory_length = 332
      payload_start = 684
      dsig_status = 'absent'
      profiles = @('StaticGlyf','StaticGlyf')
    }
    faces = @($faces)
    shared_tables = @($sharedTables)
    standalone_oracle_binding = [ordered]@{
      path = 'fixtures/font/dejavu-sans-2.37/oracle.json'
      sha256 = $StandaloneOracleSha256
      semantic_source = 'both selected faces use the standalone oracle; no target output is an oracle'
      face_indices = @(0, 1)
    }
  }
}

function Update-OrCheckFontCollectionArtifacts {
  param(
    [Parameter(Mandatory)]$CasesDocument,
    [Parameter(Mandatory)][byte[]]$TtcBytes,
    [Parameter(Mandatory)]$CollectionOracle,
    [switch]$CheckOnly
  )
  [void](Read-FontCollectionQualificationCases -Document $CasesDocument)
  $casesJson = ConvertTo-StableJson $CasesDocument
  $casesBytes = $Utf8NoBom.GetBytes($casesJson)
  $oracleJson = ConvertTo-StableJson $CollectionOracle
  $oracleBytes = $Utf8NoBom.GetBytes($oracleJson)
  if ($CheckOnly) {
    foreach ($item in @(
        [ordered]@{ path=$CollectionCasesPath; bytes=$casesBytes; label='collection cases' },
        [ordered]@{ path=$CollectionFontPath; bytes=$TtcBytes; label='collection TTC' },
        [ordered]@{ path=$CollectionOraclePath; bytes=$oracleBytes; label='collection oracle' }
      )) {
      if (-not (Test-Path -LiteralPath $item.path -PathType Leaf)) {
        throw "Font qualification $($item.label) artifact is missing: $($item.path)"
      }
      $actual = [IO.File]::ReadAllBytes($item.path)
      if (-not [Linq.Enumerable]::SequenceEqual(
          [byte[]]$item.bytes,
          [byte[]]$actual
        )) {
        throw "Font qualification $($item.label) artifact drifted: $($item.path)"
      }
    }
    return
  }
  # Every canonical and derived fact above is validated before the first write.
  [IO.File]::WriteAllBytes($CollectionCasesPath, $casesBytes)
  [IO.File]::WriteAllBytes($CollectionFontPath, $TtcBytes)
  [IO.File]::WriteAllBytes($CollectionOraclePath, $oracleBytes)
}

function Get-QualificationCasesManifestRecord {
  param([Parameter(Mandatory)][string]$Sha256)
  return [ordered]@{
    id = 'font-qualification-cases'
    path = 'fixtures/font/qualification-cases.json'
    origin = 'generated'
    source = 'repository-derived:scripts/fixtures/Generate-FontQualification.ps1'
    author = 'MoonBit Native Foundation project generator'
    retrieval_date = $RetrievalDate
    sha256 = $Sha256
    license = 'Apache-2.0'
    redistribution_status = 'not-applicable'
    expected_use = 'Phase 100 closed hostile-input and transactional font qualification matrix'
  }
}

function Update-OrCheckCasesManifest {
  param([switch]$CheckOnly)

  $casesBytes = [IO.File]::ReadAllBytes($CasesPath)
  $casesSha256 = Get-FontQualificationSha256 -Bytes $casesBytes
  $expected = Get-QualificationCasesManifestRecord -Sha256 $casesSha256
  $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
  $records = @($manifest.records)
  $matches = @($records | Where-Object id -CEQ $expected.id)
  if ($CheckOnly) {
    if ($matches.Count -ne 1 -or $records[$records.Count - 1].id -cne $expected.id) {
      throw 'Font qualification case manifest record is missing, duplicated, or reordered.'
    }
    Assert-ManifestRecord $records[$records.Count - 1] $expected
    return
  }
  if ($matches.Count -eq 0) {
    $manifest.records = @($records) + @($expected)
    [IO.File]::WriteAllText(
      $ManifestPath,
      (($manifest | ConvertTo-Json -Depth 30).Replace("`r`n", "`n") + "`n"),
      $Utf8NoBom
    )
    return
  }
  if ($matches.Count -ne 1 -or $records[$records.Count - 1].id -cne $expected.id) {
    throw 'Refusing duplicate or reordered font qualification case manifest record.'
  }
  foreach ($key in @($expected.Keys)) {
    $records[$records.Count - 1].$key = $expected[$key]
  }
  [IO.File]::WriteAllText(
    $ManifestPath,
    (($manifest | ConvertTo-Json -Depth 30).Replace("`r`n", "`n") + "`n"),
    $Utf8NoBom
  )
}

function Get-FontCollectionManifestRecords {
  $casesSha256 = Get-FontQualificationSha256 -Bytes (
    [IO.File]::ReadAllBytes($CollectionCasesPath)
  )
  $oracleSha256 = Get-FontQualificationSha256 -Bytes (
    [IO.File]::ReadAllBytes($CollectionOraclePath)
  )
  return @(
    [ordered]@{
      id = 'font-collection-qualification-cases'
      path = 'fixtures/font/collection-qualification-cases.json'
      origin = 'generated'
      source = 'repository-derived:scripts/fixtures/Generate-FontQualification.ps1'
      author = 'MoonBit Native Foundation project generator'
      retrieval_date = $CollectionGenerationDate
      sha256 = $casesSha256
      license = 'Apache-2.0'
      redistribution_status = 'not-applicable'
      expected_use = 'Phase 103 closed public, hostile, mutation, limit, caller-budget, and ancestor-budget collection qualification matrix'
    },
    [ordered]@{
      id = 'font-dejavu-sans-2.37-two-face-v1'
      path = 'fixtures/font/dejavu-sans-2.37/DejaVuSans-two-face-v1.ttc'
      origin = 'external'
      source = "$ArchiveUrl; parent=fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf@$FontSha256; generator=scripts/fixtures/Generate-FontQualification.ps1#dejavu-two-face-exact-sharing-v1; notice=fixtures/font/dejavu-sans-2.37/LICENSE@$LicenseSha256"
      author = 'DejaVu Fonts project; derived from Bitstream Vera and Arev'
      retrieval_date = $CollectionGenerationDate
      sha256 = $CollectionFontSha256
      license = $UpstreamLicense
      redistribution_status = 'confirmed'
      expected_use = 'Phase 103 qualification-only licensed two-face exact-sharing TTC v1 derivative'
    },
    [ordered]@{
      id = 'font-dejavu-sans-2.37-collection-oracle'
      path = 'fixtures/font/dejavu-sans-2.37/collection-oracle.json'
      origin = 'generated'
      source = "repository-derived:scripts/fixtures/Generate-FontQualification.ps1; derivative=$CollectionFontSha256; standalone-oracle=$StandaloneOracleSha256; metadata-only-no-payload-bytes"
      author = 'MoonBit Native Foundation project generator'
      retrieval_date = $CollectionGenerationDate
      sha256 = $oracleSha256
      license = 'Apache-2.0'
      redistribution_status = 'not-applicable'
      expected_use = 'Phase 103 independent metadata-only TTC structure, checksum, sharing, lineage, and standalone-oracle binding'
    }
  )
}

function Assert-FontCollectionManifestContract {
  $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
  $records = @($manifest.records)
  if ($records.Count -ne 14) {
    throw 'Font collection manifest records are missing, duplicated, or reordered.'
  }
  $prefixJson = ConvertTo-StableJson @($records[0..10])
  $prefixSha256 = Get-FontQualificationSha256 -Bytes $Utf8NoBom.GetBytes($prefixJson)
  if ($prefixSha256 -cne $PreCollectionManifestRecordsSha256) {
    throw 'Pre-Phase-103 manifest record order or values drifted.'
  }
  $expected = @(Get-FontCollectionManifestRecords)
  for ($index = 0; $index -lt $expected.Count; $index++) {
    Assert-ManifestRecord $records[11 + $index] $expected[$index]
  }
  if (@($records | Where-Object {
      $_.path -ceq 'fixtures/font/dejavu-sans-2.37/NOTICE'
    }).Count -ne 0) {
    throw 'Duplicate DejaVu NOTICE record is forbidden; the retained LICENSE is canonical.'
  }
}

function Assert-FontCollectionGeneratedSourceContract {
  if (-not (Test-Path -LiteralPath $GeneratedSourcePath -PathType Leaf)) {
    throw "Generated font qualification source is missing: $GeneratedSourcePath"
  }
  $source = [IO.File]::ReadAllText($GeneratedSourcePath, $Utf8NoBom)
  $lines = $source.Replace("`r`n", "`n").Split("`n")
  $expectedHeader = @(
    '// Generated by scripts/fixtures/Generate-FontQualification.ps1. Do not edit.',
    '// Canonical source: fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf',
    "// SHA-256: $FontSha256",
    "// Upstream license: $UpstreamLicense",
    "// Literal chunk size: $GeneratedChunkSize bytes"
  )
  if (($lines[0..4] -join "`0") -cne ($expectedHeader -join "`0")) {
    throw 'The first five generated DejaVu provenance lines drifted.'
  }
  if ([regex]::Matches(
      $source,
      '(?m)^fn _font_qualification_dejavu_chunk_[0-9]{3}\(\) -> Bytes \{$'
    ).Count -ne 185) {
    throw 'Generated source no longer has exactly one 185-chunk DejaVu literal representation.'
  }
  foreach ($symbol in @(
      'struct FontCollectionQualificationBudgetSnapshot',
      'struct FontCollectionQualificationError',
      'struct FontCollectionQualificationCase',
      'fn font_collection_qualification_cases()',
      'fn font_qualification_dejavu_two_face_ttc_v1_bytes()'
    )) {
    if (-not $source.Contains($symbol, [StringComparison]::Ordinal)) {
      throw "Generated font collection qualification symbol is missing: $symbol"
    }
  }
  if ($source -match '(?m)^\s*(?:let\s+)?(?:path|file|url)\s*=' -or
      $source -match '(?i)\b(?:filesystem|network|ffi|host-font)\b') {
    throw 'Generated collection mirror contains forbidden ambient runtime access.'
  }
}

function ConvertTo-MoonOptionalUInt64 {
  param($Value)
  if ($null -eq $Value) { return 'None' }
  return "Some($([uint64]$Value)UL)"
}

function ConvertTo-MoonDoubleLiteral {
  param([Parameter(Mandatory)][string]$Value)

  if ($Value -cnotmatch '^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?$') {
    throw "Malformed font qualification coordinate '$Value'."
  }
  $number = [double]::Parse(
    $Value,
    [Globalization.NumberStyles]::AllowLeadingSign -bor
      [Globalization.NumberStyles]::AllowDecimalPoint,
    [Globalization.CultureInfo]::InvariantCulture
  )
  $canonical = Format-FontQualificationCoordinate $number
  if ($canonical -cne $Value) {
    throw "Noncanonical font qualification coordinate '$Value'."
  }
  if ($canonical.Contains('.', [StringComparison]::Ordinal)) {
    return $canonical
  }
  return "$canonical.0"
}

function ConvertFrom-FontQualificationCommand {
  param([Parameter(Mandatory)][string]$Command)

  if ($Command -ceq 'Z') {
    return [ordered]@{
      kind = 'Z'
      x1 = '0.0'
      y1 = '0.0'
      x2 = '0.0'
      y2 = '0.0'
    }
  }
  $match = [regex]::Match(
    $Command,
    '^(?<kind>M|L):(?<x1>-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?),(?<y1>-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?)$',
    [Text.RegularExpressions.RegexOptions]::CultureInvariant
  )
  if ($match.Success) {
    return [ordered]@{
      kind = $match.Groups['kind'].Value
      x1 = ConvertTo-MoonDoubleLiteral $match.Groups['x1'].Value
      y1 = ConvertTo-MoonDoubleLiteral $match.Groups['y1'].Value
      x2 = '0.0'
      y2 = '0.0'
    }
  }
  $match = [regex]::Match(
    $Command,
    '^Q:(?<x1>-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?),(?<y1>-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?):(?<x2>-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?),(?<y2>-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?)$',
    [Text.RegularExpressions.RegexOptions]::CultureInvariant
  )
  if ($match.Success) {
    return [ordered]@{
      kind = 'Q'
      x1 = ConvertTo-MoonDoubleLiteral $match.Groups['x1'].Value
      y1 = ConvertTo-MoonDoubleLiteral $match.Groups['y1'].Value
      x2 = ConvertTo-MoonDoubleLiteral $match.Groups['x2'].Value
      y2 = ConvertTo-MoonDoubleLiteral $match.Groups['y2'].Value
    }
  }
  throw "Unsupported or malformed font qualification command '$Command'."
}

function Get-FontQualificationSupportedOutlines {
  param([Parameter(Mandatory)]$Oracle)

  $expected = @(
    [ordered]@{ scalar = 'U+0041'; scalar_value = 0x41UL; glyph_id = 36; command_count = 13 },
    [ordered]@{ scalar = 'U+034C'; scalar_value = 0x34CUL; glyph_id = 765; command_count = 48 },
    [ordered]@{ scalar = 'U+10300'; scalar_value = 0x10300UL; glyph_id = 5373; command_count = 13 }
  )
  $supported = [Collections.Generic.List[object]]::new()
  foreach ($item in $expected) {
    $matches = @($Oracle.glyphs | Where-Object { $_.scalar -ceq $item.scalar })
    if ($matches.Count -ne 1) {
      throw "Independent oracle supported glyph $($item.scalar) is missing or duplicated."
    }
    $glyph = $matches[0]
    $commands = @($glyph.path.commands)
    if ([int]$glyph.glyph_id -ne [int]$item.glyph_id -or
        [int]$glyph.path.command_count -ne [int]$item.command_count -or
        $commands.Count -ne [int]$item.command_count) {
      throw "Independent oracle supported glyph $($item.scalar) identity or command count drifted."
    }
    $fingerprint = Get-FontQualificationSha256 -Bytes $Utf8NoBom.GetBytes(
      $commands -join '|'
    )
    if ([string]::IsNullOrWhiteSpace([string]$glyph.path.fingerprint_sha256) -or
        $fingerprint -cne [string]$glyph.path.fingerprint_sha256) {
      throw "Independent oracle supported glyph $($item.scalar) fingerprint drifted."
    }
    $structured = @(
      foreach ($command in $commands) {
        ConvertFrom-FontQualificationCommand -Command ([string]$command)
      }
    )
    $supported.Add([ordered]@{
      scalar = $item.scalar
      scalar_value = [uint64]$item.scalar_value
      glyph_id = [int]$item.glyph_id
      fingerprint_sha256 = [string]$glyph.path.fingerprint_sha256
      commands = $structured
    })
  }
  return @($supported)
}

function Write-FontQualificationGeneratedSource {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][byte[]]$FontBytes,
    [Parameter(Mandatory)]$Oracle,
    [Parameter(Mandatory)]$CasesDocument,
    [switch]$CheckOnly
  )

  Assert-ExactBytesIdentity 'generated DejaVu source' $FontBytes $FontLength $FontSha256
  $supportedOutlines = @(Get-FontQualificationSupportedOutlines -Oracle $Oracle)
  $rows = [Collections.Generic.List[string]]::new()
  $rows.Add('// Generated by scripts/fixtures/Generate-FontQualification.ps1. Do not edit.')
  $rows.Add('// Canonical source: fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf')
  $rows.Add("// SHA-256: $FontSha256")
  $rows.Add("// Upstream license: $UpstreamLicense")
  $rows.Add("// Literal chunk size: $GeneratedChunkSize bytes")
  $rows.Add('')
  $rows.Add('///|')
  $rows.Add('struct FontQualificationCase {')
  $rows.Add('  id : String')
  $rows.Add('  stage : String')
  $rows.Add('  category : String')
  $rows.Add('  code : String')
  $rows.Add('  context : String')
  $rows.Add('  requested : UInt64?')
  $rows.Add('  limit : UInt64?')
  $rows.Add('  publication : String')
  $rows.Add('}')
  $rows.Add('')
  $rows.Add('///|')
  $rows.Add('struct FontQualificationExpectedCommand {')
  $rows.Add('  kind : String')
  $rows.Add('  x1 : Double')
  $rows.Add('  y1 : Double')
  $rows.Add('  x2 : Double')
  $rows.Add('  y2 : Double')
  $rows.Add('}')
  $rows.Add('')
  $rows.Add('///|')
  $rows.Add('struct FontQualificationOutlineExpectation {')
  $rows.Add('  scalar : Int')
  $rows.Add('  glyph_id : UInt64')
  $rows.Add('  fingerprint_sha256 : String')
  $rows.Add('  commands : Array[FontQualificationExpectedCommand]')
  $rows.Add('}')
  $rows.Add('')
  $rows.Add('///|')
  $rows.Add('fn _font_qualification_join_bytes(parts : Array[Bytes]) -> Bytes {')
  $rows.Add('  let mut capacity = 0')
  $rows.Add('  for part in parts {')
  $rows.Add('    capacity += part.length()')
  $rows.Add('  }')
  $rows.Add('  let output : Array[Byte] = Array::new(capacity~)')
  $rows.Add('  for part in parts {')
  $rows.Add('    output.push_iter(part.iter())')
  $rows.Add('  }')
  $rows.Add('  Bytes::from_array(output)')
  $rows.Add('}')
  $rows.Add('')

  $rows.Add('///|')
  $rows.Add('fn font_qualification_dejavu_supported_outlines() -> Array[FontQualificationOutlineExpectation] {')
  $rows.Add('  [')
  foreach ($outline in $supportedOutlines) {
    $rows.Add('    {')
    $rows.Add(('      scalar: 0x{0:x},' -f [uint64]$outline.scalar_value))
    $rows.Add("      glyph_id: $([uint64]$outline.glyph_id)UL,")
    $rows.Add("      fingerprint_sha256: `"$($outline.fingerprint_sha256)`",")
    $rows.Add('      commands: [')
    foreach ($command in @($outline.commands)) {
      $rows.Add('        {')
      $rows.Add("          kind: `"$($command.kind)`",")
      $rows.Add("          x1: $($command.x1),")
      $rows.Add("          y1: $($command.y1),")
      $rows.Add("          x2: $($command.x2),")
      $rows.Add("          y2: $($command.y2),")
      $rows.Add('        },')
    }
    $rows.Add('      ],')
    $rows.Add('    },')
  }
  $rows.Add('  ]')
  $rows.Add('}')
  $rows.Add('')

  $chunkLiterals = [Collections.Generic.List[string]]::new()
  $chunkCount = [Math]::Ceiling($FontBytes.Length / [double]$GeneratedChunkSize)
  for ($chunk = 0; $chunk -lt $chunkCount; $chunk++) {
    $start = $chunk * $GeneratedChunkSize
    $length = [Math]::Min($GeneratedChunkSize, $FontBytes.Length - $start)
    $builder = [Text.StringBuilder]::new($length * 4)
    for ($index = 0; $index -lt $length; $index++) {
      [void]$builder.AppendFormat('\x{0:x2}', $FontBytes[$start + $index])
    }
    $literal = $builder.ToString()
    $chunkLiterals.Add($literal)
    $rows.Add('///|')
    $rows.Add(('fn _font_qualification_dejavu_chunk_{0:d3}() -> Bytes {{' -f $chunk))
    $rows.Add(('  b"{0}"' -f $literal))
    $rows.Add('}')
    $rows.Add('')
  }

  $roundTrip = [Collections.Generic.List[byte]]::new($FontBytes.Length)
  foreach ($literal in $chunkLiterals) {
    $matches = [regex]::Matches($literal, '\\x(?<hex>[0-9a-f]{2})')
    foreach ($match in $matches) {
      $roundTrip.Add([Convert]::ToByte($match.Groups['hex'].Value, 16))
    }
  }
  $roundTripBytes = $roundTrip.ToArray()
  Assert-ExactBytesIdentity 'rendered DejaVu literals' $roundTripBytes $FontLength $FontSha256
  if (-not [Linq.Enumerable]::SequenceEqual(
      [byte[]]$FontBytes,
      [byte[]]$roundTripBytes
    )) {
    throw 'Rendered DejaVu literal round-trip differs from canonical bytes.'
  }

  $rows.Add('///|')
  $rows.Add('fn font_qualification_dejavu_sans_237_bytes() -> Bytes {')
  $rows.Add('  _font_qualification_join_bytes([')
  for ($chunk = 0; $chunk -lt $chunkCount; $chunk++) {
    $rows.Add(('    _font_qualification_dejavu_chunk_{0:d3}(),' -f $chunk))
  }
  $rows.Add('  ])')
  $rows.Add('}')
  $rows.Add('')

  $rows.Add('///|')
  $rows.Add('fn font_qualification_compact_bytes() -> Bytes {')
  $rows.Add('  let simple = b"\x00\x01\x00\x00\x00\x00\x00\x64\x00\x64\x00\x04\x00\x00\x31\x3a\x01\x35\x23\x32\x32\x64\x64"')
  $rows.Add('  let first = font_test_component_record(0x002BUL, 1UL, 10, -4, [8192])')
  $rows.Add('  let second = font_test_component_record(0x0009UL, 1UL, 3, 0, [8192])')
  $rows.Add('  let composite = font_test_composite_glyph([first, second])')
  $rows.Add('  let glyphs = [b"", simple, composite]')
  $rows.Add('  let glyf : Array[Byte] = []')
  $rows.Add('  let loca : Array[Byte] = []')
  $rows.Add('  font_test_push_u16(loca, 0UL)')
  $rows.Add('  for glyph in glyphs {')
  $rows.Add('    glyf.push_iter(glyph.iter())')
  $rows.Add('    if glyph.length() % 2 != 0 {')
  $rows.Add('      glyf.push(b''\x00'')')
  $rows.Add('    }')
  $rows.Add('    font_test_push_u16(loca, glyf.length().to_uint64() / 2UL)')
  $rows.Add('  }')
  $rows.Add('  let hmtx : Array[Byte] = [b''\x01'', b''\xf4'', b''\x00'', b''\x00'', b''\x00'', b''\x00'', b''\x00'', b''\x00'']')
  $rows.Add('  let maxp = font_test_maxp_table_with_glyphs(3UL).to_array()')
  $rows.Add('  font_test_put_u16(maxp, 28, 16UL)')
  $rows.Add('  font_test_put_u16(maxp, 30, 1UL)')
  $rows.Add('  let cmap = font_test_cmap_records(')
  $rows.Add('    [(0UL, 4UL, 0)],')
  $rows.Add('    [font_test_cmap_subtable(font_test_cmap_format12([')
  $rows.Add('      (0x0041UL, 0x0041UL, 1UL),')
  $rows.Add('      (0x10300UL, 0x10300UL, 2UL),')
  $rows.Add('    ]))],')
  $rows.Add('  )')
  $rows.Add('  font_test_build_truetype([')
  $rows.Add('    { tag: b"OS/2", payload: font_test_fixed_table(78) },')
  $rows.Add('    { tag: b"cmap", payload: cmap },')
  $rows.Add('    { tag: b"glyf", payload: Bytes::from_array(glyf) },')
  $rows.Add('    { tag: b"head", payload: font_test_head_table() },')
  $rows.Add('    { tag: b"hhea", payload: font_test_hhea_table() },')
  $rows.Add('    { tag: b"hmtx", payload: Bytes::from_array(hmtx) },')
  $rows.Add('    { tag: b"kern", payload: font_test_kern_format0([(1UL, 2UL, -37)]) },')
  $rows.Add('    { tag: b"loca", payload: Bytes::from_array(loca) },')
  $rows.Add('    { tag: b"maxp", payload: Bytes::from_array(maxp) },')
  $rows.Add('    { tag: b"name", payload: font_test_name_table() },')
  $rows.Add('    { tag: b"post", payload: font_test_post_table() },')
  $rows.Add('  ])')
  $rows.Add('}')
  $rows.Add('')

  $rows.Add('///|')
  $rows.Add('fn font_qualification_cases() -> Array[FontQualificationCase] {')
  $rows.Add('  [')
  foreach ($case in @($CasesDocument.cases)) {
    $rows.Add('    {')
    $rows.Add("      id: `"$($case.id)`",")
    $rows.Add("      stage: `"$($case.stage)`",")
    $rows.Add("      category: `"$($case.category)`",")
    $rows.Add("      code: `"$($case.code)`",")
    $rows.Add("      context: `"$($case.context)`",")
    $rows.Add("      requested: $(ConvertTo-MoonOptionalUInt64 $case.requested),")
    $rows.Add("      limit: $(ConvertTo-MoonOptionalUInt64 $case.limit),")
    $rows.Add("      publication: `"$($case.publication)`",")
    $rows.Add('    },')
  }
  $rows.Add('  ]')
  $rows.Add('}')
  $rows.Add('')

  $rendered = ($rows -join "`n")
  $renderedBytes = $Utf8NoBom.GetBytes($rendered)
  if ($CheckOnly) {
    if (-not (Test-Path -LiteralPath $GeneratedSourcePath -PathType Leaf)) {
      throw "Generated font qualification source is missing: $GeneratedSourcePath"
    }
    $actualBytes = [IO.File]::ReadAllBytes($GeneratedSourcePath)
    if (-not [Linq.Enumerable]::SequenceEqual(
        [byte[]]$renderedBytes,
        [byte[]]$actualBytes
      )) {
      throw "Generated font qualification source drifted: $GeneratedSourcePath"
    }
    return
  }
  [IO.File]::WriteAllBytes($GeneratedSourcePath, $renderedBytes)
}

function Test-FontQualificationInputs {
  param([Parameter(Mandatory)]$Oracle)

  foreach ($path in @($FontPath, $LicensePath, $OraclePath, $ManifestPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw "Font qualification input is missing: $path"
    }
  }
  $fontBytes = [IO.File]::ReadAllBytes($FontPath)
  $licenseBytes = [IO.File]::ReadAllBytes($LicensePath)
  Assert-ExactBytesIdentity 'DejaVuSans.ttf' $fontBytes $FontLength $FontSha256
  Assert-ExactBytesIdentity 'DejaVu LICENSE' $licenseBytes $LicenseLength $LicenseSha256
  $expectedOracle = ConvertTo-StableJson $Oracle
  $actualOracle = [IO.File]::ReadAllText($OraclePath, $Utf8NoBom).Replace("`r`n", "`n")
  if ($actualOracle -cne $expectedOracle) {
    throw 'Independent oracle schema, keys, facts, or serialization drifted.'
  }
  Update-OrCheckManifest -CheckOnly
}

if ($Intake -and $Check) {
  throw '-Intake and -Check are mutually exclusive.'
}
if ($Intake) {
  Invoke-FontQualificationIntake
}
$fontBytes = [IO.File]::ReadAllBytes($FontPath)
$oracle = Read-FontQualificationSfntOracle -Bytes $fontBytes
if (-not $Check) {
  [IO.File]::WriteAllText($OraclePath, (ConvertTo-StableJson $oracle), $Utf8NoBom)
}
Test-FontQualificationInputs -Oracle $oracle
$casesDocument = Read-FontQualificationCases
$expectedCollectionCases = New-FontCollectionQualificationCases
$collectionTtcBytes = New-FontQualificationDejaVuTtc -FontBytes $fontBytes
$collectionOracle = Read-FontQualificationTtcOracle `
  -TtcBytes $collectionTtcBytes `
  -FontBytes $fontBytes `
  -StandaloneOracle $oracle
Update-OrCheckFontCollectionArtifacts `
  -CasesDocument $expectedCollectionCases `
  -TtcBytes $collectionTtcBytes `
  -CollectionOracle $collectionOracle `
  -CheckOnly:$Check
$collectionCasesDocument = Read-FontCollectionQualificationCases
Assert-FontCollectionManifestContract
Assert-FontCollectionGeneratedSourceContract
if ($Check) {
  Update-OrCheckCasesManifest -CheckOnly
  Write-FontQualificationGeneratedSource `
    -FontBytes $fontBytes `
    -Oracle $oracle `
    -CasesDocument $casesDocument `
    -CheckOnly
} else {
  Update-OrCheckCasesManifest
  Write-FontQualificationGeneratedSource `
    -FontBytes $fontBytes `
    -Oracle $oracle `
    -CasesDocument $casesDocument
}
Write-Host 'Font qualification intake, oracle, hostile matrix, and generated source verification passed.'
