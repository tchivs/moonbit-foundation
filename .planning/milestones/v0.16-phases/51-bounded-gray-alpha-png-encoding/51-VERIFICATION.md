---
phase: 51-bounded-gray-alpha-png-encoding
verified: 2026-07-23T00:00:00Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 51: Bounded Gray+Alpha PNG Encoding Verification Report

**Phase Goal:** Library users can produce standards-compliant, non-interlaced Gray+Alpha8 PNGs through the existing bounded eager and caller-buffered pipeline.
**Verified:** 2026-07-23T00:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A compatible Gray+Alpha8 image can use explicit eager or caller-buffered factories and receive an 8-bit, type-4, non-interlaced PNG. | ✓ VERIFIED | `PngEncoder::new_graya8*` in `png.mbt:181-221` and `PngChunkEncoder::new_graya8*` in `stream_encode.mbt:98-159` expose default, compression-only, filter-only, and combined forms. Their combined forms select `GrayAlpha8` and `None`; the IHDR emitter maps that profile to depth `8`, colour type `4`, and interlace `0` (`stream_encode.mbt:1048-1068`). Native package execution passed 195/195. |
| 2 | Decoding emitted PNGs preserves every compatible source gray/alpha pair. | ✓ VERIFIED | The concrete two-pixel fixture contains non-symmetric `(13,A7)` and `(D2,4C)` source pairs. The eager regression asserts the Stored raster bytes are gray then alpha and invokes the real decoder; `png_encode_graya8_decode_matches_source` checks canonical RGBA channels 0–2 equal gray and channel 3 equals alpha (`encode_test.mbt:150-174,383-410,905-916`). That behavioral test passed. |
| 3 | The explicit route supports None/Adaptive filtering with Stored, FixedOrStored, and DynamicOrFixedOrStored compression under the established bounded contract. | ✓ VERIFIED | Both eager and chunk constructors delegate to the shared combined profile route. The eager matrix covers all six pairs (`encode_test.mbt:931-956`); the chunk test constructs a fresh encoder for all six, drains it, checks byte identity with eager, and checks IHDR framing (`stream_encode_test.mbt:791-821`). The machine runs the existing profile-aware preflight/filter/planner/replay transaction (`stream_encode.mbt:527-584`; `encode.mbt:1520-1541,1560-1787`). Native package execution passed 195/195. |
| 4 | Incompatible inputs and geometry/output/work/budget failures are reported before eager output or caller-buffered lease exposure. | ✓ VERIFIED | `_png_encode_source` rejects non-packed/non-sRGB/non-top-left/non-GrayAlpha/non-straight/non-U8 sources before source reads and later budget charge (`encode.mbt:54-149`); the graya8 combined chunk constructor returns `Err` before constructing `PngChunkEncoder` (`stream_encode.mbt:144-159`). The atomicity test crosses all six pairs with an incompatible descriptor plus width, output, work, and budget envelopes; it asserts matching typed errors, zero eager writer position, unchanged budgets, and every `Z` sentinel lease byte untouched (`stream_encode_test.mbt:2148-2189,2291-2309`). That behavioral test passed. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Private `GrayAlpha8` profile and four eager graya8 factory forms. | ✓ VERIFIED | L1 exists; L2 has substantive factory implementations; L3 each public convenience factory delegates to `new_graya8_with_strategies`, which fixes `GrayAlpha8` and `None`. Legacy, Gray8, and Gray16 profile arms remain present. |
| `modules/mb-image/png/encode.mbt` | Locked descriptor admission, two-byte U8 raster layout, and shared preflight. | ✓ VERIFIED | L1 exists; L2 performs common layout/metadata checks then closed GrayAlpha/U8/straight-alpha admission and checked row geometry; L3 `channels=2` flows to scalar wire/filter/preflight/planning without a conversion buffer. |
| `modules/mb-image/png/stream_encode.mbt` | Four caller-buffered forms and type-4 IHDR emission through `PngEncodeMachine`. | ✓ VERIFIED | L1 exists; L2 constructs the shared machine and emits profile-specific IHDR; L3 the combined public constructor calls `new_with_profile` before an encoder value exists. |
| `modules/mb-image/png/encode_test.mbt` | Eager framing, wire-order, decoder-fidelity, and strategy regressions. | ✓ VERIFIED | Uses real owned image, real memory writer, real PNG decoder, non-symmetric source bytes, and all six eager strategy pairs. |
| `modules/mb-image/png/stream_encode_test.mbt` | Caller-buffered parity and atomic preflight regressions. | ✓ VERIFIED | Uses real public constructors and drain helper; checks each public convenience form, all six strategy pairs, and error-state/lease-sentinel atomicity. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `PngEncoder::new_graya8_with_strategies` | `_png_encode_source` / bounded preflight | `GrayAlpha8` profile passed to `ImageEncoder::encode` → `PngEncodeMachine::new_with_profile` | ✓ WIRED | `png.mbt:207-220`; `encode.mbt:1791-1806`; profile admission precedes scanline work and final budget charge. |
| `PngChunkEncoder::new_graya8_with_strategies` | `PngEncodeMachine::new_with_profile` | Direct construction call with `GrayAlpha8`, supplied strategies, and non-interlaced selection | ✓ WIRED | `stream_encode.mbt:144-159`; an error returns before `PngChunkEncoderState::Active` can be created. |
| GrayAlpha profile channels | PNG scanline bytes / IHDR | Generic U8 scalar fallback with `channels=2`; profile-specific IHDR branch | ✓ WIRED | `_png_wire_byte` obtains component `position % channels`, yielding component 0 then 1 (`encode.mbt:405-424`); `stream_encode.mbt:1061-1067` emits `08 04 00 00 00`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Eager graya8 encode path | `channels`, scanline wire bytes | Validated packed `ImageView` → `_png_encode_source` → generic scalar reader → filter/planner/replay | The data-bearing fixture writes `13 A7 D2 4C`; the Stored PNG test observes these exact gray/alpha bytes in the raster and decoder output. | ✓ FLOWING |
| Caller-buffered graya8 path | chunk bytes and lease state | Validated `ImageView` → `PngEncodeMachine` → caller-owned drain leases | Each strategy-pair drain is byte-identical to the real eager output; failure paths leave a real caller-owned sentinel unchanged. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Native PNG package, including GrayAlpha eager fidelity, factory matrix, chunk parity, and atomicity | `moon -C modules/mb-image test png --target native --frozen` | 195 passed, 0 failed | ✓ PASS |
| Phase 50 GrayAlpha descriptor/storage/operation handoff across portable targets | `moon test --target all modules/mb-image/model modules/mb-image/storage modules/mb-image/ops` | 79 passed, 0 failed on wasm, wasm-gc, js, and native | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| GRAYA-02 | `51-01-PLAN.md`, `51-02-PLAN.md` | Explicit eager and caller-buffered factories emit non-interlaced type-4/8-bit PNGs while preserving gray/alpha pairs. | ✓ SATISFIED | Truths 1–2, real framing/raster/decoder tests, and six-pair eager/chunk parity above. |
| GRAYA-03 | `51-01-PLAN.md`, `51-02-PLAN.md` | Both routes share bounded preflight, filtering, planning, and acknowledgement-safe replay; unsupported/resource failures are atomic. | ✓ SATISFIED | Truths 3–4: the same `PngEncodeMachine` construction path plus every-pair ordinary and atomic rejection tests. |

No requirements mapped to Phase 51 are orphaned: `GRAYA-02` and `GRAYA-03` are declared by both plans and are covered above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, `TODO`, placeholder, empty implementation, or hardcoded-empty-output pattern was introduced in the five Phase 51 PNG source/test files. | ℹ️ Info | No completion-blocking debt marker or stub evidence found. |

### Scope and Disconfirmation Checks

- Initial verification: no prior `51-VERIFICATION.md` and no overrides exist.
- The verifier tool did not parse the plans' scalar artifact/key-link declarations (`0` declared artifacts/links), so the required artifact and link checks above were performed manually at the concrete implementation seams rather than treating that empty tool result as evidence.
- Disconfirmation pass: a factory-only implementation would have failed because each public combined route was traced to `PngEncodeMachine::new_with_profile`; a PNG-header-only test would have failed because the regression observes non-symmetric raster bytes and real decoder canonicalization; a late-error implementation would have failed the six-pair writer/budget/sentinel assertions.
- `git diff --check` is clean. The Phase implementation diff adds only the five planned PNG source/test files; no FFI, release/registry automation, target-specific implementation, alternate encoder, staging buffer, or copied/generated source tree was added. The only matching phrase in the changed source is pre-existing explanatory decoder/interlace documentation, not a stub.
- Phase 52 explicitly owns hostile schedules, frozen legacy vectors, and public four-target GrayAlpha qualification. Those items are not gaps in Phase 51 because the Phase 51 roadmap contract is met; Phase 50's all-target model handoff was independently re-run above.

### Gaps Summary

No gaps found. The private GrayAlpha8 profile is admitted through the same bounded preflight/replay machine used by the existing routes; public eager and caller-buffered factory families are substantive and wired; the type-4/8-bit/non-interlaced wire form and gray/alpha order are behaviorally exercised; all six strategy pairs and all specified pre-exposure failures have executable coverage.

---

_Verified: 2026-07-23T00:00:00Z_
_Verifier: the agent (gsd-verifier)_
