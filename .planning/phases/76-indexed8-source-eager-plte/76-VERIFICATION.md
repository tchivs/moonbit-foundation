---
phase: 76-indexed8-source-eager-plte
verified: 2026-07-23T20:13:20Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 76: Indexed8 PNG Source & Eager PLTE Verification Report

**Phase Goal:** Define an owning PNG-only indexed source and emit bounded Type-3/8 eager PNG with PLTE.
**Verified:** 2026-07-23T20:13:20Z
**Status:** passed
**Re-verification:** No — metadata refresh only. The previous report had no gaps; `f13dec3` changed only `76-01-SUMMARY.md` metadata by adding `requirements-completed: [INDEX-01, INDEX-02]`.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can construct an immutable, PNG-only Indexed8 source from unpacked indices and RGB palette triples. | ✓ VERIFIED | `PngIndexedImage` is an owning public type in `modules/mb-image/png/png.mbt:201-207`. Its constructor validates PNG U32 dimensions, checked pixel count, exact raster length, RGB triples, 1–256 palette entries, and every index before the sole charged `OwnedBytes` allocation (`224-279`); storage is private and exposed only through internal read accessors (`315-353`). The optional alpha argument is the later Phase 77 extension; opaque Phase 76 inputs use all-`FF` alpha. |
| 2 | A valid indexed source eagerly emits a bounded non-interlaced Type-3/8 PNG in IHDR, PLTE, IDAT, IEND order using Stored DEFLATE and filter None. | ✓ VERIFIED | `_png_encode_indexed_preflight` computes checked scanline/output facts, applies all limits, and charges work before creating output state (`encode.mbt:2042-2123`). `PngEncoder::encode_indexed8` creates the indexed machine (`2174-2212`), whose constructor fixes Indexed8/Stored/None/non-interlaced (`stream_encode.mbt:929-958`) and whose byte emitter writes PLTE before IDAT (`1420-1495`). The opaque test independently asserts the exact 89-byte vector, Type-3/8 IHDR, PLTE/IDAT/IEND order, Stored bytes, and every chunk CRC (`encode_test.mbt:990-1025`). |
| 3 | Malformed indexed sources and failed eager limits or budget admission expose neither writer bytes nor a partial budget charge. | ✓ VERIFIED | Source validation precedes allocation (`png.mbt:232-273`); eager preflight validates output/work/pixel limits before machine construction (`encode.mbt:2089-2113`). `encode_test.mbt:1059-1137` exercises invalid dimensions, palette shape/alpha cardinality, out-of-range indices, source budget refusal, output/work/pixel admissions, zero writer position, and unchanged budget snapshots. |
| 4 | Existing PNG source profiles retain their exact legacy output bytes while the indexed output decodes through the public generic RGB8 route. | ✓ VERIFIED | Public decode-back uses `ImageDecoder::decode(PngDecoder::new(), ...)` and asserts RGB with the expected palette-expanded pixels (`encode_test.mbt:887-917`). Private frame facts prove Indexed PLTE offsets while zero-PLTE legacy facts remain `idat_start=33`, `iend_start=60`, and total `72` (`encode_wbtest.mbt:1091-1123`). |

**Score:** 4/4 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Public `PngIndexedImage` contract and indexed eager API input. | ✓ VERIFIED | Substantive owning source with one charged defensive copy; consumed by the encoder/machine, not orphaned. |
| `modules/mb-image/png/encode.mbt` | Indexed admission and bounded preflight. | ✓ VERIFIED | `encode_indexed8` calls `PngEncodeMachine::new_with_indexed`; preflight produces the machine facts and performs admission before writing. |
| `modules/mb-image/png/stream_encode.mbt` | Frame-aware IHDR/PLTE/IDAT/IEND byte machine with acknowledged CRC state. | ✓ VERIFIED | Indexed source and PLTE CRC are machine state (`704-742`); PLTE data is emitted from the source (`1448-1463`) and CRC advances only on accepted palette bytes (`1534-1538`). |
| `modules/mb-image/png/encode_test.mbt` | Public Type-3 wire, atomicity, and RGB8 decode-back proof. | ✓ VERIFIED | Uses a test-local CRC implementation (`956-970`), exact opaque wire checks, public decode, and atomic-admission cases. |
| `modules/mb-image/png/encode_wbtest.mbt` | Frame-fact and legacy-layout regression proof. | ✓ VERIFIED | Verifies Indexed8 offsets, PLTE CRC acknowledgement timing, oversized-IDAT rejection, and frozen zero-PLTE offsets. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `encode.mbt` | `PngEncoder::encode_indexed8` accepts `PngIndexedImage`. | ✓ WIRED | Public signature takes `PngIndexedImage` (`encode.mbt:2174-2181`); public tests construct it and pass it to the entry point (`encode_test.mbt:887-900`). |
| `encode.mbt` | `stream_encode.mbt` | Indexed preflight feeds the shared bounded machine. | ✓ WIRED | `encode_indexed8` calls `new_with_indexed` (`2182-2186`), which calls `_png_encode_indexed_preflight` before filling its frame/source state (`stream_encode.mbt:929-958`). |
| `stream_encode.mbt` | `encode_test.mbt` | Output bytes are independently checked and decoded. | ✓ WIRED | `byte_at` emits frame-derived PLTE/IDAT bytes; test-local wire/CRC checks and public decoder assertions consume the eager output (`encode_test.mbt:990-1025`, `887-917`). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `png.mbt` → `stream_encode.mbt` | Indexed raster and RGB palette bytes | Validated `PngIndexedImage` owned bytes | `index_at` and `palette_byte_at` read caller-derived, validated bytes; no static palette/raster fallback exists. | ✓ FLOWING |
| `encode.mbt` → `stream_encode.mbt` | Frame facts and resource limits | Checked dimensions/scanlines/palette length and codec limits | Facts determine PLTE, IDAT, IEND starts and total length before writer use. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Current main PNG suite on all supported targets | `moon -C modules/mb-image test png --target all --frozen --target-dir D:\source\moonbit-foundation-v019\.moon-phase78-main` | **Not re-run for this metadata refresh.** The Phase 78 independent verification records exit 0 in 187.3 s and `279/279` passing on each of wasm, wasm-gc, js, and native; it also records that the temporary target directory was absent afterwards. | ✓ PASS (recorded independent evidence) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| INDEX-01 | `76-01-PLAN.md` | Dedicated immutable Indexed8 PNG source with validated RGB palette and canonical unpacked index raster. | ✓ SATISFIED | Plan declares the requirement; the current owning source and public construction/decode tests above satisfy it. `76-01-SUMMARY.md` now explicitly declares it in `requirements-completed`. |
| INDEX-02 | `76-01-PLAN.md` | Bounded eager non-interlaced Type-3/8 framing with atomic rejection. | ✓ SATISFIED | Plan declares the requirement; preflight/machine wiring plus independent opaque wire/CRC and admission tests satisfy it. `76-01-SUMMARY.md` now explicitly declares it in `requirements-completed`. |

No Phase 76 requirement is orphaned: both roadmap-mapped IDs appear in the Phase 76 plan and summary metadata.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or hard-coded empty-output marker in the five Phase 76 source/test files. | ℹ️ Info | No audit-blocking implementation debt found. |

### Disconfirmation Pass

The plausible false-positive paths were checked explicitly: a constructor that aliases unvalidated caller input (ruled out by validation followed by one `OwnedBytes` copy), an eager API that bypasses bounded preflight (ruled out by the direct `new_with_indexed` link), and a PLTE stub or misplaced frame data (ruled out by exact opaque bytes plus independent CRC/order assertions). The Phase 77 alpha extension and Phase 78 chunk adapter are later-phase changes; they do not replace or disconnect the opaque Phase 76 source-to-eager path.

### Gaps Summary

None. The source, bounded eager wiring, data flow, independent wire/CRC evidence, public RGB8 decode-back, atomic rejection checks, and legacy-layout regression evidence satisfy the Phase 76 goal. This refresh deliberately did not run tests; the all-target result recorded above is the latest independent Phase 78 evidence on `main`, not a new execution claim.

---

_Verified: 2026-07-23T20:13:20Z_
_Verifier: gsd-verifier_
