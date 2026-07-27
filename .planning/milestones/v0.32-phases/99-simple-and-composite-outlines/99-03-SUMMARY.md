---
phase: 99-simple-and-composite-outlines
plan: 03
subsystem: font-outline-qualification
tags: [moonbit, truetype, path2, q15, policy, four-target]

requires:
  - phase: 99-simple-and-composite-outlines
    plan: 01
    provides: Guarded simple-outline Path2 extraction and retained outline limits
  - phase: 99-simple-and-composite-outlines
    plan: 02
    provides: Bounded one-level composite traversal, transforms, and attachment
provides:
  - One checksum-correct generated public workflow covering empty, repeated/implied simple, and transformed/attached composite outlines
  - Exact Phase 99 generated interface and independent fail-closed publication policy
  - Executable four-target package documentation, candidate changelog, and synchronized English/Chinese discovery text
affects: [100-real-font-qualification, mb-font-publication, font-policy]

tech-stack:
  added: []
  patterns:
    - One generated font proves the public workflow identically on all four targets
    - Generated semantic interface is copied verbatim into policy and approved independently
    - Documentation distinguishes generated portable evidence from licensed real-font qualification

key-files:
  created: []
  modified:
    - modules/mb-font/font/font_test.mbt
    - modules/mb-font/font/font_wbtest.mbt
    - modules/mb-font/font/generated_fonts_wbtest.mbt
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - modules/mb-font/README.mbt.md
    - modules/mb-font/CHANGELOG.md
    - README.md

key-decisions:
  - "Use glyph zero as empty, glyph one as the repeated-flag/implied-midpoint simple outline, and glyph two as the transformed plus real-point-attached composite in the permanent portable fixture."
  - "Keep pkg.generated.mbti as ignored moon-info output while freezing its exact 56 semantic lines in policy and an independent Phase 99 classifier."
  - "State generated four-target qualification explicitly while reserving licensed real-font workflow evidence for Phase 100."

patterns-established:
  - "Portable tracer: one immutable checksum-correct font, fresh admission/query budgets, opaque GlyphIds, and Path2 length/get inspection only."
  - "Publication closure: regenerate, baseline-diff, exact policy sequence, private/deferred synthetic rejects."

requirements-completed: [FONT-03]

coverage:
  - id: D1
    description: Complete simple and bounded one-level composite outline behavior is identical on native, js, wasm, and wasm-gc.
    requirement: FONT-03
    verification:
      - kind: integration
        ref: "moon -C modules/mb-font test font --target <native|js|wasm|wasm-gc> --frozen --target-dir <unique> --no-parallelize (87/87 each)"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/font_test.mbt#one generated font traces empty repeated implied and attached outlines"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/font_wbtest.mbt#portable outline fixture freezes expanded points descriptors and graph"
        status: pass
    human_judgment: false
  - id: D2
    description: The final generated interface contains only the intended Phase 99 additions and exact policy rejects private or deferred surface.
    requirement: FONT-03
    verification:
      - kind: integration
        ref: "moon -C modules/mb-font info --target all --frozen --target-dir target/phase99-final-interface-overall"
        status: pass
      - kind: integration
        ref: "Assert-FontFoundationPolicy -PolicyPath ./policy/foundation.json"
        status: pass
    human_judgment: false
  - id: D3
    description: Executable package, changelog, English, and Chinese documentation publish the delivered and excluded Phase 99 contract without Phase 100 overclaim.
    requirement: FONT-03
    verification:
      - kind: integration
        ref: "moon -C modules/mb-font check README.mbt.md --target <native|js|wasm|wasm-gc> --frozen --target-dir <unique> --serial"
        status: pass
      - kind: other
        ref: "bilingual exact-scope and added-line stub/threat scans"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-07-27
status: complete
---

# Phase 99 Plan 03: Portable Outline Qualification Summary

**One generated TrueType font now proves exact empty, simple, and bounded composite `Path2` behavior on all four targets under a 56-line fail-closed publication contract.**

## Performance

- **Duration:** 12 minutes
- **Started:** 2026-07-27T10:52:35Z
- **Completed:** 2026-07-27T11:04:59Z
- **Tasks:** 3
- **Tracked files modified:** 8

## Accomplishments

- Added one checksum-correct font containing an empty glyph, a repeated-flag simple glyph with an implied midpoint, and a uniformly transformed composite whose later component attaches through encoded real points.
- Froze every public path command and unchanged horizontal metric through `Path2::length`/`get`, plus private expanded-point, descriptor, Q15, attachment-numbering, and graph-classification facts.
- Qualified the full isolated font package at 87/87 tests independently on native, js, wasm, and wasm-gc.
- Regenerated the interface byte-stably at SHA-256 `d5bb5e76fe1448554aff2cf58e84b7a316d6f2255740736540cca956d89906e0` and confirmed the Phase 98 delta is exactly math, `Font::outline`, four outline accessors, and the expanded constructor.
- Published exact source/import/interface policy and executable package, changelog, English, and Chinese documentation without widening targets, runtime dependencies, or Phase 100 claims.

## Task Commits

1. **Task 1 RED: failing permanent portable tracer** - `db1b2176` (`test`)
2. **Task 1 GREEN: complete portable fixture matrix** - `45599674` (`feat`)
3. **Task 2: regenerate interface and freeze publication policy** - `6a71b80e` (`feat`)
4. **Task 3: publish executable and bilingual documentation** - `3ab5a341` (`docs`)

## Files Created/Modified

- `modules/mb-font/font/generated_fonts_wbtest.mbt` - Canonical generated empty/simple/composite matrix fixture.
- `modules/mb-font/font/font_test.mbt` - Complete public Path2 and metric tracer using opaque glyph identities and fresh budgets.
- `modules/mb-font/font/font_wbtest.mbt` - Private expanded-point, descriptor, transform, placement, and graph facts.
- `modules/mb-font/font/pkg.generated.mbti` - Ignored local `moon info` output regenerated byte-stably; intentionally not force-staged.
- `policy/foundation.json` - Exact outline source, math import, description, and 56-line semantic interface.
- `scripts/quality/Assert-Policy.ps1` - Independent Phase 99 exact-set classifier and private/deferred negative fixtures.
- `modules/mb-font/README.mbt.md` - Four-target executable outline example, limits, Q15 boundary, taxonomy, and exclusions.
- `modules/mb-font/CHANGELOG.md` - Candidate record for direct outlines, four ceilings, exact transforms, and transactional failure.
- `README.md` - Synchronized English/Chinese Phase 99 capability and evidence boundary.

## Decisions Made

- The permanent public tracer uses one three-glyph font so empty, simple, composite, metrics, budgets, and determinism are proven through one immutable admitted value rather than disconnected fixtures.
- Public tests inspect only opaque glyph IDs, `Font::outline`, structured errors, metrics, and `Path2::length`/`get`; private Q15, point numbering, descriptors, and graph facts stay in white-box tests.
- The generated interface remains ignored tool output. Policy holds the exact semantic sequence, and the independent classifier separately approves every line while rejecting parser, graph, Q15, nested, hint, grid, raster, host, file, and FFI surface.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Planning state] Normalized stale final-phase progress fields**

- **Found during:** Final GSD state update
- **Issue:** The SDK correctly moved the machine-readable state to verification and 9/9 plans, but left last-activity prose, milestone text, display ratios, Phase 99 decision labels, Windows evidence, operator next steps, and aggregate metrics at their Plan 99-02 values.
- **Fix:** Synchronized those fields with the three Phase 99 summaries, completed plan counts, and final verification evidence without marking the still-unverified phase complete in ROADMAP.
- **Files modified:** `.planning/STATE.md`
- **Verification:** STATE now reports Plan 3 of 3, 9/9 plans, `verifying`, the final Phase 99 evidence, and verification as the next action.

**Total deviations:** 1 auto-fixed (1 state consistency bug).
**Impact on plan:** No implementation or publication scope changed; canonical GSD progress now matches disk evidence.

## Issues Encountered

- `moon fmt` interpreted scoped file arguments as a package-format operation and touched two production files outside Task 1. Those formatter-only changes were restored file-by-file before the Task 1 GREEN commit; no unrelated source change entered history.
- The ignored interface already matched the Plan 99-01 final hash. Regeneration from a fresh target directory confirmed it remained byte-stable, while the Phase 98 policy interface supplied the recorded 50-line baseline for the exact additive comparison.

## Verification

- Full isolated font package:
  - `native`: 87 passed, 0 failed
  - `js`: 87 passed, 0 failed
  - `wasm`: 87 passed, 0 failed
  - `wasm-gc`: 87 passed, 0 failed
- Native integration check passed.
- All four isolated literate README checks passed with unique target directories.
- All-target interface regeneration passed; generated hash remained `d5bb5e76fe1448554aff2cf58e84b7a316d6f2255740736540cca956d89906e0`.
- Exact font policy, dependency, source order, package manifest, documentation, private-leak, deferred-capability, and 56-line generated-interface gates passed.
- Policy and module JSON parsed successfully; `git diff --check` passed.
- Added-line TODO/FIXME/placeholder/skip/stub and network/auth/file/schema threat scans passed.
- The known unscoped Windows `mb-image/png` workspace lane was not run.

## Known Stubs

None. Empty arrays and `b""` values found in whole-file scans are live generated-font builders or intentional empty-glyph/negative fixtures; no added placeholder, TODO, FIXME, skipped test, or incomplete publication path exists.

## Threat Flags

None. The plan added no network endpoint, authentication path, host file access, FFI, schema change, or new dependency boundary. The planned hostile-font, resource, generated-interface, and private-publication threats are covered by the four-target matrix and fail-closed classifier.

## TDD Gate Compliance

- RED commit `db1b2176` failed because `font_test_portable_outline_matrix_truetype` was intentionally unbound.
- GREEN commit `45599674` added the fixture and private matrix; the focused outline lane passed 22/22 before the four-target 87/87 gate.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- FONT-03 has complete generated four-target, interface, policy, and documentation evidence.
- Phase 100 can now add licensed real-font provenance, redistribution records, digests, inventories, and independently checked semantic facts without changing the Phase 99 outline contract.

## Self-Check: PASSED

- All nine implementation, test, generated-interface, policy, and documentation artifacts plus this summary exist.
- All four RED/GREEN/task commits resolve in repository history.
- Every required target, interface, policy, manifest, documentation, diff, stub, and threat gate passed.

---
*Phase: 99-simple-and-composite-outlines*
*Completed: 2026-07-27*
