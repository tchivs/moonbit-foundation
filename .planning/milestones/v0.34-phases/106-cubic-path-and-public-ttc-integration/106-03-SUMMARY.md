---
phase: 106-cubic-path-and-public-ttc-integration
plan: "03"
subsystem: font
tags: [moonbit, cff1, ttc, otc, collection, atomic-budget, compatibility]

requires:
  - phase: 106-cubic-path-and-public-ttc-integration
    provides: standalone CFF1 promotion, exact-capacity cubic paths, atomic outline authority, and exhaustive mutation precedence
provides:
  - selected TTC/OTC CFF1 faces admitted through the shared CFF transaction with collection-root offsets and authoritative opening revisions
  - face-local cmap, metrics, kerning, bounds, and line metrics combined with shared CFF bytes
  - exact and one-short admission/outline authority plus mutation-atomic selected-face evidence
  - frozen standalone and selected static-glyf ordering and charge compatibility
affects: [phase-107-qualification, mb-font, ttc, otc, cff1]

tech-stack:
  added: []
  patterns:
    - collection-selected CFF1 faces reuse shared admission with an explicit authoritative collection opening revision
    - collection capability failures retain the existing font-collection profile error contract
    - selected CFF and static-glyf compatibility is frozen through public and white-box deterministic fingerprints

key-files:
  created: []
  modified:
    - modules/mb-font/font/cff_admission.mbt
    - modules/mb-font/font/font.mbt
    - modules/mb-font/font/collection.mbt
    - modules/mb-font/font/collection_test.mbt
    - modules/mb-font/font/collection_wbtest.mbt
    - modules/mb-font/font/font_test.mbt

key-decisions:
  - "Thread an optional authoritative opening revision through private CFF admission so standalone opens keep fresh capture while collection-selected faces retain the collection transaction revision."
  - "Project selected CFF1 faces through the existing admitted-CFF Font constructor and translate capability failures to the established collection profile error surface."
  - "Keep CFF2, variable, and other unsupported profiles rejected while preserving the static-glyf arm byte-for-byte in production."

patterns-established:
  - "Selected CFF tests compare shared outline bytes with face-local cmap, metrics, kerning, bounds, and line metrics against standalone parity."
  - "Collection transaction tests exercise exact and every independent one-short caller/ancestor dimension before mutation-at-execution, mutation-before-commit, and mutation-after-path-stage cases."

requirements-completed: [CFF-04, CFF-05]

coverage:
  - id: CFF-05-selected-collection
    description: "A CFF1 face selected from TTC/OTC opens through the shared public Font surface, reuses root-relative CFF bytes, and preserves face-local public facts and standalone ordering."
    requirement: CFF-05
    verification:
      - kind: integration
        ref: "modules/mb-font/font/collection_test.mbt#Phase 106 selected CFF1 shares cubic bytes and retains face local facts"
        status: pass
      - kind: integration
        ref: "moon test modules/mb-font/font --target native --filter \"*Phase 106 selected CFF1*\" (2 passed)"
        status: pass
    human_judgment: false
  - id: CFF-04-selected-authority
    description: "Selected CFF admission and outline transactions succeed at exact authority, reject every independent one-short caller and ancestor window, and return State without charge at all authorized mutation seams."
    requirement: CFF-04
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_wbtest.mbt#Phase 106 preserves selected CFF admission outline and mutation authority"
        status: pass
      - kind: integration
        ref: "moon test modules/mb-font/font --target native --filter \"*CFF outline atomic*\" (4 passed)"
        status: pass
    human_judgment: false
  - id: CFF-05-compatibility-freeze
    description: "Collection edge errors, standalone/selected ordering, repeated charge deltas, invalid inputs, and existing static-glyf fingerprints remain deterministic."
    requirement: CFF-05
    verification:
      - kind: integration
        ref: "moon test modules/mb-font/font --target native --filter \"*Phase 106 preserves*\" (5 passed)"
        status: pass
      - kind: integration
        ref: "moon test --target native (1273 passed)"
        status: pass
    human_judgment: false

duration: 31min
completed: 2026-07-29
status: complete
---

# Phase 106 Plan 03: Selected CFF Collection Integration and Compatibility Freeze Summary

**TTC/OTC-selected CFF1 faces now reuse the standalone atomic CFF admission and cubic outline path while retaining collection-root offsets, opening-revision authority, face-local facts, and existing static-glyf behavior.**

## Performance

- **Duration:** 31 min
- **Started:** 2026-07-28T19:54:31Z
- **Completed:** 2026-07-28T20:25:57Z
- **Tasks:** 2
- **Files created/modified:** 7

## Accomplishments

- Added a selected-CFF collection adapter that reuses the shared admission pipeline, collection checksum policy, preflighted collection charge, and authoritative collection opening revision.
- Preserved root-relative shared CFF bytes while keeping each face's cmap, hmtx, kern, head, hhea, and OS/2 facts distinct and publicly equivalent to standalone opens.
- Proved exact and independently one-short bytes, allocations, allocation-size, and work authority for selected admission and cubic outline transactions in direct and nested budgets.
- Proved execution-time, pre-commit, and post-path-stage mutation returns State with no caller or ancestor charge.
- Froze zero-face and out-of-range collection errors, standalone/selected ordering, repeatable resource deltas, invalid scalar/GID behavior, and both standalone and selected static-glyf fingerprints.
- Passed the full 1,273-test native suite and all configured target checks without adding a public CFF or Type 2 limit surface.

## Task Commits

Each task was committed atomically:

1. **Task 1: Route selected collection CFF1 faces through shared admission**
   - `96d0dcd1` — test: add failing selected CFF collection tracer
   - `97cd2d2d` — feat: open selected CFF faces through shared admission
2. **Task 2: Freeze authority edges and static-glyf compatibility**
   - `5e3c9dc9` — test: freeze selected CFF authority and glyf compatibility

## Files Created/Modified

- `modules/mb-font/font/cff_admission.mbt` — accepts an optional authoritative opening revision across the private shared CFF admission path.
- `modules/mb-font/font/font.mbt` — adapts a collection face directory into the existing admitted-CFF `Font` projection and preserves the collection error contract.
- `modules/mb-font/font/collection.mbt` — routes `FontFaceProfile::Cff` through the selected-CFF adapter while leaving static glyf and unsupported profiles intact.
- `modules/mb-font/font/collection_test.mbt` — covers shared cubic bytes, face-local facts, collection edges, standalone parity, and selected static-glyf ordering.
- `modules/mb-font/font/collection_wbtest.mbt` — covers collection-root/revision retention, exact/one-short authority, nested budgets, and mutation atomicity.
- `modules/mb-font/font/font_test.mbt` — expands standalone static-glyf repetition, resource-delta, invalid-GID, and invalid-scalar compatibility evidence.

## Decisions Made

- Standalone CFF admission continues to capture the current source revision by default; only the private collection adapter supplies the collection's authoritative opening revision.
- Selected CFF faces reuse `font_from_admitted_cff1` rather than introducing a second projection, decoder, glyph interpreter, or budget transaction.
- Selected CFF capability failures map to the established `font-collection-open-face` profile error so collection callers retain their existing structured-error contract.
- The production static-glyf branch was not rewritten; compatibility was expanded entirely through deterministic regression evidence.

## Verification

- `moon test modules/mb-font/font --target native --filter "*Phase 106 selected CFF1*"` — 2 passed, 0 failed.
- `moon test modules/mb-font/font --target native --filter "*Phase 106 preserves*"` — 5 passed, 0 failed.
- `moon test modules/mb-font/font --target native --filter "*CFF outline exact path charge*"` — 4 passed, 0 failed.
- `moon test modules/mb-font/font --target native --filter "*CFF outline atomic*"` — 4 passed, 0 failed.
- `moon test --target native` — 1,273 passed, 0 failed.
- `moon check --target native` — passed with 0 errors.
- `moon check --target all` — passed with 0 errors on every configured target.
- Both checks retain 37 non-fatal pre-existing unused/deprecated-debug warnings; no verification was skipped.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Retargeted legacy unsupported-profile assertions after CFF1 became selectable**
- **Found during:** Task 1 (selected collection CFF tracer)
- **Issue:** Three existing collection tests used CFF1 as their unsupported-profile fixture, which contradicted the planned CFF1 promotion and blocked the package suite.
- **Fix:** Retargeted those negative cases to the still-unsupported CFF2 and variable profiles without weakening the legacy error assertions.
- **Files modified:** `modules/mb-font/font/collection_test.mbt`
- **Verification:** Full `mb-font/font` native tests and the 1,273-test repository native suite passed.
- **Committed in:** `97cd2d2d`

**2. [Rule 3 - Blocking] Preserved the collection capability error boundary**
- **Found during:** Task 1 (full package verification)
- **Issue:** Shared CFF admission surfaced a lower-level capability error for selected collection faces, while the established collection contract requires the structured profile error.
- **Fix:** Translated capability failures in the private selected-CFF adapter to `font_collection_profile_error` while leaving Resource, State, Data, and other categories untouched.
- **Files modified:** `modules/mb-font/font/font.mbt`
- **Verification:** Hostile qualification tests and the full native suite passed with the original collection operation/context ordering.
- **Committed in:** `97cd2d2d`

**3. [Rule 3 - Blocking] Normalized SDK-generated Phase 106 completion metadata**
- **Found during:** Final state advancement
- **Issue:** The state SDK recognized the last plan and 100% progress but retained Plan 02 activity text, Plan 03 next-step prose, phase-less decision labels, and an in-progress roadmap row.
- **Fix:** Synchronized Phase 106 completion, current activity, decisions, next action, completed-plan count, and roadmap status with the committed summaries and requirements.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Verification:** State reports 12/12 completed plans and ready-for-verification status; the roadmap reports Phase 106 complete at 3/3 plans.
- **Committed in:** final metadata commit

---

**Total deviations:** 3 auto-fixed blocking compatibility/metadata issues.
**Impact on plan:** The implementation fixes were required to promote CFF1 without changing unrelated profile support or the existing collection error surface, and the metadata fix aligns execution state with disk artifacts; no public API or scope was added.

## Issues Encountered

- Task 2 initially used an empty-outline fixture for the path one-short matrix. Its zero byte charge made `bytes - 1UL` underflow, so the test was corrected to use the real cubic CFF fixture before commit.
- A package-wide formatter invocation touched unrelated font files during Task 1 preparation. Every unintended formatting edit was explicitly restored before the task commit; no unrelated file entered plan history.

## Known Stubs

None. The pre-existing fixture variable `placeholder_top` computes same-size CFF offsets before writing the final Top DICT; it is not an unwired production value or deferred behavior.

## Threat Flags

None. The selected face remains inside the plan's existing untrusted-byte, revision, capability, and budget boundaries; no network endpoint, authentication path, filesystem access, schema boundary, FFI, ambient I/O, public CFF API, or post-commit callback surface was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 106 now has end-to-end standalone and collection-selected CFF1 cubic outlines with exact authority, mutation precedence, and deterministic compatibility evidence.
- Phase 107 qualification can treat selected CFF1 as a normal public `Font` while preserving CFF2/variable rejection and the static-glyf baseline.
- No implementation, test, setup, or verification blocker remains.

## Self-Check: PASSED

- All six implementation/evidence files and this summary exist.
- RED `96d0dcd1`, GREEN `97cd2d2d`, and compatibility `5e3c9dc9` commits exist in repository history.
- Focused selected-CFF, preserves, exact-charge, atomic, full native, native-check, and all-target checks passed before state advancement.

---
*Phase: 106-cubic-path-and-public-ttc-integration*
*Completed: 2026-07-29*
