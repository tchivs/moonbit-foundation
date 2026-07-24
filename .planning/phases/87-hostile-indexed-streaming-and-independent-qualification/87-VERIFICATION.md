---
phase: 87-hostile-indexed-streaming-and-independent-qualification
verified: 2026-07-24T11:45:00Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: none
  previous_score: none
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 87: Hostile Indexed Streaming and Independent Qualification Verification Report

**Phase Goal:** Users can rely on the indexed compression profile under hostile
caller leases and obtain independently verifiable, decodable, portable PNG
bytes without disturbing frozen indexed compatibility routes.

**Status:** passed — 4/4 must-haves verified.

## Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Fixed winners and Stored fallbacks preserve accepted-only progress, sentinel tails, and eager parity under zero, one-byte, and ragged leases. | VERIFIED | `stream_encode_test.mbt` hostile matrix covers Indexed1/2/4/8 × both strategies × three schedules; focused indexed compression filter 14/14 and native package 315/315. |
| 2 | Released leases, replay-work drift, and terminal pulls are sticky zero-write outcomes. | VERIFIED | Public release/replay matrix plus `stream_encode_wbtest.mbt` indexed replay-work fingerprint test; later pulls preserve totals and sentinels. |
| 3 | Eager and separately collected chunk-origin bytes are independently parsed for Type-3 framing, PLTE/tRNS, Fixed/Stored DEFLATE, packed rows/tails, Adler/CRC, and public decode. | VERIFIED | Test-local bounded parser/inflater and narrow 5×3 fixtures in `stream_encode_test.mbt`; opaque RGB8 and partial-alpha RGBA8 coordinate assertions pass. |
| 4 | Compatibility vectors remain frozen and declared portability gates pass. | VERIFIED | Explicit Stored equals legacy Indexed1/2/4/8 vectors; existing indexed Adam7 tests remain in the package; native, wasm, wasm-gc, js, and `--target all` each report 315/315. |

## Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| INDEXCOMP-04 | SATISFIED | Hostile lease matrix, sticky release/Finished behavior, and mandatory indexed replay-work drift test. |
| INDEXCOMP-05 | SATISFIED | Independent eager/collected parser and inflater, CRC/Adler/raster/decode checks, compatibility vectors, and four-target gates. |

## Scope Fence

The implementation changes only `stream_encode_test.mbt` and
`stream_encode_wbtest.mbt` plus planning artifacts. No production encoder,
machine, source model, Dynamic/adaptive/Adam7 compression route, staging,
FFI, wrapper, copied tree, release automation, or public API was added.
Indexed source revision mutation is intentionally not induced because
`PngIndexedImage` is immutable; the private replay-work ledger mismatch is
tested instead and fails closed at the acknowledged machine seam.

## Verification Commands

- `moon -C modules/mb-image test png --target native --frozen --filter "*indexed compression*"` — 14/14.
- `moon -C modules/mb-image test png --target native --frozen` — 315/315.
- Executor evidence: `--target native`, `wasm`, `wasm-gc`, `js`, and `--target all` — 315/315 each.

## Gaps

None. Phase 87 requirements are satisfied; deferred Dynamic/adaptive/Adam7
compression selection and release work remain outside this milestone.

_Verified: 2026-07-24_  
_Verifier: main agent (goal-backward equivalent)_
