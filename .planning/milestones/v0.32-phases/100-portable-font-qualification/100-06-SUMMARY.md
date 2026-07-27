---
phase: 100-portable-font-qualification
plan: "06"
subsystem: testing
tags: [moonbit, truetype, dejavu-sans, oracle, cross-target, release-evidence]

requires:
  - phase: 100-portable-font-qualification
    provides: Plans 01-05 immutable fixtures, independent oracle, public workflows, and four-target evidence runner
provides:
  - Complete independent ordered command vectors behind every supported DejaVu outline fingerprint
  - Deterministic generated test-private expectations for all 74 supported commands
  - Exhaustive PathCommand assertions on js, wasm, wasm-gc, and native
  - Focused assertion provenance required before each target evidence record is constructed
affects: [phase-100-verification, font-release-qualification, portable-font-conformance]

tech-stack:
  added: []
  patterns:
    - Complete oracle vectors generate structured target expectations without runtime hashing
    - Evidence publication is gated on an exact focused test identity, command, and passing result

key-files:
  created: []
  modified:
    - scripts/fixtures/Generate-FontQualification.ps1
    - fixtures/font/dejavu-sans-2.37/oracle.json
    - modules/mb-font/font/generated_font_qualification_test.mbt
    - modules/mb-font/font/font_qualification_test.mbt
    - scripts/quality/Invoke-FontQualification.ps1
    - scripts/quality/Assert-Policy.ps1

key-decisions:
  - "Persist complete canonical M/L/Q/Z arrays in oracle schema 1.1.0 while retaining SHA-256 exclusively in offline PowerShell tooling."
  - "Generate one ordered test-private expectation set for U+0041, U+034C, and U+10300 and structurally assert every command."
  - "Publish target fingerprints only after the exact one-test DejaVu assertion reports 1/1 passing for that target."

patterns-established:
  - "Oracle completeness: command_count, commands length, and SHA-256 over UTF-8 pipe-joined commands must agree."
  - "Target proof: path length plus variant-specific ordered coordinate checks precede evidence construction."

requirements-completed: [FONT-05]

coverage:
  - id: D1
    description: Independent DejaVu oracle and generated test source preserve every command behind the three supported outline fingerprints.
    requirement: FONT-05
    verification:
      - kind: integration
        ref: "./scripts/fixtures/Generate-FontQualification.ps1 -Check plus Assert-FontFoundationPolicy"
        status: pass
    human_judgment: false
  - id: D2
    description: Every supported DejaVu PathCommand is structurally asserted before four-target fingerprint evidence is published.
    requirement: FONT-05
    verification:
      - kind: e2e
        ref: "./scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/font-plan06"
        status: pass
      - kind: integration
        ref: "font/font_qualification_test.mbt#font-complete-public freezes DejaVu Sans 2.37 public facts (1/1 on js, wasm, wasm-gc, native)"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-07-27
status: complete
---

# Phase 100 Plan 06: Complete DejaVu Fingerprint Evidence Summary

**Complete independent DejaVu vectors now drive all 74 ordered target-side PathCommand assertions before any supported outline fingerprint enters four-target evidence.**

## Performance

- **Duration:** 8 minutes
- **Started:** 2026-07-27T15:49:38Z
- **Completed:** 2026-07-27T15:57:22Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Upgraded the closed independent oracle to schema/reader version 1.1.0 and persisted complete canonical command arrays for every inventoried glyph.
- Generated ordered structured expectations for U+0041 (13 commands), U+034C (48 commands), and U+10300 (13 commands) directly from the freshly recomputed oracle.
- Replaced the three partial eight-command checks with exhaustive path-length and variant-specific M/L/Q/Z assertions across all 74 commands.
- Required one exact 1/1 DejaVu assertion pass on each target before constructing that target's evidence record, while retaining the full 102-test package gate.
- Preserved exact fingerprints, the eight-command readable evidence subset, target/runner-only normalization, the sole `mb-font -> mb-core` dependency, and the 56-line public interface.

## Task Commits

Each TDD gate was committed atomically:

1. **Task 1 RED: Require complete oracle vector contract** - `ba34f0cd` (`test`)
2. **Task 1 GREEN: Generate complete DejaVu outline vectors** - `0a2d9ca5` (`feat`)
3. **Task 2 RED: Require exhaustive target outline proof** - `74932900` (`test`)
4. **Task 2 GREEN: Prove complete outlines before evidence** - `771d5b63` (`feat`)

## Files Created/Modified

- `scripts/fixtures/Generate-FontQualification.ps1` - Recomputes complete vectors/fingerprints, validates the closed grammar, and renders structured expectations.
- `fixtures/font/dejavu-sans-2.37/oracle.json` - Stores complete ordered commands under schema 1.1.0.
- `modules/mb-font/font/generated_font_qualification_test.mbt` - Test-private command and outline expectation records for all 74 supported commands.
- `modules/mb-font/font/font_qualification_test.mbt` - Exhaustive public Path2 structural assertions.
- `scripts/quality/Invoke-FontQualification.ps1` - Focused one-test gate, evidence provenance, and complete-oracle closure checks.
- `scripts/quality/Assert-Policy.ps1` - Frozen schema, supported counts, vector equality, fingerprints, and generated symbols.

## Decisions Made

- Kept SHA-256 entirely in offline PowerShell; MoonBit proves the complete path value summarized by each independent fingerprint without a runtime/public hash API.
- Kept U+00E9 at `font-outline-grid-rounding`; only U+0041, U+034C, and U+10300 receive generated supported-outline assertions.
- Retained only the first eight commands as readable evidence metadata while binding the fingerprint to the independently stored complete vector and target-executed complete assertion.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the generated scalar type for public lookup**

- **Found during:** Task 2 focused js compile
- **Issue:** The first generated expectation used `UInt64` for `scalar`, but the published `Font::glyph_for_scalar` contract accepts `Int`.
- **Fix:** Rendered test-private scalar values as `Int` while retaining opaque glyph IDs as `UInt64`.
- **Files modified:** `scripts/fixtures/Generate-FontQualification.ps1`, `modules/mb-font/font/generated_font_qualification_test.mbt`
- **Verification:** The exact focused test passed 1/1 on js, wasm, wasm-gc, and native.
- **Committed in:** `771d5b63`

**2. [Rule 3 - Blocking] Synchronized final plan and verification state**

- **Found during:** Plan metadata finalization
- **Issue:** The state SDK advanced prose to Plan 6 but left `current_plan: 5`, stale Plan 05 activity/metrics, `executing` status, and `Phase ?` decision attribution; the roadmap inserted Plan 06 outside its wave.
- **Fix:** Synchronized STATE to Plan 6 of 6 and `verifying`, attributed decisions to Phase 100, refreshed 16-plan metrics/operator guidance, and placed Plan 06 under Wave 6 while retaining the roadmap's 6/6 pending-verification status.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Verification:** Machine-readable and prose state agree on Plan 6 of 6; roadmap reports 6/6 with ordered Waves 1-6.
- **Committed in:** Final plan metadata commit

---

**Total deviations:** 2 auto-fixed (1 Rule 1 bug, 1 Rule 3 blocking metadata repair)
**Impact on plan:** The implementation fix was test-private and the metadata repair affected planning state only; no runtime, public interface, dependency, or evidence-normalization change.

## Issues Encountered

- The new complete generated expectation initially exposed the test-private scalar type mismatch described above. The focused compile gate caught it before the GREEN commit.

## TDD Gate Compliance

- Task 1 RED `ba34f0cd` failed on the old 1.0.0 partial oracle before GREEN `0a2d9ca5`.
- Task 2 RED `74932900` failed because evidence construction still expected partial `selected_commands` and lacked focused assertion provenance before GREEN `771d5b63`.

## Verification

- Generator `-Check` passed with exact 13/48/13 supported-vector partitioning and recomputed fingerprint equality.
- Foundation policy passed the oracle schema, generated symbols, fixture, interface, dependency, and portable-source gates.
- The exact focused DejaVu test passed 1/1 on js, wasm, wasm-gc, and native before each record was constructed.
- The complete font package passed 102/102 on each supported target.
- All four records retain the independent U+0041/U+034C/U+10300 fingerprints and report `outline_assertion_passed=true`.
- `comparison.json` reports `equal=true`, removes only `target` and `runner`, and has semantic SHA-256 `65b63177ed296ffa4cb1f46a4c6943d6036a71d70eb1b8409830a35e65fcdef8`.
- `moon info --target all --frozen` regenerated exactly 56 semantic interface lines.
- `git diff --check`, dependency, stub-marker, and public/runtime scope scans passed.

## Known Stubs

None. The policy script's reference to the word `placeholder` is an intentional rejection rule, not a stub.

## Threat Flags

None. The planned oracle-to-generated-source and focused-test-to-evidence trust boundaries are closed; no production network, authentication, filesystem, FFI, schema, or public API surface was added.

## User Setup Required

None - qualification remains offline against committed immutable fixtures.

## Next Phase Readiness

- The Phase 100 verifier can now resolve the prior human-needed fingerprint evidence warning using target-executed complete vectors.
- The separate bounded Required timeout remains the existing workspace concern and was not changed or relabeled by this plan.

## Self-Check: PASSED

- All six plan-owned implementation artifacts and this summary exist.
- All four TDD task commits resolve in repository history.
- Complete oracle, focused four-target, full-package, evidence, interface, dependency, stub, and threat-surface claims were rechecked.

---
*Phase: 100-portable-font-qualification*
*Completed: 2026-07-27*
