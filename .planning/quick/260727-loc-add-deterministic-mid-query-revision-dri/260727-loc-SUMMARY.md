---
phase: quick-260727-loc
plan: 01
subsystem: font
tags: [moonbit, font, cmap, kerning, revision-guard, tdd, portability]
requires:
  - phase: 98-unicode-mapping-and-kerning
    provides: guarded Unicode scalar mapping, legacy kerning, and the verifier's 15/16 ordering-gap report
provides:
  - deterministic after-lookup/before-publication revision-drift evidence for glyph mapping
  - deterministic after-lookup/before-publication revision-drift evidence for kerning
  - byte-stable private query instrumentation across all four supported targets
affects: [phase-98-verification, FONT-02, FONT-04, font-query-safety]
tech-stack:
  added: []
  patterns:
    - Public query methods delegate through package-private after-lookup callbacks whose no-op production path preserves the public API
    - Retained-source mutation tests execute after successful lookup and before the second revision guard
key-files:
  created:
    - .planning/quick/260727-loc-add-deterministic-mid-query-revision-dri/260727-loc-SUMMARY.md
  modified:
    - modules/mb-font/font/font.mbt
    - modules/mb-font/font/font_wbtest.mbt
key-decisions:
  - "Use two package-private callback-bearing adapters, one per query shape, with the same after-lookup/before-guard ordering pattern and no public visibility."
  - "Keep public glyph_for_scalar and kerning behavior on no-op callbacks while white-box tests inject one deterministic retained-owner mutation."
patterns-established:
  - "Post-read guard evidence: successful lookup -> exactly-once callback -> require_revision -> publish only when unchanged."
requirements-completed: [FONT-02, FONT-04]
coverage:
  - id: D1
    description: Glyph mapping rejects a retained-source mutation performed after cmap lookup and publishes no GlyphId.
    requirement: FONT-02
    verification:
      - kind: unit
        ref: "font/font_wbtest.mbt#glyph_for_scalar rejects post-read revision drift"
        status: pass
    human_judgment: false
  - id: D2
    description: Kerning rejects a retained-source mutation performed after pair lookup and publishes no adjustment.
    requirement: FONT-04
    verification:
      - kind: unit
        ref: "font/font_wbtest.mbt#kerning rejects post-read revision drift"
        status: pass
    human_judgment: false
  - id: D3
    description: The complete font package passes on native, js, wasm, and wasm-gc without changing the generated public interface.
    requirement: FONT-02
    verification:
      - kind: integration
        ref: "moon -C modules/mb-font test font --target <native|js|wasm|wasm-gc> --frozen --target-dir <unique-external> --no-parallelize"
        status: pass
      - kind: integration
        ref: "moon -C modules/mb-font info --target all --frozen --target-dir <unique-external>"
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-07-27
status: complete
---

# Quick 260727-loc: Deterministic Post-Read Revision Drift Summary

**Package-private after-lookup callbacks now prove that glyph and kerning queries reject retained-source mutation before any value is published, with an unchanged public interface on all four MoonBit targets.**

## Performance

- **Started:** 2026-07-27T07:49:55Z
- **Completed:** 2026-07-27T07:56:57Z
- **Duration:** 7 minutes
- **Tasks:** 1 TDD feature
- **Files modified:** 2 implementation/test files plus this summary

## Accomplishments

- Added private `glyph_for_scalar_after_lookup` and `kerning_after_lookup` adapters while retaining the existing public method signatures and public documentation semantics.
- Added two white-box regressions whose callbacks each execute exactly once, mutate the retained `OwnedBytes` after a successful lookup, and require the stable `State` / `InvalidRange` / `font-query` / `font-source-revision-drift` error.
- Proved that neither a `GlyphId` nor a signed kerning adjustment escapes after mid-query source mutation.
- Passed the complete 62-test font package independently on native, js, wasm, and wasm-gc with unique external target directories and `--no-parallelize`.
- Preserved `pkg.generated.mbti` byte-for-byte at SHA-256 `f8058722f34e1f54a6c5dcbd5e8960a4d29a48d9561382599c9ec20e56d92ade`.

## TDD Commits

1. **RED: Add failing post-read revision tests** — `aba48a63`
   - Both focused native tests compiled and executed.
   - Both failed because the successful `GlyphId` or adjustment was still published while the adapters ignored their callbacks.
2. **GREEN: Guard post-read query publication** — `96c09619`
   - Each adapter invokes its callback exactly once after successful lookup and immediately before the existing second revision guard.
   - The focused native tests passed 2/2.
3. **REFACTOR:** Not needed — the implementation already uses the smallest clear package-private pattern without widening visibility.

## Validation Evidence

- RED focused native: 2 tests executed, 0 passed, 2 failed for successful value publication.
- GREEN focused native: 2 passed, 0 failed.
- Final focused native: 2 passed, 0 failed.
- Full package native: 62 passed, 0 failed.
- Full package js: 62 passed, 0 failed.
- Full package wasm: 62 passed, 0 failed.
- Full package wasm-gc: 62 passed, 0 failed.
- Interface SHA-256 before all-target regeneration: `f8058722f34e1f54a6c5dcbd5e8960a4d29a48d9561382599c9ec20e56d92ade`.
- Interface SHA-256 after all-target regeneration: `f8058722f34e1f54a6c5dcbd5e8960a4d29a48d9561382599c9ec20e56d92ade`.
- `git diff --exit-code -- modules/mb-font/font/pkg.generated.mbti` passed.
- `git diff --check -- modules/mb-font/font/font.mbt modules/mb-font/font/font_wbtest.mbt` passed.
- The only compiler warning was the known installed-toolchain warning in `builtin/result.mbt`; no project-source warning or driver stall occurred.

## Files Created/Modified

- `modules/mb-font/font/font.mbt` — private callback-bearing glyph and kerning adapters with callbacks positioned between successful lookup and the existing post-read guard.
- `modules/mb-font/font/font_wbtest.mbt` — bounded owner/mutation helpers and exactly-once glyph/kerning post-read drift regressions.
- `.planning/quick/260727-loc-add-deterministic-mid-query-revision-dri/260727-loc-SUMMARY.md` — uncommitted quick execution evidence for the orchestrator.

## Decisions Made

- Kept one private adapter per result type rather than introducing an abstraction that would obscure the security-critical lookup/callback/guard order.
- Used receiving-font glyph ID zero for the kerning fixture so the existing one-glyph generated inventory could be extended with a single supported classic format-0 pair.
- Mutated one bounded byte at offset zero: the mutation revision changes deterministically after lookup, while the post-read guard executes before any further table-dependent publication.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. The scoped commands avoided the known unrelated unscoped Required-lane Windows driver stall.

## Known Stubs

None. The new empty `tables` array is a bounded test-fixture builder populated from the required table inventory before use.

## Threat Flags

None — the private test seam and retained-byte mutation boundary were explicitly covered by the plan threat model; no new public, network, authentication, file-access, schema, or FFI surface was introduced.

## Evidence Preservation

- `.planning/phases/98-unicode-mapping-and-kerning/98-VERIFICATION.md` remained exactly untracked as `??`.
- Its SHA-256 remained `dce6b75056a86be6f1f14a1e8336fdfa5fbde4386225a4c9432c7e2cf2c78c39`.
- Neither task commit contains the verification report, PLAN, SUMMARY, STATE, ROADMAP, REQUIREMENTS, or generated interface.

## Self-Check: PASSED

- Both task-owned files and this summary exist.
- Commits `aba48a63` and `96c09619` resolve and contain only their intended source/test paths.
- The interface and verification-report hashes match their recorded baselines.
- Final worktree status contains exactly the three expected untracked planning artifacts: the Phase 98 verification report, quick PLAN, and quick SUMMARY.

---
*Quick: 260727-loc*
*Completed: 2026-07-27*
