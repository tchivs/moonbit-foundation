---
phase: 26-pausable-png-decode-substrate
verified: 2026-07-21T09:45:02Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 26: Pausable PNG Decode Substrate Verification Report

**Phase Goal:** Existing PNG users retain the eager decoder's complete supported profile and deterministic safety semantics while its framing, IDAT/CRC transport, DEFLATE, and raster work can pause at any input boundary.

**Verified:** 2026-07-21T09:45:02Z

**Status:** passed

**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The private PNG machine can resume at byte boundaries without retaining caller input or a complete IDAT stream. | ✓ VERIFIED | `PngDecodeMachine::accept` owns one `Byte`; its state has no `ByteView`; `PngIdatState` retains header/CRC counters but no payload; `PngInflateState` owns a one-byte bit pending slot and bounded history. White-box tests exercise split framing, IDAT, stored/fixed/dynamic DEFLATE, and raster handoff. |
| 2 | Framing, CRC, DEFLATE/zlib, filtering, Adam7, IEND, and EOF retain enough state for exact deterministic success or failure. | ✓ VERIFIED | The private state machine holds signature/chunk/CRC states; `PngInflateState` holds token, tree, match, Adler, and trailer phases; `PngRasterSink` holds row/filter/Adam7 state. The generated public corpus asserts exact category/code/context for rejected vectors and pixels/metadata for accepted vectors; all four targets passed. |
| 3 | Output stays private until raster, IDAT CRC, Adler-32, IEND, and EOF validation pass. | ✓ VERIFIED | `finish` only creates `PngMachineOutcome` from `NeedEof` after `inflate.complete()` and `sink.finish()`; any byte after IEND becomes `png-trailing-data`. The targeted late-IEND-CRC test passed and confirms no private outcome is exposed. |
| 4 | Existing `PngDecoder` remains eager-equivalent across the full supported profile and portable targets, while the public interface stays unchanged. | ✓ VERIFIED | `PngDecoder::decode` delegates to `PngDecodeMachine::decode_reader`; generated vectors cover grayscale, indexed/PLTE, tRNS, 16-bit, Adam7, sRGB, legacy/ICC metadata, malformed data, limits, and budgets. `moon -C modules/mb-image test png --target all --frozen` passed 68/68 on wasm, wasm-gc, js, and native; policy lane verifies only `PngDecoder`/`PngEncoder` are public. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/stream_decode.mbt` | Private framing/lifecycle/terminal state machine | ✓ VERIFIED | 788 lines; wired by `PngDecoder::decode` through `decode_reader`. |
| `modules/mb-image/png/stream_decode_wbtest.mbt` | Boundary, ownership, integrity, and no-result evidence | ✓ VERIFIED | 24 white-box tests cover split state and terminal gates. |
| `modules/mb-image/png/deflate_inflate.mbt` | Resumable stored/fixed/dynamic inflater | ✓ VERIFIED | Persisted zlib, block, dynamic-tree, match-copy, Adler, and output handoff state. |
| `modules/mb-image/png/raster_decode.mbt` | Persistent filtering/packed-row/Adam7 sink | ✓ VERIFIED | `PngRasterSink` is created once at first IDAT preflight and receives inflater output. |
| `modules/mb-image/png/stream_decode_test.mbt` | Public facade schedule equivalence evidence | ✓ VERIFIED | One-byte reader public comparison checks all accepted generated vectors against the standard eager reader. |
| `policy/foundation.json` | Exact private-source inventory and unchanged public interface | ✓ VERIFIED | Lists `stream_decode.mbt`; semantic interface is exactly `PngDecoder` and `PngEncoder`. |

`gsd-tools verify.artifacts` independently reported 6/6 passed.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `stream_decode.mbt` | `structural.mbt` | Existing grammar, CRC, metadata, and resource helpers | ✓ WIRED | Machine calls the established `_png_*` validators/preflight helpers. |
| `stream_decode.mbt` | `deflate_inflate.mbt` | Authenticated IDAT byte to `PngInflateState::accept_to` | ✓ WIRED | The payload path authenticates/accountes each IDAT byte before handoff. |
| `deflate_inflate.mbt` | `raster_decode.mbt` | Pending inflated byte to `PngRasterSink::emit` | ✓ WIRED | `accept_to` drains every emitted byte to the owned sink before accepting more input. |

`gsd-tools verify.key-links` independently reported 3/3 verified.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Generated accepted and rejected decode corpus through public facade | `moon -C modules/mb-image test png --target native --frozen -f '*generated PNG decode vectors execute fixed and dynamic streams through PngDecoder*'` | 1/1 passed | ✓ PASS |
| Late terminal integrity failure cannot publish private outcome | `moon -C modules/mb-image test png --target native --frozen -f '*PNG private machine withholds its outcome after a late IEND CRC failure*'` | 1/1 passed | ✓ PASS |
| Four-target package behavior | `moon -C modules/mb-image test png --target all --frozen` | 68/68 passed on wasm, wasm-gc, js, native | ✓ PASS |
| Fixture and policy/quality integrity | `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check`; `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | 3,850 vectors checked; PNG quality lane passed | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGS-03 | `26-01-PLAN.md` | Chunked substrate preserves eager supported profile, semantics, accounting, diagnostics, resource limits, and no partial image. | ✓ SATISFIED | Eager facade is routed through the machine; generated public and private boundary tests plus four-target quality evidence cover the specified profile and terminal/resource behavior. |

### Prohibitions and Anti-Patterns

| Check | Status | Evidence |
| --- | --- | --- |
| No public chunk/stream decoder in Phase 26 | ✓ VERIFIED | Public declaration scan found no `PngChunkDecoder`, `PngStreamDecoder`, `push`, or public `finish`; PNG policy negative fixtures passed. |
| No FFI or borrowed `ByteView` retention | ✓ VERIFIED | `stream_decode.mbt` contains no executable `ByteView` reference and no FFI declarations; machine input is a `Byte`. |
| No full IDAT buffering | ✓ VERIFIED | `PngIdatState` contains length/type/CRC fields and counters only; compressed payload is immediately passed to the inflater. |
| Unresolved debt markers in phase-modified implementation | ✓ VERIFIED | No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, or placeholder implementation marker was found. |

The compiler reports non-fatal unused-private-symbol warnings for the test support adapter and inspection helpers. They do not leave an unwired public behavior: the actual public path is `PngDecoder::decode` → `PngDecodeMachine::decode_reader`, which is exercised by the public corpus.

### Human Verification Required

None. The phase produces a portable codec substrate; all goal-level runtime transitions have executable evidence on every supported target.

### Gaps Summary

No blocking gaps found. Phase 27 remains responsible for exposing the already-private chunk/finish API; this phase correctly keeps that surface absent.

---

_Verified: 2026-07-21T09:45:02Z_

_Verifier: the agent (gsd-verifier)_
