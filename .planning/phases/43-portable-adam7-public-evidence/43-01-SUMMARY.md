---
phase: 43-portable-adam7-public-evidence
plan: 01
subsystem: png-public-evidence
tags: [png, adam7, streaming, portability, moonbit]
requires:
  - phase: 42-bounded-adam7-pass-encoding
    provides: bounded Adam7 eager and caller-buffered encoding
provides:
  - Generated RGB8 and straight-RGBA8 public Adam7 eager decode-fidelity evidence
  - Hostile-capacity chunk/eager identity and decode-fidelity evidence
  - Isolated four-target public Adam7 quality runner
affects: [PNGI-04, png-encoding]
tech-stack:
  added: []
  patterns: [generated-public-corpus, hostile-capacity-drain, owned-target-directory]
key-files:
  created: [43-01-SUMMARY.md]
  modified:
    - modules/mb-image/png/encode_test.mbt
    - modules/mb-image/png/stream_encode_test.mbt
    - scripts/quality/Invoke-PngAdam7Compatibility.ps1
key-decisions:
  - "Use deterministic 5x5 RGB8 and straight-RGBA8 sources so every Adam7 pass contributes distinct public pixels."
  - "Keep frozen legacy and explicit-None vectors in the focused selectors and assert method-0 IHDR alongside method-1 Adam7 output."
  - "Run each public selector separately in a GUID-owned target directory for every portable MoonBit target."
patterns-established:
  - "Public Adam7 stream tests prove zero-capacity no-op before one-byte and ragged drains, then decode accepted bytes through PngDecoder."
requirements-completed: [PNGI-04]
coverage:
  - id: D1
    description: Generated eager RGB8/RGBA8 Adam7 bytes round-trip through public PngEncoder and PngDecoder APIs.
    requirement: PNGI-04
    verification:
      - kind: unit
        ref: modules/mb-image/png/encode_test.mbt#PNG Adam7 public eager fidelity and frozen None compatibility
        status: pass
    human_judgment: false
  - id: D2
    description: Public chunk Adam7 output preserves zero-capacity ownership, eager byte identity, and exact decoded pixels under one-byte and ragged drains.
    requirement: PNGI-04
    verification:
      - kind: unit
        ref: modules/mb-image/png/stream_encode_test.mbt#PNG Adam7 public chunk fidelity, hostile identity, and frozen None compatibility
        status: pass
    human_judgment: false
  - id: D3
    description: Both focused public selectors execute independently on js, wasm, wasm-gc, and native in owned temporary target directories.
    requirement: PNGI-04
    verification:
      - kind: integration
        ref: pwsh -NoProfile -File scripts/quality/Invoke-PngAdam7Compatibility.ps1
        status: pass
    human_judgment: false
duration: 33min
completed: 2026-07-22
status: complete
---

# Phase 43 Plan 01: Portable Adam7 Public Evidence Summary

**Generated 5x5 RGB8 and straight-RGBA8 Adam7 encodings now prove exact public eager/chunk decode fidelity, frozen None compatibility, and independent four-target execution.**

## Performance

- **Duration:** 33 min
- **Started:** 2026-07-22T09:14:18Z
- **Completed:** 2026-07-22T09:47:05Z
- **Tasks:** 3 completed
- **Files modified:** 3 planned implementation files

## Accomplishments

- Retained complete legacy and explicit-None byte vectors while asserting their IHDR interlace method remains `0`.
- Added generated 5x5 RGB8/RGBA8 public eager Adam7 decode fidelity for Stored, FixedOrStored, and DynamicOrFixedOrStored, with method-`1` IHDR evidence.
- Added public chunk evidence for zero-capacity no-op plus one-byte and ragged drains, exact eager bytes, exact public decode, and all three compression strategies.
- Updated the existing runner to invoke only the two Phase 43 public selectors separately on js, wasm, wasm-gc, and native with its validated GUID-owned cleanup boundary.

## Verification

- `moon -C modules/mb-image test png --target native --frozen -f "PNG Adam7 public eager fidelity and frozen None compatibility" --no-parallelize` — passed (1/1).
- `moon -C modules/mb-image test png --target native --frozen -f "PNG Adam7 public chunk fidelity, hostile identity, and frozen None compatibility" --no-parallelize` — passed (1/1).
- `pwsh -NoProfile -File scripts/quality/Invoke-PngAdam7Compatibility.ps1` — passed for both selectors on js, wasm, wasm-gc, and native.
- `moon -C modules/mb-image test png --target all --frozen` — passed: 171/171 on each of js, wasm, wasm-gc, and native.
- `git diff --check -- modules/mb-image/png/stream_encode_test.mbt scripts/quality/Invoke-PngAdam7Compatibility.ps1` — passed.

## Commit Intent

The pre-created worktree is on `codex/phase42`, which fails the mandatory executor `worktree-agent-*` commit guard. No Task 2, Task 3, or metadata commit was attempted.

1. **Task 1: public eager Adam7 fidelity and frozen None evidence** — `5607f88` (`test(png): budget Adam7 fixed round trip evidence`).
2. **Task 2: public hostile-capacity Adam7 stream fidelity and byte identity** — pending `test(43-01): prove Adam7 chunk public fidelity` for `modules/mb-image/png/stream_encode_test.mbt`.
3. **Task 3: independent four-target public evidence runner** — pending `chore(43-01): run public Adam7 compatibility evidence` for `scripts/quality/Invoke-PngAdam7Compatibility.ps1`.
4. **Plan metadata** — pending `docs(43-01): complete portable Adam7 public evidence plan` for this summary; preserve coordinator-owned `.planning/STATE.md` separately.

## Files Created/Modified

- `modules/mb-image/png/encode_test.mbt` — generated public eager RGB8/RGBA8 Adam7 fidelity plus immutable None-vector IHDR checks.
- `modules/mb-image/png/stream_encode_test.mbt` — public zero/one/ragged chunk drain parity and decode-fidelity checks with immutable None vectors.
- `scripts/quality/Invoke-PngAdam7Compatibility.ps1` — exact Phase 43 selectors in the existing isolated four-target runner.

## Decisions Made

- Kept the corpus generated and bounded rather than adding fixtures or encoder traversal tests, preserving the public API boundary.
- Used the existing owned temporary-target lifecycle unchanged; only selector names changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test budget] Fixed Adam7 FixedOrStored public round-trip test capacity**
- **Found during:** Task 1
- **Issue:** The original eager test helper's capacity was too small for the generated 5x5 Fixed Adam7 output, causing a native abort before public decode assertions.
- **Fix:** Added the bounded Adam7-specific eager helper in `5607f88` with adequate test-only limits.
- **Files modified:** `modules/mb-image/png/encode_test.mbt`
- **Verification:** The eager selector and all-target package suite pass.
- **Commit:** `5607f88`

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** The correction is test-only and required to exercise the planned public FixedOrStored route; no codec algorithm changed.

## Known Stubs

None.

## Issues Encountered

- The aggregate portable suite required 211 seconds and waited on the shared MoonBit build lock, but completed successfully.
- The mandatory worktree commit guard prevents this executor from committing on `codex/phase42`; uncommitted changes and exact commit grouping are listed above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

PNGI-04 has executable public evidence across all supported targets. Commit the pending Task 2, Task 3, and metadata groups from an approved per-agent branch or coordinator context.

## Self-Check

PASSED — all three planned implementation files and this summary exist; Task 1 commit `5607f88` exists; `git diff --check` passes. Task 2, Task 3, and metadata commits remain intentionally pending because the mandatory worktree branch guard rejected `codex/phase42`.

---
*Phase: 43-portable-adam7-public-evidence*
*Completed: 2026-07-22*
