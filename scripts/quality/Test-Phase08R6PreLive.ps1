[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$selector=Join-Path $PSScriptRoot 'Invoke-Phase08R6PreLive.ps1'
if(-not(Test-Path -LiteralPath $selector -PathType Leaf)){throw 'P08-R6-PRELIVE-MISSING: selector is required.'}
. $selector -Check -Repository tchivs/moonbit-foundation -Remote origin -LibraryOnly
if(-not(Get-Command Assert-Phase08R6PreLive -ErrorAction SilentlyContinue)){throw 'P08-R6-PRELIVE-API: validator function is missing.'}

Write-Host 'Phase 8 r6 pre-live selector fixtures: PASS.'
