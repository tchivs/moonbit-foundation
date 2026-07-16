---
phase: 02-bounded-core-primitives
plan: "05"
subsystem: bounded-io
tags: [moonbit, streams, exact-io, bounded-io, optional-seeking]

requires:
  - phase: 02-bounded-core-primitives
    plan: "01"
    provides: stable structured stream, range, and state errors
  - phase: 02-bounded-core-primitives
    plan: "02"
    provides: checked UInt64 arithmetic, ranges, and backend narrowing
  - phase: 02-bounded-core-primitives
    plan: "04"
    provides: retained immutable byte views and exclusive mutable leases
provides:
  - explicit progress, end-of-stream, and partial-failure stream outcomes
  - exact read and write helpers with deterministic EOS and no-progress termination
  - seekable in-memory readers and writers over validated byte storage
  - non-seeking nested bounded readers and writers with hard logical windows
affects: [03-color, 04-image, 05-codec]

tech-stack:
  added: []
  patterns: [capability-specific-stream-traits, opaque-read-window, checked-cursor-before-mutation]

key-files:
  created:
    - modules/mb-core/io/moon.pkg
    - modules/mb-core/io/traits.mbt
    - modules/mb-core/io/exact.mbt
    - modules/mb-core/io/memory.mbt
    - modules/mb-core/io/bounded.mbt
    - modules/mb-core/io/io_test.mbt
    - modules/mb-core/io/io_wbtest.mbt
  modified:
    - policy/foundation.json

key-decisions:
  - "Use an opaque ReadWindow in Reader calls so bounded adapters can narrow writable access without consuming the caller lease or exposing a larger destination."
  - "Keep BoundedReader and BoundedWriter non-seeking; only MemoryReader and MemoryWriter implement the separate Seeker capability."
  - "Treat Progress(0) as an invalid transition for non-empty exact operations and fail after one transition with NoProgress."

patterns-established:
  - "Exact I/O: zero length returns before backend access; partial transitions accumulate; EOS, failure, and no-progress terminate deterministically."
  - "Bounded delegation: pass only a capability-safe narrowed window or immutable subview, then validate reported progress before cursor mutation."

requirements-completed: [CORE-03, CORE-04, CORE-05]

coverage:
  - id: D1
    description: "Reader and Writer expose explicit progress, EOS, and partial-failure states while exact helpers preserve totals and reject no-progress loops"
    requirement: CORE-03
    verification:
      - kind: unit
        ref: "modules/mb-core/io/io_test.mbt#exact stream transition tests"
        status: pass
      - kind: unit
        ref: "moon -C modules/mb-core test io --target all --frozen"
        status: pass
    human_judgment: false
  - id: D2
    description: "Seekable memory providers and nested non-seeking bounded adapters enforce checked cursors and sentinel-proven logical windows"
    requirement: CORE-04
    verification:
      - kind: unit
        ref: "modules/mb-core/io/io_test.mbt#memory and bounded provider tests"
        status: pass
      - kind: unit
        ref: "modules/mb-core/io/io_wbtest.mbt#seek ordering and transition validation"
        status: pass
    human_judgment: false
  - id: D3
    description: "Seeking remains a separately requested capability with exact zero/end boundaries and unchanged cursors on rejection"
    requirement: CORE-05
    verification:
      - kind: unit
        ref: "modules/mb-core/io/io_test.mbt#seeking is a separate capability with checked boundaries"
        status: pass
    human_judgment: false
  - id: D4
    description: "The io package has exact imports, semantic interface, four-target metadata, and publication contents in the root quality contract"
    requirement: CORE-03
    verification:
      - kind: integration
        ref: "pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-16
status: complete
---

# Phase 02 Plan 05: Bounded Core I/O Summary

**Backend-neutral partial stream state machines with exact helpers, capability-specific seeking, and hard bounded in-memory windows across all four targets**

## Performance

- **Duration:** 10 min
- **Started:** 2026-07-16T15:30:52Z
- **Completed:** 2026-07-16T15:40:41Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added open `Reader` and `Writer` traits with explicit progress/EOS/failure outcomes, a separate `Seeker`, and exact helpers that retain completed counts without spinning or touching a backend for zero-length work.
- Added seekable `MemoryReader` and `MemoryWriter` plus nested non-seeking `BoundedReader` and `BoundedWriter`, with checked cursor mutation and sentinel-proven window containment.
- Qualified 12/12 I/O tests on js, wasm, wasm-gc, and native, then passed the full Required lane with 58/58 tests per target and an exact 63-line I/O interface.

## Task Commits

1. **Task 1 RED: Specify stream outcomes, exact helpers, and separate seeking** - `f24413a` (test)
2. **Task 1 GREEN: Implement explicit stream state machines and exact helpers** - `4ba6b74` (feat)
3. **Task 2 RED: Specify bounded in-memory providers** - `0909fd5` (test)
4. **Task 2 GREEN: Implement memory and bounded providers** - `940d59f` (feat)
5. **Task 3: Register and qualify the exact I/O package contract** - `53e7c55` (chore)

## Files Created/Modified

- `modules/mb-core/io/moon.pkg` - Portable package declaration over prior core packages only.
- `modules/mb-core/io/traits.mbt` - Outcomes, opaque read windows, Reader/Writer/Seeker, and checked seek arithmetic.
- `modules/mb-core/io/exact.mbt` - Partial-progress exact read/write loops with EOS, failure, and no-progress termination.
- `modules/mb-core/io/memory.mbt` - Seekable in-memory reader and writer over retained views and owned storage.
- `modules/mb-core/io/bounded.mbt` - Nested non-seeking logical reader/writer windows.
- `modules/mb-core/io/io_test.mbt` - Public stream, exact, seek, memory, bounded, and sentinel contracts.
- `modules/mb-core/io/io_wbtest.mbt` - Internal seek ordering and oversized-progress invariants.
- `policy/foundation.json` - Exact I/O imports, semantic interface, targets, and publication contents.

## Decisions Made

- `ReadWindow` is the only mutable destination visible to a Reader implementation. Its private lease and declared length let bounded wrappers safely narrow access without creating overlapping public leases or trusting an underlying provider to honor a separate count.
- Memory providers implement the optional `Seeker` capability. Bounded wrappers deliberately do not: non-seekable composition stays first-class, and no wrapper claims it can rewind a forward-only source.
- Exact helpers treat zero progress as a state error only for non-empty operations. Empty operations return `Ok(0)` before any backend method call.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added an opaque capability-safe read window**
- **Found during:** Task 2 (Implement bounded in-memory providers)
- **Issue:** Passing a full `MutByteLease` to an underlying Reader would let it write beyond a bounded wrapper's logical remaining length; using the existing consuming split operation would invalidate the exact helper's lease.
- **Fix:** Added opaque `ReadWindow` with bounded `get`, `set`, and `length` operations. Reader calls receive only this window, and bounded readers can safely narrow it without exposing or consuming the full lease.
- **Files modified:** `modules/mb-core/io/traits.mbt`, `modules/mb-core/io/exact.mbt`, `modules/mb-core/io/bounded.mbt`
- **Verification:** Nested bounded-reader sentinel tests and all-target I/O tests passed.
- **Committed in:** `940d59f`

---

**Total deviations:** 1 auto-fixed (1 Rule 2 missing-critical correction)
**Impact on plan:** The additional opaque type is required to make D-11's hard window guarantee enforceable while retaining D-06 mutable-alias safety; no scope outside portable I/O was added.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. The new mutable destination and cursor surfaces are the planned threat-model scope: opaque narrowed windows prevent out-of-range writes, exact loops reject non-progress, and cursor validation precedes mutation.

## Next Phase Readiness

- Plan 02-06 can define explicitly injected host capabilities without coupling them to stream or seek support.
- Phase 4 and Phase 5 can compose bounded readers and writers over validated bytes without filesystem access or whole-input buffering.

## Self-Check: PASSED

- All seven I/O package files and the exact policy entry exist.
- Task commits `f24413a`, `4ba6b74`, `0909fd5`, `940d59f`, and `53e7c55` exist in order.
- `moon -C modules/mb-core test io --target all --frozen` passed 12/12 on every required target.
- `pwsh -NoProfile -File ./scripts/quality.ps1 -Lane Required` passed with 58/58 tests per target, exact 63-line I/O interface classification, exact package contents, and read-only tracked proof.

---
*Phase: 02-bounded-core-primitives*
*Completed: 2026-07-16*
