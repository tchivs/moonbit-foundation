[CmdletBinding()]
param([switch]$WorkflowOnly)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$generator = Join-Path $PSScriptRoot 'New-PreparedReleaseBundle.ps1'

function Confirm-PreparedRule {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][scriptblock]$Action)
  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure -or -not $failure.StartsWith("$Id`: ", [StringComparison]::Ordinal)) {
    throw "Prepared negative '$Id' passed or failed for the wrong reason: '$failure'."
  }
}

function Write-Utf8NoBom {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Text)
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Force -Path $parent }
  [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Write-JsonFixture {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][object]$Value)
  Write-Utf8NoBom -Path $Path -Text ($Value | ConvertTo-Json -Depth 100 -Compress)
}

function Copy-PreparedTree {
  param([Parameter(Mandatory)][string]$Source, [Parameter(Mandatory)][string]$Destination)
  $null = New-Item -ItemType Directory -Force -Path $Destination
  Get-ChildItem -LiteralPath $Source -Force | Copy-Item -Destination $Destination -Recurse -Force
}

function Assert-WorkflowOnly {
  $workflowPath = Join-Path $repoRoot '.github\workflows\publish-modules.yml'
  $source = Get-Content -LiteralPath $workflowPath -Raw
  if ($source.Contains("'{}' | Set-Content", [StringComparison]::Ordinal) -or
      $source.Contains("'{}'|Set-Content", [StringComparison]::Ordinal)) {
    throw 'PREP20-WORKFLOW-PLACEHOLDER: prepared manifest placeholder remains.'
  }
  foreach ($required in @('New-PreparedReleaseBundle.ps1','-ValidateOnly','actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02','mnf-prepared-')) {
    if (-not $source.Contains($required, [StringComparison]::Ordinal)) { throw "PREP20-WORKFLOW-WIRING: missing '$required'." }
  }
  $prepareStart = $source.IndexOf('  prepare:', [StringComparison]::Ordinal)
  $nextJob = $source.IndexOf('  publisher_dry_run:', [StringComparison]::Ordinal)
  if ($prepareStart -lt 0 -or $nextJob -le $prepareStart) { throw 'PREP20-WORKFLOW-WIRING: prepare and hosted jobs are not distinct.' }
  $prepare = $source.Substring($prepareStart, $nextJob - $prepareStart)
  foreach ($forbidden in @('environment:','secrets.','MOONCAKES_TOKEN','moon publish','workflow_dispatch','git tag','git push','LiveOneStep','Invoke-ReleasePublisher.ps1 -Mode Live')) {
    if ($prepare.IndexOf($forbidden, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw "PREP21-WORKFLOW-REVERSIBLE: prepare contains '$forbidden'." }
  }
  $validate = $prepare.IndexOf('-ValidateOnly', [StringComparison]::Ordinal)
  $upload = $prepare.IndexOf('actions/upload-artifact@', [StringComparison]::Ordinal)
  if ($validate -lt 0 -or $upload -le $validate) { throw 'PREP20-WORKFLOW-WIRING: upload is not after closed validation.' }
  Write-Host 'Prepared workflow selector passed: one validated content-addressed artifact and no irreversible prepare path.'
}

if ($WorkflowOnly) {
  Assert-WorkflowOnly
  return
}

if (-not (Test-Path -LiteralPath $generator -PathType Leaf)) {
  throw 'PREP00-GENERATOR-MISSING: New-PreparedReleaseBundle.ps1 is required.'
}

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('mnf-prepared-bundle-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Force -Path $tempRoot
try {
  $sourceSha = '1' * 40
  $intentSha = '2' * 64
  $attemptZeroSha = 'b9bda5378ea339f4cdd42c417c1cc0cf8caabbd51ab11d453cd45ddae77d9b52'
  $r1Sha = 'cba047dae2e6b4e1bbf0248653ed7848f144971b54a0a4ed30ef42ab97325653'
  $r2Sha = 'aae8bee66e7dbfca7f3f22f1b52071e7888ae3ec8feee513d1c5d8eba6111609'
  $r3Sha = 'cf29473b2b07ff9aa8fd8a4810ddc45f6aacd2fd4b74048f5d29b3b6fa939d41'
  $r4Sha = 'd9b045bc65df87dc2701144ea7716defc67acb84ec9ea8e7ffdafd0118ba0906'
  $r5Sha = '1239b63f983bef86ac44c731171093ad67759de9cce7c15610b92f5df6214843'
  $r6Sha = '3f9c0d9916dbccfa9144488d2967ee1a7fb3fd1d9936f8cc4139c2734f2d0ad4'
  $r7Sha = 'baf5d4921c75b2ba4a64cd234663a1b7086d6c45a653edd1ce4a63f56882933f'
  $historySetSha = '48de74c184100e34651e9e050e6949b252414746d13f78e04855fd28b69c8580'
  $inputRoot = Join-Path $tempRoot 'input'
  $toolchain = [ordered]@{
    moon = '0.1.20260713 (75c7e1f 2026-07-13)'
    moonc = 'v0.10.4+2cc641edf (2026-07-15)'
    moonrun = '0.1.20260713 (75c7e1f 2026-07-13)'
  }
  $intent = [ordered]@{
    schema_version='mnf-release-intent/1'; intent_kind='initial'; repository='tchivs/moonbit-foundation'; owner='tchivs'
    release_ref='refs/tags/modules-v0.1.0-r8'; source_sha=$sourceSha; correction_sequence=0; toolchain=$toolchain
    modules=@(); evidence=[ordered]@{}; tracked_source_clean=$true; credentials_read=$false; publication_performed=$false
  }
  Write-JsonFixture -Path (Join-Path $inputRoot 'intent\current.json') -Value $intent
  $intentSha = (Get-FileHash -LiteralPath (Join-Path $inputRoot 'intent\current.json') -Algorithm SHA256).Hash.ToLowerInvariant()
  Write-Utf8NoBom -Path (Join-Path $inputRoot 'intent\current.sha256') -Text $intentSha
  Write-JsonFixture -Path (Join-Path $inputRoot 'intent\root-binding.json') -Value ([ordered]@{
    root_intent_sha256=$intentSha; intent_sha256=$intentSha; source_sha=$sourceSha; release_ref='refs/tags/modules-v0.1.0-r8'
  })
  Write-JsonFixture -Path (Join-Path $inputRoot 'request.json') -Value ([ordered]@{
    repository='tchivs/moonbit-foundation'; actor='tchivs'; release_ref='refs/tags/modules-v0.1.0-r8'; source_sha=$sourceSha
    root_intent_sha256=$intentSha; intent_sha256=$intentSha; intent_kind='initial'; correction_sequence=0
    predecessor_intent_sha256=$null; authorization_valid=$true; evidence_valid=$true; dry_run_passed=$true; authority_account='tchivs'
    historical_attempt_zero_sha256=$attemptZeroSha; historical_r1_sha256=$r1Sha; historical_r2_sha256=$r2Sha; historical_r3_sha256=$r3Sha; historical_r4_sha256=$r4Sha; historical_r5_sha256=$r5Sha; historical_r6_sha256=$r6Sha; historical_r7_sha256=$r7Sha
    historical_history_set_sha256=$historySetSha
  })
  foreach ($module in @('mb-core','mb-color','mb-image')) {
    Write-Utf8NoBom -Path (Join-Path $inputRoot "archives\$module.zip") -Text "deterministic-$module-archive"
  }
  $fixtureFiles = [ordered]@{
    'scripts/quality/New-PreparedReleaseBundle.ps1' = 'prepared validator'
    'scripts/quality/Invoke-ReleasePublisher.ps1' = 'publisher controller'
    'scripts/quality/Invoke-MooncakesLiveMutation.ps1' = 'structural adapter markers: MOONCAKES_TOKEN credentials.json'
    'scripts/quality/ReleasePublisher.Common.ps1' = 'publisher common'
    'policy/release-qualification.json' = '{"schema_version":"1.0.0"}'
    'schemas/prepared.json' = '{"title":"prepared"}'
    'schemas/intent.json' = '{"title":"intent"}'
    'schemas/journal-record.json' = '{"title":"journal"}'
    'qualification/phase-07-requirements.json' = '{"schema_version":"mnf-phase-07-requirements/1"}'
    'compatibility/interface-digests.json' = '{"schema_version":"mnf-interface-digests/1"}'
    'registry/authority-observation.json' = '{"schema_version":"1.0.0","status":"unknown"}'
  }
  foreach ($entry in $fixtureFiles.GetEnumerator()) { Write-Utf8NoBom -Path (Join-Path $inputRoot $entry.Key) -Text $entry.Value }

  $common = @{
    InputRoot=$inputRoot; Repository='tchivs/moonbit-foundation'; Actor='tchivs'; RunId='1001'; RunAttempt=1
    ReleaseRef='refs/tags/modules-v0.1.0-r8'; SourceSha=$sourceSha; RootIntentSha256=$intentSha; IntentSha256=$intentSha
    HistoricalAttemptZeroSha256=$attemptZeroSha; HistoricalR1Sha256=$r1Sha; HistoricalR2Sha256=$r2Sha; HistoricalR3Sha256=$r3Sha; HistoricalR4Sha256=$r4Sha; HistoricalR5Sha256=$r5Sha; HistoricalR6Sha256=$r6Sha; HistoricalR7Sha256=$r7Sha; HistoricalHistorySetSha256=$historySetSha
    RunMode='start'
  }
  $validation = @{} + $common
  $validation.Remove('InputRoot')
  $outA = Join-Path $tempRoot 'out-a'
  $outB = Join-Path $tempRoot 'out-b'
  $a = & $generator @common -OutputRoot $outA
  $b = & $generator @common -OutputRoot $outB
  $aBytes = [IO.File]::ReadAllBytes($a.manifest_path)
  $bBytes = [IO.File]::ReadAllBytes($b.manifest_path)
  if (-not [Linq.Enumerable]::SequenceEqual([byte[]]$aBytes,[byte[]]$bBytes) -or $a.manifest_sha256 -cne $b.manifest_sha256) {
    throw 'PREP01-DETERMINISM: clean generations differ.'
  }
  $manifestA = Get-Content -LiteralPath $a.manifest_path -Raw | ConvertFrom-Json -Depth 100
  $manifestB = Get-Content -LiteralPath $b.manifest_path -Raw | ConvertFrom-Json -Depth 100
  if (@($manifestA.payloads).Count -ne 18 -or (@($manifestA.payloads.sha256) -join ',') -cne (@($manifestB.payloads.sha256) -join ',')) {
    throw 'PREP01-DETERMINISM: payload inventory or digests differ.'
  }
  & $generator -ValidateOnly -OutputRoot $outA @validation | Out-Null

  function Invoke-MutatedCase {
    param([string]$Name,[string]$Rule,[scriptblock]$Mutate)
    $caseRoot = Join-Path $tempRoot $Name
    Copy-PreparedTree -Source $outA -Destination $caseRoot
    & $Mutate $caseRoot
    Confirm-PreparedRule $Rule { & $generator -ValidateOnly -OutputRoot $caseRoot @validation | Out-Null }
  }

  Invoke-MutatedCase 'missing' 'PREP04-MISSING-PAYLOAD' { param($r) Remove-Item -LiteralPath (Join-Path $r 'archives\mb-core.zip') -Force }
  Invoke-MutatedCase 'empty' 'PREP05-EMPTY-PAYLOAD' { param($r) [IO.File]::WriteAllBytes((Join-Path $r 'archives\mb-core.zip'),[byte[]]@()) }
  Invoke-MutatedCase 'extra' 'PREP06-EXTRA-PAYLOAD' { param($r) Write-Utf8NoBom -Path (Join-Path $r 'unexpected.txt') -Text 'extra' }
  Invoke-MutatedCase 'digest' 'PREP07-PAYLOAD-DIGEST' {
    param($r) $p=Join-Path $r 'archives\mb-core.zip'; $bytes=[IO.File]::ReadAllBytes($p); $bytes[0]=$bytes[0] -bxor 1; [IO.File]::WriteAllBytes($p,$bytes)
  }
  Invoke-MutatedCase 'size' 'PREP08-PAYLOAD-SIZE' {
    param($r) $p=Join-Path $r 'prepared-bundle.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $m.payloads[0].size++; Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'traversal' 'PREP02-PAYLOAD-PATH' {
    param($r) $p=Join-Path $r 'prepared-bundle.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $m.payloads[0].path='../escape'; Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'unrecognized' 'PREP03-INVENTORY' {
    param($r) $p=Join-Path $r 'prepared-bundle.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $m.payloads[0].path='archives/other.zip'; Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'reordered' 'PREP03-INVENTORY' {
    param($r) $p=Join-Path $r 'prepared-bundle.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $first=$m.payloads[0]; $m.payloads[0]=$m.payloads[1]; $m.payloads[1]=$first; Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'binding' 'PREP09-BINDING' {
    param($r) $p=Join-Path $r 'prepared-bundle.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $m.source_sha='f'*40; Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'journal' 'PREP10-JOURNAL-BINDING' {
    param($r) $p=Join-Path $r 'request.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $m.intent_sha256='f'*64; Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'old-root' 'PREP10-JOURNAL-BINDING' {
    param($r) $p=Join-Path $r 'request.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $m.root_intent_sha256='e'*64; Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'correction-lane' 'PREP10-JOURNAL-BINDING' {
    param($r) $p=Join-Path $r 'request.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $m.intent_kind='forward_correction';$m.correction_sequence=1;$m.predecessor_intent_sha256='e'*64; Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'history-substitution' 'PREP14-HISTORICAL-BINDING' {
    param($r) $p=Join-Path $r 'request.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $m.historical_r1_sha256='c'*64; Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'history-missing-r7' 'PREP10-JOURNAL-BINDING' {
    param($r) $p=Join-Path $r 'request.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $m.PSObject.Properties.Remove('historical_r7_sha256'); Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'history-order-mix' 'PREP14-HISTORICAL-BINDING' {
    param($r) $p=Join-Path $r 'request.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $t=$m.historical_r6_sha256;$m.historical_r6_sha256=$m.historical_r7_sha256;$m.historical_r7_sha256=$t; Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'history-aggregate' 'PREP14-HISTORICAL-BINDING' {
    param($r) $p=Join-Path $r 'request.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $m.historical_history_set_sha256='f'*64; Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'reused-state' 'PREP10-JOURNAL-BINDING' {
    param($r) $p=Join-Path $r 'request.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $m|Add-Member -NotePropertyName locator_path -NotePropertyValue 'old.json'; Write-JsonFixture -Path $p -Value $m
  }
  $legacy=@{}+$common;$legacy.ReleaseRef='refs/tags/modules-v0.1.0-r7'
  Confirm-PreparedRule 'PREP09-BINDING' { & $generator @legacy -OutputRoot (Join-Path $tempRoot 'legacy-r7') | Out-Null }
  Invoke-MutatedCase 'toolchain' 'PREP11-TOOLCHAIN' {
    param($r) $p=Join-Path $r 'prepared-bundle.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $m.toolchain.moon='latest'; Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'self-reference' 'PREP12-SELF-REFERENCE' {
    param($r) $p=Join-Path $r 'prepared-bundle.json'; $m=Get-Content $p -Raw|ConvertFrom-Json -Depth 100; $m.payloads[0].path='prepared-bundle.json'; Write-JsonFixture -Path $p -Value $m
  }
  Invoke-MutatedCase 'secret' 'PREP13-SECRET-MATERIAL' { param($r) Add-Content -LiteralPath (Join-Path $r 'request.json') -Value 'MOONCAKES_TOKEN' -NoNewline }

  Write-Host 'Prepared bundle selector passed: deterministic closed inventory and adversarial fail-closed matrix.'
} finally {
  if (Test-Path -LiteralPath $tempRoot) {
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
    $full = [IO.Path]::GetFullPath($tempRoot)
    if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or
        -not (Split-Path -Leaf $full).StartsWith('mnf-prepared-bundle-',[StringComparison]::Ordinal)) {
      throw "Refusing to remove unverified prepared test path: $full"
    }
    Remove-Item -LiteralPath $full -Recurse -Force
  }
}
