---
phase: 19-portable-streaming-qoi-evidence
verified: 2026-07-20T14:18:35Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 19: Portable Streaming QOI Evidence Verification Report

**Phase Goal:** Library users and maintainers can independently prove the new streaming contracts through a small public processing workflow and adversarial portable conformance evidence.
**Verified:** 2026-07-20T14:18:35Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Maintainers can run every generated QOI decode and encode vector through named hostile streaming schedules on js, wasm, wasm-gc, and native, with exact decoded pixels, canonical bytes, per-call progress, cumulative counters, finish failures, and sticky terminal behavior asserted. | ✓ VERIFIED | `cases.json` defines zero/one-byte, header/token/marker, and PRNG schedules; generated helpers feed both white-box suites. The harnesses assert per-call and total progress, exact pixels/bytes, and terminal calls; the public contract tests cover strict incomplete/malformed/trailing finish errors. Fresh `moon -C modules/mb-image test qoi --target all --frozen` passed 30/30 tests on each of wasm, wasm-gc, js, and native. |
| 2 | A user can run the existing qoi-portable executable unchanged as the sole public example; it feeds fixed QOI chunks to QoiStreamDecoder, flips the decoded image horizontally, drains QoiStreamEncoder through fixed caller-owned output leases, and prints one deterministic evidence line. | ✓ VERIFIED | `examples/qoi-portable/main/main.mbt` directly uses `QoiStreamDecoder`, `flip_horizontal`, and `QoiStreamEncoder`, checks its exact 27-byte/24-byte evidence, and prints the frozen status line. Fresh isolated public-example verification passed on all four targets. |
| 3 | The QOI quality lane remains restricted to the QOI package policy, QOI negative fixtures, exact package allowlist, and the QOI public example; it does not enter qualification, registry, release, publication, credential, PNG/DEFLATE, or FFI routes. | ✓ VERIFIED | `Assert-QoiLaneIsolation` shadows all broader-route functions with throwing traps, asserts its exact four-stage trace, then directly invokes the public-example isolation probe. `Invoke-MoonQuality.ps1 -Lane Qoi` completed successfully; the direct probe emitted only `Assert-ExampleSource`, `Assert-NamedDependencies`, `Assert-PublicImports`, and `Invoke-MoonExampleVerification`. The example has only public portable imports and no prohibited capability tokens. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `fixtures/qoi/cases.json` | Named hostile input/output schedules | ✓ VERIFIED | Four named schedules in each direction, including zero-capacity and one-byte turns. |
| `fixtures/manifest.json` | QSTR-06 fixture provenance | ✓ VERIFIED | QOI record explicitly names QSTR-06 hostile-streaming evidence. |
| `modules/mb-image/qoi/generated_vectors.mbt` | Generated schedules | ✓ VERIFIED | Contains both generated schedule helper functions; current generator check passed. |
| `modules/mb-image/qoi/stream_decode_wbtest.mbt` | Decode progress evidence | ✓ VERIFIED | Iterates every generated valid vector and input schedule; verifies accepted bytes, total bytes, pixels, and post-finish terminal result. |
| `modules/mb-image/qoi/stream_encode_wbtest.mbt` | Encode progress evidence | ✓ VERIFIED | Iterates every generated encode vector and output schedule; checks `written`, `total_written`, canonical bytes, and post-finish terminal result. |
| `examples/qoi-portable/main/main.mbt` | Public streaming workflow | ✓ VERIFIED | Substantive streaming decode → flip → caller-owned streaming encode implementation, executed by the public-example check. |
| `scripts/quality/Test-PublicExamples.ps1` | Four-target status-line contract | ✓ VERIFIED | Runs qoi-portable on js, wasm, wasm-gc, and native against the one exact expected line. |
| `scripts/quality/Invoke-MoonQuality.ps1` | Isolated QOI-lane entry point | ✓ VERIFIED | `Qoi` dispatches to `Assert-QoiLaneIsolation`, which proves both lane trace and direct isolation probe. |
| `modules/mb-image/README.mbt.md` | Public streaming documentation | ✓ VERIFIED | Documents the fixed schedules, explicit decoder finish, output leases, counters, and evidence digests. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `fixtures/qoi/cases.json` | `generated_vectors.mbt` | `Generate-QoiVectors.ps1` | ✓ WIRED | The generator reads `stream_schedules.input/output` and writes `_generated_qoi_input_schedules` / `_generated_qoi_output_schedules`; fresh `-Check` passed. |
| `generated_vectors.mbt` | Decode and encode white-box tests | Named schedule helpers | ✓ WIRED | The tests call `_generated_qoi_cases` plus `_generated_qoi_input_schedules`, and `_generated_qoi_encode_cases` plus `_generated_qoi_output_schedules`, respectively. |
| `qoi-portable/main.mbt` | Public-example verifier and QOI lane | Exact status line, four-target runner, isolation trace | ✓ WIRED | The verifier runs the executable on all four targets; the QOI lane calls it and separately calls the `-IsolationProbe` form. |

`verify.key-links` reported the three declared prose `pattern` strings as absent, but those strings are descriptions rather than source patterns. The direct source traces above verify each intended connection.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Generated stream tests | `schedule` and generated vector tuples | Repository fixture → checked generator output | Fixture-defined bytes and capacities, not hardcoded empty data | ✓ FLOWING |
| `qoi-portable/main.mbt` | `decoded`, `flipped`, and accumulated `output` | Fixed QOI bytes → `QoiStreamDecoder` → `flip_horizontal` → `QoiStreamEncoder` output leases | Exact canonical 24-byte output, digest, and SHA-256 are asserted before printing | ✓ FLOWING |
| QOI quality lane | Status-line output and lane trace | Direct four-target public-example invocation | Exact status line plus exact isolation trace are asserted | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Generated vector artifact is current | `pwsh -File scripts/fixtures/Generate-QoiVectors.ps1 -Check` | `QOI vector generation/check passed.` | ✓ PASS |
| Portable hostile stream behavior | `moon -C modules/mb-image test qoi --target all --frozen` | 30/30 passed on wasm, wasm-gc, js, and native | ✓ PASS |
| Public streaming example and isolation | `pwsh -File scripts/quality/Test-PublicExamples.ps1 -Example qoi -Mode workspace -Target all -IsolationProbe` | Exact four-stage workspace trace; `workspace_examples: pass` | ✓ PASS |
| QOI lane scope and direct isolation probe | `pwsh -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Qoi` | Exit code 0 | ✓ PASS |

### Probe Execution

No phase-declared or conventional `probe-*.sh` files apply to this phase. The declared generator, package test, public-example isolation, and QOI-lane commands above were run instead.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| QSTR-06 | `19-01-PLAN.md` | Generated-vector streaming decode/encode evidence across hostile schedules and four portable targets | ✓ SATISFIED | Generated schedule loops and fresh four-target 30-test suite result. |
| QSTR-07 | `19-01-PLAN.md` | One portable public streaming decode → operation → canonical encode example with deterministic evidence | ✓ SATISFIED | Existing qoi-portable was upgraded in place and passed the fresh all-target isolated verifier. |

No Phase 19 requirements are orphaned: the plan declares both roadmap-mapped IDs, QSTR-06 and QSTR-07.

### Anti-Patterns Found

No blocker or warning anti-patterns found. The committed Phase 19 implementation artifacts have no untracked `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, or placeholder markers; `git diff --check feb6efb..HEAD` is clean. Broader-route terms in the quality scripts are intentional throwing isolation traps and were executed successfully by the QOI-lane check.

### Disconfirmation Checks

- The zero-capacity turns are not inert: both test drivers advance the schedule turn after checking a zero-progress result; the one-byte schedules then exercise every byte boundary.
- The test suite does not merely compare a final success value: decode verifies each push's accepted count and cumulative bytes; encode verifies each pull's `written` and `total_written`, while public contract tests exercise strict finish failures and terminal follow-ups.
- The quality lane cannot silently call broader release paths in its tested configuration because its isolation wrapper replaces those functions with throwing traps before invoking the lane.

---

_Verified: 2026-07-20T14:18:35Z_
_Verifier: the agent (gsd-verifier)_
