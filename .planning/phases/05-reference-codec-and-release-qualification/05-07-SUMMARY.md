---
phase: 05-reference-codec-and-release-qualification
plan: "07"
subsystem: release-qualification
tags: [moonbit, packaging, zip, sha256, source-isolation, release]

requires:
  - phase: 05-reference-codec-and-release-qualification/05-06
    provides: Correctness-gated benchmark qualification and frozen static/dynamic evidence boundaries
  - phase: 01-foundation-charter-and-reproducible-workspace
    provides: Exact candidate manifests, package inventories, target policy, and topological module order
provides:
  - Two-clean-copy deterministic package lists and byte-identical ZIP evidence for all three modules
  - Exact extracted mb-core artifact consumption on all four required targets without moon.work
  - Honest downstream copied-source success and unpublished-registry blocking without path rewrites
  - Closed post-publication order contract and fail-closed Required qualification
affects: [05-08-final-verification, WORK-06, QUAL-06, release-publication]

tech-stack:
  added: []
  patterns:
    - Package artifacts are compared from two clean local clones at the same committed HEAD
    - Artifact, copied-source, and registry-resolution evidence remain distinct outcomes
    - Dynamic reports are ignored while policy and schema remain tracked and closed

key-files:
  created:
    - policy/release-qualification.json
    - release/qualification/package-schema.json
    - scripts/quality/ReleaseQualification.Common.ps1
    - scripts/quality/Invoke-ReleaseQualification.ps1
    - scripts/quality/Test-ReleaseQualification.ps1
    - qualification/consumers/mb-core/main/main.mbt
    - qualification/consumers/downstream-public/main.mbt
  modified:
    - scripts/quality.ps1
    - .gitignore

key-decisions:
  - "Treat the foundation publication inventory as a closed set while comparing the packer's actual ordered list exactly across two clean copies."
  - "Qualify mb-core by extracting the exact ZIP as a no-moon.work module root and adding only the checked public consumer package."
  - "Keep mb-color and mb-image artifact consumption blocked until published dependencies resolve; copied-source success cannot substitute for registry resolution."

patterns-established:
  - "Release reports state publication=false and credentials_read=false; Required never invokes publish or reads credentials."
  - "Post-publication qualification is strictly publish/resolve core, then color, then image at exact 0.1.0 constraints."

requirements-completed: [WORK-06, QUAL-06]

coverage:
  - id: D1
    description: All three modules produce identical ordered package lists and exact ZIP bytes, hashes, sizes, entries, and manifests in two clean same-HEAD copies.
    requirement: QUAL-06
    verification:
      - kind: integration
        ref: "scripts/quality/Invoke-ReleaseQualification.ps1#two clean-copy package builds"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false
  - id: D2
    description: The exact extracted mb-core package ZIP supports a public consumer on js, wasm, wasm-gc, and native with no moon.work.
    requirement: WORK-06
    verification:
      - kind: integration
        ref: "qualification/consumers/mb-core/main/main.mbt; Invoke-CoreArtifactConsumer check+test all required targets"
        status: pass
    human_judgment: false
  - id: D3
    description: mb-color and mb-image copied-source consumers pass while unchanged no-workspace named dependencies remain explicitly blocked by the unpublished namespace.
    requirement: QUAL-06
    verification:
      - kind: integration
        ref: "Invoke-SourceIsolation and Invoke-RegistryProbe for mb-color and mb-image"
        status: pass
      - kind: integration
        ref: "scripts/quality/Test-ReleaseQualification.ps1#REL01-REL07"
        status: pass
    human_judgment: false

duration: 49min
completed: 2026-07-17
status: complete
---

# Phase 5 Plan 7: Deterministic Release Qualification Summary

**Two clean same-HEAD builds now prove exact candidate ZIP determinism while extracted-core, copied-source, and unpublished-registry outcomes remain explicitly separated.**

## Performance

- **Duration:** 49 min
- **Completed:** 2026-07-17
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Produced byte-identical package ZIPs in two clean full-repository clones with exact ordered `moon package --frozen --list` comparison, closed archive inventories, source-identical manifests, SHA-256, and byte sizes.
- Qualified the exact extracted `mb-core` ZIP through a public black-box consumer on `js`, `wasm`, `wasm-gc`, and `native`, with no `moon.work` or registry/path substitution.
- Proved `mb-color` and `mb-image` copied-source isolation on all four targets while preserving both unchanged no-workspace named dependency probes as `blocked_unpublished_namespace`.
- Added seven fail-closed policy mutations, report round-trip checks, tracked-diff protection, ignored dynamic reports, and Required-lane integration.

## Package Evidence

| Module | SHA-256 | ZIP bytes | Exact two-copy result |
|---|---|---:|---|
| mb-core | `290cf0d8ba41bcf691f1d00463c1bdcbd0ca31aba68b33ec9400d90a7460e5c3` | 37,596 | list, bytes, entries, manifest pass |
| mb-color | `f32fa9b70b9570aa5dac3dc76b7ed09015bf958af388f927c67018e15c64b475` | 26,163 | list, bytes, entries, manifest pass |
| mb-image | `800f415e5e1686b3f4ce33f8275e205319decbd4488567fd9c57aa72f7c786cd` | 68,221 | list, bytes, entries, manifest pass |

## Task Commits

1. **RED release qualification contract** - `e37adcd`
2. **Closed release policy and schema** - `d4d3988`
3. **Deterministic packages and isolated consumers** - `2572544`

## Files Created/Modified

- `policy/release-qualification.json` - Closed manifests, dependencies, contents, outcomes, provenance, and post-publication order.
- `release/qualification/package-schema.json` - Closed machine-readable report contract.
- `scripts/quality/ReleaseQualification.Common.ps1` - Canonical policy, schema, digest, path, and read-only helpers.
- `scripts/quality/Invoke-ReleaseQualification.ps1` - Clean cloning, deterministic packaging, archive inspection, consumers, probes, and report generation.
- `scripts/quality/Test-ReleaseQualification.ps1` - Seven static negatives plus the complete dynamic qualification.
- `qualification/consumers/mb-core/` - Exact named dependency manifest and all-public-package core consumer.
- `qualification/consumers/downstream-public/main.mbt` - Unchanged shared source for source-isolation and registry probes.
- `scripts/quality.ps1` - Required-lane release qualification integration.
- `.gitignore` - Dynamic release evidence exclusion at every nested output path.

## Decisions Made

- Compared actual ordered packer output between clean copies, while treating the foundation publication list as a closed set because the packer has its own stable ordering.
- Used the pinned toolchain's strongest honest local-artifact seam: exact core ZIP extraction without `moon.work`; no unsupported local library install was fabricated.
- Retained downstream artifact and registry blockers until exact dependencies are published and independently resolvable in topological order.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added Required wrapper and nested dynamic-evidence ignore**
- **Found during:** Task 2
- **Issue:** The plan required negative and Required integration, but the explicit file list omitted the wrapper and root lane files; the existing one-level ignore did not cover the requested nested output directory.
- **Fix:** Added `Test-ReleaseQualification.ps1`, invoked it from Required, and ignored the complete dynamic release evidence subtree.
- **Files modified:** `scripts/quality/Test-ReleaseQualification.ps1`, `scripts/quality.ps1`, `.gitignore`
- **Verification:** Seven mutations reject and the full Required lane passes read-only.
- **Committed in:** `e37adcd`, `2572544`

**2. [Rule 1 - Bug] Compared packer order independently from policy inventory order**
- **Found during:** Task 2 focused qualification
- **Issue:** The pinned packer emits a stable module-specific order that differs from the foundation policy's inventory order for mb-color.
- **Fix:** Require an exact closed inventory set and separately require byte-for-byte ordered list equality between both clean copies.
- **Files modified:** `scripts/quality/Invoke-ReleaseQualification.ps1`
- **Verification:** All three ordered lists match across both clean copies and every inventory remains closed.
- **Committed in:** `2572544`

---

**Total deviations:** 2 auto-fixed (1 missing critical integration, 1 classifier bug)
**Impact on plan:** Both fixes strengthen the requested evidence without broadening release scope or changing publication state.

## Issues Encountered

- The pinned CLI has no verified local library-ZIP installation flow. The locked D-22 fallback was applied exactly: only the leaf core artifact receives a true no-workspace artifact-consumer pass; downstream artifact and registry outcomes stay blocked.

## User Setup Required

None - qualification never publishes, requests credentials, or requires external configuration.

## Verification

- Focused release qualification: passed all seven negatives, three deterministic packages, the exact core artifact consumer, two copied-source consumers, and two expected registry blockers.
- Full Required lane: passed with 197/197 tests on each of `js`, `wasm`, `wasm-gc`, and `native`, exact interfaces/docs/package inventories, and read-only tracked checkout proof.

## Self-Check: PASSED

- Summary and all eleven implementation files exist.
- Commits `e37adcd`, `d4d3988`, and `2572544` exist.
- No known stubs or unplanned threat surfaces remain.

## Next Phase Readiness

- Plan 05-08 can run final two-pass Required verification and requirement-to-evidence closure.
- Real publication remains intentionally blocked until the namespace is verified and an explicit human action follows the recorded core → color → image order.

---
*Phase: 05-reference-codec-and-release-qualification*
*Completed: 2026-07-17*
