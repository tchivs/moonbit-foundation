---
phase: 98-unicode-mapping-and-kerning
verified: 2026-07-27T08:53:05.757Z
status: passed
score: 16/16 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 16/16
  gaps_closed:
    - "CR-98-001: failed kern subtable and pair scans now consume shared work immediately while bytes and allocations remain atomic."
    - "CR-98-002: failed cmap record and format-4 discovery scans now consume shared work immediately while one-short preflight does not charge the rejected scan."
    - "WR-98-001: the module manifest description is now enforced as an exact policy value."
    - "WR-98-002: bilingual root discovery text now identifies v0.32 TrueType Font Foundation as the active line."
  gaps_remaining: []
  regressions: []
---

# Phase 98: Unicode Mapping and Kerning Verification Report

**Phase Goal:** Library authors can resolve Unicode scalars and basic legacy horizontal kerning through deterministic queries over the admitted font.
**Verified:** 2026-07-27T08:53:05.757Z
**Status:** passed
**Re-verification:** Yes — final post-review-fix regression verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | BMP and supplementary-plane scalars map deterministically to in-range opaque glyph IDs. | ✓ VERIFIED | `Font::glyph_for_scalar` returns `GlyphId`; public scalar and combined workflow tests pass on all four targets (`font.mbt:250`, `font_test.mbt:1011,1046`). |
| 2 | A valid unmapped scalar returns glyph zero; invalid scalars and malformed mappings return structured errors. | ✓ VERIFIED | Scalar boundaries/misses are asserted in `font_test.mbt:1011`; malformed cmap bodies/keys/cardinality are asserted in the package suite; no eligible Unicode cmap is Capability at `font_test.mbt:1781`. |
| 3 | Supported version-0 horizontal format-0 kerning returns signed units; table absence and pair miss return zero. | ✓ VERIFIED | `font_test.mbt:1143` asserts absence, empty table, first/middle/last hits, positive/negative values, misses, repeatability, and budget neutrality. |
| 4 | Unsupported kern profiles and malformed kern bytes remain distinct from absence/miss. | ✓ VERIFIED | `font_test.mbt:1296,1319,1376` assert deferred Capability versus open-time Data; `font_wbtest.mbt:433` freezes the five-way taxonomy. |
| 5 | Canonical cmap selection uses the exact four ranks, is record-order independent, admits aliases, rejects duplicate canonical keys, and never falls back. | ✓ VERIFIED | Literal rank in `cmap.mbt:32`; selector in `cmap.mbt:136`; black-/white-box tests at `font_test.mbt:1680,1746` and `font_wbtest.mbt:187`. |
| 6 | No eligible Unicode record is Capability; supplementary input against selected format 4 is a valid zero miss. | ✓ VERIFIED | `font_test.mbt:1712,1781`; `font_lookup_cmap_format4` returns zero above U+FFFF at `cmap.mbt:301`. |
| 7 | Cmap mappings are structurally/cardinality validated during atomic opening and retained as compact table-local lookup facts. | ✓ VERIFIED | `font_admit_cmap_lookup` is called by `font_admit_cmap_envelope` before `RequiredTableFacts` publication (`tables.mbt:1333-1385,1796-1861`); format-4/12 admission proves mapped glyph ranges. |
| 8 | Kerning revalidates both opaque glyph IDs against the receiving font. | ✓ VERIFIED | `Font::kerning` delegates to the private implementation that validates left and right before key construction (`font.mbt:354-391`); cross-font rejection test passes at `font_test.mbt:1188`. |
| 9 | The supported kern profile enforces exact classic version/subtable/coverage/format, exact lengths, canonical helpers, and sorted unique in-range keys. | ✓ VERIFIED | Classic/Apple envelope and format-0 validators are substantive (`kern.mbt:62,110,160`); hostile public/private cases pass. |
| 10 | Directory, cmap, kern-subtable, and pair work is preflighted before loops and charged under explicit limits, max_work, and shared budget. | ✓ VERIFIED | Cmap record/format-4 and kern subtable/pair scans are preflighted and work-only charged immediately before their loops (`tables.mbt:949-1078`; `kern.mbt:302-478`). The final admission charge subtracts all precharged scan work exactly once (`tables.mbt:347-375`). Focused malformed-late, one-short, exact-fit, and atomicity tests pass. |
| 11 | Successful queries are allocation-free binary searches, repeatable/order-independent, and budget-neutral. | ✓ VERIFIED | Count-derived searches in `cmap.mbt:230,301` and `kern.mbt:484`; combined and isolated workflow tests assert repeated values and unchanged budgets. |
| 12 | Pre/post revision guards reject mutation before or during table lookup. | ✓ VERIFIED | `glyph_for_scalar_after_lookup` orders successful cmap lookup → callback → second guard → `GlyphId` (`font.mbt:258-280`); `kerning_after_lookup` orders successful kern lookup → callback → second guard → adjustment (`font.mbt:363-401`). White-box tests at `font_wbtest.mbt:313,329` mutate the retained owner inside that interval, reject any `Ok`, assert the exact State/InvalidRange drift error, and pass 2/2. |
| 13 | The complete public/private matrix behaves identically on js, wasm, wasm-gc, and native. | ✓ VERIFIED | Independent final runs: 65/65 on each target with package `font`, unique external target dirs, and `--no-parallelize`. |
| 14 | The generated interface exposes only the two queries, two kern-limit accessors, and expanded constructor; private facts do not leak. | ✓ VERIFIED | `pkg.generated.mbti:19,23,41-49`; `moon info --target all` was byte-stable; scoped private-symbol scan returned no matches. |
| 15 | Policy preserves four targets and the sole `mb-font -> mb-core` dependency while registering exact cmap/kern inventories. | ✓ VERIFIED | `policy/foundation.json`, `moon.pkg`, and independent `Assert-FontFoundationPolicy` agree and pass; `moon.mod.json.description` exactly equals the policy value and the generic policy gate now enforces it. |
| 16 | Public documentation accurately describes the delivered queries, limits, taxonomy, guards, and Phase 99/100 exclusions. | ✓ VERIFIED | The module literate contract, changelog, and equivalent English/Chinese root README text describe the delivered v0.32 foundation and its exclusions; README checks pass on all four targets. |

**Score:** 16/16 truths verified (0 behavior-unverified)

### Re-verification Evidence

This final pass independently inspected the implementation introduced by review-fix commits `1d2fb155`, `5bb88f20`, `d5597d55`, and `4f916918`; the clean review/security narratives were used only to identify claims to falsify.

- Cmap record discovery commits `record_count` work immediately before traversal. Each format-4 segment scan separately proves the semantic cumulative `max_work`, preflights the remaining shared budget, then commits only that scan's work.
- Kern subtable and pair scans use the same ordering. Semantic checks include the full cumulative cmap/kern work, while shared-budget preflights include previously charged work implicitly through the reduced remaining budget.
- Successful admission computes the full aggregate once and subtracts cmap record, format-4 discovery, kern subtable, and kern pair work already committed; focused exact-fit tests and the full suite prove there is no double charge.
- One-short shared-budget tests prove the rejected scan is neither entered nor charged. Failure-path tests repeat late malformed cmap and kern inputs against one shared budget and observe cumulative work consumption, while bytes and allocations remain unchanged.
- Deterministic post-read revision interleaving still passes 2/2, and the complete package passes 65/65 independently on all four supported targets.
- The generated interface is byte-stable, the exact manifest description policy passes, and bilingual discovery text identifies v0.32 as active. No regression or human-only item remains.

### Prohibition Verification

| Prohibition | Tier | Status | Enforcement evidence |
|---|---|---|---|
| Malformed or unsupported cmap/kern data must not be silently reinterpreted as glyph zero or neutral kerning zero. | test | ✓ VERIFIED | Executable capability/data/miss matrices at `font_test.mbt:1296-1439,1680-1799` and five-way taxonomy at `font_wbtest.mbt:433`; all pass on four targets. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-font/font/cmap.mbt` | Canonical rank, compact format-4/12 facts, allocation-free lookup | ✓ VERIFIED | 406-line substantive implementation; called by admission and public query. |
| `modules/mb-font/font/kern.mbt` | Optional tri-state, strict bounded admission, pair lookup | ✓ VERIFIED | 545-line substantive implementation; immediate work charging is wired before attacker-driven scans. |
| `modules/mb-font/font/tables.mbt` | Atomic retained cmap/kern integration and work accounting | ✓ VERIFIED | `RequiredTableFacts` carries both states; `FontAdmissionPlan` carries bounded kern state. |
| `modules/mb-font/font/directory.mbt` | Optional normalized table lookup | ✓ VERIFIED | `font_optional_table_window` at line 627 is used by kern admission. |
| `modules/mb-font/font/font.mbt` | Public guarded scalar and kerning methods | ✓ VERIFIED | Public methods at lines 250 and 354 delegate through private after-lookup seams; validation, lookup, callback, second guard, and publication remain wired in order. |
| `modules/mb-font/font/limits.mbt` | Explicit non-zero kern ceilings | ✓ VERIFIED | Constructor validation and accessors at lines 41-67 and 121-127. |
| `modules/mb-font/font/font_test.mbt` | Public semantic/resource/mutation evidence | ✓ VERIFIED | Phase 98 black-box matrix includes repeated malformed scans, one-short preflight, exact-fit, and atomic byte/allocation assertions; the total package is 65 tests on every target. |
| `modules/mb-font/font/font_wbtest.mbt` | Private rank/search/envelope/taxonomy and post-read ordering evidence | ✓ VERIFIED | New deterministic drift tests at lines 313 and 329 plus all prior private boundary tests execute in all four target runs. |
| `modules/mb-font/font/pkg.generated.mbti` | Exact minimal public interface | ✓ VERIFIED | Regenerated byte-stable; no private cmap/kern symbols. |
| `policy/foundation.json` and `modules/mb-font/moon.mod.json` | Exact dependency/target/source/publication/interface/description policy | ✓ VERIFIED | Independent policy classifier passes and the manifest description is an exact policy match. |
| Module/root documentation | Accurate delivered contract, active milestone, and exclusions | ✓ VERIFIED | Four-target literate checks pass; English and Chinese discovery text agree on v0.32. |
| Phase 98 review/security artifacts | Clean final review and threat audit | ✓ VERIFIED | `98-REVIEW.md` is clean and `98-SECURITY.md` closes all 19 threats; their implementation claims were independently traced and exercised above. |

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
| `Font::open` resource path | `FontAdmissionPlan` and `ResourceCharge` | caller limits/budget plus attacker-declared table/record/pair counts | Yes; successful scans are charged exactly once, malformed scans consume work, a rejected one-short scan is uncharged, and bytes/allocations remain atomic | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Failed kern scan charging | Four focused native tests, including `repeated malformed last kern pairs consume one shared work budget` and exact-fit/atomicity | 4 individually named tests passed, 0 failed | ✓ PASS |
| Failed cmap scan charging and one-short behavior | The same focused run includes repeated malformed late discovery and rejected-scan one-short tests | Repeated attempts consume prior scan work; rejected scan is uncharged; bytes/allocations stay unchanged | ✓ PASS |
| Post-read cmap/kern mutation invariant | `moon -C modules/mb-font test font --target native --frozen --target-dir ...\revision-native --no-parallelize -f "*post-read revision drift*"` | 2 passed, 0 failed | ✓ PASS |
| Native public/private package behavior | Scoped command with `--target native`, unique external target directory, and `--no-parallelize` | 65 passed, 0 failed | ✓ PASS |
| JavaScript public/private package behavior | Scoped command with `--target js`, unique external target directory, and `--no-parallelize` | 65 passed, 0 failed | ✓ PASS |
| Wasm public/private package behavior | Scoped command with `--target wasm`, unique external target directory, and `--no-parallelize` | 65 passed, 0 failed | ✓ PASS |
| Wasm-GC public/private package behavior | Scoped command with `--target wasm-gc`, unique external target directory, and `--no-parallelize` | 65 passed, 0 failed | ✓ PASS |
| Generated interface | `moon -C modules/mb-font info --target all --frozen --target-dir ...\info-all` | Completed; SHA-256 remained `f8058722f34e1f54a6c5dcbd5e8960a4d29a48d9561382599c9ec20e56d92ade` | ✓ PASS |
| Literate public contract | `moon -C modules/mb-font check README.mbt.md --target <each target> --frozen --target-dir <unique> --serial` | Passed for native/js/wasm/wasm-gc | ✓ PASS |
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

No unreferenced `TBD`, `FIXME`, or `XXX` marker exists in Phase 98 production files. No runtime placeholder, empty public handler, FFI, new dependency, or private interface leak was found. The intentional no-op callbacks on public entry points preserve production behavior while keeping the interleaving control private. `git diff --check` passes. All four supplied post-review commits exist, and the worktree was clean before this report update.

### Deferred Items

No failed Phase 98 truth was deferred. Phase 99 outline extraction and Phase 100 licensed real-font/workspace qualification are explicit future scope, not missing Phase 98 deliverables.

### Gaps Summary

All post-review findings are closed in executable code and policy/documentation gates. No implementation, wiring, resource-accounting, policy, interface, requirement, behavioral, security, or human-verification gap remains. Phase 98 achieves its goal and is ready to proceed.

---

_Verified: 2026-07-27T08:53:05.757Z_
_Verifier: the agent (gsd-verifier)_
