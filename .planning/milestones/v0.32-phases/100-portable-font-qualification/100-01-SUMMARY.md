---
phase: 100-portable-font-qualification
plan: 01
subsystem: font-fixture-qualification
tags: [moonbit, truetype, dejavu, powershell, fixtures, portability]

requires:
  - phase: 99-simple-and-composite-outlines
    provides: Public simple/composite Path2 workflow and checksum-correct generated font builders
provides:
  - Exact redistributed DejaVu Sans 2.37 font and notice with immutable provenance
  - Independent closed SFNT oracle for tables, cmap, metrics, glyph paths, kern, and maxp
  - Deterministic 4096-byte portable MoonBit transport plus compact complete-workflow fixture
  - Closed eleven-case hostile and transactional qualification matrix
affects: [100-cmap-coexistence, 100-public-font-qualification, fixture-policy]

tech-stack:
  added: []
  patterns:
    - One fail-closed PowerShell tool owns archive intake, independent oracle derivation, schema validation, and generated-source drift checks
    - External font bytes retain upstream provenance while only the project-authored hostile matrix uses Apache-2.0
    - Portable tests reconstruct canonical binary bytes from bounded compile-time literals without ambient capabilities

key-files:
  created:
    - fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf
    - fixtures/font/dejavu-sans-2.37/LICENSE
    - fixtures/font/dejavu-sans-2.37/oracle.json
    - fixtures/font/qualification-cases.json
    - scripts/fixtures/Generate-FontQualification.ps1
    - modules/mb-font/font/generated_font_qualification_test.mbt
  modified:
    - fixtures/manifest.json

key-decisions:
  - "Freeze a versioned closed PowerShell oracle whose expected serialization is byte-compared and can never be updated from mb-font output."
  - "Keep the selected 4096-byte literal chunk size after it compiled successfully on js, wasm, wasm-gc, and native."
  - "Use a 580-byte checksum-correct compact font for the minimal BMP, supplementary, metric, simple, composite, and nonzero kern workflow."
  - "Keep requested/limit values optional in the hostile schema, freezing numeric pairs only for the source, open-budget, and outline-budget exact/one-short cases."

patterns-established:
  - "Fixture intake proves archive and both exact members in temporary memory before the first repository write."
  - "Generated-source checking reconstructs rendered byte literals and verifies exact length, SHA-256, and byte equality."

requirements-completed: [FONT-05]

coverage:
  - id: D1
    description: Exact DejaVu Sans 2.37 bytes, notice, provenance, and independent semantic oracle are fail-closed.
    requirement: FONT-05
    verification:
      - kind: integration
        ref: "./scripts/fixtures/Generate-FontQualification.ps1 -Check plus Assert-FixtureManifest"
        status: pass
    human_judgment: false
  - id: D2
    description: Canonical DejaVu bytes and the compact complete-workflow fixture are available through portable generated MoonBit source.
    requirement: FONT-05
    verification:
      - kind: integration
        ref: "moon -C modules/mb-font check --target <js|wasm|wasm-gc|native> --frozen --target-dir target/phase100-plan01-<target> --serial"
        status: pass
      - kind: unit
        ref: "Temporary smoke execution proved exact 757076/580 byte lengths, open, mappings, outlines, kern, and 11 cases before canonical regeneration"
        status: pass
    human_judgment: false
  - id: D3
    description: The closed hostile matrix freezes all required D-11 and D-13 operation, error, limit, and publication facts.
    requirement: FONT-05
    verification:
      - kind: integration
        ref: "Generate-FontQualification.ps1 closed schema/ID validation and idempotent -Check"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-07-27
status: complete
---

# Phase 100 Plan 01: Licensed Font Intake and Portable Generation Summary

**Exact DejaVu Sans 2.37 bytes now flow through a versioned independent SFNT oracle into deterministic four-target MoonBit transport and a closed hostile qualification matrix.**

## Performance

- **Duration:** 14 minutes
- **Started:** 2026-07-27T13:43:30Z
- **Completed:** 2026-07-27T13:57:12Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Verified the locked 417,746-byte upstream ZIP before extraction, then verified and committed the exact 757,076-byte TTF and 8,816-byte notice before repository mutation.
- Added a named/versioned independent PowerShell reader that freezes the exact 20-table inventory, cmap records and mappings, named metrics, glyph classifications/bounds/components, path counts/fingerprints/coordinates, A/V kerning, and maxp ceilings.
- Appended two confirmed upstream-license manifest records and one project-authored Apache-2.0 hostile-matrix record without changing the prior eight-record order.
- Generated exact DejaVu bytes as 185 bounded MoonBit literal chunks, round-tripped them to the locked SHA-256, and compiled the source on all four targets.
- Added an eleven-case closed matrix and a compact checksum-correct complete-workflow fixture covering BMP and supplementary mappings, simple/composite outlines, named metrics, and nonzero classic kern.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fail closed on DejaVu intake and derive the independent oracle** - `2a21f0fa` (`feat`)
2. **Task 2: Generate portable byte transport and the closed hostile matrix** - `313a7a4a` (`feat`)

## Files Created/Modified

- `fixtures/font/dejavu-sans-2.37/DejaVuSans.ttf` - Exact upstream font bytes with SHA-256 `7da195a74c55bef988d0d48f9508bd5d849425c1770dba5d7bfc6ce9ed848954`.
- `fixtures/font/dejavu-sans-2.37/LICENSE` - Exact upstream redistribution notice.
- `fixtures/font/dejavu-sans-2.37/oracle.json` - Closed independent inventory and semantic fact set.
- `fixtures/font/qualification-cases.json` - Ordered eleven-case hostile and transactional descriptor matrix.
- `fixtures/manifest.json` - Adjacent confirmed DejaVu records followed by the generated case record.
- `scripts/fixtures/Generate-FontQualification.ps1` - Sole intake, oracle, generation, and drift-check implementation.
- `modules/mb-font/font/generated_font_qualification_test.mbt` - Exact generated bytes, compact fixture accessor, and case transport.

## Decisions Made

- The oracle canonicalizes command sequences as stable `M`/`L`/`Q`/`Z` records and hashes their UTF-8 representation while retaining selected commands for readable coordinate checks.
- The generated source keeps 4,096-byte chunks because every declared backend accepted that layout; the canonical font identity is independent of this reversible source-layout choice.
- The compact fixture is assembled only from established checksum-correct test builders, keeping production parser logic out of the generator.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first intake exposed Windows `ConvertTo-Json` CRLF output during byte comparison. Stable JSON rendering was normalized to LF before canonical writes and checks.
- A temporary compact-fixture smoke assertion initially guessed 552 bytes; execution proved the checksum-correct fixture is 580 bytes. The closed exact/one-short descriptors were frozen to 580/579, and the temporary test was removed by canonical regeneration.
- MoonBit reports expected unused-field/function warnings because Plans 100-02 and 100-03 are the first consumers of the generated test-private accessors. All four checks completed with zero errors.

## Verification

- Generator normal mode was byte-idempotent; generated source SHA-256 remained `ee1a0d354cd669fa180ce25cdfe1c9d35a86a33ee009cb4ee80b1791641d91ef`.
- Generator `-Check` validated font, notice, oracle, cases, manifest order, schema, provenance, rendered literal round-trip, and generated-source bytes without tracked mutations.
- Fixture manifest policy passed for all eleven records.
- `moon check` passed independently on `js`, `wasm`, `wasm-gc`, and `native` with unique target directories.
- A temporary executed smoke test passed 93/93 on `js`, including exact generated lengths, compact open, BMP/supplementary lookup, simple/composite outline publication, nonzero kern, and case count; canonical regeneration then removed the smoke test.
- `git diff --check` and added-file TODO/FIXME/placeholder/skipped-test scans passed.

## Known Stubs

None. The generated accessors are intentionally consumed by later Phase 100 plans; they already compile on every target and their core byte/workflow facts were executed by the temporary smoke proof.

## Threat Flags

None. The planned untrusted archive, fixture substitution, self-oracle, licensing, and generated-byte trust boundaries are covered. No network endpoint, runtime filesystem access, authentication path, FFI, public API, dependency, or production parser surface was added.

## User Setup Required

None - normal generation and `-Check` are offline after the committed intake.

## Next Phase Readiness

- Plan 100-02 can consume the exact generated DejaVu accessor to reproduce and repair the valid format-6 coexistence admission defect.
- Plan 100-03 can consume the compact accessor, independent public facts, and exact hostile ID sequence without target-specific source or ambient capabilities.

## Self-Check: PASSED

- All seven implementation/fixture artifacts and this summary exist.
- Both task commits resolve in repository history.
- Exact intake, independent oracle, manifest, generator, round-trip, four-target compilation, compact smoke, stub, and threat gates passed.

---
*Phase: 100-portable-font-qualification*
*Completed: 2026-07-27*
