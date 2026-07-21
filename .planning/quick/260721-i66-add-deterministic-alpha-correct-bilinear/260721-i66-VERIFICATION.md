---
phase: quick-260721-i66
verified: 2026-07-21T05:49:00Z
status: passed
score: 10/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 8/10
  gaps_closed:
    - "A requested resize requiring an unavailable non-sRGB colour transform returns Capability/CapabilityUnavailable with the bilinear operation/context and no Budget charge."
    - "Opaque RGB8/RGBA 1×1 identity and RGB/RGBA interpolation parity have executable public vectors."
  gaps_remaining: []
  regressions: []
---

# Quick 260721-i66: Deterministic Alpha-Correct Bilinear Verification Report

**Goal:** Deterministic alpha-correct `resize_bilinear` for portable RGB8 and straight-RGBA8 with checked limits and atomic budgets, without changing nearest.

**Verified:** 2026-07-21T05:49:00Z  
**Status:** passed  
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Public bilinear API is usable from the `ops` package. | ✓ VERIFIED | `pub fn resize_bilinear` is in `modules/mb-image/ops/resize.mbt:249`; public tests and the executable README call `@ops.resize_bilinear`. |
| 2 | Coordinates retain nearest's integer base mapping and safely clamp the high neighbour. | ✓ VERIFIED | Checked product, quotient/remainder, and high-only clamp are implemented in `bilinear_source_coordinate` (`resize.mbt:177-199`); white-box vectors prove 0/3, 2/3, final edge, and 2→1 cases (`resize_convert_wbtest.mbt:307-318`). |
| 3 | RGB8 and fully opaque straight-RGBA8 retain byte identity/parity. | ✓ VERIFIED | New public vector tests a `1×1` `[12,34,56]` RGB8 and opaque RGBA source at 1×1, 2×3, and 4×2, comparing every byte; a distinct 2×2→3×4 vector compares every interpolated RGB byte and asserts alpha 255 (`resize_convert_test.mbt:250-325`). All four target runs pass it. |
| 4 | Straight RGBA interpolation is linear-light and premultiplied, preventing transparent-colour fringes. | ✓ VERIFIED | Decode/premultiply occurs before four-tap blend, followed by unpremultiply only during store (`processing.mbt:70-134`, `resize.mbt:204-224`). The public transparent-red vector produces RGB zero and alpha 170. |
| 5 | Alpha that quantizes to zero is canonical transparent black, including the quantization boundary. | ✓ VERIFIED | `store_linear_premultiplied` quantizes alpha before its zero branch (`processing.mbt:113-120`); the `[255,0,0,1]` regression asserts all four middle bytes are zero (`resize_convert_test.mbt:347-357`). |
| 6 | Bilinear fails closed for unsupported packed formats, alpha representation, transfer, colour space, and profile. | ✓ VERIFIED | Acceptance is restricted to packed-U8 RGB/no-alpha or straight-RGBA plus encoded sRGB space/transfer and builtin profile (`resize.mbt:201-247`). Format and metadata rejections are tested with complete Budget snapshots unchanged. |
| 7 | An unavailable non-sRGB colour transform returns the typed PNGCM-04 capability result. | ✓ VERIFIED | Metadata rejection now explicitly returns `ErrorCategory::Capability` and `ErrorCode::CapabilityUnavailable` with `image-resize-bilinear` / `image-resize-bilinear-metadata` (`resize.mbt:276-284`). White-box tests assert category, code, operation, context, and atomic budgets for both linear-sRGB and custom ICC profile inputs (`resize_convert_wbtest.mbt:385-426`). |
| 8 | Empty source, descriptor/coordinate overflow, and all resource boundaries fail before a partial Budget charge. | ✓ VERIFIED | Empty source is rejected before format/metadata/descriptor work (`resize.mbt:255-265`); checked descriptor/tap/work arithmetic precedes the sole `OwnedImage::new_operation` (`resize.mbt:286-310`). Tests compare all eight remaining Budget fields for empty, overflow, and every output-limit boundary (`resize_convert_wbtest.mbt:363-464`). |
| 9 | `resize_nearest` retains its established contract. | ✓ VERIFIED | Across `c12ae92`, `58947ba`, and `6411680`, nearest's logic is unchanged except the explicit existing operation argument to shared descriptor construction; its mapping and atomicity tests remain in the passing ops suite. |
| 10 | Exact operations vectors and executable README contract pass on js, wasm, wasm-gc, and native. | ✓ VERIFIED | Independently ran all eight prescribed commands: each ops suite reports 47/47 passed; each README check exits 0. |

**Score:** 10/10 truths verified (0 present but behavior-unverified).

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/ops/resize.mbt` | Public checked resize, correct capability gate, and one authoritative allocation | ✓ VERIFIED | Substantive public operation; checked coordinate/work preflight and one `new_operation` call. |
| `modules/mb-image/ops/processing.mbt` | Shared linear-premultiplied RGB8/RGBA helpers | ✓ VERIFIED | Shared sRGB decode/premultiply/store paths with quantized-alpha transparent-black canonicalization. |
| `modules/mb-image/ops/resize_convert_test.mbt` | Public exact RGB8/RGBA vectors | ✓ VERIFIED | Covers linear-light 213, transparent fringe prevention, quantization-to-zero, opaque identity, and interpolation parity. |
| `modules/mb-image/ops/resize_convert_wbtest.mbt` | Coordinates and atomic rejection evidence | ✓ VERIFIED | Covers coordinates, typed metadata/format rejection, custom profile, overflow, and all remaining Budget fields. |
| `modules/mb-image/README.mbt.md` | Executable public contract and target matrix | ✓ VERIFIED | Documents supported formats, coordinate/alpha semantics, bounds, nearest separation, and all four target commands. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `resize.mbt` | `processing.mbt` | Four taps flow through shared linear-premultiplied conversion/store helpers | ✓ WIRED | `resize_bilinear` selects RGB8/RGBA loaders and matching stores; no encoded-byte interpolation path exists. |
| `resize.mbt` | `storage/owned_image.mbt` | Checked descriptor/work reaches one authoritative allocation | ✓ WIRED | Checked `pixels * 4` is passed once to `OwnedImage::new_operation`, which receives storage length, dimensions, pixels, and work. |
| Tests | `resize.mbt` | Public vectors and white-box rejection tests exercise the API | ✓ WIRED | `resize_convert_test.mbt` uses `@ops.resize_bilinear`; white-box tests cover private coordinate logic and typed atomic rejection. |

## Data-Flow Trace

| Artifact | Data variable | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| `resize_bilinear` | Four source taps → premultiplied interpolant → destination bytes | Caller `ImageView.get_byte` values | Yes | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Ops vectors | `moon test --target js modules/mb-image/ops` | 47 passed, 0 failed | ✓ PASS |
| Ops vectors | `moon test --target wasm modules/mb-image/ops` | 47 passed, 0 failed | ✓ PASS |
| Ops vectors | `moon test --target wasm-gc modules/mb-image/ops` | 47 passed, 0 failed | ✓ PASS |
| Ops vectors | `moon test --target native modules/mb-image/ops` | 47 passed, 0 failed | ✓ PASS |
| README contract | `moon -C modules/mb-image check README.mbt.md --target js` | exit 0 | ✓ PASS |
| README contract | `moon -C modules/mb-image check README.mbt.md --target wasm` | exit 0 | ✓ PASS |
| README contract | `moon -C modules/mb-image check README.mbt.md --target wasm-gc` | exit 0 | ✓ PASS |
| README contract | `moon -C modules/mb-image check README.mbt.md --target native` | exit 0 (Moon runtime unused-value warnings only) | ✓ PASS |

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PNGCM-04 | `260721-i66-PLAN.md` | Requested operation needing unavailable colour transform/discarding non-sRGB semantics receives a typed capability result. | ✓ SATISFIED | The metadata gate and two white-box inputs assert `Capability/CapabilityUnavailable`, exact operation/context, and unchanged full Budget snapshots. |

## Anti-Patterns Found

No `TBD`, `FIXME`, `XXX`, placeholder, empty-output, or hardcoded-empty-data markers appear in the five task files. The three task commits (`c12ae92`, `58947ba`, `6411680`) modify only planned bilinear/docs/test files; they do not alter QOI, codecs, FFI, or release scripts.

## Re-verification Result

`6411680` closes both prior findings without introducing a regression. The former metadata-category mismatch is now covered by direct white-box assertions, while the former identity/parity evidence gap is covered by public vectors executed on all four portable targets.

_Verified: 2026-07-21T05:49:00Z_  
_Verifier: the agent (gsd-verifier)_
