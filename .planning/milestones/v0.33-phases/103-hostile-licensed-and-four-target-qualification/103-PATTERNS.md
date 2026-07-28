# Phase 103: Hostile, Licensed, and Four-Target Qualification - Pattern Map

**Mapped:** 2026-07-28  
**Branch:** `codex/v0.33-ttc-adapters`  
**Files/responsibilities classified:** 18  
**Analogs found:** 18 / 18

## Scope Interpretation

Phase 103 should extend the Phase 100 qualification system, not create another lane or
change runtime behavior. The recommended concrete new fixture paths are:

- `fixtures/font/collection-qualification-cases.json`
- `fixtures/font/dejavu-sans-2.37/DejaVuSans-two-face.ttc`
- `fixtures/font/dejavu-sans-2.37/collection-oracle.json`

The first path is project-authored Apache-2.0 data. The TTC, its oracle lineage, and
the notice are externally derived DejaVu evidence and must retain
`Bitstream-Vera AND LicenseRef-DejaVu-Arev`, confirmed redistribution, the immutable
upstream source, the derivative generator identity, and separate digests.

No new production `.mbt` file is indicated. The exact 85-line public interface,
production source order, package imports, module dependency edge, and publication
policy remain unchanged. Qualification additions belong in existing generated/test,
runner, policy, CI, and documentation files.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `fixtures/font/collection-qualification-cases.json` | config / fixture corpus | batch transform | `fixtures/font/qualification-cases.json` | exact |
| `fixtures/font/dejavu-sans-2.37/DejaVuSans-two-face.ttc` | fixture | file-I/O / batch | `DejaVuSans.ttf` plus `font_collection_test_shared_selected_ttc()` | composite exact |
| `fixtures/font/dejavu-sans-2.37/collection-oracle.json` | config / oracle | batch transform | `fixtures/font/dejavu-sans-2.37/oracle.json` | exact role |
| `fixtures/manifest.json` | config | file-I/O / batch | existing three font records at lines 124-158 | exact |
| `scripts/fixtures/Generate-FontQualification.ps1` | utility / generator | file-I/O / batch / transform | same file's Phase 100 intake, oracle, manifest, and generated-source functions | exact |
| `modules/mb-font/font/generated_font_qualification_test.mbt` | provider / generated fixture mirror | transform | same file plus `font_collection_test_shared_selected_ttc()` | exact |
| `modules/mb-font/font/font_qualification_test.mbt` | black-box test | request-response | current compact/DejaVu public workflows | exact |
| `modules/mb-font/font/font_qualification_hostile_test.mbt` | black-box test | request-response | current closed hostile dispatcher | exact |
| `modules/mb-font/font/collection_wbtest.mbt` | white-box test | event-driven / request-response | current `open_after_normalize` and `open_face_after_admit` hooks | exact |
| `scripts/quality/Invoke-FontQualification.ps1` | service / evidence runner | batch | same file's v1 runner | exact |
| `scripts/quality/Test-FontQualificationEvidenceBoundary.ps1` | test | file-I/O | same file's managed-directory negative matrix | exact |
| `scripts/quality/Assert-Policy.ps1` | policy utility | batch | `Assert-FontQualificationArtifacts`, `Assert-FontPhase102Surface`, source and workflow gates | exact |
| `policy/foundation.json` | config | batch | current `tchivs/mb-font` module block | exact |
| `.github/workflows/quality.yml` | workflow config | event-driven / batch | existing `font-qualification` job | exact |
| `modules/mb-font/moon.mod.json` | config | batch | current manifest description synchronized by policy | exact |
| `docs/policies/licensing-and-fixtures.md` | policy documentation | transform | current fixture provenance/external-content rules | exact |
| `modules/mb-font/README.mbt.md` | public documentation / literate test | request-response / transform | current `mbt check` examples and qualification contract | exact |
| `modules/mb-font/CHANGELOG.md` | documentation | transform | current unpublished `0.1.0 candidate` Added/Fixed sections | exact |

## Pattern Assignments

### 1. Canonical collection corpus

#### `fixtures/font/collection-qualification-cases.json`

**Analog:** `fixtures/font/qualification-cases.json:1-116`

Copy the ordered, closed document shape:

```json
{
  "schema_version": "1.0.0",
  "license": "Apache-2.0",
  "cases": [
    {
      "id": "malformed-directory-range",
      "stage": "open",
      "category": "Data",
      "code": "InvalidEncoding",
      "context": "font-table-range",
      "requested": null,
      "limit": null,
      "publication": "none"
    }
  ]
}
```

**Required adaptation:**

- Use a new collection-specific schema identity and a separate ordered ID list. Never
  edit or regenerate `qualification-cases.json`; its 11 IDs and digest are the v0.32
  baseline.
- Freeze complete structured errors, not rendered prose. The collection record should
  order fields as:
  `id`, `stage`, `category`, `code`, `operation`, `context`, `source_offset`,
  `requested`, `limit`, `publication`, `budget_before`, `budget_after`.
- Both budget objects must use the exact eight-field order:
  `bytes`, `allocations`, `allocation_size`, `width`, `height`, `pixels`, `depth`,
  `work`.
- Keep all TTC-04 groups explicit and ordered: header/version/count/offset array,
  face directory/table range, DSIG tuple/body, overlap/duplicate, invalid index,
  CFF/CFF2/variable selection, checked range/arithmetic, every semantic ceiling,
  caller budget, ancestor budget, pre/post/mid-operation mutation.
- Use explicit success records for exact boundaries and error records for one-short
  boundaries. Do not infer one from the other in target tests.

**Anti-patterns:** one giant aggregate case, target-specific expectations, optional
budget dimensions, rendered error-message snapshots, or merging these records into the
Phase 100 corpus.

#### `DejaVuSans-two-face.ttc`

**Composite analogs:**

- `fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf`
- `modules/mb-font/font/collection_test.mbt:593-639`

The closest collection constructor copies two directories and points both at one
payload base:

```moonbit
fn font_collection_test_shared_selected_ttc() -> Bytes {
  let standalone = font_test_minimal_truetype()
  let payload_base = 768UL
  let output = Array::make(payload_base.to_int() + standalone.length(), b'\x00')
  font_collection_test_put_u32(output, 0, 0x74746366UL)
  font_collection_test_put_u32(output, 4, 0x00010000UL)
  font_collection_test_put_u32(output, 8, 2UL)
  font_collection_test_put_u32(output, 12, 256UL)
  font_collection_test_put_u32(output, 16, 512UL)
  font_collection_test_copy_selected_directory(output, standalone, 256, payload_base)
  font_collection_test_copy_selected_directory(output, standalone, 512, payload_base)
  for index, byte in standalone {
    output[payload_base.to_int() + index] = byte
  }
  Bytes::from_array(output)
}
```

**Required adaptation:**

- Implement the equivalent algorithm independently in PowerShell over the exact
  committed DejaVu TTF.
- Emit TTC v1, count 2, two separate SFNT directories, and one exact shared set of
  root-relative table ranges. Recompute each directory's offsets from collection byte
  zero; do not rebase from the directory.
- Build in memory, validate both directories and every shared record, then write the
  canonical TTC. The output digest becomes immutable input to generation, policy, and
  v2 evidence.
- Treat the bytes as an external derivative. `origin` is `external`, not `generated`;
  the `source` field should name both the immutable upstream archive and
  `scripts/fixtures/Generate-FontQualification.ps1` as derivative generator.

**Anti-patterns:** two copies of every DejaVu table, a one-face wrapper, directory-
relative offsets, using `FontCollection` to certify the derivative, or Apache-2.0
relabeling.

#### `collection-oracle.json`

**Analog:** `oracle.json:1-199` and
`Generate-FontQualification.ps1:483-687`

The Phase 100 reader establishes the independent-oracle pattern:

```powershell
function Read-FontQualificationSfntOracle {
  param([Parameter(Mandatory)][byte[]]$Bytes)
  Assert-ExactBytesIdentity 'DejaVuSans.ttf' $Bytes $FontLength $FontSha256
  $signature = Read-U32BE $Bytes 0
  $tableCount = [int](Read-U16BE $Bytes 4)
  if ($signature -ne 0x00010000UL -or $tableCount -ne 20) {
    throw 'Oracle SFNT profile or table count drift.'
  }
  # Parse every record independently and emit an [ordered] schema.
}
```

**Required adaptation:**

- Add a separately named closed TTC reader, for example
  `Read-FontQualificationCollectionOracle`; do not make the SFNT reader accept both
  formats.
- Freeze ordered identity/lineage, TTC signature/version/count, directory coordinates,
  each directory's records, exact cross-face sharing groups, table checksums, derivative
  length/SHA-256, and both expected face profiles.
- Bind selected semantic facts to the existing `oracle.json` identity/digest rather
  than copying parser output into the new oracle.
- Recompute the oracle on every normal/check invocation and byte-compare stable LF,
  UTF-8-no-BOM JSON, following `ConvertTo-StableJson` at lines 690-693 and
  `Test-FontQualificationInputs` at lines 1286-1304.

**Anti-patterns:** invoking MoonBit/`mb-font`, embedding target output, modifying
`oracle.json`, or allowing unknown/reordered keys.

#### Existing `LICENSE` notice

**Analog:** `fixtures/font/dejavu-sans-2.37/LICENSE` and manifest record
`fixtures/manifest.json:136-145`.

Preserve the exact existing 8,816-byte upstream license/notice bytes and SHA-256
`7a083b136e64d064794c3419751e5c7dd10d2f64c108fe5ba161eae5e5958a93`.
Reference the existing `LICENSE` from derivative lineage; do not add, rename, or copy a
second notice because the Phase 100 manifest identity must remain intact.

**Anti-pattern:** rewriting or summarizing upstream terms in a project-authored notice.

#### `fixtures/manifest.json`

**Analog:** current adjacent DejaVu records and final generated case record at
lines 124-158; generator enforcement at
`Generate-FontQualification.ps1:695-786` and `906-958`.

Reuse exact ordered keys:

```powershell
$expectedKeys = @(
  'id','path','origin','source','author','retrieval_date','sha256','license',
  'redistribution_status','expected_use'
)
```

Append a canonical Phase 103 block after the unchanged Phase 100 records. The
recommended order is collection cases, TTC derivative, collection oracle, notice.
The generator must reject partial, duplicate, or reordered blocks and exact-field
drift, as `Update-OrCheckManifest` currently does.

**Anti-patterns:** reordering the first 11 records, updating the standalone font/case
digests, adding derivative-only metadata by changing the global manifest schema, or
marking the TTC as `not-applicable` redistribution.

#### `scripts/fixtures/Generate-FontQualification.ps1`

**Closest analog sections:**

- constants and exact byte identity: lines 1-66;
- independent SFNT oracle: lines 483-687;
- stable JSON, provenance, and fail-closed intake: lines 690-845;
- closed case validation/manifest drift: lines 847-958;
- generated source and literal round trip: lines 1075-1284;
- normal versus `-Check` orchestration: lines 1286-1333.

The generated-output pattern is:

```powershell
$rendered = ($rows -join "`n")
$renderedBytes = $Utf8NoBom.GetBytes($rendered)
if ($CheckOnly) {
  $actualBytes = [IO.File]::ReadAllBytes($GeneratedSourcePath)
  if (-not [Linq.Enumerable]::SequenceEqual(
      [byte[]]$renderedBytes,
      [byte[]]$actualBytes
    )) {
    throw "Generated font qualification source drifted: $GeneratedSourcePath"
  }
  return
}
[IO.File]::WriteAllBytes($GeneratedSourcePath, $renderedBytes)
```

**Required adaptation:**

- Keep `-Intake` and `-Check` semantics and the Phase 100 SFNT constants intact.
- Add exact paths/constants for the four new artifacts and a TTC derivative builder,
  closed TTC oracle reader, collection case validator, and adjacent manifest block.
- Normal mode deterministically regenerates TTC, collection oracle, manifest digests,
  and MoonBit mirror. `-Check` reconstructs all of them in memory and rejects any byte
  drift; it does not rewrite.
- Extend, do not replace, the generated MoonBit source. Preserve the first five Phase
  100 provenance lines and append a collection provenance block.

**Anti-patterns:** network access outside explicit `-Intake`, repository writes before
all identities validate, using `ConvertTo-Json` without LF normalization, or sharing
parsing code with production MoonBit.

#### `generated_font_qualification_test.mbt`

**Analogs:** generated header/types/accessors at lines 1-50 and
`Generate-FontQualification.ps1:1075-1265`.

Keep the existing DejaVu chunks and `font_qualification_dejavu_sans_237_bytes()`
unchanged. Render:

- a closed `FontCollectionQualificationCase` type including all structured error and
  eight-dimension budget fields;
- `font_qualification_cases()` delegates to `font_collection_qualification_cases()` in the canonical JSON order;
- `font_qualification_dejavu_two_face_ttc_bytes()` built from the existing standalone
  accessor plus a small generated header/directory transformation.

The collection accessor must reproduce the canonical TTC byte-for-byte and digest-check
in PowerShell generation. Do not emit another 757,076-byte literal copy. The existing
pattern already reconstructs one canonical binary from bounded chunks and verifies
round-trip identity at generator lines 1161-1193.

### 2. Public, hostile, mutation, and standalone locks

#### `font_qualification_test.mbt`

**Analog:** lines 161-332.

Preserve these existing test names and facts:

- `font-complete-public freezes compact public workflow facts`
- `font-complete-public exercises the compact format-4 branch`
- `font-complete-public freezes DejaVu Sans 2.37 public facts`

Extract the DejaVu assertions at lines 243-332 into a reusable black-box helper without
changing the named test's semantic content. Add a distinct focused collection test
which:

1. constructs caller-owned bytes from the generated TTC;
2. opens `FontCollection` with explicit collection limits/budget;
3. proves version/count/face profiles/DSIG status;
4. selects face 0 and face 1 independently;
5. applies the same DejaVu public-fact helper to both selected `Font` values;
6. proves the standalone named test still passes unchanged.

Copy assertion style from the current helpers:

```moonbit
fn font_qualification_assert_bounds(...) -> Unit raise {
  inspect(bounds.x_min() == x_min, content="true")
  inspect(bounds.y_min() == y_min, content="true")
  inspect(bounds.x_max() == x_max, content="true")
  inspect(bounds.y_max() == y_max, content="true")
}
```

**Anti-patterns:** comparing debug strings, exposing raw records/offsets through public
assertions, renaming old test identities, freezing a package-wide test count, or
weakening the DejaVu standalone oracle.

#### `font_qualification_hostile_test.mbt`

**Analogs:**

- exact category/code/context/requested/limit dispatcher: lines 2-63;
- publication-aware closed dispatcher: lines 138-325;
- ordered ID lock: lines 329-358;
- all-eight budget snapshot helper:
  `collection_test.mbt:345-358`.

Use the collection helper's complete equality pattern:

```moonbit
let after = budget.remaining()
inspect(after.bytes() == before.bytes(), content="true")
inspect(after.allocations() == before.allocations(), content="true")
inspect(after.allocation_size() == before.allocation_size(), content="true")
inspect(after.width() == before.width(), content="true")
inspect(after.height() == before.height(), content="true")
inspect(after.pixels() == before.pixels(), content="true")
inspect(after.depth() == before.depth(), content="true")
inspect(after.work() == before.work(), content="true")
```

Keep the 11-case standalone dispatcher and exact test identity unchanged. Add a second
collection-specific dispatcher and focused test identity. Each case must assert
operation, context, optional source offset, requested, limit, publication state, and
the complete before/after budget objects. Successful exact-fit cases should assert the
published object and exact charge; failures must assert no publication and exact
before/after equality.

Copy error precedence from `collection_test.mbt:939-1033`: revision before index after
mutation, index before cached profile on stable input, and profile rejection before
any selected-face charge.

Copy caller/ancestor failure patterns from `collection_test.mbt:1282-1564`: one-short
bytes/allocations/allocation-size/work, short semantic `max_work`, short source limit,
and both parent and child unchanged when an ancestor is depleted.

**Anti-patterns:** checking only bytes/work/allocations as the Phase 100 hostile test
does at lines 248-260, collapsing operation/context, or treating CFF/CFF2/variable as
malformed instead of `CapabilityUnavailable`.

#### `collection_wbtest.mbt`

**Analog:** deterministic private hooks at lines 299-551 and 993-1034.

For mid-collection-open mutation, use:

```moonbit
let result = FontCollection::open_after_normalize(
  owner.view(),
  limits,
  budget,
  fn() { font_collection_wb_mutate_restore(owner, offset) },
)
```

For mid-selection/final publication mutation, use:

```moonbit
let error = collection.open_face_after_admit(
  0UL,
  font_limits,
  budget,
  fn() { font_collection_wb_mutate_restore(owner, offset) },
).unwrap_err()
```

The existing final-hook test at lines 299-362 is the strongest exact pattern: callback
count 1, `State/InvalidRange`, exact operation/context, no source/request/limit fields,
no `Font`, and all eight budget dimensions unchanged.

Add one focused white-box qualification test that exercises the otherwise
unobservable mid-open and mid-selection windows. Keep pre/post-publication mutation in
black-box tests. Do not add threads or target-specific scheduling.

**Anti-patterns:** new production hooks, exposing a hook publicly, nondeterministic
races, or duplicating all public hostile cases in white-box form.

### 3. v2 evidence, policy, CI, and documentation

#### `Invoke-FontQualification.ps1`

**Analog:** the complete existing v1 runner.

Reuse:

- strict mode, fixed target order, and closed top-level keys: lines 1-48;
- canonical LF JSON and file facts: lines 50-92;
- contained, link-free managed paths and ownership marker: lines 94-259;
- recursive closed-key validation: lines 261-374;
- dependency facts: lines 584-617;
- evidence construction: lines 620-657;
- four-target semantic comparison: lines 659-715;
- per-target check, focused assertions, full package, read-back, negative probes, and
  README checks: lines 736-899.

Use a fresh default directory such as
`artifacts/release-qualification/font-v2`, marker schema
`mnf-font-qualification-evidence/v2`, workflow ID
`font-complete-public-v2`, and schema version `2.0.0`. Do not reuse or delete the v1
directory.

Recommended exact ordered v2 record keys:

```powershell
$RecordKeys = @(
  'schema_version',
  'workflow_id',
  'target',
  'toolchain',
  'fixtures',
  'standalone_baseline',
  'generated_collection_facts',
  'licensed_derivative_facts',
  'collection_hostile_outcomes',
  'mutation_atomicity_facts',
  'boundary_dependency_facts',
  'focused_assertions',
  'runner',
  'pass'
)
```

`standalone_baseline` should retain the current compact/DejaVu public facts, all 11
hostile outcomes, the three existing focused assertion names, and the exact `Font`
interface subsequence. `focused_assertions` must hold target-neutral file/name
identities; target-specific command strings belong only in `runner`.

Run, in exact target order, independent:

- module check;
- unchanged standalone compact/DejaVu focused assertions;
- generated/licensed collection public assertion;
- collection hostile assertion;
- private mutation/atomicity assertion;
- full `font` package.

Do not use an aggregate test-count constant for the full package. Continue requiring
exact `1 passed` output for each focused identity.

The current semantic projection at lines 674-686 explicitly copies every field except
`target` and `runner`. For v2, make this invariant mechanically closed: clone each
record, remove exactly those two properties, assert the remaining key order equals
`$RecordKeys` minus those names, then canonicalize. This prevents a newly added field
from being accidentally omitted from comparison.

Keep both negative probes at lines 876-887 and add negatives for reordered targets,
missing nested keys, extra nested keys, fixture digest drift, hostile/budget drift,
focused identity drift, and divergence in every new semantic section.

**Anti-patterns:** a second quality lane, normalization of toolchain/fixture/pass data,
writing evidence before all focused/full tests pass, deleting v1 evidence, or allowing
records with extra keys.

#### `Test-FontQualificationEvidenceBoundary.ps1`

**Analog:** lines 1-143.

Retain the import-only runner seam, temp-root prefix, outside/root/unowned/owned/corrupt
marker/link probes, known-file-only cleanup, unrelated-file preservation, and guarded
recursive temp cleanup.

Adapt expected marker schema/workflow to v2 and use v2 target filenames. Add a negative
that a valid v1 marker cannot authorize v2 cleanup and verify the v1 directory remains
byte-unchanged.

**Anti-pattern:** broad recursive deletion or accepting the managed root itself
(`Resolve-FontQualificationEvidencePath` correctly requires a child at runner
lines 150-178).

#### `Assert-Policy.ps1`

**Closest analog sections:**

- exact 85-line independent classifier: lines 981-1093 and 2421-2425;
- exact fixture records/order: lines 1095-1165;
- executable-source lexer boundary: lines 1429-1460;
- exact workflow-step mapping pattern: lines 1617-1665;
- fixture/oracle/case/generated-source gates: lines 2371-2522;
- interface/dependency/inventory/document gates and negatives: lines 2619-2864.

Required adaptations:

- Rename the classifier label to Phase 103 while leaving the approved 85 lines
  byte-identical. Preserve missing/duplicate/reordered and forbidden-line negatives.
- Extend the exact fixture ID sequence and exact expected records for the four Phase
  103 artifacts.
- Assert the new collection oracle's exact ordered schemas, identity, lineage, TTC
  version/count, two directories, exact record equality, exact shared ranges, profile
  facts, derivative digest, and binding to the standalone oracle digest.
- Assert collection corpus schema, ordered IDs, closed error keys, and exact eight-key
  before/after budget objects.
- Extend generated-source header/symbol checks without replacing the existing DejaVu
  header checks.
- Preserve exact dependency/import/target/source inventories. Because no new `.mbt`
  file is proposed, the production/test/publication file lists should not change.
- Extend `Assert-FontPortableSourceBoundary` with executable WOFF/WOFF2 decode/admission
  probes. Use the existing lexer, which strips comments and non-interpolated strings;
  documentation words alone must not fail the gate.
- Add exact `font-qualification` run/upload step mapping checks modeled on the Required
  step checks at lines 1617-1665. Pin the v2 directory and success-only upload.
- Add negatives for TTC fixture/oracle digest drift, licensed artifact relabeling,
  missing retained license digest/reference, WOFF execution/import, CFF/CFF2/variable selection execution, changed
  interface line, dependency edge, target set, runner directory, upload condition,
  normalization set, and timeout drift.

**Anti-patterns:** trusting `foundation.json` alone to define the interface, regexing
raw source without the existing lexer, permitting a coordinated policy/runtime API
change, or weakening old Phase 100 assertions when adding collection assertions.

#### `policy/foundation.json`

**Analog:** lines 2181-2355.

Change only the synchronized module description so it names bounded standalone
TrueType plus TTC/OTC v1/v2 inspection and static-`glyf` face selection. Retain:

- candidate stability;
- four targets;
- sole direct dependency `tchivs/mb-core`;
- publication files;
- production/test source order;
- allowed imports;
- exact 85 semantic interface lines.

The policy script already enforces those values independently at
`Assert-Policy.ps1:2619-2702`.

**Anti-patterns:** adding fixture/evidence files to the module publication inventory,
changing release/publication policy, or adding a semantic-interface line for
qualification.

#### `.github/workflows/quality.yml`

**Analog:** lines 11-32.

Keep the existing job, checkout, pinned toolchain install, and 20-minute timeout unless
the measured final complete run exceeds it. Change the runner and upload paths together
to the fresh v2 directory, for example:

```yaml
- name: Run focused font qualification
  shell: pwsh
  run: ./scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/ci-font-v2
- name: Upload passing font qualification evidence
  if: ${{ success() }}
  uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02
  with:
    name: font-qualification-evidence-v2
    path: artifacts/release-qualification/ci-font-v2
```

`scripts/quality.ps1:16-19` already routes `FontQualification` to the existing runner;
no selector change is required.

**Anti-patterns:** a second collection job/lane, `always()` for passing evidence,
sharing the Required diagnostic path/name, mutable action tags, or increasing timeout
without a measured need.

#### `modules/mb-font/moon.mod.json`

**Analog:** lines 1-13.

Update only `description`; keep name/version/license/readme/preferred target, the exact
four-target compact set, and sole dependency unchanged. Its description must exactly
match `policy/foundation.json`, enforced by `Assert-Policy.ps1:2632-2633`.

#### `docs/policies/licensing-and-fixtures.md`

**Analog:** lines 14-39.

Add one explicit external-derivative rule: deterministic transformation does not
change origin or license; records must preserve upstream source/author/license,
confirmed redistribution, derivative generator identity/date, parent and derivative
digests, notice, and expected use. Keep the existing statement that generated fixture
preference never permits copying external input and relabeling it.

#### `README.mbt.md`

**Analog sections:**

- MoonBit doc-test frontmatter and public-only imports: lines 1-12;
- executable caller-owned-byte/limits/budget examples: lines 40-157;
- exact qualification narrative and commands: lines 296-381;
- deliberate boundaries: lines 383-396.

Add a public `mbt check` collection example using deterministic inline/generated bytes,
`FontCollectionLimits`, `FontCollection::open`, profile/DSIG inspection, and
`open_face`. It must use only public imports and caller-owned bytes.

Update the contract table's accepted input and opening description. Document TTC/OTC
v1/v2 inspection, selected static-`glyf` admission, DejaVu two-face derivative
provenance/digests, both faces' equality to standalone facts, v2 command/evidence
directory, and exactly-four-target comparison.

Correct lines 390-391, which currently exclude collection containers. Retain explicit
exclusions for WOFF1/2 runtime admission, CFF/CFF2 selection/execution, variable face
selection, DSIG trust/cryptographic verification, ambient I/O/FFI, and higher text or
rendering layers.

**Anti-patterns:** non-executable snippets, filesystem paths as runtime input, claiming
DSIG trust, or deleting the Phase 100 standalone oracle narrative.

#### `CHANGELOG.md`

**Analog:** current single unpublished candidate section, especially Added lines 10-60
and retained boundary lines 69-74.

Append bullets under the existing `0.1.0 candidate (unpublished)` section for:

- TTC/OTC v1/v2 inspection and static-`glyf` selected admission already delivered by
  Phases 101/102;
- Phase 103 hostile/mutation/atomicity qualification;
- the licensed DejaVu two-face derivative and independent TTC oracle;
- v2 four-target evidence.

Replace only the stale “collection support” exclusion. Retain WOFF, CFF/CFF2 execution,
variation execution, DSIG trust, publication, stability, and new-public-API exclusions.

## Shared Patterns

### Closed ordered schemas

**Sources:** generator lines 847-903, runner lines 261-374, policy lines 2448-2498.

All JSON schemas are order-sensitive, versioned, and reject missing, extra, duplicate,
or reordered keys/IDs. Use `[ordered]` PowerShell objects and LF UTF-8-no-BOM
serialization everywhere.

### Independent oracle boundary

**Source:** `Generate-FontQualification.ps1:483-687`.

PowerShell parses canonical bytes directly. Production MoonBit and target test output
never certify fixtures. The new TTC oracle must bind to, not replace, the existing SFNT
oracle.

### Atomic public failures

**Sources:** `collection_test.mbt:939-1033`, `1282-1564`, and
`collection_wbtest.mbt:299-362`.

Every failure assertion records the exact structured error and publication state, then
proves all eight caller budget dimensions unchanged. Ancestor failures snapshot both
parent and child.

### Mutation without races

**Sources:** `collection_test.mbt:1587-1642` and
`collection_wbtest.mbt:299-362`, `993-1034`.

Public tests cover mutation before/after publication and permanent revision identity.
White-box callbacks cover only mid-open/mid-selection windows with mutate-and-restore;
no threads, timers, or target-dependent scheduling are needed.

### Managed evidence ownership

**Sources:** runner lines 94-259 and boundary test lines 34-142.

Evidence paths must be strict children of the managed root, contain no reparse/symbolic
link component, and carry the exact v2 ownership marker. Cleanup removes only the four
known target records and `comparison.json`.

### Exact interface and dependency independence

**Sources:** `Assert-Policy.ps1:981-1093`, `2421-2425`, `2619-2702`.

The policy JSON allowlist, an independent hard-coded classifier, generated interface,
module manifest, package imports, dependency graph, target set, directory inventory,
and negative fixtures must all agree.

## Strict Plan Dependencies and Conflict-Safe Ownership

| Slice | Exclusive file ownership | Required handoff |
|---|---|---|
| **103-01 Canonical fixtures/oracle/provenance** | four new fixture files, `fixtures/manifest.json`, `Generate-FontQualification.ps1`, `generated_font_qualification_test.mbt`, plus only the exact fixture-manifest inventory block in `Assert-Policy.ps1` | Freeze paths, ordered schemas/IDs, digests, oracle identity, generated type/function names, exact TTC bytes, and the fail-closed 14-record manifest gate before Slice 2 starts. |
| **103-02 Public/hostile/mutation/standalone locks** | `font_qualification_test.mbt`, `font_qualification_hostile_test.mbt`, `collection_wbtest.mbt` | Freeze exact focused file/test names, public fact sections, hostile ID order, budget schema, and pass identities before Slice 3 starts. Do not edit Slice 1 artifacts. |
| **103-03 v2 evidence/policy/CI/docs** | runner, evidence-boundary test, remaining `Assert-Policy.ps1` v2/API/source/workflow gates, `foundation.json`, workflow, module manifest, licensing policy, README, changelog | Consume Slice 1's already-merged fixture-manifest classifier and digests/schemas plus Slice 2 test identities verbatim. Do not regress the 14-record gate, regenerate fixtures, or rename tests. |

These are strict sequential dependencies. `Assert-Policy.ps1` is the sole shared writable
file: Slice 1 owns only the manifest hard-dependency discovered by its fixture-policy
gate, and Slice 3 reopens the already-merged file for the remaining v2 boundaries.
No shared file is written concurrently. Do not parallelize Slice 2 before the generated
symbols/case IDs exist, or Slice 3 before the focused assertion names and evidence fact
shapes are final.

## Anti-Patterns to Reject Globally

- Editing production MoonBit unless evidence proves a concrete defect.
- Changing any of the exact 85 public interface lines.
- Modifying the Phase 100 standalone corpus, oracle identity, 11 hostile IDs, or
  standalone test names.
- Copying the DejaVu binary a second time into generated MoonBit literals.
- Calling `mb-font` from the oracle/generator.
- Relabeling external or derived DejaVu content as Apache-2.0/project-generated.
- Runtime filesystem/network/host-font access, FFI, GUI state, or target-specific code.
- Treating inspectable CFF/CFF2/variable faces as selectable.
- Adding WOFF decode/admission or relying on documentation-only WOFF exclusions.
- Trusting or cryptographically verifying DSIG.
- Normalizing any evidence field except top-level `target` and `runner`.
- Reusing, auto-migrating, or deleting the v1 evidence directory.
- Broad recursive cleanup without marker, containment, and link checks.
- Aggregate full-package test-count locks.
- CI passing-evidence upload under `always()`.
- Publication or release-policy changes.

## No Analog Found

None. Every Phase 103 responsibility has a direct Phase 100 qualification analog, a
Phase 101/102 collection analog, or a composite of the two.

## Metadata

**Graph discovery:** codebase-memory project `mnf-phase100-exec` (1,240 indexed files);
the graph indexes Markdown/JSON sections but has no MoonBit/PowerShell callable-symbol
nodes, so unsupported implementation/config gaps were read directly.  
**Targeted search scope:** `fixtures/font`, `scripts/fixtures`, `scripts/quality`,
`modules/mb-font`, `policy/foundation.json`, `.github/workflows/quality.yml`,
licensing policy, and Phase 100-102 planning/verification artifacts.  
**Pattern extraction date:** 2026-07-28
