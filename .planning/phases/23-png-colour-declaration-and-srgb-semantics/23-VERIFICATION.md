---
phase: 23-png-colour-declaration-and-srgb-semantics
verified: 2026-07-21T01:22:04Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 2/3
  gaps_closed:
    - "The eager PNG decoder rejects fixed-size sRGB, gAMA, and cHRM declarations from their declared header length before payload accumulation."
  gaps_remaining: []
  regressions: []
---

# Phase 23: PNG Colour Declaration and sRGB Semantics Verification Report

**Phase Goal:** A library user can receive strict validated PNG colour declarations, with `sRGB` mapped truthfully to the existing encoded-sRGB image model.
**Verified:** 2026-07-21T01:22:04Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `sRGB`, `gAMA`, `cHRM`, and `iCCP` singleton/order/payload rules are enforced before image visibility. | ✓ VERIFIED | `structural.mbt:787-800` selects the only legal fixed size (1/4/32) and returns the corresponding typed error before `payload` is created at line 801 or `_png_read_one` enters at line 810. `structural.mbt:1239-1249` routes recognised chunks through that parser before IDAT allocation. The all-target generated decoder test passed. |
| 2 | Valid `sRGB` images preserve rendering intent and expose built-in encoded-sRGB metadata; malformed or conflicting declarations fail deterministically. | ✓ VERIFIED | CRC is advanced for every legal fixed payload byte and verified at `structural.mbt:810-842`; only then does it validate semantics at lines 843-853. Valid intent is carried in `PngStreamTransport` and consumed by `png.mbt:68-84`. The generated test asserts `Srgb`, `EncodedSrgb`, the built-in profile, exactly one opaque metadata entry, and the intent byte (`png_test.mbt:415-423`) on every target. |
| 3 | Valid non-sRGB `gAMA`, `cHRM`, and `iCCP` declarations do not relabel raw samples as sRGB and return the typed transform-unavailable boundary. | ✓ VERIFIED | `_png_colour_declaration` selects `NonSrgb` for iCCP or non-sRGB legacy facts (`structural.mbt:128-137`), and transport returns `png-colour-transform-unavailable` before image construction at `structural.mbt:1257-1263`. Generated hostile/non-sRGB cases execute through the public decoder and assert category, code, and context (`png_test.mbt:457-483`). |
| 4 | Existing reference operations continue to accept only actual encoded-sRGB images. | ✓ VERIFIED | `ImageDescriptor::supports_reference_operations` requires both `Srgb` and `EncodedSrgb` (`model/descriptor.mbt:684-697`); `model_test.mbt:201-220` proves linear-sRGB is rejected. `moon -C modules/mb-image test model --target all --frozen` passed 13/13 on wasm, wasm-gc, js, and native. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/structural.mbt` | Strict colour state, pre-payload fixed-length gates, CRC parsing, and transport facts. | ✓ VERIFIED | Exists (1,411 lines), substantive, and wired. The fixed gate precedes the array allocation/read loop; legal data remains bounded to at most 32 bytes and CRC-authenticated. |
| `modules/mb-image/png/png.mbt` | sRGB-aware descriptor metadata and non-sRGB capability boundary. | ✓ VERIFIED | Consumes only the validated `srgb_intent`/metadata budget and builds the descriptor before raster decoding. |
| `scripts/fixtures/Generate-PngDecodeVectors.ps1` | Independent hostile header-only construction and colour oracle. | ✓ VERIFIED | Requires fixed kinds, `header_only: true`, `declared_length: 2147483647`, no payload fields, and pre-PLTE placement before emitting `HeaderOnly-Chunk` (lines 57-101). |
| `fixtures/png/decode-cases.json` | Declarative 2 GiB hostile cases. | ✓ VERIFIED | Contains one header-only `sRGB`, `gAMA`, and `cHRM` record at lines 158-160 with the three expected typed contexts. |
| `modules/mb-image/png/generated_decode_vectors_test.mbt` | Executable portable hostile decoder records. | ✓ VERIFIED | Lines 3764-3766 contain compact inputs ending immediately after `sRGB`/`gAMA`/`cHRM` type bytes — no declared payload or CRC can be read. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `structural.mbt` | `png.mbt` | `PngStreamTransport` carries validated declaration facts to descriptor construction. | ✓ WIRED | `srgb_intent` is produced only after CRC/semantic validation and read by `png.mbt:68-80`; automated key-link verification passed. |
| `fixtures/png/decode-cases.json` | `generated_decode_vectors_test.mbt` | Independent PowerShell generator emits the test corpus. | ✓ WIRED | Generator freshness check passed for 3,773 cases; automated key-link verification passed. |
| `structural.mbt` | `png_test.mbt` | `PngDecoder` runs the generated header-only records through `_png_read_colour_chunk`. | ✓ WIRED | `png_test_decode_vector` constructs a `MemoryReader` and invokes `PngDecoder` (`png_test.mbt:386-402`); the test loops over every generated case (`406-408`). |
| `generated_decode_vectors_test.mbt` | error assertions | Declared contexts are compared with the returned error. | ✓ WIRED | Error branch requires an error result and checks category, code, and exact context (`png_test.mbt:457-483`). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `structural.mbt` | `length`, `kind`, `PngColourFacts` | PNG chunk header read from the supplied `Reader` | The parser rejects fixed-size malformed declarations before a byte is read; legal bytes feed CRC and semantic facts. | ✓ FLOWING |
| `png.mbt` | `stream.srgb_intent` | CRC-authenticated valid `sRGB` payload | The value becomes bounded opaque metadata and is asserted in portable generated tests. | ✓ FLOWING |
| generated vector corpus | `PngDecodeVector.bytes` | Independent JSON → PowerShell assembly | The three 2 GiB records end after the chunk type and produce their fixed-length errors, not EOF/allocation errors. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Fixture grammar, manifest, generated-source freshness, and header-only vectors | `pwsh -NoProfile -File scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` | 3,773 executable cases | ✓ PASS |
| PNG colour/parser behavior on supported targets | `moon -C modules/mb-image test png --target all --frozen` | 38/38 passed on wasm, wasm-gc, js, native | ✓ PASS |
| PNG policy, generator, target, and isolation checks | `pwsh -NoProfile -File scripts/quality/Invoke-MoonQuality.ps1 -Lane Png` | Passed; only pre-existing unused-field compiler warnings | ✓ PASS |
| Reference-operation encoded-sRGB gate | `moon -C modules/mb-image test model --target all --frozen` | 13/13 passed on wasm, wasm-gc, js, native | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no Phase 23 probe declaration and no `scripts/**/tests/probe-*.sh` files exist.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGCM-01 | `23-01-PLAN.md`, `23-02-PLAN.md` | Typed deterministic rejection for duplicate, late, malformed, or conflicting recognised colour chunks before an image is exposed. | ✓ SATISFIED | The corrected fixed-size pre-payload gate is live and covered by three 2 GiB header-only all-target records; ordering, singleton, CRC, conflict, and typed errors remain wired. |
| PNGCM-02 | `23-01-PLAN.md` | Valid `sRGB` decodes into existing encoded-sRGB metadata with retained intent. | ✓ SATISFIED | Validated intent flows to the descriptor and all-target generated tests inspect every required metadata property. |

No requirement mapped to Phase 23 is orphaned from the plans.

### Anti-Patterns Found

No blocker or warning anti-patterns were found in the Phase 23 implementation, generated corpus, generator, or tests. The prior unbounded accumulation was removed: the payload array remains only for legal, fixed 1/4/32-byte declarations. No unreferenced `TBD`, `FIXME`, or `XXX` markers were found.

### Re-verification Finding

The prior blocker is falsified by live code and executable evidence. An arbitrary declared size for `sRGB`, `gAMA`, or `cHRM` reaches the fixed-length decision immediately after the chunk header. The parser has neither entered its payload loop nor retained a payload byte; the generated 2 GiB records physically end after the chunk type and still return `png-srgb-length`, `png-gama-length`, and `png-chrm-length`. Conversely, legal fixed-size chunks take the existing CRC and semantic path, verified by the all-target suite.

---

_Verified: 2026-07-21T01:22:04Z_
_Verifier: the agent (gsd-verifier)_
