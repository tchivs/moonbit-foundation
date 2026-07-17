---
phase: 04-image-model-views-and-operations
plan: "02"
subsystem: image-model
tags: [moonbit, image-descriptor, planes, orientation, checked-arithmetic]

requires:
  - phase: 02-bounded-core-primitives
    provides: Checked UInt64 arithmetic, dimensions, and half-open ranges
  - phase: 03-reference-color-semantics
    provides: Explicit sRGB, transfer, alpha, and profile identities
  - phase: 04-image-model-views-and-operations/04-01
    provides: Bounded canonical opaque metadata
provides:
  - Closed explicit packed and planar image format vocabulary
  - Checked descriptor validation for dimensions, rows, planes, storage, and overlap
  - Eight neutral EXIF-style orientations and checked half-open rectangles
  - Image metadata composition and closed reference-operation support classification
affects: [04-image-model-views-and-operations, image-storage, image-operations, codec-contracts]

tech-stack:
  added: []
  patterns:
    - Full-width checked descriptor validation before any storage access or allocation
    - Closed general model with deliberately narrower reference-operation support

key-files:
  created:
    - modules/mb-image/model/descriptor.mbt
    - modules/mb-image/model/model_test.mbt
    - modules/mb-image/model/model_wbtest.mbt
    - modules/mb-image/model/moon.pkg
  modified:
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1

key-decisions:
  - "Represent component type, channel order, plane layout, endianness, orientation, and every plane range as closed inspectable values while keeping constructors opaque and validated."
  - "Permit the model to describe packed or planar U8/U16/F32 data, but classify only encoded-sRGB packed U8 RGB and alpha-explicit RGBA as supported by Phase 4 reference operations."
  - "Treat the declared half-open plane range as the alias boundary: padded rows are valid, touching planes are valid, and any overlap or storage escape rejects."

patterns-established:
  - "Descriptor validation order: positive dimensions, checked pixel count, plane count, alpha identity, checked row shape, storage containment, then pairwise disjointness."
  - "Orientation identity remains metadata; display dimensions swap only for orientation codes 5 through 8."

requirements-completed: [IMAG-01, IMAG-02, IMAG-06]

coverage:
  - id: D1
    description: Every packed or planar image descriptor exposes explicit storage, color, alpha, profile, orientation, and metadata identities.
    requirement: IMAG-01
    verification:
      - kind: unit
        ref: "modules/mb-image/model/model_test.mbt; moon -C modules/mb-image test model --target all --frozen (11/11 per target)"
        status: pass
    human_judgment: false
  - id: D2
    description: Invalid dimensions, arithmetic, row shape, plane count, storage containment, and overlap reject before access or allocation.
    requirement: IMAG-02
    verification:
      - kind: unit
        ref: "modules/mb-image/model/model_wbtest.mbt; moon -C modules/mb-image test model --target all --frozen (11/11 per target)"
        status: pass
    human_judgment: false
  - id: D3
    description: Image metadata retains explicit color/profile/alpha/orientation identity and the bounded opaque metadata value from Plan 04-01.
    requirement: IMAG-06
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 19min
completed: 2026-07-17
status: complete
---

# Phase 4 Plan 2: Explicit Validated Image Model Summary

**Opaque image descriptors now expose packed or planar U8/U16/F32 topology, checked disjoint plane ranges, explicit color metadata, and all eight neutral orientation states**

## Performance

- **Duration:** 19 min
- **Started:** 2026-07-17T04:46:30+08:00
- **Completed:** 2026-07-17T05:05:33+08:00
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added a closed, inspectable image format and metadata model covering component storage, channels, layout, byte order, color/transfer/profile/alpha identity, orientation, and opaque metadata.
- Added checked constructors that reject zero owned-image axes, overflow, invalid plane shapes, short rows/ranges, wrong plane counts, storage escape, and pairwise overlap while accepting padding and touching ranges.
- Registered the model after metadata with an exact 92-line semantic interface, publication allowlist, portable targets, and dependency policy.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add failing image model contracts** - `6510a0a` (test)
2. **Task 1 GREEN: Implement validated image descriptors** - `e7058c6` (feat)
3. **Task 2: Register image model topology** - `15a4e88` (chore)

## Files Created/Modified

- `modules/mb-image/model/descriptor.mbt` - Closed format, plane, orientation, rectangle, metadata, and validated descriptor contracts.
- `modules/mb-image/model/model_test.mbt` - Public explicit-identity, supported-format, orientation, and rectangle behavior.
- `modules/mb-image/model/model_wbtest.mbt` - Arithmetic, range, stride, storage, overlap, touching-range, and alpha-identity adversarial coverage.
- `modules/mb-image/model/moon.pkg` - Exact portable package imports and four-target declaration.
- `policy/foundation.json` - Model publication inventory, imports, targets, and 92-line semantic interface.
- `scripts/quality/Assert-Policy.ps1` - Pinned MoonBit `@alias` import recognition in exact dependency classification.

## Decisions Made

- Kept layout vocabulary broad enough for packed and planar U8/U16/F32 descriptors while making operation support an explicit narrow predicate rather than an inferred promise.
- Required RGBA descriptors to carry a straight or premultiplied `mb-color` alpha identity and required non-alpha channel orders to carry none.
- Used each plane's complete declared half-open byte range for containment and overlap proofs so padding cannot become an undocumented alias channel.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Recognized pinned MoonBit block-import aliases in policy classification**
- **Found during:** Task 2 (Freeze model topology)
- **Issue:** The pinned toolchain accepts `"package" @alias`, but `Get-PackageImportSet` only recognized an unsupported `as name` spelling and rejected the model's necessary color-model alias.
- **Fix:** Extended both single and block import classifiers to accept `@alias` while preserving exact package-name extraction and existing syntax checks.
- **Files modified:** `scripts/quality/Assert-Policy.ps1`
- **Verification:** The Foundation policy stage classified the real `@color` import and Required passed through exact DAG, interface, publication, and read-only gates.
- **Committed in:** `15a4e88`

---

**Total deviations:** 1 auto-fixed (1 blocking issue).
**Impact on plan:** The fix only teaches policy classification the pinned toolchain's valid alias grammar; it adds no product scope or dependency.

## Issues Encountered

- The first full Required run reached the final read-only proof while the intended policy edits were still uncommitted; after the atomic Task 2 commit, the identical Required lane passed.

## User Setup Required

None - no external service configuration required.

## Verification

- `moon -C modules/mb-image check --target all --deny-warn --frozen`: passed on js, wasm, wasm-gc, and native.
- `moon -C modules/mb-image test model --target all --frozen`: 11/11 passed independently on js, wasm, wasm-gc, and native.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required`: passed, including 131/131 workspace tests per target, exact 92-line model interface, package allowlist, DAG, and read-only proof.

## Self-Check: PASSED

- All six planned or deviation files exist.
- Commits `6510a0a`, `e7058c6`, and `15a4e88` resolve in repository history.
- No known stubs or new network, host, filesystem, authentication, or schema threat surface was introduced.

## Next Phase Readiness

- The validated descriptor is ready for Plan 04-03 owned storage and retained view contracts.
- No blockers remain for Plan 04-03.

---
*Phase: 04-image-model-views-and-operations*
*Completed: 2026-07-17*
