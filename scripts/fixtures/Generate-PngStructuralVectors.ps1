[CmdletBinding()]
param([switch]$Check)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$Root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$CasesPath = Join-Path $Root 'fixtures\png\cases.json'
$OutputPath = Join-Path $Root 'modules\mb-image\png\generated_vectors.mbt'
$TestOutputPath = Join-Path $Root 'modules\mb-image\png\generated_vectors_test.mbt'
$ManifestPath = Join-Path $Root 'fixtures\manifest.json'
$Signature = [byte[]](0x89,0x50,0x4e,0x47,0x0d,0x0a,0x1a,0x0a)

function Join-ByteArrays([object[]]$Parts) {
  $result = [Collections.Generic.List[byte]]::new()
  foreach ($part in $Parts) { if ($null -ne $part) { $result.AddRange([byte[]]$part) } }
  return ,$result.ToArray()
}
function U32([uint64]$Value) {
  [byte[]]@(
    [byte](($Value -shr 24) -band 255), [byte](($Value -shr 16) -band 255),
    [byte](($Value -shr 8) -band 255), [byte]($Value -band 255)
  )
}
function Get-Crc([byte[]]$Data) {
  [uint64]$crc = 0xffffffffUL
  foreach ($byte in $Data) { $crc = $crc -bxor [uint64]$byte; for ($bit = 0; $bit -lt 8; $bit++) { if (($crc -band 1UL) -eq 1UL) { $crc = (($crc -shr 1) -bxor 0xedb88320UL) -band 0xffffffffUL } else { $crc = ($crc -shr 1) -band 0xffffffffUL } } }
  ($crc -bxor 0xffffffffUL) -band 0xffffffffUL
}
function New-Chunk([string]$Type, [byte[]]$Payload) {
  $kind = [Text.Encoding]::ASCII.GetBytes($Type)
  $crc = Get-Crc (Join-ByteArrays @($kind, $Payload))
  return ,(Join-ByteArrays @((U32 $Payload.Length), $kind, $Payload, (U32 $crc)))
}
function New-Ihdr([byte[]]$Payload) { New-Chunk 'IHDR' $Payload }
function Get-Ihdr([bool]$Rgba = $false) { [byte[]]$p = 0,0,0,1,0,0,0,1,8,($(if($Rgba){6}else{2})),0,0,0; New-Ihdr $p }
function Get-Idat { New-Chunk 'IDAT' ([byte[]]@()) }
function Get-Iend { New-Chunk 'IEND' ([byte[]]@()) }
function Assemble([object[]]$Chunks) { return ,(Join-ByteArrays @($Signature, (Join-ByteArrays $Chunks))) }
function Before-Idat([byte[]]$Chunk) { Assemble @((Get-Ihdr), $Chunk, (Get-Idat), (Get-Iend)) }
function After-Idat([byte[]]$Chunk) { Assemble @((Get-Ihdr), (Get-Idat), $Chunk, (Get-Iend)) }
function Get-Semantic([string]$Type) { Before-Idat (New-Chunk $Type ([byte[]]@())) }
function Corrupt([byte[]]$Data) { $copy = [byte[]]$Data.Clone(); $copy[$copy.Length-1] = $copy[$copy.Length-1] -bxor 1; $copy }
function Get-CaseBytes([string]$Id) {
  $rgb = Assemble @((Get-Ihdr), (Get-Idat), (Get-Iend)); $rgba = Assemble @((Get-Ihdr $true), (Get-Idat), (Get-Iend))
  switch ($Id) {
    'empty-signature' { return [byte[]]@() }; 'short-signature' { return $Signature[0..3] }; 'truncated-signature-7' { return $Signature[0..6] }; 'bad-signature' { return [byte[]](0,0,0,0,0,0,0,0) }
    'truncated-chunk-length' { return Join-ByteArrays @($Signature,([byte[]](0,0,0))) }; 'truncated-chunk-type' { return Join-ByteArrays @($Signature,(U32 0),([byte[]](73,72,68))) }; 'overlong-chunk' { return Join-ByteArrays @($Signature,(U32 2147483648)) }
    'non-letter-type' { return Join-ByteArrays @($Signature,(U32 0),([byte[]](0,0,0,0))) }; 'reserved-third-lowercase' { return Join-ByteArrays @($Signature,(U32 0),([byte[]](73,65,97,68))) }
    'ihdr-not-first' { return Assemble @((New-Chunk 'abCD' ([byte[]]@())),(Get-Ihdr),(Get-Idat),(Get-Iend)) }; 'duplicate-ihdr' { return Assemble @((Get-Ihdr),(Get-Ihdr),(Get-Idat),(Get-Iend)) }; 'ihdr-length-12' { return Assemble @((New-Ihdr ([byte[]](0,0,0,1,0,0,0,1,8,2,0,0))),(Get-Idat),(Get-Iend)) }
    'ihdr-zero-width' { return Assemble @((New-Ihdr ([byte[]](0,0,0,0,0,0,0,1,8,2,0,0,0))),(Get-Idat),(Get-Iend)) }; 'ihdr-zero-height' { return Assemble @((New-Ihdr ([byte[]](0,0,0,1,0,0,0,0,8,2,0,0,0))),(Get-Idat),(Get-Iend)) }
    'ihdr-bit-depth-1' { return Assemble @((New-Ihdr ([byte[]](0,0,0,1,0,0,0,1,1,2,0,0,0))),(Get-Idat),(Get-Iend)) }
    'ihdr-colour-grayscale' { return Assemble @((New-Ihdr ([byte[]](0,0,0,1,0,0,0,1,8,0,0,0,0))),(Get-Idat),(Get-Iend)) }; 'ihdr-colour-invalid-1' { return Assemble @((New-Ihdr ([byte[]](0,0,0,1,0,0,0,1,8,1,0,0,0))),(Get-Idat),(Get-Iend)) }; 'ihdr-colour-indexed' { return Assemble @((New-Ihdr ([byte[]](0,0,0,1,0,0,0,1,8,3,0,0,0))),(Get-Idat),(Get-Iend)) }; 'ihdr-colour-grayscale-alpha' { return Assemble @((New-Ihdr ([byte[]](0,0,0,1,0,0,0,1,8,4,0,0,0))),(Get-Idat),(Get-Iend)) }; 'ihdr-colour-invalid-5' { return Assemble @((New-Ihdr ([byte[]](0,0,0,1,0,0,0,1,8,5,0,0,0))),(Get-Idat),(Get-Iend)) }
    'ihdr-compression-method' { return Assemble @((New-Ihdr ([byte[]](0,0,0,1,0,0,0,1,8,2,1,0,0))),(Get-Idat),(Get-Iend)) }; 'ihdr-filter-method' { return Assemble @((New-Ihdr ([byte[]](0,0,0,1,0,0,0,1,8,2,0,1,0))),(Get-Idat),(Get-Iend)) }; 'ihdr-interlace-method' { return Assemble @((New-Ihdr ([byte[]](0,0,0,1,0,0,0,1,8,2,0,0,1))),(Get-Idat),(Get-Iend)) }
    'ihdr-crc' { $x=[byte[]]$rgb.Clone(); $x[32]=$x[32]-bxor 1; return $x }; 'idat-before-ihdr' { return Assemble @((Get-Idat),(Get-Ihdr),(Get-Iend)) }; 'split-contiguous-idat' { return Assemble @((Get-Ihdr),(Get-Idat),(Get-Idat),(Get-Iend)) }; 'ancillary-after-idat' { return After-Idat (New-Chunk 'abCD' ([byte[]]@())) }; 'idat-after-semantic' { return Assemble @((Get-Ihdr),(Get-Idat),(New-Chunk 'PLTE' ([byte[]]@())),(Get-Idat),(Get-Iend)) }
    'missing-idat' { return Assemble @((Get-Ihdr),(Get-Iend)) }; 'separated-idat' { return Assemble @((Get-Ihdr),(Get-Idat),(New-Chunk 'abCD' ([byte[]]@())),(Get-Idat),(Get-Iend)) }; 'iend-before-idat' { return Assemble @((Get-Ihdr),(Get-Iend)) }; 'iend-before-ihdr' { return Assemble @((Get-Iend)) }; 'truncated-iend-crc' { $iend=Get-Iend; return Join-ByteArrays @((Assemble @((Get-Ihdr),(Get-Idat))),$iend[0..10]) }; 'iend-crc' { return Assemble @((Get-Ihdr),(Get-Idat),(Corrupt (Get-Iend))) }; 'nonempty-iend' { return Assemble @((Get-Ihdr),(Get-Idat),(New-Chunk 'IEND' ([byte[]](0)))) }; 'duplicate-iend' { return Assemble @((Get-Ihdr),(Get-Idat),(Get-Iend),(Get-Iend)) }; 'post-iend-idat' { return Assemble @((Get-Ihdr),(Get-Idat),(Get-Iend),(Get-Idat)) }; 'trailing-byte' { return Join-ByteArrays @($rgb,([byte[]](0))) }
    'idat-crc' { return Assemble @((Get-Ihdr),(Corrupt (Get-Idat)),(Get-Iend)) }; 'ancillary-crc' { return Before-Idat (Corrupt (New-Chunk 'abCD' ([byte[]]@()))) }; 'ancillary-discard' { return Before-Idat (New-Chunk 'abCD' ([byte[]]@())) }; 'unknown-critical' { return Before-Idat (New-Chunk 'ABCD' ([byte[]]@())) }; 'semantic-palette' { return Before-Idat (New-Chunk 'PLTE' ([byte[]](0,0,0))) }; 'semantic-crc' { return Before-Idat (Corrupt (New-Chunk 'PLTE' ([byte[]]@()))) }
    'trns-gray-length' { return Get-Semantic 'tRNS' }; 'semantic-chrm' { return Get-Semantic 'cHRM' }; 'semantic-gama' { return Get-Semantic 'gAMA' }; 'semantic-iccp' { return Get-Semantic 'iCCP' }; 'semantic-sbit' { return Get-Semantic 'sBIT' }; 'semantic-srgb' { return Get-Semantic 'sRGB' }; 'semantic-cicp' { return Get-Semantic 'cICP' }; 'semantic-mdcv' { return Get-Semantic 'mDCv' }; 'semantic-clli' { return Get-Semantic 'cLLi' }; 'semantic-actl' { return Get-Semantic 'acTL' }; 'semantic-fctl' { return Get-Semantic 'fcTL' }; 'semantic-fdat' { return Get-Semantic 'fdAT' }
    'rgb-structural' { return $rgb }; 'rgba-structural' { return $rgba }; default { throw "Unknown PNG case construction: $Id" }
  }
}

$cases = Get-Content -Raw -LiteralPath $CasesPath | ConvertFrom-Json
if ($cases.schema_version -ne '2.0.0') { throw 'PNG fixture schema version is stale.' }
$requiredCaseIds = @('short-signature','empty-signature','truncated-signature-7','bad-signature','truncated-chunk-length','truncated-chunk-type','overlong-chunk','non-letter-type','reserved-third-lowercase','ihdr-not-first','duplicate-ihdr','ihdr-length-12','ihdr-zero-width','ihdr-zero-height','ihdr-bit-depth-1','ihdr-colour-grayscale','ihdr-colour-invalid-1','ihdr-colour-indexed','ihdr-colour-grayscale-alpha','ihdr-colour-invalid-5','ihdr-compression-method','ihdr-filter-method','ihdr-interlace-method','ihdr-crc','idat-before-ihdr','split-contiguous-idat','ancillary-after-idat','idat-after-semantic','missing-idat','separated-idat','iend-before-idat','iend-before-ihdr','truncated-iend-crc','iend-crc','nonempty-iend','duplicate-iend','post-iend-idat','trailing-byte','strict-eof-trailing-at-max','idat-crc','ancillary-crc','ancillary-discard','ancillary-preserve','unknown-critical','semantic-palette','semantic-crc','trns-gray-length','semantic-chrm','semantic-gama','semantic-iccp','semantic-sbit','semantic-srgb','semantic-cicp','semantic-mdcv','semantic-clli','semantic-actl','semantic-fctl','semantic-fdat','rgb-structural','rgba-structural','rgba-at-ceiling','rgb-exact-input-ceiling','input-57-below','width-at-ceiling','width-below','height-at-ceiling','height-below','pixels-at-ceiling','pixels-below','shared-output-at-ceiling','image-bytes-below-shared-output-bound','output-bytes-at-ceiling','output-bytes-below','work-at-ceiling','work-below','budget-bytes-at-ceiling','budget-bytes-below','budget-allocations-at-ceiling','budget-allocations-below','budget-allocation-size-at-ceiling','budget-allocation-size-below','budget-width-at-ceiling','budget-width-below','budget-height-at-ceiling','budget-height-below','budget-pixels-at-ceiling','budget-pixels-below','budget-work-at-ceiling','budget-work-below')
$actual = @($cases.cases | ForEach-Object { [string]$_.id }); if (($actual | Select-Object -Unique).Count -ne $actual.Count -or (Compare-Object $requiredCaseIds $actual)) { throw 'PNG fixture matrix is missing, duplicate, or has an unplanned case ID.' }
foreach ($case in $cases.cases) { foreach ($field in 'id','mutation_phase','construction','expected','options','limits','budget','immutable_caller_state','routes') { if ($null -eq $case.PSObject.Properties[$field]) { throw "PNG case missing ${field}: $($case.id)" } }; foreach($field in 'category','code','context'){ if($null -eq $case.expected.PSObject.Properties[$field]){throw "PNG expected missing ${field}: $($case.id)"} }; if($null -eq $cases.limits_profiles.PSObject.Properties[[string]$case.limits] -or $null -eq $cases.budget_profiles.PSObject.Properties[[string]$case.budget]){throw "PNG case profile missing: $($case.id)"}; if(-not $case.routes.public -or -not $case.routes.whitebox){throw "PNG case lacks P+W routing: $($case.id)"}; [void](Get-CaseBytes ([string]$case.construction)) }

function Moon-Bytes([AllowNull()][byte[]]$Bytes) { if ($null -eq $Bytes -or $Bytes.Length -eq 0) { return '' }; (($Bytes | ForEach-Object { '\x{0:x2}' -f $_ }) -join '') }
function Moon-Limits($Values) { 'PngGeneratedLimits::{{ probe: {0}UL, input: {1}UL, output: {2}UL, width: {3}UL, height: {4}UL, pixels: {5}UL, work: {6}UL }}' -f $Values }
function Moon-Budget($Values) { 'PngGeneratedBudget::{{ bytes: {0}UL, allocations: {1}UL, allocation_size: {2}UL, width: {3}UL, height: {4}UL, pixels: {5}UL, depth: {6}UL, work: {7}UL }}' -f $Values }
$header = @('// Generated by scripts/fixtures/Generate-PngStructuralVectors.ps1. Do not edit.','','///|','priv struct PngGeneratedLimits { probe : UInt64; input : UInt64; output : UInt64; width : UInt64; height : UInt64; pixels : UInt64; work : UInt64 }','','///|','priv struct PngGeneratedBudget { bytes : UInt64; allocations : UInt64; allocation_size : UInt64; width : UInt64; height : UInt64; pixels : UInt64; depth : UInt64; work : UInt64 }','','///|','priv struct PngGeneratedCase { id : String; bytes : Bytes; category : String; code : String; context : String; preserve_opaque_metadata : Bool; limits : PngGeneratedLimits; budget : PngGeneratedBudget; immutable_caller_state : Bool }','')
function Render-Table([string]$Name, [bool]$IncludeTypes) { $lines=[Collections.Generic.List[string]]::new(); if($IncludeTypes){$lines.AddRange([string[]]$header)}else{$lines.Add('// Generated by scripts/fixtures/Generate-PngStructuralVectors.ps1. Do not edit.');$lines.Add('')}; $lines.Add('///|'); $lines.Add("fn $Name() -> Array[PngGeneratedCase] {"); $lines.Add('  ['); foreach($case in $cases.cases){$b=Moon-Bytes (Get-CaseBytes $case.construction); $l=Moon-Limits $cases.limits_profiles.($case.limits); $q=Moon-Budget $cases.budget_profiles.($case.budget); $p=([bool]$case.options.preserve_opaque_metadata).ToString().ToLowerInvariant(); $m=([bool]$case.immutable_caller_state).ToString().ToLowerInvariant(); $lines.Add(('    PngGeneratedCase::{{ id: "{0}", bytes: b"{1}", category: "{2}", code: "{3}", context: "{4}", preserve_opaque_metadata: {5}, limits: {6}, budget: {7}, immutable_caller_state: {8} }},' -f $case.id,$b,$case.expected.category,$case.expected.code,$case.expected.context,$p,$l,$q,$m))}; $lines.Add('  ]');$lines.Add('}');$lines.Add(''); ($lines -join "`n")+"`n" }
$text=Render-Table '_generated_png_structural_cases' $true; $testText=Render-Table '_generated_png_public_cases' $true
$sha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([IO.File]::ReadAllBytes($CasesPath))).ToLowerInvariant(); $manifest=Get-Content -Raw $ManifestPath | ConvertFrom-Json; $record=@($manifest.records|Where-Object {$_.id -ceq 'png-structural-safety-vectors'}); if($record.Count-ne 1){throw 'PNG manifest record missing.'}; foreach($field in $manifest.required_record_fields){if($null-eq $record[0].PSObject.Properties[$field] -or [string]::IsNullOrWhiteSpace([string]$record[0].$field)){throw "PNG manifest field missing: $field"}}; if($record[0].path -cne 'fixtures/png/cases.json' -or $record[0].origin -cne 'generated' -or $record[0].license -cne 'Apache-2.0'){throw 'PNG fixture manifest identity is invalid.'}; if($Check -and $record[0].sha256 -cne $sha){throw 'PNG fixture manifest digest is stale.'}; if(-not $Check){$record[0].sha256=$sha;[IO.File]::WriteAllText($ManifestPath,(($manifest|ConvertTo-Json -Depth 20)+"`n"),$Utf8NoBom)}
if($Check){if(-not(Test-Path $OutputPath)-or([IO.File]::ReadAllText($OutputPath,$Utf8NoBom).Replace("`r`n","`n"))-cne$text){throw "Generated artifact stale: $OutputPath"};if(-not(Test-Path $TestOutputPath)-or([IO.File]::ReadAllText($TestOutputPath,$Utf8NoBom).Replace("`r`n","`n"))-cne$testText){throw "Generated artifact stale: $TestOutputPath"}}else{[IO.File]::WriteAllText($OutputPath,$text,$Utf8NoBom);[IO.File]::WriteAllText($TestOutputPath,$testText,$Utf8NoBom)}
Write-Host "PNG structural vector generation/check passed ($($cases.cases.Count) P+W cases)."
