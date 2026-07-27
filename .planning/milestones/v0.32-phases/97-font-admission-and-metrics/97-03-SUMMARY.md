---
phase: 97-font-admission-and-metrics
plan: 03
subsystem: font
tags: [moonbit, truetype, hmtx, loca, glyf, metrics, policy]
requires:
  - phase: 97-font-admission-and-metrics
    plan: 02
    provides: strict standalone TrueType admission, normalized metric-table facts, retained-source guards, and named global metrics
provides:
  - opaque range-checked GlyphId and exact per-glyph horizontal metric values
  - admission-wide hmtx, loca, and common glyf-header validation under explicit limits
  - exact mb-font publication, dependency, documentation, and semantic-interface policy
affects:
  - 98-unicode-mapping-and-kerning
  - 99-outlines
  - 100-font-qualification
tech-stack:
  added: []
  patterns:
    - receiving Font revalidates opaque glyph identities before table-local reads
    - compact hmtx tails repeat only advance width while retaining per-glyph signed bearings
    - generated semantic interfaces are exact allowlists and reject private or deferred capabilities
key-files:
  created:
    - modules/mb-font/README.mbt.md
    - modules/mb-font/CHANGELOG.md
    - .planning/phases/97-font-admission-and-metrics/deferred-items.md
  modified:
    - modules/mb-font/font/font.mbt
    - modules/mb-font/font/metrics.mbt
    - modules/mb-font/font/generated_fonts.mbt
    - modules/mb-font/font/font_test.mbt
    - modules/mb-font/font/font_wbtest.mbt
    - modules/mb-font/moon.mod.json
    - policy/foundation.json
    - scripts/quality/Assert-Policy.ps1
    - README.md
key-decisions:
  - "GlyphId remains opaque and is revalidated by every receiving Font, so identifiers cannot bypass per-font cardinality checks."
  - "Non-empty glyf intervals are validated during Font admission; metric queries therefore expose only previously admitted common-header bounds."
  - "The public policy surface freezes only limits, opaque Font/GlyphId, source-named global metrics, and exact per-glyph horizontal metrics."
patterns-established:
  - "Metric publication: pre-query revision guard, receiving-font GlyphId range check, checked table-local lookup, post-read revision guard, then opaque value construction."
  - "Font qualification: exact source/test/publication inventories plus a generated .mbti classifier and explicit deferred-capability leak checks."
requirements-completed: [FONT-01]
coverage:
  - id: D1
    description: "Callers can obtain opaque range-checked glyph identities and exact advance, left bearing, optional bounds, and checked right bearing values."
    requirement: FONT-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/font_test.mbt#public per-glyph metric contract"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font test --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Hostile hmtx, short/long loca, common glyf headers, budget edges, mutation drift, and interleaved fonts fail closed or return deterministic values."
    requirement: FONT-01
    verification:
      - kind: unit
        ref: "modules/mb-font/font/font_wbtest.mbt#checked right-side-bearing and hostile metric helpers"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font test --target all --frozen"
        status: pass
    human_judgment: false
  - id: D3
    description: "mb-font is independently documented and governed by exact module, dependency, source, publication, target, and minimal semantic-interface allowlists."
    requirement: FONT-01
    verification:
      - kind: integration
        ref: "Assert-FontFoundationPolicy -PolicyPath policy/foundation.json"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font check README.mbt.md --target all --frozen"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font package --frozen --list"
        status: pass
    human_judgment: false
duration: 42min
completed: 2026-07-26
status: complete
---

# Phase 97 Plan 03: Per-Glyph Metrics and Publication Qualification Summary

Opaque glyph identities now drive checked hmtx/loca/glyf metric queries across all four targets, backed by hostile admission evidence and an exact minimal publication/interface policy.

## Performance

- **Started:** 2026-07-26T10:11:54Z
- **Completed:** 2026-07-26T10:53:53Z
- **Duration:** 42 minutes
- **Tasks:** 3
- **Files changed:** 13

## Accomplishments

- Published opaque `GlyphId` and `GlyphHorizontalMetrics` values with receiving-font range validation, pre/post retained-source revision guards, optional declared bounds, and checked signed right-side-bearing derivation.
- Implemented exact compact/full `hmtx`, short/long `loca`, empty-glyph, and common `glyf` header semantics, rejecting malformed cardinalities and short headers before `Font` publication.
- Expanded hostile generated micro-font coverage for one-short/extra tables, descending/out-of-range offsets, exact limit and budget edges, every query mutation path, mutate-back, and interleaved independent fonts.
- Registered `mb-font -> mb-core` as the sole dependency and froze exact source, test, publication, target, documentation, and generated semantic-interface inventories without exposing deferred font capabilities.
- Added bilingual repository discovery, a four-target literate module README, and an independent unpublished candidate changelog that preserves the Phase 100 licensed real-font boundary.

## Task Commits

Each task was committed atomically with TDD RED and GREEN gates where required:

1. **Task 1: Publish opaque glyph IDs and horizontal metrics**
   - `bcbe7fa` — `test(97-03): add failing per-glyph metric coverage`
   - `cf9263f` — `feat(97-03): publish checked glyph horizontal metrics`
2. **Task 2: Complete hostile metric, mutation, and portability evidence**
   - `8c5b9aa` — `test(97-03): add failing hostile metric matrix`
   - `956b5ef` — `feat(97-03): validate hostile glyph metric inputs`
3. **Task 3: Finalize publication policy, documentation, and interface enforcement**
   - `943160c` — `feat(97-03): qualify mb-font publication surface`

## Files Created/Modified

- `modules/mb-font/font/font.mbt` — publishes opaque glyph identities and guarded per-glyph horizontal metric queries.
- `modules/mb-font/font/metrics.mbt` — validates exact hmtx/loca/glyf relationships and performs checked metric derivation.
- `modules/mb-font/font/generated_fonts.mbt` — supplies deterministic compact/full metric, long-loca, and short-header micro-font variants.
- `modules/mb-font/font/font_test.mbt` — verifies public hostile, limit, mutation, determinism, and cross-font behavior.
- `modules/mb-font/font/font_wbtest.mbt` — verifies checked signed extent/right-bearing arithmetic and private metric invariants.
- `modules/mb-font/README.mbt.md` — documents the caller-owned ByteView/limits/budget workflow and exact Phase 97 boundary.
- `modules/mb-font/CHANGELOG.md` — records the independent unpublished 0.1.0 candidate surface.
- `modules/mb-font/moon.mod.json` — registers the literate publication README.
- `policy/foundation.json` — records exact mb-font module/package/dependency/publication/source/interface policy.
- `scripts/quality/Assert-Policy.ps1` — adds the scoped font classifier and updates live exact inventories.
- `README.md` — adds mb-font to both English and Chinese module inventories.
- `.planning/phases/97-font-admission-and-metrics/deferred-items.md` — records the unrelated full Required governance blocker for follow-up.
- `.planning/WINDOWS.md` — records the uncompleted full gate and policy-inventory deviation for the ship gate.

## Decisions Made

- Keep `GlyphId` opaque but not font-branded in its representation; every receiving `Font` revalidates its numeric value, preserving a narrow public interface while preventing cross-font cardinality bypass.
- Validate every non-empty common `glyf` header during admission. This keeps queries deterministic over already admitted facts and rejects short or inverted headers before any public `Font` exists.
- Define empty-glyph ink extent as zero and return `bounds: None`; no synthetic bounds are invented.
- Preserve exact source naming for global metrics and exact hmtx semantics for per-glyph metrics; this layer does not select layout policy.
- Keep generated micro-fonts as Phase 97 evidence and reserve licensed real-font provenance/end-to-end evidence for Phase 100.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added missing publication README metadata**
- **Found during:** Task 3 policy integration
- **Issue:** The new module manifest lacked the `readme` field required by the repository's generic publication policy.
- **Fix:** Registered `README.mbt.md` in `modules/mb-font/moon.mod.json`.
- **Files modified:** `modules/mb-font/moon.mod.json`
- **Verification:** scoped font policy and `moon package --list` passed with both README and changelog present.
- **Committed in:** `943160c`

**2. [Rule 3 - Blocking] Reconciled existing live policy inventories**
- **Found during:** Task 3 scoped policy verification
- **Issue:** Existing hard-coded module/package arrays and several core utility, blend, image-ops, and canvas import allowlists had drifted from the already tracked workspace, preventing the planned exact font selector from running.
- **Fix:** Preserved every live module/example and updated only the exact arrays/import allowlists needed to match tracked manifests and `moon.pkg` files before adding mb-font.
- **Files modified:** `policy/foundation.json`, `scripts/quality/Assert-Policy.ps1`
- **Verification:** every tracked package import set matches policy, and `Assert-FontFoundationPolicy` passes.
- **Committed in:** `943160c`

---

**Total deviations:** 2 auto-fixed (2 Rule 3 blocking issues)
**Impact on plan:** Both fixes were confined to the planned publication-policy surface and were necessary for exact fail-closed mb-font qualification; no font capability or dependency scope expanded.

## Issues Encountered

- The first all-target rerun exceeded the 124-second tool window without reporting a test failure. Repeating the same command with a 360-second window completed successfully on all four targets.
- The planned full repository command `.\scripts\quality.ps1 -Lane Required -EvidenceDirectory artifacts/release-qualification/local` cannot currently complete for two pre-existing reasons:
  1. the wrapper dot-sources `Invoke-MoonQuality.ps1` without its mandatory `Lane` parameter;
  2. the underlying Required lane passes all stages through D-14, then rejects the existing RFC 0001 status drift because policy says `Accepted` while the canonical RFC and index say `Proposed`.
  These files are outside Plan 97-03 ownership. The root executor will resolve them in a separate GSD quick and rerun the full gate; this summary does not mark that gate passed.

## Verification

- `moon -C modules/mb-font test --target all --frozen`
  - wasm: 1035 passed, 0 failed
  - wasm-gc: 1035 passed, 0 failed
  - JavaScript: 1035 passed, 0 failed
  - native: 1035 passed, 0 failed
- `moon -C modules/mb-font info --target all --frozen` completed with zero errors.
- `Assert-FontFoundationPolicy -PolicyPath policy/foundation.json` verified the sole package/dependency, exact source/test/publication inventories, four targets, candidate docs, generated interface, and deferred-capability exclusions.
- `moon -C modules/mb-font check README.mbt.md --target all --frozen` passed.
- `moon -C modules/mb-font package --frozen --list` emitted exactly the policy-owned README, changelog, manifest, package directory, and source/test files.
- Stub/skip scan found no functional `TODO`, `FIXME`, placeholder, coming-soon, skipped test, or unwired data surface in Plan 97-03 files. Empty arrays are bounded builders/collections, not runtime stubs.
- Threat-surface review found no unplanned network, filesystem, authentication, schema, FFI, or host-discovery surface beyond the plan's hostile caller-byte admission boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The opaque metric facade and private normalized metric index are ready for Phase 98 cmap lookup and kerning without widening raw table access.
- Phase 99 can consume range-checked glyph identities while keeping outline payload decoding separate from Phase 97 metrics.
- Before phase-level verification, the root executor must resolve the pre-existing quality-wrapper and RFC 0001 policy/document status drift, then rerun the full Required lane.

## Self-Check: PASSED

- All 13 claimed source, test, documentation, policy, and tracking files exist.
- All five Task 1-3 RED/GREEN/policy commits exist.
- Four-target font tests, exact scoped policy/interface checks, literate README checks, and package inventory checks pass.
- The uncompleted full Required gate is explicitly recorded in this summary, the phase deferred ledger, and `.planning/WINDOWS.md`; it is not represented as passed.

---
*Phase: 97-font-admission-and-metrics*
*Completed: 2026-07-26*
