---
phase: 106-cubic-path-and-public-ttc-integration
verified: 2026-07-28T22:25:33Z
status: passed
score: 12/12 must-haves verified
behavior_unverified: 0
overrides_applied: 0
requirements:
  - id: CFF-04
    status: satisfied
    reason: "Standalone static CFF1 now uses the existing opaque Font workflow, format-neutral common queries/errors, and an atomic exact native-cubic Path2 transaction."
  - id: CFF-05
    status: satisfied
    reason: "Selected TTC/OTC CFF1 faces reuse the same admission/outline implementation with retained collection revision, root/table coordinate authority, face-local common facts, and passing static-glyf compatibility fingerprints."
prohibitions_verified: 11
---

# Phase 106: Cubic Path and Public/TTC Integration Verification Report

**Phase Goal:** Library authors can use static CFF1 outlines through the existing format-neutral `Font` and `FontCollection` workflows.
**Verified:** 2026-07-28T22:25:33Z
**Status:** passed
**Re-verification:** No — initial goal verification after the final clean review/fix cycle

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | A supported standalone static CFF1 `OTTO` opens as the existing opaque `Font`, with common mapping, identity, metrics, kerning, line facts, and public operation names remaining format-neutral. | ✓ VERIFIED | `Font::open` branches `OTTO` into `admit_cff1_structure`, then non-fallibly projects complete facts through `font_from_admitted_cff1`. The public tracer and `public CFF boundaries keep format-neutral operation names` both pass. |
| 2 | A CFF outline returns one complete native cubic `Path2` with exact ordered controls and no CFF-specific public result or partial prefix. | ✓ VERIFIED | `Font::outline_after_decode` dispatches privately to `cff_decode_outline_atomic`; the public tracer asserts literal `MoveTo(10,20)`, `CubicTo((40,20),(80,30),(130,20))`, `Close`. No CFF production file contains `QuadTo`, flattening, or quadratic conversion. |
| 3 | Selected TTC/OTC CFF1 admission preserves collection-root authority, the collection opening revision, face directory/table count, and table-local CFF offsets. | ✓ VERIFIED | `FontCollection::open_face_after_preflights` passes the retained root, `self.opening_revision`, `face.directory_start`, and `face.table_count` to `font_open_cff_collection_face`; CFF parsing then operates on the selected `TableWindow.view`. The focused root/revision test passes. |
| 4 | Existing static-glyf standalone and collection behavior and charges remain unchanged. | ✓ VERIFIED | The production `StaticGlyf` arm still calls the original `font_open_collection_face`, `outline.mbt` is unchanged by Phase 106, and both Phase 106 public glyf fingerprints pass. The supplied full native result is 1281/1281. |
| 5 | Exact Top/FD matrix and design-unit normalization remain rational until one checked deterministic `Double` conversion at the `Point2` boundary. | ✓ VERIFIED | `Type2PathSink::point` calls exact `type2_matrix_apply` and only then `type2_rational_to_double`; literal integral, signed-fraction, large-cancellation, translation, and transformed-cubic goldens exist and pass in the native suite. |
| 6 | Empty, endchar-only, and move-only glyphs return an empty `Path2` with `bounds() == None`; only drawing contours publish `MoveTo` and `Close`. | ✓ VERIFIED | `Type2BoundsSink::include_contour_start` flushes the pending move on the first segment, while `close` emits only for `contour_has_segments`. The public edge test asserts empty/move-only paths and line/flex/multi-contour ordering. |
| 7 | Admission retains compact bounds, exact command counts, and exact path work, not full paths or replayable command streams. | ✓ VERIFIED | `AdmittedCff1` retains `bounds`, `path_command_counts`, and `path_work`; it has no `Path2`/command-stream field. Repository search finds no retained `Path2` in `cff_admission.mbt` or `cff_type2.mbt`. |
| 8 | Each outline query executes only the selected admitted GID through the sole Type 2 VM with fresh VM/PRNG/geometry/path state. | ✓ VERIFIED | One `while vm.frames` interpreter loop exists. `cff_decode_outline_atomic_with_probes` selects one descriptor and calls `type2_execute_glyph_with_path_capacity`; repeated/interleaved public queries produce identical command order and charge deltas. |
| 9 | Exact caller and ancestor authority succeeds; each independent one-short byte/allocation/allocation-size/work window fails before publication and changes no counter. | ✓ VERIFIED | The exact/one-short white-box matrices pass for standalone and selected collection admission/outline. `cff_decode_outline_atomic_with_probes` preflights retained exact path work before VM execution and commits one `CffPathCharge`. |
| 10 | Pre-execution, VM-fetch, pre-admission-commit, and post-stage mutation failures prefer `State`, return no `Font`/`Path2`, and leave every caller/ancestor budget unchanged. | ✓ VERIFIED | Focused pre-read, mid-fetch, public mutation, collection execution/commit, and post-stage tests pass. The closing code is `after_stage` → revision check → one `budget.charge` → immediate `Ok(path)`. |
| 11 | Shared CFF bytes coexist with independent face-local cmap, hmtx, kern, head/hhea/OS2 facts, and equal standalone/selected data has identical ordered results. | ✓ VERIFIED | The two-face shared-CFF fixture produces different scalar mappings, advances, bearings, kern, global/line facts but identical cubic commands; standalone/selected parity compares mapping, metrics, kerning, and every path command. |
| 12 | The public surface remains closed and unsupported CFF2/variable/mixed profiles remain rejected. | ✓ VERIFIED | The only added public declaration is format-neutral `Path2::with_capacity`; no public `Cff`/`Type2`/DICT/INDEX/FD API exists. Collection dispatch accepts only `StaticGlyf` and `Cff`; all other profile variants return the established collection profile capability error. |

**Score:** 12/12 truths verified (0 present-but-behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-core/math/path.mbt` | Format-neutral exact-capacity path construction | ✓ VERIFIED | Exists, substantive, and wired by `Type2PathSink::new`; negative capacity is deterministically rejected before allocation. |
| `modules/mb-font/font/cff_type2_path.mbt` | Exact cubic path sink and one-commit selected query | ✓ VERIFIED | Contains checked rational conversion, native command emission, exact `CffPathCharge`, selected-GID execution, final guard, and sole query commit. |
| `modules/mb-font/font/cff_type2_bounds.mbt` | Shared geometry/contour lifecycle for bounds and paths | ✓ VERIFIED | The same absolute fixed-point state feeds compact bounds and optional `Type2PathSink`; pending-move and non-empty-close logic are shared. |
| `modules/mb-font/font/cff_type2.mbt` | Sole VM plus compact per-GID counts/work | ✓ VERIFIED | One interpreter loop; all-glyph admission retains counts/work while selected query reuses one descriptor and the same loop. Review fix preflights instruction work before observing the byte. |
| `modules/mb-font/font/cff_admission.mbt` | Complete atomic CFF aggregate with common facts | ✓ VERIFIED | Retains directory, required tables, hmtx facts, bounds/counts/work, opening revision, directory start, and CFF offset; combines structural/type2 charge before one atomic commit. |
| `modules/mb-font/font/tables.mbt`, `kern.mbt` | Outline-neutral common table/kern admission | ✓ VERIFIED | CFF supplies its decoded maxp facts to the common helper; cumulative kern authority is preflighted before traversal. Existing glyf wrapper remains present. |
| `modules/mb-font/font/font.mbt` | Opaque projection and closed query dispatch | ✓ VERIFIED | Standalone and collection CFF both use `font_from_admitted_cff1`; cardinality, metrics, common queries, and outlines dispatch privately by `FontOutlineSource`. |
| `modules/mb-font/font/collection.mbt` | Closed selected-face dispatch | ✓ VERIFIED | `StaticGlyf` retains its existing adapter, `Cff` uses the shared CFF adapter, and unsupported variants retain the established error. |
| Phase 106 public/white-box tests | Behavioral, resource, mutation, TTC, and compatibility evidence | ✓ VERIFIED | All named spot-checks below pass; tests are normal `*_test.mbt`/`*_wbtest.mbt` package inputs. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| standalone `OTTO` bytes | opaque `Font` | `Font::open` → `admit_cff1_structure` → `font_from_admitted_cff1` | ✓ WIRED | Complete admitted facts cross the private boundary; public signature is unchanged. |
| `Font::outline` CFF arm | sole Type 2 VM | retained descriptor/count/work → `type2_execute_glyph_with_path_capacity` | ✓ WIRED | One selected descriptor, exact preflight, one VM execution. |
| Type 2 geometry | bounds and path | `Type2BoundsSink` with optional `Type2PathSink` | ✓ WIRED | Identical current-point, matrix, contour, and command semantics feed both outputs. |
| CFF metrics | public horizontal metrics | face-local `hmtx` + retained bound → `font_lookup_cff_horizontal_metrics` | ✓ WIRED | CharString width is not referenced by public metric lookup. |
| selected collection face | shared CFF admission | retained root/revision/directory/count → `font_open_cff_collection_face` | ✓ WIRED | No copied or rebased face buffer is constructed. |
| selected CFF common tables | public queries | each face's `RequiredTableFacts` → opaque `Font` fields | ✓ WIRED | Shared outline bytes do not replace face-local cmap/hmtx/kern/head/hhea/OS2. |
| staged path | public return | post-stage probe → final revision guard → one charge → `Ok(path)` | ✓ WIRED | No callback, allocation, validation, conversion, or other fallible operation follows the charge. |
| static-glyf profile | existing implementation | unchanged `font_open_collection_face` and `font_decode_outline` arms | ✓ WIRED | Both standalone and selected public compatibility fingerprints pass. |

## Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `font.mbt` | mapping/line/metric/kern facts | selected face directory's admitted common tables | Yes; two-face fixture returns deliberately different face-local values | ✓ FLOWING |
| `cff_type2_path.mbt` | ordered `PathCommand`s | selected admitted CharString + local/global subrs + exact matrix | Yes; literal cubic controls/end and line/flex/multi-contour commands are asserted | ✓ FLOWING |
| `cff_admission.mbt` | compact bounds/count/work | ascending all-GID execution through the sole VM | Yes; arrays align with admitted descriptor cardinality | ✓ FLOWING |
| collection CFF adapter | root/revision/face facts | retained `FontCollection` source and `CollectionFaceFacts` | Yes; selected font retains the same root length/revision and face-local facts | ✓ FLOWING |

## Final Code-Review Fix Re-verification

| Fix/concern | Status | Independent evidence |
|---|---|---|
| Public CFF operation neutrality | ✓ VERIFIED | `font_rebind_operation` preserves category/code/payload/context while rebinding `font-open`, `font-outline`, or `font-collection-open-face`; focused public test passes. |
| Static-glyf precedence and behavior | ✓ VERIFIED | Static branch remains the original call path; `outline.mbt` has no Phase 106 diff; two public fingerprints and full native suite pass. |
| Cumulative CFF kern authority | ✓ VERIFIED | `kern_base_work` seeds the ledger and the sum of subtable/pair work is preflighted cumulatively; focused regression passes. |
| No mutable staged-path callback | ✓ VERIFIED | `after_stage` has type `() -> Unit`, never receives `Path2`; mutation tests still pass. |
| Independent resource goldens | ✓ VERIFIED | Literal exact values are frozen in collection/path/type2 tests; production charges are not the only oracle. |
| Selected-outline work before execution | ✓ VERIFIED | Retained `path_work` enters exact charge and `budget.preflight` before `type2_execute_glyph_with_path_capacity`; focused no-execution regression passes. |
| Deferred Type 2 work before byte read | ✓ VERIFIED | `preflight_instruction` runs before `read_probe`/`source.get`, then `accept_preflighted_instruction` advances the private ledger only after a successful read; caller and ancestor one-short tests pass. |
| Negative path capacity | ✓ VERIFIED | `Path2::with_capacity` returns `InvalidInput/InvalidRange` before `Array::new`; focused test passes. |
| Maximum single allocation | ✓ VERIFIED | Retained bounds/count/work sizes are compared by maximum, then compared with scratch allocation size; focused exact/one-short test passes. |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Standalone opaque Font + exact cubic | named `Phase 106 standalone CFF1 opens and publishes one native cubic path` | 1 passed | ✓ PASS |
| Exact caller/ancestor outline authority | named `CFF outline exact path charge covers caller and ancestor dimensions` | 1 passed | ✓ PASS |
| Shared CFF bytes + face-local facts | named `Phase 106 selected CFF1 shares cubic bytes and retains face local facts` | 1 passed | ✓ PASS |
| Collection root/opening revision | named `Phase 106 selected CFF1 retains collection root and opening revision authority` | 1 passed | ✓ PASS |
| Standalone static-glyf fingerprint | named `Phase 106 preserves the public standalone static glyf fingerprint` | 1 passed | ✓ PASS |
| Selected static-glyf fingerprint | named `Phase 106 preserves the public selected static glyf fingerprint` | 1 passed | ✓ PASS |
| Caller/ancestor pre-read work authority | two named `Type 2 ... one-short stops before the unauthorized VM read` tests | 2 passed | ✓ PASS |
| Selected outline pre-execution work | named `CFF outline work preflight prevents caller and ancestor VM execution` | 1 passed | ✓ PASS |
| Cumulative kern authority | named `seeded CFF kern authority rejects cumulative work before pair traversal` | 1 passed | ✓ PASS |
| Public error operation neutrality | named `public CFF boundaries keep format-neutral operation names` | 1 passed | ✓ PASS |
| Negative capacity | named `path2 negative capacity is rejected deterministically` | 1 passed | ✓ PASS |
| Maximum single retained allocation | named `Type 2 retained arrays use the maximum single allocation` | 1 passed | ✓ PASS |
| Pre/post/fetch mutation atomicity | two named atomic mutation tests | 2 passed | ✓ PASS |
| Overflow/count mismatch atomicity | named `CFF outline exact path charge rejects overflow and count mismatch atomically` | 1 passed | ✓ PASS |
| Complete native regression | `moon test --target native` | 1281/1281, independently observed by orchestrator | ✓ PASS |
| Four-target static check | `moon check --target all` | 0 errors, independently observed by orchestrator | ✓ PASS |

## Prohibition Verification

The PLAN files use the legacy `verification: flagged` spelling. Each item was resolved with deterministic source/diff/test evidence; none requires visual or external human judgment.

| Prohibition | Status | Evidence |
|---|---|---|
| No public CFF-specific API/limit | ✓ VERIFIED | Only added public symbol is format-neutral `Path2::with_capacity`. |
| No second VM, retained full path, or replay stream | ✓ VERIFIED | One VM loop; admitted facts retain only bounds/count/work. |
| No cubic-to-quadratic conversion or flattening | ✓ VERIFIED | No `QuadTo` in CFF production scope; literal native `CubicTo` tests pass. |
| No Type 2 width as public metric authority | ✓ VERIFIED | Public CFF metrics read face-local hmtx and retained bounds only. |
| No widened CFF2/variation/seac/rendering/FFI/I/O scope | ✓ VERIFIED | Closed profile/operator dispatch and no new dependency/FFI/I/O surface. |
| No query-time CFF structural reparse | ✓ VERIFIED | Query consumes retained descriptor/subrs/matrix/count/work directly. |
| No sink/VM budget commit or partial geometry | ✓ VERIFIED | Query commit occurs only in `cff_type2_path.mbt`; path stays private until success. |
| No bounds reconstruction of outlines | ✓ VERIFIED | Path comes from selected VM execution; retained bounds are used only for metrics. |
| No glyf semantic/charge change | ✓ VERIFIED | Original arms/formulas remain; focused fingerprints and full suite pass. |
| No selected-face copy/rebase or parallel parser | ✓ VERIFIED | Same root `ByteView` and shared admission function are used with face directory facts. |
| No duplicate/overlap collection policy change | ✓ VERIFIED | `collection_parser.mbt` is outside the Phase 106 diff; existing collection tests pass in the full suite. |

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| CFF-04 | 106-01, 106-02, 106-03 | Opaque standalone Font, format-neutral common behavior/errors, and atomic native cubic Path2 | ✓ SATISFIED | Truths 1–2 and 5–10; literal public path/error tests plus exact resource/mutation matrices. |
| CFF-05 | 106-03 | Shared selected TTC/OTC implementation, coordinate authority, face-local facts, frozen glyf | ✓ SATISFIED | Truths 3–4 and 11–12; production trace plus selected CFF/root/revision/parity/glyf tests. |

No Phase 106 requirement is orphaned. `REQUIREMENTS.md` maps exactly CFF-04 and CFF-05 to Phase 106.

## Anti-Patterns and Disconfirmation Pass

No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, unimplemented marker, empty production implementation, public CFF API, second Type 2 loop, CFF `QuadTo`, or retained `Path2` was found in the 22-file implementation/test diff.

Three fixture variables named `placeholder_top` are same-size offset-layout calculations that are immediately replaced by finalized Top DICT bytes; they do not flow to public/runtime output and are not stubs.

The broad public standalone and selected tests alone do not prove atomic authority or revision ordering. Separate named white-box tests were therefore run for caller/ancestor one-short windows, pre-read work, mid-fetch/post-stage mutation, overflow/count mismatch, cumulative kern work, and maximum-single-allocation authority. The selected root-authority assertion alone is also coarse; production tracing independently shows root-relative directory parsing followed by table-local `cff.view` parsing. No contradictory or uncovered must-have remained after these checks.

## Probe Execution

No phase probe scripts or deferred `<human-check>` blocks are declared. Probe execution is not applicable.

## Human Verification Required

None. Every goal truth is deterministic library behavior with direct source wiring and passing named automated evidence.

## Gaps Summary

No gaps found. CFF-04 and CFF-05 are satisfied, all 12 merged must-haves are verified, the final code-review fixes remain closed, and no static-glyf regression or public CFF-specific surface was observed.

---

_Verified: 2026-07-28T22:25:33Z_
_Verifier: the agent (gsd-verifier)_
