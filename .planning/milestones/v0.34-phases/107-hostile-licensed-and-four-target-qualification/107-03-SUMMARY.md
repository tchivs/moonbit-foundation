---
phase: 107-hostile-licensed-and-four-target-qualification
plan: 03
subsystem: testing
tags: [cff1, evidence-carrier, moonbit, four-target, frozen-resolution, private-oracles]

requires:
  - phase: 107-hostile-licensed-and-four-target-qualification
    plan: 02
    provides: Exact licensed Source Sans and Source Han payloads, normalized two-reader facts, provenance, and hostile corpus
provides:
  - Non-published four-target evidence module resolved only from tracked local mb-core and mb-font workspace members
  - One package-private generated literal owner for each licensed CFF1 payload
  - Closed public, hostile, compatibility, target, workload, B8, workflow, and precedence facts
  - Exact private oracle/mirror checks and repository-wide single-owner enforcement
affects: [107-04, 107-05, 107-06, CFF-06]

tech-stack:
  added: []
  patterns: [link-free temporary moon.work, empty-cache frozen resolution, generator-owned private regions, single literal payload ownership]

key-files:
  created:
    - benchmarks/font-cff/moon.mod.json
    - benchmarks/font-cff/moon.pkg
    - benchmarks/font-cff/generated_cff_evidence.mbt
    - benchmarks/font-cff/cff_qualification_wbtest.mbt
  modified:
    - scripts/fixtures/Generate-FontQualification.ps1

key-decisions:
  - "The evidence module is version 0.0.0, non-published, supports js/wasm/wasm-gc/native, and resolves tchivs/mb-font@0.1.0 only through explicit tracked workspace members."
  - "Licensed Source Sans and Source Han bytes each have one generated package-private MoonBit literal body; all carrier accessors reuse those bodies."
  - "Wave 4 private regions are generator-owned: absent markers are left untouched in this plan, while present regions must match canonical byte-for-byte rendering."
  - "Compatibility and workload facts remain closed producer data, including twelve workflow IDs, two static-glyf locks, B8 ordering, four targets, four workloads, and precedence rows."

patterns-established:
  - "Evidence compilation uses a fresh link-free temporary workspace, independent target directory, empty external cache, --frozen, and exact manifest/interface digests."
  - "Private evidence check modes reconstruct only canonical corpus and two-reader facts and validate exact source locators before comparing delimited regions."
  - "Normal generation and -Check render the 26 MB carrier from tracked inputs, with LF UTF-8 and exact byte comparison."

requirements-completed: [CFF-06]

coverage:
  - id: D1
    description: The non-published evidence module resolves only the tracked local public mb-font package on all four targets.
    requirement: CFF-06
    verification:
      - kind: integration
        ref: "Generate-FontQualification.ps1 -CheckEvidencePackage -Target native/js/wasm/wasm-gc"
        status: pass
    human_judgment: false
  - id: D2
    description: A single package-private carrier owns each licensed payload and closed public/hostile/compatibility/workload facts.
    requirement: CFF-06
    verification:
      - kind: integration
        ref: "Generate-FontQualification.ps1 -Check/-CheckSinglePayloadOwner/-CheckPublicPrivateBoundary"
        status: pass
    human_judgment: false
  - id: D3
    description: Private FD/oracle and hostile/mutation/B8 projections are canonical, locator-bound, and ready for Wave 4 materialization.
    requirement: CFF-06
    verification:
      - kind: integration
        ref: "Generate-FontQualification.ps1 -CheckPrivateOracleFacts/-CheckPrivateEvidenceMirrors"
        status: pass
    human_judgment: false

duration: 24min
completed: 2026-07-29
status: complete
---

# Phase 107 Plan 03: Closed CFF Evidence Carrier Summary

**Four-target local-only MoonBit evidence module with single-owner licensed CFF payloads, closed generated facts, and exact generator-owned private mirror contracts**

## Performance

- **Duration:** 24 min
- **Started:** 2026-07-29T03:13:00Z
- **Completed:** 2026-07-29T03:35:42Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a non-published `moonbit-foundation/font-cff-evidence@0.0.0` module supporting js, wasm, wasm-gc, and native while resolving `tchivs/mb-font@0.1.0` only from the tracked workspace under `--frozen`.
- Generated one package-private literal body each for the exact 334,924-byte Source Sans and 6,210,796-byte Source Han payloads, plus deterministic standalone/collection accessors and six closed public semantic facts.
- Generated all 53 hostile rows, twelve workflow IDs, two compatibility locks, the eight-field B8 order, six generated workflows, two precedence facts, four targets, and four fixed workloads from canonical producer data.
- Added exact `-CheckPrivateOracleFacts`, `-CheckPrivateEvidenceMirrors`, and `-CheckSinglePayloadOwner` modes without modifying the downstream Wave 4 white-box files.

## Task Commits

Each task followed the required TDD RED/GREEN sequence:

1. **Task 1: Prove tracked public font resolution** — `6882458f` (RED), `af465902` (GREEN)
2. **Task 2: Generate the single carrier and close private mirror modes** — `61a184af` (RED), `4406186f` (GREEN)

## Files Created/Modified

- `benchmarks/font-cff/moon.mod.json` — exact non-published four-target evidence module identity and sole system-under-test dependency.
- `benchmarks/font-cff/moon.pkg` — public font and benchmark imports with no export surface.
- `benchmarks/font-cff/cff_qualification_wbtest.mbt` — carrier visibility, payload identity, closed fact counts, and public `FontLimits` tracer.
- `benchmarks/font-cff/generated_cff_evidence.mbt` — generated package-private licensed bytes and closed evidence facts.
- `scripts/fixtures/Generate-FontQualification.ps1` — canonical rendering, frozen local workspace proof, private region checks, and single-owner enforcement.

## Decisions Made

- Used explicit absolute canonical workspace members only inside a fresh temporary `moon.work`; aliases, substitutions, reparse points, wrong names/versions/digests, cache fallback, private references, and public exports are rejected.
- Kept licensed byte mirrors exclusively in the evidence module and reconstructed carrier accessors from those bodies; no licensed bytes, dependency, or fixture API entered production `modules/mb-font`.
- Made private-region checks read-only in this plan: they validate canonical in-memory rendering and exact source locators now, then byte-compare regions once Wave 4 adds the agreed markers.
- Preserved compatibility facts as producer-rendered data instead of allowing downstream tests to infer or complete expected values.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved later manifest records during legacy collection regeneration**
- **Found during:** Task 2 default generator verification
- **Issue:** The Phase 103 collection-manifest helper assumed the repository forever contained exactly 11 or 14 records and rejected the valid 20-record Phase 107 manifest.
- **Fix:** Kept exact validation of the first fourteen records while preserving the already validated later licensed-CFF suffix during regeneration.
- **Files modified:** `scripts/fixtures/Generate-FontQualification.ps1`
- **Verification:** Default generation and `-Check` both pass without modifying `fixtures/manifest.json`.
- **Committed in:** `4406186f`

**2. [Rule 1 - Bug] Rendered canonical MoonBit boolean literals**
- **Found during:** Task 2 native evidence compile
- **Issue:** PowerShell interpolation emitted malformed hostile/workload boolean tokens in the first generated carrier.
- **Fix:** Rendered explicit `true`/`false` literals from each canonical Boolean before source generation.
- **Files modified:** `scripts/fixtures/Generate-FontQualification.ps1`, `benchmarks/font-cff/generated_cff_evidence.mbt`
- **Verification:** Frozen native compilation and all three portable target checks pass; both MoonBit format checks pass.
- **Committed in:** `4406186f`

---

**Total deviations:** 2 auto-fixed Rule 1 bugs.
**Impact on plan:** Both fixes were required for the mandated generator and four-target verification; neither changes the production font API, dependency graph, licensed payloads, or downstream white-box files.

## Issues Encountered

- The evidence carrier is intentionally large (26,418,364 bytes) because it is the sole MoonBit literal owner of both exact licensed payloads; generation and format verification remain deterministic.
- MoonBit reports expected unused private evidence warnings before Wave 4 consumes all closed fields; compilation succeeds on all four targets.

## TDD Gate Compliance

- Task 1 RED `6882458f` failed because the evidence module/import did not yet exist; GREEN `af465902` passed the frozen native resolution gate and tracer feedback gate.
- Task 2 RED `61a184af` failed on missing package-private payload/fact functions; GREEN `4406186f` passed exact regeneration, private modes, single-owner, boundary, format, and four-target gates.

## Known Stubs

None. Empty GID lists belong to the declared full-admission workloads, optional `None` hostile fields encode inapplicable facts, and absent downstream private markers intentionally defer materialization to Plan 107-04 without weakening the in-memory contracts.

## Authentication Gates

None.

## Threat Flags

No unplanned threat surface was introduced. Temporary filesystem workspaces, local module resolution, licensed literal storage, private fact projection, and package boundaries are declared by T-107-03-01 through T-107-03-05 and covered by negative tests and exact digests.

## User Setup Required

None.

## Self-Check: PASSED

- Confirmed all five plan files and this summary exist in the dedicated worktree.
- Confirmed RED/GREEN commits `6882458f`, `af465902`, `61a184af`, and `4406186f` exist.
- Confirmed the complete plan verification and all four target-resolution checks pass.
