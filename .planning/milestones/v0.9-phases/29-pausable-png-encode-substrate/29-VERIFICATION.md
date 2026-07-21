---
phase: 29-pausable-png-encode-substrate
verified: 2026-07-21T13:53:38Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/5
  gaps_closed:
    - "A Writer failure returns the Writer's original typed CoreError unchanged, and the failed byte is not acknowledged."
  gaps_remaining: []
  regressions: []
---

# Phase 29: Pausable PNG Encode Substrate Verification Report

**Phase Goal:** Compatible RGB8 and straight-RGBA8 images can enter a private resumable MoonBit encoding state only after eager-equivalent capability, dimension, limit, and budget preflight succeeds.
**Verified:** 2026-07-21T13:53:38Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Compatible RGB8 and straight-RGBA8 sources reach the private machine only after capability, dimension, length, output/work-limit, disposition, and budget admission. | ✓ VERIFIED | `_png_encode_preflight` validates source and checked geometry/lengths, checks all limits, constructs disposition, then performs the sole `budget.charge`; `PngEncodeMachine::new` is the constructor consumer. Native PNG suite: 92/92 passed. |
| 2 | Rejected sources, limits, or budgets expose no output and do not charge work before construction succeeds. | ✓ VERIFIED | `PngEncoder::encode` constructs the machine before creating the one-byte owner or calling `Writer.write`; preflight tests assert zero Writer position for output/work/capability rejection, and native PNG suite passed. |
| 3 | The private emitter's acknowledged byte sequence is exactly the canonical eager PNG sequence across all supported targets. | ✓ VERIFIED | The shared-filter parity test drains `PngEncodeMachine` by present/acknowledge and compares RGB8 and straight-RGBA8 bytes and completed count to eager output. `Invoke-PngEncodeEvidence.ps1` independently passed its three-test filter on js, wasm, wasm-gc, and native. |
| 4 | The eager one-byte Writer adapter acknowledges only after a successful complete one-byte write. | ✓ VERIFIED | `encode.mbt` matches only `WriteOutcome::Progress(1UL)` before `machine.acknowledge(byte)`; zero and oversized progress return an adapter error. The malformed-progress native test passed; the pending-byte regression passed on all four isolated target runs. |
| 5 | A Writer failure returns the Writer's original typed `CoreError` unchanged while leaving the failed byte unacknowledged. | ✓ VERIFIED | The eager adapter calls `writer.write` directly and returns `WriteOutcome::Failed(error, _)` unchanged. The scripted failure test verifies Host/HostOperationFailed plus `png-scripted-write`, requested 91, completed 17, limit 23, context `scripted`, with exactly 43 accepted bytes and 44 one-byte calls; it passed in each target-isolated run. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/stream_encode.mbt` | Private resumable canonical state machine | ✓ VERIFIED | Substantive private state retains only `ImageView`, scalar/checksum fields, and `Byte? pending`; it has no destination lease or output-sized staging. |
| `modules/mb-image/png/encode.mbt` | Shared preflight and eager Writer adapter | ✓ VERIFIED | Sole eager route is `PngEncodeMachine::new` → one-byte owner → direct `Writer.write` → acknowledge only on `Progress(1)`. |
| `modules/mb-image/png/*encode*_test.mbt` | Parity, atomicity, Writer-error, and ownership evidence | ✓ VERIFIED | Focused malformed-progress test passed; complete native suite passed 92/92; the three selected behavioral tests passed per target. |
| `scripts/quality/Invoke-PngEncodeEvidence.ps1` | Isolated four-target runtime evidence runner | ✓ VERIFIED | Accepts exactly one supported target, provides a target-specific build directory, filters the three named tests, propagates failure, and was independently run successfully four times. |
| `policy/foundation.json` | Private-source inventory and unchanged public interface | ✓ VERIFIED | PNG source inventory includes `stream_encode.mbt`; semantic interface lists only the pre-existing public PNG types. `Assert-Policy.ps1` exited 0. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `encode.mbt` | `stream_encode.mbt` | `PngEncodeMachine::new` → `present` → one-byte direct `Writer.write` → `acknowledge` | ✓ WIRED | The machine is constructed before Writer access; no alternate eager full-PNG encoder remains. |
| `encode.mbt` | `modules/mb-core/io/traits.mbt` | Direct `WriteOutcome` handling | ✓ WIRED | The code no longer invokes normalizing `write_all`; failed outcomes return their embedded provider error. |
| `stream_encode.mbt` | PNG checksum helpers | `_png_crc_for_type`, `_png_crc_step`, `_png_adler_step` | ✓ WIRED | The machine derives canonical checksum bytes from established helpers. |
| Evidence runner | Named source/test regressions | shared `*PNG encoder isolated four-target evidence*` filter | ✓ WIRED | Each target invocation ran exactly the three required Writer-error, pending-byte, and eager/private parity tests. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `stream_encode.mbt` | `byte_at` / `zlib_byte` output | Immutable `ImageView.get_byte` plus scalar framing, checksum, and cursor state | Yes — samples are read as scanline bytes and framed into canonical PNG output | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Direct malformed Writer progress cannot advance the machine | `moon -C modules/mb-image test png --target native --target-dir _build/png-encode-verifier-native --frozen -f '*PNG encoder rejects malformed direct one-byte Writer progress*'` | 1 passed, 0 failed | ✓ PASS |
| Full native PNG regression suite | `moon -C modules/mb-image test png --target native --target-dir _build/png-encode-verifier-native-full --frozen` | 92 passed, 0 failed | ✓ PASS |
| Isolated native evidence | `pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target native` | 3 passed, 0 failed | ✓ PASS |
| Isolated JavaScript evidence | `pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target js` | 3 passed, 0 failed | ✓ PASS |
| Isolated WebAssembly evidence | `pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target wasm` | 3 passed, 0 failed | ✓ PASS |
| Isolated Wasm-GC evidence | `pwsh -NoProfile -File scripts/quality/Invoke-PngEncodeEvidence.ps1 -Target wasm-gc` | 3 passed, 0 failed | ✓ PASS |
| PNG policy/public-interface gate | `pwsh -NoProfile -File scripts/quality/Assert-Policy.ps1` | exit 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGE-01 | 29-01, 29-02, 29-03 | Compatible RGB8/straight-RGBA8 sources admit only after eager-equivalent preflight; rejection precedes exposed encoded bytes. | ✓ SATISFIED | Shared preflight precedes any Writer operation; canonical, preflight, original-Writer-error, acknowledgement, policy, and four-target evidence all pass. |

### Anti-Patterns Found

No blocker or warning anti-patterns found in Phase 29 source, tests, or runner. The modified Phase 29 files contain no unreferenced `TBD`, `FIXME`, or `XXX` debt markers. The direct Writer adapter replaces, rather than wraps, the normalizing helper; no public PNG encoder type, retained caller lease, whole-output staging field, FFI, or unrelated public-surface change was found.

### Re-verification Notes

The previous blocker was real: `@io.write_all` reconstructed the failed `CoreError`. The current direct `Writer.write` match removes that normalizing layer. The provider-originated error path and failed-byte ownership are now exercised by the same isolated target-specific runtime test set that proves eager/private canonical parity.

---

_Verified: 2026-07-21T13:53:38Z_
_Verifier: the agent (gsd-verifier)_
