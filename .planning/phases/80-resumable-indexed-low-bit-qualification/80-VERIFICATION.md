---
phase: 80-resumable-indexed-low-bit-qualification
verified: 2026-07-23T22:08:23Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 80: Resumable Indexed Low-Bit Qualification Verification Report

**Phase Goal:** Library users can emit the same low-bit Indexed PNG through caller-owned leases with eager-identical bytes, sticky terminals, and portable independent evidence.
**Verified:** 2026-07-23T22:08:23Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can select Indexed Type-3 depth One, Two, or Four and receive the same PNG bytes through caller-owned leases as eager encoding. | ✓ VERIFIED | `PngChunkEncoder::new_indexed` maps all three public selectors to their private profile and creates the existing active machine (`stream_encode.mbt:41-59`). The passing all-depth hostile-drain test compares collected accepted lease bytes with `PngEncoder::encode_indexed`; a separate Indexed2 tracer passes under a zero lease then 1/3/2/5-byte leases. |
| 2 | For every selected depth, hostile zero-capacity, one-byte, and ragged leases commit only accepted bytes, preserve unused caller storage, and replay completed and failed terminals without later-lease mutation. | ✓ VERIFIED | `png_stream_indexed_low_bit_hostile_drain` asserts zero-capacity `NeedOutput`, accepted-only totals, `Z`-filled tails, eager parity, then zero-write sticky completion (`stream_encode_test.mbt:5080-5131`). The all-depth test invokes `[0,1]`, `[1]`, and `[0,1,3,2,5]`; released-lease failure replay checks equal errors and untouched first/later leases (`5135-5195`). The two named behavioral tests passed. |
| 3 | Rejected selected-depth construction has no observable budget charge; Indexed8 behavior and independent Type-3 wire/decode evidence remain part of the portable qualification. | ✓ VERIFIED | The selected-depth admission test covers output, pixel, and work rejections for One/Two/Four with before/after resource snapshots (`5198-5232`). `new_indexed8` remains the fixed-Eight wrapper (`stream_encode.mbt:23-35`, `990-998`). Existing independent literal low-bit wire/decode tests and Indexed8 compatibility tests passed; the fresh ordinary four-target package run passed 286/286 for wasm, wasm-gc, js, and native. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/stream_encode.mbt` | `PngChunkEncoder::new_indexed` selected-depth caller-buffered factory over the shared profile-aware machine | ✓ VERIFIED | Exists and is substantive. It maps only One/Two/Four, calls `PngEncodeMachine::new_with_indexed_profile`, returns that error unchanged, and initializes the existing `Active(machine)` state with zero total. Manual wiring check confirms no second machine or transport. |
| `modules/mb-image/png/stream_encode_test.mbt` | All-depth hostile lease, sticky terminal, atomic admission, and eager-parity qualification | ✓ VERIFIED | Exists and is substantive. The selected-depth helpers and three focused tests are live, invoked by the package command, and passed under native plus all targets. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `PngChunkEncoder::new_indexed` | `PngEncodeMachine::new_with_indexed_profile` | selector mapping and existing `Active` initialization | ✓ WIRED | Direct call at `stream_encode.mbt:53-54`; the same constructor invokes shared selected-depth preflight then stores the supplied indexed source in the one `PngEncodeMachine` (`953-988`). |
| `png_stream_indexed_low_bit_hostile_drain` | `PngEncoder::encode_indexed` | public eager oracle compares collected lease bytes for each selected depth | ✓ WIRED | Helper calls `png_stream_indexed_low_bit_eager`, which directly calls `PngEncoder::encode_indexed`; all three depths and schedules invoke the helper (`stream_encode_test.mbt:4917-4934`, `5080-5131`, `5167-5183`). |

`verify.key-links` could not parse the plan's symbolic `from` values as file paths, so it reported both links as unresolved; direct source inspection above verifies both actual calls.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `PngChunkEncoder::new_indexed` / `PngEncodeMachine` | indexed source bytes and selected wire profile | Caller-supplied `PngIndexedImage` and `PngIndexedBitDepth` | Yes — the factory passes both into shared selected-depth construction; the machine stores `indexed_source: Some(source)` and uses the established acknowledged byte/scanline path. The passing parity tests use non-empty opaque and transparent palettes at all depths. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| All-depth zero/one/ragged leases, tail ownership, eager parity, sticky completion | `moon -C modules/mb-image test png/stream_encode_test.mbt --target native --frozen --filter 'PNG selected Indexed chunk hostile leases retain eager parity and sticky completion'` | 1 passed, 0 failed | ✓ PASS |
| All-depth released lease failure replay | `moon -C modules/mb-image test png/stream_encode_test.mbt --target native --frozen --filter 'PNG selected Indexed chunk replays released lease failures'` | 1 passed, 0 failed | ✓ PASS |
| All-depth atomic construction admission | `moon -C modules/mb-image test png/stream_encode_test.mbt --target native --frozen --filter 'PNG selected Indexed chunk admission is atomic'` | 1 passed, 0 failed | ✓ PASS |
| Independent low-bit wire/decode evidence | `moon -C modules/mb-image test png/encode_test.mbt --target native --frozen --filter 'PNG Indexed1 and Indexed4 eager rows are independently MSB-first and zero-tailed'`; `... --filter 'PNG Indexed2 eager packs an odd transparent row and decodes palette RGBA8'` | 1 passed, 0 failed for each | ✓ PASS |
| Frozen Indexed8 hostile lifecycle | `moon -C modules/mb-image test png/stream_encode_test.mbt --target native --frozen --filter 'PNG Indexed8 chunk hostile leases retain eager parity and sticky completion'` | 1 passed, 0 failed | ✓ PASS |
| Ordinary portable PNG package gate | `moon -C modules/mb-image test png --target all --frozen` | 286 passed, 0 failed for each of wasm, wasm-gc, js, and native | ✓ PASS |

### Probe Execution

No phase-declared or conventional `scripts/**/tests/probe-*.sh` probe exists. This PNG package phase is qualified by its ordinary frozen MoonBit test gate.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| INDEXLOW-04 | `80-01-PLAN.md` | Caller-buffered low-bit output reuses the bounded eager machine, retains byte identity under hostile capacity, preserves lease ownership, and keeps terminals sticky. | ✓ SATISFIED | Thin adapter is directly wired to the existing profile-aware machine; all-depth hostile and released-lease behavioral tests pass. |
| INDEXLOW-05 | `80-01-PLAN.md` | Independent low-bit wire/decode vectors, hostile lifecycle, Indexed8/legacy compatibility, and four-target ordinary package coverage. | ✓ SATISFIED | Independent Type-3/1, /2, /4 wire/decode tests and Indexed8 lifecycle test pass; fresh package run passes wasm, wasm-gc, js, and native. |

No Phase 80 requirement is orphaned: the plan declares exactly `INDEXLOW-04` and `INDEXLOW-05`, which are the only requirements mapped to Phase 80.

### Anti-Patterns Found

None. The phase commits modify only `stream_encode.mbt` and `stream_encode_test.mbt`; the production diff is one thin factory. No second traversal, framing, CRC, preflight, source model, strategy, Adam7, staging, wrapper, copied tree, release automation, debt marker, or placeholder was found. `git diff --check` from the phase base through `5fe480a` is clean.

### Disconfirmation Pass

- **Potential partial requirement:** parity alone could hide a shared eager/chunk packing defect. This is countered by the retained literal independent Type-3/1, /2, and /4 wire tests and public RGB8/RGBA8 decoding checks, both included in the passing package gate.
- **Potential misleading test:** a successful normal-buffer drain would not prove acknowledgement ordering. The passing selected-depth test deliberately exercises zero-capacity, one-byte, and ragged schedules, checks accepted-only totals and every unused sentinel tail, and repeats both success and released-lease terminals.
- **Potential uncovered error path:** construction could charge a budget before exposing its failure. The passing all-depth admission test exercises output-limit, pixel-budget, and work-budget rejections and compares complete resource snapshots before and after each call.

### Gaps Summary

No blocking gaps found. The phase meets the caller-owned selected-depth lifecycle contract through the existing bounded machine, retains independent and Indexed8 evidence, and has fresh successful four-target qualification.

---

_Verified: 2026-07-23T22:08:23Z_
_Verifier: the agent (gsd-verifier)_
