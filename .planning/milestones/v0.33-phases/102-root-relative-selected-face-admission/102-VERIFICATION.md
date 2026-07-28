---
phase: 102-root-relative-selected-face-admission
verified: 2026-07-28T03:43:46Z
status: passed
score: 14/14 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 102: Root-Relative Selected-Face Admission Verification Report

**Phase Goal:** Library authors can select one supported static TrueType face from an admitted collection and use the existing opaque `Font` contract unchanged.
**Verified:** 2026-07-28T03:43:46Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

The four ROADMAP success criteria are retained as truths 1–4. The fifteen PLAN truth declarations were merged and deduplicated into truths 5–14; no PLAN truth reduced the ROADMAP contract.

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Any in-range static `glyf`-based TrueType face yields the existing `Font`, with metrics, Unicode mapping, kerning, glyph identity, and unhinted outlines equivalent to the standalone logical font. | ✓ VERIFIED | `FontCollection::open_face` returns `Result[Font, CoreError]` and publishes through the same private `font_from_admitted_facts` constructor as standalone open (`collection.mbt:152-216`, `font.mbt:97-130,245-254,317-326`). The named public equivalence test compares units-per-em, bounds, both line metrics, BMP/supplementary mapping, glyph identity, full horizontal metrics, kerning hit/miss, and exact `Path2` commands/coordinates (`collection_test.mbt:810-936`). It passed on all four targets. |
| 2 | Valid selected faces work with table bytes before or after a non-zero face directory because table offsets are collection-root-relative. | ✓ VERIFIED | Directory-local fields add `directory_start`, but `table_offset` is read unchanged and passed directly to `checked_font_table_view(source, table_offset, table_length)` (`directory.mbt:445-460,517-584,606-735`). The generated public fixture deliberately places `loca` at root offset 32 before directory 256 and all other tables after it (`collection_test.mbt:429-468`). Public and white-box root-relative tests passed on all four targets. |
| 3 | Distinct and exact shared table ranges admit without copying the retained collection root. | ✓ VERIFIED | Two face directories in the exact-sharing fixture point to the same root payload ranges (`collection_test.mbt:615-639`), while mixed-profile sibling ranges are distinct (`collection_test.mbt:643-684`). Each selected `Font` retains `self.source` and `self.opening_revision`, not a synthesized SFNT or directory subview (`collection.mbt:208-215`, `font.mbt:245-253`). Root identity and both sharing modes are behaviorally tested. |
| 4 | A supported selected face works beside unsupported CFF/CFF2 or variable siblings, with collection checksum semantics and standalone checks preserved. | ✓ VERIFIED | `open_face` gates the cached selected profile before deep admission (`collection.mbt:187-207`), so unsupported siblings are not reparsed. The mixed fixture contains CFF, CFF2, and `fvar` siblings; the static face succeeds and each unsupported selection returns Capability with no charge (`collection_test.mbt:1217-1278`). Both modes run the same table checksum loop and head-byte zeroing; only standalone runs the whole-source adjustment check (`directory.mbt:883-940`). Full standalone native regression passed 147/147. |
| 5 | One private directory seam parses at source byte zero or a non-zero absolute directory start while every `TableWindow` remains a no-copy root subview at the record's unchanged root offset. | ✓ VERIFIED | `font_parse_directory_at` is the shared core and `font_parse_directory` is its zero-base standalone wrapper (`directory.mbt:765-807`). Checked directory/table range, touching/intersection, wrong-rebase, cached-count, and overflow cases are substantive white-box tests (`collection_wbtest.mbt:555-635`). |
| 6 | Standalone and collection checksum modes share per-table checksum/head-zeroing behavior, while standalone alone retains the whole-source `0xB1B0AFBA` rule and checksum-before-final-budget precedence. | ✓ VERIFIED | `font_validate_checksums_with_mode` always calls `font_validate_table_checksums`, whose head call passes `zero_head_adjustment=true`; its mode branch alone controls the aggregate check (`directory.mbt:883-940`). The collection/standalone dispatcher test and public bad-table-checksum precedence test passed. |
| 7 | The admission ledger preserves historical standalone staged charges and gives selected admission cumulative live caller/ancestor preflights before attacker-sized traversal, while deferring the real charge. | ✓ VERIFIED | `FontAdmissionLedger::admit_stage` uses real `Budget::preflight`; collection mode requests cumulative `next_staged` and does not charge, while standalone mode retains incremental charges (`tables.mbt:93-189`). Directory and profile/checksum prefixes are staged before their loops (`font.mbt:142-211`); cmap and kern discovery preflight their declared loops (`tables.mbt:1203-1333`, `kern.mbt:302-445`); the exact remaining semantic work is staged before semantic/metric loops (`tables.mbt:540-561`). The post-review caller/ancestor hook test passed 13/13 on every target. |
| 8 | Existing `Font::open` retains its public signature and standalone success, error, precedence, checksum, and exact charge observations. | ✓ VERIFIED | The generated interface still contains exactly the inherited `Font::open(@bytes.ByteView, FontLimits, @budget.Budget) -> Result[Self, CoreError]` line. Standalone still selects `StandaloneIncremental`, validates profile/required/checksums in its historical path, and publishes through the shared constructor (`font.mbt:260-326`). The complete native package passed 147/147 after all review fixes. |
| 9 | `FontCollection::open_face(index, FontLimits, Budget)` is the only new public operation, is non-consuming/repeatable, and each success uses an independent caller-owned transaction returning the existing opaque `Font`. | ✓ VERIFIED | The facade contains exactly the one specified method (`collection.mbt:149-159`) and stores no selected-face cache (`collection.mbt:21-27`). Repeated selection with independent budgets succeeds and consumes equal independent charges (`collection_test.mbt:780-807,1587-1614`). |
| 10 | Selected Fonts retain the collection root and opening revision; mutation before/during selection or after publication—including mutate-then-restore—fails State without a partial charge. | ✓ VERIFIED | Revision is checked before index/profile (`collection.mbt:187-207`) and again after the deterministic hook but before charge/publication (`font.mbt:233-254`). The mid-selection test proves all eight budget fields unchanged, and two returned Fonts share root/revision identity (`collection_wbtest.mbt:299-408`). The public test proves all existing Font queries fail State after mutate-restore (`collection_test.mbt:1587-1642`). |
| 11 | `max_source_bytes` bounds the retained root; selected charge is `D + T`, three allocations, `max(64R, 8(G+1))`, and exact selected work; unrelated sibling payload is uncharged and every failed selection is atomic. | ✓ VERIFIED | Collection selected extent is checked directory bytes plus selected table bytes, while the source ceiling is applied to full retained root (`tables.mbt:192-212,510-571`; `directory.mbt:452-460`). Public exact/one-short tests cover source, bytes, allocations, allocation-size, max-work, caller work, and tighter ancestors with unchanged budgets (`collection_test.mbt:1282-1584`). |
| 12 | Revision, index, profile, selected authority/data, required tables, checksums, final budget, final revision, charge, and publication follow the frozen error precedence with exact structured facts. | ✓ VERIFIED | The facade order is revision → index → profile (`collection.mbt:187-207`); the selected path is staged authority → directory → profile/required/checksum → semantic plan/admission → exact preflight → final revision → charge → publication (`font.mbt:142-254`). Named public multi-fault tests assert category, code, operation, context, offsets/requested/limit, and unchanged budgets (`collection_test.mbt:939-1214,1282-1584`). |
| 13 | The generated `mb-font/font` interface has exactly 85 ordered semantic lines: the 84-line Phase 101 surface plus only the exact `open_face` signature; private/storage/deferred alternatives fail closed. | ✓ VERIFIED | Direct comparison against the pre-Phase-102 parent `67dd1481` found 85 versus 84 lines, exactly one addition, and zero removals. Current generated `pkg.generated.mbti` is an exact ordered 85-line match, ignored and untracked. The independent classifier and missing/duplicate/reorder/altered/private negative fixtures pass (`Assert-Policy.ps1:981-1092,2421-2422,2730-2850`). |
| 14 | Focused selected behavior is portable on `js`, `wasm`, `wasm-gc`, and `native`, while target-all compilation, pure-MoonBit/dependency policy, no ambient I/O/FFI, and the Phase 103 scope boundary remain intact. | ✓ VERIFIED | Verifier-run public tests passed 31/31 and white-box tests 13/13 independently on each target; `moon check --target all --frozen` completed all four targets; full native passed 147/147; `Assert-FontFoundationPolicy` passed exact interface, inventory, target, dependency, source-boundary, lexer/interpolation, and negative gates. |

**Score:** 14/14 truths verified (0 present, behavior-unverified)

## Review-Fix Audit

| Review finding | Post-fix implementation evidence | Independent result |
|---|---|---|
| CR-01: selected loops ran before caller/ancestor work authority | Fix `8195a491` stages directory, profile/checksum, cmap, kern, and remaining semantic/metric work through one live deferred ledger before dependent traversal; final charge remains after final revision. | `selected caller and ancestor authority precede every dependent loop family` passed on all four targets; full source trace confirms count-discovery loops have their own preflights and later loops are covered by the exact remaining-work preflight. |
| CR-02: comment/string sanitizer could hide forbidden source | Fixes `a89f013f` and `d8dccd6c` implement a stateful lexer for comments, literals, byte strings, raw/interpolated multiline strings, nested braces/comments, and executable interpolation frames (`Assert-Policy.ps1:1167-1427`). | Fresh policy execution passed all direct, comment-delimiter, string/bytes interpolation, multiline, nested-brace, comment-brace, escape, and raw-literal probes (`Assert-Policy.ps1:2530-2614`). |

## Required Artifacts

| Artifact | Expected | L1 Exists | L2 Substantive | L3 Wired | Status |
|---|---|---:|---:|---:|---|
| `modules/mb-font/font/directory.mbt` | Offset-aware parser and checksum modes | Yes | 941 lines; checked coordinates, ranges, table checksums, standalone aggregate | Called by standalone and selected admission | ✓ VERIFIED |
| `modules/mb-font/font/tables.mbt` | Dual-mode ledger and exact selected charge | Yes | 2165 lines; cumulative preflight, formulas, semantic plans | Used by `font.mbt` and `kern.mbt` | ✓ VERIFIED |
| `modules/mb-font/font/kern.mbt` | Ledger-aware kern traversal | Yes | 521 lines; subtable/pair ceilings and staged preflights | Called by shared admission plan | ✓ VERIFIED |
| `modules/mb-font/font/font.mbt` | Shared standalone/selected semantic admission and existing Font publication | Yes | 675 lines; complete transaction and all existing queries | Called by public `Font::open` and `FontCollection::open_face` | ✓ VERIFIED |
| `modules/mb-font/font/collection.mbt` | Exact public facade and gates | Yes | 228 lines; revision/index/profile ordering and private hooks | Exposed by generated interface; delegates to selected admission | ✓ VERIFIED |
| `modules/mb-font/font/font_test.mbt` | Standalone compatibility oracle | Yes | 5210 lines; checksum/accounting/precedence regression coverage | Full native package includes it | ✓ VERIFIED |
| `modules/mb-font/font/collection_test.mbt` | Public equivalence/sharing/precedence/accounting/mutation evidence | Yes | 2756 lines; 31 runnable black-box tests | Passed on all four targets | ✓ VERIFIED |
| `modules/mb-font/font/collection_wbtest.mbt` | Private coordinate/ledger/revision evidence | Yes | 1035 lines; 13 runnable white-box tests | Passed on all four targets | ✓ VERIFIED |
| `policy/foundation.json` | Ordered 85-line public contract and inventories | Yes | Current font package policy has exactly 85 interface lines | Consumed by policy script and generated comparison | ✓ VERIFIED |
| `scripts/quality/Assert-Policy.ps1` | Independent interface/source/dependency classifier | Yes | 3039 lines; exact allowlist, lexer, and fail-closed negatives | Fresh `Assert-FontFoundationPolicy` invocation passed | ✓ VERIFIED |

`verify.artifacts` reports 16/16 PLAN-declared artifact occurrences passed across the three plans.

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `collection.mbt` | cached `CollectionFaceFacts` | revision/index/profile-gated face selection | ✓ WIRED | Only the selected cached face is forwarded; siblings are not semantically rescanned. |
| `collection.mbt` | `font.mbt` | `font_open_collection_face` | ✓ WIRED | Passes retained root, opening revision, cached directory facts, fresh limits, and caller budget. |
| `font.mbt` | `directory.mbt` | `font_parse_directory_at(..., Collection)` | ✓ WIRED | Selected directory fields use an absolute base and table records retain root offsets. |
| `font.mbt` | `tables.mbt` | shared deferred ledger/admission plan | ✓ WIRED | Exact work/charge is produced before final preflight/revision/one charge. |
| `directory.mbt` | `mb-core/bytes` | `checked_font_table_view(source, table_offset, length)` | ✓ WIRED | Table windows are no-copy subviews of the retained root. |
| `tables.mbt` / `kern.mbt` | `mb-core/budget` | cumulative `preflight` and mode-specific charge | ✓ WIRED | Real caller and ancestors authorize each declared traversal prefix. |
| `collection_test.mbt` | public Font/FontCollection APIs | standalone-vs-selected oracle and hostile matrices | ✓ WIRED | Tests use public observations for equivalence and public `open_face` for selection. |
| `Assert-Policy.ps1` | `foundation.json` / generated interface | exact 85-line classification and sequence comparison | ✓ WIRED | Fresh policy invocation regenerated and exact-compared the ignored interface. |

`verify.key-links` reports 13/13 PLAN-declared links verified.

## Data-Flow Trace (Level 4)

| Artifact | Data | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `FontCollection::open_face` | selected face authority | retained root + opening revision + cached `CollectionFaceFacts` | Yes; generated static, shared, and mixed collections yield real selected Fonts | ✓ FLOWING |
| `Font` public queries | metrics/cmap/kern/glyph/outline facts | selected root-backed `DirectoryFacts` → shared semantic tables/metric index → existing `Font` fields | Yes; independent standalone/selected public values and path commands are equal | ✓ FLOWING |
| Selected budget transaction | D+T/allocations/allocation-size/work | selected directory/table facts + exact semantic plan → live preflights → final revision → one charge | Yes; exact success deltas and every one-short/semantic/mutation failure are asserted | ✓ FLOWING |
| Public interface policy | semantic declarations | compiler-generated `pkg.generated.mbti` → normalized lines → policy and independent classifier | Yes; exact ordered 85-line match and negative fixtures pass | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Public selected contract on `js` | `moon -C modules/mb-font test font/collection_test.mbt --target js ...` | 31/31 | ✓ PASS |
| White-box selected invariants on `js` | `moon -C modules/mb-font test font/collection_wbtest.mbt --target js ...` | 13/13 | ✓ PASS |
| Public/white-box on `wasm` | two focused commands | 31/31 and 13/13 | ✓ PASS |
| Public/white-box on `wasm-gc` | two focused commands | 31/31 and 13/13 | ✓ PASS |
| Public/white-box on `native` | two focused commands | 31/31 and 13/13 | ✓ PASS |
| Complete standalone and collection native regression | `moon -C modules/mb-font test font --target native --frozen ...` | 147/147; only pre-existing generated `Result` warning | ✓ PASS |
| Portable compilation | `moon -C modules/mb-font check --target all --frozen ...` | all four target passes finished | ✓ PASS |
| Exact interface, lexer, inventories, dependency, target, and source policy | `Assert-FontFoundationPolicy -PolicyPath ./policy/foundation.json` | both font qualification and foundation policy gates passed | ✓ PASS |
| Whitespace | `git diff --check` | exit 0 | ✓ PASS |

## Probe Execution

Step 7c: SKIPPED — no PLAN/SUMMARY probe path or conventional `probe-*.sh` exists for this library phase.

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| TTC-02 | 102-01, 102-02, 102-03 | Select an in-range static `glyf` face into the existing opaque `Font` with standalone-equivalent metrics, mapping, kerning, glyph identity, and unhinted outlines. | ✓ SATISFIED | Truths 1, 8–13; exact public method; full public equivalence test; repeated independent transactions; mutation and atomicity tests; exact one-line interface advance. |
| TTC-03 | 102-01, 102-02, 102-03 | Resolve offsets from collection root, preserve exact sharing, enforce collection checksums, and isolate supported selection from unsupported siblings. | ✓ SATISFIED | Truths 2–7, 10–12, 14; root-relative fixtures; exact sharing; mixed CFF/CFF2/variable siblings; checksum dispatcher; selected accounting and staged authority. |

No orphaned Phase 102 requirement exists: all three PLANs declare both TTC-02 and TTC-03, and REQUIREMENTS.md maps only those two IDs to Phase 102. TTC-04/TTC-05 and broad licensed/release qualification are explicitly Phase 103.

## Prohibition Verification

| Prohibition | Status | Evidence |
|---|---|---|
| No extra public selected type/query/storage/parser/range/source handle, cache, or consuming operation. | ✓ VERIFIED | Exact 84→85 interface diff contains only `open_face`; `FontCollection` fields contain no face cache; independent forbidden-interface fixtures pass. |
| No collection copy/materialized SFNT, directory-relative table rebasing, disabled per-table checksum, or standalone whole-root rule applied to collection mode. | ✓ VERIFIED | Selected Font retains root/revision; unchanged record offsets feed root subviews; both modes share table checks; collection alone skips aggregate adjustment. |
| No failed selected transaction charges any budget dimension or publishes a partial Font. | ✓ VERIFIED | All failure matrices snapshot all eight budget fields; final hook/revision precedes the one charge and construction. |
| Standalone `Font::open` signature, checksum adjustment, structured behavior, and charge model remain intact. | ✓ VERIFIED | Exact inherited interface line, standalone-mode source trace, named checksum oracle, and fresh 147/147 native package result. |
| No CFF/CFF2/variation execution, WOFF path, DSIG trust, authoring/materialization, shaping, bidi, hinting, rasterization, FFI, ambient I/O, new module, or dependency. | ✓ VERIFIED | Unsupported profiles stop at cached Capability gate; package remains pure MoonBit with only `mb-core`; source-boundary lexer and negative gates pass; no module/manifests added. |
| `pkg.generated.mbti` remains ignored, untracked compiler output. | ✓ VERIFIED | `git check-ignore` resolves `.gitignore:4`; `git ls-files` has no entry; generation hash remained unchanged during verification. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `scripts/quality/Assert-Policy.ps1` | 227 | Literal regex text includes `placeholder`, `todo`, and `tbd` | ℹ️ Info | This is a fail-closed policy rejection rule, not a debt marker or runtime stub. |

No scoped source contains an unresolved `TBD`, `FIXME`, `XXX`, executable placeholder, empty implementation, skipped selected test, or hardcoded-empty shipped result.

## Confirmation-Bias Counter

- **Partial-requirement candidate:** the mixed unsupported-sibling fixture is focused generated evidence rather than a licensed/broad hostile release corpus. ROADMAP explicitly assigns licensed and broad release qualification to Phase 103, so this does not reduce TTC-02/TTC-03 or Phase 102's focused collection behavior.
- **Potentially misleading test:** `selected caller and ancestor authority precede every dependent loop family` exposes only three coarse callbacks (`directory`, `profile-checksum`, `semantic`), not one callback per inner loop. Source tracing independently confirms cmap-record/format-4 and kern subtable/pair discovery have their own live-ledger preflights, while the exact remaining-work preflight occurs before all later cmap/name/post/glyph/loca/metric loops.
- **Uncovered branch search:** there is no dedicated selected-face two-fault test for every individual `name`/`post` malformed branch against a short caller budget. Those branches execute only after the exact aggregate remaining-work preflight, their standalone semantic tests remain in the 147-test package, and Phase 103 owns the broad hostile matrix. This is an informational coverage note, not a goal gap.

## Human Verification Required

None. This is deterministic pure-MoonBit library behavior with no visual, real-time, external-service, performance-feel, or judgment-tier prohibition. Every state-transition, ordering, mutation, and atomicity truth has a passing behavioral test.

## Gaps Summary

No blocking or warning gaps remain. All ROADMAP outcomes, merged PLAN truths, TTC-02/TTC-03, D-01–D-17, artifacts, key links, selected data flow, resource preflights, exact error precedence, mutation atomicity, root-relative sharing/checksums, standalone compatibility, exact public interface, post-review policy classifier, and focused four-target behavior are verified against the actual codebase.

---

_Verified: 2026-07-28T03:43:46Z_
_Verifier: the agent (gsd-verifier)_
