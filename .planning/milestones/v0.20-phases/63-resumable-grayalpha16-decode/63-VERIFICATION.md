---
phase: 63-resumable-grayalpha16-decode
verified: 2026-07-23T06:01:53Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 63: Resumable GrayAlpha16 Decode Verification Report

**Phase Goal:** Users can obtain the same preserved GrayAlpha16 result through caller-owned input chunks while retaining the established bounded decoder lifecycle.
**Verified:** 2026-07-23T06:01:53Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can create `PngChunkDecoder::new_graya16`, pass legal declaration-free or sRGB Type-4/16 PNGs through empty, one-byte, and ragged schedules, and receive the exact result of a fresh `decode_graya16` peer only after successful `finish()`. | ✓ VERIFIED | `new_graya16` constructs `new_with_profile(GrayAlpha16)` in `png.mbt`; the public schedule test starts with an empty push and runs both literals through one-byte and ragged schedules. It compares descriptor, disposition, metadata, all U16 component bytes, budget, and diagnostics against a fresh eager peer. Focused JS test: 2/2 passed. |
| 2 | Active pushes report exactly accepted caller bytes; no result is exposed during pushes (including after IEND), and successful `finish()` is the sole transfer boundary, without retaining a caller view. | ✓ VERIFIED | The shared `push` advances `consumed_total` only after the next byte passes the input limit, returns only `NeedInput` or `Failed`, and has no result field. `finish` alone calls `into_decode_result`, then moves to `Finished`. The new selector stores that exact shared-machine state; neither wrapper nor machine contains a `ByteView` field. Schedule coverage asserts exact counts and `NeedInput` through IEND before `finish()`. |
| 3 | Incomplete, malformed, metadata-rejected, and input-limit streams fail atomically with established typed diagnostics and sticky terminal behavior. | ✓ VERIFIED | The terminal test exercises early EOF, malformed signature, the GrayAlpha16 metadata gate, and `max_input_bytes=0`; it checks the first error, zero-consumption replay on a later push, and identical replay from `finish`. `push` records the first error in `Failed`, and `finish` returns it unchanged. Focused JS test: 2/2 passed. |
| 4 | The existing generic `PngChunkDecoder::new` route retains its frozen RGBA8 high-byte result for the same Type-4/16 literal. | ✓ VERIFIED | `new` still invokes the generic `PngDecodeMachine::new`; only the additive factory invokes `new_with_profile(GrayAlpha16)`. The terminal test independently asserts generic first-pixel `12,12,12,a7`. Focused JS test: 2/2 passed. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Sole public `PngChunkDecoder::new_graya16` selector using the existing private GrayAlpha16 profile. | ✓ VERIFIED | Exists, is substantive, and the factory creates the identical wrapper fields/options as `new`, substituting only `new_with_profile(GrayAlpha16)`. |
| `modules/mb-image/png/stream_decode_test.mbt` | Public schedule/eager-parity, accepted-progress, terminal-error, and generic-compatibility regressions. | ✓ VERIFIED | Exists, is substantive, invokes the public factory/push/finish API, and is discovered by the focused MoonBit test command (2/2 passed). |

`verify.artifacts` reported 2/2 passing artifacts. No artifact is a stub or orphan.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `stream_decode.mbt` | `new_graya16` → `new_with_profile(GrayAlpha16)` → shared `PngChunkDecoder` state | ✓ WIRED | Manual source inspection confirms the multiline constructor call and shared state. The automated key-link regex missed it because `new_graya16` and `new_with_profile` are on different lines. |
| `stream_decode_test.mbt` | `png.mbt` | Fresh explicit chunk factory and eager `decode_graya16` peer | ✓ WIRED | Tests call `PngChunkDecoder::new_graya16` and `PngDecoder::decode_graya16` directly; automated key-link check passed. |
| `stream_decode_test.mbt` | `stream_decode.mbt` | Public `push` and `finish` behavior | ✓ WIRED | Tests execute empty, one-byte, ragged, EOF, malformed, metadata, limit, and sticky-replay paths; automated key-link check passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `png.mbt` / shared decoder | final U16 component bytes | caller-owned Type-4/16 literal → shared byte-fed machine → GrayAlpha16 preflight → profile-aware raster sink | Public schedules compare fresh eager/chunk results and observe `34,12,c5,a7` and `0f,be,76,5a` component lanes. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Explicit schedules, finish-only result transfer, typed sticky terminals, and generic compatibility | `moon -C modules/mb-image test png --target js --frozen --filter '*graya16 chunk*'` | 2 passed, 0 failed | ✓ PASS |
| Native compilation of the affected package | `moon -C modules/mb-image check --target native --frozen` | 0 errors; pre-existing warnings only | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — Phase 63 declares no probe and no conventional `probe-*.sh` exists.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| `GRA16DEC-02` | `63-01-PLAN.md` | Select the shared bounded decoder through `new_graya16`, preserve eager-equivalent result and accepted-only/atomic/sticky semantics under hostile schedules. | ✓ SATISFIED | Truths 1–4, focused public tests, shared lifecycle source inspection, and native check above. |

No requirements mapped to Phase 63 are absent from the plan. Phase 64's filters, Adam7, broad hostile matrix, and all-target qualification are specifically deferred roadmap work, not missing Phase 63 deliverables.

### Anti-Patterns Found

No blocker or warning anti-patterns found in the Phase 63-modified files. There are no `TBD`, `FIXME`, or `XXX` debt markers, no placeholder returns, and the phase diff changes only the declared selector and focused tests. No alternate decoder or image-sized source staging buffer was introduced.

### Gaps Summary

None. The phase goal is achieved: the additive explicit factory selects the existing preservation profile and uses the same bounded lifecycle as the generic façade, while focused behavioral evidence covers the required schedules and terminal invariants.

---

_Verified: 2026-07-23T06:01:53Z_
_Verifier: the agent (gsd-verifier)_
