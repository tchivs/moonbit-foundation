---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "06"
subsystem: release-automation
tags: [powershell, github-actions, mooncakes, authority-union, cold-consumer, fail-closed]

requires:
  - phase: 08-05
    provides: fresh r1 release intent, exact actor policy, and historical/current authority separation
provides:
  - clean-clone-bound hosted controller with a closed operation and outcome switch
  - exclusive core-entry MutationAuthorizationPacket or ExactExistingAuthority union
  - normalized exact-existing and published-now successor authority records
  - deterministic public-surface, observation, and cold-proof indexing contracts
affects: [08-07, 08-08, phase-09-provenance]

tech-stack:
  added: []
  patterns:
    - durable execution-root and boundary-SHA locator with per-use Git blob verification
    - source-discriminated normalized module authority with explicit predecessor records
    - exact-existing observer-to-cold path that cannot reach publication

key-files:
  created:
    - release/qualification/phase-08-authority-schema.json
  modified:
    - scripts/quality/Invoke-Phase08HostedRun.ps1
    - scripts/quality/Test-Phase08Qualification.ps1
    - scripts/quality/Test-Phase08LiveSeam.ps1
    - .github/workflows/publish-modules.yml
    - scripts/quality/Get-MooncakesObservation.ps1
    - scripts/quality/Test-MooncakesObservation.ps1
    - scripts/quality/Invoke-ColdRegistryConsumer.ps1
    - scripts/quality/Test-ColdRegistryConsumer.ps1

key-decisions:
  - "Bind every hosted helper use to one clean r1 execution root, HEAD, and exact Git blob before any dispatch, poll, download, selector, or script invocation."
  - "Accept exactly one core-entry authority variant: absent may yield a MutationAuthorizationPacket, while exact yields zero-mutation ExactExistingAuthority and can never reach PublishOne."
  - "Keep DIST-01 through DIST-04 and PROV-05 pending until live publication and live registry-only evidence actually exist."

patterns-established:
  - "Closed outcome switch: absent is a non-mutating candidate, exact closes authority without republish, mismatch requires forward correction, and unknown/disagreement/timeout stop."
  - "Successor authority always names and hashes its unique predecessor; the core mutation packet is never reused as downstream authorization."

requirements-completed: []

coverage:
  - id: D1
    description: Clean-clone controller, locator, authority union, resume switch, and normalized predecessor contracts
    verification:
      - kind: integration
        ref: "Test-Phase08Qualification.ps1 -FixtureOnly plus Test-ReleasePublisherNegative.ps1 -ReducerOnly"
        status: pass
    human_judgment: false
  - id: D2
    description: Exact r1 hosted workflow with actor-bound dry-run, secret-free preflight/observation, and one-module publication reachability
    verification:
      - kind: integration
        ref: "Test-Phase08LiveSeam.ps1 plus Phase 7 and prepared-bundle workflow selectors"
        status: pass
    human_judgment: false
  - id: D3
    description: Bounded structured observation and four-target native cold-proof paths for exact-existing and post-publish evidence
    verification:
      - kind: integration
        ref: "Test-MooncakesObservation.ps1, Test-ColdRegistryConsumer.ps1, and Invoke-MoonQuality.ps1 -Required"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-07-19
status: complete
---

# Phase 08 Plan 06: Hosted Static Seam Summary

**A clean-r1 hosted controller now closes publication authority as an exclusive mutation-packet/exact-existing union and carries both published-now and no-republish paths through indexed observation, four-target cold proof, and explicit predecessor authority.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-07-18T19:00:57Z
- **Completed:** 2026-07-18T19:20:59Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Added all eleven hosted controller modes, a durable execution locator, clean HEAD and Git-blob checks, and a tested closed switch for absent, exact, mismatch, unknown, disagreement, and timeout outcomes.
- Added a closed authority schema and selectors for `MutationAuthorizationPacket`, `ExactExistingAuthority`, the exclusive `AuthorityUnion`, and source-discriminated normalized core/color/image authority records with explicit predecessor and reducer evidence.
- Rebound the hosted workflow to `refs/tags/modules-v0.1.0-r1`, preserved the fail-closed reachable-channel toolchain setup from `6fe0c1f`, separated actor stdout/stderr, and kept exact-existing observation outside publisher reachability.
- Required explicit clone-rooted policy/schema inputs, exact 20-attempt/15-second observation semantics, deterministic exact-existing/post-publish surface indexes, and real four-target/native cold evidence.

## Task Commits

Each task was committed atomically with RED then GREEN evidence:

1. **Task 1: Build the clean-clone controller and closed resume switch**
   - `efc9dc7` — failing hosted authority seam fixtures
   - `810fa9d` — clean-clone controller, authority schema, union, and selectors
2. **Task 2: Wire exact hosted jobs and actor-bound authorization**
   - `d601d88` — failing hosted workflow authority fixtures
   - `231f538` — r1 hosted jobs, actor isolation, exact-existing path, and one-module reachability
3. **Task 3: Complete live observation and cold-proof fixture coverage**
   - `6ed7c28` — failing explicit observation/cold binding fixtures
   - `4f909f2` — explicit inputs, cadence enforcement, and deterministic phase indexes

Additional correctness commit:

- `2b08e2d` — require real reducer and historical-negative records instead of synthetic digest sentinels

Existing hosted setup correction retained and verified:

- `6fe0c1f` — changed five hosted setup sites to the reachable channel with immediate exact executable hash/version checks. This pre-existing Plan 08-06-owned correction was reused without duplication or reversal.

## Files Created/Modified

- `release/qualification/phase-08-authority-schema.json` — closed packet, exact-existing, and published-now authority variants.
- `scripts/quality/Invoke-Phase08HostedRun.ps1` — durable boundary, all hosted modes, closed outcome switch, artifact index, authority selection, and no-republish guard.
- `scripts/quality/Test-Phase08Qualification.ps1` — boundary, outcome, authority-union, selector, predecessor, and schema fixtures.
- `.github/workflows/publish-modules.yml` — exact r1 hosted mode inputs, actor-isolated dry-run, secret-free exact-existing path, and explicit observer/cold inputs.
- `scripts/quality/Test-Phase08LiveSeam.ps1` — hosted toolchain, actor ambiguity, workflow reachability, secret isolation, and stale/duplicate selection fixtures.
- `scripts/quality/Get-MooncakesObservation.ps1` — explicit policy/schema binding and locked polling cadence validation.
- `scripts/quality/Test-MooncakesObservation.ps1` — malformed/secret/drift/cadence fixtures plus exact-existing/post-publish surface indexing.
- `scripts/quality/Invoke-ColdRegistryConsumer.ps1` — explicit policy/schema production bindings for registry-only proof.
- `scripts/quality/Test-ColdRegistryConsumer.ps1` — explicit-input, isolation, graph, four-target, native-runtime, and digest adversarial coverage.

## Decisions Made

- `ExactExistingAuthority` requires real indexed observation, cold proof, reducer record, and historical-negative record. It contains no mutation packet, actor evidence, dry-run authorization, or mutation count.
- Core mutation may begin only from `MutationAuthorizationPacket`; color and image eligibility comes from their unique normalized predecessor authority and reducer state.
- Local fixture evidence is never represented as live registry proof, and no live requirement is completed by static seam verification.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Replaced synthetic reducer digest with explicit authority evidence**

- **Found during:** Final adversarial owned-file scan
- **Issue:** The first exact-existing record builder used a zero digest sentinel for the reducer record, which could make structurally valid authority without real reducer evidence.
- **Fix:** Required explicit reducer and historical-negative files, validated the reducer's exact module/state/root/current observation bindings, and content-bound the historical `29652468948/1` terminal failure.
- **Files modified:** `scripts/quality/Invoke-Phase08HostedRun.ps1`, `release/qualification/phase-08-authority-schema.json`, `.github/workflows/publish-modules.yml`
- **Verification:** Full local Phase 8 qualification, live-seam, observation, cold-consumer, Required, and diff checks passed.
- **Committed in:** `2b08e2d`

---

**Total deviations:** 1 auto-fixed (1 missing critical functionality).
**Impact on plan:** The fix strengthens the planned authority boundary without expanding external behavior or performing any live action.

## Issues Encountered

- The prior hosted setup failure had already been corrected in `6fe0c1f`; the current execution audited, retained, and reverified it rather than duplicating the change.
- The worktree contained unrelated user changes and caches. They were preserved and never staged.

## Known Stubs

None. Unavailable public facts are modeled as explicit sanitized `unknown` outcomes that stop; they are not empty live evidence or future-feature placeholders.

## Threat Flags

None. The new workflow/controller/observer/cold surfaces are the trust boundaries explicitly covered by the Plan 08-06 threat model and corresponding adversarial fixtures.

## User Setup Required

None. This plan was entirely local, credential-free, and non-mutating.

## Live Requirements

`DIST-01`, `DIST-02`, `DIST-03`, `DIST-04`, and `PROV-05` remain pending. No GitHub workflow was dispatched, no secret was accessed, no tag/ref was changed, no HTTP/registry observation ran, and no `moon publish` command executed.

## Next Phase Readiness

- Phase 8 is 6/8 plans complete; Plan 08-07 is next.
- Plan 08-07 can verify the exact completion HEAD and static hosted seam before any separately authorized external action.
- There are no local blockers, but live distribution claims remain gated on actual publication and registry-only evidence.

## Self-Check: PASSED

All nine declared files exist, all seven Plan 08-06 commits and the reused `6fe0c1f` setup correction exist, all plan verification commands pass locally, and the owned-file stub scan is clean.

---
*Phase: 08-ordered-mooncakes-publication-and-registry-consumers*
*Completed: 2026-07-19*
