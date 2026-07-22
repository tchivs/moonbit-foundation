[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('CandidateSelection', 'FinalEvidence')]
  [string]$Mode
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$targets = @('js', 'wasm', 'wasm-gc', 'native')
$candidateSelectors = @(
  [pscustomobject]@{ Id = 'R1'; Selector = 'PNG adaptive filter evidence candidate RGB8 R1 strict win' },
  [pscustomobject]@{ Id = 'R2'; Selector = 'PNG adaptive filter evidence candidate RGB8 R2 strict win' },
  [pscustomobject]@{ Id = 'R3'; Selector = 'PNG adaptive filter evidence candidate RGB8 R3 strict win' },
  [pscustomobject]@{ Id = 'A1'; Selector = 'PNG adaptive filter evidence candidate straight-RGBA8 A1 strict win' },
  [pscustomobject]@{ Id = 'A2'; Selector = 'PNG adaptive filter evidence candidate straight-RGBA8 A2 strict win' },
  [pscustomobject]@{ Id = 'A3'; Selector = 'PNG adaptive filter evidence candidate straight-RGBA8 A3 strict win' }
)

function New-OwnedTargetDirectory([string]$Target) {
  $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
  $targetDirectory = Join-Path $tempRoot ('mnf-png-adaptive-evidence-' + [guid]::NewGuid().ToString('N'))
  $resolvedDirectory = [IO.Path]::GetFullPath($targetDirectory)
  $prefix = 'mnf-png-adaptive-evidence-'
  $relative = [IO.Path]::GetRelativePath($tempRoot, $resolvedDirectory)
  if ([IO.Path]::IsPathRooted($relative) -or $relative -match '^\.\.' -or
      $relative -ne [IO.Path]::GetFileName($resolvedDirectory) -or
      [IO.Path]::GetFileName($resolvedDirectory) -notlike "$prefix*") {
    throw "Refusing unsafe PNG evidence target root: $resolvedDirectory"
  }
  New-Item -ItemType Directory -Path $resolvedDirectory -ErrorAction Stop | Out-Null
  return [pscustomobject]@{ TempRoot = $tempRoot; Directory = $resolvedDirectory; Target = $Target }
}

function Remove-OwnedTargetDirectory($Owned) {
  $resolvedDirectory = [IO.Path]::GetFullPath($Owned.Directory)
  $relative = [IO.Path]::GetRelativePath($Owned.TempRoot, $resolvedDirectory)
  if ([IO.Path]::IsPathRooted($relative) -or $relative -match '^\.\.' -or
      $relative -ne [IO.Path]::GetFileName($resolvedDirectory) -or
      [IO.Path]::GetFileName($resolvedDirectory) -notlike 'mnf-png-adaptive-evidence-*') {
    throw "Refusing unsafe PNG evidence cleanup: $resolvedDirectory"
  }
  if (Test-Path -LiteralPath $resolvedDirectory) {
    Remove-Item -LiteralPath $resolvedDirectory -Recurse -Force -ErrorAction Stop
  }
}

function Invoke-PngSelector([string]$Target, [string]$TargetDirectory, [string]$Selector) {
  & moon -C modules/mb-image test png --target $Target --target-dir $TargetDirectory --frozen -f $Selector | Out-Host
  return $LASTEXITCODE
}

function Select-AllTargetWinner([string[]]$Ids, [hashtable]$Matrix, [string[]]$Targets) {
  foreach ($Id in $Ids) {
    $passed = $true
    foreach ($Target in $Targets) {
      if (-not $Matrix["$Target/$Id"]) {
        $passed = $false
        break
      }
    }
    if ($passed) { return $Id }
  }
  return $null
}

Push-Location $repositoryRoot
try {
  if ($Mode -eq 'CandidateSelection') {
    $matrix = @{}
    foreach ($Target in $targets) {
      $owned = New-OwnedTargetDirectory $Target
      try {
        foreach ($candidate in $candidateSelectors) {
          $matrix["$Target/$($candidate.Id)"] = (Invoke-PngSelector $Target $owned.Directory $candidate.Selector) -eq 0
        }
      } finally {
        Remove-OwnedTargetDirectory $owned
      }
    }
    foreach ($Target in $targets) {
      $values = $candidateSelectors | ForEach-Object { "$($_.Id)=$($matrix["$Target/$($_.Id)"])" }
      Write-Output "PNG adaptive candidate target=$Target $($values -join ' ')"
    }
    $rgbWinner = Select-AllTargetWinner @('R1', 'R2', 'R3') $matrix $targets
    $rgbaWinner = Select-AllTargetWinner @('A1', 'A2', 'A3') $matrix $targets
    Write-Output "PNG adaptive candidate selection rgb=$rgbWinner rgba=$rgbaWinner"
    if (-not $rgbWinner -or -not $rgbaWinner) { exit 1 }
    exit 0
  }

  $researchPath = Join-Path $repositoryRoot '.planning\phases\40-portable-adaptive-filter-evidence\40-RESEARCH.md'
  if (-not (Select-String -LiteralPath $researchPath -Pattern '^\*\*A1: RESOLVED' -Quiet)) {
    throw 'FinalEvidence requires a recorded A1: RESOLVED CandidateSelection result.'
  }
  $finalSelectors = @(
    'PNG adaptive filter evidence RGB8 horizontal eager strictly beats None and decodes completely',
    'PNG adaptive filter evidence straight-RGBA8 vertical eager strictly beats None and decodes completely',
    'PNG adaptive filter evidence RGB8 horizontal chunk exactly matches eager and decodes completely',
    'PNG adaptive filter evidence straight-RGBA8 vertical chunk exactly matches eager and decodes completely'
  )
  foreach ($Target in $targets) {
    $owned = New-OwnedTargetDirectory $Target
    try {
      foreach ($selector in $finalSelectors) {
        $result = Invoke-PngSelector $Target $owned.Directory $selector
        if ($result -ne 0) {
          Write-Error "PNG adaptive final evidence target=$Target selector=$selector result=failed exit=$result"
          exit $result
        }
      }
      Write-Output "PNG adaptive final evidence target=$Target result=passed"
    } finally {
      Remove-OwnedTargetDirectory $owned
    }
  }
} finally {
  Pop-Location
}
