[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$repoRoot=(Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$hosted=Join-Path $PSScriptRoot 'Invoke-Phase08HostedRun.ps1'
if(-not(Test-Path -LiteralPath $hosted -PathType Leaf)){throw 'P08-PREPARE-HISTORY-SCHEMA-MISSING: hosted runner is required.'}

$control=Get-Content -LiteralPath (Join-Path $repoRoot 'policy/release-control.json') -Raw|ConvertFrom-Json -Depth 100
$r12=@($control.initial_attempt_family.terminal_negative_history)[12]
if($r12.attempt -cne 'r12' -or $r12.reason -cne 'terminal_tag_before_script_ref_agreement_failure' -or
    $r12.tag_object_sha -cne '57b76c9f9044d3190acc1e4c3fb7ada516f4dece' -or $r12.tag_peeled_source_sha -cne '5e7b19cdc74ec11d5c524ff34a36c266b15bba39' -or
    $r12.failure_code -cne 'REL01-REF' -or $r12.PSObject.Properties.Name -ccontains 'active_attempt_path'){
  throw 'P08-PREPARE-HISTORY-SCHEMA-R12: expected immutable r12 REL01-REF terminal shape.'
}

. $hosted -Mode PrepareAttempt -LibraryOnly
$BoundaryLocatorPath='strict-mode-history-schema-probe'
$ReleaseRef='refs/tags/modules-v0.1.0-r13'
$HistoricalReleaseRef='refs/tags/modules-v0.1.0-r12'
$HistoricalSourceSha='5e7b19cdc74ec11d5c524ff34a36c266b15bba39'
$script:GitCommand={param($Root,[string[]]$Arguments);throw 'P08-PREPARE-HISTORY-SCHEMA-GIT: exact r12 history was accepted before any git read.'}
$probeState=Join-Path ([IO.Path]::GetTempPath()) ('mnf-p08-history-schema-'+[Guid]::NewGuid().ToString('N'))
$boundary=[pscustomobject]@{execution_root=$repoRoot;state_root=$probeState;boundary_sha=('a'*40)}
$failure=$null
try{New-P08PreparedAttempt -Boundary $boundary}catch{$failure=$_.Exception.Message}
if($failure -notmatch '^P08-PREPARE-HISTORY-SCHEMA-GIT:'){
  throw "P08-PREPARE-HISTORY-SCHEMA: expected the pre-git sentinel after accepting exact r12 terminal history, got '$failure'."
}
if(Test-Path -LiteralPath (Join-Path $probeState 'phase-08-live-locator.json')){
  throw 'P08-PREPARE-HISTORY-SCHEMA: active locator was written before the controlled git sentinel.'
}

function Confirm-P08PrepareHistoryBindingFailure([object]$Policy,[string]$Label){
  $root=Join-Path ([IO.Path]::GetTempPath()) ('mnf-p08-history-schema-negative-'+[Guid]::NewGuid().ToString('N'))
  try{
    $policyPath=Join-Path $root 'policy/release-control.json'
    $null=New-Item -ItemType Directory -Force -Path (Split-Path -Parent $policyPath)
    [IO.File]::WriteAllText($policyPath,($Policy|ConvertTo-Json -Depth 100 -Compress),[Text.UTF8Encoding]::new($false))
    $failure=$null
    try{New-P08PreparedAttempt -Boundary ([pscustomobject]@{execution_root=$root;state_root=(Join-Path $root 'state');boundary_sha=('a'*40)})}catch{$failure=$_.Exception.Message}
    if($failure -notmatch '^P08-PREPARE-HISTORICAL-BINDING:'){
      throw "P08-PREPARE-HISTORY-SCHEMA-${Label}: expected fail-closed historical binding rejection, got '$failure'."
    }
  }finally{if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}}
}

$unexpectedField=$control|ConvertTo-Json -Depth 100|ConvertFrom-Json -Depth 100
$unexpectedField.initial_attempt_family.terminal_negative_history[12] | Add-Member -NotePropertyName active_attempt_path -NotePropertyValue 'unexpected'
Confirm-P08PrepareHistoryBindingFailure -Policy $unexpectedField -Label 'FIELD'
$digestDrift=$control|ConvertTo-Json -Depth 100|ConvertFrom-Json -Depth 100
$digestDrift.initial_attempt_family.terminal_negative_history[12].record_sha256=('0'*64)
Confirm-P08PrepareHistoryBindingFailure -Policy $digestDrift -Label 'DIGEST'

$preAuthorizationRoot=Join-Path ([IO.Path]::GetTempPath()) ('mnf-p08-preauthorization-'+[Guid]::NewGuid().ToString('N'))
try{
  $null=New-Item -ItemType Directory -Path $preAuthorizationRoot
  $packet=[pscustomobject][ordered]@{schema_version='mnf-phase08-mutation-authorization-packet/1';release_ref='refs/tags/modules-v0.1.0-r13';packet_sha256=''}
  $packet.packet_sha256=Get-P08SelfExcludingDigest $packet 'packet_sha256'
  $packetPath=Join-Path $preAuthorizationRoot 'packet.json';[IO.File]::WriteAllText($packetPath,($packet|ConvertTo-Json -Compress),[Text.UTF8Encoding]::new($false))
  $projection=[pscustomobject][ordered]@{schema_version='mnf-phase08-pre-authorization/1';release_ref='refs/tags/modules-v0.1.0-r13';active_attempt_path=$null;authority_variant='confirmed_absent';exact_existing_authority_path=$null;exact_existing_authority_sha256=$null;mutation_authorization_packet_path=$packetPath;mutation_authorization_packet_sha256=(Get-P08Sha256 $packetPath);authorization_receipt_path=$null;authorization_receipt_sha256=$null;fixed_handoff_path=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08-r13-handoff.json'));fixed_handoff_sha256=$null;observation_path=$null;observation_sha256=$null;mutation_count=0;output_write_count=0}
  $projectionPath=Join-Path $preAuthorizationRoot 'projection.json';[IO.File]::WriteAllText($projectionPath,($projection|ConvertTo-Json -Compress),[Text.UTF8Encoding]::new($false))
  & $hosted -Mode ValidatePreAuthorization -PreAuthorizationPath $projectionPath|Out-Null
  $mixed=$projection.PSObject.Copy();$mixed.authorization_receipt_path=$packetPath;$mixed.authorization_receipt_sha256=(Get-P08Sha256 $packetPath);$mixedPath=Join-Path $preAuthorizationRoot 'mixed.json';[IO.File]::WriteAllText($mixedPath,($mixed|ConvertTo-Json -Compress),[Text.UTF8Encoding]::new($false))
  $failure=$null;try{& $hosted -Mode ValidatePreAuthorization -PreAuthorizationPath $mixedPath|Out-Null}catch{$failure=$_.Exception.Message}
  if($failure -notmatch '^P08-PREAUTH-ZERO-MUTATION:'){throw "P08-PREAUTH-RECEIPT: mixed pre-authorization was not rejected, got '$failure'."}
}finally{if(Test-Path -LiteralPath $preAuthorizationRoot){Remove-Item -LiteralPath $preAuthorizationRoot -Recurse -Force}}

Write-Host 'Phase 8 PrepareAttempt r11 terminal history schema: PASS.'
