---
phase: quick-260726-r3a
plan: 01
subsystem: formatting
tags: [moonbit, moon-fmt, mb-core, mb-color, mb-image, quality]

requires: []
provides:
  - Pinned-formatter normalization of the Required WORK-04 source sets
  - All-target compile and test evidence for the three Required modules
  - Atomic source commit containing only selected MoonBit source and literate-document files
affects: [required-quality-gate, WORK-04, quick-260726-qdh]

tech-stack:
  added: []
  patterns:
    - Explicit sorted source arrays for scoped MoonBit formatting
    - Explicit package-directory arrays for module-local check and test commands

key-files:
  created:
    - .planning/quick/260726-r3a-normalize-moonbit-formatting-for-the-req/260726-r3a-SUMMARY.md
  modified:
    - modules/mb-core
    - modules/mb-color
    - modules/mb-image

key-decisions:
  - "Use explicit package directories without --deny-warn so mechanical formatting verification requires zero errors while preserving pre-existing warnings."
  - "Keep the five pre-existing mb-core warnings outside this formatting-only quick."

patterns-established:
  - "Formatter scope: enumerate only filenames matching `[.]mbt(?:[.]md)?$` and pass every path explicitly."
  - "Verification scope: enumerate package-manifest directories per module and pass them explicitly to check and test."

requirements-completed: []

coverage:
  - id: D1
    description: "The exact 67 mb-core, 29 mb-color, and 83 mb-image WORK-04 files are normalized by the pinned formatter."
    verification:
      - kind: other
        ref: "moon fmt --check <explicit sorted module source array>"
        status: pass
    human_judgment: false
  - id: D2
    description: "All explicit package sets compile and test across wasm, wasm-gc, js, and native."
    verification:
      - kind: integration
        ref: "moon check --target all --frozen <explicit module package directories>"
        status: pass
      - kind: integration
        ref: "moon test --target all --frozen <explicit module package directories>"
        status: pass
    human_judgment: false
  - id: D3
    description: "The source commit contains only formatter-selected module files and preserves all unrelated paths."
    verification:
      - kind: other
        ref: "git diff-tree --no-commit-id --name-only -r f20b8f2"
        status: pass
      - kind: other
        ref: "git diff --check -- modules/mb-core modules/mb-color modules/mb-image"
        status: pass
    human_judgment: false

duration: 27 min
completed: 2026-07-26
status: complete
---

# Quick 260726-r3a: Required WORK-04 Formatting Summary

**Pinned MoonBit formatting normalized 179 checked source paths across mb-core, mb-color, and mb-image, with all explicit-package checks and 3,312 cross-target test executions passing.**

## Performance

- **Duration:** 27 min
- **Started:** 2026-07-26T11:42:02Z
- **Completed:** 2026-07-26T12:09:01Z
- **Tasks:** 1
- **Source files modified:** 84

## Accomplishments

- Reproduced the WORK-04 inventories exactly: 67 `mb-core`, 29 `mb-color`, and 83 `mb-image` `.mbt` / `.mbt.md` files.
- Applied pinned `moon fmt` only to those explicit arrays and passed an independent exact `moon fmt --check` for every module.
- Passed explicit-package all-target checks and tests with zero errors and zero test failures.
- Created atomic source commit `f20b8f2` containing only 84 formatter-changed files from the selected inventories.

## Verification Evidence

| Module | Inventory | Packages | fmt-check | check --target all | Tests per target |
| --- | ---: | ---: | --- | --- | --- |
| `mb-core` | 67 | 11 | PASS | PASS — 5 existing warnings, 0 errors | 267/267 on wasm, wasm-gc, js, native |
| `mb-color` | 29 | 6 | PASS | PASS | 87/87 on wasm, wasm-gc, js, native |
| `mb-image` | 83 | 8 | PASS | PASS — existing non-blocking warnings remain visible | 474/474 on wasm, wasm-gc, js, native |

Commands were run independently with complete explicit arrays:

```powershell
moon fmt --check @files
moon check --target all --frozen @packages
moon test --target all --frozen @packages
```

Final scope checks also passed:

- `git diff --check -- modules/mb-core modules/mb-color modules/mb-image`
- No tracked changes outside the three module roots before staging.
- No staged paths outside the 84 selected `.mbt` / `.mbt.md` files.
- No committed file additions or deletions.

## Pre-existing Warnings

The revised verification contract intentionally does not use `--deny-warn`. The five stable `mb-core` diagnostics appeared on each target with zero errors:

1. `math/bezier.mbt`: unused `bezier2_derivative`.
2. `math/bezier.mbt`: unused `bezier3_derivative`.
3. `text/utf8_wbtest.mbt`: deprecated Show-based `inspect`.
4. `text/xml_escape.mbt`: deprecated `substring` call at the entity body extraction.
5. `text/xml_escape.mbt`: deprecated `substring` call at the hexadecimal prefix removal.

`mb-image` likewise emits existing warnings in PNG implementation, generated-vector, and test code. They remained non-blocking; the scoped commands exited zero and every test passed. Warning cleanup is outside this mechanical formatting quick.

## Task Commit

1. **Task 1: Format and verify the exact Required WORK-04 module set** — `f20b8f2` (`style`)

The PLAN and this SUMMARY remain uncommitted for the orchestrator-owned documentation commit.

## Files Created/Modified

- `modules/mb-core` — 34 formatter-changed source files.
- `modules/mb-color` — 8 formatter-changed source files.
- `modules/mb-image` — 42 formatter-changed source files.
- `.planning/quick/260726-r3a-normalize-moonbit-formatting-for-the-req/260726-r3a-SUMMARY.md` — uncommitted execution evidence.

## Decisions Made

- Used explicit package-directory selectors to prevent parent `moon.work` members from entering module-local verification.
- Preserved warning visibility without converting pre-existing diagnostics into formatting failures.
- Kept the source commit limited to formatter output; no manifest, generated interface, governance, fixture-script, or planning-ledger file was staged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed interrupted-executor module migration residue**

- **Found during:** Task 1 resume
- **Issue:** A previously interrupted concurrent executor had deleted tracked `modules/mb-image/png/generated_vectors.mbt` and created untracked `generated_vectors_wbtest.mbt`, which was not formatter output.
- **Fix:** Restored the tracked path from current HEAD, removed only the untracked residue, then reran the pinned formatter over the complete 83-file mb-image inventory.
- **Files modified:** `modules/mb-image/png/generated_vectors.mbt`; transient untracked `modules/mb-image/png/generated_vectors_wbtest.mbt` removed
- **Verification:** Final inventory remained exactly 83; no module file additions/deletions; full mb-image fmt-check, check, and tests passed.
- **Committed in:** `f20b8f2` (formatter output only)

---

**Total deviations:** 1 auto-fixed blocking issue.
**Impact on plan:** The recovery prevented an unrelated source-layout migration from contaminating the formatting commit; the final output remains formatter-only.

## Issues Encountered

- The original verification promoted pre-existing warnings to errors. The revised, checker-approved plan uses explicit package scoping without `--deny-warn`, while still requiring exit code zero and zero test failures.
- An earlier parallel executor changed unrelated repository state while this quick was paused. Execution resumed only after that executor was interrupted and the root established an exclusive boundary; no outside file was restored or committed by this task.

## Known Stubs

None introduced. A diff scan found only pre-existing prose containing “not available” or “placeholder”; the formatter did not add runtime stubs, TODOs, FIXMEs, or skipped tests.

## User Setup Required

None — no external service configuration is required.

## Next Step Readiness

- The Required quality parent can rerun WORK-04 against the normalized source sets.
- Governance and wrapper work remains owned by the parent quick and was not included in `f20b8f2`.

## Self-Check: PASSED

- SUMMARY exists with `status: complete`.
- Source commit `f20b8f2` exists and contains exactly 84 selected module files.
- The commit contains no additions, deletions, manifests, governance files, fixture scripts, or planning artifacts.
- The tracked working tree and index are clean after the source commit.
- The PLAN and SUMMARY remain uncommitted for orchestrator close-out.

---
*Quick: 260726-r3a*
*Completed: 2026-07-26*
