---
phase: 98-unicode-mapping-and-kerning
plan: 03
subsystem: font
tags: [moonbit, unicode, cmap, kern, portability, publication-policy]

requires:
  - phase: 98-unicode-mapping-and-kerning
    plan: 01
    provides: deterministic canonical cmap admission and guarded scalar lookup
  - phase: 98-unicode-mapping-and-kerning
    plan: 02
    provides: strict legacy kern admission, signed pair lookup, and explicit kern ceilings
provides:
  - one permanent all-target Unicode-to-opaque-glyph-to-signed-kerning tracer
  - complete public/private generated qualification for FONT-02 and FONT-04
  - exact Phase 98 source, publication, interface, dependency, and target policy
  - literate and bilingual documentation of the delivered font contract and exclusions
affects: [99-outline-extraction, 100-font-qualification, font-api, release-policy]

tech-stack:
  added: []
  patterns:
    - exercise BMP and supplementary scalars through one public method before passing opaque IDs into kerning
    - keep generated semantic interfaces and an independent fail-closed classifier synchronized
    - qualify each MoonBit target with an isolated external target directory and package-scoped selector

key-files:
  created: []
  modified:
    - modules/mb-font/font/font_test.mbt
    - modules/mb-font/font/font_wbtest.mbt
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - modules/mb-font/README.mbt.md
    - modules/mb-font/CHANGELOG.md
    - README.md

key-decisions:
  - "The permanent tracer uses one checksum-correct font carrying both a canonical format-12 cmap and one supported classic format-0 kern table."
  - "Phase 98 publication exposes only glyph_for_scalar, kerning, two kern ceilings, and the expanded FontLimits constructor; all cmap/kern facts remain private."
  - "The independent font policy classifier now approves the exact Phase 98 surface while continuing to reject raw cmap/kern facts and Phase 99+ capabilities."

patterns-established:
  - "Portable tracer gate: run one named public workflow independently on js, wasm, wasm-gc, and native before expanding the matrix."
  - "Policy closure: exact generated interface, exact source/publication order, private-leak classifier, four targets, and mb-core-only dependency move together."

requirements-completed: [FONT-02, FONT-04]

coverage:
  - id: D1
    description: One generated font maps BMP and supplementary scalars through the same public method and passes the opaque results into signed legacy kerning.
    requirement: FONT-02
    verification:
      - kind: integration
        ref: "font/font_test.mbt#one generated font maps Unicode scalars into a signed kern pair"
        status: pass
      - kind: integration
        ref: "four target-specific tracer runs: js/wasm/wasm-gc/native, 1/1 each"
        status: pass
    human_judgment: false
  - id: D2
    description: Unicode and kern public/private hostile, resource, mutation, determinism, and error-taxonomy matrices execute identically on all supported targets.
    requirement: FONT-04
    verification:
      - kind: unit
        ref: "moon -C modules/mb-font test font --target <target> --frozen --target-dir <isolated> --no-parallelize"
        status: pass
      - kind: integration
        ref: "js/wasm/wasm-gc/native: 60 passed, 0 failed on each target"
        status: pass
    human_judgment: false
  - id: D3
    description: Generated interface, exact policy, literate docs, changelog, and bilingual discovery text publish only the Phase 98 contract.
    requirement: FONT-02
    verification:
      - kind: integration
        ref: "Assert-FontFoundationPolicy -PolicyPath policy/foundation.json"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font check README.mbt.md --target <target> --frozen --target-dir <isolated>"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-07-27
status: complete
---

# Phase 98 Plan 03: Portable Qualification and Publication Summary

**A four-target Unicode-to-opaque-glyph-to-signed-kern workflow backed by complete generated adversarial evidence and an exact mb-core-only publication contract.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-07-27T06:59:27Z
- **Completed:** 2026-07-27T07:18:53Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added a permanent checksum-correct public tracer whose single `Font` maps U+0041 and U+1F600, passes the returned opaque IDs to `Font::kerning`, and publishes the exact signed `-37` adjustment without consuming query budget.
- Completed the generated public matrix for scalar endpoints, valid noncharacters/unassigned values, format-12 first/last/gap behavior, empty and first/middle/last kern lookup, unsupported profiles, malformed recognized pairs, and interleaved cross-font isolation.
- Added private five-way error-taxonomy assertions while retaining rank, format-4 base math, format-12/4 lower bounds, kern search helpers, key order, exact lengths, and signed FWORD evidence.
- Verified the complete 60-test font package independently on `js`, `wasm`, `wasm-gc`, and `native`.
- Regenerated the public interface with `moon info --target all --frozen`; the canonical file already matched the intended Phase 98 surface and required no textual update.
- Registered `cmap.mbt` and `kern.mbt` in exact production/publication inventories, froze the 50-line semantic interface, preserved all four targets, and kept `tchivs/mb-core` as the only direct dependency and import family.
- Documented the singular signed-scalar contract, deterministic rank, glyph-zero miss, optional legacy kerning taxonomy, explicit ceilings, retained-source guards, allocation-free lookups, and Phase 99/100 exclusions in literate, changelog, English, and Chinese surfaces.

## Task Commits

1. **Task 1 RED: Add failing Unicode-plus-kerning tracer** - `34a0ee3f` (test)
2. **Task 1 GREEN: Trace the portable Unicode-to-kerning flow** - `9c4d8296` (feat)
3. **Task 1 qualification: Complete portable cmap/kern evidence** - `322fa0e3` (test)
4. **Task 2: Publish exact interface policy and documentation** - `9746559b` (feat)

## Files Created/Modified

- `modules/mb-font/font/font_test.mbt` - Permanent combined tracer plus scalar, kern, hostile-pair, isolation, and resource-neutral public evidence.
- `modules/mb-font/font/font_wbtest.mbt` - Exact invalid-input/data/capability/state/resource taxonomy evidence.
- `policy/foundation.json` - Phase 98 description, exact cmap/kern inventories, and exact generated semantic interface.
- `scripts/quality/Assert-Policy.ps1` - Independent Phase 98 allowlist, source/publication inventory, and private cmap/kern leak rejection.
- `modules/mb-font/README.mbt.md` - Literate public contract, limits, selection, outcomes, guards, and exclusions.
- `modules/mb-font/CHANGELOG.md` - Unpublished candidate record for deterministic mapping and basic legacy kerning.
- `README.md` - Equivalent English and Chinese responsibility and status descriptions.

`modules/mb-font/font/pkg.generated.mbti` was regenerated and verified byte-stable; it already contained the exact intended public delta from Plans 98-01 and 98-02.

## Decisions Made

- The integration oracle is a real generated SFNT with both tables, not two separate public-query tests.
- Valid Unicode noncharacters and unassigned values are accepted as scalars and return glyph zero when unmapped; only negative, surrogate, and above-maximum values are invalid input.
- Kern declared-length mismatches are classified at the outer recognized envelope boundary before inner format-0 validation.
- The policy classifier remains independent from `foundation.json`: it explicitly approves the Phase 98 surface and independently rejects private facts or future outline/shaping/host APIs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the malformed kern length test oracle**
- **Found during:** Task 1 qualification
- **Issue:** The new test initially expected `font-kern-format0`, but an inconsistent declared subtable length fails the earlier exact classic-envelope exhaustion gate.
- **Fix:** Froze the actual stable `font-kern-envelope` context while retaining inner search/order/range contexts for their respective malformed cases.
- **Files modified:** `modules/mb-font/font/font_test.mbt`
- **Commit:** `322fa0e3`

**2. [Rule 3 - Blocking] Advanced the independent font policy classifier**
- **Found during:** Task 2 policy integration
- **Issue:** `Assert-Policy.ps1` still hard-coded the Phase 97 source/publication/interface allowlists and classified every cmap/kern public line as a deferred capability, so the planned exact Phase 98 policy could not pass.
- **Fix:** Added exact cmap/kern inventories and approved public lines, preserved raw private-fact rejection, and moved the deferred-capability boundary to Phase 99+.
- **Files modified:** `scripts/quality/Assert-Policy.ps1`
- **Commit:** `9746559b`

**3. [Rule 3 - Blocking] Reconciled stale final-plan state prose**
- **Found during:** Final state update
- **Issue:** The SDK correctly moved Phase 98 to `verifying` but left Plan 98-02 activity, 5/6 progress prose, open-requirement text, `[Phase ?]` decision labels, and the old operator next step in the human-readable state body.
- **Fix:** Synchronized those fields with the canonical state frontmatter, three Phase 98 summaries, and completed FONT-02/FONT-04 requirement records.
- **Files modified:** `.planning/STATE.md`
- **Verification:** `STATE.md` now records completed Plan 98-03, 6/6 plans, Phase 98 decisions, and verification as the next action.

---

**Total deviations:** 3 auto-fixed (1 Rule 1, 2 Rule 3)
**Impact on plan:** The changes tighten executable evidence, fail-closed publication policy, and planning-state accuracy; no runtime dependency, public type, target, or feature scope expanded.

## Verification

- Permanent tracer:
  - `js`: 1 passed, 0 failed
  - `wasm`: 1 passed, 0 failed
  - `wasm-gc`: 1 passed, 0 failed
  - `native`: 1 passed, 0 failed
- Full package-scoped suite using unique external target directories and `--no-parallelize`:
  - `js`: 60 passed, 0 failed
  - `wasm`: 60 passed, 0 failed
  - `wasm-gc`: 60 passed, 0 failed
  - `native`: 60 passed, 0 failed
- `moon -C modules/mb-font info --target all --frozen --target-dir <isolated>` completed and left `pkg.generated.mbti` unchanged.
- `moon -C modules/mb-font check README.mbt.md --target <target> --frozen --target-dir <isolated>` passed independently on all four targets.
- `Assert-FontFoundationPolicy -PolicyPath policy/foundation.json` passed exact dependency, publication, source-order, target, documentation, private-leak, deferred-capability, and 50-line generated-interface checks.
- JSON parsing, `git diff --check`, stub/skip scans, and private-interface leak scans passed.

## Issues Encountered

The full repository Required lane passed its governance, fixture, source-audit, benchmark, compatibility, toolchain, exact policy/interface, formatting, prohibition, deterministic-vector, negative-fixture, source-isolation, and initial JavaScript check stages. It then reached the known Windows unscoped driver stall at:

`moon test --target js --frozen` → `tchivs/mb-image/png` black-box Node runner.

The exact run tree (`pwsh` 35996 → `moon` 20732 → `node` 35584) was terminated. The unscoped command was not retried, as required. This uncompleted full-lane tail is recorded in `.planning/WINDOWS.md`; all Phase 98-owned scoped tests and policy/documentation gates passed.

MoonBit native compilation emitted only the known warning from the toolchain's `builtin/result.mbt`; no project-source warning was introduced.

## Known Stubs

None. Empty arrays in the changed test file are bounded byte/pair fixture builders, not runtime placeholders or unwired data.

## User Setup Required

None - no external services, packages, host fonts, or credentials are required.

## Next Phase Readiness

- Phase 99 can consume opaque, range-checked glyph identities for outline extraction without widening cmap/kern facts or introducing text shaping.
- Phase 100 can add licensed real-font provenance and end-to-end evidence while reusing the now-frozen four-target public workflow.
- The open full Required-lane Windows driver entry remains visible in `.planning/WINDOWS.md` for ship-time resolution.

## Self-Check: PASSED

- All nine claimed implementation, test, generated-interface, policy, documentation, and summary files exist.
- All four Task 1-2 commits exist in git history.
- No private cmap/kern fact appears in the generated or policy semantic interface.
- Stub scans found only deterministic empty test builders and the policy validator's rejection of placeholder approval evidence; neither is a runtime stub.
- `git diff --check` passed.
