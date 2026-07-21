---
phase: 27-public-png-chunk-decoder
verified: 2026-07-21T18:21:10+08:00
status: gaps_found
score: 0/4 must-haves verified
behavior_unverified: 4
overrides_applied: 0
gaps:
  - truth: "The public chunk decoder contract is covered for arbitrary ByteView partitions with exact consumption and no pre-finish image."
    status: partial
    reason: "The only public chunk tests cover an empty push, one complete one-pixel PNG supplied as a single view, and a malformed first signature byte. They do not exercise arbitrary partitions or the required PNG continuation boundaries."
    artifacts:
      - path: "modules/mb-image/png/stream_decode_test.mbt"
        issue: "No chunk schedule, post-push mutation/reuse, source-limit boundary, or per-boundary consumption test exists."
    missing:
      - "Black-box schedules at signature, length/type/payload/CRC, IDAT, DEFLATE, filter, IEND, and trailing boundaries with exact accepted-byte assertions."
      - "A caller-view mutation/reuse check proving no ByteView is retained."
  - truth: "finish() classifies every incomplete state and preserves the first typed terminal error with zero-consumption later pushes."
    status: partial
    reason: "The planned white-box artifact contains no PngChunkDecoder, chunk_incomplete_error, or frozen EOF-classifier tests. Only a malformed signature replay is tested publicly."
    artifacts:
      - path: "modules/mb-image/png/stream_decode_wbtest.mbt"
        issue: "No Phase 27 test was added; it does not test the public wrapper classifier or first-error precedence."
    missing:
      - "Focused tests for zlib/raster precedence, every partial IEND/IDAT CRC context, incomplete framing, trailing input, limit/allocation/budget errors, and sticky replay through both push and finish."
  - truth: "finish() transfers one eager-equivalent DecodeResult with matching pixels, metadata, disposition, accounting, diagnostics, budget state, and terminal errors."
    status: partial
    reason: "There is no paired eager/chunk runner or comparison of visible success/error fields, diagnostics, or Budget::remaining values."
    artifacts:
      - path: "modules/mb-image/png/stream_decode_test.mbt"
        issue: "The one success assertion checks a single byte and bytes_read only; it does not establish eager equivalence across the supported profile."
    missing:
      - "Paired eager/chunk comparisons for accepted profile variants and structural, DEFLATE, raster, trailing, limit, allocation, and budget failures."
behavior_unverified_items:
  - truth: "Arbitrary caller-owned ByteView partitions report exact per-push consumption and NeedInput."
    test: "Feed a valid PNG at every framing, IDAT, DEFLATE, filter, and IEND boundary, including empty views."
    expected: "Each active push reports exactly its admitted bytes and NeedInput; no result is exposed before finish."
    why_human: "The adapter loops byte-by-byte, but the required partition behavior has no behavioral test."
  - truth: "finish() is the sole EOF/result transfer and yields an eager-equivalent complete result."
    test: "Compare eager and chunk paths for representative RGB/RGBA, palette/tRNS, 16-bit, and Adam7 accepted inputs."
    expected: "Pixels, descriptor/metadata/disposition, bytes_read, diagnostics, and all remaining budget fields agree; a second finish cannot replay the image."
    why_human: "A single 1x1 stored PNG success is insufficient to establish the required supported-profile equivalence."
  - truth: "All malformed, incomplete, trailing, limit, budget, raster, and DEFLATE paths are sticky typed terminal errors."
    test: "Trigger each frozen classifier row and each representative parser/resource failure, then call push and finish again."
    expected: "The first CoreError remains unchanged and every later push consumes zero bytes."
    why_human: "Only malformed-signature replay is executed; no test exercises the public EOF classifier or the other terminal families."
  - truth: "The public interface is portable and retains no caller ByteView."
    test: "Run the complete PNG quality lane after adding mutation/reuse and schedule tests on all four targets."
    expected: "All public chunk cases pass unchanged on js, wasm, wasm-gc, and native."
    why_human: "The two narrow tests compile and pass on all targets, but the full qualification lane and the ownership behavior lack independent behavioral coverage."
---

# Phase 27: Public PNG Chunk Decoder Verification Report

**Phase Goal:** Library users can submit caller-owned PNG byte chunks to `PngChunkDecoder` and explicitly complete one eager-equivalent decode without changing existing `Reader` EOF semantics.
**Verified:** 2026-07-21T18:21:10+08:00
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Arbitrary caller-owned chunks have exact consumption and non-terminal progress. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `PngChunkDecoder::push` iterates transient bytes, but the public tests exercise only empty input and a whole-buffer 1×1 PNG. |
| 2 | `finish()` alone transfers exactly one eager-equivalent owned result after strict terminal validation. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Source calls `PngDecodeMachine::finish` only at `NeedEof` and moves `PngMachineOutcome` once; no eager/chunk parity test covers the required profile or observables. |
| 3 | Every required failure family is typed and sticky with zero-consumption later pushes. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Wrapper stores `Failed(CoreError)`, but only a bad-signature replay is executed. The frozen incomplete-state classifier has no tests. |
| 4 | The documented PNG chunk API is public, does not retain caller views, and is portable-qualified. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Exact MBTI policy and two narrow tests pass on four targets. Static state inspection finds no wrapper `ByteView` field, but no mutation/reuse test or independent complete quality-lane run proves the full contract. |

**Score:** 0/4 truths verified (4 present, behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Exact public declarations and signatures | ✓ VERIFIED | Generated MBTI exposes `PngChunkDecoder`, `PngChunkPushOutcome`, and `PngChunkPushResult` with the planned methods. |
| `modules/mb-image/png/stream_decode.mbt` | Thin adapter, classifier, one-time transfer, sticky state | ✓ VERIFIED (static) | `push` dispatches one source byte; `finish` delegates only from `NeedEof`; `chunk_incomplete_error` is non-mutating. |
| `modules/mb-image/png/stream_decode_test.mbt` | Public schedule, ownership, parity, resource, and terminal evidence | ✗ STUB FOR PHASE 27 | Contains only two new chunk tests; required schedule/parity/resource coverage is absent. |
| `modules/mb-image/png/stream_decode_wbtest.mbt` | Classifier, no-retained-view, private-outcome, terminal-precedence evidence | ✗ STUB FOR PHASE 27 | No `PngChunkDecoder` or `chunk_incomplete_error` reference; no Phase 27 change in the implementation commits. |
| `policy/foundation.json` | Exact generated semantic-interface contract | ✓ VERIFIED | `Assert-PngFoundationPolicy` and negative fixtures passed against regenerated MBTI. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `stream_decode.mbt` | `PngDecodeMachine` | `push` calls `machine.accept`; `finish` calls machine finish then transfers outcome | ✓ WIRED | Static source inspection plus GSD link query. |
| `png.mbt` | `stream_decode.mbt` | Public constructor and methods use private wrapper state | ✓ WIRED | Exact generated interface checked. |
| `foundation.json` | `pkg.generated.mbti` | `Assert-PngFoundationPolicy` regenerates and exact-compares semantic interface | ✓ WIRED | Direct verifier command passed. |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Public chunk API on native | `moon -C modules/mb-image test png --target native --frozen -f '*PNG chunk decoder*'` | 2/2 passed | ✓ PASS |
| Narrow public chunk tests on all portable targets | `moon -C modules/mb-image test png --target all --frozen -f '*PNG chunk decoder*'` | 2/2 passed on wasm, wasm-gc, js, native | ✓ PASS |
| Existing PNG suite on native | `moon -C modules/mb-image test png --target native --frozen` | 70/70 passed | ✓ PASS |
| PNG fixtures and exact policy | `Assert-PngFoundationPolicy`; `Assert-PngQualificationNegativeFixtures`; vector `-Check` | policy/negative fixtures passed; 3,850 vectors checked | ✓ PASS |
| Complete all-target PNG suite and `Invoke-MoonQuality -Lane Png` | Independent full-run evidence | The combined and all-target full invocations exceeded the verifier command window; the narrow all-target API test passed, but this is not a substitute. | ? NOT CONFIRMED |

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGS-01 | 27-01 | Arbitrary caller chunks, deterministic progress, no image before strict completion | ✗ BLOCKED | Implementation is wired, but the planned boundary schedules and ownership/mutation evidence are absent. |
| PNGS-02 | 27-01 | One explicit eager-equivalent result or sticky typed terminal error | ✗ BLOCKED | One simple success and signature failure do not cover eager parity, frozen EOF contexts, or resource/error families. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `modules/mb-image/png/stream_decode_wbtest.mbt` | whole file | Planned Phase 27 white-box artifact has no public-wrapper coverage | 🛑 Blocker | Classifier/precedence behavior cannot be claimed as verified. |
| `modules/mb-image/png/stream_decode_test.mbt` | 127–219 | Only two narrow chunk tests | 🛑 Blocker | The universal chunk, parity, and resource contracts are untested. |

## Gaps Summary

The implementation and interface wiring are plausible, and no buffering or public-API policy violation was found. The phase nevertheless misses the test deliverables that make its externally observable streaming contract auditable. This is not deferred to Phase 28: that phase owns the larger hostile corpus and workflow, while Phase 27's own plan explicitly requires focused public/white-box tests for exact consumption, classifier precedence, ownership, sticky resource errors, and eager parity. Add those tests and re-run verification before proceeding.

---

_Verified: 2026-07-21T18:21:10+08:00_  
_Verifier: gsd-verifier_
