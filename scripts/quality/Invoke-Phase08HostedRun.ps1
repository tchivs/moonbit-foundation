[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet('PublisherDryRun','HostedPreflight','PublishOne')][string]$Mode,
  [Parameter(Mandatory)][string]$Repository,
  [Parameter(Mandatory)][string]$Workflow,
  [Parameter(Mandatory)][string]$ReleaseRef,
  [Parameter(Mandatory)][string]$SourceSha,
  [Parameter(Mandatory)][string]$RootIntentSha256,
  [Parameter(Mandatory)][string]$IntentSha256,
  [Parameter(Mandatory)][string]$PreparedManifestSha256,
  [Parameter(Mandatory)][ValidateSet('mb-core','mb-color','mb-image')][string]$TargetModule,
  [Parameter(Mandatory)][string]$LocatorPath,
  [Parameter(Mandatory)][string]$ArtifactRoot,
  [string]$AuthorizationPacketPath,
  [string]$PriorRunId='',
  [string]$PriorArtifactName='',
  [switch]$LibraryOnly,
  [scriptblock]$GhCommand
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Throw-P08HostedRule([string]$Id,[string]$Message) { throw "$Id`: $Message" }

function Get-P08Sha256([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Throw-P08HostedRule 'P08-HOSTED-FILE' "Missing file '$Path'." }
  (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-P08CanonicalJson([object]$Value) {
  ($Value | ConvertTo-Json -Depth 100 -Compress)
}

function Get-P08ObjectDigest([object]$Value) {
  $bytes=[Text.UTF8Encoding]::new($false).GetBytes((Get-P08CanonicalJson $Value))
  ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes))).ToLowerInvariant()
}

function Test-P08SafePath([string]$Path,[string]$Root,[switch]$AllowRoot) {
  $full=[IO.Path]::GetFullPath($Path); $rootFull=[IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
  if (($AllowRoot -and $full -ceq $rootFull) -or $full.StartsWith($rootFull + [IO.Path]::DirectorySeparatorChar,[StringComparison]::Ordinal)) { return $full }
  Throw-P08HostedRule 'P08-STORE-ESCAPE' "Path '$full' escapes '$rootFull'."
}

function Write-P08ExclusiveJson([string]$Path,[object]$Value) {
  if (Test-Path -LiteralPath $Path) { Throw-P08HostedRule 'P08-STORE-COLLISION' "Immutable path '$Path' already exists." }
  $parent=Split-Path -Parent $Path; $null=New-Item -ItemType Directory -Force $parent
  $temp=Join-Path $parent ('.' + [IO.Path]::GetFileName($Path) + '.' + [Guid]::NewGuid().ToString('N') + '.tmp')
  try {
    [IO.File]::WriteAllText($temp,(Get-P08CanonicalJson $Value),[Text.UTF8Encoding]::new($false))
    [IO.File]::Move($temp,$Path,$false)
  } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
}

function Write-P08ReplaceJson([string]$Path,[object]$Value) {
  $parent=Split-Path -Parent $Path; $null=New-Item -ItemType Directory -Force $parent
  $temp=Join-Path $parent ('.' + [IO.Path]::GetFileName($Path) + '.' + [Guid]::NewGuid().ToString('N') + '.tmp')
  try {
    [IO.File]::WriteAllText($temp,(Get-P08CanonicalJson $Value),[Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temp -Destination $Path -Force
  } finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
}

function Get-P08ExpectedStore([string]$RootIntent) {
  $base=[IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) 'mnf-phase08'))
  [pscustomobject][ordered]@{
    locator=[IO.Path]::GetFullPath((Join-Path $base 'phase-08-live-locator.json'))
    root=[IO.Path]::GetFullPath((Join-Path $base "artifacts/$RootIntent"))
    index=[IO.Path]::GetFullPath((Join-Path $base "artifacts/$RootIntent/index.json"))
  }
}

function Get-P08LocatorProjection([object]$Locator) {
  [pscustomobject][ordered]@{
    schema_version=[string]$Locator.schema_version; artifact_root=[string]$Locator.artifact_root; index_path=[string]$Locator.index_path
    repository=[string]$Locator.repository; workflow=[string]$Locator.workflow; release_ref=[string]$Locator.release_ref
    source_sha=[string]$Locator.source_sha; root_intent_sha256=[string]$Locator.root_intent_sha256; intent_sha256=[string]$Locator.intent_sha256
    authorization_packet_path=$Locator.authorization_packet_path; authorization_packet_sha256=$Locator.authorization_packet_sha256
    created_at_utc=[string]$Locator.created_at_utc
  }
}

function Assert-P08NoLinks([string]$Root) {
  $rootItem=Get-Item -LiteralPath $Root -Force
  if (($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Throw-P08HostedRule 'P08-STORE-LINK' 'Artifact root is a link.' }
  foreach($item in @(Get-ChildItem -LiteralPath $Root -Recurse -Force)) {
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Throw-P08HostedRule 'P08-STORE-LINK' "Linked evidence path '$($item.FullName)' is forbidden." }
  }
}

function Open-P08ArtifactStore {
  param([string]$Locator,[string]$Root,[string]$Repo,[string]$WorkflowPath,[string]$Ref,[string]$Sha,[string]$RootIntent,[string]$CurrentIntent)
  $expected=Get-P08ExpectedStore $RootIntent
  $locatorFull=[IO.Path]::GetFullPath($Locator); $rootFull=[IO.Path]::GetFullPath($Root)
  if ($locatorFull -cne $expected.locator -or $rootFull -cne $expected.root) { Throw-P08HostedRule 'P08-STORE-PATH' 'Explicit locator/root do not equal deterministic paths.' }
  if ($Repo -cne 'tchivs/moonbit-foundation' -or $WorkflowPath -cne 'publish-modules.yml' -or $Ref -cne 'refs/tags/modules-v0.1.0' -or $Sha -notmatch '^[0-9a-f]{40}$' -or $RootIntent -notmatch '^[0-9a-f]{64}$' -or $CurrentIntent -notmatch '^[0-9a-f]{64}$') { Throw-P08HostedRule 'P08-STORE-BINDING' 'Repository/workflow/tag/SHA/intent binding is invalid.' }
  if (-not (Test-Path -LiteralPath $locatorFull)) {
    foreach($directory in @($rootFull,(Join-Path $rootFull 'runs'),(Join-Path $rootFull 'observations'),(Join-Path $rootFull 'authorization'))) {
      if (Test-Path -LiteralPath $directory) { Throw-P08HostedRule 'P08-STORE-PARTIAL' 'Store exists without its locator.' }
      $null=New-Item -ItemType Directory -Path $directory
    }
    $index=[pscustomobject][ordered]@{ schema_version='mnf-phase08-live-index/1'; root_intent_sha256=$RootIntent; records=@() }
    Write-P08ExclusiveJson $expected.index $index
    $locatorValue=[pscustomobject][ordered]@{
      schema_version='mnf-phase08-live-locator/1'; artifact_root=$rootFull; index_path=$expected.index; repository=$Repo; workflow=$WorkflowPath
      release_ref=$Ref; source_sha=$Sha; root_intent_sha256=$RootIntent; intent_sha256=$CurrentIntent
      authorization_packet_path=$null; authorization_packet_sha256=$null; created_at_utc=[DateTime]::UtcNow.ToString('o'); locator_sha256=''
    }
    $locatorValue.locator_sha256=Get-P08ObjectDigest (Get-P08LocatorProjection $locatorValue)
    Write-P08ExclusiveJson $locatorFull $locatorValue
  }
  $locatorValue=Get-Content -LiteralPath $locatorFull -Raw | ConvertFrom-Json -Depth 100
  $expectedNames=@('schema_version','artifact_root','index_path','repository','workflow','release_ref','source_sha','root_intent_sha256','intent_sha256','authorization_packet_path','authorization_packet_sha256','created_at_utc','locator_sha256')
  if ((@($locatorValue.PSObject.Properties.Name) -join ',') -cne ($expectedNames -join ',')) { Throw-P08HostedRule 'P08-STORE-LOCATOR-CLOSED' 'Locator fields drifted.' }
  if ($locatorValue.schema_version -cne 'mnf-phase08-live-locator/1' -or [IO.Path]::GetFullPath([string]$locatorValue.artifact_root) -cne $rootFull -or [IO.Path]::GetFullPath([string]$locatorValue.index_path) -cne $expected.index -or $locatorValue.repository -cne $Repo -or $locatorValue.workflow -cne $WorkflowPath -or $locatorValue.release_ref -cne $Ref -or $locatorValue.source_sha -cne $Sha -or $locatorValue.root_intent_sha256 -cne $RootIntent -or $locatorValue.intent_sha256 -cne $CurrentIntent) { Throw-P08HostedRule 'P08-STORE-LOCATOR-BINDING' 'Locator binding drifted.' }
  if ($locatorValue.locator_sha256 -cne (Get-P08ObjectDigest (Get-P08LocatorProjection $locatorValue))) { Throw-P08HostedRule 'P08-STORE-LOCATOR-DIGEST' 'Locator digest drifted.' }
  Assert-P08NoLinks $rootFull
  $index=Get-Content -LiteralPath $expected.index -Raw | ConvertFrom-Json -Depth 100
  if ((@($index.PSObject.Properties.Name) -join ',') -cne 'schema_version,root_intent_sha256,records' -or $index.schema_version -cne 'mnf-phase08-live-index/1' -or $index.root_intent_sha256 -cne $RootIntent) { Throw-P08HostedRule 'P08-STORE-INDEX' 'Index binding drifted.' }
  $seen=@{}; $logicalSeen=@{}; foreach($record in @($index.records)) {
    if ((@($record.PSObject.Properties.Name) -join ',') -cne 'logical_key,kind,run_id,run_attempt,artifact_name,path,sha256') { Throw-P08HostedRule 'P08-STORE-RECORD-CLOSED' 'Index record fields drifted.' }
    $relative=[string]$record.path; if ($seen.ContainsKey($relative)) { Throw-P08HostedRule 'P08-STORE-DUPLICATE' "Duplicate indexed path '$relative'." }; $seen[$relative]=$true
    $logical=[string]$record.logical_key; if ([string]::IsNullOrWhiteSpace($logical) -or $logicalSeen.ContainsKey($logical)) { Throw-P08HostedRule 'P08-STORE-DUPLICATE' "Duplicate indexed logical evidence '$logical'." }; $logicalSeen[$logical]=$true
    $absolute=Test-P08SafePath (Join-Path $rootFull $relative) $rootFull
    if ((Get-P08Sha256 $absolute) -cne [string]$record.sha256) { Throw-P08HostedRule 'P08-STORE-INDEX-DIGEST' "Indexed digest drifted for '$relative'." }
  }
  $actual=@(Get-ChildItem -LiteralPath $rootFull -Recurse -File | Where-Object FullName -cne $expected.index | ForEach-Object { [IO.Path]::GetRelativePath($rootFull,$_.FullName).Replace('\','/') })
  foreach($relative in $actual) { if (-not $seen.ContainsKey($relative)) { Throw-P08HostedRule 'P08-STORE-UNINDEXED' "Unindexed evidence '$relative'." } }
  [pscustomobject]@{ locator=$locatorValue; index=$index; paths=$expected }
}

function Assert-P08NoSecretShape([object]$Value) {
  $json=Get-P08CanonicalJson $Value
  foreach($pattern in @('(?i)gh[opusr]_[A-Za-z0-9_]{12,}','(?i)bearer\s+[A-Za-z0-9._-]+','(?i)MOONCAKES_TOKEN','(?i)credentials[.]json','(?i)authorization\s*:','(?i)token\s*[:=]')) {
    if ($json -match $pattern) { Throw-P08HostedRule 'P08-HOSTED-SECRET-SHAPE' 'Sanitized evidence contains a forbidden secret-shaped value.' }
  }
}

function Assert-P08HostedEvidence {
  param([ValidateSet('PublisherDryRun','HostedPreflight')][string]$Operation,[object]$Evidence,[object]$Run,[object]$Store,[string]$PreparedDigest,[string]$Module)
  Assert-P08NoSecretShape $Evidence
  $common=@('schema_version','mode','repository','workflow','run_id','run_attempt','release_ref','source_sha','root_intent_sha256','intent_sha256','prepared_manifest_sha256','target_module')
  foreach($name in $common) { if ($null -eq $Evidence.PSObject.Properties[$name]) { Throw-P08HostedRule 'P08-HOSTED-EVIDENCE-CLOSED' "Missing evidence field '$name'." } }
  if ([string]$Evidence.mode -cne $Operation -or [string]$Evidence.repository -cne [string]$Store.locator.repository -or
      [string]$Evidence.workflow -cne [string]$Store.locator.workflow -or [string]$Evidence.run_id -cne [string]$Run.databaseId -or
      [int]$Evidence.run_attempt -ne [int]$Run.attempt -or [string]$Evidence.release_ref -cne [string]$Store.locator.release_ref -or
      [string]$Evidence.source_sha -cne [string]$Store.locator.source_sha -or [string]$Evidence.root_intent_sha256 -cne [string]$Store.locator.root_intent_sha256 -or
      [string]$Evidence.intent_sha256 -cne [string]$Store.locator.intent_sha256 -or [string]$Evidence.prepared_manifest_sha256 -cne $PreparedDigest -or
      [string]$Evidence.target_module -cne $Module) { Throw-P08HostedRule 'P08-HOSTED-EVIDENCE-BINDING' 'Sanitized evidence does not bind the exact run and release inputs.' }
  foreach($field in @('started_at_utc','completed_at_utc')) {
    if ($null -eq $Evidence.PSObject.Properties[$field]) { Throw-P08HostedRule 'P08-HOSTED-EVIDENCE-STALE' "Missing '$field'." }
    try { $time=[DateTimeOffset]::Parse([string]$Evidence.$field) } catch { Throw-P08HostedRule 'P08-HOSTED-EVIDENCE-STALE' "Invalid '$field'." }
    if ($time -lt [DateTimeOffset]::UtcNow.AddHours(-6) -or $time -gt [DateTimeOffset]::UtcNow.AddMinutes(5)) { Throw-P08HostedRule 'P08-HOSTED-EVIDENCE-STALE' "Stale '$field'." }
  }
  if ($Operation -ceq 'PublisherDryRun') {
    if ([string]$Evidence.schema_version -cne 'mnf-publisher-dry-run/1' -or [string]$Evidence.command_classification -cne 'moon_publish_frozen_dry_run' -or
        [int]$Evidence.exit_code -ne 0 -or $Evidence.mutation_performed -ne $false -or $Evidence.credential_state_removed -ne $true -or
        $Evidence.raw_output_persisted -ne $false -or [string]$Evidence.module_identity -cne 'tchivs/mb-core@0.1.0' -or
        [string]$Evidence.module_manifest_sha256 -notmatch '^[0-9a-f]{64}$' -or [string]$Evidence.archive_sha256 -notmatch '^[0-9a-f]{64}$') { Throw-P08HostedRule 'P08-HOSTED-DRYRUN-EVIDENCE' 'PublisherDryRun evidence is incomplete or mutation-indicating.' }
  } else {
    if ([string]$Evidence.schema_version -cne 'mnf-hosted-preflight/1' -or $Evidence.native_runtime_verified -ne $true -or $Evidence.compile_only -ne $false -or
        [int]$Evidence.exit_code -ne 0 -or $Evidence.sentinel_match -ne $true -or
        [string]$Evidence.expected_sentinel_sha256 -notmatch '^[0-9a-f]{64}$' -or [string]$Evidence.observed_sentinel_sha256 -cne [string]$Evidence.expected_sentinel_sha256 -or
        [string]::IsNullOrWhiteSpace([string]$Evidence.toolchain_identity) -or [string]::IsNullOrWhiteSpace([string]$Evidence.linker_identity) -or
        [string]::IsNullOrWhiteSpace([string]$Evidence.runtime_identity) -or $Evidence.raw_output_persisted -ne $false) { Throw-P08HostedRule 'P08-HOSTED-PREFLIGHT-EVIDENCE' 'HostedPreflight evidence is incomplete, compile-only, or drifted.' }
  }
}

function Add-P08ArtifactRecord {
  param([object]$Store,[string]$Kind,[string]$RunId,[int]$RunAttempt,[string]$ArtifactName,[string]$SourcePath)
  $safeName=($ArtifactName -replace '[^A-Za-z0-9._-]','_'); $relative="runs/$Kind-$RunId-$RunAttempt-$safeName.json"
  $destination=Test-P08SafePath (Join-Path $Store.paths.root $relative) $Store.paths.root
  $digest=Get-P08Sha256 $SourcePath
  $logical="$Kind|$RunId|$RunAttempt|$ArtifactName"
  $matches=@($Store.index.records | Where-Object { $_.logical_key -ceq $logical })
  if ($matches.Count -gt 1) { Throw-P08HostedRule 'P08-STORE-DUPLICATE' "Ambiguous logical evidence '$logical'." }
  if ($matches.Count -eq 1) {
    if ($matches[0].path -cne $relative -or $matches[0].sha256 -cne $digest -or (Get-P08Sha256 $destination) -cne $digest) { Throw-P08HostedRule 'P08-STORE-RESUME-DRIFT' "Immutable evidence '$logical' changed." }
    return $matches[0]
  }
  $bytes=[IO.File]::ReadAllBytes($SourcePath); $parent=Split-Path -Parent $destination; $null=New-Item -ItemType Directory -Force $parent
  $temp=Join-Path $parent ('.' + [IO.Path]::GetFileName($destination) + '.' + [Guid]::NewGuid().ToString('N') + '.tmp')
  try { [IO.File]::WriteAllBytes($temp,$bytes); [IO.File]::Move($temp,$destination,$false) } finally { if(Test-Path $temp){Remove-Item $temp -Force} }
  $record=[pscustomobject][ordered]@{ logical_key=$logical; kind=$Kind; run_id=$RunId; run_attempt=$RunAttempt; artifact_name=$ArtifactName; path=$relative; sha256=$digest }
  $records=@($Store.index.records)+@($record); $Store.index=[pscustomobject][ordered]@{ schema_version='mnf-phase08-live-index/1'; root_intent_sha256=[string]$Store.index.root_intent_sha256; records=$records }
  Write-P08ReplaceJson $Store.paths.index $Store.index
  $record
}

function Add-P08DerivedEvidenceRecord {
  param([object]$Store,[string]$Kind,[string]$LogicalKey,[string]$RelativePath,[string]$SourcePath,[string]$RunId='derived',[int]$RunAttempt=0,[string]$ArtifactName)
  if ($RelativePath -notmatch '^(observations|authorization)/[A-Za-z0-9._/-]+[.]json$') { Throw-P08HostedRule 'P08-STORE-DERIVED-PATH' 'Derived evidence path is not allowlisted.' }
  $destination=Test-P08SafePath (Join-Path $Store.paths.root $RelativePath) $Store.paths.root
  $digest=Get-P08Sha256 $SourcePath
  $matches=@($Store.index.records | Where-Object { $_.logical_key -ceq $LogicalKey })
  if ($matches.Count -gt 1) { Throw-P08HostedRule 'P08-STORE-DUPLICATE' "Ambiguous logical evidence '$LogicalKey'." }
  if ($matches.Count -eq 1) {
    if ($matches[0].path -cne $RelativePath -or $matches[0].sha256 -cne $digest -or (Get-P08Sha256 $destination) -cne $digest) { Throw-P08HostedRule 'P08-STORE-RESUME-DRIFT' "Immutable evidence '$LogicalKey' changed." }
    return $matches[0]
  }
  if (Test-Path -LiteralPath $destination) { Throw-P08HostedRule 'P08-STORE-COLLISION' "Unindexed destination '$RelativePath' exists." }
  $parent=Split-Path -Parent $destination; $null=New-Item -ItemType Directory -Force $parent
  $temp=Join-Path $parent ('.' + [IO.Path]::GetFileName($destination) + '.' + [Guid]::NewGuid().ToString('N') + '.tmp')
  try { [IO.File]::WriteAllBytes($temp,[IO.File]::ReadAllBytes($SourcePath)); [IO.File]::Move($temp,$destination,$false) } finally { if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Force} }
  $record=[pscustomobject][ordered]@{logical_key=$LogicalKey;kind=$Kind;run_id=$RunId;run_attempt=$RunAttempt;artifact_name=$ArtifactName;path=$RelativePath;sha256=$digest}
  $Store.index=[pscustomobject][ordered]@{schema_version='mnf-phase08-live-index/1';root_intent_sha256=[string]$Store.index.root_intent_sha256;records=@($Store.index.records)+@($record)}
  Write-P08ReplaceJson $Store.paths.index $Store.index
  $record
}

function New-P08AuthorizationPacket {
  param([object]$Store,[string]$PreparedDigest,[object]$DryRunRecord,[object]$DryRunEvidence,[object]$AbsenceRecord,[object]$AbsenceEvidence,[object]$PreflightRecord,[object]$PreflightEvidence,[object]$GateDigests)
  if ($Store.locator.authorization_packet_path -or $Store.locator.authorization_packet_sha256) { Throw-P08HostedRule 'P08-PACKET-ALREADY-BOUND' 'Authorization packet is already bound.' }
  if ([string]$AbsenceEvidence.outcome -cne 'absent' -or $AbsenceEvidence.mutation_authorized -ne $false -or [string]$AbsenceEvidence.identity -cne 'tchivs/mb-core' -or [string]$AbsenceEvidence.version -cne '0.1.0') { Throw-P08HostedRule 'P08-PACKET-ABSENCE' 'Fresh exact core absence is required.' }
  $dryProjection=[ordered]@{};foreach($p in $DryRunEvidence.PSObject.Properties){$dryProjection[$p.Name]=$p.Value};$dryProjection.path=[string]$DryRunRecord.path;$dryProjection.sha256=[string]$DryRunRecord.sha256;$dryProjection.artifact_name=[string]$DryRunRecord.artifact_name
  $nativeProjection=[ordered]@{};foreach($p in $PreflightEvidence.PSObject.Properties){$nativeProjection[$p.Name]=$p.Value};$nativeProjection.path=[string]$PreflightRecord.path;$nativeProjection.sha256=[string]$PreflightRecord.sha256;$nativeProjection.artifact_name=[string]$PreflightRecord.artifact_name
  $absenceProjection=[ordered]@{outcome='absent';mutation_authorized=$false;identity='tchivs/mb-core@0.1.0';observed_at_utc=[string]$AbsenceEvidence.completed_at_utc;path=[string]$AbsenceRecord.path;sha256=[string]$AbsenceRecord.sha256}
  $packet=[ordered]@{
    schema_version='mnf-phase08-authorization-packet/1';repository=[string]$Store.locator.repository;workflow=[string]$Store.locator.workflow
    release_ref=[string]$Store.locator.release_ref;source_sha=[string]$Store.locator.source_sha;root_intent_sha256=[string]$Store.locator.root_intent_sha256
    intent_sha256=[string]$Store.locator.intent_sha256;prepared_manifest_sha256=$PreparedDigest;target_module='mb-core'
    publisher_dry_run=[pscustomobject]$dryProjection;fresh_absence=[pscustomobject]$absenceProjection;hosted_preflight=[pscustomobject]$nativeProjection
    gate_digests=$GateDigests;created_at_utc=[DateTime]::UtcNow.ToString('o');packet_sha256=''
  }
  $projection=[ordered]@{};foreach($entry in $packet.GetEnumerator()){if($entry.Key -cne 'packet_sha256'){$projection[$entry.Key]=$entry.Value}}
  $packet.packet_sha256=Get-P08ObjectDigest ([pscustomobject]$projection)
  $temporary=Join-Path ([IO.Path]::GetTempPath()) ('mnf-p08-packet-'+[Guid]::NewGuid().ToString('N')+'.json')
  try {
    [IO.File]::WriteAllText($temporary,(Get-P08CanonicalJson ([pscustomobject]$packet)),[Text.UTF8Encoding]::new($false))
    $record=Add-P08DerivedEvidenceRecord -Store $Store -Kind 'authorization-packet' -LogicalKey 'authorization|authorize-core' -RelativePath 'authorization/authorize-core.json' -SourcePath $temporary -ArtifactName 'authorize-core.json'
  } finally { if(Test-Path -LiteralPath $temporary){Remove-Item -LiteralPath $temporary -Force} }
  $locatorProjection=Get-P08LocatorProjection $Store.locator
  $Store.locator.authorization_packet_path=[string]$record.path;$Store.locator.authorization_packet_sha256=[string]$record.sha256
  $Store.locator.locator_sha256=Get-P08ObjectDigest (Get-P08LocatorProjection $Store.locator)
  Write-P08ReplaceJson $Store.paths.locator $Store.locator
  [pscustomobject]@{packet_path=(Join-Path $Store.paths.root $record.path);packet_sha256=[string]$packet.packet_sha256;file_sha256=[string]$record.sha256;record=$record}
}

function Invoke-P08Gh([string[]]$Arguments) {
  if ($null -ne $script:GhCommand) { return (& $script:GhCommand $Arguments) }
  $output=& gh @Arguments 2>&1; if ($LASTEXITCODE -ne 0) { Throw-P08HostedRule 'P08-HOSTED-GH' 'GitHub CLI operation failed.' }; $output
}

function Get-P08Runs([string]$Repo,[string]$WorkflowPath) {
  $json=(Invoke-P08Gh @('run','list','--repo',$Repo,'--workflow',$WorkflowPath,'--event','workflow_dispatch','--limit','100','--json','databaseId,headBranch,headSha,status,conclusion,displayTitle,workflowName,url,createdAt,updatedAt')) -join "`n"
  if ([string]::IsNullOrWhiteSpace($json)) { return @() }
  @($json | ConvertFrom-Json -Depth 30)
}

function Select-P08NewRun([hashtable]$Before,[object[]]$Runs,[string]$Sha,[string]$Title,[string]$DispatchRef) {
  $matches=@($Runs | Where-Object { -not $Before.ContainsKey([string]$_.databaseId) -and $_.headBranch -ceq $DispatchRef -and $_.headSha -ceq $Sha -and $_.displayTitle -ceq $Title })
  if ($matches.Count -gt 1) { Throw-P08HostedRule 'P08-HOSTED-AMBIGUOUS-RUN' 'Multiple new bound runs exist.' }
  if ($matches.Count -eq 1) { return $matches[0] }
  $null
}

function Select-P08Artifact([object]$Response,[string]$Prefix) {
  $matches=@($Response.artifacts | Where-Object { -not $_.expired -and $_.name.StartsWith($Prefix,[StringComparison]::Ordinal) })
  if ($matches.Count -ne 1) { Throw-P08HostedRule 'P08-HOSTED-AMBIGUOUS-ARTIFACT' 'Expected exactly one bound sanitized artifact.' }
  $matches[0]
}

function Invoke-P08HostedDispatch {
  param([string]$Operation,[string]$Repo,[string]$WorkflowPath,[string]$Ref,[string]$Sha,[string]$RootIntent,[string]$CurrentIntent,[string]$PreparedDigest,[string]$Module,[string]$PriorId,[string]$PriorArtifact,[string]$Packet)
  $before=@{}; foreach($run in @(Get-P08Runs $Repo $WorkflowPath)){ $before[[string]$run.databaseId]=$true }
  $fields=@('operation_mode='+$Operation,'run_mode='+(if([string]::IsNullOrWhiteSpace($PriorId)){'start'}else{'resume'}),'release_ref='+$Ref,'source_sha='+$Sha,'root_intent_sha256='+$RootIntent,'intent_sha256='+$CurrentIntent,'prepared_manifest_sha256='+$PreparedDigest,'target_module='+$Module,'live_authorization='+(if($Operation -ceq 'PublishOne'){'true'}else{'false'}),'prior_run_id='+$PriorId,'prior_artifact_name='+$PriorArtifact,'authorization_packet_sha256='+(if([string]::IsNullOrWhiteSpace($Packet)){''}else{Get-P08Sha256 $Packet}))
  $dispatchRef=if($Ref.StartsWith('refs/tags/',[StringComparison]::Ordinal)){$Ref.Substring(10)}else{$Ref}
  $args=@('workflow','run',$WorkflowPath,'--repo',$Repo,'--ref',$dispatchRef); foreach($field in $fields){$args+=@('-f',$field)}
  $null=Invoke-P08Gh $args
  $title="MNF $Operation $Module $RootIntent $CurrentIntent $PreparedDigest"
  $deadline=[DateTime]::UtcNow.AddMinutes(45); $candidate=$null
  do {
    $candidate=Select-P08NewRun -Before $before -Runs @(Get-P08Runs $Repo $WorkflowPath) -Sha $Sha -Title $title -DispatchRef $dispatchRef
    if ($null -ne $candidate -and $candidate.status -ceq 'completed') { break }
    Start-Sleep -Seconds 10
  } while([DateTime]::UtcNow -lt $deadline)
  if ($null -eq $candidate -or $candidate.status -cne 'completed' -or $candidate.conclusion -cne 'success') { Throw-P08HostedRule 'P08-HOSTED-RUN' 'Unique bound run did not complete successfully.' }
  $viewJson=(Invoke-P08Gh @('run','view',[string]$candidate.databaseId,'--repo',$Repo,'--json','databaseId,attempt,headBranch,headSha,event,status,conclusion,displayTitle,workflowName,url,createdAt,updatedAt')) -join "`n"
  $view=$viewJson | ConvertFrom-Json -Depth 30
  if ($view.databaseId -ne $candidate.databaseId -or $view.attempt -lt 1 -or $view.headBranch -cne $dispatchRef -or $view.headSha -cne $Sha -or $view.event -cne 'workflow_dispatch' -or $view.displayTitle -cne $title -or $view.conclusion -cne 'success') { Throw-P08HostedRule 'P08-HOSTED-RUN-BINDING' 'Terminal run binding drifted.' }
  $view
}

function Receive-P08HostedArtifact {
  param([object]$Run,[string]$Repo,[string]$Prefix,[string]$StoreKind,[object]$Store,[string]$Operation,[string]$PreparedDigest,[string]$Module)
  $response=((Invoke-P08Gh @('api',"repos/$Repo/actions/runs/$($Run.databaseId)/artifacts")) -join "`n") | ConvertFrom-Json -Depth 30
  $selected=Select-P08Artifact -Response $response -Prefix $Prefix
  $download=Join-Path ([IO.Path]::GetTempPath()) ('mnf-p08-download-' + [Guid]::NewGuid().ToString('N'))
  try {
    $null=New-Item -ItemType Directory -Path $download
    $null=Invoke-P08Gh @('run','download',[string]$Run.databaseId,'--repo',$Repo,'--name',[string]$selected.name,'--dir',$download)
    $files=@(Get-ChildItem -LiteralPath $download -Recurse -File -Filter '*.json')
    if ($files.Count -ne 1) { Throw-P08HostedRule 'P08-HOSTED-ARTIFACT-CONTENT' 'Sanitized artifact must contain exactly one JSON file.' }
    $value=Get-Content -LiteralPath $files[0].FullName -Raw | ConvertFrom-Json -Depth 100
    Assert-P08HostedEvidence -Operation $Operation -Evidence $value -Run $Run -Store $Store -PreparedDigest $PreparedDigest -Module $Module
    $record=Add-P08ArtifactRecord -Store $Store -Kind $StoreKind -RunId ([string]$Run.databaseId) -RunAttempt ([int]$Run.attempt) -ArtifactName ([string]$selected.name) -SourcePath $files[0].FullName
    [pscustomobject]@{ value=$value; record=$record; github_artifact_id=[string]$selected.id; github_artifact_digest=[string]$selected.digest }
  } finally { if(Test-Path $download){Remove-Item -LiteralPath $download -Recurse -Force} }
}

if ($LibraryOnly) { return }
$script:GhCommand=$GhCommand
$store=Open-P08ArtifactStore -Locator $LocatorPath -Root $ArtifactRoot -Repo $Repository -WorkflowPath $Workflow -Ref $ReleaseRef -Sha $SourceSha -RootIntent $RootIntentSha256 -CurrentIntent $IntentSha256
if ($Mode -ceq 'PublishOne') {
  if ([string]::IsNullOrWhiteSpace($AuthorizationPacketPath) -or -not (Test-Path -LiteralPath $AuthorizationPacketPath -PathType Leaf)) { Throw-P08HostedRule 'P08-HOSTED-AUTHORIZATION' 'PublishOne requires the unchanged authorization packet.' }
}
$run=Invoke-P08HostedDispatch -Operation $Mode -Repo $Repository -WorkflowPath $Workflow -Ref $ReleaseRef -Sha $SourceSha -RootIntent $RootIntentSha256 -CurrentIntent $IntentSha256 -PreparedDigest $PreparedManifestSha256 -Module $TargetModule -PriorId $PriorRunId -PriorArtifact $PriorArtifactName -Packet $AuthorizationPacketPath
$prefix=if($Mode -ceq 'PublisherDryRun'){'mnf-publisher-dry-run-'}elseif($Mode -ceq 'HostedPreflight'){'mnf-hosted-preflight-'}else{'mnf-checkpoint-'}
$kind=if($Mode -ceq 'PublisherDryRun'){'publisher-dry-run'}elseif($Mode -ceq 'HostedPreflight'){'hosted-preflight'}else{'publish-one'}
$artifact=Receive-P08HostedArtifact -Run $run -Repo $Repository -Prefix $prefix -StoreKind $kind -Store $store -Operation $Mode -PreparedDigest $PreparedManifestSha256 -Module $TargetModule
[pscustomobject][ordered]@{ mode=$Mode; run_id=[string]$run.databaseId; run_attempt=[int]$run.attempt; conclusion=[string]$run.conclusion; artifact_name=[string]$artifact.record.artifact_name; artifact_sha256=[string]$artifact.record.sha256; artifact_path=[string]$artifact.record.path; evidence=$artifact.value }
