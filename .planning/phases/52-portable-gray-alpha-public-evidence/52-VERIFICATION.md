---
phase: 52-portable-gray-alpha-public-evidence
verified: 2026-07-22T19:36:37Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 52: Portable Gray+Alpha Public Evidence Verification Report

**Phase Goal:** Library users can rely on documented Gray+Alpha8 PNG fidelity and caller-buffered semantics across every supported portable target while legacy output remains stable.
**Verified:** 2026-07-22T19:36:37Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Public non-symmetric GrayAlpha8 vectors prove exact type-4 PNG wire-pair preservation and decode canonicalization to straight RGBA8. | ✓ VERIFIED | `encode_test.mbt:919-935` uses only `PngEncoder::new_graya8_with_strategies(Stored, None)` for a real `(13,A7)/(D2,4C)` image and asserts the PNG signature, IHDR `08 04 00`, and literal Stored scanline `00 13 A7 D2 4C`. `png_encode_graya8_decode_matches_source` (`383-410`) decodes those bytes through `ImageDecoder::decode(PngDecoder::new(), ...)`, requires `Rgba`, and checks `R=G=B=gray`, `A=alpha` for both pairs. The named native test passed. |
| 2 | All six compression/filter pairs withstand zero-capacity, one-byte, and ragged caller-buffered schedules with eager byte identity, accepted-only progress, untouched tails, and sticky completion. | ✓ VERIFIED | `stream_encode_test.mbt:577-638` creates a fresh public chunk encoder per drain; it appends only `written()` bytes, requires `total_written == accepted_before + written`, preserves every `Z` tail, compares the complete output with the fresh public eager oracle, then proves a later seven-byte lease receives zero bytes and remains `Finished`. `1043-1077` applies a direct empty lease plus `[0,1]`, `[1]`, and `[0,8,4,1,13,2,5,3,21]` schedules to Stored/FixedOrStored/DynamicOrFixedOrStored × None/Adaptive. The named native test passed. |
| 3 | Literal Gray8, Gray16, RGB8, and straight-RGBA8 PNG compatibility vectors remain byte-identical for eager and caller-buffered routes. | ✓ VERIFIED | Eager literals are compared directly in `encode_test.mbt:775-866`; the Phase 52 addition supplies the Gray16 literal at `793-807`. Chunk literals are compared directly in `stream_encode_test.mbt:1120-1236`; the Phase 52 addition supplies Gray16 at `1139-1151`. The expected values are byte literals, not values emitted by a second encoder. The all-target suite passed. |
| 4 | The complete PNG package evidence runs unchanged on js, wasm, wasm-gc, and native. | ✓ VERIFIED | `modules/mb-image/png/moon.pkg` declares `supported_targets = "+js+wasm+wasm-gc+native"`. Independent execution of `moon -C modules/mb-image test png --target all --frozen` passed 196/196 on each of wasm, wasm-gc, js, and native. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode_test.mbt` | Public GrayAlpha8 wire/decode evidence, six-pair eager coverage, and four literal eager vectors. | ✓ VERIFIED | L1 exists. L2 is substantive: the non-symmetric source, literal wire assertion, real public decode, matrix, and literal baselines are executable test code. L3 is wired: the named test executes through `moon test`; its public factories and decoder compile and passed. |
| `modules/mb-image/png/stream_encode_test.mbt` | Public GrayAlpha8 hostile-capacity, accepted-progress, terminal, eager-parity, and frozen-vector coverage. | ✓ VERIFIED | L1 exists. L2 has a bounded drain loop with concrete failure assertions, not a placeholder. L3 is wired: the named package test invokes the helper for all six strategy/filter pairs and passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `PngEncoder::new_graya8_with_strategies` | `PngDecoder::new` | Stored/None public bytes → `ImageDecoder::decode` | ✓ WIRED | `encode_test.mbt:921-935` builds bytes with the public eager factory and passes exactly those bytes to the public decoder helper. The helper verifies canonical RGB replication and alpha preservation. |
| `PngChunkEncoder::new_graya8_with_strategies` | `PngEncoder::new_graya8_with_strategies` | Fresh chunk schedule result → fresh eager oracle equality | ✓ WIRED | The stream test derives `eager` from `png_stream_graya8_eager_with_strategies` (`684-702`) and passes it into a helper that constructs a new public chunk encoder (`577-588`) before checking complete byte equality (`611`). |

`verify.key-links` reported both plan links as unverifiable only because their `from` values are symbols rather than relative source paths; manual source and named-test tracing above verifies both actual links.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Eager public evidence | PNG bytes / decoded RGBA channels | Real packed `OwnedImage` populated with `13 A7 D2 4C` → public eager encoder → public decoder | The literal raster bytes and decoded channels are observed directly. | ✓ FLOWING |
| Chunk public evidence | Accepted byte prefix / terminal state | Same real image → fresh public chunk encoder → mutable caller leases | Only returned prefixes enter `output`; real final output is compared with the public eager bytes and terminal lease sentinels are inspected. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Wire order and public straight-RGBA8 decode | `moon -C modules/mb-image test png --target native --frozen --filter "PNG GrayAlpha8 public eager evidence"` | 1 passed, 0 failed | ✓ PASS |
| Six-pair hostile schedules, accepted-only progress, lease ownership, and sticky finish | `moon -C modules/mb-image test png --target native --frozen --filter "PNG GrayAlpha8 chunk public evidence"` | 1 passed, 0 failed | ✓ PASS |
| Portable PNG package suite | `moon -C modules/mb-image test png --target all --frozen` | 196 passed, 0 failed on each of wasm, wasm-gc, js, and native | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| GRAYA-04 | `52-01-PLAN.md` | Public GrayAlpha8 PNGs prove exact non-symmetric wire pairs and straight-RGBA8 decode canonicalization. | ✓ SATISFIED | Truth 1: literal type-4 Stored/None raster evidence plus the public decoder behavioral spot-check. |
| GRAYA-05 | `52-01-PLAN.md` | Hostile capacities preserve eager identity, accepted-only progress, sticky terminals, legacy byte vectors, and all-target execution. | ✓ SATISFIED | Truths 2–4: all-six matrix, literal eager/chunk baselines, and independent 196/196 four-target execution. |

No requirement mapped to Phase 52 is orphaned: `GRAYA-04` and `GRAYA-05` are declared in the plan and are the only Phase 52 requirements in `REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No Phase 52 additions contain `TBD`, `FIXME`, `XXX`, `TODO`, placeholder, empty-output, or console-only implementation patterns. | ℹ️ Info | No completion-blocking debt marker or test stub found. |

### Scope and Disconfirmation Checks

- Initial mode: no prior `52-VERIFICATION.md` and no overrides exist.
- Inversion checks: a header-only assertion would miss component reversal, so the test uses asymmetric pairs and asserts the literal filtered payload; a drain that merely finishes would miss attempted-byte accounting and tail mutation, so every pull verifies accepted-prefix accounting and lease sentinels; a native-only green run would miss portability, so the identical complete suite was executed on all four targets.
- The Phase implementation range `6953530..11794ab` changes only `modules/mb-image/png/encode_test.mbt` and `modules/mb-image/png/stream_encode_test.mbt`; `git diff --check` is clean. `png.mbt`, `encode.mbt`, and `stream_encode.mbt` are unchanged. No FFI, target branch, release/build change, copied source, fixture, staging buffer, retry mechanism, or new PNG capability was added.
- Disconfirmation pass found no partial roadmap criterion, misleading passing test, or uncovered behavior path within Phase 52's contract: the two state/ordering invariants each have a focused, passing named test rather than a presence-only conclusion.

### Gaps Summary

No gaps found. Public wire/decode, bounded caller-buffered ownership, frozen legacy bytes, and the required portable execution are all executable and independently confirmed.

---

_Verified: 2026-07-22T19:36:37Z_
_Verifier: the agent (gsd-verifier)_
