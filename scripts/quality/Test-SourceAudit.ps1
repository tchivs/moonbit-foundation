[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Assert-Policy.ps1')

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$canonicalPath = Join-Path $repoRoot 'policy/phase-01-source-audit.json'
$canonical = Get-Content -LiteralPath $canonicalPath -Raw | ConvertFrom-Json -Depth 100 -DateKind String

function Copy-Audit([object]$Value) {
  return $Value | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100 -DateKind String
}

function Invoke-AuditCase([string]$Name, [scriptblock]$Mutate, [string]$ExpectedFailurePattern) {
  $audit = Copy-Audit $canonical
  if ($Mutate) { & $Mutate $audit }
  $path = Join-Path ([System.IO.Path]::GetTempPath()) ('mnf-audit-' + [guid]::NewGuid().ToString('N') + '.json')
  try {
    $audit | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $path -Encoding utf8
    $failure = $null
    try { Assert-PhaseSourceAudit -AuditPath $path -RepositoryRoot $repoRoot }
    catch { $failure = $_.Exception.Message }
    if ([string]::IsNullOrWhiteSpace($ExpectedFailurePattern)) {
      if ($null -ne $failure) { throw "Source-audit case '$Name' expected success but failed: $failure" }
    } elseif ($null -eq $failure -or $failure -cnotmatch $ExpectedFailurePattern) {
      throw "Source-audit case '$Name' expected failure '$ExpectedFailurePattern'; got '$failure'."
    }
    Write-Host "PASS: $Name"
  } finally {
    Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
  }
}

$lfIds = @(Get-PhaseSourceAuditMarkerIds -PlanText "header`n<!-- phase-source-audit: A,B -->`nfooter`n" -Plan 'lf-fixture')
$crlfIds = @(Get-PhaseSourceAuditMarkerIds -PlanText "header`r`n<!-- phase-source-audit: A,B -->  `r`nfooter`r`n" -Plan 'crlf-fixture')
Assert-ExactSet 'LF source-audit marker fixture' $lfIds @('A','B')
Assert-ExactSet 'CRLF source-audit marker fixture' $crlfIds @('A','B')
Write-Host 'PASS: LF and CRLF source-audit markers'

Invoke-AuditCase 'canonical source audit' $null $null
Invoke-AuditCase 'missing source anchor' { param($a) $a.goals[0].source='.planning/ROADMAP.md#missing-anchor' } 'anchor.*does not exist'
Invoke-AuditCase 'unknown covering plan' { param($a) $a.goals[0].covering_plan='99-99' } 'unknown Phase 01 plan'
Invoke-AuditCase 'duplicate covering plan id' { param($a) $a.goals[0].covering_plan='01-08,01-08' } 'duplicate covering plan IDs'
Invoke-AuditCase 'known id mapped to wrong plan' { param($a) $a.goals[0].covering_plan='01-01' } 'reciprocal source-audit IDs.*mismatch'

Write-Host 'Phase 1 source-audit provenance and reciprocal coverage matrix passed.'
