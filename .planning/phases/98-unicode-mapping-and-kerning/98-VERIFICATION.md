---
phase: 98-unicode-mapping-and-kerning
verified: 2026-07-27T08:07:26.951Z
status: passed
score: 16/16 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 15/16
  gaps_closed:
    - "Post-read retained-source mutation is now exercised deterministically for glyph_for_scalar and kerning."
  gaps_remaining: []
  regressions: []
---

# Phase 98: Unicode Mapping and Kerning Verification Report

**Phase Goal:** Library authors can resolve Unicode scalars and basic legacy horizontal kerning through deterministic queries over the admitted font.
**Verified:** 2026-07-27T08:07:26.951Z
**Status:** passed
**Re-verification:** Yes — after closure of the sole behavior-unverified ordering invariant

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | BMP and supplementary-plane scalars map deterministically to in-range opaque glyph IDs. | ✓ VERIFIED | `Font::glyph_for_scalar` returns `GlyphId`; public scalar and combined workflow tests pass on all four targets (`font.mbt:250`, `font_test.mbt:1011,1046`). |
| 2 | A valid unmapped scalar returns glyph zero; invalid scalars and malformed mappings return structured errors. | ✓ VERIFIED | Scalar boundaries/misses are asserted in `font_test.mbt:1011`; malformed cmap bodies/keys/cardinality are asserted in the package suite; no eligible Unicode cmap is Capability at `font_test.mbt:1683`. |
| 3 | Supported version-0 horizontal format-0 kerning returns signed units; table absence and pair miss return zero. | ✓ VERIFIED | `font_test.mbt:1143` asserts absence, empty table, first/middle/last hits, positive/negative values, misses, repeatability, and budget neutrality. |
| 4 | Unsupported kern profiles and malformed kern bytes remain distinct from absence/miss. | ✓ VERIFIED | `font_test.mbt:1292,1315,1361` assert deferred Capability versus open-time Data; `font_wbtest.mbt:433` freezes the five-way taxonomy. |
| 5 | Canonical cmap selection uses the exact four ranks, is record-order independent, admits aliases, rejects duplicate canonical keys, and never falls back. | ✓ VERIFIED | Literal rank in `cmap.mbt:32`; selector in `cmap.mbt:136`; black-/white-box tests at `font_test.mbt:1582,1648` and `font_wbtest.mbt:187`. |
| 6 | No eligible Unicode record is Capability; supplementary input against selected format 4 is a valid zero miss. | ✓ VERIFIED | `font_test.mbt:1614,1683`; `font_lookup_cmap_format4` returns zero above U+FFFF at `cmap.mbt:301`. |
| 7 | Cmap mappings are structurally/cardinality validated during atomic opening and retained as compact table-local lookup facts. | ✓ VERIFIED | `font_admit_cmap_lookup` is called by `font_admit_cmap_envelope` before `RequiredTableFacts` publication (`tables.mbt:1314,1804`); format-4/12 admission proves mapped glyph ranges. |
| 8 | Kerning revalidates both opaque glyph IDs against the receiving font. | ✓ VERIFIED | `Font::kerning` delegates to the private implementation that validates left and right before key construction (`font.mbt:354-391`); cross-font rejection test passes at `font_test.mbt:1188`. |
| 9 | The supported kern profile enforces exact classic version/subtable/coverage/format, exact lengths, canonical helpers, and sorted unique in-range keys. | ✓ VERIFIED | Classic/Apple envelope and format-0 validators are substantive (`kern.mbt:62,110,160`); hostile public/private cases pass. |
| 10 | Directory, cmap, kern-subtable, and pair work is preflighted before loops and charged under explicit limits, max_work, and shared budget. | ✓ VERIFIED | `font_admission_charge` and `font_admit_kern_bounded` wire the preflight/aggregate plan (`tables.mbt:74,162`; `kern.mbt:302`); exact-fit/one-short tests pass at `font_test.mbt:1389,1447`. |
| 11 | Successful queries are allocation-free binary searches, repeatable/order-independent, and budget-neutral. | ✓ VERIFIED | Count-derived searches in `cmap.mbt:230,301` and `kern.mbt:433`; combined and isolated workflow tests assert repeated values and unchanged budgets. |
| 12 | Pre/post revision guards reject mutation before or during table lookup. | ✓ VERIFIED | `glyph_for_scalar_after_lookup` orders successful cmap lookup → callback → second guard → `GlyphId` (`font.mbt:258-280`); `kerning_after_lookup` orders successful kern lookup → callback → second guard → adjustment (`font.mbt:363-401`). White-box tests at `font_wbtest.mbt:313,329` mutate the retained owner inside that interval, reject any `Ok`, assert the exact State/InvalidRange drift error, and pass 2/2. |
| 13 | The complete public/private matrix behaves identically on js, wasm, wasm-gc, and native. | ✓ VERIFIED | Independent re-verifier runs: 62/62 on each target with package `font`, unique external target dirs, and `--no-parallelize`. |
| 14 | The generated interface exposes only the two queries, two kern-limit accessors, and expanded constructor; private facts do not leak. | ✓ VERIFIED | `pkg.generated.mbti:19,23,41-49`; `moon info --target all` was byte-stable; scoped private-symbol scan returned no matches. |
| 15 | Policy preserves four targets and the sole `mb-font -> mb-core` dependency while registering exact cmap/kern inventories. | ✓ VERIFIED | `policy/foundation.json:2181-2331`, `moon.pkg`, and independent `Assert-FontFoundationPolicy` all agree and pass. |
| 16 | Public documentation accurately describes the delivered queries, limits, taxonomy, guards, and Phase 99/100 exclusions. | ✓ VERIFIED | Literate contract sections at `modules/mb-font/README.mbt.md:121-185`, changelog, and equivalent English/Chinese root README text; README checks pass on all four targets. |

**Score:** 16/16 truths verified (0 behavior-unverified)

### Re-verification Evidence

The previous report left only truth 12 behavior-unverified. Quick task commits `aba48a63` and `96c09619` added the private deterministic interleaving seam and executable tests; `ed2cadce` recorded their planning evidence. Independent re-verification found:

- Both callbacks occur only after their successful cmap/kern lookup and immediately before the second revision guard.
- Each test mutates the same retained `OwnedBytes`, executes its callback exactly once, treats any successful value as a test failure, and receives `State` / `InvalidRange`, operation `font-query`, context `font-source-revision-drift`.
- Focused native evidence passes 2/2.
- The complete package passes 62/62 independently on all four supported targets.
- Previously verified artifacts, key links, requirements, policy, and documentation have no regression.

### Prohibition Verification

| Prohibition | Tier | Status | Enforcement evidence |
|---|---|---|---|
| Malformed or unsupported cmap/kern data must not be silently reinterpreted as glyph zero or neutral kerning zero. | test | ✓ VERIFIED | Executable capability/data/miss matrices at `font_test.mbt:1292-1388,1582-1704` and five-way taxonomy at `font_wbtest.mbt:333`; all pass on four targets. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-font/font/cmap.mbt` | Canonical rank, compact format-4/12 facts, allocation-free lookup | ✓ VERIFIED | 402-line substantive implementation; called by admission and public query. |
| `modules/mb-font/font/kern.mbt` | Optional tri-state, strict admission, pair lookup | ✓ VERIFIED | 480-line substantive implementation; called by admission and public query. |
| `modules/mb-font/font/tables.mbt` | Atomic retained cmap/kern integration and work accounting | ✓ VERIFIED | `RequiredTableFacts` carries both states; `FontAdmissionPlan` carries bounded kern state. |
| `modules/mb-font/font/directory.mbt` | Optional normalized table lookup | ✓ VERIFIED | `font_optional_table_window` at line 627 is used by kern admission. |
| `modules/mb-font/font/font.mbt` | Public guarded scalar and kerning methods | ✓ VERIFIED | Public methods at lines 250 and 354 delegate through private after-lookup seams; validation, lookup, callback, second guard, and publication remain wired in order. |
| `modules/mb-font/font/limits.mbt` | Explicit non-zero kern ceilings | ✓ VERIFIED | Constructor validation and accessors at lines 41-67 and 121-127. |
| `modules/mb-font/font/font_test.mbt` | Public semantic/resource/mutation evidence | ✓ VERIFIED | Phase 98 black-box matrix is part of all four 60-test passes. |
| `modules/mb-font/font/font_wbtest.mbt` | Private rank/search/envelope/taxonomy and post-read ordering evidence | ✓ VERIFIED | New deterministic drift tests at lines 313 and 329 plus all prior private boundary tests execute in all four target runs. |
| `modules/mb-font/font/pkg.generated.mbti` | Exact minimal public interface | ✓ VERIFIED | Regenerated byte-stable; no private cmap/kern symbols. |
| `policy/foundation.json` | Exact dependency/target/source/publication/interface policy | ✓ VERIFIED | Independent policy classifier passes. |
| Module/root documentation | Accurate delivered contract and exclusions | ✓ VERIFIED | Four-target literate checks pass; English and Chinese discovery text agree. |

### Key Link Verification

The generic key-link query reported “target not referenced” because MoonBit package files share private symbols without per-file imports. Manual symbol-level tracing verified the links:

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `font.mbt` | `cmap.mbt` | `Font::glyph_for_scalar -> font_lookup_cmap` | ✓ WIRED | Signed validation, one selected lookup, second guard, opaque publication. |
| `tables.mbt` | `cmap.mbt` | `font_admit_cmap_envelope -> font_admit_cmap_lookup` | ✓ WIRED | Selected descriptor enters `RequiredTableFacts.cmap`. |
| `directory.mbt` | `kern.mbt` | `tables.mbt` passes `font_optional_table_window(...)` into `font_admit_kern_bounded` | ✓ WIRED | Absence remains `None`; no required-table error conversion. |
| `tables.mbt` | `kern.mbt` | bounded admission retains `KernState` in `FontAdmissionPlan` and `RequiredTableFacts` | ✓ WIRED | No query-time profile parsing. |
| `font.mbt` | `kern.mbt` | `Font::kerning -> font_lookup_kern` | ✓ WIRED | Both IDs validated before lookup; second guard before publication. |
| `pkg.generated.mbti` | `policy/foundation.json` | exact semantic-interface allowlist | ✓ WIRED | Independent policy gate passed. |
| `font_test.mbt` | public `Font` API | black-box calls to `glyph_for_scalar`, `kerning`, and limits | ✓ WIRED | Same suite executed on all targets. |
| `policy/foundation.json` | `moon.pkg` | exact imports and target contract | ✓ WIRED | mb-core-only imports and four targets agree. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| `Font::glyph_for_scalar` | mapped glyph value | retained caller `ByteView` -> normalized cmap `TableWindow` -> selected `CmapLookupFacts` -> binary search | Yes; generated fonts return glyphs 1/2/3/4 and real misses | ✓ FLOWING |
| `Font::kerning` | signed adjustment | optional kern `TableWindow` -> admitted `KernState::Supported` -> pair binary search -> `read_i16` | Yes; tests return `10`, `-20`, `30`, and `-37` | ✓ FLOWING |
| `Font::open` resource path | `FontAdmissionPlan` and `ResourceCharge` | caller limits/budget plus attacker-declared table/record/pair counts | Yes; exact-fit consumes work and one-short fails unchanged | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Post-read cmap/kern mutation invariant | `moon -C modules/mb-font test font --target native --frozen --target-dir D:\AI-Data\temp\Admin\mnf-phase98-reverify-20260727-c9d4\focused-native --no-parallelize -f "*post-read revision drift*"` | 2 passed, 0 failed | ✓ PASS |
| Native public/private package behavior | Scoped command with `--target native` and unique `...\full-native` directory | 62 passed, 0 failed | ✓ PASS |
| JavaScript public/private package behavior | Scoped command with `--target js` and unique `...\full-js` directory | 62 passed, 0 failed | ✓ PASS |
| Wasm public/private package behavior | Scoped command with `--target wasm` and unique `...\full-wasm` directory | 62 passed, 0 failed | ✓ PASS |
| Wasm-GC public/private package behavior | Scoped command with `--target wasm-gc` and unique `...\full-wasm-gc` directory | 62 passed, 0 failed | ✓ PASS |
| Generated interface | `moon -C modules/mb-font info --target all --frozen --target-dir ...\info-all` | Completed; SHA-256 remained `f8058722f34e1f54a6c5dcbd5e8960a4d29a48d9561382599c9ec20e56d92ade` | ✓ PASS |
| Literate public contract | `moon -C modules/mb-font check README.mbt.md --target <each target> --frozen --target-dir <unique>` | Passed for native/js/wasm/wasm-gc | ✓ PASS |
| Independent font policy | `. scripts/quality/Assert-Policy.ps1; Assert-FontFoundationPolicy -PolicyPath policy/foundation.json` | Exact policy/interface/dependency/target checks passed | ✓ PASS |

Native compilation emitted only the known warning from the installed MoonBit core `builtin/result.mbt`; no project-source warning was reported.

### Probe Execution

Step 7c: **SKIPPED** — no Phase 98 plan/summary declares a probe script, and no conventional `scripts/**/tests/probe-*.sh` exists for this phase.

### Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
|---|---|---|---|---|
| FONT-02 | 98-01, 98-03 | Deterministic format-12/4 mapping, zero miss, structured invalid/malformed outcomes | ✓ SATISFIED | Truths 1, 2, 5-7, 13-16; four-target suite passes. |
| FONT-04 | 98-02, 98-03 | Basic format-0 kerning with neutral absence/miss and distinct unsupported/malformed outcomes | ✓ SATISFIED | Truths 3, 4, 8-11, 13-16; four-target suite passes. |

No Phase 98 requirement is orphaned: REQUIREMENTS.md maps exactly FONT-02 and FONT-04 to Phase 98, and both appear in plan frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `scripts/quality/Assert-Policy.ps1` | 227 | Words `placeholder`, `todo`, and `tbd` appear in a rejection regex/message | ℹ️ Info | This is fail-closed validator text, not debt. |
| Test/build helpers | various | Empty arrays used as mutable byte/table builders | ℹ️ Info | Each is populated or intentionally represents a zero-record fixture; none flows as a runtime placeholder. |
| Root `README.md` | 26, 128 | Pre-existing “active line is v0.27” milestone prose | ℹ️ Info | Introduced before Phase 98; Phase 98's English/Chinese font capability text is accurate and equivalent. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker exists in Phase 98 production files. No skipped/focused tests, runtime placeholder, empty public handler, FFI, new dependency, or private interface leak was found. The intentional no-op callbacks on public entry points preserve production behavior while keeping the interleaving control private. `git diff --check` passes. All 16 implementation commits named by the Phase 98 and gap-closure summaries exist.

### Deferred Items

No failed Phase 98 truth was deferred. Phase 99 outline extraction and Phase 100 licensed real-font/workspace qualification are explicit future scope, not missing Phase 98 deliverables.

### Gaps Summary

The sole prior behavior-unverified item is closed by deterministic executable evidence for both public query paths. No implementation, wiring, policy, interface, requirement, behavioral, or human-verification gap remains. Phase 98 achieves its goal and is ready to proceed.

---

_Verified: 2026-07-27T08:07:26.951Z_
_Verifier: the agent (gsd-verifier)_
