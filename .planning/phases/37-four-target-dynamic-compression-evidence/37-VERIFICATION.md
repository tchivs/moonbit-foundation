---
phase: 37-four-target-dynamic-compression-evidence
verified: 2026-07-21T22:12:36Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 37: Four-Target Dynamic Compression Evidence Verification Report

**Phase Goal:** Maintainers can reproduce portable evidence that the explicit dynamic route is deterministic, strictly wins where intended, and decodes faithfully through the public PNG API.

**Verified:** 2026-07-21T22:12:36Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A generated periodic five-symbol RGB8 and straight-RGBA8 corpus is available in memory and remains literal-heavy for the retained distance-1-through-4 matcher. | ✓ VERIFIED | `png_stream_test_dynamic_corpus_image` creates `128x1` images through `png_stream_test_image`; it fills every component with `((x * channels + channel) % 5)`. The underlying image helper selects RGB8 for 3 channels and RGBA8 with `AlphaMode::Straight` for 4 channels. |
| 2 | On every supported target, DynamicOrFixedOrStored emits `BTYPE=10` and is strictly smaller than unchanged FixedOrStored for both corpus records. | ✓ VERIFIED | `png_stream_test_dynamic_corpus_case` uses the public Dynamic and FixedOrStored eager factories, rejects both `Dynamic > Fixed` and `Dynamic >= Fixed`, and checks `(eager_first[43] & 0x07) == 0x05` (final LSB-first Dynamic block). The named test passed separately on js, wasm, wasm-gc, and native. |
| 3 | Repeated eager and hostile caller-buffered Dynamic encodes are byte-identical for both corpus records. | ✓ VERIFIED | The case creates two Dynamic eager outputs and a `PngChunkEncoder::new_with_compression_strategy` output drained with `[0, 1, 3, 2, 5]`; it rejects either unequal result. The named behavior test passed on all four targets. |
| 4 | Every eager and chunk Dynamic corpus result completely decodes through the public PNG API with descriptor and component fidelity. | ✓ VERIFIED | Each of the first eager, second eager, and chunk bytes feeds `PngDecoder::new` with `require_complete_input=true`; the shared oracle compares width, height, channel count, and every source component. The named test passed on all four targets. |

**Score:** 4/4 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/stream_encode_test.mbt` | Named public four-target Dynamic corpus, relative-size, BTYPE, eager/chunk determinism, and complete-decode evidence | ✓ VERIFIED | Exists and is substantive. Commit `25b4c31` adds 58 test-only lines: corpus generator, public-strategy case helper, and exactly one named test. The current file has no TODO/FIXME/XXX/HACK/placeholder marker and no uncommitted change. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png_stream_test_dynamic_corpus_case` | `PngEncoder::new_with_compression_strategy` and `PngChunkEncoder::new_with_compression_strategy` | Public FixedOrStored and DynamicOrFixedOrStored factories | ✓ WIRED | `png_stream_test_eager_with_strategy` invokes the eager public factory; the case directly creates the Dynamic chunk encoder from the same source before comparing all three Dynamic byte streams. |
| Dynamic eager and chunk `Bytes` | `PngDecoder::new` | Complete-input descriptor-and-component oracle | ✓ WIRED | The case calls the oracle three times; it materializes the bytes, invokes public `ImageDecoder::decode(PngDecoder::new(), ...)`, requires complete input, and checks descriptor fields plus every component. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `stream_encode_test.mbt` Dynamic corpus case | `eager_first`, `eager_second`, `chunked` | Generated in-memory RGB8/RGBA8 image → public Dynamic encoder adapters → PNG bytes → public decoder → restored image view | Yes — the test compares emitted complete PNG byte lengths/BTYPE/parity, then every decoded component to the generated source. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Named Dynamic corpus test is selectable and passes on js | `moon -C modules/mb-image test png --target js --frozen --outline -f '*PNG dynamic corpus evidence*'`; filtered test in `_build/phase37-verification/js` | Named exactly once; 1/1 passed | ✓ PASS |
| Named Dynamic corpus test is selectable and passes on wasm | Same command with `--target wasm`; filtered test in `_build/phase37-verification/wasm` | Named exactly once; 1/1 passed | ✓ PASS |
| Named Dynamic corpus test is selectable and passes on wasm-gc | Same command with `--target wasm-gc`; filtered test in `_build/phase37-verification/wasm-gc` | Named exactly once; 1/1 passed | ✓ PASS |
| Named Dynamic corpus test is selectable and passes on native | Same command with `--target native`; filtered test in `_build/phase37-verification/native` | Named exactly once; 1/1 passed | ✓ PASS |
| Full PNG regression suite | `moon -C modules/mb-image test png --target {js,wasm,wasm-gc,native} --target-dir _build/phase37-verification/{target} --frozen` | 131/131 passed independently on each target | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGD-04 | `37-01-PLAN.md` | Generated literal-heavy RGB8/RGBA8 corpus proves BTYPE=10, strict Dynamic win over FixedOrStored, eager/chunk determinism, and complete decode on four targets. | ✓ SATISFIED | The single named public test exercises both generated channel formats and all specified public encoding/decoding routes; its selection and execution were independently confirmed on every supported target. |

No Phase 37 requirement is orphaned: `PNGD-04` is declared by the sole plan and is the only requirement mapped to this phase. No later milestone phase covers an unmet item, so there are no deferred items.

### Anti-Patterns Found

None. `git diff --check 25b4c31^ 25b4c31` is clean; the implementation commit changes only the intended test file. The current test file contains no unresolved debt marker or placeholder pattern.

### Gaps Summary

No gaps found. The verifier independently executed the claimed four-target evidence; all must-haves, public links, and the complete data flow are exercised by passing behavior tests.

---

_Verified: 2026-07-21T22:12:36Z_
_Verifier: the agent (gsd-verifier)_
