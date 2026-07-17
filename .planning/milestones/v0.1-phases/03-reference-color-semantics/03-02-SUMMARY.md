---
phase: 03-reference-color-semantics
plan: "02"
subsystem: color-fixtures
tags: [powershell, srgb, provenance, deterministic-generation, moonbit]

requires:
  - phase: 03-reference-color-semantics
    provides: explicit validated color model and exact transitional package policy
provides:
  - primary-formula-derived sRGB transfer evidence with exact source and digest records
  - separate repository-derived quantization, alpha, profile, and adversarial evidence
  - selective byte-stable package-local MoonBit vector generation without runtime file access
affects: [03-transfer, 03-quantize, 03-alpha, 03-profile, fixture-policy]

tech-stack:
  added: []
  patterns: [canonical in-memory evidence dataset, byte-for-byte check mode, package-local generated test constants]

key-files:
  created:
    - scripts/fixtures/Generate-ColorVectors.ps1
    - fixtures/color/srgb-reference-vectors.json
    - fixtures/color/derived-edge-vectors.json
  modified:
    - fixtures/manifest.json

key-decisions:
  - "Generate standards-formula-derived and repository-derived evidence from one canonical in-memory dataset while keeping their provenance claims separate."
  - "Make each package selector own exactly one reference_vectors_wbtest.mbt output; portable MoonBit tests consume constants and never access the fixture filesystem."
  - "Treat -Check as a byte-for-byte comparison over UTF-8 without BOM and LF endings, including regenerated manifest digests."

patterns-established:
  - "Selective fixture generation: fixtures updates only two JSON artifacts plus their manifest records; transfer, quantize, alpha, and profile each update one package-local test table."
  - "Honest provenance: primary URLs identify formulas, project-authored derived cases are explicitly non-official, and no external bytes are relabeled."

requirements-completed: [COLR-04]

coverage:
  - id: D1
    description: "Deterministic separate sRGB formula-derived and project-derived adversarial fixture classes with actual SHA-256 provenance records"
    requirement: COLR-04
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts fixtures -Check"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality/Test-FixturePolicy.ps1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Selective package-local MoonBit vector outputs for transfer, quantize, alpha, and profile with no runtime filesystem dependency"
    requirement: COLR-04
    verification:
      - kind: integration
        ref: "selector-map isolation check for modules/mb-color/{transfer,quantize,alpha,profile}/reference_vectors_wbtest.mbt"
        status: pass
    human_judgment: false
  - id: D3
    description: "Existing missing-file, digest, traversal, date, redistribution, and symlink provenance failures remain fail closed under the full Required lane"
    requirement: COLR-04
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 18min
completed: 2026-07-17
status: complete
---

# Phase 03 Plan 02: Deterministic Color Evidence Summary

**One canonical generator now produces byte-stable, provenance-recorded color evidence and isolated filesystem-free MoonBit test tables**

## Performance

- **Duration:** 18 min
- **Started:** 2026-07-16T17:43:00Z
- **Completed:** 2026-07-16T18:01:21Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added primary-formula-derived sRGB endpoint, threshold, adjacent-value, and sample conversion vectors without copying third-party fixture bytes.
- Added a separately labeled project-derived dataset covering ties-to-even quantization, ratio rounding, encoded alpha boundaries, and opaque-profile tag/limit cases.
- Added selective generation and byte-for-byte check modes, registered actual digests, and retained the complete fail-closed provenance and Required qualification matrix.

## Task Commits

1. **Task 1: Generate and register honest reference evidence** - `622c7fa` (feat)
2. **Task 2: Prove fixture provenance remains fail closed** - `6088a44` (test)

## Files Created/Modified

- `scripts/fixtures/Generate-ColorVectors.ps1` - Canonical invariant-culture generator for fixtures and isolated package-local MoonBit tables.
- `fixtures/color/srgb-reference-vectors.json` - Published-formula-derived sRGB conversion evidence with explicit formula sources.
- `fixtures/color/derived-edge-vectors.json` - Project-authored quantization, ratio, alpha, profile, and adversarial evidence.
- `fixtures/manifest.json` - Complete provenance, retrieval date, license, redistribution, use, and actual digest records.

## Decisions Made

- The generator computes all outputs from one canonical data graph, but serializes standards-formula-derived and repository-derived cases into separate artifacts so neither provenance claim overreaches.
- `fixtures` owns only repository evidence and manifest digests; each package selector owns exactly one future `reference_vectors_wbtest.mbt`, preserving sequential package delivery.
- Check mode never writes: it computes expected bytes and fails on a missing or byte-different artifact.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Initial PowerShell portability probes exposed parser and byte-array comparison differences; the generator was corrected to use valid switch syntax and an explicit byte loop before any task commit.

## User Setup Required

None - no external services, packages, or manual configuration are required.

## Known Stubs

None.

## Threat Flags

None. The planned generator is repository-local, uses contained fixed output paths, performs no network access, and its package outputs contain constants only.

## Next Phase Readiness

- Plan 03-03 can generate and consume the transfer table from the registered sRGB dataset.
- Plans 03-04 through 03-06 can generate their own single package-local tables from the same derived dataset without adding runtime file or host capabilities.

## Self-Check: PASSED

- All four implementation/evidence files and this summary exist.
- Task commits `622c7fa` and `6088a44` exist.
- Fixture generation check is byte-identical, the full fixture negative matrix and Required lane pass, and structured coverage classifies all three deliverables as automatically proven.

---
*Phase: 03-reference-color-semantics*
*Completed: 2026-07-17*
