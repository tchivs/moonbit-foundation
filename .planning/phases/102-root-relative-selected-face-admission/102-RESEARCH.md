# Phase 102: Root-Relative Selected-Face Admission - Research

**Researched:** 2026-07-28  
**Domain:** No-copy TTC/OTC selected-face normalization into the existing MoonBit `Font` admission path  
**Confidence:** HIGH for repository seams, signatures, ordering, and test strategy; MEDIUM-HIGH for the prescriptive private ledger and exact selected-byte formula

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Public selected-face contract
- **D-01:** Add exactly one public operation, `FontCollection::open_face(index, FontLimits, Budget) -> Result[Font, CoreError]`, with the concrete MoonBit receiver/reference spelling derived from existing package conventions. — **Reversibility:** costly — renaming or replacing the method after consumers adopt it changes the generated public interface and downstream call sites.
- **D-02:** A successful selection returns the existing opaque `Font` directly. Do not add `CollectionFace`, collection-specific metric/query methods, or public directory/range handles.
- **D-03:** `open_face` is non-consuming and repeatable. Each call is an independent admission transaction with its own limits and caller-owned budget; the collection stores no admitted-face cache.

### Root-relative private admission seam
- **D-04:** Parameterize the private directory/admission seam with the retained root source, an absolute selected-directory start, and an explicit checksum mode. Add the directory start only to directory-field reads; consume every table-record offset unchanged against collection byte zero.
- **D-05:** Never materialize a standalone SFNT, concatenate table bytes, or copy the complete collection. The returned `Font` retains the same root `ByteView` and collection opening revision so exact shared table ranges retain one mutation identity.
- **D-06:** Reuse Phase 101 cached selected-face authority facts (`directory_start`, declared table count, closed profile, collection structural admission, opening revision). Reparse only the selected directory into fresh semantic `DirectoryFacts`; do not rescan or semantically admit unrelated siblings.
- **D-07:** Exact cross-face sharing needs no global cache or special public identity. Each selected `Font` builds its own table-local root subviews. Unsupported CFF/CFF2/variable siblings remain irrelevant after the collection envelope is admitted; selecting one of those profiles fails `Capability` before deep table admission.

### Limits, work, and atomic budget ownership
- **D-08:** Keep collection opening and selected-face admission as separate transactions. `open_face` accepts the existing `FontLimits` and `Budget`; it never reuses, stores, refunds, or mutates the Phase 101 collection-opening charge.
- **D-09:** Resolve the research accounting tension with a split rule: `FontLimits.max_source_bytes` bounds the retained collection-root extent, while admission work/byte facts and the final caller charge cover only the selected directory plus distinct referenced selected-table extents and the selected semantic work. Unrelated sibling payloads are neither scanned nor repeatedly charged.
- **D-10:** Collection selection uses staged preflights before attacker-declared loops but commits one exact aggregate selected-face charge only after semantic admission and the final revision guard. Preserve standalone `Font::open` charging and observable malformed-input behavior unchanged by using a private collection-mode ledger/commit policy rather than globally rewriting helper semantics.

### Error precedence, mutation, and publication
- **D-11:** Freeze selection precedence as: retained-root revision → face index → cached selected profile → selected source/declaration/structural authority stages → selected directory/table facts in established wire order → required-table and per-table checksum semantics → exact final budget preflight → final root revision → one charge → publish `Font`.
- **D-12:** Any mutation since collection admission returns `State` before index/profile handling. Mutation during selection fails the final revision guard without a committed charge or published `Font`; any later mutation, including mutate-then-restore, invalidates all inherited `Font` queries through the retained shared revision cell.
- **D-13:** Out-of-range indices remain `Input`; unsupported selected profiles remain `Capability`; malformed selected directory/tables/checksums remain their existing `Data` contexts; resource failures use the established `Resource` category. Combination tests must freeze the order in D-11.

### Collection checksum compatibility
- **D-14:** In collection mode validate every selected table checksum exactly as standalone mode does, including zeroing `head` bytes 8–11 for the `head` table checksum, but skip only the standalone whole-source `0xB1B0AFBA` checksum-adjustment check. Standalone checksum behavior and bytes remain unchanged.
- **D-15:** A selected static `glyf` face must expose existing `Font` metrics, cmap, kerning, glyph identity, and unhinted outline semantics with no collection provenance visible in those APIs.

### Explicit non-goals
- **D-16:** Phase 102 remains read-only and selected-static-`glyf` only: no CFF/CFF2 or variable execution, WOFF/WOFF2, DSIG trust, eager all-face semantic admission, persistent face caching, extraction/materialization, subsetting/merging/writing, discovery/fallback, shaping, bidi, hinting, rasterization, FFI, ambient I/O, new module, or new dependency.
- **D-17:** Phase 103 owns broad hostile matrices, licensed collection/derivative provenance, immutable fixture digests, standalone-vs-collection qualification, and complete four-target release evidence. Phase 102 still adds focused tests necessary to prove its own contracts.

### the agent's Discretion
- Private type names, file splits, and helper placement may follow the closest `directory.mbt` / `font.mbt` / `tables.mbt` patterns.
- The exact internal ledger representation and checked-arithmetic helper decomposition are flexible if D-09 through D-13 remain directly testable.
- Focused generated TTC builder reuse may be refactored for clarity, but fixture provenance and broad qualification remain Phase 103.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within Phase 102 scope. Broad qualification, licensed evidence, and release-level four-target matrices remain explicitly assigned to Phase 103.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TTC-02 | Library authors can select one in-range static `glyf`-based TrueType face from an admitted collection and receive the existing opaque `Font`, whose metrics, Unicode mapping, kerning, glyph identity, and unhinted outline behavior match the equivalent standalone logical font. | Concrete `open_face` signature, shared admission seam, retained-root publication, equivalence assertions, and focused generated-face strategy below. |
| TTC-03 | A selected collection face resolves table offsets against the collection root, preserves valid exact cross-face table sharing, enforces collection-specific checksum rules, and remains usable when unsupported CFF/CFF2 or variable siblings are present. | Offset-aware directory seam, explicit checksum mode, cached-profile gate, sharing/lifetime policy, mixed-profile cases, and standalone compatibility gates below. |
</phase_requirements>

## Summary

Phase 102 should add one method to `FontCollection` and refactor the existing private standalone directory/admission pipeline into two modes without changing any existing `Font::open` observation. The exact public implementation spelling should be:

```moonbit
pub fn FontCollection::open_face(
  self : FontCollection,
  index : UInt64,
  limits : FontLimits,
  budget : @budget.Budget,
) -> Result[Font, @error.CoreError]
```

The generated interface spelling is therefore `pub fn FontCollection::open_face(Self, UInt64, FontLimits, @budget.Budget) -> Result[Font, @error.CoreError]`. This matches the existing receiver convention and the Phase 102 negative fixture already embedded in `Assert-Policy.ps1`. [VERIFIED: `collection.mbt`, generated Phase 101 interface, `Assert-Policy.ps1`, CONTEXT.md D-01]

The core implementation seam is not a second parser. Generalize `directory.mbt` so directory-local reads use an absolute `directory_start`, table-record offsets remain root-relative, and checksum behavior is selected through a private closed mode. Keep thin zero-offset standalone wrappers. Then move the common post-directory path in `font.mbt` behind a private admission function that accepts a commit policy: existing incremental standalone semantics versus one deferred atomic collection charge. [VERIFIED: current `directory.mbt`, `font.mbt`, `tables.mbt`; RECOMMENDATION derived from D-04, D-10, D-14]

The budget refactor is the main planning hazard. Current cmap and kern declaration scans call `Budget::charge` before semantic completion, and `Font::open` commits its main admission charge before profile, required-table, checksum, table-semantic, metric-index, and final revision checks. Reusing that path directly would violate D-10. A collection-mode private ledger must preflight the real caller budget cumulatively before every attacker-declared loop but record virtual staged work without mutating that budget; only the exact aggregate charge is committed after semantic admission and the final revision guard. The standalone mode must retain the current preflight/charge calls and their error order. [VERIFIED: `font.mbt:99-168`, `tables.mbt:89-390`, `tables.mbt:918-958`, `kern.mbt:302-480`; CONTEXT.md D-10 through D-13]

**Primary recommendation:** implement Phase 102 in three dependent plans: first refactor offset/checksum/ledger internals under unchanged standalone tests, then wire `open_face` and exact selected accounting, then add focused equivalence/precedence/policy/four-target evidence.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `open_face` orchestration | `FontCollection` public facade | shared private font admission | The collection owns revision/index/profile gates; the existing font pipeline owns semantic admission and publication. [VERIFIED: CONTEXT.md D-01 through D-07] |
| Root-relative directory parsing | `directory.mbt` private boundary | Phase 101 cached face facts | Directory fields need a base; table windows remain root-based and downstream tables stay container-neutral. [VERIFIED: current source; CITED: OpenType 1.9.1 `otff`] |
| Checksum policy | `directory.mbt` private validation | `font.mbt` sequencing | Both modes validate selected tables; only standalone validates the whole source. [VERIFIED: current source; CITED: OpenType `otff` and `head`] |
| Staged work authority | private admission ledger in `tables.mbt`/`kern.mbt` | `Budget` | The ledger adapts commit timing; `Budget` remains the authoritative ancestor-aware preflight/charge mechanism. [VERIFIED: `mb-core/budget`; RECOMMENDATION] |
| Metrics/cmap/kern/glyph/outline behavior | existing `Font` and table-local readers | root-backed `TableWindow`s | These components already consume retained table-local views and need no collection branch. [VERIFIED: `font.mbt`, `cmap.mbt`, `kern.mbt`, `metrics.mbt`, `outline.mbt`] |
| Exact sharing identity | retained collection root `ByteView` | independent selected `Font` handles | Equal root ranges naturally share bytes/revision without a cache or public identity. [VERIFIED: Phase 101 implementation and `ByteView` behavior] |
| Public surface and inventories | `policy/foundation.json` | `Assert-Policy.ps1` | Both exact allowlists must advance together by one intended method and continue rejecting parser/storage/deferred types. [VERIFIED: current policy files] |

## Project Constraints (from AGENTS.md)

- Core algorithms and data models must remain pure MoonBit. [VERIFIED: AGENTS.md]
- The package remains portable across `js`, `wasm`, `wasm-gc`, and `native`; native is the primary local performance/integration target. [VERIFIED: AGENTS.md; `moon.pkg`]
- No FFI is needed or permitted for this phase. [VERIFIED: AGENTS.md; CONTEXT.md D-16]
- Public dependencies remain acyclic; `tchivs/mb-font` continues to depend only on `tchivs/mb-core`. [VERIFIED: AGENTS.md; current manifests]
- Public pre-1.0 changes must be explicit and policy-tracked; only `open_face` is added. [VERIFIED: AGENTS.md; CONTEXT.md D-01, D-02]
- Operations remain deterministic and accept caller-provided bytes/budgets without ambient GUI, filesystem, or network state. [VERIFIED: AGENTS.md; CONTEXT.md D-16]
- Any performance claim would require a reproducible workload; Phase 102 acceptance uses exact accounting and behavioral tests rather than marketing benchmarks. [VERIFIED: AGENTS.md]
- No new module or architectural boundary is introduced without an RFC; work stays inside the RFC-accepted `mb-font/font` package. [VERIFIED: AGENTS.md; RFC 0004]
- Code discovery must prefer codebase-memory MCP. The indexed project returned zero MoonBit nodes for `modules/mb-font/font`, so targeted source search and complete relevant-file reads were the permitted fallback. [VERIFIED: codebase-memory queries; AGENTS.md]
- Work is already routed through `$gsd-plan-phase`; implementation edits belong to later `$gsd-execute-phase` work. [VERIFIED: AGENTS.md; orchestrator task]

No project-local skills were found in `.codex/skills` or `.agents/skills`, and no `gsd-phase-researcher` agent skill was configured. [VERIFIED: filesystem and agent-skills query]

## Standard Stack

### Core

| Component | Verified Version | Purpose | Why Standard |
|-----------|------------------|---------|--------------|
| `moon` / `moonrun` | `0.1.20260713` (`75c7e1f`, 2026-07-13) | Build and run the package on all supported targets | Exact local and CI development baseline. [VERIFIED: local CLI] |
| `moonc` | `v0.10.4+2cc641edf` (2026-07-15) | Compile MoonBit sources | Bundled with the pinned toolchain. [VERIFIED: local CLI] |
| `tchivs/mb-font` | repository `0.1.0` line | Collection facade and existing opaque `Font` | Phase 102 adapts the existing package rather than creating a parallel font model. [VERIFIED: manifests; CONTEXT.md D-02] |
| `tchivs/mb-core` | repository `0.1.0` line | `ByteView`, revision identity, checked arithmetic, `Budget`, structured errors, `Path2` | Already supplies every required foundation primitive and is the only runtime dependency. [VERIFIED: manifests and source] |
| OpenType specification | 1.9.1 | Normative TTC root-offset and checksum behavior | Official format authority. [CITED: https://learn.microsoft.com/en-us/typography/opentype/spec/otff] |

### Supporting

| Component | Purpose | Prescriptive Use |
|-----------|---------|------------------|
| `CollectionFaceFacts` | Cached `directory_start`, `directory_end`, `table_count`, `sfnt_version`, profile | Pass the selected start/count/profile into the shared seam; do not rediscover siblings. [VERIFIED: `collection_parser.mbt`] |
| `DirectoryFacts` / `TableWindow` | Existing normalized semantic directory and root-backed table views | Preserve these types so all downstream readers remain unchanged. [VERIFIED: `directory.mbt`] |
| `Budget::preflight` / `Budget::charge` | Ancestor-aware resource authority and atomic commit | Collection mode uses real cumulative preflights and one final charge; never use a detached shadow as authority. [VERIFIED: `mb-core/budget`; RECOMMENDATION] |
| `mutation_revision()` | Permanent shared mutation identity | Carry Phase 101 opening revision into every derived `Font`. [VERIFIED: `collection.mbt`, `font.mbt`, `mb-core/bytes`] |
| Existing generated SFNT/TTC builders | Deterministic focused test data | Relocate standalone table records into deliberately before/after-directory root layouts. [VERIFIED: `font_test.mbt`, `generated_fonts_wbtest.mbt`, `collection_test.mbt`] |

**Installation:** none. Phase 102 adds no external package, runtime service, native library, or tool dependency. Package-legitimacy audit is not applicable. [VERIFIED: CONTEXT.md D-16]

## Architecture Patterns

### System Architecture Diagram

```text
FontCollection::open_face(index, limits, budget)
                  |
                  v
      require retained root revision
                  |
                  v
       index gate -> cached profile gate
                  |
                  v
root ByteView + opening revision + directory_start + cached table_count
                  |
                  v
 offset-aware private directory seam
 - directory fields = root[directory_start + local field offset]
 - TableRecord.offset = root offset unchanged
 - same-face overlap/range checks
 - root-backed TableWindow normalization
                  |
                  v
 shared admission with Collection checksum mode
 - required tables
 - per-table checksum (head bytes 8..11 treated as zero)
 - no whole-root 0xB1B0AFBA check
 - existing cmap/kern/metrics/loca/glyf semantics
 - cumulative staged budget preflights through deferred ledger
                  |
                  v
 exact aggregate preflight -> final root revision -> one charge
                  |
                  v
 existing opaque Font retaining collection root + collection opening revision
```

### Recommended Project Structure

```text
modules/mb-font/font/
├── collection.mbt          # add the single public open_face facade and selection gates
├── directory.mbt           # offset-aware parsing + explicit checksum mode + zero-offset wrappers
├── font.mbt                # shared post-directory admission/publication; preserve Font::open
├── tables.mbt              # admission plan exposes exact totals; ledger-aware cmap staging
├── kern.mbt                # ledger-aware kern staging
├── collection_test.mbt     # black-box selected-face workflows and precedence
├── collection_wbtest.mbt   # private base/checksum/ledger/revision-hook facts
└── font_test.mbt           # unchanged standalone regression oracle; add only surgical guards if needed
```

Avoid a new production file unless the helper split materially improves readability: every new file expands exact production/test inventories in both policy files. The existing five implementation files already own the relevant responsibilities. [VERIFIED: current policy inventories; RECOMMENDATION]

### Pattern 1: Thin Standalone Wrappers over an Offset-Aware Core

Use an explicit private mode and an optional cached count:

```moonbit
priv enum FontChecksumMode {
  Standalone
  Collection
}

fn font_parse_directory_at(
  source : @bytes.ByteView,
  directory_start : UInt64,
  expected_table_count : UInt64?,
  limits : FontLimits,
  checksum_mode : FontChecksumMode,
) -> Result[DirectoryFacts, @error.CoreError]
```

`font_parse_directory(source, limits)` remains as a zero-offset standalone wrapper so existing call sites and diagnostics do not change. Collection mode passes `Some(face.table_count)` and must compare the re-read count with the cached count before looping; revision identity makes disagreement impossible on valid state, but the comparison keeps the private authority boundary fail-closed. [VERIFIED: current wrappers and cached facts; RECOMMENDATION]

Only these field locations add `directory_start`:

- SFNT signature: `directory_start`
- table count: `directory_start + 4`
- search facts: `directory_start + 6`, `+8`, `+10`
- record `i`: `directory_start + 12 + 16*i`

The `offset` stored in each table record is passed unchanged to `checked_font_table_view(source, offset, length)`. [CITED: OpenType 1.9.1 `otff`; VERIFIED: CONTEXT.md D-04]

Replace `table_offset < directory_end` with a half-open overlap test against `[directory_start, directory_end)`. Tables before the directory are legal; touching endpoints are legal; non-empty same-face overlaps remain `Data`. Do not compare selected tables to sibling tables again: Phase 101 already established all protected and cross-face alias facts under the retained revision. [VERIFIED: Phase 101 code/verification; CONTEXT.md D-06]

### Pattern 2: Explicit Checksum Mode, Split Operations

Refactor checksum validation into:

```text
font_validate_table_checksums(directory)        # both modes
font_validate_standalone_checksum(directory)    # standalone only
font_validate_checksums(directory, mode)        # ordered dispatcher
```

For every selected table, keep the existing padded big-endian `UInt32` checksum and pass `zero_head_adjustment=true` only for `head`. In collection mode stop after the table loop. In standalone mode run the unchanged whole-source sum and require `0xB1B0AFBA`. [VERIFIED: current `font_sfnt_checksum`/`font_validate_checksums`; CITED: OpenType `otff` and `head`; CONTEXT.md D-14]

Do not infer the mode from `directory_start == 0`: semantic container policy must be explicit and auditably impossible to select accidentally. [RECOMMENDATION derived from D-04, D-14]

### Pattern 3: Dual-Mode Admission Ledger

Introduce one private mutable ledger/policy passed through cmap and kern declared-work helpers:

```moonbit
priv enum FontAdmissionCommitMode {
  StandaloneIncremental
  CollectionDeferred
}

priv struct FontAdmissionLedger {
  caller : @budget.Budget
  mode : FontAdmissionCommitMode
  mut virtual_staged_work : UInt64
}
```

Required behavior:

1. `preflight(base_plus_next_stage)` checks `FontLimits.max_work`.
2. In standalone mode it calls the existing caller `preflight` with the existing request and later charges the stage exactly where current code does.
3. In collection mode it checked-adds `virtual_staged_work` to the request, preflights that cumulative work against the real caller budget and every ancestor, and records the stage only in `virtual_staged_work`.
4. The admission plan exposes both `exact_work` and the legacy `remaining_work`; standalone commits exactly the legacy remainder at its existing point, while collection includes full `exact_work` in one final charge.

Do not create `Budget::new(budget.remaining())` as the sole authority: `remaining()` exposes only the current window, so a detached shadow loses possibly tighter live ancestor windows. Real cumulative `preflight` calls are required to preserve hierarchical authority without committing. [VERIFIED: `Budget::remaining`, `preflight`, `charge`, `child`; RECOMMENDATION]

This ledger is the minimal way to reuse the current cmap/kern loops and still meet both D-10 requirements: zero collection failure charges and unchanged standalone timing/errors. [VERIFIED: current staged charge sites; RECOMMENDATION]

### Pattern 4: Shared Semantic Admission, Mode-Specific Commit Timing

Extract the post-directory body into one private function or tightly paired functions. It must reuse:

- `font_require_table_presence`
- table checksum validation
- `font_admission_charge`/plan discovery
- `font_admit_required_tables_with_kern`
- `font_admit_metric_index`
- existing `Font` construction

The collection sequence is:

1. required-table presence;
2. selected per-table checksums;
3. exact semantic plan discovery with deferred staged preflights;
4. required-table semantic admission and metric-index admission;
5. exact final aggregate caller preflight;
6. final root revision;
7. one caller charge;
8. construct the existing `Font`.

The standalone facade keeps its current observable order and commit points. The shared implementation may branch on private commit/checksum modes, but it must not create separate cmap/kern/metrics/outline implementations. [VERIFIED: current pipeline; CONTEXT.md D-10, D-11, D-15]

### Pattern 5: Revision-First Facade and Inherited Identity

`open_face` should:

1. call `self.require_revision("font-collection-open-face")`;
2. validate `index < self.faces.length`;
3. checked-narrow the index;
4. reject any cached profile other than `StaticGlyf` as `Capability`;
5. pass `self.source`, `self.opening_revision`, cached directory facts, limits, and budget to the private collection admission seam.

On success, `Font.source` is `self.source` and `Font.opening_revision` is `self.opening_revision`, not a directory subview and not a fresh independent identity. [VERIFIED: current struct fields and revision pattern; CONTEXT.md D-05, D-12]

Add a private `open_face_after_admit(..., before_final_guard : () -> Unit)` test seam analogous to `FontCollection::open_after_normalize`. This gives a deterministic mid-selection mutate/restore test without exposing hooks publicly. [VERIFIED: existing Phase 101 test seam; RECOMMENDATION]

## Exact Selected-Face Accounting

### Selected Extent Formula

Let:

- `R = cached selected table_count`
- `D = face.directory_end - face.directory_start`
- `T = checked sum of every selected table record's actual length`
- `S = font_directory_search_power_and_selector(R).1`
- `P = R * (R - 1) / 2`, with checked subtraction before multiplication

Phase 101 already guarantees no same-face table overlap, so each selected record contributes one distinct referenced extent; shared ranges in sibling faces do not duplicate the selected face's `T`. [VERIFIED: Phase 101 D-08 and verification]

Use:

```text
selected_extent_bytes = checked_add(D, T)

collection_directory_work =
    R       # selected record scan
  + P       # same-face overlap comparisons
  + R       # DirectoryFacts/TableWindow normalization
  + S       # deterministic search-selector work
  + T       # selected per-table checksum source-byte work
```

The directory bytes are represented in `selected_extent_bytes`; their fixed field reads are already represented by record/search work. There is no whole-root checksum term in collection mode. Standalone retains its existing `2 * source.length` directory checksum-work formula and its exact historical charges. [VERIFIED: current standalone formula; RECOMMENDATION derived from D-09, D-10, D-14]

The final collection charge should be:

```text
ResourceCharge:
  bytes           = selected_extent_bytes
  allocations     = 3
  allocation_size = max(64 * R, 8 * (num_glyphs + 1))
  width/height/pixels = 0
  work            = exact selected work from the existing admission formula
                    with collection_directory_work as its directory prefix
```

The three allocations and allocation-size formula are the current directory-record, normalized-table-window, and loca-index model. Keep them unchanged. [VERIFIED: `font_directory_allocation_size`, `font_admission_charge`; RECOMMENDATION]

### Semantic Limit versus Caller Charge

- `FontLimits.max_source_bytes` compares against `self.source.length()`, because the returned `Font` retains the complete collection root. [VERIFIED: CONTEXT.md D-09]
- `max_tables`, `max_table_bytes`, all semantic count ceilings, and `max_work` apply only to the selected face. [VERIFIED: CONTEXT.md D-08, D-09]
- Caller `ResourceCharge.bytes` is `D + T`, not root length, not copied allocation, and not multiplied by sibling count. [VERIFIED: CONTEXT.md D-09]
- A repeat call recomputes and charges one independent selected transaction; it does not reuse Phase 101 charge or prior selected work. [VERIFIED: CONTEXT.md D-03, D-08]

### Staged Authority

Before each attacker-declared selected loop, preflight cumulative work through the deferred ledger:

1. cached `R` authorizes the directory-record scan only after `max_tables` and its structural-work prefix pass;
2. selected table lengths are checked against `max_table_bytes` and checked-summed before checksum scans;
3. cmap, kern, name, post, glyph, loca, and mapping counts keep their existing semantic ceiling and staged work preflights;
4. the exact aggregate budget preflight occurs after semantics and before the final revision guard;
5. no stage mutates the real caller budget.

This preserves bounded traversal while keeping the one committed transaction. [VERIFIED: D-10, D-11; RECOMMENDATION]

## Stable Error and Publication Precedence

| Order | Gate | Required outcome |
|------:|------|------------------|
| 1 | retained collection revision | `State/InvalidRange`, operation `font-collection-open-face`, context `font-collection-source-revision-drift` |
| 2 | `index >= face_count` or narrowing failure | `InvalidInput/InvalidRange`, operation `font-collection-open-face`, context `font-collection-face-index`, requested=index, limit=count |
| 3 | cached profile is not `StaticGlyf` | `Capability/CapabilityUnavailable`, operation `font-collection-open-face`, context `font-collection-face-profile` |
| 4 | root `max_source_bytes`, cached selected count, structural/staged work authority | existing `Resource` taxonomy; no loop before authority |
| 5 | selected signature/count/search/record tags, limits, root-relative ranges, same-face overlap | existing `font-*` `Data`/`Resource` contexts in wire order |
| 6 | required table presence, selected per-table checksums | existing `font-required-table` then `font-table-checksum`; collection never emits `font-checksum-adjustment` |
| 7 | selected semantic admission and exact final caller preflight | existing semantic `Data`/`Capability`/`Resource` contexts; budget errors remain `budget_charge` dimension facts |
| 8 | final retained-root revision | `State` with no committed charge and no `Font` |
| 9 | one exact caller charge | failure publishes no `Font`; successful commit occurs once |
| 10 | publication | construct existing opaque `Font` only here |

The three new pre-gate contexts above are prescriptive names under the agent's discretion. Deep parser/table contexts should stay exactly existing to satisfy D-13 and avoid collection-specific duplicates. [VERIFIED: current errors; RECOMMENDATION]

Mandatory multi-fault tests:

- revision drift + out-of-range index → `State`;
- out-of-range index + unsupported profile → `InvalidInput`;
- unsupported cached profile + selected bytes that would fail limits/data → `Capability`;
- malformed selected directory + short exact budget → earlier `Data` when structural traversal authority is sufficient;
- missing required table + bad checksum → required-table `Data`;
- bad selected table checksum + exact budget one short → checksum `Data`;
- valid semantics + final budget one short → `Resource`, unchanged budget;
- deterministic mid-selection mutate/restore → `State`, unchanged budget.

[VERIFIED: CONTEXT.md D-11 through D-13; RECOMMENDATION]

## Public and Policy Contract Changes

Advance the generated semantic interface from 84 to 85 lines by inserting exactly:

```text
pub fn FontCollection::open_face(Self, UInt64, FontLimits, @budget.Budget) -> Result[Font, @error.CoreError]
```

Expected edits:

1. add the method to `collection.mbt`;
2. add the exact line to `policy/foundation.json` after `FontCollection::open(...)` in generated order;
3. rename/generalize `Assert-FontPhase101Surface` to the current Phase 102 classifier and add the same line to its independent exact allowlist;
4. remove only the exact `open_face` line from the deferred-forbidden list;
5. add negative cases for missing, duplicated, reordered, altered-return-type, and extra `CollectionFace`/raw handle declarations;
6. keep `pkg.generated.mbti` generated and ignored; regenerate it for comparison but do not commit it.

No public type, constructor parameter, import, module dependency, source view, raw range, parser fact, or collection-specific query may accompany the method. [VERIFIED: current policy, `.gitignore`, CONTEXT.md D-01, D-02]

## Focused Test Strategy

### Test Builders

Reuse the existing generated standalone SFNT tables and collection placement helpers. A focused TTC builder should:

1. take one valid generated standalone `glyf` font;
2. copy its directory to a non-zero chosen root offset;
3. relocate each table payload independently and patch each directory record to the absolute collection-root location;
4. preserve per-table checksum values;
5. permit tables both before and after the directory;
6. permit selected faces to point at exact shared root ranges;
7. permit a sibling directory with CFF/CFF2/variable profile tags but no deep semantic payload.

Do not derive expected metrics/outlines by calling the production parser. Compare the selected `Font` to the already-open standalone generated `Font` through public methods. [VERIFIED: existing builders; CONTEXT.md specifics; RECOMMENDATION]

### Required Black-Box Cases

| Area | Focused cases |
|------|---------------|
| Public contract | index 0 and last valid index return `Font`; repeated selection with independent budgets; no collection provenance method/type |
| Equivalence | units-per-em, bounds, both line metrics, scalar→glyph, glyph ID, horizontal metrics, kern hit/miss, and outline commands/digest equal the standalone logical font |
| Offset origin | non-zero directory with legal table before it and table after it; wrong rebase remains in-bounds but produces different bytes |
| Sharing | two faces select successfully with exact shared `glyf`/`loca`/`hmtx`; distinct cmap/name facts remain face-local |
| Mixed profiles | supported static face opens beside CFF, CFF2, and variable siblings; selecting each unsupported sibling fails before deep admission |
| Checksums | selected bad table checksum fails; non-zero `head.checksumAdjustment` does not trigger whole-source failure in collection; unchanged standalone bad whole adjustment still fails |
| Limits/charge | root source ceiling exact/one-short; selected `D+T`, allocations, allocation-size, and exact work exact/one-short; every failed collection selection leaves all budget dimensions unchanged |
| Revision | mutate/restore before selection; deterministic mutation during selection; later mutation invalidates all queries on every independently returned `Font` |
| Precedence | all multi-fault combinations listed above |

### Required White-Box Cases

- exact root-coordinate `DirectoryFacts` and table views for before/after layouts;
- `collection_directory_work` and `selected_extent_bytes` exact arithmetic/overflow remapping;
- standalone versus collection checksum dispatcher, including proof that collection never calls the whole-source branch;
- deferred ledger cumulative preflight and zero real charges on semantic failure;
- standalone ledger mode reproduces existing staged deltas and error order;
- final revision hook rejects mutate/restore before one final charge;
- two selected fonts retain the same root revision identity but do not share an admitted-font cache.

### Commands and Sampling

Current baseline is 131/131 on native. [VERIFIED: local execution on 2026-07-28]

Use:

```text
moon -C modules/mb-font test font/collection_test.mbt --target native --frozen --target-dir target/phase102-public --no-parallelize
moon -C modules/mb-font test font/collection_wbtest.mbt --target native --frozen --target-dir target/phase102-private --no-parallelize
moon -C modules/mb-font test font --target native --frozen --target-dir target/phase102-native --no-parallelize
moon -C modules/mb-font check --target all --frozen
moon -C modules/mb-font info --target all --frozen
powershell -NoProfile -File scripts/quality/Assert-Policy.ps1
git diff --check
```

At the phase gate, run the focused collection public/private selectors independently on `js`, `wasm`, `wasm-gc`, and `native`. Phase 103 owns the complete broad four-target release matrix and licensed fixture evidence. [VERIFIED: CONTEXT.md D-17; RECOMMENDATION]

`.planning/config.json` explicitly sets `workflow.nyquist_validation` to `false`, so no separate Validation Architecture section is emitted. The focused test contract above remains required by D-17. [VERIFIED: config]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Root byte ownership | copied standalone SFNT or scatter/gather virtual file | retained root `ByteView` plus existing subviews | Preserves no-copy sharing and monotonic revision identity. [VERIFIED: D-05] |
| Table semantics | collection-specific cmap/kern/metric/outline parser | existing `DirectoryFacts` → existing admission/readers | Prevents behavioral divergence. [VERIFIED: D-02, D-15] |
| Budget authority | detached counters or a `Budget::new(remaining())` shadow as sole authority | real cumulative `Budget::preflight` plus private virtual staged-work ledger | Preserves ancestor constraints and atomic final commit. [VERIFIED: budget source; RECOMMENDATION] |
| Checksum implementation | disabling checksums or rebuilding a synthetic whole font | existing `font_sfnt_checksum` plus explicit mode dispatcher | Keeps table integrity and changes only the normative collection aggregate rule. [CITED: OpenType `otff`, `head`] |
| Cross-face sharing cache | global table/font cache, dedup hash, public identity | independent root subviews over exact shared ranges | Phase 101 already admitted the structural alias; no cache contract is needed. [VERIFIED: D-03, D-07] |
| Sibling validation | rescan or semantically admit every sibling during selection | cached Phase 101 authority facts plus one selected reparse | Keeps work independent of unrelated sibling payloads. [VERIFIED: D-06, D-09] |

## Runtime State Inventory

Phase 102 includes a private refactor, so all five runtime-state categories were audited.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None — `mb-font/font` is a pure byte library with no database/datastore integration. [VERIFIED: package source/imports] | None |
| Live service config | None — no external service, UI-stored workflow, daemon, or remote configuration participates. [VERIFIED: package source/imports] | None |
| OS-registered state | None — no task, service, launcher, registry, or system-font registration exists. [VERIFIED: repository/source audit] | None |
| Secrets/env vars | None — selected admission reads only explicit arguments and no secret/environment name is changed. [VERIFIED: source audit] | None |
| Build artifacts | Ignored `pkg.generated.mbti` and target caches may contain the pre-Phase-102 interface/objects. [VERIFIED: `.gitignore`, local generated file] | Regenerate through `moon info` and rebuild isolated target directories; no data migration or installed-package migration. |

After every repo file is updated, no runtime system retains an old selected-face name or schema; only disposable build/interface artifacts require regeneration. [VERIFIED: inventory above]

## Common Pitfalls

### Pitfall 1: Double-Basing Record Offsets

**What goes wrong:** `directory_start + record.offset` reads the wrong table, sometimes still in bounds.  
**How to avoid:** add the base only to directory field locations; build each table view from the root and unchanged record offset.  
**Warning sign:** a builder with all tables after the directory passes but a before-directory fixture fails. [CITED: OpenType `otff`; VERIFIED: D-04]

### Pitfall 2: Treating Source Ceiling as Selected Charge

**What goes wrong:** charging the entire root per face makes repeated selection proportional to unrelated siblings.  
**How to avoid:** compare root length with `max_source_bytes`, then charge only `D + T` and selected work.  
**Warning sign:** two collections with identical selected face but different unused sibling payloads produce different selection charges. [VERIFIED: D-09]

### Pitfall 3: Using Existing Incremental Charges on the Real Budget

**What goes wrong:** malformed checksum/table/metric or mid-selection mutation consumes work before failure.  
**How to avoid:** collection ledger preflights cumulative real authority but records staged work virtually until final commit.  
**Warning sign:** any failed `open_face` changes `budget.remaining()`. [VERIFIED: current charge sites; D-10]

### Pitfall 4: Detached Shadow Budget Loses Ancestors

**What goes wrong:** `Budget::new(budget.remaining())` sees only the current window and can authorize work that a concurrently consumed ancestor can no longer cover.  
**How to avoid:** preflight cumulative work on the real budget at every stage.  
**Warning sign:** behavior differs between root and child budgets with an independently consumed ancestor. [VERIFIED: `Budget` implementation]

### Pitfall 5: Applying Standalone Whole-Source Checksum

**What goes wrong:** valid TTC faces fail `font-checksum-adjustment`.  
**How to avoid:** keep all selected table checksums and skip only the standalone aggregate branch.  
**Warning sign:** collection acceptance depends on the sum of unrelated sibling/header bytes. [CITED: OpenType `otff`, `head`]

### Pitfall 6: Revalidating Every Sibling

**What goes wrong:** selection work scales with the full collection and unsupported siblings poison a supported face.  
**How to avoid:** trust Phase 101 structural facts under the revision guard; reparse only the selected directory and tables.  
**Warning sign:** corrupt deep CFF payload blocks a static `glyf` sibling. [VERIFIED: D-06, D-07]

### Pitfall 7: Fresh Revision Instead of Collection Revision

**What goes wrong:** a stale collection could “refresh” selected facts or a derived font could outlive a mutation boundary.  
**How to avoid:** revision-first gate and publish the `Font` with the collection's retained opening revision.  
**Warning sign:** mutate/restore between collection open and face selection succeeds. [VERIFIED: D-12]

### Pitfall 8: Policy Allowlist Drift

**What goes wrong:** implementation, JSON policy, and independent PowerShell classifier evolve together but accidentally expose another type or omit a negative.  
**How to avoid:** exact one-line advance plus missing/duplicate/reorder/extra-surface negative fixtures.  
**Warning sign:** generated interface count is not exactly 85 semantic lines. [VERIFIED: current Phase 101 gate; RECOMMENDATION]

## Code Examples

### Root-Relative Record Location

```moonbit
let record_start = @checked.checked_add(
  directory_start,
  @checked.checked_add(
    12UL,
    @checked.checked_mul(table_index, 16UL).unwrap(),
  ).unwrap(),
).unwrap()
let table_start = read_u32(source, record_start + 8UL).unwrap()
let table_length = read_u32(source, record_start + 12UL).unwrap()
let table_view = checked_font_table_view(source, table_start, table_length)
```

The example is schematic: production code must map checked failures to the established font `Data`/`Resource` contexts rather than use `unwrap`. The important invariant is that `directory_start` is absent from `table_start`. [CITED: OpenType `otff`; VERIFIED: current helper conventions]

### Collection Checksum Dispatch

```moonbit
fn font_validate_checksums(
  directory : DirectoryFacts,
  mode : FontChecksumMode,
) -> Result[Unit, @error.CoreError] {
  match font_validate_table_checksums(directory) {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  match mode {
    Standalone => font_validate_standalone_checksum(directory)
    Collection => Ok(())
  }
}
```

This keeps table checksum ordering identical and removes only the collection-inapplicable aggregate rule. [CITED: OpenType `otff`, `head`; RECOMMENDATION]

### Revision-First Public Gate

```moonbit
pub fn FontCollection::open_face(
  self : FontCollection,
  index : UInt64,
  limits : FontLimits,
  budget : @budget.Budget,
) -> Result[Font, @error.CoreError] {
  match self.require_revision("font-collection-open-face") {
    Err(error) => return Err(error)
    Ok(_) => ()
  }
  // index, checked narrowing, cached profile, then private admission
  // against self.source and self.opening_revision
}
```

The concrete method signature is fixed; helper names and the remainder of the body are planner discretion. [VERIFIED: D-01, D-11]

## State of the Art

| Existing State | Phase 102 State | Impact |
|----------------|-----------------|--------|
| Standalone directory begins at zero | shared parser accepts an absolute directory start | One root-relative normalization seam supports both containers. [VERIFIED: current source; CITED: OpenType] |
| `font_validate_checksums` always applies table and whole-source rules | explicit standalone/collection mode | Valid TTC faces keep per-table integrity without a false aggregate invariant. [CITED: OpenType] |
| cmap/kern work can be committed during declaration scans | collection mode virtually records staged work and commits once | Malformed/mutated selection is budget-atomic. [VERIFIED: current source; D-10] |
| `Font::open` owns the only construction path | standalone and selected collection route to the same opaque `Font` constructor | Existing public queries remain container-neutral. [VERIFIED: D-02, D-15] |
| Phase 101 interface has 84 lines and forbids `open_face` | Phase 102 interface has exactly 85 lines and permits only that method | Policy remains fail-closed. [VERIFIED: current policy; RECOMMENDATION] |

## Assumptions Log

All factual format claims were checked against official OpenType 1.9.1 documentation; all repository claims were verified in current source or Phase 101 verification. No `[ASSUMED]` claim remains.

The selected accounting formula, private type names, context strings, and three-plan decomposition are labeled recommendations under explicit agent discretion. They are not external factual claims.

## Open Questions

No user decision is required before planning. The planner should treat the following as prescriptive defaults:

1. Use `D + T` for selected charge bytes.
2. Use `T` as collection per-table checksum byte work and retain standalone `2 * source.length` unchanged.
3. Use a real-budget cumulative-preflight ledger rather than a detached shadow.
4. Keep deep errors on existing `font-*` contexts and use `font-collection-open-face` only for revision/index/profile gates.
5. Keep production file inventory unchanged unless a helper split clearly outweighs the additional policy churn.

If implementation evidence shows MoonBit mutability makes the proposed ledger shape awkward, the planner may change the private representation but not its observable rules: cumulative ancestor-aware preflights, zero real collection charges before final publication, and unchanged standalone behavior. [VERIFIED: CONTEXT.md discretion]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| `moon` | compile/test/info | ✓ | `0.1.20260713` | none needed |
| `moonc` | compilation | ✓ | `v0.10.4+2cc641edf` | supplied by pinned toolchain |
| `moonrun` | backend test execution | ✓ | `0.1.20260713` | none needed |
| workspace `tchivs/mb-core` | bytes/revision/checked/budget/error/math | ✓ | repository workspace | no alternative permitted |
| External font engine/crypto/FFI/service | not required | n/a | — | intentionally excluded |

**Missing dependencies with no fallback:** none.  
**Missing dependencies with fallback:** none.

The current full native `mb-font/font` suite passes 131/131 before Phase 102 edits. [VERIFIED: local execution]

## Security Domain

Security enforcement is not explicitly disabled, so input-validation and resource-atomicity controls apply. [VERIFIED: `.planning/config.json`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No identity boundary. |
| V3 Session Management | no | No session state. |
| V4 Access Control | no | No principal or protected operation. |
| V5 Input Validation | yes | Cached authority, checked root-coordinate arithmetic, semantic ceilings, per-table checksums, stable error precedence. |
| V6 Cryptography | no | Collection DSIG remains structurally unverified and Phase 102 adds no trust claim. |

This is a phase-local applicability map, not a compliance certification. [RECOMMENDATION]

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Directory-base confusion redirects table reads | Tampering | Absolute directory-local reads plus unchanged root table offsets and in-bounds wrong-rebase fixture. [CITED: OpenType `otff`] |
| Huge selected declarations cause work before authority | Denial of Service | Cached count ceilings and cumulative staged preflights before every dependent loop. [VERIFIED: D-10, D-11] |
| Semantic failure consumes caller budget | Denial of Service / integrity | Deferred virtual staged-work ledger and one final commit. [VERIFIED: D-10] |
| Unsupported sibling poisons selected face | Denial of Service | Cached selected-profile gate; no sibling semantic rescan. [VERIFIED: D-06, D-07] |
| Mutation between admission and publication | Tampering | Opening revision inherited from collection and final guard before charge. [VERIFIED: D-12] |
| Whole-collection checksum misapplied | Tampering / compatibility | Per-table checksums in both modes; standalone aggregate only in standalone mode. [CITED: OpenType `otff`, `head`] |
| Accidental public parser/storage surface | Information disclosure / compatibility | Exact 85-line independent interface classifier and negative fixtures. [VERIFIED: policy pattern; D-02] |

## Plan Decomposition Recommendation

### Plan 102-01 — Offset-Aware Directory, Checksum Mode, and Standalone Lock

- Add `FontChecksumMode`, checked absolute directory helpers, `font_parse_directory_at`, real overlap checks, and thin zero-offset wrappers.
- Split table versus standalone aggregate checksum validation.
- Introduce the dual-mode admission ledger and expose exact/legacy work facts in the private admission plan.
- Route existing `Font::open` through standalone modes without adding `open_face`.
- Tests: offset/before-directory white-box cases, checksum dispatcher, ledger standalone mode, all 131 existing native tests, exact historical error/budget regressions.

**Dependency rationale:** the risky refactor must be proven behavior-neutral before the new public path uses it. [RECOMMENDATION]

### Plan 102-02 — Selected-Face Transaction and Existing `Font` Publication

- Add revision/index/profile error helpers and the exact public `open_face` method.
- Pass cached start/count/profile and collection opening revision into the shared seam.
- Implement root source ceiling, selected `D + T`, collection directory work, deferred staged preflights, semantic admission, final aggregate preflight, final revision hook/guard, one charge, and existing `Font` construction.
- Tests: public selected static face, repeatability, mixed-profile isolation, root-relative before/after tables, exact sharing, checksum mode, exact/one-short dimensions, later query revision invalidation.

**Dependency rationale:** selected admission depends on the qualified private modes from 102-01. [RECOMMENDATION]

### Plan 102-03 — Equivalence, Precedence, Policy, and Focused Portability Gate

- Complete standalone-vs-selected public metric/cmap/kern/glyph/outline equivalence.
- Add the multi-fault D-11 precedence matrix and deterministic mid-selection mutate/restore atomicity.
- Advance `policy/foundation.json` and the independent PowerShell classifier by exactly one line; retain all private/deferred negatives.
- Run focused public/private collection tests on all four targets, full native regression, target-all check/info, policy, and whitespace gates.

**Dependency rationale:** policy and cross-target evidence should freeze the settled implementation/signature, while broad licensed/release qualification stays Phase 103. [RECOMMENDATION]

## Sources

### Primary (HIGH repository authority)

- `102-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md` — locked scope, TTC-02/TTC-03, and sequencing.
- `101-RESEARCH.md`, `101-VERIFICATION.md`, and resolved TTC precedence debug record — inherited authority, verified root/alias/revision facts, and staged-work lessons.
- `modules/mb-font/font/collection.mbt`, `collection_parser.mbt`, `directory.mbt`, `font.mbt`, `tables.mbt`, `kern.mbt`, `metrics.mbt`, `cmap.mbt`, `outline.mbt` — exact current implementation seams.
- `modules/mb-core/budget/budget.mbt` and bytes implementation — hierarchical budget and shared revision semantics.
- `policy/foundation.json` and `scripts/quality/Assert-Policy.ps1` — exact public interface/source/dependency gates.
- Existing font/collection black-box and white-box tests — builder and assertion patterns.

### Official Specifications (MEDIUM seam confidence; HIGH authority)

- [OpenType font file / Font Collections 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/otff) — complete per-face directories, root-relative table offsets, table sharing, per-table checksums, and collection checksum policy.
- [OpenType `head` table 1.9.1](https://learn.microsoft.com/en-us/typography/opentype/spec/head) — `checksumAdjustment` is ignored when the font is a collection component.

The research-plan seam selected Jina, which was unavailable in this agent runtime; the documented fallback used web search restricted to the official Microsoft OpenType pages. `classify-confidence --provider websearch --verified` returned MEDIUM, and both digests were cached at that tier. [VERIFIED: research seam execution]

### Secondary

- `.planning/research/ARCHITECTURE.md`, `FEATURES.md`, and `SUMMARY.md` — milestone synthesis cross-checked against the current post-Phase-101 code.

### Tertiary

- None.

## Metadata

**Confidence breakdown:**

- Public signature/policy change: HIGH — current generated convention and exact negative fixture already identify the intended line.
- Directory/root/checksum architecture: HIGH — current source plus official OpenType rules.
- Revision/lifetime propagation: HIGH — Phase 101 verification and `ByteView`/`Font` source fields.
- Ledger design: MEDIUM-HIGH — directly derived from current charge sites and hierarchical `Budget`; private representation remains discretionary.
- Exact selected charge/work formula: MEDIUM-HIGH — D-09 fixes the boundary and current formulas fix the dimensions; exact `D + T`/`T` representation is a prescriptive planner choice requiring one-short tests.
- Test/policy decomposition: HIGH — established local test and fail-closed policy patterns.

**Research date:** 2026-07-28  
**Valid until:** 2026-08-27, or earlier if Phase 101 authority facts, `Budget`, `Font::open`, the generated interface baseline, or the pinned MoonBit toolchain change.
