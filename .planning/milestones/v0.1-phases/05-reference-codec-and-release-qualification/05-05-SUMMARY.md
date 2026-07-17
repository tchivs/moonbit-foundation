---
phase: 05-reference-codec-and-release-qualification
plan: "05"
subsystem: candidate-documentation
tags: [moonbit, release-candidate, documentation, metadata, provenance, qualification]

requires:
  - phase: 05-reference-codec-and-release-qualification/05-04
    provides: Public portable and Native injected examples with source-isolation and registry-resolution outcomes
  - phase: 01-foundation-charter-and-reproducible-workspace
    provides: Canonical module, publication, target, stability, and fixture policies
provides:
  - Exact runnable 0.1.0 candidate documentation and changelogs for all three modules
  - Manifest repository, description, license, version, targets, and named dependency qualification
  - Fail-closed QUAL-04 checker for docs, support, DAG, provenance, examples, and prohibited claims
affects: [05-07-release-qualification, 05-08-final-verification, QUAL-04]

tech-stack:
  added: []
  patterns:
    - Policy-derived exact public DAG fingerprints embedded as machine-compared documentation data
    - Generated temporary negative mutations keyed by stable QUAL04 rule IDs

key-files:
  created:
    - docs/release/v0.1-candidate.md
    - scripts/quality/Test-CandidateDocumentation.ps1
  modified:
    - modules/mb-core/README.mbt.md
    - modules/mb-core/CHANGELOG.md
    - modules/mb-core/moon.mod.json
    - modules/mb-color/README.mbt.md
    - modules/mb-color/CHANGELOG.md
    - modules/mb-color/moon.mod.json
    - modules/mb-image/README.mbt.md
    - modules/mb-image/CHANGELOG.md
    - modules/mb-image/moon.mod.json
    - policy/foundation.json
    - scripts/quality/Invoke-MoonQuality.ps1

key-decisions:
  - "Use https://github.com/moonbit-foundation/moonbit-foundation as the exact repository metadata value while publication remains separately blocked by the unverified namespace."
  - "Represent the complete public package DAG as policy-derived ordered fingerprints so documentation drift fails closed without creating a second policy owner."
  - "Keep source_isolation: pass separate from registry_resolution: blocked_unpublished_namespace and make both exact candidate-documentation claims."

patterns-established:
  - "Candidate docs state support and exclusions together: four required targets, candidate compatibility, and no stable, publication, full-codec, LLVM, or marketing claim."
  - "Documentation negatives mutate temporary copies and require the exact owning QUAL04 rule ID."

requirements-completed: [QUAL-04]

coverage:
  - id: D1
    description: Every candidate module exposes runnable docs, exact support and compatibility, changelog, DAG, license, fixture provenance, and deferred scope aligned with its manifest.
    requirement: QUAL-04
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Test-CandidateDocumentation.ps1"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality.ps1 -Lane Required; 197/197 tests per required target"
        status: pass
    human_judgment: false
  - id: D2
    description: Candidate documentation fails closed on missing facts, metadata drift, non-runnable examples, and positive stable/full-PPM/published/LLVM/marketing claims.
    requirement: QUAL-04
    verification:
      - kind: integration
        ref: "scripts/quality/Test-CandidateDocumentation.ps1#generated negative mutation matrix"
        status: pass
    human_judgment: false

duration: 18min
completed: 2026-07-17
status: complete
---

# Phase 5 Plan 5: Candidate Documentation and Claim Qualification Summary

**Three independently versioned modules now expose exact runnable candidate contracts, and a fail-closed gate prevents metadata, provenance, support, example, or claim drift**

## Performance

- **Duration:** 18 min
- **Started:** 2026-07-17T01:19:30Z
- **Completed:** 2026-07-17T01:37:33Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments

- Added exact `0.1.0` candidate metadata, support matrices, compatibility language, package DAGs, fixture identities/digests, runnable examples, changelogs, and deferred boundaries for mb-core, mb-color, and mb-image.
- Documented the codec only as the MNF strict PPM P6/sRGB subset, linked both public consumers, and preserved `source_isolation: pass` alongside `registry_resolution: blocked_unpublished_namespace`.
- Added seven stable QUAL04 rule IDs with positive validation and generated negative cases for missing docs/support/DAG/provenance/examples, manifest drift, and prohibited claims.
- Integrated the candidate gate into Required; the final run passed 197/197 tests on each required target plus exact interfaces, package inventories, documentation generation, and tracked read-only proof.

## Task Commits

1. **Task 1: Publish exact candidate docs and manifest metadata** - `f8f5199` (docs)
2. **Task 2 RED: Define failing candidate documentation gate** - `0947a34` (test)
3. **Task 2 GREEN: Enforce candidate documentation qualification** - `3b20902` (test)
4. **Task 2 verification fix: Preserve bounded PPM ownership statement** - `f833b28` (fix)

## Files Created/Modified

- `docs/release/v0.1-candidate.md` - Cross-module metadata, support, DAG, examples, provenance, blocker, and deferred-scope index.
- `scripts/quality/Test-CandidateDocumentation.ps1` - Exact positive checks and generated negative matrix with stable rule IDs.
- `scripts/quality/Invoke-MoonQuality.ps1` - Required QUAL-04 stage integration.
- `modules/mb-{core,color,image}/README.mbt.md` - Runnable candidate contracts, support, provenance, and deferred scope.
- `modules/mb-{core,color,image}/CHANGELOG.md` - Explicit unpublished 0.1.0 candidate records.
- `modules/mb-{core,color,image}/moon.mod.json` - Exact description and repository metadata alongside existing version/license/target/dependency facts.
- `policy/foundation.json` - Canonical module description and repository values consumed by the checker.

## Decisions Made

- Repository metadata is exact in policy and manifests, while publication and namespace verification remain independent blocked outcomes.
- Documentation carries an exact ordered DAG fingerprint derived from policy; prose remains readable while automation compares the complete edge set.
- Positive claims are rejected through explicit synthetic markers so real, correctly negated boundary prose is not falsely classified.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced unsupported planned `moon doc --target --source-map` invocation**
- **Found during:** Task 1 verification
- **Issue:** The pinned `moon doc` command rejects `--target`; the plan-level command could not execute.
- **Fix:** Used the verified module-local `moon -C modules/<module> doc --frozen` seam and separately checked every literate README on all four explicit targets.
- **Files modified:** None.
- **Verification:** Three module docs and twelve module/target README checks passed.
- **Committed in:** Not applicable; verification-only adjustment.

**2. [Rule 1 - Bug] Restored the exact bounded PPM ownership sentence required by the existing image documentation gate**
- **Found during:** First full Required run
- **Issue:** Reframing the deferred-scope paragraph removed an exact existing phrase consumed by `Assert-ImageReadmeContract`.
- **Fix:** Restored the sentence and immediately qualified it as the MNF strict PPM P6/sRGB subset.
- **Files modified:** `modules/mb-image/README.mbt.md`
- **Verification:** Focused image prohibitions, candidate checker, and complete Required rerun passed.
- **Committed in:** `f833b28`

**Total deviations:** 2 auto-fixed (1 blocking verification mismatch, 1 documentation-gate regression). **Impact:** No public API or codec scope changed; verification is stronger than the invalid planned command.

## Issues Encountered

- The Required lane intentionally prints the missing-README negative fixture error before confirming rejection; the enclosing gate and final lane exit are successful.

## User Setup Required

None.

## Verification

- `pwsh -NoProfile -File scripts/quality/Test-CandidateDocumentation.ps1`: passed all positive checks and generated negative mutations.
- `moon -C modules/<module> doc --frozen`: passed for mb-core, mb-color, and mb-image.
- Literate README checks: passed for all three modules on js, wasm, wasm-gc, and native.
- Public examples: portable all-target and Native injected adapter passed.
- `pwsh -NoProfile -File scripts/quality.ps1 -Lane Required`: passed in 111.3 seconds with 197/197 workspace tests per required target and read-only proof.

## Self-Check: PASSED

- Both created files and all eleven modified production/documentation files exist.
- Commits `f8f5199`, `0947a34`, `3b20902`, and `f833b28` resolve in repository history.
- No TODO, FIXME, placeholder, stable/publication/full-codec/LLVM/performance claim, path dependency, or fabricated registry pass was introduced.

## Next Phase Readiness

- Plan 05-06 can freeze benchmark schema/baselines against exact candidate documentation without broadening claims.
- Plan 05-07 can consume the canonical manifest repository/description facts and the honest unpublished-namespace outcome for release qualification.

---
*Phase: 05-reference-codec-and-release-qualification*
*Completed: 2026-07-17*
