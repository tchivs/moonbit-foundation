[CmdletBinding()]
param(
  [switch]$Check,
  [switch]$ManifestSelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$Root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$CasesPath = Join-Path $Root 'fixtures\ppm\cases.json'
$OutputPath = Join-Path $Root 'modules\mb-image\ppm\generated_vectors.mbt'
$ManifestPath = Join-Path $Root 'fixtures\manifest.json'

function Bytes-Literal([string]$Hex) {
  $clean = $Hex.Replace(' ', '')
  if (($clean.Length % 2) -ne 0) { throw "Odd payload hex length: $Hex" }
  $parts = for ($i = 0; $i -lt $clean.Length; $i += 2) { '\x' + $clean.Substring($i, 2).ToLowerInvariant() }
  return 'b"' + ($parts -join '') + '"'
}
function Canonical-Literal([object]$Case) {
  $header = "P6`n$($Case.width) $($Case.height)`n255`n"
  $headerHex = -join ($Utf8NoBom.GetBytes($header) | ForEach-Object { '\x{0:x2}' -f $_ })
  $clean = ([string]$Case.payload_hex).Replace(' ', '')
  $payloadParts = @()
  for ($i = 0; $i -lt $clean.Length; $i += 2) { $payloadParts += '\x' + $clean.Substring($i, 2).ToLowerInvariant() }
  $payloadHex = -join $payloadParts
  return 'b"' + $headerHex + $payloadHex + '"'
}
function Bytes-Equal([byte[]]$Left, [byte[]]$Right) {
  if ($Left.Length -ne $Right.Length) { return $false }
  for ($i = 0; $i -lt $Left.Length; $i++) { if ($Left[$i] -ne $Right[$i]) { return $false } }
  return $true
}
function Write-Or-Check([string]$Path, [string]$Text) {
  $expected = $Utf8NoBom.GetBytes($Text)
  if ($Check) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "Generated artifact missing: $Path" }
    $actual = [System.IO.File]::ReadAllBytes($Path)
    if (-not (Bytes-Equal $actual $expected)) { throw "Generated artifact stale: $Path" }
  } else {
    [System.IO.File]::WriteAllBytes($Path, $expected)
  }
}
function Format-Moon([string]$Text) {
  $temporary = Join-Path $Root 'modules\mb-image\ppm\generated_vectors.format.mbt'
  try {
    [System.IO.File]::WriteAllBytes($temporary, $Utf8NoBom.GetBytes($Text))
    & moon fmt $temporary | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'moon fmt failed for generated PPM vectors.' }
    return [System.IO.File]::ReadAllText($temporary, $Utf8NoBom)
  } finally {
    Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
  }
}

function Merge-PpmManifestRecord {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ExistingRecords,
    [Parameter(Mandatory)][object]$PpmRecord
  )

  $ownedId = 'ppm-p6-conformance-vectors'
  $seen = $false
  $merged = [System.Collections.Generic.List[object]]::new()
  foreach ($existingRecord in $ExistingRecords) {
    if ([string]$existingRecord.id -ceq $ownedId) {
      if ($seen) {
        throw "Duplicate owned PPM manifest record ID '$ownedId'."
      }
      $seen = $true
      $merged.Add($PpmRecord)
    } else {
      $merged.Add($existingRecord)
    }
  }
  if (-not $seen) { $merged.Add($PpmRecord) }
  return $merged.ToArray()
}

function Invoke-ManifestSelfTest {
  [CmdletBinding()]
  param()

  function Assert-SelfTest([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "PPM manifest self-test failed: $Message" }
  }

  $ownedId = 'ppm-p6-conformance-vectors'
  $canonical = [ordered]@{ id=$ownedId; path='fixtures/ppm/cases.json'; sha256='canonical' }
  $foreignA = [pscustomobject][ordered]@{ id='foreign-a'; path='a'; nested=[ordered]@{ value=1; label='alpha' } }
  $foreignB = [pscustomobject][ordered]@{ id='foreign-b'; path='b'; nested=[ordered]@{ value=2; label='beta' } }
  $foreignAJson = $foreignA | ConvertTo-Json -Depth 10 -Compress
  $foreignBJson = $foreignB | ConvertTo-Json -Depth 10 -Compress

  $duplicateMessage = $null
  try {
    Merge-PpmManifestRecord -ExistingRecords @(
      [ordered]@{ id=$ownedId },
      [ordered]@{ id=$ownedId }
    ) -PpmRecord $canonical | Out-Null
  } catch {
    $duplicateMessage = $_.Exception.Message
  }
  $expectedDuplicate = "Duplicate owned PPM manifest record ID '$ownedId'."
  if ($duplicateMessage -cne $expectedDuplicate) {
    throw "PPM manifest self-test duplicate expected '$expectedDuplicate', got '$duplicateMessage'."
  }

  $missing = @(Merge-PpmManifestRecord -ExistingRecords @($foreignA, $foreignB) -PpmRecord $canonical)
  Assert-SelfTest ($missing.Count -eq 3) 'missing merge count changed'
  Assert-SelfTest ([object]::ReferenceEquals($missing[0], $foreignA)) 'first foreign record identity changed during missing append'
  Assert-SelfTest ([object]::ReferenceEquals($missing[1], $foreignB)) 'second foreign record identity changed during missing append'
  Assert-SelfTest ([object]::ReferenceEquals($missing[2], $canonical)) 'missing canonical PPM record was not appended'

  $staleOwned = [ordered]@{ id=$ownedId; path='stale'; sha256='stale' }
  $replaced = @(Merge-PpmManifestRecord -ExistingRecords @($foreignA, $staleOwned, $foreignB) -PpmRecord $canonical)
  Assert-SelfTest ($replaced.Count -eq 3) 'replacement merge count changed'
  Assert-SelfTest ([object]::ReferenceEquals($replaced[0], $foreignA)) 'first foreign record moved during replacement'
  Assert-SelfTest ([object]::ReferenceEquals($replaced[1], $canonical)) 'canonical PPM record was not replaced at the same index'
  Assert-SelfTest ([object]::ReferenceEquals($replaced[2], $foreignB)) 'second foreign record moved during replacement'
  Assert-SelfTest (($replaced[0] | ConvertTo-Json -Depth 10 -Compress) -ceq $foreignAJson) 'first foreign serialized values changed'
  Assert-SelfTest (($replaced[2] | ConvertTo-Json -Depth 10 -Compress) -ceq $foreignBJson) 'second foreign serialized values changed'

  $completeInput = @($foreignA, $canonical, $foreignB)
  $completeBefore = $completeInput | ConvertTo-Json -Depth 10 -Compress
  $completeOnce = @(Merge-PpmManifestRecord -ExistingRecords $completeInput -PpmRecord $canonical)
  $completeTwice = @(Merge-PpmManifestRecord -ExistingRecords $completeOnce -PpmRecord $canonical)
  Assert-SelfTest (($completeOnce | ConvertTo-Json -Depth 10 -Compress) -ceq $completeBefore) 'complete input was not logically idempotent'
  Assert-SelfTest (($completeTwice | ConvertTo-Json -Depth 10 -Compress) -ceq $completeBefore) 'second complete merge was not byte/logically idempotent'
  Assert-SelfTest ([object]::ReferenceEquals($completeOnce[0], $foreignA)) 'complete merge changed first foreign identity'
  Assert-SelfTest ([object]::ReferenceEquals($completeOnce[2], $foreignB)) 'complete merge changed second foreign identity'

  Write-Host 'PPM manifest self-test passed.'
}

if ($ManifestSelfTest) {
  Invoke-ManifestSelfTest
  return
}

$data = Get-Content -Raw -LiteralPath $CasesPath | ConvertFrom-Json
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('// Generated by scripts/fixtures/Generate-PpmVectors.ps1. Do not edit.')
$lines.Add('')
$lines.Add('///|')
$lines.Add('fn _generated_ppm_cases() -> Array[(String, Bytes, Bytes)] {')
$lines.Add('  [')
foreach ($case in $data.canonical_cases) {
  $payload = Bytes-Literal $case.payload_hex
  $canonical = Canonical-Literal $case
  $lines.Add(('    ("{0}", {1}, {2}),' -f $case.id, $canonical, $payload))
}
$lines.Add('  ]')
$lines.Add('}')
$lines.Add('')
$lines.Add('///|')
$lines.Add('fn _generated_ppm_chunk_schedules() -> Array[(String, Array[UInt64])] {')
$lines.Add('  [')
foreach ($schedule in $data.chunk_schedules) {
  $chunks = (@($schedule.chunks) | ForEach-Object { "${_}UL" }) -join ', '
  $lines.Add(('    ("{0}", [{1}]),' -f $schedule.id, $chunks))
}
$lines.Add('  ]')
$lines.Add('}')
$lines.Add('')
$lines.Add('///|')
$lines.Add('fn _generated_ppm_adversarial_ids() -> Array[String] {')
$ids = (@($data.adversarial_cases) | ForEach-Object { '"' + $_.id + '"' }) -join ', '
$lines.Add("  [$ids]")
$lines.Add('}')
$moon = Format-Moon (($lines -join "`n") + "`n")
Write-Or-Check $OutputPath $moon

$caseBytes = [System.IO.File]::ReadAllBytes($CasesPath)
$digest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($caseBytes)).ToLowerInvariant()
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
$record = [ordered]@{
  id='ppm-p6-conformance-vectors'; path='fixtures/ppm/cases.json'; origin='generated'
  source='https://netpbm.sourceforge.net/doc/ppm.html plus repository-derived adversarial schedules'
  author='MoonBit Native Foundation project generator'; retrieval_date='2026-07-17'; sha256=$digest
  license='Apache-2.0'; redistribution_status='not-applicable'
  expected_use='QUAL-01 and QUAL-03 strict P6 canonical, adversarial, progress, and metamorphic conformance'
}
$records = @(Merge-PpmManifestRecord -ExistingRecords @($manifest.records) -PpmRecord $record)
$ordered = [ordered]@{
  schema_version=$manifest.schema_version; preferred_origin=$manifest.preferred_origin
  required_record_fields=@($manifest.required_record_fields); allowed_origins=@($manifest.allowed_origins)
  allowed_redistribution_statuses=@($manifest.allowed_redistribution_statuses)
  external_requires_confirmed_redistribution=$manifest.external_requires_confirmed_redistribution
  records=$records
}
$manifestText = (($ordered | ConvertTo-Json -Depth 20).Replace("`r`n", "`n").TrimEnd() + "`n")
Write-Or-Check $ManifestPath $manifestText
Write-Host 'PPM vector generation/check passed.'
