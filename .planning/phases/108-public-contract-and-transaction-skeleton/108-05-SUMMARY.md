---
phase: 108-public-contract-and-transaction-skeleton
plan: "05"
subsystem: text-shaping
tags: [moonbit, policy, semantic-interface, portability, font-qualification]

requires:
  - phase: 108-01
    provides: public empty shaping tracer and font-owned transaction
  - phase: 108-02
    provides: checked signed arithmetic and ResourceCharge composition
  - phase: 108-03
    provides: owner-bound GlyphId and guarded FontShapeScope authority
  - phase: 108-04
    provides: immutable run projection and complete contract evidence
provides:
  - exact mb-text module, dependency, source, test, publication, and semantic-interface policy
  - additive mb-core and mb-font interface seals preserving all 85 qualified v0.34 font lines
  - explicit Required-lane mb-text execution on js, wasm, wasm-gc, and native
  - literate public contract and candidate changelog for mb-text
  - FontQualification evidence bound to the exact 89-line Phase 108 font interface
affects: [109-layout-admission, 110-gsub, 111-gpos, 113-qualification, mb-text-public-contract]

tech-stack:
  added: []
  patterns:
    - exact semantic-interface allowlists with fail-closed one-field negative mutations
    - legacy qualification surfaces are validated before exact additive contract lines
    - documentation claims distinguish four-target portability from semantic qualification

key-files:
  created:
    - modules/mb-text/README.mbt.md
    - modules/mb-text/CHANGELOG.md
  modified:
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - scripts/quality/Invoke-MoonQuality.ps1
    - scripts/quality/Invoke-FontQualification.ps1
    - modules/mb-core/README.mbt.md
    - modules/mb-core/CHANGELOG.md
    - modules/mb-font/README.mbt.md

key-decisions:
  - "The mb-font Phase 108 policy is exactly the qualified 85-line v0.34 interface plus the four approved generic transaction and public-abstract scope lines."
  - "Phase 108 documentation proves four-target build and contract behavior but leaves semantic equivalence and successful nonempty real-font qualification to Phase 113."
  - "FontQualification calls the shared exact Phase 108 interface validator so its evidence cannot accept either legacy-line drift or unapproved additive scope."

patterns-established:
  - "Exact additive qualification: remove and validate the four approved additions, then require the remaining legacy interface byte-for-byte and in order."
  - "Closed publication boundary: module identity, DAG, sources, tests, imports, docs, and generated public interface are one policy-owned unit."

requirements-completed: [TXT-01, TXT-02]

coverage:
  - id: D1
    description: "The exact mb-text publication unit, dependency DAG, source inventory, and closed public interface are fail-closed policy facts."
    requirement: TXT-01
    verification:
      - kind: integration
        ref: "Assert-FoundationPolicy -PolicyPath policy/foundation.json"
        status: pass
      - kind: other
        ref: "moon -C modules/mb-text info --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "The complete text contract and immutable-run evidence execute on js, wasm, wasm-gc, and native without opening the nonempty real-font capability."
    requirement: TXT-02
    verification:
      - kind: integration
        ref: "moon -C modules/mb-text test --target <js|wasm|wasm-gc|native> --frozen (1323/1323 per target)"
        status: pass
      - kind: integration
        ref: "moon test --target all --frozen (1323/1323 per target)"
        status: pass
    human_judgment: false
  - id: D3
    description: "All qualified v0.34 font interface lines remain exact and the four approved Phase 108 scope lines are bound into four-target FontQualification evidence."
    requirement: TXT-01
    verification:
      - kind: integration
        ref: "scripts/quality.ps1 -Lane FontQualification -EvidenceDirectory artifacts/release-qualification/phase108-font"
        status: pass
      - kind: integration
        ref: "scripts/quality/Invoke-FontQualification.ps1 -ContractOnly"
        status: pass
    human_judgment: false
  - id: D4
    description: "Literate core, font, and text documentation builds on all four targets and makes no UI, external-service, or Phase 113 qualification claim."
    requirement: TXT-01
    verification:
      - kind: other
        ref: "moon -C modules/<mb-core|mb-font|mb-text> check README.mbt.md --target all --frozen"
        status: pass
      - kind: other
        ref: "policy no-UI/no-external production-source audit"
        status: pass
    human_judgment: false

duration: 54min
completed: 2026-07-30
status: complete
---

# Phase 108 Plan 05: Public Contract and Transaction Skeleton Summary

**Exact mb-text module and interface policy now seals the four-target shaping contract while preserving the full v0.34 font surface through an additive 89-line qualification boundary.**

## Performance

- **Duration:** 54 min
- **Started:** 2026-07-29T22:29:37Z
- **Completed:** 2026-07-29T23:24:12Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Registered exactly `tchivs/mb-text@0.1.0`, its direct `mb-core`/`mb-font` DAG, four targets, source/test/publication inventories, package imports, and 54-line public semantic interface.
- Added fail-closed policy negatives for reverse dependencies, extra imports, omitted sources, alternate limits, public fixture/transaction authority, and positive nonempty real-font claims.
- Extended Required quality to check, test, document, inspect, and package mb-text independently on js, wasm, wasm-gc, and native.
- Published compile-checked core/font/text contract documentation covering checked charges, generic transaction scope invalidation, scalar clusters, signed LTR/RTL projection, one commit, synchronous/no-cache execution, and stable error precedence.
- Preserved FontQualification across the additive scope API: all four targets and four evidence records pass with semantic digest `482f3123124c82126af5389f5761f3ff576c037b605813d5cb1ac77189fbe9ff`.

## Task Commits

Each task and deviation was committed atomically:

1. **Task 1 RED: Add failing text policy seal** - `a2477dab` (test)
2. **Task 1 GREEN: Seal text module contract policy** - `2fbe1f05` (feat)
3. **Task 2: Document the text shaping contract** - `7b412069` (docs)
4. **Rule 3 fix: Preserve FontQualification across the additive scope API** - `ad184bee` (fix)

## Files Created/Modified

- `policy/foundation.json` - Owns exact mb-text identity, DAG, inventories, semantic interface, and additive core/font interface facts.
- `scripts/quality/Assert-Policy.ps1` - Verifies the exact text contract and exercises fail-closed dependency, source, interface, and claim negatives.
- `scripts/quality/Invoke-MoonQuality.ps1` - Runs independent mb-text quality operations on every supported target.
- `scripts/quality/Invoke-FontQualification.ps1` - Validates all 85 legacy font lines plus the four exact Phase 108 scope additions.
- `modules/mb-core/README.mbt.md` - Documents and compile-checks signed arithmetic and charge composition.
- `modules/mb-core/CHANGELOG.md` - Records candidate-compatible checked arithmetic additions.
- `modules/mb-font/README.mbt.md` - Documents owner-bound glyphs and the exact scoped generic transaction.
- `modules/mb-text/README.mbt.md` - Provides the literate closed shaping contract and executable empty/fail-closed examples.
- `modules/mb-text/CHANGELOG.md` - Records the candidate public contract and explicit deferred capability boundary.

## Decisions Made

- Kept the public FontShapeScope surface to `units_per_em` and the exact generic tuple callback; constructors, source facts, probes, ledgers, and commit authority remain private.
- Kept ShapeLimits to its two required nonzero fields and three exact public operations, without defaults or layout/resource limit groups.
- Documented nominal generic-T scope escape honestly: escape is possible, but every post-callback scope operation returns the exact closed-scope State/InvalidRange error.
- Treated four-target build and contract tests as portability evidence only; Phase 113 remains the semantic qualification authority.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Synchronized stale mb-core math policy facts**

- **Found during:** Task 1 policy verification
- **Issue:** The live Phase 106 `Path2::with_capacity` and `mb-core/error` import additions were already committed but absent from the policy inventory, preventing exact workspace policy validation.
- **Fix:** Updated only the existing mb-core math policy source/import/interface facts before adding the planned mb-text record.
- **Files modified:** `policy/foundation.json`
- **Verification:** `Assert-FoundationPolicy -PolicyPath policy/foundation.json`
- **Committed in:** `2fbe1f05`

**2. [Rule 3 - Blocking] Advanced the stale FontQualification interface seal**

- **Found during:** Task 2 FontQualification regression
- **Issue:** The qualification runner hardcoded an 85-line count and rejected the plan-required four additive Phase 108 scope lines after all runtime tests passed.
- **Fix:** Reused the shared exact validator, which preserves every qualified 85-line v0.34 declaration and admits exactly the four approved additions; updated evidence count and its one-field negative from 86 to 90.
- **Files modified:** `scripts/quality/Invoke-FontQualification.ps1`, `policy/foundation.json`
- **Verification:** contract-only negatives and full four-target FontQualification pass
- **Committed in:** `ad184bee`

**3. [Rule 3 - Blocking] Reconciled stale aggregate Phase 108 state**

- **Found during:** Final state advancement
- **Issue:** Plans 108-02 through 108-04 had summaries on disk, but STATE still identified Plan 2 as next, reported 1/5 complete, omitted their metrics, and retained Plan 1 activity prose.
- **Fix:** Advanced through the missing SDK positions, restored the three summary-backed metrics, and normalized final Plan 5 verification/activity/decision prose.
- **Files modified:** `.planning/STATE.md`
- **Verification:** state progress reports 5/5 and 100%, Plan 5 of 5, ready for verification
- **Committed in:** final metadata commit

---

**Total deviations:** 3 auto-fixed (3 blocking)
**Impact on plan:** The implementation fixes were required to execute the planned exact policy and compatibility gates, and the metadata repair restored summary-backed state. None widened the public API or dependency graph.

## Verification

- PASS — exact policy, RFC, workspace, DAG, inventories, generated interfaces, documentation claims, and negative matrices.
- PASS — `moon -C modules/mb-text info --target all --frozen`.
- PASS — core, font, and text literate READMEs on js, wasm, wasm-gc, and native.
- PASS — `moon test --target all --frozen`, 1323/1323 on every target.
- PASS — explicit mb-text test runs on js, wasm, wasm-gc, and native, 1323/1323 per target.
- PASS — FontQualification v3, four targets/four records, closed-contract negatives, semantic digest `482f3123124c82126af5389f5761f3ff576c037b605813d5cb1ac77189fbe9ff`.
- BLOCKED (inherited) — `moon check --target all --deny-warn --frozen` reports 40 pre-existing mb-font CFF unused/deprecated warnings.
- BLOCKED (inherited) — Required reaches policy and benchmark preflight successfully, then stops at the pre-existing repository-wide mb-core `moon fmt --check` drift.

## Issues Encountered

- The exact workspace deny-warning command remains blocked by the existing CFF warning backlog already recorded in `.planning/WINDOWS.md` entry 61. Warning-tolerant interface and test commands pass.
- Required cannot reach its later per-module commands because `moon fmt --check` reports broad pre-existing mb-core formatting drift. This distinct inherited blocker is recorded in `.planning/WINDOWS.md` entry 64.
- FontQualification initially rejected the intentional additive interface after completing its runtime suites; the bounded compatibility fix is documented above and the full lane now passes.

## Deferred Issues

- Clear the existing mb-font CFF warning backlog before treating dependency-wide `--deny-warn` as a clean promotion gate.
- Normalize the existing mb-core source tree with the pinned formatter so Required can proceed past WORK-04.

## Known Stubs

None. The README's empty scalar array is the executable empty-input contract, and the public nonempty `CapabilityUnavailable` result is the intentional Phase 108 boundary assigned to later layout phases, not a placeholder success path.

## Threat Flags

None. The new surface is policy/configuration and documentation over the plan-declared module, publication, generated-interface, compatibility, and claim trust boundaries; no network, authentication, file-access, database, UI, or FFI surface was introduced.

## TDD Gate Compliance

- RED: `a2477dab` introduced the exact mb-text policy expectations and failed against the prior five-module policy.
- GREEN: `2fbe1f05` added the exact module/DAG/interface facts and made the policy plus four-target interface gate pass.

## Authentication Gates

None.

## User Setup Required

None - no external services, credentials, or local configuration are required.

## Next Phase Readiness

- Phase 109 can consume one policy-sealed format-neutral shape operation, immutable run surface, and font-owned transaction without importing private source/table authority.
- Nonempty layout admission remains deliberately fail-closed and semantic four-target qualification remains assigned to Phase 113.
- The inherited CFF warning and mb-core formatting backlogs should be cleared independently; they do not invalidate the Phase 108 policy, functional tests, docs, or FontQualification evidence.

## Self-Check: PASSED

All nine implementation/documentation files and this summary exist, and commits `a2477dab`, `2fbe1f05`, `7b412069`, and `ad184bee` resolve as commits in repository history.

---
*Phase: 108-public-contract-and-transaction-skeleton*
*Completed: 2026-07-30*
