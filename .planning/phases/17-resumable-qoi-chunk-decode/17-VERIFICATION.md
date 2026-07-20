---
phase: 17-resumable-qoi-chunk-decode
verified: 2026-07-20T13:29:10Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 2/3
  gaps_closed:
    - "QSTR-02 invalid-marker and trailing-data finish paths now have focused behavioral coverage."
  gaps_remaining: []
  regressions: []
---

# Phase 17: Resumable QOI Chunk Decode Verification Report

**Phase Goal:** Library users can feed a stateful QOI decoder caller-owned byte chunks, then explicitly obtain one complete owned image or a typed terminal result without changing `@io.Reader` EOF behavior.
**Verified:** 2026-07-20T13:29:10Z
**Status:** passed
**Re-verification:** Yes — after behavioral-evidence closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Arbitrary caller-owned `ByteView` chunks, including all header/opcode/end-marker boundaries, report exact consumption and `NeedInput` before explicit completion. | ✓ VERIFIED | `push` reads only its local `source`, increments `accepted` only per accepted byte, and persists copied `Array[Byte]` token/header/marker state. One-byte and hostile-schedule tests passed on all four targets. |
| 2 | `finish` is required for exactly one result; strict incomplete, malformed, trailing, run-overrun, and terminal-reuse cases give typed deterministic outcomes. | ✓ VERIFIED | The focused public test now invokes incomplete, malformed, and trailing marker finish paths, asserts their typed errors and accepted counts, and proves zero-consumption terminal pushes; success, run-overrun, and input-limit paths also pass. |
| 3 | Stream output preserves eager descriptor, pixels, disposition, accounting, limits, budget, diagnostics, and private-output guarantees. | ✓ VERIFIED | The stream reuses the eager private QOI helpers, compares RGB/RGBA output with eager decoding, runs all generated vectors/schedules, preflights before `OwnedImage::new_operation`, and exposes the private image only through successful `finish`. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Decision Contract Coverage

| Decision | Status | Evidence |
| --- | --- | --- |
| D-01 — separate stream API; eager traits and `Reader` unchanged | ✓ VERIFIED | Phase commits modify only `qoi.mbt` among the eager/trait sources; `QoiStreamDecoder` is a separate public type and `ImageDecoder`/`Reader` retain their original methods. |
| D-02 — no retained caller view; exact per-push consumption | ✓ VERIFIED | `QoiStreamState` holds copied arrays/values only; mutation-after-push test passes; `push` returns `accepted`, including failed run and input-limit paths. |
| D-03 — `finish` is sole EOF and validates strict marker/trailing input | ✓ VERIFIED | The explicit `finish` test exercises incomplete, malformed, and trailing markers and asserts typed errors; malformed/trailing terminal pushes consume zero bytes. |
| D-04 — preflight before one private owned-image allocation | ✓ VERIFIED | `qoi_stream_preflight` checks header, limits, descriptor, then calls `OwnedImage::new_operation` once. White-box budget test confirms preflight rejection leaves all budgets unchanged and accepted preflight charges once. |
| D-05 — eager-equivalent limits, budget, diagnostics, descriptor, accounting | ✓ VERIFIED | Shared `qoi_error`, `qoi_limit`, descriptor, pixel/hash, disposition and accounting helpers are used; generated and eager-comparison tests pass. Both eager and stream retain diagnostics without writing to it. |
| D-06 — sticky typed terminal result/error and no reprocessing | ✓ VERIFIED | `Failed`/`Finished` short-circuit `push` with zero consumption and `finish` with `qoi-stream-terminal`; successful and failed terminal scenarios pass in the focused suite. |
| D-07 — copied parser state and fresh mutable view per pump | ✓ VERIFIED | Pending parser values are copied into private arrays; `emit` obtains `image.with_mut_view` only for its callback. The mutation and white-box pending-state tests pass. |
| D-08 — boundary, hostile, resource, and generated-vector evidence | ✓ VERIFIED | Generated RGB/RGBA/index/diff/luma/run vectors run under all hostile schedules and one-byte splitting; resource/preflight and parser-state white-box tests pass. Phase 19’s public example is explicitly deferred scope, not a gap. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/qoi/qoi.mbt` | Public stream contract beside eager codecs | ✓ VERIFIED | Exposes `QoiStreamDecoder`, `QoiStreamPushResult`, and `NeedInput`/typed `Failed` outcome without changing eager traits. |
| `modules/mb-image/qoi/stream_decode.mbt` | Stateful strict parser | ✓ VERIFIED | Substantive 373-line parser with private state, preflight, copied pending tokens, strict finish, and terminal gate. |
| `modules/mb-image/qoi/stream_decode_test.mbt` | Public contract coverage | ✓ VERIFIED | Exercises one-byte progress, finish/terminal behavior, eager parity, copied input, run failure, and input-limit consumption. |
| `modules/mb-image/qoi/stream_decode_wbtest.mbt` | Generated/resource/state coverage | ✓ VERIFIED | Exercises every generated case/schedule, one-byte schedules, budget preflight, and private pending state. |
| `policy/foundation.json` | Exact QOI inventory/interface policy | ✓ VERIFIED | Lists the stream source/tests, the three stream public types, and all four portable targets. |
| `scripts/quality/Assert-Policy.ps1` | Broad and scoped policy enforcement | ✓ VERIFIED | Both broad and scoped production-source sequences include `stream_decode.mbt`; negative fixtures reject reordered/missing/extra stream entries. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `stream_decode.mbt` | `decode.mbt` | Shared QOI semantic helpers | ✓ WIRED | It compiles against private `QoiHeader`, errors, limits, descriptor, pixel/hash, and disposition helpers; four-target QOI tests pass. |
| `stream_decode.mbt` | `owned_image.mbt` | One private allocation and fresh mutable callback | ✓ WIRED | `qoi_stream_preflight` calls `OwnedImage::new_operation`; `emit` uses `with_mut_view` only inside each callback. |
| `qoi.mbt` | `codec/contracts.mbt` | Existing limits/budget/diagnostics and `DecodeResult` | ✓ WIRED | Constructor accepts the existing policy types and `finish` returns the existing `DecodeResult`; `ImageDecoder` was not extended. |
| `foundation.json` | `Assert-Policy.ps1` | Exact QOI inventory | ✓ WIRED | Scoped assertion reads the policy, regenerates interface for all targets, and negative fixtures exercise both scoped and controlled broad source order. |
| `qoi.mbt` | stream tests | Public push result contract | ✓ WIRED | Public tests compile and execute the public decoder/result/outcome API on all four targets. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `stream_decode.mbt` | private parser state and `OwnedImage` | Caller `ByteView` bytes accepted by `push`, copied into state, emitted into owned storage | Yes — decoded bytes are compared with eager and generated-vector expectations | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Generated interface on every portable target | `moon -C modules/mb-image info --target all --frozen` | Completed four target passes | ✓ PASS |
| Resumable QOI decoding | `moon -C modules/mb-image test qoi --target all --frozen` | 24/24 passed on wasm, wasm-gc, js, native | ✓ PASS |
| Scoped QOI policy plus broad/scoped negative order checks | Dot-source `Assert-Policy.ps1`; run `Assert-QoiFoundationPolicy` and `Assert-QoiQualificationNegativeFixtures` | Passed; broad reordered stream order and all scoped negative cases were rejected | ✓ PASS |
| Existing QOI quality lane | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Qoi` | Exit 0 | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no Phase 17 probe script was declared or discovered.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| QSTR-01 | 17-01 | Arbitrary caller chunks produce deterministic input-needed progress | ✓ SATISFIED | Private copied state, exact `accepted` accounting, one-byte and hostile-schedule tests on every target. |
| QSTR-02 | 17-01 | Explicit strict finish and deterministic terminal failures | ✓ SATISFIED | Public terminal test covers incomplete, malformed, and trailing markers with typed errors, exact push consumption, and zero-consumption post-terminal behavior. |
| QSTR-03 | 17-01 | Eager-equivalent bounded output, accounting, and visibility | ✓ SATISFIED | Shared semantic helpers, eager parity/generated-vector tests, preflight budget test, and private image state. |

There are no orphaned Phase 17 requirements: the plan declares QSTR-01, QSTR-02, and QSTR-03, exactly matching the requirements mapping.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/quality/Assert-Policy.ps1` | 227 | `placeholder` appears in a rejection regex | ℹ️ Info | This is policy enforcement, not unfinished implementation. |

No phase-modified file contains an unresolved `TBD`, `FIXME`, or `XXX`; `git diff --check` passes.

### Gaps Summary

No implementation blockers or human-verification items remain. Commit `cd94ac1` closes the only prior behavioral-evidence gap without changing the implementation contract.

---

_Verified: 2026-07-20T13:29:10Z_
_Verifier: the agent (gsd-verifier)_
