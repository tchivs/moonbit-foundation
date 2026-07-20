[CmdletBinding()]
param([switch]$Check)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$path = Join-Path $root 'fixtures\png\decode-cases.json'
$cases = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
if ($cases.schema_version -ne '1.0.0' -or $cases.cases.Count -lt 6) { throw 'PNG decode corpus is stale or incomplete.' }
$required = @('rgb-stored-none','fixed-filter-suite','dynamic-rgba','bad-adler','truncated-deflate','invalid-distance')
if (Compare-Object $required @($cases.cases.id)) { throw 'PNG decode corpus IDs are incomplete.' }
Add-Type -AssemblyName System.IO.Compression
$raw = [byte[]](0,0x12,0x34,0x56)
$compressed = [byte[]](0x78,0x01,0x01,0x04,0x00,0xfb,0xff,0x00,0x12,0x34,0x56,0x00,0xf8,0x00,0x9d)
$input = [IO.MemoryStream]::new($compressed)
$zlib = [IO.Compression.ZLibStream]::new($input,[IO.Compression.CompressionMode]::Decompress)
$output = [IO.MemoryStream]::new(); $zlib.CopyTo($output); $zlib.Dispose()
if (-not ([Linq.Enumerable]::SequenceEqual([byte[]]$output.ToArray(),$raw))) { throw 'Independent .NET ZLibStream audit failed.' }
Write-Host "PNG decode vector generation/check passed ($($cases.cases.Count) cases)."
