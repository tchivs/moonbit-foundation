# Phase 7: Release Safety, Intent, and Recovery Automation - Pattern Map

**Mapped:** 2026-07-18
**Files analyzed:** 16 likely new or modified files
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `policy/release-control.json` | config/policy | batch validation | `policy/release-qualification.json` | exact |
| `release/intent/schema.json` | model/schema | transform | `release/qualification/package-schema.json` | exact |
| `release/intent/README.md` | documentation | file I/O | `release/intent/schema.json` plus policy-first convention | role-match |
| `release/journal/record-schema.json` | model/schema | event-driven append-only | `release/registry/authority-observation-schema.json` | role-match |
| `release/journal/state-schema.json` | model/schema | state-machine transform | `release/registry/authority-observation-schema.json` | role-match |
| `release/prepared/schema.json` | model/schema | cross-job file I/O transform | `release/qualification/package-schema.json` plus `release/registry/authority-observation-schema.json` | role-match |
| `release/qualification/phase-07-requirements.json` | config/evidence ledger | batch | `release/qualification/phase-06-requirements.json` | exact |
| `scripts/quality/New-ReleaseIntent.ps1` | utility/generator | file I/O transform | `scripts/quality/Invoke-ReleaseQualification.ps1` | role-match |
| `scripts/quality/Test-ReleaseIntent.ps1` | test/validator | batch transform | `scripts/quality/ReleaseQualification.Common.ps1` | role-match |
| `scripts/quality/ReleasePublisher.Common.ps1` | service/pure reducer | event-driven transform | `scripts/quality/ReleaseQualification.Common.ps1` | role-match |
| `scripts/quality/Invoke-ReleasePublisher.ps1` | controller/orchestrator | event-driven request-response | `scripts/quality/Invoke-ReleaseQualification.ps1` | role-match |
| `scripts/quality/Test-ReleasePublisherNegative.ps1` | test/fixture matrix | event-driven transform | `scripts/quality/Test-RegistryAuthorityNegative.ps1` | exact |
| `scripts/quality/Test-Phase07Qualification.ps1` | test/integration gate | batch | `scripts/quality/Test-Phase06Qualification.ps1` | exact |
| `scripts/quality/ReleaseQualification.Common.ps1` | shared utility (modify) | transform | existing file's stable projection/hash helpers | exact |
| `scripts/quality/Invoke-ReleaseQualification.ps1` and `Invoke-MoonQuality.ps1` | orchestrators (modify) | batch/file I/O | existing release report and Required-stage seams | exact |
| `.github/workflows/publish-modules.yml` | config/controller | event-driven | `.github/workflows/quality.yml` | role-match |

## Pattern Assignments

### Policy, intent, journal, and prepared-bundle contracts

**Primary analogs:** `policy/release-qualification.json`, `release/qualification/package-schema.json`, and `release/registry/authority-observation-schema.json`.

Copy the policy-owned exact order and immutable identity shape from `policy/release-qualification.json` lines 1-16 and 36-49:

```json
{
  "schema_version": "1.0.0",
  "module_order": ["mb-core", "mb-color", "mb-image"],
  "repository": "https://github.com/tchivs/moonbit-foundation",
  "post_publish_order": [
    "publish:tchivs/mb-core@0.1.0",
    "resolve:tchivs/mb-core@0.1.0"
  ],
  "publication": {
    "performed": false,
    "credentials_read": false
  }
}
```

For `policy/release-control.json`, retain the same machine-authoritative style: closed known fields, exact actor/repository/tag/environment constants, exact module order, exact allowed transitions and sanitized outcomes. Prose may explain the policy but must not override it.

Copy the closed-schema pattern from `release/qualification/package-schema.json` lines 1-11 and 41-52:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "additionalProperties": false,
  "required": ["schema_version", "head", "module_order"],
  "properties": {
    "schema_version": { "const": "1.0.0" },
    "head": { "type": "string", "pattern": "^[0-9a-f]{40}$" },
    "module_order": { "const": ["mb-core", "mb-color", "mb-image"] }
  }
}
```

Use this for `release/intent/schema.json`, `release/journal/record-schema.json`, `release/journal/state-schema.json`, and `release/prepared/schema.json`: `additionalProperties: false` at every object layer, `const` for fixed identities/order, enums for states/outcomes, and strict 40/64-hex patterns. For the journal and prepared manifest, adapt the sanitized-observation shape from `release/registry/authority-observation-schema.json` lines 34-60 and the fact/state enum pattern at lines 111-120. The prepared schema additionally requires a stable exact payload inventory with unique relative path/role, byte size, and SHA-256 for qualification artifacts, exact source, intent evidence, journal/genesis, scripts, policies, and schemas. Never admit raw output, credential paths, headers, cookies, arbitrary state names, unlisted files, or path traversal.

`release/intent/README.md` has no separate runtime analog; keep it explanatory and point to the schema/policy as authority. Do not duplicate mutable values as a competing contract.

### `scripts/quality/New-ReleaseIntent.ps1` and qualification integration

**Analog:** `scripts/quality/Invoke-ReleaseQualification.ps1` plus the stable-report helpers in `ReleaseQualification.Common.ps1`.

Copy the evidence-only entry shape from `Invoke-ReleaseQualification.ps1` lines 1-25:

```powershell
[CmdletBinding()]
param(
  [switch]$Check,
  [string]$PolicyPath = 'policy/release-qualification.json',
  [string]$OutputDirectory = 'artifacts/release-qualification/current'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot 'ReleaseQualification.Common.ps1')
if (-not $Check) { throw 'Release qualification is evidence-only and requires -Check.' }
```

Generate the intent only after archive/interface/qualification evidence exists. Follow the acyclic stable projection used by `Get-RequiredRunStableObject` and `Write-RequiredQualificationReport` in `ReleaseQualification.Common.ps1` lines 128-203:

```powershell
$stable = [ordered]@{
  schema_version = '1.0.0'
  head = $head
  ledger_sha256 = Get-ReleaseSha256 -Path $ledgerPath
  selector_order = @($ledger.selectors.id)
  artifacts = @($artifacts)
  tracked_diff_unchanged = $true
}
$digest = Get-ReleaseTextSha256 -Text ($stable | ConvertTo-Json -Depth 100 -Compress)
[IO.File]::WriteAllText($path, (($report | ConvertTo-Json -Depth 100) + "`n"), [Text.UTF8Encoding]::new($false))
```

The Phase 7 generator should narrow this further to its controlled canonical profile (schema-ordered `[ordered]` objects, policy-ordered arrays, compact UTF-8 without BOM, no floats), then let the final Required wrapper point one-way to the intent digest. Do not hash the final wrapper if it embeds that same digest.

Modify `Invoke-ReleaseQualification.ps1` at its report assembly seam (lines 326-347) to emit/bind the stable intent after tracked-diff validation, preserving `performed=false` and `credentials_read=false`. Modify `Invoke-MoonQuality.ps1` at its Required stages/report seam (existing lines 740-753) to run the Phase 7 credential-free validator and attach only sanitized, deterministic Phase 7 evidence.

### `scripts/quality/Test-ReleaseIntent.ps1`

**Analog:** validation primitives in `ReleaseQualification.Common.ps1` lines 3-52 and report validation at lines 206-237.

```powershell
function Throw-ReleaseRule {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][string]$Message)
  throw "$Id`: $Message"
}

function Assert-ReleaseClosedProperties {
  param([string]$Label, [object]$Object, [string[]]$Expected)
  if ($null -eq $Object) { throw "$Label is missing." }
  Assert-ReleaseExactSet -Label "$Label properties" -Actual @($Object.PSObject.Properties.Name) -Expected $Expected
}
```

Use exact ordinal comparisons, exact sequence checks, closed properties, strict digest regexes, and diagnostic IDs. Recompute the canonical stable object/digest exactly as the generator does. Validate Git refs with Git object resolution, not name regex alone. Test two clean copies for byte/digest equality and mutate every bound source to prove rejection.

### `scripts/quality/ReleasePublisher.Common.ps1` and `Invoke-ReleasePublisher.ps1`

**Closest analog:** `ReleaseQualification.Common.ps1` for pure helpers and exact diagnostics; `Invoke-ReleaseQualification.ps1` for an orchestration shell with isolated side-effect functions.

Reuse these concrete primitives from `ReleaseQualification.Common.ps1` lines 14-52:

```powershell
function Assert-ReleaseExactSequence {
  param([string]$Label, [object[]]$Actual, [object[]]$Expected)
  if ($Actual.Count -ne $Expected.Count) { throw "$Label count mismatch." }
  for ($i = 0; $i -lt $Expected.Count; $i++) {
    if ([string]$Actual[$i] -cne [string]$Expected[$i]) { throw "$Label mismatch at index $i." }
  }
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

Keep the reducer pure: `(intent, verified journal, sanitized observation, requested operation) -> one legal command/record or exact diagnostic`. The common file must not read credentials, environment secrets, GitHub state, or the network. Append records as ordered closed objects with `sequence`, `prior_record_sha256`, `intent_sha256`, sanitized observation, outcome, timestamp, and recomputed digest.

`Invoke-ReleasePublisher.ps1` should be a thin adapter-driven controller. It validates actor/repository/ref/tag/source/intent and prior digest chain before selecting a single dependency-safe module. Its normal/test modes use injected observations only. The live mode may expose exactly one mutation command to the workflow's secret-bearing step, followed by deletion of the ephemeral Moon home and mandatory read-only re-observation. Unknown, timeout, mismatch, invalid auth, or stale evidence stop; there is no overwrite/delete/yank fallback.

### `scripts/quality/Test-ReleasePublisherNegative.ps1`

**Analog:** `scripts/quality/Test-RegistryAuthorityNegative.ps1` lines 16-28, 41-52, and 64-102.

```powershell
function Confirm-ExactRule {
  param([Parameter(Mandatory)][string]$Id, [Parameter(Mandatory)][scriptblock]$Action)
  $failure = $null
  try { & $Action } catch { $failure = $_.Exception.Message }
  if ($null -eq $failure -or -not $failure.StartsWith("$Id`: ", [StringComparison]::Ordinal)) {
    throw "Negative '$Id' passed or failed for the wrong reason: '$failure'."
  }
}

$cases = @(
  @{ id = 'RULE-ID'; mutate = { param($value) $value.some_field = 'invalid' } }
)
foreach ($case in $cases) {
  Confirm-ExactRule -Id $case.id -Action { ... }
}
```

Use mutated in-memory JSON and injected adapter outcomes for timeout, partial/exact success, existing mismatch, invalid auth, stale evidence, replay, concurrency/cancellation, sequence gaps, prior-digest mismatch, and skipped dependency. Preserve fixture hashes before/after classification. Copy the verified temp cleanup guard from `Test-RegistryAuthorityNegative.ps1` lines 103-112; never recursively delete an unverified path.

### `release/qualification/phase-07-requirements.json` and `Test-Phase07Qualification.ps1`

**Analogs:** `release/qualification/phase-06-requirements.json` lines 1-77 and `scripts/quality/Test-Phase06Qualification.ps1` lines 46-149.

The ledger should preserve the reciprocal shape:

```json
{
  "schema_version": "1.0.0",
  "phase": "07",
  "required_entrypoint": "pwsh -NoProfile -File scripts/quality.ps1 -Lane Required -EvidenceDirectory <untracked-evidence-directory>",
  "selectors": [],
  "requirements": {},
  "artifact_contracts": [],
  "edge_probes": [],
  "prohibitions": [],
  "evidence": []
}
```

The validator must enforce exact REL-01..REL-05 order, unique selector/artifact/evidence IDs, reverse requirement mapping, same-ID passing edge/prohibition evidence, content-addressed tracked artifacts, and exact declaration ownership. Copy the reciprocal traversal from `Test-Phase06Qualification.ps1` lines 68-118.

Preserve and extend the Required-boundary scan from `Test-Phase06Qualification.ps1` lines 153-163:

```powershell
foreach ($forbiddenPattern in @(
  'Get-Content[^\r\n]*(?:credentials|token|cookie|authorization)',
  'Get-ChildItem[^\r\n]*(?:env:|credentials)',
  'moon\s+(?:login|publish)',
  '(?:gh|git)\s+(?:repo\s+create|push)'
)) {
  if ($requiredSource -cmatch $forbiddenPattern) { throw "Required orchestration crosses a credential or mutation boundary: $forbiddenPattern" }
}
```

Phase 7 Required may inspect the publisher source/workflow statically and execute pure fixture adapters, but must not read `MOONCAKES_TOKEN`, hydrate `$MOON_HOME`, invoke live registry mutation, or configure GitHub settings.

### `.github/workflows/publish-modules.yml`

**Analog:** `.github/workflows/quality.yml` lines 7-26 and 34-44.

Copy the least-privilege and immutable-action baseline:

```yaml
permissions:
  contents: read

steps:
  - name: Check out repository without persisted credentials
    uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
    with:
      persist-credentials: false
  - name: Set up exact MoonBit toolchain
    uses: hustcer/setup-moonbit@bdc8c076af1f4c5012a6ac3451a2009ec75bf921
    with:
      version: 0.1.20260713+75c7e1f
```

Add `workflow_dispatch` inputs for exact ref, source SHA, canonical-initial `root_intent_sha256`, current `intent_sha256`, and prior run/artifact identity; validate actor `tchivs` and repository before the secret-bearing step. Initial dispatch requires root/current equality; corrections retain the initial root while binding their current digest, predecessor, and sequence+1. Use repository plus `root_intent_sha256` for the locked release-wide concurrency identity, with `cancel-in-progress: false` and `queue: max`. Preparation has `contents: read` plus `actions: read`, no environment or secret, and uploads one content-addressed exact-source prepared bundle. Publisher has only `actions: read`, performs no checkout, and revalidates the exact current-run bundle before secret access. Only the single mutation step in the `mooncakes-production` publisher job maps `secrets.MOONCAKES_TOKEN`; create and delete the ephemeral `$MOON_HOME` in that same step's `try/finally`. Pin upload/download artifact actions to the full SHAs recorded in research.

## Shared Patterns

### Determinism and content addressing

**Source:** `ReleaseQualification.Common.ps1` lines 41-52 and 128-203. Apply to intent generation, journal records, ledger artifacts, and Required integration. Use UTF-8 without BOM, `[ordered]` objects, exact arrays, lowercase SHA-256, and recomputation during validation.

### Exact cross-job prepared-bundle handoff

**Sources:** `release/qualification/package-schema.json`, `release/registry/authority-observation-schema.json`, and the SHA-pinned artifact pattern in `.github/workflows/quality.yml`. The prepare job builds a closed canonical manifest whose exact inventory binds every payload by path, role, size, and digest, then names the artifact `mnf-prepared-<root-intent>-<current-intent>-<manifest-sha256>`. The publisher has no checkout or contents permission: it downloads only that job-output name from the exact current run, verifies manifest bytes against the prepare output, rejects inventory extras/substitutions, recomputes every digest and actor/ref/SHA/root/current/journal binding, and only then crosses the Mooncakes credential boundary. `github.token` is confined to pinned official download actions; no third-party `uses:` step receives the Mooncakes credential.

### Closed-world validation

**Source:** `ReleaseQualification.Common.ps1` lines 14-33 and `package-schema.json` lines 5-11. Apply to every policy, schema, intent, journal record, workflow input projection, and report extension. Unknown fields/states are errors, not ignored extensions.

### Exact rule ownership

**Source:** `Test-RegistryAuthorityNegative.ps1` lines 21-28 and `Test-Phase06Qualification.ps1` lines 68-118. Every adversarial case must fail for one expected diagnostic prefix; every requirement maps reciprocally to selector, rule, artifact, and passing evidence.

### Credential and mutation boundary

**Source:** `.github/workflows/quality.yml` lines 7-26 and `Test-Phase06Qualification.ps1` lines 153-163. Required remains credential-free and non-publishing. The workflow maps the Mooncakes token only into one isolated mutation step after all non-secret checks pass.

### Forward-only recovery

**Source:** `policy/registry-authority.json` lines 54-64 and 83-89. Persist only allowlisted sanitized dispositions, reject unsafe evidence strings, re-observe after ambiguity, and never invent destructive recovery semantics.

## No Analog Found

No likely Phase 7 file is wholly without an analog. The pure monotonic reducer and secret-scoped publisher workflow are new combinations, but their component patterns are already established by the shared qualification helpers, fail-closed negative matrices, registry observation schema, and read-only SHA-pinned workflow.

## Metadata

**Analog search scope:** `policy/`, `release/`, `scripts/quality/`, `.github/workflows/`
**Files scanned:** 39 candidate files; 9 analog files read in detail
**Primary analogs:** `policy/release-qualification.json`, `release/qualification/package-schema.json`, `release/registry/authority-observation-schema.json`, `release/qualification/phase-06-requirements.json`, `scripts/quality/ReleaseQualification.Common.ps1`, `scripts/quality/Invoke-ReleaseQualification.ps1`, `scripts/quality/Test-RegistryAuthorityNegative.ps1`, `scripts/quality/Test-Phase06Qualification.ps1`, `.github/workflows/quality.yml`
**Pattern extraction date:** 2026-07-18
