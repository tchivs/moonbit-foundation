---
phase: 09-checked-image-geometry-and-diagnostics
verified: 2026-07-20T07:53:48Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 9: Checked Image Geometry and Diagnostics Verification Report

**Phase Goal:** Library users can safely crop, reorient, and resize images through composable portable APIs that report invalid work deterministically.
**Verified:** 2026-07-20T07:53:48Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A caller can crop a supported image into an independent, tightly packed output without reading outside the requested stored-coordinate rectangle; invalid regions and resource limits fail as typed errors before charging. | ✓ VERIFIED | `crop` validates capability, emptiness, and checked `Rect` bounds before descriptor creation, charges once with `OwnedImage::new_operation`, then copies only `region.x/y + x/y` ([geometry.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/geometry.mbt:65)). Public and white-box tests prove tight/fresh output, invalid-dimension/range errors, endpoint overflow, all resource ceilings, and unchanged complete budget snapshots ([geometry_test.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/geometry_test.mbt:21), [geometry_wbtest.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/geometry_wbtest.mbt:73)). |
| 2 | A caller can flip horizontally/vertically and request explicit 90°, 180°, or 270° clockwise rotations with expected pixels and dimensions. | ✓ VERIFIED | Existing flip implementation remains substantive and is covered by exact permutation tests ([copy_flip.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/copy_flip.mbt:191), [copy_flip_test.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/copy_flip_test.mbt:153)). The three public rotation APIs map every RGB/RGBA coordinate directly and normalize physical output metadata to `TopLeft` ([geometry.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/geometry.mbt:170), [geometry_test.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/geometry_test.mbt:75)); an independent white-box oracle repeats the complete non-square mapping ([geometry_wbtest.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/geometry_wbtest.mbt:167)). |
| 3 | A caller can resize with the documented deterministic nearest-neighbor reference mapping and get the same result on every supported target. | ✓ VERIFIED | `resize_nearest` retains checked integer-floor source-indexing and bounded allocation/work accounting ([resize.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/resize.mbt:13), [resize.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/resize.mbt:85)). The two-dimensional, channel-by-channel regression independently computes the floor mapping ([resize_convert_wbtest.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/resize_convert_wbtest.mbt:110)). Full suite passed on js, wasm, wasm-gc, and native. |
| 4 | Unsupported formats and incompatible dimensions return typed, deterministic errors rather than conversion, out-of-bounds access, or partial budget mutation. | ✓ VERIFIED | Shared capability gate accepts only packed U8 encoded-sRGB RGB/RGBA ([copy_flip.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/copy_flip.mbt:54)); crop/rotation report `CapabilityUnavailable`, invalid crop regions report `InvalidDimensions`/`InvalidRange`, and resize zero axes/capability rejection have dedicated tests ([geometry_wbtest.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/geometry_wbtest.mbt:73), [resize_convert_wbtest.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/resize_convert_wbtest.mbt:134)). |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `modules/mb-image/ops/geometry.mbt` | Checked public crop and named rotations | ✓ VERIFIED | Exists, substantive (286 lines of validation/allocation/mapping logic), exported by the compiled `ops` package, and exercised by public plus white-box tests. |
| `modules/mb-image/ops/geometry_test.mbt` | Public output, metadata, mapping, and diagnostic tests | ✓ VERIFIED | Exists, substantive, and included in all four successful package test executions. |
| `modules/mb-image/ops/geometry_wbtest.mbt` | Boundary, capability, coordinate-oracle, and atomic-budget evidence | ✓ VERIFIED | Exists, substantive (199 lines); its full-budget and all-resource-limit assertions execute in the four-target suite. |
| `modules/mb-image/ops/resize_convert_wbtest.mbt` | Deterministic nearest-neighbor regression | ✓ VERIFIED | Exists, substantive, calls both `nearest_source_index` and `resize_nearest`, and verifies a 3×2-to-5×4 channel mapping. |
| `modules/mb-image/README.mbt.md` | Four-target public geometry/resize contract | ✓ VERIFIED | Documents borrowed vs owned crop, capability/error policy, named rotations, `TopLeft` normalization, and the floor formula; checked successfully on all four targets. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `geometry.mbt` | `storage/owned_image.mbt` | Validated tight descriptor → one `OwnedImage::new_operation` charge → `with_mut_view` | ✓ WIRED | Both crop and rotations allocate through the authoritative atomic operation boundary before writes ([geometry.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/geometry.mbt:101), [geometry.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/geometry.mbt:161)). |
| `geometry.mbt` | `copy_flip.mbt` | Shared capability/error/result/disposition helpers | ✓ WIRED | `supports_copy_flip`, `operation_error`, `ImageOperationResult`, and `preserve_all_disposition` are directly used; compiler and all targets accept package-private wiring. |
| `README.mbt.md` | `geometry.mbt` | Checked public example invokes owned crop and explicit rotation with caller budget | ✓ WIRED | Example calls `@ops.crop` and `@ops.rotate_90` ([README.mbt.md](/D:/source/moonbit-foundation/modules/mb-image/README.mbt.md:194)); its text documents all three named rotations ([README.mbt.md](/D:/source/moonbit-foundation/modules/mb-image/README.mbt.md:173)). The automated key-link query missed this due to the PLAN's double-escaped regex, not missing code. |
| `resize_convert_wbtest.mbt` | `resize.mbt` | Independent reference test calls existing resize/index implementation | ✓ WIRED | Tests invoke both symbols ([resize_convert_wbtest.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/resize_convert_wbtest.mbt:101), [resize_convert_wbtest.mbt](/D:/source/moonbit-foundation/modules/mb-image/ops/resize_convert_wbtest.mbt:115)). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `geometry.mbt` crop | Destination channel byte | `source.get_byte(region.x()+x, region.y()+y, channel)` → `destination.set_byte` | Caller-provided `ImageView` bytes, not hardcoded/static data | ✓ FLOWING |
| `geometry.mbt` rotations | Destination channel byte | `source.get_byte(source_x, source_y, channel)` → mapped destination coordinate | Caller-provided `ImageView` bytes for each source coordinate | ✓ FLOWING |
| `resize.mbt` | Destination channel byte | Checked nearest source indices → `source.get_byte` → `destination.set_byte` | Caller-provided `ImageView` bytes; mapping independently asserted | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Geometry, flip, resize, diagnostics, and adversarial invariants on js | `moon test modules/mb-image/ops --target js` | 28 passed, 0 failed | ✓ PASS |
| Same portable behavior on wasm | `moon test modules/mb-image/ops --target wasm` | 28 passed, 0 failed | ✓ PASS |
| Same portable behavior on wasm-gc | `moon test modules/mb-image/ops --target wasm-gc` | 28 passed, 0 failed | ✓ PASS |
| Same portable behavior on native | `moon test modules/mb-image/ops --target native` | 28 passed, 0 failed | ✓ PASS |
| Public documentation examples | `moon -C modules/mb-image check README.mbt.md --target js|wasm|wasm-gc|native --frozen` | All four commands exited 0 | ✓ PASS |

### Probe Execution

SKIPPED — Phase 9 declares no probe and contains no conventional `scripts/*/tests/probe-*.sh` probe.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| GEOM-01 | 09-01 | Checked rectangular crop without out-of-bounds access or overflow-driven allocation | ✓ SATISFIED | Truth 1; checked `Rect`, source-bound validation, checked descriptor arithmetic, atomic owned allocation, public/white-box tests. |
| GEOM-02 | 09-01 | Horizontal/vertical flip and right-angle rotation preserving pixels | ✓ SATISFIED | Truth 2; unchanged flip tests plus direct 90/180/270 coordinate-oracle tests. |
| GEOM-03 | 09-02 | Deterministic documented nearest-neighbor resize across supported targets | ✓ SATISFIED | Truth 3; implementation/reference regression plus four target suite and README checks. |
| RASTER-03 | 09-01 | Typed deterministic unsupported-format, invalid-region, incompatible-dimension, and resource-limit errors | ✓ SATISFIED | Truth 4; exact CoreError tests and atomic complete-budget-snapshot tests. |

No orphaned Phase 9 requirements: all four mapped IDs appear in Phase 9 plan frontmatter.

### Anti-Patterns Found

No blocker or warning anti-patterns found. The phase-modified implementation, tests, and README contain no `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, placeholder, or empty-implementation marker. Phase commits modify only planned source/test/documentation and planning artifacts; no release script, workflow, registry artifact, or generated vector table was added.

### Disconfirmation Checks

- **Partial-requirement check:** the test suite contains direct behavior assertions for crop freshness/tightness, all three rotations, preserved flip behavior, resize mapping, all stated typed error classes, and all resource ceilings; no partial Phase 9 criterion remained.
- **Misleading-test check:** rotation tests use an independent source-to-destination oracle rather than merely comparing one implementation route to another; resize tests independently calculate the two-dimensional floor indices.
- **Uncovered-error-path check:** crop endpoint overflow is correctly tested at `Rect::new`, where it is constructible; source-outside/empty rectangle errors, capability variants, zero resize axes, and resource rejection are separately tested. No observable Phase 9 error path was untested.

### Gaps Summary

None. All Phase 9 roadmap success criteria and GEOM-01, GEOM-02, GEOM-03, and RASTER-03 are evidenced by substantive, wired implementation plus passing behavioral tests on js, wasm, wasm-gc, and native.

---

_Verified: 2026-07-20T07:53:48Z_
_Verifier: the agent (gsd-verifier)_
