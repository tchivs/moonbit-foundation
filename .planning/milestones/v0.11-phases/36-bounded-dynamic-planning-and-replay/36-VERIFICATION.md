---
phase: 36-bounded-dynamic-planning-and-replay
verified: 2026-07-21T21:52:16Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 2/4
  gaps_closed:
    - "Dynamic-selected exact-work admission charges once, while the one-less case exposes no eager byte or caller lease byte."
    - "A Dynamic replay-drift failure is sticky through PngChunkEncoder and never mutates a later caller lease."
  gaps_remaining: []
  regressions: []
---

# Phase 36: Bounded Dynamic Planning and Replay Verification Report

**Phase Goal:** A dynamic-strategy user receives a deterministic, bounded Dynamic PNG only when it is strictly smaller than the unchanged FixedOrStored winner, with exact preflight and acknowledgement-safe eager/chunk replay.

**Verified:** 2026-07-21T21:52:16Z  
**Status:** passed  
**Re-verification:** Yes — closure tests from commits 87db126 and a9f5925 were independently executed.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | An admitted compatible image receives either a legal single Dynamic DEFLATE block or the byte-identical existing FixedOrStored winner, with Dynamic selected only when the complete PNG is strictly smaller. | ✓ VERIFIED | encode.mbt selects the unchanged FixedOrStored winner first, then admits Dynamic only when dynamic.total_length is strictly smaller (lines 558-577). stream_encode_test.mbt verifies a Dynamic BTYPE=10 strict winner, complete public decode, every RGB component, and eager/chunk byte equality (lines 316-342). |
| 2 | A dynamic candidate whose ordinary canonical construction cannot stay within DEFLATE's 15-bit bound falls back to FixedOrStored without a length-limited optimizer or image-sized staging. | ✓ VERIFIED | deflate_huffman.mbt uses an ordinary stable merge and returns None if depth exceeds 15 (lines 15-119); encode.mbt propagates that unavailable candidate to the existing winner (lines 352-423 and 571-576). PngDynamicPlan stores fixed DEFLATE alphabet/header facts and scalar totals only (lines 140-160); the focused bounded-builder/fallback test is in deflate_wbtest.mbt. |
| 3 | Capability, geometry, output, work, and budget rejection occurs before an eager writer or caller lease observes any byte; the selected exact plan is charged once. | ✓ VERIFIED | The shared preflight resolves the selected plan, validates every limit in one loop, then performs exactly one budget charge before either factory builds output state (encode.mbt:493-621). New white-box coverage proves the actual Dynamic winner costs 9388 work, succeeds exactly once, and rejects at 9387 with all budget fields unchanged (encode_wbtest.mbt:292-324). New public coverage proves exact eager and chunk admission, zero eager-writer bytes on one-less rejection, identical rejection errors, unchanged budgets, and untouched sentinel storage (stream_encode_test.mbt:375-441). |
| 4 | A library user can drain dynamic eager and caller-buffered output under arbitrary valid capacities with exact progress, byte-identical results, acknowledgement-only state commits, and sticky completion/failure behavior. | ✓ VERIFIED | Dynamic preview is cached privately and committed only by acknowledge (stream_encode.mbt:494-614 and 675-716). The hostile-capacity test includes zero-byte pulls and validates exact cumulative progress through the drain helper (stream_encode_test.mbt:209-251 and 346-357). The new public composition test mutates an admitted Dynamic source, observes png-encode-dynamic-replay-drift, then proves a later fresh sentinel lease has zero writes, unchanged total progress, the same error, and unchanged bytes (stream_encode_test.mbt:443-488). |

**Score:** 4/4 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| modules/mb-image/png/deflate_huffman.mbt | Deterministic bounded canonical-code construction | ✓ VERIFIED | Exists (232 lines), has a stable ordinary merge, canonical reversed-code validation, singleton handling, and an explicit >15-bit decline. Used by encode.mbt. |
| modules/mb-image/png/encode.mbt | Bounded Dynamic plan, exact accounting, strict atomic selection | ✓ VERIFIED | Exists (663 lines); PngDynamicPlan has fixed-size DEFLATE facts, shared preflight uses strict complete-PNG comparison, and the sole budget charge follows all limits. |
| modules/mb-image/png/stream_encode.mbt | Acknowledgement-gated scalar Dynamic replay | ✓ VERIFIED | Exists (717 lines); Dynamic state is previewed without mutation and committed only on acknowledged output. PngChunkEncoder latches terminal errors before a later lease is touched. |
| modules/mb-image/png/deflate_wbtest.mbt | Builder, RFC-header, singleton, and fallback evidence | ✓ VERIFIED | Substantive named focused tests cover canonical construction, RLE/header facts, singleton trees, and over-15-bit fallback. |
| modules/mb-image/png/encode_wbtest.mbt | Selection and selected-work admission evidence | ✓ VERIFIED | Commit 87db126 added the Dynamic 9388 exact/9387 one-less behavioral test; it asserts Dynamic selection, one charge, normal work rejection, and all resource fields unchanged. |
| modules/mb-image/png/stream_encode_wbtest.mbt | Preview/acknowledgement and replay-drift evidence | ✓ VERIFIED | Tests Dynamic preview non-mutation and private replay-drift detection; public composition is additionally covered below. |
| modules/mb-image/png/encode_test.mbt | Public eager strategy evidence | ✓ VERIFIED | Covers non-winning Dynamic fallback and frozen compatibility paths. |
| modules/mb-image/png/stream_encode_test.mbt | Public eager/chunk parity, progress, admission, and terminal evidence | ✓ VERIFIED | Commit a9f5925 added public atomic-admission and Dynamic chunk replay-drift/lease-isolation tests in addition to strict-winner decode and hostile-capacity parity coverage. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| deflate_huffman.mbt | encode.mbt | Canonical lengths and DEFLATE-LSB codes feed header and token accounting. | ✓ WIRED | _png_huffman_from_frequencies produces the literal, distance, and code-length trees used by _png_dynamic_plan. |
| encode.mbt | stream_encode.mbt | Charged PngDeflatePlan::Dynamic creates scalar replay state before either adapter starts. | ✓ WIRED | Both factories call the same preflight through PngEncodeMachine::new_with_compression_strategy, which initializes PngDynamicState only for a selected Dynamic plan. |
| stream_encode.mbt | public tests | PngEncoder and PngChunkEncoder share the selected plan and machine semantics. | ✓ WIRED | The public tests exercise both factories, compare their output, and test the PngChunkEncoder terminal after an admitted Dynamic selection. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| encode.mbt → stream_encode.mbt | Frequencies, Dynamic header facts, matcher work, fingerprint, replay bytes | ImageView → filter-None/A1 matcher → bounded Dynamic plan → PngDynamicState → PNG framing | The public strict-winner test decodes emitted bytes with complete-input enforcement and compares all dimensions and source components. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused Dynamic behavior on all supported targets | moon -C modules/mb-image test png --target all --frozen -f '*dynamic*' | 21/21 passed on wasm, wasm-gc, js, and native; exit 0. This includes all three closure tests. | ✓ PASS |
| Full PNG package | Not rerun: the only post-suite changes are the two test-only commits 87db126 and a9f5925, and the requested verification scope excludes the long quality lane. | Recorded pre-test-only evidence was 127/127 on each target. The current focused all-target execution is the evidence used for the closure behaviors. | ℹ️ RECORDED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGD-02 | 36-01-PLAN.md, 36-02-PLAN.md | Bounded strict Dynamic selection with exact atomic admission | ✓ SATISFIED | Strict winner/fallback and fixed-capacity representation are implemented; current all-target Dynamic tests exercise the 9388/9387 selected-work boundary through white-box and public factories. |
| PNGD-03 | 36-01-PLAN.md, 36-02-PLAN.md | Eager/chunk parity, exact progress, acknowledgement safety, sticky terminals | ✓ SATISFIED | Current all-target Dynamic tests exercise public strict-winner decode, zero/hostile-capacity parity, acknowledgement-gated preview, and public replay-drift sticky lease isolation. |

No Phase 36 requirements are orphaned: both PNGD-02 and PNGD-03 are declared by both plans, and REQUIREMENTS.md maps no additional requirement to this phase. No deferred items apply; Phase 37's broader corpus evidence does not substitute for either Phase 36 runtime proof.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| modules/mb-image/png/stream_encode.mbt | 129 | A stale comment says the compatibility-phase Dynamic route has no Dynamic tree, while the implementation below contains PngDynamicState. | ⚠️ Warning | Documentation-only inconsistency; no runtime behavior is affected. |

The Phase 36 files contain no unresolved TBD, FIXME, or XXX marker. The apparent “not available” comments in deflate_wbtest.mbt identify the historical RED-test stage; their tests now call implemented production functions and pass on every target. git diff --check across the Phase 36 implementation and closure commits is clean.

### Gaps Summary

The prior report's two present-but-unexercised Dynamic transitions are now covered by current, all-target behavioral tests. No missing artifact, stub, broken wiring, disconnected data flow, failed truth, or human-only check remains.

---

_Verified: 2026-07-21T21:52:16Z_  
_Verifier: the agent (gsd-verifier)_
