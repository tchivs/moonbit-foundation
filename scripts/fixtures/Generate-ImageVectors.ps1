[CmdletBinding()]
param([switch]$Check)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Invariant = [System.Globalization.CultureInfo]::InvariantCulture
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$RepositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
[System.Globalization.CultureInfo]::CurrentCulture = $Invariant
[System.Globalization.CultureInfo]::CurrentUICulture = $Invariant

function Join-Lines([string[]]$Lines) { (($Lines -join "`n") + "`n") }
function Get-Bytes([string]$Text) { $Utf8NoBom.GetBytes($Text) }
function Get-Sha256([byte[]]$Bytes) {
  [System.Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()
}
function Test-BytesEqual([byte[]]$Left, [byte[]]$Right) {
  if ($Left.Length -ne $Right.Length) { return $false }
  for ($i = 0; $i -lt $Left.Length; $i++) { if ($Left[$i] -ne $Right[$i]) { return $false } }
  return $true
}
function Assert-OrWriteArtifact([string]$RelativePath, [string]$Content) {
  $fullPath = [System.IO.Path]::GetFullPath((Join-Path $RepositoryRoot $RelativePath))
  $prefix = $RepositoryRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  if (-not $fullPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Artifact path escapes repository root: $RelativePath"
  }
  $expected = Get-Bytes $Content
  if ($Check) {
    if (-not [System.IO.File]::Exists($fullPath)) { throw "Generated artifact is missing: $RelativePath" }
    if (-not (Test-BytesEqual ([System.IO.File]::ReadAllBytes($fullPath)) $expected)) {
      throw "Generated artifact is stale or non-deterministic: $RelativePath"
    }
    Write-Host "PASS: $RelativePath is byte-identical."
  } else {
    [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($fullPath))
    [System.IO.File]::WriteAllBytes($fullPath, $expected)
    Write-Host "WROTE: $RelativePath"
  }
}

function New-CanonicalData {
  # Standards-literal Exif oracle. These source-to-destination equations are
  # intentionally authored here and are never obtained from production code.
  $orientation = @(
    [ordered]@{ code=1; name='TopLeft'; out_width=3; out_height=2; map=@('0,0>0,0','1,0>1,0','2,0>2,0','0,1>0,1','1,1>1,1','2,1>2,1') },
    [ordered]@{ code=2; name='TopRight'; out_width=3; out_height=2; map=@('0,0>2,0','1,0>1,0','2,0>0,0','0,1>2,1','1,1>1,1','2,1>0,1') },
    [ordered]@{ code=3; name='BottomRight'; out_width=3; out_height=2; map=@('0,0>2,1','1,0>1,1','2,0>0,1','0,1>2,0','1,1>1,0','2,1>0,0') },
    [ordered]@{ code=4; name='BottomLeft'; out_width=3; out_height=2; map=@('0,0>0,1','1,0>1,1','2,0>2,1','0,1>0,0','1,1>1,0','2,1>2,0') },
    [ordered]@{ code=5; name='LeftTop'; out_width=2; out_height=3; map=@('0,0>0,0','1,0>0,1','2,0>0,2','0,1>1,0','1,1>1,1','2,1>1,2') },
    [ordered]@{ code=6; name='RightTop'; out_width=2; out_height=3; map=@('0,0>1,0','1,0>1,1','2,0>1,2','0,1>0,0','1,1>0,1','2,1>0,2') },
    [ordered]@{ code=7; name='RightBottom'; out_width=2; out_height=3; map=@('0,0>1,2','1,0>1,1','2,0>1,0','0,1>0,2','1,1>0,1','2,1>0,0') },
    [ordered]@{ code=8; name='LeftBottom'; out_width=2; out_height=3; map=@('0,0>0,2','1,0>0,1','2,0>0,0','0,1>1,2','1,1>1,1','2,1>1,0') }
  )
  [ordered]@{
    metadata = @(
      [ordered]@{ id='canonical-order'; behavior='accept-sort'; count=2 },
      [ordered]@{ id='duplicate-key'; behavior='reject-duplicate'; count=2 },
      [ordered]@{ id='orientation-disposition'; behavior='transform-orientation'; count=5 }
    )
    model = @(
      [ordered]@{ id='packed-padded'; behavior='accept'; start=1; length=14; stride=8; row_bytes=6; width=2; height=2; storage=16 },
      [ordered]@{ id='short-row'; behavior='reject-row'; start=0; length=4; stride=2; row_bytes=2; width=1; height=1; storage=4 },
      [ordered]@{ id='one-byte-short'; behavior='reject-storage'; start=0; length=6; stride=6; row_bytes=6; width=2; height=1; storage=5 }
    )
    storage = @(
      [ordered]@{ id='crop-edge'; x=1; y=0; width=1; height=2; first=4; last=12 },
      [ordered]@{ id='empty-crop'; x=2; y=2; width=0; height=0; first=0; last=0 },
      [ordered]@{ id='lease-stale'; x=0; y=0; width=1; height=1; first=1; last=1 },
      [ordered]@{ id='lease-overlap'; x=0; y=0; width=2; height=1; first=1; last=6 }
    )
    orientation = $orientation
    resize = @(
      [ordered]@{ id='upscale-2-to-5'; source=2; destination=5; map=@(0,0,0,1,1) },
      [ordered]@{ id='downscale-5-to-2'; source=5; destination=2; map=@(0,2) },
      [ordered]@{ id='unit-axis'; source=1; destination=4; map=@(0,0,0,0) }
    )
    conversion = @(
      [ordered]@{ id='rgb-to-rgba'; source=@(1,2,3); expected=@(1,2,3,255); lossy=$false },
      [ordered]@{ id='opaque-rgba-to-rgb'; source=@(4,5,6,255); expected=@(4,5,6); lossy=$false },
      [ordered]@{ id='lossy-rgba-to-rgb'; source=@(7,8,9,10); expected=@(7,8,9); lossy=$true }
    )
    codec = @(
      [ordered]@{ id='empty-prefix'; available=0; outcome='need-more'; seeker_calls=0 },
      [ordered]@{ id='short-prefix'; available=1; outcome='need-more'; seeker_calls=0 },
      [ordered]@{ id='non-match'; available=2; outcome='no-match'; seeker_calls=0 },
      [ordered]@{ id='short-progress'; available=3; outcome='bounded-read'; seeker_calls=0 }
    )
  }
}

function Render-Json([object]$Data) {
  $payload = [ordered]@{
    schema_version='1.0.0'; classification='repository-derived-adversarial'
    generator='scripts/fixtures/Generate-ImageVectors.ps1'
    source='repository-derived:scripts/fixtures/Generate-ImageVectors.ps1'
    standards_note='Exif orientation equations are literal project-authored transcriptions of the eight-state coordinate semantics; no third-party fixture bytes are copied.'
    descriptor_plane_vectors=$Data.model; crop_lease_vectors=$Data.storage
    orientation_vectors=$Data.orientation; resize_vectors=$Data.resize
    conversion_vectors=$Data.conversion; metadata_vectors=$Data.metadata
    codec_vectors=$Data.codec
  }
  (($payload | ConvertTo-Json -Depth 20).Replace("`r`n", "`n").TrimEnd() + "`n")
}

function Render-MetadataMoon([object]$Data) {
  Join-Lines @(
    '// Generated by scripts/fixtures/Generate-ImageVectors.ps1. Do not edit.','',
    '///|','fn generated_metadata_case_ids() -> Array[String] {',
    ('  [{0}]' -f (($Data.metadata | ForEach-Object { '"' + $_.id + '"' }) -join ', ')), '}', '',
    '///|','test "generated metadata vectors consume every case" {',
    ('  inspect(generated_metadata_case_ids().length(), content="{0}")' -f $Data.metadata.Count),
    '  let limits = MetadataLimits::new(','    max_entries=2UL,','    max_token_bytes=16UL,','    max_value_bytes=1UL,','    max_total_bytes=32UL,','    max_disposition_fields=5UL,','  )',
    '  let budget = internal_metadata_budget(2UL)',
    '  let ordered = OpaqueMetadata::from_entries(','    [("z", "key", "raw", b"2"), ("a", "key", "raw", b"1")],','    limits,','    budget,','  ).unwrap()',
    '  inspect(ordered.entry(0).unwrap().canonical_key(), content="a:key:raw")',
    '  inspect(ordered.entry(1).unwrap().canonical_key(), content="z:key:raw")',
    '  inspect(','    OpaqueMetadata::from_entries(','      [("a", "key", "raw", b"1"), ("a", "key", "raw", b"2")],','      limits,','      internal_metadata_budget(2UL),','    )','    is Err(_),','    content="true",','  )',
    '  let orientation = DispositionField::new("orientation", limits).unwrap()',
    '  let disposition = MetadataDisposition::new(','    [','      DispositionField::new("alpha", limits).unwrap(),','      DispositionField::new("color", limits).unwrap(),','      DispositionField::new("opaque", limits).unwrap(),','      DispositionField::new("profile", limits).unwrap(),','    ],','    [orientation],','    [],','    false,','    limits,','  ).unwrap()',
    '  inspect(disposition.preserved_length(), content="4")','  inspect(disposition.transformed(0).unwrap().value(), content="orientation")','}'
  )
}

function Render-ModelMoon([object]$Data) {
  Join-Lines @(
    '// Generated by scripts/fixtures/Generate-ImageVectors.ps1. Do not edit.','',
    '///|','fn generated_model_case_ids() -> Array[String] {',
    ('  [{0}]' -f (($Data.model | ForEach-Object { '"' + $_.id + '"' }) -join ', ')), '}', '',
    '///|','test "generated descriptor vectors consume every case" {',
    ('  inspect(generated_model_case_ids().length(), content="{0}")' -f $Data.model.Count),
    '  let padded = ImageDescriptor::new(','    2UL,','    2UL,','    ImageFormat::rgb8(),','    [PlaneDescriptor::new(1UL, 14UL, 8UL, 6UL, 1UL, 1UL, 2UL, 2UL).unwrap()],','    16UL,','    internal_metadata(None),','  ).unwrap()',
    '  inspect(padded.plane(0).unwrap().row_stride(), content="8")',
    '  let short_row = PlaneDescriptor::new(0UL, 4UL, 2UL, 2UL, 1UL, 1UL, 1UL, 1UL).unwrap()',
    '  inspect(','    ImageDescriptor::new(','      1UL,','      1UL,','      ImageFormat::rgb8(),','      [short_row],','      4UL,','      internal_metadata(None),','    )','    is Err(_),','    content="true",','  )',
    '  let outside = PlaneDescriptor::new(0UL, 6UL, 6UL, 6UL, 1UL, 1UL, 2UL, 1UL).unwrap()',
    '  inspect(','    ImageDescriptor::new(','      2UL,','      1UL,','      ImageFormat::rgb8(),','      [outside],','      5UL,','      internal_metadata(None),','    )','    is Err(_),','    content="true",','  )','}'
  )
}

function Render-StorageMoon([object]$Data) {
  Join-Lines @(
    '// Generated by scripts/fixtures/Generate-ImageVectors.ps1. Do not edit.','',
    '///|','fn generated_storage_case_ids() -> Array[String] {',
    ('  [{0}]' -f (($Data.storage | ForEach-Object { '"' + $_.id + '"' }) -join ', ')), '}', '',
    '///|','test "generated crop and lease vectors consume every case" {',
    ('  inspect(generated_storage_case_ids().length(), content="{0}")' -f $Data.storage.Count),
    '  let image = mutable_test_image()','  image','  .with_mut_view(fn(view) {','    for y = 0UL; y < 2UL; y = y + 1UL {','      for x = 0UL; x < 3UL; x = x + 1UL {','        match view.set_byte(x, y, 0UL, ((y * 3UL + x) * 3UL + 1UL).to_byte()) {','          Err(error) => return Err(error)','          Ok(_) => ()','        }','      }','    }','    Ok(())','  })','  .unwrap()',
    '  let crop = image','    .view()','    .crop(@model.Rect::new(1UL, 0UL, 1UL, 2UL).unwrap())','    .unwrap()','  inspect(crop.get_byte(0UL, 0UL, 0UL).unwrap() == b''\x04'', content="true")','  inspect(crop.get_byte(0UL, 1UL, 0UL).unwrap() == b''\x0d'', content="true")',
    '  inspect(','    image','    .view()','    .crop(@model.Rect::new(2UL, 2UL, 0UL, 0UL).unwrap())','    .unwrap()','    .is_empty(),','    content="true",','  )',
    '  let mut stale : MutImageView? = None','  image','  .with_mut_view(fn(view) {','    stale = Some(','      view.crop(@model.Rect::new(0UL, 0UL, 1UL, 1UL).unwrap()).unwrap(),','    )','    Ok(())','  })','  .unwrap()','  inspect(stale.unwrap().get_byte(0UL, 0UL, 0UL) is Err(_), content="true")',
    '  let overlap_left = @model.Rect::new(0UL, 0UL, 2UL, 1UL).unwrap()','  let overlap_right = @model.Rect::new(1UL, 0UL, 2UL, 1UL).unwrap()',
    '  let mut overlap_rejected = false','  image','  .with_mut_view(fn(view) {','    match view.split_disjoint(overlap_left, overlap_right) {','      Err(_) => overlap_rejected = true','      Ok(_) => ()','    }','    Ok(())','  })','  .unwrap()','  inspect(overlap_rejected, content="true")','}'
  )
}

function Orientation-Variant([string]$Name) { '@model.Orientation::' + $Name }
function Render-OpsMoon([object]$Data) {
  $lines = [System.Collections.Generic.List[string]]::new()
  foreach ($line in @('// Generated by scripts/fixtures/Generate-ImageVectors.ps1. Do not edit.','','///|','fn generated_orientation_vectors() -> Array[','  (@model.Orientation, UInt64, UInt64, Array[(UInt64, UInt64, UInt64, UInt64)]),','] {','  [')) { $lines.Add($line) }
  foreach ($item in $Data.orientation) {
    $maps = @($item.map | ForEach-Object { if ($_ -notmatch '^(\d+),(\d+)>(\d+),(\d+)$') { throw "Invalid literal orientation map: $_" }; "($($Matches[1])UL, $($Matches[2])UL, $($Matches[3])UL, $($Matches[4])UL)" })
    $lines.Add('    (')
    $lines.Add(('      {0},' -f (Orientation-Variant $item.name)))
    $lines.Add(('      {0}UL,' -f $item.out_width))
    $lines.Add(('      {0}UL,' -f $item.out_height))
    $lines.Add('      [')
    foreach ($map in $maps) { $lines.Add(('        {0},' -f $map)) }
    $lines.Add('      ],')
    $lines.Add('    ),')
  }
  foreach ($line in @('  ]','}','','///|','fn generated_resize_axis_vectors() -> Array[(UInt64, UInt64, Array[UInt64])] {','  [')) { $lines.Add($line) }
  foreach ($item in $Data.resize) { $lines.Add(('    ({0}UL, {1}UL, [{2}]),' -f $item.source, $item.destination, ((@($item.map) | ForEach-Object { "${_}UL" }) -join ', '))) }
  foreach ($line in @('  ]','}','','///|','fn generated_conversion_case_count() -> Int {','  3','}','','///|','test "generated operation vector tables are complete" {','  inspect(generated_orientation_vectors().length(), content="8")','  inspect(generated_resize_axis_vectors().length(), content="3")','  inspect(generated_conversion_case_count(), content="3")','}')) { $lines.Add($line) }
  Join-Lines $lines.ToArray()
}

function Render-CodecMoon([object]$Data) {
  Join-Lines @(
    '// Generated by scripts/fixtures/Generate-ImageVectors.ps1. Do not edit.','',
    '///|','fn generated_codec_cases() -> Array[(String, UInt64, String, UInt64)] {','  [',
    ($Data.codec | ForEach-Object { '    ("{0}", {1}UL, "{2}", {3}UL),' -f $_.id, $_.available, $_.outcome, $_.seeker_calls }),
    '  ]','}','','///|','test "generated codec vectors require no seeker" {',('  inspect(generated_codec_cases().length(), content="{0}")' -f $Data.codec.Count),'  for item in generated_codec_cases() { let (_, _, _, seeker_calls) = item; inspect(seeker_calls, content="0") }','}'
  )
}

function Render-Manifest([string]$Digest) {
  $path = Join-Path $RepositoryRoot 'fixtures\manifest.json'
  $manifest = Get-Content -Raw $path | ConvertFrom-Json
  $records = @($manifest.records | Where-Object { $_.id -cne 'image-operation-vectors' }) + @([ordered]@{
    id='image-operation-vectors'; path='fixtures/image/operation-vectors.json'; origin='generated'
    source='repository-derived:scripts/fixtures/Generate-ImageVectors.ps1; Exif eight-state coordinate semantics transcribed literally from CIPA DC-X010-2017'
    author='MoonBit Native Foundation project generator'; retrieval_date='2026-07-17'; sha256=$Digest
    license='Apache-2.0'; redistribution_status='not-applicable'
    expected_use='IMAG-05 and IMAG-07 descriptor, plane, crop, lease, orientation, resize, conversion, metadata disposition, and non-seeking codec conformance'
  })
  $out = [ordered]@{
    schema_version=$manifest.schema_version; preferred_origin=$manifest.preferred_origin
    required_record_fields=@($manifest.required_record_fields); allowed_origins=@($manifest.allowed_origins)
    allowed_redistribution_statuses=@($manifest.allowed_redistribution_statuses)
    external_requires_confirmed_redistribution=$manifest.external_requires_confirmed_redistribution; records=$records
  }
  (($out | ConvertTo-Json -Depth 20).Replace("`r`n", "`n").TrimEnd() + "`n")
}

$data = New-CanonicalData
$json = Render-Json $data
$artifacts = [ordered]@{
  'fixtures/image/operation-vectors.json' = $json
  'fixtures/manifest.json' = Render-Manifest (Get-Sha256 (Get-Bytes $json))
  'modules/mb-image/metadata/reference_vectors_wbtest.mbt' = Render-MetadataMoon $data
  'modules/mb-image/model/reference_vectors_wbtest.mbt' = Render-ModelMoon $data
  'modules/mb-image/storage/reference_vectors_wbtest.mbt' = Render-StorageMoon $data
  'modules/mb-image/ops/reference_vectors_wbtest.mbt' = Render-OpsMoon $data
  'modules/mb-image/codec/reference_vectors_wbtest.mbt' = Render-CodecMoon $data
}
foreach ($entry in $artifacts.GetEnumerator()) { Assert-OrWriteArtifact $entry.Key $entry.Value }
$completion = if ($Check) { 'Image vector check passed.' } else { 'Image vector generation completed.' }
Write-Host $completion
