---
phase: 84-low-bit-indexed-adam7-streaming-qualification
verified: 2026-07-24T04:14:50Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 84: Low-Bit Indexed Adam7 Streaming Qualification — Verification Report

**Phase Goal:** Each admitted low-bit Indexed Adam7 route is safe through caller-owned leases, independently wire-qualified from collected stream bytes, compatibility-frozen, and proven on all four declared targets.

**Verified:** 2026-07-24T04:14:50Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- |
| 1 | Indexed1, Indexed2, and Indexed4 Adam7 chunk selectors reproduce fresh eager bytes under zero-capacity, one-byte, and ragged caller leases; totals count accepted bytes only and every unaccepted tail remains caller-owned. | ✓ VERIFIED | `PNG selected low-bit Adam7 chunk qualifies every hostile lease schedule` runs all three depths with `[0,1]`, `[1]`, and `[0,1,3,2,5]`. Each drain constructs `new_indexed_with_interlace_strategy(..., Adam7, ...)`, asserts `written <= capacity` and `total_written == prior accepted + written`, collects only accepted prefixes, checks each remaining `Z` byte, and uses a one-byte owner with a zero-length lease to observe zero-capacity preservation. |
| 2 | Released leases replay sticky zero-write failures, and completed streams replay zero-write `Finished` without mutating later destinations. | ✓ VERIFIED | `PNG selected low-bit Adam7 chunk replays released lease failures` covers One/Two/Four: released first and later leases both have zero write/total, equivalent errors, and untouched sentinels. Each successful hostile drain performs a later seven-byte `Z` lease check for zero-write `Finished`, unchanged total, and all bytes unchanged. |
| 3 | Collected stream bytes independently prove Type-3 Adam7 signature/framing/CRC/Stored raster, local MSB-first packing with zero tails, and public RGBA8/RGB8 palette decode for each selected depth. | ✓ VERIFIED | `png_stream_indexed_low_bit_adam7_chunk_origin_qualification` receives only `Bytes::from_array(output)` collected from accepted chunk pulls. It validates PNG signature, IHDR 5×5 Type-3 with depth 1/2/4 and Adam7 flag, positional PLTE/tRNS/IDAT/IEND ordering and all CRCs, then compares test-local Stored extraction with literal 22/24/27-byte rasters. Its local Adam7 table recomputes filter tags, pass coordinates, MSB-first bytes, and zero tails without production geometry/packing/preflight helpers. The public decoder verifies every transparent RGBA palette/alpha pixel; separately drained opaque chunk streams verify RGB palette pixels. |
| 4 | Existing Type-3 low-bit non-interlaced vectors and Type-3/8 Adam7 vectors remain frozen. | ✓ VERIFIED | Phase commits `a403933`, `0f0d143`, `2a6a225`, and `43c573d` change only `stream_encode_test.mbt`; established vector owners such as `encode_test.mbt` are untouched. The ordinary PNG package run executes the existing vector registrations together with the new tests. |
| 5 | The ordinary frozen PNG package gate passes on wasm, wasm-gc, js, and native. | ✓ VERIFIED | Mainline final evidence records `moon -C modules/mb-image test png --target all --frozen` at **298/298 passed on each target**. `moon.mod.json` declares `+js+wasm+wasm-gc+native`, and `git diff --name-only 43c573d..HEAD -- modules/mb-image/png` is empty, so the result applies to current PNG source. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- |
| `modules/mb-image/png/stream_encode_test.mbt` | Test-local hostile lease matrix, terminal replay, independent Type-3 Adam7 parser/raster proof, decode proof, and freeze qualification. | ✓ VERIFIED | Exists and is substantive. The phase diff adds 460 test-only lines, including registered hostile-schedule and released-lease tests, literal fixtures, local packing oracle, collected-byte parser, and opaque decoder path. Artifact verification reports 1/1 passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| Low-bit Adam7 test harness | Existing chunk facade | `PngChunkEncoder::new_indexed_with_interlace_strategy(..., Adam7, ...)` followed by real caller-owned `pull` leases | ✓ WIRED | Each test helper uses the explicit selected-depth Adam7 selector; no test-owned transport or encoder is introduced. Tool verification reports the declared link found. |
| Collected chunk output | Independent framing/raster/decode evidence | Test-local `png_indexed_crc32`, `png_indexed_u32`, `png_indexed_slice`, and `png_encode_public_stored_scanlines` | ✓ WIRED | The parser input is `collected`, not eager output. It consumes literal vectors and a test-local pass table, then invokes public decoding over the collected bytes. Tool verification reports the declared link found. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Hostile drain | `output` / `collected` | Accepted prefix bytes from actual `PngChunkEncoder::pull` calls on caller-owned leases | Only written bytes are appended; the completed stream is compared to fresh eager bytes and independently qualified. | ✓ FLOWING |
| Independent raster proof | `png_encode_public_stored_scanlines(collected, raw.length())` | Stored IDAT from the collected chunk bytes | Must equal the literal 22/24/27-byte source oracle, then passes local coordinate/MSB/tail checks. | ✓ FLOWING |
| Public decode proof | decoded image view | `PngDecoder` over owned collected transparent or opaque chunk stream bytes | Every one of 25 coordinates is checked against literal palette codes, including RGBA alpha or opaque RGB format. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Full frozen PNG package across declared targets | `moon -C modules/mb-image test png --target all --frozen` | Mainline final evidence: 298/298 passed on wasm, wasm-gc, js, and native. | ✓ PASS |
| Hostile schedules, terminal replay, and collected wire evidence | Same package command; `PNG selected low-bit Adam7 chunk qualifies every hostile lease schedule` and `PNG selected low-bit Adam7 chunk replays released lease failures` | Included in the mainline result; source inspection confirms all depth/schedule/terminal assertions use the explicit Adam7 route. | ✓ PASS |
| Independent Type-3 raster and public decoding | Same package command through the hostile-matrix test helpers | Included in the mainline result; the parser uses collected stream bytes plus literals/local arithmetic, not eager bytes or production packers. | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| INDEXLOWADAM7-05 | 84-01 | Low-bit Adam7 chunk output has eager parity under hostile leases, accepted-only totals/tails, sticky released failure, and untouched completed replay. | ✓ SATISFIED | All depth/schedule matrix plus dedicated released-lease test and seven-byte finished replay assertions. |
| INDEXLOWADAM7-06 | 84-01 | Independent selected-depth wire/raster/decode proof, frozen Type-3 compatibility vectors, and four-target ordinary package gate. | ✓ SATISFIED | Collected-byte signature/framing/CRC/Stored/local-packing/RGBA/RGB assertions, source-only test diff, and 298-per-target mainline gate. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| — | — | No phase-introduced TODO/FIXME/XXX/HACK/placeholder, empty implementation, production path, duplicate stream/encoder, or staging buffer. `git diff --check a403933^..43c573d -- modules/mb-image/png` is clean. | — | — |

### Scope and Compatibility Check

- The four Phase 84 commits modify only `modules/mb-image/png/stream_encode_test.mbt`; no production encoder, machine, model, filter, compression, FFI, wrapper, copied tree, or release artifact changed.
- All new route construction explicitly uses the existing selected-depth `Adam7` facade. The existing `present → destination.set → acknowledge` lifecycle remains the subject under test.
- The phase adds no low-bit strategy expansion or alternate parser/encoder. Its local pass table is test-only independent evidence.
- Current HEAD contains documentation only after the final Phase 84 test commit; there is no later PNG source/test change that invalidates the supplied package evidence.
- The only dirty worktree item is the pre-existing unrelated v0.21 research input; it was not modified.

## Gaps Summary

No implementation gap found. The code-review runner's earlier all-target invocation exceeded its command window without diagnostic output, but the supplied mainline final run completed at 298/298 on every declared target and the PNG source is unchanged thereafter.

## VERDICT: PASS

Both Phase 84 requirements and every roadmap success criterion are achieved in the current codebase. The admitted low-bit Adam7 routes have real caller-lease behavior tests, independent collected-byte wire/decode qualification, frozen compatibility coverage, and recorded four-target proof without an architecture change.

---

_Verified: 2026-07-24T04:14:50Z_
_Verifier: the agent (gsd-verifier)_
