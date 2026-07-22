---
phase: 46-portable-gray8-public-evidence
verified: 2026-07-22
verifier: orchestrator
status: passed
score: 3/3
---

# Phase 46: Portable Gray8 Public Evidence — Verification

## Result

**VERIFICATION PASSED** — all `GRAYPNG-03` acceptance conditions are present in public tests and were independently executed in each supported target by the orchestrator.

## Must-have evidence

### 1. Generated public eager Gray8 fidelity — PASS

`modules/mb-image/png/encode_test.mbt` creates a deterministic 5×3 `Gray`/one-channel source and loops through all three compression strategies with both `None` and `Adaptive` filtering. Each case uses the public `PngEncoder::new_gray8_with_strategies`, encodes through `ImageEncoder::encode`, then decodes through `PngDecoder`.

The test asserts the encoded IHDR is 8-bit, color type 0, and non-interlaced. It then asserts preserved dimensions and every source sample. `PngDecoder` deliberately canonicalizes Gray PNG into RGB8, so the test verifies its documented public result (`Rgb`, three channels) and requires every decoded R/G/B component to equal the original gray sample. This is a semantic fidelity proof, not a private implementation or opaque byte-snapshot check.

### 2. Caller-buffered hostile capacity identity — PASS

`modules/mb-image/png/stream_encode_test.mbt` uses fresh public `PngChunkEncoder::new_gray8_with_strategies` instances for every strategy/filter pair. It first checks a zero-capacity lease produces `NeedOutput` with zero accepted and total bytes, then checks zero-prefixed, one-byte, and ragged schedules against the matching public eager bytes.

The existing `png_chunk_test_drain_encoder` remains the sole drain oracle; after every pull it verifies `total_written` equals the bytes actually accepted from caller leases. No staging path or alternate stream driver was added.

### 3. Compatibility and four-target portability — PASS

Existing frozen RGB8 and straight-RGBA8 literal-byte vectors remain in the ordinary eager and chunk PNG test files, so they execute with the new Gray8 evidence. The exact package suite was run separately after both Phase 46 test tasks:

| Target | Command | Result |
| --- | --- | --- |
| js | `moon -C modules/mb-image test png --target js --frozen` | 181 passed, 0 failed |
| wasm | `moon -C modules/mb-image test png --target wasm --frozen` | 181 passed, 0 failed |
| wasm-gc | `moon -C modules/mb-image test png --target wasm-gc --frozen` | 181 passed, 0 failed |
| native | `moon -C modules/mb-image test png --target native --frozen` | 181 passed, 0 failed |

## Scope check

Only `encode_test.mbt` and `stream_encode_test.mbt` changed for the plan. There are no production encoder/API, CI, release, publication, or script changes. The resolved Phase 46 debug record confirms the one issue found was a test-oracle correction for existing decoder RGB canonicalization; it did not require a product-code change.

