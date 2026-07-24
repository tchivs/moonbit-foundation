---
phase: 85-indexed-compression-api-and-fixed-wire-contract
verified: 2026-07-24T06:14:15Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 85: Indexed Compression API and Fixed Wire Contract Verification Report

**Phase Goal:** Library users can explicitly request deterministic non-interlaced Fixed-or-Stored compression for Type-3/1, /2, /4, and /8 PNG output without changing any legacy indexed Stored/filter-None byte stream.

**Verified:** 2026-07-24T06:14:15Z

**Status:** passed

**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Callers have exactly four additive non-interlaced indexed compression selectors: eager and chunk forms for Indexed8 and selected Indexed1/2/4. | VERIFIED | Exactly two eager selectors are public in `encode.mbt` (lines 2468, 2560) and exactly two chunk selectors in `stream_encode.mbt` (lines 36, 84). Filtered public tests passed for Indexed8 and selected-depth eager/chunk routes. |
| 2 | Legacy non-interlaced indexed APIs literally forward Stored/filter-None, while indexed Adam7 remains the Stored/None path. | VERIFIED | Legacy eager forwards use `PngCompressionStrategy::Stored` at `encode.mbt:2461` and `:2554`; chunk forwards do the same at `stream_encode.mbt:29` and `:78`. Adam7 facades call the Stored-only indexed constructor at `encode.mbt:2509`, `:2604`, `stream_encode.mbt:59`, and `:110`. Public Stored-parity tests passed. |
| 3 | Dynamic returns the stable indexed capability failure before indexed preflight/admission, writer progress, lease exposure, or budget mutation. | VERIFIED | The first operation in `_png_encode_indexed_preflight_with_profile_and_strategy` is the `DynamicOrFixedOrStored` guard (`encode.mbt:2234-2235`), before width/height, palette, frame, or `budget.charge` work. Eager and chunk tests assert the exact context and unchanged budget; the filtered Indexed8 and selected-depth test runs passed. |
| 4 | FixedOrStored selects Fixed exactly when its complete palette-aware Type-3 frame is no larger than Stored, including equality. | VERIFIED | Both candidates use `_png_frame_facts(source.palette_length(), trns_length, idat_length)` (`encode.mbt:2309-2315`, `:2333-2336`), and the winner condition is `fixed_frame.total_length <= stored_frame.total_length` (`:2336`). The all-depth matrix test passed: Fixed winner uses `<=`; 81-byte Fixed versus 76-byte Stored falls back to Stored. |
| 5 | The selected non-interlaced route uses one bounded filter-None indexed raw-byte/match producer with the existing matcher, Fixed emitter, and acknowledged machine. | VERIFIED | `PngMatchProducer::IndexedNone(PngIndexedRawCursor)` is the only indexed producer variant (`encode.mbt:1165-1167`); `new_indexed` retains the existing 262-byte matcher window (`:1285-1292`). The same cursor type feeds Fixed planning (`:2324-2328`), Stored traversal (`stream_encode.mbt:1055-1059`), and Fixed replay (`:1060-1068`); `fixed_preview_byte` stages state and `acknowledge` commits it (`stream_encode.mbt:1322-1458`, `:1793-1798`). The existing fixed replay white-box test is present at `stream_encode_wbtest.mbt:641`. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode.mbt` | Eager selectors, early strategy validation, candidate facts, and shared indexed producer. | VERIFIED | Substantive implementation at lines 1165-1292, 2226-2390, and 2453-2589. Both selector facades wire to the indexed machine seam. |
| `modules/mb-image/png/stream_encode.mbt` | Chunk selectors through the sole acknowledged machine. | VERIFIED | Public chunk selectors at lines 23-96 converge at `new_with_indexed_profile_and_strategy` (1027-1077); no parallel encoder or state machine was added. |
| `modules/mb-image/png/encode_test.mbt` | Public eager compatibility, selection, and rejection coverage. | VERIFIED | Indexed8 and selected-depth selector tests at lines 922 and 992 passed under filtered native execution. |
| `modules/mb-image/png/stream_encode_test.mbt` | Public chunk/eager parity and Dynamic-rejection coverage. | VERIFIED | Indexed8 and selected-depth chunk tests at lines 4977 and 5009 passed under filtered native execution. |
| `modules/mb-image/png/encode_wbtest.mbt` | Palette-aware all-depth choice facts. | VERIFIED | Matrix at lines 1386-1420 passed, including canonical one-byte `tRNS`, Fixed-on-tie rule, and Stored fallback. |
| `modules/mb-image/png/stream_encode_wbtest.mbt` | Acknowledgement-safe Fixed replay invariant. | VERIFIED | Existing sticky Fixed replay test remains at line 641; production replay uses the same `PngFixedState` path. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| Indexed eager and chunk selectors | `PngEncodeMachine::new_with_indexed_profile_and_strategy` | Direct calls from both selector pairs. | WIRED | Eager calls at `encode.mbt:2477,2570`; chunk calls at `stream_encode.mbt:43,92`. |
| Indexed producer | Stored traversal, Fixed planning, Fixed replay | `PngFilteredMatchCursor::new_indexed`. | WIRED | Planning creates it at `encode.mbt:2324`; machine creates identical bounded cursors for Stored and Fixed at `stream_encode.mbt:1055-1068`. |
| Palette/transparency facts | Fixed-or-Stored decision | `_png_frame_facts` candidate totals and `<=`. | WIRED | Stored and Fixed frames include actual PLTE and shortest `tRNS` lengths before comparison at `encode.mbt:2301-2344`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `encode.mbt` indexed producer | Raw filter-None scanline byte | Immutable `PngIndexedImage` indices, packed in `PngIndexedRawCursor::next`. | Yes — emits filter byte, indexed bytes, and zero low-bit tail directly from the source. | FLOWING |
| `stream_encode.mbt` acknowledged machine | Stored/Fixed zlib bytes | Same producer cursor supplied to selected machine state. | Yes — passed eager/chunk parity tests exercise emitted bytes. | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| All-depth frame-aware Fixed/Stored selection | `moon -C modules/mb-image test png --target native --frozen --filter "*indexed compression matrix selects Fixed and Stored at every depth*"` | 1 passed, 0 failed. | PASS |
| Selected-depth public eager/chunk APIs, Stored parity, Dynamic rejection | `moon -C modules/mb-image test png --target native --frozen --filter "*indexed*compression*"` | 3 passed, 0 failed. | PASS |
| Indexed8 public eager/chunk APIs, Stored parity, Dynamic rejection | `moon -C modules/mb-image test png --target native --frozen --filter "*Indexed8 compression*"` | 2 passed, 0 failed. | PASS |
| Whole PNG package gate | `moon -C modules/mb-image test png --target native --frozen` | Timed out after 34 seconds without a result in this verifier environment. Filtered relevant tests passed; this is not counted as package-gate evidence. | INFO |

### Probe Execution

Step 7c: SKIPPED — this phase declares no probe scripts and contains no migration or CLI probe contract.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| INDEXCOMP-01 | 85-01-PLAN.md | Explicit Stored/FixedOrStored selectors, byte-frozen Stored compatibility, and early Dynamic rejection. | SATISFIED | Truths 1-3; public filtered test runs passed. |
| INDEXCOMP-02 | 85-01-PLAN.md | Single bounded producer and complete-frame Fixed-or-Stored choice without prohibited architecture. | SATISFIED | Truths 4-5; all-depth white-box matrix passed. |

No requirement mapped to Phase 85 is orphaned from the plan.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or hardcoded-empty output pattern found in the Phase 85 production/test files. | INFO | No completion-debt blocker. |

### Scope-Fence Check

The Phase 85 production diff adds no indexed Dynamic route: the only new indexed `DynamicOrFixedOrStored` branches return `indexed-dynamic-compression-unavailable`. It adds no adaptive selector, indexed Adam7 compression selector, staging collection, second encoder, matcher widening, FFI, copied tree, or generic public source-model API. The private producer is a tagged variant beneath the pre-existing bounded matcher and retains its 262-byte window.

### Gaps Summary

None. The code and relevant executed tests prove the Phase 85 contract. The whole-package native command did not finish within the verifier timeout, but focused tests covering every new selector and wire-choice contract passed; four-target and hostile-lease qualification are explicitly Phase 87 scope.

---

_Verified: 2026-07-24T06:14:15Z_

_Verifier: the agent (gsd-verifier)_
