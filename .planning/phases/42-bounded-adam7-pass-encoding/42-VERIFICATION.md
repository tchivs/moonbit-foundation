---
phase: 42-bounded-adam7-pass-encoding
verified: 2026-07-22T08:07:08Z
status: gaps_found
score: 1/4 must-haves verified
behavior_unverified: 3
overrides_applied: 0
gaps:
  - truth: "Targeted Phase 42 tests exercise real nontrivial Adam7 pass traversal, atomic admission, and acknowledgement-gated replay."
    status: failed
    reason: "The added tests exercise only structural pass records or a 1x1 image (one nonempty pass); they do not exercise the required multi-pass byte stream, Adam7 API rejection matrix, or unacknowledged Adam7 successor state."
    artifacts:
      - path: "modules/mb-image/png/encode_wbtest.mbt"
        issue: "The named canonical-pass test reads _png_adam7_passes but never consumes PngFilteredCursor to assert the 5x5 pass filter-tag/sample stream; its filter-reset assertion only excludes the Up tag on 2x2 input."
      - path: "modules/mb-image/png/encode_test.mbt"
        issue: "Adam7 eager assertions use 1x1 RGB/RGBA input and check framing/IHDR only; they do not exercise seven nonempty passes."
      - path: "modules/mb-image/png/stream_encode_test.mbt"
        issue: "Adam7 parity uses 1x1 input and has no Adam7 capability/geometry/output/budget rejection or repeated-present-before-acknowledge case."
    missing:
      - "A deterministic 5x5 RGB8 and straight-RGBA8 cursor test asserting exact nonempty-pass filter-tag-plus-sample bytes and 1x1 empty-pass omission."
      - "Adam7 eager and chunk admission tests for capability, geometry, output, work, and budget failures across Stored, FixedOrStored, and DynamicOrFixedOrStored, including zero writer output/no lease and unchanged budget fields."
      - "An Adam7 multi-pass acknowledgement test that repeats preview before acceptance, verifies no cursor/CRC/Adler progress, then verifies accepted-byte-only progress and sticky terminal behavior."
behavior_unverified_items:
  - truth: "Compatible RGB8 and straight-RGBA8 Adam7 output emits the deterministic seven-pass filtered stream without staging."
    test: "Run a focused 5x5 RGB8/RGBA8 cursor/output regression that asserts each nonempty pass's tag and sample bytes."
    expected: "All seven canonical nonempty-pass sections occur in order; 1x1 omits empty passes; no cache/staging is needed."
    why_human: "Static code traces the intended scalar source, but the current test only inspects geometry records, not generated multi-pass bytes."
  - truth: "Adam7 construction rejects every invalid capability, geometry, output, work, and budget request atomically for eager and caller-buffered routes."
    test: "Run focused eager/chunk Adam7 rejection cases for all three compression strategies, one limit at a time."
    expected: "Writer remains at zero, no encoder/lease is returned, and every budget field remains unchanged."
    why_human: "The source ordering is correct and one white-box work-bound case exists, but no Adam7 public rejection matrix exercises the observable boundary."
  - truth: "Adam7 caller-buffered replay commits only accepted bytes and remains exact across hostile capacities."
    test: "Use a multi-pass Adam7 image; call present twice before acknowledge at DEFLATE output, then drain with zero/one/tiny capacities."
    expected: "The preview and replay state stay unchanged until acknowledgement; accepted output equals eager bytes and Finished is sticky."
    why_human: "The pending-successor wiring is present, but the Adam7 test is 1x1 and does not directly exercise an unacknowledged Adam7 cursor successor."
---

# Phase 42: Bounded Adam7 Pass Encoding Verification Report

**Phase Goal:** Opted-in images are encoded as deterministic, bounded Adam7 passes while preserving atomic admission and acknowledgement-safe caller-buffered replay.
**Verified:** 2026-07-22T08:07:08Z  
**Status:** gaps_found  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | RGB8/RGBA8 Adam7 uses canonical bounded pass bytes, pass-local filters, and a shared planner input. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `encode.mbt:470-699` regenerates only `_png_adam7_passes` geometry and scalar samples; `PngFilteredMatchCursor` retains a fixed 262-byte window. However, the added 5x5 test checks geometry only, not cursor output. |
| 2 | Adam7 eager/chunk admission is atomic for geometry, output, work, and budget under every strategy. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `encode.mbt:1454-1644` completes planners and limits before the sole `budget.charge`; `stream_encode.mbt:307-380` preflights before machine/lease construction. Tests cover only internal one-less work, not the required public Adam7 rejection matrix. |
| 3 | Arbitrary-capacity Adam7 replay progresses only after accepted bytes and equals eager output. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `stream_encode.mbt:124-177` calls `acknowledge` only after `destination.set`; `present`/`acknowledge` at `836-907` preserve pending successors. The Adam7 parity test uses only a 1x1 image and has no direct pre-ack state assertion. |
| 4 | Adam7 IHDR is method 1; legacy and explicit-None routes remain method 0 and retain frozen vectors. | ✓ VERIFIED | `stream_encode.mbt:804-832` emits 1 only for `Adam7`, otherwise 0; `encode_test.mbt:528-588` and `stream_encode_test.mbt:758-849` retain None vectors while checking Adam7 IHDR. |

**Score:** 1/4 truths verified (3 present, behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode.mbt` | Bounded pass-aware source and atomic ledger | ✓ VERIFIED | Exists/substantive; `verify.artifacts` passed; all Adam7 planner walks use `new_with_interlace`. |
| `modules/mb-image/png/stream_encode.mbt` | Adam7 replay, framing, acknowledgement-gated commits | ✓ VERIFIED | Exists/substantive; preflight precedes construction and pending successors commit only in `acknowledge`. |
| `modules/mb-image/png/encode_wbtest.mbt` | Pass-order/filter-reset/exact-ledger coverage | ✗ HOLLOW COVERAGE | New tests do not consume a 5x5 cursor stream or assert its bytes. |
| `modules/mb-image/png/encode_test.mbt` | Eager Adam7 framing and None compatibility coverage | ⚠️ PARTIAL | Checks method-1 framing on 1x1; does not exercise seven passes. |
| `modules/mb-image/png/stream_encode_test.mbt` | Hostile-capacity, atomic-admission, eager/chunk Adam7 coverage | ✗ HOLLOW COVERAGE | Uses 1x1 parity only; lacks Adam7 admission and pre-ack replay cases. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `encode.mbt` | `structural.mbt` | `_png_adam7_passes` | ✓ WIRED | Calls at `encode.mbt:475` and `1481`; no encoder-local pass starts/strides found. |
| `encode.mbt` | planner/replay cursor | `PngFilteredMatchCursor::new_with_interlace` | ✓ WIRED | Stored traversal, fixed plan, dynamic frequency/bit plans, and replay each receive the selected interlace strategy. |
| `stream_encode.mbt` | `stream_encode_test.mbt` | `present` then `acknowledge` after lease write | ⚠️ PARTIAL | Production wiring is correct, but Adam7-specific tests do not exercise an unacknowledged successor. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- |
| `encode.mbt` | `PngFilteredCursor` byte | `ImageView.get_byte(pass.x + column * pass.dx, pass.y + row * pass.dy, channel)` | Caller image pixels; pass geometry is regenerated from structural authority | ✓ FLOWING |
| `stream_encode.mbt` | Stored/fixed/dynamic replay cursor | Fresh `PngFilteredMatchCursor` selected at machine construction | Same caller image and selected pass-aware source as preflight | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Native PNG test suite | `moon -C modules/mb-image test png --target native --frozen` | Not run: this independent verifier was restricted to writing only this report; no machine-readable prior result was supplied. SUMMARY claims were not accepted as evidence. | ? SKIP |

## Probe Execution

No Phase 42 probe was declared or found; this is not a migration/tooling phase.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGI-02 | 42-01 | Bounded deterministic seven-pass geometry/bytes/filtering/compression input without staging | ✗ BLOCKED | Implementation is present, but the required 5x5 emitted-byte regression is absent; the named test only asserts structural records. |
| PNGI-03 | 42-01 | Atomic admission and accepted-byte-only replay for all three strategies | ✗ BLOCKED | Preflight and pending-state code is wired, but Adam7 tests omit observable API rejection and pre-ack state cases. |

No requirements mapped to Phase 42 were orphaned. Phase 43's generated four-target fidelity/compatibility evidence was deliberately not counted as evidence for PNGI-02 or PNGI-03.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| `modules/mb-image/png/stream_encode_test.mbt` | 757 | Stale “not-yet-implemented Adam7” comment | ⚠️ Warning | Misdescribes a test that now constructs Adam7 encoders; not a `TBD`/`FIXME` blocker. |

No `TBD`, `FIXME`, or `XXX` debt markers were found in Phase 42 implementation/test files. No pass/image-sized cache or staged output artifact was found; bounded matcher/Huffman arrays are fixed-size.

## Gaps Summary

The implementation is not a placeholder: it has a real scalar Adam7 source, all three planner/replay links, one admission seam, and acknowledgement-gated successor commits. The phase nevertheless fails its verification gate because its new tests do not prove the phase's risk-bearing runtime behavior. A regression that substituted full-image scanline bytes, leaked cross-pass filtering, exposed a lease before a rejected Adam7 preflight, or committed an Adam7 successor during preview could still evade the added Adam7 tests.

This is not deferred to Phase 43. Phase 43 owns generated public four-target fidelity evidence; Phase 42's own plan explicitly requires targeted native pass-stream, admission, and acknowledgement regressions.

---

_Verified: 2026-07-22T08:07:08Z_  
_Verifier: gsd-verifier_
