---
phase: 28-portable-png-streaming-evidence
verified: 2026-07-21T12:06:18Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 28: Portable PNG Streaming Evidence Verification Report

**Phase Goal:** Library users and maintainers can independently verify the public resumable PNG decode contract through hostile schedules and one portable processing workflow.
**Verified:** 2026-07-21T12:06:18Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Maintainers can run generated accepted and rejected PNG vectors through one-byte and adversarial split schedules at framing, IDAT payload/CRC, DEFLATE bit/tree/match, filter, IEND, and EOF boundaries, proving progress, terminal behavior, and eager-equivalent results. | ✓ VERIFIED | `stream_decode_test.mbt:284-430` instantiates only public `PngChunkDecoder`, sends a fresh `OwnedBytes` allocation per push, begins each route with empty input, executes `[1]` and `[8,4,1,13,2,5,3,21]` over every `_generated_png_decode_cases()` record, compares first source terminal prefixes, sticky replay, finish result/error, error shape, diagnostics, and every remaining budget field to a fresh eager oracle. Direct `Generate-PngDecodeVectors.ps1 -Check` reported 3,850 cases; `moon -C modules/mb-image test png --target all --frozen` passed 84/84 on js, wasm, wasm-gc, and native. |
| 2 | A library user can run one public portable workflow that feeds PNG chunks to `PngChunkDecoder`, applies an existing image operation, uses the existing eager PNG encoder, and prints deterministic evidence. | ✓ VERIFIED | `examples/png-portable/main/main.mbt:48-101` feeds the 75-byte source through the specified sixteen pushes, requires `NeedInput` and exact consumption for every call, calls `finish()` once, then applies `resize_bilinear` and `PngEncoder`; it checks the 3-by-1 pixels, 78 exact bytes, and digest `626208771`. Independent direct runs on js, wasm, wasm-gc, and native each produced exactly one required frozen evidence line. |
| 3 | The hostile-schedule suite and public workflow produce the same asserted outcomes on js, wasm, wasm-gc, and native using only public portable MoonBit contracts, with no FFI, public streaming encoder, registry, or release-automation work. | ✓ VERIFIED | `Invoke-PngQualityLane` runs fixture freshness, exact workflow output per target, README checks, and package tests; `Assert-PngLaneIsolation` replaces broad/release routes with throws and asserts the ordered scoped trace. Independent `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` passed, including `PNG lane isolation proof passed`. A phase-surface search found no `PngStreamEncoder`, `PngChunkEncoder`, FFI declaration, or foreign import. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/stream_decode_test.mbt` | Black-box all-record hostile public schedule harnesses | ✓ VERIFIED | 630 substantive lines. The runner is used by the corpus-wide test and reaches `PngChunkDecoder::new`, `push`, and `finish`; direct four-target package run passes. |
| `examples/png-portable/main/main.mbt` | Single portable chunk-decode → bilinear-resize → eager-encode workflow | ✓ VERIFIED | 101 substantive lines. Its fixed public schedule, exact admission assertions, finish-only transfer, resize, eager encoding, byte comparison, digest, and evidence output are all on the runtime path. |
| `modules/mb-image/README.mbt.md` | Runnable public ownership documentation | ✓ VERIFIED | 634 substantive lines. The `mbt check` block at lines 466-500 constructs the public decoder, proves empty input consumes zero, proves full source remains `NeedInput`, and takes the image only from `finish`; four-target README check passed. |
| `scripts/quality/Invoke-MoonQuality.ps1` | Exact four-target workflow evidence and isolated lane trace | ✓ VERIFIED | 848 substantive lines. Lines 767-811 exact-match the new evidence line once per target and assert the full Png-only stage order; direct lane run passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `stream_decode_test.mbt` | `png.mbt` / public decoder implementation | Fresh caller-owned slices to `PngChunkDecoder::push`, result only from `finish` | ✓ WIRED | `gsd-tools query verify.key-links` reported the declared public API pattern present; source audit confirms the runner reaches all three calls. |
| `examples/png-portable/main/main.mbt` | public chunk decoder → resize → eager encoder | Fixed schedule before `resize_bilinear` and `PngEncoder` | ✓ WIRED | Source order and direct four-target executable output prove this is the executed path, not an unused example. |
| `Invoke-MoonQuality.ps1` | `png-portable` executable | One exact evidence line per supported target | ✓ WIRED | The lane invokes each target, extracts `example=png-portable`, rejects count/value mismatches, and passed independently. |

### Data-Flow Trace (Level 4)

Not applicable: these are codec tests, a CLI-style executable, documentation checks, and a quality driver rather than UI components with dynamic rendering. The relevant runtime flow is directly exercised by the package, executable, and lane commands above.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Generated public hostile schedules on all required targets | `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check; moon -C modules/mb-image test png --target all --frozen` | 3,850 generated cases; 84/84 passed on js, wasm, wasm-gc, and native | ✓ PASS |
| Public chunk-decode → resize → eager-encode workflow | `moon -C examples/png-portable run main --target {js,wasm,wasm-gc,native} --frozen` | Each target printed exactly one frozen 75-read/78-written/digest evidence line | ✓ PASS |
| Runnable chunk ownership documentation | `moon -C modules/mb-image check README.mbt.md --target all --frozen` | Completed successfully for all four targets | ✓ PASS |
| Scoped public evidence and isolation | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | PNG quality lane and lane isolation proof both passed | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| PNGS-04 | `28-01-PLAN.md` | Maintainers run adversarial split schedules and one public PNG chunk-decode workflow unchanged on js, wasm, wasm-gc, and native. | ✓ SATISFIED | Corpus scheduler, direct four-target executable, README check, and isolated PNG quality lane all ran and passed independently. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholder, or empty-implementation marker in Phase 28's four modified artifacts. | — | No blocker. |

## Disconfirmation Checks

- The generic artifact/link query is only a presence check, so it was not treated as behavioral proof; the direct four-target MoonBit runs and the actual quality-lane execution supplied that proof.
- The corpus runner does not depend on private parser records: each call constructs `PngChunkDecoder`, supplies a newly owned `ByteView` slice, and checks only public progress/outcome/result APIs.
- EOF-only rows finish without a source-terminal byte. Their all-record results are eager-compared by the new runner; public EOF replay is additionally exercised by the existing `stream_decode_wbtest.mbt` public-wrapper matrix, while `finish` sets the shared decoder state to `Failed` before later `push` can return.
- The phase quality diff only changes the portable workflow stage name and frozen evidence line. The executed isolation probe replaces broad foundation, QOI, Required, and release entry points with throws; no such route was reached.

## Gaps Summary

No blocking gaps found. All roadmap criteria, plan must-haves, artifacts, key links, required four-target behavior, and PNGS-04 evidence have direct passing evidence.

---

_Verified: 2026-07-21T12:06:18Z_
_Verifier: gsd-verifier_
