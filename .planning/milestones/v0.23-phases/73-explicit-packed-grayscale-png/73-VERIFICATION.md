---
phase: 73-explicit-packed-grayscale-png
verified: 2026-07-23T15:43:23Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 73: Explicit Packed Grayscale PNG Verification Report

**Phase Goal:** Library users can select lossless Type-0/1, Type-0/2, or Type-0/4 output from exactly representable canonical Gray/U8 source levels.
**Verified:** 2026-07-23T15:43:23Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can explicitly select eager Gray1, Gray2, or Gray4 output for a canonical opaque packed Gray/U8 image with exactly representable levels. | ✓ VERIFIED | `PngEncoder::new_gray1/2/4` are public eager-only constructors in `png.mbt:226-254`; profile admission in `encode.mbt:173-187` accepts only Gray/U8 without alpha, and `encode.mbt:70-92` maps only the specified exact levels. |
| 2 | Each new selector emits Stored, filter None, non-interlaced Type-0 PNG with IHDR depth 1, 2, or 4. | ✓ VERIFIED | Each selector fixes all three choices at `png.mbt:226-254`; `stream_encode.mbt:1302-1310` maps the profiles to colour type 0 and their profile depth. The public tests assert IHDR depth/type/interlace at `encode_test.mbt:1333-1335` and `1359-1371`. |
| 3 | Packed scanlines are MSB-first and deterministically zero unused final-byte lanes. | ✓ VERIFIED | The sole low-bit provider in `encode.mbt:541-563` starts each byte at zero, only visits in-range pixels, and uses the decoder-mirrored shift `8-depth-(start%8)`. The independent Stored-IDAT parser in `encode_test.mbt:594-646` checks literal odd-width rows `00 55 80`, `00 1b 00`, and `00 0f 10` at `1335`, `1361`, and `1371`. |
| 4 | A nonrepresentable selected level fails before eager output advances or a caller budget changes. | ✓ VERIFIED | `_png_encode_source` completes before planning and the only `budget.charge` (`encode.mbt:1746-1756`, `1935-1945`); eager writer progress begins only after machine creation (`1958-1978`). Tests for Gray1/2/4 assert the typed error, writer position zero, and unchanged bytes/allocations/work at `1342-1349`, `1376-1384`, and `1387-1395`. |
| 5 | Existing generic, Gray8, and Gray16 routes preserve their wire behavior. | ✓ VERIFIED | Commit `53bbfd5` changes the row-byte path only through `_png_profile_wire_row_bytes`, whose non-low-bit branch remains the original `width * channels` calculation (`encode.mbt:97-115`). Existing Gray8/Gray16 wire assertions remain in `encode_test.mbt:1304-1322`, `1399-1424`, and `2034-2068`; the provided mainline all-target run executed the complete package suite. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/png/png.mbt` | Explicit eager Gray1/2/4 selectors fixed to Stored/None/non-interlaced. | ✓ VERIFIED | Exists, substantive (24,858 bytes), and the selector profiles feed the `ImageEncoder` implementation. |
| `modules/mb-image/png/encode.mbt` | Exact-level admission, checked packed layout, and scalar MSB-first provider. | ✓ VERIFIED | Exists, substantive (76,449 bytes); exact-code, checked ceiling arithmetic, preflight, and wire-provider paths are implemented. |
| `modules/mb-image/png/stream_encode.mbt` | Profile-aware shared machine and Type-0 IHDR depths. | ✓ VERIFIED | Exists, substantive (53,404 bytes); the single `new_with_profile` constructor consumes preflight facts and `byte_at` emits the profile IHDR. |
| `modules/mb-image/png/encode_test.mbt` | Independent Stored-wire and atomic rejection coverage. | ✓ VERIFIED | Exists, substantive (113,059 bytes); parser is independent of production pack/decode helpers and public selector tests cover all three depths. |

`verify.artifacts` independently reported 4/4 artifacts present and substantive.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `png.mbt` | `encode.mbt` | `PngEncoder` profile → preflight → shared machine | ✓ WIRED | `ImageEncoder::encode` calls `PngEncodeMachine::new_with_profile` (`encode.mbt:1949-1963`), whose constructor calls profile-aware preflight (`stream_encode.mbt:767-781`). |
| `encode.mbt` | `stream_encode.mbt` | Preflight facts carrying profile and packed `row_bytes` into IHDR/IDAT traversal | ✓ WIRED | Preflight returns `profile` and `row_bytes` (`encode.mbt:1942-1945`); the one machine retains those facts and handles IHDR and IDAT. |
| `encode_test.mbt` | eager encoder public API | Public selectors checked through an independent Stored-block parser | ✓ WIRED | Tests instantiate only `PngEncoder::new_gray1/2/4` and compare parser output to literal expected scanlines. |

`verify.key-links` independently reported 3/3 critical links verified.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `encode.mbt` / `stream_encode.mbt` | packed `row_bytes`, profile, source sample codes | Caller `ImageView` → `_png_encode_source` → preflight facts → `PngEncodeMachine::byte_at` → eager writer | Yes — source bytes are read per visible pixel and emitted by the existing machine; no static raster or staging buffer is introduced. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Gray1/2/4 public wire format, atomic rejection, and legacy PNG regression across portable targets | `moon -C modules/mb-image test png --target all --frozen` | Mainline execution evidence supplied for this verification: native, js, wasm, and wasm-gc each passed 260/260. The test bodies were independently audited above; the command was not re-run here after the coordinator directed no duplicate long test. | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| GRAYPACK-01 | 73-01 | Explicit legal non-interlaced Type-0 depth 1/2/4 output with MSB-first samples and zero padding. | ✓ SATISFIED | Truths 1-3, all three public selector tests, independent Stored oracle, and all-target package evidence. |
| GRAYPACK-02 | 73-01 | Unsupported levels, descriptors, limits, and budgets fail atomically before eager output. | ✓ SATISFIED | Exact admission precedes all planner/budget/writer work; all-depth rejection tests check typed error, zero writer position, and all budget fields. |

No Phase 73 requirement is orphaned: both roadmap-mapped IDs are declared by `73-01-PLAN.md`.

### Anti-Patterns Found

No Phase-introduced `TBD`, `FIXME`, `XXX`, placeholder implementation, hard-coded empty output, or empty handler was found in the four changed source/test files. Two pre-existing prose uses of “not available” in `png.mbt` describe existing API boundaries and are not stubs or phase debt.

### Disconfirmation Pass

- **Partial-requirement check:** searched for low-bit `PngChunkEncoder` or strategy-taking factories; none exist. This preserves the Phase 73 eager-only scope rather than leaving a partial public transport.
- **Misleading-test check:** the wire assertions do not reuse encoder packing or decoder helpers; `png_encode_public_stored_scanlines` parses PNG chunks and Stored DEFLATE directly before literal-byte comparison.
- **Uncovered-error-path check:** descriptor/limit/budget failures retain the shared preflight’s existing error paths. The newly introduced nonrepresentable-level path is directly tested at every depth and is placed before the shared budget charge. No Phase 73-specific untested error path was found.

### Gaps Summary

None. All roadmap and plan must-haves are present, substantive, wired through the one bounded encoder machine, and covered by the cited four-target package execution.

---

_Verified: 2026-07-23T15:43:23Z_
_Verifier: the agent (gsd-verifier)_
