---
phase: 44-gray8-factory-compatibility
verified: 2026-07-22T10:56:39Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 44: Gray8 Factory Compatibility Verification Report

**Phase Goal:** Users can explicitly request standards-compliant, 8-bit, non-interlaced Gray8 PNG output for existing `ChannelOrder::Gray` images through eager and caller-buffered PNG factories without changing RGB8/RGBA8 results.
**Verified:** 2026-07-22T10:56:39Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A user can encode a packed U8 Gray image through explicit eager and caller-buffered default-Stored factories and receive a complete non-interlaced Gray8 PNG. | ✓ VERIFIED | `PngEncoder::new_gray8` and `PngChunkEncoder::new_gray8` select `Gray8` + Stored/None/None. The native suite passed 173/173, including the eager exact-byte fixture and chunk/eager identity test. Independent parsing of that accepted fixture verified PNG signature, all chunk CRCs, IHDR `1x1/8/type-0/non-interlaced`, and zlib scanline `00 7f`. |
| 2 | Existing RGB8 and straight-RGBA8 factories retain their existing admission behavior and exact bytes. | ✓ VERIFIED | All legacy public constructors still select `LegacyRgbOrRgba`; existing eager and chunk frozen RGB/RGBA vector tests ran successfully in the native 173/173 suite. |
| 3 | The public Gray8 route has a deterministic boundary: no palette output, low-bit packing, 16-bit samples, transparency conversion, or Adam7 interlacing is selected implicitly. | ✓ VERIFIED | `PngEncodeProfile` is private; only the two public `new_gray8` functions exist. Both hard-code Stored/None/None. Profile preflight rejects non-U8, unpacked, noncanonical metadata, alpha, and non-Gray sources before construction. |
| 4 | Gray8 source admission and rejection are deterministic and atomic; unsupported forms cannot enter the emitter. | ✓ VERIFIED | `_png_encode_source` validates component/layout/metadata/profile/row geometry before preflight reaches its sole budget charge. The eager and chunk native regressions exercise a wrong-profile rejection and assert zero writer bytes or unchanged budget respectively; the chunk test also preserves the sentinel lease. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Explicit default-Stored Gray8 profile selection for eager and chunk surfaces. | ✓ VERIFIED | Defines private `PngEncodeProfile`, public eager `new_gray8`, and keeps legacy factory construction on `LegacyRgbOrRgba`. |
| `modules/mb-image/png/encode.mbt` | Profile-aware Gray8 source admission and shared one-channel Stored preflight facts. | ✓ VERIFIED | Source checks return one channel only for Gray8; preflight records profile/channels/row bytes and charges budget only after validation and limits. |
| `modules/mb-image/png/stream_encode.mbt` | One-channel Stored IHDR, scanline traversal, byte emission, and acknowledgement-safe caller-buffered replay. | ✓ VERIFIED | Chunk factory reaches the profile-aware machine; machine uses shared `facts.channels` for traversal and derives IHDR type from `facts.profile`. |
| `modules/mb-image/png/encode_test.mbt` | Real eager Stored Gray8 output, rejection, and frozen legacy-vector tests. | ✓ VERIFIED | Exact Gray8 binary fixture checks IHDR values and atomic RGB rejection; established legacy vector tests remain in the same native run. |
| `modules/mb-image/png/stream_encode_test.mbt` | Real chunk Stored Gray8/eager identity, rejection, and frozen legacy-vector tests. | ✓ VERIFIED | Drains the new chunk encoder with ordinary capacity 17, compares eager bytes, and checks atomic rejection/budget/sentinel behavior. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `PngEncoder::new_gray8` | `PngEncodeMachine::new_with_profile` | `ImageEncoder::encode` carries the private profile into the shared machine. | ✓ WIRED | `new_gray8` stores `Gray8`; `encode` calls `new_with_profile` with that stored profile. |
| `PngChunkEncoder::new_gray8` | `PngEncodeMachine::new_with_profile` | Direct explicit construction with Gray8 + Stored/None/None. | ✓ WIRED | `stream_encode.mbt` calls the private machine constructor directly and returns an active encoder only after successful preflight. |
| `_png_encode_source` | Machine byte emission | Shared preflight returns profile/channels/row facts; machine uses them for traversal and IHDR. | ✓ WIRED | `facts.channels` supplies scanline traversal and `facts.profile` produces colour type 0 in `byte_at`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `stream_encode.mbt` | `facts.profile`, `facts.channels`, `facts.row_bytes` | Caller `ImageView` → `_png_encode_source` → profile-aware preflight | Image pixels are read by the Stored traversal; profile facts produce IHDR and source bytes produce zlib scanlines. | ✓ FLOWING |
| `encode_test.mbt` / `stream_encode_test.mbt` | Gray pixel `0x7f` | Constructed packed Gray U8 `OwnedImage` | Full native suite confirms exact eager bytes and caller-buffered replay identity. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Native PNG package regression suite | `moon -C modules/mb-image test png --target native --frozen` | `Total tests: 173, passed: 173, failed: 0.` | ✓ PASS |
| Standards conformance of the accepted eager Gray8 fixture | Python parser over the fixture asserted by the passing native test | Valid signature, IHDR, all PNG CRCs, zlib payload, and decoded `00 7f` scanline. | ✓ PASS |
| Phase-change integrity | `git diff --check 66a4c8e..HEAD` | No whitespace errors. | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — this phase declares no probe and is a MoonBit library implementation, not a migration or tooling phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| GRAYPNG-01 | `44-01-PLAN.md` | Explicit non-interlaced Gray8 eager/chunk factories while RGB8/RGBA8 bytes and behavior remain unchanged. | ✓ SATISFIED | Both public factories, real type-0/8-bit/non-interlaced output, rejection boundary, and native legacy regression coverage are present and pass. |

No orphaned Phase 44 requirements: `REQUIREMENTS.md` maps only `GRAYPNG-01` to this phase. Gray8 strategy expansion is explicitly owned by Phase 45 and broad four-target public evidence by Phase 46; neither is treated as missing Phase 44 work.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, empty implementation, or hardcoded-empty output path in phase-modified implementation/test files. | ℹ️ None | No blocker or warning. |

### Gaps Summary

None. The code—not merely the summary—implements and wires the narrow Stored Gray8 route, preserves legacy profile selection, and passes the requested native evidence.

---

_Verified: 2026-07-22T10:56:39Z_
_Verifier: the agent (gsd-verifier)_
