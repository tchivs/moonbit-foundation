[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$targets = @('js', 'wasm', 'wasm-gc', 'native')
$selectors = @(
  'PNG Adam7 public eager fidelity and frozen None compatibility',
  'PNG Adam7 public chunk fidelity, hostile identity, and frozen None compatibility'
)

function New-OwnedTargetDirectory([string]$Target) {
  $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
  $directory = [IO.Path]::GetFullPath((Join-Path $tempRoot ('mnf-png-adam7-compatibility-' + [guid]::NewGuid().ToString('N'))))
  $relative = [IO.Path]::GetRelativePath($tempRoot, $directory)
  if ([IO.Path]::IsPathRooted($relative) -or $relative -match '^\.\.' -or $relative -ne [IO.Path]::GetFileName($directory) -or [IO.Path]::GetFileName($directory) -notlike 'mnf-png-adam7-compatibility-*') {
    throw "Refusing unsafe PNG Adam7 target root: $directory"
  }
  New-Item -ItemType Directory -Path $directory -ErrorAction Stop | Out-Null
  [pscustomobject]@{ TempRoot = $tempRoot; Directory = $directory; Target = $Target }
}

function Remove-OwnedTargetDirectory($Owned) {
  $directory = [IO.Path]::GetFullPath($Owned.Directory)
  $relative = [IO.Path]::GetRelativePath($Owned.TempRoot, $directory)
  if ([IO.Path]::IsPathRooted($relative) -or $relative -match '^\.\.' -or $relative -ne [IO.Path]::GetFileName($directory) -or [IO.Path]::GetFileName($directory) -notlike 'mnf-png-adam7-compatibility-*') {
    throw "Refusing unsafe PNG Adam7 cleanup: $directory"
  }
  if (Test-Path -LiteralPath $directory) {
    Remove-Item -LiteralPath $directory -Recurse -Force -ErrorAction Stop
  }
}

Push-Location $repositoryRoot
try {
  foreach ($target in $targets) {
    $owned = New-OwnedTargetDirectory $target
    try {
      foreach ($selector in $selectors) {
        & moon -C modules/mb-image test png --target $target --target-dir $owned.Directory --frozen -f $selector | Out-Host
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
      }
      Write-Output "PNG Adam7 compatibility target=$target result=passed"
    } finally {
      Remove-OwnedTargetDirectory $owned
    }
  }
} finally {
  Pop-Location
}
