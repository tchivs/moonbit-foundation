---
phase: 82-indexed8-adam7-streaming-and-qualification
verified: 2026-07-24T00:36:36Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 82: Indexed8 Adam7 Streaming and Qualification — Verification Report

**Phase Goal:** The same admitted Indexed8 Adam7 machine is usable through caller-owned leases with eager-identical bytes, sticky outcomes, independent transport evidence, frozen compatibility, and four-target proof.

**Verified:** 2026-07-24T00:36:36Z  
**Status:** passed  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Zero-capacity, one-byte, and ragged leases reproduce fresh eager Adam7 bytes; progress counts accepted bytes only and unaccepted lease tails stay caller-owned. | ✓ VERIFIED | `png_stream_indexed8_adam7_hostile_drain` creates fresh eager and `new_indexed8_with_interlace_strategy(..., Adam7, ...)` instances, exercises `[0,1]`, `[1]`, `[0,1,3,2,5]`, and terminal-tail `[0,1,3,2,5,7]` schedules, appends only `written` bytes, requires `total_written == accepted_before + written`, and checks every remaining `Z` byte. |
| 2 | Released leases yield sticky zero-write failures; repeated finished pulls yield zero-write `Finished` without mutating later destinations. | ✓ VERIFIED | `png_stream_indexed8_adam7_released_failure` releases the first one-byte lease, then checks same-error `Failed`, zero writes/totals, and both sentinels. The hostile drain makes a later seven-byte pull after `Finished` and checks zero write, unchanged total, `Finished`, and all seven `Z` bytes. |
| 3 | Chunk-origin output independently proves framed Type-3/8 Adam7 bytes, CRCs, seven-pass raster, and public palette decode rather than only eager parity. | ✓ VERIFIED | The drain passes its collected `Bytes::from_array(output)` to `png_stream_indexed8_adam7_chunk_origin_qualification`, which checks 143-byte frame length, IHDR `08 03 00 00 01`, PLTE, canonical three-byte `tRNS`, IDAT/IEND ordering and all CRCs; it compares test-local Stored extraction with the literal 36-byte oracle and public-decodes all 25 RGBA pixels. |
| 4 | Existing Indexed8 opaque/transparent and Indexed1/2/4 non-interlaced literal vectors remain frozen. | ✓ VERIFIED | Phase diff `4bf8664..226192f` changes only `stream_encode_test.mbt` (+199/-0); `encode_test.mbt`, which owns the frozen vector tests, is untouched. The ordinary package evidence executes the unchanged tests together with Phase 82 coverage. |
| 5 | The ordinary frozen PNG package gate passes on wasm, wasm-gc, js, and native. | ✓ VERIFIED | Mainline final evidence records `moon -C modules/mb-image test png --target all --frozen` at **291/291 passed on each target**. `modules/mb-image/moon.mod.json` declares `+js+wasm+wasm-gc+native`; `git diff --name-only 226192f..HEAD -- modules/mb-image/png` is empty, so this evidence applies to the current PNG source. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/stream_encode_test.mbt` | Indexed8 Adam7 hostile drain, released-lease replay, independent parser/raster evidence, and public decode qualification. | ✓ VERIFIED | Exists and is substantive: the Phase 82 block contains the two registered tests plus source/eager/parser/drain/failure helpers. The four-target package evidence executes the test package; source has no TODO/FIXME/XXX/HACK/placeholder or empty implementation markers. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| Adam7 qualification helper | Existing caller-buffered machine | `PngChunkEncoder::new_indexed8_with_interlace_strategy(..., PngInterlaceStrategy::Adam7, ...)` then real `MutByteLease` pulls | ✓ WIRED | Both hostile-drain and released-lease helpers use the explicit Adam7 factory and invoke `encoder.pull(lease)`; no test-owned encoder or transport exists. |
| Accepted bytes from chunk drain | Independent wire/decode evidence | `Bytes::from_array(output)` into parser, Stored extractor, then public `PngDecoder` | ✓ WIRED | The parser receives `chunk_bytes` collected solely from accepted caller lease prefixes, after equality is checked; it does not inspect eager bytes as its framing/raster/decode input. |
| Frozen compatibility vectors | Four-target qualification | Ordinary `moon ... test png --target all --frozen` package gate | ✓ WIRED | Existing `encode_test.mbt` vector tests remain in the PNG package and the recorded 291-per-target result covers that same package. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Hostile chunk qualification | `output` / `chunk_bytes` | Real `PngChunkEncoder::pull` writes into owned caller leases; only `written` prefixes enter `output` | Collected output is compared to fresh eager bytes, then parsed and decoded | ✓ FLOWING |
| Independent Adam7 raster check | `png_encode_public_stored_scanlines(chunk_bytes, 36)` | Test-only extraction of the drained IDAT payload | Compared against `png_indexed8_adam7_expected_raw()`, a hand-authored literal 36-byte seven-pass oracle | ✓ FLOWING |
| Public RGBA verification | decoded image view | `PngDecoder::new()` over an owned copy of `chunk_bytes` | All 25 source-indexed palette RGB and alpha pixels are asserted | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Full ordinary PNG package on all production targets | `moon -C modules/mb-image test png --target all --frozen` | Mainline final evidence: 291/291 passed on wasm, wasm-gc, js, and native. | ✓ PASS |
| Registered Adam7 hostile and terminal tests | Same package command; `PNG Indexed8 Adam7 chunk hostile leases qualify stream-origin bytes` and `PNG Indexed8 Adam7 chunk replays released lease failure` | Included in the mainline result; direct inspection confirms their concrete schedule, terminal, and decode assertions. | ✓ PASS |
| Local native test-file recheck | `moon -C modules/mb-image test png/stream_encode_test.mbt --target native --frozen` | Timed out after 64 seconds without compiler or test-failure output, so it is not treated as a pass/fail substitute for the recorded all-target mainline result. | ? ENVIRONMENT TIMEOUT |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| INDEXADAM7-05 | 82-01 | Caller-buffered Indexed8 Adam7 output reuses the bounded eager machine, is byte-identical under hostile leases, preserves accepted-only progress/tails, and has sticky terminals. | ✓ SATISFIED | Fresh eager/chunk construction under the required schedules, per-pull accounting/tail assertions, and explicit released/finished replay coverage in `stream_encode_test.mbt`. |
| INDEXADAM7-06 | 82-01 | Independent seven-pass wire evidence, public decode, frozen Indexed8/low-bit vectors, and ordinary package gate qualify four targets. | ✓ SATISFIED | Chunk-origin framing/CRC/literal-raster/public-decode assertions, unchanged frozen vector source, and recorded 291/291 four-target package result. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| — | — | No phase-introduced TODO/FIXME/XXX/HACK/placeholder, empty handler, hardcoded output path, or duplicate transport. `git diff --check 4bf8664..HEAD` is clean. | — | — |

### Scope and Compatibility Check

- Phase commits `5520dd1`, `8e27a00`, and `226192f` modify only `modules/mb-image/png/stream_encode_test.mbt`; no production PNG file is in their name-status output.
- The test uses the Phase 81 public Adam7 selector and the existing pull lifecycle. No new stream, encoder, indexed source model, filter/compression strategy, low-bit Adam7 path, FFI, wrapper, staging layer, copied tree, or release automation is introduced.
- Current HEAD contains only documentation after the last Phase 82 test commit; no later PNG source/test diff invalidates the recorded mainline package result.
- The only dirty worktree item is the pre-existing, unrelated untracked Phase 66 research input; it was not read as evidence or modified.

## Gaps Summary

No implementation gap found. The only local execution limitation was a native test-file rerun that timed out without diagnostic output; it does not contradict the supplied mainline all-target result of 291/291 on every declared target, and the current PNG code is unchanged since that result.

## VERDICT: PASS

All Phase 82 roadmap success criteria and both mapped requirements are achieved by the current codebase. The phase provides executable hostile caller-lease and independent chunk-origin qualification over the Phase 81 machine without production scope expansion.

---

_Verified: 2026-07-24T00:36:36Z_  
_Verifier: the agent (gsd-verifier)_
