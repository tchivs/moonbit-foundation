---
phase: 43-portable-adam7-public-evidence
verified: 2026-07-22T09:53:01Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 43: Portable Adam7 Public Evidence Verification Report

**Phase Goal:** Users have independent public proof that Adam7 encoding faithfully round-trips RGB8 and straight-RGBA8 images across every supported portable target.
**Verified:** 2026-07-22T09:53:01Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Generated RGB8 and straight-RGBA8 sources that exercise all seven Adam7 passes round-trip through the public eager PNG API with exact dimensions, channel count, and pixels. | ✓ VERIFIED | `encode_test.mbt:126-144` creates a deterministic 5×5 RGB8/RGBA8 source with a distinct `(x,y,channel)` value. The focused selector (`611-678`) constructs the public `PngEncoder::new_with_all_strategies`, asserts IHDR byte 28 is `1`, decodes through public `PngDecoder::new`, and compares descriptor fields plus every component (`191-220`) for Stored, FixedOrStored, and DynamicOrFixedOrStored. The selector passed when independently run on native and each portable target. |
| 2 | For every supported compression strategy, public caller-buffered Adam7 output drained with zero, one-byte, and ragged capacities is byte-identical to eager output and decodes to the original pixels. | ✓ VERIFIED | `stream_encode_test.mbt:763-800` uses public eager and `PngChunkEncoder::new_with_all_strategies` routes. It proves a zero-capacity pull is a no-op, drains one-byte and `[0,1,3,2,5]` schedules, compares every completed byte to eager output, checks method `1`, then publicly decodes and compares dimensions/channels/every pixel (`174-205`). The selector loops both profiles and all three strategies (`805-866`) and passed on native and all four runner targets. |
| 3 | Frozen legacy and explicit-None non-interlaced byte vectors remain unchanged while every Adam7 public evidence PNG declares IHDR interlace method 1. | ✓ VERIFIED | The eager selector retains literal RGB8/RGBA8 Stored vectors and Fixed/Dynamic vectors across legacy and explicit-None factories, asserting exact equality and IHDR method `0` (`encode_test.mbt:612-660`); its Adam7 cases assert method `1` (`662-676`). The chunk selector retains the equivalent hostile-schedule vectors and method-`0` assertions (`stream_encode_test.mbt:805-854`) before the generated Adam7 matrix. Both executed successfully. |
| 4 | The focused public Adam7 evidence selectors run independently on js, wasm, wasm-gc, and native, each with a validated GUID-owned temporary target directory that is removed on success or failure. | ✓ VERIFIED | `Invoke-PngAdam7Compatibility.ps1:5-48` iterates exactly `js`, `wasm`, `wasm-gc`, and `native`; executes each exact selector separately with `--frozen --target-dir`; validates a direct GUID-prefixed child of the OS temp root before creation/removal; and removes it in `finally`. The verifier ran the script: both selectors passed independently for all four targets and no owned directory remained. A nonzero-exit PowerShell `try/finally` spot-check confirmed that `finally` executes before `exit` terminates the process. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/encode_test.mbt` | Public eager Adam7 generated RGB8/RGBA8 decode-fidelity and frozen-None compatibility selector | ✓ VERIFIED | Exists (896 lines), substantive test code, and selected by the runner. It uses the exported `PngEncoder`/`PngDecoder` façade rather than cursor internals. |
| `modules/mb-image/png/stream_encode_test.mbt` | Public Adam7 hostile-capacity byte-identity, decode-fidelity, and frozen-None chunk compatibility selector | ✓ VERIFIED | Exists (1,801 lines), substantive caller-lease drain/decode assertions, and selected by the runner. Its accepted bytes flow to eager equality and public decode checks. |
| `scripts/quality/Invoke-PngAdam7Compatibility.ps1` | Independent four-target runner with owned temporary-directory cleanup | ✓ VERIFIED | Exists (50 lines), substantive target/selector process execution plus validated lifecycle cleanup, and was directly executed by this verifier. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `encode_test.mbt` | `png.mbt` public façade | `PngEncoder::new_with_all_strategies` → `ImageEncoder::encode` → `PngDecoder::new` → `ImageDecoder::decode` | ✓ WIRED | Public exported constructors exist in `png.mbt:4-8,95-181`; the focused selector invokes them and the named test passed. `verify.key-links` reported this pattern present. |
| `stream_encode_test.mbt` | `stream_encode.mbt` public façade | `PngChunkEncoder::new_with_all_strategies` → caller-owned leases → collected accepted bytes | ✓ WIRED | Public chunk constructor delegates to `PngEncodeMachine::new_with_all_strategies` (`stream_encode.mbt:93-109`); the test repeatedly calls its public `pull` method through caller-owned leases and compares the completed data. `verify.key-links` reported this pattern present. |
| `Invoke-PngAdam7Compatibility.ps1` | public focused tests | one exact MoonBit selector per target and isolated target directory | ✓ WIRED | Runner selector strings exactly match both `test` names, calls `moon -C modules/mb-image test png --target $target --target-dir $owned.Directory --frozen -f $selector`, and produced one passed result for each target. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `encode_test.mbt` | `bytes`, decoded `restored` image | Generated 5×5 source → public eager encoder → `MemoryWriter` bytes → public decoder | Each source component is explicitly written from its row-major coordinate; decoded dimensions, channel count, and every component are compared. | ✓ FLOWING |
| `stream_encode_test.mbt` | `one_byte` / `ragged` accepted-byte collections | Generated 5×5 source → public eager and chunk encoders → caller-owned leases → public decoder | Zero, one-byte, and ragged schedules feed actual lease capacities; complete output must equal eager output and then every decoded component must match. | ✓ FLOWING |
| quality runner | target-specific test process outcome | Explicit targets and exact public selectors | Every selector process exited successfully for each target; runner emits target success only after both succeed. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Native eager public fidelity and frozen-None compatibility | `moon -C modules/mb-image test png --target native --frozen -f "PNG Adam7 public eager fidelity and frozen None compatibility" --no-parallelize` | `1/1` passed, exit 0 | ✓ PASS |
| Native chunk hostile-capacity identity/fidelity and frozen-None compatibility | `moon -C modules/mb-image test png --target native --frozen -f "PNG Adam7 public chunk fidelity, hostile identity, and frozen None compatibility" --no-parallelize` | `1/1` passed, exit 0 | ✓ PASS |
| Independent four-target execution and cleanup | `pwsh -NoProfile -File scripts/quality/Invoke-PngAdam7Compatibility.ps1` | Both selectors: `1/1` passed on js, wasm, wasm-gc, and native; exit 0 | ✓ PASS |
| Owned temporary directory cleanup | Post-run search for `mnf-png-adam7-compatibility-*` under the OS temp root | No directory remained | ✓ PASS |
| Failure-path cleanup control-flow | `pwsh -NoProfile -Command "try { exit 42 } finally { Write-Output 'FINALLY_EXECUTED_ON_EXIT' }"` | Printed `FINALLY_EXECUTED_ON_EXIT`, exit 42 | ✓ PASS |

### Probe Execution

No phase probe was declared or found. The dedicated quality runner is the declared executable target-evidence mechanism and was run above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGI-04 | 43-01 | Generated RGB8/RGBA8 Adam7 public decode fidelity; eager/chunk identity under hostile capacities; frozen non-interlaced output; independently executable js/wasm/wasm-gc/native evidence | ✓ SATISFIED | Both focused public tests assert the full behavioral contract; the verifier independently ran native selectors and the four-target runner successfully. |

No Phase 43 requirement is orphaned. There are no later milestone phases against which to defer any item.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, empty-implementation, or hardcoded-empty-output pattern in the three Phase 43 artifacts | ℹ️ Info | No phase-local stub or unauditable debt marker found. |

The focused test/runner commands emit pre-existing compiler warnings from unrelated production files, but all commands exit 0. They are not Phase 43 test or runner stubs and do not contradict the required evidence.

### Gaps Summary

None. The code, actual public-test behavior, target isolation, and cleanup evidence establish PNGI-04. No human verification is required.

---

_Verified: 2026-07-22T09:53:01Z_
_Verifier: gsd-verifier_
