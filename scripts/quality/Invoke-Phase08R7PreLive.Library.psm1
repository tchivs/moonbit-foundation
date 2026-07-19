Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

. (Join-Path $PSScriptRoot 'Invoke-Phase08R7PreLive.ps1') -Check -Repository tchivs/moonbit-foundation -Remote origin -LibraryOnly

Export-ModuleMember -Function New-Phase08R7ProductionContext
