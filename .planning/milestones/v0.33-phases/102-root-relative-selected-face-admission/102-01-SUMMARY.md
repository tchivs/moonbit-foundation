---
phase: 102-root-relative-selected-face-admission
plan: 01
subsystem: font-admission
tags: [moonbit, opentype, ttc, checksums, budgets, tdd]

requires:
  - phase: 101-collection-contract-and-bounded-envelope
    provides: Retained collection roots, cached face authority, root-relative structural admission, and revision identity
provides:
  - Private absolute-directory/root-relative-table parsing seam
  - Explicit standalone and collection checksum policies with shared table integrity
  - Ancestor-aware standalone-incremental and collection-deferred admission ledger
  - Exact admission-work and historical standalone-remainder facts
affects: [102-02-selected-face-transaction, 102-03-equivalence-policy-portability]

tech-stack:
  added: []
  patterns:
    - Thin standalone wrappers over explicit private collection-aware modes
    - Cumulative preflight on the real hierarchical Budget with mode-specific commit timing

key-files:
  created: []
  modified:
    - modules/mb-font/font/directory.mbt
    - modules/mb-font/font/tables.mbt
    - modules/mb-font/font/kern.mbt
    - modules/mb-font/font/font.mbt
    - modules/mb-font/font/collection_wbtest.mbt

key-decisions:
  - "Directory-local fields add the absolute selected directory start; table-record offsets remain unchanged collection-root coordinates."
  - "Per-table checksums and head adjustment-byte zeroing are shared; only standalone applies the complete-source checksum adjustment."
  - "One ledger preserves historical standalone incremental charges while collection mode cumulatively preflights live caller and ancestor windows without mutating them."

patterns-established:
  - "Coordinate split: selected directory fields are absolute, retained TableWindow offsets remain root-relative."
  - "Commit-policy split: StandaloneIncremental charges declared scans at their historical sites; CollectionDeferred records staged work and only preflights."

requirements-completed:
  - TTC-02
  - TTC-03

coverage:
  - id: D1
    description: "A private parser reads a selected directory at a non-zero absolute start while retaining no-copy root-relative table windows before or after that directory."
    requirement: TTC-03
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_wbtest.mbt#selected directory reads absolute fields and keeps table offsets root relative"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/collection_wbtest.mbt#selected directory permits touching tables and rejects intersections"
        status: pass
    human_judgment: false
  - id: D2
    description: "Standalone and collection modes share every table checksum and head-byte-zeroing rule, while collection skips only the whole-root adjustment."
    requirement: TTC-03
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_wbtest.mbt#collection checksum mode keeps table integrity and skips only root adjustment"
        status: pass
    human_judgment: false
  - id: D3
    description: "The admission ledger cumulatively preflights real ancestor authority, leaves deferred budgets unchanged, and exposes exact work without double-counting staged scans."
    requirement: TTC-02
    verification:
      - kind: unit
        ref: "modules/mb-font/font/collection_wbtest.mbt#deferred admission ledger cumulatively preflights ancestors without charging"
        status: pass
      - kind: unit
        ref: "modules/mb-font/font/collection_wbtest.mbt#admission plan reports exact work without double counting staged scans"
        status: pass
    human_judgment: false
  - id: D4
    description: "The unchanged public Font::open path preserves standalone behavior, exact staged accounting, generated interface, package policy, and four-target execution."
    requirement: TTC-02
    verification:
      - kind: integration
        ref: "moon -C modules/mb-font test font --target {js,wasm,wasm-gc,native} --frozen (138/138 each)"
        status: pass
      - kind: integration
        ref: "pwsh -NoProfile -File scripts/quality/Assert-Policy.ps1"
        status: pass
      - kind: other
        ref: "moon -C modules/mb-font check --target all --frozen"
        status: pass
    human_judgment: false

duration: 21min
completed: 2026-07-28
status: complete
---

# Phase 102 Plan 01: Offset-Aware Admission Foundation Summary

**Root-relative selected-directory parsing and an ancestor-aware dual-mode work ledger now reuse the standalone font pipeline without changing any `Font::open` observation.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-07-28T00:51:44Z
- **Completed:** 2026-07-28T01:12:44Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Generalized private directory admission to non-zero absolute directory starts while preserving unchanged root table offsets, no-copy `ByteView` subviews, checked addressing, and half-open overlap rules.
- Split checksum validation into a shared selected-table loop and an explicit standalone-only whole-source adjustment gate.
- Added a shared admission ledger whose standalone mode preserves historical cmap/kern charges and whose deferred mode cumulatively preflights the live hierarchical budget without committing.
- Preserved complete standalone behavior across 138 tests on each supported target, target-all compilation, the generated public interface, and independent policy gates.

## Task Commits

TDD gates and task outcomes were committed atomically:

1. **Task 1 RED: Offset/checksum behavioral tests** — `260ffaac`
2. **Task 1 GREEN: Offset-aware directory/checksum seam** — `54e614d7`
3. **Task 2 RED: Deferred-ledger behavioral tests** — `4b87cbae`
4. **Task 2 GREEN: Dual-mode admission ledger** — `3547f5af`

## Files Created/Modified

- `modules/mb-font/font/directory.mbt` — absolute selected-directory parser, root-backed table windows, half-open overlap checks, and checksum-mode dispatcher.
- `modules/mb-font/font/tables.mbt` — admission commit modes, cumulative work ledger, exact/remaining work facts, and ledger-aware cmap discovery.
- `modules/mb-font/font/kern.mbt` — ledger-aware classic/Apple subtable and pair admission.
- `modules/mb-font/font/font.mbt` — unchanged public facade explicitly selects historical standalone commit mode.
- `modules/mb-font/font/collection_wbtest.mbt` — non-zero-base, touching/intersection, checksum, ancestor-budget, overflow, semantic-failure, and no-double-count evidence.

`font_test.mbt` required no surgical edit: its existing exact accounting and checksum oracles plus the complete package suite already locked every standalone observation.

## Decisions Made

- Kept `font_parse_directory` and `font_validate_checksums` as thin standalone wrappers so existing private tests and `Font::open` remain source- and behavior-compatible.
- Kept collection policy explicit rather than deriving it from `directory_start == 0`.
- Used real `Budget::preflight` calls for deferred authority; no detached shadow budget can bypass a tighter live ancestor.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Windows PowerShell 5.1 misdecoded the UTF-8 policy script and produced parser errors. Running the same gate with PowerShell 7 (`pwsh`) passed; no repository file required modification.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. Empty private arrays found by the mechanical scan are populated parser accumulators, not shipped placeholder results.

## Next Phase Readiness

- Plan 102-02 can call `font_parse_directory_at` with cached Phase 101 authority and `FontChecksumMode::Collection`.
- Plan 102-02 can use `FontAdmissionCommitMode::CollectionDeferred`, exact admission work, a final root revision guard, and one aggregate selected-face charge.
- No blockers remain.

## Self-Check: PASSED

All five modified implementation/test files exist, all four TDD/task commits resolve, the summary is present in the assigned worktree, and no file remains in the main workspace.

---
*Phase: 102-root-relative-selected-face-admission*
*Completed: 2026-07-28*
