---
phase: 34-portable-png-compression-corpus-evidence
verified: 2026-07-21T19:52:05Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 34: Portable PNG Compression Corpus Evidence Verification Report

**Phase Goal:** Maintainers can reproduce four-target evidence that the opt-in optimized strategy remains valid and deterministic while delivering measured compression wins for its intended repetitive-image cases.
**Verified:** 2026-07-21T19:52:05Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | The stable corpus generates exactly flat 32x1 RGB8 and straight-RGBA8 sources with `0xaa` components, then proves FixedOrStored is never larger than explicit Stored and strictly smaller for both records. | VERIFIED | The one named test calls `png_stream_test_fixed_or_stored_corpus_case` exactly twice with `png_stream_test_flat_image(3UL, 32UL)` and `(4UL, 32UL)` ([stream_encode_test.mbt](D:/source/moonbit-foundation/modules/mb-image/png/stream_encode_test.mbt:260)). The helper creates width `32`, height `1`, RGB8/RGBA8 (with Straight alpha for RGBA), overwrites every component with `b'\\xaa'`, encodes explicit Stored and FixedOrStored, and separately aborts on `optimized > stored` and `optimized >= stored` ([stream_encode_test.mbt](D:/source/moonbit-foundation/modules/mb-image/png/stream_encode_test.mbt:21), [stream_encode_test.mbt](D:/source/moonbit-foundation/modules/mb-image/png/stream_encode_test.mbt:82), [stream_encode_test.mbt](D:/source/moonbit-foundation/modules/mb-image/png/stream_encode_test.mbt:130)). The named test passed on js, wasm, wasm-gc, and native. |
| 2 | Two FixedOrStored eager encodes and configured caller-buffered output drained under `[0, 1, 3, 2, 5]` produce identical bytes for each corpus record. | VERIFIED | The helper constructs two independent configured eager encoders and a configured `PngChunkEncoder`, drains the latter with the exact schedule, and aborts unless all three byte sequences are equal ([stream_encode_test.mbt](D:/source/moonbit-foundation/modules/mb-image/png/stream_encode_test.mbt:131)). The named test passed independently once on every declared target. |
| 3 | Both optimized byte sequences complete-input decode to matching dimensions, channel count, and every generated source component on js, wasm, wasm-gc, and native. | VERIFIED | The decode oracle materializes `OwnedBytes`, calls public `PngDecoder` through `ImageDecoder::decode` with `require_complete_input=true`, checks descriptor width/height/channel count, then compares every `y`/`x`/channel component. It exercises each eager result and chunk result ([stream_encode_test.mbt](D:/source/moonbit-foundation/modules/mb-image/png/stream_encode_test.mbt:96)). The exact test passed 1/1 on js, wasm, wasm-gc, and native. |
| 4 | Every target outline names the one corpus test before isolated filtered execution, and the existing PNG quality lane remains the broader regression gate. | VERIFIED | For js, wasm, wasm-gc, and native, `moon ... --outline -f '*PNG fixed-or-stored corpus evidence*'` listed exactly one occurrence of the exact test name, followed by a dedicated `--target-dir` filtered run that passed 1/1. The phase diff changes only the package test; it adds no script or quality-lane bypass. The quality lane itself has **no passing verdict**: the executor summary records a 120-second timeout, and this verifier stopped a new invocation after 104 seconds on the instruction not to re-run the known long-running lane. This truth is about retaining the broader gate, not treating its uncompleted run as a pass. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `modules/mb-image/png/stream_encode_test.mbt` | Named public PNG compression corpus evidence with a source-component decode oracle and FixedOrStored/Stored relative-size assertions. | VERIFIED | **L1:** exists. **L2:** 780+ lines with concrete image construction, encoding, decoder, component-loop, and abort assertions; no phase-diff TODO/FIXME/XXX/HACK/placeholder or empty implementation. **L3:** the named package test directly invokes the corpus helper. **L4:** generated source bytes flow through public eager/chunk encoders into completed `Bytes`, then through the public decoder and are compared to the original source. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `png_stream_test_fixed_or_stored_corpus_case` | `PngEncoder::new_with_compression_strategy` and `PngChunkEncoder::new_with_compression_strategy` | Explicit Stored baseline, repeated FixedOrStored eager construction, configured chunk drain | WIRED | The eager helper calls configured `PngEncoder`; the corpus helper calls it once with Stored and twice with FixedOrStored, then constructs `PngChunkEncoder::new_with_compression_strategy` using FixedOrStored ([stream_encode_test.mbt](D:/source/moonbit-foundation/modules/mb-image/png/stream_encode_test.mbt:64), [stream_encode_test.mbt](D:/source/moonbit-foundation/modules/mb-image/png/stream_encode_test.mbt:130)). |
| Optimized eager and chunk `Bytes` | `PngDecoder::new` complete-input decode | Descriptor and component comparison to source | WIRED | The corpus helper passes all optimized outputs to the oracle; it calls `PngDecoder::new` with complete-input decoding and compares source data ([stream_encode_test.mbt](D:/source/moonbit-foundation/modules/mb-image/png/stream_encode_test.mbt:96)). |

`verify.key-links` reported both declarative links as unparseable because the plan uses function/component names rather than relative source paths. That is a limitation of that schema probe, not an absent connection; the manual source trace above verifies both links.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `stream_encode_test.mbt` corpus helper | `source`, `stored`, `eager_first`, `eager_second`, `chunked` | In-memory OwnedImage populated with every component `0xaa`; public eager/chunk encoders; public decoder | Yes — completed PNG bytes are emitted, decoded, and component-compared rather than using fixtures or static expected output. | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Exact corpus test is selectable once and passes in an isolated js target directory | `moon -C modules/mb-image test png --target js --frozen --outline -f '*PNG fixed-or-stored corpus evidence*'`; filtered run with `--target-dir _build/png-phase34-verification/js` | Exact name listed once; 1/1 passed | PASS |
| Same corpus test on wasm | Same command pattern with `--target wasm` | Exact name listed once; 1/1 passed | PASS |
| Same corpus test on wasm-gc | Same command pattern with `--target wasm-gc` | Exact name listed once; 1/1 passed | PASS |
| Same corpus test on native | Same command pattern with `--target native` | Exact name listed once; 1/1 passed | PASS |
| Complete portable PNG regression | `moon -C modules/mb-image test png --target all --frozen` | 114/114 passed on wasm, wasm-gc, js, and native | PASS |
| Scoped PNG quality lane | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | No current pass/fail result. The submitted summary says its run exceeded 120 seconds and was terminated; this verifier stopped a fresh run at 104 seconds on instruction not to repeat the known long-running check. | NOT COMPLETED — not counted as pass |

### Probe Execution

No phase-declared or conventional `scripts/*/tests/probe-*.sh` probes were found. This phase's executable evidence is the named MoonBit test, which was run above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| PNGC-04 | `34-01-PLAN.md` | Reproducible deterministic corpus with decoder round trips, FixedOrStored never larger than Stored, and a declared flat RGB8/RGBA8 compression win. | SATISFIED | Both declared cases are generated and verified by the one named test; independent outline plus isolated execution passed on all four supported targets, and the complete portable PNG suite passed. |

No orphaned Phase 34 requirements were found. There are no later roadmap phases to which a gap could be deferred.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | No phase-diff debt markers, placeholders, empty handlers, static output, or formatting errors found. | — | No blocker. |

## Disconfirmation Pass

- **Partial-requirement check:** the relative-size proof uses the required explicit Stored baseline, not an optimized-vs-optimized comparison; both non-strict and strict predicates are independently present.
- **Misleading-test check:** the target filter cannot false-green on zero matches: every target outline was checked for exactly one exact test-name occurrence before the filtered run.
- **Uncovered-error-path check:** resource/admission and sticky-terminal error paths are intentionally outside PNGC-04's deterministic corpus claim and remain covered by the existing PNG suite; the corpus itself tests successful completed-output behavior.

## Gaps Summary

No PNGC-04 goal gap was found. The only incomplete supporting check is the pre-existing scoped PNG quality lane, which has no successful result because it exceeds the available command window. It is recorded accurately above and is not represented as a passing check; it does not invalidate the independently passing four-target corpus or full portable PNG evidence.

---

_Verified: 2026-07-21T19:52:05Z_
_Verifier: the agent (gsd-verifier)_
