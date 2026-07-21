---
phase: 27-public-png-chunk-decoder
verified: 2026-07-21T12:29:11Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/4
  gaps_closed:
    - "Real fixed-Huffman-token, dynamic-tree, and dynamic-match inflater pauses now prove zlib-truncated precedence through both private and public paths."
    - "Zero-length wrong-fourth-type and completed non-IEND-type inputs now remain active through byte 68 and finish as png-iend-type with sticky replay."
  gaps_remaining: []
  regressions: []
---

# Phase 27: Public PNG Chunk Decoder — Final Re-verification

**Phase Goal:** Library users can submit caller-owned PNG byte chunks to `PngChunkDecoder` and explicitly complete one eager-equivalent decode without changing existing `Reader` EOF semantics.

**Verified:** 2026-07-21T12:29:11Z
**Status:** passed

**Freshness confirmation:** A detached-worktree `moon -C modules/mb-image test png --target all --frozen` run at `2bd4974` passed 84/84 on wasm, wasm-gc, js, and native; no implementation changes followed this report.
**Re-verification:** Yes — after 27-03 EOF-matrix closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Arbitrary caller-owned chunks, including empty input and framing/IDAT/DEFLATE/filter/IEND boundaries, report exact consumption and non-terminal `NeedInput`; no image is available from `push`. | ✓ VERIFIED | `PngChunkDecoder::push` reads each `ByteView` byte synchronously, increments only admitted bytes, and exposes only `PngChunkPushOutcome`. Executed public one-byte generated-profile, mixed-boundary, empty-push, mutation/reuse, limit, trailing, and sticky-terminal tests in the 83-test four-target suite. |
| 2 | `finish()` is the sole EOF/result transfer and returns one strict eager-equivalent owned result only after IDAT CRC, zlib/Adler, raster, IEND, and trailing-input validation. | ✓ VERIFIED | `finish` calls private `PngDecodeMachine::finish` only from `NeedEof`, transfers `into_decode_result` once, then enters `Finished`; public test proves second finish is a state error and later push consumes zero. Generated-corpus test compares pixels, descriptor metadata, disposition, bytes read, diagnostics, and every budget remainder against independent eager decoding. |
| 3 | Incomplete framing/raster work, malformed CRC/zlib/DEFLATE, malformed or missing IEND, trailing input, limits, and budget failures are typed sticky terminals; later pushes consume zero. | ✓ VERIFIED | Public corpus parity and focused classifier tests exercise structural, DEFLATE, raster, trailing, limit/allocation/budget families. `png_wb_assert_incomplete` compares private/public full CoreError shape, exact completed total, zero-consumption later push, and repeated-finish replay. The newly added literal vectors cover real fixed-token, dynamic-tree, dynamic-match, wrong-fourth-type, and completed non-IEND-type cases. |
| 4 | The documented portable `PngChunk*` API is policy-exact, retains no caller view, and passes all four production targets. | ✓ VERIFIED | `png.mbt` declares only the documented public wrapper/result/outcome types; wrapper state has no `ByteView`, reader, or lease field. Direct policy/negative-fixture check passed, vector freshness checked 3,850 cases, and `moon -C modules/mb-image test png --target all --frozen` passed 83/83 on wasm, wasm-gc, js, and native. |

**Score:** 4/4 truths verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Public chunk API | ✓ VERIFIED | Public `PngChunkDecoder`, `PngChunkPushOutcome`, and `PngChunkPushResult` expose constructor, `push`, `finish`, `consumed`, and `outcome`; no result accessor exists on progress. |
| `modules/mb-image/png/stream_decode.mbt` | Private machine adapter, classifier, one-time transfer, sticky state | ✓ VERIFIED | `push` preflights input limit then dispatches exactly one transient byte; `finish` is the only transition that can move the private outcome. `PendingIendType` is explicitly classified and rejects subsequent input with its stored type error. |
| `modules/mb-image/png/stream_decode_test.mbt` | Public schedule, ownership, parity, resource, and terminal evidence | ✓ VERIFIED | Tests cover accepted generated profiles one byte at a time, structural mixed boundaries, caller mutation/reuse, exact accepted counts, strict finish, successful single transfer, sticky failures, and eager parity over the generated corpus. |
| `modules/mb-image/png/stream_decode_wbtest.mbt` | Complete frozen EOF classifier/precedence matrix | ✓ VERIFIED | The shared private/public harness is executed for framing, IDAT/IEND CRC, raster precedence, stored/header/Adler, real fixed/dynamic DEFLATE pauses, and both zero-length terminal type rows. |
| `policy/foundation.json` | Exact public semantic interface | ✓ VERIFIED | `Assert-PngFoundationPolicy` and its scoped negative fixtures passed against the current generated interface. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `PngChunkDecoder::push` | `PngDecodeMachine::accept` | Current source byte is read then dispatched once | ✓ WIRED | `stream_decode.mbt` lines 664–702 keep only byte-local source access and return after the first machine error. |
| `PngChunkDecoder::finish` | `PngDecodeMachine::finish` / `into_decode_result` | Only `NeedEof` calls terminal machine transition and moves result | ✓ WIRED | `stream_decode.mbt` lines 705–726 gate all other active states through the non-mutating classifier. |
| `stream_decode_wbtest.mbt` | classifier and public wrapper | Same literal prefix runs private classifier then public push/finish | ✓ WIRED | `png_wb_assert_incomplete` verifies full error equivalence, exact completed total, and both replay channels. |
| `policy/foundation.json` | generated MBTI | Foundation policy regenerates and compares API | ✓ WIRED | Direct policy and negative-fixture commands passed. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Newly closed EOF rows | `moon -C modules/mb-image test png --target native --frozen -f '*PNG chunk EOF classifier*'` | 5/5 passed | ✓ PASS |
| Full public/private PNG behavior on four targets | `moon -C modules/mb-image test png --target all --frozen` | 83/83 passed on wasm, wasm-gc, js, native | ✓ PASS |
| Generated decode corpus freshness | `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | 3,850 executable cases checked | ✓ PASS |
| API policy and fail-closed negatives | `Assert-PngFoundationPolicy` and `Assert-PngQualificationNegativeFixtures` with `policy/foundation.json` | Both passed | ✓ PASS |

The isolated PNG quality lane had already passed in the previous re-verification. Its long repeat was stopped at the verifier time boundary; this report does not rely on that interrupted process: the current direct policy, vector, and all-four-target component checks above passed after the 27-03 source change.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| PNGS-01 | 27-01, 27-02 | Arbitrary caller chunks, deterministic non-terminal progress, no image before strict completion | ✓ SATISFIED | Byte-at-a-time accepted profile corpus; explicit empty/mixed schedules; exact consumption; caller-owner mutation; `push` type has no result. |
| PNGS-02 | 27-01, 27-02, 27-03 | Explicit eager-equivalent result or sticky typed terminal error | ✓ SATISFIED | Full eager/chunk observable parity, resource/terminal replay tests, exhaustive frozen EOF classifier, and current four-target 83/83 run. |

### Anti-Patterns Found

No Phase 27 `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, or placeholder implementation was found in the public facade, machine, or focused tests. Existing compiler warnings are pre-existing unused private testing seams and do not suppress a test or alter the verified transition paths.

## Re-verification Finding

The former gap was real: the prior classifier test had named fixed/dynamic coverage without constructing fixed/dynamic pause states, and had omitted the two byte-68 zero-length type rows. The current implementation and tests falsify that concern. The new helpers prove the inflater phase before building the PNG prefix (`Symbols` with a non-empty cursor, `DynamicCodeLengths`, and a real dynamic length/distance/copy transition); the public wrapper then finishes with `zlib-truncated` before surrounding IDAT/IEND framing. The zero-length `IENX` and `vpAg` headers remain private `PendingIendType` states until `finish`, both classify as `png-iend-type`, and both preserve exact error replay.

No observable requirement remains unverified; Phase 27's goal is achieved.

---

_Verified: 2026-07-21T19:32:50+08:00_  
_Verifier: gsd-verifier_
