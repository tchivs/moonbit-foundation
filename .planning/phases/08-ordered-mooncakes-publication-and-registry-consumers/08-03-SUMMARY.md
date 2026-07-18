---
phase: 08-ordered-mooncakes-publication-and-registry-consumers
plan: "03"
subsystem: registry-consumer-qualification
tags: [mooncakes, cold-consumer, powershell, moonbit, registry-only, json-schema]
requires:
  - phase: 08-ordered-mooncakes-publication-and-registry-consumers
    plan: "02"
    provides: Closed Mooncakes observation policy, schema, and sanitized observer
provides:
  - Closed content-addressed cold registry consumer proof contract
  - Deterministic public behaviors for exact core, color, and image graph layers
  - Disposable credential-free four-target registry consumer runner with adversarial fixture validation
affects: [08-04-live-seam, 08-05-hosted-consumers, 08-06-ordered-publication, phase-09-provenance]
tech-stack:
  added: []
  patterns: [fresh-moon-home, curated-child-environment, semantic-graph-equality, canonical-proof-order, explicit-evidence-mode]
key-files:
  created:
    - release/consumers/proof-schema.json
    - qualification/registry-consumers/mb-core/main/main.mbt
    - qualification/registry-consumers/mb-color/main/main.mbt
    - qualification/registry-consumers/mb-image/main/main.mbt
    - scripts/quality/Invoke-ColdRegistryConsumer.ps1
    - scripts/quality/Test-ColdRegistryConsumer.ps1
  modified: []
key-decisions:
  - "Treat graph equality as semantic node-and-edge equality while serializing every accepted proof in canonical policy order."
  - "Mark fixture and live registry evidence explicitly so fixture validation can never be mistaken for a live distribution proof."
  - "Require cumulative exact 0.1.0 registry floors for core, color, and image consumers while prohibiting every alternate dependency source."
patterns-established:
  - "Cold consumer boundary: fresh external root, empty MOON_HOME, explicit toolchain, cleared child environment, and finally-bounded teardown."
  - "Distribution proof gate: exact observation, archive/manifest identity, graph, toolchain, four target runtimes, and behavior digest before verified output."
requirements-completed: [DIST-01, DIST-02, DIST-03, DIST-04]
coverage:
  - id: D1
    description: Closed cold-isolation and exact graph proof semantics
    requirement: DIST-04
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Test-ColdRegistryConsumer.ps1 -IsolationOnly"
        status: pass
    human_judgment: false
  - id: D2
    description: Deterministic documented public behavior templates for the one, two, and three-module graphs
    requirement: DIST-03
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Test-ColdRegistryConsumer.ps1 -BehaviorOnly"
        status: pass
      - kind: other
        ref: "moon fmt --check qualification/registry-consumers/mb-core/main/main.mbt qualification/registry-consumers/mb-color/main/main.mbt qualification/registry-consumers/mb-image/main/main.mbt"
        status: pass
    human_judgment: false
  - id: D3
    description: Disposable four-target runner and adversarial fixture gate with explicit non-live fixture evidence
    requirement: DIST-01
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Test-ColdRegistryConsumer.ps1"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Test-MooncakesObservation.ps1"
        status: pass
    human_judgment: false
duration: 28min
completed: 2026-07-18
status: complete
---

# Phase 8 Plan 3: Cold Registry Consumer Proof Summary

**A disposable credential-free runner now accepts only exact Mooncakes observations, canonical 0.1.0 graphs, pinned toolchains, real four-target runtime results, and deterministic public behavior before emitting a content-addressed proof.**

## Performance

- **Duration:** 28 minutes
- **Started:** 2026-07-18T10:36:16Z
- **Completed:** 2026-07-18T11:04:09Z
- **Tasks:** 3
- **Files created:** 6

## Accomplishments

- Defined a recursively closed verified-proof schema and 16 independent contamination fixtures covering checkout, Moon home, credentials, workspace, copied source, local/path/Git sources, registry/index/archive caches, `.mooncakes`, target output, and ambient toolchains.
- Added cumulative core, color, and image consumers that use documented public imports and produce stable checked arithmetic, quantization, and bounded strict PPM behavior.
- Implemented real and fixture runner paths that normalize `moon tree`, require observer/archive/manifest agreement, clear the child environment, execute `check`, `test`, and `run` on all four targets, reject compile-only Native evidence, and tear down the unique root in `finally`.
- Kept all autonomous evidence explicitly fixture-scoped; no live registry version, credential, tag, workflow dispatch, publication, workspace dependency, copied module source, or warm-cache proof was used.

## Task Commits

1. **Task 1 RED: failing cold proof contract** - `7990e13`
2. **Task 1 GREEN: closed isolation and graph semantics** - `4ed10d5`
3. **Task 2 RED: failing behavior and manifest contracts** - `aabbaaf`
4. **Task 2 GREEN: deterministic public behavior templates** - `4460178`
5. **Task 3: disposable four-target runner and adversarial fixtures** - `a1f5de4`

## Files Created

- `release/consumers/proof-schema.json` - Closed verified cold-consumer evidence contract with explicit fixture/live mode.
- `qualification/registry-consumers/mb-core/main/main.mbt` - Checked core, bytes, I/O, and host behavior.
- `qualification/registry-consumers/mb-color/main/main.mbt` - Core-backed typed color quantization behavior.
- `qualification/registry-consumers/mb-image/main/main.mbt` - Full-graph bounded strict PPM decode/re-encode behavior.
- `scripts/quality/Invoke-ColdRegistryConsumer.ps1` - Fresh-root registry resolution, observation, graph, target, behavior, and proof runner.
- `scripts/quality/Test-ColdRegistryConsumer.ps1` - Isolation, manifest, behavior, graph, target, missing-fact, and compile-only negatives.

## Decisions Made

- Graph comparison sorts nodes and directed edges for semantic equality, then emits the policy-owned canonical order so serialization differences cannot change proof identity.
- Fixture mode emits `evidence_mode: fixture`; only the real cold path can emit `evidence_mode: live_registry`.
- Each layer declares all canonical registry floors it imports: core has one, color has two, and image has three. No path, Git, workspace, local, copied-source, or cache fallback exists.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Used the actual PPM fixture contract after a stale read-first path**
- **Found during:** Task 2
- **Issue:** The plan referenced `fixtures/ppm/README.md`, which does not exist; the tracked fixture contract is `fixtures/ppm/cases.json`.
- **Fix:** Read and used `cases.json` together with the documented strict PPM public contract.
- **Files modified:** None beyond planned Task 2 artifacts.
- **Verification:** Behavior selector and MoonBit formatter passed.
- **Committed in:** `4460178`

**2. [Rule 2 - Missing Critical] Distinguished fixture evidence from live registry evidence**
- **Found during:** Task 3
- **Issue:** A schema-valid fixture proof without an explicit evidence mode could be mistaken for unavailable live registry proof.
- **Fix:** Added the required `evidence_mode` field and restricted the fixture and real runner paths to `fixture` and `live_registry` respectively.
- **Files modified:** `release/consumers/proof-schema.json`, `scripts/quality/Invoke-ColdRegistryConsumer.ps1`, `scripts/quality/Test-ColdRegistryConsumer.ps1`
- **Verification:** Full selector asserts every fixture proof is non-live and all negative fixtures fail before output.
- **Committed in:** `a1f5de4`

**Total deviations:** 2 auto-fixed: 1 blocking reference correction and 1 missing critical evidence distinction. **Impact:** Both preserve the planned fail-closed boundary without broadening publication scope.

## Issues Encountered

- Live registry execution was intentionally not attempted because the canonical module versions are not yet published. The real path is implemented; only explicitly marked fixture evidence was produced and deleted during tests.

## Known Stubs

None. The fixture seam is complete test machinery and is explicitly non-live; it is not a substitute for the live proof required after publication.

## User Setup Required

None - no credentials or external configuration were accessed or changed.

## Next Phase Readiness

- Later Phase 8 plans can invoke the real runner only after each exact registry version exists and an exact sanitized observer fixture is available.
- DIST live evidence remains absent, as required, until ordered publication occurs; no alternate source or cached result can satisfy the runner.

## Self-Check: PASSED

- All six declared files exist.
- Commits `7990e13`, `4ed10d5`, `aabbaaf`, `4460178`, and `a1f5de4` exist in history.
- Isolation, behavior, full adversarial, upstream observation, schema, and MoonBit formatting checks pass.
- Stub and threat-surface scans found no incomplete implementation or unmodeled trust boundary.

---
*Phase: 08-ordered-mooncakes-publication-and-registry-consumers*
*Completed: 2026-07-18*
