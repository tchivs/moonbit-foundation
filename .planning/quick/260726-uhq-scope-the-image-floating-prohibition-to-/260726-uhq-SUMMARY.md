---
phase: quick-260726-uhq
plan: 01
subsystem: quality
tags: [moonbit, image, floating-point, policy, qualification]
requires:
  - phase: 10-alpha-correct-pixel-processing
    provides: Typed linear-premultiplied pixel processing and box-blur color averaging
  - phase: legacy-quick-260721-i66
    provides: Checked integer bilinear geometry with bounded blend fractions
provides:
  - Exact fail-closed floating-point inventory for mb-image production operations
  - No-Lane image floating-policy self-test using the production policy seams
affects: [release-qualification, mb-image, geometry-policy]
tech-stack:
  added: []
  patterns:
    - Remove exact audited forms before rejecting residual floating tokens
key-files:
  created:
    - .planning/quick/260726-uhq-scope-the-image-floating-prohibition-to-/260726-uhq-SUMMARY.md
  modified:
    - scripts/quality/Invoke-MoonQuality.ps1
key-decisions:
  - "Floating point remains prohibited for image geometry and indexing; only exact typed color math and checked-remainder blend fractions are admitted."
  - "Every admitted form is anchored, cardinality-checked, and bound to its canonical file and function."
patterns-established:
  - "Audited exceptions are removed from a copy of production source before residual Double, to_double, and decimal/exponent scanning."
requirements-completed: []
coverage:
  - id: D1
    description: Exact audited image floating-point policy rejects inventory drift and floating geometry
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality/Invoke-MoonQuality.ps1 -ImageFloatingPolicySelfTest"
        status: pass
    human_judgment: false
  - id: D2
    description: Existing image operations remain unchanged and portable across all supported targets
    verification:
      - kind: integration
        ref: "moon -C modules/mb-image test ops --target {js,wasm,wasm-gc,native} --frozen"
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-07-26
status: complete
---

# Quick 260726-uhq: Image Floating Policy Summary

**Exact source-form whitelisting now permits verified typed color and bilinear blend math while floating geometry, indexing, rounding, and inventory drift fail closed.**

## Accomplishments

- Replaced the stale file-wide floating regex with `Assert-ImageOpsFloatingPolicy`, including canonical path, function, form, and cardinality checks.
- Added `-ImageFloatingPolicySelfTest`, which runs without `-Lane` and verifies focused positives, identifier boundaries, all required negative spellings, the live portable-source prohibition, and the existing image negative matrix.
- Kept all image implementation sources unchanged and verified 48 ops tests on each of js, wasm, wasm-gc, and native.

## Exact Admitted Inventory

`modules/mb-image/ops/processing.mbt` admits only:

- One `NormalizedAlpha::new(1.0)` opaque-alpha construction in `load_linear_premultiplied_rgb8`.
- One `let factor = 1.0 - sa` in `composite_source_over`.
- One Rec.709 luminance expression containing `0.2126`, `0.7152`, and `0.0722` in `grayscale`.
- One each of `rr`, `gg`, `bb`, and `aa` initialized to `0.0` in `box_blur`.
- One each of the typed `rr`, `gg`, `bb`, and `aa` divisions by `window.to_double()` in `box_blur`.

`modules/mb-image/ops/resize.mbt` admits only:

- One private `x_fraction : Double` and one private `y_fraction : Double` in `bilinear_interpolate`.
- One `remainder_y.to_double() / height.to_double()` and one `remainder_x.to_double() / width.to_double()` in `resize_bilinear`.

All other ops source, and every residual token in these two canonical files, rejects `Double`, `.to_double(`, decimal or exponent literals, and `round`, `floor`, or `ceil` calls. Public operation declarations reject `Double` explicitly.

## Locked Rationale

Phase 10 established typed linear-premultiplied color arithmetic, including box-window averaging. Legacy quick i66 established checked integer multiplication, division, quotient, and remainder for bilinear geometry, with conversion only after bounded integer remainder facts exist. This policy preserves both decisions: floating values can blend typed color values but cannot select coordinates, indexes, or extents.

## Verification Evidence

- Image floating-policy self-test: PASS, including exact marker `Image floating policy self-test passed.`
- Live image portable prohibition: PASS.
- Existing image qualification negative matrix: PASS.
- Core narrowing self-test dispatch regression check: PASS.
- mb-image ops js: 48 passed, 0 failed.
- mb-image ops wasm: 48 passed, 0 failed.
- mb-image ops wasm-gc: 48 passed, 0 failed.
- mb-image ops native: 48 passed, 0 failed.
- `git diff --check`: PASS.

## Task Commit

- `d0afa0e` — `fix(260726-uhq): scope image floating policy inventory`

The source commit changes only `scripts/quality/Invoke-MoonQuality.ps1`. No image implementation source changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Plan inventory mismatch] Bound opaque alpha to the actual helper**

- **Found during:** Focused policy self-test against production source.
- **Issue:** The plan named `load_linear_premultiplied`, but the audited `NormalizedAlpha::new(1.0)` form is in `load_linear_premultiplied_rgb8`.
- **Fix:** Bound the exact form to the function that owns it in production.
- **Verification:** Live portable-source prohibition passes.
- **Committed in:** `d0afa0e`

**2. [Rule 3 - Blocking stale assertion] Refreshed the mutable-view gate name**

- **Found during:** Mandated production portable-prohibition seam.
- **Issue:** The quality script still expected `require_packed_u8_view`, while the production contract now uses `require_packed_u8_or_u16_view`.
- **Fix:** Updated the existing order assertion to the current gate name.
- **Verification:** Live portable-source prohibition and its removed-gate negative fixture pass.
- **Committed in:** `d0afa0e`

**3. [Rule 3 - Blocking stale assertion] Refreshed the README phrase**

- **Found during:** Mandated production portable-prohibition seam.
- **Issue:** The README contract now explicitly says nearest resize performs no filtering, interpolation, hidden color conversion, or alpha processing.
- **Fix:** Updated the exact quality assertion to include `interpolation`.
- **Verification:** Live README contract and missing-statement negative fixture pass.
- **Committed in:** `d0afa0e`

**Total deviations:** 3 auto-fixed (1 plan inventory correction, 2 blocking stale assertions). All changes remain confined to the owned quality script.

## Known Stubs

None.

## Self-Check: PASSED

- Source commit `d0afa0e` exists and contains exactly one modified file.
- All declared verification commands passed.
- The only remaining worktree artifact is this untracked SUMMARY.

---
*Quick: 260726-uhq*
*Completed: 2026-07-26*
