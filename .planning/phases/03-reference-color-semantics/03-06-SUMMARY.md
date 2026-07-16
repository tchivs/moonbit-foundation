---
phase: 03-reference-color-semantics
plan: "06"
subsystem: color-profile
tags: [moonbit, opaque-profile, bounded-bytes, resource-budget, identity-metadata]

requires:
  - phase: 02-bounded-core-primitives
    provides: atomic resource budgets, independently owned bytes, and retained immutable views
  - phase: 03-reference-color-semantics
    provides: deterministic derived profile vectors and explicit color semantic boundaries
provides:
  - direct built-in sRGB identity plus explicitly tagged opaque profile identity
  - caller-bounded exact independent profile byte preservation
  - pre-copy tag, payload-limit, and atomic budget rejection evidence
affects: [04-image-contract, 05-codec, color-conformance]

tech-stack:
  added: []
  patterns: [identity-only format tags, caller-supplied payload ceilings, validate-then-delegate owned storage]

key-files:
  created:
    - modules/mb-color/profile/moon.pkg
    - modules/mb-color/profile/profile.mbt
    - modules/mb-color/profile/profile_test.mbt
    - modules/mb-color/profile/profile_wbtest.mbt
    - modules/mb-color/profile/reference_vectors_wbtest.mbt
  modified:
    - scripts/fixtures/Generate-ColorVectors.ps1
    - policy/foundation.json

key-decisions:
  - "Treat ProfileFormatTag as a case-preserving bounded ASCII identity token; canonical icc labels bytes without certifying their contents."
  - "Check the caller-supplied payload maximum before delegating allocation, atomic budget charging, and copying directly to OwnedBytes::from_bytes."
  - "Keep profile as an independent leaf with exact DAG edges only to mb-core/error, mb-core/budget, and mb-core/bytes."

patterns-established:
  - "Opaque profile preservation: validate identity and caller ceiling before the authoritative mb-core owned-byte allocation path."
  - "Profile semantics: exact retained bytes and format tag are identity metadata only; no parsing, header inspection, digest, transform, or ambient I/O exists."

requirements-completed: [COLR-05, COLR-04]

coverage:
  - id: D1
    description: "Direct built-in sRGB and explicitly tagged opaque identities preserve accepted tag spelling and exact independent bytes"
    requirement: COLR-05
    verification:
      - kind: unit
        ref: "moon -C modules/mb-color test profile --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Invalid tags, one-over caller limits, and bytes/allocation/allocation-size budget failures reject deterministically before copy side effects"
    requirement: COLR-05
    verification:
      - kind: unit
        ref: "modules/mb-color/profile/profile_wbtest.mbt#tag and caller-limit rejection precede owned-byte charging"
        status: pass
      - kind: unit
        ref: "modules/mb-color/profile/profile_test.mbt#each independent storage budget dimension rejects atomically"
        status: pass
    human_judgment: false
  - id: D3
    description: "Generated profile evidence plus exact interface, publication surface, four targets, and independent core-only DAG are fail closed"
    requirement: COLR-04
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/fixtures/Generate-ColorVectors.ps1 -Artifacts profile -Check"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-07-17
status: complete
---

# Phase 03 Plan 06: Bounded Opaque Profile Identity Summary

**Direct built-in sRGB identity and caller-bounded opaque profile bytes now preserve exact metadata through atomic mb-core storage without interpreting ICC contents**

## Performance

- **Duration:** 14 min
- **Started:** 2026-07-16T18:45:00Z
- **Completed:** 2026-07-16T18:59:03Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added a case-preserving ASCII profile tag grammar, canonical `icc`, explicit caller payload limits, and direct built-in/opaque profile identities.
- Preserved empty, exact-limit, and arbitrary ICC-tagged bytes exactly and independently while exposing only retained immutable views.
- Proved tag and caller-limit rejection precede storage, and independently proved bytes, allocation-count, and allocation-size budget failures consume nothing.
- Registered profile after alpha with an exact 27-line interface, five-file publication surface, four targets, and only the three planned mb-core dependencies.

## Task Commits

1. **Task 1 RED: Specify bounded opaque profile semantics** - `a924fb4` (test)
2. **Task 1 GREEN: Implement bounded opaque profile identity** - `145d1ba` (feat)
3. **Task 1 fix: Keep generated profile evidence format-clean** - `d141506` (fix)
4. **Task 2: Register exact profile package contract** - `6d2d454` (chore)

## Files Created/Modified

- `modules/mb-color/profile/moon.pkg` - Four-target leaf importing only mb-core error, budget, and bytes.
- `modules/mb-color/profile/profile.mbt` - Validated tags, caller limits, exact owned payloads, immutable views, and built-in/opaque identities.
- `modules/mb-color/profile/profile_test.mbt` - Public identity, grammar, limit, budget, and byte-round-trip evidence.
- `modules/mb-color/profile/profile_wbtest.mbt` - Internal precharge ordering, source independence, and no-header-inspection proof.
- `modules/mb-color/profile/reference_vectors_wbtest.mbt` - Deterministic package-local accepted/rejected tag table.
- `scripts/fixtures/Generate-ColorVectors.ps1` - Formatter-stable profile table serialization.
- `policy/foundation.json` - Exact profile package order, interface, imports, targets, and publication allowlist.

## Decisions Made

- The tag grammar is exactly ASCII `[A-Za-z0-9][A-Za-z0-9._+-]{0,31}` and preserves caller spelling/case; `icc` is a canonical convenience label only.
- The profile layer performs only tag and caller-limit validation. `OwnedBytes::from_bytes` remains authoritative for checked narrowing, allocation approval, atomic multidimensional budget charge, allocation, and copy ordering.
- Empty payloads are valid opaque data when the explicit limit and budget permit them, because this carrier promises preservation rather than profile validity.
- No digest API, ICC header check, transform, semantic-equivalence claim, filesystem capability, host adapter, or global maximum was introduced.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made generated profile evidence formatter-clean**
- **Found during:** Task 1 post-GREEN generator check
- **Issue:** The profile renderer emitted a table shape that the pinned formatter rewrote, so byte-identical generator check and mandatory formatting could not both pass.
- **Fix:** Added the canonical header separator and emitted the accepted/rejected tag arrays in the formatter-stable representation.
- **Files modified:** `scripts/fixtures/Generate-ColorVectors.ps1`, `modules/mb-color/profile/reference_vectors_wbtest.mbt`
- **Verification:** Selective profile generator check, formatter check, four-target package tests, and the full Required lane pass.
- **Committed in:** `d141506`

---

**Total deviations:** 1 auto-fixed (1 blocking issue)
**Impact on plan:** The fix only aligns canonical generated bytes with existing format policy; tag, payload, budget, and identity semantics are unchanged.

## Issues Encountered

None beyond the formatter/generator alignment documented above.

## User Setup Required

None - no external service, dependency, or manual configuration is required.

## Known Stubs

None.

## Threat Flags

None. The only new trust boundary is the planned profile input surface: explicit ceilings mitigate allocation pressure, bounded tags remain identity-only, and private owned storage prevents exposing caller or mutable backing.

## TDD Gate Compliance

- RED commit `a924fb4` failed on the planned absent profile types and functions.
- GREEN commit `145d1ba` follows it and passes all ten profile tests on js, wasm, wasm-gc, and native.

## Next Phase Readiness

- Plan 03-07 can remove the private root scaffold and document the complete five-package color contract.
- Phase 4 can retain profile identity and exact opaque bytes without importing a parser or inventing resource policy.
- No blockers remain; the Required lane is green with 111 tests per target and exact profile policy classification.

## Self-Check: PASSED

- All five profile package files and both modified integration files exist.
- Task commits `a924fb4`, `145d1ba`, `d141506`, and `6d2d454` exist in history.
- Profile tests pass 10/10 on every required target, selective generation is byte-identical, and the complete Required lane passes.

---
*Phase: 03-reference-color-semantics*
*Completed: 2026-07-17*
