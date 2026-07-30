---
phase: 108-public-contract-and-transaction-skeleton
verified: 2026-07-30T00:55:24Z
status: passed
score: 20/20 must-haves verified
behavior_unverified: 0
overrides_applied: 0
prohibitions_verified: 13
prohibitions_flagged: 0
next_action: "Verification passed — continue."
next_command: ""
---

# Phase 108: Public Contract and Transaction Skeleton Verification Report

**Phase Goal:** Library authors have a stable format-neutral shaping contract whose prepared values can cross the opaque font/text boundary and publish only after one combined authority commit.
**Verified:** 2026-07-30T00:55:24Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Roadmap Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Callers can express the closed, format-neutral shaping request without ambient discovery, normalization, bidi, I/O, or raw OpenType state. | ✓ VERIFIED | Fresh generated interfaces expose only `shape(Font, Array[Int], ShapingOptions, ShapeLimits, Budget)`, closed direction/language/feature types, and two required limits. `modules/mb-text/text/{tags,options,limits,shape}.mbt` enforce exact four-byte tags, scalar validation, request-owned input copying, and the closed `liga`/`kern` controls with required behavior non-disableable. |
| 2 | The immutable run exposes only same-font opaque glyph identities, scalar clusters, checked signed design-unit positioning, UPEM, direction, and checked total advance. | ✓ VERIFIED | `modules/mb-font/font/font.mbt` binds every `GlyphId` to its owning `Font`; `modules/mb-text/text/run.mbt` copies private records and provides only value accessors. `shape.mbt` uses checked signed projection and summation. Foreign-font, signed-boundary, offset, and copy-isolation tests passed on all four targets. |
| 3 | Generated cases freeze empty, LTR/RTL, ligature-cluster, validation, and error-stage precedence behavior. | ✓ VERIFIED | The 20-test `mb-text/text` suite passed independently on `js`, `wasm`, `wasm-gc`, and `native`. It exercises empty input, logical LTR/final-only RTL reversal, signed deltas, minimum-source ligature clusters, malformed input, combined faults, and every named mutation seam. |
| 4 | Prepared work is discarded without authority change or published after one checked aggregate charge, with no second commit or leaked raw state. | ✓ VERIFIED | `modules/mb-font/font/shape_transaction.mbt` keeps the scope private, closes it with `defer`, checked-composes charges, preflights, performs the final revision guard, invokes exactly one `budget.charge(combined)`, and then only returns the staged value. Transaction, one-short, ancestor, overflow, scope-escape, error-path, and mutation tests passed in the fresh 284-test `mb-font/font` suite on all four targets. |

### Locked Decision Coverage

| Decision | Required outcome | Status | Code/test evidence |
|---|---|---|---|
| D-01 | One closed `shape` operation; no public builder/session. | ✓ VERIFIED | Fresh `modules/mb-text/text/pkg.generated.mbti`; interface-leakage policy gate. |
| D-02 | Ordered scalar input, full validation, request-owned snapshot. | ✓ VERIFIED | `shape.mbt` validates every scalar before `scalars.copy()` and before font work; mutation tests pass. |
| D-03 | Opaque immutable run and glyph records with indexed value access only. | ✓ VERIFIED | `run.mbt`; generated interface contains no arrays, views, offsets, lookup records, or layout profiles. |
| D-04 | Same-font glyph, scalar cluster, checked signed positioning, UPEM/direction/total. | ✓ VERIFIED | `font.mbt`, `run.mbt`, `shape.mbt`; ownership and projection tests pass. |
| D-05 | Logical shaping for both directions; final-only RTL record reversal. | ✓ VERIFIED | `shape.mbt` projects in logical order and reverses only final records; exact LTR/RTL tests pass. |
| D-06 | Signed pen deltas and checked total advance. | ✓ VERIFIED | `shape.mbt` uses `checked_add_i64`/`checked_neg_i64`; boundary and total tests pass. |
| D-07 | Offsets remain signed design-space values, not screen coordinates. | ✓ VERIFIED | Offsets are copied unchanged during RTL projection; extreme-offset tests pass. |
| D-08 | Scalar-origin clusters; ligatures use minimum consumed source index. | ✓ VERIFIED | Generated-fact validation and adjacency/ligature tests cover bounds and minimum clusters. |
| D-09 | Exact four-byte tags and explicit closed language/direction. | ✓ VERIFIED | `tags.mbt` copies and validates four printable bytes; `options.mbt` has only explicit closed variants. |
| D-10 | Closed `liga`/`kern`; required behavior non-disableable. | ✓ VERIFIED | `FeaturePolicy` has only two private booleans; no arbitrary tags, ranges, values, or variation coordinates in the public interface. |
| D-11 | Valid empty input succeeds through guarded metadata and one exact fixed charge. | ✓ VERIFIED | Empty path enters `with_shape_transaction`, reads UPEM, stages an empty run, and charges exact text work once; exact/one-short/revision tests pass. |
| D-12 | Caller-contract failures do not degrade into capability fallbacks. | ✓ VERIFIED | Scalar/tag/limit/foreign-glyph validation exists and combined-fault tests prove precedence. |
| D-13 | Ownership split and DAG remain `mb-text -> mb-font -> mb-core`. | ✓ VERIFIED | Module manifests, `moon.work`, package imports, source inventory, and reverse-edge scan all match; no `mb-font -> mb-text` edge. |
| D-14 | One private aggregate transaction, one preflight/final guard/charge/publication. | ✓ VERIFIED | `shape_transaction.mbt`; exact charge, one-short, hierarchy, captured-scope, and mutation tests pass. |
| D-15 | Stable InvalidInput → State → Data → Capability → Resource precedence. | ✓ VERIFIED | Current source orders provenance/structure before transaction capability and arithmetic/resource after capability; review-fix combined-fault regressions pass on four targets. |
| D-16 | Stable `CoreError` categories/codes and generic operation/context strings. | ✓ VERIFIED | Public paths use structured `CoreError`; snapshots and stage-matrix tests pass. No future table/lookup-specific public diagnostic is exposed. |

**Score:** 20/20 merged truths verified (4 roadmap truths + D-01 through D-16; 0 present-but-behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-text/moon.mod.json`, `modules/mb-text/text/moon.pkg.json`, `moon.work` | Independent portable module with exact dependency direction | ✓ VERIFIED | Module is `tchivs/mb-text@0.1.0`, supports all four targets, and depends only on exact `mb-core` and `mb-font` versions. |
| `modules/mb-text/text/tags.mbt` | Exact script/language tags | ✓ VERIFIED | Private copied bytes; exactly four printable bytes; language rejects `dflt`/`DFLT`. |
| `modules/mb-text/text/options.mbt`, `limits.mbt` | Closed options and bounded limits | ✓ VERIFIED | Explicit language/direction, two feature booleans, and two nonzero checked limits. |
| `modules/mb-text/text/run.mbt` | Immutable public value run | ✓ VERIFIED | Private fields, copied records, checked indexed access, no mutable backing view. |
| `modules/mb-text/text/shape.mbt` | Request validation, staging, projection, and public call | ✓ VERIFIED | Substantive implementation with scalar snapshot, generated-fact validation, checked arithmetic, final-only RTL reversal, and capability fallback for unsupported nonempty shaping. |
| `modules/mb-font/font/font.mbt` | Same-font glyph authority | ✓ VERIFIED | `GlyphId` stores a private owner and value; font operations reject distinct same-range glyphs before selected work. |
| `modules/mb-font/font/shape_transaction.mbt` | Opaque transaction and sole aggregate commit | ✓ VERIFIED | Private active scope, checked composition, ancestor preflight, final revision guard, one charge, and guaranteed close. |
| `modules/mb-core/budget/budget.mbt`, `modules/mb-core/checked/checked.mbt` | Checked immutable charge and signed arithmetic | ✓ VERIFIED | Every charge field is checked; hierarchy preflight precedes hierarchy commit; signed add/negation/conversion reject boundaries. |
| `modules/mb-text/text/pkg.generated.mbti`, `modules/mb-font/font/pkg.generated.mbti` | Closed generated public interfaces | ✓ VERIFIED | Regenerated successfully for all targets; no private fixtures, prepared values, probes, raw authority, or extra commit API escaped. |
| `scripts/quality/Assert-Policy.ps1` and policy inventories | Fail-closed module/API/scope gates | ✓ VERIFIED | Fresh policy run exited 0; exact source/interface inventory and no-leakage/no-external/no-qualification-overclaim checks are active. |

The GSD artifact checker independently reported 23/23 declared artifacts substantive across all five plans. Manual source inspection supplied the wiring and behavioral evidence above; file existence alone was not accepted.

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `shape.mbt` | `Font::with_shape_transaction` | public request enters guarded opaque font authority | ✓ WIRED | Empty publication and private generated contract path both use the transaction boundary. |
| `shape_transaction.mbt` | `Budget::charge` | checked aggregate preflight + final revision guard | ✓ WIRED | Exactly one `.charge(combined)` call exists in the text/font transaction path; no fallible work follows it. |
| `FontShapeScope` | `Font` operations | active-scope and revision checks | ✓ WIRED | Every public scope operation validates active state before revision-bound font work. |
| `GlyphId` | `ShapedRun` | owner validation before generated fact publication | ✓ WIRED | Foreign generated glyphs fail before transaction/capability work; regression passes. |
| `ResourceCharge::checked_add` | caller and ancestor budgets | one composite authority debit | ✓ WIRED | Field-wise checked composition feeds hierarchy-wide preflight and commit. |
| `mb-text` | `mb-font` | exact manifest/package import | ✓ WIRED | No reverse import or module cycle found. |

The GSD key-link checker reported 13/13 declared links verified across the five plans.

## Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| `shape.mbt` | scalar snapshot/options/limits | caller request after complete validation and copy | Yes | ✓ FLOWING |
| `shape.mbt` | positioned records | private generated facts validated against font ownership and cluster bounds | Yes | ✓ FLOWING |
| `run.mbt` | glyph records and total | checked projection copied into private immutable storage | Yes | ✓ FLOWING |
| `shape_transaction.mbt` | combined charge | immutable font-side + text-side `ResourceCharge` | Yes | ✓ FLOWING |
| `budget.mbt` | caller/ancestor authority | composite preflight followed by single hierarchy commit | Yes | ✓ FLOWING |

No dynamic UI/data-rendering artifact exists in this phase; the relevant Level-4 trace is authority and value flow rather than a frontend fetch path.

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Public shaping contract and stage matrix | `moon -C modules/mb-text test text --target all --frozen` | 20/20 passed on each of `js`, `wasm`, `wasm-gc`, `native` | ✓ PASS |
| Font ownership and aggregate transaction behavior | `moon -C modules/mb-font test font --target all --frozen` | 284/284 passed on each target | ✓ PASS |
| Checked charge and signed arithmetic foundation | `moon -C modules/mb-core test budget checked --target all --frozen` | 36/36 passed on each target | ✓ PASS |
| Workspace test roster | `moon test --target all --frozen --outline` | 1326 tests enumerated for each target (5304 entries) | ✓ PASS (enumeration) |
| Generated public interfaces | `moon -C modules/mb-text info --target all --frozen`; `moon -C modules/mb-font info --target all --frozen` | Both exited 0; 34 inherited CFF warnings, 0 errors | ✓ PASS |
| Repository policy | `./scripts/quality/Assert-Policy.ps1` | Exit 0 | ✓ PASS |
| Fresh cross-target font qualification | `./scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/phase108-verification` | Four target records passed; normalized semantic equality true; digest `80b9f93b381a38d6f2c4a15abb1fab63da10cdc1f89513190d55a2f6cc4751a9` | ✓ PASS |
| External API coverage gate | `gsd-tools check api-coverage.verify-pre .planning/phases/108-public-contract-and-transaction-skeleton --raw` | Passed; no external-API integration detected, matrix not required | ✓ PASS |

The one fresh aggregate `moon test --target all --frozen` execution outlived the five-minute command harness and finished after its parent capture timed out, so no aggregate exit summary was retained. The report does not misstate that run as a captured 1326/1326 pass. The exact 1326-per-target roster was independently enumerated, and every Phase-108 behavior-dependent truth is directly exercised by the fresh green `mb-text`, `mb-font`, and `mb-core` suites above.

## Probe Execution

No `probe-*.sh` path is declared by the phase plans or summaries. The canonical executable qualification for the affected authority boundary is the fresh `FontQualification` lane recorded above; it completed with four passing target records and the required digest.

## Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
|---|---|---|---|---|
| TXT-01 | 108-01 through 108-05 | Stable format-neutral shaping request and immutable prepared run contract | ✓ SATISFIED | Closed generated interface, immutable run implementation, same-font glyph authority, checked projection, and four-target contract tests. |
| TXT-02 | 108-02 through 108-05 | Atomic prepared-value publication across the opaque font/text boundary | ✓ SATISFIED | Private continuation, checked aggregate charge, hierarchy preflight, final revision guard, sole commit, scope closure, and four-target transaction tests. |

No additional requirement is mapped to Phase 108 in `REQUIREMENTS.md`; there are no orphaned phase requirements.

## Prohibition Verification

All 13 plan prohibitions have deterministic source, interface, policy, or test enforcement. None is silently treated as passed without evidence.

| # | Prohibition | Status | Enforcement evidence |
|---|---|---|---|
| 1 | No GSUB/GPOS/GDEF/legacy-kern parser or executor. | ✓ VERIFIED | Source/interface inventory and scope scans; public nonempty shaping returns capability-unavailable. |
| 2 | No public prepared/commit/raw/source/mutable-run/cache surface. | ✓ VERIFIED | Fresh generated interfaces and fail-closed leakage policy. |
| 3 | No separate font/text charges or publication before the guard. | ✓ VERIFIED | Single aggregate transaction code and exact/one-short/mutation tests. |
| 4 | No ordinary signed arithmetic, MIN negation, lossy conversion, or reinterpretation as proof. | ✓ VERIFIED | Projection uses checked helpers; boundary tests pass. |
| 5 | Numeric glyph range alone cannot establish same-font authority. | ✓ VERIFIED | Owner identity check plus alias/distinct-font tests. |
| 6 | No usable escaped scope, probe, charge mutator, raw view, or commit API. | ✓ VERIFIED | Private scope construction; inactive captured/returned scope tests; generated interface gate. |
| 7 | No independent font commit, callback after commit, or reverse dependency. | ✓ VERIFIED | One callback before one charge; manifest/DAG checks. |
| 8 | No mutable arrays/views or public raw generated facts/source capability. | ✓ VERIFIED | Run and fixture storage are private/copying; interface gate. |
| 9 | No input reversal, offset negation, byte/grapheme clusters, implicit cluster merge, or unchecked projection. | ✓ VERIFIED | Projection implementation and exact LTR/RTL/cluster/offset tests. |
| 10 | No successful public nonempty run without layout authority. | ✓ VERIFIED | Public nonempty path is explicit capability-unavailable. |
| 11 | No reverse edge, path dependency, manifest migration, native FFI, external SDK, or registry integration. | ✓ VERIFIED | Exact manifests, `moon.work`, source scan, policy, and API-coverage gate. |
| 12 | No public raw arrays/source/table/lookup/probes/scope constructor/commit. | ✓ VERIFIED | Generated interfaces plus public-interface policy. |
| 13 | No documentation claim of semantic qualification or successful nonempty real-font shaping. | ✓ VERIFIED | README/policy wording explicitly identifies the skeleton/capability boundary; qualification evidence is scoped to the font foundation. |

## Review-Fix Verification

The final code-review ledger is clean (0 open findings). The five remediation commits were inspected rather than accepted from their summaries:

- transaction inputs are included in source qualification;
- foreign generated glyphs are rejected;
- generated clusters are bounds-checked;
- `mb-text` README metadata is policy-required;
- generated-fault ordering now implements the locked stage matrix.

`git show --check` is clean for all five commits. The final precedence fix adds combined-fault regressions, and those regressions passed in the fresh 20/20 four-target `mb-text` run.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| — | — | No unreferenced `TBD`, `FIXME`, or `XXX`; no incomplete handler, empty implementation, user-visible placeholder, or console-only path found in phase-modified files. | None | No blocker or warning. |

The few literal `placeholder` occurrences are a computed local name in an existing CFF offset-sizing test, documentation rejecting placeholder success, and a policy rule that forbids placeholder evidence; none is an implementation stub.

## Adversarial Disconfirmation

- A façade-only API with hidden raw authority was sought and not found: fresh generated interfaces and the exact policy inventory close the boundary.
- A nominal “single charge” with a hidden second commit or fallible post-commit work was sought and not found: the transaction contains one charge and then only `Ok(value)`.
- Incorrect stage precedence despite green happy-path tests was specifically checked. The prior review finding is fixed in current source and exercised by combined-fault regressions on all four targets.
- UI/layout-engine scope creep was sought and not found: no frontend artifacts, external service integration, layout parser/executor, native FFI, or real-font nonempty shaping claim entered this phase.

## Human Verification Required

None. All behavior-dependent state transitions and ordering invariants in the phase goal have named tests that passed on all four targets. The phase contains no visual UI, realtime flow, or external-service behavior.

## Gaps Summary

No gaps. The stable format-neutral public contract, same-font immutable run projection, generated stage matrix, and one-commit authority boundary all exist, are wired, and have direct behavioral evidence. Phase 108 is ready to proceed.

---

_Verified: 2026-07-30T00:55:24Z_
_Verifier: the agent (gsd-verifier)_
