# Phase 6: Namespace Authority and Compatibility Contract - Pattern Map

**Mapped:** 2026-07-17
**Files analyzed:** 24 explicit or grouped new/modified paths
**Analogs found:** 21 / 24 (3 responsibilities have only partial analogs)

## Scope Extracted from Context and Research

Phase 6 adds a credential-redacted observation plane and a credential-free Required validation plane. Policy JSON remains the machine authority; schemas are closed; reports separate stable content from run-local facts; every ambiguous interface or registry fact fails closed. The existing v0.1 report and `release/qualification/v0.1-requirements.json` remain semantically unchanged.

The research names the following exact new paths:

- `policy/registry-authority.json`
- `release/registry/authority-observation-schema.json`
- `release/registry/capability-matrix-schema.json`
- `release/registry/authority-observation.json`
- `scripts/quality/Invoke-RegistryObservation.ps1`
- `scripts/quality/Test-RegistryAuthority.ps1`
- `compatibility/schema/baseline-schema.json`
- `compatibility/schema/comparison-schema.json`
- `compatibility/baselines/0.1.0/<module>/<package>/raw.mbti`
- `compatibility/baselines/0.1.0/<module>/<package>/baseline.json`
- `policy/compatibility.json`
- `scripts/quality/New-PublicInterfaceBaseline.ps1`
- `scripts/quality/Compare-PublicInterfaceBaseline.ps1`
- `scripts/quality/Test-PublicCompatibility.ps1`

The context/research also requires modifications to the existing Required integration and publication documentation:

- `scripts/quality/Invoke-MoonQuality.ps1`, `scripts/quality.ps1`, and `.github/workflows/quality.yml`
- `scripts/quality/Test-CandidateDocumentation.ps1`
- `modules/mb-{core,color,image}/moon.mod.json`
- `modules/mb-{core,color,image}/README.mbt.md`
- `modules/mb-{core,color,image}/CHANGELOG.md`

The research requires but does not name exact paths for a Phase 6 selector/artifact ledger beside the locked v0.1 ledger, negative fixtures, shared support/security route documents, and conditional migration notes. The planner must freeze those paths rather than silently modifying the v0.1 ledger or inventing different module-local truths.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `policy/registry-authority.json` | config / policy model | file-I/O, transform | `policy/release-qualification.json` | exact role and flow |
| `policy/compatibility.json` | config / policy model | file-I/O, transform | `policy/release-qualification.json` | exact role and flow |
| `release/registry/authority-observation-schema.json` | schema / model | file-I/O validation | `release/qualification/package-schema.json` | exact role and flow |
| `release/registry/capability-matrix-schema.json` | schema / model | file-I/O validation | `release/qualification/package-schema.json` | exact role and flow |
| `compatibility/schema/baseline-schema.json` | schema / model | file-I/O validation | `release/qualification/package-schema.json` | exact role and flow |
| `compatibility/schema/comparison-schema.json` | schema / model | file-I/O validation | `release/qualification/package-schema.json` | exact role and flow |
| `release/registry/authority-observation.json` | evidence model | request-response to sanitized file-I/O | `release/qualification/package-schema.json` plus stable-object helpers | partial; no authenticated analog |
| `scripts/quality/Invoke-RegistryObservation.ps1` | operator-only service / utility | request-response, file-I/O | `ReleaseQualification.Common.ps1` | partial; no credential-safe command collector exists |
| `scripts/quality/Test-RegistryAuthority.ps1` | validator / test | file-I/O, transform | `ReleaseQualification.Common.ps1` + `Test-ReleaseQualificationNegative.ps1` | role-match |
| `compatibility/baselines/0.1.0/**/raw.mbti` | immutable evidence model | batch file-I/O | current `pkg.generated.mbti` checks in `Invoke-MoonQuality.ps1` | partial; raw retention is new |
| `compatibility/baselines/0.1.0/**/baseline.json` | normalized evidence model | batch transform | release report stable-object pattern | role-match |
| `scripts/quality/New-PublicInterfaceBaseline.ps1` | generator / utility | batch, file-I/O, transform | `Test-CandidateDocumentation.ps1` isolated-copy helpers + release hashing helpers | role-match |
| `scripts/quality/Compare-PublicInterfaceBaseline.ps1` | comparator / service | batch transform | exact sequence/set helpers | partial; structural `.mbti` classification is new |
| `scripts/quality/Test-PublicCompatibility.ps1` | validator / test | batch transform | `Test-ReleaseQualificationNegative.ps1` | exact test shape |
| `scripts/quality/Test-CandidateDocumentation.ps1` | validator / test | batch file-I/O | its existing policy-driven module loop | exact in-place extension |
| `modules/mb-{core,color,image}/moon.mod.json` | config | file-I/O validation | current three manifests | exact in-place extension |
| `modules/mb-{core,color,image}/README.mbt.md` | documentation / executable test | batch transform | current three literate READMEs | exact in-place extension |
| `modules/mb-{core,color,image}/CHANGELOG.md` | documentation / evidence model | file-I/O validation | current three changelogs | exact in-place extension |
| `scripts/quality/Invoke-MoonQuality.ps1` | orchestrator | batch | existing `Invoke-QualityStage` Required sequence | exact in-place extension |
| `scripts/quality.ps1` | entrypoint / route | request-response | existing lane dispatcher | exact in-place extension |
| `.github/workflows/quality.yml` | CI config | event-driven, batch | existing Required job | exact in-place extension |
| Phase 6 selector/artifact ledger path (TBD) | config / evidence index | batch file-I/O | `release/qualification/v0.1-requirements.json` validation in common helpers | role-match; must be separate |
| support/security/migration document paths (TBD) | documentation | file-I/O validation | module README/changelog collective contract | role-match |
| compatibility and authority negative fixture paths (TBD) | test fixture | batch file-I/O | `qualification/negative/**` | exact fixture shape |

## Five Closest Analogs

### 1. `policy/release-qualification.json` — centralized closed facts

Use for `policy/registry-authority.json` and `policy/compatibility.json`. It owns ordered modules, targets, module metadata, dependencies, public package inventories, and an honest publication blocker rather than deriving these facts from prose.

**Identity and ordered facts** (`policy/release-qualification.json:2-16`):

```json
"schema_version": "1.0.0",
"module_order": [
  "mb-core",
  "mb-color",
  "mb-image"
],
"required_targets": [
  "js",
  "wasm",
  "wasm-gc",
  "native"
],
"candidate_status": "candidate",
"license": "Apache-2.0",
"repository": "https://github.com/moonbit-foundation/moonbit-foundation"
```

**Honest blocked external outcome** (`policy/release-qualification.json:44-49`):

```json
"publication": {
  "performed": false,
  "credentials_read": false,
  "namespace_verified": false,
  "blocked_reason": "unverified_mooncakes_owner_namespace"
}
```

**Per-module exact identity, dependencies, and package inventory** (`policy/release-qualification.json:50-70`):

```json
"modules": {
  "mb-core": {
    "manifest": {
      "name": "moonbit-foundation/mb-core",
      "version": "0.1.0",
      "preferred-target": "native",
      "supported-targets": "+js+wasm+wasm-gc+native"
    },
    "dependencies": {},
    "public_packages": [
      "moonbit-foundation/mb-core/error",
      "moonbit-foundation/mb-core/checked",
      "moonbit-foundation/mb-core/budget",
      "moonbit-foundation/mb-core/bytes",
      "moonbit-foundation/mb-core/io",
      "moonbit-foundation/mb-core/host"
    ]
  }
}
```

**Assignment:** Keep authority facts, capability dispositions, compatibility consequences, and documentation requirements in separate versioned policy objects. Do not put live observations into policy or let README prose redefine consequences.

### 2. `release/qualification/package-schema.json` — closed JSON evidence

Use for all four new schemas. Every object is closed, required fields are explicit, identity values use `const`, and digests/commit identities use anchored patterns.

**Closed root and exact identity** (`release/qualification/package-schema.json:5-11`):

```json
"type": "object",
"additionalProperties": false,
"required": ["schema_version", "head", "module_order", "copies", "modules", "post_publish_order", "publication", "tracked_diff_unchanged"],
"properties": {
  "schema_version": { "const": "1.0.0" },
  "head": { "type": "string", "pattern": "^[0-9a-f]{40}$" },
  "module_order": { "const": ["mb-core", "mb-color", "mb-image"] }
}
```

**Closed credential-free publication record** (`release/qualification/package-schema.json:41-50`):

```json
"publication": {
  "type": "object",
  "additionalProperties": false,
  "required": ["performed", "credentials_read", "namespace_verified", "blocked_reason"],
  "properties": {
    "performed": { "const": false },
    "credentials_read": { "const": false },
    "namespace_verified": { "const": false },
    "blocked_reason": { "const": "unverified_mooncakes_owner_namespace" }
  }
}
```

**Reusable digest record** (`release/qualification/package-schema.json:65-76`):

```json
"package": {
  "type": "object",
  "additionalProperties": false,
  "required": ["ordered_list", "archive_entries", "sha256", "size", "zip_bytes_equal", "manifest_exact"],
  "properties": {
    "ordered_list": { "type": "array", "minItems": 1, "items": { "type": "string" }, "uniqueItems": true },
    "sha256": { "type": "string", "pattern": "^[0-9a-f]{64}$" }
  }
}
```

**Assignment:** Authority and capability schemas should use closed enums `documented|safely_observed|unknown`; baseline/comparison schemas should use closed result enums `exact|additive|incompatible|unknown`. Unknown syntax or extra fields must reject, not disappear during normalization.

### 3. `scripts/quality/ReleaseQualification.Common.ps1` — validation, hashing, stable evidence

Use as the shared implementation style for registry and compatibility validators.

**Strict JSON and exact collection validation** (`scripts/quality/ReleaseQualification.Common.ps1:8-33`):

```powershell
function Read-ReleaseJson {
  param([Parameter(Mandatory)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required JSON is missing: $Path" }
  try { return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100 } catch { throw "Invalid JSON '$Path': $($_.Exception.Message)" }
}

function Assert-ReleaseExactSequence {
  param([string]$Label, [object[]]$Actual, [object[]]$Expected)
  if ($Actual.Count -ne $Expected.Count) { throw "$Label count mismatch: expected $($Expected.Count), got $($Actual.Count)." }
  for ($i = 0; $i -lt $Expected.Count; $i++) {
    if ([string]$Actual[$i] -cne [string]$Expected[$i]) { throw "$Label mismatch at index $i`: expected '$($Expected[$i])', got '$($Actual[$i])'." }
  }
}

function Assert-ReleaseClosedProperties {
  param([string]$Label, [object]$Object, [string[]]$Expected)
  Assert-ReleaseExactSet -Label "$Label properties" -Actual @($Object.PSObject.Properties | ForEach-Object { $_.Name }) -Expected $Expected
}
```

**Platform SHA-256 over files and UTF-8 stable text** (`scripts/quality/ReleaseQualification.Common.ps1:41-52`):

```powershell
function Get-ReleaseSha256 {
  param([Parameter(Mandatory)][string]$Path)
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-ReleaseTextSha256 {
  param([Parameter(Mandatory)][string]$Text)
  $algorithm = [Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text)
    return ([Convert]::ToHexString($algorithm.ComputeHash($bytes))).ToLowerInvariant()
  } finally { $algorithm.Dispose() }
}
```

**Stable/run-local separation** (`scripts/quality/ReleaseQualification.Common.ps1:128-140`, `190-202`):

```powershell
function Get-RequiredRunStableObject {
  param([Parameter(Mandatory)][object]$Report)
  return [ordered]@{
    schema_version = [string]$Report.schema_version
    head = [string]$Report.head
    ledger_sha256 = [string]$Report.ledger_sha256
    selector_order = @($Report.selector_order)
    selectors = @($Report.selectors)
    artifacts = @($Report.artifacts)
    publication = $Report.publication
    tracked_diff_unchanged = [bool]$Report.tracked_diff_unchanged
  }
}

$digest = Get-ReleaseTextSha256 -Text ($stable | ConvertTo-Json -Depth 100 -Compress)
$report.run_local = [ordered]@{
  started_utc = $StartedUtc
  completed_utc = [DateTime]::UtcNow.ToString('o')
  evidence_directory = $absoluteEvidence
  os = [Environment]::OSVersion.VersionString
  powershell = $PSVersionTable.PSVersion.ToString()
}
[IO.File]::WriteAllText($path, (($report | ConvertTo-Json -Depth 100) + "`n"), [Text.UTF8Encoding]::new($false))
```

**Mutation guard and safe temp cleanup** (`scripts/quality/ReleaseQualification.Common.ps1:240-251`, `372-383`):

```powershell
function Assert-ReleaseTrackedSnapshot {
  param([Parameter(Mandatory)][string]$Before, [Parameter(Mandatory)][string]$After)
  if ($Before -cne $After) {
    Throw-ReleaseRule -Id 'REL14-TRACKED-SOURCE-MUTATION' -Message 'tracked source differs from the captured baseline.'
  }
}

if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
    -not $leaf.StartsWith('mnf-release-qualification-', [StringComparison]::Ordinal)) {
  throw "Refusing to remove unverified release qualification path: $full"
}
Remove-Item -LiteralPath $full -Recurse -Force
```

**Assignment:** Reuse or extend these helpers rather than creating parallel JSON, hashing, exact-set, or safe-cleanup conventions. Stable authority/baseline digests must exclude timestamps and local paths while the full report retains them in a separate run-local object.

### 4. `scripts/quality/Test-ReleaseQualificationNegative.ps1` — exact rule-owned negatives

Use for authority drift, unexpected fields, stale observation, secret/path-shaped output, target divergence, unknown `.mbti` syntax, version-policy failure, missing migration/RFC, and documentation mismatch.

**UTF-8 fixture writes and exact diagnostic ownership** (`scripts/quality/Test-ReleaseQualificationNegative.ps1:17-34`):

```powershell
function Write-NegativeJson {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][object]$Value)
  $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path)
  [IO.File]::WriteAllText($Path, (($Value | ConvertTo-Json -Depth 100) + "`n"), [Text.UTF8Encoding]::new($false))
}

function Confirm-ExactRule {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][scriptblock]$Action)
  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure -or -not $failure.StartsWith("$Id`: ", [StringComparison]::Ordinal)) {
    throw "Negative '$Id' passed or failed for the wrong reason: '$failure'."
  }
}
```

**Rule table plus isolated mutation** (`scripts/quality/Test-ReleaseQualificationNegative.ps1:95-109`):

```powershell
$metadataCases = @(
  @{ id = 'REL08-MISSING-VERSION'; mutate = { param($p) $p.modules.'mb-core'.manifest.PSObject.Properties.Remove('version') } },
  @{ id = 'REL09-WRONG-STATUS'; mutate = { param($p) $p.candidate_status = 'stable' } },
  @{ id = 'REL10-MISSING-LICENSE'; mutate = { param($p) $p.license = '' } },
  @{ id = 'REL01-MODULE-ORDER'; mutate = { param($p) [Array]::Reverse($p.module_order) } }
)
foreach ($case in $metadataCases) {
  Confirm-ExactRule $case.id {
    $value = Read-ReleaseJson -Path $releasePolicy
    & $case.mutate $value
    $path = Join-Path $tempRoot "$($case.id).release.json"
    Write-NegativeJson -Path $path -Value $value
    Assert-ReleasePolicy -PolicyPath $path -FoundationPath $foundationPolicy -FixtureManifestPath $fixtureManifest -SchemaPath (Join-Path $repoRoot 'release\qualification\package-schema.json') -RepoRoot $repoRoot | Out-Null
  }
}
```

**Fixture immutability and guarded cleanup** (`scripts/quality/Test-ReleaseQualificationNegative.ps1:130-145`):

```powershell
foreach ($relative in $fixtureHashes.Keys) {
  if ((Get-ReleaseSha256 -Path (Join-Path $negativeRoot $relative)) -cne $fixtureHashes[$relative]) {
    throw "Negative fixture changed during classification: $relative"
  }
}
if (-not $full.StartsWith($tempBase + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
    -not (Split-Path -Leaf $full).StartsWith('mnf-release-negative-', [StringComparison]::Ordinal)) {
  throw "Refusing to remove unverified negative path: $full"
}
```

**Assignment:** Every negative must assert one stable rule ID and verify it failed for that reason. Never accept “any exception” for unknown syntax or security-sensitive observation rejection.

### 5. `scripts/quality/Test-CandidateDocumentation.ps1` — collective publication-doc contract

Use for PROV-03 and the existing module manifest/README/changelog modifications.

**One policy-owned module loop across manifest, README, and changelog** (`scripts/quality/Test-CandidateDocumentation.ps1:90-103`):

```powershell
foreach ($row in $moduleRows) {
  $modulePolicy = @($policy.modules | Where-Object { [string]$_.name -ceq $row.name })
  if ($modulePolicy.Count -ne 1) {
    Fail-Rule 'QUAL04-MANIFEST-METADATA' "Policy must contain exactly one module '$($row.name)'."
  }
  $manifestRelative = "$($row.path)/moon.mod.json"
  $readmeRelative = "$($row.path)/README.mbt.md"
  $changelogRelative = "$($row.path)/CHANGELOG.md"
  $manifest = Read-RequiredJson -Root $Root -Relative $manifestRelative -Rule 'QUAL04-MANIFEST-METADATA'
  $readme = Read-RequiredText -Root $Root -Relative $readmeRelative -Rule 'QUAL04-DOC-REQUIRED'
  $changelog = Read-RequiredText -Root $Root -Relative $changelogRelative -Rule 'QUAL04-DOC-REQUIRED'
}
```

**Exact metadata and dependency-floor checks** (`scripts/quality/Test-CandidateDocumentation.ps1:109-135`):

```powershell
foreach ($fact in @(
  @('name', [string]$modulePolicy.name),
  @('version', [string]$modulePolicy.version),
  @('description', [string]$modulePolicy.description),
  @('license', [string]$policy.license),
  @('repository', [string]$modulePolicy.repository),
  @('readme', 'README.mbt.md'),
  @('preferred-target', [string]$modulePolicy.preferred_target),
  @('supported-targets', $compactTargets)
)) {
  if ([string]$manifest.$field -cne $expected) {
    Fail-Rule 'QUAL04-MANIFEST-METADATA' "$manifestRelative field '$field' must equal '$expected'."
  }
}
Assert-ExactSet $actualDeps @($modulePolicy.direct_dependencies) 'QUAL04-MANIFEST-METADATA' "$manifestRelative dependency names"
```

**Collective required tokens and negative-copy pattern** (`scripts/quality/Test-CandidateDocumentation.ps1:137-148`, `210-238`):

```powershell
foreach ($token in @($row.name, '0.1.0', 'candidate', 'Apache-2.0', [string]$modulePolicy.repository, $compactTargets, 'CHANGELOG.md')) {
  Assert-Contains $readme $token 'QUAL04-DOC-REQUIRED' $readmeRelative
}
foreach ($token in @('0.1.0 candidate (unpublished)', 'Compatibility status: candidate', 'Deferred:')) {
  Assert-Contains $changelog $token 'QUAL04-DOC-REQUIRED' $changelogRelative
}

function Invoke-NegativeCase {
  param([string]$Name, [string]$ExpectedRule, [scriptblock]$Mutate)
  $root = Copy-CandidateFixture
  try {
    & $Mutate $root
    try {
      Assert-CandidateTree -Root $root
      throw "Negative candidate case unexpectedly passed: $Name"
    } catch {
      if (-not $_.Exception.Message.StartsWith("[$ExpectedRule]", [System.StringComparison]::Ordinal)) {
        throw "Negative candidate case '$Name' failed with wrong rule: $($_.Exception.Message)"
      }
    }
  } finally { Remove-CandidateFixture -Path $root }
}
```

**Literate docs on every supported target** (`scripts/quality/Test-CandidateDocumentation.ps1:241-248`):

```powershell
foreach ($target in $requiredTargets) {
  foreach ($module in @('mb-core', 'mb-color', 'mb-image')) {
    & moon -C (Join-Path $repoRoot "modules/$module") check README.mbt.md --target $target --frozen
    if ($LASTEXITCODE -ne 0) {
      Fail-Rule 'QUAL04-EXAMPLE-RUNNABLE' "Literate README failed for $module on $target."
    }
  }
}
```

**Assignment:** Extend the collective contract with exact install/import commands, pinned/minimum toolchain, current change class, support/security routes, changelog/migration links, and source metadata intended for registry rendering. Keep `registry_renders_intended_metadata` explicitly `unknown` until registry-side evidence exists.

## Required Integration Pattern

These are existing modification targets rather than additional analogs.

- `scripts/quality/Invoke-MoonQuality.ps1:553-567` captures the tracked-diff baseline before Required stages and starts with the locked v0.1 ledger. Add Phase 6 stages beside that ledger; do not change its selector meanings.
- `scripts/quality/Invoke-MoonQuality.ps1:628-684` runs documentation, all-target README/workspace/module checks, interface generation, release qualification, the final tracked-diff proof, and deterministic report assertion. Place authority/compatibility validation before the final tracked-diff snapshot and bind its artifacts through a new Phase 6 contract.
- `scripts/quality.ps1:1-20` is a thin lane-preserving entrypoint. Avoid adding an observation lane here: the operator-only collector must not be reachable from Required.
- `.github/workflows/quality.yml:7-26` already uses read-only contents permission, checkout without persisted credentials, full-SHA-pinned actions, an exact toolchain, and the Required entrypoint. Preserve all four properties; Phase 6 adds no registry secret to this job.

## Shared Patterns

### Credential boundary

**Apply to:** authority policy/schema/artifact, observation collector, authority validator, Required integration.

- Required may read only tracked sanitized evidence and must continue to assert no credential access.
- The operator collector may invoke a closed allowlist of identity/status/read-only commands, but must never open a credential path or persist raw output.
- Sanitize into allowlisted scalar fields first, reject secret/header/cookie/path shapes, then write. Do not write raw output and redact afterward.
- Authenticated identity is not namespace authority. Missing namespace proof remains `unknown` and blocks publication.

### Closed inputs and exact diagnostics

**Apply to:** every new JSON policy, schema, report, comparator result, and negative fixture.

- Use `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` in executable scripts.
- Reject additional properties and unknown enum values.
- Use ordinal/case-sensitive comparisons for canonical identities and ordered records.
- Prefix failures with one stable rule ID and make negatives assert that exact ID.

### Stable evidence identity

**Apply to:** observation records, raw/normalized baselines, comparison reports, Required artifact bindings.

- Serialize ordered stable objects as compressed JSON for digest input.
- Use UTF-8 without BOM and one trailing newline for persisted JSON.
- Keep source commit, toolchain triplet, module/package/target/schema, raw digest, normalized digest, and inspection outcome in the stable record.
- Keep timestamps, absolute evidence directory, OS, and PowerShell version in a separate run-local record unless a timestamp is explicitly part of authority freshness validation.

### Isolated generation and source immutability

**Apply to:** baseline generator, compatibility tests, Required integration.

- Generate in two independent clean copies with `--frozen` and compare normalized records.
- Preserve canonical raw `pkg.generated.mbti`; target commands are inspections referencing that raw digest, not separate target-generated raw files.
- Snapshot tracked diff before and after Required. Generators in check mode must not mutate tracked source.
- Guard every recursive temp cleanup by resolved temp-root containment and a unique MNF prefix.

### Policy-owned documentation

**Apply to:** manifests, READMEs, changelogs, support/security documents, migration notes.

- Policy owns version consequences and required evidence.
- The three documentation sets consume identical support/security routes and exact module facts.
- Changelogs state the change class; incompatible pre-1.0 changes additionally link a migration note; RFC evidence is conditional on a boundary/architecture/governance change.
- Literate READMEs remain executable on `js`, `wasm`, `wasm-gc`, and `native`.

## No Exact Analog Found

| Responsibility | Proposed File(s) | Why No Exact Analog Exists | Planner Direction |
|---|---|---|---|
| Credential-safe authenticated/read-only observation | `scripts/quality/Invoke-RegistryObservation.ps1`, `release/registry/authority-observation.json` | Existing Required code intentionally never authenticates and has no sanitizer for auth command output. | Reuse strict mode, stable-object hashing, closed schemas, exact rule IDs, and safe writes; design a new closed command/output allowlist and keep it outside Required. |
| Lossless `.mbti` structural normalization and four-class comparison | `New-PublicInterfaceBaseline.ps1`, `Compare-PublicInterfaceBaseline.ps1` | Existing `Assert-GeneratedInterface` compares exact line arrays but does not parse declarations or classify additive/incompatible/unknown changes. | Define a versioned grammar subset. Any unrepresented syntax, target divergence, toolchain mismatch, or ambiguous match returns `unknown`; never normalize it away. |
| Registry-render equality proof | Phase 6 documentation evidence | Existing tests validate source metadata only; the registry has not been safely observed. | Validate renderable source metadata now and record registry rendering as `unknown`; do not fabricate a pass or make a production mutation in Phase 6. |

## Planner Guardrails

1. Do not edit `release/qualification/v0.1-requirements.json` or reinterpret the locked v0.1 report. Add a separate Phase 6 selector/artifact contract and aggregate it at the Required orchestration layer.
2. Do not call the operator observation collector from Required or CI.
3. Do not rewrite `moonbit-foundation/*` identities until sanitized authority evidence proves a mismatch and a later explicit decision authorizes a rename.
4. Do not make real `mb-core`, `mb-color`, or `mb-image` publication a Phase 6 acceptance step.
5. Do not infer behavior, resource limits, semantics, or registry artifact byte identity from `.mbti` text equality.
6. Do not add a second approver, quorum, or team ceremony; explicit sole-maintainer intent plus machine verification remains the governance model.

## Metadata

**Analog search scope:** `policy/`, `release/qualification/`, `qualification/negative/`, `scripts/quality/`, `.github/workflows/`, `modules/mb-{core,color,image}/`, and referenced governance/policy docs.

**Strong analogs used:** 5 files — `policy/release-qualification.json`, `release/qualification/package-schema.json`, `scripts/quality/ReleaseQualification.Common.ps1`, `scripts/quality/Test-ReleaseQualificationNegative.ps1`, and `scripts/quality/Test-CandidateDocumentation.ps1`.

**Pattern extraction date:** 2026-07-17
