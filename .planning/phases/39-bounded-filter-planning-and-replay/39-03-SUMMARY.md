---
phase: 39-bounded-filter-planning-and-replay
plan: "03"
subsystem: png-encoding
tags: [png, adaptive-filter, compression-strategy, stream-encoding, public-api]
requires:
  - phase: 39-02
    provides: bounded adaptive planning/replay in the shared PNG encode machine
provides:
  - additive eager and caller-buffered PNG compression/filter factories
  - documented deterministic Adaptive method-0 selection contract
  - public black-box adaptive route and atomic-admission coverage
affects: [png-encode, png-stream-encode, png-quality-policy]
tech-stack:
  added: []
  patterns: [single-shared-filter-aware-machine, public-semantic-interface-registration]
key-files:
  created: []
  modified:
    - modules/mb-image/png/png.mbt
    - modules/mb-image/png/stream_encode.mbt
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
    - modules/mb-image/png/encode.mbt
    - policy/foundation.json
key-decisions:
  - "Expose combined factories as thin delegates to the existing shared filter-aware machine."
  - "Keep PngRowFilter private so only the documented PngFilterStrategy is public."
patterns-established:
  - "Combined eager and chunk factory names use identical compression/filter strategy terminology."
requirements-completed: [PNGF-02, PNGF-03]
coverage:
  - id: D1
    description: "Public eager and caller-buffered combined Adaptive factories for all compression strategies."
    requirement: PNGF-02
    verification:
      - kind: unit
        ref: "modules/mb-image/png/encode_test.mbt#PNG adaptive combined eager routes"
        status: pass
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG adaptive combined chunk routes"
        status: pass
    human_judgment: false
  - id: D2
    description: "Adaptive combined construction rejects capability, geometry, output, work, and budget failures atomically."
    requirement: PNGF-03
    verification:
      - kind: unit
        ref: "modules/mb-image/png/stream_encode_test.mbt#PNG adaptive combined admission is atomic"
        status: pass
    human_judgment: false
metrics:
  tasks_completed: 2
  files_modified: 6
status: complete
---

# Phase 39 Plan 03: Public Combined Adaptive PNG Routes Summary

**Documented eager and caller-buffered PNG factories now combine deterministic Adaptive filtering with Stored, FixedOrStored, or DynamicOrFixedOrStored compression through one atomic encode machine.**

## Performance

- **Tasks:** 2/2
- **Files modified:** 6
- **Focused verification:** 12/12 named test runs passed across js, wasm, wasm-gc, and native.

## Accomplishments

- Added public `new_with_strategies` factories for eager and caller-buffered PNG encoding without introducing another planner, emitter, or admission branch.
- Documented None/Sub/Up/Average/Paeth candidate order, signed-absolute residual scoring, and strict-lower earlier-wins tie handling.
- Added public eager/chunk round-trip, hostile-capacity, sticky-terminal, legacy-semantics, and atomic-admission coverage.
- Registered exactly the two additive factory declarations in the PNG semantic interface policy.

## Task Commits

1. **Task 1: Add RED public tests for combined Adaptive routes and atomic rejection** - `3f11f6c` (test)
2. **Task 2: Publish combined factories and register the public interface** - `b6c701a` (feat)

## Files Created/Modified

- `modules/mb-image/png/png.mbt` - Public eager combined factory and Adaptive selection documentation.
- `modules/mb-image/png/stream_encode.mbt` - Public caller-buffered combined factory delegating to the shared machine.
- `modules/mb-image/png/encode_test.mbt` - Public eager RGB8/RGBA8 combined-route decoding proof.
- `modules/mb-image/png/stream_encode_test.mbt` - Hostile drain, parity, and atomic rejection proof.
- `modules/mb-image/png/encode.mbt` - Restored `PngRowFilter` to private implementation visibility.
- `policy/foundation.json` - Two additive combined-factory semantic-interface declarations.

## Decisions Made

- Combined factories retain both strategy values and call the existing Wave 2 filter-aware machine directly.
- Filter-only Adaptive remains Stored plus Adaptive; default and compression-only routes remain explicit None filters.

## Verification

- Passed `PNG adaptive combined eager routes`, `PNG adaptive combined chunk routes`, and `PNG adaptive combined admission is atomic` independently on js, wasm, wasm-gc, and native.
- Passed `moon -C modules/mb-image info --target all --target-dir _build/phase39-active --frozen` and an exact generated PNG semantic-interface policy comparison.
- `Invoke-MoonQuality.ps1 -Lane Png` was time-limited after 304 seconds without stage output or an assertion failure. Its result is **indeterminate**, not a passing quality claim.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Public visibility] Restored the internal adaptive row-filter enum to private visibility.**
- **Found during:** Task 2 policy verification.
- **Issue:** Wave 1/2 left `PngRowFilter` public, adding an undocumented semantic-interface line and blocking the PNG policy gate.
- **Fix:** Changed only `PngRowFilter` to `priv enum`; behavior and internal call sites remain unchanged.
- **Files modified:** `modules/mb-image/png/encode.mbt`
- **Verification:** Generated interface matches `policy/foundation.json` exactly.
- **Committed in:** `b6c701a`

**Total deviations:** 1 auto-fixed (Rule 1).

## Known Stubs

None.

## Issues Encountered

- Initial chunk-test timeouts were caused by an orphaned Moon process holding the shared build lock; after cleanup, the named chunk test passed.
- The scoped PNG quality lane exceeded its five-minute execution limit without emitting a failure, so it remains indeterminate for follow-up rather than being treated as passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- PNGF-02 and PNGF-03 public API and focused portable evidence are ready for downstream verification.
- Re-run the scoped PNG quality lane with an adequate execution window before asserting its full-lane result.

## Self-Check: PASSED

- Task commits `3f11f6c` and `b6c701a` exist.
- All six plan-owned source, test, and policy files exist.
