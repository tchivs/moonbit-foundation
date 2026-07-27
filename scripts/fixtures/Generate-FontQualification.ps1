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
$ManifestPath = Join-Path $RepositoryRoot 'fixtures/manifest.json'

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

function Get-FontQualificationSha256 {
  [CmdletBinding()]
  param([Parameter(Mandatory)][byte[]]$Bytes)

  return [Convert]::ToHexString(
    [System.Security.Cryptography.SHA256]::HashData($Bytes)
  ).ToLowerInvariant()
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
      $arg1 = [sbyte]$Glyf[$offset]
      $arg2 = [sbyte]$Glyf[$offset + 1]
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
      $startX = [int](($first.x + $last.x) / 2)
      $startY = [int](($first.y + $last.y) / 2)
      $index = $contourStart
    }
    $commands.Add("M:$startX,$startY")
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
          $midX = [int](($control.x + $point.x) / 2)
          $midY = [int](($control.y + $point.y) / 2)
          $commands.Add("Q:$($control.x),$($control.y):$midX,$midY")
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
        selected_commands = @($commands | Select-Object -First 8)
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
    schema_version = '1.0.0'
    oracle = [ordered]@{
      implementation = 'mnf-powershell-closed-sfnt-reader'
      version = '1.0.0'
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
  if ($CheckOnly) {
    if ($matches.Count -ne 2 -or $existing.Count -lt 2) {
      throw 'DejaVu manifest records are missing or duplicated.'
    }
    if ($existing[$existing.Count - 2].id -cne $expected[0].id -or
        $existing[$existing.Count - 1].id -cne $expected[1].id) {
      throw 'DejaVu manifest records must be the final two records in canonical order.'
    }
    Assert-ManifestRecord $existing[$existing.Count - 2] $expected[0]
    Assert-ManifestRecord $existing[$existing.Count - 1] $expected[1]
    return
  }
  if ($matches.Count -eq 2 -and
      $existing[$existing.Count - 2].id -ceq $expected[0].id -and
      $existing[$existing.Count - 1].id -ceq $expected[1].id) {
    Assert-ManifestRecord $existing[$existing.Count - 2] $expected[0]
    Assert-ManifestRecord $existing[$existing.Count - 1] $expected[1]
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

function Test-FontQualificationInputs {
  foreach ($path in @($FontPath, $LicensePath, $OraclePath, $ManifestPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw "Font qualification input is missing: $path"
    }
  }
  $fontBytes = [IO.File]::ReadAllBytes($FontPath)
  $licenseBytes = [IO.File]::ReadAllBytes($LicensePath)
  Assert-ExactBytesIdentity 'DejaVuSans.ttf' $fontBytes $FontLength $FontSha256
  Assert-ExactBytesIdentity 'DejaVu LICENSE' $licenseBytes $LicenseLength $LicenseSha256
  $expectedOracle = ConvertTo-StableJson (
    Read-FontQualificationSfntOracle -Bytes $fontBytes
  )
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
Test-FontQualificationInputs
Write-Host 'Font qualification intake and independent oracle verification passed.'
