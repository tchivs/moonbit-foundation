---
phase: 107-hostile-licensed-and-four-target-qualification
plan: "04"
subsystem: testing
tags: [moonbit, cff, font, conformance, hostile-fixtures, four-target]

requires:
  - phase: 107-03
    provides: Closed generated/licensed CFF carrier, canonical hostile corpus, and generator-owned private facts
provides:
  - Public-only standalone and selected-collection CFF observations for every generated and licensed face
  - Generator-checked private FD/local-environment and 53-row hostile/mutation evidence mirrors
  - Static glyf semantic compatibility fingerprint and four-target CFF conformance coverage
affects: [107-05, cff-v3-serialization, qualification-policy, release-evidence]

tech-stack:
  added: []
  patterns:
    - Package-private evidence carrier consumed exclusively through public Font and FontCollection APIs
    - Generator-delimited private oracle and hostile regions with exact source-locator verification
    - Backend-portable semantic assertions that avoid implementation-capacity locks

key-files:
  created: []
  modified:
    - benchmarks/font-cff/cff_qualification_wbtest.mbt
    - modules/mb-font/font/cff_cid_fixture_wbtest.mbt
    - modules/mb-font/font/cff_hostile_fixture_wbtest.mbt
    - modules/mb-font/font/font_qualification_test.mbt
    - scripts/fixtures/Generate-FontQualification.ps1

key-decisions:
  - "Keep generated and licensed carrier bytes package-private; qualify them only through public Font and FontCollection observations."
  - "Treat live frame length and executed call depth as the portable Type 2 semantic contract, not backend-specific Array capacity."
  - "Materialize the closed 53-row private hostile corpus once, then require exact generator mirror checks on every verification run."

patterns-established:
  - "Public/private evidence split: format-neutral observations live in the evidence package; FD, Private DICT, and local Subrs facts stay in mb-font white-box tests."
  - "Canonical locator discipline: changes that move source identities regenerate the carrier and revalidate every locator."

requirements-completed: [CFF-06]

coverage:
  - id: D1
    description: Every generated and licensed CFF face passes exact standalone and selected-collection public observations on all four targets.
    requirement: CFF-06
    verification:
      - kind: integration
        ref: "Generate-FontQualification.ps1 -CheckEvidencePackage -Target js|wasm|wasm-gc|native"
        status: pass
    human_judgment: false
  - id: D2
    description: Private FD/local-environment and all canonical hostile, resource, mutation, publication, and B8 facts are generator-checked and executed.
    requirement: CFF-06
    verification:
      - kind: integration
        ref: "font-cff1-v3 private fd oracle; private hostile outcomes; private mutation windows and atomic budgets"
        status: pass
    human_judgment: false
  - id: D3
    description: Static glyf semantics remain compatible while the complete mb-font suite passes on js, wasm, wasm-gc, and native.
    requirement: CFF-06
    verification:
      - kind: integration
        ref: "moon -C modules/mb-font test --target all --frozen (1286/1286 per target)"
        status: pass
    human_judgment: false

duration: 111min
completed: 2026-07-29
status: complete
---

# Phase 107 Plan 04: Public and Private CFF Qualification Summary

**Carrier-backed public CFF interoperability, exact private FD/hostile atomicity, and static glyf compatibility now pass on all four MoonBit targets.**

## Performance

- **Duration:** 111 min
- **Started:** 2026-07-29T03:39:22Z
- **Completed:** 2026-07-29T05:30:28Z
- **Tasks:** 3
- **Files modified:** 15

## Accomplishments

- Qualified generated name-keyed, CID, shared-CFF collection, Source Sans, and Source Han faces through exact public mapping, metrics, bounds, kerning, path, mutation, and correctness-workload observations.
- Locked generator-owned private CID descriptor/FD/local Subrs/matrix facts and the Phase 106 static glyf semantic fingerprint without exposing private evidence or freezing aggregate test counts.
- Executed all 53 canonical structural, Type 2, semantic-limit, resource, mutation, and precedence identities with exact publication and caller/ancestor B8 snapshots.
- Passed the evidence package and complete 1286-test mb-font suite on js, wasm, wasm-gc, and native.

## Task Commits

Each TDD task was committed atomically:

1. **Task 1 RED: failing public CFF observation suite** - `d697bbf5`
2. **Task 1 GREEN: carrier-backed public CFF workflows** - `7065d2c4`
3. **Task 2 RED: failing private and glyf compatibility locks** - `6c073936`
4. **Task 2 GREEN: private CFF and static glyf facts** - `e776b933`
5. **Task 3 RED: failing hostile and mutation matrix identities** - `cb01f943`
6. **Task 3 GREEN: closed hostile and mutation matrix** - `b3765be8`

## Files Created/Modified

- `benchmarks/font-cff/cff_qualification_wbtest.mbt` - Public-only generated/licensed standalone, collection, mutation, and correctness-workload observations.
- `benchmarks/font-cff/generated_cff_evidence.mbt` - Regenerated canonical carrier projections and source locators.
- `benchmarks/font-cff/moon.mod.json` / `benchmarks/font-cff/moon.pkg` - Frozen local mb-font resolution and required public imports.
- `fixtures/font/cff-qualification-cases.json` - Corrected canonical GID sets and exact source locators.
- `modules/mb-font/font/cff_cid_fixture_wbtest.mbt` - Generator-delimited private FD/local-environment oracle comparison.
- `modules/mb-font/font/cff_hostile_fixture_wbtest.mbt` - Complete 53-row hostile/mutation dispatcher and mirror region.
- `modules/mb-font/font/cff_type2_fixture_wbtest.mbt` - Portable depth semantics used by hostile/resource evidence.
- `modules/mb-font/font/cff_type2_wbtest.mbt` - CFF hint substitution regression coverage.
- `modules/mb-font/font/font_qualification_test.mbt` - Static glyf semantic compatibility fingerprint.
- `modules/mb-font/font/font_wbtest.mbt` - Public CFF workload support and exact mapping coverage.
- `modules/mb-font/font/cff_type2.mbt` - Correct Type 2 hint substitution state after moveto.
- `modules/mb-font/font/cmap.mbt` / `modules/mb-font/font/tables.mbt` - Recognized companion cmap record support for licensed fonts.
- `scripts/fixtures/Generate-FontQualification.ps1` - Canonical evidence generation, private oracle rendering, and hostile mirror materialization/checking.

## Decisions Made

- Public evidence remains deliberately format-neutral: the carrier supplies bytes and expected values, while all font behavior is observed through imported public APIs.
- Private FD, Private DICT, local Subrs, descriptor, and matrix facts remain confined to existing mb-font white-box tests.
- Array allocation capacity is not a cross-target contract; live root-frame state plus ten successful calls/returns is the portable depth-ceiling proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected Type 2 hint substitution after path start**
- **Found during:** Task 1 public licensed-face path qualification
- **Issue:** Valid CFF hint substitution after a moveto was rejected, preventing exact licensed outline observations.
- **Fix:** Preserved the valid hint state transition and added focused regression coverage.
- **Files modified:** `modules/mb-font/font/cff_type2.mbt`, `modules/mb-font/font/cff_type2_wbtest.mbt`
- **Verification:** Evidence-package four-target suite and complete mb-font four-target suite pass.
- **Committed in:** `7065d2c4`

**2. [Rule 1 - Bug] Accepted recognized cmap companion records**
- **Found during:** Task 1 licensed standalone/collection qualification
- **Issue:** Licensed fonts carrying recognized companion cmap records failed admission despite a valid selected mapping.
- **Fix:** Parsed and retained the supported companion record framing without adding a public API.
- **Files modified:** `modules/mb-font/font/cmap.mbt`, `modules/mb-font/font/tables.mbt`
- **Verification:** Exact Source Sans and Source Han public projections pass on all four targets.
- **Committed in:** `7065d2c4`

**3. [Rule 1 - Bug] Reconciled canonical generated GIDs and source locators**
- **Found during:** Tasks 1 and 3 generator checks
- **Issue:** Some generated outline selections were empty and later test additions moved canonical source identities.
- **Fix:** Selected nonempty ordered GIDs, updated every affected canonical locator, and regenerated the single carrier.
- **Files modified:** `fixtures/font/cff-qualification-cases.json`, `benchmarks/font-cff/generated_cff_evidence.mbt`
- **Verification:** `-Check`, `-CheckPublicPrivateBoundary`, and `-CheckPrivateEvidenceMirrors` pass.
- **Committed in:** `7065d2c4`, `b3765be8`

**4. [Rule 3 - Blocking] Added exact generator materializers for planned private regions**
- **Found during:** Tasks 2 and 3
- **Issue:** Check modes existed conceptually, but the plan-required delimited private FD and hostile regions could not be produced exactly.
- **Fix:** Added one-shot, region-bounded materializers and exact check paths; no runtime or public visibility was added.
- **Files modified:** `scripts/fixtures/Generate-FontQualification.ps1`
- **Verification:** `-CheckPrivateOracleFacts` and `-CheckPrivateEvidenceMirrors` pass.
- **Committed in:** `e776b933`, `b3765be8`

**5. [Rule 1 - Bug] Removed backend-specific Array capacity assertion**
- **Found during:** Task 3 all-target verification
- **Issue:** JS reports initial frame-array capacity 1 while other backends report 11; capacity is an implementation detail, not the Type 2 depth contract.
- **Fix:** Asserted one live root frame and retained exact ten-call/ten-return execution at the legal ceiling.
- **Files modified:** `modules/mb-font/font/cff_type2_fixture_wbtest.mbt`
- **Verification:** Focused JS test passes and all four targets pass 1286/1286.
- **Committed in:** `b3765be8`

**6. [Rule 1 - Bug] Normalized stale SDK-generated execution metadata**
- **Found during:** Plan finalization
- **Issue:** State handlers advanced the counters but emitted `Phase ?` decisions and left pre-execution activity, blocker, next-step, and metric prose stale.
- **Fix:** Attributed decisions to Phase 107 and synchronized the surrounding execution metadata with completed Plan 04.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Verification:** State reports Plan 5 of 6, 16/18 completed plans, 89% progress, and ROADMAP reports 4/6.
- **Committed in:** Plan metadata commit

---

**Total deviations:** 6 auto-fixed (5 Rule 1 bugs, 1 Rule 3 blocking issue).
**Impact on plan:** All fixes were required to make the specified canonical evidence correct and portable; no dependency, public API, runtime hook, or licensed-payload surface was added.

## Issues Encountered

- A package-wide formatter invocation touched unrelated files during Task 2. Every unrelated formatting change was restored file-by-file before the task commit; only planned files remained.
- Existing compiler and deprecation warnings remain outside this plan's scope; no test was skipped and no verification was left unrun.

## Known Stubs

None. The `placeholder` identifiers in the CFF generator are intentional first-pass offset objects that are replaced during deterministic fixture construction; they do not flow to UI or shipped evidence as empty data.

## Threat Flags

None. No new endpoint, authentication path, filesystem/runtime access, schema boundary, dependency, FFI seam, or production mutation hook was introduced.

## TDD Gate Compliance

- RED commits exist for all three tasks and precede their GREEN commits.
- Every RED identity failed for the intended missing assertion/dispatcher before implementation.
- All GREEN gates pass on their required targets.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Wave 5 can serialize exact public/private/hostile/glyf/correctness facts from closed, executable producers.
- No blocker, open stub, skipped test, or unrun verification remains.

## Self-Check: PASSED

All key files and all six task commits were verified on disk/history.

---
*Phase: 107-hostile-licensed-and-four-target-qualification*
*Completed: 2026-07-29*
