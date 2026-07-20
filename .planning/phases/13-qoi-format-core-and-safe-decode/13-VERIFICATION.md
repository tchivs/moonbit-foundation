---
phase: 13-qoi-format-core-and-safe-decode
verified: 2026-07-20T10:48:19Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 13: QOI Format Core and Safe Decode Verification Report

**Phase Goal:** Library users can safely identify and decode complete QOI 1.0 RGB and RGBA images through the portable codec contracts.
**Verified:** 2026-07-20T10:48:19Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A library user can probe caller-owned QOI prefixes without consuming a reader and receives deterministic `NoMatch` or minimum-length `NeedMore` results for incomplete or non-QOI prefixes. | ✓ VERIFIED | `QoiDecoder` implements `ImageDecoder::probe` in `decode.mbt`; `_probe_qoi_prefix` classifies `<4` bytes as `NeedMore(4)`, `qoif` as `Match`, and other four-byte prefixes as `NoMatch`. The all-target test run exercised `QOI probe classifies only caller-owned prefixes`. |
| 2 | A library user can decode a valid complete QOI 1.0 RGB or RGBA image from a forward-only reader into an owned portable image with exact pixels, dimensions, channels, and straight-alpha semantics. | ✓ VERIFIED | `decode.mbt` implements all QOI opcode families, constructs `rgb8`/`rgba8` descriptors, and writes one `OwnedImage`. Public RGB/RGBA metadata assertions and the generated-vector test cover exact bytes, dimensions, formats, and transfer semantics; all passed on four targets. |
| 3 | A library user receives typed, deterministic failures for malformed headers/opcodes, truncated data, invalid end markers, trailing data, declared limits, and reader failures; a preflight rejection leaves output allocation and budget charges unchanged. | ✓ VERIFIED | Tests cover malformed header, truncation, run overrun, strict marker/trailing input, zero-progress and host reader failures, plus exact work-limit preflight with every budget field unchanged on rejection. `decode.mbt` checks header-derived limits before its only `OwnedImage::new_operation` call. |
| 4 | The QOI package and generated-vector evidence pass on js, wasm, wasm-gc, and native. | ✓ VERIFIED | `moon.pkg` declares `+js+wasm+wasm-gc+native`; `moon -C modules/mb-image test --target all --frozen` reported 227/227 passing on each target. The vector generator’s `-Check` mode also passed without mutation. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/qoi/qoi.mbt` | Public `QoiDecoder` and prefix probe | ✓ VERIFIED | 21 substantive lines; prefix-only helper and public decoder value; wired by the `ImageDecoder` implementation in `decode.mbt`. |
| `modules/mb-image/qoi/decode.mbt` | Bounded QOI header preflight and complete chunk decoder | ✓ VERIFIED | 588 substantive lines; checked header/resource preflight, all opcode branches, strict end validation, and one post-preflight allocation. |
| `fixtures/qoi/cases.json` | Reviewable spec-derived QOI cases and provenance | ✓ VERIFIED | Contains eight valid opcode/state cases, adversarial case identifiers, and reader schedules; SHA-256 is `79cd80b9bf81faf6b4a77ec6cc9213ef500aab96359314b519a17b7defe3dcb8`. |
| `fixtures/manifest.json` | QOI provenance record | ✓ VERIFIED | `qoi-1.0-conformance-vectors` record contains every required field and the exact source-byte SHA-256; generator check validated it. |
| `scripts/fixtures/Generate-QoiVectors.ps1` | Deterministic generator and stale-artifact check | ✓ VERIFIED | Reads the JSON source, formats/writes-or-checks the MoonBit table, recomputes SHA-256, and checks the ordered manifest without network access. |
| `modules/mb-image/qoi/generated_vectors.mbt` | Checked fixture table consumed by QOI tests | ✓ VERIFIED | Generated table is current and `_generated_qoi_cases()` is consumed by `decode_wbtest.mbt`. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `qoi.mbt` | `codec/contracts.mbt` | `ImageDecoder` implementation | ✓ WIRED | `decode.mbt` provides public `ImageDecoder::probe` and `ImageDecoder::decode` implementations for `QoiDecoder`, using unchanged codec types. |
| `decode.mbt` | `storage/owned_image.mbt` | One post-preflight allocation and mutable fill | ✓ WIRED | Header limits and descriptor construction precede the sole `OwnedImage::new_operation` call; `with_mut_view` fills decoded pixels. |
| `decode.mbt` | `io/exact.mbt` | Exact forward-only reads | ✓ WIRED | `qoi_read_one` and strict EOF validation call `@io.read_exact`; payload failures are reclassified as QOI payload diagnostics. |
| `Generate-QoiVectors.ps1` | `generated_vectors.mbt` | Deterministic source-to-generated check | ✓ WIRED | The script reads `cases.json`, emits/checks `generated_vectors.mbt`, and the white-box test iterates `_generated_qoi_cases()` during the all-target suite. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `generated_vectors.mbt` | `_generated_qoi_cases()` | `fixtures/qoi/cases.json` through `Generate-QoiVectors.ps1` | JSON valid cases are deterministically materialized; `-Check` verified byte-for-byte freshness and the white-box test consumes the table. | ✓ FLOWING |
| `decode.mbt` | decoded pixels and descriptor | Caller `Reader` plus parsed QOI header/chunks | Exact reads populate the QOI state machine and `OwnedImage` mutable view; all-target valid-vector and RGB/RGBA tests passed. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Fixture generation and provenance are current | `pwsh -NoProfile -File scripts/fixtures/Generate-QoiVectors.ps1 -Check` | `QOI vector generation/check passed.` | ✓ PASS |
| QOI codec behavior is portable | `moon -C modules/mb-image test --target all --frozen` | 227/227 passed on wasm, wasm-gc, js, and native. | ✓ PASS |

### Probe Execution

No phase-declared or conventional `scripts/**/tests/probe-*.sh` probes were present; no probe execution was applicable.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| QOI-01 | `13-01-PLAN.md` | Probe QOI without consuming it and return deterministic match/no-match/need-more outcomes. | ✓ SATISFIED | Prefix implementation plus its four-target public test. |
| QOI-02 | `13-01-PLAN.md` | Decode valid RGB/RGBA QOI into a portable owned image with exact pixels and semantics. | ✓ SATISFIED | Generated all-opcode vectors and public RGB/RGBA descriptor tests pass on all targets. |
| QOI-04 | `13-01-PLAN.md` | Typed failures for hostile input with atomic preflight resource handling. | ✓ SATISFIED | Hostile-reader, malformed-input, strict-completion, and budget-atomicity tests pass on all targets. |

No requirement mapped to Phase 13 is orphaned from the plan. QOI-03, QOI-05, and QOI-06 are explicitly mapped to later phases and are not Phase 13 gaps.

### Anti-Patterns Found

No `TBD`, `FIXME`, `XXX`, placeholder, empty-implementation, forbidden dependency, registry, encoder, streaming, or FFI markers were found in the phase implementation and fixture files. The Phase 13 commit range changes no `modules/mb-image/codec/` file.

### Disconfirmation Pass

- A potential partial requirement — generated adversarial fixture identifiers are descriptive rather than standalone encoded hostile streams — does not leave the required hostile behaviors untested: the public QOI tests directly exercise malformed headers, truncated payloads, run overrun, end marker/trailing data, and scripted reader failures on every target.
- A potentially misleading success signal — the generic key-link query reported literal-path misses because MoonBit imports packages rather than source-file paths — was rejected as proof. Direct source inspection verified every package/API connection listed above.
- An uncovered error path was sought in prefix classification, decoding state, and reader handling. The test suite includes incomplete/non-QOI probing, all six chunk families, strict/relaxed completion, and zero-progress/host reader failures; no untested phase-critical path was found that contradicts the roadmap contract.

---

_Verified: 2026-07-20T10:48:19Z_
_Verifier: the agent (gsd-verifier)_
