---
phase: 56-grayalpha16-adam7-factory-and-pass-profile
verified: 2026-07-22T23:22:27Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 56: GrayAlpha16 Adam7 Factory and Pass Profile — Verification Report

**Phase Goal:** Library users can explicitly select eager or caller-buffered Adam7 encoding for legal packed U16 Gray+Alpha images and receive standards-compliant interlaced Type-4/16 PNGs.

**Verified:** 2026-07-22T23:22:27Z  
**Status:** passed  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A library user can select explicit eager and caller-buffered GrayAlpha16 Adam7 factories for a legal packed little-endian image. | ✓ VERIFIED | `PngEncoder` exposes `new_graya16_with_interlace_strategy` and `new_graya16_with_all_strategies` in `png.mbt`; `PngChunkEncoder` exposes the matching two public factories in `stream_encode.mbt`. The eager and chunk focused tests passed independently on wasm, wasm-gc, JS, and native. |
| 2 | Each generated image declares Adam7 interlace, colour type 4, and bit depth 16, with every pass sample serialized in PNG order as `Ghi,Glo,Ahi,Alo`. | ✓ VERIFIED | The `GrayAlpha16` profile has four bytes/pixel, the Adam7 cursor passes all sample reads through `_png_wire_byte`, and the U16 mapper reverses legal little-endian component bytes for PNG. The focused eager test asserts IHDR `[depth=0x10, type=0x04, compression=0, filter=0, interlace=1]` and byte-compares all 111 uncompressed Stored pass bytes against independently built seven-pass expectations; it passed on all four targets. |
| 3 | Strict Big-endian GrayAlpha16 descriptor rejection remains in force, and existing non-interlaced GrayAlpha16 factory selection remains unchanged. | ✓ VERIFIED | `validate_gray_alpha_identity` still requires packed little-endian storage. The targeted Big-endian descriptor test and eager/chunk non-interlaced regressions are included in the independently run native PNG suite, which passed 206/206. Existing `new_graya16*_with_strategies` factories still explicitly use `PngInterlaceStrategy::None`. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Additive public eager GrayAlpha16 Adam7 selectors | ✓ VERIFIED | L1 exists; L2 substantive public factory pair preserves `GrayAlpha16` and caller-selected interlace; L3 `ImageEncoder::encode` forwards those selected fields to `PngEncodeMachine::new_with_profile`. |
| `modules/mb-image/png/encode.mbt` | Profile-aware Adam7 wire traversal and legal admission | ✓ VERIFIED | L1 exists; L2 `GrayAlpha16` validates straight U16 Gray+Alpha and has a four-byte layout; L3 the Adam7 raw/candidate paths call `_png_wire_byte` and preflight admits GrayAlpha16 while retaining rejection for Gray8, Gray16, and GrayAlpha8 Adam7. |
| `modules/mb-image/png/stream_encode.mbt` | Additive caller-buffered GrayAlpha16 Adam7 selectors using the existing machine | ✓ VERIFIED | L1 exists; L2 substantive narrow and all-strategy public constructors; L3 each calls `PngEncodeMachine::new_with_profile(source, GrayAlpha16, ..., interlace_strategy, ...)` and returns an active encoder state. |
| `modules/mb-image/png/encode_test.mbt` | Eager framing and seven-pass lane-order regression | ✓ VERIFIED | L1 exists; L2 creates a distinct-byte 5×5 legal fixture and independently derives the seven Adam7 pass payloads; L3 the selected public factories are encoded and their 111 output bytes are checked. |
| `modules/mb-image/png/stream_encode_test.mbt` | Caller-buffered parity regression | ✓ VERIFIED | L1 exists; L2 drains both public chunk selector shapes with a ragged schedule; L3 each is compared with its corresponding public eager oracle and asserts the Type-4/16/Adam7 IHDR. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `png.mbt` | `encode.mbt` | `PngEncoder::new_graya16_with_all_strategies` stores the selected profile/interlace, then `ImageEncoder::encode` creates the profile-aware machine | ✓ WIRED | The eager factory preserves `GrayAlpha16` and the supplied interlace strategy; `PngEncoder::encode` forwards both to `PngEncodeMachine::new_with_profile`. |
| `stream_encode.mbt` | `encode.mbt` | `new_graya16_with_all_strategies` constructs the profile-aware machine | ✓ WIRED | Direct call passes `GrayAlpha16` and the caller's `interlace_strategy`; no alternate GrayAlpha16 machine or staging path exists. |
| `encode.mbt` | `encode_test.mbt` | Adam7 scalar reads use `_png_wire_byte` and the test checks the literal pass stream | ✓ WIRED | `_png_adam7_raw_byte` calls `_png_wire_byte`; the test's independently generated expected data exposes wrong component, byte, pass, or row order. |
| Public selectors | Test runner | Named MoonBit tests | ✓ WIRED | Both focused public-facing tests executed successfully on all configured package targets. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Eager factory and encoder | `profile`, `interlace_strategy` | Public factory arguments → `PngEncoder::encode` → `PngEncodeMachine::new_with_profile` | Legal 5×5 `ImageFormat::graya16()` storage is read during encoding | ✓ FLOWING |
| Adam7 traversal | pass-local source component bytes | `_png_adam7_raw_byte` → `_png_wire_byte` → `ImageView.get_component_byte` | The test fixture gives each gray/alpha high/low lane a distinct value and verifies all seven nonempty passes | ✓ FLOWING |
| Chunk factory | `PngEncodeMachine` active state | Caller source and factory choices passed directly to `new_with_profile` | Ordinary chunk drain is byte-identical to the corresponding eager output | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Eager selectors produce the required IHDR and seven-pass wire stream on every target | `moon -C modules/mb-image test png --target all --frozen -f 'PNG GrayAlpha16 Adam7 eager pass profile'` | 1/1 passed on wasm, wasm-gc, JS, native | ✓ PASS |
| Chunk selectors drain to their eager peers on every target | `moon -C modules/mb-image test png --target all --frozen -f 'PNG GrayAlpha16 Adam7 chunk parity'` | 1/1 passed on wasm, wasm-gc, JS, native | ✓ PASS |
| PNG regression baseline, including Big-endian admission and non-interlaced GrayAlpha16 tests | `moon -C modules/mb-image test png --target native --frozen` | 206/206 passed | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| GRAYA16A7-01 | 56-01, 56-02 | Explicit eager/chunk legal U16 Gray+Alpha Adam7 factories with Type-4/16 and `Ghi,Glo,Ahi,Alo` pass fidelity | ✓ SATISFIED | The public selectors, shared profile/machine wiring, literal pass-byte regression, all-target focused execution, and native 206/206 suite provide direct evidence. |

`REQUIREMENTS.md` still labels this requirement as `Planned`; that is planning metadata, not a contradiction of the implementation and test evidence above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | 24, 97 | Pre-existing prose contains “not available” | ℹ️ Info | `git blame` attributes these lines to pre-Phase-56 commits; they are explanatory comments, not placeholder behavior. No `TBD`, `FIXME`, or `XXX` markers, empty implementations, hardcoded empty production data, or unwired phase artifacts were found. |

### Disconfirmation Checks

- **Partial-requirement check:** verified that the all-strategy selectors do not merely exist: both preserve `GrayAlpha16` and forward the explicit Adam7 choice into the one machine.
- **Misleading-test check:** the eager test does not derive expected bytes through the encoder; it constructs Adam7 geometry and byte lanes independently, so a cursor/order regression cannot self-confirm.
- **Uncovered-error-path check:** Phase 56 intentionally does not claim Phase 57 bounded-resource/replay semantics. The selected route's basic admission and legacy regressions are covered by the native suite; the deferred wider failure matrix is not a Phase-56 gap because it is explicitly assigned to Phase 57.

### Human Verification Required

None. All goal-dependent runtime behaviors have direct automated evidence on the package's four supported targets or in the native regression suite.

### Gaps Summary

No gaps found. The phase goal and all three roadmap success criteria are achieved in the current codebase. Later Phase 57/58 work expands bounded strategy/replay and broader public evidence, but it does not defer any unmet Phase-56 truth.

---

_Verified: 2026-07-22T23:22:27Z_  
_Verifier: the agent (gsd-verifier)_
