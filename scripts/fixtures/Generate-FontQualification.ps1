[CmdletBinding()]
param(
  [switch]$Intake,
  [switch]$Check,
  [switch]$CheckGeneratedTracer,
  [switch]$CheckContracts,
  [switch]$CheckGeneratedRecipes,
  [switch]$CheckOracleAdapters,
  [switch]$CheckSchemaNegatives,
  [switch]$CheckHostileInventory,
  [switch]$CheckOutcomeTrace,
  [switch]$CheckBoundaryApplicability,
  [switch]$CheckIntakeContract,
  [switch]$CheckIntakeNegatives,
  [switch]$CheckLicensedIntake,
  [switch]$CheckOracleAgreement,
  [switch]$CheckProvenance,
  [switch]$CheckEvidencePackage,
  [switch]$CheckPublicPrivateBoundary,
  [ValidateSet('js', 'wasm', 'wasm-gc', 'native')]
  [string]$Target = 'native',
  [string]$ExecutionHandoffPath,
  [string]$ProvisionedToolsRoot
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
$CffQualificationCasesPath = Join-Path $RepositoryRoot 'fixtures/font/cff-qualification-cases.json'
$CffOracleToolsPath = Join-Path $RepositoryRoot 'fixtures/font/cff-oracle-tools.json'
$CffHostLockPath = Join-Path $RepositoryRoot 'fixtures/font/cff/host-toolchain.lock.json'
$CffFontToolsAdapterPath = Join-Path $RepositoryRoot 'scripts/fixtures/oracles/fonttools_cff_oracle.py'
$CffAfdkoAdapterPath = Join-Path $RepositoryRoot 'scripts/fixtures/oracles/Invoke-AfdkoCffOracle.ps1'
$CffExecutionHandoffRelativePath =
  'artifacts/release-qualification/phase-107/107-01-host-toolchain-handoff.json'
$CffExecutionHandoffSha256 =
  '340e878b488ae3bec90a6b55c380d85cd33673611ce5258c4291d46ffc45dc3e'
$CffExecutionHandoffSchema = 'mnf-phase107-host-toolchain-handoff/1.0.0'
$CffLicensedRetrievalDate = '2026-07-29'
$CffLicensedFixtureRoot = Join-Path $RepositoryRoot 'fixtures/font'
$CffEvidenceRoot = Join-Path $RepositoryRoot 'benchmarks/font-cff'
$CffEvidenceManifestPath = Join-Path $CffEvidenceRoot 'moon.mod.json'
$CffEvidencePackagePath = Join-Path $CffEvidenceRoot 'moon.pkg'
$CffEvidenceWbtestPath = Join-Path $CffEvidenceRoot 'cff_qualification_wbtest.mbt'
$CffCoreManifestPath = Join-Path $RepositoryRoot 'modules/mb-core/moon.mod.json'
$CffFontManifestPath = Join-Path $RepositoryRoot 'modules/mb-font/moon.mod.json'
$CffCoreManifestSha256 =
  '70f253dec675d8309783bdcc7864faa65d1a5805179e68256ef67bba3d89862e'
$CffFontManifestSha256 =
  'c93c8d1390088b5eb877b00fef9de060e5370953d4b85f098a8e0f60cd4c868b'
$CffFontPublicInterfaceSha256 =
  '59dd433ea85f4169d87d59bc5b4416564f32317656bca8ad987efce74c1b9153'

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

$CffGeneratedTracerBase64 = 'T1RUTwAJAIAAAwAQQ0ZGIEfWkL4AAALQAAAAkE9TLzJFIUQbAAABAAAAAGBjbWFwAAwAlQAAAnwAAAA0aGVhZGE8Qx8AAACcAAAANmhoZWEFSAIMAAAA1AAAACRobXR4BrgAlgAAA2AAAAAMbWF4cAADUAAAAAD4AAAABm5hbWWS/b0oAAABYAAAARpwb3N0AAMAAAAAArAAAAAgAAEAAAABAADMU4v3Xw889QADA+gAAAAAAAAAAAAAAAAAAAAAADIAAAH0Aj8AAAADAAIAAAAAAAAAAQAAAyD/OAAAAmwAMgBkAfQAAQAAAAAAAAAAAAAAAAAAAAMAAFAAAAMAAAADAj0BkAAFAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAA/Pz8/AAAAQQBCAyD/OAAAAyAAyAAAAAAAAAAAAAAAAAAAACAAAAAAAAoAfgABAAAAAAABAAoAAAABAAAAAAACAAcACgABAAAAAAADABEAEQABAAAAAAAEABIAIgABAAAAAAAGABEAEQADAAEECQABABQANAADAAEECQACAA4ASAADAAEECQADACIAVgADAAEECQAEACQAeAADAAEECQAGACIAVk1ORiBUcmFjZXJSZWd1bGFyTU5GVHJhY2VyLVJlZ3VsYXJNTkYgVHJhY2VyIFJlZ3VsYXIATQBOAEYAIABUAHIAYQBjAGUAcgBSAGUAZwB1AGwAYQByAE0ATgBGAFQAcgBhAGMAZQByAC0AUgBlAGcAdQBsAGEAcgBNAE4ARgAgAFQAcgBhAGMAZQByACAAUgBlAGcAdQBsAGEAcgAAAAAAAgAAAAMAAAAUAAMAAQAAABQABAAgAAAABAAEAAEAAABC//8AAABB////wAABAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAEAQABAQESTU5GVHJhY2VyLVJlZ3VsYXIAAQEBGfgbAvgcA/gYBL2L+Ij40wXmD4v3JBLqEQACAQETHU1ORiBUcmFjZXIgUmVndWxhck1ORiBUcmFjZXIAAAEAIgEAAwEBAxUriw6L7xbv+IgFve/vi70n7/yIGA6LvRb4iAf3jov7jvuO98CL+477wBsOAfQAAAJYAGQCbAAy'
$CffGeneratedTracerLength = 876L
$CffGeneratedTracerSha256 = 'aa44c7ced50fa71660d76e8a456a301a404d2b1d5e34ea0099a849b876083d5d'

function Get-FontQualificationSha256 {
  [CmdletBinding()]
  param([Parameter(Mandatory)][byte[]]$Bytes)

  return [Convert]::ToHexString(
    [System.Security.Cryptography.SHA256]::HashData($Bytes)
  ).ToLowerInvariant()
}

function Invoke-CffGeneratedTracerCheck {
  if (-not $ExecutionHandoffPath) {
    throw '-ExecutionHandoffPath is required for -CheckGeneratedTracer.'
  }
  if (-not $ProvisionedToolsRoot) {
    throw '-ProvisionedToolsRoot is required for -CheckGeneratedTracer.'
  }
  $handoffPath = if ([IO.Path]::IsPathFullyQualified($ExecutionHandoffPath)) {
    [IO.Path]::GetFullPath($ExecutionHandoffPath)
  } else {
    [IO.Path]::GetFullPath((Join-Path $RepositoryRoot $ExecutionHandoffPath))
  }
  if (-not (Test-Path -LiteralPath $handoffPath -PathType Leaf)) {
    throw 'CFF generated tracer handoff is missing.'
  }
  $handoff = Get-Content -Raw -LiteralPath $handoffPath | ConvertFrom-Json
  if ($handoff.schema -cne 'mnf-phase107-host-toolchain-handoff/1.0.0' -or
      $handoff.preflight_validated -ne $true -or
      $handoff.provisioning_validated -ne $true) {
    throw 'CFF generated tracer handoff is not fully validated.'
  }
  $provisionedRoot = (Resolve-Path -LiteralPath $ProvisionedToolsRoot).Path
  if ($provisionedRoot -cne [string]$handoff.provisioned_tools_root) {
    throw 'CFF generated tracer provisioned root differs from the handoff.'
  }
  $provisionedPath = Join-Path $provisionedRoot 'provisioned-tools.json'
  $provisioned = Get-Content -Raw -LiteralPath $provisionedPath | ConvertFrom-Json
  if ($provisioned.schema -cne 'cff-provisioned-tools/1.0.0' -or
      $provisioned.provisioning_validated -ne $true -or
      $provisioned.invoked_identities_sha256 -cne $handoff.invoked_identities_sha256) {
    throw 'CFF generated tracer provisioned-tool identity drifted.'
  }
  if ((Get-FileHash -Algorithm SHA256 -LiteralPath $CffFontToolsAdapterPath).Hash.ToLowerInvariant() -cne
        [string]$handoff.adapter_sha256.fonttools -or
      (Get-FileHash -Algorithm SHA256 -LiteralPath $CffAfdkoAdapterPath).Hash.ToLowerInvariant() -cne
        [string]$handoff.adapter_sha256.afdko) {
    throw 'CFF generated tracer adapter digest drifted.'
  }

  $tracerPath = Join-Path $provisionedRoot 'generated-name-tracer.otf'
  $tracerBytes = [Convert]::FromBase64String($CffGeneratedTracerBase64)
  if ($tracerBytes.LongLength -ne $CffGeneratedTracerLength -or
      (Get-FontQualificationSha256 $tracerBytes) -cne $CffGeneratedTracerSha256) {
    throw 'Hand-derived CFF generated tracer identity drifted.'
  }
  [IO.File]::WriteAllBytes($tracerPath, $tracerBytes)

  $pythonPath = @($provisioned.invoked_identities |
    Where-Object { $_.id -ceq 'runtime.cpython' })[0].path
  $fontToolsJson = & $pythonPath $CffFontToolsAdapterPath `
    --site-root $provisioned.fonttools_site_root `
    --font $tracerPath `
    --scalar U+0041
  if ($LASTEXITCODE -ne 0) { throw 'Pinned fontTools reader failed.' }
  $fontTools = $fontToolsJson | ConvertFrom-Json
  $afdkoJson = & $CffAfdkoAdapterPath `
    -PythonPath $pythonPath `
    -AfdkoSiteRoot $provisioned.afdko_site_root `
    -TxRunnerPath $provisioned.tx_runner_path `
    -FontPath $tracerPath `
    -Scalar U+0041
  $afdko = $afdkoJson | ConvertFrom-Json

  function Get-CffSemanticProjection {
    param([Parameter(Mandatory)]$Value)
    return [ordered]@{
      schema = $Value.schema
      source_sha256 = $Value.source_sha256
      face_index = $Value.face_index
      scalar = $Value.scalar
      glyph_name = $Value.glyph_name
      gid = $Value.gid
      advance = $Value.advance
      lsb = $Value.lsb
      bounds = @($Value.bounds)
      commands = @($Value.commands)
      cff_profile = $Value.cff_profile
      keying = $Value.keying
    }
  }

  $fontToolsProjection = Get-CffSemanticProjection $fontTools
  $afdkoProjection = Get-CffSemanticProjection $afdko
  $fontToolsCanonical = $fontToolsProjection | ConvertTo-Json -Depth 10 -Compress
  $afdkoCanonical = $afdkoProjection | ConvertTo-Json -Depth 10 -Compress
  if ($fontToolsCanonical -cne $afdkoCanonical) {
    throw "Independent CFF semantic readers disagree.`nfontTools=$fontToolsCanonical`nAFDKO=$afdkoCanonical"
  }
  $expected = [ordered]@{
    schema = 'cff-semantic-reader/1.0.0'
    source_sha256 = $CffGeneratedTracerSha256
    face_index = 0
    scalar = 'U+0041'
    glyph_name = 'A'
    gid = 1
    advance = 600
    lsb = 100
    bounds = @(100, 0, 500, 575)
    commands = @(
      [ordered]@{ op='MoveTo'; points=@(100, 0) },
      [ordered]@{ op='LineTo'; points=@(200, 500) },
      [ordered]@{ op='CubicTo'; points=@(250, 600, 350, 600, 400, 500) },
      [ordered]@{ op='LineTo'; points=@(500, 0) },
      [ordered]@{ op='Close'; points=@() }
    )
    cff_profile = 'CFF1'
    keying = 'name'
  }
  $expectedCanonical = $expected | ConvertTo-Json -Depth 10 -Compress
  if ($fontToolsCanonical -cne $expectedCanonical) {
    throw "Generated CFF tracer differs from hand-derived facts.`n$fontToolsCanonical"
  }

  $disagreement = $afdkoProjection | ConvertTo-Json -Depth 10 | ConvertFrom-Json
  $disagreement.advance = 601
  if ((Get-CffSemanticProjection $disagreement | ConvertTo-Json -Depth 10 -Compress) -ceq
      $fontToolsCanonical) {
    throw 'Reader-disagreement negative did not fail.'
  }

  $hostManifest = Get-Content -Raw -LiteralPath $handoff.manifest_path | ConvertFrom-Json
  $otsOutput = Join-Path $provisionedRoot 'generated-name-tracer-sanitized.otf'
  $oldPath = $env:PATH
  try {
    $env:PATH = @($hostManifest.sanitized_environment.PATH) -join ';'
    $otsLog = & $provisioned.ots_sanitize_path $tracerPath $otsOutput 2>&1
    if ($LASTEXITCODE -ne 0 -or
        -not (Test-Path -LiteralPath $otsOutput -PathType Leaf)) {
      throw "OTS structural acceptance failed: $($otsLog -join "`n")"
    }
  } finally {
    $env:PATH = $oldPath
  }
  Write-Host 'Generated CFF tracer passed two independent readers and OTS structural acceptance.'
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

function Assert-CffQualificationCanonicalJson {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "$Label is missing: $Path"
  }
  $bytes = [IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -lt 2 -or
      ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and
        $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) {
    throw "$Label must be nonempty UTF-8 without BOM."
  }
  $strictUtf8 = [Text.UTF8Encoding]::new($false, $true)
  $text = $strictUtf8.GetString($bytes)
  if ($text.Contains("`r") -or -not $text.EndsWith("`n") -or
      $text.EndsWith("`n`n")) {
    throw "$Label must use canonical LF with exactly one final newline."
  }
  if (-not [Linq.Enumerable]::SequenceEqual(
      [byte[]]$bytes,
      [byte[]]$strictUtf8.GetBytes($text)
    )) {
    throw "$Label is not byte-canonical UTF-8."
  }
}

function Assert-CffQualificationOrderedValues {
  param(
    [Parameter(Mandatory)][object[]]$Actual,
    [Parameter(Mandatory)][object[]]$Expected,
    [Parameter(Mandatory)][string]$Label
  )

  if (($Actual -join "`0") -cne ($Expected -join "`0")) {
    throw "$Label membership or order drifted."
  }
}

function Assert-CffQualificationSha256 {
  param(
    [AllowNull()][string]$Value,
    [Parameter(Mandatory)][string]$Label
  )

  if ($Value -cnotmatch '^[0-9a-f]{64}$') {
    throw "$Label is not a lowercase SHA-256."
  }
}

function Get-CffQualificationTextSha256 {
  param([Parameter(Mandatory)][string]$Text)
  return Get-FontQualificationSha256 -Bytes $Utf8NoBom.GetBytes($Text)
}

function Read-CffQualificationJson {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Label
  )

  Assert-CffQualificationCanonicalJson $Path $Label
  return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

function Assert-CffOracleToolsDocument {
  param([Parameter(Mandatory)]$Document)

  Assert-FontQualificationOrderedKeys $Document @(
    'schema','caller','packages','sources','invoked_identities',
    'invoked_identities_sha256','adapters','structural_reader','independence',
    'provisioning_validated'
  ) 'CFF oracle tools'
  if ($Document.schema -cne 'cff-oracle-tools/1.0.0' -or
      $Document.provisioning_validated -ne $true) {
    throw 'CFF oracle tools header drifted.'
  }

  Assert-FontQualificationOrderedKeys $Document.caller @(
    'manifest_schema','manifest_sha256','sdk_inventory_sha256','lock_sha256'
  ) 'CFF oracle caller'
  $lock = Get-Content -Raw -LiteralPath $CffHostLockPath | ConvertFrom-Json
  if ($Document.caller.manifest_schema -cne $lock.approved_manifest_schema -or
      $Document.caller.manifest_sha256 -cne $lock.approved_manifest_sha256 -or
      $Document.caller.sdk_inventory_sha256 -cne $lock.sdk_inventory_sha256 -or
      $Document.caller.lock_sha256 -cne
        (Get-FontQualificationSha256 -Bytes ([IO.File]::ReadAllBytes($CffHostLockPath)))) {
    throw 'CFF oracle caller digest set drifted.'
  }
  foreach ($name in @('manifest_sha256','sdk_inventory_sha256','lock_sha256')) {
    Assert-CffQualificationSha256 ([string]$Document.caller.$name) "CFF oracle caller $name"
  }

  $packages = @($Document.packages)
  Assert-CffQualificationOrderedValues @($packages.id) @('fonttools','afdko') 'CFF semantic packages'
  if ($packages.Count -ne @($lock.semantic_readers).Count) {
    throw 'CFF semantic package cardinality drifted.'
  }
  for ($index = 0; $index -lt $packages.Count; $index++) {
    $package = $packages[$index]
    $locked = $lock.semantic_readers[$index]
    Assert-FontQualificationOrderedKeys $package @(
      'id','version','role','url','length','sha256'
    ) "CFF semantic package $index"
    foreach ($name in @('id','version','role','url','length','sha256')) {
      if ([string]$package.$name -cne [string]$locked.$name) {
        throw "CFF semantic package $index $name drifted."
      }
    }
    Assert-CffQualificationSha256 ([string]$package.sha256) "CFF semantic package $index"
  }

  $sources = @($Document.sources)
  if ($sources.Count -ne 1) { throw 'Exactly one structural CFF reader source is required.' }
  Assert-FontQualificationOrderedKeys $sources[0] @(
    'id','revision','role','url','length','sha256'
  ) 'CFF structural source'
  $structural = $lock.structural_reader
  foreach ($pair in @(
      @('id','id'), @('revision','commit'), @('role','role'), @('url','url'),
      @('length','length'), @('sha256','sha256')
    )) {
    if ([string]$sources[0].($pair[0]) -cne [string]$structural.($pair[1])) {
      throw "CFF structural source $($pair[0]) drifted."
    }
  }

  $invoked = @($Document.invoked_identities)
  Assert-CffQualificationOrderedValues @($invoked.id) @(
    'runtime.cpython','build.meson','build.ninja','compiler.c','compiler.cpp',
    'linker','ots-sanitize','fonttools-adapter','afdko-adapter','tx-runner'
  ) 'CFF invoked identities'
  foreach ($identity in $invoked) {
    Assert-FontQualificationOrderedKeys $identity @('id','sha256') "CFF invoked $($identity.id)"
    Assert-CffQualificationSha256 ([string]$identity.sha256) "CFF invoked $($identity.id)"
  }
  Assert-CffQualificationSha256 ([string]$Document.invoked_identities_sha256) `
    'CFF invoked identity-set digest'

  $adapters = @($Document.adapters)
  Assert-CffQualificationOrderedValues @($adapters.id) @('fonttools','afdko') 'CFF adapters'
  $adapterPaths = @($CffFontToolsAdapterPath, $CffAfdkoAdapterPath)
  for ($index = 0; $index -lt $adapters.Count; $index++) {
    Assert-FontQualificationOrderedKeys $adapters[$index] @(
      'id','language','backend','version','sha256'
    ) "CFF adapter $index"
    $actual = Get-FontQualificationSha256 -Bytes ([IO.File]::ReadAllBytes($adapterPaths[$index]))
    if ($adapters[$index].sha256 -cne $actual -or
        $adapters[$index].version -cne $packages[$index].version) {
      throw "CFF adapter $index identity drifted."
    }
  }
  if ($invoked[7].sha256 -cne $adapters[0].sha256 -or
      $invoked[8].sha256 -cne $adapters[1].sha256) {
    throw 'CFF adapter alias identity drifted.'
  }

  Assert-FontQualificationOrderedKeys $Document.structural_reader @(
    'id','role','executable_sha256'
  ) 'CFF structural reader'
  if ($Document.structural_reader.id -cne 'ots' -or
      $Document.structural_reader.role -cne 'structural-only' -or
      $Document.structural_reader.executable_sha256 -cne $invoked[6].sha256) {
    throw 'CFF structural reader authority drifted.'
  }
  Assert-FontQualificationOrderedKeys $Document.independence @(
    'fonttools_forbidden_import','afdko_forbidden_import','ots_semantic_oracle'
  ) 'CFF oracle independence'
  if ($Document.independence.fonttools_forbidden_import -cne 'afdko' -or
      $Document.independence.afdko_forbidden_import -cne 'fonttools' -or
      $Document.independence.ots_semantic_oracle -ne $false) {
    throw 'CFF oracle independence contract drifted.'
  }
}

function Assert-CffQualificationCasesDocument {
  param([Parameter(Mandatory)]$Document)

  Assert-FontQualificationOrderedKeys $Document @(
    'schema','license','recipes','generated_workflows','expected_facts',
    'licensed_intake','public_workflow_ids','compatibility_lock_ids','targets',
    'workloads','b8_order','hostile_groups','precedence_cases'
  ) 'CFF qualification cases'
  if ($Document.schema -cne 'cff-qualification-cases/1.0.0' -or
      $Document.license -cne 'Apache-2.0') {
    throw 'CFF qualification cases header drifted.'
  }

  $recipes = @($Document.recipes)
  Assert-CffQualificationOrderedValues @($recipes.id) @(
    'generated-name-keyed-cff1','generated-cid-two-fd-cff1',
    'generated-shared-cff-two-face'
  ) 'CFF generated recipes'
  foreach ($recipe in $recipes) {
    Assert-FontQualificationOrderedKeys $recipe @(
      'id','origin','license','format','glyph_count','deterministic_input',
      'deterministic_sha256'
    ) "CFF recipe $($recipe.id)"
    if ($recipe.origin -cne 'project-generated' -or
        $recipe.license -cne 'Apache-2.0' -or [int]$recipe.glyph_count -ne 3 -or
        $recipe.deterministic_sha256 -cne
          (Get-CffQualificationTextSha256 ([string]$recipe.deterministic_input))) {
      throw "CFF recipe $($recipe.id) is not reproducible."
    }
  }

  $workflowIds = @(
    'generated-name-standalone','generated-name-selected-collection',
    'generated-cid-standalone','generated-cid-selected-collection',
    'generated-shared-cff-face-zero','generated-shared-cff-face-one'
  )
  $workflows = @($Document.generated_workflows)
  Assert-CffQualificationOrderedValues @($workflows.id) $workflowIds 'CFF generated workflows'
  foreach ($workflow in $workflows) {
    Assert-FontQualificationOrderedKeys $workflow @(
      'id','fixture_id','carrier','face_index','recipe_id','expected_fact_id'
    ) "CFF workflow $($workflow.id)"
    if ($workflow.carrier -cnotin @('standalone','collection') -or
        $workflow.fixture_id -cne $workflow.recipe_id -or
        $workflow.recipe_id -cnotin @($recipes.id)) {
      throw "CFF workflow $($workflow.id) contract drifted."
    }
  }

  $facts = @($Document.expected_facts)
  Assert-CffQualificationOrderedValues @($facts.id) @(
    'name-keyed-primary','cid-two-fd-primary','shared-cff-face-zero',
    'shared-cff-face-one'
  ) 'CFF expected facts'
  foreach ($fact in $facts) {
    Assert-FontQualificationOrderedKeys $fact @(
      'id','mapping','environment','metric','kerning','bounds','path'
    ) "CFF fact $($fact.id)"
    Assert-FontQualificationOrderedKeys $fact.mapping @(
      'scalar','gid','glyph_name'
    ) "CFF fact $($fact.id) mapping"
    Assert-FontQualificationOrderedKeys $fact.environment @(
      'keying','key_value','fd','local_subrs','top_matrix_denominator',
      'fd_matrix_magnitude'
    ) "CFF fact $($fact.id) environment"
    Assert-FontQualificationOrderedKeys $fact.metric @(
      'advance','lsb'
    ) "CFF fact $($fact.id) metric"
    Assert-FontQualificationOrderedKeys $fact.bounds @(
      'x_min','y_min','x_max','y_max'
    ) "CFF fact $($fact.id) bounds"
    if (@($fact.path).Count -eq 0 -or $fact.path[-1].op -cne 'Close') {
      throw "CFF fact $($fact.id) path is incomplete."
    }
    foreach ($command in @($fact.path)) {
      Assert-FontQualificationOrderedKeys $command @('op','points') `
        "CFF fact $($fact.id) path command"
      $expectedPointCount = switch ([string]$command.op) {
        'MoveTo' { 2 }
        'LineTo' { 2 }
        'CubicTo' { 6 }
        'Close' { 0 }
        default { throw "CFF fact $($fact.id) has unknown path command." }
      }
      if (@($command.points).Count -ne $expectedPointCount) {
        throw "CFF fact $($fact.id) path arity drifted."
      }
    }
  }
  foreach ($workflow in $workflows) {
    if ($workflow.expected_fact_id -cnotin @($facts.id)) {
      throw "CFF workflow $($workflow.id) references an unknown fact."
    }
  }

  $licensed = @($Document.licensed_intake)
  Assert-CffQualificationOrderedValues @($licensed.id) @(
    'source-sans-3.052R','source-han-serif-jp-2.003R'
  ) 'CFF licensed intake'
  foreach ($record in $licensed) {
    Assert-FontQualificationOrderedKeys $record @(
      'id','family','tag','archive','member','license_file','profile'
    ) "CFF licensed $($record.id)"
    Assert-FontQualificationOrderedKeys $record.archive @(
      'url','length','sha256'
    ) "CFF licensed $($record.id) archive"
    foreach ($partName in @('member','license_file')) {
      Assert-FontQualificationOrderedKeys $record.$partName @(
        'path','length','sha256'
      ) "CFF licensed $($record.id) $partName"
    }
    Assert-FontQualificationOrderedKeys $record.profile @(
      'sfnt_flavor','cff_version','keying','glyph_count','fd_count','used_fds',
      'local_subr_counts','global_subrs','high_gid','high_gid_fd',
      'high_gid_program_tokens'
    ) "CFF licensed $($record.id) profile"
    foreach ($part in @($record.archive, $record.member, $record.license_file)) {
      if ([int64]$part.length -le 0) { throw "CFF licensed $($record.id) has empty input." }
      Assert-CffQualificationSha256 ([string]$part.sha256) "CFF licensed $($record.id)"
    }
  }

  Assert-CffQualificationOrderedValues @($Document.public_workflow_ids) @(
    $workflowIds +
    @('licensed-latin-standalone','licensed-latin-selected-collection',
      'licensed-cjk-standalone','licensed-cjk-selected-collection',
      'static-glyf-standalone','static-glyf-selected-collection')
  ) 'CFF public workflow IDs'
  Assert-CffQualificationOrderedValues @($Document.compatibility_lock_ids) @(
    'static-glyf-standalone','static-glyf-selected-collection'
  ) 'CFF compatibility lock IDs'
  Assert-CffQualificationOrderedValues @($Document.targets) @(
    'js','wasm','wasm-gc','native'
  ) 'CFF targets'

  $workloads = @($Document.workloads)
  Assert-CffQualificationOrderedValues @($workloads.id) @(
    'latin-full-admission','cjk-full-admission','latin-fixed-outline-batch',
    'cjk-high-gid-multi-fd-outline-batch'
  ) 'CFF workloads'
  foreach ($workload in $workloads) {
    Assert-FontQualificationOrderedKeys $workload @(
      'id','fixture_id','operation','gids','correctness_input',
      'correctness_input_sha256','timing'
    ) "CFF workload $($workload.id)"
    if ($workload.timing -ne $false -or
        $workload.correctness_input_sha256 -cne
          (Get-CffQualificationTextSha256 ([string]$workload.correctness_input))) {
      throw "CFF workload $($workload.id) correctness identity drifted."
    }
  }
  Assert-CffQualificationOrderedValues @($Document.b8_order) @(
    'bytes','allocations','allocation_size','width','height','pixels','depth','work'
  ) 'CFF B8 order'
}

function Get-CffQualificationHostileRows {
  param([Parameter(Mandatory)]$Document)
  $rows = [Collections.Generic.List[object]]::new()
  foreach ($group in @($Document.hostile_groups)) {
    foreach ($row in @($group.rows)) { $rows.Add($row) }
  }
  return @($rows)
}

function Assert-CffQualificationSourceLocator {
  param(
    [Parameter(Mandatory)][string]$Locator,
    [Parameter(Mandatory)][string]$Label
  )

  if ($Locator -cnotmatch '^(.+\.mbt):([0-9]+):(.+)$') {
    throw "$Label source locator is not exact."
  }
  $path = Join-Path $RepositoryRoot $Matches[1]
  $lineNumber = [int]$Matches[2]
  $testName = [string]$Matches[3]
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "$Label source file is missing."
  }
  $lines = @(Get-Content -LiteralPath $path)
  if ($lineNumber -lt 1 -or $lineNumber -gt $lines.Count -or
      $lines[$lineNumber - 1].Trim() -cne "test `"$testName`" {") {
    throw "$Label source assertion locator drifted."
  }
}

function Assert-CffQualificationB8 {
  param(
    [Parameter(Mandatory)]$Snapshot,
    [Parameter(Mandatory)][string]$Label
  )
  $values = @($Snapshot)
  if ($values.Count -ne 8) { throw "$Label must contain all eight B8 values." }
  foreach ($value in $values) {
    if ($null -eq $value -or [int64]$value -lt 0) {
      throw "$Label contains an unresolved or negative B8 value."
    }
  }
}

function Assert-CffHostileInventory {
  param([Parameter(Mandatory)]$Document)

  $groups = @($Document.hostile_groups)
  Assert-CffQualificationOrderedValues @($groups.id) @(
    'structural','type2-program','semantic-limit','resource','mutation',
    'multi-fault-precedence'
  ) 'CFF hostile groups'
  $seen = @{}
  foreach ($group in $groups) {
    Assert-FontQualificationOrderedKeys $group @('id','rows') "CFF hostile group $($group.id)"
    if (@($group.rows).Count -eq 0) { throw "CFF hostile group $($group.id) is empty." }
    foreach ($row in @($group.rows)) {
      Assert-FontQualificationOrderedKeys $row @(
        'id','source','category','code','operation','payload','context','gid',
        'publication','caller_before','caller_after','ancestor_before',
        'ancestor_after','boundary'
      ) "CFF hostile row $($row.id)"
      if (-not $row.id -or $seen.ContainsKey([string]$row.id)) {
        throw "CFF hostile row ID is missing or duplicated: $($row.id)"
      }
      $seen[[string]$row.id] = $true
      Assert-CffQualificationSourceLocator ([string]$row.source) "CFF hostile row $($row.id)"
      Assert-FontQualificationOrderedKeys $row.payload @('requested','limit') `
        "CFF hostile row $($row.id) payload"
      Assert-FontQualificationOrderedKeys $row.boundary @(
        'pair_id','kind','dimension','applicable','reason'
      ) "CFF hostile row $($row.id) boundary"
      foreach ($name in @('caller_before','caller_after','ancestor_before','ancestor_after')) {
        Assert-CffQualificationB8 $row.$name "CFF hostile row $($row.id) $name"
      }
      if ($null -ne $row.gid -and [int64]$row.gid -lt 0) {
        throw "CFF hostile row $($row.id) GID is invalid."
      }
      if ($row.publication -cnotin @(
          'none','staged-glyph','existing-font-only','path'
        )) {
        throw "CFF hostile row $($row.id) publication state drifted."
      }
      $expectedCode = switch ([string]$row.category) {
        '' { $null }
        'Data' { 'InvalidEncoding' }
        'Capability' { 'CapabilityUnavailable' }
        'Resource' { 'BudgetExceeded' }
        'State' { 'InvalidRange' }
        default { throw "CFF hostile row $($row.id) category drifted." }
      }
      if ($row.code -cne $expectedCode) {
        throw "CFF hostile row $($row.id) category/code drifted."
      }
      if ($null -eq $row.category) {
        if ($null -ne $row.context -or $row.publication -cnotin @('staged-glyph','path')) {
          throw "CFF hostile success row $($row.id) is inconsistent."
        }
      } elseif (-not $row.context -or $row.publication -cnotin @('none','existing-font-only')) {
        throw "CFF hostile failure row $($row.id) is incomplete."
      }
    }
  }

  $precedence = @($Document.precedence_cases)
  if ($precedence.Count -ne 2) { throw 'CFF precedence case cardinality drifted.' }
  Assert-FontQualificationOrderedKeys $precedence[0] @(
    'id','ordered_categories','source'
  ) 'CFF category precedence'
  Assert-CffQualificationOrderedValues @($precedence[0].ordered_categories) @(
    'State','Resource','Capability','Data'
  ) 'CFF category precedence'
  Assert-CffQualificationSourceLocator ([string]$precedence[0].source) `
    'CFF category precedence'
  Assert-FontQualificationOrderedKeys $precedence[1] @(
    'id','ordered_gids','source'
  ) 'CFF GID precedence'
  Assert-CffQualificationOrderedValues @($precedence[1].ordered_gids) @(0,1,2) `
    'CFF GID precedence'
  Assert-CffQualificationSourceLocator ([string]$precedence[1].source) `
    'CFF GID precedence'
}

function Assert-CffOutcomeTrace {
  param([Parameter(Mandatory)]$Document)
  Assert-CffHostileInventory $Document
  $rows = Get-CffQualificationHostileRows $Document
  foreach ($requiredContext in @(
      'font-cff-header','font-cff-name-index-terminal-extent',
      'font-cff-top-index-terminal-extent','font-cff-string-index',
      'font-cff-global-subrs-index','font-cff-charstrings-index-terminal-extent',
      'font-cff-private-range','font-cff-local-subrs-index',
      'font-cff-top-dict-arity','font-cff-encoding-supplement',
      'font-cff-fd-select-fd','font-cff-fd-select-sentinel',
      'font-cff-fd-private-range','font-cff-font-matrix-arity',
      'font-cff-cid-charset','font-cff-cid-encoding',
      'font-cff-type2-stack-underflow','font-cff-type2-operand-stack',
      'font-cff-type2-division-by-zero',
      'font-cff-type2-width-duplicate','font-cff-type2-geometry-arity',
      'font-cff-type2-stems','font-cff-type2-frame-depth',
      'font-cff-type2-points','font-cff-type2-contours',
      'font-cff-type2-seac','font-cff-type2-non-tail-endchar',
      'font-cff-source-revision-drift','font-cff-type2-source-revision-drift',
      'font-cff-profile','font-cff-type2-reserved-operator',
      'bytes','allocations','allocation_size','work'
    )) {
    if ($requiredContext -cnotin @($rows.context)) {
      throw "CFF hostile outcome is untraced: $requiredContext"
    }
  }
  $mutationIds = @(@($Document.hostile_groups)[4].rows.id)
  Assert-CffQualificationOrderedValues $mutationIds @(
    'mutation-admission-opening','mutation-selected-face','mutation-type2-fetch',
    'mutation-staged-path','mutation-final-commit'
  ) 'CFF mutation windows'
  $smallest = @($rows | Where-Object { $_.id -ceq 'precedence-smallest-failing-gid' })
  if ($smallest.Count -ne 1 -or $smallest[0].gid -ne 1 -or
      $smallest[0].publication -cne 'none') {
    throw 'CFF smallest-failing-GID trace drifted.'
  }
}

function Assert-CffBoundaryApplicability {
  param([Parameter(Mandatory)]$Document)
  Assert-CffHostileInventory $Document
  foreach ($group in @($Document.hostile_groups)) {
    $rows = @($group.rows)
    for ($index = 0; $index -lt $rows.Count; $index++) {
      $row = $rows[$index]
      $kind = [string]$row.boundary.kind
      if ($kind -cnotin @('exact','one-short','not-applicable','covered-by')) {
        throw "CFF hostile row $($row.id) boundary kind drifted."
      }
      if (-not $row.boundary.reason) {
        throw "CFF hostile row $($row.id) boundary reason is missing."
      }
      if ($kind -ceq 'not-applicable') {
        if ($row.boundary.applicable -ne $false -or $null -ne $row.boundary.pair_id) {
          throw "CFF hostile row $($row.id) invented a resource pair."
        }
        continue
      }
      if ($row.boundary.applicable -ne $true -or -not $row.boundary.pair_id) {
        throw "CFF hostile row $($row.id) applicable pair is incomplete."
      }
      if ($kind -ceq 'covered-by') { continue }
      if ($kind -ceq 'exact') {
        if ($index + 1 -ge $rows.Count -or
            $rows[$index + 1].boundary.kind -cne 'one-short' -or
            $rows[$index + 1].boundary.pair_id -cne $row.boundary.pair_id) {
          throw "CFF exact/one-short pair is non-adjacent: $($row.boundary.pair_id)"
        }
      } elseif ($index -eq 0 -or
          $rows[$index - 1].boundary.kind -cne 'exact' -or
          $rows[$index - 1].boundary.pair_id -cne $row.boundary.pair_id) {
        throw "CFF one-short row lacks an adjacent exact row: $($row.id)"
      }
    }
  }
}

function Assert-CffGeneratedRecipeFacts {
  param([Parameter(Mandatory)]$Document)

  $name = @($Document.expected_facts)[0]
  if ($name.mapping.scalar -ne 65 -or $name.mapping.gid -ne 1 -or
      $name.metric.advance -ne 600 -or $name.metric.lsb -ne 100 -or
      (@($name.bounds.x_min,$name.bounds.y_min,$name.bounds.x_max,$name.bounds.y_max) -join ',') -cne
        '100,0,500,575' -or
      (@($name.path.op) -join ',') -cne 'MoveTo,LineTo,CubicTo,LineTo,Close') {
    throw 'Hand-derived generated name-keyed facts drifted.'
  }
  $cid = @($Document.expected_facts)[1]
  if ($cid.mapping.gid -ne 2 -or $cid.environment.key_value -ne 101 -or
      $cid.environment.fd -ne 1 -or $cid.environment.local_subrs -ne 0 -or
      $cid.environment.top_matrix_denominator -ne 1000 -or
      $cid.environment.fd_matrix_magnitude -ne 2) {
    throw 'Hand-derived generated CID facts drifted.'
  }
  $faceZero = @($Document.expected_facts)[2]
  $faceOne = @($Document.expected_facts)[3]
  if ($faceZero.mapping.scalar -eq $faceOne.mapping.scalar -or
      $faceZero.metric.advance -eq $faceOne.metric.advance -or
      $faceZero.metric.lsb -eq $faceOne.metric.lsb -or
      $faceZero.kerning -eq $faceOne.kerning -or
      (($faceZero.path | ConvertTo-Json -Depth 10 -Compress) -cne
        ($faceOne.path | ConvertTo-Json -Depth 10 -Compress))) {
    throw 'Shared-CFF faces do not preserve shared outlines and distinct face-local facts.'
  }
}

function Assert-CffLicensedProducerInputs {
  param([Parameter(Mandatory)]$Document)

  $latin = @($Document.licensed_intake)[0]
  if ($latin.archive.length -ne 2387997 -or
      $latin.member.length -ne 334924 -or $latin.license_file.length -ne 4579 -or
      $latin.profile.keying -cne 'name' -or $latin.profile.glyph_count -ne 2478 -or
      $latin.profile.local_subr_counts[0] -ne 648 -or
      $latin.profile.global_subrs -ne 738) {
    throw 'Source Sans producer inputs drifted.'
  }
  $cjk = @($Document.licensed_intake)[1]
  if ($cjk.archive.length -ne 36831708 -or
      $cjk.member.length -ne 6210796 -or $cjk.license_file.length -ne 4463 -or
      $cjk.profile.keying -cne 'cid' -or $cjk.profile.glyph_count -ne 17923 -or
      $cjk.profile.fd_count -ne 18 -or
      (@($cjk.profile.used_fds) -join ',') -cne ((0..17) -join ',') -or
      (@($cjk.profile.local_subr_counts) -join ',') -cne
        '16,46,7,2004,39,131,0,1,7,0,0,205,21626,237,389,17,0,231' -or
      $cjk.profile.global_subrs -ne 1599 -or $cjk.profile.high_gid -ne 17922 -or
      $cjk.profile.high_gid_fd -ne 17 -or $cjk.profile.high_gid_program_tokens -ne 136) {
    throw 'Source Han producer inputs drifted.'
  }
}

function Assert-CffOracleAdapterIndependence {
  $fontToolsSource = Get-Content -Raw -LiteralPath $CffFontToolsAdapterPath
  $afdkoSource = Get-Content -Raw -LiteralPath $CffAfdkoAdapterPath
  if ($fontToolsSource -match '(?im)^\s*(from|import)\s+afdko\b') {
    throw 'fontTools adapter aliases the AFDKO semantic backend.'
  }
  if ($afdkoSource -match '(?im)\bfonttools\b') {
    throw 'AFDKO adapter aliases the fontTools semantic backend.'
  }
}

function Copy-CffQualificationDocument {
  param([Parameter(Mandatory)]$Document)
  return ($Document | ConvertTo-Json -Depth 100) | ConvertFrom-Json
}

function Assert-CffQualificationExpectedFailure {
  param(
    [Parameter(Mandatory)][scriptblock]$Action,
    [Parameter(Mandatory)][string]$Label
  )
  $failed = $false
  try { & $Action } catch { $failed = $true }
  if (-not $failed) { throw "CFF schema negative unexpectedly passed: $Label" }
}

function Invoke-CffQualificationSchemaNegatives {
  param(
    [Parameter(Mandatory)]$Tools,
    [Parameter(Mandatory)]$Cases
  )

  $originalCulture = [Globalization.CultureInfo]::CurrentCulture
  $originalUiCulture = [Globalization.CultureInfo]::CurrentUICulture
  try {
    [Globalization.CultureInfo]::CurrentCulture =
      [Globalization.CultureInfo]::GetCultureInfo('fr-FR')
    [Globalization.CultureInfo]::CurrentUICulture =
      [Globalization.CultureInfo]::GetCultureInfo('tr-TR')
    Assert-CffOracleToolsDocument $Tools
    Assert-CffQualificationCasesDocument $Cases
  } finally {
    [Globalization.CultureInfo]::CurrentCulture = $originalCulture
    [Globalization.CultureInfo]::CurrentUICulture = $originalUiCulture
  }

  $copy = Copy-CffQualificationDocument $Cases
  $copy.PSObject.Properties.Remove('license')
  Assert-CffQualificationExpectedFailure { Assert-CffQualificationCasesDocument $copy } `
    'missing top-level key'

  $copy = Copy-CffQualificationDocument $Cases
  $copy | Add-Member -NotePropertyName unexpected -NotePropertyValue $true
  Assert-CffQualificationExpectedFailure { Assert-CffQualificationCasesDocument $copy } `
    'extra top-level key'

  $copy = Copy-CffQualificationDocument $Cases
  $copy.recipes[1].id = $copy.recipes[0].id
  Assert-CffQualificationExpectedFailure { Assert-CffQualificationCasesDocument $copy } `
    'duplicate recipe ID'

  $copy = Copy-CffQualificationDocument $Cases
  $copy.targets = @('wasm','js','wasm-gc','native')
  Assert-CffQualificationExpectedFailure { Assert-CffQualificationCasesDocument $copy } `
    'reordered target ID'

  $copy = Copy-CffQualificationDocument $Cases
  $copy.workloads = @($copy.workloads | Select-Object -SkipLast 1)
  Assert-CffQualificationExpectedFailure { Assert-CffQualificationCasesDocument $copy } `
    'missing workload ID'

  $copy = Copy-CffQualificationDocument $Cases
  $reordered = [ordered]@{}
  foreach ($name in @(
      'license','schema','recipes','generated_workflows','expected_facts',
      'licensed_intake','public_workflow_ids','compatibility_lock_ids','targets',
      'workloads','b8_order','hostile_groups','precedence_cases'
    )) {
    $reordered[$name] = $copy.$name
  }
  Assert-CffQualificationExpectedFailure { Assert-CffQualificationCasesDocument $reordered } `
    'reordered schema keys'

  $copy = Copy-CffQualificationDocument $Tools
  $copy.adapters[1].sha256 = $copy.adapters[0].sha256
  Assert-CffQualificationExpectedFailure { Assert-CffOracleToolsDocument $copy } `
    'adapter alias'

  $copy = Copy-CffQualificationDocument $Tools
  $copy.packages[0].version = '4.62.0'
  Assert-CffQualificationExpectedFailure { Assert-CffOracleToolsDocument $copy } `
    'tool substitution'

  $copy = Copy-CffQualificationDocument $Tools
  $copy.schema = 'cff-oracle-tools/0.0.0'
  Assert-CffQualificationExpectedFailure { Assert-CffOracleToolsDocument $copy } `
    'oracle schema drift'

  $copy = Copy-CffQualificationDocument $Cases
  $copy.hostile_groups[0].rows[0].caller_before = @(1,2,3,4,5,6,7)
  Assert-CffQualificationExpectedFailure { Assert-CffHostileInventory $copy } `
    'incomplete B8 snapshot'

  $copy = Copy-CffQualificationDocument $Cases
  $copy.hostile_groups[0].rows[0].category = 'Resource'
  Assert-CffQualificationExpectedFailure { Assert-CffHostileInventory $copy } `
    'wrong literal category'

  $copy = Copy-CffQualificationDocument $Cases
  $copy.hostile_groups[0].rows[0].boundary.pair_id = 'invented'
  $copy.hostile_groups[0].rows[0].boundary.applicable = $true
  Assert-CffQualificationExpectedFailure { Assert-CffBoundaryApplicability $copy } `
    'invented exact/one-short pair'

  $copy = Copy-CffQualificationDocument $Cases
  $temporary = $copy.hostile_groups[3].rows[0]
  $copy.hostile_groups[3].rows[0] = $copy.hostile_groups[3].rows[1]
  $copy.hostile_groups[3].rows[1] = $temporary
  Assert-CffQualificationExpectedFailure { Assert-CffBoundaryApplicability $copy } `
    'non-adjacent exact/one-short pair'

  $copy = Copy-CffQualificationDocument $Cases
  $copy.generated_workflows[0].expected_fact_id = 'consumer-completed-fact'
  Assert-CffQualificationExpectedFailure { Assert-CffQualificationCasesDocument $copy } `
    'consumer completion of expected fact'
}

function Invoke-CffQualificationContractCheck {
  param(
    [switch]$Contracts,
    [switch]$GeneratedRecipes,
    [switch]$OracleAdapters,
    [switch]$SchemaNegatives,
    [switch]$HostileInventory,
    [switch]$OutcomeTrace,
    [switch]$BoundaryApplicability
  )

  $tools = Read-CffQualificationJson $CffOracleToolsPath 'CFF oracle tools'
  $cases = Read-CffQualificationJson $CffQualificationCasesPath 'CFF qualification cases'
  if ($Contracts) {
    Assert-CffOracleToolsDocument $tools
    Assert-CffQualificationCasesDocument $cases
    Assert-CffLicensedProducerInputs $cases
  }
  if ($GeneratedRecipes) {
    Assert-CffQualificationCasesDocument $cases
    Assert-CffGeneratedRecipeFacts $cases
  }
  if ($OracleAdapters) {
    Assert-CffOracleToolsDocument $tools
    Assert-CffOracleAdapterIndependence
  }
  if ($SchemaNegatives) {
    Invoke-CffQualificationSchemaNegatives $tools $cases
  }
  if ($HostileInventory) {
    Assert-CffQualificationCasesDocument $cases
    Assert-CffHostileInventory $cases
  }
  if ($OutcomeTrace) {
    Assert-CffQualificationCasesDocument $cases
    Assert-CffOutcomeTrace $cases
  }
  if ($BoundaryApplicability) {
    Assert-CffQualificationCasesDocument $cases
    Assert-CffBoundaryApplicability $cases
  }
  Write-Host 'CFF canonical qualification contract verification passed.'
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
            'FontCollection::open_face','Font::query','Font::glyph_id',
            'Font::kerning','Font::outline','FontLimits::new'
          ) -or
          $case.boundary -cnotin @('success','failure','exact','one-short') -or
          $case.publication -cnotin @(
            'none','collection','font','limits',
            'existing-collection-only','existing-font-only'
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

  # These tables intentionally spell out every runtime-observable field. Do not
  # derive contexts or numeric boundaries from IDs: the corpus is the executable
  # contract, not a display-name catalogue.
  $hostileFacts = @(
    @('collection-header-truncated','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-header',$null,4UL,0UL),
    @('collection-signature-invalid','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-signature',0UL,$null,$null),
    @('collection-version-unsupported','open','FontCollection::open',$null,'Capability','CapabilityUnavailable','font-collection-open','font-collection-version',$null,$null,$null),
    @('collection-face-count-zero','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-face-count',8UL,$null,$null),
    @('collection-offset-array-truncated','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-offset-array',12UL,32UL,15UL),
    @('collection-face-directory-truncated','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-directory-range',64UL,12UL,75UL),
    @('collection-directory-search-facts-invalid','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-search-facts',$null,$null,$null),
    @('collection-directory-tags-unordered','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-table-tag-order',92UL,$null,$null),
    @('collection-table-range-overflow','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-table-range',4294967292UL,8UL,160UL),
    @('collection-protected-range-overlap','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-table-protected-overlap',64UL,4UL,$null),
    @('collection-same-face-overlap','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-same-face-overlap',96UL,4UL,$null),
    @('collection-cross-face-partial-overlap','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-cross-face-overlap',100UL,8UL,$null),
    @('collection-shared-range-metadata-conflict','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-shared-metadata',96UL,4UL,$null),
    @('collection-dsig-partial-zero-tuple','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-dsig-tuple',$null,$null,$null),
    @('collection-dsig-range-not-at-eof','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-dsig-range',68UL,28UL,100UL),
    @('collection-dsig-envelope-malformed','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-dsig-block-length',88UL,12UL,11UL),
    @('collection-dsig-version-unsupported','open','FontCollection::open',$null,'Capability','CapabilityUnavailable','font-collection-open','font-collection-dsig-version',$null,$null,$null),
    @('collection-dsig-format-unsupported','open','FontCollection::open',$null,'Capability','CapabilityUnavailable','font-collection-open','font-collection-dsig-format',$null,$null,$null),
    @('collection-dsig-block-overlap','open','FontCollection::open',$null,'Data','InvalidEncoding','font-collection-open','font-collection-dsig-block-overlap',108UL,12UL,$null),
    @('collection-face-index-equal-count','select','FontCollection::open_face',5,'Input','InvalidRange','font-collection-open-face','font-collection-face-index',$null,5UL,5UL),
    @('collection-select-cff','select','FontCollection::open_face',1,'Capability','CapabilityUnavailable','font-collection-open-face','font-cff-profile',$null,$null,$null),
    @('collection-select-cff2','select','FontCollection::open_face',2,'Capability','CapabilityUnavailable','font-collection-open-face','font-collection-face-profile',$null,$null,$null),
    @('collection-select-variable','select','FontCollection::open_face',3,'Capability','CapabilityUnavailable','font-collection-open-face','font-collection-face-profile',$null,$null,$null),
    @('collection-checked-pair-work-overflow','open','FontCollection::open',$null,'Resource','BudgetExceeded','font-collection-open','max-work',$null,[UInt64]::MaxValue,48UL)
  )
  $hostile = [Collections.Generic.List[object]]::new()
  foreach ($fact in $hostileFacts) {
    $hostile.Add((New-FontCollectionQualificationCase `
      -Id $fact[0] -FixtureId 'generated-ttc-v2-mixed-profiles' -Stage $fact[1] `
      -Entrypoint $fact[2] -FaceIndex $fact[3] -Authority 'hostile' `
      -Boundary 'failure' -Category $fact[4] -Code $fact[5] `
      -Operation $fact[6] -Context $fact[7] -SourceOffset $fact[8] `
      -Requested $fact[9] -Limit $fact[10] -Publication 'none' `
      -BudgetBefore $zero -BudgetAfter $zero))
  }

  $mutationFacts = @(
    @('mutation-collection-after-open-before-query','inspect','FontCollection::face_profile',$null,'font-collection-query','font-collection-source-revision-drift','existing-collection-only',$zero),
    @('mutation-collection-mid-open-final-guard','open','FontCollection::open',$null,'font-collection-open','font-collection-source-revision-drift','none',(New-FontCollectionQualificationBudgetSnapshot -Bytes 248UL -Allocations 2UL -AllocationSize 80UL -Work 86UL)),
    @('mutation-selection-before-open-face','select','FontCollection::open_face',0,'font-collection-open-face','font-collection-source-revision-drift','existing-collection-only',$zero),
    @('mutation-selection-mid-admission-final-guard','select','FontCollection::open_face',0,'font-collection-open-face','font-collection-source-revision-drift','existing-collection-only',(New-FontCollectionQualificationBudgetSnapshot -Bytes 65536UL -Allocations 16UL -AllocationSize 65536UL -Work 65536UL)),
    @('mutation-selected-font-after-publication','query','Font::query',0,'font-query','font-source-revision-drift','existing-font-only',$zero),
    @('mutation-glyph-lookup-mid-query','query','Font::glyph_id',0,'font-query','font-source-revision-drift','existing-font-only',$zero),
    @('mutation-kerning-mid-query','query','Font::kerning',0,'font-query','font-source-revision-drift','existing-font-only',$zero),
    @('mutation-simple-outline-mid-query','query','Font::outline',0,'font-outline','font-source-revision-drift','existing-font-only',$zero),
    @('mutation-composite-outline-mid-query','query','Font::outline',0,'font-outline','font-source-revision-drift','existing-font-only',$zero)
  )
  $mutation = [Collections.Generic.List[object]]::new()
  foreach ($fact in $mutationFacts) {
    $mutation.Add((New-FontCollectionQualificationCase `
      -Id $fact[0] -FixtureId 'generated-ttc-v1-exact-sharing' -Stage $fact[1] `
      -Entrypoint $fact[2] -FaceIndex $fact[3] -MutationWindow $fact[0] `
      -Authority 'mutation' -Boundary 'failure' -Category 'State' `
      -Code 'InvalidRange' -Operation $fact[4] -Context $fact[5] `
      -SourceOffset $null -Requested $null -Limit $null `
      -Publication $fact[6] -BudgetBefore $fact[7] -BudgetAfter $fact[7]))
  }

  $collectionLimitFacts = [ordered]@{
    'source-bytes' = 88UL
    'faces' = 5UL
    'tables-per-face' = 3UL
    'table-records' = 8UL
    'dsig-records' = 2UL
    'dsig-bytes' = 56UL
    'retained-bookkeeping-bytes' = 440UL
    'work' = 252UL
  }
  # The selected corpus uses a deliberately roomy, deterministic admission
  # envelope. Each row freezes the exact configured boundary; runtime tests
  # separately exercise the semantic parser demand for that dimension.
  $selectedLimitFacts = [ordered]@{
    'source-bytes' = 716UL
    'tables' = 10UL
    'table-bytes' = 78UL
    'glyphs' = 1UL
    'name-records' = 1UL
    'cmap-records' = 1UL
    'kern-subtables' = 1UL
    'kern-pairs' = 1UL
    'outline-points' = 1UL
    'outline-contours' = 1UL
    'outline-components' = 1UL
    'instruction-bytes' = 1UL
    'post-name-bytes' = 1UL
    'work' = 1UL
  }
  $limits = [Collections.Generic.List[object]]::new()
  foreach ($id in @($expectedIds.limit_cases)) {
    $selected = $id.StartsWith('limit-selected-', [StringComparison]::Ordinal)
    $oneShort = $id.EndsWith('-one-short', [StringComparison]::Ordinal)
    $dimension = $id.Substring($(if ($selected) { 15 } else { 17 }))
    $dimension = $dimension.Substring(0, $dimension.Length - $(if ($oneShort) { 10 } else { 6 }))
    $requested = if ($selected) { $selectedLimitFacts[$dimension] } else { $collectionLimitFacts[$dimension] }
    if ($null -eq $requested) {
      throw "No explicit qualification boundary is declared for '$id'."
    }
    $constructorBoundary = $selected -and $dimension -notin @(
      'source-bytes','tables','table-bytes'
    )
    $caseRequested = if ($constructorBoundary -and $oneShort) { 0UL } else { $requested }
    $declaredLimit = if ($constructorBoundary -and $oneShort) {
      1UL
    } elseif ($oneShort) {
      $requested - 1UL
    } else {
      $requested
    }
    $limits.Add((New-FontCollectionQualificationCase `
      -Id $id -FixtureId $(if ($selected) { 'generated-ttc-v1-static-selected' } else { 'generated-ttc-v1-exact-sharing' }) `
      -Stage $(if ($constructorBoundary) { 'inspect' } elseif ($selected) { 'select' } else { 'open' }) `
      -Entrypoint $(if ($constructorBoundary) { 'FontLimits::new' } elseif ($selected) { 'FontCollection::open_face' } else { 'FontCollection::open' }) `
      -FaceIndex $(if ($selected) { 0 } else { $null }) `
      -Authority $(if ($selected) { 'selected-limit' } else { 'collection-limit' }) `
      -Boundary $(if ($oneShort) { 'one-short' } else { 'exact' }) `
      -Category $(if ($oneShort) { $(if ($constructorBoundary) { 'Input' } else { 'Resource' }) } else { $null }) `
      -Code $(if ($oneShort) { $(if ($constructorBoundary) { 'InvalidRange' } else { 'BudgetExceeded' }) } else { $null }) `
      -Operation $(if ($oneShort) { $(if ($constructorBoundary) { 'font-limits-new' } elseif ($selected) { 'font-open' } else { 'font-collection-open' }) } else { $null }) `
      -Context $(if ($oneShort) { $(if ($dimension -ceq 'instruction-bytes') { 'max-outline-instruction-bytes' } else { "max-$dimension" }) } else { $null }) `
      -SourceOffset $null -Requested $caseRequested -Limit $declaredLimit `
      -Publication $(if ($oneShort) { 'none' } elseif ($constructorBoundary) { 'limits' } elseif ($selected) { 'font' } else { 'collection' }) `
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
  $recordIndex = -1
  for ($index = 0; $index -lt $records.Count; $index++) {
    if ($records[$index].id -ceq $expected.id) { $recordIndex = $index }
  }
  if ($CheckOnly) {
    if ($matches.Count -ne 1 -or $recordIndex -ne 10) {
      throw 'Font qualification case manifest record is missing, duplicated, or reordered.'
    }
    Assert-ManifestRecord $records[$recordIndex] $expected
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
  if ($matches.Count -ne 1 -or $recordIndex -ne 10) {
    throw 'Refusing duplicate or reordered font qualification case manifest record.'
  }
  foreach ($key in @($expected.Keys)) {
    $records[$recordIndex].$key = $expected[$key]
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

function Update-OrCheckFontCollectionManifest {
  param([switch]$CheckOnly)

  if ($CheckOnly) {
    Assert-FontCollectionManifestContract
    return
  }
  $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
  $records = @($manifest.records)
  if ($records.Count -eq 14) {
    $prefixJson = ConvertTo-StableJson @($records[0..10])
    $prefixSha256 = Get-FontQualificationSha256 -Bytes $Utf8NoBom.GetBytes($prefixJson)
    if ($prefixSha256 -cne $PreCollectionManifestRecordsSha256) {
      throw 'Refusing to update collection records after pre-Phase-103 manifest drift.'
    }
    $expectedIds = @((Get-FontCollectionManifestRecords).id)
    if ((@($records[11..13].id) -join "`0") -cne ($expectedIds -join "`0")) {
      throw 'Refusing to update reordered font collection manifest records.'
    }
    $manifest.records = @($records[0..10]) + @(Get-FontCollectionManifestRecords)
    [IO.File]::WriteAllText($ManifestPath, (ConvertTo-StableJson $manifest), $Utf8NoBom)
    Assert-FontCollectionManifestContract
    return
  }
  if ($records.Count -ne 11) {
    throw 'Refusing partial, duplicate, or reordered font collection manifest records.'
  }
  $prefixSha256 = Get-FontQualificationSha256 -Bytes $Utf8NoBom.GetBytes(
    (ConvertTo-StableJson $records)
  )
  if ($prefixSha256 -cne $PreCollectionManifestRecordsSha256) {
    throw 'Refusing to append after drifted pre-Phase-103 manifest records.'
  }
  $manifest.records = $records + @(Get-FontCollectionManifestRecords)
  [IO.File]::WriteAllText(
    $ManifestPath,
    (ConvertTo-StableJson $manifest),
    $Utf8NoBom
  )
  Assert-FontCollectionManifestContract
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

function ConvertTo-MoonOptionalString {
  param($Value)
  if ($null -eq $Value) { return 'None' }
  $text = [string]$Value
  if ($text.Contains('"', [StringComparison]::Ordinal) -or
      $text.Contains('\', [StringComparison]::Ordinal)) {
    throw "Generated MoonBit collection string requires unsupported escaping: $text"
  }
  return "Some(`"$text`")"
}

function Add-FontCollectionQualificationBudgetRows {
  param(
    [Parameter(Mandatory)][AllowEmptyString()][AllowEmptyCollection()]$Rows,
    [Parameter(Mandatory)][string]$Property,
    [Parameter(Mandatory)]$Budget,
    [Parameter(Mandatory)][string]$Indent
  )
  [void]$Rows.Add("$Indent$Property`: {")
  [void]$Rows.Add("$Indent  bytes: $([uint64]$Budget.bytes)UL,")
  [void]$Rows.Add("$Indent  allocations: $([uint64]$Budget.allocations)UL,")
  [void]$Rows.Add("$Indent  allocation_size: $([uint64]$Budget.allocation_size)UL,")
  [void]$Rows.Add("$Indent  width: $([uint64]$Budget.width)UL,")
  [void]$Rows.Add("$Indent  height: $([uint64]$Budget.height)UL,")
  [void]$Rows.Add("$Indent  pixels: $([uint64]$Budget.pixels)UL,")
  [void]$Rows.Add("$Indent  depth: $([uint64]$Budget.depth)UL,")
  [void]$Rows.Add("$Indent  work: $([uint64]$Budget.work)UL,")
  [void]$Rows.Add("$Indent},")
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
    [Parameter(Mandatory)][byte[]]$CollectionTtcBytes,
    [Parameter(Mandatory)]$Oracle,
    [Parameter(Mandatory)]$CasesDocument,
    [Parameter(Mandatory)]$CollectionCasesDocument,
    [switch]$CheckOnly
  )

  Assert-ExactBytesIdentity 'generated DejaVu source' $FontBytes $FontLength $FontSha256
  Assert-ExactBytesIdentity `
    'generated DejaVu collection source' `
    $CollectionTtcBytes `
    $CollectionFontLength `
    $CollectionFontSha256
  $reconstructedTtc = New-FontQualificationDejaVuTtc -FontBytes $FontBytes
  if (-not [Linq.Enumerable]::SequenceEqual(
      [byte[]]$CollectionTtcBytes,
      [byte[]]$reconstructedTtc
    )) {
    throw 'Generated MoonBit TTC assembler recipe differs from the canonical derivative.'
  }
  $supportedOutlines = @(Get-FontQualificationSupportedOutlines -Oracle $Oracle)
  $rows = [Collections.Generic.List[string]]::new()
  $rows.Add('// Generated by scripts/fixtures/Generate-FontQualification.ps1. Do not edit.')
  $rows.Add('// Canonical source: fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf')
  $rows.Add("// SHA-256: $FontSha256")
  $rows.Add("// Upstream license: $UpstreamLicense")
  $rows.Add("// Literal chunk size: $GeneratedChunkSize bytes")
  $rows.Add('// Collection derivative: fixtures/font/dejavu-sans-2.37/DejaVuSans-two-face-v1.ttc')
  $rows.Add("// Collection SHA-256: $CollectionFontSha256")
  $rows.Add('// Collection bytes reuse the standalone literal; no second licensed literal body.')
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
  $rows.Add('struct FontCollectionQualificationBudgetSnapshot {')
  $rows.Add('  bytes : UInt64')
  $rows.Add('  allocations : UInt64')
  $rows.Add('  allocation_size : UInt64')
  $rows.Add('  width : UInt64')
  $rows.Add('  height : UInt64')
  $rows.Add('  pixels : UInt64')
  $rows.Add('  depth : UInt64')
  $rows.Add('  work : UInt64')
  $rows.Add('}')
  $rows.Add('')
  $rows.Add('///|')
  $rows.Add('struct FontCollectionQualificationError {')
  $rows.Add('  category : String?')
  $rows.Add('  code : String?')
  $rows.Add('  operation : String?')
  $rows.Add('  context : String?')
  $rows.Add('  source_offset : UInt64?')
  $rows.Add('  requested : UInt64?')
  $rows.Add('  limit : UInt64?')
  $rows.Add('}')
  $rows.Add('')
  $rows.Add('///|')
  $rows.Add('struct FontCollectionQualificationCase {')
  $rows.Add('  id : String')
  $rows.Add('  group : String')
  $rows.Add('  fixture_id : String')
  $rows.Add('  stage : String')
  $rows.Add('  entrypoint : String')
  $rows.Add('  face_index : UInt64?')
  $rows.Add('  mutation_window : String')
  $rows.Add('  authority : String')
  $rows.Add('  boundary : String')
  $rows.Add('  error : FontCollectionQualificationError')
  $rows.Add('  publication : String')
  $rows.Add('  budget_before : FontCollectionQualificationBudgetSnapshot')
  $rows.Add('  budget_after : FontCollectionQualificationBudgetSnapshot')
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
  $rows.Add('fn font_qualification_dejavu_two_face_ttc_v1_bytes() -> Bytes {')
  $rows.Add('  let standalone = font_qualification_dejavu_sans_237_bytes()')
  $rows.Add("  let output = Array::make($CollectionFontLength, b'\x00')")
  $rows.Add('  font_test_put_u32(output, 0, 0x74746366UL)')
  $rows.Add('  font_test_put_u32(output, 4, 0x00010000UL)')
  $rows.Add('  font_test_put_u32(output, 8, 2UL)')
  $rows.Add('  font_test_put_u32(output, 12, 20UL)')
  $rows.Add('  font_test_put_u32(output, 16, 352UL)')
  $rows.Add('  for index = 0; index < 332; index = index + 1 {')
  $rows.Add('    output[20 + index] = standalone[index]')
  $rows.Add('    output[352 + index] = standalone[index]')
  $rows.Add('  }')
  $rows.Add('  for record_index = 0; record_index < 20; record_index = record_index + 1 {')
  $rows.Add('    let offset_field = 12 + record_index * 16 + 8')
  $rows.Add('    let root_offset = font_test_read_u32(standalone, offset_field) + 352UL')
  $rows.Add('    font_test_put_u32(output, 20 + offset_field, root_offset)')
  $rows.Add('    font_test_put_u32(output, 352 + offset_field, root_offset)')
  $rows.Add('  }')
  $rows.Add('  for index = 332; index < standalone.length(); index = index + 1 {')
  $rows.Add('    output[684 + index - 332] = standalone[index]')
  $rows.Add('  }')
  $rows.Add('  Bytes::from_array(output)')
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
  $rows.Add('///|')
  $rows.Add('fn font_collection_qualification_cases() -> Array[')
  $rows.Add('  FontCollectionQualificationCase,')
  $rows.Add('] {')
  $rows.Add('  [')
  $collectionGroups = [ordered]@{
    public_workflows = @($CollectionCasesDocument.public_workflows)
    hostile_cases = @($CollectionCasesDocument.hostile_cases)
    mutation_cases = @($CollectionCasesDocument.mutation_cases)
    limit_cases = @($CollectionCasesDocument.limit_cases)
    budget_cases = @($CollectionCasesDocument.budget_cases)
  }
  foreach ($group in @($collectionGroups.Keys)) {
    foreach ($case in @($collectionGroups[$group])) {
      $rows.Add('    {')
      $rows.Add("      id: `"$($case.id)`",")
      $rows.Add("      group: `"$group`",")
      $rows.Add("      fixture_id: `"$($case.fixture_id)`",")
      $rows.Add("      stage: `"$($case.stage)`",")
      $rows.Add("      entrypoint: `"$($case.entrypoint)`",")
      $rows.Add("      face_index: $(ConvertTo-MoonOptionalUInt64 $case.face_index),")
      $rows.Add("      mutation_window: `"$($case.mutation_window)`",")
      $rows.Add("      authority: `"$($case.authority)`",")
      $rows.Add("      boundary: `"$($case.boundary)`",")
      $rows.Add('      error: {')
      $rows.Add("        category: $(ConvertTo-MoonOptionalString $case.error.category),")
      $rows.Add("        code: $(ConvertTo-MoonOptionalString $case.error.code),")
      $rows.Add("        operation: $(ConvertTo-MoonOptionalString $case.error.operation),")
      $rows.Add("        context: $(ConvertTo-MoonOptionalString $case.error.context),")
      $rows.Add("        source_offset: $(ConvertTo-MoonOptionalUInt64 $case.error.source_offset),")
      $rows.Add("        requested: $(ConvertTo-MoonOptionalUInt64 $case.error.requested),")
      $rows.Add("        limit: $(ConvertTo-MoonOptionalUInt64 $case.error.limit),")
      $rows.Add('      },')
      $rows.Add("      publication: `"$($case.publication)`",")
      Add-FontCollectionQualificationBudgetRows `
        -Rows $rows `
        -Property 'budget_before' `
        -Budget $case.budget_before `
        -Indent '      '
      Add-FontCollectionQualificationBudgetRows `
        -Rows $rows `
        -Property 'budget_after' `
        -Budget $case.budget_after `
        -Indent '      '
      $rows.Add('    },')
    }
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

function Get-CffFileSha256 {
  param([Parameter(Mandatory)][string]$Path)
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Get-CffTextSha256 {
  param([Parameter(Mandatory)][string]$Text)
  return [Convert]::ToHexString(
    [Security.Cryptography.SHA256]::HashData($Utf8NoBom.GetBytes($Text))
  ).ToLowerInvariant()
}

function Test-CffPathWithinRoot {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Root)
  $pathFull = [IO.Path]::GetFullPath($Path).TrimEnd('\')
  $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\')
  return $pathFull.Equals($rootFull, [StringComparison]::OrdinalIgnoreCase) -or
    $pathFull.StartsWith($rootFull + '\', [StringComparison]::OrdinalIgnoreCase)
}

function Assert-CffNoReparsePath {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
  $current = [IO.Path]::GetFullPath($Path)
  while ($null -ne $current) {
    $item = Get-Item -LiteralPath $current -Force
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
      throw "$Label contains a reparse-point component."
    }
    $parent = [IO.Directory]::GetParent($current)
    $current = if ($null -eq $parent) { $null } else { $parent.FullName }
  }
}

function Assert-CffExecutionHandoff {
  if (-not $ExecutionHandoffPath) {
    throw '-ExecutionHandoffPath is required for licensed CFF intake.'
  }
  if ($ExecutionHandoffPath.Replace('\', '/') -cne $CffExecutionHandoffRelativePath) {
    throw 'Licensed CFF intake accepts only the summary-recorded execution handoff path.'
  }
  $handoffPath = [IO.Path]::GetFullPath((Join-Path $RepositoryRoot $ExecutionHandoffPath))
  $handoffRoot = Join-Path $RepositoryRoot 'artifacts/release-qualification/phase-107'
  if (-not (Test-CffPathWithinRoot $handoffPath $handoffRoot) -or
      -not (Test-Path -LiteralPath $handoffPath -PathType Leaf)) {
    throw 'Licensed CFF execution handoff is missing or moved.'
  }
  Assert-CffNoReparsePath $handoffPath 'execution handoff'
  if ((Get-CffFileSha256 $handoffPath) -cne $CffExecutionHandoffSha256) {
    throw 'Licensed CFF execution handoff SHA-256 differs from the 107-01 summary.'
  }
  $summaryPath = Join-Path $RepositoryRoot (
    '.planning/phases/107-hostile-licensed-and-four-target-qualification/107-01-SUMMARY.md'
  )
  $summary = Get-Content -Raw -LiteralPath $summaryPath
  if ($summary -notmatch [regex]::Escape($CffExecutionHandoffRelativePath) -or
      $summary -notmatch $CffExecutionHandoffSha256) {
    throw '107-01 summary no longer binds the licensed CFF execution handoff.'
  }

  $handoff = Get-Content -Raw -LiteralPath $handoffPath | ConvertFrom-Json
  Assert-FontQualificationOrderedKeys $handoff @(
    'schema','manifest_path','manifest_sha256','preflight_timestamp',
    'ordered_role_ids','preflight_sdk_inventory_sha256','preflight_validated',
    'lock_sha256','provisioned_tools_root','sdk_inventory_sha256',
    'invoked_identities','invoked_identities_sha256','adapter_sha256',
    'ots_executable_sha256','provisioning_validated'
  ) 'execution handoff'
  if ($handoff.schema -cne $CffExecutionHandoffSchema -or
      $handoff.preflight_validated -ne $true -or
      $handoff.provisioning_validated -ne $true) {
    throw 'Licensed CFF execution handoff is not fully validated.'
  }
  if (-not [IO.Path]::IsPathFullyQualified([string]$handoff.manifest_path) -or
      -not (Test-Path -LiteralPath $handoff.manifest_path -PathType Leaf) -or
      (Get-CffFileSha256 $handoff.manifest_path) -cne [string]$handoff.manifest_sha256) {
    throw 'Licensed CFF caller manifest identity drifted.'
  }
  Assert-CffNoReparsePath $handoff.manifest_path 'caller manifest'

  if ((Get-CffFileSha256 $CffHostLockPath) -cne [string]$handoff.lock_sha256) {
    throw 'Licensed CFF host lock identity drifted.'
  }
  $lock = Get-Content -Raw -LiteralPath $CffHostLockPath | ConvertFrom-Json
  $manifest = Get-Content -Raw -LiteralPath $handoff.manifest_path | ConvertFrom-Json
  if ($lock.approved_manifest_sha256 -cne [string]$handoff.manifest_sha256 -or
      $lock.sdk_inventory_sha256 -cne [string]$handoff.sdk_inventory_sha256 -or
      $manifest.sdk_inventory_sha256 -cne [string]$handoff.sdk_inventory_sha256 -or
      $manifest.sdk_inventories[0].inventory_sha256 -cne
        [string]$handoff.sdk_inventory_sha256 -or
      $handoff.preflight_sdk_inventory_sha256 -cne
        [string]$handoff.sdk_inventory_sha256) {
    throw 'Licensed CFF manifest, lock, or SDK inventory digest drifted.'
  }

  $toolsRoot = [IO.Path]::GetFullPath([string]$handoff.provisioned_tools_root)
  if (-not (Test-Path -LiteralPath $toolsRoot -PathType Container)) {
    throw 'Licensed CFF provisioned-tools root is missing.'
  }
  Assert-CffNoReparsePath $toolsRoot 'provisioned-tools root'
  $provisionedPath = Join-Path $toolsRoot 'provisioned-tools.json'
  $provisioned = Get-Content -Raw -LiteralPath $provisionedPath | ConvertFrom-Json
  if ($provisioned.schema -cne 'cff-provisioned-tools/1.0.0' -or
      $provisioned.provisioning_validated -ne $true -or
      $provisioned.manifest_sha256 -cne [string]$handoff.manifest_sha256 -or
      $provisioned.lock_sha256 -cne [string]$handoff.lock_sha256 -or
      $provisioned.sdk_inventory_sha256 -cne [string]$handoff.sdk_inventory_sha256) {
    throw 'Licensed CFF provisioned-tools contract drifted.'
  }
  $handoffIds = @($handoff.invoked_identities)
  $provisionedIds = @($provisioned.invoked_identities)
  if ($handoffIds.Count -ne 10 -or $provisionedIds.Count -ne $handoffIds.Count) {
    throw 'Licensed CFF invoked-identity cardinality drifted.'
  }
  for ($index = 0; $index -lt $handoffIds.Count; $index++) {
    $expected = $handoffIds[$index]
    $actual = $provisionedIds[$index]
    if ($expected.id -cne $actual.id -or $expected.path -cne $actual.path -or
        $expected.sha256 -cne $actual.sha256 -or
        -not (Test-Path -LiteralPath $expected.path -PathType Leaf) -or
        (Get-CffFileSha256 $expected.path) -cne [string]$expected.sha256) {
      throw "Licensed CFF invoked identity drifted: $($expected.id)"
    }
  }
  $invokedCanonical = $handoffIds | ConvertTo-Json -Depth 5 -Compress
  if ((Get-CffTextSha256 $invokedCanonical) -cne
        [string]$handoff.invoked_identities_sha256 -or
      $provisioned.invoked_identities_sha256 -cne
        [string]$handoff.invoked_identities_sha256) {
    throw 'Licensed CFF invoked-identity set digest drifted.'
  }
  if ((Get-CffFileSha256 $CffFontToolsAdapterPath) -cne
        [string]$handoff.adapter_sha256.fonttools -or
      (Get-CffFileSha256 $CffAfdkoAdapterPath) -cne
        [string]$handoff.adapter_sha256.afdko -or
      (Get-CffFileSha256 $provisioned.ots_sanitize_path) -cne
        [string]$handoff.ots_executable_sha256) {
    throw 'Licensed CFF adapter or OTS executable identity drifted.'
  }
  return [ordered]@{
    handoff = $handoff
    manifest = $manifest
    provisioned = $provisioned
    tools_root = $toolsRoot
  }
}

function Get-CffLicensedSpecimens {
  $cases = Read-CffQualificationJson $CffQualificationCasesPath 'CFF qualification cases'
  Assert-CffQualificationCasesDocument $cases
  Assert-CffLicensedProducerInputs $cases
  $records = @($cases.licensed_intake)
  if (($records.id -join "`n") -cne
      ("source-sans-3.052R","source-han-serif-jp-2.003R" -join "`n")) {
    throw 'Licensed CFF specimen order drifted.'
  }
  return $records
}

function Assert-CffLicensedRecord {
  param([Parameter(Mandatory)]$Record)
  Assert-FontQualificationOrderedKeys $Record @(
    'id','family','tag','archive','member','license_file','profile'
  ) "licensed specimen $($Record.id)"
  Assert-FontQualificationOrderedKeys $Record.archive @('url','length','sha256') (
    "licensed specimen $($Record.id) archive"
  )
  Assert-FontQualificationOrderedKeys $Record.member @('path','length','sha256') (
    "licensed specimen $($Record.id) member"
  )
  Assert-FontQualificationOrderedKeys $Record.license_file @('path','length','sha256') (
    "licensed specimen $($Record.id) license"
  )
  Assert-FontQualificationOrderedKeys $Record.profile @(
    'sfnt_flavor','cff_version','keying','glyph_count','fd_count','used_fds',
    'local_subr_counts','global_subrs','high_gid','high_gid_fd',
    'high_gid_program_tokens'
  ) "licensed specimen $($Record.id) profile"
  if ($Record.archive.url -notmatch
        '^https://github\.com/adobe-fonts/[^/]+/releases/download/' -or
      $Record.archive.url -notmatch ('/' + [regex]::Escape([string]$Record.tag) + '/') -or
      $Record.profile.sfnt_flavor -cne 'OTTO' -or
      $Record.profile.cff_version -cne '1.0') {
    throw "Licensed specimen source/profile contract drifted: $($Record.id)"
  }
  if ($Record.id -ceq 'source-sans-3.052R') {
    if ($Record.tag -cne '3.052R' -or
        $Record.archive.url -cne
          'https://github.com/adobe-fonts/source-sans/releases/download/3.052R/OTF-source-sans-3.052R.zip' -or
        $Record.archive.length -ne 2387997 -or
        $Record.archive.sha256 -cne
          'a4ebbdea20b08ccbd7bf3665a9462454eefdd01d9a6307129d3b3d4672981074' -or
        $Record.member.path -cne 'OTF/SourceSans3-Regular.otf' -or
        $Record.member.length -ne 334924 -or
        $Record.member.sha256 -cne
          '08df266400933d3178d081a45f94a08814c3e55b4b7dd2e0ff69cb1329f13ab6' -or
        $Record.license_file.path -cne 'LICENSE.md' -or
        $Record.license_file.length -ne 4579 -or
        $Record.license_file.sha256 -cne
          '89ad2c4f66dd29127527493e729c31e731f111cf10faf5774c3db9275ed0c22c' -or
        $Record.profile.keying -cne 'name' -or $Record.profile.glyph_count -ne 2478 -or
        (@($Record.profile.local_subr_counts) -join ',') -cne '648' -or
        $Record.profile.global_subrs -ne 738) {
      throw 'Source Sans licensed contract drifted.'
    }
  } elseif ($Record.id -ceq 'source-han-serif-jp-2.003R') {
    if ($Record.tag -cne '2.003R' -or
        $Record.archive.url -cne
          'https://github.com/adobe-fonts/source-han-serif/releases/download/2.003R/12_SourceHanSerifJP.zip' -or
        $Record.archive.length -ne 36831708 -or
        $Record.archive.sha256 -cne
          'c5a3bbc213980cea04932457899c9fc2da4784d3d1d7cae469c41909dd112230' -or
        $Record.member.path -cne 'SubsetOTF/JP/SourceHanSerifJP-Regular.otf' -or
        $Record.member.length -ne 6210796 -or
        $Record.member.sha256 -cne
          'e5f502bb193c28829895b098498f0f9dd8f658c760b0f83656ad41c1137a8785' -or
        $Record.license_file.path -cne 'LICENSE.txt' -or
        $Record.license_file.length -ne 4463 -or
        $Record.license_file.sha256 -cne
          '9ff5bb567e1b92c801fc1069e5fbf992ff8efccacb9db94e5959a5b3ba9bb903' -or
        $Record.profile.keying -cne 'cid' -or $Record.profile.glyph_count -ne 17923 -or
        $Record.profile.fd_count -ne 18 -or
        (@($Record.profile.used_fds) -join ',') -cne ((0..17) -join ',') -or
        (@($Record.profile.local_subr_counts) -join ',') -cne
          '16,46,7,2004,39,131,0,1,7,0,0,205,21626,237,389,17,0,231' -or
        $Record.profile.global_subrs -ne 1599 -or
        $Record.profile.high_gid -ne 17922 -or $Record.profile.high_gid_fd -ne 17 -or
        $Record.profile.high_gid_program_tokens -ne 136) {
      throw 'Source Han licensed contract drifted.'
    }
  } else {
    throw "Unknown licensed specimen: $($Record.id)"
  }
}

function Get-CffArchiveCachePath {
  param(
    [Parameter(Mandatory)]$Context,
    [Parameter(Mandatory)]$Record,
    [switch]$AllowNetwork
  )
  Assert-CffLicensedRecord $Record
  $cacheRoot = Join-Path $Context.tools_root 'licensed-intake-cache'
  [void](New-Item -ItemType Directory -Force -Path $cacheRoot)
  $fileName = [IO.Path]::GetFileName(([uri]$Record.archive.url).AbsolutePath)
  $destination = Join-Path $cacheRoot $fileName
  if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
    if (-not $AllowNetwork) {
      throw "Offline licensed intake cache is missing: $fileName"
    }
    $temporary = "$destination.download-$([guid]::NewGuid().ToString('N'))"
    try {
      Invoke-WebRequest -UseBasicParsing -Uri $Record.archive.url -OutFile $temporary
      $bytes = [IO.File]::ReadAllBytes($temporary)
      Assert-ExactBytesIdentity "$($Record.id) archive" $bytes `
        ([long]$Record.archive.length) ([string]$Record.archive.sha256)
      Move-Item -LiteralPath $temporary -Destination $destination
    } finally {
      if (Test-Path -LiteralPath $temporary) {
        Remove-Item -LiteralPath $temporary -Force
      }
    }
  }
  $archiveBytes = [IO.File]::ReadAllBytes($destination)
  Assert-ExactBytesIdentity "$($Record.id) archive" $archiveBytes `
    ([long]$Record.archive.length) ([string]$Record.archive.sha256)
  return $destination
}

function Get-CffDetachedLicenseCachePath {
  param(
    [Parameter(Mandatory)]$Context,
    [Parameter(Mandatory)]$Record,
    [switch]$AllowNetwork
  )
  if ($Record.id -cne 'source-sans-3.052R') { return $null }
  $url = 'https://raw.githubusercontent.com/adobe-fonts/source-sans/3.052R/LICENSE.md'
  $cacheRoot = Join-Path $Context.tools_root 'licensed-intake-cache'
  [void](New-Item -ItemType Directory -Force -Path $cacheRoot)
  $destination = Join-Path $cacheRoot 'SourceSans-3.052R-LICENSE.md'
  if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
    if (-not $AllowNetwork) {
      throw 'Offline Source Sans retained license cache is missing.'
    }
    $temporary = "$destination.download-$([guid]::NewGuid().ToString('N'))"
    try {
      Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $temporary
      $bytes = [IO.File]::ReadAllBytes($temporary)
      Assert-ExactBytesIdentity 'Source Sans retained tag license' $bytes `
        ([long]$Record.license_file.length) ([string]$Record.license_file.sha256)
      Move-Item -LiteralPath $temporary -Destination $destination
    } finally {
      if (Test-Path -LiteralPath $temporary) {
        Remove-Item -LiteralPath $temporary -Force
      }
    }
  }
  Assert-ExactBytesIdentity 'Source Sans retained tag license' `
    ([IO.File]::ReadAllBytes($destination)) ([long]$Record.license_file.length) `
    ([string]$Record.license_file.sha256)
  return $destination
}

function Assert-CffZipMemberName {
  param([Parameter(Mandatory)][string]$Name)
  $normalized = $Name.Replace('\', '/')
  if (-not $normalized -or $normalized.StartsWith('/') -or
      $normalized -match '^[A-Za-z]:' -or $normalized -match '(^|/)\.\.(/|$)' -or
      $normalized -match '(^|/)\.(/|$)' -or $normalized.IndexOf([char]0) -ge 0) {
    throw "Licensed archive member path is unsafe: $Name"
  }
}

function Assert-CffZipInventory {
  param([Parameter(Mandatory)][object[]]$Entries)
  $names = @{}
  foreach ($entry in $Entries) {
    Assert-CffZipMemberName $entry.FullName
    $folded = $entry.FullName.Replace('\', '/').ToLowerInvariant()
    if ($names.ContainsKey($folded)) {
      throw "Licensed archive has a duplicate or case-colliding member: $($entry.FullName)"
    }
    $names[$folded] = $true
    $unixType = ($entry.ExternalAttributes -shr 16) -band 0xF000
    if ($unixType -eq 0xA000 -or
        ($entry.ExternalAttributes -band [int][IO.FileAttributes]::ReparsePoint) -ne 0) {
      throw "Licensed archive contains a link/reparse member: $($entry.FullName)"
    }
  }
}

function Read-CffLicensedArchiveBundle {
  param(
    [Parameter(Mandatory)][string]$ArchivePath,
    [Parameter(Mandatory)]$Record,
    [string]$DetachedLicensePath
  )
  $archiveBytes = [IO.File]::ReadAllBytes($ArchivePath)
  Assert-ExactBytesIdentity "$($Record.id) archive" $archiveBytes `
    ([long]$Record.archive.length) ([string]$Record.archive.sha256)
  Add-Type -AssemblyName System.IO.Compression
  $stream = [IO.MemoryStream]::new($archiveBytes, $false)
  $archive = [IO.Compression.ZipArchive]::new(
    $stream,
    [IO.Compression.ZipArchiveMode]::Read,
    $false
  )
  try {
    Assert-CffZipInventory @($archive.Entries)
    $fontEntries = @($archive.Entries | Where-Object FullName -CEQ $Record.member.path)
    $licenseEntries = @($archive.Entries |
      Where-Object FullName -CEQ $Record.license_file.path)
    $expectedLicenseEntries = if ($DetachedLicensePath) { 0 } else { 1 }
    if ($fontEntries.Count -ne 1 -or
        $licenseEntries.Count -ne $expectedLicenseEntries) {
      throw "Licensed archive declared member set drifted: $($Record.id)"
    }
    if ($fontEntries[0].Length -ne [long]$Record.member.length -or
        (-not $DetachedLicensePath -and
          $licenseEntries[0].Length -ne [long]$Record.license_file.length)) {
      throw "Licensed archive declared member size drifted: $($Record.id)"
    }
    $result = [ordered]@{}
    $readEntry = {
      param($Entry, $Identity, [string]$Label)
      $input = $Entry.Open()
      $memory = [IO.MemoryStream]::new()
      try {
        $input.CopyTo($memory)
        $bytes = $memory.ToArray()
      } finally {
        $memory.Dispose()
        $input.Dispose()
      }
      Assert-ExactBytesIdentity "$($Record.id) $Label member" $bytes `
        ([long]$Identity.length) ([string]$Identity.sha256)
      return $bytes
    }
    $result.font = [byte[]](& $readEntry $fontEntries[0] $Record.member 'font')
    if ($DetachedLicensePath) {
      $licenseBytes = [IO.File]::ReadAllBytes($DetachedLicensePath)
      Assert-ExactBytesIdentity "$($Record.id) detached license" $licenseBytes `
        ([long]$Record.license_file.length) ([string]$Record.license_file.sha256)
      $result.license = $licenseBytes
    } else {
      $result.license = [byte[]](
        & $readEntry $licenseEntries[0] $Record.license_file 'license'
      )
    }
    return $result
  } finally {
    $archive.Dispose()
    $stream.Dispose()
  }
}

function Invoke-CffPinnedProfileReader {
  param(
    [Parameter(Mandatory)]$Context,
    [Parameter(Mandatory)][string]$FontPath,
    [Parameter(Mandatory)]$Record
  )
  $python = @($Context.provisioned.invoked_identities |
    Where-Object { $_.id -ceq 'runtime.cpython' })[0].path
  $program = @'
import json, pathlib, sys
site, path, high_gid = sys.argv[1], pathlib.Path(sys.argv[2]), int(sys.argv[3])
sys.path.insert(0, site)
from fontTools.ttLib import TTFont
font = TTFont(path, checkChecksums=2, lazy=False, recalcBBoxes=False)
if font.sfntVersion != "OTTO" or "CFF " not in font or "CFF2" in font or "glyf" in font:
    raise RuntimeError("not exact static CFF1")
cff = font["CFF "].cff
top = cff.topDictIndex[0]
ros = list(top.ROS) if getattr(top, "ROS", None) else None
if ros:
    fds = list(top.FDSelect.gidArray)
    local = [len(fd.Private.Subrs) if getattr(fd.Private, "Subrs", None) else 0 for fd in top.FDArray]
else:
    fds = []
    local = [len(top.Private.Subrs) if getattr(top.Private, "Subrs", None) else 0]
tokens = None
high_fd = None
if high_gid >= 0:
    glyph_name = font.getGlyphOrder()[high_gid]
    charstring = top.CharStrings[glyph_name]
    charstring.decompile()
    tokens = len(charstring.program)
    high_fd = fds[high_gid] if fds else None
print(json.dumps({
  "sfnt_flavor":"OTTO","cff_version":"1.0","keying":"cid" if ros else "name",
  "glyph_count":len(font.getGlyphOrder()),"ros":ros,
  "fd_count":len(top.FDArray) if ros else None,
  "used_fds":sorted(set(fds)) if ros else [],
  "local_subr_counts":local,"global_subrs":len(cff.GlobalSubrs),
  "high_gid":high_gid if high_gid >= 0 else None,"high_gid_fd":high_fd,
  "high_gid_program_tokens":tokens
}, separators=(",",":")))
'@
  $highGid = if ($null -eq $Record.profile.high_gid) {
    -1
  } else {
    [int]$Record.profile.high_gid
  }
  $json = & $python -c $program $Context.provisioned.fonttools_site_root `
    $FontPath ([string]$highGid)
  if ($LASTEXITCODE -ne 0) { throw "Pinned CFF profile reader failed: $($Record.id)" }
  return $json | ConvertFrom-Json
}

function Assert-CffLicensedProfile {
  param([Parameter(Mandatory)]$Actual, [Parameter(Mandatory)]$Record)
  $expectedRos = if ($Record.profile.keying -ceq 'cid') {
    @('Adobe','Identity',0)
  } else {
    $null
  }
  if ($Actual.sfnt_flavor -cne $Record.profile.sfnt_flavor -or
      $Actual.cff_version -cne $Record.profile.cff_version -or
      $Actual.keying -cne $Record.profile.keying -or
      $Actual.glyph_count -ne $Record.profile.glyph_count -or
      [string]($Actual.ros | ConvertTo-Json -Compress) -cne
        [string]($expectedRos | ConvertTo-Json -Compress) -or
      [string]$Actual.fd_count -cne [string]$Record.profile.fd_count -or
      (@($Actual.used_fds) -join ',') -cne (@($Record.profile.used_fds) -join ',') -or
      (@($Actual.local_subr_counts) -join ',') -cne
        (@($Record.profile.local_subr_counts) -join ',') -or
      $Actual.global_subrs -ne $Record.profile.global_subrs -or
      [string]$Actual.high_gid -cne [string]$Record.profile.high_gid -or
      [string]$Actual.high_gid_fd -cne [string]$Record.profile.high_gid_fd -or
      [string]$Actual.high_gid_program_tokens -cne
        [string]$Record.profile.high_gid_program_tokens) {
    throw "Licensed CFF profile facts drifted: $($Record.id)"
  }
}

function Get-CffReaderAgreementProjection {
  param([Parameter(Mandatory)]$Value)
  return [ordered]@{
    schema = $Value.schema
    source_sha256 = $Value.source_sha256
    face_index = $Value.face_index
    scalar = $Value.scalar
    gid = $Value.gid
    advance = $Value.advance
    lsb = $Value.lsb
    bounds = @($Value.bounds)
    commands = @($Value.commands | Where-Object { $_.op -cne 'Close' })
    cff_profile = $Value.cff_profile
  }
}

function Invoke-CffLicensedOracleAgreement {
  param(
    [Parameter(Mandatory)]$Context,
    [Parameter(Mandatory)][string]$FontPath,
    [Parameter(Mandatory)]$Record
  )
  $python = @($Context.provisioned.invoked_identities |
    Where-Object { $_.id -ceq 'runtime.cpython' })[0].path
  $fontToolsJson = & $python $CffFontToolsAdapterPath `
    --site-root $Context.provisioned.fonttools_site_root `
    --font $FontPath `
    --scalar U+0041
  if ($LASTEXITCODE -ne 0) { throw "Pinned fontTools reader failed: $($Record.id)" }
  $fontTools = $fontToolsJson | ConvertFrom-Json
  $afdkoJson = & $CffAfdkoAdapterPath `
    -PythonPath $python `
    -AfdkoSiteRoot $Context.provisioned.afdko_site_root `
    -TxRunnerPath $Context.provisioned.tx_runner_path `
    -FontPath $FontPath `
    -Scalar U+0041
  $afdko = $afdkoJson | ConvertFrom-Json
  $left = Get-CffReaderAgreementProjection $fontTools
  $right = Get-CffReaderAgreementProjection $afdko
  if (($left | ConvertTo-Json -Depth 20 -Compress) -cne
      ($right | ConvertTo-Json -Depth 20 -Compress)) {
    throw "Independent licensed CFF semantic readers disagree: $($Record.id)"
  }
  if ($fontTools.keying -cne $Record.profile.keying -or
      $fontTools.source_sha256 -cne $Record.member.sha256) {
    throw "Licensed CFF reader profile/source drifted: $($Record.id)"
  }

  $outputPath = Join-Path $Context.tools_root (
    "licensed-ots-$($Record.id)-$([guid]::NewGuid().ToString('N')).otf"
  )
  $oldPath = $env:PATH
  try {
    $env:PATH = @($Context.manifest.sanitized_environment.PATH) -join ';'
    $otsLog = & $Context.provisioned.ots_sanitize_path $FontPath $outputPath 2>&1
    if ($LASTEXITCODE -ne 0 -or
        -not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
      throw "OTS structural acceptance failed for $($Record.id): $($otsLog -join "`n")"
    }
  } finally {
    $env:PATH = $oldPath
    if (Test-Path -LiteralPath $outputPath) {
      Remove-Item -LiteralPath $outputPath -Force
    }
  }
  return [ordered]@{
    fonttools = $fontTools
    afdko = $afdko
    agreement = $left
    ots_accepted = $true
  }
}

function Get-CffLicensedDestination {
  param([Parameter(Mandatory)]$Record)
  if ($Record.id -ceq 'source-sans-3.052R') {
    return [ordered]@{
      directory = Join-Path $CffLicensedFixtureRoot 'source-sans-3.052r'
      font = 'SourceSans3-Regular.otf'
      license = 'LICENSE.md'
    }
  }
  return [ordered]@{
    directory = Join-Path $CffLicensedFixtureRoot 'source-han-serif-2.003r'
    font = 'SourceHanSerifJP-Regular.otf'
    license = 'LICENSE.txt'
  }
}

function Get-CffCanonicalDestinationSnapshot {
  param([Parameter(Mandatory)][object[]]$Records)
  $snapshot = [ordered]@{}
  foreach ($record in $Records) {
    $destination = Get-CffLicensedDestination $record
    foreach ($name in @($destination.font,$destination.license,'qualification.json')) {
      $path = Join-Path $destination.directory $name
      $key = $path.Substring($RepositoryRoot.Length + 1).Replace('\','/')
      $snapshot[$key] = if (Test-Path -LiteralPath $path -PathType Leaf) {
        Get-CffFileSha256 $path
      } else {
        '<missing>'
      }
    }
  }
  return ($snapshot | ConvertTo-Json -Compress)
}

function Get-CffValidatedLicensedBundles {
  param(
    [Parameter(Mandatory)]$Context,
    [Parameter(Mandatory)][object[]]$Records,
    [switch]$AllowNetwork,
    [switch]$RunOracles
  )
  $stageRoot = Join-Path $Context.tools_root (
    "licensed-intake-stage-$([guid]::NewGuid().ToString('N'))"
  )
  [void](New-Item -ItemType Directory -Path $stageRoot)
  $bundles = [Collections.Generic.List[object]]::new()
  try {
    foreach ($record in $Records) {
      $archivePath = Get-CffArchiveCachePath $Context $record -AllowNetwork:$AllowNetwork
      $detachedLicensePath = Get-CffDetachedLicenseCachePath $Context $record `
        -AllowNetwork:$AllowNetwork
      $bundle = Read-CffLicensedArchiveBundle $archivePath $record `
        -DetachedLicensePath $detachedLicensePath
      $fontPath = Join-Path $stageRoot "$($record.id).otf"
      [IO.File]::WriteAllBytes($fontPath, [byte[]]$bundle.font)
      $profile = Invoke-CffPinnedProfileReader $Context $fontPath $record
      Assert-CffLicensedProfile $profile $record
      $oracles = if ($RunOracles) {
        Invoke-CffLicensedOracleAgreement $Context $fontPath $record
      } else {
        $null
      }
      $bundles.Add([ordered]@{
        record = $record
        font = [byte[]]$bundle.font
        license = [byte[]]$bundle.license
        profile = $profile
        oracles = $oracles
      })
    }
    return @($bundles)
  } finally {
    if (Test-Path -LiteralPath $stageRoot) {
      Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
  }
}

function Publish-CffLicensedBundles {
  param([Parameter(Mandatory)][object[]]$Bundles)
  $states = @()
  foreach ($bundle in $Bundles) {
    $destination = Get-CffLicensedDestination $bundle.record
    $fontPath = Join-Path $destination.directory $destination.font
    $licensePath = Join-Path $destination.directory $destination.license
    $fontExists = Test-Path -LiteralPath $fontPath -PathType Leaf
    $licenseExists = Test-Path -LiteralPath $licensePath -PathType Leaf
    if ($fontExists -xor $licenseExists) {
      throw "Refusing partial licensed destination: $($bundle.record.id)"
    }
    if ($fontExists) {
      Assert-ExactBytesIdentity "$($bundle.record.id) canonical font" `
        ([IO.File]::ReadAllBytes($fontPath)) ([long]$bundle.record.member.length) `
        ([string]$bundle.record.member.sha256)
      Assert-ExactBytesIdentity "$($bundle.record.id) canonical license" `
        ([IO.File]::ReadAllBytes($licensePath)) `
        ([long]$bundle.record.license_file.length) `
        ([string]$bundle.record.license_file.sha256)
    }
    $states += [ordered]@{
      bundle = $bundle
      destination = $destination
      exists = $fontExists
    }
  }
  if (@($states | Where-Object exists).Count -eq $states.Count) {
    return
  }
  if (@($states | Where-Object exists).Count -ne 0) {
    throw 'Refusing a cross-bundle partial licensed publication.'
  }

  $transaction = [guid]::NewGuid().ToString('N')
  $published = [Collections.Generic.List[string]]::new()
  $stageDirectories = [Collections.Generic.List[string]]::new()
  try {
    foreach ($state in $states) {
      $parent = Split-Path -Parent $state.destination.directory
      $stage = Join-Path $parent ".$([IO.Path]::GetFileName($state.destination.directory)).stage-$transaction"
      [void](New-Item -ItemType Directory -Path $stage)
      [IO.File]::WriteAllBytes(
        (Join-Path $stage $state.destination.font),
        [byte[]]$state.bundle.font
      )
      [IO.File]::WriteAllBytes(
        (Join-Path $stage $state.destination.license),
        [byte[]]$state.bundle.license
      )
      $stageDirectories.Add($stage)
    }
    for ($index = 0; $index -lt $states.Count; $index++) {
      Move-Item -LiteralPath $stageDirectories[$index] `
        -Destination $states[$index].destination.directory
      $published.Add($states[$index].destination.directory)
    }
  } catch {
    foreach ($directory in $published) {
      if (Test-Path -LiteralPath $directory -PathType Container) {
        Remove-Item -LiteralPath $directory -Recurse -Force
      }
    }
    throw
  } finally {
    foreach ($stage in $stageDirectories) {
      if (Test-Path -LiteralPath $stage) {
        Remove-Item -LiteralPath $stage -Recurse -Force
      }
    }
  }
}

function Invoke-CffLicensedIntake {
  $context = Assert-CffExecutionHandoff
  $records = @(Get-CffLicensedSpecimens)
  $before = Get-CffCanonicalDestinationSnapshot $records
  $bundles = @(Get-CffValidatedLicensedBundles $context $records `
    -AllowNetwork -RunOracles)
  if ((Get-CffCanonicalDestinationSnapshot $records) -cne $before) {
    throw 'Licensed destinations changed during validation.'
  }
  Publish-CffLicensedBundles $bundles
  Update-OrCheckCffLicensedProvenance
  Write-Host 'Exact Source Sans and Source Han licensed bundles published atomically.'
}

function Invoke-CffIntakeContractCheck {
  $context = Assert-CffExecutionHandoff
  $records = @(Get-CffLicensedSpecimens)
  $before = Get-CffCanonicalDestinationSnapshot $records
  [void](Get-CffValidatedLicensedBundles $context $records -RunOracles)
  if ((Get-CffCanonicalDestinationSnapshot $records) -cne $before) {
    throw 'Offline licensed intake contract mutated a canonical destination.'
  }
  Write-Host 'Licensed CFF staged intake contract passed without publication.'
}

function Invoke-CffIntakeNegatives {
  $context = Assert-CffExecutionHandoff
  $records = @(Get-CffLicensedSpecimens)
  $before = Get-CffCanonicalDestinationSnapshot $records
  $mutations = @(
    @{ id='nearby-tag'; apply={ param($x); $x.tag='3.053R' } },
    @{ id='alternate-url'; apply={ param($x); $x.archive.url='https://example.invalid/font.zip' } },
    @{ id='alternate-member'; apply={ param($x); $x.member.path='OTF/SourceSans3-It.otf' } },
    @{ id='font-digest'; apply={ param($x); $x.member.sha256=('0' * 64) } },
    @{ id='license-digest'; apply={ param($x); $x.license_file.sha256=('0' * 64) } },
    @{ id='keying'; apply={ param($x); $x.profile.keying='cid' } },
    @{ id='reader-incomplete'; apply={ param($x); $x.profile.global_subrs=-1 } }
  )
  foreach ($negative in $mutations) {
    $copy = Copy-CffQualificationDocument $records[0]
    & $negative.apply $copy
    Assert-CffQualificationExpectedFailure {
      Assert-CffLicensedRecord $copy
    } "licensed intake $($negative.id)"
  }
  $cjk = Copy-CffQualificationDocument $records[1]
  $cjk.profile.used_fds = @(0..16)
  Assert-CffQualificationExpectedFailure {
    Assert-CffLicensedRecord $cjk
  } 'licensed intake incomplete FD coverage'
  $cjk = Copy-CffQualificationDocument $records[1]
  $cjk.profile.high_gid = 17921
  Assert-CffQualificationExpectedFailure {
    Assert-CffLicensedRecord $cjk
  } 'licensed intake high GID drift'
  foreach ($unsafe in @('/absolute.otf','C:/device.otf','../escape.otf','a/../b.otf')) {
    Assert-CffQualificationExpectedFailure {
      Assert-CffZipMemberName $unsafe
    } "licensed archive unsafe path $unsafe"
  }
  Assert-CffQualificationExpectedFailure {
    Assert-CffZipInventory @(
      [pscustomobject]@{ FullName='OTF/A.otf'; ExternalAttributes=0 },
      [pscustomobject]@{ FullName='otf/a.OTF'; ExternalAttributes=0 }
    )
  } 'licensed archive case collision'
  Assert-CffQualificationExpectedFailure {
    Assert-CffZipInventory @(
      [pscustomobject]@{
        FullName='OTF/link.otf'
        ExternalAttributes=([int](0xA000 -shl 16))
      }
    )
  } 'licensed archive symbolic link'
  Assert-CffQualificationExpectedFailure {
    Assert-CffZipInventory @(
      [pscustomobject]@{
        FullName='OTF/reparse.otf'
        ExternalAttributes=[int][IO.FileAttributes]::ReparsePoint
      }
    )
  } 'licensed archive reparse point'

  $oldAmbient = $env:MNF_CFF_HOST_TOOLCHAIN_INPUT
  try {
    $env:MNF_CFF_HOST_TOOLCHAIN_INPUT = 'C:\ambient-selection-is-forbidden.json'
    [void](Assert-CffExecutionHandoff)
  } finally {
    $env:MNF_CFF_HOST_TOOLCHAIN_INPUT = $oldAmbient
  }
  Assert-CffQualificationExpectedFailure {
    $script:ExecutionHandoffPath = 'artifacts/release-qualification/phase-107/moved.json'
    [void](Assert-CffExecutionHandoff)
  } 'moved execution handoff'
  $script:ExecutionHandoffPath = $CffExecutionHandoffRelativePath

  if ((Get-CffCanonicalDestinationSnapshot $records) -cne $before) {
    throw 'Licensed intake negatives mutated a canonical destination.'
  }
  Write-Host 'Licensed CFF intake negatives passed with canonical destinations preserved.'
}

function Assert-CffCanonicalLicensedIntake {
  param([switch]$RunOracles)
  $context = Assert-CffExecutionHandoff
  $records = @(Get-CffLicensedSpecimens)
  foreach ($record in $records) {
    $destination = Get-CffLicensedDestination $record
    $fontPath = Join-Path $destination.directory $destination.font
    $licensePath = Join-Path $destination.directory $destination.license
    if (-not (Test-Path -LiteralPath $fontPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $licensePath -PathType Leaf)) {
      throw "Canonical licensed CFF bundle is missing: $($record.id)"
    }
    Assert-ExactBytesIdentity "$($record.id) canonical font" `
      ([IO.File]::ReadAllBytes($fontPath)) ([long]$record.member.length) `
      ([string]$record.member.sha256)
    Assert-ExactBytesIdentity "$($record.id) canonical license" `
      ([IO.File]::ReadAllBytes($licensePath)) ([long]$record.license_file.length) `
      ([string]$record.license_file.sha256)
    $profile = Invoke-CffPinnedProfileReader $context $fontPath $record
    Assert-CffLicensedProfile $profile $record
    if ($RunOracles) {
      [void](Invoke-CffLicensedOracleAgreement $context $fontPath $record)
    }
  }
  Write-Host 'Canonical licensed CFF intake is exact and closed.'
}

function Get-CffLicensedUpstreamFacts {
  param([Parameter(Mandatory)]$Record)
  if ($Record.id -ceq 'source-sans-3.052R') {
    return [ordered]@{
      repository = 'https://github.com/adobe-fonts/source-sans'
      release_tag = '3.052R'
      release_url = 'https://github.com/adobe-fonts/source-sans/releases/tag/3.052R'
      archive_url = [string]$Record.archive.url
      license_url =
        'https://raw.githubusercontent.com/adobe-fonts/source-sans/3.052R/LICENSE.md'
      author = 'Adobe; Source Sans project contributors'
      license = 'OFL-1.1'
      expected_use =
        'Phase 107 licensed Latin static CFF1 interoperability and public-workflow qualification'
    }
  }
  return [ordered]@{
    repository = 'https://github.com/adobe-fonts/source-han-serif'
    release_tag = '2.003R'
    release_url = 'https://github.com/adobe-fonts/source-han-serif/releases/tag/2.003R'
    archive_url = [string]$Record.archive.url
    license_url = [string]$Record.archive.url
    author = 'Adobe; Source Han Serif project contributors'
    license = 'OFL-1.1'
    expected_use =
      'Phase 107 licensed CID-keyed multi-FD CJK static CFF1 interoperability and public-workflow qualification'
  }
}

function New-CffLicensedQualificationDocument {
  param(
    [Parameter(Mandatory)]$Context,
    [Parameter(Mandatory)]$Record,
    [Parameter(Mandatory)]$Profile,
    [Parameter(Mandatory)]$Oracles
  )
  $destination = Get-CffLicensedDestination $Record
  $relativeDirectory = $destination.directory.Substring($RepositoryRoot.Length + 1).
    Replace('\','/')
  $fontPath = "$relativeDirectory/$($destination.font)"
  $noticePath = "$relativeDirectory/$($destination.license)"
  $upstream = Get-CffLicensedUpstreamFacts $Record
  $tools = Read-CffQualificationJson $CffOracleToolsPath 'CFF oracle tools'
  Assert-CffOracleToolsDocument $tools
  $fontToolsPackage = @($tools.packages | Where-Object id -CEQ 'fonttools')[0]
  $afdkoPackage = @($tools.packages | Where-Object id -CEQ 'afdko')[0]
  $invokedById = @{}
  foreach ($identity in @($Context.handoff.invoked_identities)) {
    $invokedById[[string]$identity.id] = [string]$identity.sha256
  }
  return [ordered]@{
    schema = 'cff-licensed-qualification/1.0.0'
    artifact = [ordered]@{
      origin = 'generated'
      source = 'repository-derived:scripts/fixtures/Generate-FontQualification.ps1'
      author = 'MoonBit Native Foundation project generator'
      license = 'Apache-2.0'
      encoding = 'UTF-8 without BOM; LF; exactly one final newline'
    }
    upstream = [ordered]@{
      repository = $upstream.repository
      release_tag = $upstream.release_tag
      release_url = $upstream.release_url
      archive_url = $upstream.archive_url
      archive_length = [long]$Record.archive.length
      archive_sha256 = [string]$Record.archive.sha256
      archive_member = [string]$Record.member.path
      relationship = 'exact-upstream-release-member'
      author = $upstream.author
      license = $upstream.license
      retrieval_date = $CffLicensedRetrievalDate
    }
    font = [ordered]@{
      path = $fontPath
      length = [long]$Record.member.length
      sha256 = [string]$Record.member.sha256
    }
    notice = [ordered]@{
      path = $noticePath
      source_url = $upstream.license_url
      length = [long]$Record.license_file.length
      sha256 = [string]$Record.license_file.sha256
    }
    redistribution = [ordered]@{
      status = 'confirmed'
      expected_use = $upstream.expected_use
    }
    profile = [ordered]@{
      sfnt_flavor = [string]$Profile.sfnt_flavor
      cff_version = [string]$Profile.cff_version
      keying = [string]$Profile.keying
      ros = $Profile.ros
      glyph_count = [int]$Profile.glyph_count
      fd_count = $Profile.fd_count
      used_fds = @($Profile.used_fds)
      local_subr_counts = @($Profile.local_subr_counts)
      global_subrs = [int]$Profile.global_subrs
      high_gid = $Profile.high_gid
      high_gid_fd = $Profile.high_gid_fd
      high_gid_program_tokens = $Profile.high_gid_program_tokens
    }
    semantic_oracles = [ordered]@{
      schema = 'cff-two-reader-agreement/1.0.0'
      scalar = 'U+0041'
      exact_normalized_agreement = $true
      normalized_projection = $Oracles.agreement
      readers = @(
        [ordered]@{
          id = 'fonttools'
          version = [string]$fontToolsPackage.version
          package_sha256 = [string]$fontToolsPackage.sha256
          adapter_sha256 = [string]$Context.handoff.adapter_sha256.fonttools
          invoked_identities = @(
            [ordered]@{
              id = 'runtime.cpython'
              sha256 = $invokedById['runtime.cpython']
            },
            [ordered]@{
              id = 'fonttools-adapter'
              sha256 = $invokedById['fonttools-adapter']
            }
          )
          projection = $Oracles.fonttools
        },
        [ordered]@{
          id = 'afdko'
          version = [string]$afdkoPackage.version
          package_sha256 = [string]$afdkoPackage.sha256
          adapter_sha256 = [string]$Context.handoff.adapter_sha256.afdko
          invoked_identities = @(
            [ordered]@{
              id = 'runtime.cpython'
              sha256 = $invokedById['runtime.cpython']
            },
            [ordered]@{
              id = 'afdko-adapter'
              sha256 = $invokedById['afdko-adapter']
            },
            [ordered]@{
              id = 'tx-runner'
              sha256 = $invokedById['tx-runner']
            }
          )
          projection = $Oracles.afdko
        }
      )
    }
    structural_oracle = [ordered]@{
      id = 'ots'
      role = 'structural-only'
      executable_sha256 = [string]$Context.handoff.ots_executable_sha256
      accepted = [bool]$Oracles.ots_accepted
      semantic_authority = $false
    }
    host_chain = [ordered]@{
      handoff_schema = [string]$Context.handoff.schema
      handoff_sha256 = $CffExecutionHandoffSha256
      manifest_sha256 = [string]$Context.handoff.manifest_sha256
      lock_sha256 = [string]$Context.handoff.lock_sha256
      sdk_inventory_sha256 = [string]$Context.handoff.sdk_inventory_sha256
      invoked_identities_sha256 = [string]$Context.handoff.invoked_identities_sha256
      preflight_validated = $true
      provisioning_validated = $true
    }
  }
}

function Get-CffLicensedManifestRecords {
  param(
    [Parameter(Mandatory)][object[]]$Specimens,
    [Parameter(Mandatory)][hashtable]$QualificationShaById
  )
  $result = [Collections.Generic.List[object]]::new()
  foreach ($record in $Specimens) {
    $destination = Get-CffLicensedDestination $record
    $relativeDirectory = $destination.directory.Substring($RepositoryRoot.Length + 1).
      Replace('\','/')
    $upstream = Get-CffLicensedUpstreamFacts $record
    $result.Add([ordered]@{
      id = "font-$($record.id)"
      path = "$relativeDirectory/$($destination.font)"
      origin = 'external'
      source = [string]$record.archive.url
      author = $upstream.author
      retrieval_date = $CffLicensedRetrievalDate
      sha256 = [string]$record.member.sha256
      license = $upstream.license
      redistribution_status = 'confirmed'
      expected_use = $upstream.expected_use
    })
    $result.Add([ordered]@{
      id = "font-$($record.id)-license"
      path = "$relativeDirectory/$($destination.license)"
      origin = 'external'
      source = $upstream.license_url
      author = $upstream.author
      retrieval_date = $CffLicensedRetrievalDate
      sha256 = [string]$record.license_file.sha256
      license = $upstream.license
      redistribution_status = 'confirmed'
      expected_use = "Retained upstream notice for $($record.family) $($record.tag)"
    })
    $result.Add([ordered]@{
      id = "font-$($record.id)-qualification"
      path = "$relativeDirectory/qualification.json"
      origin = 'generated'
      source = 'repository-derived:scripts/fixtures/Generate-FontQualification.ps1'
      author = 'MoonBit Native Foundation project generator'
      retrieval_date = $CffLicensedRetrievalDate
      sha256 = [string]$QualificationShaById[[string]$record.id]
      license = 'Apache-2.0'
      redistribution_status = 'not-applicable'
      expected_use =
        "Phase 107 closed provenance and independent CFF oracle facts for $($record.family) $($record.tag)"
    })
  }
  return @($result)
}

function Assert-CffLicensedManifestRows {
  param(
    [Parameter(Mandatory)]$Manifest,
    [Parameter(Mandatory)][object[]]$Expected
  )
  $existing = @($Manifest.records)
  $expectedIds = @($Expected.id)
  $indices = [Collections.Generic.List[int]]::new()
  foreach ($id in $expectedIds) {
    $matches = @($existing | Where-Object id -CEQ $id)
    if ($matches.Count -ne 1) {
      throw "Licensed CFF manifest record is missing or duplicated: $id"
    }
    for ($index = 0; $index -lt $existing.Count; $index++) {
      if ($existing[$index].id -ceq $id) { $indices.Add($index); break }
    }
  }
  for ($index = 0; $index -lt $indices.Count; $index++) {
    if ($indices[$index] -ne $indices[0] + $index) {
      throw 'Licensed CFF manifest rows are not adjacent in canonical order.'
    }
    Assert-ManifestRecord $existing[$indices[$index]] $Expected[$index]
  }
}

function Get-CffLicensedQualificationSet {
  $context = Assert-CffExecutionHandoff
  $specimens = @(Get-CffLicensedSpecimens)
  $documents = [ordered]@{}
  $rendered = [ordered]@{}
  foreach ($record in $specimens) {
    $destination = Get-CffLicensedDestination $record
    $fontPath = Join-Path $destination.directory $destination.font
    $licensePath = Join-Path $destination.directory $destination.license
    Assert-ExactBytesIdentity "$($record.id) canonical font" `
      ([IO.File]::ReadAllBytes($fontPath)) ([long]$record.member.length) `
      ([string]$record.member.sha256)
    Assert-ExactBytesIdentity "$($record.id) canonical license" `
      ([IO.File]::ReadAllBytes($licensePath)) ([long]$record.license_file.length) `
      ([string]$record.license_file.sha256)
    $profile = Invoke-CffPinnedProfileReader $context $fontPath $record
    Assert-CffLicensedProfile $profile $record
    $oracles = Invoke-CffLicensedOracleAgreement $context $fontPath $record
    $document = New-CffLicensedQualificationDocument $context $record $profile $oracles
    $documents[[string]$record.id] = $document
    $rendered[[string]$record.id] = ConvertTo-StableJson $document
  }
  return [ordered]@{
    context = $context
    specimens = $specimens
    documents = $documents
    rendered = $rendered
  }
}

function Update-OrCheckCffLicensedProvenance {
  param([switch]$CheckOnly)
  $set = Get-CffLicensedQualificationSet
  $qualificationSha = @{}
  foreach ($record in @($set.specimens)) {
    $text = [string]$set.rendered[[string]$record.id]
    $qualificationSha[[string]$record.id] = Get-CffTextSha256 $text
  }
  $expectedManifest = @(
    Get-CffLicensedManifestRecords @($set.specimens) $qualificationSha
  )

  if ($CheckOnly) {
    foreach ($record in @($set.specimens)) {
      $destination = Get-CffLicensedDestination $record
      $path = Join-Path $destination.directory 'qualification.json'
      if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Licensed CFF qualification document is missing: $($record.id)"
      }
      $actualBytes = [IO.File]::ReadAllBytes($path)
      $expectedBytes = $Utf8NoBom.GetBytes(
        [string]$set.rendered[[string]$record.id]
      )
      if (-not [Linq.Enumerable]::SequenceEqual(
          [byte[]]$actualBytes,
          [byte[]]$expectedBytes
        )) {
        throw "Licensed CFF qualification document drifted: $($record.id)"
      }
      if ((Get-CffFileSha256 $path) -cne
          [string]$qualificationSha[[string]$record.id]) {
        throw "Licensed CFF qualification digest drifted: $($record.id)"
      }
    }
    $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
    Assert-CffLicensedManifestRows $manifest $expectedManifest
    Write-Host 'Licensed CFF provenance, oracle documents, and manifest reconstruct exactly.'
    return
  }

  $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
  $existingIds = @($manifest.records.id)
  $present = @($expectedManifest | Where-Object { $_.id -cin $existingIds })
  $qualificationPresent = @()
  foreach ($record in @($set.specimens)) {
    $destination = Get-CffLicensedDestination $record
    $qualificationPresent += Test-Path -LiteralPath (
      Join-Path $destination.directory 'qualification.json'
    ) -PathType Leaf
  }
  if ($present.Count -ne 0 -or $qualificationPresent -contains $true) {
    if ($present.Count -ne $expectedManifest.Count -or
        $qualificationPresent -contains $false) {
      throw 'Refusing partial licensed CFF provenance publication.'
    }
    $canonicalManifest = (
      ($manifest | ConvertTo-Json -Depth 100).Replace("`r`n", "`n") + "`n"
    )
    [IO.File]::WriteAllText($ManifestPath, $canonicalManifest, $Utf8NoBom)
    Update-OrCheckCffLicensedProvenance -CheckOnly
    return
  }
  $manifest.records = @($manifest.records) + $expectedManifest
  $manifestText = (
    ($manifest | ConvertTo-Json -Depth 100).Replace("`r`n", "`n") + "`n"
  )
  $transaction = [guid]::NewGuid().ToString('N')
  $published = [Collections.Generic.List[string]]::new()
  $temporaryFiles = [Collections.Generic.List[string]]::new()
  try {
    foreach ($record in @($set.specimens)) {
      $destination = Get-CffLicensedDestination $record
      $path = Join-Path $destination.directory 'qualification.json'
      $temporary = "$path.tmp-$transaction"
      [IO.File]::WriteAllText(
        $temporary,
        [string]$set.rendered[[string]$record.id],
        $Utf8NoBom
      )
      $temporaryFiles.Add($temporary)
    }
    $manifestTemporary = "$ManifestPath.tmp-$transaction"
    [IO.File]::WriteAllText($manifestTemporary, $manifestText, $Utf8NoBom)
    $temporaryFiles.Add($manifestTemporary)
    foreach ($temporary in @($temporaryFiles | Select-Object -SkipLast 1)) {
      $destination = $temporary.Substring(0, $temporary.Length - (5 + $transaction.Length))
      Move-Item -LiteralPath $temporary -Destination $destination
      $published.Add($destination)
    }
    Move-Item -LiteralPath $manifestTemporary -Destination $ManifestPath -Force
  } catch {
    foreach ($path in $published) {
      if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }
    throw
  } finally {
    foreach ($path in $temporaryFiles) {
      if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }
  }
  Update-OrCheckCffLicensedProvenance -CheckOnly
}

function Assert-CffProvenanceArtifacts {
  Update-OrCheckCffLicensedProvenance -CheckOnly
}

function Confirm-CffEvidenceRejected {
  param(
    [Parameter(Mandatory)][string]$Label,
    [Parameter(Mandatory)][scriptblock]$Action,
    [Parameter(Mandatory)][string]$Pattern
  )
  $failure = $null
  try {
    & $Action
  } catch {
    $failure = $_.Exception.Message
  }
  if ($null -eq $failure -or $failure -cnotmatch $Pattern) {
    throw "Evidence negative '$Label' did not fail closed as expected: $failure"
  }
}

function Get-CffEvidenceCanonicalRoots {
  return @(
    [IO.Path]::GetFullPath((Join-Path $RepositoryRoot 'modules/mb-core')),
    [IO.Path]::GetFullPath((Join-Path $RepositoryRoot 'modules/mb-font')),
    [IO.Path]::GetFullPath($CffEvidenceRoot)
  )
}

function Assert-CffEvidenceWorkspaceMembers {
  param([Parameter(Mandatory)][string[]]$Members)
  $expected = @(Get-CffEvidenceCanonicalRoots)
  if ($Members.Count -ne $expected.Count) {
    throw 'Evidence workspace member count drifted; registry fallback is forbidden.'
  }
  for ($index = 0; $index -lt $expected.Count; $index++) {
    $actualText = $Members[$index].Replace('\', '/')
    $expectedText = $expected[$index].Replace('\', '/')
    if ($actualText -cne $expectedText) {
      throw "Evidence workspace member $index is not the exact canonical tracked root."
    }
    if (-not (Test-Path -LiteralPath $Members[$index] -PathType Container)) {
      throw "Evidence workspace member $index is missing."
    }
    Assert-CffNoReparsePath $Members[$index] "evidence workspace member $index"
  }
}

function Assert-CffEvidenceManifestContract {
  param(
    [string]$EvidenceManifestPath = $CffEvidenceManifestPath,
    [string]$CoreManifestPath = $CffCoreManifestPath,
    [string]$FontManifestPath = $CffFontManifestPath
  )
  foreach ($path in @($EvidenceManifestPath, $CoreManifestPath, $FontManifestPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw "Evidence module manifest is missing: $path"
    }
    Assert-CffNoReparsePath $path 'evidence module manifest'
  }
  $evidence = Get-Content -Raw -LiteralPath $EvidenceManifestPath | ConvertFrom-Json
  Assert-FontQualificationOrderedKeys $evidence @(
    'name','version','license','preferred-target','supported-targets','deps'
  ) 'CFF evidence module'
  Assert-FontQualificationOrderedKeys $evidence.deps @(
    'tchivs/mb-font'
  ) 'CFF evidence dependency'
  if ($evidence.name -cne 'moonbit-foundation/font-cff-evidence' -or
      $evidence.version -cne '0.0.0' -or
      $evidence.license -cne 'Apache-2.0' -or
      $evidence.'preferred-target' -cne 'native' -or
      $evidence.'supported-targets' -cne '+js+wasm+wasm-gc+native' -or
      $evidence.deps.'tchivs/mb-font' -cne '0.1.0') {
    throw 'CFF evidence module identity, targets, or dependency drifted.'
  }
  if ((Get-CffFileSha256 $CoreManifestPath) -cne $CffCoreManifestSha256) {
    throw 'Tracked mb-core manifest digest drifted.'
  }
  if ((Get-CffFileSha256 $FontManifestPath) -cne $CffFontManifestSha256) {
    throw 'Tracked mb-font manifest digest drifted.'
  }
  $core = Get-Content -Raw -LiteralPath $CoreManifestPath | ConvertFrom-Json
  $font = Get-Content -Raw -LiteralPath $FontManifestPath | ConvertFrom-Json
  if ($core.name -cne 'tchivs/mb-core' -or $core.version -cne '0.1.0' -or
      $font.name -cne 'tchivs/mb-font' -or $font.version -cne '0.1.0') {
    throw 'Tracked local module name or version drifted.'
  }
  Assert-FontQualificationOrderedKeys $font.deps @(
    'tchivs/mb-core'
  ) 'mb-font production dependency'
  if ($font.deps.'tchivs/mb-core' -cne '0.1.0') {
    throw 'mb-font production dependency version drifted.'
  }
}

function Assert-CffEvidenceSourceBoundary {
  param(
    [string]$PackagePath = $CffEvidencePackagePath,
    [string]$WbtestPath = $CffEvidenceWbtestPath
  )
  if (-not (Test-Path -LiteralPath $PackagePath -PathType Leaf) -or
      -not (Test-Path -LiteralPath $WbtestPath -PathType Leaf)) {
    throw 'CFF evidence package or public tracer is missing.'
  }
  $packageText = (Get-Content -Raw -LiteralPath $PackagePath).Replace("`r`n", "`n")
  $expectedPackage = @'
import {
  "moonbitlang/core/bench" @bench,
  "tchivs/mb-font/font" @font,
}

supported_targets = "+js+wasm+wasm-gc+native"
'@.Replace("`r`n", "`n") + "`n"
  if ($packageText -cne $expectedPackage) {
    throw 'CFF evidence package imports, aliases, targets, or export boundary drifted.'
  }
  $sourceText = (Get-Content -Raw -LiteralPath $WbtestPath).Replace("`r`n", "`n")
  if ($sourceText -cmatch '(?m)^\s*pub(?:\([^)]*\))?\s+') {
    throw 'CFF evidence package must not export fixture or evidence symbols.'
  }
  if ($sourceText -cmatch
      '(?i)\b(?:read_file|write_file|open_file|filesystem|subprocess|process|network|http|foreign|extern|ffi)\b') {
    throw 'CFF evidence package contains a forbidden runtime I/O, process, network, or FFI seam.'
  }
  $aliases = @(
    [regex]::Matches($sourceText, '@(?<name>[A-Za-z][A-Za-z0-9_]*)') |
      ForEach-Object { $_.Groups['name'].Value } |
      Select-Object -Unique
  )
  foreach ($alias in $aliases) {
    if ($alias -cne 'font') {
      throw "CFF evidence tracer references a non-font package alias: @$alias"
    }
  }
  $interfacePath = Join-Path $RepositoryRoot 'modules/mb-font/font/pkg.generated.mbti'
  if ((Get-CffFileSha256 $interfacePath) -cne $CffFontPublicInterfaceSha256) {
    throw 'mb-font public interface digest drifted.'
  }
  $interfaceText = Get-Content -Raw -LiteralPath $interfacePath
  $semanticLines = @(
    Get-Content -LiteralPath $interfacePath |
      ForEach-Object { $_.TrimEnd() } |
      Where-Object { $_ -ne '' -and -not $_.TrimStart().StartsWith('//') }
  )
  if ($semanticLines.Count -ne 85) {
    throw 'mb-font public interface semantic line count drifted.'
  }
  $fontRoots = @(
    [regex]::Matches($sourceText, '@font[.](?<name>[A-Za-z][A-Za-z0-9_]*)') |
      ForEach-Object { $_.Groups['name'].Value } |
      Select-Object -Unique
  )
  foreach ($name in $fontRoots) {
    if ($interfaceText -cnotmatch
        "(?m)^pub (?:struct|enum|type|trait) $([regex]::Escape($name))\b" -and
        $interfaceText -cnotmatch
        "(?m)^pub fn $([regex]::Escape($name))(?:::|\()") {
      throw "CFF evidence tracer references a private mb-font symbol: $name"
    }
  }
}

function Remove-CffEvidenceTempRoot {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
  $full = [IO.Path]::GetFullPath($Path)
  $leaf = Split-Path -Leaf $full
  if (-not $full.StartsWith($temp + '\', [StringComparison]::OrdinalIgnoreCase) -or
      -not $leaf.StartsWith('mnf-font-cff-evidence-', [StringComparison]::Ordinal)) {
    throw "Refusing to remove unowned evidence path: $full"
  }
  Remove-Item -LiteralPath $full -Recurse -Force
}

function Invoke-CffEvidenceMoon {
  param([Parameter(Mandatory)][string[]]$Arguments)
  $moon = (Get-Command moon -ErrorAction Stop).Source
  $info = [Diagnostics.ProcessStartInfo]::new()
  $info.FileName = $moon
  $info.UseShellExecute = $false
  $info.RedirectStandardOutput = $true
  $info.RedirectStandardError = $true
  $info.CreateNoWindow = $true
  foreach ($argument in $Arguments) {
    [void]$info.ArgumentList.Add($argument)
  }
  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $info
  [void]$process.Start()
  $stdout = $process.StandardOutput.ReadToEndAsync()
  $stderr = $process.StandardError.ReadToEndAsync()
  if (-not $process.WaitForExit(60000)) {
    $process.Kill($true)
    throw 'Frozen CFF evidence package verification timed out.'
  }
  $stdoutText = $stdout.GetAwaiter().GetResult()
  $stderrText = $stderr.GetAwaiter().GetResult()
  return [pscustomobject]@{
    exit_code = $process.ExitCode
    stdout = $stdoutText
    stderr = $stderrText
  }
}

function Invoke-CffEvidencePackageNegatives {
  $expectedMembers = @(Get-CffEvidenceCanonicalRoots)
  Confirm-CffEvidenceRejected 'omitted mb-font member' {
    Assert-CffEvidenceWorkspaceMembers @($expectedMembers[0], $expectedMembers[2])
  } 'member count drifted'
  Confirm-CffEvidenceRejected 'substituted mb-font member' {
    Assert-CffEvidenceWorkspaceMembers @(
      $expectedMembers[0],
      (Join-Path $RepositoryRoot 'modules/mb-image'),
      $expectedMembers[2]
    )
  } 'not the exact canonical tracked root'
  Confirm-CffEvidenceRejected 'path alias' {
    Assert-CffEvidenceWorkspaceMembers @(
      $expectedMembers[0],
      (Join-Path $RepositoryRoot 'modules/../modules/mb-font'),
      $expectedMembers[2]
    )
  } 'not the exact canonical tracked root'

  $negativeRoot = Join-Path ([IO.Path]::GetTempPath()) (
    'mnf-font-cff-evidence-negative-' + [guid]::NewGuid().ToString('N')
  )
  try {
    [void](New-Item -ItemType Directory -Path $negativeRoot)
    $manifestPath = Join-Path $negativeRoot 'moon.mod.json'
    $packagePath = Join-Path $negativeRoot 'moon.pkg'
    $testPath = Join-Path $negativeRoot 'cff_qualification_wbtest.mbt'
    Copy-Item -LiteralPath $CffEvidenceManifestPath -Destination $manifestPath
    Copy-Item -LiteralPath $CffEvidencePackagePath -Destination $packagePath
    Copy-Item -LiteralPath $CffEvidenceWbtestPath -Destination $testPath

    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $manifest.name = 'moonbit-foundation/font-cff-evidence-renamed'
    [IO.File]::WriteAllText(
      $manifestPath,
      (($manifest | ConvertTo-Json -Depth 10).Replace("`r`n", "`n") + "`n"),
      $Utf8NoBom
    )
    Confirm-CffEvidenceRejected 'wrong evidence name' {
      Assert-CffEvidenceManifestContract -EvidenceManifestPath $manifestPath
    } 'identity, targets, or dependency drifted'

    Copy-Item -LiteralPath $CffEvidenceManifestPath -Destination $manifestPath -Force
    $fontManifestPath = Join-Path $negativeRoot 'mb-font.moon.mod.json'
    Copy-Item -LiteralPath $CffFontManifestPath -Destination $fontManifestPath
    $fontManifest = Get-Content -Raw -LiteralPath $fontManifestPath | ConvertFrom-Json
    $fontManifest.version = '0.1.1'
    [IO.File]::WriteAllText(
      $fontManifestPath,
      (($fontManifest | ConvertTo-Json -Depth 10).Replace("`r`n", "`n") + "`n"),
      $Utf8NoBom
    )
    Confirm-CffEvidenceRejected 'wrong mb-font version and digest' {
      Assert-CffEvidenceManifestContract -FontManifestPath $fontManifestPath
    } 'manifest digest drifted'

    [IO.File]::WriteAllText(
      $testPath,
      ((Get-Content -Raw -LiteralPath $CffEvidenceWbtestPath) +
        "`npub fn leaked_fixture() -> Unit {}`n"),
      $Utf8NoBom
    )
    Confirm-CffEvidenceRejected 'public evidence export' {
      Assert-CffEvidenceSourceBoundary -WbtestPath $testPath
    } 'must not export'

    [IO.File]::WriteAllText(
      $testPath,
      "@font.cff_parse_private()`n",
      $Utf8NoBom
    )
    Confirm-CffEvidenceRejected 'private mb-font symbol' {
      Assert-CffEvidenceSourceBoundary -WbtestPath $testPath
    } 'private mb-font symbol'

    $linkPath = Join-Path $negativeRoot 'mb-font-link'
    try {
      [void](New-Item -ItemType Junction -Path $linkPath -Target $expectedMembers[1])
      Confirm-CffEvidenceRejected 'reparse member' {
        Assert-CffNoReparsePath $linkPath 'evidence workspace member'
      } 'reparse-point'
    } catch {
      if ($_.Exception.Message -notmatch 'Evidence negative') {
        Write-Host 'CFF evidence reparse negative unavailable on this host; path-alias negative remains enforced.'
      } else {
        throw
      }
    }
  } finally {
    Remove-CffEvidenceTempRoot $negativeRoot
  }
}

function Invoke-CffEvidencePackageCheck {
  Assert-CffEvidenceManifestContract
  Assert-CffEvidenceSourceBoundary
  $members = @(Get-CffEvidenceCanonicalRoots)
  Assert-CffEvidenceWorkspaceMembers $members
  $tempRoot = Join-Path ([IO.Path]::GetTempPath()) (
    'mnf-font-cff-evidence-workspace-' + [guid]::NewGuid().ToString('N')
  )
  try {
    [void](New-Item -ItemType Directory -Path $tempRoot)
    $cacheRoot = Join-Path $tempRoot '.repos'
    [void](New-Item -ItemType Directory -Path $cacheRoot)
    $targetRoot = Join-Path $tempRoot 'target'
    $memberLines = @($members | ForEach-Object {
      '  "' + $_.Replace('\', '/') + '",'
    })
    $workspaceText = "members = [`n$($memberLines -join "`n")`n]`n"
    [IO.File]::WriteAllText(
      (Join-Path $tempRoot 'moon.work'),
      $workspaceText,
      $Utf8NoBom
    )
    $result = Invoke-CffEvidenceMoon @(
      '-C', $tempRoot,
      'check', $CffEvidenceRoot,
      '--target', $Target,
      '--frozen',
      '--target-dir', $targetRoot
    )
    if ($result.exit_code -ne 0) {
      throw (
        "Tracked CFF evidence package failed frozen local resolution.`n" +
        $result.stdout + $result.stderr
      )
    }
    if (@(Get-ChildItem -LiteralPath $cacheRoot -Force).Count -ne 0) {
      throw 'CFF evidence package populated the empty external module cache.'
    }
    if ((Get-CffFileSha256 $CffFontManifestPath) -cne $CffFontManifestSha256) {
      throw 'Resolved mb-font source manifest digest drifted after compilation.'
    }
  } finally {
    Remove-CffEvidenceTempRoot $tempRoot
  }
  Invoke-CffEvidencePackageNegatives
  Write-Host (
    "CFF evidence package resolved tracked mb-font under frozen $Target " +
    'with an empty external module cache.'
  )
}

if ($CheckGeneratedTracer) {
  Invoke-CffGeneratedTracerCheck
  return
}

if ($CheckIntakeContract) {
  Invoke-CffIntakeContractCheck
  return
}
if ($CheckIntakeNegatives) {
  Invoke-CffIntakeNegatives
  return
}
if ($CheckLicensedIntake) {
  Assert-CffCanonicalLicensedIntake
  return
}
if ($CheckOracleAgreement) {
  Assert-CffCanonicalLicensedIntake -RunOracles
  return
}
if ($CheckProvenance) {
  Assert-CffProvenanceArtifacts
  return
}
if ($CheckEvidencePackage) {
  Invoke-CffEvidencePackageCheck
  return
}
if ($CheckPublicPrivateBoundary) {
  Assert-CffEvidenceManifestContract
  Assert-CffEvidenceSourceBoundary
  Invoke-CffEvidencePackageNegatives
  Write-Host 'CFF evidence public/private boundary is exact and closed.'
  return
}

if ($CheckContracts -or $CheckGeneratedRecipes -or $CheckOracleAdapters -or
    $CheckSchemaNegatives -or $CheckHostileInventory -or $CheckOutcomeTrace -or
    $CheckBoundaryApplicability) {
  Invoke-CffQualificationContractCheck `
    -Contracts:$CheckContracts `
    -GeneratedRecipes:$CheckGeneratedRecipes `
    -OracleAdapters:$CheckOracleAdapters `
    -SchemaNegatives:$CheckSchemaNegatives `
    -HostileInventory:$CheckHostileInventory `
    -OutcomeTrace:$CheckOutcomeTrace `
    -BoundaryApplicability:$CheckBoundaryApplicability
  return
}

if ($Intake -and $Check) {
  throw '-Intake and -Check are mutually exclusive.'
}
if ($Intake -and $ExecutionHandoffPath) {
  Invoke-CffLicensedIntake
  return
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
Update-OrCheckFontCollectionManifest -CheckOnly:$Check
if ($Check) {
  Update-OrCheckCasesManifest -CheckOnly
  Write-FontQualificationGeneratedSource `
    -FontBytes $fontBytes `
    -CollectionTtcBytes $collectionTtcBytes `
    -Oracle $oracle `
    -CasesDocument $casesDocument `
    -CollectionCasesDocument $collectionCasesDocument `
    -CheckOnly
} else {
  Update-OrCheckCasesManifest
  Write-FontQualificationGeneratedSource `
    -FontBytes $fontBytes `
    -CollectionTtcBytes $collectionTtcBytes `
    -Oracle $oracle `
    -CasesDocument $casesDocument `
    -CollectionCasesDocument $collectionCasesDocument
}
Assert-FontCollectionManifestContract
Assert-FontCollectionGeneratedSourceContract
Write-Host 'Font qualification intake, oracle, hostile matrix, and generated source verification passed.'
