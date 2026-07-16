Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'Assert-Toolchain.ps1')
. (Join-Path $PSScriptRoot 'Assert-Policy.ps1')

function Invoke-QualityStage {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][scriptblock]$Action
  )

  Write-Host "==> $Name"
  try {
    & $Action
  } catch {
    throw "Quality stage '$Name' failed: $($_.Exception.Message)"
  }
}

function Invoke-MoonCommand {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Context,
    [Parameter(Mandatory)][string[]]$Arguments,
    [switch]$CaptureCombined
  )

  if ($CaptureCombined) {
    $output = @(& moon @Arguments 2>&1 | ForEach-Object { $_.ToString().TrimEnd() })
  } else {
    & moon @Arguments
    $output = @()
  }
  if ($LASTEXITCODE -ne 0) {
    throw "$Context failed (exit $LASTEXITCODE): moon $($Arguments -join ' ')"
  }
  return ,$output
}

function Assert-GeneratedInterface {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][object]$ModulePolicy
  )

  foreach ($package in @($ModulePolicy.public_packages)) {
    $interfacePath = if ([string]$package.path -ceq '.') {
      Join-Path ([string]$ModulePolicy.path) 'pkg.generated.mbti'
    } else {
      Join-Path (Join-Path ([string]$ModulePolicy.path) ([string]$package.path)) 'pkg.generated.mbti'
    }
    if (-not (Test-Path -LiteralPath $interfacePath -PathType Leaf)) {
      throw "Interface classifier for $($package.name) cannot find '$interfacePath'."
    }
    $semanticLines = @(Get-Content -LiteralPath $interfacePath | ForEach-Object { $_.TrimEnd() } | Where-Object { $_ -ne '' -and -not $_.TrimStart().StartsWith('//') })
    $expectedLines = @($package.semantic_interface | ForEach-Object { [string]$_ })
    if ($semanticLines.Count -ne $expectedLines.Count) {
      throw "Interface classifier for $($package.name) line count mismatch: expected $($expectedLines.Count), got $($semanticLines.Count)."
    }
    for ($index = 0; $index -lt $expectedLines.Count; $index++) {
      if ($semanticLines[$index] -cne $expectedLines[$index]) {
        throw "Interface classifier for $($package.name) mismatch at semantic line $($index + 1): expected '$($expectedLines[$index])', got '$($semanticLines[$index])'."
      }
    }
    Write-Host "Interface verified for $($package.name): $($expectedLines.Count) semantic line(s)"
  }
}

function Assert-PackageList {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][object]$ModulePolicy,
    [Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]]$Output
  )

  $expectedFiles = @($ModulePolicy.publication_files | ForEach-Object { [string]$_ })
  $listedFiles = [System.Collections.Generic.List[string]]::new()
  foreach ($line in @($Output | Where-Object { $_ -ne '' })) {
    $normalizedLine = $line.Replace('\', '/')
    if ($expectedFiles -ccontains $normalizedLine) {
      $listedFiles.Add($normalizedLine)
      continue
    }
    if ($line -cmatch "^Warning: 'repository' field is not set or empty in module manifest$" -or
        $line -ceq 'Running moon check ...' -or
        $line -cmatch '^Finished[.] moon: .+$' -or
        $line -ceq 'Check passed' -or
        $line -cmatch '^Package to .+[.]zip$') {
      continue
    }
    throw "Package list for $($ModulePolicy.name) contained an unrecognized or forbidden line: '$line'."
  }
  Assert-ExactSet "Package contents for $($ModulePolicy.name)" @($listedFiles) $expectedFiles
  Write-Host "Package contents verified for $($ModulePolicy.name): $($expectedFiles -join ', ')"
}

function Assert-CoreSourceTextProhibitions {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$RelativePath,
    [Parameter(Mandatory)][string]$Text
  )

  $publicLines = @($Text -split '\r?\n' | Where-Object { $_ -cmatch '^\s*pub(?:\([^)]*\))?\s' })
  foreach ($line in $publicLines) {
    if ($line -cmatch '\b(?:FixedArray|MutArrayView)\b') {
      throw "Raw mutable backing escaped through a public declaration in $RelativePath`: $line"
    }
    if ($RelativePath -like 'modules/mb-core/host/*' -and $line -cmatch '\b(?:Host|Environment|NativeAdapter)\b') {
      throw "Ambient, aggregate, or native host surface escaped in $RelativePath`: $line"
    }
  }

  if ($RelativePath -cne 'modules/mb-core/checked/checked.mbt' -and $Text -cmatch '[.]to_int\s*\(') {
    throw "Unchecked UInt64-to-Int narrowing exists outside checked_narrow_int in '$RelativePath'."
  }
  if ($RelativePath -like 'modules/mb-core/host/*' -and $Text -cmatch '(?i)@(?:env|fs|process)\b|\bgetenv\s*\(|\bglobal_(?:host|clock|files?)\b') {
    throw "Ambient process or host access token found in '$RelativePath'."
  }
}

function Assert-CoreReadmeProhibitions {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Readme)

  $normalizedReadme = [regex]::Replace($Readme, '\s+', ' ')
  foreach ($requiredPhrase in @(
    'Budget rejection and injected allocator rejection are portable structured results.',
    'Built-in physical runtime OOM is unrecoverable',
    'is not claimed as a catchable `CoreError`',
    'There is no ambient fallback'
  )) {
    if (-not $normalizedReadme.Contains($requiredPhrase)) {
      throw "mb-core README lacks required portable-safety statement: $requiredPhrase"
    }
  }
  if ($Readme -cmatch '(?i)physical(?: runtime)? OOM\s+(?:is|remains)\s+(?:recoverable|catchable)|catch(?:es|ing)?\s+(?:built-in\s+)?physical(?: runtime)? OOM') {
    throw 'mb-core README falsely claims built-in physical OOM is recoverable.'
  }
}

function Assert-CorePortableProhibitions {
  [CmdletBinding()]
  param()

  $coreRoot = 'modules/mb-core'
  $sourceFiles = @(Get-ChildItem -LiteralPath $coreRoot -Recurse -File -Filter '*.mbt')
  if ($sourceFiles.Count -eq 0) { throw 'No mb-core MoonBit sources were found for prohibition scanning.' }

  foreach ($sourceFile in $sourceFiles) {
    $text = Get-Content -LiteralPath $sourceFile.FullName -Raw
    $relative = [System.IO.Path]::GetRelativePath((Resolve-Path '.').Path, $sourceFile.FullName).Replace('\', '/')
    Assert-CoreSourceTextProhibitions -RelativePath $relative -Text $text
  }

  $readme = Get-Content -LiteralPath (Join-Path $coreRoot 'README.mbt.md') -Raw
  Assert-CoreReadmeProhibitions -Readme $readme

  Write-Host 'mb-core portable prohibitions verified: no raw mutable public backing, unchecked narrowing, ambient host/native aggregate, or false catchable-OOM prose.'
}

function Assert-CoreQualificationNegativeFixtures {
  [CmdletBinding()]
  param()

  function Confirm-Rejected([string]$Name, [scriptblock]$Action) {
    $rejected = $false
    try { & $Action } catch { $rejected = $true }
    if (-not $rejected) { throw "Required quality accepted negative fixture '$Name'." }
    Write-Host "Negative fixture rejected: $Name"
  }

  $packageSpine = @('error', 'checked', 'budget', 'bytes', 'io', 'host')
  Confirm-Rejected 'root package topology' {
    Assert-ExactSequence 'negative package spine' @('.', 'error', 'checked', 'budget', 'bytes', 'io', 'host') $packageSpine
  }
  Confirm-Rejected 'extra public package' {
    Assert-ExactSequence 'negative package spine' @('error', 'checked', 'budget', 'bytes', 'io', 'host', 'extra') $packageSpine
  }
  Confirm-Rejected 'missing public package' {
    Assert-ExactSequence 'negative package spine' @('error', 'checked', 'budget', 'bytes', 'io') $packageSpine
  }
  Confirm-Rejected 'reverse dependency' {
    Assert-ExactSet 'negative imports' @('moonbit-foundation/mb-core/host') @('moonbit-foundation/mb-core/error')
  }
  Confirm-Rejected 'undeclared public surface' {
    Assert-ExactSequence 'negative semantic interface' @('package "fixture"', 'pub fn unexpected() -> Unit') @('package "fixture"')
  }
  Confirm-Rejected 'raw mutable backing' {
    Assert-CoreSourceTextProhibitions -RelativePath 'modules/mb-core/bytes/fixture.mbt' -Text 'pub fn backing() -> FixedArray[Byte] { abort("fixture") }'
  }
  Confirm-Rejected 'unchecked narrowing' {
    Assert-CoreSourceTextProhibitions -RelativePath 'modules/mb-core/io/fixture.mbt' -Text 'fn narrow(value : UInt64) -> Int { value.to_int() }'
  }
  Confirm-Rejected 'ambient host access' {
    Assert-CoreSourceTextProhibitions -RelativePath 'modules/mb-core/host/fixture.mbt' -Text 'fn ambient() -> Unit { ignore(@fs.open("fixture")) }'
  }
  Confirm-Rejected 'false recoverable physical OOM prose' {
    Assert-CoreReadmeProhibitions -Readme 'Budget rejection and injected allocator rejection are portable structured results. Built-in physical runtime OOM is unrecoverable and is not claimed as a catchable `CoreError`. There is no ambient fallback. Physical runtime OOM is recoverable.'
  }
  Confirm-Rejected 'broken literate documentation input' {
    Invoke-MoonCommand -Context 'negative missing README fixture' -Arguments @('-C', 'modules/mb-core', 'check', 'README.missing.mbt.md', '--target', 'native', '--frozen')
  }

  Write-Host 'Core topology, public surface, docs, capability, backing, narrowing, and OOM negative fixtures all fail closed.'
}

function Assert-ColorSourceTextProhibitions {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$RelativePath,
    [Parameter(Mandatory)][string]$Text
  )

  if ($Text -cmatch '(?:Double::round|[.]round)\s*\(') {
    throw "Backend half-up rounding primitive found in '$RelativePath'."
  }
  if ($Text -cmatch '(?i)\bclamp\s*\(') {
    throw "Silent clamp token found in '$RelativePath'."
  }
  $publicLines = @($Text -split '\r?\n' | Where-Object { $_ -cmatch '^\s*pub(?:\([^)]*\))?\s+fn\s' })
  foreach ($line in $publicLines) {
    if ($line -cmatch '(?i)\b(?:convert|normalized|component|color)\w*\s*\([^)]*Double') {
      throw "Identity-erasing generic normalized conversion surface found in $RelativePath`: $line"
    }
    if ($line -cmatch '(?i)\b(?:default|implicit|ambient)\w*\s*\(') {
      throw "Hidden default or ambient color identity surface found in $RelativePath`: $line"
    }
    if ($line -cmatch '(?i)\b(?:Css|Image|Pixel|Renderer|Codec|Gamut|Interpolation)\b') {
      throw "Out-of-phase color surface found in $RelativePath`: $line"
    }
  }
  if ($RelativePath -like 'modules/mb-color/profile/*' -and $Text -cmatch '(?i)\b(?:parse_icc|icc_header|profile_size|header_size|tag_table)\b') {
    throw "ICC parsing token found in opaque profile package '$RelativePath'."
  }
}

function Assert-ColorReadmeContract {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Readme)

  $normalized = [regex]::Replace($Readme, '\s+', ' ')
  foreach ($requiredPhrase in @(
    'Zero alpha has one canonical result',
    'maximum component error is 127 code values',
    'does not certify that bytes are a valid ICC profile',
    'No ICC header is parsed',
    'No external fixture bytes are copied or relabeled as project-authored',
    'This order is a release sequence, not an implied dependency chain',
    'There is no root facade or prelude'
  )) {
    if (-not $normalized.Contains($requiredPhrase)) {
      throw "mb-color README lacks required exact contract statement: $requiredPhrase"
    }
  }
  foreach ($requiredToken in @('1e-12', '2e-12', '[A-Za-z0-9][A-Za-z0-9._+-]{0,31}', 'max_payload_bytes')) {
    if (-not $Readme.Contains($requiredToken)) {
      throw "mb-color README lacks required numerical/profile token: $requiredToken"
    }
  }
  if ($Readme -cmatch '(?i)\b(?:validates?|parses?)\s+(?:an?\s+)?ICC\b|\b(?:provides?|guarantees?)\s+ICC\s+(?:validation|parsing|conformance)\b|\bICC[- ]conformant\b') {
    throw 'mb-color README overstates ICC parsing, validation, or conformance.'
  }
}

function Assert-ColorPortableProhibitions {
  [CmdletBinding()]
  param()

  $colorRoot = 'modules/mb-color'
  $sourceFiles = @(Get-ChildItem -LiteralPath $colorRoot -Recurse -File -Filter '*.mbt' | Where-Object { $_.Name -notmatch '(?:_test|_wbtest)[.]mbt$' })
  if ($sourceFiles.Count -eq 0) { throw 'No mb-color production MoonBit sources were found for prohibition scanning.' }
  foreach ($sourceFile in $sourceFiles) {
    $relative = [System.IO.Path]::GetRelativePath((Resolve-Path '.').Path, $sourceFile.FullName).Replace('\', '/')
    Assert-ColorSourceTextProhibitions -RelativePath $relative -Text (Get-Content -LiteralPath $sourceFile.FullName -Raw)
  }
  Assert-ColorReadmeContract -Readme (Get-Content -LiteralPath (Join-Path $colorRoot 'README.mbt.md') -Raw)
  Write-Host 'mb-color prohibitions verified: no backend rounding, clamp, hidden identity/default, ICC parser, deferred surface, or overstated README claim.'
}

function Assert-ColorQualificationNegativeFixtures {
  [CmdletBinding()]
  param()

  function Confirm-ColorRejected([string]$Name, [scriptblock]$Action, [string]$ExpectedPattern) {
    $failure = $null
    try { & $Action } catch { $failure = $_.Exception.Message }
    if ($null -eq $failure -or $failure -cnotmatch $ExpectedPattern) {
      throw "Required color quality accepted negative fixture '$Name' or failed for the wrong reason: '$failure'."
    }
    Write-Host "Color negative fixture rejected: $Name"
  }

  $packageSpine = @('model', 'transfer', 'quantize', 'alpha', 'profile')
  Confirm-ColorRejected 'root package topology' { Assert-ExactSequence 'negative color package spine' @('.', 'model', 'transfer', 'quantize', 'alpha', 'profile') $packageSpine } 'count mismatch'
  Confirm-ColorRejected 'extra public package' { Assert-ExactSequence 'negative color package spine' @('model', 'transfer', 'quantize', 'alpha', 'profile', 'extra') $packageSpine } 'count mismatch'
  Confirm-ColorRejected 'missing public package' { Assert-ExactSequence 'negative color package spine' @('model', 'transfer', 'quantize', 'alpha') $packageSpine } 'count mismatch'
  Confirm-ColorRejected 'reverse image dependency' { Assert-ExactSet 'negative color imports' @('moonbit-foundation/mb-image/model') @('moonbit-foundation/mb-core/error') } 'mismatch'
  Confirm-ColorRejected 'forbidden quantize to transfer edge' { Assert-ExactSet 'negative quantize imports' @('moonbit-foundation/mb-color/model', 'moonbit-foundation/mb-color/transfer', 'moonbit-foundation/mb-core/error', 'moonbit-foundation/mb-core/checked') @('moonbit-foundation/mb-color/model', 'moonbit-foundation/mb-core/error', 'moonbit-foundation/mb-core/checked') } 'count mismatch'
  Confirm-ColorRejected 'forbidden profile to color edge' { Assert-ExactSet 'negative profile imports' @('moonbit-foundation/mb-core/error', 'moonbit-foundation/mb-core/budget', 'moonbit-foundation/mb-core/bytes', 'moonbit-foundation/mb-color/model') @('moonbit-foundation/mb-core/error', 'moonbit-foundation/mb-core/budget', 'moonbit-foundation/mb-core/bytes') } 'count mismatch'
  Confirm-ColorRejected 'semantic interface drift' { Assert-ExactSequence 'negative color interface' @('package "fixture"', 'pub fn unexpected() -> Unit') @('package "fixture"') } 'count mismatch'
  Confirm-ColorRejected 'publication drift' { Assert-ExactSet 'negative color publication' @('model/moon.pkg', 'unexpected.mbt') @('model/moon.pkg') } 'count mismatch'
  Confirm-ColorRejected 'generated vector publication drift' { Assert-ExactSet 'negative color generated vectors' @('transfer/reference_vectors_wbtest.mbt', 'quantize/reference_vectors_wbtest.mbt', 'alpha/reference_vectors_wbtest.mbt') @('transfer/reference_vectors_wbtest.mbt', 'quantize/reference_vectors_wbtest.mbt', 'alpha/reference_vectors_wbtest.mbt', 'profile/reference_vectors_wbtest.mbt') } 'count mismatch'
  Confirm-ColorRejected 'missing required target' { Assert-ExactSet 'negative color targets' @('js', 'wasm', 'native') @('js', 'wasm', 'wasm-gc', 'native') } 'count mismatch'
  Confirm-ColorRejected 'backend half-up rounding' { Assert-ColorSourceTextProhibitions -RelativePath 'modules/mb-color/quantize/fixture.mbt' -Text 'fn quantize(value : Double) -> Double { value.round() }' } 'half-up rounding'
  Confirm-ColorRejected 'silent clamp' { Assert-ColorSourceTextProhibitions -RelativePath 'modules/mb-color/model/fixture.mbt' -Text 'fn normalized(value : Double) -> Double { value.clamp(0.0, 1.0) }' } 'Silent clamp'
  Confirm-ColorRejected 'identity-erasing normalized API' { Assert-ColorSourceTextProhibitions -RelativePath 'modules/mb-color/fixture.mbt' -Text 'pub fn convert_color(value : Double) -> Double { value }' } 'Identity-erasing'
  Confirm-ColorRejected 'hidden default identity API' { Assert-ColorSourceTextProhibitions -RelativePath 'modules/mb-color/fixture.mbt' -Text 'pub fn default_color() -> Unit { () }' } 'Hidden default'
  Confirm-ColorRejected 'ICC parser surface' { Assert-ColorSourceTextProhibitions -RelativePath 'modules/mb-color/profile/fixture.mbt' -Text 'fn parse_icc() -> Unit { () }' } 'ICC parsing'
  Confirm-ColorRejected 'missing canonical zero README statement' { Assert-ColorReadmeContract -Readme 'candidate js wasm wasm-gc native 1e-12 2e-12 [A-Za-z0-9][A-Za-z0-9._+-]{0,31} max_payload_bytes' } 'Zero alpha'

  & ./scripts/quality/Test-FixturePolicy.ps1
  Write-Host 'Color topology, DAG, interface, publication, generated-vector, target, source, README, digest, and redistribution negatives all fail closed.'
}

function Assert-ImageSourceTextProhibitions {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$RelativePath,
    [Parameter(Mandatory)][string]$Text
  )

  $publicLines = @($Text -split '\r?\n' | Where-Object { $_ -cmatch '^\s*pub(?:\([^)]*\))?\s' })
  foreach ($line in $publicLines) {
    if ($line -cmatch '\b(?:FixedArray|MutArrayView|MutByteLease|OwnedBytes)\b') {
      throw "Raw mutable or backing storage escaped through a public image declaration in $RelativePath`: $line"
    }
    if ($line -cmatch '(?i)\b(?:default|implicit|ambient)\w*\s*\(') {
      throw "Hidden default or ambient image policy surface found in $RelativePath`: $line"
    }
  }
  if ($Text -cmatch '(?m)UInt64[^\r\n]*[.]to_int\s*\(') {
    throw "Unchecked UInt64-to-Int narrowing found in '$RelativePath'."
  }
  if ($RelativePath -like 'modules/mb-image/ops/*' -and $Text -cmatch '(?i)\bDouble\b|[.]to_double\s*\(|\b(?:round|floor|ceil)\s*\(') {
    throw "Floating-point image operation mapping found in '$RelativePath'."
  }
  if ($RelativePath -like 'modules/mb-image/codec/*' -and $Text -cmatch '(?i)\bSeeker\b|https?://|\b(?:path|url|filesystem|registry|global_codec)\b|@(?:fs|http)\b') {
    throw "Host path, URL, registry, filesystem, or seeking policy found in '$RelativePath'."
  }
  if ($RelativePath -like 'modules/mb-image/codec/*' -and $Text -cmatch '(?i)\b(?:Ppm|Png|Jpeg|Gif|Webp|Bmp|Tiff)(?:Decoder|Encoder|Codec)\b') {
    throw "Concrete codec implementation found in Phase 4 source '$RelativePath'."
  }
}

function Assert-ImageReadmeContract {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Readme)

  $normalized = [regex]::Replace($Readme, '\s+', ' ')
  foreach ($requiredPhrase in @(
    'There is no root facade or prelude',
    'reference operations deliberately accept only packed encoded-sRGB',
    'Invalid or unsupported input consumes no budget',
    'Raw mutable backing is never exposed',
    'performs no filtering or hidden color conversion',
    'Neither contract requires seeking, paths, URLs, filesystem access, a registry',
    'Phase 5 owns the first bounded PPM P6 implementation',
    'exactly five package-local tables'
  )) {
    if (-not $normalized.Contains($requiredPhrase)) {
      throw "mb-image README lacks required exact contract statement: $requiredPhrase"
    }
  }
  foreach ($token in @('metadata', 'model', 'storage', 'ops', 'codec', 'js', 'wasm', 'wasm-gc', 'native', 'floor(destination * source_extent / destination_extent)')) {
    if (-not $Readme.Contains($token)) { throw "mb-image README lacks required contract token: $token" }
  }
}

function Assert-ImagePortableProhibitions {
  [CmdletBinding()]
  param()

  $imageRoot = 'modules/mb-image'
  $sourceFiles = @(Get-ChildItem -LiteralPath $imageRoot -Recurse -File -Filter '*.mbt' | Where-Object { $_.Name -notmatch '(?:_test|_wbtest)[.]mbt$' })
  if ($sourceFiles.Count -eq 0) { throw 'No mb-image production MoonBit sources were found for prohibition scanning.' }
  foreach ($sourceFile in $sourceFiles) {
    $relative = [System.IO.Path]::GetRelativePath((Resolve-Path '.').Path, $sourceFile.FullName).Replace('\', '/')
    Assert-ImageSourceTextProhibitions -RelativePath $relative -Text (Get-Content -LiteralPath $sourceFile.FullName -Raw)
  }
  Assert-ImageReadmeContract -Readme (Get-Content -LiteralPath (Join-Path $imageRoot 'README.mbt.md') -Raw)
  Write-Host 'mb-image prohibitions verified: no root facade, raw backing, unchecked narrowing, floating mapping, hidden defaults, host paths, URLs, registries, seeking, or concrete codec.'
}

function Get-ImageCanonicalCaseSets {
  $fixture = Get-Content -LiteralPath 'fixtures/image/operation-vectors.json' -Raw | ConvertFrom-Json
  @{
    metadata = @($fixture.metadata_vectors.id | ForEach-Object { [string]$_ })
    model = @($fixture.descriptor_plane_vectors.id | ForEach-Object { [string]$_ })
    storage = @($fixture.crop_lease_vectors.id | ForEach-Object { [string]$_ })
    ops = @($fixture.orientation_vectors.id + $fixture.resize_vectors.id + $fixture.conversion_vectors.id | ForEach-Object { [string]$_ })
    codec = @($fixture.codec_vectors.id | ForEach-Object { [string]$_ })
  }
}

function Assert-ImageGeneratedEvidence {
  [CmdletBinding()]
  param(
    [string[]]$TablePaths,
    [hashtable]$CaseSets,
    [hashtable]$ConsumerTexts,
    [string]$GeneratorText
  )

  $expectedTables = @(
    'modules/mb-image/metadata/reference_vectors_wbtest.mbt',
    'modules/mb-image/model/reference_vectors_wbtest.mbt',
    'modules/mb-image/storage/reference_vectors_wbtest.mbt',
    'modules/mb-image/ops/reference_vectors_wbtest.mbt',
    'modules/mb-image/codec/reference_vectors_wbtest.mbt'
  )
  if ($null -eq $TablePaths) { $TablePaths = $expectedTables }
  Assert-ExactSequence 'mb-image generated package-local tables' @($TablePaths) $expectedTables

  $expectedCases = @{
    metadata = @('canonical-order', 'duplicate-key', 'orientation-disposition')
    model = @('packed-padded', 'short-row', 'one-byte-short')
    storage = @('crop-edge', 'empty-crop', 'lease-stale', 'lease-overlap')
    ops = @('orientation-top-left', 'orientation-top-right', 'orientation-bottom-right', 'orientation-bottom-left', 'orientation-left-top', 'orientation-right-top', 'orientation-right-bottom', 'orientation-left-bottom', 'upscale-2-to-5', 'downscale-5-to-2', 'unit-axis', 'rgb-to-rgba', 'opaque-rgba-to-rgb', 'lossy-rgba-to-rgb')
    codec = @('empty-prefix', 'short-prefix', 'non-match', 'short-progress')
  }
  if ($null -eq $CaseSets) { $CaseSets = Get-ImageCanonicalCaseSets }
  foreach ($package in @('metadata', 'model', 'storage', 'ops', 'codec')) {
    Assert-ExactSequence "mb-image $package canonical case IDs" @($CaseSets[$package]) @($expectedCases[$package])
    $tablePath = "modules/mb-image/$package/reference_vectors_wbtest.mbt"
    $tableText = Get-Content -LiteralPath $tablePath -Raw
    foreach ($id in @($expectedCases[$package])) {
      if (-not $tableText.Contains('"' + $id + '"')) { throw "Generated $package table lacks canonical case ID '$id'." }
    }
  }

  if ($null -eq $ConsumerTexts) {
    $ConsumerTexts = @{
      metadata = Get-Content -LiteralPath 'modules/mb-image/metadata/metadata_wbtest.mbt' -Raw
      model = Get-Content -LiteralPath 'modules/mb-image/model/model_wbtest.mbt' -Raw
      storage = Get-Content -LiteralPath 'modules/mb-image/storage/storage_wbtest.mbt' -Raw
      ops = (Get-Content -LiteralPath 'modules/mb-image/ops/orientation_wbtest.mbt' -Raw) + (Get-Content -LiteralPath 'modules/mb-image/ops/resize_convert_wbtest.mbt' -Raw)
      codec = Get-Content -LiteralPath 'modules/mb-image/codec/codec_wbtest.mbt' -Raw
    }
  }
  $consumerFunctions = @{
    metadata = @('generated_metadata_case_ids')
    model = @('generated_model_case_ids')
    storage = @('generated_storage_case_ids')
    ops = @('generated_ops_case_ids', 'generated_orientation_vectors', 'generated_resize_axis_vectors', 'generated_conversion_vectors')
    codec = @('generated_codec_cases')
  }
  foreach ($package in @('metadata', 'model', 'storage', 'ops', 'codec')) {
    foreach ($function in @($consumerFunctions[$package])) {
      if (-not ([string]$ConsumerTexts[$package]).Contains("$function(")) { throw "Behavioral $package tests do not consume generated function '$function'." }
    }
  }

  if ([string]::IsNullOrEmpty($GeneratorText)) { $GeneratorText = Get-Content -LiteralPath 'scripts/fixtures/Generate-ImageVectors.ps1' -Raw }
  if (-not $GeneratorText.Contains('Standards-literal Exif oracle') -or -not $GeneratorText.Contains('intentionally authored here and are never obtained from production code')) {
    throw 'The orientation oracle is not explicitly generator-owned and standards-literal.'
  }
  if ($GeneratorText -cmatch '(?i)Get-Content[^\r\n]*(?:orientation[.]mbt|modules[/\\]mb-image[/\\]ops)') {
    throw 'The orientation oracle reads production mapping source and is not independent.'
  }
  Write-Host 'Exactly five package-local image tables, canonical case IDs, behavioral consumers, and the independent orientation oracle are verified.'
}

function Assert-ImageQualificationNegativeFixtures {
  [CmdletBinding()]
  param()

  function Confirm-ImageRejected([string]$Name, [scriptblock]$Action, [string]$ExpectedPattern) {
    $failure = $null
    try { & $Action } catch { $failure = $_.Exception.Message }
    if ($null -eq $failure -or $failure -cnotmatch $ExpectedPattern) {
      throw "Required image quality accepted negative fixture '$Name' or failed for the wrong reason: '$failure'."
    }
    Write-Host "Image negative fixture rejected: $Name"
  }

  $packageSpine = @('metadata', 'model', 'storage', 'ops', 'codec')
  Confirm-ImageRejected 'root facade topology' { Assert-ExactSequence 'negative image package spine' @('.', 'metadata', 'model', 'storage', 'ops', 'codec') $packageSpine } 'count mismatch'
  Confirm-ImageRejected 'extra public package' { Assert-ExactSequence 'negative image package spine' @('metadata', 'model', 'storage', 'ops', 'codec', 'extra') $packageSpine } 'count mismatch'
  Confirm-ImageRejected 'missing public package' { Assert-ExactSequence 'negative image package spine' @('metadata', 'model', 'storage', 'ops') $packageSpine } 'count mismatch'
  Confirm-ImageRejected 'reverse codec to ops edge' { Assert-ExactSet 'negative image imports' @('moonbit-foundation/mb-image/storage', 'moonbit-foundation/mb-image/ops') @('moonbit-foundation/mb-image/storage') } 'count mismatch'
  Confirm-ImageRejected 'semantic interface drift' { Assert-ExactSequence 'negative image interface' @('package "fixture"', 'pub fn unexpected() -> Unit') @('package "fixture"') } 'count mismatch'
  Confirm-ImageRejected 'publication drift' { Assert-ExactSet 'negative image publication' @('metadata/moon.pkg', 'unexpected.mbt') @('metadata/moon.pkg') } 'count mismatch'
  Confirm-ImageRejected 'missing required target' { Assert-ExactSet 'negative image targets' @('js', 'wasm', 'native') @('js', 'wasm', 'wasm-gc', 'native') } 'count mismatch'
  Confirm-ImageRejected 'raw mutable backing' { Assert-ImageSourceTextProhibitions -RelativePath 'modules/mb-image/storage/fixture.mbt' -Text 'pub fn backing() -> MutArrayView[Byte] { abort("fixture") }' } 'Raw mutable'
  Confirm-ImageRejected 'ambient limits' { Assert-ImageSourceTextProhibitions -RelativePath 'modules/mb-image/model/fixture.mbt' -Text 'pub fn ambient_limits() -> Unit { () }' } 'Hidden default or ambient'
  Confirm-ImageRejected 'unchecked narrowing' { Assert-ImageSourceTextProhibitions -RelativePath 'modules/mb-image/model/fixture.mbt' -Text 'fn narrow(value : UInt64) -> Int { value.to_int() }' } 'Unchecked UInt64'
  Confirm-ImageRejected 'floating resize' { Assert-ImageSourceTextProhibitions -RelativePath 'modules/mb-image/ops/fixture.mbt' -Text 'fn resize(value : Double) -> Double { value.floor() }' } 'Floating-point'
  Confirm-ImageRejected 'hidden default' { Assert-ImageSourceTextProhibitions -RelativePath 'modules/mb-image/ops/fixture.mbt' -Text 'pub fn default_format() -> Unit { () }' } 'Hidden default'
  Confirm-ImageRejected 'host path codec policy' { Assert-ImageSourceTextProhibitions -RelativePath 'modules/mb-image/codec/fixture.mbt' -Text 'fn decode_path(path : String) -> Unit { ignore(path) }' } 'Host path'
  Confirm-ImageRejected 'URL codec policy' { Assert-ImageSourceTextProhibitions -RelativePath 'modules/mb-image/codec/fixture.mbt' -Text 'fn decode() -> String { "https://fixture" }' } 'Host path'
  Confirm-ImageRejected 'codec registry' { Assert-ImageSourceTextProhibitions -RelativePath 'modules/mb-image/codec/fixture.mbt' -Text 'fn registry() -> Unit { () }' } 'Host path'
  Confirm-ImageRejected 'codec seeker dependency' { Assert-ImageSourceTextProhibitions -RelativePath 'modules/mb-image/codec/fixture.mbt' -Text 'fn decode(reader : &Seeker) -> Unit { () }' } 'Host path'
  Confirm-ImageRejected 'concrete codec' { Assert-ImageSourceTextProhibitions -RelativePath 'modules/mb-image/codec/fixture.mbt' -Text 'struct PpmDecoder {}' } 'Concrete codec'
  Confirm-ImageRejected 'missing rootless README statement' { Assert-ImageReadmeContract -Readme 'candidate js wasm wasm-gc native' } 'root facade'

  $tables = @('modules/mb-image/metadata/reference_vectors_wbtest.mbt', 'modules/mb-image/model/reference_vectors_wbtest.mbt', 'modules/mb-image/storage/reference_vectors_wbtest.mbt', 'modules/mb-image/ops/reference_vectors_wbtest.mbt')
  Confirm-ImageRejected 'deleted generated table' { Assert-ImageGeneratedEvidence -TablePaths $tables } 'count mismatch'
  $deletedCases = Get-ImageCanonicalCaseSets
  $deletedCases.metadata = @($deletedCases.metadata | Select-Object -Skip 1)
  Confirm-ImageRejected 'deleted canonical case' { Assert-ImageGeneratedEvidence -CaseSets $deletedCases } 'count mismatch'
  $addedCases = Get-ImageCanonicalCaseSets
  $addedCases.codec = @($addedCases.codec) + @('unexpected-case')
  Confirm-ImageRejected 'added canonical case' { Assert-ImageGeneratedEvidence -CaseSets $addedCases } 'count mismatch'
  $consumers = @{
    metadata = ''
    model = Get-Content -LiteralPath 'modules/mb-image/model/model_wbtest.mbt' -Raw
    storage = Get-Content -LiteralPath 'modules/mb-image/storage/storage_wbtest.mbt' -Raw
    ops = (Get-Content -LiteralPath 'modules/mb-image/ops/orientation_wbtest.mbt' -Raw) + (Get-Content -LiteralPath 'modules/mb-image/ops/resize_convert_wbtest.mbt' -Raw)
    codec = Get-Content -LiteralPath 'modules/mb-image/codec/codec_wbtest.mbt' -Raw
  }
  Confirm-ImageRejected 'removed generated consumer' { Assert-ImageGeneratedEvidence -ConsumerTexts $consumers } 'do not consume'
  Confirm-ImageRejected 'production-derived orientation oracle' { Assert-ImageGeneratedEvidence -GeneratorText 'Get-Content modules/mb-image/ops/orientation.mbt' } 'not explicitly generator-owned'
  Write-Host 'Image topology, DAG, interface, publication, targets, source, README, generated-table, case, consumer, and oracle negatives all fail closed.'
}

function Get-TrackedDiffSnapshot {
  $output = @(& git diff --binary --no-ext-diff HEAD -- 2>&1 | ForEach-Object { $_.ToString() })
  if ($LASTEXITCODE -ne 0) { throw "Unable to capture tracked diff (exit $LASTEXITCODE)." }
  return ($output -join "`n")
}

function Invoke-RequiredQuality {
  $policyPath = 'policy/foundation.json'
  $auditPath = 'policy/phase-01-source-audit.json'
  $requiredTargets = @('js', 'wasm', 'wasm-gc', 'native')
  $modules = @('mb-core', 'mb-color', 'mb-image')
  $policy = Read-QualityJson -Path $policyPath
  $initialTrackedDiff = Get-TrackedDiffSnapshot

  Invoke-QualityStage 'D-14 exact toolchain identity' {
    Assert-Toolchain -PolicyPath $policyPath
  }
  Invoke-QualityStage 'Foundation policy, RFC, fixtures, inventory, target metadata, and DAG' {
    Assert-FoundationPolicy -PolicyPath $policyPath
  }
  Invoke-QualityStage 'Exact Phase 1 source inventory (1/9/16/29/17/5)' {
    Assert-PhaseSourceAudit -AuditPath $auditPath
  }
  Invoke-QualityStage 'WORK-04 format check' {
    # The pinned toolchain's unscoped formatter always proposes the explicitly
    # deferred moon.mod.json -> moon.mod migration. Enumerating every MoonBit
    # source preserves the locked compatibility floor while remaining fail-closed.
    $sourceFiles = @(Get-ChildItem -LiteralPath 'modules' -Recurse -File | Where-Object { $_.Name -match '[.]mbt(?:[.]md)?$' } | ForEach-Object { $_.FullName })
    if ($sourceFiles.Count -eq 0) { throw 'No MoonBit source files were found for formatting.' }
    Invoke-MoonCommand -Context 'workspace MoonBit source format check' -Arguments (@('fmt', '--check') + $sourceFiles)
  }
  Invoke-QualityStage 'CORE portable source and documentation prohibitions' {
    Assert-CorePortableProhibitions
  }
  Invoke-QualityStage 'CORE fail-closed negative fixtures' {
    Assert-CoreQualificationNegativeFixtures
  }
  Invoke-QualityStage 'COLR deterministic generated evidence' {
    & ./scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts all -Check
  }
  Invoke-QualityStage 'COLR portable source and documentation prohibitions' {
    Assert-ColorPortableProhibitions
  }
  Invoke-QualityStage 'COLR fail-closed negative fixtures' {
    Assert-ColorQualificationNegativeFixtures
  }
  Invoke-QualityStage 'IMAG deterministic generated evidence' {
    & ./scripts/fixtures/Generate-ImageVectors.ps1 -Check
    Assert-ImageGeneratedEvidence
  }
  Invoke-QualityStage 'IMAG portable source and documentation prohibitions' {
    Assert-ImagePortableProhibitions
  }
  Invoke-QualityStage 'IMAG fail-closed negative fixtures' {
    Assert-ImageQualificationNegativeFixtures
  }
  foreach ($target in $requiredTargets) {
    Invoke-QualityStage "CORE literate README check target $target" {
      Invoke-MoonCommand -Context "mb-core README check target $target" -Arguments @('-C', 'modules/mb-core', 'check', 'README.mbt.md', '--target', $target, '--frozen')
    }
    Invoke-QualityStage "COLR literate README check target $target" {
      Invoke-MoonCommand -Context "mb-color README check target $target" -Arguments @('-C', 'modules/mb-color', 'check', 'README.mbt.md', '--target', $target, '--frozen')
    }
    Invoke-QualityStage "IMAG literate README check target $target" {
      Invoke-MoonCommand -Context "mb-image README check target $target" -Arguments @('-C', 'modules/mb-image', 'check', 'README.mbt.md', '--target', $target, '--frozen')
    }
    Invoke-QualityStage "WORK-05 check target $target" {
      Invoke-MoonCommand -Context "workspace check target $target" -Arguments @('check', '--target', $target, '--deny-warn', '--frozen')
    }
    Invoke-QualityStage "WORK-05 test target $target" {
      Invoke-MoonCommand -Context "workspace test target $target" -Arguments @('test', '--target', $target, '--frozen')
    }
  }
  foreach ($module in $modules) {
    Invoke-QualityStage "WORK-04 documentation generation for $module" {
      Invoke-MoonCommand -Context "moon doc for $module" -Arguments @('-C', "modules/$module", 'doc', '--frozen')
    }
    Invoke-QualityStage "D-15 interface generation and classification for $module" {
      Invoke-MoonCommand -Context "moon info for $module" -Arguments @('-C', "modules/$module", 'info', '--target', 'all', '--frozen')
      $modulePolicy = @($policy.modules | Where-Object { [string]$_.path -ceq "modules/$module" })[0]
      Assert-GeneratedInterface -ModulePolicy $modulePolicy
    }
  }
  foreach ($module in $modules) {
    Invoke-QualityStage "WORK-04 package allowlist for $module" {
      $packageOutput = Invoke-MoonCommand -Context "package list for $module" -Arguments @('-C', "modules/$module", 'package', '--frozen', '--list') -CaptureCombined
      $modulePolicy = @($policy.modules | Where-Object { [string]$_.path -ceq "modules/$module" })[0]
      Assert-PackageList -ModulePolicy $modulePolicy -Output $packageOutput
    }
  }
  Invoke-QualityStage 'Read-only tracked checkout proof' {
    $finalTrackedDiff = Get-TrackedDiffSnapshot
    if ($finalTrackedDiff -cne $initialTrackedDiff) {
      throw 'Required quality commands changed tracked files.'
    }
  }
  Write-Host 'Required quality lane passed.'
}

function Invoke-LlvmExperimentalQuality {
  $policyPath = 'policy/foundation.json'
  Write-Host 'LLVM is experimental, unsupported by the required target contract, and non-blocking in CI.'
  Invoke-QualityStage 'D-14 exact toolchain identity before LLVM experiment' {
    Assert-Toolchain -PolicyPath $policyPath
  }
  Invoke-QualityStage 'Experimental LLVM check' {
    Invoke-MoonCommand -Context 'experimental LLVM workspace check' -Arguments @('check', '--target', 'llvm', '--deny-warn', '--frozen')
  }
  Invoke-QualityStage 'Experimental LLVM test' {
    Invoke-MoonCommand -Context 'experimental LLVM workspace test' -Arguments @('test', '--target', 'llvm', '--frozen')
  }
  Write-Host 'Experimental LLVM lane passed; this does not establish supported-target status.'
}

function Invoke-MoonQuality {
  [CmdletBinding()]
  param([Parameter(Mandatory)][ValidateSet('Required', 'LlvmExperimental')][string]$Lane)

  if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "PowerShell 7 or newer is required; found $($PSVersionTable.PSVersion)."
  }
  switch ($Lane) {
    'Required' { Invoke-RequiredQuality }
    'LlvmExperimental' { Invoke-LlvmExperimentalQuality }
    default { throw "Unsupported quality lane '$Lane'." }
  }
}
