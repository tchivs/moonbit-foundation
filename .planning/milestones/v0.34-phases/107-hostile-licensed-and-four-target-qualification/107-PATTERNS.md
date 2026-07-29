# Phase 107: Hostile, Licensed, and Four-Target Qualification - Pattern Map

**Mapped:** 2026-07-29  
**Files/responsibilities classified:** 30  
**Analogs found:** 27 / 30

## Scope Interpretation

Phase 107 extends the shipped Phase 103 font qualification system. It does not
create a second correctness lane and does not add production runtime behavior.
The exact 85-line public interface, the five `font/moon.pkg` imports, the sole
`tchivs/mb-core@0.1.0` module dependency, and all Phase 104-106 production files
remain compatibility locks.

Three path families are intentionally unresolved until the fail-closed 107-01
intake:

- `fixtures/font/<latin-specimen-id>/...`
- `fixtures/font/<cjk-specimen-id>/...`
- `benchmarks/<cff-benchmark-package>/...`

The planner must freeze exact names only after the Latin and CJK profile,
license, reader, and digest gates pass. The benchmark carrier must also be
chosen without duplicating licensed byte literals or adding an import to the
public `tchivs/mb-font/font` package.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `fixtures/font/cff-qualification-cases.json` | config / canonical corpus | batch / transform | `fixtures/font/collection-qualification-cases.json` | exact role |
| `fixtures/font/<latin-specimen-id>/<latin-static-cff1>.otf` | licensed fixture | file-I/O / batch | `fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf` | role-match |
| `fixtures/font/<latin-specimen-id>/<notice>` | license notice | file-I/O | `fixtures/font/dejavu-sans-2.37/LICENSE` | exact role |
| `fixtures/font/<latin-specimen-id>/<oracle-or-provenance>.json` | config / oracle | batch / transform | `fixtures/font/dejavu-sans-2.37/oracle.json` | role-match |
| `fixtures/font/<cjk-specimen-id>/<cjk-static-cid-cff1>.otf` | licensed fixture / optional derivative | file-I/O / batch | `DejaVuSans-two-face-v1.ttc` lineage | partial |
| `fixtures/font/<cjk-specimen-id>/<notice>` | license notice | file-I/O | `fixtures/font/dejavu-sans-2.37/LICENSE` | exact role |
| `fixtures/font/<cjk-specimen-id>/<oracle-or-provenance>.json` | config / multi-reader oracle | batch / transform | `collection-oracle.json` plus generator reader | role-match |
| `fixtures/manifest.json` | config | file-I/O / batch | current adjacent font records | exact |
| `scripts/fixtures/Generate-FontQualification.ps1` | utility / generator / intake | file-I/O / batch / transform | same file's Phase 100/103 pipeline | exact |
| `modules/mb-font/font/generated_font_qualification_test.mbt` | generated provider / test-private fixture mirror | transform | same file's generated DejaVu and TTC mirror | exact |
| `modules/mb-font/font/font_qualification_test.mbt` | black-box test | request-response | current standalone and collection public qualification | exact |
| `modules/mb-font/font/font_qualification_hostile_test.mbt` | black-box test / dispatcher | request-response | current closed standalone/collection dispatchers | exact |
| `modules/mb-font/font/font_wbtest.mbt` | white-box test | event-driven / request-response | existing admission/fetch/commit mutation hooks | exact seam |
| `modules/mb-font/font/collection_wbtest.mbt` | white-box test | event-driven / request-response | existing selected-face mutation hooks | exact seam |
| `scripts/quality/Invoke-FontQualification.ps1` | service / evidence runner | batch | same file's v2 four-target runner | exact |
| `scripts/quality/Test-FontQualificationEvidenceBoundary.ps1` | integration test | file-I/O | same file's v2 destructive-boundary matrix | exact |
| `scripts/quality/Assert-Policy.ps1` | policy utility | batch / transform | current font fixture, interface, source, workflow gates | exact |
| `policy/foundation.json` | config / allowlist | batch | current `tchivs/mb-font` block | exact |
| `.github/workflows/quality.yml` | workflow config | event-driven / batch | existing `font-qualification` job | exact |
| `modules/mb-font/moon.mod.json` | config | batch | current manifest description | exact |
| `modules/mb-font/README.mbt.md` | public documentation / literate test | request-response / transform | current qualification narrative and examples | exact |
| `modules/mb-font/CHANGELOG.md` | documentation | transform | current unpublished candidate section | exact |
| `docs/policies/licensing-and-fixtures.md` | policy documentation | transform | current external-derivative rules | exact |
| `benchmarks/moon.work` | workspace config | batch | current `ppm` benchmark member list | exact role |
| `benchmarks/<cff-benchmark-package>/moon.mod.json` | benchmark config | batch | `benchmarks/ppm/moon.mod.json` | role-match |
| `benchmarks/<cff-benchmark-package>/moon.pkg` | benchmark config | batch | `benchmarks/ppm/moon.pkg` | role-match |
| `benchmarks/<cff-benchmark-package>/cff_bench.mbt` | benchmark / correctness carrier | batch / transform | `modules/mb-svg/svg/svg_bench.mbt` | role-match |
| `scripts/benchmarks/Invoke-CffNativeBenchmarkBaseline.ps1` | benchmark service / audit | batch / file-I/O | `Invoke-SvgNativeBenchmarkBaseline.ps1` | exact role |
| `scripts/quality/Test-BenchmarkQualification.ps1` | negative policy test | batch / file-I/O | current benchmark negative harness | role-match |
| `docs/benchmarks/mb-font-cff-native-release-baseline.md` | generated evidence documentation | transform | `mb-svg-native-release-baseline.md` | exact role |

## Pattern Assignments

### Canonical corpus and licensed fixture bundle

#### `fixtures/font/cff-qualification-cases.json`

**Analog:** `fixtures/font/collection-qualification-cases.json` and
`scripts/fixtures/Generate-FontQualification.ps1:915-969`

Use a versioned, ordered, closed schema. Validate property order by enumerating
the object keys, not by testing set equality:

```powershell
function Assert-FontQualificationOrderedKeys {
  param($Value, [string[]]$Expected, [string]$Label)
  $actual = if ($Value -is [Collections.IDictionary]) {
    @($Value.Keys)
  } else {
    @($Value.PSObject.Properties.Name)
  }
  if (($actual -join "`0") -cne ($Expected -join "`0")) {
    throw "$Label keys or order drifted."
  }
}
```

The new corpus should keep separate ordered sections for generated public
workflows, hostile groups, mutation windows, static-glyf compatibility, and
benchmark correctness workloads. Freeze exact IDs rather than a package test
count. Expected path commands are ordered values (`MoveTo`, `LineTo`,
`CubicTo`, `Close`), not rendered debug strings.

#### Licensed Latin/CJK binaries, notices, and oracle/provenance JSON

**Composite analogs:**

- `fixtures/font/dejavu-sans-2.37/*`
- `fixtures/manifest.json:124-196`
- `Generate-FontQualification.ps1:42-78`, `492-687`, `1572-1775`
- `docs/policies/licensing-and-fixtures.md:26-37`

Copy exact byte identity enforcement:

```powershell
function Assert-ExactBytesIdentity {
  param([string]$Label, [byte[]]$Bytes, [long]$ExpectedLength,
    [string]$ExpectedSha256)
  if ($Bytes.LongLength -ne $ExpectedLength) {
    throw "$Label length drift: expected $ExpectedLength, got $($Bytes.LongLength)."
  }
  $actualSha256 = Get-FontQualificationSha256 -Bytes $Bytes
  if ($actualSha256 -cne $ExpectedSha256) {
    throw "$Label SHA-256 drift: expected $ExpectedSha256, got $actualSha256."
  }
}
```

Keep every externally sourced or derived payload `origin: external`. Each
selected record must bind the official URL/revision or release, retrieval date,
source length/SHA, derivative recipe and command, generator identity/digest,
derivative length/SHA, author, license expression, retained notice path/digest,
redistribution status, and expected use.

The current closed manifest record order is the direct pattern
(`Generate-FontQualification.ps1:733-778`):

```powershell
$expectedKeys = @(
  'id','path','origin','source','author','retrieval_date','sha256','license',
  'redistribution_status','expected_use'
)
```

Do not force the richer Source-family intake facts into those ten global
manifest fields. Put profile facts, two-reader identities/digests, FDSelect,
used-FD, local-Subrs, high-GID, and derivation details in a separately versioned
closed oracle/provenance document, while the manifest retains its established
schema and links to that artifact.

The current PowerShell SFNT/TTC readers establish the independence boundary:
they parse bytes directly and never invoke `tchivs/mb-font`. For Phase 107,
extend that boundary with two independently pinned semantic readers and OTS
structural acceptance. Reader disagreement or a failed CFF1/name-keyed/CID/
multi-FD/local-Subrs/high-GID gate must stop before committing bytes.

### Generator and portable generated mirror

#### `scripts/fixtures/Generate-FontQualification.ps1`

**Analog sections:**

- paths, pinned identities, SHA helper: lines 1-78;
- stable JSON and manifest contract: lines 699-798;
- ordered-key validation: lines 915-969;
- independent TTC oracle: lines 1572-1775;
- generated MoonBit rendering: lines 2134-2468;
- `-Check` orchestration: lines 2477-2543.

Preserve `[ordered]` objects and LF UTF-8-no-BOM rendering:

```powershell
function ConvertTo-StableJson {
  param($Value)
  return (($Value | ConvertTo-Json -Depth 30).Replace("`r`n", "`n") + "`n")
}
```

Normal mode may write only after all candidate/profile/license/tool identities
validate. `-Check` must reconstruct canonical generated binaries, oracles,
manifest facts, and MoonBit source in memory and byte-compare them without
network access or mutation.

Use the existing final orchestration pattern (`2477-2543`): read canonical
inputs, independently derive oracle facts, update/check fixture artifacts,
update/check the manifest, render/check generated source, then assert the
cross-artifact contract.

#### `generated_font_qualification_test.mbt`

**Analog:** generator lines `2134-2220` and the generated file's existing
DejaVu/TTC provider.

Keep one literal body per licensed payload. Wrapper fonts and collections must
be reconstructed from the one embedded byte representation. Generate closed
types for case facts, expected commands, complete structured errors,
publication flags, and all eight resource dimensions.

The generated header pattern is:

```moonbit
// Generated by scripts/fixtures/Generate-FontQualification.ps1. Do not edit.
// Canonical source: <exact committed fixture path>
// SHA-256: <exact digest>
// Upstream license: <exact expression>
```

Do not hand-edit this file and do not let production MoonBit generate expected
facts for itself.

### Generated name-keyed and CID vectors

**Analogs:**

- `cff_name_keyed_fixture_wbtest.mbt:97-168`
- `cff_cid_fixture_wbtest.mbt:111-211`

The name-keyed builder pattern computes every offset from the assembled parts
before concatenation:

```moonbit
let charstrings_offset = after_global
let private_offset = charstrings_offset + charstrings.length().to_uint64()
let charset_offset = private_offset + private_data.length().to_uint64()
let encoding_offset = charset_offset + charset_data.length().to_uint64()
```

The CID analog constructs two Font DICTs, distinct private ranges, FDArray, and
FDSelect:

```moonbit
let fd_array = cff_key_wb_index([
  cff_cid_wb_font_dict(private_zero_offset, false),
  cff_cid_wb_font_dict(private_one_offset, true),
])
```

Promote only a minimal subset into the canonical offline corpus. Preserve
hand-derived mappings, selected FD/local environment, face-local `hmtx`,
bounds, and exact cubic commands. Existing white-box builders remain diagnostic
sources, not canonical truth.

### Public standalone and selected-collection workflows

#### `font_qualification_test.mbt`

**Analog:** lines `67-159`, `329-535`.

Reuse public-only helpers for metrics, bounds, and ordered commands. Extend the
command helper so `CubicTo` is asserted field-by-field instead of rejected:

```moonbit
match path.get(index) {
  Some(@math.PathCommand::MoveTo(point)) => { /* exact coordinates */ }
  Some(@math.PathCommand::LineTo(point)) => { /* exact coordinates */ }
  Some(@math.PathCommand::CubicTo(control1, control2, endpoint)) => {
    /* exact six coordinates */
  }
  Some(@math.PathCommand::Close) => ()
  _ => fail("qualification path command mismatch")
}
```

For each generated and licensed face, exercise:

1. standalone `Font::open`;
2. caller-owned byte mutation before and after operations;
3. `FontCollection::open` and selected `open_face`;
4. mapping/GID, metrics, kerning, bounds, exact path, error, and budget facts.

The collection analog at `399-535` proves face count/profile/DSIG and calls the
same reusable public-fact helper for each selected face. The Phase 107 shared
CFF collection must deliberately vary face-local cmap/hmtx/kern while sharing
the CFF table so incorrect directory-root authority becomes observable.

### Hostile, resource, precedence, and mutation evidence

#### `font_qualification_hostile_test.mbt`

**Analog:** current closed dispatchers at lines `2-358` and `361-1499`.

Keep a closed ID-to-action dispatcher and exact ID lock. Every failed case must
assert error category, code, operation, payload/context, smallest failing GID
or explicit absence, publication state, and caller/ancestor snapshots.

Use the all-eight comparison from `cff_type2_path_wbtest.mbt:79-92`:

```moonbit
inspect(left.bytes() == right.bytes(), content="true")
inspect(left.allocations() == right.allocations(), content="true")
inspect(left.allocation_size() == right.allocation_size(), content="true")
inspect(left.width() == right.width(), content="true")
inspect(left.height() == right.height(), content="true")
inspect(left.pixels() == right.pixels(), content="true")
inspect(left.depth() == right.depth(), content="true")
inspect(left.work() == right.work(), content="true")
```

Do not copy the older four-dimension helper from
`cff_hostile_fixture_wbtest.mbt:2-25` unchanged; Phase 107 explicitly requires
all eight dimensions and both caller and ancestor before/after states.

#### White-box hook files

**Analogs:**

- `cff_hostile_fixture_wbtest.mbt:326-442` for caller authority and
  State → Resource → Capability → Data precedence;
- `cff_type2_path_wbtest.mbt:350-435` for preflight preventing VM/staging;
- `cff_type2_path_wbtest.mbt:508-549` for mid-fetch mutation;
- existing `font_wbtest.mbt` and `collection_wbtest.mbt` hooks for admission,
  selected-face, fetch, staged-path, and final-commit windows.

Use deterministic mutate-and-restore callbacks. Assert the callback count,
`State` error identity, no partial `Font`/face/retained facts/`Path2`, and
unchanged caller and ancestor budgets. Do not add threads, sleeps, or
target-specific scheduling. Modify these files only if an existing hook cannot
express a locked Phase 107 window.

### v3 four-target evidence

#### `scripts/quality/Invoke-FontQualification.ps1`

**Analog sections:**

- target order, identities, record keys, focused assertions: lines `1-100`;
- managed path, marker, known-file cleanup: lines `346-464`;
- closed record validation: lines `601-838`;
- semantic projection/comparison: lines `1349-1490`;
- isolated target execution and negative probes: lines `1581-1906`.

Advance the existing identities to a fresh v3 owner. Keep:

```powershell
$Targets = @('js', 'wasm', 'wasm-gc', 'native')
```

The top-level v3 keys should be frozen only after 107-01 and 107-02 hand off
their exact identities. The research-proposed order is:

```powershell
$RecordKeys = @(
  'schema_version','workflow_id','target','toolchain','fixtures',
  'oracle_facts','generated_cff_facts','licensed_cff_facts',
  'public_workflow_facts','cff_hostile_outcomes',
  'mutation_atomicity_facts','glyf_compatibility_facts',
  'benchmark_correctness_facts','boundary_facts','dependency_facts',
  'focused_assertions','runner','pass'
)
```

Normalize only top-level `target` and `runner`. Prefer deriving the semantic
payload from `$RecordKeys` so future fields cannot be silently omitted:

```powershell
$semantic = [ordered]@{}
foreach ($key in $RecordKeys) {
  if ($key -cnotin @('target', 'runner')) {
    $semantic[$key] = $record.$key
  }
}
```

Retain the current comparison gates: exactly four unique records in exact
order, closed validation before write and after read-back, one canonical
semantic payload, record hashes, one semantic hash, and `equal: true`.

Each target uses a fresh isolated target directory, runs every named focused
assertion with exactly one pass, and runs the discovered full package without
freezing a total-test constant.

#### `Test-FontQualificationEvidenceBoundary.ps1`

**Analog:** entire file, especially lines `5-34`, `62-143`, and `145-220`.

Keep the import-only runner seam and the outside/root/unowned/owned/corrupt
marker/link/write-swap probes. A v2 marker must not authorize v3 cleanup:

```powershell
Write-FontQualificationJson -Path $markerPath -Value ([ordered]@{
  schema = 'mnf-font-qualification-evidence/v2'
  workflow_id = 'font-complete-public-v2'
})
Assert-Rejected {
  Clear-FontQualificationEvidenceFiles -Directory $owned -ManagedRoot $managedRoot
} 'marker is invalid'
```

Cleanup remains known-file-only: four target JSON files and
`comparison.json`. Never recursively delete the caller-supplied evidence path.

### Policy, CI, and documentation

#### `scripts/quality/Assert-Policy.ps1` and `policy/foundation.json`

**Analog sections:**

- independent 85-line classifier: `Assert-Policy.ps1:981-1093`;
- exact fixture records/order: `1095-1200`;
- workflow schema: `1807-2007`;
- qualification inventory/API/dependency gates: `2944-3010`;
- generated source and portable boundary: `3328-3385`;
- module/source/import/docs gates: `3491-3645`;
- current policy module block: `foundation.json:2181-2350`.

Refresh stale Phase 103 source/test/publication inventories to the live Phase
106 CFF files plus Phase 107 test additions. Preserve:

```powershell
$imports = @(
  'tchivs/mb-core/budget',
  'tchivs/mb-core/bytes',
  'tchivs/mb-core/checked',
  'tchivs/mb-core/error',
  'tchivs/mb-core/math'
)
```

Keep the independent hard-coded 85-line interface classifier; do not trust a
coordinated change to `foundation.json`. Add exact gates and negative probes for
fixture/oracle/tool drift, generated and licensed GID/FD/cubic drift, hostile
error/budget/publication drift, static-glyf drift, source/dependency/import/API
expansion, v3 path/marker/workflow drift, target-root contamination, and
toolchain substitution.

#### `.github/workflows/quality.yml`

**Analog:** lines `11-34`.

Keep the single existing `font-qualification` job, pinned checkout/toolchain
installer, success-only pinned upload, and measured timeout. Change the runner
and upload paths together to the fresh v3 directory and artifact identity.
Increase the 20-minute timeout only if final measured lane duration requires it.

#### Module manifest and documentation

**Analogs:**

- `modules/mb-font/moon.mod.json:1-13`
- `modules/mb-font/README.mbt.md`
- `modules/mb-font/CHANGELOG.md:7-91`
- `docs/policies/licensing-and-fixtures.md:14-47`

Update only the module description/narrative to acknowledge qualified static
CFF1. Keep name, version, candidate stability, license, four targets, preferred
target, readme, and sole dependency unchanged. Documentation must not claim
CFF2, shaping, hint execution, rasterization, thresholds, performance
superiority, publication, or stability promotion.

### CFF benchmark correctness and native observation baseline

#### Benchmark MoonBit carrier and package config

**Composite analogs:**

- `modules/mb-svg/svg/svg_bench.mbt:1-12`, `89-198`
- `benchmarks/ppm/moon.mod.json:1-12`
- `benchmarks/ppm/moon.pkg:1-13`
- `benchmarks/moon.work:1-6`

Use named benchmark tests with correctness assertions outside the measured
closure:

```moonbit
test "bench <immutable-workload-id>" (b : @bench.T) {
  let fixture = <reconstruct frozen bytes>()
  require_benchmark(<closed correctness facts>, "<fact id>")
  b.bench(fn() { b.keep(<public operation>) })
}
```

Mandatory order: Latin full admission, CJK full admission, fixed Latin outline
batch, fixed non-empty high-GID multi-FD CJK outline batch. Freeze fixture,
workload, and correctness digests.

The exact carrier path has no direct repository precedent satisfying all Phase
107 constraints. A dedicated benchmark package is the closest safe shape
because adding `moonbitlang/core/bench` to `modules/mb-font/font/moon.pkg`
would break the five-import lock. The chosen package must still avoid a second
licensed literal body; resolve this ownership explicitly in 107-01 before
creating package files.

#### `Invoke-CffNativeBenchmarkBaseline.ps1`

**Analog:** `scripts/benchmarks/Invoke-SvgNativeBenchmarkBaseline.ps1`.

Copy:

- clean-worktree gate at lines `54-60`;
- exact command/workload list at lines `12-18`;
- frozen corpus/correctness SHA checks at lines `62-102`;
- host/toolchain identity at lines `104-166`;
- output parsing at lines `178-225`;
- seven-sample statistics at lines `227-242`;
- canonical document plus embedded audit data at lines `264-364`;
- read-only reconstruction at lines `478-524`;
- one excluded warmup plus seven captures at lines `532-568`.

The aggregate is exact:

```powershell
if ($Samples.Count -ne 7) {
  throw 'A native evidence aggregate requires exactly seven retained samples.'
}
$stddev = [Math]::Sqrt($sumSquares / ($Samples.Count - 1))
```

Record mean, median, sample standard deviation, minimum, maximum, and
coefficient of variation. The audit reads committed evidence and current fixed
inputs only; it does not execute MoonBit, rewrite the document, compare
backends, or issue a regression verdict.

#### `Test-BenchmarkQualification.ps1`

**Analog:** current 90-line script.

Extend its positive reconstruction and one-fact-at-a-time negatives for the CFF
baseline: extra claim, workload reorder, missing host fact, fixture/workload/
correctness digest drift, capture count drift, altered statistics, or a
threshold/ranking/regression field.

## Shared Patterns

### Closed ordered schemas

**Sources:** generator `915-969`, runner `601-838`, policy `1095-1200`.

Use explicit expected key arrays, explicit ordered IDs, `[ordered]` PowerShell
objects, and LF UTF-8-no-BOM serialization. Missing, extra, duplicate, or
reordered keys and cases fail closed.

### Independent oracle boundary

**Sources:** generator `492-687`, `1572-1775`.

Host tools certify committed facts before target runs. Production MoonBit and
target test output never certify their own fixture expectations. OTS is
structural evidence only; semantic readers must agree on the closed projection.

### Atomic failure evidence

**Sources:** `cff_hostile_fixture_wbtest.mbt:2-75`,
`cff_type2_path_wbtest.mbt:79-105`, `290-435`.

Failures publish nothing and charge no uncommitted transaction. Snapshot all
eight dimensions for caller and ancestor. Preserve State → Resource →
Capability → Data precedence and the smallest failing GID.

### Managed evidence ownership

**Sources:** runner `346-464`, boundary test `62-220`.

Evidence paths are strict children of the managed root, contain no
link/reparse-point component, carry an exact versioned marker, and remove only
known evidence filenames.

### Compatibility locks

**Sources:** policy `981-1093`, `2944-3010`, `3491-3582`.

The policy JSON, independent classifier, generated interface, module manifest,
package imports, dependency graph, target set, directory inventory, fixture
manifest, workflow, and negative probes must all agree. The static-glyf
fingerprint is semantic; do not freeze an aggregate test total.

## Strict Plan Dependencies and Conflict-Safe Ownership

| Slice | Exclusive file ownership | Required handoff |
|---|---|---|
| **107-01 Fixtures/oracles/provenance** | new corpus and licensed fixture bundles, `fixtures/manifest.json`, generator, generated MoonBit mirror, and only fixture-specific policy gates | Freeze exact paths, licenses, notices, recipes, tools, schemas, IDs, GIDs/FDs, workloads, hashes, generated symbols, and single-payload ownership before Slice 2. |
| **107-02 Public/hostile/glyf facts** | public/hostile qualification tests and only necessary white-box hook tests | Freeze exact focused file/test identities, ordered hostile groups, complete error/publication/budget schemas, mutation windows, and static-glyf fingerprint before Slice 3. |
| **107-03 v3/policy/CI/docs/baseline** | runner, boundary test, remaining policy gates, policy JSON, workflow, module docs/description, benchmark package/script/test/document | Consume 107-01/02 identities verbatim. Do not regenerate fixtures, rename assertions, or reopen production runtime behavior. |

`Assert-Policy.ps1` is the expected shared file: Slice 1 owns only the
fixture/manifest/generated-source contract; Slice 3 owns the final source/API/
workflow/docs/baseline gates after prior identities are frozen.

## No Analog Found

| File / Responsibility | Role | Data Flow | Reason |
|---|---|---|---|
| Two independently pinned CFF semantic reader adapters | utility / oracle | file-I/O / transform | Existing PowerShell readers are independent of `mb-font` but are one in-repository implementation; no current two-reader executable/package identity and agreement bridge exists. |
| Exact Source Han multi-FD derivative recipe | fixture generator | file-I/O / batch | DejaVu provides lineage mechanics, but no current fixture proves CID keying, multiple used FDs, FDSelect coverage, distinct local Subrs, and a fixed high GID. |
| Single-payload portable benchmark carrier | benchmark provider | batch / transform | Existing benchmark packages do not share a large generated test-private licensed payload across four-target correctness and native timing while preserving the font package's five-import lock. |

## Metadata

**Graph discovery:** `codebase-memory-mcp` project `moonbit-foundation`;
`search_graph("font qualification fixture evidence benchmark")` returned zero
nodes. This confirms the known MoonBit/PowerShell indexing gap, so discovery
used the AGENTS.md-approved source fallback.  
**Source search scope:** `fixtures/font`, `scripts/fixtures`, `scripts/quality`,
`scripts/benchmarks`, `modules/mb-font`, `benchmarks`, `policy`,
`.github/workflows`, `docs/benchmarks`, `docs/policies`, and archived Phase 103
planning artifacts.  
**Files scanned:** 112  
**Strong analog families:** Phase 103 fixture generator, Phase 103 public/
hostile tests, Phase 103 v2 runner/boundary, font policy/CI/docs gates, and
Phase 94 native baseline/audit.  
**Pattern extraction date:** 2026-07-29
