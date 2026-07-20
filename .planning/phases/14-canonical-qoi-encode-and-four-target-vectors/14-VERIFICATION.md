---
phase: 14-canonical-qoi-encode-and-four-target-vectors
verified: 2026-07-20T11:27:33Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 14: Canonical QOI Encode and Four-Target Vectors Verification Report

**Phase Goal:** Library users can losslessly create canonical QOI 1.0 bytes whose behavior is reproducibly conformant across every portable target.
**Verified:** 2026-07-20T11:27:33Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can encode compatible packed U8 RGB and straight-RGBA TopLeft sRGB image views through `@codec.ImageEncoder` and decode the exact original pixels. | ✓ VERIFIED | `QoiEncoder` is public in `qoi.mbt`; its `ImageEncoder` implementation validates RGB/RGBA source semantics in `encode.mbt` and writes through the supplied Writer. Public and generated tests encode then invoke `QoiDecoder`, comparing every source byte, channel count, and transfer identity. The independent four-target run passed 235/235 tests on wasm, wasm-gc, js, and native. |
| 2 | The encoder emits one deterministic QOI 1.0 byte sequence, including a 14-byte header, canonical chunks, the exact eight-byte marker, and typed deterministic capability, limit, budget, and I/O behavior. | ✓ VERIFIED | `qoi_encode_source` validates dimensions before any budget charge or Writer call; `qoi_chunk_length` and `qoi_write_chunks` use matching RUN → INDEX → DIFF → LUMA → RGB → RGBA state rules; `qoi_encode_header` serializes big-endian dimensions; and the marker is exactly `00 00 00 00 00 00 00 01`. The u32 boundary test accepts `4294967295`, rejects `4294967296`, and asserts the maximum-width header. Pre-output capability/limit/budget failures and exact no-progress/later-failure Writer progress are exercised by the all-target suite. |
| 3 | Maintainers can run specification-derived opcode, index, run, wraparound, and byte-round-trip vectors unchanged on js, wasm, wasm-gc, and native. | ✓ VERIFIED | Repository JSON declares canonical RGB/RGBA, INDEX reuse/collision, DIFF wraparound, LUMA, RGB/RGBA fallback, initial state, and 1/62/63-pixel run cases. `Generate-QoiVectors.ps1 -Check` independently passed without leaving changed artifacts; generated cases feed `encode_wbtest.mbt`, which byte-compares encoder output and decodes it back. The four-target test command passed on every required target. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `modules/mb-image/qoi/qoi.mbt` | Public `QoiEncoder` beside `QoiDecoder` | ✓ VERIFIED | Defines `QoiEncoder` and `QoiEncoder::new`; compiled and invoked through the public encoder trait tests. |
| `modules/mb-image/qoi/encode.mbt` | Canonical `ImageEncoder` with prepass, budget charge, and forward Writer output | ✓ VERIFIED | 540 lines of substantive validation, state machine, exact-progress remapping, and trait implementation; no PPM/ops dependency. |
| `modules/mb-image/qoi/encode_test.mbt` | Public encoder and error/progress behavior tests | ✓ VERIFIED | Exercises headers, RGB/RGBA round trips, pre-output capability/limit/budget failures, no progress, and later host failure. |
| `modules/mb-image/qoi/encode_wbtest.mbt` | Generated canonical-byte and round-trip conformance tests | ✓ VERIFIED | Iterates generated records, compares full encoded bytes, checks decoded descriptor semantics and every pixel, and checks Writer progress. |
| `fixtures/qoi/cases.json` | Human-reviewable QOI fixture authority | ✓ VERIFIED | Contains 11 canonical encode cases covering all requested opcode/boundary categories, plus retained decode/adversarial records. |
| `scripts/fixtures/Generate-QoiVectors.ps1` | Deterministic checked generation and manifest provenance | ✓ VERIFIED | Emits the encoder case table, checks byte-exact generated output and manifest SHA-256 in `-Check` mode; command passed. |
| `modules/mb-image/qoi/generated_vectors.mbt` | Generated all-target conformance table | ✓ VERIFIED | Materialized canonical source and expected byte streams; consumed directly by `encode_wbtest.mbt`. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | ------ | ------- |
| `encode.mbt` | `codec/contracts.mbt` | `@codec.ImageEncoder::encode` | ✓ WIRED | Public trait implementation takes unchanged `EncodeOptions`, `CodecLimits`, `Budget`, Writer, diagnostics, and returns `EncodeResult`. |
| `encode.mbt` | `decode.mbt` | Shared QOI state semantics | ✓ WIRED | Encoder uses the package-private `QoiPixel`, `qoi_hash`, and empty-disposition helpers defined with the decoder; vector and public tests feed its bytes to `QoiDecoder`. |
| `Generate-QoiVectors.ps1` | `generated_vectors.mbt` | `-Check` generated-table validation | ✓ WIRED | The script builds `_generated_qoi_encode_cases`; the independent check command returned exit 0. |
| `encode_wbtest.mbt` | `encode.mbt` | Canonical byte and decoder round-trip tests | ✓ WIRED | Generated source records are encoded with `QoiEncoder`, byte-compared, then decoded with `QoiDecoder` in the test that passed on all targets. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `encode_wbtest.mbt` | generated vector tuple | `fixtures/qoi/cases.json` → generator → `generated_vectors.mbt` | Complete source pixels and expected QOI streams for 11 canonical cases | ✓ FLOWING |
| `encode.mbt` | logical source pixels | Caller `@storage.ImageView::get_byte` | Validated RGB/RGBA image bytes are traversed row-major in both prepass and write pass | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Generated vectors and manifest are current | `pwsh -NoProfile -File scripts/fixtures/Generate-QoiVectors.ps1 -Check` | `QOI vector generation/check passed.` | ✓ PASS |
| Canonical encoder, round trips, resource/I/O behavior, and vector tests on all portable targets | `moon -C modules/mb-image test --target all --frozen` | 235/235 passed on wasm, wasm-gc, js, and native | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ---------- | ----------- | ------ | -------- |
| QOI-03 | `14-01-PLAN.md` | Encode compatible RGB/straight-RGBA images as canonical QOI and recover pixels through decoding | ✓ SATISFIED | Public trait wiring plus byte-for-byte RGB/RGBA round-trip tests and all-target generated-vector round trips. |
| QOI-05 | `14-01-PLAN.md` | Verify specification-derived opcode, wraparound, index, run, and byte-round-trip vectors on four targets | ✓ SATISFIED | Checked JSON authority/generator and 11 canonical cases, executed by the successful four-target suite. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, empty-implementation, or hardcoded-empty-output markers in Phase 14 implementation/fixture files | ℹ️ Info | No auditable debt or stub evidence found. |

## Disconfirmation Checks

- **Partial-requirement check:** The QOI package remains independently importable. Its `moon.pkg` imports codec/model/storage and lower-level support only; it does not import PPM or ops, and Phase 14 commits touched only the eight planned encoder/fixture files.
- **Misleading-test check:** Fixture freshness alone would only prove JSON/table parity, so it was not accepted as conformance evidence. `encode_wbtest.mbt` actually encodes each generated source, compares the full stream, and decodes it through `QoiDecoder`; this ran on all four targets.
- **Error-path check:** Writer short-success/no-progress/partial-error behavior is routed through `@io.write_all`; its core tests exercise short writes and partial completion. Phase 14 additionally verifies QOI-specific remapping for zero progress and a failure after 15 bytes. Preflight capability, limit, and budget paths assert Writer position zero.

## Scope Check

The five Phase 14 commits modify only the planned QOI encoder/tests and QOI fixture generation/provenance files. `modules/mb-image/codec/contracts.mbt`, PPM, ops, registry, streaming, FFI, benchmark, release automation, and Phase 15 example code were not changed.

## Gaps Summary

No gaps found. All roadmap success criteria, QOI-03, QOI-05, and locked decisions D-01 through D-05 have code-and-test evidence.

---

_Verified: 2026-07-20T11:27:33Z_
_Verifier: the agent (gsd-verifier)_
