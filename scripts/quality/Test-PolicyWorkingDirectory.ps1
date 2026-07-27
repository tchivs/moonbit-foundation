[CmdletBinding()]
param()

Set-StrictMode -Version Latest

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$policyPath = Join-Path $repositoryRoot 'policy/foundation.json'
$foreignDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("mnf-policy-cwd-" + [Guid]::NewGuid().ToString())

. (Join-Path $PSScriptRoot 'Assert-Policy.ps1')

New-Item -ItemType Directory -Path $foreignDirectory -ErrorAction Stop | Out-Null
try {
  Push-Location -LiteralPath $foreignDirectory
  try {
    Assert-QoiFoundationPolicy -PolicyPath $policyPath
    Assert-FontFoundationPolicy -PolicyPath $policyPath
    Assert-PngFoundationPolicy -PolicyPath $policyPath
  } finally {
    Pop-Location
  }
} finally {
  if (Test-Path -LiteralPath $foreignDirectory -PathType Container) {
    Remove-Item -LiteralPath $foreignDirectory -Recurse -Force
  }
}

Write-Host 'Policy selectors are independent of the caller working directory.'
