[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('fixtures', 'transfer', 'quantize', 'alpha', 'profile', 'all')]
  [string]$Artifacts,

  [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Invariant = [System.Globalization.CultureInfo]::InvariantCulture
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$RepositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
[System.Globalization.CultureInfo]::CurrentCulture = $Invariant
[System.Globalization.CultureInfo]::CurrentUICulture = $Invariant

function Format-JsonNumber([double]$Value) {
  if ([double]::IsNaN($Value) -or [double]::IsInfinity($Value)) {
    throw 'JSON fixture numbers must be finite.'
  }
  return $Value.ToString('R', $Invariant).Replace('E', 'e')
}

function Format-MoonDouble([double]$Value) {
  $text = Format-JsonNumber $Value
  if ($text -notmatch '[.e]') { $text += '.0' }
  return $text
}

function Escape-Json([string]$Value) {
  $builder = [System.Text.StringBuilder]::new()
  foreach ($character in $Value.ToCharArray()) {
    switch ([int]$character) {
      8 { [void]$builder.Append('\b') }
      9 { [void]$builder.Append('\t') }
      10 { [void]$builder.Append('\n') }
      12 { [void]$builder.Append('\f') }
      13 { [void]$builder.Append('\r') }
      34 { [void]$builder.Append('\"') }
      92 { [void]$builder.Append('\\') }
      default {
        if ([int]$character -lt 0x20) {
          [void]$builder.Append(('\u{0:x4}' -f [int]$character))
        } else {
          [void]$builder.Append($character)
        }
      }
    }
  }
  return $builder.ToString()
}

function Quote-Json([string]$Value) {
  return '"' + (Escape-Json $Value) + '"'
}

function Join-Lines([string[]]$Lines) {
  return (($Lines -join "`n") + "`n")
}

function Get-Bytes([string]$Text) {
  return $Utf8NoBom.GetBytes($Text)
}

function Get-Sha256([byte[]]$Bytes) {
  $hash = [System.Security.Cryptography.SHA256]::HashData($Bytes)
  return [System.Convert]::ToHexString($hash).ToLowerInvariant()
}

function Test-BytesEqual([byte[]]$Left, [byte[]]$Right) {
  if ($Left.Length -ne $Right.Length) { return $false }
  for ($index = 0; $index -lt $Left.Length; $index++) {
    if ($Left[$index] -ne $Right[$index]) { return $false }
  }
  return $true
}

function Assert-OrWriteArtifact([string]$RelativePath, [string]$Content) {
  $fullPath = [System.IO.Path]::GetFullPath((Join-Path $RepositoryRoot $RelativePath))
  $rootPrefix = $RepositoryRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
  if (-not $fullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Artifact path escapes repository root: $RelativePath"
  }

  $expected = Get-Bytes $Content
  if ($Check) {
    if (-not [System.IO.File]::Exists($fullPath)) {
      throw "Generated artifact is missing: $RelativePath"
    }
    $actual = [System.IO.File]::ReadAllBytes($fullPath)
    if (-not (Test-BytesEqual $actual $expected)) {
      throw "Generated artifact is stale or non-deterministic: $RelativePath"
    }
    Write-Host "PASS: $RelativePath is byte-identical."
    return
  }

  [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($fullPath))
  [System.IO.File]::WriteAllBytes($fullPath, $expected)
  Write-Host "WROTE: $RelativePath"
}

function Decode-Srgb([double]$Encoded) {
  if ($Encoded -le 0.04045) { return $Encoded / 12.92 }
  return [Math]::Pow(($Encoded + 0.055) / 1.055, 2.4)
}

function Encode-Srgb([double]$Linear) {
  if ($Linear -le 0.0031308) { return 12.92 * $Linear }
  return 1.055 * [Math]::Pow($Linear, 1.0 / 2.4) - 0.055
}

function Round-RatioTiesEven([uint64]$Numerator, [uint64]$Denominator) {
  if ($Denominator -eq 0) { throw 'Ratio denominator must be nonzero.' }
  $quotient = [uint64]($Numerator / $Denominator)
  $remainder = [uint64]($Numerator % $Denominator)
  $twiceRemainder = [uint64]($remainder * 2)
  if ($twiceRemainder -lt $Denominator) { return $quotient }
  if ($twiceRemainder -gt $Denominator) { return [uint64]($quotient + 1) }
  if (($quotient % 2) -eq 0) { return $quotient }
  return [uint64]($quotient + 1)
}

function New-CanonicalData {
  $decodeInputs = @(0.0, 0.0031308, 0.040449, 0.04045, 0.040451, 0.5, 1.0)
  $encodeInputs = @(0.0, 0.0031298, 0.0031308, 0.0031318, (0.04045 / 12.92), 0.21404114048223255, 1.0)
  $decode = @()
  for ($index = 0; $index -lt $decodeInputs.Count; $index++) {
    $encoded = [double]$decodeInputs[$index]
    $decode += [ordered]@{ id = "decode-$index"; encoded = $encoded; linear = (Decode-Srgb $encoded) }
  }
  $encode = @()
  for ($index = 0; $index -lt $encodeInputs.Count; $index++) {
    $linear = [double]$encodeInputs[$index]
    $encode += [ordered]@{ id = "encode-$index"; linear = $linear; encoded = (Encode-Srgb $linear) }
  }

  $quantize = @(
    [ordered]@{ id='scaled-half-0'; normalized=(0.5 / 255.0); expected=0 },
    [ordered]@{ id='scaled-half-1'; normalized=(1.5 / 255.0); expected=2 },
    [ordered]@{ id='scaled-half-2'; normalized=(2.5 / 255.0); expected=2 },
    [ordered]@{ id='below-half-2'; normalized=(2.5 - 1.0e-12) / 255.0; expected=2 },
    [ordered]@{ id='above-half-2'; normalized=(2.5 + 1.0e-12) / 255.0; expected=3 },
    [ordered]@{ id='endpoint-zero'; normalized=0.0; expected=0 },
    [ordered]@{ id='endpoint-one'; normalized=1.0; expected=255 }
  )

  $ratios = @(
    [ordered]@{ id='tie-zero-even'; numerator=1UL; denominator=2UL; expected=0UL },
    [ordered]@{ id='tie-two-up'; numerator=3UL; denominator=2UL; expected=2UL },
    [ordered]@{ id='tie-two-down'; numerator=5UL; denominator=2UL; expected=2UL },
    [ordered]@{ id='below-half'; numerator=4UL; denominator=3UL; expected=1UL },
    [ordered]@{ id='above-half'; numerator=5UL; denominator=3UL; expected=2UL }
  )

  $alpha = @(
    [ordered]@{ id='zero-alpha'; component=255; alpha=0; premultiplied=0; unpremultiplied=0 },
    [ordered]@{ id='unit-alpha'; component=255; alpha=1; premultiplied=1; unpremultiplied=255 },
    [ordered]@{ id='mid-alpha'; component=255; alpha=128; premultiplied=128; unpremultiplied=255 },
    [ordered]@{ id='near-opaque'; component=128; alpha=254; premultiplied=127; unpremultiplied=128 },
    [ordered]@{ id='opaque'; component=173; alpha=255; premultiplied=173; unpremultiplied=173 }
  )
  foreach ($case in $alpha) {
    if ($case.alpha -ne 0) {
      $case.premultiplied = [int](Round-RatioTiesEven ([uint64]($case.component * $case.alpha)) 255UL)
      $case.unpremultiplied = [int](Round-RatioTiesEven ([uint64]($case.premultiplied * 255)) ([uint64]$case.alpha))
    }
  }

  $profile = [ordered]@{
    accepted_tags = @('a', 'icc', 'ICC-v4.4_test+1', ('z' * 32))
    rejected_tags = @('', '-icc', 'contains space', ('z' * 33), "icc`u{00e9}")
    payload_cases = @(
      [ordered]@{ id='empty'; bytes=@(); maximum=0; should_succeed=$true },
      [ordered]@{ id='exact-limit'; bytes=@(0, 1, 127, 255); maximum=4; should_succeed=$true },
      [ordered]@{ id='one-over-limit'; bytes=@(0, 1, 2, 3, 4); maximum=4; should_succeed=$false },
      [ordered]@{ id='opaque-icc-shaped'; bytes=@(0, 0, 0, 132, 109, 110, 116, 114); maximum=8; should_succeed=$true }
    )
  }

  return [ordered]@{ decode=$decode; encode=$encode; quantize=$quantize; ratios=$ratios; alpha=$alpha; profile=$profile }
}

function Render-SrgbJson([object]$Data) {
  $lines = [System.Collections.Generic.List[string]]::new()
  foreach ($line in @(
    '{',
    '  "schema_version": "1.0.0",',
    '  "classification": "primary-formula-derived",',
    '  "generator": "scripts/fixtures/Generate-ColorVectors.ps1",',
    '  "formula_sources": [',
    '    "https://www.w3.org/TR/css-color-4/#color-conversion-code",',
    '    "https://registry.color.org/rgb-registry/files/sRGB.pdf"',
    '  ],',
    '  "notes": "Values are computed by the project generator from published formulas; no third-party fixture bytes are copied.",',
    '  "decode_vectors": ['
  )) { $lines.Add($line) }
  for ($index = 0; $index -lt $Data.decode.Count; $index++) {
    $item = $Data.decode[$index]
    $comma = if ($index -lt $Data.decode.Count - 1) { ',' } else { '' }
    $lines.Add(('    {{ "id": {0}, "encoded": {1}, "linear": {2} }}{3}' -f (Quote-Json $item.id), (Format-JsonNumber $item.encoded), (Format-JsonNumber $item.linear), $comma))
  }
  $lines.Add('  ],')
  $lines.Add('  "encode_vectors": [')
  for ($index = 0; $index -lt $Data.encode.Count; $index++) {
    $item = $Data.encode[$index]
    $comma = if ($index -lt $Data.encode.Count - 1) { ',' } else { '' }
    $lines.Add(('    {{ "id": {0}, "linear": {1}, "encoded": {2} }}{3}' -f (Quote-Json $item.id), (Format-JsonNumber $item.linear), (Format-JsonNumber $item.encoded), $comma))
  }
  $lines.Add('  ]')
  $lines.Add('}')
  return Join-Lines $lines.ToArray()
}

function Render-DerivedJson([object]$Data) {
  $payload = [ordered]@{
    schema_version = '1.0.0'
    classification = 'repository-derived-adversarial'
    generator = 'scripts/fixtures/Generate-ColorVectors.ps1'
    source = 'repository-derived:scripts/fixtures/Generate-ColorVectors.ps1'
    notes = 'Project-authored edge cases; these are not official or externally sourced vectors.'
    quantize_vectors = $Data.quantize
    ratio_vectors = $Data.ratios
    alpha_vectors = $Data.alpha
    profile_vectors = $Data.profile
  }
  $json = $payload | ConvertTo-Json -Depth 20
  $json = $json.Replace("`r`n", "`n")
  return ($json.TrimEnd() + "`n")
}

function Render-Manifest([string]$SrgbDigest, [string]$DerivedDigest) {
  $manifestPath = Join-Path $RepositoryRoot 'fixtures\manifest.json'
  $existingRecords = @()
  if (Test-Path -LiteralPath $manifestPath) {
    $existing = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $existingRecords = @($existing.records | Where-Object { $_.id -cnotin @('color-srgb-reference-vectors', 'color-derived-edge-vectors') })
  }
  $records = @($existingRecords) + @(
    [ordered]@{
      id='color-srgb-reference-vectors'; path='fixtures/color/srgb-reference-vectors.json'; origin='generated'
      source='https://www.w3.org/TR/css-color-4/#color-conversion-code and https://registry.color.org/rgb-registry/files/sRGB.pdf; values derived by scripts/fixtures/Generate-ColorVectors.ps1'
      author='MoonBit Native Foundation project generator'; retrieval_date='2026-07-17'; sha256=$SrgbDigest
      license='Apache-2.0'; redistribution_status='not-applicable'
      expected_use='COLR-04 sRGB transfer endpoints, thresholds, adjacent values, monotonicity, and tolerance conformance'
    },
    [ordered]@{
      id='color-derived-edge-vectors'; path='fixtures/color/derived-edge-vectors.json'; origin='generated'
      source='repository-derived:scripts/fixtures/Generate-ColorVectors.ps1'
      author='MoonBit Native Foundation project generator'; retrieval_date='2026-07-17'; sha256=$DerivedDigest
      license='Apache-2.0'; redistribution_status='not-applicable'
      expected_use='COLR-04 project-derived quantization, alpha, profile-limit, and adversarial conformance cases'
    }
  )
  $manifest = [ordered]@{
    schema_version='1.0.0'; preferred_origin='generated'
    required_record_fields=@('id','path','origin','source','author','retrieval_date','sha256','license','redistribution_status','expected_use')
    allowed_origins=@('generated','external')
    allowed_redistribution_statuses=@('confirmed','not-applicable','unconfirmed')
    external_requires_confirmed_redistribution=$true
    records=$records
  }
  $json = $manifest | ConvertTo-Json -Depth 20
  return ($json.Replace("`r`n", "`n").TrimEnd() + "`n")
}

function Render-TransferMoon([object]$Data) {
  $lines = [System.Collections.Generic.List[string]]::new()
  $lines.Add('// Generated by scripts/fixtures/Generate-ColorVectors.ps1. Do not edit.')
  $lines.Add('')
  $lines.Add('///|')
  $lines.Add('fn generated_decode_vectors() -> Array[(Double, Double)] {')
  $lines.Add('  [')
  foreach ($item in $Data.decode) { $lines.Add(('    ({0}, {1}),' -f (Format-MoonDouble $item.encoded), (Format-MoonDouble $item.linear))) }
  $lines.Add('  ]')
  $lines.Add('}')
  $lines.Add('')
  $lines.Add('///|')
  $lines.Add('fn generated_encode_vectors() -> Array[(Double, Double)] {')
  $lines.Add('  [')
  foreach ($item in $Data.encode) { $lines.Add(('    ({0}, {1}),' -f (Format-MoonDouble $item.linear), (Format-MoonDouble $item.encoded))) }
  $lines.Add('  ]')
  $lines.Add('}')
  $lines.Add('')
  $lines.Add('///|')
  $lines.Add('test "generated transfer vector table is complete" {')
  $lines.Add(('  inspect(generated_decode_vectors().length(), content="{0}")' -f $Data.decode.Count))
  $lines.Add(('  inspect(generated_encode_vectors().length(), content="{0}")' -f $Data.encode.Count))
  $lines.Add('}')
  return Join-Lines $lines.ToArray()
}

function Render-QuantizeMoon([object]$Data) {
  $lines = [System.Collections.Generic.List[string]]::new()
  $lines.Add('// Generated by scripts/fixtures/Generate-ColorVectors.ps1. Do not edit.')
  $lines.Add('')
  $lines.Add('///|')
  $lines.Add('fn generated_quantize_vectors() -> Array[(Double, Int)] {')
  $lines.Add('  [')
  foreach ($item in $Data.quantize) { $lines.Add(('    ({0}, {1}),' -f (Format-MoonDouble $item.normalized), $item.expected)) }
  $lines.Add('  ]')
  $lines.Add('}')
  $lines.Add('')
  $lines.Add('///|')
  $lines.Add('fn generated_ratio_vectors() -> Array[(UInt64, UInt64, UInt64)] {')
  $lines.Add('  [')
  foreach ($item in $Data.ratios) { $lines.Add(('    ({0}UL, {1}UL, {2}UL),' -f $item.numerator, $item.denominator, $item.expected)) }
  $lines.Add('  ]')
  $lines.Add('}')
  $lines.Add('')
  $lines.Add('///|')
  $lines.Add('test "generated quantize vector table is complete" {')
  $lines.Add(('  inspect(generated_quantize_vectors().length(), content="{0}")' -f $Data.quantize.Count))
  $lines.Add(('  inspect(generated_ratio_vectors().length(), content="{0}")' -f $Data.ratios.Count))
  $lines.Add('}')
  return Join-Lines $lines.ToArray()
}

function Render-AlphaMoon([object]$Data) {
  $lines = [System.Collections.Generic.List[string]]::new()
  $lines.Add('// Generated by scripts/fixtures/Generate-ColorVectors.ps1. Do not edit.')
  $lines.Add('')
  $lines.Add('///|')
  $lines.Add('fn generated_alpha_vectors() -> Array[(Int, Int, Int, Int)] {')
  $lines.Add('  [')
  foreach ($item in $Data.alpha) { $lines.Add(('    ({0}, {1}, {2}, {3}),' -f $item.component, $item.alpha, $item.premultiplied, $item.unpremultiplied)) }
  $lines.Add('  ]')
  $lines.Add('}')
  $lines.Add('')
  $lines.Add('///|')
  $lines.Add('test "generated alpha vector table is complete" {')
  $lines.Add(('  inspect(generated_alpha_vectors().length(), content="{0}")' -f $Data.alpha.Count))
  $lines.Add('}')
  return Join-Lines $lines.ToArray()
}

function Render-ProfileMoon([object]$Data) {
  $lines = [System.Collections.Generic.List[string]]::new()
  $lines.Add('// Generated by scripts/fixtures/Generate-ColorVectors.ps1. Do not edit.')
  $lines.Add('///|')
  $lines.Add('fn generated_accepted_profile_tags() -> Array[String] {')
  $lines.Add('  [')
  foreach ($tag in $Data.profile.accepted_tags) { $lines.Add(('    "{0}",' -f $tag)) }
  $lines.Add('  ]')
  $lines.Add('}')
  $lines.Add('')
  $lines.Add('///|')
  $lines.Add('fn generated_rejected_profile_tags() -> Array[String] {')
  $lines.Add('  [')
  foreach ($tag in $Data.profile.rejected_tags) { $lines.Add(('    "{0}",' -f $tag)) }
  $lines.Add('  ]')
  $lines.Add('}')
  $lines.Add('')
  $lines.Add('///|')
  $lines.Add('test "generated profile vector table is complete" {')
  $lines.Add(('  inspect(generated_accepted_profile_tags().length(), content="{0}")' -f $Data.profile.accepted_tags.Count))
  $lines.Add(('  inspect(generated_rejected_profile_tags().length(), content="{0}")' -f $Data.profile.rejected_tags.Count))
  $lines.Add('}')
  return Join-Lines $lines.ToArray()
}

$data = New-CanonicalData
$srgbJson = Render-SrgbJson $data
$derivedJson = Render-DerivedJson $data
$manifestJson = Render-Manifest -SrgbDigest (Get-Sha256 (Get-Bytes $srgbJson)) -DerivedDigest (Get-Sha256 (Get-Bytes $derivedJson))

$renderers = [ordered]@{
  fixtures = @(
    @{ Path='fixtures/color/srgb-reference-vectors.json'; Content=$srgbJson },
    @{ Path='fixtures/color/derived-edge-vectors.json'; Content=$derivedJson },
    @{ Path='fixtures/manifest.json'; Content=$manifestJson }
  )
  transfer = @(@{ Path='modules/mb-color/transfer/reference_vectors_wbtest.mbt'; Content=(Render-TransferMoon $data) })
  quantize = @(@{ Path='modules/mb-color/quantize/reference_vectors_wbtest.mbt'; Content=(Render-QuantizeMoon $data) })
  alpha = @(@{ Path='modules/mb-color/alpha/reference_vectors_wbtest.mbt'; Content=(Render-AlphaMoon $data) })
  profile = @(@{ Path='modules/mb-color/profile/reference_vectors_wbtest.mbt'; Content=(Render-ProfileMoon $data) })
}

$selected = if ($Artifacts -ceq 'all') { @('fixtures', 'transfer', 'quantize', 'alpha', 'profile') } else { @($Artifacts) }
foreach ($selector in $selected) {
  foreach ($artifact in $renderers[$selector]) {
    Assert-OrWriteArtifact -RelativePath $artifact.Path -Content $artifact.Content
  }
}

$completionMessage = if ($Check) { "Color vector check passed for selector '$Artifacts'." } else { "Color vector generation completed for selector '$Artifacts'." }
Write-Host $completionMessage
