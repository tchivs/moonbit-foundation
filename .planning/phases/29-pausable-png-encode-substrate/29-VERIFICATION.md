---
phase: 29-pausable-png-encode-substrate
verified: 2026-07-21T13:33:00Z
status: gaps_found
score: 2/5 must-haves verified
behavior_unverified: 2
overrides_applied: 0
gaps:
  - truth: "A Writer failure returns the Writer's original typed CoreError unchanged, and the failed byte is not acknowledged."
    status: failed
    reason: "PngEncoder passes failures through @io.write_all, which reconstructs CoreError with operation=write_all, requested=1, completed=per-call progress, and drops the Writer context/limit. This is not the original Writer error field-for-field."
    artifacts:
      - path: "modules/mb-image/png/encode.mbt"
        issue: "Lines 216-218 return @io.write_all's normalized error directly."
      - path: "modules/mb-core/io/exact.mbt"
        issue: "Lines 18-31 and 160-167 rebuild a CoreError via propagate_stream_error."
      - path: "modules/mb-image/png/encode_test.mbt"
        issue: "The Writer-failure test asserts operation=write_all, requested=1, completed=0, context=None instead of the scripted Writer's png-scripted-write/91/17/23/scripted fields."
    missing:
      - "Use a complete-write adapter that preserves the Writer CoreError field-for-field, or explicitly revise the phase contract to permit write_all normalization and then test that revised contract."
behavior_unverified_items:
  - truth: "The private emitter's acknowledged byte sequence is exactly the canonical eager PNG sequence across all supported targets."
    test: "Run moon -C modules/mb-image test png --target all --frozen."
    expected: "All PNG tests pass on js, wasm, wasm-gc, and native, including eager/private byte-parity and stored-DEFLATE boundary tests."
    why_human: "The verifier's independent command exceeded its 120-second limit without producing a passing result; source and tests are present, but no current runtime pass was obtained."
  - truth: "The eager one-byte Writer adapter acknowledges only after a successful complete write."
    test: "Run the named PNG Writer-failure test on native."
    expected: "The Writer accepts only the canonical prefix and machine progress does not include the failed byte."
    why_human: "The current suite command timed out before any named behavior test completed; static control flow proves the intended ordering but not the runtime transition."
---

# Phase 29: Pausable PNG Encode Substrate Verification Report

**Phase Goal:** Compatible RGB8 and straight-RGBA8 images can enter a private resumable MoonBit encoding state only after eager-equivalent capability, dimension, limit, and budget preflight succeeds.
**Verified:** 2026-07-21T13:33:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Compatible RGB8 and straight-RGBA8 sources reach the private machine only after capability, dimension, length, output/work-limit, disposition, and budget admission. | ✓ VERIFIED | `encode.mbt` `_png_encode_preflight` runs source validation, checked geometry/length calculations, ordered limits, empty disposition, then one `budget.charge`; `PngEncodeMachine::new` is its sole consumer. |
| 2 | Rejected sources/limits/budgets expose no output and do not charge work before construction succeeds. | ✓ VERIFIED | `PngEncoder::encode` constructs the machine before allocating the one-byte owner or touching the Writer. Every fallible preflight operation precedes the sole charge; `encode_test.mbt` includes output/work/capability rejection with Writer position zero. |
| 3 | The private machine emits the exact canonical eager representation with present/acknowledge byte ownership. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `stream_encode.mbt` owns only `ImageView`, scalar cursors, checksums, and `Byte? pending`; `encode_wbtest.mbt` and `stream_encode_wbtest.mbt` exercise parity/checksum/block boundaries, but the verifier's current four-target run timed out. |
| 4 | The eager facade uses a one-byte complete-write adapter and advances the machine only after success. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `encode.mbt` creates `OwnedBytes::from_bytes([byte])`, calls `@io.write_all`, then calls `acknowledge`; the source ordering is correct, but current runtime evidence did not complete. |
| 5 | A Writer failure returns the Writer's original typed `CoreError` unchanged while leaving the failed byte unacknowledged. | ✗ FAILED | `@io.write_all` normalizes error fields through `propagate_stream_error`; the phase test deliberately expects the normalized `write_all` error, contradicting the contract. |

**Score:** 2/5 truths verified (2 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/stream_encode.mbt` | Private resumable canonical state machine | ✓ VERIFIED | 205 substantive lines; private type; scalar checksum/cursor state plus a one-byte pending value; no `MutByteLease`, `ByteView`, `Bytes`, or `Array[Byte]` field. |
| `modules/mb-image/png/encode.mbt` | Shared preflight and eager adapter | ⚠️ PARTIAL | Preflight and adapter wiring are substantive, but Writer-error propagation violates the stated original-error contract. |
| `modules/mb-image/png/*encode*_test.mbt` | Parity, atomicity, ownership coverage | ⚠️ PRESENT | Tests exist and contain non-stub assertions; no independent successful test execution was obtained because the all-target command timed out. |
| `policy/foundation.json` | Source inventory and unchanged interface | ✓ VERIFIED | Lists `stream_encode.mbt`, exact four targets, and no public PNG stream-encoder declaration. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `encode.mbt` | `stream_encode.mbt` | `PngEncodeMachine::new` → `present` → one-byte `write_all` → `acknowledge` | ✓ WIRED | Eager facade has one construction/drain path and no remaining full PNG assembler. |
| `stream_encode.mbt` | PNG checksum helpers | `_png_crc_for_type`, `_png_crc_step`, `_png_adler_step` | ✓ WIRED | Existing checksum helpers are reused; no alternate implementation appears. |
| `policy/foundation.json` | `pkg.generated.mbti` | exact semantic-interface inventory | ✓ WIRED | Policy and generated interface expose only existing `PngEncoder`/decode public surface. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `stream_encode.mbt` | PNG bytes from `byte_at`/`zlib_byte` | immutable `ImageView.get_byte` plus scalar framing/checksum state | Yes; source samples are read per emitted scanline byte | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Four-target PNG test suite | `moon -C modules/mb-image test png --target all --frozen` | Timed out after 124.1 seconds with no pass output | ? SKIP |
| Original Writer-error preservation | Static trace: `encode.mbt` → `@io.write_all`; `io/exact.mbt` `propagate_stream_error` | Error is rebuilt as `write_all`, dropping original operation/context/limit and replacing counts | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGE-01 | 29-01, 29-02 | Compatible source admission/rejection before encoded bytes are exposed | ⚠️ PARTIAL | Admission and no-output ordering are implemented; the plan's required unchanged Writer-error behavior is not. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `modules/mb-image/png/encode.mbt` | 216 | Error normalizer introduced by `@io.write_all` | 🛑 Blocker | Violates the explicit original-Writer-`CoreError` requirement. |

No `TBD`, `FIXME`, `XXX`, TODO, placeholder, or empty-implementation markers were found in the phase source/test files.

### Gaps Summary

The private source, ordered preflight, no-output-before-construction flow, policy registration, target declaration, and no-public-API scope are present and wired. The phase nevertheless misses a stated PNGE-01 adapter invariant: Writer failures are transformed by `@io.write_all`, while the contract requires returning the Writer's typed `CoreError` unchanged. The existing test masks this by asserting the transformed fields.

The independent four-target suite did not finish within 120 seconds, so it cannot be used as verification evidence for canonical parity or acknowledge-after-success behavior in this report.

---

_Verified: 2026-07-21T13:33:00Z_
_Verifier: the agent (gsd-verifier)_
