---
phase: 59-grayalpha8-adam7-factory-and-pass-profile
verified: 2026-07-23T02:36:49Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 59: GrayAlpha8 Adam7 Factory and Pass Profile Verification Report

**Phase Goal:** Library users can explicitly select eager or caller-buffered Adam7 encoding for legal packed U8 Gray+Alpha images and receive standards-compliant interlaced Type-4/8 PNGs without changing existing non-interlaced behavior.
**Verified:** 2026-07-23T02:36:49Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can explicitly select eager or caller-buffered Adam7 encoding for a legal packed, straight-alpha U8 GrayAlpha image. | ✓ VERIFIED | Public eager selectors are additive at `png.mbt:225` and `:235`; matching chunk selectors are additive at `stream_encode.mbt:165` and `:180`. Both named eager/chunk selector tests passed. |
| 2 | Each selected factory emits Type-4/depth-8/Adam7 output, and all seven nonempty 5×5 passes serialize samples as G,A. | ✓ VERIFIED | The shared machine writes profile `GrayAlpha8` as IHDR depth `0x08`, colour type `0x04`, and Adam7 `0x01` (`stream_encode.mbt:1200-1206`). The independent seven-pass G,A oracle (`encode_test.mbt:311-328`) passed against both narrow and all-strategy eager selectors. |
| 3 | Existing GrayAlpha8 non-interlaced constructors remain method 0 and retain their frozen bytes. | ✓ VERIFIED | Legacy eager and chunk factories still explicitly forward `PngInterlaceStrategy::None` (`png.mbt:210-219`, `stream_encode.mbt:144-159`). Existing literal eager and chunk compatibility-vector tests both passed. |
| 4 | Every legal all-strategy eager GrayAlpha8 Adam7 compression/filter pairing keeps the Type-4/8/Adam7 identity. | ✓ VERIFIED | The eager strategy test iterates Stored, FixedOrStored, and DynamicOrFixedOrStored × None/Adaptive (`encode_test.mbt:1343-1350`) and passed. |
| 5 | Narrow and all-strategy caller-buffered Adam7 selectors have ordinary-drain parity with fresh eager output. | ✓ VERIFIED | Stored/None narrow/all-selector parity is tested at `stream_encode_test.mbt:1210-1244`; all six all-strategy pairs are independently drained and compared at `:1248-1280`. Both named chunk tests passed. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Locked Decision Verification

| Decision | Status | Codebase evidence |
| --- | --- | --- |
| D-01 — additive mirrored eager/chunk factories; no legacy constructor change | ✓ VERIFIED | The production diff adds exactly the four GrayAlpha8 interlace/all-strategy selectors. Existing `new_graya8*` factory signatures remain and retain explicit None forwarding. |
| D-02 — shared profile-aware machine; only GrayAlpha8 restriction lifted; no staging route | ✓ VERIFIED | Eager encoding forwards the selected profile/interlace to `PngEncodeMachine::new_with_profile` (`encode.mbt:1813-1828`); chunk all-strategy does the same (`stream_encode.mbt:189-196`). The Phase 59 production diff only deletes the GrayAlpha8 preflight rejection and adds factory forwarding; it introduces no machine, cursor, pass buffer, decoder, or target branch. Gray8 and Gray16 Adam7 rejections remain (`encode.mbt:1553-1559`). |
| D-03 — Type-4/8 Adam7 wire samples are G,A through the existing seven-pass cursor | ✓ VERIFIED | GrayAlpha8 uses two source channels (`encode.mbt:130-140`), scalar U8 wire reads preserve `position % channels` (`encode.mbt:427-445`), and Adam7 source coordinates call that same reader (`:556-602`). The non-symmetric 5×5 oracle explicitly emits seven-pass filter-0 G,A rows and passed. |
| D-04 — legal packed straight-alpha sRGB/top-left admission and frozen interlace-0 output | ✓ VERIFIED | Shared admission still requires packed layout, builtin encoded sRGB, top-left orientation, GrayAlpha, straight alpha, and U8 (`encode.mbt:71-85`, `:130-140`). Literal eager and chunk legacy vectors passed with IHDR interlace method `0`. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Additive public eager selectors | ✓ VERIFIED | Substantive public narrow and all-strategy factories retain profile and selected interlace; eager adapter is wired to the shared machine. |
| `modules/mb-image/png/encode.mbt` | GrayAlpha8 Adam7 admission and profile-aware scalar traversal | ✓ VERIFIED | Only the GrayAlpha8 Adam7 rejection was removed; existing legal-source checks, `_png_adam7_passes`, and `_png_wire_byte` remain authoritative. |
| `modules/mb-image/png/stream_encode.mbt` | Additive public caller-buffered selectors using the existing machine | ✓ VERIFIED | Narrow factory delegates to all-strategy; all-strategy constructs `PngEncodeMachine::new_with_profile(... GrayAlpha8 ...)`. |
| `modules/mb-image/png/encode_test.mbt` | Independent eager Type-4/8 G,A wire proof and legacy regression | ✓ VERIFIED | Non-symmetric 5×5 fixture, independent seven-pass raster, all eager strategy framing, and frozen vector coverage are substantive and executed. |
| `modules/mb-image/png/stream_encode_test.mbt` | Ordinary caller-buffered/eager parity and legacy regression | ✓ VERIFIED | Fresh-source selector parity tests cover Stored/None narrow parity and all six all-strategy combinations; frozen vector test remains wired. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `encode.mbt` | `ImageEncoder::encode` forwards profile/interlace to `PngEncodeMachine::new_with_profile` | WIRED | The eager selector record is consumed at `encode.mbt:1822-1824`, not bypassed by a separate eager encoder. |
| `stream_encode.mbt` | shared machine/preflight | `new_graya8_with_all_strategies` constructs `PngEncodeMachine::new_with_profile` | WIRED | Direct profile/interlace forwarding at `stream_encode.mbt:189-196`; machine preflight is invoked at `:675-680`. |
| Adam7 cursor | scalar source wire reads | `_png_adam7_raw_byte` calls `_png_wire_byte` | WIRED | Pass-local coordinate mapping at `encode.mbt:598-602` reaches the same profile-aware scalar reader as other paths. |
| Public factories | regression tests | Named public selector tests | WIRED | Four Phase 59 named tests passed after verification. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `PngEncodeMachine` | GrayAlpha8 pass sample bytes | Legal `ImageView` → Adam7 coordinate → `_png_wire_byte` | `source.get_byte(x, y, channel)` reads caller-supplied G then A, not static data | ✓ FLOWING |
| Eager/chunk selectors | profile/interlace/strategy | Public factory arguments → shared machine → IHDR/raster | IHDR derives from the retained profile and selected interlace; raster derives from the caller image | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Independent seven-pass eager G,A raster and narrow/all selector parity | `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 eager pass profile'` | 1 passed, 0 failed | ✓ PASS |
| Six eager compression/filter framing pairs | `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 eager all strategy framing'` | 1 passed, 0 failed | ✓ PASS |
| Narrow/all Stored-None chunk parity | `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 chunk parity'` | 1 passed, 0 failed | ✓ PASS |
| Six all-strategy chunk/eager parity pairs | `moon -C modules/mb-image test png --target native --frozen -f 'PNG GrayAlpha8 Adam7 chunk all strategy parity'` | 1 passed, 0 failed | ✓ PASS |
| Eager frozen GrayAlpha8 vector | `moon -C modules/mb-image test png --target native --frozen -f 'PNG filter strategy eager frozen compatibility vectors'` | 1 passed, 0 failed | ✓ PASS |
| Caller-buffered frozen GrayAlpha8 vector | `moon -C modules/mb-image test png --target native --frozen -f 'PNG filter strategy chunk frozen compatibility vectors'` | 1 passed, 0 failed | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| GRAYA8A7-01 | 59-01, 59-02 | Explicit public eager/chunk Type-4/8 Adam7 factories for legal GrayAlpha8 sources; existing non-interlaced factories and bytes unchanged. | ✓ SATISFIED | Public factory definitions, single-machine wiring, independent pass-wire oracle, six-pair framing/parity, and literal legacy-vector tests all verified. |

No requirements mapped to Phase 59 are orphaned: both plans declare `GRAYA8A7-01`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No Phase-59-added `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or hardcoded-empty output pattern found. | — | — |

### Disconfirmation Pass

- Partial-requirement check: the initial plan only required Stored/None chunk parity, but the committed `PNG GrayAlpha8 Adam7 chunk all strategy parity` test genuinely iterates all six legal pairs; the broader summary claim is supported.
- Misleading-test check: the G,A proof is not encoder self-consistency. Its expected raster independently enumerates the seven Adam7 geometries and uses different Gray (`0x20 + sample`) and Alpha (`0xa0 + sample`) values.
- Error-path check: this phase deliberately does not claim hostile schedules, replay/mutation safety, atomic-admission matrices, decode proof, or all-target qualification. Those are explicitly scheduled to Phases 60–61 and are not required to establish Phase 59's factory/profile goal.

### Human Verification Required

None. The goal's runtime-dependent assertions have direct passing named tests; this is a library-only phase with no visual or external-service behavior.

### Gaps Summary

No gaps found. The Phase 59 production diff is limited to additive public factory forwarding plus removal of the former GrayAlpha8-specific Adam7 rejection. All required behavior is exercised through the established bounded machine and verified by passing targeted tests.

---

_Verified: 2026-07-23T02:36:49Z_
_Verifier: the agent (gsd-verifier)_
