---
phase: 102-root-relative-selected-face-admission
plan: 03
subsystem: font-qualification
tags: [moonbit, opentype, ttc, equivalence, precedence, portability, policy]

requires:
  - phase: 102-root-relative-selected-face-admission
    provides: Root-relative selected-face transaction, existing Font publication, exact selected accounting, and mutation guards from Plans 102-01 and 102-02
  - phase: 101-collection-contract-and-bounded-envelope
    provides: Retained collection root, cached face authority, closed profiles, and staged bounded envelope
provides:
  - Public standalone/selected equivalence across metrics, Unicode, glyph identity, kerning, and exact outline commands
  - Complete selected multi-fault precedence and full-budget atomicity qualification
  - Exact 85-line generated interface policy admitting only FontCollection::open_face
  - Focused public/private collection evidence on js, wasm, wasm-gc, and native
affects: [103-collection-qualification, mb-font-compatibility-policy]

tech-stack:
  added: []
  patterns:
    - Compare container forms only through the existing opaque Font public observations
    - Pair every selected failure with exact structured CoreError fields and complete Budget snapshots
    - Keep generated interface output ignored while exact-comparing it against two independent allowlists

key-files:
  created: []
  modified:
    - modules/mb-font/font/collection_test.mbt
    - modules/mb-font/font/collection_wbtest.mbt
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1

key-decisions:
  - "The Phase 102 compatibility boundary advances from 84 to 85 semantic lines by only FontCollection::open_face returning the existing Font."
  - "Standalone and selected equivalence is measured only through public Font observations, including exact Path2 command coordinates."
  - "Generated pkg.generated.mbti remains ignored and untracked verification output."

patterns-established:
  - "Qualification matrix: multi-fault pair -> exact earlier category/code/operation/context/offset/requested/limit -> unchanged eight-dimensional Budget."
  - "Policy advancement: regenerate -> semantic-line normalize -> exact count/order compare -> independent negative classifier."

requirements-completed:
  - TTC-02
  - TTC-03

coverage:
  - id: D1
    description: "Standalone and collection-selected forms of the same logical font are publicly equivalent across all Phase 102 Font observations."
    requirement: TTC-02
    verification:
      - kind: integration
        ref: "modules/mb-font/font/collection_test.mbt#TTC-02 standalone and selected faces are publicly equivalent"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font test font/collection_test.mbt on js, wasm, wasm-gc, native (31/31 each)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Selected multi-fault precedence, checksum ordering, one-short authority, and mutation failures are exact and budget-atomic."
    requirement: TTC-03
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_test.mbt#TTC-02 selected multi-fault precedence is exact and atomic"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/collection_wbtest.mbt#selected final revision hook is atomic and successful Font retains root identity"
        status: pass
    human_judgment: false
  - id: D3
    description: "The public mb-font interface contains exactly 85 ordered semantic lines with only the intended open_face addition."
    requirement: TTC-02
    verification:
      - kind: integration
        ref: "moon -C modules/mb-font info --target all --frozen plus Assert-FontFoundationPolicy"
        status: pass
    human_judgment: false
  - id: D4
    description: "Focused public and private collection selectors are portable across all four targets without dependency, FFI, I/O, or generated-output expansion."
    requirement: TTC-03
    verification:
      - kind: integration
        ref: "public 31/31 and white-box 12/12 independently on js, wasm, wasm-gc, native; native font 146/146; target-all check/info and policy pass"
        status: pass
    human_judgment: false

duration: 28min
completed: 2026-07-28
status: complete
---

# Phase 102 Plan 03: Equivalence, Precedence, Policy, and Portability Summary

**Public standalone/selected Font equivalence, exact failure atomicity, and a one-line 84-to-85 interface advance are now reproducibly qualified on all four supported targets.**

## Performance

- **Duration:** 28 min
- **Started:** 2026-07-28T02:00:43Z
- **Completed:** 2026-07-28T02:28:43Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Built one generated logical TrueType with BMP and supplementary mapping, signed kerning, distinct glyph metrics, and a real unhinted outline, then proved standalone and selected public results are identical.
- Completed the selected precedence and atomicity matrix with exact structured errors, all eight Budget dimensions, selected checksum-before-resource behavior, ancestor work shortage, repeated independent selection, and mutate/restore invalidation.
- Advanced both policy allowlists to exactly 85 semantic lines and added fail-closed negatives for altered returns, overloads, selected wrappers, raw source/directory/range handles, parser facts, collection-specific queries, private storage, and deferred capabilities.
- Passed focused public 31/31 and white-box 12/12 tests independently on js, wasm, wasm-gc, and native, plus the complete native font suite at 146/146.

## Task Commits

Each task was committed atomically:

1. **Task 1: Freeze public equivalence and the complete selected failure matrix** — `3c466f8c` (test)
2. **Task 2: Advance the interface by one line and qualify focused portability** — `3d7991f2` (test)

## Files Created/Modified

- `modules/mb-font/font/collection_test.mbt` — generic selected TTC builder, complete public equivalence oracle, multi-fault ordering, exact resource fields, and repeated mutate/restore evidence.
- `modules/mb-font/font/collection_wbtest.mbt` — full mid-selection error/budget facts and repeated retained-root identity checks.
- `policy/foundation.json` — exact generated `FontCollection::open_face` addition, advancing the semantic interface from 84 to 85 lines.
- `scripts/quality/Assert-Policy.ps1` — independent Phase 102 exact classifier, 85-line count, and expanded negative fixtures.

## Decisions Made

- Reused the standalone test builders as byte-generation infrastructure but compared semantic outcomes only through public `Font` methods.
- Kept `font_test.mbt` unchanged because it already freezes the standalone whole-source bad-adjustment `Data` oracle and staged charge behavior exactly.
- Treated `pkg.generated.mbti` strictly as ignored compiler evidence; it was neither edited nor tracked.

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

Task 1 is a test-only qualification task over the production transaction completed in Plan 102-02. Its correct new behavioral regressions were immediately green against the inherited implementation, so no production GREEN commit was necessary or appropriate; the qualification outcome is captured in the atomic `test(102-03)` commit.

## Issues Encountered

- The first combined baseline command exceeded its two-minute execution window after completing part of the suite. Splitting the focused and package runs produced attributable results and all gates passed.
- The pinned MoonBit toolchain continues to emit its pre-existing generated `Result` unused-expression warning; no scoped test or policy gate failed.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The only stub-pattern matches are pre-existing empty byte-builder arrays and policy text that rejects placeholder evidence; no runtime stub, TODO, FIXME, skipped test, or placeholder was introduced.

## Verification Results

- Focused public collection tests: **31/31** on each of `js`, `wasm`, `wasm-gc`, and `native`.
- Focused white-box collection tests: **12/12** on each of `js`, `wasm`, `wasm-gc`, and `native`.
- Complete native font package: **146/146**.
- `moon check --target all --frozen`: passed.
- `moon info --target all --frozen`: passed; generated and policy interfaces both contain exactly **85** semantic lines and one exact `open_face` declaration.
- `Assert-FontFoundationPolicy`: passed exact interface negatives, source inventory, four targets, mb-core-only dependency, pure MoonBit/FFI, ambient-I/O, and deferred-capability gates.
- `pkg.generated.mbti`: ignored and untracked.
- `git diff --check`: passed.

## Next Phase Readiness

- TTC-02 and TTC-03 now have complete focused Phase 102 evidence.
- Phase 103 can add the intentionally deferred licensed, broad hostile, and release qualification matrix without changing the selected-face contract.
- No blockers remain.

## Self-Check: PASSED

All four modified task files and this summary exist, both task commits resolve, every declared verification gate passed, and no required artifact is missing.

---
*Phase: 102-root-relative-selected-face-admission*
*Completed: 2026-07-28*
