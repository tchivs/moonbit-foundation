[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$moduleRelative = 'modules/mb-core'
$archiveName = 'tchivs-mb-core-0.1.0.zip'

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
        last_write_time = $entry.LastWriteTime.ToString('o')
        external_attributes = [int]$entry.ExternalAttributes
      }
    }
    return $result
  } finally { $archive.Dispose() }
}

$attributeOutput = @(Invoke-Native -Context 'read release checkout attributes' -Command 'git' -Arguments @(
  '-C', $repoRoot, 'check-attr', 'text', 'eol', '--', "$moduleRelative/moon.mod.json"
))
if (($attributeOutput -join "`n") -notmatch '(?m): text: (auto|set)$' -or
    ($attributeOutput -join "`n") -notmatch '(?m): eol: lf$') {
  throw 'REL-XPLAT-EOL: release inputs must be committed with text=auto and eol=lf before packaging.'
}

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-cross-platform-archive-' + [Guid]::NewGuid().ToString('N'))
$fixtureRoot = Join-Path $tempRoot 'fixture'
$crlfRoot = Join-Path $tempRoot 'autocrlf-true'
$lfRoot = Join-Path $tempRoot 'autocrlf-false'
$null = New-Item -ItemType Directory -Force -Path $fixtureRoot
try {
  $tracked = @(Invoke-Native -Context 'list mb-core release inputs' -Command 'git' -Arguments @(
    '-C', $repoRoot, 'ls-files', '--', $moduleRelative
  ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  if ($tracked.Count -eq 0) { throw 'REL-XPLAT-INPUT: mb-core has no tracked release inputs.' }
  foreach ($relative in $tracked) {
    $source = Join-Path $repoRoot $relative
    $destination = Join-Path $fixtureRoot $relative
    $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination)
    Copy-Item -LiteralPath $source -Destination $destination
  }
  Copy-Item -LiteralPath (Join-Path $repoRoot '.gitattributes') -Destination (Join-Path $fixtureRoot '.gitattributes')
  Copy-Item -LiteralPath (Join-Path $repoRoot '.gitignore') -Destination (Join-Path $fixtureRoot '.gitignore')

  $null = Invoke-Native -Context 'initialize package fixture' -Command 'git' -Arguments @('-C', $fixtureRoot, 'init', '--quiet')
  $null = Invoke-Native -Context 'configure fixture identity' -Command 'git' -Arguments @('-C', $fixtureRoot, 'config', 'user.name', 'MNF Determinism Test')
  $null = Invoke-Native -Context 'configure fixture email' -Command 'git' -Arguments @('-C', $fixtureRoot, 'config', 'user.email', 'determinism@example.invalid')
  $null = Invoke-Native -Context 'stage package fixture' -Command 'git' -Arguments @('-C', $fixtureRoot, 'add', '--', '.gitattributes', '.gitignore', $moduleRelative)
  $null = Invoke-Native -Context 'commit package fixture' -Command 'git' -Arguments @('-C', $fixtureRoot, 'commit', '--quiet', '-m', 'fixture')

  $null = Invoke-Native -Context 'clone autocrlf=true fixture' -Command 'git' -Arguments @('-c', 'core.autocrlf=true', 'clone', '--quiet', '--no-hardlinks', $fixtureRoot, $crlfRoot)
  $null = Invoke-Native -Context 'clone autocrlf=false fixture' -Command 'git' -Arguments @('-c', 'core.autocrlf=false', 'clone', '--quiet', '--no-hardlinks', $fixtureRoot, $lfRoot)
  $null = Invoke-Native -Context 'package autocrlf=true fixture' -Command 'moon' -Arguments @('-C', (Join-Path $crlfRoot $moduleRelative), 'package', '--frozen', '--list')
  $null = Invoke-Native -Context 'package autocrlf=false fixture' -Command 'moon' -Arguments @('-C', (Join-Path $lfRoot $moduleRelative), 'package', '--frozen', '--list')

  $crlfArchives = @(Get-ChildItem -LiteralPath $crlfRoot -Recurse -File -Filter $archiveName)
  $lfArchives = @(Get-ChildItem -LiteralPath $lfRoot -Recurse -File -Filter $archiveName)
  if ($crlfArchives.Count -ne 1 -or $lfArchives.Count -ne 1) { throw 'REL-XPLAT-ARCHIVE: expected exactly one mb-core package archive per clone.' }
  $crlfArchive = $crlfArchives[0].FullName
  $lfArchive = $lfArchives[0].FullName
  $crlfDigest = (Get-FileHash -LiteralPath $crlfArchive -Algorithm SHA256).Hash.ToLowerInvariant()
  $lfDigest = (Get-FileHash -LiteralPath $lfArchive -Algorithm SHA256).Hash.ToLowerInvariant()
  $crlfEntries = Get-ZipEntryDigestMap -Path $crlfArchive
  $lfEntries = Get-ZipEntryDigestMap -Path $lfArchive
  if (($crlfEntries.Keys -join "`n") -cne ($lfEntries.Keys -join "`n")) { throw 'REL-XPLAT-INVENTORY: ZIP entry order differs across checkout policies.' }
  foreach ($name in $crlfEntries.Keys) {
    $left = $crlfEntries[$name]
    $right = $lfEntries[$name]
    if (($left | ConvertTo-Json -Compress) -cne ($right | ConvertTo-Json -Compress)) {
      throw "REL-XPLAT-ENTRY: ZIP entry '$name' differs across checkout policies."
    }
  }
  if ($crlfDigest -cne $lfDigest) { throw "REL-XPLAT-BYTES: archive bytes differ ($crlfDigest vs $lfDigest)." }
  Write-Host "Cross-platform release archive passed: $crlfDigest"
} finally {
  if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}
