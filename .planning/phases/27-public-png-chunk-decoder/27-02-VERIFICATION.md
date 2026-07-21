---
phase: 27-public-png-chunk-decoder
verified: 2026-07-21T11:02:30Z
status: gaps_found
score: 3/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 0/4
  gaps_closed:
    - "Arbitrary caller-owned partitions, exact accepted-byte accounting, no pre-finish result, and caller-view mutation/reuse evidence."
    - "Eager/chunk result, typed-error, diagnostics, and remaining-budget parity across the generated corpus."
    - "Independent all-target PNG package and isolated PNG quality qualification."
  gaps_remaining:
    - "The frozen EOF classifier matrix has no executable fixed-Huffman or dynamic-Huffman paused-inflater prefix, nor zero-length wrong/completed non-IEND type rows."
  regressions: []
gaps:
  - truth: "finish() has executable public and white-box evidence for every frozen incomplete-state context and precedence rule, and both push and finish replay the first typed terminal error with zero later consumption."
    status: partial
    reason: "The only `png_wb_assert_incomplete` zlib prefixes are stored-block prefixes. The test named `PNG chunk EOF classifier gives zlib precedence across inflater pauses` does not construct a fixed-Huffman token or dynamic-Huffman tree/match pause. Its IEND companion covers partial type bytes but not a zero-length wrong fourth type nor a completed zero-length non-IEND type. These rows are expressly required by the frozen table and 27-02 plan."
    artifacts:
      - path: modules/mb-image/png/stream_decode_wbtest.mbt
        issue: "Classifier test matrix omits fixed/dynamic paused inflater prefixes and two zero-length IEND type rows."
    missing:
      - "Add public-finish/private-classifier paired prefixes that pause a fixed-Huffman token and dynamic tree/match, asserting zlib-truncated wins over open IDAT/IEND framing."
      - "Add zero-length wrong-fourth-type and completed non-IEND-type prefixes, asserting png-iend-type plus sticky replay and exact consumed counts."
---

# Phase 27: Public PNG Chunk Decoder Re-verification Report

**Phase Goal:** Library users can submit caller-owned PNG byte chunks to `PngChunkDecoder` and explicitly complete one eager-equivalent decode without changing existing `Reader` EOF semantics.

**Verified:** 2026-07-21T11:02:30Z  
**Status:** gaps_found  
**Re-verification:** Yes — after 27-02 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Every active push precisely consumes dispatched bytes from arbitrary caller-owned partitions, yields `NeedInput` without an image, and retains no caller view. | ✓ VERIFIED | `stream_decode_test.mbt` drives every accepted generated case one byte at a time, has mixed structural partitions, validates per-call consumption, and mutates the first owner before supplying an independent suffix. `PngChunkDecoder` stores only limits, diagnostics, state, and count; `push` obtains each byte before calling the private machine. |
| 2 | `finish()` has executable evidence for every frozen EOF context/precedence rule and preserves first terminal errors through `push` and `finish`. | ✗ FAILED | Major framing/CRC/raster/stored-zlib rows and replay are tested, but fixed/dynamic paused-inflater prefixes and the two zero-length IEND type rows are absent from the classifier matrix. |
| 3 | Chunk decoding visibly agrees with eager decoding for supported inputs and structural, DEFLATE, raster, trailing, limit, allocation, and budget failures, including diagnostics and every budget remainder. | ✓ VERIFIED | `PNG chunk decoder matches eager errors diagnostics and budget remainders for generated corpus` runs each generated vector through the public one-byte route, compares complete typed error shape or result, diagnostics rendering/length, and `png_test_remaining_unchanged` budget fields with independent eager objects. |
| 4 | The published API is policy-exact, portable, and quality-qualified. | ✓ VERIFIED | Generated MBTI exposes only the documented `PngChunk*` declarations. Independent `moon ... test png --target all --frozen` passed 81/81 on wasm, wasm-gc, js, and native; isolated `Invoke-MoonQuality.ps1 -Lane Png` passed. |

**Score:** 3/4 must-haves verified.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Public `PngChunkDecoder` API | ✓ VERIFIED | Generated MBTI confirms exact constructor, `push`, `finish`, result, and outcome declarations. |
| `modules/mb-image/png/stream_decode.mbt` | Thin private-machine adapter, finish-only transfer, sticky state | ✓ VERIFIED | `push` handles transient bytes with a preflight input ceiling; `finish` only calls `machine.finish()` from `NeedEof`, then transfers the private outcome once. |
| `modules/mb-image/png/stream_decode_test.mbt` | Public partition, ownership, parity, and terminal evidence | ✓ VERIFIED | Eight public chunk tests exercise one-byte/generated and mixed schedules, mutation/reuse, consumption, terminal replay, and parity. |
| `modules/mb-image/png/stream_decode_wbtest.mbt` | Frozen classifier and precedence evidence | ⚠️ PARTIAL | Substantive paired private/public checks exist, but the mandatory omitted rows prevent the exhaustive classifier truth from being verified. |
| `policy/foundation.json` | Exact public semantic interface | ✓ VERIFIED | PNG policy stage passed in the independent quality lane. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `stream_decode_test.mbt` | `PngChunkDecoder` | Caller-owned `OwnedBytes` views → `push` → `finish` | ✓ WIRED | Executed 13 targeted public chunk tests successfully. |
| `stream_decode_wbtest.mbt` | `PngDecodeMachine::chunk_incomplete_error` and public `finish` | `png_wb_assert_incomplete` compares private classifier with the equivalent public route | ✓ WIRED | Covers its supplied prefixes and sticky replay; missing rows are a coverage failure, not an unwired artifact. |
| `stream_decode.mbt` | `PngDecodeMachine`/`PngRasterSink` | `push` dispatches bytewise; classifier consults inflater/lifecycle before framing; `finish` gates `into_decode_result` | ✓ WIRED | Static source inspection confirms the intended private outcome boundary. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Targeted public/wb chunk contract | `moon -C modules/mb-image test png --target native --frozen -f '*PNG chunk*'` | 13/13 passed | ✓ PASS |
| Complete portable PNG suite | `moon -C modules/mb-image test png --target all --frozen` | 81/81 passed on wasm, wasm-gc, js, native | ✓ PASS |
| Generated decode corpus freshness | `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | 3,850 executable cases checked | ✓ PASS |
| Isolated PNG qualification | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | Policy, negative fixtures, structural/decode vectors, workflow, four targets, and lane isolation passed | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGS-01 | 27-01, 27-02 | Arbitrary caller chunks, deterministic non-terminal progress, no image before strict completion | ✓ SATISFIED | One-byte and mixed schedules, explicit pending-IEND test, exact accepted counts, and ownership mutation test are executed. |
| PNGS-02 | 27-01, 27-02 | Explicit eager-equivalent result or sticky typed terminal error | ✗ BLOCKED | Eager parity and most terminal paths are executed, but the phase explicitly froze an exhaustive EOF matrix and three required rows remain without behavior evidence. |

### Anti-Patterns Found

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in Phase 27 production or test artifacts. Existing compiler warnings are outside this phase's missing behavior evidence and did not fail the quality lane.

### Gaps Summary

The functional adapter, broad parity suite, portable test suite, vectors, and isolated quality lane all pass. This verification remains blocked only because Phase 27's own frozen contract requires every EOF classifier row to be executable. The current test names overstate their coverage: the zlib precedence list supplies stored prefixes only, and the IEND matrix stops before wrong/completed zero-length alternate types. Add the five small paired prefix cases listed in the frontmatter, then re-run the focused chunk tests and this verification.

---

_Verified: 2026-07-21T11:02:30Z_  
_Verifier: gsd-verifier_
