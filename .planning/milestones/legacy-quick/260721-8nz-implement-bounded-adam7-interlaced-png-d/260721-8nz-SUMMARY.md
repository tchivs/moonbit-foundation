---
quick_id: 260721-8nz
phase: quick-260721-8nz
plan: 01
subsystem: png-decode
tags: [moonbit, png, adam7, interlace, rgba8, rgb8, deflate, fixtures]
requires:
  - quick: 260721-81r
    provides: bounded all-profile non-interlaced PNG decode semantics
provides:
  - bounded Adam7 decode for every supported eager PNG profile into RGB8 or straight RGBA8
  - independent seven-pass fixture oracle and portable split-boundary evidence
affects: [png-decode, portable-conformance]
key-decisions:
  - "Keep Adam7 entirely private to the eager decoder; no public streaming or encode API was added."
  - "Filter packed/encoded source rows per pass, then scatter into the existing RGB8/RGBA8 mapping."
  - "Reserve exactly image plus two maximum-pass rows, including indexed inputs."
requirements-completed: [PNGX-01]
completed: 2026-07-21
status: complete
---

# Quick Task 260721-8nz Summary

**The eager PNG decoder now supports bounded Adam7 interlacing across all of its supported grayscale, indexed, truecolour, grayscale-alpha, and RGBA profiles.**

## Accomplishments

- Added checked seven-pass Adam7 geometry, exact pass-filter accounting, reusable source rows, pass-local inverse filtering, and full-image scatter.
- Preserved raw PLTE/tRNS semantics, including low-bit packed samples and 16-bit transparency comparisons before high-byte RGB8/RGBA8 projection.
- Fixed two evidence-driven defects: completed interlaced streams incorrectly failed the non-interlaced terminal-row check, and indexed Adam7 allocated redundant non-interlaced rows.
- Added an independent PowerShell Adam7 oracle plus **3,738** generated vectors. Accepted vectors cover every supported profile/depth/transparency combination and every nonempty contiguous two-IDAT split; hostile vectors cover layout, resource, PLTE, tRNS, and malformed-compression failures.

## Verification

- Passed `pwsh -NoProfile -File ./scripts/fixtures/Generate-PngDecodeVectors.ps1 -Check` (3,738 vectors).
- Passed `moon -C modules/mb-image test png --target all --frozen` (34/34 on wasm, wasm-gc, js, native).
- Passed `pwsh -NoProfile -File ./scripts/quality/Invoke-MoonQuality.ps1 -Lane Png`.
- `moon -C modules/mb-image check --target all --deny-warn --frozen` remains blocked by 26 pre-existing `unused_field` diagnostics in generated structural vectors and legacy transport fields; no Adam7 diagnostic is reported.

## Scope

No release, registry, colour-management, PNG encoder, public resumable-streaming, QOI, or configuration work was added.

## Task Commits

- Core implementation: `de139b5`
- Independent oracle: `040705e`
- Evidence-driven decoder fixes: `ff682a3`, `a2ce54f`
- Profile and hostile corpus: `f2f1888` through `e9669ef`

