[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')
if (-not (Get-Command ConvertTo-ReleaseCanonicalZip -ErrorAction SilentlyContinue)) {
  throw 'REL-XPLAT-CANONICALIZER: deterministic ZIP canonicalizer is missing.'
}
$moduleRelatives = @('modules/mb-core', 'modules/mb-color', 'modules/mb-image')
$archiveNames = [ordered]@{
  'mb-core' = 'tchivs-mb-core-0.1.0.zip'
  'mb-color' = 'tchivs-mb-color-0.1.0.zip'
  'mb-image' = 'tchivs-mb-image-0.1.0.zip'
}

function Invoke-Native {
  param(
    [Parameter(Mandatory)][string]$Context,
    [Parameter(Mandatory)][string]$Command,
    [Parameter(Mandatory)][string[]]$Arguments
  )
  $output = @(& $Command @Arguments 2>&1 | ForEach-Object { $_.ToString().TrimEnd() })
  if ($LASTEXITCODE -ne 0) { throw "$Context failed (exit $LASTEXITCODE): $($output -join [Environment]::NewLine)" }
  return $output
}

function Get-ZipEntryDigestMap {
  param([Parameter(Mandatory)][string]$Path)
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archive = [IO.Compression.ZipFile]::OpenRead($Path)
  try {
    $result = [ordered]@{}
    foreach ($entry in $archive.Entries) {
      if ($result.Contains($entry.FullName)) { throw "Duplicate ZIP entry '$($entry.FullName)'." }
      $stream = $entry.Open()
      try {
        $memory = [IO.MemoryStream]::new()
        try {
          $stream.CopyTo($memory)
          $digest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($memory.ToArray())).ToLowerInvariant()
        } finally { $memory.Dispose() }
      } finally { $stream.Dispose() }
      $result[$entry.FullName] = [pscustomobject][ordered]@{
        sha256 = $digest
        length = [Int64]$entry.Length
        compressed_length = [Int64]$entry.CompressedLength
        last_write_time = $entry.LastWriteTime.ToString('o')
        external_attributes = [int]$entry.ExternalAttributes
      }
    }
    return $result
  } finally { $archive.Dispose() }
}

function Get-CanonicalZipMetadata {
  param([Parameter(Mandatory)][string]$Path)
  $bytes = [IO.File]::ReadAllBytes($Path)
  $eocdOffset = -1
  for ($candidate = $bytes.Length - 22; $candidate -ge [Math]::Max(0, $bytes.Length - 65557); $candidate--) {
    if ($bytes[$candidate] -eq 0x50 -and $bytes[$candidate + 1] -eq 0x4b -and $bytes[$candidate + 2] -eq 0x05 -and $bytes[$candidate + 3] -eq 0x06) {
      $commentLength = [BitConverter]::ToUInt16($bytes, $candidate + 20)
      if ($candidate + 22 + $commentLength -eq $bytes.Length) { $eocdOffset = $candidate; break }
    }
  }
  if ($eocdOffset -lt 0) { throw 'REL-XPLAT-METADATA: end-of-central-directory is missing.' }
  $count = [int][BitConverter]::ToUInt16($bytes, $eocdOffset + 10)
  $offset = [int][BitConverter]::ToUInt32($bytes, $eocdOffset + 16)
  $result = [Collections.Generic.List[object]]::new()
  for ($index = 0; $index -lt $count; $index++) {
    if ($bytes[$offset] -ne 0x50 -or $bytes[$offset + 1] -ne 0x4b -or $bytes[$offset + 2] -ne 0x01 -or $bytes[$offset + 3] -ne 0x02) { throw "REL-XPLAT-METADATA: central entry $index is malformed." }
    $nameLength = [BitConverter]::ToUInt16($bytes, $offset + 28)
    $extraLength = [BitConverter]::ToUInt16($bytes, $offset + 30)
    $commentLength = [BitConverter]::ToUInt16($bytes, $offset + 32)
    $name = [Text.Encoding]::UTF8.GetString($bytes, $offset + 46, $nameLength)
    $localOffset = [int][BitConverter]::ToUInt32($bytes, $offset + 42)
    if ($bytes[$localOffset] -ne 0x50 -or $bytes[$localOffset + 1] -ne 0x4b -or $bytes[$localOffset + 2] -ne 0x03 -or $bytes[$localOffset + 3] -ne 0x04) { throw "REL-XPLAT-METADATA: local entry '$name' is malformed." }
    $localNameLength = [BitConverter]::ToUInt16($bytes, $localOffset + 26)
    $localName = [Text.Encoding]::UTF8.GetString($bytes, $localOffset + 30, $localNameLength)
    $result.Add([pscustomobject][ordered]@{
      name = $name
      local_name = $localName
      made_by = [BitConverter]::ToUInt16($bytes, $offset + 4)
      central_method = [BitConverter]::ToUInt16($bytes, $offset + 10)
      local_method = [BitConverter]::ToUInt16($bytes, $localOffset + 8)
      central_time = [BitConverter]::ToUInt16($bytes, $offset + 12)
      central_date = [BitConverter]::ToUInt16($bytes, $offset + 14)
      local_time = [BitConverter]::ToUInt16($bytes, $localOffset + 10)
      local_date = [BitConverter]::ToUInt16($bytes, $localOffset + 12)
      external_attributes = ('{0:x8}' -f [BitConverter]::ToUInt32($bytes, $offset + 38))
    })
    $offset += 46 + $nameLength + $extraLength + $commentLength
  }
  return @($result)
}

function Set-ZipContainerVariant {
  param([Parameter(Mandatory)][string]$Path)
  $bytes=[IO.File]::ReadAllBytes($Path);$count=0
  for($offset=0;$offset-le$bytes.Length-46;$offset++){
    if($bytes[$offset]-ne0x50-or$bytes[$offset+1]-ne0x4b-or$bytes[$offset+2]-ne0x01-or$bytes[$offset+3]-ne0x02){continue}
    $nameLength=[BitConverter]::ToUInt16($bytes,$offset+28);$extraLength=[BitConverter]::ToUInt16($bytes,$offset+30);$commentLength=[BitConverter]::ToUInt16($bytes,$offset+32)
    $bytes[$offset+5]=0x00;0..3|ForEach-Object{$bytes[$offset+38+$_]=0x00};$count++;$offset += 45+$nameLength+$extraLength+$commentLength
  }
  if($count-eq0){throw 'REL-XPLAT-VARIANT: no central entries found.'};[IO.File]::WriteAllBytes($Path,$bytes)
}

function Assert-CanonicalizerRejectsUnsafePath {
  param([Parameter(Mandatory)][string]$Name)
  $fixturePath = Join-Path $tempRoot ('unsafe-' + [Guid]::NewGuid().ToString('N') + '.zip')
  $file = [IO.File]::Open($fixturePath, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
  try {
    $archive = [IO.Compression.ZipArchive]::new($file, [IO.Compression.ZipArchiveMode]::Create, $true)
    try {
      $entry = $archive.CreateEntry($Name, [IO.Compression.CompressionLevel]::NoCompression)
      $stream = $entry.Open()
      try { $stream.WriteByte(0x41) } finally { $stream.Dispose() }
    } finally { $archive.Dispose() }
  } finally { $file.Dispose() }

  try {
    $null = ConvertTo-ReleaseCanonicalZip -Path $fixturePath
    throw "REL-XPLAT-UNSAFE-ACCEPTED: canonicalizer accepted noncanonical path '$Name'."
  } catch {
    if ($_.Exception.Message -notmatch '^REL-XPLAT-ENTRY:') { throw }
  }
}

foreach ($moduleRelative in $moduleRelatives) {
  $attributeOutput = @(Invoke-Native -Context "read $moduleRelative checkout attributes" -Command 'git' -Arguments @(
    '-C', $repoRoot, 'check-attr', 'text', 'eol', '--', "$moduleRelative/moon.mod.json"
  ))
  if (($attributeOutput -join "`n") -notmatch '(?m): text: (auto|set)$' -or
      ($attributeOutput -join "`n") -notmatch '(?m): eol: lf$') {
    throw "REL-XPLAT-EOL: $moduleRelative release inputs must be committed with text=auto and eol=lf before packaging."
  }
}

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-cross-platform-archive-' + [Guid]::NewGuid().ToString('N'))
$crlfRoot = Join-Path $tempRoot 'autocrlf-true'
$lfRoot = Join-Path $tempRoot 'autocrlf-false'
$null = New-Item -ItemType Directory -Force -Path $tempRoot
try {
  foreach ($unsafeName in @('./moon.mod.json', 'pkg//file.mbt', 'pkg/./file.mbt')) {
    Assert-CanonicalizerRejectsUnsafePath -Name $unsafeName
  }

  $null = Invoke-Native -Context 'clone release tree with autocrlf=true' -Command 'git' -Arguments @('-c', 'core.autocrlf=true', 'clone', '--quiet', '--no-hardlinks', $repoRoot, $crlfRoot)
  $null = Invoke-Native -Context 'clone release tree with autocrlf=false' -Command 'git' -Arguments @('-c', 'core.autocrlf=false', 'clone', '--quiet', '--no-hardlinks', $repoRoot, $lfRoot)
  $tracked = @(Invoke-Native -Context 'list all module release inputs' -Command 'git' -Arguments @('-C', $repoRoot, 'ls-files', '--', 'modules') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  if ($tracked.Count -eq 0) { throw 'REL-XPLAT-INPUT: module release inputs are missing.' }
  foreach ($relative in $tracked) {
    $crlfFile = Join-Path $crlfRoot $relative
    $lfFile = Join-Path $lfRoot $relative
    if (-not (Test-Path -LiteralPath $crlfFile -PathType Leaf) -or -not (Test-Path -LiteralPath $lfFile -PathType Leaf)) { throw "REL-XPLAT-INPUT: clone omitted '$relative'." }
    if ((Get-ReleaseSha256 -Path $crlfFile) -cne (Get-ReleaseSha256 -Path $lfFile)) { throw "REL-XPLAT-EOL: '$relative' payload bytes differ across core.autocrlf policies." }
  }

  $canonicalArchives = [ordered]@{}
  $canonicalDigests = [Collections.Generic.List[string]]::new()
  foreach ($moduleRelative in $moduleRelatives) {
    $shortName = Split-Path -Leaf $moduleRelative
    $archiveName = $archiveNames[$shortName]
    $null = Invoke-Native -Context "package $shortName with autocrlf=true" -Command 'moon' -Arguments @('-C', (Join-Path $crlfRoot $moduleRelative), 'package', '--frozen', '--list')
    $null = Invoke-Native -Context "package $shortName with autocrlf=false" -Command 'moon' -Arguments @('-C', (Join-Path $lfRoot $moduleRelative), 'package', '--frozen', '--list')
    $crlfArchives = @(Get-ChildItem -LiteralPath $crlfRoot -Recurse -File -Filter $archiveName)
    $lfArchives = @(Get-ChildItem -LiteralPath $lfRoot -Recurse -File -Filter $archiveName)
    if ($crlfArchives.Count -ne 1 -or $lfArchives.Count -ne 1) { throw "REL-XPLAT-ARCHIVE: expected exactly one $shortName package archive per clone." }
    $crlfArchive = $crlfArchives[0].FullName
    $lfArchive = $lfArchives[0].FullName
    $sourceEntries = Get-ZipEntryDigestMap -Path $crlfArchive
    $otherSourceEntries = Get-ZipEntryDigestMap -Path $lfArchive
    if (($sourceEntries.Keys -join "`n") -cne ($otherSourceEntries.Keys -join "`n")) { throw "REL-XPLAT-INVENTORY: raw $shortName entry order differs across checkout policies." }
    foreach ($name in $sourceEntries.Keys) {
      if ($sourceEntries[$name].sha256 -cne $otherSourceEntries[$name].sha256 -or $sourceEntries[$name].length -ne $otherSourceEntries[$name].length) { throw "REL-XPLAT-PAYLOAD: raw $shortName entry '$name' differs across checkout policies." }
    }
    Set-ZipContainerVariant -Path $lfArchive
    if ((Get-ReleaseSha256 -Path $crlfArchive) -ceq (Get-ReleaseSha256 -Path $lfArchive)) { throw "REL-XPLAT-VARIANT: $shortName host metadata variant did not change raw ZIP identity." }
    $null = ConvertTo-ReleaseCanonicalZip -Path $crlfArchive
    $null = ConvertTo-ReleaseCanonicalZip -Path $lfArchive
    $crlfDigest = Get-ReleaseSha256 -Path $crlfArchive
    $lfDigest = Get-ReleaseSha256 -Path $lfArchive
    $null = Assert-ReleaseCanonicalZip -Path $crlfArchive
    if ($crlfDigest -cne $lfDigest) { throw "REL-XPLAT-BYTES: $shortName canonical bytes differ ($crlfDigest vs $lfDigest)." }
    $crlfEntries = Get-ZipEntryDigestMap -Path $crlfArchive
    $lfEntries = Get-ZipEntryDigestMap -Path $lfArchive
    if (($crlfEntries.Keys -join "`n") -cne ($sourceEntries.Keys -join "`n")) { throw "REL-XPLAT-INVENTORY: $shortName canonicalization changed original entry order." }
    foreach ($name in $crlfEntries.Keys) {
      $left = $crlfEntries[$name]
      $right = $lfEntries[$name]
      $source = $sourceEntries[$name]
      if ($left.sha256 -cne $source.sha256 -or $left.length -ne $source.length) { throw "REL-XPLAT-PAYLOAD: canonical $shortName entry '$name' changed payload provenance." }
      if ($left.length -ne 0 -and $left.length -ne $left.compressed_length) { throw "REL-XPLAT-COMPRESSION: canonical $shortName entry '$name' is not stored." }
      if (($left | ConvertTo-Json -Compress) -cne ($right | ConvertTo-Json -Compress)) { throw "REL-XPLAT-ENTRY: canonical $shortName entry '$name' differs across checkout policies." }
    }
    $metadata = @(Get-CanonicalZipMetadata -Path $crlfArchive)
    if (($metadata.name -join "`n") -cne ($crlfEntries.Keys -join "`n")) { throw "REL-XPLAT-METADATA: $shortName central order differs from archive order." }
    foreach ($entry in $metadata) {
      $expectedAttributes = if ($entry.name.EndsWith('/', [StringComparison]::Ordinal)) { '41ed0000' } else { '81a40000' }
      if ($entry.local_name -cne $entry.name -or $entry.made_by -ne 0x0314 -or $entry.central_method -ne 0 -or $entry.local_method -ne 0 -or $entry.central_time -ne 0 -or $entry.local_time -ne 0 -or $entry.central_date -ne 0x21 -or $entry.local_date -ne 0x21 -or $entry.external_attributes -cne $expectedAttributes) { throw "REL-XPLAT-METADATA: canonical metadata drifted for $shortName entry '$($entry.name)'." }
    }
    $canonicalArchives[$shortName] = $crlfArchive
    $canonicalDigests.Add("$shortName=$crlfDigest")
  }

  $consumerRoot = Join-Path $tempRoot 'canonical-consumer'
  $null = New-Item -ItemType Directory -Force -Path (Join-Path $consumerRoot 'modules')
  [IO.File]::WriteAllText(
    (Join-Path $consumerRoot 'moon.work'),
    "members = [`n  `"./modules/mb-core`",`n  `"./modules/mb-color`",`n  `"./modules/mb-image`",`n]`n",
    [Text.UTF8Encoding]::new($false)
  )
  foreach ($shortName in $archiveNames.Keys) {
    $destination = Join-Path $consumerRoot "modules/$shortName"
    $null = New-Item -ItemType Directory -Force -Path $destination
    Expand-Archive -LiteralPath $canonicalArchives[$shortName] -DestinationPath $destination
  }
  $null = Invoke-Native -Context 'check three canonical archive sources' -Command 'moon' -Arguments @('-C', $consumerRoot, 'check', '--frozen', '--deny-warn', '--target', 'all')
  Write-Host "Cross-platform release archives passed: $($canonicalDigests -join ', ')"
} finally {
  if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
