---
phase: 105-bounded-type-2-validation-and-retained-metrics
verified: 2026-07-28T16:19:18Z
status: gaps_found
score: 1/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
requirement_score: 0/3 satisfied
requirements:
  - id: T2-01
    status: blocked
    reason: "The production xorshift32 output uses the low 16 state bits, contradicting the locked project-owned high16(state)+1 mapping; the golden test currently freezes the wrong sequence."
  - id: T2-02
    status: blocked
    reason: "Several decode/fetch/EOF failures return directly from the VM loop instead of passing through the final revision-preference guard, so mutation is not guaranteed to dominate every simultaneous non-State error."
  - id: CFF-03
    status: blocked
    reason: "The bounds sink omits a later contour's moveto/start point once an earlier contour has emitted a segment, allowing retained bounds to under-bound valid multi-contour geometry."
gaps:
  - truth: "Supported Type 2 behavior, including project-owned random, produces the locked deterministic fixed-point results."
    status: failed
    reason: "Type2Prng::next emits (low16(state) + 1), while Phase 105 D-04 requires (high16(state) + 1). For seed 0x12345678 the first state is 0x87985AA5: required output 34713, implemented/tested output 23206."
    artifacts:
      - path: "modules/mb-font/font/cff_type2_fixed.mbt"
        issue: "Line 228 selects state & 0xFFFF instead of state >> 16."
      - path: "modules/mb-font/font/cff_type2_fixed_wbtest.mbt"
        issue: "Lines 98-115 freeze low-bit outputs [23206, 9380, 62661, 44185], so the passing test is misleading evidence."
    missing:
      - "Implement the locked high16(state)+1 output mapping."
      - "Replace the low-bit golden sequence and retain reset/order-independence coverage."
  - truth: "CFF admission retains one truthful conservative integer bound per GID."
    status: failed
    reason: "After the first contour has segments, a subsequent contour start is never included in the hull. A later moveto can be the glyph extreme while its first line/curve returns inward, producing a retained bound that is not conservative."
    artifacts:
      - path: "modules/mb-font/font/cff_type2_bounds.mbt"
        issue: "move_relative records the contour start but does not include it; line_relative_unchecked/cubic_relative_unchecked include a segment start only when global has_segments is false."
      - path: "modules/mb-font/font/cff_type2_bounds_wbtest.mbt"
        issue: "The two-contour test asserts only point/contour/command counts and never checks a later contour-start extreme."
    missing:
      - "Track whether the current contour has emitted its first segment and include that contour start in the hull without making moveto-only glyphs non-empty."
      - "Add a multi-contour regression whose second moveto is outside all subsequent endpoints/control points."
  - truth: "Mutation and multi-fault outcomes preserve State before Resource before Capability before Data on every VM error exit."
    status: failed
    reason: "The main VM loop has direct error returns after its entry revision check. A mutation racing a byte/number/escape read can be converted to Data and returned without type2_error_with_revision, contrary to the common exit and D-23 contract."
    artifacts:
      - path: "modules/mb-font/font/cff_type2.mbt"
        issue: "Direct returns around lines 1425-1431, 1450-1467, and 1496-1500 bypass the guarded result exit at lines 1548-1550."
      - path: "modules/mb-font/font/cff_type2_fixture_wbtest.mbt"
        issue: "The State precedence test mutates before VM entry; it does not exercise mutation between a loop guard and a failing fetch/decode."
    missing:
      - "Route every non-State VM error through one final revision-preference seam."
      - "Add a deterministic mutation hook covering a failing number or escaped-operator fetch after the loop-entry guard."
---

# Phase 105: Bounded Type 2 Validation and Retained Metrics Verification Report

**Phase Goal:** Maintainers can validate every Type 2 glyph deterministically and retain truthful compact bounds before any CFF-backed font is published.
**Verified:** 2026-07-28T16:19:18Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Roadmap success criterion | Status | Evidence |
|---|---|---|---|
| 1 | Supported Type 2 number, stack, transient, arithmetic, logical, storage, width, line, curve, flex, subroutine, termination, and project-owned `random` behavior produces target-identical fixed-point results. | ✗ FAILED | The integer/fixed VM is substantive and wired, but `Type2Prng::next` uses low16 rather than the locked high16 mapping. The existing native test passes because it freezes the same wrong outputs. `moon check --target all` proves compilation, not equal runtime semantic records. |
| 2 | Hint/stem framing is exact and every named authority, including mutation, fails deterministically without host recursion or partial execution state. | ✗ FAILED | Hint masks, explicit subroutine frames, depth limits, termination, and common resource paths have passing focused tests. However, several VM-loop fetch/decode/EOF failures return directly and bypass the final revision-preference guard, so the required mutation precedence is not universal. |
| 3 | Admission executes every glyph through one interpreter, retains truthful conservative bounds per GID, and keeps `hmtx` authoritative. | ✗ FAILED | Ascending all-GID staging and retained face-local `hmtx` facts are wired and tested. Bounds are not always conservative because a later contour's start point is omitted from the hull once any earlier contour has a segment. |
| 4 | Any structural, program, numeric, resource, or mutation failure publishes no `Font`, no bounds, and no committed admission charge. | ✓ VERIFIED | `cff_stage_structure_at_after_preflight` and `type2_stage_all_glyphs_with_probe` return staged facts only; combined preflight and the final revision guard precede the sole `commit_atomic`. Focused malformed-later-glyph, mutation, caller-boundary, and multi-fault tests pass. |

**Score:** 1/4 roadmap truths verified

The PLAN frontmatter details were merged into these four non-duplicated roadmap truths: fixed arithmetic/random and all operator families support truth 1; hint/subroutine/limit/error rules support truth 2; matrices/geometry/all-GID/hmtx support truth 3; and combined staging/commit supports truth 4.

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `modules/mb-font/font/cff_type2_fixed.mbt` | Checked Q16.16, PRNG, matrices, outward rounding | ✗ DEFECTIVE | Substantive and wired, but PRNG selects the wrong half of the xorshift state. |
| `modules/mb-font/font/cff_type2.mbt` | Sole iterative VM, explicit frames, limits, all-GID staging | ✗ DEFECTIVE | Substantive and production-wired; some direct error returns bypass revision-preference handling. |
| `modules/mb-font/font/cff_type2_bounds.mbt` | Conservative transformed per-GID bounds | ✗ DEFECTIVE | Substantive and wired; later contour starts can be omitted from the hull. |
| `modules/mb-font/font/cff_dict.mbt`, `cff_keying.mbt`, `limits.mbt` | Retained seed, Top/optional-FD facts, private limits | ✓ VERIFIED | Seed and matrix facts feed `type2_execute_glyph`; no duplicate name-keyed FD matrix is consumed by the VM. |
| `modules/mb-font/font/cff_admission.mbt` | One structural + all-glyph transaction and one commit | ✓ VERIFIED | Stages structure and VM results, combines charges, preflights, revision-checks, commits once, then constructs `AdmittedCff1`. |
| `modules/mb-font/font/metrics.mbt` | Face-local `hmtx` metric authority | ✓ VERIFIED | `CffMetricFacts` retains the actual `hmtx` window; `cff_read_hmtx_metric` delegates to the existing checked `hmtx` reader. Type 2 width is not used as metric authority. |
| Phase 105 white-box/public tests | Behavioral and regression evidence | ⚠️ PARTIAL | Broad coverage passes, but PRNG golden data confirms the wrong mapping and no test covers a later-contour-start bound extreme or a mid-fetch mutation/error race. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Private DICT `initialRandomSeed` | per-glyph PRNG | `descriptor.environment.private_dict.initial_random_seed` passed to `type2_execute_program_with_matrix` | ⚠️ PARTIAL | Link exists; output mapping is wrong. |
| Per-GID descriptor | sole VM | `type2_stage_all_glyphs_with_probe` → `type2_execute_glyph` | ✓ WIRED | Ascending GID check, fresh `Type2Vm::new`, selected local Subrs, matrix, seed, and global Subrs are all used. |
| Sole VM operator switch | bounds sink | moveto/geometry/flex dispatch into `Type2BoundsSink` | ⚠️ PARTIAL | All operator families reach one sink, but later contour-start geometry is lost from the hull. |
| Structural stage + Type 2 stage | final budget transaction | `cff_combine_staged_charge` → `preflight_atomic` → revision guard → `commit_atomic` | ✓ WIRED | No earlier structural commit remains on this path. |
| Admitted CFF facts | `hmtx` reader | retained `CffMetricFacts.hmtx` → `cff_read_hmtx_metric` | ✓ WIRED | Width-mismatch and shared-CFF face-local metric tests pass. |
| VM errors | revision precedence | guarded `result` exit through `type2_error_with_revision` | ✗ PARTIAL | Common exit exists, but direct fetch/decode/EOF returns bypass it. |

## Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| `cff_type2.mbt` | ordered descriptors | Phase 104 `keying.glyphs` | Yes; each actual CharString and selected environment is executed | ✓ FLOWING |
| `cff_type2_bounds.mbt` | `GlyphBoundsFacts?` | transformed VM geometry endpoints/control points | Incomplete for later contour starts | ✗ HOLLOW |
| `cff_admission.mbt` | `AdmittedCff1.bounds` | complete `Type2AllGlyphResult.bounds` | Only published after total success and commit, but may contain an under-bound value | ✗ DEFECTIVE |
| `metrics.mbt` | advance/LSB | actual admitted `hmtx` table window | Yes | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Existing PRNG golden | `moon test modules/mb-font/font --target native -j 2 -f "Type 2 xorshift stream is repeatable, resettable, and strictly positive"` | 1 passed; confirms implemented low-bit sequence | ⚠️ MISLEADING PASS |
| Exact hint mask framing | focused named native test | 1 passed | ✓ PASS |
| Tail-only subroutine termination | focused named native test | 1 passed | ✓ PASS |
| Existing transformed bounds vectors | focused named native test | 1 passed; no later-contour-start extreme | ⚠️ PARTIAL |
| Ascending all-GID staging without commit | focused named native test | 1 passed | ✓ PASS |
| Complete all-glyph admission and combined commit | focused named native test | 1 passed | ✓ PASS |
| Type 2 width versus `hmtx` authority | focused named native test | 1 passed | ✓ PASS |
| Mutation during GID traversal | focused named native test | 1 passed; mutation occurs at a GID boundary | ⚠️ PARTIAL |
| State/Resource/Capability/Data fixture | focused named native test | 1 passed; does not cover guarded-read race | ⚠️ PARTIAL |
| Complete native regression | `moon test --target native -j 2` | 1245 passed, 0 failed | ✓ PASS |
| Four-target compilation | `moon check --target all` | 0 errors; 31 non-fatal warnings | ✓ PASS |

## Probe Execution

No phase probe scripts or deferred `<human-check>` blocks are declared. Probe execution is not applicable.

## Requirements Coverage

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| T2-01 | 105-01, 105-02, 105-03, 105-04 | ✗ BLOCKED | One pure-MoonBit VM and fixed arithmetic exist, but project-owned `random` violates the locked high16 output mapping. |
| T2-02 | 105-01, 105-02, 105-03, 105-04 | ✗ BLOCKED | Hints, masks, frames, depth, termination, and many resource limits are implemented, but not every non-State error passes through the mutation precedence guard. |
| CFF-03 | 105-01, 105-03, 105-04 | ✗ BLOCKED | All glyphs are staged atomically and `hmtx` remains authoritative, but retained multi-contour bounds can be non-conservative. |

**Requirement score:** 0/3 satisfied. No Phase 105 requirement is orphaned.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `cff_type2_fixed_wbtest.mbt` | 102-114 | Test encodes implementation's low-bit PRNG output rather than the locked contract | 🛑 Blocker | A passing test masks the T2-01 semantic defect. |
| `cff_type2_bounds_wbtest.mbt` | 157-183 | Multi-contour test asserts counters only | ⚠️ Warning | The conservative-bounds hole is untested. |
| `cff_type2.mbt` | 1425-1500 | Direct error returns bypass common revision exit | 🛑 Blocker | Mutation precedence is incomplete. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in the Phase 105 implementation/test scope. The all-target check reports 31 unused-field/function and deprecated-debug warnings; these do not independently block the phase.

## Human Verification Required

None. The phase outcomes are deterministic private parser/VM/data facts and the blocking failures are directly observable in code.

## Deferred-Item Filter

Phase 107 explicitly owns isolated four-target semantic records and broad qualification, but it does not defer or excuse the wrong Phase 105 PRNG mapping, non-conservative retained bounds, or incomplete Phase 105 mutation precedence. Phase 106 consumes these facts and therefore cannot safely proceed with the gaps open.

## Gaps Summary

The phase goal is not achieved despite 1245 passing native tests and successful all-target compilation. T2-01 is blocked by the wrong deterministic random mapping, T2-02 is blocked by error exits that bypass the required final mutation guard, and CFF-03 is blocked by an under-bounding multi-contour geometry path. The atomic combined admission transaction itself is correctly wired and verified.

---

_Verified: 2026-07-28T16:19:18Z_
_Verifier: the agent (gsd-verifier)_
